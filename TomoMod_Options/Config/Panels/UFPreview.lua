-- ============================================================
-- UFPreview.lua — Aperçu UnitFrame (moteur de rendu réel) v3.4.0
--
-- L'aperçu n'est plus une maquette. Il construit ses cadres avec EXACTEMENT
-- les mêmes fabriques que les cadres de jeu :
--     TomoMod_UnitFrames.BuildVisuals()   → arbre de widgets
--     TomoMod_UnitFrames.ApplyVisuals()   → géométrie / textures / polices
-- Texture de barre, police, bordures, InfoBar, offsets d'éléments, grille
-- d'auras, buffs ennemis, indicateur et texte de menace : tout provient du
-- moteur réel.
--
-- Données (lot B) : quand l'unité existe, les cadres sont alimentés par les
-- VRAIES données via TomoMod_UnitFrames.UpdateUnitData / UpdateUnitAuras.
-- Sinon (pas de cible, pas de familier…), repli sur des valeurs simulées.
--
-- Ce fichier n'appelle JAMAIS d'API d'unité renvoyant une valeur secrète TWW :
-- il se contente de UnitExists() et délègue tout le reste au moteur, où le
-- traitement côté C est déjà en place. Un test d'analyse statique verrouille
-- cette propriété.
--
-- L'échelle est appliquée par SetScale() sur un conteneur, JAMAIS en
-- multipliant les valeurs de la DB — les proportions restent exactes.
-- ============================================================

TomoMod_UFPreview = {}
local UFP = TomoMod_UFPreview
local L   = TomoMod_L

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

-- Suffixe des noms globaux des conteneurs d'auras de l'aperçu.
-- Sans lui, CreateAuraContainer écraserait _G["TomoMod_Auras_player"],
-- que le module Movers utilise.
local PREVIEW_SUFFIX = "_TomoUFPreview"

local UNIT_ORDER = { "player", "target", "focus", "pet", "targettarget" }
local LEFT_COL   = { "player", "pet", "focus" }
local RIGHT_COL  = { "target", "targettarget" }

-- ── Mise en page (unités = pixels de la DB, avant SetScale) ──
local COL_GAP    = 26
local ROW_GAP    = 14
local LABEL_H    = 13

-- ── Mise en page (pixels écran du strip, hors échelle) ──
local HEADER_H     = 26
local SIDE_PAD     = 14
local BOTTOM_PAD   = 10
local STRIP_H_MIN  = 150
local FIT_BUDGET_H = 200   -- hauteur de contenu visée en mode « ajusté »
local SOLO_BUDGET_H = 250
local STRIP_H_MAX  = 330   -- plafond dur (mode 1:1 qui déborde)
local MIN_SCALE    = 0.34

-- Cadence de rafraîchissement des données réelles pendant que le panneau est
-- ouvert. Seule la chaîne légère tourne ici ; les auras sont pilotées par
-- UNIT_AURA, jamais par le ticker.
local LIVE_INTERVAL = 0.2

-- ============================================================
-- DONNÉES SIMULÉES
-- ============================================================
-- Choix des archétypes, pour couvrir les deux branches de coloration de
-- E.GetHealthColor :
--   player / targettarget → joueurs   (useClassColor)
--   target                → PNJ hostile (useNameplateColors / useFactionColor)
--   focus                 → joueur ennemi (useClassColor)
--   pet                   → familier    (couleur de classe du joueur)
local MOCK = {
    player = {
        hpCur = 4820000, hpMax = 6250000, absorb = 410000,
        powerCur = 62000, powerMax = 100000,
        level = 80, isPlayer = true, isLeader = true, raidIcon = nil,
    },
    target = {
        hpCur = 18400000, hpMax = 41000000, absorb = 0,
        powerCur = 88000, powerMax = 100000,
        level = 82, isPlayer = false, isLeader = false, raidIcon = 8,
    },
    focus = {
        hpCur = 3100000, hpMax = 5200000, absorb = 0,
        powerCur = 41000, powerMax = 100000,
        level = 80, isPlayer = true, isLeader = false, raidIcon = 6,
    },
    pet = {
        hpCur = 980000, hpMax = 1500000, absorb = 0,
        powerCur = 74, powerMax = 100,
        level = 80, isPlayer = false, isLeader = false, raidIcon = nil,
    },
    targettarget = {
        hpCur = 5900000, hpMax = 6100000, absorb = 0,
        powerCur = 55000, powerMax = 100000,
        level = 80, isPlayer = true, isLeader = false, raidIcon = nil,
    },
}

local MOCK_CLASS = { target = "MAGE", focus = "PRIEST", targettarget = "DRUID" }

-- Icônes toujours présentes dans le client, quelle que soit l'extension.
local MOCK_AURA_ICONS = {
    "Interface\\Icons\\Spell_Shadow_UnholyFrenzy",
    "Interface\\Icons\\Spell_Fire_Immolation",
    "Interface\\Icons\\Spell_Frost_FrostArmor02",
    "Interface\\Icons\\Ability_Rogue_Eviscerate",
    "Interface\\Icons\\Spell_Nature_Lightning",
    "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
    "Interface\\Icons\\Spell_Fire_Fireball02",
    "Interface\\Icons\\Ability_Backstab",
}
local MOCK_BUFF_ICONS = {
    "Interface\\Icons\\Spell_Holy_PowerWordShield",
    "Interface\\Icons\\Spell_Nature_Rejuvenation",
    "Interface\\Icons\\Ability_Warrior_BattleShout",
    "Interface\\Icons\\Spell_Holy_DivineSpirit",
}
local MOCK_AURA_CD    = { 18, 6, 42, 12, 3, 26, 9, 55 }
local MOCK_AURA_STACK = { nil, "3", nil, nil, "12", nil, "2", nil }

-- ============================================================
-- HELPERS
-- ============================================================

local function UFEngine()
    local UF = TomoMod_UnitFrames
    if UF and UF.BuildVisuals and UF.ApplyVisuals then return UF end
    return nil
end

-- Reproduit la cascade de E.GetHealthColor sans token d'unité réel.
local function GetMockHealthColor(unitKey, settings)
    local mock = MOCK[unitKey]
    local isPlayerUnit = mock and mock.isPlayer

    if settings.useClassColor and isPlayerUnit then
        if unitKey == "player" then
            return TomoMod_Utils.GetClassColor("player")
        end
        local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[MOCK_CLASS[unitKey] or ""]
        if c then return c.r, c.g, c.b end
    end

    if settings.useNameplateColors and not isPlayerUnit then
        local np = TomoModDB.nameplates and TomoModDB.nameplates.colors
        local c  = np and (np.enemyInCombat or np.normal or np.hostile)
        if c then return c.r, c.g, c.b end
    end

    if settings.useFactionColor and not isPlayerUnit then
        return 0.78, 0.25, 0.25   -- rouge hostile
    end

    if unitKey == "player" or unitKey == "pet" then
        return TomoMod_Utils.GetClassColor("player")
    end
    return 0.5, 0.5, 0.5
end

-- Miroir exact des formats de E.SetHealthText, avec des nombres ordinaires.
local function SetMockHealthText(fs, cur, max, format)
    if not fs then return end
    local pct = 0
    if max and max > 0 then pct = math.floor((cur / max) * 100 + 0.5) end

    if format == "percent" then
        fs:SetFormattedText("%d%%", pct)
    elseif format == "current" then
        fs:SetFormattedText("%s", AbbreviateLargeNumbers(cur))
    elseif format == "current_percent" then
        fs:SetFormattedText("%s  |cffcccccc%d%%|r", AbbreviateLargeNumbers(cur), pct)
    elseif format == "current_max" then
        fs:SetFormattedText("%s / %s", AbbreviateLargeNumbers(cur), AbbreviateLargeNumbers(max))
    elseif format == "deficit" then
        fs:SetFormattedText("-%s", AbbreviateLargeNumbers(max - cur))
    else
        fs:SetFormattedText("%s  |cffcccccc%d%%|r", AbbreviateLargeNumbers(cur), pct)
    end
end

local function MockName(unitKey)
    if unitKey == "player" then
        return (UnitName and UnitName("player")) or L["preview_player"]
    elseif unitKey == "target" then return L["preview_target_name"]
    elseif unitKey == "focus"  then return L["preview_focus_name"]
    elseif unitKey == "pet"    then return L["preview_pet_name"]
    end
    return L["preview_tot_name"]
end

-- Signature des réglages STRUCTURELS : tout ce que BuildVisuals décide une
-- fois pour toutes. Un changement force une reconstruction de l'aperçu.
local function StructSig(settings)
    local a, eb, tt = settings.auras, settings.enemyBuffs, settings.threatText
    local centered = (TomoModDB.resourceBars and TomoModDB.resourceBars.primaryPowerCentered) and 1 or 0
    return table.concat({
        settings.enabled                     and 1 or 0,
        (settings.powerHeight   or 0) > 0    and 1 or 0,
        (settings.infoBarHeight or 0) > 0    and 1 or 0,
        settings.showAbsorb                  and 1 or 0,
        settings.showThreat                  and 1 or 0,
        (tt and tt.enabled)                  and 1 or 0,
        (a  and a.enabled)                   and 1 or 0,
        tostring(a  and a.maxAuras  or 0),
        (eb and eb.enabled)                  and 1 or 0,
        tostring(eb and eb.maxAuras or 0),
        tostring(eb and eb.size     or 0),
        centered,
    }, ":")
end

-- ── Débordement des conteneurs d'auras hors du cadre ────────
-- Fractions du point d'ancrage nommé, relatives au coin BOTTOMLEFT.
local ANCHOR_FX = {
    LEFT = 0, RIGHT = 1, CENTER = 0.5, TOP = 0.5, BOTTOM = 0.5,
    TOPLEFT = 0, TOPRIGHT = 1, BOTTOMLEFT = 0, BOTTOMRIGHT = 1,
}
local ANCHOR_FY = {
    LEFT = 0.5, RIGHT = 0.5, CENTER = 0.5, TOP = 1, BOTTOM = 0,
    TOPLEFT = 1, TOPRIGHT = 1, BOTTOMLEFT = 0, BOTTOMRIGHT = 0,
}

-- Rect du conteneur exprimé dans le repère du cadre parent (origine =
-- BOTTOMLEFT du cadre). Calcul analytique : pas de dépendance à GetTop(),
-- qui peut renvoyer nil tant que la chaîne d'ancrage n'est pas résolue.
-- `pos` est un enregistrement d'element du registre : { point, relPoint,
-- x, y }. Le champ historique s'appelait relativePoint ; on accepte les
-- deux le temps qu'un profil non migre passe par ici.
local function ContainerOverflow(container, pos, defPoint, defRel, defX, defY, fw, fh)
    if not container or not container:IsShown() then return 0, 0, 0, 0 end
    local cw, ch = container:GetWidth() or 0, container:GetHeight() or 0
    if cw <= 0 or ch <= 0 then return 0, 0, 0, 0 end

    local point = (pos and pos.point)         or defPoint
    local rel   = (pos and (pos.relPoint or pos.relativePoint)) or defRel
    local ox    = (pos and pos.x)             or defX
    local oy    = (pos and pos.y)             or defY

    local pfx, pfy = ANCHOR_FX[point] or 0.5, ANCHOR_FY[point] or 0.5
    local rfx, rfy = ANCHOR_FX[rel]   or 0.5, ANCHOR_FY[rel]   or 0.5

    local left   = rfx * fw + ox - pfx * cw
    local bottom = rfy * fh + oy - pfy * ch

    return math.max(0, -left),                 -- gauche
           math.max(0, (left + cw) - fw),      -- droite
           math.max(0, (bottom + ch) - fh),    -- haut
           math.max(0, -bottom)                -- bas
end

local function UnitOverflow(pu, settings)
    local fw = pu.frame:GetWidth()  or 0
    local fh = pu.frame:GetHeight() or 0
    local l, r, t, b = 0, 0, 0, 0

    local elements = settings.elements
    local al, ar, at, ab = ContainerOverflow(
        pu.frame.auraContainer, elements and elements.auras,
        "BOTTOMLEFT", "TOPLEFT", 0, 6, fw, fh)
    l, r, t, b = math.max(l, al), math.max(r, ar), math.max(t, at), math.max(b, ab)

    local el, er, et, eb2 = ContainerOverflow(
        pu.frame.enemyBuffContainer, elements and elements.enemyBuffs,
        "BOTTOMRIGHT", "TOPRIGHT", 0, 6, fw, fh)
    l, r, t, b = math.max(l, el), math.max(r, er), math.max(t, et), math.max(b, eb2)

    return l, r, t, b
end

-- ============================================================
-- CONSTRUCTION / REMPLISSAGE D'UN CADRE D'APERÇU
-- ============================================================

local function BuildUnitFrame(pu, unitKey, settings, stage, trashBin, accent)
    local UF = UFEngine()
    if not UF then return false end

    -- Les frames WoW ne se détruisent pas : l'ancienne est reparentée dans un
    -- bac caché. Une reconstruction n'a lieu que sur un changement structurel
    -- (cases à cocher), jamais pendant un glissement de curseur.
    if pu.frame then
        pu.frame:Hide()
        pu.frame:ClearAllPoints()
        pu.frame:SetParent(trashBin)
    end

    local f = CreateFrame("Frame", nil, stage)
    UF.BuildVisuals(f, unitKey, settings, { preview = true, nameSuffix = PREVIEW_SUFFIX })
    pu.frame = f
    pu.sig   = StructSig(settings)

    -- Surbrillance au survol (au-dessus de tout l'arbre réel)
    local hl = CreateFrame("Frame", nil, f, "BackdropTemplate")
    hl:SetPoint("TOPLEFT", -2, 2)
    hl:SetPoint("BOTTOMRIGHT", 2, -2)
    hl:SetFrameLevel(f:GetFrameLevel() + 20)
    hl:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    hl:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.85)
    hl:EnableMouse(false)
    hl:Hide()
    f.tomoHighlight = hl

    return true
end

local function FillUnitFrame(pu, unitKey, settings)
    local f = pu.frame
    if not f then return end
    local mock = MOCK[unitKey]
    if not mock then return end

    local globalDB = TomoModDB.unitFrames

    -- ── Health ───────────────────────────────────────────────
    local health = f.health
    if health then
        health:SetMinMaxValues(0, mock.hpMax)
        health:SetValue(mock.hpCur)
        local r, g, b = GetMockHealthColor(unitKey, settings)
        health:SetStatusBarColor(r, g, b, 1)

        -- Texte de santé (miroir de UpdateHealth)
        if health.text then
            if settings.showHealthText then
                SetMockHealthText(health.text, mock.hpCur, mock.hpMax, settings.healthTextFormat)
            else
                health.text:SetText("")
            end
        end

        -- Nom / niveau (miroir de UpdateName + UpdateLevel)
        if health.nameText then
            if settings.showName then
                health.nameText:SetTextColor(1, 1, 1, 0.95)
                if settings.nameTruncate and settings.nameTruncateLength then
                    health.nameText:SetWidth(settings.nameTruncateLength * (globalDB.fontSize or 12) * 0.55)
                else
                    health.nameText:SetWidth(settings.width - 12)
                end
                health.nameText:SetWordWrap(false)
                health.nameText:SetNonSpaceWrap(false)
                if settings.showLevel then
                    health.nameText:SetFormattedText("%d - %s", mock.level, MockName(unitKey))
                else
                    health.nameText:SetFormattedText("%s", MockName(unitKey))
                end
            else
                health.nameText:SetText("")
            end
        end

        if health.levelText then
            if settings.showLevel and not settings.showName then
                health.levelText:SetTextColor(1, 0.82, 0, 0.9)
                health.levelText:SetFormattedText("%d", mock.level)
            else
                health.levelText:SetText("")
            end
        end

        -- Icône de raid (miroir de UpdateRaidIcon)
        if health.raidIcon then
            if settings.showRaidIcon and mock.raidIcon then
                SetRaidTargetIconTexture(health.raidIcon, mock.raidIcon)
                health.raidIcon:Show()
            else
                health.raidIcon:Hide()
            end
        end

        -- Icône de chef de groupe
        if health.leaderIcon then
            health.leaderIcon:SetShown(settings.showLeaderIcon and mock.isLeader and true or false)
        end
    end

    -- ── Absorb ───────────────────────────────────────────────
    if f.absorb then
        f.absorb:SetMinMaxValues(0, mock.hpMax)
        f.absorb:SetValue(mock.absorb)
        f.absorb:Show()
    end

    -- ── Power (miroir de E.UpdatePower) ──────────────────────
    if f.power then
        local powerType = 0
        if unitKey == "player" and UnitPowerType then
            -- Type de ressource du joueur : entier ordinaire, jamais secret.
            powerType = UnitPowerType("player") or 0
        end
        f.power:SetMinMaxValues(0, mock.powerMax)
        f.power:SetValue(mock.powerCur)
        local pr, pg, pb = TomoMod_Utils.GetPowerColor(powerType)
        f.power:SetStatusBarColor(pr, pg, pb, 1)
        if f.power.text then
            if settings.showPowerText and not settings.infoBarHeight then
                f.power.text:SetFormattedText("%s", AbbreviateLargeNumbers(mock.powerCur))
            else
                f.power.text:SetText("")
            end
        end
    end

    -- ── Info Bar (miroir de E.UpdateInfoBar) ─────────────────
    if f.infoBar then
        if f.infoBar.powerText then
            f.infoBar.powerText:SetFormattedText("%s", AbbreviateLargeNumbers(mock.powerCur))
        end
        if f.infoBar.hpText then
            f.infoBar.hpText:SetFormattedText("%s", AbbreviateLargeNumbers(mock.hpCur))
        end
    end

    -- ── Menace ───────────────────────────────────────────────
    if f.threat then
        if unitKey == "target" then
            local tr, tg, tb = GetThreatStatusColor(3)
            f.threat:SetThreatColor(tr, tg, tb)
            f.threat:Show()
        else
            f.threat:Hide()
        end
    end
    if f.threatText then
        local tr, tg, tb = GetThreatStatusColor(3)
        f.threatText:SetTextColor(tr, tg, tb, 1)
        f.threatText:SetFormattedText("%d%%", 112)
        f.threatText:Show()
    end

    -- ── Auras ────────────────────────────────────────────────
    if f.auraContainer and f.auraContainer.icons then
        local aset = settings.auras or {}
        local n    = aset.maxAuras or 8
        f.auraContainer:Show()
        for i = 1, #f.auraContainer.icons do
            local icon = f.auraContainer.icons[i]
            if icon then
                if i <= n then
                    icon.texture:SetTexture(MOCK_AURA_ICONS[((i - 1) % #MOCK_AURA_ICONS) + 1])
                    if icon.cooldown then
                        -- Nombres ordinaires : SetCooldown n'est banni qu'avec
                        -- des valeurs secrètes.
                        local dur = MOCK_AURA_CD[((i - 1) % #MOCK_AURA_CD) + 1]
                        icon.cooldown:SetCooldown(GetTime() - dur * 0.35, dur)
                        icon.cooldown:Show()
                    end
                    local stack = MOCK_AURA_STACK[((i - 1) % #MOCK_AURA_STACK) + 1]
                    icon.count:SetText(stack or "")
                    icon.count:SetShown(stack and true or false)
                    icon:Show()
                else
                    icon:Hide()
                end
            end
        end
    end

    -- ── Buffs ennemis ────────────────────────────────────────
    if f.enemyBuffContainer and f.enemyBuffContainer.icons then
        local bset = settings.enemyBuffs or {}
        local n    = bset.maxAuras or 4
        f.enemyBuffContainer:Show()
        for i = 1, #f.enemyBuffContainer.icons do
            local icon = f.enemyBuffContainer.icons[i]
            if icon then
                if i <= n then
                    icon.texture:SetTexture(MOCK_BUFF_ICONS[((i - 1) % #MOCK_BUFF_ICONS) + 1])
                    if icon.cooldown then
                        local dur = 8 + i * 5
                        icon.cooldown:SetCooldown(GetTime() - dur * 0.4, dur)
                        icon.cooldown:Show()
                    end
                    icon.count:SetText("")
                    icon:Show()
                else
                    icon:Hide()
                end
            end
        end
    end
end

-- ============================================================
-- DONNÉES RÉELLES (LOT B)
-- ============================================================

-- Le mode « données réelles » est actif par défaut ; nil vaut donc true.
local function LiveEnabled()
    return TomoModDB.unitFrames.previewLiveData ~= false
end

-- Une unité est pilotable en direct si l'option est active ET si le token
-- existe réellement. UnitExists est la seule API d'unité appelée ici : elle
-- renvoie un booléen ordinaire, jamais une valeur secrète.
local function IsLive(unitKey)
    return LiveEnabled() and UnitExists(unitKey) and true or false
end

-- Bascule un cadre d'aperçu entre données réelles et simulation.
-- En mode réel, frame.unit est renseigné et le moteur écrit dans les mêmes
-- widgets ; en simulation il est effacé pour qu'aucun appel résiduel du
-- moteur ne puisse lire une unité.
local function ApplyDataMode(pu, unitKey, settings, live)
    local f = pu.frame
    if not f then return end
    local UF = UFEngine()

    if live and UF and UF.UpdateUnitData then
        f.unit = unitKey
        UF.UpdateUnitData(f)
        UF.UpdateUnitAuras(f)
        -- E.UpdateEnemyBuffs peut créer son conteneur à cet instant : on le
        -- repasse en lecture seule (idempotent).
        if UF.NeutralizeContainer then
            UF.NeutralizeContainer(f.enemyBuffContainer)
        end
    else
        f.unit = nil
        FillUnitFrame(pu, unitKey, settings)
    end
    pu.live = live and true or false
end

-- ============================================================
-- API PUBLIQUE — CADRE D'APERÇU AUTONOME (AstralForge)
-- ============================================================
-- Le studio a besoin d'UN cadre d'aperçu isolé, pas du strip complet.
-- Plutôt que de dupliquer BuildVisuals + le remplissage simulé, on expose
-- les fabriques déjà utilisées par le panneau : le studio édite donc
-- exactement le même arbre que l'aperçu, lui-même identique aux cadres de
-- jeu. Aucune duplication possible entre les trois.
--
-- Le cadre rendu est DÉTACHÉ : il n'est jamais une frame oUF sécurisée,
-- n'a pas de token d'unité par défaut et ne porte aucun attribut protégé.
-- C'est ce qui autorise le glisser-déposer sans risque de souillure.

local standaloneBin

function UFP.CreateStandalone(parent, unitKey, opts)
    local UF = UFEngine()
    if not UF or not parent then return nil end
    local settings = TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames[unitKey]
    if not settings then return nil end

    if not standaloneBin then
        standaloneBin = CreateFrame("Frame")
        standaloneBin:Hide()
    end

    local T = TomoMod_Widgets and TomoMod_Widgets.Theme
    local accent = {
        (T and T.accent[1]) or TomoMod_Utils.BRAND[1],
        (T and T.accent[2]) or TomoMod_Utils.BRAND[2],
        (T and T.accent[3]) or TomoMod_Utils.BRAND[3],
    }

    local pu = { frame = opts and opts.recycle or nil }
    if not BuildUnitFrame(pu, unitKey, settings, parent, standaloneBin, accent) then
        return nil
    end

    -- Données SIMULÉES par défaut, et c'est structurel, pas cosmétique.
    -- En mode réel, un widget alimenté par des données protégées (le texte
    -- de vie, par exemple) voit son RECT devenir secret : GetLeft() rend
    -- alors une valeur secrète, et tout designer qui mesure ce cadre pour
    -- poser une poignée lève « arithmetic on a secret number value ».
    -- Un cadre d'aperçu simulé n'a aucun rect secret, donc il est mesurable.
    --
    -- L'appelant peut redemander le mode réel (opts.live) s'il ne mesure
    -- rien — le strip du panneau de config, lui, se contente d'afficher.
    local live = (opts and opts.live) and IsLive(unitKey) or false
    ApplyDataMode(pu, unitKey, settings, live)

    if pu.frame and pu.frame.tomoHighlight then
        pu.frame.tomoHighlight:Hide()
    end
    return pu.frame
end

-- ============================================================
-- CRÉATION DU STRIP
-- ============================================================

function UFP.Create(parent)
    local T  = TomoMod_Widgets and TomoMod_Widgets.Theme
    local accent = {
        (T and T.accent[1]) or TomoMod_Utils.BRAND[1],
        (T and T.accent[2]) or TomoMod_Utils.BRAND[2],
        (T and T.accent[3]) or TomoMod_Utils.BRAND[3],
    }
    local aR, aG, aB = accent[1], accent[2], accent[3]

    local strip = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    strip:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, 0)
    strip:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    strip:SetHeight(STRIP_H_MIN)
    strip:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    strip:SetBackdropColor(0.048, 0.048, 0.062, 1)
    strip:SetBackdropBorderColor(aR, aG, aB, 0.16)
    if strip.SetClipsChildren then strip:SetClipsChildren(true) end

    -- Bac à cadres retirés (les frames WoW ne se détruisent pas)
    local trashBin = CreateFrame("Frame", nil, strip)
    trashBin:SetSize(1, 1)
    trashBin:Hide()

    -- Scène : porte l'échelle. Toutes les coordonnées internes sont en
    -- pixels de la DB, non mis à l'échelle.
    local stage = CreateFrame("Frame", nil, strip)
    stage:SetPoint("TOPLEFT", strip, "TOPLEFT", SIDE_PAD, -HEADER_H)
    stage:SetSize(1, 1)

    -- ── En-tête ───────────────────────────────────────────────
    local header = strip:CreateFontString(nil, "OVERLAY")
    header:SetFont(FONT_BOLD, 9, "OUTLINE")
    header:SetPoint("TOPLEFT", 12, -9)
    header:SetTextColor(aR, aG, aB, 0.55)
    header:SetText(L["preview_header"])

    local dot = strip:CreateTexture(nil, "OVERLAY")
    dot:SetSize(5, 5)
    dot:SetPoint("LEFT", header, "RIGHT", 6, 0)
    dot:SetColorTexture(aR, aG, aB, 1)
    -- Le ticker du point pulsant est démarré / arrêté par StartLive / StopLive :
    -- il ne doit pas survivre à la fermeture du panneau, ni rester mort après
    -- une première fermeture.
    local dotVis    = true
    local dotTicker = nil
    -- Le démontage complet (ticker de données + événements) est posé plus bas,
    -- une fois StopLive défini.

    local sep = strip:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("BOTTOMLEFT",  strip, "BOTTOMLEFT",  0, 0)
    sep:SetPoint("BOTTOMRIGHT", strip, "BOTTOMRIGHT", 0, 0)
    sep:SetColorTexture(aR * 0.6, aG * 0.6, aB * 0.6, 0.25)

    -- ── État ─────────────────────────────────────────────────
    local selectedUnit = nil     -- nil = tout afficher
    local zoomMode     = "fit"   -- "fit" | "one"
    local Refresh                -- forward declaration

    local units  = {}
    local labels = {}
    for _, k in ipairs(UNIT_ORDER) do
        units[k] = {}
        local lbl = strip:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT, 8, "OUTLINE")
        lbl:SetTextColor(aR * 0.7, aG * 0.7, aB * 0.7, 0.70)
        lbl:SetJustifyH("LEFT")
        lbl:Hide()
        labels[k] = lbl
    end

    local BRAND_HEX = (TomoMod_Utils and TomoMod_Utils.BRAND_HEX) or "2e9dd8"

    local function BaseLabel(k)
        return L["preview_lbl_" .. (k == "targettarget" and "tot" or k)] or k:upper()
    end

    -- Pastille indiquant si la ligne montre des données réelles ou simulées :
    -- sans elle, impossible de savoir ce qu'on regarde quand on n'a pas de cible.
    local function SetUnitLabel(k)
        local pu = units[k]
        if pu and pu.live then
            labels[k]:SetText(BaseLabel(k) .. "  |cff" .. BRAND_HEX .. L["preview_tag_live"] .. "|r")
        else
            labels[k]:SetText(BaseLabel(k) .. "  |cff808080" .. L["preview_tag_sim"] .. "|r")
        end
    end

    -- ── Petit bouton générique ───────────────────────────────
    local function MakeButton(w, text)
        local b = CreateFrame("Button", nil, strip, "BackdropTemplate")
        b:SetSize(w, 18)
        b:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        b:SetBackdropColor(aR * 0.18, aG * 0.18, aB * 0.18, 0.90)
        b:SetBackdropBorderColor(aR, aG, aB, 0.45)
        local t = b:CreateFontString(nil, "OVERLAY")
        t:SetFont(FONT_BOLD, 8, "OUTLINE")
        t:SetPoint("CENTER")
        t:SetTextColor(aR, aG, aB, 0.85)
        t:SetText(text)
        b.text = t
        b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(aR, aG, aB, 0.90) end)
        b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(aR, aG, aB, 0.45) end)
        return b
    end

    local zoomBtn = MakeButton(56, L["preview_zoom_fit"])
    zoomBtn:SetPoint("TOPRIGHT", strip, "TOPRIGHT", -12, -6)
    zoomBtn:SetScript("OnClick", function()
        zoomMode = (zoomMode == "fit") and "one" or "fit"
        zoomBtn.text:SetText(zoomMode == "fit" and L["preview_zoom_fit"] or L["preview_zoom_11"])
        Refresh()
    end)
    zoomBtn:HookScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L["preview_zoom_tip"], aR, aG, aB, 1, true)
        GameTooltip:Show()
    end)
    zoomBtn:HookScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    local dataBtn = MakeButton(96, L["preview_data_live"])
    dataBtn:SetPoint("TOPRIGHT", zoomBtn, "TOPLEFT", -6, 0)
    dataBtn:SetScript("OnClick", function()
        TomoModDB.unitFrames.previewLiveData = not LiveEnabled()
        dataBtn.text:SetText(LiveEnabled() and L["preview_data_live"] or L["preview_data_mock"])
        Refresh()
    end)
    dataBtn:HookScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L["preview_data_tip"], aR, aG, aB, 1, true)
        GameTooltip:Show()
    end)
    dataBtn:HookScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    local showAllBtn = MakeButton(100, L["preview_show_all"])
    showAllBtn:SetPoint("TOPRIGHT", dataBtn, "TOPLEFT", -6, 0)
    showAllBtn:SetScript("OnClick", function()
        selectedUnit = nil
        showAllBtn:Hide()
        Refresh()
    end)
    showAllBtn:Hide()

    -- Message affiché si le moteur UnitFrames n'est pas chargé
    local warn = strip:CreateFontString(nil, "OVERLAY")
    warn:SetFont(FONT, 10, "OUTLINE")
    warn:SetPoint("CENTER", strip, "CENTER", 0, -6)
    warn:SetTextColor(0.85, 0.55, 0.35, 0.95)
    warn:Hide()

    strip.GetSelectedUnit = function() return selectedUnit end
    strip.ClearSelection   = function()
        selectedUnit = nil
        showAllBtn:Hide()
        Refresh()
    end
    strip.onUnitClick = {}

    -- ── Scripts de souris posés sur un cadre reconstruit ─────
    local function WireMouse(pu, unitKey)
        local f = pu.frame
        f:EnableMouse(true)
        f:SetScript("OnEnter", function(self)
            if self.tomoHighlight then self.tomoHighlight:Show() end
            if GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local hint = (selectedUnit == unitKey)
                    and L["preview_click_show_all"]
                    or  L["preview_click_isolate"]
                local lbl = L["preview_lbl_" .. (unitKey == "targettarget" and "tot" or unitKey)] or unitKey
                GameTooltip:SetText(lbl .. " - " .. hint, aR, aG, aB)
                GameTooltip:Show()
            end
        end)
        f:SetScript("OnLeave", function(self)
            if self.tomoHighlight then self.tomoHighlight:Hide() end
            if GameTooltip then GameTooltip:Hide() end
        end)
        f:SetScript("OnMouseUp", function()
            if selectedUnit == unitKey then
                selectedUnit = nil
                showAllBtn:Hide()
            else
                selectedUnit = unitKey
                showAllBtn:Show()
            end
            Refresh()
            local fn = strip.onUnitClick[unitKey]
            if fn then fn() end
        end)
    end

    -- ── Rendu ────────────────────────────────────────────────
    Refresh = function()
        if not TomoModDB or not TomoModDB.unitFrames then return end
        local UF = UFEngine()
        if not UF then
            for _, k in ipairs(UNIT_ORDER) do
                if units[k].frame then units[k].frame:Hide() end
                labels[k]:Hide()
            end
            warn:SetText(L["preview_engine_missing"])
            warn:Show()
            strip:SetHeight(STRIP_H_MIN)
            return
        end
        warn:Hide()

        local ufdb = TomoModDB.unitFrames

        -- 1) Construire / mettre à jour chaque unité active
        local active = {}
        for _, k in ipairs(UNIT_ORDER) do
            local settings = ufdb[k]
            local pu       = units[k]
            if settings and settings.enabled then
                local sig = StructSig(settings)
                if not pu.frame or pu.sig ~= sig then
                    if BuildUnitFrame(pu, k, settings, stage, trashBin, accent) then
                        WireMouse(pu, k)
                    end
                end
                if pu.frame then
                    UF.ApplyVisuals(pu.frame, k, settings)
                    ApplyDataMode(pu, k, settings, IsLive(k))
                    active[k] = settings
                end
            elseif pu.frame then
                pu.frame:Hide()
            end
        end

        for _, k in ipairs(UNIT_ORDER) do
            local shown = active[k] and (not selectedUnit or selectedUnit == k)
            if units[k].frame then units[k].frame:SetShown(shown and true or false) end
            SetUnitLabel(k)
            labels[k]:SetShown(shown and true or false)
        end

        if not next(active) then
            warn:SetText(L["preview_all_disabled"])
            warn:Show()
            strip:SetHeight(STRIP_H_MIN)
            return
        end

        -- 2) Mesurer (coordonnées DB, hors échelle)
        local ext = {}
        for k, settings in pairs(active) do
            local l, r, t, b = UnitOverflow(units[k], settings)
            ext[k] = {
                l = l, r = r, t = t, b = b,
                w = (units[k].frame:GetWidth()  or 0) + l + r,
                h = (units[k].frame:GetHeight() or 0) + t + b + LABEL_H,
            }
        end

        local stripW = strip:GetWidth()
        if not stripW or stripW < 50 then stripW = (parent:GetWidth() or 900) end
        local availW = math.max(120, stripW - SIDE_PAD * 2)

        local place = {}   -- [unitKey] = { x, y }  (TOPLEFT du cadre, coords scène)
        local contentW, contentH = 0, 0

        if selectedUnit then
            -- ── Mode solo ────────────────────────────────────
            local e = ext[selectedUnit]
            contentW, contentH = e.w, e.h
            place[selectedUnit] = { x = e.l, y = -e.t }
        else
            -- ── Deux colonnes ────────────────────────────────
            local function ColumnWidth(list)
                local w = 0
                for _, k in ipairs(list) do
                    if ext[k] and ext[k].w > w then w = ext[k].w end
                end
                return w
            end
            local leftW  = ColumnWidth(LEFT_COL)
            local rightW = ColumnWidth(RIGHT_COL)
            local gap    = (leftW > 0 and rightW > 0) and COL_GAP or 0
            contentW = leftW + gap + rightW

            local function LayColumn(list, x0)
                local y = 0
                for _, k in ipairs(list) do
                    local e = ext[k]
                    if e then
                        place[k] = { x = x0 + e.l, y = -(y + e.t) }
                        y = y + e.h + ROW_GAP
                    end
                end
                if y > 0 then y = y - ROW_GAP end
                return y
            end
            local leftH  = LayColumn(LEFT_COL,  0)
            local rightH = LayColumn(RIGHT_COL, leftW + gap)
            contentH = math.max(leftH, rightH)
        end

        -- 3) Échelle
        local scale = 1
        if zoomMode == "fit" then
            local budgetH = selectedUnit and SOLO_BUDGET_H or FIT_BUDGET_H
            local sw = (contentW > 0) and (availW  / contentW) or 1
            local sh = (contentH > 0) and (budgetH / contentH) or 1
            scale = math.min(1, sw, sh)
            if scale < MIN_SCALE then scale = MIN_SCALE end
        end
        stage:SetScale(scale)
        stage:SetSize(math.max(contentW, 1), math.max(contentH, 1))

        -- 4) Placer cadres et étiquettes
        for k, p in pairs(place) do
            local pu = units[k]
            pu.frame:ClearAllPoints()
            pu.frame:SetPoint("TOPLEFT", stage, "TOPLEFT", p.x, p.y)

            -- Les étiquettes sont parentées au strip (hors échelle) pour rester
            -- lisibles : leur position est projetée depuis les coords scène.
            local fh  = pu.frame:GetHeight() or 0
            local lbl = labels[k]
            lbl:ClearAllPoints()
            lbl:SetPoint("TOPLEFT", strip, "TOPLEFT",
                SIDE_PAD + p.x * scale,
                -HEADER_H + (p.y - fh) * scale - 2)
        end

        -- 5) Hauteur du strip
        local h = HEADER_H + contentH * scale + BOTTOM_PAD
        if h < STRIP_H_MIN then h = STRIP_H_MIN end
        if h > STRIP_H_MAX then h = STRIP_H_MAX end
        strip:SetHeight(math.floor(h + 0.5))
    end

    -- ── Cycle de vie des données réelles ─────────────────────
    -- Tout ne tourne QUE pendant que le panneau est affiché : ticker et
    -- événements sont créés à l'affichage et démontés à la fermeture.
    local liveTicker
    local evtFrame = CreateFrame("Frame")
    evtFrame:SetScript("OnEvent", function(_, event, unit)
        -- On ne rafraîchit pas les auras ici : on marque l'unité et le ticker
        -- absorbe la rafale (UNIT_AURA part en salve en raid).
        local pu = units[unit]
        if pu then pu.aurasDirty = true end
    end)

    local function TickLive()
        if not strip:IsShown() then return end
        local UF = UFEngine()
        if not UF then return end
        local ufdb = TomoModDB.unitFrames
        if not ufdb then return end

        for _, k in ipairs(UNIT_ORDER) do
            local pu       = units[k]
            local settings = ufdb[k]
            if settings and pu.frame and pu.frame:IsShown() then
                local live = IsLive(k)
                if live ~= pu.live then
                    -- Apparition ou disparition de l'unité : bascule complète.
                    ApplyDataMode(pu, k, settings, live)
                    pu.aurasDirty = false
                    SetUnitLabel(k)
                elseif live then
                    UF.UpdateUnitData(pu.frame)
                    if pu.aurasDirty then
                        pu.aurasDirty = false
                        UF.UpdateUnitAuras(pu.frame)
                    end
                end
            end
        end
    end

    local function StartLive()
        if not liveTicker then
            liveTicker = C_Timer.NewTicker(LIVE_INTERVAL, TickLive)
        end
        if not dotTicker then
            dotTicker = C_Timer.NewTicker(1.2, function()
                dotVis = not dotVis
                dot:SetAlpha(dotVis and 0.9 or 0.20)
            end)
        end
        evtFrame:RegisterEvent("UNIT_AURA")
    end

    local function StopLive()
        if liveTicker then liveTicker:Cancel(); liveTicker = nil end
        if dotTicker  then dotTicker:Cancel();  dotTicker  = nil end
        evtFrame:UnregisterAllEvents()
        for _, k in ipairs(UNIT_ORDER) do
            units[k].aurasDirty = false
        end
    end

    strip.Refresh    = Refresh
    UFP.Refresh      = function() if strip and strip:IsShown() then Refresh() end end
    UFP.ForceRefresh = Refresh

    strip:SetScript("OnShow", function()
        StartLive()
        Refresh()
    end)
    -- Recalcule l'échelle quand la LARGEUR du panneau change. On ignore les
    -- changements de hauteur : Refresh appelle SetHeight, ce qui rappellerait
    -- ce handler en boucle.
    strip:SetScript("OnSizeChanged", function(self, w)
        local ww = math.floor((w or self:GetWidth() or 0) + 0.5)
        if ww == self._lastW then return end
        self._lastW = ww
        if self._reflowPending then return end
        self._reflowPending = true
        C_Timer.After(0, function()
            self._reflowPending = nil
            if self:IsShown() then Refresh() end
        end)
    end)
    strip:SetScript("OnHide", StopLive)

    StartLive()
    C_Timer.After(0, Refresh)

    return strip
end

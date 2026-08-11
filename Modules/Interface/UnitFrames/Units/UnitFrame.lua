-- =====================================
-- Units/UnitFrame.lua — Moteur UnitFrame basé sur oUF
-- TomoMod v2.6.0 — Remplace le moteur hardcodé par oUF
-- Supports: player, target, targettarget, pet, focus
-- =====================================

TomoMod_UnitFrames = TomoMod_UnitFrames or {}
local UF = TomoMod_UnitFrames
local E  = UF_Elements

-- [PERF] Local caching des API WoW hot-path
local UnitExists                  = UnitExists
local UnitHealth                  = UnitHealth
local UnitHealthMax               = UnitHealthMax
local UnitGetTotalAbsorbs         = UnitGetTotalAbsorbs
local UnitName                    = UnitName
local UnitLevel                   = UnitLevel
local UnitIsPlayer                = UnitIsPlayer
local UnitIsGroupLeader           = UnitIsGroupLeader
local UnitThreatSituation         = UnitThreatSituation
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local UnitThreatPercentageOfLead  = UnitThreatPercentageOfLead
local GetRaidTargetIndex          = GetRaidTargetIndex
local SetRaidTargetIconTexture    = SetRaidTargetIconTexture
local GetThreatStatusColor        = GetThreatStatusColor
local pairs, wipe                 = pairs, wipe

-- Table des frames par unit (remplie dans Initialize)
local frames   = {}
local isLocked = true

-- =====================================
-- RAID ICON COORDS
-- =====================================
local raidIconCoords = {
    [1] = { 0,    0.25, 0,    0.25 },  -- Star
    [2] = { 0.25, 0.5,  0,    0.25 },  -- Circle
    [3] = { 0.5,  0.75, 0,    0.25 },  -- Diamond
    [4] = { 0.75, 1,    0,    0.25 },  -- Triangle
    [5] = { 0,    0.25, 0.25, 0.5  },  -- Moon
    [6] = { 0.25, 0.5,  0.25, 0.5  },  -- Square
    [7] = { 0.5,  0.75, 0.25, 0.5  },  -- Cross
    [8] = { 0.75, 1,    0.25, 0.5  },  -- Skull
}

-- =====================================
-- UPDATE FUNCTIONS
-- Inchangées vs v2.5 — utilisent frame.health / frame.power (aliases oUF).
-- SetMinMaxValues/SetValue sont C-side et acceptent les secret numbers TWW.
-- =====================================

local function UpdateHealth(frame)
    if not frame or not frame.health or not frame.unit then return end
    if not UnitExists(frame.unit) then return end

    local unit     = frame.unit
    local settings = TomoModDB.unitFrames[unit]
    if not settings then return end

    local current = UnitHealth(unit)
    local max     = UnitHealthMax(unit)

    -- C-side — acceptent les secret numbers nativement
    frame.health:SetMinMaxValues(0, max)
    frame.health:SetValue(current)

    -- Couleur
    local r, g, b = E.GetHealthColor(unit, settings)
    frame.health:SetStatusBarColor(r, g, b, 1)

    -- Texte de santé (SetFormattedText est C-side — zéro taint Lua)
    if settings.showHealthText and frame.health.text then
        E.SetHealthText(frame.health.text, current, max, settings.healthTextFormat, unit)
        if frame.health.nameText then
            frame.health.nameText:Show()
        end
    else
        frame.health.text:SetText("")
    end
end

local function UpdateAbsorb(frame)
    if not frame or not frame.absorb then return end
    if not UnitExists(frame.unit) then return end

    local absorb = UnitGetTotalAbsorbs(frame.unit)
    local max    = UnitHealthMax(frame.unit)

    frame.absorb:SetMinMaxValues(0, max)
    frame.absorb:SetValue(absorb)
    frame.absorb:Show()
end

local function UpdateName(frame)
    if not frame or not frame.health or not frame.health.nameText then return end
    if not UnitExists(frame.unit) then return end

    local settings = TomoModDB.unitFrames[frame.unit]
    if not settings or not settings.showName then
        frame.health.nameText:SetText("")
        return
    end

    -- Nom toujours en blanc pour rester lisible sur n'importe quelle
    -- couleur de barre de santé (couleur de classe, dégradé, etc.)
    frame.health.nameText:SetTextColor(1, 1, 1, 0.95)

    -- TWW: name = secret string → troncature via clip C-side (SetWidth)
    local name = UnitName(frame.unit)
    if not name then frame.health.nameText:SetText(""); return end

    local nameFS = frame.health.nameText
    if settings.nameTruncate and settings.nameTruncateLength then
        local dbFontSize = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.fontSize) or 12
        local maxWidth   = settings.nameTruncateLength * dbFontSize * 0.55
        nameFS:SetWidth(maxWidth)
        nameFS:SetWordWrap(false)
        nameFS:SetNonSpaceWrap(false)
    else
        nameFS:SetWidth(settings.width - 12)
        nameFS:SetWordWrap(false)
        nameFS:SetNonSpaceWrap(false)
    end

    if settings.showLevel then
        local level = UnitLevel(frame.unit)
        frame.health.nameText:SetFormattedText("%d - %s", level, name)
        if frame.health.levelText then
            frame.health.levelText:SetText("")
        end
    else
        frame.health.nameText:SetFormattedText("%s", name)
    end

    -- Les textes personnalises utilisent les memes jetons d'identite que le
    -- nom : ils se rafraichissent donc au meme moment, sur les memes
    -- evenements, sans en enregistrer de nouveaux.
    local UFE = TomoMod_UFElements
    if UFE and UFE.RefreshCustomTexts then
        UFE.RefreshCustomTexts(frame, settings.elements)
    end
end

local function UpdateLevel(frame)
    if not frame or not frame.health or not frame.health.levelText then return end
    if not UnitExists(frame.unit) then return end

    local settings = TomoModDB.unitFrames[frame.unit]
    if not settings or not settings.showLevel then
        frame.health.levelText:SetText("")
        return
    end

    -- Si showName aussi, le niveau est affiché combiné dans nameText
    if settings.showName then
        frame.health.levelText:SetText("")
        return
    end

    local level = UnitLevel(frame.unit)
    frame.health.levelText:SetTextColor(1, 0.82, 0, 0.9)
    frame.health.levelText:SetFormattedText("%d", level)
end

local function UpdateThreat(frame)
    if not frame or not frame.threat then return end
    if not UnitExists(frame.unit) then
        frame.threat:Hide()
        return
    end

    local settings = TomoModDB.unitFrames[frame.unit]
    if not settings or not settings.showThreat then
        frame.threat:Hide()
        return
    end

    local status = UnitThreatSituation("player", frame.unit)
    if status and status >= 2 then
        local r, g, b = GetThreatStatusColor(status)
        frame.threat:SetThreatColor(r, g, b)
        frame.threat:Show()
    else
        frame.threat:Hide()
    end
end

-- =====================================
-- UPDATE THREAT TEXT
-- TWW: UnitDetailedThreatSituation / UnitThreatPercentageOfLead
-- retournent des secret floats — passés UNIQUEMENT à SetFormattedText (C-side).
-- =====================================
local function UpdateThreatText(frame, forcePreview)
    if not frame or not frame.threatText then return end

    local unit     = frame.unit
    local settings = TomoModDB.unitFrames[unit]
    local tt       = settings and settings.threatText
    if not tt or not tt.enabled then
        frame.threatText:Hide()
        return
    end

    if forcePreview then
        frame.threatText:SetTextColor(0.6, 0.6, 0.6, 1)
        frame.threatText:SetText("0%")
        frame.threatText:Show()
        return
    end

    if not UnitExists(unit) or UnitIsPlayer(unit) then
        frame.threatText:Hide()
        return
    end

    local status = UnitThreatSituation("player", unit)
    if not status or status == 0 then
        frame.threatText:Hide()
        return
    end

    local r, g, b = GetThreatStatusColor(status)
    frame.threatText:SetTextColor(r, g, b, 1)

    if status >= 3 then
        local lead = UnitThreatPercentageOfLead("player", unit)
        if lead then
            frame.threatText:SetFormattedText("+%1.0f%%", lead)
        else
            -- [TWW TAINT] UnitDetailedThreatSituation 3rd return is a secret float.
            -- SetFormattedText is C-side and safely unwraps, but `pct or 0` has an `or`
            -- short-circuit that is technically Lua-side. pcall is a cheap belt-and-braces
            -- in case Blizzard tightens secret-value handling further.
            local ok, pct = pcall(function() return select(3, UnitDetailedThreatSituation("player", unit)) end)
            frame.threatText:SetFormattedText("%1.0f%%", (ok and pct) or 0)
        end
    else
        local ok, pct = pcall(function() return select(3, UnitDetailedThreatSituation("player", unit)) end)
        frame.threatText:SetFormattedText("%1.0f%%", (ok and pct) or 0)
    end

    frame.threatText:Show()
end

local function UpdateRaidIcon(frame)
    if not frame or not frame.health or not frame.health.raidIcon then return end

    local settings = TomoModDB.unitFrames[frame.unit]
    if not settings or not settings.showRaidIcon then
        frame.health.raidIcon:Hide()
        return
    end
    if not UnitExists(frame.unit) then
        frame.health.raidIcon:Hide()
        return
    end

    -- TWW: GetRaidTargetIndex retourne un secret number — SetRaidTargetIconTexture est C-side
    local index = GetRaidTargetIndex(frame.unit)
    if index then
        SetRaidTargetIconTexture(frame.health.raidIcon, index)
        frame.health.raidIcon:Show()
    else
        frame.health.raidIcon:Hide()
    end
end

local function UpdateLeaderIcon(frame)
    if not frame or not frame.health or not frame.health.leaderIcon then return end

    local settings = TomoModDB.unitFrames[frame.unit]
    if not settings or not settings.showLeaderIcon then
        frame.health.leaderIcon:Hide()
        return
    end
    if not UnitExists(frame.unit) then
        frame.health.leaderIcon:Hide()
        return
    end

    if UnitIsGroupLeader(frame.unit) then
        frame.health.leaderIcon:Show()
    else
        frame.health.leaderIcon:Hide()
    end
end

-- =====================================
-- CHAÎNE DE MISE À JOUR DES DONNÉES (API publique)
-- =====================================
-- Exportée pour que l'aperçu du panneau de configuration puisse alimenter ses
-- cadres avec les VRAIES données de l'unité (lot B). L'aperçu n'appelle jamais
-- lui-même une API d'unité : tout passe par ici, où les valeurs secrètes TWW
-- sont déjà traitées côté C (SetValue / SetFormattedText / SetTexture).
--
-- Prérequis : frame.unit renseigné ET UnitExists(frame.unit) vrai. Les
-- fonctions sortent proprement sinon, mais laissent l'affichage inchangé —
-- l'appelant doit donc tester l'existence de l'unité avant d'appeler.

-- Chaîne légère : valeurs, textes, icônes. Sûre à cadence élevée.
function UF.UpdateUnitData(frame)
    if not frame or not frame.unit then return end
    UpdateHealth(frame)
    UpdateAbsorb(frame)
    if frame.power then E.UpdatePower(frame) end
    E.UpdateInfoBar(frame)
    UpdateName(frame)
    UpdateLevel(frame)
    UpdateThreat(frame)
    UpdateThreatText(frame)
    UpdateRaidIcon(frame)
    UpdateLeaderIcon(frame)
end

-- Chaîne lourde : parcours des auras. À piloter par événement (UNIT_AURA),
-- pas par ticker.
function UF.UpdateUnitAuras(frame)
    if not frame or not frame.unit then return end
    E.UpdateAuras(frame)
    E.UpdateEnemyBuffs(frame)
end

function UF.UpdateAllData(frame)
    UF.UpdateUnitData(frame)
    UF.UpdateUnitAuras(frame)
end

-- =====================================
-- HIDE BLIZZARD EXTRA
-- oUF:DisableBlizzard(unit) est appelé AUTOMATIQUEMENT par oUF:Spawn
-- et gère: PlayerFrame, TargetFrame, FocusFrame, PetFrame.
-- On gère ici les castbars Blizzard et l'overlay d'action bar.
-- =====================================
local function HideBlizzardExtra()
    -- Castbars Blizzard (TWW: PlayerCastingBarFrame, PetCastingBarFrame)
    for _, castName in ipairs({ "PlayerCastingBarFrame", "PetCastingBarFrame" }) do
        local castFrame = _G[castName]
        if castFrame then
            castFrame:UnregisterAllEvents()
            castFrame:Hide()
            castFrame:ClearAllPoints()
            castFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -9999, 9999)
            castFrame:SetAlpha(0)
        end
    end

    -- TWW: ActionBarActionEventsFrame affiche un overlay de cast sur les boutons d'action
    if ActionBarActionEventsFrame then
        local castEvents = {
            "UNIT_SPELLCAST_START",         "UNIT_SPELLCAST_STOP",
            "UNIT_SPELLCAST_FAILED",        "UNIT_SPELLCAST_INTERRUPTED",
            "UNIT_SPELLCAST_DELAYED",       "UNIT_SPELLCAST_CHANNEL_START",
            "UNIT_SPELLCAST_CHANNEL_STOP",  "UNIT_SPELLCAST_CHANNEL_UPDATE",
            "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
        }
        for _, ev in ipairs(castEvents) do
            ActionBarActionEventsFrame:UnregisterEvent(ev)
        end
    end
end

-- =====================================
-- HELPERS PARTAGÉS
-- =====================================

-- Réapplique la texture de barre sans perdre la teinte courante :
-- SetStatusBarTexture remet le vertex color à blanc opaque.
local function ApplyBarTexture(bar, texture)
    if not bar or not bar.SetStatusBarTexture then return end
    local r, g, b, a = bar:GetStatusBarColor()
    bar:SetStatusBarTexture(texture)
    local t = bar:GetStatusBarTexture()
    if t then t:SetHorizTile(false) end
    if r then bar:SetStatusBarColor(r, g, b, a) end
    if bar.bg then bar.bg:SetTexture(texture) end
end

-- Publique : l'aperçu doit pouvoir re-neutraliser un conteneur créé
-- tardivement par E.UpdateEnemyBuffs. Idempotent.
function UF.NeutralizeContainer(container)
    if not container then return end
    container:SetMovable(false)
    container:EnableMouse(false)
    container:RegisterForDrag()
    container:SetScript("OnDragStart", nil)
    container:SetScript("OnDragStop", nil)
    if container.icons then
        for i = 1, #container.icons do
            local icon = container.icons[i]
            if icon then
                icon:EnableMouse(false)
                icon:SetScript("OnEnter", nil)
                icon:SetScript("OnLeave", nil)
            end
        end
    end
end

-- =====================================
-- BUILD VISUALS — construction partagée de l'arbre visuel
-- =====================================
-- Utilisée par StyleTomoMod (frame oUF sécurisée) ET par l'aperçu du panneau
-- de configuration (frame nue, non sécurisée). Ne touche à AUCUN attribut
-- sécurisé, à aucun script de souris et à aucune donnée d'unité : uniquement
-- la construction des widgets à partir de `settings`.
--
-- Conséquence : ce que l'aperçu affiche est produit par les mêmes fabriques
-- que les cadres de jeu — plus de divergence possible entre les deux.
--
-- opts.nameSuffix : suffixe ajouté aux noms globaux des conteneurs d'auras.
--                   Sans lui, l'aperçu écraserait _G["TomoMod_Auras_player"].
-- opts.preview    : neutralise le drag et les tooltips des conteneurs d'auras.
--
-- Renseigne : self.health / self.power / self.infoBar / self.absorb /
--             self.threat / self.threatText / self.auraContainer /
--             self.enemyBuffContainer
-- =====================================

function UF.BuildVisuals(self, unit, settings, opts)
    if not self or not settings then return end

    local suffix    = opts and opts.nameSuffix
    local isPreview = opts and opts.preview

    self:SetSize(settings.width, settings.healthHeight + (settings.powerHeight or 0) + (settings.infoBarHeight or 0))

    -- ── Health ───────────────────────────────────────────────────
    local health = E.CreateHealth(self, unit, settings)
    self.health = health

    -- ── Power ────────────────────────────────────────────────────
    if settings.powerHeight and settings.powerHeight > 0 then
        local power = E.CreatePower(self, unit, settings)
        if power then
            power:SetPoint("TOP", health, "BOTTOM", 0, 0)
            self.power = power
        end
    end

    -- ── Info Bar (bandeau sombre : valeur de ressource + PV totaux) ─
    if settings.infoBarHeight and settings.infoBarHeight > 0 then
        local infoBar = E.CreateInfoBar(self, unit, settings)
        infoBar:SetPoint("TOP", self.power or health, "BOTTOM", 0, 0)
        self.infoBar = infoBar
    end

    -- ── Absorb ───────────────────────────────────────────────────
    if settings.showAbsorb then
        self.absorb = E.CreateAbsorb(self, health, settings)
    end

    -- ── Indicateur de menace glow ────────────────────────────────
    if settings.showThreat then
        self.threat = E.CreateThreatIndicator(health)
    end

    -- ── Texte de menace % ────────────────────────────────────────
    if settings.threatText and settings.threatText.enabled then
        self.threatText = E.CreateThreatText(health, settings)
    end

    -- ── Auras ────────────────────────────────────────────────────
    if settings.auras and settings.auras.enabled then
        self.auraContainer = E.CreateAuraContainer(self, unit, settings,
            suffix and ("TomoMod_Auras_" .. unit .. suffix) or nil)
    end

    -- ── Buffs ennemis ────────────────────────────────────────────
    if settings.enemyBuffs and settings.enemyBuffs.enabled then
        self.enemyBuffContainer = E.CreateEnemyBuffContainer(self, unit, settings,
            suffix and ("TomoMod_EnemyBuffs_" .. unit .. suffix) or nil)
    end

    if isPreview then
        -- Mémorisé sur le cadre : E.UpdateEnemyBuffs peut créer son conteneur
        -- tardivement et doit alors reprendre le même suffixe de nom global.
        self._tomoNameSuffix = suffix
        UF.NeutralizeContainer(self.auraContainer)
        UF.NeutralizeContainer(self.enemyBuffContainer)
    end

    return self
end

-- =====================================
-- oUF STYLE FUNCTION
-- Appelée par oUF:Spawn pour chaque frame créée.
-- self = frame oUF (SecureUnitButtonTemplate)
-- unit = unité ("player", "target", etc.)
-- =====================================
local function StyleTomoMod(self, unit)
    local db = TomoModDB
    if not db or not db.unitFrames then return end
    local settings = db.unitFrames[unit]
    if not settings then return end

    self:SetAttribute("type1", "target")
    self:SetAttribute("type2", "togglemenu")
    self:RegisterForClicks("AnyDown", "AnyUp")

    -- ── Tooltip on hover ─────────────────────────────────────────
    self:SetScript("OnEnter", function(frame)
        GameTooltip_SetDefaultAnchor(GameTooltip, frame)
        GameTooltip:SetUnit(frame:GetAttribute("unit"))
        GameTooltip:Show()
    end)
    self:SetScript("OnLeave", function()
        GameTooltip:FadeOut()
    end)

    -- ── Arbre visuel (partagé avec l'aperçu de configuration) ────
    UF.BuildVisuals(self, unit, settings, nil)

    -- ── Enregistrement oUF ───────────────────────────────────────
    -- Alias canoniques oUF au-dessus des alias TomoMod posés par BuildVisuals.
    self.Health = self.health

    -- Override oUF : remplace le handler par défaut de l'élément Health.
    -- Signature : (parentFrame, event, unit) — self ici = parent frame.
    self.Health.Override = function(oufFrame, event, u)
        UpdateHealth(oufFrame)
        UpdateAbsorb(oufFrame)
        UpdateName(oufFrame)
        UpdateLevel(oufFrame)
        UpdateRaidIcon(oufFrame)
        UpdateLeaderIcon(oufFrame)
        E.UpdateInfoBar(oufFrame)
    end

    if self.power then
        self.Power = self.power
        self.Power.Override = function(oufFrame, event, u)
            E.UpdatePower(oufFrame)
            E.UpdateInfoBar(oufFrame)
        end
    end

    -- ── Drag ─────────────────────────────────────────────────────
    -- La position est appliquée dans Initialize après tous les Spawns.
    TomoMod_Utils.SetupDraggable(self, function()
        if settings.anchorTo and frames[settings.anchorTo] then
            local anchor   = frames[settings.anchorTo]
            local sx, sy   = self:GetCenter()
            local ax, ay   = anchor:GetCenter()
            if sx and sy and ax and ay then
                local dx = sx - ax
                local dy = sy - ay
                self:ClearAllPoints()
                self:SetPoint("CENTER", anchor, "CENTER", dx, dy)
                settings.position = { point = "CENTER", relativePoint = "CENTER", x = dx, y = dy }
            end
        else
            -- [DRAG] screen-absolute coords instead of GetPoint
            local left, bottom = self:GetLeft(), self:GetBottom()
            if left and bottom then
                local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
                settings.position               = settings.position or {}
                settings.position.point         = "BOTTOMLEFT"
                settings.position.relativePoint = "BOTTOMLEFT"
                settings.position.x             = left * scale
                settings.position.y             = bottom * scale
            end
        end
    end)
end

-- =====================================
-- ÉVÉNEMENTS SUPPLÉMENTAIRES
-- oUF gère automatiquement:
--   UNIT_HEALTH, UNIT_MAXHEALTH         → Health.Override
--   UNIT_POWER_UPDATE, UNIT_MAXPOWER    → Power.Override
--   PLAYER_TARGET_CHANGED               → UpdateAllElements sur target
--   PLAYER_FOCUS_CHANGED                → UpdateAllElements sur focus
--   UNIT_PET                            → UpdateAllElements sur pet
--   PLAYER_ENTERING_WORLD               → UpdateAllElements sur tous
--   RegisterUnitWatch                   → visibilité automatique
-- On complète ici: menace, absorbs, auras, icônes.
-- =====================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterEvent("RAID_TARGET_UPDATE")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PARTY_LEADER_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_TARGET_CHANGED" then
        local f = frames.target
        if f then
            UpdateThreat(f)
            UpdateThreatText(f)
            E.UpdateAuras(f)
            E.UpdateEnemyBuffs(f)
        end

    elseif event == "PLAYER_FOCUS_CHANGED" then
        local f = frames.focus
        if f then
            UpdateThreat(f)
            E.UpdateAuras(f)
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Délai C_Timer pour que les données de l'unité soient disponibles
        C_Timer.After(0, function()
            for _, f in pairs(frames) do
                UpdateThreat(f)
                UpdateThreatText(f)
                E.UpdateAuras(f)
                E.UpdateEnemyBuffs(f)
            end
        end)

    elseif event == "UNIT_PET" then
        local f = frames.pet
        if f then E.UpdateAuras(f) end

    elseif event == "RAID_TARGET_UPDATE" then
        for _, f in pairs(frames) do UpdateRaidIcon(f) end

    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LEADER_CHANGED" then
        for _, f in pairs(frames) do UpdateLeaderIcon(f) end
    end
end)

-- ── Événements par unit (menace, absorb, auras) ─────────────────
-- Enregistrés après que les frames soient créées dans Initialize.
local unitSupplementaryFrames = {}

local function RegisterSupplementaryEvents()
    for unit, _ in pairs(frames) do
        if not unitSupplementaryFrames[unit] then
            local uef = CreateFrame("Frame")
            uef:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", unit)
            uef:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED",   unit)
            uef:RegisterUnitEvent("UNIT_AURA",                    unit)
            uef:SetScript("OnEvent", function(_, event, u)
                local frame = frames[u]
                if not frame then return end

                if event == "UNIT_THREAT_SITUATION_UPDATE" then
                    UpdateThreat(frame)
                    UpdateThreatText(frame)
                    -- Rafraîchir la couleur de santé (menace → GetHealthColor)
                    if frame.Health and frame.Health.ForceUpdate then
                        frame.Health:ForceUpdate()
                    else
                        UpdateHealth(frame)
                    end

                elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
                    UpdateAbsorb(frame)

                elseif event == "UNIT_AURA" then
                    E.UpdateAuras(frame)
                    E.UpdateEnemyBuffs(frame)
                end
            end)
            unitSupplementaryFrames[unit] = uef
        end
    end
end

-- =====================================
-- API PUBLIQUE
-- =====================================

function UF.IsLocked()
    return isLocked
end

function UF.ToggleLock()
    -- [TWW] Cadres d'unité protégés : Show / UnitWatch / SetPoint sont bloqués
    -- en combat. On refuse tout (dé)verrouillage tant que le combat est actif
    -- (le mode placement passe normalement par Movers, qui garde déjà l'entrée).
    if InCombatLockdown() then
        print("|cff2ed884TomoMod UF:|r " .. (TomoMod_L["layout_combat_blocked"] or "Impossible de déplacer les cadres en combat."))
        return
    end

    isLocked = not isLocked

    for unit, frame in pairs(frames) do
        if not isLocked then
            -- Déverrouillé: retirer RegisterUnitWatch pour garder la frame visible lors du drag
            if frame.SetLocked then frame:SetLocked(false) end
            UnregisterUnitWatch(frame)
            frame:Show()
            if frame.auraContainer then
                frame.auraContainer:EnableMouse(true)
                frame.auraContainer:Show()
            end
            if frame.enemyBuffContainer then
                frame.enemyBuffContainer:EnableMouse(true)
                frame.enemyBuffContainer:Show()
            end
        else
            -- Verrouillé: réactiver RegisterUnitWatch
            if frame.SetLocked then frame:SetLocked(true) end
            if not InCombatLockdown() then
                frame:SetAttribute("unit", unit)
                RegisterUnitWatch(frame)
            end
            if frame.auraContainer then
                frame.auraContainer:EnableMouse(false)
            end
            if frame.enemyBuffContainer then
                frame.enemyBuffContainer:EnableMouse(false)
            end

            -- Ré-ancrer les frames anchorTo (ToT, Pet) à leur parent avec le bon offset
            local unitSettings = TomoModDB.unitFrames[unit]
            if unitSettings and unitSettings.anchorTo and frames[unitSettings.anchorTo] then
                local pos = unitSettings.position
                frame:ClearAllPoints()
                frame:SetPoint(
                    pos.point or "TOPLEFT",
                    frames[unitSettings.anchorTo],
                    pos.relativePoint or "TOPRIGHT",
                    pos.x or 8,
                    pos.y or 0
                )
            end

            -- Mise à jour complète via oUF si disponible, sinon manuelle
            if UnitExists(unit) then
                if frame.UpdateAllElements then
                    frame:UpdateAllElements("ToggleLock")
                else
                    UF.UpdateAllData(frame)
                end
            end
        end
    end

    if isLocked then
        print("|cff2ed884TomoMod UF:|r " .. TomoMod_L["msg_uf_locked"])
    else
        print("|cff2ed884TomoMod UF:|r " .. TomoMod_L["msg_uf_unlocked"])
    end

    -- Sync BossFrames
    if TomoMod_BossFrames and TomoMod_BossFrames.ToggleLock then
        TomoMod_BossFrames.ToggleLock()
    end
end

-- =====================================
-- APPLY VISUALS — mise en forme partagée (géométrie / textures / polices)
-- =====================================
-- Deuxième moitié du moteur partagé : tout ce qui peut être réappliqué à
-- chaud sur un arbre déjà construit, sans lire la moindre donnée d'unité.
-- Appelée par UF.RefreshUnit (cadres de jeu) ET par l'aperçu du panneau.
-- Les changements STRUCTURELS (activer/désactiver une barre, un conteneur
-- d'auras) restent du ressort de BuildVisuals — /reload en jeu, reconstruction
-- immédiate côté aperçu.
-- =====================================
function UF.ApplyVisuals(frame, unitKey, settings)
    if not frame or not settings then return end

    local globalDB    = TomoModDB.unitFrames
    local font        = globalDB.fontFamily or globalDB.font or "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
    local fontSize    = globalDB.fontSize or 12
    local fontOutline = globalDB.fontOutline or "OUTLINE"

    frame:SetSize(settings.width, settings.healthHeight + (settings.powerHeight or 0) + (settings.infoBarHeight or 0))
    frame.health:SetSize(settings.width, settings.healthHeight)

    if frame.health.text     then frame.health.text:SetFont(font, fontSize,     fontOutline) end
    if frame.health.nameText then frame.health.nameText:SetFont(font, fontSize - 1, fontOutline) end
    if frame.health.levelText then frame.health.levelText:SetFont(font, fontSize - 2, fontOutline) end

    if frame.power and settings.powerHeight then
        frame.power:SetSize(settings.width, settings.powerHeight)
        if frame.power.text then frame.power.text:SetFont(font, 8, fontOutline) end
    end

    if frame.infoBar and settings.infoBarHeight then
        frame.infoBar:SetSize(settings.width, settings.infoBarHeight)
        if frame.infoBar.powerText then frame.infoBar.powerText:SetFont(font, fontSize - 1, fontOutline) end
        if frame.infoBar.hpText    then frame.infoBar.hpText:SetFont(font, fontSize - 1, fontOutline) end
    end

    -- Texture des barres — n'était lue qu'à la création (CreateHealth /
    -- CreatePower), donc changer de texture demandait un /reload. Réappliquée
    -- à chaud ici. La couleur est reposée juste après par UpdateHealth /
    -- UpdatePower (SetStatusBarTexture remet la teinte à blanc).
    local barTex = globalDB.texture
    if barTex then
        ApplyBarTexture(frame.health,  barTex)
        ApplyBarTexture(frame.power,   barTex)
        ApplyBarTexture(frame.absorb,  barTex)
    end

    -- Texte de menace : créé si l'option vient d'être activée. Sa POSITION
    -- est posée plus bas par le registre, comme tous les autres éléments —
    -- ici on ne s'occupe que de la police.
    if not frame.threatText and settings.threatText and settings.threatText.enabled then
        frame.threatText = E.CreateThreatText(frame.health, settings)
    end
    if frame.threatText then
        local tt = settings.threatText
        frame.threatText:SetFont(font, (tt and tt.fontSize) or 13, fontOutline)
    end

    -- ── Position des éléments (AstralForge) ──────────────────────────
    -- Un seul point d'application : le registre lit `settings.elements` et
    -- pose chaque élément (nom, niveau, texte de vie, barre de ressource,
    -- icônes de raid / chef, texte de menace). Ensure() comble les entrées
    -- absentes depuis les valeurs par défaut du registre, ce qui couvre les
    -- profils importés et les resets partiels sans passer par la DB.
    local UFE = TomoMod_UFElements
    if UFE then
        if type(settings.elements) ~= "table" then settings.elements = {} end
        UFE.Ensure(settings.elements)
        UFE.ApplyAll(frame, settings.elements)
        UFE.RefreshCustomTexts(frame, settings.elements)
    end

    -- Les deux conteneurs d'auras sont desormais des elements du registre
    -- comme les autres : plus de branche dediee ici, et le drag en jeu ecrit
    -- au meme endroit (UF_Elements.SaveContainerDrag).

    -- Redimensionner les icônes d'aura puis ré-appliquer la grille (même layout
    -- qu'à la création — évite toute incohérence de taille/espacement entre unités).
    if frame.auraContainer and frame.auraContainer.icons and settings.auras then
        local auraSize     = settings.auras.size or 30
        local hideCountdown = not settings.auras.showDuration
        for _, icon in ipairs(frame.auraContainer.icons) do
            icon:SetSize(auraSize, auraSize)
            if icon.texture then icon.texture:SetAllPoints(icon) end
            -- showDuration n'était appliqué qu'à la création : un /reload était
            -- nécessaire pour voir le changement. Réappliqué à chaud ici.
            if icon.cooldown then icon.cooldown:SetHideCountdownNumbers(hideCountdown) end
        end
        if E and E.LayoutAuraGrid then
            E.LayoutAuraGrid(frame.auraContainer, settings.auras)
        end
    end

    -- Icônes de buffs ennemis : idem pour le décompte.
    if frame.enemyBuffContainer and frame.enemyBuffContainer.icons and settings.enemyBuffs then
        local hideCountdown = not settings.enemyBuffs.showDuration
        for _, icon in ipairs(frame.enemyBuffContainer.icons) do
            if icon.cooldown then icon.cooldown:SetHideCountdownNumbers(hideCountdown) end
        end
    end
end

-- =====================================
-- REFRESH UNIT — ApplyVisuals + rafraîchissement des données réelles
-- =====================================
function UF.RefreshUnit(unitKey)
    local frame    = frames[unitKey]
    local settings = TomoModDB.unitFrames[unitKey]
    if not frame or not settings then return end

    UF.ApplyVisuals(frame, unitKey, settings)

    -- Enemy Buff Container
    if settings.enemyBuffs then
        local eb = frame.enemyBuffContainer
        if eb then
            local wantedEnabled = settings.enemyBuffs.enabled
            local wantedSize    = settings.enemyBuffs.size     or 24
            local wantedMax     = settings.enemyBuffs.maxAuras or 4
            local currentSize   = eb._tomoSize    or 0
            local currentMax    = eb._tomoMaxAuras or 0
            if not wantedEnabled then
                eb:Hide()
            elseif currentSize ~= wantedSize or currentMax ~= wantedMax then
                eb:Hide()
                eb:SetParent(nil)
                frame.enemyBuffContainer = nil
                E.UpdateEnemyBuffs(frame)
            end
        elseif settings.enemyBuffs.enabled then
            E.UpdateEnemyBuffs(frame)
        end
    end

    -- Mise à jour visuelle via oUF:UpdateAllElements si disponible
    if frame.UpdateAllElements then
        frame:UpdateAllElements("RefreshUnit")
    else
        UF.UpdateAllData(frame)
    end

    -- Re-anchor standalone castbar to this UF frame (if applicable)
    if TomoMod_Castbar and TomoMod_Castbar.castbars and TomoMod_Castbar.castbars[unitKey] then
        local cb = TomoMod_Castbar.castbars[unitKey]
        if cb.ReanchorToUF then cb:ReanchorToUF() end
    end
end

-- Preview de la menace (appelé par ConfigUI OnShow/OnHide)
function UF.RefreshThreatPreview(enabled)
    local targetFrame = frames["target"]
    if not targetFrame or not targetFrame.threatText then return end
    local settings = TomoModDB.unitFrames and TomoModDB.unitFrames["target"]
    local tt = settings and settings.threatText
    if not tt or not tt.enabled then return end
    UpdateThreatText(targetFrame, enabled and true or false)
end

function UF.RefreshAllUnits()
    for _, unitKey in ipairs({ "player", "target", "focus", "targettarget", "pet" }) do
        if frames[unitKey] then
            UF.RefreshUnit(unitKey)
        end
    end
    if TomoMod_BossFrames and TomoMod_BossFrames.RefreshAll then
        TomoMod_BossFrames.RefreshAll()
    end
end

-- =====================================
-- INITIALIZE — Spawn des frames via oUF:Factory
-- oUF:Factory s'exécute immédiatement puisqu'on est
-- dans le handler PLAYER_LOGIN de Init.lua (IsLoggedIn() = true).
-- =====================================
function UF.Initialize()
    if not TomoModDB or not TomoModDB.unitFrames then return end
    if not TomoModDB.unitFrames.enabled then return end

    local oUF = TomoMod_oUF
    if not oUF then
        print("|cffff0000TomoMod UF:|r Bibliothèque oUF introuvable (X-oUF: TomoMod_oUF)!")
        return
    end

    oUF:Factory(function(ouf)
        -- Enregistrer le style et l'activer avant tout Spawn
        ouf:RegisterStyle("TomoMod", StyleTomoMod)
        ouf:SetActiveStyle("TomoMod")

        -- Spawn des frames actives dans l'ordre de construction
        local buildOrder = { "player", "target", "focus", "targettarget", "pet" }
        for _, unit in ipairs(buildOrder) do
            local settings = TomoModDB.unitFrames[unit]
            if settings and settings.enabled then
                -- ouf:Spawn crée la frame, appelle StyleTomoMod,
                -- puis appelle oUF:DisableBlizzard(unit) automatiquement.
                local f = ouf:Spawn(unit, "TomoMod_UF_" .. unit)
                frames[unit] = f
            end
        end

        -- ── Positionnement initial ──────────────────────────────────
        -- Frames autonomes (player, target, focus) → ancrées à UIParent
        for _, unit in ipairs({ "player", "target", "focus" }) do
            local f        = frames[unit]
            local settings = TomoModDB.unitFrames[unit]
            if f and settings and settings.position then
                local pos = settings.position
                f:ClearAllPoints()
                f:SetPoint(
                    pos.point or "CENTER", UIParent,
                    pos.relativePoint or "CENTER",
                    pos.x or 0, pos.y or 0
                )
            end
        end

        -- Frames ancrées (ToT → Target, Pet → Player)
        for _, unit in ipairs({ "targettarget", "pet" }) do
            local f        = frames[unit]
            local settings = TomoModDB.unitFrames[unit]
            if f and settings then
                if settings.anchorTo and frames[settings.anchorTo] then
                    local pos = settings.position
                    f:ClearAllPoints()
                    f:SetPoint(
                        pos.point or "TOPLEFT",
                        frames[settings.anchorTo],
                        pos.relativePoint or "TOPRIGHT",
                        pos.x or 8, pos.y or 0
                    )
                elseif settings.position then
                    local pos = settings.position
                    f:ClearAllPoints()
                    f:SetPoint(
                        pos.point or "CENTER", UIParent,
                        pos.relativePoint or "CENTER",
                        pos.x or 0, pos.y or 0
                    )
                end
            end
        end

        -- ── Castbars Blizzard + ActionBar cast overlay ──────────────
        if TomoModDB.unitFrames.hideBlizzardFrames then
            HideBlizzardExtra()
        end

        -- ── Événements supplémentaires (menace, absorb, auras) ──────
        RegisterSupplementaryEvents()

        -- ── Updater de durée des auras ──────────────────────────────
        E.StartAuraDurationUpdater(frames)

        -- ── Appliquer tailles, polices et offsets ───────────────────
        UF.RefreshAllUnits()

        print("|cff2ed884TomoMod UF:|r " .. TomoMod_L["msg_uf_initialized"])
    end)
end

-- =====================================
-- ENREGISTREMENT DU MODULE
-- =====================================
TomoMod_RegisterModule("unitFrames", UF)

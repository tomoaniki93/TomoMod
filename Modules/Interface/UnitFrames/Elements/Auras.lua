-- =====================================
-- Elements/Auras.lua — Aura Icons for UnitFrames
-- =====================================

local UF_Elements = UF_Elements or {}

local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"

-- The collect buffer and the pre-computed filter sets are gone with the scan
-- they served: the engine enumerates and filters auras itself.
--
-- Worth noting what went with them: the old filter table had ALL, which
-- scanned HARMFUL and HELPFUL and merged the results. An aura group carries
-- one filter, so `type = "ALL"` now falls to HARMFUL. Restoring it means two
-- groups on the same container, not a filter string.

-- =====================================
-- LAYOUT EN GRILLE (avec retour à la ligne)
-- =====================================
-- Place les icônes de gauche à droite (ou droite à gauche) et passe à la ligne
-- quand la largeur prédéfinie est dépassée. Redimensionne le conteneur à la
-- hauteur du nombre de rangées obtenu.

-- =====================================
-- CREATE AURA CONTAINER
-- =====================================

-- nameOverride : nom global alternatif. L'aperçu de configuration construit
-- de vrais conteneurs d'auras ; sans ce paramètre il écraserait
-- _G["TomoMod_Auras_player"], que le module Movers utilise.
-- =====================================
-- SAUVEGARDE DU DRAG D'UN CONTENEUR (AstralForge)
-- =====================================
-- Point unique de sauvegarde pour les deux conteneurs. Ecrit un
-- enregistrement d'element, comme le canvas du studio : le glisser en jeu,
-- le glisser dans le studio et les curseurs de la config ecrivent donc tous
-- au meme endroit et ne peuvent plus diverger.
--
-- La mesure passe par Forge.Canvas.ComputeOffset quand il est disponible :
-- elle convertit en pixels ecran via les echelles effectives, donc elle
-- survit a un SetScale sur le cadre. Le repli GetCenter reproduit l'ancien
-- calcul, valable tant qu'aucune echelle n'est en jeu.
--
-- Jamais de GetPoint() : c'est la regle du mover.
function UF_Elements.SaveContainerDrag(container, parent, elementID, settings)
    if not (container and parent and settings) then return false end

    local R = TomoMod_Forge and TomoMod_Forge.Registry
    local C = TomoMod_Forge and TomoMod_Forge.Canvas
    local UFE = TomoMod_UFElements
    if not (R and UFE) then return false end

    if type(settings.elements) ~= "table" then settings.elements = {} end
    UFE.Ensure(settings.elements)

    local rec = settings.elements[elementID]
    if type(rec) ~= "table" then
        rec = R.Default(UFE.DOMAIN, elementID)
        settings.elements[elementID] = rec
    end

    local target = R.ResolveTarget(UFE.DOMAIN, rec.relTo, parent) or parent

    local dx, dy
    if C and C.ComputeOffset then
        dx, dy = C.ComputeOffset(container, target, rec.point, rec.relPoint)
    end
    if not dx then
        local sx, sy = container:GetCenter()
        local px, py = target.GetCenter and target:GetCenter()
        if not (sx and px) then return false end
        rec.point, rec.relPoint = "CENTER", "CENTER"
        dx, dy = sx - px, sy - py
    end

    rec.x, rec.y = dx, dy
    container:ClearAllPoints()
    container:SetPoint(rec.point, target, rec.relPoint, rec.x, rec.y)
    return true
end

function UF_Elements.CreateAuraContainer(parent, unit, settings, nameOverride)
    if not settings or not settings.auras or not settings.auras.enabled then return nil end

    local auraSettings = settings.auras
    local container = CreateFrame("Frame", nameOverride or ("TomoMod_Auras_" .. unit), parent)
    -- Largeur de référence pour le calcul de la grille (réglage explicite sinon 300).
    local refWidth = (auraSettings.maxWidth and auraSettings.maxWidth > 0) and auraSettings.maxWidth or 300
    container:SetSize(refWidth, auraSettings.size + 4)
    container.unit = unit
    container.parentFrame = parent

    -- Position de construction uniquement : la position finale vient du
    -- registre AstralForge (UF.ApplyVisuals -> UFE.ApplyAll), qui passe
    -- systematiquement apres.
    container:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, 6)

    -- [12.1] The icons come from the client's aura engine now. The host
    -- frame above is kept as-is -- it is what AstralForge positions, what
    -- the drag handlers move and what UFElements resolves by name -- and the
    -- engine container simply fills it.
    local AC = TomoMod_AuraContainer
    if AC then
        container.engine = AC.Create(container, {
            key      = "auras",
            unit     = unit,
            size     = auraSettings.size or 24,
            max      = auraSettings.maxAuras or 8,
            -- The module FONT constant, not auraSettings.font: there is no
            -- such setting, and the initializer calls SetFont unprotected --
            -- a nil font errors inside the engine, on every container.
            font     = FONT,
            -- The setting is `type`, not `auraType`. Reading the wrong name
            -- made this nil, which is not "HELPFUL", so every container came
            -- out harmful regardless of what the user chose.
            harmful  = (auraSettings.type ~= "HELPFUL"),
            -- "ALL" wants both polarities. A group carries one filter, so
            -- the container gets a second group rather than a merged string.
            both     = (auraSettings.type == "ALL"),
            onlyMine = auraSettings.showOnlyMine,
            -- Restored: the engine shows aura tooltips itself, and the
            -- setting drives the swipe's countdown digits.
            tooltips     = true,
            showDuration = auraSettings.showDuration ~= false,
            point    = { "TOPLEFT", container, "TOPLEFT", 0, 0 },
        })
    end

    -- Draggable support (uses global lock state)
    container:SetMovable(true)
    container:SetClampedToScreen(true)
    container:EnableMouse(false)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    container:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        UF_Elements.SaveContainerDrag(self, parent, "auras", settings)
    end)

    -- SetLocked(bool) — appelé par le système Movers pour activer/désactiver le drag
    function container:SetLocked(locked)
        self:EnableMouse(not locked)
        self:SetMovable(not locked)
        -- Overlay visuel teal quand déverrouillé (comme les autres movers)
        if not self._moverOverlay then
            local ov = CreateFrame("Frame", nil, self)
            ov:SetAllPoints()
            ov:SetFrameLevel(self:GetFrameLevel() + 5)
            local t = ov:CreateTexture(nil, "OVERLAY")
            t:SetAllPoints()
            t:SetColorTexture(0.05, 0.82, 0.62, 0.20)
            local lbl = ov:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 9, "OUTLINE")
            lbl:SetTextColor(0.05, 0.82, 0.62, 1)
            lbl:SetPoint("CENTER")
            lbl:SetText("Auras")
            self._moverOverlay = ov
        end
        if locked then self._moverOverlay:Hide() else self._moverOverlay:Show() end
    end

    return container
end

-- =====================================
-- CREATE SINGLE AURA ICON
-- =====================================


-- =====================================
-- UPDATE AURAS
-- =====================================

function UF_Elements.UpdateAuras(frame)
    if not frame or not frame.auraContainer then return end

    local unit = frame.unit
    local container = frame.auraContainer
    local settings = TomoModDB.unitFrames[unit]

    if not settings or not settings.auras or not settings.auras.enabled
        or not UnitExists(unit) then
        container:Hide()
        return
    end

    container:Show()

    -- [12.1] Nothing to collect: the engine tracks the unit itself. Telling
    -- it which unit this frame now represents is the whole update.
    if container.engine then
        TomoMod_AuraContainer.SetUnit(container.engine, unit)
    end
end

-- =====================================
-- ENEMY BUFF CONTAINER (shows HELPFUL auras on enemy units)
-- =====================================

-- nameOverride : voir CreateAuraContainer.
function UF_Elements.CreateEnemyBuffContainer(parent, unit, settings, nameOverride)
    if not settings or not settings.enemyBuffs or not settings.enemyBuffs.enabled then return nil end

    local buffSettings = settings.enemyBuffs
    local size = buffSettings.size or 24
    local spacing = buffSettings.spacing or 2
    local maxAuras = buffSettings.maxAuras or 4

    -- Grille : 3 icônes par ligne, remplissage droite → gauche, lignes vers le haut
    --   Ligne 0 (bas) :  icône 1 (droite)  icône 2 (milieu)  icône 3 (gauche)
    --   Ligne 1       :  icône 4 (droite)  …
    local ICONS_PER_ROW = 3
    local numRows = math.ceil(maxAuras / ICONS_PER_ROW)

    -- Largeur  = 3 icônes + 2 espacements
    -- Hauteur  = nb lignes × (icône + espacement)
    local containerW = ICONS_PER_ROW * size + (ICONS_PER_ROW - 1) * spacing
    local containerH = numRows * size + (numRows - 1) * spacing

    local container = CreateFrame("Frame", nameOverride or ("TomoMod_EnemyBuffs_" .. unit), parent)
    container:SetSize(containerW, containerH)
    container:SetFrameLevel(parent:GetFrameLevel() + 10)
    container.unit = unit
    container.parentFrame = parent
    -- Stocker les paramètres courants pour détecter les changements dans RefreshUnit
    container._tomoSize     = size
    container._tomoMaxAuras = maxAuras

    -- Position de construction uniquement : cf. CreateAuraContainer.
    container:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", 0, 6)

    -- Création des icônes en grille  (droite → gauche, bas → haut)
    --   col 0 = droite, col 1 = milieu, col 2 = gauche
    --   row 0 = ligne du bas, row 1 = ligne au-dessus, …
    local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
    -- [12.1] Same handover as the aura container above: the host frame keeps
    -- its position and drag behaviour, the engine fills it with buttons.
    local AC = TomoMod_AuraContainer
    if AC then
        container.engine = AC.Create(container, {
            key     = "enemybuffs",
            unit    = unit,
            size    = size,
            max     = maxAuras,
            -- Same reason as the aura container: the initializer's SetFont is
            -- unprotected, so this cannot be left out.
            font    = FONT,
            harmful      = false,
            tooltips     = true,
            showDuration = (settings.enemyBuffs and settings.enemyBuffs.showDuration) ~= false,
            point   = { "TOPLEFT", container, "TOPLEFT", 0, 0 },
        })
    end

    -- Draggable
    container:SetMovable(true)
    container:SetClampedToScreen(true)
    container:EnableMouse(false)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart", function(self) self:StartMoving() end)
    container:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        UF_Elements.SaveContainerDrag(self, parent, "enemyBuffs", settings)
    end)

    return container
end

-- =====================================
-- UPDATE TARGET BUFFS (HELPFUL auras on target/focus)
-- Uses GetAuraSlots + select() to safely iterate varargs.
-- AuraUtil.ForEachAura CANNOT be used — it calls UnpackAuraData
-- which crashes on secret values in TWW.
-- Shows all HELPFUL auras on ANY target (enemy, friendly, neutral).
-- =====================================

-- Debug: toggle with /tm debugbuffs
UF_Elements._debugEnemyBuffs = false

function UF_Elements.UpdateEnemyBuffs(frame)
    if not frame then return end

    local unit = frame.unit
    -- Only process target and focus (no point for player/pet/targettarget)
    if unit ~= "target" and unit ~= "focus" then return end

    local settings = TomoModDB.unitFrames[unit]
    local container = frame.enemyBuffContainer

    if not settings or not settings.enemyBuffs or not settings.enemyBuffs.enabled
        or not UnitExists(unit) or not container then
        if container then container:Hide() end
        return
    end

    container:Show()

    -- [12.1] The engine tracks the unit; there is nothing to collect.
    if container.engine then
        TomoMod_AuraContainer.SetUnit(container.engine, unit)
    end
end

-- =====================================
-- DURATION UPDATER TICKER
-- =====================================

local auraDurationTicker
function UF_Elements.StartAuraDurationUpdater(frames)
    -- TWW: the Cooldown frame's built-in countdown numbers self-update C-side
    -- via SetCooldownFromDurationObject, so no Lua ticker is needed anymore.
    -- Kept as a no-op for backwards compatibility with callers.
end
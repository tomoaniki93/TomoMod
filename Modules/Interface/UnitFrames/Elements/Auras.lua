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
        local px, py
        if target.GetCenter then px, py = target:GetCenter() end
        if not (sx and sy and px and py) then return false end
        rec.point, rec.relPoint = "CENTER", "CENTER"
        dx, dy = sx - px, sy - py
    end

    rec.x, rec.y = dx, dy
    container:ClearAllPoints()
    container:SetPoint(rec.point, target, rec.relPoint, rec.x, rec.y)
    return true
end

-- Même grille perRow que ComputeEnemyBuffLayout, pour les
-- auras normales (buffs/debuffs joueur, cible, focus). Un seul calcul pour
-- Create et Relayout : cf. le commentaire sur ComputeEnemyBuffLayout pour
-- pourquoi ça doit rester un point unique.
local MAX_AURA_ICONS = 12

local function NormalizeAuraType(value)
    if value == "HELPFUL" or value == "ALL" then return value end
    return "HARMFUL"
end

function UF_Elements.AurasShowBoth(settings)
    return type(settings) == "table"
        and type(settings.auras) == "table"
        and settings.auras.enabled ~= false
        and NormalizeAuraType(settings.auras.type) == "ALL"
end

local function ComputeAuraLayout(auraSettings)
    local size = auraSettings.size or 24
    local spacing = auraSettings.spacing or 3
    local maxAuras = math.max(1, math.min(MAX_AURA_ICONS,
        math.floor(tonumber(auraSettings.maxAuras) or 8)))
    local growDirection = auraSettings.growDirection
    local growVertical = auraSettings.growVertical
    local perRow = math.max(1, math.min(MAX_AURA_ICONS,
        math.floor(tonumber(auraSettings.perRow) or 6)))

    local numRows = math.ceil(maxAuras / perRow)
    local numCols = math.min(perRow, maxAuras)

    local containerW = numCols * size + (numCols - 1) * spacing
    local containerH = numRows * size + (numRows - 1) * spacing

    return {
        size = size, spacing = spacing, maxAuras = maxAuras, perRow = perRow,
        growDirection = growDirection, growVertical = growVertical,
        containerW = containerW, containerH = containerH,
    }
end

local function CreateAuraEngine(container, unit, auraSettings, layout)
    local AC = TomoMod_AuraContainer
    if not AC then return nil end

    local auraType = NormalizeAuraType(auraSettings.type)
    return AC.Create(container, {
        key      = "auras",
        unit     = unit,
        size     = layout.size,
        max      = layout.maxAuras,
        font     = FONT,
        harmful  = (auraType ~= "HELPFUL"),
        both     = (auraType == "ALL"),
        onlyMine = auraSettings.showOnlyMine,
        tooltips     = true,
        showDuration = auraSettings.showDuration ~= false,
        durationPoint = "CENTER",
        durationX     = 0,
        durationY     = 0,
        durationColor = { 1, 1, 1, 1 },
        growDirection = layout.growDirection,
        growVertical  = layout.growVertical,
        rowWidth      = layout.containerW,
        spacing       = layout.spacing,
        anchorHost = container,
    })
end

function UF_Elements.CreateAuraContainer(parent, unit, settings, nameOverride)
    if not settings or not settings.auras or not settings.auras.enabled then return nil end

    local auraSettings = settings.auras
    local layout = ComputeAuraLayout(auraSettings)
    local container = CreateFrame("Frame", nameOverride or ("TomoMod_Auras_" .. unit), parent)
    container:SetSize(layout.containerW, layout.containerH)
    container.unit = unit
    container.parentFrame = parent

    -- Position de construction uniquement : la position finale vient du
    -- registre AstralForge (UF.ApplyVisuals -> UFE.ApplyAll), qui passe
    -- systematiquement apres.
    container:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, 6)

    -- The Forge host remains stable while the native engine child may be
    -- replaced when its Buff/Debuff filter changes.
    container.engine = CreateAuraEngine(container, unit, auraSettings, layout)
    container._tomoAuraType = NormalizeAuraType(auraSettings.type)
    container._tomoAuraOnlyMine = auraSettings.showOnlyMine and true or false

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
            if TomoMod_Utils and TomoMod_Utils.RegisterMoverLayer then
                TomoMod_Utils.RegisterMoverLayer(ov, self)
            end
            ov:SetFrameLevel(self:GetFrameLevel() + 5)
            local t = ov:CreateTexture(nil, "OVERLAY")
            t:SetAllPoints()
            t:SetColorTexture(0.18, 0.62, 0.85, 0.20)
            local lbl = ov:CreateFontString(nil, "OVERLAY")
            TomoMod_Utils.StyleMoverLabel(lbl, 9)
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


-- Réapplique en direct taille / nombre / direction / largeur de ligne sur
-- un conteneur d'auras déjà construit, sans reconstruction complète : cf.
-- UF_Elements.RelayoutEnemyBuffs pour le pourquoi (Relayout ignorait ces
-- champs tant que la taille/le nombre ne changeaient pas aussi).
function UF_Elements.RelayoutAuras(container, auraSettings)
    if not container or not auraSettings then return false end
    local layout = ComputeAuraLayout(auraSettings)
    container:SetSize(layout.containerW, layout.containerH)
    local auraType = NormalizeAuraType(auraSettings.type)
    local onlyMine = auraSettings.showOnlyMine and true or false

    -- Native AuraGroups are add-only. Changing polarity or the PLAYER filter
    -- therefore replaces only the engine child while preserving the Forge
    -- host frame, its position and its mover registration.
    if not container.engine or container._tomoAuraType ~= auraType
        or container._tomoAuraOnlyMine ~= onlyMine then
        local oldEngine = container.engine
        if oldEngine then
            if TomoMod_AuraContainer and TomoMod_AuraContainer.SetUnit then
                TomoMod_AuraContainer.SetUnit(oldEngine, nil)
            end
            oldEngine:Hide()
        end
        container.engine = CreateAuraEngine(container, container.unit,
            auraSettings, layout)
        container._tomoAuraType = auraType
        container._tomoAuraOnlyMine = onlyMine
        return container.engine ~= nil
    end

    TomoMod_AuraContainer.Relayout(container.engine, {
        size = layout.size, max = layout.maxAuras,
        growDirection = layout.growDirection, growVertical = layout.growVertical,
        rowWidth = layout.containerW,
        showDuration = auraSettings.showDuration ~= false,
    })
    return true
end

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
    UF_Elements.RelayoutAuras(container, settings.auras)

    -- [12.1] Nothing to collect: the engine tracks the unit itself. Telling
    -- it which unit this frame now represents is the whole update.
    if container.engine then
        TomoMod_AuraContainer.SetUnit(container.engine, unit)
    end
end

-- =====================================
-- ENEMY BUFF CONTAINER (shows HELPFUL auras on enemy units)
-- =====================================

-- Grille : perRow icônes par ligne, remplissage droite → gauche (ou
-- l'inverse selon growDirection), lignes vers le haut ou le bas selon
-- growVertical. Le total est borné à 12 icônes, donc le nombre de lignes
-- peut suivre fidèlement `perRow` sans croissance illimitée.
--
-- Point unique pour ce calcul : Create et le relayout en direct (settings
-- modifiés sans reload) doivent produire exactement les mêmes chiffres,
-- sinon l'un des deux dérive silencieusement de l'autre.
local function ComputeEnemyBuffLayout(buffSettings)
    local size = buffSettings.size or 24
    local spacing = buffSettings.spacing or 2
    local maxAuras = math.max(1, math.min(MAX_AURA_ICONS,
        math.floor(tonumber(buffSettings.maxAuras) or 4)))
    local growDirection = buffSettings.growDirection or "RIGHT"
    local growVertical = buffSettings.growVertical or "UP"
    local perRow = math.max(1, math.min(MAX_AURA_ICONS,
        math.floor(tonumber(buffSettings.perRow) or 3)))

    local numRows = math.ceil(maxAuras / perRow)
    local numCols = math.min(perRow, maxAuras)

    local containerW = numCols * size + (numCols - 1) * spacing
    local containerH = numRows * size + (numRows - 1) * spacing

    return {
        size = size, spacing = spacing, maxAuras = maxAuras, perRow = perRow,
        growDirection = growDirection, growVertical = growVertical,
        containerW = containerW, containerH = containerH,
    }
end

-- nameOverride : voir CreateAuraContainer.
function UF_Elements.CreateEnemyBuffContainer(parent, unit, settings, nameOverride)
    if not settings or not settings.enemyBuffs or not settings.enemyBuffs.enabled
        or UF_Elements.AurasShowBoth(settings) then return nil end

    local layout = ComputeEnemyBuffLayout(settings.enemyBuffs)

    local container = CreateFrame("Frame", nameOverride or ("TomoMod_EnemyBuffs_" .. unit), parent)
    container:SetSize(layout.containerW, layout.containerH)
    container:SetFrameLevel(parent:GetFrameLevel() + 10)
    container.unit = unit
    container.parentFrame = parent

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
            size    = layout.size,
            max     = layout.maxAuras,
            -- Same reason as the aura container: the initializer's SetFont is
            -- unprotected, so this cannot be left out.
            font    = FONT,
            harmful      = false,
            tooltips     = true,
            showDuration = (settings.enemyBuffs and settings.enemyBuffs.showDuration) ~= false,
            -- Where the swipe digits used to sit, so dropping them changes
            -- nothing on screen.
            durationPoint = "CENTER",
            durationX     = 0,
            durationY     = 0,
            durationColor = { 1, 1, 1, 1 },
            growDirection = layout.growDirection,
            growVertical  = layout.growVertical,
            rowWidth      = layout.containerW,
            spacing       = layout.spacing,
            -- Anchor corner tracks growDirection/growVertical: see
            -- HORIZONTAL_ANCHOR/VERTICAL_ANCHOR in AuraContainer.lua.
            anchorHost = container,
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

-- Réapplique en direct taille / nombre / direction / lignes par ligne sur un
-- conteneur déjà construit — appelé aussi bien par le rafraîchissement
-- explicite (options) que par la mise à jour événementielle (UNIT_AURA),
-- pour qu'un changement de réglage n'ait jamais besoin d'un /reload.
function UF_Elements.RelayoutEnemyBuffs(container, buffSettings)
    if not container or not container.engine or not buffSettings then return end
    local layout = ComputeEnemyBuffLayout(buffSettings)
    container:SetSize(layout.containerW, layout.containerH)
    TomoMod_AuraContainer.Relayout(container.engine, {
        size = layout.size, max = layout.maxAuras,
        growDirection = layout.growDirection, growVertical = layout.growVertical,
        rowWidth = layout.containerW,
    })
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
        or UF_Elements.AurasShowBoth(settings)
        or not UnitExists(unit) then
        if container then container:Hide() end
        return
    end

    -- Créé tardivement : le conteneur peut manquer si l'unité l'a d'abord
    -- construit désactivé, ou après le hide/relayout d'un ancien profil.
    if not container then
        container = UF_Elements.CreateEnemyBuffContainer(frame, unit, settings,
            frame._tomoNameSuffix and ("TomoMod_EnemyBuffs_" .. unit .. frame._tomoNameSuffix) or nil)
        frame.enemyBuffContainer = container
        if not container then return end
    else
        UF_Elements.RelayoutEnemyBuffs(container, settings.enemyBuffs)
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

-- =====================================
-- ConsumableBar.lua — Barre de consommables
-- Flask (1h) | Bien Nourri (1h)
-- Affiche l'icône + timer restant pour chaque consommable actif.
-- Intégré au système de placement (Movers) et au GUI QOL.
-- =====================================

TomoMod_ConsumableBar = TomoMod_ConsumableBar or {}
local CB = TomoMod_ConsumableBar

local pcall, ipairs = pcall, ipairs
local floor, format = math.floor, string.format
local GetTime = GetTime
local issecretvalue = issecretvalue

-- =====================================
-- CONSTANTES
-- =====================================

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local TEAL      = { r = 0.047, g = 0.824, b = 0.624 }

-- Spell IDs des Flacons (durée 1h = 3600 s)
local FLASK_IDS = {
    [1235111] = true,   -- flask-of-the-shattered-sun
    [1235057] = true,   -- flask-of-thalassian-resistance
    [1235108] = true,   -- flask-of-the-magisters
    [1235110] = true,   -- flask-of-the-blood-knights
}

-- Plage de durée pour détecter un buff de nourriture (entre 50 min et 62 min)
local FOOD_DUR_MIN = 3000
local FOOD_DUR_MAX = 3720

-- Placeholder icon pour le slot nourriture (inv_misc_food_15)
local ICON_FOOD_DEFAULT = "Interface\\Icons\\inv_misc_food_15"

-- Durées de prévisualisation (mode placement)
local PREVIEW_TIMES = {
    flask = 3480,   -- "58m"
    food  = 2700,   -- "45m"
}

-- =====================================
-- STATE
-- =====================================

local frame         = nil
local slots         = nil       -- { { key, frame, defaultIcon }, ... }
local dragOverlay   = nil
local dragLabel     = nil
local isLocked      = true
local updateTicker  = nil
local initialized   = false
local L             = nil

-- Données live des buffs (nil = pas actif)
local buffData = {
    flask = nil,    -- { icon, expirationTime, spellID }
    food  = nil,
}

-- =====================================
-- HELPERS
-- =====================================

local function DB()
    return TomoModDB and TomoModDB.consumableBar
end

local function GetSpellIconSafe(spellID)
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, tex = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and tex then return tex end
    end
    if GetSpellInfo then
        local ok, _, _, tex = pcall(GetSpellInfo, spellID)
        if ok and tex then return tex end
    end
    return nil
end

local function FormatTime(sec)
    if sec >= 3600 then
        local h = floor(sec / 3600)
        local m = floor((sec % 3600) / 60)
        return format("%dh %02dm", h, m)
    elseif sec >= 60 then
        return format("%dm", floor(sec / 60))
    else
        return format("%ds", floor(sec))
    end
end

local function SavePosition()
    local db = DB()
    if not db or not frame then return end
    -- [DRAG] screen-absolute coords instead of GetPoint
    local left, bottom = frame:GetLeft(), frame:GetBottom()
    if not left or not bottom then return end
    local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    db.position = {
        point         = "BOTTOMLEFT",
        relativePoint = "BOTTOMLEFT",
        x             = left * scale,
        y             = bottom * scale,
    }
end

local function ApplyPosition()
    local db = DB()
    if not db or not frame then return end
    frame:ClearAllPoints()
    local p = db.position
    if p and p.point then
        frame:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    end
end

-- =====================================
-- SCAN BUFFS
-- =====================================

local function ScanBuffs()
    buffData.flask = nil
    buffData.food  = nil

    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetBuffDataByIndex, "player", i)
        if not ok or not aura then break end

        local spellID = aura and aura.spellId
        if not spellID then
            -- pas de spellID : passer à l'aura suivante (ne pas arrêter le scan)
        -- Ignorer les valeurs secrètes (taint TWW)
        elseif issecretvalue and issecretvalue(spellID) then
            -- skip

        elseif FLASK_IDS[spellID] then
            if not buffData.flask then
                buffData.flask = {
                    icon           = aura.icon,
                    expirationTime = aura.expirationTime or 0,
                    spellID        = spellID,
                }
            end

        else
            -- Détection nourriture : durée ~1h, source = joueur (exclut buffs de zone/NPC)
            if not buffData.food then
                local dur = aura.duration or 0
                local src = aura.sourceUnit
                local selfApplied = (src == nil) or (src == "player") or (src == "")
                if dur >= FOOD_DUR_MIN and dur <= FOOD_DUR_MAX and selfApplied then
                    buffData.food = {
                        icon           = aura.icon,
                        expirationTime = aura.expirationTime or 0,
                        spellID        = spellID,
                    }
                end
            end
        end
    end
end

-- =====================================
-- LAYOUT & UPDATE SLOTS
-- =====================================

local function UpdateAllSlots(isPreview)
    if not slots or not frame then return end
    local db = DB()
    if not db then return end

    local iconSize    = db.iconSize    or 36
    local gap         = db.gap         or 4
    local showMissing = db.showMissing
    local orientation = db.orientation or "horizontal"
    local timerPos    = db.timerPos    or "below"
    local now         = GetTime()

    -- Corriger les combinaisons incohérentes (ex. timerPos="right" en mode horizontal)
    if orientation == "horizontal" and (timerPos == "right" or timerPos == "left") then
        timerPos = "below"
    elseif orientation == "vertical" and (timerPos == "above" or timerPos == "below") then
        timerPos = "right"
    end

    -- Dimensions d'un slot selon l'orientation
    local TIMER_H = 14   -- hauteur zone timer (barre horizontale)
    local TIMER_W = 42   -- largeur zone timer (barre verticale)

    local slotW, slotH
    if orientation == "vertical" then
        slotW = iconSize + TIMER_W
        slotH = iconSize
    else
        slotW = iconSize
        slotH = iconSize + TIMER_H
    end

    local prevSlot     = nil
    local visibleCount = 0

    for _, slotDef in ipairs(slots) do
        local slot = slotDef.frame
        local key  = slotDef.key
        local data = buffData[key]

        -- Visibilité du slot
        local shouldShow = true
        if not isPreview and not showMissing and not data then
            shouldShow = false
        end

        if shouldShow then
            slot:SetSize(slotW, slotH)

            -- Ancrage de l'icône selon orientation + position du timer
            slot.icon:ClearAllPoints()
            if orientation == "vertical" then
                if timerPos == "left" then
                    -- Icône à droite, timer à gauche
                    slot.icon:SetPoint("TOPRIGHT",    slot, "TOPRIGHT",    -1, -1)
                    slot.icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1,  1)
                else
                    -- Icône à gauche, timer à droite (défaut vertical)
                    slot.icon:SetPoint("TOPLEFT",    slot, "TOPLEFT",    1, -1)
                    slot.icon:SetPoint("BOTTOMLEFT", slot, "BOTTOMLEFT", 1,  1)
                end
                slot.icon:SetWidth(iconSize - 2)
            else
                if timerPos == "above" then
                    -- Icône en bas, timer en haut
                    slot.icon:SetPoint("BOTTOMLEFT",  slot, "BOTTOMLEFT",   1,  1)
                    slot.icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1,  1)
                else
                    -- Icône en haut, timer en bas (défaut horizontal)
                    slot.icon:SetPoint("TOPLEFT",  slot, "TOPLEFT",   1, -1)
                    slot.icon:SetPoint("TOPRIGHT", slot, "TOPRIGHT", -1, -1)
                end
                slot.icon:SetHeight(iconSize - 2)
            end

            -- Ancrage du timer
            slot.timer:ClearAllPoints()
            if orientation == "vertical" then
                if timerPos == "left" then
                    slot.timer:SetPoint("LEFT", slot, "LEFT", 2, 0)
                    slot.timer:SetJustifyH("LEFT")
                else
                    slot.timer:SetPoint("RIGHT", slot, "RIGHT", -2, 0)
                    slot.timer:SetJustifyH("RIGHT")
                end
            else
                if timerPos == "above" then
                    slot.timer:SetPoint("TOP", slot, "TOP", 0, -1)
                else
                    slot.timer:SetPoint("BOTTOM", slot, "BOTTOM", 0, 1)
                end
                slot.timer:SetJustifyH("CENTER")
            end

            -- Contenu du slot
            if isPreview then
                -- Mode placement : aperçu factice
                slot.icon:SetTexture(slotDef.defaultIcon)
                slot.icon:SetDesaturated(false)
                slot.icon:SetAlpha(1)
                slot.currentSpellID = nil
                slot.timer:SetText(FormatTime(PREVIEW_TIMES[key] or 3480))
                slot.timer:SetTextColor(1, 1, 1)
                slot.timer:Show()
                slot:SetBackdropBorderColor(TEAL.r, TEAL.g, TEAL.b, 0.85)

            elseif data then
                -- Buff actif
                slot.icon:SetTexture(data.icon or slotDef.defaultIcon)
                slot.icon:SetDesaturated(false)
                slot.icon:SetAlpha(1)
                slot.currentSpellID = data.spellID

                local rem = data.expirationTime > 0 and (data.expirationTime - now) or 0
                if rem > 0 then
                    if rem < 300 then
                        slot.timer:SetTextColor(1, 0.35, 0.35)
                    else
                        slot.timer:SetTextColor(1, 1, 1)
                    end
                    slot.timer:SetText(FormatTime(rem))
                    slot.timer:Show()
                else
                    slot.timer:Hide()
                end
                slot:SetBackdropBorderColor(TEAL.r * 0.6, TEAL.g * 0.6, TEAL.b * 0.6, 1)

            else
                -- Buff manquant (fantôme)
                slot.icon:SetTexture(slotDef.defaultIcon)
                slot.icon:SetDesaturated(true)
                slot.icon:SetAlpha(0.28)
                slot.currentSpellID = nil
                slot.timer:Hide()
                slot:SetBackdropBorderColor(0.14, 0.14, 0.16, 1)
            end

            -- Positionnement du slot dans la barre
            slot:ClearAllPoints()
            if not prevSlot then
                slot:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            else
                if orientation == "vertical" then
                    slot:SetPoint("TOPLEFT", prevSlot, "BOTTOMLEFT", 0, -gap)
                else
                    slot:SetPoint("TOPLEFT", prevSlot, "TOPRIGHT", gap, 0)
                end
            end

            slot:Show()
            prevSlot = slot
            visibleCount = visibleCount + 1
        else
            slot:Hide()
        end
    end

    -- Redimensionner le conteneur
    if visibleCount > 0 then
        if orientation == "vertical" then
            frame:SetSize(slotW, visibleCount * slotH + (visibleCount - 1) * gap)
        else
            frame:SetSize(visibleCount * slotW + (visibleCount - 1) * gap, slotH)
        end
        -- Ne pas afficher si le module est désactivé
        if db.enabled then
            frame:Show()
        end
    else
        if isLocked then
            frame:Hide()
        else
            -- En mode placement, montrer quand même
            frame:SetSize(slotW, slotH)
        end
    end
end

-- =====================================
-- CRÉATION DES SLOTS
-- =====================================

local function CreateSlot(parent, key, defaultIcon)
    local slot = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    slot.key            = key
    slot.defaultIcon    = defaultIcon
    slot.currentSpellID = nil

    slot:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    slot:SetBackdropColor(0, 0, 0, 0.65)
    slot:SetBackdropBorderColor(0.15, 0.15, 0.17, 1)

    -- Icône (occupe le haut du slot, hauteur fixée à l'update)
    local icon = slot:CreateTexture(nil, "ARTWORK")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetPoint("TOPLEFT",  slot, "TOPLEFT",  1, -1)
    icon:SetPoint("TOPRIGHT", slot, "TOPRIGHT", -1, -1)
    slot.icon = icon

    -- Timer (bas du slot, centré)
    local timer = slot:CreateFontString(nil, "OVERLAY")
    timer:SetFont(FONT, 10, "OUTLINE")
    timer:SetPoint("BOTTOM", slot, "BOTTOM", 0, 1)
    timer:SetTextColor(1, 1, 1)
    timer:SetJustifyH("CENTER")
    timer:Hide()
    slot.timer = timer

    -- Tooltip
    slot:EnableMouse(true)
    slot:SetScript("OnEnter", function(self)
        if self.currentSpellID then
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            local ok = pcall(GameTooltip.SetSpellByID, GameTooltip, self.currentSpellID)
            if ok then GameTooltip:Show() end
        end
    end)
    slot:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return slot
end

-- =====================================
-- CRÉATION DE LA BARRE
-- =====================================

local function CreateBar()
    if frame then return end
    local db = DB()
    if not db then return end

    local iconSize = db.iconSize or 36
    local timerH   = 14

    -- Conteneur principal
    frame = CreateFrame("Frame", "TomoMod_ConsumableBar", UIParent, "BackdropTemplate")
    frame:SetSize(iconSize * 4 + 12, iconSize + timerH)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(60)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(false)    -- activé uniquement en mode placement
    frame:Hide()                -- masqué par défaut ; UpdateVisibility/UpdateAllSlots gère l'affichage

    frame:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.04, 0.04, 0.06, 0.88)
    frame:SetBackdropBorderColor(0.12, 0.12, 0.14, 1)

    ApplyPosition()

    -- Overlay mode placement — c'est lui qui capte le drag (il couvre les slots enfants)
    dragOverlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    dragOverlay:SetAllPoints()
    dragOverlay:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    dragOverlay:SetBackdropColor(TEAL.r, TEAL.g, TEAL.b, 0.18)
    dragOverlay:SetBackdropBorderColor(TEAL.r, TEAL.g, TEAL.b, 0.80)
    dragOverlay:SetFrameLevel(frame:GetFrameLevel() + 20)
    dragOverlay:EnableMouse(true)
    dragOverlay:RegisterForDrag("LeftButton")
    dragOverlay:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    dragOverlay:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        SavePosition()
    end)

    dragLabel = dragOverlay:CreateFontString(nil, "OVERLAY")
    dragLabel:SetFont(FONT_BOLD, 9, "OUTLINE")
    dragLabel:SetPoint("CENTER")
    dragLabel:SetTextColor(TEAL.r, TEAL.g, TEAL.b)
    dragLabel:SetText(L and L["mover_consumable_bar"] or "Consommables")
    dragOverlay:Hide()

    -- Icônes par défaut chargées depuis les spell IDs
    local defaultFlaskIcon = GetSpellIconSafe(1235111) or 134906

    -- Créer les 2 slots
    slots = {}
    local slotDefs = {
        { key = "flask", defaultIcon = defaultFlaskIcon  },
        { key = "food",  defaultIcon = ICON_FOOD_DEFAULT },
    }
    for i, def in ipairs(slotDefs) do
        local slot = CreateSlot(frame, def.key, def.defaultIcon)
        slotDefs[i].frame = slot
        slots[i] = slotDefs[i]
    end
end

-- =====================================
-- LOCK / UNLOCK (Mover)
-- =====================================

local function SetLockedInternal(locked)
    isLocked = locked
    if not frame then return end

    if locked then
        if dragOverlay then dragOverlay:Hide() end
        ScanBuffs()
        UpdateAllSlots(false)
    else
        frame:Show()
        if dragOverlay then dragOverlay:Show() end
        UpdateAllSlots(true)
    end
end

function CB.SetLocked(locked)
    SetLockedInternal(locked)
end

function CB.ToggleLock()
    SetLockedInternal(not isLocked)
    return isLocked
end

function CB.IsLocked()
    return isLocked
end

-- =====================================
-- VISIBILITÉ
-- =====================================

local function UpdateVisibility()
    if not frame then return end
    local db = DB()
    if not db or not db.enabled then
        frame:Hide()
        return
    end
    if not isLocked then
        frame:Show()
    end
    -- Si locked : UpdateAllSlots gère la visibilité du frame selon les buffs actifs
end

-- =====================================
-- APPLY SETTINGS (appelé depuis le GUI)
-- =====================================

function CB.ApplySettings()
    if not frame then return end
    local db = DB()
    if not db then return end

    UpdateVisibility()

    if dragLabel and L then
        dragLabel:SetText(L["mover_consumable_bar"] or "Consommables")
    end

    if not isLocked then
        UpdateAllSlots(true)
    else
        ScanBuffs()
        UpdateAllSlots(false)
    end
end

-- =====================================
-- EVENTS
-- =====================================

local function OnEvent(_, event, unit)
    if event == "UNIT_AURA" and unit ~= "player" then return end

    if event == "UNIT_AURA" or event == "PLAYER_AURAS_CHANGED" then
        if isLocked then
            ScanBuffs()
            UpdateAllSlots(false)
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        UpdateVisibility()
        if isLocked then
            ScanBuffs()
            UpdateAllSlots(false)
        end
    end
end

-- =====================================
-- INITIALIZE
-- =====================================

function CB.Initialize()
    if initialized then return end
    initialized = true

    L = TomoMod_L

    CreateBar()

    -- Événements pour mise à jour immédiate au gain/perte d'un buff
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:SetScript("OnEvent", OnEvent)

    -- Ticker 1 s pour actualiser les timers et rescanner les buffs
    updateTicker = C_Timer.NewTicker(1, function()
        if not frame or not frame:IsShown() then return end
        if isLocked then
            ScanBuffs()             -- re-scan pour valeurs fraîches
            UpdateAllSlots(false)
        else
            UpdateAllSlots(true)
        end
    end)

    UpdateVisibility()
    ScanBuffs()
    UpdateAllSlots(false)
end

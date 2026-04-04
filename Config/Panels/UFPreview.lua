-- ============================================================
-- UFPreview.lua — Live UnitFrame preview strip v2.7.0
-- Renders scaled fake StatusBars that mirror TomoModDB settings.
-- Exposed via TomoMod_UFPreview.Refresh() for external calls.
--
-- Architecture (inspired by KullThranUI KUI_UnitFrames_Options):
--   CreatePreviewUnit(parent)       → builds one fake frame table
--   ApplyPreviewUnit(pu, key, db)   → reads DB, updates sizes/colors/text
--   UFP.Create(parent)              → builds the strip, returns it
--   UFP.Refresh()                   → public, calls ApplyPreviewUnit on all units
-- ============================================================

TomoMod_UFPreview = {}
local UFP = TomoMod_UFPreview
local L   = TomoMod_L

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

-- Preview scale: all DB pixel values multiplied by this factor
local SCALE = 0.76

-- Mock HP / power values shown in the preview
local MOCK = {
    player       = { hp = 78,  power = 55, pwColor = {0.00, 0.44, 1.00} },  -- mana
    target       = { hp = 45,  power = 30, pwColor = {0.22, 0.45, 0.95} },  -- mana
    focus        = { hp = 100, power = 80, pwColor = {0.80, 0.80, 0.80} },  -- energy
    pet          = { hp = 62,  power = 0,  pwColor = nil               },
    targettarget = { hp = 90,  power = 0,  pwColor = nil               },
}

-- Hardcoded class colors (avoids RAID_CLASS_COLORS taint)
local CLASS_COLOR = {
    WARRIOR     = {0.78, 0.61, 0.43},  PALADIN    = {0.96, 0.55, 0.73},
    HUNTER      = {0.67, 0.83, 0.45},  ROGUE      = {1.00, 0.96, 0.41},
    PRIEST      = {0.90, 0.90, 0.90},  DEATHKNIGHT= {0.77, 0.12, 0.23},
    SHAMAN      = {0.00, 0.44, 0.87},  MAGE       = {0.41, 0.80, 0.94},
    WARLOCK     = {0.58, 0.51, 0.79},  MONK       = {0.00, 1.00, 0.59},
    DRUID       = {1.00, 0.49, 0.04},  DEMONHUNTER= {0.64, 0.19, 0.79},
    EVOKER      = {0.20, 0.58, 0.50},
}
-- Mock class per unit key (except player which uses the real class)
local UNIT_CLASS = {
    target = "MAGE", focus = "PRIEST", targettarget = "DRUID", pet = "HUNTER",
}

local function GetPreviewColor(unitKey, useClassColor)
    if not useClassColor then return 0.10, 0.60, 0.20 end
    local classToken
    if unitKey == "player" then
        local _, c = UnitClass("player")
        classToken = c
    else
        classToken = UNIT_CLASS[unitKey]
    end
    local c = classToken and CLASS_COLOR[classToken]
    if c then return c[1], c[2], c[3] end
    return 0.047, 0.824, 0.624  -- teal fallback
end

-- ============================================================
-- Build one fake unit frame
-- Returns a table with .frame, .health, .power, .castbar, etc.
-- ============================================================
local function CreatePreviewUnit(parent)
    local pu = {}

    pu.frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    pu.frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    pu.frame:SetBackdropColor(0.07, 0.07, 0.09, 1)
    pu.frame:SetBackdropBorderColor(0.20, 0.20, 0.24, 1)

    -- Health bar
    pu.health = CreateFrame("StatusBar", nil, pu.frame)
    pu.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    pu.healthBg = pu.health:CreateTexture(nil, "BACKGROUND")
    pu.healthBg:SetAllPoints()

    -- Absorb overlay (thin bright right edge)
    pu.absorb = pu.health:CreateTexture(nil, "OVERLAY")
    pu.absorb:SetWidth(4)
    pu.absorb:SetPoint("TOPRIGHT",    pu.health, "TOPRIGHT",    0, 0)
    pu.absorb:SetPoint("BOTTOMRIGHT", pu.health, "BOTTOMRIGHT", 0, 0)
    pu.absorb:SetColorTexture(0.85, 0.85, 1.00, 0.55)
    pu.absorb:Hide()

    -- Name text
    pu.name = pu.health:CreateFontString(nil, "OVERLAY")
    pu.name:SetPoint("LEFT", 4, 0)
    pu.name:SetJustifyH("LEFT")
    pu.name:SetTextColor(1, 1, 1, 1)

    -- Health value text
    pu.value = pu.health:CreateFontString(nil, "OVERLAY")
    pu.value:SetPoint("RIGHT", -4, 0)
    pu.value:SetJustifyH("RIGHT")
    pu.value:SetTextColor(1, 1, 1, 0.80)

    -- Power bar
    pu.power = CreateFrame("StatusBar", nil, pu.frame)
    pu.power:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    pu.powerBg = pu.power:CreateTexture(nil, "BACKGROUND")
    pu.powerBg:SetAllPoints()
    pu.powerBg:SetColorTexture(0.04, 0.04, 0.06, 1)

    -- Castbar
    pu.castbar = CreateFrame("StatusBar", nil, pu.frame)
    pu.castbar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    pu.castbar:SetStatusBarColor(0.80, 0.28, 0.28, 1)
    pu.castbarBg = pu.castbar:CreateTexture(nil, "BACKGROUND")
    pu.castbarBg:SetAllPoints()
    pu.castbarBg:SetColorTexture(0.06, 0.04, 0.04, 1)

    pu.castText = pu.castbar:CreateFontString(nil, "OVERLAY")
    pu.castText:SetPoint("LEFT", 3, 0)
    pu.castText:SetJustifyH("LEFT")
    pu.castText:SetTextColor(1, 0.85, 0.85, 1)

    pu.castbarBorder = CreateFrame("Frame", nil, pu.castbar, "BackdropTemplate")
    pu.castbarBorder:SetAllPoints()
    pu.castbarBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    pu.castbarBorder:SetBackdropBorderColor(0.35, 0.18, 0.18, 1)

    -- Aura dots (up to 5)
    pu.auras = {}
    for i = 1, 5 do
        local dot = pu.frame:CreateTexture(nil, "OVERLAY")
        dot:SetSize(9, 9)
        dot:Hide()
        pu.auras[i] = dot
    end

    -- Threat indicator (left bar)
    pu.threat = pu.frame:CreateTexture(nil, "OVERLAY")
    pu.threat:SetWidth(2)
    pu.threat:SetPoint("TOPLEFT",    pu.health, "TOPLEFT",    0, 0)
    pu.threat:SetPoint("BOTTOMLEFT", pu.health, "BOTTOMLEFT", 0, 0)
    pu.threat:SetColorTexture(1, 0.15, 0.15, 0.85)
    pu.threat:Hide()

    return pu
end

-- ============================================================
-- Apply DB settings to one fake unit frame
-- ============================================================
local GAP = 2  -- pixels between health / power / castbar

local function ApplyPreviewUnit(pu, unitKey, db, globalDB)
    if not (pu and db) then return end
    local mock = MOCK[unitKey] or { hp = 100, power = 0, pwColor = nil }

    -- Scaled dimensions
    local healthH = math.max(6,  math.floor((db.healthHeight or 38) * SCALE + 0.5))
    local powerH  = math.max(0,  math.floor((db.powerHeight  or  8) * SCALE + 0.5))
    local frameW  = math.max(40, math.floor((db.width        or 220) * SCALE + 0.5))

    -- Castbar
    local cbDB   = db.castbar
    local showCB = cbDB and cbDB.enabled and (unitKey == "player" or unitKey == "target")
    local cbH    = showCB and math.max(4, math.floor((cbDB.height or 14) * SCALE + 0.5)) or 0
    local cbW    = showCB and math.max(20, math.floor((cbDB.width  or db.width or 220) * SCALE + 0.5)) or 0

    -- Power only for frames that normally have it
    local hasPower = mock.pwColor ~= nil and powerH > 0

    local totalH = healthH
        + (hasPower and (GAP + powerH) or 0)
        + (cbH > 0  and (GAP + cbH)   or 0)

    pu.frame:SetSize(frameW, totalH)

    -- Health
    pu.health:ClearAllPoints()
    pu.health:SetPoint("TOPLEFT", pu.frame, "TOPLEFT", 0, 0)
    pu.health:SetSize(frameW, healthH)
    pu.health:SetMinMaxValues(0, 100)
    pu.health:SetValue(mock.hp)

    local r, g, b = GetPreviewColor(unitKey, db.useClassColor ~= false)
    pu.health:SetStatusBarColor(r, g, b, 1)
    pu.healthBg:SetColorTexture(r * 0.14, g * 0.14, b * 0.14, 1)
    pu.frame:SetBackdropBorderColor(r * 0.40 + 0.10, g * 0.40 + 0.10, b * 0.40 + 0.10, 0.70)

    -- Absorb bar
    pu.absorb:SetShown(db.showAbsorb == true)

    -- Threat indicator
    pu.threat:SetShown(db.showThreat == true and unitKey == "target")

    -- Name
    pu.name:SetShown(db.showName ~= false)
    local fs = math.max(7, math.floor((globalDB.fontSize or 12) * SCALE + 0.5))
    pu.name:SetFont(FONT, fs, "OUTLINE")
    local displayName = (unitKey == "player" and (UnitName and UnitName("player") or (L["preview_player"] or "Joueur")))
        or (unitKey == "target" and (L["preview_target_name"] or "Taurache"))
        or (unitKey == "focus"  and (L["preview_focus_name"] or "Pr\195\170trelle"))
        or (unitKey == "pet"    and (L["preview_pet_name"] or "Loup d'eau"))
        or (L["preview_tot_name"] or "Cible-de-cible")
    if db.nameTruncate and (db.nameTruncateLength or 20) < #displayName then
        displayName = displayName:sub(1, db.nameTruncateLength or 20) .. "…"
    end
    pu.name:SetText(displayName)

    -- Value text
    pu.value:SetShown(db.showHealthText ~= false)
    pu.value:SetFont(FONT, fs, "OUTLINE")
    local fmt = db.healthTextFormat or "percent"
    if fmt == "percent" then
        pu.value:SetText(mock.hp .. "%")
    elseif fmt == "current" then
        pu.value:SetText("300K")
    elseif fmt == "current_percent" then
        pu.value:SetText("300K · " .. mock.hp .. "%")
    else
        pu.value:SetText("300K / 387K")
    end

    -- Power
    pu.power:SetShown(hasPower)
    if hasPower then
        pu.power:ClearAllPoints()
        pu.power:SetPoint("TOPLEFT", pu.health, "BOTTOMLEFT", 0, -GAP)
        pu.power:SetSize(frameW, powerH)
        pu.power:SetMinMaxValues(0, 100)
        pu.power:SetValue(mock.power)
        local pc = mock.pwColor
        pu.power:SetStatusBarColor(pc[1], pc[2], pc[3], 1)
    end

    -- Castbar
    pu.castbar:SetShown(cbH > 0)
    if cbH > 0 then
        local anchor = hasPower and pu.power or pu.health
        pu.castbar:ClearAllPoints()
        pu.castbar:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -GAP)
        pu.castbar:SetSize(cbW, cbH)
        pu.castbar:SetMinMaxValues(0, 100)
        pu.castbar:SetValue(60)
        local castFS = math.max(6, fs - 1)
        pu.castText:SetFont(FONT, castFS, "OUTLINE")
        pu.castText:SetText(unitKey == "player" and (L["preview_cast_player"] or "Éclair de givre") or (L["preview_cast_target"] or "Boule de feu"))
    end

    -- Aura dots
    local showAuras  = db.auras and db.auras.enabled
    local maxAuras   = showAuras and math.min(5, db.auras.maxAuras or 4) or 0
    local auraColors = {
        {0.80, 0.20, 0.20}, {0.65, 0.20, 0.80},
        {0.20, 0.45, 0.85}, {0.80, 0.65, 0.10}, {0.25, 0.75, 0.30},
    }
    local dotW = math.max(7, math.floor(healthH * 0.30 + 0.5))
    for i = 1, 5 do
        local dot = pu.auras[i]
        if i <= maxAuras then
            dot:SetSize(dotW, dotW)
            dot:ClearAllPoints()
            dot:SetPoint("TOPLEFT", pu.frame, "BOTTOMLEFT", (i - 1) * (dotW + 2), -3)
            local ac = auraColors[i]
            dot:SetColorTexture(ac[1], ac[2], ac[3], 0.88)
            dot:Show()
        else
            dot:Hide()
        end
    end
end

-- ============================================================
-- Create the preview strip
-- Returns the strip frame — caller positions it.
-- ============================================================
local STRIP_H_MIN  = 150
local HEADER_H     = 24   -- space for "APERÇU EN DIRECT" label
local UNIT_PAD_TOP = 30   -- top offset for first unit row
local UNIT_GAP     = 10   -- gap between rows
local SIDE_PAD     = 16   -- left/right padding

function UFP.Create(parent)
    local T  = TomoMod_Widgets and TomoMod_Widgets.Theme
    local aR = T and T.accent[1] or 0.047
    local aG = T and T.accent[2] or 0.824
    local aB = T and T.accent[3] or 0.624

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

    -- "APERÇU EN DIRECT" label
    local header = strip:CreateFontString(nil, "OVERLAY")
    header:SetFont(FONT_BOLD, 9, "OUTLINE")
    header:SetPoint("TOPLEFT", 12, -8)
    header:SetTextColor(aR, aG, aB, 0.55)
    header:SetText(L["preview_header"] or "APERÇU EN DIRECT")

    -- Pulsing dot
    local dot = strip:CreateTexture(nil, "OVERLAY")
    dot:SetSize(5, 5)
    dot:SetPoint("LEFT", header, "RIGHT", 6, 0)
    dot:SetColorTexture(aR, aG, aB, 1)
    local dotVis = true
    local dotTicker = C_Timer.NewTicker(1.2, function()
        dotVis = not dotVis
        dot:SetAlpha(dotVis and 0.9 or 0.20)
    end)
    strip:SetScript("OnHide", function()
        if dotTicker then dotTicker:Cancel(); dotTicker = nil end
    end)

    -- Separator at bottom
    local sep = strip:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("BOTTOMLEFT",  strip, "BOTTOMLEFT",  0, 0)
    sep:SetPoint("BOTTOMRIGHT", strip, "BOTTOMRIGHT", 0, 0)
    sep:SetColorTexture(aR * 0.6, aG * 0.6, aB * 0.6, 0.25)

    -- Gradient overlay at bottom
    local grad = strip:CreateTexture(nil, "BACKGROUND", nil, -1)
    grad:SetHeight(24)
    grad:SetPoint("BOTTOMLEFT",  strip, "BOTTOMLEFT",  0, 1)
    grad:SetPoint("BOTTOMRIGHT", strip, "BOTTOMRIGHT", 0, 1)
    if grad.SetGradientAlpha then
        grad:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0, 0, 0, 0.35)
    end

    -- Create fake unit frames
    local units = {}
    local UNIT_ORDER = { "player", "target", "focus", "pet", "targettarget" }
    for _, k in ipairs(UNIT_ORDER) do
        units[k] = CreatePreviewUnit(strip)
    end
    strip.units = units

    -- Unit header labels (above each unit)
    local UNIT_LABELS = {
        player = L["preview_lbl_player"] or "JOUEUR", target = L["preview_lbl_target"] or "CIBLE",
        focus  = L["preview_lbl_focus"] or "FOCUS",  pet    = L["preview_lbl_pet"] or "PET", targettarget = L["preview_lbl_tot"] or "TOT",
    }
    for k, pu in pairs(units) do
        local lbl = strip:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT, 8, "OUTLINE")
        lbl:SetTextColor(aR * 0.7, aG * 0.7, aB * 0.7, 0.70)
        lbl:SetText(UNIT_LABELS[k] or k:upper())
        pu.label = lbl
    end

    -- Hover effect + click = switch to unit's tab (populated by UnitFrames.lua)
    strip.onUnitClick = {}  -- [unitKey] = function()

    for _, k in ipairs(UNIT_ORDER) do
        local pu  = units[k]
        local key = k
        pu.frame:EnableMouse(true)
        pu.frame:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(aR, aG, aB, 0.80)
            if GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText((UNIT_LABELS[key] or key) .. " - " .. (L["preview_click_nav"] or "cliquer pour naviguer"), aR, aG, aB)
                GameTooltip:Show()
            end
        end)
        pu.frame:SetScript("OnLeave", function(self)
            -- re-apply border from Refresh
            if TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames[key] then
                local db = TomoModDB.unitFrames[key]
                local r, g, b = GetPreviewColor(key, db.useClassColor ~= false)
                self:SetBackdropBorderColor(r * 0.40 + 0.10, g * 0.40 + 0.10, b * 0.40 + 0.10, 0.70)
            end
            if GameTooltip then GameTooltip:Hide() end
        end)
        pu.frame:SetScript("OnMouseUp", function()
            local fn = strip.onUnitClick[key]
            if fn then fn() end
        end)
    end

    -- ============================================================
    -- Refresh: reads DB and repositions all units
    -- ============================================================
    local function Refresh()
        if not TomoModDB or not TomoModDB.unitFrames then return end
        local ufdb    = TomoModDB.unitFrames
        local globalDB = ufdb

        -- Apply each unit
        for _, k in ipairs(UNIT_ORDER) do
            local db = ufdb[k]
            if db then
                ApplyPreviewUnit(units[k], k, db, globalDB)
            end
        end

        -- ── Layout ──────────────────────────────────────────────
        -- Left column:  Player → Pet → Focus
        -- Right column: Target → ToT
        local function PlaceLabel(pu, x, y)
            pu.label:ClearAllPoints()
            pu.label:SetPoint("TOPLEFT", strip, "TOPLEFT", x, y)
        end

        -- Player — top left
        local pX = SIDE_PAD
        local pY = -UNIT_PAD_TOP
        units.player.frame:ClearAllPoints()
        units.player.frame:SetPoint("TOPLEFT", strip, "TOPLEFT", pX, pY)
        PlaceLabel(units.player, pX, pY + 12)

        -- Target — top right (anchor from TOPRIGHT so width changes don't clip)
        units.target.frame:ClearAllPoints()
        units.target.frame:SetPoint("TOPRIGHT", strip, "TOPRIGHT", -SIDE_PAD, pY)
        units.target.label:ClearAllPoints()
        units.target.label:SetPoint("BOTTOMLEFT", units.target.frame, "TOPLEFT", 0, 2)

        -- Pet — below player
        local petY = pY - (units.player.frame:GetHeight() or 0) - UNIT_GAP - 12
        units.pet.frame:ClearAllPoints()
        units.pet.frame:SetPoint("TOPLEFT", strip, "TOPLEFT", pX, petY)
        PlaceLabel(units.pet, pX, petY + 12)

        -- ToT — below target
        local totY = pY - (units.target.frame:GetHeight() or 0) - UNIT_GAP - 12
        units.targettarget.frame:ClearAllPoints()
        units.targettarget.frame:SetPoint("TOPRIGHT", strip, "TOPRIGHT", -SIDE_PAD, totY)
        units.targettarget.label:ClearAllPoints()
        units.targettarget.label:SetPoint("BOTTOMLEFT", units.targettarget.frame, "TOPLEFT", 0, 2)

        -- Focus — below pet
        local focY = petY - (units.pet.frame:GetHeight() or 0) - UNIT_GAP - 12
        units.focus.frame:ClearAllPoints()
        units.focus.frame:SetPoint("TOPLEFT", strip, "TOPLEFT", pX, focY)
        PlaceLabel(units.focus, pX, focY + 12)

        -- Adjust strip height
        local leftH  = math.abs(focY) + (units.focus.frame:GetHeight() or 0) + 16
        local rightH = math.abs(totY) + (units.targettarget.frame:GetHeight() or 0) + 16
        local auraExtra = 14  -- room for aura dots
        strip:SetHeight(math.max(STRIP_H_MIN, leftH, rightH) + auraExtra)
    end

    strip.Refresh      = Refresh
    UFP.Refresh        = function() if strip and strip:IsShown() then Refresh() end end
    UFP.ForceRefresh   = Refresh  -- bypasses IsShown check (called on panel open)

    strip:SetScript("OnShow", Refresh)
    C_Timer.After(0, Refresh)

    return strip
end

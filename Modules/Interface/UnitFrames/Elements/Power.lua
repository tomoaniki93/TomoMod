-- =====================================
-- Elements/Power.lua — Power (Mana/Energy/Rage/etc) Bar
-- =====================================

local UF_Elements = UF_Elements or {}

local TEXTURE = "Interface\\AddOns\\TomoModMini\\Assets\\Textures\\tomoaniki"
local FONT = "Interface\\AddOns\\TomoModMini\\Assets\\Fonts\\Tomo.ttf"

function UF_Elements.CreatePower(parent, unit, settings)
    if (settings.powerHeight or 0) <= 0 then return nil end

    local tex = (TomoModMiniDB and TomoModMiniDB.unitFrames and TomoModMiniDB.unitFrames.texture) or TEXTURE
    local font = (TomoModMiniDB and TomoModMiniDB.unitFrames and TomoModMiniDB.unitFrames.font) or FONT

    local power = CreateFrame("StatusBar", nil, parent)
    power:SetSize(settings.width, settings.powerHeight)
    power:SetStatusBarTexture(tex)
    power:GetStatusBarTexture():SetHorizTile(false)
    power:SetMinMaxValues(0, 100)
    power:SetValue(100)

    -- Background
    local bg = power:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(tex)
    bg:SetVertexColor(0.06, 0.06, 0.08, 0.8)
    power.bg = bg

    -- Border
    UF_Elements.CreateBorder(power)

    -- Power text (optional)
    local text = power:CreateFontString(nil, "OVERLAY")
    text:SetFont(font, 8, "OUTLINE")
    text:SetPoint("CENTER", 0, 0)
    text:SetTextColor(1, 1, 1, 0.8)
    text:SetText("")
    power.text = text

    power.unit = unit
    power:EnableMouse(false)  -- Let clicks pass through
    return power
end

function UF_Elements.UpdatePower(frame)
    if not frame or not frame.power or not frame.unit then return end
    if not UnitExists(frame.unit) then return end

    local unit = frame.unit
    local powerType = UnitPowerType(unit)
    local current = UnitPower(unit, powerType) or 0
    local max = UnitPowerMax(unit, powerType) or 1

    frame.power:SetMinMaxValues(0, max)
    frame.power:SetValue(current)

    -- Color by power type
    local r, g, b = TomoModMini_Utils.GetPowerColor(powerType)
    frame.power:SetStatusBarColor(r, g, b, 1)

    -- Show power text if enabled (AbbreviateLargeNumbers is C-side, accepts secret numbers)
    local settings = TomoModMiniDB.unitFrames[unit]
    if settings and settings.showPowerText then
        frame.power.text:SetFormattedText("%s", AbbreviateLargeNumbers(current))
    else
        frame.power.text:SetText("")
    end
end

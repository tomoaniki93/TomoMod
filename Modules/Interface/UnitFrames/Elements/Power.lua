-- =====================================
-- Elements/Power.lua — Power (Mana/Energy/Rage/etc) Bar
-- =====================================

local UF_Elements = UF_Elements or {}

local TEXTURE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"

function UF_Elements.CreatePower(parent, unit, settings)
    if (settings.powerHeight or 0) <= 0 then return nil end

    local tex = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.texture) or TEXTURE
    local font = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.font) or FONT

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

    -- Border: full border for standard bars, side-only for thin accent bars
    if settings.powerHeight > 4 then
        UF_Elements.CreateBorder(power)
    else
        -- Side borders only (left + right) to align with health/info bar edges
        local lEdge = power:CreateTexture(nil, "OVERLAY", nil, 7)
        lEdge:SetColorTexture(0, 0, 0, 1)
        lEdge:SetPoint("TOPLEFT"); lEdge:SetPoint("BOTTOMLEFT")
        lEdge:SetWidth(1)
        local rEdge = power:CreateTexture(nil, "OVERLAY", nil, 7)
        rEdge:SetColorTexture(0, 0, 0, 1)
        rEdge:SetPoint("TOPRIGHT"); rEdge:SetPoint("BOTTOMRIGHT")
        rEdge:SetWidth(1)
    end

    -- Power text (optional, only for standard-height power bars)
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
    local powerType = UnitPowerType(unit) or 0
    -- UnitPower/UnitPowerMax return secret numbers in TWW — pass directly to C-side APIs, do not compare
    local current = UnitPower(unit, powerType)
    local max = UnitPowerMax(unit, powerType)

    frame.power:SetMinMaxValues(0, max)
    frame.power:SetValue(current)

    -- Color by power type
    local r, g, b = TomoMod_Utils.GetPowerColor(powerType)
    frame.power:SetStatusBarColor(r, g, b, 1)

    -- Show power text if enabled (AbbreviateLargeNumbers is C-side, accepts secret numbers)
    local settings = TomoModDB.unitFrames[unit]
    if settings and settings.showPowerText and not settings.infoBarHeight then
        frame.power.text:SetFormattedText("%s", AbbreviateLargeNumbers(current))
    else
        frame.power.text:SetText("")
    end
end

-- =====================================
-- INFO BAR (dark strip below power bar)
-- Shows: power value + total HP, mirrored for target
-- =====================================

function UF_Elements.CreateInfoBar(parent, unit, settings)
    local font = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.font) or FONT
    local fontSize = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.fontSize) or 12
    local infoBarHeight = settings.infoBarHeight or 18

    local infoBar = CreateFrame("Frame", nil, parent)
    infoBar:SetSize(settings.width, infoBarHeight)

    -- Dark background
    local bg = infoBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.08, 0.10, 0.9)
    infoBar.bg = bg

    -- Border (bottom + sides only, power bar acts as top border)
    local function Edge(p1, p2, w, h)
        local t = infoBar:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(0, 0, 0, 1)
        t:SetPoint(p1); t:SetPoint(p2)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    Edge("TOPLEFT", "BOTTOMLEFT", 1, nil)
    Edge("TOPRIGHT", "BOTTOMRIGHT", 1, nil)

    -- Power value text
    local powerText = infoBar:CreateFontString(nil, "OVERLAY")
    powerText:SetFont(font, fontSize - 1, "OUTLINE")
    powerText:SetTextColor(1, 1, 1, 0.85)

    -- Total HP text
    local hpText = infoBar:CreateFontString(nil, "OVERLAY")
    hpText:SetFont(font, fontSize - 1, "OUTLINE")
    hpText:SetTextColor(1, 1, 1, 0.85)

    -- Player: power left, HP right / Target: HP left, power right
    if unit == "target" then
        hpText:SetPoint("LEFT", infoBar, "LEFT", 6, 0)
        hpText:SetJustifyH("LEFT")
        powerText:SetPoint("RIGHT", infoBar, "RIGHT", -6, 0)
        powerText:SetJustifyH("RIGHT")
    else
        powerText:SetPoint("LEFT", infoBar, "LEFT", 6, 0)
        powerText:SetJustifyH("LEFT")
        hpText:SetPoint("RIGHT", infoBar, "RIGHT", -6, 0)
        hpText:SetJustifyH("RIGHT")
    end

    infoBar.powerText = powerText
    infoBar.hpText = hpText
    infoBar.unit = unit
    infoBar:EnableMouse(false)

    return infoBar
end

function UF_Elements.UpdateInfoBar(frame)
    if not frame or not frame.infoBar or not frame.unit then return end
    if not UnitExists(frame.unit) then return end

    local unit = frame.unit

    -- Power value
    if frame.infoBar.powerText then
        local powerType = UnitPowerType(unit) or 0
        local current = UnitPower(unit, powerType)
        frame.infoBar.powerText:SetFormattedText("%s", AbbreviateLargeNumbers(current))
    end

    -- Current HP
    if frame.infoBar.hpText then
        local current = UnitHealth(unit)
        frame.infoBar.hpText:SetFormattedText("%s", AbbreviateLargeNumbers(current))
    end
end

-- =====================================
-- InfoPanel.lua — Integrated Minimap Info
-- Zone header, subzone + coords overlay, clock
-- =====================================

TomoMod_InfoPanel = {}
local IP = TomoMod_InfoPanel

-- =====================================
-- LOCALS
-- =====================================

local FONT       = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD  = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local FONT_BLACK = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Bold.ttf"
local L = TomoMod_L

local zoneBar         -- Frame above minimap (zone name)
local zoneText        -- Zone name FontString
local subZoneText     -- Subzone overlay top-left
local coordsText      -- Coords overlay top-right
local clockBar        -- Frame below minimap (clock)
local clockText       -- Clock time FontString
local clockLabel      -- S/L indicator
local durabilityText  -- Gear durability overlay bottom-left
local isInitialized = false

local function DB()
    return TomoModDB and TomoModDB.infoPanel
end

-- =====================================
-- HIDE BLIZZARD ELEMENTS
-- =====================================

local function HideBlizzardElements()
    -- Hide Blizzard clock
    if TimeManagerClockButton then
        TimeManagerClockButton:Hide()
        TimeManagerClockButton:SetAlpha(0)
    end
    if GameTimeFrame then
        GameTimeFrame:Hide()
        GameTimeFrame:SetAlpha(0)
    end

    -- Hide Blizzard zone text
    if MinimapZoneText then
        MinimapZoneText:SetAlpha(0)
    end
    if MinimapZoneTextButton then
        MinimapZoneTextButton:SetAlpha(0)
    end
end

-- =====================================
-- TIME HELPERS
-- =====================================

function IP.GetFormattedTime()
    local hour, minute
    local db = DB()
    if not db then return "00:00" end

    if db.useServerTime then
        hour, minute = GetGameTime()
    else
        local d = date("*t")
        hour, minute = d.hour, d.min
    end

    if db.use24Hour then
        return string.format("%02d:%02d", hour, minute)
    else
        local suffix = hour >= 12 and "PM" or "AM"
        hour = hour % 12
        if hour == 0 then hour = 12 end
        return string.format("%d:%02d %s", hour, minute, suffix)
    end
end

local function GetTimeLabel()
    local db = DB()
    if not db then return "L" end
    return db.useServerTime and "S" or "L"
end

-- =====================================
-- ZONE & COORDS HELPERS
-- =====================================

local function GetZoneName()
    return GetRealZoneText() or ""
end

local function GetSubZoneName()
    local sub = GetSubZoneText()
    if sub and sub ~= "" then return sub end
    return GetMinimapZoneText() or ""
end

local function GetPlayerCoords()
    local map = C_Map.GetBestMapForUnit("player")
    if not map then return nil, nil end
    local pos = C_Map.GetPlayerMapPosition(map, "player")
    if not pos then return nil, nil end
    local x, y = pos:GetXY()
    if x == 0 and y == 0 then return nil, nil end
    return x * 100, y * 100
end

-- =====================================
-- GET ZONE PVP COLOR
-- =====================================

local function GetZonePvPColor()
    local pvpType = C_PvP.GetZonePVPInfo()
    if pvpType == "sanctuary" then
        return 0.41, 0.80, 0.94  -- cyan
    elseif pvpType == "friendly" then
        return 0.10, 0.75, 0.10  -- green
    elseif pvpType == "hostile" then
        return 0.90, 0.15, 0.15  -- red
    elseif pvpType == "contested" then
        return 0.95, 0.65, 0.10  -- orange
    elseif pvpType == "combat" then
        return 1.00, 0.20, 0.20  -- bright red
    else
        return 0.85, 0.85, 0.85  -- neutral grey
    end
end

-- =====================================
-- CREATE UI ELEMENTS
-- =====================================

local function CreateUI()
    if zoneBar then return end

    local db = DB()
    if not db then return end

    local minimap = Minimap
    if not minimap then return end

    -- Get class color for accent
    local classR, classG, classB = 1, 1, 1
    if TomoMod_Utils and TomoMod_Utils.GetClassColor then
        classR, classG, classB = TomoMod_Utils.GetClassColor()
    end

    -- =========================================
    -- ZONE BAR (above minimap)
    -- =========================================
    zoneBar = CreateFrame("Frame", "TomoMod_ZoneBar", minimap, "BackdropTemplate")
    zoneBar:SetHeight(24)
    zoneBar:SetPoint("BOTTOMLEFT", minimap, "TOPLEFT", 0, 2)
    zoneBar:SetPoint("BOTTOMRIGHT", minimap, "TOPRIGHT", 0, 2)
    zoneBar:SetFrameLevel(minimap:GetFrameLevel() + 5)

    zoneBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    zoneBar:SetBackdropColor(0.06, 0.06, 0.08, 0.90)

    -- Border color: class or black
    if TomoModDB.minimap.borderColor == "class" then
        zoneBar:SetBackdropBorderColor(classR, classG, classB, 1)
    else
        zoneBar:SetBackdropBorderColor(0, 0, 0, 1)
    end

    -- Zone name text
    zoneText = zoneBar:CreateFontString(nil, "OVERLAY")
    zoneText:SetFont(FONT_BLACK, 12, "OUTLINE")
    zoneText:SetPoint("CENTER", zoneBar, "CENTER", 0, 0)
    zoneText:SetTextColor(0.95, 0.95, 0.97, 1)
    zoneText:SetText("")

    -- =========================================
    -- OVERLAY: Subzone (top-left on minimap)
    -- =========================================
    subZoneText = minimap:CreateFontString(nil, "OVERLAY")
    subZoneText:SetFont(FONT_BOLD, 11, "OUTLINE")
    subZoneText:SetPoint("TOPLEFT", minimap, "TOPLEFT", 6, -6)
    subZoneText:SetTextColor(0.41, 0.80, 0.94, 1)
    subZoneText:SetText("")

    -- =========================================
    -- OVERLAY: Coords (top-right on minimap)
    -- =========================================
    coordsText = minimap:CreateFontString(nil, "OVERLAY")
    coordsText:SetFont(FONT, 11, "OUTLINE")
    coordsText:SetPoint("TOPRIGHT", minimap, "TOPRIGHT", -6, -6)
    coordsText:SetTextColor(0.85, 0.85, 0.85, 1)
    coordsText:SetText("")

    -- =========================================
    -- OVERLAY: Durability (bottom-left on minimap)
    -- =========================================
    durabilityText = minimap:CreateFontString(nil, "OVERLAY")
    durabilityText:SetFont(FONT_BOLD, 11, "OUTLINE")
    durabilityText:SetPoint("BOTTOMLEFT", minimap, "BOTTOMLEFT", 6, 6)
    durabilityText:SetText("")

    -- =========================================
    -- CLOCK BAR (below minimap)
    -- =========================================
    clockBar = CreateFrame("Button", "TomoMod_ClockBar", minimap, "BackdropTemplate")
    clockBar:SetHeight(28)
    clockBar:SetPoint("TOPLEFT", minimap, "BOTTOMLEFT", 0, -2)
    clockBar:SetPoint("TOPRIGHT", minimap, "BOTTOMRIGHT", 0, -2)
    clockBar:SetFrameLevel(minimap:GetFrameLevel() + 5)

    clockBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    clockBar:SetBackdropColor(0.06, 0.06, 0.08, 0.90)

    if TomoModDB.minimap.borderColor == "class" then
        clockBar:SetBackdropBorderColor(classR, classG, classB, 1)
    else
        clockBar:SetBackdropBorderColor(0, 0, 0, 1)
    end

    -- Clock text (large, centered)
    clockText = clockBar:CreateFontString(nil, "OVERLAY")
    clockText:SetFont(FONT_BLACK, 16, "OUTLINE")
    clockText:SetPoint("CENTER", clockBar, "CENTER", 0, 0)
    clockText:SetTextColor(0.95, 0.95, 0.97, 1)

    -- S/L label (small, right of clock)
    clockLabel = clockBar:CreateFontString(nil, "OVERLAY")
    clockLabel:SetFont(FONT, 9, "OUTLINE")
    clockLabel:SetPoint("LEFT", clockText, "RIGHT", 4, -2)
    clockLabel:SetTextColor(0.45, 0.45, 0.50, 1)

    -- =========================================
    -- CLOCK INTERACTIONS
    -- =========================================
    clockBar:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    clockBar:SetScript("OnClick", function(self, button)
        local db = DB()
        if not db then return end

        if button == "LeftButton" then
            ToggleCalendar()
        elseif button == "RightButton" then
            if IsShiftKeyDown() then
                db.use24Hour = not db.use24Hour
                local fmt = db.use24Hour and "24h" or "12h"
                print("|cff0cd29fTomoMod|r " .. string.format(L["time_format_msg"], fmt))
            else
                db.useServerTime = not db.useServerTime
                local mode = db.useServerTime and L["time_server"] or L["time_local"]
                print("|cff0cd29fTomoMod|r " .. string.format(L["time_mode_msg"], mode))
            end
            IP.Update()
        end
    end)

    clockBar:SetScript("OnEnter", function(self)
        clockText:SetTextColor(0.047, 0.824, 0.624, 1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -4)
        GameTooltip:ClearLines()
        local db = DB()
        if db then
            local mode = db.useServerTime and L["time_server"] or L["time_local"]
            local fmt = db.use24Hour and "24h" or "12h"
            GameTooltip:AddLine(string.format(L["time_tooltip_title"], mode, fmt), 1, 1, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["time_tooltip_left_click"], 0.8, 0.8, 0.8)
            GameTooltip:AddLine(L["time_tooltip_right_click"], 0.8, 0.8, 0.8)
            GameTooltip:AddLine(L["time_tooltip_shift_right"], 0.8, 0.8, 0.8)
        end
        GameTooltip:Show()
    end)

    clockBar:SetScript("OnLeave", function(self)
        clockText:SetTextColor(0.95, 0.95, 0.97, 1)
        GameTooltip:Hide()
    end)
end

-- =====================================
-- UPDATE
-- =====================================

function IP.Update()
    if not zoneBar or not clockBar then return end
    local db = DB()
    if not db or not db.enabled then return end

    -- Zone name
    zoneText:SetText(GetZoneName())

    -- Subzone with PvP color
    local r, g, b = GetZonePvPColor()
    subZoneText:SetTextColor(r, g, b, 1)
    subZoneText:SetText(GetSubZoneName())

    -- Coords
    if db.showCoords ~= false then
        local x, y = GetPlayerCoords()
        if x and y then
            coordsText:SetText(string.format("%.1f, %.1f", x, y))
            coordsText:Show()
        else
            coordsText:SetText("")
        end
    else
        coordsText:Hide()
    end

    -- Clock
    if db.showTime ~= false then
        clockText:SetText(IP.GetFormattedTime())
        clockLabel:SetText(GetTimeLabel())
        clockBar:Show()
    else
        clockBar:Hide()
    end

    -- Durability
    if durabilityText and db.showDurability ~= false then
        local dur = IP.GetAverageDurability()
        local color
        if dur > 50 then
            color = "|cff00ff00"    -- green
        elseif dur > 25 then
            color = "|cffffff00"    -- yellow
        else
            color = "|cffff0000"    -- red
        end
        durabilityText:SetText(string.format("%s%d%%|r", color, dur))
        durabilityText:Show()
    elseif durabilityText then
        durabilityText:Hide()
    end
end

-- =====================================
-- UPDATE APPEARANCE (border sync)
-- =====================================

function IP.UpdateAppearance()
    if not zoneBar or not clockBar then return end

    local classR, classG, classB = 1, 1, 1
    if TomoMod_Utils and TomoMod_Utils.GetClassColor then
        classR, classG, classB = TomoMod_Utils.GetClassColor()
    end

    local useClass = TomoModDB.minimap.borderColor == "class"
    local bR, bG, bB = 0, 0, 0
    if useClass then bR, bG, bB = classR, classG, classB end

    zoneBar:SetBackdropBorderColor(bR, bG, bB, 1)
    clockBar:SetBackdropBorderColor(bR, bG, bB, 1)
end

-- =====================================
-- HIDE / SHOW
-- =====================================

function IP.Hide()
    if zoneBar then zoneBar:Hide() end
    if subZoneText then subZoneText:Hide() end
    if coordsText then coordsText:Hide() end
    if durabilityText then durabilityText:Hide() end
    if clockBar then clockBar:Hide() end
end

function IP.Show()
    if zoneBar then zoneBar:Show() end
    if subZoneText then subZoneText:Show() end
    if coordsText then coordsText:Show() end
    if durabilityText then durabilityText:Show() end
    if clockBar then clockBar:Show() end
end

-- =====================================
-- SET POSITION (compatibility stub)
-- =====================================

function IP.SetPosition()
    -- No-op: elements are anchored directly to Minimap
end

-- =====================================
-- DURABILITY HELPER
-- =====================================

function IP.GetAverageDurability()
    local total, count = 0, 0
    for slot = 1, 18 do
        local current, maximum = GetInventoryItemDurability(slot)
        if current and maximum and maximum > 0 then
            total = total + (current / maximum * 100)
            count = count + 1
        end
    end
    return count > 0 and (total / count) or 100
end

-- =====================================
-- INITIALIZE
-- =====================================

function IP.Initialize()
    local db = DB()
    if not db or not db.enabled then return end
    if isInitialized then return end

    -- Migration: add new fields if absent
    if db.showCoords == nil then db.showCoords = true end
    if db.showDurability == nil then db.showDurability = true end
    if db.useServerTime == nil then db.useServerTime = true end

    C_Timer.After(1, function()
        HideBlizzardElements()
        CreateUI()
        IP.Update()

        -- Event-driven updates for zone changes
        local evFrame = CreateFrame("Frame")
        evFrame:RegisterEvent("ZONE_CHANGED")
        evFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
        evFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        evFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        evFrame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
        evFrame:SetScript("OnEvent", function()
            C_Timer.After(0.1, IP.Update)
        end)

        -- Throttled OnUpdate for clock + coords (every 1s)
        local elapsed = 0
        local updateFrame = CreateFrame("Frame")
        updateFrame:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= 1 then
                elapsed = 0
                IP.Update()
            end
        end)

        isInitialized = true
    end)
end

-- Alias for compatibility
IP.HideBlizzardClock = HideBlizzardElements

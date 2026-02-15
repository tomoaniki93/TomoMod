-- =====================================
-- QOL/Tooltip/TooltipSkin.lua — ElvUI-Style Tooltip Skin
-- Dark backdrop, class/reaction border, health bar, clean fonts
-- =====================================

TomoMod_TooltipSkin = TomoMod_TooltipSkin or {}
local TS = TomoMod_TooltipSkin

local isInitialized = false

-- =====================================
-- LOCALS
-- =====================================

local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local TEXTURE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"

local function DB()
    return TomoModDB and TomoModDB.tooltipSkin
end

-- =====================================
-- COLOR HELPERS
-- =====================================

local function GetUnitColor(unit)
    if not unit then return 1, 1, 1 end

    -- Player → class color
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class and RAID_CLASS_COLORS[class] then
            local c = RAID_CLASS_COLORS[class]
            return c.r, c.g, c.b
        end
    end

    -- NPC → reaction color
    local reaction = UnitReaction(unit, "player")
    if reaction then
        if reaction >= 5 then return 0.11, 0.75, 0.11 end   -- friendly (green)
        if reaction == 4 then return 0.95, 0.80, 0.10 end   -- neutral  (yellow)
        if reaction <= 3 then return 0.78, 0.04, 0.04 end   -- hostile  (red)
    end

    -- Tapped / Dead
    if UnitIsTapDenied(unit) then return 0.50, 0.50, 0.50 end
    if UnitIsDead(unit)      then return 0.50, 0.50, 0.50 end

    return 1, 1, 1
end

-- Item quality color for item tooltips
local function GetItemQualityColor(tooltip)
    local _, item = tooltip:GetItem()
    if item then
        local _, _, quality = C_Item.GetItemInfo(item)
        if quality and quality >= 2 then
            local c = ITEM_QUALITY_COLORS[quality]
            if c then return c.r, c.g, c.b end
        end
    end
    return nil
end

-- =====================================
-- BACKDROP
-- =====================================

local backdropInfo = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = 0, right = 0, top = 0, bottom = 0 },
}

local function SkinTooltipBackdrop(tooltip)
    if not tooltip or not tooltip.SetBackdrop then return end
    local db = DB()
    if not db or not db.enabled then return end

    tooltip:SetBackdrop(backdropInfo)

    local bg = db.bgColor or {}
    tooltip:SetBackdropColor(bg.r or 0.08, bg.g or 0.08, bg.b or 0.10, db.bgAlpha or 0.92)
    tooltip:SetBackdropBorderColor(0, 0, 0, 1)

    -- Kill Blizzard NineSlice art
    if tooltip.NineSlice then
        tooltip.NineSlice:SetAlpha(0)
    end
end

-- =====================================
-- COLORED BORDER (class / reaction / item quality)
-- =====================================

local tooltipBorders = {}

local function EnsureBorder(tooltip)
    if tooltipBorders[tooltip] then return end

    -- Outer 1px black border
    local outer = CreateFrame("Frame", nil, tooltip, "BackdropTemplate")
    outer:SetPoint("TOPLEFT", -1, 1)
    outer:SetPoint("BOTTOMRIGHT", 1, -1)
    outer:SetFrameLevel(tooltip:GetFrameLevel() + 1)
    outer:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    outer:SetBackdropBorderColor(0, 0, 0, 1)

    -- Inner colored border (flush)
    local inner = CreateFrame("Frame", nil, tooltip, "BackdropTemplate")
    inner:SetPoint("TOPLEFT", 0, 0)
    inner:SetPoint("BOTTOMRIGHT", 0, 0)
    inner:SetFrameLevel(tooltip:GetFrameLevel() + 2)
    inner:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    inner:SetBackdropBorderColor(0.30, 0.30, 0.35, 0.6)

    tooltipBorders[tooltip] = { outer = outer, inner = inner }
end

local function SetBorderColor(tooltip, r, g, bv)
    local borders = tooltipBorders[tooltip]
    if borders then borders.inner:SetBackdropBorderColor(r, g, bv, 0.7) end
end

local function ResetBorderColor(tooltip)
    local borders = tooltipBorders[tooltip]
    if borders then borders.inner:SetBackdropBorderColor(0.30, 0.30, 0.35, 0.6) end
end

-- =====================================
-- HEALTH BAR
-- =====================================

local healthBar, healthBarText

local function CreateHealthBar(tooltip)
    if healthBar then return end

    -- Restyle Blizzard's existing GameTooltipStatusBar
    local bar = GameTooltipStatusBar or _G["GameTooltipStatusBar"]
    if not bar then return end

    healthBar = bar
    healthBar:ClearAllPoints()
    healthBar:SetPoint("BOTTOMLEFT",  tooltip, "BOTTOMLEFT",  2, 2)
    healthBar:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -2, 2)
    healthBar:SetHeight(8)
    healthBar:SetStatusBarTexture(TEXTURE)
    healthBar:GetStatusBarTexture():SetHorizTile(false)

    -- Dark BG
    if not healthBar._tmBG then
        local bg = healthBar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(TEXTURE)
        bg:SetVertexColor(0.06, 0.06, 0.08, 0.8)
        healthBar._tmBG = bg
    end

    -- 1px black border around bar
    if not healthBar._tmBorder then
        for _, info in ipairs({
            {"TOPLEFT","TOPLEFT","TOPRIGHT","TOPRIGHT", nil, 1},
            {"BOTTOMLEFT","BOTTOMLEFT","BOTTOMRIGHT","BOTTOMRIGHT", nil, 1},
            {"TOPLEFT","TOPLEFT","BOTTOMLEFT","BOTTOMLEFT", 1, nil},
            {"TOPRIGHT","TOPRIGHT","BOTTOMRIGHT","BOTTOMRIGHT", 1, nil},
        }) do
            local t = healthBar:CreateTexture(nil, "OVERLAY", nil, 7)
            t:SetColorTexture(0, 0, 0, 1)
            t:SetPoint(info[1], healthBar, info[2])
            t:SetPoint(info[3], healthBar, info[4])
            if info[5] then t:SetWidth(info[5]) end
            if info[6] then t:SetHeight(info[6]) end
        end
        healthBar._tmBorder = true
    end

    -- HP text centered on bar
    if not healthBar._tmText then
        local text = healthBar:CreateFontString(nil, "OVERLAY")
        text:SetFont(FONT, 8, "OUTLINE")
        text:SetPoint("CENTER", 0, 0)
        text:SetTextColor(1, 1, 1, 1)
        healthBar._tmText = text
    end
    healthBarText = healthBar._tmText
end

-- TWW-safe: StatusBar C-side methods handle secret numbers,
-- AbbreviateLargeNumbers + SetFormattedText are both C-side
local function UpdateHealthBar(unit)
    if not healthBar or not healthBarText then return end
    local db = DB()
    if not db or not db.enabled or not db.showHealthBar
       or not unit or not UnitExists(unit) then
        healthBar:Hide()
        return
    end

    local current = UnitHealth(unit)
    local max     = UnitHealthMax(unit)

    healthBar:SetMinMaxValues(0, max)
    healthBar:SetValue(current)

    local r, g, b = GetUnitColor(unit)
    healthBar:SetStatusBarColor(r, g, b, 1)

    if db.showHealthText then
        if UnitIsDead(unit) then
            healthBarText:SetText("Dead")
        elseif UnitIsGhost(unit) then
            healthBarText:SetText("Ghost")
        else
            -- C-side chain: AbbreviateLargeNumbers → SetFormattedText
            healthBarText:SetFormattedText("%s / %s",
                AbbreviateLargeNumbers(current),
                AbbreviateLargeNumbers(max))
        end
        healthBarText:Show()
    else
        healthBarText:Hide()
    end

    healthBar:SetHeight(db.healthBarHeight or 8)
    healthBar:Show()
end

-- =====================================
-- FONT RESTYLING
-- =====================================

local function RestyleFonts(tooltip)
    local db = DB()
    if not db or not db.enabled then return end

    local fontSize = db.fontSize or 12
    local font     = db.font or FONT
    local name     = tooltip:GetName()
    if not name then return end

    -- Header (unit name) — larger + outline
    local header = _G[name .. "TextLeft1"]
    if header then header:SetFont(font, fontSize + 1, "OUTLINE") end

    -- Body lines
    for i = 2, 30 do
        local left  = _G[name .. "TextLeft" .. i]
        local right = _G[name .. "TextRight" .. i]
        if left  then left:SetFont(font, fontSize, "")  end
        if right then right:SetFont(font, fontSize, "") end
    end
end

-- =====================================
-- HOOKS
-- =====================================

local currentUnit  = nil
local healthTicker = nil

-- UNIT tooltip: class/reaction border + health bar
local function OnTooltipSetUnit(tooltip, data)
    local db = DB()
    if not db or not db.enabled then return end

    local _, unit = tooltip:GetUnit()
    if not unit then return end
    currentUnit = unit

    SkinTooltipBackdrop(tooltip)
    EnsureBorder(tooltip)

    local r, g, b = GetUnitColor(unit)
    SetBorderColor(tooltip, r, g, b)

    CreateHealthBar(tooltip)
    UpdateHealthBar(unit)
    RestyleFonts(tooltip)

    -- Bottom padding so text doesn't overlap health bar
    if db.showHealthBar and healthBar and healthBar:IsShown() then
        tooltip:SetPadding(0, (db.healthBarHeight or 8) + 4)
    end

    -- [PERF] Ticker only while hovering a unit — cancelled on clear
    if not healthTicker then
        healthTicker = C_Timer.NewTicker(0.2, function()
            if currentUnit and UnitExists(currentUnit) then
                UpdateHealthBar(currentUnit)
            end
        end)
    end
end

-- ITEM tooltip: quality-colored border
local function OnTooltipSetItem(tooltip, data)
    local db = DB()
    if not db or not db.enabled or not db.itemQualityBorder then return end

    local r, g, b = GetItemQualityColor(tooltip)
    if r then
        SkinTooltipBackdrop(tooltip)
        EnsureBorder(tooltip)
        SetBorderColor(tooltip, r, g, b)
    end
end

-- Generic OnShow: skin backdrop + border
local function OnTooltipShow(tooltip)
    local db = DB()
    if not db or not db.enabled then return end

    SkinTooltipBackdrop(tooltip)
    EnsureBorder(tooltip)
    ResetBorderColor(tooltip)
    RestyleFonts(tooltip)
end

-- Cleanup
local function OnTooltipCleared(tooltip)
    currentUnit = nil

    if healthTicker then
        healthTicker:Cancel()
        healthTicker = nil
    end

    if healthBar     then healthBar:Hide()     end
    if healthBarText then healthBarText:SetText("") end

    if tooltip.SetPadding then tooltip:SetPadding(0, 0) end

    ResetBorderColor(tooltip)
end

-- =====================================
-- SKIN ADDITIONAL TOOLTIPS
-- =====================================

local skinnedTooltips = {}

local function SkinAdditionalTooltip(tt)
    if not tt or skinnedTooltips[tt] then return end
    skinnedTooltips[tt] = true
    tt:HookScript("OnShow", function(self)
        local db = DB()
        if not db or not db.enabled then return end
        SkinTooltipBackdrop(self)
        EnsureBorder(self)
    end)
end

-- =====================================
-- INITIALIZE
-- =====================================

function TS.Initialize()
    if isInitialized then return end
    local db = DB()
    if not db or not db.enabled then return end

    -- TWW TooltipDataProcessor hooks
    if TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
    end

    GameTooltip:HookScript("OnShow", OnTooltipShow)
    GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)

    -- Skin secondary tooltips
    for _, tt in ipairs({
        ShoppingTooltip1, ShoppingTooltip2,
        ItemRefTooltip,
        ItemRefShoppingTooltip1, ItemRefShoppingTooltip2,
        EmbeddedItemTooltip,
    }) do
        if tt then SkinAdditionalTooltip(tt) end
    end

    isInitialized = true
end

function TS.SetEnabled(enabled)
    local db = DB()
    if not db then return end
    db.enabled = enabled

    if enabled and not isInitialized then
        TS.Initialize()
    end

    if enabled then
        print("|cff0cd29fTomoMod:|r " .. (TomoMod_L and TomoMod_L["msg_tooltip_skin_enabled"] or "Tooltip Skin enabled"))
    else
        print("|cff0cd29fTomoMod:|r " .. (TomoMod_L and TomoMod_L["msg_tooltip_skin_disabled"] or "Tooltip Skin disabled (reload to fully revert)"))
    end
end

-- Export
_G.TomoMod_TooltipSkin = TS

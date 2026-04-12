-- =====================================
-- TooltipSkin.lua
-- Skins the Blizzard GameTooltip
-- Dark background, class-colored names, guild color, hide realm/title
-- Inspired by BetterTooltips — adapted for TomoMod aesthetic
-- Compatible with WoW 12.x (TWW / Midnight)
-- =====================================

TomoMod_TooltipSkin = TomoMod_TooltipSkin or {}
local TS = TomoMod_TooltipSkin

-- =====================================
-- LOCALS & CACHES
-- =====================================

local ADDON_FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ADDON_TEXTURE   = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"

local isInitialized = false
local isHooked      = false

-- Palette
local ACCENT     = { 0.047, 0.824, 0.624 }
local BG_COLOR   = { 0.06, 0.06, 0.08 }
local BORDER_CLR = { 0.20, 0.20, 0.24 }
local GUILD_CLR  = { 0.047, 0.824, 0.624 }

local gsub = string.gsub
local find = string.find

-- =====================================
-- SETTINGS
-- =====================================

local function S()
    return TomoModDB and TomoModDB.tooltipSkin or {}
end

local function IsEnabled()
    return S().enabled
end

-- =====================================
-- SAFE HELPERS (TWW secret-value proof)
-- =====================================

local function IsSecretValue(value)
    return type(issecurevalue) == "function" and issecurevalue(value)
        or type(issecretvalue) == "function" and issecretvalue(value)
end

local function StripColorCodes(text)
    if not text then return nil end
    if IsSecretValue(text) then return nil end
    text = gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    return gsub(text, "|r", "")
end

local function StripServerSuffix(nameText)
    if not nameText or nameText == "" then return nameText end
    if IsSecretValue(nameText) then return nameText end
    return gsub(nameText, "%-[^%-%s]+$", "")
end

-- =====================================
-- GET UNIT FROM TOOLTIP
-- =====================================

local function GetTooltipUnit(tooltip)
    if not tooltip or not tooltip.GetUnit then return nil end
    local ok, _, unit = pcall(tooltip.GetUnit, tooltip)
    if not ok or type(unit) ~= "string" then return nil end
    if IsSecretValue(unit) then return nil end
    return unit
end

-- =====================================
-- SKIN BACKGROUND & BORDER
-- =====================================

local skinnedTooltips = setmetatable({}, { __mode = "k" })

local function SkinTooltipBackground(tooltip)
    if not tooltip then return end
    local s = S()

    -- NineSlice background
    if tooltip.NineSlice then
        -- Darken background
        if tooltip.NineSlice.Center then
            tooltip.NineSlice.Center:SetVertexColor(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3])
            tooltip.NineSlice.Center:SetAlpha(s.bgAlpha or 0.92)
        end

        -- Darken border pieces
        local borderPieces = {
            "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
            "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
        }
        for _, pieceName in ipairs(borderPieces) do
            local piece = tooltip.NineSlice[pieceName]
            if piece then
                piece:SetVertexColor(BORDER_CLR[1], BORDER_CLR[2], BORDER_CLR[3])
                piece:SetAlpha(s.borderAlpha or 0.8)
            end
        end
    end

    -- Accent line at top
    if not tooltip._tomoAccent then
        local accent = tooltip:CreateTexture(nil, "OVERLAY")
        accent:SetHeight(1)
        accent:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 4, -3)
        accent:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -4, -3)
        accent:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.5)
        tooltip._tomoAccent = accent
    end
end

-- =====================================
-- SKIN HEALTH BAR
-- =====================================

local function SkinHealthBar(tooltip)
    local statusBar = tooltip.StatusBar or _G[tooltip:GetName() .. "StatusBar"]
    if not statusBar then return end

    local s = S()
    if s.hideHealthBar then
        statusBar:Hide()
        if not statusBar._tomoHideHooked then
            statusBar:HookScript("OnShow", function(self)
                if IsEnabled() and S().hideHealthBar then
                    self:Hide()
                end
            end)
            statusBar._tomoHideHooked = true
        end
        return
    end

    -- Style the health bar
    if not statusBar._tomoStyled then
        statusBar:SetStatusBarTexture(ADDON_TEXTURE)
        statusBar:SetStatusBarColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.9)

        local bg = statusBar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.08, 0.08, 0.10, 0.8)

        statusBar._tomoStyled = true
    end
end

-- =====================================
-- CLASS-COLORED PLAYER NAMES
-- =====================================

local function ApplyClassColorName(tooltip)
    local s = S()
    if not s.useClassColorNames then return end

    local unit = GetTooltipUnit(tooltip)
    if not unit then return end
    local ok, isPlayer = pcall(UnitIsPlayer, unit)
    if not ok or not isPlayer then return end

    local _, classToken = UnitClass(unit)
    if not classToken then return end

    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    if not color then return end

    local nameLine = _G[tooltip:GetName() .. "TextLeft1"]
    if nameLine then
        nameLine:SetTextColor(color.r, color.g, color.b)
    end
end

-- =====================================
-- HIDE SERVER / TITLE
-- =====================================

local function ApplyNameFormatting(tooltip)
    local s = S()
    local hideServer = s.hidePlayerServer
    local hideTitle  = s.hidePlayerTitle
    if not hideServer and not hideTitle then return end

    local unit = GetTooltipUnit(tooltip)
    if not unit then return end
    local ok, isPlayer = pcall(UnitIsPlayer, unit)
    if not ok or not isPlayer then return end

    local nameLine = _G[tooltip:GetName() .. "TextLeft1"]
    if not nameLine then return end

    local nameText
    if hideTitle then
        local name, realm = UnitName(unit)
        if not name or name == "" then return end
        if hideServer or not realm or realm == "" then
            nameText = name
        else
            nameText = name .. "-" .. realm
        end
    else
        nameText = UnitPVPName(unit) or GetUnitName(unit, true)
        if not nameText or nameText == "" then return end
        if hideServer then
            nameText = StripServerSuffix(nameText)
        end
    end

    if nameText and nameText ~= "" then
        nameLine:SetText(nameText)
    end
end

-- =====================================
-- GUILD NAME COLOR
-- =====================================

local function ApplyGuildColor(tooltip)
    local s = S()
    if not s.useGuildNameColor then return end

    local unit = GetTooltipUnit(tooltip)
    if not unit then return end
    local ok, isPlayer = pcall(UnitIsPlayer, unit)
    if not ok or not isPlayer then return end

    local guildColor = s.guildNameColor or GUILD_CLR
    local r = guildColor.r or guildColor[1] or GUILD_CLR[1]
    local g = guildColor.g or guildColor[2] or GUILD_CLR[2]
    local b = guildColor.b or guildColor[3] or GUILD_CLR[3]

    local guildName = GetGuildInfo(unit)
    local tooltipName = tooltip:GetName()

    for i = 2, math.min(tooltip:NumLines(), 4) do
        local leftText = _G[tooltipName .. "TextLeft" .. i]
        if leftText then
            local plain = StripColorCodes(leftText:GetText())
            if plain and plain ~= "" then
                if guildName and (plain == guildName or plain == "<" .. guildName .. ">") then
                    leftText:SetTextColor(r, g, b)
                    return
                end
            end
        end
    end
end

-- =====================================
-- FONT RESTYLING
-- =====================================

local function ApplyFonts(tooltip)
    local s = S()
    local fontSize = s.fontSize or 12
    local tooltipName = tooltip:GetName()

    for i = 1, tooltip:NumLines() do
        local leftText = _G[tooltipName .. "TextLeft" .. i]
        local rightText = _G[tooltipName .. "TextRight" .. i]

        if leftText then
            if i == 1 then
                pcall(leftText.SetFont, leftText, ADDON_FONT_BOLD, fontSize + 1, "")
            else
                pcall(leftText.SetFont, leftText, ADDON_FONT, fontSize, "")
            end
        end
        if rightText then
            pcall(rightText.SetFont, rightText, ADDON_FONT, fontSize, "")
        end
    end
end

-- =====================================
-- MASTER HOOK — applies all styling on Show/SetUnit
-- =====================================

local function OnTooltipShow(tooltip)
    if not IsEnabled() then return end
    if tooltip.IsForbidden and tooltip:IsForbidden() then return end

    SkinTooltipBackground(tooltip)
    SkinHealthBar(tooltip)
    ApplyFonts(tooltip)
    ApplyNameFormatting(tooltip)
    ApplyClassColorName(tooltip)
    ApplyGuildColor(tooltip)
end

local function OnTooltipSetUnit(tooltip)
    if not IsEnabled() then return end
    if tooltip.IsForbidden and tooltip:IsForbidden() then return end

    ApplyNameFormatting(tooltip)
    ApplyClassColorName(tooltip)
    ApplyGuildColor(tooltip)
end

-- =====================================
-- PUBLIC API
-- =====================================

function TS.SetEnabled(value)
    if not TomoModDB or not TomoModDB.tooltipSkin then return end
    TomoModDB.tooltipSkin.enabled = value
end

function TS.ApplySettings()
    -- Settings take effect on next tooltip show (no refresh needed)
end

function TS.Initialize()
    if isInitialized then return end
    if not IsEnabled() then return end

    if not isHooked then
        isHooked = true

        -- Hook GameTooltip
        hooksecurefunc(GameTooltip, "Show", function() OnTooltipShow(GameTooltip) end)
        hooksecurefunc(GameTooltip, "SetUnit", function() OnTooltipSetUnit(GameTooltip) end)

        -- Hook Shopping tooltips (item comparison)
        if ShoppingTooltip1 then
            hooksecurefunc(ShoppingTooltip1, "Show", function() OnTooltipShow(ShoppingTooltip1) end)
        end
        if ShoppingTooltip2 then
            hooksecurefunc(ShoppingTooltip2, "Show", function() OnTooltipShow(ShoppingTooltip2) end)
        end

        -- Hook ItemRefTooltip (linked items in chat)
        if ItemRefTooltip then
            hooksecurefunc(ItemRefTooltip, "Show", function() OnTooltipShow(ItemRefTooltip) end)
        end
    end

    isInitialized = true
end

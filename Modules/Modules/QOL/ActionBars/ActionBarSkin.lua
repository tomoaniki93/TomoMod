-- =====================================
-- ActionBarSkin.lua v4.0.0
-- Multi-style button skinning (Classic / Flat / Outlined / Glass / Minimal)
-- Uses AB.BAR_DEFS as single source of truth.
-- Opacity, fade, visibility now handled by ActionBars.lua.
-- =====================================

TomoMod_ActionBarSkin = TomoMod_ActionBarSkin or {}
local ABS = TomoMod_ActionBarSkin
local AB  = TomoMod_ActionBars

-- =====================================================================
-- CONSTANTS
-- =====================================================================
local FONT        = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local BORDER_TEX  = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Nameplates\\border.png"
local BORDER_CORNER = 5
local ICON_INSET    = 3

local SKIN_STYLES = { "classic", "flat", "outlined", "glass", "minimal" }

local skinnedButtons  = {}
local classColor      = nil

-- =====================================================================
-- HELPERS
-- =====================================================================
local function GetSettings()
    if not TomoModDB or not TomoModDB.actionBarSkin then return nil end
    return TomoModDB.actionBarSkin
end

local function GetSkinStyle()
    local s = GetSettings()
    return (s and s.skinStyle) or "classic"
end

local function GetBorderColor()
    local settings = GetSettings()
    if settings and settings.useClassColor then
        if not classColor then
            local _, class = UnitClass("player")
            classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] or { r = 0.3, g = 0.3, b = 0.4 }
        end
        return classColor.r, classColor.g, classColor.b, 1
    end
    return 0.047, 0.824, 0.624, 1
end

-- =====================================================================
-- 9-SLICE BORDER (Classic style)
-- =====================================================================
local function Create9SliceBorder(parent, r, g, b, a)
    a = a or 1
    local parts = {}
    local function Tex()
        local t = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetTexture(BORDER_TEX)
        if r then t:SetVertexColor(r, g, b, a) end
        parts[#parts + 1] = t
        return t
    end
    local c = BORDER_CORNER
    local tl = Tex(); tl:SetSize(c, c); tl:SetPoint("TOPLEFT");    tl:SetTexCoord(0, 0.5, 0, 0.5)
    local tr = Tex(); tr:SetSize(c, c); tr:SetPoint("TOPRIGHT");   tr:SetTexCoord(0.5, 1, 0, 0.5)
    local bl = Tex(); bl:SetSize(c, c); bl:SetPoint("BOTTOMLEFT"); bl:SetTexCoord(0, 0.5, 0.5, 1)
    local br = Tex(); br:SetSize(c, c); br:SetPoint("BOTTOMRIGHT");br:SetTexCoord(0.5, 1, 0.5, 1)
    local top = Tex(); top:SetHeight(c)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("TOPRIGHT", tr, "TOPLEFT")
    top:SetTexCoord(0.5, 0.5, 0, 0.5)
    local bot = Tex(); bot:SetHeight(c)
    bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT"); bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
    bot:SetTexCoord(0.5, 0.5, 0.5, 1)
    local left = Tex(); left:SetWidth(c)
    left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT")
    left:SetTexCoord(0, 0.5, 0.5, 0.5)
    local right = Tex(); right:SetWidth(c)
    right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT"); right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
    right:SetTexCoord(0.5, 1, 0.5, 0.5)
    return parts
end

-- =====================================================================
-- FLAT BORDER
-- =====================================================================
local function CreateFlatBorder(parent, r, g, b, a)
    local parts = {}
    local function Edge()
        local t = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(r, g, b, a or 1)
        return t
    end
    local top = Edge(); top:SetHeight(1)
    top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT")
    parts[1] = top
    local bot = Edge(); bot:SetHeight(1)
    bot:SetPoint("BOTTOMLEFT"); bot:SetPoint("BOTTOMRIGHT")
    parts[2] = bot
    local lft = Edge(); lft:SetWidth(1)
    lft:SetPoint("TOPLEFT"); lft:SetPoint("BOTTOMLEFT")
    parts[3] = lft
    local rgt = Edge(); rgt:SetWidth(1)
    rgt:SetPoint("TOPRIGHT"); rgt:SetPoint("BOTTOMRIGHT")
    parts[4] = rgt
    return parts
end

-- =====================================================================
-- SKIN A SINGLE BUTTON
-- =====================================================================
local function SkinButton(button)
    if not button then return end
    if skinnedButtons[button] then return end

    local name = button:GetName()
    if not name then return end
    local icon = button.icon or button.Icon
    if not icon then return end

    skinnedButtons[button] = true
    local style = GetSkinStyle()
    local bR, bG, bB, bA = GetBorderColor()

    -- Hide Blizzard default textures
    local normal = button:GetNormalTexture()
    if normal then normal:SetTexture(nil); normal:SetAlpha(0); normal:Hide() end
    local pushed = button:GetPushedTexture()
    if pushed then pushed:SetTexture(nil); pushed:SetAlpha(0) end

    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetColorTexture(1, 1, 1, 0.10)
        highlight:ClearAllPoints()
        highlight:SetPoint("TOPLEFT",     ICON_INSET, -ICON_INSET)
        highlight:SetPoint("BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
    end

    if button.GetCheckedTexture then
        local ok, checked = pcall(button.GetCheckedTexture, button)
        if ok and checked then
            checked:SetColorTexture(1, 1, 1, 0.14)
            checked:ClearAllPoints()
            checked:SetPoint("TOPLEFT",     ICON_INSET, -ICON_INSET)
            checked:SetPoint("BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
        end
    end

    if button.SlotArt     then button.SlotArt:Hide() end
    if button.IconMask    then button.IconMask:Hide() end
    if button.SlotBackground then button.SlotBackground:Hide() end
    if icon.SetMask       then pcall(icon.SetMask, icon, nil) end

    -- Background
    local bgAlpha
    if     style == "classic"  then bgAlpha = 1.0
    elseif style == "flat"     then bgAlpha = 0.92
    elseif style == "outlined" then bgAlpha = 0.30
    elseif style == "glass"    then bgAlpha = 0.45
    elseif style == "minimal"  then bgAlpha = 0.85
    end

    local bg = button:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetAllPoints()
    if style == "glass" then
        bg:SetColorTexture(0.06, 0.08, 0.14, bgAlpha)
    elseif style == "minimal" then
        bg:SetColorTexture(0.04, 0.04, 0.06, bgAlpha)
    else
        bg:SetColorTexture(0.05, 0.05, 0.10, bgAlpha)
    end
    button._tmBG = bg

    -- Inset icon
    local inset = (style == "minimal") and 2 or ICON_INSET
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT",     inset, -inset)
    icon:SetPoint("BOTTOMRIGHT", -inset, inset)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Border
    local borderParts
    if style == "classic" then
        borderParts = Create9SliceBorder(button, bR, bG, bB, bA)
    elseif style == "flat" or style == "outlined" then
        local edgeAlpha = (style == "outlined") and 0.55 or bA
        borderParts = CreateFlatBorder(button, bR, bG, bB, edgeAlpha)
    elseif style == "glass" then
        local glow = button:CreateTexture(nil, "OVERLAY", nil, 6)
        glow:SetPoint("TOPLEFT", -1, 1)
        glow:SetPoint("BOTTOMRIGHT", 1, -1)
        glow:SetColorTexture(bR * 0.6, bG * 0.6, bB * 0.6, 0.18)
        borderParts = CreateFlatBorder(button, bR, bG, bB, 0.60)
        borderParts[5] = glow
    elseif style == "minimal" then
        borderParts = {}
        local shadowTop = button:CreateTexture(nil, "ARTWORK", nil, 1)
        shadowTop:SetHeight(2)
        shadowTop:SetPoint("TOPLEFT", inset, -inset)
        shadowTop:SetPoint("TOPRIGHT", -inset, -inset)
        shadowTop:SetColorTexture(0, 0, 0, 0.35)
        borderParts[1] = shadowTop
        local shadowLeft = button:CreateTexture(nil, "ARTWORK", nil, 1)
        shadowLeft:SetWidth(2)
        shadowLeft:SetPoint("TOPLEFT", inset, -inset)
        shadowLeft:SetPoint("BOTTOMLEFT", inset, inset)
        shadowLeft:SetColorTexture(0, 0, 0, 0.25)
        borderParts[2] = shadowLeft
        local hlBot = button:CreateTexture(nil, "ARTWORK", nil, 1)
        hlBot:SetHeight(1)
        hlBot:SetPoint("BOTTOMLEFT", inset, inset)
        hlBot:SetPoint("BOTTOMRIGHT", -inset, inset)
        hlBot:SetColorTexture(1, 1, 1, 0.04)
        borderParts[3] = hlBot
    end
    button._tmBorder = borderParts

    -- Pushed overlay (polled, not hooked — avoids taint)
    if not button._tmPushed then
        local pushOverlay = button:CreateTexture(nil, "OVERLAY", nil, 5)
        pushOverlay:SetPoint("TOPLEFT",     inset, -inset)
        pushOverlay:SetPoint("BOTTOMRIGHT", -inset, inset)
        pushOverlay:SetColorTexture(0, 0, 0, 0.30)
        pushOverlay:Hide()
        button._tmPushed = pushOverlay
    end

    -- Cooldown alignment
    local cooldown = button.cooldown or _G[name .. "Cooldown"]
    if cooldown then
        cooldown:ClearAllPoints()
        cooldown:SetPoint("TOPLEFT",     icon, "TOPLEFT")
        cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
    end

    -- Text elements
    local hotkey = button.HotKey or _G[name .. "HotKey"]
    if hotkey then
        hotkey:SetFont(FONT, 12, "OUTLINE")
        hotkey:ClearAllPoints()
        hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
        hotkey:SetJustifyH("RIGHT")
    end
    local count = button.Count or _G[name .. "Count"]
    if count then
        count:SetFont(FONT, 12, "OUTLINE")
        count:ClearAllPoints()
        count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    end
    local macroName = button.Name or _G[name .. "Name"]
    if macroName then
        macroName:SetFont(FONT, 8, "OUTLINE")
        macroName:ClearAllPoints()
        macroName:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
    end

    if button.Border then button.Border:SetTexture(nil); button.Border:Hide() end
    local flash = button.Flash or _G[name .. "Flash"]
    if flash then
        flash:ClearAllPoints()
        flash:SetPoint("TOPLEFT",     inset, -inset)
        flash:SetPoint("BOTTOMRIGHT", -inset, inset)
        flash:SetColorTexture(1, 0.2, 0.2, 0.30)
    end

    -- Register for range polling
    if not button._tmRangeRegistered and button.action then
        button._tmRangeRegistered = true
        button._tmIcon = icon
    end
end

-- =====================================================================
-- EXTERNAL POLLING FRAME (range-check + pushed state)
-- =====================================================================
local _tmRangeFrame = CreateFrame("Frame")
local _tmRangeTimer = 0
_tmRangeFrame:SetScript("OnUpdate", function(self, elapsed)
    _tmRangeTimer = _tmRangeTimer + elapsed
    if _tmRangeTimer < 0.2 then return end
    _tmRangeTimer = 0
    for button in pairs(skinnedButtons) do
        local icon = button._tmIcon
        if icon and button.action then
            local action = button.action
            if IsActionInRange and IsActionInRange(action) == false then
                icon:SetVertexColor(0.8, 0.2, 0.2)
            elseif IsUsableAction then
                local usable, noMana = IsUsableAction(action)
                if noMana then
                    icon:SetVertexColor(0.3, 0.3, 0.9)
                elseif not usable then
                    icon:SetVertexColor(0.4, 0.4, 0.4)
                else
                    icon:SetVertexColor(1, 1, 1)
                end
            else
                icon:SetVertexColor(1, 1, 1)
            end
        end
        local pushOverlay = button._tmPushed
        if pushOverlay then
            local state = button:GetButtonState()
            pushOverlay:SetShown(state == "PUSHED")
        end
    end
end)

-- =====================================================================
-- SKIN ALL BUTTONS (uses AB.BAR_DEFS)
-- =====================================================================
local function SkinAllButtons()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    if AB and AB.BAR_DEFS then
        for _, def in ipairs(AB.BAR_DEFS) do
            local buttons = AB.GetButtons and AB.GetButtons(def.id)
            if buttons then
                for _, btn in ipairs(buttons) do
                    SkinButton(btn)
                end
            else
                -- Fallback: use global button names
                for i = 1, def.count do
                    local btn = _G[def.prefix .. i]
                    if btn then SkinButton(btn) end
                end
            end
        end
    end

    -- Also skin override/extra buttons (not in BAR_DEFS)
    for i = 1, 6 do
        local btn = _G["OverrideActionBarButton" .. i]
        if btn then SkinButton(btn) end
    end
    local extra = _G["ExtraActionButton1"]
    if extra then SkinButton(extra) end
end

-- =====================================================================
-- UPDATE BORDER COLORS
-- =====================================================================
function ABS.UpdateColors()
    classColor = nil
    local r, g, b, a = GetBorderColor()
    for button in pairs(skinnedButtons) do
        if button._tmBorder then
            for _, part in ipairs(button._tmBorder) do
                if part and part.SetVertexColor then
                    part:SetVertexColor(r, g, b, a)
                elseif part and part.SetColorTexture then
                    part:SetColorTexture(r, g, b, a)
                end
            end
        end
    end
end

-- =====================================================================
-- RESKIN (change style) — clear and re-skin all buttons
-- =====================================================================
function ABS.Reskin()
    for button in pairs(skinnedButtons) do
        if button._tmBorder then
            for _, part in ipairs(button._tmBorder) do
                if part and part.Hide then part:Hide() end
            end
        end
        if button._tmBG then button._tmBG:Hide() end
    end
    wipe(skinnedButtons)
    SkinAllButtons()
end

-- =====================================================================
-- RESKIN A SINGLE BAR (called from AB.RefreshBar)
-- =====================================================================
function ABS.ReskinBar(id)
    if not AB or not AB.GetButtons then return end
    local buttons = AB.GetButtons(id)
    if not buttons then return end
    for _, btn in ipairs(buttons) do
        -- Clear old skin data
        if skinnedButtons[btn] then
            if btn._tmBorder then
                for _, part in ipairs(btn._tmBorder) do
                    if part and part.Hide then part:Hide() end
                end
            end
            if btn._tmBG then btn._tmBG:Hide() end
            skinnedButtons[btn] = nil
        end
        SkinButton(btn)
    end
end

-- =====================================================================
-- ENABLE / DISABLE
-- =====================================================================
function ABS.SetEnabled(val)
    local settings = GetSettings()
    if not settings then return end
    if val then
        SkinAllButtons()
    else
        for button in pairs(skinnedButtons) do
            if button._tmBorder then
                for _, part in ipairs(button._tmBorder) do
                    if part and part.Hide then part:Hide() end
                end
            end
            if button._tmBG then button._tmBG:Hide() end
            local n = button:GetNormalTexture()
            if n then n:SetAlpha(1); n:Show() end
            if button.SlotArt     then button.SlotArt:Show() end
            if button.SlotBackground then button.SlotBackground:Show() end
        end
        wipe(skinnedButtons)
    end
end

-- =====================================================================
-- BOOT
-- =====================================================================
local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function()
    local settings = GetSettings()
    if settings and settings.enabled then
        -- Delay to let ActionBars.lua create containers first
        C_Timer.After(1.0, function()
            SkinAllButtons()
        end)
    end
end)

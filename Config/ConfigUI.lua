-- =====================================
-- ConfigUI.lua — Custom Dark-Themed Config Panel
-- Sidebar navigation, no Blizzard Options dependency
-- =====================================

TomoMod_Config = TomoMod_Config or {}
local C = TomoMod_Config
local W = TomoMod_Widgets
local T = W.Theme

local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

local configFrame
local currentCategory = nil
local categoryPanels = {}
local categoryButtons = {}

-- =====================================
-- CATEGORIES
-- =====================================

local categories = {
    { key = "general",    label = "Général",     icon = "°", builder = "TomoMod_ConfigPanel_General" },
    { key = "unitframes", label = "UnitFrames",  icon = "°", builder = "TomoMod_ConfigPanel_UnitFrames" },
    { key = "nameplates", label = "Nameplates",  icon = "°", builder = "TomoMod_ConfigPanel_Nameplates" },
    { key = "resources",  label = "CD & Ressource", icon = "°", builder = "TomoMod_ConfigPanel_CooldownResource" },
    { key = "qol",        label = "QOL / Auto",  icon = "°", builder = "TomoMod_ConfigPanel_QOL" },
    { key = "profiles",   label = "Profils",     icon = "°", builder = "TomoMod_ConfigPanel_Profiles" },
}

-- =====================================
-- CREATE MAIN FRAME
-- =====================================

local function CreateConfigFrame()
    if configFrame then return end

    configFrame = CreateFrame("Frame", "TomoModConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(720, 560)
    configFrame:SetPoint("CENTER")
    configFrame:SetFrameStrata("HIGH")
    configFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    configFrame:SetBackdropColor(unpack(T.bg))
    configFrame:SetBackdropBorderColor(unpack(T.border))
    configFrame:SetMovable(true)
    configFrame:SetClampedToScreen(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    configFrame:Hide()

    -- Close with Escape
    tinsert(UISpecialFrames, "TomoModConfigFrame")

    -- =====================================
    -- TITLE BAR
    -- =====================================
    local titleBar = CreateFrame("Frame", nil, configFrame)
    titleBar:SetSize(configFrame:GetWidth(), 40)
    titleBar:SetPoint("TOP", 0, 0)

    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.06, 0.06, 0.08, 1)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY")
    titleText:SetFont(FONT_BOLD, 16, "")
    titleText:SetPoint("LEFT", 20, 0)
    titleText:SetText("|cff0cd29fTomo|r|cffffffffMod|r")

    local versionText = titleBar:CreateFontString(nil, "OVERLAY")
    versionText:SetFont(FONT, 10, "")
    versionText:SetPoint("LEFT", titleText, "RIGHT", 8, -1)
    versionText:SetTextColor(unpack(T.textDim))
    versionText:SetText("v2.1.2")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(32, 32)
    closeBtn:SetPoint("RIGHT", -6, 0)

    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY")
    closeTxt:SetFont(FONT_BOLD, 18, "")
    closeTxt:SetPoint("CENTER")
    closeTxt:SetText("×")
    closeTxt:SetTextColor(unpack(T.textDim))

    closeBtn:SetScript("OnEnter", function() closeTxt:SetTextColor(unpack(T.red)) end)
    closeBtn:SetScript("OnLeave", function() closeTxt:SetTextColor(unpack(T.textDim)) end)
    closeBtn:SetScript("OnClick", function() configFrame:Hide() end)

    -- Title bar separator
    local titleSep = configFrame:CreateTexture(nil, "ARTWORK")
    titleSep:SetHeight(1)
    titleSep:SetPoint("TOPLEFT", 0, -40)
    titleSep:SetPoint("TOPRIGHT", 0, -40)
    titleSep:SetColorTexture(unpack(T.border))

    -- =====================================
    -- SIDEBAR
    -- =====================================
    local sidebarWidth = 160

    local sidebar = CreateFrame("Frame", nil, configFrame)
    sidebar:SetPoint("TOPLEFT", 0, -41)
    sidebar:SetPoint("BOTTOMLEFT", 0, 0)
    sidebar:SetWidth(sidebarWidth)

    local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND")
    sidebarBg:SetAllPoints()
    sidebarBg:SetColorTexture(0.06, 0.06, 0.08, 1)

    -- Sidebar separator
    local sidebarSep = configFrame:CreateTexture(nil, "ARTWORK")
    sidebarSep:SetWidth(1)
    sidebarSep:SetPoint("TOPLEFT", sidebarWidth, -40)
    sidebarSep:SetPoint("BOTTOMLEFT", sidebarWidth, 0)
    sidebarSep:SetColorTexture(unpack(T.border))

    -- Category buttons
    for i, cat in ipairs(categories) do
        local btn = CreateFrame("Button", nil, sidebar)
        btn:SetSize(sidebarWidth, 36)
        btn:SetPoint("TOPLEFT", 0, -(i - 1) * 36 - 8)

        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints()
        btnBg:SetColorTexture(0, 0, 0, 0)
        btn.bg = btnBg

        local indicator = btn:CreateTexture(nil, "OVERLAY")
        indicator:SetSize(3, 24)
        indicator:SetPoint("LEFT", 0, 0)
        indicator:SetColorTexture(unpack(T.accent))
        indicator:Hide()
        btn.indicator = indicator

        local icon = btn:CreateFontString(nil, "OVERLAY")
        icon:SetFont(FONT, 13, "")
        icon:SetPoint("LEFT", 14, 0)
        icon:SetText(cat.icon)
        icon:SetTextColor(unpack(T.textDim))
        btn.icon = icon

        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont(FONT, 12, "")
        label:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        label:SetText(cat.label)
        label:SetTextColor(unpack(T.textDim))
        btn.label = label

        btn:SetScript("OnEnter", function()
            if currentCategory ~= cat.key then
                btnBg:SetColorTexture(0.12, 0.12, 0.15, 1)
            end
        end)
        btn:SetScript("OnLeave", function()
            if currentCategory ~= cat.key then
                btnBg:SetColorTexture(0, 0, 0, 0)
            end
        end)
        btn:SetScript("OnClick", function()
            C.SwitchCategory(cat.key)
        end)

        categoryButtons[cat.key] = btn
    end

    -- =====================================
    -- CONTENT AREA
    -- =====================================
    local content = CreateFrame("Frame", nil, configFrame)
    content:SetPoint("TOPLEFT", sidebarWidth + 1, -41)
    content:SetPoint("BOTTOMRIGHT", 0, 0)
    configFrame.content = content

    -- =====================================
    -- FOOTER
    -- =====================================
    local footerSep = configFrame:CreateTexture(nil, "ARTWORK")
    footerSep:SetHeight(1)
    footerSep:SetPoint("BOTTOMLEFT", sidebarWidth + 1, 32)
    footerSep:SetPoint("BOTTOMRIGHT", 0, 32)
    footerSep:SetColorTexture(unpack(T.separator))

    local footerText = configFrame:CreateFontString(nil, "OVERLAY")
    footerText:SetFont(FONT, 9, "")
    footerText:SetPoint("BOTTOMRIGHT", -12, 10)
    footerText:SetTextColor(unpack(T.textDim))
    footerText:SetText("/tm pour toggle • /tm uf pour unlock frames")
end

-- =====================================
-- SWITCH CATEGORY
-- =====================================

function C.SwitchCategory(key)
    if currentCategory == key then return end

    -- Hide all panels
    for _, panel in pairs(categoryPanels) do
        panel:Hide()
    end

    -- Update button visuals
    for catKey, btn in pairs(categoryButtons) do
        if catKey == key then
            btn.bg:SetColorTexture(0.10, 0.10, 0.13, 1)
            btn.indicator:Show()
            btn.icon:SetTextColor(unpack(T.accent))
            btn.label:SetTextColor(unpack(T.text))
        else
            btn.bg:SetColorTexture(0, 0, 0, 0)
            btn.indicator:Hide()
            btn.icon:SetTextColor(unpack(T.textDim))
            btn.label:SetTextColor(unpack(T.textDim))
        end
    end

    -- Create or show the panel
    if not categoryPanels[key] then
        for _, cat in ipairs(categories) do
            if cat.key == key then
                local builder = _G[cat.builder]
                if builder then
                    local panel = builder(configFrame.content)
                    panel:SetAllPoints(configFrame.content)
                    categoryPanels[key] = panel
                end
                break
            end
        end
    end

    if categoryPanels[key] then
        categoryPanels[key]:Show()
    end

    currentCategory = key
end

-- =====================================
-- TOGGLE
-- =====================================

function C.Toggle()
    if not TomoModDB then
        print("|cffff0000TomoMod|r Base de données non initialisée")
        return
    end

    if not configFrame then
        CreateConfigFrame()
    end

    if configFrame:IsShown() then
        configFrame:Hide()
    else
        configFrame:Show()
        -- Open default category if none selected
        if not currentCategory then
            C.SwitchCategory("general")
        end
    end
end

function C.Show()
    C.Toggle()
    if configFrame and not configFrame:IsShown() then
        C.Toggle()
    end
end

function C.Hide()
    if configFrame and configFrame:IsShown() then
        configFrame:Hide()
    end
end

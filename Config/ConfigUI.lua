-- =====================================
-- ConfigUI.lua — Custom Dark-Themed Config Panel
-- Sidebar navigation, no Blizzard Options dependency
-- =====================================

local L = TomoMod_L

TomoMod_Config = TomoMod_Config or {}
local C = TomoMod_Config
local W = TomoMod_Widgets
local T = W.Theme

local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Tomo.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Tomo.ttf"

local configFrame
local currentCategory = nil
local categoryPanels = {}
local categoryButtons = {}

-- =====================================
-- CATEGORIES
-- =====================================
local ICON_PATH = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\icons\\"

local categories = {
    { key = "general",    label = L["cat_general"],     icon = ICON_PATH .. "icon_general.tga",     builder = "TomoMod_ConfigPanel_General" },
    { key = "unitframes", label = L["cat_unitframes"],  icon = ICON_PATH .. "icon_unitframes.tga",  builder = "TomoMod_ConfigPanel_UnitFrames" },
    { key = "nameplates", label = L["cat_nameplates"],  icon = ICON_PATH .. "icon_nameplates.tga",  builder = "TomoMod_ConfigPanel_Nameplates" },
    { key = "resources",  label = L["cat_cd_resource"], icon = ICON_PATH .. "icon_resources.tga",   builder = "TomoMod_ConfigPanel_CooldownResource" },
    { key = "actionbars", label = L["cat_action_bars"], icon = ICON_PATH .. "icon_actionbars.tga",  builder = "TomoMod_ConfigPanel_ActionBars" },
    { key = "sound",      label = L["cat_sound"],       icon = ICON_PATH .. "icon_sound.tga",       builder = "TomoMod_ConfigPanel_Sound" },
    { key = "qol",        label = L["cat_qol"],         icon = ICON_PATH .. "icon_qol.tga",         builder = "TomoMod_ConfigPanel_QOL" },
    { key = "profiles",   label = L["cat_profiles"],    icon = ICON_PATH .. "icon_profiles.tga",    builder = "TomoMod_ConfigPanel_Profiles" },
}

-- =====================================
-- CREATE MAIN FRAME
-- =====================================

local function CreateConfigFrame()
    if configFrame then return end

    configFrame = CreateFrame("Frame", "TomoModConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(840, 620)
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

    -- Preview hooks : certains éléments s'affichent pendant l'ouverture du GUI
    configFrame:SetScript("OnShow", function()
        C.isOpen = true
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshThreatPreview then
            TomoMod_UnitFrames.RefreshThreatPreview(true)
        end
    end)
    configFrame:SetScript("OnHide", function()
        C.isOpen = false
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshThreatPreview then
            TomoMod_UnitFrames.RefreshThreatPreview(false)
        end
    end)

    -- Close with Escape
    tinsert(UISpecialFrames, "TomoModConfigFrame")

    -- =====================================
    -- TITLE BAR
    -- =====================================
    local TITLE_H = 44

    local titleBar = CreateFrame("Frame", nil, configFrame)
    titleBar:SetSize(configFrame:GetWidth(), TITLE_H)
    titleBar:SetPoint("TOP", 0, 0)

    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.06, 0.06, 0.08, 1)

    -- Logo area
    local logoTex = titleBar:CreateTexture(nil, "OVERLAY")
    logoTex:SetSize(28, 28)
    logoTex:SetPoint("LEFT", 14, 0)
    logoTex:SetTexture("Interface\\AddOns\\TomoMod\\Assets\\Textures\\Logo.tga")

    local titleText = titleBar:CreateFontString(nil, "OVERLAY")
    titleText:SetFont(FONT_BOLD, 16, "")
    titleText:SetPoint("LEFT", logoTex, "RIGHT", 8, 1)
    titleText:SetText("|cff0cd29fTomo|r|cffffffffMod|r")

    local versionText = titleBar:CreateFontString(nil, "OVERLAY")
    versionText:SetFont(FONT, 10, "")
    versionText:SetPoint("LEFT", titleText, "RIGHT", 8, -1)
    versionText:SetTextColor(unpack(T.textDim))
    versionText:SetText("v2.3.3")

    -- =====================================
    -- RELOAD UI BUTTON (↺)  — positioned after close is created
    -- =====================================
    local rlBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    rlBtn:SetSize(44, 24)
    -- Position set after closeBtn is created below
    rlBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    rlBtn:SetBackdropColor(0.10, 0.08, 0.04, 0.8)
    rlBtn:SetBackdropBorderColor(0.6, 0.42, 0.08, 0.7)

    -- [FIX] ↺ (U+21BA) hors de Tomo.ttf → invisible. Utiliser icône texture + texte "RL".
    local rlBtnIcon = rlBtn:CreateTexture(nil, "OVERLAY")
    rlBtnIcon:SetSize(13, 13)
    rlBtnIcon:SetPoint("LEFT", rlBtn, "LEFT", 6, 0)
    rlBtnIcon:SetTexture("Interface\\AddOns\\TomoMod\\Assets\\Textures\\icon_reload.tga")
    rlBtnIcon:SetVertexColor(0.85, 0.65, 0.20)

    local rlTxt = rlBtn:CreateFontString(nil, "OVERLAY")
    rlTxt:SetFont(FONT, 11, "")
    rlTxt:SetPoint("LEFT", rlBtnIcon, "RIGHT", 4, 0)
    rlTxt:SetText("RL")
    rlTxt:SetTextColor(0.85, 0.65, 0.20)

    rlBtn:SetScript("OnEnter", function()
        rlBtn:SetBackdropBorderColor(1, 0.80, 0.25, 1)
        rlTxt:SetTextColor(1, 0.90, 0.40)
        rlBtnIcon:SetVertexColor(1, 0.90, 0.40)
        GameTooltip:SetOwner(rlBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["btn_reload_ui"] or "Reload UI", 1, 1, 1)
        GameTooltip:Show()
    end)
    rlBtn:SetScript("OnLeave", function()
        rlBtn:SetBackdropBorderColor(0.6, 0.42, 0.08, 0.7)
        rlTxt:SetTextColor(0.85, 0.65, 0.20)
        rlBtnIcon:SetVertexColor(0.85, 0.65, 0.20)
        GameTooltip:Hide()
    end)
    rlBtn:SetScript("OnClick", function() ReloadUI() end)

    -- =====================================
    -- LAYOUT BUTTON (⊹ Layout)
    -- =====================================
    local layoutBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    layoutBtn:SetSize(80, 24)
    layoutBtn:SetPoint("RIGHT", rlBtn, "LEFT", -6, 0)
    layoutBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })

    local function UpdateLayoutBtnStyle()
        local unlocked = TomoMod_Movers and TomoMod_Movers.IsUnlocked and TomoMod_Movers.IsUnlocked()
        if unlocked then
            layoutBtn:SetBackdropColor(0.03, 0.20, 0.14, 0.9)
            layoutBtn:SetBackdropBorderColor(0.05, 0.82, 0.62, 1)
        else
            layoutBtn:SetBackdropColor(0.06, 0.06, 0.09, 0.8)
            layoutBtn:SetBackdropBorderColor(0.20, 0.20, 0.24, 0.8)
        end
    end

    UpdateLayoutBtnStyle()

    -- [FIX] ⊹ (U+2609) hors de Tomo.ttf → icône texture + texte plain
    local layoutBtnIcon = layoutBtn:CreateTexture(nil, "OVERLAY")
    layoutBtnIcon:SetSize(13, 13)
    layoutBtnIcon:SetPoint("LEFT", layoutBtn, "LEFT", 7, 0)
    layoutBtnIcon:SetTexture("Interface\\AddOns\\TomoMod\\Assets\\Textures\\icon_layout.tga")
    layoutBtnIcon:SetVertexColor(0.05, 0.82, 0.62)

    local layoutTxt = layoutBtn:CreateFontString(nil, "OVERLAY")
    layoutTxt:SetFont(FONT, 11, "")
    layoutTxt:SetPoint("LEFT", layoutBtnIcon, "RIGHT", 5, 0)
    layoutTxt:SetText("Layout")
    layoutTxt:SetTextColor(0.05, 0.82, 0.62)

    layoutBtn:SetScript("OnEnter", function()
        layoutBtn:SetBackdropBorderColor(0.05, 0.82, 0.62, 1)
        layoutTxt:SetTextColor(1, 1, 1)
        layoutBtnIcon:SetVertexColor(1, 1, 1)
        GameTooltip:SetOwner(layoutBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["btn_layout_tooltip"] or "Toggle Layout Mode\nDrag all UI elements", 1, 1, 1)
        GameTooltip:Show()
    end)
    layoutBtn:SetScript("OnLeave", function()
        UpdateLayoutBtnStyle()
        layoutTxt:SetTextColor(0.05, 0.82, 0.62)
        layoutBtnIcon:SetVertexColor(0.05, 0.82, 0.62)
        GameTooltip:Hide()
    end)
    layoutBtn:SetScript("OnClick", function()
        if TomoMod_Movers and TomoMod_Movers.Toggle then
            TomoMod_Movers.Toggle()
        end
        UpdateLayoutBtnStyle()
    end)

    -- Close button (far right)
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

    -- RL button: juste à gauche du close
    rlBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)

    -- Layout button: juste à gauche du RL
    -- Title bar separator
    local titleSep = configFrame:CreateTexture(nil, "ARTWORK")
    titleSep:SetHeight(1)
    titleSep:SetPoint("TOPLEFT", 0, -40)
    titleSep:SetPoint("TOPRIGHT", 0, -40)
    titleSep:SetColorTexture(unpack(T.border))

    -- =====================================
    -- SIDEBAR
    -- =====================================
    local sidebarWidth = 170

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

        local icon = btn:CreateTexture(nil, "OVERLAY")
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", 14, 0)
        icon:SetTexture(cat.icon)
        icon:SetVertexColor(unpack(T.textDim))
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
            btn.icon:SetVertexColor(unpack(T.accent))
            btn.label:SetTextColor(unpack(T.text))
        else
            btn.bg:SetColorTexture(0, 0, 0, 0)
            btn.indicator:Hide()
            btn.icon:SetVertexColor(unpack(T.textDim))
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
        print("|cffff0000TomoMod|r " .. L["msg_db_not_init"])
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

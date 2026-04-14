-- =====================================
-- ConfigUI.lua — Dark Config Panel v2.7.1
-- Icônes .tga originales redimensionnées, sidebar sobre
-- Fixed size 1020 × 720
-- =====================================

local L = TomoMod_L

TomoMod_Config = TomoMod_Config or {}
local C = TomoMod_Config
local W = TomoMod_Widgets
local T = W.Theme

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ADDON_PATH = "Interface\\AddOns\\TomoMod\\"

-- =====================================================================
-- LAYOUT CONSTANTS
-- =====================================================================
local PANEL_W   = 1020
local PANEL_H   = 720
local NAV_W     = 190   -- réduit vs 210 : pas besoin d'espace pour l'icon-box
local TITLE_H   = 52
local FOOTER_H  = 36

-- =====================================================================
-- CATEGORIES
-- =====================================================================
local ICON_PATH = ADDON_PATH .. "Assets\\Textures\\icons\\"

local categories = {
    { key = "general",    label = L["cat_general"],     icon = ICON_PATH .. "icon_general.tga"     },
    { key = "unitframes", label = L["cat_unitframes"],  icon = ICON_PATH .. "icon_unitframes.tga"  },
    { key = "nameplates", label = L["cat_nameplates"],  icon = ICON_PATH .. "icon_nameplates.tga"  },
    { key = "castbars",   label = L["cat_castbars"],    icon = ICON_PATH .. "icon_castbars.tga"   },
    { key = "partyframes", label = L["cat_partyframes"] or "Party Frames", icon = ICON_PATH .. "icon_partyframes.tga" },
    { key = "resources",  label = L["cat_cd_resource"], icon = ICON_PATH .. "icon_resources.tga"   },
    { key = "actionbars", label = L["cat_action_bars"], icon = ICON_PATH .. "icon_actionbars.tga"  },
    { key = "sound",      label = L["cat_sound"],       icon = ICON_PATH .. "icon_sound.tga"       },
    { key = "skins",      label = L["cat_skins"],       icon = ICON_PATH .. "icon_skins.tga"       },
    { key = "qol",        label = L["cat_qol"],         icon = ICON_PATH .. "icon_qol.tga"         },
    { key = "mythicplus", label = L["cat_mythicplus"],  icon = ICON_PATH .. "icon_mythicplus.tga"  },
    { key = "profiles",   label = L["cat_profiles"],    icon = ICON_PATH .. "icon_profiles.tga"    },
}

-- State
local configFrame
local currentCategory = nil
local categoryPanels  = {}
local categoryButtons = {}

-- =====================================================================
-- HELPERS
-- =====================================================================
local function GetAccent() return T.accent[1], T.accent[2], T.accent[3] end

-- Performance ticker
local perfTicker
local function StopPerfTicker()
    if perfTicker then perfTicker:Cancel() end
    perfTicker = nil
end

local function StartPerfTicker(label)
    if not label then return end
    local function Sample()
        if not (label and label:IsShown()) then StopPerfTicker(); return end
        local fps = math.floor(GetFramerate() + 0.5)
        local mem = 0
        if UpdateAddOnMemoryUsage then
            UpdateAddOnMemoryUsage()
            local raw = GetAddOnMemoryUsage and GetAddOnMemoryUsage("TomoMod")
            mem = (raw and raw > 0) and raw or 0
        end
        local memStr
        if mem >= 1024 then
            memStr = string.format("%.1f MB", mem / 1024)
        else
            memStr = string.format("%d KB", math.floor(mem + 0.5))
        end
        label:SetText(string.format("FPS: %d  |  Mém: %s", fps, memStr))
    end
    Sample()
    perfTicker = C_Timer.NewTicker(2, Sample)
end

-- =====================================================================
-- NAV BUTTON  — icône .tga simple, redimensionnée pour le nouveau GUI
-- Même logique que l'ancien GUI mais adapté à 210px de sidebar
-- =====================================================================
local NAV_BTN_H = 40   -- légèrement plus grand que les 36px de l'ancien GUI

local function CreateNavButton(parent, cat, yOffset)
    local aR, aG, aB = GetAccent()

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(NAV_W, NAV_BTN_H)
    btn:SetPoint("TOPLEFT", 0, yOffset)

    -- Fond de sélection
    local selBg = btn:CreateTexture(nil, "BACKGROUND", nil, -1)
    selBg:SetAllPoints()
    selBg:SetColorTexture(aR, aG, aB, 0)
    btn.selBg = selBg

    -- Barre accent gauche (3px, identique à l'ancien)
    local selBar = btn:CreateTexture(nil, "OVERLAY")
    selBar:SetWidth(3)
    selBar:SetPoint("TOPLEFT")
    selBar:SetPoint("BOTTOMLEFT")
    selBar:SetColorTexture(aR, aG, aB, 1)
    selBar:Hide()
    btn.selBar = selBar

    -- Icône .tga — 22×22 (vs 18×18 dans l'ancien GUI)
    local ico = btn:CreateTexture(nil, "OVERLAY")
    ico:SetSize(22, 22)
    ico:SetPoint("LEFT", 16, 0)
    ico:SetTexture(cat.icon)
    ico:SetVertexColor(0.46, 0.46, 0.52, 1)
    btn.ico = ico

    -- Label — police légèrement plus grande
    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 12, "")
    lbl:SetPoint("LEFT", ico, "RIGHT", 10, 0)
    lbl:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetTextColor(0.48, 0.48, 0.54, 1)
    lbl:SetText(cat.label)
    btn.lbl = lbl

    -- Micro-séparateur bas
    local micro = btn:CreateTexture(nil, "ARTWORK")
    micro:SetHeight(1)
    micro:SetPoint("BOTTOMLEFT", 8, 0)
    micro:SetPoint("BOTTOMRIGHT", -8, 0)
    micro:SetColorTexture(1, 1, 1, 0.03)

    -- États actif / inactif
    local function SetActive(active)
        if active then
            selBg:SetColorTexture(aR, aG, aB, 0.10)
            selBar:Show()
            ico:SetVertexColor(aR, aG, aB, 1)
            lbl:SetTextColor(0.92, 0.95, 0.93, 1)
        else
            selBg:SetColorTexture(aR, aG, aB, 0)
            selBar:Hide()
            ico:SetVertexColor(0.46, 0.46, 0.52, 1)
            lbl:SetTextColor(0.48, 0.48, 0.54, 1)
        end
    end
    btn.SetActive = SetActive

    btn:SetScript("OnEnter", function()
        if currentCategory ~= cat.key then
            selBg:SetColorTexture(aR, aG, aB, 0.05)
            ico:SetVertexColor(aR * 0.7 + 0.2, aG * 0.7 + 0.2, aB * 0.7 + 0.2, 1)
            lbl:SetTextColor(0.70, 0.72, 0.71, 1)
        end
    end)
    btn:SetScript("OnLeave", function()
        SetActive(currentCategory == cat.key)
    end)
    btn:SetScript("OnClick", function()
        C.SwitchCategory(cat.key)
    end)

    return btn
end

-- =====================================================================
-- CREATE MAIN FRAME
-- =====================================================================
local function CreateConfigFrame()
    if configFrame then return end

    configFrame = CreateFrame("Frame", "TomoModConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(PANEL_W, PANEL_H)
    configFrame:SetPoint("CENTER")
    configFrame:SetFrameStrata("HIGH")
    configFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    configFrame:SetBackdropColor(0.07, 0.07, 0.09, 0.98)
    configFrame:SetBackdropBorderColor(0.14, 0.14, 0.17, 1)
    configFrame:SetMovable(true)
    configFrame:SetClampedToScreen(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop",  configFrame.StopMovingOrSizing)
    configFrame:Hide()
    tinsert(UISpecialFrames, "TomoModConfigFrame")

    configFrame:SetScript("OnShow", function(self)
        C.isOpen = true
        StartPerfTicker(self._perfLabel)
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshThreatPreview then
            TomoMod_UnitFrames.RefreshThreatPreview(true)
        end
    end)
    configFrame:SetScript("OnHide", function(self)
        C.isOpen = false
        StopPerfTicker()
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshThreatPreview then
            TomoMod_UnitFrames.RefreshThreatPreview(false)
        end
    end)

    -- ==============================================================
    -- TITLE BAR
    -- ==============================================================
    local titleBar = CreateFrame("Frame", nil, configFrame)
    titleBar:SetPoint("TOPLEFT")
    titleBar:SetPoint("TOPRIGHT")
    titleBar:SetHeight(TITLE_H)

    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.05, 0.05, 0.065, 1)

    -- Thin accent line at bottom of title
    local titleLine = configFrame:CreateTexture(nil, "ARTWORK")
    titleLine:SetHeight(1)
    titleLine:SetPoint("TOPLEFT",  0, -TITLE_H)
    titleLine:SetPoint("TOPRIGHT", 0, -TITLE_H)
    titleLine:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], 0.20)

    -- Gradient wash in header area of content side
    local headerGlow = configFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
    headerGlow:SetPoint("TOPLEFT",  NAV_W + 1, -TITLE_H)
    headerGlow:SetPoint("TOPRIGHT", 0, -TITLE_H)
    headerGlow:SetHeight(60)
    if headerGlow.SetGradientAlpha then
        headerGlow:SetGradientAlpha("VERTICAL",
            T.accent[1] * 0.12, T.accent[2] * 0.12, T.accent[3] * 0.12, 0.40,
            0, 0, 0, 0)
    else
        headerGlow:SetColorTexture(T.accent[1] * 0.12, T.accent[2] * 0.12, T.accent[3] * 0.12, 0.25)
    end

    -- Logo
    local logo = titleBar:CreateTexture(nil, "OVERLAY")
    logo:SetSize(28, 28)
    logo:SetPoint("LEFT", 16, 0)
    logo:SetTexture(ADDON_PATH .. "Assets\\Textures\\Logo.tga")
    logo:SetVertexColor(T.accent[1], T.accent[2], T.accent[3], 1)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY")
    titleText:SetFont(FONT_BOLD, 16, "")
    titleText:SetPoint("LEFT", logo, "RIGHT", 8, 1)
    titleText:SetText("|cff0cd29fTomo|r|cffe4e4e4Mod|r")

    local versionText = titleBar:CreateFontString(nil, "OVERLAY")
    versionText:SetFont(FONT, 10, "")
    versionText:SetPoint("LEFT", titleText, "RIGHT", 8, -2)
    versionText:SetTextColor(0.30, 0.30, 0.35, 1)
    versionText:SetText("v2.9.0")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(32, 32)
    closeBtn:SetPoint("RIGHT", -10, 0)
    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY")
    closeTxt:SetFont(FONT_BOLD, 22, "")
    closeTxt:SetPoint("CENTER", 0, 1)
    closeTxt:SetText("×")
    closeTxt:SetTextColor(0.36, 0.36, 0.40, 1)
    closeBtn:SetScript("OnEnter", function() closeTxt:SetTextColor(0.90, 0.28, 0.28, 1) end)
    closeBtn:SetScript("OnLeave", function() closeTxt:SetTextColor(0.36, 0.36, 0.40, 1) end)
    closeBtn:SetScript("OnClick", function() configFrame:Hide() end)

    -- Reload button
    local rlBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    rlBtn:SetSize(50, 26)
    rlBtn:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)
    rlBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    rlBtn:SetBackdropColor(0.10, 0.08, 0.04, 0.8)
    rlBtn:SetBackdropBorderColor(0.45, 0.32, 0.06, 0.6)
    local rlTxt = rlBtn:CreateFontString(nil, "OVERLAY")
    rlTxt:SetFont(FONT, 11, "")
    rlTxt:SetPoint("CENTER")
    rlTxt:SetText("RL")
    rlTxt:SetTextColor(0.78, 0.58, 0.16, 1)
    rlBtn:SetScript("OnEnter", function()
        rlBtn:SetBackdropBorderColor(1, 0.78, 0.24, 1)
        rlTxt:SetTextColor(1, 0.86, 0.32, 1)
        GameTooltip:SetOwner(rlBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["btn_reload_ui"] or "Reload UI", 1, 1, 1)
        GameTooltip:Show()
    end)
    rlBtn:SetScript("OnLeave", function()
        rlBtn:SetBackdropBorderColor(0.45, 0.32, 0.06, 0.6)
        rlTxt:SetTextColor(0.78, 0.58, 0.16, 1)
        GameTooltip:Hide()
    end)
    rlBtn:SetScript("OnClick", function() ReloadUI() end)

    -- Layout button
    local layoutBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    layoutBtn:SetSize(84, 26)
    layoutBtn:SetPoint("RIGHT", rlBtn, "LEFT", -6, 0)
    layoutBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })

    local function UpdateLayoutStyle()
        local unlocked = TomoMod_Movers and TomoMod_Movers.IsUnlocked and TomoMod_Movers.IsUnlocked()
        if unlocked then
            layoutBtn:SetBackdropColor(0.03, 0.20, 0.14, 0.9)
            layoutBtn:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 0.90)
        else
            layoutBtn:SetBackdropColor(0.07, 0.07, 0.09, 0.8)
            layoutBtn:SetBackdropBorderColor(0.20, 0.20, 0.25, 0.8)
        end
    end
    UpdateLayoutStyle()

    local layoutTxt = layoutBtn:CreateFontString(nil, "OVERLAY")
    layoutTxt:SetFont(FONT, 11, "")
    layoutTxt:SetPoint("CENTER")
    layoutTxt:SetText("Layout")
    layoutTxt:SetTextColor(T.accent[1], T.accent[2], T.accent[3], 1)
    layoutBtn:SetScript("OnEnter", function()
        layoutBtn:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 1)
        layoutTxt:SetTextColor(1, 1, 1, 1)
        GameTooltip:SetOwner(layoutBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["btn_layout_tooltip"] or "Toggle Layout Mode", 1, 1, 1)
        GameTooltip:Show()
    end)
    layoutBtn:SetScript("OnLeave", function()
        UpdateLayoutStyle()
        layoutTxt:SetTextColor(T.accent[1], T.accent[2], T.accent[3], 1)
        GameTooltip:Hide()
    end)
    layoutBtn:SetScript("OnClick", function()
        if TomoMod_Movers and TomoMod_Movers.Toggle then TomoMod_Movers.Toggle() end
        UpdateLayoutStyle()
    end)

    -- ==============================================================
    -- SIDEBAR
    -- ==============================================================
    local sidebar = CreateFrame("Frame", nil, configFrame)
    sidebar:SetPoint("TOPLEFT",    0, -TITLE_H)
    sidebar:SetPoint("BOTTOMLEFT", 0, FOOTER_H)
    sidebar:SetWidth(NAV_W)

    local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND")
    sidebarBg:SetAllPoints()
    sidebarBg:SetColorTexture(0.052, 0.052, 0.066, 1)

    local navSep = configFrame:CreateTexture(nil, "ARTWORK")
    navSep:SetWidth(1)
    navSep:SetPoint("TOPLEFT",    NAV_W, -TITLE_H)
    navSep:SetPoint("BOTTOMLEFT", NAV_W, FOOTER_H)
    navSep:SetColorTexture(0.14, 0.14, 0.17, 1)

    -- Nav buttons
    local yOff = -8
    for _, cat in ipairs(categories) do
        local btn = CreateNavButton(sidebar, cat, yOff)
        categoryButtons[cat.key] = btn
        yOff = yOff - NAV_BTN_H
    end

    -- Branding at bottom of sidebar
    local brandTxt = sidebar:CreateFontString(nil, "OVERLAY")
    brandTxt:SetFont(FONT, 9, "")
    brandTxt:SetPoint("BOTTOM", 0, 11)
    brandTxt:SetTextColor(0.20, 0.20, 0.24, 1)
    brandTxt:SetText("TomoMod · TomoAniki")

    -- ==============================================================
    -- CONTENT AREA
    -- ==============================================================
    local content = CreateFrame("Frame", nil, configFrame)
    content:SetPoint("TOPLEFT",     NAV_W + 1, -TITLE_H)
    content:SetPoint("BOTTOMRIGHT", 0,          FOOTER_H)
    configFrame.content = content

    -- ==============================================================
    -- FOOTER
    -- ==============================================================
    local footer = CreateFrame("Frame", nil, configFrame)
    footer:SetPoint("BOTTOMLEFT")
    footer:SetPoint("BOTTOMRIGHT")
    footer:SetHeight(FOOTER_H)

    local footerBg = footer:CreateTexture(nil, "BACKGROUND")
    footerBg:SetAllPoints()
    footerBg:SetColorTexture(0.04, 0.04, 0.055, 1)

    local footerLine = footer:CreateTexture(nil, "ARTWORK")
    footerLine:SetHeight(1)
    footerLine:SetPoint("TOPLEFT")
    footerLine:SetPoint("TOPRIGHT")
    footerLine:SetColorTexture(0.14, 0.14, 0.17, 1)

    local hintTxt = footer:CreateFontString(nil, "OVERLAY")
    hintTxt:SetFont(FONT, 9, "")
    hintTxt:SetPoint("LEFT", NAV_W + 14, 0)
    hintTxt:SetTextColor(0.24, 0.24, 0.28, 1)
    hintTxt:SetText(L["ui_footer_hint"] or "/tm  ·  /tm sr pour déplacer les éléments")

    local perfLabel = footer:CreateFontString(nil, "OVERLAY")
    perfLabel:SetFont(FONT, 9, "")
    perfLabel:SetPoint("RIGHT", -14, 0)
    perfLabel:SetTextColor(0.24, 0.24, 0.28, 1)
    configFrame._perfLabel = perfLabel
end

-- =====================================================================
-- SWITCH CATEGORY
-- =====================================================================
function C.SwitchCategory(key)
    if currentCategory == key then return end
    for _, panel in pairs(categoryPanels) do panel:Hide() end

    for catKey, btn in pairs(categoryButtons) do
        btn.SetActive(catKey == key)
    end

    if not categoryPanels[key] then
        local builderMap = {
            general    = "TomoMod_ConfigPanel_General",
            unitframes = "TomoMod_ConfigPanel_UnitFrames",
            nameplates = "TomoMod_ConfigPanel_Nameplates",
            castbars   = "TomoMod_ConfigPanel_Castbars",
            partyframes = "TomoMod_ConfigPanel_PartyFrames",
            resources  = "TomoMod_ConfigPanel_CooldownResource",
            actionbars = "TomoMod_ConfigPanel_ActionBars",
            sound      = "TomoMod_ConfigPanel_Sound",
            qol        = "TomoMod_ConfigPanel_QOL",
            skins      = "TomoMod_ConfigPanel_Skins",
            mythicplus = "TomoMod_ConfigPanel_MythicPlus",
            profiles   = "TomoMod_ConfigPanel_Profiles",
        }
        local builder = builderMap[key] and _G[builderMap[key]]
        if builder then
            local panel = builder(configFrame.content)
            if panel then
                panel:SetAllPoints(configFrame.content)
                categoryPanels[key] = panel
            end
        end
    end

    if categoryPanels[key] then categoryPanels[key]:Show() end
    currentCategory = key
end

-- =====================================================================
-- PUBLIC API
-- =====================================================================
function C.Toggle()
    if not TomoModDB then
        print("|cffff0000TomoMod|r " .. (L["msg_db_not_init"] or "DB not initialized"))
        return
    end
    if not configFrame then CreateConfigFrame() end
    if configFrame:IsShown() then
        configFrame:Hide()
    else
        configFrame:Show()
        if not currentCategory then C.SwitchCategory("general") end
    end
end

function C.Show()
    if not configFrame then C.Toggle()
    elseif not configFrame:IsShown() then
        configFrame:Show()
        if not currentCategory then C.SwitchCategory("general") end
    end
end

function C.Hide()
    if configFrame and configFrame:IsShown() then configFrame:Hide() end
end

function C.OpenCategory(key)
    C.Show()
    if key then C.SwitchCategory(key) end
end

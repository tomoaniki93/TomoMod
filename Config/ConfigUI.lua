-- =====================================
-- ConfigUI.lua — Dark Config Panel v2.7.1
-- Icônes .tga originales redimensionnées, sidebar sobre
-- Fixed size 1020 × 720
-- =====================================

local L = TomoMod_L

StaticPopupDialogs["TOMOMOD_MODULE_RELOAD"] = StaticPopupDialogs["TOMOMOD_MODULE_RELOAD"] or {
    text     = "Recharger l'interface pour appliquer ce changement ?",
    button1  = "Recharger",
    button2  = "Plus tard",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Locales additionnelles utilisées par ce panneau (FR + EN, autonome)
if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["cat_accueil"]           = "Home",
        ["ui_search_placeholder"] = "Search modules...",
    })
    TomoMod_RegisterLocale("frFR", {
        ["cat_accueil"]           = "Accueil",
        ["ui_search_placeholder"] = "Rechercher un module...",
    })
end

TomoMod_Config = TomoMod_Config or {}
local C = TomoMod_Config
local W = TomoMod_Widgets
local T = W.Theme

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ADDON_PATH = "Interface\\AddOns\\TomoMod\\"

local function LT(key, fallback)
    local value = L and L[key]
    if value and value ~= key then return value end
    return fallback or key
end

-- =====================================================================
-- LAYOUT CONSTANTS
-- =====================================================================
local PANEL_W   = 1020
local PANEL_H   = 720
local NAV_W     = 190   -- réduit vs 210 : pas besoin d'espace pour l'icon-box
local TITLE_H   = 52
local FOOTER_H  = 36
local PAGE_HEAD_H = 92

-- =====================================================================
-- CATEGORIES
-- =====================================================================
local ICON_PATH = ADDON_PATH .. "Assets\\Textures\\icons\\"

local categories = {
    { key = "accueil",   label = LT("cat_accueil", "Accueil"), icon = ICON_PATH .. "ico_gui.tga",          accent = { 0.180, 0.847, 0.518 }, desc = "Vue d'ensemble, presets et actions rapides.", kw = "accueil home dashboard tableau bord vue" },
    { key = "interface", label = "Interface",                   icon = ICON_PATH .. "icon_general.tga",    accent = { 0.49, 0.91, 1.00 }, desc = "Apparence globale, barres, sons et fenetres Blizzard.", kw = "general minimap actionbar skins son audio chat sacs tooltip" },
    { key = "units",     label = "Unités",                      icon = ICON_PATH .. "icon_unitframes.tga", accent = { 0.46, 0.72, 1.00 }, desc = "Joueur, plaques, groupe et raid au meme endroit.", kw = "unit frames nameplates party raid groupe cible plaques" },
    { key = "combat",    label = "Combat",                      icon = ICON_PATH .. "icon_castbars.tga",   accent = { 0.96, 0.70, 0.26 }, desc = "Incantations, ressources, cooldowns et Mythic+.", kw = "castbar ressources cooldown mythic mplus combat" },
    { key = "comfort",   label = "Confort",                     icon = ICON_PATH .. "icon_qol.tga",        accent = { 0.38, 0.86, 0.56 }, desc = "Automatisations, quetes, AFK, logement et confort.", kw = "qol confort quete afk housing logement automatisation" },
    { key = "tools",     label = "Outils",                      icon = ICON_PATH .. "icon_profiles.tga",   accent = { 0.67, 0.52, 1.00 }, desc = "Profils, sauvegardes, diagnostics et maintenance.", kw = "profil diagnostics debug erreurs import export outils" },
}

local categoryAliases = {
    general     = { key = "interface", tab = "general" },
    actionbars  = { key = "interface", tab = "actionbars" },
    skins       = { key = "interface", tab = "skins" },
    sound       = { key = "interface", tab = "sound" },

    unitframes  = { key = "units", tab = "unitframes" },
    nameplates  = { key = "units", tab = "nameplates" },
    partyframes = { key = "units", tab = "partyframes" },
    raidframes  = { key = "units", tab = "raidframes" },

    castbars    = { key = "combat", tab = "castbars" },
    resources   = { key = "combat", tab = "resources" },
    mythicplus  = { key = "combat", tab = "mythicplus" },

    qol         = { key = "comfort", tab = "qol" },
    housing     = { key = "comfort", tab = "housing" },

    profiles    = { key = "tools", tab = "profiles" },
    diagnostics = { key = "tools", tab = "diagnostics" },
}

-- State
local configFrame
local currentCategory = nil
local categoryPanels  = {}
local categoryButtons = {}
local activeCategoryPanel = nil
local hiddenPanelBin = nil

-- =====================================================================
-- HELPERS
-- =====================================================================
local function GetAccent() return T.accent[1], T.accent[2], T.accent[3] end

local function CategoryAccent(cat)
    local c = cat and cat.accent or T.accent
    return c[1] or T.accent[1], c[2] or T.accent[2], c[3] or T.accent[3]
end

local function GetCategory(key)
    for _, cat in ipairs(categories) do
        if cat.key == key then return cat end
    end
    return nil
end

local function GetHiddenPanelBin()
    if hiddenPanelBin then return hiddenPanelBin end
    hiddenPanelBin = CreateFrame("Frame", nil, UIParent)
    hiddenPanelBin:SetSize(1, 1)
    hiddenPanelBin:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -10000, -10000)
    hiddenPanelBin:Hide()
    return hiddenPanelBin
end

local function ParkPanel(panel)
    if not panel then return end
    if panel.Hide then pcall(panel.Hide, panel) end
    if panel.SetScript then pcall(panel.SetScript, panel, "OnUpdate", nil) end
    if panel.GetChildren then
        local children = { panel:GetChildren() }
        for _, child in ipairs(children) do
            ParkPanel(child)
        end
    end
    if panel.IsProtected and panel:IsProtected() then return end
    if panel.ClearAllPoints then pcall(panel.ClearAllPoints, panel) end
    if panel.SetParent then pcall(panel.SetParent, panel, GetHiddenPanelBin()) end
end

local function ClearContentArea()
    if not configFrame or not configFrame.content or not configFrame.content.GetChildren then return end

    local children = { configFrame.content:GetChildren() }
    for _, child in ipairs(children) do
        ParkPanel(child)
    end

    activeCategoryPanel = nil
    categoryPanels = {}
end

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
    local aR, aG, aB = CategoryAccent(cat)

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

local function CreatePageShell(parent, cat)
    if not cat or cat.key == "accueil" then
        return parent, nil
    end

    local r, g, b = CategoryAccent(cat)
    local shell = CreateFrame("Frame", nil, parent)
    shell:SetAllPoints()
    shell._muiDesign = cat

    local header = CreateFrame("Frame", nil, shell, "BackdropTemplate")
    header:SetPoint("TOPLEFT", 8, -10)
    header:SetPoint("TOPRIGHT", -18, -10)
    header:SetHeight(PAGE_HEAD_H - 18)
    header:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    header:SetBackdropColor(0.040, 0.038, 0.058, 0.98)
    header:SetBackdropBorderColor(r, g, b, 0.34)

    local wash = header:CreateTexture(nil, "BACKGROUND", nil, -1)
    wash:SetPoint("TOPLEFT", 1, -1)
    wash:SetPoint("BOTTOMRIGHT", -1, 1)
    if wash.SetGradientAlpha then
        wash:SetGradientAlpha("HORIZONTAL", r, g, b, 0.16, 0, 0, 0, 0)
    else
        wash:SetColorTexture(r, g, b, 0.08)
    end

    local bar = header:CreateTexture(nil, "ARTWORK")
    bar:SetWidth(4)
    bar:SetPoint("TOPLEFT", 0, 0)
    bar:SetPoint("BOTTOMLEFT", 0, 0)
    bar:SetColorTexture(r, g, b, 1)

    local icon = header:CreateTexture(nil, "OVERLAY")
    icon:SetSize(34, 34)
    icon:SetPoint("LEFT", 18, 0)
    icon:SetTexture(cat.icon)
    icon:SetVertexColor(r, g, b, 1)

    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_BOLD, 20, "")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 14, -5)
    title:SetText(cat.label or "")
    title:SetTextColor(1, 1, 1, 1)

    local desc = header:CreateFontString(nil, "OVERLAY")
    desc:SetFont(FONT, 11, "")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    desc:SetPoint("RIGHT", -24, 0)
    desc:SetJustifyH("LEFT")
    desc:SetText(cat.desc or "")
    desc:SetTextColor(0.54, 0.54, 0.62, 1)

    local body = CreateFrame("Frame", nil, shell)
    body:SetPoint("TOPLEFT", 0, -PAGE_HEAD_H)
    body:SetPoint("BOTTOMRIGHT", 0, 0)
    body._muiDesign = cat

    return body, shell
end

local function BuildPanelByName(parent, globalName)
    local builder = globalName and _G[globalName]
    if builder then return builder(parent) end
    return nil
end

local function BuildGroupedPanel(parent, tabs, defaultKey)
    local selected = C._pendingGroupTab or defaultKey or (tabs[1] and tabs[1].key)
    C._pendingGroupTab = nil

    local exists = false
    for _, tab in ipairs(tabs) do
        if tab.key == selected then exists = true; break end
    end
    if not exists then selected = tabs[1] and tabs[1].key end

    local panel = W.CreateTabPanel(parent, tabs)
    if panel and selected and panel.SwitchTab then
        panel.SwitchTab(selected)
    end
    return panel
end

local function BuildInterfacePanel(parent)
    return BuildGroupedPanel(parent, {
        { key = "general",    label = "Général",          builder = function(p) return BuildPanelByName(p, "TomoMod_ConfigPanel_General") end },
        { key = "actionbars", label = "Barres d'action",  builder = function(p) return BuildPanelByName(p, "TomoMod_ConfigPanel_ActionBars") end },
        { key = "skins",      label = "Skins",            builder = function(p) return BuildPanelByName(p, "TomoMod_ConfigPanel_Skins") end },
        { key = "sound",      label = "Son",              builder = function(p) return BuildPanelByName(p, "TomoMod_ConfigPanel_Sound") end },
    }, "general")
end

local function BuildUnitsPanel(parent)
    return BuildGroupedPanel(parent, {
        { key = "unitframes",  label = "UnitFrames", builder = function(p) return BuildPanelByName(p, "TomoMod_ConfigPanel_UnitFrames") end },
        { key = "nameplates",  label = "Nameplates", builder = function(p) return BuildPanelByName(p, "TomoMod_ConfigPanel_Nameplates") end },
        { key = "partyframes", label = "Groupe",     builder = function(p) return BuildPanelByName(p, "TomoMod_ConfigPanel_PartyFrames") end },
        { key = "raidframes",  label = "Raid",       builder = function(p) return BuildPanelByName(p, "TomoMod_ConfigPanel_RaidFrames") end },
    }, "unitframes")
end

local function BuildCombatPanel(parent)
    return BuildGroupedPanel(parent, {
        { key = "castbars",   label = "Incantations",  builder = function(p) return BuildPanelByName(p, "TomoMod_ConfigPanel_Castbars") end },
        { key = "resources",  label = "CD & Ressource", builder = function(p) return BuildPanelByName(p, "TomoMod_ConfigPanel_CooldownResource") end },
        { key = "mythicplus", label = "Mythic+",       builder = function(p) return BuildPanelByName(p, "TomoMod_ConfigPanel_MythicPlus") end },
    }, "castbars")
end

local function BuildComfortPanel(parent)
    return BuildGroupedPanel(parent, {
        { key = "qol",     label = "Qualité de vie", builder = function(p) return BuildPanelByName(p, "TomoMod_ConfigPanel_QOL") end },
        { key = "housing", label = "Housing",        builder = function(p) return BuildPanelByName(p, "TomoMod_ConfigPanel_Housing") end },
    }, "qol")
end

local function BuildToolsPanel(parent)
    return BuildGroupedPanel(parent, {
        { key = "profiles",    label = "Profils",     builder = function(p) return BuildPanelByName(p, "TomoMod_ConfigPanel_Profiles") end },
        { key = "diagnostics", label = "Diagnostics", builder = function(p) return BuildPanelByName(p, "TomoMod_ConfigPanel_Diagnostics") end },
    }, "profiles")
end

-- =====================================================================
-- CREATE MAIN FRAME
-- =====================================================================
local function CreateConfigFrame()
    if configFrame then return end

    configFrame = CreateFrame("Frame", "TomoModConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(PANEL_W, PANEL_H)
    configFrame:SetPoint("CENTER")
    configFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    configFrame:SetFrameLevel(500)
    configFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    configFrame:SetBackdropColor(0.035, 0.035, 0.052, 1)
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
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        self:SetFrameLevel(500)
        StartPerfTicker(self._perfLabel)
        if currentCategory == "units" and TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshThreatPreview then
            TomoMod_UnitFrames.RefreshThreatPreview(true)
        end
    end)
    configFrame:SetScript("OnHide", function(self)
        C.isOpen = false
        StopPerfTicker()
        if GameTooltip then GameTooltip:Hide() end
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshThreatPreview then
            TomoMod_UnitFrames.RefreshThreatPreview(false)
        end
        if TomoMod_Castbar and TomoMod_Castbar.SetPreview then
            TomoMod_Castbar.SetPreview(false)
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
    configFrame._titleLine = titleLine

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
    configFrame._headerGlow = headerGlow

    -- Logo
    local logo = titleBar:CreateTexture(nil, "OVERLAY")
    logo:SetSize(32, 32)
    logo:SetPoint("LEFT", 14, 0)
    logo:SetTexture(ADDON_PATH .. "Assets\\Textures\\Logo.tga")
    logo:SetVertexColor(1, 1, 1, 1)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY")
    titleText:SetFont(FONT_BOLD, 16, "")
    titleText:SetPoint("LEFT", logo, "RIGHT", 8, 1)
    titleText:SetText("|cff2ed884Tomo|r|cffe4e4e4Mod|r")

    local versionText = titleBar:CreateFontString(nil, "OVERLAY")
    versionText:SetFont(FONT, 10, "")
    versionText:SetPoint("LEFT", titleText, "RIGHT", 8, -2)
    versionText:SetTextColor(0.30, 0.30, 0.35, 1)
    versionText:SetText("v" .. (C_AddOns.GetAddOnMetadata("TomoMod", "Version") or "?"))

    local contextTitle = titleBar:CreateFontString(nil, "OVERLAY")
    contextTitle:SetFont(FONT_BOLD, 12, "")
    contextTitle:SetPoint("LEFT", titleText, "RIGHT", 96, 8)
    contextTitle:SetPoint("RIGHT", -190, 0)
    contextTitle:SetJustifyH("LEFT")
    contextTitle:SetTextColor(T.accent[1], T.accent[2], T.accent[3], 1)
    configFrame._contextTitle = contextTitle

    local contextDesc = titleBar:CreateFontString(nil, "OVERLAY")
    contextDesc:SetFont(FONT, 10, "")
    contextDesc:SetPoint("TOPLEFT", contextTitle, "BOTTOMLEFT", 0, -3)
    contextDesc:SetPoint("RIGHT", -190, 0)
    contextDesc:SetJustifyH("LEFT")
    contextDesc:SetTextColor(0.46, 0.46, 0.54, 1)
    configFrame._contextDesc = contextDesc

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

    -- Layout button
    local layoutBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    layoutBtn:SetSize(84, 26)
    layoutBtn:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)
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
    layoutTxt:SetText(L["btn_layout"] or "EditMode")
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

    -- ── Barre de recherche ─────────────────────────────────────
    local WHITE8 = "Interface\\Buttons\\WHITE8x8"
    local aR, aG, aB = GetAccent()
    local SEARCH_H = 28

    local searchWrap = CreateFrame("Frame", nil, sidebar, "BackdropTemplate")
    searchWrap:SetPoint("TOPLEFT",  8, -8)
    searchWrap:SetPoint("TOPRIGHT", -8, -8)
    searchWrap:SetHeight(SEARCH_H)
    searchWrap:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    searchWrap:SetBackdropColor(0.09, 0.09, 0.115, 1)
    searchWrap:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

    local mag = searchWrap:CreateTexture(nil, "OVERLAY")
    mag:SetSize(14, 14); mag:SetPoint("LEFT", 7, 0)
    mag:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    mag:SetVertexColor(0.50, 0.50, 0.56, 1)

    local searchBox = CreateFrame("EditBox", nil, searchWrap)
    searchBox:SetPoint("LEFT", mag, "RIGHT", 4, 0)
    searchBox:SetPoint("RIGHT", -22, 0)
    searchBox:SetPoint("TOP", 0, 0)
    searchBox:SetPoint("BOTTOM", 0, 0)
    searchBox:SetFont(FONT, 12, "")
    searchBox:SetTextColor(0.88, 0.90, 0.89, 1)
    searchBox:SetAutoFocus(false)
    searchBox:SetTextInsets(0, 0, 0, 0)

    local placeholder = searchBox:CreateFontString(nil, "OVERLAY")
    placeholder:SetFont(FONT, 12, ""); placeholder:SetPoint("LEFT", 1, 0)
    placeholder:SetTextColor(0.34, 0.34, 0.40, 1)
    placeholder:SetText(L["ui_search_placeholder"] or "Rechercher...")

    local clearBtn = CreateFrame("Button", nil, searchWrap)
    clearBtn:SetSize(18, 18); clearBtn:SetPoint("RIGHT", -3, 0); clearBtn:Hide()
    local clearTxt = clearBtn:CreateFontString(nil, "OVERLAY")
    clearTxt:SetFont(FONT_BOLD, 14, ""); clearTxt:SetPoint("CENTER", 0, 1); clearTxt:SetText("×")
    clearTxt:SetTextColor(0.45, 0.45, 0.50, 1)
    clearBtn:SetScript("OnEnter", function() clearTxt:SetTextColor(0.90, 0.30, 0.30, 1) end)
    clearBtn:SetScript("OnLeave", function() clearTxt:SetTextColor(0.45, 0.45, 0.50, 1) end)

    -- ── Zone de navigation défilante ───────────────────────────
    local NAV_TOP    = 8 + SEARCH_H + 8
    local NAV_BOTTOM = 26
    local navScroll = CreateFrame("ScrollFrame", nil, sidebar)
    navScroll:SetPoint("TOPLEFT", 0, -NAV_TOP)
    navScroll:SetPoint("BOTTOMRIGHT", 0, NAV_BOTTOM)

    local navChild = CreateFrame("Frame", nil, navScroll)
    navChild:SetWidth(NAV_W); navChild:SetHeight(1)
    navScroll:SetScrollChild(navChild)

    local navThumb = navScroll:CreateTexture(nil, "OVERLAY")
    navThumb:SetWidth(3); navThumb:SetColorTexture(aR, aG, aB, 0.5); navThumb:Hide()

    local function UpdateNavThumb()
        local sh = navScroll:GetHeight() or 0
        local ch = navChild:GetHeight() or 0
        local maxS = ch - sh
        if maxS <= 1 then navThumb:Hide(); return end
        navThumb:Show()
        local ratio = sh / ch
        local th    = math.max(20, math.floor(sh * ratio))
        local cur   = navScroll:GetVerticalScroll()
        local ty    = (cur / maxS) * (sh - th)
        navThumb:ClearAllPoints()
        navThumb:SetHeight(th)
        navThumb:SetPoint("TOPRIGHT", navScroll, "TOPRIGHT", -2, -ty)
    end

    navScroll:EnableMouseWheel(true)
    navScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * 40, max)))
        UpdateNavThumb()
    end)
    navScroll:SetScript("OnShow", function() C_Timer.After(0, UpdateNavThumb) end)

    -- Boutons de nav (dans le child défilant)
    for _, cat in ipairs(categories) do
        local btn = CreateNavButton(navChild, cat, 0)
        categoryButtons[cat.key] = btn
        btn._cat = cat
    end

    -- Relayout + filtre de recherche (label + clé + mots-clés)
    local function RelayoutNav(filter)
        filter = (filter or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        local yy, count = -4, 0
        for _, cat in ipairs(categories) do
            local btn = categoryButtons[cat.key]
            local hay = ((cat.label or "") .. " " .. (cat.key or "") .. " " .. (cat.kw or "")):lower()
            local match = (filter == "") or (hay:find(filter, 1, true) ~= nil)
            if match then
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", navChild, "TOPLEFT", 0, yy)
                btn:Show()
                yy = yy - NAV_BTN_H
                count = count + 1
            else
                btn:Hide()
            end
        end
        navChild:SetHeight(math.max(count * NAV_BTN_H + 8, 1))
        navScroll:SetVerticalScroll(0)
        UpdateNavThumb()
    end
    C.RelayoutNav = RelayoutNav

    searchBox:SetScript("OnTextChanged", function(self)
        local txt = self:GetText() or ""
        placeholder:SetShown(txt == "")
        clearBtn:SetShown(txt ~= "")
        RelayoutNav(txt)
    end)
    searchBox:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    searchBox:SetScript("OnEnterPressed",  function(self) self:ClearFocus() end)
    searchBox:SetScript("OnEditFocusGained", function() searchWrap:SetBackdropBorderColor(aR, aG, aB, 0.70) end)
    searchBox:SetScript("OnEditFocusLost",   function() searchWrap:SetBackdropBorderColor(0.18, 0.18, 0.22, 1) end)
    clearBtn:SetScript("OnClick", function() searchBox:SetText(""); searchBox:ClearFocus() end)

    RelayoutNav("")

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

    local contentShield = content:CreateTexture(nil, "BACKGROUND", nil, -8)
    contentShield:SetAllPoints()
    contentShield:SetColorTexture(0.032, 0.032, 0.048, 0.985)

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
    hintTxt:SetText(L["ui_footer_hint"] or "/mui  ·  /mui sr pour déplacer les éléments")

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
    if W and W.CloseDropdowns then W.CloseDropdowns() end

    local alias = categoryAliases[key]
    if alias then
        C._pendingGroupTab = alias.tab
        key = alias.key
    end

    local catMeta = GetCategory(key)
    if W and W.SetPanelContext then W.SetPanelContext(catMeta) end
    local cr, cg, cb = CategoryAccent(catMeta)

    if currentCategory == "units" and key ~= "units"
        and TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshThreatPreview then
        TomoMod_UnitFrames.RefreshThreatPreview(false)
    end

    if configFrame then
        if configFrame._contextTitle then
            configFrame._contextTitle:SetText(catMeta and catMeta.label or "")
            configFrame._contextTitle:SetTextColor(cr, cg, cb, 1)
        end
        if configFrame._contextDesc then
            configFrame._contextDesc:SetText(catMeta and catMeta.desc or "")
        end
        if configFrame._titleLine then
            configFrame._titleLine:SetColorTexture(cr, cg, cb, 0.35)
        end
        if configFrame._headerGlow then
            if configFrame._headerGlow.SetGradientAlpha then
                configFrame._headerGlow:SetGradientAlpha("VERTICAL", cr * 0.12, cg * 0.12, cb * 0.12, 0.40, 0, 0, 0, 0)
            else
                configFrame._headerGlow:SetColorTexture(cr * 0.12, cg * 0.12, cb * 0.12, 0.25)
            end
        end
    end

    ClearContentArea()

    for catKey, btn in pairs(categoryButtons) do
        btn.SetActive(catKey == key)
    end

    local builderMap = {
        accueil   = "TomoMod_ConfigPanel_Accueil",
        interface = BuildInterfacePanel,
        units     = BuildUnitsPanel,
        combat    = BuildCombatPanel,
        comfort   = BuildComfortPanel,
        tools     = BuildToolsPanel,
    }
    local builder = builderMap[key]
    if type(builder) == "string" then builder = _G[builder] end
    if builder then
        local bodyParent, shell = CreatePageShell(configFrame.content, catMeta)
        local panel = builder(bodyParent)
        if panel then
            if W and W.ApplyPanelContext then W.ApplyPanelContext(panel, catMeta) end
            panel:SetAllPoints(bodyParent)
            activeCategoryPanel = shell or panel
            categoryPanels[key] = activeCategoryPanel
        end
    end

    if activeCategoryPanel then activeCategoryPanel:Show() end
    if key == "units" and TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshThreatPreview then
        TomoMod_UnitFrames.RefreshThreatPreview(true)
    end
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
        if not currentCategory then C.SwitchCategory("accueil") end
    end
end

function C.Show()
    if not configFrame then C.Toggle()
    elseif not configFrame:IsShown() then
        configFrame:Show()
        if not currentCategory then C.SwitchCategory("accueil") end
    end
end

function C.Hide()
    if configFrame and configFrame:IsShown() then configFrame:Hide() end
end

function C.OpenCategory(key)
    C.Show()
    if key then C.SwitchCategory(key) end
end

-- =====================================
-- ConfigUI.lua — Dark Config Panel v2.7.1
-- Icônes .tga originales redimensionnées, sidebar sobre
-- Default size 1240 × 820 — resizable (bottom-right grip) + user scale
-- =====================================

local L = TomoMod_L

StaticPopupDialogs["TOMOMOD_MODULE_RELOAD"] = StaticPopupDialogs["TOMOMOD_MODULE_RELOAD"] or {
    -- Raised above the config window, which sits at FULLSCREEN_DIALOG
    -- level 500 and would otherwise hide this prompt entirely.
    OnShow   = function(self)
        local U = TomoMod_Utils
        if U and U.RaiseAboveTomoUI then U.RaiseAboveTomoUI(self) end
    end,
    OnHide   = function(self)
        local U = TomoMod_Utils
        if U and U.RestoreTomoUILayer then U.RestoreTomoUILayer(self) end
    end,
    text     = L["cfg_reload_text"],
    button1  = L["cfg_reload_confirm"],
    button2  = L["cfg_reload_later"],
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
        ["opt_gui_scale"]         = "Config window scale",
        ["info_gui_scale"]        = "Scale of the /tm window — you can also resize it by dragging its bottom-right corner.",
        ["btn_gui_reset_size"]    = "Reset window size & scale",
        ["gs_no_results"]         = "No matching option",
    })
    TomoMod_RegisterLocale("frFR", {
        ["cat_accueil"]           = "Accueil",
        ["ui_search_placeholder"] = "Rechercher un module...",
        ["opt_gui_scale"]         = "Échelle de la fenêtre de configuration",
        ["info_gui_scale"]        = "Échelle de la fenêtre /tm — elle est aussi redimensionnable en tirant son coin inférieur droit.",
        ["btn_gui_reset_size"]    = "Réinitialiser taille et échelle",
        ["gs_no_results"]         = "Aucune option correspondante",
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
local PANEL_W   = 1240
local PANEL_H   = 820
local NAV_W     = 210
local PANEL_MIN_W, PANEL_MIN_H = 1020, 720
local PANEL_MAX_W, PANEL_MAX_H = 1680, 1080
local TITLE_H   = 52
local FOOTER_H  = 36
local PAGE_HEAD_H = 92

-- =====================================================================
-- CATEGORIES
-- =====================================================================
local ICON_PATH = ADDON_PATH .. "Assets\\Textures\\icons\\"

local categories = {
    { key = "accueil",   label = LT("cat_accueil", "Accueil"), icon = ICON_PATH .. "ico_gui.tga",          accent = { 0.180, 0.847, 0.518 }, desc = L["cat_accueil_desc"], kw = "accueil home dashboard tableau bord vue" },
    { key = "roles",     label = L["cat_roles"],                      icon = ICON_PATH .. "icon_partyframes.tga", accent = { 0.94, 0.74, 0.35 }, desc = L["cat_roles_desc"], kw = "role roles tank tanking heal healer soigneur dps damage degats guide" },
    { key = "interface", label = L["cat_interface"],                   icon = ICON_PATH .. "icon_general.tga",    accent = { 0.49, 0.91, 1.00 }, desc = L["cat_interface_desc"], kw = "general minimap actionbar skins son audio chat sacs tooltip" },
    { key = "units",     label = L["cat_units"],                      icon = ICON_PATH .. "icon_unitframes.tga", accent = { 0.46, 0.72, 1.00 }, desc = L["cat_units_desc"], kw = "unit frames nameplates party raid groupe cible plaques" },
    { key = "combat",    label = L["cat_combat"],                      icon = ICON_PATH .. "icon_castbars.tga",   accent = { 0.96, 0.70, 0.26 }, desc = L["cat_combat_desc"], kw = "castbar ressources cooldown mythic mplus combat" },
    { key = "comfort",   label = L["cat_comfort"],                     icon = ICON_PATH .. "icon_qol.tga",        accent = { 0.38, 0.86, 0.56 }, desc = L["cat_comfort_desc"], kw = "qol confort quete afk housing logement automatisation" },
    { key = "changelog", label = LT("cat_changelog", "Nouveautes"), icon = ICON_PATH .. "icon_qol.tga", accent = { 0.36, 0.78, 0.98 }, desc = LT("cat_changelog_desc", "Toutes les notes de version, de la plus recente a la plus ancienne."), kw = "changelog nouveautes notes version patch historique whatsnew quoi de neuf" },
    { key = "profiles",    label = L["cat_profiles"],                  icon = ICON_PATH .. "icon_profiles.tga",    accent = { 0.67, 0.52, 1.00 }, desc = L["cat_profiles_desc"], kw = "profil profils specialisation spec import export sauvegarde backup reinitialiser reset" },
    { key = "diagnostics", label = L["cat_diagnostics"],               icon = ICON_PATH .. "icon_diagnostics.tga", accent = { 0.94, 0.48, 0.48 }, desc = L["cat_diagnostics_desc"], kw = "diagnostics diagnostic debug erreurs lua performance memoire etat modules" },
}

-- Exposed for Config/GlobalSearch.lua (ghost indexing needs the labels)
C.Categories = categories

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

    -- Legacy: the old grouped "Tools" category was split back into two
    -- standalone entries. Kept so any stale deep-link still resolves.
    tools       = { key = "profiles" },
}

-- State
local configFrame
local currentCategory = nil
local categoryPanels  = {}
local categoryButtons = {}
local activeCategoryPanel = nil
local hiddenPanelBin = nil

-- [Lot C] Categories re-shown from cache on revisit. Accueil (dashboard,
-- preset tiles), Profiles (profile list) and Diagnostics (live readings)
-- always rebuild so their dynamic content stays fresh.
local NO_CACHE = { accueil = true, profiles = true, diagnostics = true, changelog = true }

-- =====================================================================
-- HELPERS
-- =====================================================================
local function GetAccent() return T.accent[1], T.accent[2], T.accent[3] end

local function GuiDB()
    if not TomoModDB then return {} end
    TomoModDB.configGUI = TomoModDB.configGUI or {}
    return TomoModDB.configGUI
end

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
        label:SetText(string.format(L["cfg_footer_perf"], fps, memStr))
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

-- Applies (and always consumes) a pending deep-link tab on a panel that
-- owns a tab bar. Unknown keys are ignored: CreateTabPanel.SwitchTab has
-- no guard of its own and would leave the page blank.
local function SwitchPendingTab(panel)
    local key = C._pendingGroupTab
    C._pendingGroupTab = nil
    if not (key and panel and panel.SwitchTab) then return end
    if panel.HasTab and not panel.HasTab(key) then return end
    panel.SwitchTab(key)
end

local function BuildGroupedPanel(parent, tabs, defaultKey)
    -- A pending deep-link path names the outermost tab at index 1 and takes
    -- precedence over the legacy single-key hint. The path itself is NOT
    -- consumed here: nested tab bars further down still need to read it.
    local path = C._pendingTabPath
    local selected = (path and path[1]) or C._pendingGroupTab or defaultKey or (tabs[1] and tabs[1].key)
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

-- Category → tabs tree, shared by SwitchCategory and by
-- Config/GlobalSearch.lua (ghost indexing needs the full mapping as data).
local CATEGORY_TREE = {
    interface = {
        { key = "general",    label = L["cfg_tab_general"],          global = "TomoMod_ConfigPanel_General" },
        { key = "actionbars", label = L["cfg_tab_actionbars"],  global = "TomoMod_ConfigPanel_ActionBars" },
        { key = "skins",      label = L["cfg_tab_skins"],            global = "TomoMod_ConfigPanel_Skins" },
        { key = "sound",      label = L["cfg_tab_sound"],              global = "TomoMod_ConfigPanel_Sound" },
    },
    roles = {
        { key = "tank",   label = L["cfg_tab_role_tank"],   global = "TomoMod_ConfigPanel_RoleTank" },
        { key = "healer", label = L["cfg_tab_role_healer"], global = "TomoMod_ConfigPanel_RoleHealer" },
        { key = "dps",    label = L["cfg_tab_role_dps"],    global = "TomoMod_ConfigPanel_RoleDps" },
    },
    units = {
        { key = "unitframes",  label = L["cfg_tab_unitframes"], global = "TomoMod_ConfigPanel_UnitFrames" },
        { key = "nameplates",  label = L["cfg_tab_nameplates"], global = "TomoMod_ConfigPanel_Nameplates" },
        { key = "partyframes", label = L["cfg_tab_partyframes"],     global = "TomoMod_ConfigPanel_PartyFrames" },
        { key = "raidframes",  label = L["cfg_tab_raidframes"],       global = "TomoMod_ConfigPanel_RaidFrames" },
    },
    combat = {
        { key = "castbars",   label = L["cfg_tab_castbars"],   global = "TomoMod_ConfigPanel_Castbars" },
        { key = "resources",  label = L["cfg_tab_resources"], global = "TomoMod_ConfigPanel_CooldownResource" },
        { key = "cdforge",    label = L["cfg_tab_cdforge"],   global = "TomoMod_ConfigPanel_CooldownForge" },
        { key = "mythicplus", label = L["cfg_tab_mythicplus"],        global = "TomoMod_ConfigPanel_MythicPlus" },
    },
    comfort = {
        { key = "qol",     label = L["cfg_tab_qol"], global = "TomoMod_ConfigPanel_QOL" },
        { key = "housing", label = L["cfg_tab_housing"],        global = "TomoMod_ConfigPanel_Housing" },
    },
}
C.CategoryTree = CATEGORY_TREE

-- Categories that are a single page (no tab bar of their own at this
-- level). Shared with Config/GlobalSearch.lua so ghost indexing covers
-- them exactly like the grouped ones.
local SINGLE_PAGES = {
    accueil     = "TomoMod_ConfigPanel_Accueil",
    changelog   = "TomoMod_ConfigPanel_Changelog",
    profiles    = "TomoMod_ConfigPanel_Profiles",
    diagnostics = "TomoMod_ConfigPanel_Diagnostics",
}
C.SinglePages = SINGLE_PAGES

local function BuildGroupedFromTree(parent, catKey)
    local tabs = {}
    for i, t in ipairs(CATEGORY_TREE[catKey] or {}) do
        local globalName = t.global
        tabs[i] = {
            key = t.key, label = t.label,
            builder = function(p) return BuildPanelByName(p, globalName) end,
        }
    end
    return BuildGroupedPanel(parent, tabs, tabs[1] and tabs[1].key)
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
    -- [fix] Escape captured by the window itself. Going through
    -- UISpecialFrames routes it via ToggleGameMenu, whose protected
    -- ClearTarget/SpellStopCasting calls are then refused once anything
    -- has tainted the path -- and the player can no longer quit.
    TomoMod_Utils.CloseOnEscape(_G["TomoModConfigFrame"])

    -- Restore saved size / scale, enable resizing (bounds clamp saved values)
    local gdb = GuiDB()
    if gdb.width and gdb.height then
        configFrame:SetSize(
            math.max(PANEL_MIN_W, math.min(gdb.width,  PANEL_MAX_W)),
            math.max(PANEL_MIN_H, math.min(gdb.height, PANEL_MAX_H)))
    end
    configFrame:SetScale(gdb.scale or 1)
    configFrame:SetResizable(true)
    if configFrame.SetResizeBounds then
        configFrame:SetResizeBounds(PANEL_MIN_W, PANEL_MIN_H, PANEL_MAX_W, PANEL_MAX_H)
    elseif configFrame.SetMinResize then
        configFrame:SetMinResize(PANEL_MIN_W, PANEL_MIN_H)
        configFrame:SetMaxResize(PANEL_MAX_W, PANEL_MAX_H)
    end

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

    -- Exposed for Config/GlobalSearch.lua (results popup anchor + input)
    configFrame._searchWrap = searchWrap
    configFrame._searchBox  = searchBox

    -- ── Filtre par rôle ────────────────────────────────────────
    -- Dims settings that belong to other roles instead of hiding them,
    -- so a player never loses track of an option they already know.
    local ROLEBAR_H  = 24
    local ROLEBAR_Y  = 8 + SEARCH_H + 6

    local roleBar = CreateFrame("Frame", nil, sidebar)
    roleBar:SetPoint("TOPLEFT",  8, -ROLEBAR_Y)
    roleBar:SetPoint("TOPRIGHT", -8, -ROLEBAR_Y)
    roleBar:SetHeight(ROLEBAR_H)

    local ROLE_SLOTS = {
        { key = "ALL" },
        { key = "TANK" },
        { key = "HEALER" },
        { key = "DAMAGER" },
    }
    local RB_GAP = 2
    local RB_W   = math.floor((NAV_W - 16 - RB_GAP * (#ROLE_SLOTS - 1)) / #ROLE_SLOTS)

    local roleButtons = {}

    local function SetRoleButtonVisual(btn, active)
        local c = btn._roleColor
        if active then
            btn:SetBackdropColor(c[1] * 0.30, c[2] * 0.30, c[3] * 0.30, 0.95)
            btn:SetBackdropBorderColor(c[1], c[2], c[3], 0.95)
            if btn._icon then btn._icon:SetVertexColor(c[1], c[2], c[3], 1) end
            if btn._lbl  then btn._lbl:SetTextColor(c[1], c[2], c[3], 1) end
        else
            btn:SetBackdropColor(0.075, 0.075, 0.095, 1)
            btn:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)
            if btn._icon then btn._icon:SetVertexColor(0.42, 0.42, 0.48, 1) end
            if btn._lbl  then btn._lbl:SetTextColor(0.46, 0.46, 0.52, 1) end
        end
    end

    local function RefreshRoleButtons()
        local active = (W and W.GetRoleFilter and W.GetRoleFilter()) or "ALL"
        for _, btn in ipairs(roleButtons) do
            SetRoleButtonVisual(btn, btn._roleKey == active)
        end
    end
    C.RefreshRoleButtons = RefreshRoleButtons

    for i, slot in ipairs(ROLE_SLOTS) do
        local info = (slot.key ~= "ALL") and W.ROLE_INFO and W.ROLE_INFO[slot.key] or nil

        local btn = CreateFrame("Button", nil, roleBar, "BackdropTemplate")
        btn:SetSize(RB_W, ROLEBAR_H)
        btn:SetPoint("TOPLEFT", (i - 1) * (RB_W + RB_GAP), 0)
        btn:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
        btn._roleKey   = slot.key
        btn._roleColor = info and info.color or { aR, aG, aB }

        if info then
            local ico = btn:CreateTexture(nil, "OVERLAY")
            ico:SetSize(14, 14)
            ico:SetPoint("CENTER")
            ico:SetTexture(info.icon)
            btn._icon = ico
            btn._roleName = (W.Loc and W.Loc(info.lk, slot.key)) or slot.key
        else
            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT, 10, "")
            lbl:SetPoint("CENTER")
            lbl:SetText((W.Loc and W.Loc("cfg_rolefilter_all", "Tous")) or "Tous")
            btn._lbl = lbl
        end

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText((W.Loc and W.Loc("cfg_rolefilter_label", "Focus rôle")) or "Focus rôle", 1, 1, 1)
            if self._roleName then
                GameTooltip:AddLine(
                    string.format((W.Loc and W.Loc("cfg_rolefilter_tip", "%s")) or "%s", self._roleName),
                    0.72, 0.72, 0.78, true)
            else
                GameTooltip:AddLine(
                    (W.Loc and W.Loc("cfg_rolefilter_tip_all", "")) or "", 0.72, 0.72, 0.78, true)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function(self)
            if W and W.SetRoleFilter then W.SetRoleFilter(self._roleKey) end
            local gdb = GuiDB()
            gdb.roleFilter = (self._roleKey ~= "ALL") and self._roleKey or nil
            RefreshRoleButtons()
        end)

        roleButtons[#roleButtons + 1] = btn
    end

    -- Restore the saved focus before any page is built.
    if W and W.SetRoleFilter then W.SetRoleFilter(GuiDB().roleFilter or "ALL") end
    RefreshRoleButtons()

    -- ── Zone de navigation défilante ───────────────────────────
    local NAV_TOP    = ROLEBAR_Y + ROLEBAR_H + 8
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
        if C.NotifySearchText then C.NotifySearchText(txt) end
    end)
    searchBox:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    searchBox:SetScript("OnEnterPressed",  function(self)
        if C.SubmitSearch and C.SubmitSearch() then return end
        self:ClearFocus()
    end)
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
    hintTxt:SetText(L["ui_footer_hint"])

    local perfLabel = footer:CreateFontString(nil, "OVERLAY")
    perfLabel:SetFont(FONT, 9, "")
    perfLabel:SetPoint("RIGHT", -26, 0)
    perfLabel:SetTextColor(0.24, 0.24, 0.28, 1)
    configFrame._perfLabel = perfLabel

    -- ==============================================================
    -- RESIZE GRIP (bottom-right)
    -- ==============================================================
    local grip = CreateFrame("Button", nil, configFrame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -3, 3)
    grip:SetFrameLevel(configFrame:GetFrameLevel() + 20)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    local gripTex = grip:GetNormalTexture()
    if gripTex then gripTex:SetVertexColor(0.45, 0.45, 0.52, 1) end
    grip:SetScript("OnMouseDown", function(_, btn)
        if btn == "LeftButton" then configFrame:StartSizing("BOTTOMRIGHT") end
    end)
    grip:SetScript("OnMouseUp", function()
        configFrame:StopMovingOrSizing()
        local db = GuiDB()
        db.width  = math.floor((configFrame:GetWidth()  or PANEL_W) + 0.5)
        db.height = math.floor((configFrame:GetHeight() or PANEL_H) + 0.5)
    end)
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
    if W and W.SetBuildContext then W.SetBuildContext(key, catMeta and catMeta.label or key) end
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

    -- [Lot C] Hide the current page instead of destroying it. Cached
    -- pages are re-shown as-is; NO_CACHE ones are parked and rebuilt.
    if activeCategoryPanel and activeCategoryPanel.Hide then
        activeCategoryPanel:Hide()
    end
    activeCategoryPanel = nil

    for catKey, btn in pairs(categoryButtons) do
        btn.SetActive(catKey == key)
    end

    local cached = (not NO_CACHE[key]) and categoryPanels[key] or nil
    if cached and cached.root then
        activeCategoryPanel = cached.root
        SwitchPendingTab(cached.tabPanel)
    else
        if categoryPanels[key] and categoryPanels[key].root then
            ParkPanel(categoryPanels[key].root)
            categoryPanels[key] = nil
        end

        local builderMap = {
            interface = function(p) return BuildGroupedFromTree(p, "interface") end,
            roles     = function(p) return BuildGroupedFromTree(p, "roles") end,
            units     = function(p) return BuildGroupedFromTree(p, "units") end,
            combat    = function(p) return BuildGroupedFromTree(p, "combat") end,
            comfort   = function(p) return BuildGroupedFromTree(p, "comfort") end,
        }
        local builder = builderMap[key] or SINGLE_PAGES[key]
        if type(builder) == "string" then builder = _G[builder] end
        if builder then
            local bodyParent, shell = CreatePageShell(configFrame.content, catMeta)
            local panel = builder(bodyParent)
            if panel then
                if W and W.ApplyPanelContext then W.ApplyPanelContext(panel, catMeta) end
                panel:SetAllPoints(bodyParent)
                activeCategoryPanel = shell or panel
                categoryPanels[key] = { root = activeCategoryPanel, tabPanel = panel }
            end
            -- Single pages do not go through BuildGroupedPanel, so the
            -- pending deep-link tab is honoured (and cleared) here: some
            -- of them own an inner tab bar (Profiles), others none.
            SwitchPendingTab(panel)
        end
    end

    if activeCategoryPanel then activeCategoryPanel:Show() end
    if key == "units" and TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshThreatPreview then
        TomoMod_UnitFrames.RefreshThreatPreview(true)
    end

    -- [Lot A] Pages are built lazily and cached: a freshly built page has
    -- just registered its tagged sections, so the filter is re-applied here.
    if W and W.ApplyRoleFilter then W.ApplyRoleFilter() end

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

function C.ApplyGUIScale()
    if not configFrame then return end
    configFrame:SetScale(GuiDB().scale or 1)
end

function C.ResetGUISize()
    local db = GuiDB()
    db.width, db.height, db.scale = nil, nil, nil
    if configFrame then
        configFrame:SetSize(PANEL_W, PANEL_H)
        configFrame:SetScale(1)
        configFrame:ClearAllPoints()
        configFrame:SetPoint("CENTER")
    end
end

-- [Lot C] Drops every cached page (presets / profile swaps rewrite the DB
-- outside the panels, so cached widget values would be stale). The rebuild
-- of the open page is deferred one frame so any running click handler of
-- the old page finishes safely first.
-- Drops one cached page so the next SwitchCategory rebuilds it. Deep-links
-- need this: a cached page is re-shown without rebuilding, so no tab bar is
-- created and a pending tab path would never be read.
function C.InvalidateCategory(key)
    local cached = key and categoryPanels[key]
    if not cached then return end
    if cached.root then
        if activeCategoryPanel == cached.root then activeCategoryPanel = nil end
        ParkPanel(cached.root)
    end
    categoryPanels[key] = nil
end

function C.InvalidatePanels()
    ClearContentArea()
    if configFrame and configFrame:IsShown() and currentCategory then
        local key = currentCategory
        C_Timer.After(0, function()
            if configFrame and configFrame:IsShown() and currentCategory == key then
                C.SwitchCategory(key)
            end
        end)
    end
end

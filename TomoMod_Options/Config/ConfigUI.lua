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
    { key = "damagemeter", label = LT("cat_damagemeter", "Damage Meter"),  icon = ICON_PATH .. "icon_damagemeter.tga", accent = { 0.80, 0.27, 1.00 }, desc = LT("cat_damagemeter_desc", "Compteur de degats, recap de mort et recap de donjon."), kw = "damage meter dps hps degats soins recap mort donjon compteur tdm" },
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
    cdforge     = { key = "combat", tab = "cdforge" },
    mythicplus  = { key = "combat", tab = "mythicplus" },

    qol         = { key = "comfort", tab = "qol" },
    housing     = { key = "comfort", tab = "housing" },

    -- Legacy: the old grouped "Tools" category was split back into two
    -- standalone entries. Kept so any stale deep-link still resolves.
    tools       = { key = "profiles" },
}

-- Interface is the first category migrated to the new sidebar workspace.
-- The panel builders stay untouched: only their outer navigation changes.
local INTERFACE_WORKSPACE_ITEMS = {
    { key = "general",    label = L["cfg_tab_general"],    kw = "general minimap interface" },
    { key = "actionbars", label = L["cfg_tab_actionbars"], kw = "action bars barres action" },
    { key = "skins",      label = L["cfg_tab_skins"],      kw = "skins apparence chat sacs menu" },
    { key = "sound",      label = L["cfg_tab_sound"],      kw = "sound son audio" },
}

local UNITS_WORKSPACE_ITEMS = {
    { key = "unitframes",  label = L["cfg_tab_unitframes"],  kw = "unit frames unitframes joueur cible focus boss" },
    { key = "nameplates",  label = L["cfg_tab_nameplates"],  kw = "nameplates plaques noms" },
    { key = "partyframes", label = L["cfg_tab_partyframes"], kw = "party frames groupe party" },
    { key = "raidframes",  label = L["cfg_tab_raidframes"],  kw = "raid frames raid groupe" },
}

local COMBAT_WORKSPACE_ITEMS = {
    { key = "castbars",   label = L["cfg_tab_castbars"],   kw = "castbars cast bars incantation" },
    { key = "resources",  label = L["cfg_tab_resources"],  kw = "resources ressources cooldown resource bars" },
    { key = "cdforge",    label = L["cfg_tab_cdforge"],    kw = "cooldown forge cd forge cooldowns" },
    { key = "mythicplus", label = L["cfg_tab_mythicplus"], kw = "mythic plus mythic+ mplus donjon" },
}

local function ComfortText(fr, en)
    return (GetLocale and GetLocale() == "frFR") and fr or en
end

-- Confort uses one more navigation level than Interface/Unités/Combat.
-- Its group aliases therefore live in a compact secondary navigation on the
-- right, while the existing QOL builders are reused as leaves.
local COMFORT_WORKSPACE_GROUPS = {
    {
        key = "automation", label = ComfortText("Automatisation", "Automation"), default = "automations",
        pages = {
            { key = "automations", label = ComfortText("Général", "General"), kw = "automation automatisation general invite summon delete vendor repair combat text prey" },
            { key = "cinematic",   label = L["tab_qol_cinematic"],  kw = "cinematic cinematique skip" },
            { key = "autoquest",   label = L["tab_qol_auto_quest"], kw = "auto quest quete" },
        },
    },
    {
        key = "players", label = ComfortText("Joueurs", "Players"), default = "mythickeys",
        pages = {
            { key = "mythickeys",  label = L["tab_qol_mythic_keys"],      kw = "mythic keys clefs cles" },
            { key = "skyride",     label = L["tab_qol_skyride"],          kw = "skyride vol flying" },
            { key = "leveling",    label = L["tab_qol_leveling"],         kw = "leveling level niveau" },
            { key = "merchant",    label = L["tab_qol_merchant_tools"],   kw = "merchant vendeur repair reparer" },
            { key = "consumables", label = LT("tab_qol_consumable_bar", ComfortText("Consommables", "Consumables")), kw = "consumables consommables flask food huile oil ready tracker" },
            { key = "rarealert",   label = L["tab_qol_rare_alert"],       kw = "rare alert alerte rares" },
            { key = "profhelper",  label = L["tab_qol_prof_helper"],      kw = "profession helper metier" },
        },
    },
    {
        key = "classes", label = "Classes", default = "classremind",
        pages = {
            { key = "classremind", label = L["tab_qol_class_reminder"], kw = "class reminder classe rappel" },
            { key = "companion",   label = L["tab_qol_companion"],      kw = "companion compagnon" },
        },
    },
    { key = "cvars", label = "CVars", default = "cvaropt", direct = true, kw = "cvars optimizer optimisation" },
    {
        key = "worldquest", label = ComfortText("World Quest", "World Quest"), default = "worldquests",
        pages = {
            { key = "worldquests", label = L["tab_qol_world_quests"], kw = "world quest quetes monde" },
            { key = "waypoint",    label = L["tab_qol_waypoint"],     kw = "waypoint point navigation" },
            { key = "compass",     label = L["tab_qol_compass"],      kw = "compass boussole" },
        },
    },
    {
        key = "other", label = ComfortText("Autres", "Other"), default = "bagmicro",
        pages = {
            -- Kept reachable during the navigation migration. Bag & Micro Menu
            -- will move to Interface > Skins in the later content pass.
            { key = "bagmicro", label = L["tab_qol_bag_micro"], kw = "bag micro menu sacs" },
            { key = "housing",  label = L["cfg_tab_housing"],   kw = "housing logement maison" },
        },
    },
}

local COMFORT_QOL_PAGES = {
    automations = true, cinematic = true, autoquest = true, mythickeys = true,
    skyride = true, leveling = true, merchant = true, rarealert = true,
    profhelper = true, classremind = true, companion = true, cvaropt = true,
    worldquests = true, waypoint = true, compass = true, bagmicro = true,
}

local COMFORT_PAGE_TO_GROUP = {}
local COMFORT_PAGE_LABEL = {}
for _, group in ipairs(COMFORT_WORKSPACE_GROUPS) do
    if group.direct then
        COMFORT_PAGE_TO_GROUP[group.default] = group.key
        COMFORT_PAGE_LABEL[group.default] = group.label
    else
        for _, page in ipairs(group.pages or {}) do
            COMFORT_PAGE_TO_GROUP[page.key] = group.key
            COMFORT_PAGE_LABEL[page.key] = page.label
        end
    end
end

local INTERFACE_WORKSPACE_ALLOWED = {
    accueil = true,
    roles = true,
    interface = true,
    profiles = true,
    diagnostics = true,
}

local UNITS_WORKSPACE_ALLOWED = {
    accueil = true,
    roles = true,
    units = true,
    profiles = true,
    diagnostics = true,
}

local COMBAT_WORKSPACE_ALLOWED = {
    accueil = true,
    roles = true,
    combat = true,
    profiles = true,
    diagnostics = true,
}

local COMFORT_WORKSPACE_ALLOWED = {
    accueil = true,
    roles = true,
    comfort = true,
    profiles = true,
    diagnostics = true,
}

-- State
local configFrame
local currentCategory = nil
local currentWorkspace = nil
local currentInterfacePage = "general"
local currentUnitsPage = "unitframes"
local currentCombatPage = "castbars"
local currentComfortPage = "automations"
local comfortLastPageByGroup = {}
local categoryPanels  = {}
local categoryButtons = {}
local interfaceSubButtons = {}
local unitsSubButtons = {}
local combatSubButtons = {}
local activeCategoryPanel = nil
local hiddenPanelBin = nil

-- [Lot C] Categories re-shown from cache on revisit. Accueil (dashboard,
-- preset tiles), Profiles (profile list) and Diagnostics (live readings)
-- always rebuild so their dynamic content stays fresh.
local NO_CACHE = { accueil = true, profiles = true, diagnostics = true, changelog = true, damagemeter = true }

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

local function CreateSubNavButton(parent, item, categoryKey)
    local cat = GetCategory(categoryKey)
    local aR, aG, aB = CategoryAccent(cat)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(NAV_W, 32)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 28, 0)
    bg:SetPoint("BOTTOMRIGHT", -8, 0)
    bg:SetColorTexture(aR, aG, aB, 0)

    local dot = btn:CreateTexture(nil, "OVERLAY")
    dot:SetSize(4, 4)
    dot:SetPoint("LEFT", 34, 0)
    dot:SetColorTexture(aR, aG, aB, 0.30)

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, "")
    lbl:SetPoint("LEFT", 48, 0)
    lbl:SetPoint("RIGHT", -10, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(item.label or item.key)

    local function SetActive(active)
        if active then
            bg:SetColorTexture(aR, aG, aB, 0.11)
            dot:SetColorTexture(aR, aG, aB, 1)
            lbl:SetTextColor(aR, aG, aB, 1)
        else
            bg:SetColorTexture(aR, aG, aB, 0)
            dot:SetColorTexture(aR, aG, aB, 0.30)
            lbl:SetTextColor(0.52, 0.52, 0.58, 1)
        end
    end
    btn.SetActive = SetActive
    SetActive(false)

    local function IsActive()
        if currentCategory ~= categoryKey then return false end
        if categoryKey == "interface" then
            return currentInterfacePage == item.key
        elseif categoryKey == "units" then
            return currentUnitsPage == item.key
        elseif categoryKey == "combat" then
            return currentCombatPage == item.key
        end
        return false
    end

    btn:SetScript("OnEnter", function()
        if not IsActive() then
            bg:SetColorTexture(aR, aG, aB, 0.05)
            lbl:SetTextColor(0.76, 0.78, 0.80, 1)
        end
    end)
    btn:SetScript("OnLeave", function()
        SetActive(IsActive())
    end)
    btn:SetScript("OnClick", function()
        C.SwitchCategory(item.key)
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
    damagemeter = "TomoMod_ConfigPanel_DamageMeter",
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

-- Interface workspace: same lazy panel caching as CreateTabPanel, but the
-- first navigation level lives in the left sidebar instead of a horizontal
-- tab bar. Nested tabs inside General/ActionBars/Skins/Sound are unchanged.
local function BuildInterfaceWorkspacePanel(parent)
    local tabs = CATEGORY_TREE.interface or {}
    local wrapper = CreateFrame("Frame", nil, parent)
    wrapper:SetAllPoints()
    wrapper._muiDesign = GetCategory("interface")

    local content = CreateFrame("Frame", nil, wrapper)
    content:SetAllPoints()
    content._muiDesign = wrapper._muiDesign

    local tabPanels = {}
    local currentTab = nil

    local function FindTab(key)
        for _, tab in ipairs(tabs) do
            if tab.key == key then return tab end
        end
        return nil
    end

    local function SwitchTab(key)
        local tab = FindTab(key)
        if not tab then return end

        if currentTab and tabPanels[currentTab] and tabPanels[currentTab].Hide then
            tabPanels[currentTab]:Hide()
        end

        if not tabPanels[key] then
            -- Reproduce the outer-tab build path that CreateTabPanel normally
            -- establishes, so Global Search and nested deep-links keep the
            -- exact same category > tab path as before this GUI refactor.
            if W._RestoreTabPath then W._RestoreTabPath({}) end
            if W._SetBuildTabAt then
                W._SetBuildTabAt(1, tab.key, tab.label)
            elseif W._SetBuildTab then
                W._SetBuildTab(tab.key, tab.label)
            end

            local panel = BuildPanelByName(content, tab.global)
            if panel then
                if panel:GetParent() ~= content then panel:SetParent(content) end
                panel:SetAllPoints(content)
                tabPanels[key] = panel
            end
        end

        if tabPanels[key] then tabPanels[key]:Show() end
        currentTab = key
        currentInterfacePage = key

        if configFrame and configFrame._contextTitle then
            local cat = GetCategory("interface")
            configFrame._contextTitle:SetText(
                string.format("%s  /  %s", cat and cat.label or "Interface", tab.label or key))
        end
        if C.RefreshWorkspaceNav then C.RefreshWorkspaceNav() end
        if W.ApplyRoleFilter then W.ApplyRoleFilter() end
    end

    local pendingPath = C._pendingTabPath
    local startKey = (pendingPath and pendingPath[1]) or C._pendingGroupTab or currentInterfacePage
    if not FindTab(startKey) then startKey = tabs[1] and tabs[1].key end

    wrapper.SwitchTab = SwitchTab
    wrapper.HasTab = function(key) return FindTab(key) ~= nil end
    wrapper.content = content
    wrapper:SetScript("OnShow", function()
        if currentTab then SwitchTab(currentTab) end
    end)

    if startKey then SwitchTab(startKey) end
    return wrapper
end

-- Units workspace: Unit Frames, Nameplates, Party Frames and Raid Frames use
-- the same left-sidebar navigation as Interface. Their panel builders and all
-- nested tabs/previews remain untouched.
local function BuildUnitsWorkspacePanel(parent)
    local tabs = CATEGORY_TREE.units or {}
    local wrapper = CreateFrame("Frame", nil, parent)
    wrapper:SetAllPoints()
    wrapper._muiDesign = GetCategory("units")

    local content = CreateFrame("Frame", nil, wrapper)
    content:SetAllPoints()
    content._muiDesign = wrapper._muiDesign

    local tabPanels = {}
    local currentTab = nil

    local function FindTab(key)
        for _, tab in ipairs(tabs) do
            if tab.key == key then return tab end
        end
        return nil
    end

    local function SwitchTab(key)
        local tab = FindTab(key)
        if not tab then return end

        if currentTab and tabPanels[currentTab] and tabPanels[currentTab].Hide then
            tabPanels[currentTab]:Hide()
        end

        if not tabPanels[key] then
            if W._RestoreTabPath then W._RestoreTabPath({}) end
            if W._SetBuildTabAt then
                W._SetBuildTabAt(1, tab.key, tab.label)
            elseif W._SetBuildTab then
                W._SetBuildTab(tab.key, tab.label)
            end

            local panel = BuildPanelByName(content, tab.global)
            if panel then
                if panel:GetParent() ~= content then panel:SetParent(content) end
                panel:SetAllPoints(content)
                tabPanels[key] = panel
            end
        end

        if tabPanels[key] then tabPanels[key]:Show() end
        currentTab = key
        currentUnitsPage = key

        if configFrame and configFrame._contextTitle then
            local cat = GetCategory("units")
            configFrame._contextTitle:SetText(
                string.format("%s  /  %s", cat and cat.label or "Unités", tab.label or key))
        end
        if C.RefreshWorkspaceNav then C.RefreshWorkspaceNav() end
        if W.ApplyRoleFilter then W.ApplyRoleFilter() end
    end

    local pendingPath = C._pendingTabPath
    local startKey = (pendingPath and pendingPath[1]) or C._pendingGroupTab or currentUnitsPage
    if not FindTab(startKey) then startKey = tabs[1] and tabs[1].key end

    wrapper.SwitchTab = SwitchTab
    wrapper.HasTab = function(key) return FindTab(key) ~= nil end
    wrapper.content = content
    wrapper:SetScript("OnShow", function()
        if currentTab then SwitchTab(currentTab) end
    end)

    if startKey then SwitchTab(startKey) end
    return wrapper
end

-- Combat workspace: Castbars, Resources, Cooldown Forge and Mythic+ use the
-- left sidebar as their first navigation level. The panels themselves keep
-- every nested tab, preview and live setting exactly as before.
local function BuildCombatWorkspacePanel(parent)
    local tabs = CATEGORY_TREE.combat or {}
    local wrapper = CreateFrame("Frame", nil, parent)
    wrapper:SetAllPoints()
    wrapper._muiDesign = GetCategory("combat")

    local content = CreateFrame("Frame", nil, wrapper)
    content:SetAllPoints()
    content._muiDesign = wrapper._muiDesign

    local tabPanels = {}
    local currentTab = nil

    local function FindTab(key)
        for _, tab in ipairs(tabs) do
            if tab.key == key then return tab end
        end
        return nil
    end

    local function SwitchTab(key)
        local tab = FindTab(key)
        if not tab then return end

        if currentTab and tabPanels[currentTab] and tabPanels[currentTab].Hide then
            tabPanels[currentTab]:Hide()
        end

        if not tabPanels[key] then
            -- Preserve the old category > tab build path for Global Search
            -- and for any nested deep-links owned by the combat panels.
            if W._RestoreTabPath then W._RestoreTabPath({}) end
            if W._SetBuildTabAt then
                W._SetBuildTabAt(1, tab.key, tab.label)
            elseif W._SetBuildTab then
                W._SetBuildTab(tab.key, tab.label)
            end

            local panel = BuildPanelByName(content, tab.global)
            if panel then
                if panel:GetParent() ~= content then panel:SetParent(content) end
                panel:SetAllPoints(content)
                tabPanels[key] = panel
            end
        end

        if tabPanels[key] then tabPanels[key]:Show() end
        currentTab = key
        currentCombatPage = key

        if configFrame and configFrame._contextTitle then
            local cat = GetCategory("combat")
            configFrame._contextTitle:SetText(
                string.format("%s  /  %s", cat and cat.label or "Combat", tab.label or key))
        end
        if C.RefreshWorkspaceNav then C.RefreshWorkspaceNav() end
        if W.ApplyRoleFilter then W.ApplyRoleFilter() end
    end

    local pendingPath = C._pendingTabPath
    local startKey = (pendingPath and pendingPath[1]) or C._pendingGroupTab or currentCombatPage
    if not FindTab(startKey) then startKey = tabs[1] and tabs[1].key end

    wrapper.SwitchTab = SwitchTab
    wrapper.HasTab = function(key) return FindTab(key) ~= nil end
    wrapper.content = content
    wrapper:SetScript("OnShow", function()
        if currentTab then SwitchTab(currentTab) end
    end)

    if startKey then SwitchTab(startKey) end
    return wrapper
end

local function BuildReadyTrackerComfortPanel(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["ready_tracker_section"], y)
    y = ny
    local _, ny = W.CreateInfoText(c, L["ready_tracker_info"], y)
    y = ny

    local function ReadyDB()
        TomoModDB.consumableBar = TomoModDB.consumableBar or {}
        return TomoModDB.consumableBar
    end
    local function Apply()
        if TomoMod_ConsumableBar and TomoMod_ConsumableBar.ApplySettings then
            TomoMod_ConsumableBar.ApplySettings()
        end
    end

    local db = ReadyDB()
    local _, ny = W.CreateCheckbox(c, L["ready_tracker_enable"], db.enabled ~= false, y, function(v)
        ReadyDB().enabled = v
        Apply()
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, L["ready_tracker_button_side"], {
        { text = L["ready_tracker_side_left"],  value = "left" },
        { text = L["ready_tracker_side_right"], value = "right" },
    }, db.buttonSide or "left", y, function(v)
        ReadyDB().buttonSide = v
        Apply()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["ready_tracker_button_size"], db.buttonSize or 20,
        14, 32, 1, y, function(v)
            ReadyDB().buttonSize = v
            Apply()
        end, "%d px")
    y = ny

    local _, ny = W.CreateSlider(c, L["ready_tracker_tracker_size"], db.iconSize or 36,
        24, 56, 2, y, function(v)
            ReadyDB().iconSize = v
            Apply()
        end, "%d px")
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- Confort workspace: QOL remains the rendering engine, but its extra
-- hierarchy is rendered on the RIGHT. The main sidebar therefore stays as
-- compact as Interface/Unités/Combat and never grows just because Confort
-- contains more pages.
local function BuildComfortWorkspacePanel(parent)
    local wrapper = CreateFrame("Frame", nil, parent)
    wrapper:SetAllPoints()
    wrapper._muiDesign = GetCategory("comfort")

    local cat = GetCategory("comfort")
    local aR, aG, aB = CategoryAccent(cat)
    local GROUP_H, PAGE_H = 34, 30

    -- First row: aliases (Automatisation / Joueurs / Classes / CVars / ...).
    local groupBar = CreateFrame("Frame", nil, wrapper)
    groupBar:SetPoint("TOPLEFT")
    groupBar:SetPoint("TOPRIGHT")
    groupBar:SetHeight(GROUP_H)
    local groupBg = groupBar:CreateTexture(nil, "BACKGROUND")
    groupBg:SetAllPoints()
    groupBg:SetColorTexture(0.052, 0.052, 0.066, 1)
    local groupLine = groupBar:CreateTexture(nil, "ARTWORK")
    groupLine:SetHeight(1)
    groupLine:SetPoint("BOTTOMLEFT")
    groupLine:SetPoint("BOTTOMRIGHT")
    groupLine:SetColorTexture(aR, aG, aB, 0.22)

    -- Second row: only the pages belonging to the selected alias.
    local pageBar = CreateFrame("Frame", nil, wrapper)
    pageBar:SetPoint("TOPLEFT", groupBar, "BOTTOMLEFT", 0, -1)
    pageBar:SetPoint("TOPRIGHT", groupBar, "BOTTOMRIGHT", 0, -1)
    pageBar:SetHeight(PAGE_H)
    local pageBg = pageBar:CreateTexture(nil, "BACKGROUND")
    pageBg:SetAllPoints()
    pageBg:SetColorTexture(0.043, 0.043, 0.056, 1)
    local pageLine = pageBar:CreateTexture(nil, "ARTWORK")
    pageLine:SetHeight(1)
    pageLine:SetPoint("BOTTOMLEFT")
    pageLine:SetPoint("BOTTOMRIGHT")
    pageLine:SetColorTexture(aR, aG, aB, 0.14)

    local content = CreateFrame("Frame", nil, wrapper)
    content:SetPoint("TOPLEFT", pageBar, "BOTTOMLEFT", 0, -1)
    content:SetPoint("BOTTOMRIGHT", 0, 0)
    content._muiDesign = wrapper._muiDesign

    local qolPanel, housingPanel, readyPanel
    local currentSurface
    local groupButtons, pageButtons = {}, {}

    local function FindGroup(groupKey)
        for _, group in ipairs(COMFORT_WORKSPACE_GROUPS) do
            if group.key == groupKey then return group end
        end
        return nil
    end

    local function CreateRightTabButton(parentFrame, label, height, bold)
        local btn = CreateFrame("Button", nil, parentFrame)
        btn:SetHeight(height)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0)
        btn._bg = bg

        local indicator = btn:CreateTexture(nil, "ARTWORK")
        indicator:SetHeight(2)
        indicator:SetPoint("BOTTOMLEFT", 4, 0)
        indicator:SetPoint("BOTTOMRIGHT", -4, 0)
        indicator:SetColorTexture(aR, aG, aB, 1)
        indicator:Hide()
        btn._indicator = indicator

        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(bold and FONT_BOLD or FONT, bold and 11 or 10, "")
        lbl:SetPoint("LEFT", 7, 0)
        lbl:SetPoint("RIGHT", -7, 0)
        lbl:SetJustifyH("CENTER")
        lbl:SetText(label or "")
        lbl:SetTextColor(0.52, 0.52, 0.58, 1)
        btn._label = lbl

        btn.SetActive = function(_, active)
            if active then
                bg:SetColorTexture(aR, aG, aB, 0.11)
                indicator:Show()
                lbl:SetTextColor(aR, aG, aB, 1)
            else
                bg:SetColorTexture(0, 0, 0, 0)
                indicator:Hide()
                lbl:SetTextColor(0.52, 0.52, 0.58, 1)
            end
        end
        btn:SetScript("OnEnter", function(self)
            if not self._active then
                bg:SetColorTexture(aR, aG, aB, 0.05)
                lbl:SetTextColor(0.76, 0.78, 0.80, 1)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetActive(self._active)
        end)
        return btn
    end

    local function LayoutButtons(bar, buttons, orderedKeys, height)
        local count = #orderedKeys
        if count == 0 then return end
        local width = bar:GetWidth() or 0
        if width < 100 then width = parent:GetWidth() or 1000 end
        if width < 100 then width = 1000 end
        local each = math.max(80, math.floor(width / count))
        for i, key in ipairs(orderedKeys) do
            local btn = buttons[key]
            if btn then
                btn:ClearAllPoints()
                btn:SetSize((i == count) and math.max(80, width - each * (count - 1)) or each, height)
                btn:SetPoint("TOPLEFT", bar, "TOPLEFT", (i - 1) * each, 0)
            end
        end
    end

    local groupOrder = {}
    for _, group in ipairs(COMFORT_WORKSPACE_GROUPS) do
        local groupDef = group
        groupOrder[#groupOrder + 1] = groupDef.key
        local btn = CreateRightTabButton(groupBar, groupDef.label, GROUP_H, true)
        btn:SetScript("OnClick", function()
            local target = comfortLastPageByGroup[groupDef.key] or groupDef.default
            if wrapper.SwitchTab then wrapper.SwitchTab(target) end
        end)
        groupButtons[groupDef.key] = btn

        for _, page in ipairs(groupDef.pages or {}) do
            local pageDef = page
            local pageBtn = CreateRightTabButton(pageBar, pageDef.label, PAGE_H, false)
            pageBtn:SetScript("OnClick", function()
                if wrapper.SwitchTab then wrapper.SwitchTab(pageDef.key) end
            end)
            pageBtn:Hide()
            pageButtons[pageDef.key] = pageBtn
        end
    end

    local function LayoutGroupBar()
        LayoutButtons(groupBar, groupButtons, groupOrder, GROUP_H)
    end
    groupBar:SetScript("OnSizeChanged", LayoutGroupBar)
    C_Timer.After(0, LayoutGroupBar)

    local function RefreshRightNav(key)
        local groupKey = COMFORT_PAGE_TO_GROUP[key]
        local group = FindGroup(groupKey)
        for gKey, btn in pairs(groupButtons) do
            btn._active = (gKey == groupKey)
            btn:SetActive(btn._active)
        end
        for _, btn in pairs(pageButtons) do btn:Hide() end

        local orderedPages = {}
        if group and not group.direct then
            for _, page in ipairs(group.pages or {}) do
                orderedPages[#orderedPages + 1] = page.key
                local btn = pageButtons[page.key]
                if btn then
                    btn._active = (page.key == key)
                    btn:SetActive(btn._active)
                    btn:Show()
                end
            end
            pageBar:Show()
            content:ClearAllPoints()
            content:SetPoint("TOPLEFT", pageBar, "BOTTOMLEFT", 0, -1)
            content:SetPoint("BOTTOMRIGHT", 0, 0)
            LayoutButtons(pageBar, pageButtons, orderedPages, PAGE_H)
        else
            pageBar:Hide()
            content:ClearAllPoints()
            content:SetPoint("TOPLEFT", groupBar, "BOTTOMLEFT", 0, -1)
            content:SetPoint("BOTTOMRIGHT", 0, 0)
        end
    end

    pageBar:SetScript("OnSizeChanged", function() RefreshRightNav(currentComfortPage) end)

    local function HideCurrent()
        if currentSurface and currentSurface.Hide then currentSurface:Hide() end
        currentSurface = nil
    end

    local function SetOuterPath(key, label)
        if W._RestoreTabPath then W._RestoreTabPath({}) end
        if W._SetBuildTabAt then
            W._SetBuildTabAt(1, key, label)
        elseif W._SetBuildTab then
            W._SetBuildTab(key, label)
        end
    end

    local function EnsureQOLPanel()
        if qolPanel then return qolPanel end
        SetOuterPath("qol", L["cfg_tab_qol"])
        qolPanel = BuildPanelByName(content, "TomoMod_ConfigPanel_QOL")
        if not qolPanel then return nil end
        if qolPanel:GetParent() ~= content then qolPanel:SetParent(content) end
        qolPanel:SetAllPoints(content)

        -- W.CreateTabPanel exposes its content frame. Hide only the sibling
        -- tab bar and let the content reclaim the full available height.
        if qolPanel.content then
            local children = { qolPanel:GetChildren() }
            for _, child in ipairs(children) do
                if child ~= qolPanel.content and child.Hide then child:Hide() end
            end
            qolPanel.content:ClearAllPoints()
            qolPanel.content:SetAllPoints(qolPanel)
        end
        return qolPanel
    end

    local function EnsureHousingPanel()
        if housingPanel then return housingPanel end
        SetOuterPath("housing", L["cfg_tab_housing"])
        housingPanel = BuildPanelByName(content, "TomoMod_ConfigPanel_Housing")
        if housingPanel then
            if housingPanel:GetParent() ~= content then housingPanel:SetParent(content) end
            housingPanel:SetAllPoints(content)
        end
        return housingPanel
    end

    local function EnsureReadyPanel()
        if readyPanel then return readyPanel end
        SetOuterPath("consumables", COMFORT_PAGE_LABEL.consumables)
        readyPanel = BuildReadyTrackerComfortPanel(content)
        if readyPanel then
            if readyPanel:GetParent() ~= content then readyPanel:SetParent(content) end
            readyPanel:SetAllPoints(content)
        end
        return readyPanel
    end

    local function IsKnownPage(key)
        return COMFORT_QOL_PAGES[key] or key == "consumables" or key == "housing"
    end

    local function SwitchTab(key)
        if key == "qol" then key = currentComfortPage end
        if not IsKnownPage(key) then key = "automations" end
        HideCurrent()

        if COMFORT_QOL_PAGES[key] then
            local panel = EnsureQOLPanel()
            if panel then
                panel:Show()
                if panel.SwitchTab then panel.SwitchTab(key) end
                currentSurface = panel
            end
        elseif key == "consumables" then
            local panel = EnsureReadyPanel()
            if panel then panel:Show(); currentSurface = panel end
        elseif key == "housing" then
            local panel = EnsureHousingPanel()
            if panel then panel:Show(); currentSurface = panel end
        end

        currentComfortPage = key
        local groupKey = COMFORT_PAGE_TO_GROUP[key]
        if groupKey then comfortLastPageByGroup[groupKey] = key end
        RefreshRightNav(key)

        if configFrame and configFrame._contextTitle then
            local group = FindGroup(groupKey)
            local groupLabel = group and group.label
            local pageLabel = COMFORT_PAGE_LABEL[key] or key
            if groupLabel and groupLabel ~= pageLabel then
                configFrame._contextTitle:SetText(string.format("%s  /  %s  /  %s",
                    cat and cat.label or "Confort", groupLabel, pageLabel))
            else
                configFrame._contextTitle:SetText(string.format("%s  /  %s",
                    cat and cat.label or "Confort", pageLabel))
            end
        end

        if C.RefreshWorkspaceNav then C.RefreshWorkspaceNav() end
        if W.ApplyRoleFilter then W.ApplyRoleFilter() end
    end

    local pendingPath = C._pendingTabPath
    local requested = C._pendingGroupTab
    C._pendingGroupTab = nil
    local startKey = currentComfortPage
    if pendingPath and pendingPath[1] == "qol" then
        startKey = pendingPath[2] or startKey
    elseif pendingPath and pendingPath[1] then
        startKey = pendingPath[1]
    elseif requested then
        startKey = requested
    end
    if startKey == "qol" or not IsKnownPage(startKey) then startKey = currentComfortPage end
    if not IsKnownPage(startKey) then startKey = "automations" end

    wrapper.SwitchTab = SwitchTab
    wrapper.HasTab = function(key) return key == "qol" or IsKnownPage(key) end
    wrapper.content = content
    wrapper:SetScript("OnShow", function() SwitchTab(currentComfortPage) end)

    SwitchTab(startKey)
    return wrapper
end

function C.OpenComfortPage(key)
    if not key then return end
    C._pendingGroupTab = key
    C.SwitchCategory("comfort")
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
    for _, item in ipairs(INTERFACE_WORKSPACE_ITEMS) do
        interfaceSubButtons[item.key] = CreateSubNavButton(navChild, item, "interface")
        interfaceSubButtons[item.key]:Hide()
    end
    for _, item in ipairs(UNITS_WORKSPACE_ITEMS) do
        unitsSubButtons[item.key] = CreateSubNavButton(navChild, item, "units")
        unitsSubButtons[item.key]:Hide()
    end
    for _, item in ipairs(COMBAT_WORKSPACE_ITEMS) do
        combatSubButtons[item.key] = CreateSubNavButton(navChild, item, "combat")
        combatSubButtons[item.key]:Hide()
    end

    -- Relayout + filtre de recherche. In Interface workspace, Accueil is the
    -- explicit exit: Roles/Profiles/Diagnostics remain reachable without
    -- collapsing the workspace, exactly like the requested left menu.
    local function RelayoutNav(filter)
        filter = (filter or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        local yy = -4

        for _, btn in pairs(categoryButtons) do btn:Hide() end
        for _, btn in pairs(interfaceSubButtons) do btn:Hide() end
        for _, btn in pairs(unitsSubButtons) do btn:Hide() end
        for _, btn in pairs(combatSubButtons) do btn:Hide() end

        local function Match(label, key, kw)
            if filter == "" then return true end
            local hay = ((label or "") .. " " .. (key or "") .. " " .. (kw or "")):lower()
            return hay:find(filter, 1, true) ~= nil
        end

        local function Place(btn, height)
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", navChild, "TOPLEFT", 0, yy)
            btn:Show()
            yy = yy - height
        end

        if currentWorkspace == "interface" then
            local order = { "accueil", "roles", "interface", "profiles", "diagnostics" }
            for _, key in ipairs(order) do
                local btn = categoryButtons[key]
                local cat = btn and btn._cat
                if btn and cat and Match(cat.label, cat.key, cat.kw) then
                    Place(btn, NAV_BTN_H)
                end
                if key == "interface" then
                    for _, item in ipairs(INTERFACE_WORKSPACE_ITEMS) do
                        local sub = interfaceSubButtons[item.key]
                        if sub and Match(item.label, item.key, item.kw) then
                            Place(sub, 32)
                        end
                    end
                end
            end
        elseif currentWorkspace == "units" then
            local order = { "accueil", "roles", "units", "profiles", "diagnostics" }
            for _, key in ipairs(order) do
                local btn = categoryButtons[key]
                local cat = btn and btn._cat
                if btn and cat and Match(cat.label, cat.key, cat.kw) then
                    Place(btn, NAV_BTN_H)
                end
                if key == "units" then
                    for _, item in ipairs(UNITS_WORKSPACE_ITEMS) do
                        local sub = unitsSubButtons[item.key]
                        if sub and Match(item.label, item.key, item.kw) then
                            Place(sub, 32)
                        end
                    end
                end
            end
        elseif currentWorkspace == "combat" then
            local order = { "accueil", "roles", "combat", "profiles", "diagnostics" }
            for _, key in ipairs(order) do
                local btn = categoryButtons[key]
                local cat = btn and btn._cat
                if btn and cat and Match(cat.label, cat.key, cat.kw) then
                    Place(btn, NAV_BTN_H)
                end
                if key == "combat" then
                    for _, item in ipairs(COMBAT_WORKSPACE_ITEMS) do
                        local sub = combatSubButtons[item.key]
                        if sub and Match(item.label, item.key, item.kw) then
                            Place(sub, 32)
                        end
                    end
                end
            end
        elseif currentWorkspace == "comfort" then
            -- Confort's extra hierarchy is on the right. Keep the main sidebar
            -- deliberately short so it behaves like the other workspaces.
            local order = { "accueil", "roles", "comfort", "profiles", "diagnostics" }
            local comfortChildMatch = false
            if filter ~= "" then
                for _, group in ipairs(COMFORT_WORKSPACE_GROUPS) do
                    if Match(group.label, group.key, group.kw) or Match(group.label, group.default, group.kw) then
                        comfortChildMatch = true; break
                    end
                    for _, page in ipairs(group.pages or {}) do
                        if Match(page.label, page.key, page.kw) then comfortChildMatch = true; break end
                    end
                    if comfortChildMatch then break end
                end
            end
            for _, key in ipairs(order) do
                local btn = categoryButtons[key]
                local catMeta = btn and btn._cat
                local match = btn and catMeta and Match(catMeta.label, catMeta.key, catMeta.kw)
                if key == "comfort" and comfortChildMatch then match = true end
                if match then Place(btn, NAV_BTN_H) end
            end
        else
            for _, cat in ipairs(categories) do
                local btn = categoryButtons[cat.key]
                if Match(cat.label, cat.key, cat.kw) then
                    Place(btn, NAV_BTN_H)
                end
            end
        end

        navChild:SetHeight(math.max(math.abs(yy) + 8, 1))
        navScroll:SetVerticalScroll(0)
        UpdateNavThumb()
    end
    C.RelayoutNav = RelayoutNav
    C.RefreshWorkspaceNav = function()
        for key, btn in pairs(interfaceSubButtons) do
            btn.SetActive(currentCategory == "interface" and currentInterfacePage == key)
        end
        for key, btn in pairs(unitsSubButtons) do
            btn.SetActive(currentCategory == "units" and currentUnitsPage == key)
        end
        for key, btn in pairs(combatSubButtons) do
            btn.SetActive(currentCategory == "combat" and currentCombatPage == key)
        end
        RelayoutNav(searchBox:GetText() or "")
    end

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

    -- Interface opens its dedicated workspace. Accueil is the explicit way
    -- back to the normal TomoMod menu. The three utility destinations shown
    -- in that workspace do not close it; unrelated deep-links do.
    if key == "interface" then
        currentWorkspace = "interface"
    elseif key == "units" then
        currentWorkspace = "units"
    elseif key == "combat" then
        currentWorkspace = "combat"
    elseif key == "comfort" then
        currentWorkspace = "comfort"
    elseif key == "accueil" then
        currentWorkspace = nil
    elseif currentWorkspace == "interface" and not INTERFACE_WORKSPACE_ALLOWED[key] then
        currentWorkspace = nil
    elseif currentWorkspace == "units" and not UNITS_WORKSPACE_ALLOWED[key] then
        currentWorkspace = nil
    elseif currentWorkspace == "combat" and not COMBAT_WORKSPACE_ALLOWED[key] then
        currentWorkspace = nil
    elseif currentWorkspace == "comfort" and not COMFORT_WORKSPACE_ALLOWED[key] then
        currentWorkspace = nil
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
            interface = function(p) return BuildInterfaceWorkspacePanel(p) end,
            roles     = function(p) return BuildGroupedFromTree(p, "roles") end,
            units     = function(p) return BuildUnitsWorkspacePanel(p) end,
            combat    = function(p) return BuildCombatWorkspacePanel(p) end,
            comfort   = function(p) return BuildComfortWorkspacePanel(p) end,
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
    if C.RefreshWorkspaceNav then C.RefreshWorkspaceNav() end
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

-- =====================================================================
-- ConfigUI.lua -- TomoMod GUI v2 shell
--
-- One compact window, docked to the side of the screen so the frames
-- being edited stay visible. Every page lives here and every setting is
-- applied live (Config/Kit.lua); only the Cooldown and Mythic+ Studios
-- keep their own full-screen editors, launched from the sidebar.
--
--   * Ghost mode   the window fades while a slider is dragged, while Alt
--                  is held, and (optionally) while the mouse is away
--   * Show me      opening a frame page pulses the real frame on screen
--   * Search       finds any option, opens its page and lights it up
--   * Simple / expert mode, collapsible sidebar sections
-- =====================================================================

local L = TomoMod_L
local W = TomoMod_Widgets
local TH = W.Theme
local K = TomoMod_Kit
local T = K.T

TomoMod_Config = TomoMod_Config or {}
local C = TomoMod_Config

local FONT, FONT_BOLD, WHITE = K.FONT, K.FONT_BOLD, K.WHITE
local LOGO = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Logo.tga"

StaticPopupDialogs["TOMOMOD_MODULE_RELOAD"] = StaticPopupDialogs["TOMOMOD_MODULE_RELOAD"] or {
    OnShow = function(self)
        local U = TomoMod_Utils
        if U and U.RaiseAboveTomoUI then U.RaiseAboveTomoUI(self) end
    end,
    OnHide = function(self)
        local U = TomoMod_Utils
        if U and U.RestoreTomoUILayer then U.RestoreTomoUILayer(self) end
    end,
    text     = (L and L["cfg_reload_text"]) or T("Recharger l'interface maintenant ?", "Reload the UI now?"),
    button1  = (L and L["cfg_reload_confirm"]) or T("Recharger", "Reload"),
    button2  = (L and L["cfg_reload_later"]) or T("Plus tard", "Later"),
    OnAccept = function() ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- =====================================================================
-- LAYOUT
-- =====================================================================
local DEF_W, DEF_H   = 780, 600
local MIN_W, MIN_H   = 620, 440
local MAX_W, MAX_H   = 1500, 1100
local NAV_W          = 186
local TITLE_H        = 40
local FOOTER_H       = 24
local NAV_ITEM_H     = 24
local NAV_HEAD_H     = 26

-- =====================================================================
-- PAGES
-- =====================================================================
local SECTIONS = {
    { key = "home",      label = nil },
    { key = "roles",     label = T("Rôles", "Roles") },
    { key = "frames",    label = T("Mes cadres", "My frames") },
    { key = "group",     label = T("Groupe & raid", "Party & raid") },
    { key = "combat",    label = T("Combat", "Combat") },
    { key = "studios",   label = T("Studios", "Studios") },
    { key = "interface", label = T("Interface", "Interface") },
    { key = "comfort",   label = T("Confort", "Comfort") },
    { key = "tools",     label = T("Outils", "Tools") },
}
local DEFAULT_COLLAPSED = { roles = true, interface = true, comfort = true, tools = true }

local function LegacyPanel(globalName)
    return function(parent)
        local fn = _G[globalName]
        if fn then return fn(parent) end
    end
end

-- QOL tabs become individual pages: build the QOL tab panel starting on
-- the wanted tab, then hide its own tab bar.
local function QOLPage(tabKey)
    return function(parent)
        local fn = _G.TomoMod_ConfigPanel_QOL
        if not fn then return nil end
        C._pendingTabPath = { tabKey }
        local ok, panel = pcall(fn, parent)
        C._pendingTabPath = nil
        if not ok or not panel then return nil end
        if issecretvalue and issecretvalue(panel) then return nil end
        if panel.content then
            for _, child in ipairs({ panel:GetChildren() }) do
                if child ~= panel.content and child.Hide then child:Hide() end
            end
            panel.content:ClearAllPoints()
            panel.content:SetAllPoints(panel)
        end
        panel._noTabWalk = true
        return panel
    end
end

-- Consumables ("ready tracker") had its own small page in the 4.x shell.
local function BuildReadyTrackerPanel(parent)
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

-- =====================================================================
-- STUDIOS
-- Cooldown and Mythic+ keep their full-screen LoadOnDemand editors; the
-- sidebar launches them. Astral Forge, Party & Raid and Resource & Cast
-- are replaced by pages of this window, but stay installed and can still
-- be opened through C.LaunchStudio (no menu entry points to them).
-- =====================================================================
local STUDIOS = {
    cooldown     = { addon = "TomoMod_CDStudio",           global = "TomoMod_CDStudio",           label = T("Cooldown Studio", "Cooldown Studio") },
    mythic       = { launcher = "mythic",                  label = T("Studio Mythique+", "Mythic+ Studio") },
    astral       = { addon = "TomoMod_AstralForge",        global = "TomoMod_AstralForge",        label = "Astral Forge Studio" },
    group        = { addon = "TomoMod_GroupStudio",        global = "TomoMod_GroupStudio",        label = "Party & Raid Studio", defaultArg = "party" },
    resourcecast = { addon = "TomoMod_ResourceCastStudio", global = "TomoMod_ResourceCastStudio", label = "Resource & Cast Studio", defaultArg = "resources" },
}

function C.LaunchStudio(key, arg)
    local def = STUDIOS[key]
    if not def then return false end
    local Forge = TomoMod_Forge
    if def.launcher == "mythic" then
        if Forge and Forge.Studio and Forge.Studio.ClearSearchBuildContext then
            Forge.Studio.ClearSearchBuildContext()
        end
        local B = TomoMod_MythicPlusLauncher
        if B and B.Open then
            B:Open(arg or "dashboard")
            return true
        end
        return false
    end
    if not (Forge and Forge.Studio and Forge.Studio.Launch) then return false end
    return Forge.Studio.Launch({
        addon  = def.addon,
        global = def.global,
        label  = def.label,
        arg    = arg or def.defaultArg,
    })
end

local LEGACY = {
    { key = "home",        section = "home",      label = T("Accueil", "Home"), build = LegacyPanel("TomoMod_ConfigPanel_Accueil"), kw = "accueil home dashboard tableau de bord modules", noCache = true },
    { key = "role_tank",   section = "roles",     label = T("Tank", "Tank"), build = LegacyPanel("TomoMod_ConfigPanel_RoleTank"), kw = "role tank guide" },
    { key = "role_healer", section = "roles",     label = T("Soigneur", "Healer"), build = LegacyPanel("TomoMod_ConfigPanel_RoleHealer"), kw = "role healer soigneur soins guide" },
    { key = "role_dps",    section = "roles",     label = T("DPS", "DPS"), build = LegacyPanel("TomoMod_ConfigPanel_RoleDps"), kw = "role dps degats guide" },
    { key = "actionbars",  section = "combat",    label = T("Barres d'action", "Action bars"), build = LegacyPanel("TomoMod_ConfigPanel_ActionBars"), kw = "action bars barres action fondu fade paging" },
    { key = "cdm",         section = "combat",    label = T("Gestionnaire de recharges", "Cooldown manager"), build = LegacyPanel("TomoMod_ConfigPanel_CooldownManager"), kw = "cdm cooldown manager blizzard essentiels utilitaires" },
    { key = "damagemeter", section = "combat",    label = T("Compteur de dégâts", "Damage meter"), build = LegacyPanel("TomoMod_ConfigPanel_DamageMeter"), kw = "damage meter dps hps degats soins recap", noCache = true },
    { key = "studio_cooldown", section = "studios", label = T("Cooldown Studio", "Cooldown Studio"), launch = function() return C.LaunchStudio("cooldown") end, kw = "cooldown cooldowns cd forge studio sorts spells barres bars" },
    { key = "studio_mythic",   section = "studios", label = T("Studio Mythique+", "Mythic+ Studio"), launch = function() return C.LaunchStudio("mythic") end, kw = "mythic mythique m+ mplus keystone cle score donjon tracker" },
    { key = "general",     section = "interface", label = T("Général", "General"), build = LegacyPanel("TomoMod_ConfigPanel_General"), kw = "general minimap minicarte infos curseur echelle" },
    { key = "skins",       section = "interface", label = T("Apparence", "Skins"), build = LegacyPanel("TomoMod_ConfigPanel_Skins"), kw = "skins apparence chat sacs bags tooltip infobulles menu quetes" },
    { key = "sound",       section = "interface", label = T("Son", "Sound"), build = LegacyPanel("TomoMod_ConfigPanel_Sound"), kw = "son sound audio heroisme bloodlust" },
    { key = "automations", section = "comfort",   label = T("Automatisations", "Automations"), build = QOLPage("automations"), kw = "auto automatisation invitation invocation suppression texte combat prey traqueur" },
    { key = "cinematic",   section = "comfort",   label = T("Cinématiques", "Cinematics"), build = QOLPage("cinematic"), kw = "cinematique skip passer" },
    { key = "autoquest",   section = "comfort",   label = T("Quêtes auto", "Auto quests"), build = QOLPage("autoquest"), kw = "quete quest auto accepter rendre" },
    { key = "merchant",    section = "comfort",   label = T("Marchand", "Merchant"), build = QOLPage("merchant"), kw = "marchand vendeur reparer vendre gris" },
    { key = "mythickeys",  section = "comfort",   label = T("Clés Mythique+", "Mythic+ keys"), build = QOLPage("mythickeys"), kw = "mythic keys cles clefs keystone" },
    { key = "worldquests", section = "comfort",   label = T("Quêtes du monde", "World quests"), build = QOLPage("worldquests"), kw = "world quest quetes monde" },
    { key = "waypoint",    section = "comfort",   label = T("Point de route", "Waypoint"), build = QOLPage("waypoint"), kw = "waypoint navigation fleche" },
    { key = "compass",     section = "comfort",   label = T("Boussole", "Compass"), build = QOLPage("compass"), kw = "compass boussole cap" },
    { key = "rarealert",   section = "comfort",   label = T("Alertes rares", "Rare alerts"), build = QOLPage("rarealert"), kw = "rare alerte" },
    { key = "skyride",     section = "comfort",   label = T("Vol dynamique", "Skyriding"), build = QOLPage("skyride"), kw = "skyride vol dynamique dragon flying vigueur" },
    { key = "leveling",    section = "comfort",   label = T("Montée de niveau", "Leveling"), build = QOLPage("leveling"), kw = "leveling level niveau xp experience" },
    { key = "gearadvisor", section = "comfort",   label = T("Conseiller d'équipement", "Gear advisor"), build = QOLPage("gearadvisor"), kw = "gear advisor tomogear equipement upgrade score stats" },
    { key = "profhelper",  section = "comfort",   label = T("Métiers", "Professions"), build = QOLPage("profhelper"), kw = "profession metier helper" },
    { key = "consumables", section = "comfort",   label = T("Consommables", "Consumables"), build = BuildReadyTrackerPanel, kw = "consumables consommables flask food huile oil ready tracker" },
    { key = "classremind", section = "comfort",   label = T("Rappels de classe", "Class reminders"), build = QOLPage("classremind"), kw = "class reminder classe rappel" },
    { key = "companion",   section = "comfort",   label = T("Compagnon", "Companion"), build = QOLPage("companion"), kw = "companion compagnon familier" },
    { key = "cvaropt",     section = "comfort",   label = T("Optimisation (CVars)", "Optimisation (CVars)"), build = QOLPage("cvaropt"), kw = "cvar optimisation performance fps" },
    { key = "bagmicro",    section = "comfort",   label = T("Sacs & micro-menu", "Bags & micro menu"), build = QOLPage("bagmicro"), kw = "sacs bags micro menu" },
    { key = "housing",     section = "comfort",   label = T("Logement", "Housing"), build = LegacyPanel("TomoMod_ConfigPanel_Housing"), kw = "housing logement maison horloge" },
    { key = "profiles",    section = "tools",     label = T("Profils", "Profiles"), build = LegacyPanel("TomoMod_ConfigPanel_Profiles"), kw = "profil profile import export sauvegarde backup reset", noCache = true },
    { key = "changelog",   section = "tools",     label = T("Nouveautés", "What's new"), build = LegacyPanel("TomoMod_ConfigPanel_Changelog"), kw = "changelog nouveautes version", noCache = true },
    { key = "diagnostics", section = "tools",     label = T("Diagnostics", "Diagnostics"), build = LegacyPanel("TomoMod_ConfigPanel_Diagnostics"), kw = "diagnostic debug erreurs performance", noCache = true },
}

local PAGES, PAGE_BY_KEY = {}, {}

local function AddPage(def)
    if PAGE_BY_KEY[def.key] then return end
    PAGES[#PAGES + 1] = def
    PAGE_BY_KEY[def.key] = def
end

-- Home first, then the Kit pages, then the rest, so each section lists
-- its pages in the order they are declared.
local function CollectPages()
    for _, def in ipairs(LEGACY) do
        if def.section == "home" or def.section == "roles" then def.legacy = true; AddPage(def) end
    end
    for _, def in ipairs(K.PAGES) do AddPage(def) end
    for _, def in ipairs(LEGACY) do def.legacy = true; AddPage(def) end
    C.Pages, C.PageByKey = PAGES, PAGE_BY_KEY
end
CollectPages()

-- Old keys (EditMode gear, Movers routes, bookmarks, other modules).
-- Quoted keys on purpose: Tools/test_layout_gear.lua checks every EditMode
-- route name against this file as a quoted string.
local ALIASES = {
    ["accueil"] = "home", ["dashboard"] = "home",
    ["roles"] = "role_tank", ["tank"] = "role_tank", ["dps"] = "role_dps",
    ["interface"] = "general", ["comfort"] = "automations", ["qol"] = "automations",
    ["tools"] = "profiles",
    ["unitframes"] = "uf_player", ["units"] = "uf_player", ["player"] = "uf_player",
    ["target"] = "uf_target", ["focus"] = "uf_focus", ["pet"] = "uf_pet", ["targettarget"] = "uf_targettarget",
    ["bossframe"] = "uf_boss", ["boss"] = "uf_boss",
    ["castbars"] = "castbar", ["cast"] = "castbar", ["combat"] = "castbar",
    ["resources"] = "resources",
    ["partyframes"] = "party", ["raidframes"] = "raid", ["healers"] = "healer", ["group"] = "party",
    ["cdforge"] = "studio_cooldown", ["cooldown"] = "studio_cooldown", ["cooldownforge"] = "studio_cooldown",
    ["mythicplus"] = "studio_mythic", ["mythic"] = "studio_mythic",
    ["nameplate"] = "nameplates",
    ["consumable"] = "consumables",
}

local function ResolveKey(key)
    if type(key) ~= "string" then return "home" end
    if PAGE_BY_KEY[key] then return key end
    local a = ALIASES[key] or ALIASES[key:lower()]
    if a and PAGE_BY_KEY[a] then return a end
    return "home"
end

-- =====================================================================
-- STATE
-- =====================================================================
local frame, content, navScroll, navChild, searchBox, crumb
local built = {}            -- [key] = { holder, panel, wrappers }
local current               -- current page key
local navRows = {}          -- [key] = row button
local navHeads = {}         -- [section] = header button
local resultRows = {}
local bin

local function GuiDB() return K.GuiDB() end

local function Bin()
    if not bin then
        bin = CreateFrame("Frame", nil, UIParent)
        bin:Hide()
    end
    return bin
end

local function Park(entry)
    if not entry then return end
    if entry.holder then
        entry.holder:Hide()
        entry.holder:ClearAllPoints()
        entry.holder:SetParent(Bin())
    end
end

-- =====================================================================
-- SEARCH INDEX
-- Widgets call W._RegisterSearchEntry(label, region, kind) while they
-- are built. Only builds this shell starts are recorded, so a lazily
-- built tab cannot be filed under the wrong page.
-- =====================================================================
local index, indexKeys = {}, {}
local buildingPage
local indexedAll = false

local FOLD = {
    ["à"]="a",["â"]="a",["ä"]="a",["á"]="a",["ç"]="c",["é"]="e",["è"]="e",["ê"]="e",["ë"]="e",
    ["î"]="i",["ï"]="i",["í"]="i",["ô"]="o",["ö"]="o",["ó"]="o",["ù"]="u",["û"]="u",["ü"]="u",["ú"]="u",
    ["À"]="a",["Â"]="a",["Ç"]="c",["É"]="e",["È"]="e",["Ê"]="e",["Î"]="i",["Ô"]="o",["Û"]="u",
}
local function Fold(s)
    s = tostring(s or "")
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    s = s:gsub("[\195][\128-\191]", FOLD)
    return s:lower()
end

function W._RegisterSearchEntry(label, region, kind)
    if not buildingPage or type(label) ~= "string" or label == "" then return end
    local path = W.GetBuildTabPath and W.GetBuildTabPath() or {}
    local key = buildingPage .. "\1" .. table.concat(path, ">") .. "\1" .. label
    local e = indexKeys[key]
    if not e then
        e = { page = buildingPage, label = label, fold = Fold(label), path = path, kind = kind }
        indexKeys[key] = e
        index[#index + 1] = e
    end
    e.region = region
end

-- =====================================================================
-- PAGE BUILD / SWITCH
-- =====================================================================
local function BuildPage(key)
    local def = PAGE_BY_KEY[key]
    if not def or not def.build then return nil end
    local entry = built[key]
    if entry and not def.noCache then return entry end
    if entry then Park(entry); built[key] = nil end

    local holder = CreateFrame("Frame", nil, content)
    holder:SetAllPoints(content)
    holder:Hide()

    local body = holder
    if def.legacy then
        -- Legacy panels have no hero: give them a slim title strip.
        local strip = CreateFrame("Frame", nil, holder)
        strip:SetPoint("TOPLEFT")
        strip:SetPoint("TOPRIGHT")
        strip:SetHeight(30)
        local bg = strip:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(TH.accent[1] * 0.10, TH.accent[2] * 0.09, TH.accent[3] * 0.07, 1)
        local t = strip:CreateFontString(nil, "OVERLAY")
        t:SetFont(FONT_BOLD, 13, "")
        t:SetPoint("LEFT", 14, 0)
        t:SetTextColor(TH.textHeader[1], TH.textHeader[2], TH.textHeader[3], 1)
        t:SetText(def.label)
        body = CreateFrame("Frame", nil, holder)
        body:SetPoint("TOPLEFT", 0, -30)
        body:SetPoint("BOTTOMRIGHT")
    end

    if W.SetPanelContext then W.SetPanelContext(nil) end
    if W.SetBuildContext then W.SetBuildContext(key, def.label) end
    if W._RestoreTabPath then W._RestoreTabPath({}) end

    local wrappers = {}
    buildingPage = key
    W._ghostSink = wrappers
    local ok, panel = pcall(def.build, body)
    W._ghostSink = nil
    buildingPage = nil

    if not ok then
        local h = geterrorhandler and geterrorhandler()
        if h then pcall(h, "TomoMod GUI " .. key .. ": " .. tostring(panel)) end
        local err = body:CreateFontString(nil, "OVERLAY")
        err:SetFont(FONT, 11, "")
        err:SetPoint("TOPLEFT", 16, -16)
        err:SetPoint("RIGHT", -16, 0)
        err:SetJustifyH("LEFT")
        err:SetTextColor(1, 0.4, 0.4)
        err:SetText(T("Cette page n'a pas pu s'ouvrir : ", "This page failed to open: ") .. tostring(panel))
        panel = nil
    elseif panel then
        if panel:GetParent() ~= body then panel:SetParent(body) end
        panel:ClearAllPoints()
        panel:SetAllPoints(body)
    end

    entry = { holder = holder, panel = panel, wrappers = wrappers }
    built[key] = entry
    return entry
end

-- Builds every lazy tab of a page once, so search can see it.
local function WalkTabs(key, entry)
    if entry.walked or (entry.panel and entry.panel._noTabWalk) then entry.walked = true return end
    entry.walked = true
    local def = PAGE_BY_KEY[key]
    buildingPage = key
    if W.SetBuildContext then W.SetBuildContext(key, def and def.label) end
    W._ghostSink = entry.wrappers
    local i = 1
    while entry.wrappers[i] do
        local wr = entry.wrappers[i]
        if wr.tabKeys and wr.SwitchTab then
            for _, tk in ipairs(wr.tabKeys) do pcall(wr.SwitchTab, tk) end
            if wr.tabKeys[1] then pcall(wr.SwitchTab, wr.tabKeys[1]) end
        end
        i = i + 1
    end
    W._ghostSink = nil
    buildingPage = nil
end

local RelayoutNav   -- defined with the sidebar below

local function SetCrumb(def)
    if not crumb then return end
    local sec
    for _, s in ipairs(SECTIONS) do if s.key == def.section then sec = s end end
    if sec and sec.label then
        crumb:SetText("|cff7f8f9f" .. sec.label .. "  /  |r" .. def.label)
    else
        crumb:SetText(def.label)
    end
end

function C.SwitchCategory(key)
    if not frame then return end
    if W.CloseDropdowns then W.CloseDropdowns() end
    key = ResolveKey(key)
    local def = PAGE_BY_KEY[key]

    -- A Studio entry opens its own window; the current page stays.
    if def.launch then
        pcall(def.launch)
        if not current then C.SwitchCategory("home") end
        return
    end

    if current and current ~= key then
        local prev = PAGE_BY_KEY[current]
        if prev and prev.onHide then pcall(prev.onHide) end
        local pe = built[current]
        if pe and pe.holder then pe.holder:Hide() end
    end

    local entry = BuildPage(key)
    current = key
    GuiDB().lastPage = key
    if entry and entry.holder then
        entry.holder:SetParent(content)
        entry.holder:ClearAllPoints()
        entry.holder:SetAllPoints(content)
        entry.holder:Show()
        if not C._noGlide and K.Animated() and TomoMod_Utils.SlideIn then TomoMod_Utils.SlideIn(entry.holder, 16, 0, 0.18) end
    end
    if def.onShow then pcall(def.onShow) end
    SetCrumb(def)

    -- Expand the section that holds the page.
    local col = GuiDB().collapsed
    if col and col[def.section] then col[def.section] = false end
    if RelayoutNav then RelayoutNav() end

    -- Show me, automatically, without nagging when nothing is on screen.
    if def.locate and GuiDB().autoLocate ~= false and not C._noGlide then
        C_Timer.After(0.15, function()
            if current == key and frame:IsShown() then K.Locate(def.locate, def.label, true) end
        end)
    end
end

function C.RebuildCurrentPage()
    if not current then return end
    local entry = built[current]
    local def = PAGE_BY_KEY[current]
    -- A rebuild is an in-place refresh: keep the scroll position and skip
    -- the page glide, so the player does not lose their place.
    local offset
    if entry and entry.panel and entry.panel.scroll and entry.panel.scroll.GetVerticalScroll then
        offset = W.ScrollPos(entry.panel.scroll)
    end
    if entry then
        if def and def.onHide then pcall(def.onHide) end
        Park(entry)
        built[current] = nil
    end
    local key = current
    current = nil
    C._noGlide = true
    C.SwitchCategory(key)
    C._noGlide = nil
    local ne = built[key]
    local sc = offset and offset > 0 and ne and ne.panel and ne.panel.scroll
    if sc then
        C_Timer.After(0, function()
            local range = W.ScrollRange(sc)
            sc:SetVerticalScroll(math.min(offset, range))
            if ne.panel.UpdateScroll then ne.panel.UpdateScroll() end
        end)
    end
end

function C.InvalidateCategory(key)
    key = ResolveKey(key)
    local entry = built[key]
    if not entry then return end
    Park(entry)
    built[key] = nil
end

function C.InvalidatePanels()
    for key, entry in pairs(built) do
        if key ~= current then Park(entry); built[key] = nil end
    end
    indexedAll = false
    if frame and frame:IsShown() and current then
        C_Timer.After(0, function() C.RebuildCurrentPage() end)
    elseif current then
        local entry = built[current]
        if entry then Park(entry); built[current] = nil end
    end
end

-- Jump to a search hit: open the page, walk its tab bars, scroll, flash.
local function JumpTo(e)
    C.SwitchCategory(e.page)
    local entry = built[e.page]
    if not entry then return end
    for level, tk in ipairs(e.path or {}) do
        for _, wr in ipairs(entry.wrappers) do
            if wr.tabLevel == level and wr.HasTab and wr.HasTab(tk) and wr.SwitchTab then
                pcall(wr.SwitchTab, tk)
            end
        end
    end
    local region = e.region
    if not region then return end
    C_Timer.After(0.05, function()
        local p = region.GetParent and region:GetParent()
        local scroller
        while p do
            if p.child and p.UpdateScroll then scroller = p break end
            p = p.GetParent and p:GetParent()
        end
        if scroller and W.ScrollToFrame then
            W.ScrollToFrame(scroller, region, 30)
        elseif W.FlashHighlight then
            W.FlashHighlight(region)
        end
    end)
end

-- Open a page and land on one of its labels (a card title, an option).
-- Used by the role guides; falls back to the page alone.
function C.OpenPageAt(key, label)
    C.OpenCategory(key)
    if type(label) ~= "string" or label == "" then return end
    key = ResolveKey(key)
    local want = Fold(label)
    for _, e in ipairs(index) do
        if e.page == key and e.fold == want then
            JumpTo(e)
            return true
        end
    end
end

-- =====================================================================
-- SIDEBAR
-- =====================================================================
local function NavRow(parent, def)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(NAV_ITEM_H)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0)
    local bar = b:CreateTexture(nil, "ARTWORK")
    bar:SetWidth(3)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("BOTTOMLEFT")
    bar:SetColorTexture(TH.accent[1], TH.accent[2], TH.accent[3], 1)
    bar:Hide()
    local t = b:CreateFontString(nil, "OVERLAY")
    t:SetFont(FONT, 11, "")
    t:SetPoint("LEFT", def.section == "home" and 14 or 22, 0)
    t:SetPoint("RIGHT", -8, 0)
    t:SetJustifyH("LEFT")
    t:SetText(def.label)
    b.SetActive = function(_, on)
        if on then
            bg:SetColorTexture(TH.accent[1], TH.accent[2], TH.accent[3], 0.14)
            bar:Show()
            t:SetTextColor(TH.accent[1], TH.accent[2], TH.accent[3], 1)
        else
            bg:SetColorTexture(0, 0, 0, 0)
            bar:Hide()
            t:SetTextColor(TH.text[1], TH.text[2], TH.text[3], 0.92)
        end
    end
    b:SetScript("OnEnter", function()
        if current ~= def.key then bg:SetColorTexture(TH.accent[1], TH.accent[2], TH.accent[3], 0.06) end
        if def.locate then K.Locate(def.locate, def.label, true) end
    end)
    b:SetScript("OnLeave", function() b:SetActive(current == def.key) end)
    b:SetScript("OnClick", function() C.SwitchCategory(def.key) end)
    b:SetActive(false)
    return b
end

local function NavHead(parent, sec)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(NAV_HEAD_H)
    local t = b:CreateFontString(nil, "OVERLAY")
    t:SetFont(FONT_BOLD, 10, "")
    t:SetPoint("LEFT", 12, -2)
    t:SetTextColor(TH.accent[1], TH.accent[2], TH.accent[3], 1)
    t:SetText(string.upper(sec.label))
    local arrow = b:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(FONT_BOLD, 11, "")
    arrow:SetPoint("RIGHT", -10, -2)
    arrow:SetTextColor(TH.textDim[1], TH.textDim[2], TH.textDim[3], 1)
    b.arrow = arrow
    local line = b:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 10, 0)
    line:SetPoint("BOTTOMRIGHT", -10, 0)
    line:SetColorTexture(TH.border[1], TH.border[2], TH.border[3], 0.6)
    b:SetScript("OnClick", function()
        local col = GuiDB().collapsed
        col[sec.key] = not col[sec.key]
        RelayoutNav()
    end)
    return b
end

local function ResultRow(parent, i)
    local b = resultRows[i]
    if b then return b end
    b = CreateFrame("Button", nil, parent)
    b:SetHeight(32)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0)
    b.t = b:CreateFontString(nil, "OVERLAY")
    b.t:SetFont(FONT, 11, "")
    b.t:SetPoint("TOPLEFT", 12, -4)
    b.t:SetPoint("RIGHT", -6, 0)
    b.t:SetJustifyH("LEFT")
    b.t:SetTextColor(TH.text[1], TH.text[2], TH.text[3], 1)
    b.s = b:CreateFontString(nil, "OVERLAY")
    b.s:SetFont(FONT, 9, "")
    b.s:SetPoint("TOPLEFT", b.t, "BOTTOMLEFT", 0, -1)
    b.s:SetPoint("RIGHT", -6, 0)
    b.s:SetJustifyH("LEFT")
    b.s:SetTextColor(TH.accent[1], TH.accent[2], TH.accent[3], 0.9)
    b:SetScript("OnEnter", function() bg:SetColorTexture(TH.accent[1], TH.accent[2], TH.accent[3], 0.10) end)
    b:SetScript("OnLeave", function() bg:SetColorTexture(0, 0, 0, 0) end)
    b:SetScript("OnClick", function(self)
        if self.entry then JumpTo(self.entry) elseif self.pageKey then C.SwitchCategory(self.pageKey) end
    end)
    resultRows[i] = b
    return b
end

local indexing = false
local function IndexEverything(onDone)
    if indexedAll or indexing then return end
    indexing = true
    local queue = {}
    for _, def in ipairs(PAGES) do queue[#queue + 1] = def.key end
    local i = 0
    local function Step()
        i = i + 1
        local key = queue[i]
        if not key or not frame then
            indexing = false
            indexedAll = true
            if onDone then onDone() end
            return
        end
        local def = PAGE_BY_KEY[key]
        if not def.noCache or not built[key] then
            local entry = built[key] or BuildPage(key)
            if entry then
                if key ~= current and entry.holder then entry.holder:Hide() end
                WalkTabs(key, entry)
            end
        end
        C_Timer.After(0, Step)
    end
    Step()
end

-- Diagnostics: how much the search knows about.
function C.SearchIndexSize() return #index end

local function SearchResults(q)
    local out = {}
    local fq = Fold(q)
    for _, def in ipairs(PAGES) do
        local hay = Fold(def.label .. " " .. (def.kw or ""))
        if hay:find(fq, 1, true) then
            out[#out + 1] = { label = def.label, sub = T("Page", "Page"), pageKey = def.key }
        end
    end
    local seen = {}
    for _, e in ipairs(index) do
        if #out >= 40 then break end
        if e.fold:find(fq, 1, true) then
            local d = PAGE_BY_KEY[e.page]
            local k = e.page .. "\1" .. e.fold
            if d and not seen[k] then
                seen[k] = true
                out[#out + 1] = { label = e.label, sub = d.label, entry = e }
            end
        end
    end
    return out
end
C._SearchResults = SearchResults

function RelayoutNav()
    if not navChild then return end
    local q = searchBox and searchBox:GetText() or ""
    local y = -4
    local w = NAV_W - 14

    for _, b in pairs(navRows) do b:Hide() end
    for _, b in pairs(navHeads) do b:Hide() end
    for _, b in ipairs(resultRows) do b:Hide() end

    if q ~= "" then
        local results = SearchResults(q)
        for i, r in ipairs(results) do
            local b = ResultRow(navChild, i)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", 0, y)
            b:SetWidth(w)
            b.t:SetText(r.label)
            b.s:SetText(r.sub)
            b.entry, b.pageKey = r.entry, r.pageKey
            b:Show()
            y = y - 34
        end
        if #results == 0 then
            local b = ResultRow(navChild, 1)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", 0, y)
            b:SetWidth(w)
            b.t:SetText(indexing and T("Recherche...", "Searching...") or T("Aucun résultat", "No result"))
            b.s:SetText("")
            b.entry, b.pageKey = nil, nil
            b:Show()
            y = y - 34
        end
    else
        local col = GuiDB().collapsed
        for _, sec in ipairs(SECTIONS) do
            local any = false
            for _, def in ipairs(PAGES) do if def.section == sec.key then any = true break end end
            if any then
                local open = true
                if sec.label then
                    local h = navHeads[sec.key]
                    h:ClearAllPoints()
                    h:SetPoint("TOPLEFT", 0, y)
                    h:SetWidth(w)
                    open = not col[sec.key]
                    h.arrow:SetText(open and "-" or "+")
                    h:Show()
                    y = y - NAV_HEAD_H - 2
                end
                if open then
                    for _, def in ipairs(PAGES) do
                        if def.section == sec.key then
                            local b = navRows[def.key]
                            b:ClearAllPoints()
                            b:SetPoint("TOPLEFT", 0, y)
                            b:SetWidth(w)
                            b:SetActive(current == def.key)
                            b:Show()
                            y = y - NAV_ITEM_H
                        end
                    end
                end
                y = y - 4
            end
        end
    end
    navChild:SetHeight(math.abs(y) + 8)
    if navScroll and navScroll.UpdateScroll then navScroll.UpdateScroll() end
end

-- =====================================================================
-- WINDOW HELPERS
-- =====================================================================
local function ApplyDock()
    if not frame then return end
    local db = GuiDB()
    local dock = db.dock or "right"
    frame:ClearAllPoints()
    if dock == "left" then
        frame:SetPoint("LEFT", UIParent, "LEFT", 24, 0)
    elseif dock == "free" and db.pos then
        frame:SetPoint(db.pos[1] or "CENTER", UIParent, db.pos[2] or "CENTER", db.pos[3] or 0, db.pos[4] or 0)
    else
        frame:SetPoint("RIGHT", UIParent, "RIGHT", -24, 0)
    end
end

local function FitToScreen()
    if not frame then return end
    -- Our own window: its scale is the one we set from the saved setting.
    local scale = GuiDB().scale or 1
    local maxW = math.max(MIN_W, math.min(MAX_W, math.floor(((UIParent:GetWidth() or MAX_W) - 40) / scale)))
    local maxH = math.max(MIN_H, math.min(MAX_H, math.floor(((UIParent:GetHeight() or MAX_H) - 40) / scale)))
    if frame.SetResizeBounds then
        frame:SetResizeBounds(MIN_W, MIN_H, maxW, maxH)
    elseif frame.SetMinResize then
        frame:SetMinResize(MIN_W, MIN_H)
        frame:SetMaxResize(maxW, maxH)
    end
    local w, h = frame:GetWidth() or DEF_W, frame:GetHeight() or DEF_H
    if w > maxW or h > maxH then frame:SetSize(math.min(w, maxW), math.min(h, maxH)) end
end

local function HeaderButton(parent, text, width, tip, onClick)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width, 24)
    b:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    local t = b:CreateFontString(nil, "OVERLAY")
    t:SetFont(FONT, 10, "")
    t:SetPoint("CENTER")
    b.t = t
    b.SetOn = function(self, on)
        self.on = on
        if on then
            self:SetBackdropColor(TH.accent[1] * 0.25, TH.accent[2] * 0.20, TH.accent[3] * 0.10, 1)
            self:SetBackdropBorderColor(TH.accent[1], TH.accent[2], TH.accent[3], 0.9)
            t:SetTextColor(TH.accent[1], TH.accent[2], TH.accent[3], 1)
        else
            self:SetBackdropColor(TH.bgLight[1], TH.bgLight[2], TH.bgLight[3], 1)
            self:SetBackdropBorderColor(TH.border[1], TH.border[2], TH.border[3], 1)
            t:SetTextColor(TH.text[1], TH.text[2], TH.text[3], 0.9)
        end
    end
    t:SetText(text)
    b:SetScript("OnClick", onClick)
    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(TH.accent[1], TH.accent[2], TH.accent[3], 1)
        if tip then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(text, TH.accent[1], TH.accent[2], TH.accent[3])
            GameTooltip:AddLine(tip, 0.9, 0.88, 0.82, true)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self) self:SetOn(self.on); GameTooltip:Hide() end)
    b:SetOn(false)
    return b
end

-- Override Button:SetText for our label FontString.
local function SetLabel(b, text) b.t:SetText(text) end

-- =====================================================================
-- GHOST MODE
-- =====================================================================
local ghost = { alpha = 1, pressT = nil, onSlider = false }

local function IsInside(f, root)
    local depth = 0
    while f and depth < 30 do
        if f == root then return true end
        f = f.GetParent and f:GetParent()
        depth = depth + 1
    end
    return false
end

local function MouseFocus()
    if GetMouseFoci then
        local foci = GetMouseFoci()
        return foci and foci[1]
    end
    return GetMouseFocus and GetMouseFocus()
end

local function GhostTarget()
    if IsAltKeyDown() and not (GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()) then
        return 0.10
    end
    if IsMouseButtonDown("LeftButton") then
        if ghost.pressT == nil then
            ghost.pressT = GetTime()
            local f = MouseFocus()
            ghost.onSlider = f and f.GetObjectType and IsInside(f, frame)
                and (f:GetObjectType() == "Slider"
                     or (f:GetParent() and f:GetParent().GetObjectType and f:GetParent():GetObjectType() == "Slider")) or false
        end
        if ghost.onSlider and GetTime() - ghost.pressT > 0.12 then return 0.22 end
    else
        ghost.pressT, ghost.onSlider = nil, false
    end
    if GuiDB().ghost ~= false and not frame:IsMouseOver()
        and not W._openDropdown
        and not (ColorPickerFrame and ColorPickerFrame:IsShown())
        and not (GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()) then
        return 0.55
    end
    return 1
end

local function GhostUpdate(self, elapsed)
    local target = GhostTarget()
    local a = ghost.alpha
    if a ~= target then
        local step = (elapsed or 0.016) * 5
        if a < target then a = math.min(target, a + step) else a = math.max(target, a - step) end
        ghost.alpha = a
        self:SetAlpha(a)
    end
end

-- =====================================================================
-- CREATE
-- =====================================================================
local function CreateWindow()
    if frame then return end
    local db = GuiDB()
    db.collapsed = db.collapsed or {}
    for k, v in pairs(DEFAULT_COLLAPSED) do
        if db.collapsed[k] == nil then db.collapsed[k] = v end
    end

    frame = CreateFrame("Frame", "TomoModConfigFrame", UIParent, "BackdropTemplate")
    frame:SetSize(math.max(MIN_W, math.min(db.w or DEF_W, MAX_W)), math.max(MIN_H, math.min(db.h or DEF_H, MAX_H)))
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(500)
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(TH.bg[1], TH.bg[2], TH.bg[3], 0.98)
    frame:SetBackdropBorderColor(TH.border[1], TH.border[2], TH.border[3], 1)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetScale(db.scale or 1)
    frame:Hide()
    TomoMod_Utils.CloseOnEscape(frame)
    FitToScreen()
    ApplyDock()

    frame:SetScript("OnShow", function(self)
        C.isOpen = true
        FitToScreen()
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        self:SetFrameLevel(500)
        ghost.alpha = 1
        self:SetAlpha(1)
        self:SetScript("OnUpdate", GhostUpdate)
        if K.Animated() and TomoMod_Utils.SlideIn then
            local d = GuiDB().dock
            TomoMod_Utils.SlideIn(self, d == "left" and -30 or (d == "free" and 0 or 30), d == "free" and -12 or 0, 0.22)
        end
        if not current then
            C.SwitchCategory(GuiDB().lastPage or "home")
        else
            local def = PAGE_BY_KEY[current]
            if def and def.onShow then pcall(def.onShow) end
        end
    end)
    frame:SetScript("OnHide", function(self)
        C.isOpen = false
        self:SetScript("OnUpdate", nil)
        if W.CloseDropdowns then W.CloseDropdowns() end
        if GameTooltip then GameTooltip:Hide() end
        local def = current and PAGE_BY_KEY[current]
        if def and def.onHide then pcall(def.onHide) end
        K.PartyPreview(false)
        K.RaidPreview(false)
        K.CastPreview(false)
        if TomoMod_Profiles and TomoMod_Profiles.AutoSaveActiveProfile then
            TomoMod_Profiles.AutoSaveActiveProfile()
        end
    end)

    -- ---- title bar --------------------------------------------------------
    local title = CreateFrame("Frame", nil, frame)
    title:SetPoint("TOPLEFT", 1, -1)
    title:SetPoint("TOPRIGHT", -1, -1)
    title:SetHeight(TITLE_H)
    title:EnableMouse(true)
    title:RegisterForDrag("LeftButton")
    title:SetScript("OnDragStart", function() frame:StartMoving() end)
    title:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local p, _, rp, x, y = frame:GetPoint(1)
        local d = GuiDB()
        d.dock, d.pos = "free", { p, rp, x, y }
        if frame._dockBtn then SetLabel(frame._dockBtn, T("Ancrer", "Dock")) end
    end)
    local tbg = title:CreateTexture(nil, "BACKGROUND")
    tbg:SetAllPoints()
    tbg:SetColorTexture(TH.bgDark[1], TH.bgDark[2], TH.bgDark[3], 1)
    local tline = title:CreateTexture(nil, "ARTWORK")
    tline:SetHeight(1)
    tline:SetPoint("BOTTOMLEFT")
    tline:SetPoint("BOTTOMRIGHT")
    tline:SetColorTexture(TH.accent[1], TH.accent[2], TH.accent[3], 0.45)

    local logo = title:CreateTexture(nil, "OVERLAY")
    logo:SetSize(26, 26)
    logo:SetPoint("LEFT", 10, 0)
    logo:SetTexture(LOGO)
    local tt = title:CreateFontString(nil, "OVERLAY")
    tt:SetFont(FONT_BOLD, 14, "")
    tt:SetPoint("LEFT", logo, "RIGHT", 8, 0)
    tt:SetText("|cff2e9dd8Tomo|r|cffFFFFFFMod|r")

    local close = HeaderButton(title, "X", 26, nil, function() frame:Hide() end)
    close:SetPoint("RIGHT", -8, 0)

    local moveBtn = HeaderButton(title, T("Déplacer", "Move"), 72,
        T("Déverrouille l'interface pour glisser les cadres. La fenêtre reste ouverte.",
          "Unlocks the UI so you can drag frames. This window stays open."),
        function() if TomoMod_Movers and TomoMod_Movers.Toggle then TomoMod_Movers.Toggle() end end)
    moveBtn:SetPoint("RIGHT", close, "LEFT", -6, 0)

    local dockBtn = HeaderButton(title, T("Ancrer", "Dock"), 64,
        T("Colle la fenêtre au bord droit ou gauche de l'écran pour garder tes cadres visibles.",
          "Snaps the window to the right or left edge so your frames stay visible."),
        function(self)
            local d = GuiDB()
            d.dock = (d.dock == "right" or d.dock == nil) and "left" or "right"
            ApplyDock()
        end)
    dockBtn:SetPoint("RIGHT", moveBtn, "LEFT", -6, 0)
    frame._dockBtn = dockBtn

    local ghostBtn = HeaderButton(title, T("Transparence", "See-through"), 92,
        T("Activé : la fenêtre s'estompe quand ta souris en sort.\nToujours : elle s'efface quand tu tires un curseur ou maintiens Alt.",
          "On: the window fades when your mouse leaves it.\nAlways: it fades while you drag a slider or hold Alt."),
        function(self)
            local d = GuiDB()
            d.ghost = (d.ghost == false)
            self:SetOn(d.ghost ~= false)
        end)
    ghostBtn:SetPoint("RIGHT", dockBtn, "LEFT", -6, 0)
    ghostBtn:SetOn(db.ghost ~= false)

    local expertBtn = HeaderButton(title, T("Mode expert", "Expert mode"), 86,
        T("Affiche tous les réglages avancés. Désactivé : seulement l'essentiel.",
          "Shows every advanced setting. Off: only the essentials."),
        function(self)
            K.SetExpert(not K.Expert())
            self:SetOn(K.Expert())
        end)
    expertBtn:SetPoint("RIGHT", ghostBtn, "LEFT", -6, 0)
    expertBtn:SetOn(K.Expert())

    -- ---- sidebar ----------------------------------------------------------
    local side = CreateFrame("Frame", nil, frame)
    side:SetPoint("TOPLEFT", 1, -(TITLE_H + 1))
    side:SetPoint("BOTTOMLEFT", 1, FOOTER_H + 1)
    side:SetWidth(NAV_W)
    local sbg = side:CreateTexture(nil, "BACKGROUND")
    sbg:SetAllPoints()
    sbg:SetColorTexture(TH.bgMid[1], TH.bgMid[2], TH.bgMid[3], 1)
    local sline = side:CreateTexture(nil, "ARTWORK")
    sline:SetWidth(1)
    sline:SetPoint("TOPRIGHT")
    sline:SetPoint("BOTTOMRIGHT")
    sline:SetColorTexture(TH.border[1], TH.border[2], TH.border[3], 1)

    local sw = CreateFrame("Frame", nil, side, "BackdropTemplate")
    sw:SetPoint("TOPLEFT", 8, -8)
    sw:SetPoint("TOPRIGHT", -8, -8)
    sw:SetHeight(26)
    sw:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    sw:SetBackdropColor(TH.bgDark[1], TH.bgDark[2], TH.bgDark[3], 1)
    sw:SetBackdropBorderColor(TH.border[1], TH.border[2], TH.border[3], 1)
    searchBox = CreateFrame("EditBox", nil, sw)
    searchBox:SetPoint("TOPLEFT", 8, 0)
    searchBox:SetPoint("BOTTOMRIGHT", -22, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetFont(FONT, 11, "")
    searchBox:SetTextColor(TH.text[1], TH.text[2], TH.text[3], 1)
    local ph = searchBox:CreateFontString(nil, "OVERLAY")
    ph:SetFont(FONT, 11, "")
    ph:SetPoint("LEFT", 0, 0)
    ph:SetTextColor(TH.textFaint[1], TH.textFaint[2], TH.textFaint[3], 1)
    ph:SetText(T("Rechercher un réglage...", "Search a setting..."))
    local clr = CreateFrame("Button", nil, sw)
    clr:SetSize(18, 18)
    clr:SetPoint("RIGHT", -4, 0)
    local clrT = clr:CreateFontString(nil, "OVERLAY")
    clrT:SetFont(FONT_BOLD, 11, "")
    clrT:SetPoint("CENTER")
    clrT:SetText("x")
    clrT:SetTextColor(TH.textDim[1], TH.textDim[2], TH.textDim[3], 1)
    clr:Hide()
    clr:SetScript("OnClick", function() searchBox:SetText(""); searchBox:ClearFocus() end)
    searchBox:SetScript("OnTextChanged", function(self)
        local txt = self:GetText() or ""
        ph:SetShown(txt == "")
        clr:SetShown(txt ~= "")
        if txt ~= "" and not indexedAll then IndexEverything(function() RelayoutNav() end) end
        if navScroll and navScroll.scroll then navScroll.scroll:SetVerticalScroll(0) end
        RelayoutNav()
    end)
    searchBox:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    searchBox:SetScript("OnEnterPressed", function(self)
        local first = resultRows[1]
        if first and first:IsShown() and (first.entry or first.pageKey) then first:Click() end
        self:ClearFocus()
    end)
    searchBox:SetScript("OnEditFocusGained", function() sw:SetBackdropBorderColor(TH.accent[1], TH.accent[2], TH.accent[3], 1) end)
    searchBox:SetScript("OnEditFocusLost", function() sw:SetBackdropBorderColor(TH.border[1], TH.border[2], TH.border[3], 1) end)

    local navHost = CreateFrame("Frame", nil, side)
    navHost:SetPoint("TOPLEFT", 4, -42)
    navHost:SetPoint("BOTTOMRIGHT", -2, 4)
    navScroll = W.CreateScrollPanel(navHost)
    navChild = navScroll.child
    for _, def in ipairs(PAGES) do navRows[def.key] = NavRow(navChild, def) end
    for _, sec in ipairs(SECTIONS) do
        if sec.label then navHeads[sec.key] = NavHead(navChild, sec) end
    end

    -- ---- content ----------------------------------------------------------
    content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", NAV_W + 2, -(TITLE_H + 1))
    content:SetPoint("BOTTOMRIGHT", -1, FOOTER_H + 1)
    local cbg = content:CreateTexture(nil, "BACKGROUND", nil, -8)
    cbg:SetAllPoints()
    cbg:SetColorTexture(TH.bg[1] * 0.8, TH.bg[2] * 0.8, TH.bg[3] * 0.8, 1)

    -- ---- footer -------------------------------------------------------------
    local foot = CreateFrame("Frame", nil, frame)
    foot:SetPoint("BOTTOMLEFT", 1, 1)
    foot:SetPoint("BOTTOMRIGHT", -1, 1)
    foot:SetHeight(FOOTER_H)
    local fbg = foot:CreateTexture(nil, "BACKGROUND")
    fbg:SetAllPoints()
    fbg:SetColorTexture(TH.bgDark[1], TH.bgDark[2], TH.bgDark[3], 1)
    crumb = foot:CreateFontString(nil, "OVERLAY")
    crumb:SetFont(FONT, 10, "")
    crumb:SetPoint("LEFT", 10, 0)
    crumb:SetTextColor(TH.textDim[1], TH.textDim[2], TH.textDim[3], 1)
    local toastHolder = CreateFrame("Frame", nil, foot)
    toastHolder:SetAllPoints()
    local toast = toastHolder:CreateFontString(nil, "OVERLAY")
    toast:SetFont(FONT_BOLD, 10, "")
    toast:SetPoint("CENTER", 20, 0)
    toast:Hide()
    K.SetToastHost(toast)
    local hint = foot:CreateFontString(nil, "OVERLAY")
    hint:SetFont(FONT, 10, "")
    hint:SetPoint("RIGHT", -24, 0)
    hint:SetTextColor(TH.textFaint[1], TH.textFaint[2], TH.textFaint[3], 1)
    hint:SetText(T("Alt : voir à travers", "Alt: see through"))

    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetFrameLevel(frame:GetFrameLevel() + 20)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    local widthAtGrab
    grip:SetScript("OnMouseDown", function(_, b)
        if b == "LeftButton" then
            widthAtGrab = frame:GetWidth()
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        local d = GuiDB()
        d.w = math.floor((frame:GetWidth() or DEF_W) + 0.5)
        d.h = math.floor((frame:GetHeight() or DEF_H) + 0.5)
        -- StartSizing re-anchors to TOPLEFT: keep the dock if there was one.
        if d.dock ~= "free" then ApplyDock() end
        -- Pages lay their rows out once, at the width they were built for:
        -- wrapped texts got taller in a narrower window and ran into the
        -- next row. A new width rebuilds the open page and forgets the
        -- cached ones, which rebuild when next opened.
        local nw = frame:GetWidth() or 0
        if widthAtGrab and math.abs(nw - widthAtGrab) > 2 then
            for k, entry in pairs(built) do
                if k ~= current then
                    Park(entry)
                    built[k] = nil
                end
            end
            C.RebuildCurrentPage()
        end
        widthAtGrab = nil
    end)

    RelayoutNav()
end

-- =====================================================================
-- PUBLIC API
-- =====================================================================
function C.Toggle()
    if not TomoModDB then
        print("|cffff0000TomoMod|r " .. ((L and L["msg_db_not_init"]) or "DB not initialized"))
        return
    end
    if not frame then CreateWindow() end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        if not current then C.SwitchCategory(GuiDB().lastPage or "home") end
    end
end

function C.Show()
    if not frame then CreateWindow() end
    if not frame:IsShown() then
        frame:Show()
        if not current then C.SwitchCategory(GuiDB().lastPage or "home") end
    end
end

function C.Hide()
    if frame and frame:IsShown() then frame:Hide() end
end

function C.OpenCategory(key)
    C.Show()
    if key then C.SwitchCategory(key) end
end

function C.OpenComfortPage(key) C.OpenCategory(key) end

-- Cooldown and Mythic+ open their Studio. The three Studios replaced by
-- pages send old callers (role guides, bookmarks) to the matching page.
local STUDIO_TO_PAGE = {
    astral = "uf_player", group = "party", resourcecast = "resources",
}
local ARG_TO_PAGE = {
    party = "party", raid = "raid", healer = "healer", nameplate = "nameplates",
    cast = "castbar", resources = "resources", bossframe = "uf_boss",
    player = "uf_player", target = "uf_target", targettarget = "uf_targettarget",
    focus = "uf_focus", pet = "uf_pet",
}
function C.OpenStudio(key, arg)
    if key == "cooldown" or key == "mythic" then
        return C.LaunchStudio(key, arg)
    end
    C.OpenCategory((arg and ARG_TO_PAGE[arg]) or STUDIO_TO_PAGE[key] or "home")
    return true
end
function TomoMod_OpenCooldownStudio() return C.OpenStudio("cooldown") end

function C.ApplyGUIScale()
    if not frame then return end
    frame:SetScale(GuiDB().scale or 1)
    FitToScreen()
end

function C.ResetGUISize()
    local d = GuiDB()
    d.w, d.h, d.scale, d.dock, d.pos = nil, nil, nil, nil, nil
    if frame then
        frame:SetScale(1)
        frame:SetSize(DEF_W, DEF_H)
        FitToScreen()
        ApplyDock()
    end
end

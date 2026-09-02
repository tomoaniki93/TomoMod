-- =====================================================================
-- BagCore.lua — TomoMod Bags V4
-- Fresh bag engine. Blizzard still owns item actions; TomoMod owns layout.
-- =====================================================================

TomoMod_BagSkin = TomoMod_BagSkin or {}
local Bags = TomoMod_BagSkin

Bags.VERSION = 1
Bags.Modules = Bags.Modules or {}
Bags.State = Bags.State or {
    initialized = false,
    visible = false,
    refreshPending = false,
    layoutPending = false,
}

-- Phase 1 keeps its strings self-contained so no legacy BagSkin locale file
-- is required. enUS is the fallback base; the five shipped locales override it.
if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["bags_v4_title"] = "Bags",
        ["bags_v4_pinned"] = "PINNED",
        ["bags_v4_recent"] = "RECENT",
        ["bags_v4_empty_pinned"] = "Middle-click an item",
        ["bags_v4_empty_recent"] = "No recent items",
        ["bags_v4_sidebar_click"] = "Left-click: find in bags",
        ["bags_v4_sidebar_unpin"] = "Middle-click: unpin",
        ["bags_v4_search"] = "Search bags...",
        ["bags_v4_sort_natural"] = "Bag order",
        ["bags_v4_sort_quality"] = "Quality",
        ["bags_v4_sort_name"] = "Name",
        ["bags_v4_sort_ilvl"] = "Item level",
        ["bags_v4_sort_tip"] = "Click to change visual sorting.",
        ["bags_v4_pin_hint"] = "Middle-click an item to pin it",
        ["bags_v4_gui_info"] = "Bags V4 uses one TomoMod window in Combined mode. Separate mode restores Blizzard's individual bag windows.",
        ["bags_v4_gui_mode"] = "Bag display",
        ["bags_v4_gui_combined"] = "Combined",
        ["bags_v4_gui_separate"] = "Separate",
        ["bags_v4_gui_appearance"] = "Appearance",
        ["bags_v4_gui_columns"] = "Columns",
        ["bags_v4_gui_spacing"] = "Slot spacing",
        ["bags_v4_gui_sidebar"] = "Pinned & Recent",
        ["bags_v4_gui_pinned_max"] = "Pinned items",
        ["bags_v4_gui_recent_max"] = "Recent items",
    })
    TomoMod_RegisterLocale("frFR", {
        ["bags_v4_title"] = "Sacs",
        ["bags_v4_pinned"] = "ÉPINGLÉS",
        ["bags_v4_recent"] = "RÉCENTS",
        ["bags_v4_empty_pinned"] = "Clic milieu sur un objet",
        ["bags_v4_empty_recent"] = "Aucun objet récent",
        ["bags_v4_sidebar_click"] = "Clic gauche : retrouver dans les sacs",
        ["bags_v4_sidebar_unpin"] = "Clic milieu : désépingler",
        ["bags_v4_search"] = "Rechercher dans les sacs...",
        ["bags_v4_sort_natural"] = "Ordre des sacs",
        ["bags_v4_sort_quality"] = "Qualité",
        ["bags_v4_sort_name"] = "Nom",
        ["bags_v4_sort_ilvl"] = "Niveau d'objet",
        ["bags_v4_sort_tip"] = "Clique pour changer le tri visuel.",
        ["bags_v4_pin_hint"] = "Clic milieu sur un objet pour l'épingler",
        ["bags_v4_gui_info"] = "En mode Combinés, Bags V4 utilise une seule fenêtre TomoMod. Le mode Séparés restaure les fenêtres de sacs Blizzard individuelles.",
        ["bags_v4_gui_mode"] = "Affichage des sacs",
        ["bags_v4_gui_combined"] = "Combinés",
        ["bags_v4_gui_separate"] = "Séparés",
        ["bags_v4_gui_appearance"] = "Apparence",
        ["bags_v4_gui_columns"] = "Colonnes",
        ["bags_v4_gui_spacing"] = "Espacement des cases",
        ["bags_v4_gui_sidebar"] = "Épinglés & Récents",
        ["bags_v4_gui_pinned_max"] = "Objets épinglés",
        ["bags_v4_gui_recent_max"] = "Objets récents",
    })
    TomoMod_RegisterLocale("deDE", {
        ["bags_v4_title"] = "Taschen", ["bags_v4_pinned"] = "ANGEHEFTET", ["bags_v4_recent"] = "NEU",
        ["bags_v4_empty_pinned"] = "Mittelklick auf einen Gegenstand", ["bags_v4_empty_recent"] = "Keine neuen Gegenstände",
        ["bags_v4_sidebar_click"] = "Linksklick: in Taschen finden", ["bags_v4_sidebar_unpin"] = "Mittelklick: lösen",
        ["bags_v4_search"] = "Taschen durchsuchen...", ["bags_v4_sort_natural"] = "Taschenreihenfolge",
        ["bags_v4_sort_quality"] = "Qualität", ["bags_v4_sort_name"] = "Name", ["bags_v4_sort_ilvl"] = "Gegenstandsstufe",
        ["bags_v4_sort_tip"] = "Klicken, um die visuelle Sortierung zu ändern.", ["bags_v4_pin_hint"] = "Mittelklick zum Anheften",
        ["bags_v4_gui_info"] = "Kombiniert nutzt ein TomoMod-Fenster; Getrennt stellt die einzelnen Blizzard-Taschen wieder her.",
        ["bags_v4_gui_mode"] = "Taschenanzeige", ["bags_v4_gui_combined"] = "Kombiniert", ["bags_v4_gui_separate"] = "Getrennt",
        ["bags_v4_gui_appearance"] = "Aussehen", ["bags_v4_gui_columns"] = "Spalten", ["bags_v4_gui_spacing"] = "Abstand",
        ["bags_v4_gui_sidebar"] = "Angeheftet & Neu", ["bags_v4_gui_pinned_max"] = "Angeheftete Gegenstände", ["bags_v4_gui_recent_max"] = "Neue Gegenstände",
    })
    TomoMod_RegisterLocale("esES", {
        ["bags_v4_title"] = "Bolsas", ["bags_v4_pinned"] = "FIJADOS", ["bags_v4_recent"] = "RECIENTES",
        ["bags_v4_empty_pinned"] = "Clic central en un objeto", ["bags_v4_empty_recent"] = "Sin objetos recientes",
        ["bags_v4_sidebar_click"] = "Clic izquierdo: buscar en bolsas", ["bags_v4_sidebar_unpin"] = "Clic central: desfijar",
        ["bags_v4_search"] = "Buscar en las bolsas...", ["bags_v4_sort_natural"] = "Orden de bolsas",
        ["bags_v4_sort_quality"] = "Calidad", ["bags_v4_sort_name"] = "Nombre", ["bags_v4_sort_ilvl"] = "Nivel de objeto",
        ["bags_v4_sort_tip"] = "Haz clic para cambiar el orden visual.", ["bags_v4_pin_hint"] = "Clic central para fijar un objeto",
        ["bags_v4_gui_info"] = "Combinadas usa una sola ventana TomoMod; Separadas restaura las bolsas individuales de Blizzard.",
        ["bags_v4_gui_mode"] = "Vista de bolsas", ["bags_v4_gui_combined"] = "Combinadas", ["bags_v4_gui_separate"] = "Separadas",
        ["bags_v4_gui_appearance"] = "Apariencia", ["bags_v4_gui_columns"] = "Columnas", ["bags_v4_gui_spacing"] = "Espaciado",
        ["bags_v4_gui_sidebar"] = "Fijados y Recientes", ["bags_v4_gui_pinned_max"] = "Objetos fijados", ["bags_v4_gui_recent_max"] = "Objetos recientes",
    })
    TomoMod_RegisterLocale("itIT", {
        ["bags_v4_title"] = "Borse", ["bags_v4_pinned"] = "FISSATI", ["bags_v4_recent"] = "RECENTI",
        ["bags_v4_empty_pinned"] = "Clic centrale su un oggetto", ["bags_v4_empty_recent"] = "Nessun oggetto recente",
        ["bags_v4_sidebar_click"] = "Clic sinistro: trova nelle borse", ["bags_v4_sidebar_unpin"] = "Clic centrale: rimuovi",
        ["bags_v4_search"] = "Cerca nelle borse...", ["bags_v4_sort_natural"] = "Ordine borse",
        ["bags_v4_sort_quality"] = "Qualità", ["bags_v4_sort_name"] = "Nome", ["bags_v4_sort_ilvl"] = "Livello oggetto",
        ["bags_v4_sort_tip"] = "Clicca per cambiare l'ordinamento visivo.", ["bags_v4_pin_hint"] = "Clic centrale per fissare un oggetto",
        ["bags_v4_gui_info"] = "Combinato usa una sola finestra TomoMod; Separato ripristina le borse Blizzard individuali.",
        ["bags_v4_gui_mode"] = "Visualizzazione borse", ["bags_v4_gui_combined"] = "Combinato", ["bags_v4_gui_separate"] = "Separato",
        ["bags_v4_gui_appearance"] = "Aspetto", ["bags_v4_gui_columns"] = "Colonne", ["bags_v4_gui_spacing"] = "Spaziatura",
        ["bags_v4_gui_sidebar"] = "Fissati e Recenti", ["bags_v4_gui_pinned_max"] = "Oggetti fissati", ["bags_v4_gui_recent_max"] = "Oggetti recenti",
    })
    TomoMod_RegisterLocale("ptBR", {
        ["bags_v4_title"] = "Bolsas", ["bags_v4_pinned"] = "FIXADOS", ["bags_v4_recent"] = "RECENTES",
        ["bags_v4_empty_pinned"] = "Clique do meio em um item", ["bags_v4_empty_recent"] = "Nenhum item recente",
        ["bags_v4_sidebar_click"] = "Clique esquerdo: localizar nas bolsas", ["bags_v4_sidebar_unpin"] = "Clique do meio: desafixar",
        ["bags_v4_search"] = "Buscar nas bolsas...", ["bags_v4_sort_natural"] = "Ordem das bolsas",
        ["bags_v4_sort_quality"] = "Qualidade", ["bags_v4_sort_name"] = "Nome", ["bags_v4_sort_ilvl"] = "Nível do item",
        ["bags_v4_sort_tip"] = "Clique para mudar a ordenação visual.", ["bags_v4_pin_hint"] = "Clique do meio para fixar um item",
        ["bags_v4_gui_info"] = "Combinadas usa uma única janela TomoMod; Separadas restaura as bolsas individuais da Blizzard.",
        ["bags_v4_gui_mode"] = "Exibição das bolsas", ["bags_v4_gui_combined"] = "Combinadas", ["bags_v4_gui_separate"] = "Separadas",
        ["bags_v4_gui_appearance"] = "Aparência", ["bags_v4_gui_columns"] = "Colunas", ["bags_v4_gui_spacing"] = "Espaçamento",
        ["bags_v4_gui_sidebar"] = "Fixados e Recentes", ["bags_v4_gui_pinned_max"] = "Itens fixados", ["bags_v4_gui_recent_max"] = "Itens recentes",
    })
end

local DEFAULTS = {
    enabled = false,
    appearance = {
        alpha = 0.96,
        scale = 1.0,
    },
    layout = {
        mode = "combined", -- combined | separate
        columns = 12,
        slotSize = 38,
        spacing = 4,
        sidebarWidth = 94,
        padding = 10,
    },
    search = {
        enabled = true,
    },
    sorting = {
        mode = "natural", -- natural | quality | name | ilvl
    },
    slots = {
        qualityBorders = true,
        itemLevel = true,
        showEmpty = true,
    },
    sidebar = {
        pinnedMax = 8,
        recentMax = 8,
    },
    pinned = {
        items = {},
        order = {},
    },
    position = {
        point = "BOTTOMRIGHT",
        relativePoint = "BOTTOMRIGHT",
        x = -42,
        y = 86,
    },
    _legacyMigrated = false,
    _legacyEnabledMirror = nil,
}

local INIT_ORDER = {
    "Data",
    "Layout",
    "Slots",
    "Sidebar",
    "Search",
    "Bridge",
}

local function DeepFill(dst, src)
    if type(dst) ~= "table" then dst = {} end
    for key, value in pairs(src) do
        if type(value) == "table" then
            if type(dst[key]) ~= "table" then dst[key] = {} end
            DeepFill(dst[key], value)
        elseif dst[key] == nil then
            dst[key] = value
        end
    end
    return dst
end

local function Clamp(v, lo, hi, fallback)
    v = tonumber(v)
    if not v then return fallback end
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function LegacyDB()
    return TomoModDB and TomoModDB.bagSkin
end

local function SyncLegacyVisualSettings(db)
    local legacy = LegacyDB()
    if type(legacy) ~= "table" then return end

    -- Temporary compatibility bridge for the existing Bags GUI. These
    -- settings are copied into the clean V4 tree and can disappear once the
    -- dedicated V4 panel lands.
    if legacy.opacity ~= nil then
        db.appearance.alpha = Clamp(legacy.opacity / 100, 0.25, 1.0, db.appearance.alpha)
    end
    if legacy.scale ~= nil then
        db.appearance.scale = Clamp(legacy.scale / 100, 0.70, 1.40, db.appearance.scale)
    end
    if legacy.slotSize ~= nil then
        db.layout.slotSize = math.floor(Clamp(legacy.slotSize, 28, 52, db.layout.slotSize) + 0.5)
    end
    local sx = tonumber(legacy.slotSpacingX)
    local sy = tonumber(legacy.slotSpacingY)
    if sx or sy then
        db.layout.spacing = math.floor(Clamp(math.max(sx or 0, sy or 0), 0, 10, db.layout.spacing) + 0.5)
    end
    if legacy.width and db.layout.slotSize then
        local usable = math.max(280, tonumber(legacy.width) or 520) - db.layout.sidebarWidth - 30
        local step = db.layout.slotSize + db.layout.spacing
        db.layout.columns = math.floor(Clamp(math.floor((usable + db.layout.spacing) / math.max(step, 1)), 8, 16, db.layout.columns) + 0.5)
    end

    if legacy.sortMode == "quality" or legacy.sortMode == "name" or legacy.sortMode == "ilvl" then
        db.sorting.mode = legacy.sortMode
    elseif legacy.sortMode == "none" or legacy.sortMode == "recent" or legacy.sortMode == "type" then
        db.sorting.mode = "natural"
    end

    if legacy.showQualityBorders ~= nil then db.slots.qualityBorders = legacy.showQualityBorders and true or false end
    if legacy.showItemLevel ~= nil then db.slots.itemLevel = legacy.showItemLevel and true or false end
    if legacy.showEmptySlots ~= nil then db.slots.showEmpty = legacy.showEmptySlots and true or false end
    if legacy.showSearchBar ~= nil then db.search.enabled = legacy.showSearchBar and true or false end
end

local function EnsureDB()
    TomoModDB = TomoModDB or {}
    if type(TomoModDB.bagsV4) ~= "table" then TomoModDB.bagsV4 = {} end
    local db = DeepFill(TomoModDB.bagsV4, DEFAULTS)
    local legacy = LegacyDB()

    if not db._legacyMigrated then
        if type(legacy) == "table" then
            db.enabled = legacy.enabled and true or false
            SyncLegacyVisualSettings(db)
            if legacy.layoutMode == "separateBags" then
                db.layout.mode = "separate"
            elseif legacy.layoutMode == "combined" then
                db.layout.mode = "combined"
            end
            if type(legacy.position) == "table" then
                db.position.point = legacy.position.anchor or db.position.point
                db.position.relativePoint = legacy.position.relTo or db.position.relativePoint
                db.position.x = tonumber(legacy.position.x) or db.position.x
                db.position.y = tonumber(legacy.position.y) or db.position.y
            end
        end
        db._legacyMigrated = true
    end

    -- Presets / Installer / Dashboard still write the legacy boolean during
    -- Phase 1. A persisted mirror lets us distinguish an external change from
    -- the value last written by Bags V4 itself.
    if type(legacy) == "table" and db._legacyEnabledMirror == nil then
        db._legacyEnabledMirror = legacy.enabled and true or false
    end

    return db
end

function Bags.RegisterModule(name, module)
    Bags.Modules[name] = module
end

function Bags.GetDB()
    return EnsureDB()
end

function Bags.IsEnabled()
    return EnsureDB().enabled ~= false
end

function Bags.IsVisible()
    local db = EnsureDB()
    if db.layout.mode == "separate" then
        local bridge = Bags.Modules.Bridge
        return bridge and bridge.AnyNativeShown and bridge:AnyNativeShown() or false
    end
    local layout = Bags.Modules.Layout
    return layout and layout.frame and layout.frame:IsShown() or false
end

function Bags.RequestRefresh(layoutToo)
    if layoutToo then Bags.State.layoutPending = true end
    if Bags.State.refreshPending then return end
    Bags.State.refreshPending = true
    C_Timer.After(0, function()
        Bags.State.refreshPending = false
        if not Bags.State.initialized then return end
        local slots = Bags.Modules.Slots
        if slots and slots.Refresh then
            slots:Refresh(Bags.State.layoutPending)
        end
        Bags.State.layoutPending = false
        local sidebar = Bags.Modules.Sidebar
        if sidebar and sidebar.Refresh then sidebar:Refresh() end
        local layout = Bags.Modules.Layout
        if layout and layout.RefreshHeader then layout:RefreshHeader() end
    end)
end

function Bags.Show()
    if not Bags.IsEnabled() then return end
    local db = EnsureDB()
    if db.layout.mode == "separate" then
        local bridge = Bags.Modules.Bridge
        if bridge and bridge.ShowSeparate then bridge:ShowSeparate() end
        return
    end
    local layout = Bags.Modules.Layout
    if not layout or not layout.frame then return end
    layout.frame:Show()
    Bags.State.visible = true
    Bags.RequestRefresh(true)
end

function Bags.Hide(fromBridge)
    local layout = Bags.Modules.Layout
    if layout and layout.frame then layout.frame:Hide() end
    Bags.State.visible = false
    if not fromBridge then
        local bridge = Bags.Modules.Bridge
        if bridge and bridge.CloseNativeState then bridge:CloseNativeState() end
    end
end

function Bags.Toggle()
    local db = EnsureDB()
    if db.layout.mode == "separate" then
        local bridge = Bags.Modules.Bridge
        if bridge and bridge.ToggleSeparate then bridge:ToggleSeparate() end
        return
    end
    if Bags.IsVisible() then Bags.Hide() else Bags.Show() end
end

function Bags.SetDisplayMode(mode)
    local db = EnsureDB()
    mode = mode == "separate" and "separate" or "combined"
    if db.layout.mode == mode then return end
    db.layout.mode = mode

    local legacy = LegacyDB()
    if type(legacy) == "table" then
        legacy.layoutMode = mode == "separate" and "separateBags" or "combined"
    end

    local bridge = Bags.Modules.Bridge
    if bridge and bridge.ApplyMode then bridge:ApplyMode(mode) end
    Bags.ApplySettings()
end

function Bags.SetEnabled(value)
    local db = EnsureDB()
    local enabled = value and true or false
    db.enabled = enabled

    local legacy = LegacyDB()
    if type(legacy) == "table" then
        legacy.enabled = enabled
        db._legacyEnabledMirror = enabled
    end

    local bridge = Bags.Modules.Bridge
    if bridge and bridge.ApplyEnabled then bridge:ApplyEnabled(enabled) end
    if not enabled then Bags.Hide() end
    Bags.ApplySettings()
end

function Bags.ApplySettings()
    local db = EnsureDB()

    local layout = Bags.Modules.Layout
    if layout and layout.ApplySettings then layout:ApplySettings() end
    local slots = Bags.Modules.Slots
    if slots and slots.ApplySettings then slots:ApplySettings() end
    local search = Bags.Modules.Search
    if search and search.ApplySettings then search:ApplySettings() end
    Bags.RequestRefresh(true)
end

function Bags.Initialize()
    if Bags.State.initialized then return end
    EnsureDB()

    for _, name in ipairs(INIT_ORDER) do
        local module = Bags.Modules[name]
        if module and module.Initialize then
            local handler = CallErrorHandler or geterrorhandler()
            local ok, err = xpcall(function() module:Initialize() end, handler)
            if not ok then
                geterrorhandler()("TomoMod Bags V4 [" .. name .. "]: " .. tostring(err))
            end
        end
    end

    Bags.State.initialized = true
    Bags.ApplySettings()

    if TomoMod_RegisterModule then
        TomoMod_RegisterModule("bagSkin", Bags)
    end
end

_G.TomoMod_BagSkin = Bags

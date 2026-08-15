-- =====================================================
-- Config/Panels/ActionBars.lua v5.1.0
--
-- Rebuilt in lot P5 against the schema the ported Tui module reads:
-- TomoModDB.actionBars.global (shared), .bars[key] (per-bar override) and
-- .fade. A per-bar key set to nil means "inherit the global one", which is
-- exactly how GetEffectiveSettings merges them, so the per-bar tab only
-- exposes what genuinely differs per bar (layout and position).
--
-- Every control calls Refresh() rather than reaching into the module: the
-- ported code exposes TUI_RefreshActionBars as its single re-apply entry.
-- =====================================================

local L = TomoMod_L
local W = TomoMod_Widgets

local function DB()
    local db = TomoModDB and TomoModDB.actionBars
    if type(db) ~= "table" then return nil end
    if type(db.global) ~= "table" then db.global = {} end
    if type(db.bars) ~= "table" then db.bars = {} end
    if type(db.fade) ~= "table" then db.fade = {} end
    return db
end

local function Refresh()
    if type(_G.TUI_RefreshActionBars) == "function" then _G.TUI_RefreshActionBars() end
end

local function RefreshFade()
    if type(_G.TUI_RefreshActionBarFade) == "function" then _G.TUI_RefreshActionBarFade() end
end

local function G(key, fallback)
    local db = DB()
    local v = db and db.global and db.global[key]
    if v == nil then return fallback end
    return v
end

local function SetG(key, value)
    local db = DB()
    if not db then return end
    db.global[key] = value
    Refresh()
end

local function Col(key, fallback)
    local c = G(key, nil)
    if type(c) ~= "table" then c = fallback end
    return { r = c[1] or 1, g = c[2] or 1, b = c[3] or 1 }
end

local function SetCol(key, r, g, b)
    local db = DB()
    if not db then return end
    local c = db.global[key]
    if type(c) ~= "table" then c = { 1, 1, 1, 1 }; db.global[key] = c end
    c[1], c[2], c[3] = r, g, b
    Refresh()
end

local ANCHORS = {
    { value = "TOPLEFT",     text = "Haut gauche" },
    { value = "TOP",         text = "Haut" },
    { value = "TOPRIGHT",    text = "Haut droite" },
    { value = "LEFT",        text = "Gauche" },
    { value = "CENTER",      text = "Centre" },
    { value = "RIGHT",       text = "Droite" },
    { value = "BOTTOMLEFT",  text = "Bas gauche" },
    { value = "BOTTOM",      text = "Bas" },
    { value = "BOTTOMRIGHT", text = "Bas droite" },
}

local FLASH_MODES = {
    { value = "blizzard", text = "Blizzard" },
    { value = "qui",      text = "TomoMod" },
    { value = false,      text = "Aucune" },
}

local ORIENTATIONS = {
    { value = "horizontal", text = "Horizontale" },
    { value = "vertical",   text = "Verticale" },
}

local function IconSkinList()
    local ns = TomoMod_TuiNS
    local out = {}
    if ns and ns.IconSkin and ns.IconSkin.GetSkinList then
        for _, n in ipairs(ns.IconSkin.GetSkinList()) do
            out[#out + 1] = { value = n, text = n }
        end
    end
    if #out == 0 then out[1] = { value = "Default", text = "Default" } end
    return out
end

local function GlowSourceList()
    local ns = TomoMod_TuiNS
    local out = {}
    if ns and ns.IconGlow and ns.IconGlow.GetSourceList then
        for _, n in ipairs(ns.IconGlow.GetSourceList()) do
            out[#out + 1] = { value = n, text = n }
        end
    end
    if #out == 0 then out[1] = { value = "Off", text = "Off" } end
    return out
end

-- Four text layers share the same shape, so they share one builder rather
-- than four near-identical blocks.
local TEXT_LAYERS = {
    { toggle = "showKeybinds",    prefix = "keybind",      label = "opt_abt_keybinds" },
    { toggle = "showMacroNames",  prefix = "macroName",    label = "opt_abt_macronames" },
    { toggle = "showCounts",      prefix = "count",        label = "opt_abt_counts" },
    { toggle = "showCooldownText", prefix = "cooldownText", label = "opt_abt_cooldowntext" },
}

-- =====================================================================
-- TAB 1 -- GENERAL
-- =====================================================================
local function BuildGeneralTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10
    if not DB() then
        local _, ny = W.CreateInfoText(c, L["info_ab_nodb"], y)
        c:SetHeight(120)
        return scroll
    end

    local _, ny = W.CreateSectionHeader(c, L["section_ab_general"], y) y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_ab_skin_enabled"], G("skinEnabled", true), y,
        function(v) SetG("skinEnabled", v) end) y = ny
    local _, ny = W.CreateSlider(c, L["opt_ab_icon_size"], G("iconSize", 36), 16, 64, 1, y,
        function(v) SetG("iconSize", v) end) y = ny
    local _, ny = W.CreateSlider(c, L["opt_ab_icon_zoom"], G("iconZoom", 0.05), 0, 0.2, 0.01, y,
        function(v) SetG("iconZoom", v) end) y = ny
    local _, ny = W.CreateSlider(c, L["opt_ab_spacing"], G("buttonSpacing", 0), 0, 20, 1, y,
        function(v) SetG("buttonSpacing", v) end) y = ny
    local _, ny = W.CreateDropdown(c, L["opt_ab_icon_skin"], IconSkinList(), G("iconSkin", "Default"), y,
        function(v) SetG("iconSkin", v) end) y = ny

    local _, ny = W.CreateSectionHeader(c, L["section_ab_chrome"], y) y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_ab_borders"], G("showBorders", true), y,
        function(v) SetG("showBorders", v) end) y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_ab_backdrop"], G("showBackdrop", true), y,
        function(v) SetG("showBackdrop", v) end) y = ny
    local _, ny = W.CreateSlider(c, L["opt_ab_backdrop_alpha"], G("backdropAlpha", 0.2), 0, 1, 0.05, y,
        function(v) SetG("backdropAlpha", v) end) y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_ab_gloss"], G("showGloss", true), y,
        function(v) SetG("showGloss", v) end) y = ny
    local _, ny = W.CreateSlider(c, L["opt_ab_gloss_alpha"], G("glossAlpha", 0.3), 0, 1, 0.05, y,
        function(v) SetG("glossAlpha", v) end) y = ny

    local _, ny = W.CreateSectionHeader(c, L["section_ab_behaviour"], y) y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_ab_hide_empty"], G("hideEmptySlots", false), y,
        function(v) SetG("hideEmptySlots", v) end) y = ny
    local _, ny = W.CreateDropdown(c, L["opt_ab_flash"], FLASH_MODES, G("showFlash", "blizzard"), y,
        function(v) SetG("showFlash", v) end) y = ny
    local _, ny = W.CreateInfoText(c, L["info_ab_flash"], y) y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_ab_lock"], G("lockButtons", false), y,
        function(v) SetG("lockButtons", v) end) y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_ab_tooltips"], G("showTooltips", true), y,
        function(v) SetG("showTooltips", v) end) y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_ab_keydown"], G("useOnKeyDown", false), y,
        function(v)
            SetG("useOnKeyDown", v)
            if type(_G.TUI_ApplyUseOnKeyDown) == "function" then _G.TUI_ApplyUseOnKeyDown() end
        end) y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_ab_assisted"], G("assistedHighlight", false), y,
        function(v) SetG("assistedHighlight", v) end) y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_ab_masque"], G("externalSkinning", false), y,
        function(v) SetG("externalSkinning", v) end) y = ny
    local _, ny = W.CreateInfoText(c, L["info_ab_masque"], y) y = ny

    -- The totem bar is a separate module with its own DB table, so it does not
    -- go through G/SetG (which write into actionBars.global).
    local _, ny = W.CreateSectionHeader(c, L["section_ab_totem"], y) y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_ab_totem_enabled"],
        (TomoModDB and TomoModDB.totemBar and TomoModDB.totemBar.enabled) and true or false, y,
        function(v)
            if not TomoModDB then return end
            if type(TomoModDB.totemBar) ~= "table" then TomoModDB.totemBar = {} end
            TomoModDB.totemBar.enabled = v
            if type(_G.TUI_RefreshTotemBar) == "function" then _G.TUI_RefreshTotemBar() end
        end) y = ny

    local _, ny = W.CreateInfoText(c, L["info_ab_totem"], y) y = ny

    local _, ny = W.CreateButton(c, L["btn_abs_layout"], 260, y, function()
        if TomoMod_Movers and TomoMod_Movers.Toggle then TomoMod_Movers.Toggle() end
    end) y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================================================
-- TAB 2 -- TEXTS
-- =====================================================================
local function BuildTextsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10
    if not DB() then
        W.CreateInfoText(c, L["info_ab_nodb"], y)
        c:SetHeight(120)
        return scroll
    end

    for _, layer in ipairs(TEXT_LAYERS) do
        local p = layer.prefix
        local _, ny = W.CreateSectionHeader(c, L[layer.label], y) y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_abt_show"], G(layer.toggle, true), y,
            function(v) SetG(layer.toggle, v) end) y = ny
        local _, ny = W.CreateSlider(c, L["opt_abt_size"], G(p .. "FontSize", 12), 6, 28, 1, y,
            function(v) SetG(p .. "FontSize", v) end) y = ny
        local _, ny = W.CreateDropdown(c, L["opt_abt_anchor"], ANCHORS, G(p .. "Anchor", "CENTER"), y,
            function(v) SetG(p .. "Anchor", v) end) y = ny
        local _, ny = W.CreateSlider(c, L["opt_abt_offx"], G(p .. "OffsetX", 0), -20, 20, 1, y,
            function(v) SetG(p .. "OffsetX", v) end) y = ny
        local _, ny = W.CreateSlider(c, L["opt_abt_offy"], G(p .. "OffsetY", 0), -20, 20, 1, y,
            function(v) SetG(p .. "OffsetY", v) end) y = ny
        local _, ny = W.CreateColorPicker(c, L["opt_abt_color"], Col(p .. "Color", { 1, 1, 1, 1 }), y,
            function(r, g, b) SetCol(p .. "Color", r, g, b) end) y = ny
    end

    local _, ny = W.CreateCheckbox(c, L["opt_ab_hide_empty_keybinds"], G("hideEmptyKeybinds", false), y,
        function(v) SetG("hideEmptyKeybinds", v) end) y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================================================
-- TAB 3 -- INDICATORS
-- =====================================================================
local function BuildIndicatorsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10
    if not DB() then
        W.CreateInfoText(c, L["info_ab_nodb"], y)
        c:SetHeight(120)
        return scroll
    end

    local _, ny = W.CreateSectionHeader(c, L["section_ab_states"], y) y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_ab_range"], G("rangeIndicator", true), y,
        function(v) SetG("rangeIndicator", v) end) y = ny
    local _, ny = W.CreateColorPicker(c, L["opt_ab_range_color"], Col("rangeColor", { 0.8, 0.1, 0.1, 1 }), y,
        function(r, g, b) SetCol("rangeColor", r, g, b) end) y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_ab_usability"], G("usabilityIndicator", true), y,
        function(v) SetG("usabilityIndicator", v) end) y = ny
    local _, ny = W.CreateColorPicker(c, L["opt_ab_usability_color"], Col("usabilityColor", { 0.4, 0.4, 0.4, 1 }), y,
        function(r, g, b) SetCol("usabilityColor", r, g, b) end) y = ny
    local _, ny = W.CreateColorPicker(c, L["opt_ab_mana_color"], Col("manaColor", { 0.5, 0.5, 1, 1 }), y,
        function(r, g, b) SetCol("manaColor", r, g, b) end) y = ny

    local _, ny = W.CreateSectionHeader(c, L["section_ab_glow"], y) y = ny
    local _, ny = W.CreateDropdown(c, L["opt_ab_glow_source"], GlowSourceList(), G("glowSource", "TUI"), y,
        function(v) SetG("glowSource", v) end) y = ny
    local _, ny = W.CreateColorPicker(c, L["opt_ab_glow_color"], Col("glowColor", { 0.2, 0.82, 0.6, 1 }), y,
        function(r, g, b) SetCol("glowColor", r, g, b) end) y = ny
    local _, ny = W.CreateSlider(c, L["opt_ab_glow_lines"], G("glowLines", 8), 2, 20, 1, y,
        function(v) SetG("glowLines", v) end) y = ny
    local _, ny = W.CreateSlider(c, L["opt_ab_glow_thickness"], G("glowThickness", 2), 1, 6, 1, y,
        function(v) SetG("glowThickness", v) end) y = ny
    local _, ny = W.CreateSlider(c, L["opt_ab_glow_freq"], G("glowFrequency", 0.25), 0.05, 1, 0.05, y,
        function(v) SetG("glowFrequency", v) end) y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================================================
-- TAB 4 -- FADE
-- =====================================================================
local function BuildFadeTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10
    local db = DB()
    if not db then
        W.CreateInfoText(c, L["info_ab_nodb"], y)
        c:SetHeight(120)
        return scroll
    end
    local f = db.fade

    local function SetF(key, value)
        f[key] = value
        RefreshFade()
    end

    local _, ny = W.CreateSectionHeader(c, L["section_ab_fade"], y) y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_abf_enabled"], f.enabled == true, y,
        function(v) SetF("enabled", v) end) y = ny
    local _, ny = W.CreateSlider(c, L["opt_abf_out_alpha"], f.fadeOutAlpha or 0, 0, 1, 0.05, y,
        function(v) SetF("fadeOutAlpha", v) end) y = ny
    local _, ny = W.CreateSlider(c, L["opt_abf_delay"], f.fadeOutDelay or 0.5, 0, 5, 0.1, y,
        function(v) SetF("fadeOutDelay", v) end) y = ny
    local _, ny = W.CreateSlider(c, L["opt_abf_in"], f.fadeInDuration or 0.2, 0, 2, 0.05, y,
        function(v) SetF("fadeInDuration", v) end) y = ny
    local _, ny = W.CreateSlider(c, L["opt_abf_out"], f.fadeOutDuration or 0.3, 0, 2, 0.05, y,
        function(v) SetF("fadeOutDuration", v) end) y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_abf_combat"], f.alwaysShowInCombat == true, y,
        function(v) SetF("alwaysShowInCombat", v) end) y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_abf_link"], f.linkBars1to8 ~= false, y,
        function(v) SetF("linkBars1to8", v) end) y = ny

    local fadeBarKeys = {
        { key = "bar1", label = "Barre 1" },
        { key = "bar2", label = "Barre 2" },
        { key = "bar3", label = "Barre 3" },
        { key = "bar4", label = "Barre 4" },
        { key = "bar5", label = "Barre 5" },
        { key = "bar6", label = "Barre 6" },
        { key = "bar7", label = "Barre 7" },
        { key = "bar8", label = "Barre 8" },
        { key = "pet", label = "Familier" },
        { key = "stance", label = "Postures" },
        { key = "microbar", label = "Micro menu" },
        { key = "bags", label = "Barre de sac" },
    }

    local _, ny = W.CreateSectionHeader(c, "Barres ciblées", y) y = ny
    for _, def in ipairs(fadeBarKeys) do
        local bar = db.bars[def.key]
        if type(bar) ~= "table" then bar = {}; db.bars[def.key] = bar end
        local checked = bar.fadeEnabled ~= false
        local _, ny2 = W.CreateCheckbox(c, def.label, checked, y,
            function(v)
                bar.fadeEnabled = v
                RefreshFade()
            end)
        y = ny2
    end

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================================================
-- TAB 5 -- PER BAR
-- =====================================================================
local BAR_KEYS = {
    { key = "bar1", label = "Barre 1" },
    { key = "bar2", label = "Barre 2" },
    { key = "bar3", label = "Barre 3" },
    { key = "bar4", label = "Barre 4" },
    { key = "bar5", label = "Barre 5" },
    { key = "bar6", label = "Barre 6" },
    { key = "bar7", label = "Barre 7" },
    { key = "bar8", label = "Barre 8" },
    { key = "pet", label = "Familier" },
    { key = "stance", label = "Postures" },
}

local function BuildBarsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10
    local db = DB()
    if not db then
        W.CreateInfoText(c, L["info_ab_nodb"], y)
        c:SetHeight(120)
        return scroll
    end

    for _, def in ipairs(BAR_KEYS) do
        local bar = db.bars[def.key]
        if type(bar) ~= "table" then bar = {}; db.bars[def.key] = bar end
        if type(bar.ownedLayout) ~= "table" then bar.ownedLayout = {} end
        local lay = bar.ownedLayout

        local function SetL(key, value)
            lay[key] = value
            Refresh()
        end

        local _, ny = W.CreateSectionHeader(c, def.label, y) y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_bar_enabled"], bar.enabled ~= false, y,
            function(v) bar.enabled = v; Refresh() end) y = ny

        -- Pet and stance go through the same LayoutNativeButtons path as the
        -- eight action bars, so they take the same layout keys. Only the
        -- ceiling differs: ten slots instead of twelve. Stance additionally
        -- clamps iconCount to the number of forms the class actually has, so
        -- setting it high is harmless.
        local maxButtons = (def.key == "pet" or def.key == "stance") and 10 or 12

        local _, ny = W.CreateDropdown(c, L["opt_bar_orientation"], ORIENTATIONS,
            lay.orientation or "horizontal", y, function(v) SetL("orientation", v) end) y = ny
        local _, ny = W.CreateSlider(c, L["opt_bar_buttons"], lay.iconCount or maxButtons,
            1, maxButtons, 1, y, function(v) SetL("iconCount", v) end) y = ny
        local _, ny = W.CreateSlider(c, L["opt_bar_columns"], lay.columns or maxButtons,
            1, maxButtons, 1, y, function(v) SetL("columns", v) end) y = ny

        local _, ny = W.CreateSlider(c, L["opt_bar_size"], lay.buttonSize or 30, 16, 64, 1, y,
            function(v) SetL("buttonSize", v) end) y = ny
        local _, ny = W.CreateSlider(c, L["opt_bar_spacing"], lay.buttonSpacing or 0, 0, 20, 1, y,
            function(v) SetL("buttonSpacing", v) end) y = ny
        local _, ny = W.CreateCheckbox(c, L["opt_bar_grow_up"], lay.growUp == true, y,
            function(v) SetL("growUp", v) end) y = ny
        local _, ny = W.CreateCheckbox(c, L["opt_bar_grow_left"], lay.growLeft == true, y,
            function(v) SetL("growLeft", v) end) y = ny

        local _, ny = W.CreateSeparator(c, y) y = ny
    end

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================================================
-- MAIN PANEL
-- =====================================================================
function TomoMod_ConfigPanel_ActionBars(parent)
    return W.CreateTabPanel(parent, {
        { key = "general",    label = L["tab_ab_general"],    builder = BuildGeneralTab },
        { key = "texts",      label = L["tab_ab_texts"],      builder = BuildTextsTab },
        { key = "indicators", label = L["tab_ab_indicators"], builder = BuildIndicatorsTab },
        { key = "fade",       label = L["tab_ab_fade"],       builder = BuildFadeTab },
        { key = "bars",       label = L["tab_abs_bars"],      builder = BuildBarsTab },
    })
end

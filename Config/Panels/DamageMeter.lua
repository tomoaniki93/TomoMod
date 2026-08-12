-- Panels/DamageMeter.lua
--
-- The meter's settings, inside TomoMod's own config.
--
-- Nothing here knows how to apply a setting. Every control writes through
-- the module's ApplySetting, which owns the "what to refresh when this
-- changes" recipes -- the standalone options window writes through the
-- same one, so a setting behaves identically wherever it is changed.
--
-- Labels come from the module's own locale table, which already carries
-- these strings in nine languages.

local W = TomoMod_Widgets

local function DM()
    return _G.TomoMod_DamageMeterBridge
end

local function L(key, fallback)
    local b = DM()
    if b and b.L then return b.L(key, fallback) end
    return fallback or key
end

local function Get(key) local b = DM(); return b and b.Get and b.Get(key) end
local function Set(key, v) local b = DM(); if b and b.Set then b.Set(key, v) end end

-- The meter's list helpers return { value = ..., label = ... }, which is
-- the shape its own widget library reads. TomoMod's dropdown reads
-- `text`, so an unconverted list renders the right number of rows with
-- nothing written on them -- present, but blank.
--
-- Converting here rather than changing the helpers keeps the standalone
-- options window working off the same functions.
local function ToDropdownOptions(list)
    local out = {}
    for _, entry in ipairs(list or {}) do
        out[#out + 1] = {
            value = entry.value,
            text  = entry.text or entry.label or tostring(entry.value or "?"),
        }
    end
    return out
end

function TomoMod_ConfigPanel_DamageMeter(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -12

    local bridge = DM()
    local standalone = C_AddOns and C_AddOns.IsAddOnLoaded
        and C_AddOns.IsAddOnLoaded("TomoDamageMeter")

    -- Both of these are ordinary states, not errors: say which one it is
    -- rather than showing controls that would write nowhere.
    if standalone then
        local card, cy = W.CreateCard(c, L("SETTINGS_TITLE", "Damage Meter"), y)
        _, cy = W.CreateInfoText(card.inner, L("DM_STANDALONE",
            "L'addon TomoDamageMeter autonome est installe : c'est lui qui gere "
            .. "le compteur, et ses reglages sont dans sa propre fenetre. Le "
            .. "module integre reste en veille pour eviter deux fenetres "
            .. "concurrentes."), cy)
        W.FinalizeCard(card, cy)
        if scroll.UpdateScroll then scroll.UpdateScroll() end
        return scroll
    end

    if not bridge or not (bridge.IsAvailable and bridge.IsAvailable()) then
        local card, cy = W.CreateCard(c, L("SETTINGS_TITLE", "Damage Meter"), y)
        _, cy = W.CreateInfoText(card.inner, L("DM_UNAVAILABLE",
            "Le compteur de degats de Blizzard n'est pas disponible sur ce "
            .. "client, le module est inactif."), cy)
        W.FinalizeCard(card, cy)
        if scroll.UpdateScroll then scroll.UpdateScroll() end
        return scroll
    end

    -- ── Apparence ────────────────────────────────────────────────────
    local card, cy = W.CreateCard(c, L("SETTINGS_APPEARANCE", "Apparence"), y)

    _, cy = W.CreateDropdown(card.inner, L("SETTINGS_SKIN", "Theme"),
        ToDropdownOptions(bridge.GetSkinList()), Get("skin"), cy,
        function(v) Set("skin", v) end)

    -- Read at build time rather than cached: other addons register their
    -- own statusbars in LibSharedMedia, sometimes after we load.
    _, cy = W.CreateDropdown(card.inner, L("SETTINGS_BAR_TEXTURE", "Texture des barres"),
        ToDropdownOptions(bridge.GetTextureList()), Get("barTexture"), cy,
        function(v) Set("barTexture", v) end)

    local fontOpts = {}
    for _, entry in ipairs(bridge.GetFontList()) do
        fontOpts[#fontOpts + 1] = { value = entry.path, text = L(entry.key, entry.key) }
    end
    _, cy = W.CreateDropdown(card.inner, L("SETTINGS_FONT_FACE", "Police"),
        fontOpts, Get("fontPath"), cy, function(v) Set("fontPath", v) end)

    _, cy = W.CreateSlider(card.inner, L("SETTINGS_FONT_SIZE", "Taille du texte"),
        Get("fontSize") or 12, 8, 22, 1, cy, function(v) Set("fontSize", v) end, "%.0f")

    _, cy = W.CreateSlider(card.inner, L("SETTINGS_BAR_HEIGHT", "Hauteur des barres"),
        Get("barHeight") or 18, 14, 32, 1, cy, function(v) Set("barHeight", v) end, "%.0f")

    _, cy = W.CreateCheckbox(card.inner, L("SETTINGS_USE_CLASS_COLOR", "Accent a la couleur de classe"),
        Get("accentUseClassColor"), cy, function(v) Set("accentUseClassColor", v) end)

    y = W.FinalizeCard(card, cy)

    -- ── Opacite ──────────────────────────────────────────────────────
    card, cy = W.CreateCard(c, L("SETTINGS_OPACITY", "Opacite"), y)

    _, cy = W.CreateSlider(card.inner, L("SETTINGS_BG_OPACITY", "Fond"),
        Get("bgAlpha") or 0.8, 0, 1, 0.05, cy, function(v) Set("bgAlpha", v) end, "%.2f")

    _, cy = W.CreateSlider(card.inner, L("SETTINGS_OOC_OPACITY", "Hors combat"),
        Get("oocAlpha") or 1, 0.1, 1, 0.05, cy, function(v) Set("oocAlpha", v) end, "%.2f")

    _, cy = W.CreateSlider(card.inner, L("SETTINGS_BREAKDOWN_OPACITY", "Panneaux de detail"),
        Get("breakdownAlpha") or 1, 0.1, 1, 0.05, cy,
        function(v) Set("breakdownAlpha", v) end, "%.2f")

    y = W.FinalizeCard(card, cy)

    -- ── Comportement ─────────────────────────────────────────────────
    card, cy = W.CreateCard(c, L("SETTINGS_GENERAL", "Comportement"), y)

    _, cy = W.CreateCheckbox(card.inner, L("SETTINGS_STRIP_REALM", "Masquer le royaume"),
        Get("stripRealm") ~= false, cy, function(v) Set("stripRealm", v) end)

    _, cy = W.CreateCheckbox(card.inner, L("SETTINGS_SHOW_SELF", "Toujours afficher ma barre"),
        Get("showSelfBar"), cy, function(v) Set("showSelfBar", v) end)

    _, cy = W.CreateCheckbox(card.inner, L("SETTINGS_BAR_TOOLTIPS", "Infobulles sur les barres"),
        Get("showBarTooltips"), cy, function(v) Set("showBarTooltips", v) end)

    _, cy = W.CreateCheckbox(card.inner, L("SETTINGS_COMBAT_TIMER", "Chronometre de combat"),
        Get("showCombatTimer"), cy, function(v) Set("showCombatTimer", v) end)

    _, cy = W.CreateSegmentedControl(card.inner, L("SETTINGS_TIMER_POS", "Position du chronometre"),
        { { value = "LEFT", text = L("SETTINGS_TIMER_LEFT", "Gauche") },
          { value = "RIGHT", text = L("SETTINGS_TIMER_RIGHT", "Droite") } },
        Get("combatTimerPos") or "RIGHT", cy,
        function(v) Set("combatTimerPos", v) end, 2)

    _, cy = W.CreateCheckbox(card.inner, L("SETTINGS_AUTO_RESET", "Reinitialiser en entrant en instance"),
        Get("autoResetOnInstance"), cy, function(v) Set("autoResetOnInstance", v) end)

    _, cy = W.CreateCheckbox(card.inner, L("SETTINGS_SNAP", "Aimanter les fenetres"),
        Get("snapEnabled") ~= false, cy, function(v) Set("snapEnabled", v) end)

    y = W.FinalizeCard(card, cy)

    -- ── Recaps ───────────────────────────────────────────────────────
    card, cy = W.CreateCard(c, L("SETTINGS_RECAPS", "Recapitulatifs"), y)

    _, cy = W.CreateCheckbox(card.inner, L("SETTINGS_RUN_RECAP_AUTO", "Recap de donjon automatique"),
        Get("runRecapAutoShow") ~= false, cy, function(v) Set("runRecapAutoShow", v) end)

    _, cy = W.CreateCheckbox(card.inner, L("SETTINGS_DEATH_RECAP_AUTO", "Recap de mort automatique"),
        Get("deathRecapAutoShow"), cy, function(v) Set("deathRecapAutoShow", v) end)

    _, cy = W.CreateSlider(card.inner, L("SETTINGS_REPORT_LINES", "Lignes par rapport"),
        Get("reportLines") or 5, 3, 20, 1, cy, function(v) Set("reportLines", v) end, "%.0f")

    y = W.FinalizeCard(card, cy)

    -- ── Fenetres ─────────────────────────────────────────────────────
    -- Columns, window creation and category filtering stay in the meter's
    -- own window: they act on a specific window rather than on a global
    -- setting, and reproducing that here would mean a second layout for
    -- something that already reads well next to the window it edits.
    card, cy = W.CreateCard(c, L("SETTINGS_WINDOWS", "Fenetres"), y)

    _, cy = W.CreateInfoText(card.inner, L("DM_WINDOWS_HINT",
        "Les colonnes, l'ajout de fenetres et le filtrage par categorie se "
        .. "reglent dans la fenetre du compteur, au plus pres de la fenetre "
        .. "concernee."), cy)

    _, cy = W.CreateButtonRow(card.inner, {
        { text = L("DM_OPEN_WINDOW_SETTINGS", "Reglages des fenetres"), width = 220,
          callback = function()
              local b = DM()
              if b and b.ToggleSettings then b.ToggleSettings() end
          end },
        { text = L("DM_TOGGLE_WINDOWS", "Afficher / masquer"), width = 180,
          callback = function()
              local b = DM()
              if b and b.ToggleWindows then b.ToggleWindows() end
          end },
    }, cy)

    y = W.FinalizeCard(card, cy)

    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

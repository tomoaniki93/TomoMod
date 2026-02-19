-- =====================================
-- Panels/CooldownResource.lua — Cooldown & Resource Config (Tabbed)
-- =====================================

local W = TomoMod_Widgets
local L = TomoMod_L

-- Shortcuts
local function ApplyRB()
    if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
end

local function ApplyCDM()
    if TomoMod_CooldownManager then TomoMod_CooldownManager.ApplySettings() end
end

-- =====================================
-- TAB 1: COOLDOWN MANAGER
-- =====================================

local function BuildCooldownManagerTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local cdm = TomoModDB.cooldownManager
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_cdm"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_cdm_enable"], cdm.enabled, y, function(v)
        cdm.enabled = v
        if TomoMod_CooldownManager then TomoMod_CooldownManager.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_cdm_description"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_cdm_show_hotkeys"], cdm.showHotKey, y, function(v)
        cdm.showHotKey = v; ApplyCDM()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_cdm_combat_alpha"], cdm.combatAlpha, y, function(v)
        cdm.combatAlpha = v; ApplyCDM()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_cdm_alpha_combat"], cdm.alphaInCombat or 1.0, 0, 1, 0.05, y, function(v)
        cdm.alphaInCombat = v; ApplyCDM()
    end, "%.2f")
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_cdm_alpha_target"], cdm.alphaWithTarget or 0.8, 0, 1, 0.05, y, function(v)
        cdm.alphaWithTarget = v; ApplyCDM()
    end, "%.2f")
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_cdm_alpha_ooc"], cdm.alphaOutOfCombat or 0.5, 0, 1, 0.05, y, function(v)
        cdm.alphaOutOfCombat = v; ApplyCDM()
    end, "%.2f")
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_cdm_editmode"], y)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB 2: RESOURCE BARS (general, visibility, dimensions, sync)
-- =====================================

local function BuildResourceBarsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.resourceBars
    local y = -10

    -- General
    local _, ny = W.CreateSectionHeader(c, L["section_resource_bars"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_rb_enable"], db.enabled, y, function(v)
        db.enabled = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_rb_description"], y)
    y = ny

    -- Visibility
    local _, ny = W.CreateSectionHeader(c, L["section_visibility"], y)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_rb_visibility_mode"], {
        { text = L["vis_always"], value = "always" },
        { text = L["vis_combat"], value = "combat" },
        { text = L["vis_target"], value = "target" },
        { text = L["vis_hidden"], value = "hidden" },
    }, db.visibilityMode or "always", y, function(v)
        db.visibilityMode = v; ApplyRB()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_cdm_alpha_combat"], db.combatAlpha or 1.0, 0, 1, 0.05, y, function(v)
        db.combatAlpha = v; ApplyRB()
    end, "%.2f")
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_cdm_alpha_ooc"], db.oocAlpha or 0.5, 0, 1, 0.05, y, function(v)
        db.oocAlpha = v; ApplyRB()
    end, "%.2f")
    y = ny

    -- Dimensions
    local _, ny = W.CreateSectionHeader(c, L["section_dimensions"], y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_rb_width"], db.width or 260, 80, 600, 5, y, function(v)
        db.width = v; ApplyRB()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_rb_primary_height"], db.primaryHeight or 16, 6, 40, 1, y, function(v)
        db.primaryHeight = v; ApplyRB()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_rb_secondary_height"], db.secondaryHeight or 12, 6, 30, 1, y, function(v)
        db.secondaryHeight = v; ApplyRB()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_rb_global_scale"], db.scale or 1.0, 0.5, 2.0, 0.05, y, function(v)
        db.scale = v; ApplyRB()
    end, "%.2f")
    y = ny

    -- Sync with cooldowns
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_rb_sync_width"], db.syncWidthWithCooldowns or false, y, function(v)
        db.syncWidthWithCooldowns = v
        if v and TomoMod_ResourceBars then TomoMod_ResourceBars.SyncWidth() end
    end)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_sync_now"], 160, y, function()
        if TomoMod_ResourceBars then TomoMod_ResourceBars.SyncWidth() end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_rb_sync"], y)
    y = ny

    -- Footer
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_rb_druid"], y)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB 3: TEXT, FONT & POSITION
-- =====================================

local function BuildTextPositionTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.resourceBars
    local y = -10

    -- Text & Font
    local _, ny = W.CreateSectionHeader(c, L["section_text_font"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_rb_show_text"], db.showText, y, function(v)
        db.showText = v; ApplyRB()
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_rb_text_align"], {
        { text = L["align_left"], value = "LEFT" },
        { text = L["align_center"], value = "CENTER" },
        { text = L["align_right"], value = "RIGHT" },
    }, db.textAlignment or "CENTER", y, function(v)
        db.textAlignment = v; ApplyRB()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_rb_font_size"], db.fontSize or 11, 7, 20, 1, y, function(v)
        db.fontSize = v; ApplyRB()
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_rb_font"], {
        { text = "Poppins Medium", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf" },
        { text = "Poppins SemiBold", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf" },
        { text = "Poppins Bold", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Bold.ttf" },
        { text = "Poppins Black", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Black.ttf" },
        { text = "Expressway", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Expressway.TTF" },
        { text = "Accidental Pres.", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\accidental_pres.ttf" },
        { text = "Tomo", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Tomo.ttf" },
        { text = "Friz Quadrata (WoW)", value = "Fonts\\FRIZQT__.TTF" },
        { text = "Arial Narrow (WoW)", value = "Fonts\\ARIALN.TTF" },
        { text = "Morpheus (WoW)", value = "Fonts\\MORPHEUS.TTF" },
    }, db.font or "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", y, function(v)
        db.font = v; ApplyRB()
    end)
    y = ny

    -- Position
    local _, ny = W.CreateSectionHeader(c, L["section_position"], y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_toggle_lock"], 260, y, function()
        if TomoMod_UnitFrames and TomoMod_UnitFrames.ToggleLock then
            TomoMod_UnitFrames.ToggleLock()
        end
        if TomoMod_ResourceBars and TomoMod_ResourceBars.ToggleLock then
            TomoMod_ResourceBars.ToggleLock()
        end
    end)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_reset_position"], 160, y, function()
        db.position = nil
        ApplyRB()
        print("|cff0cd29fTomoMod|r " .. L["msg_rb_position_reset"])
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_rb_position"], y)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB 4: RESOURCE COLORS
-- =====================================

local function BuildColorsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.resourceBars.colors
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_resource_colors"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_rb_colors_custom"], y)
    y = ny

    local entries = {
        { key = "mana",            label = L["res_mana"] },
        { key = "rage",            label = L["res_rage"] },
        { key = "energy",          label = L["res_energy"] },
        { key = "focus",           label = L["res_focus"] },
        { key = "runicPower",      label = L["res_runic_power"] },
        { key = "runesReady",      label = L["res_runes_ready"] },
        { key = "runes",           label = L["res_runes_cd"] },
        { key = "soulShards",      label = L["res_soul_shards"] },
        { key = "astralPower",     label = L["res_astral_power"] },
        { key = "holyPower",       label = L["res_holy_power"] },
        { key = "maelstrom",       label = L["res_maelstrom"] },
        { key = "chi",             label = L["res_chi"] },
        { key = "insanity",        label = L["res_insanity"] },
        { key = "fury",            label = L["res_fury"] },
        { key = "comboPoints",     label = L["res_combo_points"] },
        { key = "arcaneCharges",   label = L["res_arcane_charges"] },
        { key = "essence",         label = L["res_essence"] },
        { key = "stagger",         label = L["res_stagger"] },
        { key = "soulFragments",   label = L["res_soul_fragments"] },
        { key = "tipOfTheSpear",   label = L["res_tip_of_spear"] },
        { key = "maelstromWeapon", label = L["res_maelstrom_weapon"] },
    }

    for _, e in ipairs(entries) do
        if db[e.key] then
            local _, ny = W.CreateColorPicker(c, e.label, db[e.key], y, function(r, g, b)
                db[e.key].r, db[e.key].g, db[e.key].b = r, g, b
                ApplyRB()
            end)
            y = ny
        end
    end

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- MAIN PANEL ENTRY POINT
-- =====================================

function TomoMod_ConfigPanel_CooldownResource(parent)
    local tabs = {
        { key = "cdm",      label = L["tab_cdm"],           builder = function(p) return BuildCooldownManagerTab(p) end },
        { key = "resource",  label = L["tab_resource_bars"], builder = function(p) return BuildResourceBarsTab(p) end },
        { key = "textpos",   label = L["tab_text_position"], builder = function(p) return BuildTextPositionTab(p) end },
        { key = "colors",    label = L["tab_rb_colors"],     builder = function(p) return BuildColorsTab(p) end },
    }

    return W.CreateTabPanel(parent, tabs)
end
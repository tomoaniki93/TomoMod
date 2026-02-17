-- =====================================
-- Panels/Nameplates.lua — Nameplates Config (Tabbed)
-- =====================================

local W = TomoModMini_Widgets
local L = TomoModMini_L

-- Shortcut: refresh all nameplates
local function RefreshNP()
    if TomoModMini_Nameplates then TomoModMini_Nameplates.RefreshAll() end
end

local function ApplyNP()
    if TomoModMini_Nameplates then TomoModMini_Nameplates.ApplySettings() end
end

-- =====================================
-- TAB 1: GENERAL (enable, dimensions, display, castbar)
-- =====================================

local function BuildGeneralTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModMiniDB.nameplates
    local y = -10

    -- Enable
    local _, ny = W.CreateSectionHeader(c, L["section_np_general"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_np_enable"], db.enabled, y, function(v)
        db.enabled = v
        if TomoModMini_Nameplates then
            if v then TomoModMini_Nameplates.Enable() else TomoModMini_Nameplates.Disable() end
        end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_np_description"], y)
    y = ny

    -- Dimensions
    local _, ny = W.CreateSectionHeader(c, L["section_dimensions"], y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_width"], db.width, 60, 300, 5, y, function(v)
        db.width = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_health_height"], db.height, 6, 40, 1, y, function(v)
        db.height = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_np_name_font_size"], db.nameFontSize or 10, 6, 20, 1, y, function(v)
        db.nameFontSize = v; RefreshNP()
    end)
    y = ny

    -- Display
    local _, ny = W.CreateSectionHeader(c, L["section_display"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_name"], db.showName, y, function(v)
        db.showName = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_level"], db.showLevel, y, function(v)
        db.showLevel = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_health_text"], db.showHealthText, y, function(v)
        db.showHealthText = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_health_format"], {
        { text = L["np_fmt_percent"], value = "percent" },
        { text = L["np_fmt_current"], value = "current" },
        { text = L["np_fmt_current_percent"], value = "current_percent" },
    }, db.healthTextFormat or "percent", y, function(v)
        db.healthTextFormat = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_np_show_classification"], db.showClassification, y, function(v)
        db.showClassification = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_np_show_absorb"] or "Show Absorb Bar", db.showAbsorb ~= false, y, function(v)
        db.showAbsorb = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_threat"], db.showThreat, y, function(v)
        db.showThreat = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_np_class_colors"], db.useClassColors, y, function(v)
        db.useClassColors = v; RefreshNP()
    end)
    y = ny

    -- Castbar
    local _, ny = W.CreateSectionHeader(c, L["section_castbar"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_np_show_castbar"], db.showCastbar, y, function(v)
        db.showCastbar = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_np_castbar_height"], db.castbarHeight, 4, 20, 1, y, function(v)
        db.castbarHeight = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_castbar"], db.castbarColor, y, function(r, g, b)
        db.castbarColor = { r = r, g = g, b = b }; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_castbar_uninterruptible"], db.castbarUninterruptible, y, function(r, g, b)
        db.castbarUninterruptible = { r = r, g = g, b = b }; RefreshNP()
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

-- =====================================
-- TAB 2: AURAS (debuffs + enemy buffs)
-- =====================================

local function BuildAurasTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModMiniDB.nameplates
    local y = -10

    -- Debuff Auras
    local _, ny = W.CreateSectionHeader(c, L["section_auras"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_np_show_auras"], db.showAuras, y, function(v)
        db.showAuras = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_np_aura_size"], db.auraSize, 12, 36, 1, y, function(v)
        db.auraSize = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_np_max_auras"], db.maxAuras, 1, 10, 1, y, function(v)
        db.maxAuras = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_np_only_my_debuffs"], db.showOnlyMyAuras, y, function(v)
        db.showOnlyMyAuras = v; RefreshNP()
    end)
    y = ny

    -- Enemy Buffs
    local _, ny = W.CreateSectionHeader(c, L["section_enemy_buffs"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_np_show_enemy_buffs"], db.showEnemyBuffs, y, function(v)
        db.showEnemyBuffs = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_np_enemy_buff_size"], db.enemyBuffSize or 18, 12, 36, 1, y, function(v)
        db.enemyBuffSize = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_np_max_enemy_buffs"], db.maxEnemyBuffs or 3, 1, 8, 1, y, function(v)
        db.maxEnemyBuffs = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_np_enemy_buff_y_offset"], db.enemyBuffYOffset or 4, 0, 20, 1, y, function(v)
        db.enemyBuffYOffset = v; RefreshNP()
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

-- =====================================
-- TAB 3: ADVANCED (transparency, stacking, colors, tank, reset)
-- =====================================

local function BuildAdvancedTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModMiniDB.nameplates
    local y = -10

    -- Transparency
    local _, ny = W.CreateSectionHeader(c, L["section_transparency"], y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_np_selected_alpha"], db.selectedAlpha, 0.3, 1.0, 0.05, y, function(v)
        db.selectedAlpha = v
    end, "%.2f")
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_np_unselected_alpha"], db.unselectedAlpha, 0.3, 1.0, 0.05, y, function(v)
        db.unselectedAlpha = v
    end, "%.2f")
    y = ny

    -- Stacking
    local _, ny = W.CreateSectionHeader(c, L["section_stacking"], y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_np_overlap"], db.overlapV or 1.6, 0.5, 3.0, 0.1, y, function(v)
        db.overlapV = v; ApplyNP()
    end, "%.1f")
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_np_top_inset"], db.topInset or 0.065, 0.01, 0.5, 0.005, y, function(v)
        db.topInset = v; ApplyNP()
    end, "%.3f")
    y = ny

    -- Colors
    local _, ny = W.CreateSectionHeader(c, L["section_colors"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_np_colors_custom"], y)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_hostile"], db.colors.hostile, y, function(r, g, b)
        db.colors.hostile = { r = r, g = g, b = b }; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_neutral"], db.colors.neutral, y, function(r, g, b)
        db.colors.neutral = { r = r, g = g, b = b }; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_friendly"], db.colors.friendly, y, function(r, g, b)
        db.colors.friendly = { r = r, g = g, b = b }; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_tapped"], db.colors.tapped, y, function(r, g, b)
        db.colors.tapped = { r = r, g = g, b = b }; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_focus"], db.colors.focus, y, function(r, g, b)
        db.colors.focus = { r = r, g = g, b = b }; RefreshNP()
    end)
    y = ny

    -- NPC Type Colors (Ellesmere-style)
    local _, ny = W.CreateSectionHeader(c, L["section_npc_type_colors"], y)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_caster"], db.colors.caster, y, function(r, g, b)
        db.colors.caster = { r = r, g = g, b = b }; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_miniboss"], db.colors.miniboss, y, function(r, g, b)
        db.colors.miniboss = { r = r, g = g, b = b }; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_enemy_in_combat"], db.colors.enemyInCombat, y, function(r, g, b)
        db.colors.enemyInCombat = { r = r, g = g, b = b }; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_np_darken_ooc"], y)
    y = ny

    -- Classification Colors
    local _, ny = W.CreateSectionHeader(c, L["section_classification_colors"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_np_use_classification"], db.useClassificationColors, y, function(v)
        db.useClassificationColors = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_boss"], db.colors.boss, y, function(r, g, b)
        db.colors.boss = { r = r, g = g, b = b }; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_elite"], db.colors.elite, y, function(r, g, b)
        db.colors.elite = { r = r, g = g, b = b }; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_rare"], db.colors.rare, y, function(r, g, b)
        db.colors.rare = { r = r, g = g, b = b }; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_normal"], db.colors.normal, y, function(r, g, b)
        db.colors.normal = { r = r, g = g, b = b }; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_trivial"], db.colors.trivial, y, function(r, g, b)
        db.colors.trivial = { r = r, g = g, b = b }; RefreshNP()
    end)
    y = ny

    -- Tank Mode
    local _, ny = W.CreateSectionHeader(c, L["section_tank_mode"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_np_tank_mode"], db.tankMode, y, function(v)
        db.tankMode = v; RefreshNP()
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_no_threat"], db.tankColors.noThreat, y, function(r, g, b)
        db.tankColors.noThreat = { r = r, g = g, b = b }
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_low_threat"], db.tankColors.lowThreat, y, function(r, g, b)
        db.tankColors.lowThreat = { r = r, g = g, b = b }
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_has_threat"], db.tankColors.hasThreat, y, function(r, g, b)
        db.tankColors.hasThreat = { r = r, g = g, b = b }
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_dps_has_aggro"], db.tankColors.dpsHasAggro, y, function(r, g, b)
        db.tankColors.dpsHasAggro = { r = r, g = g, b = b }
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["color_dps_near_aggro"], db.tankColors.dpsNearAggro, y, function(r, g, b)
        db.tankColors.dpsNearAggro = { r = r, g = g, b = b }
    end)
    y = ny

    -- Reset
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_reset_nameplates"], 220, y, function()
        TomoModMini_ResetModule("nameplates")
        print("|cffff3399TomoModMini|r " .. L["msg_np_reset"])
    end)
    y = ny - 20

    c:SetHeight(math.abs(y) + 20)
    return scroll
end

-- =====================================
-- MAIN PANEL ENTRY POINT
-- =====================================

function TomoModMini_ConfigPanel_Nameplates(parent)
    local tabs = {
        { key = "general", label = L["tab_general"],      builder = function(p) return BuildGeneralTab(p) end },
        { key = "auras",   label = L["tab_np_auras"],     builder = function(p) return BuildAurasTab(p) end },
        { key = "advanced", label = L["tab_np_advanced"],  builder = function(p) return BuildAdvancedTab(p) end },
    }

    return W.CreateTabPanel(parent, tabs)
end
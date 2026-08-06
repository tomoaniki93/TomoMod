-- =====================================
-- Panels/PartyFrames.lua — Party Frames Config Panel
-- =====================================
local W = TomoMod_Widgets
local L = TomoMod_L

local function ApplyPF() if TomoMod_PartyFrames then TomoMod_PartyFrames.ApplySettings() end end
local function ApplyRT()
    C_Timer.After(0, function()
        if TomoMod_ResurrectTracker and TomoMod_ResurrectTracker.ApplySettings then
            TomoMod_ResurrectTracker.ApplySettings()
        end
    end)
end

-- ══════════════════════════════════════════════
-- TAB: GENERAL
-- ══════════════════════════════════════════════
local function BuildGeneralTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.partyFrames
    local y = -12

    -- Activation
    local card, cy = W.CreateCard(c, L["pf_section_general"], y)
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_enable"], db.enabled, cy, function(v)
        db.enabled = v
        if TomoMod_PartyFrames then TomoMod_PartyFrames.SetEnabled(v) end
        StaticPopup_Show("TOMOMOD_MODULE_RELOAD")
    end)
    local _, cy = W.CreateInfoText(card.inner, L["info_module_reload"], cy)
    local _, cy = W.CreateInfoText(card.inner, L["pf_info_description"], cy)
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_hide_blizzard"], db.hideBlizzardFrames, cy, function(v) db.hideBlizzardFrames = v; StaticPopup_Show("TOMOMOD_MODULE_RELOAD") end)
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_sort_role"], db.sortByRole, cy, function(v) db.sortByRole = v; ApplyPF() end)
    y = W.FinalizeCard(card, cy)

    -- Dimensions
    local card2, cy = W.CreateCard(c, L["pf_section_dimensions"], y)
    local _, cy = W.CreateSlider(card2.inner, L["pf_opt_width"], db.width, 100, 300, 5, cy, function(v) db.width = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateSlider(card2.inner, L["pf_opt_height"], db.height, 20, 80, 1, cy, function(v) db.height = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateSlider(card2.inner, L["pf_opt_spacing"], db.spacing, 0, 10, 1, cy, function(v) db.spacing = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateDropdown(card2.inner, L["pf_opt_grow_direction"], {
        { text = L["pf_dir_down"],  value = "DOWN" },
        { text = L["pf_dir_up"],    value = "UP" },
        { text = L["pf_dir_right"], value = "RIGHT" },
        { text = L["pf_dir_left"],  value = "LEFT" },
    }, db.growDirection or "DOWN", cy, function(v) db.growDirection = v; ApplyPF() end)
    y = W.FinalizeCard(card2, cy)

    -- Display
    local card3, cy = W.CreateCard(c, L["pf_section_display"], y)
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_name"], db.showName, cy, function(v) db.showName = v; ApplyPF() end)
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_health_text"], db.showHealthText, cy, function(v) db.showHealthText = v; ApplyPF() end)
    local _, cy = W.CreateDropdown(card3.inner, L["pf_opt_health_format"], {
        { text = L["fmt_percent"], value = "percent" },
        { text = L["fmt_current"],    value = "current" },
        { text = L["fmt_current_percent"], value = "current_percent" },
        { text = L["pf_fmt_deficit"],    value = "deficit" },
    }, db.healthTextFormat or "percent", cy, function(v) db.healthTextFormat = v; ApplyPF() end)
    local _, cy = W.CreateDropdown(card3.inner, L["pf_opt_health_color"], {
        { text = L["opt_class_color"], value = "class" },
        { text = L["pf_color_green"],       value = "green" },
        { text = L["pf_color_gradient"],  value = "gradient" },
    }, db.healthColor or "class", cy, function(v) db.healthColor = v; ApplyPF() end)
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_power"], db.showPower, cy, function(v) db.showPower = v; ApplyPF() end)
    local _, cy = W.CreateSlider(card3.inner, L["pf_opt_power_height"], db.powerHeight, 1, 10, 1, cy, function(v) db.powerHeight = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateSlider(card3.inner, L["pf_opt_name_max_length"], db.nameMaxLength or 0, 0, 20, 1, cy, function(v) db.nameMaxLength = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_role"], db.showRoleIcon, cy, function(v) db.showRoleIcon = v; ApplyPF() end)
    local _, cy = W.CreateSlider(card3.inner, L["pf_opt_role_size"], db.roleIconSize, 8, 24, 1, cy, function(v) db.roleIconSize = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_leader"], db.showLeaderIcon ~= false, cy, function(v) db.showLeaderIcon = v; ApplyPF() end)
    local _, cy = W.CreateSlider(card3.inner, L["pf_opt_leader_size"], db.leaderIconSize or 14, 8, 24, 1, cy, function(v) db.leaderIconSize = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_marker"], db.showRaidMarker, cy, function(v) db.showRaidMarker = v; ApplyPF() end)
    local _, cy = W.CreateSlider(card3.inner, L["pf_opt_readycheck_size"], db.readyCheckSize or 24, 12, 40, 1, cy, function(v) db.readyCheckSize = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateSlider(card3.inner, L["pf_opt_summon_size"], db.summonSize or 18, 10, 36, 1, cy, function(v) db.summonSize = v; ApplyPF() end, "%.0f")
    y = W.FinalizeCard(card3, cy)

    -- Text & Font
    local card4, cy = W.CreateCard(c, L["pf_section_font"], y)
    local _, cy = W.CreateSlider(card4.inner, L["pf_opt_font_size"], db.fontSize, 8, 18, 1, cy, function(v) db.fontSize = v end, "%.0f")
    y = W.FinalizeCard(card4, cy)

    -- Position
    local card5, cy = W.CreateCard(c, L["pf_section_position"], y)
    local _, cy = W.CreateInfoText(card5.inner, L["pf_info_position"], cy)
    local _, cy = W.CreateButton(card5.inner, L["pf_btn_reset_position"], 180, cy, function()
        local defaults = TomoMod_Defaults.partyFrames
        if defaults and defaults.position then
            db.position = CopyTable(defaults.position)
            ApplyPF()
        end
    end)
    y = W.FinalizeCard(card5, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- TAB: FEATURES
-- ══════════════════════════════════════════════
local function BuildFeaturesTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.partyFrames
    local y = -12

    -- Absorb & Heal Prediction
    local card, cy = W.CreateCard(c, L["pf_section_health_extras"], y, "H")
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_show_absorb"], db.showAbsorb, cy, function(v) db.showAbsorb = v; ApplyPF() end)
    local ac = db.absorbColor or { r = 0.5, g = 0.5, b = 1.0 }
    local _, cy = W.CreateColorPicker(card.inner, L["pf_opt_absorb_color"], ac, cy, function(r,g,b) db.absorbColor = { r=r, g=g, b=b, a=0.5 }; ApplyPF() end)
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_show_heal_pred"], db.showHealPrediction, cy, function(v) db.showHealPrediction = v; ApplyPF() end)
    y = W.FinalizeCard(card, cy)

    -- Range
    local card2, cy = W.CreateCard(c, L["pf_section_range"], y, "H")
    local _, cy = W.CreateCheckbox(card2.inner, L["pf_opt_show_range"], db.showRange, cy, function(v) db.showRange = v end)
    local _, cy = W.CreateSlider(card2.inner, L["pf_opt_oor_alpha"], db.oorAlpha, 0.10, 0.80, 0.05, cy, function(v) db.oorAlpha = v end, "%.2f")
    y = W.FinalizeCard(card2, cy)

    -- Dispel
    local card3, cy = W.CreateCard(c, L["pf_section_dispel"], y, "H")
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_dispel"], db.showDispel, cy, function(v) db.showDispel = v; ApplyPF() end)
    local _, cy = W.CreateSlider(card3.inner, L["pf_opt_dispel_border"], db.dispelBorderSize or 2, 1, 6, 1, cy, function(v) db.dispelBorderSize = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateInfoText(card3.inner, L["pf_info_dispel"], cy)
    y = W.FinalizeCard(card3, cy)

    -- HoTs
    local card4, cy = W.CreateCard(c, L["pf_section_hots"], y, "H")
    local _, cy = W.CreateCheckbox(card4.inner, L["pf_opt_show_hots"], db.showHoTs, cy, function(v) db.showHoTs = v; ApplyPF() end)
    local _, cy = W.CreateSlider(card4.inner, L["pf_opt_hot_size"], db.hotSize, 8, 20, 1, cy, function(v) db.hotSize = v end, "%.0f")
    local _, cy = W.CreateSlider(card4.inner, L["pf_opt_max_hots"], db.maxHoTs, 1, 6, 1, cy, function(v) db.maxHoTs = v end, "%.0f")
    local _, cy = W.CreateInfoText(card4.inner, L["pf_info_hots"], cy)
    y = W.FinalizeCard(card4, cy)

    -- Defensive cooldowns
    local card5, cy = W.CreateCard(c, L["pf_section_defensives"], y, "TH")
    local _, cy = W.CreateCheckbox(card5.inner, L["pf_opt_show_defensives"], db.showDefensives, cy, function(v) db.showDefensives = v; ApplyPF() end)
    local _, cy = W.CreateSlider(card5.inner, L["pf_opt_defensive_size"], db.defensiveIconSize or 16, 10, 24, 1, cy, function(v) db.defensiveIconSize = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateSlider(card5.inner, L["pf_opt_max_defensives"], db.maxDefensives or 2, 1, 4, 1, cy, function(v) db.maxDefensives = v; StaticPopup_Show("TOMOMOD_MODULE_RELOAD") end)
    local _, cy = W.CreateCheckbox(card5.inner, L["pf_opt_def_externals"], db.defensiveShowExternals ~= false, cy, function(v) db.defensiveShowExternals = v; ApplyPF() end)
    local _, cy = W.CreateCheckbox(card5.inner, L["pf_opt_def_raidwide"], db.defensiveShowRaidWide == true, cy, function(v) db.defensiveShowRaidWide = v; ApplyPF() end)
    local _, cy = W.CreateCheckbox(card5.inner, L["pf_opt_def_personals"], db.defensiveShowPersonals == true, cy, function(v) db.defensiveShowPersonals = v; ApplyPF() end)
    local _, cy = W.CreateInfoText(card5.inner, L["pf_info_defensives"], cy)
    y = W.FinalizeCard(card5, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- TAB: M+ COOLDOWNS
-- ══════════════════════════════════════════════
local function BuildCooldownsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.partyFrames
    local y = -12

    local card, cy = W.CreateCard(c, L["pf_section_cooldowns"], y, "TD")
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_show_kick"], db.showInterruptCD, cy, function(v) db.showInterruptCD = v end)
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_show_brez"], db.showBrezCD, cy, function(v) db.showBrezCD = v end)
    local _, cy = W.CreateSlider(card.inner, L["pf_opt_cd_size"], db.cdIconSize, 12, 28, 1, cy, function(v) db.cdIconSize = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateDropdown(card.inner, L["pf_opt_cd_layout"], {
        { text = L["pf_cd_vertical"],  value = "vertical" },
        { text = L["pf_cd_horizontal"],   value = "horizontal" },
    }, db.cdLayout or "vertical", cy, function(v) db.cdLayout = v end)
    local _, cy = W.CreateInfoText(card.inner, L["pf_info_cooldowns"], cy)
    y = W.FinalizeCard(card, cy)

    local cardRez, cy = W.CreateCard(c, L["pf_section_resurrect"], y, "H")
    local _, cy = W.CreateCheckbox(cardRez.inner, L["pf_opt_show_resurrect"], db.showResurrectIndicator, cy, function(v) db.showResurrectIndicator = v; ApplyRT() end)
    local _, cy = W.CreateSlider(cardRez.inner, L["pf_opt_resurrect_size"], db.resurrectIconSize or 26, 12, 44, 1, cy, function(v) db.resurrectIconSize = v; ApplyRT() end, "%.0f")
    local _, cy = W.CreateInfoText(cardRez.inner, L["pf_info_resurrect"], cy)
    y = W.FinalizeCard(cardRez, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- TAB: ARENA
-- ══════════════════════════════════════════════
local function BuildArenaTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.partyFrames.arena
    local y = -12

    local card, cy = W.CreateCard(c, L["pf_section_arena"], y)
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_arena_enable"], db.enabled, cy, function(v) db.enabled = v end)
    local _, cy = W.CreateInfoText(card.inner, L["pf_info_arena"], cy)
    y = W.FinalizeCard(card, cy)

    local card2, cy = W.CreateCard(c, L["pf_section_arena_dims"], y)
    local _, cy = W.CreateSlider(card2.inner, L["pf_opt_arena_width"], db.width, 100, 300, 5, cy, function(v) db.width = v end, "%.0f")
    local _, cy = W.CreateSlider(card2.inner, L["pf_opt_arena_height"], db.height, 20, 80, 1, cy, function(v) db.height = v end, "%.0f")
    local _, cy = W.CreateSlider(card2.inner, L["pf_opt_arena_spacing"], db.spacing, 0, 10, 1, cy, function(v) db.spacing = v end, "%.0f")
    y = W.FinalizeCard(card2, cy)

    local card3, cy = W.CreateCard(c, L["pf_section_arena_trinket"], y)
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_trinket"], db.showTrinketCD, cy, function(v) db.showTrinketCD = v end)
    local _, cy = W.CreateSlider(card3.inner, L["pf_opt_trinket_size"], db.trinketSize, 12, 32, 1, cy, function(v) db.trinketSize = v end, "%.0f")
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_spec"], db.showSpecIcon, cy, function(v) db.showSpecIcon = v end)
    y = W.FinalizeCard(card3, cy)

    local card4, cy = W.CreateCard(c, L["pf_section_arena_pos"], y)
    local _, cy = W.CreateInfoText(card4.inner, L["pf_info_arena_pos"], cy)
    local _, cy = W.CreateButton(card4.inner, L["pf_btn_reset_arena_pos"], 180, cy, function()
        local defaults = TomoMod_Defaults.partyFrames and TomoMod_Defaults.partyFrames.arena
        if defaults and defaults.position then
            db.position = CopyTable(defaults.position)
        end
    end)
    y = W.FinalizeCard(card4, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- MAIN BUILDER (tabbed)
-- ══════════════════════════════════════════════
function TomoMod_ConfigPanel_PartyFrames(contentArea)
    return W.CreateTabPanel(contentArea, {
        { key = "general",   label = L["pf_tab_general"],    builder = BuildGeneralTab },
        { key = "features",  label = L["pf_tab_features"],   builder = BuildFeaturesTab },
        { key = "cooldowns", label = L["pf_tab_cooldowns"],  builder = BuildCooldownsTab },
        { key = "arena",     label = L["pf_tab_arena"],      builder = BuildArenaTab },
    })
end

-- =====================================
-- Panels/PartyFrames.lua — Party Frames Config Panel
-- =====================================
local W = TomoMod_Widgets
local L = TomoMod_L

local function ApplyPF() if TomoMod_PartyFrames then TomoMod_PartyFrames.ApplySettings() end end

-- ══════════════════════════════════════════════
-- TAB: GENERAL
-- ══════════════════════════════════════════════
local function BuildGeneralTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.partyFrames
    local y = -12

    -- Activation
    local card, cy = W.CreateCard(c, L["pf_section_general"] or "General", y)
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_enable"] or "Enable Party Frames", db.enabled, cy, function(v)
        db.enabled = v
        if TomoMod_PartyFrames then TomoMod_PartyFrames.SetEnabled(v) end
    end)
    local _, cy = W.CreateInfoText(card.inner, L["pf_info_description"] or "Custom party frames for M+ and Arena with health, absorb, heal prediction, HoTs, interrupt/brez CD tracking, and dispel highlights.", cy)
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_hide_blizzard"] or "Hide Blizzard party frames", db.hideBlizzardFrames, cy, function(v) db.hideBlizzardFrames = v end)
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_sort_role"] or "Sort by role (Tank > Healer > DPS)", db.sortByRole, cy, function(v) db.sortByRole = v; ApplyPF() end)
    y = W.FinalizeCard(card, cy)

    -- Dimensions
    local card2, cy = W.CreateCard(c, L["pf_section_dimensions"] or "Dimensions", y)
    local _, cy = W.CreateSlider(card2.inner, L["pf_opt_width"] or "Frame width", db.width, 100, 300, 5, cy, function(v) db.width = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateSlider(card2.inner, L["pf_opt_height"] or "Frame height", db.height, 20, 80, 1, cy, function(v) db.height = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateSlider(card2.inner, L["pf_opt_spacing"] or "Spacing", db.spacing, 0, 10, 1, cy, function(v) db.spacing = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateDropdown(card2.inner, L["pf_opt_grow_direction"] or "Growth direction", {
        { text = L["pf_dir_down"]  or "Down",  value = "DOWN" },
        { text = L["pf_dir_up"]    or "Up",    value = "UP" },
        { text = L["pf_dir_right"] or "Right", value = "RIGHT" },
        { text = L["pf_dir_left"]  or "Left",  value = "LEFT" },
    }, db.growDirection or "DOWN", cy, function(v) db.growDirection = v; ApplyPF() end)
    y = W.FinalizeCard(card2, cy)

    -- Display
    local card3, cy = W.CreateCard(c, L["pf_section_display"] or "Display", y)
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_name"] or "Show name", db.showName, cy, function(v) db.showName = v; ApplyPF() end)
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_health_text"] or "Show health text", db.showHealthText, cy, function(v) db.showHealthText = v; ApplyPF() end)
    local _, cy = W.CreateDropdown(card3.inner, L["pf_opt_health_format"] or "Health format", {
        { text = L["fmt_percent"]         or "Percentage", value = "percent" },
        { text = L["fmt_current"]         or "Current",    value = "current" },
        { text = L["fmt_current_percent"] or "Current + %", value = "current_percent" },
        { text = L["pf_fmt_deficit"]      or "Deficit",    value = "deficit" },
    }, db.healthTextFormat or "percent", cy, function(v) db.healthTextFormat = v; ApplyPF() end)
    local _, cy = W.CreateDropdown(card3.inner, L["pf_opt_health_color"] or "Health color mode", {
        { text = L["opt_class_color"] or "Class color", value = "class" },
        { text = L["pf_color_green"]  or "Green",       value = "green" },
        { text = L["pf_color_gradient"] or "Gradient",  value = "gradient" },
    }, db.healthColor or "class", cy, function(v) db.healthColor = v; ApplyPF() end)
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_power"] or "Show power bar", db.showPower, cy, function(v) db.showPower = v; ApplyPF() end)
    local _, cy = W.CreateSlider(card3.inner, L["pf_opt_power_height"] or "Power bar height", db.powerHeight, 1, 10, 1, cy, function(v) db.powerHeight = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateSlider(card3.inner, L["pf_opt_name_max_length"] or "Name max letters", db.nameMaxLength or 0, 0, 20, 1, cy, function(v) db.nameMaxLength = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_role"] or "Show role icon", db.showRoleIcon, cy, function(v) db.showRoleIcon = v; ApplyPF() end)
    local _, cy = W.CreateSlider(card3.inner, L["pf_opt_role_size"] or "Role icon size", db.roleIconSize, 8, 24, 1, cy, function(v) db.roleIconSize = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_marker"] or "Show raid marker", db.showRaidMarker, cy, function(v) db.showRaidMarker = v; ApplyPF() end)
    y = W.FinalizeCard(card3, cy)

    -- Text & Font
    local card4, cy = W.CreateCard(c, L["pf_section_font"] or "Font", y)
    local _, cy = W.CreateSlider(card4.inner, L["pf_opt_font_size"] or "Font size", db.fontSize, 8, 18, 1, cy, function(v) db.fontSize = v end, "%.0f")
    y = W.FinalizeCard(card4, cy)

    -- Position
    local card5, cy = W.CreateCard(c, L["pf_section_position"] or "Position", y)
    local _, cy = W.CreateInfoText(card5.inner, L["pf_info_position"] or "Use /tm layout to unlock and drag party frames.", cy)
    local _, cy = W.CreateButton(card5.inner, L["pf_btn_reset_position"] or "Reset Position", 180, cy, function()
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
    local card, cy = W.CreateCard(c, L["pf_section_health_extras"] or "Health Features", y)
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_show_absorb"] or "Show absorb bar", db.showAbsorb, cy, function(v) db.showAbsorb = v; ApplyPF() end)
    local ac = db.absorbColor or { r = 0.5, g = 0.5, b = 1.0 }
    local _, cy = W.CreateColorPicker(card.inner, L["pf_opt_absorb_color"] or "Absorb color", ac, cy, function(r,g,b) db.absorbColor = { r=r, g=g, b=b, a=0.5 }; ApplyPF() end)
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_show_heal_pred"] or "Show heal prediction", db.showHealPrediction, cy, function(v) db.showHealPrediction = v; ApplyPF() end)
    y = W.FinalizeCard(card, cy)

    -- Range
    local card2, cy = W.CreateCard(c, L["pf_section_range"] or "Range Check", y)
    local _, cy = W.CreateCheckbox(card2.inner, L["pf_opt_show_range"] or "Fade out-of-range members", db.showRange, cy, function(v) db.showRange = v end)
    local _, cy = W.CreateSlider(card2.inner, L["pf_opt_oor_alpha"] or "Out-of-range opacity", db.oorAlpha, 0.10, 0.80, 0.05, cy, function(v) db.oorAlpha = v end, "%.2f")
    y = W.FinalizeCard(card2, cy)

    -- Dispel
    local card3, cy = W.CreateCard(c, L["pf_section_dispel"] or "Dispel Highlight", y)
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_dispel"] or "Highlight dispellable debuffs", db.showDispel, cy, function(v) db.showDispel = v; ApplyPF() end)
    local _, cy = W.CreateInfoText(card3.inner, L["pf_info_dispel"] or "Border glows by debuff type: Magic (blue), Curse (purple), Disease (brown), Poison (green).", cy)
    y = W.FinalizeCard(card3, cy)

    -- HoTs
    local card4, cy = W.CreateCard(c, L["pf_section_hots"] or "HoT Tracking", y)
    local _, cy = W.CreateCheckbox(card4.inner, L["pf_opt_show_hots"] or "Show HoT indicators", db.showHoTs, cy, function(v) db.showHoTs = v; ApplyPF() end)
    local _, cy = W.CreateSlider(card4.inner, L["pf_opt_hot_size"] or "HoT icon size", db.hotSize, 8, 20, 1, cy, function(v) db.hotSize = v end, "%.0f")
    local _, cy = W.CreateSlider(card4.inner, L["pf_opt_max_hots"] or "Max HoTs shown", db.maxHoTs, 1, 6, 1, cy, function(v) db.maxHoTs = v end, "%.0f")
    local _, cy = W.CreateInfoText(card4.inner, L["pf_info_hots"] or "Displays healing-over-time effects with class-colored borders. Supports Priest, Druid, Paladin, Shaman, Monk, and Evoker HoTs.", cy)
    y = W.FinalizeCard(card4, cy)

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

    local card, cy = W.CreateCard(c, L["pf_section_cooldowns"] or "Cooldown Trackers", y)
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_show_kick"] or "Show interrupt cooldown", db.showInterruptCD, cy, function(v) db.showInterruptCD = v end)
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_show_brez"] or "Show battle rez cooldown", db.showBrezCD, cy, function(v) db.showBrezCD = v end)
    local _, cy = W.CreateSlider(card.inner, L["pf_opt_cd_size"] or "CD icon size", db.cdIconSize, 12, 28, 1, cy, function(v) db.cdIconSize = v; ApplyPF() end, "%.0f")
    local _, cy = W.CreateDropdown(card.inner, L["pf_opt_cd_layout"] or "CD icon layout", {
        { text = L["pf_cd_vertical"]   or "Vertical (on frame)",  value = "vertical" },
        { text = L["pf_cd_horizontal"] or "Horizontal (below)",   value = "horizontal" },
    }, db.cdLayout or "vertical", cy, function(v) db.cdLayout = v end)
    local _, cy = W.CreateInfoText(card.inner, L["pf_info_cooldowns"] or "Tracks interrupt and battle rez cooldowns for each party member. Detected via UNIT_SPELLCAST_SUCCEEDED (no COMBAT_LOG_EVENT_UNFILTERED).", cy)
    y = W.FinalizeCard(card, cy)

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

    local card, cy = W.CreateCard(c, L["pf_section_arena"] or "Arena Enemy Frames", y)
    local _, cy = W.CreateCheckbox(card.inner, L["pf_opt_arena_enable"] or "Enable Arena Frames", db.enabled, cy, function(v) db.enabled = v end)
    local _, cy = W.CreateInfoText(card.inner, L["pf_info_arena"] or "Displays enemy team health, power, and PvP trinket cooldowns in Arena (2v2/3v3).", cy)
    y = W.FinalizeCard(card, cy)

    local card2, cy = W.CreateCard(c, L["pf_section_arena_dims"] or "Arena Dimensions", y)
    local _, cy = W.CreateSlider(card2.inner, L["pf_opt_arena_width"] or "Width", db.width, 100, 300, 5, cy, function(v) db.width = v end, "%.0f")
    local _, cy = W.CreateSlider(card2.inner, L["pf_opt_arena_height"] or "Height", db.height, 20, 80, 1, cy, function(v) db.height = v end, "%.0f")
    local _, cy = W.CreateSlider(card2.inner, L["pf_opt_arena_spacing"] or "Spacing", db.spacing, 0, 10, 1, cy, function(v) db.spacing = v end, "%.0f")
    y = W.FinalizeCard(card2, cy)

    local card3, cy = W.CreateCard(c, L["pf_section_arena_trinket"] or "PvP Trinket", y)
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_trinket"] or "Show trinket cooldown", db.showTrinketCD, cy, function(v) db.showTrinketCD = v end)
    local _, cy = W.CreateSlider(card3.inner, L["pf_opt_trinket_size"] or "Trinket icon size", db.trinketSize, 12, 32, 1, cy, function(v) db.trinketSize = v end, "%.0f")
    local _, cy = W.CreateCheckbox(card3.inner, L["pf_opt_show_spec"] or "Show spec icon", db.showSpecIcon, cy, function(v) db.showSpecIcon = v end)
    y = W.FinalizeCard(card3, cy)

    local card4, cy = W.CreateCard(c, L["pf_section_arena_pos"] or "Arena Position", y)
    local _, cy = W.CreateInfoText(card4.inner, L["pf_info_arena_pos"] or "Use /tm layout to unlock and drag arena frames.", cy)
    local _, cy = W.CreateButton(card4.inner, L["pf_btn_reset_arena_pos"] or "Reset Position", 180, cy, function()
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
        { key = "general",   label = L["pf_tab_general"]   or "General",    builder = BuildGeneralTab },
        { key = "features",  label = L["pf_tab_features"]  or "Features",   builder = BuildFeaturesTab },
        { key = "cooldowns", label = L["pf_tab_cooldowns"] or "Cooldowns",  builder = BuildCooldownsTab },
        { key = "arena",     label = L["pf_tab_arena"]     or "Arena",      builder = BuildArenaTab },
    })
end

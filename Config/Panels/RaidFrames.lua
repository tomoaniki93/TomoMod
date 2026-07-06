-- =====================================
-- Panels/RaidFrames.lua — Raid Frames Config Panel
-- =====================================
local W = TomoMod_Widgets
local L = TomoMod_L

local function ApplyRF()
    C_Timer.After(0, function()
        if TomoMod_RaidFrames then TomoMod_RaidFrames.ApplySettings() end
        if TomoMod_RFPreview  and TomoMod_RFPreview.Refresh  then TomoMod_RFPreview.Refresh()  end
    end)
end

local function ApplyRT()
    C_Timer.After(0, function()
        if TomoMod_ResurrectTracker and TomoMod_ResurrectTracker.ApplySettings then
            TomoMod_ResurrectTracker.ApplySettings()
        end
    end)
end

-- TAB: GENERAL
local function BuildGeneralTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.raidFrames
    local y = -12

    local card, cy = W.CreateCard(c, L["rf_section_general"] or "General", y)
    local _, cy = W.CreateCheckbox(card.inner, L["rf_opt_enable"] or "Enable Raid Frames", db.enabled, cy, function(v)
        db.enabled = v
        if TomoMod_RaidFrames then TomoMod_RaidFrames.SetEnabled(v) end
        StaticPopup_Show("TOMOMOD_MODULE_RELOAD")
    end)
    local _, cy = W.CreateInfoText(card.inner, L["info_module_reload"] or "", cy)
    local _, cy = W.CreateInfoText(card.inner, L["rf_info_description"] or "Custom raid frames with health, absorb, heal prediction, HoTs, debuffs, dispel highlight, defensive CDs, and range check.", cy)
    local _, cy = W.CreateCheckbox(card.inner, L["rf_opt_hide_blizzard"] or "Hide Blizzard raid frames", db.hideBlizzardFrames, cy, function(v) db.hideBlizzardFrames = v; StaticPopup_Show("TOMOMOD_MODULE_RELOAD") end)
    local _, cy = W.CreateCheckbox(card.inner, L["rf_opt_skin_group_manager"] or "Skin the group leader panel (ready check, markers, leave group)", db.skinGroupManager, cy, function(v)
        db.skinGroupManager = v
        if TomoMod_GroupManagerSkin then TomoMod_GroupManagerSkin.ApplySettings() end
    end)
    local _, cy = W.CreateCheckbox(card.inner, L["rf_opt_sort_role"] or "Sort by role (Tank > Healer > DPS)", db.sortByRole, cy, function(v) db.sortByRole = v; ApplyRF() end)
    y = W.FinalizeCard(card, cy)

    local card2, cy = W.CreateCard(c, L["rf_section_layout"] or "Layout", y)
    local _, cy = W.CreateDropdown(card2.inner, L["rf_opt_layout_mode"] or "Layout mode", {
        { text = L["rf_layout_grid"] or "Grid (groups as columns)", value = "grid" },
        { text = L["rf_layout_list"] or "List (single column)",     value = "list" },
    }, db.layout or "grid", cy, function(v) db.layout = v; ApplyRF() end)
    local _, cy = W.CreateSlider(card2.inner, L["rf_opt_width"] or "Frame width", db.width, 40, 200, 2, cy, function(v) db.width = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateSlider(card2.inner, L["rf_opt_height"] or "Frame height", db.height, 20, 80, 1, cy, function(v) db.height = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateSlider(card2.inner, L["rf_opt_spacing"] or "Spacing", db.spacing, 0, 10, 1, cy, function(v) db.spacing = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateSlider(card2.inner, L["rf_opt_group_spacing"] or "Group spacing", db.groupSpacing, 0, 20, 1, cy, function(v) db.groupSpacing = v; ApplyRF() end, "%.0f")
    y = W.FinalizeCard(card2, cy)

    local card3, cy = W.CreateCard(c, L["rf_section_display"] or "Display", y)
    local _, cy = W.CreateCheckbox(card3.inner, L["rf_opt_show_name"] or "Show name", db.showName, cy, function(v) db.showName = v; ApplyRF() end)
    local _, cy = W.CreateSlider(card3.inner, L["rf_opt_name_max_length"] or "Name max letters", db.nameMaxLength or 0, 0, 12, 1, cy, function(v) db.nameMaxLength = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateCheckbox(card3.inner, L["rf_opt_show_health_text"] or "Show health text", db.showHealthText, cy, function(v) db.showHealthText = v; ApplyRF() end)
    local _, cy = W.CreateDropdown(card3.inner, L["rf_opt_health_format"] or "Health format", {
        { text = L["fmt_percent"]    or "Percentage", value = "percent" },
        { text = L["fmt_current"]    or "Current",    value = "current" },
        { text = L["pf_fmt_deficit"] or "Deficit",    value = "deficit" },
    }, db.healthTextFormat or "percent", cy, function(v) db.healthTextFormat = v; ApplyRF() end)
    local _, cy = W.CreateDropdown(card3.inner, L["rf_opt_health_color"] or "Health color mode", {
        { text = L["opt_class_color"]   or "Class color", value = "class" },
        { text = L["pf_color_green"]    or "Green",       value = "green" },
        { text = L["pf_color_gradient"] or "Gradient",    value = "gradient" },
    }, db.healthColor or "class", cy, function(v) db.healthColor = v; ApplyRF() end)
    local _, cy = W.CreateCheckbox(card3.inner, L["rf_opt_show_role"] or "Show role icon", db.showRoleIcon, cy, function(v) db.showRoleIcon = v; ApplyRF() end)
    local _, cy = W.CreateCheckbox(card3.inner, L["rf_opt_show_marker"] or "Show raid marker", db.showRaidMarker, cy, function(v) db.showRaidMarker = v; ApplyRF() end)
    local _, cy = W.CreateSlider(card3.inner, L["rf_opt_readycheck_size"] or "Ready check icon size", db.readyCheckSize or 20, 12, 40, 1, cy, function(v) db.readyCheckSize = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateSlider(card3.inner, L["rf_opt_summon_size"] or "Summon indicator size", db.summonSize or 18, 10, 36, 1, cy, function(v) db.summonSize = v; ApplyRF() end, "%.0f")
    y = W.FinalizeCard(card3, cy)

    local card4, cy = W.CreateCard(c, L["rf_section_font"] or "Font", y)
    local _, cy = W.CreateSlider(card4.inner, L["rf_opt_font_size"] or "Font size", db.fontSize, 7, 14, 1, cy, function(v) db.fontSize = v; ApplyRF() end, "%.0f")
    y = W.FinalizeCard(card4, cy)

    local card5, cy = W.CreateCard(c, L["rf_section_position"] or "Position", y)
    local _, cy = W.CreateInfoText(card5.inner, L["rf_info_position"] or "Use /tm layout to unlock and drag raid frames.", cy)
    local _, cy = W.CreateButton(card5.inner, L["rf_btn_reset_position"] or "Reset Position", 180, cy, function()
        local defaults = TomoMod_Defaults.raidFrames
        if defaults and defaults.position then
            db.position = CopyTable(defaults.position)
            ApplyRF()
        end
    end)
    y = W.FinalizeCard(card5, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- TAB: FEATURES
local function BuildFeaturesTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.raidFrames
    local y = -12

    local card, cy = W.CreateCard(c, L["rf_section_health_extras"] or "Health Features", y)
    local _, cy = W.CreateCheckbox(card.inner, L["rf_opt_show_power"] or "Show power bar (healers only)", db.showPower, cy, function(v) db.showPower = v; ApplyRF() end)
    local _, cy = W.CreateSlider(card.inner, L["rf_opt_power_height"] or "Power bar height", db.powerHeight, 1, 8, 1, cy, function(v) db.powerHeight = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateCheckbox(card.inner, L["rf_opt_show_absorb"] or "Show absorb bar", db.showAbsorb, cy, function(v) db.showAbsorb = v; ApplyRF() end)
    local _, cy = W.CreateCheckbox(card.inner, L["rf_opt_show_heal_pred"] or "Show heal prediction", db.showHealPrediction, cy, function(v) db.showHealPrediction = v; ApplyRF() end)
    y = W.FinalizeCard(card, cy)

    local card2, cy = W.CreateCard(c, L["rf_section_range"] or "Range Check", y)
    local _, cy = W.CreateCheckbox(card2.inner, L["rf_opt_show_range"] or "Fade out-of-range members", db.showRange, cy, function(v) db.showRange = v end)
    local _, cy = W.CreateSlider(card2.inner, L["rf_opt_oor_alpha"] or "Out-of-range opacity", db.oorAlpha, 0.10, 0.80, 0.05, cy, function(v) db.oorAlpha = v end, "%.2f")
    y = W.FinalizeCard(card2, cy)

    local card3, cy = W.CreateCard(c, L["rf_section_dispel"] or "Dispel Highlight", y)
    local _, cy = W.CreateCheckbox(card3.inner, L["rf_opt_show_dispel"] or "Highlight dispellable debuffs", db.showDispel, cy, function(v) db.showDispel = v; ApplyRF() end)
    local _, cy = W.CreateInfoText(card3.inner, L["pf_info_dispel"] or "Border glows by debuff type: Magic (blue), Curse (purple), Disease (brown), Poison (green).", cy)
    y = W.FinalizeCard(card3, cy)

    local card4, cy = W.CreateCard(c, L["rf_section_hots"] or "HoT Tracking", y)
    local _, cy = W.CreateCheckbox(card4.inner, L["rf_opt_show_hots"] or "Show HoT indicators", db.showHoTs, cy, function(v) db.showHoTs = v; ApplyRF() end)
    local _, cy = W.CreateSlider(card4.inner, L["rf_opt_hot_size"] or "HoT icon size", db.hotSize, 6, 16, 1, cy, function(v) db.hotSize = v end, "%.0f")
    local _, cy = W.CreateSlider(card4.inner, L["rf_opt_max_hots"] or "Max HoTs shown", db.maxHoTs, 1, 4, 1, cy, function(v) db.maxHoTs = v end, "%.0f")
    y = W.FinalizeCard(card4, cy)

    local card5, cy = W.CreateCard(c, L["rf_section_debuffs"] or "Debuff Tracking", y)
    local _, cy = W.CreateCheckbox(card5.inner, L["rf_opt_show_debuffs"] or "Show debuff icons", db.showDebuffs, cy, function(v) db.showDebuffs = v; ApplyRF() end)
    local _, cy = W.CreateSlider(card5.inner, L["rf_opt_debuff_size"] or "Debuff icon size", db.debuffSize, 8, 20, 1, cy, function(v) db.debuffSize = v end, "%.0f")
    local _, cy = W.CreateSlider(card5.inner, L["rf_opt_max_debuffs"] or "Max debuffs shown", db.maxDebuffs, 1, 5, 1, cy, function(v) db.maxDebuffs = v end, "%.0f")
    y = W.FinalizeCard(card5, cy)

    local card6, cy = W.CreateCard(c, L["rf_section_defensives"] or "Defensive Cooldowns", y)
    local _, cy = W.CreateCheckbox(card6.inner, L["rf_opt_show_defensives"] or "Show active defensive buffs", db.showDefensives, cy, function(v) db.showDefensives = v; ApplyRF() end)
    local _, cy = W.CreateSlider(card6.inner, L["rf_opt_defensive_size"] or "Defensive icon size", db.defensiveIconSize, 10, 22, 1, cy, function(v) db.defensiveIconSize = v end, "%.0f")
    local _, cy = W.CreateInfoText(card6.inner, L["rf_info_defensives"] or "Displays active defensive cooldowns (e.g. Pain Suppression, Ironbark, Divine Shield) on each raid member.", cy)
    y = W.FinalizeCard(card6, cy)

    -- Resurrection indicator
    local cardRez, cy = W.CreateCard(c, L["rf_section_resurrect"] or "Resurrection Indicator", y)
    local _, cy = W.CreateCheckbox(cardRez.inner, L["rf_opt_show_resurrect"] or "Show incoming-resurrect icon", db.showResurrectIndicator, cy, function(v) db.showResurrectIndicator = v; ApplyRT() end)
    local _, cy = W.CreateSlider(cardRez.inner, L["rf_opt_resurrect_size"] or "Resurrect icon size", db.resurrectIconSize or 22, 12, 40, 1, cy, function(v) db.resurrectIconSize = v; ApplyRT() end, "%.0f")
    local _, cy = W.CreateInfoText(cardRez.inner, L["rf_info_resurrect"] or "Shows a rez icon on a member while a resurrection is being cast on them (combat-res or normal).", cy)
    y = W.FinalizeCard(cardRez, cy)

    -- Battle Rez counter (shared combat-res pool)
    local brdb = TomoModDB.battleRez
    if brdb then
        local cardBR, cy = W.CreateCard(c, L["rf_section_battlerez"] or "Battle Rez Counter", y)
        local _, cy = W.CreateCheckbox(cardBR.inner, L["rf_opt_br_enable"] or "Show battle-rez counter", brdb.enabled, cy, function(v) brdb.enabled = v; ApplyRT() end)
        local _, cy = W.CreateCheckbox(cardBR.inner, L["rf_opt_br_only_instance"] or "Only inside dungeons/raids", brdb.onlyInstance, cy, function(v) brdb.onlyInstance = v; ApplyRT() end)
        local _, cy = W.CreateSlider(cardBR.inner, L["rf_opt_br_size"] or "Counter size", brdb.size or 44, 24, 96, 1, cy, function(v) brdb.size = v; ApplyRT() end, "%.0f")
        local _, cy = W.CreateSlider(cardBR.inner, L["rf_opt_br_font"] or "Counter font size", brdb.fontSize or 18, 10, 32, 1, cy, function(v) brdb.fontSize = v; ApplyRT() end, "%.0f")
        local _, cy = W.CreateInfoText(cardBR.inner, L["rf_info_battlerez"] or "A movable counter showing how many battle resurrections are available and the time to the next charge. Reads the shared combat-res pool, so it works on any class. Use /tm layout to move it.", cy)
        y = W.FinalizeCard(cardBR, cy)
    end

    -- Per-size layout overrides (10 / 25 / 40)
    local ov = db.raidSizeOverrides
    if ov then
        ov["10"] = ov["10"] or {}; ov["25"] = ov["25"] or {}; ov["40"] = ov["40"] or {}
        local cardOv, cy = W.CreateCard(c, L["rf_section_size_overrides"] or "Per-Size Layout (10/25/40)", y)
        local _, cy = W.CreateCheckbox(cardOv.inner, L["rf_opt_overrides_enable"] or "Enable per-size overrides", ov.enabled, cy, function(v) ov.enabled = v; ApplyRF() end)
        local _, cy = W.CreateInfoText(cardOv.inner, L["rf_info_size_overrides"] or "When enabled, frame size adapts to the current group size (spacing auto-adjusts per bracket).", cy)
        local _, cy = W.CreateInfoText(cardOv.inner, L["rf_ov_small"] or "Small  (up to 10)", cy)
        local _, cy = W.CreateSlider(cardOv.inner, L["rf_ov_width"] or "Width", ov["10"].width or db.width, 40, 200, 2, cy, function(v) ov["10"].width = v; ApplyRF() end, "%.0f")
        local _, cy = W.CreateSlider(cardOv.inner, L["rf_ov_height"] or "Height", ov["10"].height or db.height, 20, 80, 1, cy, function(v) ov["10"].height = v; ApplyRF() end, "%.0f")
        local _, cy = W.CreateInfoText(cardOv.inner, L["rf_ov_medium"] or "Medium  (up to 25)", cy)
        local _, cy = W.CreateSlider(cardOv.inner, L["rf_ov_width"] or "Width", ov["25"].width or db.width, 40, 200, 2, cy, function(v) ov["25"].width = v; ApplyRF() end, "%.0f")
        local _, cy = W.CreateSlider(cardOv.inner, L["rf_ov_height"] or "Height", ov["25"].height or db.height, 20, 80, 1, cy, function(v) ov["25"].height = v; ApplyRF() end, "%.0f")
        local _, cy = W.CreateInfoText(cardOv.inner, L["rf_ov_large"] or "Large  (26-40)", cy)
        local _, cy = W.CreateSlider(cardOv.inner, L["rf_ov_width"] or "Width", ov["40"].width or db.width, 40, 200, 2, cy, function(v) ov["40"].width = v; ApplyRF() end, "%.0f")
        local _, cy = W.CreateSlider(cardOv.inner, L["rf_ov_height"] or "Height", ov["40"].height or db.height, 20, 80, 1, cy, function(v) ov["40"].height = v; ApplyRF() end, "%.0f")
        y = W.FinalizeCard(cardOv, cy)
    end

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ============================================================
-- MAIN ENTRY POINT
-- Layout:
--   ┌─ wrapper ─────────────────────────────────────────┐
--   │  live preview strip (auto height)                  │
--   ├────────────────────────────────────────────┤
--   │  General / Features tabs                           │
--   └────────────────────────────────────────────┘
-- ============================================================
local PREVIEW_H_INITIAL = 200  -- initial height before first Refresh

function TomoMod_ConfigPanel_RaidFrames(contentArea)
    local wrapper = CreateFrame("Frame", nil, contentArea)
    wrapper:SetAllPoints()

    -- Live preview strip
    local preview = TomoMod_RFPreview.Create(wrapper)

    -- Tab host, anchored just below the preview strip
    local tabHost = CreateFrame("Frame", nil, wrapper)
    tabHost:SetPoint("TOPLEFT",     wrapper, "TOPLEFT",     0, -PREVIEW_H_INITIAL)
    tabHost:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", 0, 0)

    -- Re-anchor tab host whenever the strip resizes
    preview:SetScript("OnSizeChanged", function(self)
        local h = math.floor(self:GetHeight() + 0.5)
        tabHost:ClearAllPoints()
        tabHost:SetPoint("TOPLEFT",     wrapper, "TOPLEFT",     0, -h)
        tabHost:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", 0, 0)
    end)

    local tabWidget = W.CreateTabPanel(tabHost, {
        { key = "general",  label = L["rf_tab_general"]  or "General",  builder = BuildGeneralTab  },
        { key = "features", label = L["rf_tab_features"] or "Features", builder = BuildFeaturesTab },
    })
    tabWidget:SetAllPoints(tabHost)

    -- Force a refresh when the panel is opened
    wrapper:SetScript("OnShow", function()
        if TomoMod_RFPreview and TomoMod_RFPreview.ForceRefresh then
            TomoMod_RFPreview.ForceRefresh()
        end
    end)

    return wrapper
end

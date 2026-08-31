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

    local card, cy = W.CreateCard(c, L["rf_section_general"], y)
    local _, cy = W.CreateCheckbox(card.inner, L["rf_opt_enable"], db.enabled, cy, function(v)
        db.enabled = v
        if TomoMod_RaidFrames then TomoMod_RaidFrames.SetEnabled(v) end
        if TomoMod_Lifecycle then TomoMod_Lifecycle.RequestReload("raidFrames") end
    end)
    local _, cy = W.CreateInfoText(card.inner, L["info_module_reload"], cy)
    local _, cy = W.CreateInfoText(card.inner, L["rf_info_description"], cy)
    local _, cy = W.CreateCheckbox(card.inner, L["rf_opt_hide_blizzard"], db.hideBlizzardFrames, cy, function(v) db.hideBlizzardFrames = v; if TomoMod_Lifecycle then TomoMod_Lifecycle.RequestReload("raidFrames") end end)
    local _, cy = W.CreateCheckbox(card.inner, L["rf_opt_skin_group_manager"], db.skinGroupManager, cy, function(v)
        db.skinGroupManager = v
        if TomoMod_GroupManagerSkin then TomoMod_GroupManagerSkin.ApplySettings() end
    end)
    local _, cy = W.CreateCheckbox(card.inner, L["rf_opt_sort_role"], db.sortByRole, cy, function(v) db.sortByRole = v; ApplyRF() end)
    y = W.FinalizeCard(card, cy)

    local card2, cy = W.CreateCard(c, L["rf_section_layout"], y)
    local _, cy = W.CreateDropdown(card2.inner, L["rf_opt_layout_mode"], {
        { text = L["rf_layout_grid"], value = "grid" },
        { text = L["rf_layout_list"],     value = "list" },
    }, db.layout or "grid", cy, function(v) db.layout = v; ApplyRF() end)
    local _, cy = W.CreateSlider(card2.inner, L["rf_opt_width"], db.width, 40, 200, 2, cy, function(v) db.width = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateSlider(card2.inner, L["rf_opt_height"], db.height, 20, 80, 1, cy, function(v) db.height = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateSlider(card2.inner, L["rf_opt_spacing"], db.spacing, 0, 10, 1, cy, function(v) db.spacing = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateSlider(card2.inner, L["rf_opt_group_spacing"], db.groupSpacing, 0, 20, 1, cy, function(v) db.groupSpacing = v; ApplyRF() end, "%.0f")
    y = W.FinalizeCard(card2, cy)

    local card3, cy = W.CreateCard(c, L["rf_section_display"], y)
    local _, cy = W.CreateCheckbox(card3.inner, L["rf_opt_show_name"], db.showName, cy, function(v) db.showName = v; ApplyRF() end)
    local _, cy = W.CreateSlider(card3.inner, L["rf_opt_name_max_length"], db.nameMaxLength or 0, 0, 12, 1, cy, function(v) db.nameMaxLength = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateCheckbox(card3.inner, L["rf_opt_show_health_text"], db.showHealthText, cy, function(v) db.showHealthText = v; ApplyRF() end)
    local _, cy = W.CreateDropdown(card3.inner, L["rf_opt_health_format"], {
        { text = L["fmt_percent"], value = "percent" },
        { text = L["fmt_current"],    value = "current" },
        { text = L["pf_fmt_deficit"],    value = "deficit" },
    }, db.healthTextFormat or "percent", cy, function(v) db.healthTextFormat = v; ApplyRF() end)
    local _, cy = W.CreateDropdown(card3.inner, L["rf_opt_health_color"], {
        { text = L["opt_class_color"], value = "class" },
        { text = L["pf_color_green"],       value = "green" },
        { text = L["pf_color_gradient"],    value = "gradient" },
    }, db.healthColor or "class", cy, function(v) db.healthColor = v; ApplyRF() end)
    local _, cy = W.CreateCheckbox(card3.inner, L["rf_opt_show_role"], db.showRoleIcon, cy, function(v) db.showRoleIcon = v; ApplyRF() end)
    local _, cy = W.CreateCheckbox(card3.inner, L["rf_opt_show_marker"], db.showRaidMarker, cy, function(v) db.showRaidMarker = v; ApplyRF() end)
    local _, cy = W.CreateSlider(card3.inner, L["rf_opt_readycheck_size"], db.readyCheckSize or 20, 12, 40, 1, cy, function(v) db.readyCheckSize = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateSlider(card3.inner, L["rf_opt_summon_size"], db.summonSize or 18, 10, 36, 1, cy, function(v) db.summonSize = v; ApplyRF() end, "%.0f")
    y = W.FinalizeCard(card3, cy)

    local card4, cy = W.CreateCard(c, L["rf_section_font"], y)
    local _, cy = W.CreateSlider(card4.inner, L["rf_opt_font_size"], db.fontSize, 7, 14, 1, cy, function(v) db.fontSize = v; ApplyRF() end, "%.0f")
    y = W.FinalizeCard(card4, cy)

    local card5, cy = W.CreateCard(c, L["rf_section_position"], y)
    local _, cy = W.CreateInfoText(card5.inner, L["rf_info_position"], cy)
    local _, cy = W.CreateButton(card5.inner, L["rf_btn_reset_position"], 180, cy, function()
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

    local card, cy = W.CreateCard(c, L["rf_section_health_extras"], y, "H")
    local _, cy = W.CreateCheckbox(card.inner, L["rf_opt_show_power"], db.showPower, cy, function(v) db.showPower = v; ApplyRF() end)
    local _, cy = W.CreateSlider(card.inner, L["rf_opt_power_height"], db.powerHeight, 1, 8, 1, cy, function(v) db.powerHeight = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateCheckbox(card.inner, L["rf_opt_show_absorb"], db.showAbsorb, cy, function(v) db.showAbsorb = v; ApplyRF() end)
    local _, cy = W.CreateCheckbox(card.inner, L["rf_opt_show_heal_pred"], db.showHealPrediction, cy, function(v) db.showHealPrediction = v; ApplyRF() end)
    y = W.FinalizeCard(card, cy)

    local card2, cy = W.CreateCard(c, L["rf_section_range"], y, "H")
    local _, cy = W.CreateCheckbox(card2.inner, L["rf_opt_show_range"], db.showRange, cy, function(v) db.showRange = v end)
    local _, cy = W.CreateSlider(card2.inner, L["rf_opt_oor_alpha"], db.oorAlpha, 0.10, 0.80, 0.05, cy, function(v) db.oorAlpha = v end, "%.2f")
    y = W.FinalizeCard(card2, cy)

    local card3, cy = W.CreateCard(c, L["rf_section_dispel"], y, "H")
    local _, cy = W.CreateCheckbox(card3.inner, L["rf_opt_show_dispel"], db.showDispel, cy, function(v) db.showDispel = v; ApplyRF() end)
    local _, cy = W.CreateCheckbox(card3.inner, L["rf_opt_show_dispel_border"], db.showDispelBorder ~= false, cy, function(v) db.showDispelBorder = v; ApplyRF() end)
    local _, cy = W.CreateCheckbox(card3.inner, L["rf_opt_show_dispel_icon"], db.showDispelIcon ~= false, cy, function(v) db.showDispelIcon = v; ApplyRF() end)
    local _, cy = W.CreateCheckbox(card3.inner, L["rf_opt_show_dispel_bleed"], db.showDispelBleed ~= false, cy, function(v) db.showDispelBleed = v; ApplyRF() end)
    local _, cy = W.CreateSlider(card3.inner, L["rf_opt_dispel_size"], db.dispelSize or 18, 10, 28, 1, cy, function(v) db.dispelSize = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateSlider(card3.inner, L["rf_opt_dispel_border_size"], db.dispelBorderSize or 2, 1, 5, 1, cy, function(v) db.dispelBorderSize = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateInfoText(card3.inner, L["rf_info_dispel"], cy)
    y = W.FinalizeCard(card3, cy)

    local card4, cy = W.CreateCard(c, L["rf_section_hots"], y, "H")
    local _, cy = W.CreateCheckbox(card4.inner, L["rf_opt_show_hots"], db.showHoTs, cy, function(v) db.showHoTs = v; ApplyRF() end)
    local _, cy = W.CreateSlider(card4.inner, L["rf_opt_hot_size"], db.hotSize, 6, 50, 1, cy, function(v) db.hotSize = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateSlider(card4.inner, L["rf_opt_max_hots"], db.maxHoTs, 1, 4, 1, cy, function(v) db.maxHoTs = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateCheckbox(card4.inner, L["rf_opt_hot_duration"], db.hotShowDuration ~= false, cy, function(v) db.hotShowDuration = v; ApplyRF() end)
    -- See PartyFrames.lua: the studio is the advanced path for this row.
    local _, cy = W.CreateSeparator(card4.inner, cy)
    local _, cy = W.CreateButton(card4.inner, L["btn_open_healerstudio"], 240, cy, function()
        TomoMod_OpenHealerStudio("raid")
    end)
    local _, cy = W.CreateInfoText(card4.inner, L["info_healerstudio"], cy)
    y = W.FinalizeCard(card4, cy)

    local card5, cy = W.CreateCard(c, L["rf_section_debuffs"], y, "H")
    local _, cy = W.CreateCheckbox(card5.inner, L["rf_opt_show_debuffs"], db.showDebuffs, cy, function(v) db.showDebuffs = v; ApplyRF() end)
    local _, cy = W.CreateSlider(card5.inner, L["rf_opt_debuff_size"], db.debuffSize or 18, 10, 28, 1, cy, function(v) db.debuffSize = v end, "%.0f")
    local _, cy = W.CreateSlider(card5.inner, L["rf_opt_max_debuffs"], db.maxDebuffs, 1, 5, 1, cy, function(v) db.maxDebuffs = v end, "%.0f")
    y = W.FinalizeCard(card5, cy)

    local card6, cy = W.CreateCard(c, L["rf_section_defensives"], y, "TH")
    local _, cy = W.CreateCheckbox(card6.inner, L["rf_opt_show_defensives"], db.showDefensives, cy, function(v) db.showDefensives = v; ApplyRF() end)
    local _, cy = W.CreateSlider(card6.inner, L["rf_opt_defensive_size"], db.defensiveIconSize, 10, 22, 1, cy, function(v) db.defensiveIconSize = v; ApplyRF() end, "%.0f")
    local _, cy = W.CreateSlider(card6.inner, L["rf_opt_max_defensives"], db.maxDefensives or 2, 1, 4, 1, cy, function(v) db.maxDefensives = v; if TomoMod_Lifecycle then TomoMod_Lifecycle.RequestReload("raidFrames") end end)
    local _, cy = W.CreateCheckbox(card6.inner, L["rf_opt_def_externals"], db.defensiveShowExternals ~= false, cy, function(v) db.defensiveShowExternals = v; ApplyRF() end)
    local _, cy = W.CreateCheckbox(card6.inner, L["rf_opt_def_raidwide"], db.defensiveShowRaidWide == true, cy, function(v) db.defensiveShowRaidWide = v; ApplyRF() end)
    local _, cy = W.CreateCheckbox(card6.inner, L["rf_opt_def_personals"], db.defensiveShowPersonals == true, cy, function(v) db.defensiveShowPersonals = v; ApplyRF() end)
    local _, cy = W.CreateInfoText(card6.inner, L["rf_info_defensives"], cy)
    y = W.FinalizeCard(card6, cy)

    -- Resurrection indicator
    local cardRez, cy = W.CreateCard(c, L["rf_section_resurrect"], y, "H")
    local _, cy = W.CreateCheckbox(cardRez.inner, L["rf_opt_show_resurrect"], db.showResurrectIndicator, cy, function(v) db.showResurrectIndicator = v; ApplyRT() end)
    local _, cy = W.CreateSlider(cardRez.inner, L["rf_opt_resurrect_size"], db.resurrectIconSize or 22, 12, 40, 1, cy, function(v) db.resurrectIconSize = v; ApplyRT() end, "%.0f")
    local _, cy = W.CreateInfoText(cardRez.inner, L["rf_info_resurrect"], cy)
    y = W.FinalizeCard(cardRez, cy)

    -- Battle Rez counter (shared combat-res pool)
    local brdb = TomoModDB.battleRez
    if brdb then
        local cardBR, cy = W.CreateCard(c, L["rf_section_battlerez"], y, "H")
        local _, cy = W.CreateCheckbox(cardBR.inner, L["rf_opt_br_enable"], brdb.enabled, cy, function(v) brdb.enabled = v; ApplyRT() end)
        local _, cy = W.CreateCheckbox(cardBR.inner, L["rf_opt_br_only_instance"], brdb.onlyInstance, cy, function(v) brdb.onlyInstance = v; ApplyRT() end)
        local _, cy = W.CreateSlider(cardBR.inner, L["rf_opt_br_size"], brdb.size or 44, 24, 96, 1, cy, function(v) brdb.size = v; ApplyRT() end, "%.0f")
        local _, cy = W.CreateSlider(cardBR.inner, L["rf_opt_br_font"], brdb.fontSize or 18, 10, 32, 1, cy, function(v) brdb.fontSize = v; ApplyRT() end, "%.0f")
        local _, cy = W.CreateInfoText(cardBR.inner, L["rf_info_battlerez"], cy)
        y = W.FinalizeCard(cardBR, cy)
    end

    -- Per-size layout overrides (10 / 25 / 40)
    local ov = db.raidSizeOverrides
    if ov then
        ov["10"] = ov["10"] or {}; ov["25"] = ov["25"] or {}; ov["40"] = ov["40"] or {}
        local cardOv, cy = W.CreateCard(c, L["rf_section_size_overrides"], y)
        local _, cy = W.CreateCheckbox(cardOv.inner, L["rf_opt_overrides_enable"], ov.enabled, cy, function(v) ov.enabled = v; ApplyRF() end)
        local _, cy = W.CreateInfoText(cardOv.inner, L["rf_info_size_overrides"], cy)
        local _, cy = W.CreateInfoText(cardOv.inner, L["rf_ov_small"], cy)
        local _, cy = W.CreateSlider(cardOv.inner, L["rf_ov_width"], ov["10"].width or db.width, 40, 200, 2, cy, function(v) ov["10"].width = v; ApplyRF() end, "%.0f")
        local _, cy = W.CreateSlider(cardOv.inner, L["rf_ov_height"], ov["10"].height or db.height, 20, 80, 1, cy, function(v) ov["10"].height = v; ApplyRF() end, "%.0f")
        local _, cy = W.CreateInfoText(cardOv.inner, L["rf_ov_medium"], cy)
        local _, cy = W.CreateSlider(cardOv.inner, L["rf_ov_width"], ov["25"].width or db.width, 40, 200, 2, cy, function(v) ov["25"].width = v; ApplyRF() end, "%.0f")
        local _, cy = W.CreateSlider(cardOv.inner, L["rf_ov_height"], ov["25"].height or db.height, 20, 80, 1, cy, function(v) ov["25"].height = v; ApplyRF() end, "%.0f")
        local _, cy = W.CreateInfoText(cardOv.inner, L["rf_ov_large"], cy)
        local _, cy = W.CreateSlider(cardOv.inner, L["rf_ov_width"], ov["40"].width or db.width, 40, 200, 2, cy, function(v) ov["40"].width = v; ApplyRF() end, "%.0f")
        local _, cy = W.CreateSlider(cardOv.inner, L["rf_ov_height"], ov["40"].height or db.height, 20, 80, 1, cy, function(v) ov["40"].height = v; ApplyRF() end, "%.0f")
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
        { key = "general",  label = L["rf_tab_general"],  builder = BuildGeneralTab  },
        { key = "features", label = L["rf_tab_features"], builder = BuildFeaturesTab },
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

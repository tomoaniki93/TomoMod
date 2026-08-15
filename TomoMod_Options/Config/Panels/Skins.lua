-- =====================================
-- Skins.lua — Config Panel for Skins category
-- Top-level tabs: Chat Frame, Bags, Obj. Tracker, Character,
--                 Buffs, Game Menu, Mail
-- Migrates all skin settings from the QOL tab into a dedicated section.
-- =====================================

local L = TomoMod_L
local W = TomoMod_Widgets
local T = W.Theme

-- =====================================================================
-- TAB: CHAT FRAME (v2 — tabbed standalone chat panel)
-- =====================================================================

local function BuildChatFrameTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_chat_skin"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_enable"], TomoModDB.chatFrameSkin.enabled, y, function(v)
        TomoModDB.chatFrameSkin.enabled = v
        if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateSegmentedControl(c, L["opt_chat_skin_style"], {
        { text = L["opt_chat_skin_style_tui"],     value = "tui" },
        { text = L["opt_chat_skin_style_classic"],  value = "classic" },
        { text = L["opt_chat_skin_style_glass"],    value = "glass" },
        { text = L["opt_chat_skin_style_minimal"],  value = "minimal" },
    }, TomoModDB.chatFrameSkin.skinStyle or "tui", y, function(v)
        TomoModDB.chatFrameSkin.skinStyle = v
        if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.ApplySettings() end
    end, 2)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_chat_skin_bg_alpha"], (TomoModDB.chatFrameSkin.bgAlpha or 0.70) * 100, 0, 100, 5, y, function(v)
        TomoModDB.chatFrameSkin.bgAlpha = v / 100
        if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.ApplySettings() end
    end, "%.0f%%")
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_chat_skin_font_size"], TomoModDB.chatFrameSkin.fontSize or 13, 9, 18, 1, y, function(v)
        TomoModDB.chatFrameSkin.fontSize = v
        if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.ApplySettings() end
    end)
    y = ny

    -- New settings
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_fade"], TomoModDB.chatFrameSkin.fade, y, function(v)
        TomoModDB.chatFrameSkin.fade = v
        if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_short_channels"], TomoModDB.chatFrameSkin.shortChannelNames, y, function(v)
        TomoModDB.chatFrameSkin.shortChannelNames = v
        if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_timestamp"], TomoModDB.chatFrameSkin.showTimestamp, y, function(v)
        TomoModDB.chatFrameSkin.showTimestamp = v
        if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_url"], TomoModDB.chatFrameSkin.findURL, y, function(v)
        TomoModDB.chatFrameSkin.findURL = v
        if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_emoji"], TomoModDB.chatFrameSkin.emoji, y, function(v)
        TomoModDB.chatFrameSkin.emoji = v
        if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_class_colors"], TomoModDB.chatFrameSkin.classColorMentions, y, function(v)
        TomoModDB.chatFrameSkin.classColorMentions = v
        if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_chat_copy_button"], {
        { text = L["opt_chat_copy_button_always"], value = "always" },
        { text = L["opt_chat_copy_button_hover"],  value = "hover"  },
        { text = L["opt_chat_copy_button_hidden"], value = "hidden" },
    }, TomoModDB.chatFrameSkin.copyButtonMode or "hover", y, function(v)
        TomoModDB.chatFrameSkin.copyButtonMode = v
        if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.ApplySettings() end
    end)
    y = ny

    -- ── Historique du chat ────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["chat_history_section"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_history"], TomoModDB.chatFrameSkin.chatHistory, y, function(v)
        TomoModDB.chatFrameSkin.chatHistory = v
        if TomoMod_ChatFrameSkin then
            if TomoMod_ChatFrameSkin.ApplyHistorySettings then TomoMod_ChatFrameSkin.ApplyHistorySettings() end
            TomoMod_ChatFrameSkin.ApplySettings()
        end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["opt_chat_skin_history_info"], y)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_chat_history_max_age"], {
        { text = L["opt_chat_history_age_1h"],        value = 3600 },
        { text = L["opt_chat_history_age_6h"],        value = 21600 },
        { text = L["opt_chat_history_age_24h"],       value = 86400 },
        { text = L["opt_chat_history_age_3d"],        value = 259200 },
        { text = L["opt_chat_history_age_unlimited"], value = 0 },
    }, TomoModDB.chatFrameSkin.historyMaxAge or 21600, y, function(v)
        TomoModDB.chatFrameSkin.historyMaxAge = v
        if TomoMod_ChatFrameSkin and TomoMod_ChatFrameSkin.ApplyHistorySettings then
            TomoMod_ChatFrameSkin.ApplyHistorySettings()
        end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_chat_history_max_lines"], TomoModDB.chatFrameSkin.historyMaxLines or 128, 10, 500, 10, y, function(v)
        TomoModDB.chatFrameSkin.historyMaxLines = v
        if TomoMod_ChatFrameSkin and TomoMod_ChatFrameSkin.ApplyHistorySettings then
            TomoMod_ChatFrameSkin.ApplyHistorySettings()
        end
    end, "%.0f")
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_chat_history_delay"], TomoModDB.chatFrameSkin.historyDelay or 2, 0, 10, 0.5, y, function(v)
        TomoModDB.chatFrameSkin.historyDelay = v
    end, "%.1fs")
    y = ny

    local _, ny = W.CreateInfoText(c, L["opt_chat_history_delay_info"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_history_separator"], TomoModDB.chatFrameSkin.historySeparator ~= false, y, function(v)
        TomoModDB.chatFrameSkin.historySeparator = v
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["opt_chat_history_separator_info"], y)
    y = ny

    -- Per-channel replay filter. The setting already existed in the DB but
    -- had never been exposed.
    local _, ny = W.CreateSubLabel(c, L["sublabel_chat_history_channels"], y)
    y = ny

    TomoModDB.chatFrameSkin.showHistory = TomoModDB.chatFrameSkin.showHistory or {}
    local sh = TomoModDB.chatFrameSkin.showHistory

    local CHANNEL_ROWS = {
        { "WHISPER",  "opt_chat_history_ch_whisper",  "GUILD",    "opt_chat_history_ch_guild"   },
        { "OFFICER",  "opt_chat_history_ch_officer",  "PARTY",    "opt_chat_history_ch_party"   },
        { "RAID",     "opt_chat_history_ch_raid",     "INSTANCE", "opt_chat_history_ch_instance"},
        { "CHANNEL",  "opt_chat_history_ch_channel",  "SAY",      "opt_chat_history_ch_say"     },
        { "YELL",     "opt_chat_history_ch_yell",     "EMOTE",    "opt_chat_history_ch_emote"   },
    }
    for _, row in ipairs(CHANNEL_ROWS) do
        local keyA, lblA, keyB, lblB = row[1], row[2], row[3], row[4]
        local _, rowY = W.CreateCheckboxPair(c,
            L[lblA], sh[keyA] == true, y, function(v) sh[keyA] = v end,
            L[lblB], sh[keyB] == true,    function(v) sh[keyB] = v end)
        y = rowY
    end

    local _, ny = W.CreateButton(c, L["btn_chat_history_clear"], 260, y, function()
        StaticPopup_Show("TOMOMOD_CLEAR_CHAT_HISTORY")
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

--[[ Chat Frame UI (multi-position containers — MayronUI style) — disabled for now
    TomoModDB.chatFrameUI = TomoModDB.chatFrameUI or {}
    local cfuiDB = TomoModDB.chatFrameUI

    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_chatframeui"], y); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_cfui_enable"], cfuiDB.enabled, y, function(v)
        cfuiDB.enabled = v
        if TomoMod_ChatFrameUI then TomoMod_ChatFrameUI.SetEnabled(v) end
    end); y = ny

    -- Per-anchor frame toggles
    local anchors = {
        { key = "TOPLEFT",     label = L["opt_cfui_frame_topleft"] },
        { key = "TOPRIGHT",    label = L["opt_cfui_frame_topright"] },
        { key = "BOTTOMLEFT",  label = L["opt_cfui_frame_bottomleft"] },
        { key = "BOTTOMRIGHT", label = L["opt_cfui_frame_bottomright"] },
    }
    for _, a in ipairs(anchors) do
        cfuiDB.chatFrames = cfuiDB.chatFrames or {}
        cfuiDB.chatFrames[a.key] = cfuiDB.chatFrames[a.key] or {}
        local fs = cfuiDB.chatFrames[a.key]
        local _, ny = W.CreateCheckbox(c, a.label, fs.enabled, y, function(v)
            fs.enabled = v
            if TomoMod_ChatFrameUI then TomoMod_ChatFrameUI.ApplySettings() end
        end); y = ny
    end

    local _, ny = W.CreateSeparator(c, y); y = ny

    -- Icons anchor
    local _, ny = W.CreateDropdown(c, L["opt_cfui_icons_anchor"], {
        { text = "Top-Left",     value = "TOPLEFT" },
        { text = "Top-Right",    value = "TOPRIGHT" },
        { text = "Bottom-Left",  value = "BOTTOMLEFT" },
        { text = "Bottom-Right", value = "BOTTOMRIGHT" },
    }, cfuiDB.iconsAnchor or "TOPLEFT", y, function(v)
        cfuiDB.iconsAnchor = v
        if TomoMod_ChatFrameUI then TomoMod_ChatFrameUI.RefreshSideBarIcons() end
    end); y = ny

    -- Edit box position
    local _, ny = W.CreateDropdown(c, L["opt_cfui_editbox_position"], {
        { text = "Top",    value = "TOP" },
        { text = "Bottom", value = "BOTTOM" },
    }, (cfuiDB.editBox and cfuiDB.editBox.position) or "BOTTOM", y, function(v)
        cfuiDB.editBox = cfuiDB.editBox or {}
        cfuiDB.editBox.position = v
        if TomoMod_ChatFrameUI then TomoMod_ChatFrameUI.ApplySettings() end
    end); y = ny

    -- Edit box height
    local _, ny = W.CreateSlider(c, L["opt_cfui_editbox_height"], (cfuiDB.editBox and cfuiDB.editBox.height) or 27, 20, 50, 1, y, function(v)
        cfuiDB.editBox = cfuiDB.editBox or {}
        cfuiDB.editBox.height = v
        if TomoMod_ChatFrameUI then TomoMod_ChatFrameUI.ApplySettings() end
    end); y = ny

    -- Raid frame manager
    local _, ny = W.CreateCheckbox(c, L["opt_cfui_raid_frame_mgr"], cfuiDB.raidFrameManager ~= false, y, function(v)
        cfuiDB.raidFrameManager = v
    end); y = ny

    -- Swap buttons in combat
    local _, ny = W.CreateCheckbox(c, L["opt_cfui_swap_in_combat"], cfuiDB.swapInCombat, y, function(v)
        cfuiDB.swapInCombat = v
    end); y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
--]]

-- =====================================================================
-- TAB: BAGS
-- =====================================================================

local function BuildBagsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_skin_bags"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_skin_bags_desc"], y)
    y = ny

    local db = TomoModDB.bagSkin
    if not db then
        TomoModDB.bagSkin = {}
        db = TomoModDB.bagSkin
    end

    -- Enable
    local _, ny = W.CreateCheckbox(c, L["opt_skin_bags_enable"], db.enabled, y, function(v)
        db.enabled = v
        if TomoMod_BagSkin then TomoMod_BagSkin.SetEnabled(v) end
    end)
    y = ny

    -- Layout mode (GW2_UI-inspired: combined / categories / separate bags)
    local _, ny = W.CreateSegmentedControl(c, (L and L["opt_skin_bags_layout_mode"]) or "Layout Mode", {
        { text = (L and L["opt_skin_bags_layout_combined"])   or "Combined Grid",  value = "combined" },
        { text = (L and L["opt_skin_bags_layout_separate"])   or "Separate Bags",  value = "separateBags" },
    }, db.layoutMode or "combined", y, function(v)
        db.layoutMode = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end, 2)
    y = ny

    -- Sort mode
    local _, ny = W.CreateSegmentedControl(c, L["opt_skin_bags_sort_mode"], {
        { text = L["opt_skin_bags_sort_none"],    value = "none" },
        { text = L["opt_skin_bags_sort_quality"], value = "quality" },
        { text = L["opt_skin_bags_sort_name"],    value = "name" },
        { text = L["opt_skin_bags_sort_type"],    value = "type" },
        { text = L["opt_skin_bags_sort_ilvl"],    value = "ilvl" },
        { text = L["opt_skin_bags_sort_recent"],  value = "recent" },
    }, db.sortMode or "quality", y, function(v)
        db.sortMode = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end, 3)
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    -- Slot size (GW2_UI: BAG_ITEM_SIZE 26–48)
    local _, ny = W.CreateSlider(c, L["opt_skin_bags_slot_size"], db.slotSize or 40, 26, 48, 1, y, function(v)
        db.slotSize = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    -- Slot spacing X (GW2_UI-style separate X/Y)
    local _, ny = W.CreateSlider(c, (L and L["opt_skin_bags_slot_spacing_x"]) or "Slot Spacing X", db.slotSpacingX or 5, 0, 20, 1, y, function(v)
        db.slotSpacingX = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    -- Slot spacing Y
    local _, ny = W.CreateSlider(c, (L and L["opt_skin_bags_slot_spacing_y"]) or "Slot Spacing Y", db.slotSpacingY or 5, 0, 20, 1, y, function(v)
        db.slotSpacingY = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    -- Scale
    local _, ny = W.CreateSlider(c, L["opt_skin_bags_scale"], db.scale or 100, 50, 200, 5, y, function(v)
        db.scale = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end, "%.0f%%")
    y = ny

    -- Opacity
    local _, ny = W.CreateSlider(c, L["opt_skin_bags_opacity"], db.opacity or 92, 0, 100, 5, y, function(v)
        db.opacity = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end, "%.0f%%")
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    -- Visual options
    local _, ny = W.CreateCheckbox(c, L["opt_skin_bags_quality_borders"], db.showQualityBorders ~= false, y, function(v)
        db.showQualityBorders = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, (L and L["opt_skin_bags_show_ilvl"]) or "Show Item Level", db.showItemLevel == true, y, function(v)
        db.showItemLevel = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, (L and L["opt_skin_bags_show_junk_icon"]) or "Show Junk Icon", db.showJunkIcon == true, y, function(v)
        db.showJunkIcon = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_skin_bags_cooldowns"], db.showCooldowns ~= false, y, function(v)
        db.showCooldowns = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_skin_bags_quantity"], db.showQuantityBadges ~= false, y, function(v)
        db.showQuantityBadges = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_skin_bags_search"], db.showSearchBar ~= false, y, function(v)
        db.showSearchBar = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    -- Feature toggles
    local _, ny = W.CreateCheckbox(c, L["opt_skin_bags_stack_merge"], db.stackMerge == true, y, function(v)
        db.stackMerge = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_skin_bags_show_empty"], db.showEmptySlots ~= false, y, function(v)
        db.showEmptySlots = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_skin_bags_show_recent"], db.showRecentItems ~= false, y, function(v)
        db.showRecentItems = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, (L and L["opt_skin_bags_reverse_order"]) or "Reverse Bag Order", db.reverseBagOrder == true, y, function(v)
        db.reverseBagOrder = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, (L and L["opt_skin_bags_show_bag_bar"]) or "Show Bag Bar", db.showBagBar ~= false, y, function(v)
        db.showBagBar = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    -- Footer options
    local _, ny = W.CreateCheckbox(c, L["opt_skin_bags_show_gold"], db.showGold ~= false, y, function(v)
        db.showGold = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_skin_bags_show_currencies"], db.showCurrencies == true, y, function(v)
        db.showCurrencies = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB: OBJECTIVE TRACKER SKIN
-- =====================================

local function BuildObjectiveTrackerTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_obj_tracker"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_obj_tracker"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_obj_tracker_enable"], TomoModDB.objectiveTracker.enabled, y, function(v)
        if TomoMod_ObjectiveTracker then TomoMod_ObjectiveTracker.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_obj_tracker_bg_alpha"], TomoModDB.objectiveTracker.bgAlpha, 0, 1, 0.05, y, function(v)
        TomoModDB.objectiveTracker.bgAlpha = v
        if TomoMod_ObjectiveTracker then TomoMod_ObjectiveTracker.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_obj_tracker_border"], TomoModDB.objectiveTracker.showBorder, y, function(v)
        TomoModDB.objectiveTracker.showBorder = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_obj_tracker_hide_empty"], TomoModDB.objectiveTracker.hideWhenEmpty, y, function(v)
        TomoModDB.objectiveTracker.hideWhenEmpty = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_obj_tracker_buckets"], TomoModDB.objectiveTracker.buckets, y, function(v)
        TomoModDB.objectiveTracker.buckets = v
        if TomoMod_ObjectiveTracker then TomoMod_ObjectiveTracker.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_obj_tracker_header_size"], TomoModDB.objectiveTracker.headerFontSize, 8, 20, 1, y, function(v)
        TomoModDB.objectiveTracker.headerFontSize = v
        if TomoMod_ObjectiveTracker then TomoMod_ObjectiveTracker.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_obj_tracker_cat_size"], TomoModDB.objectiveTracker.categoryFontSize, 8, 18, 1, y, function(v)
        TomoModDB.objectiveTracker.categoryFontSize = v
        if TomoMod_ObjectiveTracker then TomoMod_ObjectiveTracker.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_obj_tracker_quest_size"], TomoModDB.objectiveTracker.questFontSize, 8, 18, 1, y, function(v)
        TomoModDB.objectiveTracker.questFontSize = v
        if TomoMod_ObjectiveTracker then TomoMod_ObjectiveTracker.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_obj_tracker_obj_size"], TomoModDB.objectiveTracker.objectiveFontSize, 8, 16, 1, y, function(v)
        TomoModDB.objectiveTracker.objectiveFontSize = v
        if TomoMod_ObjectiveTracker then TomoMod_ObjectiveTracker.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_obj_tracker_max_quests"], TomoModDB.objectiveTracker.maxQuestsShown, 0, 25, 1, y, function(v)
        TomoModDB.objectiveTracker.maxQuestsShown = v
        if TomoMod_ObjectiveTracker then TomoMod_ObjectiveTracker.ApplySettings() end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB: CHARACTER SKIN
-- =====================================

local function BuildCharacterSkinTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_char_skin"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_char_skin_desc"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_char_skin_enable"], TomoModDB.characterSkin.enabled, y, function(v)
        TomoModDB.characterSkin.enabled = v
        if TomoMod_CharacterSkin then TomoMod_CharacterSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_char_skin_character"], TomoModDB.characterSkin.skinCharacter, y, function(v)
        TomoModDB.characterSkin.skinCharacter = v
        if TomoMod_CharacterSkin then TomoMod_CharacterSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_char_skin_inspect"], TomoModDB.characterSkin.skinInspect, y, function(v)
        TomoModDB.characterSkin.skinInspect = v
        if TomoMod_CharacterSkin then TomoMod_CharacterSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_char_skin_iteminfo"], TomoModDB.characterSkin.showItemInfo, y, function(v)
        TomoModDB.characterSkin.showItemInfo = v
        if TomoMod_CharacterSkin then TomoMod_CharacterSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_char_skin_gems"], TomoModDB.characterSkin.showGems, y, function(v)
        TomoModDB.characterSkin.showGems = v
        if TomoMod_CharacterSkin then TomoMod_CharacterSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_char_skin_midnight"], TomoModDB.characterSkin.midnightEnchants, y, function(v)
        TomoModDB.characterSkin.midnightEnchants = v
        if TomoMod_CharacterSkin then TomoMod_CharacterSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_char_skin_scale"], (TomoModDB.characterSkin.scale or 1.0) * 100, 70, 150, 5, y, function(v)
        local scale = v / 100
        TomoModDB.characterSkin.scale = scale
        -- Apply scale live
        if _G.CharacterFrame then
            _G.CharacterFrame:SetScale(scale)
        end
        if _G.InspectFrame then
            _G.InspectFrame:SetScale(scale)
        end
    end, "%.0f%%")
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    -- Fenetre Personnage deplacable
    local _, ny = W.CreateCheckbox(c, L["opt_char_skin_movable"], TomoModDB.characterSkin.movable or false, y, function(v)
        TomoModDB.characterSkin.movable = v
        if TomoMod_CharacterSkin and TomoMod_CharacterSkin.SetMovable then TomoMod_CharacterSkin.SetMovable(v) end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_char_skin_movable"], y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_char_skin_reset_pos"], 220, y, function()
        if TomoMod_CharacterSkin and TomoMod_CharacterSkin.ResetCharacterPosition then TomoMod_CharacterSkin.ResetCharacterPosition() end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end
local function BuildGameMenuSkinTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["sublabel_game_menu_skin"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_game_menu_skin_enable"], TomoModDB.gameMenuSkin.enabled, y, function(v)
        TomoModDB.gameMenuSkin.enabled = v
        if TomoMod_GameMenuSkin then TomoMod_GameMenuSkin.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_game_menu_skin_reload"], y)
    y = ny
    
    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

--[[local function BuildMailSkinTab(parent)
    if _G.TomoMod_BuildMailSkinTab then
        return _G.TomoMod_BuildMailSkinTab(parent)
    end
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local _, ny = W.CreateInfoText(c, "Mail skin (configured in QOL > Skins).", -10)
    c:SetHeight(60)
    return scroll
end]]

-- =====================================================================
-- TAB: TOOLTIP
-- =====================================================================

local function BuildTooltipSkinTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_tooltip_skin"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_skin_enable"], TomoModDB.tooltipSkin.enabled, y, function(v)
        TomoModDB.tooltipSkin.enabled = v
        if TomoMod_TooltipSkin then TomoMod_TooltipSkin.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_tooltip_skin_reload"], y)
    y = ny

    -- Background alpha
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSlider(c, L["opt_tooltip_bg_alpha"], (TomoModDB.tooltipSkin.bgAlpha or 0.92) * 100, 0, 100, 5, y, function(v)
        TomoModDB.tooltipSkin.bgAlpha = v / 100
    end, "%.0f%%")
    y = ny

    -- Border alpha
    local _, ny = W.CreateSlider(c, L["opt_tooltip_border_alpha"], (TomoModDB.tooltipSkin.borderAlpha or 0.8) * 100, 0, 100, 5, y, function(v)
        TomoModDB.tooltipSkin.borderAlpha = v / 100
    end, "%.0f%%")
    y = ny

    -- Couleur du fond / de la bordure (configurable pour éviter que le fond se fonde dans le décor)
    if not TomoModDB.tooltipSkin.bgColor then TomoModDB.tooltipSkin.bgColor = { r = 0.06, g = 0.06, b = 0.08 } end
    local _, ny = W.CreateColorPicker(c, L["opt_tooltip_bg_color"], TomoModDB.tooltipSkin.bgColor, y, function(r, g, b)
        TomoModDB.tooltipSkin.bgColor.r = r
        TomoModDB.tooltipSkin.bgColor.g = g
        TomoModDB.tooltipSkin.bgColor.b = b
    end)
    y = ny

    if not TomoModDB.tooltipSkin.borderColor then TomoModDB.tooltipSkin.borderColor = { r = 0.20, g = 0.20, b = 0.24 } end
    local _, ny = W.CreateColorPicker(c, L["opt_tooltip_border_color"], TomoModDB.tooltipSkin.borderColor, y, function(r, g, b)
        TomoModDB.tooltipSkin.borderColor.r = r
        TomoModDB.tooltipSkin.borderColor.g = g
        TomoModDB.tooltipSkin.borderColor.b = b
    end)
    y = ny

    -- Position de l'infobulle (defaut / souris / coin / personnalise)
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateDropdown(c, L["opt_tooltip_anchor"], {
        { text = L["tooltip_anchor_default"],          value = "default" },
        { text = L["tooltip_anchor_cursor"],          value = "cursor"  },
        { text = L["tooltip_anchor_corner"], value = "corner"  },
        { text = L["tooltip_anchor_custom"],    value = "custom"  },
    }, TomoModDB.tooltipSkin.anchor or "default", y, function(v)
        TomoModDB.tooltipSkin.anchor = v
        if TomoMod_TooltipSkin and TomoMod_TooltipSkin.RefreshAnchor then TomoMod_TooltipSkin.RefreshAnchor() end
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_tooltip_anchor_corner"], {
        { text = L["corner_br"],  value = "BOTTOMRIGHT" },
        { text = L["corner_bl"],  value = "BOTTOMLEFT"  },
        { text = L["corner_tr"], value = "TOPRIGHT"    },
        { text = L["corner_tl"], value = "TOPLEFT"     },
    }, TomoModDB.tooltipSkin.anchorCorner or "BOTTOMRIGHT", y, function(v)
        TomoModDB.tooltipSkin.anchorCorner = v
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_tooltip_anchor"], y)
    y = ny

    -- [FIX] Le repere teal restait affiche en permanence des que le mode
    -- "Personnalise" etait choisi, meme en dehors de tout mode d'edition.
    -- Il est desormais cache par defaut (comme les autres reperes de l'addon,
    -- geres par le bouton Layout) ; ce bouton permet de l'afficher/masquer a
    -- la demande sans avoir a ouvrir le panneau Layout complet.
    local _, ny = W.CreateButton(c, L["btn_tooltip_toggle_anchor"], 220, y, function()
        if TomoMod_TooltipSkin and TomoMod_TooltipSkin.ToggleLock then
            TomoMod_TooltipSkin.ToggleLock()
        end
    end)
    y = ny

    -- Font size
    local _, ny = W.CreateSlider(c, L["opt_tooltip_font_size"], TomoModDB.tooltipSkin.fontSize or 12, 9, 18, 1, y, function(v)
        TomoModDB.tooltipSkin.fontSize = v
    end)
    y = ny

    -- Hide health bar
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_hide_healthbar"], TomoModDB.tooltipSkin.hideHealthBar, y, function(v)
        TomoModDB.tooltipSkin.hideHealthBar = v
    end)
    y = ny

    -- Class color names
    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_class_color"], TomoModDB.tooltipSkin.useClassColorNames, y, function(v)
        TomoModDB.tooltipSkin.useClassColorNames = v
    end)
    y = ny

    -- Hide server
    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_hide_server"], TomoModDB.tooltipSkin.hidePlayerServer, y, function(v)
        TomoModDB.tooltipSkin.hidePlayerServer = v
    end)
    y = ny

    -- Hide title
    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_hide_title"], TomoModDB.tooltipSkin.hidePlayerTitle, y, function(v)
        TomoModDB.tooltipSkin.hidePlayerTitle = v
    end)
    y = ny

    -- Guild name color
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_guild_color"], TomoModDB.tooltipSkin.useGuildNameColor, y, function(v)
        TomoModDB.tooltipSkin.useGuildNameColor = v
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["opt_tooltip_guild_color_pick"], TomoModDB.tooltipSkin.guildNameColor, y, function(r, g, b)
        TomoModDB.tooltipSkin.guildNameColor.r = r
        TomoModDB.tooltipSkin.guildNameColor.g = g
        TomoModDB.tooltipSkin.guildNameColor.b = b
    end)
    y = ny

    -- ─────────────────────────────────────────────
    -- Unit information (TooltipInfo)
    -- ─────────────────────────────────────────────
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_tooltip_info"], y); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_unit_info"], TomoModDB.tooltipSkin.showUnitInfo ~= false, y, function(v)
        TomoModDB.tooltipSkin.showUnitInfo = v
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_tooltip_unit_info"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_reaction_border"], TomoModDB.tooltipSkin.reactionBorder ~= false, y, function(v)
        TomoModDB.tooltipSkin.reactionBorder = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_color_level"], TomoModDB.tooltipSkin.colorTooltipLevel ~= false, y, function(v)
        TomoModDB.tooltipSkin.colorTooltipLevel = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_raid_marker"], TomoModDB.tooltipSkin.showTooltipRaidMarker ~= false, y, function(v)
        TomoModDB.tooltipSkin.showTooltipRaidMarker = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_role_icon"], TomoModDB.tooltipSkin.showTooltipRoleIcon ~= false, y, function(v)
        TomoModDB.tooltipSkin.showTooltipRoleIcon = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_class_icon"], TomoModDB.tooltipSkin.showTooltipClassIcon, y, function(v)
        TomoModDB.tooltipSkin.showTooltipClassIcon = v
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_tooltip_icon_size"], TomoModDB.tooltipSkin.infoIconSize or 14, 8, 24, 1, y, function(v)
        TomoModDB.tooltipSkin.infoIconSize = v
    end, "%.0f")
    y = ny

    local _, ny = W.CreateSeparator(c, y); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_guild_rank"], TomoModDB.tooltipSkin.showTooltipGuildRank ~= false, y, function(v)
        TomoModDB.tooltipSkin.showTooltipGuildRank = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_guild_rank_index"], TomoModDB.tooltipSkin.showTooltipGuildRankIndex, y, function(v)
        TomoModDB.tooltipSkin.showTooltipGuildRankIndex = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_guild_realm"], TomoModDB.tooltipSkin.showTooltipGuildRealm ~= false, y, function(v)
        TomoModDB.tooltipSkin.showTooltipGuildRealm = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_show_target"], TomoModDB.tooltipSkin.showTooltipTarget ~= false, y, function(v)
        TomoModDB.tooltipSkin.showTooltipTarget = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_mythic_score"], TomoModDB.tooltipSkin.showTooltipMythicScore ~= false, y, function(v)
        TomoModDB.tooltipSkin.showTooltipMythicScore = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_mount"], TomoModDB.tooltipSkin.showTooltipMount ~= false, y, function(v)
        TomoModDB.tooltipSkin.showTooltipMount = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_speed"], TomoModDB.tooltipSkin.showTooltipSpeed, y, function(v)
        TomoModDB.tooltipSkin.showTooltipSpeed = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_location"], TomoModDB.tooltipSkin.showTooltipLocation, y, function(v)
        TomoModDB.tooltipSkin.showTooltipLocation = v
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_tooltip_location"], y)
    y = ny

    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_tooltip_inspect"], y); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_item_level"], TomoModDB.tooltipSkin.showTooltipItemLevel ~= false, y, function(v)
        TomoModDB.tooltipSkin.showTooltipItemLevel = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_spec"], TomoModDB.tooltipSkin.showTooltipSpec ~= false, y, function(v)
        TomoModDB.tooltipSkin.showTooltipSpec = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_spec_icon"], TomoModDB.tooltipSkin.showTooltipSpecIcon ~= false, y, function(v)
        TomoModDB.tooltipSkin.showTooltipSpecIcon = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tooltip_pending_text"], TomoModDB.tooltipSkin.inspectPendingText ~= false, y, function(v)
        TomoModDB.tooltipSkin.inspectPendingText = v
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_tooltip_inspect"], y)
    y = ny

    -- ─────────────────────────────────────────────
    -- Tooltip IDs
    -- ─────────────────────────────────────────────
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_tooltip_ids"], y); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_enable"], TomoModDB.tooltipIDs.enabled, y, function(v)
        TomoModDB.tooltipIDs.enabled = v
        if TomoMod_TooltipIDs then TomoMod_TooltipIDs.SetEnabled(v) end
    end); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tid_spell"], TomoModDB.tooltipIDs.showSpellID, y, function(v)
        TomoModDB.tooltipIDs.showSpellID = v
    end); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tid_item"], TomoModDB.tooltipIDs.showItemID, y, function(v)
        TomoModDB.tooltipIDs.showItemID = v
    end); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tid_npc"], TomoModDB.tooltipIDs.showNPCID, y, function(v)
        TomoModDB.tooltipIDs.showNPCID = v
    end); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tid_quest"], TomoModDB.tooltipIDs.showQuestID, y, function(v)
        TomoModDB.tooltipIDs.showQuestID = v
    end); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tid_mount"], TomoModDB.tooltipIDs.showMountID, y, function(v)
        TomoModDB.tooltipIDs.showMountID = v
    end); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tid_currency"], TomoModDB.tooltipIDs.showCurrencyID, y, function(v)
        TomoModDB.tooltipIDs.showCurrencyID = v
    end); y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tid_achievement"], TomoModDB.tooltipIDs.showAchievementID, y, function(v)
        TomoModDB.tooltipIDs.showAchievementID = v
    end); y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================================================
-- MAIN PANEL ENTRY POINT
-- =====================================================================

function TomoMod_ConfigPanel_Skins(parent)
    local tabs = {
        { key = "chatframe",  label = L["tab_skin_chatframe"],  builder = function(p) return BuildChatFrameTab(p) end },
        { key = "bags",       label = L["tab_skin_bags"],       builder = function(p) return BuildBagsTab(p) end },
        { key = "objtracker", label = L["tab_skin_objtracker"], builder = function(p) return BuildObjectiveTrackerTab(p) end },
        { key = "character",  label = L["tab_skin_character"],  builder = function(p) return BuildCharacterSkinTab(p) end },
        { key = "gamemenu",   label = L["tab_skin_gamemenu"],   builder = function(p) return BuildGameMenuSkinTab(p) end },
        { key = "tooltip",    label = L["tab_skin_tooltip"],    builder = function(p) return BuildTooltipSkinTab(p) end },
        --{ key = "mail",       label = L["tab_skin_mail"],       builder = function(p) return BuildMailSkinTab(p) end },
    }

    return W.CreateTabPanel(parent, tabs)
end

-- Clearing the stored history is destructive and irreversible, so it goes
-- behind a confirmation rather than firing straight off the button.
StaticPopupDialogs["TOMOMOD_CLEAR_CHAT_HISTORY"] = {
    text = L["popup_chat_history_clear"],
    button1 = L["popup_confirm"],
    button2 = L["popup_cancel"],
    OnAccept = function()
        local n = 0
        if TomoMod_ChatFrameSkin and TomoMod_ChatFrameSkin.ClearChatHistory then
            n = TomoMod_ChatFrameSkin.ClearChatHistory() or 0
        end
        print("|cff2ed884TomoMod|r " .. string.format(L["msg_chat_history_cleared"], n))
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

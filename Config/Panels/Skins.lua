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

    local _, ny = W.CreateDropdown(c, L["opt_chat_skin_style"], {
        { text = L["opt_chat_skin_style_tui"],     value = "tui" },
        { text = L["opt_chat_skin_style_classic"],  value = "classic" },
        { text = L["opt_chat_skin_style_glass"],    value = "glass" },
        { text = L["opt_chat_skin_style_minimal"],  value = "minimal" },
    }, TomoModDB.chatFrameSkin.skinStyle or "tui", y, function(v)
        TomoModDB.chatFrameSkin.skinStyle = v
        if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.ApplySettings() end
    end)
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

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_history"], TomoModDB.chatFrameSkin.chatHistory, y, function(v)
        TomoModDB.chatFrameSkin.chatHistory = v
        if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_copy_lines"], TomoModDB.chatFrameSkin.copyChatLines, y, function(v)
        TomoModDB.chatFrameSkin.copyChatLines = v
        if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.ApplySettings() end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

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
    local _, ny = W.CreateDropdown(c, (L and L["opt_skin_bags_layout_mode"]) or "Layout Mode", {
        { text = (L and L["opt_skin_bags_layout_combined"])   or "Combined Grid",  value = "combined" },
        { text = (L and L["opt_skin_bags_layout_categories"]) or "Categories",     value = "categories" },
        { text = (L and L["opt_skin_bags_layout_separate"])   or "Separate Bags",  value = "separateBags" },
    }, db.layoutMode or "combined", y, function(v)
        db.layoutMode = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
    y = ny

    -- Sort mode
    local _, ny = W.CreateDropdown(c, L["opt_skin_bags_sort_mode"], {
        { text = L["opt_skin_bags_sort_none"],    value = "none" },
        { text = L["opt_skin_bags_sort_quality"], value = "quality" },
        { text = L["opt_skin_bags_sort_name"],    value = "name" },
        { text = L["opt_skin_bags_sort_type"],    value = "type" },
        { text = L["opt_skin_bags_sort_ilvl"],    value = "ilvl" },
        { text = L["opt_skin_bags_sort_recent"],  value = "recent" },
    }, db.sortMode or "quality", y, function(v)
        db.sortMode = v
        if TomoMod_BagSkin then TomoMod_BagSkin.ApplySettings() end
    end)
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

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

local function BuildBuffsSkinTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["sublabel_buff_skin"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_buff_skin_enable"], TomoModDB.buffSkin.enabled, y, function(v)
        TomoModDB.buffSkin.enabled = v
        if TomoMod_BuffSkin then TomoMod_BuffSkin.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_buff_skin_buffs"], TomoModDB.buffSkin.skinBuffs, y, function(v)
        TomoModDB.buffSkin.skinBuffs = v
        if TomoMod_BuffSkin then TomoMod_BuffSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_buff_skin_debuffs"], TomoModDB.buffSkin.skinDebuffs, y, function(v)
        TomoModDB.buffSkin.skinDebuffs = v
        if TomoMod_BuffSkin then TomoMod_BuffSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_buff_skin_color_by_type"], TomoModDB.buffSkin.colorByType, y, function(v)
        TomoModDB.buffSkin.colorByType = v
        if TomoMod_BuffSkin then TomoMod_BuffSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_buff_skin_teal_border"], TomoModDB.buffSkin.tealBorder, y, function(v)
        TomoModDB.buffSkin.tealBorder = v
        if TomoMod_BuffSkin then TomoMod_BuffSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_buff_skin_desaturate"], TomoModDB.buffSkin.desaturateDebuffs, y, function(v)
        TomoModDB.buffSkin.desaturateDebuffs = v
        if TomoMod_BuffSkin then TomoMod_BuffSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_buff_skin_hide_buffs"], TomoModDB.buffSkin.hideBuffFrame, y, function(v)
        TomoModDB.buffSkin.hideBuffFrame = v
        if TomoMod_BuffSkin then TomoMod_BuffSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_buff_skin_hide_debuffs"], TomoModDB.buffSkin.hideDebuffFrame, y, function(v)
        TomoModDB.buffSkin.hideDebuffFrame = v
        if TomoMod_BuffSkin then TomoMod_BuffSkin.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_buff_skin_font_size"], TomoModDB.buffSkin.fontSize or 11, 8, 20, 1, y, function(v)
        TomoModDB.buffSkin.fontSize = v
        if TomoMod_BuffSkin then TomoMod_BuffSkin.ApplySettings() end
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
        { key = "buffs",      label = L["tab_skin_buffs"],      builder = function(p) return BuildBuffsSkinTab(p) end },
        { key = "gamemenu",   label = L["tab_skin_gamemenu"],   builder = function(p) return BuildGameMenuSkinTab(p) end },
        { key = "tooltip",    label = L["tab_skin_tooltip"],    builder = function(p) return BuildTooltipSkinTab(p) end },
        --{ key = "mail",       label = L["tab_skin_mail"],       builder = function(p) return BuildMailSkinTab(p) end },
    }

    return W.CreateTabPanel(parent, tabs)
end

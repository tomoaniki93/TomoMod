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
-- TAB: CHAT FRAME V4 — live Chat V4 controls
-- =====================================================================

local function BuildChatFrameTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local Chat = TomoMod_ChatFrameSkin
    if not Chat or not Chat.GetDB then
        local _, ny = W.CreateInfoText(c, "Chat V4 unavailable.", y)
        y = ny
        c:SetHeight(math.abs(y) + 40)
        if scroll.UpdateScroll then scroll.UpdateScroll() end
        return scroll
    end

    local db = Chat.GetDB()
    local appearance = db.appearance
    local messages = db.messages
    local sidebar = db.sidebar
    local copy = db.copy

    local function Apply()
        if Chat and Chat.ApplySettings then Chat.ApplySettings() end
    end

    local _, ny = W.CreateInfoText(c, L["chat_v4_live_info"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_enable"], db.enabled ~= false, y, function(v)
        Chat.SetEnabled(v)
    end)
    y = ny

    -- ── Appearance ─────────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["chat_v4_appearance"], y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_chat_skin_bg_alpha"], (appearance.bgAlpha or 0.72) * 100, 0, 100, 5, y, function(v)
        appearance.bgAlpha = v / 100
        Apply()
    end, "%.0f%%")
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_chat_message_bg_alpha"], (appearance.messageBgAlpha or appearance.bgAlpha or 0.72) * 100, 0, 100, 5, y, function(v)
        appearance.messageBgAlpha = v / 100
        Apply()
    end, "%.0f%%")
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_chat_skin_font_size"], appearance.fontSize or 13, 9, 20, 1, y, function(v)
        appearance.fontSize = v
        Apply()
    end)
    y = ny

    -- ── Messages ───────────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["chat_v4_messages"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_fade"], messages.fade ~= false, y, function(v)
        messages.fade = v
        Apply()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_timestamp"], messages.showTimestamp ~= false, y, function(v)
        messages.showTimestamp = v
        Apply()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_short_channels"], messages.shortChannelNames ~= false, y, function(v)
        messages.shortChannelNames = v
        Apply()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_url"], messages.findURL ~= false, y, function(v)
        messages.findURL = v
        Apply()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_emoji"], messages.emoji ~= false, y, function(v)
        messages.emoji = v
        Apply()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_class_colors"], messages.classColorMentions ~= false, y, function(v)
        messages.classColorMentions = v
        Apply()
    end)
    y = ny

    -- ── Sidebar ────────────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["chat_v4_sidebar"], y)
    y = ny

    local _, ny = W.CreateDropdown(c, L["chat_v4_sidebar_side"], {
        { text = L["chat_v4_sidebar_left"],  value = "LEFT"  },
        { text = L["chat_v4_sidebar_right"], value = "RIGHT" },
    }, sidebar.side or "LEFT", y, function(v)
        sidebar.side = v
        Apply()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["chat_v4_sidebar_width"], sidebar.width or 32, 26, 48, 1, y, function(v)
        sidebar.width = v
        Apply()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["chat_v4_sidebar_icon_size"], sidebar.iconSize or 20, 16, 30, 1, y, function(v)
        sidebar.iconSize = v
        Apply()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["chat_v4_sidebar_spacing"], sidebar.spacing or 2, 0, 8, 1, y, function(v)
        sidebar.spacing = v
        Apply()
    end)
    y = ny

    sidebar.buttons = sidebar.buttons or {}
    local sb = sidebar.buttons
    local BUTTON_ROWS = {
        { "friends",      "chat_v4_btn_friends",  "guild",    "chat_v4_btn_guild"    },
        { "playerStatus", "chat_v4_btn_status",   "voice",    "chat_v4_btn_voice"    },
        { "mute",         "chat_v4_btn_mute",     "deafen",   "chat_v4_btn_deafen"   },
        { "copy",         "chat_v4_btn_copy",     "loot",     "chat_v4_btn_loot"     },
        { "settings",     "chat_v4_btn_settings", "scroll",   "chat_v4_btn_scroll"   },
    }
    for _, row in ipairs(BUTTON_ROWS) do
        local keyA, labelA, keyB, labelB = row[1], row[2], row[3], row[4]
        local _, rowY = W.CreateCheckboxPair(c,
            L[labelA], sb[keyA] ~= false, y, function(v) sb[keyA] = v; Apply() end,
            L[labelB], sb[keyB] ~= false,    function(v) sb[keyB] = v; Apply() end)
        y = rowY
    end

    -- ── Copy Chat ──────────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["chat_v4_copy"], y)
    y = ny

    local _, ny = W.CreateSlider(c, L["chat_v4_copy_lines"], copy.maxLines or 500, 50, 1000, 50, y, function(v)
        copy.maxLines = v
    end, "%.0f")
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

    local Bags = TomoMod_BagSkin
    if not Bags or not Bags.GetDB then
        local _, ny = W.CreateInfoText(c, "Bags V4 unavailable.", y)
        y = ny
        c:SetHeight(math.abs(y) + 40)
        if scroll.UpdateScroll then scroll.UpdateScroll() end
        return scroll
    end

    local db = Bags.GetDB()
    local layout = db.layout
    local appearance = db.appearance
    local sorting = db.sorting
    local slots = db.slots
    local sidebar = db.sidebar
    local search = db.search

    local function Loc(key, fallback)
        local value = L and L[key]
        if type(value) == "string" and value ~= key and value ~= "" then return value end
        return fallback
    end

    local function Apply()
        if Bags and Bags.ApplySettings then Bags.ApplySettings() end
    end

    local _, ny = W.CreateSectionHeader(c, Loc("section_skin_bags", "Bags V4"), y)
    y = ny

    local _, ny = W.CreateInfoText(c, Loc("bags_v4_gui_info", "Combined mode uses one TomoMod bag window. Separate mode restores Blizzard's individual bag windows."), y)
    y = ny

    local _, ny = W.CreateCheckbox(c, Loc("opt_skin_bags_enable", "Enable Bags V4"), db.enabled ~= false, y, function(v)
        Bags.SetEnabled(v)
    end)
    y = ny

    -- Display mode ------------------------------------------------------
    local _, ny = W.CreateSegmentedControl(c, Loc("bags_v4_gui_mode", "Bag display"), {
        { text = Loc("bags_v4_gui_combined", "Combined"), value = "combined" },
        { text = Loc("bags_v4_gui_separate", "Separate"), value = "separate" },
    }, layout.mode or "combined", y, function(v)
        if Bags.SetDisplayMode then
            Bags.SetDisplayMode(v)
        else
            layout.mode = v
            Apply()
        end
    end, 2)
    y = ny

    -- Appearance --------------------------------------------------------
    local _, ny = W.CreateSectionHeader(c, Loc("bags_v4_gui_appearance", "Appearance"), y)
    y = ny

    local _, ny = W.CreateSlider(c, Loc("bags_v4_gui_columns", "Columns"), layout.columns or 12, 6, 16, 1, y, function(v)
        layout.columns = math.floor(v + 0.5)
        Apply()
    end, "%.0f")
    y = ny

    local _, ny = W.CreateSlider(c, Loc("opt_skin_bags_slot_size", "Slot size"), layout.slotSize or 38, 28, 52, 1, y, function(v)
        layout.slotSize = math.floor(v + 0.5)
        Apply()
    end, "%.0f")
    y = ny

    local _, ny = W.CreateSlider(c, Loc("bags_v4_gui_spacing", "Slot spacing"), layout.spacing or 4, 0, 10, 1, y, function(v)
        layout.spacing = math.floor(v + 0.5)
        Apply()
    end, "%.0f")
    y = ny

    local _, ny = W.CreateSlider(c, Loc("opt_skin_bags_scale", "Scale"), (appearance.scale or 1) * 100, 70, 140, 5, y, function(v)
        appearance.scale = v / 100
        Apply()
    end, "%.0f%%")
    y = ny

    local _, ny = W.CreateSlider(c, Loc("opt_skin_bags_opacity", "Opacity"), (appearance.alpha or 0.96) * 100, 25, 100, 5, y, function(v)
        appearance.alpha = v / 100
        Apply()
    end, "%.0f%%")
    y = ny

    -- Sorting & search --------------------------------------------------
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateSegmentedControl(c, Loc("opt_skin_bags_sort_mode", "Visual sorting"), {
        { text = Loc("bags_v4_sort_natural", "Bag order"), value = "natural" },
        { text = Loc("bags_v4_sort_quality", "Quality"), value = "quality" },
        { text = Loc("bags_v4_sort_name", "Name"), value = "name" },
        { text = Loc("bags_v4_sort_ilvl", "Item level"), value = "ilvl" },
    }, sorting.mode or "natural", y, function(v)
        sorting.mode = v
        Apply()
    end, 2)
    y = ny

    local _, ny = W.CreateCheckbox(c, Loc("opt_skin_bags_search", "Search bar"), search.enabled ~= false, y, function(v)
        search.enabled = v
        Apply()
    end)
    y = ny

    -- Item slots --------------------------------------------------------
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateCheckbox(c, Loc("opt_skin_bags_quality_borders", "Quality borders"), slots.qualityBorders ~= false, y, function(v)
        slots.qualityBorders = v
        Apply()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, Loc("opt_skin_bags_show_ilvl", "Show item level"), slots.itemLevel ~= false, y, function(v)
        slots.itemLevel = v
        Apply()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, Loc("opt_skin_bags_show_empty", "Show empty slots"), slots.showEmpty ~= false, y, function(v)
        slots.showEmpty = v
        Apply()
    end)
    y = ny

    -- Pinned / Recent ---------------------------------------------------
    local _, ny = W.CreateSectionHeader(c, Loc("bags_v4_gui_sidebar", "Pinned & Recent"), y)
    y = ny

    local _, ny = W.CreateSlider(c, Loc("bags_v4_gui_pinned_max", "Pinned items"), sidebar.pinnedMax or 8, 2, 12, 1, y, function(v)
        sidebar.pinnedMax = math.floor(v + 0.5)
        Apply()
    end, "%.0f")
    y = ny

    local _, ny = W.CreateSlider(c, Loc("bags_v4_gui_recent_max", "Recent items"), sidebar.recentMax or 8, 2, 12, 1, y, function(v)
        sidebar.recentMax = math.floor(v + 0.5)
        Apply()
    end, "%.0f")
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

    local _, ny = W.CreateCheckbox(c, L["opt_char_skin_inspect_iteminfo"], TomoModDB.characterSkin.showInspectItemInfo, y, function(v)
        TomoModDB.characterSkin.showInspectItemInfo = v
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
        print("|cff2e9dd8TomoMod|r " .. string.format(L["msg_chat_history_cleared"], n))
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

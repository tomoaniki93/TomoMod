-- =====================================
-- Panels/QOL.lua — QOL Modules Config (Tabbed)
-- =====================================

local W = TomoMod_Widgets
local L = TomoMod_L

-- =====================================
-- TAB 1: CINEMATIC SKIP
-- =====================================

local function BuildCinematicTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_cinematic"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_cinematic_auto_skip"], TomoModDB.cinematicSkip.enabled, y, function(v)
        TomoModDB.cinematicSkip.enabled = v
        if v and TomoMod_CinematicSkip then TomoMod_CinematicSkip.Initialize() end
    end)
    y = ny

    local viewedStr = "0"
    if TomoMod_CinematicSkip and TomoMod_CinematicSkip.GetViewedCount then
        viewedStr = tostring(TomoMod_CinematicSkip.GetViewedCount())
    end
    local _, ny = W.CreateInfoText(c, string.format(L["info_cinematic_viewed"], viewedStr), y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_clear_history"], 180, y, function()
        if TomoMod_CinematicSkip then TomoMod_CinematicSkip.ClearHistory() end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB 2: AUTO QUEST
-- =====================================

local function BuildAutoQuestTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_auto_quest"], y)
    y = ny

    local _, ny = W.CreateCheckboxPair(c,
        L["opt_quest_auto_accept"], TomoModDB.autoQuest.autoAccept, y,
        function(v) TomoModDB.autoQuest.autoAccept = v end,
        L["opt_quest_auto_turnin"], TomoModDB.autoQuest.autoTurnIn,
        function(v) TomoModDB.autoQuest.autoTurnIn = v end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_quest_auto_gossip"], TomoModDB.autoQuest.autoGossip, y, function(v)
        TomoModDB.autoQuest.autoGossip = v
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_quest_shift"], y)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB 3: AUTOMATIONS (castbar, invite, summon, fill delete)
-- =====================================

local function BuildAutomationsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_automations"], y)
    y = ny

    -- Hide Blizzard Castbar
    local _, ny = W.CreateCheckbox(c, L["opt_hide_blizzard_castbar"], TomoModDB.hideCastBar.enabled, y, function(v)
        if TomoMod_HideCastBar then TomoMod_HideCastBar.SetEnabled(v) end
    end)
    y = ny

    -- Auto Accept Invite
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_auto_accept_invite"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_enable"], TomoModDB.autoAcceptInvite.enabled, y, function(v)
        TomoModDB.autoAcceptInvite.enabled = v
    end)
    y = ny

    local _, ny = W.CreateCheckboxPair(c,
        L["opt_accept_friends"], TomoModDB.autoAcceptInvite.acceptFriends, y,
        function(v) TomoModDB.autoAcceptInvite.acceptFriends = v end,
        L["opt_accept_guild"],   TomoModDB.autoAcceptInvite.acceptGuild,
        function(v) TomoModDB.autoAcceptInvite.acceptGuild = v end)
    y = ny

    -- Auto Skip Role
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_auto_skip_role"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_enable"], TomoModDB.autoSkipRole.enabled, y, function(v)
        TomoModDB.autoSkipRole.enabled = v
        if TomoMod_AutoSkipRole then TomoMod_AutoSkipRole.SetEnabled(v) end
    end)
    y = ny

    -- Auto Summon
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_auto_summon"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_enable"], TomoModDB.autoSummon.enabled, y, function(v)
        TomoModDB.autoSummon.enabled = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_accept_friends"], TomoModDB.autoSummon.acceptFriends, y, function(v)
        TomoModDB.autoSummon.acceptFriends = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_accept_guild"], TomoModDB.autoSummon.acceptGuild, y, function(v)
        TomoModDB.autoSummon.acceptGuild = v
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_summon_delay"], TomoModDB.autoSummon.delaySec, 0, 10, 1, y, function(v)
        TomoModDB.autoSummon.delaySec = v
    end)
    y = ny

    -- Auto Fill Delete
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_auto_fill_delete"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_enable"], TomoModDB.autoFillDelete.enabled, y, function(v)
        TomoModDB.autoFillDelete.enabled = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_focus_ok_button"], TomoModDB.autoFillDelete.focusButton, y, function(v)
        TomoModDB.autoFillDelete.focusButton = v
    end)
    y = ny

    -- Combat Text
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_combat_text"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_combat_text_enable"], TomoModDB.combatText.enabled, y, function(v)
        TomoModDB.combatText.enabled = v
        if TomoMod_CombatText then TomoMod_CombatText.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_combat_text_offset_x"], TomoModDB.combatText.offsetX, -200, 200, 1, y, function(v)
        TomoModDB.combatText.offsetX = v
        if TomoMod_CombatText then TomoMod_CombatText.UpdatePosition() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_combat_text_offset_y"], TomoModDB.combatText.offsetY, -200, 200, 1, y, function(v)
        TomoModDB.combatText.offsetY = v
        if TomoMod_CombatText then TomoMod_CombatText.UpdatePosition() end
    end)
    y = ny

    -- Tooltip IDs
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_tooltip_ids"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_enable"], TomoModDB.tooltipIDs.enabled, y, function(v)
        TomoModDB.tooltipIDs.enabled = v
        if TomoMod_TooltipIDs then TomoMod_TooltipIDs.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tid_spell"], TomoModDB.tooltipIDs.showSpellID, y, function(v)
        TomoModDB.tooltipIDs.showSpellID = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tid_item"], TomoModDB.tooltipIDs.showItemID, y, function(v)
        TomoModDB.tooltipIDs.showItemID = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tid_npc"], TomoModDB.tooltipIDs.showNPCID, y, function(v)
        TomoModDB.tooltipIDs.showNPCID = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tid_quest"], TomoModDB.tooltipIDs.showQuestID, y, function(v)
        TomoModDB.tooltipIDs.showQuestID = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tid_mount"], TomoModDB.tooltipIDs.showMountID, y, function(v)
        TomoModDB.tooltipIDs.showMountID = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tid_currency"], TomoModDB.tooltipIDs.showCurrencyID, y, function(v)
        TomoModDB.tooltipIDs.showCurrencyID = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_tid_achievement"], TomoModDB.tooltipIDs.showAchievementID, y, function(v)
        TomoModDB.tooltipIDs.showAchievementID = v
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB 4: MYTHIC+ KEYS
-- =====================================

local function BuildMythicKeysTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_mythic_keys"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_keys_enable_tracker"], TomoModDB.MythicKeys.enabled, y, function(v)
        TomoModDB.MythicKeys.enabled = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_keys_mini_frame"], TomoModDB.MythicKeys.miniFrame, y, function(v)
        TomoModDB.MythicKeys.miniFrame = v
        if MK and MK.UpdateMiniFrame then MK:UpdateMiniFrame() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_keys_auto_refresh"], TomoModDB.MythicKeys.autoRefresh, y, function(v)
        TomoModDB.MythicKeys.autoRefresh = v
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB 5: SKYRIDE
-- =====================================

local function BuildSkyRideTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local function SR_Apply()
        if TomoMod_SkyRide and TomoMod_SkyRide.ApplySettings then
            TomoMod_SkyRide.ApplySettings()
        end
    end

    -- ── Activation ──────────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["section_skyride"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_skyride_enable"], TomoModDB.skyRide.enabled, y, function(v)
        if TomoMod_SkyRide and TomoMod_SkyRide.SetEnabled then
            TomoMod_SkyRide.SetEnabled(v)
        end
    end)
    y = ny

    -- ── Dimensions ──────────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["section_skyride_dims"], y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_width"], TomoModDB.skyRide.width, 100, 600, 10, y, function(v)
        TomoModDB.skyRide.width = v; SR_Apply()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_skyride_bar_height"], TomoModDB.skyRide.height, 8, 40, 1, y, function(v)
        TomoModDB.skyRide.height = v; SR_Apply()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_skyride_charge_height"], TomoModDB.skyRide.comboHeight, 4, 30, 1, y, function(v)
        TomoModDB.skyRide.comboHeight = v; SR_Apply()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_skyride_charge_gap"], TomoModDB.skyRide.chargeGap, 0, 8, 1, y, function(v)
        TomoModDB.skyRide.chargeGap = v; SR_Apply()
    end)
    y = ny

    -- ── Texte ────────────────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["section_skyride_text"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_skyride_show_speed_text"], TomoModDB.skyRide.showSpeedText, y, function(v)
        TomoModDB.skyRide.showSpeedText = v; SR_Apply()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_skyride_speed_font_size"], TomoModDB.skyRide.fontSize, 8, 24, 1, y, function(v)
        TomoModDB.skyRide.fontSize = v; SR_Apply()
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_skyride_show_charge_timer"], TomoModDB.skyRide.showChargeTimer, y, function(v)
        TomoModDB.skyRide.showChargeTimer = v; SR_Apply()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_skyride_charge_font_size"], TomoModDB.skyRide.chargeFontSize, 8, 20, 1, y, function(v)
        TomoModDB.skyRide.chargeFontSize = v; SR_Apply()
    end)
    y = ny

    -- ── Position ─────────────────────────────────────────────────
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_reset_skyride"], 200, y, function()
        if TomoMod_SkyRide and TomoMod_SkyRide.ResetPosition then
            TomoMod_SkyRide.ResetPosition()
        end
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

-- =====================================
-- Tab: Leveling Bar
-- =====================================

local function BuildLevelingTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_leveling_bar"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_leveling_enable"],
        TomoModDB.levelingBar and TomoModDB.levelingBar.enabled or false, y, function(v)
        if not TomoModDB.levelingBar then TomoModDB.levelingBar = {} end
        TomoModDB.levelingBar.enabled = v
        if TomoMod_LevelingBar then TomoMod_LevelingBar.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_leveling_width"],
        TomoModDB.levelingBar and TomoModDB.levelingBar.width or 500, 300, 800, 10, y, function(v)
        if not TomoModDB.levelingBar then TomoModDB.levelingBar = {} end
        TomoModDB.levelingBar.width = v
        if TomoMod_LevelingBar then TomoMod_LevelingBar.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_leveling_height"],
        TomoModDB.levelingBar and TomoModDB.levelingBar.height or 28, 18, 50, 1, y, function(v)
        if not TomoModDB.levelingBar then TomoModDB.levelingBar = {} end
        TomoModDB.levelingBar.height = v
        if TomoMod_LevelingBar then TomoMod_LevelingBar.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_reset_leveling_pos"], 180, y, function()
        if TomoModDB.levelingBar then
            TomoModDB.levelingBar.position = nil
        end
        if TomoMod_LevelingBar then TomoMod_LevelingBar.SetPosition() end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB: CVAR OPTIMIZER
-- =====================================

local function BuildCVarOptimizerTab(parent)
    local OPT = TomoMod_CVarOptimizer
    if not OPT then return W.CreateScrollPanel(parent) end

    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child

    -- Palette locale (reprend T.accent du thème)
    local TEAL   = { 0.047, 0.824, 0.624 }
    local ORANGE = { 1.0,   0.65,  0.10  }
    local RED    = { 0.9,   0.25,  0.25  }
    local DIM    = { 0.55,  0.55,  0.60  }
    local FONT   = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
    local FONT_B = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Bold.ttf"

    local y = -10

    -- ── En-tête ──────────────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["section_cvar_optimizer"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_cvar_optimizer"], y)
    y = ny

    -- ── Boutons Apply All / Revert All ───────────────────────────
    local applyAllBtn, ny2 = W.CreateButton(c, L["btn_cvar_apply_all"], 160, y, function()
        OPT.ApplyAll()
        -- Refresh toutes les lignes via leur update callback
        for _, child in ipairs(c.cvarRows or {}) do
            if child.Refresh then child:Refresh() end
        end
    end)
    y = ny2

    local revertAllBtn, ny3 = W.CreateButton(c, L["btn_cvar_revert_all"], 160, y, function()
        OPT.RevertAll()
        for _, child in ipairs(c.cvarRows or {}) do
            if child.Refresh then child:Refresh() end
        end
    end)
    -- Placer Revert All à droite de Apply All
    revertAllBtn:ClearAllPoints()
    revertAllBtn:SetPoint("LEFT", applyAllBtn, "RIGHT", 10, 0)
    y = y  -- ny3 déjà avancé par Apply All

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    -- ── Helper : couleur selon statut ────────────────────────────
    local function StatusColor(isOptimal)
        if isOptimal then return TEAL[1], TEAL[2], TEAL[3]
        else               return ORANGE[1], ORANGE[2], ORANGE[3] end
    end

    -- ── Création d'une ligne CVar ─────────────────────────────────
    -- Layout : [Nom 170px] [Valeur actuelle 90px] [→] [Optimal 90px] [Apply 70px] [Revert 70px]
    local ROW_H   = 26
    local COL_VAL = 158   -- x valeur actuelle
    local COL_SEP = 248   -- x séparateur ->
    local COL_OPT = 264   -- x valeur optimale
    local COL_APP = 372   -- x bouton Apply
    local COL_REV = 442   -- x bouton Revert

    c.cvarRows = {}

    local function CreateCVarRow(entry, yRow)
        local row = CreateFrame("Frame", nil, c)
        row:SetSize(c:GetWidth() - 20, ROW_H)
        row:SetPoint("TOPLEFT", c, "TOPLEFT", 16, yRow)

        -- Fond alternant léger
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0)

        -- Nom de la CVar
        local nameFS = row:CreateFontString(nil, "OVERLAY")
        nameFS:SetFont(FONT, 11, "")
        nameFS:SetPoint("LEFT", 0, 0)
        nameFS:SetWidth(COL_VAL - 10)
        nameFS:SetJustifyH("LEFT")
        nameFS:SetText(L[entry.labelKey] or entry.cvar)
        nameFS:SetTextColor(0.90, 0.90, 0.92)

        -- Valeur actuelle
        local curFS = row:CreateFontString(nil, "OVERLAY")
        curFS:SetFont(FONT, 11, "OUTLINE")
        curFS:SetPoint("LEFT", COL_VAL, 0)
        curFS:SetWidth(82)
        curFS:SetJustifyH("LEFT")

        -- Flèche
        local arrFS = row:CreateFontString(nil, "OVERLAY")
        arrFS:SetFont(FONT, 10, "")
        arrFS:SetPoint("LEFT", COL_SEP, 0)
        arrFS:SetTextColor(unpack(DIM))
        arrFS:SetText("->")

        -- Valeur optimale
        local optFS = row:CreateFontString(nil, "OVERLAY")
        optFS:SetFont(FONT_B, 11, "OUTLINE")
        optFS:SetPoint("LEFT", COL_OPT, 0)
        optFS:SetWidth(100)
        optFS:SetJustifyH("LEFT")
        optFS:SetText(OPT.FormatValue(entry.cvar, entry.optimal))
        optFS:SetTextColor(unpack(TEAL))

        -- Bouton Apply
        local appBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        appBtn:SetSize(62, 20)
        appBtn:SetPoint("LEFT", COL_APP, 0)
        appBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8",
                              edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        appBtn:SetBackdropColor(0.035, 0.60, 0.45, 1)
        appBtn:SetBackdropBorderColor(0.047, 0.824, 0.624, 1)
        local appLabel = appBtn:CreateFontString(nil, "OVERLAY")
        appLabel:SetFont(FONT, 10, "")
        appLabel:SetPoint("CENTER")
        appLabel:SetText(L["btn_cvar_apply"])
        appLabel:SetTextColor(1, 1, 1, 1)
        appBtn:SetScript("OnEnter", function() appBtn:SetBackdropColor(0.047, 0.824, 0.624, 1); appLabel:SetTextColor(0.05, 0.05, 0.08, 1) end)
        appBtn:SetScript("OnLeave", function() appBtn:SetBackdropColor(0.035, 0.60, 0.45, 1); appLabel:SetTextColor(1, 1, 1, 1) end)

        -- Bouton Revert
        local revBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        revBtn:SetSize(62, 20)
        revBtn:SetPoint("LEFT", COL_REV, 0)
        revBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8",
                              edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        revBtn:SetBackdropColor(0.20, 0.08, 0.08, 1)
        revBtn:SetBackdropBorderColor(0.60, 0.20, 0.20, 1)
        local revLabel = revBtn:CreateFontString(nil, "OVERLAY")
        revLabel:SetFont(FONT, 10, "")
        revLabel:SetPoint("CENTER")
        revLabel:SetText(L["btn_cvar_revert"])
        revLabel:SetTextColor(1, 1, 1, 1)
        revBtn:SetScript("OnEnter", function() revBtn:SetBackdropColor(0.60, 0.20, 0.20, 1); revLabel:SetTextColor(1, 1, 1, 1) end)
        revBtn:SetScript("OnLeave", function() revBtn:SetBackdropColor(0.20, 0.08, 0.08, 1); revLabel:SetTextColor(1, 1, 1, 1) end)

        -- Tooltip hover sur le nom
        row:EnableMouse(true)
        row:SetScript("OnEnter", function()
            GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
            GameTooltip:SetText(entry.cvar, 1, 0.8, 0.2, 1, true)
            local raw = OPT.GetRaw(entry.cvar)
            GameTooltip:AddLine("Actuel : " .. tostring(raw or "?"), 0.8, 0.8, 0.8)
            GameTooltip:AddLine("Optimal : " .. entry.optimal, 0.047, 0.824, 0.624)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Fonction de rafraîchissement
        local function Refresh()
            local raw = OPT.GetRaw(entry.cvar)
            local isOpt = OPT.IsOptimal(entry.cvar, entry.optimal)
            curFS:SetText(OPT.FormatValue(entry.cvar, raw))
            curFS:SetTextColor(StatusColor(isOpt))

            -- Revert dispo seulement si backup individuel existe
            local hasBackup = OPT.HasIndividualBackup(entry.cvar)
            revBtn:SetEnabled(hasBackup)
            revBtn:SetAlpha(hasBackup and 1 or 0.4)
        end
        Refresh()

        appBtn:SetScript("OnClick", function()
            OPT.ApplyOne(entry.cvar, entry.optimal)
            C_Timer.After(0.05, Refresh)
        end)

        revBtn:SetScript("OnClick", function()
            OPT.RevertOne(entry.cvar)
            C_Timer.After(0.05, Refresh)
        end)

        row.Refresh = Refresh
        table.insert(c.cvarRows, row)

        return row, yRow - ROW_H - 2
    end

    -- ── Rendu par catégorie ───────────────────────────────────────
    for _, cat in ipairs(OPT.CATEGORIES) do
        local _, ny = W.CreateSectionHeader(c, L[cat.labelKey] or cat.key, y)
        y = ny

        for _, entry in ipairs(OPT.CVARS) do
            if entry.category == cat.key then
                local _, newY = CreateCVarRow(entry, y)
                y = newY
            end
        end

        local _, ny = W.CreateSeparator(c, y)
        y = ny
    end

    -- ── Refresh All visible au scroll ─────────────────────────────
    -- Rafraîchit toutes les lignes à l'ouverture du panneau (CVar peuvent changer hors addon)
    scroll:SetScript("OnShow", function()
        for _, row in ipairs(c.cvarRows) do
            if row.Refresh then row:Refresh() end
        end
        -- Griser Revert All si pas de backup global
        revertAllBtn:SetEnabled(OPT.HasGlobalBackup())
        revertAllBtn:SetAlpha(OPT.HasGlobalBackup() and 1 or 0.4)
    end)

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB: SKINS (Chat)
-- =====================================

local function BuildSkinsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_skins"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_skins_desc"], y)
    y = ny

    -- ── Chat Frame Skin ──
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_chat_skin"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_chat_skin_enable"], TomoModDB.chatFrameSkin.enabled, y, function(v)
        TomoModDB.chatFrameSkin.enabled = v
        if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.SetEnabled(v) end
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

    -- ── Buff / Debuff Skin ──
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_buff_skin"], y)
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

    -- ── Game Menu Skin ──
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_game_menu_skin"], y)
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

-- =====================================
-- TAB: BAG & MICRO MENU
-- =====================================

local function BuildBagMicroMenuTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_bag_micro"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_bag_micro"], y)
    y = ny

    -- Bag Bar
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_bag_bar"], y)
    y = ny

    local bagModeOptions = {
        { value = "show",  text = L["mode_show"] },
        { value = "hover", text = L["mode_hover"] },
    }

    local _, ny = W.CreateDropdown(c, L["opt_bag_bar_mode"],
        bagModeOptions,
        TomoModDB.bagMicroMenu and TomoModDB.bagMicroMenu.bagBarMode or "show",
        y, function(v)
        if not TomoModDB.bagMicroMenu then TomoModDB.bagMicroMenu = {} end
        TomoModDB.bagMicroMenu.bagBarMode = v
        if TomoMod_BagMicroMenu then TomoMod_BagMicroMenu.SetBagBarMode(v) end
    end)
    y = ny

    -- Micro Menu
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_micro_menu"], y)
    y = ny

    local microModeOptions = {
        { value = "show",  text = L["mode_show"] },
        { value = "hover", text = L["mode_hover"] },
    }

    local _, ny = W.CreateDropdown(c, L["opt_micro_menu_mode"],
        microModeOptions,
        TomoModDB.bagMicroMenu and TomoModDB.bagMicroMenu.microMenuMode or "show",
        y, function(v)
        if not TomoModDB.bagMicroMenu then TomoModDB.bagMicroMenu = {} end
        TomoModDB.bagMicroMenu.microMenuMode = v
        if TomoMod_BagMicroMenu then TomoMod_BagMicroMenu.SetMicroMenuMode(v) end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB 12: WORLD QUEST TAB
-- =====================================

local function BuildWorldQuestTabTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_wq_tab"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_wq_tab_desc"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_wq_enable"], TomoModDB.worldQuestTab.enabled, y, function(v)
        TomoModDB.worldQuestTab.enabled = v
        if TomoMod_WorldQuestTab then TomoMod_WorldQuestTab.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_wq_auto_show"], TomoModDB.worldQuestTab.autoShow, y, function(v)
        TomoModDB.worldQuestTab.autoShow = v
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_wq_max_quests"], TomoModDB.worldQuestTab.maxQuestsShown, 0, 100, 1, y, function(v)
        TomoModDB.worldQuestTab.maxQuestsShown = v
        if TomoMod_WorldQuestTab then TomoMod_WorldQuestTab.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_wq_min_time"], TomoModDB.worldQuestTab.minTimeMinutes, 0, 1440, 10, y, function(v)
        TomoModDB.worldQuestTab.minTimeMinutes = v
        if TomoMod_WorldQuestTab then TomoMod_WorldQuestTab.ApplySettings() end
    end)
    y = ny

    -- Reward filters section
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSectionHeader(c, L["section_wq_filters"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_wq_filter_gold"], TomoModDB.worldQuestTab.filterGold, y, function(v)
        TomoModDB.worldQuestTab.filterGold = v
        if TomoMod_WorldQuestTab then TomoMod_WorldQuestTab.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_wq_filter_gear"], TomoModDB.worldQuestTab.filterGear, y, function(v)
        TomoModDB.worldQuestTab.filterGear = v
        if TomoMod_WorldQuestTab then TomoMod_WorldQuestTab.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_wq_filter_rep"], TomoModDB.worldQuestTab.filterRep, y, function(v)
        TomoModDB.worldQuestTab.filterRep = v
        if TomoMod_WorldQuestTab then TomoMod_WorldQuestTab.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_wq_filter_currency"], TomoModDB.worldQuestTab.filterCurrency, y, function(v)
        TomoModDB.worldQuestTab.filterCurrency = v
        if TomoMod_WorldQuestTab then TomoMod_WorldQuestTab.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_wq_filter_anima"], TomoModDB.worldQuestTab.filterAnima, y, function(v)
        TomoModDB.worldQuestTab.filterAnima = v
        if TomoMod_WorldQuestTab then TomoMod_WorldQuestTab.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_wq_filter_pet"], TomoModDB.worldQuestTab.filterPet, y, function(v)
        TomoModDB.worldQuestTab.filterPet = v
        if TomoMod_WorldQuestTab then TomoMod_WorldQuestTab.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_wq_filter_other"], TomoModDB.worldQuestTab.filterOther, y, function(v)
        TomoModDB.worldQuestTab.filterOther = v
        if TomoMod_WorldQuestTab then TomoMod_WorldQuestTab.ApplySettings() end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB: PROFESSION HELPER
-- =====================================

local function BuildProfessionHelperTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_prof_helper"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_prof_helper_desc"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_prof_helper_enable"], TomoModDB.professionHelper.enabled, y, function(v)
        TomoModDB.professionHelper.enabled = v
    end)
    y = ny

    -- Quality filters for disenchant
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_prof_de_filters"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_prof_filter_green"], TomoModDB.professionHelper.filterGreen, y, function(v)
        TomoModDB.professionHelper.filterGreen = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_prof_filter_blue"], TomoModDB.professionHelper.filterBlue, y, function(v)
        TomoModDB.professionHelper.filterBlue = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_prof_filter_epic"], TomoModDB.professionHelper.filterEpic, y, function(v)
        TomoModDB.professionHelper.filterEpic = v
    end)
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_prof_open_helper"], 200, y, function()
        if TomoMod_ProfessionHelper then TomoMod_ProfessionHelper.Toggle() end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB: CLASS REMINDER
-- =====================================

local function BuildClassReminderTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local function CR_Apply()
        if TomoMod_ClassReminder and TomoMod_ClassReminder.ApplySettings then
            TomoMod_ClassReminder.ApplySettings()
        end
    end

    local _, ny = W.CreateSectionHeader(c, L["section_class_reminder"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_class_reminder"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_class_reminder_enable"], TomoModDB.classReminder.enabled, y, function(v)
        TomoModDB.classReminder.enabled = v
        if TomoMod_ClassReminder then TomoMod_ClassReminder.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_class_reminder_scale"], TomoModDB.classReminder.scale, 0.5, 3.0, 0.1, y, function(v)
        TomoModDB.classReminder.scale = v; CR_Apply()
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, L["opt_class_reminder_color"], TomoModDB.classReminder.textColor, y, function(r, g, b)
        TomoModDB.classReminder.textColor.r = r
        TomoModDB.classReminder.textColor.g = g
        TomoModDB.classReminder.textColor.b = b
        CR_Apply()
    end)
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateSubLabel(c, L["sublabel_class_reminder_pos"], y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_class_reminder_x"], TomoModDB.classReminder.offsetX, -250, 250, 1, y, function(v)
        TomoModDB.classReminder.offsetX = v; CR_Apply()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_class_reminder_y"], TomoModDB.classReminder.offsetY, -250, 250, 1, y, function(v)
        TomoModDB.classReminder.offsetY = v; CR_Apply()
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- MAIN PANEL ENTRY POINT
-- =====================================

function TomoMod_ConfigPanel_QOL(parent)
    local tabs = {
        { key = "cinematic",    label = L["tab_qol_cinematic"],    builder = function(p) return BuildCinematicTab(p) end },
        { key = "autoquest",    label = L["tab_qol_auto_quest"],   builder = function(p) return BuildAutoQuestTab(p) end },
        { key = "automations",  label = L["tab_qol_automations"],  builder = function(p) return BuildAutomationsTab(p) end },
        { key = "mythickeys",   label = L["tab_qol_mythic_keys"],  builder = function(p) return BuildMythicKeysTab(p) end },
        { key = "skyride",      label = L["tab_qol_skyride"],      builder = function(p) return BuildSkyRideTab(p) end },
        { key = "skins",        label = L["tab_qol_skins"],        builder = function(p) return BuildSkinsTab(p) end },
        { key = "objtracker",   label = L["tab_qol_obj_tracker"],  builder = function(p) return BuildObjectiveTrackerTab(p) end },
        { key = "bagmicro",     label = L["tab_qol_bag_micro"],    builder = function(p) return BuildBagMicroMenuTab(p) end },
        { key = "charskin",     label = L["tab_qol_char_skin"],    builder = function(p) return BuildCharacterSkinTab(p) end },
        { key = "leveling",     label = L["tab_qol_leveling"],     builder = function(p) return BuildLevelingTab(p) end },
        { key = "cvaropt",      label = L["tab_qol_cvar_opt"],     builder = function(p) return BuildCVarOptimizerTab(p) end },
        { key = "worldquests",  label = L["tab_qol_world_quests"], builder = function(p) return BuildWorldQuestTabTab(p) end },
        { key = "profhelper",   label = L["tab_qol_prof_helper"],  builder = function(p) return BuildProfessionHelperTab(p) end },
        { key = "classremind", label = L["tab_qol_class_reminder"], builder = function(p) return BuildClassReminderTab(p) end },
    }

    return W.CreateTabPanel(parent, tabs)
end
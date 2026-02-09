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

    local _, ny = W.CreateCheckbox(c, L["opt_quest_auto_accept"], TomoModDB.autoQuest.autoAccept, y, function(v)
        TomoModDB.autoQuest.autoAccept = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_quest_auto_turnin"], TomoModDB.autoQuest.autoTurnIn, y, function(v)
        TomoModDB.autoQuest.autoTurnIn = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_quest_auto_gossip"], TomoModDB.autoQuest.autoGossip, y, function(v)
        TomoModDB.autoQuest.autoGossip = v
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_quest_shift"], y)
    y = ny

    c:SetHeight(math.abs(y) + 40)
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

    local _, ny = W.CreateCheckbox(c, L["opt_accept_friends"], TomoModDB.autoAcceptInvite.acceptFriends, y, function(v)
        TomoModDB.autoAcceptInvite.acceptFriends = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_accept_guild"], TomoModDB.autoAcceptInvite.acceptGuild, y, function(v)
        TomoModDB.autoAcceptInvite.acceptGuild = v
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

    c:SetHeight(math.abs(y) + 40)
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
    return scroll
end

-- =====================================
-- TAB 5: SKYRIDE
-- =====================================

local function BuildSkyRideTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_skyride"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_skyride_enable"], TomoModDB.skyRide.enabled, y, function(v)
        if TomoMod_SkyRide and TomoMod_SkyRide.SetEnabled then
            TomoMod_SkyRide.SetEnabled(v)
        end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_width"], TomoModDB.skyRide.width, 100, 600, 10, y, function(v)
        TomoModDB.skyRide.width = v
        if TomoMod_SkyRide and TomoMod_SkyRide.ApplySettings then
            TomoMod_SkyRide.ApplySettings()
        end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_skyride_bar_height"], TomoModDB.skyRide.height, 10, 40, 1, y, function(v)
        TomoModDB.skyRide.height = v
        if TomoMod_SkyRide and TomoMod_SkyRide.ApplySettings then
            TomoMod_SkyRide.ApplySettings()
        end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_font_size"], TomoModDB.skyRide.fontSize, 8, 24, 1, y, function(v)
        TomoModDB.skyRide.fontSize = v
        if TomoMod_SkyRide and TomoMod_SkyRide.ApplySettings then
            TomoMod_SkyRide.ApplySettings()
        end
    end)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_reset_skyride"], 200, y, function()
        if TomoMod_SkyRide and TomoMod_SkyRide.ResetPosition then
            TomoMod_SkyRide.ResetPosition()
        end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
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
    }

    return W.CreateTabPanel(parent, tabs)
end
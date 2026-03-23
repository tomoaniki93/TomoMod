-- =====================================
-- Panels/MythicPlus.lua — M+ Tracker Config Panel
-- Integrated into TomoMod's Config UI
-- =====================================

local W = TomoMod_Widgets
local L = TomoMod_L

function TomoMod_ConfigPanel_MythicPlus(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    -- ── Section: Enable ──────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, "M+ Tracker", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["tmt_cfg_panel_enable"], TomoModDB.MythicTracker.enabled, y, function(v)
        TomoModDB.MythicTracker.enabled = v
    end)
    y = ny

    -- ── Section: Display ─────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["tmt_cfg_section_display"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["tmt_cfg_show_timer"], TomoModDB.MythicTracker.showTimer, y, function(v)
        TomoModDB.MythicTracker.showTimer = v
        if TomoMod_MythicTracker and TomoMod_MythicTracker.Frame then
            TomoMod_MythicTracker.Frame.TimerBar:SetShown(v)
            TomoMod_MythicTracker:LayoutFrame()
        end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["tmt_cfg_show_forces"], TomoModDB.MythicTracker.showForces, y, function(v)
        TomoModDB.MythicTracker.showForces = v
        if TomoMod_MythicTracker and TomoMod_MythicTracker.Frame then
            TomoMod_MythicTracker.Frame.ForcesBar:SetShown(v)
            TomoMod_MythicTracker:LayoutFrame()
        end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["tmt_cfg_show_bosses"], TomoModDB.MythicTracker.showBosses, y, function(v)
        TomoModDB.MythicTracker.showBosses = v
        if TomoMod_MythicTracker then
            TomoMod_MythicTracker:UpdateBossRows()
            TomoMod_MythicTracker:LayoutFrame()
        end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["tmt_cfg_hide_blizzard"], TomoModDB.MythicTracker.hideBlizzard, y, function(v)
        TomoModDB.MythicTracker.hideBlizzard = v
        if v and TomoMod_MythicTracker and TomoMod_MythicTracker._inChallenge then
            TomoMod_MythicTracker:SuppressBlizzardUI()
        end
    end)
    y = ny

    -- ── Section: Frame ───────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["tmt_cfg_section_frame"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["tmt_cfg_lock"], TomoModDB.MythicTracker.locked, y, function(v)
        TomoModDB.MythicTracker.locked = v
        if TomoMod_MythicTracker then
            TomoMod_MythicTracker:SetMovable(not v)
        end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["tmt_cfg_scale"], TomoModDB.MythicTracker.scale, 0.5, 2.0, 0.05, y, function(v)
        TomoModDB.MythicTracker.scale = v
        if TomoMod_MythicTracker and TomoMod_MythicTracker.Frame then
            TomoMod_MythicTracker.Frame:SetScale(v)
        end
    end, "%.2f")
    y = ny

    local _, ny = W.CreateSlider(c, L["tmt_cfg_alpha"], TomoModDB.MythicTracker.alpha, 0.2, 1.0, 0.05, y, function(v)
        TomoModDB.MythicTracker.alpha = v
        if TomoMod_MythicTracker and TomoMod_MythicTracker.Frame then
            TomoMod_MythicTracker.Frame:SetAlpha(v)
        end
    end, "%.2f")
    y = ny

    -- ── Section: Actions ─────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["tmt_cfg_section_actions"], y)
    y = ny

    local _, ny = W.CreateButton(c, L["tmt_cfg_preview"], 140, y, function()
        if TomoMod_MythicTracker then
            TomoMod_MythicTracker:Preview()
        end
    end)
    y = ny

    local _, ny = W.CreateButton(c, L["tmt_cfg_reset_pos"], 140, y, function()
        if TomoMod_MythicTracker then
            TomoMod_MythicTracker:ResetPosition()
            print(L["tmt_reset_msg"])
        end
    end)
    y = ny

    -- ══════════════════════════════════════════════════════════════
    --  TomoScore — Dungeon Scoreboard
    -- ══════════════════════════════════════════════════════════════
    local _, ny = W.CreateSectionHeader(c, L["ts_cfg_title"], y - 10)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["ts_cfg_enable"], TomoModDB.TomoScore.enabled, y, function(v)
        TomoModDB.TomoScore.enabled = v
    end)
    y = ny

    -- ── Display ──────────────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["ts_cfg_section_display"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["ts_cfg_auto_show_mplus"], TomoModDB.TomoScore.autoShowMPlus, y, function(v)
        TomoModDB.TomoScore.autoShowMPlus = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["ts_cfg_auto_show_m0"], TomoModDB.TomoScore.autoShowM0, y, function(v)
        TomoModDB.TomoScore.autoShowM0 = v
    end)
    y = ny

    -- ── Frame ────────────────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["ts_cfg_section_frame"], y)
    y = ny

    local _, ny = W.CreateSlider(c, L["ts_cfg_scale"], TomoModDB.TomoScore.scale, 0.5, 2.0, 0.05, y, function(v)
        TomoModDB.TomoScore.scale = v
        if TomoMod_TomoScore and TomoMod_TomoScore.SB then
            TomoMod_TomoScore.SB:SetScale(v)
        end
    end, "%.2f")
    y = ny

    local _, ny = W.CreateSlider(c, L["ts_cfg_alpha"], TomoModDB.TomoScore.alpha, 0.2, 1.0, 0.05, y, function(v)
        TomoModDB.TomoScore.alpha = v
        if TomoMod_TomoScore and TomoMod_TomoScore.SB then
            TomoMod_TomoScore.SB:SetAlpha(v)
        end
    end, "%.2f")
    y = ny

    -- ── Actions ──────────────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["ts_cfg_section_actions"], y)
    y = ny

    local _, ny = W.CreateButton(c, L["ts_cfg_preview"], 140, y, function()
        if TomoMod_TomoScore then
            TomoMod_TomoScore:ShowPreview()
        end
    end)
    y = ny

    local _, ny = W.CreateButton(c, L["ts_cfg_last_run"], 140, y, function()
        if TomoMod_TomoScore then
            TomoMod_TomoScore:ShowLastRun()
        end
    end)
    y = ny

    local _, ny = W.CreateButton(c, L["ts_cfg_reset_pos"], 140, y, function()
        if TomoMod_TomoScore then
            TomoMod_TomoScore:ResetPosition()
            print(L["ts_reset_msg"])
        end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- Panels/MythicPlus.lua v2.7.0
local W = TomoMod_Widgets
local L = TomoMod_L

local function RefreshTracker()
    if TomoMod_MythicTracker then
        if TomoMod_MythicTracker.LayoutFrame then TomoMod_MythicTracker:LayoutFrame() end
    end
end

-- A style key was changed by hand: re-resolve which preset (if any) the
-- database now matches, push the answer back into the preset control, and
-- rebuild the tracker's appearance.
local function StyleChanged(presetControl)
    local T = TomoMod_MythicTracker
    if not T then return end
    local resolved = T.ResolvePreset and T:ResolvePreset() or nil
    if presetControl and presetControl.SetValue and resolved then
        presetControl:SetValue(resolved)
    end
    if T.RefreshStyle then T:RefreshStyle() end
end

function TomoMod_ConfigPanel_MythicPlus(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -12

    -- ═══════════════════════════════════════════════
    -- M+ TRACKER
    -- ═══════════════════════════════════════════════
    local card, cy = W.CreateCard(c, "M+ Tracker", y)
    local db = TomoModDB.MythicTracker
    local presetControl
    local cbBackground, cbHeader, cbDungeon, segObjective, segTimer, segColors, sldFontScale

    -- Push the database back into the style widgets after a preset is
    -- applied, so the panel never shows stale ticks.
    local function SyncStyleWidgets()
        if cbBackground then cbBackground:SetChecked(db.showBackground) end
        if cbHeader     then cbHeader:SetChecked(db.showHeaderBlock)    end
        if cbDungeon    then cbDungeon:SetChecked(db.showDungeonName)   end
        if segObjective then segObjective:SetValue(db.objectiveStyle)   end
        if segTimer     then segTimer:SetValue(db.timerLayout)          end
        if segColors    then segColors:SetValue(db.segmentColors)       end
        if sldFontScale then sldFontScale:SetValue(db.fontScale)        end
    end

    local _, cy = W.CreateCheckbox(card.inner, L["tmt_cfg_panel_enable"], db.enabled, cy, function(v)
        db.enabled = v
    end)

    -- ── Style preset ────────────────────────────────────────────────
    -- Only the named presets are offered. When the database sits on
    -- "custom" neither button highlights, which is the honest state.
    presetControl, cy = W.CreateSegmentedControl(card.inner, L["tmt_cfg_preset"], {
        { value = "panel",   text = L["tmt_cfg_preset_panel"]   },
        { value = "hud",     text = L["tmt_cfg_preset_hud"]     },
        { value = "minimal", text = L["tmt_cfg_preset_minimal"] },
    }, db.preset, cy, function(v)
        if TomoMod_MythicTracker and TomoMod_MythicTracker.ApplyPreset then
            TomoMod_MythicTracker:ApplyPreset(v)
            TomoMod_MythicTracker:RefreshStyle()
        end
        SyncStyleWidgets()
    end, 3)

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col)
            local cb, ny = W.CreateCheckbox(col, L["tmt_cfg_show_background"], db.showBackground, 0, function(v)
                db.showBackground = v
                StyleChanged(presetControl)
            end)
            cbBackground = cb
            return ny
        end,
        function(col)
            local cb, ny = W.CreateCheckbox(col, L["tmt_cfg_show_header"], db.showHeaderBlock, 0, function(v)
                db.showHeaderBlock = v
                StyleChanged(presetControl)
            end)
            cbHeader = cb
            return ny
        end)

    cbDungeon, cy = W.CreateCheckbox(card.inner, L["tmt_cfg_show_dungeon"], db.showDungeonName, cy, function(v)
        db.showDungeonName = v
        StyleChanged(presetControl)
    end)

    segObjective, cy = W.CreateSegmentedControl(card.inner, L["tmt_cfg_objective_style"], {
        { value = "rows", text = L["tmt_cfg_objective_rows"] },
        { value = "text", text = L["tmt_cfg_objective_text"] },
        { value = "none", text = L["tmt_cfg_objective_none"] },
    }, db.objectiveStyle, cy, function(v)
        db.objectiveStyle = v
        StyleChanged(presetControl)
    end, 3)

    segTimer, cy = W.CreateSegmentedControl(card.inner, L["tmt_cfg_timer_layout"], {
        { value = "stacked", text = L["tmt_cfg_timer_stacked"] },
        { value = "inline",  text = L["tmt_cfg_timer_inline"]  },
    }, db.timerLayout, cy, function(v)
        db.timerLayout = v
        StyleChanged(presetControl)
    end, 2)

    segColors, cy = W.CreateSegmentedControl(card.inner, L["tmt_cfg_segment_colors"], {
        { value = "palier", text = L["tmt_cfg_segment_palier"] },
        { value = "brand",  text = L["tmt_cfg_segment_brand"]  },
    }, db.segmentColors, cy, function(v)
        db.segmentColors = v
        StyleChanged(presetControl)
    end, 2)

    sldFontScale, cy = W.CreateSlider(card.inner, L["tmt_cfg_font_scale"], db.fontScale, 0.7, 1.6, 0.05, cy, function(v)
        db.fontScale = v
        StyleChanged(presetControl)
    end, "%.2f")

    -- ── Content ─────────────────────────────────────────────────────
    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["tmt_cfg_show_timer"], db.showTimer, 0, function(v)
                db.showTimer = v
                if TomoMod_MythicTracker and TomoMod_MythicTracker.Frame then
                    TomoMod_MythicTracker:UpdateTimerBar()
                    RefreshTracker()
                end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["tmt_cfg_show_forces"], db.showForces, 0, function(v)
                db.showForces = v
                if TomoMod_MythicTracker and TomoMod_MythicTracker.Frame then
                    TomoMod_MythicTracker:UpdateForcesBar()
                    RefreshTracker()
                end
            end)
            return ny
        end)

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["tmt_cfg_show_bosses"], db.showBosses, 0, function(v)
                db.showBosses = v
                if TomoMod_MythicTracker then
                    TomoMod_MythicTracker:UpdateBossRows()
                    RefreshTracker()
                end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["tmt_cfg_hide_blizzard"], db.hideBlizzard, 0, function(v)
                db.hideBlizzard = v
            end)
            return ny
        end)

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["tmt_cfg_splits"], db.splitsEnabled, 0, function(v)
                db.splitsEnabled = v
                if TomoMod_MythicTracker then TomoMod_MythicTracker:RefreshStyle() end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["tmt_cfg_checkpoints"], db.checkpointsEnabled, 0, function(v)
                db.checkpointsEnabled = v
                if TomoMod_MythicTracker then TomoMod_MythicTracker:RefreshStyle() end
            end)
            return ny
        end)

    local _, cy = W.CreateCheckbox(card.inner, L["tmt_cfg_lock"], db.locked, cy, function(v)
        db.locked = v
        if TomoMod_MythicTracker then
            TomoMod_MythicTracker:SetMovable(not v)
        end
    end)

    local _, cy = W.CreateSlider(card.inner, L["tmt_cfg_scale"], db.scale, 0.5, 2.0, 0.05, cy, function(v)
        db.scale = v
        if TomoMod_MythicTracker and TomoMod_MythicTracker.Frame then
            TomoMod_MythicTracker.Frame:SetScale(v)
        end
    end, "%.2f")

    local _, cy = W.CreateSlider(card.inner, L["tmt_cfg_alpha"], db.alpha, 0.2, 1.0, 0.05, cy, function(v)
        db.alpha = v
        if TomoMod_MythicTracker and TomoMod_MythicTracker.Frame then
            TomoMod_MythicTracker.Frame:SetAlpha(v)
        end
    end, "%.2f")

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col)
            local _, ny = W.CreateButton(col, L["tmt_cfg_preview"], 160, 0, function()
                if TomoMod_MythicTracker then TomoMod_MythicTracker:Preview() end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateButton(col, L["tmt_cfg_reset_pos"], 160, 0, function()
                if TomoMod_MythicTracker then
                    TomoMod_MythicTracker:ResetPosition()
                    print(L["tmt_reset_msg"])
                end
            end)
            return ny
        end)

    local _, cy = W.CreateButton(card.inner, L["tmt_cfg_clear_splits"], 160, cy, function()
        if TomoMod_MythicTracker then
            TomoMod_MythicTracker:ClearSplits()
            print(L["tmt_splits_cleared"])
        end
    end)

    y = W.FinalizeCard(card, cy)

    -- ═══════════════════════════════════════════════
    -- TOMO SCORE
    -- ═══════════════════════════════════════════════
    local card2, cy = W.CreateCard(c, L["ts_cfg_title"], y)

    local _, cy = W.CreateCheckbox(card2.inner, L["ts_cfg_enable"], TomoModDB.TomoScore.enabled, cy, function(v)
        TomoModDB.TomoScore.enabled = v
    end)

    local _, cy = W.CreateCheckbox(card2.inner, L["ts_cfg_auto_show_mplus"], TomoModDB.TomoScore.autoShowMPlus, cy, function(v)
        TomoModDB.TomoScore.autoShowMPlus = v
    end)

    local _, cy = W.CreateSlider(card2.inner, L["ts_cfg_scale"], TomoModDB.TomoScore.scale, 0.5, 2.0, 0.05, cy, function(v)
        TomoModDB.TomoScore.scale = v
        if TomoMod_TomoScore and TomoMod_TomoScore.SB then
            TomoMod_TomoScore.SB:SetScale(v)
        end
    end, "%.2f")

    local _, cy = W.CreateSlider(card2.inner, L["ts_cfg_alpha"], TomoModDB.TomoScore.alpha, 0.2, 1.0, 0.05, cy, function(v)
        TomoModDB.TomoScore.alpha = v
        if TomoMod_TomoScore and TomoMod_TomoScore.SB then
            TomoMod_TomoScore.SB:SetAlpha(v)
        end
    end, "%.2f")

    local _, cy = W.CreateTwoColumnRow(card2.inner, cy,
        function(col)
            local _, ny = W.CreateButton(col, L["ts_cfg_preview"], 160, 0, function()
                if TomoMod_TomoScore then TomoMod_TomoScore:ShowPreview() end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateButton(col, L["ts_cfg_reset_pos"], 160, 0, function()
                if TomoMod_TomoScore then
                    TomoMod_TomoScore:ResetPosition()
                    print(L["ts_reset_msg"])
                end
            end)
            return ny
        end)

    y = W.FinalizeCard(card2, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- Panels/MythicPlus.lua v2.7.0
local W = TomoMod_Widgets
local L = TomoMod_L

local function RefreshTracker()
    if TomoMod_MythicTracker then
        if TomoMod_MythicTracker.LayoutFrame then TomoMod_MythicTracker:LayoutFrame() end
    end
end

function TomoMod_ConfigPanel_MythicPlus(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -12

    -- ═══════════════════════════════════════════════
    -- M+ TRACKER
    -- ═══════════════════════════════════════════════
    local card, cy = W.CreateCard(c, "M+ Tracker", y)

    local _, cy = W.CreateCheckbox(card.inner, L["tmt_cfg_panel_enable"], TomoModDB.MythicTracker.enabled, cy, function(v)
        TomoModDB.MythicTracker.enabled = v
    end)

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["tmt_cfg_show_timer"], TomoModDB.MythicTracker.showTimer, 0, function(v)
                TomoModDB.MythicTracker.showTimer = v
                if TomoMod_MythicTracker and TomoMod_MythicTracker.Frame then
                    TomoMod_MythicTracker.Frame.TimerBar:SetShown(v)
                    RefreshTracker()
                end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["tmt_cfg_show_forces"], TomoModDB.MythicTracker.showForces, 0, function(v)
                TomoModDB.MythicTracker.showForces = v
                if TomoMod_MythicTracker and TomoMod_MythicTracker.Frame then
                    TomoMod_MythicTracker.Frame.ForcesBar:SetShown(v)
                    RefreshTracker()
                end
            end)
            return ny
        end)

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["tmt_cfg_show_bosses"], TomoModDB.MythicTracker.showBosses, 0, function(v)
                TomoModDB.MythicTracker.showBosses = v
                if TomoMod_MythicTracker then
                    TomoMod_MythicTracker:UpdateBossRows()
                    RefreshTracker()
                end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["tmt_cfg_hide_blizzard"], TomoModDB.MythicTracker.hideBlizzard, 0, function(v)
                TomoModDB.MythicTracker.hideBlizzard = v
            end)
            return ny
        end)

    local _, cy = W.CreateCheckbox(card.inner, L["tmt_cfg_lock"] or "Verrouillé", TomoModDB.MythicTracker.locked, cy, function(v)
        TomoModDB.MythicTracker.locked = v
        if TomoMod_MythicTracker then
            TomoMod_MythicTracker:SetMovable(not v)
        end
    end)

    local _, cy = W.CreateSlider(card.inner, L["tmt_cfg_scale"] or "Échelle", TomoModDB.MythicTracker.scale, 0.5, 2.0, 0.05, cy, function(v)
        TomoModDB.MythicTracker.scale = v
        if TomoMod_MythicTracker and TomoMod_MythicTracker.Frame then
            TomoMod_MythicTracker.Frame:SetScale(v)
        end
    end, "%.2f")

    local _, cy = W.CreateSlider(card.inner, L["tmt_cfg_alpha"] or "Opacité", TomoModDB.MythicTracker.alpha, 0.2, 1.0, 0.05, cy, function(v)
        TomoModDB.MythicTracker.alpha = v
        if TomoMod_MythicTracker and TomoMod_MythicTracker.Frame then
            TomoMod_MythicTracker.Frame:SetAlpha(v)
        end
    end, "%.2f")

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col)
            local _, ny = W.CreateButton(col, L["tmt_cfg_preview"] or "Prévisualiser", 160, 0, function()
                if TomoMod_MythicTracker then TomoMod_MythicTracker:Preview() end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateButton(col, L["tmt_cfg_reset_pos"] or "Réinitialiser pos.", 160, 0, function()
                if TomoMod_MythicTracker then
                    TomoMod_MythicTracker:ResetPosition()
                    print(L["tmt_reset_msg"] or "Position réinitialisée.")
                end
            end)
            return ny
        end)

    y = W.FinalizeCard(card, cy)

    -- ═══════════════════════════════════════════════
    -- TOMO SCORE
    -- ═══════════════════════════════════════════════
    local card2, cy = W.CreateCard(c, L["ts_cfg_title"] or "TomoScore", y)

    local _, cy = W.CreateCheckbox(card2.inner, L["ts_cfg_enable"] or "Activer TomoScore", TomoModDB.TomoScore.enabled, cy, function(v)
        TomoModDB.TomoScore.enabled = v
    end)

    local _, cy = W.CreateCheckbox(card2.inner, L["ts_cfg_auto_show_mplus"] or "Afficher automatiquement en M+", TomoModDB.TomoScore.autoShowMPlus, cy, function(v)
        TomoModDB.TomoScore.autoShowMPlus = v
    end)

    local _, cy = W.CreateSlider(card2.inner, L["ts_cfg_scale"] or "Échelle", TomoModDB.TomoScore.scale, 0.5, 2.0, 0.05, cy, function(v)
        TomoModDB.TomoScore.scale = v
        if TomoMod_TomoScore and TomoMod_TomoScore.SB then
            TomoMod_TomoScore.SB:SetScale(v)
        end
    end, "%.2f")

    local _, cy = W.CreateSlider(card2.inner, L["ts_cfg_alpha"] or "Opacité", TomoModDB.TomoScore.alpha, 0.2, 1.0, 0.05, cy, function(v)
        TomoModDB.TomoScore.alpha = v
        if TomoMod_TomoScore and TomoMod_TomoScore.SB then
            TomoMod_TomoScore.SB:SetAlpha(v)
        end
    end, "%.2f")

    local _, cy = W.CreateTwoColumnRow(card2.inner, cy,
        function(col)
            local _, ny = W.CreateButton(col, L["ts_cfg_preview"] or "Prévisualiser", 160, 0, function()
                if TomoMod_TomoScore then TomoMod_TomoScore:ShowPreview() end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateButton(col, L["ts_cfg_reset_pos"] or "Réinitialiser pos.", 160, 0, function()
                if TomoMod_TomoScore then
                    TomoMod_TomoScore:ResetPosition()
                    print(L["ts_reset_msg"] or "Position réinitialisée.")
                end
            end)
            return ny
        end)

    y = W.FinalizeCard(card2, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

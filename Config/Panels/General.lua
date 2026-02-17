-- =====================================
-- Panels/General.lua — General & About (TomoModMini)
-- =====================================

local W = TomoModMini_Widgets
local L = TomoModMini_L

function TomoModMini_ConfigPanel_General(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child

    local y = -10

    -- CURSOR RING
    local _, ny = W.CreateSectionHeader(c, L["section_cursor_ring"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_enable"], TomoModMiniDB.cursorRing.enabled, y, function(v)
        TomoModMiniDB.cursorRing.enabled = v
        if TomoModMini_CursorRing then TomoModMini_CursorRing.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_class_color"], TomoModMiniDB.cursorRing.useClassColor, y, function(v)
        TomoModMiniDB.cursorRing.useClassColor = v
        if TomoModMini_CursorRing then TomoModMini_CursorRing.ApplyColor() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_anchor_tooltip_ring"], TomoModMiniDB.cursorRing.anchorTooltip, y, function(v)
        TomoModMiniDB.cursorRing.anchorTooltip = v
        if TomoModMini_CursorRing then
            TomoModMini_CursorRing.SetupTooltipAnchor()
            TomoModMini_CursorRing.Toggle(true)
        end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_scale"], TomoModMiniDB.cursorRing.scale, 0.5, 3.0, 0.1, y, function(v)
        TomoModMiniDB.cursorRing.scale = v
        if TomoModMini_CursorRing then TomoModMini_CursorRing.ApplyScale() end
    end, "%.1f")
    y = ny - 20

    -- ABOUT
    local _, ny = W.CreateSectionHeader(c, L["section_about"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["about_text"], y)
    y = ny - 6

    -- GENERAL
    local _, ny = W.CreateSectionHeader(c, L["section_general"], y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_reset_all"], 200, y, function()
        StaticPopup_Show("TOMOMODMINI_RESET_ALL")
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_reset_all"], y)
    y = ny - 10

    -- Resize child
    c:SetHeight(math.abs(y) + 20)

    return scroll
end

-- Static popup for reset
StaticPopupDialogs["TOMOMODMINI_RESET_ALL"] = {
    text = L["popup_reset_text"],
    button1 = L["popup_confirm"],
    button2 = L["popup_cancel"],
    OnAccept = function()
        TomoModMini_ResetDatabase()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

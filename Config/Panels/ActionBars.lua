-- =====================================================
-- Config/Panels/ActionBars.lua v5.0.0
--
-- PLACEHOLDER (lot P4).
--
-- The previous panel drove TomoMod_ActionBars / TomoMod_ABRender / etc.,
-- all of which were removed in P4 when the ported Tui module took over. Its
-- controls wrote to the old DB schema and would silently do nothing now, so
-- rather than leave forty-five dead widgets on screen the panel says what is
-- happening. Lot P5 rebuilds it against the Tui schema.
-- =====================================================

local L = TomoMod_L
local W = TomoMod_Widgets

function TomoMod_ConfigPanel_ActionBars(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_action_bars"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_ab_rebuilding"], y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_abs_layout"], 260, y, function()
        if TomoMod_Movers and TomoMod_Movers.Toggle then
            TomoMod_Movers.Toggle()
        end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

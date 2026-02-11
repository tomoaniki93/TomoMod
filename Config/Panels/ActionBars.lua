-- =====================================
-- Config/Panels/ActionBars.lua
-- Action Bar Skin configuration panel
-- =====================================

local L = TomoMod_L
local W = TomoMod_Widgets

-- Bar definitions: key matches Database barOpacity keys
local BAR_LIST = {
    { value = "ActionButton",           text = "Action Bar 1" },
    { value = "MultiBarBottomLeft",     text = "Action Bar 2 (Bottom Left)" },
    { value = "MultiBarBottomRight",    text = "Action Bar 3 (Bottom Right)" },
    { value = "MultiBarRight",          text = "Action Bar 4 (Right)" },
    { value = "MultiBarLeft",           text = "Action Bar 5 (Left)" },
    { value = "MultiBar5",              text = "Action Bar 6" },
    { value = "MultiBar6",              text = "Action Bar 7" },
    { value = "MultiBar7",              text = "Action Bar 8" },
    { value = "PetActionButton",        text = "Pet Bar" },
    { value = "StanceButton",           text = "Stance Bar" },
}

function TomoMod_ConfigPanel_ActionBars(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    -- ===== SECTION: Skin =====
    local _, ny = W.CreateSectionHeader(c, L["section_action_bars"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_abs_enable"], TomoModDB.actionBarSkin.enabled, y, function(v)
        TomoModDB.actionBarSkin.enabled = v
        if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_abs_class_color"], TomoModDB.actionBarSkin.useClassColor, y, function(v)
        TomoModDB.actionBarSkin.useClassColor = v
        if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.UpdateColors() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_abs_shift_reveal"], TomoModDB.actionBarSkin.shiftReveal or false, y, function(v)
        TomoModDB.actionBarSkin.shiftReveal = v
        if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.SetShiftReveal(v) end
    end)
    y = ny

    -- ===== SECTION: Per-Bar Opacity =====
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_bar_opacity"], y)
    y = ny

    -- Ensure barOpacity table exists
    if not TomoModDB.actionBarSkin.barOpacity then
        TomoModDB.actionBarSkin.barOpacity = {}
    end

    -- State: currently selected bar
    local selectedBar = BAR_LIST[1].value
    local opacitySliderFrame

    -- Dropdown to pick which bar
    local _, ny = W.CreateDropdown(c, L["opt_abs_select_bar"], BAR_LIST, selectedBar, y, function(barKey)
        selectedBar = barKey
        -- Update slider to reflect this bar's opacity
        local val = TomoModDB.actionBarSkin.barOpacity[barKey] or 100
        if opacitySliderFrame then
            opacitySliderFrame:SetValue(val)
        end
    end)
    y = ny

    -- Opacity slider
    local sliderFrame, ny = W.CreateSlider(c, L["opt_abs_opacity"], TomoModDB.actionBarSkin.barOpacity[selectedBar] or 100, 0, 100, 5, y, function(v)
        TomoModDB.actionBarSkin.barOpacity[selectedBar] = v
        if TomoMod_ActionBarSkin and TomoMod_ActionBarSkin.ApplyBarOpacity then
            TomoMod_ActionBarSkin.ApplyBarOpacity(selectedBar, v)
        end
    end, "%d%%")
    y = ny
    opacitySliderFrame = sliderFrame

    -- ===== Apply All button =====
    local _, ny = W.CreateButton(c, L["btn_abs_apply_all_opacity"], 260, y, function()
        local val = opacitySliderFrame:GetValue()
        for _, bar in ipairs(BAR_LIST) do
            TomoModDB.actionBarSkin.barOpacity[bar.value] = val
            if TomoMod_ActionBarSkin and TomoMod_ActionBarSkin.ApplyBarOpacity then
                TomoMod_ActionBarSkin.ApplyBarOpacity(bar.value, val)
            end
        end
        print("|cff0cd29fTomoMod:|r " .. string.format(L["msg_abs_all_opacity"], val))
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

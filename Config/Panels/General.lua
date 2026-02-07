-- =====================================
-- Panels/General.lua — General & About
-- =====================================

local W = TomoMod_Widgets
local L = TomoMod_L

function TomoMod_ConfigPanel_General(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child

    local y = -10

    -- ABOUT
    local _, ny = W.CreateSectionHeader(c, L["section_about"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["about_text"], y)
    y = ny - 6

    -- GENERAL
    local _, ny = W.CreateSectionHeader(c, L["section_general"], y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_reset_all"], 200, y, function()
        StaticPopup_Show("TOMOMOD_RESET_ALL")
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_reset_all"], y)
    y = ny - 10

    -- MINIMAP
    local _, ny = W.CreateSectionHeader(c, L["section_minimap"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_minimap_enable"], TomoModDB.minimap.enabled, y, function(v)
        TomoModDB.minimap.enabled = v
        if v and TomoMod_Minimap then TomoMod_Minimap.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_size"], TomoModDB.minimap.size, 150, 300, 10, y, function(v)
        TomoModDB.minimap.size = v
        if Minimap then Minimap:SetSize(v, v) end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_scale"], TomoModDB.minimap.scale, 0.5, 2.0, 0.1, y, function(v)
        TomoModDB.minimap.scale = v
        if TomoMod_Minimap then TomoMod_Minimap.ApplyScale() end
    end, "%.1f")
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_border"], {
        { text = L["border_class"], value = "class" },
        { text = L["border_black"], value = "black" },
    }, TomoModDB.minimap.borderColor, y, function(v)
        TomoModDB.minimap.borderColor = v
        if TomoMod_Minimap then TomoMod_Minimap.CreateBorder() end
    end)
    y = ny

    -- INFO PANEL
    local _, ny = W.CreateSectionHeader(c, L["section_info_panel"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_enable"], TomoModDB.infoPanel.enabled, y, function(v)
        TomoModDB.infoPanel.enabled = v
        if v then
            if TomoMod_InfoPanel then TomoMod_InfoPanel.Initialize() end
        else
            local p = _G["TomoModInfoPanel"]
            if p then p:Hide() end
        end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_durability"], TomoModDB.infoPanel.showDurability, y, function(v)
        TomoModDB.infoPanel.showDurability = v
        if TomoMod_InfoPanel then TomoMod_InfoPanel.Update() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_time"], TomoModDB.infoPanel.showTime, y, function(v)
        TomoModDB.infoPanel.showTime = v
        if TomoMod_InfoPanel then TomoMod_InfoPanel.Update() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_24h_format"], TomoModDB.infoPanel.use24Hour, y, function(v)
        TomoModDB.infoPanel.use24Hour = v
        if TomoMod_InfoPanel then TomoMod_InfoPanel.Update() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_scale"], TomoModDB.infoPanel.scale, 0.5, 2.0, 0.1, y, function(v)
        TomoModDB.infoPanel.scale = v
        if TomoMod_InfoPanel then TomoMod_InfoPanel.UpdateAppearance() end
    end, "%.1f")
    y = ny

    local _, ny = W.CreateButton(c, L["btn_reset_position"], 160, y, function()
        TomoModDB.infoPanel.position = nil
        if TomoMod_InfoPanel then TomoMod_InfoPanel.SetPosition() end
    end)
    y = ny

    -- CURSOR RING
    local _, ny = W.CreateSectionHeader(c, L["section_cursor_ring"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_enable"], TomoModDB.cursorRing.enabled, y, function(v)
        TomoModDB.cursorRing.enabled = v
        if TomoMod_CursorRing then TomoMod_CursorRing.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_class_color"], TomoModDB.cursorRing.useClassColor, y, function(v)
        TomoModDB.cursorRing.useClassColor = v
        if TomoMod_CursorRing then TomoMod_CursorRing.ApplyColor() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_anchor_tooltip_ring"], TomoModDB.cursorRing.anchorTooltip, y, function(v)
        TomoModDB.cursorRing.anchorTooltip = v
        if TomoMod_CursorRing then
            TomoMod_CursorRing.SetupTooltipAnchor()
            TomoMod_CursorRing.Toggle(true)
        end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_scale"], TomoModDB.cursorRing.scale, 0.5, 3.0, 0.1, y, function(v)
        TomoModDB.cursorRing.scale = v
        if TomoMod_CursorRing then TomoMod_CursorRing.ApplyScale() end
    end, "%.1f")
    y = ny - 20

    -- Resize child
    c:SetHeight(math.abs(y) + 20)

    return scroll
end

-- Static popup for reset
StaticPopupDialogs["TOMOMOD_RESET_ALL"] = {
    text = L["popup_reset_text"],
    button1 = L["popup_confirm"],
    button2 = L["popup_cancel"],
    OnAccept = function()
        TomoMod_ResetDatabase()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Panels/General.lua v2.7.0
local W = TomoMod_Widgets
local L = TomoMod_L

function TomoMod_ConfigPanel_General(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -12

    -- ═══════════════════════════════════════════════
    -- MINIMAP
    -- ═══════════════════════════════════════════════
    local card, cy = W.CreateCard(c, L["section_minimap"] or "Minimap", y)

    local _, cy = W.CreateCheckbox(card.inner, L["opt_minimap_enable"], TomoModDB.minimap.enabled, cy, function(v)
        TomoModDB.minimap.enabled = v
        if v and TomoMod_Minimap then TomoMod_Minimap.ApplySettings() end
    end)

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col)
            local _, ny = W.CreateSlider(col, L["opt_size"] or "Taille", TomoModDB.minimap.size, 150, 300, 10, 0, function(v)
                TomoModDB.minimap.size = v
                if Minimap then Minimap:SetSize(v, v) end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateSlider(col, L["opt_scale"] or "Échelle", TomoModDB.minimap.scale, 0.5, 2.0, 0.1, 0, function(v)
                TomoModDB.minimap.scale = v
                if TomoMod_Minimap then TomoMod_Minimap.ApplyScale() end
            end, "%.1f")
            return ny
        end)

    local _, cy = W.CreateDropdown(card.inner, L["opt_border"] or "Bordure", {
        { text = L["border_class"] or "Couleur de classe", value = "class"  },
        { text = L["border_black"] or "Noir",              value = "black"  },
    }, TomoModDB.minimap.borderColor, cy, function(v)
        TomoModDB.minimap.borderColor = v
        if TomoMod_Minimap then TomoMod_Minimap.CreateBorder() end
    end)

    y = W.FinalizeCard(card, cy)

    -- ═══════════════════════════════════════════════
    -- INFO PANEL
    -- ═══════════════════════════════════════════════
    local card2, cy = W.CreateCard(c, L["section_info_panel"] or "Info Panel", y)

    local _, cy = W.CreateCheckbox(card2.inner, L["opt_enable"] or "Activer", TomoModDB.infoPanel.enabled, cy, function(v)
        TomoModDB.infoPanel.enabled = v
        if v then
            if TomoMod_InfoPanel then TomoMod_InfoPanel.Initialize() end
        else
            if TomoMod_InfoPanel then TomoMod_InfoPanel.Hide() end
        end
    end)

    local _, cy = W.CreateTwoColumnRow(card2.inner, cy,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["opt_time"] or "Heure", TomoModDB.infoPanel.showTime, 0, function(v)
                TomoModDB.infoPanel.showTime = v
                if TomoMod_InfoPanel then TomoMod_InfoPanel.Update() end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["opt_24h_format"] or "Format 24h", TomoModDB.infoPanel.use24Hour, 0, function(v)
                TomoModDB.infoPanel.use24Hour = v
                if TomoMod_InfoPanel then TomoMod_InfoPanel.Update() end
            end)
            return ny
        end)

    local _, cy = W.CreateTwoColumnRow(card2.inner, cy,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["opt_show_coords"] or "Coordonnées", TomoModDB.infoPanel.showCoords ~= false, 0, function(v)
                TomoModDB.infoPanel.showCoords = v
                if TomoMod_InfoPanel then TomoMod_InfoPanel.Update() end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["opt_durability"] or "Durabilité", TomoModDB.infoPanel.showDurability ~= false, 0, function(v)
                TomoModDB.infoPanel.showDurability = v
                if TomoMod_InfoPanel then TomoMod_InfoPanel.Update() end
            end)
            return ny
        end)

    y = W.FinalizeCard(card2, cy)

    -- ═══════════════════════════════════════════════
    -- CURSOR RING
    -- ═══════════════════════════════════════════════
    local card3, cy = W.CreateCard(c, L["section_cursor_ring"] or "Anneau de curseur", y)

    local _, cy = W.CreateCheckbox(card3.inner, L["opt_enable"] or "Activer", TomoModDB.cursorRing.enabled, cy, function(v)
        TomoModDB.cursorRing.enabled = v
        if TomoMod_CursorRing then TomoMod_CursorRing.ApplySettings() end
    end)

    local _, cy = W.CreateTwoColumnRow(card3.inner, cy,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["opt_class_color"] or "Couleur de classe", TomoModDB.cursorRing.useClassColor, 0, function(v)
                TomoModDB.cursorRing.useClassColor = v
                if TomoMod_CursorRing then TomoMod_CursorRing.ApplyColor() end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["opt_anchor_tooltip_ring"] or "Ancrer tooltip", TomoModDB.cursorRing.anchorTooltip, 0, function(v)
                TomoModDB.cursorRing.anchorTooltip = v
                if TomoMod_CursorRing then TomoMod_CursorRing.SetupTooltipAnchor() end
            end)
            return ny
        end)

    local _, cy = W.CreateSlider(card3.inner, L["opt_scale"] or "Échelle", TomoModDB.cursorRing.scale, 0.5, 3.0, 0.1, cy, function(v)
        TomoModDB.cursorRing.scale = v
        if TomoMod_CursorRing then TomoMod_CursorRing.ApplyScale() end
    end, "%.1f")

    y = W.FinalizeCard(card3, cy)

    -- ═══════════════════════════════════════════════
    -- GÉNÉRAL
    -- ═══════════════════════════════════════════════
    local card4, cy = W.CreateCard(c, L["section_general"] or "Général", y)

    local _, cy = W.CreateInfoText(card4.inner, L["about_text"] or "TomoMod — Interface personnalisée par TomoAniki.", cy)

    local _, cy = W.CreateButton(card4.inner, L["btn_relaunch_installer"] or "Relancer l'installeur", 220, cy, function()
        if TomoMod_Installer then
            TomoMod_Installer.Show()
            if TomoMod_Config and TomoMod_Config.Hide then TomoMod_Config.Hide() end
        end
    end)
    local _, cy = W.CreateInfoText(card4.inner, L["info_relaunch_installer"] or "Lance l'assistant de configuration en 12 étapes.", cy)

    local _, cy = W.CreateButton(card4.inner, L["btn_reset_all"] or "Réinitialiser tout", 220, cy, function()
        StaticPopup_Show("TOMOMOD_RESET_ALL")
    end)
    local _, cy = W.CreateInfoText(card4.inner, L["info_reset_all"] or "Réinitialise tous les paramètres et recharge l'UI.", cy)

    y = W.FinalizeCard(card4, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

StaticPopupDialogs["TOMOMOD_RESET_ALL"] = {
    text     = L["popup_reset_text"]   or "Réinitialiser tous les paramètres ?",
    button1  = L["popup_confirm"]      or "Confirmer",
    button2  = L["popup_cancel"]       or "Annuler",
    OnAccept = function() TomoMod_ResetDatabase(); ReloadUI() end,
    timeout       = 0,
    whileDead     = true,
    hideOnEscape  = true,
    preferredIndex = 3,
}

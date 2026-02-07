-- =====================================
-- Panels/General.lua — General & About
-- =====================================

local W = TomoMod_Widgets

function TomoMod_ConfigPanel_General(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child

    local y = -10

    -- ABOUT
    local _, ny = W.CreateSectionHeader(c, "À propos", y)
    y = ny

    local _, ny = W.CreateInfoText(c, "|cff0cd29fTomoMod|r v2.1.2 par TomoAniki\nInterface légère avec QOL, UnitFrames et Nameplates.\nTapez /tm help pour la liste des commandes.", y)
    y = ny - 6

    -- GENERAL
    local _, ny = W.CreateSectionHeader(c, "Général", y)
    y = ny

    local _, ny = W.CreateButton(c, "Réinitialiser tout", 200, y, function()
        StaticPopup_Show("TOMOMOD_RESET_ALL")
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, "Cela réinitialise TOUS les paramètres et recharge l'UI.", y)
    y = ny - 10

    -- MINIMAP
    local _, ny = W.CreateSectionHeader(c, "Minimap", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Activer la minimap personnalisée", TomoModDB.minimap.enabled, y, function(v)
        TomoModDB.minimap.enabled = v
        if v and TomoMod_Minimap then TomoMod_Minimap.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Taille", TomoModDB.minimap.size, 150, 300, 10, y, function(v)
        TomoModDB.minimap.size = v
        if Minimap then Minimap:SetSize(v, v) end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Échelle", TomoModDB.minimap.scale, 0.5, 2.0, 0.1, y, function(v)
        TomoModDB.minimap.scale = v
        if TomoMod_Minimap then TomoMod_Minimap.ApplyScale() end
    end, "%.1f")
    y = ny

    local _, ny = W.CreateDropdown(c, "Bordure", {
        { text = "Couleur de classe", value = "class" },
        { text = "Noir", value = "black" },
    }, TomoModDB.minimap.borderColor, y, function(v)
        TomoModDB.minimap.borderColor = v
        if TomoMod_Minimap then TomoMod_Minimap.CreateBorder() end
    end)
    y = ny

    -- INFO PANEL
    local _, ny = W.CreateSectionHeader(c, "Info Panel", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Activer", TomoModDB.infoPanel.enabled, y, function(v)
        TomoModDB.infoPanel.enabled = v
        if v then
            if TomoMod_InfoPanel then TomoMod_InfoPanel.Initialize() end
        else
            local p = _G["TomoModInfoPanel"]
            if p then p:Hide() end
        end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Durabilité (Gear)", TomoModDB.infoPanel.showDurability, y, function(v)
        TomoModDB.infoPanel.showDurability = v
        if TomoMod_InfoPanel then TomoMod_InfoPanel.Update() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Heure", TomoModDB.infoPanel.showTime, y, function(v)
        TomoModDB.infoPanel.showTime = v
        if TomoMod_InfoPanel then TomoMod_InfoPanel.Update() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Format 24h", TomoModDB.infoPanel.use24Hour, y, function(v)
        TomoModDB.infoPanel.use24Hour = v
        if TomoMod_InfoPanel then TomoMod_InfoPanel.Update() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Échelle", TomoModDB.infoPanel.scale, 0.5, 2.0, 0.1, y, function(v)
        TomoModDB.infoPanel.scale = v
        if TomoMod_InfoPanel then TomoMod_InfoPanel.UpdateAppearance() end
    end, "%.1f")
    y = ny

    local _, ny = W.CreateButton(c, "Reset Position", 160, y, function()
        TomoModDB.infoPanel.position = nil
        if TomoMod_InfoPanel then TomoMod_InfoPanel.SetPosition() end
    end)
    y = ny

    -- CURSOR RING
    local _, ny = W.CreateSectionHeader(c, "Cursor Ring", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Activer", TomoModDB.cursorRing.enabled, y, function(v)
        TomoModDB.cursorRing.enabled = v
        if TomoMod_CursorRing then TomoMod_CursorRing.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Couleur de classe", TomoModDB.cursorRing.useClassColor, y, function(v)
        TomoModDB.cursorRing.useClassColor = v
        if TomoMod_CursorRing then TomoMod_CursorRing.ApplyColor() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Ancrer Tooltip + Afficher Ring", TomoModDB.cursorRing.anchorTooltip, y, function(v)
        TomoModDB.cursorRing.anchorTooltip = v
        if TomoMod_CursorRing then
            TomoMod_CursorRing.SetupTooltipAnchor()
            TomoMod_CursorRing.Toggle(true)
        end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Échelle", TomoModDB.cursorRing.scale, 0.5, 3.0, 0.1, y, function(v)
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
    text = "|cff0cd29fTomoMod|r\n\nRéinitialiser TOUS les paramètres ?\nCela rechargera votre UI.",
    button1 = "Confirmer",
    button2 = "Annuler",
    OnAccept = function()
        TomoMod_ResetDatabase()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

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

    local _, cy = W.CreateCheckbox(card.inner, L["opt_minimap_tracking"] or "Bouton de pistage", TomoModDB.minimap.showTracking ~= false, cy, function(v)
        TomoModDB.minimap.showTracking = v
        if TomoMod_Minimap and TomoMod_Minimap.CreateTrackingButton then
            TomoMod_Minimap.CreateTrackingButton()
        end
    end)

    -- [3.0.2] Style du bouton de pistage : TomoMod ou natif Blizzard
    local _, cy = W.CreateDropdown(card.inner, L["opt_tracking_style"] or "Style du bouton de pistage", {
        { text = L["minimap_style_tomo"] or "TomoMod",  value = "tomomod"  },
        { text = L["minimap_style_bliz"] or "Blizzard",  value = "blizzard" },
    }, TomoModDB.minimap.trackingStyle or "tomomod", cy, function(v)
        TomoModDB.minimap.trackingStyle = v
        if TomoMod_Minimap then
            if TomoMod_Minimap.CreateTrackingButton then TomoMod_Minimap.CreateTrackingButton() end
            if TomoMod_Minimap.HideNativeClutter then TomoMod_Minimap.HideNativeClutter() end
        end
    end)

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["opt_minimap_mail"] or "Courrier", TomoModDB.minimap.showMail ~= false, 0, function(v)
                TomoModDB.minimap.showMail = v
                if TomoMod_Minimap and TomoMod_Minimap.ApplyNativeIndicators then TomoMod_Minimap.ApplyNativeIndicators() end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["opt_minimap_difficulty"] or "Difficulté", TomoModDB.minimap.showDifficulty ~= false, 0, function(v)
                TomoModDB.minimap.showDifficulty = v
                if TomoMod_Minimap and TomoMod_Minimap.ApplyNativeIndicators then TomoMod_Minimap.ApplyNativeIndicators() end
            end)
            return ny
        end)

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["opt_minimap_expansion"] or "Bouton d'extension", TomoModDB.minimap.showExpansion ~= false, 0, function(v)
                TomoModDB.minimap.showExpansion = v
                if TomoMod_Minimap and TomoMod_Minimap.ApplyNativeIndicators then TomoMod_Minimap.ApplyNativeIndicators() end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["opt_minimap_crafting"] or "Commandes de craft", TomoModDB.minimap.showCraftingOrder ~= false, 0, function(v)
                TomoModDB.minimap.showCraftingOrder = v
                if TomoMod_Minimap and TomoMod_Minimap.ApplyNativeIndicators then TomoMod_Minimap.ApplyNativeIndicators() end
            end)
            return ny
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
    -- INDICATEURS DE LA MINIMAP (position / taille)
    -- ═══════════════════════════════════════════════
    local cardI, ciy = W.CreateCard(c, L["section_minimap_indicators"] or "Indicateurs de la minimap", y)

    -- État courant : quel indicateur on configure
    local INDS = {
        { key = "tracking",   label = L["opt_minimap_tracking"]   or "Pistage" },
        { key = "mail",       label = L["opt_minimap_mail"]       or "Courrier" },
        { key = "difficulty", label = L["opt_minimap_difficulty"] or "Difficulté" },
        { key = "expansion",  label = L["opt_minimap_expansion"]  or "Extension" },
        { key = "crafting",   label = L["opt_minimap_crafting"]   or "Commandes de craft" },
    }
    local selKey = "tracking"

    local function EnsureCfg(key)
        TomoModDB.minimap.indicators = TomoModDB.minimap.indicators or {}
        TomoModDB.minimap.indicators[key] = TomoModDB.minimap.indicators[key] or {}
        return TomoModDB.minimap.indicators[key]
    end

    -- Ré-applique l'indicateur courant en jeu (live)
    local function ApplyOne(key)
        if not TomoMod_Minimap then return end
        if key == "tracking" then
            if TomoMod_Minimap.CreateTrackingButton then TomoMod_Minimap.CreateTrackingButton() end
        else
            if TomoMod_Minimap.ApplyNativeIndicators then TomoMod_Minimap.ApplyNativeIndicators() end
        end
    end

    local _, ciy = W.CreateInfoText(cardI.inner, L["info_minimap_indicators"]
        or "Choisis un indicateur, puis règle son coin, sa taille et son décalage. Appliqué en direct.", ciy)

    -- Contrôles (déclarés avant le sélecteur pour pouvoir être mis à jour)
    local cornerDD, scaleSL, offXSL, offYSL

    -- Sélecteur d'indicateur
    local indOpts = {}
    for _, e in ipairs(INDS) do indOpts[#indOpts+1] = { text = e.label, value = e.key } end
    local _, ciy = W.CreateDropdown(cardI.inner, L["opt_indicator"] or "Indicateur", indOpts, selKey, ciy, function(v)
        selKey = v
        local cfg = EnsureCfg(selKey)
        local dC, dS, dX, dY = TomoMod_Minimap.GetIndicatorCfg(selKey)
        -- Met à jour les widgets pour refléter l'indicateur choisi
        if cornerDD then cornerDD:SetValue(cfg.corner or dC) end
        if scaleSL  then scaleSL:SetValue(cfg.scale or dS) end
        if offXSL   then offXSL:SetValue(cfg.x or dX) end
        if offYSL   then offYSL:SetValue(cfg.y or dY) end
    end)

    -- Valeurs initiales (indicateur "tracking")
    local iC, iS, iX, iY = TomoMod_Minimap and TomoMod_Minimap.GetIndicatorCfg(selKey)
    iC = iC or "TOPLEFT"; iS = iS or 1.0; iX = iX or 0; iY = iY or 0

    -- Coin + Échelle
    local _, ciy = W.CreateTwoColumnRow(cardI.inner, ciy,
        function(col)
            local f, ny = W.CreateDropdown(col, L["opt_corner"] or "Coin", {
                { text = L["corner_topleft"]     or "Haut gauche",  value = "TOPLEFT"     },
                { text = L["corner_topright"]    or "Haut droite",  value = "TOPRIGHT"    },
                { text = L["corner_bottomleft"]  or "Bas gauche",   value = "BOTTOMLEFT"  },
                { text = L["corner_bottomright"] or "Bas droite",   value = "BOTTOMRIGHT" },
            }, iC, 0, function(v)
                EnsureCfg(selKey).corner = v
                ApplyOne(selKey)
            end)
            cornerDD = f
            return ny
        end,
        function(col)
            local f, ny = W.CreateSlider(col, L["opt_size"] or "Taille", iS, 0.5, 2.0, 0.05, 0, function(v)
                EnsureCfg(selKey).scale = v
                ApplyOne(selKey)
            end, "%.2f")
            scaleSL = f
            return ny
        end)

    -- Décalage X + Y
    local _, ciy = W.CreateTwoColumnRow(cardI.inner, ciy,
        function(col)
            local f, ny = W.CreateSlider(col, L["opt_offset_x"] or "Décalage X", iX, -60, 60, 1, 0, function(v)
                EnsureCfg(selKey).x = v
                ApplyOne(selKey)
            end, "%d")
            offXSL = f
            return ny
        end,
        function(col)
            local f, ny = W.CreateSlider(col, L["opt_offset_y"] or "Décalage Y", iY, -60, 60, 1, 0, function(v)
                EnsureCfg(selKey).y = v
                ApplyOne(selKey)
            end, "%d")
            offYSL = f
            return ny
        end)

    y = W.FinalizeCard(cardI, ciy)

    -- ═══════════════════════════════════════════════
    -- BOUTONS D'ADDON (collecteur)
    -- ═══════════════════════════════════════════════
    local cardB, cby = W.CreateCard(c, L["section_buttonbag"] or "Boutons d'addon", y)

    local function EnsureBag()
        TomoModDB.minimap.buttonBag = TomoModDB.minimap.buttonBag or {}
        return TomoModDB.minimap.buttonBag
    end
    local function ApplyBag()
        if TomoMod_Minimap and TomoMod_Minimap.CreateButtonBag then TomoMod_Minimap.CreateButtonBag() end
        if TomoMod_Minimap and TomoMod_Minimap.RefreshButtonBag then TomoMod_Minimap.RefreshButtonBag() end
    end

    local _, cby = W.CreateInfoText(cardB.inner, L["info_buttonbag"]
        or "Regroupe les boutons d'addon de la minimap dans une boîte. Clique le bouton sur la minimap pour l'ouvrir.", cby)

    local _, cby = W.CreateCheckbox(cardB.inner, L["opt_buttonbag_enable"] or "Activer le collecteur", EnsureBag().enabled ~= false, cby, function(v)
        EnsureBag().enabled = v
        ApplyBag()
        if TomoMod_Minimap and TomoMod_Minimap.HideNativeClutter then TomoMod_Minimap.HideNativeClutter() end
    end)

    -- [3.0.2] Style du collecteur : boîte TomoMod ou compartiment natif Blizzard
    local _, cby = W.CreateDropdown(cardB.inner, L["opt_collector_style"] or "Style du collecteur", {
        { text = L["collector_style_tomo"] or "TomoMod (boîte)",   value = "tomomod"  },
        { text = L["collector_style_bliz"] or "Blizzard (natif)",  value = "blizzard" },
    }, TomoModDB.minimap.collectorStyle or "tomomod", cby, function(v)
        TomoModDB.minimap.collectorStyle = v
        ApplyBag()
        if TomoMod_Minimap and TomoMod_Minimap.HideNativeClutter then TomoMod_Minimap.HideNativeClutter() end
    end)

    local bagDB = EnsureBag()

    -- [3.0.1] Position du collecteur : sur la minimap (coin) ou collé à l'horloge
    local _, cby = W.CreateDropdown(cardB.inner, L["opt_buttonbag_anchor"] or "Position du bouton", {
        { text = L["buttonbag_anchor_corner"] or "Sur la minimap (coin)", value = "corner"      },
        { text = L["buttonbag_anchor_clockl"] or "Gauche de l'horloge",   value = "clock-left"  },
        { text = L["buttonbag_anchor_clockr"] or "Droite de l'horloge",   value = "clock-right" },
    }, bagDB.anchor or "corner", cby, function(v)
        EnsureBag().anchor = v
        ApplyBag()
    end)

    local _, cby = W.CreateTwoColumnRow(cardB.inner, cby,
        function(col)
            local f, ny = W.CreateDropdown(col, L["opt_corner"] or "Coin", {
                { text = L["corner_topleft"]     or "Haut gauche",  value = "TOPLEFT"     },
                { text = L["corner_topright"]    or "Haut droite",  value = "TOPRIGHT"    },
                { text = L["corner_bottomleft"]  or "Bas gauche",   value = "BOTTOMLEFT"  },
                { text = L["corner_bottomright"] or "Bas droite",   value = "BOTTOMRIGHT" },
            }, bagDB.corner or "BOTTOMLEFT", 0, function(v)
                EnsureBag().corner = v
                ApplyBag()
            end)
            return ny
        end,
        function(col)
            local f, ny = W.CreateSlider(col, L["opt_buttonbag_columns"] or "Colonnes", bagDB.columns or 5, 1, 10, 1, 0, function(v)
                EnsureBag().columns = v
                -- RelayoutBag : les boutons sont déjà dans bagFrame.content,
                -- un rescan (ApplyBag) ne les retrouverait plus.
                if TomoMod_Minimap and TomoMod_Minimap.RelayoutBag then TomoMod_Minimap.RelayoutBag() end
            end, "%d")
            return ny
        end)

    local _, cby = W.CreateSlider(cardB.inner, L["opt_buttonbag_iconsize"] or "Taille des icônes", bagDB.iconSize or 28, 16, 40, 1, cby, function(v)
        EnsureBag().iconSize = v
        -- RelayoutBag : les boutons sont déjà dans bagFrame.content,
        -- un rescan (ApplyBag) ne les retrouverait plus.
        if TomoMod_Minimap and TomoMod_Minimap.RelayoutBag then TomoMod_Minimap.RelayoutBag() end
    end, "%d")

    local _, cby = W.CreateButton(cardB.inner, L["btn_buttonbag_rescan"] or "Rescanner les boutons", 220, cby, function()
        if TomoMod_Minimap and TomoMod_Minimap.RefreshButtonBag then TomoMod_Minimap.RefreshButtonBag() end
    end)

    y = W.FinalizeCard(cardB, cby)

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

    local ver = "v" .. (C_AddOns.GetAddOnMetadata("TomoMod", "Version") or "?")
    local _, cy = W.CreateInfoText(card4.inner, string.format(L["about_text"] or "TomoMod %s — Interface personnalisée par TomoAniki.", ver), cy)

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

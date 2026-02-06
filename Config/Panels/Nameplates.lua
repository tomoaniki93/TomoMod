-- =====================================
-- Panels/Nameplates.lua — Nameplates Config
-- =====================================

local W = TomoMod_Widgets

function TomoMod_ConfigPanel_Nameplates(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.nameplates

    local y = -10

    -- GENERAL
    local _, ny = W.CreateSectionHeader(c, "Paramètres Généraux", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Activer les Nameplates TomoMod", db.enabled, y, function(v)
        db.enabled = v
        if TomoMod_Nameplates then
            if v then
                TomoMod_Nameplates.Enable()
            else
                TomoMod_Nameplates.Disable()
            end
        end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, "Remplace les nameplates Blizzard par un style minimaliste personnalisable.", y)
    y = ny

    -- DIMENSIONS
    local _, ny = W.CreateSectionHeader(c, "Dimensions", y)
    y = ny

    local _, ny = W.CreateSlider(c, "Largeur", db.width, 60, 300, 5, y, function(v)
        db.width = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Hauteur", db.height, 6, 40, 1, y, function(v)
        db.height = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Taille police nom", db.nameFontSize or 10, 6, 20, 1, y, function(v)
        db.nameFontSize = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    -- DISPLAY
    local _, ny = W.CreateSectionHeader(c, "Affichage", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Afficher le nom", db.showName, y, function(v)
        db.showName = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Afficher le niveau", db.showLevel, y, function(v)
        db.showLevel = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Afficher le % de santé", db.showHealthText, y, function(v)
        db.showHealthText = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, "Format de santé", {
        { text = "Pourcentage (75%)", value = "percent" },
        { text = "Courant (25.3K)", value = "current" },
        { text = "Courant + %", value = "current_percent" },
    }, db.healthTextFormat or "percent", y, function(v)
        db.healthTextFormat = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Afficher classification (élite, rare, boss)", db.showClassification, y, function(v)
        db.showClassification = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Indicateur de menace", db.showThreat, y, function(v)
        db.showThreat = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Couleurs de classe (joueurs)", db.useClassColors, y, function(v)
        db.useClassColors = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    -- CASTBAR
    local _, ny = W.CreateSectionHeader(c, "Castbar", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Afficher la castbar", db.showCastbar, y, function(v)
        db.showCastbar = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Hauteur castbar", db.castbarHeight, 4, 20, 1, y, function(v)
        db.castbarHeight = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    -- AURAS
    local _, ny = W.CreateSectionHeader(c, "Auras", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Afficher les auras", db.showAuras, y, function(v)
        db.showAuras = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Taille des icônes", db.auraSize, 12, 36, 1, y, function(v)
        db.auraSize = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Nombre max", db.maxAuras, 1, 10, 1, y, function(v)
        db.maxAuras = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Seulement mes debuffs", db.showOnlyMyAuras, y, function(v)
        db.showOnlyMyAuras = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    -- ALPHA
    local _, ny = W.CreateSectionHeader(c, "Transparence", y)
    y = ny

    local _, ny = W.CreateSlider(c, "Alpha sélectionné", db.selectedAlpha, 0.3, 1.0, 0.05, y, function(v)
        db.selectedAlpha = v
    end, "%.2f")
    y = ny

    local _, ny = W.CreateSlider(c, "Alpha non-sélectionné", db.unselectedAlpha, 0.3, 1.0, 0.05, y, function(v)
        db.unselectedAlpha = v
    end, "%.2f")
    y = ny

    -- STACKING
    local _, ny = W.CreateSectionHeader(c, "Empilement", y)
    y = ny

    local _, ny = W.CreateSlider(c, "Chevauchement vertical", db.overlapV or 1.6, 0.5, 3.0, 0.1, y, function(v)
        db.overlapV = v
        if TomoMod_Nameplates then TomoMod_Nameplates.ApplySettings() end
    end, "%.1f")
    y = ny

    local _, ny = W.CreateSlider(c, "Limite haute écran", db.topInset or 0.065, 0.01, 0.5, 0.005, y, function(v)
        db.topInset = v
        if TomoMod_Nameplates then TomoMod_Nameplates.ApplySettings() end
    end, "%.3f")
    y = ny

    -- COLORS
    local _, ny = W.CreateSectionHeader(c, "Couleurs", y)
    y = ny

    local _, ny = W.CreateColorPicker(c, "Hostile (Ennemi)", db.colors.hostile, y, function(r, g, b)
        db.colors.hostile = { r = r, g = g, b = b }
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, "Neutre", db.colors.neutral, y, function(r, g, b)
        db.colors.neutral = { r = r, g = g, b = b }
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, "Amical", db.colors.friendly, y, function(r, g, b)
        db.colors.friendly = { r = r, g = g, b = b }
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, "Tagué (tapped)", db.colors.tapped, y, function(r, g, b)
        db.colors.tapped = { r = r, g = g, b = b }
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    -- CLASSIFICATION COLORS
    local _, ny = W.CreateSectionHeader(c, "Couleurs par Classification", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Couleurs par type d'ennemi", db.useClassificationColors, y, function(v)
        db.useClassificationColors = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, "Boss", db.colors.boss, y, function(r, g, b)
        db.colors.boss = { r = r, g = g, b = b }
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, "Élite / Mini-boss", db.colors.elite, y, function(r, g, b)
        db.colors.elite = { r = r, g = g, b = b }
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, "Rare", db.colors.rare, y, function(r, g, b)
        db.colors.rare = { r = r, g = g, b = b }
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, "Normal", db.colors.normal, y, function(r, g, b)
        db.colors.normal = { r = r, g = g, b = b }
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, "Trivial", db.colors.trivial, y, function(r, g, b)
        db.colors.trivial = { r = r, g = g, b = b }
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    -- TANK
    local _, ny = W.CreateSectionHeader(c, "Mode Tank", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Activer le mode Tank (couleur par menace)", db.tankMode, y, function(v)
        db.tankMode = v
        if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, "Pas de menace", db.tankColors.noThreat, y, function(r, g, b)
        db.tankColors.noThreat = { r = r, g = g, b = b }
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, "Menace faible", db.tankColors.lowThreat, y, function(r, g, b)
        db.tankColors.lowThreat = { r = r, g = g, b = b }
    end)
    y = ny

    local _, ny = W.CreateColorPicker(c, "Menace tenue", db.tankColors.hasThreat, y, function(r, g, b)
        db.tankColors.hasThreat = { r = r, g = g, b = b }
    end)
    y = ny

    -- RESET
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateButton(c, "Réinitialiser Nameplates", 220, y, function()
        TomoMod_ResetModule("nameplates")
        print("|cff0cd29fTomoMod|r Nameplates réinitialisées (reload recommandé)")
    end)
    y = ny - 20

    c:SetHeight(math.abs(y) + 20)
    return scroll
end

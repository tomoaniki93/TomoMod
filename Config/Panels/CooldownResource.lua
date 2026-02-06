-- =====================================
-- Panels/CooldownResource.lua — Cooldown & Resource Config
-- =====================================

local W = TomoMod_Widgets

-- =====================================
-- COLOR SECTION
-- =====================================
local function CreateColorSection(parent, y)
    local db = TomoModDB.resourceBars.colors

    local _, ny = W.CreateSectionHeader(parent, "Couleurs des Ressources", y)
    y = ny

    local entries = {
        { key = "mana",            label = "Mana" },
        { key = "rage",            label = "Rage" },
        { key = "energy",          label = "Energy" },
        { key = "focus",           label = "Focus" },
        { key = "runicPower",      label = "Runic Power" },
        { key = "runesReady",      label = "Runes (prêtes)" },
        { key = "runes",           label = "Runes (cooldown)" },
        { key = "soulShards",      label = "Soul Shards" },
        { key = "astralPower",     label = "Astral Power" },
        { key = "holyPower",       label = "Holy Power" },
        { key = "maelstrom",       label = "Maelstrom" },
        { key = "chi",             label = "Chi" },
        { key = "insanity",        label = "Insanity" },
        { key = "fury",            label = "Fury" },
        { key = "comboPoints",     label = "Combo Points" },
        { key = "arcaneCharges",   label = "Arcane Charges" },
        { key = "essence",         label = "Essence" },
        { key = "stagger",         label = "Stagger" },
        { key = "soulFragments",   label = "Soul Fragments" },
        { key = "tipOfTheSpear",   label = "Tip of the Spear" },
        { key = "maelstromWeapon", label = "Maelstrom Weapon" },
    }

    for _, e in ipairs(entries) do
        if db[e.key] then
            local _, ny = W.CreateColorPicker(parent, e.label, db[e.key], y, function(r, g, b)
                db[e.key].r, db[e.key].g, db[e.key].b = r, g, b
                if TomoMod_ResourceBars and TomoMod_ResourceBars.ApplySettings then
                    TomoMod_ResourceBars.ApplySettings()
                end
            end)
            y = ny
        end
    end

    return y
end

-- =====================================
-- MAIN PANEL
-- =====================================
function TomoMod_ConfigPanel_CooldownResource(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    -- =============================================
    -- COOLDOWN MANAGER (icons Blizzard reskin)
    -- =============================================
    local cdm = TomoModDB.cooldownManager

    local _, ny = W.CreateSectionHeader(c, "Cooldown Manager", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Activer le Cooldown Manager", cdm.enabled, y, function(v)
        cdm.enabled = v
        if TomoMod_CooldownManager then TomoMod_CooldownManager.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, "Reskin des icônes du CooldownManager Blizzard : bordures 1px, overlay de classe quand actif, texte de CD personnalisé, alignement centré des buffs. Placement via Edit Mode Blizzard.", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Afficher les hotkeys", cdm.showHotKey, y, function(v)
        cdm.showHotKey = v
        if TomoMod_CooldownManager then TomoMod_CooldownManager.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Modifier l'opacité (combat / cible)", cdm.combatAlpha, y, function(v)
        cdm.combatAlpha = v
        if TomoMod_CooldownManager then TomoMod_CooldownManager.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Alpha en combat", cdm.alphaInCombat or 1.0, 0, 1, 0.05, y, function(v)
        cdm.alphaInCombat = v
        if TomoMod_CooldownManager then TomoMod_CooldownManager.ApplySettings() end
    end, "%.2f")
    y = ny

    local _, ny = W.CreateSlider(c, "Alpha avec cible (hors combat)", cdm.alphaWithTarget or 0.8, 0, 1, 0.05, y, function(v)
        cdm.alphaWithTarget = v
        if TomoMod_CooldownManager then TomoMod_CooldownManager.ApplySettings() end
    end, "%.2f")
    y = ny

    local _, ny = W.CreateSlider(c, "Alpha hors combat", cdm.alphaOutOfCombat or 0.5, 0, 1, 0.05, y, function(v)
        cdm.alphaOutOfCombat = v
        if TomoMod_CooldownManager then TomoMod_CooldownManager.ApplySettings() end
    end, "%.2f")
    y = ny

    local _, ny = W.CreateInfoText(c, "Le placement des barres se fait via le Edit Mode de Blizzard (Échap → Edit Mode).", y)
    y = ny

    -- =============================================
    -- RESOURCE BARS
    -- =============================================
    local db = TomoModDB.resourceBars

    -- === GENERAL ===
    local _, ny = W.CreateSectionHeader(c, "Barres de Ressources", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Activer les barres de ressources", db.enabled, y, function(v)
        db.enabled = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, "Affiche les ressources de classe (Mana, Rage, Energy, Combo Points, Runes, etc.) avec support adaptatif pour les Druides.", y)
    y = ny

    -- === VISIBILITY ===
    local _, ny = W.CreateSectionHeader(c, "Visibilité", y)
    y = ny

    local _, ny = W.CreateDropdown(c, "Mode de visibilité", {
        { text = "Toujours visible", value = "always" },
        { text = "En combat seulement", value = "combat" },
        { text = "Combat ou cible", value = "target" },
        { text = "Cachée", value = "hidden" },
    }, db.visibilityMode or "always", y, function(v)
        db.visibilityMode = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Alpha en combat", db.combatAlpha or 1.0, 0, 1, 0.05, y, function(v)
        db.combatAlpha = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end, "%.2f")
    y = ny

    local _, ny = W.CreateSlider(c, "Alpha hors combat", db.oocAlpha or 0.5, 0, 1, 0.05, y, function(v)
        db.oocAlpha = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end, "%.2f")
    y = ny

    -- === DIMENSIONS ===
    local _, ny = W.CreateSectionHeader(c, "Dimensions", y)
    y = ny

    local _, ny = W.CreateSlider(c, "Largeur", db.width or 260, 80, 600, 5, y, function(v)
        db.width = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Hauteur barre primaire", db.primaryHeight or 16, 6, 40, 1, y, function(v)
        db.primaryHeight = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Hauteur barre secondaire", db.secondaryHeight or 12, 6, 30, 1, y, function(v)
        db.secondaryHeight = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Échelle globale", db.scale or 1.0, 0.5, 2.0, 0.05, y, function(v)
        db.scale = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end, "%.2f")
    y = ny

    -- === SYNC WITH COOLDOWNS ===
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Synchroniser la largeur avec Essential Cooldowns", db.syncWidthWithCooldowns or false, y, function(v)
        db.syncWidthWithCooldowns = v
        if v and TomoMod_ResourceBars then TomoMod_ResourceBars.SyncWidth() end
    end)
    y = ny

    local _, ny = W.CreateButton(c, "Sync maintenant", 160, y, function()
        if TomoMod_ResourceBars then TomoMod_ResourceBars.SyncWidth() end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, "Aligne la largeur avec le EssentialCooldownViewer du Cooldown Manager Blizzard.", y)
    y = ny

    -- === TEXT & FONT ===
    local _, ny = W.CreateSectionHeader(c, "Texte & Police", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Afficher le texte sur les barres", db.showText, y, function(v)
        db.showText = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, "Alignement du texte", {
        { text = "Gauche", value = "LEFT" },
        { text = "Centre", value = "CENTER" },
        { text = "Droite", value = "RIGHT" },
    }, db.textAlignment or "CENTER", y, function(v)
        db.textAlignment = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Taille de police", db.fontSize or 11, 7, 20, 1, y, function(v)
        db.fontSize = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, "Police", {
        { text = "Poppins Medium", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf" },
        { text = "Poppins Bold", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf" },
        { text = "Expressway", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Expressway.TTF" },
        { text = "Tomo", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Tomo.ttf" },
        { text = "Accidental", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\accidental_pres.ttf" },
        { text = "Défaut WoW", value = STANDARD_TEXT_FONT },
    }, db.font or "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", y, function(v)
        db.font = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    -- === POSITION ===
    local _, ny = W.CreateSectionHeader(c, "Position", y)
    y = ny

    local _, ny = W.CreateButton(c, "Toggle Lock/Unlock (/tm uf)", 260, y, function()
        if TomoMod_UnitFrames and TomoMod_UnitFrames.ToggleLock then
            TomoMod_UnitFrames.ToggleLock()
        end
        if TomoMod_ResourceBars and TomoMod_ResourceBars.ToggleLock then
            TomoMod_ResourceBars.ToggleLock()
        end
    end)
    y = ny

    local _, ny = W.CreateButton(c, "Reset Position", 160, y, function()
        db.position = nil
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
        print("|cff0cd29fTomoMod|r Position des barres de ressources réinitialisée")
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, "Utilisez /tm uf pour déverrouiller et déplacer les barres. La position est sauvegardée automatiquement.", y)
    y = ny

    -- === COLORS ===
    y = CreateColorSection(c, y)

    -- === FOOTER ===
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateInfoText(c, "Les barres s'adaptent automatiquement à votre classe et spé.\nDruide : la ressource change selon la forme (Ours → Rage, Chat → Energy, Moonkin → Astral Power).", y)
    y = ny - 20

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

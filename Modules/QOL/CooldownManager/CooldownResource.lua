-- Panels/CooldownResource.lua v2.7.0 — Cards layout
local W = TomoMod_Widgets
local L = TomoMod_L

local function ApplyRB()  if TomoMod_ResourceBars    then TomoMod_ResourceBars.ApplySettings()    end end
local function ApplyCDM() if TomoMod_CooldownManager then TomoMod_CooldownManager.ApplySettings() end end

local FONT_LIST = {
    { text = "Poppins Medium",    value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"   },
    { text = "Poppins SemiBold",  value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf" },
    { text = "Poppins Bold",      value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Bold.ttf"     },
    { text = "Expressway",        value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Expressway.TTF"       },
    { text = "Tomo",              value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Tomo.ttf"             },
    { text = "Friz Quadrata",     value = "Fonts\\FRIZQT__.TTF"                                             },
    { text = "Arial Narrow",      value = "Fonts\\ARIALN.TTF"                                               },
}

-- ══════════════════════════════════════════════
-- TAB 1 : COOLDOWN MANAGER
-- ══════════════════════════════════════════════
local function BuildCooldownManagerTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local cdm = TomoModDB.cooldownManager
    local y = -12

    -- Activation
    local card, cy = W.CreateCard(c, L["section_cdm"] or "Cooldown Manager", y)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_cdm_enable"] or "Activer le CDM", cdm.enabled, cy, function(v)
        cdm.enabled = v
        if TomoMod_CooldownManager then TomoMod_CooldownManager.SetEnabled(v) end
    end)
    local _, cy = W.CreateInfoText(card.inner, L["info_cdm_description"] or "", cy)
    local _, cy = W.CreateCheckboxPair(card.inner,
        L["opt_cdm_show_hotkeys"] or "Afficher les raccourcis", cdm.showHotKey, cy, function(v) cdm.showHotKey  = v; ApplyCDM() end,
        L["opt_cdm_combat_alpha"] or "Alpha en combat", cdm.combatAlpha,           function(v) cdm.combatAlpha = v; ApplyCDM() end)
    y = W.FinalizeCard(card, cy)

    -- Opacité
    local card2, cy = W.CreateCard(c, L["section_cdm_alpha"] or "Opacité", y)
    local _, cy = W.CreateTwoColumnRow(card2.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_alpha_combat"]  or "En combat",          cdm.alphaInCombat    or 1.0, 0, 1, 0.05, 0, function(v) cdm.alphaInCombat    = v; ApplyCDM() end, "%.2f") return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_alpha_target"]  or "Avec cible",         cdm.alphaWithTarget  or 0.8, 0, 1, 0.05, 0, function(v) cdm.alphaWithTarget  = v; ApplyCDM() end, "%.2f") return ny end)
    local _, cy = W.CreateSlider(card2.inner, L["opt_cdm_alpha_ooc"] or "Hors combat", cdm.alphaOutOfCombat or 0.5, 0, 1, 0.05, cy, function(v) cdm.alphaOutOfCombat = v; ApplyCDM() end, "%.2f")
    y = W.FinalizeCard(card2, cy)

    -- Overlay/Swipe
    local overlayCol = { r = cdm.overlayR or 1, g = cdm.overlayG or 1,    b = cdm.overlayB or 1    }
    local swipeCol   = { r = cdm.swipeR  or 1, g = cdm.swipeG  or 0.95, b = cdm.swipeB  or 0.57 }
    local card3, cy = W.CreateCard(c, L["section_cdm_overlay"] or "Overlay & Swipe", y)
    local _, cy = W.CreateCheckboxPair(card3.inner,
        L["opt_cdm_custom_overlay"] or "Overlay personnalisé", cdm.useCustomOverlay,  cy, function(v) cdm.useCustomOverlay   = v; ApplyCDM() end,
        L["opt_cdm_custom_swipe"]   or "Swipe actif personnalisé",   cdm.customSwipeEnabled,    function(v) cdm.customSwipeEnabled = v; ApplyCDM() end)
    local _, cy = W.CreateColorPickerPair(card3.inner, L["opt_cdm_overlay_color"] or "Overlay", overlayCol, L["opt_cdm_swipe_color"] or "Swipe actif", swipeCol, cy,
        function(r,g,b) cdm.overlayR=r; cdm.overlayG=g; cdm.overlayB=b; ApplyCDM() end,
        function(r,g,b) cdm.swipeR=r;   cdm.swipeG=g;   cdm.swipeB=b;   ApplyCDM() end)
    local _, cy = W.CreateSlider(card3.inner, L["opt_cdm_swipe_alpha"] or "Alpha swipe actif", cdm.swipeA or 0.55, 0, 1, 0.05, cy, function(v) cdm.swipeA = v; ApplyCDM() end, "%.2f")
    -- V3: Separate CD swipe color
    local cdSwipeCol = { r = cdm.cdSwipeR or 0, g = cdm.cdSwipeG or 0, b = cdm.cdSwipeB or 0 }
    local _, cy = W.CreateCheckbox(card3.inner, L["opt_cdm_custom_cd_swipe"] or "Swipe CD personnalisé", cdm.customCDSwipeEnabled or false, cy, function(v) cdm.customCDSwipeEnabled = v; ApplyCDM() end)
    local _, cy = W.CreateColorPicker(card3.inner, L["opt_cdm_cd_swipe_color"] or "Couleur swipe CD", cdSwipeCol, cy, function(r,g,b) cdm.cdSwipeR=r; cdm.cdSwipeG=g; cdm.cdSwipeB=b; ApplyCDM() end)
    local _, cy = W.CreateSlider(card3.inner, L["opt_cdm_cd_swipe_alpha"] or "Alpha swipe CD", cdm.cdSwipeA or 0.7, 0, 1, 0.05, cy, function(v) cdm.cdSwipeA = v; ApplyCDM() end, "%.2f")
    y = W.FinalizeCard(card3, cy)

    -- Utilitaires
    local card4, cy = W.CreateCard(c, L["section_cdm_utility"] or "Utilitaires", y)
    local _, cy = W.CreateCheckbox(card4.inner, L["opt_cdm_dim_utility"] or "Assombrir les sorts utilitaires", cdm.dimUtility, cy, function(v) cdm.dimUtility = v; ApplyCDM() end)
    local _, cy = W.CreateSlider(card4.inner, L["opt_cdm_dim_opacity"] or "Opacité assombrie", cdm.dimOpacity or 0.35, 0.1, 1, 0.05, cy, function(v) cdm.dimOpacity = v; ApplyCDM() end, "%.2f")
    local _, cy = W.CreateInfoText(card4.inner, L["info_cdm_editmode"] or "", cy)
    y = W.FinalizeCard(card4, cy)

    -- Avancé (V3)
    local card5, cy = W.CreateCard(c, L["section_cdm_advanced"] or "Avancé", y)
    local _, cy = W.CreateCheckboxPair(card5.inner,
        L["opt_cdm_hide_gcd"] or "Masquer le GCD", cdm.hideGCD or false, cy, function(v) cdm.hideGCD = v; ApplyCDM() end,
        L["opt_cdm_desaturate"] or "Désaturer en CD", cdm.desaturateOnCD or false, function(v) cdm.desaturateOnCD = v; ApplyCDM() end)
    local _, cy = W.CreateDropdown(card5.inner, L["opt_cdm_buff_alignment"] or "Alignement buffs", {
        { text = L["align_center_outward"] or "Centre→Extérieur", value = "CENTER" },
        { text = L["align_start"] or "Début (gauche)", value = "START" },
        { text = L["align_end"] or "Fin (droite)", value = "END" },
    }, cdm.buffAlignment or "CENTER", cy, function(v) cdm.buffAlignment = v; ApplyCDM() end)
    y = W.FinalizeCard(card5, cy)

    -- Règles de visibilité (V3)
    local visRules = cdm.visibilityRules or {}
    local card6, cy = W.CreateCard(c, L["section_cdm_visibility"] or "Règles de visibilité", y)
    local _, cy = W.CreateInfoText(card6.inner, L["info_cdm_visibility"] or "Règles prioritaires de masquage. Les conditions 'Afficher' overrides 'Masquer'.", cy)
    local _, cy = W.CreateCheckboxPair(card6.inner,
        L["opt_cdm_hide_mounted"] or "Masquer sur monture", visRules.hideWhenMounted or false, cy, function(v) visRules.hideWhenMounted = v; cdm.visibilityRules = visRules; ApplyCDM() end,
        L["opt_cdm_hide_vehicle"] or "Masquer en véhicule", visRules.hideInVehicles or false, function(v) visRules.hideInVehicles = v; cdm.visibilityRules = visRules; ApplyCDM() end)
    local _, cy = W.CreateCheckbox(card6.inner, L["opt_cdm_hide_ooc"] or "Masquer hors combat (pas de cible)", visRules.hideOutOfCombat or false, cy, function(v) visRules.hideOutOfCombat = v; cdm.visibilityRules = visRules; ApplyCDM() end)
    local _, cy = W.CreateCheckboxPair(card6.inner,
        L["opt_cdm_show_combat"] or "Toujours afficher en combat", visRules.showInCombat or false, cy, function(v) visRules.showInCombat = v; cdm.visibilityRules = visRules; ApplyCDM() end,
        L["opt_cdm_show_instance"] or "Toujours afficher en instance", visRules.showInInstance or false, function(v) visRules.showInInstance = v; cdm.visibilityRules = visRules; ApplyCDM() end)
    local _, cy = W.CreateCheckbox(card6.inner, L["opt_cdm_show_enemy"] or "Afficher avec cible ennemie", visRules.showWithEnemyTarget or false, cy, function(v) visRules.showWithEnemyTarget = v; cdm.visibilityRules = visRules; ApplyCDM() end)
    y = W.FinalizeCard(card6, cy)

    -- Sound Alerts, Pandemic, Range Check (V3.1)
    local card7, cy = W.CreateCard(c, L["section_cdm_extras"] or "Sound / Pandemic / Range", y)
    -- Sound Alerts
    local _, cy = W.CreateCheckbox(card7.inner, L["opt_cdm_sound_alert"] or "Son quand un sort est prêt", cdm.soundAlertEnabled or false, cy, function(v) cdm.soundAlertEnabled = v; ApplyCDM() end)
    local _, cy = W.CreateDropdown(card7.inner, L["opt_cdm_sound_file"] or "Fichier son", {
        { text = "Golden Lust",  value = "Interface\\AddOns\\TomoMod\\Assets\\Sounds\\Golden_Lust.ogg"  },
        { text = "Chipi",        value = "Interface\\AddOns\\TomoMod\\Assets\\Sounds\\Chipi.ogg"        },
        { text = "Spinning Cat", value = "Interface\\AddOns\\TomoMod\\Assets\\Sounds\\Spining_Cat.ogg"  },
        { text = "Taluani BL",   value = "Interface\\AddOns\\TomoMod\\Assets\\Sounds\\Taluani_BL.ogg"   },
    }, cdm.soundAlertFile or "Interface\\AddOns\\TomoMod\\Assets\\Sounds\\Golden_Lust.ogg", cy, function(v) cdm.soundAlertFile = v; ApplyCDM() end)
    -- Pandemic Detection
    local _, cy = W.CreateCheckbox(card7.inner, L["opt_cdm_pandemic"] or "Pandemic (bordure de refresh)", cdm.pandemicEnabled or false, cy, function(v) cdm.pandemicEnabled = v; ApplyCDM() end)
    local _, cy = W.CreateSlider(card7.inner, L["opt_cdm_pandemic_threshold"] or "Seuil pandemic (%)", (cdm.pandemicThreshold or 0.3) * 100, 10, 50, 5, cy, function(v) cdm.pandemicThreshold = v / 100; ApplyCDM() end, "%.0f%%")
    -- Range Check
    local _, cy = W.CreateCheckbox(card7.inner, L["opt_cdm_range_check"] or "Teinter rouge hors portée", cdm.rangeCheckEnabled or false, cy, function(v) cdm.rangeCheckEnabled = v; ApplyCDM() end)
    y = W.FinalizeCard(card7, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- TAB 2 : RESOURCE BARS
-- ══════════════════════════════════════════════
local function BuildResourceBarsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.resourceBars
    local y = -12

    -- Activation
    local card, cy = W.CreateCard(c, L["section_resource_bars"] or "Resource Bars", y)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_rb_enable"] or "Activer", db.enabled, cy, function(v)
        db.enabled = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.SetEnabled(v) end
    end)
    local _, cy = W.CreateDropdown(card.inner, L["opt_rb_display_mode"] or "Display mode", {
        { text = L["display_mode_icons"] or "Icons (TUI)", value = "icons" },
        { text = L["display_mode_bars"]  or "Bars (flat)",  value = "bars"  },
    }, db.displayMode or "icons", cy, function(v) db.displayMode = v; ApplyRB() end)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_rb_primary_centered"] or "Afficher la ressource principale au centre", db.primaryPowerCentered or false, cy, function(v)
        db.primaryPowerCentered = v
        ApplyRB()
        -- Rebuild player unit frame to add/remove power bar
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RebuildUnit then
            TomoMod_UnitFrames.RebuildUnit("player")
        end
    end)
    local _, cy = W.CreateInfoText(card.inner, L["info_rb_primary_centered"] or "Deplace la barre de mana/energie/rage du player frame vers le centre de l'ecran.", cy)
    y = W.FinalizeCard(card, cy)

    -- Visibilité
    local card2, cy = W.CreateCard(c, L["section_visibility"] or "Visibilité", y)
    local _, cy = W.CreateDropdown(card2.inner, L["opt_rb_visibility_mode"] or "Mode de visibilité", {
        { text = L["vis_always"] or "Toujours", value = "always" },
        { text = L["vis_combat"] or "En combat", value = "combat" },
        { text = L["vis_target"] or "Avec cible", value = "target" },
        { text = L["vis_hidden"] or "Caché", value = "hidden" },
    }, db.visibilityMode or "always", cy, function(v) db.visibilityMode = v; ApplyRB() end)
    local _, cy = W.CreateTwoColumnRow(card2.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_alpha_combat"] or "Alpha combat",  db.combatAlpha or 1.0, 0, 1, 0.05, 0, function(v) db.combatAlpha = v; ApplyRB() end, "%.2f") return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_alpha_ooc"]    or "Alpha hors combat", db.oocAlpha or 0.5, 0, 1, 0.05, 0, function(v) db.oocAlpha = v; ApplyRB() end, "%.2f") return ny end)
    y = W.FinalizeCard(card2, cy)

    -- Dimensions
    local card3, cy = W.CreateCard(c, L["section_dimensions"] or "Dimensions", y)
    local _, cy = W.CreateTwoColumnRow(card3.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_rb_width"]            or "Largeur",    db.width or 260,         80, 600, 5,    0, function(v) db.width  = v; ApplyRB() end) return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_rb_global_scale"]     or "Échelle",    db.scale or 1.0,       0.5, 2.0, 0.05,  0, function(v) db.scale  = v; ApplyRB() end, "%.2f") return ny end)
    local _, cy = W.CreateTwoColumnRow(card3.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_rb_classpower_height"]  or "Haut. pouvoir de classe",  db.primaryHeight   or 16, 6, 40, 1, 0, function(v) db.primaryHeight   = v; ApplyRB() end) return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_rb_druidmana_height"] or "Haut. mana druide", db.secondaryHeight or 12, 6, 30, 1, 0, function(v) db.secondaryHeight = v; ApplyRB() end) return ny end)
    local _, cy = W.CreateSlider(card3.inner, L["opt_rb_primary_power_height"] or "Haut. barre principale", db.primaryPowerBarHeight or 14, 6, 30, 1, cy, function(v) db.primaryPowerBarHeight = v; ApplyRB() end)
    y = W.FinalizeCard(card3, cy)

    -- Sync & position
    local card4, cy = W.CreateCard(c, L["section_position"] or "Sync & Position", y)
    local _, cy = W.CreateCheckbox(card4.inner, L["opt_rb_sync_width"] or "Synchroniser la largeur avec les cooldowns", db.syncWidthWithCooldowns or false, cy, function(v)
        db.syncWidthWithCooldowns = v
        if v and TomoMod_ResourceBars then TomoMod_ResourceBars.SyncWidth() end
    end)
    local _, cy = W.CreateTwoColumnRow(card4.inner, cy,
        function(col)
            local _, ny = W.CreateButton(col, L["btn_sync_now"] or "Sync maintenant", 180, 0, function()
                if TomoMod_ResourceBars then TomoMod_ResourceBars.SyncWidth() end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateButton(col, L["btn_reset_position"] or "Réinitialiser pos.", 180, 0, function()
                db.position = nil; ApplyRB()
                print("|cff0cd29fTomoMod|r " .. (L["msg_rb_position_reset"] or "Position réinitialisée."))
            end)
            return ny
        end)
    local _, cy = W.CreateInfoText(card4.inner, L["info_rb_druid"] or "", cy)
    y = W.FinalizeCard(card4, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- TAB 3 : TEXTE & POLICE
-- ══════════════════════════════════════════════
local function BuildTextPositionTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.resourceBars
    local y = -12

    local card, cy = W.CreateCard(c, L["section_text_font"] or "Texte & Police", y)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_rb_show_text"] or "Afficher le texte", db.showText, cy, function(v) db.showText = v; ApplyRB() end)
    local _, cy = W.CreateDropdown(card.inner, L["opt_rb_text_align"] or "Alignement", {
        { text = L["align_left"] or "Gauche", value = "LEFT" },
        { text = L["align_center"] or "Centre", value = "CENTER" },
        { text = L["align_right"] or "Droite", value = "RIGHT" },
    }, db.textAlignment or "CENTER", cy, function(v) db.textAlignment = v; ApplyRB() end)
    local _, cy = W.CreateSlider(card.inner, L["opt_rb_font_size"] or "Taille de police", db.fontSize or 11, 7, 20, 1, cy, function(v) db.fontSize = v; ApplyRB() end)
    local _, cy = W.CreateDropdown(card.inner, L["opt_rb_font"] or "Police", FONT_LIST, db.font or FONT_LIST[1].value, cy, function(v) db.font = v; ApplyRB() end)
    y = W.FinalizeCard(card, cy)

    local card2, cy = W.CreateCard(c, L["section_position"] or "Position", y)
    local _, cy = W.CreateButton(card2.inner, L["btn_toggle_lock"] or "Verrouiller/Déverrouiller", 240, cy, function()
        if TomoMod_ResourceBars and TomoMod_ResourceBars.ToggleLock then TomoMod_ResourceBars.ToggleLock() end
    end)
    local _, cy = W.CreateInfoText(card2.inner, L["info_rb_position"] or "", cy)
    y = W.FinalizeCard(card2, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- TAB 4 : COULEURS DES RESSOURCES
-- ══════════════════════════════════════════════
local function BuildColorsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.resourceBars.colors
    local y = -12

    local card, cy = W.CreateCard(c, L["section_resource_colors"] or "Couleurs des ressources", y)
    local _, cy = W.CreateInfoText(card.inner, L["info_rb_colors_custom"] or "Personnalisez la couleur de chaque type de ressource.", cy)

    local entries = {
        { key = "comboPoints", label = L["res_combo_points"] or "Combo Points" }, { key = "holyPower", label = L["res_holy_power"] or "Holy Power" },
        { key = "soulShards", label = L["res_soul_shards"] or "Soul Shards" }, { key = "chi", label = L["res_chi"] or "Chi" },
        { key = "essence", label = L["res_essence"] or "Essence" }, { key = "arcaneCharges", label = L["res_arcane_charges"] or "Arcane Charges" },
        { key = "runes", label = L["res_runes_cd"] or "Runes (CD)" }, { key = "runesReady", label = L["res_runes_ready"] or "Runes Ready" },
        { key = "stagger", label = L["res_stagger"] or "Stagger" }, { key = "mana", label = L["res_mana"] or "Mana (Druid)" },
        { key = "soulFragments", label = L["res_soul_fragments"] or "Soul Fragments" }, { key = "tipOfTheSpear", label = L["res_tip_of_spear"] or "Tip of the Spear" },
        { key = "maelstromWeapon", label = L["res_maelstrom_weapon"] or "Maelstrom Weapon" },
    }

    local i = 1
    while i <= #entries do
        local eA = entries[i]; local eB = entries[i+1]
        if eB and db[eA.key] and db[eB.key] then
            local kA, kB = eA.key, eB.key
            _, cy = W.CreateColorPickerPair(card.inner, eA.label, db[kA], eB.label, db[kB], cy,
                function(r,g,b) db[kA].r,db[kA].g,db[kA].b=r,g,b; ApplyRB() end,
                function(r,g,b) db[kB].r,db[kB].g,db[kB].b=r,g,b; ApplyRB() end)
            i = i + 2
        elseif db[eA.key] then
            _, cy = W.CreateColorPicker(card.inner, eA.label, db[eA.key], cy, function(r,g,b)
                db[eA.key].r,db[eA.key].g,db[eA.key].b=r,g,b; ApplyRB()
            end)
            i = i + 1
        else i = i + 1 end
    end

    y = W.FinalizeCard(card, cy)
    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- ENTRY POINT
-- ══════════════════════════════════════════════
function TomoMod_ConfigPanel_CooldownResource(parent)
    return W.CreateTabPanel(parent, {
        { key = "cdm",      label = L["tab_cdm"]           or "CDM",           builder = BuildCooldownManagerTab },
        { key = "resource", label = L["tab_resource_bars"] or "Resource Bars", builder = BuildResourceBarsTab    },
        { key = "textpos",  label = L["tab_text_position"] or "Texte",         builder = BuildTextPositionTab    },
        { key = "colors",   label = L["tab_rb_colors"]     or "Couleurs",      builder = BuildColorsTab          },
    })
end

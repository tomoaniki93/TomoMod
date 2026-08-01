-- Panels/CooldownResource.lua v2.9.0 — Cards layout + onglet Barres (Phase 4 holders) + Barre de vie / Animations RB
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
-- HELPERS — Phase 4 (holders / viewerLayout)
-- ══════════════════════════════════════════════
local function Holders()
    return TomoMod_CDMHolders
end

--- Accès direct au bloc viewerLayout[key] (indépendant du module holders).
local function GetVL(key)
    local cdm = TomoModDB and TomoModDB.cooldownManager
    if not cdm then return {} end
    cdm.viewerLayout = cdm.viewerLayout or {}
    cdm.viewerLayout[key] = cdm.viewerLayout[key] or {}
    return cdm.viewerLayout[key]
end

local function GetPos(key)
    local Hd = Holders()
    if Hd and Hd.GetPosition then
        return Hd.GetPosition(key)
    end
    local vl = GetVL(key)
    if vl.position then return vl.position.x or 0, vl.position.y or 0 end
    return 0, 0
end

local function SetPos(key, x, y)
    local vl = GetVL(key)
    vl.position = vl.position or {}
    if x then vl.position.x = x end
    if y then vl.position.y = y end
    vl.position.x = vl.position.x or 0
    vl.position.y = vl.position.y or 0
    local Hd = Holders()
    if Hd and Hd.ApplyPosition then Hd.ApplyPosition(key) end
end

local DIRECTION_ITEMS = {
    { text = L["dir_centered"],  value = "CENTERED" },
    { text = L["dir_left"],                value = "LEFT"     },
    { text = L["dir_right"],                value = "RIGHT"    },
    { text = L["dir_up"],                  value = "UP"       },
    { text = L["dir_down"],                   value = "DOWN"     },
}

local SECONDARY_ITEMS = {
    { text = L["secdir_auto"],                  value = "AUTO"  },
    { text = L["secdir_down"],    value = "DOWN"  },
    { text = L["secdir_up"],   value = "UP"    },
    { text = L["secdir_right"],  value = "RIGHT" },
    { text = L["secdir_left"],  value = "LEFT"  },
}

--- Carte de réglages d'un viewer à icônes (Essential / Utility / BuffIcon).
local function BuildViewerCard(c, key, title, y)
    local vl = GetVL(key)
    local card, cy = W.CreateCard(c, title, y)

    -- Position live
    local px, py = GetPos(key)
    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_pos_x"], px, -960, 960, 1, 0, function(v) SetPos(key, v, nil) end, "%.0f") return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_pos_y"], py, -540, 540, 1, 0, function(v) SetPos(key, nil, v) end, "%.0f") return ny end)

    -- Taille (0 = auto = taille Blizzard/Edit Mode)
    local _, cy = W.CreateSlider(card.inner, L["opt_cdm_icon_size"], vl.iconSize or 0, 0, 64, 2, cy, function(v)
        vl.iconSize = (v > 0) and v or nil
        ApplyCDM()
    end, "%.0f")

    -- Espacement + limite par ligne
    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_spacing"], vl.spacing or 1, 0, 20, 1, 0, function(v) vl.spacing = v; ApplyCDM() end, "%.0f") return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_row_limit"], vl.rowLimit or 0, 0, 12, 1, 0, function(v) vl.rowLimit = (v > 0) and v or nil; ApplyCDM() end, "%.0f") return ny end)

    -- Directions
    local _, cy = W.CreateDropdown(card.inner, L["opt_cdm_direction"], DIRECTION_ITEMS, vl.direction or "CENTERED", cy, function(v)
        vl.direction = v
        ApplyCDM()
    end)
    local _, cy = W.CreateDropdown(card.inner, L["opt_cdm_secondary_direction"], SECONDARY_ITEMS, vl.secondaryDirection or "AUTO", cy, function(v)
        vl.secondaryDirection = (v ~= "AUTO") and v or nil
        ApplyCDM()
    end)

    return W.FinalizeCard(card, cy)
end

-- ══════════════════════════════════════════════
-- TAB 1 : COOLDOWN MANAGER
-- ══════════════════════════════════════════════
local function BuildCooldownManagerTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local cdm = TomoModDB.cooldownManager
    local y = -12

    -- Activation
    local card, cy = W.CreateCard(c, L["section_cdm"], y)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_cdm_enable"], cdm.enabled, cy, function(v)
        cdm.enabled = v
        if TomoMod_CooldownManager then TomoMod_CooldownManager.SetEnabled(v) end
    end)
    local _, cy = W.CreateInfoText(card.inner, L["info_cdm_description"], cy)
    local _, cy = W.CreateCheckboxPair(card.inner,
        L["opt_cdm_show_hotkeys"], cdm.showHotKey, cy, function(v) cdm.showHotKey  = v; ApplyCDM() end,
        L["opt_cdm_combat_alpha"], cdm.combatAlpha,           function(v) cdm.combatAlpha = v; ApplyCDM() end)
    y = W.FinalizeCard(card, cy)

    -- Placement (Phase 4 — remplace le bouton Edit Mode)
    local cardPrev, cy = W.CreateCard(c, L["section_cdm_placement"], y)
    local _, cy = W.CreateInfoText(cardPrev.inner, L["info_cdm_placement"], cy)
    local _, cy = W.CreateButton(cardPrev.inner, L["btn_cdm_unlock"], 220, cy, function()
        local Hd = Holders()
        if Hd then Hd.ToggleLock() end
    end)
    local Hd = Holders()
    local _, cy = W.CreateCheckbox(cardPrev.inner, L["opt_cdm_preview"], (Hd and Hd.IsPreviewActive and Hd.IsPreviewActive()) or false, cy, function(v)
        local Hd2 = Holders()
        if Hd2 then Hd2.SetPreview(v) end
    end)
    local _, cy = W.CreateInfoText(cardPrev.inner, L["info_cdm_preview_live"], cy)
    y = W.FinalizeCard(cardPrev, cy)

    -- Opacité
    local card2, cy = W.CreateCard(c, L["section_cdm_alpha"], y)
    local _, cy = W.CreateTwoColumnRow(card2.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_alpha_combat"],          cdm.alphaInCombat    or 1.0, 0, 1, 0.05, 0, function(v) cdm.alphaInCombat    = v; ApplyCDM() end, "%.2f") return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_alpha_target"],         cdm.alphaWithTarget  or 0.8, 0, 1, 0.05, 0, function(v) cdm.alphaWithTarget  = v; ApplyCDM() end, "%.2f") return ny end)
    local _, cy = W.CreateSlider(card2.inner, L["opt_cdm_alpha_ooc"], cdm.alphaOutOfCombat or 0.5, 0, 1, 0.05, cy, function(v) cdm.alphaOutOfCombat = v; ApplyCDM() end, "%.2f")
    y = W.FinalizeCard(card2, cy)

    -- Overlay/Swipe
    local overlayCol = { r = cdm.overlayR or 1, g = cdm.overlayG or 1,    b = cdm.overlayB or 1    }
    local swipeCol   = { r = cdm.swipeR  or 1, g = cdm.swipeG  or 0.95, b = cdm.swipeB  or 0.57 }
    local card3, cy = W.CreateCard(c, L["section_cdm_overlay"], y)
    local _, cy = W.CreateCheckboxPair(card3.inner,
        L["opt_cdm_custom_overlay"], cdm.useCustomOverlay,  cy, function(v) cdm.useCustomOverlay   = v; ApplyCDM() end,
        L["opt_cdm_custom_swipe"],   cdm.customSwipeEnabled,    function(v) cdm.customSwipeEnabled = v; ApplyCDM() end)
    local _, cy = W.CreateColorPickerPair(card3.inner, L["opt_cdm_overlay_color"], overlayCol, L["opt_cdm_swipe_color"], swipeCol, cy,
        function(r,g,b) cdm.overlayR=r; cdm.overlayG=g; cdm.overlayB=b; ApplyCDM() end,
        function(r,g,b) cdm.swipeR=r;   cdm.swipeG=g;   cdm.swipeB=b;   ApplyCDM() end)
    local _, cy = W.CreateSlider(card3.inner, L["opt_cdm_swipe_alpha"], cdm.swipeA or 0.55, 0, 1, 0.05, cy, function(v) cdm.swipeA = v; ApplyCDM() end, "%.2f")
    -- V3: Separate CD swipe color
    local cdSwipeCol = { r = cdm.cdSwipeR or 0, g = cdm.cdSwipeG or 0, b = cdm.cdSwipeB or 0 }
    local _, cy = W.CreateCheckbox(card3.inner, L["opt_cdm_custom_cd_swipe"], cdm.customCDSwipeEnabled or false, cy, function(v) cdm.customCDSwipeEnabled = v; ApplyCDM() end)
    local _, cy = W.CreateColorPicker(card3.inner, L["opt_cdm_cd_swipe_color"], cdSwipeCol, cy, function(r,g,b) cdm.cdSwipeR=r; cdm.cdSwipeG=g; cdm.cdSwipeB=b; ApplyCDM() end)
    local _, cy = W.CreateSlider(card3.inner, L["opt_cdm_cd_swipe_alpha"], cdm.cdSwipeA or 0.7, 0, 1, 0.05, cy, function(v) cdm.cdSwipeA = v; ApplyCDM() end, "%.2f")
    y = W.FinalizeCard(card3, cy)

    -- Utilitaires
    local card4, cy = W.CreateCard(c, L["section_cdm_utility"], y)
    local _, cy = W.CreateCheckbox(card4.inner, L["opt_cdm_dim_utility"], cdm.dimUtility, cy, function(v) cdm.dimUtility = v; ApplyCDM() end)
    local _, cy = W.CreateSlider(card4.inner, L["opt_cdm_dim_opacity"], cdm.dimOpacity or 0.35, 0.1, 1, 0.05, cy, function(v) cdm.dimOpacity = v; ApplyCDM() end, "%.2f")
    y = W.FinalizeCard(card4, cy)

    -- Avancé (V3)
    local card5, cy = W.CreateCard(c, L["section_cdm_advanced"], y)
    local _, cy = W.CreateCheckboxPair(card5.inner,
        L["opt_cdm_hide_gcd"], cdm.hideGCD or false, cy, function(v) cdm.hideGCD = v; ApplyCDM() end,
        L["opt_cdm_desaturate"], cdm.desaturateOnCD or false, function(v) cdm.desaturateOnCD = v; ApplyCDM() end)
    local _, cy = W.CreateDropdown(card5.inner, L["opt_cdm_buff_alignment"], {
        { text = L["align_center_outward"], value = "CENTER" },
        { text = L["align_start"], value = "START" },
        { text = L["align_end"], value = "END" },
    }, cdm.buffAlignment or "CENTER", cy, function(v) cdm.buffAlignment = v; ApplyCDM() end)
    y = W.FinalizeCard(card5, cy)

    -- Règles de visibilité (V3)
    local visRules = cdm.visibilityRules or {}
    local card6, cy = W.CreateCard(c, L["section_cdm_visibility"], y)
    local _, cy = W.CreateInfoText(card6.inner, L["info_cdm_visibility"], cy)
    local _, cy = W.CreateCheckboxPair(card6.inner,
        L["opt_cdm_hide_mounted"], visRules.hideWhenMounted or false, cy, function(v) visRules.hideWhenMounted = v; cdm.visibilityRules = visRules; ApplyCDM() end,
        L["opt_cdm_hide_vehicle"], visRules.hideInVehicles or false, function(v) visRules.hideInVehicles = v; cdm.visibilityRules = visRules; ApplyCDM() end)
    local _, cy = W.CreateCheckbox(card6.inner, L["opt_cdm_hide_ooc"], visRules.hideOutOfCombat or false, cy, function(v) visRules.hideOutOfCombat = v; cdm.visibilityRules = visRules; ApplyCDM() end)
    local _, cy = W.CreateCheckboxPair(card6.inner,
        L["opt_cdm_show_combat"], visRules.showInCombat or false, cy, function(v) visRules.showInCombat = v; cdm.visibilityRules = visRules; ApplyCDM() end,
        L["opt_cdm_show_instance"], visRules.showInInstance or false, function(v) visRules.showInInstance = v; cdm.visibilityRules = visRules; ApplyCDM() end)
    local _, cy = W.CreateCheckbox(card6.inner, L["opt_cdm_show_enemy"], visRules.showWithEnemyTarget or false, cy, function(v) visRules.showWithEnemyTarget = v; cdm.visibilityRules = visRules; ApplyCDM() end)
    y = W.FinalizeCard(card6, cy)

    -- Sound Alerts, Pandemic, Range Check (V3.1)
    local card7, cy = W.CreateCard(c, L["section_cdm_extras"], y)
    -- Sound Alerts
    local _, cy = W.CreateCheckbox(card7.inner, L["opt_cdm_sound_alert"], cdm.soundAlertEnabled or false, cy, function(v) cdm.soundAlertEnabled = v; ApplyCDM() end)
    local _, cy = W.CreateDropdown(card7.inner, L["opt_cdm_sound_file"], {
        { text = "Golden Lust",  value = "Interface\\AddOns\\TomoMod\\Assets\\Sounds\\Golden_Lust.ogg"  },
        { text = "Chipi",        value = "Interface\\AddOns\\TomoMod\\Assets\\Sounds\\Chipi.ogg"        },
        { text = "Spinning Cat", value = "Interface\\AddOns\\TomoMod\\Assets\\Sounds\\Spining_Cat.ogg"  },
        { text = "Taluani BL",   value = "Interface\\AddOns\\TomoMod\\Assets\\Sounds\\Taluani_BL.ogg"   },
    }, cdm.soundAlertFile or "Interface\\AddOns\\TomoMod\\Assets\\Sounds\\Golden_Lust.ogg", cy, function(v) cdm.soundAlertFile = v; ApplyCDM() end)
    -- Pandemic Detection
    local _, cy = W.CreateCheckbox(card7.inner, L["opt_cdm_pandemic"], cdm.pandemicEnabled or false, cy, function(v) cdm.pandemicEnabled = v; ApplyCDM() end)
    local _, cy = W.CreateSlider(card7.inner, L["opt_cdm_pandemic_threshold"], (cdm.pandemicThreshold or 0.3) * 100, 10, 50, 5, cy, function(v) cdm.pandemicThreshold = v / 100; ApplyCDM() end, "%.0f%%")
    -- Range Check
    local _, cy = W.CreateCheckbox(card7.inner, L["opt_cdm_range_check"], cdm.rangeCheckEnabled or false, cy, function(v) cdm.rangeCheckEnabled = v; ApplyCDM() end)
    y = W.FinalizeCard(card7, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- TAB 2 : BARRES (Phase 4 — réglages par viewer, tout en live)
-- ══════════════════════════════════════════════
local function BuildViewerBarsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local cdm = TomoModDB.cooldownManager
    local y = -12

    -- Placement & aperçu
    local card, cy = W.CreateCard(c, L["section_cdm_placement"], y)
    local _, cy = W.CreateInfoText(card.inner, L["info_cdm_bars"], cy)
    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col)
            local _, ny = W.CreateButton(col, L["btn_cdm_unlock"], 200, 0, function()
                local Hd = Holders()
                if Hd then Hd.ToggleLock() end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateButton(col, L["btn_cdm_reset_pos"], 200, 0, function()
                local Hd = Holders()
                if Hd then
                    Hd.ResetPosition("essential")
                    Hd.ResetPosition("utility")
                    Hd.ResetPosition("buffIcon")
                    Hd.ResetPosition("buffBar")
                    ApplyCDM()
                    print("|cff2ed884TomoMod|r " .. (L["msg_cdm_pos_reset"]))
                end
            end)
            return ny
        end)
    local Hd = Holders()
    local _, cy = W.CreateCheckbox(card.inner, L["opt_cdm_preview"], (Hd and Hd.IsPreviewActive and Hd.IsPreviewActive()) or false, cy, function(v)
        local Hd2 = Holders()
        if Hd2 then Hd2.SetPreview(v) end
    end)
    y = W.FinalizeCard(card, cy)

    -- Cartes par viewer
    y = BuildViewerCard(c, "essential", L["section_cdm_essential"], y)
    y = BuildViewerCard(c, "utility",   L["section_cdm_utility_bar"], y)
    y = BuildViewerCard(c, "buffIcon",  L["section_cdm_bufficons"], y)

    -- Buff Bars (réglages spécifiques barres)
    local vlB = GetVL("buffBar")
    local cardB, cy = W.CreateCard(c, L["section_cdm_buffbars"], y)
    local bx, by = GetPos("buffBar")
    local _, cy = W.CreateTwoColumnRow(cardB.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_pos_x"], bx, -960, 960, 1, 0, function(v) SetPos("buffBar", v, nil) end, "%.0f") return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_pos_y"], by, -540, 540, 1, 0, function(v) SetPos("buffBar", nil, v) end, "%.0f") return ny end)
    local _, cy = W.CreateDropdown(cardB.inner, L["opt_cdm_buffbar_direction"], {
        { text = L["buffbar_vertical"],   value = "VERTICAL"   },
        { text = L["buffbar_horizontal"], value = "HORIZONTAL" },
    }, vlB.direction or cdm.buffBarDirection or "VERTICAL", cy, function(v)
        vlB.direction = v
        cdm.buffBarDirection = v   -- sync top-level (compat v3.1)
        ApplyCDM()
    end)
    local _, cy = W.CreateTwoColumnRow(cardB.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_buffbar_width"], vlB.barWidth or cdm.buffBarWidth or 120, 60, 400, 5, 0, function(v)
            vlB.barWidth = v
            cdm.buffBarWidth = v   -- sync top-level (compat v3.1)
            ApplyCDM()
        end, "%.0f") return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_buffbar_spacing"], vlB.spacing or cdm.buffBarSpacing or 2, 0, 12, 1, 0, function(v)
            vlB.spacing = v
            cdm.buffBarSpacing = v -- sync top-level (compat v3.1)
            ApplyCDM()
        end, "%.0f") return ny end)
    y = W.FinalizeCard(cardB, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- TAB 3 : RESOURCE BARS
-- ══════════════════════════════════════════════
local function BuildResourceBarsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.resourceBars
    local y = -12

    -- Activation
    local card, cy = W.CreateCard(c, L["section_resource_bars"], y)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_rb_enable"], db.enabled, cy, function(v)
        db.enabled = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.SetEnabled(v) end
    end)
    local _, cy = W.CreateDropdown(card.inner, L["opt_rb_display_mode"], {
        { text = L["display_mode_icons"], value = "icons" },
        { text = L["display_mode_bars"],  value = "bars"  },
    }, db.displayMode or "icons", cy, function(v) db.displayMode = v; ApplyRB() end)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_rb_primary_centered"], db.primaryPowerCentered or false, cy, function(v)
        db.primaryPowerCentered = v
        ApplyRB()
        -- Rebuild player unit frame to add/remove power bar
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RebuildUnit then
            TomoMod_UnitFrames.RebuildUnit("player")
        end
    end)
    local _, cy = W.CreateInfoText(card.inner, L["info_rb_primary_centered"], cy)
    y = W.FinalizeCard(card, cy)

    -- Visibilité
    local card2, cy = W.CreateCard(c, L["section_visibility"], y)
    local _, cy = W.CreateDropdown(card2.inner, L["opt_rb_visibility_mode"], {
        { text = L["vis_always"], value = "always" },
        { text = L["vis_combat"], value = "combat" },
        { text = L["vis_target"], value = "target" },
        { text = L["vis_hidden"], value = "hidden" },
    }, db.visibilityMode or "always", cy, function(v) db.visibilityMode = v; ApplyRB() end)
    local _, cy = W.CreateTwoColumnRow(card2.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_alpha_combat"],  db.combatAlpha or 1.0, 0, 1, 0.05, 0, function(v) db.combatAlpha = v; ApplyRB() end, "%.2f") return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_cdm_alpha_ooc"], db.oocAlpha or 0.5, 0, 1, 0.05, 0, function(v) db.oocAlpha = v; ApplyRB() end, "%.2f") return ny end)
    y = W.FinalizeCard(card2, cy)

    -- Dimensions
    local card3, cy = W.CreateCard(c, L["section_dimensions"], y)
    local _, cy = W.CreateTwoColumnRow(card3.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_rb_width"],    db.width or 260,         80, 600, 5,    0, function(v) db.width  = v; ApplyRB() end) return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_rb_global_scale"],    db.scale or 1.0,       0.5, 2.0, 0.05,  0, function(v) db.scale  = v; ApplyRB() end, "%.2f") return ny end)
    local _, cy = W.CreateTwoColumnRow(card3.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_rb_classpower_height"],  db.primaryHeight   or 16, 6, 40, 1, 0, function(v) db.primaryHeight   = v; ApplyRB() end) return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_rb_druidmana_height"], db.secondaryHeight or 12, 6, 30, 1, 0, function(v) db.secondaryHeight = v; ApplyRB() end) return ny end)
    local _, cy = W.CreateSlider(card3.inner, L["opt_rb_primary_power_height"], db.primaryPowerBarHeight or 14, 6, 30, 1, cy, function(v) db.primaryPowerBarHeight = v; ApplyRB() end)
    y = W.FinalizeCard(card3, cy)

    -- v2.9 : Barre de vie (HUD)
    db.colors = db.colors or {}
    db.colors.health    = db.colors.health    or { r = 0.15, g = 0.75, b = 0.30 }
    db.colors.healthLow = db.colors.healthLow or { r = 1.00, g = 0.20, b = 0.20 }
    db.colors.powerLow  = db.colors.powerLow  or { r = 1.00, g = 0.25, b = 0.25 }

    local cardHB, cy = W.CreateCard(c, L["section_rb_healthbar"], y)
    local _, cy = W.CreateCheckbox(cardHB.inner, L["opt_rb_hb_enable"], db.healthBarEnabled or false, cy, function(v)
        db.healthBarEnabled = v; ApplyRB()
    end)
    local _, cy = W.CreateInfoText(cardHB.inner, L["info_rb_healthbar"], cy)
    local _, cy = W.CreateTwoColumnRow(cardHB.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_rb_hb_height"], db.healthBarHeight or 14, 8, 30, 1, 0, function(v) db.healthBarHeight = v; ApplyRB() end, "%.0f") return ny end,
        function(col) local _, ny = W.CreateDropdown(col, L["opt_rb_hb_text"], {
            { text = L["hb_text_none"],       value = "none"    },
            { text = L["hb_text_value"],      value = "value"   },
            { text = L["hb_text_percent"], value = "percent" },
            { text = L["hb_text_both"],  value = "both"    },
        }, db.healthTextFormat or "both", 0, function(v) db.healthTextFormat = v; ApplyRB() end) return ny end)
    local _, cy = W.CreateCheckbox(cardHB.inner, L["opt_rb_hb_classcolor"], db.healthClassColored ~= false, cy, function(v)
        db.healthClassColored = v; ApplyRB()
    end)
    local _, cy = W.CreateColorPicker(cardHB.inner, L["opt_rb_hb_color"], db.colors.health, cy, function(r,g,b)
        db.colors.health.r, db.colors.health.g, db.colors.health.b = r, g, b; ApplyRB()
    end)
    local _, cy = W.CreateCheckbox(cardHB.inner, L["opt_rb_hb_threshold"], db.healthThresholdEnabled ~= false, cy, function(v)
        db.healthThresholdEnabled = v; ApplyRB()
    end)
    local _, cy = W.CreateTwoColumnRow(cardHB.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_rb_hb_threshold_pct"], db.healthThresholdPct or 30, 10, 60, 5, 0, function(v) db.healthThresholdPct = v; ApplyRB() end, "%.0f%%") return ny end,
        function(col) local _, ny = W.CreateColorPicker(col, L["opt_rb_hb_threshold_color"], db.colors.healthLow, 0, function(r,g,b)
            db.colors.healthLow.r, db.colors.healthLow.g, db.colors.healthLow.b = r, g, b; ApplyRB()
        end) return ny end)
    y = W.FinalizeCard(cardHB, cy)

    -- v2.9 : Animations & barre de puissance (smooth / ticks / seuil)
    local cardAN, cy = W.CreateCard(c, L["section_rb_anim"], y)
    local _, cy = W.CreateCheckbox(cardAN.inner, L["opt_rb_smooth"], db.smoothBars ~= false, cy, function(v)
        db.smoothBars = v; ApplyRB()
    end)
    local _, cy = W.CreateDropdown(cardAN.inner, L["opt_rb_power_ticks"], {
        { text = L["ticks_none"],             value = ""            },
        { text = "50%",                                    value = "50"          },
        { text = "25 / 50 / 75%",                          value = "25 50 75"    },
        { text = "20 / 40 / 60 / 80%",                     value = "20 40 60 80" },
    }, db.powerTicks or "", cy, function(v) db.powerTicks = v; ApplyRB() end)
    local _, cy = W.CreateCheckbox(cardAN.inner, L["opt_rb_power_threshold"], db.powerThresholdEnabled or false, cy, function(v)
        db.powerThresholdEnabled = v; ApplyRB()
    end)
    local _, cy = W.CreateTwoColumnRow(cardAN.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_rb_power_threshold_pct"], db.powerThresholdPct or 25, 5, 60, 5, 0, function(v) db.powerThresholdPct = v; ApplyRB() end, "%.0f%%") return ny end,
        function(col) local _, ny = W.CreateColorPicker(col, L["opt_rb_power_threshold_color"], db.colors.powerLow, 0, function(r,g,b)
            db.colors.powerLow.r, db.colors.powerLow.g, db.colors.powerLow.b = r, g, b; ApplyRB()
        end) return ny end)
    local _, cy = W.CreateInfoText(cardAN.inner, L["info_rb_anim"], cy)
    y = W.FinalizeCard(cardAN, cy)

    -- Sync & position
    local card4, cy = W.CreateCard(c, L["section_position"], y)
    local _, cy = W.CreateCheckbox(card4.inner, L["opt_rb_sync_width"], db.syncWidthWithCooldowns or false, cy, function(v)
        db.syncWidthWithCooldowns = v
        if v and TomoMod_ResourceBars then TomoMod_ResourceBars.SyncWidth() end
    end)
    local _, cy = W.CreateTwoColumnRow(card4.inner, cy,
        function(col)
            local _, ny = W.CreateButton(col, L["btn_sync_now"], 180, 0, function()
                if TomoMod_ResourceBars then TomoMod_ResourceBars.SyncWidth() end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateButton(col, L["btn_reset_position"], 180, 0, function()
                db.position = nil; ApplyRB()
                print("|cff2ed884TomoMod|r " .. (L["msg_rb_position_reset"]))
            end)
            return ny
        end)
    local _, cy = W.CreateInfoText(card4.inner, L["info_rb_druid"], cy)
    y = W.FinalizeCard(card4, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- TAB 4 : TEXTE & POLICE
-- ══════════════════════════════════════════════
local function BuildTextPositionTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.resourceBars
    local y = -12

    local card, cy = W.CreateCard(c, L["section_text_font"], y)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_rb_show_text"], db.showText, cy, function(v) db.showText = v; ApplyRB() end)
    local _, cy = W.CreateDropdown(card.inner, L["opt_rb_text_align"], {
        { text = L["align_left"], value = "LEFT" },
        { text = L["align_center"], value = "CENTER" },
        { text = L["align_right"], value = "RIGHT" },
    }, db.textAlignment or "CENTER", cy, function(v) db.textAlignment = v; ApplyRB() end)
    local _, cy = W.CreateSlider(card.inner, L["opt_rb_font_size"], db.fontSize or 11, 7, 20, 1, cy, function(v) db.fontSize = v; ApplyRB() end)
    local _, cy = W.CreateDropdown(card.inner, L["opt_rb_font"], FONT_LIST, db.font or FONT_LIST[1].value, cy, function(v) db.font = v; ApplyRB() end)
    y = W.FinalizeCard(card, cy)

    local card2, cy = W.CreateCard(c, L["section_position"], y)
    local _, cy = W.CreateButton(card2.inner, L["btn_toggle_lock"], 240, cy, function()
        if TomoMod_ResourceBars and TomoMod_ResourceBars.ToggleLock then TomoMod_ResourceBars.ToggleLock() end
    end)
    local _, cy = W.CreateInfoText(card2.inner, L["info_rb_position"], cy)
    y = W.FinalizeCard(card2, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- TAB 5 : COULEURS DES RESSOURCES
-- ══════════════════════════════════════════════
local function BuildColorsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.resourceBars.colors
    local y = -12

    local card, cy = W.CreateCard(c, L["section_resource_colors"], y)
    local _, cy = W.CreateInfoText(card.inner, L["info_rb_colors_custom"], cy)

    local entries = {
        { key = "comboPoints", label = L["res_combo_points"] },
        { key = "chargedComboPoints", label = L["res_charged_combo_points"] },
        { key = "holyPower", label = L["res_holy_power"] },
        { key = "soulShards", label = L["res_soul_shards"] }, { key = "chi", label = L["res_chi"] },
        { key = "essence", label = L["res_essence"] }, { key = "arcaneCharges", label = L["res_arcane_charges"] },
        { key = "runes", label = L["res_runes_cd"] }, { key = "runesReady", label = L["res_runes_ready"] },
        { key = "stagger", label = L["res_stagger"] }, { key = "mana", label = L["res_mana"] },
        { key = "soulFragments", label = L["res_soul_fragments"] }, { key = "tipOfTheSpear", label = L["res_tip_of_spear"] },
        { key = "maelstromWeapon", label = L["res_maelstrom_weapon"] },
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
        { key = "cdm",      label = L["tab_cdm"],           builder = BuildCooldownManagerTab },
        { key = "bars",     label = L["tab_cdm_bars"],        builder = BuildViewerBarsTab      },
        { key = "resource", label = L["tab_resource_bars"], builder = BuildResourceBarsTab    },
        { key = "textpos",  label = L["tab_text_position"],         builder = BuildTextPositionTab    },
        { key = "colors",   label = L["tab_rb_colors"],      builder = BuildColorsTab          },
    })
end

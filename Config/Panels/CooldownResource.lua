-- =====================================
-- Panels/CooldownResource.lua — Cooldown & Resource Config
-- =====================================

local W = TomoMod_Widgets
local L = TomoMod_L

-- =====================================
-- COLOR SECTION
-- =====================================
local function CreateColorSection(parent, y)
    local db = TomoModDB.resourceBars.colors

    local _, ny = W.CreateSectionHeader(parent, L["section_resource_colors"], y)
    y = ny

    local entries = {
        { key = "mana",            label = L["res_mana"] },
        { key = "rage",            label = L["res_rage"] },
        { key = "energy",          label = L["res_energy"] },
        { key = "focus",           label = L["res_focus"] },
        { key = "runicPower",      label = L["res_runic_power"] },
        { key = "runesReady",      label = L["res_runes_ready"] },
        { key = "runes",           label = L["res_runes_cd"] },
        { key = "soulShards",      label = L["res_soul_shards"] },
        { key = "astralPower",     label = L["res_astral_power"] },
        { key = "holyPower",       label = L["res_holy_power"] },
        { key = "maelstrom",       label = L["res_maelstrom"] },
        { key = "chi",             label = L["res_chi"] },
        { key = "insanity",        label = L["res_insanity"] },
        { key = "fury",            label = L["res_fury"] },
        { key = "comboPoints",     label = L["res_combo_points"] },
        { key = "arcaneCharges",   label = L["res_arcane_charges"] },
        { key = "essence",         label = L["res_essence"] },
        { key = "stagger",         label = L["res_stagger"] },
        { key = "soulFragments",   label = L["res_soul_fragments"] },
        { key = "tipOfTheSpear",   label = L["res_tip_of_spear"] },
        { key = "maelstromWeapon", label = L["res_maelstrom_weapon"] },
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

    local _, ny = W.CreateSectionHeader(c, L["section_cdm"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_cdm_enable"], cdm.enabled, y, function(v)
        cdm.enabled = v
        if TomoMod_CooldownManager then TomoMod_CooldownManager.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_cdm_description"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_cdm_show_hotkeys"], cdm.showHotKey, y, function(v)
        cdm.showHotKey = v
        if TomoMod_CooldownManager then TomoMod_CooldownManager.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_cdm_combat_alpha"], cdm.combatAlpha, y, function(v)
        cdm.combatAlpha = v
        if TomoMod_CooldownManager then TomoMod_CooldownManager.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_cdm_alpha_combat"], cdm.alphaInCombat or 1.0, 0, 1, 0.05, y, function(v)
        cdm.alphaInCombat = v
        if TomoMod_CooldownManager then TomoMod_CooldownManager.ApplySettings() end
    end, "%.2f")
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_cdm_alpha_target"], cdm.alphaWithTarget or 0.8, 0, 1, 0.05, y, function(v)
        cdm.alphaWithTarget = v
        if TomoMod_CooldownManager then TomoMod_CooldownManager.ApplySettings() end
    end, "%.2f")
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_cdm_alpha_ooc"], cdm.alphaOutOfCombat or 0.5, 0, 1, 0.05, y, function(v)
        cdm.alphaOutOfCombat = v
        if TomoMod_CooldownManager then TomoMod_CooldownManager.ApplySettings() end
    end, "%.2f")
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_cdm_editmode"], y)
    y = ny

    -- =============================================
    -- RESOURCE BARS
    -- =============================================
    local db = TomoModDB.resourceBars

    -- === GENERAL ===
    local _, ny = W.CreateSectionHeader(c, L["section_resource_bars"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_rb_enable"], db.enabled, y, function(v)
        db.enabled = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_rb_description"], y)
    y = ny

    -- === VISIBILITY ===
    local _, ny = W.CreateSectionHeader(c, L["section_visibility"], y)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_rb_visibility_mode"], {
        { text = L["vis_always"], value = "always" },
        { text = L["vis_combat"], value = "combat" },
        { text = L["vis_target"], value = "target" },
        { text = L["vis_hidden"], value = "hidden" },
    }, db.visibilityMode or "always", y, function(v)
        db.visibilityMode = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_cdm_alpha_combat"], db.combatAlpha or 1.0, 0, 1, 0.05, y, function(v)
        db.combatAlpha = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end, "%.2f")
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_cdm_alpha_ooc"], db.oocAlpha or 0.5, 0, 1, 0.05, y, function(v)
        db.oocAlpha = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end, "%.2f")
    y = ny

    -- === DIMENSIONS ===
    local _, ny = W.CreateSectionHeader(c, L["section_dimensions"], y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_rb_width"], db.width or 260, 80, 600, 5, y, function(v)
        db.width = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_rb_primary_height"], db.primaryHeight or 16, 6, 40, 1, y, function(v)
        db.primaryHeight = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_rb_secondary_height"], db.secondaryHeight or 12, 6, 30, 1, y, function(v)
        db.secondaryHeight = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_rb_global_scale"], db.scale or 1.0, 0.5, 2.0, 0.05, y, function(v)
        db.scale = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end, "%.2f")
    y = ny

    -- === SYNC WITH COOLDOWNS ===
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_rb_sync_width"], db.syncWidthWithCooldowns or false, y, function(v)
        db.syncWidthWithCooldowns = v
        if v and TomoMod_ResourceBars then TomoMod_ResourceBars.SyncWidth() end
    end)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_sync_now"], 160, y, function()
        if TomoMod_ResourceBars then TomoMod_ResourceBars.SyncWidth() end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_rb_sync"], y)
    y = ny

    -- === TEXT & FONT ===
    local _, ny = W.CreateSectionHeader(c, L["section_text_font"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_rb_show_text"], db.showText, y, function(v)
        db.showText = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_rb_text_align"], {
        { text = L["align_left"], value = "LEFT" },
        { text = L["align_center"], value = "CENTER" },
        { text = L["align_right"], value = "RIGHT" },
    }, db.textAlignment or "CENTER", y, function(v)
        db.textAlignment = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_rb_font_size"], db.fontSize or 11, 7, 20, 1, y, function(v)
        db.fontSize = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_rb_font"], {
        { text = "Poppins Medium", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf" },
        { text = "Poppins Bold", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf" },
        { text = "Expressway", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Expressway.TTF" },
        { text = "Tomo", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Tomo.ttf" },
        { text = "Accidental", value = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\accidental_pres.ttf" },
        { text = L["font_default_wow"], value = STANDARD_TEXT_FONT },
    }, db.font or "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", y, function(v)
        db.font = v
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
    end)
    y = ny

    -- === POSITION ===
    local _, ny = W.CreateSectionHeader(c, L["section_position"], y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_toggle_lock"], 260, y, function()
        if TomoMod_UnitFrames and TomoMod_UnitFrames.ToggleLock then
            TomoMod_UnitFrames.ToggleLock()
        end
        if TomoMod_ResourceBars and TomoMod_ResourceBars.ToggleLock then
            TomoMod_ResourceBars.ToggleLock()
        end
    end)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_reset_position"], 160, y, function()
        db.position = nil
        if TomoMod_ResourceBars then TomoMod_ResourceBars.ApplySettings() end
        print("|cff0cd29fTomoMod|r " .. L["msg_rb_position_reset"])
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_rb_position"], y)
    y = ny

    -- === COLORS ===
    y = CreateColorSection(c, y)

    -- === FOOTER ===
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_rb_druid"], y)
    y = ny - 20

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

-- Panels/Castbars.lua — Standalone Castbar Config Panel
local W = TomoMod_Widgets
local L = TomoMod_L

local function ApplyCB() if TomoMod_Castbar then TomoMod_Castbar.ApplySettings() end end

-- ══════════════════════════════════════════════
-- TAB: GENERAL
-- ══════════════════════════════════════════════
local function BuildGeneralTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.castbars
    local y = -12

    -- Activation
    local card, cy = W.CreateCard(c, L["cb_section_general"], y)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_cb_enable"], db.enabled, cy, function(v)
        db.enabled = v
        if TomoMod_Castbar then TomoMod_Castbar.SetEnabled(v) end
    end)
    local _, cy = W.CreateInfoText(card.inner, L["info_cb_description"], cy)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_cb_hide_blizzard"], db.hideBlizzardCastbar, cy, function(v) db.hideBlizzardCastbar = v; ApplyCB() end)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_cb_class_color"], db.useClassColor, cy, function(v) db.useClassColor = v; ApplyCB() end)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_cb_show_transitions"], db.showTransitions, cy, function(v) db.showTransitions = v; ApplyCB() end)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_cb_show_channel_ticks"], db.showChannelTicks, cy, function(v) db.showChannelTicks = v; ApplyCB() end)
    local _, cy = W.CreateDropdown(card.inner, L["opt_cb_timer_format"], {
        { text = L["cb_timer_remaining"],       value = "remaining" },
        { text = L["cb_timer_remaining_total"], value = "remaining_total" },
        { text = L["cb_timer_elapsed"],         value = "elapsed" },
    }, db.timerFormat or "remaining", cy, function(v) db.timerFormat = v; ApplyCB() end)
    local _, cy = W.CreateSlider(card.inner, L["opt_cb_spell_max_len"], db.spellNameMaxLen or 0, 0, 40, 1, cy, function(v) db.spellNameMaxLen = v; ApplyCB() end, "%.0f")
    y = W.FinalizeCard(card, cy)

    -- Appearance
    local card2, cy = W.CreateCard(c, L["cb_section_appearance"], y)
    local _, cy = W.CreateDropdown(card2.inner, L["opt_cb_bar_texture"], {
        { text = L["cb_tex_blizzard"], value = "blizzard" },
        { text = L["cb_tex_smooth"],   value = "smooth" },
        { text = L["cb_tex_flat"],     value = "flat" },
    }, db.barTexture or "blizzard", cy, function(v) db.barTexture = v; ApplyCB() end)
    local _, cy = W.CreateSlider(card2.inner, L["opt_cb_font_size"], db.fontSize or 12, 8, 24, 1, cy, function(v) db.fontSize = v; ApplyCB() end, "%.0f")
    local _, cy = W.CreateDropdown(card2.inner, L["opt_cb_bg_mode"], {
        { text = L["cb_bg_black"],       value = "black" },
        { text = L["cb_bg_transparent"], value = "transparent" },
        { text = L["cb_bg_custom"],      value = "custom" },
    }, db.backgroundMode or "black", cy, function(v) db.backgroundMode = v; ApplyCB() end)
    y = W.FinalizeCard(card2, cy)

    -- Colors
    local card3, cy = W.CreateCard(c, L["cb_section_colors"], y)
    local castCol = db.castbarColor or { r = 1, g = 0.7, b = 0 }
    local niCol   = db.castbarNIColor or { r = 0.5, g = 0.5, b = 0.5 }
    local intCol  = db.castbarInterruptColor or { r = 0.1, g = 0.8, b = 0.1 }
    local _, cy = W.CreateColorPicker(card3.inner, L["opt_cb_cast_color"], castCol, cy, function(r,g,b) db.castbarColor = { r=r, g=g, b=b }; ApplyCB() end)
    local _, cy = W.CreateColorPicker(card3.inner, L["opt_cb_ni_color"], niCol, cy, function(r,g,b) db.castbarNIColor = { r=r, g=g, b=b }; ApplyCB() end)
    local _, cy = W.CreateColorPicker(card3.inner, L["opt_cb_interrupt_color"], intCol, cy, function(r,g,b) db.castbarInterruptColor = { r=r, g=g, b=b }; ApplyCB() end)
    y = W.FinalizeCard(card3, cy)

    -- Spark
    local card4, cy = W.CreateCard(c, L["cb_section_spark"], y)
    local _, cy = W.CreateCheckbox(card4.inner, L["opt_cb_show_spark"], db.showSpark, cy, function(v) db.showSpark = v; ApplyCB() end)
    local _, cy = W.CreateDropdown(card4.inner, L["opt_cb_spark_style"], {
        { text = "Comet",  value = "Comet" },
        { text = "Pulse",  value = "Pulse" },
        { text = "Helix",  value = "Helix" },
        { text = "Glitch", value = "Glitch" },
    }, db.sparkStyle or "Comet", cy, function(v) db.sparkStyle = v; ApplyCB() end)
    local sCol   = db.sparkColor     or { r = 1, g = 1, b = 1 }
    local sgCol  = db.sparkGlowColor or { r = 1, g = 0.9, b = 0.5 }
    local stCol  = db.sparkTailColor or { r = 1, g = 0.8, b = 0.3 }
    local _, cy = W.CreateColorPicker(card4.inner, L["opt_cb_spark_color"], sCol, cy, function(r,g,b) db.sparkColor = { r=r, g=g, b=b }; ApplyCB() end)
    local _, cy = W.CreateColorPicker(card4.inner, L["opt_cb_spark_glow_color"], sgCol, cy, function(r,g,b) db.sparkGlowColor = { r=r, g=g, b=b }; ApplyCB() end)
    local _, cy = W.CreateColorPicker(card4.inner, L["opt_cb_spark_tail_color"], stCol, cy, function(r,g,b) db.sparkTailColor = { r=r, g=g, b=b }; ApplyCB() end)
    local _, cy = W.CreateSlider(card4.inner, L["opt_cb_spark_glow_alpha"], db.sparkGlowAlpha or 0.7, 0, 1, 0.05, cy, function(v) db.sparkGlowAlpha = v; ApplyCB() end, "%.2f")
    local _, cy = W.CreateSlider(card4.inner, L["opt_cb_spark_tail_alpha"], db.sparkTailAlpha or 0.6, 0, 1, 0.05, cy, function(v) db.sparkTailAlpha = v; ApplyCB() end, "%.2f")
    y = W.FinalizeCard(card4, cy)

    -- GCD
    local card5, cy = W.CreateCard(c, L["cb_section_gcd"], y)
    local _, cy = W.CreateCheckbox(card5.inner, L["opt_cb_show_gcd"], db.showGCDSpark, cy, function(v) db.showGCDSpark = v; ApplyCB() end)
    local _, cy = W.CreateSlider(card5.inner, L["opt_cb_gcd_height"], db.gcdHeight or 4, 2, 12, 1, cy, function(v) db.gcdHeight = v; ApplyCB() end, "%.0f")
    local gcdCol = db.gcdColor or { r = 1, g = 1, b = 1 }
    local _, cy = W.CreateColorPicker(card5.inner, L["opt_cb_gcd_color"], gcdCol, cy, function(r,g,b) db.gcdColor = { r=r, g=g, b=b }; ApplyCB() end)
    y = W.FinalizeCard(card5, cy)

    -- Interrupt feedback
    local card6, cy = W.CreateCard(c, L["cb_section_interrupt"], y)
    local _, cy = W.CreateCheckbox(card6.inner, L["opt_cb_show_interrupt_feedback"], db.showInterruptFeedback, cy, function(v) db.showInterruptFeedback = v end)
    local fbCol = db.interruptFeedbackColor or { r = 0.1, g = 0.8, b = 0.1 }
    local _, cy = W.CreateColorPicker(card6.inner, L["opt_cb_interrupt_fb_color"], fbCol, cy, function(r,g,b) db.interruptFeedbackColor = { r=r, g=g, b=b } end)
    local _, cy = W.CreateSlider(card6.inner, L["opt_cb_interrupt_fb_size"], db.interruptFeedbackFontSize or 28, 14, 48, 1, cy, function(v) db.interruptFeedbackFontSize = v end, "%.0f")
    y = W.FinalizeCard(card6, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- TAB: PER-UNIT
-- ══════════════════════════════════════════════
local function BuildUnitTab(parent, unitKey, unitLabel)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.castbars
    local udb = db[unitKey]
    if not udb then return scroll end
    local y = -12

    local card, cy = W.CreateCard(c, string.format(L["cb_section_unit"], unitLabel), y)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_cb_unit_enable"], udb.enabled, cy, function(v) udb.enabled = v; ApplyCB() end)
    local _, cy = W.CreateSlider(card.inner, L["opt_cb_unit_width"], udb.width or 260, 100, 500, 5, cy, function(v) udb.width = v; ApplyCB() end, "%.0f")
    local _, cy = W.CreateSlider(card.inner, L["opt_cb_unit_height"], udb.height or 22, 8, 40, 1, cy, function(v) udb.height = v; ApplyCB() end, "%.0f")
    local _, cy = W.CreateCheckbox(card.inner, L["opt_cb_unit_show_icon"], udb.showIcon, cy, function(v) udb.showIcon = v; ApplyCB() end)
    local _, cy = W.CreateDropdown(card.inner, L["opt_cb_unit_icon_side"], {
        { text = L["cb_icon_left"],  value = "LEFT" },
        { text = L["cb_icon_right"], value = "RIGHT" },
    }, udb.iconSide or "LEFT", cy, function(v) udb.iconSide = v; ApplyCB() end)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_cb_unit_show_timer"], udb.showTimer, cy, function(v) udb.showTimer = v; ApplyCB() end)

    if unitKey == "player" then
        local _, cy2 = W.CreateCheckbox(card.inner, L["opt_cb_unit_show_latency"], udb.showLatency, cy, function(v) udb.showLatency = v; ApplyCB() end)
        local _, cy2 = W.CreateInfoText(card.inner, L["info_cb_latency"], cy2)
        cy = cy2
    end

    local _, cy = W.CreateInfoText(card.inner, L["info_cb_position"], cy)
    local _, cy = W.CreateButton(card.inner, L["btn_cb_reset_position"], 180, cy, function()
        local defaults = TomoMod_Defaults.castbars[unitKey]
        if defaults and defaults.position then
            udb.position = CopyTable(defaults.position)
            ApplyCB()
        end
    end)
    y = W.FinalizeCard(card, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- MAIN BUILDER (tabbed)
-- ══════════════════════════════════════════════
function TomoMod_ConfigPanel_Castbars(contentArea)
    local unitLabels = {
        player = L["unit_player"] or "Player",
        target = L["unit_target"] or "Target",
        focus  = L["unit_focus"]  or "Focus",
        pet    = L["unit_pet"]    or "Pet",
        boss   = L["tab_boss"]    or "Boss",
    }

    return W.CreateTabPanel(contentArea, {
        { key = "general", label = L["cb_tab_general"] or "General", builder = BuildGeneralTab },
        { key = "player",  label = L["cb_tab_player"]  or "Player",  builder = function(p) return BuildUnitTab(p, "player", unitLabels.player) end },
        { key = "target",  label = L["cb_tab_target"]  or "Target",  builder = function(p) return BuildUnitTab(p, "target", unitLabels.target) end },
        { key = "focus",   label = L["cb_tab_focus"]   or "Focus",   builder = function(p) return BuildUnitTab(p, "focus",  unitLabels.focus)  end },
        { key = "pet",     label = L["cb_tab_pet"]     or "Pet",     builder = function(p) return BuildUnitTab(p, "pet",    unitLabels.pet)    end },
        { key = "boss",    label = L["cb_tab_boss"]    or "Boss",    builder = function(p) return BuildUnitTab(p, "boss",   unitLabels.boss)   end },
    })
end

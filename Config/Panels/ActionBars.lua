-- =====================================
-- Config/Panels/ActionBars.lua v4.0.0
-- Unified action bars: Skin style + per-bar settings
-- Uses AB.BAR_DEFS as single source of truth.
-- =====================================

local L = TomoMod_L
local W = TomoMod_Widgets

local FONT_MEDIUM = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_SEMI   = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

local SKIN_STYLES_LIST = {
    { value = "classic",  text = "Classic (9-slice)" },
    { value = "flat",     text = "Flat" },
    { value = "outlined", text = "Outlined" },
    { value = "glass",    text = "Glass" },
    { value = "minimal",  text = "Minimal (sans bordure)" },
}

local CD_BACKEND_LIST = {
    { value = "native",  text = "Blizzard" },
    { value = "managed", text = "TomoMod" },
}

local GLOW_TYPE_LIST = {
    { value = "Pixel Glow",         text = "Pixel" },
    { value = "Autocast Shine",     text = "Autocast" },
    { value = "Action Button Glow", text = "Button" },
    { value = "Proc Glow",          text = "Proc" },
    { value = "Blizzard Glow",      text = "Blizzard" },
}

local HK_ANCHOR_LIST = {
    { value = "TOPRIGHT",    text = "Haut droite" },
    { value = "TOPLEFT",     text = "Haut gauche" },
    { value = "TOP",         text = "Haut" },
    { value = "BOTTOMRIGHT", text = "Bas droite" },
    { value = "BOTTOMLEFT",  text = "Bas gauche" },
    { value = "BOTTOM",      text = "Bas" },
    { value = "CENTER",      text = "Centre" },
}

local ORIENTATION_LIST = {
    { value = "horizontal", text = "Horizontal" },
    { value = "vertical",   text = "Vertical" },
}

local GROW_DIR_LIST = {
    { value = "rightdown", text = "Droite + Bas" },
    { value = "rightup",   text = "Droite + Haut" },
    { value = "leftdown",  text = "Gauche + Bas" },
    { value = "leftup",    text = "Gauche + Haut" },
}

-- Build display condition dropdown from presets
local function GetConditionList()
    local list = {}
    local AB = TomoMod_ActionBars
    if AB and AB.DISPLAY_PRESETS then
        for _, p in ipairs(AB.DISPLAY_PRESETS) do
            list[#list + 1] = { value = p.condition, text = p.label }
        end
    else
        list[1] = { value = "", text = "always" }
    end
    return list
end

-- =====================================================================
-- TAB 1 -- SKIN STYLE
-- =====================================================================
local function BuildSkinTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_action_bars"], y)
    y = ny

    if not TomoModDB.actionBars then TomoModDB.actionBars = {} end
    if not TomoModDB.actionBarSkin then TomoModDB.actionBarSkin = {} end

    -- Master system toggle
    local _, ny = W.CreateSectionHeader(c, L["section_ab_system"], y)
    y = ny
    local _, ny = W.CreateCheckbox(c, L["opt_ab_system_enable"],
        TomoModDB.actionBars.enabled ~= false, y, function(v)
            TomoModDB.actionBars.enabled = v
        end)
    y = ny
    local _, ny = W.CreateInfoText(c, L["opt_ab_system_reload"], y)
    y = ny

    -- Skin toggle
    local _, ny = W.CreateSectionHeader(c, L["section_ab_skin"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_abs_enable"], TomoModDB.actionBarSkin.enabled, y, function(v)
        TomoModDB.actionBarSkin.enabled = v
        if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_abs_style"], SKIN_STYLES_LIST,
        TomoModDB.actionBarSkin.skinStyle or "classic", y, function(v)
            TomoModDB.actionBarSkin.skinStyle = v
            if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.Reskin() end
        end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_abs_class_color"],
        TomoModDB.actionBarSkin.useClassColor, y, function(v)
            TomoModDB.actionBarSkin.useClassColor = v
            if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.UpdateColors() end
        end)
    y = ny

    -- Shift reveal (now on actionBars)
    if not TomoModDB.actionBars then TomoModDB.actionBars = {} end
    local _, ny = W.CreateCheckbox(c, L["opt_abs_shift_reveal"],
        TomoModDB.actionBars.shiftReveal or false, y, function(v)
            TomoModDB.actionBars.shiftReveal = v
            local AB = TomoMod_ActionBars
            if AB and AB.SetShiftReveal then AB.SetShiftReveal(v) end
        end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================================================
-- TAB 2 -- BUTTONS (icons, cooldowns, texts, state decoration)
-- =====================================================================
local function BuildButtonsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    -- =================================================================
    -- ICONS & COOLDOWNS (render layer, AB_Render)
    -- =================================================================
    local RENDER = TomoMod_ABRender
    local rdb = RENDER and RENDER.GetSettings and RENDER.GetSettings() or nil
    if rdb then
        local function ApplyRender()
            if RENDER.ApplySettings then RENDER.ApplySettings() end
        end
        local sc = rdb.swipeColor or { 0, 0, 0, 0.65 }

        local _, ny = W.CreateSectionHeader(c, L["section_ab_icons"], y)
        y = ny

        local _, ny = W.CreateDropdown(c, L["opt_ab_cd_backend"], CD_BACKEND_LIST,
            rdb.cooldownBackend or "native", y, function(v)
                rdb.cooldownBackend = v
                ApplyRender()
            end)
        y = ny

        local _, ny = W.CreateInfoText(c, L["info_ab_cd_managed"], y)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_ab_cd_numbers"],
            rdb.countdownNumbers ~= false, y, function(v)
                rdb.countdownNumbers = v
                ApplyRender()
            end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_ab_cd_size"],
            rdb.countdownFontSize or 16, 8, 28, 1, y, function(v)
                rdb.countdownFontSize = v
                ApplyRender()
            end)
        y = ny

        local _, ny = W.CreateColorPicker(c, L["opt_ab_swipe_color"],
            { r = sc[1] or 0, g = sc[2] or 0, b = sc[3] or 0 }, y, function(r, g, b)
                sc[1], sc[2], sc[3] = r, g, b
                rdb.swipeColor = sc
                ApplyRender()
            end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_ab_swipe_alpha"],
            sc[4] or 0.65, 0, 1, 0.05, y, function(v)
                sc[4] = v
                rdb.swipeColor = sc
                ApplyRender()
            end)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_ab_show_count"],
            rdb.showCount ~= false, y, function(v)
                rdb.showCount = v
                ApplyRender()
            end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_ab_count_size"],
            rdb.countFontSize or 12, 8, 24, 1, y, function(v)
                rdb.countFontSize = v
                ApplyRender()
            end)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_ab_show_macro"],
            rdb.showMacroText or false, y, function(v)
                rdb.showMacroText = v
                ApplyRender()
            end)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_ab_desat_unusable"],
            rdb.desaturateUnusable or false, y, function(v)
                rdb.desaturateUnusable = v
                ApplyRender()
            end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_ab_icon_zoom"],
            rdb.iconZoom or 0.07, 0, 0.20, 0.01, y, function(v)
                rdb.iconZoom = v
                ApplyRender()
            end)
        y = ny
    end

    -- =================================================================
    -- STANCES / PET / STATE DECORATION (AB_Special)
    -- =================================================================
    local SP = TomoMod_ABSpecial
    local sdb = SP and SP.GetSettings and SP.GetSettings() or nil
    if sdb then
        local function ApplySP()
            if SP.ApplySettings then SP.ApplySettings() end
        end
        local acCol = sdb.activeColor   or { 1, 0.82, 0.25, 1 }
        local eqCol = sdb.equippedColor or { 0.18, 0.85, 0.52, 1 }
        local auCol = sdb.autoCastColor or { 0.95, 0.95, 0.32, 1 }

        local _, ny = W.CreateSectionHeader(c, L["section_ab_special"], y)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_ab_sp_active"],
            sdb.activeEnabled ~= false, y, function(v)
                sdb.activeEnabled = v
                ApplySP()
            end)
        y = ny

        local _, ny = W.CreateColorPicker(c, L["opt_ab_sp_active_color"],
            { r = acCol[1] or 1, g = acCol[2] or 1, b = acCol[3] or 1 }, y, function(r, g, b)
                acCol[1], acCol[2], acCol[3] = r, g, b
                sdb.activeColor = acCol
                ApplySP()
            end)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_ab_sp_equipped"],
            sdb.equippedEnabled ~= false, y, function(v)
                sdb.equippedEnabled = v
                ApplySP()
            end)
        y = ny

        local _, ny = W.CreateColorPicker(c, L["opt_ab_sp_equipped_color"],
            { r = eqCol[1] or 1, g = eqCol[2] or 1, b = eqCol[3] or 1 }, y, function(r, g, b)
                eqCol[1], eqCol[2], eqCol[3] = r, g, b
                sdb.equippedColor = eqCol
                ApplySP()
            end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_ab_sp_thickness"],
            sdb.accentThickness or 2, 1, 6, 1, y, function(v)
                sdb.accentThickness = v
                ApplySP()
            end)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_ab_sp_autocast"],
            sdb.autoCastShine ~= false, y, function(v)
                sdb.autoCastShine = v
                ApplySP()
            end)
        y = ny

        local _, ny = W.CreateColorPicker(c, L["opt_ab_sp_autocast_color"],
            { r = auCol[1] or 1, g = auCol[2] or 1, b = auCol[3] or 1 }, y, function(r, g, b)
                auCol[1], auCol[2], auCol[3] = r, g, b
                sdb.autoCastColor = auCol
                ApplySP()
            end)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_ab_sp_pet_autohide"],
            sdb.petAutoHide or false, y, function(v)
                sdb.petAutoHide = v
                if SP.RefreshPetVisibility then SP.RefreshPetVisibility() end
            end)
        y = ny

        local _, ny = W.CreateInfoText(c, L["info_ab_sp_pet_autohide"], y)
        y = ny
    end

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================================================
-- TAB 3 -- GLOW (procs, rotation hint)
-- =====================================================================
local function BuildGlowTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    -- =================================================================
    -- GLOW (AB_Glow): procs + rotation hint
    -- =================================================================
    local GLOW = TomoMod_ABGlow
    local gdb = GLOW and GLOW.GetSettings and GLOW.GetSettings() or nil
    if gdb then
        local function ApplyGlow()
            if GLOW.ApplySettings then GLOW.ApplySettings() end
        end
        local pc = gdb.procColor   or { 0.95, 0.95, 0.32, 1 }
        local ac = gdb.assistColor or { 0.18, 0.85, 0.52, 1 }

        local _, ny = W.CreateSectionHeader(c, L["section_ab_glow"], y)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_ab_glow_proc"],
            gdb.procEnabled ~= false, y, function(v)
                gdb.procEnabled = v
                ApplyGlow()
            end)
        y = ny

        local _, ny = W.CreateDropdown(c, L["opt_ab_glow_proc_type"], GLOW_TYPE_LIST,
            gdb.procType or "Pixel Glow", y, function(v)
                gdb.procType = v
                ApplyGlow()
            end)
        y = ny

        local _, ny = W.CreateColorPicker(c, L["opt_ab_glow_proc_color"],
            { r = pc[1] or 1, g = pc[2] or 1, b = pc[3] or 1 }, y, function(r, g, b)
                pc[1], pc[2], pc[3] = r, g, b
                gdb.procColor = pc
                ApplyGlow()
            end)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_ab_glow_assist"],
            gdb.assistEnabled or false, y, function(v)
                gdb.assistEnabled = v
                ApplyGlow()
                if GLOW.UpdateAssistTicker then GLOW.UpdateAssistTicker() end
            end)
        y = ny

        local _, ny = W.CreateInfoText(c, L["info_ab_glow_assist"], y)
        y = ny

        local _, ny = W.CreateDropdown(c, L["opt_ab_glow_assist_type"], GLOW_TYPE_LIST,
            gdb.assistType or "Proc Glow", y, function(v)
                gdb.assistType = v
                ApplyGlow()
            end)
        y = ny

        local _, ny = W.CreateColorPicker(c, L["opt_ab_glow_assist_color"],
            { r = ac[1] or 1, g = ac[2] or 1, b = ac[3] or 1 }, y, function(r, g, b)
                ac[1], ac[2], ac[3] = r, g, b
                gdb.assistColor = ac
                ApplyGlow()
            end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_ab_glow_lines"],
            gdb.pixelLines or 8, 2, 20, 1, y, function(v)
                gdb.pixelLines = v
                ApplyGlow()
            end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_ab_glow_thickness"],
            gdb.pixelThickness or 2, 1, 6, 1, y, function(v)
                gdb.pixelThickness = v
                ApplyGlow()
            end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_ab_glow_freq"],
            gdb.pixelFrequency or 0.25, 0.05, 1, 0.05, y, function(v)
                gdb.pixelFrequency = v
                gdb.autoFrequency = v
                gdb.buttonFrequency = v
                ApplyGlow()
            end)
        y = ny
    end

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================================================
-- TAB 4 -- HOTKEYS (keybind text, binding mode)
-- =====================================================================
local function BuildHotkeyTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    -- =================================================================
    -- HOTKEYS (AB_Hotkey)
    -- =================================================================
    local HK = TomoMod_ABHotkey
    local hdb = HK and HK.GetSettings and HK.GetSettings() or nil
    if hdb then
        local function ApplyHK()
            if HK.ApplySettings then HK.ApplySettings() end
        end
        local hc = hdb.color or { 1, 1, 1, 1 }

        local _, ny = W.CreateSectionHeader(c, L["section_ab_hotkey"], y)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_ab_hk_enable"],
            hdb.enabled ~= false, y, function(v)
                hdb.enabled = v
                ApplyHK()
            end)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_ab_hk_abbrev"],
            hdb.abbreviate ~= false, y, function(v)
                hdb.abbreviate = v
                ApplyHK()
            end)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_ab_hk_hide_empty"],
            hdb.hideEmpty ~= false, y, function(v)
                hdb.hideEmpty = v
                ApplyHK()
            end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_ab_hk_size"],
            hdb.fontSize or 12, 6, 24, 1, y, function(v)
                hdb.fontSize = v
                ApplyHK()
            end)
        y = ny

        local _, ny = W.CreateDropdown(c, L["opt_ab_hk_anchor"], HK_ANCHOR_LIST,
            hdb.anchor or "TOPRIGHT", y, function(v)
                hdb.anchor = v
                ApplyHK()
            end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_ab_hk_offx"],
            hdb.offsetX or -2, -20, 20, 1, y, function(v)
                hdb.offsetX = v
                ApplyHK()
            end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_ab_hk_offy"],
            hdb.offsetY or -2, -20, 20, 1, y, function(v)
                hdb.offsetY = v
                ApplyHK()
            end)
        y = ny

        local _, ny = W.CreateColorPicker(c, L["opt_ab_hk_color"],
            { r = hc[1] or 1, g = hc[2] or 1, b = hc[3] or 1 }, y, function(r, g, b)
                hc[1], hc[2], hc[3] = r, g, b
                hdb.color = hc
                ApplyHK()
            end)
        y = ny

        local _, ny = W.CreateButton(c, L["btn_ab_hk_bind"], 260, y, function()
            if HK.ToggleBindMode then HK.ToggleBindMode() end
        end)
        y = ny

        local _, ny = W.CreateInfoText(c, L["info_ab_hk_bind"], y)
        y = ny

        -- Only offered when another addon in the profile provides the library.
        local KBM = TomoMod_ABKeyBound
        if KBM and KBM.IsAvailable and KBM.IsAvailable() then
            local _, ny = W.CreateButton(c, L["btn_ab_kb_lib"], 260, y, function()
                if KBM.Toggle then KBM.Toggle() end
            end)
            y = ny

            local _, ny = W.CreateInfoText(c, L["info_ab_kb_lib"], y)
            y = ny
        end
    end

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================================================
-- TAB 5 -- BAR MANAGEMENT (collapsible per-bar sections)
-- =====================================================================

-- Helper: get localized bar display name
local function GetBarDisplayName(id)
    local nameKey = "bar_name_" .. id
    local localized = L[nameKey]
    if localized and localized ~= nameKey then return localized end
    return id:sub(1,1):upper() .. id:sub(2)
end

-- Helper: apply a single bar setting change and refresh
local function SetBarVal(id, key, val)
    if not TomoModDB.actionBars then return end
    if not TomoModDB.actionBars.bars then TomoModDB.actionBars.bars = {} end
    if not TomoModDB.actionBars.bars[id] then TomoModDB.actionBars.bars[id] = {} end
    TomoModDB.actionBars.bars[id][key] = val
    local AB = TomoMod_ActionBars
    if AB and AB.RefreshBar then AB.RefreshBar(id) end
end

-- Popup de confirmation pour "uniformiser" (action destructive : écrase
-- l'apparence de toutes les autres barres).
StaticPopupDialogs["TOMOMOD_AB_UNIFORMIZE"] = {
    text = L["popup_ab_uniformize"],
    button1 = L["popup_confirm"],
    button2 = L["popup_cancel"],
    OnAccept = function(self, data)
        local AB = TomoMod_ActionBars
        if AB and AB.CopyBarToAll and data and data.id then
            AB.CopyBarToAll(data.id)
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- Accent color helper
local ACCENT_R, ACCENT_G, ACCENT_B = TomoMod_Utils.BRAND[1], TomoMod_Utils.BRAND[2], TomoMod_Utils.BRAND[3]
local HEADER_H = 30
local HEADER_GAP = 2

-- Build the content widgets for a single bar inside a parent frame.
-- Returns the total content height.
local function BuildBarContent(contentFrame, id, barDB)
    local AB = TomoMod_ActionBars
    local cy = -6

    -- Enabled checkbox
    local _, cny = W.CreateCheckbox(contentFrame, L["opt_bar_enabled"], barDB.enabled ~= false, cy, function(v)
        SetBarVal(id, "enabled", v)
    end)
    cy = cny

    -- Orientation dropdown
    local AB_ = TomoMod_ActionBars
    if AB_ and AB_.OWN_BUTTON_ELIGIBLE and AB_.OWN_BUTTON_ELIGIBLE[id] then
        local _, cny = W.CreateCheckbox(contentFrame, L["opt_bar_own_buttons"],
            barDB.useOwnButtons == true, cy, function(v)
                SetBarVal(id, "useOwnButtons", v)
            end)
        cy = cny
        local _, cny = W.CreateInfoText(contentFrame, L["info_bar_own_buttons"], cy)
        cy = cny
    end

    local _, cny = W.CreateDropdown(contentFrame, L["opt_bar_orientation"], ORIENTATION_LIST,
        barDB.orientation or "horizontal", cy, function(v)
            SetBarVal(id, "orientation", v)
        end)
    cy = cny

    -- Grow direction dropdown
    local _, cny = W.CreateDropdown(contentFrame, L["opt_bar_grow_dir"], GROW_DIR_LIST,
        barDB.growDirection or "rightdown", cy, function(v)
            SetBarVal(id, "growDirection", v)
        end)
    cy = cny

    -- Columns slider
    local _, cny = W.CreateSlider(contentFrame, L["opt_bar_columns"],
        barDB.columns or 12, 1, 12, 1, cy, function(v)
            SetBarVal(id, "columns", v)
        end, "%.0f")
    cy = cny

    -- Button size slider
    local _, cny = W.CreateSlider(contentFrame, L["opt_bar_button_size"],
        barDB.buttonSize or 36, 20, 64, 1, cy, function(v)
            SetBarVal(id, "buttonSize", v)
        end, "%.0f px")
    cy = cny

    -- Spacing slider
    local _, cny = W.CreateSlider(contentFrame, L["opt_bar_spacing"],
        barDB.spacing or 2, 0, 12, 1, cy, function(v)
            SetBarVal(id, "spacing", v)
        end, "%.0f px")
    cy = cny

    -- Alpha slider
    local _, cny = W.CreateSlider(contentFrame, L["opt_bar_alpha"],
        (barDB.alpha or 1) * 100, 0, 100, 5, cy, function(v)
            SetBarVal(id, "alpha", v / 100)
        end, "%.0f%%")
    cy = cny

    -- Scale slider
    local _, cny = W.CreateSlider(contentFrame, L["opt_bar_scale"],
        (barDB.scale or 1) * 100, 50, 200, 5, cy, function(v)
            SetBarVal(id, "scale", v / 100)
        end, "%.0f%%")
    cy = cny

    -- Display condition dropdown
    local _, cny = W.CreateDropdown(contentFrame, L["opt_bar_display_cond"], GetConditionList(),
        barDB.displayCondition or "", cy, function(v)
            SetBarVal(id, "displayCondition", v)
            if AB and AB.UpdateDisplayCondition then AB.UpdateDisplayCondition(id) end
        end)
    cy = cny

    -- Fade section
    local _, cny = W.CreateCheckbox(contentFrame, L["opt_bar_fade"], barDB.fadeEnabled or false, cy, function(v)
        SetBarVal(id, "fadeEnabled", v)
    end)
    cy = cny

    if barDB.fadeEnabled then
        local _, cny2 = W.CreateSlider(contentFrame, L["opt_bar_fade_out_alpha"],
            (barDB.fadeOutAlpha or 0) * 100, 0, 100, 5, cy, function(v)
                SetBarVal(id, "fadeOutAlpha", v / 100)
            end, "%.0f%%")
        cy = cny2

        local _, cny2 = W.CreateSlider(contentFrame, L["opt_bar_fade_out_delay"],
            barDB.fadeOutDelay or 0.5, 0, 3, 0.1, cy, function(v)
                SetBarVal(id, "fadeOutDelay", v)
            end, "%.1fs")
        cy = cny2

        local _, cny2 = W.CreateSlider(contentFrame, L["opt_bar_fade_out_dur"],
            barDB.fadeOutDuration or 0.3, 0.05, 1, 0.05, cy, function(v)
                SetBarVal(id, "fadeOutDuration", v)
            end, "%.2fs")
        cy = cny2

        local _, cny2 = W.CreateSlider(contentFrame, L["opt_bar_fade_in_dur"],
            barDB.fadeInDuration or 0.2, 0.05, 1, 0.05, cy, function(v)
                SetBarVal(id, "fadeInDuration", v)
            end, "%.2fs")
        cy = cny2
    end

    -- Click-through
    local _, cny = W.CreateCheckbox(contentFrame, L["opt_bar_click_through"], barDB.clickThrough or false, cy, function(v)
        SetBarVal(id, "clickThrough", v)
    end)
    cy = cny

    -- Show empty buttons
    local _, cny = W.CreateCheckbox(contentFrame, L["opt_bar_show_empty"], barDB.showEmptyButtons or false, cy, function(v)
        SetBarVal(id, "showEmptyButtons", v)
    end)
    cy = cny

    -- Show hotkey text
    local _, cny = W.CreateCheckbox(contentFrame, L["opt_bar_show_hotkey"], barDB.showHotkeyText ~= false, cy, function(v)
        SetBarVal(id, "showHotkeyText", v)
    end)
    cy = cny

    -- Hotkey font size
    local _, cny = W.CreateSlider(contentFrame, L["opt_bar_hotkey_size"],
        barDB.hotkeyFontSize or 14, 8, 24, 1, cy, function(v)
            SetBarVal(id, "hotkeyFontSize", v)
        end, "%d")
    cy = cny

    -- Uniformiser : copier les réglages de CETTE barre vers toutes les autres
    local _, cny = W.CreateButton(contentFrame, L["btn_bar_uniformize"], 320, cy, function()
        StaticPopup_Show("TOMOMOD_AB_UNIFORMIZE", GetBarDisplayName(id), nil, { id = id })
    end)
    cy = cny

    local _, cny = W.CreateInfoText(contentFrame, L["info_bar_uniformize"], cy)
    cy = cny

    return math.abs(cy) + 10
end

local function BuildManagementTab(parent)
    local AB = TomoMod_ActionBars
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_bar_management"], y)
    y = ny

    -- Layout mode button
    local _, ny = W.CreateButton(c, L["btn_abs_layout"], 260, y, function()
        if TomoMod_Movers and TomoMod_Movers.Toggle then
            TomoMod_Movers.Toggle()
        end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_abs_layout"], y)
    y = ny

    -- Extra Action Button (single secure frame, managed apart from BAR_DEFS)
    do
        if not TomoModDB.actionBars then TomoModDB.actionBars = {} end
        if not TomoModDB.actionBars.bars then TomoModDB.actionBars.bars = {} end
        if not TomoModDB.actionBars.bars.extra then TomoModDB.actionBars.bars.extra = {} end
        local exDB = (AB and AB.GetBarDB) and AB.GetBarDB("extra") or TomoModDB.actionBars.bars.extra

        local function SetExtra(key, val)
            TomoModDB.actionBars.bars.extra[key] = val
            if AB and AB.ApplyExtra then AB.ApplyExtra() end
        end

        local _, ny = W.CreateSectionHeader(c, L["section_extra_button"], y)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_extra_enabled"],
            exDB.enabled ~= false, y, function(v)
                SetExtra("enabled", v)
            end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_extra_scale"],
            (exDB.scale or 1) * 100, 50, 200, 5, y, function(v)
                SetExtra("scale", v / 100)
            end, "%.0f%%")
        y = ny

        local _, ny = W.CreateButton(c, L["btn_extra_reset_pos"], 220, y, function()
            if AB and AB.ResetExtraPosition then AB.ResetExtraPosition() end
        end)
        y = ny

        local _, ny = W.CreateInfoText(c, L["info_extra_button"], y)
        y = ny
    end

    local defs = (AB and AB.BAR_DEFS) or {}
    if not TomoModDB.actionBars then TomoModDB.actionBars = {} end
    if not TomoModDB.actionBars.bars then TomoModDB.actionBars.bars = {} end

    -- We collect all section data to allow re-layout on expand/collapse
    local sections = {}

    for idx, def in ipairs(defs) do
        local id = def.id
        local barDB = (AB and AB.GetBarDB) and AB.GetBarDB(id) or (TomoModDB.actionBars.bars[id] or {})
        local displayName = GetBarDisplayName(id)

        -- Header button
        local header = CreateFrame("Button", nil, c, "BackdropTemplate")
        header:SetHeight(HEADER_H)
        header:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        header:SetBackdropColor(0.09, 0.09, 0.11, 1)
        header:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

        -- Arrow indicator (texture, not font — Poppins lacks Unicode arrows)
        local arrow = header:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(12, 12)
        arrow:SetPoint("LEFT", 10, 0)
        arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
        arrow:SetVertexColor(ACCENT_R, ACCENT_G, ACCENT_B, 1)

        -- Bar name
        local nameTxt = header:CreateFontString(nil, "OVERLAY")
        nameTxt:SetFont(FONT_SEMI, 11, "")
        nameTxt:SetPoint("LEFT", 26, 0)
        nameTxt:SetTextColor(0.80, 0.82, 0.81, 1)
        nameTxt:SetText(displayName)

        -- Summary badge (shown when collapsed)
        local summary = header:CreateFontString(nil, "OVERLAY")
        summary:SetFont(FONT_MEDIUM, 9, "")
        summary:SetPoint("RIGHT", -10, 0)
        summary:SetTextColor(0.45, 0.45, 0.50, 1)

        local function UpdateSummary()
            local parts = {}
            parts[#parts + 1] = (barDB.columns or 12) .. " col"
            parts[#parts + 1] = (barDB.buttonSize or 36) .. "px"
            parts[#parts + 1] = string.format("%.0f%%", (barDB.alpha or 1) * 100)
            if barDB.fadeEnabled then parts[#parts + 1] = "|cff8888ccFade|r" end
            if barDB.clickThrough then parts[#parts + 1] = "|cffcc8844CT|r" end
            if barDB.enabled == false then
                summary:SetText("|cff666666" .. L["opt_bar_disabled"] .. "|r")
            else
                summary:SetText(table.concat(parts, "  "))
            end
        end
        UpdateSummary()

        -- Hover effect
        header:SetScript("OnEnter", function()
            header:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B, 0.5)
        end)
        header:SetScript("OnLeave", function()
            header:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)
        end)

        -- Content frame (starts hidden)
        local content = CreateFrame("Frame", nil, c, "BackdropTemplate")
        content:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        content:SetBackdropColor(0.07, 0.07, 0.09, 1)
        content:SetBackdropBorderColor(0.15, 0.15, 0.18, 0.6)
        content:Hide()

        -- Build content widgets
        local contentH = BuildBarContent(content, id, barDB)
        content:SetHeight(contentH)

        local section = {
            header    = header,
            content   = content,
            contentH  = contentH,
            arrow     = arrow,
            summary   = summary,
            expanded  = false,
            updateSummary = UpdateSummary,
        }
        sections[#sections + 1] = section

        -- Layout function: repositions all sections from the fixed baseY
        -- (defined after the loop, attached via closure)
    end

    -- Fixed base Y after the header/info elements
    local baseY = y

    -- Re-layout all sections vertically
    local function Relayout()
        local py = baseY
        for _, sec in ipairs(sections) do
            sec.header:ClearAllPoints()
            sec.header:SetPoint("TOPLEFT", 8, py)
            sec.header:SetPoint("TOPRIGHT", -8, py)
            py = py - HEADER_H

            if sec.expanded then
                sec.content:ClearAllPoints()
                sec.content:SetPoint("TOPLEFT", 8, py)
                sec.content:SetPoint("TOPRIGHT", -8, py)
                sec.content:SetHeight(sec.contentH)
                sec.content:Show()
                py = py - sec.contentH
            else
                sec.content:Hide()
            end
            py = py - HEADER_GAP

            sec.arrow:SetRotation(sec.expanded and (math.pi / 2) or 0)
            sec.summary:SetShown(not sec.expanded)
        end
        c:SetHeight(math.abs(py) + 40)
        if scroll.UpdateScroll then scroll.UpdateScroll() end
    end

    -- Wire up click handlers
    for _, sec in ipairs(sections) do
        sec.header:SetScript("OnClick", function()
            sec.expanded = not sec.expanded
            sec.updateSummary()
            Relayout()
        end)
    end

    Relayout()
    return scroll
end

-- =====================================================================
-- MAIN PANEL
-- =====================================================================
function TomoMod_ConfigPanel_ActionBars(parent)
    return W.CreateTabPanel(parent, {
        { key = "skin",    label = L["tab_abs_skin"],    builder = BuildSkinTab },
        { key = "buttons", label = L["tab_abs_buttons"], builder = BuildButtonsTab },
        { key = "glow",    label = L["tab_abs_glow"],    builder = BuildGlowTab },
        { key = "hotkeys", label = L["tab_abs_hotkeys"], builder = BuildHotkeyTab },
        { key = "bars",    label = L["tab_abs_bars"],    builder = BuildManagementTab },
    })
end

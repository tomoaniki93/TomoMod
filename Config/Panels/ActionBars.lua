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
-- TAB 1 — SKIN STYLE
-- =====================================================================
local function BuildSkinTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_action_bars"] or "Action Bar Skin", y)
    y = ny

    if not TomoModDB.actionBarSkin then TomoModDB.actionBarSkin = {} end

    local _, ny = W.CreateCheckbox(c, L["opt_abs_enable"] or "Activer le skin", TomoModDB.actionBarSkin.enabled, y, function(v)
        TomoModDB.actionBarSkin.enabled = v
        if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.SetEnabled(v) end
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_abs_style"] or "Style visuel", SKIN_STYLES_LIST,
        TomoModDB.actionBarSkin.skinStyle or "classic", y, function(v)
            TomoModDB.actionBarSkin.skinStyle = v
            if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.Reskin() end
        end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_abs_class_color"] or "Couleur de bordure = couleur de classe",
        TomoModDB.actionBarSkin.useClassColor, y, function(v)
            TomoModDB.actionBarSkin.useClassColor = v
            if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.UpdateColors() end
        end)
    y = ny

    -- Shift reveal (now on actionBars)
    if not TomoModDB.actionBars then TomoModDB.actionBars = {} end
    local _, ny = W.CreateCheckbox(c, L["opt_abs_shift_reveal"] or "Maintenir Shift pour voir les barres cachees",
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
-- TAB 2 — BAR MANAGEMENT (collapsible per-bar sections)
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

-- Accent color helper
local ACCENT_R, ACCENT_G, ACCENT_B = 0.047, 0.824, 0.624
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
        { key = "skin",  label = L["tab_abs_skin"] or "Skin des boutons", builder = BuildSkinTab },
        { key = "bars",  label = L["tab_abs_bars"] or "Gestion des barres", builder = BuildManagementTab },
    })
end

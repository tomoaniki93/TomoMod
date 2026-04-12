-- =====================================
-- Config/Panels/ActionBars.lua v3.0.0
-- Action bars: Skin style + per-bar management via tabs
-- =====================================

local L = TomoMod_L
local W = TomoMod_Widgets

-- Bar list for skin opacity tab (matches ActionBarSkin BAR_DEFS barKeys)
local BAR_LIST = {
    { value = "ActionButton",          text = "Action Bar 1" },
    { value = "MultiBarBottomLeft",    text = "Action Bar 2 (BL)" },
    { value = "MultiBarBottomRight",   text = "Action Bar 3 (BR)" },
    { value = "MultiBarRight",         text = "Action Bar 4 (Right)" },
    { value = "MultiBarLeft",          text = "Action Bar 5 (Left)" },
    { value = "MultiBar5",             text = "Action Bar 6" },
    { value = "MultiBar6",             text = "Action Bar 7" },
    { value = "MultiBar7",             text = "Action Bar 8" },
    { value = "PetActionButton",       text = "Pet Bar" },
    { value = "StanceButton",          text = "Stance Bar" },
}

-- Bar management list (matches ActionBars.lua BAR_DEFS ids/names)
local BARS_MGT = {
    { id = "bar1",   name = "Action Bar 1" },
    { id = "bar2",   name = "Action Bar 2 (BL)" },
    { id = "bar3",   name = "Action Bar 3 (BR)" },
    { id = "bar4",   name = "Action Bar 4 (Right)" },
    { id = "bar5",   name = "Action Bar 5 (Left)" },
    { id = "bar6",   name = "Action Bar 6" },
    { id = "bar7",   name = "Action Bar 7" },
    { id = "bar8",   name = "Action Bar 8" },
    { id = "pet",    name = "Pet Bar" },
    { id = "stance", name = "Stance Bar" },
}

local SKIN_STYLES_LIST = {
    { value = "classic",  text = "Classic (9-slice)" },
    { value = "flat",     text = "Flat" },
    { value = "outlined", text = "Outlined" },
    { value = "glass",    text = "Glass" },
    { value = "minimal",  text = "Minimal (sans bordure)" },
}

-- =====================================================================
-- TAB 1 — SKIN STYLE
-- =====================================================================
local function BuildSkinTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    -- ===== Skin Enable =====
    local _, ny = W.CreateSectionHeader(c, L["section_action_bars"] or "Action Bar Skin", y)
    y = ny

    if not TomoModDB.actionBarSkin then TomoModDB.actionBarSkin = {} end

    local _, ny = W.CreateCheckbox(c, L["opt_abs_enable"] or "Activer le skin", TomoModDB.actionBarSkin.enabled, y, function(v)
        TomoModDB.actionBarSkin.enabled = v
        if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.SetEnabled(v) end
    end)
    y = ny

    -- ===== Skin Style dropdown =====
    local _, ny = W.CreateDropdown(c, L["opt_abs_style"] or "Style visuel", SKIN_STYLES_LIST,
        TomoModDB.actionBarSkin.skinStyle or "classic", y, function(v)
            TomoModDB.actionBarSkin.skinStyle = v
            if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.Reskin() end
        end)
    y = ny

    -- ===== Color options =====
    local _, ny = W.CreateCheckbox(c, L["opt_abs_class_color"] or "Couleur de bordure = couleur de classe",
        TomoModDB.actionBarSkin.useClassColor, y, function(v)
            TomoModDB.actionBarSkin.useClassColor = v
            if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.UpdateColors() end
        end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_abs_shift_reveal"] or "Maintenir Shift pour voir les barres cachées",
        TomoModDB.actionBarSkin.shiftReveal or false, y, function(v)
            TomoModDB.actionBarSkin.shiftReveal = v
            if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.SetShiftReveal(v) end
        end)
    y = ny

    -- ===== Per-Bar Opacity =====
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSectionHeader(c, L["section_bar_opacity"] or "Opacité par barre", y)
    y = ny

    if not TomoModDB.actionBarSkin.barOpacity then TomoModDB.actionBarSkin.barOpacity = {} end
    if not TomoModDB.actionBarSkin.combatShow  then TomoModDB.actionBarSkin.combatShow  = {} end

    local selectedBar = BAR_LIST[1].value
    local opacitySlider
    local combatCheck

    local _, ny = W.CreateDropdown(c, L["opt_abs_bar_select"] or "Barre à configurer", BAR_LIST, selectedBar, y, function(barKey)
        selectedBar = barKey
        if opacitySlider then
            opacitySlider:SetValue(TomoModDB.actionBarSkin.barOpacity[barKey] or 100)
        end
        if combatCheck then
            combatCheck:SetChecked(TomoModDB.actionBarSkin.combatShow[barKey] or false)
        end
    end)
    y = ny

    local sl, ny = W.CreateSlider(c, L["opt_abs_opacity"] or "Opacité", TomoModDB.actionBarSkin.barOpacity[selectedBar] or 100,
        0, 100, 5, y, function(v)
            TomoModDB.actionBarSkin.barOpacity[selectedBar] = v
            if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.ApplyBarOpacity(selectedBar, v) end
        end, "%d%%")
    y = ny
    opacitySlider = sl

    -- Apply all
    local _, ny = W.CreateButton(c, L["btn_abs_apply_all"] or "Appliquer à toutes les barres", 260, y, function()
        local val = opacitySlider:GetValue()
        for _, bar in ipairs(BAR_LIST) do
            TomoModDB.actionBarSkin.barOpacity[bar.value] = val
            if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.ApplyBarOpacity(bar.value, val) end
        end
    end)
    y = ny

    -- ===== Combat visibility =====
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["opt_abs_combat_only_label"] or "Affichage seulement en combat :", y)
    y = ny

    local cbF, ny = W.CreateCheckbox(c, L["opt_abs_combat_only"] or "Barre visible en combat seulement",
        TomoModDB.actionBarSkin.combatShow[selectedBar] or false, y, function(v)
            TomoModDB.actionBarSkin.combatShow[selectedBar] = v
            if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.ApplyCombatShow() end
        end)
    y = ny
    combatCheck = cbF

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================================================
-- TAB 2 — BAR MANAGEMENT
-- =====================================================================
local function BuildManagementTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_bar_management"] or "Gestion des barres d'action", y)
    y = ny

    -- Unlock / Lock all button
    local unlockBtn, ny = W.CreateButton(c, L["btn_abs_unlock"] or "Déverrouiller les barres", 240, y, function()
        if TomoMod_ActionBars then
            if TomoMod_ActionBars.IsUnlocked() then
                TomoMod_ActionBars.LockAll()
            else
                TomoMod_ActionBars.UnlockAll()
            end
        end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c,
        L["info_abs_unlock"] or "Déverrouillez les barres pour faire apparaître les poignées de déplacement.\nClic droit sur une poignée pour configurer une barre individuellement.", y)
    y = ny

    -- Per-bar quick settings cards
    local _, ny = W.CreateSectionHeader(c, L["section_bar_quick"] or "Paramètres rapides", y)
    y = ny

    if not TomoModDB.actionBars then TomoModDB.actionBars = { bars = {} } end
    TomoModDB.actionBars.bars = TomoModDB.actionBars.bars or {}

    for _, def in ipairs(BARS_MGT) do
        -- Ensure DB entry
        TomoModDB.actionBars.bars[def.id] = TomoModDB.actionBars.bars[def.id] or {}
        local db = TomoModDB.actionBars.bars[def.id]
        if db.alpha           == nil then db.alpha           = 1.0 end
        if db.scale           == nil then db.scale           = 1.0 end
        if db.fade            == nil then db.fade            = false end
        if db.showHotkey      == nil then db.showHotkey      = true end
        if db.showMacro       == nil then db.showMacro       = true end
        if db.showCount       == nil then db.showCount       = true end
        if db.clickThrough    == nil then db.clickThrough    = false end
        if db.displayCondition == nil then db.displayCondition = "" end

        -- Mini row: bar name + status indicators + config button
        local row = CreateFrame("Frame", nil, c, "BackdropTemplate")
        row:SetPoint("TOPLEFT", 8, y)
        row:SetPoint("TOPRIGHT", -8, y)
        row:SetHeight(54)
        row:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        row:SetBackdropColor(0.09, 0.09, 0.11, 1)
        row:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

        -- Bar name
        local nameLbl = row:CreateFontString(nil, "OVERLAY")
        nameLbl:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 11, "")
        nameLbl:SetPoint("LEFT", 10, 12)
        nameLbl:SetTextColor(0.80, 0.82, 0.81, 1)
        nameLbl:SetText(def.name)

        -- Status line: alpha + feature badges
        local statusLbl = row:CreateFontString(nil, "OVERLAY")
        statusLbl:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 9, "")
        statusLbl:SetPoint("LEFT", 10, -4)
        statusLbl:SetTextColor(0.35, 0.35, 0.40, 1)

        local statusParts = {}
        statusParts[#statusParts + 1] = string.format("Alpha: |cff0cd29f%.0f%%|r", (db.alpha or 1) * 100)
        if db.fade then statusParts[#statusParts + 1] = "|cff8888ccFade|r" end
        if db.clickThrough then statusParts[#statusParts + 1] = "|cffcc8844Click-through|r" end
        if db.displayCondition and db.displayCondition ~= "" then
            statusParts[#statusParts + 1] = "|cffcccc44Cond.|r"
        end
        statusLbl:SetText(table.concat(statusParts, "  "))

        -- Feature mini-toggle: Fade
        local fadeTag = row:CreateFontString(nil, "OVERLAY")
        fadeTag:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 8, "")
        fadeTag:SetPoint("LEFT", 10, -16)
        if db.fade then
            fadeTag:SetTextColor(0.047, 0.824, 0.624, 0.8)
            fadeTag:SetText("FADE ON")
        else
            fadeTag:SetTextColor(0.30, 0.30, 0.35, 0.6)
            fadeTag:SetText("FADE OFF")
        end

        -- Config button (opens BarEditor)
        local barId = def.id
        local cfgBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        cfgBtn:SetSize(22, 22)
        cfgBtn:SetPoint("RIGHT", -8, 0)
        cfgBtn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        cfgBtn:SetBackdropColor(0.06, 0.06, 0.08, 1)
        cfgBtn:SetBackdropBorderColor(0.22, 0.22, 0.26, 1)
        local cfgTxt = cfgBtn:CreateFontString(nil, "OVERLAY")
        cfgTxt:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 13, "")
        cfgTxt:SetPoint("CENTER", 0, 1)
        cfgTxt:SetText(">")
        cfgTxt:SetTextColor(0.50, 0.50, 0.55, 1)
        cfgBtn:SetScript("OnEnter", function()
            cfgBtn:SetBackdropBorderColor(0.047, 0.824, 0.624, 0.80)
            cfgTxt:SetTextColor(0.047, 0.824, 0.624, 1)
        end)
        cfgBtn:SetScript("OnLeave", function()
            cfgBtn:SetBackdropBorderColor(0.22, 0.22, 0.26, 1)
            cfgTxt:SetTextColor(0.50, 0.50, 0.55, 1)
        end)
        cfgBtn:SetScript("OnClick", function()
            if TomoMod_ActionBars then
                local bar = TomoMod_ActionBars.GetBar(barId)
                if bar then TomoMod_ActionBars.ShowBarEditor(bar) end
            end
        end)

        y = y - 60
    end

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================================================
-- MAIN PANEL (TabPanel wrapper)
-- =====================================================================
function TomoMod_ConfigPanel_ActionBars(parent)
    return W.CreateTabPanel(parent, {
        { key = "skin",  label = L["tab_abs_skin"] or "Skin des boutons", builder = BuildSkinTab },
        { key = "bars",  label = L["tab_abs_bars"] or "Gestion des barres", builder = BuildManagementTab },
    })
end

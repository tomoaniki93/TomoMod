-- Panels/Nameplates.lua v2.7.0 — Cards + 2-col layout
local W = TomoMod_Widgets
local L = TomoMod_L

local function T(key, fallback)
    local value = L and L[key]
    if value and value ~= key then return value end
    return fallback or key
end

local function RefreshPreview()
    if TomoMod_NameplatesPreviewRefresh then
        TomoMod_NameplatesPreviewRefresh()
    end
end

local function RefreshNP()
    if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
    RefreshPreview()
end

local function ApplyNP()
    if TomoMod_Nameplates then TomoMod_Nameplates.ApplySettings() end
    RefreshPreview()
end
local WHITE = "Interface\\Buttons\\WHITE8x8"

local function CreateNameplatePreview(parent, y, db)
    local card, cy = W.CreateCard(parent, T("np_preview_title", "Aperçu des plaques"), y)

    local stage = CreateFrame("Frame", nil, card.inner, "BackdropTemplate")
    stage:SetPoint("TOPLEFT", 16, cy)
    stage:SetPoint("TOPRIGHT", -16, cy)
    stage:SetHeight(166)
    stage:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    stage:SetBackdropColor(0.030, 0.034, 0.044, 0.98)
    stage:SetBackdropBorderColor(0.38, 0.88, 0.72, 0.28)
    -- Hard guard: clip every preview element to the stage so a large bar
    -- size can never spill outside the card.
    if stage.SetClipsChildren then stage:SetClipsChildren(true) end

    local wash = stage:CreateTexture(nil, "BACKGROUND", nil, -1)
    wash:SetAllPoints()
    if wash.SetGradientAlpha then
        wash:SetGradientAlpha("HORIZONTAL", 0.04, 0.55, 0.42, 0.18, 0.08, 0.02, 0.18, 0.05)
    else
        wash:SetColorTexture(0.04, 0.55, 0.42, 0.10)
    end

    local function GetPreviewSize()
        return math.max(120, math.min(300, db.width or 170)),
               math.max(8, math.min(24, db.height or 12))
    end

    local previewW, previewH = GetPreviewSize()
    local previewPlates = {}

    local function CreatePlate(label, value, x, yOff, w, h, r, g, b, hostile)
        local plate = CreateFrame("Frame", nil, stage, "BackdropTemplate")
        plate:SetPoint("TOPLEFT", x, yOff)
        plate:SetSize(w, h + 20)
        plate:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
        plate:SetBackdropColor(0.020, 0.022, 0.030, 0.88)
        plate:SetBackdropBorderColor(r, g, b, hostile and 0.70 or 0.45)

        local name = plate:CreateFontString(nil, "OVERLAY")
        name:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf", 9, "OUTLINE")
        name:SetPoint("BOTTOMLEFT", plate, "TOPLEFT", 1, 2)
        name:SetText(label)
        name:SetTextColor(r, g, b, 1)

        local hp = CreateFrame("StatusBar", nil, plate)
        hp:SetPoint("TOPLEFT", 3, -4)
        hp:SetPoint("TOPRIGHT", -3, -4)
        hp:SetHeight(h)
        hp:SetStatusBarTexture(WHITE)
        hp:SetMinMaxValues(0, 100)
        hp:SetValue(value)
        hp:SetStatusBarColor(r, g, b, 0.95)
        plate._hp = hp

        local hpBg = hp:CreateTexture(nil, "BACKGROUND")
        hpBg:SetAllPoints()
        hpBg:SetColorTexture(r * 0.12, g * 0.12, b * 0.12, 1)

        local pct = hp:CreateFontString(nil, "OVERLAY")
        pct:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 8, "OUTLINE")
        pct:SetPoint("RIGHT", -4, 0)
        pct:SetText(value .. "%")
        pct:SetTextColor(1, 1, 1, 0.82)
        plate._pct = pct

        local cast = CreateFrame("StatusBar", nil, plate)
        cast:SetPoint("TOPLEFT", hp, "BOTTOMLEFT", 0, -3)
        cast:SetPoint("TOPRIGHT", hp, "BOTTOMRIGHT", 0, -3)
        cast:SetHeight(5)
        cast:SetStatusBarTexture(WHITE)
        cast:SetMinMaxValues(0, 100)
        cast:SetValue(hostile and 68 or 0)
        cast:SetStatusBarColor(0.95, 0.58, 0.20, hostile and 0.90 or 0)

        local castBg = cast:CreateTexture(nil, "BACKGROUND")
        castBg:SetAllPoints()
        castBg:SetColorTexture(0.16, 0.10, 0.04, hostile and 0.80 or 0.25)
        plate._cast = cast
        plate._name = name
        plate._previewAddW = w - previewW
        plate._previewAddH = h - previewH
        plate._previewValue = value
        plate._previewSlot = #previewPlates + 1
        plate._previewY = yOff
        previewPlates[#previewPlates + 1] = plate

        for i = 1, hostile and 4 or 2 do
            local dot = plate:CreateTexture(nil, "OVERLAY")
            dot:SetSize(7, 7)
            dot:SetPoint("TOPLEFT", plate, "BOTTOMLEFT", 4 + (i - 1) * 9, -4)
            if i == 1 then dot:SetColorTexture(0.82, 0.18, 0.22, 0.92)
            elseif i == 2 then dot:SetColorTexture(0.55, 0.24, 0.90, 0.92)
            elseif i == 3 then dot:SetColorTexture(0.22, 0.56, 0.95, 0.92)
            else dot:SetColorTexture(0.25, 0.78, 0.34, 0.92) end
        end
    end

    CreatePlate(T("preview_np_friendly", "Allié"), 92, 22, -34, previewW, previewH, 0.38, 0.88, 0.72, false)
    CreatePlate(T("preview_np_target", "Cible hostile"), 48, 290, -30, previewW + 28, previewH + 2, 0.95, 0.35, 0.28, true)
    CreatePlate(T("preview_np_boss", "Boss marqué"), 71, 560, -34, previewW + 18, previewH, 0.96, 0.70, 0.26, true)

    local hint = stage:CreateFontString(nil, "OVERLAY")
    hint:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 9, "")
    hint:SetPoint("TOPLEFT", 18, -8)
    hint:SetText(T("np_preview_hint", "Lisibilité rapide : couleur, cast, auras et menace au même endroit."))
    hint:SetTextColor(0.56, 0.58, 0.65, 1)

    TomoMod_NameplatesPreviewRefresh = function()
        if not stage or not stage:IsShown() then return end
        local stageW = stage:GetWidth() or 0
        if stageW < 120 then
            -- Width not computed yet: derive it from the card (stage is inset
            -- 16px on each side) rather than guessing, so we never lay out
            -- against a width wider than the actual card.
            local innerW = card.inner and card.inner:GetWidth() or 0
            stageW = innerW > 52 and (innerW - 32) or 0
        end
        if stageW < 120 then return end  -- still unknown; OnSizeChanged will re-run
        local margin = 20
        local gap = 18
        local colW = math.max(120, math.floor((stageW - margin * 2 - gap) / 2))
        local fullW = math.max(120, stageW - margin * 2)
        local w, h = GetPreviewSize()
        local castH = math.max(3, math.min(14, db.castbarHeight or 5))
        for _, plate in ipairs(previewPlates) do
            local slot = plate._previewSlot or 1
            local maxW = slot == 3 and fullW or colW
            local plateW = math.min(w + (plate._previewAddW or 0), maxW)
            local plateH = h + (plate._previewAddH or 0)
            local x
            local y = -48
            if slot == 1 then
                x = margin
            elseif slot == 2 then
                x = margin + colW + gap
            else
                x = margin + math.max(0, math.floor((fullW - plateW) / 2))
                y = -108
            end
            -- Final safety: never let a plate cross the right edge of the stage,
            -- whatever the slot math or bar size produced.
            local maxRight = stageW - margin
            if x + plateW > maxRight then
                plateW = math.max(40, maxRight - x)
            end
            plate:ClearAllPoints()
            plate:SetPoint("TOPLEFT", stage, "TOPLEFT", x, y)
            plate:SetSize(plateW, plateH + 20)
            if plate._hp then plate._hp:SetHeight(plateH) end
            if plate._cast then
                plate._cast:SetHeight(castH)
                plate._cast:SetShown(db.showCastbar ~= false)
            end
            if plate._name then
                plate._name:SetShown(db.showName ~= false)
                plate._name:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf", db.nameFontSize or 9, "OUTLINE")
            end
            if plate._pct then plate._pct:SetText((plate._previewValue or 0) .. "%") end
        end
    end
    stage:SetScript("OnSizeChanged", function()
        if TomoMod_NameplatesPreviewRefresh then TomoMod_NameplatesPreviewRefresh() end
    end)
    TomoMod_NameplatesPreviewRefresh()

    cy = cy - 178
    return W.FinalizeCard(card, cy)
end

-- ══════════════════════════════════════════════
-- TAB 1 : GÉNÉRAL
-- ══════════════════════════════════════════════
local function BuildGeneralTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.nameplates
    local y = -12

    y = CreateNameplatePreview(c, y, db)

    -- Activation
    local card, cy = W.CreateCard(c, L["section_np_general"] or "Activation", y)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_np_enable"] or "Activer", db.enabled, cy, function(v)
        db.enabled = v
        if TomoMod_Nameplates then if v then TomoMod_Nameplates.Enable() else TomoMod_Nameplates.Disable() end end
        StaticPopup_Show("TOMOMOD_MODULE_RELOAD")
    end)
    local _, cy = W.CreateInfoText(card.inner, L["info_module_reload"] or "", cy)
    local _, cy = W.CreateInfoText(card.inner, L["info_np_description"] or "", cy)
    y = W.FinalizeCard(card, cy)

    -- Dimensions
    local card2, cy = W.CreateCard(c, L["section_dimensions"] or "Dimensions", y)
    local _, cy = W.CreateTwoColumnRow(card2.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_width"] or "Largeur", db.width, 60, 300, 5, 0, function(v) db.width = v; RefreshNP() end) return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_health_height"] or "Hauteur HP", db.height, 6, 40, 1, 0, function(v) db.height = v; RefreshNP() end) return ny end)
    local _, cy = W.CreateSlider(card2.inner, L["opt_np_name_font_size"] or "Taille police nom", db.nameFontSize or 10, 6, 20, 1, cy, function(v) db.nameFontSize = v; RefreshNP() end)
    y = W.FinalizeCard(card2, cy)

    -- Affichage
    local card3, cy = W.CreateCard(c, L["section_display"] or "Affichage", y)
    local _, cy = W.CreateCheckboxPair(card3.inner, L["opt_show_name"] or "Nom", db.showName, cy, function(v) db.showName = v; RefreshNP() end,
        L["opt_show_level"] or "Niveau", db.showLevel, function(v) db.showLevel = v; RefreshNP() end)
    local _, cy = W.CreateCheckboxPair(card3.inner, L["opt_show_health_text"] or "Texte HP", db.showHealthText, cy, function(v) db.showHealthText = v; RefreshNP() end,
        L["opt_np_show_classification"] or "Classification", db.showClassification, function(v) db.showClassification = v; RefreshNP() end)
    local _, cy = W.CreateCheckboxPair(card3.inner, L["opt_show_threat"] or "Menace", db.showThreat, cy, function(v) db.showThreat = v; RefreshNP() end,
        L["opt_np_class_colors"] or "Couleurs de classe", db.useClassColors, function(v) db.useClassColors = v; RefreshNP() end)
    local _, cy = W.CreateCheckboxPair(card3.inner, L["opt_np_show_absorb"] or "Absorb", db.showAbsorb ~= false, cy, function(v) db.showAbsorb = v; RefreshNP() end,
        L["opt_np_friendly_name_only"] or "Alliés : nom uniquement", db.friendlyNameOnly ~= false, function(v) db.friendlyNameOnly = v; RefreshNP() end)
    local _, cy = W.CreateDropdown(card3.inner, L["opt_health_format"] or "Format HP", {
        { text = L["np_fmt_percent"]         or "%", value = "percent" },
        { text = L["np_fmt_current"]         or "Valeur", value = "current" },
        { text = L["np_fmt_current_percent"] or "Valeur + %", value = "current_percent" },
    }, db.healthTextFormat or "percent", cy, function(v) db.healthTextFormat = v; RefreshNP() end)
    y = W.FinalizeCard(card3, cy)

    -- Icônes de rôle
    local card4, cy = W.CreateCard(c, L["opt_np_friendly_role_icons"] or "Icônes de rôle", y)
    local _, cy = W.CreateCheckbox(card4.inner, L["opt_np_friendly_role_icons"] or "Afficher les icônes de rôle", db.friendlyRoleIcons ~= false, cy, function(v) db.friendlyRoleIcons = v; RefreshNP() end)
    local _, cy = W.CreateCheckboxPair(card4.inner, L["opt_np_role_show_tank"] or "Tank", db.roleShowTank ~= false, cy, function(v) db.roleShowTank = v; RefreshNP() end,
        L["opt_np_role_show_healer"] or "Healeur", db.roleShowHealer ~= false, function(v) db.roleShowHealer = v; RefreshNP() end)
    local _, cy = W.CreateCheckbox(card4.inner, L["opt_np_role_show_dps"] or "DPS", db.roleShowDps ~= false, cy, function(v) db.roleShowDps = v; RefreshNP() end)
    local _, cy = W.CreateSlider(card4.inner, L["opt_np_role_icon_size"] or "Taille icône", db.roleIconSize or 32, 16, 60, 2, cy, function(v) db.roleIconSize = v; RefreshNP() end)
    y = W.FinalizeCard(card4, cy)

    -- Marqueur de raid
    local card5, cy = W.CreateCard(c, L["section_raid_marker"] or "Marqueur de raid", y)
    local _, cy = W.CreateDropdown(card5.inner, L["opt_np_raid_icon_anchor"] or "Ancre", {
        { text = "Top",    value = "TOP" }, { text = "TopRight", value = "TOPRIGHT" }, { text = "TopLeft", value = "TOPLEFT" },
        { text = "Bottom", value = "BOTTOM" }, { text = "BottomRight", value = "BOTTOMRIGHT" }, { text = "BottomLeft", value = "BOTTOMLEFT" },
        { text = "Left",   value = "LEFT" }, { text = "Right", value = "RIGHT" }, { text = "Center", value = "CENTER" },
    }, db.raidIconAnchor or "TOPRIGHT", cy, function(v) db.raidIconAnchor = v; RefreshNP() end)
    local _, cy = W.CreateTwoColumnRow(card5.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, "X", db.raidIconX or 2, -50, 50, 1, 0, function(v) db.raidIconX = v; RefreshNP() end) return ny end,
        function(col) local _, ny = W.CreateSlider(col, "Y", db.raidIconY or 2, -50, 50, 1, 0, function(v) db.raidIconY = v; RefreshNP() end) return ny end)
    local _, cy = W.CreateSlider(card5.inner, L["opt_np_raid_icon_size"] or "Taille", db.raidIconSize or 24, 10, 60, 1, cy, function(v) db.raidIconSize = v; RefreshNP() end)
    y = W.FinalizeCard(card5, cy)

    -- Castbar
    local card6, cy = W.CreateCard(c, L["section_castbar"] or "Barre de cast", y)
    local _, cy = W.CreateCheckbox(card6.inner, L["opt_np_show_castbar"] or "Afficher la castbar", db.showCastbar, cy, function(v) db.showCastbar = v; RefreshNP() end)
    local _, cy = W.CreateSlider(card6.inner, L["opt_np_castbar_height"] or "Hauteur", db.castbarHeight, 4, 20, 1, cy, function(v) db.castbarHeight = v; RefreshNP() end)
    local _, cy = W.CreateColorPickerPair(card6.inner, L["color_castbar"] or "Interruptible", db.castbarColor, L["color_castbar_uninterruptible"] or "Non-interruptible", db.castbarUninterruptible, cy,
        function(r,g,b) db.castbarColor = {r=r,g=g,b=b}; RefreshNP() end,
        function(r,g,b) db.castbarUninterruptible = {r=r,g=g,b=b}; RefreshNP() end)
    y = W.FinalizeCard(card6, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- TAB 2 : AURAS
-- ══════════════════════════════════════════════
local function BuildAurasTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.nameplates
    local y = -12

    local card, cy = W.CreateCard(c, L["section_auras"] or "Debuffs", y)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_np_show_auras"] or "Afficher les auras", db.showAuras, cy, function(v) db.showAuras = v; RefreshNP() end)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_np_only_my_debuffs"] or "Seulement mes debuffs", db.showOnlyMyAuras, cy, function(v) db.showOnlyMyAuras = v; RefreshNP() end)
    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_np_aura_size"] or "Taille", db.auraSize, 12, 36, 1, 0, function(v) db.auraSize = v; RefreshNP() end) return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_np_max_auras"] or "Nb max", db.maxAuras, 1, 10, 1, 0, function(v) db.maxAuras = v; RefreshNP() end) return ny end)
    y = W.FinalizeCard(card, cy)

    local card2, cy = W.CreateCard(c, L["section_enemy_buffs"] or "Buffs ennemis", y)
    local _, cy = W.CreateCheckbox(card2.inner, L["opt_np_show_enemy_buffs"] or "Afficher les buffs ennemis", db.showEnemyBuffs, cy, function(v) db.showEnemyBuffs = v; RefreshNP() end)
    local _, cy = W.CreateTwoColumnRow(card2.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_np_enemy_buff_size"] or "Taille", db.enemyBuffSize or 18, 12, 36, 1, 0, function(v) db.enemyBuffSize = v; RefreshNP() end) return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_np_max_enemy_buffs"] or "Nb max", db.maxEnemyBuffs or 3, 1, 8, 1, 0, function(v) db.maxEnemyBuffs = v; RefreshNP() end) return ny end)
    local _, cy = W.CreateSlider(card2.inner, L["opt_np_enemy_buff_y_offset"] or "Offset Y", db.enemyBuffYOffset or 4, 0, 20, 1, cy, function(v) db.enemyBuffYOffset = v; RefreshNP() end)
    y = W.FinalizeCard(card2, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ══════════════════════════════════════════════
-- TAB 3 : AVANCÉ
-- ══════════════════════════════════════════════
local function BuildAdvancedTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.nameplates
    local y = -12

    -- Transparence
    local card, cy = W.CreateCard(c, L["section_transparency"] or "Transparence", y)
    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_np_selected_alpha"] or "Sélectionné", db.selectedAlpha, 0.3, 1.0, 0.05, 0, function(v) db.selectedAlpha = v end, "%.2f") return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_np_unselected_alpha"] or "Non-sélectionné", db.unselectedAlpha, 0.3, 1.0, 0.05, 0, function(v) db.unselectedAlpha = v end, "%.2f") return ny end)
    y = W.FinalizeCard(card, cy)

    -- Empilement
    local card2, cy = W.CreateCard(c, L["section_stacking"] or "Empilement", y)
    local _, cy = W.CreateTwoColumnRow(card2.inner, cy,
        function(col) local _, ny = W.CreateSlider(col, L["opt_np_overlap"] or "Chevauchement V", db.overlapV or 1.6, 0.5, 3.0, 0.1, 0, function(v) db.overlapV = v; ApplyNP() end, "%.1f") return ny end,
        function(col) local _, ny = W.CreateSlider(col, L["opt_np_top_inset"] or "Inset haut", db.topInset or 0.065, 0.01, 0.5, 0.005, 0, function(v) db.topInset = v; ApplyNP() end, "%.3f") return ny end)
    y = W.FinalizeCard(card2, cy)

    -- Couleurs générales
    local card3, cy = W.CreateCard(c, L["section_colors"] or "Couleurs", y)
    local _, cy = W.CreateInfoText(card3.inner, L["info_np_colors_custom"] or "", cy)
    local _, cy = W.CreateColorPickerPair(card3.inner, L["color_hostile"] or "Hostile", db.colors.hostile, L["color_neutral"] or "Neutre", db.colors.neutral, cy,
        function(r,g,b) db.colors.hostile = {r=r,g=g,b=b}; RefreshNP() end,
        function(r,g,b) db.colors.neutral = {r=r,g=g,b=b}; RefreshNP() end)
    local _, cy = W.CreateColorPickerPair(card3.inner, L["color_friendly"] or "Allié", db.colors.friendly, L["color_tapped"] or "Tapped", db.colors.tapped, cy,
        function(r,g,b) db.colors.friendly = {r=r,g=g,b=b}; RefreshNP() end,
        function(r,g,b) db.colors.tapped = {r=r,g=g,b=b}; RefreshNP() end)
    local _, cy = W.CreateColorPickerPair(card3.inner, L["color_focus"] or "Focus", db.colors.focus, L["color_caster"] or "Lanceur", db.colors.caster, cy,
        function(r,g,b) db.colors.focus = {r=r,g=g,b=b}; RefreshNP() end,
        function(r,g,b) db.colors.caster = {r=r,g=g,b=b}; RefreshNP() end)
    local _, cy = W.CreateColorPickerPair(card3.inner, L["color_miniboss"] or "Mini-boss", db.colors.miniboss, L["color_enemy_in_combat"] or "En combat", db.colors.enemyInCombat, cy,
        function(r,g,b) db.colors.miniboss = {r=r,g=g,b=b}; RefreshNP() end,
        function(r,g,b) db.colors.enemyInCombat = {r=r,g=g,b=b}; RefreshNP() end)
    y = W.FinalizeCard(card3, cy)

    -- Classification
    local card4, cy = W.CreateCard(c, L["section_classification_colors"] or "Couleurs de classification", y)
    local _, cy = W.CreateCheckbox(card4.inner, L["opt_np_use_classification"] or "Utiliser les couleurs de classification", db.useClassificationColors, cy, function(v) db.useClassificationColors = v; RefreshNP() end)
    local _, cy = W.CreateColorPickerPair(card4.inner, L["color_boss"] or "Boss", db.colors.boss, L["color_elite"] or "Élite", db.colors.elite, cy,
        function(r,g,b) db.colors.boss = {r=r,g=g,b=b}; RefreshNP() end,
        function(r,g,b) db.colors.elite = {r=r,g=g,b=b}; RefreshNP() end)
    local _, cy = W.CreateColorPickerPair(card4.inner, L["color_rare"] or "Rare", db.colors.rare, L["color_normal"] or "Normal", db.colors.normal, cy,
        function(r,g,b) db.colors.rare = {r=r,g=g,b=b}; RefreshNP() end,
        function(r,g,b) db.colors.normal = {r=r,g=g,b=b}; RefreshNP() end)
    local _, cy = W.CreateTwoColumnRow(card4.inner, cy,
        function(col) local _, ny = W.CreateColorPicker(col, L["color_trivial"] or "Trivial", db.colors.trivial, 0, function(r,g,b) db.colors.trivial = {r=r,g=g,b=b}; RefreshNP() end) return ny end,
        nil)
    y = W.FinalizeCard(card4, cy)

    -- Mode tank
    local card5, cy = W.CreateCard(c, L["section_tank_mode"] or "Mode Tank", y)
    local _, cy = W.CreateCheckbox(card5.inner, L["opt_np_tank_mode"] or "Activer le mode tank", db.tankMode, cy, function(v) db.tankMode = v; RefreshNP() end)
    local _, cy = W.CreateColorPickerPair(card5.inner, L["color_no_threat"] or "Pas de menace", db.tankColors.noThreat, L["color_low_threat"] or "Faible menace", db.tankColors.lowThreat, cy,
        function(r,g,b) db.tankColors.noThreat = {r=r,g=g,b=b} end,
        function(r,g,b) db.tankColors.lowThreat = {r=r,g=g,b=b} end)
    local _, cy = W.CreateColorPickerPair(card5.inner, L["color_has_threat"] or "Menace", db.tankColors.hasThreat, L["color_dps_has_aggro"] or "DPS aggro", db.tankColors.dpsHasAggro, cy,
        function(r,g,b) db.tankColors.hasThreat = {r=r,g=g,b=b} end,
        function(r,g,b) db.tankColors.dpsHasAggro = {r=r,g=g,b=b} end)
    local _, cy = W.CreateTwoColumnRow(card5.inner, cy,
        function(col) local _, ny = W.CreateColorPicker(col, L["color_dps_near_aggro"] or "DPS proche aggro", db.tankColors.dpsNearAggro, 0, function(r,g,b) db.tankColors.dpsNearAggro = {r=r,g=g,b=b} end) return ny end,
        nil)
    y = W.FinalizeCard(card5, cy)

    -- Reset
    local card6, cy = W.CreateCard(c, "", y)
    local _, cy = W.CreateButton(card6.inner, L["btn_reset_nameplates"] or "Réinitialiser les nameplates", 280, cy, function()
        if TomoMod_ResetModule then TomoMod_ResetModule("nameplates") end
        print("|cff2ed884TomoMod|r " .. (L["msg_np_reset"] or "Nameplates réinitialisées."))
    end)
    y = W.FinalizeCard(card6, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

function TomoMod_ConfigPanel_Nameplates(parent)
    return W.CreateTabPanel(parent, {
        { key = "general",  label = L["tab_general"]     or "Général",  builder = BuildGeneralTab  },
        { key = "auras",    label = L["tab_np_auras"]    or "Auras",    builder = BuildAurasTab    },
        { key = "advanced", label = L["tab_np_advanced"] or "Avancé",   builder = BuildAdvancedTab },
    })
end

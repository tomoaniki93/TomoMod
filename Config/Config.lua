-- =====================================
-- Config.lua
-- =====================================

TomoMod_Config = TomoMod_Config or {}

local configFrame
local currentTab = "QOL" -- Onglet par défaut

-- =====================================
-- FONCTIONS UTILITAIRES COLOR PICKER
-- =====================================
local function ShowColorPicker(r, g, b, callback)
    ColorPickerFrame.previousValues = {r, g, b}
    
    local function OnColorChanged()
        local newR, newG, newB = ColorPickerFrame:GetColorRGB()
        callback(newR, newG, newB)
    end
    
    local function OnCancel()
        local prev = ColorPickerFrame.previousValues
        callback(prev[1], prev[2], prev[3])
    end
    
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.func = OnColorChanged
    ColorPickerFrame.cancelFunc = OnCancel
    ColorPickerFrame:Hide()
    ColorPickerFrame:Show()
end

local function CreateColorButton(parent, x, y, initialColor, label, onColorChanged)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(250, 25)
    frame:SetPoint("TOPLEFT", x, y)
    
    local labelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("LEFT", 0, 0)
    labelText:SetText(label)
    
    local colorBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    colorBtn:SetSize(25, 20)
    colorBtn:SetPoint("LEFT", labelText, "RIGHT", 10, 0)
    colorBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    colorBtn:SetBackdropColor(initialColor[1], initialColor[2], initialColor[3], 1)
    colorBtn:SetBackdropBorderColor(0, 0, 0, 1)
    
    local rgbText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rgbText:SetPoint("LEFT", colorBtn, "RIGHT", 5, 0)
    rgbText:SetTextColor(0.7, 0.7, 0.7)
    
    local function UpdateRGBText(r, g, b)
        rgbText:SetText(string.format("(%d, %d, %d)", math.floor(r*255), math.floor(g*255), math.floor(b*255)))
    end
    UpdateRGBText(initialColor[1], initialColor[2], initialColor[3])
    
    colorBtn:SetScript("OnClick", function()
        local currentColor = {colorBtn:GetBackdropColor()}
        ShowColorPicker(currentColor[1], currentColor[2], currentColor[3], function(r, g, b)
            colorBtn:SetBackdropColor(r, g, b, 1)
            UpdateRGBText(r, g, b)
            if onColorChanged then
                onColorChanged(r, g, b)
            end
        end)
    end)
    
    frame.colorBtn = colorBtn
    frame.rgbText = rgbText
    
    return frame
end

-- =====================================
-- FONCTIONS DE CRÉATION DES ONGLETS
-- =====================================
-- Fonction pour créer un bouton d'onglet
local function CreateTabButton(parent, text, tabName, point, relativeTo, relativePoint, x, y)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn.tabName = tabName
    btn:SetSize(120, 30)
    btn:SetPoint(point, relativeTo, relativePoint, x, y)
    btn:SetText(text)
    
    btn:SetScript("OnClick", function(self)
        TomoMod_Config.SwitchTab(tabName)
    end)
    
    return btn
end

-- Fonction pour changer d'onglet
function TomoMod_Config.SwitchTab(tabName)
    currentTab = tabName
    
    -- Cacher tous les contenus
    if configFrame.qolContent then configFrame.qolContent:Hide() end
    if configFrame.skyrideContent then configFrame.skyrideContent:Hide() end
    if configFrame.combatInfoContent then configFrame.combatInfoContent:Hide() end
    if configFrame.uiContent then configFrame.uiContent:Hide() end
    
    -- Afficher le contenu sélectionné
    if tabName == "QOL" and configFrame.qolContent then
        configFrame.qolContent:Show()
    elseif tabName == "Skyride" and configFrame.skyrideContent then
        configFrame.skyrideContent:Show()
    elseif tabName == "CombatInfo" and configFrame.combatInfoContent then
        configFrame.combatInfoContent:Show()
    elseif tabName == "UI" and configFrame.uiContent then
        configFrame.uiContent:Show()
    end
    
    -- Mettre à jour l'apparence des boutons d'onglets
    for _, btn in ipairs(configFrame.tabs) do
        if btn.tabName == tabName then
            btn:Disable()
            btn:SetAlpha(1)
        else
            btn:Enable()
            btn:SetAlpha(0.6)
        end
    end
end

function TomoMod_Config.Create()
    if configFrame then return end
    
    configFrame = CreateFrame("Frame", "TomoModConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(520, 600)
    configFrame:SetPoint("CENTER")
    configFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    configFrame:Hide()
    
    -- Titre principal
    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("TomoMod - Configuration")
    
    -- Créer les onglets
    configFrame.tabs = {}
    
    local qolTab = CreateTabButton(configFrame, "QOL", "QOL", "TOPLEFT", 20, -45)
    table.insert(configFrame.tabs, qolTab)

    local skyrideTab = CreateTabButton(configFrame, "Skyride", "Skyride", "LEFT", qolTab, "RIGHT", 5, 0)
    table.insert(configFrame.tabs, skyrideTab)

    local combatInfoTab = CreateTabButton(configFrame, "CombatInfo", "CombatInfo", "TOPLEFT", configFrame, "TOPLEFT", 20, -80)
    table.insert(configFrame.tabs, combatInfoTab)

    local uiTab = CreateTabButton(configFrame, "UI", "UI", "LEFT", skyrideTab, "RIGHT", 5, 0)
    table.insert(configFrame.tabs, uiTab)
    
    -- Ligne de séparation sous les onglets
    local separator = configFrame:CreateTexture(nil, "ARTWORK")
    separator:SetSize(480, 2)
    separator:SetPoint("TOPLEFT", 20, -80)
    separator:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    -- ========================================
    -- CONTENU QOL
    -- ========================================
    TomoMod_Config.CreateQOLContent()

    -- ========================================
    -- CONTENU Skyride
    -- ========================================
    TomoMod_Config.CreateSkyrideContent()

    -- ========================================
    -- CONTENU COMBAT INFO
    -- ========================================
    TomoMod_Config.CreateCombatInfoContent()

    -- ========================================
    -- CONTENU UI
    -- ========================================
    TomoMod_Config.CreateUIContent()
    
    -- Bouton Fermer (fixe en bas de configFrame)
    local closeBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    closeBtn:SetSize(100, 25)
    closeBtn:SetPoint("BOTTOM", 0, 15)
    closeBtn:SetText("Fermer")
    closeBtn:SetScript("OnClick", function()
        configFrame:Hide()
    end)
    
    -- Info (fixe en bas de configFrame)
    local dragInfo = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dragInfo:SetPoint("BOTTOMLEFT", 20, 15)
    dragInfo:SetText("Shift + Clic = Déplacer")
    dragInfo:SetTextColor(0.7, 0.7, 0.7)
    
    -- Info scroll
    local scrollInfo = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scrollInfo:SetPoint("BOTTOMRIGHT", -35, 15)
    scrollInfo:SetText("Molette pour défiler")
    scrollInfo:SetTextColor(0.7, 0.7, 0.7)
    
    -- Activer l'onglet QOL par défaut
    TomoMod_Config.SwitchTab("QOL")
end

-- =====================================
-- CONTENU QOL
-- =====================================
-- Créer le contenu de l'onglet QOL
function TomoMod_Config.CreateQOLContent()
    if not TomoModDB then return end
    -- Créer le ScrollFrame pour QOL
    local scrollFrame = CreateFrame("ScrollFrame", "TomoModConfigScrollQOL", configFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    
    -- Créer le contenu scrollable
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(460, 1000)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Support de la molette
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = math.max(0, math.min(current - (delta * 20), maxScroll))
        self:SetVerticalScroll(newScroll)
    end)
    
    configFrame.qolContent = scrollFrame
    
    -- ========== SECTION MINIMAP ==========
    local minimapHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    minimapHeader:SetPoint("TOPLEFT", 20, -10)
    minimapHeader:SetText("Minimap")
    minimapHeader:SetTextColor(0.3, 0.8, 1)
    
    -- Enable minimap
    local minimapEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -35, "Activer", TomoModDB.minimap.enabled, function(self)
        TomoModDB.minimap.enabled = self:GetChecked()
        if TomoModDB.minimap.enabled then
            TomoMod_Minimap.ApplySettings()
        end
    end)
    
    -- Slider taille minimap
    local minimapSizeSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModMinimapSizeSlider", "TOPLEFT", 30, -65,
        150, 300, 10, 250, "Taille: " .. TomoModDB.minimap.size,
        function(self, value)
            TomoModDB.minimap.size = value
            _G[self:GetName().."Text"]:SetText("Taille: " .. math.floor(value))
            Minimap:SetSize(value, value)
        end
    )
    minimapSizeSlider:SetValue(TomoModDB.minimap.size)
    
    -- Slider échelle minimap
    local minimapScaleSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModMinimapScaleSlider", "TOPLEFT", 30, -125,
        0.5, 2.0, 0.1, 250, "Échelle: " .. TomoModDB.minimap.scale,
        function(self, value)
            TomoModDB.minimap.scale = value
            _G[self:GetName().."Text"]:SetText("Échelle: " .. string.format("%.1f", value))
            TomoMod_Minimap.ApplyScale()
        end
    )
    minimapScaleSlider:SetValue(TomoModDB.minimap.scale)
    
    -- Bordure minimap
    local minimapBorderLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minimapBorderLabel:SetPoint("TOPLEFT", 30, -165)
    minimapBorderLabel:SetText("Bordure:")
    
    local minimapClassBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    minimapClassBtn:SetSize(100, 25)
    minimapClassBtn:SetPoint("TOPLEFT", 100, -165)
    minimapClassBtn:SetText("Classe")
    minimapClassBtn:SetScript("OnClick", function()
        TomoModDB.minimap.borderColor = "class"
        TomoMod_Minimap.CreateBorder()
    end)
    
    local minimapBlackBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    minimapBlackBtn:SetSize(100, 25)
    minimapBlackBtn:SetPoint("LEFT", minimapClassBtn, "RIGHT", 5, 0)
    minimapBlackBtn:SetText("Noir")
    minimapBlackBtn:SetScript("OnClick", function()
        TomoModDB.minimap.borderColor = "black"
        TomoMod_Minimap.CreateBorder()
    end)
    
    -- ========== SECTION INFO PANEL ==========
    local panelHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panelHeader:SetPoint("TOPLEFT", 20, -205)
    panelHeader:SetText("Info Panel")
    panelHeader:SetTextColor(0.3, 0.8, 1)
    
    -- Enable panel
    local panelEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -230, "Activer", TomoModDB.infoPanel.enabled, function(self)
        TomoModDB.infoPanel.enabled = self:GetChecked()
        print("|cff00ff00TomoMod:|r Panel enabled = " .. tostring(TomoModDB.infoPanel.enabled))
        if TomoModDB.infoPanel.enabled then
            TomoMod_InfoPanel.Initialize()
        else
            local panel = _G["TomoModInfoPanel"]
            if panel then 
                panel:Hide()
                print("|cff00ff00TomoMod:|r Panel caché")
            end
        end
    end)
    
    -- Checkboxes
    local durabilityCheck = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -255, "Durabilité (Gear)", TomoModDB.infoPanel.showDurability, function(self)
        TomoModDB.infoPanel.showDurability = self:GetChecked()
        TomoMod_InfoPanel.Update()
    end)
    
    local timeCheck = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -285, "Heure (Time)", TomoModDB.infoPanel.showTime, function(self)
        TomoModDB.infoPanel.showTime = self:GetChecked()
        TomoMod_InfoPanel.Update()
    end)
    
    local format24Check = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 50, -315, "Format 24h", TomoModDB.infoPanel.use24Hour, function(self)
        TomoModDB.infoPanel.use24Hour = self:GetChecked()
        TomoMod_InfoPanel.Update()
    end)
    
    -- Slider échelle panel
    local panelScaleSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModPanelScaleSlider", "TOPLEFT", 30, -385,
        0.5, 2.0, 0.1, 250, "Échelle: " .. TomoModDB.infoPanel.scale,
        function(self, value)
            TomoModDB.infoPanel.scale = value
            _G[self:GetName().."Text"]:SetText("Échelle: " .. string.format("%.1f", value))
            TomoMod_InfoPanel.UpdateAppearance()
        end
    )
    panelScaleSlider:SetValue(TomoModDB.infoPanel.scale)
    
    -- Bordure panel
    local panelBorderLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panelBorderLabel:SetPoint("TOPLEFT", 30, -435)
    panelBorderLabel:SetText("Bordure:")
    
    local panelBlackBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    panelBlackBtn:SetSize(100, 25)
    panelBlackBtn:SetPoint("TOPLEFT", 100, -435)
    panelBlackBtn:SetText("Noir")
    panelBlackBtn:SetScript("OnClick", function()
        TomoModDB.infoPanel.borderColor = "black"
        TomoMod_InfoPanel.UpdateAppearance()
    end)
    
    local panelClassBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    panelClassBtn:SetSize(100, 25)
    panelClassBtn:SetPoint("LEFT", panelBlackBtn, "RIGHT", 5, 0)
    panelClassBtn:SetText("Classe")
    panelClassBtn:SetScript("OnClick", function()
        TomoModDB.infoPanel.borderColor = "class"
        TomoMod_InfoPanel.UpdateAppearance()
    end)
    
    -- Reset position (à droite, même ligne que les boutons de bordure)
    local resetBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetBtn:SetSize(150, 25)
    resetBtn:SetPoint("TOPRIGHT", 0, -435)
    resetBtn:SetText("Reset Position Panel")
    resetBtn:SetScript("OnClick", function()
        TomoModDB.infoPanel.position = nil
        TomoMod_InfoPanel.SetPosition()
        print("|cff00ff00TomoMod:|r Position réinitialisée")
    end)
    
    -- ========== SECTION CURSOR RING ==========
    local cursorHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    cursorHeader:SetPoint("TOPLEFT", 20, -470)
    cursorHeader:SetText("Cursor Ring")
    cursorHeader:SetTextColor(0.3, 0.8, 1)
    
    -- Enable cursor ring
    local cursorEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -495, "Activer", TomoModDB.cursorRing.enabled, function(self)
        TomoModDB.cursorRing.enabled = self:GetChecked()
        TomoMod_CursorRing.ApplySettings()
    end)
    
    -- Couleur de classe
    local cursorClassColor = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -520, "Couleur de classe", TomoModDB.cursorRing.useClassColor, function(self)
        TomoModDB.cursorRing.useClassColor = self:GetChecked()
        TomoMod_CursorRing.ApplyColor()
    end)
    
    -- Ancrer tooltip
    local cursorTooltip = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 180, -520, "Ancrer Tooltip + Afficher Ring", TomoModDB.cursorRing.anchorTooltip, function(self)
        TomoModDB.cursorRing.anchorTooltip = self:GetChecked()
        TomoMod_CursorRing.SetupTooltipAnchor()
        TomoMod_CursorRing.Toggle(true)
    end)
    
    -- Slider échelle cursor
    local cursorScaleSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModCursorScaleSlider", "TOPLEFT", 30, -560,
        0.5, 3.0, 0.1, 250, "Échelle: " .. TomoModDB.cursorRing.scale,
        function(self, value)
            TomoModDB.cursorRing.scale = value
            _G[self:GetName().."Text"]:SetText("Échelle: " .. string.format("%.1f", value))
            TomoMod_CursorRing.ApplyScale()
        end
    )
    cursorScaleSlider:SetValue(TomoModDB.cursorRing.scale)
    
    -- Séparateur visuel
    local separator = scrollChild:CreateTexture(nil, "ARTWORK")
    separator:SetSize(420, 1)
    separator:SetPoint("TOPLEFT", 20, -610)
    separator:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    -- ========== SECTION CINEMATIC SKIP ==========
    local cinematicHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    cinematicHeader:SetPoint("TOPLEFT", 20, -630)
    cinematicHeader:SetText("Cinematic Skip")
    cinematicHeader:SetTextColor(0.3, 0.8, 1)
    
    -- Enable cinematic skip
    local cinematicEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -655, "Activer le skip automatique", TomoModDB.cinematicSkip.enabled, function(self)
        TomoModDB.cinematicSkip.enabled = self:GetChecked()
        if TomoModDB.cinematicSkip.enabled then
            TomoMod_CinematicSkip.Initialize()
        end
    end)
    
    -- Info sur le nombre de cinématiques vues
    local viewedCount = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    viewedCount:SetPoint("TOPLEFT", 30, -680)
    viewedCount:SetText("Cinématiques vues: " .. TomoMod_CinematicSkip.GetViewedCount())
    viewedCount:SetTextColor(0.8, 0.8, 0.8)
    
    -- Bouton pour effacer l'historique
    local clearHistoryBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    clearHistoryBtn:SetSize(180, 25)
    clearHistoryBtn:SetPoint("TOPLEFT", 30, -705)
    clearHistoryBtn:SetText("Effacer l'historique")
    clearHistoryBtn:SetScript("OnClick", function()
        TomoMod_CinematicSkip.ClearHistory()
        viewedCount:SetText("Cinématiques vues: " .. TomoMod_CinematicSkip.GetViewedCount())
    end)
    
    -- Info explicative
    local infoText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", 30, -740)
    infoText:SetWidth(400)
    infoText:SetJustifyH("LEFT")
    infoText:SetText("Les cinématiques sont skippées automatiquement après la première visualisation.\nL'historique est partagé entre tous vos personnages.")
    infoText:SetTextColor(0.6, 0.6, 0.6)
    
    -- Séparateur
    local separator2 = scrollChild:CreateTexture(nil, "ARTWORK")
    separator2:SetSize(420, 1)
    separator2:SetPoint("TOPLEFT", 20, -780)
    separator2:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    -- ========== SECTION AUTO QUEST ==========
    local autoQuestHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    autoQuestHeader:SetPoint("TOPLEFT", 20, -800)
    autoQuestHeader:SetText("Auto Quest")
    autoQuestHeader:SetTextColor(0.3, 0.8, 1)
    
    -- Enable auto accept
    local autoAcceptCheck = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -825, "Auto-accepter les quêtes", TomoModDB.autoQuest.autoAccept, function(self)
        TomoModDB.autoQuest.autoAccept = self:GetChecked()
    end)
    
    -- Enable auto turn in
    local autoTurnInCheck = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -850, "Auto-compléter les quêtes", TomoModDB.autoQuest.autoTurnIn, function(self)
        TomoModDB.autoQuest.autoTurnIn = self:GetChecked()
    end)
    
    -- Enable auto gossip
    local autoGossipCheck = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -875, "Auto-sélectionner les dialogues", TomoModDB.autoQuest.autoGossip, function(self)
        TomoModDB.autoQuest.autoGossip = self:GetChecked()
    end)
    
    -- Info explicative
    local questInfoText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    questInfoText:SetPoint("TOPLEFT", 30, -905)
    questInfoText:SetWidth(400)
    questInfoText:SetJustifyH("LEFT")
    questInfoText:SetText("Maintenez SHIFT pour désactiver temporairement l'auto-acceptation.\nLes quêtes avec choix de récompenses multiples ne seront pas auto-complétées.")
    questInfoText:SetTextColor(0.6, 0.6, 0.6)

    -- ========== SECTION Hide Player CastBar ==========
    local hideCastBarCheck = TomoMod_Utils.CreateCheckbox(
        scrollChild, "TOPLEFT", 30, -945,
        "Cacher la barre de cast",
        TomoModDB.hideCastBar.enabled,
        function(self)
            TomoMod_HideCastBar.SetEnabled(self:GetChecked())
        end
    )

    -- ========== SECTION MYTHIC KEYS ==========
    local mkHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mkHeader:SetPoint("TOPLEFT", 20, -980)
    mkHeader:SetText("Mythic+ Keys")
    mkHeader:SetTextColor(0.3, 0.8, 1)

    -- Enable Mythic Keys
    TomoMod_Utils.CreateCheckbox(
        scrollChild, "TOPLEFT", 30, -1005,
        "Activer le tracker de clés Mythic+",
        TomoModDB.MythicKeys.enabled,
        function(self)
            TomoModDB.MythicKeys.enabled = self:GetChecked()
            if TomoModDB.MythicKeys.enabled then
                TomoMod_EnableModule("MythicKeys")
            end
        end
    )

    -- Mini frame
    TomoMod_Utils.CreateCheckbox(
        scrollChild, "TOPLEFT", 30, -1030,
        "Afficher la mini-frame sur l'UI Mythic+",
        TomoModDB.MythicKeys.miniFrame,
        function(self)
            TomoModDB.MythicKeys.miniFrame = self:GetChecked()
            if MK and MK.UpdateMiniFrame then
                MK:UpdateMiniFrame()
            end
        end
    )

    -- Auto refresh
    TomoMod_Utils.CreateCheckbox(
        scrollChild, "TOPLEFT", 30, -1055,
        "Actualisation automatique",
        TomoModDB.MythicKeys.autoRefresh,
        function(self)
            TomoModDB.MythicKeys.autoRefresh = self:GetChecked()
        end
    )
end

-- =====================================
-- CONTENU Skyride
-- =====================================
function TomoMod_Config.CreateSkyrideContent()
    if not TomoModDB then return end
    -- Créer le ScrollFrame pour Skyride
    local scrollFrame = CreateFrame("ScrollFrame", "TomoModConfigScrollSkyride", configFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    
    -- Créer le contenu scrollable
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(460, 500)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Support de la molette
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = math.max(0, math.min(current - (delta * 20), maxScroll))
        self:SetVerticalScroll(newScroll)
    end)
    
    configFrame.skyrideContent = scrollFrame
    scrollFrame:Hide() -- Caché par défaut
    
    -- ========== SECTION GLOBALE ==========
    local globalHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    globalHeader:SetPoint("TOPLEFT", 20, -10)
    globalHeader:SetText("Paramètres Globaux")
    globalHeader:SetTextColor(1, 0.8, 0)
    
    -- Checkbox pour activer le module
    local enableCheck = TomoMod_Utils.CreateCheckbox(
        scrollChild, "TOPLEFT", 30, -35,
        "Activer SkyRide (affichage en vol uniquement)",
        TomoModDB.skyRide and TomoModDB.skyRide.enabled or false,
        function(self)
            if TomoMod_SkyRide and TomoMod_SkyRide.SetEnabled then
                TomoMod_SkyRide.SetEnabled(self:GetChecked())
            end
        end
    )
    
    -- Checkbox pour lock/unlock
    local lockCheck = TomoMod_Utils.CreateCheckbox(
        scrollChild, "TOPLEFT", 30, -60,
        "Verrouiller la barre (décocher pour déplacer)",
        true,
        function(self)
            if TomoMod_SkyRide and TomoMod_SkyRide.SetLocked then
                TomoMod_SkyRide.SetLocked(self:GetChecked())
            end
        end
    )
    
    -- Info sur le mode déplacement
    local lockInfo = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lockInfo:SetPoint("TOPLEFT", 50, -85)
    lockInfo:SetWidth(400)
    lockInfo:SetJustifyH("LEFT")
    lockInfo:SetText("Décochez pour activer le mode déplacement. Un overlay jaune apparaîtra.\nCliquez et glissez pour positionner. Recochez pour verrouiller.")
    lockInfo:SetTextColor(0.7, 0.7, 0.7)
    
    -- Séparateur
    local separatorGlobal = scrollChild:CreateTexture(nil, "ARTWORK")
    separatorGlobal:SetSize(420, 2)
    separatorGlobal:SetPoint("TOPLEFT", 20, -125)
    separatorGlobal:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    -- ========== SECTION APPARENCE ==========
    local appearanceHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    appearanceHeader:SetPoint("TOPLEFT", 20, -145)
    appearanceHeader:SetText("Apparence")
    appearanceHeader:SetTextColor(0.3, 0.8, 1)
    
    local skyRideSettings = TomoModDB.skyRide or {}
    
    -- Width slider
    local widthSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModSkyRideWidthSlider", "TOPLEFT", 30, -170,
        100, 600, 10, 250, "Largeur: " .. (skyRideSettings.width or 340),
        function(self, value)
            skyRideSettings.width = value
            _G[self:GetName().."Text"]:SetText("Largeur: " .. string.format("%.0f", value))
            if TomoMod_SkyRide and TomoMod_SkyRide.ApplySettings then
                TomoMod_SkyRide.ApplySettings()
            end
        end
    )
    widthSlider:SetValue(skyRideSettings.width or 340)
    
    -- Height slider (barre principale)
    local heightSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModSkyRideHeightSlider", "TOPLEFT", 30, -220,
        10, 40, 1, 250, "Hauteur barre: " .. (skyRideSettings.height or 20),
        function(self, value)
            skyRideSettings.height = value
            _G[self:GetName().."Text"]:SetText("Hauteur barre: " .. string.format("%.0f", value))
            if TomoMod_SkyRide and TomoMod_SkyRide.ApplySettings then
                TomoMod_SkyRide.ApplySettings()
            end
        end
    )
    heightSlider:SetValue(skyRideSettings.height or 20)
    
    -- Combo height slider
    local comboHeightSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModSkyRideComboHeightSlider", "TOPLEFT", 30, -270,
        3, 15, 1, 250, "Hauteur charges: " .. (skyRideSettings.comboHeight or 5),
        function(self, value)
            skyRideSettings.comboHeight = value
            _G[self:GetName().."Text"]:SetText("Hauteur charges: " .. string.format("%.0f", value))
            if TomoMod_SkyRide and TomoMod_SkyRide.ApplySettings then
                TomoMod_SkyRide.ApplySettings()
            end
        end
    )
    comboHeightSlider:SetValue(skyRideSettings.comboHeight or 5)
    
    -- Font size slider
    local fontSizeSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModSkyRideFontSizeSlider", "TOPLEFT", 30, -320,
        8, 24, 1, 250, "Taille police: " .. (skyRideSettings.fontSize or 12),
        function(self, value)
            skyRideSettings.fontSize = value
            _G[self:GetName().."Text"]:SetText("Taille police: " .. string.format("%.0f", value))
            if TomoMod_SkyRide and TomoMod_SkyRide.ApplySettings then
                TomoMod_SkyRide.ApplySettings()
            end
        end
    )
    fontSizeSlider:SetValue(skyRideSettings.fontSize or 12)
    
    -- Couleur de la barre de vitesse
    local barColorBtn = CreateColorButton(
        scrollChild, 30, -370,
        {skyRideSettings.barColor and skyRideSettings.barColor.r or 1,
         skyRideSettings.barColor and skyRideSettings.barColor.g or 1,
         skyRideSettings.barColor and skyRideSettings.barColor.b or 0},
        "Couleur barre vitesse:",
        function(r, g, b)
            skyRideSettings.barColor = {r = r, g = g, b = b}
            if TomoMod_SkyRide and TomoMod_SkyRide.ApplySettings then
                TomoMod_SkyRide.ApplySettings()
            end
        end
    )
    
    -- Séparateur
    local separator2 = scrollChild:CreateTexture(nil, "ARTWORK")
    separator2:SetSize(420, 2)
    separator2:SetPoint("TOPLEFT", 20, -410)
    separator2:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    -- ========== SECTION INFORMATIONS ==========
    local infoHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    infoHeader:SetPoint("TOPLEFT", 20, -430)
    infoHeader:SetText("Informations")
    infoHeader:SetTextColor(0.3, 0.8, 1)
    
    local infoText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoText:SetPoint("TOPLEFT", 30, -455)
    infoText:SetWidth(400)
    infoText:SetJustifyH("LEFT")
    infoText:SetText([[La barre SkyRide affiche:

    • Barre jaune: Vitesse de vol actuelle (0-1100%)
    • Nombre au centre: Cooldown de récupération Vigor
    • Première rangée (bleu clair): Charges Surge Forward
    • Deuxième rangée (bleu foncé): Charges Skyward Ascent

    La barre s'affiche automatiquement en vol et se cache au sol.]])
    infoText:SetTextColor(0.8, 0.8, 0.8)
    
    -- Séparateur
    local separator3 = scrollChild:CreateTexture(nil, "ARTWORK")
    separator3:SetSize(420, 2)
    separator3:SetPoint("TOPLEFT", 20, -580)
    separator3:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    -- ========== SECTION POSITION ==========
    local positionHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    positionHeader:SetPoint("TOPLEFT", 20, -600)
    positionHeader:SetText("Position")
    positionHeader:SetTextColor(0.3, 0.8, 1)
    
    -- Reset button
    local resetBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetBtn:SetSize(150, 25)
    resetBtn:SetPoint("TOPLEFT", 30, -625)
    resetBtn:SetText("Reset Position")
    resetBtn:SetScript("OnClick", function()
        if TomoMod_SkyRide and TomoMod_SkyRide.ResetPosition then
            TomoMod_SkyRide.ResetPosition()
        end
    end)
    
    -- Info position
    local posInfo = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    posInfo:SetPoint("TOPLEFT", 30, -660)
    posInfo:SetWidth(400)
    posInfo:SetJustifyH("LEFT")
    posInfo:SetText("Position par défaut: Centre-bas de l'écran (Y: -180)\nDéverrouillez pour déplacer, puis reverrouillez pour sécuriser.")
    posInfo:SetTextColor(0.7, 0.7, 0.7)

    -- Séparateur visuel
    local separator = scrollChild:CreateTexture(nil, "ARTWORK")
    separator:SetSize(420, 1)
    separator:SetPoint("TOPLEFT", 20, -610)
    separator:SetColorTexture(0.3, 0.3, 0.3, 0.8)
end

-- =====================================
-- CONTENU COMBAT INFO
-- =====================================
function TomoMod_Config.CreateCombatInfoContent()
    if not TomoModDB then return end
    
    -- Créer le ScrollFrame pour CombatInfo
    local scrollFrame = CreateFrame("ScrollFrame", "TomoModConfigScrollCombatInfo", configFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -120)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(460, 700)
    scrollFrame:SetScrollChild(scrollChild)
    
    configFrame.combatInfoContent = scrollFrame
    scrollFrame:Hide() -- Caché par défaut
    
    -- ========== SECTION GLOBALE ==========
    local globalHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    globalHeader:SetPoint("TOPLEFT", 20, -10)
    globalHeader:SetText("Paramètres Globaux")
    globalHeader:SetTextColor(1, 0.8, 0)
    
    local combatInfoSettings = TomoModDB.combatInfo or {}
    
    -- Checkbox pour activer le module
    local enableCheck = TomoMod_Utils.CreateCheckbox(
        scrollChild, "TOPLEFT", 30, -35,
        "Activer Combat Info",
        combatInfoSettings.enabled or true,
        function(self)
            if TomoMod_CombatInfo and TomoMod_CombatInfo.SetEnabled then
                TomoMod_CombatInfo.SetEnabled(self:GetChecked())
            end
        end
    )
    
    -- Info générale
    local infoText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", 50, -60)
    infoText:SetWidth(400)
    infoText:SetJustifyH("LEFT")
    infoText:SetText("Combat Info améliore l'apparence des buffs, debuffs et cooldowns Blizzard.\nModifications appliquées automatiquement au chargement.")
    infoText:SetTextColor(0.7, 0.7, 0.7)
    
    -- Séparateur
    local separatorGlobal = scrollChild:CreateTexture(nil, "ARTWORK")
    separatorGlobal:SetSize(420, 2)
    separatorGlobal:SetPoint("TOPLEFT", 20, -100)
    separatorGlobal:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    -- ========== SECTION APPARENCE ==========
    local appearanceHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    appearanceHeader:SetPoint("TOPLEFT", 20, -120)
    appearanceHeader:SetText("Apparence des Icônes")
    appearanceHeader:SetTextColor(0.3, 0.8, 1)
    
    -- Aligned Buff
    local alignedBuffCheck = TomoMod_Utils.CreateCheckbox(
        scrollChild, "TOPLEFT", 30, -145,
        "Centrer les buffs horizontalement",
        combatInfoSettings.alignedBuff or false,
        function(self)
            combatInfoSettings.alignedBuff = self:GetChecked()
            if TomoMod_CombatInfo and TomoMod_CombatInfo.ApplySettings then
                TomoMod_CombatInfo.ApplySettings()
            end
        end
    )
    
    -- Show HotKey
    local showHotKeyCheck = TomoMod_Utils.CreateCheckbox(
        scrollChild, "TOPLEFT", 30, -170,
        "Afficher les raccourcis clavier (hotkeys)",
        combatInfoSettings.showHotKey or false,
        function(self)
            combatInfoSettings.showHotKey = self:GetChecked()
            if TomoMod_CombatInfo and TomoMod_CombatInfo.ApplySettings then
                TomoMod_CombatInfo.ApplySettings()
            end
        end
    )
    
    -- Alert Assisted Spell
    local alertAssistedCheck = TomoMod_Utils.CreateCheckbox(
        scrollChild, "TOPLEFT", 30, -195,
        "Alerter le prochain sort assisté (pulsation verte)",
        combatInfoSettings.alertAssistedSpell or false,
        function(self)
            combatInfoSettings.alertAssistedSpell = self:GetChecked()
            if TomoMod_CombatInfo and TomoMod_CombatInfo.ApplySettings then
                TomoMod_CombatInfo.ApplySettings()
            end
        end
    )
    
    -- Séparateur
    local separator2 = scrollChild:CreateTexture(nil, "ARTWORK")
    separator2:SetSize(420, 2)
    separator2:SetPoint("TOPLEFT", 20, -230)
    separator2:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    -- ========== SECTION BARRES DE BUFF ==========
    local buffBarHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    buffBarHeader:SetPoint("TOPLEFT", 20, -250)
    buffBarHeader:SetText("Barres de Buff")
    buffBarHeader:SetTextColor(0.3, 0.8, 1)
    
    -- Change Buff Bar
    local changeBuffBarCheck = TomoMod_Utils.CreateCheckbox(
        scrollChild, "TOPLEFT", 30, -275,
        "Améliorer les barres de buff",
        combatInfoSettings.changeBuffBar or true,
        function(self)
            combatInfoSettings.changeBuffBar = self:GetChecked()
            if TomoMod_CombatInfo and TomoMod_CombatInfo.ApplySettings then
                TomoMod_CombatInfo.ApplySettings()
            end
        end
    )
    
    -- Buff Bar Class Color
    local buffBarClassColorCheck = TomoMod_Utils.CreateCheckbox(
        scrollChild, "TOPLEFT", 30, -300,
        "Couleur de classe pour les barres",
        combatInfoSettings.buffBarClassColor or true,
        function(self)
            combatInfoSettings.buffBarClassColor = self:GetChecked()
            if TomoMod_CombatInfo and TomoMod_CombatInfo.ApplySettings then
                TomoMod_CombatInfo.ApplySettings()
            end
        end
    )
    
    -- Hide Bar Name
    local hideBarNameCheck = TomoMod_Utils.CreateCheckbox(
        scrollChild, "TOPLEFT", 30, -325,
        "Cacher les noms des barres",
        combatInfoSettings.hideBarName or true,
        function(self)
            combatInfoSettings.hideBarName = self:GetChecked()
            if TomoMod_CombatInfo and TomoMod_CombatInfo.ApplySettings then
                TomoMod_CombatInfo.ApplySettings()
            end
        end
    )
    
    -- Séparateur
    local separator3 = scrollChild:CreateTexture(nil, "ARTWORK")
    separator3:SetSize(420, 2)
    separator3:SetPoint("TOPLEFT", 20, -360)
    separator3:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    -- ========== SECTION COMBAT ==========
    local combatHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    combatHeader:SetPoint("TOPLEFT", 20, -380)
    combatHeader:SetText("Combat")
    combatHeader:SetTextColor(0.3, 0.8, 1)
    
    -- Combat Alpha Change
    local combatAlphaCheck = TomoMod_Utils.CreateCheckbox(
        scrollChild, "TOPLEFT", 30, -405,
        "Changer l'opacité en combat",
        combatInfoSettings.combatAlphaChange or true,
        function(self)
            combatInfoSettings.combatAlphaChange = self:GetChecked()
            if TomoMod_CombatInfo and TomoMod_CombatInfo.ApplySettings then
                TomoMod_CombatInfo.ApplySettings()
            end
        end
    )
    
    local alphaInfo = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    alphaInfo:SetPoint("TOPLEFT", 50, -430)
    alphaInfo:SetWidth(400)
    alphaInfo:SetJustifyH("LEFT")
    alphaInfo:SetText("En combat: 100% opacité | Hors combat: 50% opacité")
    alphaInfo:SetTextColor(0.7, 0.7, 0.7)
    
    -- Séparateur
    local separator4 = scrollChild:CreateTexture(nil, "ARTWORK")
    separator4:SetSize(420, 2)
    separator4:SetPoint("TOPLEFT", 20, -460)
    separator4:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    -- ========== SECTION INFORMATIONS ==========
    local infoHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    infoHeader:SetPoint("TOPLEFT", 20, -480)
    infoHeader:SetText("Informations")
    infoHeader:SetTextColor(0.3, 0.8, 1)
    
    local detailsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    detailsText:SetPoint("TOPLEFT", 30, -505)
    detailsText:SetWidth(400)
    detailsText:SetJustifyH("LEFT")
    detailsText:SetText([[Combat Info modifie l'apparence des viewers de cooldown Blizzard:

    • UtilityCooldownViewer
    • EssentialCooldownViewer
    • BuffIconCooldownViewer
    • BuffBarCooldownViewer

    Les modifications incluent:
    - Icônes redimensionnées et recadrées
    - Bordures noires propres
    - Textures de barres améliorées
    - Texte de cooldown optimisé
    - Raccourcis clavier affichables
    - Centrage automatique des buffs

    Nécessite un /reload pour appliquer les changements.]])
    detailsText:SetTextColor(0.8, 0.8, 0.8)
end

-- =====================================
-- CONTENU Interface
-- =====================================
function TomoMod_Config.CreateUIContent()

end

function TomoMod_Config.Toggle()
    if not TomoModDB then
        print("|cffff0000TomoMod|r Base de données non initialisée")
        return
    end

    if not configFrame then
        TomoMod_Config.Create()
    end

    if configFrame:IsShown() then
        configFrame:Hide()
    else
        configFrame:Show()
    end
end

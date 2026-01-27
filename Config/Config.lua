-- =====================================
-- Config.lua
-- =====================================

TomoMod_Config = {}
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
local function CreateTabButton(parent, text, tabName, point, x, y)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn.tabName = tabName
    btn:SetSize(120, 30)
    btn:SetPoint(point, x, y)
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
    if configFrame.uiContent then configFrame.uiContent:Hide() end
    if configFrame.aurasContent then configFrame.aurasContent:Hide() end
    
    -- Afficher le contenu sélectionné
    if tabName == "QOL" and configFrame.qolContent then
        configFrame.qolContent:Show()
    elseif tabName == "UI" and configFrame.uiContent then
        configFrame.uiContent:Show()
    elseif tabName == "Auras" and configFrame.aurasContent then
        configFrame.aurasContent:Show()
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
    
    local uiTab = CreateTabButton(configFrame, "UI", "UI", "LEFT", qolTab, "RIGHT", 5, 0)
    table.insert(configFrame.tabs, uiTab)
    
    local aurasTab = CreateTabButton(configFrame, "Auras", "Auras", "LEFT", uiTab, "RIGHT", 5, 0)
    table.insert(configFrame.tabs, aurasTab)
    
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
    -- CONTENU UI
    -- ========================================
    TomoMod_Config.CreateUIContent()
    
    -- ========================================
    -- CONTENU AURAS (vide pour l'instant)
    -- ========================================
    TomoMod_Config.CreateAurasContent()
    
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
    
    local fpsCheck = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -345, "FPS (Fps)", TomoModDB.infoPanel.showFPS, function(self)
        TomoModDB.infoPanel.showFPS = self:GetChecked()
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
    resetBtn:SetPoint("TOPRIGHT", -20, -435)
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
    local cursorTooltip = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -520, "Ancrer Tooltip + Afficher Ring", TomoModDB.cursorRing.anchorTooltip, function(self)
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
end

-- =====================================
-- CONTENU UI
-- =====================================
-- Créer le contenu de l'onglet UI
function TomoMod_Config.CreateUIContent()
    local scrollFrame = CreateFrame("ScrollFrame", "TomoModConfigScrollUI", configFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(460, 2200)
    scrollFrame:SetScrollChild(scrollChild)
    
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = math.max(0, math.min(current - (delta * 30), maxScroll))
        self:SetVerticalScroll(newScroll)
    end)
    
    configFrame.uiContent = scrollFrame
    scrollFrame:Hide()
    
    local yOffset = -10
    
    -- ========== PRÉVISUALISATION ==========
    local previewHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    previewHeader:SetPoint("TOPLEFT", 20, yOffset)
    previewHeader:SetText("Mode Prévisualisation")
    previewHeader:SetTextColor(1, 0.82, 0)
    
    yOffset = yOffset - 30
    
    local previewToggleBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    previewToggleBtn:SetSize(150, 28)
    previewToggleBtn:SetPoint("TOPLEFT", 30, yOffset)
    previewToggleBtn:SetText("Activer Prévisualisation")
    
    local previewStatus = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    previewStatus:SetPoint("LEFT", previewToggleBtn, "RIGHT", 15, 0)
    previewStatus:SetText("● Inactif")
    previewStatus:SetTextColor(0.5, 0.5, 0.5)
    
    local function UpdatePreviewButton()
        if TomoMod_PreviewMode.IsActive() then
            previewToggleBtn:SetText("Arrêter Prévisualisation")
            previewStatus:SetText("● Actif")
            previewStatus:SetTextColor(0, 1, 0)
        else
            previewToggleBtn:SetText("Activer Prévisualisation")
            previewStatus:SetText("● Inactif")
            previewStatus:SetTextColor(0.5, 0.5, 0.5)
        end
    end
    
    previewToggleBtn:SetScript("OnClick", function()
        if TomoMod_PreviewMode.IsActive() then
            TomoMod_CastBars.HidePreview()
            TomoMod_UnitFrames.HidePreview()
            TomoMod_PreviewMode.Stop()
        else
            TomoMod_CastBars.ShowPreview()
            TomoMod_UnitFrames.ShowPreview()
            TomoMod_PreviewMode.Start()
        end
        UpdatePreviewButton()
    end)
    
    yOffset = yOffset - 35
    
    local gridSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModGridSizeSlider", "TOPLEFT", 30, yOffset,
        16, 64, 8, 200, "Grille: " .. TomoMod_PreviewMode.GetGridSize() .. " px",
        function(self, value)
            TomoMod_PreviewMode.SetGridSize(value)
            _G[self:GetName().."Text"]:SetText("Grille: " .. math.floor(value) .. " px")
        end
    )
    gridSlider:SetValue(TomoMod_PreviewMode.GetGridSize())
    
    yOffset = yOffset - 45
    
    local sep1 = scrollChild:CreateTexture(nil, "ARTWORK")
    sep1:SetSize(420, 2)
    sep1:SetPoint("TOPLEFT", 20, yOffset)
    sep1:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    yOffset = yOffset - 20
    
    -- ========== CAST BAR ==========
    local castBarHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    castBarHeader:SetPoint("TOPLEFT", 20, yOffset)
    castBarHeader:SetText("Barre de Cast (Cible)")
    castBarHeader:SetTextColor(0.3, 0.8, 1)
    
    yOffset = yOffset - 25
    
    local castBarEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Activer", TomoModDB.castBars.enabled, function(self)
        TomoModDB.castBars.enabled = self:GetChecked()
    end)
    
    yOffset = yOffset - 22
    
    local showSpellName = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Nom du sort", TomoModDB.castBars.showSpellName, function(self)
        TomoModDB.castBars.showSpellName = self:GetChecked()
        TomoMod_CastBars.UpdateSettings()
    end)
    
    local showTargetName = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 200, yOffset, "Nom cible", TomoModDB.castBars.showTargetName, function(self)
        TomoModDB.castBars.showTargetName = self:GetChecked()
        TomoMod_CastBars.UpdateSettings()
    end)
    
    yOffset = yOffset - 22
    
    local flashOnTargeted = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Flash si ciblé", TomoModDB.castBars.flashOnTargeted, function(self)
        TomoModDB.castBars.flashOnTargeted = self:GetChecked()
    end)
    
    yOffset = yOffset - 35
    
    local widthSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModCastBarWidthSlider", "TOPLEFT", 30, yOffset,
        150, 400, 10, 180, "Largeur: " .. TomoModDB.castBars.width,
        function(self, value)
            TomoModDB.castBars.width = value
            _G[self:GetName().."Text"]:SetText("Largeur: " .. math.floor(value))
            TomoMod_CastBars.UpdateSettings()
        end
    )
    widthSlider:SetValue(TomoModDB.castBars.width)
    
    local heightSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModCastBarHeightSlider", "TOPLEFT", 250, yOffset,
        15, 40, 1, 180, "Hauteur: " .. TomoModDB.castBars.height,
        function(self, value)
            TomoModDB.castBars.height = value
            _G[self:GetName().."Text"]:SetText("Hauteur: " .. math.floor(value))
            TomoMod_CastBars.UpdateSettings()
        end
    )
    heightSlider:SetValue(TomoModDB.castBars.height)
    
    yOffset = yOffset - 50
    
    local interruptColor = CreateColorButton(scrollChild, 30, yOffset, TomoModDB.castBars.interruptibleColor, "Interruptible:", function(r, g, b)
        TomoModDB.castBars.interruptibleColor = {r, g, b}
    end)
    
    yOffset = yOffset - 25
    
    local notInterruptColor = CreateColorButton(scrollChild, 30, yOffset, TomoModDB.castBars.notInterruptibleColor, "Non-Interruptible:", function(r, g, b)
        TomoModDB.castBars.notInterruptibleColor = {r, g, b}
    end)
    
    yOffset = yOffset - 25
    
    local interruptedColor = CreateColorButton(scrollChild, 30, yOffset, TomoModDB.castBars.interruptedColor, "Interrompu:", function(r, g, b)
        TomoModDB.castBars.interruptedColor = {r, g, b}
    end)
    
    yOffset = yOffset - 30
    
    local resetCastPosBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetCastPosBtn:SetSize(120, 22)
    resetCastPosBtn:SetPoint("TOPLEFT", 30, yOffset)
    resetCastPosBtn:SetText("Reset Position")
    resetCastPosBtn:SetScript("OnClick", function()
        TomoMod_CastBars.ResetPosition()
    end)
    
    yOffset = yOffset - 35
    
    local sep2 = scrollChild:CreateTexture(nil, "ARTWORK")
    sep2:SetSize(420, 2)
    sep2:SetPoint("TOPLEFT", 20, yOffset)
    sep2:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    yOffset = yOffset - 20
    
    -- ========== PLAYER FRAME ==========
    local playerHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    playerHeader:SetPoint("TOPLEFT", 20, yOffset)
    playerHeader:SetText("Player Frame")
    playerHeader:SetTextColor(0.3, 0.8, 1)
    
    yOffset = yOffset - 25
    
    local playerEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Activer", TomoModDB.unitFrames.player.enabled, function(self)
        TomoModDB.unitFrames.player.enabled = self:GetChecked()
    end)
    
    local playerMinimalist = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 200, yOffset, "Mode Minimaliste", TomoModDB.unitFrames.player.minimalist, function(self)
        TomoModDB.unitFrames.player.minimalist = self:GetChecked()
        TomoMod_UnitFrames.UpdatePlayerSettings()
    end)
    
    yOffset = yOffset - 22
    
    local playerLeader = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Leader", TomoModDB.unitFrames.player.showLeader, function(self)
        TomoModDB.unitFrames.player.showLeader = self:GetChecked()
        TomoMod_UnitFrames.UpdatePlayerSettings()
    end)
    
    local playerMarker = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 150, yOffset, "Marqueur", TomoModDB.unitFrames.player.showRaidMarker, function(self)
        TomoModDB.unitFrames.player.showRaidMarker = self:GetChecked()
        TomoMod_UnitFrames.UpdatePlayerSettings()
    end)
    
    local playerName = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 280, yOffset, "Nom", TomoModDB.unitFrames.player.showName, function(self)
        TomoModDB.unitFrames.player.showName = self:GetChecked()
        TomoMod_UnitFrames.UpdatePlayerSettings()
    end)
    
    yOffset = yOffset - 22
    
    local playerLevel = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Niveau", TomoModDB.unitFrames.player.showLevel, function(self)
        TomoModDB.unitFrames.player.showLevel = self:GetChecked()
        TomoMod_UnitFrames.UpdatePlayerSettings()
    end)
    
    local playerCurrentHP = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 150, yOffset, "HP valeur", TomoModDB.unitFrames.player.showCurrentHP, function(self)
        TomoModDB.unitFrames.player.showCurrentHP = self:GetChecked()
        TomoMod_UnitFrames.UpdatePlayerSettings()
    end)
    
    local playerPercentHP = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 280, yOffset, "HP %", TomoModDB.unitFrames.player.showPercentHP, function(self)
        TomoModDB.unitFrames.player.showPercentHP = self:GetChecked()
        TomoMod_UnitFrames.UpdatePlayerSettings()
    end)
    
    yOffset = yOffset - 30
    
    local playerWidthSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModPlayerWidthSlider", "TOPLEFT", 30, yOffset,
        100, 400, 10, 130, "Larg: " .. TomoModDB.unitFrames.player.width,
        function(self, value)
            if not TomoModDB.unitFrames.player.minimalist then
                TomoModDB.unitFrames.player.width = value
                _G[self:GetName().."Text"]:SetText("Larg: " .. math.floor(value))
                TomoMod_UnitFrames.UpdatePlayerSettings()
            end
        end
    )
    playerWidthSlider:SetValue(TomoModDB.unitFrames.player.width)
    
    local playerHeightSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModPlayerHeightSlider", "TOPLEFT", 180, yOffset,
        15, 60, 1, 130, "Haut: " .. TomoModDB.unitFrames.player.height,
        function(self, value)
            if not TomoModDB.unitFrames.player.minimalist then
                TomoModDB.unitFrames.player.height = value
                _G[self:GetName().."Text"]:SetText("Haut: " .. math.floor(value))
                TomoMod_UnitFrames.UpdatePlayerSettings()
            end
        end
    )
    playerHeightSlider:SetValue(TomoModDB.unitFrames.player.height)
    
    local playerScaleSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModPlayerScaleSlider", "TOPLEFT", 330, yOffset,
        0.5, 2.0, 0.1, 100, "Scale: " .. TomoModDB.unitFrames.player.scale,
        function(self, value)
            TomoModDB.unitFrames.player.scale = value
            _G[self:GetName().."Text"]:SetText("Scale: " .. string.format("%.1f", value))
            TomoMod_UnitFrames.UpdatePlayerSettings()
        end
    )
    playerScaleSlider:SetValue(TomoModDB.unitFrames.player.scale)
    
    yOffset = yOffset - 45
    
    local resetPlayerPosBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetPlayerPosBtn:SetSize(120, 22)
    resetPlayerPosBtn:SetPoint("TOPLEFT", 30, yOffset)
    resetPlayerPosBtn:SetText("Reset Position")
    resetPlayerPosBtn:SetScript("OnClick", function()
        TomoMod_UnitFrames.ResetPlayerPosition()
    end)
    
    yOffset = yOffset - 35
    
    local sep3 = scrollChild:CreateTexture(nil, "ARTWORK")
    sep3:SetSize(420, 2)
    sep3:SetPoint("TOPLEFT", 20, yOffset)
    sep3:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    yOffset = yOffset - 20
    
    -- ========== TARGET FRAME ==========
    local targetHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    targetHeader:SetPoint("TOPLEFT", 20, yOffset)
    targetHeader:SetText("Target Frame")
    targetHeader:SetTextColor(0.3, 0.8, 1)
    
    yOffset = yOffset - 25
    
    local targetEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Activer", TomoModDB.unitFrames.target.enabled, function(self)
        TomoModDB.unitFrames.target.enabled = self:GetChecked()
    end)
    
    local targetMinimalist = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 200, yOffset, "Mode Minimaliste", TomoModDB.unitFrames.target.minimalist, function(self)
        TomoModDB.unitFrames.target.minimalist = self:GetChecked()
        TomoMod_UnitFrames.UpdateTargetSettings()
    end)
    
    yOffset = yOffset - 22
    
    local targetLeader = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Leader", TomoModDB.unitFrames.target.showLeader, function(self)
        TomoModDB.unitFrames.target.showLeader = self:GetChecked()
        TomoMod_UnitFrames.UpdateTargetSettings()
    end)
    
    local targetMarker = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 150, yOffset, "Marqueur", TomoModDB.unitFrames.target.showRaidMarker, function(self)
        TomoModDB.unitFrames.target.showRaidMarker = self:GetChecked()
        TomoMod_UnitFrames.UpdateTargetSettings()
    end)
    
    local targetName = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 280, yOffset, "Nom", TomoModDB.unitFrames.target.showName, function(self)
        TomoModDB.unitFrames.target.showName = self:GetChecked()
        TomoMod_UnitFrames.UpdateTargetSettings()
    end)
    
    yOffset = yOffset - 22
    
    local targetLevel = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Niveau", TomoModDB.unitFrames.target.showLevel, function(self)
        TomoModDB.unitFrames.target.showLevel = self:GetChecked()
        TomoMod_UnitFrames.UpdateTargetSettings()
    end)
    
    local targetCurrentHP = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 150, yOffset, "HP valeur", TomoModDB.unitFrames.target.showCurrentHP, function(self)
        TomoModDB.unitFrames.target.showCurrentHP = self:GetChecked()
        TomoMod_UnitFrames.UpdateTargetSettings()
    end)
    
    local targetPercentHP = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 280, yOffset, "HP %", TomoModDB.unitFrames.target.showPercentHP, function(self)
        TomoModDB.unitFrames.target.showPercentHP = self:GetChecked()
        TomoMod_UnitFrames.UpdateTargetSettings()
    end)
    
    yOffset = yOffset - 25
    
    local targetColorInfo = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    targetColorInfo:SetPoint("TOPLEFT", 30, yOffset)
    targetColorInfo:SetText("Couleurs: Joueur=Classe, Amical=Vert, Neutre=Jaune, Ennemi=Rouge")
    targetColorInfo:SetTextColor(0.6, 0.6, 0.6)
    
    yOffset = yOffset - 25
    
    local targetWidthSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModTargetWidthSlider", "TOPLEFT", 30, yOffset,
        100, 400, 10, 130, "Larg: " .. TomoModDB.unitFrames.target.width,
        function(self, value)
            if not TomoModDB.unitFrames.target.minimalist then
                TomoModDB.unitFrames.target.width = value
                _G[self:GetName().."Text"]:SetText("Larg: " .. math.floor(value))
                TomoMod_UnitFrames.UpdateTargetSettings()
            end
        end
    )
    targetWidthSlider:SetValue(TomoModDB.unitFrames.target.width)
    
    local targetHeightSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModTargetHeightSlider", "TOPLEFT", 180, yOffset,
        15, 60, 1, 130, "Haut: " .. TomoModDB.unitFrames.target.height,
        function(self, value)
            if not TomoModDB.unitFrames.target.minimalist then
                TomoModDB.unitFrames.target.height = value
                _G[self:GetName().."Text"]:SetText("Haut: " .. math.floor(value))
                TomoMod_UnitFrames.UpdateTargetSettings()
            end
        end
    )
    targetHeightSlider:SetValue(TomoModDB.unitFrames.target.height)
    
    local targetScaleSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModTargetScaleSlider", "TOPLEFT", 330, yOffset,
        0.5, 2.0, 0.1, 100, "Scale: " .. TomoModDB.unitFrames.target.scale,
        function(self, value)
            TomoModDB.unitFrames.target.scale = value
            _G[self:GetName().."Text"]:SetText("Scale: " .. string.format("%.1f", value))
            TomoMod_UnitFrames.UpdateTargetSettings()
        end
    )
    targetScaleSlider:SetValue(TomoModDB.unitFrames.target.scale)
    
    yOffset = yOffset - 45
    
    local resetTargetPosBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetTargetPosBtn:SetSize(120, 22)
    resetTargetPosBtn:SetPoint("TOPLEFT", 30, yOffset)
    resetTargetPosBtn:SetText("Reset Position")
    resetTargetPosBtn:SetScript("OnClick", function()
        TomoMod_UnitFrames.ResetTargetPosition()
    end)
    
    yOffset = yOffset - 35
    
    local sep4 = scrollChild:CreateTexture(nil, "ARTWORK")
    sep4:SetSize(420, 2)
    sep4:SetPoint("TOPLEFT", 20, yOffset)
    sep4:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    yOffset = yOffset - 20
    
    -- ========== TARGET OF TARGET FRAME ==========
    local totHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    totHeader:SetPoint("TOPLEFT", 20, yOffset)
    totHeader:SetText("Target of Target")
    totHeader:SetTextColor(0.3, 0.8, 1)
    
    yOffset = yOffset - 25
    
    local totEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Activer", TomoModDB.unitFrames.targetoftarget.enabled, function(self)
        TomoModDB.unitFrames.targetoftarget.enabled = self:GetChecked()
    end)
    
    local totMinimalist = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 200, yOffset, "Mode Minimaliste (max 150)", TomoModDB.unitFrames.targetoftarget.minimalist, function(self)
        TomoModDB.unitFrames.targetoftarget.minimalist = self:GetChecked()
        TomoMod_UnitFrames.UpdateToTSettings()
    end)
    
    yOffset = yOffset - 25
    
    local totInfo = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    totInfo:SetPoint("TOPLEFT", 30, yOffset)
    totInfo:SetText("Affiche uniquement le nom (couleur classe si joueur, blanc si PNJ)")
    totInfo:SetTextColor(0.6, 0.6, 0.6)
    
    yOffset = yOffset - 25
    
    local totColorInfo = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    totColorInfo:SetPoint("TOPLEFT", 30, yOffset)
    totColorInfo:SetText("Barre: Joueur=Classe, Amical=Vert, Neutre=Jaune, Ennemi=Rouge")
    totColorInfo:SetTextColor(0.6, 0.6, 0.6)
    
    yOffset = yOffset - 30
    
    local totWidthSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModToTWidthSlider", "TOPLEFT", 30, yOffset,
        60, 150, 5, 180, "Largeur: " .. TomoModDB.unitFrames.targetoftarget.width,
        function(self, value)
            if not TomoModDB.unitFrames.targetoftarget.minimalist then
                TomoModDB.unitFrames.targetoftarget.width = value
                _G[self:GetName().."Text"]:SetText("Largeur: " .. math.floor(value))
                TomoMod_UnitFrames.UpdateToTSettings()
            end
        end
    )
    totWidthSlider:SetValue(TomoModDB.unitFrames.targetoftarget.width)
    
    local totScaleSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModToTScaleSlider", "TOPLEFT", 250, yOffset,
        0.5, 2.0, 0.1, 150, "Scale: " .. TomoModDB.unitFrames.targetoftarget.scale,
        function(self, value)
            TomoModDB.unitFrames.targetoftarget.scale = value
            _G[self:GetName().."Text"]:SetText("Scale: " .. string.format("%.1f", value))
            TomoMod_UnitFrames.UpdateToTSettings()
        end
    )
    totScaleSlider:SetValue(TomoModDB.unitFrames.targetoftarget.scale)
    
    yOffset = yOffset - 45
    
    local resetToTPosBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetToTPosBtn:SetSize(120, 22)
    resetToTPosBtn:SetPoint("TOPLEFT", 30, yOffset)
    resetToTPosBtn:SetText("Reset Position")
    resetToTPosBtn:SetScript("OnClick", function()
        TomoMod_UnitFrames.ResetToTPosition()
    end)
    
    yOffset = yOffset - 50
    
    -- Info finale
    local infoText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", 20, yOffset)
    infoText:SetWidth(420)
    infoText:SetJustifyH("LEFT")
    infoText:SetText("Notes:\n• Player: Barre d'absorption bleue pour boucliers\n• Séparateur \" - \" si HP valeur ET % activés\n• ToT: Hauteur fixe 15px\n• /reload nécessaire pour activer/désactiver")
    infoText:SetTextColor(0.5, 0.5, 0.5)
    
    scrollFrame:SetScript("OnShow", function()
        UpdatePreviewButton()
    end)
end

-- =====================================
-- CONTENU AURAS
-- =====================================
-- Créer le contenu de l'onglet Auras
function TomoMod_Config.CreateAurasContent()
    -- Créer le ScrollFrame pour Auras
    local scrollFrame = CreateFrame("ScrollFrame", "TomoModConfigScrollAuras", configFrame, "UIPanelScrollFrameTemplate")
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
    
    configFrame.aurasContent = scrollFrame
    scrollFrame:Hide()
    
    -- Contenu placeholder
    local placeholder = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    placeholder:SetPoint("CENTER", scrollChild, "TOP", 0, -100)
    placeholder:SetText("Section Auras")
    placeholder:SetTextColor(0.7, 0.7, 0.7)
    
    local info = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info:SetPoint("TOP", placeholder, "BOTTOM", 0, -20)
    info:SetText("Les futures modifications de buffs/debuffs\nseront disponibles ici")
    info:SetTextColor(0.5, 0.5, 0.5)
end

function TomoMod_Config.Toggle()
    if not configFrame then
        TomoMod_Config.Create()
    end
    
    if configFrame:IsShown() then
        configFrame:Hide()
    else
        configFrame:Show()
    end
end
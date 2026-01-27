-- =====================================
-- Config.lua
-- =====================================

TomoMod_Config = {}
local configFrame
local currentTab = "QOL" -- Onglet par défaut

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
    -- CONTENU UI (vide pour l'instant)
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

-- Créer le contenu de l'onglet UI
function TomoMod_Config.CreateUIContent()
    -- Créer le ScrollFrame pour UI
    local scrollFrame = CreateFrame("ScrollFrame", "TomoModConfigScrollUI", configFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    
    -- Créer le contenu scrollable
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(460, 700) -- Augmenté pour le contenu additionnel
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Support de la molette
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = math.max(0, math.min(current - (delta * 20), maxScroll))
        self:SetVerticalScroll(newScroll)
    end)
    
    configFrame.uiContent = scrollFrame
    scrollFrame:Hide()
    
    -- ========== SECTION CAST BAR ==========
    local castBarHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    castBarHeader:SetPoint("TOPLEFT", 20, -10)
    castBarHeader:SetText("Barre de Cast (Cible)")
    castBarHeader:SetTextColor(0.3, 0.8, 1)
    
    -- Enable
    local castBarEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -35, "Activer", TomoModDB.castBars.enabled, function(self)
        TomoModDB.castBars.enabled = self:GetChecked()
        print("|cff00ff00TomoMod:|r Cast Bar = " .. tostring(TomoModDB.castBars.enabled) .. " - /reload pour appliquer")
    end)
    
    -- Afficher nom du sort
    local showSpellName = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -60, "Afficher nom du sort", TomoModDB.castBars.showSpellName, function(self)
        TomoModDB.castBars.showSpellName = self:GetChecked()
        TomoMod_CastBars.UpdateSettings()
    end)
    
    -- Afficher nom de la cible
    local showTargetName = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -85, "Afficher la cible (couleur de classe)", TomoModDB.castBars.showTargetName, function(self)
        TomoModDB.castBars.showTargetName = self:GetChecked()
        TomoMod_CastBars.UpdateSettings()
    end)
    
    -- Flash si ciblé
    local flashOnTargeted = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, -110, "Flash si vous êtes ciblé", TomoModDB.castBars.flashOnTargeted, function(self)
        TomoModDB.castBars.flashOnTargeted = self:GetChecked()
    end)
    
    -- Largeur
    local widthSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModCastBarWidthSlider", "TOPLEFT", 30, -155,
        150, 400, 10, 250, "Largeur: " .. TomoModDB.castBars.width,
        function(self, value)
            TomoModDB.castBars.width = value
            _G[self:GetName().."Text"]:SetText("Largeur: " .. math.floor(value))
            TomoMod_CastBars.UpdateSettings()
        end
    )
    widthSlider:SetValue(TomoModDB.castBars.width)
    
    -- Hauteur
    local heightSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModCastBarHeightSlider", "TOPLEFT", 30, -215,
        15, 40, 1, 250, "Hauteur: " .. TomoModDB.castBars.height,
        function(self, value)
            TomoModDB.castBars.height = value
            _G[self:GetName().."Text"]:SetText("Hauteur: " .. math.floor(value))
            TomoMod_CastBars.UpdateSettings()
        end
    )
    heightSlider:SetValue(TomoModDB.castBars.height)
    
    -- ========== PRÉVISUALISATION ==========
    local previewLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    previewLabel:SetPoint("TOPLEFT", 20, -270)
    previewLabel:SetText("Prévisualisation")
    previewLabel:SetTextColor(0.3, 0.8, 1)
    
    -- Bouton Prévisualiser
    local previewBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    previewBtn:SetSize(120, 25)
    previewBtn:SetPoint("TOPLEFT", 30, -295)
    previewBtn:SetText("Prévisualiser")
    previewBtn:SetScript("OnClick", function()
        TomoMod_CastBars.StartPreview()
    end)
    
    -- Bouton Arrêter
    local stopPreviewBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    stopPreviewBtn:SetSize(120, 25)
    stopPreviewBtn:SetPoint("LEFT", previewBtn, "RIGHT", 10, 0)
    stopPreviewBtn:SetText("Arrêter")
    stopPreviewBtn:SetScript("OnClick", function()
        TomoMod_CastBars.StopPreview()
    end)
    
    -- Info prévisualisation
    local previewInfo = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewInfo:SetPoint("TOPLEFT", 30, -325)
    previewInfo:SetWidth(400)
    previewInfo:SetJustifyH("LEFT")
    previewInfo:SetText("En mode prévisualisation, vous pouvez déplacer la barre en la glissant directement.")
    previewInfo:SetTextColor(0.6, 0.6, 0.6)
    
    -- ========== COULEURS ==========
    local colorsLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    colorsLabel:SetPoint("TOPLEFT", 20, -360)
    colorsLabel:SetText("Couleurs")
    colorsLabel:SetTextColor(0.3, 0.8, 1)
    
    -- Couleur Interruptible (Cyan par défaut)
    local interruptLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    interruptLabel:SetPoint("TOPLEFT", 30, -385)
    interruptLabel:SetText("Interruptible:")
    
    -- Aperçu couleur interruptible
    local interruptColorPreview = scrollChild:CreateTexture(nil, "ARTWORK")
    interruptColorPreview:SetSize(20, 20)
    interruptColorPreview:SetPoint("LEFT", interruptLabel, "RIGHT", 10, 0)
    local ic = TomoModDB.castBars.interruptibleColor
    interruptColorPreview:SetColorTexture(ic[1], ic[2], ic[3], 1)
    
    local interruptColorText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    interruptColorText:SetPoint("LEFT", interruptColorPreview, "RIGHT", 5, 0)
    interruptColorText:SetText("Cyan (par défaut)")
    interruptColorText:SetTextColor(0.7, 0.7, 0.7)
    
    -- Couleur Not Interruptible (Gris par défaut)
    local notInterruptLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    notInterruptLabel:SetPoint("TOPLEFT", 30, -410)
    notInterruptLabel:SetText("Non-Interruptible:")
    
    -- Aperçu couleur non-interruptible
    local notInterruptColorPreview = scrollChild:CreateTexture(nil, "ARTWORK")
    notInterruptColorPreview:SetSize(20, 20)
    notInterruptColorPreview:SetPoint("LEFT", notInterruptLabel, "RIGHT", 10, 0)
    local nic = TomoModDB.castBars.notInterruptibleColor
    notInterruptColorPreview:SetColorTexture(nic[1], nic[2], nic[3], 1)
    
    local notInterruptColorText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    notInterruptColorText:SetPoint("LEFT", notInterruptColorPreview, "RIGHT", 5, 0)
    notInterruptColorText:SetText("Gris (par défaut)")
    notInterruptColorText:SetTextColor(0.7, 0.7, 0.7)
    
    -- Couleur Interrompu (Plum)
    local interruptedLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    interruptedLabel:SetPoint("TOPLEFT", 30, -435)
    interruptedLabel:SetText("Interrompu:")
    
    -- Aperçu couleur interrompu
    local interruptedColorPreview = scrollChild:CreateTexture(nil, "ARTWORK")
    interruptedColorPreview:SetSize(20, 20)
    interruptedColorPreview:SetPoint("LEFT", interruptedLabel, "RIGHT", 10, 0)
    local irc = TomoModDB.castBars.interruptedColor
    interruptedColorPreview:SetColorTexture(irc[1], irc[2], irc[3], 1)
    
    local interruptedColorText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    interruptedColorText:SetPoint("LEFT", interruptedColorPreview, "RIGHT", 5, 0)
    interruptedColorText:SetText("Plum (par défaut)")
    interruptedColorText:SetTextColor(0.7, 0.7, 0.7)
    
    -- Séparateur
    local separator = scrollChild:CreateTexture(nil, "ARTWORK")
    separator:SetSize(420, 1)
    separator:SetPoint("TOPLEFT", 20, -470)
    separator:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    -- ========== POSITION ==========
    local posLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    posLabel:SetPoint("TOPLEFT", 20, -490)
    posLabel:SetText("Position")
    posLabel:SetTextColor(0.3, 0.8, 1)
    
    -- Reset position
    local resetPosBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetPosBtn:SetSize(200, 25)
    resetPosBtn:SetPoint("TOPLEFT", 30, -515)
    resetPosBtn:SetText("Réinitialiser la position")
    resetPosBtn:SetScript("OnClick", function()
        TomoMod_CastBars.ResetPosition()
        print("|cff00ff00TomoMod:|r Position réinitialisée")
    end)
    
    -- Info
    local infoText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", 30, -550)
    infoText:SetWidth(400)
    infoText:SetJustifyH("LEFT")
    infoText:SetText("• La barre devient opaque (0.4) si la cible est un allié en groupe/raid\n• Shift + Clic pour déplacer la barre (ou utilisez la prévisualisation)\n• Certains changements nécessitent un /reload")
    infoText:SetTextColor(0.6, 0.6, 0.6)
end

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
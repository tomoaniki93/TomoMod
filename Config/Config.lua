-- =====================================
-- Config.lua
-- =====================================

TomoMod_Config = {}
TomoMod_ConfigPreview = {}

local configFrame
local currentTab = "QOL"

-- =====================================
-- FONCTIONS PREVIEW
-- =====================================

local previewModules = {
    ui = {
        show = function()
            if TomoMod_CastBars then TomoMod_CastBars.ShowPreview() end
            if TomoMod_UnitFrames then TomoMod_UnitFrames.ShowPreview() end
        end,
        hide = function()
            if TomoMod_CastBars then TomoMod_CastBars.HidePreview() end
            if TomoMod_UnitFrames then TomoMod_UnitFrames.HidePreview() end
        end,
    },
    auras = {
        show = function()
            if TomoMod_Auras then TomoMod_Auras.ShowPreview() end
        end,
        hide = function()
            if TomoMod_Auras then TomoMod_Auras.HidePreview() end
        end,
    },
    qol = {
        show = function() end,
        hide = function() end,
    },
}

function TomoMod_ConfigPreview.RegisterModule(tabName, showFunc, hideFunc)
    if not previewModules[tabName] then
        previewModules[tabName] = { show = function() end, hide = function() end }
    end
    
    local originalShow = previewModules[tabName].show
    local originalHide = previewModules[tabName].hide
    
    previewModules[tabName].show = function()
        originalShow()
        if showFunc then showFunc() end
    end
    
    previewModules[tabName].hide = function()
        originalHide()
        if hideFunc then hideFunc() end
    end
end

function TomoMod_ConfigPreview.ShowForTab(tabName)
    if previewModules[tabName] then
        previewModules[tabName].show()
    end
    TomoMod_PreviewMode.Start()
end

function TomoMod_ConfigPreview.HideForTab(tabName)
    if previewModules[tabName] then
        previewModules[tabName].hide()
    end
    TomoMod_PreviewMode.Stop()
end

function TomoMod_ConfigPreview.ShowAll()
    for _, module in pairs(previewModules) do
        module.show()
    end
    TomoMod_PreviewMode.Start()
end

function TomoMod_ConfigPreview.HideAll()
    for _, module in pairs(previewModules) do
        module.hide()
    end
    TomoMod_PreviewMode.Stop()
end

-- Widget de preview réutilisable
function TomoMod_ConfigPreview.CreatePreviewSection(parent, yOffset, tabName)
    local elements = {}
    
    elements.header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    elements.header:SetPoint("TOPLEFT", 20, yOffset)
    elements.header:SetText("Mode Prévisualisation")
    elements.header:SetTextColor(1, 0.82, 0)
    
    yOffset = yOffset - 30
    
    elements.toggleBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    elements.toggleBtn:SetSize(150, 28)
    elements.toggleBtn:SetPoint("TOPLEFT", 30, yOffset)
    elements.toggleBtn:SetText("Activer Prévisualisation")
    
    elements.status = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    elements.status:SetPoint("LEFT", elements.toggleBtn, "RIGHT", 15, 0)
    elements.status:SetText("● Inactif")
    elements.status:SetTextColor(0.5, 0.5, 0.5)
    
    local function UpdatePreviewButton()
        if TomoMod_PreviewMode.IsActive() then
            elements.toggleBtn:SetText("Arrêter Prévisualisation")
            elements.status:SetText("● Actif")
            elements.status:SetTextColor(0, 1, 0)
        else
            elements.toggleBtn:SetText("Activer Prévisualisation")
            elements.status:SetText("● Inactif")
            elements.status:SetTextColor(0.5, 0.5, 0.5)
        end
    end
    
    elements.UpdateButton = UpdatePreviewButton
    
    elements.toggleBtn:SetScript("OnClick", function()
        if TomoMod_PreviewMode.IsActive() then
            TomoMod_ConfigPreview.HideForTab(tabName)
        else
            TomoMod_ConfigPreview.ShowForTab(tabName)
        end
        UpdatePreviewButton()
    end)
    
    yOffset = yOffset - 35
    
    elements.gridSlider = TomoMod_Utils.CreateSlider(
        parent, "TomoModGridSizeSlider_" .. tabName, "TOPLEFT", 30, yOffset,
        16, 64, 8, 200, "Grille: " .. TomoMod_PreviewMode.GetGridSize() .. " px",
        function(self, value)
            TomoMod_PreviewMode.SetGridSize(value)
            _G[self:GetName().."Text"]:SetText("Grille: " .. math.floor(value) .. " px")
        end
    )
    elements.gridSlider:SetValue(TomoMod_PreviewMode.GetGridSize())
    
    yOffset = yOffset - 45
    
    elements.separator = parent:CreateTexture(nil, "ARTWORK")
    elements.separator:SetSize(420, 2)
    elements.separator:SetPoint("TOPLEFT", 20, yOffset)
    elements.separator:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    yOffset = yOffset - 20
    
    return yOffset, elements
end

function TomoMod_ConfigPreview.CreatePreviewSectionSimple(parent, yOffset, tabName)
    local elements = {}
    
    elements.header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    elements.header:SetPoint("TOPLEFT", 20, yOffset)
    elements.header:SetText("Mode Prévisualisation")
    elements.header:SetTextColor(1, 0.82, 0)
    
    yOffset = yOffset - 30
    
    elements.toggleBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    elements.toggleBtn:SetSize(150, 28)
    elements.toggleBtn:SetPoint("TOPLEFT", 30, yOffset)
    elements.toggleBtn:SetText("Activer Prévisualisation")
    
    elements.status = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    elements.status:SetPoint("LEFT", elements.toggleBtn, "RIGHT", 15, 0)
    elements.status:SetText("● Inactif")
    elements.status:SetTextColor(0.5, 0.5, 0.5)
    
    local function UpdatePreviewButton()
        if TomoMod_PreviewMode.IsActive() then
            elements.toggleBtn:SetText("Arrêter Prévisualisation")
            elements.status:SetText("● Actif")
            elements.status:SetTextColor(0, 1, 0)
        else
            elements.toggleBtn:SetText("Activer Prévisualisation")
            elements.status:SetText("● Inactif")
            elements.status:SetTextColor(0.5, 0.5, 0.5)
        end
    end
    
    elements.UpdateButton = UpdatePreviewButton
    
    elements.toggleBtn:SetScript("OnClick", function()
        if TomoMod_PreviewMode.IsActive() then
            TomoMod_ConfigPreview.HideForTab(tabName)
        else
            TomoMod_ConfigPreview.ShowForTab(tabName)
        end
        UpdatePreviewButton()
    end)
    
    yOffset = yOffset - 40
    
    elements.separator = parent:CreateTexture(nil, "ARTWORK")
    elements.separator:SetSize(420, 2)
    elements.separator:SetPoint("TOPLEFT", 20, yOffset)
    elements.separator:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    yOffset = yOffset - 20
    
    return yOffset, elements
end

-- =====================================
-- FONCTIONS UTILITAIRES COLOR PICKER
-- =====================================

local function ShowColorPicker(r, g, b, callback)
    local info = {
        swatchFunc = function()
            local newR, newG, newB = ColorPickerFrame:GetColorRGB()
            if callback then callback(newR, newG, newB) end
        end,
        cancelFunc = function()
            if callback then callback(r, g, b) end
        end,
        r = r,
        g = g,
        b = b,
        hasOpacity = false,
    }
    ColorPickerFrame:SetupColorPickerAndShow(info)
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
        local cr, cg, cb = colorBtn:GetBackdropColor()
        ShowColorPicker(cr, cg, cb, function(newR, newG, newB)
            colorBtn:SetBackdropColor(newR, newG, newB, 1)
            UpdateRGBText(newR, newG, newB)
            if onColorChanged then onColorChanged(newR, newG, newB) end
        end)
    end)
    
    frame.colorBtn = colorBtn
    frame.rgbText = rgbText
    return frame
end

-- =====================================
-- FONCTIONS DE CRÉATION DES ONGLETS
-- =====================================

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

function TomoMod_Config.SwitchTab(tabName)
    currentTab = tabName
    
    if configFrame.qolContent then configFrame.qolContent:Hide() end
    if configFrame.uiContent then configFrame.uiContent:Hide() end
    if configFrame.aurasContent then configFrame.aurasContent:Hide() end
    
    if tabName == "QOL" and configFrame.qolContent then
        configFrame.qolContent:Show()
    elseif tabName == "UI" and configFrame.uiContent then
        configFrame.uiContent:Show()
    elseif tabName == "Auras" and configFrame.aurasContent then
        configFrame.aurasContent:Show()
    end
    
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
    
    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("TomoMod - Configuration")
    
    configFrame.tabs = {}
    
    local qolTab = CreateTabButton(configFrame, "QOL", "QOL", "TOPLEFT", 20, -45)
    table.insert(configFrame.tabs, qolTab)
    
    local uiTab = CreateTabButton(configFrame, "UI", "UI", "LEFT", qolTab, "RIGHT", 5, 0)
    table.insert(configFrame.tabs, uiTab)
    
    local aurasTab = CreateTabButton(configFrame, "Auras", "Auras", "LEFT", uiTab, "RIGHT", 5, 0)
    table.insert(configFrame.tabs, aurasTab)
    
    local separator = configFrame:CreateTexture(nil, "ARTWORK")
    separator:SetSize(480, 2)
    separator:SetPoint("TOPLEFT", 20, -80)
    separator:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    TomoMod_Config.CreateQOLContent()
    TomoMod_Config.CreateUIContent()
    TomoMod_Config.CreateAurasContent()
    
    local closeBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    closeBtn:SetSize(100, 25)
    closeBtn:SetPoint("BOTTOM", 0, 15)
    closeBtn:SetText("Fermer")
    closeBtn:SetScript("OnClick", function()
        configFrame:Hide()
    end)
    
    local dragInfo = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dragInfo:SetPoint("BOTTOMLEFT", 20, 15)
    dragInfo:SetText("Shift + Clic = Déplacer")
    dragInfo:SetTextColor(0.7, 0.7, 0.7)
    
    local scrollInfo = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scrollInfo:SetPoint("BOTTOMRIGHT", -35, 15)
    scrollInfo:SetText("Molette pour défiler")
    scrollInfo:SetTextColor(0.7, 0.7, 0.7)
    
    TomoMod_Config.SwitchTab("QOL")
end

-- =====================================
-- CONTENU QOL
-- =====================================

function TomoMod_Config.CreateQOLContent()
    local scrollFrame = CreateFrame("ScrollFrame", "TomoModConfigScrollQoL", configFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(460, 1400)
    scrollFrame:SetScrollChild(scrollChild)
    
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = math.max(0, math.min(current - (delta * 30), maxScroll))
        self:SetVerticalScroll(newScroll)
    end)
    
    configFrame.qolContent = scrollFrame
    scrollFrame:Hide()
    
    local yOffset = -10
    local previewElements
    
    -- ========== PRÉVISUALISATION ==========
    yOffset, previewElements = TomoMod_ConfigPreview.CreatePreviewSectionSimple(scrollChild, yOffset, "qol")
    
    -- ========== SECTION MINIMAP ==========
    local minimapHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    minimapHeader:SetPoint("TOPLEFT", 20, yOffset)
    minimapHeader:SetText("Minimap")
    minimapHeader:SetTextColor(0.3, 0.8, 1)
    
    yOffset = yOffset - 25
    
    local minimapEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Activer", TomoModDB.minimap.enabled, function(self)
        TomoModDB.minimap.enabled = self:GetChecked()
        if TomoModDB.minimap.enabled then
            TomoMod_Minimap.ApplySettings()
        end
    end)
    
    yOffset = yOffset - 30
    
    local minimapSizeSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModMinimapSizeSlider", "TOPLEFT", 30, yOffset,
        150, 300, 10, 250, "Taille: " .. TomoModDB.minimap.size,
        function(self, value)
            TomoModDB.minimap.size = value
            _G[self:GetName().."Text"]:SetText("Taille: " .. math.floor(value))
            Minimap:SetSize(value, value)
        end
    )
    minimapSizeSlider:SetValue(TomoModDB.minimap.size)
    
    yOffset = yOffset - 50
    
    local minimapScaleSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModMinimapScaleSlider", "TOPLEFT", 30, yOffset,
        0.5, 2.0, 0.1, 250, "Échelle: " .. TomoModDB.minimap.scale,
        function(self, value)
            TomoModDB.minimap.scale = value
            _G[self:GetName().."Text"]:SetText("Échelle: " .. string.format("%.1f", value))
            TomoMod_Minimap.ApplyScale()
        end
    )
    minimapScaleSlider:SetValue(TomoModDB.minimap.scale)
    
    yOffset = yOffset - 45
    
    local minimapBorderLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minimapBorderLabel:SetPoint("TOPLEFT", 30, yOffset)
    minimapBorderLabel:SetText("Bordure:")
    
    local minimapClassBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    minimapClassBtn:SetSize(100, 25)
    minimapClassBtn:SetPoint("TOPLEFT", 100, yOffset)
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
    
    yOffset = yOffset - 40
    
    local sep1 = scrollChild:CreateTexture(nil, "ARTWORK")
    sep1:SetSize(420, 2)
    sep1:SetPoint("TOPLEFT", 20, yOffset)
    sep1:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    yOffset = yOffset - 20
    
    -- ========== SECTION INFO PANEL ==========
    local panelHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panelHeader:SetPoint("TOPLEFT", 20, yOffset)
    panelHeader:SetText("Info Panel")
    panelHeader:SetTextColor(0.3, 0.8, 1)
    
    yOffset = yOffset - 25
    
    local panelEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Activer", TomoModDB.infoPanel.enabled, function(self)
        TomoModDB.infoPanel.enabled = self:GetChecked()
        if TomoModDB.infoPanel.enabled then
            TomoMod_InfoPanel.Initialize()
        else
            local panel = _G["TomoModInfoPanel"]
            if panel then panel:Hide() end
        end
    end)
    
    yOffset = yOffset - 25
    
    local durabilityCheck = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Durabilité (Gear)", TomoModDB.infoPanel.showDurability, function(self)
        TomoModDB.infoPanel.showDurability = self:GetChecked()
        TomoMod_InfoPanel.Update()
    end)
    
    yOffset = yOffset - 25
    
    local timeCheck = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Heure (Time)", TomoModDB.infoPanel.showTime, function(self)
        TomoModDB.infoPanel.showTime = self:GetChecked()
        TomoMod_InfoPanel.Update()
    end)
    
    yOffset = yOffset - 25
    
    local format24Check = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 50, yOffset, "Format 24h", TomoModDB.infoPanel.use24Hour, function(self)
        TomoModDB.infoPanel.use24Hour = self:GetChecked()
        TomoMod_InfoPanel.Update()
    end)
    
    yOffset = yOffset - 25
    
    local fpsCheck = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "FPS (Fps)", TomoModDB.infoPanel.showFPS, function(self)
        TomoModDB.infoPanel.showFPS = self:GetChecked()
        TomoMod_InfoPanel.Update()
    end)
    
    yOffset = yOffset - 35
    
    local panelScaleSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModPanelScaleSlider", "TOPLEFT", 30, yOffset,
        0.5, 2.0, 0.1, 250, "Échelle: " .. TomoModDB.infoPanel.scale,
        function(self, value)
            TomoModDB.infoPanel.scale = value
            _G[self:GetName().."Text"]:SetText("Échelle: " .. string.format("%.1f", value))
            TomoMod_InfoPanel.UpdateAppearance()
        end
    )
    panelScaleSlider:SetValue(TomoModDB.infoPanel.scale)
    
    yOffset = yOffset - 50
    
    local panelBorderLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panelBorderLabel:SetPoint("TOPLEFT", 30, yOffset)
    panelBorderLabel:SetText("Bordure:")
    
    local panelBlackBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    panelBlackBtn:SetSize(100, 25)
    panelBlackBtn:SetPoint("TOPLEFT", 100, yOffset)
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
    
    local resetBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 25)
    resetBtn:SetPoint("LEFT", panelClassBtn, "RIGHT", 10, 0)
    resetBtn:SetText("Reset Position")
    resetBtn:SetScript("OnClick", function()
        TomoModDB.infoPanel.position = nil
        TomoMod_InfoPanel.SetPosition()
    end)
    
    yOffset = yOffset - 40
    
    local sep2 = scrollChild:CreateTexture(nil, "ARTWORK")
    sep2:SetSize(420, 2)
    sep2:SetPoint("TOPLEFT", 20, yOffset)
    sep2:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    yOffset = yOffset - 20
    
    -- ========== TOOLTIP ==========
    local tooltipHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    tooltipHeader:SetPoint("TOPLEFT", 20, yOffset)
    tooltipHeader:SetText("Tooltip")
    tooltipHeader:SetTextColor(0.4, 0.8, 1)
    
    yOffset = yOffset - 25
    
    local tooltipEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Activer les améliorations", TomoModDB.tooltip.enabled, function(self)
        TomoModDB.tooltip.enabled = self:GetChecked()
    end)
    
    yOffset = yOffset - 25
    
    local colorBorder = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Bordure colorée selon la cible", TomoModDB.tooltip.colorBorder, function(self)
        TomoModDB.tooltip.colorBorder = self:GetChecked()
    end)
    
    yOffset = yOffset - 25
    
    local colorName = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Nom coloré selon la cible", TomoModDB.tooltip.colorName, function(self)
        TomoModDB.tooltip.colorName = self:GetChecked()
    end)
    
    yOffset = yOffset - 25
    
    local improveBackdrop = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Améliorer l'apparence du fond", TomoModDB.tooltip.improveBackdrop, function(self)
        TomoModDB.tooltip.improveBackdrop = self:GetChecked()
    end)
    
    yOffset = yOffset - 30
    
    local legendHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    legendHeader:SetPoint("TOPLEFT", 30, yOffset)
    legendHeader:SetText("Légende des couleurs :")
    legendHeader:SetTextColor(0.8, 0.8, 0.8)
    
    yOffset = yOffset - 20
    
    local colors = {
        {label = "Joueur", desc = "Couleur de classe", r = 0.78, g = 0.61, b = 0.43},
        {label = "PNJ Amical", desc = "Vert", r = 0, g = 0.8, b = 0},
        {label = "PNJ Neutre", desc = "Jaune", r = 1, g = 0.82, b = 0},
        {label = "PNJ Hostile", desc = "Rouge", r = 0.8, g = 0, b = 0},
        {label = "Mort", desc = "Gris", r = 0.5, g = 0.5, b = 0.5},
    }
    
    for _, colorInfo in ipairs(colors) do
        local colorSwatch = scrollChild:CreateTexture(nil, "ARTWORK")
        colorSwatch:SetSize(14, 14)
        colorSwatch:SetPoint("TOPLEFT", 40, yOffset)
        colorSwatch:SetColorTexture(colorInfo.r, colorInfo.g, colorInfo.b, 1)
        
        local label = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", colorSwatch, "RIGHT", 8, 0)
        label:SetText(colorInfo.label .. " - " .. colorInfo.desc)
        label:SetTextColor(0.7, 0.7, 0.7)
        
        yOffset = yOffset - 18
    end
    
    yOffset = yOffset - 15
    
    local sep3 = scrollChild:CreateTexture(nil, "ARTWORK")
    sep3:SetSize(420, 2)
    sep3:SetPoint("TOPLEFT", 20, yOffset)
    sep3:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    yOffset = yOffset - 20
    
    -- ========== CURSOR RING ==========
    local cursorHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    cursorHeader:SetPoint("TOPLEFT", 20, yOffset)
    cursorHeader:SetText("Cursor Ring")
    cursorHeader:SetTextColor(0.4, 0.8, 1)
    
    yOffset = yOffset - 25
    
    local cursorEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Activer l'anneau de curseur", TomoModDB.cursorRing.enabled, function(self)
        TomoModDB.cursorRing.enabled = self:GetChecked()
    end)
    
    yOffset = yOffset - 25
    
    local cursorClassColor = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Couleur de classe", TomoModDB.cursorRing.useClassColor, function(self)
        TomoModDB.cursorRing.useClassColor = self:GetChecked()
    end)
    
    local cursorAnchorTooltip = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 200, yOffset, "Ancrer le tooltip", TomoModDB.cursorRing.anchorTooltip, function(self)
        TomoModDB.cursorRing.anchorTooltip = self:GetChecked()
    end)
    
    yOffset = yOffset - 35
    
    local cursorScaleSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModCursorScaleSlider", "TOPLEFT", 30, yOffset,
        0.5, 2.0, 0.1, 200, "Échelle: " .. string.format("%.1f", TomoModDB.cursorRing.scale or 1),
        function(self, value)
            TomoModDB.cursorRing.scale = value
            _G[self:GetName().."Text"]:SetText("Échelle: " .. string.format("%.1f", value))
        end
    )
    cursorScaleSlider:SetValue(TomoModDB.cursorRing.scale or 1)
    
    yOffset = yOffset - 50
    
    local sep4 = scrollChild:CreateTexture(nil, "ARTWORK")
    sep4:SetSize(420, 2)
    sep4:SetPoint("TOPLEFT", 20, yOffset)
    sep4:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    yOffset = yOffset - 20
    
    -- ========== CINEMATIC SKIP ==========
    local cinematicHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    cinematicHeader:SetPoint("TOPLEFT", 20, yOffset)
    cinematicHeader:SetText("Cinematic Skip")
    cinematicHeader:SetTextColor(0.4, 0.8, 1)
    
    yOffset = yOffset - 25
    
    local cinematicEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Passer les cinématiques déjà vues", TomoModDB.cinematicSkip.enabled, function(self)
        TomoModDB.cinematicSkip.enabled = self:GetChecked()
    end)
    
    yOffset = yOffset - 30
    
    local resetCinematicBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetCinematicBtn:SetSize(180, 22)
    resetCinematicBtn:SetPoint("TOPLEFT", 30, yOffset)
    resetCinematicBtn:SetText("Réinitialiser les cinématiques")
    resetCinematicBtn:SetScript("OnClick", function()
        TomoModDB.cinematicSkip.viewedCinematics = {}
        print("|cff00ff00TomoMod:|r Liste des cinématiques vues réinitialisée")
    end)
    
    yOffset = yOffset - 30
    
    local cinematicInfoText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cinematicInfoText:SetPoint("TOPLEFT", 30, yOffset)
    cinematicInfoText:SetWidth(400)
    cinematicInfoText:SetJustifyH("LEFT")
    cinematicInfoText:SetText("Les cinématiques sont skippées automatiquement après la première visualisation.\nL'historique est partagé entre tous vos personnages.")
    cinematicInfoText:SetTextColor(0.6, 0.6, 0.6)
    
    yOffset = yOffset - 40
    
    local sep5 = scrollChild:CreateTexture(nil, "ARTWORK")
    sep5:SetSize(420, 2)
    sep5:SetPoint("TOPLEFT", 20, yOffset)
    sep5:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    yOffset = yOffset - 20
    
    -- ========== AUTO QUEST ==========
    local autoQuestHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    autoQuestHeader:SetPoint("TOPLEFT", 20, yOffset)
    autoQuestHeader:SetText("Auto Quest")
    autoQuestHeader:SetTextColor(0.4, 0.8, 1)
    
    yOffset = yOffset - 25
    
    local autoAccept = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Accepter automatiquement les quêtes", TomoModDB.autoQuest.autoAccept, function(self)
        TomoModDB.autoQuest.autoAccept = self:GetChecked()
    end)
    
    yOffset = yOffset - 25
    
    local autoTurnIn = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Rendre automatiquement les quêtes", TomoModDB.autoQuest.autoTurnIn, function(self)
        TomoModDB.autoQuest.autoTurnIn = self:GetChecked()
    end)
    
    yOffset = yOffset - 25
    
    local autoGossip = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Passer automatiquement les dialogues", TomoModDB.autoQuest.autoGossip, function(self)
        TomoModDB.autoQuest.autoGossip = self:GetChecked()
    end)
    
    yOffset = yOffset - 30
    
    local questInfoText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    questInfoText:SetPoint("TOPLEFT", 30, yOffset)
    questInfoText:SetWidth(400)
    questInfoText:SetJustifyH("LEFT")
    questInfoText:SetText("Maintenez SHIFT pour désactiver temporairement l'auto-acceptation.\nLes quêtes avec choix de récompenses multiples ne seront pas auto-complétées.")
    questInfoText:SetTextColor(0.6, 0.6, 0.6)
    
    yOffset = yOffset - 50
    
    -- Note finale
    local noteText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    noteText:SetPoint("TOPLEFT", 20, yOffset)
    noteText:SetWidth(420)
    noteText:SetJustifyH("LEFT")
    noteText:SetText("Note: /reload nécessaire pour appliquer certains changements d'activation.")
    noteText:SetTextColor(0.5, 0.5, 0.5)
    
    scrollFrame:SetScript("OnShow", function()
        if previewElements and previewElements.UpdateButton then
            previewElements.UpdateButton()
        end
    end)
end

-- =====================================
-- CONTENU UI
-- =====================================

function TomoMod_Config.CreateUIContent()
    local scrollFrame = CreateFrame("ScrollFrame", "TomoModConfigScrollUI", configFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(460, 2400)
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
    local previewElements
    
    -- ========== PRÉVISUALISATION ==========
    yOffset, previewElements = TomoMod_ConfigPreview.CreatePreviewSection(scrollChild, yOffset, "ui")
    
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
    
    local playerClassColor = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Couleur de classe", TomoModDB.unitFrames.player.useClassColor, function(self)
        TomoModDB.unitFrames.player.useClassColor = self:GetChecked()
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
    
    local playerInfo = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playerInfo:SetPoint("LEFT", resetPlayerPosBtn, "RIGHT", 15, 0)
    playerInfo:SetText("Clic gauche = cibler, Clic droit = menu")
    playerInfo:SetTextColor(0.6, 0.6, 0.6)
    
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
    
    local targetClassColor = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Couleur classe/réaction", TomoModDB.unitFrames.target.useClassColor, function(self)
        TomoModDB.unitFrames.target.useClassColor = self:GetChecked()
        TomoMod_UnitFrames.UpdateTargetSettings()
    end)
    
    local targetPowerBar = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 220, yOffset, "Barre de ressource", TomoModDB.unitFrames.target.showPowerBar, function(self)
        TomoModDB.unitFrames.target.showPowerBar = self:GetChecked()
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
    
    yOffset = yOffset - 30
    
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
    
    local targetInfo = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    targetInfo:SetPoint("LEFT", resetTargetPosBtn, "RIGHT", 15, 0)
    targetInfo:SetText("Clic gauche = cibler, Clic droit = menu")
    targetInfo:SetTextColor(0.6, 0.6, 0.6)
    
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
    
    local totMinimalist = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 200, yOffset, "Mode Minimaliste", TomoModDB.unitFrames.targetoftarget.minimalist, function(self)
        TomoModDB.unitFrames.targetoftarget.minimalist = self:GetChecked()
        TomoMod_UnitFrames.UpdateToTSettings()
    end)
    
    yOffset = yOffset - 22
    
    local totClassColor = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Couleur classe/réaction", TomoModDB.unitFrames.targetoftarget.useClassColor, function(self)
        TomoModDB.unitFrames.targetoftarget.useClassColor = self:GetChecked()
        TomoMod_UnitFrames.UpdateToTSettings()
    end)
    
    local totTruncate = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 220, yOffset, "Tronquer le nom", TomoModDB.unitFrames.targetoftarget.truncateName, function(self)
        TomoModDB.unitFrames.targetoftarget.truncateName = self:GetChecked()
        TomoMod_UnitFrames.UpdateToTSettings()
    end)
    
    yOffset = yOffset - 30
    
    local totWidthSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModToTWidthSlider", "TOPLEFT", 30, yOffset,
        60, 150, 5, 130, "Largeur: " .. TomoModDB.unitFrames.targetoftarget.width,
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
        scrollChild, "TomoModToTScaleSlider", "TOPLEFT", 180, yOffset,
        0.5, 2.0, 0.1, 130, "Scale: " .. TomoModDB.unitFrames.targetoftarget.scale,
        function(self, value)
            TomoModDB.unitFrames.targetoftarget.scale = value
            _G[self:GetName().."Text"]:SetText("Scale: " .. string.format("%.1f", value))
            TomoMod_UnitFrames.UpdateToTSettings()
        end
    )
    totScaleSlider:SetValue(TomoModDB.unitFrames.targetoftarget.scale)
    
    yOffset = yOffset - 50
    
    local totTruncLenSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModToTTruncLenSlider", "TOPLEFT", 30, yOffset,
        3, 15, 1, 200, "Longueur nom max: " .. TomoModDB.unitFrames.targetoftarget.truncateNameLength,
        function(self, value)
            TomoModDB.unitFrames.targetoftarget.truncateNameLength = value
            _G[self:GetName().."Text"]:SetText("Longueur nom max: " .. math.floor(value))
            TomoMod_UnitFrames.UpdateToTSettings()
        end
    )
    totTruncLenSlider:SetValue(TomoModDB.unitFrames.targetoftarget.truncateNameLength)
    
    yOffset = yOffset - 45
    
    local resetToTPosBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetToTPosBtn:SetSize(120, 22)
    resetToTPosBtn:SetPoint("TOPLEFT", 30, yOffset)
    resetToTPosBtn:SetText("Reset Position")
    resetToTPosBtn:SetScript("OnClick", function()
        TomoMod_UnitFrames.ResetToTPosition()
    end)
    
    yOffset = yOffset - 50
    
    local infoText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", 20, yOffset)
    infoText:SetWidth(420)
    infoText:SetJustifyH("LEFT")
    infoText:SetText("Notes:\n• Player: Pas de barre de ressource, barre d'absorption bleue\n• Target: Barre de ressource optionnelle\n• ToT: Nom tronqué avec \"...\" si activé\n• Textes en blanc avec outline noir\n• /reload nécessaire pour activer/désactiver")
    infoText:SetTextColor(0.5, 0.5, 0.5)
    
    scrollFrame:SetScript("OnShow", function()
        if previewElements and previewElements.UpdateButton then
            previewElements.UpdateButton()
        end
    end)
end

-- =====================================
-- CONTENU AURAS
-- =====================================

function TomoMod_Config.CreateAurasContent()
    local scrollFrame = CreateFrame("ScrollFrame", "TomoModConfigScrollAuras", configFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(460, 900)
    scrollFrame:SetScrollChild(scrollChild)
    
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = math.max(0, math.min(current - (delta * 30), maxScroll))
        self:SetVerticalScroll(newScroll)
    end)
    
    configFrame.aurasContent = scrollFrame
    scrollFrame:Hide()
    
    local yOffset = -10
    local previewElements
    
    -- ========== PRÉVISUALISATION ==========
    yOffset, previewElements = TomoMod_ConfigPreview.CreatePreviewSection(scrollChild, yOffset, "auras")
    
    -- ========== PLAYER DEBUFFS ==========
    local playerHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    playerHeader:SetPoint("TOPLEFT", 20, yOffset)
    playerHeader:SetText("Debuffs Joueur")
    playerHeader:SetTextColor(0.8, 0.3, 0.3)
    
    yOffset = yOffset - 25
    
    local playerEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Activer", TomoModDB.auras.playerDebuffs.enabled, function(self)
        TomoModDB.auras.playerDebuffs.enabled = self:GetChecked()
    end)
    
    yOffset = yOffset - 30
    
    local playerCountSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModPlayerDebuffCountSlider", "TOPLEFT", 30, yOffset,
        2, 8, 1, 200, "Nombre de debuffs: " .. (TomoModDB.auras.playerDebuffs.count or 8),
        function(self, value)
            TomoModDB.auras.playerDebuffs.count = value
            _G[self:GetName().."Text"]:SetText("Nombre de debuffs: " .. math.floor(value))
            TomoMod_Auras.UpdatePlayerDebuffSettings()
        end
    )
    playerCountSlider:SetValue(TomoModDB.auras.playerDebuffs.count or 8)
    
    yOffset = yOffset - 50
    
    local playerScaleSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModPlayerDebuffScaleSlider", "TOPLEFT", 30, yOffset,
        0.5, 2.0, 0.1, 200, "Échelle: " .. string.format("%.1f", TomoModDB.auras.playerDebuffs.scale or 1),
        function(self, value)
            TomoModDB.auras.playerDebuffs.scale = value
            _G[self:GetName().."Text"]:SetText("Échelle: " .. string.format("%.1f", value))
            TomoMod_Auras.UpdatePlayerDebuffSettings()
        end
    )
    playerScaleSlider:SetValue(TomoModDB.auras.playerDebuffs.scale or 1)
    
    yOffset = yOffset - 50
    
    local playerDirectionLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerDirectionLabel:SetPoint("TOPLEFT", 30, yOffset)
    playerDirectionLabel:SetText("Direction de croissance:")
    
    yOffset = yOffset - 25
    
    local playerDirections = {"LEFT", "RIGHT", "UP", "DOWN"}
    local playerDirectionLabels = {"Gauche", "Droite", "Haut", "Bas"}
    local playerDirectionBtns = {}
    
    for i, dir in ipairs(playerDirections) do
        local btn = CreateFrame("CheckButton", nil, scrollChild, "UIRadioButtonTemplate")
        btn:SetPoint("TOPLEFT", 30 + ((i-1) * 100), yOffset)
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("LEFT", btn, "RIGHT", 2, 0)
        btn.text:SetText(playerDirectionLabels[i])
        
        btn:SetScript("OnClick", function()
            TomoModDB.auras.playerDebuffs.growDirection = dir
            for _, b in ipairs(playerDirectionBtns) do
                b:SetChecked(false)
            end
            btn:SetChecked(true)
            TomoMod_Auras.UpdatePlayerDebuffSettings()
        end)
        
        if (TomoModDB.auras.playerDebuffs.growDirection or "LEFT") == dir then
            btn:SetChecked(true)
        end
        
        playerDirectionBtns[i] = btn
    end
    
    yOffset = yOffset - 30
    
    local resetPlayerPosBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetPlayerPosBtn:SetSize(120, 22)
    resetPlayerPosBtn:SetPoint("TOPLEFT", 30, yOffset)
    resetPlayerPosBtn:SetText("Reset Position")
    resetPlayerPosBtn:SetScript("OnClick", function()
        TomoMod_Auras.ResetPlayerDebuffPosition()
    end)
    
    yOffset = yOffset - 40
    
    local sep2 = scrollChild:CreateTexture(nil, "ARTWORK")
    sep2:SetSize(420, 2)
    sep2:SetPoint("TOPLEFT", 20, yOffset)
    sep2:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    yOffset = yOffset - 20
    
    -- ========== TARGET DEBUFFS ==========
    local targetHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    targetHeader:SetPoint("TOPLEFT", 20, yOffset)
    targetHeader:SetText("Debuffs Cible")
    targetHeader:SetTextColor(0.8, 0.5, 0.2)
    
    yOffset = yOffset - 25
    
    local targetEnable = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 30, yOffset, "Activer", TomoModDB.auras.targetDebuffs.enabled, function(self)
        TomoModDB.auras.targetDebuffs.enabled = self:GetChecked()
    end)
    
    local targetOnlyMine = TomoMod_Utils.CreateCheckbox(scrollChild, "TOPLEFT", 200, yOffset, "Mes debuffs uniquement", TomoModDB.auras.targetDebuffs.onlyMine, function(self)
        TomoModDB.auras.targetDebuffs.onlyMine = self:GetChecked()
        TomoMod_Auras.UpdateTargetDebuffSettings()
    end)
    
    yOffset = yOffset - 30
    
    local targetCountSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModTargetDebuffCountSlider", "TOPLEFT", 30, yOffset,
        2, 8, 1, 200, "Debuffs par ligne: " .. (TomoModDB.auras.targetDebuffs.countPerRow or 8),
        function(self, value)
            TomoModDB.auras.targetDebuffs.countPerRow = value
            _G[self:GetName().."Text"]:SetText("Debuffs par ligne: " .. math.floor(value))
            TomoMod_Auras.UpdateTargetDebuffSettings()
        end
    )
    targetCountSlider:SetValue(TomoModDB.auras.targetDebuffs.countPerRow or 8)
    
    yOffset = yOffset - 50
    
    local targetRowsSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModTargetDebuffRowsSlider", "TOPLEFT", 30, yOffset,
        1, 2, 1, 200, "Nombre de lignes: " .. (TomoModDB.auras.targetDebuffs.rows or 1),
        function(self, value)
            TomoModDB.auras.targetDebuffs.rows = value
            _G[self:GetName().."Text"]:SetText("Nombre de lignes: " .. math.floor(value))
            TomoMod_Auras.UpdateTargetDebuffSettings()
        end
    )
    targetRowsSlider:SetValue(TomoModDB.auras.targetDebuffs.rows or 1)
    
    yOffset = yOffset - 50
    
    local targetScaleSlider = TomoMod_Utils.CreateSlider(
        scrollChild, "TomoModTargetDebuffScaleSlider", "TOPLEFT", 30, yOffset,
        0.5, 2.0, 0.1, 200, "Échelle: " .. string.format("%.1f", TomoModDB.auras.targetDebuffs.scale or 1),
        function(self, value)
            TomoModDB.auras.targetDebuffs.scale = value
            _G[self:GetName().."Text"]:SetText("Échelle: " .. string.format("%.1f", value))
            TomoMod_Auras.UpdateTargetDebuffSettings()
        end
    )
    targetScaleSlider:SetValue(TomoModDB.auras.targetDebuffs.scale or 1)
    
    yOffset = yOffset - 50
    
    local targetHDirLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    targetHDirLabel:SetPoint("TOPLEFT", 30, yOffset)
    targetHDirLabel:SetText("Direction horizontale:")
    
    yOffset = yOffset - 25
    
    local targetHDirections = {"RIGHT", "LEFT"}
    local targetHDirLabels = {"Droite", "Gauche"}
    local targetHDirBtns = {}
    
    for i, dir in ipairs(targetHDirections) do
        local btn = CreateFrame("CheckButton", nil, scrollChild, "UIRadioButtonTemplate")
        btn:SetPoint("TOPLEFT", 30 + ((i-1) * 100), yOffset)
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("LEFT", btn, "RIGHT", 2, 0)
        btn.text:SetText(targetHDirLabels[i])
        
        btn:SetScript("OnClick", function()
            TomoModDB.auras.targetDebuffs.growDirection = dir
            for _, b in ipairs(targetHDirBtns) do
                b:SetChecked(false)
            end
            btn:SetChecked(true)
            TomoMod_Auras.UpdateTargetDebuffSettings()
        end)
        
        if (TomoModDB.auras.targetDebuffs.growDirection or "RIGHT") == dir then
            btn:SetChecked(true)
        end
        
        targetHDirBtns[i] = btn
    end
    
    yOffset = yOffset - 30
    
    local targetVDirLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    targetVDirLabel:SetPoint("TOPLEFT", 30, yOffset)
    targetVDirLabel:SetText("Direction des lignes:")
    
    yOffset = yOffset - 25
    
    local targetVDirections = {"DOWN", "UP"}
    local targetVDirLabels = {"Bas", "Haut"}
    local targetVDirBtns = {}
    
    for i, dir in ipairs(targetVDirections) do
        local btn = CreateFrame("CheckButton", nil, scrollChild, "UIRadioButtonTemplate")
        btn:SetPoint("TOPLEFT", 30 + ((i-1) * 100), yOffset)
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("LEFT", btn, "RIGHT", 2, 0)
        btn.text:SetText(targetVDirLabels[i])
        
        btn:SetScript("OnClick", function()
            TomoModDB.auras.targetDebuffs.rowDirection = dir
            for _, b in ipairs(targetVDirBtns) do
                b:SetChecked(false)
            end
            btn:SetChecked(true)
            TomoMod_Auras.UpdateTargetDebuffSettings()
        end)
        
        if (TomoModDB.auras.targetDebuffs.rowDirection or "DOWN") == dir then
            btn:SetChecked(true)
        end
        
        targetVDirBtns[i] = btn
    end
    
    yOffset = yOffset - 35
    
    local resetTargetPosBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetTargetPosBtn:SetSize(120, 22)
    resetTargetPosBtn:SetPoint("TOPLEFT", 30, yOffset)
    resetTargetPosBtn:SetText("Reset Position")
    resetTargetPosBtn:SetScript("OnClick", function()
        TomoMod_Auras.ResetTargetDebuffPosition()
    end)
    
    yOffset = yOffset - 50
    
    local infoText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", 20, yOffset)
    infoText:SetWidth(420)
    infoText:SetJustifyH("LEFT")
    infoText:SetText("Notes:\n• Les ancres sont visibles uniquement en mode prévisualisation\n• L'ancre représente la position du premier debuff\n• Couleurs: Rouge=Physique, Violet=Magie, Vert=Poison, Marron=Maladie, Bleu=Curse\n• /reload nécessaire pour activer/désactiver")
    infoText:SetTextColor(0.5, 0.5, 0.5)
    
    scrollFrame:SetScript("OnShow", function()
        if previewElements and previewElements.UpdateButton then
            previewElements.UpdateButton()
        end
    end)
end

-- =====================================
-- TOGGLE
-- =====================================

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
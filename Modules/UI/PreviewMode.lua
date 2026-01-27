-- =====================================
-- PreviewMode.lua
-- Système de prévisualisation généralisé pour l'UI
-- =====================================

TomoMod_PreviewMode = {}

local isPreviewActive = false
local gridFrame = nil
local gridSize = 32 -- Taille par défaut de la grille
local overlayFrames = {} -- Stocke les overlays jaunes pour chaque élément

-- =====================================
-- GRILLE D'ALIGNEMENT
-- =====================================

local function CreateGrid()
    if gridFrame then return gridFrame end
    
    gridFrame = CreateFrame("Frame", "TomoModPreviewGrid", UIParent)
    gridFrame:SetAllPoints(UIParent)
    gridFrame:SetFrameStrata("BACKGROUND")
    gridFrame:Hide()
    
    gridFrame.lines = {}
    
    return gridFrame
end

local function UpdateGrid()
    if not gridFrame then CreateGrid() end
    
    -- Supprimer les anciennes lignes
    for _, line in ipairs(gridFrame.lines) do
        line:Hide()
        line:SetParent(nil)
    end
    gridFrame.lines = {}
    
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    
    -- Couleur de la grille (gris semi-transparent)
    local r, g, b, a = 0.3, 0.3, 0.3, 0.4
    
    -- Lignes verticales
    for x = 0, screenWidth, gridSize do
        local line = gridFrame:CreateTexture(nil, "BACKGROUND")
        line:SetColorTexture(r, g, b, a)
        line:SetSize(1, screenHeight)
        line:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", x, 0)
        table.insert(gridFrame.lines, line)
    end
    
    -- Lignes horizontales
    for y = 0, screenHeight, gridSize do
        local line = gridFrame:CreateTexture(nil, "BACKGROUND")
        line:SetColorTexture(r, g, b, a)
        line:SetSize(screenWidth, 1)
        line:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", 0, -y)
        table.insert(gridFrame.lines, line)
    end
    
    -- Lignes centrales (plus visibles)
    local centerLineV = gridFrame:CreateTexture(nil, "BACKGROUND")
    centerLineV:SetColorTexture(0.5, 0.5, 0.5, 0.6)
    centerLineV:SetSize(2, screenHeight)
    centerLineV:SetPoint("CENTER", gridFrame, "CENTER", 0, 0)
    table.insert(gridFrame.lines, centerLineV)
    
    local centerLineH = gridFrame:CreateTexture(nil, "BACKGROUND")
    centerLineH:SetColorTexture(0.5, 0.5, 0.5, 0.6)
    centerLineH:SetSize(screenWidth, 2)
    centerLineH:SetPoint("CENTER", gridFrame, "CENTER", 0, 0)
    table.insert(gridFrame.lines, centerLineH)
end

function TomoMod_PreviewMode.SetGridSize(size)
    gridSize = size
    if isPreviewActive then
        UpdateGrid()
    end
end

function TomoMod_PreviewMode.GetGridSize()
    return gridSize
end

-- =====================================
-- OVERLAY JAUNE POUR LES ÉLÉMENTS
-- =====================================

local function CreateYellowOverlay(frame, name)
    if not frame then return nil end
    
    local overlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    overlay:SetAllPoints(frame)
    overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
    
    -- Bordure jaune
    overlay:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    overlay:SetBackdropBorderColor(1, 0.82, 0, 1) -- Jaune doré
    
    -- Fond jaune semi-transparent
    overlay.bg = overlay:CreateTexture(nil, "BACKGROUND")
    overlay.bg:SetAllPoints()
    overlay.bg:SetColorTexture(1, 0.82, 0, 0.15)
    
    -- Label du nom
    overlay.label = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    overlay.label:SetPoint("TOP", overlay, "TOP", 0, -2)
    overlay.label:SetText(name or "Element")
    overlay.label:SetTextColor(1, 0.82, 0, 1)
    
    overlay:Hide()
    
    return overlay
end

-- =====================================
-- GESTION DES ÉLÉMENTS PRÉVISUALISABLES
-- =====================================

local previewableElements = {}

function TomoMod_PreviewMode.RegisterElement(frame, name, onDragStop)
    if not frame then return end
    
    local element = {
        frame = frame,
        name = name,
        onDragStop = onDragStop,
        overlay = CreateYellowOverlay(frame, name),
        originalMovable = frame:IsMovable(),
        originalMouseEnabled = frame:IsMouseEnabled(),
    }
    
    previewableElements[name] = element
end

function TomoMod_PreviewMode.UnregisterElement(name)
    if previewableElements[name] then
        if previewableElements[name].overlay then
            previewableElements[name].overlay:Hide()
            previewableElements[name].overlay:SetParent(nil)
        end
        previewableElements[name] = nil
    end
end

-- =====================================
-- ACTIVATION / DÉSACTIVATION
-- =====================================

function TomoMod_PreviewMode.Start()
    if isPreviewActive then return end
    isPreviewActive = true
    
    -- Afficher la grille
    if not gridFrame then CreateGrid() end
    UpdateGrid()
    gridFrame:Show()
    
    -- Activer tous les éléments enregistrés
    for name, element in pairs(previewableElements) do
        local frame = element.frame
        
        if frame then
            -- Rendre déplaçable
            frame:SetMovable(true)
            frame:EnableMouse(true)
            frame:RegisterForDrag("LeftButton")
            
            -- Script de drag
            frame:SetScript("OnDragStart", function(self)
                self:StartMoving()
            end)
            
            frame:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()
                if element.onDragStop then
                    element.onDragStop(self)
                end
            end)
            
            -- Afficher l'overlay jaune
            if element.overlay then
                element.overlay:Show()
            end
            
            -- S'assurer que le frame est visible
            frame:Show()
        end
    end
    
    print("|cff00ff00TomoMod:|r Mode prévisualisation activé - Déplacez les éléments puis cliquez sur Arrêter")
end

function TomoMod_PreviewMode.Stop()
    if not isPreviewActive then return end
    isPreviewActive = false
    
    -- Cacher la grille
    if gridFrame then
        gridFrame:Hide()
    end
    
    -- Désactiver tous les éléments
    for name, element in pairs(previewableElements) do
        local frame = element.frame
        
        if frame then
            -- Restaurer l'état original
            frame:SetMovable(element.originalMovable)
            frame:EnableMouse(element.originalMouseEnabled)
            
            -- Retirer les scripts de drag (sauf si shift est maintenu)
            frame:SetScript("OnDragStart", function(self)
                if IsShiftKeyDown() then
                    self:StartMoving()
                end
            end)
            
            frame:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()
                if element.onDragStop then
                    element.onDragStop(self)
                end
            end)
            
            -- Cacher l'overlay jaune
            if element.overlay then
                element.overlay:Hide()
            end
        end
    end
    
    print("|cff00ff00TomoMod:|r Mode prévisualisation arrêté - Positions sauvegardées")
end

function TomoMod_PreviewMode.Toggle()
    if isPreviewActive then
        TomoMod_PreviewMode.Stop()
    else
        TomoMod_PreviewMode.Start()
    end
end

function TomoMod_PreviewMode.IsActive()
    return isPreviewActive
end

-- =====================================
-- FONCTIONS UTILITAIRES
-- =====================================

-- Fonction pour sauvegarder la position d'un frame
function TomoMod_PreviewMode.SavePosition(frame, dbTable)
    if not frame or not dbTable then return end
    
    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
    dbTable.position = {
        point = point,
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs
    }
end

-- Fonction pour charger la position d'un frame
function TomoMod_PreviewMode.LoadPosition(frame, dbTable, defaultX, defaultY)
    if not frame then return end
    
    frame:ClearAllPoints()
    
    if dbTable and dbTable.position then
        local pos = dbTable.position
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", defaultX or 0, defaultY or 0)
    end
end

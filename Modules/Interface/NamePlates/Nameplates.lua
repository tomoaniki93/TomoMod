-- =====================================
-- TomoPlates.lua 
-- Système de Nameplates personnalisé pour TomoMod
-- Sans dépendances de textures externes
-- =====================================

TomoMod_Nameplates = TomoMod_Nameplates or {}
local Nameplates = TomoMod_Nameplates

-- =====================================
-- VARIABLES LOCALES
-- =====================================
local plates = {}
local activeNameplates = {}

-- APIs locales pour performance
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitName, UnitGUID = UnitName, UnitGUID
local UnitIsUnit, UnitCanAttack = UnitIsUnit, UnitCanAttack
local UnitIsEnemy, UnitIsTapDenied = UnitIsEnemy, UnitIsTapDenied
local UnitReaction = UnitReaction
local UnitIsPlayer, UnitClass = UnitIsPlayer, UnitClass
local UnitLevel, UnitEffectiveLevel = UnitLevel, UnitEffectiveLevel
local UnitClassification = UnitClassification
local GetThreatStatusColor = GetThreatStatusColor
local UnitThreatSituation = UnitThreatSituation
local C_NamePlate = C_NamePlate

-- =====================================
-- HELPER FUNCTIONS
-- =====================================

-- Obtenir les paramètres (avec fallback sur defaults)
local function GetSettings()
    return TomoModDB and TomoModDB.nameplates or {}
end

-- Obtenir une couleur avec fallback
local function GetColor(key)
    local settings = GetSettings()
    local color = settings.colors and settings.colors[key]
    if color then
        return color.r, color.g, color.b
    end
    return 1, 1, 1 -- blanc par défaut
end

-- Assombrir une couleur (pour unités hors combat)
local function DarkenColor(r, g, b, factor)
    factor = factor or 0.5
    return r * factor, g * factor, b * factor
end

-- =====================================
-- CRÉATION DE NAMEPLATE
-- =====================================

local function CreateNameplate(baseFrame)
    local plate = CreateFrame("Frame", nil, baseFrame)
    plate:SetAllPoints(baseFrame)
    plate:SetFrameStrata("BACKGROUND")
    
    local settings = GetSettings()
    local width = settings.width or 150
    local height = settings.height or 18
    
    -- Barre de santé
    plate.healthBar = CreateFrame("StatusBar", nil, plate)
    plate.healthBar:SetSize(width, height)
    plate.healthBar:SetPoint("CENTER", 0, 0)
    plate.healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    plate.healthBar:GetStatusBarTexture():SetHorizTile(false)
    plate.healthBar:SetMinMaxValues(0, 100)
    plate.healthBar:SetValue(100)
    
    -- Background de la barre
    plate.healthBG = plate.healthBar:CreateTexture(nil, "BACKGROUND")
    plate.healthBG:SetAllPoints(plate.healthBar)
    plate.healthBG:SetColorTexture(0.15, 0.15, 0.15, 1)
    
    -- Bordures noires (1 pixel)
    local function CreateBorder(parent)
        local t = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(0, 0, 0, 1)
        t:SetPoint("TOPLEFT")
        t:SetPoint("TOPRIGHT")
        t:SetHeight(1)
        
        local b = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        b:SetColorTexture(0, 0, 0, 1)
        b:SetPoint("BOTTOMLEFT")
        b:SetPoint("BOTTOMRIGHT")
        b:SetHeight(1)
        
        local l = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        l:SetColorTexture(0, 0, 0, 1)
        l:SetPoint("TOPLEFT")
        l:SetPoint("BOTTOMLEFT")
        l:SetWidth(1)
        
        local r = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        r:SetColorTexture(0, 0, 0, 1)
        r:SetPoint("TOPRIGHT")
        r:SetPoint("BOTTOMRIGHT")
        r:SetWidth(1)
    end
    CreateBorder(plate.healthBar)
    
    -- Texte de nom
    plate.nameText = plate.healthBar:CreateFontString(nil, "OVERLAY")
    plate.nameText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    plate.nameText:SetPoint("BOTTOM", plate.healthBar, "TOP", 0, 2)
    plate.nameText:SetTextColor(1, 1, 1)
    
    -- Texte de level
    plate.levelText = plate.healthBar:CreateFontString(nil, "OVERLAY")
    plate.levelText:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    plate.levelText:SetPoint("RIGHT", plate.healthBar, "LEFT", -2, 0)
    plate.levelText:SetTextColor(1, 1, 1)
    
    -- Texte de santé
    plate.healthText = plate.healthBar:CreateFontString(nil, "OVERLAY")
    plate.healthText:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    plate.healthText:SetPoint("CENTER", plate.healthBar, "CENTER", 0, 0)
    plate.healthText:SetTextColor(1, 1, 1)
    
    -- Texte de classification (élite, rare, etc.) - Au lieu d'une icône
    plate.classificationText = plate.healthBar:CreateFontString(nil, "OVERLAY")
    plate.classificationText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    plate.classificationText:SetPoint("LEFT", plate.healthBar, "RIGHT", 2, 0)
    plate.classificationText:Hide()
    
    -- Indicateur de menace (threat) - Bordure colorée
    plate.threatFrame = CreateFrame("Frame", nil, plate.healthBar)
    plate.threatFrame:SetAllPoints(plate.healthBar)
    plate.threatFrame:SetFrameLevel(plate.healthBar:GetFrameLevel() + 10)
    
    -- Bordures épaisses pour le threat
    local function CreateThickBorder(parent)
        local thickness = 2
        local t = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(1, 0, 0, 1)
        t:SetPoint("TOPLEFT", -1, 1)
        t:SetPoint("TOPRIGHT", 1, 1)
        t:SetHeight(thickness)
        
        local b = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        b:SetColorTexture(1, 0, 0, 1)
        b:SetPoint("BOTTOMLEFT", -1, -1)
        b:SetPoint("BOTTOMRIGHT", 1, -1)
        b:SetHeight(thickness)
        
        local l = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        l:SetColorTexture(1, 0, 0, 1)
        l:SetPoint("TOPLEFT", -1, 1)
        l:SetPoint("BOTTOMLEFT", -1, -1)
        l:SetWidth(thickness)
        
        local r = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        r:SetColorTexture(1, 0, 0, 1)
        r:SetPoint("TOPRIGHT", 1, 1)
        r:SetPoint("BOTTOMRIGHT", 1, -1)
        r:SetWidth(thickness)
        
        return {t, b, l, r}
    end
    
    plate.threatBorders = CreateThickBorder(plate.threatFrame)
    plate.threatFrame:Hide()
    
    return plate
end

-- =====================================
-- MISE À JOUR DES NAMEPLATES
-- =====================================

local function UpdateNameplateSize(plate)
    local settings = GetSettings()
    local width = settings.width or 150
    local height = settings.height or 18
    
    if plate.healthBar then
        plate.healthBar:SetSize(width, height)
    end
end

local function UpdateNameplateHealth(plate, unit)
    if not plate.healthBar then return end
    
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    
    if maxHealth > 0 then
        plate.healthBar:SetMinMaxValues(0, maxHealth)
        plate.healthBar:SetValue(health)
        
        -- Mettre à jour le texte de santé
        local settings = GetSettings()
        if settings.showHealthText then
            local percent = math.floor((health / maxHealth) * 100)
            plate.healthText:SetText(percent .. "%")
            plate.healthText:Show()
        else
            plate.healthText:Hide()
        end
    end
end

local function UpdateNameplateColor(plate, unit)
    if not plate.healthBar then return end
    
    local r, g, b = 1, 1, 1
    local settings = GetSettings()
    
    -- Déterminer la couleur selon le type d'unité
    if UnitIsPlayer(unit) then
        -- Couleur de classe pour les joueurs
        if settings.useClassColors then
            local _, class = UnitClass(unit)
            if class then
                local classColor = RAID_CLASS_COLORS[class]
                if classColor then
                    r, g, b = classColor.r, classColor.g, classColor.b
                end
            end
        else
            -- Couleur selon la faction
            if UnitIsEnemy("player", unit) then
                r, g, b = GetColor("hostile")
            elseif UnitIsFriend("player", unit) then
                r, g, b = GetColor("friendly")
            else
                r, g, b = GetColor("neutral")
            end
        end
    else
        -- NPCs
        if UnitIsTapDenied(unit) then
            r, g, b = GetColor("tapped")
        elseif UnitIsEnemy("player", unit) then
            r, g, b = GetColor("hostile")
        elseif UnitReaction(unit, "player") then
            local reaction = UnitReaction(unit, "player")
            if reaction >= 5 then
                r, g, b = GetColor("friendly")
            elseif reaction == 4 then
                r, g, b = GetColor("neutral")
            else
                r, g, b = GetColor("hostile")
            end
        end
    end
    
    plate.healthBar:SetStatusBarColor(r, g, b)
end

local function UpdateNameplateName(plate, unit)
    if not plate.nameText then return end
    
    local settings = GetSettings()
    
    if settings.showName then
        local name = UnitName(unit)
        if name then
            plate.nameText:SetText(name)
            plate.nameText:Show()
        else
            plate.nameText:Hide()
        end
    else
        plate.nameText:Hide()
    end
end

local function UpdateNameplateLevel(plate, unit)
    if not plate.levelText then return end
    
    local settings = GetSettings()
    
    if settings.showLevel then
        local level = UnitEffectiveLevel(unit)
        local classification = UnitClassification(unit)
        
        local levelText = ""
        
        if level == -1 then
            levelText = "??"
        else
            levelText = tostring(level)
        end
        
        -- Ajouter symbole pour élite/rare/boss
        if classification == "elite" then
            levelText = levelText .. "+"
        elseif classification == "rare" then
            levelText = levelText .. "R"
        elseif classification == "rareelite" then
            levelText = levelText .. "R+"
        elseif classification == "worldboss" then
            levelText = "Boss"
        end
        
        plate.levelText:SetText(levelText)
        
        -- Couleur selon la difficulté
        local color = GetQuestDifficultyColor(level)
        plate.levelText:SetTextColor(color.r, color.g, color.b)
        
        plate.levelText:Show()
    else
        plate.levelText:Hide()
    end
end

local function UpdateNameplateThreat(plate, unit)
    if not plate.threatFrame then return end
    
    local settings = GetSettings()
    
    if settings.showThreat and UnitIsEnemy("player", unit) then
        local status = UnitThreatSituation("player", unit)
        
        if status and status >= 2 then
            -- On a l'aggro
            local r, g, b = GetThreatStatusColor(status)
            for _, border in ipairs(plate.threatBorders) do
                border:SetVertexColor(r, g, b, 1)
            end
            plate.threatFrame:Show()
        else
            plate.threatFrame:Hide()
        end
    else
        plate.threatFrame:Hide()
    end
end

local function UpdateNameplateClassification(plate, unit)
    if not plate.classificationText then return end
    
    local settings = GetSettings()
    
    if settings.showClassification then
        local classification = UnitClassification(unit)
        
        if classification == "elite" then
            plate.classificationText:SetText("★")
            plate.classificationText:SetTextColor(1, 0.84, 0) -- Or
            plate.classificationText:Show()
        elseif classification == "rareelite" then
            plate.classificationText:SetText("★★")
            plate.classificationText:SetTextColor(0, 0.8, 1) -- Bleu clair
            plate.classificationText:Show()
        elseif classification == "rare" then
            plate.classificationText:SetText("◆")
            plate.classificationText:SetTextColor(0, 0.8, 1) -- Bleu clair
            plate.classificationText:Show()
        elseif classification == "worldboss" then
            plate.classificationText:SetText("☠")
            plate.classificationText:SetTextColor(1, 0, 0) -- Rouge
            plate.classificationText:Show()
        else
            plate.classificationText:Hide()
        end
    else
        plate.classificationText:Hide()
    end
end

local function UpdateNameplate(plate, unit)
    if not plate or not unit then return end
    
    UpdateNameplateHealth(plate, unit)
    UpdateNameplateColor(plate, unit)
    UpdateNameplateName(plate, unit)
    UpdateNameplateLevel(plate, unit)
    UpdateNameplateThreat(plate, unit)
    UpdateNameplateClassification(plate, unit)
end

-- =====================================
-- EVENT HANDLERS
-- =====================================

local function OnNamePlateAdded(unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end
    
    -- Cacher le nameplate par défaut
    if nameplate.UnitFrame then
        nameplate.UnitFrame:Hide()
    end
    
    -- Créer notre nameplate personnalisé
    local plate = CreateNameplate(nameplate)
    plate.unit = unit
    plate.baseFrame = nameplate
    
    plates[nameplate] = plate
    activeNameplates[unit] = plate
    
    UpdateNameplate(plate, unit)
end

local function OnNamePlateRemoved(unit)
    local plate = activeNameplates[unit]
    if plate then
        if plate.baseFrame then
            plates[plate.baseFrame] = nil
        end
        activeNameplates[unit] = nil
        
        -- Nettoyer
        if plate.healthBar then
            plate.healthBar:Hide()
        end
        plate:Hide()
    end
end

local function OnNamePlateUpdate(unit)
    local plate = activeNameplates[unit]
    if plate then
        UpdateNameplate(plate, unit)
    end
end

-- =====================================
-- FRAME DE GESTION
-- =====================================

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("UNIT_MAXHEALTH")
eventFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
eventFrame:RegisterEvent("UNIT_FACTION")

eventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        OnNamePlateAdded(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        OnNamePlateRemoved(unit)
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        if unit and activeNameplates[unit] then
            UpdateNameplateHealth(activeNameplates[unit], unit)
        end
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" then
        if unit and activeNameplates[unit] then
            UpdateNameplateThreat(activeNameplates[unit], unit)
        end
    elseif event == "UNIT_FACTION" then
        if unit and activeNameplates[unit] then
            UpdateNameplateColor(activeNameplates[unit], unit)
        end
    end
end)

-- =====================================
-- FONCTIONS PUBLIQUES
-- =====================================

function Nameplates.Initialize()
    local settings = GetSettings()
    
    if not settings.enabled then
        Nameplates.Disable()
        return
    end
    
    print("|cff00ff00TomoMod:|r Nameplates activées")
    
    -- Appliquer les settings à tous les nameplates actifs
    Nameplates.RefreshAll()
end

function Nameplates.Enable()
    if TomoModDB and TomoModDB.nameplates then
        TomoModDB.nameplates.enabled = true
    end
    
    -- Réenregistrer les events
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    
    -- Rafraîchir tous les nameplates
    Nameplates.RefreshAll()
end

function Nameplates.Disable()
    -- Désenregistrer les events
    eventFrame:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
    
    -- Nettoyer tous les nameplates
    for _, plate in pairs(plates) do
        if plate.healthBar then
            plate.healthBar:Hide()
        end
        plate:Hide()
        
        -- Réafficher le nameplate par défaut
        if plate.baseFrame and plate.baseFrame.UnitFrame then
            plate.baseFrame.UnitFrame:Show()
        end
    end
    
    plates = {}
    activeNameplates = {}
end

function Nameplates.RefreshAll()
    -- Mettre à jour tous les nameplates actifs
    for unit, plate in pairs(activeNameplates) do
        UpdateNameplateSize(plate)
        UpdateNameplate(plate, unit)
    end
end

function Nameplates.ApplySettings()
    Nameplates.RefreshAll()
end

-- =====================================
-- ENREGISTREMENT DU MODULE
-- =====================================

TomoMod_RegisterModule("nameplates", Nameplates)

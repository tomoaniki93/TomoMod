-- =========================================================================
-- UnitFrames.lua
-- Barres de vie pour Player, Target et TargetOfTarget
-- =========================================================================

TomoMod_UnitFrames = {}

local playerFrame = nil
local targetFrame = nil
local totFrame = nil

-- =====================================
-- COULEURS DES RESSOURCES
-- =====================================

local POWER_COLORS = {
    ["MANA"] = {0, 0.44, 0.87},
    ["RAGE"] = {0.77, 0.12, 0.23},
    ["FOCUS"] = {1, 0.5, 0.25},
    ["ENERGY"] = {1, 0.96, 0.41},
    ["RUNIC_POWER"] = {0, 0.82, 1},
    ["LUNAR_POWER"] = {0.3, 0.52, 0.9},
    ["MAELSTROM"] = {0, 0.5, 1},
    ["INSANITY"] = {0.4, 0, 0.8},
    ["FURY"] = {0.79, 0.26, 0.99},
    ["PAIN"] = {1, 0.61, 0},
}

local POWER_TYPE_MAP = {
    [0] = "MANA",
    [1] = "RAGE",
    [2] = "FOCUS",
    [3] = "ENERGY",
    [6] = "RUNIC_POWER",
    [8] = "LUNAR_POWER",
    [11] = "MAELSTROM",
    [13] = "INSANITY",
    [17] = "FURY",
    [18] = "PAIN",
}

-- =====================================
-- FONCTIONS UTILITAIRES
-- =====================================

local function GetUnitClassColor(unit)
    if not UnitExists(unit) then return 1, 1, 1 end
    local _, class = UnitClass(unit)
    if class and RAID_CLASS_COLORS[class] then
        local color = RAID_CLASS_COLORS[class]
        return color.r, color.g, color.b
    end
    return 1, 1, 1
end

local function GetUnitReactionColor(unit)
    if not UnitExists(unit) then return 1, 1, 1 end
    
    if UnitIsPlayer(unit) then
        return GetUnitClassColor(unit)
    end
    
    local reaction = UnitReaction(unit, "player")
    if reaction then
        if reaction >= 5 then
            return 0, 0.8, 0
        elseif reaction == 4 then
            return 1, 0.82, 0
        else
            return 0.8, 0, 0
        end
    end
    
    return 1, 1, 1
end

local function GetPowerColor(unit)
    local powerType = UnitPowerType(unit)
    local powerName = POWER_TYPE_MAP[powerType] or "MANA"
    local color = POWER_COLORS[powerName] or {0, 0.44, 0.87}
    return color[1], color[2], color[3]
end

local function AbbreviateNumbers(value)
    if value >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fK", value / 1000)
    else
        return tostring(math.floor(value))
    end
end

local function FormatHealth(current, max, showCurrent, showPercent)
    if not showCurrent and not showPercent then
        return ""
    end
    
    local percent = max > 0 and math.floor((current / max) * 100) or 0
    
    if showCurrent and showPercent then
        return string.format("%s - %d%%", AbbreviateNumbers(current), percent)
    elseif showCurrent then
        return AbbreviateNumbers(current)
    else
        return string.format("%d%%", percent)
    end
end

-- =====================================
-- PLAYER FRAME
-- =====================================

local function CreatePlayerFrame()
    if playerFrame then return playerFrame end
    
    local db = TomoModDB.unitFrames.player
    local width = db.minimalist and 150 or db.width
    local height = db.minimalist and 15 or db.height
    
    playerFrame = CreateFrame("Frame", "TomoModPlayerFrame", UIParent, "BackdropTemplate")
    playerFrame:SetSize(width, height + 8)
    playerFrame:SetFrameStrata("MEDIUM")
    playerFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    playerFrame:SetBackdropColor(0, 0, 0, 0.8)
    playerFrame:SetBackdropBorderColor(0, 0, 0, 1)
    
    playerFrame.healthBar = CreateFrame("StatusBar", nil, playerFrame)
    playerFrame.healthBar:SetSize(width - 2, height - 2)
    playerFrame.healthBar:SetPoint("TOPLEFT", 1, -1)
    playerFrame.healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    playerFrame.healthBar:SetMinMaxValues(0, 1)
    playerFrame.healthBar:SetValue(1)
    
    playerFrame.healthBar.bg = playerFrame.healthBar:CreateTexture(nil, "BACKGROUND")
    playerFrame.healthBar.bg:SetAllPoints()
    playerFrame.healthBar.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    playerFrame.healthBar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    playerFrame.absorbBar = playerFrame.healthBar:CreateTexture(nil, "OVERLAY")
    playerFrame.absorbBar:SetTexture("Interface\\Buttons\\WHITE8x8")
    playerFrame.absorbBar:SetVertexColor(0.3, 0.7, 1, 0.4)
    playerFrame.absorbBar:SetPoint("LEFT", playerFrame.healthBar:GetStatusBarTexture(), "RIGHT", 0, 0)
    playerFrame.absorbBar:SetHeight(height - 2)
    playerFrame.absorbBar:Hide()
    
    playerFrame.powerBar = CreateFrame("StatusBar", nil, playerFrame)
    playerFrame.powerBar:SetSize(width - 2, 6)
    playerFrame.powerBar:SetPoint("TOPLEFT", playerFrame.healthBar, "BOTTOMLEFT", 0, -1)
    playerFrame.powerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    playerFrame.powerBar:SetMinMaxValues(0, 1)
    playerFrame.powerBar:SetValue(1)
    
    playerFrame.powerBar.bg = playerFrame.powerBar:CreateTexture(nil, "BACKGROUND")
    playerFrame.powerBar.bg:SetAllPoints()
    playerFrame.powerBar.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    playerFrame.powerBar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    playerFrame.indicators = CreateFrame("Frame", nil, playerFrame)
    playerFrame.indicators:SetSize(50, 16)
    playerFrame.indicators:SetPoint("TOPLEFT", playerFrame, "BOTTOMLEFT", 0, -2)
    
    playerFrame.leaderIcon = playerFrame.indicators:CreateTexture(nil, "OVERLAY")
    playerFrame.leaderIcon:SetSize(14, 14)
    playerFrame.leaderIcon:SetPoint("LEFT", 0, 0)
    playerFrame.leaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    playerFrame.leaderIcon:Hide()
    
    playerFrame.raidMarker = playerFrame.indicators:CreateTexture(nil, "OVERLAY")
    playerFrame.raidMarker:SetSize(14, 14)
    playerFrame.raidMarker:SetPoint("LEFT", playerFrame.leaderIcon, "RIGHT", 2, 0)
    playerFrame.raidMarker:Hide()
    
    playerFrame.nameText = playerFrame.healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playerFrame.nameText:SetPoint("LEFT", 4, 0)
    playerFrame.nameText:SetJustifyH("LEFT")
    
    playerFrame.levelText = playerFrame.healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playerFrame.levelText:SetPoint("LEFT", playerFrame.nameText, "RIGHT", 4, 0)
    playerFrame.levelText:SetTextColor(1, 0.82, 0)
    
    playerFrame.healthText = playerFrame.healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playerFrame.healthText:SetPoint("RIGHT", -4, 0)
    playerFrame.healthText:SetJustifyH("RIGHT")
    playerFrame.healthText:SetTextColor(1, 1, 1)
    
    playerFrame:SetMovable(true)
    playerFrame:EnableMouse(true)
    playerFrame:RegisterForDrag("LeftButton")
    
    playerFrame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() or TomoMod_PreviewMode.IsActive() then
            self:StartMoving()
        end
    end)
    
    playerFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        TomoMod_PreviewMode.SavePosition(self, TomoModDB.unitFrames.player)
    end)
    
    TomoMod_PreviewMode.RegisterElement(playerFrame, "Player Frame", function(frame)
        TomoMod_PreviewMode.SavePosition(frame, TomoModDB.unitFrames.player)
    end)
    
    return playerFrame
end

-- =====================================
-- TARGET FRAME
-- =====================================

local function CreateTargetFrame()
    if targetFrame then return targetFrame end
    
    local db = TomoModDB.unitFrames.target
    local width = db.minimalist and 150 or db.width
    local height = db.minimalist and 15 or db.height
    
    targetFrame = CreateFrame("Frame", "TomoModTargetFrame", UIParent, "BackdropTemplate")
    targetFrame:SetSize(width, height + 8)
    targetFrame:SetFrameStrata("MEDIUM")
    targetFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    targetFrame:SetBackdropColor(0, 0, 0, 0.8)
    targetFrame:SetBackdropBorderColor(0, 0, 0, 1)
    targetFrame:Hide()
    
    targetFrame.healthBar = CreateFrame("StatusBar", nil, targetFrame)
    targetFrame.healthBar:SetSize(width - 2, height - 2)
    targetFrame.healthBar:SetPoint("TOPLEFT", 1, -1)
    targetFrame.healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    targetFrame.healthBar:SetMinMaxValues(0, 1)
    targetFrame.healthBar:SetValue(1)
    
    targetFrame.healthBar.bg = targetFrame.healthBar:CreateTexture(nil, "BACKGROUND")
    targetFrame.healthBar.bg:SetAllPoints()
    targetFrame.healthBar.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    targetFrame.healthBar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    targetFrame.powerBar = CreateFrame("StatusBar", nil, targetFrame)
    targetFrame.powerBar:SetSize(width - 2, 6)
    targetFrame.powerBar:SetPoint("TOPLEFT", targetFrame.healthBar, "BOTTOMLEFT", 0, -1)
    targetFrame.powerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    targetFrame.powerBar:SetMinMaxValues(0, 1)
    targetFrame.powerBar:SetValue(1)
    
    targetFrame.powerBar.bg = targetFrame.powerBar:CreateTexture(nil, "BACKGROUND")
    targetFrame.powerBar.bg:SetAllPoints()
    targetFrame.powerBar.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    targetFrame.powerBar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    targetFrame.indicators = CreateFrame("Frame", nil, targetFrame)
    targetFrame.indicators:SetSize(50, 16)
    targetFrame.indicators:SetPoint("TOPLEFT", targetFrame, "BOTTOMLEFT", 0, -2)
    
    targetFrame.leaderIcon = targetFrame.indicators:CreateTexture(nil, "OVERLAY")
    targetFrame.leaderIcon:SetSize(14, 14)
    targetFrame.leaderIcon:SetPoint("LEFT", 0, 0)
    targetFrame.leaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    targetFrame.leaderIcon:Hide()
    
    targetFrame.raidMarker = targetFrame.indicators:CreateTexture(nil, "OVERLAY")
    targetFrame.raidMarker:SetSize(14, 14)
    targetFrame.raidMarker:SetPoint("LEFT", targetFrame.leaderIcon, "RIGHT", 2, 0)
    targetFrame.raidMarker:Hide()
    
    targetFrame.nameText = targetFrame.healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    targetFrame.nameText:SetPoint("LEFT", 4, 0)
    targetFrame.nameText:SetJustifyH("LEFT")
    
    targetFrame.levelText = targetFrame.healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    targetFrame.levelText:SetPoint("LEFT", targetFrame.nameText, "RIGHT", 4, 0)
    targetFrame.levelText:SetTextColor(1, 0.82, 0)
    
    targetFrame.healthText = targetFrame.healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    targetFrame.healthText:SetPoint("RIGHT", -4, 0)
    targetFrame.healthText:SetJustifyH("RIGHT")
    targetFrame.healthText:SetTextColor(1, 1, 1)
    
    targetFrame:SetMovable(true)
    targetFrame:EnableMouse(true)
    targetFrame:RegisterForDrag("LeftButton")
    
    targetFrame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() or TomoMod_PreviewMode.IsActive() then
            self:StartMoving()
        end
    end)
    
    targetFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        TomoMod_PreviewMode.SavePosition(self, TomoModDB.unitFrames.target)
    end)
    
    TomoMod_PreviewMode.RegisterElement(targetFrame, "Target Frame", function(frame)
        TomoMod_PreviewMode.SavePosition(frame, TomoModDB.unitFrames.target)
    end)
    
    return targetFrame
end

-- =====================================
-- TARGET OF TARGET FRAME
-- =====================================

local function CreateToTFrame()
    if totFrame then return totFrame end
    
    local db = TomoModDB.unitFrames.targetoftarget
    local width = db.minimalist and 150 or db.width
    local height = 15 -- Hauteur fixe
    
    totFrame = CreateFrame("Frame", "TomoModToTFrame", UIParent, "BackdropTemplate")
    totFrame:SetSize(width, height)
    totFrame:SetFrameStrata("MEDIUM")
    totFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    totFrame:SetBackdropColor(0, 0, 0, 0.8)
    totFrame:SetBackdropBorderColor(0, 0, 0, 1)
    totFrame:Hide()
    
    -- Barre de vie
    totFrame.healthBar = CreateFrame("StatusBar", nil, totFrame)
    totFrame.healthBar:SetSize(width - 2, height - 2)
    totFrame.healthBar:SetPoint("TOPLEFT", 1, -1)
    totFrame.healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    totFrame.healthBar:SetMinMaxValues(0, 1)
    totFrame.healthBar:SetValue(1)
    
    totFrame.healthBar.bg = totFrame.healthBar:CreateTexture(nil, "BACKGROUND")
    totFrame.healthBar.bg:SetAllPoints()
    totFrame.healthBar.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    totFrame.healthBar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    -- Nom uniquement
    totFrame.nameText = totFrame.healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    totFrame.nameText:SetPoint("CENTER", 0, 0)
    totFrame.nameText:SetJustifyH("CENTER")
    
    -- Drag
    totFrame:SetMovable(true)
    totFrame:EnableMouse(true)
    totFrame:RegisterForDrag("LeftButton")
    
    totFrame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() or TomoMod_PreviewMode.IsActive() then
            self:StartMoving()
        end
    end)
    
    totFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        TomoMod_PreviewMode.SavePosition(self, TomoModDB.unitFrames.targetoftarget)
    end)
    
    TomoMod_PreviewMode.RegisterElement(totFrame, "Target of Target", function(frame)
        TomoMod_PreviewMode.SavePosition(frame, TomoModDB.unitFrames.targetoftarget)
    end)
    
    return totFrame
end

-- =====================================
-- MISE À JOUR DES FRAMES
-- =====================================

local function UpdatePlayerFrame()
    if not playerFrame then return end
    
    local db = TomoModDB.unitFrames.player
    
    local health = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    local healthPercent = maxHealth > 0 and (health / maxHealth) or 0
    
    playerFrame.healthBar:SetValue(healthPercent)
    
    local r, g, b = GetUnitClassColor("player")
    playerFrame.healthBar:SetStatusBarColor(r, g, b)
    
    -- Absorption
    local absorb = UnitGetTotalAbsorbs("player") or 0
    if absorb > 0 and maxHealth > 0 then
        local absorbPercent = absorb / maxHealth
        local barWidth = playerFrame.healthBar:GetWidth()
        local healthWidth = barWidth * healthPercent
        local absorbWidth = math.min(barWidth * absorbPercent, barWidth - healthWidth)
        
        if absorbWidth > 0 then
            playerFrame.absorbBar:SetWidth(absorbWidth)
            playerFrame.absorbBar:Show()
        else
            playerFrame.absorbBar:Hide()
        end
    else
        playerFrame.absorbBar:Hide()
    end
    
    -- Ressource
    local power = UnitPower("player")
    local maxPower = UnitPowerMax("player")
    local powerPercent = maxPower > 0 and (power / maxPower) or 0
    
    playerFrame.powerBar:SetValue(powerPercent)
    local pr, pg, pb = GetPowerColor("player")
    playerFrame.powerBar:SetStatusBarColor(pr, pg, pb)
    
    -- Textes
    if db.showName then
        playerFrame.nameText:SetText(UnitName("player"))
        playerFrame.nameText:SetTextColor(r, g, b)
        playerFrame.nameText:Show()
    else
        playerFrame.nameText:Hide()
    end
    
    if db.showLevel then
        playerFrame.levelText:SetText(UnitLevel("player"))
        playerFrame.levelText:Show()
    else
        playerFrame.levelText:Hide()
    end
    
    playerFrame.healthText:SetText(FormatHealth(health, maxHealth, db.showCurrentHP, db.showPercentHP))
    
    -- Indicateurs
    if db.showLeader and UnitIsGroupLeader("player") then
        playerFrame.leaderIcon:Show()
    else
        playerFrame.leaderIcon:Hide()
    end
    
    if db.showRaidMarker then
        local marker = GetRaidTargetIndex("player")
        if marker then
            playerFrame.raidMarker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. marker)
            playerFrame.raidMarker:Show()
        else
            playerFrame.raidMarker:Hide()
        end
    else
        playerFrame.raidMarker:Hide()
    end
end

local function UpdateTargetFrame()
    if not targetFrame then return end
    
    local db = TomoModDB.unitFrames.target
    
    if not UnitExists("target") then
        if not TomoMod_PreviewMode.IsActive() then
            targetFrame:Hide()
        end
        return
    end
    
    targetFrame:Show()
    
    local health = UnitHealth("target")
    local maxHealth = UnitHealthMax("target")
    local healthPercent = maxHealth > 0 and (health / maxHealth) or 0
    
    targetFrame.healthBar:SetValue(healthPercent)
    
    local r, g, b = GetUnitReactionColor("target")
    targetFrame.healthBar:SetStatusBarColor(r, g, b)
    
    -- Ressource
    local power = UnitPower("target")
    local maxPower = UnitPowerMax("target")
    local powerPercent = maxPower > 0 and (power / maxPower) or 0
    
    targetFrame.powerBar:SetValue(powerPercent)
    local pr, pg, pb = GetPowerColor("target")
    targetFrame.powerBar:SetStatusBarColor(pr, pg, pb)
    
    -- Textes
    if db.showName then
        targetFrame.nameText:SetText(UnitName("target"))
        if UnitIsPlayer("target") then
            targetFrame.nameText:SetTextColor(r, g, b)
        else
            targetFrame.nameText:SetTextColor(1, 1, 1)
        end
        targetFrame.nameText:Show()
    else
        targetFrame.nameText:Hide()
    end
    
    if db.showLevel then
        local level = UnitLevel("target")
        if level == -1 then
            targetFrame.levelText:SetText("??")
            targetFrame.levelText:SetTextColor(1, 0, 0)
        else
            targetFrame.levelText:SetText(level)
            targetFrame.levelText:SetTextColor(1, 0.82, 0)
        end
        targetFrame.levelText:Show()
    else
        targetFrame.levelText:Hide()
    end
    
    targetFrame.healthText:SetText(FormatHealth(health, maxHealth, db.showCurrentHP, db.showPercentHP))
    
    -- Indicateurs
    if db.showLeader and UnitIsGroupLeader("target") then
        targetFrame.leaderIcon:Show()
    else
        targetFrame.leaderIcon:Hide()
    end
    
    if db.showRaidMarker then
        local marker = GetRaidTargetIndex("target")
        if marker then
            targetFrame.raidMarker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. marker)
            targetFrame.raidMarker:Show()
        else
            targetFrame.raidMarker:Hide()
        end
    else
        targetFrame.raidMarker:Hide()
    end
end

local function UpdateToTFrame()
    if not totFrame then return end
    
    local db = TomoModDB.unitFrames.targetoftarget
    
    if not UnitExists("targettarget") then
        if not TomoMod_PreviewMode.IsActive() then
            totFrame:Hide()
        end
        return
    end
    
    totFrame:Show()
    
    local health = UnitHealth("targettarget")
    local maxHealth = UnitHealthMax("targettarget")
    local healthPercent = maxHealth > 0 and (health / maxHealth) or 0
    
    totFrame.healthBar:SetValue(healthPercent)
    
    -- Couleur de la barre
    local r, g, b = GetUnitReactionColor("targettarget")
    totFrame.healthBar:SetStatusBarColor(r, g, b)
    
    -- Nom avec couleur appropriée
    local name = UnitName("targettarget")
    totFrame.nameText:SetText(name)
    
    if UnitIsPlayer("targettarget") then
        -- Joueur = couleur de classe
        local cr, cg, cb = GetUnitClassColor("targettarget")
        totFrame.nameText:SetTextColor(cr, cg, cb)
    else
        -- PNJ = blanc
        totFrame.nameText:SetTextColor(1, 1, 1)
    end
end

-- =====================================
-- MISE À JOUR APPARENCE
-- =====================================

local function UpdatePlayerAppearance()
    if not playerFrame then return end
    
    local db = TomoModDB.unitFrames.player
    local width = db.minimalist and 150 or db.width
    local height = db.minimalist and 15 or db.height
    
    playerFrame:SetSize(width, height + 8)
    playerFrame:SetScale(db.scale)
    
    playerFrame.healthBar:SetSize(width - 2, height - 2)
    playerFrame.powerBar:SetSize(width - 2, 6)
    playerFrame.absorbBar:SetHeight(height - 2)
    
    UpdatePlayerFrame()
end

local function UpdateTargetAppearance()
    if not targetFrame then return end
    
    local db = TomoModDB.unitFrames.target
    local width = db.minimalist and 150 or db.width
    local height = db.minimalist and 15 or db.height
    
    targetFrame:SetSize(width, height + 8)
    targetFrame:SetScale(db.scale)
    
    targetFrame.healthBar:SetSize(width - 2, height - 2)
    targetFrame.powerBar:SetSize(width - 2, 6)
    
    UpdateTargetFrame()
end

local function UpdateToTAppearance()
    if not totFrame then return end
    
    local db = TomoModDB.unitFrames.targetoftarget
    local width = db.minimalist and 150 or db.width
    local height = 15 -- Hauteur fixe
    
    totFrame:SetSize(width, height)
    totFrame:SetScale(db.scale)
    
    totFrame.healthBar:SetSize(width - 2, height - 2)
    
    UpdateToTFrame()
end

-- =====================================
-- CACHER FRAMES BLIZZARD
-- =====================================

local function HideBlizzardFrames()
    local db = TomoModDB.unitFrames
    
    if db.player.enabled then
        PlayerFrame:UnregisterAllEvents()
        PlayerFrame:Hide()
        PlayerFrame:SetScript("OnShow", function(self) self:Hide() end)
    end
    
    if db.target.enabled then
        TargetFrame:UnregisterAllEvents()
        TargetFrame:Hide()
        TargetFrame:SetScript("OnShow", function(self) self:Hide() end)
    end
    
    if db.targetoftarget.enabled then
        if TargetFrameToT then
            TargetFrameToT:UnregisterAllEvents()
            TargetFrameToT:Hide()
            TargetFrameToT:SetScript("OnShow", function(self) self:Hide() end)
        end
    end
end

-- =====================================
-- ÉVÉNEMENTS
-- =====================================

local eventFrame = CreateFrame("Frame")

local function OnEvent(self, event, ...)
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local unit = ...
        if unit == "player" then
            UpdatePlayerFrame()
        elseif unit == "target" then
            UpdateTargetFrame()
        elseif unit == "targettarget" then
            UpdateToTFrame()
        end
        
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        local unit = ...
        if unit == "player" then
            UpdatePlayerFrame()
        elseif unit == "target" then
            UpdateTargetFrame()
        end
        
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        local unit = ...
        if unit == "player" then
            UpdatePlayerFrame()
        end
        
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateTargetFrame()
        UpdateToTFrame()
        
    elseif event == "UNIT_TARGET" then
        local unit = ...
        if unit == "target" then
            UpdateToTFrame()
        end
        
    elseif event == "RAID_TARGET_UPDATE" or event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LEADER_CHANGED" then
        UpdatePlayerFrame()
        UpdateTargetFrame()
        
    elseif event == "UNIT_LEVEL" or event == "UNIT_NAME_UPDATE" then
        local unit = ...
        if unit == "player" then
            UpdatePlayerFrame()
        elseif unit == "target" then
            UpdateTargetFrame()
        elseif unit == "targettarget" then
            UpdateToTFrame()
        end
    end
end

-- =====================================
-- PRÉVISUALISATION
-- =====================================

function TomoMod_UnitFrames.ShowPreview()
    if not playerFrame then CreatePlayerFrame() end
    if not targetFrame then CreateTargetFrame() end
    if not totFrame then CreateToTFrame() end
    
    UpdatePlayerAppearance()
    UpdateTargetAppearance()
    UpdateToTAppearance()
    
    playerFrame:Show()
    targetFrame:Show()
    totFrame:Show()
    
    -- Preview target
    targetFrame.healthBar:SetValue(0.75)
    targetFrame.healthBar:SetStatusBarColor(0.8, 0, 0)
    targetFrame.powerBar:SetValue(0.5)
    targetFrame.powerBar:SetStatusBarColor(0, 0.44, 0.87)
    targetFrame.nameText:SetText("Cible Preview")
    targetFrame.nameText:SetTextColor(1, 1, 1)
    targetFrame.levelText:SetText("70")
    targetFrame.healthText:SetText("75%")
    
    -- Preview ToT
    totFrame.healthBar:SetValue(0.9)
    totFrame.healthBar:SetStatusBarColor(0, 0.8, 0)
    totFrame.nameText:SetText("ToT Preview")
    totFrame.nameText:SetTextColor(1, 1, 1)
end

function TomoMod_UnitFrames.HidePreview()
    UpdatePlayerFrame()
    
    if not UnitExists("target") then
        if targetFrame then targetFrame:Hide() end
    else
        UpdateTargetFrame()
    end
    
    if not UnitExists("targettarget") then
        if totFrame then totFrame:Hide() end
    else
        UpdateToTFrame()
    end
end

-- =====================================
-- INITIALISATION
-- =====================================

function TomoMod_UnitFrames.Initialize()
    local db = TomoModDB.unitFrames
    
    if db.player.enabled then
        CreatePlayerFrame()
        TomoMod_PreviewMode.LoadPosition(playerFrame, db.player, -200, -100)
        UpdatePlayerAppearance()
        UpdatePlayerFrame()
        playerFrame:Show()
    end
    
    if db.target.enabled then
        CreateTargetFrame()
        TomoMod_PreviewMode.LoadPosition(targetFrame, db.target, 200, -100)
        UpdateTargetAppearance()
    end
    
    if db.targetoftarget.enabled then
        CreateToTFrame()
        TomoMod_PreviewMode.LoadPosition(totFrame, db.targetoftarget, 200, -150)
        UpdateToTAppearance()
    end
    
    HideBlizzardFrames()
    
    eventFrame:RegisterEvent("UNIT_HEALTH")
    eventFrame:RegisterEvent("UNIT_MAXHEALTH")
    eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
    eventFrame:RegisterEvent("UNIT_MAXPOWER")
    eventFrame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("UNIT_TARGET")
    eventFrame:RegisterEvent("RAID_TARGET_UPDATE")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PARTY_LEADER_CHANGED")
    eventFrame:RegisterEvent("UNIT_LEVEL")
    eventFrame:RegisterEvent("UNIT_NAME_UPDATE")
    
    eventFrame:SetScript("OnEvent", OnEvent)
    
    print("|cff00ff00TomoMod:|r UnitFrames initialisés")
end

function TomoMod_UnitFrames.UpdatePlayerSettings()
    UpdatePlayerAppearance()
end

function TomoMod_UnitFrames.UpdateTargetSettings()
    UpdateTargetAppearance()
end

function TomoMod_UnitFrames.UpdateToTSettings()
    UpdateToTAppearance()
end

function TomoMod_UnitFrames.ResetPlayerPosition()
    TomoModDB.unitFrames.player.position = nil
    if playerFrame then
        TomoMod_PreviewMode.LoadPosition(playerFrame, TomoModDB.unitFrames.player, -200, -100)
    end
end

function TomoMod_UnitFrames.ResetTargetPosition()
    TomoModDB.unitFrames.target.position = nil
    if targetFrame then
        TomoMod_PreviewMode.LoadPosition(targetFrame, TomoModDB.unitFrames.target, 200, -100)
    end
end

function TomoMod_UnitFrames.ResetToTPosition()
    TomoModDB.unitFrames.targetoftarget.position = nil
    if totFrame then
        TomoMod_PreviewMode.LoadPosition(totFrame, TomoModDB.unitFrames.targetoftarget, 200, -150)
    end
end

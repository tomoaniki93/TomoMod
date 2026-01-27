-- ==========================================================================
-- UnitFrames.lua
-- Barres de vie pour Player, Target et TargetOfTarget
-- ==========================================================================

TomoMod_UnitFrames = {}

local playerFrame = nil
local targetFrame = nil
local totFrame = nil

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
    [0] = "MANA", [1] = "RAGE", [2] = "FOCUS", [3] = "ENERGY",
    [6] = "RUNIC_POWER", [8] = "LUNAR_POWER", [11] = "MAELSTROM",
    [13] = "INSANITY", [17] = "FURY", [18] = "PAIN",
}

-- =====================================
-- FONCTIONS UTILITAIRES
-- =====================================

local function IsValidNumber(value)
    if value == nil then return false end
    local success = pcall(function() return value + 0 end)
    return success and type(value) == "number"
end

local function SafeUnitHealth(unit)
    if not UnitExists(unit) then return 0, 1 end
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    if not IsValidNumber(health) then health = 0 end
    if not IsValidNumber(maxHealth) or maxHealth == 0 then maxHealth = 1 end
    return health, maxHealth
end

local function SafeUnitPower(unit)
    if not UnitExists(unit) then return 0, 1 end
    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    if not IsValidNumber(power) then power = 0 end
    if not IsValidNumber(maxPower) or maxPower == 0 then maxPower = 1 end
    return power, maxPower
end

local function SafeUnitAbsorb(unit)
    if not UnitExists(unit) then return 0 end
    local absorb = UnitGetTotalAbsorbs(unit)
    if not IsValidNumber(absorb) then return 0 end
    return absorb
end

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
    if UnitIsPlayer(unit) then return GetUnitClassColor(unit) end
    
    local reaction = UnitReaction(unit, "player")
    if reaction then
        if reaction >= 5 then return 0, 0.8, 0
        elseif reaction == 4 then return 1, 0.82, 0
        else return 0.8, 0, 0 end
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
    if not IsValidNumber(value) then return "0" end
    if value >= 1000000 then return string.format("%.1fM", value / 1000000)
    elseif value >= 1000 then return string.format("%.1fK", value / 1000)
    else return tostring(math.floor(value)) end
end

local function FormatHealth(current, max, showCurrent, showPercent)
    if not showCurrent and not showPercent then return "" end
    if not IsValidNumber(current) or not IsValidNumber(max) then return "" end
    
    local percent = max > 0 and math.floor((current / max) * 100) or 0
    if showCurrent and showPercent then
        return string.format("%s - %d%%", AbbreviateNumbers(current), percent)
    elseif showCurrent then return AbbreviateNumbers(current)
    else return string.format("%d%%", percent) end
end

-- Tronquer le nom à un nombre maximum de caractères
local function TruncateName(name, maxLen)
    if not name then return "" end
    if not maxLen or maxLen <= 0 then return name end
    if string.len(name) > maxLen then
        return string.sub(name, 1, maxLen) .. "..."
    end
    return name
end

-- Créer un FontString avec outline
local function CreateOutlinedText(parent, layer, size)
    local text = parent:CreateFontString(nil, layer or "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", size or 10, "OUTLINE")
    text:SetTextColor(1, 1, 1) -- Blanc
    text:SetShadowColor(0, 0, 0, 1)
    text:SetShadowOffset(1, -1)
    return text
end

-- =====================================
-- MENUS CONTEXTUELS
-- =====================================

local function ShowPlayerMenu(frame)
    ToggleDropDownMenu(1, nil, PlayerFrameDropDown, frame, 0, 0)
end

local function ShowTargetMenu(frame)
    ToggleDropDownMenu(1, nil, TargetFrameDropDown, frame, 0, 0)
end

-- =====================================
-- PLAYER FRAME
-- =====================================

local function CreatePlayerFrame()
    if playerFrame then return playerFrame end
    
    local db = TomoModDB.unitFrames.player
    local width = db.minimalist and 350 or db.width
    local height = db.minimalist and 15 or db.height
    
    playerFrame = CreateFrame("Button", "TomoModPlayerFrame", UIParent, "SecureUnitButtonTemplate, BackdropTemplate")
    playerFrame:SetAttribute("unit", "player")
    playerFrame:SetAttribute("type1", "target") -- Clic gauche = cibler
    playerFrame:SetAttribute("type2", "togglemenu") -- Clic droit = menu
    RegisterUnitWatch(playerFrame)
    
    playerFrame:SetSize(width, height)
    playerFrame:SetFrameStrata("MEDIUM")
    playerFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    playerFrame:SetBackdropColor(0, 0, 0, 0.8)
    playerFrame:SetBackdropBorderColor(0, 0, 0, 1)
    
    -- Barre de vie
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
    
    -- Barre d'absorption
    playerFrame.absorbBar = playerFrame.healthBar:CreateTexture(nil, "OVERLAY")
    playerFrame.absorbBar:SetTexture("Interface\\Buttons\\WHITE8x8")
    playerFrame.absorbBar:SetVertexColor(0.3, 0.7, 1, 0.4)
    playerFrame.absorbBar:SetHeight(height - 2)
    playerFrame.absorbBar:Hide()
    
    -- Indicateurs
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
    
    -- Textes avec outline
    playerFrame.nameText = CreateOutlinedText(playerFrame.healthBar, "OVERLAY", 10)
    playerFrame.nameText:SetPoint("LEFT", 4, 0)
    playerFrame.nameText:SetJustifyH("LEFT")
    
    playerFrame.levelText = CreateOutlinedText(playerFrame.healthBar, "OVERLAY", 10)
    playerFrame.levelText:SetPoint("LEFT", playerFrame.nameText, "RIGHT", 4, 0)
    
    playerFrame.healthText = CreateOutlinedText(playerFrame.healthBar, "OVERLAY", 10)
    playerFrame.healthText:SetPoint("RIGHT", -4, 0)
    playerFrame.healthText:SetJustifyH("RIGHT")
    
    -- Drag
    playerFrame:SetMovable(true)
    playerFrame:RegisterForDrag("LeftButton")
    playerFrame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() or TomoMod_PreviewMode.IsActive() then self:StartMoving() end
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
    local width = db.minimalist and 350 or db.width
    local height = db.minimalist and 15 or db.height
    
    targetFrame = CreateFrame("Button", "TomoModTargetFrame", UIParent, "SecureUnitButtonTemplate, BackdropTemplate")
    targetFrame:SetAttribute("unit", "target")
    targetFrame:SetAttribute("type1", "target") -- Clic gauche = cibler
    targetFrame:SetAttribute("type2", "togglemenu") -- Clic droit = menu
    RegisterUnitWatch(targetFrame)
    
    targetFrame:SetSize(width, height + 8)
    targetFrame:SetFrameStrata("MEDIUM")
    targetFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    targetFrame:SetBackdropColor(0, 0, 0, 0.8)
    targetFrame:SetBackdropBorderColor(0, 0, 0, 1)
    
    -- Barre de vie
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
    
    -- Barre de ressource
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
    
    -- Indicateurs
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
    
    -- Textes avec outline
    targetFrame.nameText = CreateOutlinedText(targetFrame.healthBar, "OVERLAY", 10)
    targetFrame.nameText:SetPoint("LEFT", 4, 0)
    targetFrame.nameText:SetJustifyH("LEFT")
    
    targetFrame.levelText = CreateOutlinedText(targetFrame.healthBar, "OVERLAY", 10)
    targetFrame.levelText:SetPoint("LEFT", targetFrame.nameText, "RIGHT", 4, 0)
    
    targetFrame.healthText = CreateOutlinedText(targetFrame.healthBar, "OVERLAY", 10)
    targetFrame.healthText:SetPoint("RIGHT", -4, 0)
    targetFrame.healthText:SetJustifyH("RIGHT")
    
    -- Drag
    targetFrame:SetMovable(true)
    targetFrame:RegisterForDrag("LeftButton")
    targetFrame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() or TomoMod_PreviewMode.IsActive() then self:StartMoving() end
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
    local height = 15
    
    totFrame = CreateFrame("Button", "TomoModToTFrame", UIParent, "SecureUnitButtonTemplate, BackdropTemplate")
    totFrame:SetAttribute("unit", "targettarget")
    totFrame:SetAttribute("type1", "target") -- Clic gauche = cibler
    RegisterUnitWatch(totFrame)
    
    totFrame:SetSize(width, height)
    totFrame:SetFrameStrata("MEDIUM")
    totFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    totFrame:SetBackdropColor(0, 0, 0, 0.8)
    totFrame:SetBackdropBorderColor(0, 0, 0, 1)
    
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
    
    -- Texte avec outline
    totFrame.nameText = CreateOutlinedText(totFrame.healthBar, "OVERLAY", 9)
    totFrame.nameText:SetPoint("CENTER", 0, 0)
    totFrame.nameText:SetJustifyH("CENTER")
    
    -- Drag
    totFrame:SetMovable(true)
    totFrame:RegisterForDrag("LeftButton")
    totFrame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() or TomoMod_PreviewMode.IsActive() then self:StartMoving() end
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
    
    local health, maxHealth = SafeUnitHealth("player")
    local healthPercent = maxHealth > 0 and (health / maxHealth) or 0
    
    playerFrame.healthBar:SetValue(healthPercent)
    
    -- Couleur de la barre de vie
    if db.useClassColor then
        local r, g, b = GetClassColor("player")
        playerFrame.healthBar:SetStatusBarColor(r, g, b)
    else
        playerFrame.healthBar:SetStatusBarColor(0.2, 0.2, 0.2) -- Gris foncé/noir
    end
    
    -- Absorption
    local absorb = SafeUnitAbsorb("player")
    if absorb > 0 and maxHealth > 0 then
        local absorbPercent = absorb / maxHealth
        local barWidth = playerFrame.healthBar:GetWidth()
        local healthWidth = barWidth * healthPercent
        local absorbWidth = math.min(barWidth * absorbPercent, barWidth - healthWidth)
        
        if absorbWidth > 0 then
            playerFrame.absorbBar:ClearAllPoints()
            playerFrame.absorbBar:SetPoint("LEFT", playerFrame.healthBar:GetStatusBarTexture(), "RIGHT", 0, 0)
            playerFrame.absorbBar:SetWidth(absorbWidth)
            playerFrame.absorbBar:Show()
        else
            playerFrame.absorbBar:Hide()
        end
    else
        playerFrame.absorbBar:Hide()
    end
    
    -- Textes
    if db.showName then
        playerFrame.nameText:SetText(UnitName("player"))
        playerFrame.nameText:Show()
    else playerFrame.nameText:Hide() end
    
    if db.showLevel then
        playerFrame.levelText:SetText(UnitLevel("player"))
        playerFrame.levelText:Show()
    else playerFrame.levelText:Hide() end
    
    playerFrame.healthText:SetText(FormatHealth(health, maxHealth, db.showCurrentHP, db.showPercentHP))
    
    -- Indicateurs
    if db.showLeader and UnitIsGroupLeader("player") then
        playerFrame.leaderIcon:Show()
    else playerFrame.leaderIcon:Hide() end
    
    if db.showRaidMarker then
        local marker = GetRaidTargetIndex("player")
        if marker then
            playerFrame.raidMarker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. marker)
            playerFrame.raidMarker:Show()
        else playerFrame.raidMarker:Hide() end
    else playerFrame.raidMarker:Hide() end
end

local function UpdateTargetFrame()
    if not targetFrame then return end
    local db = TomoModDB.unitFrames.target
    
    if not UnitExists("target") then
        return
    end
    
    local health, maxHealth = SafeUnitHealth("target")
    local healthPercent = maxHealth > 0 and (health / maxHealth) or 0
    
    targetFrame.healthBar:SetValue(healthPercent)
    
    -- Couleur de la barre de vie
    if db.useClassColor then
        local r, g, b = GetUnitReactionColor("target")
        targetFrame.healthBar:SetStatusBarColor(r, g, b)
    else
        targetFrame.healthBar:SetStatusBarColor(0.2, 0.2, 0.2) -- Gris foncé/noir
    end
    
    -- Ressource
    if db.showPowerBar then
        local power, maxPower = SafeUnitPower("target")
        local powerPercent = maxPower > 0 and (power / maxPower) or 0
        targetFrame.powerBar:SetValue(powerPercent)
        local pr, pg, pb = GetPowerColor("target")
        targetFrame.powerBar:SetStatusBarColor(pr, pg, pb)
        targetFrame.powerBar:Show()
    else
        targetFrame.powerBar:Hide()
    end
    
    -- Textes
    if db.showName then
        targetFrame.nameText:SetText(UnitName("target"))
        targetFrame.nameText:Show()
    else targetFrame.nameText:Hide() end
    
    if db.showLevel then
        local level = UnitLevel("target")
        if level == -1 then
            targetFrame.levelText:SetText("??")
        else
            targetFrame.levelText:SetText(level)
        end
        targetFrame.levelText:Show()
    else targetFrame.levelText:Hide() end
    
    targetFrame.healthText:SetText(FormatHealth(health, maxHealth, db.showCurrentHP, db.showPercentHP))
    
    -- Indicateurs
    if db.showLeader and UnitIsGroupLeader("target") then
        targetFrame.leaderIcon:Show()
    else targetFrame.leaderIcon:Hide() end
    
    if db.showRaidMarker then
        local marker = GetRaidTargetIndex("target")
        if marker then
            targetFrame.raidMarker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. marker)
            targetFrame.raidMarker:Show()
        else targetFrame.raidMarker:Hide() end
    else targetFrame.raidMarker:Hide() end

    -- Nom tronqué
    local name = UnitName("target")
    local maxLen = db.truncateNameLength or 8
    if db.truncateName and maxLen > 0 then
        name = TruncateName(name, maxLen)
    end
    totFrame.nameText:SetText(name)
end

local function UpdateToTFrame()
    if not totFrame then return end
    local db = TomoModDB.unitFrames.targetoftarget
    
    if not UnitExists("targettarget") then
        return
    end
    
    local health, maxHealth = SafeUnitHealth("targettarget")
    local healthPercent = maxHealth > 0 and (health / maxHealth) or 0
    
    totFrame.healthBar:SetValue(healthPercent)
    
    -- Couleur de la barre de vie
    if db.useClassColor then
        local r, g, b = GetUnitReactionColor("targettarget")
        totFrame.healthBar:SetStatusBarColor(r, g, b)
    else
        totFrame.healthBar:SetStatusBarColor(0.2, 0.2, 0.2)
    end
    
    -- Nom tronqué
    local name = UnitName("targettarget")
    local maxLen = db.truncateNameLength or 8
    if db.truncateName and maxLen > 0 then
        name = TruncateName(name, maxLen)
    end
    totFrame.nameText:SetText(name)
end

-- =====================================
-- MISE À JOUR APPARENCE
-- =====================================

local function UpdatePlayerAppearance()
    if not playerFrame then return end
    local db = TomoModDB.unitFrames.player
    local width = db.minimalist and 350 or db.width
    local height = db.minimalist and 15 or db.height
    
    playerFrame:SetSize(width, height)
    playerFrame:SetScale(db.scale)
    playerFrame.healthBar:SetSize(width - 2, height - 2)
    playerFrame.absorbBar:SetHeight(height - 2)
    UpdatePlayerFrame()
end

local function UpdateTargetAppearance()
    if not targetFrame then return end
    local db = TomoModDB.unitFrames.target
    local width = db.minimalist and 350 or db.width
    local height = db.minimalist and 15 or db.height
    
    local totalHeight = height
    if db.showPowerBar then
        totalHeight = height + 8
    end
    
    targetFrame:SetSize(width, totalHeight)
    targetFrame:SetScale(db.scale)
    targetFrame.healthBar:SetSize(width - 2, height - 2)
    targetFrame.powerBar:SetSize(width - 2, 6)
    
    if db.showPowerBar then
        targetFrame.powerBar:Show()
    else
        targetFrame.powerBar:Hide()
    end
    
    UpdateTargetFrame()
end

local function UpdateToTAppearance()
    if not totFrame then return end
    local db = TomoModDB.unitFrames.targetoftarget
    local width = db.minimalist and 150 or db.width
    
    totFrame:SetSize(width, 15)
    totFrame:SetScale(db.scale)
    totFrame.healthBar:SetSize(width - 2, 13)
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
    
    if db.targetoftarget.enabled and TargetFrameToT then
        TargetFrameToT:UnregisterAllEvents()
        TargetFrameToT:Hide()
        TargetFrameToT:SetScript("OnShow", function(self) self:Hide() end)
    end
end

-- =====================================
-- ÉVÉNEMENTS
-- =====================================

local eventFrame = CreateFrame("Frame")

local function OnEvent(self, event, ...)
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local unit = ...
        if unit == "player" then UpdatePlayerFrame()
        elseif unit == "target" then UpdateTargetFrame()
        elseif unit == "targettarget" then UpdateToTFrame() end
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        local unit = ...
        if unit == "target" then UpdateTargetFrame() end
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        local unit = ...
        if unit == "player" then UpdatePlayerFrame() end
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateTargetFrame()
        UpdateToTFrame()
    elseif event == "UNIT_TARGET" then
        local unit = ...
        if unit == "target" then UpdateToTFrame() end
    elseif event == "RAID_TARGET_UPDATE" or event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LEADER_CHANGED" then
        UpdatePlayerFrame()
        UpdateTargetFrame()
    elseif event == "UNIT_LEVEL" or event == "UNIT_NAME_UPDATE" then
        local unit = ...
        if unit == "player" then UpdatePlayerFrame()
        elseif unit == "target" then UpdateTargetFrame()
        elseif unit == "targettarget" then UpdateToTFrame() end
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
    local db = TomoModDB.unitFrames.target
    targetFrame.healthBar:SetValue(0.75)
    if db.useClassColor then
        targetFrame.healthBar:SetStatusBarColor(0.8, 0, 0)
    else
        targetFrame.healthBar:SetStatusBarColor(0.2, 0.2, 0.2)
    end
    if db.showPowerBar then
        targetFrame.powerBar:SetValue(0.5)
        targetFrame.powerBar:SetStatusBarColor(0, 0.44, 0.87)
    end
    targetFrame.nameText:SetText("Cible Preview")
    targetFrame.levelText:SetText("70")
    targetFrame.healthText:SetText("75%")
    
    -- Preview ToT
    local dbTot = TomoModDB.unitFrames.targetoftarget
    totFrame.healthBar:SetValue(0.9)
    if dbTot.useClassColor then
        totFrame.healthBar:SetStatusBarColor(0, 0.8, 0)
    else
        totFrame.healthBar:SetStatusBarColor(0.2, 0.2, 0.2)
    end
    local totName = "ToT Preview"
    if dbTot.truncateName then
        totName = TruncateName(totName, dbTot.truncateNameLength or 8)
    end
    totFrame.nameText:SetText(totName)
end

function TomoMod_UnitFrames.HidePreview()
    UpdatePlayerFrame()
    UpdateTargetFrame()
    UpdateToTFrame()
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
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("UNIT_TARGET")
    eventFrame:RegisterEvent("RAID_TARGET_UPDATE")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PARTY_LEADER_CHANGED")
    eventFrame:RegisterEvent("UNIT_LEVEL")
    eventFrame:RegisterEvent("UNIT_NAME_UPDATE")
    
    eventFrame:SetScript("OnEvent", OnEvent)
end

function TomoMod_UnitFrames.UpdatePlayerSettings() UpdatePlayerAppearance() end
function TomoMod_UnitFrames.UpdateTargetSettings() UpdateTargetAppearance() end
function TomoMod_UnitFrames.UpdateToTSettings() UpdateToTAppearance() end

function TomoMod_UnitFrames.ResetPlayerPosition()
    TomoModDB.unitFrames.player.position = nil
    if playerFrame then TomoMod_PreviewMode.LoadPosition(playerFrame, TomoModDB.unitFrames.player, -200, -100) end
end

function TomoMod_UnitFrames.ResetTargetPosition()
    TomoModDB.unitFrames.target.position = nil
    if targetFrame then TomoMod_PreviewMode.LoadPosition(targetFrame, TomoModDB.unitFrames.target, 200, -100) end
end

function TomoMod_UnitFrames.ResetToTPosition()
    TomoModDB.unitFrames.targetoftarget.position = nil
    if totFrame then TomoMod_PreviewMode.LoadPosition(totFrame, TomoModDB.unitFrames.targetoftarget, 200, -150) end
end
-- =====================================
-- Auras.lua
-- Tracking des debuffs pour Player et Target
-- =====================================

TomoMod_Auras = {}

local playerDebuffAnchor = nil
local targetDebuffAnchor = nil
local playerDebuffFrames = {}
local targetDebuffFrames = {}

local ICON_SIZE = 32
local ICON_SPACING = 2

-- =====================================
-- FONCTIONS UTILITAIRES
-- =====================================

local function CreateDebuffIcon(parent, index, unit)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(ICON_SIZE, ICON_SIZE)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("TOPLEFT", 1, -1)
    frame.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints(frame.icon)
    frame.cooldown:SetDrawEdge(false)
    frame.cooldown:SetDrawBling(false)
    frame.cooldown:SetDrawSwipe(true)
    frame.cooldown:SetReverse(true)
    
    frame.count = frame:CreateFontString(nil, "OVERLAY")
    frame.count:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    frame.count:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.count:SetTextColor(1, 1, 1)
    
    frame.duration = frame:CreateFontString(nil, "OVERLAY")
    frame.duration:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    frame.duration:SetPoint("TOP", frame, "BOTTOM", 0, -1)
    frame.duration:SetTextColor(1, 1, 0)
    
    frame.index = index
    frame.unit = unit
    frame:Hide()
    
    return frame
end

local function FormatDuration(duration)
    if duration >= 3600 then
        return string.format("%dh", math.floor(duration / 3600))
    elseif duration >= 60 then
        return string.format("%dm", math.floor(duration / 60))
    elseif duration >= 1 then
        return string.format("%d", math.floor(duration))
    else
        return string.format("%.1f", duration)
    end
end

local function UpdateDebuffIcon(frame, name, icon, count, debuffType, duration, expirationTime, source, spellId)
    if not name then
        frame:Hide()
        return
    end
    
    frame.icon:SetTexture(icon)
    
    if count and count > 1 then
        frame.count:SetText(count)
        frame.count:Show()
    else
        frame.count:Hide()
    end
    
    -- Couleur de bordure selon le type de debuff
    local r, g, b = 0.8, 0, 0 -- Rouge par défaut
    if debuffType then
        local color = DebuffTypeColor[debuffType]
        if color then
            r, g, b = color.r, color.g, color.b
        end
    end
    frame:SetBackdropBorderColor(r, g, b, 1)
    
    -- Cooldown
    if duration and duration > 0 and expirationTime then
        frame.cooldown:SetCooldown(expirationTime - duration, duration)
        frame.cooldown:Show()
    else
        frame.cooldown:Hide()
    end
    
    frame.name = name
    frame.expirationTime = expirationTime
    frame.duration = duration
    frame:Show()
end

-- =====================================
-- PLAYER DEBUFF ANCHOR
-- =====================================

local function CreatePlayerDebuffAnchor()
    if playerDebuffAnchor then return playerDebuffAnchor end
    
    local db = TomoModDB.auras.playerDebuffs
    
    playerDebuffAnchor = CreateFrame("Frame", "TomoModPlayerDebuffAnchor", UIParent, "BackdropTemplate")
    playerDebuffAnchor:SetSize(ICON_SIZE, ICON_SIZE)
    playerDebuffAnchor:SetFrameStrata("MEDIUM")
    playerDebuffAnchor:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    playerDebuffAnchor:SetBackdropColor(0.8, 0, 0, 0.3)
    playerDebuffAnchor:SetBackdropBorderColor(0.8, 0, 0, 0.8)
    playerDebuffAnchor:Hide()
    
    playerDebuffAnchor.label = playerDebuffAnchor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playerDebuffAnchor.label:SetPoint("TOP", playerDebuffAnchor, "BOTTOM", 0, -2)
    playerDebuffAnchor.label:SetText("Player Debuffs")
    playerDebuffAnchor.label:SetTextColor(1, 0.5, 0.5)
    
    -- Créer les icônes de debuff (max 8)
    for i = 1, 8 do
        playerDebuffFrames[i] = CreateDebuffIcon(UIParent, i, "player")
    end
    
    -- Drag (uniquement en mode preview)
    playerDebuffAnchor:SetMovable(true)
    playerDebuffAnchor:EnableMouse(true)
    playerDebuffAnchor:RegisterForDrag("LeftButton")
    playerDebuffAnchor:SetScript("OnDragStart", function(self)
        if TomoMod_PreviewMode.IsActive() then
            self:StartMoving()
        end
    end)
    playerDebuffAnchor:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if TomoMod_PreviewMode.IsActive() then
            TomoMod_PreviewMode.SavePosition(self, TomoModDB.auras.playerDebuffs)
        end
    end)
    
    TomoMod_PreviewMode.RegisterElement(playerDebuffAnchor, "Player Debuffs", function(frame)
        TomoMod_PreviewMode.SavePosition(frame, TomoModDB.auras.playerDebuffs)
    end)
    
    return playerDebuffAnchor
end

local function PositionPlayerDebuffs()
    local db = TomoModDB.auras.playerDebuffs
    local scale = db.scale or 1
    local count = db.count or 8
    local growDirection = db.growDirection or "LEFT"
    local iconSize = ICON_SIZE * scale
    local spacing = ICON_SPACING * scale
    
    for i, frame in ipairs(playerDebuffFrames) do
        frame:SetScale(scale)
        frame:ClearAllPoints()
        
        if i <= count then
            local xOffset, yOffset = 0, 0
            
            if growDirection == "LEFT" then
                xOffset = -((i - 1) * (ICON_SIZE + ICON_SPACING))
            elseif growDirection == "RIGHT" then
                xOffset = (i - 1) * (ICON_SIZE + ICON_SPACING)
            elseif growDirection == "UP" then
                yOffset = (i - 1) * (ICON_SIZE + ICON_SPACING)
            elseif growDirection == "DOWN" then
                yOffset = -((i - 1) * (ICON_SIZE + ICON_SPACING))
            end
            
            frame:SetPoint("CENTER", playerDebuffAnchor, "CENTER", xOffset, yOffset)
        else
            frame:Hide()
        end
    end
end

local function UpdatePlayerDebuffs()
    if not TomoModDB.auras.playerDebuffs.enabled then return end
    
    local db = TomoModDB.auras.playerDebuffs
    local count = db.count or 8
    local debuffIndex = 0
    
    for i = 1, 40 do
        local name, icon, stacks, debuffType, duration, expirationTime, source, _, _, spellId = UnitDebuff("player", i)
        
        if not name then break end
        
        debuffIndex = debuffIndex + 1
        if debuffIndex <= count then
            UpdateDebuffIcon(playerDebuffFrames[debuffIndex], name, icon, stacks, debuffType, duration, expirationTime, source, spellId)
        end
    end
    
    -- Cacher les icônes non utilisées
    for i = debuffIndex + 1, 8 do
        playerDebuffFrames[i]:Hide()
    end
end

-- =====================================
-- TARGET DEBUFF ANCHOR
-- =====================================

local function CreateTargetDebuffAnchor()
    if targetDebuffAnchor then return targetDebuffAnchor end
    
    local db = TomoModDB.auras.targetDebuffs
    
    targetDebuffAnchor = CreateFrame("Frame", "TomoModTargetDebuffAnchor", UIParent, "BackdropTemplate")
    targetDebuffAnchor:SetSize(ICON_SIZE, ICON_SIZE)
    targetDebuffAnchor:SetFrameStrata("MEDIUM")
    targetDebuffAnchor:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    targetDebuffAnchor:SetBackdropColor(0.8, 0.4, 0, 0.3)
    targetDebuffAnchor:SetBackdropBorderColor(0.8, 0.4, 0, 0.8)
    targetDebuffAnchor:Hide()
    
    targetDebuffAnchor.label = targetDebuffAnchor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    targetDebuffAnchor.label:SetPoint("TOP", targetDebuffAnchor, "BOTTOM", 0, -2)
    targetDebuffAnchor.label:SetText("Target Debuffs")
    targetDebuffAnchor.label:SetTextColor(1, 0.7, 0.3)
    
    -- Créer les icônes de debuff (max 16: 2 lignes x 8)
    for i = 1, 16 do
        targetDebuffFrames[i] = CreateDebuffIcon(UIParent, i, "target")
    end
    
    -- Drag (uniquement en mode preview)
    targetDebuffAnchor:SetMovable(true)
    targetDebuffAnchor:EnableMouse(true)
    targetDebuffAnchor:RegisterForDrag("LeftButton")
    targetDebuffAnchor:SetScript("OnDragStart", function(self)
        if TomoMod_PreviewMode.IsActive() then
            self:StartMoving()
        end
    end)
    targetDebuffAnchor:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if TomoMod_PreviewMode.IsActive() then
            TomoMod_PreviewMode.SavePosition(self, TomoModDB.auras.targetDebuffs)
        end
    end)
    
    TomoMod_PreviewMode.RegisterElement(targetDebuffAnchor, "Target Debuffs", function(frame)
        TomoMod_PreviewMode.SavePosition(frame, TomoModDB.auras.targetDebuffs)
    end)
    
    return targetDebuffAnchor
end

local function PositionTargetDebuffs()
    local db = TomoModDB.auras.targetDebuffs
    local scale = db.scale or 1
    local countPerRow = db.countPerRow or 8
    local rows = db.rows or 1
    local growDirection = db.growDirection or "RIGHT"
    local rowDirection = db.rowDirection or "DOWN"
    
    local totalCount = countPerRow * rows
    
    for i, frame in ipairs(targetDebuffFrames) do
        frame:SetScale(scale)
        frame:ClearAllPoints()
        
        if i <= totalCount then
            local row = math.floor((i - 1) / countPerRow)
            local col = (i - 1) % countPerRow
            
            local xOffset, yOffset = 0, 0
            
            -- Direction horizontale
            if growDirection == "RIGHT" then
                xOffset = col * (ICON_SIZE + ICON_SPACING)
            elseif growDirection == "LEFT" then
                xOffset = -(col * (ICON_SIZE + ICON_SPACING))
            end
            
            -- Direction verticale (lignes)
            if rowDirection == "DOWN" then
                yOffset = -(row * (ICON_SIZE + ICON_SPACING + 12)) -- +12 pour le texte de durée
            elseif rowDirection == "UP" then
                yOffset = row * (ICON_SIZE + ICON_SPACING + 12)
            end
            
            frame:SetPoint("CENTER", targetDebuffAnchor, "CENTER", xOffset, yOffset)
        else
            frame:Hide()
        end
    end
end

local function UpdateTargetDebuffs()
    if not TomoModDB.auras.targetDebuffs.enabled then return end
    if not UnitExists("target") then
        for i = 1, 16 do
            targetDebuffFrames[i]:Hide()
        end
        return
    end
    
    local db = TomoModDB.auras.targetDebuffs
    local countPerRow = db.countPerRow or 8
    local rows = db.rows or 1
    local onlyMine = db.onlyMine or false
    local maxDebuffs = countPerRow * rows
    local debuffIndex = 0
    
    for i = 1, 40 do
        local name, icon, stacks, debuffType, duration, expirationTime, source, _, _, spellId = UnitDebuff("target", i)
        
        if not name then break end
        
        -- Filtrer par source si "only mine" est activé
        local showDebuff = true
        if onlyMine and source ~= "player" then
            showDebuff = false
        end
        
        if showDebuff then
            debuffIndex = debuffIndex + 1
            if debuffIndex <= maxDebuffs then
                UpdateDebuffIcon(targetDebuffFrames[debuffIndex], name, icon, stacks, debuffType, duration, expirationTime, source, spellId)
            end
        end
    end
    
    -- Cacher les icônes non utilisées
    for i = debuffIndex + 1, 16 do
        targetDebuffFrames[i]:Hide()
    end
end

-- =====================================
-- MISE À JOUR DU TEXTE DE DURÉE
-- =====================================

local updateFrame = CreateFrame("Frame")
local elapsed = 0

local function OnUpdate(self, delta)
    elapsed = elapsed + delta
    if elapsed < 0.1 then return end
    elapsed = 0
    
    local currentTime = GetTime()
    
    -- Player debuffs
    for _, frame in ipairs(playerDebuffFrames) do
        if frame:IsShown() and frame.expirationTime then
            local remaining = frame.expirationTime - currentTime
            if remaining > 0 then
                frame.duration:SetText(FormatDuration(remaining))
            else
                frame.duration:SetText("")
            end
        end
    end
    
    -- Target debuffs
    for _, frame in ipairs(targetDebuffFrames) do
        if frame:IsShown() and frame.expirationTime then
            local remaining = frame.expirationTime - currentTime
            if remaining > 0 then
                frame.duration:SetText(FormatDuration(remaining))
            else
                frame.duration:SetText("")
            end
        end
    end
end

-- =====================================
-- PRÉVISUALISATION
-- =====================================

function TomoMod_Auras.ShowPreview()
    if not playerDebuffAnchor then CreatePlayerDebuffAnchor() end
    if not targetDebuffAnchor then CreateTargetDebuffAnchor() end
    
    -- Afficher les ancres
    playerDebuffAnchor:Show()
    targetDebuffAnchor:Show()
    
    -- Positionner les debuffs
    PositionPlayerDebuffs()
    PositionTargetDebuffs()
    
    -- Afficher des icônes de preview pour Player
    local db = TomoModDB.auras.playerDebuffs
    for i = 1, db.count or 8 do
        local frame = playerDebuffFrames[i]
        frame.icon:SetTexture("Interface\\Icons\\Spell_Shadow_ShadowWordPain")
        frame.count:Hide()
        frame:SetBackdropBorderColor(0.8, 0, 0.8, 1) -- Magie
        frame.cooldown:Hide()
        frame.duration:SetText(tostring(10 - i + 1))
        frame:Show()
    end
    
    -- Afficher des icônes de preview pour Target
    local dbTarget = TomoModDB.auras.targetDebuffs
    local maxTarget = (dbTarget.countPerRow or 8) * (dbTarget.rows or 1)
    for i = 1, maxTarget do
        local frame = targetDebuffFrames[i]
        frame.icon:SetTexture("Interface\\Icons\\Ability_Rogue_Rupture")
        frame.count:Hide()
        frame:SetBackdropBorderColor(0.8, 0, 0, 1) -- Physical
        frame.cooldown:Hide()
        frame.duration:SetText(tostring(15 - i + 1))
        frame:Show()
    end
end

function TomoMod_Auras.HidePreview()
    if playerDebuffAnchor then
        playerDebuffAnchor:Hide()
    end
    if targetDebuffAnchor then
        targetDebuffAnchor:Hide()
    end
    
    -- Mettre à jour avec les vrais debuffs
    UpdatePlayerDebuffs()
    UpdateTargetDebuffs()
end

-- =====================================
-- ÉVÉNEMENTS
-- =====================================

local eventFrame = CreateFrame("Frame")

local function OnEvent(self, event, ...)
    if event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            UpdatePlayerDebuffs()
        elseif unit == "target" then
            UpdateTargetDebuffs()
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateTargetDebuffs()
    end
end

-- =====================================
-- INITIALISATION
-- =====================================

function TomoMod_Auras.Initialize()
    local db = TomoModDB.auras
    
    if db.playerDebuffs.enabled then
        CreatePlayerDebuffAnchor()
        TomoMod_PreviewMode.LoadPosition(playerDebuffAnchor, db.playerDebuffs, -300, -200)
        PositionPlayerDebuffs()
        UpdatePlayerDebuffs()
    end
    
    if db.targetDebuffs.enabled then
        CreateTargetDebuffAnchor()
        TomoMod_PreviewMode.LoadPosition(targetDebuffAnchor, db.targetDebuffs, 300, -200)
        PositionTargetDebuffs()
        UpdateTargetDebuffs()
    end
    
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:SetScript("OnEvent", OnEvent)
    
    updateFrame:SetScript("OnUpdate", OnUpdate)
end

function TomoMod_Auras.UpdatePlayerDebuffSettings()
    PositionPlayerDebuffs()
    UpdatePlayerDebuffs()
end

function TomoMod_Auras.UpdateTargetDebuffSettings()
    PositionTargetDebuffs()
    UpdateTargetDebuffs()
end

function TomoMod_Auras.ResetPlayerDebuffPosition()
    TomoModDB.auras.playerDebuffs.position = nil
    if playerDebuffAnchor then
        TomoMod_PreviewMode.LoadPosition(playerDebuffAnchor, TomoModDB.auras.playerDebuffs, -300, -200)
    end
end

function TomoMod_Auras.ResetTargetDebuffPosition()
    TomoModDB.auras.targetDebuffs.position = nil
    if targetDebuffAnchor then
        TomoMod_PreviewMode.LoadPosition(targetDebuffAnchor, TomoModDB.auras.targetDebuffs, 300, -200)
    end
end
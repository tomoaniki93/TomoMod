-- =====================================
-- CastBars.lua
-- Barre de cast personnalisée pour la cible
-- =====================================

TomoMod_CastBars = {}

local castBar
local isInterrupted = false
local fadeOutTimer = nil

-- Cacher la barre de cast Blizzard de la cible
local function HideBlizzardTargetCastBar()
    if TargetFrameSpellBar then
        TargetFrameSpellBar:UnregisterAllEvents()
        TargetFrameSpellBar:Hide()
        TargetFrameSpellBar:SetScript("OnShow", function(self) self:Hide() end)
    end
end

-- Vérifier si la cible est un allié en groupe/raid
local function IsTargetFriendlyGroupMember()
    if not UnitExists("target") then return false end
    if UnitIsEnemy("player", "target") then return false end
    
    if UnitInParty("target") or UnitInRaid("target") then
        return true
    end
    
    return false
end

-- Obtenir la couleur de classe d'une unité
local function GetUnitClassColor(unit)
    if not UnitExists(unit) then return 1, 1, 1 end
    local _, class = UnitClass(unit)
    if class and RAID_CLASS_COLORS[class] then
        local color = RAID_CLASS_COLORS[class]
        return color.r, color.g, color.b
    end
    return 1, 1, 1
end

-- Vérifier si le joueur est ciblé par la cible
local function IsPlayerTargetedByTarget()
    return UnitExists("targettarget") and UnitIsUnit("targettarget", "player")
end

-- Créer la barre de cast
local function CreateCastBar()
    if castBar then return castBar end
    
    local db = TomoModDB.castBars
    
    local iconSize = db.height
    local barWidth = db.width - iconSize - 2
    
    -- Frame principale
    castBar = CreateFrame("Frame", "TomoModTargetCastBar", UIParent, "BackdropTemplate")
    castBar:SetSize(db.width, db.height)
    castBar:SetFrameStrata("HIGH")
    castBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    castBar:SetBackdropColor(0, 0, 0, 0.8)
    castBar:SetBackdropBorderColor(0, 0, 0, 1)
    castBar:Hide()
    
    -- Icône du sort
    castBar.icon = castBar:CreateTexture(nil, "ARTWORK")
    castBar.icon:SetSize(iconSize, iconSize)
    castBar.icon:SetPoint("LEFT", castBar, "LEFT", 0, 0)
    castBar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    -- Bordure de l'icône
    castBar.iconBorder = CreateFrame("Frame", nil, castBar, "BackdropTemplate")
    castBar.iconBorder:SetPoint("TOPLEFT", castBar.icon, "TOPLEFT", 0, 0)
    castBar.iconBorder:SetPoint("BOTTOMRIGHT", castBar.icon, "BOTTOMRIGHT", 0, 0)
    castBar.iconBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    castBar.iconBorder:SetBackdropBorderColor(0, 0, 0, 1)
    
    -- StatusBar
    castBar.bar = CreateFrame("StatusBar", nil, castBar)
    castBar.bar:SetSize(barWidth, db.height)
    castBar.bar:SetPoint("LEFT", castBar.icon, "RIGHT", 2, 0)
    castBar.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    castBar.bar:SetMinMaxValues(0, 1)
    castBar.bar:SetValue(0)
    
    castBar.barWidth = barWidth
    
    -- Background de la barre
    castBar.bar.bg = castBar.bar:CreateTexture(nil, "BACKGROUND")
    castBar.bar.bg:SetAllPoints()
    castBar.bar.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    castBar.bar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    -- Nom du sort
    castBar.spellName = castBar.bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    castBar.spellName:SetPoint("LEFT", castBar.bar, "LEFT", 4, 0)
    castBar.spellName:SetJustifyH("LEFT")
    castBar.spellName:SetTextColor(1, 1, 1)
    
    -- Timer
    castBar.timer = castBar.bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    castBar.timer:SetPoint("RIGHT", castBar.bar, "RIGHT", -4, 0)
    castBar.timer:SetJustifyH("RIGHT")
    castBar.timer:SetTextColor(1, 1, 1)
    
    -- Nom de la cible
    castBar.targetName = castBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    castBar.targetName:SetPoint("BOTTOM", castBar, "TOP", 0, 2)
    castBar.targetName:SetJustifyH("CENTER")
    
    -- Spark
    castBar.spark = castBar.bar:CreateTexture(nil, "OVERLAY")
    castBar.spark:SetSize(16, db.height * 2)
    castBar.spark:SetBlendMode("ADD")
    castBar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    
    -- Flash overlay
    castBar.flash = castBar:CreateTexture(nil, "OVERLAY")
    castBar.flash:SetAllPoints()
    castBar.flash:SetTexture("Interface\\Buttons\\WHITE8x8")
    castBar.flash:SetVertexColor(1, 0, 0, 0)
    castBar.flash:SetBlendMode("ADD")
    
    -- Animation de flash
    castBar.flashAnim = castBar.flash:CreateAnimationGroup()
    castBar.flashAnim:SetLooping("REPEAT")
    
    local fadeIn = castBar.flashAnim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(0.3)
    fadeIn:SetDuration(0.5)
    fadeIn:SetOrder(1)
    
    local fadeOut = castBar.flashAnim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(0.3)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.5)
    fadeOut:SetOrder(2)
    
    -- Rendre la barre déplaçable (seulement avec Shift ou en mode preview)
    castBar:SetMovable(true)
    castBar:EnableMouse(true)
    castBar:RegisterForDrag("LeftButton")
    
    castBar:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() or TomoMod_PreviewMode.IsActive() then
            self:StartMoving()
        end
    end)
    
    castBar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        TomoMod_PreviewMode.SavePosition(self, TomoModDB.castBars)
    end)
    
    -- Enregistrer dans le système de prévisualisation
    TomoMod_PreviewMode.RegisterElement(castBar, "Cast Bar Cible", function(frame)
        TomoMod_PreviewMode.SavePosition(frame, TomoModDB.castBars)
    end)
    
    return castBar
end

-- Appliquer la position sauvegardée
local function ApplyPosition()
    if not castBar then return end
    TomoMod_PreviewMode.LoadPosition(castBar, TomoModDB.castBars, 0, -150)
end

-- Mettre à jour l'apparence
local function UpdateAppearance()
    if not castBar then return end
    
    local db = TomoModDB.castBars
    
    local iconSize = db.height
    local barWidth = db.width - iconSize - 2
    
    castBar:SetSize(db.width, db.height)
    castBar.icon:SetSize(iconSize, iconSize)
    castBar.bar:SetSize(barWidth, db.height)
    castBar.barWidth = barWidth
    castBar.spark:SetSize(16, db.height * 2)
    
    if db.showSpellName then
        castBar.spellName:Show()
    else
        castBar.spellName:Hide()
    end
    
    if db.showTargetName then
        castBar.targetName:Show()
    else
        castBar.targetName:Hide()
    end
end

-- Définir la couleur de la barre
local function SetBarColor(notInterruptible, interrupted)
    if not castBar then return end
    
    local db = TomoModDB.castBars
    local r, g, b
    
    if interrupted then
        local color = db.interruptedColor or {221/255, 160/255, 221/255}
        r, g, b = color[1], color[2], color[3]
    elseif notInterruptible then
        local color = db.notInterruptibleColor or {0.5, 0.5, 0.5}
        r, g, b = color[1], color[2], color[3]
    else
        local color = db.interruptibleColor or {0, 1, 1}
        r, g, b = color[1], color[2], color[3]
    end
    
    castBar.bar:SetStatusBarColor(r, g, b)
end

-- Gérer le flash
local function UpdateFlash()
    if not castBar or not castBar:IsShown() then return end
    
    local db = TomoModDB.castBars
    
    if db.flashOnTargeted and IsPlayerTargetedByTarget() and not TomoMod_PreviewMode.IsActive() then
        if not castBar.flashAnim:IsPlaying() then
            castBar.flashAnim:Play()
        end
    else
        if castBar.flashAnim:IsPlaying() then
            castBar.flashAnim:Stop()
            castBar.flash:SetAlpha(0)
        end
    end
end

-- Mettre à jour l'opacité
local function UpdateOpacity()
    if not castBar then return end
    
    if TomoMod_PreviewMode.IsActive() then
        castBar:SetAlpha(1)
    elseif IsTargetFriendlyGroupMember() then
        castBar:SetAlpha(0.4)
    else
        castBar:SetAlpha(1)
    end
end

-- Démarrer un cast
local function StartCast(unit, spellName, spellTexture, startTime, endTime, notInterruptible, castID)
    if unit ~= "target" or not TomoModDB.castBars.enabled then return end
    if TomoMod_PreviewMode.IsActive() then return end
    if not castBar then CreateCastBar() end
    
    isInterrupted = false
    
    if fadeOutTimer then
        fadeOutTimer:Cancel()
        fadeOutTimer = nil
    end
    
    local db = TomoModDB.castBars
    
    castBar.icon:SetTexture(spellTexture)
    castBar.spellName:SetText(spellName)
    
    if db.showTargetName then
        local targetName = UnitName("target") or "Cible"
        local r, g, b = GetUnitClassColor("target")
        castBar.targetName:SetText(targetName)
        castBar.targetName:SetTextColor(r, g, b)
    end
    
    local duration = (endTime - startTime) / 1000
    castBar.startTime = startTime / 1000
    castBar.endTime = endTime / 1000
    castBar.duration = duration
    castBar.castID = castID
    castBar.channeling = false
    
    SetBarColor(notInterruptible, false)
    UpdateOpacity()
    
    castBar.bar:SetMinMaxValues(0, 1)
    castBar.bar:SetValue(0)
    castBar:Show()
    
    UpdateFlash()
end

-- Démarrer un channel
local function StartChannel(unit, spellName, spellTexture, startTime, endTime, notInterruptible)
    if unit ~= "target" or not TomoModDB.castBars.enabled then return end
    if TomoMod_PreviewMode.IsActive() then return end
    if not castBar then CreateCastBar() end
    
    isInterrupted = false
    
    if fadeOutTimer then
        fadeOutTimer:Cancel()
        fadeOutTimer = nil
    end
    
    local db = TomoModDB.castBars
    
    castBar.icon:SetTexture(spellTexture)
    castBar.spellName:SetText(spellName)
    
    if db.showTargetName then
        local targetName = UnitName("target") or "Cible"
        local r, g, b = GetUnitClassColor("target")
        castBar.targetName:SetText(targetName)
        castBar.targetName:SetTextColor(r, g, b)
    end
    
    local duration = (endTime - startTime) / 1000
    castBar.startTime = startTime / 1000
    castBar.endTime = endTime / 1000
    castBar.duration = duration
    castBar.channeling = true
    
    SetBarColor(notInterruptible, false)
    UpdateOpacity()
    
    castBar.bar:SetMinMaxValues(0, 1)
    castBar.bar:SetValue(1)
    castBar:Show()
    
    UpdateFlash()
end

-- Arrêter le cast
local function StopCast(unit, interrupted)
    if unit ~= "target" or not castBar then return end
    if TomoMod_PreviewMode.IsActive() then return end
    
    if interrupted then
        isInterrupted = true
        SetBarColor(false, true)
        
        fadeOutTimer = C_Timer.NewTimer(0.5, function()
            if castBar and not TomoMod_PreviewMode.IsActive() then
                castBar:Hide()
            end
            fadeOutTimer = nil
        end)
    else
        castBar:Hide()
    end
    
    if castBar.flashAnim:IsPlaying() then
        castBar.flashAnim:Stop()
        castBar.flash:SetAlpha(0)
    end
end

-- Mise à jour OnUpdate
local function OnUpdate(self, elapsed)
    if not castBar or not castBar:IsShown() or isInterrupted then return end
    
    -- Mode prévisualisation
    if TomoMod_PreviewMode.IsActive() then
        local currentTime = GetTime()
        local previewProgress = (currentTime % 3) / 3
        
        castBar.bar:SetValue(previewProgress)
        castBar.timer:SetText(string.format("%.1f", 3 - (previewProgress * 3)))
        
        local barWidth = castBar.barWidth or castBar.bar:GetWidth()
        if barWidth and barWidth > 0 then
            castBar.spark:ClearAllPoints()
            castBar.spark:SetPoint("CENTER", castBar.bar, "LEFT", barWidth * previewProgress, 0)
        end
        return
    end
    
    local currentTime = GetTime()
    
    if castBar.channeling then
        local remaining = castBar.endTime - currentTime
        if remaining <= 0 then
            castBar:Hide()
            return
        end
        
        local progress = remaining / castBar.duration
        castBar.bar:SetValue(progress)
        castBar.timer:SetText(string.format("%.1f", remaining))
        
        local barWidth = castBar.barWidth or castBar.bar:GetWidth()
        if barWidth and barWidth > 0 then
            castBar.spark:ClearAllPoints()
            castBar.spark:SetPoint("CENTER", castBar.bar, "LEFT", barWidth * progress, 0)
        end
    else
        local elapsed = currentTime - castBar.startTime
        if elapsed >= castBar.duration then
            castBar:Hide()
            return
        end
        
        local progress = elapsed / castBar.duration
        castBar.bar:SetValue(progress)
        castBar.timer:SetText(string.format("%.1f", castBar.duration - elapsed))
        
        local barWidth = castBar.barWidth or castBar.bar:GetWidth()
        if barWidth and barWidth > 0 then
            castBar.spark:ClearAllPoints()
            castBar.spark:SetPoint("CENTER", castBar.bar, "LEFT", barWidth * progress, 0)
        end
    end
    
    UpdateFlash()
end

-- Gestionnaire d'événements
local eventFrame = CreateFrame("Frame")

local function OnEvent(self, event, ...)
    if event == "UNIT_SPELLCAST_START" then
        local unit = ...
        if unit == "target" then
            local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("target")
            if name then
                StartCast("target", name, texture, startTime, endTime, notInterruptible, castID)
            end
        end
        
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unit = ...
        if unit == "target" then
            local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo("target")
            if name then
                StartChannel("target", name, texture, startTime, endTime, notInterruptible)
            end
        end
        
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or 
           event == "UNIT_SPELLCAST_FAILED_QUIET" then
        local unit = ...
        if unit == "target" then
            StopCast("target", false)
        end
        
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        local unit = ...
        if unit == "target" then
            StopCast("target", true)
        end
        
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        local unit = ...
        if unit == "target" then
            StopCast("target", false)
        end
        
    elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        local unit = ...
        if unit == "target" and castBar and castBar:IsShown() and not TomoMod_PreviewMode.IsActive() then
            local notInterruptible = (event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
            SetBarColor(notInterruptible, false)
        end
        
    elseif event == "PLAYER_TARGET_CHANGED" then
        if TomoMod_PreviewMode.IsActive() then return end
        
        if castBar then
            castBar:Hide()
            if castBar.flashAnim:IsPlaying() then
                castBar.flashAnim:Stop()
                castBar.flash:SetAlpha(0)
            end
        end
        
        if UnitExists("target") then
            local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("target")
            if name then
                StartCast("target", name, texture, startTime, endTime, notInterruptible, castID)
            else
                local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo("target")
                if name then
                    StartChannel("target", name, texture, startTime, endTime, notInterruptible)
                end
            end
        end
        
    elseif event == "UNIT_TARGET" then
        local unit = ...
        if unit == "target" and not TomoMod_PreviewMode.IsActive() then
            UpdateFlash()
        end
    end
end

-- =====================================
-- PRÉVISUALISATION SPÉCIFIQUE
-- =====================================

function TomoMod_CastBars.ShowPreview()
    if not castBar then CreateCastBar() end
    
    local db = TomoModDB.castBars
    UpdateAppearance()
    
    castBar.icon:SetTexture("Interface\\Icons\\Spell_Nature_Starfall")
    castBar.spellName:SetText("Sort de Prévisualisation")
    
    local playerName = UnitName("player")
    local r, g, b = TomoMod_Utils.GetClassColor()
    castBar.targetName:SetText(playerName)
    castBar.targetName:SetTextColor(r, g, b)
    
    SetBarColor(false, false)
    
    castBar.bar:SetMinMaxValues(0, 1)
    castBar.bar:SetValue(0)
    castBar:SetAlpha(1)
    castBar:Show()
    
    if castBar.flashAnim:IsPlaying() then
        castBar.flashAnim:Stop()
        castBar.flash:SetAlpha(0)
    end
end

function TomoMod_CastBars.HidePreview()
    if castBar then
        castBar:Hide()
        if castBar.flashAnim:IsPlaying() then
            castBar.flashAnim:Stop()
            castBar.flash:SetAlpha(0)
        end
    end
    
    -- Vérifier si la cible actuelle incante
    if UnitExists("target") and TomoModDB.castBars.enabled then
        local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("target")
        if name then
            StartCast("target", name, texture, startTime, endTime, notInterruptible, castID)
        else
            local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo("target")
            if name then
                StartChannel("target", name, texture, startTime, endTime, notInterruptible)
            end
        end
    end
end

-- =====================================
-- INITIALISATION
-- =====================================

function TomoMod_CastBars.Initialize()
    if not TomoModDB.castBars.enabled then return end
    
    HideBlizzardTargetCastBar()
    
    CreateCastBar()
    ApplyPosition()
    UpdateAppearance()
    
    eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("UNIT_TARGET")
    
    eventFrame:SetScript("OnEvent", OnEvent)
    castBar:SetScript("OnUpdate", OnUpdate)
    
    print("|cff00ff00TomoMod:|r Barre de cast cible initialisée")
end

function TomoMod_CastBars.UpdateSettings()
    if castBar then
        UpdateAppearance()
    end
end

function TomoMod_CastBars.ResetPosition()
    TomoModDB.castBars.position = nil
    ApplyPosition()
end

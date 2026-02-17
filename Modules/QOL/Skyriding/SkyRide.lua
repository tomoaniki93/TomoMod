-- =====================================
-- TomoMod_SkyRide.lua
-- Module de barre Dragonriding/Skyriding
-- =====================================

TomoMod_SkyRide = TomoMod_SkyRide or {}
local SR = TomoMod_SkyRide

-- =====================================
-- CONSTANTES
-- =====================================
local SURGE_FORWARD_SPELL = 372608  -- Surge Forward (vitesse avant)
local SKYWARD_ASCENT_SPELL = 425782 -- Skyward Ascent (ascension)
local VIGOR_SPELL = 361584          -- Vigor (récupération)

-- Constantes pour le calcul de vitesse
local SPEED_MULTIPLIER = 14.285  -- Multiplicateur pour convertir forwardSpeed en %
local BASE_MOVEMENT_SPEED = 7    -- Vitesse de base du joueur

local STATUSBAR_COLORS = {
    [1] = {r = 0.3, g = 0.8, b = 1}, -- Bleu clair pour Surge Forward
    [2] = {r = 0.1, g = 0.6, b = 1}, -- Bleu foncé pour Skyward Ascent
}

-- Fonction Round
local function Round(num)
    return math.floor(num + 0.5)
end

-- =====================================
-- VARIABLES DU MODULE
-- =====================================
local frame
local speedBar
local comboBars = {}
local maxCombos = {}
local isLocked = true
local updateSpeedTimer
local updateSpellTimer

-- =====================================
-- FONCTIONS UTILITAIRES
-- =====================================
local function GetSettings()
    if not TomoModDB or not TomoModDB.skyRide then
        return nil
    end
    return TomoModDB.skyRide
end

local function SavePosition()
    local settings = GetSettings()
    if not settings then return end
    
    local point, _, relativePoint, x, y = frame:GetPoint()
    settings.position = {
        point = point or "BOTTOM",
        relativePoint = relativePoint or "CENTER",
        x = x or 0,
        y = y or -180,
    }
    
    print("|cff00ff00TomoMod:|r " .. TomoMod_L["msg_sr_pos_saved"])
end

local function ApplyPosition()
    local settings = GetSettings()
    if not settings then return end
    
    local pos = settings.position
    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
end

local function UpdateVisibility()
    local settings = GetSettings()
    if not settings or not settings.enabled then
        frame:Hide()
        return
    end
    
    -- En mode unlock (déverrouillé), toujours afficher pour permettre le positionnement
    if not isLocked then
        frame:Show()
        return
    end
    
    -- En mode lock (verrouillé), afficher seulement si en vol
    if IsFlying("player") then
        frame:Show()
    else
        frame:Hide()
    end
end

-- =====================================
-- SYSTÈME DE LOCK/UNLOCK
-- =====================================
local dragOverlay, dragLabel

local function SetLocked(locked)
    isLocked = locked
    
    if locked then
        -- Mode verrouillé
        frame:EnableMouse(false)
        if dragOverlay then dragOverlay:Hide() end
        if dragLabel then dragLabel:Hide() end
        
        -- Mettre à jour la visibilité (va cacher si au sol)
        UpdateVisibility()
    else
        -- Mode déplacement
        frame:EnableMouse(true)
        if dragOverlay then dragOverlay:Show() end
        if dragLabel then dragLabel:Show() end
        
        -- Forcer l'affichage en mode déplacement
        frame:Show()
        frame:SetAlpha(1)
    end
end

function SR.SetLocked(locked)
    SetLocked(locked)
    
    if locked then
        print("|cff00ff00TomoMod:|r " .. TomoMod_L["msg_sr_locked"])
    else
        print("|cffffff00TomoMod:|r " .. TomoMod_L["msg_sr_unlock"])
    end
end

function SR.ToggleLock()
    SetLocked(not isLocked)
    return isLocked
end

function SR.IsLocked()
    return isLocked
end

-- =====================================
-- SETUP DES COMBOS (CHARGES)
-- =====================================
local function SetupMaxCombo(max, index)
    if issecretvalue and issecretvalue(max) then
        return
    end
    
    if max == 0 then
        return
    end
    
    maxCombos[index] = max
    
    local settings = GetSettings()
    if not settings then return end
    
    local width = (settings.width - (1 * (max - 1))) / max
    local bars = comboBars[index]
    
    -- Cacher toutes les barres
    for i = 1, 10 do
        bars[i]:Hide()
    end
    
    -- Afficher et configurer les barres nécessaires
    for i = 1, max do
        local bar = bars[i]
        bar:SetWidth(width)
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(0)
        bar:Show()
    end
end

local function CheckSpellCooldown(spellID, index)
    local chargeInfo = C_Spell.GetSpellCharges(spellID)
    local durationInfo = C_Spell.GetSpellChargeDuration(spellID)
    
    if chargeInfo and durationInfo and not (issecretvalue and issecretvalue(chargeInfo.currentCharges)) then
        SetupMaxCombo(chargeInfo.maxCharges, index)
        
        local bars = comboBars[index]
        
        for i = 1, maxCombos[index] do
            local bar = bars[i]
            if i <= chargeInfo.currentCharges then
                -- Charge disponible
                local color = STATUSBAR_COLORS[index]
                bar:SetStatusBarColor(color.r, color.g, color.b)
                bar:SetMinMaxValues(0, 1)
                bar:SetValue(1)
            elseif i == chargeInfo.currentCharges + 1 then
                -- Charge en recharge
                bar:SetStatusBarColor(0.5, 0.5, 0.5)
                if bar.SetTimerDuration then
                    bar:SetTimerDuration(durationInfo)
                end
            else
                -- Charge vide
                bar:SetMinMaxValues(0, 1)
                bar:SetValue(0)
            end
        end
    end
end

-- =====================================
-- UPDATE DE LA VITESSE
-- =====================================
local function UpdateSpeed()
    local settings = GetSettings()
    if not settings or not settings.enabled then
        frame:Hide()
        return
    end
    
    -- En mode unlock, ne pas cacher le frame et afficher des valeurs de preview
    if not IsFlying("player") then
        if isLocked then
            frame:Hide()
        else
            -- Mode unlock: afficher des valeurs de preview
            frame:Show()
            speedBar:SetMinMaxValues(0, 1100)
            speedBar:SetValue(550, Enum.StatusBarInterpolation.ExponentialEaseOut) -- 50% pour preview
            if speedBar.text then
                speedBar.text:SetText("--") -- Pas de cooldown en preview
            end
        end
        return
    end
    
    frame:Show()
    
    -- Calcul de la vitesse (en vol)
    local isGliding, canGlide, forwardSpeed = C_PlayerInfo.GetGlidingInfo()
    
    -- Calculer la vitesse en pourcentage
    local moveSpeed = 0
    if isGliding and forwardSpeed then
        -- Utiliser forwardSpeed avec le multiplicateur approprié
        moveSpeed = Round(forwardSpeed * SPEED_MULTIPLIER * 10) -- Multiplier par 10 pour obtenir le % correct
    else
        -- Fallback sur GetUnitSpeed si pas en gliding
        local speed = GetUnitSpeed("player")
        moveSpeed = Round(speed / BASE_MOVEMENT_SPEED * 100)
    end
    
    -- Limiter entre 0 et 1100
    moveSpeed = math.max(0, math.min(moveSpeed, 1100))
    
    speedBar:SetMinMaxValues(0, 1100)
    speedBar:SetValue(moveSpeed, Enum.StatusBarInterpolation.ExponentialEaseOut)
    
    -- Afficher le cooldown de Vigor
    local durationInfo = C_Spell.GetSpellCooldownDuration(VIGOR_SPELL)
    if durationInfo and speedBar.text then
        local remaining = durationInfo:GetRemainingDuration(0)
        speedBar.text:SetText(string.format("%2d", remaining))
    end
end

-- =====================================
-- UPDATE DES SORTS
-- =====================================
local function UpdateSpells()
    if not IsFlying("player") then
        -- En mode unlock, afficher un preview des charges
        if not isLocked then
            -- Preview: 3 charges Surge Forward (ligne 1)
            if comboBars[1] and maxCombos[1] then
                for i = 1, maxCombos[1] do
                    local bar = comboBars[1][i]
                    if bar then
                        if i <= 3 then
                            -- 3 premières charges pleines
                            local color = STATUSBAR_COLORS[1]
                            bar:SetStatusBarColor(color.r, color.g, color.b)
                            bar:SetMinMaxValues(0, 1)
                            bar:SetValue(1)
                        else
                            -- Autres charges vides
                            bar:SetMinMaxValues(0, 1)
                            bar:SetValue(0)
                        end
                    end
                end
            end
            
            -- Preview: 2 charges Skyward Ascent (ligne 2)
            if comboBars[2] and maxCombos[2] then
                for i = 1, maxCombos[2] do
                    local bar = comboBars[2][i]
                    if bar then
                        if i <= 2 then
                            -- 2 premières charges pleines
                            local color = STATUSBAR_COLORS[2]
                            bar:SetStatusBarColor(color.r, color.g, color.b)
                            bar:SetMinMaxValues(0, 1)
                            bar:SetValue(1)
                        else
                            -- Autres charges vides
                            bar:SetMinMaxValues(0, 1)
                            bar:SetValue(0)
                        end
                    end
                end
            end
        end
        return
    end
    
    CheckSpellCooldown(SURGE_FORWARD_SPELL, 1)
    CheckSpellCooldown(SKYWARD_ASCENT_SPELL, 2)
end

-- =====================================
-- CRÉATION DE L'INTERFACE
-- =====================================
local function CreateUI()
    local settings = GetSettings()
    if not settings then return end
    
    -- Frame principal
    frame = CreateFrame("Frame", "TomoModSkyRideFrame", UIParent)
    frame:SetSize(settings.width, settings.height)
    frame:SetFrameLevel(9600)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    
    -- Setup drag handlers
    frame:SetScript("OnMouseDown", function(self, button)
        if not isLocked and button == "LeftButton" then
            self:StartMoving()
        end
    end)
    
    frame:SetScript("OnMouseUp", function(self, button)
        if not isLocked and button == "LeftButton" then
            self:StopMovingOrSizing()
            SavePosition()
        end
    end)
    
    -- Overlay pour le mode déplacement
    dragOverlay = frame:CreateTexture(nil, "OVERLAY")
    dragOverlay:SetAllPoints()
    dragOverlay:SetColorTexture(1, 1, 1, 0.1)
    dragOverlay:Hide()
    
    dragLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dragLabel:SetPoint("CENTER")
    dragLabel:SetTextColor(1, 1, 0)
    dragLabel:SetText("SKYRIDE\n|cffaaaaaa(Cliquez et glissez)")
    dragLabel:Hide()
    
    -- Barre de vitesse principale
    speedBar = CreateFrame("StatusBar", nil, frame)
    speedBar:SetStatusBarTexture("RaidFrame-Hp-Fill")
    speedBar:GetStatusBarTexture():SetHorizTile(false)
    speedBar:SetMinMaxValues(0, 100)
    speedBar:SetValue(100)
    speedBar:SetSize(settings.width, settings.height)
    speedBar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
    speedBar:EnableMouse(false)
    speedBar:SetStatusBarColor(1, 1, 0)
    
    -- Background de la barre de vitesse
    speedBar.bg = speedBar:CreateTexture(nil, "BACKGROUND")
    speedBar.bg:SetPoint("TOPLEFT", speedBar, "TOPLEFT", -1, 1)
    speedBar.bg:SetPoint("BOTTOMRIGHT", speedBar, "BOTTOMRIGHT", 1, -1)
    speedBar.bg:SetColorTexture(0, 0, 0, 1)
    
    -- Texte (cooldown Vigor)
    speedBar.text = speedBar:CreateFontString(nil, "ARTWORK")
    speedBar.text:SetFont(settings.font or STANDARD_TEXT_FONT, settings.fontSize, settings.fontOutline)
    speedBar.text:SetPoint("CENTER", speedBar, "CENTER", 0, 0)
    speedBar.text:SetTextColor(1, 1, 1, 1)
    
    -- Création des combobars (2 rangées)
    comboBars[1] = {}
    comboBars[2] = {}
    
    -- Première rangée (Surge Forward)
    for i = 1, 10 do
        local bar = CreateFrame("StatusBar", nil, frame)
        bar:SetStatusBarTexture("RaidFrame-Hp-Fill")
        bar:GetStatusBarTexture():SetHorizTile(false)
        bar:SetFrameLevel(9600)
        bar:SetMinMaxValues(0, 100)
        bar:SetValue(100)
        bar:SetHeight(settings.comboHeight)
        bar:SetWidth(20)
        bar:EnableMouse(false)
        bar:SetStatusBarColor(0, 0.8, 0.8)
        
        -- Background
        bar.bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.bg:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
        bar.bg:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
        bar.bg:SetColorTexture(0, 0, 0, 1)
        
        -- Position
        if i == 1 then
            bar:SetPoint("BOTTOMLEFT", speedBar, "TOPLEFT", 0, 1)
        else
            bar:SetPoint("LEFT", comboBars[1][i - 1], "RIGHT", 1, 0)
        end
        
        bar:Hide()
        comboBars[1][i] = bar
    end
    
    -- Deuxième rangée (Skyward Ascent)
    for i = 1, 10 do
        local bar = CreateFrame("StatusBar", nil, frame)
        bar:SetStatusBarTexture("RaidFrame-Hp-Fill")
        bar:GetStatusBarTexture():SetHorizTile(false)
        bar:SetFrameLevel(9600)
        bar:SetMinMaxValues(0, 100)
        bar:SetValue(100)
        bar:SetHeight(settings.comboHeight)
        bar:SetWidth(20)
        bar:EnableMouse(false)
        bar:SetStatusBarColor(0.8, 0.5, 0)
        
        -- Background
        bar.bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.bg:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
        bar.bg:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
        bar.bg:SetColorTexture(0, 0, 0, 1)
        
        -- Position
        if i == 1 then
            bar:SetPoint("BOTTOMLEFT", comboBars[1][1], "TOPLEFT", 0, 1)
        else
            bar:SetPoint("LEFT", comboBars[2][i - 1], "RIGHT", 1, 0)
        end
        
        bar:Hide()
        comboBars[2][i] = bar
    end
    
    ApplyPosition()
    SetLocked(true)
    UpdateVisibility()
end

-- =====================================
-- FONCTIONS D'APPLICATION DES SETTINGS
-- =====================================
function SR.ApplySettings()
    local settings = GetSettings()
    if not settings or not frame then return end
    
    -- Taille
    frame:SetSize(settings.width, settings.height)
    speedBar:SetSize(settings.width, settings.height)
    
    -- Police
    if speedBar.text then
        speedBar.text:SetFont(settings.font or STANDARD_TEXT_FONT, settings.fontSize, settings.fontOutline)
    end
    
    -- Couleur de la barre de vitesse
    speedBar:SetStatusBarColor(
        settings.barColor.r,
        settings.barColor.g,
        settings.barColor.b
    )
    
    -- Hauteur des combobars
    for row = 1, 2 do
        for i = 1, 10 do
            comboBars[row][i]:SetHeight(settings.comboHeight)
        end
    end
    
    ApplyPosition()
    UpdateVisibility()
end

function SR.ResetPosition()
    local settings = GetSettings()
    if not settings then return end
    
    settings.position = {
        point = "BOTTOM",
        relativePoint = "CENTER",
        x = 0,
        y = -180,
    }
    
    ApplyPosition()
    print("|cff00ff00TomoMod:|r " .. TomoMod_L["msg_sr_pos_reset"])
end

function SR.SetEnabled(enabled)
    local settings = GetSettings()
    if not settings then return end
    
    settings.enabled = enabled
    UpdateVisibility()
end

-- =====================================
-- INITIALISATION
-- =====================================
function SR.Initialize()
    if not TomoModDB then
        print("|cffff0000TomoMod SkyRide:|r " .. TomoMod_L["msg_sr_db_not_init"])
        return
    end
    
    -- Initialiser les settings si nécessaire
    if not TomoModDB.skyRide then
        TomoModDB.skyRide = {
            enabled = false, -- Désactivé par défaut
            width = 340,
            height = 20,
            comboHeight = 5,
            font = STANDARD_TEXT_FONT,
            fontSize = 12,
            fontOutline = "OUTLINE",
            barColor = {r = 1, g = 1, b = 0},
            position = {
                point = "BOTTOM",
                relativePoint = "CENTER",
                x = 0,
                y = -180,
            },
        }
    end
    
    -- Créer l'interface
    CreateUI()
    
    -- Démarrer les timers d'update
    updateSpeedTimer = C_Timer.NewTicker(0.2, UpdateSpeed)
    updateSpellTimer = C_Timer.NewTicker(0.2, UpdateSpells)
    
    print("|cff00ff00TomoMod SkyRide:|r " .. TomoMod_L["msg_sr_initialized"])
end

-- Export
_G.TomoMod_SkyRide = SR

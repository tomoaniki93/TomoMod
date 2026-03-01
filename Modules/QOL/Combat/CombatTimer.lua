-- =====================================
-- QOL/Combat/CombatTimer.lua
-- Chronomètre de combat avec rapport dans le chat
--
-- Affiche le temps écoulé depuis l'entrée en combat.
-- À la sortie du combat, imprime la durée dans le chat local.
-- Options : instance only, sticky (garde la dernière valeur), rapport chat.
--
-- Inspiré de NaowhQOL/Modules/CombatTimerDisplay.lua.
-- =====================================

TomoMod_CombatTimer = TomoMod_CombatTimer or {}
local CT = TomoMod_CombatTimer

-- =====================================
-- State
-- =====================================
local combatStartTime   = 0
local lastCombatDuration = 0
local inCombat          = false
local updateAcc         = 0
local UPDATE_INTERVAL   = 1.0   -- rafraîchissement texte toutes les secondes

local function GetDB()
    return TomoModDB and TomoModDB.combatTimer
end

-- =====================================
-- Display frame
-- =====================================
local timerFrame = CreateFrame("Frame", "TomoMod_CombatTimerFrame", UIParent)
timerFrame:SetSize(200, 36)
timerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
timerFrame:SetFrameStrata("MEDIUM")
timerFrame:Hide()

local timerText = timerFrame:CreateFontString(nil, "OVERLAY")
timerText:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf", 22, "OUTLINE")
timerText:SetPoint("CENTER", timerFrame, "CENTER")
timerText:SetJustifyH("CENTER")
timerText:SetTextColor(1, 0.85, 0.1)

-- =====================================
-- Helpers
-- =====================================
local function IsInstanceCheckPassed()
    local db = GetDB()
    if not db or not db.instanceOnly then return true end
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType ~= "none"
end

local function FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%d:%02d", m, s)
end

local function UpdateText()
    local elapsed
    if inCombat then
        elapsed = GetTime() - combatStartTime
    elseif lastCombatDuration > 0 then
        elapsed = lastCombatDuration
    else
        elapsed = 0
    end
    timerText:SetText("⚔ " .. FormatTime(elapsed))
end

-- =====================================
-- Restore saved position
-- =====================================
local function RestorePosition()
    local db = GetDB()
    if not db then return end
    if db.posX and db.posY then
        timerFrame:ClearAllPoints()
        timerFrame:SetPoint("CENTER", UIParent, "CENTER", db.posX, db.posY)
    end
end

-- =====================================
-- Drag support
-- =====================================
local function EnableDrag()
    timerFrame:SetMovable(true)
    timerFrame:SetClampedToScreen(true)
    timerFrame:EnableMouse(true)
    timerFrame:RegisterForDrag("LeftButton")
    timerFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    timerFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint()
        local db = GetDB()
        if db then db.posX = x; db.posY = y end
    end)
end

-- =====================================
-- OnUpdate — throttled
-- =====================================
timerFrame:SetScript("OnUpdate", function(self, elapsed)
    updateAcc = updateAcc + elapsed
    if updateAcc < UPDATE_INTERVAL then return end
    updateAcc = 0
    if inCombat then UpdateText() end
end)

-- =====================================
-- Chat report
-- =====================================
local function ChatReport(duration)
    local db = GetDB()
    if not db or db.chatReport == false then return end

    local h = math.floor(duration / 3600)
    local m = math.floor((duration % 3600) / 60)
    local s = math.floor(duration % 60)

    local timeStr
    if h > 0 then
        timeStr = string.format("%dh %02dm %02ds", h, m, s)
    elseif m > 0 then
        timeStr = string.format("%dm %02ds", m, s)
    else
        timeStr = string.format("%ds", s)
    end

    print("|cff0cd29fTomoMod|r ⚔ Combat terminé — durée : |cffffff00" .. timeStr .. "|r")
end

-- =====================================
-- API publique
-- =====================================
function CT.SetEnabled(v)
    local db = GetDB()
    if not db then return end
    db.enabled = v
    if not v then
        inCombat = false
        timerFrame:Hide()
    end
end

function CT.ApplySettings()
    local db = GetDB()
    if not db or not db.enabled then
        timerFrame:Hide()
        return
    end
    RestorePosition()
    if inCombat then
        UpdateText()
        timerFrame:Show()
    elseif db.stickyTimer and lastCombatDuration > 0 and IsInstanceCheckPassed() then
        UpdateText()
        timerFrame:Show()
    end
end

-- =====================================
-- Event handler
-- =====================================
local eventFrame = CreateFrame("Frame", "TomoMod_CombatTimerEvents")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Auto-initialise la section DB si absente
        if TomoModDB and not TomoModDB.combatTimer then
            TomoModDB.combatTimer = {
                enabled      = true,
                chatReport   = true,
                instanceOnly = false,
                stickyTimer  = false,
            }
        end
        local db = GetDB()
        if not db or not db.enabled then return end
        RestorePosition()
        EnableDrag()
        return
    end

    local db = GetDB()
    if not db or not db.enabled then return end

    if event == "PLAYER_REGEN_DISABLED" then
        if db.instanceOnly and not IsInstanceCheckPassed() then return end
        inCombat        = true
        combatStartTime = GetTime()
        updateAcc       = UPDATE_INTERVAL   -- force refresh immédiat
        UpdateText()
        timerFrame:Show()

    elseif event == "PLAYER_REGEN_ENABLED" then
        if inCombat then
            lastCombatDuration = GetTime() - combatStartTime
            ChatReport(lastCombatDuration)
        end
        inCombat = false

        if db.stickyTimer and lastCombatDuration > 0 and IsInstanceCheckPassed() then
            UpdateText()
            timerFrame:Show()
        else
            timerFrame:Hide()
        end
    end
end)

TomoMod_RegisterModule("combatTimer", CT)

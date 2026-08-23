-- =====================================
-- BagMicroMenu.lua
-- Gère la barre de sac et le micro menu Blizzard natif
-- avec option de survol à la souris.
--
-- Important:
--   - TomoMod ne remplace plus le MicroMenu Blizzard.
--   - le fade n'agit plus sur MicroMenuContainer mais seulement sur MicroMenu,
--     afin de ne pas faire disparaître l'oeil LFG.
--   - l'oeil LFG reste Blizzard natif ; TomoMod conserve seulement ON/OFF + taille.
-- =====================================

TomoMod_BagMicroMenu = TomoMod_BagMicroMenu or {}
local BMM = TomoMod_BagMicroMenu

local FADE_IN_TIME = 0.15
local FADE_OUT_TIME = 0.3
local FADE_OUT_ALPHA = 0

-- =====================================
-- FRAMES CIBLES
-- =====================================

local function GetBagBarFrame()
    return _G.BagsBar or _G.MicroMenuContainer and _G.MicroMenuContainer:GetParent()
end

local function GetMicroMenuFrame()
    return _G.MicroMenu
end

local function EnsureBagDB()
    if not TomoModDB.bagMicroMenu then
        TomoModDB.bagMicroMenu = {
            bagBarMode = "show",
            microMenuMode = "show",
        }
    end
    return TomoModDB.bagMicroMenu
end

local function EnsureEyeDB()
    if not TomoModDB.microBar then
        TomoModDB.microBar = {}
    end
    if TomoModDB.microBar.lfgEyeEnabled == nil then
        TomoModDB.microBar.lfgEyeEnabled = true
    end
    if TomoModDB.microBar.lfgEyeScale == nil then
        TomoModDB.microBar.lfgEyeScale = 1.0
    end
    return TomoModDB.microBar
end

-- =====================================
-- HOVER LOGIC
-- =====================================

local function IsMouseOverFrame(frame)
    if not frame or not frame:IsShown() then return false end
    if frame:IsMouseOver() then return true end

    for _, child in ipairs({ frame:GetChildren() }) do
        if child:IsMouseOver() then return true end
    end
    return false
end

local function SetupHoverForFrame(frame, onEnter, onLeave)
    if not frame then return end

    frame:HookScript("OnEnter", onEnter)
    frame:HookScript("OnLeave", onLeave)

    for _, child in ipairs({ frame:GetChildren() }) do
        if child:HasScript("OnEnter") then
            child:HookScript("OnEnter", onEnter)
            child:HookScript("OnLeave", onLeave)
        else
            child:SetScript("OnEnter", onEnter)
            child:SetScript("OnLeave", onLeave)
        end
    end
end

local function FadeIn(frame)
    if not frame then return end
    UIFrameFadeIn(frame, FADE_IN_TIME, frame:GetAlpha(), 1)
end
local function FadeOut(frame)
    if not frame then return end
    UIFrameFadeOut(frame, FADE_OUT_TIME, frame:GetAlpha(), FADE_OUT_ALPHA)
end

-- =====================================
-- APPLICATION DES REGLAGES
-- =====================================

local hookedBagBar = false
local hookedMicroMenu = false

local function ApplyBagBar()
    local settings = TomoModDB and TomoModDB.bagMicroMenu
    if not settings then return end

    local bagBar = GetBagBarFrame()
    if not bagBar then return end

    if settings.bagBarMode == "hover" then
        bagBar:SetAlpha(FADE_OUT_ALPHA)

        if not hookedBagBar then
            hookedBagBar = true

            local function OnEnter()
                local s = TomoModDB and TomoModDB.bagMicroMenu
                if s and s.bagBarMode == "hover" then
                    FadeIn(bagBar)
                end
            end

            local function OnLeave()
                local s = TomoModDB and TomoModDB.bagMicroMenu
                if s and s.bagBarMode == "hover" then
                    C_Timer.After(0.2, function()
                        if not IsMouseOverFrame(bagBar) then
                            FadeOut(bagBar)
                        end
                    end)
                end
            end

            SetupHoverForFrame(bagBar, OnEnter, OnLeave)
        end
    else
        bagBar:SetAlpha(1)
    end
end

local function ApplyMicroMenu()
    local settings = TomoModDB and TomoModDB.bagMicroMenu
    if not settings then return end

    local microMenu = GetMicroMenuFrame()
    if not microMenu then return end

    if settings.microMenuMode == "hover" then
        microMenu:SetAlpha(FADE_OUT_ALPHA)

        if not hookedMicroMenu then
            hookedMicroMenu = true

            local function OnEnter()
                local s = TomoModDB and TomoModDB.bagMicroMenu
                if s and s.microMenuMode == "hover" then
                    FadeIn(microMenu)
                end
            end

            local function OnLeave()
                local s = TomoModDB and TomoModDB.bagMicroMenu
                if s and s.microMenuMode == "hover" then
                    C_Timer.After(0.2, function()
                        if not IsMouseOverFrame(microMenu) then
                            FadeOut(microMenu)
                        end
                    end)
                end
            end

            SetupHoverForFrame(microMenu, OnEnter, OnLeave)
        end
    else
        microMenu:SetAlpha(1)
    end
end

local function ApplyLFGEye()
    local btn = _G["QueueStatusButton"]
    if not btn then return end

    local db = EnsureEyeDB()
    local visible = db.lfgEyeEnabled ~= false
    local scale = tonumber(db.lfgEyeScale) or 1.0

    btn:SetScale(scale)
    btn:SetAlpha(visible and 1 or 0)
    btn:EnableMouse(visible and true or false)
end

function BMM.ApplySettings()
    ApplyBagBar()
    ApplyMicroMenu()
    ApplyLFGEye()
end

-- =====================================
-- INITIALISATION
-- =====================================

local eventFrame = nil

function BMM.Initialize()
    if not TomoModDB then return end

    EnsureBagDB()
    EnsureEyeDB()

    if not eventFrame then
        eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("LFG_UPDATE")
        eventFrame:RegisterEvent("LFG_QUEUE_STATUS_UPDATE")
        eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
        eventFrame:SetScript("OnEvent", function()
            C_Timer.After(0, function()
                BMM.ApplySettings()
            end)
        end)
    end

    C_Timer.After(1, function()
        BMM.ApplySettings()
    end)
end

function BMM.SetBagBarMode(mode)
    EnsureBagDB().bagBarMode = mode
    ApplyBagBar()
end

function BMM.SetMicroMenuMode(mode)
    EnsureBagDB().microMenuMode = mode
    ApplyMicroMenu()
end

function BMM.SetLFGEyeEnabled(enabled)
    EnsureEyeDB().lfgEyeEnabled = enabled and true or false
    ApplyLFGEye()
end

function BMM.SetLFGEyeScale(scale)
    EnsureEyeDB().lfgEyeScale = tonumber(scale) or 1.0
    ApplyLFGEye()
end

_G.TomoMod_BagMicroMenu = BMM

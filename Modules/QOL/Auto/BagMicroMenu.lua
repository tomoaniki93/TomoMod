-- =====================================
-- BagMicroMenu.lua
-- Cache la barre de sac et le micro menu
-- avec option de survol à la souris
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
    return _G.MicroMenu or _G.MicroMenuContainer
end

-- =====================================
-- HOVER LOGIC
-- =====================================

local hoverFrame = nil

local function IsMouseOverFrame(frame)
    if not frame or not frame:IsShown() then return false end
    if frame:IsMouseOver() then return true end
    -- Vérifier aussi les enfants (boutons)
    for _, child in ipairs({ frame:GetChildren() }) do
        if child:IsMouseOver() then return true end
    end
    return false
end

local function SetupHoverForFrame(frame, onEnter, onLeave)
    if not frame then return end

    frame:HookScript("OnEnter", onEnter)
    frame:HookScript("OnLeave", onLeave)

    -- Hook aussi les enfants (boutons individuels)
    for _, child in ipairs({ frame:GetChildren() }) do
        if child:HasScript("OnEnter") then
            child:HookScript("OnEnter", onEnter)
            child:HookScript("OnLeave", onLeave)
        else
            child:EnableMouse(true)
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
-- APPLICATION DES RÉGLAGES
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
        -- Mode "show" : toujours visible
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
        -- Mode "show" : toujours visible
        microMenu:SetAlpha(1)
    end
end

function BMM.ApplySettings()
    ApplyBagBar()
    ApplyMicroMenu()
end

-- =====================================
-- INITIALISATION
-- =====================================

function BMM.Initialize()
    if not TomoModDB then return end

    if not TomoModDB.bagMicroMenu then
        TomoModDB.bagMicroMenu = {
            bagBarMode = "show",
            microMenuMode = "show",
        }
    end

    -- Attendre que les frames soient prêtes
    C_Timer.After(1, function()
        BMM.ApplySettings()
    end)
end

function BMM.SetBagBarMode(mode)
    if not TomoModDB or not TomoModDB.bagMicroMenu then return end
    TomoModDB.bagMicroMenu.bagBarMode = mode
    ApplyBagBar()
end

function BMM.SetMicroMenuMode(mode)
    if not TomoModDB or not TomoModDB.bagMicroMenu then return end
    TomoModDB.bagMicroMenu.microMenuMode = mode
    ApplyMicroMenu()
end

-- Export
_G.TomoMod_BagMicroMenu = BMM

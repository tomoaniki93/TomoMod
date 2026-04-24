-- =====================================
-- Modules/Housing/HousingCore.lua — Editor mode controller
-- Adapté de Plumber/HouseEditor_Main.lua
--
-- Role :
--   - Enregistre les sous-modules (handlers) qui réagissent aux changements
--     de mode de l'éditeur de maison (BasicDecor, Customize, Layout...).
--   - Les handlers "alwaysOn" tournent tant que l'éditeur est actif.
--   - Les handlers par mode s'activent/se désactivent selon le mode courant.
-- =====================================

TomoMod_Housing = TomoMod_Housing or {}
local H = TomoMod_Housing
local L = TomoMod_L

-- Controller frame
local Controller = CreateFrame("Frame")
H.Controller = Controller
Controller.modeHandlers     = {}   -- [modeEnum] = handler
Controller.alwaysOnHandlers = {}   -- array

local function GetHousingAPI()
    return H.API
end

local function IsHousingAvailable()
    local API = GetHousingAPI()
    return API and API.IsHousingAvailable()
end

-- =====================================
-- REGISTRATION
-- =====================================

function Controller.AddSubModule(modeHandler)
    if modeHandler.alwaysOn then
        table.insert(Controller.alwaysOnHandlers, modeHandler)
        return
    end

    local modeID = Enum and Enum.HouseEditorMode and Enum.HouseEditorMode[modeHandler.editMode]
    if modeID then
        Controller.modeHandlers[modeID] = modeHandler
    end
end

-- Called when Blizzard_HouseEditor addon finishes loading
local function Blizzard_HouseEditor_OnLoaded()
    Controller.blizzardAddOnLoaded = true
    for _, handler in pairs(Controller.modeHandlers) do
        if handler.BlizzardHouseEditorLoaded then
            handler:BlizzardHouseEditorLoaded()
        end
    end
    for _, handler in ipairs(Controller.alwaysOnHandlers) do
        if handler.BlizzardHouseEditorLoaded then
            handler:BlizzardHouseEditorLoaded()
        end
    end
end

function Controller:IsBlizzardHouseEditorLoaded()
    return self.blizzardAddOnLoaded
end

-- =====================================
-- MODE HANDLING
-- =====================================

function Controller:InitSubModules()
    if not IsHousingAvailable() then return end

    local anyEnabled
    for _, handler in pairs(self.modeHandlers) do
        if handler:IsEnabled() then anyEnabled = true end
    end
    for _, handler in ipairs(self.alwaysOnHandlers) do
        if handler:IsEnabled() then anyEnabled = true end
    end

    if anyEnabled then
        self:RegisterEvent("HOUSE_EDITOR_MODE_CHANGED")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
    else
        self:UnregisterEvent("HOUSE_EDITOR_MODE_CHANGED")
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end

    self:UpdateActiveMode()
end

function Controller:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        if not (H.API and H.API.IsHouseEditorActive()) then
            self:UnregisterEvent(event)
            self:OnActiveModeChanged()
        end
    elseif event == "HOUSE_EDITOR_MODE_CHANGED" then
        local newMode = ...
        self:OnActiveModeChanged(newMode)
    end
end
Controller:SetScript("OnEvent", Controller.OnEvent)

function Controller:OnActiveModeChanged(newMode)
    if not newMode then newMode = 0 end

    -- Swap the per-mode handler
    if self.activeModeHandler then
        if self.activeModeHandler == self.modeHandlers[newMode] then
            -- Same handler → nothing to do
        else
            self.activeModeHandler:Deactivate()
            self.activeModeHandler = nil
        end
    end

    if self.modeHandlers[newMode] then
        self.modeHandlers[newMode]:Activate()
        self.activeModeHandler = self.modeHandlers[newMode]
    end

    -- Toggle alwaysOn handlers based on editor state
    if newMode ~= 0 then
        if not self.isEditingHouse then
            self.isEditingHouse = true
            for _, handler in ipairs(self.alwaysOnHandlers) do
                handler:Activate()
            end
        end
    else
        if self.isEditingHouse then
            self.isEditingHouse = false
            for _, handler in ipairs(self.alwaysOnHandlers) do
                handler:Deactivate()
            end
        end
    end
end

function Controller:UpdateActiveMode()
    if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_HouseEditor") then
        if C_HouseEditor and C_HouseEditor.GetActiveHouseEditorMode then
            self:OnActiveModeChanged(C_HouseEditor.GetActiveHouseEditorMode())
        end
    end
end

function Controller:RequestUpdate()
    if not self.pauseUpdate then
        self.pauseUpdate = true
        C_Timer.After(0, function()
            self.pauseUpdate = nil
            self:InitSubModules()
        end)
    end
end

-- =====================================
-- SHARED HANDLER MIXIN
-- =====================================

local HandlerMixin = {}

function HandlerMixin:Activate()
    if not self:IsEnabled() then return end
    if self.activated then return end
    self.activated = true

    if self.Init then
        self:Init()
    end
    self:OnActivated()
end

function HandlerMixin:Deactivate()
    if not self.activated then return end
    self.activated = nil
    self:OnDeactivated()
end

function HandlerMixin:OnActivated() end
function HandlerMixin:OnDeactivated() end

function HandlerMixin:IsEnabled()
    return self.enabled and true or false
end

function HandlerMixin:SetEnabled(state)
    state = state and true or false
    if state == (self.enabled and true or false) then return end
    if state then
        self.enabled = true
    else
        self.enabled = nil
        self:Deactivate()
    end
    Controller:RequestUpdate()
end

-- Factory: create a mode handler
-- editMode = "AnyMode" for alwaysOn, or "BasicDecor", "Customize", "Layout", etc.
function Controller.CreateModeHandler(editMode)
    local handler = CreateFrame("Frame")
    Mixin(handler, HandlerMixin)
    if editMode == "AnyMode" then
        handler.alwaysOn = true
    else
        handler.editMode = editMode
    end
    Controller.AddSubModule(handler)
    return handler
end

-- =====================================
-- BOOTSTRAP
-- Hook into Blizzard_HouseEditor load event so submodules can inject UI
-- into HouseEditorFrame when it becomes available.
-- =====================================

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("ADDON_LOADED")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_HouseEditor" then
        Blizzard_HouseEditor_OnLoaded()
    elseif event == "PLAYER_LOGIN" then
        -- If the editor addon was already loaded at login, catch it now
        if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_HouseEditor") then
            Blizzard_HouseEditor_OnLoaded()
        end
        -- Kick off submodule initialisation
        C_Timer.After(0.5, function()
            if IsHousingAvailable() then
                H.Refresh()  -- sync handler enabled state from DB before init
                Controller:InitSubModules()
            end
        end)
    end
end)

-- =====================================
-- PUBLIC API FOR TomoMod MODULE SYSTEM
-- =====================================

-- Let the main TomoMod.ApplyAllSettings() or panel callbacks call this
-- to refresh enabled/disabled state after user toggles DB options.
function H.Refresh()
    if not TomoModDB or not TomoModDB.housing then return end
    local db = TomoModDB.housing

    -- Forward enable flags to each named handler (handlers define a .dbKey).
    -- No housing API calls here, so no IsHousingAvailable() guard needed.
    if H.Handlers then
        for _, handler in pairs(H.Handlers) do
            if handler.dbKey then
                handler:SetEnabled(db[handler.dbKey] == true)
            end
        end
    end

    -- If housing APIs are present, kick a controller re-init so event
    -- registration reflects the new enabled states.
    if IsHousingAvailable() then
        Controller:RequestUpdate()
    end
end

H.Handlers = H.Handlers or {}
-- =====================================
-- Modules/Housing/TeleportMacros.lua
-- Adapté de Plumber/Housing_ActionButton.lua + Housing_Macro.lua
--
-- Ce que fait ce module :
--   - Crée 4 boutons sécurisés invisibles capables d'exécuter les actions
--     natives de téléportation Housing :
--       * CurrentFaction : téléport vers la maison de la faction active
--       * Alliance       : téléport vers la maison Alliance (Founder's Point)
--       * Horde          : téléport vers la maison Horde (Razorwind Shores)
--       * Leave          : quitter la maison visitée et revenir au point de départ
--   - Expose un slash `/tm home` qui déclenche le bouton approprié selon
--     l'état courant (visite en cours = leave, sinon = teleport home).
--
-- IMPORTANT : les actions de type "teleporthome" / "returnhome" sont des
-- actions protégées ; elles doivent passer par un SecureActionButtonTemplate
-- et ne peuvent PAS être modifiées en combat.
-- =====================================

TomoMod_Housing = TomoMod_Housing or {}
local H = TomoMod_Housing
local L = TomoMod_L

H.TeleportHomeButtons = H.TeleportHomeButtons or {}
local Buttons = H.TeleportHomeButtons

-- =====================================
-- BUTTON MIXIN (secure action setup)
-- =====================================

local TeleportButtonMixin = {}

function TeleportButtonMixin:SetAction_TeleportHome(neighborhoodGUID, houseGUID, plotID)
    self.neighborhoodGUID = neighborhoodGUID
    self.houseGUID        = houseGUID
    self.plotID           = plotID

    if InCombatLockdown() then
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.setupFunc = self.SetAction_TeleportHome
        return
    end

    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self:SetAttribute("useOnKeyDown", false)
    self:RegisterForClicks("AnyDown", "AnyUp")
    self:SetScript("PostClick", self.PostClick)

    if neighborhoodGUID and houseGUID and plotID then
        self:SetAttribute("type", "teleporthome")
        self:SetAttribute("house-neighborhood-guid", neighborhoodGUID)
        self:SetAttribute("house-guid", houseGUID)
        self:SetAttribute("house-plot-id", plotID)
    else
        self:SetAttribute("type", nil)
    end
end

function TeleportButtonMixin:SetAction_ReturnHome()
    self.neighborhoodGUID = nil
    self.houseGUID        = nil
    self.plotID           = nil

    if InCombatLockdown() then
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.setupFunc = self.SetAction_ReturnHome
        return
    end

    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self:SetAttribute("useOnKeyDown", false)
    self:RegisterForClicks("AnyDown", "AnyUp")
    self:SetScript("PostClick", self.PostClick)
    self:SetAttribute("type", "returnhome")
end

function TeleportButtonMixin:OnEvent(event)
    if event == "PLAYER_REGEN_ENABLED" and self.setupFunc then
        self.setupFunc(self, self.neighborhoodGUID, self.houseGUID, self.plotID)
    end
end

function TeleportButtonMixin:PostClick()
    if self:GetAttribute("type") == "teleporthome" then
        if H.API and H.API.CheckTeleportInCooldown then
            H.API.CheckTeleportInCooldown()
        end
    end
    -- Clean up any prompt display triggered by ShowTeleportPrompt()
    self:HidePrompt()
    if H._promptTimer then
        H._promptTimer:Cancel()
        H._promptTimer = nil
    end
end

function TeleportButtonMixin:ShowAsPrompt(label)
    if not self.promptLabel then
        self:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        self:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        self:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        self:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        self:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
        self:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        self.promptLabel = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        self.promptLabel:SetPoint("CENTER", self, "CENTER")
    end
    self.promptLabel:SetText(label or "Téléporter")
    self:ClearAllPoints()
    self:SetSize(220, 36)
    self:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    self:Show()
end

function TeleportButtonMixin:HidePrompt()
    if not self:IsShown() then return end
    self:Hide()
    self:SetSize(1, 1)
    self:SetPoint("BOTTOMRIGHT", UIParent, "TOPLEFT", -1, -1)
end

-- =====================================
-- BUTTON CREATION
-- =====================================

local function CreateTeleportHomeButton(index)
    local f = CreateFrame("Button", "TomoMod_HousingHome" .. index, UIParent, "SecureActionButtonTemplate")
    Mixin(f, TeleportButtonMixin)
    f:SetSize(1, 1)
    f:SetPoint("BOTTOMRIGHT", UIParent, "TOPLEFT", -1, -1) -- offscreen
    f:SetScript("OnEvent", f.OnEvent)
    return f
end

local ButtonKeys = { "CurrentFaction", "Alliance", "Horde", "Leave" }
for index, key in ipairs(ButtonKeys) do
    Buttons[key] = CreateTeleportHomeButton(index)
end

-- Leave button always uses "returnhome" action
Buttons.Leave:SetAction_ReturnHome()

-- =====================================
-- MACRO GETTERS (for players who want to drag an action to their bar)
-- =====================================

function H.GetTeleportHomeMacro()
    return "/click " .. Buttons.CurrentFaction:GetName()
end

function H.GetTeleportAllianceHomeMacro()
    return "/click " .. Buttons.Alliance:GetName()
end

function H.GetTeleportHordeHomeMacro()
    return "/click " .. Buttons.Horde:GetName()
end

function H.GetLeaveHomeMacro()
    return "/click " .. Buttons.Leave:GetName()
end

-- =====================================
-- PUBLIC API : smart teleport
-- Picks the right button based on current state and faction.
-- =====================================

function H.SmartTeleportHome()
    if InCombatLockdown() then
        if UIErrorsFrame and UIErrorsFrame.TryDisplayMessage then
            UIErrorsFrame:TryDisplayMessage(0, ERR_AFFECTING_COMBAT or "Can't do that in combat.", 1, 0.1, 0.1)
        end
        return
    end

    -- If we're currently visiting a house, leave it
    if C_HousingNeighborhood and C_HousingNeighborhood.CanReturnAfterVisitingHouse
       and C_HousingNeighborhood.CanReturnAfterVisitingHouse() then
        if Buttons.Leave then Buttons.Leave:Click() end
        return
    end

    -- Otherwise teleport to current faction house
    if H.API and H.API.CheckTeleportInCooldown and H.API.CheckTeleportInCooldown() then
        return -- cooldown message already shown
    end
    if Buttons.CurrentFaction then
        Buttons.CurrentFaction:Click()
    end
end

-- =====================================
-- PUBLIC API : show a clickable on-screen prompt
-- TeleportHome() is a protected C function; it can only execute through a
-- SecureActionButtonTemplate triggered by a real hardware click.  Calling
-- Button:Click() from a slash-command or config-panel OnClick (both
-- non-secure contexts) raises ADDON_ACTION_FORBIDDEN / taint.
-- ShowTeleportPrompt() surfaces the appropriate secure button at the centre
-- of the screen so the player physically clicks it (one extra click).
-- =====================================

function H.ShowTeleportPrompt()
    if InCombatLockdown() then
        if UIErrorsFrame and UIErrorsFrame.TryDisplayMessage then
            UIErrorsFrame:TryDisplayMessage(0, ERR_AFFECTING_COMBAT or "Can't do that in combat.", 1, 0.1, 0.1)
        end
        return
    end

    local btn, label
    if C_HousingNeighborhood and C_HousingNeighborhood.CanReturnAfterVisitingHouse
       and C_HousingNeighborhood.CanReturnAfterVisitingHouse() then
        btn   = Buttons.Leave
        label = L and L["btn_housing_leave"] or "Quitter la maison"
    else
        if H.API and H.API.CheckTeleportInCooldown and H.API.CheckTeleportInCooldown() then
            return -- cooldown message already shown
        end
        btn   = Buttons.CurrentFaction
        label = L and L["btn_housing_tp_home"] or "Aller à la maison"
    end

    if not btn then return end

    -- Cancel any previous auto-hide timer and reset all prompt buttons
    if H._promptTimer then
        H._promptTimer:Cancel()
        H._promptTimer = nil
    end
    for _, b in pairs(Buttons) do
        b:HidePrompt()
    end

    btn:ShowAsPrompt(label)

    H._promptTimer = C_Timer.NewTimer(5, function()
        btn:HidePrompt()
        H._promptTimer = nil
    end)
end

-- =====================================
-- BOOT: request house list on login + zone change
-- =====================================

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("PLAYER_ENTERING_WORLD")
boot:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(2, function()
            if H.API and H.API.IsHousingAvailable() and H.API.RequestUpdateHouseInfo then
                H.API.RequestUpdateHouseInfo()
            end
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        if H.API and H.API.IsHousingAvailable() and H.API.RequestUpdateHouseInfo then
            C_Timer.After(1, H.API.RequestUpdateHouseInfo)
        end
    end
end)
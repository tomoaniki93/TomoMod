-- =====================================================================
-- Ported from Tui: TUI_ActionBars/actionbars/actionbars_editmode.lua
--
-- Every edit made to this file is marked with "TOMOMOD:" so upstream changes
-- stay diffable. Do not reformat: the point of keeping it verbatim is that a
-- newer Tui revision can be re-imported by replaying the same edits.
-- =====================================================================
local ADDON_NAME, ns = "TomoMod", TomoMod_TuiNS -- TOMOMOD: was `...`
local env = ns.ActionBarsEnv
env.ADDON_NAME = ADDON_NAME
env.ns = ns
env.SetChunkEnv(1, env)

---@diagnostic disable: lowercase-global -- SetChunkEnv installs a setfenv

local function ApplyContainerDragState(container, barKey)
    if not container then return end
    container:EnableMouse(true)
    container:SetMovable(true)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart", function(self, button)
        if button ~= "LeftButton" then return end
        if not ActionBarsOwned or not ActionBarsOwned.editModeActive then return end
        self:StartMoving()
    end)
    container:SetScript("OnDragStop", function(self)
        if not ActionBarsOwned or not ActionBarsOwned.editModeActive then return end
        self:StopMovingOrSizing()
        if barKey then
            SaveContainerPosition(barKey)
        end
    end)
    container:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        if not ActionBarsOwned or not ActionBarsOwned.editModeActive then return end
        self:StartMoving()
    end)
    container:SetScript("OnMouseUp", function(self)
        if not ActionBarsOwned or not ActionBarsOwned.editModeActive then return end
        if self.isMoving then
            self:StopMovingOrSizing()
            self.isMoving = nil
            if barKey then
                SaveContainerPosition(barKey)
            end
        end
    end)
end

function CreateEditOverlay(container, barKey)
    ApplyContainerDragState(container, barKey)

    local overlay = CreateFrame("Frame", nil, container, "BackdropTemplate")
    overlay:SetAllPoints(container)
    -- TomoMod teal, matching the rest of the /tm layout movers
    ns.SkinBase.ApplyPixelBackdrop(overlay, 2, true, false, {0.047, 0.824, 0.624, 1}, {0.047, 0.824, 0.624, 0.3})
    overlay:EnableMouse(true)
    overlay:SetMovable(true)
    overlay:RegisterForDrag("LeftButton")
    overlay:SetFrameStrata("HIGH")
    overlay:Hide()

    local text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetTextColor(1, 1, 1, 1)
    local displayName = barKey:gsub("bar", "Bar ")
    text:SetText(displayName)
    overlay.label = text

    overlay:SetScript("OnDragStart", function(self, button)
        if button ~= "LeftButton" then return end
        if not ActionBarsOwned or not ActionBarsOwned.editModeActive then return end
        container:StartMoving()
        self:StartMoving()
    end)

    overlay:SetScript("OnDragStop", function(self)
        if not ActionBarsOwned or not ActionBarsOwned.editModeActive then return end
        container:StopMovingOrSizing()
        self:StopMovingOrSizing()
        SaveContainerPosition(barKey)
    end)

    return overlay
end

function EnsureEditOverlay(barKey)
    local container = ActionBarsOwned.containers[barKey]
    if not container then return nil end

    local overlay = ActionBarsOwned.editOverlays[barKey]
    if not overlay then
        overlay = CreateEditOverlay(container, barKey)
        ActionBarsOwned.editOverlays[barKey] = overlay
    end

    return overlay
end

function SetEditOverlayVisible(barKey, visible)
    local overlay = EnsureEditOverlay(barKey)
    if not overlay then return end

    if visible then
        overlay:Show()
    else
        overlay:Hide()
    end
end

function OnEditModeEnter()
    ActionBarsOwned.editModeActive = true
    if ActionBarsOwned.HideOwnedFlyout then
        ActionBarsOwned.HideOwnedFlyout()
    end

    for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
        local container = ActionBarsOwned.containers[barKey]
        if container then
            LayoutNativeButtons(barKey)
            ApplyContainerDragState(container, barKey)
            container:SetMovable(true)

            local state = GetOwnedBarFadeState(barKey)
            state.isFading = false
            CancelOwnedBarFadeTimers(state)
            SetOwnedBarAlpha(barKey, 1)

            SetEditOverlayVisible(barKey, true)
        end
    end
end

function OnEditModeExit()
    ActionBarsOwned.editModeActive = false

    for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
        if ActionBarsOwned.editOverlays[barKey] then
            ActionBarsOwned.editOverlays[barKey]:Hide()
        end

        SaveContainerPosition(barKey)
        LayoutNativeButtons(barKey)
        SetupOwnedBarMouseover(barKey)
    end
end

function ActionBarsOwned.SetEditModeEnabled(enabled)
    if not ActionBarsOwned then return end
    if not ActionBarsOwned.initialized then
        if type(ActionBarsOwned.Initialize) == "function" then
            ActionBarsOwned:Initialize()
        end
        if not ActionBarsOwned.initialized then
            return
        end
    end

    if enabled then
        OnEditModeEnter()
    else
        OnEditModeExit()
    end
end

function IsVehicleBarActive()
    return (HasVehicleActionBar and HasVehicleActionBar())
        or (HasOverrideActionBar and HasOverrideActionBar())
        or (UnitInVehicle and UnitInVehicle("player"))
end

function IsPetBattleActive()
    return C_PetBattles and C_PetBattles.IsInBattle and C_PetBattles.IsInBattle()
end

function ApplyBarOverrideBindings(barKey)
    if InCombatLockdown() and not inInitSafeWindow then
        ActionBarsOwned.pendingBindings = true
        return
    end

    local container = ActionBarsOwned.containers[barKey]
    if not container then return end

    ClearOverrideBindings(container)

    if barKey == "bar1" and IsVehicleBarActive() then
        return
    end

    if IsPetBattleActive() then
        return
    end

    if ActionBarsOwned._inHousing then
        return
    end

    local buttons = ActionBarsOwned.nativeButtons[barKey]
    local prefix = BINDING_COMMANDS[barKey]
    if not buttons or not prefix then return end

    for i, btn in ipairs(buttons) do
        local command = prefix .. i
        for ki = 1, select("#", GetBindingKey(command)) do
            local key = select(ki, GetBindingKey(command))
            if key then
                local existing = GetBindingAction(key, true)
                if not existing or existing == "" or existing == command then
                    local vBtn = ((barKey == "pet" or barKey == "stance") or btn:GetAttribute("gse-button"))
                        and "LeftButton" or "Keybind"
                    SetOverrideBindingClick(container, false, key, btn:GetName(), vBtn)
                end
            end
        end
    end
end

function ApplyAllOverrideBindings()
    for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
        ApplyBarOverrideBindings(barKey)
    end
end

ApplyBar1OverrideBindings = function() ApplyBarOverrideBindings("bar1") end

function BuildPagingCondition()
    local parts = {}
    table.insert(parts, "[overridebar] override")
    table.insert(parts, "[vehicleui][possessbar][shapeshift] possess")
    table.insert(parts, "[bonusbar:5] 11")
    for i = 4, 1, -1 do
        table.insert(parts, "[bonusbar:" .. i .. "] " .. (6 + i))
    end
    for i = 6, 2, -1 do
        table.insert(parts, "[bar:" .. i .. "] " .. i)
    end
    table.insert(parts, "1")
    return table.concat(parts, "; ")
end

bar1PagingInitialized = false

function SetupBar1Paging(container)
    if bar1PagingInitialized then return end
    bar1PagingInitialized = true

    container:SetAttribute("_onstate-page", [[
        local page = newstate
        if page == "override" then
            if HasVehicleActionBar and HasVehicleActionBar() then
                page = GetVehicleBarIndex()
            elseif HasOverrideActionBar and HasOverrideActionBar() then
                page = GetOverrideBarIndex()
            elseif HasTempShapeshiftActionBar and HasTempShapeshiftActionBar() then
                page = GetTempShapeshiftBarIndex()
            else
                page = 1
            end
        elseif page == "possess" then
            if HasVehicleActionBar and HasVehicleActionBar() then
                page = GetVehicleBarIndex()
            elseif HasOverrideActionBar and HasOverrideActionBar() then
                page = GetOverrideBarIndex()
            elseif HasTempShapeshiftActionBar and HasTempShapeshiftActionBar() then
                page = GetTempShapeshiftBarIndex()
            elseif HasBonusActionBar and HasBonusActionBar() then
                page = GetBonusBarIndex()
            else
                page = 1
            end
        end
        page = tonumber(page) or 1
        local offset = (page - 1) * 12
        control:ChildUpdate("offset", offset)
    ]])
    RegisterStateDriver(container, "page", BuildPagingCondition())
end


function SetupSecureActionFlagRefresh(container)
    if not container or container._tomomodActionFlagRefreshSetup then return end
    container._tomomodActionFlagRefreshSetup = true
    container:SetAttribute("qui-refresh-target", nil)
    container:SetAttribute("_onattributechanged", [[
        if name ~= "qui-refresh-target" then return end
        local ref = value and self:GetFrameRef(value)
        if ref then
            ref:RunAttribute("TUI_UpdateActionFlags")
        end
    ]])
end

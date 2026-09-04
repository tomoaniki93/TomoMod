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
    ns.SkinBase.ApplyPixelBackdrop(overlay, 2, true, false, {0.180, 0.616, 0.847, 1}, {0.180, 0.616, 0.847, 0.3})
    overlay:EnableMouse(true)
    overlay:SetMovable(true)
    overlay:RegisterForDrag("LeftButton")
    overlay:SetFrameStrata("HIGH")
    if TomoMod_Utils and TomoMod_Utils.RegisterMoverLayer then
        TomoMod_Utils.RegisterMoverLayer(overlay, container)
    end
    overlay:Hide()

    local text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    TomoMod_Utils.StyleMoverLabel(text, 11) -- TOMOMOD: shared mover typography
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
    if InCombatLockdown() then
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
                        and "LeftButton" or "Key"
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

-- TOMOMOD: BuildPagingCondition / SetupBar1Paging used to live here. They were
-- moved to actionbars_paging.lua (SecurePaging) so the driver rebuild can be
-- combat-gated and configurable. This file loads AFTER actionbars_paging.lua,
-- so keeping a copy here would silently shadow the real implementation.
-- Do not reintroduce them: edit actionbars_paging.lua instead.

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

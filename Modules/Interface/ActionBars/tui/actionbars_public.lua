-- =====================================================================
-- Ported from Tui: TUI_ActionBars/actionbars/actionbars_public.lua
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

local function PurgeOverrideBarShownExternal()
    -- Midnight 12.1 native-frame ownership rule:
    -- OverrideActionBar belongs entirely to Blizzard. Never write addon fields,
    -- purge taint markers, alter methods, attributes, cooldowns or presentation
    -- on this frame. Reads are allowed; mutations are not.
    return
end

-- P3.5.11: visually suppress Blizzard's controller-owned standard bars only
-- after TomoMod has built/refreshed its own independent button graph.  The
-- native frames keep their secure paging/events/attributes; only bar alpha is
-- changed and only out of combat.
local function SuppressStandardBlizzardBarVisuals()
    if InCombatLockdown and InCombatLockdown() then
        return false
    end

    local touched = false
    for _, barKey in ipairs(STANDARD_BAR_KEYS) do
        local frameName = BAR_FRAMES[barKey]
        local frame = frameName and _G[frameName]
        if frame and frame.SetAlpha then
            frame:SetAlpha(0)
            touched = true
        end
    end

    return touched
end

-- P3.5.11: the standard TUI buttons are detached from Blizzard's native
-- ActionButton registry.  Keep their Lua-side action slot synchronized from
-- their own secure action attribute before repainting.  This is TomoMod-owned
-- state only; no Blizzard ActionButton or cooldown object is mutated here.
local function RefreshOwnedStandardButtonVisuals()
    if InCombatLockdown and InCombatLockdown() then
        return false
    end

    for _, barKey in ipairs(STANDARD_BAR_KEYS) do
        local buttons = ActionBarsOwned.nativeButtons and ActionBarsOwned.nativeButtons[barKey]
        local settings = GetEffectiveSettings and GetEffectiveSettings(barKey)
        if buttons and settings then
            for _, btn in ipairs(buttons) do
                if btn and btn.GetAttribute then
                    local action = btn:GetAttribute("action")
                    if action ~= nil and not (Helpers.IsSecretValue and Helpers.IsSecretValue(action)) then
                        local ok, numericAction = ns.SafeCall("best-effort-style", tonumber, action)
                        if ok and type(numericAction) == "number" then
                            btn.action = numericAction
                        end
                    end
                end

                if btn then
                    ActionBarsOwned.SafeUpdate(btn)
                    local state = GetFrameState(btn)
                    state.sk_sz = nil
                    SkinButton(btn, settings)
                    UpdateButtonText(btn, settings)
                    UpdateEmptySlotVisibility(btn, settings)
                end
            end
        end
    end

    return true
end

local function ApplyStandardBlizzardVisualSuppression()
    if not SuppressStandardBlizzardBarVisuals() then
        return false
    end
    RefreshOwnedStandardButtonVisuals()
    return true
end

-- TOMOMOD P2.13 / Midnight 12.1 Edit Mode presentation:
-- P2.12 proved that StanceBar, PetActionBar and PossessActionBar must remain
-- entirely Blizzard-owned. Do not Hide(), SetAlpha(), reparent, unregister,
-- hook or otherwise mutate those frames to remove their Edit Mode previews.
-- Blizzard already exposes account settings whose sole job is deciding whether
-- Edit Mode force-shows these bars. Switch those previews off through C_EditMode
-- before the manager is opened; the real runtime bars remain untouched.
local function DisableBlizzardSpecialBarEditModePreviews()
    if ActionBarsOwned._blizzardSpecialEditModePreviewsDisabled then
        return true
    end

    local api = C_EditMode
    local accountEnum = Enum and Enum.EditModeAccountSetting
    if not api or type(api.GetAccountSettings) ~= "function"
        or type(api.SetAccountSetting) ~= "function" or not accountEnum then
        return false
    end

    local wanted = {
        accountEnum.ShowStanceBar,
        accountEnum.ShowPetActionBar,
        accountEnum.ShowPossessActionBar,
    }

    -- If a build removes/renames one of the enum fields, do nothing rather than
    -- guessing a numeric enum and risking an unrelated Edit Mode preference.
    for i = 1, #wanted do
        if type(wanted[i]) ~= "number" then
            return false
        end
    end

    local okSettings, settings = pcall(api.GetAccountSettings)
    if not okSettings or type(settings) ~= "table" then
        return false
    end

    local current = {}
    for _, info in pairs(settings) do
        if type(info) == "table" and type(info.setting) == "number" then
            current[info.setting] = info.value
        end
    end

    for i = 1, #wanted do
        local setting = wanted[i]
        if current[setting] ~= 0 then
            local ok = pcall(api.SetAccountSetting, setting, 0)
            if not ok then
                return false
            end
        end
    end

    ActionBarsOwned._blizzardSpecialEditModePreviewsDisabled = true
    return true
end

function ActionBarsOwned:Initialize()
    if self.initialized then return end

    self.initialized = true

    -- Apply the Blizzard-owned Edit Mode preview policy before any user can
    -- enter Edit Mode. Retry one tick later if account settings were not ready
    -- yet during ADDON_LOADED; the retry is deliberately outside Blizzard's
    -- secure Edit Mode enter/exit execution.
    if not DisableBlizzardSpecialBarEditModePreviews() and C_Timer and C_Timer.After then
        C_Timer.After(0, DisableBlizzardSpecialBarEditModePreviews)
    end

    -- Do not suppress Blizzard standard-bar alpha yet.  TUI button construction
    -- and the first icon/empty-slot pass run below with the native presentation
    -- untouched; suppression is applied only after all owned bars exist.

    PatchLibKeyBoundForMidnight()

    ownedEventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    -- TOMOMOD: SLOT_CHANGED is not a drag-only event. Midnight fires it for
    -- transformed actions, macro resolution, spec/loadout changes and other
    -- content swaps while the grid is closed. Keep one central targeted
    -- listener alive permanently; actionbars_events.lua coalesces the work.
    ownedEventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    ownedEventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    -- TOMOMOD: the override bar was never listened to. Vehicles, skyriding and
    -- druid Flight Form all swap the player onto it, and without this event the
    -- module never learns the page changed.
    ownedEventFrame:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
    ownedEventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    ownedEventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
    ownedEventFrame:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
    ownedEventFrame:RegisterEvent("UPDATE_SHAPESHIFT_USABLE")
    ownedEventFrame:RegisterEvent("UPDATE_STEALTH")
    ownedEventFrame:RegisterEvent("UPDATE_BINDINGS")
    ownedEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    ownedEventFrame:RegisterEvent("CURSOR_CHANGED")
    ownedEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    ownedEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    ownedEventFrame:RegisterEvent("PLAYER_LEVEL_UP")
    ownedEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    ownedEventFrame:RegisterEvent("ZONE_CHANGED")
    ownedEventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
    ownedEventFrame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
    ownedEventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
    ownedEventFrame:RegisterEvent("CHALLENGE_MODE_START")
    ownedEventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    ownedEventFrame:RegisterEvent("CHALLENGE_MODE_RESET")
    ownedEventFrame:RegisterEvent("ENCOUNTER_START")
    ownedEventFrame:RegisterEvent("ENCOUNTER_END")
    ownedEventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
    ownedEventFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
    ownedEventFrame:RegisterEvent("UPDATE_EXTRA_ACTIONBAR")
    ownedEventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    ownedEventFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    -- TOMOMOD P3.2: Midnight's C-side action usability dispatcher.  Some
    -- conditional abilities (Touch of Death is the canonical example) can
    -- flip their activation-overlay state when the action becomes usable
    -- without a reliable spell-ID glow edge reaching our detached buttons.
    ownedEventFrame:RegisterEvent("ACTION_USABLE_CHANGED")
    ownedEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    ownedEventFrame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    ownedEventFrame:RegisterEvent("ACTIONBAR_SHOWGRID")
    ownedEventFrame:RegisterEvent("ACTIONBAR_HIDEGRID")
    ownedEventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
    ownedEventFrame:RegisterUnitEvent("UNIT_AURA", "player")
    ownedEventFrame:RegisterEvent("SPELL_UPDATE_ICON")
    ownedEventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
    ownedEventFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
    ownedEventFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
    ownedEventFrame:RegisterEvent("PET_BATTLE_OPENING_START")
    ownedEventFrame:RegisterEvent("PET_BATTLE_CLOSE")
    ownedEventFrame:RegisterEvent("LOSS_OF_CONTROL_ADDED")
    ownedEventFrame:RegisterEvent("LOSS_OF_CONTROL_UPDATE")
    ownedEventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    ownedEventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    ownedEventFrame:RegisterEvent("SPELLS_CHANGED")
    ownedEventFrame:RegisterEvent("SPELL_UPDATE_USABLE")
    ownedEventFrame:RegisterEvent("SPELL_FLYOUT_UPDATE")
    ownedEventFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
    ownedEventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    ownedEventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    ownedEventFrame:RegisterEvent("START_AUTOREPEAT_SPELL")
    ownedEventFrame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
    if IS_MIDNIGHT then
        ownedEventFrame:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE")
    end
    ownedEventFrame:Show()

    for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
        BuildBar(barKey)
    end

    -- P3.5.11: late alpha suppression.  Repaint our owned standard buttons on
    -- the same pass and again next frame so icon/action-slot state is settled.
    ApplyStandardBlizzardVisualSuppression()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if not ActionBarsOwned.initialized then return end
            if InCombatLockdown and InCombatLockdown() then return end
            ApplyStandardBlizzardVisualSuppression()
        end)
    end

    PurgeOverrideBarShownExternal()

    -- Midnight 12.1 native-frame ownership rule:
    -- Do not wrap or replace any method on OverrideActionBarButton1..6 or
    -- ExtraActionButton1. ExtraActionButtonTemplate inherits Blizzard's native
    -- ActionBar button code and participates in the same action-event/cooldown
    -- pipeline as ActionButton1..12. Even a well-intentioned SetCooldown or
    -- attribute guard here can contaminate later secret-value execution.

    -- Midnight 12.1:
    -- Do not mutate PossessActionBar. Blizzard calls PossessActionBar:Update()
    -- at the very start of ActionBarController_UpdateAll(), before the protected
    -- MainActionBar:SetAttribute("actionpage", ...) write. Any addon taint on
    -- the possess bar can therefore poison the entire controller execution.
    -- Keep the native possess graph fully Blizzard-owned.

    -- Midnight 12.1:
    -- Keep Blizzard's action-bar globals pristine. Replacing AddSpellToActionBar
    -- or AddClassSpellToActionBar marks shared ActionBar controller execution as
    -- addon-owned and is incompatible with the zero-touch native-bar strategy.
    -- AutoPushSpellWatcher is allowed to run with Blizzard's original handlers.
    ns.SafeCallMethodIfPresent("report", _G.AutoPushSpellWatcher, "Start")

    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("HouseEditor.StateUpdated", function(_, state)
            if InCombatLockdown() then
                if not state then
                    ActionBarsOwned.pendingBindings = true
                end
                return
            end
            if state then
                ActionBarsOwned._inHousing = true
                for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
                    local cont = ActionBarsOwned.containers[barKey]
                    if cont then ClearOverrideBindings(cont) end
                end
            else
                ActionBarsOwned._inHousing = nil
                ApplyAllOverrideBindings()
            end
        end, "TUI_ActionBars")
    end

    ownedEventFrame:RegisterEvent("PET_BAR_UPDATE")
    ownedEventFrame:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
    ownedEventFrame:RegisterEvent("PET_UI_UPDATE")
    ownedEventFrame:RegisterEvent("UNIT_PET")

    UpdatePetBarVisibility()
    UpdateStanceBarLayout()

    if _G.UpdateOnBarHighlightMarksBySpell then
        hooksecurefunc("UpdateOnBarHighlightMarksBySpell", function(spellID)
            ActionBarsOwned.spellHighlight.type = "spell"
            ActionBarsOwned.spellHighlight.id = tonumber(spellID)
        end)
    end
    if _G.UpdateOnBarHighlightMarksByFlyout then
        hooksecurefunc("UpdateOnBarHighlightMarksByFlyout", function(flyoutID)
            ActionBarsOwned.spellHighlight.type = "flyout"
            ActionBarsOwned.spellHighlight.id = tonumber(flyoutID)
        end)
    end
    if _G.ClearOnBarHighlightMarks then
        hooksecurefunc("ClearOnBarHighlightMarks", function()
            ActionBarsOwned.spellHighlight.type = nil
            ActionBarsOwned.spellHighlight.id = nil
        end)
    end
    if _G.ActionBarController_UpdateAllSpellHighlights then
        hooksecurefunc("ActionBarController_UpdateAllSpellHighlights", ActionBarsOwned.UpdateAllSpellHighlights)
    end

    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("AssistedCombatManager.OnSetActionSpell", function()
            local okSpell, newSpell = ns.SafeCall("best-effort-style", C_AssistedCombat.GetNextCastSpell, false)
            if not okSpell then newSpell = nil end
            if newSpell == ActionBarsOwned._lastAssistRotationSpell then return end
            ActionBarsOwned._lastAssistRotationSpell = newSpell
            if newSpell then ActionBarsOwned._assistedCombatEverActive = true end
            ActionBarsOwned.UpdateAllAssistedCombatRotation()
            ScheduleABVisualUpdate(false, true)
            local kb = ns.Keybinds
            if kb and kb.UpdateAllRotationHelpers then ns.SafeCall("bulkhead", kb.UpdateAllRotationHelpers) end
        end, "TUI_ActionBars_AssistedCombat")

        EventRegistry:RegisterCallback("AssistedCombatManager.OnAssistedHighlightSpellChange", function()
            local okHL, nextSpell = ns.SafeCall("best-effort-style", C_AssistedCombat.GetNextCastSpell, false)
            if not okHL then nextSpell = nil end
            if not nextSpell then return end
            if nextSpell == ActionBarsOwned._lastAssistHighlightSpell then return end
            ActionBarsOwned._lastAssistHighlightSpell = nextSpell
            UpdateAllAssistedHighlights()
        end, "TUI_ActionBars_AssistedHighlight")
    end

    if AssistedCombatManager and AssistedCombatManager.UpdateAllAssistedHighlightFramesForSpell then
        hooksecurefunc(AssistedCombatManager, "UpdateAllAssistedHighlightFramesForSpell", function(_, spellID)
            if not spellID then return end
            local Helpers = ns.Helpers
            local isSecret = Helpers and Helpers.IsSecretValue(spellID)

            local resolvedID = spellID
            if not isSecret then
                local okOvr, overrideID = ns.SafeCall("best-effort-style", C_Spell.GetOverrideSpell, spellID)
                if okOvr and overrideID and overrideID ~= spellID then
                    resolvedID = overrideID
                end
            end

            ScheduleABVisualUpdate(false, true)
            local kb = ns.Keybinds
            if kb and kb.UpdateAllRotationHelpers then
                ns.SafeCall("bulkhead", kb.UpdateAllRotationHelpers, resolvedID, spellID)
            end
        end)
    end

    if ActionButton_Update then
        hooksecurefunc("ActionButton_Update", function(button)
            if InCombatLockdown() then return end
            if not ActionBarsOwned.skinnedButtons[button] then return end
            local bk = GetBarKeyFromButton(button)
            if not bk then return end
            local s = GetEffectiveSettings(bk)
            if s then
                SkinButton(button, s)
                UpdateButtonText(button, s)
                UpdateEmptySlotVisibility(button, s)
            end
        end)
    end

    ActionBarsOwned.UpdateUsabilityPolling()

    local core = GetCore()
    if core and core.RegisterEditModeEnter then
        core:RegisterEditModeEnter(OnEditModeEnter)
        core:RegisterEditModeExit(OnEditModeExit)
    end

    ActionBarsOwned._suppressTooltips = false
    function ActionBarsOwned:RefreshTooltipSuppressCache()
        local global = GetGlobalSettings()
        self._suppressTooltips = global and global.showTooltips == false
    end
    ActionBarsOwned:RefreshTooltipSuppressCache()

    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        if not ActionBarsOwned._suppressTooltips then return end
        if not parent or not ActionBarsOwned.skinnedButtons[parent] then return end
        tooltip:Hide()
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:ClearLines()
    end)

    ActionBarsOwned.EnsureSpellBookVisibilityHooks()
    ActionBarsOwned.HookSpellBookToggleFunction("ToggleSpellBook")
    ActionBarsOwned.HookSpellBookToggleFunction("TogglePlayerSpellsFrame")
    ActionBarsOwned.ScheduleSpellBookVisibilityRefresh()

    inInitSafeWindow = true
    InitializeExtraButtons()
    inInitSafeWindow = false

    local db = GetDB()
    if db and db.bars and db.bars.bar1 then
        ApplyPageArrowVisibility(db.bars.bar1.hidePageArrow)
    end

    for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
        local barDB = GetBarSettings(barKey)
        if barDB and barDB.enabled == false then
            local container = self.containers[barKey]
            if container then
                container:SetAttribute("qui-user-shown", false)
                container:Hide()
            end
        end
    end

    local profile = Helpers.GetProfile()
    local hiddenHandles = profile and profile.layoutMode and profile.layoutMode.hiddenHandles
    if hiddenHandles then
        local LAYOUT_TO_CONTAINER = {
            bar1 = "bar1", bar2 = "bar2", bar3 = "bar3", bar4 = "bar4",
            bar5 = "bar5", bar6 = "bar6", bar7 = "bar7", bar8 = "bar8",
            petBar = "pet", stanceBar = "stance",
            microMenu = "microbar", bagBar = "bags",
        }
        local lm = ns.TUI_LayoutMode
        if lm then
            lm._gameplayHidden = lm._gameplayHidden or {}
        end
        for layoutKey, containerKey in pairs(LAYOUT_TO_CONTAINER) do
            if hiddenHandles[layoutKey] then
                local container = self.containers[containerKey]
                if container then
                    container:SetAttribute("qui-user-shown", false)
                    container:Hide()
                    if lm then
                        lm._gameplayHidden[layoutKey] = true
                    end
                end
            end
        end
    end
end

function ActionBarsOwned:Refresh()
    if not self.initialized then return end

    InvalidateEffectiveSettingsCache()

    if InCombatLockdown() then
        self.pendingRefresh = true
        return
    end

    if HideOwnedFlyout then
        HideOwnedFlyout()
    end

    for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
        BuildBar(barKey)
    end

    PatchLibKeyBoundForMidnight()

    if not ActionBarsOwned._refreshHooksInstalled then
        ActionBarsOwned._refreshHooksInstalled = true
        hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
            local global = GetGlobalSettings()
            if not global or global.showTooltips ~= false then return end
            local name = parent and parent.GetName and parent:GetName()
            if name and (name:match("^ActionButton") or name:match("^MultiBar") or name:match("^PetActionButton")
                or name:match("^StanceButton") or name:match("^OverrideActionBar") or name:match("^ExtraActionButton")) then
                tooltip:Hide()
                tooltip:SetOwner(UIParent, "ANCHOR_NONE")
                tooltip:ClearLines()
            end
        end)

        if ActionButtonSpellAlertManager and ActionButtonSpellAlertManager.ShowAlert then
            hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", function(_, actionButton)
                if not actionButton then return end
                if not ActionBarsOwned.skinnedButtons[actionButton] then return end
                ActionBarsOwned.SuppressButtonProcVisuals(actionButton)
                local acrf = actionButton.AssistedCombatRotationFrame
                if acrf and acrf.SpellActivationAlert then
                    SuppressProcVisualFrame(acrf.SpellActivationAlert)
                end
            end)
        end
        if type(ActionButton_ShowOverlayGlow) == "function" then
            hooksecurefunc("ActionButton_ShowOverlayGlow", function(button)
                if ActionBarsOwned.skinnedButtons[button] then
                    ActionBarsOwned.SuppressButtonProcVisuals(button)
                end
            end)
        end
    end

    for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
        SkinBar(barKey)
    end

    -- Keep Blizzard standard bars visually suppressed after every options
    -- refresh, then repaint TomoMod's own buttons so hide-empty/icon state is
    -- recalculated from the current secure action slots.
    ApplyStandardBlizzardVisualSuppression()

    ActionBarsOwned.HookSpellFlyoutSkinning()

    ApplyAllBarSpacing()
    ApplyAllFlyoutDirections()
    if SyncOwnedFlyoutInfoToHandler then
        SyncOwnedFlyoutInfoToHandler()
    end

    for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
        local barDB = GetBarSettings(barKey)
        if barDB and barDB.enabled == false then
            local container = self.containers[barKey]
            if container then
                container:SetAttribute("qui-user-shown", false)
                container:Hide()
            end
        end
    end

    UpdatePetBarVisibility()
    UpdateStanceBarLayout()

    ActionBarsOwned.UpdateUsabilityPolling()
    if self.RefreshTooltipSuppressCache then self:RefreshTooltipSuppressCache() end
end

_G.TUI_RefreshActionBars = function()
    if InCombatLockdown() then
        ActionBarsOwned.pendingRefresh = true
        return
    end
    ActionBarsOwned:Refresh()
    if ns.TUI_ActionBarsPreviewDriver and ns.TUI_ActionBarsPreviewDriver.Refresh then
        ns.TUI_ActionBarsPreviewDriver.Refresh()
    end
end

_G.TUI_ApplyUseOnKeyDown = function()
    if InCombatLockdown() then
        ActionBarsOwned.pendingUseOnKeyDownUpdate = true
        return
    end
    local db = GetDB()
    local value = not (db and db.global and db.global.useOnKeyDown == false)
    for bar = 1, 8 do
        for i = 1, 12 do
            local btn = _G["TUI_Bar" .. bar .. "Button" .. i]
            if btn then
                btn:SetAttribute("useOnKeyDown", value)
                if btn.RunAttribute then
                    btn:RunAttribute("TUI_UpdateActionFlags")
                end
            end
        end
    end
    if EnsureOwnedFlyoutFrame then
        local flyout = EnsureOwnedFlyoutFrame()
        local count = (flyout and flyout.GetAttribute and flyout:GetAttribute("numFlyoutButtons")) or 0
        for i = 1, count do
            local btn = _G["TUI_SpellFlyoutButton" .. i]
            if btn then
                btn:SetAttribute("useOnKeyDown", value)
            end
        end
    end
end

_G.TUI_ReapplyActionBarBindings = function()
    if InCombatLockdown() then
        ActionBarsOwned.pendingBindings = true
        return
    end
    RefreshNativeKeybinds()
end

_G.TUI_RefreshActionBarFade = function()
    if not ActionBarsOwned.initialized then return end
    if RefreshActionBarContextVisibility then
        RefreshActionBarContextVisibility()
    end
    for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
        local state = GetOwnedBarFadeState(barKey)
        state.isFading = false
        CancelOwnedBarFadeTimers(state)
        SetupOwnedBarMouseover(barKey)
    end
    -- ExtraActionBarFrame and ZoneAbilityFrame are native
    -- Blizzard-owned surfaces. Do not install
    -- fade/mouseover handlers or change their alpha here.
end

initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    -- TOMOMOD: kept as a kill switch (ns.TUI_ACTIONBARS_READY), on since P4.
    if addonName == ADDON_NAME and ns.TUI_ACTIONBARS_READY then
        if not GetDB() then return end
        ActionBarsOwned:Initialize()
    elseif addonName == "Blizzard_ActionBar" then
        -- P3.5.11: if Blizzard_ActionBar loads after TomoMod, suppress only
        -- after its frames exist and repaint our independent buttons afterwards.
        if ActionBarsOwned.initialized then
            ApplyStandardBlizzardVisualSuppression()
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    if not ActionBarsOwned.initialized then return end
                    if InCombatLockdown and InCombatLockdown() then return end
                    ApplyStandardBlizzardVisualSuppression()
                end)
            end
        end
        ActionBarsOwned.HookSpellFlyoutSkinning()
        C_Timer.After(0, SkinSpellFlyoutButtons)
        local db = GetDB()
        if db and db.bars and db.bars.bar1 then
            C_Timer.After(0, function()
                ApplyPageArrowVisibility(db.bars.bar1.hidePageArrow)
            end)
        end
        PurgeOverrideBarShownExternal()
    elseif ActionBarsOwned.HandleSpellBookAddonLoaded then
        ActionBarsOwned.HandleSpellBookAddonLoaded(addonName)
    end
end)

do
    local function RegisterLayoutModeElements()
        local um = ns.TUI_LayoutMode
        if not um or type(um.RegisterElement) ~= "function" then return end

        local BAR_ELEMENTS = {
            { key = "bar1", label = ns.L["Action Bar 1"], order = 1 },
            { key = "bar2", label = ns.L["Action Bar 2"], order = 2 },
            { key = "bar3", label = ns.L["Action Bar 3"], order = 3 },
            { key = "bar4", label = ns.L["Action Bar 4"], order = 4 },
            { key = "bar5", label = ns.L["Action Bar 5"], order = 5 },
            { key = "bar6", label = ns.L["Action Bar 6"], order = 6 },
            { key = "bar7", label = ns.L["Action Bar 7"], order = 7 },
            { key = "bar8", label = ns.L["Action Bar 8"], order = 8 },
            { key = "petBar",    label = ns.L["Pet Bar"],     order = 9 },
            { key = "stanceBar", label = ns.L["Stance Bar"],  order = 10 },
            { key = "microMenu", label = ns.L["Micro Menu"],  order = 11 },
        }

        local DB_KEY_MAP = {
            petBar = "pet", stanceBar = "stance",
            microMenu = "microbar",
        }

        um:RegisterElement({
            key = "actionBars",
            label = ns.L["Action Bars"],
            group = ns.L["Action Bars"],
            order = -1,
            isOwned = true,
            noHandle = true,
            getFrame = function()
                return ActionBarsOwned.containers and ActionBarsOwned.containers["bar1"]
            end,
        })

        um:RegisterElement({
            key = "leaveVehicle",
            label = ns.L["Leave Vehicle"],
            group = ns.L["Action Bars"],
            order = 13,
            isOwned = true,
            getFrame = function()
                -- Never expose Blizzard's protected native leave
                -- button to our layout layer; return only the TomoMod-owned proxy.
                return ActionBarsOwned.extraBtnState
                    and ActionBarsOwned.extraBtnState.leaveVehicleProxy
            end,
        })

        for _, info in ipairs(BAR_ELEMENTS) do
            local dbKey = DB_KEY_MAP[info.key] or info.key
            local containerKey = dbKey
            um:RegisterElement({
                key = info.key,
                label = info.label,
                group = ns.L["Action Bars"],
                order = info.order,
                isOwned = true,
                isEnabled = function()
                    local barDB = GetBarSettings(dbKey)
                    return barDB and barDB.enabled ~= false
                end,
                setEnabled = function(val)
                    local barDB = GetBarSettings(dbKey)
                    if not barDB then return end
                    local old = barDB.enabled ~= false
                    barDB.enabled = val
                    local container = ActionBarsOwned.containers and ActionBarsOwned.containers[containerKey]
                    if container then
                        container:SetAttribute("qui-user-shown", val and true or false)
                        if val then
                            container:Show()
                        else
                            if ActionBarsOwned.HideOwnedFlyout then
                                ActionBarsOwned.HideOwnedFlyout()
                            end
                            container:Hide()
                        end
                    end
                    if (val ~= false) ~= old then
                        local TUI = _G.TUI
                        local GUI = TUI and TUI.GUI
                        if GUI and GUI.ShowConfirmation then
                            GUI:ShowConfirmation({
                                title = ns.L["Reload UI?"],
                                message = ns.L["Enabling or disabling an action bar requires a UI reload to fully take effect."],
                                acceptText = ns.L["Reload"],
                                cancelText = ns.L["Later"],
                                onAccept = function() TUI:SafeReload() end,
                            })
                        end
                    end
                end,
                getFrame = function()
                    local owned = ActionBarsOwned.containers and ActionBarsOwned.containers[containerKey]
                    if owned then return owned end
                    local BLIZZARD_FRAMES = {
                        bar1 = "MainActionBar", bar2 = "MultiBarBottomLeft",
                        bar3 = "MultiBarBottomRight", bar4 = "MultiBarRight",
                        bar5 = "MultiBarLeft", bar6 = "MultiBar5",
                        bar7 = "MultiBar6", bar8 = "MultiBar7",
                        petBar = "PetActionBar", stanceBar = "StanceBar",
                        microMenu = "MicroMenuContainer", bagBar = "BagsBar",
                    }
                    return _G[BLIZZARD_FRAMES[info.key]]
                end,
                setGameplayHidden = function(hide)
                    local container = ActionBarsOwned.containers and ActionBarsOwned.containers[containerKey]
                    if not container then return end
                    container:SetAttribute("qui-user-shown", (not hide) and true or false)
                    if hide then
                        if ActionBarsOwned.HideOwnedFlyout then
                            ActionBarsOwned.HideOwnedFlyout()
                        end
                        container:Hide()
                    else
                        container:Show()
                    end
                end,
                onOpen = function()
                    SetEditOverlayVisible(containerKey, true)
                end,
                onClose = function()
                    SetEditOverlayVisible(containerKey, false)
                end,
            })
        end
    end

    C_Timer.After(2, RegisterLayoutModeElements)
end

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

-- P3.5.14: standard Blizzard bars stay fully alive for the controller, but
-- their presentation is suppressed after TUI has painted its own independent
-- buttons. This function never touches StanceBar, PetActionBar or
-- PossessActionBar.
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

-- P3.5.17: native Stance/Pet/Possess bars must stay fully functional because
-- Blizzard's ActionBarController still updates them as part of the protected
-- action-bar graph. P3.5.12 proved that changing the bar/button alpha itself
-- can break paging/input. P3.5.16 successfully hid ordinary Texture/FontString
-- regions, but two C/animation-backed visual helpers remain visible:
--   * Cooldown frames (stance/form GCD swipe)
--   * Pet AutoCastOverlay frames (animated gold border)
-- Suppress those helper frames only; never mutate the native bar/button alpha,
-- secure attributes, events, parentage, cooldown data or click handlers.
local NATIVE_SPECIAL_VISUAL_BAR_NAMES = {
    "StanceBar",
    "PetActionBar",
    "PossessActionBar",
}

local NATIVE_SPECIAL_BUTTON_GROUPS = {
    { prefix = "StanceButton", count = 10 },
    { prefix = "PetActionButton", count = 10 },
    { prefix = "PossessButton", count = 2 },
}

local function SuppressNativeVisualHelperFrame(frame)
    if frame and frame.SetAlpha then
        -- Presentation-only alpha. Do not Hide() the helper and do not alter
        -- cooldown timing/swipe APIs; Blizzard remains the sole state owner.
        frame:SetAlpha(0)
    end
end

local function SuppressNativeButtonResidualVisuals(button)
    if not button then return end

    -- CooldownFrame has C-side rendering, so hiding only its texture regions
    -- does not remove the swipe/GCD. Alpha on the child Cooldown frame does.
    SuppressNativeVisualHelperFrame(button.cooldown)
    SuppressNativeVisualHelperFrame(button.Cooldown)
    SuppressNativeVisualHelperFrame(button.chargeCooldown)
    SuppressNativeVisualHelperFrame(button.ChargeCooldown)

    -- PetActionBar:Update() explicitly drives AutoCastOverlay visibility and
    -- animation. Keeping the overlay frame alive at alpha 0 prevents its
    -- animated gold border from reappearing while preserving native state.
    SuppressNativeVisualHelperFrame(button.AutoCastOverlay)
end

-- P3.5.18: PetActionBar also keeps persistent command/reaction buttons in a
-- checked state (Follow/Assist/Defensive/etc.) and may flash an active action.
-- Those textures are driven independently from the icon/AutoCastOverlay, so
-- suppress them explicitly without changing SetChecked(), action state or any
-- secure input path. This is presentation-only and limited to native pet
-- buttons; the TUI pet buttons keep their own checked/flash feedback.
local function SuppressNativePetStateVisuals(button)
    if not button then return end

    if button.GetCheckedTexture then
        SuppressNativeVisualHelperFrame(button:GetCheckedTexture())
    end
    SuppressNativeVisualHelperFrame(button.CheckedTexture)
    SuppressNativeVisualHelperFrame(button.checkedTexture)
    SuppressNativeVisualHelperFrame(button.Flash)
    SuppressNativeVisualHelperFrame(button.flash)
end

local function SuppressNativeRenderRegions(frame, depth, seen)
    if not frame or depth > 6 or seen[frame] then return end
    seen[frame] = true

    if frame.GetRegions then
        local regions = { frame:GetRegions() }
        for i = 1, #regions do
            local region = regions[i]
            -- Regions are presentation-only objects. Do not Hide() them: some
            -- Blizzard update paths Show() the icon/checked texture again.
            -- Alpha 0 survives those Show() calls and does not mutate the
            -- protected owner frame.
            if region and region.SetAlpha then
                region:SetAlpha(0)
            end
        end
    end

    if frame.GetChildren then
        local children = { frame:GetChildren() }
        for i = 1, #children do
            local child = children[i]
            -- A Cooldown is a visual child frame with its own C-side swipe
            -- renderer. SetAlpha(0) is intentionally limited to this helper
            -- type; ordinary native Button/Frame objects remain zero-touch.
            local objectType = child and child.GetObjectType and child:GetObjectType()
            if objectType == "Cooldown" then
                SuppressNativeVisualHelperFrame(child)
            end
            SuppressNativeRenderRegions(child, depth + 1, seen)
        end
    end
end

function ActionBarsOwned.SuppressNativeSpecialVisualRegions()
    local seen = {}
    for i = 1, #NATIVE_SPECIAL_VISUAL_BAR_NAMES do
        local bar = _G[NATIVE_SPECIAL_VISUAL_BAR_NAMES[i]]
        if bar then
            SuppressNativeRenderRegions(bar, 0, seen)
        end
    end

    -- Explicit field pass catches Blizzard helper frames even if a template
    -- changes their child nesting/order. The buttons themselves are untouched.
    for i = 1, #NATIVE_SPECIAL_BUTTON_GROUPS do
        local group = NATIVE_SPECIAL_BUTTON_GROUPS[i]
        for index = 1, group.count do
            local button = _G[group.prefix .. index]
            SuppressNativeButtonResidualVisuals(button)
            if group.prefix == "PetActionButton" then
                SuppressNativePetStateVisuals(button)
            end
        end
    end
end

local function ScheduleNativeSpecialVisualSuppression()
    if not ActionBarsOwned.SuppressNativeSpecialVisualRegions then return end
    ActionBarsOwned.SuppressNativeSpecialVisualRegions()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if ActionBarsOwned.initialized and ActionBarsOwned.SuppressNativeSpecialVisualRegions then
                ActionBarsOwned.SuppressNativeSpecialVisualRegions()
            end
        end)
    end
end

local function PaintOwnedStandardBarsBeforeSuppression()
    if ActionBarsOwned.ForceFullVisualRescan then
        ActionBarsOwned.ForceFullVisualRescan()
    end
    if ActionBarsOwned.UpdateAllButtonVisuals then
        ActionBarsOwned.UpdateAllButtonVisuals()
    end
end

local function ApplyLateStandardBarSuppression()
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    PaintOwnedStandardBarsBeforeSuppression()
    return SuppressStandardBlizzardBarVisuals()
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

-- TOMOMOD 3.6.1 / input latency:
-- Keep TomoMod's per-button useOnKeyDown setting and Blizzard's account-wide
-- ActionButtonUseKeyDown CVar in lockstep.  Secure CLICK bindings can otherwise
-- traverse two different press/release policies: TomoMod's button attribute
-- says "down" while the binding path still follows Blizzard's CVar.  The result
-- is not necessarily an error; the first hardware event can simply be ignored
-- and a later press/release is the one that finally casts.
local function GetConfiguredUseOnKeyDown()
    local db = GetDB()
    return not (db and db.global and db.global.useOnKeyDown == false)
end

local function SyncActionButtonUseKeyDownCVar(value)
    local wanted = value and "1" or "0"
    local current = nil

    if type(GetCVar) == "function" then
        local ok, result = pcall(GetCVar, "ActionButtonUseKeyDown")
        if ok and result ~= nil then
            current = tostring(result)
        end
    end

    if current == wanted then
        return true
    end

    local setter = (C_CVar and C_CVar.SetCVar) or SetCVar
    if type(setter) ~= "function" then
        return false
    end

    local ok = pcall(setter, "ActionButtonUseKeyDown", wanted)
    return ok
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

    PatchLibKeyBoundForMidnight()

    -- Honour the TomoMod "Cast on key press" setting through Blizzard's real
    -- input CVar before any owned action button or override CLICK binding is
    -- built.  The button-specific attribute remains in place for Midnight's
    -- secure template, but both sides now agree on the same phase.
    SyncActionButtonUseKeyDownCVar(GetConfiguredUseOnKeyDown())

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
    -- P3.5.16: possession has its own native visual update event.  Listen only
    -- so the visual-region mask can be refreshed after Blizzard repaints it.
    ownedEventFrame:RegisterEvent("UPDATE_POSSESS_BAR")
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

    -- P3.5.16: keep native special-bar behavior alive but remove only their
    -- presentation regions.  This intentionally happens after TUI owns its
    -- independent Stance/Pet controls.
    ScheduleNativeSpecialVisualSuppression()

    -- Paint TUI from its own secure action attributes first, then hide only the
    -- standard Blizzard bar parents. No Lua-side action slot is written here.
    ApplyLateStandardBarSuppression()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if not ActionBarsOwned.initialized then return end
            ApplyLateStandardBarSuppression()
        end)
        C_Timer.After(0.25, function()
            if not ActionBarsOwned.initialized then return end
            ApplyLateStandardBarSuppression()
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
        -- TOMOMOD 3.6.1 Assisted Combat optimization:
        -- A suggestion change is not a reason to invalidate every owned action
        -- button. Keep rotation-frame/highlight work targeted and let normal
        -- action/cooldown events update unrelated buttons. In particular, do
        -- not hook AssistedCombatManager:UpdateAllAssistedHighlightFramesForSpell;
        -- Blizzard can call it at rotation-evaluation cadence in combat.
        EventRegistry:RegisterCallback("AssistedCombatManager.OnSetActionSpell", function()
            local okSpell, newSpell = ns.SafeCall("best-effort-style", C_AssistedCombat.GetNextCastSpell, false)
            if not okSpell then newSpell = nil end
            if newSpell == ActionBarsOwned._lastAssistRotationSpell then return end
            ActionBarsOwned._lastAssistRotationSpell = newSpell
            if newSpell then ActionBarsOwned._assistedCombatEverActive = true end
            ActionBarsOwned.UpdateAllAssistedCombatRotation()
            local kb = ns.Keybinds
            if kb and kb.UpdateAllRotationHelpers then ns.SafeCall("bulkhead", kb.UpdateAllRotationHelpers) end
        end, "TUI_ActionBars_AssistedCombat")

        EventRegistry:RegisterCallback("AssistedCombatManager.OnAssistedHighlightSpellChange", function()
            local okHL, nextSpell = ns.SafeCall("best-effort-style", C_AssistedCombat.GetNextCastSpell, false)
            if not okHL then nextSpell = nil end
            if nextSpell == ActionBarsOwned._lastAssistHighlightSpell then return end
            ActionBarsOwned._lastAssistHighlightSpell = nextSpell
            UpdateAllAssistedHighlights()

            local resolvedID = nextSpell
            if nextSpell and C_Spell and C_Spell.GetOverrideSpell then
                local Helpers = ns.Helpers
                local isSecret = Helpers and Helpers.IsSecretValue and Helpers.IsSecretValue(nextSpell)
                if not isSecret then
                    local okOvr, overrideID = ns.SafeCall("best-effort-style", C_Spell.GetOverrideSpell, nextSpell)
                    if okOvr and overrideID and overrideID ~= nextSpell then
                        resolvedID = overrideID
                    end
                end
            end

            local kb = ns.Keybinds
            if kb and kb.UpdateAllRotationHelpers then
                ns.SafeCall("bulkhead", kb.UpdateAllRotationHelpers, resolvedID, nextSpell)
            end
        end, "TUI_ActionBars_AssistedHighlight")

        EventRegistry:RegisterCallback("AssistedCombatManager.OnSetUseAssistedHighlight", function()
            UpdateAllAssistedHighlights()
        end, "TUI_ActionBars_AssistedHighlight_CVar")
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

    -- Extra/zone buttons defer themselves through pendingExtraButtonInit when
    -- the lockdown is on; no safe-window override is needed or wanted here.
    InitializeExtraButtons()

    local db = GetDB()
    if db and db.bars and db.bars.bar1 then
        ApplyPageArrowVisibility(db.bars.bar1.hidePageArrow)
    end

    for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
        local barDB = GetBarSettings(barKey)
        if barDB and barDB.enabled == false then
            local container = self.containers[barKey]
            if container then
                -- TOMOMOD 3.6.1: was a raw SetAttribute + Hide, which ran under
                -- lockdown on a /reload taken in combat. SetBarContainerShown
                -- routes through the secure user-shown path and defers when
                -- locked, replaying on PLAYER_REGEN_ENABLED.
                SetBarContainerShown(container, false)
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
            bagBar = "bags",
        }
        local lm = ns.TUI_LayoutMode
        if lm then
            lm._gameplayHidden = lm._gameplayHidden or {}
        end
        for layoutKey, containerKey in pairs(LAYOUT_TO_CONTAINER) do
            if hiddenHandles[layoutKey] then
                local container = self.containers[containerKey]
                if container then
                    SetBarContainerShown(container, false)
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

    ApplyLateStandardBarSuppression()

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
                -- TOMOMOD 3.6.1: was a raw SetAttribute + Hide, which ran under
                -- lockdown on a /reload taken in combat. SetBarContainerShown
                -- routes through the secure user-shown path and defers when
                -- locked, replaying on PLAYER_REGEN_ENABLED.
                SetBarContainerShown(container, false)
            end
        end
    end

    UpdatePetBarVisibility()
    UpdateStanceBarLayout()
    ScheduleNativeSpecialVisualSuppression()

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

    local value = GetConfiguredUseOnKeyDown()

    -- The GUI option now controls the same input phase Blizzard uses for
    -- action bindings.  Do this before updating the secure button attributes
    -- so there is never a window where CVar and button disagree.
    SyncActionButtonUseKeyDownCVar(value)

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

    -- Pet and Stance are TUI-owned secure buttons too.  They were initialized
    -- from the setting but were never updated when the option changed later.
    for _, prefix in ipairs({ "TUI_PetButton", "TUI_StanceButton" }) do
        for i = 1, 10 do
            local btn = _G[prefix .. i]
            if btn then
                btn:SetAttribute("useOnKeyDown", value)
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
        if barKey == "microbar" then
            -- Blizzard owns MicroMenu; only refresh native alpha/mouseover.
            local state = GetBarFadeState(barKey)
            state.isFading = false
            CancelBarFadeTimers(state)
            SetupBarMouseover(barKey)
        else
            local state = GetOwnedBarFadeState(barKey)
            state.isFading = false
            CancelOwnedBarFadeTimers(state)
            SetupOwnedBarMouseover(barKey)
        end
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
        if ActionBarsOwned.initialized then
            ApplyLateStandardBarSuppression()
            ScheduleNativeSpecialVisualSuppression()
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    if ActionBarsOwned.initialized then
                        ApplyLateStandardBarSuppression()
                    end
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
        }

        local DB_KEY_MAP = {
            petBar = "pet", stanceBar = "stance",
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
                        bagBar = "BagsBar",
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

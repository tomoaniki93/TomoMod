-- =====================================================================
-- Ported from Tui: TUI_ActionBars/actionbars/actionbars_events.lua
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

local _abCooldownStats

local function RefreshAllEmptySlotVisibility()
    for _, barKey in ipairs(STANDARD_BAR_KEYS) do
        local buttons = ActionBarsOwned.nativeButtons[barKey]
        local settings = GetEffectiveSettings(barKey)
        local runtimeVisible = not ActionBarsOwned.IsBarRuntimeVisible or ActionBarsOwned.IsBarRuntimeVisible(barKey)
        if buttons and settings and runtimeVisible then
            for _, btn in ipairs(buttons) do
                UpdateEmptySlotVisibility(btn, settings)
            end
        end
    end
end

local function RefreshAllFlyouts()
    for _, barKey in ipairs(STANDARD_BAR_KEYS) do
        local btns = ActionBarsOwned.nativeButtons[barKey]
        local runtimeVisible = not ActionBarsOwned.IsBarRuntimeVisible or ActionBarsOwned.IsBarRuntimeVisible(barKey)
        if btns and runtimeVisible then
            for _, btn in ipairs(btns) do
                ns.SafeCallMethodIfPresent("best-effort-style", btn, "UpdateFlyout")
            end
        end
    end
    ApplyAllFlyoutDirections()
    if SyncOwnedFlyoutInfoToHandler then SyncOwnedFlyoutInfoToHandler() end
end

local function RefreshContextVisibilityFade()
    if RefreshActionBarContextVisibility then
        RefreshActionBarContextVisibility()
    end
    if _G.TUI_RefreshActionBarFade then
        _G.TUI_RefreshActionBarFade()
    end
end

AB_CD_UPDATE_INTERVAL_COMBAT = 0.033
AB_CD_UPDATE_INTERVAL_IDLE   = 0.20
AB_STATE_UPDATE_INTERVAL     = 0.033
AB_VIS_UPDATE_INTERVAL       = 0.033

abUpdateFrame = CreateFrame("Frame")
abUpdateFrame:Hide()
abUpdateFrame._lastCd = 0
abUpdateFrame._lastState = 0
abUpdateFrame._lastVis = 0
abUpdateFrame._dirtyCooldowns = false
abUpdateFrame._dirtyStates = false
abUpdateFrame._dirtyVisuals = false
abUpdateFrame._dirtyCounts = false
abUpdateFrame._immediate = false
abUpdateFrame:SetScript("OnUpdate", function(self)
    local now = GetTime()
    local inCombat = InCombatLockdown()
    local throttle = inCombat and not self._immediate
    local cdInterval = inCombat and AB_CD_UPDATE_INTERVAL_COMBAT or AB_CD_UPDATE_INTERVAL_IDLE
    self._immediate = false

    local doVis = self._dirtyVisuals
    local doState = self._dirtyStates
    local doCd  = self._dirtyCooldowns
    local doCount = self._dirtyCounts

    if doVis then
        if throttle and (now - self._lastVis < AB_VIS_UPDATE_INTERVAL) then return end
        self:Hide()
        self._lastVis = now
        self._lastCd = now
        self._lastState = now
        self._dirtyCooldowns = false
        self._dirtyStates = false
        self._dirtyVisuals = false
        self._dirtyCounts = false
        ActionBarsOwned.UpdateAllButtonVisuals()
    elseif doState then
        if throttle and (now - self._lastState < AB_STATE_UPDATE_INTERVAL) then return end
        self:Hide()
        self._lastState = now
        self._dirtyStates = false
        ActionBarsOwned.UpdateAllButtonStates()
        if doCd then
            if now - self._lastCd >= cdInterval then
                self._lastCd = now
                self._dirtyCooldowns = false
                ActionBarsOwned.UpdateAllCooldowns()
            else
                self:Show()
            end
        end
        if doCount then
            self._dirtyCounts = false
            ActionBarsOwned.UpdateAllButtonCounts()
        end
    elseif doCd then
        if now - self._lastCd < cdInterval then return end
        self:Hide()
        self._lastCd = now
        self._dirtyCooldowns = false
        ActionBarsOwned.UpdateAllCooldowns()
        if doCount then
            self._dirtyCounts = false
            ActionBarsOwned.UpdateAllButtonCounts()
        end
    elseif doCount then
        self:Hide()
        self._dirtyCounts = false
        ActionBarsOwned.UpdateAllButtonCounts()
    else
        self:Hide()
    end
end)

ActionBarsOwned._perfProbesEnabled = false
if ns.TUI_ENABLE_ACTIONBAR_SPLIT_PERF_PROBES == true or _G.TUI_ENABLE_ACTIONBAR_SPLIT_PERF_PROBES == true then
    ActionBarsOwned._perfProbesEnabled = true
    local origAllCd    = ActionBarsOwned.UpdateAllCooldowns
    local origAllVis   = ActionBarsOwned.UpdateAllButtonVisuals
    local origAllState = ActionBarsOwned.UpdateAllButtonStates
    local cdProbeFrame    = CreateFrame("Frame")
    local visProbeFrame   = CreateFrame("Frame")
    local stateProbeFrame = CreateFrame("Frame")
    cdProbeFrame:SetScript("OnEvent",    function() origAllCd()    end)
    visProbeFrame:SetScript("OnEvent",   function() origAllVis()   end)
    stateProbeFrame:SetScript("OnEvent", function() origAllState() end)
    ActionBarsOwned.UpdateAllCooldowns     = function() cdProbeFrame:GetScript("OnEvent")()    end
    ActionBarsOwned.UpdateAllButtonVisuals = function() visProbeFrame:GetScript("OnEvent")()   end
    ActionBarsOwned.UpdateAllButtonStates  = function() stateProbeFrame:GetScript("OnEvent")() end
    local function SetupSplitPerfProbeRegistry()
        ns.TUI_PerfRegistry = ns.TUI_PerfRegistry or {}
        ns.TUI_PerfRegistry[#ns.TUI_PerfRegistry + 1] = { name = "AB_Cooldowns", frame = cdProbeFrame,    scriptType = "OnEvent" }
        ns.TUI_PerfRegistry[#ns.TUI_PerfRegistry + 1] = { name = "AB_States",    frame = stateProbeFrame, scriptType = "OnEvent" }
        ns.TUI_PerfRegistry[#ns.TUI_PerfRegistry + 1] = { name = "AB_Visuals",   frame = visProbeFrame,   scriptType = "OnEvent" }
    end
    if ns.DebugRegister then
        ns.DebugRegister(SetupSplitPerfProbeRegistry)
    else
        SetupSplitPerfProbeRegistry()
    end
end

function ScheduleABCooldownUpdate(immediate)
    abUpdateFrame._dirtyCooldowns = true
    if immediate then abUpdateFrame._immediate = true end
    abUpdateFrame:Show()
end

function ScheduleABVisualUpdate(full, immediate)
    abUpdateFrame._dirtyVisuals = true
    if immediate then abUpdateFrame._immediate = true end
    if full then
        ActionBarsOwned.ForceFullVisualRescan()
    end
    abUpdateFrame:Show()
end

function ScheduleABStateUpdate(immediate)
    abUpdateFrame._dirtyStates = true
    if immediate then abUpdateFrame._immediate = true end
    abUpdateFrame:Show()
end

function ScheduleABCountUpdate()
    abUpdateFrame._dirtyCounts = true
    abUpdateFrame:Show()
end

abDirtySlots = {}
abSlotFrame = CreateFrame("Frame")
abSlotFrame:Hide()
_lastPagingTime = 0

abSlotFrame:SetScript("OnUpdate", function(self)
    self:Hide()
    local slotMap = ActionBarsOwned.slotMap
    local inCombat = InCombatLockdown()
    for slot in pairs(abDirtySlots) do
        if slotMap then
            local entry = slotMap[slot]
            if entry then
                local btn, barKey = entry.button, entry.barKey
                if ResetButtonChargeCapabilityCache then
                    ResetButtonChargeCapabilityCache(btn)
                end
                ns.SafeCall("best-effort-style", ActionBarsOwned.SafeUpdate, btn)
                ActionBarsOwned.UpdateCooldown(btn)
                ActionBarsOwned.UpdateOverlayGlow(btn)
                if not inCombat then
                    local cont = ActionBarsOwned.containers and ActionBarsOwned.containers[barKey]
                    local refreshRef = btn.GetAttribute and btn:GetAttribute("qui-refresh-ref")
                    if cont and refreshRef then
                        cont:SetAttribute("qui-refresh-target", refreshRef)
                        cont:SetAttribute("qui-refresh-target", nil)
                    end
                end
                if not inCombat then
                    local settings = GetEffectiveSettings(barKey)
                    if settings then
                        local st = GetFrameState(btn)
                        st.sk_sz = nil
                        SkinButton(btn, settings)
                        UpdateButtonText(btn, settings)
                        UpdateEmptySlotVisibility(btn, settings)
                    end
                end
                -- TOMOMOD: slot contents can change without a separate usable
                -- event. Refresh the affected button now so an old mana/range/
                -- unusable tint cannot survive a spell/item replacement.
                local globalSettings = GetGlobalSettings()
                if globalSettings and UpdateButtonUsability then
                    UpdateButtonUsability(btn, globalSettings)
                end
            end
        end
    end
    wipe(abDirtySlots)
    if MarkSpellIdMapDirty then MarkSpellIdMapDirty() end
    if SyncOwnedFlyoutInfoToHandler then
        SyncOwnedFlyoutInfoToHandler()
    end
    _assistRotationButton = nil
    UpdateAllAssistedHighlights()
    ActionBarsOwned.UpdateAllAssistedCombatRotation()
end)

-- TOMOMOD P3.2.1: consume the usability batch itself, mirroring Blizzard's
-- ActionBarButtonUsableWatcherFrame. This preserves conditional usability states
-- (for example Touch of Death) without reading target health or branching on
-- secret unit data. Secret/inaccessible payload fields simply fall back to the
-- existing safe query path inside UpdateButtonUsability.
local function RefreshButtonUsabilityForChanges(changes)
    if type(changes) ~= "table" then return false end
    local slotMap = ActionBarsOwned.slotMap
    local settings = GetGlobalSettings and GetGlobalSettings() or nil
    if not slotMap or not settings or not UpdateButtonUsability then return false end

    local sawMappedSlot = false
    for _, change in ipairs(changes) do
        if type(change) == "table" then
            local slot = Helpers.SafeValue(change.slot, nil)
            if type(slot) == "number" and slot > 0 then
                local entry = slotMap[slot]
                local btn = entry and entry.button
                if btn then
                    sawMappedSlot = true
                    local barKey = entry.barKey or btn._tomomodBarKey
                    if not ActionBarsOwned.IsBarRuntimeVisible
                        or ActionBarsOwned.IsBarRuntimeVisible(barKey) then
                        UpdateButtonUsability(btn, settings, change.usable, change.noMana)
                    end
                end
            end
        end
    end
    return sawMappedSlot
end

-- TOMOMOD P3.2: reconcile the proc glow from the action-slot usability
-- signal rather than trying to inspect target health in Lua.  Midnight sends
-- ACTION_USABLE_CHANGED as a batch of { slot, usable, noMana } records.  This
-- is especially important for threshold actions such as Touch of Death: their
-- activation overlay can become true when the target crosses the execute
-- condition even when the GLOW_SHOW spell id is not useful to a detached
-- custom button.  Query IsSpellOverlayed on the button currently occupying the
-- changed slot, which keeps Blizzard as the source of truth.
local function RefreshGlowForUsabilityChanges(changes)
    if type(changes) ~= "table" then
        ActionBarsOwned.UpdateAllOverlayGlows()
        return
    end

    local slotMap = ActionBarsOwned.slotMap
    if not slotMap then
        ActionBarsOwned.UpdateAllOverlayGlows()
        return
    end

    local sawMappedSlot = false
    for _, change in ipairs(changes) do
        local slot = type(change) == "table" and Helpers.SafeValue(change.slot, nil) or nil
        if type(slot) == "number" and slot > 0 then
            local entry = slotMap[slot]
            local btn = entry and entry.button
            if btn then
                sawMappedSlot = true
                local barKey = entry.barKey or btn._tomomodBarKey
                if not ActionBarsOwned.IsBarRuntimeVisible
                    or ActionBarsOwned.IsBarRuntimeVisible(barKey) then
                    ActionBarsOwned.UpdateOverlayGlow(btn)
                end
            end
        end
    end

    -- A batch can describe a slot which is currently represented through a
    -- macro/flyout or a page transition not yet present in slotMap.  Falling
    -- back only in that uncommon case keeps the hot path targeted.
    if not sawMappedSlot then
        ActionBarsOwned.UpdateAllOverlayGlows()
    end
end

function ScheduleSlotUpdate(slot)
    if slot == 0 then
        -- TOMOMOD: Blizzard uses slot 0 as "all slots changed". Ignoring it
        -- leaves stale icons/tints/cooldowns after broad content changes.
        if ResetAllChargeCapabilityCaches then ResetAllChargeCapabilityCaches() end
        ScheduleABVisualUpdate(true, true)
        ScheduleABCooldownUpdate(true)
        ScheduleUsabilityUpdate()
        if MarkSpellIdMapDirty then MarkSpellIdMapDirty() end
        return
    end
    if not slot or slot < 1 then return end
    if GetTime() - _lastPagingTime < 0.5 then return end
    abDirtySlots[slot] = true
    abSlotFrame:Show()
end

-- TOMOMOD: the events after which the client may have handed their events back
-- to the Blizzard originals we retired at build time. Every one of these is
-- already registered on ownedEventFrame; the sweep is idempotent and skips
-- itself in combat, so re-entering it twice on a vehicle swap is free.
-- P3.5.17: Blizzard repaints the native Stance/Pet/Possess visuals on these
-- events. Reapply the region mask plus the residual Cooldown/AutoCastOverlay
-- helper-frame alpha on the next frame, after Blizzard's own handlers finish.
-- The protected bar/button frames themselves remain untouched.
local NATIVE_SPECIAL_VISUAL_RESUPPRESS_EVENTS = {
    PLAYER_ENTERING_WORLD = true,
    PLAYER_REGEN_ENABLED = true,
    UPDATE_SHAPESHIFT_FORM = true,
    UPDATE_SHAPESHIFT_FORMS = true,
    UPDATE_SHAPESHIFT_COOLDOWN = true,
    UPDATE_SHAPESHIFT_USABLE = true,
    PET_BAR_UPDATE = true,
    PET_BAR_UPDATE_COOLDOWN = true,
    PET_UI_UPDATE = true,
    UNIT_PET = true,
    UPDATE_VEHICLE_ACTIONBAR = true,
    UPDATE_POSSESS_BAR = true,
}

local function ScheduleNativeSpecialVisualResuppression()
    if not C_Timer or not C_Timer.After then return end
    C_Timer.After(0, function()
        if not ActionBarsOwned.initialized then return end
        if ActionBarsOwned.SuppressNativeSpecialVisualRegions then
            ActionBarsOwned.SuppressNativeSpecialVisualRegions()
        end
    end)
end

local RESUPPRESS_EVENTS = {
    PLAYER_ENTERING_WORLD    = true,
    PLAYER_REGEN_ENABLED     = true,
    ACTIONBAR_PAGE_CHANGED   = true,
    UPDATE_BONUS_ACTIONBAR   = true,
    UPDATE_OVERRIDE_ACTIONBAR = true,
    UPDATE_VEHICLE_ACTIONBAR = true,
    UNIT_ENTERED_VEHICLE     = true,
    UNIT_EXITED_VEHICLE      = true,
    UPDATE_SHAPESHIFT_FORM   = true,
    PET_BATTLE_CLOSE         = true,
}

function OnOwnedEvent(self, event, ...)
    if not ActionBarsOwned.initialized then return end

    if RESUPPRESS_EVENTS[event] then
        ResuppressBlizzardButtons()
    end

    if NATIVE_SPECIAL_VISUAL_RESUPPRESS_EVENTS[event] then
        ScheduleNativeSpecialVisualResuppression()
    end

    if event == "ACTIONBAR_SLOT_CHANGED" then
        local slot = ...
        ScheduleSlotUpdate(slot)
        ScheduleUsabilityUpdate()

    elseif event == "ACTIONBAR_PAGE_CHANGED"
        or event == "UPDATE_BONUS_ACTIONBAR"
        -- TOMOMOD: routed here rather than to the UPDATE_VEHICLE_ACTIONBAR
        -- branch below. That branch only schedules a visual rescan; this one
        -- also rebuilds the slotMap and repaints, which is what an override
        -- swap actually needs -- the buttons point at different slots.
        or event == "UPDATE_OVERRIDE_ACTIONBAR"
        or event == "UPDATE_SHAPESHIFT_FORM"
        or event == "UPDATE_SHAPESHIFT_FORMS"
        or event == "UPDATE_STEALTH" then
        _lastPagingTime = GetTime()
        _assistRotationButton = nil
        if HideOwnedFlyout then
            HideOwnedFlyout()
        end
        local buttons = ActionBarsOwned.nativeButtons["bar1"]
        local slotMap = ActionBarsOwned.slotMap
        if slotMap then
            for slot, entry in pairs(slotMap) do
                if entry.barKey == "bar1" then
                    slotMap[slot] = nil
                end
            end
            if buttons then
                for _, btn in ipairs(buttons) do
                    local action = GetSafeActionSlot(btn)
                    if action and action > 0 then
                        slotMap[action] = { button = btn, barKey = "bar1" }
                        if ResetButtonChargeCapabilityCache then
                            ResetButtonChargeCapabilityCache(btn)
                        end
                    end
                end
            end
        end
        local settings = GetEffectiveSettings("bar1")
        if buttons and settings then
            for _, btn in ipairs(buttons) do
                UpdateEmptySlotVisibility(btn, settings)
            end
        end
        if buttons then
            for _, btn in ipairs(buttons) do
                ActionBarsOwned.UpdateCooldown(btn)
                ActionBarsOwned.UpdateOverlayGlow(btn)
            end
        end

        -- TOMOMOD: repaint the buttons after a page change.
        --
        -- Paging swaps each button's action attribute through the secure
        -- snippet, but nothing above repaints the icon: this branch only
        -- refreshed cooldown, glow and empty-slot visibility. Upstream relies
        -- on the hooksecurefunc("ActionButton_Update", ...) installed in
        -- actionbars_public.lua to catch Blizzard's own repaint -- and that
        -- hook is installed only `if ActionButton_Update then`, a global that
        -- no longer exists on modern retail. So on a vehicle, a possess bar or
        -- a skyriding page swap the buttons kept their previous artwork, or
        -- none at all, until something forced a full rebuild.
        --
        -- This is the same trio the hook would have run, and the same one
        -- OwnedButton_PostDrag uses after a drag. Guarded on combat because
        -- SkinButton resizes and re-anchors regions.
        -- TOMOMOD: run the repaint now AND once more on the next frame.
        --
        -- The secure snippet sets each button's action attribute during the
        -- page swap. GetSafeActionSlot reads that attribute directly, so the
        -- repaint never depends on a stale Lua-side button.action snapshot.
        -- The deferred pass remains useful for APIs whose visual data settles
        -- one frame after the secure page transition --
        -- and with hideEmptySlots on, UpdateEmptySlotVisibility answers by
        -- setting alpha 0. That is the symptom: on a vehicle, skyriding or
        -- druid Flight Form the buttons are present but invisible, and
        -- unticking "hide empty slots" makes it go away entirely.
        --
        -- Nothing re-evaluates afterwards, which is why only a full rebuild
        -- (TUI_RefreshActionBars or /reload) brought them back. The deferred
        -- pass is the same C_Timer.After(0, ...) idiom OwnedButton_PostDrag
        -- already uses after a drag, for the same reason.
        local function RepaintBar1(list, s)
            if not list or not s then return end
            local inCombat = InCombatLockdown()
            for _, btn in ipairs(list) do
                -- SafeUpdate is visual-only on TUI-owned buttons and now reads
                -- the authoritative secure action attribute without copying it
                -- into Lua state. This lets Cat/Bear/vehicle/possess pages repaint
                -- immediately in combat. Geometry/skin writes remain out-of-combat.
                ActionBarsOwned.SafeUpdate(btn)
                if not inCombat then
                    local st = GetFrameState(btn)
                    st.sk_sz = nil
                    SkinButton(btn, s)
                end
                UpdateButtonText(btn, s)
                UpdateEmptySlotVisibility(btn, s)
            end
        end

        RepaintBar1(buttons, settings)
        C_Timer.After(0, function()
            if not ActionBarsOwned.initialized then return end
            -- Settings are re-read rather than captured: a page swap can cross
            -- a profile change, and a stale table would repaint from the wrong
            -- one.
            RepaintBar1(ActionBarsOwned.nativeButtons["bar1"], GetEffectiveSettings("bar1"))
            ScheduleUsabilityUpdate()
        end)
        if not InCombatLockdown() then
            UpdateStanceBarLayout()
        else
            ActionBarsOwned.pendingStanceUpdate = true
        end
        ApplyBar1OverrideBindings()

    elseif event == "UPDATE_SHAPESHIFT_COOLDOWN" or event == "UPDATE_SHAPESHIFT_USABLE" then
        ActionBarsOwned.UpdateAllStanceButtons()

    elseif event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" then
        local unit = ...
        if unit == "player" then
            ApplyBar1OverrideBindings()
            if event == "UNIT_EXITED_VEHICLE" then
                C_Timer.After(0.2, function()
                    if not ActionBarsOwned.initialized then return end
                    if InCombatLockdown() then
                        ActionBarsOwned.pendingMicroReclaim = true
                        ActionBarsOwned.pendingBagsReclaim = true
                        return
                    end
                    ReclaimBarButtons("microbar")
                    ReclaimBarButtons("bags")
                end)
            end
        end

    elseif event == "UPDATE_BINDINGS" then
        -- P0: binding changes are input-path state. Do not add an arbitrary
        -- 100 ms dead window before rebuilding our override CLICK bindings.
        RefreshNativeKeybinds()

    elseif event == "CURSOR_CHANGED" then
        local settings = GetGlobalSettings()
        if settings and settings.hideEmptySlots then
            local shouldPreview = CursorHasPlaceableAction()
            if shouldPreview ~= (ActionBarsOwned.dragPreviewActive or false) then
                ActionBarsOwned.dragPreviewActive = shouldPreview or nil
                RefreshAllEmptySlotVisibility()
            end
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        if ActionBarsOwned.pendingExtraButtonInit then
            ActionBarsOwned.pendingExtraButtonInit = false
            InitializeExtraButtons()
        end
        if ActionBarsOwned.pendingExtraButtonRefresh then
            ActionBarsOwned.pendingExtraButtonRefresh = false
            RefreshExtraButtons()
        end
        if ActionBarsOwned.pendingRefresh then
            ActionBarsOwned.pendingRefresh = false
            ActionBarsOwned:Refresh()
        end
        if ActionBarsOwned.pendingUseOnKeyDownUpdate then
            ActionBarsOwned.pendingUseOnKeyDownUpdate = false
            if _G.TUI_ApplyUseOnKeyDown then _G.TUI_ApplyUseOnKeyDown() end
        end
        if ActionBarsOwned.pendingBindings then
            ActionBarsOwned.pendingBindings = false
            ApplyAllOverrideBindings()
        end
        if ActionBarsOwned.pendingPetUpdate then
            ActionBarsOwned.pendingPetUpdate = false
            UpdatePetBarVisibility()
        end
        if ActionBarsOwned.pendingStanceUpdate then
            ActionBarsOwned.pendingStanceUpdate = false
            UpdateStanceBarLayout()
        end
        if ActionBarsOwned.pendingMicroReclaim then
            ActionBarsOwned.pendingMicroReclaim = false
            ReclaimBarButtons("microbar")
        end
        if ActionBarsOwned.pendingBagsReclaim then
            ActionBarsOwned.pendingBagsReclaim = false
            ReclaimBarButtons("bags")
        end
        if ActionBarsOwned.pendingSpacing then
            ActionBarsOwned.pendingSpacing = false
            ApplyAllBarSpacing()
        end
        if ActionBarsOwned.pendingFlyoutDirection then
            ActionBarsOwned.pendingFlyoutDirection = false
            if ApplyAllFlyoutDirections then ApplyAllFlyoutDirections() end
        end
        if ActionBarsOwned.pendingFlyoutSkin then
            ActionBarsOwned.pendingFlyoutSkin = false
            if SkinSpellFlyoutButtons then SkinSpellFlyoutButtons() end
        end
        if ActionBarsOwned.pendingOwnedFlyoutSync then
            ActionBarsOwned.pendingOwnedFlyoutSync = false
            if SyncOwnedFlyoutInfoToHandler then SyncOwnedFlyoutInfoToHandler() end
        end

    elseif event == "PET_BAR_UPDATE" or event == "PET_BAR_UPDATE_COOLDOWN" then
        ActionBarsOwned.UpdateAllPetButtons()
        UpdatePetBarVisibility()

    elseif event == "PET_UI_UPDATE" or event == "UNIT_PET" then
        local unit = ...
        if event == "UNIT_PET" and unit ~= "player" then return end
        C_Timer.After(0.1, function()
            if not ActionBarsOwned.initialized then return end
            UpdatePetBarVisibility()
        end)

    elseif event == "PLAYER_ENTERING_WORLD" then
        local isLogin, isReload = ...
        if isReload then
            ApplyAllBarSpacing()
            ActionBarsOwned.pendingSpacing = true
        end
        if ns.TUI_Anchoring and ns.TUI_Anchoring.ApplyAllFrameAnchors then
            ns.TUI_Anchoring:ApplyAllFrameAnchors(true)
        end
        for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
            LayoutNativeButtons(barKey)
            RestoreContainerPosition(barKey)
        end
        RefreshAllNativeVisuals()
        ActionBarsOwned.UpdateAllButtonVisuals()
        ActionBarsOwned.UpdateAllCooldowns()
        ScheduleUsabilityUpdate()
        UpdatePetBarVisibility()
        UpdateStanceBarLayout()
        ApplyAllFlyoutDirections()
        if SyncOwnedFlyoutInfoToHandler then SyncOwnedFlyoutInfoToHandler() end
        RefreshContextVisibilityFade()
        C_Timer.After(0.2, function()
            if InCombatLockdown() then
                ActionBarsOwned.pendingRefresh = true
                ActionBarsOwned.pendingPetUpdate = true
                ActionBarsOwned.pendingStanceUpdate = true
                return
            end
            for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
                LayoutNativeButtons(barKey)
                RestoreContainerPosition(barKey)
            end
            RefreshAllNativeVisuals()
            ActionBarsOwned.ForceFullVisualRescan()
            ActionBarsOwned.UpdateAllButtonVisuals()
            ActionBarsOwned.UpdateAllCooldowns()
            ScheduleUsabilityUpdate()
            UpdatePetBarVisibility()
            UpdateStanceBarLayout()
            ApplyAllFlyoutDirections()
            if SyncOwnedFlyoutInfoToHandler then SyncOwnedFlyoutInfoToHandler() end
            RefreshContextVisibilityFade()
        end)
        local db = GetDB()
        if db and db.bars and db.bars.bar1 then
            C_Timer.After(0.1, function()
                ApplyPageArrowVisibility(db.bars.bar1.hidePageArrow)
            end)
            C_Timer.After(0.6, function()
                ApplyPageArrowVisibility(db.bars.bar1.hidePageArrow)
            end)
        end

    elseif event == "PLAYER_REGEN_DISABLED" then
        local fadeSettings = GetFadeSettings()
        if fadeSettings and fadeSettings.enabled and fadeSettings.alwaysShowInCombat then
            for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
                local state = GetOwnedBarFadeState(barKey)
                CancelOwnedBarFadeTimers(state)
                StartOwnedBarFade(barKey, 1)
            end
        end

    elseif event == "ZONE_CHANGED_NEW_AREA"
        or event == "ZONE_CHANGED"
        or event == "ZONE_CHANGED_INDOORS"
        or event == "PLAYER_DIFFICULTY_CHANGED"
        or event == "UPDATE_INSTANCE_INFO"
        or event == "CHALLENGE_MODE_START"
        or event == "CHALLENGE_MODE_COMPLETED"
        or event == "CHALLENGE_MODE_RESET" then
        RefreshContextVisibilityFade()

    elseif event == "ENCOUNTER_START" then
        local encounterID, encounterName, difficultyID = ...
        if SetActionBarEncounterVisibilityContext then
            SetActionBarEncounterVisibilityContext(encounterID, encounterName, difficultyID)
        end
        RefreshContextVisibilityFade()

    elseif event == "ENCOUNTER_END" then
        local encounterID = ...
        if ClearActionBarEncounterVisibilityContext then
            ClearActionBarEncounterVisibilityContext(encounterID)
        end
        RefreshContextVisibilityFade()

    elseif event == "PLAYER_LEVEL_UP" then
        if UpdateLevelSuppressionState() then
            if type(_G.TUI_RefreshActionBars) == "function" then
                _G.TUI_RefreshActionBars()
            end
        end

    elseif event == "ACTIONBAR_UPDATE_COOLDOWN"
        or event == "LOSS_OF_CONTROL_ADDED"
        or event == "LOSS_OF_CONTROL_UPDATE" then
        if _abCooldownStats then _abCooldownStats.events = _abCooldownStats.events + 1 end
        ScheduleABCooldownUpdate()

    elseif event == "ACTIONBAR_UPDATE_STATE" then
        ScheduleABStateUpdate()

    elseif event == "SPELL_UPDATE_ICON" then
        ScheduleABVisualUpdate(false, true)

    elseif event == "MODIFIER_STATE_CHANGED" then
        ScheduleABVisualUpdate(false, true)

    elseif event == "ACTIONBAR_UPDATE_USABLE" then
        ScheduleUsabilityUpdate()

    elseif event == "ACTION_USABLE_CHANGED" then
        local changes = ...
        if not RefreshButtonUsabilityForChanges(changes) then
            ScheduleUsabilityUpdate()
        end
        RefreshGlowForUsabilityChanges(changes)

    elseif event == "PLAYER_TARGET_CHANGED" then
        -- Target swaps can select an already-executable target without a fresh
        -- overlay edge.  A target change is sparse, so one visible-bar scan is
        -- cheap and guarantees the activation glow is reconciled immediately.
        ScheduleUsabilityUpdate()
        ActionBarsOwned.UpdateAllOverlayGlows()

    elseif event == "SPELL_UPDATE_CHARGES" then
        ScheduleABCountUpdate()

    elseif event == "UNIT_AURA" then
        ScheduleABCountUpdate()

    elseif event == "ACTIONBAR_SHOWGRID" then
        ActionBarsOwned._showGrid = true
        self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
        for _, barKey in ipairs(STANDARD_BAR_KEYS) do
            local btns = ActionBarsOwned.nativeButtons[barKey]
            if btns then
                for _, btn in ipairs(btns) do
                    btn:SetAlpha(1)
                end
            end
        end

    elseif event == "ACTIONBAR_HIDEGRID" then
        ActionBarsOwned._showGrid = nil
        -- TOMOMOD: ACTIONBAR_SLOT_CHANGED remains registered permanently; it
        -- also carries non-drag transforms and spec/loadout content changes.
        ScheduleABVisualUpdate(true)
        ScheduleABCooldownUpdate()
        ActionBarsOwned.UpdateAllAssistedCombatRotation()
        UpdateAllAssistedHighlights()
        RefreshAllEmptySlotVisibility()
        if MarkSpellIdMapDirty then MarkSpellIdMapDirty() end
        if SyncOwnedFlyoutInfoToHandler then SyncOwnedFlyoutInfoToHandler() end

    elseif event == "PLAYER_ENTER_COMBAT" or event == "PLAYER_LEAVE_COMBAT" then
        ScheduleABVisualUpdate(false, true)

    elseif event == "START_AUTOREPEAT_SPELL" or event == "STOP_AUTOREPEAT_SPELL" then
        ScheduleABVisualUpdate(false, true)

    elseif event == "SPELLS_CHANGED"
        or event == "LEARNED_SPELL_IN_SKILL_LINE" then
        -- TOMOMOD: a spec/loadout swap can replace the contents of an action
        -- slot without changing its numeric slot. Drop per-button cooldown and
        -- charge memos so the new action cannot inherit the previous spell's
        -- cached duration/state.
        if ResetAllChargeCapabilityCaches then ResetAllChargeCapabilityCaches() end
        ScheduleABVisualUpdate(true)
        ScheduleABCooldownUpdate()
        ScheduleUsabilityUpdate()
        ActionBarsOwned.UpdateAllOverlayGlows()
        RefreshAllFlyouts()
        RefreshAllEmptySlotVisibility()
        RefreshExtraButtons()

    elseif event == "SPELL_FLYOUT_UPDATE" then
        RefreshAllFlyouts()

    elseif event == "SPELL_UPDATE_USABLE" then
        ScheduleUsabilityUpdate()

    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
        local spellId = ...
        ActionBarsOwned.OnSpellActivationGlowShow(spellId)

    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        local spellId = ...
        ActionBarsOwned.OnSpellActivationGlowHide(spellId)

    elseif event == "UPDATE_VEHICLE_ACTIONBAR" then
        ScheduleABVisualUpdate(true)
        ScheduleABCooldownUpdate()
        ActionBarsOwned.UpdateAllOverlayGlows()
        ApplyBar1OverrideBindings()
        -- TOMOMOD: a vehicle swap repoints bar 1 at different action slots, so
        -- a visual rescan alone leaves the slotMap stale and the icons behind.
        -- Re-enter this handler through the paging path, which rebuilds both.
        OnOwnedEvent(self, "ACTIONBAR_PAGE_CHANGED")

    elseif event == "UPDATE_EXTRA_ACTIONBAR" then
        RefreshExtraButtons()

    elseif event == "UNIT_INVENTORY_CHANGED" then
        local unit = ...
        if unit == "player" then
            ScheduleABVisualUpdate(true)
            ScheduleABCooldownUpdate()
        end

    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        ScheduleABVisualUpdate()

    elseif event == "PET_BATTLE_OPENING_START" then
        if not InCombatLockdown() then
            for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
                local cont = ActionBarsOwned.containers[barKey]
                if cont then
                    ClearOverrideBindings(cont)
                    cont:Hide()
                end
            end
        end

    elseif event == "PET_BATTLE_CLOSE" then
        if not InCombatLockdown() then
            for _, barKey in ipairs(ALL_MANAGED_BAR_KEYS) do
                local cont = ActionBarsOwned.containers[barKey]
                if cont then cont:Show() end
            end
            ApplyAllOverrideBindings()
            UpdatePetBarVisibility()
            UpdateStanceBarLayout()
        else
            ActionBarsOwned.pendingBindings = true
            ActionBarsOwned.pendingRefresh = true
        end
    end
end

ownedEventFrame:SetScript("OnEvent", OnOwnedEvent)

local function SetupDebugInstrumentation()
    _abCooldownStats = _G._abCooldownStats
    ns.TUI_PerfRegistry = ns.TUI_PerfRegistry or {}
    ns.TUI_PerfRegistry[#ns.TUI_PerfRegistry + 1] = { name = "ActionBars", frame = ownedEventFrame }
end
if ns.DebugRegister then
    ns.DebugRegister(SetupDebugInstrumentation)
else
    SetupDebugInstrumentation()
end

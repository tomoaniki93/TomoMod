-- =====================================================================
-- Ported from Tui: TUI_ActionBars/actionbars/actionbars_usability.lua
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

do

local _abUsabilityStats
local function SetupDebugInstrumentation()
    _abUsabilityStats = { activeScans = 0, fallbackScans = 0, buttons = 0, rangeScans = 0, rangeButtons = 0, rangeEvents = 0 }
    local mp = ns._memprobes or {}; ns._memprobes = mp
    mp[#mp + 1] = { name = "AB_usabilityActiveScans", counter = true, fn = function() return _abUsabilityStats.activeScans end }
    mp[#mp + 1] = { name = "AB_usabilityFallbackScans", counter = true, fn = function() return _abUsabilityStats.fallbackScans end }
    mp[#mp + 1] = { name = "AB_usabilityButtons", counter = true, fn = function() return _abUsabilityStats.buttons end }
    mp[#mp + 1] = { name = "AB_rangeScans", counter = true, fn = function() return _abUsabilityStats.rangeScans end }
    mp[#mp + 1] = { name = "AB_rangeButtons", counter = true, fn = function() return _abUsabilityStats.rangeButtons end }
    mp[#mp + 1] = { name = "AB_rangeEvents", counter = true, fn = function() return _abUsabilityStats.rangeEvents end }
end
if ns.DebugRegister then
    ns.DebugRegister(SetupDebugInstrumentation)
else
    SetupDebugInstrumentation()
end

local function ClearButtonTint(state)
    if state.tintOverlay then state.tintOverlay:Hide() end
    state.tinted = nil
    state.usabilityTint = nil
    state.rangeOut = nil
end

function GetTintOverlay(button)
    local state = GetFrameState(button)
    if not state.tintOverlay then
        local icon = GetButtonIconTexture(button)
        if not icon then return nil end
        local overlay = button:CreateTexture(nil, "ARTWORK", nil, 1)
        overlay:SetAllPoints(icon)
        overlay:SetBlendMode("MOD")
        overlay:SetColorTexture(1, 1, 1, 1)
        overlay:Hide()
        state.tintOverlay = overlay
    end
    return state.tintOverlay
end

-- TOMOMOD P1 PERF: range and usability have different update semantics.
-- Mana/unusable changes are event-driven; distance has no equivalent event and
-- still needs a lightweight poll. Cache the two inputs separately so a range
-- tick never calls IsUsableAction and an usability event never needs to own the
-- continuous range loop.
local function ApplyCachedButtonTint(button, settings, state)
    -- P3.2.2: usability is the stronger state. A conditional spell that cannot
    -- currently be used (Touch of Death is the canonical example) should stay
    -- dim even if its target is also out of range. Range is only meaningful for
    -- an otherwise-usable action.
    local newTint = state.usabilityTint or (state.rangeOut and "range")
    if state.tinted == newTint then return end

    if newTint == "range" then
        local overlay = GetTintOverlay(button)
        if overlay then
            local c = settings.rangeColor
            overlay:SetColorTexture(c and c[1] or 0.8, c and c[2] or 0.1, c and c[3] or 0.1, c and c[4] or 1)
            overlay:Show()
        end
        state.tinted = "range"
    elseif newTint == "mana" then
        local overlay = GetTintOverlay(button)
        if overlay then
            local c = settings.manaColor
            overlay:SetColorTexture(c and c[1] or 0.5, c and c[2] or 0.5, c and c[3] or 1.0, c and c[4] or 1)
            overlay:Show()
        end
        state.tinted = "mana"
    elseif newTint == "unusable" then
        local overlay = GetTintOverlay(button)
        if overlay then
            local c = settings.usabilityColor
            overlay:SetColorTexture(c and c[1] or 0.4, c and c[2] or 0.4, c and c[3] or 0.4, c and c[4] or 1)
            overlay:Show()
        end
        state.tinted = "unusable"
    else
        if state.tintOverlay then state.tintOverlay:Hide() end
        state.tinted = nil
    end
end

local function SetRangeCandidate(button, isCandidate)
    local candidates = usabilityState.rangeCandidates
    if not candidates then return end
    candidates[button] = isCandidate and true or nil

    -- TOMOMOD P1 PERF: no range-capable action means no permanent OnUpdate at
    -- all. Events remain registered while the frame is hidden and will seed a
    -- new candidate (target/slot/page change), which wakes the ticker again.
    local checkFrame = usabilityState.checkFrame
    if checkFrame and usabilityState.rangePollingActive then
        if isCandidate or next(candidates) ~= nil then
            checkFrame:Show()
        else
            checkFrame:Hide()
            checkFrame.elapsed = 0
        end
    end
end

local function UpdateButtonRangeOnly(button, settings)
    if not settings or not settings.rangeIndicator then return false end
    local state = GetFrameState(button)
    local action = GetSafeActionSlot(button)

    if state.fadeHidden or state.hiddenEmpty or not action or not SafeHasAction(action) then
        state.rangeOut = nil
        SetRangeCandidate(button, false)
        ApplyCachedButtonTint(button, settings, state)
        return false
    end

    -- P3.2.2: no target is not "out of range". Some actions report false from
    -- the range API while targetless during early login/page initialization;
    -- painting that red creates the exact stale state that used to disappear
    -- only after mousing over the button. PLAYER_TARGET_CHANGED reseeds range.
    if UnitExists and not UnitExists("target") then
        state.rangeOut = nil
        SetRangeCandidate(button, false)
        ApplyCachedButtonTint(button, settings, state)
        return false
    end

    local inRange = SafeIsActionInRange(action)
    if inRange == nil then
        -- nil means the action has no meaningful range for the current target.
        state.rangeOut = nil
        SetRangeCandidate(button, false)
        ApplyCachedButtonTint(button, settings, state)
        return false
    end

    state.rangeOut = (inRange == false)
    SetRangeCandidate(button, true)
    ApplyCachedButtonTint(button, settings, state)
    return true
end

function UpdateButtonUsability(button, settings, knownUsable, knownNoMana)
    if not settings then return end
    local state = GetFrameState(button)
    local action = GetSafeActionSlot(button)

    if state.fadeHidden or state.hiddenEmpty then
        SetRangeCandidate(button, false)
        return
    end

    if not action or not SafeHasAction(action) then
        SetRangeCandidate(button, false)
        ClearButtonTint(state)
        return
    end

    if not settings.rangeIndicator and not settings.usabilityIndicator then
        SetRangeCandidate(button, false)
        ClearButtonTint(state)
        return
    end

    -- Seed/update range candidacy on events (target/slot/page/etc.). Between
    -- those events the dedicated range ticker updates only these candidates.
    if settings.rangeIndicator then
        UpdateButtonRangeOnly(button, settings)
    else
        state.rangeOut = nil
        SetRangeCandidate(button, false)
    end

    if settings.usabilityIndicator then
        -- ACTION_USABLE_CHANGED carries Blizzard's authoritative conditional
        -- state. Prefer it when supplied. When a follow-up generic refresh can
        -- only obtain an unknown/secret result, preserve the last known tint
        -- instead of clearing it and exposing a lower-priority red range tint.
        local isUsable, notEnoughMana
        local eventUsable = Helpers.SafeValue(knownUsable, nil)
        local eventNoMana = Helpers.SafeValue(knownNoMana, nil)
        if type(eventUsable) == "boolean" and type(eventNoMana) == "boolean" then
            isUsable, notEnoughMana = eventUsable, eventNoMana
        else
            isUsable, notEnoughMana = SafeIsUsableAction(action)
        end
        if notEnoughMana == true then
            state.usabilityTint = "mana"
        elseif isUsable == false then
            state.usabilityTint = "unusable"
        elseif isUsable == true then
            state.usabilityTint = nil
        end
        -- nil/nil = unknown: keep the last authoritative state unchanged.
    else
        state.usabilityTint = nil
    end

    ApplyCachedButtonTint(button, settings, state)
end

local function IsUsabilityButtonActive(button)
    local active = ActionBarsOwned._activeStandardButtons
    if active and active[button] then return true end
    return not active or next(active) == nil
end

function UpdateAllButtonRange()
    local settings = GetGlobalSettings()
    if _abUsabilityStats then _abUsabilityStats.rangeScans = _abUsabilityStats.rangeScans + 1 end
    if not settings or not settings.rangeIndicator then return end
    local candidates = usabilityState.rangeCandidates
    if not candidates then return end

    for button in pairs(candidates) do
        local barKey = button._tomomodBarKey or GetBarKeyFromButton(button)
        local fadeState = ActionBarsOwned.fadeState and ActionBarsOwned.fadeState[barKey]
        if not IsUsabilityButtonActive(button)
            or (ActionBarsOwned.IsBarRuntimeVisible and not ActionBarsOwned.IsBarRuntimeVisible(barKey))
            or (fadeState and fadeState.currentAlpha <= 0)
            or (IsButtonInsideVisibleLayout and not IsButtonInsideVisibleLayout(button, barKey))
            or (button.IsVisible and not button:IsVisible()) then
            candidates[button] = nil
        else
            if _abUsabilityStats then _abUsabilityStats.rangeButtons = _abUsabilityStats.rangeButtons + 1 end
            UpdateButtonRangeOnly(button, settings)
        end
    end
end
ActionBarsOwned.UpdateAllButtonRange = UpdateAllButtonRange

-- TOMOMOD P1 PERF/12.1: Midnight exposes a C-side range subscription. Prefer
-- it over a Lua ticker: the client tracks only the action slots we opt into and
-- fires ACTION_RANGE_CHECK_UPDATE when their range state actually flips.
local function DisableNativeRangeChecks()
    local enabled = usabilityState.rangeSlots
    if not enabled then return end
    local fn = C_ActionBar and C_ActionBar.EnableActionRangeCheck
    if fn then
        for slot in pairs(enabled) do
            pcall(fn, slot, false)
        end
    end
    wipe(enabled)
    wipe(usabilityState.rangeSlotButtons)
    usabilityState.nativeRangeActive = false
end

local function SyncNativeRangeChecks(settings)
    local fn = C_ActionBar and C_ActionBar.EnableActionRangeCheck
    if not fn or not settings or not settings.rangeIndicator then
        DisableNativeRangeChecks()
        return false
    end

    local desired = {}
    local slotButtons = {}
    local active = ActionBarsOwned._activeStandardButtons
    local useActive = active and next(active) ~= nil

    local function Consider(button, barKey)
        if useActive and not active[button] then return end
        if ActionBarsOwned.IsBarRuntimeVisible and not ActionBarsOwned.IsBarRuntimeVisible(barKey) then return end
        local fadeState = ActionBarsOwned.fadeState and ActionBarsOwned.fadeState[barKey]
        if fadeState and fadeState.currentAlpha <= 0 then return end
        if IsButtonInsideVisibleLayout and not IsButtonInsideVisibleLayout(button, barKey) then return end
        if button.IsVisible and not button:IsVisible() then return end
        local slot = GetSafeActionSlot(button)
        if not slot or not SafeHasAction(slot) then return end
        desired[slot] = true
        local hosts = slotButtons[slot]
        if not hosts then hosts = {}; slotButtons[slot] = hosts end
        hosts[#hosts + 1] = button
    end

    if useActive then
        for button in pairs(active) do
            Consider(button, button._tomomodBarKey or GetBarKeyFromButton(button))
        end
    else
        for _, barKey in ipairs(STANDARD_BAR_KEYS) do
            for _, button in ipairs(GetBarButtons(barKey)) do
                Consider(button, barKey)
            end
        end
    end

    local enabled = usabilityState.rangeSlots
    for slot in pairs(enabled) do
        if not desired[slot] then
            pcall(fn, slot, false)
            enabled[slot] = nil
        end
    end
    for slot in pairs(desired) do
        if not enabled[slot] then
            pcall(fn, slot, true)
            enabled[slot] = true
        end
    end

    usabilityState.rangeSlotButtons = slotButtons
    usabilityState.nativeRangeActive = true
    return true
end

local function HandleNativeRangeUpdate(slot, inRange, checksRange)
    if not usabilityState.nativeRangeActive or not slot then return end
    if Helpers.IsSecretValue(inRange) or Helpers.IsSecretValue(checksRange) then return end
    local hosts = usabilityState.rangeSlotButtons and usabilityState.rangeSlotButtons[slot]
    if not hosts then return end
    if _abUsabilityStats then _abUsabilityStats.rangeEvents = _abUsabilityStats.rangeEvents + 1 end

    local outOfRange = (checksRange == true and inRange == false)
    if UnitExists and not UnitExists("target") then
        outOfRange = false
    end
    local settings = GetGlobalSettings()
    if not settings or not settings.rangeIndicator then return end
    for i = 1, #hosts do
        local button = hosts[i]
        local barKey = button and (button._tomomodBarKey or GetBarKeyFromButton(button))
        if button and (not ActionBarsOwned.IsBarRuntimeVisible or ActionBarsOwned.IsBarRuntimeVisible(barKey)) then
            local state = GetFrameState(button)
            state.rangeOut = outOfRange or nil
            ApplyCachedButtonTint(button, settings, state)
        end
    end
end

function UpdateAllButtonUsability()
    local globalSettings = GetGlobalSettings()
    if not globalSettings then return end
    if not globalSettings.rangeIndicator and not globalSettings.usabilityIndicator then return end

    local activeStandardButtons = ActionBarsOwned._activeStandardButtons
    if activeStandardButtons and next(activeStandardButtons) ~= nil then
        if _abUsabilityStats then _abUsabilityStats.activeScans = _abUsabilityStats.activeScans + 1 end
        for button in pairs(activeStandardButtons) do
            local barKey = button._tomomodBarKey or GetBarKeyFromButton(button)
            local fadeState = ActionBarsOwned.fadeState and ActionBarsOwned.fadeState[barKey]
            if (not ActionBarsOwned.IsBarRuntimeVisible or ActionBarsOwned.IsBarRuntimeVisible(barKey))
                and (not fadeState or fadeState.currentAlpha > 0)
                and (not IsButtonInsideVisibleLayout or IsButtonInsideVisibleLayout(button, barKey))
                and (not button.IsVisible or button:IsVisible()) then
                if _abUsabilityStats then _abUsabilityStats.buttons = _abUsabilityStats.buttons + 1 end
                UpdateButtonUsability(button, globalSettings)
            elseif IsButtonInsideVisibleLayout and not IsButtonInsideVisibleLayout(button, barKey) then
                ActionBarsOwned._activeButtons[button] = nil
                activeStandardButtons[button] = nil
                SetRangeCandidate(button, false)
            end
        end
        if usabilityState.nativeRangeActive then SyncNativeRangeChecks(globalSettings) end
        return
    end

    if _abUsabilityStats then _abUsabilityStats.fallbackScans = _abUsabilityStats.fallbackScans + 1 end
    for _, barKey in ipairs(STANDARD_BAR_KEYS) do
        local fadeState = ActionBarsOwned.fadeState and ActionBarsOwned.fadeState[barKey]
        if (not ActionBarsOwned.IsBarRuntimeVisible or ActionBarsOwned.IsBarRuntimeVisible(barKey))
            and (not fadeState or fadeState.currentAlpha > 0) then
            for _, button in ipairs(GetBarButtons(barKey)) do
                if (not IsButtonInsideVisibleLayout or IsButtonInsideVisibleLayout(button, barKey))
                    and (not button.IsVisible or button:IsVisible()) then
                    if _abUsabilityStats then _abUsabilityStats.buttons = _abUsabilityStats.buttons + 1 end
                    UpdateButtonUsability(button, globalSettings)
                end
            end
        end
    end
    if usabilityState.nativeRangeActive then SyncNativeRangeChecks(globalSettings) end
end

ActionBarsOwned.UpdateAllButtonUsability = UpdateAllButtonUsability

env.__declared.usabilityUpdateFrame = true
function GetUsabilityScheduleDelay()
    -- TOMOMOD P1 PERF: usability is event-driven now. Debounce event bursts,
    -- but never hold a mana/usability change behind the range polling cadence.
    return usabilityState.EVENT_DEBOUNCE
end

function UsabilityUpdateFrameOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + (elapsed or 0)
    if self.elapsed < (self.delay or usabilityState.EVENT_DEBOUNCE) then return end
    local nextDelay = GetUsabilityScheduleDelay()
    if nextDelay > usabilityState.EVENT_DEBOUNCE then
        self.elapsed = 0
        self.delay = nextDelay
        return
    end

    self.elapsed = 0
    self.delay = usabilityState.EVENT_DEBOUNCE
    usabilityState.updatePending = false
    self:Hide()
    UpdateAllButtonUsability()
end

function EnsureUsabilityUpdateFrame()
    if usabilityUpdateFrame then return usabilityUpdateFrame end

    usabilityUpdateFrame = CreateFrame("Frame")
    usabilityUpdateFrame.elapsed = 0
    usabilityUpdateFrame:Hide()
    usabilityUpdateFrame:SetScript("OnUpdate", UsabilityUpdateFrameOnUpdate)
    ActionBarsOwned._usabilityUpdateFrame = usabilityUpdateFrame
    return usabilityUpdateFrame
end

function UsabilityCheckFrameOnEvent(self, event, ...)
    if event == "ACTION_RANGE_CHECK_UPDATE" then
        HandleNativeRangeUpdate(...)
        return
    elseif event == "PLAYER_REGEN_DISABLED" then
        usabilityState.inCombat = true
        self.elapsed = 0
        return
    elseif event == "PLAYER_REGEN_ENABLED" then
        usabilityState.inCombat = false
        ScheduleUsabilityUpdate()
        return
    end
    ScheduleUsabilityUpdate()
end

function UsabilityCheckFrameOnUpdate(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    local interval = usabilityState.inCombat and usabilityState.RANGE_INTERVAL_COMBAT or usabilityState.RANGE_INTERVAL_IDLE
    if self.elapsed < interval then return end
    self.elapsed = 0
    UpdateAllButtonRange()
end

ScheduleUsabilityUpdate = function()
    if usabilityState.updatePending then return end
    usabilityState.updatePending = true
    local frame = EnsureUsabilityUpdateFrame()
    frame.elapsed = 0
    frame.delay = GetUsabilityScheduleDelay()
    frame:Show()
end
ActionBarsOwned.ScheduleUsabilityUpdate = ScheduleUsabilityUpdate

function ResetAllButtonTints()
    for _, barKey in ipairs(STANDARD_BAR_KEYS) do
        local buttons = GetBarButtons(barKey)
        for _, button in ipairs(buttons) do
            local state = GetFrameState(button)
            ClearButtonTint(state)
        end
    end
end

function UpdateUsabilityPolling()
    local settings = GetGlobalSettings()
    local usabilityEnabled = settings and settings.usabilityIndicator
    local rangeEnabled = settings and settings.rangeIndicator

    if not usabilityState.checkFrame then
        usabilityState.checkFrame = CreateFrame("Frame")
        usabilityState.checkFrame.elapsed = 0
    end

    local checkFrame = usabilityState.checkFrame

    if usabilityEnabled or rangeEnabled then
        checkFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
        checkFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
        checkFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        checkFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        checkFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        checkFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        checkFrame:RegisterEvent("ZONE_CHANGED_INDOORS")

        checkFrame:SetScript("OnEvent", UsabilityCheckFrameOnEvent)

        ScheduleUsabilityUpdate()
    else
        checkFrame:UnregisterAllEvents()
        checkFrame:SetScript("OnEvent", nil)
        DisableNativeRangeChecks()
    end

    if rangeEnabled and C_ActionBar and C_ActionBar.EnableActionRangeCheck then
        -- 12.1 native path: zero permanent Lua polling.
        usabilityState.rangePollingActive = false
        usabilityState.nativeRangeActive = true
        checkFrame:SetScript("OnUpdate", nil)
        checkFrame.elapsed = 0
        checkFrame:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")
        checkFrame:Hide()
        SyncNativeRangeChecks(settings)
    elseif rangeEnabled then
        -- Compatibility fallback for clients without native range subscriptions.
        usabilityState.nativeRangeActive = false
        usabilityState.rangePollingActive = true
        checkFrame:SetScript("OnUpdate", UsabilityCheckFrameOnUpdate)
        if usabilityState.rangeCandidates and next(usabilityState.rangeCandidates) ~= nil then
            checkFrame:Show()
        else
            checkFrame:Hide()
        end
    else
        DisableNativeRangeChecks()
        usabilityState.rangePollingActive = false
        checkFrame:UnregisterEvent("ACTION_RANGE_CHECK_UPDATE")
        checkFrame:SetScript("OnUpdate", nil)
        checkFrame.elapsed = 0
        if usabilityState.rangeCandidates then wipe(usabilityState.rangeCandidates) end
        if not usabilityEnabled then
            checkFrame:Hide()
            ResetAllButtonTints()
        else
            -- Re-evaluate once so a former red range tint immediately falls
            -- back to mana/unusable (or clears) when the option is disabled.
            ScheduleUsabilityUpdate()
        end
    end
end

ActionBarsOwned.UpdateUsabilityPolling = UpdateUsabilityPolling

end

function DetectBarColumns(buttons)
    if #buttons < 2 then return #buttons end

    local firstTop = buttons[1]:GetTop()
    if not firstTop then return #buttons end

    local buttonHeight = buttons[1]:GetHeight() or 30
    local threshold = buttonHeight * 0.3
    local numCols = 1

    for i = 2, #buttons do
        local top = buttons[i]:GetTop()
        if not top or math.abs(top - firstTop) > threshold then
            break
        end
        numCols = numCols + 1
    end

    return numCols
end

function GetBarGridLayout(barFrame, buttons)
    local isVertical = false
    local numCols, numRows

    local EditModeSettings = Enum.EditModeActionBarSetting
    if barFrame.GetSettingValue and EditModeSettings then
        local okO, orientation = pcall(barFrame.GetSettingValue, barFrame, EditModeSettings.Orientation)
        local okR, editNumRows = pcall(barFrame.GetSettingValue, barFrame, EditModeSettings.NumRows)

        if okO and okR and editNumRows and editNumRows > 0 then
            isVertical = (orientation == 1)
            if isVertical then
                numCols = editNumRows
                numRows = math.ceil(#buttons / numCols)
            else
                numRows = editNumRows
                numCols = math.ceil(#buttons / numRows)
            end
        end
    end

    if not numCols then
        numCols = DetectBarColumns(buttons)
        numRows = math.ceil(#buttons / numCols)
    end

    return numCols, numRows, isVertical
end

function ApplyButtonSpacing(barKey)
    if InCombatLockdown() and not inInitSafeWindow then
        ActionBarsOwned.pendingSpacing = true
        return
    end

    local settings = GetGlobalSettings()
    if not settings or settings.buttonSpacing == nil then return end

    local spacing = settings.buttonSpacing
    if barKey == "pet" or barKey == "stance" then return end
    local ownedLayout = ActionBarsOwned.containers and ActionBarsOwned.containers[barKey]
    if ownedLayout then return end

    local allButtons = GetBarButtons(barKey)
    if #allButtons < 2 then return end

    local barFrame = GetBarFrame(barKey)
    if not barFrame then return end

    do
        local needsSort = false
        for _, btn in ipairs(allButtons) do
            local container = btn:GetParent()
            if container and container.layoutIndex then
                needsSort = true
                break
            end
        end
        if needsSort then
            local sorted = {}
            for i, btn in ipairs(allButtons) do
                sorted[i] = btn
            end
            table.sort(sorted, function(a, b)
                local indexA = a:GetParent() and a:GetParent().layoutIndex
                local indexB = b:GetParent() and b:GetParent().layoutIndex
                if indexA and indexB and indexA ~= indexB then
                    return indexA < indexB
                end
                local numA = tonumber(a:GetName():match("%d+$")) or 0
                local numB = tonumber(b:GetName():match("%d+$")) or 0
                return numA < numB
            end)
            allButtons = sorted
        end
    end

    local buttons = allButtons
    local editModeNumIcons = nil
    local EditModeSettings = Enum.EditModeActionBarSetting
    if barFrame.GetSettingValue and EditModeSettings then
        local okN, numIcons = pcall(barFrame.GetSettingValue, barFrame, EditModeSettings.NumIcons)
        if okN and numIcons and numIcons > 0 then
            editModeNumIcons = numIcons
            if numIcons < #allButtons then
                local visible = {}
                for i = 1, numIcons do
                    visible[i] = allButtons[i]
                end
                buttons = visible
            end
        end
    end

    if not editModeNumIcons and #buttons == #allButtons then
        local shown = {}
        for _, btn in ipairs(allButtons) do
            if btn:IsShown() then
                shown[#shown + 1] = btn
            end
        end
        if #shown > 0 and #shown < #buttons then
            buttons = shown
        end
    end

    if #buttons < 2 then return end

    local numCols, numRows, isVertical = GetBarGridLayout(barFrame, buttons)

    local addToTop = barFrame.addButtonsToTop
    local addToRight = barFrame.addButtonsToRight

    local containerEffScale = buttons[1]:GetParent():GetEffectiveScale()
    local barEffScale = barFrame:GetEffectiveScale()
    if not containerEffScale or containerEffScale <= 0 or not barEffScale or barEffScale <= 0 then return end

    local btnWidth = buttons[1]:GetWidth()
    local btnHeight = buttons[1]:GetHeight()
    local groupWidth = numCols * btnWidth + math.max(0, numCols - 1) * spacing
    local groupHeight = numRows * btnHeight + math.max(0, numRows - 1) * spacing

    barFrame:SetSize(
        groupWidth * containerEffScale / barEffScale,
        groupHeight * containerEffScale / barEffScale
    )

    local container1 = buttons[1]:GetParent()
    container1:ClearAllPoints()
    container1:SetSize(btnWidth, btnHeight)

    if isVertical then
        local buttonsPerCol = numRows
        if addToRight == false then
            container1:SetPoint("TOPRIGHT", barFrame, "TOPRIGHT", 0, 0)
        else
            container1:SetPoint("TOPLEFT", barFrame, "TOPLEFT", 0, 0)
        end

        for i = 2, #buttons do
            local container = buttons[i]:GetParent()
            local rowInCol = (i - 1) % buttonsPerCol

            container:ClearAllPoints()
            if rowInCol == 0 then
                local prevColStart = i - buttonsPerCol
                if addToRight == false then
                    container:SetPoint("TOPRIGHT", buttons[prevColStart]:GetParent(), "TOPLEFT", -spacing, 0)
                else
                    container:SetPoint("TOPLEFT", buttons[prevColStart]:GetParent(), "TOPRIGHT", spacing, 0)
                end
            else
                container:SetPoint("TOPLEFT", buttons[i - 1]:GetParent(), "BOTTOMLEFT", 0, -spacing)
            end
            container:SetSize(btnWidth, btnHeight)
        end
    else
        if addToTop then
            container1:SetPoint("BOTTOMLEFT", barFrame, "BOTTOMLEFT", 0, 0)
        else
            container1:SetPoint("TOPLEFT", barFrame, "TOPLEFT", 0, 0)
        end

        for i = 2, #buttons do
            local container = buttons[i]:GetParent()
            local colIndex = ((i - 1) % numCols) + 1

            container:ClearAllPoints()
            if colIndex == 1 then
                local prevRowStart = buttons[i - numCols]:GetParent()
                if addToTop then
                    container:SetPoint("BOTTOMLEFT", prevRowStart, "TOPLEFT", 0, spacing)
                else
                    container:SetPoint("TOPLEFT", prevRowStart, "BOTTOMLEFT", 0, -spacing)
                end
            else
                local prevContainer = buttons[i - 1]:GetParent()
                container:SetPoint("LEFT", prevContainer, "RIGHT", spacing, 0)
            end
            container:SetSize(btnWidth, btnHeight)
        end
    end

    for i = 1, #buttons do
        buttons[i]:ClearAllPoints()
        buttons[i]:SetAllPoints(buttons[i]:GetParent())
    end
end

ApplyAllBarSpacing = function()
    if InCombatLockdown() and not inInitSafeWindow then
        ActionBarsOwned.pendingSpacing = true
        return
    end

    for barKey, _ in pairs(BUTTON_PATTERNS) do
        ApplyButtonSpacing(barKey)
    end
end

ComputeAutoFlyoutDirection = function(btn, isVertical)
    local rawX, rawY = btn:GetCenter()
    local cx = Helpers.SafeNumberOrNil(rawX)
    local cy = Helpers.SafeNumberOrNil(rawY)
    if isVertical then
        if cx then return cx > (GetScreenWidth() / 2) and "LEFT" or "RIGHT" end
        return "RIGHT"
    end
    if cy then return cy < (GetScreenHeight() / 2) and "UP" or "DOWN" end
    return "UP"
end

VALID_FLYOUT_DIRS = { UP = true, DOWN = true, LEFT = true, RIGHT = true }

ApplyFlyoutDirection = function(barKey)
    local buttons = ActionBarsOwned.nativeButtons and ActionBarsOwned.nativeButtons[barKey]
    if not buttons or #buttons == 0 then return end

    local db = GetDB()
    local barDB = db and db.bars and db.bars[barKey]
    local layout = barDB and barDB.ownedLayout
    if not layout then return end

    if InCombatLockdown() then
        ActionBarsOwned.pendingFlyoutDirection = true
        return
    end

    if HideOwnedFlyout then
        HideOwnedFlyout()
    end

    local dir = layout.flyoutDirection
    if not VALID_FLYOUT_DIRS[dir] then dir = nil end
    local isVertical = (GetOwnedLayout(barKey)) == "vertical"

    for _, btn in ipairs(buttons) do
        if btn and btn.SetAttribute then
            local effectiveDir = dir or ComputeAutoFlyoutDirection(btn, isVertical)
            btn:SetAttribute("flyoutDirection", effectiveDir)
            if btn.SetPopupDirection then btn:SetPopupDirection(effectiveDir) end
            ns.SafeCallMethodIfPresent("best-effort-style", btn, "UpdateFlyout")
        end
    end
end

ApplyAllFlyoutDirections = function()
    for _, barKey in ipairs(STANDARD_BAR_KEYS) do
        ApplyFlyoutDirection(barKey)
    end
end

ActionBarsOwned.SuppressButtonProcVisuals = SuppressButtonProcVisuals
ActionBarsOwned.DRAG_PREVIEW_ALPHA = DRAG_PREVIEW_ALPHA

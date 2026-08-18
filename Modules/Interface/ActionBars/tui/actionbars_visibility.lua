-- =====================================================================
-- TomoMod secure visibility engine for owned ActionBars.
-- Midnight 12.1: structural visibility is driven by SecureStateDriver.
-- =====================================================================
local ADDON_NAME, ns = "TomoMod", TomoMod_TuiNS
local env = ns.ActionBarsEnv
env.ADDON_NAME = ADDON_NAME
env.ns = ns
env.SetChunkEnv(1, env)

---@diagnostic disable: lowercase-global -- SetChunkEnv installs a setfenv

local SECURE_VISIBILITY_BAR_KEYS = {
    bar1 = true, bar2 = true, bar3 = true, bar4 = true,
    bar5 = true, bar6 = true, bar7 = true, bar8 = true,
    pet = true, stance = true,
}

local VISIBILITY_MODE_DRIVERS = {
    always   = "show",
    combat   = "[combat] show; hide",
    nocombat = "[nocombat] show; hide",
    solo     = "[nogroup] show; hide",
    party    = "[group:party,nogroup:raid] show; hide",
    raid     = "[group:raid] show; hide",
    instance = "[instance:party][instance:raid][instance:pvp][instance:arena][instance:scenario] show; hide",
    mounted  = "[mounted] show; hide",
    target   = "[@target,exists] show; hide",
    hostile  = "[@target,harm,nodead] show; hide",
    hidden   = "hide",
}

local visibilityPending = {}
local pendingUserShown = setmetatable({}, { __mode = "k" })
local visibilityEventFrame = CreateFrame("Frame")

local function IsSecureVisibilityBar(barKey)
    return SECURE_VISIBILITY_BAR_KEYS[barKey] == true
end

local function Trim(value)
    if type(value) ~= "string" then return "" end
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function SanitizeCustomCondition(value)
    value = Trim(value)
    if value == "" or #value > 200 then return nil end
    if value:find(";", 1, true) or value:find("\n", 1, true) or value:find("\r", 1, true) then
        return nil
    end
    if not value:match("^%[") or not value:match("%]$") then return nil end
    if value:find("[^%[%]@%w%s_:,!/%-%.]") then return nil end

    local depth = 0
    for i = 1, #value do
        local c = value:sub(i, i)
        if c == "[" then
            depth = depth + 1
            if depth > 1 then return nil end
        elseif c == "]" then
            depth = depth - 1
            if depth < 0 then return nil end
        end
    end
    if depth ~= 0 then return nil end
    return value
end

local function GetVisibilityMode(barKey)
    local settings = GetEffectiveSettings(barKey)
    local mode = settings and settings.visibilityMode or "always"
    if mode == "custom" then return mode, settings end
    if not VISIBILITY_MODE_DRIVERS[mode] then mode = "always" end
    return mode, settings
end

function BuildBarVisibilityDriver(barKey)
    if not IsSecureVisibilityBar(barKey) then return nil end

    local hardHide = "[overridebar][vehicleui][possessbar][petbattle] hide; "
    if barKey == "pet" then
        hardHide = "[overridebar][vehicleui][possessbar][petbattle][nopet] hide; "
    end

    local mode, settings = GetVisibilityMode(barKey)
    if mode == "custom" then
        local custom = SanitizeCustomCondition(settings and settings.visibilityCustom)
        if custom then
            ActionBarsOwned.visibilityErrors[barKey] = nil
            return hardHide .. custom .. " show; hide"
        end
        ActionBarsOwned.visibilityErrors[barKey] = "invalid-custom-condition"
        return hardHide .. "show"
    end

    ActionBarsOwned.visibilityErrors[barKey] = nil
    return hardHide .. VISIBILITY_MODE_DRIVERS[mode]
end

local function SyncContainerShownState(container)
    if not container or InCombatLockdown() then return end
    local userShown = container:GetAttribute("qui-user-shown")
    local state = container:GetAttribute("state-tuivis")
    if userShown and state ~= "hide" then
        container:Show()
    else
        if ActionBarsOwned.HideOwnedFlyout then
            ActionBarsOwned.HideOwnedFlyout()
        end
        container:Hide()
    end
end

local function ApplyDriverToContainer(container, barKey)
    if not container or not IsSecureVisibilityBar(barKey) then return end
    if InCombatLockdown() then
        visibilityPending[barKey] = true
        visibilityEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    local driver = BuildBarVisibilityDriver(barKey)
    if not driver then return end

    local state = GetFrameState(container)
    if state.visibilityDriver ~= driver then
        UnregisterStateDriver(container, "tuivis")
        local ok, err = pcall(RegisterStateDriver, container, "tuivis", driver)
        if ok then
            state.visibilityDriver = driver
            state.visibilityRegisterError = nil
        else
            state.visibilityRegisterError = tostring(err)
            local fallback = "[overridebar][vehicleui][possessbar][petbattle] hide; show"
            if barKey == "pet" then
                fallback = "[overridebar][vehicleui][possessbar][petbattle][nopet] hide; show"
            end
            pcall(RegisterStateDriver, container, "tuivis", fallback)
        end
    end
    SyncContainerShownState(container)
end

local function IsBarRuntimeVisible(barKey)
    if not barKey then return true end
    local container = ActionBarsOwned.containers and ActionBarsOwned.containers[barKey]
    if not container then return true end
    if container.GetAttribute and container:GetAttribute("qui-user-shown") == false then
        return false
    end
    if container.IsShown then
        return container:IsShown() == true
    end
    return true
end

local function WakeDormantBar(barKey)
    if not IsBarRuntimeVisible(barKey) then return end

    -- P3.1: a visibility-hidden bar does no continuous visual work. Re-arm its
    -- presentation once when the secure driver makes it visible again so no
    -- cooldown, glow, count, or usability state can be stale. These are all
    -- TUI-owned visual refresh paths; bindings/secure action dispatch never
    -- participate in dormancy.
    if ScheduleABVisualUpdate then ScheduleABVisualUpdate(true, true) end
    if ScheduleABCooldownUpdate then ScheduleABCooldownUpdate(true) end
    if ScheduleABStateUpdate then ScheduleABStateUpdate(true) end
    if ScheduleABCountUpdate then ScheduleABCountUpdate() end
    if ScheduleUsabilityUpdate then ScheduleUsabilityUpdate() end
    if MarkSpellIdMapDirty then MarkSpellIdMapDirty() end

    if barKey == "pet" and ActionBarsOwned.UpdateAllPetButtons then
        ActionBarsOwned.UpdateAllPetButtons()
    elseif barKey == "stance" and ActionBarsOwned.UpdateAllStanceButtons then
        ActionBarsOwned.UpdateAllStanceButtons()
    end

    if ActionBarsOwned.UpdateAllOverlayGlows then
        ActionBarsOwned.UpdateAllOverlayGlows()
    end
end

local function InstallDormancyHooks(container, barKey)
    local state = GetFrameState(container)
    if state.visibilityDormancyHooks then return end
    state.visibilityDormancyHooks = true

    container:HookScript("OnShow", function()
        WakeDormantBar(barKey)
    end)
    container:HookScript("OnHide", function()
        -- Drop native range subscriptions promptly when a visibility rule
        -- hides the bar. The deferred usability pass is visual-only and safe
        -- in combat; the secure buttons/bindings themselves stay untouched.
        if ScheduleUsabilityUpdate then ScheduleUsabilityUpdate() end
        if ActionBarsOwned.HideOwnedFlyout then ActionBarsOwned.HideOwnedFlyout() end
    end)
end

function InstallBarVisibilityDriver(container, barKey)
    if not container or not IsSecureVisibilityBar(barKey) then return end
    InstallDormancyHooks(container, barKey)
    container:SetAttribute("qui-bar-key", barKey)
    container:SetAttribute("_onstate-tuivis", [[
        if newstate == "show" and self:GetAttribute("qui-user-shown") then
            self:Show()
        else
            self:Hide()
        end
    ]])

    local settings = GetEffectiveSettings(barKey)
    container:SetAttribute("qui-user-shown", not settings or settings.enabled ~= false)
    ApplyDriverToContainer(container, barKey)
end

function SetSecureBarUserShown(container, shown)
    if not container then return end
    if InCombatLockdown() then
        pendingUserShown[container] = shown and true or false
        visibilityEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    container:SetAttribute("qui-user-shown", shown and true or false)
    SyncContainerShownState(container)
end

function RefreshSecureBarVisibility(barKey)
    if InvalidateEffectiveSettingsCache then
        InvalidateEffectiveSettingsCache(barKey)
    end
    if barKey and IsSecureVisibilityBar(barKey) then
        local container = ActionBarsOwned.containers and ActionBarsOwned.containers[barKey]
        if container then ApplyDriverToContainer(container, barKey) end
        return
    end
    for key in pairs(SECURE_VISIBILITY_BAR_KEYS) do
        local container = ActionBarsOwned.containers and ActionBarsOwned.containers[key]
        if container then ApplyDriverToContainer(container, key) end
    end
end

visibilityEventFrame:SetScript("OnEvent", function(self, event)
    if event ~= "PLAYER_REGEN_ENABLED" then return end

    for container, shown in pairs(pendingUserShown) do
        pendingUserShown[container] = nil
        if container then
            container:SetAttribute("qui-user-shown", shown and true or false)
            SyncContainerShownState(container)
        end
    end

    for barKey in pairs(visibilityPending) do
        visibilityPending[barKey] = nil
        local container = ActionBarsOwned.containers and ActionBarsOwned.containers[barKey]
        if container then ApplyDriverToContainer(container, barKey) end
    end

    if not next(visibilityPending) and not next(pendingUserShown) then
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end)

ActionBarsOwned.visibilityErrors = ActionBarsOwned.visibilityErrors or {}
ActionBarsOwned.RefreshVisibility = RefreshSecureBarVisibility
ActionBarsOwned.IsSecureVisibilityBar = IsSecureVisibilityBar
ActionBarsOwned.IsBarRuntimeVisible = IsBarRuntimeVisible
ActionBarsOwned.WakeDormantBar = WakeDormantBar

_G.TUI_RefreshActionBarsVisibility = function(barKey)
    RefreshSecureBarVisibility(barKey)
end

-- =====================================================================
-- TomoMod secure Action Bar 1 paging engine.
-- Midnight 12.1: page selection is resolved by a SecureStateDriver so
-- modifier/target/form/skyriding/manual transitions remain combat-safe.
-- =====================================================================
local ADDON_NAME, ns = "TomoMod", TomoMod_TuiNS
local env = ns.ActionBarsEnv
env.ADDON_NAME = ADDON_NAME
env.ns = ns
env.SetChunkEnv(1, env)

---@diagnostic disable: lowercase-global -- SetChunkEnv installs a setfenv

local pagingPending = false
local pagingEventFrame = CreateFrame("Frame")

local PAGE_BY_BAR = {
    bar1 = 1,
    bar2 = 6,
    bar3 = 5,
    bar4 = 3,
    bar5 = 4,
    bar6 = 13,
    bar7 = 14,
    bar8 = 15,
}

local function NormalizeConfiguredPage(value)
    value = tonumber(value)
    if not value or value <= 0 then return nil end
    for _, page in pairs(PAGE_BY_BAR) do
        if value == page then return page end
    end
    return nil
end

local function GetBar1PagingSettings()
    local settings = GetEffectiveSettings and GetEffectiveSettings("bar1")
    local paging = settings and settings.paging
    if type(paging) ~= "table" then paging = nil end
    return settings, paging
end

function BuildPagingCondition()
    local settings, paging = GetBar1PagingSettings()
    local parts = {}

    -- Hard replacements always win. Keep the existing secure-side resolver so
    -- vehicle/override/temp-shapeshift indices come from Blizzard at runtime.
    table.insert(parts, "[overridebar] override")
    table.insert(parts, "[vehicleui][possessbar][shapeshift] possess")

    -- Explicit modifier pages are user intent and therefore outrank the normal
    -- action-bar page, forms, skyriding, and target-based paging.
    if paging then
        local alt = NormalizeConfiguredPage(paging.alt)
        local shift = NormalizeConfiguredPage(paging.shift)
        local ctrl = NormalizeConfiguredPage(paging.ctrl)
        if alt then table.insert(parts, "[mod:alt] " .. alt) end
        if shift then table.insert(parts, "[mod:shift] " .. shift) end
        if ctrl then table.insert(parts, "[mod:ctrl] " .. ctrl) end
    end

    -- Blizzard only consults the bonus bar while the manual action page is 1.
    -- Mirror that resolution order so /changeactionbar and the built-in page
    -- bindings still work while mounted or after a form transition.
    for i = 6, 2, -1 do
        table.insert(parts, "[bar:" .. i .. "] " .. i)
    end

    if not (settings and settings.disableFormPaging) then
        for i = 4, 1, -1 do
            table.insert(parts, "[bonusbar:" .. i .. "] " .. (6 + i))
        end
    end

    if not (settings and settings.disableSkyridingPaging) then
        table.insert(parts, "[bonusbar:5] 11")
    end

    -- Target paging is intentionally lower priority than manual/form/skyriding
    -- pages. A target change should never steal a vehicle/form/manual page.
    if paging then
        local help = NormalizeConfiguredPage(paging.help)
        local harm = NormalizeConfiguredPage(paging.harm)
        if help then table.insert(parts, "[help] " .. help) end
        if harm then table.insert(parts, "[harm] " .. harm) end
    end

    table.insert(parts, "1")
    return table.concat(parts, "; ")
end

local function InstallPagingSnippet(container)
    if not container or container._tomomodPagingSnippetInstalled then return end
    container._tomomodPagingSnippetInstalled = true
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
end

local function ApplyBar1Paging(container)
    container = container or (ActionBarsOwned.containers and ActionBarsOwned.containers.bar1)
    if not container then return end

    InstallPagingSnippet(container)

    if InCombatLockdown() then
        pagingPending = true
        pagingEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    local driver = BuildPagingCondition()
    local state = GetFrameState(container)
    if state.pagingDriver == driver then return end

    UnregisterStateDriver(container, "page")
    local ok, err = pcall(RegisterStateDriver, container, "page", driver)
    if ok then
        state.pagingDriver = driver
        state.pagingRegisterError = nil
    else
        state.pagingRegisterError = tostring(err)
        pcall(RegisterStateDriver, container, "page", "[overridebar] override; [vehicleui][possessbar][shapeshift] possess; [bar:6] 6; [bar:5] 5; [bar:4] 4; [bar:3] 3; [bar:2] 2; [bonusbar:4] 10; [bonusbar:3] 9; [bonusbar:2] 8; [bonusbar:1] 7; [bonusbar:5] 11; 1")
    end

    -- Reconcile visual caches after a driver rebuild. The actual page switch
    -- remains fully secure; these are only TUI-owned presentation refreshes.
    if ScheduleABVisualUpdate then ScheduleABVisualUpdate(true, true) end
    if ScheduleABCooldownUpdate then ScheduleABCooldownUpdate(true) end
    if ScheduleUsabilityUpdate then ScheduleUsabilityUpdate() end
    if MarkSpellIdMapDirty then MarkSpellIdMapDirty() end
    if ActionBarsOwned.UpdateAllOverlayGlows then ActionBarsOwned.UpdateAllOverlayGlows() end
end

function SetupBar1Paging(container)
    ApplyBar1Paging(container)
end

function RefreshBar1Paging()
    if InvalidateEffectiveSettingsCache then InvalidateEffectiveSettingsCache("bar1") end
    ApplyBar1Paging()
end

pagingEventFrame:SetScript("OnEvent", function(self, event)
    if event ~= "PLAYER_REGEN_ENABLED" then return end
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    if not pagingPending then return end
    pagingPending = false
    RefreshBar1Paging()
end)

ActionBarsOwned.PAGE_BY_BAR = PAGE_BY_BAR
ActionBarsOwned.BuildPagingCondition = BuildPagingCondition
ActionBarsOwned.RefreshPaging = RefreshBar1Paging

_G.TUI_RefreshActionBarsPaging = RefreshBar1Paging

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

    -- TOMOMOD 3.6.1: form and skyriding pages MUST be tested before [bar:N].
    --
    -- The first SecurePaging revision put [bar:6]..[bar:2] first, reasoning that
    -- Blizzard only consults the bonus bar while the manual action page is 1.
    -- In practice that broke druid form transitions: as soon as anything leaves
    -- the manual page at a value other than 1 -- a page binding, /changeactionbar,
    -- an addon, or Blizzard's own controller during a form swap -- the [bar:N]
    -- clause wins and the [bonusbar:N] form page is never reached, so Cat/Bear
    -- keep showing the caster page.
    --
    -- Bonusbar-before-bar is also what every other bar addon ships and what the
    -- pre-SecurePaging TomoMod condition used, i.e. the ordering that was known
    -- to work in the field. Do not reorder these two blocks again without an
    -- in-game druid test.
    if not (settings and settings.disableSkyridingPaging) then
        table.insert(parts, "[bonusbar:5] 11")
    end

    if not (settings and settings.disableFormPaging) then
        for i = 4, 1, -1 do
            table.insert(parts, "[bonusbar:" .. i .. "] " .. (6 + i))
        end
    end

    for i = 6, 2, -1 do
        table.insert(parts, "[bar:" .. i .. "] " .. i)
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

-- TOMOMOD 3.6.1: writing _onstate-page is SetAttribute on a protected frame, so
-- it is only legal out of combat. The caller checks the lockdown first; the
-- installed flag is set only after the write actually happened, otherwise a
-- single in-combat call would latch the flag and the bar would never get a
-- paging snippet for the rest of the session.
local function InstallPagingSnippet(container)
    if not container or container._tomomodPagingSnippetInstalled then return end
    if InCombatLockdown() then return end
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
    container._tomomodPagingSnippetInstalled = true
end

local function ApplyBar1Paging(container)
    container = container or (ActionBarsOwned.containers and ActionBarsOwned.containers.bar1)
    if not container then return end

    if InCombatLockdown() then
        pagingPending = true
        pagingEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    InstallPagingSnippet(container)

    local driver = BuildPagingCondition()
    local state = GetFrameState(container)
    -- The cached-driver shortcut is only valid once a driver has actually been
    -- registered on this container. Checking the string alone would skip the
    -- very first registration after a build that was deferred out of combat.
    if state.pagingInstalled and state.pagingDriver == driver then return end

    UnregisterStateDriver(container, "page")
    local ok, err = pcall(RegisterStateDriver, container, "page", driver)
    if ok then
        state.pagingDriver = driver
        state.pagingInstalled = true
        state.pagingRegisterError = nil
    else
        state.pagingRegisterError = tostring(err)
        -- Same ordering rule as BuildPagingCondition: forms first, [bar:N] last.
        local fallbackOk = pcall(RegisterStateDriver, container, "page",
            "[overridebar] override; [vehicleui][possessbar][shapeshift] possess; "
            .. "[bonusbar:5] 11; [bonusbar:4] 10; [bonusbar:3] 9; [bonusbar:2] 8; [bonusbar:1] 7; "
            .. "[bar:6] 6; [bar:5] 5; [bar:4] 4; [bar:3] 3; [bar:2] 2; 1")
        state.pagingDriver = nil
        state.pagingInstalled = fallbackOk and true or nil
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

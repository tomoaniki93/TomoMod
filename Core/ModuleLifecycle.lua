-- =====================================================================
-- ModuleLifecycle.lua — Turning modules on and off at runtime (v4 Lot 1)
-- ---------------------------------------------------------------------
-- What this fixes.
--
-- Disabling a module meant setting a flag and reloading. Not because
-- the modules could not do better: 28 of them already ship a
-- SetEnabled(), three ship an Enable()/Disable() pair, and six of the
-- skins already read the flag inside their hooks so a change takes
-- effect on the next call. That work existed and was never wired to
-- anything. Nothing centralised it, so the config UI fell back to the
-- one thing that always works -- a reload prompt.
--
-- This engine is the wiring. Core/ModuleManifest.lua declares, per
-- module, which global implements it and which method brings it to the
-- state the flag now describes. Nothing is inferred: a method is called
-- only where a manifest names it, because the same name means different
-- things in different files. Toggle() writes the flag in most modules
-- but shows or hides a window in Loots, and SetEnabled() does the full
-- job in AutoSummon while writing nothing but the flag in TooltipSkin.
-- Guessing from a name would silently do the wrong thing in a handful
-- of modules and there would be no way to see it from the outside.
--
-- Apply modes
-- -----------
-- The flag is always written by the registry. An apply mode only says
-- how the module is then told to realise it:
--
--   setter   impl.<apply>(value)
--   gate     impl.<apply>()      -- re-reads the flag itself
--   pair     impl.Enable() / impl.Disable()
--   nil      no live path; the caller is told a reload is needed
--
-- Combat
-- ------
-- Anything that respawns frames is deferred to PLAYER_REGEN_ENABLED,
-- because a protected frame touched in combat taints the rest of the
-- session. Modules that only register or unregister events are marked
-- combatSafe in the manifest and go through immediately -- making a
-- player leave combat to turn off fast loot would be theatre.
-- =====================================================================

TomoMod_Lifecycle = TomoMod_Lifecycle or {}
local LC = TomoMod_Lifecycle

local R = TomoMod_Registry

-- ---------------------------------------------------------------------
-- STATE
-- ---------------------------------------------------------------------

local resolved  = false
local pending   = {}    -- key -> desired boolean, replayed after combat
local pendingN  = 0
local combatFrame

-- Reload bookkeeping. A module with no live path still moves its flag,
-- so the stored choice is already correct; what is missing is the frame
-- work that only a reload performs. These hold what is waiting.
local reloadPending  = {}
local reloadN        = 0
local promptArmed    = false
local promptSuppress = false

-- What each module's flag read at login. A change is only worth a reload
-- while it differs from that: unticking a box and reticking it before
-- reloading leaves the session exactly as it started, and prompting then
-- would be asking the player to pay for nothing.
local bootState = {}

-- Callbacks fired whenever the pending set changes, so the banner can
-- redraw without polling.
local watchers = {}

-- Forward declaration. The combat watcher is installed above the reload
-- section but has to release a prompt that was withheld during a fight,
-- so the name has to exist in scope before it is assigned.
local ArmPrompt

-- Reported rather than printed, so the GUI can show them in place and
-- the slash command can print them. Cleared at the start of every call.
local lastReport

-- ---------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------

local function Impl(m)
    if not m or not m.global then return nil end
    return m.impl or _G[m.global]
end

--- Calls a module method with the error isolated. One module blowing up
--- while a profile is applied must not take the other sixty with it:
--- Init.lua already learned that lesson for Initialize(), and the same
--- reasoning applies here with more force, because this runs on a
--- player action rather than once at login.
local function SafeCall(m, method, ...)
    local impl = Impl(m)
    if not impl then return false, "no implementation" end
    local fn = impl[method]
    if type(fn) ~= "function" then return false, "no method " .. tostring(method) end

    local args = { ... }
    local ok, err = xpcall(function() return fn(unpack(args)) end, function(msg)
        return tostring(msg) .. "\n" .. debugstack(2)
    end)
    if not ok then
        local handler = geterrorhandler and geterrorhandler()
        if handler then
            handler("TomoMod " .. m.key .. "." .. tostring(method) .. ": " .. tostring(err))
        end
        return false, err
    end
    return true
end

-- ---------------------------------------------------------------------
-- RESOLVE
-- ---------------------------------------------------------------------
-- Binds each manifest to the global that implements it. Run once at
-- login, after every module file has had its chance to create its
-- table. A manifest whose global is missing is not an error: the module
-- may be part of a sub-addon that is not loaded, or shipped
-- standalone. It simply has no live path.
-- ---------------------------------------------------------------------

function LC.Resolve()
    local bound, missing = 0, 0
    for _, m in ipairs(R.ListAll()) do
        if m.global then
            local impl = _G[m.global]
            if type(impl) == "table" then
                R.Bind(m.key, impl)
                bound = bound + 1
            else
                missing = missing + 1
            end
        end
        if not m.internal then
            -- Only record a state we actually read. IsEnabled returns nil
            -- when the DB is not there yet, and coercing that to false
            -- would make every module look as though it booted disabled --
            -- so the first tick of any box would count as a revert and
            -- silently drop out of the reload queue.
            local state = R.IsEnabled(m.key)
            if state ~= nil then bootState[m.key] = state and true or false end
        end
    end
    resolved = true
    return bound, missing
end

function LC.IsResolved()
    return resolved
end

-- ---------------------------------------------------------------------
-- CAPABILITY
-- ---------------------------------------------------------------------
-- What can actually be done to this module right now:
--   "live"    the flag can be flipped and take effect immediately
--   "reload"  the flag can be flipped but only a reload realises it
--   "none"    nothing to flip (passive module, or internal)
-- ---------------------------------------------------------------------

function LC.Capability(key)
    local m = R.Get(key)
    if not m then return "none" end
    if m.internal or m.toggleModel == "passive" then return "none" end
    if m.requiresReload then return "reload" end

    local impl = Impl(m)
    if not impl then return "reload" end

    if m.applyMode == "pair" then
        if type(impl.Enable) == "function" and type(impl.Disable) == "function" then return "live" end
        return "reload"
    elseif m.applyMode == "setter" or m.applyMode == "gate" then
        if type(impl[m.apply]) == "function" then return "live" end
        return "reload"
    end
    return "reload"
end

--- True when the change has to wait for the end of combat.
local function MustDefer(m)
    if not InCombatLockdown or not InCombatLockdown() then return false end
    return not m.combatSafe
end

-- ---------------------------------------------------------------------
-- APPLY
-- ---------------------------------------------------------------------

--- Brings the module in line with the flag the registry has just
--- written. The flag is always the registry's to write, never the
--- module's: several SetEnabled() implementations write it, one
--- (RareAlert) does not, and a couple write it in a shape that differs
--- from what a composite module needs. Writing it here first and
--- unconditionally makes the stored state correct whatever the module
--- then does with the value it is handed.
local function Realise(m, value)
    if m.applyMode == "setter" then
        return SafeCall(m, m.apply, value)
    elseif m.applyMode == "gate" then
        return SafeCall(m, m.apply)
    elseif m.applyMode == "pair" then
        return SafeCall(m, value and "Enable" or "Disable")
    end
    return false, "no apply mode"
end

-- ---------------------------------------------------------------------
-- SET ENABLED
-- ---------------------------------------------------------------------
-- The single entry point. Returns a report table rather than printing
-- or prompting: the caller knows whether it is a slash command, a
-- checkbox or a profile being applied, and can present the outcome
-- accordingly.
--
--   report.ok          the flag now holds the requested value
--   report.applied     the change is live
--   report.deferred    queued until combat ends
--   report.needsReload the flag moved but a reload is required
--   report.cascade     dependents switched off alongside it
--   report.missingDeps deps that are off, so this module will idle
-- ---------------------------------------------------------------------

function LC.SetEnabled(key, value, _seen)
    local report = { key = key, value = value and true or false,
                     ok = false, applied = false, deferred = false,
                     needsReload = false, cascade = {}, missingDeps = {} }
    lastReport = report

    local m = R.Get(key)
    if not m then return report end
    if m.internal or m.toggleModel == "passive" then return report end

    value = value and true or false

    -- Turning a module off takes its dependents with it: a dependent
    -- whose base is gone cannot work, and leaving it ticked would
    -- report a state the player does not have. Turning one back on does
    -- NOT cascade upward -- silently enabling things the player never
    -- asked for is worse than telling them what is missing.
    _seen = _seen or {}
    _seen[key] = true
    if not value then
        for _, dep in ipairs(R.Dependents(key)) do
            if not _seen[dep] and R.IsEnabled(dep) then
                local sub = LC.SetEnabled(dep, false, _seen)
                report.cascade[#report.cascade + 1] = dep
                if sub.needsReload then report.needsReload = true end
            end
        end
        lastReport = report
    end

    if MustDefer(m) then
        -- Re-deciding during the same fight replaces the queued value
        -- rather than stacking a second entry: what gets replayed is the
        -- player's last word, and the count has to say one, not two.
        if pending[key] == nil then pendingN = pendingN + 1 end
        pending[key] = value
        LC._ArmCombatWatch()
        report.deferred = true
        return report
    end

    -- The flag moves first and always, whatever the apply path does or
    -- fails to do. A module that cannot be realised live still has to
    -- remember the player's choice across the reload it will prompt.
    report.ok = R.SetEnabled(key, value)

    local cap = LC.Capability(key)
    if cap == "live" then
        local applied = Realise(m, value)
        report.applied = applied and true or false
        if not applied then report.needsReload = true end
    else
        report.needsReload = true
    end

    -- Queue or unqueue against the login state. Done after the apply
    -- attempt, so a module that was supposed to be live but threw is
    -- treated like any other module needing a reload.
    if report.needsReload then
        LC.NoteReloadNeeded(key)
    end

    if value then
        report.missingDeps = R.MissingDeps(key)
    end

    lastReport = report
    return report
end

function LC.Toggle(key)
    local current = R.IsEnabled(key)
    if current == nil then return { key = key, ok = false } end
    return LC.SetEnabled(key, not current)
end

function LC.LastReport()
    return lastReport
end

-- ---------------------------------------------------------------------
-- COMBAT DEFERRAL
-- ---------------------------------------------------------------------

function LC._ArmCombatWatch()
    if combatFrame then return end
    if not CreateFrame then return end
    combatFrame = CreateFrame("Frame")
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatFrame:SetScript("OnEvent", function()
        LC.FlushPending()
        -- A prompt that was withheld during the fight is offered now.
        if reloadN > 0 then ArmPrompt() end
    end)
end

--- Replays everything that was queued during combat. Order is not
--- guaranteed to matter here -- the queue holds at most one entry per
--- module, and a cascade already resolved its dependents when it was
--- queued.
function LC.FlushPending()
    if pendingN == 0 then return 0 end
    local queue = pending
    pending, pendingN = {}, 0
    local n = 0
    for key, value in pairs(queue) do
        LC.SetEnabled(key, value)
        n = n + 1
    end
    return n
end

function LC.PendingCount()
    return pendingN
end

function LC.Pending()
    local out = {}
    for key, value in pairs(pending) do out[key] = value end
    return out
end

-- ---------------------------------------------------------------------
-- RELOAD REQUESTS
-- ---------------------------------------------------------------------
-- Modules with no live path still need the frame work a reload does.
-- Rather than let every caller fire its own popup -- which is what the
-- party, raid and nameplate panels each grew independently -- requests
-- accumulate here and produce one dialog for the whole batch.
--
-- Three behaviours matter more than the dialog itself:
--
--   Coalescing   unticking five boxes in a row is one prompt, not five,
--                and a dependency cascade is one prompt for the player
--                action that caused it rather than one per module.
--   Reverting    a module put back the way it was at login leaves the
--                queue. There is nothing left to realise.
--   Combat       the prompt waits. Offering a UI reload mid-pull is
--                worse than the stale frame it would fix.
-- ---------------------------------------------------------------------

local PROMPT_DEBOUNCE = 0.35   -- long enough to absorb a burst of clicks

local function NotifyWatchers()
    for i = 1, #watchers do
        local ok = pcall(watchers[i], reloadN)
        if not ok then end   -- a broken banner must not block the engine
    end
end

--- Registers a callback fired on every change to the pending set.
function LC.OnPendingChanged(fn)
    if type(fn) == "function" then watchers[#watchers + 1] = fn end
end

function LC.PendingReloadCount()
    return reloadN
end

function LC.IsPendingReload(key)
    return reloadPending[key] and true or false
end

--- Sorted so the dialog and the banner list things in a stable order
--- rather than whatever pairs() happens to yield.
function LC.PendingReload()
    local out = {}
    for key in pairs(reloadPending) do out[#out + 1] = key end
    table.sort(out)
    return out
end

function LC.CancelReload(key)
    if not reloadPending[key] then return false end
    reloadPending[key] = nil
    reloadN = reloadN - 1
    NotifyWatchers()
    return true
end

function LC.ClearReload()
    if reloadN == 0 then return end
    reloadPending, reloadN = {}, 0
    NotifyWatchers()
end

-- Supplied by Core/ModuleReloadUI.lua. Kept as a hook so the engine
-- carries no reference to a frame or a popup: the headless suites drive
-- it with a plain function, and lot 7 can swap the surface without
-- touching anything here.
local promptHandler

function LC.SetPromptHandler(fn)
    promptHandler = type(fn) == "function" and fn or nil
end

local function ShowPrompt()
    promptArmed = false
    if reloadN == 0 or promptSuppress then return end
    if InCombatLockdown and InCombatLockdown() then
        -- Re-armed by the same watcher that replays deferred toggles.
        LC._ArmCombatWatch()
        return
    end
    if promptHandler then promptHandler() end
end

function ArmPrompt()
    if promptArmed or promptSuppress then return end
    promptArmed = true
    if C_Timer and C_Timer.After then
        C_Timer.After(PROMPT_DEBOUNCE, ShowPrompt)
    else
        ShowPrompt()
    end
end

--- Queues a reload for `key`. Safe to call repeatedly: a key already in
--- the queue does not re-arm the dialog.
function LC.RequestReload(key)
    if not key or reloadPending[key] then return false end
    reloadPending[key] = true
    reloadN = reloadN + 1
    NotifyWatchers()
    ArmPrompt()
    return true
end

--- Used when a batch of changes is about to be made and only one
--- decision should be offered at the end -- a profile being applied, or
--- a resolution preset being written in lot 5.
function LC.BeginBatch()
    promptSuppress = true
end

function LC.EndBatch()
    promptSuppress = false
    if reloadN > 0 then ArmPrompt() end
end

--- Compares a module against the state it had at login and queues or
--- unqueues accordingly. Called by SetEnabled; exposed because settings
--- that are not a module flag -- a party frame slider, say -- need the
--- same behaviour without going through the toggle path.
function LC.NoteReloadNeeded(key)
    local booted = bootState[key]
    if booted ~= nil and R.IsEnabled(key) == booted then
        return LC.CancelReload(key)
    end
    return LC.RequestReload(key)
end



--- Re-applies every module to the flag it currently holds. This is what
--- a profile load needs: the DB has been replaced wholesale, and every
--- module has to be told to look again. Modules with no live path are
--- counted, not forced -- the caller decides whether that warrants a
--- reload prompt.
function LC.ApplyAll()
    local applied, stale, skipped = 0, 0, 0
    for _, m in ipairs(R.List()) do
        local cap = LC.Capability(m.key)
        if cap == "live" then
            local value = R.IsEnabled(m.key)
            if Realise(m, value and true or false) then
                applied = applied + 1
            else
                stale = stale + 1
            end
        elseif cap == "reload" then
            stale = stale + 1
        else
            skipped = skipped + 1
        end
    end
    return applied, stale, skipped
end

--- Inventory of what the engine can and cannot do, for the diagnostics
--- panel and the slash command.
function LC.Summary()
    local live, reload, none = 0, 0, 0
    for _, m in ipairs(R.List()) do
        local cap = LC.Capability(m.key)
        if cap == "live" then live = live + 1
        elseif cap == "reload" then reload = reload + 1
        else none = none + 1 end
    end
    return live, reload, none
end

--- Rows for a listing: key, label, on/off, capability, group.
function LC.Report()
    local rows = {}
    for _, m in ipairs(R.List()) do
        rows[#rows + 1] = {
            key        = m.key,
            label      = m.label,
            group      = m.group,
            enabled    = R.IsEnabled(m.key),
            capability = LC.Capability(m.key),
            bound      = Impl(m) ~= nil,
        }
    end
    return rows
end

--- Test seam.
function LC._Reset()
    resolved, pending, pendingN, lastReport = false, {}, 0, nil
    combatFrame = nil
    reloadPending, reloadN = {}, 0
    promptArmed, promptSuppress = false, false
    bootState, watchers, promptHandler = {}, {}, nil
end

-- =====================================================================
-- ContextProfiles.lua — Profiles that follow the content (v4 Lot 4)
-- ---------------------------------------------------------------------
-- Arbitration A: content profiles are swapped whole rather than layered.
--
-- The spec-based switch in Core/Profiles.lua already does exactly this
-- shape of work -- save the active profile, apply another snapshot, note
-- what is now active -- so contexts follow the same path instead of
-- inventing a parallel one. What is new is the key, the detection, and
-- three things that only matter because a content change can happen at
-- any moment rather than at a deliberate click:
--
--   Combat      a swap rewrites TomoModDB and respawns frames. Keys are
--               started in combat often enough that deferring is not an
--               edge case, it is the normal path.
--   Pinning     lot 0 marked nine modules contextSwap = false. A player
--               who opens the diagnostics panel in a raid should not
--               find it closed after stepping into a key.
--   Reloads     a snapshot can differ in module *settings* (live) or in
--               which modules are *enabled* (often reload-only). Only
--               the second kind is worth a prompt, so the two snapshots
--               are compared before anything is applied.
--
-- Resolution order, most specific first:
--
--   contextProfiles["<specID>:<context>"]   this spec, this content
--   contextProfiles["*:<context>"]          any spec, this content
--   (nothing)                               the spec assignment decides,
--                                           exactly as it does today
--
-- A player who never assigns a context keeps today's behaviour to the
-- letter: Evaluate() finds no assignment and returns without touching
-- anything.
-- =====================================================================

TomoMod_Context = TomoMod_Context or {}
local CTX = TomoMod_Context

local R = TomoMod_Registry

-- ---------------------------------------------------------------------
-- CONTEXTS
-- ---------------------------------------------------------------------
-- Five, in the order the GUI should list them. Derived from instance
-- type and the challenge-mode API, never from dungeon or season ids:
-- those get renumbered at patches and a table of them would rot.
-- ---------------------------------------------------------------------

local CONTEXTS = {
    { key = "solo",       label = "ctx_solo",       order = 1 },
    { key = "party",      label = "ctx_party",      order = 2 },
    { key = "mythicplus", label = "ctx_mythicplus", order = 3 },
    { key = "raid",       label = "ctx_raid",       order = 4 },
    { key = "pvp",        label = "ctx_pvp",        order = 5 },
}
CTX.CONTEXTS = CONTEXTS

local VALID = {}
for _, c in ipairs(CONTEXTS) do VALID[c.key] = true end

local ANY_SPEC = "*"

-- ---------------------------------------------------------------------
-- STATE
-- ---------------------------------------------------------------------

local current      = nil    -- last context actually applied
local pendingCtx   = nil    -- waiting for the end of combat
local watcher                -- event frame
local lastReport

-- ---------------------------------------------------------------------
-- DETECTION
-- ---------------------------------------------------------------------

--- Which content the player is in right now.
---
--- A Mythic+ dungeon only reports as such once the key is started, so
--- walking in reads as "party" and slotting the key moves to
--- "mythicplus". That second change lands mid-pull often enough that
--- the deferral below is the normal path rather than a safety net.
function CTX.Detect()
    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive
       and C_ChallengeMode.IsChallengeModeActive() then
        return "mythicplus"
    end

    local instanceType
    if GetInstanceInfo then
        local _, t = GetInstanceInfo()
        instanceType = t
    end

    if instanceType == "raid" then return "raid" end
    if instanceType == "pvp" or instanceType == "arena" then return "pvp" end
    if instanceType == "party" then return "party" end

    -- Outside an instance: a group still counts as party content, because
    -- that is what the layout is being asked to suit.
    if IsInRaid and IsInRaid() then return "raid" end
    if IsInGroup and IsInGroup() then return "party" end
    return "solo"
end

function CTX.Current()
    return current
end

function CTX.IsValid(key)
    return VALID[key] == true
end

-- ---------------------------------------------------------------------
-- ASSIGNMENTS
-- ---------------------------------------------------------------------

local function DB()
    local P = TomoMod_Profiles
    if not P or not TomoModDB then return nil end
    P.EnsureProfilesDB()
    local db = TomoModDB._profiles
    if not db then return nil end
    if type(db.contextProfiles) ~= "table" then db.contextProfiles = {} end
    return db
end

local function Key(specID, context)
    return tostring(specID or ANY_SPEC) .. ":" .. tostring(context)
end
CTX.Key = Key

function CTX.IsEnabled()
    local db = DB()
    return (db and db.contextEnabled) and true or false
end

function CTX.SetEnabled(value)
    local db = DB()
    if not db then return false end
    db.contextEnabled = value and true or false
    if db.contextEnabled then CTX.Evaluate() end
    return true
end

--- `specID` may be nil or "*" to mean "whatever spec I am".
function CTX.Assign(specID, context, profileName)
    if not VALID[context] then return false end
    local db = DB()
    if not db or not db.named or not db.named[profileName] then return false end
    db.contextProfiles[Key(specID, context)] = profileName
    return true
end

function CTX.Unassign(specID, context)
    local db = DB()
    if not db then return false end
    db.contextProfiles[Key(specID, context)] = nil
    return true
end

--- The profile that should be active for a context, or nil when nothing
--- is assigned and the spec rules should be left alone.
function CTX.Resolve(context, specID)
    local db = DB()
    if not db then return nil end
    local P = TomoMod_Profiles
    if specID == nil and P and P.GetCurrentSpecID then specID = P.GetCurrentSpecID() end

    local name = db.contextProfiles[Key(specID, context)]
    if not name then name = db.contextProfiles[Key(ANY_SPEC, context)] end
    -- An assignment pointing at a profile that has since been deleted is
    -- treated as no assignment: silently applying nothing is better than
    -- erroring, and the stale key is dropped so it stops being consulted.
    if name and not (db.named and db.named[name]) then
        db.contextProfiles[Key(specID, context)] = nil
        db.contextProfiles[Key(ANY_SPEC, context)] = nil
        return nil
    end
    return name
end

--- Every assignment, for the GUI and the slash command.
function CTX.List()
    local db = DB()
    local out = {}
    if not db then return out end
    for key, name in pairs(db.contextProfiles) do
        local spec, context = key:match("^([^:]+):(.+)$")
        if context and VALID[context] then
            out[#out + 1] = { spec = spec, context = context, profile = name }
        end
    end
    table.sort(out, function(a, b)
        if a.context ~= b.context then return a.context < b.context end
        return tostring(a.spec) < tostring(b.spec)
    end)
    return out
end

-- ---------------------------------------------------------------------
-- RELOAD PREDICTION
-- ---------------------------------------------------------------------
-- A snapshot differing in a slider, a colour or a position is applied
-- live. A snapshot differing in whether a module is switched on may not
-- be: lot 1 measured that 33 of 62 modules still need a reload to change
-- that. Comparing the two before applying means the player is only asked
-- to reload when something actually cannot be realised, instead of on
-- every zone change.
-- ---------------------------------------------------------------------

--- Modules whose enabled state differs between the live DB and `snap`,
--- and which have no live path to that change.
function CTX.PredictReloads(snap)
    local out = {}
    if type(snap) ~= "table" or not R then return out end
    local LC = TomoMod_Lifecycle
    for _, m in ipairs(R.List()) do
        -- A module absent from the snapshot is not "off": ApplySnapshot
        -- runs MergeTables afterwards, so it will be filled from the
        -- defaults. Reading a missing path as false would predict a
        -- reload for every module a partial snapshot happens not to
        -- carry, which is the opposite of the point.
        if m.contextSwap and m.toggleModel ~= "passive" and snap[m.dbKey] ~= nil then
            local now    = R.IsEnabled(m.key)
            local target = R.IsEnabledIn(snap, m.key)
            if target ~= nil and now ~= target then
                local cap = LC and LC.Capability(m.key) or "reload"
                if cap ~= "live" then out[#out + 1] = m.key end
            end
        end
    end
    table.sort(out)
    return out
end

-- ---------------------------------------------------------------------
-- SWAP
-- ---------------------------------------------------------------------

local function ApplyContext(context)
    local report = { context = context, swapped = false, deferred = false,
                     profile = nil, reloads = {} }
    lastReport = report

    local P = TomoMod_Profiles
    local db = DB()
    if not P or not db then return report end

    local target = CTX.Resolve(context)
    if not target then
        -- Nothing assigned: the spec rules keep whatever they decided.
        current = context
        return report
    end

    if db.activeProfile == target then
        current = context
        return report
    end

    local snap = db.named[target]
    if not snap then return report end

    report.reloads = CTX.PredictReloads(snap)
    report.profile = target

    local LC = TomoMod_Lifecycle
    -- One decision for the whole swap rather than one per module.
    if LC and LC.BeginBatch then LC.BeginBatch() end

    local ok = P.ApplyForContext(target)

    if ok then
        current = context
        report.swapped = true
        if LC then
            if LC.ApplyAll then LC.ApplyAll() end
            for _, key in ipairs(report.reloads) do
                if LC.RequestReload then LC.RequestReload(key) end
            end
        end
    end

    if LC and LC.EndBatch then LC.EndBatch() end
    return report
end

--- Detects the content and swaps if needed. Safe to call as often as an
--- event fires: it returns immediately when nothing has changed.
function CTX.Evaluate()
    if not CTX.IsEnabled() then return nil end

    local context = CTX.Detect()
    if context == current then return nil end

    if InCombatLockdown and InCombatLockdown() then
        -- Rewriting the whole DB and respawning frames mid-combat is
        -- exactly the taint this addon spends its time avoiding.
        pendingCtx = context
        CTX._ArmWatcher()
        lastReport = { context = context, swapped = false, deferred = true, reloads = {} }
        return lastReport
    end

    pendingCtx = nil
    return ApplyContext(context)
end

function CTX.Pending()
    return pendingCtx
end

function CTX.LastReport()
    return lastReport
end

-- ---------------------------------------------------------------------
-- EVENTS
-- ---------------------------------------------------------------------

local EVENTS = {
    "PLAYER_ENTERING_WORLD",
    "ZONE_CHANGED_NEW_AREA",
    "GROUP_ROSTER_UPDATE",
    "CHALLENGE_MODE_START",
    "CHALLENGE_MODE_COMPLETED",
    "CHALLENGE_MODE_RESET",
    "PLAYER_REGEN_ENABLED",
}

function CTX._ArmWatcher()
    if watcher or not CreateFrame then return end
    watcher = CreateFrame("Frame")
    for _, e in ipairs(EVENTS) do
        pcall(watcher.RegisterEvent, watcher, e)
    end
    watcher:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            if pendingCtx then
                local ctx = pendingCtx
                pendingCtx = nil
                ApplyContext(ctx)
            end
            return
        end
        CTX.Evaluate()
    end)
end

function CTX.Initialize()
    CTX._ArmWatcher()
    -- Seed without swapping: at login the active profile is whatever was
    -- saved, and treating that as a change would swap on every reload.
    current = CTX.Detect()
    return current
end

--- Test seam.
function CTX._Reset()
    current, pendingCtx, watcher, lastReport = nil, nil, nil, nil
end

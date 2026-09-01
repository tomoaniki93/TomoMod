-- =====================================================================
-- SelectiveImport.lua — Choosing what an import brings in (v4 Lot 6)
-- ---------------------------------------------------------------------
-- Importing a profile was all-or-nothing: ApplySnapshot emptied
-- TomoModDB and wrote the payload over it. Someone who wanted another
-- player's nameplate work had to accept their action bars, their chat
-- skin and their minimap along with it.
--
-- Arbitration C: nine collapsible groups with drill-down. The groups
-- come from Core/ModuleRegistry.lua, so this file holds no list of its
-- own and cannot fall out of step with the inventory.
--
-- Why a module slice is safe to move on its own
-- ---------------------------------------------
-- Lot 0's Validate() proves that every toggle path and every anchor path
-- of a module sits inside that module's own dbKey. Nothing reaches
-- sideways into another module's table. That is what makes replacing one
-- top-level key a complete, self-consistent operation instead of a
-- half-applied import -- and it is why the check was written back then
-- rather than left as a nicety.
--
-- Merge, not replace
-- ------------------
-- Only the selected keys are written. Everything else is left exactly as
-- it was, which is the whole point and the one behaviour that makes this
-- different from the existing import. TomoMod_MergeTables then fills any
-- key the payload predates, because a profile exported two versions ago
-- has no entry for settings added since.
-- =====================================================================

TomoMod_SelectiveImport = TomoMod_SelectiveImport or {}
local SI = TomoMod_SelectiveImport

local R = TomoMod_Registry

-- Bookkeeping that must never travel between installations: profile
-- storage itself, migration flags, resolution captures tied to someone
-- else's screen.
local NEVER_IMPORT = {
    _profiles   = true,
    _migrations = true,
    _resolution = true,
    _auraTrackerRescue = true,
}
SI.NEVER_IMPORT = NEVER_IMPORT

-- ---------------------------------------------------------------------
-- COMPARISON
-- ---------------------------------------------------------------------

--- Short-circuits on the first difference. A preview compares sixty-odd
--- module tables and only ever needs a yes or no per module, so walking
--- the whole of each one would be wasted work on every keystroke in the
--- import box.
local function Differs(a, b, depth)
    depth = (depth or 0) + 1
    if depth > 12 then return false end          -- pathological nesting
    if a == b then return false end
    if type(a) ~= "table" or type(b) ~= "table" then return true end
    for k, v in pairs(a) do
        if Differs(v, b[k], depth) then return true end
    end
    for k in pairs(b) do
        if a[k] == nil then return true end
    end
    return false
end
SI.Differs = Differs

local function DeepCopy(v)
    if type(v) ~= "table" then return v end
    local o = {}
    for k, val in pairs(v) do o[k] = DeepCopy(val) end
    return o
end

-- ---------------------------------------------------------------------
-- INSPECT
-- ---------------------------------------------------------------------

--- Builds the checkbox tree for a payload.
---
--- Returns groups, meta, unknown:
---   groups   ordered list of { key, label, modules = { row, ... } }
---   meta     the payload header (version, class, spec, date)
---   unknown  top-level keys the payload carries that no manifest claims
---
--- Each row carries what a row has to show to be worth reading:
---   key, label, group
---   enabledNow / enabledInPayload
---   differs         whether importing it would change anything at all
---   requiresReload  whether accepting it costs a /reload
---
--- `differs` is the field that makes the table usable. A full profile
--- carries all sixty-two modules, and without it every row looks equally
--- worth ticking when three of them actually hold anything new.
function SI.Inspect(settings)
    local groups, unknown = {}, {}
    if type(settings) ~= "table" or not R or not TomoModDB then
        return groups, nil, unknown
    end

    local LC = TomoMod_Lifecycle
    local claimed = {}

    for _, g in ipairs(R.Groups()) do
        local rows = {}
        for _, m in ipairs(R.ListByGroup(g.key)) do
            claimed[m.dbKey] = true
            local slice = settings[m.dbKey]
            if slice ~= nil then
                local cap = LC and LC.Capability(m.key) or "reload"
                rows[#rows + 1] = {
                    key             = m.key,
                    dbKey           = m.dbKey,
                    label           = m.label,
                    group           = g.key,
                    enabledNow      = R.IsEnabled(m.key),
                    enabledInPayload = R.IsEnabledIn(settings, m.key),
                    differs         = Differs(slice, TomoModDB[m.dbKey]),
                    requiresReload  = (cap ~= "live"),
                }
            end
        end
        if #rows > 0 then
            groups[#groups + 1] = { key = g.key, label = g.label, order = g.order, modules = rows }
        end
    end

    -- Internal manifests are claimed too, so they are neither offered nor
    -- reported as unknown: nobody wants another player's installer
    -- progress or keystone cache.
    for _, m in ipairs(R.ListAll()) do claimed[m.dbKey] = true end

    for k in pairs(settings) do
        if not claimed[k] and not NEVER_IMPORT[k] then
            unknown[#unknown + 1] = k
        end
    end
    table.sort(unknown)

    return groups, nil, unknown
end

--- Convenience over Core/Profiles.lua: decode a string and inspect it in
--- one call. Returns groups, meta, unknown, err.
function SI.InspectString(str)
    local P = TomoMod_Profiles
    if not P or not P.DecodeImport then return nil, nil, nil, "Profiles indisponible" end
    local payload, err = P.DecodeImport(str)
    if not payload then return nil, nil, nil, err end
    local groups, _, unknown = SI.Inspect(payload.settings)
    local meta = {
        version = payload._version,
        class   = payload._class,
        spec    = payload._spec,
        date    = payload._date,
    }
    return groups, meta, unknown, nil
end

-- ---------------------------------------------------------------------
-- SUMMARY
-- ---------------------------------------------------------------------

--- Header figures for the dialog: how much is on offer, how much of it
--- actually changes anything, and how much of that costs a reload.
function SI.Summarize(groups, selected)
    local total, changed, reloads = 0, 0, 0
    if type(groups) ~= "table" then return total, changed, reloads end
    for _, g in ipairs(groups) do
        for _, row in ipairs(g.modules) do
            local counted = (selected == nil) or selected[row.key]
            if counted then
                total = total + 1
                if row.differs then changed = changed + 1 end
                if row.differs and row.requiresReload then reloads = reloads + 1 end
            end
        end
    end
    return total, changed, reloads
end

--- Every module key in the tree, for a "select all" that cannot drift
--- from what is actually displayed.
function SI.AllKeys(groups, onlyChanged)
    local out = {}
    if type(groups) ~= "table" then return out end
    for _, g in ipairs(groups) do
        for _, row in ipairs(g.modules) do
            if not onlyChanged or row.differs then out[#out + 1] = row.key end
        end
    end
    return out
end

--- The keys of one group, for its header checkbox.
function SI.GroupKeys(groups, groupKey)
    local out = {}
    if type(groups) ~= "table" then return out end
    for _, g in ipairs(groups) do
        if g.key == groupKey then
            for _, row in ipairs(g.modules) do out[#out + 1] = row.key end
        end
    end
    return out
end

-- ---------------------------------------------------------------------
-- APPLY
-- ---------------------------------------------------------------------

--- Writes only the chosen modules.
---
--- `keys` is an array of module keys, or of raw top-level keys for the
--- unknown bucket. Anything not listed is left untouched -- that is the
--- entire difference from the existing import, and the reason this does
--- not go anywhere near ApplySnapshot.
---
--- Returns a report: applied, skipped, reloads.
function SI.Apply(settings, keys)
    local report = { applied = 0, skipped = 0, reloads = {} }
    if type(settings) ~= "table" or type(keys) ~= "table" or not TomoModDB or not R then
        return report
    end

    local LC = TomoMod_Lifecycle
    -- One reload decision for the whole import rather than one per module.
    if LC and LC.BeginBatch then LC.BeginBatch() end

    for _, key in ipairs(keys) do
        local m = R.Get(key)
        local dbKey = m and m.dbKey or key

        if NEVER_IMPORT[dbKey] or (m and m.internal) then
            report.skipped = report.skipped + 1
        elseif settings[dbKey] == nil then
            report.skipped = report.skipped + 1
        else
            -- A reload is only warranted when the module's enabled state
            -- actually moves and cannot be realised live. A different
            -- colour or position is applied on the spot.
            if m then
                local before = R.IsEnabled(m.key)
                local after  = R.IsEnabledIn(settings, m.key)
                local cap    = LC and LC.Capability(m.key) or "reload"
                if after ~= nil and before ~= after and cap ~= "live" then
                    report.reloads[#report.reloads + 1] = m.key
                end
            end

            TomoModDB[dbKey] = DeepCopy(settings[dbKey])
            report.applied = report.applied + 1
        end
    end

    -- A payload exported by an older version has no entry for settings
    -- added since; the merge fills those from the defaults rather than
    -- leaving the module reading nil.
    if TomoMod_MergeTables and TomoMod_Defaults then
        TomoMod_MergeTables(TomoModDB, TomoMod_Defaults)
    end
    if TomoMod_NormalizeAllElements then TomoMod_NormalizeAllElements() end

    if LC then
        if LC.ApplyAll then LC.ApplyAll() end
        for _, key in ipairs(report.reloads) do
            if LC.RequestReload then LC.RequestReload(key) end
        end
        if LC.EndBatch then LC.EndBatch() end
    end

    if TomoMod_Config and TomoMod_Config.InvalidatePanels then
        TomoMod_Config.InvalidatePanels()
    end

    table.sort(report.reloads)
    return report
end

--- Decode and apply in one call.
function SI.ApplyString(str, keys)
    local P = TomoMod_Profiles
    if not P or not P.DecodeImport then return nil, "Profiles indisponible" end
    local payload, err = P.DecodeImport(str)
    if not payload then return nil, err end
    return SI.Apply(payload.settings, keys)
end

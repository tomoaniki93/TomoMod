-- =====================================================================
-- ModuleRegistry.lua — Central module manifest (v4 Lot 0)
-- ---------------------------------------------------------------------
-- Why this file exists.
--
-- Core/Init.lua already shipped a TomoMod_RegisterModule(), but only a
-- handful of modules ever called it, so there has never been a real
-- inventory of what TomoMod contains. Everything that wants to reason
-- about "the set of modules" -- enable/disable, per-content profiles,
-- selective profile import, the layout engine -- had to re-derive that
-- set by hand, and each one derived a slightly different set.
--
-- This registry is that inventory, expressed as data. It stores no
-- behaviour of its own: a manifest describes where a module keeps its
-- settings, which group it belongs to, what it can be toggled by, what
-- it may move on screen, and whether it survives a content swap. The
-- lots that follow read it instead of re-deriving:
--
--   Lot 1  Enable/Disable    -> enabledPath / toggles / requiresReload
--   Lot 2  Layout engine     -> anchors (declared shape, relative model)
--   Lot 4  Content profiles  -> contextSwap
--   Lot 6  Selective import  -> group + dbKey
--
-- Nothing here changes runtime behaviour. Defining a manifest does not
-- load, enable, disable or touch a module; it only records facts about
-- it. That is deliberate: the registry has to be trustworthy before
-- anything is allowed to act on it.
-- =====================================================================

TomoMod_Registry = TomoMod_Registry or {}
local R = TomoMod_Registry

R.SCHEMA_VERSION = 1

-- ---------------------------------------------------------------------
-- GROUPS
-- ---------------------------------------------------------------------
-- Nine collapsible groups. They are the drill-down level for the
-- selective profile import (Lot 6) and the natural spine for the v4
-- GUI navigation (Lot 7).
--
-- These deliberately do NOT mirror TomoMod_Config.CategoryTree. That
-- tree is a description of the *current* config UI, and Lot 7 rewrites
-- it; binding the data layer to it would mean re-labelling every
-- manifest the day the shell changes. Groups are owned here.
-- ---------------------------------------------------------------------

local GROUPS = {
    { key = "general",     label = "mod_group_general",     order = 1 },
    { key = "actionbars",  label = "mod_group_actionbars",  order = 2 },
    { key = "skins",       label = "mod_group_skins",       order = 3 },
    { key = "unitframes",  label = "mod_group_unitframes",  order = 4 },
    { key = "groupframes", label = "mod_group_groupframes", order = 5 },
    { key = "nameplates",  label = "mod_group_nameplates",  order = 6 },
    { key = "cooldowns",   label = "mod_group_cooldowns",   order = 7 },
    { key = "mythicplus",  label = "mod_group_mythicplus",  order = 8 },
    { key = "qol",         label = "mod_group_qol",         order = 9 },
}

local GROUP_BY_KEY = {}
for _, g in ipairs(GROUPS) do GROUP_BY_KEY[g.key] = g end

R.GROUPS = GROUPS

-- Anchor storage shapes found in TomoMod_Defaults. Three variants grew
-- independently over time and all three are still live, so the layout
-- engine cannot assume one. Declaring the shape per anchor turns the
-- Lot 2 migration into a table walk instead of 26 special cases.
local ANCHOR_SHAPES = {
    point_relativePoint = { point = "point", rel = "relativePoint", x = "x", y = "y" },
    point_relPoint      = { point = "point", rel = "relPoint",      x = "x", y = "y" },
    anchor_relTo        = { point = "anchor", rel = "relTo",        x = "x", y = "y" },
}
R.ANCHOR_SHAPES = ANCHOR_SHAPES

-- ---------------------------------------------------------------------
-- STATE
-- ---------------------------------------------------------------------

local manifests = {}   -- key -> manifest
local order     = {}   -- insertion order, so List() is deterministic
local errors    = {}   -- collected by Validate()

-- ---------------------------------------------------------------------
-- PATH HELPERS
-- ---------------------------------------------------------------------
-- Paths are dotted and rooted at TomoModDB: "minimap.enabled",
-- "merchantTools.extendPages.enabled". Reads never create tables;
-- writes create only what they must.
-- ---------------------------------------------------------------------

local function SplitPath(path)
    local parts = {}
    for seg in string.gmatch(path, "[^%.]+") do
        parts[#parts + 1] = seg
    end
    return parts
end
R.SplitPath = SplitPath

local function GetPath(root, path)
    if type(root) ~= "table" or type(path) ~= "string" then return nil end
    local node = root
    for _, seg in ipairs(SplitPath(path)) do
        if type(node) ~= "table" then return nil end
        node = node[seg]
    end
    return node
end
R.GetPath = GetPath

local function SetPath(root, path, value)
    if type(root) ~= "table" or type(path) ~= "string" then return false end
    local parts = SplitPath(path)
    local last  = table.remove(parts)
    if not last then return false end
    local node = root
    for _, seg in ipairs(parts) do
        if type(node[seg]) ~= "table" then node[seg] = {} end
        node = node[seg]
    end
    node[last] = value
    return true
end
R.SetPath = SetPath

-- ---------------------------------------------------------------------
-- DEFINE
-- ---------------------------------------------------------------------
-- Structural problems raise immediately: a malformed manifest is a
-- coding error, and letting it through would poison every consumer
-- downstream. Relational problems (an unknown dependency, a dbKey with
-- no matching default) cannot be judged here because manifests may be
-- declared in any order and TomoMod_Defaults may not be populated yet;
-- those are Validate()'s job.
-- ---------------------------------------------------------------------

function R.Define(desc)
    assert(type(desc) == "table", "Registry.Define: manifest must be a table")

    local key = desc.key
    assert(type(key) == "string" and key ~= "", "Registry.Define: missing key")
    assert(manifests[key] == nil, "Registry.Define: duplicate key '" .. key .. "'")

    local m = {
        key      = key,
        dbKey    = desc.dbKey or key,
        internal = desc.internal and true or false,
    }

    if m.internal then
        -- Bookkeeping, not configuration: installer progress, cached
        -- keystone data, CVar backups. Never listed, never toggled,
        -- never offered at import.
        assert(desc.group == nil, "Registry.Define: internal module '" .. key .. "' must not declare a group")
        m.group       = nil
        m.label       = desc.label   -- optional, diagnostics only
        m.contextSwap = false
    else
        assert(type(desc.label) == "string" and desc.label ~= "",
            "Registry.Define: '" .. key .. "' needs a label locale key")
        assert(type(desc.group) == "string" and GROUP_BY_KEY[desc.group],
            "Registry.Define: '" .. key .. "' has unknown group '" .. tostring(desc.group) .. "'")
        m.label = desc.label
        m.group = desc.group
        -- Arbitration A: content profiles are swapped whole, so the
        -- interesting flag is which modules must NOT follow the swap.
        -- Default is to follow; opting out is the exception.
        m.contextSwap = (desc.contextSwap ~= false)
    end

    -- Toggle model. A module is either:
    --   simple    -> one boolean at enabledPath
    --   composite -> several booleans, no single master switch
    --   passive   -> neither (always on, e.g. pure skins with no flag)
    assert(not (desc.enabledPath and desc.toggles),
        "Registry.Define: '" .. key .. "' declares both enabledPath and toggles")

    if desc.enabledPath then
        assert(type(desc.enabledPath) == "string", "Registry.Define: '" .. key .. "' enabledPath must be a string")
        m.enabledPath = desc.enabledPath
        m.toggleModel = "simple"
    elseif desc.toggles then
        assert(type(desc.toggles) == "table" and #desc.toggles > 0,
            "Registry.Define: '" .. key .. "' toggles must be a non-empty array")
        m.toggles = {}
        for i, t in ipairs(desc.toggles) do
            assert(type(t) == "table" and type(t.path) == "string",
                "Registry.Define: '" .. key .. "' toggle #" .. i .. " needs a path")
            m.toggles[i] = { path = t.path, label = t.label }
        end
        m.toggleModel = "composite"
    else
        m.toggleModel = "passive"
    end

    m.requiresReload = desc.requiresReload and true or false

    -- Lot 1: how the module is brought in line with its flag. Nothing is
    -- inferred from method names -- the same name means different things
    -- across the codebase, so an apply path counts only when a manifest
    -- names it explicitly.
    --   setter  impl.<apply>(value)  owns the flag and applies it
    --   gate    flag written here, then impl.<apply>() re-applies
    --   pair    impl.Enable() / impl.Disable()
    m.global   = desc.global
    m.apply    = desc.apply
    m.applyMode = desc.applyMode
    if m.applyMode then
        assert(m.applyMode == "setter" or m.applyMode == "gate" or m.applyMode == "pair",
            "Registry.Define: '" .. key .. "' has unknown applyMode '" .. tostring(m.applyMode) .. "'")
        assert(type(m.global) == "string" and m.global ~= "",
            "Registry.Define: '" .. key .. "' declares an applyMode without a global")
        if m.applyMode == "pair" then
            assert(desc.apply == nil,
                "Registry.Define: '" .. key .. "' uses the Enable/Disable pair, so apply must stay unset")
        else
            assert(type(m.apply) == "string" and m.apply ~= "",
                "Registry.Define: '" .. key .. "' applyMode '" .. m.applyMode .. "' needs an apply method")
        end
        assert(not m.requiresReload,
            "Registry.Define: '" .. key .. "' cannot declare both an applyMode and requiresReload")
    else
        assert(desc.apply == nil,
            "Registry.Define: '" .. key .. "' names an apply method without an applyMode")
    end

    -- Changes that only register or unregister events are safe to make
    -- in combat. Anything that may respawn a frame is deferred, so the
    -- default is the cautious one.
    m.combatSafe = desc.combatSafe and true or false

    -- Dependencies are resolved in Validate(), not here: declaration
    -- order is not guaranteed and a forward reference is legitimate.
    m.deps = {}
    if desc.deps then
        assert(type(desc.deps) == "table", "Registry.Define: '" .. key .. "' deps must be an array")
        for i, d in ipairs(desc.deps) do
            assert(type(d) == "string", "Registry.Define: '" .. key .. "' dep #" .. i .. " must be a string")
            m.deps[i] = d
        end
    end

    -- Arbitration B: anchors are declared with their current storage
    -- shape so the layout engine can normalise them to a relative
    -- model without hard-coding per-module knowledge.
    m.anchors = {}
    if desc.anchors then
        assert(type(desc.anchors) == "table", "Registry.Define: '" .. key .. "' anchors must be an array")
        for i, a in ipairs(desc.anchors) do
            assert(type(a) == "table" and type(a.id) == "string" and type(a.path) == "string",
                "Registry.Define: '" .. key .. "' anchor #" .. i .. " needs id and path")
            assert(ANCHOR_SHAPES[a.shape],
                "Registry.Define: '" .. key .. "' anchor '" .. a.id .. "' has unknown shape '" .. tostring(a.shape) .. "'")
            m.anchors[i] = { id = a.id, path = a.path, shape = a.shape, label = a.label }
        end
    end

    m.forgeDomain = desc.forgeDomain   -- Lot 3, nil until a domain exists
    m.impl        = nil                -- bound later by Bind()

    manifests[key] = m
    order[#order + 1] = key
    return m
end

-- ---------------------------------------------------------------------
-- BIND
-- ---------------------------------------------------------------------
-- Attaches the live module table to its manifest. Kept separate from
-- Define so manifests stay pure data loadable outside the game (the
-- headless suites depend on that).
-- ---------------------------------------------------------------------

function R.Bind(key, impl)
    local m = manifests[key]
    if not m then return false end
    m.impl = impl
    return true
end

-- ---------------------------------------------------------------------
-- QUERY
-- ---------------------------------------------------------------------

function R.Get(key)
    return manifests[key]
end

function R.Has(key)
    return manifests[key] ~= nil
end

function R.Groups()
    local out = {}
    for i, g in ipairs(GROUPS) do out[i] = g end
    return out
end

function R.GetGroup(groupKey)
    return GROUP_BY_KEY[groupKey]
end

--- Every non-internal manifest, in declaration order.
function R.List()
    local out = {}
    for _, key in ipairs(order) do
        local m = manifests[key]
        if not m.internal then out[#out + 1] = m end
    end
    return out
end

--- Including internals. Diagnostics and the coverage suite want this.
function R.ListAll()
    local out = {}
    for i, key in ipairs(order) do out[i] = manifests[key] end
    return out
end

function R.ListByGroup(groupKey)
    local out = {}
    for _, key in ipairs(order) do
        local m = manifests[key]
        if not m.internal and m.group == groupKey then out[#out + 1] = m end
    end
    return out
end

--- Groups paired with their members, ready for a collapsible tree.
--- Empty groups are dropped: an expander that opens onto nothing is
--- worse than an absent one.
function R.Tree()
    local tree = {}
    for _, g in ipairs(GROUPS) do
        local members = R.ListByGroup(g.key)
        if #members > 0 then
            tree[#tree + 1] = { key = g.key, label = g.label, order = g.order, modules = members }
        end
    end
    return tree
end

--- Module keys that follow a content swap (arbitration A).
function R.ContextSwappable()
    local out = {}
    for _, key in ipairs(order) do
        local m = manifests[key]
        if m.contextSwap then out[#out + 1] = m.key end
    end
    return out
end

--- Module keys pinned across content swaps.
function R.ContextPinned()
    local out = {}
    for _, key in ipairs(order) do
        local m = manifests[key]
        if not m.contextSwap then out[#out + 1] = m.key end
    end
    return out
end

--- Every declared anchor, flattened, with its owning module (Lot 2).
function R.Anchors()
    local out = {}
    for _, key in ipairs(order) do
        local m = manifests[key]
        for _, a in ipairs(m.anchors) do
            out[#out + 1] = { module = m.key, id = a.id, path = a.path, shape = a.shape, label = a.label }
        end
    end
    return out
end

-- ---------------------------------------------------------------------
-- ENABLE STATE
-- ---------------------------------------------------------------------
-- Reads and writes go through TomoModDB. The registry does not call
-- Enable()/Disable() on the module: wiring the live cycle is Lot 1.
-- Here we only own the flag, so that Lot 1 has exactly one place to
-- hook into and the GUI can already render honest checkbox state.
-- ---------------------------------------------------------------------

--- Suspended sub-toggle state for a composite module lives inside the
--- module's own DB table, under a reserved key. Two consequences we
--- want: it travels with a profile (re-enabling a module restores the
--- sub-choices that profile had), and TomoMod_MergeTables leaves it
--- alone because that merge only fills in missing keys.
local SUSPEND_KEY = "_suspended"

function R.IsEnabled(key)
    local m = manifests[key]
    if not m then return nil end
    if not TomoModDB then return nil end

    if m.toggleModel == "simple" then
        return GetPath(TomoModDB, m.enabledPath) and true or false
    elseif m.toggleModel == "composite" then
        -- Composite modules have no master switch, so "enabled" means
        -- at least one sub-feature is live.
        for _, t in ipairs(m.toggles) do
            if GetPath(TomoModDB, t.path) then return true end
        end
        return false
    end
    return true   -- passive: no flag, always on
end

--- Returns ok, needsReload. needsReload is advisory: it reports the
--- manifest's requiresReload so the caller can prompt, it does not
--- reload anything itself.
function R.SetEnabled(key, value)
    local m = manifests[key]
    if not m or not TomoModDB then return false, false end
    value = value and true or false

    if m.toggleModel == "simple" then
        SetPath(TomoModDB, m.enabledPath, value)

    elseif m.toggleModel == "composite" then
        local store = TomoModDB[m.dbKey]
        if type(store) ~= "table" then return false, false end

        if not value then
            -- Remember the sub-toggles before flattening them, so that
            -- turning the module back on does not silently reset the
            -- player's per-feature choices to "all on".
            local saved = {}
            for _, t in ipairs(m.toggles) do
                saved[t.path] = GetPath(TomoModDB, t.path) and true or false
                SetPath(TomoModDB, t.path, false)
            end
            store[SUSPEND_KEY] = saved
        else
            local saved = store[SUSPEND_KEY]
            local restoredAny = false
            if type(saved) == "table" then
                for _, t in ipairs(m.toggles) do
                    if saved[t.path] then
                        SetPath(TomoModDB, t.path, true)
                        restoredAny = true
                    end
                end
                store[SUSPEND_KEY] = nil
            end
            -- Nothing to restore (never suspended, or suspended while
            -- already fully off): fall back to turning everything on,
            -- otherwise the switch would appear not to respond.
            if not restoredAny then
                for _, t in ipairs(m.toggles) do
                    SetPath(TomoModDB, t.path, true)
                end
            end
        end

    else
        return false, false   -- passive modules have nothing to set
    end

    return true, m.requiresReload
end

--- Dependencies of `key` that are declared but currently off. A module
--- whose dependency is disabled cannot be expected to work; Lot 1 uses
--- this to refuse or warn, the GUI uses it to grey a row.
function R.MissingDeps(key)
    local m = manifests[key]
    if not m then return {} end
    local out = {}
    for _, dep in ipairs(m.deps) do
        if R.IsEnabled(dep) == false then out[#out + 1] = dep end
    end
    return out
end

--- Modules that declare `key` as a dependency.
function R.Dependents(key)
    local out = {}
    for _, k in ipairs(order) do
        for _, dep in ipairs(manifests[k].deps) do
            if dep == key then out[#out + 1] = k break end
        end
    end
    return out
end

-- ---------------------------------------------------------------------
-- SNAPSHOT (Lot 6 groundwork)
-- ---------------------------------------------------------------------
-- Extracts only the DB slices owned by the given module keys. The
-- selective import builds on this: a profile payload is filtered down
-- to the modules the player ticked, instead of the current all-or-
-- nothing overwrite of TomoModDB.
--
-- Copy semantics stay the caller's problem -- Core/Profiles.lua already
-- owns DeepCopy and knows when a copy is needed and when the payload is
-- disposable. Handing back references keeps that choice where it is.
-- ---------------------------------------------------------------------

function R.Slice(source, keys)
    local out = {}
    if type(source) ~= "table" or type(keys) ~= "table" then return out end
    for _, key in ipairs(keys) do
        local m = manifests[key]
        if m and source[m.dbKey] ~= nil then
            out[m.dbKey] = source[m.dbKey]
        end
    end
    return out
end

--- Which manifests a payload actually carries, grouped for the import
--- tree. Modules absent from the payload are omitted, so the player is
--- never offered a tickbox for something the profile does not contain.
function R.DescribePayload(source)
    local tree = {}
    if type(source) ~= "table" then return tree end
    for _, g in ipairs(GROUPS) do
        local members = {}
        for _, m in ipairs(R.ListByGroup(g.key)) do
            if source[m.dbKey] ~= nil then members[#members + 1] = m end
        end
        if #members > 0 then
            tree[#tree + 1] = { key = g.key, label = g.label, order = g.order, modules = members }
        end
    end
    return tree
end

-- ---------------------------------------------------------------------
-- VALIDATE
-- ---------------------------------------------------------------------
-- Relational checks that Define() could not make. Returns ok, errors.
-- Called by the headless suites and surfaced in the Diagnostics panel;
-- it never raises, because a registry problem should be reported, not
-- turned into a load failure that hides the rest of the addon.
-- ---------------------------------------------------------------------

function R.Validate(defaults)
    errors = {}
    defaults = defaults or TomoMod_Defaults

    local seenAnchorID = {}
    local seenDBKey    = {}

    for _, key in ipairs(order) do
        local m = manifests[key]

        if type(defaults) == "table" and defaults[m.dbKey] == nil then
            errors[#errors + 1] = ("module '%s': dbKey '%s' has no entry in TomoMod_Defaults")
                :format(m.key, m.dbKey)
        end

        if seenDBKey[m.dbKey] then
            errors[#errors + 1] = ("module '%s': dbKey '%s' already claimed by '%s'")
                :format(m.key, m.dbKey, seenDBKey[m.dbKey])
        else
            seenDBKey[m.dbKey] = m.key
        end

        for _, dep in ipairs(m.deps) do
            if not manifests[dep] then
                errors[#errors + 1] = ("module '%s': unknown dependency '%s'"):format(m.key, dep)
            elseif dep == m.key then
                errors[#errors + 1] = ("module '%s': depends on itself"):format(m.key)
            end
        end

        for _, a in ipairs(m.anchors) do
            if seenAnchorID[a.id] then
                errors[#errors + 1] = ("anchor '%s' declared by both '%s' and '%s'")
                    :format(a.id, seenAnchorID[a.id], m.key)
            else
                seenAnchorID[a.id] = m.key
            end
            -- An anchor path must sit inside the module's own DB slice,
            -- otherwise a selective import could move a frame belonging
            -- to a module the player chose not to import.
            if string.sub(a.path, 1, #m.dbKey + 1) ~= (m.dbKey .. ".") then
                errors[#errors + 1] = ("module '%s': anchor '%s' path '%s' escapes its dbKey")
                    :format(m.key, a.id, a.path)
            end
        end

        if m.toggleModel == "simple" then
            if string.sub(m.enabledPath, 1, #m.dbKey + 1) ~= (m.dbKey .. ".") then
                errors[#errors + 1] = ("module '%s': enabledPath '%s' escapes its dbKey")
                    :format(m.key, m.enabledPath)
            end
        elseif m.toggleModel == "composite" then
            for _, t in ipairs(m.toggles) do
                if string.sub(t.path, 1, #m.dbKey + 1) ~= (m.dbKey .. ".") then
                    errors[#errors + 1] = ("module '%s': toggle path '%s' escapes its dbKey")
                        :format(m.key, t.path)
                end
            end
        end
    end

    -- Cycle detection over deps. A cycle would deadlock the Lot 1
    -- enable ordering, so it is caught while the graph is still data.
    local MARK_TEMP, MARK_DONE = 1, 2
    local mark = {}
    local function visit(k, trail)
        if mark[k] == MARK_DONE then return end
        if mark[k] == MARK_TEMP then
            errors[#errors + 1] = ("dependency cycle: %s -> %s"):format(table.concat(trail, " -> "), k)
            return
        end
        mark[k] = MARK_TEMP
        trail[#trail + 1] = k
        local m = manifests[k]
        if m then
            for _, dep in ipairs(m.deps) do
                if manifests[dep] then visit(dep, trail) end
            end
        end
        trail[#trail] = nil
        mark[k] = MARK_DONE
    end
    for _, key in ipairs(order) do visit(key, {}) end

    return #errors == 0, errors
end

function R.Errors()
    return errors
end

--- Test seam. Only the headless suites use it; nothing in the addon
--- ever needs to forget what it has registered.
function R._Reset()
    manifests = {}
    order     = {}
    errors    = {}
end

-- ---------------------------------------------------------------------
-- BACKWARD COMPATIBILITY
-- ---------------------------------------------------------------------
-- Core/Init.lua's TomoMod_RegisterModule() stays exactly as it was for
-- the seven callers that use it; it now also binds the implementation
-- to the manifest when one exists. Init.lua defines the function later
-- in load order, so the bridge is installed there rather than here to
-- avoid depending on which file wins.
-- ---------------------------------------------------------------------

function R.BridgeLegacy(legacyTable)
    if type(legacyTable) ~= "table" then return end
    for name, impl in pairs(legacyTable) do
        R.Bind(name, impl)
    end
end

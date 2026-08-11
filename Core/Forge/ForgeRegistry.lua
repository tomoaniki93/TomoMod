-- =====================================================================
-- TomoMod Forge -- Registry (L2)
-- Declarative element registry shared by every deep-editing domain
-- (UnitFrames today, Nameplates next). A domain declares:
--   * HOSTS    : the anchorable widgets of a frame ("health", "power"...)
--   * ELEMENTS : the positionable widgets, each with a default anchor
--                record and a resolver that finds it on a built frame.
--
-- The stored config for one element is a flat record:
--   { point = "LEFT", relTo = "health", relPoint = "LEFT", x = 6, y = 0 }
--
-- Registry.Apply turns that record into ClearAllPoints + SetPoint. Every
-- field is sanitised first: an invalid point string coming from a share
-- code would otherwise throw inside SetPoint and break the whole frame.
--
-- Scope note (AstralForge lot 1): `relTo` may only name a declared HOST.
-- Element-to-element anchoring needs a cycle guard and topological
-- ordering -- that lands with the canvas lots, and Registry.Apply is the
-- single place it will have to change.
--
-- No unit API is touched here, so no secret value can reach this file.
-- =====================================================================

local Forge = TomoMod_Forge
if not Forge then return end

Forge.Registry = Forge.Registry or {}
local R = Forge.Registry

local tonumber, type, pairs, ipairs = tonumber, type, pairs, ipairs
local tsort = table.sort

-- ---------------------------------------------------------------------
-- Valid anchor points (SetPoint throws on anything else)
-- ---------------------------------------------------------------------
R.POINTS = {
    "TOPLEFT", "TOP", "TOPRIGHT",
    "LEFT", "CENTER", "RIGHT",
    "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}

local VALID_POINT = {}
for _, p in ipairs(R.POINTS) do VALID_POINT[p] = true end

function R.IsPoint(p)
    return VALID_POINT[p] == true
end

-- ---------------------------------------------------------------------
-- Domain storage
-- ---------------------------------------------------------------------
local domains = {}

local function domain(name)
    local d = domains[name]
    if not d then
        d = { hosts = {}, hostOrder = {}, elements = {}, order = {}, sorted = nil }
        domains[name] = d
    end
    return d
end

-- desc = { id, labelKey, resolve(frame) -> widget|nil }
function R.DefineHost(domainName, desc)
    if type(desc) ~= "table" or type(desc.id) ~= "string" then return false end
    if type(desc.resolve) ~= "function" then return false end
    local d = domain(domainName)
    if not d.hosts[desc.id] then
        d.hostOrder[#d.hostOrder + 1] = desc.id
    end
    d.hosts[desc.id] = desc
    return true
end

-- desc = {
--   id         : stable key, also the store key
--   labelKey   : locale key for the GUI
--   order      : sort weight in listings (default 100)
--   anchorMode : "inside" (point and relPoint move together, the simple
--                GUI exposes a 9-point dropdown) or "fixed" (the pair is
--                part of the element's identity). The canvas ignores this
--                and always offers full freedom.
--   targets    : optional whitelist of target ids this element may anchor
--                to (hosts AND sibling elements). Leave nil for "anything
--                declared". This guards the edges the ENGINE creates and
--                the registry cannot see: BuildVisuals anchors the info
--                bar to the power bar, so power must be forbidden from
--                anchoring back to it or the client raises an anchor-family
--                error. User-created element-to-element edges are guarded
--                separately, by the cycle walk below.
--   default    : { point, relTo, relPoint, x, y }
--   resolve    : function(frame) -> widget|nil
-- }
function R.Define(domainName, desc)
    if type(desc) ~= "table" or type(desc.id) ~= "string" then return false end
    if type(desc.resolve) ~= "function" then return false end
    if type(desc.default) ~= "table" then return false end
    local d = domain(domainName)
    if not d.elements[desc.id] then
        d.order[#d.order + 1] = desc.id
    end
    desc.order = tonumber(desc.order) or 100
    desc.anchorMode = (desc.anchorMode == "inside") and "inside" or "fixed"
    if not R.KINDS[desc.kind] then desc.kind = "frame" end
    if type(desc.targets) == "table" then
        local set = {}
        for _, t in ipairs(desc.targets) do set[t] = true end
        desc._targetSet = set
    end
    d.elements[desc.id] = desc
    d.sorted = nil
    return true
end

-- Static whitelist check. No whitelist means "anything declared".
function R.TargetAllowed(desc, targetID)
    if type(desc) ~= "table" then return false end
    if not desc._targetSet then return true end
    return desc._targetSet[targetID] == true
end

-- ---------------------------------------------------------------------
-- Per-element properties
--
-- Beyond its anchor, an element carries a few visual overrides. Which ones
-- apply is a property of the WIDGET KIND, not a free choice: SetScale
-- exists on frames but not on regions, and SetFont only on font strings.
-- Declaring `kind` on the descriptor is what lets the registry apply the
-- right subset and lets the GUI show only knobs that do something.
--
-- Deliberately NOT here, and it is a design decision rather than an
-- omission: colour, visibility and size. All three are driven dynamically
-- by the modules themselves -- class colours, health colours, threat
-- state, the showName/showLevel toggles, raidIconSize. A registry override
-- would fight the engine on every update and lose, or win and break the
-- feature. They stay where the logic that owns them lives.
--
-- Every property is applied ABSOLUTELY, never as a delta, so re-running
-- ApplyAll any number of times converges on the same result. fontSize in
-- particular re-reads the family and flags the module just set and only
-- overrides the size, which is why a zero means "inherit".
-- ---------------------------------------------------------------------

R.KINDS = { frame = true, texture = true, fontstring = true }

local KIND_CAPS = {
    frame      = { alpha = true, scale = true },
    texture    = { alpha = true },
    fontstring = { alpha = true, fontSize = true },
}

R.PROP_LIMITS = {
    alpha    = { min = 0,   max = 1,  default = 1 },
    scale    = { min = 0.25, max = 4, default = 1 },
    -- 0 means "keep whatever the module computed".
    fontSize = { min = 6,   max = 64, default = 0 },
}

function R.Caps(desc)
    if type(desc) ~= "table" then return nil end
    return desc.caps or KIND_CAPS[desc.kind] or KIND_CAPS.frame
end

function R.HasProp(domainName, id, prop)
    local caps = R.Caps(R.Get(domainName, id))
    return caps ~= nil and caps[prop] == true
end

-- Ordered list of the properties this element supports, for the GUI.
function R.Props(domainName, id)
    local caps = R.Caps(R.Get(domainName, id))
    local out = {}
    if not caps then return out end
    for _, prop in ipairs({ "alpha", "scale", "fontSize" }) do
        if caps[prop] then out[#out + 1] = prop end
    end
    return out
end

local function clampProp(prop, value, fallback)
    local lim = R.PROP_LIMITS[prop]
    if not lim then return fallback end
    local v = tonumber(value)
    if not v then return fallback end
    -- fontSize keeps 0 as the "inherit" sentinel, outside the usable range.
    if prop == "fontSize" and v == 0 then return 0 end
    if v < lim.min then return lim.min end
    if v > lim.max then return lim.max end
    return v
end

-- ---------------------------------------------------------------------
-- Instanced elements
--
-- Everything above is a SINGLETON: one descriptor, one widget the module's
-- own factories already built. An instanced type is the opposite -- the
-- user asks for one, the registry builds it, and there can be several.
--
-- Store keys are "typeId:n". The counter is never reused after a delete,
-- so a stale reference in another record's relTo cannot silently re-point
-- at a different widget once the index comes round again.
--
-- Widgets live on the frame under `_forgeInstances`, not in the registry:
-- the registry is shared by every frame of a domain, so it must stay free
-- of per-frame state.
-- ---------------------------------------------------------------------

local INSTANCE_SEP = ":"

function R.DefineInstanced(domainName, desc)
    if type(desc) ~= "table" or type(desc.id) ~= "string" then return false end
    if type(desc.build) ~= "function" then return false end
    if type(desc.default) ~= "table" then return false end
    local d = domain(domainName)
    desc.instanced = true
    desc.max = tonumber(desc.max) or 8
    if not R.KINDS[desc.kind] then desc.kind = "frame" end
    d.types = d.types or {}
    d.typeOrder = d.typeOrder or {}
    if not d.types[desc.id] then d.typeOrder[#d.typeOrder + 1] = desc.id end
    d.types[desc.id] = desc
    return true
end

function R.ListTypes(domainName)
    local d = domains[domainName]
    if not d or not d.typeOrder then return {} end
    local out = {}
    for _, id in ipairs(d.typeOrder) do out[#out + 1] = d.types[id] end
    return out
end

-- "customText:3" -> "customText", 3
function R.SplitKey(key)
    if type(key) ~= "string" then return nil end
    local typeID, n = key:match("^(.-)" .. INSTANCE_SEP .. "(%d+)$")
    if not typeID then return nil end
    return typeID, tonumber(n)
end

function R.GetType(domainName, typeID)
    local d = domains[domainName]
    return d and d.types and d.types[typeID] or nil
end

-- Descriptor for any key, singleton or instance.
function R.Describe(domainName, key)
    local desc = R.Get(domainName, key)
    if desc then return desc end
    local typeID = R.SplitKey(key)
    return typeID and R.GetType(domainName, typeID) or nil
end

-- Instance keys present in `store`, sorted so the GUI order is stable.
function R.ListInstances(domainName, store)
    local out = {}
    if type(store) ~= "table" then return out end
    for key in pairs(store) do
        local typeID, n = R.SplitKey(key)
        local desc = typeID and R.GetType(domainName, typeID)
        if desc then out[#out + 1] = { key = key, typeID = typeID, index = n, desc = desc } end
    end
    tsort(out, function(a, b)
        if a.typeID ~= b.typeID then return a.typeID < b.typeID end
        return a.index < b.index
    end)
    return out
end

function R.CountInstances(domainName, store, typeID)
    local n = 0
    for _, inst in ipairs(R.ListInstances(domainName, store)) do
        if inst.typeID == typeID then n = n + 1 end
    end
    return n
end

-- Returns the new key, or nil plus a reason when the type is unknown or
-- already at its cap.
function R.AddInstance(domainName, store, typeID)
    local desc = R.GetType(domainName, typeID)
    if not desc or type(store) ~= "table" then return nil, "unknown" end
    if R.CountInstances(domainName, store, typeID) >= desc.max then
        return nil, "max"
    end

    -- Highest index ever used, not the count: deleting #2 of three must not
    -- make the next insert collide with #3.
    local highest = 0
    for key in pairs(store) do
        local t, n = R.SplitKey(key)
        if t == typeID and n > highest then highest = n end
    end

    local key = typeID .. INSTANCE_SEP .. (highest + 1)
    store[key] = R.DefaultFor(domainName, desc)
    return key
end

function R.RemoveInstance(domainName, store, key)
    if type(store) ~= "table" or store[key] == nil then return false end
    if not R.SplitKey(key) then return false end
    store[key] = nil

    -- Anything anchored to the departing element would dangle; send those
    -- back to their own default target rather than leave a broken anchor.
    for otherKey, rec in pairs(store) do
        if type(rec) == "table" and rec.relTo == key then
            local desc = R.Describe(domainName, otherKey)
            rec.relTo = desc and desc.default.relTo or nil
        end
    end
    return true
end

-- Builds (once) and returns the widget backing an instance key.
function R.ResolveInstance(domainName, key, frame)
    if not frame then return nil end
    local typeID = R.SplitKey(key)
    local desc = typeID and R.GetType(domainName, typeID)
    if not desc then return nil end

    local cache = rawget(frame, "_forgeInstances")
    if not cache then
        cache = {}
        frame._forgeInstances = cache
    end
    local widget = cache[key]
    if widget then return widget end

    local ok, built = pcall(desc.build, frame, key)
    if not ok or not built then return nil end
    cache[key] = built
    return built
end

-- Hides every built instance whose key is no longer in `store`. Called
-- after ApplyAll so a deleted element disappears without a reload.
function R.PruneInstances(domainName, frame, store)
    local cache = frame and rawget(frame, "_forgeInstances")
    if not cache then return 0 end
    local n = 0
    for key, widget in pairs(cache) do
        if type(store) ~= "table" or store[key] == nil then
            if widget.Hide then widget:Hide() end
            if widget.SetText then widget:SetText("") end
            n = n + 1
        end
    end
    return n
end

function R.Get(domainName, id)
    local d = domains[domainName]
    return d and d.elements[id] or nil
end

function R.GetHost(domainName, id)
    local d = domains[domainName]
    return d and d.hosts[id] or nil
end

-- Ordered array of element descriptors (stable: order then id).
function R.List(domainName)
    local d = domains[domainName]
    if not d then return {} end
    if d.sorted then return d.sorted end
    local out = {}
    for _, id in ipairs(d.order) do out[#out + 1] = d.elements[id] end
    tsort(out, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        return a.id < b.id
    end)
    d.sorted = out
    return out
end

-- Ordered array of host descriptors.
function R.ListHosts(domainName)
    local d = domains[domainName]
    if not d then return {} end
    local out = {}
    for _, id in ipairs(d.hostOrder) do out[#out + 1] = d.hosts[id] end
    return out
end

-- ---------------------------------------------------------------------
-- Records
-- ---------------------------------------------------------------------
-- Fresh record from a descriptor, singleton or instance type alike.
function R.DefaultFor(domainName, desc)
    if type(desc) ~= "table" then return nil end
    local dft = desc.default
    local out = {
        point    = dft.point,
        relTo    = dft.relTo,
        relPoint = dft.relPoint,
        x        = tonumber(dft.x) or 0,
        y        = tonumber(dft.y) or 0,
    }
    -- Only the properties this widget kind can actually honour: an alpha on
    -- a font string is meaningful, a scale is not, and writing a key nobody
    -- reads would just be noise in the saved variables.
    local caps = R.Caps(desc)
    for prop, lim in pairs(R.PROP_LIMITS) do
        if caps[prop] then
            local d = dft[prop]
            out[prop] = clampProp(prop, d ~= nil and d or lim.default, lim.default)
        end
    end
    -- Free-form payload owned by the instance type (a custom text template,
    -- for instance). The registry stores and copies it, never interprets it.
    if desc.instanced and dft.text ~= nil then out.text = dft.text end
    return out
end

function R.Default(domainName, id)
    return R.DefaultFor(domainName, R.Describe(domainName, id))
end

-- Returns a NEW sanitised record; every invalid field falls back to the
-- descriptor default rather than to an arbitrary value, so a partially
-- corrupt import degrades to the shipped layout instead of erroring.
function R.Sanitize(domainName, id, cfg)
    local desc = R.Describe(domainName, id)
    if not desc then return nil end
    local out = R.Default(domainName, id)
    if type(cfg) ~= "table" then return out end

    if VALID_POINT[cfg.point] then out.point = cfg.point end
    if VALID_POINT[cfg.relPoint] then out.relPoint = cfg.relPoint end

    if type(cfg.relTo) == "string" and R.IsTarget(domainName, cfg.relTo)
       and cfg.relTo ~= id
       and R.TargetAllowed(desc, cfg.relTo) then
        out.relTo = cfg.relTo
    end

    local x, y = tonumber(cfg.x), tonumber(cfg.y)
    if x then out.x = x end
    if y then out.y = y end

    local caps = R.Caps(desc)
    for prop in pairs(R.PROP_LIMITS) do
        if caps[prop] and cfg[prop] ~= nil then
            out[prop] = clampProp(prop, cfg[prop], out[prop])
        end
    end

    if desc.instanced and type(cfg.text) == "string" then
        out.text = cfg.text
    end

    return out
end

-- Fills every missing element entry of `store` with its default. Existing
-- entries are sanitised IN PLACE so a bad value is corrected once and the
-- corrected value is what gets saved.
function R.Ensure(domainName, store)
    if type(store) ~= "table" then return store end
    for _, desc in ipairs(R.List(domainName)) do
        store[desc.id] = R.Sanitize(domainName, desc.id, store[desc.id])
    end
    for _, inst in ipairs(R.ListInstances(domainName, store)) do
        store[inst.key] = R.Sanitize(domainName, inst.key, store[inst.key])
    end
    -- Sanitize only sees one record at a time, so a loop spanning several
    -- entries survives it. Repair the graph once every entry exists.
    R.BreakCycles(domainName, store)
    return store
end

-- ---------------------------------------------------------------------
-- Anchor targets
--
-- `relTo` names either a declared HOST (a structural widget the module's
-- own factories position: the frame, the health bar...) or a sibling
-- ELEMENT. The two live in one id space on purpose: in the unit frame
-- domain "power" is both a host and an element, and it is the same widget
-- either way. Hosts win the lookup, and a static test asserts the shared
-- ids resolve identically.
--
-- Two different hazards produce anchor-family errors, guarded separately:
--
--   * Edges the ENGINE creates, invisible to the registry (BuildVisuals
--     anchors the info bar to the power bar). Guarded statically by
--     `desc.targets`, declared by whoever wrote the descriptors.
--
--   * Edges the USER creates by pointing one element at another. Guarded
--     dynamically by the walk below, because they only exist in the store.
--
-- Note there is deliberately NO topological sort. SetPoint builds a live
-- relationship: re-anchoring a target drags its dependants along on the
-- client's own layout pass, so application order does not affect the
-- result. Only cycles are fatal, and those are what we reject.
-- ---------------------------------------------------------------------

-- Is `targetID` a declared anchor target at all (host or element)?
function R.IsTarget(domainName, targetID)
    local d = domains[domainName]
    if not d or type(targetID) ~= "string" then return false end
    if (d.hosts[targetID] or d.elements[targetID]) ~= nil then return true end
    -- An instance is a legitimate anchor target too, but only its TYPE can
    -- be checked here; whether that particular instance exists is a
    -- question for the store, answered at resolution time.
    local typeID = R.SplitKey(targetID)
    return typeID ~= nil and R.GetType(domainName, typeID) ~= nil
end

-- Resolve `targetID` to a widget on `frame`. Hosts first: when an id is
-- both, the host descriptor is the structural definition.
function R.ResolveTarget(domainName, targetID, frame)
    local d = domains[domainName]
    if not d or type(targetID) ~= "string" then return nil end
    local desc = d.hosts[targetID] or d.elements[targetID]
    if not desc then
        if R.SplitKey(targetID) then
            return R.ResolveInstance(domainName, targetID, frame)
        end
        return nil
    end
    local ok, widget = pcall(desc.resolve, frame)
    if not ok then return nil end
    return widget
end

-- Backwards-compatible alias: hosts are targets.
function R.ResolveHost(domainName, hostID, frame)
    return R.ResolveTarget(domainName, hostID, frame)
end

-- Follow relTo from `startID` and report whether the chain comes back to
-- `startID`. `override` lets the caller test a candidate edge without
-- writing it, which is how the GUI filters its dropdown.
--
-- Only ELEMENT hops are followed: a pure host is a root, positioned by the
-- module's factories and never by us, so a chain that reaches one ends.
local function chainCycles(domainName, store, startID, overrideID, overrideTo)
    local d = domains[domainName]
    if not d then return false end

    local seen = {}
    local cur  = startID
    local hops = 0
    while cur do
        if seen[cur] then return true end
        seen[cur] = true

        hops = hops + 1
        if hops > 256 then return true end  -- paranoia: never spin forever

        local nextID
        if cur == overrideID then
            nextID = overrideTo
        else
            local rec = store and store[cur]
            nextID = type(rec) == "table" and rec.relTo or nil
            if nextID == nil then
                local desc = R.Describe(domainName, cur)
                nextID = desc and desc.default.relTo or nil
            end
        end

        -- Reaching a pure host terminates the chain; elements AND live
        -- instances continue it.
        local continues = (nextID ~= nil)
            and (d.elements[nextID] ~= nil
                 or (store and store[nextID] ~= nil and R.SplitKey(nextID) ~= nil))
        if not continues then return false end
        if nextID == startID then return true end
        cur = nextID
    end
    return false
end

-- Would pointing `id` at `targetID` close a loop? Self-reference counts.
function R.WouldCycle(domainName, store, id, targetID)
    if id == targetID then return true end
    local d = domains[domainName]
    if not d then return false end
    local isElement  = d.elements[targetID] ~= nil
    local isInstance = R.SplitKey(targetID) ~= nil
        and store ~= nil and store[targetID] ~= nil
    if not (isElement or isInstance) then return false end
    return chainCycles(domainName, store, id, id, targetID)
end

-- Target descriptors this element may anchor to, hosts first then sibling
-- elements, filtered by the static whitelist AND by cycle safety against
-- the CURRENT store. Each entry is { id, labelKey, kind }.
function R.AllowedTargets(domainName, id, store)
    local desc = R.Describe(domainName, id)
    local out = {}
    if not desc then return out end

    for _, host in ipairs(R.ListHosts(domainName)) do
        if R.TargetAllowed(desc, host.id) then
            out[#out + 1] = { id = host.id, labelKey = host.labelKey, kind = "host" }
        end
    end

    local d = domains[domainName]
    for _, other in ipairs(R.List(domainName)) do
        -- Skip ids already offered as a host: same widget, one entry.
        if other.id ~= id and not (d and d.hosts[other.id])
           and R.TargetAllowed(desc, other.id)
           and not R.WouldCycle(domainName, store, id, other.id) then
            out[#out + 1] = { id = other.id, labelKey = other.labelKey, kind = "element" }
        end
    end

    for _, inst in ipairs(R.ListInstances(domainName, store)) do
        if inst.key ~= id
           and R.TargetAllowed(desc, inst.key)
           and not R.WouldCycle(domainName, store, id, inst.key) then
            out[#out + 1] = {
                id       = inst.key,
                labelKey = inst.desc.labelKey,
                kind     = "element",
                index    = inst.index,
            }
        end
    end
    return out
end

-- Break any cycle present in `store`. Deterministic by construction: the
-- registry's own stable order decides which edge gives way, and the loser
-- falls back to its descriptor default. Only corrupt or hand-edited data
-- reaches this -- the GUI cannot create a cycle, since AllowedTargets
-- never offers one.
function R.BreakCycles(domainName, store)
    if type(store) ~= "table" then return 0 end
    local broken = 0
    local function repair(key, desc)
        local rec = store[key]
        if type(rec) == "table" and chainCycles(domainName, store, key) then
            rec.relTo = desc.default.relTo
            broken = broken + 1
        end
    end
    for _, desc in ipairs(R.List(domainName)) do repair(desc.id, desc) end
    for _, inst in ipairs(R.ListInstances(domainName, store)) do
        repair(inst.key, inst.desc)
    end
    -- A record may also point at an instance that no longer exists (the
    -- store was hand-edited, or a share code arrived with fewer elements).
    for key, rec in pairs(store) do
        if type(rec) == "table" and type(rec.relTo) == "string"
           and R.SplitKey(rec.relTo) and store[rec.relTo] == nil then
            local desc = R.Describe(domainName, key)
            if desc then rec.relTo = desc.default.relTo end
        end
    end
    return broken
end

-- Places ONE element. Returns true when the widget was actually anchored.
function R.Apply(domainName, id, frame, store)
    local desc = R.Describe(domainName, id)
    if not desc or not frame then return false end

    local widget
    if desc.instanced then
        widget = R.ResolveInstance(domainName, id, frame)
    else
        local ok, w = pcall(desc.resolve, frame)
        widget = ok and w or nil
    end
    if not widget then return false end

    local cfg    = R.Sanitize(domainName, id, store and store[id])
    local target = R.ResolveTarget(domainName, cfg.relTo, frame)
    if not target then
        -- The configured target is missing on this frame (power bar turned
        -- off, for instance). Fall back to the descriptor default rather
        -- than leaving the widget unanchored.
        cfg.relTo = desc.default.relTo
        target = R.ResolveTarget(domainName, cfg.relTo, frame)
        if not target then return false end
    end

    -- Last line of defence. A widget anchored to itself is an immediate
    -- client error, and resolution can land there when an element and a
    -- host share an id.
    if target == widget then return false end

    widget:ClearAllPoints()
    widget:SetPoint(cfg.point, target, cfg.relPoint, cfg.x, cfg.y)
    R.ApplyProps(domainName, id, widget, cfg)
    return true
end

-- Applies the visual overrides. Split out so a module can refresh them
-- without re-anchoring, and so the tests can exercise them in isolation.
function R.ApplyProps(domainName, id, widget, cfg)
    local desc = R.Describe(domainName, id)
    if not desc or not widget or type(cfg) ~= "table" then return false end
    local caps = R.Caps(desc)

    if caps.alpha and cfg.alpha and widget.SetAlpha then
        widget:SetAlpha(clampProp("alpha", cfg.alpha, 1))
    end

    if caps.scale and cfg.scale and widget.SetScale then
        widget:SetScale(clampProp("scale", cfg.scale, 1))
    end

    -- Absolute override, so applying twice is applying once. The family and
    -- flags come from whatever the module last set, which is why this has
    -- to run AFTER the module's own SetFont and not instead of it.
    if caps.fontSize and widget.GetFont and widget.SetFont then
        local size = clampProp("fontSize", cfg.fontSize, 0)
        if size and size > 0 then
            local family, _, flags = widget:GetFont()
            if family then widget:SetFont(family, size, flags) end
        end
    end
    return true
end

-- Places every registered element of a domain. Returns the count applied.
function R.ApplyAll(domainName, frame, store)
    local n = 0
    for _, desc in ipairs(R.List(domainName)) do
        if R.Apply(domainName, desc.id, frame, store) then n = n + 1 end
    end
    for _, inst in ipairs(R.ListInstances(domainName, store)) do
        if R.Apply(domainName, inst.key, frame, store) then n = n + 1 end
    end
    R.PruneInstances(domainName, frame, store)
    return n
end

-- Test seam: drops a whole domain (never called by the addon itself).
function R.Reset(domainName)
    domains[domainName] = nil
end

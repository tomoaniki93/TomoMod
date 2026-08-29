-- =====================================
-- Shared/HealerIndicators.lua — configurable healer aura indicators
-- Party/Raid profiles, per-spell anchors, LoadOnDemand studio bridge.
--
-- [12.1] Midnight-safe: this module never reads aura data. Each selected
-- spell owns one CustomAuraContainerTemplate group narrowed with
-- includeSpellIDs, so the client decides whether the aura is present and
-- drives icon / cooldown / count. Nothing here compares a secret value.
--
-- PERF CONTRACT -- UpdateUnit sits on the UNIT_AURA path, once per visible
-- cell per event. Everything it needs is precomputed and cached behind a
-- revision counter; the function itself must not allocate a table, sort,
-- or walk the spell database. Any edit that reintroduces one of those in
-- UpdateUnit / IsModeActive is a regression, not a refactor.
-- =====================================

TomoMod_HealerIndicators = TomoMod_HealerIndicators or {}
local HI = TomoMod_HealerIndicators

-- AuraContainer.lua is <Include>d by Shared.xml before this <Script>, and
-- AuraData.lua is the <Script> immediately above it, so both globals are
-- published by the time this chunk runs.
local AD = TomoMod_AuraData
local AC = TomoMod_AuraContainer

local max, min, sort = math.max, math.min, table.sort
local pairs, ipairs, type, tonumber = pairs, ipairs, type, tonumber
local wipe = wipe

HI.SCHEMA_VERSION = 1
HI.ADDON_NAME     = "TomoMod_HealerStudio"
HI.STUDIO_GLOBAL  = "TomoMod_HealerStudio"
HI.CLASS_ORDER    = { "PRIEST", "DRUID", "PALADIN", "SHAMAN", "MONK", "EVOKER" }

-- Hoisted: the normalisation loop below is reachable from the aura path on
-- the first call after a profile swap, and a table constructor there would
-- be garbage generated inside combat.
local MODES = { "party", "raid" }
local EMPTY = {}

-- Stable presentation order for the studio list. AuraData remains the
-- source of truth: GetSpellsForClass filters these ids against
-- AD.HEALER_HOTS and appends anything added there but not listed here.
HI.SPELL_ORDER = {
    PRIEST  = { 139, 17, 194384, 41635, 77489, 214206 },
    DRUID   = { 774, 8936, 33763, 48438, 155777, 207386, 200389, 391891, 102342 },
    PALADIN = { 53563, 156910, 223306, 287280, 388013 },
    SHAMAN  = { 61295, 974, 382024, 383009, 157153 },
    MONK    = { 119611, 124682, 325209, 191840, 116849 },
    EVOKER  = { 366155, 376788, 355941, 378001, 373267, 363502 },
}

-- Category is a display grouping for the studio list only; it never gates
-- behaviour. Spell names and icons come from the client, so nothing here
-- duplicates a localised string that would rot at a patch.
HI.SPELL_CATEGORY = {
    [139]    = "hot",      [17]     = "shield",   [194384] = "marker",
    [41635]  = "hot",      [77489]  = "hot",      [214206] = "marker",

    [774]    = "hot",      [8936]   = "hot",      [33763]  = "hot",
    [48438]  = "hot",      [155777] = "hot",      [207386] = "hot",
    [200389] = "hot",      [391891] = "hot",      [102342] = "external",

    [53563]  = "beacon",   [156910] = "beacon",   [223306] = "marker",
    [287280] = "marker",   [388013] = "external",

    [61295]  = "hot",      [974]    = "shield",   [382024] = "hot",
    [383009] = "marker",   [157153] = "marker",

    [119611] = "hot",      [124682] = "hot",      [325209] = "hot",
    [191840] = "hot",      [116849] = "external",

    [366155] = "hot",      [376788] = "marker",   [355941] = "hot",
    [378001] = "hot",      [373267] = "marker",   [363502] = "hot",
}

HI.CATEGORY_ORDER = { "hot", "shield", "beacon", "marker", "external" }

HI.ANCHOR_POINTS = {
    "TOPLEFT", "TOP", "TOPRIGHT",
    "LEFT", "CENTER", "RIGHT",
    "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}

-- Fresh entries are spread around the cell rather than stacked, so a
-- starter preset is readable before the player has moved anything.
local DEFAULT_POINTS = {
    { point = "TOPLEFT",     x = 3,  y = -3 },
    { point = "TOPRIGHT",    x = -3, y = -3 },
    { point = "BOTTOMLEFT",  x = 3,  y = 3 },
    { point = "BOTTOMRIGHT", x = -3, y = 3 },
    { point = "TOP",         x = 0,  y = -3 },
    { point = "BOTTOM",      x = 0,  y = 3 },
    { point = "LEFT",        x = 3,  y = 0 },
    { point = "RIGHT",       x = -3, y = 0 },
    { point = "CENTER",      x = 0,  y = 0 },
}

local function DefaultPoint(index)
    local p = DEFAULT_POINTS[((index - 1) % #DEFAULT_POINTS) + 1]
    return p.point, p.x, p.y
end

-- Published: the studio's size slider must not carry its own copy of the
-- bounds the runtime clamps to.
HI.MIN_SIZE, HI.MAX_SIZE = 6, 30
local MIN_SIZE, MAX_SIZE = HI.MIN_SIZE, HI.MAX_SIZE

local function ClampSize(v, fallback)
    return max(MIN_SIZE, min(MAX_SIZE, tonumber(v) or fallback))
end

local function GetLegacySize(mode)
    local db = TomoModDB and TomoModDB[mode == "raid" and "raidFrames" or "partyFrames"]
    if db and tonumber(db.hotSize) then return tonumber(db.hotSize) end
    return mode == "raid" and 10 or 12
end

-- ---------------------------------------------------------------------
-- Memoised spell lists
--
-- AD.HEALER_HOTS is authored at load and never mutates, so the ordered
-- list per class is built once. The previous shape rebuilt three tables
-- and ran a sort inside UpdateUnit -- roughly eight allocations per cell
-- per aura event, which in a 20-man pull is thousands per second.
-- ---------------------------------------------------------------------
local spellLists = {}

function HI.GetSpellsForClass(class)
    if not class then return EMPTY end
    local cached = spellLists[class]
    if cached then return cached end

    local source = AD and AD.HEALER_HOTS and AD.HEALER_HOTS[class]
    if type(source) ~= "table" then
        spellLists[class] = EMPTY
        return EMPTY
    end

    local result, seen = {}, {}
    for _, spellID in ipairs(HI.SPELL_ORDER[class] or EMPTY) do
        if source[spellID] then
            result[#result + 1] = spellID
            seen[spellID] = true
        end
    end

    local extras
    for spellID in pairs(source) do
        if not seen[spellID] then
            extras = extras or {}
            extras[#extras + 1] = spellID
        end
    end
    if extras then
        sort(extras)
        for _, spellID in ipairs(extras) do result[#result + 1] = spellID end
    end

    spellLists[class] = result
    return result
end

function HI.IsHealerClass(class)
    return (class and AD and AD.HEALER_HOTS and type(AD.HEALER_HOTS[class]) == "table") and true or false
end

function HI.GetSpellDisplay(spellID)
    local name, texture
    if C_Spell then
        if C_Spell.GetSpellName then
            local ok, v = pcall(C_Spell.GetSpellName, spellID)
            if ok then name = v end
        end
        if C_Spell.GetSpellTexture then
            local ok, v = pcall(C_Spell.GetSpellTexture, spellID)
            if ok then texture = v end
        end
    end
    -- No English fallback table: an id the client cannot name is one that
    -- no longer exists, and hardcoding a stale name would be worse than
    -- showing the id. The studio re-queries on every refresh, so a name
    -- that was merely uncached fills itself in.
    return name or ("#" .. tostring(spellID)), texture or 134400,
        HI.SPELL_CATEGORY[spellID] or "hot"
end

-- ---------------------------------------------------------------------
-- Player state
-- ---------------------------------------------------------------------
local cachedPlayerClass
local cachedHealerSpec

function HI.GetPlayerClass()
    if not cachedPlayerClass then
        local _, class = UnitClass("player")
        cachedPlayerClass = class
    end
    return cachedPlayerClass
end

function HI.IsHealerSpec()
    if cachedHealerSpec ~= nil then return cachedHealerSpec end
    -- Same shape as CDF_Watch / ClassReminder: C_SpecializationInfo is the
    -- Midnight home of these, the globals are the compatibility path.
    local getIdx  = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
    local getRole = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationRole) or GetSpecializationRole
    if not getIdx or not getRole then
        cachedHealerSpec = true
        return true
    end
    local index = getIdx()
    cachedHealerSpec = (index and getRole(index) == "HEALER") and true or false
    return cachedHealerSpec
end

-- ---------------------------------------------------------------------
-- Database
--
-- revision is bumped by every structural change (normalisation, a studio
-- edit, a profile swap). The per-mode active list and the per-frame record
-- sweep are both keyed on it, which is what keeps UpdateUnit allocation
-- free between edits.
-- ---------------------------------------------------------------------
local rootRef
local revision = 0

function HI.Invalidate()
    revision = revision + 1
end

local function Normalize(root)
    root.schemaVersion = HI.SCHEMA_VERSION
    if root.onlyHealerSpec == nil then root.onlyHealerSpec = true end

    for _, mode in ipairs(MODES) do
        local modeDB = root[mode]
        if type(modeDB) ~= "table" then
            modeDB = {}
            root[mode] = modeDB
        end
        if modeDB.enabled == nil then modeDB.enabled = false end
        if type(modeDB.classes) ~= "table" then modeDB.classes = {} end
        if not tonumber(modeDB.defaultSize) then modeDB.defaultSize = GetLegacySize(mode) end
    end
end

-- Fast path is a single table read and one identity compare. A profile
-- switch replaces TomoModDB.healerStudio wholesale, so the compare is also
-- what detects it -- no event hook needed.
local function Root()
    local db = TomoModDB
    if not db then return nil end

    local root = db.healerStudio
    if root ~= nil and root == rootRef then return root end

    if type(root) ~= "table" then
        root = {}
        db.healerStudio = root
    end
    Normalize(root)
    rootRef = root
    revision = revision + 1
    return root
end

function HI.GetRootDB()
    return Root()
end

function HI.GetModeDB(mode)
    local root = Root()
    if not root then return nil end
    return root[mode == "raid" and "raid" or "party"]
end

-- Creates any missing per-spell entry and repairs malformed ones. Called
-- from the studio and from the active-list rebuild, never per aura event.
function HI.EnsureClass(mode, class)
    local modeDB = HI.GetModeDB(mode)
    if not modeDB or not HI.IsHealerClass(class) then return nil end

    local classDB = modeDB.classes[class]
    if type(classDB) ~= "table" then
        classDB = { spells = {} }
        modeDB.classes[class] = classDB
    end
    if type(classDB.spells) ~= "table" then classDB.spells = {} end

    local defaultSize = ClampSize(modeDB.defaultSize, GetLegacySize(mode))
    for index, spellID in ipairs(HI.GetSpellsForClass(class)) do
        local entry = classDB.spells[spellID]
        if type(entry) ~= "table" then
            local point, x, y = DefaultPoint(index)
            classDB.spells[spellID] = {
                enabled = false, point = point, x = x, y = y, size = defaultSize,
            }
        else
            if entry.enabled == nil then entry.enabled = false end
            if not entry.point then
                entry.point, entry.x, entry.y = DefaultPoint(index)
            end
            entry.x    = tonumber(entry.x) or 0
            entry.y    = tonumber(entry.y) or 0
            entry.size = ClampSize(entry.size, defaultSize)
        end
    end

    return classDB
end

function HI.GetEntry(mode, class, spellID)
    local classDB = HI.EnsureClass(mode, class)
    return classDB and classDB.spells and classDB.spells[spellID] or nil
end

function HI.HasEnabledSpells(mode, class)
    local classDB = HI.EnsureClass(mode, class)
    if not classDB then return false end
    for _, spellID in ipairs(HI.GetSpellsForClass(class)) do
        local entry = classDB.spells[spellID]
        if entry and entry.enabled then return true end
    end
    return false
end

-- ---------------------------------------------------------------------
-- Editing helpers (studio-facing)
-- ---------------------------------------------------------------------
function HI.ResetSpellPosition(mode, class, spellID)
    local entry = HI.GetEntry(mode, class, spellID)
    if not entry then return end
    for index, id in ipairs(HI.GetSpellsForClass(class)) do
        if id == spellID then
            entry.point, entry.x, entry.y = DefaultPoint(index)
            HI.Invalidate()
            return
        end
    end
end

function HI.ResetClass(mode, class, keepEnabled)
    local classDB = HI.EnsureClass(mode, class)
    if not classDB then return end
    local defaultSize = ClampSize(HI.GetModeDB(mode).defaultSize, GetLegacySize(mode))
    for index, spellID in ipairs(HI.GetSpellsForClass(class)) do
        local entry = classDB.spells[spellID]
        local wasEnabled = entry and entry.enabled
        local point, x, y = DefaultPoint(index)
        classDB.spells[spellID] = {
            enabled = (keepEnabled and wasEnabled) or false,
            point = point, x = x, y = y, size = defaultSize,
        }
    end
    HI.Invalidate()
end

function HI.ApplyStarterPreset(mode, class)
    local classDB = HI.EnsureClass(mode, class)
    if not classDB then return end
    -- Raid cells are half the width of a party cell, so the preset seeds
    -- one slot fewer there rather than shipping a layout that overlaps out
    -- of the box.
    local count = (mode == "raid") and 3 or 4
    for index, spellID in ipairs(HI.GetSpellsForClass(class)) do
        local entry = classDB.spells[spellID]
        entry.enabled = index <= count
        entry.point, entry.x, entry.y = DefaultPoint(index)
    end
    HI.Invalidate()
end

function HI.SetModeEnabled(mode, enabled, class)
    local modeDB = HI.GetModeDB(mode)
    if not modeDB then return end
    modeDB.enabled = enabled and true or false
    class = class or HI.GetPlayerClass()
    -- Turning the profile on with nothing selected would blank the cells:
    -- seed a readable default instead of an empty layout.
    if enabled and HI.IsHealerClass(class) and not HI.HasEnabledSpells(mode, class) then
        HI.ApplyStarterPreset(mode, class)
    end
    HI.Invalidate()
    HI.RefreshAll(mode)
end

function HI.IsModeActive(mode)
    local root = Root()
    if not root then return false end

    local modeDB = root[mode == "raid" and "raid" or "party"]
    if not modeDB or not modeDB.enabled then return false end
    if not HI.IsHealerClass(HI.GetPlayerClass()) then return false end
    if root.onlyHealerSpec ~= false and not HI.IsHealerSpec() then return false end
    return true
end

-- ---------------------------------------------------------------------
-- Active list cache
--
-- One parallel-array record per mode: rebuilt only when the revision or
-- the player class changes, reused verbatim on every aura event in between.
-- ---------------------------------------------------------------------
local activeCache = {
    party = { rev = -1, class = false, n = 0, ids = {}, entries = {}, set = {} },
    raid  = { rev = -1, class = false, n = 0, ids = {}, entries = {}, set = {} },
}

local function ActiveList(mode, class)
    local c = activeCache[mode]
    if c.rev == revision and c.class == class then return c end

    wipe(c.ids); wipe(c.entries); wipe(c.set)
    c.n = 0

    local classDB = HI.EnsureClass(mode, class)
    if classDB then
        for _, spellID in ipairs(HI.GetSpellsForClass(class)) do
            local entry = classDB.spells[spellID]
            if entry and entry.enabled then
                local n = c.n + 1
                c.n, c.ids[n], c.entries[n], c.set[spellID] = n, spellID, entry, true
            end
        end
    end

    -- EnsureClass may have normalised something and bumped the revision;
    -- stamp the current one so the next event hits the cache.
    c.rev, c.class = revision, class
    return c
end

-- ---------------------------------------------------------------------
-- Runtime containers
-- ---------------------------------------------------------------------
local function GetFontForMode(mode)
    local frameDB = TomoModDB and TomoModDB[mode == "raid" and "raidFrames" or "partyFrames"]
    return (frameDB and frameDB.font) or STANDARD_TEXT_FONT
end

local function GetFrameCache(f, mode)
    local host = f._tomoHealerIndicators
    if type(host) ~= "table" then
        host = {}
        f._tomoHealerIndicators = host
    end
    local cache = host[mode]
    if type(cache) ~= "table" then
        cache = { rev = -1, records = {} }
        host[mode] = cache
    end
    return cache
end

local function DeactivateRecord(record)
    if not record or not record.container then return end
    if record.boundUnit ~= nil and AC then
        AC.SetUnit(record.container, nil)
        record.boundUnit = nil
    end
    record.container:Hide()
    record.active = false
end

function HI.HideFrame(f, mode)
    local host = f and f._tomoHealerIndicators
    if type(host) ~= "table" then return end
    local cache = host[mode]
    if type(cache) ~= "table" then return end
    for _, record in pairs(cache.records) do DeactivateRecord(record) end
end

local function ApplyRecordGeometry(record, host, entry)
    if not record or not record.container or not host or not entry then return end

    local size = ClampSize(entry.size, 12)
    if record.size ~= size then
        if AC.Relayout then AC.Relayout(record.container, { size = size, max = 1 }) end
        record.size = size
    end

    local point = entry.point or "TOPLEFT"
    local x, y = tonumber(entry.x) or 0, tonumber(entry.y) or 0
    if record.point ~= point or record.x ~= x or record.y ~= y then
        record.container:ClearAllPoints()
        record.container:SetPoint(point, host, point, x, y)
        record.point, record.x, record.y = point, x, y
    end
end

local function EnsureRecord(f, cache, mode, spellID, entry)
    local record = cache.records[spellID]
    if record and record.container then
        ApplyRecordGeometry(record, f.content, entry)
        return record
    end
    if not AC or not AC.Create then return nil end

    local size = ClampSize(entry.size, GetLegacySize(mode))
    local container = AC.Create(f.content, {
        key             = "healer_" .. mode .. "_" .. spellID,
        size            = size,
        max             = 1,
        font            = GetFontForMode(mode),
        harmful         = false,
        onlyMine        = true,
        tooltips        = false,
        showDuration    = true,
        includeSpellIDs = { [spellID] = true },
        durationPoint   = "CENTER",
        durationX       = 0,
        durationY       = 0,
        durationColor   = { 1, 1, 1, 1 },
        point           = { "CENTER", f.content, "CENTER", 0, 0 },
    })
    if not container then return nil end

    if container.SetFrameLevel and f.content.GetFrameLevel then
        pcall(container.SetFrameLevel, container, f.content:GetFrameLevel() + 20)
    end

    record = { container = container, size = size, boundUnit = nil, active = false }
    cache.records[spellID] = record
    ApplyRecordGeometry(record, f.content, entry)
    return record
end

-- Builds every container a cell needs while out of combat, so the first
-- pull does not pay for 40 cells worth of frame creation at once (and does
-- not run into the engine refusing a SetSize while auras are restricted).
function HI.Prewarm(f, mode)
    if not f or not f.content then return end
    if not HI.IsModeActive(mode) then return end
    local cache = GetFrameCache(f, mode)
    local list = ActiveList(mode, HI.GetPlayerClass())
    for i = 1, list.n do
        EnsureRecord(f, cache, mode, list.ids[i], list.entries[i])
    end
end

-- Returns true when the advanced profile owns this cell: the caller then
-- skips its legacy HoT row entirely. One IsModeActive per update, not two.
function HI.UpdateUnit(f, mode)
    if not f then return false end
    mode = (mode == "raid") and "raid" or "party"

    if not AC or not HI.IsModeActive(mode) then
        HI.HideFrame(f, mode)
        return false
    end
    if not f.content then return false end

    local unit = f.unit
    if not unit or not UnitExists(unit) then
        HI.HideFrame(f, mode)
        return true
    end

    local cache = GetFrameCache(f, mode)
    local list  = ActiveList(mode, HI.GetPlayerClass())

    -- Retire containers only when the selection actually changed. Objects
    -- are kept and reused when the checkbox is turned back on.
    if cache.rev ~= list.rev then
        for spellID, record in pairs(cache.records) do
            if not list.set[spellID] then DeactivateRecord(record) end
        end
        cache.rev = list.rev
    end

    for i = 1, list.n do
        local record = EnsureRecord(f, cache, mode, list.ids[i], list.entries[i])
        if record and record.container then
            record.container:Show()
            record.active = true
            if record.boundUnit ~= unit then
                AC.SetUnit(record.container, unit)
                record.boundUnit = unit
            end
        end
    end

    return true
end

function HI.RefreshAll(mode)
    local function RefreshMode(key, module, legacy, legacyMethod)
        if not module or type(module.frames) ~= "table" then return end
        local active = HI.IsModeActive(key)
        for _, f in pairs(module.frames) do
            if f then
                if active then
                    HI.UpdateUnit(f, key)
                    if not InCombatLockdown() then HI.Prewarm(f, key) end
                    if f.hotContainer then f.hotContainer:Hide() end
                else
                    HI.HideFrame(f, key)
                    if f.hotContainer and legacy then legacy[legacyMethod](f) end
                end
            end
        end
    end

    if mode ~= "raid" then
        RefreshMode("party", TomoMod_PartyFrames, TomoMod_PartyHoTs, "UpdateUnit")
    end
    if mode ~= "party" then
        RefreshMode("raid", TomoMod_RaidFrames, TomoMod_RaidAuras, "UpdateHoTs")
    end
end

-- Single entry point for the studio: a layout edit changes both what the
-- active list holds and what the live cells draw, and splitting the two
-- was how an edit could land in the database without reaching the frames.
function HI.Commit(mode)
    HI.Invalidate()
    HI.RefreshAll(mode)
end

-- Geometry-only variant. Size / anchor / offset live in the very entry
-- tables the active list already holds by reference, so the cached list
-- stays valid: pushing the change to the frames is enough. Used by the
-- studio sliders, which fire on every drag tick.
function HI.Touch(mode)
    HI.RefreshAll(mode)
end

-- ---------------------------------------------------------------------
-- Studio bridge
--
-- Loading, self-healing a DISABLED sub-addon and reporting a locale-
-- independent failure reason all live in Forge.Studio.Launch; this is only
-- the combat gate and the mode argument.
-- ---------------------------------------------------------------------
function HI.OpenStudio(mode)
    mode = (mode == "raid") and "raid" or "party"

    local Forge = TomoMod_Forge
    if not (Forge and Forge.Studio and Forge.Studio.Launch) then
        print("|cff2ed884TomoMod|r : Forge.Studio indisponible, Healer Studio ne peut pas s'ouvrir.")
        return false
    end

    return Forge.Studio.Launch({
        addon  = HI.ADDON_NAME,
        global = HI.STUDIO_GLOBAL,
        label  = "Healer Studio",
        arg    = mode,
    })
end

function TomoMod_OpenHealerStudio(mode)
    return HI.OpenStudio(mode)
end

-- A container creation can be refused while aura data is restricted, and
-- the spec gate has to be re-evaluated after a spec change. Re-run once on
-- each of those rather than polling.
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("GROUP_ROSTER_UPDATE")
watcher:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        if unit and unit ~= "player" then return end
        cachedHealerSpec = nil
    elseif event == "PLAYER_ENTERING_WORLD" then
        cachedHealerSpec = nil
        cachedPlayerClass = nil
    end
    HI.RefreshAll()
end)

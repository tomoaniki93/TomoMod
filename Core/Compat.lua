-- =====================================================================
-- Compat.lua — Which client is running, and what must not run on it
-- ---------------------------------------------------------------------
-- WoW: Forever is the third branch of the game: vanilla-era content on
-- the modern client. For an addon that matters more than the name
-- suggests.
--
--   * It is NOT a Classic client. WOW_PROJECT_ID reports
--     WOW_PROJECT_MAINLINE, the C_* namespaces are Midnight's, Edit Mode
--     and the Cooldown Manager are there, and the old Classic globals
--     (GetItemInfo, GetSpellInfo, UnitAura, GetTalentInfo) are gone. So
--     TomoMod is already written against the right API -- porting it is
--     not the problem.
--
--   * It reports interface 16001 with build version 1.60.x, so neither
--     the project id nor the build number identifies it alone: only the
--     pair does. Every addon that tests `select(4, GetBuildInfo()) >=
--     100000` to mean "modern client" is told no by this client and
--     takes its Classic branch. Detect() below keys on the pair.
--
--   * Whole game systems are absent: no Mythic+, no housing, no
--     skyriding, no world quests, no Midnight prey hunts. A module built
--     on one of those does not degrade gracefully -- it throws on the
--     first RegisterEvent of an event the client has never heard of, and
--     throws again on every retry for the rest of the session.
--
-- So availability is declared here, once, as data, and enforced in five
-- places that each read this file and nothing else:
--
--   the module files        a guard at the top of each entry file, so a
--                           blocked module is never parsed into being
--   Core/Init.lua           Initialize() is never called for it
--   Core/Database.lua       defaults ship disabled, and every profile,
--                           import or reset is brought back in line
--   Core/ModuleRegistry.lua a blocked module reads as off and cannot be
--                           switched on
--   Core/ModuleLifecycle.lua the live toggle refuses it as well
--
-- Nothing here depends on the player's settings. A module blocked on a
-- client is blocked for that client, not for that profile: the flag is
-- forced off rather than hidden, so a profile carried back to Midnight
-- only has to be reticked, never repaired.
--
-- This file loads before Database.lua and before the registry, so it
-- owns its own tiny path writer instead of borrowing theirs.
-- =====================================================================

TomoMod_Compat = TomoMod_Compat or {}
local Compat = TomoMod_Compat

Compat.MAINLINE = "mainline"   -- Midnight and later retail
Compat.FOREVER  = "forever"    -- WoW: Forever (1.60+ on the modern client)

-- ---------------------------------------------------------------------
-- DETECTION
-- ---------------------------------------------------------------------
-- Forever = modern project id + vanilla version line. Both halves are
-- required. On its own the version line would also match a real Classic
-- Era client (1.15.x is below 1.60, but a future Era patch need not be),
-- and on its own the project id matches every retail build there is.
--
-- The interface number is a second, independent witness: a mainline
-- client reporting an interface below 100000 cannot be Midnight. It is
-- kept as a fallback for the day Blizzard renumbers the version string,
-- not as the primary test.
-- ---------------------------------------------------------------------

local function Detect()
    local version, build, _, interface
    if GetBuildInfo then
        version, build, _, interface = GetBuildInfo()
    end

    interface = tonumber(interface) or 0
    build     = tonumber(build) or 0

    local major, minor = 0, 0
    if type(version) == "string" then
        local a, b = string.match(version, "^(%d+)%.(%d+)")
        major, minor = tonumber(a) or 0, tonumber(b) or 0
    end

    -- A client that does not define WOW_PROJECT_ID at all is treated as
    -- mainline: that is what the headless test harnesses look like, and
    -- refusing to run there would be worse than assuming retail.
    local mainlineProject = (WOW_PROJECT_ID == nil)
        or (WOW_PROJECT_MAINLINE ~= nil and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

    local forever = mainlineProject
        and ((major == 1 and minor >= 60)
             or (interface >= 16000 and interface < 100000))

    return {
        flavor    = forever and Compat.FOREVER or Compat.MAINLINE,
        version   = version or "unknown",
        build     = build,
        interface = interface,
        major     = major,
        minor     = minor,
    }
end

local state = Detect()
Compat.state = state

function Compat.Flavor()    return state.flavor end
function Compat.IsForever() return state.flavor == Compat.FOREVER end
function Compat.IsMainline() return state.flavor == Compat.MAINLINE end

--- Test seam and field escape hatch. Not persisted anywhere: a player
--- who has to force a flavour has hit a detection bug, and that bug is
--- worth seeing again on the next login rather than being papered over
--- permanently by a saved variable.
function Compat.Override(flavor)
    if flavor == Compat.FOREVER or flavor == Compat.MAINLINE then
        state.flavor = flavor
        return true
    end
    state = Detect()
    return false
end

-- ---------------------------------------------------------------------
-- FEATURES
-- ---------------------------------------------------------------------
-- One entry per game system TomoMod builds on, not one per Lua file.
-- Each names what the system costs us when it is absent:
--
--   modules  registry keys, so the inventory and the toggles agree
--   paths    dotted TomoModDB paths forced false
--   init     the label Core/Init.lua passes to safeInit()
--   addon    a LoadOnDemand sub-addon that must not be loaded
--   tabs     Options QOL tab keys to drop from the tab bar
--   page     Options category page to drop from the navigation
-- ---------------------------------------------------------------------

local FEATURES = {
    mythicplus = {
        label   = "Mythic+",
        modules = { "MythicKeys", "MythicTracker", "TomoScore" },
        paths   = { "MythicKeys.enabled", "MythicTracker.enabled", "TomoScore.enabled" },
        addon   = "TomoMod_MythicPlus",
        tabs    = { "mythickeys" },
        page    = "mythicplus",
    },
    housing = {
        label   = "Housing",
        modules = { "housing" },
        paths   = { "housing.enabled" },
        page    = "housing",
    },
    preytracker = {
        label   = "Prey Tracker",
        modules = { "preyTracker" },
        paths   = { "preyTracker.enabled" },
        init    = "PreyTracker",
    },
    compass = {
        label   = "Compass",
        modules = { "compass" },
        paths   = { "compass.enabled" },
        init    = "Compass",
        tabs    = { "compass" },
    },
    consumables = {
        label   = "Consumables",
        modules = { "consumableBar" },
        paths   = { "consumableBar.enabled" },
        init    = "ConsumableBar",
        tabs    = { "consumable" },
    },
    skyriding = {
        label   = "Skyriding",
        modules = { "skyRide" },
        paths   = { "skyRide.enabled" },
        init    = "SkyRide",
        tabs    = { "skyride" },
    },
    worldquests = {
        label   = "World Quests",
        modules = { "worldQuestTab" },
        paths   = { "worldQuestTab.enabled" },
        init    = "WorldQuestTab",
        tabs    = { "worldquests" },
    },
}
Compat.FEATURES = FEATURES

-- What each client cannot run. Absent from this table means "runs
-- everything", which is what mainline does.
local BLOCKED_BY_FLAVOR = {
    [Compat.FOREVER] = {
        "mythicplus",     -- no keystones, no challenge mode, no vault
        "housing",        -- no player housing, no house editor
        "preytracker",    -- Midnight prey hunt widgets
        "compass",        -- built on the Midnight waypoint/world-map model
        "consumables",    -- flask/food/oil set is Midnight's
        "skyriding",      -- no dragonriding: no vigor, no second wind
        "worldquests",    -- no world quests
    },
}

-- Flattened lookups, built once. Blocking is read on every module file
-- and on every DB normalisation, so it has to be a table hit, not a scan.
local blockedFeature = {}
local blockedModule  = {}
local blockedInit    = {}
local blockedAddOn   = {}
local blockedTab     = {}
local blockedPage    = {}
local blockedPaths   = {}

local function BuildLookups()
    blockedFeature, blockedModule, blockedInit = {}, {}, {}
    blockedAddOn, blockedTab, blockedPage, blockedPaths = {}, {}, {}, {}

    local list = BLOCKED_BY_FLAVOR[state.flavor]
    if not list then return end

    for _, name in ipairs(list) do
        local f = FEATURES[name]
        if f then
            blockedFeature[name] = true
            for _, key  in ipairs(f.modules or {}) do blockedModule[key] = name end
            for _, path in ipairs(f.paths   or {}) do blockedPaths[#blockedPaths + 1] = path end
            for _, tab  in ipairs(f.tabs    or {}) do blockedTab[tab] = name end
            if f.init  then blockedInit[f.init]   = name end
            if f.addon then blockedAddOn[f.addon] = name end
            if f.page  then blockedPage[f.page]   = name end
        end
    end
end
BuildLookups()

--- Rebuilds the lookups after an Override. Only the test seam needs it.
function Compat.Refresh() BuildLookups() end

-- ---------------------------------------------------------------------
-- QUERIES
-- ---------------------------------------------------------------------
-- Each answers for the current client. All are safe to call before the
-- database exists, which is the point: the module guards run at file
-- scope, long before ADDON_LOADED.
-- ---------------------------------------------------------------------

--- The guard every blocked module file opens with.
function Compat.Blocked(feature)
    return blockedFeature[feature] == true
end

--- Registry key -> blocked. Used by the registry and the lifecycle.
function Compat.IsModuleBlocked(key)
    return blockedModule[key] ~= nil
end

--- safeInit() label -> blocked. Used by Core/Init.lua.
function Compat.IsInitBlocked(name)
    return blockedInit[name] ~= nil
end

--- Sub-addon name -> blocked. Used by the studio hub and the launchers.
function Compat.IsAddOnBlocked(addon)
    return blockedAddOn[addon] ~= nil
end

--- Options QOL tab key -> blocked.
function Compat.IsTabBlocked(key)
    return blockedTab[key] ~= nil
end

--- Options category page key -> blocked.
function Compat.IsPageBlocked(key)
    return blockedPage[key] ~= nil
end

--- Which feature blocks this module, for a tooltip or a log line.
function Compat.BlockingFeature(key)
    local name = blockedModule[key]
    local f = name and FEATURES[name]
    return name, f and f.label or nil
end

--- Every dotted DB path this client forces off. Order is stable.
function Compat.BlockedPaths()
    local out = {}
    for i, p in ipairs(blockedPaths) do out[i] = p end
    return out
end

-- ---------------------------------------------------------------------
-- ENFORCEMENT
-- ---------------------------------------------------------------------
-- Writing false rather than deleting the key: the setting still exists,
-- it is simply not true here. A profile exported from Forever and
-- imported back into Midnight is then a normal profile with those
-- modules off, not a profile with holes in it.
-- ---------------------------------------------------------------------

local function SetFalse(root, path)
    if type(root) ~= "table" then return false end
    local node = root
    local last
    for seg in string.gmatch(path, "[^%.]+") do
        if last then
            if type(node[last]) ~= "table" then return false end
            node = node[last]
        end
        last = seg
    end
    if not last then return false end
    if node[last] == false then return false end
    node[last] = false
    return true
end

--- Called once, from Core/Database.lua, as soon as TomoMod_Defaults is
--- complete. A fresh install on Forever then never turns these on, and
--- TomoMod_ResetDatabase / TomoMod_ResetModule inherit it for free
--- because both copy from the defaults.
function Compat.ApplyDefaults(defaults)
    defaults = defaults or TomoMod_Defaults
    if type(defaults) ~= "table" then return 0 end
    local n = 0
    for _, path in ipairs(blockedPaths) do
        if SetFalse(defaults, path) then n = n + 1 end
    end
    return n
end

--- Called from TomoMod_NormalizeAllElements(), which is the one funnel
--- every path into the live database already goes through: login,
--- profile load, context swap, full import and selective import. An
--- existing Midnight profile carried over to Forever is corrected there
--- instead of being trusted.
function Compat.EnforceDB(db)
    db = db or TomoModDB
    if type(db) ~= "table" then return 0 end
    local n = 0
    for _, path in ipairs(blockedPaths) do
        if SetFalse(db, path) then n = n + 1 end
    end
    return n
end

-- ---------------------------------------------------------------------
-- DIAGNOSTICS
-- ---------------------------------------------------------------------

--- One line for /tm flavor and for the Diagnostics report.
function Compat.Summary()
    local names = {}
    for name in pairs(blockedFeature) do names[#names + 1] = name end
    table.sort(names)
    return string.format("%s %s (build %d, interface %d)%s",
        state.flavor == Compat.FOREVER and "WoW: Forever" or "WoW Retail",
        tostring(state.version), state.build, state.interface,
        #names > 0 and (" — disabled: " .. table.concat(names, ", ")) or "")
end

-- =====================================================================
-- test_compat_forever.lua — headless suite for Core/Compat.lua
--
--   lua5.1 Tools/test_compat_forever.lua       (from the repo root)
--
-- Four kinds of check, in the order they catch things:
--
--   1 detection    both clients, plus the near-misses that must NOT be
--                  read as Forever (Classic Era, Mists Classic, Midnight)
--   2 enforcement  defaults and live DB, including a profile imported
--                  from Midnight with every blocked module switched on
--   3 bijection    every key and path the feature table names really
--                  exists in the manifest and in TomoMod_Defaults --
--                  a typo here would silently block nothing at all
--   4 source       every file of a blocked module opens with its guard
-- =====================================================================

local failures, checks = 0, 0

-- Several source files carry a UTF-8 BOM, which loadfile() in Lua 5.1
-- rejects outright. Read and strip, then compile from the string.
local function LoadSource(path)
    local fh = assert(io.open(path, "rb"), "cannot open " .. path)
    local src = fh:read("*a")
    fh:close()
    src = src:gsub("^\239\187\191", "")
    return assert(loadstring(src, "@" .. path))
end

local function ok(cond, what)
    checks = checks + 1
    if not cond then
        failures = failures + 1
        print("  FAIL  " .. what)
    end
end

local function eq(a, b, what)
    ok(a == b, what .. "  (got " .. tostring(a) .. ", want " .. tostring(b) .. ")")
end

-- ---------------------------------------------------------------------
-- Loading Compat.lua under a stubbed client
-- ---------------------------------------------------------------------

local function LoadCompat(version, build, interface, projectID)
    -- Fresh globals each time: Compat caches its detection at load, which
    -- is the behaviour we want in game and the thing to defeat in a test.
    TomoMod_Compat        = nil
    WOW_PROJECT_ID        = projectID
    WOW_PROJECT_MAINLINE  = 1
    WOW_PROJECT_CLASSIC   = 2
    GetBuildInfo = function() return version, build, "", interface end

    LoadSource("Core/Compat.lua")()
    return TomoMod_Compat
end

local FOREVER  = { "1.60.1", "69913", 16001, 1 }
local MIDNIGHT = { "12.1.5", "71204", 120105, 1 }

-- =====================================================================
print("1. detection")
-- =====================================================================

local C = LoadCompat(unpack(FOREVER))
eq(C.Flavor(), "forever", "Forever 1.60.1 / 16001 is detected as forever")
ok(C.IsForever(), "IsForever() on the Forever client")

C = LoadCompat(unpack(MIDNIGHT))
eq(C.Flavor(), "mainline", "Midnight 12.1.5 / 120105 is detected as mainline")
ok(not C.IsForever(), "IsForever() is false on Midnight")

-- Near-misses. Each one matches exactly half of the Forever test, which
-- is why the detection needs both halves.
C = LoadCompat("1.15.7", "60000", 11507, 2)   -- Classic Era: right line, wrong project
eq(C.Flavor(), "mainline", "Classic Era is not mistaken for Forever")
C = LoadCompat("5.5.4", "60111", 50504, 2)    -- Mists Classic
eq(C.Flavor(), "mainline", "Mists Classic is not mistaken for Forever")
C = LoadCompat("12.0.0", "70000", 120000, 1)  -- plain Midnight
eq(C.Flavor(), "mainline", "Midnight 12.0.0 is not mistaken for Forever")

-- A future Forever build that renumbers the version string still trips
-- the interface fallback.
C = LoadCompat("2.0.0", "80000", 16005, 1)
eq(C.Flavor(), "forever", "mainline project + sub-100000 interface falls back to forever")

-- The two halves of the test are isolated below, because with the real
-- build numbers they overlap: 1.60.1 satisfies both, so a break in either
-- one alone would be masked by the other.
--
-- Version half only: interface unreadable, version line still 1.60+.
C = LoadCompat("1.61.0", "70000", 0, 1)
eq(C.Flavor(), "forever", "version line alone identifies Forever")

-- Interface half only, in the direction that matters: a mainline project
-- on a 1.1x line with a 1.1x interface is not Forever. This is the case
-- that a loosened `minor >=` bound would wrongly claim.
C = LoadCompat("1.15.7", "60000", 11507, 1)
eq(C.Flavor(), "mainline", "a mainline 1.15 client is still not Forever")

-- =====================================================================
print("2. enforcement")
-- =====================================================================

C = LoadCompat(unpack(FOREVER))

local BLOCKED_PATHS = C.BlockedPaths()
eq(#BLOCKED_PATHS, 9, "nine flags are forced off on Forever")

-- A profile exported from Midnight: every blocked module switched on.
local function MidnightProfile()
    return {
        MythicKeys    = { enabled = true },
        MythicTracker = { enabled = true },
        TomoScore     = { enabled = true },
        housing       = { enabled = true },
        preyTracker   = { enabled = true },
        compass       = { enabled = true },
        consumableBar = { enabled = true, readyTrackerMigrated = true },
        skyRide       = { enabled = true },
        worldQuestTab = { enabled = true },
        minimap       = { enabled = true },   -- untouched control
    }
end

local db = MidnightProfile()
eq(C.EnforceDB(db), 9, "importing a Midnight profile corrects nine flags")
for _, path in ipairs(BLOCKED_PATHS) do
    local key = path:match("^([^%.]+)")
    eq(db[key].enabled, false, path .. " is off after EnforceDB")
end
eq(db.minimap.enabled, true, "a module that is not blocked is left alone")
eq(db.consumableBar.readyTrackerMigrated, true, "sibling settings survive: only the flag moves")
eq(C.EnforceDB(db), 0, "EnforceDB is idempotent — a second pass changes nothing")

-- Turning one back off is not the same as deleting it: a profile carried
-- back to Midnight must be a normal profile, not one with holes in it.
ok(db.compass.enabled ~= nil, "the flag is set to false, never removed")

-- On Midnight nothing is touched at all.
local mainline = LoadCompat(unpack(MIDNIGHT))
eq(#mainline.BlockedPaths(), 0, "Midnight blocks nothing")
local db2 = MidnightProfile()
eq(mainline.EnforceDB(db2), 0, "EnforceDB is a no-op on Midnight")
eq(db2.compass.enabled, true, "Midnight leaves every flag as the profile had it")

-- A DB missing the parent table must not be created by the enforcement:
-- writing into a table the merge has not built yet would put a lone
-- `enabled = false` where a full default set belongs.
local sparse = { compass = { enabled = true } }
C = LoadCompat(unpack(FOREVER))
C.EnforceDB(sparse)
eq(sparse.compass.enabled, false, "present tables are corrected")
eq(sparse.housing, nil, "absent tables are not conjured into existence")

-- =====================================================================
print("3. bijection with the manifest and the defaults")
-- =====================================================================

-- ModuleRegistry + ModuleManifest are pure data and load headless, which
-- is exactly what the registry was built for.
TomoMod_Registry = nil
LoadSource("Core/ModuleRegistry.lua")()
LoadSource("Core/ModuleManifest.lua")()
local R = TomoMod_Registry

-- TomoMod_Defaults is a plain table literal; read it without running the
-- rest of Database.lua by loading the file with the globals it touches
-- stubbed out.
local defaults
do
    local env = setmetatable({}, { __index = _G })
    local chunk = LoadSource("Core/Database.lua")
    setfenv(chunk, env)
    pcall(chunk)   -- later sections need the client; the table is built first
    defaults = env.TomoMod_Defaults or TomoMod_Defaults
end
ok(type(defaults) == "table", "TomoMod_Defaults loaded")

-- Database.lua calls ApplyDefaults at file scope, so loading it under the
-- Forever stub must already have moved the real shipped defaults. This is
-- the check that a fresh install on Forever starts with these modules off.
eq(defaults.compass.enabled, false, "shipped default: compass off on Forever")
eq(defaults.housing.enabled, false, "shipped default: housing off on Forever")
eq(defaults.MythicTracker.enabled, false, "shipped default: MythicTracker off on Forever")
eq(defaults.minimap.enabled, true, "shipped default: minimap untouched")

C = LoadCompat(unpack(FOREVER))

for name, feature in pairs(C.FEATURES) do
    for _, key in ipairs(feature.modules or {}) do
        ok(R.Has(key), ("feature '%s' names manifest key '%s'"):format(name, key))
        local m = R.Get(key)
        if m then
            ok(m.enabledPath ~= nil,
                ("'%s' has an enabledPath to force off"):format(key))
        end
    end
    for _, path in ipairs(feature.paths or {}) do
        local head, tail = path:match("^([^%.]+)%.(.+)$")
        ok(defaults[head] ~= nil,
            ("path '%s' has a TomoMod_Defaults entry"):format(path))
        ok(defaults[head] and defaults[head][tail] ~= nil,
            ("path '%s' resolves inside the defaults"):format(path))
    end
end

-- Every path a blocked module declares in the manifest is a path the
-- feature table also claims: a manifest key blocked without its path
-- would read as unavailable while its flag stayed true in the DB.
for _, key in ipairs({ "MythicKeys", "MythicTracker", "TomoScore", "housing",
                       "preyTracker", "compass", "consumableBar", "skyRide",
                       "worldQuestTab" }) do
    local m = R.Get(key)
    local found = false
    for _, p in ipairs(BLOCKED_PATHS) do
        if m and p == m.enabledPath then found = true end
    end
    ok(found, ("manifest enabledPath of '%s' is in BlockedPaths()"):format(key))
    ok(C.IsModuleBlocked(key), ("'%s' reports as blocked"):format(key))
end

-- The registry itself has to agree, not just Compat.
ok(R.IsAvailable("minimap"), "an unblocked module stays available")
ok(not R.IsAvailable("compass"), "registry refuses a blocked module")

TomoModDB = MidnightProfile()
C.EnforceDB(TomoModDB)
eq(R.IsEnabled("compass"), false, "a blocked module reads as off")
local set = R.SetEnabled("compass", true)
eq(set, false, "the registry refuses to switch a blocked module on")
eq(TomoModDB.compass.enabled, false, "and the flag did not move")

-- =====================================================================
print("4. source guards")
-- =====================================================================

local GUARDED = {
    mythicplus = {
        "Modules/QOL/MythicPlus/DataKeys.lua", "Modules/QOL/MythicPlus/KeySync.lua",
        "Modules/QOL/MythicPlus/Keystone.lua", "Modules/QOL/MythicPlus/MythicHub.lua",
        "Modules/QOL/MythicPlus/MythicKeys.lua", "Modules/QOL/MythicPlus/MythicPlusBridge.lua",
        "Modules/QOL/MythicPlus/MythicTracker.lua", "Modules/QOL/MythicPlus/RunSurvival.lua",
        "Modules/QOL/MythicPlus/TeleportMenu.lua", "Modules/QOL/MythicPlus/TomoScoreAnalysis.lua",
        "Modules/QOL/MythicPlus/TomoScoreCore.lua", "Modules/QOL/MythicPlus/TomoScoreData.lua",
        "Modules/QOL/MythicPlus/TomoScoreUI.lua",
        "TomoMod_MythicPlus/Bootstrap.lua", "TomoMod_MythicPlus/RunAnalysis.lua",
        "TomoMod_MythicPlus/RunHistory.lua", "TomoMod_MythicPlus/Studio.lua",
        "TomoMod_MythicPlus/SurvivalAnalysis.lua",
    },
    housing = {
        "Modules/Housing/EditorClock.lua", "Modules/Housing/HousingAPI.lua",
        "Modules/Housing/HousingCore.lua",
    },
    preytracker = { "Modules/QOL/Combat/PreyTracker.lua" },
    compass     = { "Modules/QOL/Compass/Compass.lua" },
    consumables = { "Modules/QOL/Consumables/ConsumableBar.lua" },
    skyriding   = { "Modules/QOL/Skyriding/SkyRide.lua" },
    worldquests = { "Modules/QOL/WorldQuests/WorldQuestJournal.lua" },
}

for feature, files in pairs(GUARDED) do
    for _, path in ipairs(files) do
        local fh = io.open(path, "rb")
        ok(fh ~= nil, "readable: " .. path)
        if fh then
            local head = fh:read(700) or ""
            fh:close()
            local want = 'TomoMod_Compat.Blocked("' .. feature .. '") then return end'
            ok(head:find(want, 1, true) ~= nil,
                ("%s opens with the '%s' guard"):format(path, feature))
        end
    end
end

-- Nothing under the blocked folders may be left unguarded: a new file
-- added to Modules/QOL/MythicPlus later has to fail this test, not ship.
local function ScanFolder(folder, feature)
    local pipe = io.popen('ls "' .. folder .. '"/*.lua 2>/dev/null')
    if not pipe then return end
    for path in pipe:lines() do
        local fh = io.open(path, "rb")
        if fh then
            local head = fh:read(700) or ""
            fh:close()
            ok(head:find('TomoMod_Compat.Blocked("' .. feature .. '")', 1, true) ~= nil,
                ("every file in %s is guarded (%s)"):format(folder, path))
        end
    end
    pipe:close()
end
ScanFolder("Modules/QOL/MythicPlus", "mythicplus")
ScanFolder("TomoMod_MythicPlus", "mythicplus")
ScanFolder("Modules/Housing", "housing")

-- =====================================================================
print(("\n%d checks, %d failures"):format(checks, failures))
os.exit(failures == 0 and 0 or 1)

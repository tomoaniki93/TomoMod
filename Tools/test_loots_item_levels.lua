local function read(path)
    local f = assert(io.open(path, "rb"))
    local s = f:read("*a"); f:close()
    return s
end
local source = read("Modules/QOL/Loots/Loots.lua")
local start = assert(source:find("local DIFF_LIST =", 1, true))
local finish = assert(source:find("local FILTER_BAR_H", start, true))
local base, itemClass = 250, 4
local requested
local env = setmetatable({
    C_Item = {
        GetDetailedItemLevelInfo = function() return base, false, base end,
        RequestLoadItemDataByID = function(id) requested = id end,
    },
    GetItemInfoInstant = function() return 123, nil, nil, nil, nil, itemClass end,
}, { __index = _G })
local chunk = assert(loadstring(source:sub(start, finish - 1)
    .. "\nreturn ItemLink, DIFF_BONUS_ID, DUNGEON_BONUS_IDS, BONUS_LEVELS"))
setfenv(chunk, env)
local link, raids, dungeons, levels = chunk()
local function fields(value)
    local result = {}
    for field in value:gmatch("[^:]+") do result[#result+1] = field end
    return result
end
for _, difficulty in ipairs({17,14,15,16}) do
    local bonus = raids[difficulty]
    local parts = fields(link(123, bonus))
    assert(tonumber(parts[14]) == 2, "bonus count")
    assert(tonumber(parts[15]) == bonus, "track")
    assert(tonumber(parts[16]) == 1472 + levels[bonus] - base, "level adjustment")
end
assert(link(123, raids[14]) ~= link(123, raids[16]))
assert(link(123, dungeons[0]) ~= link(123, dungeons[10]))
assert(levels[dungeons[0]] == 292 and levels[dungeons[10]] == 311)
base = 1
assert(tonumber(fields(link(123, dungeons[10]))[16]) == 3239)
base = 311
assert(tonumber(fields(link(123, dungeons[10]))[14]) == 1)
base = nil
assert(link(123, dungeons[10]) == "item:123" and requested == 123)
base, itemClass = 250, 15
assert(link(123, raids[16]) == "item:123", "collectible unchanged")

-- Test the data paths, not just the hyperlink formatter.
env.TomoMod_LootsData = { dungeons={[99]={123}}, raidBosses={[88]={[15]={123}}},
    raidBonusIDs={[88]={[15]=12843}} }
env.ItemsFromIDs = function(ids, bonus) return {ids=ids, bonus=bonus} end
env.DUNGEON_BONUS_IDS, env.DIFF_BONUS_ID = dungeons, raids
local body = assert(source:match("(local function GetDungeonItems.-)\n%-%- Heuristique"))
local getters = assert(loadstring(body .. "\nreturn GetDungeonItems, GetBossItems"))
setfenv(getters, env)
local dungeon, boss = getters()
assert(dungeon(99,0).bonus==12833 and dungeon(99,10).bonus==12843)
assert(boss(88,15).bonus==12843)
env.TomoMod_LootsData.raidBonusIDs = nil
assert(boss(88,15).bonus==12841)
print("PASS: Loots difficulty bonuses, item-level offsets, cached data and source selection")

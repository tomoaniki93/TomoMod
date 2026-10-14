-- Exercise the production gem reader without loading the character UI.
local file = assert(io.open("Modules/QOL/Skins/CharacterSkin.lua", "rb"))
local source = file:read("*a")
file:close()
local block = assert(source:match("(local function GetGemInfo%(unit, slotId%).-)local gemOverlays"))
local function reader(env)
    local chunk = assert(loadstring(block .. "\nreturn GetGemInfo"))
    setfenv(chunk, setmetatable(env, { __index = _G }))
    return chunk()
end
local env = {
    GetInventoryItemLink = function() return "item:equipment" end,
    C_TooltipInfo = { GetInventoryItem = function()
        return { lines = { { type = 3 }, { type = 3 } } }
    end },
}
local function gem(_, index)
    if index == 1 then return "Gem", "item:123" end
end
local function info()
    return "Gem", "item:123", 3, 1, 1, "Gem", "Red", 1, "", 456
end
env.C_Item = { GetItemGem = gem, GetItemInfo = info }
local gems, count = reader(env)("player", 1)
assert(count == 2 and #gems == 2)
assert(gems[1].filled and gems[1].icon == 456 and gems[1].type == "Red")
assert(not gems[2].filled)

-- A gem not in the item cache still gets its icon from the instant API.
env.C_Item.GetItemInfo = function() end
env.C_Item.GetItemInfoInstant = function(link)
    assert(link == "item:123")
    return 123
end
env.C_Item.GetItemIconByID = function(id) assert(id == 123); return 789 end
gems = reader(env)("target", 1)
assert(gems[1].icon == 789 and gems[1].type == "Prismatic")

-- Legacy clients, missing optional APIs, and unequipped slots.
env.C_Item = nil
env.GetItemGem, env.GetItemInfo = gem, info
gems = reader(env)("player", 1)
assert(gems[1].icon == 456)
env.GetItemInfo = nil
gems = reader(env)("player", 1)
assert(gems[1].filled and gems[1].icon == nil)
env.GetItemGem = nil
gems, count = reader(env)("player", 1)
assert(#gems == 0 and count == 0)
env.GetItemGem = gem
env.GetInventoryItemLink = function() end
gems, count = reader(env)("player", 1)
assert(#gems == 0 and count == 0)
print("PASS: character gems, Retail APIs, legacy fallback and missing data")

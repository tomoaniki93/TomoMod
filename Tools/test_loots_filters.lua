local f = assert(io.open("Modules/QOL/Loots/Loots.lua", "rb"))
local source = f:read("*a"); f:close()
local block = assert(source:match("(local function ItemMatchesSlot.-)\nlocal function IsEquipped"))
local chunk = assert(loadstring(block .. "\nreturn ItemMatchesSlot"))
local location
setfenv(chunk, setmetatable({ GetItemInfoInstant = function()
    return 123, nil, nil, location
end }, { __index = _G }))
local matches = chunk()
assert(matches(123, nil))
for _, token in ipairs({"INVTYPE_CHEST", "INVTYPE_ROBE"}) do
    location = token
    assert(matches(123, "INVTYPE_CHEST"))
    assert(not matches(123, "INVTYPE_HEAD"))
end
for _, token in ipairs({"INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_2HWEAPON", "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT", "INVTYPE_THROWN"}) do
    location = token
    assert(matches(123, "INVTYPE_WEAPON"), token)
end
for _, token in ipairs({"INVTYPE_WEAPON", "INVTYPE_WEAPONOFFHAND", "INVTYPE_SHIELD", "INVTYPE_HOLDABLE"}) do
    location = token
    assert(matches(123, "INVTYPE_WEAPONOFFHAND"), token)
end
location = "INVTYPE_2HWEAPON"
assert(not matches(123, "INVTYPE_WEAPONOFFHAND"))
location = "INVTYPE_FINGER"
assert(matches(123, "INVTYPE_FINGER"))
assert(not matches(123, "INVTYPE_TRINKET"))
location = nil
assert(not matches(123, "INVTYPE_HEAD"))
assert(matches(123, nil))
print("PASS: Loots slot filter, robes, weapons, off-hand items and unknown locations")

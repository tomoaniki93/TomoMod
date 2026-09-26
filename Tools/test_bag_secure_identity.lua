-- Regression bench for Midnight's protected container-button identity.
-- Custom buttons may keep Blizzard's native click script only when their bag
-- ID is installed through ContainerFrameItemButtonMixin:SetBagID().

local total = 0
local function check(label, condition)
    total = total + 1
    assert(condition, label)
end

local function read(path)
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a")
    file:close()
    return source:gsub("^\239\187\191", ""):gsub("\r\n", "\n")
end

local source = read("Modules/QOL/Bags/BagSlots.lua")
local createStart = assert(source:find("function Slots:CreatePhysicalSlot", 1, true))
local ensureStart = assert(source:find("function Slots:EnsurePool", createStart, true))
local renderStart = assert(source:find("function Slots:Render", ensureStart, true))
local layoutStart = assert(source:find("function Slots:LayoutDisplay", renderStart, true))
local create = source:sub(createStart, ensureStart - 1)
local render = source:sub(renderStart, layoutStart - 1)

check("physical slot uses protected bag identity",
      create:find("button:SetBagID(bagID)", 1, true) ~= nil)
check("physical slot still assigns its fixed slot ID",
      create:find("button:SetID(slotID)", 1, true) ~= nil)
check("combat-safe render does not rewrite bag identity",
      render:find("SetBagID", 1, true) == nil)
check("combat-safe render does not rewrite slot ID",
      render:find("button:SetID", 1, true) == nil)
check("native input scripts remain untouched",
      create:find('SetScript("OnClick"', 1, true) == nil
      and create:find('HookScript("OnClick"', 1, true) == nil
      and create:find('SetScript("PreClick"', 1, true) == nil
      and create:find('HookScript("PreClick"', 1, true) == nil)

print(("Bag secure-identity tests passed: %d"):format(total))

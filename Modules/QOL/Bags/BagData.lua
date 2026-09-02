-- =====================================================================
-- BagData.lua — inventory snapshot, visual sorting, pins and recent items
-- =====================================================================

local Bags = TomoMod_BagSkin
if not Bags then return end

local Data = {
    items = {},
    byKey = {},
    countByItem = {},
    recentSet = {},
    recentOrder = {},
    snapshotReady = false,
}
Bags.RegisterModule("Data", Data)

local issecretvalue = issecretvalue
local lower = string.lower

local BAG_IDS = { 0, 1, 2, 3, 4 }
local reagent = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag
if reagent and reagent ~= 0 then BAG_IDS[#BAG_IDS + 1] = reagent end
Data.BAG_IDS = BAG_IDS

local function Safe(value, fallback)
    if issecretvalue and issecretvalue(value) then return fallback end
    return value == nil and fallback or value
end

local function ItemLevel(bagID, slotID, classID, itemLink)
    local weapon = Enum and Enum.ItemClass and Enum.ItemClass.Weapon or 2
    local armor = Enum and Enum.ItemClass and Enum.ItemClass.Armor or 4
    if classID ~= weapon and classID ~= armor then return nil end

    -- Prefer the live ItemLocation value because it includes upgrades.
    if ItemLocation and ItemLocation.CreateFromBagAndSlot and C_Item and C_Item.GetCurrentItemLevel then
        local ok, location = pcall(ItemLocation.CreateFromBagAndSlot, ItemLocation, bagID, slotID)
        if ok and location and location.IsValid and location:IsValid() then
            local levelOK, level = pcall(C_Item.GetCurrentItemLevel, location)
            if levelOK and not (issecretvalue and issecretvalue(level)) and type(level) == "number" and level > 0 then
                return level
            end
        end
    end

    -- Midnight occasionally has the location API lag one cache update behind.
    -- The detailed link API is a safe fallback for normal bag items.
    if itemLink and C_Item and C_Item.GetDetailedItemLevelInfo then
        local levelOK, level = pcall(C_Item.GetDetailedItemLevelInfo, itemLink)
        if levelOK and not (issecretvalue and issecretvalue(level)) and type(level) == "number" and level > 0 then
            return level
        end
    end

    return nil
end

local function NaturalLess(a, b)
    if a.bagOrder ~= b.bagOrder then return a.bagOrder < b.bagOrder end
    return a.slotID < b.slotID
end

local function QualityLess(a, b)
    if a.hasItem ~= b.hasItem then return a.hasItem end
    local aq, bq = a.quality or -1, b.quality or -1
    if aq ~= bq then return aq > bq end
    local an, bn = a.nameLower or "", b.nameLower or ""
    if an ~= bn then return an < bn end
    return NaturalLess(a, b)
end

local function NameLess(a, b)
    if a.hasItem ~= b.hasItem then return a.hasItem end
    local an, bn = a.nameLower or "", b.nameLower or ""
    if an ~= bn then return an < bn end
    return NaturalLess(a, b)
end

local function IlvlLess(a, b)
    if a.hasItem ~= b.hasItem then return a.hasItem end
    local al, bl = a.ilvl or 0, b.ilvl or 0
    if al ~= bl then return al > bl end
    return QualityLess(a, b)
end

local SORTERS = {
    natural = NaturalLess,
    quality = QualityLess,
    name = NameLess,
    ilvl = IlvlLess,
}

local function CopyArray(src)
    local out = {}
    for i = 1, #src do out[i] = src[i] end
    return out
end

function Data:Key(bagID, slotID)
    return tostring(bagID) .. ":" .. tostring(slotID)
end

function Data:Scan(trackRecent)
    wipe(self.items)
    wipe(self.byKey)

    local newCounts = {}
    local used, total = 0, 0

    for bagOrder, bagID in ipairs(BAG_IDS) do
        local numSlots = C_Container.GetContainerNumSlots(bagID) or 0
        for slotID = 1, numSlots do
            total = total + 1
            local raw = C_Container.GetContainerItemInfo(bagID, slotID)
            local item = {
                key = self:Key(bagID, slotID),
                bagID = bagID,
                bagOrder = bagOrder,
                slotID = slotID,
                hasItem = raw ~= nil,
            }

            if raw then
                item.itemID = Safe(raw.itemID)
                item.icon = Safe(raw.iconFileID)
                item.count = tonumber(Safe(raw.stackCount, 1)) or 1
                item.quality = tonumber(Safe(raw.quality, 0)) or 0
                item.locked = Safe(raw.isLocked, false) and true or false
                item.quest = Safe(raw.isQuestItem, false) and true or false
                item.name = Safe(raw.itemName, "")
                local rawLink = C_Container.GetContainerItemLink and C_Container.GetContainerItemLink(bagID, slotID)
                item.link = Safe(rawLink)

                if item.itemID then
                    local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(item.itemID)
                    item.classID = tonumber(Safe(classID))
                    item.subClassID = tonumber(Safe(subClassID))
                    if item.name == "" and C_Item.GetItemNameByID then
                        item.name = Safe(C_Item.GetItemNameByID(item.itemID), "")
                    end
                    item.nameLower = type(item.name) == "string" and lower(item.name) or ""
                    item.ilvl = ItemLevel(bagID, slotID, item.classID, item.link)
                    newCounts[item.itemID] = (newCounts[item.itemID] or 0) + item.count
                end
                used = used + 1
            else
                item.count = 0
                item.name = ""
                item.nameLower = ""
                item.quality = 0
            end

            self.items[#self.items + 1] = item
            self.byKey[item.key] = item
        end
    end

    if trackRecent and self.snapshotReady then
        for itemID, count in pairs(newCounts) do
            local old = self.countByItem[itemID] or 0
            if count > old then self:AddRecent(itemID) end
        end
    end

    wipe(self.countByItem)
    for itemID, count in pairs(newCounts) do self.countByItem[itemID] = count end
    self.snapshotReady = true
    self.used, self.total = used, total
    return self.items
end

function Data:GetDisplayItems(query, sortMode, showEmpty)
    local source = CopyArray(self.items)
    local q = type(query) == "string" and lower(query) or ""
    q = q:gsub("^%s+", ""):gsub("%s+$", "")

    if q ~= "" or showEmpty == false then
        local filtered = {}
        for _, item in ipairs(source) do
            local keep = item.hasItem
            if keep and q ~= "" then
                keep = (item.nameLower and item.nameLower:find(q, 1, true) ~= nil)
                    or (item.itemID and tostring(item.itemID):find(q, 1, true) ~= nil)
            elseif not keep and q == "" then
                keep = showEmpty ~= false
            end
            if keep then filtered[#filtered + 1] = item end
        end
        source = filtered
    end

    table.sort(source, SORTERS[sortMode] or NaturalLess)
    return source
end

function Data:TogglePinned(itemID)
    itemID = tonumber(itemID)
    if not itemID then return end
    local pinned = Bags.GetDB().pinned
    pinned.items = pinned.items or {}
    pinned.order = pinned.order or {}

    if pinned.items[itemID] then
        pinned.items[itemID] = nil
        for i = #pinned.order, 1, -1 do
            if pinned.order[i] == itemID then table.remove(pinned.order, i) end
        end
    else
        pinned.items[itemID] = true
        pinned.order[#pinned.order + 1] = itemID
    end
    Bags.RequestRefresh(false)
end

function Data:IsPinned(itemID)
    local items = Bags.GetDB().pinned.items
    return itemID and items and items[itemID] == true
end

function Data:GetPinnedItems()
    local db = Bags.GetDB()
    local out = {}
    local seen = {}
    local order = db.pinned.order or {}

    local representative = {}
    for _, item in ipairs(self.items) do
        if item.hasItem and item.itemID and not representative[item.itemID] then
            representative[item.itemID] = item
        end
    end

    for _, itemID in ipairs(order) do
        if db.pinned.items[itemID] and representative[itemID] then
            out[#out + 1] = representative[itemID]
            seen[itemID] = true
        end
    end
    for itemID in pairs(db.pinned.items or {}) do
        if not seen[itemID] and representative[itemID] then
            out[#out + 1] = representative[itemID]
        end
    end
    return out
end

function Data:AddRecent(itemID)
    itemID = tonumber(itemID)
    if not itemID then return end
    if self.recentSet[itemID] then
        for i = #self.recentOrder, 1, -1 do
            if self.recentOrder[i] == itemID then table.remove(self.recentOrder, i) end
        end
    end
    self.recentSet[itemID] = true
    self.recentOrder[#self.recentOrder + 1] = itemID

    local maxItems = math.max(1, tonumber(Bags.GetDB().sidebar.recentMax) or 8)
    while #self.recentOrder > maxItems do
        local removed = table.remove(self.recentOrder, 1)
        self.recentSet[removed] = nil
    end
end

function Data:GetRecentItems()
    local representative = {}
    for _, item in ipairs(self.items) do
        if item.hasItem and item.itemID and not representative[item.itemID] then
            representative[item.itemID] = item
        end
    end

    local out = {}
    for i = #self.recentOrder, 1, -1 do
        local item = representative[self.recentOrder[i]]
        if item then out[#out + 1] = item end
    end
    return out
end

function Data:GetCounts()
    return self.used or 0, self.total or 0
end

function Data:Initialize()
    self:Scan(false)
end

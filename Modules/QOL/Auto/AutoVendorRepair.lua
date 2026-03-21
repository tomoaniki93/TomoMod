--------------------------------------------------
-- AutoVendorRepair
-- Automatically sells gray items and repairs gear
--------------------------------------------------

local addonName = ...
local f = CreateFrame("Frame")

--------------------------------------------------
-- Settings (simple, hardcoded for now)
--------------------------------------------------
local SELL_GRAYS = true
local AUTO_REPAIR = true
local PRINT_SUMMARY = true

--------------------------------------------------
-- Utils
--------------------------------------------------
local function FormatGold(amount)
    local gold = floor(amount / 10000)
    local silver = floor((amount % 10000) / 100)
    local copper = amount % 100
    return string.format("%dg %ds %dc", gold, silver, copper)
end

--------------------------------------------------
-- Sell gray items (one per tick to avoid lag spikes)
--------------------------------------------------
local function SellGrayItems()
    if not SELL_GRAYS then return end

    local greyItems = {}
    for bag = 0, NUM_BAG_FRAMES do
        local slots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.hyperlink and itemInfo.quality == Enum.ItemQuality.Poor then
                tinsert(greyItems, { bag = bag, slot = slot, id = itemInfo.itemID })
            end
        end
    end

    if #greyItems == 0 then return end

    local total = 0
    local idx = 0
    local ticker
    ticker = C_Timer.NewTicker(0.15, function()
        idx = idx + 1
        if idx > #greyItems then
            ticker:Cancel()
            if PRINT_SUMMARY and total > 0 then
                print(string.format(TomoMod_L["msg_avr_sold"], FormatGold(total)))
            end
            return
        end
        local item = greyItems[idx]
        local info = C_Container.GetContainerItemInfo(item.bag, item.slot)
        if info and info.itemID == item.id and info.quality == Enum.ItemQuality.Poor then
            local price = info.stackCount * (select(11, GetItemInfo(item.id)) or 0)
            C_Container.UseContainerItem(item.bag, item.slot)
            total = total + price
        end
    end)
end

--------------------------------------------------
-- Repair gear
--------------------------------------------------
local function RepairItems()
    if not AUTO_REPAIR then return 0 end
    if not CanMerchantRepair() then return 0 end

    local cost = GetRepairAllCost()
    if cost > 0 and cost <= GetMoney() then
        RepairAllItems()
        return cost
    end

    return 0
end

--------------------------------------------------
-- Event handler
--------------------------------------------------
f:RegisterEvent("MERCHANT_SHOW")

f:SetScript("OnEvent", function()
    local repairCost = RepairItems()

    if PRINT_SUMMARY and repairCost > 0 then
        print("|cff00ff00" .. TomoMod_L["msg_avr_header"] .. "|r")
        print(string.format(TomoMod_L["msg_avr_repaired"], FormatGold(repairCost)))
    end

    SellGrayItems()
end)
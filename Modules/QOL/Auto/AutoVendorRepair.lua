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
-- Sell gray items
--------------------------------------------------
local function SellGrayItems()
    if not SELL_GRAYS then return 0 end

    local total = 0

    for bag = 0, NUM_BAG_FRAMES do
        local slots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.hyperlink then
                local quality = itemInfo.quality
                if quality == Enum.ItemQuality.Poor then
                    local price = itemInfo.stackCount * (select(11, GetItemInfo(itemInfo.itemID)) or 0)
                    C_Container.UseContainerItem(bag, slot)
                    total = total + price
                end
            end
        end
    end

    return total
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
    local sold = SellGrayItems()
    local repairCost = RepairItems()

    if PRINT_SUMMARY and (sold > 0 or repairCost > 0) then
        print("|cff00ff00" .. TomoModMini_L["msg_avr_header"] .. "|r")

        if sold > 0 then
            print(string.format(TomoModMini_L["msg_avr_sold"], FormatGold(sold)))
        end

        if repairCost > 0 then
            print(string.format(TomoModMini_L["msg_avr_repaired"], FormatGold(repairCost)))
        end
    end
end)
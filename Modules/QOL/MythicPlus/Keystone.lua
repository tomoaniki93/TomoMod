local AutoInsertKey = CreateFrame("Frame")

-- Trouver la clé mythique
local function FindKeystoneInBags()
    for bag = 0, NUM_BAG_SLOTS do
        local slots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then
                local classID, subClassID = select(6, C_Item.GetItemInfoInstant(itemID))
                if classID == Enum.ItemClass.Reagent
                and subClassID == Enum.ItemReagentSubclass.Keystone then
                    return bag, slot
                end
            end
        end
    end
end

local function InsertKeystone()
    -- Déjà une clé insérée → on ne touche pas
    if C_ChallengeMode.GetSlottedKeystoneInfo() then
        return
    end

    local bag, slot = FindKeystoneInBags()
    if not bag then return end

    C_Container.PickupContainerItem(bag, slot)

    if C_Cursor.GetCursorItem() then
        C_ChallengeMode.SlotKeystone()
        ClearCursor()
    end
end

-- Hook UI Blizzard
AutoInsertKey:RegisterEvent("ADDON_LOADED")
AutoInsertKey:SetScript("OnEvent", function(self, _, addon)
    if addon == "Blizzard_ChallengesUI" then
        if ChallengesKeystoneFrame then
            ChallengesKeystoneFrame:HookScript("OnShow", InsertKeystone)
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
--------------------------------------------------
-- FastLoot (Retail)
-- Auto-loot ultra rapide (fenêtre quasi invisible)
--------------------------------------------------

local FastLoot = CreateFrame("Frame")

-- Active l'autoloot sans passer par l'option système
local function EnableFastLoot()
    if not GetCVarBool("autoLootDefault") then
        SetCVar("autoLootDefault", 1)
    end
end

-- Loot instantané à l'ouverture
FastLoot:RegisterEvent("LOOT_READY")
FastLoot:RegisterEvent("LOOT_OPENED")

FastLoot:SetScript("OnEvent", function(self, event, autoLoot)
    -- Toujours autoloot
    if event == "LOOT_READY" then
        EnableFastLoot()

        for i = GetNumLootItems(), 1, -1 do
            LootSlot(i)
        end

        -- Force fermeture immédiate
        CloseLoot()
    end
end)

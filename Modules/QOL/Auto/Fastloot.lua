--------------------------------------------------
-- FastLoot (Retail)
-- Auto-loot ultra rapide
--------------------------------------------------

local FastLoot = CreateFrame("Frame")

-- Active l'autoloot sans passer par l'option systeme
local function EnableFastLoot()
    if not GetCVarBool("autoLootDefault") then
        SetCVar("autoLootDefault", 1)
    end
end

-- Loot instantane a l'ouverture
FastLoot:RegisterEvent("LOOT_READY")

FastLoot:SetScript("OnEvent", function(self, event, autoLoot)
    if event == "LOOT_READY" then
        EnableFastLoot()

        for i = GetNumLootItems(), 1, -1 do
            LootSlot(i)
        end

        -- Ne PAS appeler CloseLoot() ici !
        -- LootSlot() est asynchrone, les items ne sont pas encore
        -- dans le sac. Le client ferme automatiquement la fenetre
        -- quand tous les items sont ramasseÃ©s avec autoLoot.
    end
end)

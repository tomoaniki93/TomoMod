-- =====================================
-- Auto/Fastloot.lua
-- Loot instantané — version améliorée
--
-- Améliorations vs version précédente :
--   • Vérification DB (enabled) — plus toujours actif sans contrôle
--   • Respect du CVar autoLootDefault + modificateur (XOR, comme Naowh)
--   • Throttle 0.2 s pour éviter les doubles déclenchements
--   • Garde si le curseur tient déjà un objet (compatibilité TSM/Destroy)
--   • N'appelle plus SetCVar ni CloseLoot de force
--   • Ne s'enregistre sur LOOT_READY qu'après PLAYER_LOGIN
-- =====================================

local THROTTLE = 0.2
local lastLootTime = 0

local function GetDB()
    return TomoModDB and TomoModDB.fastLoot
end

-- Respecte le CVar + modificateur (XOR)
local function ShouldAutoLoot()
    local autoLootOn = GetCVarBool("autoLootDefault")
    local modifierHeld = IsModifiedClick("AUTOLOOTTOGGLE")
    return autoLootOn ~= modifierHeld
end

local function CollectLoot()
    local db = GetDB()
    if not db or not db.enabled then return end
    if not ShouldAutoLoot() then return end

    local now = GetTime()
    if now - lastLootTime < THROTTLE then return end
    lastLootTime = now

    if GetCursorInfo() then return end

    local count = GetNumLootItems()
    for i = 1, count do
        LootSlot(i)
    end
end

local frame = CreateFrame("Frame", "TomoMod_FastLoot")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if TomoModDB and not TomoModDB.fastLoot then
            TomoModDB.fastLoot = { enabled = true }
        end
        local db = GetDB()
        if db and db.enabled then
            self:RegisterEvent("LOOT_READY")
        end
        self:UnregisterEvent("PLAYER_LOGIN")
    elseif event == "LOOT_READY" then
        CollectLoot()
    end
end)

TomoMod_FastLoot = TomoMod_FastLoot or {}
function TomoMod_FastLoot.SetEnabled(v)
    local db = GetDB()
    if not db then return end
    db.enabled = v
    if v then frame:RegisterEvent("LOOT_READY")
    else frame:UnregisterEvent("LOOT_READY") end
end

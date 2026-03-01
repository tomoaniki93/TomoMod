-- =====================================
-- QOL/AH/AHCurrentExpansion.lua
-- Filtre automatique de l'HdV sur l'extension actuelle
--
-- À l'ouverture de l'hôtel des ventes, active le filtre
-- "Extension actuelle uniquement" si l'option est activée.
-- Inspiré de NaowhQOL/Modules/AuctionHouseFilter.lua.
-- =====================================

TomoMod_AHCurrentExpansion = TomoMod_AHCurrentExpansion or {}
local AH = TomoMod_AHCurrentExpansion

local function GetDB()
    return TomoModDB and TomoModDB.ahCurrentExpansion
end

local function ApplyFilter()
    local db = GetDB()
    if not db or not db.enabled then return end

    -- Attendre 0 tick pour que l'AH ait fini d'ouvrir ses frames
    C_Timer.After(0, function()
        if not AuctionHouseFrame then return end
        local searchBar = AuctionHouseFrame.SearchBar
        if not searchBar then return end

        local filterBtn = searchBar.FilterButton
        if not filterBtn or not filterBtn.filters then return end

        filterBtn.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly] = true

        if searchBar.UpdateClearFiltersButton then
            searchBar:UpdateClearFiltersButton()
        end
    end)
end

-- =====================================
-- Événements
-- =====================================
local frame = CreateFrame("Frame", "TomoMod_AHCurrentExpansion")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if TomoModDB and not TomoModDB.ahCurrentExpansion then
            TomoModDB.ahCurrentExpansion = { enabled = false }
        end
        local db = GetDB()
        if db and db.enabled then
            self:RegisterEvent("AUCTION_HOUSE_SHOW")
        end
        self:UnregisterEvent("PLAYER_LOGIN")

    elseif event == "AUCTION_HOUSE_SHOW" then
        ApplyFilter()
    end
end)

-- =====================================
-- API publique
-- =====================================
function AH.SetEnabled(v)
    local db = GetDB()
    if not db then return end
    db.enabled = v
    if v then
        frame:RegisterEvent("AUCTION_HOUSE_SHOW")
    else
        frame:UnregisterEvent("AUCTION_HOUSE_SHOW")
    end
end

function AH.ApplyNow()
    ApplyFilter()
end

TomoMod_RegisterModule("ahCurrentExpansion", AH)

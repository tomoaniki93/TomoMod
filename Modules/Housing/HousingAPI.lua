-- =====================================
-- Modules/Housing/HousingAPI.lua — Shared helpers
-- Inspiré de Plumber/Modules/Housing/Housing_API.lua (réécrit pour TomoMod)
-- =====================================

TomoMod_Housing = TomoMod_Housing or {}
local H = TomoMod_Housing
local L = TomoMod_L

-- Sub-namespace
H.API = H.API or {}
local API = H.API

-- Locals API
local C_Housing          = C_Housing
local C_HousingCatalog   = C_HousingCatalog
local C_HousingDecor     = C_HousingDecor
local C_HouseEditor      = C_HouseEditor
local C_HousingNeighborhood = C_HousingNeighborhood

-- =====================================
-- AVAILABILITY GUARD
-- Some clients may not have Housing APIs (pre-Midnight). The module
-- must not crash on those; it just shouldn't activate.
-- =====================================

function API.IsHousingAvailable()
    return C_Housing and C_HouseEditor and C_HousingCatalog and true or false
end

-- =====================================
-- DB ACCESSORS (shorthand)
-- =====================================

function API.GetDB()
    return TomoModDB and TomoModDB.housing
end

function API.GetDBBool(key)
    local db = API.GetDB()
    return db and db[key] and true or false
end

function API.GetDBValue(key)
    local db = API.GetDB()
    return db and db[key]
end

function API.SetDBValue(key, value)
    local db = API.GetDB()
    if db then db[key] = value end
end

function API.FlipDBBool(key)
    local db = API.GetDB()
    if db then db[key] = not db[key] end
    return API.GetDBBool(key)
end

-- =====================================
-- CATALOG HELPERS
-- =====================================

-- Enum.HousingCatalogEntryType.Decor == 1
local DECOR_ENTRY_TYPE = 1

function API.GetCatalogDecorInfo(decorID)
    if not (C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByRecordID) then
        return nil
    end
    local tryGetOwnedInfo = true
    return C_HousingCatalog.GetCatalogEntryInfoByRecordID(DECOR_ENTRY_TYPE, decorID, tryGetOwnedInfo)
end

function API.GetDecorSourceText(decorID, ownedOnly)
    if not (C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByRecordID) then
        return nil
    end
    if ownedOnly then
        local info = C_HousingCatalog.GetCatalogEntryInfoByRecordID(DECOR_ENTRY_TYPE, decorID, true)
        return info and info.quantity and info.quantity > 0 and info.sourceText
    else
        local info = C_HousingCatalog.GetCatalogEntryInfoByRecordID(DECOR_ENTRY_TYPE, decorID, false)
        return info and info.sourceText
    end
end

-- =====================================
-- TIME FORMAT (for editor clock session counter)
-- =====================================

function API.SecondsToTime(seconds, forceShowMinutes, showSeconds)
    seconds = math.floor(seconds or 0)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        if showSeconds then
            return string.format("%dh %02dm %02ds", h, m, s)
        else
            return string.format("%dh %02dm", h, m)
        end
    elseif m > 0 or forceShowMinutes then
        if showSeconds then
            return string.format("%dm %02ds", m, s)
        else
            return string.format("%dm", m)
        end
    else
        return string.format("%ds", s)
    end
end

-- =====================================
-- ZONE DETECTION
-- =====================================

function API.IsInHousingZone()
    if not C_Housing then return false end
    local insideHouseOrPlot = C_Housing.IsInsideHouseOrPlot and C_Housing.IsInsideHouseOrPlot()
    local onNeighborhoodMap = C_Housing.IsOnNeighborhoodMap and C_Housing.IsOnNeighborhoodMap()
    return insideHouseOrPlot or onNeighborhoodMap
end

function API.IsHouseEditorActive()
    return C_HouseEditor and C_HouseEditor.IsHouseEditorActive and C_HouseEditor.IsHouseEditorActive()
end

-- =====================================
-- HOUSE INFO CACHE
-- Tracks the player's owned houses for teleport action buttons.
-- =====================================

API.houseInfoList = nil
API.playerhasHomeInFaction = { [1] = false, [2] = false }
API.numHomes = 0
API.teleportHomeInfo = {}

-- Neighborhood uiMapID → faction index (1 Alliance, 2 Horde)
API.NeighborhoodMapIndex = {
    [2352] = 1, -- Alliance, Founder's Point
    [2351] = 2, -- Horde, Razorwind Shores
}

function API.GetPlayerFactionIndex()
    local faction = UnitFactionGroup("player")
    if faction == "Horde" then return 2 end
    return 1 -- Alliance is default
end

function API.GetMaxHousesPlayerCanOwn()
    return 2
end

function API.GetAllianceMapName()
    if not API._mapName1 then
        local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(2352)
        API._mapName1 = (info and info.name) or (L and L["housing_alliance_zone"]) or "Founder's Point"
    end
    return API._mapName1
end

function API.GetHordeMapName()
    if not API._mapName2 then
        local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(2351)
        API._mapName2 = (info and info.name) or (L and L["housing_horde_zone"]) or "Razorwind Shores"
    end
    return API._mapName2
end

-- =====================================
-- TELEPORT COOLDOWN
-- =====================================

function API.GetTeleportCooldownText()
    if not (C_Housing and C_Housing.GetVisitCooldownInfo) then return nil end
    local cd = C_Housing.GetVisitCooldownInfo()
    if cd and cd.isEnabled then
        local endTime = cd.startTime + cd.duration
        local diff = endTime - GetTime()
        if diff > 1 then
            return API.SecondsToTime(diff, true, true)
        end
    end
    return nil
end

function API.CheckTeleportInCooldown()
    local timeString = API.GetTeleportCooldownText()
    if timeString then
        local messageType = 0
        if UIErrorsFrame and UIErrorsFrame.TryDisplayMessage then
            local fmt = ITEM_COOLDOWN_TIME or "Cooldown: %s"
            local red = RED_FONT_COLOR or { r = 1, g = 0.1, b = 0.1 }
            local r, g, b = 1, 0.1, 0.1
            if red.GetRGB then r, g, b = red:GetRGB() end
            UIErrorsFrame:TryDisplayMessage(messageType, fmt:format("|cffffffff" .. timeString .. "|r"), r, g, b)
        end
        return true
    end
    return false
end

-- =====================================
-- HOUSE LIST — process owned houses & populate teleport buttons
-- =====================================

function API.ProcessHouseInfoList()
    API.teleportHomeInfo = {}
    API.playerhasHomeInFaction = { [1] = false, [2] = false }
    API.numHomes = 0

    if not API.houseInfoList or #API.houseInfoList == 0 then return end

    local factionIndex = API.GetPlayerFactionIndex()
    local buttons = H.TeleportHomeButtons

    for i = 1, API.GetMaxHousesPlayerCanOwn() do
        local info = API.houseInfoList[i]
        if info then
            local uiMapID = C_Housing.GetUIMapIDForNeighborhood and C_Housing.GetUIMapIDForNeighborhood(info.neighborhoodGUID)
            local mapIndex = uiMapID and API.NeighborhoodMapIndex[uiMapID]

            if mapIndex then
                API.playerhasHomeInFaction[mapIndex] = true
                API.numHomes = API.numHomes + 1
            else
                mapIndex = 1
            end

            if buttons then
                if (i == 1 or mapIndex == factionIndex) and buttons.CurrentFaction then
                    buttons.CurrentFaction:SetAction_TeleportHome(info.neighborhoodGUID, info.houseGUID, info.plotID)
                end
                if mapIndex == 1 and buttons.Alliance then
                    buttons.Alliance:SetAction_TeleportHome(info.neighborhoodGUID, info.houseGUID, info.plotID)
                elseif mapIndex == 2 and buttons.Horde then
                    buttons.Horde:SetAction_TeleportHome(info.neighborhoodGUID, info.houseGUID, info.plotID)
                end
            end

            API.teleportHomeInfo[i] = {
                ownerName = info.ownerName,
                houseName = info.houseName,
                mapIndex  = mapIndex,
            }
        end
    end
end

-- LoadHouses: one-shot fetch, wires PLAYER_HOUSE_LIST_UPDATED once
local loaderFrame
function API.LoadHouses()
    if not (C_Housing and C_Housing.GetPlayerOwnedHouses) then return end
    if not loaderFrame then
        loaderFrame = CreateFrame("Frame")
        loaderFrame:SetScript("OnEvent", function(self, event, list)
            if event == "PLAYER_HOUSE_LIST_UPDATED" then
                self:UnregisterEvent(event)
                API.houseInfoList = list
                API.ProcessHouseInfoList()
            end
        end)
    end
    loaderFrame:RegisterEvent("PLAYER_HOUSE_LIST_UPDATED")
    C_Housing.GetPlayerOwnedHouses()
end

function API.RequestUpdateHouseInfo()
    if API._isUpdating then return end
    API._isUpdating = true
    API.LoadHouses()
    C_Timer.After(1, function() API._isUpdating = nil end)
end

-- =====================================
-- PUBLIC EXPORT (for convenience in other submodules)
-- =====================================

H.GetCatalogDecorInfo = API.GetCatalogDecorInfo
H.GetDecorSourceText  = API.GetDecorSourceText
H.IsInHousingZone     = API.IsInHousingZone
H.IsHouseEditorActive = API.IsHouseEditorActive
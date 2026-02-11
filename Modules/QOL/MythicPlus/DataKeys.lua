-- =====================================
-- DataKeys.lua
-- Fallback table: MapChallengeModeID → Dungeon Name / Short / Teleport
-- Used when C_ChallengeMode.GetMapUIInfo() returns nil
-- (TWW secret values, data not yet loaded, etc.)
--
-- Also includes a DYNAMIC RUNTIME CACHE that auto-discovers
-- dungeon names and season data from Blizzard APIs once loaded.
-- =====================================

TomoMod_DataKeys = {}

-- Master table: [mapChallengeModeID] = { full, short, teleportSpellID }
local DB = {

    -- =================================
    -- Wrath of the Lich King
    -- =================================
    [556] = { "Pit of Saron",                          "PIT",    1254555 },

    -- =================================
    -- Mists of Pandaria
    -- =================================
    [2]   = { "Temple of the Jade Serpent",             "TJS",    131204  },
    [56]  = { "Stormstout Brewery",                     "SSB",    131205  },
    [57]  = { "Shado-Pan Monastery",                    "SPM",    131206  },
    [58]  = { "Siege of Niuzao Temple",                 "SNT",    131228  },
    [59]  = { "Gate of the Setting Sun",                "GOTSS",  131225  },
    [60]  = { "Mogu'shan Palace",                       "MSP",    131222  },
    [76]  = { "Scholomance",                            "SCHOLO", 131232  },
    [77]  = { "Scarlet Halls",                          "SH",     131231  },
    [78]  = { "Scarlet Monastery",                      "SM",     131229  },

    -- =================================
    -- Warlords of Draenor
    -- =================================
    [161] = { "Bloodmaul Slag Mines",                   "BSM",    159895  },
    [163] = { "Auchindoun",                             "AUCH",   159897  },
    [164] = { "Skyreach",                               "SKY",    159898  },
    [165] = { "Shadowmoon Burial Grounds",              "SBG",    159899  },
    [166] = { "Grimrail Depot",                         "GD",     159900  },
    [167] = { "Upper Blackrock Spire",                  "UBRS",   159902  },
    [168] = { "The Everbloom",                          "EB",     159901  },
    [169] = { "Iron Docks",                             "ID",     159896  },

    -- =================================
    -- Legion
    -- =================================
    [197] = { "Eye of Azshara",                         "EOA",    nil     },
    [198] = { "Darkheart Thicket",                      "DT",     424163  },
    [199] = { "Black Rook Hold",                        "BRH",    424153  },
    [200] = { "Halls of Valor",                         "HOV",    393764  },
    [206] = { "Neltharion's Lair",                      "NL",     410078  },
    [207] = { "Vault of the Wardens",                   "VAULT",  nil     },
    [208] = { "Maw of Souls",                           "MOS",    nil     },
    [209] = { "The Arcway",                             "ARC",    nil     },
    [210] = { "Court of Stars",                         "COS",    393766  },
    [227] = { "Return to Karazhan: Lower",              "LKARA",  373262  },
    [233] = { "Cathedral of Eternal Night",             "COEN",   nil     },
    [234] = { "Return to Karazhan: Upper",              "UKARA",  373262  },
    [239] = { "Seat of the Triumvirate",                "SEAT",   1254551 },

    -- =================================
    -- Battle for Azeroth
    -- =================================
    [244] = { "Atal'Dazar",                             "AD",     424187  },
    [245] = { "Freehold",                               "FH",     410071  },
    [246] = { "Tol Dagor",                              "TD",     nil     },
    [247] = { "The MOTHERLODE!!",                       "ML",     nil     },
    [248] = { "Waycrest Manor",                         "WM",     424167  },
    [249] = { "Kings' Rest",                            "KR",     nil     },
    [250] = { "Temple of Sethraliss",                   "SETH",   nil     },
    [251] = { "The Underrot",                           "UNDR",   410074  },
    [252] = { "Shrine of the Storm",                    "SHRINE", nil     },
    [353] = { "Siege of Boralus",                       "SIEGE",  nil     },
    [369] = { "Operation: Mechagon - Junkyard",         "YARD",   373274  },
    [370] = { "Operation: Mechagon - Workshop",         "WORK",   373274  },

    -- =================================
    -- Shadowlands
    -- =================================
    [375] = { "Mists of Tirna Scithe",                  "MISTS",  354464  },
    [376] = { "The Necrotic Wake",                      "NW",     354462  },
    [377] = { "De Other Side",                          "DOS",    354468  },
    [378] = { "Halls of Atonement",                     "HOA",    354465  },
    [379] = { "Plaguefall",                             "PF",     354463  },
    [380] = { "Sanguine Depths",                        "SD",     354469  },
    [381] = { "Spires of Ascension",                    "SOA",    354466  },
    [382] = { "Theater of Pain",                        "TOP",    354467  },
    [391] = { "Tazavesh: Streets of Wonder",            "STRT",   367416  },
    [392] = { "Tazavesh: So'leah's Gambit",             "GMBT",   367416  },

    -- =================================
    -- Dragonflight
    -- =================================
    [399] = { "Ruby Life Pools",                        "RLP",    393256  },
    [400] = { "The Nokhud Offensive",                   "NO",     393262  },
    [401] = { "The Azure Vault",                        "AV",     393279  },
    [402] = { "Algeth'ar Academy",                      "AA",     393273  },
    [403] = { "Uldaman: Legacy of Tyr",                 "ULD",    393222  },
    [404] = { "Neltharus",                              "NELTH",  393276  },
    [405] = { "Brackenhide Hollow",                     "BH",     393267  },
    [406] = { "Halls of Infusion",                      "HOI",    393283  },
    [463] = { "Dawn of the Infinite: Galakrond's Fall", "DOTI",   424197  },
    [464] = { "Dawn of the Infinite: Murozond's Rise",  "DOTI",   424197  },

    -- =================================
    -- Cataclysm
    -- =================================
    [438] = { "Vortex Pinnacle",                        "VP",     410080  },
    [456] = { "Throne of the Tides",                    "TOTT",   424142  },

    -- =================================
    -- The War Within
    -- =================================
    [499] = { "Priory of the Sacred Flame",             "PSF",    445444  },
    [500] = { "The Rookery",                            "ROOK",   445443  },
    [501] = { "The Stonevault",                         "SV",     445269  },
    [502] = { "City of Threads",                        "COT",    445416  },
    [503] = { "Ara-Kara, City of Echoes",               "ARAK",   445417  },
    [504] = { "Darkflame Cleft",                        "DFC",    445441  },
    [505] = { "The Dawnbreaker",                        "DAWN",   445414  },
    [506] = { "Cinderbrew Meadery",                     "BREW",   445440  },
    [507] = { "Grim Batol",                             "GB",     445424  },
    [525] = { "Operation: Floodgate",                   "FLOOD",  1216786 },
    [542] = { "Eco-Dome Al'dani",                       "EDA",    1237215 },

    -- =================================
    -- Midnight (12.x)
    -- =================================
    [557] = { "Windrunner Spire",                       "WIND",   1254840 },
    [558] = { "Magisters' Terrace",                     "MAGI",   1254572 },
    [559] = { "Nexus-Point Xenas",                      "XENAS",  1254563 },
    [560] = { "Maisara Caverns",                        "CAVNS",  1255247 },
}

-- =====================================
-- Name → short abbreviation mapping (for API-discovered dungeons)
-- Used to generate short names for dungeons not in the hardcoded DB
-- =====================================
local NAME_TO_SHORT = {}
for _, data in pairs(DB) do
    if data[1] and data[2] then
        NAME_TO_SHORT[data[1]:lower()] = data[2]
    end
end

-- =====================================
-- Dynamic runtime cache
-- Populated from Blizzard APIs when data becomes available
-- [mapChallengeModeID] = { name, short, texture }
-- =====================================
local runtimeCache = {}
local runtimeSeasonIDs = nil  -- populated from C_ChallengeMode.GetMapTable()
local apiDataReady = false

--- Attempt to populate the runtime cache from Blizzard APIs
--- Safe to call multiple times — will refresh data each time
function TomoMod_DataKeys.RefreshFromAPI()
    if not C_ChallengeMode then return false end

    -- Discover current season dungeon IDs
    if C_ChallengeMode.GetMapTable then
        local ok, mapTable = pcall(C_ChallengeMode.GetMapTable)
        if ok and mapTable and #mapTable > 0 then
            runtimeSeasonIDs = mapTable
        end
    end

    -- Populate names from API for all known IDs
    local idsToQuery = {}

    -- Add season IDs
    if runtimeSeasonIDs then
        for _, id in ipairs(runtimeSeasonIDs) do
            idsToQuery[id] = true
        end
    end

    -- Also query any IDs we know from DB but might have updated names
    for id in pairs(DB) do
        idsToQuery[id] = true
    end

    local anyResolved = false
    if C_ChallengeMode.GetMapUIInfo then
        for id in pairs(idsToQuery) do
            local ok, name, _, _, tex = pcall(C_ChallengeMode.GetMapUIInfo, id)
            if ok and name and name ~= "" then
                -- Generate short name: use hardcoded if exists, else from name mapping, else abbreviate
                local short = nil
                local dbEntry = DB[id]
                if dbEntry and dbEntry[2] then
                    short = dbEntry[2]
                elseif NAME_TO_SHORT[name:lower()] then
                    short = NAME_TO_SHORT[name:lower()]
                end

                runtimeCache[id] = {
                    name    = name,
                    short   = short,
                    texture = tex,
                }
                anyResolved = true
            end
        end
    end

    if anyResolved then
        apiDataReady = true
    end

    return anyResolved
end

--- Check if API data has been loaded
function TomoMod_DataKeys.IsAPIReady()
    return apiDataReady
end

-- =====================================
-- Reverse lookup: name/short → mapID (case-insensitive)
-- =====================================
local nameToMapID = {}
for id, data in pairs(DB) do
    if data[1] then nameToMapID[data[1]:lower()] = id end
    if data[2] then nameToMapID[data[2]:lower()] = id end
end

-- =====================================
-- PUBLIC API
-- =====================================

--- Get full dungeon name from MapChallengeModeID
--- Priority: runtime cache (API) → hardcoded DB → nil
function TomoMod_DataKeys.GetDungeonName(mapID)
    if not mapID then return nil end
    mapID = tonumber(mapID)
    if not mapID then return nil end

    -- 1) Check runtime cache (populated from API)
    local cached = runtimeCache[mapID]
    if cached and cached.name then
        return cached.name
    end

    -- 2) Try API directly (in case RefreshFromAPI hasn't run yet)
    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local ok, name = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
        if ok and name and name ~= "" then
            -- Cache it for future use
            runtimeCache[mapID] = runtimeCache[mapID] or {}
            runtimeCache[mapID].name = name
            return name
        end
    end

    -- 3) Fallback to hardcoded table
    local entry = DB[mapID]
    return entry and entry[1] or nil
end

--- Get short dungeon abbreviation
function TomoMod_DataKeys.GetShortName(mapID)
    if not mapID then return nil end
    mapID = tonumber(mapID)
    if not mapID then return nil end

    -- Check runtime cache
    local cached = runtimeCache[mapID]
    if cached and cached.short then
        return cached.short
    end

    -- Check hardcoded DB
    local entry = DB[mapID]
    return entry and entry[2] or nil
end

--- Get name with fallback chain: runtime cache → API → full → short → "ID:xxx"
function TomoMod_DataKeys.GetDisplayName(mapID)
    return TomoMod_DataKeys.GetDungeonName(mapID)
        or TomoMod_DataKeys.GetShortName(mapID)
        or ("ID:" .. tostring(mapID))
end

--- Get teleport spell ID for a dungeon
function TomoMod_DataKeys.GetTeleportSpellID(mapID)
    if not mapID then return nil end
    mapID = tonumber(mapID)
    if not mapID then return nil end
    local entry = DB[mapID]
    return entry and entry[3] or nil
end

--- Lookup mapID by dungeon name or short name (case-insensitive)
function TomoMod_DataKeys.GetMapIDByName(name)
    if not name then return nil end
    return nameToMapID[name:lower()]
end

--- Get the raw DB entry: { fullName, shortName, teleportSpellID }
--- Also checks runtime cache for entries not in hardcoded DB
function TomoMod_DataKeys.GetEntry(mapID)
    if not mapID then return nil end
    mapID = tonumber(mapID)
    if not mapID then return nil end

    -- Hardcoded DB first (has spellID)
    local entry = DB[mapID]
    if entry then return entry end

    -- Fallback: build a synthetic entry from runtime cache
    local cached = runtimeCache[mapID]
    if cached and cached.name then
        return { cached.name, cached.short or cached.name, nil }
    end

    return nil
end

--- Get all known mapIDs (sorted, for iteration)
function TomoMod_DataKeys.GetAllMapIDs()
    local ids = {}
    local seen = {}
    for id in pairs(DB) do
        ids[#ids + 1] = id
        seen[id] = true
    end
    -- Include runtime-discovered IDs
    for id in pairs(runtimeCache) do
        if not seen[id] then
            ids[#ids + 1] = id
            seen[id] = true
        end
    end
    table.sort(ids)
    return ids
end

-- =====================================
-- CURRENT M+ SEASON
-- Dynamically populated from C_ChallengeMode.GetMapTable()
-- Falls back to hardcoded list if API data not available
-- =====================================
local HARDCODED_SEASON = {
    542,  -- Eco-Dome Al'dani
    499,  -- Priory of the Sacred Flame
    525,  -- Operation: Floodgate
    503,  -- Ara-Kara, City of Echoes
    505,  -- The Dawnbreaker
    378,  -- Halls of Atonement
    391,  -- Tazavesh: Streets of Wonder
    392,  -- Tazavesh: So'leah's Gambit
}

--- Get the current season dungeon ID list
--- Uses API data when available, falls back to hardcoded
function TomoMod_DataKeys.GetCurrentSeasonIDs()
    if runtimeSeasonIDs and #runtimeSeasonIDs > 0 then
        return runtimeSeasonIDs
    end
    return HARDCODED_SEASON
end

-- Keep backward compat (some code may read this directly)
TomoMod_DataKeys.CURRENT_SEASON = HARDCODED_SEASON

--- Get current season dungeon list with full data
--- Dynamically resolves names for API-discovered dungeons
function TomoMod_DataKeys.GetCurrentSeasonData()
    local seasonIDs = TomoMod_DataKeys.GetCurrentSeasonIDs()
    local result = {}

    for _, mapID in ipairs(seasonIDs) do
        -- Try hardcoded DB first (has spellID for TP)
        local entry = DB[mapID]
        if entry then
            result[#result + 1] = {
                mapID    = mapID,
                name     = entry[1],
                short    = entry[2],
                spellID  = entry[3],
            }
        else
            -- Fallback: build from runtime cache / API
            local name = TomoMod_DataKeys.GetDungeonName(mapID) or ("ID:" .. mapID)
            local short = TomoMod_DataKeys.GetShortName(mapID) or name
            local spellID = nil  -- unknown for API-discovered dungeons

            result[#result + 1] = {
                mapID    = mapID,
                name     = name,
                short    = short,
                spellID  = spellID,
            }
        end
    end

    return result
end

-- =====================================
-- Auto-refresh on events (deferred init)
-- =====================================
local refreshFrame = CreateFrame("Frame")
refreshFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
refreshFrame:RegisterEvent("MYTHIC_PLUS_NEW_SEASON")
refreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

local refreshCount = 0
refreshFrame:SetScript("OnEvent", function(_, event)
    -- Try to refresh from API on relevant events
    TomoMod_DataKeys.RefreshFromAPI()

    -- On PLAYER_ENTERING_WORLD, schedule a few retries
    -- because challenge mode data often loads after a delay
    if event == "PLAYER_ENTERING_WORLD" and refreshCount == 0 then
        refreshCount = 1
        C_Timer.After(2, function()
            TomoMod_DataKeys.RefreshFromAPI()
        end)
        C_Timer.After(5, function()
            TomoMod_DataKeys.RefreshFromAPI()
        end)
        C_Timer.After(10, function()
            TomoMod_DataKeys.RefreshFromAPI()
            -- Update CURRENT_SEASON reference for backward compat
            local ids = TomoMod_DataKeys.GetCurrentSeasonIDs()
            if ids and #ids > 0 then
                TomoMod_DataKeys.CURRENT_SEASON = ids
            end
        end)
    end
end)

-- Also request map info to trigger data loading
if C_ChallengeMode and C_ChallengeMode.RequestMapInfo then
    pcall(C_ChallengeMode.RequestMapInfo)
end

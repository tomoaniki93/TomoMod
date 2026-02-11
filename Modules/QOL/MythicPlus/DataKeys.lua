-- =====================================
-- DataKeys.lua
-- Fallback table: MapChallengeModeID → Dungeon Name / Short / Teleport
-- Used when C_ChallengeMode.GetMapUIInfo() returns nil
-- (TWW secret values, data not yet loaded, etc.)
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
    -- Future Midnight dungeons (no mapID yet):
    -- Murder Row          = "MURDR"
    -- The Blinding Vale   = "BLIND"
    -- Den of Nalorakk     = "NALO"
    -- The Foraging        = "FORAG"
    -- Voidscar Arena      = "VSCAR"
    -- The Heart of Rage   = "RAGE"
    -- Voidstorm           = "VSTORM"
}

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
--- Tries Blizzard API first, falls back to hardcoded table
function TomoMod_DataKeys.GetDungeonName(mapID)
    if not mapID then return nil end
    mapID = tonumber(mapID)
    if not mapID then return nil end

    -- Try API first (works when data is loaded and not tainted)
    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local ok, name = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
        if ok and name and name ~= "" then return name end
    end

    -- Fallback to our table
    local entry = DB[mapID]
    return entry and entry[1] or nil
end

--- Get short dungeon abbreviation
function TomoMod_DataKeys.GetShortName(mapID)
    if not mapID then return nil end
    mapID = tonumber(mapID)
    if not mapID then return nil end
    local entry = DB[mapID]
    return entry and entry[2] or nil
end

--- Get name with fallback chain: API → full → short → "ID:xxx"
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
function TomoMod_DataKeys.GetEntry(mapID)
    if not mapID then return nil end
    mapID = tonumber(mapID)
    return mapID and DB[mapID] or nil
end

--- Get all known mapIDs (sorted, for iteration)
function TomoMod_DataKeys.GetAllMapIDs()
    local ids = {}
    for id in pairs(DB) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    return ids
end

-- =====================================
-- CURRENT M+ SEASON
-- Update this table each new season
-- =====================================
TomoMod_DataKeys.CURRENT_SEASON = {
    542,  -- Eco-Dome Al'dani
    499,  -- Priory of the Sacred Flame
    525,  -- Operation: Floodgate
    503,  -- Ara-Kara, City of Echoes
    505,  -- The Dawnbreaker
    378,  -- Halls of Atonement
    391,  -- Tazavesh: Streets of Wonder
    392,  -- Tazavesh: So'leah's Gambit
}

--- Get current season dungeon list with full data
function TomoMod_DataKeys.GetCurrentSeasonData()
    local result = {}
    for _, mapID in ipairs(TomoMod_DataKeys.CURRENT_SEASON) do
        local entry = DB[mapID]
        if entry then
            result[#result + 1] = {
                mapID    = mapID,
                name     = entry[1],
                short    = entry[2],
                spellID  = entry[3],
            }
        end
    end
    return result
end

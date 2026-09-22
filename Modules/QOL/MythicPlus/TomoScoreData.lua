-- [Compat] WoW: Forever has no Mythic+ content. The frames below register
-- CHALLENGE_MODE_* events this client does not define, which throws on
-- the first RegisterEvent and again on every retry.
-- See Core/Compat.lua.
if TomoMod_Compat and TomoMod_Compat.Blocked("mythicplus") then return end

-- =====================================================================
-- TomoScoreData.lua — Data collection via C_DamageMeter API + preview
-- =====================================================================

local L  = TomoMod_L
local TS = TomoMod_TomoScore
local DK = TomoMod_DataKeys

local openRaidLib = TomoMod_KeySync

-- Same helper shape as RunSurvival.lua: issecretvalue() before any use.
local _issecret = issecretvalue
local function IsSecret(v)
    if not _issecret then return false end
    local ok, secret = pcall(_issecret, v)
    return ok and secret or false
end

-- Merge one meter type of the run-wide (Overall) session into the players
-- table, the way DamageMeter/Meter/RunRecap.lua reads run totals.
--
-- This used to call C_DamageMeter.GetCombatSessionSourceFromType(session,
-- type). That API returns ONE source's spell breakdown and needs a
-- sourceGUID: the ipairs() loops over its result never saw a player, so the
-- damage / healing / interrupt columns stayed at 0. The interrupt pass also
-- asked for Enum.DamageMeterType.Actions, which does not exist.
--
-- Read from a timer rather than an event handler, the whole session can come
-- back secret: every level is guarded and the column simply stays at 0.
local function MergeMeterTotals(meterType, field, playersByGUID, playersByName)
    if meterType == nil then return end
    local sessionType = Enum.DamageMeterSessionType and Enum.DamageMeterSessionType.Overall
    if sessionType == nil then return end

    local ok, session = pcall(C_DamageMeter.GetCombatSessionFromType, sessionType, meterType)
    if not ok or not session or IsSecret(session) then return end
    local sources = session.combatSources
    if type(sources) ~= "table" or IsSecret(sources) then return end

    for _, src in ipairs(sources) do
        if type(src) == "table" and not IsSecret(src) then
            local p
            local guid = src.sourceGUID
            if guid ~= nil and not IsSecret(guid) then
                p = playersByGUID[guid]
            end
            if not p then
                local srcName = src.name
                if srcName ~= nil and not IsSecret(srcName) then
                    p = playersByName[srcName]
                end
            end
            local total = src.totalAmount
            if p and total ~= nil and not IsSecret(total) then
                p[field] = total
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Build a snapshot of group data at the current moment
-- ─────────────────────────────────────────────────────────────────────────────
function TS:CollectRunData()
    local data = {
        dungeonName = "",
        keyLevel    = 0,
        isMPlus     = false,
        onTime      = false,
        duration    = 0,
        players     = {},
    }

    local instanceName, _, difficultyID = GetInstanceInfo()
    data.dungeonName = instanceName or "?"
    data.isMPlus = (difficultyID == 8)

    if data.isMPlus then
        local info = C_ChallengeMode.GetChallengeCompletionInfo()
        if info then
            data.keyLevel = info.level or 0
            data.onTime   = info.onTime or false
            data.duration = (info.time or 0) / 1000

            local mapName = C_ChallengeMode.GetMapUIInfo(info.mapChallengeModeID or 0)
            if mapName and not IsSecret(mapName) then data.dungeonName = mapName end
        end
    else
        data.keyLevel = 0
    end

    -- Gather group unit IDs
    local units = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            units[#units + 1] = "raid" .. i
        end
    elseif IsInGroup() then
        units[#units + 1] = "player"
        for i = 1, GetNumGroupMembers() - 1 do
            units[#units + 1] = "party" .. i
        end
    else
        units[#units + 1] = "player"
    end

    -- Build per-player info
    local playersByName = {}
    local playersByGUID = {}
    for _, unit in ipairs(units) do
        if UnitExists(unit) and UnitIsPlayer(unit) then
            local name, realm = UnitName(unit)
            if name then
                local fullName = realm and realm ~= "" and (name .. "-" .. realm) or name
                -- [12.1] nil when the client will not say; consumers colour by
                -- class only when they have one.
                local classFile = TomoMod_Utils and TomoMod_Utils.UnitClassToken(unit)
                local role = TomoMod_Utils.SafeGroupRole(unit)

                -- GetInspectSpecialization only answers for units whose
                -- inspect data is cached, and it returns 0 for the player
                -- themselves. At the end of a run everyone has been inspected;
                -- opening the board from town (/tm keys) is the case where that
                -- is not true, so read the player's own spec directly.
                local specID
                if UnitIsUnit(unit, "player") then
                    local idx = GetSpecialization and GetSpecialization()
                    if idx then specID = GetSpecializationInfo(idx) end
                end
                if not specID or specID == 0 then
                    specID = GetInspectSpecialization(unit)
                end
                local specIcon
                if specID and specID > 0 then
                    _, _, _, specIcon = GetSpecializationInfoByID(specID)
                end

                local rating = 0
                local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
                if ratingSummary then
                    rating = ratingSummary.currentSeasonScore or 0
                end

                local entry = {
                    name       = name,
                    fullName   = fullName,
                    unit       = unit,
                    class      = classFile,
                    role       = role,
                    specID     = specID or 0,
                    specIcon   = specIcon or nil,
                    rating     = rating,
                    keyLevel   = 0,
                    keyMapID   = nil,
                    keyName    = nil,
                    keySpellID = nil,
                    damage     = 0,
                    healing    = 0,
                    interrupts = 0,
                }
                playersByName[fullName] = entry
                local guid = UnitGUID(unit)
                if guid ~= nil and not IsSecret(guid) then
                    playersByGUID[guid] = entry
                end
            end
        end
    end

    -- Pull keystone info from the keystone sync module
    if openRaidLib then
        local allKeys = openRaidLib.GetAllKeystonesInfo and openRaidLib.GetAllKeystonesInfo() or {}
        for pName, pData in pairs(playersByName) do
            local info = allKeys[pName] or allKeys[pData.name]
            if not info and pData.unit then
                info = openRaidLib.GetKeystoneInfo and openRaidLib.GetKeystoneInfo(pData.unit)
            end
            if info and info.level and info.level > 0 then
                local mapID = info.challengeMapID or info.mythicPlusMapID
                pData.keyLevel = info.level
                pData.keyMapID = mapID
                if mapID and DK then
                    pData.keyName    = DK.GetShortName(mapID) or DK.GetDungeonName(mapID)
                    pData.keySpellID = DK.GetTeleportSpellID(mapID)
                end
            end
        end
    end

    -- Pull totals from C_DamageMeter (see MergeMeterTotals above)
    local mtypes = Enum.DamageMeterType
    if C_DamageMeter and C_DamageMeter.GetCombatSessionFromType and mtypes then
        MergeMeterTotals(mtypes.DamageDone,  "damage",     playersByGUID, playersByName)
        MergeMeterTotals(mtypes.HealingDone, "healing",    playersByGUID, playersByName)
        MergeMeterTotals(mtypes.Interrupts,  "interrupts", playersByGUID, playersByName)
    end

    -- Sort: tank → healer → dps, then by damage
    local roleOrder = { TANK = 1, HEALER = 2, DAMAGER = 3, NONE = 4 }
    local sorted = {}
    for _, p in pairs(playersByName) do
        sorted[#sorted + 1] = p
    end
    table.sort(sorted, function(a, b)
        local ra = roleOrder[a.role] or 4
        local rb = roleOrder[b.role] or 4
        if ra ~= rb then return ra < rb end
        -- Damage decides after a run. Outside one it is zero for everyone, and
        -- sorting on it alone left same-role players in `pairs` order, which
        -- reshuffles between two openings of the same board.
        local da, db = a.damage or 0, b.damage or 0
        if da ~= db then return da > db end
        local ka, kb = a.keyLevel or 0, b.keyLevel or 0
        if ka ~= kb then return ka > kb end
        local ga, gb = a.rating or 0, b.rating or 0
        if ga ~= gb then return ga > gb end
        return (a.fullName or "") < (b.fullName or "")
    end)

    data.players = sorted
    return data
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Preview data
-- ─────────────────────────────────────────────────────────────────────────────
function TS:GetPreviewData()
    return {
        dungeonName = "Priory of the Sacred Flame",
        keyLevel    = 12,
        isMPlus     = true,
        onTime      = true,
        duration    = 1523,
        players     = {
            { name = "Tomotank",   fullName = "Tomotank",   class = "WARRIOR",     role = "TANK",    specID = 73,  specIcon = 134952, rating = 2480, keyLevel = 14, keyMapID = 503, keyName = "ARAK",  keySpellID = 445417, damage = 18450000, healing = 1200000,  interrupts = 14 },
            { name = "Holyspring", fullName = "Holyspring", class = "PRIEST",      role = "HEALER",  specID = 257, specIcon = 135940, rating = 2310, keyLevel = 11, keyMapID = 499, keyName = "PSF",   keySpellID = 445444, damage = 4200000,  healing = 42800000, interrupts = 3  },
            { name = "Blazefury",  fullName = "Blazefury",  class = "MAGE",        role = "DAMAGER", specID = 63,  specIcon = 135810, rating = 2650, keyLevel = 11, keyMapID = 501, keyName = "SV",    keySpellID = 445269, damage = 52300000, healing = 350000,   interrupts = 22 },
            { name = "Shadowkill", fullName = "Shadowkill", class = "ROGUE",       role = "DAMAGER", specID = 261, specIcon = 236270, rating = 2120, keyLevel = 0,  keyMapID = nil, keyName = nil,     keySpellID = nil,    damage = 48700000, healing = 280000,   interrupts = 18 },
            { name = "Natureclaw", fullName = "Natureclaw", class = "DRUID",       role = "DAMAGER", specID = 102, specIcon = 136096, rating = 1890, keyLevel = 11, keyMapID = 378, keyName = "HOA",   keySpellID = 354465, damage = 44100000, healing = 1800000,  interrupts = 7  },
        },
    }
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Save / recall last run
-- ─────────────────────────────────────────────────────────────────────────────
function TS:SaveRunData(data)
    local db = self:GetDB()
    if db then
        db.lastRun = data
    end
end

function TS:ShowLastRun()
    local db = self:GetDB()
    if db and db.lastRun then
        self:SafeShowScoreboard(db.lastRun)
    else
        print(L["ts_no_data"])
    end
end

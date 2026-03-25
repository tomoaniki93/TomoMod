-- =====================================================================
-- TomoScoreData.lua — Data collection via C_DamageMeter API + preview
-- =====================================================================

local L = TomoMod_L
local TS = TomoMod_TomoScore

local SOURCE_DAMAGE  = Enum.DamageMeterType and Enum.DamageMeterType.DamageDone  or 0
local SOURCE_HEALING = Enum.DamageMeterType and Enum.DamageMeterType.HealingDone or 1

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
            if mapName then data.dungeonName = mapName end
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
    for _, unit in ipairs(units) do
        if UnitExists(unit) and UnitIsPlayer(unit) then
            local name, realm = UnitName(unit)
            if name then
                local fullName = realm and realm ~= "" and (name .. "-" .. realm) or name
                local _, classFile = UnitClass(unit)
                local role = UnitGroupRolesAssigned(unit)

                local specID = GetInspectSpecialization(unit)
                local specIcon
                if specID and specID > 0 then
                    _, _, _, specIcon = GetSpecializationInfoByID(specID)
                end

                local rating = 0
                local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
                if ratingSummary then
                    rating = ratingSummary.currentSeasonScore or 0
                end

                playersByName[fullName] = {
                    name      = name,
                    fullName  = fullName,
                    unit      = unit,
                    class     = classFile,
                    role      = role,
                    specID    = specID or 0,
                    specIcon  = specIcon or nil,
                    rating    = rating,
                    damage    = 0,
                    healing   = 0,
                    interrupts = 0,
                }
            end
        end
    end

    -- Pull totals from C_DamageMeter
    local SESSION_CURRENT = 0
    if C_DamageMeter and C_DamageMeter.GetCombatSessionSourceFromType then
        local damageSources = C_DamageMeter.GetCombatSessionSourceFromType(SESSION_CURRENT, SOURCE_DAMAGE)
        if damageSources then
            for _, src in ipairs(damageSources) do
                local pName = src.name or src.unitName
                if pName and playersByName[pName] then
                    local total = src.totalAmount or 0
                    if not issecurevariable or not issecretvalue or not issecretvalue(total) then
                        playersByName[pName].damage = total
                    end
                end
            end
        end

        local healSources = C_DamageMeter.GetCombatSessionSourceFromType(SESSION_CURRENT, SOURCE_HEALING)
        if healSources then
            for _, src in ipairs(healSources) do
                local pName = src.name or src.unitName
                if pName and playersByName[pName] then
                    local total = src.totalAmount or 0
                    if not issecurevariable or not issecretvalue or not issecretvalue(total) then
                        playersByName[pName].healing = total
                    end
                end
            end
        end

        local interruptType = Enum.DamageMeterType and Enum.DamageMeterType.Actions or 2
        local ok, intSources = pcall(C_DamageMeter.GetCombatSessionSourceFromType, SESSION_CURRENT, interruptType)
        if ok and intSources then
            for _, src in ipairs(intSources) do
                local pName = src.name or src.unitName
                if pName and playersByName[pName] then
                    local total = src.totalAmount or 0
                    if not issecurevariable or not issecretvalue or not issecretvalue(total) then
                        playersByName[pName].interrupts = total
                    end
                end
            end
        end
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
        return (a.damage or 0) > (b.damage or 0)
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
            { name = "Tomotank",   fullName = "Tomotank",   class = "WARRIOR",     role = "TANK",    specID = 73,  specIcon = 134952, rating = 2480, damage = 18450000, healing = 1200000,  interrupts = 14 },
            { name = "Holyspring", fullName = "Holyspring", class = "PRIEST",      role = "HEALER",  specID = 257, specIcon = 135940, rating = 2310, damage = 4200000,  healing = 42800000, interrupts = 3  },
            { name = "Blazefury",  fullName = "Blazefury",  class = "MAGE",        role = "DAMAGER", specID = 63,  specIcon = 135810, rating = 2650, damage = 52300000, healing = 350000,   interrupts = 22 },
            { name = "Shadowkill", fullName = "Shadowkill", class = "ROGUE",       role = "DAMAGER", specID = 261, specIcon = 236270, rating = 2120, damage = 48700000, healing = 280000,   interrupts = 18 },
            { name = "Natureclaw", fullName = "Natureclaw", class = "DRUID",       role = "DAMAGER", specID = 102, specIcon = 136096, rating = 1890, damage = 44100000, healing = 1800000,  interrupts = 7  },
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
        self:ShowScoreboard(db.lastRun)
    else
        print(L["ts_no_data"])
    end
end

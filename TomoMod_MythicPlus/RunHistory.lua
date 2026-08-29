-- =====================================================================
-- TomoMod_MythicPlus / RunHistory.lua
-- Local, persistent Mythic+ completion history. It deliberately records
-- only runs observed by TomoMod from V1 onward; Blizzard's historical list
-- is used for dashboard context but is never rewritten as local history.
-- =====================================================================

local MP = TomoMod_MythicPlus
if not MP then return end

local RH = {}
MP.RunHistory = RH

local _issecret = issecretvalue
local function IsSecret(v)
    if not _issecret then return false end
    local ok, secret = pcall(_issecret, v)
    return ok and secret or false
end

local function Num(v)
    if v == nil or IsSecret(v) or type(v) ~= "number" then return nil end
    return v
end

local function Bool(v)
    if v == nil or IsSecret(v) then return nil end
    return v and true or false
end

local function Str(v)
    if v == nil or IsSecret(v) or type(v) ~= "string" then return nil end
    return v
end

local function ScoreNow()
    if C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore then
        return Num(C_ChallengeMode.GetOverallDungeonScore()) or 0
    end
    if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        return summary and (Num(summary.currentSeasonScore) or 0) or 0
    end
    return 0
end

local function CurrentSeason()
    if C_MythicPlus and C_MythicPlus.GetCurrentSeason then
        return Num(C_MythicPlus.GetCurrentSeason()) or 0
    end
    return 0
end

local function MapInfo(mapID)
    if not mapID or mapID <= 0 or not C_ChallengeMode or not C_ChallengeMode.GetMapUIInfo then
        return nil, nil, nil
    end
    local name, _, limit, texture = C_ChallengeMode.GetMapUIInfo(mapID)
    return Str(name), Num(limit), Num(texture)
end

local function DeathsNow()
    if not C_ChallengeMode or not C_ChallengeMode.GetDeathCount then return nil end
    local deaths = C_ChallengeMode.GetDeathCount()
    return Num(deaths)
end

local function PlayerName()
    local name = UnitName("player") or "?"
    local realm = GetRealmName and GetRealmName() or ""
    if realm ~= "" then return name .. "-" .. realm:gsub("%s+", "") end
    return name
end

local function Runs()
    local db = MP:GetDB()
    db.history = db.history or { maxRuns = 100, runs = {} }
    db.history.runs = db.history.runs or {}
    return db.history.runs
end

local function Trim()
    local db = MP:GetDB()
    local runs = Runs()
    -- Fixed V1.1 ceiling: this is intentionally not a user-facing slider.
    -- One hundred complete runs is enough for comparison and trend analysis
    -- without letting SavedVariables grow indefinitely.
    db.history.maxRuns = 100
    while #runs > 100 do table.remove(runs) end
end

local function Fingerprint(run)
    return table.concat({
        tostring(run.mapID or 0), tostring(run.level or 0),
        tostring(run.durationMS or 0), tostring(run.finishedAt or 0),
    }, ":")
end

local function SnapshotSplits()
    local tracker = _G.TomoMod_MythicTracker
    if not tracker then return nil, nil end

    local times  = type(tracker.bossKillTimes) == "table" and tracker.bossKillTimes or {}
    local forces = type(tracker.bossForces) == "table" and tracker.bossForces or {}
    local names  = type(tracker._ejByIndex) == "table" and tracker._ejByIndex or {}
    local maxIndex = math.max(#times, #forces, #names)
    local bosses = {}

    for i = 1, maxIndex do
        local killTime = Num(times[i])
        local forcePct = Num(forces[i])
        local name = Str(names[i])
        if killTime or forcePct then
            bosses[#bosses + 1] = {
                index = i,
                name = name or ("Boss " .. i),
                time = killTime,
                forces = forcePct,
            }
        end
    end

    return bosses, Num(tracker.forcesCompTime)
end

function RH:Start()
    local db = MP:GetDB()
    if not (db.modules and db.modules.runHistory) then
        self.active = nil
        return
    end

    local mapID = C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID
        and Num(C_ChallengeMode.GetActiveChallengeMapID()) or nil
    local level = C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo
        and Num(C_ChallengeMode.GetActiveKeystoneInfo()) or nil

    self.active = {
        startedAt = time(),
        mapID = mapID or 0,
        level = level or 0,
        deaths = DeathsNow() or 0,
        scoreBefore = ScoreNow(),
        seasonID = CurrentSeason(),
        character = PlayerName(),
    }

    -- Some clients resolve the challenge map one frame after the start event.
    -- A one-shot retry fills only fields that were unavailable; it never
    -- overwrites an already valid snapshot.
    C_Timer.After(0.5, function()
        local a = RH.active
        if not a then return end
        if (a.mapID or 0) <= 0 and C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID then
            a.mapID = Num(C_ChallengeMode.GetActiveChallengeMapID()) or a.mapID
        end
        if (a.level or 0) <= 0 and C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo then
            a.level = Num(C_ChallengeMode.GetActiveKeystoneInfo()) or a.level
        end
        a.deaths = DeathsNow() or a.deaths or 0
    end)
end

function RH:UpdateDeaths()
    if not self.active then return end
    local deaths = DeathsNow()
    if deaths then self.active.deaths = deaths end
end

function RH:Complete()
    local db = MP:GetDB()
    if not (db.modules and db.modules.runHistory) then
        self.active = nil
        return
    end

    local info = C_ChallengeMode and C_ChallengeMode.GetChallengeCompletionInfo
        and C_ChallengeMode.GetChallengeCompletionInfo() or nil
    if not info then return end

    local active = self.active or {}
    local mapID = Num(info.mapChallengeModeID) or active.mapID or 0
    local level = Num(info.level) or active.level or 0
    local durationMS = Num(info.time) or 0
    local onTime = Bool(info.onTime)
    local upgrades = Num(info.keystoneUpgradeLevels) or 0
    local practice = Bool(info.practiceRun) or false
    local oldScore = Num(info.oldOverallDungeonScore)
    local newScore = Num(info.newOverallDungeonScore)
    local name, timeLimit, texture = MapInfo(mapID)

    local scoreBefore = oldScore or active.scoreBefore or 0
    local scoreAfter = newScore or ScoreNow()
    local scoreGain = 0
    if scoreBefore and scoreAfter then scoreGain = math.max(0, scoreAfter - scoreBefore) end

    local bossSplits, forcesDone = SnapshotSplits()

    local run = {
        finishedAt = time(),
        startedAt = active.startedAt,
        mapID = mapID,
        mapName = name or MP:T("unknown"),
        texture = texture,
        level = level,
        durationMS = durationMS,
        timeLimit = timeLimit or 0,
        onTime = (onTime == true),
        upgradeLevels = upgrades,
        deaths = DeathsNow() or active.deaths or 0,
        scoreBefore = scoreBefore,
        scoreAfter = scoreAfter,
        scoreGain = scoreGain,
        seasonID = active.seasonID or CurrentSeason(),
        character = active.character or PlayerName(),
        practiceRun = practice,
        splits = {
            forcesDone = forcesDone,
            bosses = bossSplits or {},
        },
    }

    -- The bridge can be called more than once by external integrations; do
    -- not let that duplicate a completion. Same map/level/time within ten
    -- seconds is the same event for our purposes.
    local runs = Runs()
    local newest = runs[1]
    if newest and newest.mapID == run.mapID and newest.level == run.level
        and newest.durationMS == run.durationMS
        and math.abs((newest.finishedAt or 0) - run.finishedAt) <= 10 then
        self.active = nil
        return newest
    end

    run.id = Fingerprint(run)
    table.insert(runs, 1, run)
    Trim()
    self.active = nil

    if MP.Frame and MP.Frame:IsShown() and MP.RefreshCurrentPage then
        MP:RefreshCurrentPage()
    end
    return run
end

function RH:GetRuns()
    return Runs()
end

function RH:GetWeekStart()
    local now = time()
    local secs = C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset
        and Num(C_DateAndTime.GetSecondsUntilWeeklyReset()) or nil
    if not secs then return now - (7 * 86400) end
    return (now + secs) - (7 * 86400)
end

function RH:GetStats()
    local result = {
        total = 0, timed = 0, depleted = 0, rate = 0,
        bestLevel = 0, averageLevel = 0, scoreGain = 0,
        thisWeek = 0, byDungeon = {}, byLevel = {}, comfortLevel = 0,
    }
    local levelTotal = 0
    local weekStart = self:GetWeekStart()
    local seasonFilter = CurrentSeason()

    for _, run in ipairs(Runs()) do
        local runSeason = tonumber(run.seasonID) or 0
        if seasonFilter <= 0 or runSeason == seasonFilter then
        result.total = result.total + 1
        local level = tonumber(run.level) or 0
        local duration = (tonumber(run.durationMS) or 0) / 1000
        local deaths = tonumber(run.deaths) or 0
        levelTotal = levelTotal + level
        if level > result.bestLevel then result.bestLevel = level end
        if run.onTime then result.timed = result.timed + 1 else result.depleted = result.depleted + 1 end
        result.scoreGain = result.scoreGain + (tonumber(run.scoreGain) or 0)
        if (tonumber(run.finishedAt) or 0) >= weekStart then result.thisWeek = result.thisWeek + 1 end

        local mapID = tonumber(run.mapID) or 0
        local d = result.byDungeon[mapID]
        if not d then
            d = { mapID=mapID, name=run.mapName or MP:T("unknown"), total=0, timed=0, bestLevel=0, levelTotal=0, durationTotal=0, deathsTotal=0 }
            result.byDungeon[mapID] = d
        end
        d.total = d.total + 1
        d.levelTotal = d.levelTotal + level
        d.durationTotal = d.durationTotal + duration
        d.deathsTotal = d.deathsTotal + deaths
        if run.onTime then d.timed = d.timed + 1 end
        if level > d.bestLevel then d.bestLevel = level end

        if level > 0 then
            local l = result.byLevel[level]
            if not l then
                l = { level=level, total=0, timed=0, durationTotal=0, deathsTotal=0 }
                result.byLevel[level] = l
            end
            l.total = l.total + 1
            l.durationTotal = l.durationTotal + duration
            l.deathsTotal = l.deathsTotal + deaths
            if run.onTime then l.timed = l.timed + 1 end
        end
        end
    end

    if result.total > 0 then
        result.averageLevel = levelTotal / result.total
        result.rate = result.timed / result.total * 100
    end

    for level, data in pairs(result.byLevel) do
        local rate = data.total > 0 and (data.timed / data.total * 100) or 0
        if data.total >= 3 and rate >= 70 and level > result.comfortLevel then
            result.comfortLevel = level
        end
    end
    return result
end

-- Death updates begin after the LoD addon is loaded at CHALLENGE_MODE_START.
-- Start/completion are deliberately delivered by the always-loaded bridge,
-- because an event that causes LoadAddOn cannot be received retroactively by
-- a frame created during that load.
local events = CreateFrame("Frame")
events:RegisterEvent("CHALLENGE_MODE_DEATH_COUNT_UPDATED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event)
    if event == "CHALLENGE_MODE_DEATH_COUNT_UPDATED" then
        RH:UpdateDeaths()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Abandoned or reset challenge: don't carry stale deaths/score into
        -- the next completion. An active challenge survives zone loads, so
        -- only clear when no active challenge map is reported.
        local mapID = C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID
            and Num(C_ChallengeMode.GetActiveChallengeMapID()) or nil
        if not mapID or mapID <= 0 then RH.active = nil end
    end
end)

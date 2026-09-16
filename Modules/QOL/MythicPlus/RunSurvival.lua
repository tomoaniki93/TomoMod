-- =====================================================================
-- RunSurvival.lua -- Mythic+ survival / death timeline collector.
--
-- Always loaded with TomoMod so it cannot miss a death before the Mythic+
-- Studio is opened.  It deliberately avoids COMBAT_LOG_EVENT_UNFILTERED on
-- WoW 12.x: group deaths come from unit-state transitions, while the local
-- player's detailed pre-death timeline is copied from C_DeathRecap through
-- TomoDamageMeter's already guarded bridge.
-- =====================================================================

TomoMod_RunSurvival = TomoMod_RunSurvival or {}
local API = TomoMod_RunSurvival

local UNITS = {
    player = true,
    party1 = true,
    party2 = true,
    party3 = true,
    party4 = true,
}

local MAX_RECAP_EVENTS = 12
local RECAP_RETRIES = 12
local RECAP_RETRY_DELAY = 0.20

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

local function Str(v)
    if v == nil or IsSecret(v) or type(v) ~= "string" then return nil end
    return v
end

local function Bool(v)
    if v == nil or IsSecret(v) then return nil end
    return v and true or false
end

local function NameKey(name)
    name = Str(name)
    if not name then return nil end
    name = name:match("^[^-]+") or name
    return string.lower(name)
end

local function DM()
    return TomoMod and TomoMod.DM or nil
end

-- Iterate the Deaths sources while their C_DamageMeter values are readable.
-- The source row carries the most recent deathRecapID for that player.  We
-- match by GUID first and only fall back to the short name if the GUID is not
-- readable.  Current is tried before Overall so a just-landed death wins.
local function ForEachDeathSource(callback)
    if not (C_DamageMeter and C_DamageMeter.GetCombatSessionFromType
        and Enum and Enum.DamageMeterType and Enum.DamageMeterSessionType) then
        return nil
    end

    local deathType = Enum.DamageMeterType.Deaths
    local sessionTypes = {
        Enum.DamageMeterSessionType.Current,
        Enum.DamageMeterSessionType.Overall,
    }

    for _, sessionType in ipairs(sessionTypes) do
        local ok, session = pcall(C_DamageMeter.GetCombatSessionFromType, sessionType, deathType)
        if ok and session and not IsSecret(session) then
            local sources = session.combatSources
            if type(sources) == "table" and not IsSecret(sources) then
                for _, source in ipairs(sources) do
                    if type(source) == "table" and not IsSecret(source) then
                        local stop = callback(source)
                        if stop then return stop end
                    end
                end
            end
        end
    end
    return nil
end

local function SourceMatchesDeath(source, death)
    if type(source) ~= "table" or type(death) ~= "table" then return false end

    local sourceGUID = Str(source.sourceGUID)
    local deathGUID = Str(death.guid)
    if sourceGUID and deathGUID then
        return sourceGUID == deathGUID
    end

    local sourceName = NameKey(source.name)
    local deathName = NameKey(death.name)
    return sourceName ~= nil and deathName ~= nil and sourceName == deathName
end

local function FindRecapID(run, death)
    if not run or not death then return nil end
    local found
    ForEachDeathSource(function(source)
        if SourceMatchesDeath(source, death) then
            local rid = Num(source.deathRecapID)
            if rid and rid > 0 and not run.seenRecaps[rid] then
                found = rid
                return true
            end
        end
        return false
    end)
    return found
end

local function ChallengeElapsed()
    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive
        and C_ChallengeMode.IsChallengeModeActive() then
        local _, elapsed = GetWorldElapsedTime(1)
        elapsed = Num(elapsed)
        if elapsed and elapsed >= 0 then return elapsed end
    end
    return nil
end

local function CurrentMapLevel()
    local mapID = C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID
        and Num(C_ChallengeMode.GetActiveChallengeMapID()) or nil
    local level = C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo
        and Num(C_ChallengeMode.GetActiveKeystoneInfo()) or nil
    return mapID, level
end

local activeRun
local lastRun
local runSerial = 0

local function RunElapsed(run)
    local elapsed = ChallengeElapsed()
    if elapsed ~= nil then return elapsed end
    if run and run.startedAt then
        local wall = time() - run.startedAt
        if wall >= 0 then return wall end
    end
    return 0
end

local function CopyEvent(ev)
    if type(ev) ~= "table" then return nil end
    return {
        spellID = Num(ev.spellID),
        name = Str(ev.name),
        icon = Num(ev.icon),
        event = Str(ev.event),
        isHeal = ev.isHeal == true,
        amount = Num(ev.amount) or 0,
        overkill = Num(ev.overkill),
        currentHP = Num(ev.currentHP) or 0,
        timestamp = Num(ev.timestamp),
    }
end

local function CopyDetail(detail)
    if type(detail) ~= "table" then return nil end
    local out = {
        maxHP = Num(detail.maxHP) or 0,
        fatalIndex = Num(detail.fatalIndex),
        events = {},
    }
    for _, ev in ipairs(type(detail.events) == "table" and detail.events or {}) do
        local copy = CopyEvent(ev)
        if copy then out.events[#out.events + 1] = copy end
    end
    return out
end

local function Snapshot(run)
    if type(run) ~= "table" then return nil end
    local out = {
        version = 3,
        reliable = run.reliable == true,
        totalDeaths = Num(run.totalDeaths),
        observedDeaths = #run.deaths,
        mapID = Num(run.mapID),
        keyLevel = Num(run.keyLevel),
        startedAt = Num(run.startedAt),
        finishedAt = Num(run.finishedAt),
        deaths = {},
    }
    for _, death in ipairs(run.deaths) do
        out.deaths[#out.deaths + 1] = {
            at = Num(death.at) or 0,
            name = Str(death.name),
            class = Str(death.class),
            guid = Str(death.guid),
            isLocal = death.isLocal == true,
            detail = CopyDetail(death.detail),
            detailUnavailable = death.detailUnavailable == true,
        }
    end
    return out
end

local function SeedExistingRecaps(run)
    if not run then return end
    -- Mark every recap already present when the key starts.  Overall may still
    -- contain the previous dungeon; without this seed, the first death of a
    -- player could accidentally inherit that stale recap while the new one is
    -- still being published.
    ForEachDeathSource(function(source)
        local rid = Num(source.deathRecapID)
        if rid and rid > 0 then run.seenRecaps[rid] = true end
        return false
    end)
end

local function FindFatalIndex(events)
    for i = #events, 1, -1 do
        if not events[i].isHeal then return i end
    end
    return #events > 0 and #events or nil
end

local function CaptureDeathRecap(run, death, attempt)
    if not run or not death or death.detail then return end
    if run.serial ~= death.serial then return end

    local dm = DM()
    local rid = FindRecapID(run, death)
    if rid and dm and dm.GetDeathRecap then
        local ok, events, maxHP = pcall(dm.GetDeathRecap, rid)
        if ok and type(events) == "table" and #events > 0 then
            run.seenRecaps[rid] = true
            local copied = {}
            local startAt = math.max(1, #events - MAX_RECAP_EVENTS + 1)
            for i = startAt, #events do
                local ev = CopyEvent(events[i])
                if ev then copied[#copied + 1] = ev end
            end
            death.detail = {
                maxHP = Num(maxHP) or 0,
                events = copied,
                fatalIndex = FindFatalIndex(copied),
            }
            death.detailUnavailable = nil
            return
        end
    end

    attempt = (attempt or 0) + 1
    if attempt < RECAP_RETRIES then
        C_Timer.After(RECAP_RETRY_DELAY, function()
            CaptureDeathRecap(run, death, attempt)
        end)
    else
        death.detailUnavailable = true
    end
end

local function SeedUnit(run, unit)
    if not run or not UNITS[unit] or not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    local guid = Str(UnitGUID(unit))
    if not guid then return end
    run.dead[guid] = UnitIsDeadOrGhost(unit) and true or false
end

local function RecordDeath(run, unit, guid)
    local name = Str(UnitName(unit))
    local _, class = UnitClass(unit)
    class = Str(class)
    local isLocal = UnitIsUnit and UnitIsUnit(unit, "player") or unit == "player"

    local death = {
        at = RunElapsed(run),
        name = name,
        class = class,
        guid = guid,
        isLocal = isLocal and true or false,
        serial = run.serial,
    }
    run.deaths[#run.deaths + 1] = death

    -- C_DamageMeter exposes a per-source deathRecapID for group members too.
    -- Poll briefly because the source row is updated a fraction after the unit
    -- death transition, especially during simultaneous deaths / wipes.
    C_Timer.After(0.35, function()
        CaptureDeathRecap(run, death, 0)
    end)
end

local function TrackUnit(unit)
    local run = activeRun
    if not run or not UNITS[unit] or not UnitExists(unit) or not UnitIsPlayer(unit) then return end

    local guid = Str(UnitGUID(unit))
    if not guid then return end
    local nowDead = UnitIsDeadOrGhost(unit) and true or false
    local wasDead = run.dead[guid]

    if wasDead == nil then
        run.dead[guid] = nowDead
        return
    end

    if nowDead and not wasDead then
        RecordDeath(run, unit, guid)
    end
    run.dead[guid] = nowDead
end

local function RegisterUnitEvents(frame)
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_FLAGS")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("PLAYER_DEAD")
end

local function UnregisterUnitEvents(frame)
    frame:UnregisterEvent("UNIT_HEALTH")
    frame:UnregisterEvent("UNIT_FLAGS")
    frame:UnregisterEvent("GROUP_ROSTER_UPDATE")
    frame:UnregisterEvent("PLAYER_DEAD")
end

local function BeginRun(frame, reliable)
    runSerial = runSerial + 1
    local mapID, level = CurrentMapLevel()
    local elapsed = ChallengeElapsed() or 0
    activeRun = {
        serial = runSerial,
        reliable = reliable == true,
        startedAt = time() - elapsed,
        mapID = mapID,
        keyLevel = level,
        deaths = {},
        dead = {},
        seenRecaps = {},
    }
    lastRun = nil

    for unit in pairs(UNITS) do SeedUnit(activeRun, unit) end
    RegisterUnitEvents(frame)
    C_Timer.After(0, function()
        if activeRun and activeRun.serial == runSerial then SeedExistingRecaps(activeRun) end
    end)
end

local function FinishRun(frame)
    local run = activeRun
    if not run then return end

    for unit in pairs(UNITS) do TrackUnit(unit) end

    local info = C_ChallengeMode and C_ChallengeMode.GetChallengeCompletionInfo
        and C_ChallengeMode.GetChallengeCompletionInfo() or nil
    if info then
        run.mapID = Num(info.mapChallengeModeID) or run.mapID
        run.keyLevel = Num(info.level) or run.keyLevel
    end

    local total = C_ChallengeMode and C_ChallengeMode.GetDeathCount
        and Num(C_ChallengeMode.GetDeathCount()) or nil
    run.totalDeaths = total or #run.deaths
    if total ~= nil and total ~= #run.deaths then run.reliable = false end
    run.finishedAt = time()

    lastRun = run
    activeRun = nil
    UnregisterUnitEvents(frame)
end

local function AbortRun(frame)
    activeRun = nil
    UnregisterUnitEvents(frame)
end

local events = CreateFrame("Frame")
events:RegisterEvent("CHALLENGE_MODE_START")
events:RegisterEvent("CHALLENGE_MODE_COMPLETED")
events:RegisterEvent("CHALLENGE_MODE_RESET")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(self, event, unit)
    if event == "CHALLENGE_MODE_START" then
        BeginRun(self, true)
        return
    end

    if event == "CHALLENGE_MODE_COMPLETED" then
        FinishRun(self)
        return
    end

    if event == "CHALLENGE_MODE_RESET" then
        AbortRun(self)
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        local inChallenge = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive
            and C_ChallengeMode.IsChallengeModeActive()
        if inChallenge then
            if not activeRun then BeginRun(self, false) end
        elseif activeRun then
            AbortRun(self)
        end
        return
    end

    if event == "GROUP_ROSTER_UPDATE" then
        if activeRun then
            for groupUnit in pairs(UNITS) do SeedUnit(activeRun, groupUnit) end
        end
        return
    end

    if event == "PLAYER_DEAD" then
        TrackUnit("player")
        return
    end

    TrackUnit(unit)
end)

function API.GetSnapshot()
    return Snapshot(lastRun or activeRun)
end

function API.IsTracking()
    return activeRun ~= nil
end

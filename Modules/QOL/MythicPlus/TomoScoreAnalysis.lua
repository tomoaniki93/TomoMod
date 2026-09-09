-- =====================================================================
-- TomoScoreAnalysis.lua — bridge from the end-of-run TomoScore window to
-- the LoadOnDemand Mythic+ Run Analysis window.
--
-- This file deliberately wraps the existing TomoScore public methods instead
-- of changing its secure keystone row implementation.  The analysis button is
-- a plain mouse button in the footer and never participates in secure actions.
-- =====================================================================

local TS = TomoMod_TomoScore
local B  = TomoMod_MythicPlusLauncher
if not TS or not B then return end

local WHITE8 = "Interface\\Buttons\\WHITE8x8"

local BUTTON_TEXT = {
    enUS = "Run Analysis",
    frFR = "Analyse du run",
    deDE = "Run-Analyse",
    esES = "Analizar run",
    itIT = "Analisi run",
    ptBR = "Analisar run",
}

local function ButtonText()
    local locale = GetLocale and GetLocale() or "enUS"
    return BUTTON_TEXT[locale] or BUTTON_TEXT.enUS
end

local _issecret = issecretvalue
local function IsSecret(v)
    if not _issecret then return false end
    local ok, secret = pcall(_issecret, v)
    return ok and secret or false
end

local function Number(v)
    if type(v) ~= "number" or IsSecret(v) then return nil end
    return v
end

local function Boolean(v)
    if v == nil or IsSecret(v) then return nil end
    return v and true or false
end

-- V1.2: keep an independent, non-combat-log death attribution for the five
-- challenge units. C_DamageMeter's Deaths metric can legitimately be absent
-- for a player when the value is secret on the only snapshot where it changes.
-- UNIT_HEALTH / UNIT_FLAGS give us the transition to dead without touching the
-- protected combat log, and the final total is cross-checked against Blizzard.
local DEATH_UNITS = { "player", "party1", "party2", "party3", "party4" }
local deathTrack = { active = false, reliable = false, counts = {}, dead = {} }

local function PlayerKey(name)
    if type(name) ~= "string" or name == "" then return nil end
    name = name:match("^[^-]+") or name
    return string.lower(name)
end

local function SeedDeathUnit(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    local guid = UnitGUID(unit)
    local key = PlayerKey(UnitName(unit))
    if guid then deathTrack.dead[guid] = UnitIsDeadOrGhost(unit) and true or false end
    if key and deathTrack.counts[key] == nil then deathTrack.counts[key] = 0 end
end

local function BeginDeathTracking(reliable)
    deathTrack.active = true
    deathTrack.reliable = reliable == true
    deathTrack.counts = {}
    deathTrack.dead = {}
    for _, unit in ipairs(DEATH_UNITS) do SeedDeathUnit(unit) end
end

local function TrackDeathUnit(unit)
    if not deathTrack.active or not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    local guid = UnitGUID(unit)
    if not guid then return end
    local key = PlayerKey(UnitName(unit))
    local dead = UnitIsDeadOrGhost(unit) and true or false
    local previous = deathTrack.dead[guid]

    if previous == nil then
        SeedDeathUnit(unit)
        return
    end
    if dead and not previous and key then
        deathTrack.counts[key] = (deathTrack.counts[key] or 0) + 1
    end
    deathTrack.dead[guid] = dead
end

local function EndDeathTracking()
    if not deathTrack.active then return end
    for _, unit in ipairs(DEATH_UNITS) do TrackDeathUnit(unit) end
    deathTrack.active = false
end

local function SnapshotPlayerDeaths(data)
    if not deathTrack.reliable or type(data) ~= "table" then return nil end
    local out, trackedTotal = {}, 0
    for _, player in ipairs(type(data.players) == "table" and data.players or {}) do
        local key = PlayerKey(player.name or player.fullName)
        if key then
            local count = deathTrack.counts[key] or 0
            out[key] = count
            trackedTotal = trackedTotal + count
        end
    end

    -- Never turn a missed transition into a false zero. If Blizzard's run total
    -- is readable and disagrees with our attribution, let the UI fall back to
    -- C_DamageMeter / unknown instead.
    local totalDeaths = C_ChallengeMode and C_ChallengeMode.GetDeathCount
        and Number(C_ChallengeMode.GetDeathCount()) or nil
    if totalDeaths ~= nil and trackedTotal ~= totalDeaths then return nil end
    return next(out) and out or nil
end

local deathEvents = CreateFrame("Frame")
deathEvents:RegisterEvent("CHALLENGE_MODE_START")
deathEvents:RegisterEvent("CHALLENGE_MODE_COMPLETED")
deathEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
deathEvents:RegisterEvent("GROUP_ROSTER_UPDATE")
deathEvents:SetScript("OnEvent", function(_, event, unit)
    if event == "CHALLENGE_MODE_START" then
        BeginDeathTracking(true)
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        EndDeathTracking()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive
            and C_ChallengeMode.IsChallengeModeActive() then
            -- A /reload in the middle of a key cannot reconstruct earlier
            -- individual deaths, so keep the tracker explicitly unreliable.
            if not deathTrack.active then BeginDeathTracking(false) end
        else
            deathTrack.active = false
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        if deathTrack.active then
            for _, groupUnit in ipairs(DEATH_UNITS) do SeedDeathUnit(groupUnit) end
        end
    else
        TrackDeathUnit(unit)
    end
end)

-- RegisterUnitEvent takes at most TWO unit tokens, and a second call for the
-- same event replaces the first filter rather than adding to it. Registering
-- the five challenge units in one call would silently watch only player and
-- party1, so every unit pair gets its own frame.
for i = 1, #DEATH_UNITS, 2 do
    local watcher = CreateFrame("Frame")
    watcher:RegisterUnitEvent("UNIT_HEALTH", DEATH_UNITS[i], DEATH_UNITS[i + 1])
    watcher:RegisterUnitEvent("UNIT_FLAGS", DEATH_UNITS[i], DEATH_UNITS[i + 1])
    watcher:SetScript("OnEvent", function(_, _, unit) TrackDeathUnit(unit) end)
end

local function SnapshotMeter()
    local dm = _G.TomoDamageMeter
    if not (dm and dm.GetRunSnapshot) then return nil end
    local ok, snapshot = pcall(dm.GetRunSnapshot)
    if not ok or type(snapshot) ~= "table" then return nil end
    return snapshot
end

local function CopyString(v)
    return type(v) == "string" and v or nil
end

local function CopyPlayerDeaths(deaths)
    if type(deaths) ~= "table" then return nil end
    local out = {}
    for name, count in pairs(deaths) do
        local safe = Number(count)
        if type(name) == "string" and safe ~= nil then out[name] = safe end
    end
    return next(out) and out or nil
end

local function CopyMeter(meter)
    if type(meter) ~= "table" then return nil end
    local out = {
        mapID = Number(meter.mapID),
        zoneName = CopyString(meter.zoneName),
        keyLevel = Number(meter.keyLevel),
        duration = Number(meter.duration),
        players = {},
    }
    for _, player in ipairs(type(meter.players) == "table" and meter.players or {}) do
        out.players[#out.players + 1] = {
            guid = CopyString(player.guid),
            name = CopyString(player.name),
            class = CopyString(player.class),
            dps = Number(player.dps),
            hps = Number(player.hps),
            interrupts = Number(player.interrupts),
            deaths = Number(player.deaths),
            avoidable = Number(player.avoidable),
        }
    end
    return out
end

local function CopyAnalysisRun(data)
    if type(data) ~= "table" then return nil end
    local out = {
        dungeonName = CopyString(data.dungeonName),
        keyLevel = Number(data.keyLevel) or 0,
        isMPlus = data.isMPlus == true,
        onTime = Boolean(data.onTime),
        duration = Number(data.duration) or 0,
        players = {},
    }
    for _, player in ipairs(type(data.players) == "table" and data.players or {}) do
        out.players[#out.players + 1] = {
            name = CopyString(player.name), fullName = CopyString(player.fullName),
            class = CopyString(player.class), role = CopyString(player.role),
            specID = Number(player.specID), specIcon = Number(player.specIcon),
            rating = Number(player.rating), damage = Number(player.damage),
            healing = Number(player.healing), interrupts = Number(player.interrupts),
        }
    end

    local meta = type(data._tmRunAnalysis) == "table" and data._tmRunAnalysis or {}
    out._tmRunAnalysis = {
        completedAt = Number(meta.completedAt), mapID = Number(meta.mapID),
        upgradeLevels = Number(meta.upgradeLevels), oldScore = Number(meta.oldScore),
        newScore = Number(meta.newScore), onTime = Boolean(meta.onTime),
        scoreGain = Number(meta.scoreGain), historyID = meta.historyID,
        meter = CopyMeter(meta.meter),
        playerDeaths = CopyPlayerDeaths(meta.playerDeaths),
    }
    return out
end

local function MatchHistory(data, meta)
    local mp = _G.TomoMod_MythicPlus
    local rh = mp and mp.RunHistory
    if not (rh and rh.GetRuns) then return nil end

    local runs = rh:GetRuns()
    if type(runs) ~= "table" then return nil end

    local mapID = meta and Number(meta.mapID) or nil
    local level = data and Number(data.keyLevel) or nil
    local duration = data and Number(data.duration) or nil
    local finished = meta and Number(meta.completedAt) or nil

    local best, bestRank
    for i = 1, math.min(#runs, 20) do
        local run = runs[i]
        if type(run) == "table" then
            local runMap = Number(run.mapID)
            local runLevel = Number(run.level)
            local runDuration = Number(run.durationMS)
            local runFinished = Number(run.finishedAt)

            local mapOK = not mapID or not runMap or mapID == runMap
            local levelOK = not level or level <= 0 or not runLevel or level == runLevel
            if mapOK and levelOK then
                local rank = 0
                if duration and runDuration then
                    rank = rank + math.abs((runDuration / 1000) - duration)
                else
                    rank = rank + 20
                end
                if finished and runFinished then
                    rank = rank + math.min(math.abs(runFinished - finished) / 10, 20)
                end
                if not bestRank or rank < bestRank then
                    best, bestRank = run, rank
                end
            end
        end
    end

    if best and (not bestRank or bestRank <= 12) then return best end
    return nil
end

local function CaptureAnalysisData(data)
    if type(data) ~= "table" or data.isMPlus ~= true then return end

    local meta = type(data._tmRunAnalysis) == "table" and data._tmRunAnalysis or {}
    data._tmRunAnalysis = meta
    meta.completedAt = time()

    local info = C_ChallengeMode and C_ChallengeMode.GetChallengeCompletionInfo
        and C_ChallengeMode.GetChallengeCompletionInfo() or nil
    if info then
        meta.mapID = Number(info.mapChallengeModeID) or meta.mapID
        meta.upgradeLevels = Number(info.keystoneUpgradeLevels) or meta.upgradeLevels
        meta.oldScore = Number(info.oldOverallDungeonScore) or meta.oldScore
        meta.newScore = Number(info.newOverallDungeonScore) or meta.newScore
        meta.onTime = Boolean(info.onTime)
        if meta.oldScore and meta.newScore then
            meta.scoreGain = math.max(0, meta.newScore - meta.oldScore)
        end
    end

    local playerDeaths = SnapshotPlayerDeaths(data)
    if playerDeaths then meta.playerDeaths = playerDeaths end

    local meter = SnapshotMeter()
    if meter then
        -- Prefer the event-attributed value when it passed the Blizzard total
        -- cross-check. This fills the exact case where DamageMeter reports a
        -- player's DPS/HPS but its Deaths field stayed secret / nil.
        if playerDeaths and type(meter.players) == "table" then
            for _, player in ipairs(meter.players) do
                local key = PlayerKey(player and player.name)
                if key and playerDeaths[key] ~= nil then player.deaths = playerDeaths[key] end
            end
        end
        meta.meter = meter
    end

    local history = MatchHistory(data, meta)
    if history and history.id then
        meta.historyID = history.id
        local mp = _G.TomoMod_MythicPlus
        local rh = mp and mp.RunHistory
        if rh and rh.SaveAnalysis then rh:SaveAnalysis(history.id, CopyAnalysisRun(data)) end
    end
end

local function EnsureAnalysisButton(self, frame)
    if not frame or frame._tmRunAnalysisButton then return end
    local footer = frame.Footer
    if not footer then return end

    local C = self.C
    local btn = CreateFrame("Button", nil, footer, "BackdropTemplate")
    frame._tmRunAnalysisButton = btn
    btn:SetSize(118, 20)
    btn:SetPoint("RIGHT", footer, "RIGHT", -6, 0)
    btn:SetFrameLevel(footer:GetFrameLevel() + 5)
    btn:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    btn:SetBackdropColor(C.BG_ROW_ODD[1], C.BG_ROW_ODD[2], C.BG_ROW_ODD[3], 0.95)
    btn:SetBackdropBorderColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.70)

    local label = self:MakeFS(btn, 9, "OUTLINE")
    btn._label = label
    label:SetPoint("CENTER", 0, 0)
    label:SetText(ButtonText())
    label:SetTextColor(unpack(C.TEXT_ACCENT))

    btn:SetScript("OnEnter", function(b)
        b:SetBackdropColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.22)
        b:SetBackdropBorderColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 1)
    end)
    btn:SetScript("OnLeave", function(b)
        b:SetBackdropColor(C.BG_ROW_ODD[1], C.BG_ROW_ODD[2], C.BG_ROW_ODD[3], 0.95)
        b:SetBackdropBorderColor(C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.70)
    end)
    btn:SetScript("OnClick", function()
        local data = frame._tmRunAnalysisData
        if type(data) ~= "table" then return end
        frame:Hide()
        B:OpenAnalysis(data)
    end)
    btn:Hide()
end

-- Capture a compact immutable-enough analysis snapshot at the same moment
-- TomoScore stores its last run.  This keeps reopening "Last Run" tied to that
-- exact completion instead of whatever C_DamageMeter happens to contain later.
local SaveRunData = TS.SaveRunData
function TS:SaveRunData(data)
    CaptureAnalysisData(data)
    return SaveRunData(self, data)
end

-- Add the button without touching TomoScoreUI.lua or its secure teleport rows.
local BuildScoreboard = TS.BuildScoreboard
function TS:BuildScoreboard(...)
    local frame = BuildScoreboard(self, ...)
    EnsureAnalysisButton(self, frame)
    return frame
end

local PopulateScoreboard = TS.PopulateScoreboard
function TS:PopulateScoreboard(data, ...)
    local result = PopulateScoreboard(self, data, ...)
    local frame = self.SB
    if frame then
        EnsureAnalysisButton(self, frame)
        frame._tmRunAnalysisData = data

        -- The completion path saves the exact table before showing it. Preview
        -- and /tm keys use fresh tables, so identity is a reliable discriminator
        -- and does not require another flag in TomoScore's saved schema.
        local db = self:GetDB()
        local isCompletedRun = type(data) == "table"
            and data.isMPlus == true
            and db and db.lastRun == data
        frame._tmRunAnalysisButton:SetShown(isCompletedRun and true or false)
    end
    return result
end

-- Defensive late-create path in case another module built TomoScore during the
-- same load sequence before this wrapper was reached.
if TS.SB then EnsureAnalysisButton(TS, TS.SB) end

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

local function SnapshotMeter()
    local dm = _G.TomoDamageMeter
    if not (dm and dm.GetRunSnapshot) then return nil end
    local ok, snapshot = pcall(dm.GetRunSnapshot)
    if not ok or type(snapshot) ~= "table" then return nil end
    return snapshot
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

    local meter = SnapshotMeter()
    if meter then meta.meter = meter end

    local history = MatchHistory(data, meta)
    if history and history.id then meta.historyID = history.id end
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

-- =====================================
-- CinematicSkip.lua
-- Skip automatique des cinematiques deja vues.
-- =====================================

TomoMod_CinematicSkip = {}
local cinematicFrame
local skipAttempts = 0
local maxSkipAttempts = 10

-- =====================================
-- UTILS
-- =====================================
local function GetDB()
    return TomoModDB and TomoModDB.cinematicSkip
end

local function GetCinematicID()
    local zoneName = GetZoneText() or ""
    local subZone = GetSubZoneText() or ""
    return zoneName .. "_" .. subZone
end

local function HasSeenCinematic(cinematicID)
    local db = GetDB()
    if not db then return false end
    if not db.viewedCinematics then
        db.viewedCinematics = {}
    end
    return db.viewedCinematics[cinematicID] ~= nil
end

local function MarkCinematicAsSeen(cinematicID)
    local db = GetDB()
    if not db then return end
    if not db.viewedCinematics then
        db.viewedCinematics = {}
    end
    db.viewedCinematics[cinematicID] = time()
end

-- Tenter de skip la cinematique
local function TrySkipCinematic()
    local db = GetDB()
    if not db or not db.enabled then return end

    if CinematicFrame and CinematicFrame:IsShown() then
        local cinematicID = GetCinematicID()

        if HasSeenCinematic(cinematicID) then
            CinematicFrame_CancelCinematic()
            print("|cff0cd29fTomoMod:|r Cinematique skippee (deja vue)")
        else
            MarkCinematicAsSeen(cinematicID)
        end
    end
end

-- =====================================
-- HOOK EVENTS
-- =====================================
local function HookCinematicEvents()
    if cinematicFrame then return end

    cinematicFrame = CreateFrame("Frame")
    cinematicFrame:RegisterEvent("CINEMATIC_START")
    cinematicFrame:RegisterEvent("PLAY_MOVIE")

    cinematicFrame:SetScript("OnEvent", function(self, event, ...)
        local db = GetDB()
        if not db or not db.enabled then return end

        if event == "CINEMATIC_START" then
            skipAttempts = 0
            C_Timer.NewTicker(0.1, function()
                skipAttempts = skipAttempts + 1
                TrySkipCinematic()
                if skipAttempts >= maxSkipAttempts then
                    return true
                end
            end, maxSkipAttempts)

        elseif event == "PLAY_MOVIE" then
            local movieID = ...
            if not movieID then return end

            local movieKey = "MOVIE_" .. tostring(movieID)

            if HasSeenCinematic(movieKey) then
                -- MovieFrame:Hide() est la methode fiable pour stopper
                -- une video. MovieFrame_PlayMovie n'existe pas dans l'API.
                C_Timer.After(0.1, function()
                    if MovieFrame and MovieFrame:IsShown() then
                        MovieFrame:Hide()
                        print("|cff0cd29fTomoMod:|r Video #" .. movieID .. " skippee")
                    end
                end)
            else
                MarkCinematicAsSeen(movieKey)
            end
        end
    end)
end

-- =====================================
-- PUBLIC API
-- =====================================
function TomoMod_CinematicSkip.ClearHistory()
    local db = GetDB()
    if not db then return end
    db.viewedCinematics = {}
    print("|cff0cd29fTomoMod:|r Historique des cinematiques efface")
end

function TomoMod_CinematicSkip.GetViewedCount()
    local db = GetDB()
    if not db or not db.viewedCinematics then
        return 0
    end
    local count = 0
    for _ in pairs(db.viewedCinematics) do
        count = count + 1
    end
    return count
end

function TomoMod_CinematicSkip.Initialize()
    local db = GetDB()
    if not db then return end
    if db.enabled then
        HookCinematicEvents()
    end
end

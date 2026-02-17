-- =====================================
-- CinematicSkip.lua
-- =====================================

TomoMod_CinematicSkip = {}
local cinematicFrame
local skipAttempts = 0
local maxSkipAttempts = 10

-- Obtenir un ID unique pour la cinématique actuelle
local function GetCinematicID()
    -- Utiliser le nom de la zone + timestamp approximatif comme identifiant
    local zoneName = GetZoneText()
    local subZone = GetSubZoneText()
    
    -- Créer un ID basé sur la localisation
    local cinematicID = zoneName .. "_" .. subZone
    
    return cinematicID
end

-- Vérifier si une cinématique a déjà été vue
local function HasSeenCinematic(cinematicID)
    if not TomoModDB.cinematicSkip.viewedCinematics then
        TomoModDB.cinematicSkip.viewedCinematics = {}
    end
    
    return TomoModDB.cinematicSkip.viewedCinematics[cinematicID] ~= nil
end

-- Marquer une cinématique comme vue
local function MarkCinematicAsSeen(cinematicID)
    if not TomoModDB.cinematicSkip.viewedCinematics then
        TomoModDB.cinematicSkip.viewedCinematics = {}
    end
    
    TomoModDB.cinematicSkip.viewedCinematics[cinematicID] = time()
end

-- Tenter de skip la cinématique
local function TrySkipCinematic()
    if not TomoModDB.cinematicSkip.enabled then return end
    
    -- Vérifier si on est dans une cinématique
    if CinematicFrame and CinematicFrame:IsShown() then
        local cinematicID = GetCinematicID()
        
        if HasSeenCinematic(cinematicID) then
            -- Skip la cinématique
            CinematicFrame_CancelCinematic()
            print("|cff00ff00TomoMod:|r " .. TomoMod_L["msg_cin_skipped"])
        else
            -- Première fois, marquer comme vue
            MarkCinematicAsSeen(cinematicID)
        end
    end
    
    -- Vérifier les movie frames (vidéos in-game)
    if MovieFrame and MovieFrame:IsShown() then
        local cinematicID = GetCinematicID()
        
        if HasSeenCinematic(cinematicID) then
            -- Skip la vidéo
            MovieFrame_PlayMovie(MovieFrame, 0) -- Force l'arrêt
            GameMovieFinished()
            print("|cff00ff00TomoMod:|r " .. TomoMod_L["msg_vid_skipped"])
        else
            -- Première fois, marquer comme vue
            MarkCinematicAsSeen(cinematicID)
        end
    end
end

-- Hook sur les événements de cinématiques
local function HookCinematicEvents()
    if cinematicFrame then return end
    
    cinematicFrame = CreateFrame("Frame")
    
    -- Événements pour les cinématiques
    cinematicFrame:RegisterEvent("CINEMATIC_START")
    cinematicFrame:RegisterEvent("PLAY_MOVIE")
    
    cinematicFrame:SetScript("OnEvent", function(self, event, ...)
        if not TomoModDB.cinematicSkip.enabled then return end
        
        if event == "CINEMATIC_START" then
            -- Délai court pour laisser le temps à la cinématique de se charger
            skipAttempts = 0
            C_Timer.NewTicker(0.1, function()
                skipAttempts = skipAttempts + 1
                TrySkipCinematic()
                if skipAttempts >= maxSkipAttempts then
                    return true -- Arrêter le ticker
                end
            end, maxSkipAttempts)
            
        elseif event == "PLAY_MOVIE" then
            local movieID = ...
            
            -- Vérifier si cette vidéo a été vue
            if HasSeenCinematic("MOVIE_" .. movieID) then
                -- Skip immédiatement
                C_Timer.After(0.1, function()
                    if MovieFrame and MovieFrame:IsShown() then
                        MovieFrame:StopMovie()
                        GameMovieFinished()
                        print("|cff00ff00TomoMod:|r " .. string.format(TomoMod_L["msg_vid_id_skipped"], movieID))
                    end
                end)
            else
                -- Marquer comme vue
                MarkCinematicAsSeen("MOVIE_" .. movieID)
            end
        end
    end)
end

-- Effacer toutes les cinématiques vues
function TomoMod_CinematicSkip.ClearHistory()
    TomoModDB.cinematicSkip.viewedCinematics = {}
    print("|cff00ff00TomoMod:|r " .. TomoMod_L["msg_cin_cleared"])
end

-- Obtenir le nombre de cinématiques vues
function TomoMod_CinematicSkip.GetViewedCount()
    if not TomoModDB.cinematicSkip.viewedCinematics then
        return 0
    end
    
    local count = 0
    for _ in pairs(TomoModDB.cinematicSkip.viewedCinematics) do
        count = count + 1
    end
    
    return count
end

-- Initialisation du module
function TomoMod_CinematicSkip.Initialize()
    if TomoModDB.cinematicSkip.enabled then
        HookCinematicEvents()
    end
end
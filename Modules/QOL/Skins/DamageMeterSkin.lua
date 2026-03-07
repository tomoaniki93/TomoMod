-- =====================================
-- DamageMeterSkin.lua
-- TomoMod – paramètres du Damage Meter natif Blizzard (12.x / Midnight)
--
-- CONTRAINTE TAINT CRITIQUE :
--   Le DamageMeter est un frame Blizzard sécurisé. Toute manipulation Lua
--   directe sur lui ou ses enfants depuis du code addon (GetRegions, SetBackdrop,
--   CreateTexture, hooksecurefunc, KillNineSlice, StripBGTextures…) propage
--   le taint vers DamageMeterSessionWindow et DamageMeterEntry, causant :
--     • "secret number value tainted by 'TomoMod'" sur durationSeconds
--     • "secret string value tainted by 'TomoMod'" sur text / nameText
--
--   Ce module utilise UNIQUEMENT les 4 API officielles Blizzard exposées
--   par le frame DamageMeter. C'est la seule interface safe documentée.
--
--   Sources : Details! parser_nocleu.lua l.16 + DamageMeter API publique
-- =====================================

TomoMod_DamageMeterSkin = TomoMod_DamageMeterSkin or {}
local DM = TomoMod_DamageMeterSkin
local L  -- assigned in Initialize

-- =====================================
-- STATE
-- =====================================

local isInitialized = false
local detectedFrame = nil

-- =====================================
-- SETTINGS
-- =====================================

local function GetSettings()
    return (TomoModDB and TomoModDB.damageMeterSkin) or {}
end

local function IsEnabled()
    return GetSettings().enabled ~= false
end

-- =====================================
-- API NATIVES BLIZZARD
-- Les seules méthodes safe sur le frame DamageMeter :
--   SetUseClassColor(bool)   — couleurs de classe WoW
--   SetBarHeight(height)     — hauteur de chaque entrée
--   SetBarSpacing(spacing)   — espacement entre entrées
--   SetShowBarIcons(bool)    — icône de spé à gauche
--   SetAlpha(0.0–1.0)        — opacité globale (méthode Frame standard)
-- Toute autre manipulation est interdite pour éviter le taint.
-- =====================================

local CANDIDATE_FRAMES = {
    "DamageMeter",               -- nom confirmé 12.x / Midnight
    "EncounterStatsMeterFrame",
    "DamageMeterFrame",
    "EncounterStatsDamageMeter",
    "CombatStatsMeterFrame",
}

local function FindDamageMeterFrame()
    for _, name in ipairs(CANDIDATE_FRAMES) do
        local f = _G[name]
        if f and f.IsObjectType and f:IsObjectType("Frame") then
            return f
        end
    end
    if C_EncounterStats then
        for _, fn in ipairs({ "GetMeterFrame", "GetDamageMeterFrame" }) do
            if C_EncounterStats[fn] then
                local f = C_EncounterStats[fn]()
                if f then return f end
            end
        end
    end
    return nil
end

local function ApplyBlizzardSettings()
    local dm = detectedFrame or FindDamageMeterFrame()
    if not dm then return end
    detectedFrame = dm

    local db = GetSettings()

    -- Couleurs de classe WoW par entrée
    if dm.SetUseClassColor then
        dm:SetUseClassColor(db.useClassColors ~= false)
    end

    -- Hauteur de chaque barre (px)
    if dm.SetBarHeight and db.barHeight then
        dm:SetBarHeight(db.barHeight)
    end

    -- Espacement vertical entre les barres (px)
    if dm.SetBarSpacing and db.spacing then
        dm:SetBarSpacing(db.spacing)
    end

    -- Icône de spécialisation à gauche de chaque entrée
    if dm.SetShowBarIcons then
        dm:SetShowBarIcons(db.showSpecIcon ~= false)
    end

    -- Opacité globale de la fenêtre (0–100 → 0.0–1.0)
    -- SetAlpha est une méthode Frame standard, safe sur n'importe quel frame
    if db.opacity then
        dm:SetAlpha((db.opacity or 80) / 100)
    end
end

local function TryApply()
    if not IsEnabled() then return end
    ApplyBlizzardSettings()
end

-- =====================================
-- ÉVÉNEMENTS
-- =====================================

local eventFrame = CreateFrame("Frame", "TomoMod_DamageMeterSkinEvents")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if not IsEnabled() then return end

    if event == "ADDON_LOADED" then
        -- Tentative courte après chargement des addons Blizzard
        C_Timer.After(0.5, TryApply)

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Deuxième tentative après chargement complet du monde
        C_Timer.After(2.0, TryApply)
    end
end)

-- =====================================
-- API PUBLIQUE
-- =====================================

function DM.Initialize()
    L = TomoMod_L
    if isInitialized then return end
    isInitialized = true
    if not IsEnabled() then return end
    C_Timer.After(2.0, TryApply)
end

-- Appelé depuis Config quand l'utilisateur change un paramètre
function DM.ApplySettings()
    detectedFrame = nil
    if IsEnabled() then
        TryApply()
    end
end

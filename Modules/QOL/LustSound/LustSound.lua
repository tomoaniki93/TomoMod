-- =====================================
-- QOL/LustSound/LustSound.lua — Bloodlust Sound Alert
-- Detection via Sated/Exhaustion debuff presence (OhnoBloodlust approach)
-- Uses C_Timer polling only — NO RegisterEvent (zero taint risk)
-- =====================================

TomoMod_LustSound = TomoMod_LustSound or {}
local LS = TomoMod_LustSound

local SOUND_BASE = "Interface\\AddOns\\TomoMod\\Assets\\Sounds\\"

-- =====================================
-- SOUND REGISTRY
-- =====================================

LS.soundRegistry = {
    ["TALUANI"] = {
        name = "Taluani BL (Custom)",
        file = SOUND_BASE .. "Taluani_BL.ogg",
    },
    ["CUSTOM_OGG"] = {
        name = "Custom (Interface\\Sounds\\bloodlust.ogg)",
        file = "Interface\\Sounds\\bloodlust.ogg",
    },
    ["CUSTOM_MP3"] = {
        name = "Custom (Interface\\Sounds\\bloodlust.mp3)",
        file = "Interface\\Sounds\\bloodlust.mp3",
    },
}

LS.channelRegistry = {
    ["Master"]   = "Master",
    ["SFX"]      = "SFX",
    ["Music"]    = "Music",
    ["Ambience"] = "Ambience",
    ["Dialog"]   = "Dialog",
}

-- =====================================
-- SATED / EXHAUSTION DEBUFF SPELL IDS
-- When any of these appears on the player, Bloodlust was cast.
-- When all are gone, the Sated window has expired.
-- Same list used by OhnoBloodlust, BLDetect, etc.
-- =====================================

local SATED_IDS = {
    [57723]  = true,  -- Exhaustion (Shaman Heroism)
    [57724]  = true,  -- Sated (Shaman Bloodlust)
    [80354]  = true,  -- Temporal Displacement (Mage Time Warp)
    [95809]  = true,  -- Insanity (Hunter pet Ancient Hysteria)
    [160455] = true,  -- Fatigued (Hunter pet Primal Rage)
    [264689] = true,  -- Fatigued (Hunter pet Primal Rage variant)
    [390435] = true,  -- Exhaustion (Evoker Fury of the Aspects)
}

-- =====================================
-- STATE
-- Simple boolean toggle (same as OhnoBloodlust):
--   false -> true  = Sated just appeared  -> play sound
--   true  -> false = Sated just disappeared -> silent
-- No combat checks, no duration thresholds, no re-trigger risk.
-- =====================================

local active = false
local soundHandle = nil
local mainTicker = nil
local suppressUntil = 0  -- suppress sound until this GetTime() (login settle)

local POLL_INTERVAL = 0.5

-- =====================================
-- DETECTION: Any Sated debuff present?
-- =====================================

local function HasSatedDebuff()
    for spellID in pairs(SATED_IDS) do
        if C_UnitAuras.GetPlayerAuraBySpellID(spellID) then
            return true
        end
    end
    return false
end

-- =====================================
-- SOUND PLAYBACK
-- =====================================

local function DoPlaySound()
    local db = TomoModDB and TomoModDB.lustSound
    if not db then return end

    local entry = LS.soundRegistry[db.sound] or LS.soundRegistry["TALUANI"]

    if soundHandle then
        StopSound(soundHandle, 500)
        soundHandle = nil
    end

    local willPlay, handle = PlaySoundFile(entry.file, db.channel or "Master")
    if willPlay then
        soundHandle = handle
    end
end

function LS.PlayPreview()
    DoPlaySound()
end

function LS.StopPreview()
    if soundHandle then
        StopSound(soundHandle, 500)
        soundHandle = nil
    end
end

-- =====================================
-- MAIN POLL (replaces ALL events)
-- Mirrors OhnoBloodlust's UNIT_AURA logic but via timer polling
-- to avoid any RegisterEvent taint in TomoMod's loading context.
-- =====================================

local function OnPollTick()
    local db = TomoModDB and TomoModDB.lustSound
    if not db or not db.enabled then return end

    local hasSated = HasSatedDebuff()

    -- Transition: Sated just appeared -> trigger
    if hasSated and not active then
        active = true

        if db.showChat then
            print("|cff0cd29fTomoMod|r |cffff4400\226\153\170 Bloodlust d\195\169tect\195\169 !|r")
        end

        -- Suppress sound during login/reload settle window
        if GetTime() < suppressUntil then
            if db.debug then
                print("|cff0cd29fLustSound|r Trigger suppressed (login settle)")
            end
        else
            if db.debug then
                print("|cff0cd29fLustSound|r Trigger: sated debuff appeared")
            end
            DoPlaySound()
        end

    -- Transition: Sated just disappeared -> end
    elseif not hasSated and active then
        active = false

        if db.showChat then
            print("|cff0cd29fTomoMod|r |cff888888Bloodlust termin\195\169.|r")
        end
    end
end

-- =====================================
-- START / STOP TICKER
-- =====================================

local function StartTicker()
    if mainTicker then return end
    mainTicker = C_Timer.NewTicker(POLL_INTERVAL, OnPollTick)
end

local function StopTicker()
    if mainTicker then mainTicker:Cancel(); mainTicker = nil end
end

-- =====================================
-- ENABLE / DISABLE (from config)
-- =====================================

function LS.SetEnabled(enabled)
    local db = TomoModDB and TomoModDB.lustSound
    if db then db.enabled = enabled end

    if enabled then
        StartTicker()
    else
        StopTicker()
        active = false
    end
end

-- =====================================
-- INITIALIZE (called from Init.lua)
-- =====================================

function LS.Initialize()
    local db = TomoModDB and TomoModDB.lustSound
    if not db or not db.enabled then return end
    if mainTicker then return end

    -- 3s suppress window: if Sated is already present at login/reload,
    -- don't replay the sound (lust was cast before the reload).
    suppressUntil = GetTime() + 3.0

    -- 2s delay to let login auras settle
    C_Timer.After(2.0, function()
        if not (TomoModDB and TomoModDB.lustSound and TomoModDB.lustSound.enabled) then return end
        -- Snapshot current sated state so an existing debuff doesn't
        -- false-trigger on first tick (transition guard handles this
        -- correctly: if sated is already present, active starts false,
        -- trigger fires but sound is suppressed by suppressUntil).
        StartTicker()
    end)
end

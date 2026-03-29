-- =====================================
-- QOL/LustSound/LustSound.lua — Bloodlust Sound Alert
-- Dual detection:
--   1. Instant via UNIT_SPELLCAST_SUCCEEDED (spell ID list)
--   2. Fallback via Sated/Exhaustion debuff polling
-- Force-sound: overrides Master volume so alert plays even when muted
-- =====================================

TomoMod_LustSound = TomoMod_LustSound or {}
local LS = TomoMod_LustSound

local SOUND_BASE = "Interface\\AddOns\\TomoMod\\Assets\\Sounds\\"

-- =====================================
-- SOUND REGISTRY
-- =====================================

LS.soundRegistry = {
    ["TALUANI"] = {
        name = "Taluani BL",
        file = SOUND_BASE .. "Taluani_BL.ogg",
    },
    ["GOLDEN_KPOP"] = {
        name = "Golden Kpop",
        file = SOUND_BASE .. "Golden_Lust.ogg",
    },
    ["SPINNING_CAT"] = {
        name = "Spinning Cat",
        file = SOUND_BASE .. "Spining_Cat.ogg",
    },
    ["CHIPI_CHAPA"] = {
        name = "Chipi Chapa",
        file = SOUND_BASE .. "Chipi.ogg",
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
-- BLOODLUST SPELL IDS (instant detection via UNIT_SPELLCAST_SUCCEEDED)
-- Same list as PedroBL — covers all class lusts, drums, and pet abilities
-- =====================================

-- TWW 11.1: spellID from UNIT_SPELLCAST_SUCCEEDED is a secret number —
-- can't be used as table index, so we use a list and compare with ==
local BL_SPELLS = {
    -- Class abilities (30% haste)
    2825,    -- Bloodlust (Shaman Horde)
    32182,   -- Heroism (Shaman Alliance)
    80353,   -- Time Warp (Mage)
    264667,  -- Primal Rage (Hunter Alliance — Ferocity pet)
    272678,  -- Primal Rage (Hunter Horde — Ferocity pet)
    390386,  -- Fury of the Aspects (Evoker)

    -- Drums (15% haste)
    146555,  -- Drums of the Legion
    178207,  -- Drums of Fury
    230935,  -- Drums of the Mountain
    256740,  -- Drums of Deadly Ferocity
    309658,  -- Drums of Deathly Ferocity (SL/DF/TWW)
    444257,  -- Thunderous Drums
    444120,  -- War Drums

    -- Other (pets / specials)
    160452,  -- Abyssal Celerity
    90355,   -- Ancient Hysteria (Hunter core hound)
    110309,  -- Symbiosis: Bloodlust
    466904,  -- Eaglet Screech (Hunter TWW)
}

-- =====================================
-- SATED / EXHAUSTION DEBUFF SPELL IDS (detection via polling)
-- When any of these appears on the player, Bloodlust was cast.
-- TWW 11.1: spellID from UNIT_SPELLCAST_SUCCEEDED is a secret number —
-- cannot be compared, indexed, or used in arithmetic, so instant spell
-- detection is no longer possible. We rely entirely on Sated polling.
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
-- =====================================

local active = false
local soundHandle = nil
local mainTicker = nil
local suppressUntil = 0
local savedMasterVol = nil
local savedMasterEnabled = nil

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
-- FORCE-SOUND CVar MANAGEMENT
-- =====================================

local function ForceSoundOn()
    local db = TomoModDB and TomoModDB.lustSound
    if not db or not db.forceSound then return end

    if savedMasterVol == nil then
        savedMasterVol = tonumber(GetCVar("Sound_MasterVolume")) or 0.5
        savedMasterEnabled = GetCVar("Sound_EnableAllSound")
    end

    C_CVar.SetCVar("Sound_EnableAllSound", "1")
    C_CVar.SetCVar("Sound_MasterVolume", tostring(math.max(savedMasterVol, 0.5)))
end

local function RestoreSound()
    if savedMasterVol then
        C_CVar.SetCVar("Sound_MasterVolume", tostring(savedMasterVol))
    end
    if savedMasterEnabled then
        C_CVar.SetCVar("Sound_EnableAllSound", savedMasterEnabled)
    end
    savedMasterVol = nil
    savedMasterEnabled = nil
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

    ForceSoundOn()

    local willPlay, handle = PlaySoundFile(entry.file, db.channel or "Master")
    if willPlay then
        soundHandle = handle
    end
end

local function DoStopSound()
    if soundHandle then
        StopSound(soundHandle, 500)
        soundHandle = nil
    end
    RestoreSound()
end

function LS.PlayPreview()
    DoPlaySound()
end

function LS.StopPreview()
    DoStopSound()
end

-- =====================================
-- TRIGGER LOGIC (shared by both detection paths)
-- =====================================

local function OnLustDetected(source)
    local db = TomoModDB and TomoModDB.lustSound
    if not db or not db.enabled then return end
    if active then return end

    active = true

    if db.showChat then
        print("|cff0cd29fTomoMod|r |cffff4400\226\153\170 Bloodlust d\195\169tect\195\169 !|r")
    end

    if GetTime() < suppressUntil then
        if db.debug then
            print("|cff0cd29fLustSound|r Trigger suppressed (login settle)")
        end
    else
        if db.debug then
            print("|cff0cd29fLustSound|r Trigger: " .. (source or "unknown"))
        end
        DoPlaySound()
    end
end

local function OnLustEnded()
    local db = TomoModDB and TomoModDB.lustSound
    if not active then return end

    active = false
    DoStopSound()

    if db and db.showChat then
        print("|cff0cd29fTomoMod|r |cff888888Bloodlust termin\195\169.|r")
    end
end

-- =====================================
-- SATED DEBUFF POLLING (primary detection)
-- TWW 11.1: UNIT_SPELLCAST_SUCCEEDED spellID is a secret number —
-- even == comparison is blocked, so spell-cast detection is removed.
-- Polling catches all BL variants via Sated/Exhaustion debuffs.
-- =====================================

local function OnPollTick()
    local db = TomoModDB and TomoModDB.lustSound
    if not db or not db.enabled then return end

    local hasSated = HasSatedDebuff()

    if hasSated and not active then
        OnLustDetected("sated debuff appeared")
    elseif not hasSated and active then
        OnLustEnded()
    end
end

-- =====================================
-- START / STOP
-- =====================================

local function StartDetection()
    if not mainTicker then
        mainTicker = C_Timer.NewTicker(POLL_INTERVAL, OnPollTick)
    end
end

local function StopDetection()
    if mainTicker then mainTicker:Cancel(); mainTicker = nil end

    if active then
        OnLustEnded()
    end
end

-- =====================================
-- ENABLE / DISABLE (from config)
-- =====================================

function LS.SetEnabled(enabled)
    local db = TomoModDB and TomoModDB.lustSound
    if db then db.enabled = enabled end

    if enabled then
        StartDetection()
    else
        StopDetection()
    end
end

-- =====================================
-- INITIALIZE (called from Init.lua)
-- =====================================

function LS.Initialize()
    local db = TomoModDB and TomoModDB.lustSound
    if not db or not db.enabled then return end

    -- 3s suppress window: if Sated is already present at login/reload,
    -- don't replay the sound (lust was cast before the reload).
    suppressUntil = GetTime() + 3.0

    -- 2s delay to let login auras settle before starting detection
    C_Timer.After(2.0, function()
        if not (TomoModDB and TomoModDB.lustSound and TomoModDB.lustSound.enabled) then return end
        StartDetection()
    end)
end

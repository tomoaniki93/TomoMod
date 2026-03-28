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

local BL_SPELLS = {
    -- Class abilities (30% haste)
    [2825]   = true,  -- Bloodlust (Shaman Horde)
    [32182]  = true,  -- Heroism (Shaman Alliance)
    [80353]  = true,  -- Time Warp (Mage)
    [264667] = true,  -- Primal Rage (Hunter Alliance — Ferocity pet)
    [272678] = true,  -- Primal Rage (Hunter Horde — Ferocity pet)
    [390386] = true,  -- Fury of the Aspects (Evoker)

    -- Drums (15% haste)
    [146555] = true,  -- Drums of the Legion
    [178207] = true,  -- Drums of Fury
    [230935] = true,  -- Drums of the Mountain
    [256740] = true,  -- Drums of Deadly Ferocity
    [309658] = true,  -- Drums of Deathly Ferocity (SL/DF/TWW)
    [444257] = true,  -- Thunderous Drums
    [444120] = true,  -- War Drums

    -- Other (pets / specials)
    [160452] = true,  -- Abyssal Celerity
    [90355]  = true,  -- Ancient Hysteria (Hunter core hound)
    [110309] = true,  -- Symbiosis: Bloodlust
    [466904] = true,  -- Eaglet Screech (Hunter TWW)
}

-- =====================================
-- SATED / EXHAUSTION DEBUFF SPELL IDS (fallback polling)
-- When any of these appears on the player, Bloodlust was cast.
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
-- PATH 1: INSTANT DETECTION via UNIT_SPELLCAST_SUCCEEDED
-- Triggers the moment someone casts a BL spell — zero delay.
-- =====================================

local spellListener = CreateFrame("Frame")

local function OnSpellEvent(self, event, unitID, _, spellID)
    if event ~= "UNIT_SPELLCAST_SUCCEEDED" then return end

    local db = TomoModDB and TomoModDB.lustSound
    if not db or not db.enabled then return end

    if spellID and BL_SPELLS[spellID] then
        OnLustDetected("spell cast " .. tostring(spellID))
    end
end

-- =====================================
-- PATH 2: SATED DEBUFF POLLING (fallback)
-- Catches anything the spell list might miss.
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
    -- Path 1: event listener
    spellListener:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    spellListener:SetScript("OnEvent", OnSpellEvent)

    -- Path 2: sated polling
    if not mainTicker then
        mainTicker = C_Timer.NewTicker(POLL_INTERVAL, OnPollTick)
    end
end

local function StopDetection()
    -- Path 1
    spellListener:UnregisterAllEvents()
    spellListener:SetScript("OnEvent", nil)

    -- Path 2
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

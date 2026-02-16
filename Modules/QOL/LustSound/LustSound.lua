-- =====================================
-- QOL/LustSound/LustSound.lua — Bloodlust Sound Alert
-- Dual detection: haste spike + sated debuff + buff fallback
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
-- STATE
-- =====================================

local active = false
local maybeHaste = false
local maybeSated = false
local lockedBaseline = nil
local hasteValues = nil
local confirmTimer = nil
local soundHandle = nil
local mainTicker = nil
local wasInCombat = false

-- Snapshot of harmful aura IDs for sated detection
local prevAuraIDs = {}

-- Known Bloodlust buff spell IDs (name-based lookup is broken in 12.x)
local LUST_BUFF_IDS = {
    [2825]   = "Bloodlust",
    [32182]  = "Heroism",
    [80353]  = "Time Warp",
    [90355]  = "Ancient Hysteria",
    [264667] = "Primal Rage",
    [390386] = "Fury of the Aspects",
    [392844] = "Harrier's Cry",
}

local POLL_INTERVAL = 0.5

-- =====================================
-- HASTE MATH
-- =====================================

local function GetMean(v)
    return (v[1] + v[2] + v[3] + v[4] + v[5]) / 5
end

local function IsMaybeBloodlust(v, current, opts)
    local m = GetMean(v)
    local maxv = math.max(v[1], v[2], v[3], v[4], v[5])
    if m < 0.01 or maxv < 0.01 then return false, 0, 0 end

    local ratio = current / m
    local jump = current / maxv

    return ratio >= (opts.spike_ratio / 100) and jump >= (opts.jump_ratio / 100), ratio, jump
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
-- AURA SNAPSHOT (sated detection)
-- =====================================

local function SnapshotHarmfulAuras()
    local ids = {}
    for i = 1, 40 do
        local data = C_UnitAuras.GetAuraDataByIndex("player", i, "HARMFUL")
        if not data then break end
        ids[data.auraInstanceID] = true
    end
    return ids
end

local function HasNewHarmfulAura(prev, curr)
    for id in pairs(curr) do
        if not prev[id] then return true end
    end
    return false
end

-- =====================================
-- BUFF DETECTION (direct check)
-- =====================================

local function HasLustBuff()
    -- Use C_UnitAuras to iterate player buffs by spell ID (12.x safe)
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetBuffDataByIndex("player", i)
        if not auraData then break end
        if auraData.spellId and LUST_BUFF_IDS[auraData.spellId] then
            return true, LUST_BUFF_IDS[auraData.spellId]
        end
    end
    return false
end

-- =====================================
-- CONFIRM TIMER (waits for haste + sated)
-- =====================================

local confirmCount = 0

local function ConfirmTick()
    confirmCount = confirmCount - 1

    if maybeHaste and maybeSated then
        LS.TriggerBloodlust()
        if confirmTimer then confirmTimer:Cancel(); confirmTimer = nil end
        return
    end

    if confirmCount <= 0 then
        local db = TomoModDB and TomoModDB.lustSound
        if db and db.debug then
            print("|cff0cd29fLustSound|r Confirm expired: haste=" .. tostring(maybeHaste) .. " sated=" .. tostring(maybeSated))
        end
        maybeHaste = false
        maybeSated = false
        if confirmTimer then confirmTimer:Cancel(); confirmTimer = nil end
    end
end

local function StartConfirmTimer()
    if confirmTimer then return end
    confirmCount = 15
    confirmTimer = C_Timer.NewTicker(0.1, ConfirmTick, 15)
end

-- =====================================
-- BLOODLUST START / STOP
-- =====================================

function LS.TriggerBloodlust()
    if active then return end

    local db = TomoModDB and TomoModDB.lustSound
    active = true
    lockedBaseline = hasteValues and GetMean(hasteValues) or 0

    if db and db.showChat then
        print("|cff0cd29fTomoMod|r |cffff4400\226\153\170 Bloodlust d\195\169tect\195\169 !|r")
    end

    DoPlaySound()
end

local function EndBloodlust()
    if not active then return end

    active = false
    maybeHaste = false
    maybeSated = false
    lockedBaseline = nil

    local db = TomoModDB and TomoModDB.lustSound
    if db and db.showChat then
        print("|cff0cd29fTomoMod|r |cff888888Bloodlust termin\195\169.|r")
    end
end

-- =====================================
-- HASTE BASELINE
-- =====================================

local function SetHasteBaseline()
    local h = UnitSpellHaste("player")
    hasteValues = { h, h, h, h, h }
end

-- =====================================
-- MAIN POLL (replaces ALL events)
-- =====================================

local function OnPollTick()
    local db = TomoModDB and TomoModDB.lustSound
    if not db or not db.enabled then return end
    if not hasteValues then return end

    local inCombat = InCombatLockdown()

    -- Combat exit: reset
    if wasInCombat and not inCombat then
        if active then EndBloodlust() end
        maybeHaste = false
        maybeSated = false
        lockedBaseline = nil
    end
    wasInCombat = inCombat

    -- 1) Buff-based detection (works anytime, instant)
    if not active then
        local hasLust, lustName = HasLustBuff()
        if hasLust then
            if db.debug then
                print("|cff0cd29fLustSound|r Buff: " .. tostring(lustName))
            end
            LS.TriggerBloodlust()
            return
        end
    end

    -- 2) Haste spike detection
    local v = hasteValues
    local current = UnitSpellHaste("player")
    local m = GetMean(v)
    local maybeLust, ratio, jump = IsMaybeBloodlust(v, current, db.detection)

    -- Spike START
    if not maybeHaste and not active and maybeLust then
        if db.debug then
            print(string.format("|cff0cd29fLustSound|r Spike! cur=%.2f mean=%.2f ratio=%.2f jump=%.2f", current, m, ratio, jump))
        end
        lockedBaseline = m
        maybeHaste = true
        StartConfirmTimer()
        -- Check auras but don't update baseline
    elseif active and lockedBaseline then
        -- Fade detection
        local fadeCheck = current / lockedBaseline
        if fadeCheck < (db.detection.fade_ratio / 100) then
            EndBloodlust()
        end
        -- Don't update baseline while active
    else
        -- Debug
        if db.debug and current ~= v[5] then
            print(string.format("|cff0cd29fLustSound|r h=%.2f m=%.2f r=%.2f j=%.2f", current, m, ratio, jump))
        end

        -- Normal baseline update
        if not active then
            v[1] = v[2]; v[2] = v[3]; v[3] = v[4]; v[4] = v[5]; v[5] = current
        end
    end

    -- 3) Sated detection (new harmful aura appeared)
    if not maybeSated and not active then
        local currIDs = SnapshotHarmfulAuras()
        if HasNewHarmfulAura(prevAuraIDs, currIDs) then
            if db.debug then
                print("|cff0cd29fLustSound|r New harmful aura (Sated?)")
            end
            maybeSated = true
            StartConfirmTimer()
        end
        prevAuraIDs = currIDs
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
    if confirmTimer then confirmTimer:Cancel(); confirmTimer = nil end
end

-- =====================================
-- ENABLE / DISABLE (from config)
-- =====================================

function LS.SetEnabled(enabled)
    local db = TomoModDB and TomoModDB.lustSound
    if db then db.enabled = enabled end

    if enabled then
        SetHasteBaseline()
        prevAuraIDs = SnapshotHarmfulAuras()
        wasInCombat = InCombatLockdown()
        StartTicker()
    else
        StopTicker()
        EndBloodlust()
    end
end

-- =====================================
-- INITIALIZE (called from Init.lua)
-- =====================================

function LS.Initialize()
    local db = TomoModDB and TomoModDB.lustSound
    if not db or not db.enabled then return end
    if mainTicker then return end

    -- 2s delay to let login haste settle
    C_Timer.After(2.0, function()
        if not (TomoModDB and TomoModDB.lustSound and TomoModDB.lustSound.enabled) then return end
        SetHasteBaseline()
        prevAuraIDs = SnapshotHarmfulAuras()
        wasInCombat = InCombatLockdown()
        StartTicker()
    end)
end

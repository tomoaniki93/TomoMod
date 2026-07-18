-- =====================================
-- CDMScanner.lua — Phase 1: Anti-Taint CDM Caching
-- Inspired by DDingUI BetterCooldownManager pattern
--
-- Problem: Accessing frame.cooldownID during combat propagates
-- taint through Blizzard_CooldownViewer secure frames.
--
-- Solution: Cache all frame → cooldownID mappings in weak tables
-- outside combat. During combat, use cached values only.
--
-- Usage:
--   local cdID  = CDMScanner.GetCachedCooldownID(frame)
--   local info  = CDMScanner.GetCachedInfo(frame)
--   local spell = CDMScanner.GetCachedSpellID(frame)
-- =====================================

TomoMod_CDMScanner = TomoMod_CDMScanner or {}
local Scanner = TomoMod_CDMScanner

-- =====================================
-- WEAK TABLES (auto-cleanup on GC)
-- =====================================

-- frame → cooldownID (primary cache — prevents taint)
local frameToCooldownID = setmetatable({}, { __mode = "k" })

-- frame → { spellID, overrideSpellID, hasAura, charges, flags }
local frameToCooldownInfo = setmetatable({}, { __mode = "k" })

-- frame → chargesShown (cached boolean from cooldownChargesShown)
local frameToChargesShown = setmetatable({}, { __mode = "k" })

-- =====================================
-- STATE
-- =====================================
local isInCombat    = false
local lastScanTime  = 0
local scanCount     = 0
local isInitialized = false

-- Viewer list (same as CooldownManager.lua)
local CDM_VIEWERS = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
    "BuffIconCooldownViewer",
    "BuffBarCooldownViewer",
}

-- =====================================
-- SAFE ACCESSORS (zero taint — reads weak table only)
-- =====================================

--- Get cached cooldownID for a frame (SAFE during combat)
--- @param frame table — CDM child frame
--- @return number|nil cooldownID
function Scanner.GetCachedCooldownID(frame)
    if not frame then return nil end
    return frameToCooldownID[frame]
end

--- Get cached cooldown info for a frame (SAFE during combat)
--- Returns { spellID, overrideSpellID, hasAura, charges, flags }
--- @param frame table — CDM child frame
--- @return table|nil info
function Scanner.GetCachedInfo(frame)
    if not frame then return nil end
    return frameToCooldownInfo[frame]
end

--- Get cached spellID for a frame (convenience — SAFE during combat)
--- Returns overrideSpellID if available, otherwise spellID
--- @param frame table — CDM child frame
--- @return number|nil spellID
function Scanner.GetCachedSpellID(frame)
    local info = frameToCooldownInfo[frame]
    if not info then return nil end
    return info.overrideSpellID or info.spellID
end

--- Get cached chargesShown for a frame (SAFE during combat)
--- @param frame table — CDM child frame
--- @return boolean
function Scanner.GetCachedChargesShown(frame)
    if not frame then return false end
    return frameToChargesShown[frame] or false
end

--- Check if scanner is initialized and has cached data
--- @return boolean
function Scanner.IsReady()
    return isInitialized and lastScanTime > 0
end

--- Get scan statistics
--- @return number lastScanTime, number scanCount, number cachedFrames
function Scanner.GetStats()
    local count = 0
    for _ in pairs(frameToCooldownID) do count = count + 1 end
    return lastScanTime, scanCount, count
end

-- =====================================
-- SCAN ENGINE (only runs outside combat)
-- =====================================

--- Cache a single frame's cooldownID and cooldown info.
--- Uses pcall to safely read protected properties.
--- @param frame table — CDM child frame
--- @return boolean success
local function CacheFrame(frame)
    if not frame then return false end

    -- 1. Read cooldownID (protected property → pcall)
    local cdID
    local ok = pcall(function()
        cdID = frame.cooldownID
        -- Fallback: nested cooldownInfo table
        if not cdID and frame.cooldownInfo then
            cdID = frame.cooldownInfo.cooldownID
        end
        -- Fallback: bar frames with Icon.cooldownID
        if not cdID and frame.Icon and frame.Icon.cooldownID then
            cdID = frame.Icon.cooldownID
        end
    end)

    if not ok or not cdID or type(cdID) ~= "number" then return false end

    -- Store in weak table
    frameToCooldownID[frame] = cdID

    -- 2. Read cooldown info from API (numeric cdID is safe to pass)
    local info
    pcall(function()
        info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cdID)
    end)

    if info then
        frameToCooldownInfo[frame] = {
            spellID            = info.spellID,
            overrideSpellID    = info.overrideSpellID,
            hasAura            = info.hasAura,
            selfAura           = info.selfAura,
            charges            = info.charges,
            flags              = info.flags,
            linkedSpellIDs     = info.linkedSpellIDs,
        }
    end

    -- 3. Cache chargesShown (can be secretvalue in combat)
    pcall(function()
        local cs = frame.cooldownChargesShown
        if cs ~= nil and not issecretvalue(cs) then
            frameToChargesShown[frame] = (cs == true)
        end
    end)

    return true
end

--- Full scan of all CDM viewers. Only call outside combat.
--- Wipes and rebuilds all caches.
--- @return boolean success, number totalCached
function Scanner.ScanAll()
    if InCombatLockdown() then
        return false, 0
    end

    -- Wipe caches (weak tables keep old entries until GC, but we
    -- want fresh data — stale mappings are harmless but wasteful)
    wipe(frameToCooldownID)
    wipe(frameToCooldownInfo)
    wipe(frameToChargesShown)

    local totalCached = 0

    for _, viewerName in ipairs(CDM_VIEWERS) do
        local viewer = _G[viewerName]
        if viewer then
            local children = { viewer:GetChildren() }
            for _, frame in ipairs(children) do
                if CacheFrame(frame) then
                    totalCached = totalCached + 1
                end
            end
        end
    end

    lastScanTime = GetTime()
    scanCount = scanCount + 1
    isInitialized = true

    return true, totalCached
end

--- Incremental scan: cache a single frame if not already cached.
--- Safe to call anytime — skips if in combat and frame not in cache.
--- @param frame table — CDM child frame
--- @return number|nil cooldownID — the cached (or newly cached) cooldownID
function Scanner.EnsureCached(frame)
    if not frame then return nil end

    -- Already cached? Return immediately
    local existing = frameToCooldownID[frame]
    if existing then return existing end

    -- Not cached — try to cache (only if out of combat)
    if not InCombatLockdown() then
        if CacheFrame(frame) then
            return frameToCooldownID[frame]
        end
    end

    return nil
end

--- Refresh info cache for all known frames (without re-reading cooldownID).
--- Useful when spell overrides change (talent swap, override spell procs).
--- Safe outside combat only.
function Scanner.RefreshInfo()
    if InCombatLockdown() then return end

    for frame, cdID in pairs(frameToCooldownID) do
        local info
        pcall(function()
            info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cdID)
        end)
        if info then
            frameToCooldownInfo[frame] = {
                spellID            = info.spellID,
                overrideSpellID    = info.overrideSpellID,
                hasAura            = info.hasAura,
                selfAura           = info.selfAura,
                charges            = info.charges,
                flags              = info.flags,
                linkedSpellIDs     = info.linkedSpellIDs,
            }
        end

        -- Refresh chargesShown
        pcall(function()
            local cs = frame.cooldownChargesShown
            if cs ~= nil and not issecretvalue(cs) then
                frameToChargesShown[frame] = (cs == true)
            end
        end)
    end
end

-- =====================================
-- EVENT-DRIVEN AUTO-SCAN
-- =====================================

local eventFrame = CreateFrame("Frame")

-- Debounce: collapse rapid events into one scan
local pendingTimer = nil
local function DebouncedScan(delay)
    if pendingTimer then
        pendingTimer:Cancel()
    end
    pendingTimer = C_Timer.NewTimer(delay, function()
        pendingTimer = nil
        Scanner.ScanAll()
    end)
end

-- Progressive retry for init / spec changes (cancel previous timers)
local retryTimers = {}
local function ScheduleRetryScans(delays)
    for i = 1, #retryTimers do
        if retryTimers[i] then retryTimers[i]:Cancel() end
    end
    wipe(retryTimers)
    for _, delay in ipairs(delays) do
        retryTimers[#retryTimers + 1] = C_Timer.NewTimer(delay, function()
            Scanner.ScanAll()
        end)
    end
end

eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
eventFrame:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_REGEN_DISABLED" then
        isInCombat = true
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        isInCombat = false
        -- Rescan after combat ends (frames may have changed)
        DebouncedScan(0.3)
        return
    end

    if event == "ADDON_LOADED" and arg1 == "Blizzard_CooldownManager" then
        -- CDM just loaded — schedule initial scan
        ScheduleRetryScans({ 0.5, 1.5 })
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        -- Reload / zone change — progressive retry
        ScheduleRetryScans({ 0.5, 1.5, 3.0 })
        return
    end

    -- Spec / talent changes — progressive retry
    if event == "PLAYER_SPECIALIZATION_CHANGED"
        or event == "TRAIT_CONFIG_UPDATED"
        or event == "TRAIT_CONFIG_LIST_UPDATED"
        or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        ScheduleRetryScans({ 0.5, 1.5, 3.0 })
        return
    end
end)

-- =====================================
-- DEBUG SLASH COMMAND
-- =====================================
SLASH_TOMOCDMSCAN1 = "/tomocdmscan"
SlashCmdList["TOMOCDMSCAN"] = function(msg)
    if msg == "scan" then
        local ok, total = Scanner.ScanAll()
        print("|cff00ccffTomoMod CDMScanner:|r " .. (ok and ("Scanned " .. total .. " frames") or "Failed (in combat)"))
    elseif msg == "stats" then
        local t, sc, fc = Scanner.GetStats()
        print("|cff00ccffTomoMod CDMScanner:|r")
        print("  Last scan: " .. (t > 0 and string.format("%.1fs ago", GetTime() - t) or "never"))
        print("  Total scans: " .. sc)
        print("  Cached frames: " .. fc)
        print("  In combat: " .. tostring(isInCombat))
    elseif msg == "dump" then
        print("|cff00ccffTomoMod CDMScanner:|r Cached entries:")
        local i = 0
        for frame, cdID in pairs(frameToCooldownID) do
            i = i + 1
            local info = frameToCooldownInfo[frame]
            local name = info and info.spellID and C_Spell.GetSpellName(info.overrideSpellID or info.spellID) or "?"
            print(string.format("  [%d] cdID:%d → %s (spell:%s)", i, cdID, name, tostring(info and (info.overrideSpellID or info.spellID))))
        end
    else
        print("|cff00ccffTomoMod CDMScanner:|r Commands: scan, stats, dump")
    end
end

-- Export
_G.TomoMod_CDMScanner = Scanner

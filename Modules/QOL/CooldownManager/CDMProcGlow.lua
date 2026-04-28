-- =====================================
-- CDMProcGlow.lua — Phase 3: Custom Proc Glow Effects
-- Inspired by DDingUI ProcGlow module
--
-- Replaces Blizzard's default SpellActivationAlert on CDM icons
-- with configurable glow effects via LibCustomGlow-1.0.
--
-- Features:
--   • 5 glow types: Pixel, Autocast, ButtonGlow, ProcGlow, Blizzard
--   • Configurable color, line count, frequency, thickness
--   • Persistence timer: re-applies glow if removed externally
--   • SpellID tracking: survives frame recycling/rescan
--   • Anti-taint: uses CDMScanner for spellID lookups
--   • Per-viewer enable/disable
--
-- Usage:
--   CDMProcGlow.Initialize()    — call once after CDM init
--   CDMProcGlow.RefreshAll()     — after settings change
--   CDMProcGlow.UpdateButton(button) — after skin/layout changes
--
-- Requires: CDMScanner.lua loaded before this file.
-- Optional: LibCustomGlow-1.0 (falls back to Blizzard glow)
-- =====================================

TomoMod_CDMProcGlow = TomoMod_CDMProcGlow or {}
local ProcGlow = TomoMod_CDMProcGlow

local Scanner = TomoMod_CDMScanner

-- =====================================
-- OPTIONAL LIBRARY
-- =====================================
local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)

-- =====================================
-- CONSTANTS
-- =====================================
local GLOW_KEY = "_TomoCDMProcGlow"

-- Available glow types (order matches config dropdown)
ProcGlow.GlowTypes = {
    "Pixel Glow",
    "Autocast Shine",
    "Action Button Glow",
    "Proc Glow",
    "Blizzard Glow",
}

-- Default glow settings
local DEFAULTS = {
    enabled         = true,
    glowType        = "Pixel Glow",
    color           = { 0.95, 0.95, 0.32, 1 },
    -- Pixel Glow
    pixelLines      = 5,
    pixelFrequency  = 0.25,
    pixelLength     = 8,
    pixelThickness  = 1,
    -- Autocast Shine
    autoParticles   = 8,
    autoFrequency   = 0.25,
    autoScale       = 1.0,
    -- Button Glow
    buttonFrequency = 0.25,
}

-- =====================================
-- STATE
-- =====================================
local activeGlows  = {}    -- [frame] = true
local activeSpells = {}    -- [spellID] = true (survives frame recycle)
local persistTimers = {}   -- [frame] = ticker
local isInitialized = false

-- =====================================
-- VIEWER LIST
-- =====================================
local CDM_VIEWERS = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
    "BuffIconCooldownViewer",
}

-- =====================================
-- SETTINGS ACCESSOR
-- =====================================
local function GetSettings()
    local db = TomoModDB and TomoModDB.cooldownManager
    return db and db.procGlow or DEFAULTS
end

-- =====================================
-- SPELLID LOOKUP (via CDMScanner — anti-taint)
-- =====================================
local function GetButtonSpellID(button)
    if not button then return nil end

    -- CDMScanner cached spellID (safe during combat)
    local spellID = Scanner.GetCachedSpellID(button)
    if spellID then return spellID end

    -- Fallback: try GetSpellID method
    if button.GetSpellID and type(button.GetSpellID) == "function" then
        local ok, sid = pcall(button.GetSpellID, button)
        if ok and sid and type(sid) == "number" and sid > 0 then return sid end
    end

    return nil
end

-- =====================================
-- VIEWER DETECTION
-- =====================================
local function IsCooldownViewerIcon(button)
    if not button then return false end
    local parent = button:GetParent()
    if not parent or not parent.GetName then return false end
    local name = parent:GetName()
    for _, vName in ipairs(CDM_VIEWERS) do
        if name == vName then return true end
    end
    return false
end

-- =====================================
-- HIDE BLIZZARD GLOW
-- =====================================
local function HideBlizzardGlow(frame)
    if frame.SpellActivationAlert then
        frame.SpellActivationAlert:Hide()
        if frame.SpellActivationAlert.ProcLoopFlipbook then
            frame.SpellActivationAlert.ProcLoopFlipbook:Hide()
        end
        if frame.SpellActivationAlert.ProcStartFlipbook then
            frame.SpellActivationAlert.ProcStartFlipbook:Hide()
        end
    end
    if frame.overlay then frame.overlay:Hide() end
    if frame.Overlay then frame.Overlay:Hide() end
    if frame.Glow    then frame.Glow:Hide()    end
end

-- =====================================
-- GLOW FRAME DETECTION
-- =====================================
local function IsGlowFramePresent(frame, glowType)
    local glowFrame
    if glowType == "Pixel Glow" then
        glowFrame = frame["_PixelGlow" .. GLOW_KEY]
    elseif glowType == "Autocast Shine" then
        glowFrame = frame["_AutoCastGlow" .. GLOW_KEY]
    elseif glowType == "Action Button Glow" then
        glowFrame = frame._ButtonGlow
    elseif glowType == "Proc Glow" then
        glowFrame = frame["_ProcGlow" .. GLOW_KEY]
    elseif glowType == "Blizzard Glow" then
        if frame.overlay and frame.overlay:IsShown() then return true end
        if frame.SpellActivationAlert and frame.SpellActivationAlert:IsShown() then return true end
        return false
    end
    return glowFrame and glowFrame.IsShown and glowFrame:IsShown() or false
end

-- =====================================
-- APPLY GLOW EFFECT (raw LCG call)
-- =====================================
local function ApplyGlowEffect(frame, forceRestart)
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    local glowType = settings.glowType or DEFAULTS.glowType
    local color = settings.color or DEFAULTS.color
    if not color[4] then color[4] = 1 end

    -- Skip if already active and correct type (prevent flicker)
    if not forceRestart and frame._cdm_procGlowActive and IsGlowFramePresent(frame, glowType) then
        return
    end

    -- Stop any existing glows first
    if LCG then
        LCG.PixelGlow_Stop(frame, GLOW_KEY)
        LCG.AutoCastGlow_Stop(frame, GLOW_KEY)
        LCG.ProcGlow_Stop(frame, GLOW_KEY)
        LCG.ButtonGlow_Stop(frame)
    end
    if ActionButton_HideOverlayGlow then
        ActionButton_HideOverlayGlow(frame)
    end

    -- Apply selected glow type
    if glowType == "Blizzard Glow" then
        if ActionButton_ShowOverlayGlow then
            ActionButton_ShowOverlayGlow(frame)
        end
    elseif LCG then
        if glowType == "Pixel Glow" then
            LCG.PixelGlow_Start(frame, color,
                math.floor(settings.pixelLines or DEFAULTS.pixelLines),
                settings.pixelFrequency or DEFAULTS.pixelFrequency,
                settings.pixelLength or DEFAULTS.pixelLength,
                settings.pixelThickness or DEFAULTS.pixelThickness,
                -1, -1, false, GLOW_KEY)
        elseif glowType == "Autocast Shine" then
            LCG.AutoCastGlow_Start(frame, color,
                math.floor(settings.autoParticles or DEFAULTS.autoParticles),
                settings.autoFrequency or DEFAULTS.autoFrequency,
                settings.autoScale or DEFAULTS.autoScale,
                0, 0, GLOW_KEY)
        elseif glowType == "Action Button Glow" then
            LCG.ButtonGlow_Start(frame, color,
                settings.buttonFrequency or DEFAULTS.buttonFrequency)
        elseif glowType == "Proc Glow" then
            LCG.ProcGlow_Start(frame, {
                color = color,
                startAnim = false,
                xOffset = 0,
                yOffset = 0,
                key = GLOW_KEY,
            })
        end
    end

    frame._cdm_procGlowActive = true
    activeGlows[frame] = true
end

-- =====================================
-- START GLOW (with persistence timer)
-- =====================================
local function StartGlow(frame)
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    local glowType = settings.glowType or DEFAULTS.glowType

    -- Already active and visible? Skip
    if frame._cdm_procGlowActive and IsGlowFramePresent(frame, glowType) then
        return
    end

    -- Apply the glow
    ApplyGlowEffect(frame)

    -- Cancel existing persistence timer
    if persistTimers[frame] then
        persistTimers[frame]:Cancel()
        persistTimers[frame] = nil
    end

    -- Start persistence timer: re-apply if removed externally (every 0.3s)
    persistTimers[frame] = C_Timer.NewTicker(0.3, function()
        if not activeGlows[frame] then
            if persistTimers[frame] then
                persistTimers[frame]:Cancel()
                persistTimers[frame] = nil
            end
            return
        end
        if not frame:IsShown() then return end

        local s = GetSettings()
        if not s or not s.enabled then return end
        local gt = s.glowType or DEFAULTS.glowType
        if not IsGlowFramePresent(frame, gt) then
            ApplyGlowEffect(frame)
            if gt ~= "Blizzard Glow" then
                HideBlizzardGlow(frame)
            end
        end
    end)
end

-- =====================================
-- STOP GLOW
-- =====================================
local function StopGlow(frame)
    if not frame._cdm_procGlowActive then return end

    -- Cancel persistence timer
    if persistTimers[frame] then
        persistTimers[frame]:Cancel()
        persistTimers[frame] = nil
    end

    -- Remove all glow types
    if LCG then
        LCG.PixelGlow_Stop(frame, GLOW_KEY)
        LCG.AutoCastGlow_Stop(frame, GLOW_KEY)
        LCG.ProcGlow_Stop(frame, GLOW_KEY)
        LCG.ButtonGlow_Stop(frame)
    end
    if ActionButton_HideOverlayGlow then
        ActionButton_HideOverlayGlow(frame)
    end

    frame._cdm_procGlowActive = nil
    activeGlows[frame] = nil
end

-- =====================================
-- REAPPLY AFTER RESKIN / LAYOUT
-- =====================================

--- Re-apply glows for tracked spellIDs after frames are recycled.
--- Call this after SkinAndLayout completes.
local function ReapplyGlowsForViewer(viewer)
    if not next(activeSpells) then return end
    if not viewer then return end

    local children = { viewer:GetChildren() }
    for _, child in ipairs(children) do
        if child and child:IsShown() and (child.Icon or child.icon) then
            local spellID = GetButtonSpellID(child)
            if spellID and activeSpells[spellID] then
                local settings = GetSettings()
                if settings and settings.enabled then
                    local gt = settings.glowType or DEFAULTS.glowType
                    if not child._cdm_procGlowActive then
                        if gt ~= "Blizzard Glow" then HideBlizzardGlow(child) end
                        StartGlow(child)
                    elseif not IsGlowFramePresent(child, gt) then
                        ApplyGlowEffect(child)
                        if gt ~= "Blizzard Glow" then HideBlizzardGlow(child) end
                    end
                end
            end
        end
    end
end

-- =====================================
-- SCAN EXISTING OVERLAYS
-- =====================================
local function ScanExistingOverlays()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    for _, viewerName in ipairs(CDM_VIEWERS) do
        local viewer = _G[viewerName]
        if viewer and viewer:IsShown() then
            local children = { viewer:GetChildren() }
            for _, child in ipairs(children) do
                if child and child:IsShown() and (child.Icon or child.icon) then
                    if child.SpellActivationAlert and child.SpellActivationAlert:IsShown() then
                        local spellID = GetButtonSpellID(child)
                        HideBlizzardGlow(child)
                        StartGlow(child)
                        if spellID then activeSpells[spellID] = true end
                    end
                end
            end
        end
    end
end

-- =====================================
-- SETUP HOOKS
-- =====================================
local function SetupHooks()
    if not ActionButtonSpellAlertManager then return end

    -- Hook ShowAlert: replace Blizzard glow with custom glow
    if ActionButtonSpellAlertManager.ShowAlert then
        hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", function(_, button)
            if not IsCooldownViewerIcon(button) then return end

            local settings = GetSettings()
            if not settings or not settings.enabled then return end

            local spellID = GetButtonSpellID(button)
            local glowType = settings.glowType or DEFAULTS.glowType

            button._cdm_procActive = true

            if glowType == "Blizzard Glow" then
                -- Let Blizzard's native glow show, just track it
                button._cdm_procGlowActive = true
                activeGlows[button] = true
            else
                HideBlizzardGlow(button)
                C_Timer.After(0, function()
                    if button._cdm_procActive then
                        StartGlow(button)
                        HideBlizzardGlow(button)
                    end
                end)
            end

            -- Track by spellID for rescan survival
            if spellID then activeSpells[spellID] = true end
        end)
    end

    -- Hook HideAlert: stop custom glow
    if ActionButtonSpellAlertManager.HideAlert then
        hooksecurefunc(ActionButtonSpellAlertManager, "HideAlert", function(_, button)
            if not IsCooldownViewerIcon(button) then return end

            local spellID = GetButtonSpellID(button)
            button._cdm_procActive = nil
            StopGlow(button)
            if spellID then activeSpells[spellID] = nil end
        end)
    end

    -- Scan for already-active overlays
    ScanExistingOverlays()
end

-- =====================================
-- PUBLIC API
-- =====================================

--- Initialize the ProcGlow module. Call once after CDM init.
function ProcGlow.Initialize()
    if isInitialized then return end
    isInitialized = true

    if ActionButtonSpellAlertManager then
        SetupHooks()
    else
        C_Timer.After(0.3, SetupHooks)
    end
end

--- Re-apply glow on a single button after skin/layout changes.
--- @param button table — CDM icon frame
function ProcGlow.UpdateButton(button)
    if not button then return end
    if button._cdm_procActive or activeGlows[button] then
        local settings = GetSettings()
        if settings and settings.enabled then
            ApplyGlowEffect(button)
            local gt = settings.glowType or DEFAULTS.glowType
            if gt ~= "Blizzard Glow" then HideBlizzardGlow(button) end
        end
    end
end

--- Re-apply glows on all viewers after SkinAndLayout.
--- @param viewers table — array of viewer frames
function ProcGlow.ReapplyAll(viewers)
    if not next(activeSpells) then return end
    for _, viewer in ipairs(viewers) do
        if viewer and viewer:IsShown() then
            ReapplyGlowsForViewer(viewer)
        end
    end
end

--- Refresh all glows (after settings change — stop + restart).
function ProcGlow.RefreshAll()
    -- Stop all current glows
    local procs = {}
    for frame in pairs(activeGlows) do
        local spellID = GetButtonSpellID(frame)
        if spellID then procs[frame] = spellID end
        StopGlow(frame)
    end
    wipe(activeGlows)

    -- Re-apply for frames whose proc is still active
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    for frame, spellID in pairs(procs) do
        if frame and frame:IsShown() then
            StartGlow(frame)
        end
    end
end

-- =====================================
-- DEBUG SLASH COMMAND
-- =====================================
SLASH_TOMOCDMPROCGLOW1 = "/tomoprocglow"
SlashCmdList["TOMOCDMPROCGLOW"] = function(msg)
    if msg == "test" then
        -- Test: apply glow to first visible Essential icon
        local viewer = _G["EssentialCooldownViewer"]
        if viewer then
            local children = { viewer:GetChildren() }
            for _, child in ipairs(children) do
                if child:IsShown() then
                    StartGlow(child)
                    print("|cff00ccffTomoMod ProcGlow:|r Test glow applied")
                    return
                end
            end
        end
        print("|cff00ccffTomoMod ProcGlow:|r No visible icons found")
    elseif msg == "stop" then
        for frame in pairs(activeGlows) do StopGlow(frame) end
        wipe(activeSpells)
        print("|cff00ccffTomoMod ProcGlow:|r All glows stopped")
    elseif msg == "status" then
        local count = 0
        for _ in pairs(activeGlows) do count = count + 1 end
        local spellCount = 0
        for _ in pairs(activeSpells) do spellCount = spellCount + 1 end
        print("|cff00ccffTomoMod ProcGlow:|r")
        print("  Active glows: " .. count)
        print("  Tracked spells: " .. spellCount)
        print("  LCG loaded: " .. tostring(LCG ~= nil))
        print("  Initialized: " .. tostring(isInitialized))
    else
        print("|cff00ccffTomoMod ProcGlow:|r Commands: test, stop, status")
    end
end

-- Export
_G.TomoMod_CDMProcGlow = ProcGlow

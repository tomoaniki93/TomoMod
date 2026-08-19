-- =====================================================================
-- Core/OptionsLoader.lua
--
-- Config/ moved to the TomoMod_Options sub-addon (LoadOnDemand). It is 28
-- files and roughly 17 900 lines that most sessions never open.
--
-- Every existing call site guards on `if TomoMod_Config and ...`, so leaving
-- the global nil would make them all quietly do nothing -- clicking the
-- minimap button would simply not respond, with no error to explain why.
-- This file publishes a stand-in that loads the sub-addon on first use and
-- then forwards to the real implementation.
--
-- ConfigUI.lua does `TomoMod_Config = TomoMod_Config or {}`, so it extends
-- this table and overwrites each stub with the real function. The sentinel
-- below is how a stub tells whether that has happened: without it, forwarding
-- would call itself forever.
-- =====================================================================

TomoMod_Config = TomoMod_Config or {}
local C = TomoMod_Config

local ADDON = "TomoMod_Options"
local FORWARDED = { "Toggle", "Show", "Hide", "SwitchCategory", "InvalidatePanels" }

local stubs = {}          -- [name] = the stub function we installed
local loadAttempted = false
local loadFailed = false

local function Load()
    if loadFailed then return false end

    local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(ADDON)
    if loaded then return true end
    if loadAttempted then return false end
    loadAttempted = true

    local ok, reason
    if C_AddOns and C_AddOns.LoadAddOn then
        ok, reason = C_AddOns.LoadAddOn(ADDON)
    elseif LoadAddOn then
        ok, reason = LoadAddOn(ADDON)
    end

    if not ok then
        -- Disabled in the addon list, missing from the package, or out of
        -- memory. Say so once rather than failing silently on every click.
        loadFailed = true
        print("|cff2ed884TomoMod|r " ..
            (TomoMod_L and TomoMod_L["options_load_failed"] or
             "options panel unavailable") ..
            (reason and (" (" .. tostring(reason) .. ")") or ""))
        return false
    end
    return true
end

C.EnsureLoaded = Load

for _, name in ipairs(FORWARDED) do
    local stub
    stub = function(...)
        if not Load() then return end
        local real = C[name]
        -- Guard against the sub-addon loading without defining this entry:
        -- forwarding to ourselves would recurse until the stack gives out.
        if real == nil or real == stub or real == stubs[name] then return end
        return real(...)
    end
    stubs[name] = stub
    C[name] = stub
end

-- =====================================================================
-- FIRST-RUN INSTALLER BRIDGE
-- =====================================================================
-- Installer.lua lives in the LoadOnDemand TomoMod_Options addon, therefore it
-- cannot own PLAYER_LOGIN: on a fresh install that file is not loaded yet.
-- Keep the tiny bootstrap here in core and only load the full options addon
-- once the player is out of cinematics and combat.
local INSTALLER_RETRY_DELAY = 2
local INSTALLER_MAX_ATTEMPTS = 150
local installerGeneration = 0

local function InstallerBlocked()
    if _G.CinematicFrame and _G.CinematicFrame:IsShown() then return true end
    if _G.MovieFrame and _G.MovieFrame:IsShown() then return true end
    if type(_G.InCinematic) == "function" then
        local ok, active = pcall(_G.InCinematic)
        if ok and active then return true end
    end
    if InCombatLockdown() then return true end
    local ok, fighting = pcall(function()
        return UnitAffectingCombat("player") and true or false
    end)
    if ok and fighting then return true end
    return false
end

local function TryShowInstaller(attempt, generation)
    attempt = tonumber(attempt) or 1
    if generation ~= installerGeneration then return end
    if not TomoModDB then return end

    TomoModDB.installer = TomoModDB.installer or { completed = false, step = 1 }
    if TomoModDB.installer.completed then return end

    if InstallerBlocked() then
        if attempt < INSTALLER_MAX_ATTEMPTS then
            C_Timer.After(INSTALLER_RETRY_DELAY, function()
                TryShowInstaller(attempt + 1, generation)
            end)
        end
        return
    end

    if not Load() then return end
    if TomoMod_Installer and TomoMod_Installer.Show then
        TomoMod_Installer.Show()
    end
end

-- Manual and automatic entry points use the same guards. A manual request
-- supersedes any earlier pending retry so only one installer can appear.
function TomoMod_OpenInstaller(manual)
    installerGeneration = installerGeneration + 1
    local generation = installerGeneration

    if TomoModDB then
        TomoModDB.installer = TomoModDB.installer or { completed = false, step = 1 }
        if manual then
            local function TryManual(attempt)
                if generation ~= installerGeneration then return end
                if InstallerBlocked() then
                    if attempt < INSTALLER_MAX_ATTEMPTS then
                        C_Timer.After(INSTALLER_RETRY_DELAY, function() TryManual(attempt + 1) end)
                    end
                    return
                end
                if Load() and TomoMod_Installer and TomoMod_Installer.Show then
                    TomoMod_Installer.Show()
                end
            end
            TryManual(1)
            return
        end
    end

    TryShowInstaller(1, generation)
end

local installerBoot = CreateFrame("Frame")
installerBoot:RegisterEvent("PLAYER_LOGIN")
installerBoot:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    C_Timer.After(1.5, function()
        TomoMod_OpenInstaller(false)
    end)
end)


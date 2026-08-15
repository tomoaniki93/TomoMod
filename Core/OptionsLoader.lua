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

-- ---------------------------------------------------------------------
-- Guard.lua -- stand down when the standalone addon is installed
--
-- TomoDamageMeter ships both ways: as its own CurseForge project and
-- bundled here. A player can therefore have both, and two copies fighting
-- over the same windows, CVars and combat sessions is worse than either
-- one alone.
--
-- The embedded copy is the one that yields. That is deliberate: a player
-- who installed the standalone chose it explicitly, and older standalone
-- versions already in the wild carry no guard of their own, so they
-- cannot be asked to stand down. Deferring here is the only rule that
-- works without shipping a matching update first.
--
-- Loaded before every other DamageMeter file, so the flag is set by the
-- time any of them registers an event.
-- ---------------------------------------------------------------------

local ADDON_NAME, TomoMod = ...

-- The module's own corner of TomoMod's shared namespace. Created here
-- because Guard.lua is the first DamageMeter file the XML loads, so every
-- other file can simply take it.
TomoMod.DM = TomoMod.DM or {}
local ns = TomoMod.DM

local function StandaloneLoaded()
    local api = C_AddOns
    if not api then return false end

    -- Loaded is the reliable signal, but at this point in TomoMod's own
    -- load the other addon may not have run yet. Enabled-and-present is
    -- the question that actually matters.
    if api.IsAddOnLoaded and api.IsAddOnLoaded("TomoDamageMeter") then
        return true
    end
    if api.GetAddOnEnableState then
        local ok, state = pcall(api.GetAddOnEnableState, "TomoDamageMeter",
            UnitName and UnitName("player") or nil)
        -- 0 disabled, 1 enabled for some characters, 2 enabled for all.
        if ok and type(state) == "number" and state > 0 then return true end
    end
    return false
end

ns.embedded = true
ns.disabled = StandaloneLoaded()

-- Every DamageMeter entry point calls this before doing anything.
function ns.Blocked()
    return ns.disabled == true
end

if ns.disabled then
    local shown = false
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function(self)
        self:UnregisterAllEvents()
        if shown then return end
        shown = true
        print("|cff2ed884TomoMod|r : le damage meter integre est en veille, "
            .. "l'addon TomoDamageMeter autonome est installe.")
    end)
end

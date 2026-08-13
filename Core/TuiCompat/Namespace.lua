-- =====================================================================
-- Core/TuiCompat/Namespace.lua -- TUI compatibility layer, lot P1
--
-- Modules ported from Tui expect a shared table conventionally received as
-- the second vararg of an addon chunk (`local ADDON_NAME, ns = ...`) and
-- reached as `ns.<something>`. TomoMod does not use that convention, so this
-- layer builds one table and hands it to the ported files explicitly.
--
-- Nothing in here is TomoMod behaviour: it exists so a file lifted from Tui
-- can be dropped in unchanged, which is the whole point of the port. When a
-- ported module is later rewritten to TomoMod conventions, its entry here
-- can go away.
-- =====================================================================

TomoMod_TuiNS = TomoMod_TuiNS or {}
local ns = TomoMod_TuiNS

ns.ADDON_NAME = "TomoMod"
ns.Addon      = ns.Addon or {}

-- Locale bridge. Ported files read ns.L["key"]; TomoMod's own table already
-- returns the raw key for anything undefined, so a missing translation shows
-- the key rather than erroring.
ns.L = setmetatable({}, {
    __index = function(_, key)
        local L = TomoMod_L
        if L then return L[key] end
        return key
    end,
})

-- Perf probes are a Tui debugging facility. Ported code appends to these and
-- never reads them back, so empty tables are a faithful no-op.
ns._memprobes      = ns._memprobes or {}
ns.TUI_PerfRegistry = ns.TUI_PerfRegistry or {
    Register = function() end,
    Unregister = function() end,
}

ns._inInitSafeWindow = false

-- Shared media, already vendored by TomoMod.
ns.LSM = _G.LibStub and _G.LibStub("LibSharedMedia-3.0", true) or nil

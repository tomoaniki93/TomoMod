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
-- The ported module reaches the addon object through Helpers.GetCore(), which
-- gives it two things: db.profile (13 call sites) and an AceEvent-style
-- RegisterEvent/UnregisterEvent pair used to defer work out of combat.
--
-- db.profile was already handled -- GetCore() installed it lazily. It is set
-- up here instead so the object is complete from the moment the namespace
-- exists, which keeps the two halves in one place.
--
-- RegisterEvent was not, and that was a real bug: actionbars_builder.lua sets
-- _microDeferPending = true and THEN calls Addon:RegisterEvent. On a plain
-- table that call throws, SafeCall swallows it, and the flag stays true
-- forever -- so the deferred micro-button reparent never replayed after
-- combat, silently and with nothing in the error log.
ns.Addon = ns.Addon or {}

-- db.profile must stay live rather than be captured once: TomoMod's profile
-- engine swaps module tables in place under TomoModDB, so a snapshot taken at
-- load would go stale on the first profile switch.
if not ns.Addon.db then
    ns.Addon.db = setmetatable({}, {
        __index = function(_, key)
            if key == "profile" then return TomoModDB end
            return nil
        end,
    })
end

if not ns.Addon.RegisterEvent then
    local eventFrame = CreateFrame("Frame")
    local handlers = {}

    eventFrame:SetScript("OnEvent", function(_, event, ...)
        local fn = handlers[event]
        if fn then fn(event, ...) end
    end)

    function ns.Addon:RegisterEvent(event, handler)
        if type(event) ~= "string" then return end
        handlers[event] = type(handler) == "function" and handler or nil
        eventFrame:RegisterEvent(event)
    end

    function ns.Addon:UnregisterEvent(event)
        if type(event) ~= "string" then return end
        handlers[event] = nil
        eventFrame:UnregisterEvent(event)
    end
end

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

-- Split perf probes are a Tui debugging switch; the ported code only reads it.
ns.TUI_ENABLE_ACTIONBAR_SPLIT_PERF_PROBES = false

-- Gate for the ported action bar module, which self-initialises on
-- ADDON_LOADED. The full Tui file set landed in lot P4, so it is live.
ns.TUI_ACTIONBARS_READY = true

-- Shared media, already vendored by TomoMod.
ns.LSM = _G.LibStub and _G.LibStub("LibSharedMedia-3.0", true) or nil

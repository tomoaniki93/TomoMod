-- =====================================================================
-- Core/TuiCompat/Helpers.lua
--
-- The four Helpers entry points the ported action bar code actually uses,
-- written against TomoMod rather than copied from Tui (TUI/core/utils.lua is
-- 1663 lines for these four).
--
-- DB SCHEMA: we adopt Tui's shape. TomoMod's profile engine swaps module
-- tables in place under TomoModDB, so the "active profile" at runtime IS
-- TomoModDB; CreateDBGetter("actionBars") therefore hands back
-- TomoModDB.actionBars and the ported code finds db.global.* and db.bars.*
-- exactly where it expects them. Defaults live in Core/Database.lua under
-- TomoMod_Defaults.actionBars (lifted from Tui in lot P5) so the profile engine
-- and the reset paths see them like any other module.
-- =====================================================================

local ns = TomoMod_TuiNS
local Helpers = ns.Helpers or {}
ns.Helpers = Helpers

Helpers.AssetPath = "Interface\\AddOns\\TomoMod\\Assets\\"

function Helpers.GetProfile()
    if not TomoModDB then return nil end
    return TomoModDB
end

function Helpers.CreateDBGetter(moduleKey)
    return function()
        local profile = Helpers.GetProfile()
        if not profile then return nil end
        local db = profile[moduleKey]
        if type(db) ~= "table" then
            -- Should not happen once TomoMod_InitDatabase has run, but a
            -- module reset or a hand-edited SavedVariables can get here. Seed
            -- from the real defaults rather than an empty table: empty means
            -- buttons with no size, no font and no colour, which looks like a
            -- rendering bug rather than a missing database.
            local defaults = TomoMod_Defaults and TomoMod_Defaults[moduleKey]
            db = (defaults and CopyTable) and CopyTable(defaults) or {}
            profile[moduleKey] = db
        end
        if type(db.global) ~= "table" then db.global = {} end
        if type(db.bars) ~= "table" then db.bars = {} end
        if type(db.fade) ~= "table" then db.fade = {} end
        return db
    end
end

-- Ported code calls this with a font object and a media name; it must never
-- leave a fontstring unrendered, hence the fallback to TomoMod's own face.
local FALLBACK_FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

function Helpers.ApplyFontWithFallback(fontString, mediaName, size, flags)
    if not fontString or not fontString.SetFont then return end
    local path
    if ns.LSM and mediaName then
        local ok, res = pcall(ns.LSM.Fetch, ns.LSM, "font", mediaName, true)
        if ok and type(res) == "string" then path = res end
    end
    path = path or FALLBACK_FONT
    size = tonumber(size) or 12
    if not pcall(fontString.SetFont, fontString, path, size, flags) then
        pcall(fontString.SetFont, fontString, FALLBACK_FONT, size, flags)
    end
end

function Helpers.IsEditModeShown()
    -- ActionBarsOwned lives in the sandboxed Tui env, reachable here via ns (TomoMod_TuiNS)
    local ABO = ns.ActionBarsOwned
    if ABO and ABO.editModeActive then
        return true
    end

    local f = _G.EditModeManagerFrame
    if not f or not f.IsShown then return false end
    local ok, shown = pcall(f.IsShown, f)
    return (ok and shown) and true or false
end

-- Consumed by IconSkin when it tints a button border.
function Helpers.GetSkinBorderColor()
    local U = TomoMod_Utils
    local c = U and U.BRAND
    if type(c) == "table" then
        return c[1] or 0, c[2] or 0, c[3] or 0, 1
    end
    return 0, 0, 0, 1
end

-- Ported verbatim from Tui (TUI/core/utils.lua): the action bar core calls
-- these five and nothing else from that file.

function Helpers.CreateStateTable()
    local tbl = setmetatable({}, { __mode = "k" })
    local function get(key)
        local s = tbl[key]
        if not s then s = {}; tbl[key] = s end
        return s
    end
    return tbl, get
end

-- ns.Addon is fully assembled in Namespace.lua (db.profile + the event API),
-- so this is just the accessor the ported code expects.
function Helpers.GetCore()
    return ns.Addon
end

function Helpers.HasSecretValue(...)
    if not issecretvalue then return false end
    for i = 1, select("#", ...) do
        if issecretvalue(select(i, ...)) then
            return true
        end
    end
    return false
end

function Helpers.IsSecretValue(value)
    return issecretvalue and issecretvalue(value) or false
end

function Helpers.SafeToNumber(value, fallback)
    if issecretvalue and issecretvalue(value) then
        return fallback or 0
    end
    local num = tonumber(value)
    if num then
        return num
    end
    return fallback or 0
end

-- Added for lot P3 (cooldowns / usability / glow / flyout / extra buttons).
-- Ported verbatim from Tui, with the fail-closed secret policy intact: a value
-- we cannot prove safe is treated as restricted rather than assumed benign.

function Helpers.FrameMutationRestricted(frame)
    if not frame then return false end
    if frame.IsProtected then
        local ok, answer = pcall(frame.IsProtected, frame)
        if not ok then return true end
        if issecretvalue and issecretvalue(answer) then return true end
        if answer then return true end
    end
    if frame.IsAnchoringRestricted then
        local ok, answer = pcall(frame.IsAnchoringRestricted, frame)
        if not ok then return true end
        if issecretvalue and issecretvalue(answer) then return true end
        if answer then return true end
    end
    return false
end

function Helpers.SafeNumberOrNil(value)
    if issecretvalue and issecretvalue(value) then
        return nil
    end
    return tonumber(value)
end

function Helpers.SafeValue(value, fallback)
    if issecretvalue and issecretvalue(value) then
        return fallback
    end
    return value
end

-- Tui resolves this from its own skin colour settings; TomoMod has no
-- equivalent yet, so it answers with the brand accent until lot P5 wires the
-- real setting.
function Helpers.GetSkinAccentColor()
    return Helpers.GetSkinBorderColor()
end

-- Added for lot P4 (skinning / mouseover / editmode). Ported verbatim from
-- Tui, combat queue included: Hide() on a protected frame is blocked in
-- combat, so the call is deferred to PLAYER_REGEN_ENABLED rather than dropped.
local _deferredHideHooked = setmetatable({}, { __mode = "k" })
local _combatHideQueue = {}
local _combatHideFrame

local function FlushCombatHideQueue()
    if InCombatLockdown() then return end
    for frame, shouldClearAlpha in pairs(_combatHideQueue) do
        if not (frame.IsForbidden and frame:IsForbidden()) then
            ns.SafeCallMethod("best-effort-style", frame, "Hide")
            if shouldClearAlpha and frame.SetAlpha then frame:SetAlpha(0) end
        end
    end
    wipe(_combatHideQueue)
    _combatHideFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

local function QueueCombatHide(frame, clearAlpha)
    _combatHideQueue[frame] = clearAlpha or false
    if not _combatHideFrame then
        _combatHideFrame = CreateFrame("Frame")
        _combatHideFrame:SetScript("OnEvent", FlushCombatHideQueue)
    end
    _combatHideFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function Helpers.DeferredHideOnShow(frame, opts)
    if not frame or not frame.Show then return end
    if _deferredHideHooked[frame] then return end
    _deferredHideHooked[frame] = true
    local clearAlpha = opts and opts.clearAlpha or false
    local combatCheck = not opts or opts.combatCheck ~= false
    hooksecurefunc(frame, "Show", function(self)
        C_Timer.After(0, function()
            if self.IsForbidden and self:IsForbidden() then return end
            if InCombatLockdown() then
                if combatCheck then return end
                if self.SetAlpha then self:SetAlpha(0) end
                QueueCombatHide(self, clearAlpha)
                return
            end
            ns.SafeCallMethod("best-effort-style", self, "Hide")
            if clearAlpha and self.SetAlpha then self:SetAlpha(0) end
        end)
    end)
end

-- Keybind text formatting. Ported code calls ns.FormatKeybind(key).
local ABBREV = {
    { "MOUSEWHEELUP", "mwu" }, { "MOUSEWHEELDOWN", "mwd" },
    { "NUMPAD", "n" }, { "PAGEUP", "pu" }, { "PAGEDOWN", "pd" },
    { "BACKSPACE", "bs" }, { "CAPSLOCK", "cl" }, { "ESCAPE", "esc" },
    { "INSERT", "ins" }, { "DELETE", "del" },
    { "MULTIPLY", "*" }, { "SUBTRACT", "-" }, { "DIVIDE", "/" }, { "DECIMAL", "." },
    { "UPARROW", "up" }, { "DOWNARROW", "dn" }, { "LEFTARROW", "lt" }, { "RIGHTARROW", "rt" },
    { "SPACE", "sp" }, { "BUTTON", "m" }, { "HOME", "hm" }, { "ADD", "+" }, { "END", "en" },
    { "ALT%-", "a" }, { "CTRL%-", "c" }, { "SHIFT%-", "s" }, { "META%-", "M" },
}

function ns.FormatKeybind(key)
    if type(key) ~= "string" or key == "" then return key end
    local out = key
    for i = 1, #ABBREV do
        out = out:gsub(ABBREV[i][1], ABBREV[i][2])
    end
    return out
end

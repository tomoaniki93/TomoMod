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
-- exactly where it expects them. Migration of the old TomoMod keys lands in
-- lot P5.
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
            db = {}
            profile[moduleKey] = db
        end
        if type(db.global) ~= "table" then db.global = {} end
        if type(db.bars) ~= "table" then db.bars = {} end
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

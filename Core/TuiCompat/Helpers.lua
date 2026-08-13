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

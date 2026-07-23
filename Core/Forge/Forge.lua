-- =====================================================================
-- TomoMod Forge -- internal shared library (L1)
-- Common machinery for the deep-editing stack (CooldownForge, Cooldown
-- Studio, and the upcoming UnitFrames studio):
--   Forge.Util : Px (pixel-perfect), ClassColor, Fold (accent folding),
--                CopyDeep
--   Forge.IO   : versioned share-string codecs      (ForgeIO.lua)
--   Forge.Edit : addon-wide edit session -- grid, snap, overlays,
--                movable & provider registration    (ForgeEdit.lua)
-- Internal library: a single global (TomoMod_Forge), released with the
-- addon. No LibStub on purpose -- nothing external consumes it yet; the
-- day TomoHDV/TomoPorter want it, a LibStub shim can wrap this table.
-- =====================================================================

local Forge = TomoMod_Forge or {}
TomoMod_Forge = Forge

Forge.BRAND     = (TomoMod_Utils and TomoMod_Utils.BRAND) or { 0.18, 0.85, 0.52 }
Forge.FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
Forge.FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

Forge.Util = Forge.Util or {}
local U = Forge.Util

-- ---------------------------------------------------------------------
-- Pixel-perfect: n physical pixels expressed in UI units for a frame
-- living under UIParent.
-- ---------------------------------------------------------------------
function U.Px(n)
    local _, ph = GetPhysicalScreenSize()
    if not ph or ph == 0 then return n or 1 end
    local scale = UIParent and UIParent:GetEffectiveScale() or 1
    if scale <= 0 then scale = 1 end
    local v = (n or 1) * (768 / ph) / scale
    if v < 0.5 then v = 0.5 end
    return v
end

-- ---------------------------------------------------------------------
-- Player class color (RAID_CLASS_COLORS), brand green as fallback.
-- Resolved at call time, never meant to be stored.
-- ---------------------------------------------------------------------
function U.ClassColor()
    local _, class = UnitClass("player")
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c then return c.r, c.g, c.b end
    local b = Forge.BRAND
    return b[1], b[2], b[3]
end

-- ---------------------------------------------------------------------
-- Accent folding for search/filter matching ("echelle" matches
-- "Échelle"). Byte-level gsub on UTF-8 sequences -- Lua 5.1 safe.
-- ---------------------------------------------------------------------
local FOLD = {
    ["à"] = "a", ["â"] = "a", ["ä"] = "a", ["é"] = "e", ["è"] = "e",
    ["ê"] = "e", ["ë"] = "e", ["î"] = "i", ["ï"] = "i", ["ô"] = "o",
    ["ö"] = "o", ["ù"] = "u", ["û"] = "u", ["ü"] = "u", ["ç"] = "c",
    ["œ"] = "oe",
    ["À"] = "a", ["Â"] = "a", ["Ä"] = "a", ["É"] = "e", ["È"] = "e",
    ["Ê"] = "e", ["Ë"] = "e", ["Î"] = "i", ["Ï"] = "i", ["Ô"] = "o",
    ["Ö"] = "o", ["Ù"] = "u", ["Û"] = "u", ["Ü"] = "u", ["Ç"] = "c",
    ["Œ"] = "oe",
}

function U.Fold(s)
    s = tostring(s or ""):lower()
    for k, v in pairs(FOLD) do
        s = s:gsub(k, v)
    end
    return s
end

-- ---------------------------------------------------------------------
-- Deep copy (tables only; no metatable/userdata handling by design).
-- ---------------------------------------------------------------------
function U.CopyDeep(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do
        out[k] = (type(v) == "table") and U.CopyDeep(v) or v
    end
    return out
end

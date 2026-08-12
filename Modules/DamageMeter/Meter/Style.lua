local ADDON_NAME, TomoMod = ...

-- [MERGE] Standalone, `ns` was this addon's own private table. Embedded, the
-- vararg hands over TomoMod's, which every other file in the suite shares --
-- so 157 generic names (db, L, FONT, BG, ACCENT, Refresh, windows, inCombat)
-- would sit in the same table as everything TomoMod ever adds. Nothing
-- collides today, but the first core file that reaches for `ns.db` would
-- find this module's and neither would know.
--
-- One sub-table keeps the module's world to itself, and leaves every `ns.X`
-- below untouched.
local ns = TomoMod.DM

----------------------------------------------------------------------
-- Style: Colors, Textures, Layout Constants
----------------------------------------------------------------------

ns.FLAT = "Interface\\BUTTONS\\WHITE8X8"

-- [MERGE] Bundled inside TomoMod; the standalone addon keeps its own copy.
-- [MERGE] Textures live with the rest of TomoMod's art, not beside
-- the module, so the suite keeps one asset root.
local ADDON_TEX  = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Meter\\"

-- Icon textures (32x32 white TGA, colorable via SetVertexColor)
ns.TEX_GEAR      = ADDON_TEX .. "gear"
ns.TEX_CLOSE     = ADDON_TEX .. "close"
ns.TEX_RESET     = ADDON_TEX .. "reset"
ns.TEX_REPORT    = ADDON_TEX .. "report"
ns.TEX_LOCK      = ADDON_TEX .. "lock"
ns.TEX_LOCK_OPEN = ADDON_TEX .. "lock-open"
ns.TEX_CHEVRON   = ADDON_TEX .. "chevron"
ns.TEX_DETAILS   = ADDON_TEX .. "details"
ns.TEX_TARGET    = ADDON_TEX .. "target"

-- Tomo palette (dark blue, TomoMythic style)
ns.BG              = { 0.00, 0.00, 0.00, 0.80 }
ns.HEADER_BG       = { 0.04, 0.08, 0.16, 1.00 }
ns.BORDER_COLOR     = { 0.25, 0.25, 0.30, 0.70 }
ns.DEFAULT_ACCENT   = { 0.33, 0.70, 0.00 }       -- apple green
ns.ACCENT           = { 0.33, 0.70, 0.00, 1.00 }

-- Text
ns.TEXT_PRIMARY     = { 1.00, 1.00, 1.00 }
ns.TEXT_SECONDARY   = { 0.55, 0.55, 0.55 }
ns.TEXT_LABEL       = { 0.75, 0.75, 0.78 }
ns.TEXT_MUTED       = { 0.40, 0.40, 0.43 }

----------------------------------------------------------------------
-- Tint registry
----------------------------------------------------------------------
-- Applies a role colour to a FontString and remembers it, so a skin change
-- can re-tint text that was coloured once at creation.
--
-- Without this, only the bar rows followed a skin change (they are recoloured
-- on every render); every header label, column title and settings label kept
-- the colour it was born with. That was invisible while every preset was dark
-- and fatal the moment a light preset existed.
--
-- Keyed by the FontString itself, so the hot render path can call it freely
-- without the registry growing.

local ROLE_TABLES = {
    primary   = "TEXT_PRIMARY",
    secondary = "TEXT_SECONDARY",
    label     = "TEXT_LABEL",
    muted     = "TEXT_MUTED",
    accent    = "ACCENT",
}

local tinted = {}

function ns.Tint(fs, role)
    if not fs then return fs end
    local tbl = ns[ROLE_TABLES[role] or "TEXT_PRIMARY"]
    tinted[fs] = role
    fs:SetTextColor(tbl[1], tbl[2], tbl[3])
    return fs
end

-- Re-apply every registered role colour from the live Style tables.
function ns.RetintAll()
    for fs, role in pairs(tinted) do
        local tbl = ns[ROLE_TABLES[role] or "TEXT_PRIMARY"]
        fs:SetTextColor(tbl[1], tbl[2], tbl[3])
    end
end

----------------------------------------------------------------------
-- Surface registry
----------------------------------------------------------------------
-- Same idea as ns.Tint, for the secondary surfaces: the action strip, tab
-- backgrounds, column headers, search boxes. Every one of them was a
-- hard-coded dark navy, so they stayed dark under a light skin and left a
-- slab of the old theme sitting in the middle of the new one.
--
-- They all derive from HEADER_BG, which is the skin's own secondary surface.

local surfaces = {}

function ns.Surface(tex, alpha)
    if not tex then return tex end
    alpha = alpha or ns.HEADER_BG[4] or 1
    surfaces[tex] = alpha
    tex:SetVertexColor(ns.HEADER_BG[1], ns.HEADER_BG[2], ns.HEADER_BG[3], alpha)
    return tex
end

function ns.ResurfaceAll()
    for tex, alpha in pairs(surfaces) do
        tex:SetVertexColor(ns.HEADER_BG[1], ns.HEADER_BG[2], ns.HEADER_BG[3], alpha)
    end
end

----------------------------------------------------------------------
-- Contrast helpers
----------------------------------------------------------------------

local function Luminance(r, g, b)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

--- Accent usable on the settings panel, which stays dark whatever the skin.
--- A preset built for a light background picks a dark accent — Parchment's
--- rust is the obvious case — and that accent is unreadable on a dark panel.
--- Lift it until it clears the floor, keeping its hue.
function ns.PanelAccent()
    local r, g, b = ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3]
    local lum = Luminance(r, g, b)
    local FLOOR = 0.42
    if lum >= FLOOR then return r, g, b end
    local k = FLOOR / math.max(lum, 0.02)
    return math.min(r * k, 1), math.min(g * k, 1), math.min(b * k, 1)
end

--- Class colour normalised for the active skin.
---
--- RAID_CLASS_COLORS is tuned for a dark UI and its luminances are all over the
--- place: Priest is pure white, Death Knight is near-black crimson. On a light
--- skin that breaks twice over. A flat darkening factor does not fix it either,
--- because it moves every colour by the same ratio and leaves the spread intact.
---
--- What actually matters is that the bar sits in a luminance band where two
--- things hold at once: it stays distinguishable from the background, and the
--- row text stays readable *on top of it*. There is no single text colour that
--- works over both a light background and a dark bar, so the bar is what has to
--- move. Each class colour is pushed onto a target luminance — toward white when
--- too dark, toward black when too bright — which preserves the hue and leaves
--- every class equally legible.
---
--- Dark presets leave CLASS_LUM nil and are untouched.
function ns.ClassColor(classFile)
    local cc = classFile and RAID_CLASS_COLORS[classFile]
    if not cc then return 0.6, 0.6, 0.6 end

    local target = ns.CLASS_LUM
    if not target then return cc.r, cc.g, cc.b end

    local r, g, b = cc.r, cc.g, cc.b
    local lum = Luminance(r, g, b)
    if math.abs(lum - target) < 0.02 then return r, g, b end

    if lum < target then
        -- Blend toward white. Luminance is linear, so the exact mix is known.
        local t = (target - lum) / (1 - lum)
        return r + (1 - r) * t, g + (1 - g) * t, b + (1 - b) * t
    end
    -- Blend toward black: a plain scale lands exactly on target.
    local k = target / lum
    return r * k, g * k, b * k
end

ns.CLASS_LUM = nil


-- Interactive
ns.HOVER_BG         = { 0.10, 0.22, 0.44, 0.40 }
ns.HEADER_HOVER_BG  = { 0.10, 0.22, 0.44, 0.40 }
ns.BAR_ALPHA        = 0.5
ns.ICON_ALPHA       = 0.7

-- Category colors (header label tint)
ns.CAT_DAMAGE       = { 1.00, 0.30, 0.20 }
ns.CAT_HEALING      = { 0.55, 0.90, 0.20 }
ns.CAT_ACTIONS      = { 0.50, 0.72, 1.00 }

-- Scrollbar
ns.SCROLLBAR_TRACK  = { 0.04, 0.08, 0.14, 0.60 }
ns.SCROLLBAR_THUMB  = { 0.15, 0.32, 0.60, 0.70 }

-- Layout
ns.HEADER_HEIGHT    = 20
ns.SUBHEADER_HEIGHT = 16
ns.HEADER_TOTAL     = 20
ns.HEADER_COMBINED  = 20 + 16 + 1  -- header + subheader + separator
ns.HEADER_PAD_TOP   = 0
ns.HEADER_PAD_Y     = 0
ns.HEADER_PAD_X     = 6
ns.TEXT_PAD          = 6
ns.BAR_HEIGHT       = 21
ns.BAR_SPACING      = 1
ns.BORDER_WIDTH     = 1
ns.CONTENT_INSET    = 3
ns.SCROLLBAR_WIDTH  = 6
ns.STRIP_WIDTH      = 18

-- Font defaults
ns.FONT_SIZE        = 12
ns.BAR_FONT_SIZE    = 10

-- Default font (uses game built-in; can be overridden in DB)
ns.FONT = "Fonts\\FRIZQT__.TTF"
ns.HEADER_FONT = ns.FONT

----------------------------------------------------------------------
-- Font Registry (built-in game fonts)
----------------------------------------------------------------------

ns.FONT_LIST = {
    { path = "Fonts\\FRIZQT__.TTF",     key = "FONT_FRIZ" },
    { path = "Fonts\\ARIALN.TTF",       key = "FONT_ARIAL" },
    { path = "Fonts\\2002.TTF",         key = "FONT_2002" },
    { path = "Fonts\\MORPHEUS.TTF",     key = "FONT_MORPHEUS" },
    { path = "Fonts\\SKURRI.TTF",       key = "FONT_SKURRI" },
}

----------------------------------------------------------------------
-- Font accessor (DB override)
----------------------------------------------------------------------

function ns.GetFont()
    return ns.db and ns.db.fontPath or ns.FONT
end

function ns.GetFontSize()
    return ns.db and ns.db.fontSize or ns.BAR_FONT_SIZE
end

function ns.GetBarHeight()
    return ns.db and ns.db.barHeight or ns.BAR_HEIGHT
end

function ns.GetFontNudge()
    return ns.db and ns.db.fontNudge or 0
end
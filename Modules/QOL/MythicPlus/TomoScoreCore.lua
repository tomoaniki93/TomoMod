-- =====================================================================
-- TomoScoreCore.lua — TomoScore integrated into TomoMod (MythicPlus)
-- Addon table, color palette, utilities.
-- =====================================================================

local L = TomoMod_L

TomoMod_TomoScore = TomoMod_TomoScore or {}
local TS = TomoMod_TomoScore

-- ── Color palette ─────────────────────────────────────────────────────────
-- Derived from the shared TomoMod theme instead of the standalone dark/teal
-- set this file used to carry. The scoreboard was the only surface in the
-- addon with its own palette -- a cyan accent against the suite's green, and a
-- blue-tinted background against a neutral one -- so it read as a different
-- product. Config\Widgets.lua loads at TOC line 49 and QOL.xml at 79, so the
-- theme is always available here; the literals remain as a fallback rather
-- than a second source of truth.
-- Theme lives in the TomoMod_Options load-on-demand sub-addon. The previous
-- capture ran at login, before that addon exists, so it always resolved to
-- the empty fallback and every colour below silently came out nil. The proxy
-- resolves per access instead, and still falls back once loaded if a key is
-- genuinely absent.
local T = setmetatable({}, { __index = function(_, key)
    local theme = TomoMod_Widgets and TomoMod_Widgets.Theme
    return theme and theme[key] or nil
end })

local function tint(themeColor, fallback, alpha)
    local c = themeColor or fallback
    return { c[1], c[2], c[3], alpha or c[4] or 1 }
end

TS.C = {
    BG            = tint(T.bg,          { 0.07,  0.07,  0.09  }, 0.94),
    BG_HEADER     = tint(T.bgMid,       { 0.09,  0.09,  0.115 }, 1.00),
    BG_ROW_ODD    = tint(T.bgLight,     { 0.11,  0.11,  0.14  }, 0.55),
    BG_ROW_EVEN   = tint(T.bgDark,      { 0.045, 0.045, 0.060 }, 0.55),
    ACCENT        = tint(T.accent,      { 0.18,  0.85,  0.52  }, 1.00),
    ACCENT_DIM    = tint(T.accentDark,  { 0.11,  0.54,  0.33  }, 0.60),
    BORDER        = tint(T.border,      { 0.18,  0.18,  0.22  }, 0.85),
    -- Historic names said TEAL; the colour is the brand accent now, so the
    -- names follow rather than lying about it.
    BORDER_ACCENT = tint(T.accent,      { 0.18,  0.85,  0.52  }, 0.80),
    BAR_ACCENT    = tint(T.accent,      { 0.18,  0.85,  0.52  }, 0.80),
    BAR_TRACK     = tint(T.bgDark,      { 0.045, 0.045, 0.060 }, 1.00),
    -- Kept distinct from the accent: on a green-accented panel, "on time"
    -- must not be the same green as every border and header.
    BAR_GREEN     = { 0.33, 0.70, 0.00, 0.90 },
    BAR_RED       = tint(T.red,         { 0.88,  0.22,  0.22  }, 0.90),
    TEXT_WHITE    = tint(T.text,        { 0.88,  0.90,  0.89  }, 1.00),
    TEXT_GREY     = tint(T.textDim,     { 0.48,  0.48,  0.54  }, 1.00),
    TEXT_ACCENT   = tint(T.textHeader,  { 0.18,  0.85,  0.52  }, 1.00),
    TEXT_GREEN    = { 0.55, 0.90, 0.20, 1.00 },
    TEXT_RED      = tint(T.red,         { 0.88,  0.22,  0.22  }, 1.00),
    TEXT_YELLOW   = tint(T.yellow,      { 0.96,  0.80,  0.10  }, 1.00),
}

-- WoW class colors (fallback)
TS.CLASS_COLORS = {
    WARRIOR     = { 0.78, 0.61, 0.43 },
    PALADIN     = { 0.96, 0.55, 0.73 },
    HUNTER      = { 0.67, 0.83, 0.45 },
    ROGUE       = { 1.00, 0.96, 0.41 },
    PRIEST      = { 1.00, 1.00, 1.00 },
    DEATHKNIGHT = { 0.77, 0.12, 0.23 },
    SHAMAN      = { 0.00, 0.44, 0.87 },
    MAGE        = { 0.25, 0.78, 0.92 },
    WARLOCK     = { 0.53, 0.53, 0.93 },
    MONK        = { 0.00, 1.00, 0.60 },
    DRUID       = { 1.00, 0.49, 0.04 },
    DEMONHUNTER = { 0.64, 0.19, 0.79 },
    EVOKER      = { 0.20, 0.58, 0.50 },
}

-- ── Layout constants ──────────────────────────────────────────────────────────
TS.FRAME_W      = 360
TS.HEADER_H     = 44
TS.COL_HEADER_H = 20
TS.ROW_H        = 36
TS.GAP          = 2
TS.EDGE         = 1
TS.MAX_PLAYERS  = 40

-- ICON holds the role icon and the spec icon side by side: the spec says what
-- the player brought, the role says what they are doing with it, and a keystone
-- board read before pulling wants both.
TS.ROLE_ICON = 16
TS.COL = {
    ICON       = 48,
    NAME       = 120,
    RATING     = 52,
    KEY_LEVEL  = 36,
    KEY_NAME   = 90,
}

-- ── DB access ─────────────────────────────────────────────────────────────────
function TS:GetDB()
    return TomoModDB and TomoModDB.TomoScore
end

-- ── Font helper ───────────────────────────────────────────────────────────────
function TS:GetFont(size, flags)
    return "Fonts\\FRIZQT__.TTF", size or 12, flags or "OUTLINE"
end

-- ── Frame helpers ─────────────────────────────────────────────────────────────
function TS:MakeBG(parent, r, g, b, a)
    local t = parent:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints(parent)
    t:SetColorTexture(r, g, b, a)
    return t
end

function TS:MakeLineBorders(parent, r, g, b, a, size)
    size = size or 1
    local c = { r, g, b, a or 1 }
    local sides = {}
    for _, info in ipairs({
        { "TOPLEFT",    "TOPRIGHT",    "h", size },
        { "BOTTOMLEFT", "BOTTOMRIGHT", "h", size },
        { "TOPLEFT",    "BOTTOMLEFT",  "v", size },
        { "TOPRIGHT",   "BOTTOMRIGHT", "v", size },
    }) do
        local t = parent:CreateTexture(nil, "BORDER")
        t:SetColorTexture(unpack(c))
        t:SetPoint(info[1], parent, info[1])
        t:SetPoint(info[2], parent, info[2])
        if info[3] == "h" then t:SetHeight(info[4])
        else                    t:SetWidth(info[4]) end
        sides[#sides + 1] = t
    end
    return sides
end

function TS:MakeFS(parent, size, flags, anchor, relTo, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(self:GetFont(size, flags))
    fs:SetShadowColor(0, 0, 0, 0.9)
    fs:SetShadowOffset(1, -1)
    if anchor then
        fs:SetPoint(anchor, relTo or parent, anchor, x or 0, y or 0)
    end
    return fs
end

-- ── Number formatting ─────────────────────────────────────────────────────────
function TS:FormatNumber(n)
    if not n or n == 0 then return "0" end
    if n >= 1000000 then
        return string.format("%.2fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    else
        return tostring(math.floor(n))
    end
end

function TS:FormatTime(sec)
    if not sec or sec <= 0 then return "--:--" end
    sec = math.floor(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s)
    else          return string.format("%d:%02d", m, s) end
end

-- ── Class color helper ────────────────────────────────────────────────────────
function TS:GetClassColor(class)
    if not class then return 1, 1, 1 end
    local cc = RAID_CLASS_COLORS[class]
    if cc then return cc.r, cc.g, cc.b end
    local f = self.CLASS_COLORS[class]
    if f then return f[1], f[2], f[3] end
    return 1, 1, 1
end

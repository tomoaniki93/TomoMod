-- =====================================================================
-- TomoScoreCore.lua — TomoScore integrated into TomoMod (MythicPlus)
-- Addon table, color palette, utilities.
-- =====================================================================

local L = TomoMod_L

TomoMod_TomoScore = {}
local TS = TomoMod_TomoScore

-- ── Color palette (dark/teal theme) ───────────────────────────────────────
TS.C = {
    BG            = { 0.00, 0.00, 0.00, 0.88 },
    BG_HEADER     = { 0.04, 0.08, 0.16, 1.00 },
    BG_ROW_ODD    = { 0.06, 0.06, 0.08, 0.60 },
    BG_ROW_EVEN   = { 0.03, 0.03, 0.05, 0.60 },
    ACCENT        = { 0.10, 0.68, 0.72, 1.00 },
    ACCENT_DIM    = { 0.08, 0.45, 0.50, 0.60 },
    BORDER        = { 0.25, 0.25, 0.30, 0.70 },
    BORDER_TEAL   = { 0.12, 0.55, 0.60, 0.80 },
    BAR_TEAL      = { 0.10, 0.58, 0.62, 0.80 },
    BAR_TRACK     = { 0.04, 0.08, 0.14, 1.00 },
    BAR_GREEN     = { 0.33, 0.70, 0.00, 0.90 },
    BAR_RED       = { 0.85, 0.15, 0.10, 0.90 },
    TEXT_WHITE    = { 1.00, 1.00, 1.00, 1.00 },
    TEXT_GREY     = { 0.55, 0.55, 0.55, 1.00 },
    TEXT_TEAL     = { 0.30, 0.85, 0.90, 1.00 },
    TEXT_GREEN    = { 0.55, 0.90, 0.20, 1.00 },
    TEXT_RED      = { 1.00, 0.30, 0.20, 1.00 },
    TEXT_YELLOW   = { 1.00, 0.82, 0.10, 1.00 },
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
TS.FRAME_W      = 680
TS.HEADER_H     = 44
TS.COL_HEADER_H = 20
TS.ROW_H        = 36
TS.GAP          = 2
TS.EDGE         = 1
TS.MAX_PLAYERS  = 40

TS.COL = {
    ICON       = 28,
    NAME       = 120,
    RATING     = 52,
    KEY_LEVEL  = 36,
    KEY_NAME   = 100,
    DAMAGE     = 100,
    HEALING    = 100,
    INTERRUPTS = 68,
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

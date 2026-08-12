local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- Skins: named visual presets + LibSharedMedia-backed bar textures
----------------------------------------------------------------------

-- LibSharedMedia hookup (soft: the addon still works if LSM is ever absent)
local LSM = _G.LibStub and _G.LibStub("LibSharedMedia-3.0", true)
ns.LSM = LSM

local TEX_PATH = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Meter\\"

-- Bundled statusbar textures, registered into LSM so they show up in the
-- texture picker alongside any textures other addons have registered.
ns.TEX_FLAT   = "Tomo Flat"
ns.TEX_SMOOTH = "Tomo Smooth"
ns.TEX_GLOSSY = "Tomo Glossy"

if LSM then
    LSM:Register("statusbar", ns.TEX_FLAT,   ns.FLAT)
    LSM:Register("statusbar", ns.TEX_SMOOTH, TEX_PATH .. "statusbar-smooth")
    LSM:Register("statusbar", ns.TEX_GLOSSY, TEX_PATH .. "statusbar-glossy")
end

----------------------------------------------------------------------
-- Texture resolution
----------------------------------------------------------------------

-- Resolve the active bar texture (DB key -> file path). Falls back to the
-- flat WHITE8X8 fill when LSM is missing or the key is unknown.
function ns.GetBarTexture()
    local lsm = ns.LSM
    local key = ns.db and ns.db.barTexture
    if lsm and key then
        local path = lsm:Fetch("statusbar", key, true) -- noDefault = true
        if path then return path end
    end
    return ns.FLAT
end

-- Option list for the texture dropdown: every statusbar registered in LSM,
-- sorted alphabetically. Falls back to the bundled flat fill if LSM is gone.
function ns.GetTextureList()
    local out = {}
    local lsm = ns.LSM
    if lsm then
        for _, key in ipairs(lsm:List("statusbar")) do
            out[#out + 1] = { value = key, label = key }
        end
    end
    if #out == 0 then
        out[1] = { value = ns.TEX_FLAT, label = ns.TEX_FLAT }
    end
    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end

----------------------------------------------------------------------
-- Skin registry
----------------------------------------------------------------------
-- Each preset bundles the structural look (background, header, border,
-- accent, bar fill texture/alpha and row density). Picking a skin in the
-- options seeds the individual settings (accent, bg opacity, bar height,
-- texture) so the user can still fine-tune on top of any preset.

ns.SKINS = {
    {
        key = "DARK", name = "SKIN_DARK",
        bg          = { 0.00, 0.00, 0.00 }, bgAlpha = 0.80,
        headerBg    = { 0.04, 0.08, 0.16, 1.00 },
        headerHover = { 0.10, 0.22, 0.44, 0.40 },
        border      = { 0.25, 0.25, 0.30, 0.70 },
        scrollThumb = { 0.15, 0.32, 0.60 },
        accent      = { 0.33, 0.70, 0.00 },
        textPrimary = { 1.00, 1.00, 1.00 },
        textSecondary = { 0.55, 0.55, 0.55 },
        textMuted   = { 0.40, 0.40, 0.43 },
        textLabel   = { 0.75, 0.75, 0.78 },
        barTexture  = "Tomo Flat",
        barAlpha    = 0.50,
        barSpacing  = 1,
        barHeight   = 21,
    },
    {
        key = "NEON", name = "SKIN_NEON",
        bg          = { 0.012, 0.008, 0.024 }, bgAlpha = 0.92,
        headerBg    = { 0.051, 0.027, 0.086, 1.00 },
        headerHover = { 0.80, 0.267, 1.00, 0.16 },
        border      = { 0.80, 0.267, 1.00, 0.35 },
        scrollThumb = { 0.55, 0.20, 0.85 },
        accent      = { 0.80, 0.267, 1.00 },
        textPrimary = { 1.00, 1.00, 1.00 },
        textSecondary = { 0.55, 0.55, 0.55 },
        textMuted   = { 0.40, 0.40, 0.43 },
        textLabel   = { 0.75, 0.75, 0.78 },
        barTexture  = "Tomo Smooth",
        barAlpha    = 0.62,
        barSpacing  = 1,
        barHeight   = 21,
    },
    {
        key = "MINIMAL", name = "SKIN_MINIMAL",
        bg          = { 0.027, 0.027, 0.035 }, bgAlpha = 0.85,
        headerBg    = { 0.05, 0.05, 0.06, 0.55 },
        headerHover = { 1.00, 1.00, 1.00, 0.06 },
        border      = { 1.00, 1.00, 1.00, 0.05 },
        scrollThumb = { 0.45, 0.45, 0.50 },
        accent      = { 0.60, 0.63, 0.66 },
        textPrimary = { 1.00, 1.00, 1.00 },
        textSecondary = { 0.55, 0.55, 0.55 },
        textMuted   = { 0.40, 0.40, 0.43 },
        textLabel   = { 0.75, 0.75, 0.78 },
        barTexture  = "Tomo Flat",
        barAlpha    = 0.45,
        barSpacing  = 0,
        barHeight   = 16,
    },
    {
        key = "GLOSSY", name = "SKIN_GLOSSY",
        bg          = { 0.04, 0.04, 0.06 }, bgAlpha = 0.90,
        headerBg    = { 0.09, 0.09, 0.12, 1.00 },
        headerHover = { 0.91, 0.70, 0.23, 0.14 },
        border      = { 0.49, 0.49, 0.54, 0.55 },
        scrollThumb = { 0.55, 0.45, 0.20 },
        accent      = { 0.91, 0.70, 0.23 },
        textPrimary = { 1.00, 1.00, 1.00 },
        textSecondary = { 0.55, 0.55, 0.55 },
        textMuted   = { 0.40, 0.40, 0.43 },
        textLabel   = { 0.75, 0.75, 0.78 },
        barTexture  = "Tomo Glossy",
        barAlpha    = 0.90,
        barSpacing  = 1,
        barHeight   = 21,
    },
    {
        key = "EMBER", name = "SKIN_EMBER",
        bg          = { 0.055, 0.031, 0.024 }, bgAlpha = 0.88,
        headerBg    = { 0.133, 0.063, 0.035, 1.00 },
        headerHover = { 0.95, 0.45, 0.15, 0.16 },
        border      = { 0.95, 0.45, 0.15, 0.30 },
        scrollThumb = { 0.70, 0.32, 0.10 },
        accent      = { 0.95, 0.45, 0.15 },
        textPrimary = { 1.00, 1.00, 1.00 },
        textSecondary = { 0.65, 0.56, 0.51 },
        textMuted   = { 0.48, 0.40, 0.36 },
        textLabel   = { 0.78, 0.72, 0.68 },
        barTexture  = "Tomo Glossy",
        barAlpha    = 0.78,
        barSpacing  = 1,
        barHeight   = 21,
    },
    {
        key = "FROST", name = "SKIN_FROST",
        bg          = { 0.016, 0.043, 0.067 }, bgAlpha = 0.86,
        headerBg    = { 0.035, 0.086, 0.122, 1.00 },
        headerHover = { 0.40, 0.80, 0.95, 0.16 },
        border      = { 0.40, 0.80, 0.95, 0.30 },
        scrollThumb = { 0.25, 0.55, 0.72 },
        accent      = { 0.40, 0.80, 0.95 },
        textPrimary = { 1.00, 1.00, 1.00 },
        textSecondary = { 0.60, 0.68, 0.73 },
        textMuted   = { 0.42, 0.50, 0.56 },
        textLabel   = { 0.74, 0.80, 0.84 },
        barTexture  = "Tomo Smooth",
        barAlpha    = 0.70,
        barSpacing  = 1,
        barHeight   = 21,
    },
    {
        key = "TERMINAL", name = "SKIN_TERMINAL",
        bg          = { 0.00, 0.00, 0.00 }, bgAlpha = 0.95,
        headerBg    = { 0.020, 0.051, 0.020, 1.00 },
        headerHover = { 0.20, 1.00, 0.45, 0.14 },
        border      = { 0.20, 0.90, 0.40, 0.25 },
        scrollThumb = { 0.15, 0.60, 0.30 },
        accent      = { 0.20, 1.00, 0.45 },
        textPrimary = { 1.00, 1.00, 1.00 },
        textSecondary = { 0.56, 0.75, 0.62 },
        textMuted   = { 0.36, 0.52, 0.42 },
        textLabel   = { 0.70, 0.84, 0.75 },
        -- Low fill on purpose: the bars read as a trace behind the numbers
        -- rather than as blocks, which is the whole point of this preset.
        barTexture  = "Tomo Flat",
        barAlpha    = 0.30,
        barSpacing  = 0,
        barHeight   = 15,
    },
    {
        key = "VOID", name = "SKIN_VOID",
        bg          = { 0.020, 0.016, 0.035 }, bgAlpha = 0.55,
        headerBg    = { 0.039, 0.031, 0.071, 0.40 },
        headerHover = { 1.00, 1.00, 1.00, 0.05 },
        border      = { 1.00, 1.00, 1.00, 0.03 },
        scrollThumb = { 0.30, 0.28, 0.50 },
        accent      = { 0.45, 0.42, 0.85 },
        textPrimary = { 1.00, 1.00, 1.00 },
        textSecondary = { 0.62, 0.60, 0.72 },
        textMuted   = { 0.44, 0.42, 0.55 },
        textLabel   = { 0.76, 0.74, 0.84 },
        -- Barely any chrome, so the rows get extra spacing to stay legible.
        barTexture  = "Tomo Smooth",
        barAlpha    = 0.40,
        barSpacing  = 2,
        barHeight   = 19,
    },
    {
        key = "PARCHMENT", name = "SKIN_PARCHMENT",
        -- Disabled for now: kept in full so re-enabling is a one-line change.
        -- The machinery it forced into existence stays and benefits every
        -- preset — the tint and surface registries, the fourth text role, the
        -- contrast-corrected panel accent, and ns.ClassColor.
        hidden      = true,
        -- The only light preset. It works because every FontString in the
        -- addon is created with the "OUTLINE" flag, which draws a black
        -- outline: class colours stay untouched and even a white Priest name
        -- keeps its edge against the light background.
        bg          = { 0.878, 0.851, 0.780 }, bgAlpha = 0.94,
        headerBg    = { 0.780, 0.741, 0.651, 1.00 },
        headerHover = { 0.55, 0.25, 0.10, 0.12 },
        border      = { 0.35, 0.30, 0.22, 0.40 },
        scrollThumb = { 0.45, 0.38, 0.26 },
        accent      = { 0.55, 0.25, 0.10 },
        textPrimary = { 0.141, 0.122, 0.086 },
        textSecondary = { 0.290, 0.259, 0.196 },
        textMuted   = { 0.420, 0.384, 0.310 },
        textLabel   = { 0.220, 0.196, 0.149 },
        -- Light skin: every class colour is pushed onto this luminance so
        -- the dark row text stays readable over the bar.
        classLum    = 0.68,
        barTexture  = "Tomo Flat",
        barAlpha    = 1.00,
        barSpacing  = 1,
        barHeight   = 21,
    },
}

ns.SKIN_BY_KEY = {}
for _, s in ipairs(ns.SKINS) do
    ns.SKIN_BY_KEY[s.key] = s
end

-- Option list for the skin dropdown (localized display names).
function ns.GetSkinList()
    local L = ns.L
    local out = {}
    for _, s in ipairs(ns.SKINS) do
        if not s.hidden then
            out[#out + 1] = { value = s.key, label = (L and L[s.name]) or s.key }
        end
    end
    return out
end

----------------------------------------------------------------------
-- Skin application
----------------------------------------------------------------------

local skinCallbacks = {}

function ns.OnSkinChanged(fn)
    skinCallbacks[#skinCallbacks + 1] = fn
end

local function copy3(dst, src)
    dst[1], dst[2], dst[3] = src[1], src[2], src[3]
end

local function copy4(dst, src)
    dst[1], dst[2], dst[3], dst[4] = src[1], src[2], src[3], src[4]
end

-- Apply skin `key`. When `seedDefaults` is true (the user picked a skin in
-- the options) the per-setting DB values (accent, bg opacity, bar height,
-- bar texture) are overwritten with the preset's values. When false (the
-- login re-apply) only the structural look is set and saved user tweaks are
-- preserved.
function ns.ApplySkin(key, seedDefaults)
    local skin = ns.SKIN_BY_KEY[key]
    -- A hidden preset can still be sitting in someone's saved variables, so it
    -- falls back rather than erroring. Anyone currently on it lands on DARK.
    if skin and skin.hidden then
        skin = nil
        key = "DARK"
        if ns.db then ns.db.skin = "DARK" end
    end
    if not skin then
        skin = ns.SKIN_BY_KEY["DARK"]
        key = "DARK"
    end

    -- Structural look -> live Style tables (read live by the renderer)
    copy3(ns.BG, skin.bg)
    ns.BG[4] = skin.bgAlpha
    copy4(ns.HEADER_BG, skin.headerBg)
    copy4(ns.HEADER_HOVER_BG, skin.headerHover)
    copy4(ns.BORDER_COLOR, skin.border)
    if ns.SCROLLBAR_THUMB and skin.scrollThumb then
        copy3(ns.SCROLLBAR_THUMB, skin.scrollThumb)
    end
    copy3(ns.DEFAULT_ACCENT, skin.accent)

    -- Text colours. Previously hard-coded white/grey in Style.lua, which meant
    -- every preset silently assumed a dark background. Carrying them on the
    -- skin is what makes a light preset possible at all.
    if skin.textPrimary then copy3(ns.TEXT_PRIMARY, skin.textPrimary) end
    if skin.textSecondary then copy3(ns.TEXT_SECONDARY, skin.textSecondary) end
    if skin.textMuted then copy3(ns.TEXT_MUTED, skin.textMuted) end
    if skin.textLabel then copy3(ns.TEXT_LABEL, skin.textLabel) end
    ns.CLASS_LUM = skin.classLum
    ns.BAR_ALPHA   = skin.barAlpha
    ns.BAR_SPACING = skin.barSpacing

    if ns.db then
        ns.db.skin = key
        if seedDefaults then
            ns.db.bgAlpha    = skin.bgAlpha
            ns.db.barHeight  = skin.barHeight
            ns.db.barTexture = skin.barTexture
            ns.db.accentColor = { skin.accent[1], skin.accent[2], skin.accent[3] }
            ns.db.accentUseClassColor = false
        end
    end

    -- Re-derive accent from the DB (honours the seed above or a saved override)
    if ns.ApplyAccentColor then
        ns.ApplyAccentColor()
    end

    for _, fn in ipairs(skinCallbacks) do
        fn()
    end
end

----------------------------------------------------------------------
-- Live refresh: re-skin every open window in place (no /reload)
----------------------------------------------------------------------

ns.OnSkinChanged(function()
    -- Text first: every FontString registered through ns.Tint, including the
    -- standalone windows and the settings panel, which are built once and
    -- would otherwise keep their original colours.
    ns.RetintAll()
    ns.ResurfaceAll()

    if not ns.windows then return end
    for _, win in ipairs(ns.windows) do
        if win.RefreshSkin then win.RefreshSkin() end
        if win.RefreshAccentColor then win.RefreshAccentColor() end
        if win.RefreshBarHeight then win.RefreshBarHeight() end
    end
end)

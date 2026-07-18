-- =====================================================================
-- CooldownForge -- Skin (S0). Parametric per-bar visual style: three
-- named presets ("net", "tomo", "verre") over eight axes. Class color
-- is resolved at apply time and never stored, so an exported bar stays
-- portable across classes. desatOnCooldown is an independent toggle
-- (available on every preset, does not flip the bar to "custom").
-- Display-only: no secret values, no protected frames.
-- =====================================================================

local CDF = TomoMod_CooldownForge
if not CDF then return end

local BRAND = { 0.18, 0.85, 0.52 }

CDF.SKIN_TEX = {
    mask_soft   = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\cdf\\mask_corner_soft.tga",
    mask_round  = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\cdf\\mask_corner_round.tga",
    shadow_soft = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\cdf\\shadow_soft.tga",
}

CDF.SKIN_AXES = {
    "border", "corners", "swipe", "timer",
    "badge", "desatOnCooldown", "shadow", "stackPos",
    -- [S7] fine axes (default nil in presets -> resolved defaults below)
    "opacity", "timerColor",
}

CDF.SKIN_PRESETS = {
    net = {
        opacity = 1,
        timerColor = { 1, 1, 1 },
        border  = { mode = "flat", color = { 0, 0, 0 }, thickness = 1 },
        corners = "sharp",
        swipe   = { mode = "dark" },
        timer   = { pos = "center", size = 14 },
        badge   = false,
        desatOnCooldown = false,
        shadow  = false,
        stackPos = "BOTTOMRIGHT",
    },
    tomo = {
        opacity = 1,
        timerColor = nil,   -- nil = accent/class-driven default in render
        border  = { mode = "class", thickness = 1 },
        corners = "soft",
        swipe   = { mode = "class" },
        timer   = { pos = "badge", size = 10 },
        badge   = true,
        desatOnCooldown = false,
        shadow  = false,
        stackPos = "TOPRIGHT",
    },
    verre = {
        opacity = 1,
        timerColor = { 1, 1, 1 },
        border  = { mode = "flat", color = { 1, 1, 1, 0.10 }, thickness = 1 },
        corners = "round",
        swipe   = { mode = "verre" },
        timer   = { pos = "center", size = 15 },
        badge   = false,
        desatOnCooldown = true,
        shadow  = true,
        stackPos = "BOTTOMRIGHT",
    },
}

-- ---------------------------------------------------------------------
-- Color resolution
-- ---------------------------------------------------------------------
-- [L1] delegated to Forge.Util (brand fallback keeps the headless
-- self-test standalone).
function CDF.ClassColor()
    local F = TomoMod_Forge
    if F and F.Util then return F.Util.ClassColor() end
    return BRAND[1], BRAND[2], BRAND[3]
end

-- mode: "class" (player class color) | "bar" (explicit color) | anything
-- else falls back to `color` then to the provided fallback.
function CDF.ResolveTint(mode, color, fr, fg, fb)
    if mode == "class" then return CDF.ClassColor() end
    if mode == "bar" and color then
        return color[1] or 1, color[2] or 1, color[3] or 1, color[4]
    end
    if color then
        return color[1] or 0, color[2] or 0, color[3] or 0, color[4]
    end
    return fr or 0, fg or 0, fb or 0
end

-- ---------------------------------------------------------------------
-- Style normalization / resolution
-- ---------------------------------------------------------------------
-- Ensure bar.style exists and points at a known preset (or "custom").
function CDF.NormalizeStyle(bar)
    if type(bar) ~= "table" then return end
    bar.style = bar.style or {}
    local st = bar.style
    if st.preset ~= "custom" and not CDF.SKIN_PRESETS[st.preset] then
        st.preset = "tomo"
    end
    return bar.style
end

-- Effective style: preset defaults overlaid with the bar's explicit
-- per-axis overrides. "custom" resolves over the tomo base.
function CDF.ResolveStyle(bar)
    local st = (bar and bar.style) or {}
    local base = CDF.SKIN_PRESETS[st.preset] or CDF.SKIN_PRESETS.tomo
    local eff = {}
    for _, axis in ipairs(CDF.SKIN_AXES) do
        local v = st[axis]
        if v == nil then v = base[axis] end
        eff[axis] = v
    end
    return eff
end

-- ---------------------------------------------------------------------
-- Pixel-perfect helper: n physical pixels expressed in UI units for a
-- frame living under UIParent (PanelPP idea, scoped to CDF).
-- ---------------------------------------------------------------------
-- [L1] delegated to Forge.Util.
function CDF.Px(n)
    local F = TomoMod_Forge
    if F and F.Util then return F.Util.Px(n) end
    return n or 1
end

-- ---------------------------------------------------------------------
-- Headless self-test (dev):
--   /script print(TomoMod_CooldownForge.__skinSelfTest())
-- ---------------------------------------------------------------------
function CDF.__skinSelfTest()
    local ok, fail = 0, 0
    local function check(cond)
        if cond then ok = ok + 1 else fail = fail + 1 end
    end
    for _, p in pairs(CDF.SKIN_PRESETS) do
        for _, axis in ipairs(CDF.SKIN_AXES) do
            check(p[axis] ~= nil)
        end
        check(type(p.border) == "table" and p.border.mode ~= nil)
        check(type(p.timer) == "table" and p.timer.pos and p.timer.size)
    end
    local eff = CDF.ResolveStyle({ style = { preset = "net", badge = true } })
    check(eff.badge == true)          -- explicit override wins
    check(eff.corners == "sharp")     -- preset default kept
    local eff2 = CDF.ResolveStyle({})
    check(eff2.corners == "soft")     -- fallback preset = tomo
    local nb = { style = { preset = "wat" } }
    CDF.NormalizeStyle(nb)
    check(nb.style.preset == "tomo")  -- unknown preset normalized
    local r, g, b = CDF.ClassColor()
    check(r and g and b)
    check(CDF.Px(1) > 0)
    return string.format("CDF skin self-test: %d ok / %d fail", ok, fail), fail == 0
end

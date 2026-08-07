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
    -- [S9] castability tint; see CDF.UNUSABLE_MODES. "off" on every preset
    -- so no existing bar changes appearance.
    "unusableMode",
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
        unusableMode = "off",
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
        unusableMode = "off",
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
        unusableMode = "off",
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
-- Bounds for the border thickness slider, exported so an editor can never
-- offer a value the engine would rewrite underneath it.
CDF.BORDER_THICKNESS_MIN, CDF.BORDER_THICKNESS_MAX = 1, 10

-- Ensure bar.style exists and that `preset` names a real preset. Note that
-- "custom" is NOT one: it is a legacy sentinel, migrated away below.
function CDF.NormalizeStyle(bar)
    if type(bar) ~= "table" then return end
    bar.style = bar.style or {}
    local st = bar.style

    -- `preset` names the BASE the fine settings sit on top of. It used to be
    -- overwritten with the sentinel "custom" the moment any fine setting was
    -- touched, and since there is no "custom" entry in SKIN_PRESETS,
    -- ResolveStyle fell back to tomo -- so picking a border colour on a Net or
    -- Verre bar silently rebased the whole icon to Tomo. The customisation is
    -- now a separate flag and the base is preserved.
    if st.preset == "custom" then
        st.preset = "tomo"          -- what "custom" actually resolved to
        st.customized = true
    end
    if not CDF.SKIN_PRESETS[st.preset] then
        st.preset = "tomo"
    end
    st.customized = st.customized and true or nil

    if st.border and st.border.thickness ~= nil then
        local t = tonumber(st.border.thickness) or 1
        if t < CDF.BORDER_THICKNESS_MIN then t = CDF.BORDER_THICKNESS_MIN end
        if t > CDF.BORDER_THICKNESS_MAX then t = CDF.BORDER_THICKNESS_MAX end
        st.border.thickness = t
    end
    -- [S9] drop an unknown castability mode rather than storing it; nil
    -- falls back to the preset value in ResolveStyle.
    if st.unusableMode ~= nil and not (CDF.UNUSABLE_MODES or {})[st.unusableMode] then
        st.unusableMode = nil
    end
    return bar.style
end

-- Axes whose preset value is a table of independent fields. An override on
-- one field must not discard the others.
CDF.SKIN_TABLE_AXES = { border = true, swipe = true, timer = true }

-- Effective style: preset defaults overlaid with the bar's explicit
-- per-axis overrides. `st.preset` always names a real preset by the time this
-- runs (NormalizeStyle guarantees it), so the fallback below is a guard, not
-- the path a customised bar takes -- that was the "custom" sentinel bug.
--
-- Table axes are merged FIELD BY FIELD. Replacing them wholesale was a real
-- defect: the studio writes one field at a time (`bar.style.border.thickness
-- = v`), so moving the thickness slider left border = { thickness = 3 } with
-- no `mode`, and the renderer's `if bd and bd.mode` branch then took its
-- else path and called SetBackdrop(nil) — the outline vanished instead of
-- getting thicker. Changing only the colour did the same, and changing only
-- the mode silently reset the thickness to 1.
function CDF.ResolveStyle(bar)
    local st = (bar and bar.style) or {}
    local base = CDF.SKIN_PRESETS[st.preset] or CDF.SKIN_PRESETS.tomo
    local eff = {}
    for _, axis in ipairs(CDF.SKIN_AXES) do
        local v = st[axis]
        local b = base[axis]
        if CDF.SKIN_TABLE_AXES[axis] and type(v) == "table" and type(b) == "table" then
            local merged = {}
            for k, bv in pairs(b) do merged[k] = bv end
            for k, ov in pairs(v) do merged[k] = ov end
            v = merged
        elseif v == nil then
            v = b
        end
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

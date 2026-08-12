-- =====================================================================
-- CooldownForge -- Core (schema constants, migration, backup, init)
-- AstralForge Cooldown -- Lot 1: foundations & DB. No rendering yet.
-- Schema reference: docs/AstralForge_Cooldown_Schema_v1.md
--
-- Display-only, autonomous engine (replaces the CDM reskin once the
-- renderer lands). Bars are stored per class token in TomoModDB.
-- cooldownForge.bars; defaults are merged defensively by
-- TomoMod_InitDatabase (fill-missing only), so player bars are never
-- clobbered on update.
-- =====================================================================

TomoMod_CooldownForge = TomoMod_CooldownForge or {}
local CDF = TomoMod_CooldownForge

CDF.CURRENT_SCHEMA = 4

-- Stepwise migrations. [v] transforms the db IN PLACE from v-1 to v.
CDF.MIGRATIONS = {
    -- [S2] v2: per-entry overrides (e.override) become a first-class,
    -- sanitized field. Pure normalization pass; the auto-backup taken by
    -- RunMigrations covers any pre-existing garbage in the reserved slot.
    [2] = function(db)
        for _, bars in pairs(db.bars or {}) do
            if type(bars) == "table" then
                for _, bar in ipairs(bars) do
                    if type(bar) == "table" then
                        for _, e in ipairs(bar.entries or {}) do
                            if type(e) == "table" then
                                e.override = CDF.SanitizeOverride(e.override)
                            end
                        end
                    end
                end
            end
        end
    end,
    -- [S6] v3: per-bar conditional visibility (bar.visibility). Pure
    -- normalization; older bars get the "always show" default.
    [3] = function(db)
        for _, bars in pairs(db.bars or {}) do
            if type(bars) == "table" then
                for _, bar in ipairs(bars) do
                    if type(bar) == "table" then
                        bar.visibility = CDF.SanitizeVisibility(bar.visibility)
                    end
                end
            end
        end
    end,
    -- [S8] v4: line/radial layout, split along/cross spacing, glow
    -- conditions and the ready-only display filter. Pure normalization:
    -- an untouched bar keeps its exact previous look, since "line" and
    -- the "ready" glow condition are the historic hardcoded behaviours.
    [4] = function(db)
        for _, bars in pairs(db.bars or {}) do
            if type(bars) == "table" then
                for _, bar in ipairs(bars) do
                    if type(bar) == "table" then
                        if not CDF.LAYOUTS[bar.layout] then bar.layout = "line" end
                        bar.radial = CDF.SanitizeRadial(bar.radial)
                        bar.hideOnCooldown = bar.hideOnCooldown == true
                        if type(bar.glow) == "table"
                           and not CDF.GLOW_CONDS[bar.glow.condition] then
                            bar.glow.condition = "ready"
                        end
                    end
                end
            end
        end
    end,
}

-- ---------------------------------------------------------------------
-- Preset catalog (code-side; entries store only a stable key).
-- itemIDs are finalized in Lot 2/3; the keys are stable and validated now.
-- ---------------------------------------------------------------------
CDF.PRESETS = {
    healthstone = { name = "Healthstone",          itemIDs = {} },
    healthpot   = { name = "Health Potion",         itemIDs = {} },
    manapot     = { name = "Mana Potion",           itemIDs = {} },
    invis       = { name = "Invisibility Potion",   itemIDs = {} },
}

-- Racials resolved to the player's race at runtime (filled in Lot 2).
CDF.RACIALS = {}

-- Valid enum sets (used by sanitize/validation).
CDF.ORIENTATIONS  = { horizontal = true, vertical = true }
CDF.GROWTHS       = { RIGHT = true, LEFT = true, UP = true, DOWN = true }
CDF.TEXT_MODES    = { timer = true, name = true, none = true }
CDF.GLOW_TYPES    = { Pixel = true, Autocast = true, Button = true }
-- [S8] Layout modes and glow trigger conditions.
--   ready  -> off cooldown (historic, hardcoded behaviour)
--   aura   -> a buff is currently up on the player
--   always -> glow whenever the icon is shown
--   usable -> off cooldown AND currently castable (resource available)
CDF.LAYOUTS       = { line = true, radial = true }
-- [H4] `maxCharges`: every charge is back, detected from the CHARGE duration
-- object rather than by comparing counts -- chargeInfo.currentCharges is a
-- secret value and must never meet a comparison operator.
-- `stacks`: the tracked buff reached a count the player names, because the
-- client does not expose a maximum for an aura.
CDF.GLOW_CONDS    = { ready = true, aura = true, always = true, usable = true,
                      maxCharges = true, stacks = true }
-- [S9] Castability tint modes applied to the icon art:
--   off      -> never tint (pre-S9 behaviour; default on every preset)
--   dim      -> grey out whenever the spell/item cannot be used right now
--   resource -> grey when unusable, blue-dark when the missing resource is
--               the blocker (same treatment as ActionBarSkin on the bars)
CDF.UNUSABLE_MODES = { off = true, dim = true, resource = true }
CDF.ENTRY_KINDS   = { spell = true, item = true, itemPreset = true, equippedTrinket = true, racial = true }
CDF.TRINKET_SLOTS = { [13] = true, [14] = true }

-- ---------------------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------------------
-- Published so the Studio's sliders cannot drift from what Sanitize will
-- accept. A slider that offers a value the sanitizer then rejects is worse
-- than a narrower slider: it looks like it worked.
CDF.ICON_MIN  = 8
CDF.ICON_MAX  = 128
CDF.ICON_BASE = 40   -- schema default, and the 1.00x point of the scale slider

local function clamp(v, lo, hi)
    v = tonumber(v)
    if not v then return lo end
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end
CDF.clamp = clamp

-- [S2] Per-entry override sanitizer. Tri-states are nil (inherit) / true
-- / false; emphasis is clamped to [1.0, 1.3] and dropped when neutral;
-- glowColor must be a valid {r,g,b[,a]} array. Returns nil when nothing
-- meaningful remains, keeping the stored schema lean.
CDF.OVERRIDE_TRIS = { "glow", "desat", "swipe", "timer", "stacks" }

function CDF.SanitizeOverride(o)
    if type(o) ~= "table" then return nil end
    local out = {}
    for _, k in ipairs(CDF.OVERRIDE_TRIS) do
        local v = o[k]
        if type(v) == "boolean" then out[k] = v end
    end
    local em = tonumber(o.emphasis)
    if em and em > 1.001 then
        if em > 1.3 then em = 1.3 end
        out.emphasis = em
    end
    -- [S8] per-entry glow condition + the buff to watch for it
    if type(o.glowCondition) == "string" and CDF.GLOW_CONDS[o.glowCondition] then
        out.glowCondition = o.glowCondition
    end
    local aid = tonumber(o.auraSpellID)
    if aid and aid > 0 then out.auraSpellID = math.floor(aid) end
    -- [H4] threshold for the `stacks` condition, per entry.
    local gs = tonumber(o.glowStacks)
    if gs and gs > 1 then out.glowStacks = math.min(math.floor(gs), 99) end
    -- [S9] per-entry castability tint (nil = inherit from the bar style)
    if type(o.unusableMode) == "string" and CDF.UNUSABLE_MODES[o.unusableMode] then
        out.unusableMode = o.unusableMode
    end
    local gc = o.glowColor
    if type(gc) == "table" and tonumber(gc[1]) and tonumber(gc[2]) and tonumber(gc[3]) then
        out.glowColor = {
            clamp(gc[1], 0, 1), clamp(gc[2], 0, 1), clamp(gc[3], 0, 1),
            gc[4] and clamp(gc[4], 0, 1) or 1,
        }
    end
    if next(out) == nil then return nil end
    return out
end

-- [S8] Radial layout parameters. Angles in degrees, 0 = right, 90 = up.
-- An arc of 360 spreads the icons over a full circle (step = arc / n);
-- anything smaller lays them along that arc inclusive of both ends.
CDF.RADIAL_DEFAULT = { radius = 90, startAngle = 90, arc = 360, clockwise = true }

function CDF.SanitizeRadial(r)
    if type(r) ~= "table" then r = {} end
    local d = CDF.RADIAL_DEFAULT
    return {
        radius     = clamp(r.radius     or d.radius,     20, 400),
        startAngle = clamp(r.startAngle or d.startAngle,  0, 359),
        arc        = clamp(r.arc        or d.arc,        30, 360),
        clockwise  = r.clockwise ~= false,
    }
end

-- Player's class token, e.g. "MAGE".
function CDF.PlayerClass()
    local _, class = UnitClass("player")
    return class
end

-- Root DB block (assumes TomoMod_InitDatabase already ran).
function CDF.DB()
    return TomoModDB and TomoModDB.cooldownForge
end

-- Generate a stable bar id unique within `arr`.
function CDF.genBarId(arr)
    local id
    repeat
        id = string.format("bar_%04x%04x", math.random(0, 0xffff), math.random(0, 0xffff))
        local taken = false
        for i = 1, #arr do
            if arr[i].id == id then taken = true; break end
        end
    until not taken
    return id
end

-- ---------------------------------------------------------------------
-- Schema factories
-- ---------------------------------------------------------------------
-- [S6] Conditional visibility, all tri-state (nil = don't care, true =
-- require, false = require NOT). Non-secret, event-driven signals only.
CDF.VIS_CONDS = { "inCombat", "hasTarget", "inInstance", "inGroup", "inRaid" }

-- [G3] What happens when a condition is NOT met: hide the bar (the original
-- and still the default) or keep it on screen at reduced opacity. Dimming is
-- a display-only effect on the bar container; the icons keep updating, so a
-- dimmed bar shows live cooldowns instead of freezing.
CDF.VIS_UNMET = { hide = true, dim = true }
CDF.VIS_DIM_DEFAULT = 0.5
CDF.VIS_DIM_MIN, CDF.VIS_DIM_MAX = 0.05, 0.95

function CDF.SanitizeVisibility(v)
    if type(v) ~= "table" then return nil end
    local out = {}
    for _, k in ipairs(CDF.VIS_CONDS) do
        if type(v[k]) == "boolean" then out[k] = v[k] end
    end
    local hasCond = next(out) ~= nil

    if CDF.VIS_UNMET[v.unmet] and v.unmet ~= "hide" then
        out.unmet = v.unmet
        local a = tonumber(v.dimAlpha)
        if a then
            if a < CDF.VIS_DIM_MIN then a = CDF.VIS_DIM_MIN end
            if a > CDF.VIS_DIM_MAX then a = CDF.VIS_DIM_MAX end
            out.dimAlpha = a
        end
    end

    -- Keep the table when the player has chosen dimming even with no condition
    -- set yet: dropping it would silently discard that choice the moment they
    -- set it before picking a condition.
    if not hasCond and out.unmet == nil then return nil end
    return out
end

function CDF.NewBarSchema(name)
    return {
        id          = nil,   -- assigned by CreateBar
        name        = name or "Bar",
        enabled     = true,
        layout      = "line",          -- [S8] "line" | "radial"
        orientation = "horizontal",
        growth      = "RIGHT",
        iconSize    = 40,             -- legacy square size; still the fallback
        iconWidth   = nil,            -- [G2] nil = follow iconSize
        iconHeight  = nil,            -- [G2] nil = follow iconSize
        spacing     = 4,               -- along the growth axis
        spacingCross = nil,            -- [S8] between wrapped lines; nil = follow `spacing`
        wrap        = 0,
        radial      = { radius = 90, startAngle = 90, arc = 360, clockwise = true },
        hideOnCooldown = false,        -- [S8] drop icons while they are on cooldown
        hideOnUnusable = false,        -- [S9] drop icons the player cannot afford
        glow  = { enabled = true, type = "Pixel", color = { 0.18, 0.85, 0.52, 1 },
                  condition = "ready", auraSpellID = nil, stacks = 2 },
        swipe = { draw = true, color = { 0, 0, 0, 0.6 }, reverse = false },
        -- [H2] threshold: 0 disables. Below it the countdown switches colour,
        -- which is the cheapest way to read "about to come up" mid-fight.
        -- [H3] `font` is an LSM name; nil or unknown falls back to the bundled
        -- Poppins. `timerSize` nil means "follow the style preset".
        text  = { mode = "timer", font = nil, outline = "OUTLINE",
                  size = 13, timerSize = nil, stacks = true,
                  threshold = 0, thresholdColor = { 1, 0.35, 0.25 } },
        style = { preset = "tomo" },
        visibility = nil,   -- [S6] nil = always shown
        position = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 },
        entries = {},
    }
end

-- [G4] Which aura an entry watches: its explicit override, else its own
-- spell. Returns nil for entries that cannot resolve to a spell (items,
-- trinkets), which is why aura mode is only offered on spell entries.
function CDF.EntryAuraID(entry, resolved)
    if type(entry) ~= "table" or entry.mode ~= "aura" then return nil end
    local id = tonumber(entry.auraID)
    if id then return id end
    if resolved and resolved.spellID then return tonumber(resolved.spellID) end
    return tonumber(entry.id)
end

-- [G2] Effective icon dimensions. Width and height are independent
-- overrides on top of the historic square `iconSize`, so a bar that has
-- never been touched keeps rendering exactly as before and no migration is
-- needed. Both fall back to iconSize, then to the schema default.
function CDF.IconDims(bar)
    local base = (bar and tonumber(bar.iconSize)) or 40
    local w = (bar and tonumber(bar.iconWidth))  or base
    local h = (bar and tonumber(bar.iconHeight)) or base
    return w, h
end

-- Extents along and across the growth axis, for the layout maths.
function CDF.IconExtents(bar)
    local w, h = CDF.IconDims(bar)
    if bar and bar.orientation == "vertical" then return h, w end
    return w, h
end

function CDF.NewEntrySchema(data)
    data = data or {}
    return {
        kind     = data.kind,
        enabled  = data.enabled ~= false,
        id       = data.id,
        preset   = data.preset,
        slot     = data.slot,
        spec     = tonumber(data.spec) or 0,
        -- [G4] "aura": the icon tracks a BUFF instead of a cooldown. It is
        -- hidden while the aura is absent and appears with its remaining
        -- time and stacks while it is up — the behaviour Blizzard's "Tracked
        -- Buffs" viewer has and a plain cooldown entry does not.
        mode     = (data.mode == "aura") and "aura" or nil,
        -- Optional: watch a different aura than the entry's own spell. Some
        -- procs are granted by one spell and applied as another.
        auraID   = tonumber(data.auraID) or nil,
        -- [H5] Show this entry only when a talent is taken (or only when it is
        -- not). Expressed as the spell the talent grants: node ids get
        -- renumbered at every rework, spell ids do not.
        talentID   = tonumber(data.talentID) or nil,
        talentMode = (data.talentMode == "unknown") and "unknown" or nil,
        override = CDF.SanitizeOverride(data.override),   -- [S2] per-entry FX
        -- Marks an entry as coming from a Blizzard viewer import rather than
        -- from the player. Resync only ever removes entries carrying it, so
        -- it has to survive the schema: this table is a whitelist, and a
        -- field missing from it is silently dropped.
        fromViewer = data.fromViewer and true or nil,
    }
end

-- ---------------------------------------------------------------------
-- Defensive sanitize (clamps enums/ranges; used on create/duplicate and
-- callable after import). Never removes unknown data silently beyond
-- coercing invalid enum values back to their default.
-- ---------------------------------------------------------------------
function CDF.SanitizeBar(bar)
    if type(bar) ~= "table" then return end
    bar.name        = tostring(bar.name or "Bar")
    if bar.enabled == nil then bar.enabled = true end
    if not CDF.LAYOUTS[bar.layout] then bar.layout = "line" end
    if not CDF.ORIENTATIONS[bar.orientation] then bar.orientation = "horizontal" end
    if not CDF.GROWTHS[bar.growth] then bar.growth = "RIGHT" end
    -- iconSize used to be clamped to 24..64 while the width and height
    -- overrides allowed 8..128, so the same 8px icon was reachable through
    -- one control and refused by the other. Worse, nothing sanitizes on
    -- every apply: a size outside the range looked accepted until something
    -- called SanitizeBar -- a resync, an import, a duplicate -- and then
    -- snapped back with no explanation. One range now, for all three.
    bar.iconSize = clamp(bar.iconSize, CDF.ICON_MIN, CDF.ICON_MAX)
    -- [G2] nil stays nil so an untouched bar keeps following iconSize and
    -- exports stay portable; only an explicit override is clamped.
    if bar.iconWidth  ~= nil then bar.iconWidth  = clamp(bar.iconWidth,  CDF.ICON_MIN, CDF.ICON_MAX) end
    if bar.iconHeight ~= nil then bar.iconHeight = clamp(bar.iconHeight, CDF.ICON_MIN, CDF.ICON_MAX) end
    bar.spacing  = clamp(bar.spacing, 0, 64)
    if bar.spacingCross ~= nil then bar.spacingCross = clamp(bar.spacingCross, 0, 64) end
    bar.wrap     = clamp(bar.wrap, 0, 12)
    bar.radial   = CDF.SanitizeRadial(bar.radial)
    bar.hideOnCooldown = bar.hideOnCooldown == true
    -- [S9] independent of hideOnCooldown: hides an icon that is off cooldown
    -- but currently uncastable (not enough rage, wrong form, ...).
    bar.hideOnUnusable = bar.hideOnUnusable == true
    bar.glow  = bar.glow  or { enabled = true, type = "Pixel", color = { 0.18, 0.85, 0.52, 1 } }
    if not CDF.GLOW_TYPES[bar.glow.type] then bar.glow.type = "Pixel" end
    if not CDF.GLOW_CONDS[bar.glow.condition] then bar.glow.condition = "ready" end
    if bar.glow.auraSpellID ~= nil then
        local a = tonumber(bar.glow.auraSpellID)
        bar.glow.auraSpellID = (a and a > 0) and math.floor(a) or nil
    end
    bar.swipe = bar.swipe or { draw = true, color = { 0, 0, 0, 0.6 }, reverse = false }
    bar.text  = bar.text  or { mode = "timer", font = "Poppins-Medium", size = 13, stacks = true }
    if not CDF.TEXT_MODES[bar.text.mode] then bar.text.mode = "timer" end
    bar.glow = bar.glow or {}
    bar.glow.stacks = clamp(tonumber(bar.glow.stacks) or 2, 2, 20)
    bar.text.threshold = clamp(tonumber(bar.text.threshold) or 0, 0, 60)
    if type(bar.text.font) ~= "string" or bar.text.font == "" then bar.text.font = nil end
    if bar.text.outline ~= "none" and bar.text.outline ~= "THICKOUTLINE" then
        bar.text.outline = "OUTLINE"
    end
    bar.text.size = clamp(tonumber(bar.text.size) or 13, 8, 28)
    if bar.text.timerSize ~= nil then
        bar.text.timerSize = clamp(tonumber(bar.text.timerSize) or 13, 8, 28)
    end
    local tcol = bar.text.thresholdColor
    if type(tcol) ~= "table" or not tonumber(tcol[1]) then
        bar.text.thresholdColor = { 1, 0.35, 0.25 }
    end
    if CDF.NormalizeStyle then CDF.NormalizeStyle(bar) end
    bar.visibility = CDF.SanitizeVisibility(bar.visibility)
    bar.entries = bar.entries or {}
    for _, e in ipairs(bar.entries) do
        if type(e) == "table" then
            e.override = CDF.SanitizeOverride(e.override)
            -- [G4] only "aura" is stored; anything else falls back to the
            -- historic cooldown behaviour rather than being persisted.
            if e.mode ~= "aura" then e.mode = nil end
            e.auraID = tonumber(e.auraID) or nil
            e.talentID = tonumber(e.talentID) or nil
            if e.talentID == nil or e.talentMode ~= "unknown" then e.talentMode = nil end
        end
    end
    return bar
end

-- ---------------------------------------------------------------------
-- Migration + auto-backup
-- ---------------------------------------------------------------------
-- [L2] Delegated to the shared Forge.Schema machinery (same semantics:
-- stepwise pcall, pre-migration backup, failure keeps `from`).
local function schemaOpts(db)
    return {
        root       = db,
        target     = CDF.CURRENT_SCHEMA,
        migrations = CDF.MIGRATIONS,
        dataKeys   = { "bars" },
    }
end

function CDF.RunMigrations()
    local db = CDF.DB()
    if not db then return end
    local F = TomoMod_Forge
    if F and F.Schema then
        F.Schema.Migrate(schemaOpts(db))
    end
end

-- Manual restore from _backup (never automatic). Returns true on success.
function CDF.RestoreBackup()
    local db = CDF.DB()
    if not db then return false end
    local F = TomoMod_Forge
    if F and F.Schema then
        return F.Schema.Restore(schemaOpts(db))
    end
    return false
end

-- ---------------------------------------------------------------------
-- Init: run migrations once the DB is ready (PLAYER_LOGIN fires strictly
-- after TomoMod_InitDatabase on ADDON_LOADED).
-- ---------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    if not CDF.DB() then return end
    CDF.RunMigrations()
    CDF.initialized = true
end)

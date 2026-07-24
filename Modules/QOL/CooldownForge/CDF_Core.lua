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
CDF.LAYOUTS       = { line = true, radial = true }
CDF.GLOW_CONDS    = { ready = true, aura = true, always = true }
CDF.ENTRY_KINDS   = { spell = true, item = true, itemPreset = true, equippedTrinket = true, racial = true }
CDF.TRINKET_SLOTS = { [13] = true, [14] = true }

-- ---------------------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------------------
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
CDF.VIS_CONDS = { "inCombat", "inInstance", "inGroup", "inRaid" }

function CDF.SanitizeVisibility(v)
    if type(v) ~= "table" then return nil end
    local out = {}
    for _, k in ipairs(CDF.VIS_CONDS) do
        if type(v[k]) == "boolean" then out[k] = v[k] end
    end
    if next(out) == nil then return nil end
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
        iconSize    = 40,
        spacing     = 4,               -- along the growth axis
        spacingCross = nil,            -- [S8] between wrapped lines; nil = follow `spacing`
        wrap        = 0,
        radial      = { radius = 90, startAngle = 90, arc = 360, clockwise = true },
        hideOnCooldown = false,        -- [S8] drop icons while they are on cooldown
        glow  = { enabled = true, type = "Pixel", color = { 0.18, 0.85, 0.52, 1 },
                  condition = "ready", auraSpellID = nil },
        swipe = { draw = true, color = { 0, 0, 0, 0.6 }, reverse = false },
        text  = { mode = "timer", font = "Poppins-Medium", size = 13, stacks = true },
        style = { preset = "tomo" },
        visibility = nil,   -- [S6] nil = always shown
        position = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 },
        entries = {},
    }
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
        override = CDF.SanitizeOverride(data.override),   -- [S2] per-entry FX
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
    bar.iconSize = clamp(bar.iconSize, 24, 64)
    bar.spacing  = clamp(bar.spacing, 0, 64)
    if bar.spacingCross ~= nil then bar.spacingCross = clamp(bar.spacingCross, 0, 64) end
    bar.wrap     = clamp(bar.wrap, 0, 12)
    bar.radial   = CDF.SanitizeRadial(bar.radial)
    bar.hideOnCooldown = bar.hideOnCooldown == true
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
    if CDF.NormalizeStyle then CDF.NormalizeStyle(bar) end
    bar.visibility = CDF.SanitizeVisibility(bar.visibility)
    bar.entries = bar.entries or {}
    for _, e in ipairs(bar.entries) do
        if type(e) == "table" then
            e.override = CDF.SanitizeOverride(e.override)
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

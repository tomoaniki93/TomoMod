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

CDF.CURRENT_SCHEMA = 2

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
function CDF.NewBarSchema(name)
    return {
        id          = nil,   -- assigned by CreateBar
        name        = name or "Bar",
        enabled     = true,
        orientation = "horizontal",
        growth      = "RIGHT",
        iconSize    = 40,
        spacing     = 4,
        wrap        = 0,
        glow  = { enabled = true, type = "Pixel", color = { 0.18, 0.85, 0.52, 1 } },
        swipe = { draw = true, color = { 0, 0, 0, 0.6 }, reverse = false },
        text  = { mode = "timer", font = "Poppins-Medium", size = 13, stacks = true },
        style = { preset = "tomo" },
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
    if not CDF.ORIENTATIONS[bar.orientation] then bar.orientation = "horizontal" end
    if not CDF.GROWTHS[bar.growth] then bar.growth = "RIGHT" end
    bar.iconSize = clamp(bar.iconSize, 24, 64)
    bar.spacing  = clamp(bar.spacing, 0, 16)
    bar.wrap     = clamp(bar.wrap, 0, 12)
    bar.glow  = bar.glow  or { enabled = true, type = "Pixel", color = { 0.18, 0.85, 0.52, 1 } }
    if not CDF.GLOW_TYPES[bar.glow.type] then bar.glow.type = "Pixel" end
    bar.swipe = bar.swipe or { draw = true, color = { 0, 0, 0, 0.6 }, reverse = false }
    bar.text  = bar.text  or { mode = "timer", font = "Poppins-Medium", size = 13, stacks = true }
    if not CDF.TEXT_MODES[bar.text.mode] then bar.text.mode = "timer" end
    if CDF.NormalizeStyle then CDF.NormalizeStyle(bar) end
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
function CDF.RunMigrations()
    local db = CDF.DB()
    if not db then return end
    local from = tonumber(db.schemaVersion) or 1
    if from >= CDF.CURRENT_SCHEMA then
        db.schemaVersion = CDF.CURRENT_SCHEMA
        return
    end
    -- Auto-backup BEFORE migrating (retention = 1; overwrites previous).
    db._backup = {
        schemaVersion = from,
        date          = date("%Y-%m-%d %H:%M"),
        bars          = CopyTable(db.bars or {}),
    }
    for v = from + 1, CDF.CURRENT_SCHEMA do
        local m = CDF.MIGRATIONS[v]
        if type(m) == "function" then
            local ok, err = pcall(m, db)
            if not ok then
                -- Migration failed: keep the backup, leave version at `from`.
                db.schemaVersion = from
                if geterrorhandler then geterrorhandler()(err) end
                return
            end
        end
    end
    db.schemaVersion = CDF.CURRENT_SCHEMA
end

-- Manual restore from _backup (never automatic). Returns true on success.
function CDF.RestoreBackup()
    local db = CDF.DB()
    if not db or not db._backup then return false end
    db.bars = CopyTable(db._backup.bars or {})
    db.schemaVersion = tonumber(db._backup.schemaVersion) or CDF.CURRENT_SCHEMA
    CDF.RunMigrations()   -- bring restored (older) data back up to CURRENT
    return true
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

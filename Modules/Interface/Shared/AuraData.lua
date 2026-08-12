-- =====================================
-- Interface/Shared/AuraData.lua — shared aura database for group frames
--
-- PartyFrame/HoTs.lua and RaidFrame/Auras.lua each carried their own copy of
-- the healer HoT list and they had already drifted apart (party knew about
-- Blessing of Summer, Cloudburst and Enveloping Breath, raid did not). Both
-- now read from here.
--
-- Defensive cooldowns are split into three categories because a healer wants
-- very different things from them:
--   external — cast BY someone else ON this player (Ironbark, Life Cocoon,
--              Pain Suppression…). "Does this target already have a cooldown
--              on it?" This is the one that matters mid-pull.
--   raidwide — a single cast that lands on the whole group (Rallying Cry,
--              Darkness, Anti-Magic Zone…). Useful, but it lights up every
--              frame at once, so it is opt-in.
--   personal — the player pressing their own button (Divine Shield, Ice
--              Block, Barkskin…). Informative, noisy, opt-in.
--
-- All aura numbers pass through SafeNumber: in 12.x duration and
-- expirationTime on group members can be secret values, and arithmetic or
-- comparison on a secret value is the cardinal taint rule.
-- =====================================

TomoMod_AuraData = TomoMod_AuraData or {}
local AD = TomoMod_AuraData

local pcall, pairs, type = pcall, pairs, type
local GetTime = GetTime
local UnitExists = UnitExists
local issecretvalue = issecretvalue

-- =====================================
-- SECRET-VALUE SAFE ACCESSORS
-- issecretvalue() runs before ANY comparison on the argument.
-- =====================================
function AD.SafeNumber(value)
    if issecretvalue(value) then return nil end
    if type(value) ~= "number" then return nil end
    return value
end

-- Remaining seconds for an aura, or nil when the value is unusable — which
-- includes the case where the API handed us a secret value.
function AD.RemainingTime(duration, expirationTime)
    local d = AD.SafeNumber(duration)
    if not d then return nil end
    if d <= 0 then return nil end

    local e = AD.SafeNumber(expirationTime)
    if not e then return nil end

    local remaining = e - GetTime()
    if remaining <= 0 then return nil end
    return remaining
end

-- =====================================
-- HEALER HOT DATABASE (union of the former party and raid tables)
-- =====================================
AD.HEALER_HOTS = {
    PRIEST = {
        [139]    = true,  -- Renew
        [17]     = true,  -- Power Word: Shield
        [194384] = true,  -- Atonement
        [41635]  = true,  -- Prayer of Mending
        [77489]  = true,  -- Echo of Light
        [214206] = true,  -- Atonement (PvP)
    },
    DRUID = {
        [774]    = true,  -- Rejuvenation
        [8936]   = true,  -- Regrowth (HoT component)
        [33763]  = true,  -- Lifebloom
        [48438]  = true,  -- Wild Growth
        [102342] = true,  -- Ironbark
        [155777] = true,  -- Germination (Rejuv 2)
        [207386] = true,  -- Spring Blossoms
        [200389] = true,  -- Cultivation
        [391891] = true,  -- Adaptive Swarm
    },
    PALADIN = {
        [53563]  = true,  -- Beacon of Light
        [156910] = true,  -- Beacon of Faith
        [223306] = true,  -- Bestow Faith
        [287280] = true,  -- Glimmer of Light
        [388013] = true,  -- Blessing of Summer
    },
    SHAMAN = {
        [61295]  = true,  -- Riptide
        [382024] = true,  -- Earthliving Weapon
        [383009] = true,  -- Healing Tide (buff)
        [157153] = true,  -- Cloudburst
    },
    MONK = {
        [119611] = true,  -- Renewing Mist
        [116849] = true,  -- Life Cocoon
        [124682] = true,  -- Enveloping Mist
        [191840] = true,  -- Essence Font
        [325209] = true,  -- Enveloping Breath
    },
    EVOKER = {
        [355941] = true,  -- Dream Breath
        [363502] = true,  -- Dream Flight
        [366155] = true,  -- Reversion
        [373267] = true,  -- Lifebind
        [376788] = true,  -- Echo
        [378001] = true,  -- Dream Breath (HoT)
    },
}

AD.CLASS_HOT_COLORS = {
    PRIEST  = { r = 1.00, g = 1.00, b = 1.00 },
    DRUID   = { r = 1.00, g = 0.49, b = 0.04 },
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    SHAMAN  = { r = 0.00, g = 0.44, b = 0.87 },
    MONK    = { r = 0.00, g = 1.00, b = 0.60 },
    EVOKER  = { r = 0.20, g = 0.58, b = 0.50 },
}

AD.HOT_SPELL_TO_CLASS = {}
for cls, spells in pairs(AD.HEALER_HOTS) do
    for spellID in pairs(spells) do
        AD.HOT_SPELL_TO_CLASS[spellID] = cls
    end
end

-- =====================================
-- DEBUFF TYPE COLOURS (dispel highlight, debuff borders)
-- =====================================
AD.DEBUFF_TYPE_COLORS = {
    Magic   = { r = 0.20, g = 0.60, b = 1.00 },
    Curse   = { r = 0.60, g = 0.00, b = 1.00 },
    Disease = { r = 0.60, g = 0.40, b = 0.00 },
    Poison  = { r = 0.00, g = 0.60, b = 0.00 },
}

-- =====================================
-- DEFENSIVE COOLDOWNS
-- =====================================
AD.DEFENSIVE_KIND_EXTERNAL = "external"
AD.DEFENSIVE_KIND_RAIDWIDE = "raidwide"
AD.DEFENSIVE_KIND_PERSONAL = "personal"

AD.DEFENSIVE_KIND_COLORS = {
    external = { r = 1.00, g = 0.82, b = 0.00 },  -- gold
    raidwide = { r = 0.20, g = 0.90, b = 0.90 },  -- cyan
    personal = { r = 0.90, g = 0.25, b = 0.25 },  -- red
}

-- Lower weight sorts first inside a category.
local EXTERNALS = {
    -- Priest
    [33206]  = 10,  -- Pain Suppression
    [47788]  = 10,  -- Guardian Spirit
    -- Paladin
    [1022]   = 20,  -- Blessing of Protection
    [6940]   = 20,  -- Blessing of Sacrifice
    [204018] = 20,  -- Blessing of Spellwarding
    -- Druid
    [102342] = 20,  -- Ironbark
    -- Monk
    [116849] = 10,  -- Life Cocoon
    -- Evoker
    [357170] = 20,  -- Time Dilation
    -- Warlock
    [108416] = 40,  -- Dark Pact (pet sacrifice, lands on the warlock)
}

local RAIDWIDE = {
    -- Priest
    [81782]  = 10,  -- Power Word: Barrier
    -- Warrior
    [97463]  = 10,  -- Rallying Cry
    -- Demon Hunter
    [209426] = 20,  -- Darkness
    -- Death Knight
    [145629] = 20,  -- Anti-Magic Zone
    -- Shaman
    [325174] = 10,  -- Spirit Link Totem
    -- Evoker
    [374227] = 20,  -- Zephyr
}

local PERSONALS = {
    -- Death Knight
    [48707]  = 20,  -- Anti-Magic Shell
    [48792]  = 10,  -- Icebound Fortitude
    [49028]  = 20,  -- Dancing Rune Weapon
    [55233]  = 10,  -- Vampiric Blood
    -- Demon Hunter
    [187827] = 10,  -- Metamorphosis (Vengeance)
    [196555] = 10,  -- Netherwalk
    [198589] = 30,  -- Blur
    -- Druid
    [22812]  = 30,  -- Barkskin
    [61336]  = 10,  -- Survival Instincts
    -- Evoker
    [363916] = 20,  -- Obsidian Scales
    [374348] = 20,  -- Renewing Blaze
    -- Hunter
    [186265] = 10,  -- Aspect of the Turtle
    -- Mage
    [45438]  = 10,  -- Ice Block
    [11426]  = 30,  -- Ice Barrier
    [235313] = 30,  -- Blazing Barrier
    [235450] = 30,  -- Prismatic Barrier
    -- Monk
    [115176] = 20,  -- Zen Meditation
    [115203] = 10,  -- Fortifying Brew
    [122278] = 20,  -- Dampen Harm
    [122783] = 20,  -- Diffuse Magic
    -- Paladin
    [498]    = 30,  -- Divine Protection
    [642]    = 10,  -- Divine Shield
    [31850]  = 10,  -- Ardent Defender
    [86659]  = 10,  -- Guardian of Ancient Kings
    -- Priest
    [47585]  = 10,  -- Dispersion
    -- Rogue
    [5277]   = 20,  -- Evasion
    [31224]  = 20,  -- Cloak of Shadows
    [1966]   = 40,  -- Feint
    -- Shaman
    [108271] = 10,  -- Astral Shift
    -- Warlock
    [104773] = 10,  -- Unending Resolve
    -- Warrior
    [871]    = 10,  -- Shield Wall
    [12975]  = 10,  -- Last Stand
    [23920]  = 30,  -- Spell Reflection
    [118038] = 20,  -- Die by the Sword
    [184364] = 20,  -- Enraged Regeneration
}

-- spellID -> { kind = <category>, weight = <sort order> }
AD.DEFENSIVES = {}
local function RegisterDefensives(source, kind, kindWeight)
    for spellID, weight in pairs(source) do
        AD.DEFENSIVES[spellID] = { kind = kind, weight = kindWeight + weight }
    end
end
RegisterDefensives(EXTERNALS, AD.DEFENSIVE_KIND_EXTERNAL, 0)
RegisterDefensives(RAIDWIDE,  AD.DEFENSIVE_KIND_RAIDWIDE, 1000)
RegisterDefensives(PERSONALS, AD.DEFENSIVE_KIND_PERSONAL, 2000)

-- =====================================
-- SCAN
-- `want`  : caller-owned table { external = bool, raidwide = bool,
--           personal = bool }, built once at module scope by each consumer
-- `out`   : caller-owned result table, entries are reused across calls
-- returns : number of usable entries in `out`
-- =====================================
local SCAN_LIMIT = 12

function AD.ScanDefensives(unit, want, maxCount, out)
    if not unit then return 0 end
    if not UnitExists(unit) then return 0 end
    if not want then return 0 end
    if not maxCount or maxCount < 1 then return 0 end
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return 0 end
    -- [12.1] Nothing can be counted on a restricted frame. 0 does read as
    -- "nobody has it" rather than "cannot tell", and this signature has no
    -- way to say the latter -- but it is also exactly what the failing scan
    -- below returned before, so the icons go dark either way. Saying "cannot
    -- tell" properly would mean a nil return and a caller that leaves its
    -- icons untouched, which is a visible-behaviour decision, not a cleanup.
    if TomoMod_Utils and TomoMod_Utils.AurasRestricted and TomoMod_Utils.AurasRestricted() then return 0 end

    local count = 0
    local idx = 1
    while idx <= 40 and count < SCAN_LIMIT do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, idx, "HELPFUL")
        if not ok or not aura then break end

        local spellID = AD.SafeNumber(aura.spellId)
        if spellID then
            local info = AD.DEFENSIVES[spellID]
            if info and want[info.kind] then
                count = count + 1
                local entry = out[count]
                if not entry then entry = {}; out[count] = entry end
                entry.spellID  = spellID
                entry.kind     = info.kind
                entry.weight   = info.weight
                entry.icon     = aura.icon
                entry.duration = aura.duration
                entry.expTime  = aura.expirationTime
            end
        end

        idx = idx + 1
    end

    -- Insertion sort: at most SCAN_LIMIT entries, in practice two or three,
    -- and it allocates nothing (table.sort would need a comparator upvalue).
    for i = 2, count do
        local entry = out[i]
        local j = i - 1
        while j >= 1 and out[j].weight > entry.weight do
            out[j + 1] = out[j]
            j = j - 1
        end
        out[j + 1] = entry
    end

    if count > maxCount then count = maxCount end
    return count
end

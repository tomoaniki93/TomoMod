-- =====================================
-- AuraTracker/SpellDB.lua — Tracked aura database
-- Categories: trinkets, enchants, selfBuffs, raidBuffs, defensives
-- Updated for Midnight Season 1
-- =====================================

TomoMod_AuraTrackerDB = TomoMod_AuraTrackerDB or {}
local SDB = TomoMod_AuraTrackerDB

-- =====================
-- FORMAT: [spellID] = { cat = "category" }
-- Actual icon/name come from the aura data at runtime
-- =====================

SDB.spells = {
    -- ═══════════════════════════════
    -- TRINKET PROCS (Midnight S1)
    -- TODO: Replace placeholder IDs with real Midnight S1 trinket proc spellIDs
    -- ═══════════════════════════════

    -- Midnight S1 Raid trinkets
    -- [000001] = { cat = "trinkets" },  -- Placeholder: Raid trinket 1
    -- [000002] = { cat = "trinkets" },  -- Placeholder: Raid trinket 2
    -- [000003] = { cat = "trinkets" },  -- Placeholder: Raid trinket 3
    -- [000004] = { cat = "trinkets" },  -- Placeholder: Raid trinket 4

    -- Midnight S1 Dungeon trinkets
    -- [000005] = { cat = "trinkets" },  -- Placeholder: Dungeon trinket 1
    -- [000006] = { cat = "trinkets" },  -- Placeholder: Dungeon trinket 2
    -- [000007] = { cat = "trinkets" },  -- Placeholder: Dungeon trinket 3
    -- [000008] = { cat = "trinkets" },  -- Placeholder: Dungeon trinket 4

    -- Evergreen / PvP
    [345228] = { cat = "trinkets" },  -- Gladiator's Badge (On Use)
    [345231] = { cat = "trinkets" },  -- Gladiator's Insignia proc

    -- ═══════════════════════════════
    -- WEAPON ENCHANT PROCS (Midnight S1)
    -- TODO: Replace placeholder IDs with real Midnight S1 weapon enchant proc spellIDs
    -- ═══════════════════════════════

    -- [000010] = { cat = "enchants" },  -- Placeholder: Midnight enchant 1
    -- [000011] = { cat = "enchants" },  -- Placeholder: Midnight enchant 2
    -- [000012] = { cat = "enchants" },  -- Placeholder: Midnight enchant 3
    -- [000013] = { cat = "enchants" },  -- Placeholder: Midnight enchant 4

    -- ═══════════════════════════════
    -- SELF-BUFFS (Class Cooldowns / Personal)
    -- ═══════════════════════════════

    -- Death Knight
    [48707]  = { cat = "selfBuffs" },  -- Anti-Magic Shell
    [48792]  = { cat = "selfBuffs" },  -- Icebound Fortitude
    [55233]  = { cat = "selfBuffs" },  -- Vampiric Blood
    [49028]  = { cat = "selfBuffs" },  -- Dancing Rune Weapon
    [51271]  = { cat = "selfBuffs" },  -- Pillar of Frost
    [207289] = { cat = "selfBuffs" },  -- Unholy Assault

    -- Demon Hunter
    [187827] = { cat = "selfBuffs" },  -- Metamorphosis (Havoc)
    [162264] = { cat = "selfBuffs" },  -- Metamorphosis (Vengeance)
    [196555] = { cat = "selfBuffs" },  -- Netherwalk
    [209426] = { cat = "selfBuffs" },  -- Darkness

    -- Druid
    [194223] = { cat = "selfBuffs" },  -- Celestial Alignment
    [102558] = { cat = "selfBuffs" },  -- Incarnation: Guardian
    [102543] = { cat = "selfBuffs" },  -- Incarnation: King of the Jungle
    [106951] = { cat = "selfBuffs" },  -- Berserk (Feral)
    [61336]  = { cat = "selfBuffs" },  -- Survival Instincts
    [22812]  = { cat = "selfBuffs" },  -- Barkskin
    [29166]  = { cat = "selfBuffs" },  -- Innervate

    -- Evoker
    [375087] = { cat = "selfBuffs" },  -- Dragonrage
    [363916] = { cat = "selfBuffs" },  -- Obsidian Scales
    [370960] = { cat = "selfBuffs" },  -- Emerald Communion

    -- Hunter
    [186265] = { cat = "selfBuffs" },  -- Aspect of the Turtle
    [288613] = { cat = "selfBuffs" },  -- Trueshot
    [19574]  = { cat = "selfBuffs" },  -- Bestial Wrath
    [266779] = { cat = "selfBuffs" },  -- Coordinated Assault

    -- Mage
    [12472]  = { cat = "selfBuffs" },  -- Icy Veins
    [190319] = { cat = "selfBuffs" },  -- Combustion
    [365362] = { cat = "selfBuffs" },  -- Arcane Surge
    [45438]  = { cat = "selfBuffs" },  -- Ice Block
    [110960] = { cat = "selfBuffs" },  -- Greater Invisibility

    -- Monk
    [137639] = { cat = "selfBuffs" },  -- Storm, Earth, and Fire
    [152173] = { cat = "selfBuffs" },  -- Serenity
    [122278] = { cat = "selfBuffs" },  -- Dampen Harm
    [122783] = { cat = "selfBuffs" },  -- Diffuse Magic
    [115176] = { cat = "selfBuffs" },  -- Zen Meditation
    [243435] = { cat = "selfBuffs" },  -- Fortifying Brew

    -- Paladin
    [31884]  = { cat = "selfBuffs" },  -- Avenging Wrath
    [231895] = { cat = "selfBuffs" },  -- Crusade
    [642]    = { cat = "selfBuffs" },  -- Divine Shield
    [498]    = { cat = "selfBuffs" },  -- Divine Protection
    [86659]  = { cat = "selfBuffs" },  -- Guardian of Ancient Kings
    [1022]   = { cat = "selfBuffs" },  -- Blessing of Protection
    [6940]   = { cat = "selfBuffs" },  -- Blessing of Sacrifice

    -- Priest
    [10060]  = { cat = "selfBuffs" },  -- Power Infusion
    [47585]  = { cat = "selfBuffs" },  -- Dispersion
    [33206]  = { cat = "selfBuffs" },  -- Pain Suppression
    [47788]  = { cat = "selfBuffs" },  -- Guardian Spirit
    [194249] = { cat = "selfBuffs" },  -- Voidform

    -- Rogue
    [13750]  = { cat = "selfBuffs" },  -- Adrenaline Rush
    [121471] = { cat = "selfBuffs" },  -- Shadow Blades
    [31224]  = { cat = "selfBuffs" },  -- Cloak of Shadows
    [5277]   = { cat = "selfBuffs" },  -- Evasion
    [185311] = { cat = "selfBuffs" },  -- Crimson Vial
    [1966]   = { cat = "selfBuffs" },  -- Feint

    -- Shaman
    [114050] = { cat = "selfBuffs" },  -- Ascendance (Elemental)
    [114051] = { cat = "selfBuffs" },  -- Ascendance (Enhancement)
    [114052] = { cat = "selfBuffs" },  -- Ascendance (Restoration)
    [108271] = { cat = "selfBuffs" },  -- Astral Shift

    -- Warlock
    [104773] = { cat = "selfBuffs" },  -- Unending Resolve
    [113860] = { cat = "selfBuffs" },  -- Dark Soul: Misery
    [113858] = { cat = "selfBuffs" },  -- Dark Soul: Instability

    -- Warrior
    [1719]   = { cat = "selfBuffs" },  -- Recklessness
    [107574] = { cat = "selfBuffs" },  -- Avatar
    [12975]  = { cat = "selfBuffs" },  -- Last Stand
    [871]    = { cat = "selfBuffs" },  -- Shield Wall
    [184364] = { cat = "selfBuffs" },  -- Enraged Regeneration
    [18499]  = { cat = "selfBuffs" },  -- Berserker Rage
    [23920]  = { cat = "selfBuffs" },  -- Spell Reflection

    -- ═══════════════════════════════
    -- RAID BUFFS (party-wide)
    -- ═══════════════════════════════
    [1459]   = { cat = "raidBuffs" },  -- Arcane Intellect
    [21562]  = { cat = "raidBuffs" },  -- Power Word: Fortitude
    [6673]   = { cat = "raidBuffs" },  -- Battle Shout
    [1126]   = { cat = "raidBuffs" },  -- Mark of the Wild
    [381748] = { cat = "raidBuffs" },  -- Blessing of the Bronze
    [97463]  = { cat = "raidBuffs" },  -- Rallying Cry
    [390386] = { cat = "raidBuffs" },  -- Fury of the Aspects

    -- ═══════════════════════════════
    -- DEFENSIVES (External + Major)
    -- ═══════════════════════════════
    [33206]  = { cat = "defensives" },  -- Pain Suppression
    [47788]  = { cat = "defensives" },  -- Guardian Spirit
    [102342] = { cat = "defensives" },  -- Ironbark
    [116849] = { cat = "defensives" },  -- Life Cocoon
    [6940]   = { cat = "defensives" },  -- Blessing of Sacrifice
    [1022]   = { cat = "defensives" },  -- Blessing of Protection
    [204018] = { cat = "defensives" },  -- Blessing of Spellwarding
    [357170] = { cat = "defensives" },  -- Time Dilation (Evoker)
}

-- Build reverse lookup: spellID → category
SDB.spellIndex = {}
for id, data in pairs(SDB.spells) do
    SDB.spellIndex[id] = data.cat
end

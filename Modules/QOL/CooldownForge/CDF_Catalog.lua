-- =====================================================================
-- CooldownForge -- Catalog (racials + item presets) & resolvers
-- AstralForge Cooldown -- Lot 2. Fills the code-side catalog stubbed in
-- CDF_Core and provides racial/preset resolution. Requires CDF_Core.
-- =====================================================================

local CDF = TomoMod_CooldownForge

-- Racials by race token (as returned by UnitRace). Several candidates per
-- race (spec/variant-specific IDs, e.g. Arcane Torrent, Blood Fury); the
-- resolver picks the first the player actually knows. Data are game facts.
CDF.RACIALS = {
    Scourge            = { 7744 },
    Tauren             = { 20549 },
    Orc                = { 20572, 33697, 33702 },
    BloodElf           = { 202719, 50613, 25046, 69179, 80483, 155145, 129597, 232633, 28730 },
    Dwarf              = { 20594 },
    Troll              = { 26297 },
    Draenei            = { 28880, 59543, 59545, 121093, 59544, 370626, 59547, 59548, 59542, 416250 },
    NightElf           = { 58984 },
    Human              = { 59752 },
    DarkIronDwarf      = { 265221 },
    Gnome              = { 20589 },
    HighmountainTauren = { 255654 },
    Worgen             = { 68992 },
    Goblin             = { 69070 },
    Pandaren           = { 107079 },
    MagharOrc          = { 274738 },
    LightforgedDraenei = { 255647 },
    VoidElf            = { 256948 },
    KulTiran           = { 287712 },
    ZandalariTroll     = { 291944 },
    Vulpera            = { 312411 },
    Mechagnome         = { 312924 },
    Nightborne         = { 260364 },
    Dracthyr           = { 357214 }, -- Wing Buffet (Evokers already track it in CDM)
    EarthenDwarf       = { 436344 },
    Haranir            = { 1237885 },
}

-- Item presets. `itemIDs` = altItemIDs: the first one present in bags wins;
-- the first listed is used for icon/name when none are in bags. Health/mana
-- potion IDs are expansion-specific -- extend against the live 12.x client.
-- The resolver degrades gracefully when the list is empty or none present.
CDF.PRESETS = {
    healthstone = { name = "Healthstone",        itemIDs = { 224464, 5512 } },
    -- [S5] 12.x IDs (verified): Silvermoon Health Potion 241305 (crafted
    -- standard), Potent Healing Potion 258138 (looted fallback),
    -- Lightfused Mana Potion 241300 (vendor). Extend per patch as needed.
    healthpot   = { name = "Health Potion",       itemIDs = { 241305, 258138 } },
    manapot     = { name = "Mana Potion",         itemIDs = { 241300 } },
    invis       = { name = "Invisibility Potion", itemIDs = { 9172 } },
}

-- ---------------------------------------------------------------------
-- Resolvers
-- ---------------------------------------------------------------------
local function isKnown(sid)
    if not sid then return false end
    if IsSpellKnown and IsSpellKnown(sid) then return true end
    if IsPlayerSpell and IsPlayerSpell(sid) then return true end
    return false
end
CDF.isSpellKnown = isKnown

-- First racial spellID for the player's race that the player knows; falls
-- back to the first listed (so the icon still resolves when unknown).
function CDF.ResolveRacialSpell()
    local _, raceToken = UnitRace("player")
    local list = raceToken and CDF.RACIALS[raceToken]
    if not list then return nil end
    for i = 1, #list do
        if isKnown(list[i]) then return list[i], true end
    end
    return list[1], false
end

-- Resolve a preset key to an itemID: first present in bags, else first listed.
-- Returns itemID, present(boolean). nil if the preset/list is empty.
function CDF.ResolvePresetItemID(presetKey)
    local p = CDF.PRESETS[presetKey]
    if not p or not p.itemIDs or #p.itemIDs == 0 then return nil, false end
    if C_Item and C_Item.GetItemCount then
        for i = 1, #p.itemIDs do
            local iid = p.itemIDs[i]
            if (C_Item.GetItemCount(iid) or 0) > 0 then
                return iid, true
            end
        end
    end
    return p.itemIDs[1], false
end

-- =====================================================================
-- [S4] Spellbook library scanner (player's class only). Returns groups
-- { name, offSpecID, spells = { { spellID, name, icon } } }. Passives
-- are skipped, duplicates deduped by spellID (first line wins). No
-- cooldown-based filtering: comparing durations would mean arithmetic
-- on 12.x secret values. Cached per session; the cache is dropped on
-- SPELLS_CHANGED / PLAYER_SPECIALIZATION_CHANGED.
-- =====================================================================
-- [S8] Grimoire scan (spellbook lines). `seen` is shared with the talent
-- scan so a talent already granted through the spellbook isn't listed twice.
local function scanSpellbookInto(out, seen)
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines
            and C_SpellBook.GetSpellBookSkillLineInfo and C_SpellBook.GetSpellBookItemInfo) then
        return
    end
    local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
    local wantType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
    for li = 1, (C_SpellBook.GetNumSpellBookSkillLines() or 0) do
        local line = C_SpellBook.GetSpellBookSkillLineInfo(li)
        if line and not line.isGuild then
            local group = { name = line.name or ("Ligne " .. li), offSpecID = line.offSpecID, spells = {} }
            local off = line.itemIndexOffset or 0
            local num = line.numSpellBookItems or 0
            for j = off + 1, off + num do
                local ok, info = pcall(C_SpellBook.GetSpellBookItemInfo, j, bank)
                if ok and type(info) == "table" and info.spellID
                    and not info.isPassive and not seen[info.spellID]
                    and (wantType == nil or info.itemType == wantType) then
                    seen[info.spellID] = true
                    group.spells[#group.spells + 1] = {
                        spellID = info.spellID,
                        name    = info.name
                            or (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(info.spellID))
                            or ("Sort " .. info.spellID),
                        icon    = info.iconID,
                    }
                end
            end
            if #group.spells > 0 then out[#out + 1] = group end
        end
    end
end

-- [S8] Talent + hero-talent scan (C_Traits). Only COMMITTED, ACTIVE
-- (non-passive) talents are listed; every call is pcall-guarded, and
-- spellIDs already in `seen` (grimoire) are skipped. Hero-talent nodes
-- (identified by their subTreeID) go into a separate group.
local function scanTalentsInto(out, seen)
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID
            and C_Traits and C_Traits.GetConfigInfo and C_Traits.GetTreeNodes
            and C_Traits.GetNodeInfo and C_Traits.GetEntryInfo and C_Traits.GetDefinitionInfo) then
        return
    end
    local okC, configID = pcall(C_ClassTalents.GetActiveConfigID)
    if not okC or not configID then return end
    local okI, configInfo = pcall(C_Traits.GetConfigInfo, configID)
    if not okI or type(configInfo) ~= "table" or type(configInfo.treeIDs) ~= "table" then return end

    local heroSpecID
    if C_ClassTalents.GetActiveHeroTalentSpec then
        local okH, h = pcall(C_ClassTalents.GetActiveHeroTalentSpec)
        if okH then heroSpecID = h end
    end

    local talents = { name = "Talents", spells = {} }
    local hero    = { name = "Talents heroiques", spells = {} }

    local function addSpell(group, spellID)
        if not spellID or seen[spellID] then return end
        -- skip passives (no cooldown to track)
        if C_Spell and C_Spell.IsSpellPassive then
            local okP, passive = pcall(C_Spell.IsSpellPassive, spellID)
            if okP and passive then return end
        end
        seen[spellID] = true
        local name
        if C_Spell and C_Spell.GetSpellName then
            local okN, n = pcall(C_Spell.GetSpellName, spellID)
            if okN then name = n end
        end
        local icon
        if C_Spell and C_Spell.GetSpellTexture then
            local okT, t = pcall(C_Spell.GetSpellTexture, spellID)
            if okT then icon = t end
        end
        group.spells[#group.spells + 1] = {
            spellID = spellID,
            name    = name or ("Sort " .. spellID),
            icon    = icon,
        }
    end

    for _, treeID in ipairs(configInfo.treeIDs) do
        local okN, nodes = pcall(C_Traits.GetTreeNodes, treeID)
        if okN and type(nodes) == "table" then
            for _, nodeID in ipairs(nodes) do
                local okNI, nodeInfo = pcall(C_Traits.GetNodeInfo, configID, nodeID)
                if okNI and type(nodeInfo) == "table" then
                    local isHero = heroSpecID and nodeInfo.subTreeID
                        and nodeInfo.subTreeID == heroSpecID
                    local entries = nodeInfo.entryIDsWithCommittedRanks
                    if type(entries) == "table" then
                        for _, entryID in ipairs(entries) do
                            local okE, entryInfo = pcall(C_Traits.GetEntryInfo, configID, entryID)
                            if okE and type(entryInfo) == "table" and entryInfo.definitionID then
                                local okD, def = pcall(C_Traits.GetDefinitionInfo, entryInfo.definitionID)
                                if okD and type(def) == "table" and def.spellID then
                                    addSpell(isHero and hero or talents, def.spellID)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if #talents.spells > 0 then out[#out + 1] = talents end
    if #hero.spells   > 0 then out[#out + 1] = hero end
end

function CDF.ScanSpellbook()
    if CDF._libCache then return CDF._libCache end
    local out = {}
    CDF._libCache = out
    local seen = {}
    scanSpellbookInto(out, seen)
    scanTalentsInto(out, seen)
    return out
end

local libEv = CreateFrame("Frame")
libEv:RegisterEvent("SPELLS_CHANGED")
libEv:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
-- [S8] talent changes invalidate the library cache too. Guard optional
-- events: registering an unknown event errors in WoW.
local function tryReg(ev)
    if C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(ev) then return end
    pcall(libEv.RegisterEvent, libEv, ev)
end
tryReg("TRAIT_CONFIG_UPDATED")
libEv:SetScript("OnEvent", function() CDF._libCache = nil end)
CDF._libEvFrame = libEv

-- =====================================================================
-- [S5] Bar blueprints: complete, ready-to-use bars created in one click
-- from the studio sidebar. Pure data + a small factory over the existing
-- CRUD; entries go through NewEntrySchema/SanitizeBar like everything.
-- =====================================================================
CDF.BAR_BLUEPRINTS = {
    conso = {
        name = "Consommables",
        iconSize = 34,
        entries = {
            { kind = "itemPreset", preset = "healthstone" },
            { kind = "itemPreset", preset = "healthpot" },
            { kind = "itemPreset", preset = "manapot" },
            { kind = "itemPreset", preset = "invis" },
        },
    },
    utils = {
        name = "Utilitaires",
        iconSize = 36,
        entries = {
            { kind = "equippedTrinket", slot = 13 },
            { kind = "equippedTrinket", slot = 14 },
            { kind = "racial" },
        },
    },
}

-- Creates the blueprint as a new bar for `class`; returns the new bar id.
function CDF.CreateBarFromBlueprint(class, key)
    local bp = CDF.BAR_BLUEPRINTS[key]
    if not bp then return nil end
    local bar, id = CDF.CreateBar(class, bp.name)
    if not bar then return nil end
    if bp.iconSize then bar.iconSize = bp.iconSize end
    for _, e in ipairs(bp.entries) do
        bar.entries[#bar.entries + 1] = CDF.NewEntrySchema(e)
    end
    CDF.SanitizeBar(bar)
    return id
end

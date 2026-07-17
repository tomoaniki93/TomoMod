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
    healthpot   = { name = "Health Potion",       itemIDs = {} },  -- TODO: fill 12.x IDs
    manapot     = { name = "Mana Potion",         itemIDs = {} },  -- TODO: fill 12.x IDs
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

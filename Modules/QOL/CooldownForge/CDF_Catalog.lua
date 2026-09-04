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
                -- [fix] Only nodes actually taken (currentRank > 0), and read
                -- the SELECTED entry via activeEntry.entryID. The previous field,
                -- entryIDsWithCommittedRanks, is not reliably populated outside a
                -- preview/loadout context, so in-game the scan found nothing.
                -- Fall back to that list only if activeEntry is missing.
                if okNI and type(nodeInfo) == "table"
                   and nodeInfo.currentRank and nodeInfo.currentRank > 0 then
                    local isHero = heroSpecID and nodeInfo.subTreeID
                        and nodeInfo.subTreeID == heroSpecID

                    local entryIDs = {}
                    if nodeInfo.activeEntry and nodeInfo.activeEntry.entryID then
                        entryIDs[1] = nodeInfo.activeEntry.entryID
                    elseif type(nodeInfo.entryIDsWithCommittedRanks) == "table" then
                        entryIDs = nodeInfo.entryIDsWithCommittedRanks
                    end

                    for _, entryID in ipairs(entryIDs) do
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

-- =====================================================================
-- [S6] Import from Blizzard's Cooldown Manager
--
-- Blizzard curates three category sets per spec -- Essential, Utility and
-- Tracked Buffs -- and keeps them current across reworks. Rebuilding that
-- list by hand is exactly the "no hardcoded rotting data" trap, so the
-- import reads the live category set instead of shipping spell tables.
--
-- Category names, not numbers: Enum.CooldownViewerCategory members get
-- renumbered between builds, so we resolve by key and skip anything the
-- running client does not expose.
CDF.VIEWER_IMPORTS = {
    essential = { enumKey = "Essential",   name = "Essentiels",  iconSize = 36 },
    utility   = { enumKey = "Utility",     name = "Utilitaires", iconSize = 34 },
    -- Blizzard calls this "Tracked Buffs" in the UI and TrackedBuff in the
    -- enum; entries come in as auras rather than plain cooldowns.
    buff      = { enumKey = "TrackedBuff", name = "Buffs suivis", iconSize = 34, aura = true },
}

-- Returns the spell ids Blizzard currently lists for `key`, in its order,
-- plus a status string: "ok", "noapi" or "empty".
function CDF.GetViewerSpellIDs(key)
    local def = CDF.VIEWER_IMPORTS[key]
    if not def then return nil, "noapi" end

    local CV = C_CooldownViewer
    if not (CV and CV.GetCooldownViewerCategorySet and CV.GetCooldownViewerCooldownInfo) then
        return nil, "noapi"
    end
    local cats = Enum and Enum.CooldownViewerCategory
    if type(cats) ~= "table" then return nil, "noapi" end

    local cat = cats[def.enumKey]
    if cat == nil then return nil, "noapi" end

    local ok, ids = pcall(CV.GetCooldownViewerCategorySet, cat)
    if not ok or type(ids) ~= "table" then return nil, "empty" end

    local out, seen = {}, {}
    for _, cdID in ipairs(ids) do
        local ok2, info = pcall(CV.GetCooldownViewerCooldownInfo, cdID)
        if ok2 and type(info) == "table" then
            -- overrideSpellID is what the player actually casts when a
            -- talent replaces the base ability; prefer it so the icon
            -- matches the spellbook.
            local spellID = tonumber(info.overrideSpellID) or tonumber(info.spellID)
            if spellID and not seen[spellID] then
                seen[spellID] = true
                out[#out + 1] = spellID
            end
        end
    end
    if #out == 0 then return nil, "empty" end
    return out, "ok"
end

-- Creates a bar from a Blizzard viewer category. Returns the new bar id
-- and how many entries were imported, or nil plus a status on failure.
function CDF.CreateBarFromViewer(class, key)
    local def = CDF.VIEWER_IMPORTS[key]
    if not def then return nil, "noapi" end

    local ids, status = CDF.GetViewerSpellIDs(key)
    if not ids then return nil, status end

    local bar, id = CDF.CreateBar(class, def.name)
    if not bar then return nil, "empty" end
    if def.iconSize then bar.iconSize = def.iconSize end

    -- Remembering the source is what makes the bar re-syncable later.
    bar.viewerSource = key

    for _, spellID in ipairs(ids) do
        bar.entries[#bar.entries + 1] = CDF.NewEntrySchema({
            kind = "spell",
            id   = spellID,
            -- Tracked buffs behave like auras: visible while up, with the
            -- remaining time, rather than as a plain cooldown swipe.
            mode = def.aura and "aura" or nil,
            -- Marks the entry as Blizzard's, not the player's. Resync only
            -- ever removes entries carrying this flag.
            fromViewer = true,
        })
    end
    CDF.SanitizeBar(bar)
    return id, #ids
end

-- Re-reads the category and reconciles the bar against it.
--
-- Deliberately a reconcile, not a rebuild. A player who imported a bar
-- then spent ten minutes setting glow conditions and spec visibility would
-- not forgive a button that threw all of it away, so:
--   * spells still listed keep their entry untouched, overrides included
--   * spells newly listed are appended in Blizzard's order
--   * entries flagged fromViewer that Blizzard dropped are removed
--   * anything the player added by hand is never touched, and keeps its
--     relative order after the imported block
--
-- Returns added, removed, kept -- or nil plus a status.
function CDF.ResyncBarFromViewer(class, barId)
    local bars = CDF.GetClassBars(class)
    local bar
    for _, b in ipairs(bars or {}) do
        if b.id == barId then bar = b; break end
    end
    if not bar or not bar.viewerSource then return nil, "notimported" end

    local def = CDF.VIEWER_IMPORTS[bar.viewerSource]
    if not def then return nil, "noapi" end

    local ids, status = CDF.GetViewerSpellIDs(bar.viewerSource)
    if not ids then return nil, status end

    local live = {}
    for _, spellID in ipairs(ids) do live[spellID] = true end

    -- Index the entries we already hold, so a kept spell reuses its entry
    -- object rather than a fresh one.
    local existing = {}
    for _, e in ipairs(bar.entries or {}) do
        if e.kind == "spell" and e.id then existing[e.id] = e end
    end

    local imported, manual = {}, {}
    local removed = 0
    for _, e in ipairs(bar.entries or {}) do
        if e.fromViewer then
            if not (e.kind == "spell" and e.id and live[e.id]) then
                removed = removed + 1
            end
        else
            manual[#manual + 1] = e
        end
    end

    local added, kept = 0, 0
    for _, spellID in ipairs(ids) do
        local e = existing[spellID]
        if e and e.fromViewer then
            kept = kept + 1
        elseif e then
            -- The player had already added this spell by hand. Leave it in
            -- their block and do not claim it: adopting it would mean a
            -- later resync could delete an entry they created.
            e = nil
        else
            e = CDF.NewEntrySchema({
                kind = "spell",
                id   = spellID,
                mode = def.aura and "aura" or nil,
                fromViewer = true,
            })
            added = added + 1
        end
        if e then imported[#imported + 1] = e end
    end

    local out = {}
    for _, e in ipairs(imported) do out[#out + 1] = e end
    for _, e in ipairs(manual)   do out[#out + 1] = e end
    bar.entries = out

    CDF.SanitizeBar(bar)
    return added, removed, kept
end

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

-- =====================================================================
-- [P3] Contextual cooldown preset packs
--
-- One pack is three normal bars, all tied to the same specialization and
-- position. Existing bar-level visibility does the runtime switching:
--   solo  -> Minimal   (not in a group)
--   party -> Mythic+   (in a group, but not a raid)
--   raid  -> Raid      (in a raid)
--
-- Spell data is read from Blizzard's live Cooldown Manager categories, so
-- class/spec reworks do not require a hardcoded spell table in TomoMod.
-- =====================================================================
CDF.CONTEXT_PRESET_PROFILES = {
    solo = {
        categories = { "essential" },
        visibility = { inGroup = false },
        iconSize = 36,
    },
    party = {
        categories = { "essential", "utility" },
        visibility = { inGroup = true, inRaid = false },
        iconSize = 36,
    },
    raid = {
        categories = { "essential", "utility", "buff" },
        visibility = { inRaid = true },
        iconSize = 36,
    },
}
CDF.CONTEXT_PRESET_ORDER = { "solo", "party", "raid" }

local function contextEntryKey(spellID, mode)
    return tostring(tonumber(spellID) or 0) .. ":" .. tostring(mode or "cooldown")
end

-- Returns ordered desired entries for a profile, or nil + noapi/empty.
-- Each item is { id, mode, source } and is still pure data at this stage.
function CDF.GetContextPresetProfileData(profileKey)
    local profile = CDF.CONTEXT_PRESET_PROFILES[profileKey]
    if not profile then return nil, "empty" end

    local out, seen = {}, {}
    local sawAPI = false
    for _, sourceKey in ipairs(profile.categories or {}) do
        local ids, status = CDF.GetViewerSpellIDs(sourceKey)
        if status ~= "noapi" then sawAPI = true end
        if ids then
            local sourceDef = CDF.VIEWER_IMPORTS[sourceKey]
            local mode = sourceDef and sourceDef.aura and "aura" or nil
            for _, spellID in ipairs(ids) do
                local key = contextEntryKey(spellID, mode)
                if not seen[key] then
                    seen[key] = true
                    out[#out + 1] = {
                        id = spellID,
                        mode = mode,
                        source = sourceKey,
                    }
                end
            end
        end
    end

    if #out == 0 then return nil, sawAPI and "empty" or "noapi" end
    return out, "ok"
end

function CDF.ContextPresetPackID(class, specID)
    class = class or CDF.PlayerClass() or "UNKNOWN"
    return "tm_context_" .. tostring(class) .. "_" .. tostring(tonumber(specID) or 0)
end

-- Returns a table keyed solo/party/raid. Missing members stay nil so an
-- interrupted/deleted pack can be repaired by InstallContextPresetPack.
function CDF.FindContextPresetPack(class, specID)
    local out = {}
    local packID = CDF.ContextPresetPackID(class, specID)
    for _, bar in ipairs(CDF.GetClassBars(class) or {}) do
        if bar.contextPackID == packID and CDF.CONTEXT_PRESET_PROFILES[bar.contextProfile] then
            out[bar.contextProfile] = bar
        end
    end
    return out
end

local function copyContextVisuals(src, dst)
    if not (src and dst) then return end
    for _, key in ipairs({
        "layout", "orientation", "growth", "iconSize", "iconWidth", "iconHeight",
        "spacing", "spacingCross", "wrap", "radial", "hideOnCooldown", "hideOnUnusable",
        "glow", "swipe", "text", "style", "position",
    }) do
        local v = src[key]
        if type(v) == "table" then
            dst[key] = CopyTable(v)
        elseif v ~= nil then
            dst[key] = v
        end
    end
end

local function reconcileContextEntries(bar, specID, desired)
    local generated, manual, manualKeys = {}, {}, {}
    local oldGenerated = 0

    for _, entry in ipairs(bar.entries or {}) do
        if entry.fromContextPreset then
            oldGenerated = oldGenerated + 1
            if entry.kind == "spell" and entry.id then
                generated[contextEntryKey(entry.id, entry.mode)] = entry
            end
        else
            manual[#manual + 1] = entry
            if entry.kind == "spell" and entry.id then
                manualKeys[contextEntryKey(entry.id, entry.mode)] = true
            end
        end
    end

    local imported = {}
    local added, kept, keptGenerated = 0, 0, 0
    for _, want in ipairs(desired) do
        local key = contextEntryKey(want.id, want.mode)
        local entry = generated[key]
        if entry then
            kept = kept + 1
            keptGenerated = keptGenerated + 1
        elseif manualKeys[key] then
            -- The player already owns an equivalent manual entry. Do not
            -- duplicate it and never adopt it into the generated block.
            kept = kept + 1
        else
            entry = CDF.NewEntrySchema({
                kind = "spell",
                id = want.id,
                spec = specID,
                mode = want.mode,
            })
            entry.fromContextPreset = true
            entry.contextSource = want.source
            added = added + 1
        end

        if entry then
            entry.spec = specID
            entry.mode = want.mode
            entry.fromContextPreset = true
            entry.contextSource = want.source
            imported[#imported + 1] = entry
        end
    end

    local removed = math.max(0, oldGenerated - keptGenerated)
    local out = {}
    for _, entry in ipairs(imported) do out[#out + 1] = entry end
    for _, entry in ipairs(manual) do out[#out + 1] = entry end
    bar.entries = out
    return added, removed, kept
end

-- Installs or updates the three-bar pack for the CURRENT character/spec.
-- Existing generated entries are reconciled in place, preserving per-entry
-- overrides. Manual entries are never removed. Returns barsByProfile, stats.
function CDF.InstallContextPresetPack(class, specID, names)
    class = class or CDF.PlayerClass()
    specID = tonumber(specID) or 0
    if class ~= CDF.PlayerClass() then return nil, "wrongclass" end
    local currentSpec = CDF.CurrentSpecID and CDF.CurrentSpecID() or 0
    if specID == 0 or currentSpec ~= specID then return nil, "wrongspec" end

    -- Read every profile before mutating the DB. If Blizzard has not finished
    -- populating a category set yet, an update must not erase a valid pack.
    local desired = {}
    for _, profileKey in ipairs(CDF.CONTEXT_PRESET_ORDER) do
        local data, status = CDF.GetContextPresetProfileData(profileKey)
        if not data then return nil, status end
        desired[profileKey] = data
    end

    local packID = CDF.ContextPresetPackID(class, specID)
    local bars = CDF.FindContextPresetPack(class, specID)
    local template = bars.solo or bars.party or bars.raid
    local stats = {}

    for _, profileKey in ipairs(CDF.CONTEXT_PRESET_ORDER) do
        local profile = CDF.CONTEXT_PRESET_PROFILES[profileKey]
        local bar = bars[profileKey]
        local isNew = false
        if not bar then
            local b = CDF.CreateBar(class,
                (names and names[profileKey]) or ("Context " .. profileKey))
            bar = b
            if not bar then return nil, "create" end
            isNew = true
            if template then copyContextVisuals(template, bar) end
            bars[profileKey] = bar
            if not template then template = bar end
        end

        bar.contextPreset = true
        bar.contextPackID = packID
        bar.contextProfile = profileKey
        bar.contextSpecID = specID
        if isNew and profile.iconSize then
            bar.iconSize = profile.iconSize
        end
        bar.visibility = CopyTable(profile.visibility or {})

        local added, removed, kept = reconcileContextEntries(bar, specID, desired[profileKey])
        CDF.SanitizeBar(bar)
        stats[profileKey] = { added = added, removed = removed, kept = kept, total = #desired[profileKey] }
    end

    -- Context bars are one visual element. Keep every member on the same
    -- anchor immediately; CDF_Movers keeps them linked after the player moves it.
    local anchor = bars.solo or bars.party or bars.raid
    if anchor and anchor.position then
        for _, profileKey in ipairs(CDF.CONTEXT_PRESET_ORDER) do
            local bar = bars[profileKey]
            if bar then bar.position = CopyTable(anchor.position) end
        end
    end

    return bars, stats
end

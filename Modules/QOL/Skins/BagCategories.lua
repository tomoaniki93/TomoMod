-- =====================================
-- BagCategories.lua
-- Locale-safe category manager for the TomoMod bag rework (sidebar layout).
-- Categories are identified by STABLE internal keys (locale-independent) and
-- classified via Enum.ItemClass numeric IDs, so detection never depends on a
-- localized type string. Users can rename, reorder, group, disable, create
-- custom categories, and assign individual items to a category.
--
-- Inspired by the organization model of EllesmereUIBags, fully reimplemented
-- for TomoMod (no shared code).
--
-- Public API: TomoMod_BagCategories
--   :GetCategories()                      -> ordered runtime list
--   :GetCategoryCount()
--   :IndexOfKey(key) / :GetSpecialIndex(flag)
--   :ClassifyItem(itemLink, itemID, bag, slot, quality) -> category index
--   :ClassifyAll(items)                   -> counts, total (sets .categoryIndex)
--   :RenameCategory / :ReorderCategory
--   :GroupCategories / :AddToGroup / :UngroupCategory / :DisbandGroup
--   :RenameGroup / :GetGroupNames / :GetGroupMembers / :IsGrouped
--   :AddCustomCategory / :RemoveCustomCategory
--   :AssignItem / :UnassignItem / :CanAssignToCategory
--   :ToggleDisabled / :IsDisabled
--   :TogglePin / :IsPinned / :GetPinCount / :SeedDefaultPins
--   :SnapshotKnownIDs / :DetectNewItems / :GetRecentSet / :IsRecent / :ResetRecent
--   :InitCategories / :SaveState
-- =====================================

TomoMod_BagCategories = TomoMod_BagCategories or {}
local BC = TomoMod_BagCategories
local L  = TomoMod_L

-- =====================================
-- SETTINGS ACCESS
-- All bag data lives under TomoModDB.bagSkin (account-scoped, like the rest of
-- the bag module). TomoModDB may not exist yet at file-load time (SavedVariables
-- load at ADDON_LOADED); reads then return defaults and writes are no-ops until
-- the first post-login user action.
-- =====================================

local _emptyS = {}
local function S()
    if not TomoModDB then return _emptyS end
    TomoModDB.bagSkin = TomoModDB.bagSkin or {}
    return TomoModDB.bagSkin
end

-- =====================================
-- ITEM CLASS CONSTANTS (locale-independent, Midnight-ready)
-- =====================================

local IC = Enum and Enum.ItemClass or {}
local IC_CONSUMABLE   = IC.Consumable      or 0
local IC_CONTAINER    = IC.Container       or 1
local IC_WEAPON       = IC.Weapon          or 2
local IC_GEM          = IC.Gem             or 3
local IC_ARMOR        = IC.Armor           or 4
local IC_REAGENT      = IC.Reagent         or 5
local IC_TRADEGOODS   = IC.Tradegoods      or 7
local IC_ITEMENHANCE  = IC.ItemEnhancement or 8
local IC_RECIPE       = IC.Recipe          or 9
local IC_QUESTITEM    = IC.Questitem       or 12
local IC_MISC         = IC.Miscellaneous   or 15
local IC_BATTLEPET    = IC.Battlepet       or IC.BattlePet or 17
local IC_PROFESSION   = IC.Profession      or 19   -- Midnight
local IC_HOUSING      = IC.Housing         or 20   -- Midnight

-- Reagent bag index (bag 5 in retail). Items physically in the reagent bag are
-- always routed to the Reagent Bag category regardless of class.
local REAGENT_BAG_ID = (Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag) or 5

-- =====================================
-- LOCALIZED NAME HELPER
-- =====================================

local function CN(key, fallback)
    return (L and L[key]) or fallback
end

-- =====================================
-- DEFAULT CATEGORIES
-- key      : stable, locale-independent identifier (DB keys reference this)
-- nameKey  : locale string key; fallback is the English default
-- icon     : fileID (number) or atlas name (string); isAtlas marks atlas strings
-- match metadata (one of):
--   types            : list of Enum.ItemClass IDs that match
--   equipSlots       : also match items of other classes with these equip slots
--   excludeEquipSlots: reject matching items that have these equip slots
--   isJunk           : matches quality == 0 (poor)
--   isQuest          : matches quest items (via GetContainerItemQuestInfo)
--   isSetGear        : matches gear that belongs to an equipment set
--   isCatchAll       : final fallback (matches anything left)
-- special flags:
--   isPinned/isRecent: virtual buckets filled by the render pipeline, never
--                      matched by ClassifyItem
--   isReagentBag     : positional bucket (bag == REAGENT_BAG_ID)
--   noGroup          : cannot be put into a group
--   noMove           : pinned to the top, cannot be reordered
--
-- NOTE on icons: the values below are placeholders (questionmark, fileID 134400).
-- Final per-category icons are chosen in the sidebar increment, where the
-- renderer also self-heals invalid atlases (falls back to 134400). Editing one
-- table here is all it takes to retheme.
-- =====================================

local QUESTIONMARK = 134400

local DEFAULT_CATEGORIES = {
    { key = "pinned",      nameKey = "bagcat_pinned",      fallback = "Pinned",             icon = QUESTIONMARK, isPinned = true,  noGroup = true, noMove = true },
    { key = "recent",      nameKey = "bagcat_recent",      fallback = "Recent",             icon = QUESTIONMARK, isRecent = true,  noGroup = true, noMove = true },
    { key = "reagentBag",  nameKey = "bagcat_reagentbag",  fallback = "Reagent Bag",        icon = QUESTIONMARK, isReagentBag = true, noGroup = true },
    { key = "setGear",     nameKey = "bagcat_setgear",     fallback = "Equipment Sets",     icon = QUESTIONMARK, isSetGear = true },
    { key = "quest",       nameKey = "bagcat_quest",       fallback = "Quest",              icon = QUESTIONMARK, isQuest = true, types = { IC_QUESTITEM } },
    { key = "weapons",     nameKey = "bagcat_weapons",     fallback = "Weapons & Trinkets", icon = QUESTIONMARK, types = { IC_WEAPON }, equipSlots = { "INVTYPE_TRINKET" } },
    { key = "armor",       nameKey = "bagcat_armor",       fallback = "Armor",              icon = QUESTIONMARK, types = { IC_ARMOR }, excludeEquipSlots = { "INVTYPE_TRINKET" } },
    { key = "consumables", nameKey = "bagcat_consumables", fallback = "Consumables",        icon = QUESTIONMARK, types = { IC_CONSUMABLE } },
    { key = "tradeGoods",  nameKey = "bagcat_tradegoods",  fallback = "Trade Goods",        icon = QUESTIONMARK, types = { IC_TRADEGOODS, IC_REAGENT } },
    { key = "gemsEnhance", nameKey = "bagcat_gems",        fallback = "Gems & Enhancements",icon = QUESTIONMARK, types = { IC_GEM, IC_ITEMENHANCE } },
    { key = "professions", nameKey = "bagcat_professions", fallback = "Professions",        icon = QUESTIONMARK, types = { IC_PROFESSION, IC_RECIPE } },
    { key = "battlePets",  nameKey = "bagcat_pets",        fallback = "Battle Pets",        icon = QUESTIONMARK, types = { IC_BATTLEPET } },
    { key = "housing",     nameKey = "bagcat_housing",     fallback = "Housing",            icon = QUESTIONMARK, types = { IC_HOUSING } },
    { key = "junk",        nameKey = "bagcat_junk",        fallback = "Junk",               icon = QUESTIONMARK, isJunk = true },
    { key = "misc",        nameKey = "bagcat_misc",        fallback = "Miscellaneous",      icon = QUESTIONMARK, types = { IC_MISC, IC_CONTAINER }, isCatchAll = true },
}

-- Fast lookup of default definitions by key
local DEF_BY_KEY = {}
for _, def in ipairs(DEFAULT_CATEGORIES) do
    DEF_BY_KEY[def.key] = def
end

-- =====================================
-- DEFAULT PINNED ITEMS (seeded once on first ever bag open)
-- =====================================

local DEFAULT_PINS = {
    [6948] = 1,   -- Hearthstone
}

-- =====================================
-- STATE
-- =====================================

BC._categories = BC._categories or nil   -- runtime ordered list (lazy-built)

-- Recent items: session-only (reset on /reload)
BC._recentSet   = BC._recentSet   or {}   -- [itemID] = true
BC._recentOrder = BC._recentOrder or {}   -- ordered itemIDs (oldest first)
local RECENT_MAX = 12
local _knownIDs  = {}                      -- [itemID] = true (snapshot of all bag IDs)
local _snapshotReady = false

-- =====================================
-- INTERNAL HELPERS
-- =====================================

local function IsGearItem(itemLink)
    if not itemLink then return false end
    local _, _, _, _, _, classID = GetItemInfoInstant(itemLink)
    return classID == IC_WEAPON or classID == IC_ARMOR
end

-- Build a runtime category entry from a default definition + saved user state.
local function MakeFromDefault(def, state)
    return {
        key               = def.key,
        name              = (state and state.rename) or CN(def.nameKey, def.fallback),
        icon              = def.icon,
        isAtlas           = def.isAtlas,
        types             = def.types,
        equipSlots        = def.equipSlots,
        excludeEquipSlots = def.excludeEquipSlots,
        isJunk            = def.isJunk,
        isQuest           = def.isQuest,
        isSetGear         = def.isSetGear,
        isCatchAll        = def.isCatchAll,
        isPinned          = def.isPinned,
        isRecent          = def.isRecent,
        isReagentBag      = def.isReagentBag,
        noGroup           = def.noGroup,
        noMove            = def.noMove,
        groupName         = state and state.groupName,
        groupNameCustom   = state and state.groupNameCustom,
    }
end

-- Build a runtime entry for a user-created custom category.
local function MakeCustom(uc, state)
    local icon = uc.icon or QUESTIONMARK
    return {
        key             = uc.key,
        name            = (state and state.rename) or uc.name,
        icon            = icon,
        isAtlas         = (type(icon) == "string") or nil,
        types           = {},          -- custom categories match only via item assignment
        isUserCreated   = true,
        groupName       = state and state.groupName,
        groupNameCustom = state and state.groupNameCustom,
    }
end

-- =====================================
-- INIT (lazy): build the ordered runtime list from defaults + saved state.
-- Saved state is keyed by the stable category key, so renames never break
-- persistence and adding/removing default categories in a future version is
-- forward-compatible.
-- =====================================

function BC:InitCategories()
    local s = S()
    local userState = s.catState or {}      -- [key] = { rename, groupName, groupNameCustom }
    local userOrder = s.catOrder            -- ordered list of keys
    local userCats  = s.userCats            -- { { key, name, icon }, ... }

    local customByKey = {}
    if userCats then
        for _, uc in ipairs(userCats) do customByKey[uc.key] = uc end
    end

    -- 1. Establish display order
    local ordered = {}                       -- list of { def=, custom= } in order
    local seen = {}
    if userOrder and #userOrder > 0 then
        for _, key in ipairs(userOrder) do
            if DEF_BY_KEY[key] then
                ordered[#ordered + 1] = { def = DEF_BY_KEY[key] }
                seen[key] = true
            elseif customByKey[key] then
                ordered[#ordered + 1] = { custom = customByKey[key] }
                seen[key] = true
            end
        end
        -- Append any built-in defaults missing from the saved order (new in an
        -- update): catch-all stays last, everything else before it.
        for _, def in ipairs(DEFAULT_CATEGORIES) do
            if not seen[def.key] then
                local insertIdx = #ordered + 1
                if not def.isCatchAll then
                    for i, e in ipairs(ordered) do
                        if e.def and e.def.isCatchAll then insertIdx = i; break end
                    end
                end
                table.insert(ordered, insertIdx, { def = def })
            end
        end
        -- Append any custom categories created since the last save
        if userCats then
            for _, uc in ipairs(userCats) do
                if not seen[uc.key] then
                    local insertIdx = #ordered + 1
                    for i, e in ipairs(ordered) do
                        if e.def and e.def.isCatchAll then insertIdx = i; break end
                    end
                    table.insert(ordered, insertIdx, { custom = uc })
                end
            end
        end
    else
        for _, def in ipairs(DEFAULT_CATEGORIES) do
            ordered[#ordered + 1] = { def = def }
        end
    end

    -- 2. Force noMove categories to the top, in their DEFAULT_CATEGORIES order
    local top, rest = {}, {}
    for _, e in ipairs(ordered) do
        if e.def and e.def.noMove then top[e.def.key] = e end
    end
    local finalOrder = {}
    for _, def in ipairs(DEFAULT_CATEGORIES) do
        if def.noMove and top[def.key] then finalOrder[#finalOrder + 1] = top[def.key] end
    end
    for _, e in ipairs(ordered) do
        if not (e.def and e.def.noMove) then finalOrder[#finalOrder + 1] = e end
    end

    -- 3. Materialize runtime entries
    local cats = {}
    for _, e in ipairs(finalOrder) do
        if e.def then
            cats[#cats + 1] = MakeFromDefault(e.def, userState[e.def.key])
        elseif e.custom then
            cats[#cats + 1] = MakeCustom(e.custom, userState[e.custom.key])
        end
    end

    self._categories = cats
    return cats
end

-- =====================================
-- SAVE STATE (renames, order, groups, custom list) back to DB
-- =====================================

function BC:SaveState()
    local cats = self._categories
    if not cats then return end
    if not TomoModDB then return end
    local s = S()

    -- Built-in categories persist a rename only when it differs from the
    -- localized default. Custom categories store their name in s.userCats
    -- (rebuilt below), so they never need a catState.rename entry.
    local state, order = {}, {}
    for _, cat in ipairs(cats) do
        order[#order + 1] = cat.key
        local entry, has = {}, false
        if not cat.isUserCreated then
            local def = DEF_BY_KEY[cat.key]
            local defaultName = def and CN(def.nameKey, def.fallback) or nil
            if defaultName and cat.name ~= defaultName then
                entry.rename = cat.name; has = true
            end
        end
        if cat.groupName then entry.groupName = cat.groupName; has = true end
        if cat.groupNameCustom then entry.groupNameCustom = cat.groupNameCustom; has = true end
        if has then state[cat.key] = entry end
    end
    s.catState = state
    s.catOrder = order

    -- Rebuild the user-created list from runtime state
    local ucList = {}
    for _, cat in ipairs(cats) do
        if cat.isUserCreated then
            ucList[#ucList + 1] = { key = cat.key, name = cat.name, icon = cat.icon }
        end
    end
    s.userCats = (#ucList > 0) and ucList or nil
end

-- =====================================
-- ACCESSORS
-- =====================================

function BC:GetCategories()
    if not self._categories then self:InitCategories() end
    return self._categories
end

function BC:GetCategoryCount()
    return #self:GetCategories()
end

function BC:IndexOfKey(key)
    local cats = self:GetCategories()
    for i, cat in ipairs(cats) do
        if cat.key == key then return i end
    end
    return nil
end

-- Find the index of a special bucket by its flag name ("isPinned", "isRecent",
-- "isReagentBag", "isCatchAll"). Used by the render pipeline.
function BC:GetSpecialIndex(flag)
    local cats = self:GetCategories()
    for i, cat in ipairs(cats) do
        if cat[flag] then return i end
    end
    return nil
end

-- =====================================
-- CLASSIFICATION
-- =====================================

-- Equipment-set gear lookup: rebuilt once per ClassifyAll pass.
local _setGearLookup = {}

local function BuildSetGearLookup()
    wipe(_setGearLookup)
    if not (C_EquipmentSet and C_EquipmentSet.GetEquipmentSetIDs) then return end
    local ids = C_EquipmentSet.GetEquipmentSetIDs()
    if not ids then return end
    for _, setID in ipairs(ids) do
        local locs = C_EquipmentSet.GetItemLocations(setID)
        if locs then
            for _, loc in pairs(locs) do
                if loc and loc > 0 and EquipmentManager_UnpackLocation then
                    local player, bank, bags, voidStorage, slot, bag = EquipmentManager_UnpackLocation(loc)
                    if bags and bag and slot then
                        _setGearLookup[bag * 1000 + slot] = true
                    end
                end
            end
        end
    end
end

-- Optional manual itemID -> Enum.ItemClass overrides (e.g. items Blizzard
-- mis-classifies). Kept tiny; users override via item assignment instead.
local ITEM_TYPE_OVERRIDES = {}

-- Classify one item to a category index. Order of precedence:
--   1. reagent bag (physical)   2. user item assignment   3. manual override
--   4. quest                    5. equipment-set gear     6. first matching
--      category in display order (junk/type rules)        7. catch-all
-- Pinned/recent are NOT handled here (virtual buckets filled by the pipeline).
function BC:ClassifyItem(itemLink, itemID, bag, slot, quality)
    if not itemLink then return nil end
    local cats = self:GetCategories()

    -- 1. Reagent bag -> Reagent Bag category
    if bag == REAGENT_BAG_ID then
        for i, cat in ipairs(cats) do
            if cat.isReagentBag then return i end
        end
    end

    -- 2. User assignment (overrides auto-classification)
    if itemID then
        local assign = S().itemAssign
        local key = assign and assign[itemID]
        if key then
            local idx = self:IndexOfKey(key)
            if idx then return idx end
        end
    end

    -- 3. Manual override table
    if itemID and ITEM_TYPE_OVERRIDES[itemID] then
        local oc = ITEM_TYPE_OVERRIDES[itemID]
        for i, cat in ipairs(cats) do
            if cat.types then
                for _, t in ipairs(cat.types) do
                    if t == oc then return i end
                end
            end
        end
    end

    -- Quest status (catches "begins a quest" items the class ID would miss)
    local isQuestItem = false
    if bag and slot and C_Container and C_Container.GetContainerItemQuestInfo then
        local q = C_Container.GetContainerItemQuestInfo(bag, slot)
        if q and (q.isQuestItem or q.questID) then isQuestItem = true end
    end

    -- Class + equip slot (locale-safe numeric IDs)
    local _, _, _, equipSlot, _, classID = GetItemInfoInstant(itemLink)

    -- Equipment-set membership
    local inSet = false
    if bag and slot and (classID == IC_ARMOR or classID == IC_WEAPON) then
        inSet = _setGearLookup[bag * 1000 + slot] or false
    end

    -- 6. Walk categories in display order; first matching rule wins.
    -- A category may combine a special predicate (quest/setGear/junk) with
    -- class-type rules; it matches if any of its rules match. Catch-all is
    -- deferred to the end; pinned/recent/reagentBag are never matched here.
    local catchIdx
    for i, cat in ipairs(cats) do
        if cat.isCatchAll then
            catchIdx = i
        elseif cat.isPinned or cat.isRecent or cat.isReagentBag then
            -- virtual / positional: skip
        else
            local match = false
            if cat.isQuest and isQuestItem then match = true end
            if not match and cat.isSetGear and inSet then match = true end
            if not match and cat.isJunk and (quality or 1) == 0 then match = true end
            if not match and cat.types and #cat.types > 0 then
                if classID then
                    for _, t in ipairs(cat.types) do
                        if t == classID then match = true; break end
                    end
                end
                -- equipSlots: pull in items of other classes by equip slot (trinkets)
                if not match and cat.equipSlots and equipSlot then
                    for _, es in ipairs(cat.equipSlots) do
                        if es == equipSlot then match = true; break end
                    end
                end
                -- excludeEquipSlots: reject matched items with an excluded equip slot
                if match and cat.excludeEquipSlots and equipSlot then
                    for _, es in ipairs(cat.excludeEquipSlots) do
                        if es == equipSlot then match = false; break end
                    end
                end
            end
            if match then return i end
        end
    end

    return catchIdx or #cats
end

-- Classify a whole list. Each entry needs .itemLink, .info (with itemID,
-- quality), .bag, .slot. Sets .categoryIndex on each. Disabled categories are
-- rerouted to the catch-all. Returns (counts, total) using reusable tables.
local _claCounts = {}
local _claDisabledIdx = {}

function BC:ClassifyAll(items)
    BuildSetGearLookup()
    local cats = self:GetCategories()
    wipe(_claCounts)
    for i = 1, #cats do _claCounts[i] = 0 end
    local total = 0

    -- Map disabled category keys -> indices, find catch-all
    local disabled = S().catDisabled
    local catchIdx
    wipe(_claDisabledIdx)
    local hasDisabled = false
    for i, cat in ipairs(cats) do
        if cat.isCatchAll then catchIdx = i end
        if disabled and cat.key and disabled[cat.key] then
            _claDisabledIdx[i] = true
            hasDisabled = true
        end
    end

    for _, data in ipairs(items) do
        if data.info and data.itemLink then
            local idx = self:ClassifyItem(data.itemLink, data.info.itemID, data.bag, data.slot, data.info.quality)
            if hasDisabled and idx and _claDisabledIdx[idx] and catchIdx then
                idx = catchIdx
            end
            data.categoryIndex = idx
            if idx then _claCounts[idx] = (_claCounts[idx] or 0) + 1 end
            total = total + 1
        end
    end

    return _claCounts, total
end

-- =====================================
-- RENAME / REORDER
-- =====================================

function BC:RenameCategory(index, newName)
    local cats = self:GetCategories()
    local cat = cats[index]
    if not cat or cat.isCatchAll then return false end
    if not newName or newName == "" then return false end
    local oldGroup = cat.groupName
    cat.name = newName
    if oldGroup and not self:IsGroupNameCustom(oldGroup) then
        self:RegenerateGroupName(oldGroup)
    end
    self:SaveState()
    return true
end

-- Index, in the runtime list, of the first reorderable (non-noMove) category.
local function FirstMovableIndex(cats)
    for i, cat in ipairs(cats) do
        if not cat.noMove then return i end
    end
    return #cats + 1
end

-- Move a category. Callers pass the desired final position; index math is
-- handled internally. noMove categories cannot be moved, and nothing can be
-- dropped above the noMove block.
function BC:ReorderCategory(fromIndex, toIndex)
    local cats = self:GetCategories()
    local cat = cats[fromIndex]
    if not cat or cat.noMove then return end
    if fromIndex == toIndex then return end
    local minIdx = FirstMovableIndex(cats)
    if toIndex < minIdx then toIndex = minIdx end
    if toIndex > #cats + 1 then toIndex = #cats + 1 end
    local entry = table.remove(cats, fromIndex)
    local insertAt = toIndex
    if fromIndex < toIndex then insertAt = toIndex - 1 end
    if insertAt < minIdx then insertAt = minIdx end
    if insertAt > #cats + 1 then insertAt = #cats + 1 end
    table.insert(cats, insertAt, entry)
    self:SaveState()
end

-- =====================================
-- GROUPING
-- =====================================

local function JoinNames(names)
    if #names == 2 then
        return names[1] .. " & " .. names[2]
    elseif #names >= 3 then
        local last = names[#names]
        local head = {}
        for i = 1, #names - 1 do head[i] = names[i] end
        return table.concat(head, ", ") .. ", & " .. last
    end
    return names[1] or "Group"
end

function BC:GroupCategories(indices, groupName)
    local cats = self:GetCategories()
    if not indices or #indices < 2 then return end
    if not groupName then
        local names = {}
        for _, idx in ipairs(indices) do
            if cats[idx] then names[#names + 1] = cats[idx].name end
        end
        groupName = JoinNames(names)
    end
    for _, idx in ipairs(indices) do
        local cat = cats[idx]
        if cat and not cat.noGroup then
            cat.groupName = groupName
            cat.groupNameCustom = nil
        end
    end
    self:SaveState()
end

function BC:AddToGroup(catIndex, groupName)
    local cats = self:GetCategories()
    local cat = cats[catIndex]
    if not cat or cat.noGroup or not groupName then return end
    cat.groupName = groupName
    self:RegenerateGroupName(groupName)
    self:SaveState()
end

function BC:UngroupCategory(catIndex)
    local cats = self:GetCategories()
    local cat = cats[catIndex]
    if not cat or not cat.groupName then return end
    local oldGroup = cat.groupName
    local wasCustom = self:IsGroupNameCustom(oldGroup)
    cat.groupName = nil
    local remaining = {}
    for i, c in ipairs(cats) do
        if c.groupName == oldGroup then remaining[#remaining + 1] = i end
    end
    if #remaining == 1 then
        cats[remaining[1]].groupName = nil   -- auto-disband single-member group
    elseif #remaining >= 2 and not wasCustom then
        self:RegenerateGroupName(oldGroup)
    end
    self:SaveState()
end

function BC:DisbandGroup(groupName)
    local cats = self:GetCategories()
    for _, cat in ipairs(cats) do
        if cat.groupName == groupName then cat.groupName = nil end
    end
    self:SaveState()
end

function BC:RenameGroup(oldName, newName)
    if not newName or newName == "" then return end
    local cats = self:GetCategories()
    for _, cat in ipairs(cats) do
        if cat.groupName == oldName then cat.groupName = newName end
    end
    self:SaveState()
end

function BC:IsGroupNameCustom(groupName)
    local cats = self:GetCategories()
    for _, cat in ipairs(cats) do
        if cat.groupName == groupName and cat.groupNameCustom then return true end
    end
    return false
end

function BC:SetGroupNameCustom(groupName, isCustom)
    local cats = self:GetCategories()
    for _, cat in ipairs(cats) do
        if cat.groupName == groupName then
            cat.groupNameCustom = isCustom or nil
        end
    end
    self:SaveState()
end

function BC:RegenerateGroupName(groupName)
    local cats = self:GetCategories()
    local names = {}
    for _, cat in ipairs(cats) do
        if cat.groupName == groupName then names[#names + 1] = cat.name end
    end
    if #names < 2 then return end
    local newName = JoinNames(names)
    if newName ~= groupName then
        self:RenameGroup(groupName, newName)
        self:SetGroupNameCustom(newName, false)
    end
end

function BC:GetGroupNames()
    local cats = self:GetCategories()
    local seen, groups = {}, {}
    for _, cat in ipairs(cats) do
        if cat.groupName and not seen[cat.groupName] then
            seen[cat.groupName] = true
            groups[#groups + 1] = cat.groupName
        end
    end
    return groups
end

function BC:GetGroupMembers(groupName)
    local cats = self:GetCategories()
    local members = {}
    for i, cat in ipairs(cats) do
        if cat.groupName == groupName then members[#members + 1] = i end
    end
    return members
end

function BC:IsGrouped(catIndex)
    local cats = self:GetCategories()
    return cats[catIndex] and cats[catIndex].groupName or nil
end

-- =====================================
-- CUSTOM CATEGORY CRUD
-- =====================================

function BC:AddCustomCategory(name)
    if not name or name == "" then return nil end
    local s = S()
    s.userCats = s.userCats or {}

    -- Unique key: Custom_N
    local maxN = 0
    for _, uc in ipairs(s.userCats) do
        local n = tonumber(tostring(uc.key):match("Custom_(%d+)"))
        if n and n > maxN then maxN = n end
    end
    local key = "Custom_" .. (maxN + 1)
    s.userCats[#s.userCats + 1] = { key = key, name = name, icon = QUESTIONMARK }

    -- Insert into runtime list just before the catch-all
    local cats = self:GetCategories()
    local insertIdx = #cats + 1
    for i, c in ipairs(cats) do
        if c.isCatchAll then insertIdx = i; break end
    end
    table.insert(cats, insertIdx, {
        key = key, name = name, icon = QUESTIONMARK, isAtlas = nil,
        types = {}, isUserCreated = true,
    })
    self:SaveState()
    return insertIdx
end

function BC:RemoveCustomCategory(catIndex)
    local cats = self:GetCategories()
    local cat = cats[catIndex]
    if not cat or not cat.isUserCreated then return false end
    local key = cat.key

    -- Drop item assignments pointing at this category
    local assign = S().itemAssign
    if assign then
        for itemID, aKey in pairs(assign) do
            if aKey == key then assign[itemID] = nil end
        end
    end
    -- Drop from disabled set
    local disabled = S().catDisabled
    if disabled then disabled[key] = nil end

    table.remove(cats, catIndex)
    self:SaveState()
    return true
end

-- =====================================
-- ITEM ASSIGNMENT (user overrides auto-classification)
-- =====================================

function BC:AssignItem(itemID, categoryKey)
    if not itemID or not TomoModDB then return end
    local s = S()
    s.itemAssign = s.itemAssign or {}
    s.itemAssign[itemID] = categoryKey
end

function BC:UnassignItem(itemID)
    if not itemID then return end
    local assign = S().itemAssign
    if assign then assign[itemID] = nil end
end

function BC:GetAssignment(itemID)
    if not itemID then return nil end
    local assign = S().itemAssign
    return assign and assign[itemID] or nil
end

-- Categories that accept item assignments (drag targets). Excludes the
-- virtual/positional buckets.
function BC:CanAssignToCategory(catIndex)
    local cats = self:GetCategories()
    local cat = cats[catIndex]
    if not cat then return false end
    if cat.isPinned or cat.isRecent or cat.isReagentBag then return false end
    return true
end

-- =====================================
-- DISABLED CATEGORIES (route to catch-all)
-- =====================================

function BC:ToggleDisabled(catIndex)
    local cats = self:GetCategories()
    local cat = cats[catIndex]
    if not cat or cat.isCatchAll then return end
    if cat.isPinned or cat.isRecent or cat.isReagentBag then return end
    local s = S()
    s.catDisabled = s.catDisabled or {}
    if s.catDisabled[cat.key] then
        s.catDisabled[cat.key] = nil
    else
        s.catDisabled[cat.key] = true
    end
end

function BC:IsDisabled(catIndex)
    local cats = self:GetCategories()
    local cat = cats[catIndex]
    if not cat then return false end
    local disabled = S().catDisabled
    return (disabled and cat.key and disabled[cat.key]) and true or false
end

-- =====================================
-- PINNED ITEMS
-- Non-gear: pin all stacks (count 999) or unpin. Gear: per-stack count toggle
-- so multiple copies can be individually pinned.
-- =====================================

function BC:TogglePin(itemID, itemLink)
    if not itemID or not TomoModDB then return end
    local s = S()
    s.pinned = s.pinned or {}
    local cur = s.pinned[itemID] or 0
    if IsGearItem(itemLink) then
        -- Gear: per-stack count toggle so multiple copies can be pinned
        if cur > 0 then
            cur = cur - 1
            if cur > 0 then s.pinned[itemID] = cur else s.pinned[itemID] = nil end
        else
            s.pinned[itemID] = cur + 1
        end
    else
        -- Non-gear: pin all stacks at once / unpin
        if cur > 0 then s.pinned[itemID] = nil else s.pinned[itemID] = 999 end
    end
end

function BC:IsPinned(itemID)
    if not itemID then return false end
    local pinned = S().pinned
    return (pinned and (pinned[itemID] or 0) > 0) and true or false
end

function BC:GetPinCount(itemID)
    if not itemID then return 0 end
    local pinned = S().pinned
    return (pinned and pinned[itemID]) or 0
end

-- Seed default pins once, ever.
function BC:SeedDefaultPins()
    if not TomoModDB then return end
    local s = S()
    if s.pinsSeeded then return end
    s.pinsSeeded = true
    s.pinned = s.pinned or {}
    for id, count in pairs(DEFAULT_PINS) do
        if s.pinned[id] == nil then s.pinned[id] = count end
    end
end

-- =====================================
-- RECENT ITEMS (session-only)
-- =====================================

function BC:SnapshotKnownIDs()
    wipe(_knownIDs)
    for bag = 0, REAGENT_BAG_ID do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then _knownIDs[info.itemID] = true end
        end
    end
    _snapshotReady = true
end

function BC:DetectNewItems()
    if not _snapshotReady then return end
    for bag = 0, REAGENT_BAG_ID do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local id = info.itemID
                if not _knownIDs[id] and not self._recentSet[id] then
                    self._recentSet[id] = true
                    self._recentOrder[#self._recentOrder + 1] = id
                    if #self._recentOrder > RECENT_MAX then
                        local oldest = table.remove(self._recentOrder, 1)
                        if oldest then self._recentSet[oldest] = nil end
                    end
                end
                _knownIDs[id] = true
            end
        end
    end
end

function BC:GetRecentSet()
    return self._recentSet
end

function BC:IsRecent(itemID)
    return itemID and self._recentSet[itemID] or false
end

function BC:ResetRecent()
    wipe(self._recentSet)
    wipe(self._recentOrder)
    wipe(_knownIDs)
    _snapshotReady = false
end

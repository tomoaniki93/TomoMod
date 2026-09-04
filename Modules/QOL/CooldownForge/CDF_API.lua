-- =====================================================================
-- CooldownForge -- CRUD API (bars & entries)
-- Pure data manipulation; no frame work, so combat-safe (no taint,
-- no InCombatLockdown guard needed). Rendering arrives in Lot 3.
-- Requires CDF_Core.lua loaded first.
-- =====================================================================

local CDF = TomoMod_CooldownForge

-- Returns the ORDERED bar array for `class` (defaults to the player's
-- class), creating the per-class table on first access. nil if the DB
-- is not ready yet. Also returns the resolved class token.
function CDF.GetClassBars(class)
    local db = CDF.DB()
    if not db then return nil end
    class = class or CDF.PlayerClass()
    if not class then return nil end
    db.bars = db.bars or {}
    db.bars[class] = db.bars[class] or {}
    return db.bars[class], class
end

-- Find a bar (and its index) by id within a class.
function CDF.GetBar(class, id)
    local arr = CDF.GetClassBars(class)
    if not arr then return nil end
    for i = 1, #arr do
        if arr[i].id == id then return arr[i], i end
    end
    return nil
end

-- ---------------------------------------------------------------------
-- Bar CRUD
-- ---------------------------------------------------------------------
function CDF.CreateBar(class, name)
    local arr = CDF.GetClassBars(class)
    if not arr then return nil end
    local bar = CDF.SanitizeBar(CDF.NewBarSchema(name))
    bar.id = CDF.genBarId(arr)
    arr[#arr + 1] = bar
    return bar, bar.id
end

function CDF.RenameBar(class, id, newName)
    local bar = CDF.GetBar(class, id)
    if not bar then return false end
    newName = tostring(newName or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if newName == "" then return false end
    bar.name = newName
    return true
end

-- [copy] Copy ONLY the visual style (bar.style) from one bar to another.
-- id, name, position, layout, visibility and spells of the destination are
-- left untouched. Deep copy so the two bars never share table references.
function CDF.CopyStyle(class, srcId, dstId)
    if srcId == dstId then return false end
    local src = CDF.GetBar(class, srcId)
    local dst = CDF.GetBar(class, dstId)
    if not src or not dst then return false end
    local copy = TomoMod_Forge and TomoMod_Forge.Util and TomoMod_Forge.Util.CopyDeep
    if not copy then return false end
    dst.style = copy(src.style or {})
    if CDF.SanitizeBar then CDF.SanitizeBar(dst) end
    return true
end

function CDF.DeleteBar(class, id)
    local arr = CDF.GetClassBars(class)
    if not arr then return false end
    for i = 1, #arr do
        if arr[i].id == id then
            table.remove(arr, i)
            return true
        end
    end
    return false
end

function CDF.DuplicateBar(class, id)
    local arr = CDF.GetClassBars(class)
    if not arr then return nil end
    local src, idx = CDF.GetBar(class, id)
    if not src then return nil end
    local copy = CopyTable(src)
    copy.id   = CDF.genBarId(arr)
    copy.name = (src.name or "Bar") .. " (copie)"
    -- [P3] A duplicate of one member of a contextual preset becomes a normal
    -- standalone bar. Keeping the pack metadata would make future preset
    -- updates mistake the copy for the real Solo/Mythic+/Raid member.
    copy.contextPreset  = nil
    copy.contextPackID  = nil
    copy.contextProfile = nil
    copy.contextSpecID  = nil
    for _, entry in ipairs(copy.entries or {}) do
        entry.fromContextPreset = nil
        entry.contextSource = nil
    end
    -- Position is personal; reset the copy so it doesn't overlap the source.
    copy.position = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 }
    table.insert(arr, idx + 1, copy)
    return copy, copy.id
end

-- Reorder a bar within its class array. delta -1 = up, +1 = down.
function CDF.MoveBar(class, id, delta)
    local arr = CDF.GetClassBars(class)
    if not arr then return false end
    local _, i = CDF.GetBar(class, id)
    if not i then return false end
    local j = i + (tonumber(delta) or 0)
    if j < 1 or j > #arr then return false end
    arr[i], arr[j] = arr[j], arr[i]
    return true
end

-- ---------------------------------------------------------------------
-- Entry validation & CRUD
-- ---------------------------------------------------------------------
-- Returns true | false, reason
function CDF.ValidateEntry(data)
    if type(data) ~= "table" then return false, "no data" end
    local kind = data.kind
    if not CDF.ENTRY_KINDS[kind] then return false, "bad kind" end
    if kind == "spell" or kind == "item" then
        if not tonumber(data.id) then return false, "missing id" end
    elseif kind == "itemPreset" then
        if not (data.preset and CDF.PRESETS[data.preset]) then return false, "unknown preset" end
    elseif kind == "equippedTrinket" then
        if not CDF.TRINKET_SLOTS[tonumber(data.slot) or -1] then return false, "bad slot" end
    end
    -- racial: no identity required (resolved from the player's race)
    return true
end

function CDF.AddEntry(class, barId, data)
    local bar = CDF.GetBar(class, barId)
    if not bar then return nil, "no bar" end
    local ok, reason = CDF.ValidateEntry(data)
    if not ok then return nil, reason end
    local entry = CDF.NewEntrySchema({
        kind     = data.kind,
        id       = tonumber(data.id),
        preset   = data.preset,
        slot     = tonumber(data.slot),
        spec     = data.spec,
        enabled  = data.enabled,
        override = data.override,
    })
    bar.entries = bar.entries or {}
    bar.entries[#bar.entries + 1] = entry
    return entry
end

function CDF.RemoveEntry(class, barId, index)
    local bar = CDF.GetBar(class, barId)
    if not bar or not bar.entries then return false end
    if not bar.entries[index] then return false end
    table.remove(bar.entries, index)
    return true
end

function CDF.MoveEntry(class, barId, index, delta)
    local bar = CDF.GetBar(class, barId)
    if not bar or not bar.entries then return false end
    local j = index + (tonumber(delta) or 0)
    if not bar.entries[index] or j < 1 or j > #bar.entries then return false end
    bar.entries[index], bar.entries[j] = bar.entries[j], bar.entries[index]
    return true
end

function CDF.GetEntry(class, barId, index)
    local bar = CDF.GetBar(class, barId)
    if not bar or not bar.entries then return nil end
    return bar.entries[index]
end

-- Set an entry's spec-visibility condition (0 = all specs, else a specID).
function CDF.SetEntrySpec(class, barId, index, specID)
    local entry = CDF.GetEntry(class, barId, index)
    if not entry then return false end
    entry.spec = tonumber(specID) or 0
    return true
end

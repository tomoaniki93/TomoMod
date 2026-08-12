local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- SpellBridge: queries C_DamageMeter for per-spell breakdown data
----------------------------------------------------------------------
-- Uses C_DamageMeter.GetCombatSessionSourceFromType() which returns
-- a combatSpells array for a given source GUID.  No CLEU needed.
--
-- Each combatSpells entry (damagemeter_combat_spell) exposes more than
-- just amount/rate; the Midnight API also carries:
--   creatureName   -> pet / guardian that cast the spell
--   overkillAmount -> wasted (over-the-kill) portion
--   isAvoidable    -> flagged avoidable damage
--   isDeadly       -> spell delivered a killing blow
-- These were previously dropped on the floor; they now ride along on
-- every entry (each read guarded, since any field can be a secret value
-- mid-combat).
----------------------------------------------------------------------

local GetSpellInfo = C_Spell and C_Spell.GetSpellInfo or GetSpellInfo

local DEBUG = false -- set to true to log C_DamageMeter pcall failures

local function GetSpellIcon(spellID)
    if not spellID or spellID == 0 then return 134400 end
    if issecretvalue and issecretvalue(spellID) then return 134400 end
    local info = GetSpellInfo(spellID)
    if info then
        return info.iconID or 134400
    end
    return 134400
end

local function GetSpellName(spellID)
    if not spellID or spellID == 0 then return "?" end
    if issecretvalue and issecretvalue(spellID) then return "?" end
    local info = GetSpellInfo(spellID)
    if info then
        return info.name or ("Spell " .. spellID)
    end
    return "Spell " .. spellID
end

----------------------------------------------------------------------
-- Optional enriched fields (Midnight). Each may be a secret value during
-- combat, so every read is individually guarded; missing fields stay nil.
----------------------------------------------------------------------

local function ReadSpellExtras(spell, entry)
    local creature = spell.creatureName
    if creature and not issecretvalue(creature) and creature ~= "" then
        entry.creatureName = creature
    end

    local overkill = spell.overkillAmount
    if overkill and not issecretvalue(overkill) and overkill > 0 then
        entry.overkill = overkill
    end

    local avoidable = spell.isAvoidable
    if avoidable ~= nil and not issecretvalue(avoidable) and avoidable then
        entry.isAvoidable = true
    end

    local deadly = spell.isDeadly
    if deadly ~= nil and not issecretvalue(deadly) and deadly then
        entry.isDeadly = true
    end
end

-- Build a single sorted entry from a raw combatSpells element.
local function MakeEntry(spell)
    local spellID     = spell.spellID
    local totalAmount = spell.totalAmount or 0

    if issecretvalue(spellID) or issecretvalue(totalAmount) or totalAmount <= 0 then
        return nil
    end

    local entry = {
        spellID = spellID,
        total   = totalAmount,
        perSec  = spell.amountPerSecond,
        name    = GetSpellName(spellID),
        icon    = GetSpellIcon(spellID),
    }
    ReadSpellExtras(spell, entry)
    return entry
end

-- Sum two optional numbers, refusing to do arithmetic on a secret value.
-- Returns nil when either side is unreadable, so the caller falls back to the
-- "-" placeholder rather than erroring.
local function AddNum(a, b)
    if a == nil then return b end
    if b == nil then return a end
    if issecretvalue(a) or issecretvalue(b) then return nil end
    return a + b
end

-- Fold entries that resolve to the same spell name into one row.
--
-- Several spellIDs can share a name: rank variants, trinket and embellishment
-- procs, class effects with a hidden secondary ID. Listed side by side they
-- read as a duplicate-row bug even though both lines are correct.
--
-- Pet / guardian attribution is part of the merge key on purpose: the same
-- spell cast by two different guardians stays split, since telling those apart
-- is exactly what the attribution is for.
local function MergeByName(entries)
    local byKey, out = {}, {}
    for _, e in ipairs(entries) do
        local key = (e.name or "?") .. "\0" .. (e.creatureName or "")
        local hit = byKey[key]
        if hit then
            hit.total    = hit.total + e.total
            hit.perSec   = AddNum(hit.perSec, e.perSec)
            hit.overkill = AddNum(hit.overkill, e.overkill)
            if e.isAvoidable then hit.isAvoidable = true end
            if e.isDeadly then hit.isDeadly = true end
            hit.mergedCount = (hit.mergedCount or 1) + 1
        else
            byKey[key] = e
            out[#out + 1] = e
        end
    end
    return out
end

-- Shared finalizer: merge homonyms, sort by total desc, stamp percentages.
local function Finalize(sorted, grandTotal)
    sorted = MergeByName(sorted)
    table.sort(sorted, function(a, b) return a.total > b.total end)
    for _, entry in ipairs(sorted) do
        entry.pct = grandTotal > 0 and (entry.total / grandTotal * 100) or 0
    end
    return sorted, grandTotal
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

--- Returns a sorted array of spell entries for a GUID in the current session.
--- @param sessionType number Enum.DamageMeterSessionType
--- @param meterType number Enum.DamageMeterType
--- @param sourceGUID string
--- @return table|nil sortedSpells, number grandTotal
function ns.GetSpellBreakdown(sessionType, meterType, sourceGUID)
    if not C_DamageMeter or not C_DamageMeter.GetCombatSessionSourceFromType then
        return nil, 0
    end

    -- pcall: sourceGUID may be a secret value (enemy targets); the C API
    -- can resolve it internally but Lua-side errors must be caught.
    local ok, spellData = pcall(C_DamageMeter.GetCombatSessionSourceFromType, sessionType, meterType, sourceGUID)
    if not ok then
        if DEBUG then print(ns.L["ADDON_PREFIX"] .. "SpellBridge: GetCombatSessionSourceFromType failed: " .. tostring(spellData)) end
        return nil, 0
    end
    if not spellData or issecretvalue(spellData) then return nil, 0 end

    local combatSpells = spellData.combatSpells
    if not combatSpells or issecretvalue(combatSpells) or #combatSpells == 0 then return nil, 0 end

    local sorted = {}
    local grandTotal = 0

    for _, spell in ipairs(combatSpells) do
        local entry = MakeEntry(spell)
        if entry then
            sorted[#sorted + 1] = entry
            grandTotal = grandTotal + entry.total
        end
    end

    return Finalize(sorted, grandTotal)
end

--- Returns true if the meter type supports spell breakdown.
function ns.HasSpellBreakdown(meterType)
    -- Actions types (Interrupts, Dispels, Deaths) also have per-spell data
    return meterType ~= nil
end

--- Returns the player's spell breakdown for a specific combat segment.
--- Uses GetCombatSessionSourceFromID with DamageDone/HealingDone + playerGUID.
--- @param sessionID number
--- @param meterType number Enum.DamageMeterType (DamageDone or HealingDone)
--- @param sourceGUID string player GUID
--- @return table|nil sortedSpells, number grandTotal
function ns.GetSpellBreakdownBySegment(sessionID, meterType, sourceGUID)
    if not C_DamageMeter or not C_DamageMeter.GetCombatSessionSourceFromID then
        return nil, 0
    end

    local ok, spellData = pcall(C_DamageMeter.GetCombatSessionSourceFromID,
        sessionID, meterType, sourceGUID)
    if not ok then
        if DEBUG then print(ns.L["ADDON_PREFIX"] .. "SpellBridge: GetCombatSessionSourceFromID failed: " .. tostring(spellData)) end
        return nil, 0
    end
    if not spellData or issecretvalue(spellData) then return nil, 0 end

    local combatSpells = spellData.combatSpells
    if not combatSpells or issecretvalue(combatSpells) or #combatSpells == 0 then return nil, 0 end

    local sorted = {}
    local grandTotal = 0

    for _, spell in ipairs(combatSpells) do
        local entry = MakeEntry(spell)
        if entry then
            sorted[#sorted + 1] = entry
            grandTotal = grandTotal + entry.total
        end
    end

    return Finalize(sorted, grandTotal)
end

--- Returns a processed death-recap event list for a recapID (from the Deaths
--- category's per-source deathRecapID field). Events are ordered oldest-first,
--- so the last entry is the fatal blow. Every field is secretvalue-guarded.
--- @param recapID number source.deathRecapID
--- @return table|nil events, number maxHP
function ns.GetDeathRecap(recapID)
    if not recapID or (issecretvalue and issecretvalue(recapID)) or recapID <= 0 then
        return nil, 0
    end
    if not C_DeathRecap or not C_DeathRecap.GetRecapEvents then
        return nil, 0
    end

    local ok, raw = pcall(C_DeathRecap.GetRecapEvents, recapID)
    if not ok or not raw or issecretvalue(raw) or #raw == 0 then
        return nil, 0
    end

    local maxHP = 1
    if C_DeathRecap.GetRecapMaxHealth then
        local ok2, hp = pcall(C_DeathRecap.GetRecapMaxHealth, recapID)
        if ok2 and type(hp) == "number" and hp > 0 then maxHP = hp end
    end

    local L = ns.L
    -- API returns newest-first; reverse so the fatal blow is last.
    local events = {}
    for i = #raw, 1, -1 do
        local ev = raw[i]
        local evType = ev.event or ""
        local isHeal = (evType == "SPELL_HEAL" or evType == "SPELL_PERIODIC_HEAL")

        local spID = ev.spellId
        if spID and issecretvalue(spID) then spID = nil end

        local icon
        if spID and spID > 0 then
            icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spID)
        end
        if not icon then icon = 135274 end -- melee-swing fallback

        local spellName = ev.spellName
        if not spellName or issecretvalue(spellName) or spellName == "" then
            if isHeal then spellName = L["RECAP_HEAL"]
            elseif evType == "SWING_DAMAGE" then spellName = L["RECAP_MELEE"]
            else spellName = L["RECAP_UNKNOWN"] end
        end

        local amount = ev.amount
        if amount == nil or issecretvalue(amount) then amount = 0 end

        local curHP = ev.currentHP
        if curHP == nil or issecretvalue(curHP) then curHP = 0 end

        local overkill = ev.overkill
        if overkill ~= nil and issecretvalue(overkill) then overkill = nil end

        -- Timestamps were the one field passing through unguarded. DeathRecap
        -- subtracts them, so a secret value reached Lua arithmetic and errored.
        local ts = ev.timestamp
        if ts ~= nil and issecretvalue(ts) then ts = nil end

        events[#events + 1] = {
            spellID   = spID,
            name      = spellName,
            icon      = icon,
            event     = evType,
            isHeal    = isHeal,
            amount    = amount,
            overkill  = overkill,
            currentHP = curHP,
            timestamp = ts,
        }
    end

    return events, maxHP
end

--- Scans the Deaths sessions (Current then Overall) for the local player's most
--- recent deathRecapID. Used by the death-recap auto-popup.
--- @return number|nil recapID, string|nil name, string|nil classFilename
function ns.FindLocalDeathRecap()
    if not C_DamageMeter or not C_DamageMeter.GetCombatSessionFromType then return nil end
    local Deaths = Enum.DamageMeterType.Deaths
    local sessionTypes = {
        Enum.DamageMeterSessionType.Current,
        Enum.DamageMeterSessionType.Overall,
    }
    for _, st in ipairs(sessionTypes) do
        local session = C_DamageMeter.GetCombatSessionFromType(st, Deaths)
        if session and not issecretvalue(session) and session.combatSources then
            for _, s in ipairs(session.combatSources) do
                local isSelf = s.isLocalPlayer
                if isSelf ~= nil and not issecretvalue(isSelf) and isSelf then
                    local rid = s.deathRecapID
                    if rid and not issecretvalue(rid) and rid > 0 then
                        local name = s.name
                        if name and issecretvalue(name) then name = nil end
                        return rid, name, s.classFilename
                    end
                end
            end
        end
    end
    return nil
end

--- Stub: no external data to reset anymore
function ns.ResetSpellData()
    -- No-op: C_DamageMeter handles its own data lifecycle
end

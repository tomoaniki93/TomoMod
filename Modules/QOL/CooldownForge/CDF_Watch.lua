-- =====================================================================
-- CooldownForge -- Watch (resolution, visibility, cooldown state, events)
-- AstralForge Cooldown -- Lot 2. Turns schema entries into draw-ready
-- descriptors and secret-safe cooldown data, and drives an event-based
-- update dispatcher (no polling). Requires CDF_Core + CDF_Catalog.
--
-- 12.0 secret-value rules (see docs/AstralForge_Cooldown_Schema_v1.md sec.6):
--   spells/racials -> duration OBJECTS, never numbers. Passed straight to
--   the Cooldown widget in Lot 3. maxCharges is non-secret; the current
--   charge count is secret and only ever fed to safe sinks (SetText).
--   items/trinkets are non-secret -> plain start/duration numbers.
-- =====================================================================

local CDF = TomoMod_CooldownForge

-- Current spec ID (0 if none). Non-secret.
function CDF.CurrentSpecID()
    local getIdx = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
    local idx = getIdx and getIdx()
    if not idx then return 0 end
    local id = GetSpecializationInfo and GetSpecializationInfo(idx)
    return id or 0
end

-- ---------------------------------------------------------------------
-- Resolution: entry -> descriptor { kind, spellID|itemID|slot, icon, name }
-- Returns nil when the entry has no resolvable identity. Reads no cooldowns.
-- ---------------------------------------------------------------------
function CDF.ResolveEntry(entry)
    if type(entry) ~= "table" then return nil end
    local kind = entry.kind

    if kind == "spell" then
        local id = entry.id
        if not id then return nil end
        return { kind = kind, spellID = id,
                 icon = C_Spell.GetSpellTexture(id), name = C_Spell.GetSpellName(id) }

    elseif kind == "racial" then
        local id = CDF.ResolveRacialSpell()
        if not id then return nil end
        return { kind = kind, spellID = id,
                 icon = C_Spell.GetSpellTexture(id), name = C_Spell.GetSpellName(id) }

    elseif kind == "item" then
        local id = entry.id
        if not id then return nil end
        return { kind = kind, itemID = id,
                 icon = C_Item.GetItemIconByID(id), name = C_Item.GetItemNameByID(id) }

    elseif kind == "itemPreset" then
        local id, present = CDF.ResolvePresetItemID(entry.preset)
        if not id then return nil end
        return { kind = kind, itemID = id, present = present,
                 icon = C_Item.GetItemIconByID(id), name = C_Item.GetItemNameByID(id) }

    elseif kind == "equippedTrinket" then
        local slot = entry.slot
        local id = slot and GetInventoryItemID("player", slot)
        if not id then return { kind = kind, slot = slot, empty = true } end
        return { kind = kind, slot = slot, itemID = id,
                 icon = C_Item.GetItemIconByID(id), name = C_Item.GetItemNameByID(id) }
    end

    return nil
end

-- ---------------------------------------------------------------------
-- Visibility: spec gate + known/present. Non-secret signals only.
-- ---------------------------------------------------------------------
--- [H5] Is a talent taken?
---
--- Asked through the spell it grants rather than through trait nodes: node ids
--- are renumbered at every talent rework, and a hardcoded table of them is the
--- kind of data this project refuses to carry. A talent-granted spell is in
--- the spellbook exactly while the talent is picked, which is the same signal
--- with none of the maintenance.
---
--- C_SpellBook.IsSpellKnownOrInSpellBook is the current test; the globals
--- below are the legacy path, and the live override covers a talent that
--- replaces the spell with another.
function CDF.IsSpellTaken(spellID)
    spellID = tonumber(spellID)
    if not spellID then return false end

    local ids = { spellID }
    if C_SpellBook and C_SpellBook.FindSpellOverrideByID then
        local ok, ov = pcall(C_SpellBook.FindSpellOverrideByID, spellID)
        ov = ok and tonumber(ov) or nil
        if ov and ov ~= spellID then ids[#ids + 1] = ov end
    end

    for _, id in ipairs(ids) do
        if C_SpellBook then
            for _, fn in ipairs({ "IsSpellKnownOrInSpellBook", "IsSpellInSpellBook", "IsSpellKnown" }) do
                if C_SpellBook[fn] then
                    local ok, r = pcall(C_SpellBook[fn], id)
                    if ok and r then return true end
                end
            end
        end
        if IsPlayerSpell and IsPlayerSpell(id) then return true end
        if IsSpellKnown and IsSpellKnown(id) then return true end
    end
    return false
end

--- Does the entry's talent condition hold? No condition means yes.
function CDF.TalentConditionMet(entry)
    if type(entry) ~= "table" then return true end
    local tid = tonumber(entry.talentID)
    if not tid then return true end
    local taken = CDF.IsSpellTaken(tid)
    if entry.talentMode == "unknown" then return not taken end
    return taken
end

function CDF.IsEntryVisible(entry)
    if type(entry) ~= "table" or entry.enabled == false then return false end
    local spec = tonumber(entry.spec) or 0
    if spec ~= 0 and spec ~= CDF.CurrentSpecID() then return false end
    -- [H5] Checked before the kind-specific tests, like the spec filter: a
    -- talent condition is about whether the entry belongs in this build at
    -- all, not about what it points to.
    if not CDF.TalentConditionMet(entry) then return false end

    local kind = entry.kind
    if kind == "spell" then
        -- [G4] A tracked buff is usually NOT a castable spell: proc auras are
        -- granted by a talent or by another spell, so IsSpellKnown and
        -- IsPlayerSpell both answer false for them. Gating an aura entry on
        -- the spellbook rejected it here, before entryShown ever got to look
        -- at whether the buff was up -- the icon simply never appeared.
        -- Presence of an aura entry is decided by the aura itself.
        if entry.mode == "aura" then return true end
        return CDF.isSpellKnown(entry.id)
    elseif kind == "racial" then
        local sid = CDF.ResolveRacialSpell()
        return sid ~= nil and CDF.isSpellKnown(sid)
    elseif kind == "equippedTrinket" then
        return entry.slot ~= nil and GetInventoryItemID("player", entry.slot) ~= nil
    elseif kind == "itemPreset" then
        local _, present = CDF.ResolvePresetItemID(entry.preset)
        return present == true
    elseif kind == "item" then
        return entry.id ~= nil
    end
    return false
end

-- ---------------------------------------------------------------------
-- [S6] Bar-level conditional visibility. Tri-state conditions evaluated
-- against non-secret, event-driven signals. nil visibility = always show.
-- ---------------------------------------------------------------------
-- [G3] Three-state verdict: "show", "dim" (conditions unmet but the bar stays
-- on screen at reduced opacity) or "hide". IsBarVisible below keeps the old
-- boolean contract for existing callers, treating "dim" as visible — a dimmed
-- bar must keep being laid out and polled.
function CDF.GetBarVisibility(bar)
    if type(bar) ~= "table" then return "hide" end
    if bar.enabled == false then return "hide" end
    local v = bar.visibility
    if type(v) ~= "table" then return "show" end
    local unmet = (v.unmet == "dim") and "dim" or "hide"

    if v.inCombat ~= nil then
        local inCombat = (InCombatLockdown() or UnitAffectingCombat("player")) and true or false
        if inCombat ~= v.inCombat then return unmet end
    end
    if v.hasTarget ~= nil then
        -- UnitExists is a plain boolean and stays readable in restricted
        -- content; nothing here inspects the target itself.
        local hasTarget = UnitExists("target") and true or false
        if hasTarget ~= v.hasTarget then return unmet end
    end
    if v.inInstance ~= nil then
        if (IsInInstance() and true or false) ~= v.inInstance then return unmet end
    end
    if v.inRaid ~= nil then
        if (IsInRaid() and true or false) ~= v.inRaid then return unmet end
    end
    if v.inGroup ~= nil then
        if (IsInGroup() and true or false) ~= v.inGroup then return unmet end
    end
    return "show"
end

-- Opacity to apply while a bar is in the "dim" state.
function CDF.GetBarDimAlpha(bar)
    local v = bar and bar.visibility
    local a = v and tonumber(v.dimAlpha) or nil
    if not a then return CDF.VIS_DIM_DEFAULT or 0.5 end
    local lo = CDF.VIS_DIM_MIN or 0.05
    local hi = CDF.VIS_DIM_MAX or 0.95
    if a < lo then return lo end
    if a > hi then return hi end
    return a
end

function CDF.IsBarVisible(bar)
    return CDF.GetBarVisibility(bar) ~= "hide"
end

-- ---------------------------------------------------------------------
-- Cooldown state (secret-safe). The renderer (Lot 3) branches on isSpell:
--   isSpell -> feed durObj/chargeDurObj to Cooldown:SetCooldownFromDurationObject
--   else    -> Cooldown:SetCooldown(start, duration)  (non-secret numbers)
-- No arithmetic or comparison is ever performed on secret values here.
-- ---------------------------------------------------------------------
function CDF.GetCooldownState(resolved)
    if not resolved then return nil end

    if resolved.spellID then
        local sid = resolved.spellID
        local charge = C_Spell.GetSpellCharges(sid)
        return {
            isSpell      = true,
            durObj       = C_Spell.GetSpellCooldownDuration(sid),
            chargeDurObj = C_Spell.GetSpellChargeDuration(sid),
            maxCharges   = (charge and charge.maxCharges) or 1,
            chargeInfo   = charge,   -- current count is secret; SetText only
        }

    elseif resolved.kind == "equippedTrinket" and resolved.slot then
        local start, duration, enable = GetInventoryItemCooldown("player", resolved.slot)
        return { isSpell = false, start = start, duration = duration, enable = enable }

    elseif resolved.itemID then
        local start, duration, enable = C_Item.GetItemCooldown(resolved.itemID)
        return { isSpell = false, start = start, duration = duration, enable = enable }
    end

    return nil
end

-- ---------------------------------------------------------------------
-- [S8] Aura presence on the player.
-- Detect-don't-test: we only ever check that the aura EXISTS. Its duration
-- and expiration are never read, compared or used in arithmetic, so no
-- secret value is touched (see sec.6).
-- ---------------------------------------------------------------------
function CDF.IsAuraActive(spellID)
    spellID = tonumber(spellID)
    if not spellID then return false end
    -- Routed through the same registry the tracked-buff entries use:
    -- GetPlayerAuraBySpellID returns nil for most auras once combat starts, so
    -- glow-on-aura carried the same blind spot, silently.
    local st = CDF.GetAuraState and CDF.GetAuraState(spellID)
    return (st and st.active) and true or false
end

-- ---------------------------------------------------------------------
-- [S9] Castability (resource, form, reactive requirements).
--
-- Cooldown state alone is not the whole story: an off-cooldown spell can
-- still be uncastable because the player cannot pay for it -- Ironfur with
-- no rage is the canonical case. Blizzard exposes that as two plain
-- booleans, the same pair the action bars use to grey their buttons.
--
-- 12.x safety: should either return ever become a secret value, branching
-- on it would raise, so the call is wrapped in pcall and both results are
-- type checked. On any doubt we answer "usable", i.e. the pre-S9
-- behaviour, so a future API change degrades instead of breaking.
--
-- Returns: usable (boolean), noPower (boolean)
-- ---------------------------------------------------------------------
local function asBool(v, default)
    if type(v) == "boolean" then return v end
    return default
end

function CDF.GetUsable(resolved)
    if type(resolved) ~= "table" then return true, false end

    local sid = resolved.spellID
    if sid then
        local fn = (C_Spell and C_Spell.IsSpellUsable) or IsUsableSpell
        if not fn then return true, false end
        local ok, usable, noPower = pcall(fn, sid)
        if not ok then return true, false end
        return asBool(usable, true), asBool(noPower, false)
    end

    local iid = resolved.itemID
    if not iid and resolved.slot then
        iid = GetInventoryItemID("player", resolved.slot)
    end
    if iid then
        local fn = (C_Item and C_Item.IsUsableItem) or IsUsableItem
        if not fn then return true, false end
        local ok, usable, noPower = pcall(fn, iid)
        if not ok then return true, false end
        return asBool(usable, true), asBool(noPower, false)
    end

    return true, false
end

-- ---------------------------------------------------------------------
-- [S8] Ready test usable OUTSIDE the render pass.
-- Spell cooldowns are secret in 12.x, so the only legal way to know
-- whether one is running is to feed the duration object to a Cooldown
-- widget and read back IsShown() -- the same detect-don't-test trick the
-- renderer already uses on real icons (CDF_Render, applyEntry). Here it
-- runs against one shared scratch widget so the ready state can be known
-- BEFORE deciding which icons to lay out.
--
-- The host is parked off-screen at alpha 0 rather than hidden, so the
-- Cooldown widget keeps updating its own shown flag normally.
-- ---------------------------------------------------------------------
local probe
local function getProbe()
    if not probe then
        local host = CreateFrame("Frame", nil, UIParent)
        host:SetSize(1, 1)
        host:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -500, 500)
        host:SetAlpha(0)
        probe = CreateFrame("Cooldown", nil, host, "CooldownFrameTemplate")
        probe:SetAllPoints(host)
        probe:SetDrawBling(false)
        probe:SetDrawSwipe(false)
        probe:SetHideCountdownNumbers(true)
    end
    return probe
end

--- [H4] Are all charges back?
---
--- The obvious test -- currentCharges == maxCharges -- is exactly the one that
--- is forbidden: chargeInfo.currentCharges is a secret value. The charge
--- cooldown itself answers the question without any comparison: it runs while
--- a charge is missing and stops once they are all back.
function CDF.IsAtMaxCharges(state)
    if type(state) ~= "table" or not state.isSpell then return false end
    local maxC = tonumber(state.maxCharges) or 1
    if maxC <= 1 then
        -- No charge system: "all charges back" is just "off cooldown".
        return CDF.IsReady(nil, state)
    end
    if not state.chargeDurObj then return false end
    local p = getProbe()
    local ok = pcall(p.SetCooldownFromDurationObject, p, state.chargeDurObj)
    if not ok then return false end
    return not p:IsShown()
end

function CDF.IsReady(resolved, state)
    if not state then return true end
    if state.isSpell then
        local durObj = (state.maxCharges and state.maxCharges > 1 and state.chargeDurObj)
                       or state.durObj
        if not durObj then return true end
        local p = getProbe()
        p:SetCooldownFromDurationObject(durObj)
        return not p:IsShown()
    end
    -- items / trinkets: plain non-secret numbers, safe to compare
    local d = state.duration
    return (not d) or d == 0
end

-- ---------------------------------------------------------------------
-- Update dispatcher (event-driven; zero idle CPU). Subscribers (the
-- renderer, Lot 3) register a callback and receive a coarse reason:
--   "cooldown" -> a cooldown/charge changed (redraw swipes)
--   "layout"   -> spec/roster/bags/equipment changed (re-evaluate visibility)
-- ---------------------------------------------------------------------
CDF._updateSubs = CDF._updateSubs or {}

function CDF.RegisterUpdate(fn)
    if type(fn) == "function" then
        CDF._updateSubs[#CDF._updateSubs + 1] = fn
    end
end

local function fireUpdate(reason)
    local subs = CDF._updateSubs
    for i = 1, #subs do
        subs[i](reason)
    end
end
CDF.FireUpdate = fireUpdate

local w = CreateFrame("Frame")
w:RegisterEvent("SPELL_UPDATE_COOLDOWN")
w:RegisterEvent("SPELL_UPDATE_CHARGES")
w:RegisterEvent("BAG_UPDATE_COOLDOWN")
w:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player") -- catches final-charge spends inside the GCD
w:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
w:RegisterEvent("SPELLS_CHANGED")
w:RegisterEvent("BAG_UPDATE_DELAYED")
w:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
-- [S6] visibility-condition triggers (event-driven, no polling; note we
-- never touch COMBAT_LOG_EVENT_UNFILTERED, which is protected in TWW).
w:RegisterEvent("PLAYER_REGEN_ENABLED")
w:RegisterEvent("PLAYER_REGEN_DISABLED")
w:RegisterEvent("GROUP_ROSTER_UPDATE")
w:RegisterEvent("ZONE_CHANGED_NEW_AREA")
w:RegisterEvent("PLAYER_ENTERING_WORLD")
w:RegisterEvent("PLAYER_TARGET_CHANGED")
-- [G5] Talent changes re-point the ability -> buff overrides the aura link map
-- is built from. PLAYER_SPECIALIZATION_CHANGED is already registered above.
w:RegisterEvent("TRAIT_CONFIG_UPDATED")
-- [H5] Swapping loadouts fires this and not TRAIT_CONFIG_UPDATED, so without
-- it a talent condition would keep the previous build's answer until something
-- else forced a layout.
w:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
w:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED")
w:SetScript("OnEvent", function(_, event, unit, updateInfo)
    if event == "UNIT_AURA" then
        CDF.OnUnitAura(updateInfo)
    end
    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "SPELLS_CHANGED"
       or event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED"
       or event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED"
       or event == "GROUP_ROSTER_UPDATE" or event == "ZONE_CHANGED_NEW_AREA"
       or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED"
       or event == "TRAIT_CONFIG_UPDATED" or event == "ACTIVE_TALENT_GROUP_CHANGED"
       or event == "TRAIT_CONFIG_LIST_UPDATED" then
        if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "TRAIT_CONFIG_UPDATED"
           or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "TRAIT_CONFIG_LIST_UPDATED" then
            CDF.InvalidateAuraLinks()
        end
        fireUpdate("layout")
    else
        fireUpdate("cooldown")
    end
end)
CDF._watchFrame = w

-- [S8] UNIT_AURA fires very often in combat, so it is only registered
-- while at least one bar actually needs aura state (glow condition
-- "aura"). The renderer recomputes this on every layout refresh, which
-- keeps the dispatcher at its usual zero idle cost otherwise.
-- [G4] Aura state for a tracked-buff entry.
--
-- Existence is the only thing that is always safe to read, and it alone
-- drives show/hide. Duration and stacks are a bonus: in restricted content
-- (Mythic+) those fields can be SECRET values, and feeding a secret to
-- Cooldown:SetCooldown or comparing it is exactly what the taint rules
-- forbid. So each numeric is gated on issecretvalue() and simply omitted
-- when unreadable — the icon still appears and disappears correctly, it just
-- shows no timer there.
-- Strings need the same gate as numbers, and for the same reason. Reading a
-- FontString off a Blizzard frame can hand back a SECRET string, and
-- comparing one -- even against "" -- raises. That is what happened: the
-- countdown mirror tested `txt ~= ""` before checking secrecy and threw on
-- every frame, over a thousand times a fight.
local function readableString(v)
    if v == nil then return nil end
    if issecretvalue and issecretvalue(v) then return nil end
    if type(v) ~= "string" then return nil end
    -- Safe from here: v is known non-secret, so comparing it is allowed.
    if v == "" then return nil end
    return v
end

local function readableNumber(v)
    if v == nil then return nil end
    if issecretvalue and issecretvalue(v) then return nil end
    if type(v) ~= "number" then return nil end
    return v
end

-- An ability and the buff it grants are two different spell IDs. Blizzard's
-- Cooldown Manager knows the link -- that is how its "Tracked Buffs" viewer
-- shows an aura for an ability -- and exposes it as overrideSpellID and
-- linkedSpellIDs on each cooldown entry. Reading THAT is why nothing here is
-- hardcoded: the map is rebuilt from the client, so it follows every patch
-- and every talent change on its own.
local auraLinks, auraLinksBuilt, auraCandidates
-- [G5] Why these two are tracked: if the client ever renames the category API,
-- every guard below fails softly and the map comes out empty -- which looks
-- exactly like "this ability simply has no linked buff". Counting what was
-- built is what tells the two apart, and /tm forge prints it.
local auraLinkAPI, auraLinkCount = false, 0

local function BuildAuraLinks()
    auraLinksBuilt = true
    auraLinks, auraCandidates = {}, {}
    auraLinkAPI, auraLinkCount = false, 0
    local CV = C_CooldownViewer
    if not (CV and CV.GetCooldownViewerCategorySet and CV.GetCooldownViewerCooldownInfo) then
        return
    end
    local cats = Enum and Enum.CooldownViewerCategory
    if type(cats) ~= "table" then return end
    auraLinkAPI = true
    for _, cat in pairs(cats) do
        local ok, ids = pcall(CV.GetCooldownViewerCategorySet, cat)
        if ok and type(ids) == "table" then
            for _, cdID in ipairs(ids) do
                local ok2, info = pcall(CV.GetCooldownViewerCooldownInfo, cdID)
                if ok2 and type(info) == "table" then
                    local list = {}
                    local function add(v)
                        v = tonumber(v)
                        if not v then return end
                        for i = 1, #list do if list[i] == v then return end end
                        list[#list + 1] = v
                    end
                    add(info.overrideSpellID)
                    if type(info.linkedSpellIDs) == "table" then
                        for _, s in ipairs(info.linkedSpellIDs) do add(s) end
                    end
                    if #list > 0 then
                        -- Index by every id the player could plausibly type in,
                        -- so either the ability or its override resolves.
                        local base = tonumber(info.spellID)
                        if base and not auraLinks[base] then
                            auraLinks[base] = list
                            auraLinkCount = auraLinkCount + 1
                        end
                        local ov = tonumber(info.overrideSpellID)
                        if ov and not auraLinks[ov] then
                            auraLinks[ov] = list
                            auraLinkCount = auraLinkCount + 1
                        end
                    end
                end
            end
        end
    end
end

-- Talent and spec changes re-point overrides, so the map is dropped rather
-- than patched.
function CDF.InvalidateAuraLinks()
    auraLinksBuilt, auraLinks, auraCandidates = nil, nil, nil
    auraLinkAPI, auraLinkCount = false, 0
end

-- Was the link map actually built, and how much did it find? An empty map is
-- indistinguishable from "no ability here has a linked buff" without this.
function CDF.AuraLinkStatus()
    if not auraLinksBuilt then BuildAuraLinks() end
    return auraLinkAPI, auraLinkCount
end

-- Every id worth testing for an entry: the one typed in, then whatever
-- Blizzard links to it.
--
-- Memoised, and deliberately so: this sits behind GetAuraState, which runs per
-- icon on every render pass, and rebuilding a throwaway table there is the
-- kind of churn the 3.3.2 aura work existed to remove. The returned table is
-- SHARED -- callers iterate it, they must not modify it.
function CDF.AuraCandidates(spellID)
    spellID = tonumber(spellID)
    if not spellID then return nil end
    if not auraLinksBuilt then BuildAuraLinks() end

    local out, seen = {}, {}
    local function add(v)
        v = tonumber(v)
        if not v or seen[v] then return end
        seen[v] = true
        out[#out + 1] = v
    end
    local function addOverride(v)
        if not (C_SpellBook and C_SpellBook.FindSpellOverrideByID and v) then return end
        local ok, ov = pcall(C_SpellBook.FindSpellOverrideByID, v)
        if ok then add(ov) end
    end

    -- 1. the id typed in.
    add(spellID)
    -- 2. its LIVE override, resolved on every call and never cached. A talent
    --    or a proc can swap the live spell mid-fight and the aura then lands
    --    under the override id. The cooldown-viewer map below is a snapshot
    --    taken at spec/talent change, so it cannot see that: the measured hit
    --    rate was 18% out of combat against 0.1% in combat, the same auras
    --    flipping to "not found" in the very frame combat started.
    addOverride(spellID)
    -- 3. whatever the cooldown viewer links to it, and their overrides in turn.
    local linked = auraLinks and auraLinks[spellID]
    if linked then
        for k = 1, #linked do
            add(linked[k])
            addOverride(linked[k])
        end
    end
    return out
end

-- [MIDNIGHT] aura.spellId goes SECRET in combat: measured 100% readable out
-- of combat against 6.5% in combat, which is why keying the snapshot by
-- spellId emptied it the moment a fight started. The enumeration itself was
-- never the problem.
--
-- The payload of UNIT_AURA carries the spellId at APPLICATION time, together
-- with an auraInstanceID. Learning the pair once and then tracking the
-- INSTANCE survives the field going secret afterwards -- this is what the
-- reference cooldown addons do, and the event handler here was discarding the
-- payload entirely.
local activeBySpell, spellByInstance = {}, {}

-- Ids the client has actually been willing to name while we watched. Learned,
-- never authored: a hand-written table of "non-secret" ids is exactly the kind
-- of data that rots at every patch, and this one maintains itself. Persisted
-- so the knowledge survives a session.
local function LearnReadable(sid)
    if not sid then return end
    local db = TomoModDB and TomoModDB.cooldownForge
    if not db then return end
    db.readableAuraIDs = db.readableAuraIDs or {}
    if db.readableAuraIDs[sid] == nil then db.readableAuraIDs[sid] = true end
end

--- Has this id ever been readable? Used to tell "the client hides this one"
--- from "this buff is simply not up", which is the difference between a bug
--- and a limit when a tracked buff refuses to appear.
function CDF.IsAuraIDReadable(sid)
    local db = TomoModDB and TomoModDB.cooldownForge
    local t = db and db.readableAuraIDs
    return (t and t[tonumber(sid) or -1]) and true or false
end

local function AuraAdded(aura)
    if type(aura) ~= "table" then return end
    local sid = readableNumber(aura.spellId)
    local iid = readableNumber(aura.auraInstanceID)

    LearnReadable(sid)
    if not (sid and iid) then return end
    spellByInstance[iid] = sid
    activeBySpell[sid] = iid
end

local function AuraRemoved(iid)
    iid = readableNumber(iid)
    if not iid then return end
    local sid = spellByInstance[iid]
    spellByInstance[iid] = nil
    if sid and activeBySpell[sid] == iid then activeBySpell[sid] = nil end
end

local function AuraFullUpdate()
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return end
    -- [12.1] A restricted frame cannot be rescanned. Returning leaves the
    -- watch list as it was; the next UNIT_AURA will try again.
    --
    -- This has to come BEFORE the two wipes below, not after: returning once
    -- they have run leaves the list empty, which is the opposite of leaving
    -- it as it was, and CooldownForge then tracks nothing until the next
    -- readable update arrives.
    if TomoMod_Utils and TomoMod_Utils.AurasRestricted and TomoMod_Utils.AurasRestricted() then return end
    for k in pairs(activeBySpell) do activeBySpell[k] = nil end
    for k in pairs(spellByInstance) do spellByInstance[k] = nil end
    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
        if not ok or not aura then break end
        AuraAdded(aura)
    end
end

-- Called from the event handler with the UNIT_AURA payload.
function CDF.OnUnitAura(updateInfo)
    if type(updateInfo) ~= "table" then
        AuraFullUpdate()
        return
    end

    -- [12.1] The whole payload can arrive secret: isFullUpdate as a secret
    -- boolean, addedAuras and the id lists as secret tables. A plain
    -- `if updateInfo.isFullUpdate` is a boolean test on a secret value and
    -- throws before anything else runs -- 38 times in one session in the
    -- report that prompted this.
    --
    -- Unreadable is treated as a full update: the incremental lists are
    -- just as unreadable, so rescanning is the only way to stay current.
    local full = updateInfo.isFullUpdate
    if issecretvalue and issecretvalue(full) then
        AuraFullUpdate()
        return
    end
    if full then
        AuraFullUpdate()
        return
    end

    -- The lists themselves can be secret even when the flag is not, and
    -- ipairs on a secret table throws the same way. A failed walk falls
    -- back to a rescan rather than silently dropping the update.
    if updateInfo.addedAuras then
        local ok = pcall(function()
            for _, a in ipairs(updateInfo.addedAuras) do AuraAdded(a) end
        end)
        if not ok then
            AuraFullUpdate()
            return
        end
    end
    if updateInfo.updatedAuraInstanceIDs then
        -- A buff that merely gains a stack is reported here, never in
        -- addedAuras: without this, an instance first seen mid-fight was
        -- never learned at all.
        local get = C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID
        local ok = pcall(function()
            for _, iid in ipairs(updateInfo.updatedAuraInstanceIDs) do
                local n = readableNumber(iid)
                if n and spellByInstance[n] == nil and get then
                    local ok2, a = pcall(get, "player", n)
                    if ok2 and a then AuraAdded(a) end
                end
            end
        end)
        if not ok then
            AuraFullUpdate()
            return
        end
    end
    if updateInfo.removedAuraInstanceIDs then
        -- A failed removal walk is not worth a rescan: the worst case is a
        -- stale entry that the next full update clears anyway, and rescanning
        -- on every removal event would be far more expensive than the bug.
        pcall(function()
            for _, iid in ipairs(updateInfo.removedAuraInstanceIDs) do AuraRemoved(iid) end
        end)
    end
end

-- Is the instance we recorded for this spell still on the player? Asking by
-- INSTANCE keeps the query C-side, so nothing depends on reading spellId now.
local function LiveInstance(spellID)
    local iid = activeBySpell[spellID]
    if not iid then return nil end
    local get = C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID
    if not get then return iid end
    local ok, aura = pcall(get, "player", iid)
    if ok and aura then return iid, aura end
    AuraRemoved(iid)
    return nil
end

-- ---------------------------------------------------------------------
-- Source 0: Blizzard's own Tracked Buffs viewer
-- ---------------------------------------------------------------------
-- The client draws these procs correctly mid-fight because its own viewer is
-- not subject to the aura restrictions we are. Rather than fight for the aura
-- data, read the verdict Blizzard already reached: an item frame of
-- BuffIconCooldownViewer is shown exactly while its buff is up, and its
-- Cooldown widget and Applications text already hold the numbers on screen.
--
-- Nothing here is hardcoded: the spellID -> frame mapping comes from
-- CDMScanner, which caches it out of combat to avoid touching the protected
-- cooldownID property during a fight.
local VIEWER_NAMES = { "BuffIconCooldownViewer", "BuffBarCooldownViewer" }

local function ViewerFrameFor(cands)
    local Scanner = TomoMod_CDMScanner
    if not (Scanner and Scanner.GetCachedSpellID) then return nil end
    local want = {}
    for _, id in ipairs(cands) do want[id] = true end
    for _, name in ipairs(VIEWER_NAMES) do
        local viewer = _G[name]
        if viewer and viewer.GetChildren then
            local ok, children = pcall(function() return { viewer:GetChildren() } end)
            if ok then
                for _, frame in ipairs(children) do
                    local sid = Scanner.GetCachedSpellID(frame)
                    if sid and want[sid] then return frame, sid end
                    local info = Scanner.GetCachedInfo and Scanner.GetCachedInfo(frame)
                    local ov = info and info.overrideSpellID
                    if ov and want[ov] then return frame, ov end
                end
            end
        end
    end
    return nil
end

-- Blizzard shows the frame exactly while the buff is up. Its Cooldown widget
-- and Applications text are display sinks, so reading them costs nothing in
-- taint terms and gives the same numbers the player already sees.
local function ViewerAuraState(cands)
    local frame, sid = ViewerFrameFor(cands)
    if not frame then return nil end
    local okShown, shown = pcall(frame.IsShown, frame)
    if not okShown or not shown then
        return { active = false, matchedID = sid, viewer = true, timed = false }
    end

    -- `timed` is always present, never nil: every other producer of an aura
    -- state sets it explicitly and callers test it directly.
    local st = { active = true, matchedID = sid, viewer = true, timed = false }

    -- The item frame carries the aura's instance id IN CLEAR -- a diagnostics
    -- dump showed auraInstanceID=281 sitting next to auraSpellID=<secret
    -- number>. The instance-scoped accessors are display-safe by design, so
    -- this is the route to duration and stacks that never reads a secret.
    local iid = readableNumber(frame.auraInstanceID)
    if iid then
        st.auraInstanceID = iid
        if C_UnitAuras and C_UnitAuras.GetAuraApplicationDisplayCount then
            local okN, n = pcall(C_UnitAuras.GetAuraApplicationDisplayCount, "player", iid)
            n = okN and readableNumber(n) or nil
            if n and n > 1 then st.applications = n end
        end
        if C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID then
            local okA, ad = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID, "player", iid)
            if okA and type(ad) == "table" then
                local d = readableNumber(ad.duration)
                local e = readableNumber(ad.expirationTime)
                if d and e and d > 0 then
                    st.duration, st.expirationTime, st.timed = d, e, true
                end
                if st.applications == nil then
                    local n = readableNumber(ad.applications)
                    if n and n > 1 then st.applications = n end
                end
            end
        end
        if not st.timed and C_UnitAuras and C_UnitAuras.GetAuraDuration then
            local okD, o = pcall(C_UnitAuras.GetAuraDuration, "player", iid)
            if okD and o then st.durationObject = o end
        end
        -- Feed the registry while the pair is readable: the viewer names the
        -- spell here even when the enumeration APIs will not.
        local ssid = readableNumber(frame.auraSpellID)
        if ssid then AuraAdded({ spellId = ssid, auraInstanceID = iid }) end
    end

    local cd = (not st.timed)
           and (frame.Cooldown or (frame.Icon and frame.Icon.Cooldown)) or nil
    if cd and cd.GetCooldownTimes then
        local okT, startMs, durMs = pcall(cd.GetCooldownTimes, cd)
        local sMs, dMs = readableNumber(startMs), readableNumber(durMs)
        if okT and sMs and dMs and dMs > 0 then
            st.duration       = dMs / 1000
            st.expirationTime = (sMs + dMs) / 1000
            st.timed          = true
        end
    end
    -- Measured in combat: GetCooldownTimes yields nothing usable, yet the
    -- client still DRAWS the countdown. A rendered string is a display sink
    -- and stays readable, so mirroring it shows the player the very number
    -- Blizzard settled on -- no swipe is possible without the underlying
    -- values, but the figure is exact.
    if not st.timed and cd and cd.GetRegions then
        local okR, regions = pcall(function() return { cd:GetRegions() } end)
        if okR then
            for _, r in ipairs(regions) do
                if r.GetObjectType and r:GetObjectType() == "FontString"
                   and r.IsShown and r:IsShown() then
                    local okX, txt = pcall(r.GetText, r)
                    local safe = okX and readableString(txt) or nil
                    if safe then
                        st.timerText = safe
                        break
                    end
                end
            end
        end
    end

    -- Stacks live on the CHILD icon, not on the item frame -- reading
    -- frame.Applications returned nil for every entry. The bar variant nests
    -- them one level deeper again.
    local apps = (frame.Icon and frame.Icon.Applications)
              or (frame.Applications and frame.Applications.Applications)
              or frame.Applications
              or frame.Count
    if apps and apps.GetText then
        local okA, txt = pcall(apps.GetText, apps)
        -- tonumber on a secret string is just as unsafe as comparing one.
        local n = readableNumber(tonumber(readableString(okA and txt or nil) or ""))
        if n and n > 0 then st.applications = n end
    end
    return st
end

--- Seconds left, or nil when the client will not say.
---
--- Items and trinkets hand back plain numbers. Spells only expose a duration
--- object: feeding it to the probe and reading the times back is worth a try,
--- but those values are often secret, and the guard turns that into nil rather
--- than into a comparison. Callers must treat nil as "no threshold", never as
--- zero -- a spell whose remaining time is unreadable must not look ready.
function CDF.RemainingSeconds(state)
    if type(state) ~= "table" then return nil end

    if not state.isSpell then
        local d = readableNumber(state.duration)
        local st = readableNumber(state.start)
        if not (d and st) or d <= 0 then return nil end
        local left = (st + d) - GetTime()
        return (left > 0) and left or nil
    end

    local durObj = (state.maxCharges and state.maxCharges > 1 and state.chargeDurObj)
                   or state.durObj
    if not durObj then return nil end
    local p = getProbe()
    local ok = pcall(p.SetCooldownFromDurationObject, p, durObj)
    if not ok or not p.GetCooldownTimes then return nil end
    local okT, startMs, durMs = pcall(p.GetCooldownTimes, p)
    local sMs, dMs = readableNumber(startMs), readableNumber(durMs)
    if not (okT and sMs and dMs) or dMs <= 0 then return nil end
    local left = ((sMs + dMs) / 1000) - GetTime()
    return (left > 0) and left or nil
end

-- ---------------------------------------------------------------------
-- [12.1] Probe source.
--
-- One hidden aura container per tracked spell, restricted to that spell's
-- candidate ids. The engine fills it and drives the icon's own cooldown,
-- so the swipe is right in combat -- the case every source below fails,
-- because they all end in a read the client refuses.
--
-- Probes are keyed by icon, weakly: the studio rebuilds its bars freely
-- and a probe must not keep a discarded icon alive.
-- ---------------------------------------------------------------------
local probes = setmetatable({}, { __mode = "k" })

-- Attaches a probe to an icon, or returns the one it already has.
function CDF.EnsureAuraProbe(icon, spellID)
    if not icon or not icon.cd then return nil end
    local existing = probes[icon]
    if existing and existing.spellID == spellID then return existing.probe end

    local AC = TomoMod_AuraContainer
    if not AC or not AC.CreateAuraProbe then return nil end

    -- The studio reuses icons across rebuilds, so an icon can arrive here
    -- carrying a probe for a different spell. Leaving that one attached
    -- would put two containers on the same icon, both driving icon.cd.
    if existing and existing.probe and AC.DestroyAuraProbe then
        AC.DestroyAuraProbe(existing.probe)
    end

    local cands = CDF.AuraCandidates(spellID) or { spellID }
    local include = {}
    for _, id in ipairs(cands) do include[id] = true end
    if not next(include) then return nil end

    local probe = AC.CreateAuraProbe(icon, include, icon.cd)
    probes[icon] = { spellID = spellID, probe = probe }
    return probe
end

-- True when a probe is attached to this icon and driving its cooldown.
--
-- The engine writes that widget continuously. Anything else writing it
-- too gives one Cooldown two owners, and the swipe flickers as they take
-- turns -- so the renderer asks this before touching it at all, not just
-- before clearing it.
--
-- Attached is not the same as driving, and the difference matters: the
-- engine side rests on API shapes this addon cannot verify from Lua. A probe
-- that never fills would, on "attached" alone, lock the readable sources out
-- of a swipe it is not drawing either -- no swipe at all, and no error to say
-- why. Ownership therefore transfers the first time the probe demonstrably
-- shows its button, and stays transferred: flipping it back each time the
-- aura drops would hand the widget between two owners again, which is the
-- flicker this exists to remove.
function CDF.ProbeDrives(icon)
    if not icon then return false end
    local held = probes[icon]
    return (held and held.probe and held.proven) and true or false
end

-- The probe's verdict, or nil when there is no probe to ask.
function CDF.ProbeAuraState(icon, spellID)
    local probe = CDF.EnsureAuraProbe(icon, spellID)
    if not probe then return nil end

    local AC = TomoMod_AuraContainer
    if not AC.ProbeActive(probe) then return { active = false, fromProbe = true } end

    -- It answered: from here the engine owns this icon's cooldown.
    local held = probes[icon]
    if held then held.proven = true end

    -- Deliberately no duration numbers: the engine already drives the
    -- icon's cooldown, and inventing figures here would mean reading the
    -- aura again. `timed` stays false so the renderer leaves the swipe
    -- alone rather than clearing it.
    return { active = true, fromProbe = true }
end

function CDF.GetAuraState(spellID)
    spellID = tonumber(spellID)
    if not spellID then return nil end

    local cands = CDF.AuraCandidates(spellID) or { spellID }
    local aura, matched

    -- Sources in order of accuracy. Measured over ~12 700 evaluations each:
    -- the instance registry scored 583 hits, ALL in combat; the name match
    -- 323, all but two out of combat. The HELPFUL index scan (5) and
    -- GetPlayerAuraBySpellID (2) were dropped -- the direct call never errors,
    -- it simply returned nil 19 143 times in combat.

    -- 0. Blizzard's own Tracked Buffs viewer. It is not subject to the aura
    --    restrictions we are, so when it carries the spell it is the most
    --    accurate source available -- and the only one that reports duration
    --    and stacks for a proc applied mid-fight.
    local vst = ViewerAuraState(cands)
    if vst and vst.active and (vst.timed or vst.timerText or vst.applications) then
        return vst
    end

    -- 1. instance registry: works during a fight for auras learned while the
    --    client was still willing to name them.
    for _, id in ipairs(cands) do
        local iid, res = LiveInstance(id)
        if iid then
            aura, matched = res, id
            if not aura then aura = { auraInstanceID = iid } end
            aura.auraInstanceID = aura.auraInstanceID or iid
            break
        end
    end

    -- 1b. the viewer said the buff is up but gave no numbers: that verdict is
    --     still better than nothing, so keep it rather than reporting absent.
    if not aura and vst and vst.active then
        return vst
    end

    -- 2. name match: carries the out-of-combat case, where the client still
    --    names auras freely.
    if not aura and C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName
       and C_Spell and C_Spell.GetSpellName then
        local okN, name = pcall(C_Spell.GetSpellName, spellID)
        name = okN and readableString(name) or nil
        if name then
            local okA, res = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", name, "HELPFUL")
            if okA and res then aura, matched = res, spellID end
        end
    end

    if not aura then return { active = false } end

    local dur  = readableNumber(aura.duration)
    local exp  = readableNumber(aura.expirationTime)
    local apps = readableNumber(aura.applications)

    -- The instance-scoped accessors return display-safe values where the raw
    -- fields are secret, which is what brings the timer and the stack count
    -- back inside restricted content.
    local iid = readableNumber(aura.auraInstanceID)
    local durObj
    if iid and C_UnitAuras then
        if C_UnitAuras.GetAuraDuration then
            local ok, d = pcall(C_UnitAuras.GetAuraDuration, "player", iid)
            if ok then durObj = d end
        end
        if apps == nil and C_UnitAuras.GetAuraApplicationDisplayCount then
            local ok, n = pcall(C_UnitAuras.GetAuraApplicationDisplayCount, "player", iid)
            if ok then apps = readableNumber(n) end
        end
    end
    return {
        active         = true,
        matchedID      = matched,
        durationObject = durObj,
        duration       = dur,
        expirationTime = exp,
        applications   = apps,
        -- Only a pair of readable, finite numbers can drive the swipe.
        timed          = (dur ~= nil and exp ~= nil and dur > 0) or false,
    }
end

function CDF.SetAuraWatch(on)
    on = on and true or false
    if CDF._auraWatch == on then return end
    CDF._auraWatch = on
    if on then
        w:RegisterUnitEvent("UNIT_AURA", "player")
    else
        w:UnregisterEvent("UNIT_AURA")
    end
end

-- [S9] SPELL_UPDATE_USABLE fires on every resource threshold crossing, so
-- it follows the same pay-for-what-you-use rule as UNIT_AURA above: the
-- renderer turns it on only while a bar actually consumes castability
-- (tint mode, "usable" glow condition, or hideOnUnusable). It is routed to
-- the "cooldown" reason, i.e. a light refresh; bars using hideOnUnusable
-- detect the set change through their ready signature and re-lay out.
function CDF.SetUsableWatch(on)
    on = on and true or false
    if CDF._usableWatch == on then return end
    CDF._usableWatch = on
    if on then
        w:RegisterEvent("SPELL_UPDATE_USABLE")
    else
        w:UnregisterEvent("SPELL_UPDATE_USABLE")
    end
end

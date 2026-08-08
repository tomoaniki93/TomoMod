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
function CDF.IsEntryVisible(entry)
    if type(entry) ~= "table" or entry.enabled == false then return false end
    local spec = tonumber(entry.spec) or 0
    if spec ~= 0 and spec ~= CDF.CurrentSpecID() then return false end

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
w:SetScript("OnEvent", function(_, event, unit, updateInfo)
    if event == "UNIT_AURA" then
        CDF.OnUnitAura(updateInfo)
    end
    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "SPELLS_CHANGED"
       or event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED"
       or event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED"
       or event == "GROUP_ROSTER_UPDATE" or event == "ZONE_CHANGED_NEW_AREA"
       or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED"
       or event == "TRAIT_CONFIG_UPDATED" then
        if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
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
    for k in pairs(activeBySpell) do activeBySpell[k] = nil end
    for k in pairs(spellByInstance) do spellByInstance[k] = nil end
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return end
    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
        if not ok or not aura then break end
        AuraAdded(aura)
    end
end

-- Called from the event handler with the UNIT_AURA payload.
function CDF.OnUnitAura(updateInfo)
    if type(updateInfo) ~= "table" or updateInfo.isFullUpdate then
        AuraFullUpdate()
        return
    end
    if updateInfo.addedAuras then
        for _, a in ipairs(updateInfo.addedAuras) do AuraAdded(a) end
    end
    if updateInfo.updatedAuraInstanceIDs then
        -- A buff that merely gains a stack is reported here, never in
        -- addedAuras: without this, an instance first seen mid-fight was
        -- never learned at all.
        local get = C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID
        for _, iid in ipairs(updateInfo.updatedAuraInstanceIDs) do
            local n = readableNumber(iid)
            if n and spellByInstance[n] == nil and get then
                local ok, a = pcall(get, "player", n)
                if ok and a then AuraAdded(a) end
            end
        end
    end
    if updateInfo.removedAuraInstanceIDs then
        for _, iid in ipairs(updateInfo.removedAuraInstanceIDs) do AuraRemoved(iid) end
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
    local cd = frame.Cooldown or (frame.Icon and frame.Icon.Cooldown)
    if cd and cd.GetCooldownTimes then
        local okT, startMs, durMs = pcall(cd.GetCooldownTimes, cd)
        local sMs, dMs = readableNumber(startMs), readableNumber(durMs)
        if okT and sMs and dMs and dMs > 0 then
            st.duration       = dMs / 1000
            st.expirationTime = (sMs + dMs) / 1000
            st.timed          = true
        end
    end
    local apps = frame.Applications or frame.Count
    if apps and apps.GetText then
        local okA, txt = pcall(apps.GetText, apps)
        local n = okA and tonumber(txt) or nil
        if n then st.applications = n end
    end
    return st
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
    if vst and vst.active and (vst.timed or vst.applications) then
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
        if okN and type(name) == "string" and name ~= "" then
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

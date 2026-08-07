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
    local get = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
    if not get then return false end
    return get(spellID) ~= nil
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
w:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "SPELLS_CHANGED"
       or event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED"
       or event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED"
       or event == "GROUP_ROSTER_UPDATE" or event == "ZONE_CHANGED_NEW_AREA"
       or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" then
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

function CDF.GetAuraState(spellID)
    spellID = tonumber(spellID)
    if not spellID then return nil end
    local get = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
    if not get then return nil end
    local aura = get(spellID)
    if not aura then return { active = false } end

    local dur  = readableNumber(aura.duration)
    local exp  = readableNumber(aura.expirationTime)
    local apps = readableNumber(aura.applications)
    return {
        active         = true,
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

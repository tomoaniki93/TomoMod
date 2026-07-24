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
function CDF.IsBarVisible(bar)
    if type(bar) ~= "table" then return false end
    if bar.enabled == false then return false end
    local v = bar.visibility
    if type(v) ~= "table" then return true end

    if v.inCombat ~= nil then
        local inCombat = (InCombatLockdown() or UnitAffectingCombat("player")) and true or false
        if inCombat ~= v.inCombat then return false end
    end
    if v.inInstance ~= nil then
        local inInst = IsInInstance() and true or false
        if inInst ~= v.inInstance then return false end
    end
    if v.inRaid ~= nil then
        local inRaid = IsInRaid() and true or false
        if inRaid ~= v.inRaid then return false end
    end
    if v.inGroup ~= nil then
        local inGroup = IsInGroup() and true or false
        if inGroup ~= v.inGroup then return false end
    end
    return true
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
w:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "SPELLS_CHANGED"
       or event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED"
       or event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED"
       or event == "GROUP_ROSTER_UPDATE" or event == "ZONE_CHANGED_NEW_AREA"
       or event == "PLAYER_ENTERING_WORLD" then
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

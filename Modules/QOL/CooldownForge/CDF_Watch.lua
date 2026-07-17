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
w:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "SPELLS_CHANGED"
       or event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        fireUpdate("layout")
    else
        fireUpdate("cooldown")
    end
end)
CDF._watchFrame = w

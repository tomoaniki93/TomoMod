-- =====================================================================
-- AB_Engine.lua v1.0.0 -- ActionBars state engine (Lot A1)
--
-- Single source of truth for "what state is this action button in".
-- Owns registration, adapters, event wiring, diffing and dispatch.
--
-- Design goals:
--   * Button abstraction. The engine never assumes the underlying frame is
--     a Blizzard button. An adapter translates a frame into raw state, so a
--     future TomoMod-owned secure button only needs a new adapter, not a
--     rewrite of every consumer (skin, glow, hotkeys, ...).
--   * Event driven. Replaces the previous global 0.2s OnUpdate that pushed
--     SetVertexColor on every button five times a second regardless of
--     whether anything had changed. Only range still needs a ticker (no
--     event exists for it), and that ticker is gated on having a target.
--   * Diffing. Consumers are only called when a value actually changed.
--   * 12.x safety. Every game API read goes through pcall and every boolean
--     is resolved inside a protected call, so a secret value degrades to
--     "unknown" (nil) instead of erroring. No arithmetic is ever performed
--     on a value returned by the game.
--
-- Public API
--   ABE.RegisterButton(frame, kind, barId, index) -> entry
--   ABE.UnregisterButton(frame)
--   ABE.GetEntry(frame) -> entry
--   ABE.GetState(frame) -> state table (read only)
--   ABE.Entries() -> iterator over entries
--   ABE.Scan() / ABE.ScanBar(barId)
--   ABE.RegisterCallback(owner, event, fn)
--   ABE.UnregisterCallback(owner, event)
--   ABE.Refresh(what) / ABE.RefreshButton(frame, what)
--   ABE.SetEnabled(bool) / ABE.IsEnabled()
--   ABE.SetRangeInterval(seconds)
--
-- Callback events: "register", "unregister", "action", "usable", "range",
--                  "state", "pushed", "cooldown", "count"
-- Callback signature: fn(entry, state)
-- =====================================================================

TomoMod_ABEngine = TomoMod_ABEngine or {}
local ABE = TomoMod_ABEngine

local AB = nil  -- resolved lazily, ActionBars.lua may load after us

-- =====================================================================
-- CONSTANTS
-- =====================================================================

ABE.KIND_ACTION = "action"
ABE.KIND_PET    = "pet"
ABE.KIND_STANCE = "stance"

local KIND_ACTION = ABE.KIND_ACTION
local KIND_PET    = ABE.KIND_PET
local KIND_STANCE = ABE.KIND_STANCE

local DEFAULT_RANGE_INTERVAL = 0.15

-- =====================================================================
-- STATE
-- =====================================================================

local entries       = {}     -- array of entry
local entryByFrame  = {}     -- frame -> entry
local entriesByBar  = {}     -- barId -> array of entry

local callbacks     = {}     -- event -> { [owner] = fn }
local enabled       = false
local rangeInterval = DEFAULT_RANGE_INTERVAL

-- =====================================================================
-- SAFE READS (12.x secret values never leave this block)
-- =====================================================================

-- Resolves a game-returned value to true / false / nil.
-- nil stays nil (meaning "not applicable", e.g. a spell with no range),
-- and anything that cannot be coerced (a secret value) also becomes nil,
-- which every consumer treats as "no information, render as normal".
local function BoolOf(v)
    if v == nil then return nil end
    return v and true or false
end

local function ResolveBool(v)
    local ok, res = pcall(BoolOf, v)
    if ok then return res end
    return nil
end

local function SafeCall(fn, a, b)
    if type(fn) ~= "function" then return nil end
    local ok, r1, r2, r3, r4, r5, r6 = pcall(fn, a, b)
    if not ok then return nil end
    return r1, r2, r3, r4, r5, r6
end

-- =====================================================================
-- ADAPTERS
-- Each adapter turns a frame into a raw state table. Adding a new button
-- implementation later means adding an adapter here and nothing else.
-- =====================================================================

local adapters = {}

-- --- Blizzard / TomoMod action buttons -------------------------------
adapters[KIND_ACTION] = {
    GetSlot = function(frame)
        local slot = frame.action
        if slot == nil and frame.GetAttribute then
            slot = SafeCall(frame.GetAttribute, frame, "action")
        end
        if type(slot) ~= "number" then return nil end
        return slot
    end,

    ReadState = function(frame, slot, out)
        if not slot then
            out.hasAction = false
            return out
        end
        out.hasAction = ResolveBool(SafeCall(HasAction, slot))
        out.equipped  = ResolveBool(SafeCall(IsEquippedAction, slot))

        local usable, noMana = SafeCall(IsUsableAction, slot)
        out.usable = ResolveBool(usable)
        out.noMana = ResolveBool(noMana)

        local current = ResolveBool(SafeCall(IsCurrentAction, slot))
        if current ~= true then
            current = ResolveBool(SafeCall(IsAutoRepeatAction, slot))
        end
        out.active = current
        return out
    end,

    ReadRange = function(frame, slot)
        if not slot then return nil end
        return ResolveBool(SafeCall(IsActionInRange, slot))
    end,

    -- What the slot currently holds. Everything here comes from
    -- GetActionInfo / GetActionText, which are plain (non-secret) data.
    GetContent = function(frame, slot)
        if not slot then return nil end
        local actionType, id, subType = SafeCall(GetActionInfo, slot)
        if type(actionType) ~= "string" then return nil end

        local out = { actionType = actionType, id = id, subType = subType }
        out.macroText = SafeCall(GetActionText, slot)

        if actionType == "spell" then
            out.spellID = tonumber(id)
        elseif actionType == "item" then
            out.itemID = tonumber(id)
        elseif actionType == "macro" then
            local sid = SafeCall(GetMacroSpell, id)
            out.spellID = tonumber(sid)
            if not out.spellID then
                local _, link = SafeCall(GetMacroItem, id)
                if type(link) == "string" then
                    out.itemID = tonumber(string.match(link, "item:(%d+)"))
                end
            end
        end
        return out
    end,

    GetTexture = function(frame, slot)
        if not slot then return nil end
        return SafeCall(GetActionTexture, slot)
    end,

    -- Spell cooldowns are secret in 12.x: only duration objects cross this
    -- boundary, and they are never inspected. Items return plain numbers.
    GetCooldown = function(frame, slot, content)
        if not content then return nil end

        if content.spellID and C_Spell then
            local sid = content.spellID
            local charges = SafeCall(C_Spell.GetSpellCharges, sid)
            local maxCharges = 1
            if type(charges) == "table" and type(charges.maxCharges) == "number" then
                maxCharges = charges.maxCharges
            end
            return {
                isSpell      = true,
                durObj       = SafeCall(C_Spell.GetSpellCooldownDuration, sid),
                chargeDurObj = SafeCall(C_Spell.GetSpellChargeDuration, sid),
                maxCharges   = maxCharges,
            }
        end

        if content.itemID and C_Item then
            local start, duration, enable = SafeCall(C_Item.GetItemCooldown, content.itemID)
            if type(start) ~= "number" then return nil end
            return { isSpell = false, start = start, duration = duration or 0, enable = enable }
        end

        return nil
    end,

    -- "show" is derived from non-secret data only. "value" may be secret and
    -- must never be compared, only passed to FontString:SetText().
    GetCount = function(frame, slot, content)
        if not slot or not content then return { show = false } end

        if content.actionType == "item" then
            return { show = true, value = SafeCall(GetActionCount, slot), isCharges = false }
        end

        if content.spellID and C_Spell then
            local charges = SafeCall(C_Spell.GetSpellCharges, content.spellID)
            if type(charges) == "table" and type(charges.maxCharges) == "number"
               and charges.maxCharges > 1 then
                return { show = true, value = charges.currentCharges, isCharges = true }
            end
        end

        return { show = false }
    end,
}

-- --- Pet action buttons ----------------------------------------------
adapters[KIND_PET] = {
    GetSlot = function(frame)
        local id = frame.GetID and SafeCall(frame.GetID, frame)
        if type(id) ~= "number" then return nil end
        return id
    end,

    ReadState = function(frame, slot, out)
        if not slot then
            out.hasAction = false
            return out
        end
        local name, texture, _, isActive, autoAllowed, autoEnabled =
            SafeCall(GetPetActionInfo, slot)
        out.hasAction       = ResolveBool(texture or name)
        out.active          = ResolveBool(isActive)
        out.autoCastAllowed = ResolveBool(autoAllowed)
        out.autoCastEnabled = ResolveBool(autoEnabled)
        out.usable          = ResolveBool(SafeCall(GetPetActionSlotUsable, slot))
        out.noMana          = false
        return out
    end,

    ReadRange = function() return nil end,

    GetContent = function(frame, slot)
        if not slot then return nil end
        local name, _, _, _, _, _, spellID = SafeCall(GetPetActionInfo, slot)
        return { actionType = "pet", spellID = tonumber(spellID), macroText = name }
    end,

    GetTexture = function(frame, slot)
        if not slot then return nil end
        local _, texture = SafeCall(GetPetActionInfo, slot)
        return texture
    end,

    GetCooldown = function(frame, slot)
        if not slot then return nil end
        local start, duration, enable = SafeCall(GetPetActionCooldown, slot)
        if type(start) ~= "number" then return nil end
        return { isSpell = false, start = start, duration = duration or 0, enable = enable }
    end,

    GetCount = function() return { show = false } end,
}

-- --- Stance / shapeshift buttons -------------------------------------
adapters[KIND_STANCE] = {
    GetSlot = function(frame)
        local id = frame.GetID and SafeCall(frame.GetID, frame)
        if type(id) ~= "number" then return nil end
        return id
    end,

    ReadState = function(frame, slot, out)
        if not slot then
            out.hasAction = false
            return out
        end
        local texture, isActive, isCastable = SafeCall(GetShapeshiftFormInfo, slot)
        out.hasAction = ResolveBool(texture)
        out.active    = ResolveBool(isActive)
        out.usable    = ResolveBool(isCastable)
        out.noMana    = false
        return out
    end,

    ReadRange = function() return nil end,

    GetContent = function(frame, slot)
        if not slot then return nil end
        return { actionType = "stance" }
    end,

    GetTexture = function(frame, slot)
        if not slot then return nil end
        local texture = SafeCall(GetShapeshiftFormInfo, slot)
        return texture
    end,

    GetCooldown = function(frame, slot)
        if not slot then return nil end
        local start, duration, enable = SafeCall(GetShapeshiftFormCooldown, slot)
        if type(start) ~= "number" then return nil end
        return { isSpell = false, start = start, duration = duration or 0, enable = enable }
    end,

    GetCount = function() return { show = false } end,
}

function ABE.RegisterAdapter(kind, adapter)
    if type(kind) == "string" and type(adapter) == "table" then
        adapters[kind] = adapter
    end
end

-- =====================================================================
-- CALLBACK DISPATCH
-- =====================================================================

function ABE.RegisterCallback(owner, event, fn)
    if type(owner) ~= "string" or type(event) ~= "string" or type(fn) ~= "function" then
        return
    end
    if not callbacks[event] then callbacks[event] = {} end
    callbacks[event][owner] = fn
end

function ABE.UnregisterCallback(owner, event)
    if callbacks[event] then callbacks[event][owner] = nil end
end

-- Any pass that dispatches callbacks must iterate a SNAPSHOT of the entry
-- list. A consumer is allowed to register or unregister buttons from inside a
-- callback (AB_Button does exactly that when a slot turns into a flyout), and
-- UnregisterButton table.remove()s from `entries`, which would shift the array
-- under a live "for i = 1, #entries" loop and hand the next iteration a nil.
local function Snapshot()
    local buf = {}
    for i = 1, #entries do buf[i] = entries[i] end
    return buf
end

local function Fire(event, entry)
    local list = callbacks[event]
    if not list then return end
    for _, fn in pairs(list) do
        -- A misbehaving consumer must never break the whole engine.
        pcall(fn, entry, entry.state)
    end
end

-- =====================================================================
-- ENTRY HELPERS
-- =====================================================================

local scratch = {}

local function ClearScratch()
    for k in pairs(scratch) do scratch[k] = nil end
    return scratch
end

-- Recomputes the non-range state of an entry and fires only what changed.
local function UpdateEntryState(entry)
    local adapter = entry.adapter
    if not adapter then return end

    entry.slot = adapter.GetSlot(entry.frame)

    local new   = adapter.ReadState(entry.frame, entry.slot, ClearScratch())
    local state = entry.state

    local actionChanged = false
    local usableChanged = false
    local stateChanged  = false

    if state.hasAction ~= new.hasAction then
        state.hasAction = new.hasAction
        actionChanged = true
    end
    if state.equipped ~= new.equipped then
        state.equipped = new.equipped
        actionChanged = true
    end
    if state.usable ~= new.usable then
        state.usable = new.usable
        usableChanged = true
    end
    if state.noMana ~= new.noMana then
        state.noMana = new.noMana
        usableChanged = true
    end
    if state.active ~= new.active then
        state.active = new.active
        stateChanged = true
    end
    if state.autoCastAllowed ~= new.autoCastAllowed then
        state.autoCastAllowed = new.autoCastAllowed
        stateChanged = true
    end
    if state.autoCastEnabled ~= new.autoCastEnabled then
        state.autoCastEnabled = new.autoCastEnabled
        stateChanged = true
    end

    if actionChanged then
        ABE.InvalidateContent(entry)
        Fire("action", entry)
    end
    if usableChanged then Fire("usable", entry) end
    if stateChanged  then Fire("state",  entry) end
end

-- Identity of whatever the slot currently holds. Built only from
-- GetActionInfo data, which is never secret; wrapped anyway so that an
-- unexpected value degrades to "unknown" instead of erroring.
local function BuildSig(content)
    if not content then return "" end
    return tostring(content.actionType) .. "/" .. tostring(content.id)
        .. "/" .. tostring(content.spellID) .. "/" .. tostring(content.itemID)
end

-- Returns true when the slot now holds something different. Swapping spell A
-- for spell B leaves hasAction/usable/active untouched, so without this the
-- "action" callback would never fire and every consumer would keep rendering
-- the previous spell's data.
local function UpdateEntrySlot(entry)
    local adapter = entry.adapter
    if not adapter then return false end

    entry.slot = adapter.GetSlot(entry.frame)
    ABE.InvalidateContent(entry)

    local ok, sig = pcall(BuildSig, ABE.GetContentCached(entry))
    if not ok then sig = "" end

    if entry.sig ~= sig then
        entry.sig = sig
        return true
    end
    return false
end

local function UpdateEntryRange(entry)
    local adapter = entry.adapter
    if not adapter or not adapter.ReadRange then return end
    local inRange = adapter.ReadRange(entry.frame, entry.slot)
    if entry.state.inRange ~= inRange then
        entry.state.inRange = inRange
        Fire("range", entry)
    end
end

-- =====================================================================
-- REGISTRATION
-- =====================================================================

local function HookPushedState(entry)
    local frame = entry.frame
    if entry.pushHooked or not frame.SetButtonState then return end
    entry.pushHooked = true
    -- Visual-only reaction to a widget method: reads nothing protected and
    -- calls nothing protected, so this is taint-safe. It removes the need
    -- to poll GetButtonState() on every button every frame batch.
    hooksecurefunc(frame, "SetButtonState", function(self, newState)
        local e = entryByFrame[self]
        if not e then return end
        local pushed = (newState == "PUSHED")
        if e.state.pushed ~= pushed then
            e.state.pushed = pushed
            Fire("pushed", e)
        end
    end)
end

function ABE.RegisterButton(frame, kind, barId, index)
    if type(frame) ~= "table" or not frame.GetName then return nil end
    local existing = entryByFrame[frame]
    if existing then return existing end

    kind = kind or KIND_ACTION
    local adapter = adapters[kind]
    if not adapter then return nil end

    local entry = {
        frame   = frame,
        kind    = kind,
        barId   = barId,
        index   = index,
        adapter = adapter,
        slot    = nil,
        state   = {
            hasAction = nil, usable = nil, noMana = nil, inRange = nil,
            equipped  = nil, active = nil, pushed = false,
        },
    }

    entryByFrame[frame] = entry
    entries[#entries + 1] = entry
    if barId then
        if not entriesByBar[barId] then entriesByBar[barId] = {} end
        local list = entriesByBar[barId]
        list[#list + 1] = entry
    end

    HookPushedState(entry)
    entry.slot = adapter.GetSlot(frame)
    local okSig, sig = pcall(BuildSig, ABE.GetContentCached(entry))
    entry.sig = okSig and sig or ""

    Fire("register", entry)

    UpdateEntryState(entry)
    UpdateEntryRange(entry)

    return entry
end

function ABE.UnregisterButton(frame)
    local entry = entryByFrame[frame]
    if not entry then return end
    entryByFrame[frame] = nil
    for i = #entries, 1, -1 do
        if entries[i] == entry then table.remove(entries, i) end
    end
    local list = entry.barId and entriesByBar[entry.barId]
    if list then
        for i = #list, 1, -1 do
            if list[i] == entry then table.remove(list, i) end
        end
    end
    Fire("unregister", entry)
end

-- =====================================================================
-- CONTENT ACCESS
-- Consumers (AB_Render) ask the engine, never the game, so that a future
-- TomoMod-owned button only needs a new adapter.
-- =====================================================================

function ABE.GetContent(entry)
    if not entry or not entry.adapter or not entry.adapter.GetContent then return nil end
    return entry.adapter.GetContent(entry.frame, entry.slot)
end

function ABE.GetTexture(entry)
    if not entry or not entry.adapter or not entry.adapter.GetTexture then return nil end
    return entry.adapter.GetTexture(entry.frame, entry.slot)
end

function ABE.GetCooldown(entry, content)
    if not entry or not entry.adapter or not entry.adapter.GetCooldown then return nil end
    if content == nil then content = ABE.GetContent(entry) end
    return entry.adapter.GetCooldown(entry.frame, entry.slot, content)
end

function ABE.GetCount(entry, content)
    if not entry or not entry.adapter or not entry.adapter.GetCount then return nil end
    if content == nil then content = ABE.GetContent(entry) end
    return entry.adapter.GetCount(entry.frame, entry.slot, content)
end

-- Cached content. GetActionInfo and the C_Spell lookups are comparatively
-- expensive, so the result is memoised and only recomputed when the slot's
-- contents actually change (see the slot pass below). AB_Render and AB_Glow
-- both read through this, so a bar refresh costs one lookup, not two.
function ABE.InvalidateContent(entry)
    if entry then
        entry._content = nil
        entry._contentValid = false
    end
end

function ABE.GetContentCached(entry)
    if not entry then return nil end
    if entry._contentValid then return entry._content end
    entry._content = ABE.GetContent(entry)
    entry._contentValid = true
    return entry._content
end

function ABE.GetEntry(frame) return entryByFrame[frame] end
function ABE.GetState(frame)
    local entry = entryByFrame[frame]
    return entry and entry.state or nil
end

function ABE.Entries()
    local list = Snapshot()
    local i = 0
    return function()
        i = i + 1
        return list[i]
    end
end

function ABE.BarEntries(barId) return entriesByBar[barId] end

-- =====================================================================
-- SCANNING
-- Walks AB.BAR_DEFS (single source of truth) plus the buttons that live
-- outside it (override bar, extra action button).
-- =====================================================================

local function KindForBar(id)
    if id == "pet"    then return KIND_PET end
    if id == "stance" then return KIND_STANCE end
    return KIND_ACTION
end

function ABE.ScanBar(barId)
    AB = AB or TomoMod_ActionBars
    if not AB or not AB.GetDef then return end
    local def = AB.GetDef(barId)
    if not def then return end

    local kind = KindForBar(barId)
    local buttons = AB.GetButtons and AB.GetButtons(barId)
    if buttons then
        for i, btn in ipairs(buttons) do
            ABE.RegisterButton(btn, kind, barId, i)
        end
    else
        for i = 1, def.count do
            local btn = _G[def.prefix .. i]
            if btn then ABE.RegisterButton(btn, kind, barId, i) end
        end
    end
end

function ABE.Scan()
    AB = AB or TomoMod_ActionBars
    if AB and AB.BAR_DEFS then
        for _, def in ipairs(AB.BAR_DEFS) do
            ABE.ScanBar(def.id)
        end
    end

    for i = 1, 6 do
        local btn = _G["OverrideActionBarButton" .. i]
        if btn then ABE.RegisterButton(btn, KIND_ACTION, "override", i) end
    end

    local extra = _G["ExtraActionButton1"]
    if extra then ABE.RegisterButton(extra, KIND_ACTION, "extra", 1) end
end

-- =====================================================================
-- REFRESH
-- =====================================================================

function ABE.RefreshButton(frame, what)
    local entry = entryByFrame[frame]
    if not entry then return end
    if what ~= "range" then UpdateEntryState(entry) end
    if what ~= "state" then UpdateEntryRange(entry) end
end

function ABE.Refresh(what)
    local list = Snapshot()
    for i = 1, #list do
        local entry = list[i]
        if what == nil or what == "all" then
            if UpdateEntrySlot(entry) then Fire("action", entry) end
        end
        if what ~= "range" then UpdateEntryState(entry) end
        if what ~= "state" then UpdateEntryRange(entry) end
    end
end

-- Fires a pass-through event for consumers that own their own rendering
-- (cooldowns and counts are read by the consumer, not by the engine, so
-- that the 12.x duration-object handling stays in one place: Lot A2).
local function Broadcast(event)
    local list = Snapshot()
    for i = 1, #list do
        Fire(event, list[i])
    end
end

-- =====================================================================
-- BATCHED FLUSH
-- Several of these events fire many times in the same frame (a full bar
-- swap fires ACTIONBAR_SLOT_CHANGED per slot). Coalesce into one pass.
-- =====================================================================

local pending = {}
local flushFrame = CreateFrame("Frame")
flushFrame:Hide()

flushFrame:SetScript("OnUpdate", function(self)
    self:Hide()
    local doSlot     = pending.slot
    local doState    = pending.state
    local doCooldown = pending.cooldown
    local doCount    = pending.count
    pending.slot, pending.state = nil, nil
    pending.cooldown, pending.count = nil, nil

    if doSlot then
        local list = Snapshot()
        for i = 1, #list do
            local entry = list[i]
            if UpdateEntrySlot(entry) then Fire("action", entry) end
        end
    end
    if doState then
        local list = Snapshot()
        for i = 1, #list do
            UpdateEntryState(list[i])
        end
    end
    if doCooldown then Broadcast("cooldown") end
    if doCount    then Broadcast("count")    end
end)

local function Queue(what)
    if not enabled then return end
    pending[what] = true
    flushFrame:Show()
end

-- =====================================================================
-- RANGE TICKER
-- No event exists for "the target moved out of range", so this is the one
-- place a timer is unavoidable. It is gated: it only runs while a target
-- (hard or soft) exists, and it only dispatches on an actual change.
-- =====================================================================

local rangeFrame   = CreateFrame("Frame")
local rangeElapsed = 0
rangeFrame:Hide()

rangeFrame:SetScript("OnUpdate", function(self, delta)
    rangeElapsed = rangeElapsed + delta
    if rangeElapsed < rangeInterval then return end
    rangeElapsed = 0
    for i = 1, #entries do
        local entry = entries[i]
        -- Hot path: no snapshot, but stay nil-safe in case the list shrank.
        if entry and entry.kind == KIND_ACTION then
            UpdateEntryRange(entry)
        end
    end
end)

local function HasAnyTarget()
    if UnitExists("target")        then return true end
    if UnitExists("softenemy")     then return true end
    if UnitExists("softfriend")    then return true end
    if UnitExists("softinteract")  then return true end
    return false
end

local function UpdateRangeTicker()
    if enabled and HasAnyTarget() then
        if not rangeFrame:IsShown() then
            rangeElapsed = rangeInterval  -- first pass on the very next frame
            rangeFrame:Show()
        end
    else
        if rangeFrame:IsShown() then
            rangeFrame:Hide()
            -- Clear any stale out-of-range tint now that there is no target.
            for i = 1, #entries do
                local entry = entries[i]
                if entry and entry.state.inRange ~= nil then
                    entry.state.inRange = nil
                    Fire("range", entry)
                end
            end
        end
    end
end

function ABE.SetRangeInterval(seconds)
    if type(seconds) == "number" and seconds > 0 then
        rangeInterval = seconds
    else
        rangeInterval = DEFAULT_RANGE_INTERVAL
    end
end

function ABE.GetRangeInterval() return rangeInterval end

-- =====================================================================
-- EVENT WIRING
-- =====================================================================

local eventFrame = CreateFrame("Frame")

-- Events that can change WHAT sits in a slot. These trigger the (more
-- expensive) slot pass on top of the ordinary state pass.
local SLOT_EVENTS = {
    "ACTIONBAR_SLOT_CHANGED",
    "ACTIONBAR_PAGE_CHANGED",
    "UPDATE_BONUS_ACTIONBAR",
    "UPDATE_VEHICLE_ACTIONBAR",
    "UPDATE_OVERRIDE_ACTIONBAR",
    "UPDATE_SHAPESHIFT_FORM",
    "UPDATE_SHAPESHIFT_FORMS",
    "PET_BAR_UPDATE",
    "PET_UI_UPDATE",
    "UNIT_PET",
    "COMPANION_UPDATE",
    "PLAYER_SPECIALIZATION_CHANGED",
    "LEARNED_SPELL_IN_SKILL_LINE",
}

-- Events that only change HOW the existing action looks.
local STATE_EVENTS = {
    "ACTIONBAR_UPDATE_STATE",
    "ACTIONBAR_UPDATE_USABLE",
    "SPELL_UPDATE_USABLE",
    "UPDATE_SHAPESHIFT_USABLE",
    "PLAYER_EQUIPMENT_CHANGED",
    "TRADE_SKILL_SHOW",
    "TRADE_SKILL_CLOSE",
    "ARCHAEOLOGY_CLOSED",
    "PLAYER_ENTER_COMBAT",
    "PLAYER_LEAVE_COMBAT",
    "START_AUTOREPEAT_SPELL",
    "STOP_AUTOREPEAT_SPELL",
}

local COOLDOWN_EVENTS = {
    "ACTIONBAR_UPDATE_COOLDOWN",
    "SPELL_UPDATE_COOLDOWN",
    "SPELL_UPDATE_CHARGES",
    "PET_BAR_UPDATE_COOLDOWN",
    "UPDATE_SHAPESHIFT_COOLDOWN",
}

local COUNT_EVENTS = {
    "BAG_UPDATE_DELAYED",
}

local TARGET_EVENTS = {
    "PLAYER_TARGET_CHANGED",
    "PLAYER_SOFT_ENEMY_CHANGED",
    "PLAYER_SOFT_FRIEND_CHANGED",
    "PLAYER_SOFT_INTERACT_CHANGED",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
}

local eventKind = {}
for _, ev in ipairs(STATE_EVENTS)    do eventKind[ev] = "state"    end
for _, ev in ipairs(SLOT_EVENTS)     do eventKind[ev] = "slot"     end
for _, ev in ipairs(COOLDOWN_EVENTS) do eventKind[ev] = "cooldown" end
for _, ev in ipairs(COUNT_EVENTS)    do eventKind[ev] = "count"    end
for _, ev in ipairs(TARGET_EVENTS)   do eventKind[ev] = "target"   end

local function RegisterEvents()
    for ev in pairs(eventKind) do
        pcall(eventFrame.RegisterEvent, eventFrame, ev)
    end
end

eventFrame:SetScript("OnEvent", function(_, event)
    if not enabled then return end
    local kind = eventKind[event]
    if kind == "slot" then
        Queue("slot")
        Queue("state")
    elseif kind == "target" then
        UpdateRangeTicker()
        Queue("state")
    elseif kind == "cooldown" then
        Queue("cooldown")
    elseif kind == "count" then
        Queue("count")
        Queue("state")
    else
        Queue("state")
    end
end)

-- =====================================================================
-- ENABLE / DISABLE
-- =====================================================================

function ABE.IsEnabled() return enabled end

function ABE.SetEnabled(value)
    value = value and true or false
    if enabled == value then return end
    enabled = value
    if enabled then
        RegisterEvents()
        ABE.Scan()
        ABE.Refresh()
        UpdateRangeTicker()
    else
        eventFrame:UnregisterAllEvents()
        rangeFrame:Hide()
        flushFrame:Hide()
        pending.state, pending.cooldown, pending.count = nil, nil, nil
    end
end

-- =====================================================================
-- BOOT
-- Runs after ActionBars.lua has created its containers and reparented the
-- Blizzard buttons (AB.Initialize is scheduled at PLAYER_LOGIN + 0.5s and
-- applies at +0.3s after that).
-- =====================================================================

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    C_Timer.After(1.0, function()
        ABE.SetEnabled(true)
    end)
end)

-- Re-scan when a bar is rebuilt or the paging offset changes the slots.
local rescanFrame = CreateFrame("Frame")
rescanFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
rescanFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
rescanFrame:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
rescanFrame:SetScript("OnEvent", function()
    if not enabled then return end
    C_Timer.After(0.2, function()
        if not enabled then return end
        ABE.Scan()
        ABE.Refresh()
        UpdateRangeTicker()
    end)
end)

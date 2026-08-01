-- =====================================
-- TooltipInspect.lua
-- Inspection engine: average item level + specialization.
--
-- Deliberately knows nothing about tooltips. It answers one question --
-- "what do we know about this unit's gear and spec right now?" -- and tells
-- the caller whether the answer is final, on its way, or unavailable. The
-- display side (TooltipInfo.lua) owns everything visual.
--
-- Inspection is the expensive, fragile part of the feature set:
--   * the server throttles NotifyInspect, so requests are queued and paced;
--   * only one request can be in flight, and it can silently never answer,
--     so it times out;
--   * Blizzard's own inspect window uses the same channel, so we stay off it
--     entirely while InspectFrame is open rather than fight over it;
--   * results are cached per GUID, because a tooltip can be re-shown many
--     times a second while the mouse sits on a unit.
--
-- Compatible with WoW 12.x (Midnight).
-- =====================================

TomoMod_TooltipInspect = TomoMod_TooltipInspect or {}
local TQ = TomoMod_TooltipInspect

-- =====================================
-- TUNING
-- =====================================

local CACHE_TTL    = 300    -- seconds a result stays good (gear does change)
local MIN_INTERVAL = 1.5    -- seconds between two NotifyInspect calls
local TIMEOUT      = 3      -- seconds before a silent request is abandoned
local INSPECT_RANGE = 1     -- CheckInteractDistance index for inspect (~28y)

-- =====================================
-- STATE
-- =====================================

local cache      = {}       -- [guid] = { data = {...}, time = t }
local inFlight   = nil      -- { guid, unit, sentAt }
local lastSent   = 0
local callbacks  = {}
local eventFrame = nil

-- =====================================
-- SAFE HELPERS (Midnight secret-value proof)
-- =====================================

local function IsSecret(v)
    return (type(issecretvalue) == "function" and issecretvalue(v))
        or (type(issecurevalue) == "function" and issecurevalue(v))
        or false
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e, f
end

-- ORDER MATTERS: issecretvalue() is tested BEFORE any comparison touches the
-- value. `v == ""` evaluated first raises on precisely the secret values these
-- guards exist to catch. Never move a comparison above the IsSecret line.
local function SafeNum(v)
    if IsSecret(v) then return nil end
    if type(v) ~= "number" then return nil end
    return v
end

local function SafeStr(v)
    if IsSecret(v) then return nil end
    if type(v) ~= "string" then return nil end
    if v == "" then return nil end
    return v
end

-- `UnitIsPlayer(unit) == true` is a comparison too, and raises on a secret
-- boolean exactly like a string would.
local function SafeBool(v)
    if IsSecret(v) then return nil end
    if type(v) ~= "boolean" then return nil end
    return v
end

-- =====================================
-- SPEC LOOKUP
-- =====================================

local function SpecFromID(specID)
    specID = SafeNum(specID)
    if not specID or specID <= 0 then return nil end
    local _, name, _, icon = SafeCall(GetSpecializationInfoByID, specID)
    name = SafeStr(name)
    if not name then return nil end
    return { specID = specID, specName = name, specIcon = SafeNum(icon) }
end

-- =====================================
-- SELF (no inspection needed)
-- =====================================

local function SelfData()
    local data = {}

    -- GetAverageItemLevel returns overall then equipped; equipped is the one
    -- that matches what an inspect of us would report to someone else.
    local overall, equipped = SafeCall(GetAverageItemLevel)
    data.ilvl = SafeNum(equipped) or SafeNum(overall)

    local idx = SafeNum(SafeCall(GetSpecialization))
    if idx and idx > 0 then
        local specID = SafeNum(SafeCall(GetSpecializationInfo, idx))
        local spec = SpecFromID(specID)
        if spec then
            data.specID, data.specName, data.specIcon =
                spec.specID, spec.specName, spec.specIcon
        end
    end

    if not data.ilvl and not data.specName then return nil end
    return data
end

-- =====================================
-- READING AN INSPECT RESULT
-- =====================================

local function ReadInspect(unit)
    local data = {}

    if C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel then
        local ilvl = SafeNum(SafeCall(C_PaperDollInfo.GetInspectItemLevel, unit))
        -- 0 means "not populated yet", not "naked".
        if ilvl and ilvl > 0 then data.ilvl = math.floor(ilvl + 0.5) end
    end

    local spec = SpecFromID(SafeCall(GetInspectSpecialization, unit))
    if spec then
        data.specID, data.specName, data.specIcon =
            spec.specID, spec.specName, spec.specIcon
    end

    if not data.ilvl and not data.specName then return nil end
    return data
end

-- =====================================
-- ELIGIBILITY
-- =====================================

-- Blizzard's inspect window shares the single inspect channel with us. If it
-- is open, our request would overwrite the data it is displaying (and vice
-- versa), so we stand down completely rather than race it.
local function BlizzardInspectOpen()
    if InspectFrame == nil then return false end
    return SafeBool(SafeCall(InspectFrame.IsShown, InspectFrame)) == true
end

local function CanQuery(unit)
    if SafeBool(SafeCall(UnitExists, unit)) ~= true then return false end
    if SafeBool(SafeCall(UnitIsPlayer, unit)) ~= true then return false end
    if SafeBool(SafeCall(UnitIsConnected, unit)) ~= true then return false end
    if SafeBool(SafeCall(CanInspect, unit, false)) ~= true then return false end
    -- CanInspect does not test range; without this the request is simply
    -- swallowed and we would retry forever.
    if SafeBool(SafeCall(CheckInteractDistance, unit, INSPECT_RANGE)) ~= true then
        return false
    end
    return true
end

-- =====================================
-- QUEUE
-- =====================================

local function ClearInFlight()
    inFlight = nil
end

local function Send(unit, guid)
    local now = GetTime()
    if inFlight then
        -- A request that never answered must not block the queue forever.
        if (now - inFlight.sentAt) < TIMEOUT then return false end
        ClearInFlight()
    end
    if (now - lastSent) < MIN_INTERVAL then return false end
    if BlizzardInspectOpen() then return false end

    lastSent = now
    inFlight = { guid = guid, unit = unit, sentAt = now }
    SafeCall(NotifyInspect, unit)
    return true
end

local function Store(guid, data)
    if not guid or not data then return end
    cache[guid] = { data = data, time = GetTime() }
    for _, fn in ipairs(callbacks) do
        pcall(fn, guid, data)
    end
end

-- =====================================
-- PUBLIC API
-- =====================================

-- Query(unit) -> data, status
--   status "ready"       data is usable
--   status "pending"     a request is on its way; a callback will fire
--   status "unavailable" nothing can be known (out of range, NPC, offline)
function TQ.Query(unit)
    if type(unit) ~= "string" then return nil, "unavailable" end

    if SafeBool(SafeCall(UnitIsUnit, unit, "player")) == true then
        local data = SelfData()
        return data, data and "ready" or "unavailable"
    end

    local guid = SafeStr(SafeCall(UnitGUID, unit))
    if not guid then return nil, "unavailable" end

    local hit = cache[guid]
    if hit and (GetTime() - hit.time) < CACHE_TTL then
        return hit.data, "ready"
    end

    if not CanQuery(unit) then return nil, "unavailable" end
    if inFlight and inFlight.guid == guid then return nil, "pending" end

    if Send(unit, guid) then return nil, "pending" end

    -- Throttled or blocked this frame. Still "pending" from the caller's
    -- point of view: the next tooltip pass will try again.
    return nil, "pending"
end

function TQ.RegisterCallback(fn)
    if type(fn) == "function" then callbacks[#callbacks + 1] = fn end
end

function TQ.Purge(guid)
    if guid then cache[guid] = nil else cache = {} end
end

function TQ.Initialize()
    if eventFrame then return end
    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("INSPECT_READY")
    eventFrame:SetScript("OnEvent", function(_, _, guid)
        guid = SafeStr(guid)
        if not guid or not inFlight or inFlight.guid ~= guid then return end

        local unit = inFlight.unit
        ClearInFlight()

        local data = ReadInspect(unit)
        -- Releasing the inspect channel matters: holding it stops Blizzard's
        -- own inspect window from working until the next request.
        SafeCall(ClearInspectPlayer)

        if data then Store(guid, data) end
    end)
end

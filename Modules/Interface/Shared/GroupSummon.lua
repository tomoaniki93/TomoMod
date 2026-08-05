-- =====================================
-- Interface/Shared/GroupSummon.lua — shared incoming-summon state
--
-- PartyFrame and RaidFrame used to carry byte-identical copies of the summon
-- indicator logic, so a fix in one silently missed the other. This is now the
-- single source of truth for both.
--
-- Root cause of the stuck icon: C_IncomingSummon.IncomingSummonStatus keeps
-- returning the LAST known status (Accepted / Declined) once the summon has
-- been resolved server-side — the record is flagged inactive, it is not reset
-- to None. Blizzard's own CompactUnitFrame gates on HasIncomingSummon() before
-- reading the status; without that gate the icon stays up until a reload
-- rebuilds the client-side cache.
-- =====================================

TomoMod_GroupSummon = TomoMod_GroupSummon or {}
local GS = TomoMod_GroupSummon

local pcall, type = pcall, type
local GetTime = GetTime
local UnitExists = UnitExists
local issecretvalue = issecretvalue

local STATUS_NONE     = (Enum and Enum.SummonStatus and Enum.SummonStatus.None)     or 0
local STATUS_PENDING  = (Enum and Enum.SummonStatus and Enum.SummonStatus.Pending)  or 1
local STATUS_ACCEPTED = (Enum and Enum.SummonStatus and Enum.SummonStatus.Accepted) or 2
local STATUS_DECLINED = (Enum and Enum.SummonStatus and Enum.SummonStatus.Declined) or 3

GS.STATUS_NONE     = STATUS_NONE
GS.STATUS_PENDING  = STATUS_PENDING
GS.STATUS_ACCEPTED = STATUS_ACCEPTED
GS.STATUS_DECLINED = STATUS_DECLINED

local ATLAS_BY_STATUS = {
    [STATUS_PENDING]  = "RaidFrame-Icon-SummonPending",
    [STATUS_ACCEPTED] = "RaidFrame-Icon-SummonAccepted",
    [STATUS_DECLINED] = "RaidFrame-Icon-SummonDeclined",
}

-- Second safety net. Even if HasIncomingSummon were to stay true on some
-- realm or in some future build, a resolved summon is only meaningful for a
-- few seconds; after that the icon is noise, so drop it.
GS.RESOLVED_HOLD = 6

-- =====================================
-- SECRET-VALUE SAFE ACCESSOR
-- issecretvalue() runs before ANY comparison on the argument.
-- =====================================
local function SafeStatus(value)
    if issecretvalue(value) then return nil end
    if type(value) ~= "number" then return nil end
    return value
end

-- =====================================
-- HOLD EXPIRY
-- One shot per resolution per consumer; never fires from a hot path, so the
-- single closure allocation here is not on any per-frame budget.
-- =====================================
local holdArmed = {}

local function OnHoldExpired(refresh)
    holdArmed[refresh] = nil
    refresh()
end

function GS.ArmHoldExpiry(refresh)
    if type(refresh) ~= "function" then return end
    if holdArmed[refresh] then return end
    holdArmed[refresh] = true
    C_Timer.After(GS.RESOLVED_HOLD + 0.1, function() OnHoldExpired(refresh) end)
end

-- =====================================
-- STATUS QUERY
-- Returns a displayable status, or nil when nothing should be shown.
-- =====================================
function GS.GetStatus(unit)
    if not unit then return nil end
    if not UnitExists(unit) then return nil end
    if not C_IncomingSummon then return nil end

    -- Authoritative gate: goes false as soon as the summon is resolved or
    -- expires. This is the fix for the icon that stayed until /reload.
    if C_IncomingSummon.HasIncomingSummon then
        local ok, active = pcall(C_IncomingSummon.HasIncomingSummon, unit)
        if not ok then return nil end
        if issecretvalue(active) then return nil end
        if not active then return nil end
    end

    if not C_IncomingSummon.IncomingSummonStatus then return nil end
    local ok, raw = pcall(C_IncomingSummon.IncomingSummonStatus, unit)
    if not ok then return nil end

    local status = SafeStatus(raw)
    if not status then return nil end
    if status == STATUS_NONE then return nil end
    if not ATLAS_BY_STATUS[status] then return nil end

    return status
end

-- =====================================
-- APPLY TO AN INDICATOR
-- indicator : Frame carrying a .texture that accepts SetAtlas
-- unit      : unit token owned by the frame
-- refresh   : module-level function re-running the update for every frame of
--             that module, used once the hold window expires
-- =====================================
function GS.Apply(indicator, unit, refresh)
    if not indicator then return false end

    local status = GS.GetStatus(unit)
    if not status then
        indicator.tomoResolvedAt = nil
        indicator:Hide()
        return false
    end

    if status == STATUS_PENDING then
        indicator.tomoResolvedAt = nil
    else
        local since = indicator.tomoResolvedAt
        if not since then
            indicator.tomoResolvedAt = GetTime()
            GS.ArmHoldExpiry(refresh)
        elseif GetTime() - since >= GS.RESOLVED_HOLD then
            indicator:Hide()
            return false
        end
    end

    if indicator.texture then
        indicator.texture:SetAtlas(ATLAS_BY_STATUS[status])
    end
    indicator:Show()
    return true
end

-- =====================================
-- RESET (roster shift, frame recycling, zone change)
-- =====================================
function GS.Reset(indicator)
    if not indicator then return end
    indicator.tomoResolvedAt = nil
    indicator:Hide()
end

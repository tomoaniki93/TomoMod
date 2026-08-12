-- =====================================
-- PartyFrame/HoTs.lua — HoT tracking with class-colored indicators
-- [12.1] The aura rows here are drawn by the client's aura engine
-- (Shared/AuraContainer.lua); nothing in this file reads an aura.
-- Class-specific healer HoT databases
-- NO COMBAT_LOG_EVENT_UNFILTERED
-- =====================================

TomoMod_PartyHoTs = TomoMod_PartyHoTs or {}
local HoT = TomoMod_PartyHoTs

local pcall, ipairs = pcall, ipairs
local issecretvalue = issecretvalue

-- =====================================
-- SHARED SPELL DATA
-- The HoT database and class colours live in Interface/Shared/AuraData.lua so
-- party and raid can no longer drift apart. HoT.HEALER_HOTS is kept as an
-- alias for anything reading it from outside.
-- =====================================
local AD = TomoMod_AuraData

HoT.HEALER_HOTS      = AD and AD.HEALER_HOTS or {}
local SPELL_TO_CLASS = AD and AD.HOT_SPELL_TO_CLASS or {}
local CLASS_HOT_COLORS = AD and AD.CLASS_HOT_COLORS or {}

-- =====================================
-- UPDATE HOTS FOR A UNIT FRAME
-- =====================================
function HoT.UpdateUnit(f)
    if not f or not f.hotContainer then return end
    -- The setting is honoured at update time, not only at creation:
    -- ApplySettings re-applies visuals to existing frames rather than
    -- rebuilding them, so dropping this left the HoTs on screen after the
    -- option was turned off, until a reload.
    local db = TomoModDB and TomoModDB.partyFrames
    if not db or not db.showHoTs then f.hotContainer:Hide(); return end
    local unit = f.unit
    if not unit or not UnitExists(unit) then f.hotContainer:Hide(); return end
    f.hotContainer:Show()
    -- [12.1] The engine tracks the unit and narrows the group to the
    -- tracked HoT spell ids; there is nothing left to scan here.
    if f.hotContainer.engine then
        TomoMod_AuraContainer.SetUnit(f.hotContainer.engine, unit)
    end
end

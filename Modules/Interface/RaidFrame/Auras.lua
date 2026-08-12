-- =====================================
-- RaidFrame/Auras.lua — Debuff, HoT & Defensive tracking for Raid Frames
-- [12.1] The aura rows here are drawn by the client's aura engine
-- (Shared/AuraContainer.lua); nothing in this file reads an aura.
-- NO COMBAT_LOG_EVENT_UNFILTERED
-- =====================================

TomoMod_RaidAuras = TomoMod_RaidAuras or {}
local RA = TomoMod_RaidAuras

local pcall, ipairs = pcall, ipairs
local issecretvalue = issecretvalue

-- =====================================
-- SHARED SPELL DATA
-- The HoT database, class colours and debuff-type colours live in
-- Interface/Shared/AuraData.lua so party and raid can no longer drift apart.
-- RA.HEALER_HOTS is kept as an alias for anything reading it from outside.
-- =====================================
local AD = TomoMod_AuraData

RA.HEALER_HOTS       = AD and AD.HEALER_HOTS or {}
local SPELL_TO_CLASS = AD and AD.HOT_SPELL_TO_CLASS or {}
local CLASS_HOT_COLORS = AD and AD.CLASS_HOT_COLORS or {}

-- =====================================
-- UPDATE DEBUFFS FOR A UNIT FRAME
-- =====================================
function RA.UpdateDebuffs(f, db)
    if not f or not f.debuffContainer then return end
    db = db or (TomoModDB and TomoModDB.raidFrames)
    -- The setting still has to be honoured at update time, not only at
    -- creation. ApplySettings re-applies visuals to existing frames rather
    -- than rebuilding them, so without this, turning the option off left the
    -- debuffs on screen until a reload.
    if not db or not db.showDebuffs then f.debuffContainer:Hide(); return end
    local unit = f.unit
    if not unit or not UnitExists(unit) then f.debuffContainer:Hide(); return end
    f.debuffContainer:Show()
    -- [12.1] The engine tracks the unit and colours the border from the
    -- aura's own dispel type, which is what the scan used to read.
    if f.debuffContainer.engine then
        TomoMod_AuraContainer.SetUnit(f.debuffContainer.engine, unit)
    end
end

-- =====================================
-- UPDATE HOTS FOR A UNIT FRAME
-- =====================================
function RA.UpdateHoTs(f, db)
    if not f or not f.hotContainer then return end
    db = db or (TomoModDB and TomoModDB.raidFrames)
    if not db or not db.showHoTs then f.hotContainer:Hide(); return end
    local unit = f.unit
    if not unit or not UnitExists(unit) then f.hotContainer:Hide(); return end
    f.hotContainer:Show()
    -- [12.1] The spell list is now the group's candidate filter, applied by
    -- the engine: spellId is exactly what the client withholds.
    if f.hotContainer.engine then
        TomoMod_AuraContainer.SetUnit(f.hotContainer.engine, unit)
    end
end

-- =====================================
-- COMBINED UPDATE (called from Core on UNIT_AURA)
-- =====================================
function RA.UpdateUnit(f)
    -- Read once and hand it to both, which is what the db parameter is for.
    local db = TomoModDB and TomoModDB.raidFrames
    RA.UpdateDebuffs(f, db)
    RA.UpdateHoTs(f, db)
end

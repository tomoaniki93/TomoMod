-- =====================================
-- PartyFrame/HoTs.lua — HoT tracking with class-colored indicators
-- Scans via C_UnitAuras.GetAuraDataByIndex (taint-safe)
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

    local db = TomoModDB and TomoModDB.partyFrames
    if not db or not db.showHoTs then
        for _, icon in ipairs(f.hotContainer.icons) do icon:Hide() end
        return
    end

    local unit = f.unit
    if not unit or not UnitExists(unit) then
        for _, icon in ipairs(f.hotContainer.icons) do icon:Hide() end
        return
    end

    local maxHoTs = db.maxHoTs or 3
    local found = {}

    -- Scan buffs via C_UnitAuras
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local auraIndex = 1
        while auraIndex <= 40 and #found < maxHoTs do
            local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unit, auraIndex, "HELPFUL")
            if not ok or not auraData then break end

            local spellID = auraData.spellId
            if spellID and not issecretvalue(spellID) and SPELL_TO_CLASS[spellID] then
                local cls = SPELL_TO_CLASS[spellID]
                local entry = {
                    spellID  = spellID,
                    class    = cls,
                    icon     = auraData.icon,
                    duration = auraData.duration,
                    expTime  = auraData.expirationTime,
                }
                found[#found + 1] = entry
            end

            auraIndex = auraIndex + 1
        end
    end

    -- Update icons
    for i, icon in ipairs(f.hotContainer.icons) do
        local data = found[i]
        if data then
            if data.icon then
                icon.texture:SetTexture(data.icon)
            end
            -- Class-colored border
            local cc = CLASS_HOT_COLORS[data.class]
            if cc then
                icon.border:SetBackdropBorderColor(cc.r, cc.g, cc.b, 1)
            else
                icon.border:SetBackdropBorderColor(0, 0, 0, 1)
            end
            -- Duration text. duration / expirationTime can be secret values
            -- on group members in 12.x, so the arithmetic goes through the
            -- shared guard rather than being done inline.
            local remaining = AD and AD.RemainingTime(data.duration, data.expTime)
            if remaining then
                icon.duration:SetText(string.format("%.0f", remaining))
            else
                icon.duration:SetText("")
            end
            icon:Show()
        else
            icon:Hide()
        end
    end
end

-- =====================================
-- RaidFrame/Auras.lua — Debuff, HoT & Defensive tracking for Raid Frames
-- Scans via C_UnitAuras.GetAuraDataByIndex (taint-safe)
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
local DEBUFF_TYPE_COLORS = AD and AD.DEBUFF_TYPE_COLORS or {}

-- =====================================
-- UPDATE DEBUFFS FOR A UNIT FRAME
-- =====================================
function RA.UpdateDebuffs(f)
    if not f or not f.debuffContainer then return end

    local db = TomoModDB and TomoModDB.raidFrames
    if not db or not db.showDebuffs then
        for _, icon in ipairs(f.debuffContainer.icons) do icon:Hide() end
        return
    end

    local unit = f.unit
    if not unit or not UnitExists(unit) then
        for _, icon in ipairs(f.debuffContainer.icons) do icon:Hide() end
        return
    end

    local maxDebuffs = db.maxDebuffs or 3
    local found = {}

    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local auraIndex = 1
        while auraIndex <= 40 and #found < maxDebuffs do
            local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unit, auraIndex, "HARMFUL")
            if not ok or not auraData then break end

            local dispelType = auraData.dispelName
            if dispelType and not issecretvalue(dispelType) then
                found[#found + 1] = {
                    icon      = auraData.icon,
                    duration  = auraData.duration,
                    expTime   = auraData.expirationTime,
                    stacks    = auraData.applications,
                    type      = dispelType,
                }
            end

            auraIndex = auraIndex + 1
        end
    end

    for i, icon in ipairs(f.debuffContainer.icons) do
        local data = found[i]
        if data then
            if data.icon then
                icon.texture:SetTexture(data.icon)
            end
            -- Color border by debuff type
            local tc = DEBUFF_TYPE_COLORS[data.type]
            if tc then
                icon:SetBackdropBorderColor(tc.r, tc.g, tc.b, 1)
            else
                icon:SetBackdropBorderColor(0.8, 0, 0, 1)
            end
            -- Duration text
            -- duration / expirationTime can be secret values on group
            -- members in 12.x: the arithmetic goes through the shared guard.
            local remaining = AD and AD.RemainingTime(data.duration, data.expTime)
            if remaining then
                icon.duration:SetText(string.format("%.0f", remaining))
            else
                icon.duration:SetText("")
            end
            -- Stacks
            if data.stacks and data.stacks > 1 then
                icon.stacks:SetText(tostring(data.stacks))
            else
                icon.stacks:SetText("")
            end
            icon:Show()
        else
            icon:Hide()
        end
    end
end

-- =====================================
-- UPDATE HOTS FOR A UNIT FRAME
-- =====================================
function RA.UpdateHoTs(f)
    if not f or not f.hotContainer then return end

    local db = TomoModDB and TomoModDB.raidFrames
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

    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local auraIndex = 1
        while auraIndex <= 40 and #found < maxHoTs do
            local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unit, auraIndex, "HELPFUL")
            if not ok or not auraData then break end

            local spellID = auraData.spellId
            if spellID and not issecretvalue(spellID) and SPELL_TO_CLASS[spellID] then
                local cls = SPELL_TO_CLASS[spellID]
                found[#found + 1] = {
                    spellID  = spellID,
                    class    = cls,
                    icon     = auraData.icon,
                    duration = auraData.duration,
                    expTime  = auraData.expirationTime,
                }
            end

            auraIndex = auraIndex + 1
        end
    end

    for i, icon in ipairs(f.hotContainer.icons) do
        local data = found[i]
        if data then
            if data.icon then
                icon.texture:SetTexture(data.icon)
            end
            local cc = CLASS_HOT_COLORS[data.class]
            if cc then
                icon:SetBackdropBorderColor(cc.r, cc.g, cc.b, 1)
            else
                icon:SetBackdropBorderColor(0, 0, 0, 1)
            end
            -- duration / expirationTime can be secret values on group
            -- members in 12.x: the arithmetic goes through the shared guard.
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

-- =====================================
-- COMBINED UPDATE (called from Core on UNIT_AURA)
-- =====================================
function RA.UpdateUnit(f)
    RA.UpdateDebuffs(f)
    RA.UpdateHoTs(f)
end

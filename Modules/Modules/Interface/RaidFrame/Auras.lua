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
-- HEALER HOT SPELL DATABASE (shared with PartyFrame HoTs)
-- =====================================
RA.HEALER_HOTS = {
    PRIEST = {
        [139]    = true,  -- Renew
        [17]     = true,  -- Power Word: Shield
        [194384] = true,  -- Atonement
        [41635]  = true,  -- Prayer of Mending
        [77489]  = true,  -- Echo of Light
    },
    DRUID = {
        [774]    = true,  -- Rejuvenation
        [8936]   = true,  -- Regrowth (HoT)
        [33763]  = true,  -- Lifebloom
        [48438]  = true,  -- Wild Growth
        [102342] = true,  -- Ironbark
        [155777] = true,  -- Germination
        [207386] = true,  -- Spring Blossoms
        [200389] = true,  -- Cultivation
        [391891] = true,  -- Adaptive Swarm
    },
    PALADIN = {
        [53563]  = true,  -- Beacon of Light
        [156910] = true,  -- Beacon of Faith
        [223306] = true,  -- Bestow Faith
        [287280] = true,  -- Glimmer of Light
    },
    SHAMAN = {
        [61295]  = true,  -- Riptide
        [382024] = true,  -- Earthliving Weapon
    },
    MONK = {
        [119611] = true,  -- Renewing Mist
        [116849] = true,  -- Life Cocoon
        [124682] = true,  -- Enveloping Mist
        [191840] = true,  -- Essence Font
    },
    EVOKER = {
        [355941] = true,  -- Dream Breath
        [366155] = true,  -- Reversion
        [376788] = true,  -- Echo
        [378001] = true,  -- Dream Breath (HoT)
    },
}

-- =====================================
-- CLASS COLORS (for HoT border)
-- =====================================
local CLASS_HOT_COLORS = {
    PRIEST  = { r = 1.00, g = 1.00, b = 1.00 },
    DRUID   = { r = 1.00, g = 0.49, b = 0.04 },
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    SHAMAN  = { r = 0.00, g = 0.44, b = 0.87 },
    MONK    = { r = 0.00, g = 1.00, b = 0.60 },
    EVOKER  = { r = 0.20, g = 0.58, b = 0.50 },
}

-- Build reverse lookup: spellID -> class
local SPELL_TO_CLASS = {}
for cls, spells in pairs(RA.HEALER_HOTS) do
    for spellID in pairs(spells) do
        SPELL_TO_CLASS[spellID] = cls
    end
end

-- =====================================
-- DEBUFF TYPE COLORS
-- =====================================
local DEBUFF_TYPE_COLORS = {
    Magic   = { r = 0.20, g = 0.60, b = 1.00 },
    Curse   = { r = 0.60, g = 0.00, b = 1.00 },
    Disease = { r = 0.60, g = 0.40, b = 0.00 },
    Poison  = { r = 0.00, g = 0.60, b = 0.00 },
}

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
            if data.expTime and data.duration and data.duration > 0 then
                local remaining = data.expTime - GetTime()
                if remaining > 0 then
                    icon.duration:SetText(string.format("%.0f", remaining))
                else
                    icon.duration:SetText("")
                end
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
            if data.expTime and data.duration and data.duration > 0 then
                local remaining = data.expTime - GetTime()
                if remaining > 0 then
                    icon.duration:SetText(string.format("%.0f", remaining))
                else
                    icon.duration:SetText("")
                end
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

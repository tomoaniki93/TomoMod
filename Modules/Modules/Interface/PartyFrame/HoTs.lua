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
-- HEALER HOT SPELL DATABASE (by class)
-- =====================================
HoT.HEALER_HOTS = {
    -- PRIEST
    PRIEST = {
        [139]    = true,  -- Renew
        [17]     = true,  -- Power Word: Shield
        [194384] = true,  -- Atonement
        [41635]  = true,  -- Prayer of Mending
        [77489]  = true,  -- Echo of Light
        [214206] = true,  -- Atonement (PvP)
    },
    -- DRUID
    DRUID = {
        [774]    = true,  -- Rejuvenation
        [8936]   = true,  -- Regrowth (HoT component)
        [33763]  = true,  -- Lifebloom
        [48438]  = true,  -- Wild Growth
        [102342] = true,  -- Ironbark
        [155777] = true,  -- Germination (Rejuv 2)
        [207386] = true,  -- Spring Blossoms
        [200389] = true,  -- Cultivation
        [391891] = true,  -- Adaptive Swarm
    },
    -- PALADIN
    PALADIN = {
        [53563]  = true,  -- Beacon of Light
        [156910] = true,  -- Beacon of Faith
        [223306] = true,  -- Bestow Faith
        [287280] = true,  -- Glimmer of Light
        [388013] = true,  -- Blessing of Summer
    },
    -- SHAMAN
    SHAMAN = {
        [61295]  = true,  -- Riptide
        [382024] = true,  -- Earthliving Weapon
        [383009] = true,  -- Healing Tide (buff)
        [157153] = true,  -- Cloudburst
    },
    -- MONK
    MONK = {
        [119611] = true,  -- Renewing Mist
        [116849] = true,  -- Life Cocoon
        [124682] = true,  -- Enveloping Mist
        [191840] = true,  -- Essence Font
        [325209] = true,  -- Enveloping Breath
    },
    -- EVOKER
    EVOKER = {
        [355941] = true,  -- Dream Breath
        [363502] = true,  -- Dream Flight
        [366155] = true,  -- Reversion
        [373267] = true,  -- Lifebind
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
for cls, spells in pairs(HoT.HEALER_HOTS) do
    for spellID in pairs(spells) do
        SPELL_TO_CLASS[spellID] = cls
    end
end

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
            icon:Show()
        else
            icon:Hide()
        end
    end
end

-- =====================================
-- PartyFrame/CooldownTrackers.lua — Interrupt & Battle Rez CD tracking
-- UNIT_SPELLCAST_SUCCEEDED only (no CLEU — causes taint)
-- All spellID checks wrapped in pcall/issecretvalue
-- =====================================

TomoMod_PartyCooldowns = TomoMod_PartyCooldowns or {}
local CD = TomoMod_PartyCooldowns

local pcall, pairs, ipairs = pcall, pairs, ipairs
local issecretvalue = issecretvalue
local GetTime = GetTime

-- =====================================
-- INTERRUPT SPELL DATABASE
-- { spellID = { cd = seconds, icon = texturePath } }
-- =====================================
CD.INTERRUPT_SPELLS = {
    -- Death Knight
    [47528]  = { cd = 15, icon = "Interface\\Icons\\Spell_DeathKnight_MindFreeze" },
    -- Demon Hunter
    [183752] = { cd = 15, icon = "Interface\\Icons\\Ability_DemonHunter_Consume" },
    -- Druid
    [106839] = { cd = 15, icon = "Interface\\Icons\\Ability_Druid_SkullBash" },
    [78675]  = { cd = 60, icon = "Interface\\Icons\\Ability_Druid_SolarBeam" },
    -- Evoker
    [351338] = { cd = 40, icon = "Interface\\Icons\\Ability_Evoker_Quell" },
    -- Hunter
    [147362] = { cd = 24, icon = "Interface\\Icons\\Ability_Hunter_SteadyShot" },
    -- Mage
    [2139]   = { cd = 24, icon = "Interface\\Icons\\Spell_Frost_IceShock" },
    -- Monk
    [116705] = { cd = 15, icon = "Interface\\Icons\\Ability_Monk_SpearHandStrike" },
    -- Paladin
    [96231]  = { cd = 15, icon = "Interface\\Icons\\Spell_Holy_Rebuke" },
    -- Priest
    [15487]  = { cd = 45, icon = "Interface\\Icons\\Spell_Shadow_Silence" },
    -- Rogue
    [1766]   = { cd = 15, icon = "Interface\\Icons\\Ability_Kick" },
    -- Shaman
    [57994]  = { cd = 12, icon = "Interface\\Icons\\Spell_Nature_EarthShock" },
    -- Warlock
    [119910] = { cd = 24, icon = "Interface\\Icons\\Spell_Shadow_MindRot" },
    [19647]  = { cd = 24, icon = "Interface\\Icons\\Spell_Nature_Purge" },
    -- Warrior
    [6552]   = { cd = 15, icon = "Interface\\Icons\\Ability_Warrior_Pummel" },
}

-- =====================================
-- BATTLE REZ SPELL DATABASE
-- { spellID = { cd = seconds, icon = texturePath } }
-- =====================================
CD.BREZ_SPELLS = {
    -- Death Knight
    [61999]  = { cd = 600, icon = "Interface\\Icons\\Spell_DeathKnight_Raise_Dead" },
    -- Druid
    [20484]  = { cd = 600, icon = "Interface\\Icons\\Spell_Nature_Rebirth" },
    -- Paladin
    [391054] = { cd = 600, icon = "Interface\\Icons\\Spell_Holy_Intercession" },
    -- Warlock
    [20707]  = { cd = 600, icon = "Interface\\Icons\\Spell_Shadow_Soulstone" },
    -- Evoker (placeholder if added)
}

-- Build reverse spell lookups
local SPELL_IS_KICK = {}
for spellID in pairs(CD.INTERRUPT_SPELLS) do
    SPELL_IS_KICK[spellID] = true
end

local SPELL_IS_BREZ = {}
for spellID in pairs(CD.BREZ_SPELLS) do
    SPELL_IS_BREZ[spellID] = true
end

-- =====================================
-- CLASS → DEFAULT SPELL LOOKUPS
-- Returns the default interrupt/brez icon for a given class
-- =====================================
local CLASS_INTERRUPT = {
    DEATHKNIGHT  = { spellID = 47528,  cd = 15 },
    DEMONHUNTER  = { spellID = 183752, cd = 15 },
    DRUID        = { spellID = 106839, cd = 15 },
    EVOKER       = { spellID = 351338, cd = 40 },
    HUNTER       = { spellID = 147362, cd = 24 },
    MAGE         = { spellID = 2139,   cd = 24 },
    MONK         = { spellID = 116705, cd = 15 },
    PALADIN      = { spellID = 96231,  cd = 15 },
    PRIEST       = { spellID = 15487,  cd = 45 },
    ROGUE        = { spellID = 1766,   cd = 15 },
    SHAMAN       = { spellID = 57994,  cd = 12 },
    WARLOCK      = { spellID = 119910, cd = 24 },
    WARRIOR      = { spellID = 6552,   cd = 15 },
}

local CLASS_BREZ = {
    DEATHKNIGHT = { spellID = 61999,  cd = 600 },
    DRUID       = { spellID = 20484,  cd = 600 },
    PALADIN     = { spellID = 391054, cd = 600 },
    WARLOCK     = { spellID = 20707,  cd = 600 },
}

-- Resolve spell icon texture from spellID (cached)
local iconCache = {}
local function GetSpellIcon(spellID)
    if iconCache[spellID] then return iconCache[spellID] end
    local tex = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)
    if not tex then
        local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
        tex = info and info.iconID
    end
    if tex then iconCache[spellID] = tex end
    return tex
end

-- =====================================
-- ACTIVE COOLDOWNS STATE
-- { unit = { kick = { spellID, startTime, duration, icon }, brez = { ... } } }
-- =====================================
CD.active = {}

-- =====================================
-- EVENT: UNIT_SPELLCAST_SUCCEEDED
-- =====================================
local eventFrame = CreateFrame("Frame")
local cdTrackingEnabled = false

local function OnSpellCastSucceeded(self, event, unit, _, spellID)
    if not unit or not spellID then return end

    -- Only track party/player units
    local validUnit = (unit == "player")
    if not validUnit then
        for i = 1, 4 do
            if unit == "party" .. i then validUnit = true; break end
        end
    end
    if not validUnit then return end

    -- Taint-safe spellID check
    if issecretvalue and issecretvalue(spellID) then
        -- Secret spellID: can't use as table index, try pcall lookup
        for knownID, data in pairs(CD.INTERRUPT_SPELLS) do
            local ok, match = pcall(function() return spellID == knownID end)
            if ok and match then
                if not CD.active[unit] then CD.active[unit] = {} end
                CD.active[unit].kick = {
                    spellID   = knownID,
                    startTime = GetTime(),
                    duration  = data.cd,
                    icon      = data.icon,
                }
                CD.UpdateAllFrames()
                return
            end
        end
        for knownID, data in pairs(CD.BREZ_SPELLS) do
            local ok, match = pcall(function() return spellID == knownID end)
            if ok and match then
                if not CD.active[unit] then CD.active[unit] = {} end
                CD.active[unit].brez = {
                    spellID   = knownID,
                    startTime = GetTime(),
                    duration  = data.cd,
                    icon      = data.icon,
                }
                CD.UpdateAllFrames()
                return
            end
        end
        return
    end

    local safeID = spellID

    -- Check interrupt
    local kickData = CD.INTERRUPT_SPELLS[safeID]
    if kickData then
        if not CD.active[unit] then CD.active[unit] = {} end
        CD.active[unit].kick = {
            spellID   = safeID,
            startTime = GetTime(),
            duration  = kickData.cd,
            icon      = kickData.icon,
        }
        CD.UpdateAllFrames()
        return
    end

    -- Check brez
    local brezData = CD.BREZ_SPELLS[safeID]
    if brezData then
        if not CD.active[unit] then CD.active[unit] = {} end
        CD.active[unit].brez = {
            spellID   = safeID,
            startTime = GetTime(),
            duration  = brezData.cd,
            icon      = brezData.icon,
        }
        CD.UpdateAllFrames()
        return
    end
end

-- =====================================
-- UPDATE FRAME CD ICONS
-- Always visible when unit's class has the ability
-- Ready = teal border, full alpha | On CD = desaturated + swipe
-- =====================================
local TEAL = { 0.047, 0.824, 0.624 }
local RED  = { 0.8, 0.2, 0.2 }
local IDLE = { 0.20, 0.20, 0.20 }

local function SetIconReady(icon, data)
    local tex = GetSpellIcon(data.spellID)
    if tex then icon.texture:SetTexture(tex) end
    icon.texture:SetDesaturated(false)
    icon:SetBackdropBorderColor(TEAL[1], TEAL[2], TEAL[3], 1)
    icon.cooldown:Clear()
    icon.durationText:SetText("")
    icon:Show()
end

local function SetIconOnCD(icon, cdData, classData, remaining, startTime, duration)
    local tex = GetSpellIcon(classData.spellID) or cdData.icon
    if tex then icon.texture:SetTexture(tex) end
    icon.texture:SetDesaturated(true)
    icon:SetBackdropBorderColor(RED[1], RED[2], RED[3], 1)
    icon.cooldown:SetCooldown(startTime, duration)
    icon.durationText:SetText(string.format("%.0f", remaining))
    icon:Show()
end

function CD.UpdateFrame(f)
    if not f or not f.cdContainer then return end
    if not f.unit or not UnitExists(f.unit) then
        if f.cdContainer.kickIcon then f.cdContainer.kickIcon:Hide() end
        if f.cdContainer.brezIcon then f.cdContainer.brezIcon:Hide() end
        return
    end

    local db = TomoModDB and TomoModDB.partyFrames
    if not db then return end

    local _, classFile = UnitClass(f.unit)
    local unitCDs = CD.active[f.unit]
    local now = GetTime()

    -- Kick icon
    if f.cdContainer.kickIcon and db.showInterruptCD then
        local classKick = classFile and CLASS_INTERRUPT[classFile]
        if classKick then
            local kickData = unitCDs and unitCDs.kick
            if kickData and (kickData.startTime + kickData.duration) > now then
                local remaining = (kickData.startTime + kickData.duration) - now
                SetIconOnCD(f.cdContainer.kickIcon, kickData, classKick, remaining, kickData.startTime, kickData.duration)
            else
                -- Ready or no CD tracked yet — show placeholder
                if unitCDs and unitCDs.kick then unitCDs.kick = nil end
                SetIconReady(f.cdContainer.kickIcon, classKick)
            end
        else
            f.cdContainer.kickIcon:Hide()
        end
    end

    -- Brez icon
    if f.cdContainer.brezIcon and db.showBrezCD then
        local classBrez = classFile and CLASS_BREZ[classFile]
        if classBrez then
            local brezData = unitCDs and unitCDs.brez
            if brezData and (brezData.startTime + brezData.duration) > now then
                local remaining = (brezData.startTime + brezData.duration) - now
                SetIconOnCD(f.cdContainer.brezIcon, brezData, classBrez, remaining, brezData.startTime, brezData.duration)
            else
                if unitCDs and unitCDs.brez then unitCDs.brez = nil end
                SetIconReady(f.cdContainer.brezIcon, classBrez)
            end
        else
            f.cdContainer.brezIcon:Hide()
        end
    end
end

-- =====================================
-- UPDATE ALL FRAMES
-- =====================================
function CD.UpdateAllFrames()
    if not TomoMod_PartyFrames then return end
    for _, f in pairs(TomoMod_PartyFrames.frames) do
        if f and f:IsShown() then
            CD.UpdateFrame(f)
        end
    end
end

-- =====================================
-- TICKER: update CD text (every 0.5s)
-- =====================================
local cdTicker = nil

function CD.StartTicker()
    if cdTicker then return end
    cdTicker = C_Timer.NewTicker(0.5, function()
        CD.UpdateAllFrames()
    end)
end

function CD.StopTicker()
    if cdTicker then cdTicker:Cancel(); cdTicker = nil end
end

-- =====================================
-- INITIALIZE
-- =====================================
function CD.Initialize()
    local db = TomoModDB and TomoModDB.partyFrames
    if not db then return end
    if not db.showInterruptCD and not db.showBrezCD then return end

    cdTrackingEnabled = true
    CD.StartTicker()
end

-- =====================================
-- RESET (on group disband)
-- =====================================
function CD.Reset()
    wipe(CD.active)
    CD.UpdateAllFrames()
end

-- =====================================
-- EVENT REGISTRATION (file scope — taint-safe)
-- Only UNIT_SPELLCAST_SUCCEEDED: no COMBAT_LOG_EVENT_UNFILTERED (causes taint).
-- Mirrors BliZzi_Interrupts pattern: register at load time,
-- gate processing behind a runtime flag set by Initialize().
-- =====================================
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if not cdTrackingEnabled then return end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        OnSpellCastSucceeded(self, event, ...)
    end
end)

-- =====================================
-- PartyFrame/CooldownTrackers.lua — Interrupt & Battle Rez CD tracking
-- Interrupts: UNIT_SPELLCAST_SUCCEEDED (no CLEU — causes taint in WoW 12.x).
--   Party spellIDs are secret values in 12.x; resolved via ResolveSpellID with
--   a class-default fallback when a cast cannot be attributed to a known spell.
-- Battle rez: POOL-DRIVEN via C_Spell.GetSpellCharges(20484). In instanced
--   content every brez spell shares ONE charge pool, readable from any class,
--   so per-cast detection (impossible for party members) is not needed.
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

-- =====================================
-- BATTLE-REZ CHARGE POOL READER
-- C_Spell.GetSpellCharges(20484) returns the SHARED combat-resurrection pool
-- and is readable from any class while inside instanced content (nil elsewhere).
-- Prefers the central TomoMod_ResurrectTracker reader when present, so the
-- party frames and the standalone counter HUD agree on a single source.
-- Secret-value guarded: if any field is secret we report "no pool" rather than
-- performing arithmetic on a secret value (12.x taint rule).
-- =====================================
local REBIRTH_SPELLID = 20484
local function GetBrezCharges()
    local RT = TomoMod_ResurrectTracker
    if RT and RT.GetBrezCharges then
        local ok, cur, maxC, start, dur = pcall(RT.GetBrezCharges)
        if ok then return cur, maxC, start, dur end
    end
    if not (C_Spell and C_Spell.GetSpellCharges) then return nil end
    local info = C_Spell.GetSpellCharges(REBIRTH_SPELLID)
    if type(info) ~= "table" then return nil end
    local cur, maxC  = info.currentCharges, info.maxCharges
    local start, dur = info.cooldownStartTime, info.cooldownDuration
    if issecretvalue and (issecretvalue(cur) or issecretvalue(maxC)
        or issecretvalue(start) or issecretvalue(dur)) then
        return nil
    end
    return cur, maxC, start, dur
end

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
-- TAINT-SAFE SPELLID RESOLVER
-- In WoW 12.x, spellIDs from party UNIT_SPELLCAST_SUCCEEDED are tainted and
-- cannot be used as table indices directly.
-- Resolution order (mirrors BliZzi_Interrupts BIT.Taint:ResolveNumber):
--   1. Direct pcall table access — fast path for clean IDs (player is never tainted)
--   2. string.format("%.0f", raw) → tonumber — strips taint on numeric primitives
--      in most 12.x builds; the resulting tainted string converts to a clean integer
--      via tonumber, which CAN be used as a table key safely.
-- COMBAT_LOG_EVENT_UNFILTERED is intentionally NOT registered: doing so from
-- addon code causes taint in 12.x, blocking protected-frame API calls.
-- =====================================
local function ResolveSpellID(rawID)
    if rawID == nil then return nil end
    -- Fast path: attempt to use rawID as a table key via pcall (errors if tainted)
    local ok = pcall(function()
        local _ = CD.INTERRUPT_SPELLS[rawID]
        local __ = CD.BREZ_SPELLS[rawID]
    end)
    if ok then return rawID end  -- clean integer, safe to use directly
    -- Strip taint: string.format works on tainted numeric primitives in 12.x
    local okF, s = pcall(string.format, "%.0f", rawID)
    if okF and s then
        local okN, num = pcall(tonumber, s)
        if okN and num then return num end
    end
    return nil
end

-- =====================================
-- EVENT: UNIT_SPELLCAST_SUCCEEDED
-- Tracks interrupt and battle-rez casts for player + party members.
-- spellID may be tainted for party units in 12.x — resolved via ResolveSpellID.
-- Fallback: when spellID is fully unresolvable, attribute to the class-default
-- interrupt if that slot is not currently on cooldown (BliZzi "WilduTools" approach:
-- trust the known spell rather than requiring a readable runtime ID).
-- =====================================
local eventFrame = CreateFrame("Frame")
local cdTrackingEnabled = false

local function OnSpellCastSucceeded(unit, spellID)
    if not unit or not spellID then return end

    local safeID = ResolveSpellID(spellID)

    if safeID then
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

    else
        -- spellID unresolvable (secret value AND string.format strip failed).
        -- Fall back to the class-known interrupt if not already on cooldown.
        -- Brez needs no fallback here: it is pool-driven in CD.UpdateFrame.
        -- [12.1] nil when unreadable; the caller already skips a nil class.
        local classFile = TomoMod_Utils and TomoMod_Utils.UnitClassToken(unit)
        if classFile then
            local classKick = CLASS_INTERRUPT[classFile]
            if classKick then
                local now     = GetTime()
                local unitCDs = CD.active[unit]
                local kickOnCD = unitCDs and unitCDs.kick
                    and (unitCDs.kick.startTime + unitCDs.kick.duration) > now
                if not kickOnCD then
                    if not CD.active[unit] then CD.active[unit] = {} end
                    CD.active[unit].kick = {
                        spellID   = classKick.spellID,
                        startTime = now,
                        duration  = classKick.cd,
                        icon      = nil,
                    }
                    CD.UpdateAllFrames()
                end
            end
        end
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

    -- [12.1] nil when unreadable; the caller already skips a nil class.
    local classFile = TomoMod_Utils and TomoMod_Utils.UnitClassToken(f.unit)
    local unitCDs = CD.active[f.unit]
    local now = GetTime()

    -- Kick icon (hidden for healers — since 12.x healers have no interrupt)
    if f.cdContainer.kickIcon and db.showInterruptCD then
        local role = UnitGroupRolesAssigned(f.unit)
        local classKick = classFile and CLASS_INTERRUPT[classFile]
        if classKick and role ~= "HEALER" then
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

    -- Brez icon — POOL-DRIVEN (shared combat-resurrection pool).
    -- Every brez-capable member reflects the same shared pool: greyed + swiping
    -- while no charge is available, ready otherwise. This is why the party brez
    -- icon now correctly enters cooldown when ANY brez is used in the instance.
    if f.cdContainer.brezIcon and db.showBrezCD then
        local classBrez = classFile and CLASS_BREZ[classFile]
        if classBrez then
            local cur, _maxC, start, dur = GetBrezCharges()
            if cur ~= nil and cur <= 0 and start and dur and start > 0 and dur > 0 then
                local remaining = (start + dur) - now
                if remaining < 0 then remaining = 0 end
                SetIconOnCD(f.cdContainer.brezIcon, classBrez, classBrez, remaining, start, dur)
            else
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
-- UNIT_SPELLCAST_SUCCEEDED: fires for player + party units.
--   For the player it is fully reliable; for party members in 12.x the
--   spellID argument is tainted but ResolveSpellID() handles that.
-- No COMBAT_LOG_EVENT_UNFILTERED: registering it from addon code causes
-- taint in WoW 12.x, blocking protected frame / API calls.
-- =====================================
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:SetScript("OnEvent", function(self, event, unit, _, spellID)
    if not cdTrackingEnabled then return end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if not unit then return end
        if unit ~= "player" then
            local valid = false
            for i = 1, 4 do
                if unit == "party" .. i then valid = true; break end
            end
            if not valid then return end
        end
        OnSpellCastSucceeded(unit, spellID)
    end
end)

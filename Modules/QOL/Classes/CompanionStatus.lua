-- CompanionStatus (Retail final)
local ADDON_NAME = ...

--------------------------------------------------
-- Frame
--------------------------------------------------
local CompanionStatus = CreateFrame("Frame", "CompanionStatusFrame", UIParent, "BackdropTemplate")
CompanionStatus:Hide()

--------------------------------------------------
-- SavedVariables
--------------------------------------------------
CompanionStatusDB = CompanionStatusDB or {}

local DEFAULTS = {
    enabled = true,
    debug = false,
    scale = 4.0,
    size = 36,
    point = { "CENTER", "CENTER", 0, 0 },
    displayMode = "both", -- icon | text | both
    hideWhileMounted = true,
}

local DB
local L

local function ApplyDefaults(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = type(v) == "table" and { unpack(v) } or v
        end
    end
end

--------------------------------------------------
-- Utils
--------------------------------------------------
local function Debug(msg)
    if DB and DB.debug then
        print("|cff00ffff[CompanionStatus]|r", msg)
    end
end

-- L is captured at ADDON_LOADED, not at file scope: the locale tables are
-- registered earlier in the TOC, but the fallback keeps a missing L from
-- turning the reminder into a blank frame.
local function T(key, fallback)
    if L then return L[key] end
    return fallback
end

local function PlayerClass()
    local _, class = UnitClass("player")
    return class
end

local function SpellIcon(spellID)
    return C_Spell.GetSpellTexture(spellID) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

--------------------------------------------------
-- Talent checks (no-pet builds)
--------------------------------------------------
local function HunterHasLoneWolf()
    return IsSpellKnown(155228)
end

local function WarlockHasSacrifice()
    return IsSpellKnown(108503)
end

--------------------------------------------------
-- HARD FILTER: does this spec EVER use a companion?
--------------------------------------------------
local function PlayerUsesCompanion()
    local _, class = UnitClass("player")
    local spec = GetSpecialization()
    if not spec then return false end
    local specID = GetSpecializationInfo(spec)

    if class == "HUNTER" then
        return specID == 253 or specID == 255
    end

    if class == "WARLOCK" then
        return true
    end

    if class == "DEATHKNIGHT" then
        return specID == 252
    end

    return false
end

--------------------------------------------------
-- Icons (Blizzard native, SAFE)
--------------------------------------------------
local function GetHunterPetIcon()
    if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then
        return SpellIcon(136) -- Mend Pet
    end

    local guid = UnitGUID("pet")
    if not guid then
        return SpellIcon(136)
    end

    local speciesID = C_PetJournal.GetPetSpeciesIDByGUID(guid)
    if speciesID then
        local _, _, _, icon = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
        if icon then
            return icon
        end
    end

    return SpellIcon(136)
end

local WARLOCK_DEMON_SPELLS = {
    ["Imp"]        = 688,
    ["Voidwalker"] = 697,
    ["Succubus"]   = 712,
    ["Felhunter"]  = 691,
    ["Felguard"]   = 30146,
}

local function GetWarlockPetIcon()
    local family = UnitCreatureFamily("pet")
    if family and WARLOCK_DEMON_SPELLS[family] then
        return SpellIcon(WARLOCK_DEMON_SPELLS[family])
    end
    return SpellIcon(688)
end

local function GetDKGhoulIcon()
    return SpellIcon(46584) -- Raise Dead
end

local function GetPetIcon()
    local class = PlayerClass()
    if class == "HUNTER" then
        return GetHunterPetIcon()
    elseif class == "WARLOCK" then
        return GetWarlockPetIcon()
    elseif class == "DEATHKNIGHT" then
        return GetDKGhoulIcon()
    end
end

--------------------------------------------------
-- Travel states
--------------------------------------------------
-- IsFlying() is polled state: the client announces nothing when you leave the
-- ground. Evaluating it only from pet and talent events meant the reminder was
-- decided while still standing on the mount -- so it showed -- and then stayed
-- on screen for the whole flight, at scale 4.0, with no event left to hide it.
--
-- Suppressing on IsMounted() as well is what makes this event-driven again:
-- every entry into and exit from a travel state passes through
-- PLAYER_MOUNT_DISPLAY_CHANGED, PLAYER_CONTROL_LOST/GAINED (taxi) or
-- UNIT_ENTERED/EXITED_VEHICLE. Nothing needs to be polled. It is also the
-- honest behaviour: mounted, you cannot summon a companion anyway, so the
-- reminder has nothing to remind you of.
local function IsTravelling()
    if IsFlying() then return true end
    if UnitOnTaxi("player") then return true end
    if UnitInVehicle("player") then return true end
    if DB and DB.hideWhileMounted and IsMounted() then return true end
    return false
end

--------------------------------------------------
-- Frame UI
--------------------------------------------------
CompanionStatus:SetSize(DEFAULTS.size, DEFAULTS.size)

local icon = CompanionStatus:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints()

local text = CompanionStatus:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
text:SetPoint("TOP", CompanionStatus, "BOTTOM", 0, -2)

--------------------------------------------------
-- Layout
--------------------------------------------------
local function ApplyDisplay()
    if DB.displayMode == "icon" then
        icon:Show()
        text:Hide()
    elseif DB.displayMode == "text" then
        icon:Hide()
        text:Show()
        text:SetPoint("CENTER", CompanionStatus, "CENTER", 0, 0)
    else
        icon:Show()
        text:Show()
        text:SetPoint("TOP", CompanionStatus, "BOTTOM", 0, -2)
    end
end

local function ApplyPosition()
    CompanionStatus:ClearAllPoints()
    if not DB.point or #DB.point == 0 then
        DB.point = { unpack(DEFAULTS.point) }
    end
    -- point stores { anchorPoint, relativePoint, offsetX, offsetY } without frame refs (can't serialize)
    if #DB.point == 5 then
        -- migrate old format that included a frame reference
        DB.point = { DB.point[1], DB.point[3], DB.point[4], DB.point[5] }
    end
    CompanionStatus:SetPoint(DB.point[1], UIParent, DB.point[2], DB.point[3], DB.point[4])
end

--------------------------------------------------
-- Core logic (SAFE)
--------------------------------------------------
local function UpdateState()
    if not DB.enabled then
        CompanionStatus:Hide()
        return
    end

    -- Hide while flying, mounted, on a taxi or in a vehicle
    if IsTravelling() then
        CompanionStatus:Hide()
        return
    end

    -- 🚨 ABSOLUTE GUARD (fixes monk issue)
    if not PlayerUsesCompanion() then
        CompanionStatus:Hide()
        return
    end

    local class = PlayerClass()

    if class == "HUNTER" and HunterHasLoneWolf() then
        Debug("Hunter Lone Wolf active")
        CompanionStatus:Hide()
        return
    end

    if class == "WARLOCK" and WarlockHasSacrifice() then
        Debug("Warlock Grimoire of Sacrifice active")
        CompanionStatus:Hide()
        return
    end

    if not UnitExists("pet") then
        icon:SetTexture(GetPetIcon())
        text:SetText(T("companion_pet_missing", "Pet missing"))
        ApplyDisplay()
        CompanionStatus:Show()
        Debug("Pet missing")
        return
    end

    if UnitIsDeadOrGhost("pet") then
        icon:SetTexture(GetPetIcon())
        text:SetText(T("companion_pet_dead", "Pet dead"))
        ApplyDisplay()
        CompanionStatus:Show()
        Debug("Pet dead")
        return
    end

    CompanionStatus:Hide()
end

--------------------------------------------------
-- Events (OPTIMIZED)
--------------------------------------------------
CompanionStatus:RegisterEvent("ADDON_LOADED")
CompanionStatus:RegisterEvent("PLAYER_ENTERING_WORLD")
CompanionStatus:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
CompanionStatus:RegisterEvent("PLAYER_TALENT_UPDATE")
CompanionStatus:RegisterUnitEvent("UNIT_PET", "player")
CompanionStatus:RegisterUnitEvent("UNIT_HEALTH", "pet")
CompanionStatus:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
CompanionStatus:RegisterUnitEvent("UNIT_FLAGS", "pet")
-- Taxi flights take control away rather than firing a mount event, and
-- vehicles do neither.
CompanionStatus:RegisterEvent("PLAYER_CONTROL_LOST")
CompanionStatus:RegisterEvent("PLAYER_CONTROL_GAINED")
CompanionStatus:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
CompanionStatus:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")

-- Mount, taxi and vehicle state is not always settled on the frame its own
-- event fires, so these get a second look on the next one.
local DEFERRED_RECHECK = {
    PLAYER_MOUNT_DISPLAY_CHANGED = true,
    PLAYER_CONTROL_LOST          = true,
    PLAYER_CONTROL_GAINED        = true,
    UNIT_ENTERED_VEHICLE         = true,
    UNIT_EXITED_VEHICLE          = true,
}

CompanionStatus:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        ApplyDefaults(CompanionStatusDB, DEFAULTS)
        DB = CompanionStatusDB
        L = TomoMod_L

        self:SetScale(DB.scale)
        self:SetSize(DB.size, DB.size)

        ApplyPosition()
        ApplyDisplay()
        UpdateState()
        return
    end

    if event == "UNIT_HEALTH" and arg1 ~= "pet" then return end
    if event == "UNIT_PET" and arg1 ~= "player" then return end

    UpdateState()

    if DEFERRED_RECHECK[event] then
        C_Timer.After(0, UpdateState)
    end
end)

--------------------------------------------------
-- Public API (consumed by Config/Panels/QOL.lua)
--------------------------------------------------
-- Settings still live in their own CompanionStatusDB SavedVariable rather
-- than in TomoModDB. Folding them in would be tidier but would have to
-- migrate every existing profile for a five-option module, so the panel
-- reaches in through here instead.
TomoMod_CompanionStatus = TomoMod_CompanionStatus or {}
local API = TomoMod_CompanionStatus

function API.GetSettings()
    if not DB then
        CompanionStatusDB = CompanionStatusDB or {}
        ApplyDefaults(CompanionStatusDB, DEFAULTS)
        DB = CompanionStatusDB
    end
    return DB
end

function API.SetEnabled(v)
    API.GetSettings().enabled = v and true or false
    UpdateState()
end

function API.ApplySettings()
    local db = API.GetSettings()
    CompanionStatus:SetScale(db.scale)
    CompanionStatus:SetSize(db.size, db.size)
    ApplyPosition()
    ApplyDisplay()
    UpdateState()
end

function API.ResetPosition()
    API.GetSettings().point = { unpack(DEFAULTS.point) }
    ApplyPosition()
end

--------------------------------------------------
-- Slash commands
--------------------------------------------------
SLASH_COMPANIONSTATUS1 = "/cs"
SlashCmdList.COMPANIONSTATUS = function(msg)
    msg = (msg or ""):lower()

    if msg == "debug" then
        DB.debug = not DB.debug
        print("CompanionStatus debug:", DB.debug and "ON" or "OFF")
        return
    end

    if msg == "off" then
        DB.enabled = false
        UpdateState()
        return
    end

    if msg == "on" then
        DB.enabled = true
        UpdateState()
        return
    end

    if msg == "mounted" then
        DB.hideWhileMounted = not DB.hideWhileMounted
        print("CompanionStatus hide while mounted:", DB.hideWhileMounted and "ON" or "OFF")
        UpdateState()
        return
    end

    print("|cff00ff00/cs debug|r - toggle debug")
    print("|cff00ff00/cs on|r / |cff00ff00off|r")
    print("|cff00ff00/cs mounted|r - toggle hiding while mounted on the ground")
end
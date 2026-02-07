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
    point = { "CENTER", UIParent, "CENTER", 0, 0 },
    displayMode = "both", -- icon | text | both
}

local DB

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

local function ShouldShowIcon()
    if IsFlying() then return false end
    return true
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
    CompanionStatus:SetPoint(unpack(DB.point))
end

function UpdateIcon()
    if ShouldShowIcon() then
        icon:Show()
    else
        icon:Hide()
    end
end

--------------------------------------------------
-- Core logic (SAFE)
--------------------------------------------------
local function UpdateState()
    if not DB.enabled then
        CompanionStatus:Hide()
        return
    end

    -- Hide while flying
    if IsFlying() then
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
        text:SetText("Pet missing")
        ApplyDisplay()
        CompanionStatus:Show()
        Debug("Pet missing")
        return
    end

    if UnitIsDeadOrGhost("pet") then
        icon:SetTexture(GetPetIcon())
        text:SetText("Pet dead")
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

CompanionStatus:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        ApplyDefaults(CompanionStatusDB, DEFAULTS)
        DB = CompanionStatusDB

        self:SetScale(DB.scale)
        self:SetSize(DB.size, DB.size)

        ApplyPosition()
        ApplyDisplay()
        UpdateState()
        UpdateIcon()
        return
    end

    if event == "UNIT_HEALTH" and arg1 ~= "pet" then return end
    if event == "UNIT_PET" and arg1 ~= "player" then return end

    UpdateState()
end)

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

    print("|cff00ff00/cs debug|r - toggle debug")
    print("|cff00ff00/cs on|r / |cff00ff00off|r")
end
-- CompanionStatus (Retail - TomoMod integrated)
-- Affiche une icone quand le pet est mort ou absent
-- pour Hunter (BM/Surv), Warlock, DK Unholy

TomoMod_CompanionStatus = TomoMod_CompanionStatus or {}
local CS = TomoMod_CompanionStatus

--------------------------------------------------
-- Frame
--------------------------------------------------
local CompanionStatus = CreateFrame("Frame", "CompanionStatusFrame", UIParent, "BackdropTemplate")
CompanionStatus:Hide()

--------------------------------------------------
-- Defaults (ce module gere ses propres defaults
-- car il n'est pas dans Database.lua)
--------------------------------------------------
local DEFAULTS = {
    enabled = true,
    debug = false,
    scale = 4.0,
    size = 36,
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
    displayMode = "both", -- icon | text | both
}

local DB

local function EnsureDB()
    if not TomoModDB then return false end
    if not TomoModDB.companionStatus then
        TomoModDB.companionStatus = {}
    end
    for k, v in pairs(DEFAULTS) do
        if TomoModDB.companionStatus[k] == nil then
            TomoModDB.companionStatus[k] = v
        end
    end
    DB = TomoModDB.companionStatus
    return true
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
-- Icons
-- Note: UnitGUID("pet") retourne un unit GUID (Creature-0-...)
-- alors que C_PetJournal attend un BattlePet GUID.
-- On utilise les icones de sort comme fallback fiable.
--------------------------------------------------
local HUNTER_MEND_SPELL = 136

local function GetHunterPetIcon()
    return SpellIcon(HUNTER_MEND_SPELL)
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
    return SpellIcon(46584)
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
    if not DB then return end
    if DB.displayMode == "icon" then
        icon:Show()
        text:Hide()
    elseif DB.displayMode == "text" then
        icon:Hide()
        text:Show()
        text:ClearAllPoints()
        text:SetPoint("CENTER", CompanionStatus, "CENTER", 0, 0)
    else
        icon:Show()
        text:Show()
        text:ClearAllPoints()
        text:SetPoint("TOP", CompanionStatus, "BOTTOM", 0, -2)
    end
end

local function ApplyPosition()
    if not DB then return end
    CompanionStatus:ClearAllPoints()
    CompanionStatus:SetPoint(
        DB.point or "CENTER",
        UIParent,
        DB.relativePoint or "CENTER",
        DB.x or 0,
        DB.y or 0
    )
end

local function UpdateIcon()
    if not IsFlying() then
        icon:Show()
    else
        icon:Hide()
    end
end

--------------------------------------------------
-- Core logic
--------------------------------------------------
local function UpdateState()
    if not DB or not DB.enabled then
        CompanionStatus:Hide()
        return
    end

    if IsFlying() then
        CompanionStatus:Hide()
        return
    end

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
-- Events
-- On utilise PLAYER_LOGIN au lieu de ADDON_LOADED
-- car le vararg ... retourne nil dans un fichier
-- charge via <Include> XML.
--------------------------------------------------
CompanionStatus:RegisterEvent("PLAYER_LOGIN")
CompanionStatus:RegisterEvent("PLAYER_ENTERING_WORLD")
CompanionStatus:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
CompanionStatus:RegisterEvent("PLAYER_TALENT_UPDATE")
CompanionStatus:RegisterUnitEvent("UNIT_PET", "player")
CompanionStatus:RegisterUnitEvent("UNIT_HEALTH", "pet")
CompanionStatus:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
CompanionStatus:RegisterUnitEvent("UNIT_FLAGS", "pet")

CompanionStatus:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        if not EnsureDB() then return end
        self:SetScale(DB.scale)
        self:SetSize(DB.size, DB.size)
        ApplyPosition()
        ApplyDisplay()
        UpdateState()
        UpdateIcon()
        return
    end

    if not DB then return end
    if event == "UNIT_HEALTH" and arg1 ~= "pet" then return end
    if event == "UNIT_PET" and arg1 ~= "player" then return end

    UpdateState()
end)

--------------------------------------------------
-- Slash commands
--------------------------------------------------
SLASH_COMPANIONSTATUS1 = "/cs"
SlashCmdList.COMPANIONSTATUS = function(msg)
    if not DB then
        print("|cffff0000CompanionStatus:|r DB non initialisee")
        return
    end
    msg = (msg or ""):lower()

    if msg == "debug" then
        DB.debug = not DB.debug
        print("|cff0cd29fCompanionStatus|r debug:", DB.debug and "ON" or "OFF")
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

    print("|cff0cd29f/cs debug|r - toggle debug")
    print("|cff0cd29f/cs on|r / |cff0cd29foff|r")
end

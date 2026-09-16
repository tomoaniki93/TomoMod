-- =====================================
-- QOL/Combat/CombatText.lua
-- Affiche "+ COMBAT" / "- COMBAT" au centre de l'écran
-- et gère les options granulaires du texte de combat flottant Blizzard.
-- =====================================

TomoMod_CombatText = TomoMod_CombatText or {}
local CTX = TomoMod_CombatText

local L = TomoMod_L

local FONT_PATH = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local FONT_SIZE = 26
local FADE_DURATION = 2.0

-- Midnight 12.x: Blizzard a déplacé les réglages FCT vers les CVars _v2.
-- Le switch dégâts couvre les dégâts directs/périodiques et ceux du familier.
-- Le switch soins reste volontairement limité aux montants de soins : les
-- absorptions/boucliers gardent leur réglage Blizzard indépendant.
local FCT_DAMAGE_CVARS = {
    "floatingCombatTextCombatDamage_v2",
    "floatingCombatTextCombatLogPeriodicSpells_v2",
    "floatingCombatTextPetMeleeDamage_v2",
    "floatingCombatTextPetSpellDamage_v2",
}
local FCT_HEALING_CVARS = {
    "floatingCombatTextCombatHealing_v2",
}

local FCT_CVAR_GROUP = {}
for _, cvar in ipairs(FCT_DAMAGE_CVARS) do FCT_CVAR_GROUP[cvar] = "damage" end
for _, cvar in ipairs(FCT_HEALING_CVARS) do FCT_CVAR_GROUP[cvar] = "healing" end

-- =====================================
-- Display frame
-- =====================================
local frame = CreateFrame("Frame", "TomoMod_CombatTextFrame", UIParent)
frame:SetSize(300, 40)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetFrameStrata("HIGH")

local text = frame:CreateFontString(nil, "OVERLAY")
text:SetFont(FONT_PATH, FONT_SIZE, "OUTLINE")
text:SetPoint("CENTER", frame, "CENTER")
text:SetJustifyH("CENTER")

local fadeGroup = frame:CreateAnimationGroup()
local fadeAnim = fadeGroup:CreateAnimation("Alpha")
fadeAnim:SetFromAlpha(1)
fadeAnim:SetToAlpha(0)
fadeAnim:SetDuration(FADE_DURATION)
fadeAnim:SetStartDelay(0.5)
fadeGroup:SetScript("OnFinished", function() frame:SetAlpha(0) end)

-- =====================================
-- Helpers
-- =====================================
local function GetDB()
    return TomoModDB and TomoModDB.combatText
end

local function GetFloatingDB()
    if not TomoModDB then return nil, nil end

    TomoModDB.floatingCombatText = TomoModDB.floatingCombatText or {
        hideDamage = false,
        hideHealing = false,
    }

    -- Backup hors profil : il doit survivre à un reset / changement de profil
    -- pour pouvoir restaurer exactement les valeurs Blizzard précédentes.
    TomoModDB._floatingCombatTextBackup = TomoModDB._floatingCombatTextBackup or {}
    local backup = TomoModDB._floatingCombatTextBackup
    backup.damage = backup.damage or {}
    backup.healing = backup.healing or {}

    return TomoModDB.floatingCombatText, backup
end

local function ReadCVar(name)
    local ok, value = pcall(GetCVar, name)
    if not ok or value == nil then return nil end
    return tostring(value)
end

local function WriteCVar(name, value)
    local ok = pcall(SetCVar, name, tostring(value))
    return ok
end

local function SetGroupHidden(groupKey, cvars, hidden)
    local _, backup = GetFloatingDB()
    if not backup then return end

    local values = backup[groupKey]
    if hidden then
        for _, cvar in ipairs(cvars) do
            local current = ReadCVar(cvar)
            if current ~= nil then
                if values[cvar] == nil then
                    values[cvar] = current
                end
                if current ~= "0" then
                    WriteCVar(cvar, "0")
                end
            end
        end
        return
    end

    for _, cvar in ipairs(cvars) do
        local previous = values[cvar]
        if previous ~= nil then
            local current = ReadCVar(cvar)
            if current == nil or WriteCVar(cvar, previous) then
                values[cvar] = nil
            end
        end
    end
end

local function UpdatePosition()
    local db = GetDB()
    if not db then return end
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", db.offsetX or 0, db.offsetY or 0)
end

local function ShowText(msg, r, g, b)
    local db = GetDB()
    if not db or not db.enabled then return end
    UpdatePosition()
    fadeGroup:Stop()
    frame:SetAlpha(1)
    text:SetText(msg)
    text:SetTextColor(r, g, b)
    fadeGroup:Play()
end

local function EnforceFloatingCVar(cvar)
    local group = FCT_CVAR_GROUP[cvar]
    if not group then return end

    local db = GetFloatingDB()
    if not db then return end

    local shouldHide = (group == "damage" and db.hideDamage == true)
        or (group == "healing" and db.hideHealing == true)

    if shouldHide and ReadCVar(cvar) ~= "0" then
        WriteCVar(cvar, "0")
    end
end

-- =====================================
-- Events
-- =====================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CVAR_UPDATE")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        CTX.Initialize()
    elseif event == "ADDON_LOADED" and arg1 == "Blizzard_CombatText" then
        if C_Timer and C_Timer.After then
            C_Timer.After(0, CTX.ApplyFloatingTextSettings)
        else
            CTX.ApplyFloatingTextSettings()
        end
    elseif event == "CVAR_UPDATE" then
        EnforceFloatingCVar(arg1)
    elseif event == "PLAYER_REGEN_DISABLED" then
        ShowText("+ COMBAT", 1.0, 0.15, 0.15)
    elseif event == "PLAYER_REGEN_ENABLED" then
        ShowText("- COMBAT", 1.0, 1.0, 1.0)
    end
end)

-- =====================================
-- Public API
-- =====================================
function CTX.Initialize()
    if not TomoModDB then return end
    if not TomoModDB.combatText then
        TomoModDB.combatText = { enabled = false, offsetX = 0, offsetY = 0 }
    end

    frame:SetAlpha(0)
    CTX.ApplyFloatingTextSettings()

    -- Blizzard_CombatText peut réappliquer ses CVars légèrement après le login.
    -- Une seconde passe garde le choix TomoMod sans forcer le CVar maître FCT.
    if C_Timer and C_Timer.After then
        C_Timer.After(1, CTX.ApplyFloatingTextSettings)
    end
end

function CTX.ApplyFloatingTextSettings()
    local db = GetFloatingDB()
    if not db then return end

    SetGroupHidden("damage", FCT_DAMAGE_CVARS, db.hideDamage == true)
    SetGroupHidden("healing", FCT_HEALING_CVARS, db.hideHealing == true)
end

function CTX.SetFloatingDamageHidden(v)
    local db = GetFloatingDB()
    if not db then return end
    db.hideDamage = v and true or false
    SetGroupHidden("damage", FCT_DAMAGE_CVARS, db.hideDamage)
end

function CTX.SetFloatingHealingHidden(v)
    local db = GetFloatingDB()
    if not db then return end
    db.hideHealing = v and true or false
    SetGroupHidden("healing", FCT_HEALING_CVARS, db.hideHealing)
end

function CTX.SetEnabled(v)
    local db = GetDB()
    if not db then return end
    db.enabled = v
    if not v then
        fadeGroup:Stop()
        frame:SetAlpha(0)
    end
end

function CTX.UpdatePosition()
    UpdatePosition()
end

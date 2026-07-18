-- =====================================
-- QOL/Combat/CombatText.lua
-- Affiche "+ COMBAT" / "- COMBAT" au centre de l'écran
-- =====================================

TomoMod_CombatText = TomoMod_CombatText or {}
local CTX = TomoMod_CombatText

local L = TomoMod_L

local FONT_PATH = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local FONT_SIZE = 26
local FADE_DURATION = 2.0

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

-- =====================================
-- Events
-- =====================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        CTX.Initialize()
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

-- =====================================
-- ClassReminder.lua — Missing Buff / Form / Stance / Aura Reminder
-- =====================================

TomoMod_ClassReminder = TomoMod_ClassReminder or {}
local CR = TomoMod_ClassReminder

local ADDON_FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local L = TomoMod_L

-- ── Helpers ──────────────────────────────────────────────────

local function GetDB()
    return TomoModDB and TomoModDB.classReminder
end

-- ── Class Data ──────────────────────────────────────────────
-- Each entry: spellIDs = list of buff spell IDs to check on the player
-- formIDs   = list of shapeshift form indices that count as "active"
-- stanceIDs = same (GetShapeshiftForm index, 1-based)
-- auraIDs   = paladin auras (buff on player)

local CLASS_DATA = {
    PRIEST = {
        buffs = {
            { nameKey = "cr_fortitude", spellIDs = { 21562 } },
        },
        forms = {
            -- Shadow Priest: Shadowform (spellID 232698) — shapeshift form index 1
            { nameKey = "cr_shadowform", formIndices = { 1 }, specID = 258 },
        },
    },
    MAGE = {
        buffs = {
            { nameKey = "cr_arcane_intellect", spellIDs = { 1459 } },
        },
    },
    SHAMAN = {
        buffs = {
            { nameKey = "cr_skyfury", spellIDs = { 462854 } },
        },
    },
    DRUID = {
        buffs = {
            { nameKey = "cr_mark_of_the_wild", spellIDs = { 1126 } },
        },
        forms = {
            -- Cat(2) Feral, Bear(1) Guardian, Moonkin(4) Balance
            { nameKey = "cr_cat_form",     formIndices = { 2 }, specID = 103 },
            { nameKey = "cr_bear_form",    formIndices = { 1 }, specID = 104 },
            { nameKey = "cr_moonkin_form", formIndices = { 4 }, specID = 102 },
        },
    },
    WARRIOR = {
        buffs = {
            { nameKey = "cr_battle_shout", spellIDs = { 6673 } },
        },
        forms = {
            -- Stances are shapeshift forms for warriors
            { nameKey = "cr_stance", formIndices = { 1, 2, 3 } },
        },
    },
    PALADIN = {
        forms = {
            -- Devotion Aura / Crusader Aura / Concentration Aura / Retribution Aura
            -- Paladin auras use the shapeshift form system, not player buffs
            { nameKey = "cr_aura", formIndices = { 1, 2, 3, 4, 5, 6, 7 } },
        },
    },
    EVOKER = {
        buffs = {
            { nameKey = "cr_blessing_bronze", spellIDs = { 381748 } },
        },
    },
}

-- ── Display Frame ────────────────────────────────────────────

local reminderFrame = CreateFrame("Frame", "TomoMod_ClassReminderFrame", UIParent)
reminderFrame:SetSize(400, 50)
reminderFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
reminderFrame:SetFrameStrata("HIGH")
reminderFrame:Hide()

local reminderText = reminderFrame:CreateFontString(nil, "OVERLAY")
reminderText:SetFont(ADDON_FONT, 22, "OUTLINE")
reminderText:SetPoint("CENTER", reminderFrame, "CENTER")
reminderText:SetTextColor(1, 1, 1, 1)

-- ── State ────────────────────────────────────────────────────

local playerClass
local currentSpecID
local missingList = {}

-- ── Core Logic ───────────────────────────────────────────────

local function PlayerHasBuff(spellIDs)
    for _, id in ipairs(spellIDs) do
        if C_UnitAuras then
            local aura = C_UnitAuras.GetPlayerAuraBySpellID(id)
            if aura then return true end
        end
    end
    return false
end

local function PlayerHasAnyForm(formIndices)
    local current = GetShapeshiftForm()
    if current == 0 then return false end
    for _, idx in ipairs(formIndices) do
        if current == idx then return true end
    end
    return false
end

local _cr_missing = {}

local function CheckMissing()
    wipe(_cr_missing)
    local db = GetDB()
    if not db or not db.enabled then return _cr_missing end

    local data = CLASS_DATA[playerClass]
    if not data then return _cr_missing end

    -- Check buffs
    if data.buffs then
        for _, buff in ipairs(data.buffs) do
            if not PlayerHasBuff(buff.spellIDs) then
                _cr_missing[#_cr_missing + 1] = L[buff.nameKey]
            end
        end
    end

    -- Check forms/stances (only if spec matches when specID is set)
    if data.forms then
        for _, form in ipairs(data.forms) do
            local matchSpec = true
            if form.specID and form.specID ~= currentSpecID then
                matchSpec = false
            end
            if matchSpec and not PlayerHasAnyForm(form.formIndices) then
                _cr_missing[#_cr_missing + 1] = L[form.nameKey]
            end
        end
    end

    return _cr_missing
end

local function UpdateDisplay()
    local db = GetDB()
    if not db or not db.enabled then
        reminderFrame:Hide()
        return
    end

    missingList = CheckMissing()

    if #missingList > 0 then
        local text = table.concat(missingList, "  |  ")
        reminderText:SetText(text)

        -- Apply settings
        local scale = db.scale or 1.0
        reminderFrame:SetScale(scale)

        local color = db.textColor or { r = 1, g = 1, b = 1 }
        reminderText:SetTextColor(color.r, color.g, color.b, 1)

        local offX = db.offsetX or 0
        local offY = db.offsetY or 0
        reminderFrame:ClearAllPoints()
        reminderFrame:SetPoint("CENTER", UIParent, "CENTER", offX, offY)

        reminderFrame:Show()
    else
        reminderFrame:Hide()
    end
end

-- ── Pulse Animation ──────────────────────────────────────────

local pulseGroup = reminderFrame:CreateAnimationGroup()
local fadeIn = pulseGroup:CreateAnimation("Alpha")
fadeIn:SetFromAlpha(0.4)
fadeIn:SetToAlpha(1.0)
fadeIn:SetDuration(0.8)
fadeIn:SetOrder(1)
fadeIn:SetSmoothing("IN_OUT")

local fadeOut = pulseGroup:CreateAnimation("Alpha")
fadeOut:SetFromAlpha(1.0)
fadeOut:SetToAlpha(0.4)
fadeOut:SetDuration(0.8)
fadeOut:SetOrder(2)
fadeOut:SetSmoothing("IN_OUT")

pulseGroup:SetLooping("REPEAT")

reminderFrame:SetScript("OnShow", function()
    pulseGroup:Play()
end)
reminderFrame:SetScript("OnHide", function()
    pulseGroup:Stop()
end)

-- ── Throttled Update ─────────────────────────────────────────

local UPDATE_INTERVAL = 1.0
local timeSinceUpdate = 0

local function OnUpdate(_, elapsed)
    timeSinceUpdate = timeSinceUpdate + elapsed
    if timeSinceUpdate >= UPDATE_INTERVAL then
        timeSinceUpdate = 0
        UpdateDisplay()
    end
end

-- ── Public API ───────────────────────────────────────────────

function CR.SetEnabled(v)
    local db = GetDB()
    if db then db.enabled = v end
    if v then
        reminderFrame:SetScript("OnUpdate", OnUpdate)
        UpdateDisplay()
    else
        reminderFrame:SetScript("OnUpdate", nil)
        reminderFrame:Hide()
    end
end

function CR.ApplySettings()
    local db = GetDB()
    if not db or not db.enabled then
        reminderFrame:Hide()
        return
    end
    UpdateDisplay()
end

function CR.Initialize()
    local db = GetDB()
    if not db then return end

    -- Cache class & spec
    local _, englishClass = UnitClass("player")
    playerClass = englishClass
    currentSpecID = GetSpecializationInfo(GetSpecialization() or 1) or 0

    if db.enabled then
        reminderFrame:SetScript("OnUpdate", OnUpdate)
        UpdateDisplay()
    end
end

-- ── Events ───────────────────────────────────────────────────

local eventFrame = CreateFrame("Frame", "TomoMod_ClassReminderEvents")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        CR.Initialize()
        return
    end

    local db = GetDB()
    if not db or not db.enabled then return end

    if event == "UNIT_AURA" and arg1 == "player" then
        UpdateDisplay()
    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        UpdateDisplay()
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        currentSpecID = GetSpecializationInfo(GetSpecialization() or 1) or 0
        UpdateDisplay()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        UpdateDisplay()
    end
end)

-- ── Register Module ──────────────────────────────────────────

TomoMod_RegisterModule("classReminder", CR)

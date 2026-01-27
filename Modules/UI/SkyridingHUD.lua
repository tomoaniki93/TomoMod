-- =====================================
-- SkyridingHUD.lua
-- Barre de Skyriding HUD
-- =====================================

TomoMod_SkiridingHUD = {}

local skyriding
local IsFlying = false

-- =====================================
-- Informations sur le Skyriding
-- =====================================
-- les sorts de vol
local SPELLS = {
    ACCELERATION = 372610, -- Skyward Ascent
    VIGOR        = 372608, -- Second souffle
    WHIRL        = 361584, -- Impulsion tournoyante
}

-- Nombres de charges
local MAX_CHARGES = {
    [SPELLS.ACCELERATION] = 6,
    [SPELLS.VIGOR]        = 3,
    [SPELLS.WHIRL]        = 1,
}

-- =====================================
-- CREATION DES BARRES
-- =====================================
local function CreateBar(parent, index, color)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(CONFIG.barWidth, CONFIG.barHeight)

    local xOffset = (index - 1) * (CONFIG.barWidth + CONFIG.spacing)
    bar:SetPoint("LEFT", parent, "LEFT", xOffset, 0)

    bar:SetStatusBarTexture(Tomo.Media.Textures.PRIMARY)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar:SetStatusBarColor(unpack(color))

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)

    -- Animation (pulse)
    bar.anim = bar:CreateAnimationGroup()

    local grow = bar.anim:CreateAnimation("Scale")
    grow:SetScale(CONFIG.pulseScale, CONFIG.pulseScale)
    grow:SetDuration(CONFIG.pulseTime)
    grow:SetOrder(1)

    local shrink = bar.anim:CreateAnimation("Scale")
    shrink:SetScale(1 / CONFIG.pulseScale, 1 / CONFIG.pulseScale)
    shrink:SetDuration(CONFIG.pulseTime)
    shrink:SetOrder(2)

    return bar
end

-- =====================================
-- COULEURS DES RESSOURCES
-- =====================================
local Bars = {
    [SPELLS.ACCELERATION] = CreateBar(Frame, 1, CONFIG.colors.acceleration),
    [SPELLS.VIGOR]        = CreateBar(Frame, 2, CONFIG.colors.vigor),
    [SPELLS.WHIRL]        = CreateBar(Frame, 3, CONFIG.colors.whirl),
}

local PreviousCharges = {}

-- =====================================
-- FONCTIONS UTILITAIRES
-- =====================================
-- Vérifier si le joueur vol en utilisant une monture skyriding
local function IsUsingSkyriding()
    return IsFlying()
       and C_PlayerInfo.IsPlayerUsingSkyriding()
end

local function UpdateBar(spellID)
    local bar = Bars[spellID]
    if not bar then return end

    local charges, max = C_Spell.GetSpellCharges(spellID)
    if not charges then
        bar:SetValue(0)
        return
    end

    bar:SetMinMaxValues(0, MAX_CHARGES[spellID])
    bar:SetValue(charges)

    -- Animation sur le gain d'une charge
    local prev = PreviousCharges[spellID] or charges
    if charges > prev and not bar.anim:IsPlaying() then
        bar.anim:Play()
    end
    PreviousCharges[spellID] = charges
end

-- =====================================
-- MISE À JOUR DU VOL
-- =====================================
local function UpdateHUD()
    if not IsUsingSkyriding() then
        Frame:Hide()
        return
    end

    Frame:Show()

    for spellID in pairs(Bars) do
        UpdateBar(spellID)
    end
end

-- =====================================
-- ÉVÉNEMENTS
-- =====================================
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
EventFrame:RegisterEvent("UNIT_AURA")

EventFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" and unit ~= "player" then return end
    UpdateHUD()
end)

-- sécurité
C_Timer.NewTicker(0.25, UpdateHUD)
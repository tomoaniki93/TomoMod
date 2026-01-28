-- ==========================================================================
-- UnitFrames.lua
-- Barres de vie pour Player, Target et TargetOfTarget
-- ==========================================================================

TomoMod_UnitFrames = {}
local UF = TomoMod_UnitFrames

UF.isPreview = false

local function SavePosition(frame, key)
    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
    TomoModDB.unitFrames.positions[key] = {
        point = point,
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs,
    }
end

function UF.EnableMove(frame, key)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self, key)
    end)
end

function UF.DisableMove(frame)
    frame:SetMovable(false)
    frame:EnableMouse(true) -- 🔑 indispensable pour SecureUnitButton
    frame:SetScript("OnDragStart", nil)
    frame:SetScript("OnDragStop", nil)
end

----------------------------------------------------------
-- Locals & shortcuts
----------------------------------------------------------
local abs, min, format = math.abs, math.min, string.format

----------------------------------------------------------
-- Class / reaction color cache
----------------------------------------------------------
local CLASS_COLORS = {}

local function GetUnitColor(unit, useClass)
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if useClass and class then
            if not CLASS_COLORS[class] then
                local c = RAID_CLASS_COLORS[class]
                CLASS_COLORS[class] = { c.r, c.g, c.b }
            end
            return unpack(CLASS_COLORS[class])
        end
    end

    local r, g, b = UnitSelectionColor(unit)
    return r, g, b
end

----------------------------------------------------------
-- Frame factory
----------------------------------------------------------
local function CreateUnitFrame(name, width, height)

    local f = CreateFrame("Button", name, UIParent, "SecureUnitButtonTemplate")
    f:SetSize(width, height)
    f:SetScale(1)
    f:SetClampedToScreen(true)
    f:RegisterForClicks("AnyUp")
    f:SetAttribute("type1", "target")
    f:SetAttribute("type2", "togglemenu")

    -- Health bar
    f.healthBar = CreateFrame("StatusBar", nil, f)
    f.healthBar:SetAllPoints()
    f.healthBar:SetStatusBarTexture("Interface\\AddOns\\TomoMod\\Assets\\Textures\\TomoMod.tga")
    f.healthBar:SetMinMaxValues(0, 1)
    f.healthBar:SetPoint("TOPLEFT", 1, -1)
    f.healthBar:SetPoint("BOTTOMRIGHT", -1, 1)

    -- Power bar
    local POWER_HEIGHT = 6
    local BORDER_SIZE = 1
    local POWER_OVERLAP = 3

    -- Frame border
    f.powerBorder = CreateFrame("Frame", nil, f.healthBar)
    f.powerBorder:SetHeight(POWER_HEIGHT + BORDER_SIZE * 2)
    f.powerBorder:SetPoint("TOPLEFT", f.healthBar, "BOTTOMLEFT", 0, POWER_OVERLAP)
    f.powerBorder:SetPoint("TOPRIGHT", f.healthBar, "BOTTOMRIGHT", 0, POWER_OVERLAP)

    -- Fond du contour
    f.powerBorder.bg = f.powerBorder:CreateTexture(nil, "BACKGROUND")
    f.powerBorder.bg:SetAllPoints()
    f.powerBorder.bg:SetColorTexture(0, 0, 0, 0.8) -- contour noir discret

    -- Power bar à l’intérieur
    f.powerBar = CreateFrame("StatusBar", nil, f.powerBorder)
    f.powerBar:SetPoint("TOPLEFT", BORDER_SIZE, -BORDER_SIZE)
    f.powerBar:SetPoint("BOTTOMRIGHT", -BORDER_SIZE, BORDER_SIZE)
    f.powerBar:SetStatusBarTexture("Interface\\AddOns\\TomoMod\\Assets\\Textures\\TomoMod.tga")
    f.powerBar:SetMinMaxValues(0, 1)

    -- Heal prediction
    f.healBar = CreateFrame("StatusBar", nil, f.healthBar)
    f.healBar:SetAllPoints()
    f.healBar:SetStatusBarTexture("Interface\\AddOns\\TomoMod\\Assets\\Textures\\TomoMod.tga")
    f.healBar:SetStatusBarColor(0, 1, 0, 0.35)

    -- Absorb bar
    f.absorbBar = CreateFrame("StatusBar", nil, f.healthBar)
    f.absorbBar:SetAllPoints()
    f.absorbBar:SetStatusBarTexture("Interface\\AddOns\\TomoMod\\Assets\\Textures\\TomoMod.tga")
    f.absorbBar:SetStatusBarColor(0.2, 0.6, 1, 0.6)

    -- Health text
    f.healthText = f.healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.healthText:SetPoint("CENTER", f.healthBar, "CENTER", 0, 0)
    f.healthText:SetDrawLayer("ARTWORK", 7)
    f.healthText:SetTextColor(1, 1, 1)
    f.healthText:SetShadowOffset(1, -1)
    f.healthText:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\TomoMod.TTF", 11, "OUTLINE")
    f.healthText:SetShadowOffset(0, 0)

    -- Heal prediction (overlay)
    f.healBar:SetFrameLevel(f.healthBar:GetFrameLevel() + 1)
    f.healBar:SetAlpha(0.4)

    -- Absorb (overlay)
    f.absorbBar:SetFrameLevel(f.healthBar:GetFrameLevel() + 2)
    f.absorbBar:SetAlpha(0.6)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0, 0, 0, 0.6)

    -- Name
    f.nameText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.nameText:SetPoint("LEFT", f, 6, 0)

    -- Level
    f.levelText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.levelText:SetPoint("RIGHT", f, -6, 0)

    -- Raid icon
    f.raidIcon = f:CreateTexture(nil, "OVERLAY")
    f.raidIcon:SetSize(16, 16)
    f.raidIcon:SetPoint("CENTER", f, "TOP", 0, 8)

    return f
end

----------------------------------------------------------
-- Generic UnnitInfo update
----------------------------------------------------------
local function UpdateUnitInfo(frame, unit, db)
    if not UnitExists(unit) then return end

    -- Name
    if db.showName then
        local name = UnitName(unit)
        if db.truncateName and name then
            name = string.sub(name, 1, db.truncateNameLength or 8)
        end
        frame.nameText:SetText(name or "")
        frame.nameText:Show()
    else
        frame.nameText:Hide()
    end

    -- Level
    if db.showLevel then
        local level = UnitLevel(unit)
        frame.levelText:SetText(level > 0 and level or "??")
        frame.levelText:Show()
    else
        frame.levelText:Hide()
    end

    -- Raid marker
    if db.showRaidMarker then
        local icon = GetRaidTargetIndex(unit)
        if icon then
            SetRaidTargetIconTexture(frame.raidIcon, icon)
            frame.raidIcon:Show()
        else
            frame.raidIcon:Hide()
        end
    else
        frame.raidIcon:Hide()
    end
end


----------------------------------------------------------
-- Generic health update
----------------------------------------------------------
local function UpdateHealth(frame, unit, db)
    if not UnitExists(unit) then
        frame:Hide()
        return
    end

    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)

    -- Si Blizzard n'a pas encore fourni les valeurs
    if health == nil or maxHealth == nil then
        return
    end

    frame:Show()
    frame.healthBar:SetMinMaxValues(0, maxHealth)
    frame.healthBar:SetValue(health)

    if db.showCurrentHP then
        frame.healthText:SetText(AbbreviateNumbers(health))
    else
        frame.healthText:SetText("")
    end

    if UnitIsDeadOrGhost(unit) then
        frame.healthText:SetTextColor(0.6, 0.6, 0.6)
    else
        frame.healthText:SetTextColor(1, 1, 1)
    end

    local r, g, b = GetUnitColor(unit, db.useClassColor)
    frame.healthBar:SetStatusBarColor(r, g, b)

    -- Heal prediction (TWW-safe)
    frame.healBar:SetMinMaxValues(0, maxHealth)
    local incHeal = UnitGetIncomingHeals(unit)
    if incHeal ~= nil then
        frame.healBar:SetMinMaxValues(0, maxHealth)
        frame.healBar:SetValue(incHeal)
    else
        frame.healBar:SetValue(0)
    end
    frame.healBar:Show()

    -- Absorb (TWW-safe)
    frame.absorbBar:SetMinMaxValues(0, maxHealth)
    frame.absorbBar:SetValue(UnitGetTotalAbsorbs(unit))
    frame.absorbBar:Show()
end

----------------------------------------------------------
-- Generic Power update
----------------------------------------------------------
local function UpdatePower(frame, unit, db)
    if not frame.powerBar or not db.showPowerBar then
        if frame.powerBorder then frame.powerBorder:Hide() end
        return
    end

    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)

    if power == nil or maxPower == nil then
        frame.powerBar:Hide()
        return
    end

    frame.powerBar:Show()
    frame.powerBar:SetMinMaxValues(0, maxPower)
    frame.powerBar:SetValue(power)

    local powerType = UnitPowerType(unit)
    local color = PowerBarColor[powerType]
    if color then
        frame.powerBar:SetStatusBarColor(color.r, color.g, color.b)
    end
    frame.powerBorder:Show()
end

----------------------------------------------------------
-- Frames
----------------------------------------------------------
local PlayerFrameUF
local TargetFrameUF
local ToTFrameUF

----------------------------------------------------------
-- Updates
----------------------------------------------------------
function UF.UpdatePlayer()
    local frame = PlayerFrameUF
    local unit = "player"
    local db = TomoModDB.unitFrames.player

    if not db.enabled then
        frame:Hide()
        return
    end

    UpdateHealth(frame, unit, db)
    UpdatePower(frame, unit, db)
    UpdateUnitInfo(frame, unit, db)
end


function UF.UpdateTarget()
    local frame = TargetFrameUF
    local unit = "target"
    local db = TomoModDB.unitFrames.target

    if not db.enabled then
        frame:Hide()
        return
    end

    UpdateHealth(frame, unit, db)
    UpdatePower(frame, unit, db)
    UpdateUnitInfo(frame, unit, db)
end


function UF.UpdateToT()
    local frame = ToTFrameUF
    local unit = "targettarget"
    local db = TomoModDB.unitFrames.targetoftarget

    if not db.enabled then
        frame:Hide()
        return
    end

    UpdateHealth(frame, unit, db)
    UpdateUnitInfo(frame, unit, db)
end

----------------------------------------------------------
-- Settings application
----------------------------------------------------------
local function ApplySettings(frame, db)
    frame:SetSize(db.width, db.height)
    frame:SetScale(db.scale)
    if db.minimalist then
        frame.nameText:Hide()
        frame.levelText:Hide()
        frame.healthText:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\TomoMod.TTF", 9, "OUTLINE")
        frame.powerBar:SetHeight(4)
    else
        frame.healthText:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\TomoMod.TTF", 11, "OUTLINE")
        frame.powerBar:SetHeight(6)
    end
end

function UF.UpdatePlayerSettings()
    ApplySettings(PlayerFrameUF, TomoModDB.unitFrames.player)
    UF.UpdatePlayer()
end

function UF.UpdateTargetSettings()
    ApplySettings(TargetFrameUF, TomoModDB.unitFrames.target)
    UF.UpdateTarget()
end

function UF.UpdateToTSettings()
    ApplySettings(ToTFrameUF, TomoModDB.unitFrames.targetoftarget)
    UF.UpdateToT()
    ToTFrameUF:SetAlpha(0.85)
    ToTFrameUF.nameText:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\TomoMod.TTF", 9, "OUTLINE")
    ToTFrameUF.healthText:Hide()
end

----------------------------------------------------------
-- Position reset
----------------------------------------------------------
function UF.ResetPlayerPosition()
    PlayerFrameUF:ClearAllPoints()
    PlayerFrameUF:SetPoint("CENTER", UIParent, "CENTER", -200, -200)
end

function UF.ResetTargetPosition()
    TargetFrameUF:ClearAllPoints()
    TargetFrameUF:SetPoint("CENTER", UIParent, "CENTER", 200, -200)
end

function UF.ResetToTPosition()
    ToTFrameUF:ClearAllPoints()
    ToTFrameUF:SetPoint("TOP", TargetFrameUF, "BOTTOM", 0, -10)
end

----------------------------------------------------------
-- Preview mode
----------------------------------------------------------
local PREVIEW_BG_COLOR = { 0, 0, 0, 0.8 } -- noir semi-opaque
local NORMAL_BG_COLOR  = { 0, 0, 0, 0.6 } -- normal en jeu

function UF.ShowPreview()
    UF.isPreview = true

    PlayerFrameUF:Show()
    TargetFrameUF:Show()
    ToTFrameUF:Show()

    PlayerFrameUF.bg:SetColorTexture(unpack(PREVIEW_BG_COLOR))
    TargetFrameUF.bg:SetColorTexture(unpack(PREVIEW_BG_COLOR))
    ToTFrameUF.bg:SetColorTexture(unpack(PREVIEW_BG_COLOR))

    UF.EnableMove(PlayerFrameUF, "player")
    UF.EnableMove(TargetFrameUF, "target")
    UF.EnableMove(ToTFrameUF, "tot")
end

function UF.HidePreview()
    if not UF.isPreview then return end
    UF.isPreview = false

    PlayerFrameUF.bg:SetColorTexture(unpack(NORMAL_BG_COLOR))
    TargetFrameUF.bg:SetColorTexture(unpack(NORMAL_BG_COLOR))
    ToTFrameUF.bg:SetColorTexture(unpack(NORMAL_BG_COLOR))

    UF.DisableMove(PlayerFrameUF)
    UF.DisableMove(TargetFrameUF)
    UF.DisableMove(ToTFrameUF)

    UF.UpdatePlayer()
    UF.UpdateTarget()
    UF.UpdateToT()
end

local function RestorePosition(frame, key, defaultFunc)
    local pos = TomoModDB.unitFrames.positions[key]
    frame:ClearAllPoints()

    if pos then
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        defaultFunc()
    end
end

----------------------------------------------------------
-- Events
----------------------------------------------------------
UF.EventFrame = CreateFrame("Frame")

function UF.OnEvent(event, unit)
    if event == "PLAYER_ENTERING_WORLD" then
        UF.UpdatePlayer()
        UF.UpdateTarget()
        UF.UpdateToT()
        return
    end

    if event == "PLAYER_TARGET_CHANGED" then
        UF.UpdateTarget()
        UF.UpdateToT()
        return
    end

    if unit == "player" then
        UF.UpdatePlayer()
    elseif unit == "target" then
        UF.UpdateTarget()
    elseif unit == "targettarget" then
        UF.UpdateToT()
    end
end

----------------------------------------------------------
-- Enable / Disable
----------------------------------------------------------
function UF.Enable()
    local f = UF.EventFrame
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("UNIT_HEALTH")
    f:RegisterEvent("UNIT_MAXHEALTH")
    f:RegisterEvent("UNIT_HEAL_PREDICTION")
    f:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
    f:RegisterEvent("UNIT_FACTION")

    UF.EventFrame:SetScript("OnEvent", function(_, event, unit)
    UF.OnEvent(event, unit)
    end)
end

function UF.Disable()
    UF.EventFrame:UnregisterAllEvents()
end

----------------------------------------------------------
-- Hide BLizzard
----------------------------------------------------------
local function HideBlizzardUnitFrames()
    local frames = {
        PlayerFrame,
        TargetFrame,
        TargetFrameToT,
        FocusFrame,
    }

    for _, frame in pairs(frames) do
        if frame then
            frame:UnregisterAllEvents()
            frame:Hide()
            frame:SetAlpha(0)

            -- Empêche Blizzard de le réafficher
            hooksecurefunc(frame, "Show", function(self)
                self:Hide()
            end)
        end
    end
end

----------------------------------------------------------
-- Initialize
----------------------------------------------------------
function UF.Initialize()
    -- Sécurité DB
    TomoModDB.unitFrames = TomoModDB.unitFrames or {}
    TomoModDB.unitFrames.positions = TomoModDB.unitFrames.positions or {}

    -- Create frames
    PlayerFrameUF = CreateUnitFrame("TomoMod_PlayerFrame", 200, 30)
    TargetFrameUF = CreateUnitFrame("TomoMod_TargetFrame", 200, 30)
    ToTFrameUF = CreateUnitFrame("TomoMod_ToTFrame", 90, 30)

    PlayerFrameUF:SetAttribute("unit", "player")
    TargetFrameUF:SetAttribute("unit", "target")
    ToTFrameUF:SetAttribute("unit", "targettarget")

    -- Positions
    UF.ResetPlayerPosition()
    UF.ResetTargetPosition()
    UF.ResetToTPosition()

    RestorePosition(PlayerFrameUF, "player", UF.ResetPlayerPosition)
    RestorePosition(TargetFrameUF, "target", UF.ResetTargetPosition)
    RestorePosition(ToTFrameUF, "tot", UF.ResetToTPosition)

    -- Apply settings
    UF.UpdatePlayerSettings()
    UF.UpdateTargetSettings()
    UF.UpdateToTSettings()

    UF.Enable()

    -- Hide Blizzard frames (OPTIONNEL)
    if TomoModDB.unitFrames.hideBlizzard then
        HideBlizzardUnitFrames()
    end
end

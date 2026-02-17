-- =====================================
-- Nameplates.lua — Complete Nameplate System
-- Castbar, Auras, Tank Mode, Alpha
-- Visual style inspired by EllesmereNameplates
-- =====================================

TomoMod_Nameplates = TomoMod_Nameplates or {}
local NP = TomoMod_Nameplates

-- =====================================
-- LOCALS
-- =====================================

local activePlates = {} -- [nameplateFrame] = ourPlate
local unitPlates = {}   -- [unitToken] = ourPlate

-- [PERF] Offscreen parent technique (à la Ellesmere): reparent Blizzard elements
-- under a hidden frame so they can NEVER render, regardless of SetAlpha/Show calls
local npOffscreenParent = CreateFrame("Frame")
npOffscreenParent:Hide()
local hookedUFs = {}
local storedParents = {}
local npModuleActive = false  -- global flag to control hooks

local function MoveToOffscreen(element)
    if not element then return end
    if not storedParents[element] then
        storedParents[element] = element:GetParent()
    end
    element:SetParent(npOffscreenParent)
end

local function RestoreFromOffscreen(element)
    if not element then return end
    local origParent = storedParents[element]
    if origParent then
        element:SetParent(origParent)
        storedParents[element] = nil
    end
end

local function HideBlizzardFrame(nameplate, unit)
    if not nameplate then return end
    local uf = nameplate.UnitFrame
    if not uf then return end

    uf:SetAlpha(0)
    -- Move key Blizzard sub-elements to the offscreen parent
    if uf.healthBar then MoveToOffscreen(uf.healthBar) end
    MoveToOffscreen(uf.selectionHighlight)
    MoveToOffscreen(uf.aggroHighlight)
    MoveToOffscreen(uf.softTargetFrame)
    MoveToOffscreen(uf.SoftTargetFrame)
    MoveToOffscreen(uf.ClassificationFrame)
    MoveToOffscreen(uf.RaidTargetFrame)
    if uf.BuffFrame then uf.BuffFrame:SetAlpha(0) end

    -- Hook SetAlpha once per UnitFrame to prevent Blizzard from restoring visibility
    if not hookedUFs[uf] then
        hookedUFs[uf] = true
        local locked = false
        hooksecurefunc(uf, "SetAlpha", function(self)
            if not npModuleActive then return end
            if locked then return end
            locked = true
            self:SetAlpha(0)
            locked = false
        end)
    end
end

local function RestoreBlizzardFrame(nameplate)
    if not nameplate then return end
    local uf = nameplate.UnitFrame
    if not uf then return end
    -- Restore sub-elements to their original parent
    if uf.healthBar then RestoreFromOffscreen(uf.healthBar) end
    RestoreFromOffscreen(uf.selectionHighlight)
    RestoreFromOffscreen(uf.aggroHighlight)
    RestoreFromOffscreen(uf.softTargetFrame)
    RestoreFromOffscreen(uf.SoftTargetFrame)
    RestoreFromOffscreen(uf.ClassificationFrame)
    RestoreFromOffscreen(uf.RaidTargetFrame)
    if uf.BuffFrame then uf.BuffFrame:SetAlpha(1) end
    -- Note: can't unhook SetAlpha, but since elements are restored it's cosmetic
    uf:SetAlpha(1)
end

local UnitName, UnitLevel, UnitEffectiveLevel = UnitName, UnitLevel, UnitEffectiveLevel
local UnitClass, UnitClassification = UnitClass, UnitClassification
local UnitIsPlayer, UnitIsEnemy, UnitIsTapDenied = UnitIsPlayer, UnitIsEnemy, UnitIsTapDenied
local UnitReaction, UnitThreatSituation = UnitReaction, UnitThreatSituation
local UnitAffectingCombat, UnitDetailedThreatSituation = UnitAffectingCombat, UnitDetailedThreatSituation
local UnitGroupRolesAssigned, UnitClassBase = UnitGroupRolesAssigned, UnitClassBase
local GetInstanceInfo = GetInstanceInfo
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitIsDeadOrGhost, UnitIsUnit, UnitCanAttack = UnitIsDeadOrGhost, UnitIsUnit, UnitCanAttack
local GetThreatStatusColor = GetThreatStatusColor
local GetRaidTargetIndex, SetRaidTargetIconTexture = GetRaidTargetIndex, SetRaidTargetIconTexture
local C_NamePlate = C_NamePlate
local GetTime = GetTime

-- Textures — flat bar + Ellesmere-style assets for border/glow/absorb/spark
local FLAT_TEXTURE = "Interface\\Buttons\\WHITE8x8"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local NP_MEDIA = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Nameplates\\"
local BORDER_TEX = NP_MEDIA .. "border.png"
local GLOW_TEX = NP_MEDIA .. "background.png"
local ABSORB_TEX = NP_MEDIA .. "absorb-default.png"
local SPARK_TEX = NP_MEDIA .. "cast_spark.tga"
local SHIELD_TEX = NP_MEDIA .. "shield.png"
local ARROW_LEFT = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\arrow_left"
local ARROW_RIGHT = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\arrow_right"

local BORDER_CORNER = 6
local GLOW_MARGIN = 0.48
local GLOW_CORNER = 12
local GLOW_EXTEND = 6
local HOVER_ALPHA = 0.25

local function DB()
    return TomoModDB and TomoModDB.nameplates or {}
end

-- =====================================
-- BORDER HELPERS (9-slice rounded)
-- =====================================

local function CreateRoundedBorder(plate)
    local bf = CreateFrame("Frame", nil, plate.health)
    bf:SetFrameLevel(plate.health:GetFrameLevel() + 5)
    bf:SetAllPoints()
    plate.borderFrame = bf

    local function Tex()
        local t = bf:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetTexture(BORDER_TEX)
        return t
    end

    plate.borderTL = Tex()
    plate.borderTL:SetSize(BORDER_CORNER, BORDER_CORNER)
    plate.borderTL:SetPoint("TOPLEFT")
    plate.borderTL:SetTexCoord(0, 0.5, 0, 0.5)

    plate.borderTR = Tex()
    plate.borderTR:SetSize(BORDER_CORNER, BORDER_CORNER)
    plate.borderTR:SetPoint("TOPRIGHT")
    plate.borderTR:SetTexCoord(0.5, 1, 0, 0.5)

    plate.borderBL = Tex()
    plate.borderBL:SetSize(BORDER_CORNER, BORDER_CORNER)
    plate.borderBL:SetPoint("BOTTOMLEFT")
    plate.borderBL:SetTexCoord(0, 0.5, 0.5, 1)

    plate.borderBR = Tex()
    plate.borderBR:SetSize(BORDER_CORNER, BORDER_CORNER)
    plate.borderBR:SetPoint("BOTTOMRIGHT")
    plate.borderBR:SetTexCoord(0.5, 1, 0.5, 1)

    plate.borderTop = Tex()
    plate.borderTop:SetHeight(BORDER_CORNER)
    plate.borderTop:SetPoint("TOPLEFT", plate.borderTL, "TOPRIGHT")
    plate.borderTop:SetPoint("TOPRIGHT", plate.borderTR, "TOPLEFT")
    plate.borderTop:SetTexCoord(0.5, 0.5, 0, 0.5)

    plate.borderBottom = Tex()
    plate.borderBottom:SetHeight(BORDER_CORNER)
    plate.borderBottom:SetPoint("BOTTOMLEFT", plate.borderBL, "BOTTOMRIGHT")
    plate.borderBottom:SetPoint("BOTTOMRIGHT", plate.borderBR, "BOTTOMLEFT")
    plate.borderBottom:SetTexCoord(0.5, 0.5, 0.5, 1)

    plate.borderLeft = Tex()
    plate.borderLeft:SetWidth(BORDER_CORNER)
    plate.borderLeft:SetPoint("TOPLEFT", plate.borderTL, "BOTTOMLEFT")
    plate.borderLeft:SetPoint("BOTTOMLEFT", plate.borderBL, "TOPLEFT")
    plate.borderLeft:SetTexCoord(0, 0.5, 0.5, 0.5)

    plate.borderRight = Tex()
    plate.borderRight:SetWidth(BORDER_CORNER)
    plate.borderRight:SetPoint("TOPRIGHT", plate.borderTR, "BOTTOMRIGHT")
    plate.borderRight:SetPoint("BOTTOMRIGHT", plate.borderBR, "TOPRIGHT")
    plate.borderRight:SetTexCoord(0.5, 1, 0.5, 0.5)
end

-- =====================================
-- GLOW (target highlight, ADD blend)
-- =====================================

local function CreateGlowFrame(plate)
    local gf = CreateFrame("Frame", nil, plate)
    gf:SetFrameStrata("BACKGROUND")
    gf:SetFrameLevel(1)
    gf:SetPoint("TOPLEFT", plate.health, "TOPLEFT", -GLOW_EXTEND, GLOW_EXTEND)
    gf:SetPoint("BOTTOMRIGHT", plate.health, "BOTTOMRIGHT", GLOW_EXTEND, -GLOW_EXTEND)
    plate.glowFrame = gf

    local function GTex()
        local t = gf:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(GLOW_TEX)
        t:SetVertexColor(0.41, 0.67, 1.0, 1.0)
        t:SetBlendMode("ADD")
        return t
    end

    local tl = GTex(); tl:SetSize(GLOW_CORNER, GLOW_CORNER); tl:SetPoint("TOPLEFT")
    tl:SetTexCoord(0, GLOW_MARGIN, 0, GLOW_MARGIN)
    local tr = GTex(); tr:SetSize(GLOW_CORNER, GLOW_CORNER); tr:SetPoint("TOPRIGHT")
    tr:SetTexCoord(1-GLOW_MARGIN, 1, 0, GLOW_MARGIN)
    local bl = GTex(); bl:SetSize(GLOW_CORNER, GLOW_CORNER); bl:SetPoint("BOTTOMLEFT")
    bl:SetTexCoord(0, GLOW_MARGIN, 1-GLOW_MARGIN, 1)
    local br = GTex(); br:SetSize(GLOW_CORNER, GLOW_CORNER); br:SetPoint("BOTTOMRIGHT")
    br:SetTexCoord(1-GLOW_MARGIN, 1, 1-GLOW_MARGIN, 1)

    local top = GTex(); top:SetHeight(GLOW_CORNER)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("TOPRIGHT", tr, "TOPLEFT")
    top:SetTexCoord(GLOW_MARGIN, 1-GLOW_MARGIN, 0, GLOW_MARGIN)
    local bot = GTex(); bot:SetHeight(GLOW_CORNER)
    bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT"); bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
    bot:SetTexCoord(GLOW_MARGIN, 1-GLOW_MARGIN, 1-GLOW_MARGIN, 1)
    local lft = GTex(); lft:SetWidth(GLOW_CORNER)
    lft:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); lft:SetPoint("BOTTOMLEFT", bl, "TOPLEFT")
    lft:SetTexCoord(0, GLOW_MARGIN, GLOW_MARGIN, 1-GLOW_MARGIN)
    local rgt = GTex(); rgt:SetWidth(GLOW_CORNER)
    rgt:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT"); rgt:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
    rgt:SetTexCoord(1-GLOW_MARGIN, 1, GLOW_MARGIN, 1-GLOW_MARGIN)

    gf:Hide()
end

-- Simple 1px border for small frames (auras, cast icon)
local function CreatePixelBorder(parent, r, g, b)
    r, g, b = r or 0, g or 0, b or 0
    local function Edge(p1, p2, w, h)
        local t = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(r, g, b, 1)
        t:SetPoint(p1); t:SetPoint(p2)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    Edge("TOPLEFT", "TOPRIGHT", nil, 1)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    Edge("TOPLEFT", "BOTTOMLEFT", 1, nil)
    Edge("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
end

-- =====================================
-- CREATE NAMEPLATE
-- =====================================

local function CreatePlate(baseFrame)
    local settings = DB()
    local font = settings.font or FONT
    local fontSize = settings.fontSize or 10
    local w = settings.width or 156
    local h = settings.height or 17

    local plate = CreateFrame("Frame", nil, baseFrame)
    plate:SetAllPoints(baseFrame)
    plate:SetFrameStrata("BACKGROUND")
    plate:EnableMouse(false)

    -- =========== HEALTH BAR ===========
    plate.health = CreateFrame("StatusBar", nil, plate)
    plate.health:SetFrameLevel(10)
    plate.health:SetSize(w, h)
    plate.health:SetPoint("CENTER", 0, 0)
    plate.health:SetStatusBarTexture(FLAT_TEXTURE)
    plate.health:GetStatusBarTexture():SetHorizTile(false)
    plate.health:SetClipsChildren(true)
    plate.health:SetMinMaxValues(0, 100)
    plate.health:SetValue(100)
    plate.health:EnableMouse(false)

    local bg = plate.health:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.12, 0.12, 0.12, 1.0)
    plate.health.bg = bg

    -- =========== ABSORB BAR ===========
    plate.absorb = CreateFrame("StatusBar", nil, plate.health)
    plate.absorb:SetStatusBarTexture(ABSORB_TEX)
    plate.absorb:GetStatusBarTexture():SetDrawLayer("ARTWORK", 1)
    plate.absorb:SetStatusBarColor(1, 1, 1, 0.8)
    plate.absorb:SetReverseFill(true)
    plate.absorb:SetPoint("TOPRIGHT", plate.health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
    plate.absorb:SetPoint("BOTTOMRIGHT", plate.health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
    plate.absorb:SetWidth(w)
    plate.absorb:SetHeight(h)
    plate.absorb:SetFrameLevel(plate.health:GetFrameLevel())
    plate.absorb:Hide()

    -- Heal prediction calculator (TWW)
    if CreateUnitHealPredictionCalculator then
        plate.hpCalculator = CreateUnitHealPredictionCalculator()
        if plate.hpCalculator.SetMaximumHealthMode then
            plate.hpCalculator:SetMaximumHealthMode(Enum.UnitMaximumHealthMode.WithAbsorbs)
            plate.hpCalculator:SetDamageAbsorbClampMode(Enum.UnitDamageAbsorbClampMode.MaximumHealth)
        end
    end

    -- =========== ROUNDED BORDER (9-slice) ===========
    CreateRoundedBorder(plate)

    -- =========== TARGET GLOW ===========
    CreateGlowFrame(plate)

    -- =========== MOUSEOVER HIGHLIGHT ===========
    plate.highlight = plate.health:CreateTexture(nil, "OVERLAY", nil, 6)
    plate.highlight:SetAllPoints()
    plate.highlight:SetColorTexture(1, 1, 1, HOVER_ALPHA)
    plate.highlight:Hide()

    -- =========== NAME ===========
    local nameFontSize = settings.nameFontSize or 11
    plate.nameText = plate:CreateFontString(nil, "OVERLAY")
    plate.nameText:SetFont(font, nameFontSize, "OUTLINE")
    plate.nameText:SetPoint("BOTTOM", plate.health, "TOP", 0, 4)
    plate.nameText:SetWidth(w - 20)
    plate.nameText:SetWordWrap(false)
    plate.nameText:SetMaxLines(1)
    plate.nameText:SetTextColor(1, 1, 1)

    -- =========== HEALTH TEXT ===========
    plate.hpNumber = plate.health:CreateFontString(nil, "OVERLAY")
    plate.hpNumber:SetFont(font, fontSize + 2, "OUTLINE")
    plate.hpNumber:SetPoint("CENTER", plate.health, "CENTER", 0, 0)
    plate.hpNumber:SetTextColor(1, 1, 1, 1)

    plate.hpPercent = plate.health:CreateFontString(nil, "OVERLAY")
    plate.hpPercent:SetFont(font, fontSize, "OUTLINE")
    plate.hpPercent:SetPoint("RIGHT", plate.health, "RIGHT", -4, 0)
    plate.hpPercent:SetTextColor(1, 1, 1, 0.9)

    plate.healthText = plate.hpNumber

    -- =========== LEVEL ===========
    plate.levelText = plate.health:CreateFontString(nil, "OVERLAY")
    plate.levelText:SetFont(font, fontSize, "OUTLINE")
    plate.levelText:SetPoint("RIGHT", plate.health, "LEFT", -3, 0)

    -- =========== CLASSIFICATION ICON ===========
    plate.classFrame = CreateFrame("Frame", nil, plate)
    plate.classFrame:SetSize(20, 20)
    plate.classFrame:SetPoint("LEFT", plate.health, "LEFT", 2, 0)
    plate.classFrame:SetFrameLevel(plate.health:GetFrameLevel() + 3)
    plate.classFrame:Hide()
    plate.classIcon = plate.classFrame:CreateTexture(nil, "ARTWORK")
    plate.classIcon:SetAllPoints()

    plate.classText = plate.health:CreateFontString(nil, "OVERLAY")
    plate.classText:SetFont(font, fontSize + 2, "OUTLINE")
    plate.classText:SetPoint("LEFT", plate.health, "RIGHT", 3, 0)
    plate.classText:Hide()

    -- =========== THREAT BORDER ===========
    plate.threatFrame = CreateFrame("Frame", nil, plate.health)
    plate.threatFrame:SetPoint("TOPLEFT", -2, 2)
    plate.threatFrame:SetPoint("BOTTOMRIGHT", 2, -2)
    plate.threatFrame:SetFrameLevel(plate.health:GetFrameLevel() + 10)
    plate.threatBorders = {}
    local function ThreatEdge(p1, p2, w2, h2)
        local t = plate.threatFrame:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(1, 0, 0, 1)
        t:SetPoint(p1); t:SetPoint(p2)
        if w2 then t:SetWidth(w2) end
        if h2 then t:SetHeight(h2) end
        table.insert(plate.threatBorders, t)
    end
    ThreatEdge("TOPLEFT", "TOPRIGHT", nil, 2)
    ThreatEdge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 2)
    ThreatEdge("TOPLEFT", "BOTTOMLEFT", 2, nil)
    ThreatEdge("TOPRIGHT", "BOTTOMRIGHT", 2, nil)
    plate.threatFrame:Hide()
    plate.threatFrame:EnableMouse(false)

    -- =========== CASTBAR ===========
    local cbH = settings.castbarHeight or 14
    plate.castbar = CreateFrame("StatusBar", nil, plate)
    plate.castbar:SetSize(w, cbH)
    plate.castbar:SetPoint("TOP", plate.health, "BOTTOM", 0, 0)
    plate.castbar:SetStatusBarTexture(FLAT_TEXTURE)
    plate.castbar:GetStatusBarTexture():SetHorizTile(false)
    plate.castbar:SetMinMaxValues(0, 1)
    plate.castbar:SetValue(0)
    local cbColor = settings.castbarColor or { r = 0.85, g = 0.15, b = 0.15 }
    plate.castbar:SetStatusBarColor(cbColor.r, cbColor.g, cbColor.b, 1)

    local cbBg = plate.castbar:CreateTexture(nil, "BACKGROUND")
    cbBg:SetAllPoints()
    cbBg:SetColorTexture(0.10, 0.10, 0.10, 0.9)
    CreatePixelBorder(plate.castbar)

    plate.castbar.iconFrame = CreateFrame("Frame", nil, plate.castbar)
    plate.castbar.iconFrame:SetSize(cbH, cbH)
    plate.castbar.iconFrame:SetPoint("RIGHT", plate.castbar, "LEFT", 0, 0)
    CreatePixelBorder(plate.castbar.iconFrame)

    plate.castbar.icon = plate.castbar.iconFrame:CreateTexture(nil, "ARTWORK")
    plate.castbar.icon:SetPoint("TOPLEFT", 1, -1)
    plate.castbar.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    plate.castbar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    plate.castbar.spark = plate.castbar:CreateTexture(nil, "OVERLAY", nil, 1)
    plate.castbar.spark:SetTexture(SPARK_TEX)
    plate.castbar.spark:SetSize(8, cbH)
    plate.castbar.spark:SetPoint("CENTER", plate.castbar:GetStatusBarTexture(), "RIGHT", 0, 0)
    plate.castbar.spark:SetBlendMode("ADD")

    local shieldHeight = cbH * 0.75
    local shieldWidth = shieldHeight * (29 / 35)
    plate.castbar.shieldFrame = CreateFrame("Frame", nil, plate.castbar)
    plate.castbar.shieldFrame:SetSize(shieldWidth, shieldHeight)
    plate.castbar.shieldFrame:SetPoint("CENTER", plate.castbar, "LEFT", 0, 0)
    plate.castbar.shieldFrame:SetFrameLevel(plate.castbar.iconFrame:GetFrameLevel() + 5)
    plate.castbar.shieldFrame:Hide()
    plate.castbar.shield = plate.castbar.shieldFrame:CreateTexture(nil, "OVERLAY")
    plate.castbar.shield:SetAllPoints()
    plate.castbar.shield:SetTexture(SHIELD_TEX)

    plate.castbar.text = plate.castbar:CreateFontString(nil, "OVERLAY")
    plate.castbar.text:SetFont(font, math.max(8, cbH - 4), "OUTLINE")
    plate.castbar.text:SetPoint("LEFT", plate.castbar, 5, 0)
    plate.castbar.text:SetJustifyH("LEFT")
    plate.castbar.text:SetWidth(w * 0.55)
    plate.castbar.text:SetWordWrap(false)
    plate.castbar.text:SetMaxLines(1)
    plate.castbar.text:SetTextColor(1, 1, 1)

    plate.castbar.timer = plate.castbar:CreateFontString(nil, "OVERLAY")
    plate.castbar.timer:SetFont(font, math.max(8, cbH - 4), "OUTLINE")
    plate.castbar.timer:SetPoint("RIGHT", plate.castbar, -3, 0)
    plate.castbar.timer:SetTextColor(1, 1, 1, 0.8)

    local cbStatusTex = plate.castbar:GetStatusBarTexture()
    plate.castbar.niOverlay = plate.castbar:CreateTexture(nil, "ARTWORK", nil, 1)
    plate.castbar.niOverlay:SetPoint("TOPLEFT", cbStatusTex, "TOPLEFT", 0, 0)
    plate.castbar.niOverlay:SetPoint("BOTTOMRIGHT", cbStatusTex, "BOTTOMRIGHT", 0, 0)
    local niColor = settings.castbarUninterruptible or { r = 0.45, g = 0.45, b = 0.45 }
    plate.castbar.niOverlay:SetColorTexture(niColor.r, niColor.g, niColor.b, 1)
    plate.castbar.niOverlay:SetAlpha(0)
    plate.castbar.niOverlay:Show()

    plate.castbar:Hide()
    plate.castbar:EnableMouse(false)

    plate.castbar.casting = false
    plate.castbar.channeling = false
    plate.castbar.empowered = false
    plate.castbar.numStages = 0
    plate.castbar.duration_obj = nil
    plate.castbar.failstart = nil

    -- Empower stage markers (vertical lines for Evoker casts)
    plate.castbar.stageMarkers = {}
    for i = 1, 4 do
        local marker = plate.castbar:CreateTexture(nil, "OVERLAY", nil, 2)
        marker:SetWidth(2)
        marker:SetPoint("TOP", plate.castbar, "TOP", 0, 0)
        marker:SetPoint("BOTTOM", plate.castbar, "BOTTOM", 0, 0)
        marker:SetColorTexture(1, 1, 1, 0.7)
        marker:Hide()
        plate.castbar.stageMarkers[i] = marker
    end

    plate.castbar:SetScript("OnUpdate", function(self, elapsed)
        if self.failstart then
            if GetTime() - self.failstart > 1 then
                self.failstart = nil
                self:Hide()
            end
            return
        end
        if not self.casting and not self.channeling and not self.empowered then
            self:Hide()
            return
        end
        self:SetValue(GetTime() * 1000, Enum.StatusBarInterpolation.ExponentialEaseOut)
        if self.timer and self.duration_obj then
            self.timer:SetText(string.format("%.1f", self.duration_obj:GetRemainingDuration(0)))
        end
    end)

    -- =========== DEBUFFS (centered above name) ===========
    plate.auras = {}
    local maxAuras = settings.maxAuras or 5
    local auraSize = settings.auraSize or 24
    for i = 1, maxAuras do
        local aura = CreateFrame("Frame", nil, plate)
        aura:SetSize(auraSize, auraSize - 4)
        aura:EnableMouse(false)
        aura:SetPoint("BOTTOM", plate.nameText, "TOP", (i - (maxAuras + 1) / 2) * (auraSize + 2), 2)

        aura.icon = aura:CreateTexture(nil, "ARTWORK")
        aura.icon:SetPoint("TOPLEFT", 1, -1)
        aura.icon:SetPoint("BOTTOMRIGHT", -1, 1)
        local cropPercent = 2 / auraSize
        aura.icon:SetTexCoord(0.08, 0.92, 0.08 + cropPercent, 0.92 - cropPercent)

        aura.cooldown = CreateFrame("Cooldown", nil, aura, "CooldownFrameTemplate")
        aura.cooldown:SetAllPoints(aura.icon)
        aura.cooldown:SetDrawEdge(false)
        aura.cooldown:SetReverse(true)
        aura.cooldown:SetHideCountdownNumbers(true)
        aura.cooldown:EnableMouse(false)

        aura.count = aura:CreateFontString(nil, "OVERLAY")
        aura.count:SetFont(font, 9, "OUTLINE")
        aura.count:SetPoint("BOTTOMRIGHT", 1, 1)
        aura.count:SetJustifyH("RIGHT")

        aura.duration = aura:CreateFontString(nil, "OVERLAY")
        aura.duration:SetFont(font, 9, "OUTLINE")
        aura.duration:SetPoint("TOPLEFT", aura, "TOPLEFT", -3, 4)
        aura.duration:SetJustifyH("LEFT")
        aura.duration:SetTextColor(1, 1, 0, 1)

        CreatePixelBorder(aura)
        aura:Hide()
        plate.auras[i] = aura
    end

    -- =========== ENEMY BUFFS (left of health bar) ===========
    plate.enemyBuffs = {}
    local maxEnemyBuffs = settings.maxEnemyBuffs or 4
    local enemyBuffSize = settings.enemyBuffSize or 22
    for i = 1, maxEnemyBuffs do
        local buff = CreateFrame("Frame", nil, plate)
        buff:SetSize(enemyBuffSize, enemyBuffSize)
        buff:EnableMouse(false)
        if i == 1 then
            buff:SetPoint("RIGHT", plate.health, "LEFT", -2, 0)
        else
            buff:SetPoint("RIGHT", plate.enemyBuffs[i - 1], "LEFT", -2, 0)
        end

        buff.icon = buff:CreateTexture(nil, "ARTWORK")
        buff.icon:SetPoint("TOPLEFT", 1, -1)
        buff.icon:SetPoint("BOTTOMRIGHT", -1, 1)
        buff.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        buff.cooldown = CreateFrame("Cooldown", nil, buff, "CooldownFrameTemplate")
        buff.cooldown:SetAllPoints(buff.icon)
        buff.cooldown:SetDrawEdge(false)
        buff.cooldown:SetReverse(true)
        buff.cooldown:SetHideCountdownNumbers(true)
        buff.cooldown:EnableMouse(false)

        buff.count = buff:CreateFontString(nil, "OVERLAY")
        buff.count:SetFont(font, 8, "OUTLINE")
        buff.count:SetPoint("BOTTOMRIGHT", 2, -2)

        buff.duration = buff:CreateFontString(nil, "OVERLAY")
        buff.duration:SetFont(font, 8, "OUTLINE")
        buff.duration:SetPoint("TOP", buff, "BOTTOM", 0, -1)
        buff.duration:SetTextColor(1, 1, 0.6, 1)

        CreatePixelBorder(buff, 0.11, 0.82, 0.11)
        buff:Hide()
        plate.enemyBuffs[i] = buff
    end

    -- =========== TARGET ARROWS ===========
    local arrowSize = h + 6
    plate.targetArrowLeft = plate:CreateTexture(nil, "OVERLAY")
    plate.targetArrowLeft:SetTexture(ARROW_LEFT)
    plate.targetArrowLeft:SetSize(arrowSize * 0.6, arrowSize)
    plate.targetArrowLeft:SetPoint("RIGHT", plate.nameText, "LEFT", -2, 0)
    plate.targetArrowLeft:SetVertexColor(1, 1, 1, 0.9)
    plate.targetArrowLeft:Hide()

    plate.targetArrowRight = plate:CreateTexture(nil, "OVERLAY")
    plate.targetArrowRight:SetTexture(ARROW_RIGHT)
    plate.targetArrowRight:SetSize(arrowSize * 0.6, arrowSize)
    plate.targetArrowRight:SetPoint("LEFT", plate.nameText, "RIGHT", 2, 0)
    plate.targetArrowRight:SetVertexColor(1, 1, 1, 0.9)
    plate.targetArrowRight:Hide()

    -- =========== QUEST ICON ===========
    plate.questIcon = plate:CreateTexture(nil, "OVERLAY")
    plate.questIcon:SetAtlas("SmallQuestBang")
    plate.questIcon:SetSize(14, 14)
    plate.questIcon:SetPoint("RIGHT", plate.nameText, "LEFT", -1, 0)
    plate.questIcon:Hide()

    -- =========== RAID MARKER ===========
    plate.raidFrame = CreateFrame("Frame", nil, plate)
    plate.raidFrame:SetSize(24, 24)
    plate.raidFrame:SetPoint("BOTTOMRIGHT", plate.health, "TOPRIGHT", 2, 2)
    plate.raidFrame:Hide()
    plate.raidIcon = plate.raidFrame:CreateTexture(nil, "ARTWORK")
    plate.raidIcon:SetPoint("TOPLEFT", 1, -1)
    plate.raidIcon:SetPoint("BOTTOMRIGHT", -1, 1)
    plate.raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")

    return plate
end

-- =====================================
-- UPDATE FUNCTIONS
-- =====================================

local function UpdateSize(plate)
    local s = DB()
    local w = s.width or 156
    local h = s.height or 17
    plate.health:SetSize(w, h)

    plate.absorb:SetWidth(w)
    plate.absorb:SetHeight(h)

    local cbH = s.castbarHeight or 14
    plate.castbar:SetSize(w, cbH)
    plate.castbar.iconFrame:SetSize(cbH, cbH)
    plate.castbar.spark:SetSize(8, cbH)
    local shieldHeight = cbH * 0.75
    local shieldWidth = shieldHeight * (29 / 35)
    plate.castbar.shieldFrame:SetSize(shieldWidth, shieldHeight)

    -- Refresh castbar colors from DB
    local cc = s.castbarColor or { r = 0.85, g = 0.15, b = 0.15 }
    plate.castbar:SetStatusBarColor(cc.r, cc.g, cc.b, 1)
    local niC = s.castbarUninterruptible or { r = 0.45, g = 0.45, b = 0.45 }
    plate.castbar.niOverlay:SetColorTexture(niC.r, niC.g, niC.b, 1)

    if plate.nameText then
        local font = s.font or FONT
        plate.nameText:SetFont(font, s.nameFontSize or 11, s.fontOutline or "OUTLINE")
        plate.nameText:SetWidth(w - 20)
    end

    if plate.targetArrowLeft then
        local arrowSize = h + 6
        plate.targetArrowLeft:SetSize(arrowSize * 0.6, arrowSize)
        plate.targetArrowRight:SetSize(arrowSize * 0.6, arrowSize)
    end

    if plate.auras then
        local auraSize = s.auraSize or 24
        local maxAuras = s.maxAuras or 5
        for i, aura in ipairs(plate.auras) do
            aura:SetSize(auraSize, auraSize - 4)
            aura:ClearAllPoints()
            aura:SetPoint("BOTTOM", plate.nameText, "TOP", (i - (maxAuras + 1) / 2) * (auraSize + 2), 2)
        end
    end

    if plate.enemyBuffs then
        local enemyBuffSize = s.enemyBuffSize or 22
        for i, buff in ipairs(plate.enemyBuffs) do
            buff:SetSize(enemyBuffSize, enemyBuffSize)
            buff:ClearAllPoints()
            if i == 1 then
                buff:SetPoint("RIGHT", plate.health, "LEFT", -2, 0)
            else
                buff:SetPoint("RIGHT", plate.enemyBuffs[i - 1], "LEFT", -2, 0)
            end
        end
    end
end

-- Darken a color (Ellesmere-style: out-of-combat mobs appear dimmed)
local function DarkenColor(r, g, b, factor)
    factor = factor or 0.60
    return r * factor, g * factor, b * factor
end

-- Check if player is in real instanced content (dungeon/raid)
local function InRealInstancedContent()
    local _, instanceType, difficultyID = GetInstanceInfo()
    difficultyID = tonumber(difficultyID) or 0
    if difficultyID == 0 then return false end
    if C_Garrison and C_Garrison.IsOnGarrisonMap and C_Garrison.IsOnGarrisonMap() then return false end
    if instanceType == "party" or instanceType == "raid" then return true end
    return false
end

local function GetHealthColor(unit)
    local s = DB()

    -- 1) Tapped (tagged by another player)
    if UnitIsTapDenied(unit) then
        local c = s.colors.tapped; return c.r, c.g, c.b
    end

    -- 2) Neutral
    local reaction = UnitReaction(unit, "player")
    if reaction and reaction == 4 then
        local c = s.colors.neutral; return c.r, c.g, c.b
    end
    if UnitCanAttack("player", unit) and not UnitIsEnemy(unit, "player") then
        local c = s.colors.neutral; return c.r, c.g, c.b
    end

    -- 3) Friendly
    if reaction and reaction >= 5 then
        local c = s.colors.friendly; return c.r, c.g, c.b
    end

    -- 4) Focus target
    if s.colors.focus and UnitIsUnit(unit, "focus") then
        local c = s.colors.focus; return c.r, c.g, c.b
    end

    -- 5) Enemy players: class color
    if UnitIsPlayer(unit) and UnitCanAttack("player", unit) then
        if s.useClassColors then
            local _, class = UnitClass(unit)
            if class and RAID_CLASS_COLORS[class] then
                local c = RAID_CLASS_COLORS[class]
                return c.r, c.g, c.b
            end
        end
    end

    -- From here: hostile NPCs
    local inCombat = UnitAffectingCombat(unit)

    -- 6) Miniboss: elite/worldboss with higher level than player
    if s.useClassificationColors then
        local classification = UnitClassification(unit)
        if classification == "elite" or classification == "worldboss" or classification == "rareelite" then
            local level = UnitLevel(unit)
            local playerLevel = UnitLevel("player")
            -- level == -1 means skull (boss-level); level comparison is safe if both are real numbers
            local isMiniboss = false
            if type(level) == "number" and type(playerLevel) == "number" then
                isMiniboss = (level == -1) or (level >= playerLevel + 1)
            elseif classification == "worldboss" then
                isMiniboss = true
            end
            if isMiniboss and s.colors.miniboss then
                local c = s.colors.miniboss
                if type(inCombat) == "boolean" and inCombat then
                    return c.r, c.g, c.b
                else
                    return DarkenColor(c.r, c.g, c.b)
                end
            end
        end
    end

    -- 7) Caster NPC: UnitClassBase returns "PALADIN" for caster mobs in WoW
    if s.colors.caster then
        local unitClass = UnitClassBase and UnitClassBase(unit)
        if unitClass == "PALADIN" then
            local c = s.colors.caster
            if type(inCombat) == "boolean" and inCombat then
                return c.r, c.g, c.b
            else
                return DarkenColor(c.r, c.g, c.b)
            end
        end
    end

    -- 8) Tank/DPS threat coloring (instanced content)
    if s.tankMode and InRealInstancedContent() then
        local isTanking, status = UnitDetailedThreatSituation("player", unit)
        if status then
            local role = UnitGroupRolesAssigned("player")
            local isTankRole = (role == "TANK")
            if isTankRole then
                if isTanking then
                    local c = s.tankColors.hasThreat; return c.r, c.g, c.b
                elseif status >= 2 then
                    local c = s.tankColors.lowThreat; return c.r, c.g, c.b
                else
                    local c = s.tankColors.noThreat; return c.r, c.g, c.b
                end
            else
                -- DPS/Healer threat
                if isTanking then
                    local c = s.tankColors.dpsHasAggro or s.tankColors.noThreat; return c.r, c.g, c.b
                elseif status >= 2 then
                    local c = s.tankColors.dpsNearAggro or s.tankColors.lowThreat; return c.r, c.g, c.b
                end
            end
        end
    end

    -- 9) Default enemy: in-combat vs out-of-combat dimming
    local c = s.colors.enemyInCombat or s.colors.normal or s.colors.hostile
    if type(inCombat) == "boolean" and inCombat then
        return c.r, c.g, c.b
    else
        return DarkenColor(c.r, c.g, c.b)
    end
end

-- =====================================
-- HEALTH TEXT (TWW secret-safe)
-- =====================================

local function UpdateHealthText(plate, unit)
    if not plate or not unit then return end
    local s = DB()

    if UnitIsDead(unit) then
        plate.hpNumber:SetText("Dead"); plate.hpPercent:SetText(""); return
    elseif UnitIsGhost(unit) then
        plate.hpNumber:SetText("Ghost"); plate.hpPercent:SetText(""); return
    elseif not UnitIsConnected(unit) then
        plate.hpNumber:SetText("Offline"); plate.hpPercent:SetText(""); return
    end

    local fmt = s.healthTextFormat or "current_percent"
    local ScaleTo100 = CurveConstants and CurveConstants.ScaleTo100

    if s.showHealthText then
        if fmt == "percent" then
            plate.hpNumber:SetFormattedText("%d%%", UnitHealthPercent(unit, true, ScaleTo100))
            plate.hpNumber:Show()
            plate.hpPercent:Hide()
        elseif fmt == "current" then
            plate.hpNumber:SetFormattedText("%s", AbbreviateLargeNumbers(UnitHealth(unit)))
            plate.hpNumber:Show()
            plate.hpPercent:Hide()
        else
            plate.hpNumber:SetFormattedText("%s", AbbreviateLargeNumbers(UnitHealth(unit)))
            plate.hpNumber:Show()
            plate.hpPercent:SetFormattedText("%d%%", UnitHealthPercent(unit, true, ScaleTo100))
            plate.hpPercent:Show()
        end
    else
        plate.hpNumber:Hide()
        plate.hpPercent:Hide()
    end
end

-- =====================================
-- ABSORB UPDATE (TWW-safe)
-- =====================================

local function UpdateAbsorb(plate, unit)
    if not plate.absorb then return end
    local s = DB()
    if not s.showAbsorb then plate.absorb:Hide(); return end

    -- Use hpCalculator only for absorb overlay, not for health bar
    if plate.hpCalculator and plate.hpCalculator.GetMaximumHealth then
        UnitGetDetailedHealPrediction(unit, nil, plate.hpCalculator)
        plate.hpCalculator:SetMaximumHealthMode(Enum.UnitMaximumHealthMode.WithAbsorbs)
        local maxHealth = UnitHealthMax(unit)
        plate.absorb:SetMinMaxValues(0, maxHealth)
        local absorbs = plate.hpCalculator:GetDamageAbsorbs()
        plate.absorb:SetValue(absorbs)
        plate.absorb:ClearAllPoints()
        plate.absorb:SetPoint("TOPRIGHT", plate.health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        plate.absorb:SetPoint("BOTTOMRIGHT", plate.health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
        plate.absorb:Show()
    else
        local maxHealth = UnitHealthMax(unit)
        local totalAbsorb = UnitGetTotalAbsorbs(unit)
        plate.absorb:SetMinMaxValues(0, maxHealth)
        plate.absorb:SetValue(totalAbsorb)
        plate.absorb:ClearAllPoints()
        plate.absorb:SetPoint("TOPRIGHT", plate.health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        plate.absorb:SetPoint("BOTTOMRIGHT", plate.health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
        -- No Lua comparison on secret values — bar is visually empty at 0
        plate.absorb:Show()
    end
end

-- =====================================
-- QUEST ICON DETECTION
-- =====================================

local questScanTip = CreateFrame("GameTooltip", "TomoModNPQuestScanTip", nil, "GameTooltipTemplate")
questScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

local questIconCache = {} -- [guid] = { isQuest = bool, time = GetTime() }
local QUEST_CACHE_TTL = 2 -- seconds

local function IsQuestUnit(unit)
    if not unit then return false end
    if UnitIsPlayer(unit) then return false end

    local guid = UnitGUID(unit)
    if not guid then return false end

    -- Check cache
    local cached = questIconCache[guid]
    if cached and (GetTime() - cached.time) < QUEST_CACHE_TTL then
        return cached.isQuest
    end

    -- Scan tooltip for quest objectives
    questScanTip:ClearLines()
    questScanTip:SetUnit(unit)

    local isQuest = false
    local playerName = UnitName("player")

    for i = 2, questScanTip:NumLines() do
        local left = _G["TomoModNPQuestScanTipTextLeft" .. i]
        if left then
            local text = left:GetText()
            if text then
                -- Quest objective lines often have progress like "0/1", "2/5" or percentage
                if text:match("%d+/%d+") or text:match("%d+%%") then
                    isQuest = true
                    break
                end
                -- Check for player name (indicates our quest)
                if text == playerName then
                    isQuest = true
                    break
                end
            end

            -- Check text color: quest title lines are typically yellow-ish
            local r, g, b = left:GetTextColor()
            if r and r > 0.9 and g > 0.8 and b < 0.2 and text and text ~= "" then
                -- This could be a quest title
                isQuest = true
            end
        end
    end

    -- Cache result
    questIconCache[guid] = { isQuest = isQuest, time = GetTime() }
    return isQuest
end

local function UpdateQuestIcon(plate, unit)
    if not plate.questIcon then return end

    local s = DB()
    if not s.showQuestIcon then
        plate.questIcon:Hide()
        return
    end

    -- Only check for hostile/neutral NPCs
    if UnitIsPlayer(unit) or UnitIsFriend("player", unit) then
        plate.questIcon:Hide()
        return
    end

    -- Skip in instances
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "arena" or instanceType == "pvp") then
        plate.questIcon:Hide()
        return
    end

    if IsQuestUnit(unit) then
        plate.questIcon:Show()
    else
        plate.questIcon:Hide()
    end
end

-- Periodic cache cleanup
C_Timer.NewTicker(10, function()
    local now = GetTime()
    for guid, data in pairs(questIconCache) do
        if (now - data.time) > 30 then
            questIconCache[guid] = nil
        end
    end
end)

-- Clear quest cache when quest log changes
local questEventFrame = CreateFrame("Frame")
questEventFrame:RegisterEvent("QUEST_LOG_UPDATE")
questEventFrame:RegisterEvent("QUEST_ACCEPTED")
questEventFrame:RegisterEvent("QUEST_REMOVED")
questEventFrame:RegisterEvent("QUEST_TURNED_IN")
questEventFrame:SetScript("OnEvent", function()
    wipe(questIconCache)
end)

-- =====================================
-- MAIN PLATE UPDATE
-- =====================================

local function UpdatePlate(plate, unit)
    if not plate or not unit then return end
    local s = DB()

    -- Always update health directly — hpCalculator is only used for absorb overlay
    local hp = UnitHealth(unit)
    local hpMax = UnitHealthMax(unit)
    plate.health:SetMinMaxValues(0, hpMax)
    plate.health:SetValue(hp)

    local r, g, b = GetHealthColor(unit)
    plate.health:SetStatusBarColor(r, g, b, 1)

    UpdateHealthText(plate, unit)
    UpdateAbsorb(plate, unit)

    -- Name (UnitName returns a secret string in TWW — use C-side SetFormattedText)
    if s.showName then
        local name = UnitName(unit)
        if name then
            plate.nameText:SetFormattedText("%s", name)
        else
            plate.nameText:SetText("")
        end
        plate.nameText:Show()
    else
        plate.nameText:Hide()
    end

    -- Quest Icon
    UpdateQuestIcon(plate, unit)

    -- Level (UnitEffectiveLevel returns a secret number in TWW)
    if s.showLevel then
        local level = UnitEffectiveLevel(unit)
        local classification = UnitClassification(unit)
        -- Use C-side SetFormattedText — no tostring/comparison on secret numbers
        if classification == "worldboss" then
            plate.levelText:SetText("Boss")
        elseif classification == "rareelite" then
            plate.levelText:SetFormattedText("%dR+", level)
        elseif classification == "rare" then
            plate.levelText:SetFormattedText("%dR", level)
        elseif classification == "elite" then
            plate.levelText:SetFormattedText("%d+", level)
        else
            plate.levelText:SetFormattedText("%d", level)
        end
        -- GetQuestDifficultyColor needs a real number; use safe default
        local safeLevel = type(level) == "number" and level or -1
        local color = GetQuestDifficultyColor(safeLevel)
        plate.levelText:SetTextColor(color.r, color.g, color.b)
        plate.levelText:Show()
    else
        plate.levelText:Hide()
    end

    -- Classification (atlas icons like Ellesmere)
    if s.showClassification then
        local cls = UnitClassification(unit)
        if cls == "elite" or cls == "worldboss" then
            plate.classIcon:SetAtlas("nameplates-icon-elite-gold")
            plate.classFrame:Show(); plate.classText:Hide()
        elseif cls == "rareelite" then
            plate.classIcon:SetAtlas("nameplates-icon-elite-silver")
            plate.classFrame:Show(); plate.classText:Hide()
        elseif cls == "rare" then
            plate.classIcon:SetAtlas("nameplates-icon-star")
            plate.classFrame:Show(); plate.classText:Hide()
        else
            plate.classFrame:Hide(); plate.classText:Hide()
        end
    else
        plate.classFrame:Hide(); plate.classText:Hide()
    end

    -- Raid marker
    if plate.raidIcon then
        local index = GetRaidTargetIndex(unit)
        if index then
            SetRaidTargetIconTexture(plate.raidIcon, index)
            plate.raidFrame:Show()
        else
            plate.raidFrame:Hide()
        end
    end

    -- Threat
    if s.showThreat and UnitIsEnemy("player", unit) then
        local status = UnitThreatSituation("player", unit)
        if status and status >= 2 then
            local tr, tg, tb = GetThreatStatusColor(status)
            for _, border in ipairs(plate.threatBorders) do
                border:SetVertexColor(tr, tg, tb, 1)
            end
            plate.threatFrame:Show()
        else
            plate.threatFrame:Hide()
        end
    else
        plate.threatFrame:Hide()
    end

    -- Alpha + glow + arrows
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if nameplate then
        local isTarget = UnitIsUnit(unit, "target")
        nameplate:SetAlpha(isTarget and (s.selectedAlpha or 1) or (s.unselectedAlpha or 0.8))

        if plate.glowFrame then
            if isTarget then plate.glowFrame:Show() else plate.glowFrame:Hide() end
        end
        if plate.targetArrowLeft and plate.targetArrowRight then
            if isTarget then
                plate.targetArrowLeft:Show(); plate.targetArrowRight:Show()
            else
                plate.targetArrowLeft:Hide(); plate.targetArrowRight:Hide()
            end
        end
    end

    -- Auras
    if s.showAuras then
        local auraIndex = 0
        local maxAuras = s.maxAuras or 5
        local auraFilter = "HARMFUL"
        if s.showOnlyMyAuras then auraFilter = "HARMFUL|PLAYER" end

        local results = {C_UnitAuras.GetAuraSlots(unit, auraFilter)}
        local slotIdx = 2
        while results[slotIdx] do
            if auraIndex >= maxAuras then break end
            local data = C_UnitAuras.GetAuraDataBySlot(unit, results[slotIdx])
            if data then
                auraIndex = auraIndex + 1
                local auraFrame = plate.auras[auraIndex]
                if auraFrame then
                    auraFrame.icon:SetTexture(data.icon)
                    local durObj = C_UnitAuras.GetAuraDuration(unit, data.auraInstanceID)
                    auraFrame._auraUnit = unit
                    auraFrame._auraInstanceID = data.auraInstanceID
                    if durObj then
                        auraFrame.cooldown:Hide()
                        if auraFrame.duration then
                            auraFrame.duration:SetText(string.format("%.0f", durObj:GetRemainingDuration()))
                            auraFrame.duration:Show()
                        end
                    else
                        auraFrame.cooldown:Hide()
                        if auraFrame.duration then auraFrame.duration:Hide() end
                    end
                    local stackStr = C_UnitAuras.GetAuraApplicationDisplayCount(unit, data.auraInstanceID, 2, 1000)
                    auraFrame.count:SetText(stackStr or "")
                    auraFrame.count:Show()
                    auraFrame:Show()
                end
            end
            slotIdx = slotIdx + 1
        end
        for i = auraIndex + 1, maxAuras do
            if plate.auras[i] then plate.auras[i]:Hide() end
        end
    else
        for _, a in ipairs(plate.auras) do a:Hide() end
    end

    -- Enemy Buffs
    if s.showEnemyBuffs and plate.enemyBuffs and UnitCanAttack("player", unit) then
        local buffIndex = 0
        local maxEnemyBuffs = s.maxEnemyBuffs or 4
        for _, b in ipairs(plate.enemyBuffs) do b:Hide() end

        local function processBuffSlots(token, ...)
            for i = 1, select("#", ...) do
                if buffIndex >= maxEnemyBuffs then return end
                local slot = select(i, ...)
                if not slot then return end
                local data = C_UnitAuras.GetAuraDataBySlot(unit, slot)
                if data then
                    buffIndex = buffIndex + 1
                    local buffFrame = plate.enemyBuffs[buffIndex]
                    if buffFrame then
                        buffFrame.icon:SetTexture(data.icon)
                        local durObj = C_UnitAuras.GetAuraDuration(unit, data.auraInstanceID)
                        buffFrame._auraUnit = unit
                        buffFrame._auraInstanceID = data.auraInstanceID
                        if durObj then
                            buffFrame.cooldown:Hide()
                            if buffFrame.duration then
                                buffFrame.duration:SetText(string.format("%.0f", durObj:GetRemainingDuration()))
                                buffFrame.duration:Show()
                            end
                        else
                            buffFrame.cooldown:Hide()
                            if buffFrame.duration then buffFrame.duration:Hide() end
                        end
                        local stackStr = C_UnitAuras.GetAuraApplicationDisplayCount(unit, data.auraInstanceID, 2, 1000)
                        buffFrame.count:SetText(stackStr or "")
                        buffFrame:Show()
                    end
                end
            end
        end
        processBuffSlots(C_UnitAuras.GetAuraSlots(unit, "HELPFUL"))
    elseif plate.enemyBuffs then
        for _, b in ipairs(plate.enemyBuffs) do b:Hide() end
    end
end

-- =====================================
-- CASTBAR HELPERS
-- =====================================

local function HideNPStageMarkers(castbar)
    if castbar.stageMarkers then
        for i = 1, 4 do castbar.stageMarkers[i]:Hide() end
    end
end

local function UpdateNPStageMarkers(castbar, unit, numStages, startMS, endMS)
    HideNPStageMarkers(castbar)
    if numStages <= 0 then return end

    local barWidth = castbar:GetWidth()
    pcall(function()
        local totalDuration = endMS - startMS
        if totalDuration <= 0 then return end

        local cumulative = 0
        for stage = 0, numStages - 1 do
            local stageDuration = GetUnitEmpowerStageDuration(unit, stage)
            if not stageDuration or stageDuration <= 0 then break end
            cumulative = cumulative + stageDuration

            if stage < numStages - 1 then
                local pct = cumulative / totalDuration
                local xPos = barWidth * pct
                local marker = castbar.stageMarkers[stage + 1]
                if marker then
                    marker:ClearAllPoints()
                    marker:SetPoint("TOP", castbar, "TOPLEFT", xPos, 0)
                    marker:SetPoint("BOTTOM", castbar, "BOTTOMLEFT", xPos, 0)
                    marker:Show()
                end
            end
        end
    end)
end

local function ResetNPCastbar(castbar)
    castbar.casting = false
    castbar.channeling = false
    castbar.empowered = false
    castbar.numStages = 0
    castbar.duration_obj = nil
    HideNPStageMarkers(castbar)
end

local function UpdateCastbar(plate, unit)
    if not plate or not plate.castbar then return end
    local s = DB()
    if not s.showCastbar then plate.castbar:Hide(); return end
    plate.castbar.unit = unit

    if plate.castbar.failstart then return end

    local name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible

    -- Check regular cast
    name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible = UnitCastingInfo(unit)
    if type(name) ~= "nil" then
        plate.castbar.casting = true
        plate.castbar.channeling = false
        plate.castbar.empowered = false
        plate.castbar.numStages = 0
        plate.castbar.duration_obj = UnitCastingDuration(unit)
        plate.castbar:SetMinMaxValues(startTimeMS, endTimeMS)
        plate.castbar:SetReverseFill(false)
        local cc = s.castbarColor or { r = 0.85, g = 0.15, b = 0.15 }
        plate.castbar:SetStatusBarColor(cc.r, cc.g, cc.b, 1)
        plate.castbar.text:SetFormattedText("%s", name)
        plate.castbar.icon:SetTexture(texture)
        local alpha = C_CurveUtil.EvaluateColorValueFromBoolean(notInterruptible, 1, 0)
        plate.castbar.niOverlay:SetAlpha(alpha)
        if plate.castbar.shieldFrame then
            plate.castbar.shieldFrame:SetAlpha(alpha)
            plate.castbar.shieldFrame:Show()
        end
        HideNPStageMarkers(plate.castbar)
        plate.castbar:Show()
        return
    end

    -- Check channel / empowered
    -- UnitChannelInfo returns: name, displayName, texture, startTimeMS, endTimeMS,
    --   isTradeSkill, notInterruptible, spellID, _, numEmpowerStages
    local chanNI, chanStages
    local chanName, _, chanTex, chanStart, chanEnd, _, cNI, _, _, cStages = UnitChannelInfo(unit)
    if type(chanName) ~= "nil" then
        local bempowered = (cStages and cStages > 0)

        plate.castbar.casting = false
        plate.castbar.channeling = not bempowered
        plate.castbar.empowered = bempowered
        plate.castbar.numStages = bempowered and cStages or 0
        plate.castbar.duration_obj = UnitChannelDuration(unit)
        plate.castbar:SetMinMaxValues(chanStart, chanEnd)
        -- Channels fill right-to-left, empowered fill left-to-right
        plate.castbar:SetReverseFill(not bempowered)
        local cc = s.castbarColor or { r = 0.85, g = 0.15, b = 0.15 }
        plate.castbar:SetStatusBarColor(cc.r, cc.g, cc.b, 1)
        plate.castbar.text:SetFormattedText("%s", chanName)
        plate.castbar.icon:SetTexture(chanTex)
        local alpha = C_CurveUtil.EvaluateColorValueFromBoolean(cNI, 1, 0)
        plate.castbar.niOverlay:SetAlpha(alpha)
        if plate.castbar.shieldFrame then
            plate.castbar.shieldFrame:SetAlpha(alpha)
            plate.castbar.shieldFrame:Show()
        end

        -- Empower stage markers
        if bempowered then
            UpdateNPStageMarkers(plate.castbar, unit, cStages, chanStart, chanEnd)
        else
            HideNPStageMarkers(plate.castbar)
        end

        plate.castbar:Show()
        return
    end

    plate.castbar:Hide()
    ResetNPCastbar(plate.castbar)
    if plate.castbar.shieldFrame then plate.castbar.shieldFrame:Hide() end
end

-- =====================================
-- EVENT HANDLING
-- =====================================

local eventFrame = CreateFrame("Frame")

local function OnNamePlateAdded(unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end

    if not activePlates[nameplate] then
        activePlates[nameplate] = CreatePlate(nameplate)
    end

    local plate = activePlates[nameplate]
    plate.unit = unit
    plate._blizzUnitFrame = nameplate.UnitFrame
    unitPlates[unit] = plate

    -- [PERF] Hide Blizzard frame using offscreen parent technique
    HideBlizzardFrame(nameplate, unit)

    UpdateSize(plate)
    UpdatePlate(plate, unit)
    UpdateCastbar(plate, unit)
    plate:Show()
end

local function OnNamePlateRemoved(unit)
    local plate = unitPlates[unit]
    if plate then
        plate:Hide()
        ResetNPCastbar(plate.castbar)
        plate.castbar:Hide()
        if plate.castbar.shieldFrame then plate.castbar.shieldFrame:Hide() end
        if plate.glowFrame then plate.glowFrame:Hide() end
        plate.highlight:Hide()
        plate.absorb:Hide()
        for _, a in ipairs(plate.auras) do a:Hide() end
        if plate.enemyBuffs then
            for _, b in ipairs(plate.enemyBuffs) do b:Hide() end
        end
        unitPlates[unit] = nil
    end
end

local npUnitEventFrames = {}
local npUnitEvents = {
    "UNIT_HEALTH", "UNIT_MAXHEALTH",
    "UNIT_THREAT_SITUATION_UPDATE",
    "UNIT_FACTION", "UNIT_AURA",
    "UNIT_ABSORB_AMOUNT_CHANGED",
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP",
    "UNIT_SPELLCAST_CHANNEL_UPDATE",
    "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
    "UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_SPELLCAST_EMPOWER_START", "UNIT_SPELLCAST_EMPOWER_STOP",
    "UNIT_SPELLCAST_EMPOWER_UPDATE",
}

-- [PERF] Dirty-flag batch system: coalesce multiple events per unit into one update per frame
local dirtyPlates = {}
local dirtyCastbars = {}
local dirtyBatchFrame = CreateFrame("Frame")
dirtyBatchFrame:Hide()
dirtyBatchFrame:SetScript("OnUpdate", function(self)
    self:Hide()
    for unit in pairs(dirtyPlates) do
        local p = unitPlates[unit]
        if p then
            UpdatePlate(p, unit)
        end
    end
    wipe(dirtyPlates)
    for unit in pairs(dirtyCastbars) do
        local p = unitPlates[unit]
        if p then
            UpdateCastbar(p, unit)
        end
    end
    wipe(dirtyCastbars)
end)

local function HandleNPUnitEvent(event, unit)
    if not unitPlates[unit] then return end

    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_THREAT_SITUATION_UPDATE"
        or event == "UNIT_FACTION" or event == "UNIT_AURA"
        or event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        -- [PERF] Mark dirty instead of creating a timer+closure per event
        dirtyPlates[unit] = true
        dirtyBatchFrame:Show()
    elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        dirtyCastbars[unit] = true
        dirtyBatchFrame:Show()
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START"
        or event == "UNIT_SPELLCAST_EMPOWER_START" then
        dirtyCastbars[unit] = true
        dirtyBatchFrame:Show()
    elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" or event == "UNIT_SPELLCAST_EMPOWER_UPDATE" then
        dirtyCastbars[unit] = true
        dirtyBatchFrame:Show()
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        local p = unitPlates[unit]
        if p and p.castbar then
            p.castbar.niOverlay:SetAlpha(0)
            p.castbar:SetStatusBarColor(0.1, 0.8, 0.1, 1)
            p.castbar.text:SetFormattedText("%s", INTERRUPTED or "Interrompu")
            ResetNPCastbar(p.castbar)
            p.castbar.failstart = GetTime()
            p.castbar:SetMinMaxValues(0, 100)
            p.castbar:SetValue(100)
            if p.castbar.shieldFrame then p.castbar.shieldFrame:Hide() end
            p.castbar:Show()
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- Some spells fire SUCCEEDED then immediately start a channel/empower.
        -- Re-check via UpdateCastbar to avoid killing a newly started cast (race condition).
        local p = unitPlates[unit]
        if p and p.castbar then
            if p.castbar.channeling or p.castbar.empowered then
                return
            end
            UpdateCastbar(p, unit)
        end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED"
        or event == "UNIT_SPELLCAST_CHANNEL_STOP"
        or event == "UNIT_SPELLCAST_EMPOWER_STOP" then
        -- Re-check via UpdateCastbar: if a new cast already started, show it instead of hiding.
        -- This prevents the race where STOP(old) arrives after START(new).
        local p = unitPlates[unit]
        if p and p.castbar then
            if not p.castbar.failstart then
                UpdateCastbar(p, unit)
            end
        end
    end
end

local function RegisterNPUnitEvents(unit)
    if npUnitEventFrames[unit] then return end
    local uef = CreateFrame("Frame")
    for _, ev in ipairs(npUnitEvents) do
        uef:RegisterUnitEvent(ev, unit)
    end
    uef:SetScript("OnEvent", function(_, event, u)
        HandleNPUnitEvent(event, u)
    end)
    npUnitEventFrames[unit] = uef
end

local function UnregisterNPUnitEvents(unit)
    if npUnitEventFrames[unit] then
        npUnitEventFrames[unit]:UnregisterAllEvents()
        npUnitEventFrames[unit]:SetScript("OnEvent", nil)
        npUnitEventFrames[unit] = nil
    end
end

-- NOTE: Events are NOT registered here at file scope.
-- All event registration happens in NP.Enable() to prevent
-- plates being created before the module is initialized.

eventFrame:SetScript("OnEvent", function(self, event, unit)
    if not npModuleActive then return end  -- safety guard
    if event == "NAME_PLATE_UNIT_ADDED" then
        OnNamePlateAdded(unit)
        RegisterNPUnitEvents(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        UnregisterNPUnitEvents(unit)
        OnNamePlateRemoved(unit)
    elseif event == "PLAYER_TARGET_CHANGED" then
        C_Timer.After(0, function()
            local s = DB()
            for u, p in pairs(unitPlates) do
                local np = C_NamePlate.GetNamePlateForUnit(u)
                if np then
                    local isTarget = UnitIsUnit(u, "target")
                    np:SetAlpha(isTarget and (s.selectedAlpha or 1) or (s.unselectedAlpha or 0.8))
                    if p.glowFrame then
                        if isTarget then p.glowFrame:Show() else p.glowFrame:Hide() end
                    end
                    if p.targetArrowLeft and p.targetArrowRight then
                        if isTarget then
                            p.targetArrowLeft:Show(); p.targetArrowRight:Show()
                        else
                            p.targetArrowLeft:Hide(); p.targetArrowRight:Hide()
                        end
                    end
                end
            end
        end)
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        for u, p in pairs(unitPlates) do
            if p.highlight then
                if UnitExists("mouseover") and UnitIsUnit(u, "mouseover") then
                    p.highlight:Show()
                else
                    p.highlight:Hide()
                end
            end
        end
    elseif event == "RAID_TARGET_UPDATE" then
        for u, p in pairs(unitPlates) do
            if p.raidIcon then
                local index = GetRaidTargetIndex(u)
                if index then
                    SetRaidTargetIconTexture(p.raidIcon, index)
                    p.raidFrame:Show()
                else
                    p.raidFrame:Hide()
                end
            end
        end
    end
end)

-- =====================================
-- PUBLIC API
-- =====================================

function NP.Initialize()
    if not DB().enabled then
        NP.Disable()
        return
    end
    NP.Enable()
end

function NP.Enable()
    npModuleActive = true
    if TomoModDB and TomoModDB.nameplates then
        TomoModDB.nameplates.enabled = true
    end

    local s = DB()
    NP._savedCVars = {
        nameplateOverlapV = GetCVar("nameplateOverlapV"),
        nameplateOtherTopInset = GetCVar("nameplateOtherTopInset"),
        nameplateOtherBottomInset = GetCVar("nameplateOtherBottomInset"),
    }
    SetCVar("nameplateOverlapV", s.overlapV or 1.05)
    SetCVar("nameplateOtherTopInset", s.topInset or 0.065)
    SetCVar("nameplateOtherBottomInset", 0.1)

    eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    eventFrame:RegisterEvent("RAID_TARGET_UPDATE")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    NP.RefreshAll()

    if not NP._auraTicker then
        -- [PERF] 0.25s instead of 0.1s, skip invisible plates, use C-side SetFormattedText
        NP._auraTicker = C_Timer.NewTicker(0.25, function()
            for u, p in pairs(unitPlates) do
                if p:IsVisible() then
                    if p.auras then
                        for _, aura in ipairs(p.auras) do
                            if aura:IsShown() and aura.duration and aura._auraUnit and aura._auraInstanceID then
                                local durObj = C_UnitAuras.GetAuraDuration(aura._auraUnit, aura._auraInstanceID)
                                if durObj then
                                    aura.duration:SetFormattedText("%.0f", durObj:GetRemainingDuration())
                                end
                            end
                        end
                    end
                    if p.enemyBuffs then
                        for _, buff in ipairs(p.enemyBuffs) do
                            if buff:IsShown() and buff.duration and buff._auraUnit and buff._auraInstanceID then
                                local durObj = C_UnitAuras.GetAuraDuration(buff._auraUnit, buff._auraInstanceID)
                                if durObj then
                                    buff.duration:SetFormattedText("%.0f", durObj:GetRemainingDuration())
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    print("|cff0cd29fTomoMod NP:|r " .. TomoMod_L["msg_np_enabled"])
end

function NP.Disable()
    npModuleActive = false
    eventFrame:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
    eventFrame:UnregisterEvent("RAID_TARGET_UPDATE")
    eventFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")

    if NP._auraTicker then
        NP._auraTicker:Cancel()
        NP._auraTicker = nil
    end

    if NP._savedCVars then
        for k, v in pairs(NP._savedCVars) do
            if v then SetCVar(k, v) end
        end
        NP._savedCVars = nil
    end

    for nameplate, plate in pairs(activePlates) do
        plate:Hide()
        -- Restore Blizzard elements from offscreen parent
        RestoreBlizzardFrame(nameplate)
    end
    for unit, uef in pairs(npUnitEventFrames) do
        uef:UnregisterAllEvents()
        uef:SetScript("OnEvent", nil)
    end
    npUnitEventFrames = {}
    unitPlates = {}
end

function NP.RefreshAll()
    for unit, plate in pairs(unitPlates) do
        UpdateSize(plate)
        UpdatePlate(plate, unit)
        UpdateCastbar(plate, unit)
    end
end

function NP.ApplySettings()
    local s = DB()
    SetCVar("nameplateOverlapV", s.overlapV or 1.05)
    SetCVar("nameplateOtherTopInset", s.topInset or 0.065)
    NP.RefreshAll()
end

TomoMod_RegisterModule("nameplates", NP)

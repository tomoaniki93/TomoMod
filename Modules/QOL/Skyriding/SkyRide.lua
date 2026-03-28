-- =====================================
-- TomoMod_SkyRide.lua
-- Module de barre Skyriding — v2.3.1+
-- Deux rangées : Vigor (6 charges) + Second Souffle (3 charges)
-- =====================================

TomoMod_SkyRide = TomoMod_SkyRide or {}
local SR = TomoMod_SkyRide

-- =====================================
-- CONSTANTES
-- =====================================
-- Vigor : IDs testés par ordre jusqu'au premier qui retourne des charges
-- 404966 = Skyriding passive TWW, 425782 = Skyward Ascent, 404963 = Surge Forward
-- IDs confirmés TWW
-- Vigor (6 charges) : Accélération 372608 / Ascension 372610 — même pool partagé
local VIGOR_SPELL_IDS = { 372608, 372610 }
-- Second Souffle (3 charges) : 425782
local WIND_SPELL_IDS  = { 425782 }
local SPEED_MULTIPLIER     = 14.285
local SPEED_MAX            = 1100
local VIGOR_MAX_SEGMENTS   = 6
local _vigorSpellID        = nil   -- détecté dynamiquement au premier tick
local _windSpellID         = nil   -- idem pour Second Souffle
local WIND_MAX_SEGMENTS    = 3

-- Palette TomoMod
local C = {
    teal     = { r = 0.047, g = 0.824, b = 0.624 },
    tealDim  = { r = 0.031, g = 0.549, b = 0.416 },
    wind     = { r = 0.35,  g = 0.65,  b = 0.95  },  -- bleu ciel pour Second Souffle
    windDim  = { r = 0.18,  g = 0.38,  b = 0.58  },
    bgDark   = { r = 0.06,  g = 0.06,  b = 0.09,  a = 0.88 },
    bgCharge = { r = 0.10,  g = 0.10,  b = 0.13,  a = 1    },
    text     = { r = 0.95,  g = 0.95,  b = 0.97  },
    border   = { r = 0.20,  g = 0.20,  b = 0.24,  a = 0.9  },
}

local BAR_TEXTURE = "Interface\\Buttons\\WHITE8X8"

-- =====================================
-- VARIABLES MODULE
-- =====================================
local frame
local speedBar
local vigorSegments  = {}
local vigorTimers    = {}
local windSegments   = {}   -- Second Souffle
local windTimers     = {}
local isLocked       = true
local updateTicker

local PREVIEW_CHARGES = 4
local PREVIEW_SPEED   = 580
local PREVIEW_WIND    = 2

-- =====================================
-- UTILITAIRES
-- =====================================
local function GetSettings()
    return TomoModDB and TomoModDB.skyRide
end

local function SavePosition()
    local s = GetSettings(); if not s then return end
    local point, _, rp, x, y = frame:GetPoint()
    s.position = { point = point or "BOTTOM", relativePoint = rp or "CENTER", x = x or 0, y = y or -180 }
    print("|cff00ff00TomoMod:|r " .. TomoMod_L["msg_sr_pos_saved"])
end

local function ApplyPosition()
    local s = GetSettings(); if not s then return end
    local p = s.position
    frame:ClearAllPoints()
    frame:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
end

local function UpdateVisibility()
    local s = GetSettings()
    if not s or not s.enabled then frame:Hide(); return end
    if not isLocked then frame:Show(); return end
    if IsFlying("player") then frame:Show() else frame:Hide() end
end

-- =====================================
-- LOCK / UNLOCK
-- =====================================
local dragOverlay, dragLabel

local function SetLocked(locked)
    isLocked = locked
    if locked then
        frame:EnableMouse(false)
        if dragOverlay then dragOverlay:Hide() end
        if dragLabel   then dragLabel:Hide()   end
        UpdateVisibility()
    else
        frame:EnableMouse(true)
        if dragOverlay then dragOverlay:Show() end
        if dragLabel   then dragLabel:Show()   end
        frame:Show()
    end
end

function SR.SetLocked(locked)
    SetLocked(locked)
    local msg = locked and TomoMod_L["msg_sr_locked"] or TomoMod_L["msg_sr_unlock"]
    print((locked and "|cff00ff00" or "|cffffff00") .. "TomoMod:|r " .. msg)
end

function SR.ToggleLock() SetLocked(not isLocked); return isLocked end
function SR.IsLocked()   return isLocked end

-- =====================================
-- LAYOUT
-- =====================================
local function AddBorder(parent)
    local function Edge(anchorA, offAx, offAy, anchorB, offBx, offBy)
        local t = parent:CreateTexture(nil, "BORDER")
        t:SetColorTexture(C.border.r, C.border.g, C.border.b, C.border.a)
        t:SetPoint(anchorA, parent, anchorA, offAx, offAy)
        t:SetPoint(anchorB, parent, anchorB, offBx, offBy)
        return t
    end
    local top = Edge("TOPLEFT",    0,  1, "TOPRIGHT",    0,  1); top:SetHeight(1)
    local bot = Edge("BOTTOMLEFT", 0, -1, "BOTTOMRIGHT", 0, -1); bot:SetHeight(1)
    local lft = Edge("TOPLEFT",   -1,  1, "BOTTOMLEFT", -1, -1); lft:SetWidth(1)
    local rgt = Edge("TOPRIGHT",   1,  1, "BOTTOMRIGHT", 1, -1); rgt:SetWidth(1)
end

local function RelayoutUI()
    local s = GetSettings()
    if not s or not frame then return end

    local W       = s.width
    local speedH  = s.height
    local chargeH = s.comboHeight
    local windH   = s.windHeight or chargeH   -- hauteur rangée Second Souffle
    local gap     = s.chargeGap
    -- Layout (bas → haut) : vitesse / gap / vigor / gap / second souffle
    local totalH  = speedH + gap + chargeH + gap + windH

    frame:SetSize(W, totalH)

    -- ── Barre vitesse (bas) ───────────────────────────────────────
    speedBar:ClearAllPoints()
    speedBar:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  0, 0)
    speedBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    speedBar:SetHeight(speedH)

    if speedBar.speedText then
        speedBar.speedText:SetFont(
            s.font or STANDARD_TEXT_FONT,
            s.fontSize or 11,
            s.fontOutline or "OUTLINE"
        )
    end

    -- ── Segments Vigor (milieu) ───────────────────────────────────
    local numVig = VIGOR_MAX_SEGMENTS
    local vigW   = (W - (gap * (numVig - 1))) / numVig

    for i = 1, numVig do
        local seg = vigorSegments[i]
        seg:SetHeight(chargeH)
        seg:SetWidth(vigW)
        seg:ClearAllPoints()
        if i == 1 then
            seg:SetPoint("BOTTOMLEFT", speedBar, "TOPLEFT", 0, gap)
        else
            seg:SetPoint("LEFT", vigorSegments[i - 1], "RIGHT", gap, 0)
        end
        if vigorTimers[i] then
            vigorTimers[i]:SetFont(
                s.font or STANDARD_TEXT_FONT,
                s.chargeFontSize or 10,
                s.fontOutline or "OUTLINE"
            )
        end
    end

    -- ── Segments Second Souffle (haut) ────────────────────────────
    local numWind = WIND_MAX_SEGMENTS
    local windW   = (W - (gap * (numWind - 1))) / numWind

    for i = 1, numWind do
        local seg = windSegments[i]
        seg:SetHeight(windH)
        seg:SetWidth(windW)
        seg:ClearAllPoints()
        if i == 1 then
            seg:SetPoint("BOTTOMLEFT", vigorSegments[1], "TOPLEFT", 0, gap)
        else
            seg:SetPoint("LEFT", windSegments[i - 1], "RIGHT", gap, 0)
        end
        if windTimers[i] then
            windTimers[i]:SetFont(
                s.font or STANDARD_TEXT_FONT,
                s.chargeFontSize or 10,
                s.fontOutline or "OUTLINE"
            )
        end
    end

    -- Labels positionnés au-dessus de chaque rangée (côté droit, petits)
    if frame.vigorLabel then
        frame.vigorLabel:ClearAllPoints()
        frame.vigorLabel:SetPoint("BOTTOMRIGHT", vigorSegments[VIGOR_MAX_SEGMENTS], "TOPRIGHT", 0, 1)
    end
    if frame.windLabel then
        frame.windLabel:ClearAllPoints()
        frame.windLabel:SetPoint("BOTTOMRIGHT", windSegments[WIND_MAX_SEGMENTS], "TOPRIGHT", 0, 1)
    end

    ApplyPosition()
end

-- =====================================
-- UPDATE VIGOR (6 charges)
-- =====================================
local function UpdateVigorSegments(preview)
    local s = GetSettings()
    if not s then return end

    if preview then
        for i = 1, VIGOR_MAX_SEGMENTS do
            local seg   = vigorSegments[i]
            local timer = vigorTimers[i]
            seg:SetMinMaxValues(0, 1)
            if i <= PREVIEW_CHARGES then
                seg:SetStatusBarColor(C.teal.r, C.teal.g, C.teal.b)
                seg:SetValue(1)
                if timer then timer:Hide() end
            elseif i == PREVIEW_CHARGES + 1 then
                seg:SetStatusBarColor(C.tealDim.r, C.tealDim.g, C.tealDim.b)
                seg:SetValue(0.55)
                if timer and s.showChargeTimer then timer:SetText("3"); timer:Show()
                elseif timer then timer:Hide() end
            else
                seg:SetStatusBarColor(0, 0, 0)
                seg:SetValue(0)
                if timer then timer:Hide() end
            end
        end
        return
    end

    -- Détection dynamique du bon spell ID pour le vigor
    local info
    if _vigorSpellID then
        info = C_Spell.GetSpellCharges(_vigorSpellID)
        if not info then _vigorSpellID = nil end  -- ID devenu invalide
    end
    if not info then
        for _, spellID in ipairs(VIGOR_SPELL_IDS) do
            local try = C_Spell.GetSpellCharges(spellID)
            if try and try.maxCharges and try.maxCharges >= 1 then
                _vigorSpellID = spellID
                info = try
                break
            end
        end
    end
    if not info then return end

    local charges    = info.currentCharges
    local maxCharges = math.min(info.maxCharges or VIGOR_MAX_SEGMENTS, VIGOR_MAX_SEGMENTS)
    local now        = GetTime()
    local rechargeProgress, rechargeRemaining = 0, 0

    if charges < maxCharges and info.cooldownDuration and info.cooldownDuration > 0 then
        local elapsed      = now - info.cooldownStartTime
        rechargeProgress   = math.min(elapsed / info.cooldownDuration, 1)
        rechargeRemaining  = math.max(0, info.cooldownDuration - elapsed)
    end

    for i = 1, VIGOR_MAX_SEGMENTS do
        local seg   = vigorSegments[i]
        local timer = vigorTimers[i]
        seg:SetMinMaxValues(0, 1)

        if i <= charges then
            seg:SetStatusBarColor(C.teal.r, C.teal.g, C.teal.b)
            seg:SetValue(1)
            if timer then timer:Hide() end
        elseif i == charges + 1 and charges < maxCharges then
            seg:SetStatusBarColor(C.tealDim.r, C.tealDim.g, C.tealDim.b)
            seg:SetValue(rechargeProgress)
            if timer and s.showChargeTimer then
                local secs = math.ceil(rechargeRemaining)
                timer:SetText(secs > 0 and tostring(secs) or "")
                timer:Show()
            elseif timer then timer:Hide() end
        else
            seg:SetStatusBarColor(0, 0, 0)
            seg:SetValue(0)
            if timer then timer:Hide() end
        end
    end
end

-- =====================================
-- UPDATE SECOND SOUFFLE (3 charges)
-- =====================================
local function UpdateWindSegments(preview)
    local s = GetSettings()
    if not s then return end

    if preview then
        for i = 1, WIND_MAX_SEGMENTS do
            local seg   = windSegments[i]
            local timer = windTimers[i]
            seg:SetMinMaxValues(0, 1)
            if i <= PREVIEW_WIND then
                seg:SetStatusBarColor(C.wind.r, C.wind.g, C.wind.b)
                seg:SetValue(1)
                if timer then timer:Hide() end
            else
                seg:SetStatusBarColor(C.windDim.r, C.windDim.g, C.windDim.b)
                seg:SetValue(0.35)
                if timer and s.showChargeTimer then timer:SetText("6"); timer:Show()
                elseif timer then timer:Hide() end
            end
        end
        return
    end

    -- Détection dynamique du bon spell ID pour Second Souffle
    local info
    if _windSpellID then
        info = C_Spell.GetSpellCharges(_windSpellID)
        if not info then _windSpellID = nil end
    end
    if not info then
        for _, spellID in ipairs(WIND_SPELL_IDS) do
            local try = C_Spell.GetSpellCharges(spellID)
            if try and try.maxCharges and try.maxCharges >= 1 then
                _windSpellID = spellID
                info = try
                break
            end
        end
    end
    if not info then
        -- Sort non trouvé/appris → cacher la rangée
        for i = 1, WIND_MAX_SEGMENTS do
            windSegments[i]:SetStatusBarColor(0, 0, 0)
            windSegments[i]:SetValue(0)
            if windTimers[i] then windTimers[i]:Hide() end
        end
        return
    end

    local charges    = info.currentCharges
    local maxCharges = math.min(info.maxCharges, WIND_MAX_SEGMENTS)
    local now        = GetTime()
    local rechargeProgress, rechargeRemaining = 0, 0

    if charges < maxCharges and info.cooldownDuration and info.cooldownDuration > 0 then
        local elapsed      = now - info.cooldownStartTime
        rechargeProgress   = math.min(elapsed / info.cooldownDuration, 1)
        rechargeRemaining  = math.max(0, info.cooldownDuration - elapsed)
    end

    for i = 1, WIND_MAX_SEGMENTS do
        local seg   = windSegments[i]
        local timer = windTimers[i]
        seg:SetMinMaxValues(0, 1)

        if i <= charges then
            seg:SetStatusBarColor(C.wind.r, C.wind.g, C.wind.b)
            seg:SetValue(1)
            if timer then timer:Hide() end
        elseif i == charges + 1 and charges < maxCharges then
            seg:SetStatusBarColor(C.windDim.r, C.windDim.g, C.windDim.b)
            seg:SetValue(rechargeProgress)
            if timer and s.showChargeTimer then
                local secs = math.ceil(rechargeRemaining)
                timer:SetText(secs > 0 and tostring(secs) or "")
                timer:Show()
            elseif timer then timer:Hide() end
        else
            seg:SetStatusBarColor(0, 0, 0)
            seg:SetValue(0)
            if timer then timer:Hide() end
        end
    end
end

-- =====================================
-- UPDATE VITESSE
-- =====================================
local function UpdateSpeed()
    local s = GetSettings()
    if not s or not s.enabled then frame:Hide(); return end

    if not IsFlying("player") then
        if not isLocked then
            speedBar:SetMinMaxValues(0, SPEED_MAX)
            speedBar:SetValue(PREVIEW_SPEED)
            if speedBar.speedText and s.showSpeedText then
                speedBar.speedText:SetText(PREVIEW_SPEED .. "%")
                speedBar.speedText:Show()
            end
        else
            frame:Hide()
        end
        return
    end

    frame:Show()

    local isGliding, _, forwardSpeed = C_PlayerInfo.GetGlidingInfo()
    local moveSpeed = 0
    if isGliding and forwardSpeed and forwardSpeed > 0 then
        moveSpeed = math.floor(forwardSpeed * SPEED_MULTIPLIER + 0.5)
    else
        local speed = GetUnitSpeed("player")
        moveSpeed   = math.floor(speed / 7 * 100 + 0.5)
    end
    moveSpeed = math.max(0, math.min(moveSpeed, SPEED_MAX))

    speedBar:SetMinMaxValues(0, SPEED_MAX)
    speedBar:SetValue(moveSpeed, Enum.StatusBarInterpolation.ExponentialEaseOut)

    -- [PERF] Cache speed text — skip SetText when value unchanged (avoids string concat + font update)
    if speedBar.speedText then
        if s.showSpeedText and moveSpeed > 0 then
            if moveSpeed ~= speedBar._lastSpeed then
                speedBar._lastSpeed = moveSpeed
                speedBar.speedText:SetText(moveSpeed .. "%")
            end
            speedBar.speedText:Show()
        else
            speedBar._lastSpeed = nil
            speedBar.speedText:Hide()
        end
    end
end

-- =====================================
-- TICK
-- =====================================
-- [PERF] Early-exit when not flying + locked: ticker stays alive (cheap IsFlying check)
-- but skips all heavy work (UpdateSpeed, UpdateVigor, UpdateWind).
-- No self-cancel — IsFlying() is not true yet when mount events fire, so
-- event-driven restart was unreliable.
local _srWasFlying = false
local function OnTick()
    local flying = IsFlying("player")
    local inPreview = not isLocked and not flying
    -- [PERF] Skip all heavy work when grounded + locked (single API call per tick)
    -- Hide the frame once on the flying→grounded transition
    if not flying and isLocked then
        if _srWasFlying then
            _srWasFlying = false
            frame:Hide()
        end
        return
    end
    _srWasFlying = flying
    UpdateSpeed()
    UpdateVigorSegments(inPreview)
    UpdateWindSegments(inPreview)
end

-- =====================================
-- CRÉATION UI
-- =====================================
local function CreateUI()
    local s = GetSettings()
    if not s then return end

    frame = CreateFrame("Frame", "TomoModSkyRideFrame", UIParent)
    frame:SetFrameLevel(9600)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    frame:SetScript("OnMouseDown", function(self, btn)
        if not isLocked and btn == "LeftButton" then self:StartMoving() end
    end)
    frame:SetScript("OnMouseUp", function(self, btn)
        if not isLocked and btn == "LeftButton" then
            self:StopMovingOrSizing()
            SavePosition()
        end
    end)

    dragOverlay = frame:CreateTexture(nil, "OVERLAY")
    dragOverlay:SetAllPoints()
    dragOverlay:SetColorTexture(1, 1, 1, 0.06)
    dragOverlay:Hide()

    dragLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dragLabel:SetPoint("CENTER")
    dragLabel:SetTextColor(C.teal.r, C.teal.g, C.teal.b)
    dragLabel:SetText("SKYRIDE\n|cffaaaaaa(Cliquez et glissez)")
    dragLabel:Hide()

    -- ── Barre de vitesse ─────────────────────────────────────────
    speedBar = CreateFrame("StatusBar", nil, frame)
    speedBar:SetStatusBarTexture(BAR_TEXTURE)
    speedBar:GetStatusBarTexture():SetHorizTile(false)
    speedBar:SetMinMaxValues(0, SPEED_MAX)
    speedBar:SetValue(0)
    speedBar:SetStatusBarColor(C.teal.r, C.teal.g, C.teal.b)
    speedBar:EnableMouse(false)
    speedBar:SetFrameLevel(9601)

    speedBar.bg = speedBar:CreateTexture(nil, "BACKGROUND")
    speedBar.bg:SetAllPoints()
    speedBar.bg:SetColorTexture(C.bgDark.r, C.bgDark.g, C.bgDark.b, C.bgDark.a)
    AddBorder(speedBar)

    speedBar.speedText = speedBar:CreateFontString(nil, "ARTWORK")
    speedBar.speedText:SetPoint("LEFT", speedBar, "LEFT", 5, 0)
    speedBar.speedText:SetTextColor(C.text.r, C.text.g, C.text.b)
    speedBar.speedText:Hide()

    -- ── Segments Vigor (milieu — teal) ───────────────────────────
    for i = 1, VIGOR_MAX_SEGMENTS do
        local seg = CreateFrame("StatusBar", nil, frame)
        seg:SetStatusBarTexture(BAR_TEXTURE)
        seg:GetStatusBarTexture():SetHorizTile(false)
        seg:SetFrameLevel(9601)
        seg:SetMinMaxValues(0, 1)
        seg:SetValue(0)
        seg:EnableMouse(false)

        seg.bg = seg:CreateTexture(nil, "BACKGROUND")
        seg.bg:SetAllPoints()
        seg.bg:SetColorTexture(C.bgCharge.r, C.bgCharge.g, C.bgCharge.b, C.bgCharge.a)
        AddBorder(seg)
        vigorSegments[i] = seg

        local timer = seg:CreateFontString(nil, "OVERLAY")
        timer:SetPoint("CENTER", seg, "CENTER", 0, 0)
        timer:SetTextColor(C.text.r, C.text.g, C.text.b)
        timer:SetDrawLayer("OVERLAY", 7)
        timer:Hide()
        vigorTimers[i] = timer
    end

    -- ── Segments Second Souffle (haut — bleu ciel) ───────────────
    for i = 1, WIND_MAX_SEGMENTS do
        local seg = CreateFrame("StatusBar", nil, frame)
        seg:SetStatusBarTexture(BAR_TEXTURE)
        seg:GetStatusBarTexture():SetHorizTile(false)
        seg:SetFrameLevel(9601)
        seg:SetMinMaxValues(0, 1)
        seg:SetValue(0)
        seg:EnableMouse(false)

        seg.bg = seg:CreateTexture(nil, "BACKGROUND")
        seg.bg:SetAllPoints()
        seg.bg:SetColorTexture(C.bgCharge.r, C.bgCharge.g, C.bgCharge.b, C.bgCharge.a)
        AddBorder(seg)
        windSegments[i] = seg

        local timer = seg:CreateFontString(nil, "OVERLAY")
        timer:SetPoint("CENTER", seg, "CENTER", 0, 0)
        timer:SetTextColor(C.text.r, C.text.g, C.text.b)
        timer:SetDrawLayer("OVERLAY", 7)
        timer:Hide()
        windTimers[i] = timer
    end

    -- ── Labels de rangée ─────────────────────────────────────────
    frame.vigorLabel = frame:CreateFontString(nil, "OVERLAY")
    frame.vigorLabel:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
    frame.vigorLabel:SetTextColor(C.teal.r, C.teal.g, C.teal.b, 0.70)
    --frame.vigorLabel:SetText("VIGOR")

    frame.windLabel = frame:CreateFontString(nil, "OVERLAY")
    frame.windLabel:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
    frame.windLabel:SetTextColor(C.wind.r, C.wind.g, C.wind.b, 0.70)
    --frame.windLabel:SetText("2ND SOUFFLE")

    RelayoutUI()
    SetLocked(true)
    UpdateVisibility()
end

-- =====================================
-- API PUBLIQUE
-- =====================================
function SR.ApplySettings()
    local s = GetSettings()
    if not s or not frame then return end
    RelayoutUI()
    UpdateVisibility()
end

function SR.ResetPosition()
    local s = GetSettings(); if not s then return end
    s.position = { point = "BOTTOM", relativePoint = "CENTER", x = 0, y = -180 }
    ApplyPosition()
    print("|cff00ff00TomoMod:|r " .. TomoMod_L["msg_sr_pos_reset"])
end

function SR.SetEnabled(enabled)
    local s = GetSettings(); if not s then return end
    s.enabled = enabled
    if not enabled then
        if updateTicker then updateTicker:Cancel(); updateTicker = nil end
    else
        if not updateTicker then
            updateTicker = C_Timer.NewTicker(0.25, OnTick)
        end
    end
    UpdateVisibility()
end

-- =====================================
-- INIT
-- =====================================
function SR.Initialize()
    if not TomoModDB then
        print("|cffff0000TomoMod SkyRide:|r " .. TomoMod_L["msg_sr_db_not_init"])
        return
    end

    if not TomoModDB.skyRide then TomoModDB.skyRide = {} end
    local db = TomoModDB.skyRide

    if db.enabled         == nil then db.enabled         = false        end
    if db.width           == nil then db.width           = 340          end
    if db.height          == nil then db.height          = 18           end
    if db.comboHeight     == nil then db.comboHeight     = 10           end
    if db.windHeight      == nil then db.windHeight      = 8            end  -- Second Souffle légèrement plus fin
    if db.chargeGap       == nil then db.chargeGap       = 2            end
    if db.fontSize        == nil then db.fontSize        = 11           end
    if db.chargeFontSize  == nil then db.chargeFontSize  = 10           end
    if db.fontOutline     == nil then db.fontOutline     = "OUTLINE"    end
    if db.showSpeedText   == nil then db.showSpeedText   = true         end
    if db.showChargeTimer == nil then db.showChargeTimer = true         end
    if not db.position then
        db.position = { point = "BOTTOM", relativePoint = "CENTER", x = 0, y = -180 }
    end

    db.barColor = nil
    db.font     = db.font or STANDARD_TEXT_FONT

    CreateUI()

    if db.enabled then
        updateTicker = C_Timer.NewTicker(0.25, OnTick)
    end

    print("|cff00ff00TomoMod SkyRide:|r " .. TomoMod_L["msg_sr_initialized"])
end

_G.TomoMod_SkyRide = SR

-- =====================================
-- Castbar.lua — Standalone Castbars for TomoMod
-- Supports: Player, Target, Focus, Pet, Boss (1-5)
-- Casts, Channels, Empowered (Evoker)
-- =====================================

TomoMod_Castbar = TomoMod_Castbar or {}
local CB = TomoMod_Castbar
local SA = TomoMod_CastbarSpark

-- =====================================
-- UPVALUES
-- =====================================
local GetTime           = GetTime
local math_max          = math.max
local math_min          = math.min
local math_floor        = math.floor
local math_sin          = math.sin
local string_format     = string.format
local UnitCastingInfo   = UnitCastingInfo
local UnitChannelInfo   = UnitChannelInfo
local UnitClass         = UnitClass
local IsPlayerSpell     = IsPlayerSpell
local GetNetStats       = GetNetStats
local UnitName          = UnitName
local UnitNameFromGUID  = UnitNameFromGUID
local UnitGUID          = UnitGUID
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local MAX_EMPOWER_STAGES = 4
local MAX_CHANNEL_TICKS  = 20
local TIMER_UPDATE_FREQ  = 0.05

local ADDON_PATH = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Castbars\\"

-- =====================================
-- LSM
-- =====================================
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

function CB.ResolveBarTexture(db)
    if LSM and db.barTextureLSM and db.barTextureLSM ~= "" then
        local path = LSM:Fetch("statusbar", db.barTextureLSM)
        if path then return path end
    end
    local fallback = {
        blizzard = "Interface\\TargetingFrame\\UI-StatusBar",
        smooth   = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
        flat     = "Interface\\Buttons\\WHITE8x8",
    }
    return fallback[db.barTexture] or fallback.blizzard
end

function CB.ResolveFont(db)
    if LSM and db.fontLSM and db.fontLSM ~= "" then
        local path = LSM:Fetch("font", db.fontLSM)
        if path then return path end
    end
    return db.font or "Fonts\\FRIZQT__.TTF"
end

-- =====================================
-- CAST INFO CACHE
-- =====================================
local _castInfoCache = {}

local function GetSafeCastInfo(unit, isChannel)
    local name, _, texture, startTime, endTime, _, _, notInterruptible, spellID, numStages
    if isChannel then
        name, _, texture, startTime, endTime, _, notInterruptible, spellID, _, numStages = UnitChannelInfo(unit)
    else
        name, _, texture, startTime, endTime, _, _, notInterruptible, spellID = UnitCastingInfo(unit)
    end
    if type(name) == "nil" then return nil end
    _castInfoCache.name             = name
    _castInfoCache.texture          = texture
    _castInfoCache.startTime        = startTime
    _castInfoCache.endTime          = endTime
    _castInfoCache.notInterruptible = notInterruptible
    _castInfoCache.spellID          = spellID
    _castInfoCache.numStages        = numStages or 0
    return _castInfoCache
end

-- =====================================
-- CHANNEL TICK DATABASE
-- =====================================
local CHANNEL_TICK_DATA = {
    [15407]=6,[263165]=4,[48045]=4,[64843]=4,[47540]=9,[47666]=3,
    [5143]=5,[12051]=3,[205021]=5,
    [198590]=6,[234153]=5,[755]=5,
    [740]=4,[115175]=9,[113656]=4,[117952]=4,
    [120360]=3,[257044]=7,[206931]=3,[198013]=6,[211053]=3,
    [291944]=6,[356995]=3,
}
local CHANNEL_TICK_MODIFIERS = { [356995] = { 1219723, 1 } }

local function GetChannelTicks(spellID, durationMS)
    if spellID and CHANNEL_TICK_DATA[spellID] then
        local ticks = CHANNEL_TICK_DATA[spellID]
        local mod = CHANNEL_TICK_MODIFIERS[spellID]
        if mod and IsPlayerSpell(mod[1]) then ticks = ticks + mod[2] end
        return ticks
    end
    if durationMS and durationMS > 0 then return math_max(2, math_floor(durationMS / 1000 + 0.5)) end
    return 0
end

local EMPOWER_STAGE_COLORS = {
    { 0.80, 0.50, 0.10 }, { 0.90, 0.75, 0.10 },
    { 0.20, 0.70, 0.90 }, { 0.55, 0.30, 0.95 },
}

CB.castbars = {}

-- =====================================
-- INTERRUPT FEEDBACK
-- =====================================
local _interruptFrame = nil

local function ShowInterruptFeedback(spellName)
    local db = TomoModDB and TomoModDB.castbars
    if not db or not db.showInterruptFeedback then return end
    local L = TomoMod_L

    if not _interruptFrame then
        _interruptFrame = CreateFrame("Frame", "TomoMod_CastbarInterruptFeedback", UIParent)
        _interruptFrame:SetSize(400, 60)
        _interruptFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
        _interruptFrame:SetFrameStrata("HIGH")

        local text = _interruptFrame:CreateFontString(nil, "OVERLAY")
        text:SetPoint("CENTER")
        text:SetJustifyH("CENTER")
        _interruptFrame.text = text

        local ag = _interruptFrame:CreateAnimationGroup()
        local hold = ag:CreateAnimation("Alpha")
        hold:SetFromAlpha(1); hold:SetToAlpha(1)
        hold:SetDuration(0.8); hold:SetOrder(1)
        local fade = ag:CreateAnimation("Alpha")
        fade:SetFromAlpha(1); fade:SetToAlpha(0)
        fade:SetDuration(0.7); fade:SetSmoothing("OUT"); fade:SetOrder(2)
        ag:SetScript("OnFinished", function()
            _interruptFrame:SetAlpha(0); _interruptFrame:Hide()
        end)
        _interruptFrame._fadeAG = ag
    end

    local col = db.interruptFeedbackColor or { r = 0.1, g = 0.8, b = 0.1 }
    local fSize = db.interruptFeedbackFontSize or 28
    local font = CB.ResolveFont(db)

    _interruptFrame.text:SetFont(font, fSize, "THICKOUTLINE")
    _interruptFrame.text:SetTextColor(col.r, col.g, col.b, 1)

    if spellName and spellName ~= "" then
        _interruptFrame.text:SetText(string_format(L["cb_interrupt_feedback_full"], spellName))
    else
        _interruptFrame.text:SetText(L["cb_interrupt_feedback_text"])
    end

    _interruptFrame:SetAlpha(1)
    _interruptFrame:Show()
    if _interruptFrame._fadeAG:IsPlaying() then _interruptFrame._fadeAG:Stop() end
    _interruptFrame._fadeAG:Play()
end

-- =====================================
-- CLASS COLOR
-- =====================================
local function GetUnitClassColor(unit)
    local _, class = UnitClass(unit)
    if class and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return c.r, c.g, c.b
    end
    return nil
end

-- =====================================
-- BORDER
-- =====================================
local function CreateBorder(frame, db)
    if db and db.useCustomBorder and db.customBorderPath then
        local border = frame:CreateTexture(nil, "OVERLAY", nil, 7)
        border:SetTexture(db.customBorderPath)
        border:SetPoint("TOPLEFT",     frame, "TOPLEFT",     -4,  4)
        border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",  4, -4)
        frame.customBorder = border
        return
    end
    local function Edge(p1, p2, w, h)
        local t = frame:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(0, 0, 0, 1)
        t:SetPoint(p1); t:SetPoint(p2)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    Edge("TOPLEFT","TOPRIGHT",nil,1); Edge("BOTTOMLEFT","BOTTOMRIGHT",nil,1)
    Edge("TOPLEFT","BOTTOMLEFT",1,nil); Edge("TOPRIGHT","BOTTOMRIGHT",1,nil)
end

-- =====================================
-- TIMER FORMAT
-- =====================================
local function FormatTimer(duration_obj, castStartSec, format)
    if not duration_obj then return "" end
    local ok, raw = pcall(duration_obj.GetRemainingDuration, duration_obj, 0)
    if not ok or not raw or issecretvalue(raw) then raw = 0 end
    local rem = math_max(0, raw)
    if format == "remaining_total" then
        local total = castStartSec and ((GetTime() + rem) - castStartSec) or rem
        return string_format("%.1f / %.1f", rem, total)
    elseif format == "elapsed" then
        if castStartSec then return string_format("%.1f", math_max(0, GetTime() - castStartSec)) end
        return string_format("%.1f", rem)
    end
    return string_format("%.1f", rem)
end

local function TruncateSpellName(name, maxLen)
    if not maxLen or maxLen <= 0 then return name end
    if #name > maxLen then return name:sub(1, maxLen) .. "…" end
    return name
end

-- =====================================
-- PLAYER LATENCY
-- =====================================
local _playerLatency = { sendTime = nil, timeDiff = 0 }
do
    local latFrame = CreateFrame("Frame")
    local lastCastChangeTime = nil
    latFrame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
    latFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
    latFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    latFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    latFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    latFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "CURRENT_SPELL_CAST_CHANGED" then
            lastCastChangeTime = GetTime()
        elseif event == "UNIT_SPELLCAST_SENT" and unit == "player" then
            _playerLatency.sendTime = lastCastChangeTime; lastCastChangeTime = nil
        elseif unit == "player" then
            _playerLatency.sendTime = nil
        end
    end)
end

-- =====================================
-- RESOLVE UNIT KEY → eventUnit
-- For boss1-boss5, the DB key is "boss" but the actual unit token is "boss1" etc.
-- =====================================
local function GetDBKey(unit)
    if unit:match("^boss%d") then return "boss" end
    return unit
end

-- =====================================
-- CREATE A CASTBAR
-- =====================================
function CB.CreateCastbar(unit)
    local db = TomoModDB and TomoModDB.castbars
    if not db then return nil end

    local dbKey = GetDBKey(unit)
    local unitSettings = db[dbKey]
    if not unitSettings or not unitSettings.enabled then return nil end

    local L = TomoMod_L
    local tex  = CB.ResolveBarTexture(db)
    local font = CB.ResolveFont(db)

    local castbar = CreateFrame("StatusBar", "TomoMod_Castbar_" .. unit, UIParent)
    castbar:SetSize(unitSettings.width, unitSettings.height)
    castbar:SetStatusBarTexture(tex)
    castbar:GetStatusBarTexture():SetHorizTile(false)
    castbar:SetMinMaxValues(0, 100)
    castbar:SetValue(100)

    local cbColors = db.castbarColor
    local baseR, baseG, baseB = 0.8, 0.1, 0.1
    if unit == "player" and db.useClassColor then
        local cr, cg, cb2 = GetUnitClassColor("player")
        if cr then baseR, baseG, baseB = cr, cg, cb2 end
    elseif cbColors then
        baseR, baseG, baseB = cbColors.r, cbColors.g, cbColors.b
    end
    castbar:SetStatusBarColor(baseR, baseG, baseB, 1)
    castbar._baseColor = { baseR, baseG, baseB }

    -- Position: player uses absolute position (mover), others anchor to their UF frame
    local pos = unitSettings.position or { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 }
    local anchorFrame = nil
    if unit ~= "player" and unitSettings.anchorToUnitFrame ~= false then
        -- Resolve the UF frame for this unit
        local frameName
        if unit:match("^boss%d") then
            local bossIdx = unit:match("^boss(%d)")
            frameName = "TomoMod_Boss_" .. bossIdx
        else
            frameName = "TomoMod_UF_" .. unit
        end
        anchorFrame = _G[frameName]
    end

    castbar:SetParent(UIParent)
    castbar:ClearAllPoints()
    if anchorFrame then
        -- Anchor below the UF frame and match its width
        local ufWidth = anchorFrame:GetWidth()
        if ufWidth and ufWidth > 0 then
            castbar:SetWidth(ufWidth)
        end
        local offY = unitSettings.anchorOffsetY or -4
        castbar:SetPoint("TOP", anchorFrame, "BOTTOM", 0, offY)
        castbar._anchorFrame = anchorFrame
    else
        castbar:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    end

    -- Draggable setup (only player uses the mover system; anchored bars are not draggable)
    castbar:SetMovable(unit == "player")
    castbar:SetClampedToScreen(true)
    castbar.isLocked = true

    local dragFrame = CreateFrame("Frame", nil, castbar)
    dragFrame:SetAllPoints(castbar)
    dragFrame:SetFrameLevel(castbar:GetFrameLevel() + 20)
    dragFrame:EnableMouse(false)
    dragFrame:Hide()

    local dragOverlay = dragFrame:CreateTexture(nil, "OVERLAY")
    dragOverlay:SetAllPoints(dragFrame)
    dragOverlay:SetColorTexture(1, 1, 0, 0.1)

    local dragLabel = dragFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dragLabel:SetPoint("CENTER", dragFrame, "CENTER")
    dragLabel:SetTextColor(1, 1, 0)
    dragLabel:SetText(L["cb_move_label"] or "(Move)")

    dragFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then castbar:StartMoving() end
    end)
    dragFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            castbar:StopMovingOrSizing()
            local point, _, relativePoint, x, y = castbar:GetPoint()
            unitSettings.position = unitSettings.position or {}
            unitSettings.position.point = point
            unitSettings.position.relativePoint = relativePoint
            unitSettings.position.x = x
            unitSettings.position.y = y
        end
    end)

    castbar.dragFrame = dragFrame

    castbar.SetLocked = function(self, locked)
        self.isLocked = locked
        if locked then
            dragFrame:EnableMouse(false)
            dragFrame:Hide()
        else
            if not self._anchorFrame then
                dragFrame:EnableMouse(true)
                dragFrame:Show()
            end
            self:SetAlpha(1)
            self:Show()
        end
    end

    castbar.IsLocked = function(self)
        return self.isLocked
    end

    -- Re-anchor to UF frame (called on refresh / UF resize)
    castbar.ReanchorToUF = function(self)
        if not self._anchorFrame then return end
        local af = self._anchorFrame
        if not af:IsShown() and not af:GetWidth() then return end
        local ufWidth = af:GetWidth()
        if ufWidth and ufWidth > 0 then
            self:SetWidth(ufWidth)
        end
        self:ClearAllPoints()
        local offY = unitSettings.anchorOffsetY or -4
        self:SetPoint("TOP", af, "BOTTOM", 0, offY)
    end

    castbar:SetLocked(true)
    castbar:SetFrameStrata("MEDIUM")

    -- Background
    local bg = castbar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    local bgMode = db.backgroundMode or "custom"
    if bgMode == "transparent" then bg:SetColorTexture(0, 0, 0, 0)
    elseif bgMode == "black" then bg:SetColorTexture(0, 0, 0, 0.85)
    else
        if db.customBackgroundPath then
            bg:SetTexture(db.customBackgroundPath)
            bg:SetVertexColor(0.12, 0.12, 0.15, 0.95)
        else bg:SetColorTexture(0, 0, 0, 0.85) end
    end
    castbar.bg = bg

    CreateBorder(castbar, db)

    -- NI overlay
    local statustexture = castbar:GetStatusBarTexture()
    local niOverlay = castbar:CreateTexture(nil, "ARTWORK", nil, 1)
    niOverlay:SetPoint("TOPLEFT",     statustexture, "TOPLEFT",     0, 0)
    niOverlay:SetPoint("BOTTOMRIGHT", statustexture, "BOTTOMRIGHT", 0, 0)
    local niColors = db.castbarNIColor
    local niR, niG, niB = 0.5, 0.5, 0.5
    if niColors then niR, niG, niB = niColors.r, niColors.g, niColors.b end
    niOverlay:SetColorTexture(niR, niG, niB, 1)
    niOverlay:SetAlpha(0); niOverlay:Show()
    castbar.niOverlay = niOverlay

    -- Latency (player only)
    if unit == "player" then
        local latencyTex = castbar:CreateTexture(nil, "ARTWORK", nil, 2)
        latencyTex:SetPoint("TOP",    castbar, "TOP",    0, 0)
        latencyTex:SetPoint("BOTTOM", castbar, "BOTTOM", 0, 0)
        latencyTex:SetPoint("RIGHT",  castbar, "RIGHT",  0, 0)
        latencyTex:SetWidth(1); latencyTex:SetTexture(tex)
        latencyTex:SetVertexColor(baseR*0.35, baseG*0.35, baseB*0.35, 0.85)
        latencyTex:Hide()
        castbar.latencyTex = latencyTex
    end

    -- Stage markers (Empowered)
    castbar.stageMarkers = {}
    for i = 1, MAX_EMPOWER_STAGES do
        local marker = castbar:CreateTexture(nil, "OVERLAY", nil, 2)
        marker:SetWidth(2)
        marker:SetPoint("TOP",    castbar, "TOP",    0, 0)
        marker:SetPoint("BOTTOM", castbar, "BOTTOM", 0, 0)
        marker:SetColorTexture(1, 1, 1, 0.7); marker:Hide()
        castbar.stageMarkers[i] = marker
    end
    castbar.stageOverlays = {}; castbar._stageBoundaries = {}
    for i = 1, MAX_EMPOWER_STAGES do
        local overlay = castbar:CreateTexture(nil, "ARTWORK", nil, 3)
        overlay:SetPoint("TOP", castbar, "TOP", 0, 0)
        overlay:SetPoint("BOTTOM", castbar, "BOTTOM", 0, 0)
        local col = EMPOWER_STAGE_COLORS[i] or { 0.5, 0.5, 0.5 }
        overlay:SetColorTexture(col[1], col[2], col[3], 0.45); overlay:Hide()
        castbar.stageOverlays[i] = overlay
    end

    -- Tick markers
    castbar.tickMarkers = {}
    for i = 1, MAX_CHANNEL_TICKS do
        local tick = castbar:CreateTexture(nil, "OVERLAY", nil, 1)
        tick:SetWidth(1)
        tick:SetPoint("TOP",    castbar, "TOP",    0, 0)
        tick:SetPoint("BOTTOM", castbar, "BOTTOM", 0, 0)
        tick:SetColorTexture(1, 1, 1, 0.5); tick:Hide()
        castbar.tickMarkers[i] = tick
    end
    castbar._numTicks = 0

    -- Spark
    castbar._spark = nil
    if db.showSpark then
        local sparkDb = {
            height          = unitSettings.height,
            customSparkPath = db.customSparkPath,
            sparkColor      = db.sparkColor,
            sparkGlowColor  = db.sparkGlowColor,
            sparkTailColor  = db.sparkTailColor,
            sparkGlowAlpha  = db.sparkGlowAlpha or 0.7,
            sparkTailAlpha  = db.sparkTailAlpha or 0.6,
        }
        castbar._spark = SA.CreateSparkTextures(castbar, sparkDb)
        SA.ApplyColors(castbar._spark, sparkDb)
    end

    -- Icon
    if unitSettings.showIcon then
        local icon = castbar:CreateTexture(nil, "OVERLAY")
        icon:SetSize(unitSettings.height, unitSettings.height)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        castbar.icon = icon

        local side = unitSettings.iconSide or "LEFT"
        if side == "RIGHT" then
            icon:SetPoint("LEFT", castbar, "RIGHT", 3, 0)
        else
            icon:SetPoint("RIGHT", castbar, "LEFT", -3, 0)
        end

        local iconBorder = CreateFrame("Frame", nil, castbar)
        iconBorder:SetPoint("TOPLEFT",     icon, "TOPLEFT",     -1,  1)
        iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT",  1, -1)
        CreateBorder(iconBorder, db)
        castbar.iconBorder = iconBorder
    end

    -- Texts
    local fontSize = db.fontSize or 12
    local spellText = castbar:CreateFontString(nil, "OVERLAY")
    spellText:SetFont(font, fontSize, "OUTLINE")
    spellText:SetPoint("LEFT", 4, 0); spellText:SetTextColor(1, 1, 1, 1)
    spellText:SetJustifyH("LEFT"); castbar.spellText = spellText

    if unitSettings.showTimer then
        local timerText = castbar:CreateFontString(nil, "OVERLAY")
        timerText:SetFont(font, fontSize, "OUTLINE")
        timerText:SetPoint("RIGHT", -4, 0); timerText:SetTextColor(1, 1, 1, 0.9)
        castbar.timerText = timerText
    end

    -- Target name (target/focus/boss only)
    if unit ~= "player" and unit ~= "pet" then
        local targetText = castbar:CreateFontString(nil, "OVERLAY")
        targetText:SetFont(font, fontSize, "OUTLINE")
        targetText:SetPoint("LEFT", spellText, "RIGHT", 4, 0)
        targetText:SetTextColor(1, 1, 1, 0.6)
        targetText:SetJustifyH("LEFT")
        castbar.targetText = targetText
    end

    -- Transition Animations
    do
        local fadeAG = castbar:CreateAnimationGroup()
        local fadeA = fadeAG:CreateAnimation("Alpha")
        fadeA:SetFromAlpha(1); fadeA:SetToAlpha(0)
        fadeA:SetDuration(0.3); fadeA:SetSmoothing("OUT")
        fadeAG:SetScript("OnFinished", function()
            castbar:SetAlpha(1)
            if not castbar.casting and not castbar.channeling and not castbar.empowered and not castbar.failstart then
                castbar:Hide()
            end
        end)
        castbar._fadeAG = fadeAG

        local flashAG = castbar:CreateAnimationGroup()
        local fl1 = flashAG:CreateAnimation("Alpha")
        fl1:SetFromAlpha(1); fl1:SetToAlpha(0.15); fl1:SetDuration(0.06); fl1:SetOrder(1)
        local fl2 = flashAG:CreateAnimation("Alpha")
        fl2:SetFromAlpha(0.15); fl2:SetToAlpha(1); fl2:SetDuration(0.06); fl2:SetOrder(2)
        local fl3 = flashAG:CreateAnimation("Alpha")
        fl3:SetFromAlpha(1); fl3:SetToAlpha(0.3); fl3:SetDuration(0.06); fl3:SetOrder(3)
        local fl4 = flashAG:CreateAnimation("Alpha")
        fl4:SetFromAlpha(0.3); fl4:SetToAlpha(1); fl4:SetDuration(0.06); fl4:SetOrder(4)
        castbar._flashAG = flashAG
    end

    -- State
    castbar.unit = unit; castbar.casting = false; castbar.channeling = false
    castbar.empowered = false; castbar.numStages = 0; castbar.duration_obj = nil
    castbar.failstart = nil; castbar._preview = false; castbar._castStartMS = nil
    castbar._castEndMS = nil; castbar._channelSpellID = nil; castbar._timerElapsed = 0

    castbar:Hide()

    -- =====================
    -- HELPERS
    -- =====================
    local function HideTickMarkers(self)
        for i = 1, MAX_CHANNEL_TICKS do self.tickMarkers[i]:Hide() end
        self._numTicks = 0
    end

    local function UpdateTickMarkers(self)
        HideTickMarkers(self)
        if not db.showChannelTicks or not self.channeling then return end
        local dSec = self._realDurationSec
        if not dSec or dSec <= 0 then return end
        local numTicks = GetChannelTicks(self._channelSpellID, dSec * 1000)
        if numTicks < 2 then return end
        self._numTicks = numTicks
        local bw = self:GetWidth()
        for i = 1, numTicks - 1 do
            local m = self.tickMarkers[i]
            if m then
                local xPos = bw * (i / numTicks)
                m:ClearAllPoints()
                m:SetPoint("TOP",    self, "TOPLEFT",    xPos, 0)
                m:SetPoint("BOTTOM", self, "BOTTOMLEFT", xPos, 0)
                m:Show()
            end
        end
    end

    local function HideStageMarkers(self)
        for i = 1, MAX_EMPOWER_STAGES do self.stageMarkers[i]:Hide() end
        if self.stageOverlays then for i = 1, MAX_EMPOWER_STAGES do self.stageOverlays[i]:Hide() end end
        if self._stageBoundaries then wipe(self._stageBoundaries) end
    end

    local function UpdateStageMarkers(self)
        HideStageMarkers(self)
        if not self.empowered or self.numStages <= 0 then return end
        local bw = self:GetWidth()
        local dSec = self._realDurationSec
        if not dSec or dSec <= 0 then return end
        pcall(function()
            local totalMS = dSec * 1000
            if totalMS <= 0 then return end
            local cumulative = 0
            local boundaries = {}; boundaries[0] = 0
            for stage = 0, self.numStages - 1 do
                local stageDur = GetUnitEmpowerStageDuration(self.unit, stage)
                if not stageDur or stageDur <= 0 then break end
                cumulative = cumulative + stageDur
                local pct = cumulative / totalMS
                boundaries[stage + 1] = pct
                if stage < self.numStages - 1 then
                    local xPos = bw * pct
                    local marker = self.stageMarkers[stage + 1]
                    if marker then
                        marker:ClearAllPoints()
                        marker:SetPoint("TOP",    self, "TOPLEFT",    xPos, 0)
                        marker:SetPoint("BOTTOM", self, "BOTTOMLEFT", xPos, 0)
                        marker:Show()
                    end
                end
            end
            self._stageBoundaries = boundaries
            for stage = 1, self.numStages do
                local overlay = self.stageOverlays[stage]
                if overlay then
                    local lp = boundaries[stage-1] or 0
                    local rp = boundaries[stage]   or 1
                    overlay:ClearAllPoints()
                    overlay:SetPoint("TOPLEFT",    self, "TOPLEFT",    bw*lp, 0)
                    overlay:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", bw*lp, 0)
                    overlay:SetWidth(math_max(1, bw*rp - bw*lp))
                    overlay:SetAlpha(0); overlay:Show()
                end
            end
        end)
    end

    local function ResetState(self)
        self.casting=false; self.channeling=false; self.empowered=false
        self.numStages=0; self.duration_obj=nil; self._castStartMS=nil
        self._castEndMS=nil; self._realStartSec=nil; self._realEndSec=nil
        self._realDurationSec=nil; self._channelSpellID=nil; self._timerElapsed=0
        self._lastSpellID = nil
        HideStageMarkers(self); HideTickMarkers(self)
        if self.latencyTex then self.latencyTex:Hide() end
        if self._spark     then SA.HideAll(self._spark) end
        if self.targetText then self.targetText:SetText("") end
    end

    local function FadeOut(self)
        ResetState(self)
        if db.showTransitions and self._fadeAG and not self._fadeAG:IsPlaying() then
            self._fadeAG:Play()
        else
            self:Hide()
        end
    end

    local function FlashBar(self)
        if db.showTransitions and self._flashAG then
            if self._flashAG:IsPlaying() then self._flashAG:Stop() end
            self._flashAG:Play()
        end
    end

    function castbar:ShowPreview()
        self._preview = true; ResetState(self); self.failstart = nil
        self.niOverlay:SetAlpha(0)
        self:SetMinMaxValues(0, 100); self:SetValue(100); self:SetReverseFill(false)
        local bc = self._baseColor or { 0.8, 0.1, 0.1 }
        self:SetStatusBarColor(bc[1], bc[2], bc[3], 1)
        if self.spellText then self.spellText:SetText(string_format(L["cb_preview_castbar"], self.unit)) end
        if self.targetText then self.targetText:SetText("> " .. (UnitName("player") or "Target")) end
        if self.timerText then self.timerText:SetText("1.5") end
        if self.icon then self.icon:SetTexture("Interface\\Icons\\Spell_Nature_Lightning") end
        if self.latencyTex then
            if unitSettings.showLatency then self.latencyTex:SetWidth(math_max(2, self:GetWidth()*0.04)); self.latencyTex:Show()
            else self.latencyTex:Hide() end
        end
        if self._spark then
            SA.Update(self._spark, {
                height=unitSettings.height, sparkStyle=db.sparkStyle,
                sparkGlowAlpha=db.sparkGlowAlpha or 0.7, sparkTailAlpha=db.sparkTailAlpha or 0.6,
            }, 0.75, self:GetWidth(), 0)
        end
        self:Show()
    end

    function castbar:HidePreview()
        self._preview = false
        if self.spellText  then self.spellText:SetText("") end
        if self.targetText then self.targetText:SetText("") end
        if self.timerText  then self.timerText:SetText("") end
        if self.icon      then self.icon:SetTexture(nil) end
        if self.latencyTex then self.latencyTex:Hide() end
        if self._spark    then SA.HideAll(self._spark) end
        HideStageMarkers(self)
        if not self.casting and not self.channeling and not self.empowered and not self.failstart then self:Hide() end
    end

    local function UpdateLatency(self)
        if not self.latencyTex then return end
        if not unitSettings.showLatency or not self.casting then self.latencyTex:Hide(); return end
        local dSec = self._realDurationSec
        if not dSec or dSec <= 0 then self.latencyTex:Hide(); return end
        local latSec
        if unit == "player" and _playerLatency.sendTime then
            latSec = GetTime() - _playerLatency.sendTime
            _playerLatency.timeDiff = latSec; _playerLatency.sendTime = nil
        else
            local _, _, _, latWorld = GetNetStats()
            latSec = (latWorld or 0) / 1000
        end
        local bw = self:GetWidth()
        local w = math_min(bw*0.25, math_max(2, (latSec/(dSec)) * bw))
        if w > 0 then
            local bc = self._baseColor or { 0.8, 0.1, 0.1 }
            self.latencyTex:SetVertexColor(bc[1]*0.35, bc[2]*0.35, bc[3]*0.35, 0.85)
            self.latencyTex:SetWidth(w); self.latencyTex:Show()
        else self.latencyTex:Hide() end
    end

    local function ApplyBarColor(self, unitID, spellID)
        -- Player: class color ; Others: castbarColor (red = interruptible)
        if unit == "player" and db.useClassColor then
            local r, g, b = GetUnitClassColor("player")
            if r then self:SetStatusBarColor(r, g, b, 1); self._baseColor = {r, g, b}; return end
        end
        local bc = db.castbarColor; local r, g, b = 0.8, 0.1, 0.1
        if bc then r, g, b = bc.r, bc.g, bc.b end
        self:SetStatusBarColor(r, g, b, 1); self._baseColor = {r, g, b}
    end

    local function CheckCast(self, isInterrupt, interrupterGUID)
        local unitID = self.unit
        if isInterrupt then
            if (unit ~= "player" and unit ~= "pet") and interrupterGUID and not issecretvalue(interrupterGUID) then
                local playerGUID = UnitGUID("player")
                if playerGUID and interrupterGUID == playerGUID then
                    local lastSpellName = self.spellText and self.spellText:GetText() or ""
                    ShowInterruptFeedback(lastSpellName)
                end
            end

            self.niOverlay:SetAlpha(0); ResetState(self)
            local intCol = db.castbarInterruptColor
            if intCol then self:SetStatusBarColor(intCol.r, intCol.g, intCol.b, 1)
            else self:SetStatusBarColor(0.1, 0.8, 0.1, 1) end
            if self.spellText then
                local interrupterName = interrupterGUID and not issecretvalue(interrupterGUID) and UnitNameFromGUID(interrupterGUID)
                if interrupterName and type(interrupterName) == "string" then
                    self.spellText:SetText((INTERRUPTED or L["cb_interrupted"]) .. " (" .. interrupterName .. ")")
                else self.spellText:SetText(INTERRUPTED or L["cb_interrupted"]) end
            end
            if self.targetText then self.targetText:SetText("") end
            FlashBar(self)
            self.failstart = GetTime(); self:SetMinMaxValues(0,100); self:SetValue(100); self:Show()
            return
        end
        if self.failstart then
            if GetTime() - self.failstart > 1 then
                self.failstart = nil; FadeOut(self)
            end
            return
        end
        local info = GetSafeCastInfo(unitID, false)
        local bchannel, bempowered, numStages, channelSpellID = false, false, 0, nil
        if not info then
            info = GetSafeCastInfo(unitID, true)
            if info then
                channelSpellID = info.spellID
                if info.numStages and info.numStages > 0 then bempowered=true; numStages=info.numStages
                else bchannel=true end
            end
        end
        if not info then ResetState(self); self:Hide(); return end

        if self._fadeAG and self._fadeAG:IsPlaying() then
            self._fadeAG:Stop()
            self:SetAlpha(1)
        end

        local duration = (bchannel or bempowered) and UnitChannelDuration(unitID) or UnitCastingDuration(unitID)
        self.duration_obj = duration
        self._castStartMS = info.startTime; self._castEndMS = info.endTime
        self._realStartSec=nil; self._realEndSec=nil; self._realDurationSec=nil
        self._lastSpellID = info.spellID
        if duration then
            local ok, rStart, rEnd, rDur = pcall(function()
                local rem = duration:GetRemainingDuration(0)
                local now = GetTime(); local endT = now + rem
                return endT-rem, endT, rem
            end)
            if ok then self._realStartSec=rStart; self._realEndSec=rEnd; self._realDurationSec=rDur end
        end
        self.casting=(not bchannel and not bempowered); self.channeling=bchannel
        self.empowered=bempowered; self.numStages=numStages
        self._channelSpellID=channelSpellID; self.failstart=nil; self._timerElapsed=0
        self:SetMinMaxValues(info.startTime, info.endTime); self:SetReverseFill(bchannel)
        ApplyBarColor(self, unitID, info.spellID)
        if self.spellText then self.spellText:SetText(TruncateSpellName(info.name, db.spellNameMaxLen)) end
        if self.targetText then
            local castTarget = UnitName(unitID .. "target")
            if castTarget and type(castTarget) == "string" then
                self.targetText:SetText("> " .. castTarget)
            else
                self.targetText:SetText("")
            end
        end
        if self.icon then self.icon:SetTexture(info.texture) end
        local alpha = C_CurveUtil.EvaluateColorValueFromBoolean(info.notInterruptible, 1, 0)
        self.niOverlay:SetAlpha(alpha)
        if bempowered then UpdateStageMarkers(self); HideTickMarkers(self)
        elseif bchannel then HideStageMarkers(self); UpdateTickMarkers(self)
        else HideStageMarkers(self); HideTickMarkers(self) end
        UpdateLatency(self)
        self:Show()
    end

    -- =====================
    -- OnUpdate
    -- =====================
    castbar:SetScript("OnUpdate", function(self, elapsed)
        if self._preview then return end
        if self.failstart then
            if GetTime() - self.failstart > 1 then self.failstart = nil; FadeOut(self) end
            return
        end
        if not self.casting and not self.channeling and not self.empowered then self:Hide(); return end

        self:SetValue(GetTime() * 1000, Enum.StatusBarInterpolation.ExponentialEaseOut)

        if self._spark and db.showSpark then
            local startSec = self._realStartSec; local endSec = self._realEndSec
            if startSec and endSec and endSec > startSec then
                local now = GetTime()
                local pct = self.channeling and ((endSec-now)/(endSec-startSec)) or ((now-startSec)/(endSec-startSec))
                pct = math_max(0, math_min(pct, 1))
                SA.Update(self._spark, {
                    height=unitSettings.height, sparkStyle=db.sparkStyle,
                    sparkGlowAlpha=db.sparkGlowAlpha or 0.7, sparkTailAlpha=db.sparkTailAlpha or 0.6,
                }, pct, self:GetWidth(), elapsed)
            else SA.HideAll(self._spark) end
        end

        self._timerElapsed = self._timerElapsed + elapsed
        if self._timerElapsed >= TIMER_UPDATE_FREQ then
            self._timerElapsed = 0
            if self.timerText and self.duration_obj then
                self.timerText:SetText(FormatTimer(self.duration_obj, self._realStartSec, db.timerFormat))
            end
        end

        if self.empowered and self._stageBoundaries and self.numStages > 0 then
            local startSec = self._realStartSec; local endSec = self._realEndSec
            if startSec and endSec and endSec > startSec then
                local pct = math_max(0, math_min((GetTime()-startSec)/(endSec-startSec), 1))
                for stage = 1, self.numStages do
                    local overlay = self.stageOverlays[stage]
                    if overlay and overlay:IsShown() then
                        local lp = self._stageBoundaries[stage-1] or 0
                        local rp = self._stageBoundaries[stage]   or 1
                        if pct >= rp then overlay:SetAlpha(0.50)
                        elseif pct > lp then overlay:SetAlpha(0.15 + ((pct-lp)/(rp-lp))*0.35)
                        else overlay:SetAlpha(0) end
                    end
                end
            end
        end
    end)

    -- =====================
    -- EVENTS
    -- =====================
    local events = CreateFrame("Frame")
    events:RegisterUnitEvent("UNIT_SPELLCAST_START",             unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_STOP",              unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_FAILED",            unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED",       unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED",         unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START",     unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP",      unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE",    unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE",     unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START",     unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP",      unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_UPDATE",    unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED",           unit)
    if unit == "target" then events:RegisterEvent("PLAYER_TARGET_CHANGED")
    elseif unit == "focus" then events:RegisterEvent("PLAYER_FOCUS_CHANGED") end
    events:RegisterEvent("PLAYER_ENTERING_WORLD")

    if LSM then
        LSM.RegisterCallback(castbar, "LibSharedMedia_SetGlobal", function(_, mediaType)
            if mediaType == "statusbar" then
                castbar:SetStatusBarTexture(CB.ResolveBarTexture(db))
            end
        end)
    end

    events:SetScript("OnEvent", function(self, event, eventUnit, _, _, interrupterGUID)
        if castbar._preview then return end
        if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            castbar.failstart = nil; CheckCast(castbar, false); return
        end
        if eventUnit ~= unit then return end
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START" then
            castbar.failstart = nil; CheckCast(castbar, false)
        elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" or event == "UNIT_SPELLCAST_EMPOWER_UPDATE" then
            if castbar.channeling or castbar.empowered then CheckCast(castbar, false) end
        elseif event == "UNIT_SPELLCAST_DELAYED" then
            if castbar.casting then CheckCast(castbar, false) end
        elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
            if castbar.casting or castbar.channeling or castbar.empowered then CheckCast(castbar, false) end
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            CheckCast(castbar, true, interrupterGUID)
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            if castbar.channeling or castbar.empowered then return end
            FadeOut(castbar)
        elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED"
            or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_EMPOWER_STOP" then
            if not castbar.failstart then FadeOut(castbar) end
        end
    end)

    castbar.eventFrame = events
    castbar:EnableMouse(false)
    CB.castbars[unit] = castbar
    return castbar
end

-- =====================================
-- GCD SPARK
-- =====================================
function CB.CreateGCDSpark()
    local db = TomoModDB and TomoModDB.castbars
    if not db or not db.player or not db.player.enabled then return end
    if CB._gcdBar then return end

    local playerBar = CB.castbars["player"]
    local unitS     = db.player
    local gcdH      = db.gcdHeight or 4
    local tex       = CB.ResolveBarTexture(db)

    local gcd = CreateFrame("StatusBar", "TomoMod_Castbar_GCD", UIParent)
    gcd:SetSize(unitS.width, gcdH)
    gcd:SetStatusBarTexture(tex)
    gcd:GetStatusBarTexture():SetHorizTile(false)
    gcd:SetMinMaxValues(0, 1)
    gcd:SetValue(0)
    gcd:SetFrameStrata("MEDIUM")

    local col = db.gcdColor or { r = 1, g = 1, b = 1 }
    gcd:SetStatusBarColor(col.r, col.g, col.b, 0.6)

    local bg = gcd:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)

    local spark = gcd:CreateTexture(nil, "OVERLAY")
    spark:SetSize(2, gcdH * 1.6)
    spark:SetColorTexture(1, 1, 1, 0.8)
    spark:Hide()
    gcd._spark = spark

    local function AnchorGCD()
        gcd:ClearAllPoints()
        local bar = CB.castbars["player"]
        if bar then
            gcd:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -2)
            gcd:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -2)
        else
            local pos = unitS.position or { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 }
            gcd:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y - unitS.height - 4)
        end
    end
    AnchorGCD()
    gcd.AnchorGCD = AnchorGCD

    gcd._gcdStart = 0
    gcd._gcdDur   = 0
    gcd._active   = false

    gcd:SetScript("OnUpdate", function(self, elapsed)
        if not self._active then return end
        local now = GetTime()
        local elapsed_t = now - self._gcdStart
        if elapsed_t >= self._gcdDur then
            self._active = false
            self:SetValue(0)
            self._spark:Hide()
            self:Hide()
            return
        end
        local pct = elapsed_t / self._gcdDur
        self:SetValue(pct)
        self._spark:ClearAllPoints()
        self._spark:SetPoint("CENTER", self, "LEFT", self:GetWidth() * pct, 0)
        self._spark:Show()
    end)

    local evFrame = CreateFrame("Frame")
    evFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    evFrame:SetScript("OnEvent", function()
        local cdInfo = C_Spell.GetSpellCooldown(61304)
        if cdInfo and cdInfo.duration and cdInfo.duration > 0 and cdInfo.duration <= 2.0 then
            gcd._gcdStart = cdInfo.startTime
            gcd._gcdDur   = cdInfo.duration
            gcd._active   = true
            gcd:SetMinMaxValues(0, 1)
            gcd:Show()
        end
    end)

    gcd:EnableMouse(false)
    gcd:Hide()
    CB._gcdBar = gcd
end

-- =====================================
-- BLIZZARD CASTBAR
-- =====================================
local BLIZZARD_CASTBAR_FRAMES = {
    "PlayerCastingBarFrame","PetCastingBarFrame","TargetFrameSpellBar","FocusFrameSpellBar",
}
local function KillFrame(frame)
    if not frame then return end
    frame:UnregisterAllEvents(); frame:Hide()
    frame:SetScript("OnShow", function(self) self:Hide() end)
    if frame.Icon then frame.Icon:Hide() end; if frame.Border then frame.Border:Hide() end
    if frame.BorderShield then frame.BorderShield:Hide() end
    if frame.Flash then frame.Flash:Hide() end; if frame.Spark then frame.Spark:Hide() end
    if frame.Text then frame.Text:Hide() end
end
local function RestoreFrame(frame)
    if not frame then return end
    frame:SetScript("OnShow", nil); frame:Show()
    if frame.Icon then frame.Icon:Show() end; if frame.Border then frame.Border:Show() end
    if frame.Text then frame.Text:Show() end; if frame.Spark then frame.Spark:Show() end
end
function CB.HideBlizzardCastbar()
    for _, name in ipairs(BLIZZARD_CASTBAR_FRAMES) do KillFrame(_G[name]) end
end
function CB.ShowBlizzardCastbar()
    for _, name in ipairs(BLIZZARD_CASTBAR_FRAMES) do RestoreFrame(_G[name]) end
end

-- =====================================
-- LOCK / UNLOCK (used by Movers)
-- =====================================
function CB.IsLocked()
    for _, cb in pairs(CB.castbars) do
        if not cb:IsLocked() then return false end
    end
    return true
end

function CB.UnlockPlayerCastbar()
    local cb = CB.castbars["player"]
    if cb then cb:SetLocked(false); cb:ShowPreview() end
end

function CB.LockPlayerCastbar()
    local cb = CB.castbars["player"]
    if cb then cb:SetLocked(true); cb:HidePreview() end
end

function CB.ToggleLock()
    local anyUnlocked = false
    for _, cb in pairs(CB.castbars) do if not cb:IsLocked() then anyUnlocked=true; break end end
    if anyUnlocked then
        for _, cb in pairs(CB.castbars) do cb:SetLocked(true); cb:HidePreview() end
    else
        for _, cb in pairs(CB.castbars) do cb:SetLocked(false); cb:ShowPreview() end
    end
end

-- =====================================
-- RE-ANCHOR TO UF FRAMES
-- Called after UF resize/refresh so castbars stay in sync.
-- =====================================
function CB.ReanchorAllToUF()
    for _, cb in pairs(CB.castbars) do
        if cb.ReanchorToUF then cb:ReanchorToUF() end
    end
end

-- =====================================
-- INITIALIZE
-- =====================================
function CB.Initialize()
    local db = TomoModDB and TomoModDB.castbars
    if not db or not db.enabled then return end
    if db.hideBlizzardCastbar then CB.HideBlizzardCastbar() end

    -- Player, Target, Focus, Pet
    for _, unit in ipairs({ "player", "target", "focus", "pet" }) do
        if db[unit] and db[unit].enabled then CB.CreateCastbar(unit) end
    end

    -- Boss 1-5
    if db.boss and db.boss.enabled then
        for i = 1, 5 do
            CB.CreateCastbar("boss" .. i)
        end
    end

    -- GCD Spark
    if db.showGCDSpark then CB.CreateGCDSpark() end

    -- Defer re-anchor so UF frames have time to spawn
    C_Timer.After(0.1, function() CB.ReanchorAllToUF() end)
end

-- =====================================
-- REFRESH ALL
-- =====================================
function CB.RefreshAll()
    for unit, cb in pairs(CB.castbars) do
        if cb.eventFrame then
            if LSM and LSM.UnregisterCallback then LSM.UnregisterCallback(cb, "LibSharedMedia_SetGlobal") end
            cb.eventFrame:UnregisterAllEvents(); cb.eventFrame:SetScript("OnEvent", nil)
        end
        cb:SetScript("OnUpdate", nil); cb:Hide(); cb:SetParent(nil)
    end
    wipe(CB.castbars)
    if CB._gcdBar then
        CB._gcdBar:SetScript("OnUpdate", nil)
        CB._gcdBar:Hide(); CB._gcdBar:SetParent(nil)
        CB._gcdBar = nil
    end
    CB.Initialize()
end

-- =====================================
-- SetEnabled (module pattern)
-- =====================================
function CB.SetEnabled(v)
    if not TomoModDB or not TomoModDB.castbars then return end
    TomoModDB.castbars.enabled = v
    if v then
        CB.Initialize()
    else
        for unit, cb in pairs(CB.castbars) do
            if cb.eventFrame then
                cb.eventFrame:UnregisterAllEvents(); cb.eventFrame:SetScript("OnEvent", nil)
            end
            cb:SetScript("OnUpdate", nil); cb:Hide(); cb:SetParent(nil)
        end
        wipe(CB.castbars)
        if CB._gcdBar then
            CB._gcdBar:SetScript("OnUpdate", nil)
            CB._gcdBar:Hide(); CB._gcdBar:SetParent(nil)
            CB._gcdBar = nil
        end
        CB.ShowBlizzardCastbar()
    end
end

function CB.ApplySettings()
    CB.RefreshAll()
end

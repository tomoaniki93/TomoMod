-- =====================================
-- Elements/Castbar.lua — Castbar Element
-- Supports: Casts, Channels, Empowered (Evoker stages + gradient)
-- Channel tick markers via spell database lookup
-- =====================================

local UF_Elements = UF_Elements or {}

local TEXTURE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"

local MAX_EMPOWER_STAGES = 4
local MAX_TICK_MARKERS = 20

-- =====================================
-- CHANNEL TICK DATABASE
-- Maps spellID -> number of ticks (base, before haste)
-- UnitChannelInfo already returns haste-adjusted duration,
-- so we just divide evenly by tick count
-- =====================================
local CHANNEL_TICKS = {
    -- Evoker
    [356995] = 3,   -- Disintegrate (3 ticks)
    -- Priest
    [15407]  = 3,   -- Mind Flay (3 ticks)
    [391403] = 3,   -- Mind Flay: Insanity (3 ticks)
    [48045]  = 4,   -- Mind Sear (4 ticks)
    [64843]  = 4,   -- Divine Hymn (4 ticks)
    [47540]  = 4,   -- Penance (4 ticks)
    -- Mage
    [5143]   = 5,   -- Arcane Missiles (5 ticks)
    [205021] = 5,   -- Ray of Frost (5 ticks)
    -- Warlock
    [234153] = 5,   -- Drain Life (5 ticks)
    [198590] = 6,   -- Drain Soul (6 ticks)
    [755]    = 6,   -- Health Funnel (6 ticks)
    -- Druid
    [740]    = 4,   -- Tranquility (4 ticks)
    -- Shaman
    [469931] = 5,   -- Tempest (5 ticks)
    -- Monk
    [115175] = 6,   -- Soothing Mist (6 ticks)
    [191837] = 3,   -- Essence Font (3 ticks)
    -- Hunter
    [120360] = 3,   -- Barrage (3 ticks)
    -- Demon Hunter
    [198013] = 5,   -- Eye Beam (5 ticks)
}

-- Stage gradient colors (from base towards gold)
-- Applied as vertex color multipliers on stage overlays
local STAGE_COLORS = {
    { 1.0,  1.0,  1.0,  0    },  -- stage 1: base color (no overlay)
    { 1.0,  0.85, 0.4,  0.15 },  -- stage 2: warm tint
    { 1.0,  0.7,  0.2,  0.25 },  -- stage 3: orange tint
    { 1.0,  0.55, 0.1,  0.35 },  -- stage 4: deep gold tint
}

-- =====================================
-- CREATE CASTBAR
-- =====================================

function UF_Elements.CreateCastbar(parent, unit, settings)
    if not settings or not settings.castbar or not settings.castbar.enabled then return nil end

    local cbSettings = settings.castbar
    local tex = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.texture) or TEXTURE
    local font = (TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.font) or FONT

    local castbar = CreateFrame("StatusBar", "TomoMod_Castbar_" .. unit, parent)
    castbar:SetSize(cbSettings.width, cbSettings.height)
    castbar:SetStatusBarTexture(tex)
    castbar:GetStatusBarTexture():SetHorizTile(false)
    castbar:SetMinMaxValues(0, 100)
    castbar:SetValue(100)

    -- Base color from DB (interruptible cast)
    local cbColors = TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.castbarColor
    local baseR, baseG, baseB = 0.8, 0.1, 0.1
    if cbColors then baseR, baseG, baseB = cbColors.r, cbColors.g, cbColors.b end
    castbar:SetStatusBarColor(baseR, baseG, baseB, 1)
    castbar._baseColor = { baseR, baseG, baseB }

    -- Position: player castbar is standalone (anchored to UIParent, drag & drop via /tm sr)
    -- Other units anchor relative to their parent frame
    if unit == "player" then
        local pos = cbSettings.position or { point = "BOTTOM", relativePoint = "CENTER", x = -280, y = -220 }
        castbar:SetParent(UIParent)
        castbar:ClearAllPoints()
        castbar:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)

        -- Make draggable (toggled via /tm sr)
        TomoMod_Utils.SetupDraggable(castbar, function()
            local point, _, relativePoint, x, y = castbar:GetPoint()
            cbSettings.position = cbSettings.position or {}
            cbSettings.position.point = point
            cbSettings.position.relativePoint = relativePoint
            cbSettings.position.x = x
            cbSettings.position.y = y
        end)
        castbar:SetFrameStrata("MEDIUM")
    else
        local pos = cbSettings.position or { point = "TOP", relativePoint = "BOTTOM", x = 0, y = -6 }
        castbar:SetPoint(pos.point, parent, pos.relativePoint, pos.x, pos.y)
    end

    -- Background
    local bg = castbar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(tex)
    bg:SetVertexColor(0.08, 0.08, 0.10, 0.9)
    castbar.bg = bg

    -- Border
    UF_Elements.CreateBorder(castbar)

    -- Not-interruptible overlay (grey, anchored to statusbar fill texture)
    local statustexture = castbar:GetStatusBarTexture()
    local niOverlay = castbar:CreateTexture(nil, "ARTWORK", nil, 1)
    niOverlay:SetPoint("TOPLEFT", statustexture, "TOPLEFT", 0, 0)
    niOverlay:SetPoint("BOTTOMRIGHT", statustexture, "BOTTOMRIGHT", 0, 0)
    local niColors = TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.castbarNIColor
    local niR, niG, niB = 0.5, 0.5, 0.5
    if niColors then niR, niG, niB = niColors.r, niColors.g, niColors.b end
    niOverlay:SetColorTexture(niR, niG, niB, 1)
    niOverlay:SetAlpha(0)
    niOverlay:Show()
    castbar.niOverlay = niOverlay

    -- =====================================
    -- LATENCY OVERLAY (player only)
    -- =====================================
    if unit == "player" then
        local latencyTex = castbar:CreateTexture(nil, "ARTWORK", nil, 2)
        latencyTex:SetPoint("TOP", castbar, "TOP", 0, 0)
        latencyTex:SetPoint("BOTTOM", castbar, "BOTTOM", 0, 0)
        latencyTex:SetPoint("RIGHT", castbar, "RIGHT", 0, 0)
        latencyTex:SetWidth(1)
        latencyTex:SetTexture(tex)
        latencyTex:SetVertexColor(baseR * 0.35, baseG * 0.35, baseB * 0.35, 0.85)
        latencyTex:Hide()
        castbar.latencyTex = latencyTex
    end

    -- =====================================
    -- EMPOWER STAGE MARKERS (vertical lines)
    -- =====================================
    castbar.stageMarkers = {}
    for i = 1, MAX_EMPOWER_STAGES do
        local marker = castbar:CreateTexture(nil, "OVERLAY", nil, 2)
        marker:SetWidth(2)
        marker:SetPoint("TOP", castbar, "TOP", 0, 0)
        marker:SetPoint("BOTTOM", castbar, "BOTTOM", 0, 0)
        marker:SetColorTexture(1, 1, 1, 0.7)
        marker:Hide()
        castbar.stageMarkers[i] = marker
    end

    -- =====================================
    -- EMPOWER STAGE OVERLAYS (gradient color per stage section)
    -- Colored textures anchored between stage boundaries
    -- =====================================
    castbar.stageOverlays = {}
    for i = 1, MAX_EMPOWER_STAGES do
        local overlay = castbar:CreateTexture(nil, "ARTWORK", nil, 2)
        overlay:SetPoint("TOP", castbar, "TOP", 0, 0)
        overlay:SetPoint("BOTTOM", castbar, "BOTTOM", 0, 0)
        overlay:SetColorTexture(1, 0.6, 0.1, 1)
        overlay:SetAlpha(0)
        overlay:Hide()
        castbar.stageOverlays[i] = overlay
    end

    -- =====================================
    -- CHANNEL TICK MARKERS (vertical lines for periodic ticks)
    -- =====================================
    castbar.tickMarkers = {}
    for i = 1, MAX_TICK_MARKERS do
        local tick = castbar:CreateTexture(nil, "OVERLAY", nil, 1)
        tick:SetWidth(1)
        tick:SetPoint("TOP", castbar, "TOP", 0, 0)
        tick:SetPoint("BOTTOM", castbar, "BOTTOM", 0, 0)
        tick:SetColorTexture(1, 1, 1, 0.45)
        tick:Hide()
        castbar.tickMarkers[i] = tick
    end

    -- Icon
    if cbSettings.showIcon then
        local icon = castbar:CreateTexture(nil, "OVERLAY")
        icon:SetSize(cbSettings.height, cbSettings.height)
        icon:SetPoint("RIGHT", castbar, "LEFT", -3, 0)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        castbar.icon = icon

        local iconBorder = CreateFrame("Frame", nil, castbar)
        iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
        iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
        UF_Elements.CreateBorder(iconBorder)
    end

    -- Spell name
    local spellText = castbar:CreateFontString(nil, "OVERLAY")
    spellText:SetFont(font, math.max(8, cbSettings.height - 8), "OUTLINE")
    spellText:SetPoint("LEFT", 4, 0)
    spellText:SetTextColor(1, 1, 1, 1)
    spellText:SetJustifyH("LEFT")
    castbar.spellText = spellText

    -- Timer text
    if cbSettings.showTimer then
        local timerText = castbar:CreateFontString(nil, "OVERLAY")
        timerText:SetFont(font, math.max(8, cbSettings.height - 8), "OUTLINE")
        timerText:SetPoint("RIGHT", -4, 0)
        timerText:SetTextColor(1, 1, 1, 0.9)
        castbar.timerText = timerText
    end

    -- State
    castbar.unit = unit
    castbar.casting = false
    castbar.channeling = false
    castbar.empowered = false
    castbar.numStages = 0
    castbar.duration_obj = nil
    castbar.failstart = nil
    castbar._preview = false
    castbar._castStartMS = nil
    castbar._castEndMS = nil

    -- Empower stage tracking
    castbar._stageBoundaries = {}   -- cumulative ms boundaries per stage
    castbar._currentStage = 0
    castbar._empSpellName = nil

    -- Channel tick tracking
    castbar._ticksPlaced = false

    castbar:Hide()

    -- =====================================
    -- HELPER: Hide all stage markers + overlays
    -- =====================================
    local function HideStageMarkers(self)
        for i = 1, MAX_EMPOWER_STAGES do
            self.stageMarkers[i]:Hide()
            self.stageOverlays[i]:SetAlpha(0)
            self.stageOverlays[i]:Hide()
        end
        self._stageBoundaries = {}
        self._currentStage = 0
        self._empSpellName = nil
    end

    -- =====================================
    -- HELPER: Hide all tick markers
    -- =====================================
    local function HideTickMarkers(self)
        for i = 1, MAX_TICK_MARKERS do
            self.tickMarkers[i]:Hide()
        end
        self._ticksPlaced = false
    end

    -- =====================================
    -- HELPER: Position stage markers + gradient overlays for empowered cast
    -- =====================================
    local function UpdateStageMarkers(self)
        HideStageMarkers(self)
        if not self.empowered or self.numStages <= 0 then return end

        local barWidth = self:GetWidth()
        local startMS = self._castStartMS
        local endMS = self._castEndMS
        if not startMS or not endMS then return end

        local ok, _ = pcall(function()
            local totalDuration = endMS - startMS
            if totalDuration <= 0 then return end

            local cumulative = 0
            local boundaries = {}

            for stage = 0, self.numStages - 1 do
                local stageDuration = GetUnitEmpowerStageDuration(self.unit, stage)
                if not stageDuration or stageDuration <= 0 then break end
                cumulative = cumulative + stageDuration
                boundaries[stage + 1] = cumulative

                -- Stage marker (vertical white line between stages)
                if stage < self.numStages - 1 then
                    local pct = cumulative / totalDuration
                    local xPos = barWidth * pct
                    local marker = self.stageMarkers[stage + 1]
                    if marker then
                        marker:ClearAllPoints()
                        marker:SetPoint("TOP", self, "TOPLEFT", xPos, 0)
                        marker:SetPoint("BOTTOM", self, "BOTTOMLEFT", xPos, 0)
                        marker:Show()
                    end
                end

                -- Stage overlay (gradient color section)
                local overlay = self.stageOverlays[stage + 1]
                if overlay then
                    local prevPct = (stage > 0 and boundaries[stage]) and (boundaries[stage] / totalDuration) or 0
                    local curPct = cumulative / totalDuration
                    local xStart = barWidth * prevPct
                    local xEnd = barWidth * curPct

                    overlay:ClearAllPoints()
                    overlay:SetPoint("TOP", self, "TOP", 0, 0)
                    overlay:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
                    overlay:SetPoint("LEFT", self, "LEFT", xStart, 0)
                    overlay:SetWidth(math.max(1, xEnd - xStart))

                    local sc = STAGE_COLORS[stage + 1] or STAGE_COLORS[#STAGE_COLORS]
                    overlay:SetColorTexture(sc[1], sc[2], sc[3], 1)
                    overlay:SetAlpha(sc[4])
                    overlay:Show()
                end
            end

            self._stageBoundaries = boundaries
        end)
    end

    -- =====================================
    -- HELPER: Compute current empower stage from elapsed time
    -- =====================================
    local function GetCurrentEmpowerStage(self)
        if not self.empowered or not self._castStartMS then return 0 end

        local elapsedMS = GetTime() * 1000 - self._castStartMS
        local boundaries = self._stageBoundaries
        if not boundaries or #boundaries == 0 then return 0 end

        local stage = 0
        for i = 1, #boundaries do
            if elapsedMS >= boundaries[i] then
                stage = i
            else
                break
            end
        end
        return stage
    end

    -- =====================================
    -- HELPER: Place tick markers evenly from known tick count
    -- =====================================
    local function PlaceTickMarkers(self, tickCount)
        HideTickMarkers(self)
        if not tickCount or tickCount < 2 then return end

        local barWidth = self:GetWidth()

        -- Place (tickCount - 1) markers between tick boundaries
        -- e.g. 3 ticks => 2 markers at 1/3 and 2/3
        for i = 1, tickCount - 1 do
            if i > MAX_TICK_MARKERS then break end

            local pct = i / tickCount
            local xPos = barWidth * pct
            local marker = self.tickMarkers[i]
            if marker then
                marker:ClearAllPoints()
                marker:SetPoint("TOP", self, "TOPLEFT", xPos, 0)
                marker:SetPoint("BOTTOM", self, "BOTTOMLEFT", xPos, 0)
                marker:Show()
            end
        end

        self._ticksPlaced = true
    end

    -- =====================================
    -- HELPER: Reset cast state
    -- =====================================
    local function ResetState(self)
        self.casting = false
        self.channeling = false
        self.empowered = false
        self.numStages = 0
        self.duration_obj = nil
        self._castStartMS = nil
        self._castEndMS = nil
        HideStageMarkers(self)
        HideTickMarkers(self)
        if self.latencyTex then self.latencyTex:Hide() end
    end

    -- =====================================
    -- PREVIEW MODE (player only — shown when unlocked via /tm sr)
    -- =====================================

    function castbar:ShowPreview()
        self._preview = true
        ResetState(self)
        self.failstart = nil
        self.niOverlay:SetAlpha(0)

        self:SetMinMaxValues(0, 100)
        self:SetValue(100)
        self:SetReverseFill(false)
        local bc = self._baseColor or { 0.8, 0.1, 0.1 }
        self:SetStatusBarColor(bc[1], bc[2], bc[3], 1)

        if self.spellText then self.spellText:SetText("Castbar") end
        if self.timerText then self.timerText:SetText("1.5") end
        if self.icon then
            self.icon:SetTexture("Interface\\Icons\\Spell_Nature_Lightning")
        end

        -- Show latency preview
        if self.latencyTex then
            if cbSettings.showLatency then
                local previewWidth = math.max(2, self:GetWidth() * 0.04)
                self.latencyTex:SetWidth(previewWidth)
                local bc2 = self._baseColor or { 0.8, 0.1, 0.1 }
                self.latencyTex:SetVertexColor(bc2[1] * 0.35, bc2[2] * 0.35, bc2[3] * 0.35, 0.85)
                self.latencyTex:Show()
            else
                self.latencyTex:Hide()
            end
        end

        self:Show()
    end

    function castbar:HidePreview()
        self._preview = false
        if self.spellText then self.spellText:SetText("") end
        if self.timerText then self.timerText:SetText("") end
        if self.icon then self.icon:SetTexture(nil) end
        if self.latencyTex then self.latencyTex:Hide() end
        HideStageMarkers(self)
        HideTickMarkers(self)
        if not self.casting and not self.channeling and not self.empowered and not self.failstart then
            self:Hide()
        end
    end

    -- =====================================
    -- LATENCY HELPER
    -- =====================================

    local function UpdateLatency(self)
        if not self.latencyTex then return end
        if not cbSettings.showLatency then
            self.latencyTex:Hide()
            return
        end

        -- Show during casting only (not channels/empowered)
        if not self.casting then
            self.latencyTex:Hide()
            return
        end

        local startMS = self._castStartMS
        local endMS = self._castEndMS
        if not startMS or not endMS then
            self.latencyTex:Hide()
            return
        end

        local ok, result = pcall(function()
            local castDurationMS = endMS - startMS
            if castDurationMS <= 0 then return 0 end
            local _, _, _, latencyWorld = GetNetStats()
            local barWidth = self:GetWidth()
            return math.min(barWidth * 0.25, math.max(2, (latencyWorld / castDurationMS) * barWidth))
        end)

        if ok and result and result > 0 then
            local bc = self._baseColor or { 0.8, 0.1, 0.1 }
            self.latencyTex:SetVertexColor(bc[1] * 0.35, bc[2] * 0.35, bc[3] * 0.35, 0.85)
            self.latencyTex:SetWidth(result)
            self.latencyTex:Show()
        else
            self.latencyTex:Hide()
        end
    end

    -- =====================================
    -- CASTBAR LOGIC
    -- Supports: regular casts, channels, and empowered casts (Evoker)
    -- =====================================

    local function CheckCast(self, isInterrupt)
        local unitID = self.unit

        -- Handle interrupt display
        if isInterrupt then
            self.niOverlay:SetAlpha(0)
            ResetState(self)
            local intCol = TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.castbarInterruptColor
            if intCol then
                self:SetStatusBarColor(intCol.r, intCol.g, intCol.b, 1)
            else
                self:SetStatusBarColor(0.1, 0.8, 0.1, 1)
            end
            if self.spellText then
                self.spellText:SetText(INTERRUPTED or "Interrompu")
            end
            self.failstart = GetTime()
            self:SetMinMaxValues(0, 100)
            self:SetValue(100)
            self:Show()
            return
        end

        -- Fade interrupted text after 1 second
        if self.failstart then
            if GetTime() - self.failstart > 1 then
                self.failstart = nil
                self:Hide()
            end
            return
        end

        -- ===== Check regular cast =====
        local bchannel = false
        local bempowered = false
        local numStages = 0
        local channelSpellID = nil

        local name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible = UnitCastingInfo(unitID)

        -- ===== Check channel / empowered =====
        if type(name) == "nil" then
            local chanName, _, chanTex, chanStart, chanEnd, _, chanNI, chanSpellID, _, chanStages = UnitChannelInfo(unitID)
            if type(chanName) ~= "nil" then
                name = chanName
                texture = chanTex
                startTimeMS = chanStart
                endTimeMS = chanEnd
                notInterruptible = chanNI

                if chanStages and chanStages > 0 then
                    -- Empowered cast (Evoker: Fire Breath, Eternity Surge, etc.)
                    bempowered = true
                    numStages = chanStages
                else
                    -- Regular channel (Disintegrate, etc.)
                    bchannel = true
                    channelSpellID = chanSpellID
                end
            end
        end

        -- Nothing found -> hide
        if type(name) == "nil" then
            ResetState(self)
            self:Hide()
            return
        end

        -- Get duration object for timer text
        local duration
        if bchannel or bempowered then
            duration = UnitChannelDuration(unitID)
        else
            duration = UnitCastingDuration(unitID)
        end
        self.duration_obj = duration

        -- Store raw times for latency / empower markers
        self._castStartMS = startTimeMS
        self._castEndMS = endTimeMS

        -- Update state
        self.casting = (not bchannel and not bempowered)
        self.channeling = bchannel
        self.empowered = bempowered
        self.numStages = numStages
        self.failstart = nil

        -- TWW: SetMinMaxValues accepts secrets (startTimeMS, endTimeMS from API)
        self:SetMinMaxValues(startTimeMS, endTimeMS)

        -- Fill direction:
        -- Regular channels fill right-to-left (reverse)
        -- Casts and empowered fill left-to-right (normal)
        self:SetReverseFill(bchannel)

        -- Reset base color (may have been green from interrupt)
        local bc = self._baseColor or { 0.8, 0.1, 0.1 }
        self:SetStatusBarColor(bc[1], bc[2], bc[3], 1)

        -- SetText/SetTexture are C-side, accept secrets
        if self.icon then self.icon:SetTexture(texture) end

        -- Empower: show stage markers + overlays, store spell name
        if bempowered then
            self._empSpellName = name
            self._currentStage = 0
            UpdateStageMarkers(self)
            HideTickMarkers(self)
            -- Spell text will be updated in OnUpdate with stage indicator
            if self.spellText then self.spellText:SetFormattedText("%s", name) end
        else
            HideStageMarkers(self)
            if self.spellText then self.spellText:SetFormattedText("%s", name) end
        end

        -- Channel: place tick markers from spell database (player only)
        -- channelSpellID is a secret value for target/focus in TWW — cannot
        -- be used as a table index without triggering "table index is secret"
        if bchannel and unit == "player" and channelSpellID then
            local ok, tickCount = pcall(function() return CHANNEL_TICKS[channelSpellID] end)
            if ok and tickCount and tickCount > 1 then
                PlaceTickMarkers(self, tickCount)
            else
                HideTickMarkers(self)
            end
        else
            HideTickMarkers(self)
        end

        -- TWW: SetAlpha ACCEPTS secrets from C_CurveUtil
        local alpha = C_CurveUtil.EvaluateColorValueFromBoolean(notInterruptible, 1, 0)
        self.niOverlay:SetAlpha(alpha)

        -- Latency (regular casts only)
        UpdateLatency(self)

        self:Show()
    end

    -- OnUpdate: bar progress + timer text + empower stage tracking
    castbar:SetScript("OnUpdate", function(self, elapsed)
        -- Preview mode: keep bar visible, skip all logic
        if self._preview then return end

        -- Handle interrupt fadeout
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

        -- Progress: GetTime() * 1000 is non-secret, bar fill handled C-side
        self:SetValue(GetTime() * 1000, Enum.StatusBarInterpolation.ExponentialEaseOut)

        -- Timer from stored duration object (param 0 for displayable value)
        if self.timerText and self.duration_obj then
            self.timerText:SetText(string.format("%.1f", self.duration_obj:GetRemainingDuration(0)))
        end

        -- Empower: track current stage and update spell text (player only)
        -- _castStartMS is a secret value for target/focus in TWW
        if self.empowered and self.unit == "player" then
            local newStage = GetCurrentEmpowerStage(self)
            if newStage ~= self._currentStage then
                self._currentStage = newStage
                -- Update stage overlay visibility: highlight current + completed stages
                for i = 1, MAX_EMPOWER_STAGES do
                    local overlay = self.stageOverlays[i]
                    if overlay then
                        local sc = STAGE_COLORS[i] or STAGE_COLORS[#STAGE_COLORS]
                        if i <= newStage then
                            overlay:SetAlpha(sc[4] + 0.15)
                        else
                            overlay:SetAlpha(sc[4])
                        end
                    end
                end
            end
            -- Show stage in spell text (player only — name is secret for target/focus)
            if self.spellText and self.numStages > 0 and self.unit == "player" then
                local displayStage = math.max(1, self._currentStage)
                local ok, spellName = pcall(tostring, self._empSpellName)
                if ok and spellName then
                    self.spellText:SetText(spellName .. "  [" .. displayStage .. "/" .. self.numStages .. "]")
                end
            end
        end
    end)

    -- =====================================
    -- EVENTS
    -- =====================================
    local events = CreateFrame("Frame")

    -- Regular cast events
    events:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit)

    -- Channel events
    events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", unit)

    -- Interruptibility changes
    events:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", unit)

    -- Empowered cast events (Evoker: Fire Breath, Eternity Surge, etc.)
    events:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_UPDATE", unit)

    -- Target/focus change for detecting ongoing casts
    if unit == "target" then
        events:RegisterEvent("PLAYER_TARGET_CHANGED")
    elseif unit == "focus" then
        events:RegisterEvent("PLAYER_FOCUS_CHANGED")
    end

    events:SetScript("OnEvent", function(self, event, eventUnit)
        -- Preview mode: ignore all cast events
        if castbar._preview then return end

        -- Target/focus change: check for ongoing cast/channel on new target
        if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
            castbar.failstart = nil
            CheckCast(castbar, false)
            return
        end

        if eventUnit ~= unit then return end

        -- ===== CAST START / CHANNEL START / EMPOWER START =====
        if event == "UNIT_SPELLCAST_START"
            or event == "UNIT_SPELLCAST_CHANNEL_START"
            or event == "UNIT_SPELLCAST_EMPOWER_START" then
            castbar.failstart = nil
            CheckCast(castbar, false)

        -- ===== CHANNEL / EMPOWER UPDATE (duration change, stage change) =====
        elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE"
            or event == "UNIT_SPELLCAST_EMPOWER_UPDATE" then
            if castbar.channeling or castbar.empowered then
                CheckCast(castbar, false)
            end

        -- ===== INTERRUPTIBILITY CHANGE =====
        elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE"
            or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
            if castbar.casting or castbar.channeling or castbar.empowered then
                CheckCast(castbar, false)
            end

        -- ===== INTERRUPTED =====
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            CheckCast(castbar, true)

        -- ===== CAST SUCCEEDED =====
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            if castbar.channeling or castbar.empowered then
                return
            end
            CheckCast(castbar, false)

        -- ===== STOP / FAILED / CHANNEL STOP / EMPOWER STOP =====
        elseif event == "UNIT_SPELLCAST_STOP"
            or event == "UNIT_SPELLCAST_FAILED"
            or event == "UNIT_SPELLCAST_CHANNEL_STOP"
            or event == "UNIT_SPELLCAST_EMPOWER_STOP" then
            if not castbar.failstart then
                CheckCast(castbar, false)
            end
        end
    end)

    castbar.eventFrame = events
    castbar:EnableMouse(false)

    return castbar
end

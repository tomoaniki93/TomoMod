-- =====================================
-- Elements/Castbar.lua — Castbar Element
-- Supports: Casts, Channels, Empowered (Evoker stages)
-- =====================================

local UF_Elements = UF_Elements or {}

local TEXTURE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"

local MAX_EMPOWER_STAGES = 4

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
    -- SetAlpha accepts secret values from C_CurveUtil — key TWW technique from asTargetCastBar
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
    -- EMPOWER STAGE MARKERS
    -- Vertical lines showing stage boundaries for empowered casts (Evoker)
    -- Pre-created pool of MAX_EMPOWER_STAGES markers, shown/hidden as needed
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

    castbar:Hide()

    -- =====================================
    -- HELPER: Hide all stage markers
    -- =====================================
    local function HideStageMarkers(self)
        for i = 1, MAX_EMPOWER_STAGES do
            self.stageMarkers[i]:Hide()
        end
    end

    -- =====================================
    -- HELPER: Position stage markers for empowered cast
    -- Uses GetUnitEmpowerStageDuration() to compute where each stage boundary falls
    -- =====================================
    local function UpdateStageMarkers(self)
        HideStageMarkers(self)
        if not self.empowered or self.numStages <= 0 then return end

        local barWidth = self:GetWidth()
        local startMS = self._castStartMS
        local endMS = self._castEndMS
        if not startMS or not endMS then return end

        -- Compute total cast duration and cumulative stage positions
        -- GetUnitEmpowerStageDuration(unit, stage): stage is 0-indexed
        local ok, _ = pcall(function()
            local totalDuration = endMS - startMS
            if totalDuration <= 0 then return end

            local cumulative = 0
            for stage = 0, self.numStages - 1 do
                local stageDuration = GetUnitEmpowerStageDuration(self.unit, stage)
                if not stageDuration or stageDuration <= 0 then break end
                cumulative = cumulative + stageDuration

                -- Don't place marker after the last stage (it would be at the end of the bar)
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
            end
        end)
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

        -- [FIX] Un seul appel à UnitCastingInfo (deux appels successifs = données potentiellement
        -- incohérentes si le sort se termine entre les deux appels).
        local name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible = UnitCastingInfo(unitID)

        -- ===== Check channel / empowered =====
        if type(name) == "nil" then
            -- [FIX] Même chose : UnitChannelInfo appelé une seule fois.
            local chanName, _, chanTex, chanStart, chanEnd, _, chanNI, _, _, chanStages = UnitChannelInfo(unitID)
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
                end
            end
        end

        -- Nothing found → hide
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
        if self.spellText then self.spellText:SetFormattedText("%s", name) end
        if self.icon then self.icon:SetTexture(texture) end

        -- TWW: SetAlpha ACCEPTS secrets from C_CurveUtil
        local alpha = C_CurveUtil.EvaluateColorValueFromBoolean(notInterruptible, 1, 0)
        self.niOverlay:SetAlpha(alpha)

        -- Empower: show stage markers
        if bempowered then
            UpdateStageMarkers(self)
        else
            HideStageMarkers(self)
        end

        -- Latency (regular casts only)
        UpdateLatency(self)

        self:Show()
    end

    -- OnUpdate: bar progress + timer text
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
        -- Some spells fire SUCCEEDED then immediately start a channel/empower phase.
        -- Only hide if no active channel/empower follows.
        -- Re-check via CheckCast to avoid killing a newly started cast (race condition).
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            if castbar.channeling or castbar.empowered then
                -- A channel/empower is active: ignore SUCCEEDED (it's the initial cast completing)
                return
            end
            CheckCast(castbar, false)

        -- ===== STOP / FAILED / CHANNEL STOP / EMPOWER STOP =====
        -- Re-check via CheckCast: if a new cast already started, show it instead of hiding.
        -- This prevents the race where STOP(old) arrives after START(new).
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
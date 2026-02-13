-- =====================================
-- Elements/Castbar.lua — Castbar Element
-- =====================================

local UF_Elements = UF_Elements or {}

local TEXTURE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"

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
    -- Darker zone at the end of the bar showing network latency.
    -- Indicates the safe zone where you can start queuing the next spell.
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
    castbar.duration_obj = nil
    castbar.failstart = nil
    castbar._preview = false
    castbar._castStartMS = nil
    castbar._castEndMS = nil

    castbar:Hide()

    -- =====================================
    -- PREVIEW MODE (player only — shown when unlocked via /tm sr)
    -- Fills the bar, shows placeholder text/icon so the castbar is visible for dragging.
    -- =====================================

    function castbar:ShowPreview()
        self._preview = true
        self.casting = false
        self.channeling = false
        self.failstart = nil
        self.niOverlay:SetAlpha(0)

        -- Fill bar 100%, base color
        self:SetMinMaxValues(0, 100)
        self:SetValue(100)
        self:SetReverseFill(false)
        local bc = self._baseColor or { 0.8, 0.1, 0.1 }
        self:SetStatusBarColor(bc[1], bc[2], bc[3], 1)

        -- Placeholder text
        if self.spellText then self.spellText:SetText("Castbar") end
        if self.timerText then self.timerText:SetText("1.5") end

        -- Generic icon
        if self.icon then
            self.icon:SetTexture("Interface\\Icons\\Spell_Nature_Lightning")
        end

        -- Show latency preview (simulate ~60ms on a 1.5s cast ≈ 4% of bar)
        if self.latencyTex then
            if cbSettings.showLatency then
                local previewWidth = math.max(2, self:GetWidth() * 0.04)
                self.latencyTex:SetWidth(previewWidth)
                -- Refresh color
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
        -- Only hide if nothing is actively casting
        if not self.casting and not self.channeling and not self.failstart then
            self:Hide()
        end
    end

    -- =====================================
    -- LATENCY HELPER
    -- Computes the latency width from GetNetStats() and cast duration.
    -- Uses pcall because startTimeMS/endTimeMS may be secret values in TWW,
    -- though for the player unit they are typically regular numbers.
    -- =====================================

    local function UpdateLatency(self)
        if not self.latencyTex then return end
        if not cbSettings.showLatency then
            self.latencyTex:Hide()
            return
        end

        -- Only show during casting (not channeling — latency zone doesn't help there)
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

        -- latencyWidth = (latencyWorldMS / castDurationMS) * barPixelWidth
        -- pcall guards against secret value arithmetic failures
        local ok, result = pcall(function()
            local castDurationMS = endMS - startMS
            if castDurationMS <= 0 then return 0 end
            local _, _, _, latencyWorld = GetNetStats()
            local barWidth = self:GetWidth()
            return math.min(barWidth * 0.25, math.max(2, (latencyWorld / castDurationMS) * barWidth))
        end)

        if ok and result and result > 0 then
            -- Color: darker version of the base castbar color
            local bc = self._baseColor or { 0.8, 0.1, 0.1 }
            self.latencyTex:SetVertexColor(bc[1] * 0.35, bc[2] * 0.35, bc[3] * 0.35, 0.85)
            self.latencyTex:SetWidth(result)
            self.latencyTex:Show()
        else
            self.latencyTex:Hide()
        end
    end

    -- =====================================
    -- CASTBAR LOGIC (asTargetCastBar techniques)
    -- =====================================

    -- Unified check: auto-detect casting or channeling (like asTargetCastBar.check_casting)
    local function CheckCast(self, isInterrupt)
        local unitID = self.unit

        -- Handle interrupt display
        if isInterrupt then
            self.niOverlay:SetAlpha(0)
            if self.latencyTex then self.latencyTex:Hide() end
            local intCol = TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.castbarInterruptColor
            if intCol then
                self:SetStatusBarColor(intCol.r, intCol.g, intCol.b, 1)
            else
                self:SetStatusBarColor(0.1, 0.8, 0.1, 1)
            end
            if self.spellText then
                self.spellText:SetText(INTERRUPTED or "Interrompu")
            end
            self.casting = false
            self.channeling = false
            self.duration_obj = nil
            self._castStartMS = nil
            self._castEndMS = nil
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

        -- Check casting first (like asTargetCastBar)
        local bchannel = false
        local name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible
        local castInfo = UnitCastingInfo(unitID)
        if type(castInfo) ~= "nil" then
            name = castInfo
            _, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible = UnitCastingInfo(unitID)
        end

        -- If not casting, check channeling
        if type(name) == "nil" then
            local chanInfo = UnitChannelInfo(unitID)
            if type(chanInfo) ~= "nil" then
                name = chanInfo
                _, _, texture, startTimeMS, endTimeMS, _, notInterruptible = UnitChannelInfo(unitID)
                bchannel = true
            end
        end

        -- Nothing found → hide
        if type(name) == "nil" then
            self.casting = false
            self.channeling = false
            self.duration_obj = nil
            self._castStartMS = nil
            self._castEndMS = nil
            if self.latencyTex then self.latencyTex:Hide() end
            self:Hide()
            return
        end

        -- Get duration object for timer text
        local duration
        if bchannel then
            duration = UnitChannelDuration(unitID)
        else
            duration = UnitCastingDuration(unitID)
        end
        self.duration_obj = duration

        -- Store raw times for latency computation
        self._castStartMS = startTimeMS
        self._castEndMS = endTimeMS

        -- Update state
        self.casting = not bchannel
        self.channeling = bchannel
        self.failstart = nil

        -- TWW: SetMinMaxValues accepts secrets (startTimeMS, endTimeMS from API)
        self:SetMinMaxValues(startTimeMS, endTimeMS)
        self:SetReverseFill(bchannel)

        -- Reset base color (may have been green from interrupt)
        local bc = self._baseColor or { 0.8, 0.1, 0.1 }
        self:SetStatusBarColor(bc[1], bc[2], bc[3], 1)

        -- SetText/SetTexture are C-side, accept secrets
        if self.spellText then self.spellText:SetFormattedText("%s", name) end
        if self.icon then self.icon:SetTexture(texture) end

        -- TWW: SetAlpha ACCEPTS secrets from C_CurveUtil
        -- notInterruptible=true → 1 (grey overlay visible)
        -- notInterruptible=false → 0 (overlay hidden, red bar shows)
        local alpha = C_CurveUtil.EvaluateColorValueFromBoolean(notInterruptible, 1, 0)
        self.niOverlay:SetAlpha(alpha)

        -- Update latency indicator
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

        if not self.casting and not self.channeling then
            self:Hide()
            return
        end

        -- Progress: GetTime() * 1000 is non-secret, bar fill handled C-side
        -- Use ExponentialEaseOut like asTargetCastBar
        self:SetValue(GetTime() * 1000, Enum.StatusBarInterpolation.ExponentialEaseOut)

        -- Timer from stored duration object (param 0 for displayable value)
        if self.timerText and self.duration_obj then
            self.timerText:SetText(string.format("%.1f", self.duration_obj:GetRemainingDuration(0)))
        end
    end)

    -- Events — use RegisterUnitEvent to only fire for our specific unit
    -- Global RegisterEvent fires for ALL units, tainting Blizzard's secure frames
    local events = CreateFrame("Frame")
    events:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", unit)
    events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit)

    -- Register target/focus change events for initial cast detection
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

        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
            castbar.failstart = nil
            CheckCast(castbar, false)
        elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
            if castbar.casting or castbar.channeling then
                CheckCast(castbar, false)
            end
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            CheckCast(castbar, true)
        elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED"
            or event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            castbar.casting = false
            castbar.channeling = false
            castbar.duration_obj = nil
            castbar._castStartMS = nil
            castbar._castEndMS = nil
            if castbar.latencyTex then castbar.latencyTex:Hide() end
            if not castbar.failstart then
                castbar:Hide()
            end
        end
    end)

    castbar.eventFrame = events
    castbar:EnableMouse(false)

    return castbar
end

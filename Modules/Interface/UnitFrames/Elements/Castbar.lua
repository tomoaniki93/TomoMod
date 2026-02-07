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

    -- Base color: interruptible (red) — overlay handles grey when not interruptible
    castbar:SetStatusBarColor(0.8, 0.1, 0.1, 1)

    -- Position relative to parent
    local pos = cbSettings.position or { point = "TOP", relativePoint = "BOTTOM", x = 0, y = -6 }
    castbar:SetPoint(pos.point, parent, pos.relativePoint, pos.x, pos.y)

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
    niOverlay:SetColorTexture(0.5, 0.5, 0.5, 1)
    niOverlay:SetAlpha(0)
    niOverlay:Show()
    castbar.niOverlay = niOverlay

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

    castbar:Hide()

    -- =====================================
    -- CASTBAR LOGIC (asTargetCastBar techniques)
    -- =====================================

    -- Unified check: auto-detect casting or channeling (like asTargetCastBar.check_casting)
    local function CheckCast(self, isInterrupt)
        local unitID = self.unit

        -- Handle interrupt display
        if isInterrupt then
            self.niOverlay:SetAlpha(0)
            self:SetStatusBarColor(0.1, 0.8, 0.1, 1)
            if self.spellText then
                self.spellText:SetText(INTERRUPTED or "Interrompu")
            end
            self.casting = false
            self.channeling = false
            self.duration_obj = nil
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

        -- Update state
        self.casting = not bchannel
        self.channeling = bchannel
        self.failstart = nil

        -- TWW: SetMinMaxValues accepts secrets (startTimeMS, endTimeMS from API)
        self:SetMinMaxValues(startTimeMS, endTimeMS)
        self:SetReverseFill(bchannel)

        -- Reset base color to red (may have been green from interrupt)
        self:SetStatusBarColor(0.8, 0.1, 0.1, 1)

        -- SetText/SetTexture are C-side, accept secrets
        if self.spellText then self.spellText:SetFormattedText("%s", name) end
        if self.icon then self.icon:SetTexture(texture) end

        -- TWW: SetAlpha ACCEPTS secrets from C_CurveUtil
        -- notInterruptible=true → 1 (grey overlay visible)
        -- notInterruptible=false → 0 (overlay hidden, red bar shows)
        local alpha = C_CurveUtil.EvaluateColorValueFromBoolean(notInterruptible, 1, 0)
        self.niOverlay:SetAlpha(alpha)

        self:Show()
    end

    -- OnUpdate: bar progress + timer text
    castbar:SetScript("OnUpdate", function(self, elapsed)
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
            if not castbar.failstart then
                castbar:Hide()
            end
        end
    end)

    castbar.eventFrame = events
    castbar:EnableMouse(false)

    return castbar
end

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

        -- Icon border
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

    castbar:Hide()

    -- =====================================
    -- CASTBAR LOGIC (asTargetCastBar techniques)
    -- =====================================

    local function StartCast(self)
        local name, texture, startTimeMS, endTimeMS, notInterruptible
        local duration

        if self.channeling then
            local info = UnitChannelInfo(unit)
            if type(info) ~= "nil" then
                name = info
                local _, _, tex, sMS, eMS, _, ni = UnitChannelInfo(unit)
                texture = tex
                startTimeMS = sMS
                endTimeMS = eMS
                notInterruptible = ni
            end
            if type(name) ~= "nil" then
                duration = UnitChannelDuration(unit)
            end
        else
            local info = UnitCastingInfo(unit)
            if type(info) ~= "nil" then
                name = info
                local _, _, tex, sMS, eMS, _, _, ni = UnitCastingInfo(unit)
                texture = tex
                startTimeMS = sMS
                endTimeMS = eMS
                notInterruptible = ni
            end
            if type(name) ~= "nil" then
                duration = UnitCastingDuration(unit)
            end
        end

        if type(name) == "nil" then
            self:Hide()
            return
        end

        -- TWW: SetMinMaxValues accepts secrets (startTimeMS, endTimeMS)
        -- SetValue(GetTime() * 1000) in OnUpdate is non-secret — bar fills C-side
        self:SetMinMaxValues(startTimeMS, endTimeMS)
        self:SetReverseFill(self.channeling)

        -- Store duration object for timer (GetRemainingDuration(0) is displayable)
        self.duration_obj = duration

        -- SetText/SetTexture are C-side, accept secrets
        if self.spellText then self.spellText:SetFormattedText("%s", name) end
        if self.icon then self.icon:SetTexture(texture) end

        -- TWW: SetAlpha ACCEPTS secrets from C_CurveUtil
        -- EvaluateColorValueFromBoolean(condition, trueValue, falseValue):
        -- notInterruptible=true → 1 (grey overlay visible)
        -- notInterruptible=false → 0 (overlay hidden, red bar shows)
        local alpha = C_CurveUtil.EvaluateColorValueFromBoolean(notInterruptible, 1, 0)
        self.niOverlay:SetAlpha(alpha)

        self:Show()
    end

    local function StopCast(self)
        self.casting = false
        self.channeling = false
        self.duration_obj = nil
        self:Hide()
    end

    -- OnUpdate: SetValue with non-secret GetTime(), timer from stored duration_obj
    castbar:SetScript("OnUpdate", function(self, elapsed)
        if not self.casting and not self.channeling then
            self:Hide()
            return
        end

        -- Progress: GetTime() * 1000 is non-secret, bar fill handled C-side
        self:SetValue(GetTime() * 1000)

        -- Timer from stored duration object (param 0 for displayable value)
        if self.timerText and self.duration_obj then
            self.timerText:SetText(string.format("%.1f", self.duration_obj:GetRemainingDuration(0)))
        end
    end)

    -- Events
    local events = CreateFrame("Frame")
    events:RegisterEvent("UNIT_SPELLCAST_START")
    events:RegisterEvent("UNIT_SPELLCAST_STOP")
    events:RegisterEvent("UNIT_SPELLCAST_FAILED")
    events:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    events:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
    events:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
    events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

    events:SetScript("OnEvent", function(self, event, eventUnit)
        if eventUnit ~= unit then return end

        if event == "UNIT_SPELLCAST_START" then
            castbar.casting = true
            castbar.channeling = false
            StartCast(castbar)
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
            castbar.casting = false
            castbar.channeling = true
            StartCast(castbar)
        elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
            -- Mid-cast state change: re-read notInterruptible and update overlay
            if castbar.casting or castbar.channeling then
                StartCast(castbar)
            end
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            -- Green flash
            castbar.niOverlay:SetAlpha(0)
            castbar:SetStatusBarColor(0.1, 0.8, 0.1, 1)
            if castbar.spellText then
                castbar.spellText:SetText(INTERRUPTED or "Interrompu")
            end
            castbar.casting = false
            castbar.channeling = false
            castbar.duration_obj = nil
            C_Timer.After(0.4, function()
                castbar:SetStatusBarColor(0.8, 0.1, 0.1, 1)
                castbar:Hide()
            end)
        elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED"
            or event == "UNIT_SPELLCAST_SUCCEEDED" then
            StopCast(castbar)
        elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            StopCast(castbar)
        end
    end)

    castbar.eventFrame = events
    castbar:EnableMouse(false)

    return castbar
end

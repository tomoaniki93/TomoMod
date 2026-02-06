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
    castbar:SetMinMaxValues(0, 1)
    castbar:SetValue(0)

    local color = cbSettings.color or { r = 1, g = 0.7, b = 0 }
    castbar:SetStatusBarColor(color.r, color.g, color.b, 1)

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

    -- Spark
    local spark = castbar:CreateTexture(nil, "OVERLAY")
    spark:SetSize(4, cbSettings.height + 4)
    spark:SetColorTexture(1, 1, 1, 0.6)
    spark:SetBlendMode("ADD")
    castbar.spark = spark

    -- State
    castbar.unit = unit
    castbar.casting = false
    castbar.channeling = false
    castbar.startTime = 0
    castbar.endTime = 0

    castbar:Hide()

    -- Helper frame to decode secret boolean (SetShown=C-side accepts secret, IsShown returns non-secret)
    castbar._notInterruptHelper = CreateFrame("Frame", nil, castbar)
    castbar._notInterruptHelper:SetSize(1, 1)
    castbar._notInterruptHelper:SetAlpha(0)
    castbar._notInterruptHelper:EnableMouse(false)
    castbar._notInterruptHelper:Hide()

    -- =====================================
    -- CASTBAR LOGIC
    -- =====================================

    local function StartCast(self)
        local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellID
        local duration

        if self.channeling then
            local info = UnitChannelInfo(unit)
            if info then
                name = info
                local _, _, tex, sMS, eMS, _, ni = UnitChannelInfo(unit)
                texture = tex
                notInterruptible = ni
            end
            if name then
                duration = UnitChannelDuration(unit)
            end
        else
            local info = UnitCastingInfo(unit)
            if info then
                name = info
                local _, _, tex, sMS, eMS, _, _, ni = UnitCastingInfo(unit)
                texture = tex
                notInterruptible = ni
            end
            if name then
                duration = UnitCastingDuration(unit)
            end
        end

        if not name or not duration then
            self:Hide()
            return
        end

        -- Use TWW C-side SetTimerDuration — no Lua math on secret numbers
        if self.channeling then
            self:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
        else
            self:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.ElapsedTime)
        end

        -- SetText/SetTexture are C-side, accept secret values
        if self.spellText then self.spellText:SetFormattedText("%s", name) end
        if self.icon then self.icon:SetTexture(texture) end

        -- Decode secret boolean: SetShown (C-side, accepts secret) → IsShown (returns non-secret)
        castbar._notInterruptHelper:SetShown(notInterruptible)
        if castbar._notInterruptHelper:IsShown() then
            -- Not interruptible → Grey
            self:SetStatusBarColor(0.5, 0.5, 0.5, 1)
        else
            -- Interruptible → Red
            self:SetStatusBarColor(0.8, 0.1, 0.1, 1)
        end

        self:Show()
    end

    local function StopCast(self)
        self.casting = false
        self.channeling = false
        self:Hide()
    end

    -- Update on timer — use C-side GetTimerDuration (no secret number arithmetic)
    castbar._checkElapsed = 0
    castbar:SetScript("OnUpdate", function(self, elapsed)
        if not self.casting and not self.channeling then
            self:Hide()
            return
        end

        local durObj = self:GetTimerDuration()
        if not durObj then return end

        local remaining = durObj:GetRemainingDuration()

        -- SetFormattedText is C-side, accepts secret numbers
        if self.timerText then
            self.timerText:SetFormattedText("%.1f", remaining)
        end

        -- TWW: remaining and total are secret numbers — can't do Lua arithmetic
        -- for spark position (remaining/total). Hide spark.
        if self.spark then
            self.spark:Hide()
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
            castbar._interruptible = true
            castbar.casting = true
            castbar.channeling = false
            StartCast(castbar)
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
            castbar._interruptible = true
            castbar.casting = false
            castbar.channeling = true
            StartCast(castbar)
        elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
            castbar._interruptible = true
            if castbar:IsShown() then
                castbar:SetStatusBarColor(0.8, 0.1, 0.1, 1)
            end
        elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
            castbar._interruptible = false
            if castbar:IsShown() then
                castbar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
            end
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            -- Green flash
            castbar:SetStatusBarColor(0.1, 0.8, 0.1, 1)
            if castbar.spellText then
                castbar.spellText:SetText(INTERRUPTED or "Interrompu")
            end
            castbar.casting = false
            castbar.channeling = false
            C_Timer.After(0.4, function()
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
    castbar:EnableMouse(false)  -- Let clicks pass through

    return castbar
end

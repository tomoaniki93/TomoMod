-- =====================================
-- Modules/Housing/EditorClock.lua
-- Adapté de Plumber/HouseEditor_Clock.lua
--
-- Ce que fait ce module :
--   - Affiche une horloge (analogique ou digitale) au-dessus du bouton
--     "quitter l'éditeur" quand l'éditeur de maison est actif.
--   - Comptabilise le temps passé en mode éditeur (session + total).
--   - Accessible via tooltip sur l'horloge.
-- =====================================

TomoMod_Housing = TomoMod_Housing or {}
local H = TomoMod_Housing
local L = TomoMod_L

local Controller = H.Controller
if not Controller then return end

-- Any-mode handler: alive whenever the editor is active (regardless of sub-mode)
local Handler = Controller.CreateModeHandler("AnyMode")
Handler.dbKey = "clock"
H.Handlers = H.Handlers or {}
H.Handlers.Clock = Handler

-- =====================================
-- TIME COUNTER (session & lifetime)
-- Persisted across reloads via TomoModDB.housing.clock_*
-- =====================================

local Counter = {}
Counter.sessionTime  = 0
Counter.lifetimeTime = 0
Counter._loaded      = false

function Counter:LoadFromDB()
    if self._loaded then return end
    self._loaded = true
    local db = TomoModDB and TomoModDB.housing
    if db then
        self.lifetimeTime = db.clock_totalTime or 0
        -- Session resets every login
        self.sessionTime = 0
    end
end

function Counter:OnTimeElapsed(elapsed)
    self.sessionTime  = self.sessionTime  + elapsed
    self.lifetimeTime = self.lifetimeTime + elapsed
end

function Counter:Save()
    local db = TomoModDB and TomoModDB.housing
    if db then
        db.clock_totalTime = math.floor(self.lifetimeTime)
    end
end

function Counter:GetSessionText()
    return H.API.SecondsToTime(math.floor(self.sessionTime), true, true)
end

function Counter:GetLifetimeText()
    return H.API.SecondsToTime(math.floor(self.lifetimeTime), true, true)
end

-- =====================================
-- CLOCK UI
-- =====================================

local ClockUIMixin = {}

local TIME_FORMAT_12 = "%d:%02d"
local TIME_FORMAT_24 = "%02d:%02d"

function ClockUIMixin:OnShow()
    Counter:LoadFromDB()
    self:Refresh()
    self.t = 0
    self:SetScript("OnUpdate", self.OnUpdate)
end

function ClockUIMixin:OnHide()
    self.t = 0
    self:SetScript("OnUpdate", nil)
    Counter:Save()
end

function ClockUIMixin:Refresh()
    self.useLocalTime    = C_CVar and C_CVar.GetCVarBool and C_CVar.GetCVarBool("timeMgrUseLocalTime") or false
    self.useMilitaryTime = C_CVar and C_CVar.GetCVarBool and C_CVar.GetCVarBool("timeMgrUseMilitaryTime") or false

    local db = TomoModDB and TomoModDB.housing
    local isAnalog = db and db.clock_analog
    self:SetAnalogMode(isAnalog and true or false)
    self:UpdateTime()
end

function ClockUIMixin:UpdateTime()
    local hour, minute
    if self.useLocalTime then
        hour   = tonumber(date("%H"))
        minute = tonumber(date("%M"))
    else
        hour, minute = GetGameTime()
    end
    self:SetTime(hour, minute)
end

function ClockUIMixin:OnUpdate(elapsed)
    self.t = (self.t or 0) + elapsed
    Counter:OnTimeElapsed(elapsed)
    if self.t >= 5 then
        self.t = 0
        self:UpdateTime()
        Counter:Save()
    end
end

function ClockUIMixin:SetTime(hour, minute)
    if self.isAnalogMode then
        self:SetTime_Analog(hour, minute)
    else
        self:SetTime_Digital(hour, minute)
    end
end

function ClockUIMixin:SetTime_Analog(hour, minute)
    if hour > 12 then hour = hour - 12 end
    local rad1 = -2 * math.pi * (hour + minute/60) / 12
    local rad2 = -2 * math.pi * minute / 60
    if self.HourHand then self.HourHand:SetRotation(rad1) end
    if self.MinuteHand then self.MinuteHand:SetRotation(rad2) end
end

function ClockUIMixin:SetTime_Digital(hour, minute)
    self.Digits:SetText(TIME_FORMAT_24:format(hour, minute))
end

function ClockUIMixin:SetAnalogMode(state)
    self.isAnalogMode = state
    if self.MinuteHand then self.MinuteHand:SetShown(state) end
    if self.HourHand   then self.HourHand:SetShown(state)   end
    if self.Face       then self.Face:SetShown(state)        end
    if self.DigitalBg  then self.DigitalBg:SetShown(not state) end
    if self.Digits     then self.Digits:SetShown(not state) end
end

function ClockUIMixin:ShowTooltip()
    local tooltip = GameTooltip
    tooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, 2)
    local title = (L and L["housing_clock_title"]) or "TomoMod — Clock"
    tooltip:SetText(title, 1, 1, 1)

    tooltip:AddLine(" ")
    tooltip:AddLine((L and L["housing_clock_time"]) or TIMEMANAGER_TOOLTIP_TITLE or "Time", 1, 1, 1)
    local label, text
    if self.useLocalTime then
        label = (L and L["housing_clock_local"]) or TIMEMANAGER_TOOLTIP_LOCALTIME or "Local"
        text  = GameTime_GetLocalTime and GameTime_GetLocalTime(true) or date("%H:%M")
    else
        label = (L and L["housing_clock_realm"]) or TIMEMANAGER_TOOLTIP_REALMTIME or "Realm"
        text  = GameTime_GetGameTime and GameTime_GetGameTime(true) or ""
    end
    tooltip:AddDoubleLine(label, text, 1, 0.82, 0, 1, 1, 1)

    tooltip:AddLine(" ")
    tooltip:AddLine((L and L["housing_clock_time_spent"]) or "Time spent in editor", 1, 1, 1)
    tooltip:AddDoubleLine((L and L["housing_clock_session"]) or "Session:",  Counter:GetSessionText(),  1, 0.82, 0, 1, 1, 1)
    tooltip:AddDoubleLine((L and L["housing_clock_total"])   or "Total:",    Counter:GetLifetimeText(), 1, 0.82, 0, 1, 1, 1)

    tooltip:AddLine(" ")
    tooltip:AddLine((L and L["housing_clock_rightclick"]) or "Right-click to toggle analog/digital", 0.05, 0.82, 0.62, true)
    tooltip:Show()
end

function ClockUIMixin:OnEnter()
    self:ShowTooltip()
    self:UpdateTime()
end

function ClockUIMixin:OnLeave()
    GameTooltip:Hide()
    Counter:Save()
end

function ClockUIMixin:OnClick(button)
    if button == "RightButton" then
        local db = TomoModDB and TomoModDB.housing
        if db then
            db.clock_analog = not db.clock_analog
            self:Refresh()
            -- Refresh tooltip if still hovered
            if self:IsMouseOver() then self:ShowTooltip() end
        end
    end
end

-- =====================================
-- HANDLER LIFECYCLE
-- =====================================

function Handler:Init()
    self.Init = nil

    if not (HousingControlsFrame and HousingControlsFrame.OwnerControlFrame) then
        -- Blizzard_HouseEditor not yet loaded; retry later
        return
    end

    local parent = HousingControlsFrame.OwnerControlFrame
    local anchor = parent.HouseEditorButton or parent

    local f = CreateFrame("Button", nil, parent)
    self.ClockFrame = f
    f:Hide()
    f:SetFrameLevel(100)
    f:RegisterForClicks("RightButtonUp")
    f:SetSize(72, 72)
    f:SetPoint("TOP", anchor, "BOTTOM", 0, -4)
    Mixin(f, ClockUIMixin)

    local TEXTURE_PATH = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Housing\\"

    -- Face — analog clock dial with hour/minute markers
    f.Face = f:CreateTexture(nil, "BACKGROUND")
    f.Face:SetSize(72, 72)
    f.Face:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.Face:SetTexture(TEXTURE_PATH .. "clock_face")

    -- Digital background — rounded rectangle (shown in digital mode only)
    f.DigitalBg = f:CreateTexture(nil, "BACKGROUND")
    f.DigitalBg:SetSize(72, 36)
    f.DigitalBg:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.DigitalBg:SetTexture(TEXTURE_PATH .. "clock_digital")
    f.DigitalBg:Hide()

    -- Hands (textured, pivot at center of 64x64 — hand extends upward)
    f.HourHand = f:CreateTexture(nil, "OVERLAY")
    f.HourHand:SetSize(64, 64)
    f.HourHand:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.HourHand:SetTexture(TEXTURE_PATH .. "clock_hand_hour")

    f.MinuteHand = f:CreateTexture(nil, "OVERLAY")
    f.MinuteHand:SetSize(64, 64)
    f.MinuteHand:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.MinuteHand:SetTexture(TEXTURE_PATH .. "clock_hand_minute")

    -- Accent centre dot (teal) — drawn on top of hands
    local dot = f:CreateTexture(nil, "OVERLAY", nil, 1)
    dot:SetSize(6, 6)
    dot:SetPoint("CENTER", f, "CENTER", 0, 0)
    dot:SetColorTexture(0.05, 0.82, 0.62, 1)

    -- Digital fallback text (Poppins for consistency)
    local FONT_DIGITAL = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
    f.Digits = f:CreateFontString(nil, "OVERLAY")
    f.Digits:SetFont(FONT_DIGITAL, 18, "OUTLINE")
    f.Digits:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.Digits:SetTextColor(0.88, 0.82, 0.72)
    f.Digits:Hide()

    f:SetScript("OnShow",  f.OnShow)
    f:SetScript("OnHide",  f.OnHide)
    f:SetScript("OnEnter", f.OnEnter)
    f:SetScript("OnLeave", f.OnLeave)
    f:SetScript("OnClick", f.OnClick)

    f:Refresh()
    f:Show()
end

function Handler:BlizzardHouseEditorLoaded()
    if self.activated and self.Init then self:Init() end
end

function Handler:OnActivated()
    if self.ClockFrame then self.ClockFrame:Show() end
end

function Handler:OnDeactivated()
    if self.ClockFrame then self.ClockFrame:Hide() end
    Counter:Save()
end
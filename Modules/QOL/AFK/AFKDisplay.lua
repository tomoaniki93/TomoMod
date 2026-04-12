-- =====================================
-- AFK/AFKDisplay.lua — AFK Display Screen
-- Inspired by TomoUI's AFKDisplay module
-- Shows a stylized screen with player model, chat counters,
-- and elapsed timer when the player goes AFK.
-- =====================================

TomoMod_AFKDisplay = TomoMod_AFKDisplay or {}
local AFK = TomoMod_AFKDisplay

local ADDON_FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ACCENT_R, ACCENT_G, ACCENT_B = 0.047, 0.824, 0.624  -- TomoMod teal

-- =====================================
-- LOCAL REFERENCES
-- =====================================
local C_Timer = C_Timer
local InCombatLockdown = InCombatLockdown
local UnitIsAFK = UnitIsAFK
local UnitSex = UnitSex
local UnitRace = UnitRace
local UnitClass = UnitClass
local UnitLevel = UnitLevel
local UnitPVPName = UnitPVPName
local GetRealmName = GetRealmName
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local MoveViewLeftStart = MoveViewLeftStart
local MoveViewLeftStop = MoveViewLeftStop
local SetCursor = SetCursor
local WorldFrame = WorldFrame
local select, format, floor = select, string.format, math.floor

-- =====================================
-- STATE
-- =====================================
local display        -- main frame
local modelFrame     -- 3D model container
local afkTimer       -- elapsed seconds
local whisperCount   = 0
local guildCount     = 0
local whisperMessages = {}
local guildMessages   = {}
local eventFrame      -- event listener frame
local Y_POSITION      = 100

-- =====================================
-- RACE → MODEL Y-OFFSETS
-- (prevents model clipping per race/gender)
-- =====================================
local RaceOffsets = {
    Human              = { Male = { v = -0.4, hv = -0.3 }, Female = { v = -0.4, hv = -0.4 } },
    KulTiran           = { Male = { v = -0.4, hv = -0.3 }, Female = { v = -0.4, hv = -0.4 } },
    Dwarf              = { Male = { v = -0.3, hv = -0.2 }, Female = { v = -0.4, hv = -0.3 } },
    DarkIronDwarf      = { Male = { v = -0.3, hv = -0.2 }, Female = { v = -0.4, hv = -0.3 } },
    NightElf           = { Male = { v = -0.5, hv = -0.6 }, Female = { v = -0.4, hv = -0.6 } },
    VoidElf            = { Male = { v = -0.5, hv = -0.6 }, Female = { v = -0.4, hv = -0.6 } },
    Gnome              = { Male = { v = -0.3, hv = -0.3 }, Female = { v = -0.3, hv = -0.3 } },
    Mechagnome         = { Male = { v = -0.3, hv = -0.3 }, Female = { v = -0.3, hv = -0.3 } },
    Draenei            = { Male = { v = -0.4, hv = -0.7 }, Female = { v = -0.5, hv = -0.7 } },
    LightforgedDraenei = { Male = { v = -0.4, hv = -0.7 }, Female = { v = -0.5, hv = -0.7 } },
    Worgen             = { Male = { v = -0.4, hv = -0.4 }, Female = { v = -0.4, hv = -0.4 } },
    Pandaren           = { Male = { v = -0.6, hv = -0.9 }, Female = { v = -0.4, hv = -0.3 } },
    Orc                = { Male = { v = -0.4, hv = -0.4 }, Female = { v = -0.5, hv = -0.4 } },
    MagharOrc          = { Male = { v = -0.4, hv = -0.4 }, Female = { v = -0.5, hv = -0.4 } },
    Scourge            = { Male = { v = -0.4, hv = -0.6 }, Female = { v = -0.4, hv = -0.4 } },
    Tauren             = { Male = { v = -0.3, hv = -0.4 }, Female = { v = -0.6, hv = -0.4 } },
    HighmountainTauren = { Male = { v = -0.3, hv = -0.4 }, Female = { v = -0.6, hv = -0.4 } },
    Troll              = { Male = { v = -0.4, hv = -0.2 }, Female = { v = -0.3, hv = -0.5 } },
    ZandalariTroll     = { Male = { v = -0.4, hv = -0.2 }, Female = { v = -0.6, hv = -0.5 } },
    BloodElf           = { Male = { v = -0.5, hv = -0.8 }, Female = { v = -0.4, hv = -0.9 } },
    Nightborne         = { Male = { v = -0.5, hv = -0.6 }, Female = { v = -0.4, hv = -0.6 } },
    Goblin             = { Male = { v = -0.3, hv = -0.3 }, Female = { v = -0.3, hv = -0.3 } },
    Vulpera            = { Male = { v = -0.3, hv = -0.3 }, Female = { v = -0.3, hv = -0.4 } },
    Dracthyr           = { Male = { v = -0.1, hv = -0.4 }, Female = { v = -0.1, hv = -0.4 } },
    EarthenDwarf       = { Male = { v = -0.3, hv = -0.2 }, Female = { v = -0.4, hv = -0.3 } },
}

-- =====================================
-- HELPERS
-- =====================================

local function GetSettings()
    return TomoModDB and TomoModDB.afkDisplay
end

local function GetRaceGenderKey()
    local gender = UnitSex("player")
    local genderKey = (gender == 2) and "Male" or "Female"
    local race = (select(2, UnitRace("player"))):gsub("%s+", "")
    return race, genderKey
end

local function GetModelOffset(hovering)
    local race, genderKey = GetRaceGenderKey()
    local raceData = RaceOffsets[race]
    if not raceData then return -0.4 end
    local genderData = raceData[genderKey]
    if not genderData then return -0.4 end
    return hovering and genderData.hv or genderData.v
end

-- =====================================
-- MODEL ANIMATION
-- =====================================
local Animator = {}

function Animator:TransitionValue()
    local _, _, yValue = Animator.model:GetPosition()

    if Animator.step > 0 then
        if yValue >= Animator.endValue then
            Animator.model:SetPosition(-0.3, 0, Animator.endValue)
            return
        end
    else
        if yValue <= Animator.endValue then
            Animator.model:SetPosition(-0.3, 0, Animator.endValue)
            return
        end
    end

    Animator.model:SetPosition(-0.3, 0, yValue + Animator.step)
    C_Timer.After(0.01, Animator.TransitionValue)
end

local function PositionModel(hovering, falling)
    if not modelFrame then return end
    local value = GetModelOffset(hovering)
    local model = modelFrame.model

    model:SetPoint("BOTTOM")

    if not falling then
        model:SetPosition(-0.3, 0, value)
        return
    end

    local _, _, yValue = model:GetPosition()
    local difference = value - yValue

    Animator.endValue = value
    Animator.model = model

    if difference > 0 then
        Animator.step = 0.03
        C_Timer.After(0.01, Animator.TransitionValue)
    elseif difference < 0 then
        Animator.step = -0.03
        C_Timer.After(0.01, Animator.TransitionValue)
    else
        model:SetPosition(-0.3, 0, value)
    end
end

local function StartFalling()
    if not modelFrame then return end

    local point, relativeFrame, relativePoint, xOffset, yOffset = modelFrame:GetPoint()

    if yOffset > Y_POSITION then
        modelFrame:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset - 10)
        C_Timer.After(0.01, StartFalling)
    else
        if yOffset < Y_POSITION then
            modelFrame:SetPoint(point, relativeFrame, relativePoint, xOffset, Y_POSITION)
            PositionModel(nil, true)
        end
        modelFrame.model:SetAnimation(39)
        modelFrame.model.dragging = nil
    end
end

local function StartRotating()
    if not modelFrame or not modelFrame.model.dragging then return end

    local scaledScreenWidth = UIParent:GetWidth() * UIParent:GetScale()
    local modelPoint = modelFrame:GetLeft() + (modelFrame:GetWidth() / 2)
    local rotation = (scaledScreenWidth - modelPoint) - (scaledScreenWidth * 0.5)
    modelFrame.model:SetFacing(rotation / 1000)

    local justify = display.nameText:GetJustifyH()

    if modelPoint > (scaledScreenWidth * 0.5) then
        if justify == "RIGHT" then
            display.nameText:SetJustifyH("LEFT")
            display.nameText:ClearAllPoints()
            display.nameText:SetPoint("TOPLEFT", display, "TOPLEFT", 100, -14)
        end
    else
        if justify == "LEFT" then
            display.nameText:SetJustifyH("RIGHT")
            display.nameText:ClearAllPoints()
            display.nameText:SetPoint("TOPRIGHT", -100, -14)
        end
    end

    C_Timer.After(0.01, StartRotating)
end

-- =====================================
-- PLAYER MODEL CREATION
-- =====================================
local function CreatePlayerModel()
    local settings = GetSettings()
    local scale = settings and settings.modelScale or 1.0

    local frame = CreateFrame("Frame", nil, display)
    frame:SetSize(200, 500 * scale)
    frame:SetPoint("BOTTOMLEFT", display, "BOTTOMLEFT", 100, Y_POSITION)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    frame.model = CreateFrame("PlayerModel", nil, frame)
    frame.model:SetSize(600 * scale, 700 * scale)
    frame.model:SetUnit("player")
    frame.model:SetFacing(0.4)

    frame:SetScript("OnMouseUp", function(self)
        self.model:SetAnimation(8)
    end)

    frame:SetScript("OnEnter", function()
        SetCursor("Interface\\CURSOR\\UI-Cursor-Move.blp")
    end)

    frame.model:SetScript("OnAnimFinished", function(self)
        if self.dragging then
            self:SetAnimation(38)
        else
            self:SetAnimation(0)
        end
    end)

    frame:HookScript("OnDragStart", function(self)
        self:SetClampedToScreen(true)
        self.model.dragging = true
        self.model:SetAnimation(38)
        PositionModel(true)
        StartRotating()
    end)

    frame:HookScript("OnDragStop", function(self)
        self:SetClampedToScreen(false)
        local left = self:GetLeft()
        local bottom = self:GetBottom()
        self:ClearAllPoints()
        self:SetPoint("BOTTOMLEFT", display, "BOTTOMLEFT", left, bottom)
        StartFalling()
    end)

    return frame
end

-- =====================================
-- TIMER
-- =====================================
local function StartTimer()
    if not display or not display:IsShown() then return end

    afkTimer = (afkTimer or 0)
    local minutes = floor(afkTimer / 60) % 60
    local seconds = afkTimer % 60
    display.timeText:SetText(format("%.2d:%.2d", minutes, seconds))
    afkTimer = afkTimer + 1

    C_Timer.After(1, StartTimer)
end

-- =====================================
-- CHAT MESSAGE TRACKING
-- =====================================
local function OnChatMessage(event, message, sender, ...)
    if not display or not display:IsShown() then return end

    if event == "CHAT_MSG_GUILD" then
        guildCount = guildCount + 1
        display.rightBtn:SetText(format("Guild: %d", guildCount))
    else
        whisperCount = whisperCount + 1
        display.leftBtn:SetText(format("Whispers: %d", whisperCount))
    end
end

local function ResetChatCounters()
    whisperCount = 0
    guildCount = 0
    whisperMessages = {}
    guildMessages = {}
    if display then
        display.leftBtn:SetText("Whispers: 0")
        display.rightBtn:SetText("Guild: 0")
    end
end

-- =====================================
-- DISPLAY CREATION
-- =====================================
local function CreateDisplay()
    if display then return display end

    local f = CreateFrame("Frame", "TomoMod_AFKDisplayFrame", WorldFrame)
    f:SetPoint("BOTTOMLEFT", WorldFrame, "BOTTOMLEFT", 0, -100)
    f:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT", 0, -100)
    f:SetHeight(150)
    f:SetFrameStrata("FULLSCREEN")

    -- Background gradient
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0, 0, 0, 0.85)

    -- Top accent line
    f.accent = f:CreateTexture(nil, "ARTWORK")
    f.accent:SetHeight(2)
    f.accent:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    f.accent:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.accent:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 1)

    -- Logo (centered above the accent line)
    f.logo = f:CreateTexture(nil, "OVERLAY")
    f.logo:SetTexture("Interface\\AddOns\\TomoMod\\Assets\\Textures\\AFK\\Logo")
    f.logo:SetSize(400, 400)
    f.logo:SetPoint("BOTTOM", f.accent, "TOP", 0, 4)

    -- Timer text
    f.timeText = f:CreateFontString(nil, "OVERLAY")
    f.timeText:SetFont(ADDON_FONT, 22, "OUTLINE")
    f.timeText:SetPoint("TOP", 0, -16)
    f.timeText:SetWidth(120)
    f.timeText:SetTextColor(1, 1, 1)

    -- Player name / info
    f.nameText = f:CreateFontString(nil, "OVERLAY")
    f.nameText:SetFont(ADDON_FONT, 12, "OUTLINE")
    f.nameText:SetJustifyH("RIGHT")
    f.nameText:SetPoint("TOPRIGHT", -100, -14)
    f.nameText:SetTextColor(0.9, 0.9, 0.9)

    -- Whisper counter (left of timer)
    f.leftBtn = CreateFrame("Button", nil, f)
    f.leftBtn:SetSize(120, 30)
    f.leftBtn:SetPoint("RIGHT", f.timeText, "LEFT", -20, 0)
    f.leftBtn:SetNormalFontObject("GameFontHighlight")
    f.leftBtn:SetDisabledFontObject("GameFontDisable")
    f.leftBtn:SetHighlightFontObject("GameFontNormal")
    f.leftBtn:SetText("Whispers: 0")

    -- Guild counter (right of timer)
    f.rightBtn = CreateFrame("Button", nil, f)
    f.rightBtn:SetSize(120, 30)
    f.rightBtn:SetPoint("LEFT", f.timeText, "RIGHT", 20, 0)
    f.rightBtn:SetNormalFontObject("GameFontHighlight")
    f.rightBtn:SetDisabledFontObject("GameFontDisable")
    f.rightBtn:SetHighlightFontObject("GameFontNormal")
    f.rightBtn:SetText("Guild: 0")

    display = f
    return f
end

-- =====================================
-- SHOW / HIDE AFK DISPLAY
-- =====================================
local function SetAFKDisplayShown(show)
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    -- Guard: never show during combat, auction house, or movie
    if InCombatLockdown()
        or (_G.AuctionFrame and _G.AuctionFrame:IsVisible())
        or (_G.MovieFrame and _G.MovieFrame:IsShown()) then
        if display then display:Hide() end
        return
    end

    if show then
        -- Hide UIParent and show AFK display
        UIParent:Hide()

        if settings.rotateCamera then
            MoveViewLeftStart(0.01)
        end

        if not display then
            CreateDisplay()
        end

        if settings.playerModel and not modelFrame then
            modelFrame = CreatePlayerModel()
        end

        -- Update player info
        local specText = ""
        if GetSpecialization and GetSpecializationInfo then
            local specIndex = GetSpecialization()
            if specIndex then
                specText = (select(2, GetSpecializationInfo(specIndex)) or "") .. " "
            end
        end

        local _, classFile = UnitClass("player")
        local classColor = RAID_CLASS_COLORS[classFile]
        local className = select(1, UnitClass("player"))
        local coloredClass = classColor
            and format("|cff%02x%02x%02x%s%s|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, specText, className)
            or (specText .. className)

        local nameStr = format("%s - %s\nLevel %d, %s",
            UnitPVPName("player") or "",
            GetRealmName() or "",
            UnitLevel("player") or 0,
            coloredClass)

        display.nameText:SetText(nameStr)
        display:Show()

        PositionModel()
        ResetChatCounters()
        afkTimer = 0
        StartTimer()
    else
        -- Show UIParent and hide AFK display
        UIParent:Show()

        if settings.rotateCamera then
            MoveViewLeftStop()
        end

        if display then
            display:Hide()
        end
    end
end

-- =====================================
-- EVENT HANDLING
-- =====================================
local function OnEvent(self, event, arg1, ...)
    if event == "PLAYER_FLAGS_CHANGED" then
        if arg1 ~= "player" then return end
        local settings = GetSettings()
        if not settings or not settings.enabled then return end
        SetAFKDisplayShown(UnitIsAFK("player"))

    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat — always hide
        SetAFKDisplayShown(false)

    elseif event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_BN_WHISPER" or event == "CHAT_MSG_GUILD" then
        OnChatMessage(event, ...)
    end
end

-- =====================================
-- PUBLIC API
-- =====================================

function AFK.Initialize()
    local settings = GetSettings()
    if not settings then return end
    if not settings.enabled then return end

    if eventFrame then return end -- already initialized

    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
    eventFrame:RegisterEvent("CHAT_MSG_BN_WHISPER")
    eventFrame:RegisterEvent("CHAT_MSG_GUILD")
    eventFrame:SetScript("OnEvent", OnEvent)

    -- Safety: if UIParent shows, hide AFK display
    UIParent:HookScript("OnShow", function()
        SetAFKDisplayShown(false)
    end)
end

function AFK.SetEnabled(enabled)
    local settings = GetSettings()
    if not settings then return end

    settings.enabled = enabled

    if enabled then
        if not eventFrame then
            AFK.Initialize()
        end
    else
        SetAFKDisplayShown(false)
        if eventFrame then
            eventFrame:UnregisterAllEvents()
            eventFrame = nil
        end
    end
end

function AFK.Toggle()
    local settings = GetSettings()
    if settings then
        AFK.SetEnabled(not settings.enabled)
    end
end

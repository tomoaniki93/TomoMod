-- =====================================
-- CombatResTracker.lua
-- Combat Resurrection charge tracker + death count
-- + Mythic+ rating display
-- Overlay icon — /tm cr pour lock/unlock
-- =====================================

TomoMod_CombatResTracker = TomoMod_CombatResTracker or {}
local CRT = TomoMod_CombatResTracker

-- =====================================
-- CONSTANTES
-- =====================================
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local BORDER_TEX = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Nameplates\\border.png"
local BORDER_CORNER = 4
local FLAT_TEX = "Interface\\Buttons\\WHITE8x8"

-- Combat Res spell IDs
local BREZ_SPELLS = {
    [20484]  = true, -- Rebirth (Druid)
    [20707]  = true, -- Soulstone (Warlock)
    [61999]  = true, -- Raise Ally (Death Knight)
    [391054] = true, -- Intercession (Paladin)
    [265116] = true, -- Unstable Temporal Time Shifter (Engineering)
    [345130] = true, -- Disposable Spectrophasic Reanimator (Engineering)
}

-- Charge gain interval in seconds (1 charge per 10 min in 5-man M+)
local CHARGE_INTERVAL = 600
local MAX_CHARGES = 5

-- =====================================
-- VARIABLES
-- =====================================
local frame, eventFrame
local isLocked = true
local isInMythicPlus = false
local keystoneStartTime = 0
local chargesUsed = 0
local dragOverlay, dragLabel

-- =====================================
-- HELPERS
-- =====================================
local function GetSettings()
    if not TomoModDB or not TomoModDB.combatResTracker then return nil end
    return TomoModDB.combatResTracker
end

local function SavePosition()
    local settings = GetSettings()
    if not settings or not frame then return end
    local point, _, relativePoint, x, y = frame:GetPoint()
    settings.position = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }
end

-- =====================================
-- COMBAT RES CHARGE CALCULATION
-- =====================================
local function GetCharges()
    if not isInMythicPlus then return 0, MAX_CHARGES end

    local elapsed = GetTime() - keystoneStartTime
    local totalGained = 1 + math.floor(elapsed / CHARGE_INTERVAL) -- 1 initial + timed gains
    local available = math.min(MAX_CHARGES, math.max(0, totalGained - chargesUsed))
    return available, MAX_CHARGES
end

local function GetTimeToNextCharge()
    if not isInMythicPlus then return 0 end

    local elapsed = GetTime() - keystoneStartTime
    local nextChargeAt = (math.floor(elapsed / CHARGE_INTERVAL) + 1) * CHARGE_INTERVAL
    return math.max(0, nextChargeAt - elapsed)
end

-- =====================================
-- 9-SLICE BORDER HELPER
-- =====================================
local function Create9SliceBorder(parent, r, g, b, a)
    a = a or 1
    local parts = {}
    local function Tex()
        local t = parent:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetTexture(BORDER_TEX)
        if r then t:SetVertexColor(r, g, b, a) end
        parts[#parts + 1] = t
        return t
    end

    local tl = Tex(); tl:SetSize(BORDER_CORNER, BORDER_CORNER)
    tl:SetPoint("TOPLEFT"); tl:SetTexCoord(0, 0.5, 0, 0.5)
    local tr = Tex(); tr:SetSize(BORDER_CORNER, BORDER_CORNER)
    tr:SetPoint("TOPRIGHT"); tr:SetTexCoord(0.5, 1, 0, 0.5)
    local bl = Tex(); bl:SetSize(BORDER_CORNER, BORDER_CORNER)
    bl:SetPoint("BOTTOMLEFT"); bl:SetTexCoord(0, 0.5, 0.5, 1)
    local br = Tex(); br:SetSize(BORDER_CORNER, BORDER_CORNER)
    br:SetPoint("BOTTOMRIGHT"); br:SetTexCoord(0.5, 1, 0.5, 1)

    local top = Tex(); top:SetHeight(BORDER_CORNER)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("TOPRIGHT", tr, "TOPLEFT")
    top:SetTexCoord(0.5, 0.5, 0, 0.5)
    local bot = Tex(); bot:SetHeight(BORDER_CORNER)
    bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT"); bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
    bot:SetTexCoord(0.5, 0.5, 0.5, 1)
    local left = Tex(); left:SetWidth(BORDER_CORNER)
    left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT")
    left:SetTexCoord(0, 0.5, 0.5, 0.5)
    local right = Tex(); right:SetWidth(BORDER_CORNER)
    right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT"); right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
    right:SetTexCoord(0.5, 1, 0.5, 0.5)

    return parts
end

-- =====================================
-- UPDATE DISPLAY
-- =====================================
local function UpdateDisplay()
    if not frame then return end
    local settings = GetSettings()
    if not settings or not settings.enabled then
        frame:Hide()
        return
    end

    -- Show only in M+ (or when unlocked for positioning)
    if not isInMythicPlus and isLocked then
        frame:Hide()
        return
    end
    frame:Show()

    -- Combat Res charges
    local charges, maxCharges = GetCharges()
    if frame.chargeText then
        frame.chargeText:SetText(charges)
        if charges == 0 then
            frame.chargeText:SetTextColor(1, 0.2, 0.2)
        elseif charges == 1 then
            frame.chargeText:SetTextColor(1, 0.8, 0.1)
        else
            frame.chargeText:SetTextColor(0.2, 1, 0.2)
        end
    end

    -- Time to next charge
    if frame.timerText then
        local timeToNext = GetTimeToNextCharge()
        if isInMythicPlus and charges < maxCharges and timeToNext > 0 then
            local min = math.floor(timeToNext / 60)
            local sec = math.floor(timeToNext % 60)
            frame.timerText:SetFormattedText("%d:%02d", min, sec)
            frame.timerText:Show()
        else
            frame.timerText:Hide()
        end
    end

    -- Death count
    if frame.deathText then
        if isInMythicPlus then
            local deaths = C_ChallengeMode.GetDeathCount and C_ChallengeMode.GetDeathCount() or 0
            if type(deaths) == "number" then
                frame.deathText:SetText(deaths)
                if deaths == 0 then
                    frame.deathText:SetTextColor(0.7, 0.7, 0.7)
                else
                    frame.deathText:SetTextColor(1, 0.2, 0.2)
                end
            end
        else
            frame.deathText:SetText("0")
            frame.deathText:SetTextColor(0.7, 0.7, 0.7)
        end
    end

    -- M+ Rating
    if frame.ratingText then
        if settings.showRating then
            local score = C_ChallengeMode.GetOverallDungeonScore and C_ChallengeMode.GetOverallDungeonScore() or 0
            if type(score) == "number" and score > 0 then
                local color = C_ChallengeMode.GetDungeonScoreRarityColor and C_ChallengeMode.GetDungeonScoreRarityColor(score)
                if color then
                    frame.ratingText:SetText(score)
                    frame.ratingText:SetTextColor(color.r, color.g, color.b)
                else
                    frame.ratingText:SetText(score)
                    frame.ratingText:SetTextColor(1, 0.82, 0)
                end
                frame.ratingFrame:Show()
            else
                frame.ratingFrame:Hide()
            end
        else
            frame.ratingFrame:Hide()
        end
    end
end

-- =====================================
-- CREATE UI
-- =====================================
local function CreateUI()
    local settings = GetSettings()
    if not settings then return end

    -- Main frame
    frame = CreateFrame("Frame", "TomoMod_CombatResTracker", UIParent)
    frame:SetSize(settings.width or 160, settings.height or 36)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(100)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    -- Position
    local pos = settings.position
    if pos then
        frame:SetPoint(pos.point or "TOP", UIParent, pos.relativePoint or "TOP", pos.x or 0, pos.y or -200)
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, -200)
    end

    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.85)

    -- 9-slice border
    Create9SliceBorder(frame)

    -- Drag handlers
    frame:SetScript("OnMouseDown", function(self, button)
        if not isLocked and button == "LeftButton" then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnMouseUp", function(self, button)
        if not isLocked and button == "LeftButton" then
            self:StopMovingOrSizing()
            SavePosition()
        end
    end)

    -- Drag overlay (shown when unlocked)
    dragOverlay = frame:CreateTexture(nil, "OVERLAY", nil, 6)
    dragOverlay:SetAllPoints()
    dragOverlay:SetColorTexture(1, 1, 1, 0.1)
    dragOverlay:Hide()

    dragLabel = frame:CreateFontString(nil, "OVERLAY")
    dragLabel:SetFont(FONT, 10, "OUTLINE")
    dragLabel:SetPoint("CENTER")
    dragLabel:SetTextColor(1, 1, 0)
    dragLabel:SetText("COMBAT RES\n|cffaaaaaa(Drag to move)")
    dragLabel:Hide()

    -- Layout: [BrezIcon ChargeCount | Timer] [SkullIcon DeathCount] [RatingBadge]
    local leftPad = 6
    local iconSize = settings.iconSize or 18

    -- ===== Combat Res Section =====
    local brezIcon = frame:CreateTexture(nil, "ARTWORK")
    brezIcon:SetSize(iconSize, iconSize)
    brezIcon:SetPoint("LEFT", frame, "LEFT", leftPad, 0)
    brezIcon:SetTexture(136080) -- Rebirth icon (spell_nature_reincarnation)
    brezIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.brezIcon = brezIcon

    local chargeText = frame:CreateFontString(nil, "OVERLAY")
    chargeText:SetFont(FONT, 14, "OUTLINE")
    chargeText:SetPoint("LEFT", brezIcon, "RIGHT", 4, 0)
    chargeText:SetText("1")
    chargeText:SetTextColor(0.2, 1, 0.2)
    frame.chargeText = chargeText

    local timerText = frame:CreateFontString(nil, "OVERLAY")
    timerText:SetFont(FONT, 9, "OUTLINE")
    timerText:SetPoint("LEFT", chargeText, "RIGHT", 3, 0)
    timerText:SetTextColor(0.7, 0.7, 0.7)
    timerText:Hide()
    frame.timerText = timerText

    -- ===== Death Count Section =====
    local deathIcon = frame:CreateTexture(nil, "ARTWORK")
    deathIcon:SetSize(iconSize - 2, iconSize - 2)
    deathIcon:SetPoint("LEFT", frame, "CENTER", 4, 0)
    deathIcon:SetAtlas("poi-graveyard-neutral")
    frame.deathIcon = deathIcon

    local deathText = frame:CreateFontString(nil, "OVERLAY")
    deathText:SetFont(FONT, 14, "OUTLINE")
    deathText:SetPoint("LEFT", deathIcon, "RIGHT", 4, 0)
    deathText:SetText("0")
    deathText:SetTextColor(0.7, 0.7, 0.7)
    frame.deathText = deathText

    -- ===== Rating Section (right side) =====
    local ratingFrame = CreateFrame("Frame", nil, frame)
    ratingFrame:SetSize(50, iconSize)
    ratingFrame:SetPoint("RIGHT", frame, "RIGHT", -leftPad, 0)
    frame.ratingFrame = ratingFrame

    local ratingIcon = ratingFrame:CreateTexture(nil, "ARTWORK")
    ratingIcon:SetSize(iconSize - 2, iconSize - 2)
    ratingIcon:SetPoint("LEFT", ratingFrame, "LEFT", 0, 0)
    ratingIcon:SetAtlas("dungeons-star-outline")
    frame.ratingIcon = ratingIcon

    local ratingText = ratingFrame:CreateFontString(nil, "OVERLAY")
    ratingText:SetFont(FONT, 11, "OUTLINE")
    ratingText:SetPoint("LEFT", ratingIcon, "RIGHT", 3, 0)
    ratingText:SetText("0")
    ratingText:SetTextColor(1, 0.82, 0)
    frame.ratingText = ratingText

    -- Mouse interaction (locked by default)
    frame:EnableMouse(false)

    frame:Hide()
end

-- =====================================
-- COMBAT LOG TRACKING (BREZ USAGE)
-- =====================================
local function OnCombatLogEvent()
    if not isInMythicPlus then return end

    local _, subEvent, _, _, _, _, _, _, destName, _, _, spellID = CombatLogGetCurrentEventInfo()
    if subEvent == "SPELL_CAST_SUCCESS" and BREZ_SPELLS[spellID] then
        chargesUsed = chargesUsed + 1
        UpdateDisplay()
        local settings = GetSettings()
        if settings and settings.showMessages then
            print("|cff0cd29fTomoMod CR:|r " .. (destName or "?") .. " — combat res used (" .. GetCharges() .. " left)")
        end
    end
end

-- =====================================
-- EVENT HANDLING
-- =====================================
local function OnEvent(self, event, ...)
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    if event == "CHALLENGE_MODE_START" then
        isInMythicPlus = true
        keystoneStartTime = GetTime()
        chargesUsed = 0
        UpdateDisplay()

    elseif event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
        isInMythicPlus = false
        chargesUsed = 0
        UpdateDisplay()

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Check if already in a M+ run (reconnect / reload)
        local _, _, _, _, _, _, _, currentMapID = GetInstanceInfo()
        local keystoneLevel = C_ChallengeMode.GetActiveKeystoneInfo and C_ChallengeMode.GetActiveKeystoneInfo()
        if keystoneLevel and keystoneLevel > 0 then
            isInMythicPlus = true
            -- Approximate: we don't know exact start time on reload
            -- Use current elapsed from death count as heuristic
            if keystoneStartTime == 0 then
                keystoneStartTime = GetTime()
            end
        else
            isInMythicPlus = false
        end
        UpdateDisplay()

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        OnCombatLogEvent()

    elseif event == "CHALLENGE_MODE_DEATH_COUNT_UPDATED" then
        UpdateDisplay()
    end
end

-- =====================================
-- LOCK / UNLOCK
-- =====================================
local function SetLocked(locked)
    isLocked = locked
    if not frame then return end

    if locked then
        frame:EnableMouse(false)
        if dragOverlay then dragOverlay:Hide() end
        if dragLabel then dragLabel:Hide() end
        UpdateDisplay()
    else
        frame:EnableMouse(true)
        if dragOverlay then dragOverlay:Show() end
        if dragLabel then dragLabel:Show() end
        frame:Show()
        frame:SetAlpha(1)
    end
end

function CRT.ToggleLock()
    SetLocked(not isLocked)
    if isLocked then
        print("|cff0cd29fTomoMod CR:|r " .. TomoMod_L["msg_cr_locked"])
    else
        print("|cffffff00TomoMod CR:|r " .. TomoMod_L["msg_cr_unlock"])
    end
end

-- =====================================
-- TICKER (update timer every second)
-- =====================================
local tickerFrame
local function StartTicker()
    if tickerFrame then return end
    tickerFrame = CreateFrame("Frame")
    local elapsed = 0
    tickerFrame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed >= 1 then
            elapsed = 0
            if isInMythicPlus then
                UpdateDisplay()
            end
        end
    end)
end

-- =====================================
-- PUBLIC API
-- =====================================
function CRT.Initialize()
    if not TomoModDB or not TomoModDB.combatResTracker then return end
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    CreateUI()
    StartTicker()
    UpdateDisplay()
end

function CRT.SetEnabled(enabled)
    local settings = GetSettings()
    if not settings then return end
    settings.enabled = enabled

    if enabled then
        if not frame then
            CRT.Initialize()
        else
            UpdateDisplay()
        end
        print("|cff0cd29fTomoMod:|r " .. TomoMod_L["msg_cr_enabled"])
    else
        if frame then frame:Hide() end
        print("|cff0cd29fTomoMod:|r " .. TomoMod_L["msg_cr_disabled"])
    end
end

function CRT.Toggle()
    local settings = GetSettings()
    if not settings then return end
    CRT.SetEnabled(not settings.enabled)
end

-- =====================================
-- EVENTS (deferred to PLAYER_LOGIN to avoid protected frame error in TWW)
-- =====================================
eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        self:RegisterEvent("CHALLENGE_MODE_START")
        self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
        self:RegisterEvent("CHALLENGE_MODE_RESET")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:RegisterEvent("CHALLENGE_MODE_DEATH_COUNT_UPDATED")
        self:SetScript("OnEvent", OnEvent)
    end
end)

-- Export
_G.TomoMod_CombatResTracker = CRT

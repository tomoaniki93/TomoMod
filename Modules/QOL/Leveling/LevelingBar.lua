-- =====================================
-- LevelingBar.lua — XP / Leveling Info Bar
-- Level, XP, %, XP/Hour, Quest %, Rested %
-- Draggable, toggleable via config
-- =====================================

TomoMod_LevelingBar = TomoMod_LevelingBar or {}
local LB = TomoMod_LevelingBar

-- =====================================
-- LOCALS
-- =====================================

local FONT       = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD  = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local FONT_BLACK = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Bold.ttf"
local TEXTURE    = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
local L = TomoMod_L

local barFrame         -- Main container
local xpBar            -- XP StatusBar
local restedBar        -- Rested XP overlay bar
local levelText        -- "Level 80"
local xpText           -- "26,660 / 302,795"
local pctText          -- "8.8%"
local xpHourText       -- "XP/h: 12,500"
local questPctText     -- "Quest: +0.5%"
local restedText       -- "Rested: 100.5%"

local infoPanel        -- hover overlay (built lazily)

local isInitialized = false
local isLocked      = true

-- Session tracking
local sessionStartTime = 0
local sessionStartXP   = 0
local lastQuestXP      = 0
local lastQuestPct     = 0

local function DB()
    return TomoModDB and TomoModDB.levelingBar
end

-- =====================================
-- XP HELPERS
-- =====================================

local function GetXPValues()
    local current = UnitXP("player") or 0
    local max     = UnitXPMax("player") or 1
    if max == 0 then max = 1 end
    return current, max
end

local function GetRestedXP()
    return GetXPExhaustion() or 0
end

local function GetXPPerHour()
    if sessionStartTime == 0 then return 0 end
    local elapsed = GetTime() - sessionStartTime
    if elapsed < 10 then return 0 end  -- need at least 10s of data

    local current = UnitXP("player") or 0
    local gained = current - sessionStartXP

    -- Account for level-ups: if current < start, we leveled
    if gained < 0 then
        -- Reset session on level-up
        sessionStartXP = current
        sessionStartTime = GetTime()
        return 0
    end

    local hours = elapsed / 3600
    if hours < 0.001 then return 0 end
    return gained / hours
end

local function FormatNumber(n)
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    end
    return tostring(math.floor(n))
end

local function FormatNumberFull(n)
    -- Add thousand separators
    local s = tostring(math.floor(n))
    local result = ""
    local count = 0
    for i = #s, 1, -1 do
        count = count + 1
        result = s:sub(i, i) .. result
        if count % 3 == 0 and i > 1 then
            result = "," .. result
        end
    end
    return result
end

-- =====================================
-- MAX LEVEL CHECK
-- =====================================

local function CanGainXP()
    if IsLevelAtEffectiveMaxLevel then
        local ok, result = pcall(IsLevelAtEffectiveMaxLevel)
        if ok and result then return false end
    end
    if IsXPUserDisabled and IsXPUserDisabled() then
        return false
    end
    local xp = UnitXP("player") or 0
    local level = UnitLevel("player") or 0
    if xp == 0 and level >= 80 then return false end
    return true
end

-- =====================================
-- HOVER INFO OVERLAY
-- =====================================
-- A styled panel rather than a GameTooltip: it is ours to lay out (aligned
-- value column, brand accents) and cannot be pre-empted by whatever else owns
-- the tooltip at that moment.
--
-- Rows are generic slots filled top-down with whatever data is actually
-- available, so a hidden row (no rested XP, no XP/h yet) leaves no gap.

local MAX_INFO_ROWS = 9
local ROW_H, PAD    = 14, 9

local function FormatDuration(hours)
    if hours <= 0 then return "-" end
    if hours < 1 then
        return string.format("%dm", math.max(1, math.floor(hours * 60 + 0.5)))
    end
    local h = math.floor(hours)
    local m = math.floor((hours - h) * 60 + 0.5)
    if m >= 60 then h, m = h + 1, 0 end
    if m == 0 then return string.format("%dh", h) end
    return string.format("%dh%02dm", h, m)
end

-- Several existing locale strings carry a trailing colon ("Progress:") and
-- several do not. The panel supplies its own alignment, so normalise.
local function Label(key, fallback)
    local t = (L and L[key]) or fallback
    if type(t) ~= "string" or t == key then t = fallback end
    return (t:gsub(":%s*$", ""))
end

local function BuildInfoPanel()
    if infoPanel then return end

    infoPanel = CreateFrame("Frame", "TomoMod_LevelingBarInfo", UIParent, "BackdropTemplate")
    infoPanel:SetFrameStrata("TOOLTIP")
    infoPanel:SetSize(250, 40)
    infoPanel:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    infoPanel:SetBackdropColor(0.04, 0.04, 0.06, 0.96)
    infoPanel:SetBackdropBorderColor(0.047, 0.824, 0.624, 0.7)
    infoPanel:Hide()

    local title = infoPanel:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_BOLD, 12, "OUTLINE")
    title:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 10, -PAD)
    title:SetTextColor(0.047, 0.824, 0.624)
    title:SetText("TomoMod " .. Label("leveling_bar_title", "Leveling Bar"))

    infoPanel.rows = {}
    for i = 1, MAX_INFO_ROWS do
        local row = {}
        row.label = infoPanel:CreateFontString(nil, "OVERLAY")
        row.label:SetFont(FONT, 11, "OUTLINE")
        row.label:SetPoint("TOPLEFT", infoPanel, "TOPLEFT",
                           10, -(PAD + 16 + 6 + (i - 1) * ROW_H))
        row.label:SetTextColor(0.72, 0.72, 0.76)
        row.label:SetJustifyH("LEFT")

        row.value = infoPanel:CreateFontString(nil, "OVERLAY")
        row.value:SetFont(FONT_BOLD, 11, "OUTLINE")
        row.value:SetPoint("RIGHT", infoPanel, "RIGHT", -10, 0)
        row.value:SetPoint("TOP", row.label, "TOP", 0, 0)
        row.value:SetJustifyH("RIGHT")

        infoPanel.rows[i] = row
    end

    infoPanel.hint = infoPanel:CreateFontString(nil, "OVERLAY")
    infoPanel.hint:SetFont(FONT, 10, "OUTLINE")
    infoPanel.hint:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 10, 0)
    infoPanel.hint:SetTextColor(0.45, 0.45, 0.50)
    infoPanel.hint:SetText(Label("leveling_drag_hint", "/tm sr to unlock & drag"))
end

local function UpdateInfoPanel()
    if not infoPanel then return end

    local cur, max = GetXPValues()
    local data = {}
    local function add(label, value, r, g, b)
        data[#data + 1] = { label, value, r or 1, g or 1, b or 1 }
    end

    add(Label("leveling_level", "Level"), tostring(UnitLevel("player") or 0))
    add("XP", FormatNumberFull(cur) .. " / " .. FormatNumberFull(max))
    add(Label("leveling_remaining", "Remaining"), FormatNumberFull(math.max(0, max - cur)))
    add(Label("leveling_progress", "Progress"),
        string.format("%.1f%%", (cur / max) * 100), 0.047, 0.824, 0.624)

    local rested = GetRestedXP()
    if rested > 0 then
        add(Label("leveling_rested", "Rested"),
            string.format("%s (%.0f%%)", FormatNumber(rested), (rested / max) * 100),
            0.30, 0.60, 1.0)
    end

    local xph = GetXPPerHour()
    if xph > 0 then
        add("XP/h", FormatNumberFull(xph))
        add(Label("leveling_ttl", "Time to level"),
            FormatDuration((max - cur) / xph), 0.95, 0.80, 0.10)
    end

    -- sessionStartXP is reset on level-up, so this is XP gained since the last
    -- ding rather than since login -- the number that matters while levelling.
    local gained = cur - sessionStartXP
    if gained > 0 then
        add(Label("leveling_session", "This level"), "+" .. FormatNumberFull(gained))
    end

    if lastQuestPct > 0 then
        add(Label("leveling_last_quest", "Last quest"),
            string.format("+%.1f%%", lastQuestPct), 0.95, 0.80, 0.10)
    end

    local shown = math.min(#data, MAX_INFO_ROWS)
    for i = 1, MAX_INFO_ROWS do
        local row = infoPanel.rows[i]
        local d = data[i]
        if d and i <= shown then
            row.label:SetText(d[1])
            row.value:SetText(d[2])
            row.value:SetTextColor(d[3], d[4], d[5])
            row.label:Show(); row.value:Show()
        else
            row.label:Hide(); row.value:Hide()
        end
    end

    local hintY = PAD + 16 + 6 + shown * ROW_H + 4
    infoPanel.hint:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 10, -hintY)
    infoPanel:SetHeight(hintY + 14 + PAD)
end

-- =====================================
-- CREATE BAR
-- =====================================

local function CreateBar()
    if barFrame then return end

    local db = DB()
    if not db then return end

    -- Main container
    barFrame = CreateFrame("Frame", "TomoMod_LevelingBar", UIParent, "BackdropTemplate")
    barFrame:SetSize(db.width or 500, db.height or 28)
    barFrame:SetFrameStrata("MEDIUM")
    barFrame:SetFrameLevel(50)
    barFrame:SetClampedToScreen(true)

    -- Dark backdrop
    barFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    barFrame:SetBackdropColor(0.06, 0.06, 0.08, 0.92)
    barFrame:SetBackdropBorderColor(0, 0, 0, 1)

    -- XP bar (main progress)
    xpBar = CreateFrame("StatusBar", nil, barFrame)
    xpBar:SetAllPoints()
    xpBar:SetStatusBarTexture(TEXTURE)
    xpBar:SetStatusBarColor(0.047, 0.824, 0.624, 0.70)
    xpBar:SetMinMaxValues(0, 1)
    xpBar:SetValue(0)

    -- Rested XP overlay (shows after current XP, different color)
    restedBar = CreateFrame("StatusBar", nil, barFrame)
    restedBar:SetAllPoints()
    restedBar:SetStatusBarTexture(TEXTURE)
    restedBar:SetStatusBarColor(0.10, 0.40, 0.80, 0.40)
    restedBar:SetMinMaxValues(0, 1)
    restedBar:SetValue(0)
    restedBar:SetFrameLevel(barFrame:GetFrameLevel() + 1)

    -- XP bar goes on top of rested
    xpBar:SetFrameLevel(barFrame:GetFrameLevel() + 2)

    -- =========================================
    -- TEXT OVERLAY (frame above all bars)
    -- =========================================
    local textOverlay = CreateFrame("Frame", nil, barFrame)
    textOverlay:SetAllPoints()
    textOverlay:SetFrameLevel(barFrame:GetFrameLevel() + 3)

    -- Level (left)
    levelText = textOverlay:CreateFontString(nil, "OVERLAY")
    levelText:SetFont(FONT_BLACK, 13, "OUTLINE")
    levelText:SetPoint("LEFT", barFrame, "LEFT", 8, 0)
    levelText:SetTextColor(1, 1, 1, 1)

    -- XP current / max (center-left)
    xpText = textOverlay:CreateFontString(nil, "OVERLAY")
    xpText:SetFont(FONT, 11, "OUTLINE")
    xpText:SetPoint("LEFT", levelText, "RIGHT", 14, 0)
    xpText:SetTextColor(0.90, 0.90, 0.90, 1)

    -- Percentage (right)
    pctText = textOverlay:CreateFontString(nil, "OVERLAY")
    pctText:SetFont(FONT_BOLD, 12, "OUTLINE")
    pctText:SetPoint("RIGHT", barFrame, "RIGHT", -8, 0)
    pctText:SetTextColor(0.047, 0.824, 0.624, 1)

    -- Rested % (left of pct)
    restedText = textOverlay:CreateFontString(nil, "OVERLAY")
    restedText:SetFont(FONT, 10, "OUTLINE")
    restedText:SetPoint("RIGHT", pctText, "LEFT", -12, 0)
    restedText:SetTextColor(0.30, 0.60, 1.0, 1)

    -- XP/Hour (center area)
    xpHourText = textOverlay:CreateFontString(nil, "OVERLAY")
    xpHourText:SetFont(FONT, 10, "OUTLINE")
    xpHourText:SetPoint("CENTER", barFrame, "CENTER", 0, 0)
    xpHourText:SetTextColor(0.75, 0.75, 0.75, 1)

    -- Quest %
    questPctText = textOverlay:CreateFontString(nil, "OVERLAY")
    questPctText:SetFont(FONT, 10, "OUTLINE")
    questPctText:SetPoint("LEFT", xpHourText, "RIGHT", 14, 0)
    questPctText:SetTextColor(0.95, 0.80, 0.10, 1)

    -- =========================================
    -- DRAG & DROP (locked by default, /tm sr to unlock)
    -- =========================================
    barFrame:SetMovable(true)
    barFrame:EnableMouse(true)
    barFrame:RegisterForDrag("LeftButton")

    barFrame:SetScript("OnDragStart", function(self)
        if not isLocked then
            self:StartMoving()
        end
    end)

    barFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local db = DB()
        if db then
            -- [DRAG] GetLeft/GetBottom (screen-absolute) instead of GetPoint,
            -- whose relative anchor can be corrupted by StartMoving.
            local left, bottom = self:GetLeft(), self:GetBottom()
            if left and bottom then
                local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
                db.position = {
                    point = "BOTTOMLEFT",
                    relativePoint = "BOTTOMLEFT",
                    x = left * scale,
                    y = bottom * scale,
                }
            end
        end
    end)

    -- =========================================
    -- HOVER OVERLAY
    -- =========================================
    barFrame:SetScript("OnEnter", function(self)
        BuildInfoPanel()
        UpdateInfoPanel()
        infoPanel:ClearAllPoints()
        -- Flip below the bar when there is no room above, so the panel stays
        -- readable wherever the player has dragged the bar.
        local top = self:GetTop() or 0
        local screenH = UIParent:GetHeight() or 768
        if top + infoPanel:GetHeight() + 8 > screenH then
            infoPanel:SetPoint("TOP", self, "BOTTOM", 0, -6)
        else
            infoPanel:SetPoint("BOTTOM", self, "TOP", 0, 6)
        end
        infoPanel:Show()
    end)

    barFrame:SetScript("OnLeave", function()
        if infoPanel then infoPanel:Hide() end
    end)
end

-- =====================================
-- UPDATE BAR
-- =====================================

function LB.Update()
    if not barFrame then return end
    local db = DB()
    if not db or not db.enabled then return end

    local cur, max = GetXPValues()
    local pct = (cur / max) * 100

    -- Update XP bar
    xpBar:SetMinMaxValues(0, max)
    xpBar:SetValue(cur)

    -- Rested bar: shows current + rested combined
    local rested = GetRestedXP()
    restedBar:SetMinMaxValues(0, max)
    if rested > 0 then
        restedBar:SetValue(math.min(cur + rested, max))
        restedBar:Show()
    else
        restedBar:Hide()
    end

    -- Level
    local level = UnitLevel("player") or 0
    levelText:SetText(string.format("%s %d", L["leveling_level"] or "Level", level))

    -- XP numbers
    xpText:SetText(string.format("%s / %s", FormatNumberFull(cur), FormatNumberFull(max)))

    -- Percentage
    pctText:SetText(string.format("%.1f%%", pct))

    -- XP per hour
    local xph = GetXPPerHour()
    if xph > 0 then
        xpHourText:SetText(string.format("%s XP/h", FormatNumber(xph)))
        xpHourText:Show()
    else
        xpHourText:SetText("-- XP/h")
    end

    -- Last quest %
    if lastQuestPct > 0 then
        questPctText:SetText(string.format("Quest: +%.1f%%", lastQuestPct))
        questPctText:Show()
    else
        questPctText:SetText("")
    end

    -- Rested %
    if rested > 0 then
        local restedPct = (rested / max) * 100
        restedText:SetText(string.format("%s: %.1f%%", L["leveling_rested"] or "Rested", restedPct))
        restedText:Show()
    else
        restedText:SetText("")
    end
end

-- =====================================
-- APPLY SETTINGS
-- =====================================

function LB.ApplySettings()
    if not barFrame then return end
    local db = DB()
    if not db then return end

    barFrame:SetSize(db.width or 500, db.height or 28)

    -- Reposition
    LB.SetPosition()
    LB.Update()
end

-- =====================================
-- POSITION
-- =====================================

function LB.SetPosition()
    if not barFrame then return end
    local db = DB()
    if not db then return end

    barFrame:ClearAllPoints()

    if db.position then
        barFrame:SetPoint(
            db.position.point,
            UIParent,
            db.position.relativePoint,
            db.position.x,
            db.position.y
        )
    else
        -- [3.0.5] Pas de position sauvegardée : on place la barre au CENTRE de
        -- l'écran (au lieu du bas, souvent caché derrière les barres d'action)
        -- pour que le joueur la trouve immédiatement, puis la déplace.
        barFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

-- =====================================
-- HOOKS & EVENTS
-- =====================================

local function SetupEvents()
    local evFrame = CreateFrame("Frame")
    evFrame:RegisterEvent("PLAYER_XP_UPDATE")
    evFrame:RegisterEvent("PLAYER_LEVEL_UP")
    evFrame:RegisterEvent("UPDATE_EXHAUSTION")
    evFrame:RegisterEvent("QUEST_TURNED_IN")
    evFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    local prevXP = UnitXP("player") or 0

    evFrame:SetScript("OnEvent", function(self, event, ...)
        if not barFrame or not DB() or not DB().enabled then return end

        if event == "PLAYER_XP_UPDATE" then
            local newXP = UnitXP("player") or 0
            local gained = newXP - prevXP
            if gained > 0 then
                -- Track last quest XP
                local _, max = GetXPValues()
                lastQuestXP = gained
                lastQuestPct = (gained / max) * 100
            end
            prevXP = newXP
            LB.Update()

        elseif event == "PLAYER_LEVEL_UP" then
            -- Reset session tracking
            sessionStartXP = 0
            sessionStartTime = GetTime()
            prevXP = 0
            lastQuestXP = 0
            lastQuestPct = 0

            -- Auto-hide at max level, restore Blizzard bar
            if not CanGainXP() then
                if barFrame then barFrame:Hide() end
                RestoreBlizzardXPBar()
            end

            C_Timer.After(0.5, LB.Update)

        elseif event == "UPDATE_EXHAUSTION" then
            LB.Update()

        elseif event == "QUEST_TURNED_IN" then
            -- XP update comes slightly after quest turn-in
            C_Timer.After(0.2, LB.Update)

        elseif event == "PLAYER_ENTERING_WORLD" then
            prevXP = UnitXP("player") or 0
            LB.Update()
        end
    end)

    -- [PERF] Use C_Timer instead of OnUpdate ticking at 60fps
    C_Timer.NewTicker(10, function()
        if barFrame and barFrame:IsShown() then
            LB.Update()
        end
    end)
end

-- =====================================
-- LOCK / UNLOCK (via /tm sr)
-- =====================================

function LB.IsLocked()
    return isLocked
end

function LB.ToggleLock()
    if not barFrame then return end
    isLocked = not isLocked

    if isLocked then
        -- Locked: remove visual indicator
        barFrame:SetBackdropBorderColor(0, 0, 0, 1)
    else
        -- Unlocked: green border to show it's movable
        barFrame:SetBackdropBorderColor(0.047, 0.824, 0.624, 1)
    end
end

-- =====================================
-- HIDE / RESTORE BLIZZARD XP BAR
-- =====================================

local offscreenParent = CreateFrame("Frame")
offscreenParent:Hide()

local blizzBarOrigParent = nil
local blizzBarHidden = false

local function HideBlizzardXPBar()
    if blizzBarHidden then return end

    -- TWW 12.x: StatusTrackingBarManager contains the XP bar
    local manager = StatusTrackingBarManager
    if manager then
        blizzBarOrigParent = manager:GetParent()
        manager:SetParent(offscreenParent)
        blizzBarHidden = true
        return
    end

    -- Fallback: MainStatusTrackingBarContainer
    local container = MainStatusTrackingBarContainer
    if container then
        blizzBarOrigParent = container:GetParent()
        container:SetParent(offscreenParent)
        blizzBarHidden = true
    end
end

local function RestoreBlizzardXPBar()
    if not blizzBarHidden then return end

    local manager = StatusTrackingBarManager
    if manager and blizzBarOrigParent then
        manager:SetParent(blizzBarOrigParent)
        manager:Show()
    end

    local container = MainStatusTrackingBarContainer
    if container and blizzBarOrigParent then
        container:SetParent(blizzBarOrigParent)
        container:Show()
    end

    blizzBarOrigParent = nil
    blizzBarHidden = false
end

-- =====================================
-- ENABLE / DISABLE
-- =====================================

function LB.Enable()
    CreateBar()
    LB.SetPosition()
    SetupEvents()

    -- Init session tracking
    sessionStartXP = UnitXP("player") or 0
    sessionStartTime = GetTime()

    -- Hide Blizzard XP bar and show ours
    HideBlizzardXPBar()
    barFrame:Show()
    LB.Update()

    -- Auto-hide at max level (bar still enabled, just not visible)
    if not CanGainXP() then
        barFrame:Hide()
        RestoreBlizzardXPBar()
    end
end

function LB.Disable()
    if barFrame then barFrame:Hide() end
    RestoreBlizzardXPBar()
end

function LB.SetEnabled(value)
    local db = DB()
    if not db then return end
    db.enabled = value

    if value then
        LB.Enable()
    else
        LB.Disable()
    end
end

-- =====================================
-- INITIALIZE
-- =====================================

function LB.Initialize()
    if isInitialized then return end
    local db = DB()
    if not db or not db.enabled then return end

    C_Timer.After(0.5, function()
        LB.Enable()
        isInitialized = true
    end)
end

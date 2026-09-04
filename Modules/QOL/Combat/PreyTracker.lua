-- =====================================
-- QOL/Combat/PreyTracker.lua
--   Displays Prey hunt progress (Midnight expansion)
--   Shows stage progress + completion timer
--   Movable via editmode (/tm layout)
-- =====================================

TomoMod_PreyTracker = TomoMod_PreyTracker or {}
local PT = TomoMod_PreyTracker

local CreateFrame = CreateFrame
local GetTime = GetTime
local UIParent = UIParent
local C_QuestLog = C_QuestLog
local C_UIWidgetManager = C_UIWidgetManager
local floor = math.floor
local max = math.max
local min = math.min

local SOLID = "Interface\\Buttons\\WHITE8X8"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"

local PREY_WIDGET_TYPE = 31
local WIDGET_SHOWN = 1

-- =====================================
-- COLOR PALETTE (matches BattleRezCounter)
-- =====================================
local COLORS = {
    accent   = { 0.180, 0.616, 0.847, 1 },
    accent2  = { 0.11, 0.459, 0.682, 1 },
    ready    = { 0.30, 0.90, 0.40, 1 },
    cooldown = { 0.85, 0.25, 0.25, 1 },
    bg       = { 0.05, 0.05, 0.06, 0.85 },
    border   = { 0.180, 0.616, 0.847, 0.9 },
    shadow   = { 0, 0, 0, 0.4 },
    text     = { 1, 1, 1, 1 },
}

-- =====================================
-- STATE
-- =====================================
local preyFrame = nil
local preyTicker = nil
local isLocked = true

local State = {
    activeQuestID = nil,
    preyName = nil,
    progressPercent = 0,
    currentStage = 0,
    isDifficult = false,
}

-- =====================================
-- HELPERS
-- =====================================
local function GetDB()
    return TomoModDB and TomoModDB.preyTracker
end

local function SavePosition()
    local db = GetDB()
    if not db or not preyFrame then return end
    local l, b = preyFrame:GetLeft(), preyFrame:GetBottom()
    if not l or not b then return end
    db.position = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = l, y = b }
end

local function ApplyPosition()
    local db = GetDB()
    if not preyFrame then return end
    preyFrame:ClearAllPoints()
    local p = db and db.position
    if p and p.point then
        preyFrame:SetPoint(p.point, UIParent, p.relativePoint or p.point, p.x or 0, p.y or 0)
    else
        preyFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    end
end

-- =====================================
-- PREY DATA EXTRACTION
-- =====================================
local function GetActivePreyQuest()
    if not C_QuestLog or not C_QuestLog.GetActivePreyQuest then return nil end
    local ok, questID = pcall(C_QuestLog.GetActivePreyQuest)
    if ok and questID and questID > 0 then
        return questID
    end
    return nil
end

local function ExtractPreyInfo(questID)
    if not questID or not C_QuestLog then return end
    
    local ok, title = pcall(C_QuestLog.GetTitleForQuestID, questID)
    if ok and title then
        State.preyName = title
        -- Extract difficulty from title (e.g., "Prey (Difficult)")
        State.isDifficult = title:lower():find("difficult") ~= nil
    end
end

local function GetPreyWidgetInfo()
    if not C_UIWidgetManager or not C_UIWidgetManager.GetAllWidgetsBySetID then return nil end
    
    -- Try all possible widget sets
    local widgetSets = {}
    if C_UIWidgetManager.GetTopCenterWidgetSetID then
        table.insert(widgetSets, C_UIWidgetManager.GetTopCenterWidgetSetID())
    end
    if C_UIWidgetManager.GetObjectiveTrackerWidgetSetID then
        table.insert(widgetSets, C_UIWidgetManager.GetObjectiveTrackerWidgetSetID())
    end
    if C_UIWidgetManager.GetBelowMinimapWidgetSetID then
        table.insert(widgetSets, C_UIWidgetManager.GetBelowMinimapWidgetSetID())
    end

    for _, setID in ipairs(widgetSets) do
        local ok, widgets = pcall(C_UIWidgetManager.GetAllWidgetsBySetID, setID)
        if ok and widgets then
            for _, widget in ipairs(widgets) do
                if widget and widget.widgetType == PREY_WIDGET_TYPE and widget.shownState == WIDGET_SHOWN then
                    if C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo then
                        local ok, info = pcall(C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo, widget.widgetID)
                        if ok and info then return info, widget.widgetID end
                    end
                end
            end
        end
    end
    
    return nil
end

local function UpdatePreyProgress()
    local questID = GetActivePreyQuest()
    if questID then
        State.activeQuestID = questID
        ExtractPreyInfo(questID)
    else
        State.activeQuestID = nil
        State.preyName = nil
    end

    -- Try to get progress from widget
    local info = GetPreyWidgetInfo()
    if info and info.progressPercent then
        State.progressPercent = max(0, min(100, info.progressPercent))
    elseif questID and C_QuestLog and C_QuestLog.GetQuestObjectives then
        local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
        if ok and objectives then
            -- Extract progress from objectives
            local totalFulfilled = 0
            local totalRequired = 0
            for _, obj in ipairs(objectives) do
                if obj.numRequired and obj.numRequired > 0 then
                    totalRequired = totalRequired + obj.numRequired
                    totalFulfilled = totalFulfilled + (obj.numFulfilled or 0)
                end
            end
            if totalRequired > 0 then
                State.progressPercent = max(0, min(100, (totalFulfilled / totalRequired) * 100))
            end
        end
    end
end

-- =====================================
-- FRAME CREATION
-- =====================================
local function CreatePreyFrame()
    if preyFrame then return end
    local db = GetDB() or {}
    local width = db.width or 250
    local height = db.height or 20

    preyFrame = CreateFrame("StatusBar", "TomoMod_PreyTracker", UIParent, "BackdropTemplate")
    preyFrame:SetSize(width, height)
    preyFrame:SetStatusBarTexture(SOLID)
    preyFrame:SetStatusBarColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], COLORS.accent[4])
    preyFrame:SetMinMaxValues(0, 100)
    preyFrame:SetValue(0)
    preyFrame:SetFrameStrata("MEDIUM")
    preyFrame:SetMovable(true)
    preyFrame:SetClampedToScreen(true)

    -- ===== BACKDROP =====
    preyFrame:SetBackdrop({
        bgFile   = SOLID,
        edgeFile = SOLID,
        edgeSize = 2,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    preyFrame:SetBackdropColor(COLORS.bg[1], COLORS.bg[2], COLORS.bg[3], COLORS.bg[4])
    preyFrame:SetBackdropBorderColor(COLORS.border[1], COLORS.border[2], COLORS.border[3], COLORS.border[4])

    -- ===== INNER SHADOW =====
    local shadowInner = preyFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
    shadowInner:SetPoint("TOPLEFT", preyFrame, "TOPLEFT", 2, -2)
    shadowInner:SetPoint("BOTTOMRIGHT", preyFrame, "BOTTOMRIGHT", -2, 2)
    shadowInner:SetColorTexture(COLORS.shadow[1], COLORS.shadow[2], COLORS.shadow[3], 0.2)
    preyFrame.shadowInner = shadowInner

    -- ===== PROGRESS TEXT =====
    local progressText = preyFrame:CreateFontString(nil, "OVERLAY")
    progressText:SetFont(FONT, db.fontSize or 11, "OUTLINE")
    progressText:SetPoint("CENTER", preyFrame, "CENTER", 0, 0)
    progressText:SetText("")
    progressText:SetTextColor(COLORS.text[1], COLORS.text[2], COLORS.text[3], COLORS.text[4])
    preyFrame.progressText = progressText

    -- ===== TITLE TEXT =====
    local titleText = preyFrame:CreateFontString(nil, "OVERLAY")
    titleText:SetFont(FONT, 9, "OUTLINE")
    titleText:SetPoint("BOTTOMLEFT", preyFrame, "TOPLEFT", 0, 3)
    titleText:SetText("")
    titleText:SetTextColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 1)
    titleText:SetMaxLines(1)
    preyFrame.titleText = titleText

    -- ===== DRAG HANDLING =====
    preyFrame:RegisterForDrag("LeftButton")
    preyFrame:SetScript("OnDragStart", function(self)
        if not isLocked then self:StartMoving() end
    end)
    preyFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    preyFrame:EnableMouse(false)

    -- ===== DRAG LABEL =====
    local dragLabel = preyFrame:CreateFontString(nil, "OVERLAY")
    TomoMod_Utils.StyleMoverLabel(dragLabel, 9)
    dragLabel:SetPoint("TOP", preyFrame, "BOTTOM", 0, -3)
    dragLabel:SetText((TomoMod_L and TomoMod_L["mover_preytracker"]) or "Prey Tracker")
    dragLabel:Hide()
    preyFrame.dragLabel = dragLabel

    ApplyPosition()
    preyFrame:Hide()
end

-- =====================================
-- UPDATE DISPLAY
-- =====================================
function PT.UpdatePreyDisplay()
    if not preyFrame then return end
    local db = GetDB()

    -- Placement mode
    if not isLocked then
        preyFrame:Show()
        preyFrame:SetValue(50)
        preyFrame.progressText:SetText("50%")
        preyFrame.titleText:SetText("Prey Tracker (Preview)")
        return
    end

    if not db or not db.enabled then
        preyFrame:Hide()
        return
    end

    UpdatePreyProgress()

    if State.activeQuestID then
        preyFrame:Show()
        preyFrame:SetValue(State.progressPercent)
        
        local text = string.format("%.0f%%", State.progressPercent)
        preyFrame.progressText:SetText(text)
        
        local title = State.preyName or "Prey Hunt"
        if State.isDifficult then
            title = title .. " [Difficult]"
        end
        preyFrame.titleText:SetText(title)
    else
        preyFrame:Hide()
    end
end

function PT.StartTicker()
    if preyTicker then return end
    preyTicker = C_Timer.NewTicker(1.0, function()
        PT.UpdatePreyDisplay()
    end)
end

function PT.StopTicker()
    if preyTicker then
        preyTicker:Cancel()
        preyTicker = nil
    end
end

-- =====================================
-- LOCK / UNLOCK
-- =====================================
function PT.SetLocked(locked)
    isLocked = locked and true or false
    if not preyFrame then return end
    if isLocked then
        preyFrame:EnableMouse(false)
        if preyFrame.dragLabel then preyFrame.dragLabel:Hide() end
    else
        preyFrame:EnableMouse(true)
        preyFrame:Show()
        if preyFrame.dragLabel then preyFrame.dragLabel:Show() end
    end
    PT.UpdatePreyDisplay()
end

function PT.IsLocked()
    return isLocked
end

function PT.ToggleLock()
    PT.SetLocked(not isLocked)
    return isLocked
end

-- =====================================
-- APPLY SETTINGS
-- =====================================
function PT.ApplySettings()
    local db = GetDB()
    if preyFrame and db then
        local width = db.width or 250
        local height = db.height or 20
        preyFrame:SetSize(width, height)
        
        if preyFrame.progressText then
            preyFrame.progressText:SetFont(FONT, db.fontSize or 11, "OUTLINE")
        end
        
        ApplyPosition()
    end
    PT.UpdatePreyDisplay()
end

-- =====================================
-- INITIALIZE
-- =====================================
function PT.Initialize()
    if PT.initialized then return end
    PT.initialized = true

    CreatePreyFrame()

    -- Event listener for quest changes
    local evFrame = CreateFrame("Frame")
    -- pcall guards events that may not exist on every client build
    pcall(evFrame.RegisterEvent, evFrame, "QUEST_ACCEPTED")
    pcall(evFrame.RegisterEvent, evFrame, "QUEST_REMOVED")
    pcall(evFrame.RegisterEvent, evFrame, "QUEST_LOG_UPDATE")
    pcall(evFrame.RegisterEvent, evFrame, "PLAYER_ENTERING_WORLD")
    pcall(evFrame.RegisterEvent, evFrame, "UPDATE_UI_WIDGET")
    evFrame:SetScript("OnEvent", function()
        PT.UpdatePreyDisplay()
    end)
    PT.eventFrame = evFrame

    PT.StartTicker()

    -- Register with mover system
    if TomoMod_Movers and TomoMod_Movers.RegisterEntry then
        TomoMod_Movers.RegisterEntry({
            label    = (TomoMod_L and TomoMod_L["mover_preytracker"]) or "Prey Tracker",
            unlock   = function()
                if PT.IsLocked() then PT.SetLocked(false) end
            end,
            lock     = function()
                if not PT.IsLocked() then PT.SetLocked(true) end
            end,
            isActive = function()
                return TomoModDB and TomoModDB.preyTracker and TomoModDB.preyTracker.enabled
            end,
        })
    end

    C_Timer.After(0.2, function()
        PT.UpdatePreyDisplay()
    end)
end

-- =====================================
-- ObjectiveTracker.lua
-- Skin for Blizzard's Objective Tracker
-- Inspired by modern dark UI designs
-- =====================================

TomoMod_ObjectiveTracker = {}
local OT = TomoMod_ObjectiveTracker

-- =====================================
-- LOCALS & CACHES
-- =====================================

local ADDON_FONT       = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD  = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ADDON_FONT_BLACK = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Bold.ttf"
local L = TomoMod_L

local skinFrame       -- Main background panel
local headerBar       -- Custom header bar
local headerTitle     -- "OBJECTIVES" text
local headerCount     -- Quest count (X/Y)
local headerOptions   -- Options button
local isInitialized = false
local styledHeaders = {}
local styledBlocks  = {}
local styledLines   = {}

-- =====================================
-- HEADER / MODULE COLOR MAP
-- =====================================
-- Colors for each tracker module header to match the screenshot style
-- Keys are module names / header text patterns

local MODULE_COLORS = {
    -- Campaign quests => orange/red
    ["CAMPAIGN"]        = { r = 1.0,  g = 0.40, b = 0.20 },
    -- Regular quests (zone) => gold
    ["QUESTS"]          = { r = 1.0,  g = 0.82, b = 0.0  },
    ["QUEST"]           = { r = 1.0,  g = 0.82, b = 0.0  },
    -- World quests => cyan
    ["WORLD QUESTS"]    = { r = 0.0,  g = 0.80, b = 1.0  },
    -- Bonus objectives => teal
    ["BONUS"]           = { r = 0.0,  g = 0.90, b = 0.70 },
    -- Scenario => purple
    ["SCENARIO"]        = { r = 0.70, g = 0.40, b = 1.0  },
    -- Achievement => yellow-green
    ["ACHIEVEMENTS"]    = { r = 0.80, g = 1.0,  b = 0.0  },
    -- Professions => brown/warm
    ["PROFESSIONS"]     = { r = 0.90, g = 0.65, b = 0.30 },
    -- Monthly / events => pink/magenta
    ["MONTHLY"]         = { r = 0.90, g = 0.30, b = 0.70 },
    -- Adventure => teal
    ["ADVENTURE"]       = { r = 0.30, g = 0.85, b = 0.65 },
    -- Fallback
    ["DEFAULT"]         = { r = 0.70, g = 0.70, b = 0.75 },
}

-- =====================================
-- SETTINGS HELPER
-- =====================================

local function GetSettings()
    return TomoModDB and TomoModDB.objectiveTracker or {}
end

local function IsEnabled()
    local s = GetSettings()
    return s.enabled
end

-- =====================================
-- BACKGROUND PANEL
-- =====================================

local function CreateBackgroundPanel()
    if skinFrame then return end

    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    local s = GetSettings()

    -- Main dark background
    skinFrame = CreateFrame("Frame", "TomoMod_OTSkin", tracker)
    skinFrame:SetFrameStrata(tracker:GetFrameStrata())
    skinFrame:SetFrameLevel(math.max(tracker:GetFrameLevel() - 1, 0))
    skinFrame:SetPoint("TOPLEFT", tracker, "TOPLEFT", -12, 12)
    skinFrame:SetPoint("BOTTOMRIGHT", tracker, "BOTTOMRIGHT", 12, -12)

    -- Background texture
    local bg = skinFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, s.bgAlpha or 0.65)
    skinFrame.bg = bg

    -- Border (subtle)
    if s.showBorder then
        local borderSize = 1
        local bColor = { 0.25, 0.25, 0.30, 0.6 }

        local top = skinFrame:CreateTexture(nil, "BORDER")
        top:SetColorTexture(unpack(bColor))
        top:SetHeight(borderSize)
        top:SetPoint("TOPLEFT", skinFrame, "TOPLEFT", 0, 0)
        top:SetPoint("TOPRIGHT", skinFrame, "TOPRIGHT", 0, 0)

        local bot = skinFrame:CreateTexture(nil, "BORDER")
        bot:SetColorTexture(unpack(bColor))
        bot:SetHeight(borderSize)
        bot:SetPoint("BOTTOMLEFT", skinFrame, "BOTTOMLEFT", 0, 0)
        bot:SetPoint("BOTTOMRIGHT", skinFrame, "BOTTOMRIGHT", 0, 0)

        local left = skinFrame:CreateTexture(nil, "BORDER")
        left:SetColorTexture(unpack(bColor))
        left:SetWidth(borderSize)
        left:SetPoint("TOPLEFT", skinFrame, "TOPLEFT", 0, 0)
        left:SetPoint("BOTTOMLEFT", skinFrame, "BOTTOMLEFT", 0, 0)

        local right = skinFrame:CreateTexture(nil, "BORDER")
        right:SetColorTexture(unpack(bColor))
        right:SetWidth(borderSize)
        right:SetPoint("TOPRIGHT", skinFrame, "TOPRIGHT", 0, 0)
        right:SetPoint("BOTTOMRIGHT", skinFrame, "BOTTOMRIGHT", 0, 0)

        skinFrame.borderTextures = { top, bot, left, right }
    end

    skinFrame:Show()
end

-- =====================================
-- CUSTOM HEADER BAR ("OBJECTIVES  Options  14/35")
-- =====================================

local function CreateHeaderBar()
    if headerBar then return end

    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    local s = GetSettings()

    headerBar = CreateFrame("Frame", "TomoMod_OTHeader", skinFrame or tracker)
    headerBar:SetHeight(28)
    headerBar:SetPoint("TOPLEFT", skinFrame or tracker, "TOPLEFT", 0, 0)
    headerBar:SetPoint("TOPRIGHT", skinFrame or tracker, "TOPRIGHT", 0, 0)

    -- Header background (slightly lighter)
    local hbg = headerBar:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints()
    hbg:SetColorTexture(0.10, 0.10, 0.14, 0.90)
    headerBar.bg = hbg

    -- Accent line at bottom of header
    local accent = headerBar:CreateTexture(nil, "ARTWORK")
    accent:SetHeight(1)
    accent:SetPoint("BOTTOMLEFT", headerBar, "BOTTOMLEFT", 0, 0)
    accent:SetPoint("BOTTOMRIGHT", headerBar, "BOTTOMRIGHT", 0, 0)
    accent:SetColorTexture(0.047, 0.824, 0.624, 0.60)
    headerBar.accent = accent

    -- "OBJECTIVES" title
    headerTitle = headerBar:CreateFontString(nil, "OVERLAY")
    headerTitle:SetFont(ADDON_FONT_BLACK, s.headerFontSize or 13, "OUTLINE")
    headerTitle:SetPoint("LEFT", headerBar, "LEFT", 10, 0)
    headerTitle:SetTextColor(0.95, 0.95, 0.97, 1)
    headerTitle:SetText(L["ot_header_title"])

    -- "Options" button (clickable text)
    headerOptions = CreateFrame("Button", nil, headerBar)
    headerOptions:SetHeight(28)
    headerOptions.text = headerOptions:CreateFontString(nil, "OVERLAY")
    headerOptions.text:SetFont(ADDON_FONT, 11, "OUTLINE")
    headerOptions.text:SetPoint("CENTER")
    headerOptions.text:SetTextColor(0.55, 0.55, 0.60, 1)
    headerOptions.text:SetText(L["ot_header_options"])
    headerOptions:SetWidth(headerOptions.text:GetStringWidth() + 10)
    headerOptions:SetPoint("RIGHT", headerBar, "RIGHT", -60, 0)

    headerOptions:SetScript("OnEnter", function(self)
        self.text:SetTextColor(0.047, 0.824, 0.624, 1)
    end)
    headerOptions:SetScript("OnLeave", function(self)
        self.text:SetTextColor(0.55, 0.55, 0.60, 1)
    end)
    headerOptions:SetScript("OnClick", function()
        if TomoMod_Config and TomoMod_Config.Toggle then
            TomoMod_Config.Toggle()
        end
    end)

    -- Quest count "14/35"
    headerCount = headerBar:CreateFontString(nil, "OVERLAY")
    headerCount:SetFont(ADDON_FONT, 11, "OUTLINE")
    headerCount:SetPoint("RIGHT", headerBar, "RIGHT", -10, 0)
    headerCount:SetTextColor(0.55, 0.55, 0.60, 1)

    -- Separator dash
    local dash = headerBar:CreateFontString(nil, "OVERLAY")
    dash:SetFont(ADDON_FONT, 11, "OUTLINE")
    dash:SetPoint("RIGHT", headerCount, "LEFT", -6, 0)
    dash:SetTextColor(0.35, 0.35, 0.40, 1)
    dash:SetText("-")
    headerBar.dash = dash

    headerBar:Show()
end

-- =====================================
-- UPDATE QUEST COUNT
-- =====================================

local function UpdateQuestCount()
    if not headerCount then return end

    local numQuests = C_QuestLog and C_QuestLog.GetNumQuestLogEntries and select(1, C_QuestLog.GetNumQuestLogEntries()) or 0
    local maxQuests = C_QuestLog and C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept() or 35

    -- Count tracked only (approximate from tracker)
    local tracked = 0
    if C_QuestLog and C_QuestLog.GetNumQuestWatches then
        tracked = C_QuestLog.GetNumQuestWatches()
    end

    headerCount:SetText(tracked .. "/" .. maxQuests)
end

-- =====================================
-- GET MODULE COLOR
-- =====================================

local function GetModuleColor(headerText)
    if not headerText then
        return MODULE_COLORS["DEFAULT"]
    end

    local upper = string.upper(headerText)

    for key, color in pairs(MODULE_COLORS) do
        if key ~= "DEFAULT" and string.find(upper, key) then
            return color
        end
    end

    return MODULE_COLORS["DEFAULT"]
end

-- =====================================
-- STYLE A MODULE HEADER
-- =====================================

local function StyleModuleHeader(header)
    if not header then return end
    if styledHeaders[header] then return end

    local s = GetSettings()

    -- Get the header text FontString
    local text = header.Text or (header.GetText and header)
    if not text then return end

    -- Apply custom font
    if text.SetFont then
        text:SetFont(ADDON_FONT_BOLD, s.categoryFontSize or 11, "OUTLINE")
    end

    -- Get text content and apply color
    local headerStr = ""
    if text.GetText then
        headerStr = text:GetText() or ""
    end

    local color = GetModuleColor(headerStr)
    if text.SetTextColor then
        text:SetTextColor(color.r, color.g, color.b, 1)
    end

    -- Try to hide or dim the default header background
    if header.Background then
        header.Background:SetAlpha(0)
    end

    -- Add a thin colored line under header
    if not header._tomoLine and header.CreateTexture then
        local line = header:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
        line:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
        line:SetColorTexture(color.r, color.g, color.b, 0.30)
        header._tomoLine = line
    end

    styledHeaders[header] = true
end

-- =====================================
-- STYLE A QUEST BLOCK (title)
-- =====================================

local function StyleBlock(block)
    if not block then return end
    if styledBlocks[block] then return end

    local s = GetSettings()

    -- Style header text (quest title)
    local headerText = block.HeaderText
    if headerText and headerText.SetFont then
        headerText:SetFont(ADDON_FONT_BOLD, s.questFontSize or 12, "OUTLINE")
        headerText:SetTextColor(1, 1, 1, 0.95)
    end

    styledBlocks[block] = true
end

-- =====================================
-- STYLE OBJECTIVE LINES
-- =====================================

local function StyleLine(line)
    if not line then return end
    if styledLines[line] then return end

    local s = GetSettings()

    -- Style the objective text
    local text = line.Text
    if text and text.SetFont then
        text:SetFont(ADDON_FONT, s.objectiveFontSize or 11, "OUTLINE")
    end

    -- Style dash/bullet
    local dash = line.Dash
    if dash and dash.SetFont then
        dash:SetFont(ADDON_FONT, s.objectiveFontSize or 11, "OUTLINE")
    end

    styledLines[line] = true
end

-- =====================================
-- HIDE BLIZZARD HEADER (replace with ours)
-- =====================================

local function HideBlizzardHeader()
    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    -- Hide the default minimize/header area
    local header = tracker.Header or tracker.HeaderMenu
    if header then
        if header.MinimizeButton then
            header.MinimizeButton:SetAlpha(0)
        end
        if header.Title then
            header.Title:SetAlpha(0)
        end
        if header.Text then
            header.Text:SetAlpha(0)
        end
        -- Offset the tracker content below our custom header
    end
end

-- =====================================
-- SCAN & STYLE ALL MODULES
-- =====================================

local function SkinAllModules()
    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    local s = GetSettings()
    if not s.enabled then return end

    -- Iterate all tracker modules
    local modules = tracker.modules
    if not modules then return end

    for _, mod in ipairs(modules) do
        -- Style module header
        if mod.Header then
            styledHeaders[mod.Header] = nil  -- allow re-styling for color updates
            StyleModuleHeader(mod.Header)
        end

        -- Style blocks within module
        if mod.usedBlocks then
            for block in pairs(mod.usedBlocks) do
                StyleBlock(block)

                -- Style lines within block
                if block.usedLines then
                    for line in pairs(block.usedLines) do
                        StyleLine(line)
                    end
                end
            end
        end
    end
end

-- =====================================
-- UPDATE BACKGROUND SIZE
-- =====================================

local function UpdateBackgroundSize()
    if not skinFrame then return end

    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    local s = GetSettings()

    -- Update background alpha
    if skinFrame.bg then
        skinFrame.bg:SetColorTexture(0, 0, 0, s.bgAlpha or 0.65)
    end

    -- Show/hide based on whether tracker has content
    local hasContent = false
    if tracker.modules then
        for _, mod in ipairs(tracker.modules) do
            if mod.usedBlocks and next(mod.usedBlocks) then
                hasContent = true
                break
            end
        end
    end

    if hasContent then
        skinFrame:Show()
        if headerBar then headerBar:Show() end
    else
        if s.hideWhenEmpty then
            skinFrame:Hide()
            if headerBar then headerBar:Hide() end
        end
    end
end

-- =====================================
-- MASTER UPDATE (called on tracker updates)
-- =====================================

local function OnTrackerUpdate()
    if not IsEnabled() then return end

    SkinAllModules()
    UpdateQuestCount()
    UpdateBackgroundSize()
end

-- =====================================
-- HOOK TRACKER UPDATES
-- =====================================

local function HookTracker()
    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    -- Hook the main update method
    -- In 12.x, ObjectiveTrackerManager uses Update()
    if tracker.Update then
        hooksecurefunc(tracker, "Update", function()
            C_Timer.After(0.05, OnTrackerUpdate)
        end)
    end

    -- Also hook on specific events for real-time updates
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
    eventFrame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
    eventFrame:RegisterEvent("QUEST_ACCEPTED")
    eventFrame:RegisterEvent("QUEST_REMOVED")
    eventFrame:RegisterEvent("QUEST_TURNED_IN")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    local throttle = 0
    eventFrame:SetScript("OnEvent", function(self, event)
        local now = GetTime()
        if now - throttle < 0.2 then return end
        throttle = now
        C_Timer.After(0.1, OnTrackerUpdate)
    end)
end

-- =====================================
-- APPLY SETTINGS (live update)
-- =====================================

function OT.ApplySettings()
    if not isInitialized then return end

    local s = GetSettings()
    if not s.enabled then
        OT.Disable()
        return
    end

    -- Reset style caches to re-apply
    wipe(styledHeaders)
    wipe(styledBlocks)
    wipe(styledLines)

    -- Update background
    if skinFrame and skinFrame.bg then
        skinFrame.bg:SetColorTexture(0, 0, 0, s.bgAlpha or 0.65)
    end

    -- Update header font
    if headerTitle then
        headerTitle:SetFont(ADDON_FONT_BLACK, s.headerFontSize or 13, "OUTLINE")
    end

    -- Re-skin everything
    OnTrackerUpdate()
end

-- =====================================
-- ENABLE / DISABLE
-- =====================================

function OT.Enable()
    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    CreateBackgroundPanel()
    CreateHeaderBar()
    HideBlizzardHeader()
    HookTracker()

    -- Initial skin pass
    C_Timer.After(0.5, OnTrackerUpdate)

    if skinFrame then skinFrame:Show() end
    if headerBar then headerBar:Show() end
end

function OT.Disable()
    -- Hide our custom elements
    if skinFrame then skinFrame:Hide() end
    if headerBar then headerBar:Hide() end

    -- Restore Blizzard header visibility
    local tracker = ObjectiveTrackerFrame
    if tracker then
        local header = tracker.Header or tracker.HeaderMenu
        if header then
            if header.MinimizeButton then header.MinimizeButton:SetAlpha(1) end
            if header.Title then header.Title:SetAlpha(1) end
            if header.Text then header.Text:SetAlpha(1) end
        end
    end
end

function OT.SetEnabled(value)
    if not TomoModDB or not TomoModDB.objectiveTracker then return end
    TomoModDB.objectiveTracker.enabled = value
    if value then
        OT.Enable()
    else
        OT.Disable()
    end
end

-- =====================================
-- INITIALIZE
-- =====================================

function OT.Initialize()
    if isInitialized then return end

    local s = GetSettings()
    if not s.enabled then return end

    -- ObjectiveTrackerFrame may not exist yet at PLAYER_LOGIN
    -- Wait for it with a polling timer
    local attempts = 0
    local function TryInit()
        attempts = attempts + 1
        if ObjectiveTrackerFrame then
            OT.Enable()
            isInitialized = true
        elseif attempts < 20 then
            C_Timer.After(0.5, TryInit)
        end
    end

    C_Timer.After(0.3, TryInit)
end

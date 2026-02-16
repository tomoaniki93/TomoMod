-- =====================================
-- ObjectiveTracker.lua
-- Skin for Blizzard's Objective Tracker (WoW 12.x)
-- Uses recursive child scanning for maximum compatibility
-- =====================================

TomoMod_ObjectiveTracker = {}
local OT = TomoMod_ObjectiveTracker

-- =====================================
-- LOCALS & CACHES
-- =====================================

local ADDON_FONT       = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD  = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ADDON_FONT_BLACK = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Bold.ttf"
local ADDON_TEXTURE    = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
local L = TomoMod_L

local skinFrame
local headerBar
local headerTitle
local headerCount
local headerDash
local headerOptions
local isInitialized = false
local isHooked      = false

-- Dedup tables to avoid re-styling frames each pass
local styledFonts = setmetatable({}, { __mode = "k" })

-- =====================================
-- CATEGORY HEADER COLORS
-- =====================================

local HEADER_COLORS = {
    -- FR + EN keywords
    ["CAMPAIGN"]        = { 1.00, 0.40, 0.20 },
    ["CAMPAGNE"]        = { 1.00, 0.40, 0.20 },
    ["QUÊTES"]          = { 1.00, 0.82, 0.00 },
    ["QUESTS"]          = { 1.00, 0.82, 0.00 },
    ["QUEST"]           = { 1.00, 0.82, 0.00 },
    ["WORLD QUESTS"]    = { 0.00, 0.80, 1.00 },
    ["EXPÉDITIONS"]     = { 0.00, 0.80, 1.00 },
    ["BONUS"]           = { 0.00, 0.90, 0.70 },
    ["SCENARIO"]        = { 0.70, 0.40, 1.00 },
    ["SCÉNARIO"]        = { 0.70, 0.40, 1.00 },
    ["ACHIEVEMENTS"]    = { 0.80, 1.00, 0.00 },
    ["HAUTS FAITS"]     = { 0.80, 1.00, 0.00 },
    ["PROFESSIONS"]     = { 0.90, 0.65, 0.30 },
    ["MÉTIERS"]         = { 0.90, 0.65, 0.30 },
    ["MONTHLY"]         = { 0.90, 0.30, 0.70 },
    ["MENSUEL"]         = { 0.90, 0.30, 0.70 },
    ["ADVENTURE"]       = { 0.30, 0.85, 0.65 },
    ["AVENTURE"]        = { 0.30, 0.85, 0.65 },
}

-- =====================================
-- SETTINGS
-- =====================================

local function S()
    return TomoModDB and TomoModDB.objectiveTracker or {}
end

local function IsEnabled()
    return S().enabled
end

-- =====================================
-- GET COLOR FOR HEADER TEXT
-- =====================================

local function GetHeaderColor(text)
    if not text or text == "" then return nil end
    local upper = string.upper(text)
    for keyword, color in pairs(HEADER_COLORS) do
        if string.find(upper, keyword, 1, true) then
            return color
        end
    end
    return nil
end

-- =====================================
-- DETECT FRAME ROLE
-- =====================================

local function IsModuleHeader(frame)
    if frame.Text and frame.Text.GetText then
        local txt = frame.Text:GetText()
        if txt and GetHeaderColor(txt) then
            return true, txt
        end
    end
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region:IsObjectType("FontString") then
            local txt = region:GetText()
            if txt and GetHeaderColor(txt) then
                return true, txt
            end
        end
    end
    return false, nil
end

-- =====================================
-- STYLE FUNCTIONS
-- =====================================

local function StyleFontString(fs, font, size, outline, r, g, b, a)
    if not fs or not fs.SetFont then return end
    local sizeKey = size .. (outline or "")
    if styledFonts[fs] == sizeKey then return end

    pcall(fs.SetFont, fs, font, size, outline or "")
    if r then pcall(fs.SetTextColor, fs, r, g, b, a or 1) end
    styledFonts[fs] = sizeKey
end

local function StyleModuleHeader(frame, headerText)
    local s = S()
    local color = GetHeaderColor(headerText)
    if not color then return end

    -- Style the header FontString
    if frame.Text and frame.Text.SetFont then
        frame.Text:SetFont(ADDON_FONT_BOLD, s.categoryFontSize or 11, "OUTLINE")
        frame.Text:SetTextColor(color[1], color[2], color[3], 1)
    end

    -- Also style any matching region FontString
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region:IsObjectType("FontString") then
            local txt = region:GetText()
            if txt and GetHeaderColor(txt) then
                region:SetFont(ADDON_FONT_BOLD, s.categoryFontSize or 11, "OUTLINE")
                region:SetTextColor(color[1], color[2], color[3], 1)
            end
        end
    end

    -- Dim default background
    if frame.Background then frame.Background:SetAlpha(0) end

    -- Add colored underline
    if not frame._tomoLine then
        local line = frame:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        line:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        frame._tomoLine = line
    end
    frame._tomoLine:SetColorTexture(color[1], color[2], color[3], 0.35)
end

local function StyleQuestTitle(fs)
    local s = S()
    StyleFontString(fs, ADDON_FONT_BOLD, s.questFontSize or 12, "OUTLINE", 1, 1, 1, 0.95)
end

local function StyleObjectiveLine(fs, completed)
    local s = S()
    if completed then
        -- Completed: green
        StyleFontString(fs, ADDON_FONT, s.objectiveFontSize or 11, "OUTLINE", 0.30, 0.90, 0.30, 1)
    else
        -- Incomplete: light grey
        StyleFontString(fs, ADDON_FONT, s.objectiveFontSize or 11, "OUTLINE", 0.85, 0.85, 0.85, 0.90)
    end
end

-- Detect if an objective line is completed
local function IsObjectiveComplete(frame)
    -- Method 1: Check Blizzard state
    if frame.state and frame.state == 1 then return true end
    -- Method 2: Check if the Check mark texture is shown
    if frame.Check and frame.Check:IsShown() then return true end
    -- Method 3: Check Dash color (Blizzard colors completed dashes differently)
    if frame.Dash and frame.Dash.GetTextColor then
        local r, g, b = frame.Dash:GetTextColor()
        -- Blizzard dims completed lines
        if r < 0.5 and g < 0.5 and b < 0.5 then return true end
    end
    return false
end

-- =====================================
-- STATUS BAR RESTYLING (forces, progress)
-- =====================================

local styledBars = setmetatable({}, { __mode = "k" })

local function StyleStatusBar(bar)
    if not bar or styledBars[bar] then return end
    if not bar.SetStatusBarTexture then return end
    styledBars[bar] = true

    -- Apply our texture
    bar:SetStatusBarTexture(ADDON_TEXTURE)
    bar:SetStatusBarColor(0.047, 0.824, 0.624, 1)

    -- Dark background
    if not bar._tmBG then
        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.08, 0.08, 0.10, 0.80)
        bar._tmBG = bg
    end

    -- 1px black border
    if not bar._tmBorder then
        for _, info in ipairs({
            {"TOPLEFT","TOPLEFT","TOPRIGHT","TOPRIGHT", nil, 1},
            {"BOTTOMLEFT","BOTTOMLEFT","BOTTOMRIGHT","BOTTOMRIGHT", nil, 1},
            {"TOPLEFT","TOPLEFT","BOTTOMLEFT","BOTTOMLEFT", 1, nil},
            {"TOPRIGHT","TOPRIGHT","BOTTOMRIGHT","BOTTOMRIGHT", 1, nil},
        }) do
            local t = bar:CreateTexture(nil, "OVERLAY", nil, 7)
            t:SetColorTexture(0, 0, 0, 1)
            t:SetPoint(info[1], bar, info[2])
            t:SetPoint(info[3], bar, info[4])
            if info[5] then t:SetWidth(info[5]) end
            if info[6] then t:SetHeight(info[6]) end
        end
        bar._tmBorder = true
    end

    -- Style the bar text if present
    local regions = { bar:GetRegions() }
    for _, region in ipairs(regions) do
        if region:IsObjectType("FontString") then
            local s = S()
            region:SetFont(ADDON_FONT_BOLD, s.objectiveFontSize or 11, "OUTLINE")
        end
    end
end

-- =====================================
-- RECURSIVE SCANNER
-- =====================================

local function ScanAndStyle(frame, depth)
    if not frame or depth > 6 then return end

    -- Check if this frame is a module header
    local isHeader, headerText = IsModuleHeader(frame)
    if isHeader then
        StyleModuleHeader(frame, headerText)
    end

    -- Check for HeaderText (quest block title)
    if frame.HeaderText and frame.HeaderText.GetText then
        StyleQuestTitle(frame.HeaderText)
    end

    -- Check for objective lines (.Text + optional .Dash)
    if frame.Text and frame.Text.GetText and not frame.HeaderText then
        local txt = frame.Text:GetText()
        if txt and txt ~= "" then
            if frame.Dash then
                local done = IsObjectiveComplete(frame)
                StyleObjectiveLine(frame.Text, done)
                StyleObjectiveLine(frame.Dash, done)
            end
        end
    end

    -- Restyle StatusBars (enemy forces, progress bars)
    if frame:IsObjectType("StatusBar") then
        StyleStatusBar(frame)
    end

    -- Recurse into children
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        ScanAndStyle(child, depth + 1)
    end
end

-- =====================================
-- BACKGROUND PANEL
-- =====================================

local function CreateOrUpdateBackground()
    local tracker = ObjectiveTrackerFrame
    if not tracker then return end
    local s = S()

    if not skinFrame then
        skinFrame = CreateFrame("Frame", "TomoMod_OTSkin", UIParent)
        skinFrame:SetFrameStrata(tracker:GetFrameStrata())
        skinFrame:SetFrameLevel(math.max(tracker:GetFrameLevel() - 1, 0))

        -- Background texture
        local bg = skinFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        skinFrame.bg = bg

        -- Border textures
        local bColor = { 0.25, 0.25, 0.30, 0.6 }
        local borders = {}
        for _, info in ipairs({
            { "TOPLEFT", "TOPLEFT", "TOPRIGHT", "TOPRIGHT", nil, 1 },
            { "BOTTOMLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", nil, 1 },
            { "TOPLEFT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT", 1, nil },
            { "TOPRIGHT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMRIGHT", 1, nil },
        }) do
            local t = skinFrame:CreateTexture(nil, "BORDER")
            t:SetColorTexture(unpack(bColor))
            t:SetPoint(info[1], skinFrame, info[2])
            t:SetPoint(info[3], skinFrame, info[4])
            if info[5] then t:SetWidth(info[5]) end
            if info[6] then t:SetHeight(info[6]) end
            borders[#borders + 1] = t
        end
        skinFrame.borderTextures = borders
    end

    -- Position: wrap actual tracker content
    skinFrame:ClearAllPoints()
    skinFrame:SetPoint("TOPLEFT", tracker, "TOPLEFT", -12, 12)
    skinFrame:SetPoint("TOPRIGHT", tracker, "TOPRIGHT", 12, 0)

    -- Dynamic height: measure the actual bottom of visible content
    local trackerTop = tracker:GetTop()
    local lowestBottom = trackerTop  -- start at top (nothing visible)

    if trackerTop then
        local children = { tracker:GetChildren() }
        for _, child in ipairs(children) do
            -- Skip our own frames
            if child:IsShown() and child ~= skinFrame and child ~= headerBar then
                local bot = child:GetBottom()
                if bot and bot < lowestBottom then
                    lowestBottom = bot
                end
            end
        end
    end

    -- Content height = distance from tracker top to lowest child bottom
    local contentH = (trackerTop and lowestBottom) and (trackerTop - lowestBottom) or 0
    -- Add padding: 12 top (for our header offset) + 28 header bar + 16 bottom padding
    local finalH = math.max(contentH + 56, 60)
    skinFrame:SetHeight(finalH)

    -- Apply alpha
    skinFrame.bg:SetColorTexture(0, 0, 0, s.bgAlpha or 0.65)

    -- Border visibility
    if skinFrame.borderTextures then
        local show = s.showBorder
        for _, t in ipairs(skinFrame.borderTextures) do
            if show then t:Show() else t:Hide() end
        end
    end

    skinFrame:Show()
end

-- =====================================
-- HEADER BAR
-- =====================================

local function CreateOrUpdateHeader()
    local tracker = ObjectiveTrackerFrame
    if not tracker or not skinFrame then return end
    local s = S()

    if not headerBar then
        headerBar = CreateFrame("Frame", "TomoMod_OTHeader", skinFrame)
        headerBar:SetHeight(28)
        headerBar:SetPoint("TOPLEFT", skinFrame, "TOPLEFT", 0, 0)
        headerBar:SetPoint("TOPRIGHT", skinFrame, "TOPRIGHT", 0, 0)

        -- Background
        local hbg = headerBar:CreateTexture(nil, "BACKGROUND")
        hbg:SetAllPoints()
        hbg:SetColorTexture(0.10, 0.10, 0.14, 0.90)

        -- Accent line
        local accent = headerBar:CreateTexture(nil, "ARTWORK")
        accent:SetHeight(1)
        accent:SetPoint("BOTTOMLEFT", headerBar, "BOTTOMLEFT", 0, 0)
        accent:SetPoint("BOTTOMRIGHT", headerBar, "BOTTOMRIGHT", 0, 0)
        accent:SetColorTexture(0.047, 0.824, 0.624, 0.60)

        -- Title
        headerTitle = headerBar:CreateFontString(nil, "OVERLAY")
        headerTitle:SetFont(ADDON_FONT_BLACK, s.headerFontSize or 13, "OUTLINE")
        headerTitle:SetPoint("LEFT", headerBar, "LEFT", 10, 0)
        headerTitle:SetTextColor(0.95, 0.95, 0.97, 1)
        headerTitle:SetText(L["ot_header_title"])

        -- Options button
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

        -- Dash
        headerDash = headerBar:CreateFontString(nil, "OVERLAY")
        headerDash:SetFont(ADDON_FONT, 11, "OUTLINE")
        headerDash:SetTextColor(0.35, 0.35, 0.40, 1)
        headerDash:SetText("-")

        -- Count
        headerCount = headerBar:CreateFontString(nil, "OVERLAY")
        headerCount:SetFont(ADDON_FONT, 11, "OUTLINE")
        headerCount:SetPoint("RIGHT", headerBar, "RIGHT", -10, 0)
        headerCount:SetTextColor(0.55, 0.55, 0.60, 1)

        headerDash:SetPoint("RIGHT", headerCount, "LEFT", -6, 0)
    end

    -- Update fonts from settings
    headerTitle:SetFont(ADDON_FONT_BLACK, s.headerFontSize or 13, "OUTLINE")

    headerBar:Show()
end

-- =====================================
-- UPDATE QUEST COUNT
-- =====================================

local function UpdateQuestCount()
    if not headerCount then return end

    local tracked = 0
    if C_QuestLog and C_QuestLog.GetNumQuestWatches then
        tracked = C_QuestLog.GetNumQuestWatches()
    end
    local maxQ = 35
    if C_QuestLog and C_QuestLog.GetMaxNumQuestsCanAccept then
        maxQ = C_QuestLog.GetMaxNumQuestsCanAccept()
    end

    headerCount:SetText(tracked .. "/" .. maxQ)
end

-- =====================================
-- HIDE BLIZZARD HEADER
-- =====================================

local function HideBlizzardHeader()
    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    local header = tracker.Header or tracker.HeaderMenu
    if not header then return end

    -- Hide all regions (textures, fontstrings, lines)
    local regions = { header:GetRegions() }
    for _, region in ipairs(regions) do
        region:SetAlpha(0)
    end

    -- Hide all children (buttons, sub-frames)
    local children = { header:GetChildren() }
    for _, child in ipairs(children) do
        child:SetAlpha(0)
    end

    -- Also collapse height so it doesn't take space
    header:SetAlpha(0)
end

-- =====================================
-- M+ DETECTION
-- =====================================

local function IsInMythicPlus()
    return C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
end

-- =====================================
-- MASTER UPDATE
-- =====================================

local function OnTrackerUpdate()
    if not IsEnabled() then return end

    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    -- Reset font dedup so settings changes apply
    wipe(styledFonts)

    CreateOrUpdateBackground()
    CreateOrUpdateHeader()
    HideBlizzardHeader()
    ScanAndStyle(tracker, 0)
    UpdateQuestCount()

    -- In M+: hide title, count, dash — keep Options visible
    local inMP = IsInMythicPlus()
    if headerTitle then headerTitle:SetShown(not inMP) end
    if headerCount then headerCount:SetShown(not inMP) end
    if headerDash  then headerDash:SetShown(not inMP) end

    -- Visibility: check if tracker has actual visible content
    if skinFrame then
        local s = S()
        local trackerShown = tracker:IsShown()
        local trackerTop = tracker:GetTop()
        local hasContent = false

        if trackerShown and trackerTop then
            local children = { tracker:GetChildren() }
            for _, child in ipairs(children) do
                if child:IsShown() and child ~= skinFrame and child ~= headerBar
                   and child:GetBottom() then
                    hasContent = true
                    break
                end
            end
        end

        if hasContent then
            skinFrame:Show()
            if headerBar then headerBar:Show() end
        elseif s.hideWhenEmpty then
            skinFrame:Hide()
            if headerBar then headerBar:Hide() end
        end
    end
end

-- =====================================
-- HOOKS
-- =====================================

local function InstallHooks()
    if isHooked then return end
    isHooked = true

    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    -- Hook known layout methods
    for _, method in ipairs({ "Update", "SetShown", "Show", "MarkDirty" }) do
        if tracker[method] then
            hooksecurefunc(tracker, method, function()
                C_Timer.After(0.08, OnTrackerUpdate)
            end)
        end
    end

    -- Sync visibility: skinFrame is parented to UIParent, not tracker
    hooksecurefunc(tracker, "Hide", function()
        if skinFrame then skinFrame:Hide() end
        if headerBar then headerBar:Hide() end
    end)

    -- Event-driven updates
    local evFrame = CreateFrame("Frame")
    evFrame:RegisterEvent("QUEST_LOG_UPDATE")
    evFrame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
    evFrame:RegisterEvent("QUEST_ACCEPTED")
    evFrame:RegisterEvent("QUEST_REMOVED")
    evFrame:RegisterEvent("QUEST_TURNED_IN")
    evFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    evFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    evFrame:RegisterEvent("TRACKED_ACHIEVEMENT_UPDATE")

    local lastUpdate = 0
    evFrame:SetScript("OnEvent", function()
        local now = GetTime()
        if now - lastUpdate < 0.25 then return end
        lastUpdate = now
        C_Timer.After(0.15, OnTrackerUpdate)
    end)
end

-- =====================================
-- PUBLIC API
-- =====================================

function OT.ApplySettings()
    if not isInitialized then return end
    if not IsEnabled() then
        OT.Disable()
        return
    end
    OnTrackerUpdate()
end

function OT.Enable()
    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    CreateOrUpdateBackground()
    CreateOrUpdateHeader()
    HideBlizzardHeader()
    InstallHooks()

    C_Timer.After(0.5, OnTrackerUpdate)
end

function OT.Disable()
    if skinFrame then skinFrame:Hide() end
    if headerBar then headerBar:Hide() end

    local tracker = ObjectiveTrackerFrame
    if tracker then
        local header = tracker.Header or tracker.HeaderMenu
        if header then
            header:SetAlpha(1)
            local regions = { header:GetRegions() }
            for _, region in ipairs(regions) do
                region:SetAlpha(1)
            end
            local children = { header:GetChildren() }
            for _, child in ipairs(children) do
                child:SetAlpha(1)
            end
        end
    end
end

function OT.SetEnabled(value)
    if not TomoModDB or not TomoModDB.objectiveTracker then return end
    TomoModDB.objectiveTracker.enabled = value
    if value then
        OT.Enable()
        isInitialized = true
    else
        OT.Disable()
    end
end

function OT.Initialize()
    if isInitialized then return end
    if not IsEnabled() then return end

    local attempts = 0
    local function TryInit()
        attempts = attempts + 1
        if ObjectiveTrackerFrame then
            OT.Enable()
            isInitialized = true
        elseif attempts < 30 then
            C_Timer.After(0.5, TryInit)
        end
    end

    C_Timer.After(0.3, TryInit)
end

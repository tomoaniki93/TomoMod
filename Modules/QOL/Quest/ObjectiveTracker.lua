-- =====================================
-- ObjectiveTracker.lua
-- Skin for Blizzard's Objective Tracker (WoW 12.x)
-- Uses recursive child scanning for maximum compatibility
-- =====================================

TomoMod_ObjectiveTracker = TomoMod_ObjectiveTracker or {}
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
    -- FR + EN keywords — colors aligned with HorizonSuite palette
    ["CAMPAIGN"]        = { 1.00, 0.82, 0.20 },   -- Gold
    ["CAMPAGNE"]        = { 1.00, 0.82, 0.20 },
    ["QUÊTES"]          = { 0.90, 0.90, 0.90 },   -- Light grey (generic)
    ["QUESTS"]          = { 0.90, 0.90, 0.90 },
    ["QUEST"]           = { 0.90, 0.90, 0.90 },
    ["WORLD QUESTS"]    = { 0.78, 0.42, 0.95 },   -- Purple-violet
    ["QUÊTES MONDIALES"]= { 0.78, 0.42, 0.95 },
    ["EXPÉDITIONS"]     = { 0.32, 0.72, 0.68 },   -- Teal
    ["DELVES"]          = { 0.32, 0.72, 0.68 },
    ["BONUS"]           = { 0.25, 0.88, 0.92 },   -- Cyan
    ["SCENARIO"]        = { 0.38, 0.52, 0.88 },   -- Deep blue
    ["SCÉNARIO"]        = { 0.38, 0.52, 0.88 },
    ["ACHIEVEMENTS"]    = { 0.78, 0.48, 0.22 },   -- Bronze
    ["HAUTS FAITS"]     = { 0.78, 0.48, 0.22 },
    ["PROFESSIONS"]     = { 0.55, 0.75, 0.45 },   -- Sage green
    ["MÉTIERS"]         = { 0.55, 0.75, 0.45 },
    ["MONTHLY"]         = { 0.90, 0.30, 0.70 },
    ["MENSUEL"]         = { 0.90, 0.30, 0.70 },
    ["ADVENTURE"]       = { 0.90, 0.80, 0.50 },   -- Artifact gold
    ["AVENTURE"]        = { 0.90, 0.80, 0.50 },
    ["DUNGEON"]         = { 0.64, 0.21, 0.93 },   -- Epic purple
    ["DONJON"]          = { 0.64, 0.21, 0.93 },
    ["RAID"]            = { 0.85, 0.25, 0.25 },   -- Red
    ["CALLING"]         = { 0.20, 0.60, 1.00 },   -- Blue
    ["APPEL"]           = { 0.20, 0.60, 1.00 },
    ["WEEKLY"]          = { 0.25, 0.88, 0.92 },   -- Cyan
    ["HEBDOMADAIRE"]    = { 0.25, 0.88, 0.92 },
    ["DAILY"]           = { 0.25, 0.88, 0.92 },   -- Cyan
    ["QUOTIDIEN"]       = { 0.25, 0.88, 0.92 },
    ["PREY"]            = { 0.72, 0.22, 0.22 },   -- Dark crimson (Midnight)
    ["PROIE"]           = { 0.72, 0.22, 0.22 },
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

-- =====================================
-- QUEST TITLE COLORS (by quest type)
-- Inspired by HorizonSuite's color matrix system
-- Priority: complete > campaign > important > legendary > calling > dungeon > raid > world > weekly > daily > prey > delves > scenario > default
-- =====================================

local QUEST_TITLE_COLORS = {
    COMPLETE    = { 0.20, 1.00, 0.40 },   -- Green (ready to turn in)
    CAMPAIGN    = { 1.00, 0.82, 0.20 },   -- Gold
    IMPORTANT   = { 1.00, 0.45, 0.80 },   -- Pink
    LEGENDARY   = { 1.00, 0.50, 0.00 },   -- Orange
    CALLING     = { 0.20, 0.60, 1.00 },   -- Blue
    DUNGEON     = { 0.64, 0.21, 0.93 },   -- Epic purple
    RAID        = { 0.85, 0.25, 0.25 },   -- Red
    WORLD       = { 0.78, 0.42, 0.95 },   -- Purple-violet
    WEEKLY      = { 0.25, 0.88, 0.92 },   -- Cyan
    DAILY       = { 0.25, 0.88, 0.92 },   -- Cyan
    PREY        = { 0.72, 0.22, 0.22 },   -- Dark crimson (Midnight)
    DELVES      = { 0.32, 0.72, 0.68 },   -- Teal/seafoam
    SCENARIO    = { 0.38, 0.52, 0.88 },   -- Deep blue
    ADVENTURE   = { 0.90, 0.80, 0.50 },   -- Artifact gold
    ACHIEVEMENT = { 0.78, 0.48, 0.22 },   -- Bronze
    PROFESSION  = { 0.55, 0.75, 0.45 },   -- Sage green
    DEFAULT     = { 0.90, 0.90, 0.90 },   -- Light grey
}

-- Objective line colors per quest type (slightly dimmed vs title)
local QUEST_OBJECTIVE_COLORS = {
    COMPLETE    = { 0.20, 0.85, 0.35 },
    CAMPAIGN    = { 0.90, 0.75, 0.25 },
    IMPORTANT   = { 0.90, 0.45, 0.72 },
    LEGENDARY   = { 0.90, 0.48, 0.10 },
    CALLING     = { 0.25, 0.58, 0.90 },
    DUNGEON     = { 0.58, 0.25, 0.82 },
    RAID        = { 0.78, 0.28, 0.28 },
    WORLD       = { 0.70, 0.40, 0.85 },
    WEEKLY      = { 0.28, 0.78, 0.82 },
    DAILY       = { 0.28, 0.78, 0.82 },
    PREY        = { 0.65, 0.25, 0.25 },
    DELVES      = { 0.32, 0.65, 0.62 },
    SCENARIO    = { 0.38, 0.48, 0.78 },
    DEFAULT     = { 0.75, 0.75, 0.75 },
}

-- Extract questID from an objective tracker block (walks up parent chain)
local function GetBlockQuestID(frame)
    local f = frame
    for _ = 1, 4 do
        if not f then break end
        if f.questID then return f.questID end
        if f.id then return f.id end
        f = f:GetParent()
    end
    return nil
end

-- =====================================
-- QUEST BASE CATEGORY (inspired by HorizonSuite)
-- Uses C_QuestInfoSystem.GetQuestClassification + tag info fallbacks
-- =====================================

local questCategoryCache = setmetatable({}, { __mode = "v" })

local function GetQuestBaseCategory(questID)
    if not questID or questID <= 0 then return "DEFAULT" end

    -- Cache lookup
    local cached = questCategoryCache[questID]
    if cached then return cached end

    local category = "DEFAULT"

    -- 1) C_QuestInfoSystem.GetQuestClassification (most reliable on 12.x)
    if C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification then
        local ok, qc = pcall(C_QuestInfoSystem.GetQuestClassification, questID)
        if ok and qc then
            if qc == Enum.QuestClassification.Campaign then
                category = "CAMPAIGN"
            elseif qc == Enum.QuestClassification.Important then
                category = "IMPORTANT"
            elseif qc == Enum.QuestClassification.Legendary then
                category = "LEGENDARY"
            elseif qc == Enum.QuestClassification.Calling then
                category = "CALLING"
            elseif qc == Enum.QuestClassification.Recurring then
                -- Recurring: differentiate weekly vs daily via frequency
                local tagInfo = C_QuestLog.GetQuestTagInfo and C_QuestLog.GetQuestTagInfo(questID)
                if tagInfo and tagInfo.frequency then
                    if tagInfo.frequency == Enum.QuestFrequency.Daily then
                        category = "DAILY"
                    elseif tagInfo.frequency == Enum.QuestFrequency.Weekly then
                        category = "WEEKLY"
                    else
                        category = "WEEKLY" -- fallback for recurring
                    end
                else
                    category = "WEEKLY"
                end
            end
        end
    end

    -- 2) Fallback: Campaign detection via C_CampaignInfo
    if category == "DEFAULT" and C_CampaignInfo and C_CampaignInfo.IsCampaignQuest then
        local ok, isCampaign = pcall(C_CampaignInfo.IsCampaignQuest, questID)
        if ok and isCampaign then
            category = "CAMPAIGN"
        end
    end

    -- 3) Fallback: Important quest
    if category == "DEFAULT" and C_QuestLog.IsImportantQuest then
        local ok, isImp = pcall(C_QuestLog.IsImportantQuest, questID)
        if ok and isImp then
            category = "IMPORTANT"
        end
    end

    -- 4) World quest detection
    if category == "DEFAULT" then
        local isWorld = false
        if C_QuestLog.IsWorldQuest then
            local ok, val = pcall(C_QuestLog.IsWorldQuest, questID)
            isWorld = ok and val
        end
        if not isWorld and QuestUtils_IsQuestWorldQuest then
            local ok, val = pcall(QuestUtils_IsQuestWorldQuest, questID)
            isWorld = ok and val
        end
        if isWorld then
            category = "WORLD"
        end
    end

    -- 5) Tag-based detection: dungeon, raid, scenario, daily/weekly frequency
    if category == "DEFAULT" or category == "WORLD" then
        local tagInfo = C_QuestLog.GetQuestTagInfo and C_QuestLog.GetQuestTagInfo(questID)
        if tagInfo then
            -- Dungeon / Raid from tagID
            if tagInfo.tagID then
                if tagInfo.tagID == 81 then -- Dungeon
                    category = "DUNGEON"
                elseif tagInfo.tagID == 62 then -- Raid
                    category = "RAID"
                end
            end
            -- Frequency fallback for daily/weekly (if not already categorized)
            if category == "DEFAULT" and tagInfo.frequency then
                if tagInfo.frequency == Enum.QuestFrequency.Daily then
                    category = "DAILY"
                elseif tagInfo.frequency == Enum.QuestFrequency.Weekly then
                    category = "WEEKLY"
                end
            end
        end
    end

    -- 6) Calling detection (fallback)
    if category == "DEFAULT" and C_QuestLog.IsQuestCalling then
        local ok, isCalling = pcall(C_QuestLog.IsQuestCalling, questID)
        if ok and isCalling then
            category = "CALLING"
        end
    end

    questCategoryCache[questID] = category
    return category
end

-- Determine quest title color based on quest type
local function GetQuestTitleColor(questID)
    if not questID then return QUEST_TITLE_COLORS.DEFAULT end

    -- Ready to turn in (completed, not yet turned in) — always green
    if C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID) then
        return QUEST_TITLE_COLORS.COMPLETE
    end
    if C_QuestLog.ReadyForTurnIn and C_QuestLog.ReadyForTurnIn(questID) then
        return QUEST_TITLE_COLORS.COMPLETE
    end

    local category = GetQuestBaseCategory(questID)
    return QUEST_TITLE_COLORS[category] or QUEST_TITLE_COLORS.DEFAULT
end

-- Get quest category string for objective coloring
local function GetQuestCategory(questID)
    if not questID then return "DEFAULT" end
    if C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID) then
        return "COMPLETE"
    end
    if C_QuestLog.ReadyForTurnIn and C_QuestLog.ReadyForTurnIn(questID) then
        return "COMPLETE"
    end
    return GetQuestBaseCategory(questID)
end

local function StyleQuestTitle(fs, parentFrame)
    local s = S()
    local questID = GetBlockQuestID(parentFrame or (fs and fs:GetParent()))
    local color = GetQuestTitleColor(questID)
    StyleFontString(fs, ADDON_FONT_BOLD, s.questFontSize or 12, "OUTLINE", color[1], color[2], color[3], 0.95)
    -- Force color every pass (dedup only checks font/size, not color)
    if fs and fs.SetTextColor then
        fs:SetTextColor(color[1], color[2], color[3], 0.95)
    end
end

local function StyleObjectiveLine(fs, completed, parentFrame)
    local s = S()
    if completed then
        -- Completed: always green
        StyleFontString(fs, ADDON_FONT, s.objectiveFontSize or 11, "OUTLINE", 0.20, 0.85, 0.35, 1)
    else
        -- Incomplete: use quest-type tinted color for objectives
        local questID = GetBlockQuestID(parentFrame or (fs and fs:GetParent()))
        local category = GetQuestCategory(questID)
        local objColor = QUEST_OBJECTIVE_COLORS[category] or QUEST_OBJECTIVE_COLORS.DEFAULT
        StyleFontString(fs, ADDON_FONT, s.objectiveFontSize or 11, "OUTLINE", objColor[1], objColor[2], objColor[3], 0.90)
        -- Force color update
        if fs and fs.SetTextColor then
            fs:SetTextColor(objColor[1], objColor[2], objColor[3], 0.90)
        end
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
        StyleQuestTitle(frame.HeaderText, frame)
    end

    -- Check for objective lines (.Text + optional .Dash)
    if frame.Text and frame.Text.GetText and not frame.HeaderText then
        local txt = frame.Text:GetText()
        if txt and txt ~= "" then
            if frame.Dash then
                local done = IsObjectiveComplete(frame)
                StyleObjectiveLine(frame.Text, done, frame)
                StyleObjectiveLine(frame.Dash, done, frame)
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
-- QUEST DISPLAY LIMITER
-- =====================================

local overflowText = nil

local function CollectQuestBlocks(frame, depth, blocks)
    if not frame or depth > 6 then return end
    if frame == skinFrame or frame == headerBar then return end

    -- A frame with HeaderText is a quest/objective block
    if frame.HeaderText and frame.HeaderText.GetText then
        local txt = frame.HeaderText:GetText()
        if txt and txt ~= "" then
            blocks[#blocks + 1] = frame
        end
    end

    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        CollectQuestBlocks(child, depth + 1, blocks)
    end
end

local function LimitDisplayedQuests()
    local s = S()
    local maxQuests = s.maxQuestsShown or 0
    if maxQuests <= 0 then
        -- No limit: show all and hide overflow text
        if overflowText then overflowText:Hide() end
        return
    end

    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    local blocks = {}
    CollectQuestBlocks(tracker, 0, blocks)

    local hiddenCount = 0
    for i, block in ipairs(blocks) do
        if i > maxQuests then
            block:Hide()
            hiddenCount = hiddenCount + 1
        end
    end

    -- Show overflow indicator
    if hiddenCount > 0 and skinFrame then
        if not overflowText then
            overflowText = skinFrame:CreateFontString(nil, "OVERLAY")
            overflowText:SetFont(ADDON_FONT, 10, "OUTLINE")
            overflowText:SetTextColor(0.55, 0.55, 0.60, 0.9)
            overflowText:SetPoint("BOTTOMRIGHT", skinFrame, "BOTTOMRIGHT", -10, 6)
        end
        overflowText:SetText(string.format(L["ot_overflow_text"], hiddenCount))
        overflowText:Show()
    elseif overflowText then
        overflowText:Hide()
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
    if InCombatLockdown() then return end

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

    -- Reset font dedup and category cache so settings/status changes apply
    wipe(styledFonts)
    wipe(questCategoryCache)

    CreateOrUpdateBackground()
    CreateOrUpdateHeader()
    HideBlizzardHeader()
    ScanAndStyle(tracker, 0)
    UpdateQuestCount()
    LimitDisplayedQuests()

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

    if InCombatLockdown() then return end

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

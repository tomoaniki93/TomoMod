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
local _tmApplyingPosition = false -- guard so our own re-anchor doesn't recurse

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
    ["PROFESSION"]      = { 0.55, 0.75, 0.45 },
    ["MÉTIERS"]         = { 0.55, 0.75, 0.45 },
    ["MÉTIER"]          = { 0.55, 0.75, 0.45 },
    ["METIERS"]         = { 0.55, 0.75, 0.45 },   -- accent-stripped fallback
    ["METIER"]          = { 0.55, 0.75, 0.45 },
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

-- Blizzard's ObjectiveTrackerContainerTemplate owns a full-size NineSlice
-- ("common-opacity-background"), and its header templates animate their own
-- Background textures back to alpha 1. A one-shot SetAlpha(0) therefore only
-- lasts until the next native layout/update. Keep only those presentation
-- regions locked at zero while TomoMod owns the skin, then restore their exact
-- previous alpha when the module is disabled.
local nativeAlphaLocks     = setmetatable({}, { __mode = "k" })
local nativeAlphaHooks     = setmetatable({}, { __mode = "k" })
local nativeAlphaEnforcing = setmetatable({}, { __mode = "k" })
local nativeAlphaOriginal  = setmetatable({}, { __mode = "k" })

local function LockNativeAlpha(region)
    if not region or type(region.SetAlpha) ~= "function" then return end

    if nativeAlphaOriginal[region] == nil and type(region.GetAlpha) == "function" then
        nativeAlphaOriginal[region] = region:GetAlpha()
    end
    nativeAlphaLocks[region] = true

    if not nativeAlphaHooks[region] and hooksecurefunc then
        local ok = pcall(hooksecurefunc, region, "SetAlpha", function(self)
            if not nativeAlphaLocks[self] or nativeAlphaEnforcing[self] then return end
            nativeAlphaEnforcing[self] = true
            self:SetAlpha(0)
            nativeAlphaEnforcing[self] = nil
        end)
        if ok then nativeAlphaHooks[region] = true end
    end

    nativeAlphaEnforcing[region] = true
    region:SetAlpha(0)
    nativeAlphaEnforcing[region] = nil
end

local function LockNativeFrameTree(frame, depth)
    if not frame or (depth or 0) > 2 then return end
    LockNativeAlpha(frame)

    if frame.GetRegions then
        for _, region in ipairs({ frame:GetRegions() }) do
            LockNativeAlpha(region)
        end
    end
    if frame.GetChildren then
        for _, child in ipairs({ frame:GetChildren() }) do
            LockNativeFrameTree(child, (depth or 0) + 1)
        end
    end
end

local function RestoreNativeAlphaLocks()
    for region, alpha in pairs(nativeAlphaOriginal) do
        nativeAlphaLocks[region] = nil
        nativeAlphaEnforcing[region] = nil
        if region and type(region.SetAlpha) == "function" then
            region:SetAlpha(type(alpha) == "number" and alpha or 1)
        end
        nativeAlphaOriginal[region] = nil
    end
end

-- =====================================
-- GET COLOR FOR HEADER TEXT
-- =====================================

local function GetHeaderColor(text)
    if not text or text == "" then return nil end
    -- Lua's string.upper / string.lower only fold ASCII bytes, so accented
    -- characters (é, ê, ç, …) keep their case. We compare both the raw text
    -- and its naive upper/lower forms against every keyword's forms so that
    -- "Métier", "MÉTIER", "métier" all match the "MÉTIER" keyword.
    local upper = string.upper(text)
    local lower = string.lower(text)
    for keyword, color in pairs(HEADER_COLORS) do
        local kUp, kLo = string.upper(keyword), string.lower(keyword)
        if string.find(upper, kUp, 1, true)
            or string.find(lower, kLo, 1, true)
            or string.find(text,  keyword, 1, true) then
            return color
        end
    end
    return nil
end

-- =====================================
-- DETECT FRAME ROLE
-- =====================================

local function IsModuleHeader(frame)
    -- Quest blocks have HeaderText (the quest title); objective lines have Dash.
    -- Neither is ever a Blizzard module header — guard against false positives
    -- now that GetHeaderColor matches case-insensitively and accent-stripped.
    if frame.HeaderText or frame.Dash then
        return false, nil
    end
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

    -- Suppress the animated native module-header background permanently while
    -- the TomoMod skin is active.
    if frame.Background then LockNativeAlpha(frame.Background) end

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
    bar:SetStatusBarColor(0.180, 0.616, 0.847, 1)

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
    if frame._tmBucket then return end

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

    -- Position: wrap actual tracker content (+10px wider than the Blizzard tracker)
    skinFrame:ClearAllPoints()
    skinFrame:SetPoint("TOPLEFT", tracker, "TOPLEFT", -17, 12)
    skinFrame:SetPoint("TOPRIGHT", tracker, "TOPRIGHT", 17, 0)

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
        accent:SetColorTexture(0.180, 0.616, 0.847, 0.60)

        -- Title
        headerTitle = headerBar:CreateFontString(nil, "OVERLAY")
        headerTitle:SetFont(ADDON_FONT_BLACK, s.headerFontSize or 13, "OUTLINE")
        headerTitle:SetPoint("LEFT", headerBar, "LEFT", 10, 0)
        headerTitle:SetTextColor(0.95, 0.95, 0.97, 1)
        headerTitle:SetText(L["ot_header_title"])

        -- Options button
        --[[headerOptions = CreateFrame("Button", nil, headerBar)
        headerOptions:SetHeight(28)
        headerOptions.text = headerOptions:CreateFontString(nil, "OVERLAY")
        headerOptions.text:SetFont(ADDON_FONT, 11, "OUTLINE")
        headerOptions.text:SetPoint("CENTER")
        headerOptions.text:SetTextColor(0.55, 0.55, 0.60, 1)
        headerOptions.text:SetText(L["ot_header_options"])
        headerOptions:SetWidth(headerOptions.text:GetStringWidth() + 10)
        headerOptions:SetPoint("RIGHT", headerBar, "RIGHT", -60, 0)
        headerOptions:SetScript("OnEnter", function(self)
            self.text:SetTextColor(0.180, 0.616, 0.847, 1)
        end)
        headerOptions:SetScript("OnLeave", function(self)
            self.text:SetTextColor(0.55, 0.55, 0.60, 1)
        end)
        headerOptions:SetScript("OnClick", function()
            if TomoMod_Config and TomoMod_Config.Toggle then
                TomoMod_Config.Toggle()
            end
        end)]]--

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

-- Forward declaration: HideBlizzardHeader is defined before the combat
-- deferral block below, so this must already be a local upvalue at that point.
local MarkLayoutPending

local function HideBlizzardHeader()
    if InCombatLockdown() then MarkLayoutPending(); return end

    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    -- Retail's ObjectiveTrackerContainerTemplate includes a full-size native
    -- opacity backdrop. It is separate from Header, so hiding the header alone
    -- leaves a second translucent panel behind TomoMod's skin.
    LockNativeFrameTree(tracker.NineSlice, 0)

    local header = tracker.Header or tracker.HeaderMenu
    if not header then return end

    -- Hide all regions (textures, fontstrings, lines)
    local regions = { header:GetRegions() }
    for _, region in ipairs(regions) do
        LockNativeAlpha(region)
    end

    -- Hide all children (buttons, sub-frames)
    local children = { header:GetChildren() }
    for _, child in ipairs(children) do
        LockNativeFrameTree(child, 0)
    end

    -- Also collapse height so it doesn't take space
    LockNativeAlpha(header)
end

-- =====================================
-- M+ DETECTION
-- =====================================

local function IsInMythicPlus()
    return C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
end

-- =====================================
-- BUCKETS (Option A: re-anchor Blizzard quest blocks into collapsible groups)
-- =====================================

local BUCKET_ORDER = {
    "COMPLETE", "CAMPAIGN", "IMPORTANT", "LEGENDARY",
    "WEEKLY", "DAILY", "WORLD", "DUNGEON", "RAID",
    "PROFESSION", "ACHIEVEMENT", "DEFAULT", "OTHER",
}

local function BL(key, fallback)
    local s = L and L[key]
    if s and s ~= "" and s ~= key then return s end
    return fallback
end

local function BucketLabel(key)
    if key == "COMPLETE"   then return BL("ot_bucket_complete",   "Ready to Turn In") end
    if key == "CAMPAIGN"   then return BL("ot_bucket_campaign",   "Campaign") end
    if key == "IMPORTANT"  then return BL("ot_bucket_important",  "Important") end
    if key == "LEGENDARY"  then return BL("ot_bucket_legendary",  "Legendary") end
    if key == "WEEKLY"     then return BL("ot_bucket_weekly",     "Weekly") end
    if key == "DAILY"      then return BL("ot_bucket_daily",      "Daily") end
    if key == "WORLD"      then return BL("ot_bucket_world",      "World Quests") end
    if key == "DUNGEON"    then return BL("ot_bucket_dungeon",    "Dungeons") end
    if key == "RAID"       then return BL("ot_bucket_raid",       "Raids") end
    if key == "PROFESSION" then return BL("ot_bucket_profession", "Professions") end
    if key == "ACHIEVEMENT" then return BL("ot_bucket_achievement", "Achievements") end
    if key == "DEFAULT"    then return BL("ot_bucket_quests",     "Quests") end
    if key == "OTHER"      then return BL("ot_bucket_other",      "Other") end
    return key
end

local bucketFrames = {}      -- [key] = { frame, header, chev, label, count }
local bucketEnabled = true   -- mirrors S().buckets at update time

local function BucketsCollapsedTable()
    local db = TomoModDB and TomoModDB.objectiveTracker
    if not db then return nil end
    db.bucketsCollapsed = db.bucketsCollapsed or {}
    return db.bucketsCollapsed
end

local function IsBucketCollapsed(key)
    local t = BucketsCollapsedTable()
    return t and t[key] == true
end

-- =====================================
-- [fix 3.6.1] COMBAT DEFERRAL
-- =====================================
-- Every layout path in this file bails out on InCombatLockdown(), and rightly
-- so: quest blocks parent the secure QuestObjectiveItem button, so Hide /
-- SetParent / SetPoint on a block are protected operations. What was missing is
-- the other half of a combat guard -- remembering that the work was skipped and
-- replaying it. PLAYER_REGEN_ENABLED was never even registered, so a quest that
-- arrived during a fight (or a /reload taken in combat) left the tracker in a
-- half-laid-out state until some unrelated quest event happened to fire much
-- later. That is the reported overlap: the new Blizzard-positioned block paints
-- over our bucket stack, and a block belonging to a collapsed bucket that
-- Blizzard re-Shows mid-fight stays on screen underneath the headers.
local _tmPendingLayout  = false  -- layout work skipped because of the lockdown
local _tmPendingDisable = false  -- OT.Disable() restore skipped because of it
local _tmPlacedCount    = 0      -- blocks positioned under skinFrame, last pass
local _tmCombatAlpha    = {}     -- [block or button] = alpha to restore

MarkLayoutPending = function()
    _tmPendingLayout = true
end

-- SetAlpha is never a protected operation, unlike Hide/SetPoint/SetParent, so
-- it is the one tool available while the lockdown is on. Used to keep an
-- unplaced or wrongly-reappearing frame from painting over the layout until the
-- real pass can run.
local function CombatSuppressAlpha(frame)
    if not frame or _tmCombatAlpha[frame] then return end
    if not frame.GetAlpha or not frame.SetAlpha then return end
    _tmCombatAlpha[frame] = frame:GetAlpha() or 1
    frame:SetAlpha(0)
    MarkLayoutPending()
end

local function RestoreCombatSuppressedAlpha()
    for frame, alpha in pairs(_tmCombatAlpha) do
        if frame and frame.SetAlpha then
            frame:SetAlpha(type(alpha) == "number" and alpha or 1)
        end
    end
    wipe(_tmCombatAlpha)
end

-- Called from OnTrackerUpdate while locked down. Only meaningful once a layout
-- pass has actually placed something under skinFrame: on a fresh /reload taken
-- in combat nothing is placed yet, the Blizzard tracker is alone on screen and
-- perfectly readable, so blanking it would be a regression rather than a fix.
local function SuppressUnplacedBlocksInCombat()
    if not bucketEnabled or not skinFrame then return end
    if _tmPlacedCount <= 0 then return end
    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    -- CollectQuestBlocks stops at skinFrame, so everything it returns here is a
    -- block still living in Blizzard's tree, i.e. one we have not placed.
    local blocks = {}
    CollectQuestBlocks(tracker, 0, blocks)
    for _, b in ipairs(blocks) do
        if b.IsShown and b:IsShown() then
            CombatSuppressAlpha(b)
        end
    end
end

-- =====================================================================
-- RIGHT-EDGE BUTTONS (item + "recherche de groupe") d'un bloc de quete
-- ---------------------------------------------------------------------
-- Ces boutons sont ancres au bloc mais PARENTES au ContentsFrame du
-- module (pool Blizzard) : block:Hide() ne les masque donc pas. On les
-- enumere par l'intersection block.addedRegions et block.parentModule.
-- usedRightEdgeFrames -> uniquement les boutons de CE bloc (jamais les
-- timer/progress bars, jamais les boutons d'un autre bloc). Fallback sur
-- le champ nomme block.itemButton si ces tables internes manquent.
-- =====================================================================
local function ForEachBlockRightEdgeButton(block, fn)
    if not block then return end
    local handled
    local mod   = block.parentModule
    local used  = mod and mod.usedRightEdgeFrames
    local added = block.addedRegions
    if used and added then
        for _, frame in pairs(used) do
            if frame and added[frame] ~= nil then
                handled = handled or {}
                handled[frame] = true
                fn(frame)
            end
        end
    end
    -- Fallback : bouton d'objet nomme (comportement historique).
    local ib = block.itemButton
    if ib and not (handled and handled[ib]) then
        fn(ib)
    end
end

-- Masque a la reduction tous les right-edge buttons du bloc, avec le meme
-- garde anti-reapparition que le bloc (hook Show + garde combat ; Layout-
-- Buckets ne tourne qu'hors combat mais Blizzard peut re-Show pendant un
-- Update en combat).
local function HideBlockButtons(block)
    ForEachBlockRightEdgeButton(block, function(btn)
        if not btn._tmShowHooked then
            btn._tmShowHooked = true
            hooksecurefunc(btn, "Show", function(self)
                if not bucketEnabled then return end
                local b = self._tmBucketBlock
                local k = b and b._tmBucketKey
                if not (k and IsBucketCollapsed(k)) then return end
                -- [COMBAT] This is the secure QuestObjectiveItem button: Hide()
                -- on it under lockdown is a blocked action. Alpha only, and the
                -- deferred pass hides it properly after combat. Mouse state is
                -- left alone on purpose -- EnableMouse on a protected frame is
                -- itself restricted.
                if InCombatLockdown() then
                    CombatSuppressAlpha(self)
                    return
                end
                self:Hide()
            end)
        end
        btn._tmBucketBlock = block
        -- Ne marquer/masquer que s'il est reellement visible : le bouton est
        -- mis en pool par Blizzard et peut persister masque (quete sans objet
        -- utilisable) -> sinon on le re-afficherait a tort a l'expansion.
        if btn:IsShown() then
            btn._tmHiddenByBucket = true
            btn:Hide()
        end
    end)
end

-- Re-affiche a l'expansion uniquement les boutons qu'on avait masques soi-
-- meme (Blizzard corrige ensuite si l'objet n'est plus utilisable, lors de
-- son Update).
local function ShowBlockButtons(block)
    ForEachBlockRightEdgeButton(block, function(btn)
        if btn._tmHiddenByBucket then
            btn._tmHiddenByBucket = false
            btn:Show()
        end
    end)
end

local LayoutBuckets -- forward

-- Re-entry guard for LayoutBuckets / OnTrackerUpdate.
-- LayoutBuckets calls block:Layout() / SetParent / SetPoint which re-fire
-- ObjectiveTrackerFrame:Update + MarkDirty via Blizzard's bookkeeping.
-- Without these guards our hooksecurefunc chain recurses and produces the
-- visible "trembling" feedback loop.
local _tmInLayout    = false   -- true while LayoutBuckets is mutating frames
-- [fix] Authoritative "is anything actually tracked" flag, written by the
-- layout passes which are the only code that really knows. Visibility used
-- to be decided by scanning ObjectiveTrackerFrame's children, which is
-- wrong in both directions: several Blizzard module containers stay shown
-- (and full height) with nothing tracked, so it read true on an empty
-- tracker; and in bucket mode our own blocks are re-parented to skinFrame,
-- so they are not tracker children at all.
local _tmHasContent  = false
local _tmPendingPump = false   -- true while a deferred OnTrackerUpdate is queued
local _tmSilenceHook = 0       -- > 0 means: ignore hook callbacks (we caused them)
local _tmHiddenModules = {}    -- WQ module frames we've alpha=0'd (not reparented)
local _strayBars = {}          -- StatusBar frames hidden by layout; restored by DisableBuckets


local function RunPendingPump()
    _tmPendingPump = false
    -- forward call without re-entry; OnTrackerUpdate guards itself too
    if OT and OT._OnTrackerUpdate then OT._OnTrackerUpdate() end
end

local function PumpUpdateSoon()
    -- Ignore notifications that we ourselves triggered while laying out.
    if _tmInLayout or _tmSilenceHook > 0 then return end
    if _tmPendingPump then return end
    _tmPendingPump = true
    -- Named function rather than an inline closure: the pump is coalesced but
    -- still fires on every event burst, and the closure allocated each time.
    C_Timer.After(0, RunPendingPump)
end

local function ToggleBucket(key)
    local t = BucketsCollapsedTable(); if not t then return end
    t[key] = not t[key]
    LayoutBuckets()
    -- Heights of just-expanded blocks may be stale for a frame or two
    C_Timer.After(0,    function() if LayoutBuckets then LayoutBuckets() end end)
    C_Timer.After(0.05, function() if LayoutBuckets then LayoutBuckets() end end)
end

local function GetOrCreateBucket(key)
    if bucketFrames[key] then return bucketFrames[key] end
    if not skinFrame then return nil end

    local f = CreateFrame("Button", nil, skinFrame)
    f:SetHeight(20)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(skinFrame:GetFrameLevel() + 20)
    f._tmBucket = true
    f:RegisterForClicks("LeftButtonUp")
    f:SetScript("OnClick", function() ToggleBucket(key) end)

    -- Subtle accent line under header
    local accent = f:CreateTexture(nil, "ARTWORK")
    accent:SetColorTexture(1, 1, 1, 0.10)
    accent:SetHeight(1)
    accent:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 0)
    accent:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 0)

    local chev = f:CreateFontString(nil, "OVERLAY")
    chev:SetFont(ADDON_FONT_BLACK, 13, "OUTLINE")
    chev:SetPoint("LEFT", f, "LEFT", 6, 0)
    chev:SetText("-")

    local label = f:CreateFontString(nil, "OVERLAY")
    label:SetFont(ADDON_FONT_BLACK, 12, "OUTLINE")
    label:SetPoint("LEFT", chev, "RIGHT", 6, 0)

    local count = f:CreateFontString(nil, "OVERLAY")
    count:SetFont(ADDON_FONT, 11, "OUTLINE")
    count:SetPoint("RIGHT", f, "RIGHT", -6, 0)
    count:SetTextColor(0.65, 0.65, 0.70, 0.95)

    f:SetScript("OnEnter", function() accent:SetColorTexture(1, 1, 1, 0.25) end)
    f:SetScript("OnLeave", function() accent:SetColorTexture(1, 1, 1, 0.10) end)

    bucketFrames[key] = { frame = f, chev = chev, label = label, count = count, accent = accent }
    return bucketFrames[key]
end

local function ClassifyBlock(block)
    -- Prefer block.id (Blizzard sets it for quest blocks), fall back to questID or parent walk
    local qid = block.id or block.questID
    if (not qid) or qid == 0 then
        qid = GetBlockQuestID(block)
    end
    if qid and qid > 0 then
        local cat = GetQuestCategory(qid)
        -- Fold rare/unsupported categories into broader buckets
        if cat == "CALLING" then return "DAILY" end
        if cat == "PREY" or cat == "DELVES" or cat == "SCENARIO" or cat == "ADVENTURE" then
            return "OTHER"
        end
        return cat or "DEFAULT"
    end
    return "OTHER"
end

-- =====================================
-- SPECIAL MODULES (scenario / delve / bonus objectives / widgets)
-- =====================================

-- Module containers we never break into buckets: their internals are anchored
-- to each other and come apart when re-parented, so they move as one block.
local function IsSpecialModule(f)
    if not f or not f.GetName then return false end
    local n = f:GetName()
    if not n then return false end
    return (n:find("BonusObjective", 1, true)
         or n:find("Scenario",       1, true)
         or n:find("UIWidget",       1, true)
         or n:find("Delve",          1, true)) ~= nil
end

-- "Is shown" is not a content test: Blizzard keeps several module containers
-- alive and shown with nothing inside them. Look for something actually
-- rendered -- a non-empty FontString or a status bar -- inside the subtree.
-- IsShown, never IsVisible: the panel itself may currently be hidden by
-- "hide when empty", and IsVisible would then report every module as empty,
-- which would keep the panel hidden forever.
local function ModuleHasVisibleContent(f, depth)
    depth = depth or 0
    if not f or depth > 5 then return false end
    if f.IsShown and not f:IsShown() then return false end
    if f.IsObjectType and f:IsObjectType("StatusBar") then return true end
    -- select() over the varargs instead of { ... }: this walk descends five
    -- levels over a tree that reaches a couple of hundred frames in a delve or
    -- scenario, and every node allocated two throwaway tables. The other
    -- { :GetChildren() } sites in this file are one-shot layout passes and are
    -- deliberately left alone.
    if f.GetRegions then
        local n = select("#", f:GetRegions())
        for i = 1, n do
            local r = select(i, f:GetRegions())
            if r and r.IsObjectType and r:IsObjectType("FontString") and r:IsShown() then
                local txt = r:GetText()
                if txt and txt ~= "" then return true end
            end
        end
    end
    if f.GetChildren then
        local n = select("#", f:GetChildren())
        for i = 1, n do
            local c = select(i, f:GetChildren())
            if c and ModuleHasVisibleContent(c, depth + 1) then return true end
        end
    end
    return false
end

-- True when a scenario / delve / bonus-objective module is on screen with real
-- content in it. That content lives outside the quest-block collection (those
-- subtrees are deliberately skipped), so counting blocks alone reads a delve
-- run -- criteria tracked, often no quest at all -- as an empty tracker.
-- Depth mirrors the layout walk (walkForSkipped): Blizzard does not always
-- hang these modules straight off the tracker.
local function HasSpecialModuleContent(parent, depth)
    depth = depth or 0
    if not parent or not parent.GetChildren or depth > 2 then return false end
    local n = select("#", parent:GetChildren())
    for i = 1, n do
        local child = select(i, parent:GetChildren())
        if child and IsSpecialModule(child) then
            if child:IsShown() and ModuleHasVisibleContent(child, 0) then
                return true
            end
        elseif child and not child.HeaderText and HasSpecialModuleContent(child, depth + 1) then
            return true
        end
    end
    return false
end

LayoutBuckets = function()
    if _tmInLayout then return end
    _tmInLayout = true
    _tmHiddenModules = {}   -- reset each pass
    _strayBars = {}
    if not bucketEnabled then
        -- Re-show any blocks we may have hidden, hide bucket headers
        for _, bf in pairs(bucketFrames) do bf.frame:Hide() end
        _tmInLayout = false
        return
    end
    if InCombatLockdown() then _tmInLayout = false; MarkLayoutPending(); return end
    if not skinFrame or not headerBar then _tmInLayout = false; return end

    -- Out of combat now: anything alpha-suppressed during the fight goes back to
    -- its own alpha before the pass measures and repositions it.
    RestoreCombatSuppressedAlpha()

    local tracker = ObjectiveTrackerFrame
    if not tracker then _tmInLayout = false; return end

    -- Collect quest blocks from BOTH the Blizzard tracker AND our skinFrame
    -- (blocks already re-parented in previous passes live under skinFrame).
    -- We deliberately skip BonusObjective / Scenario module subtrees: they
    -- render rich reward previews (Delves, M+ scenarios) whose internal anchors
    -- break when re-parented.  WorldQuest is intentionally NOT skipped here so
    -- individual WQ quest blocks are collected and placed in the WORLD bucket.
    -- The now-empty WQ module frame is hidden separately by HideWorldQuestModules.
    local function shouldSkipSubtree(frame)
        if not frame or not frame.GetName then return false end
        local n = frame:GetName()
        if not n then return false end
        if n:find("BonusObjective", 1, true)
            or n:find("Scenario", 1, true)
            or n:find("UIWidget", 1, true) then
            return true
        end
        return false
    end

    -- Detect blocks that embed a reward / dungeon / item preview popup
    -- (Delves, weekly M+ vault, certain campaign quests). Their internal
    -- anchors break when re-parented, producing the visible overlap.
    local function HasRewardPreview(f, depth)
        if depth > 4 or not f then return false end
        if f.GetName then
            local n = f:GetName()
            if n and (
                n:find("Reward", 1, true)
                or n:find("ItemPreview", 1, true)
                or n:find("DungeonScore", 1, true)
                or n:find("Loot", 1, true)
            ) then return true end
        end
        -- Field-based detection (template-set table members)
        if f.RewardsFrame or f.ItemPreviewFrame or f.itemPreviewPool then
            return true
        end
        if f.GetChildren then
            for _, c in ipairs({ f:GetChildren() }) do
                if HasRewardPreview(c, depth + 1) then return true end
            end
        end
        return false
    end

    local function collectAll(root, depth, out, seen)
        if not root or depth > 6 then return end
        if root == headerBar then return end
        if shouldSkipSubtree(root) then return end
        -- A frame with non-empty HeaderText is a quest block
        if root.HeaderText and root.HeaderText.GetText then
            local txt = root.HeaderText:GetText()
            if txt and txt ~= "" and not seen[root] then
                -- Skip blocks with embedded reward popups (Delves etc.)
                if not HasRewardPreview(root, 0) then
                    seen[root] = true
                    out[#out + 1] = root
                end
            end
        end
        if root.GetChildren then
            for _, c in ipairs({ root:GetChildren() }) do
                if not c._tmBucket then
                    collectAll(c, depth + 1, out, seen)
                end
            end
        end
    end

    local blocks, seen = {}, {}
    collectAll(tracker, 0, blocks, seen)
    collectAll(skinFrame, 0, blocks, seen)

    -- Emptiness is decided further down, once the scenario / delve modules
    -- have been placed: they carry content of their own that never shows up
    -- in `blocks`, so a delve with no tracked quest is not an empty tracker.

    -- Group by bucket key
    local groups = {}
    for _, b in ipairs(blocks) do
        local key = ClassifyBlock(b)
        groups[key] = groups[key] or {}
        table.insert(groups[key], b)
    end

    -- Hide Blizzard module headers (per-zone titles become redundant with buckets).
    -- We scan BOTH the tracker AND skinFrame because a re-parented block can
    -- carry a child header along with it (notably the Profession recipe tracker
    -- which embeds the "Métiers" header inside the block hierarchy).
    local function HideModuleHeaders(frame, depth)
        if depth > 6 or not frame then return end
        if frame._tmBucket then return end
        if IsModuleHeader(frame) then
            frame:SetAlpha(0)
            frame:SetHeight(0.01)
            if frame.Hide then frame:Hide() end
        end
        local children = { frame:GetChildren() }
        for _, c in ipairs(children) do HideModuleHeaders(c, depth + 1) end
    end
    HideModuleHeaders(tracker, 0)
    HideModuleHeaders(skinFrame, 0)

    -- Layout: vertical stack inside skinFrame below headerBar
    local headerBarH = (headerBar:GetHeight() or 28)
    local PAD_LEFT_HEADER = 4
    local PAD_LEFT_BLOCK  = 32     -- leave room for the quest icon on the left
    local PAD_RIGHT       = 6
    local TOP_GAP         = 6
    local BLOCK_GAP       = 4
    local BUCKET_GAP      = 6

    local yStart  = -(headerBarH + TOP_GAP)
    local yOffset = yStart

    -- ── STEP 1: Scenario / Delve / BonusObjective modules FIRST (top) ─────────
    -- Mirrors Blizzard's default order: active scenario/delve sits above quests.
    local function reanchorSkippedModule(f, yCursor)
        if not f or not f.IsShown or not f:IsShown() then return yCursor end
        if not IsSpecialModule(f) then return yCursor end
        -- A shown module is not necessarily a filled one. Placing an empty
        -- container would reserve the 40px minimum below for nothing, and --
        -- worse -- would make the panel read as "has content" and stay on
        -- screen forever, which is the giant empty panel all over again.
        if not ModuleHasVisibleContent(f, 0) then return yCursor end
        -- Stash original anchor + parent once so DisableBuckets can restore.
        if not f._tmOriginalAnchor then
            local p, parent, rp, x, y = f:GetPoint(1)
            if p then
                f._tmOriginalAnchor = { p, parent, rp, x, y }
            else
                f._tmOriginalAnchor = false
            end
            f._tmOriginalParent2 = f:GetParent()
        end
        f:SetParent(skinFrame)
        f:SetFrameStrata("MEDIUM")
        f:SetFrameLevel(skinFrame:GetFrameLevel() + 5)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT",  skinFrame, "TOPLEFT",  PAD_LEFT_HEADER, yCursor)
        f:SetPoint("TOPRIGHT", skinFrame, "TOPRIGHT", -PAD_RIGHT,      yCursor)

        -- Save our anchor Y so the SetPoint hook can re-apply it.
        f._tmAnchorY   = yCursor
        f._tmAnchorL   = PAD_LEFT_HEADER
        f._tmAnchorR   = PAD_RIGHT

        -- Hook SetPoint once on this module frame so that any time Blizzard
        -- repositions it (e.g. tracker:Update() called by opening the Quest Journal),
        -- we immediately restore our anchor in the same WoW tick — before the GPU
        -- renders the frame — eliminating the one-frame flicker entirely.
        if not f._tmPositionHooked then
            f._tmPositionHooked = true
            hooksecurefunc(f, "SetPoint", function(self)
                if _tmInLayout then return end          -- we caused this call, ignore
                if not self._tmAnchorY or not skinFrame then return end
                -- Blizzard tried to reposition us — override immediately.
                _tmInLayout = true
                self:ClearAllPoints()
                self:SetPoint("TOPLEFT",  skinFrame, "TOPLEFT",  self._tmAnchorL or 4,  self._tmAnchorY)
                self:SetPoint("TOPRIGHT", skinFrame, "TOPRIGHT", -(self._tmAnchorR or 6), self._tmAnchorY)
                _tmInLayout = false
            end)
        end

        ScanAndStyle(f, 0)
        if f.Layout then pcall(f.Layout, f) end
        local h = f:GetHeight() or 0
        if h < 40  then h = 40  end
        if h > 240 then h = 240 end
        return yCursor - h - BLOCK_GAP
    end

    local function walkForSkipped(parent, depth)
        depth = depth or 0
        if not parent or not parent.GetChildren or depth > 2 then return end
        for _, child in ipairs({ parent:GetChildren() }) do
            -- WorldQuest module frames: WQ blocks are now collected individually
            -- into the WORLD bucket; just suppress the now-empty module container.
            local cn = child.GetName and child:GetName()
            if cn and cn:find("WorldQuest", 1, true) then
                if child:IsShown() then
                    child:SetAlpha(0)
                    _tmHiddenModules[#_tmHiddenModules + 1] = child
                end
            elseif IsSpecialModule(child) then
                yOffset = reanchorSkippedModule(child, yOffset)
            elseif child ~= headerBar and not child._tmBucket and not child.HeaderText then
                -- Blizzard does not always hang its module frames straight off
                -- the tracker, so look a couple of levels down instead of
                -- assuming they are direct children. Quest blocks (HeaderText)
                -- and our own bucket frames are never descended into: a widget
                -- living inside a block belongs to that block, not to us.
                walkForSkipped(child, depth + 1)
            end
        end
    end
    -- Walk both tracker and skinFrame (modules migrate to skinFrame on subsequent passes).
    walkForSkipped(tracker)
    walkForSkipped(skinFrame)

    -- ── Orphan StatusBar sweep (used by STEP 4, and by the delve-only exit) ───
    -- Module-level progress bars (WQ weekly progress, enemy forces, etc.) are
    -- sometimes parented to BlocksFrame rather than to a specific quest block, so
    -- block:Hide() doesn't reach them.  SetIgnoreParentAlpha on them also bypasses
    -- the WQ module SetAlpha(0) guard, leaving a floating "0%" bar.
    -- All active blocks are now under skinFrame; any StatusBar still in the
    -- original tracker subtree is orphaned and should be hidden.
    --
    -- Returns the reparented frame a bar ultimately belongs to, or nil when
    -- the bar is genuinely orphaned.
    --
    -- A bar sits several steps away from its block. ObjectiveTrackerProgressBar-
    -- Template is a *container* Frame holding the real StatusBar as its `Bar`
    -- child, and that child is anchored to the container, not to the block.
    -- The container itself is parented to the module's own ContentsFrame
    -- (ObjectiveTrackerModuleMixin:AcquireFrame does SetParent(self.ContentsFrame))
    -- and is only *anchored* to the block. So reading the bar's own anchor
    -- landed on the container -- which never sits under skinFrame -- and every
    -- quest progress bar was swept away, leaving the mob tooltip as the only
    -- way to follow progress.
    --
    -- Walking parents and anchor targets together reaches the block whatever
    -- the nesting: parent hop to the container, anchor hop to the block.
    local function LiveHostOf(bar)
        local seen, queue, count, i = {}, { bar }, 1, 1
        while i <= count and i <= 32 do
            local cur = queue[i]
            i = i + 1
            if cur and not seen[cur] then
                seen[cur] = true
                -- Nearest host first: a tagged block, then any frame we
                -- reparented directly under skinFrame (scenario / delve
                -- modules carry no bucket key), then skinFrame itself.
                -- Returning skinFrame too early would gate visibility on the
                -- whole panel instead of on the block that owns the bar.
                if cur._tmBucketKey then return cur end
                if cur.GetParent and cur:GetParent() == skinFrame then return cur end
                if cur == skinFrame then return cur end
                -- Reaching the untouched tracker tree means this branch is
                -- orphaned; don't expand through it.
                if cur ~= tracker then
                    if cur.GetParent then
                        local parent = cur:GetParent()
                        if parent then count = count + 1; queue[count] = parent end
                    end
                    local numPoints = cur.GetNumPoints and cur:GetNumPoints() or 0
                    for pi = 1, numPoints do
                        local _, relTo = cur:GetPoint(pi)
                        if relTo then count = count + 1; queue[count] = relTo end
                    end
                end
            end
        end
        return nil
    end

    local function HideStrayBars(f, d)
        if not f or d > 8 then return end
        if f == skinFrame or f._tmBucket then return end
        if f:IsObjectType("StatusBar") then
            -- A bar hidden by an earlier pass has to be reconsidered here too.
            -- Looking only at bars that are currently shown made this a
            -- one-way trip: collapsing a bucket hid its progress bar, and
            -- expanding it again re-ran this sweep, which skipped the bar
            -- because it was no longer shown. Nothing ever brought it back.
            -- `_tmStrayHidden` marks the bars WE hid, so a bar Blizzard is
            -- legitimately keeping hidden is still none of our business.
            if f:IsShown() or f._tmStrayHidden then
                -- Keep bars owned by a tracked, expanded block; hide everything
                -- else (empty WQ module progress, floating "0%" bars, bars whose
                -- block is collapsed or hidden) exactly as before.
                local host = LiveHostOf(f)
                if host and host:IsVisible() then
                    if f._tmStrayHidden then
                        f._tmStrayHidden = nil
                        f:Show()
                    end
                    -- These bars are not children of the block, so the per-block
                    -- ScanAndStyle pass never reaches them. Style them here so a
                    -- progress bar matches the rest of the tracker.
                    StyleStatusBar(f)
                else
                    if f:IsShown() then f:Hide() end
                    f._tmStrayHidden = true
                    _strayBars[#_strayBars + 1] = f
                end
                return  -- no need to recurse into a progress bar
            end
        end
        if f.GetChildren then
            for _, c in ipairs({ f:GetChildren() }) do HideStrayBars(c, d + 1) end
        end
    end

    -- ── Emptiness verdict ─────────────────────────────────────────────────────
    -- yOffset only moves when a scenario / delve / bonus module was actually
    -- placed, which is exactly the "content Blizzard owns" case.
    local hasSpecial = (yOffset < yStart)
    _tmHasContent = (#blocks > 0) or hasSpecial

    if #blocks == 0 then
        for _, bf in pairs(bucketFrames) do bf.frame:Hide() end
        if hasSpecial then
            -- A delve or a scenario with no quest tracked alongside it: the
            -- panel keeps only what STEP 1 placed. Sweeping stray bars here
            -- too, since the criteria bars now live under skinFrame and the
            -- ones left behind in Blizzard's tree are the floating "0%" kind.
            HideStrayBars(tracker, 0)
            local totalH = math.abs(yOffset) + 10
            if totalH < 60 then totalH = 60 end
            skinFrame:SetHeight(totalH)
        elseif skinFrame and headerBar then
            -- [fix] This early return used to leave the height computed by
            -- CreateOrUpdateBackground in place. That measurement walks
            -- Blizzard's own children and keeps the lowest visible bottom --
            -- and some of those containers stay shown at nearly full height
            -- with nothing tracked, which is why an empty tracker showed a
            -- panel spanning most of the screen. Collapse to the header.
            skinFrame:SetHeight((headerBar:GetHeight() or 28) + 16)
        end
        -- The pass completed, it just had nothing to place.
        _tmPlacedCount = 0
        _tmPendingLayout = false
        _tmInLayout = false
        _tmSilenceHook = _tmSilenceHook + 1
        C_Timer.After(0.20, function()
            _tmSilenceHook = math.max(0, _tmSilenceHook - 1)
        end)
        return
    end

    -- ── STEP 2: Quest buckets BELOW the scenario/delve block ──────────────────
    if yOffset < yStart then
        yOffset = yOffset - BUCKET_GAP   -- extra gap between delve and first bucket
    end

    for _, key in ipairs(BUCKET_ORDER) do
        local group = groups[key]
        if group and #group > 0 then
            local bf = GetOrCreateBucket(key)
            if bf then
                local color = QUEST_TITLE_COLORS[key] or QUEST_TITLE_COLORS.DEFAULT
                local collapsed = IsBucketCollapsed(key)

                bf.chev:SetText(collapsed and "+" or "-")
                bf.chev:SetTextColor(color[1], color[2], color[3], 1)
                bf.label:SetText(BucketLabel(key))
                bf.label:SetTextColor(color[1], color[2], color[3], 1)
                bf.count:SetText(tostring(#group))

                bf.frame:ClearAllPoints()
                bf.frame:SetPoint("TOPLEFT",  skinFrame, "TOPLEFT",  PAD_LEFT_HEADER,  yOffset)
                bf.frame:SetPoint("TOPRIGHT", skinFrame, "TOPRIGHT", -PAD_RIGHT,       yOffset)
                bf.frame:Show()
                yOffset = yOffset - 22

                if collapsed then
                    for _, block in ipairs(group) do
                        block._tmBucketKey = key
                        -- Install a one-shot Show hook so Blizzard's own
                        -- re-Show during its next layout pass can't make the
                        -- block reappear under a collapsed bucket header.
                        if not block._tmShowHooked then
                            block._tmShowHooked = true
                            hooksecurefunc(block, "Show", function(self)
                                if not bucketEnabled then return end
                                local k = self._tmBucketKey
                                if not (k and IsBucketCollapsed(k)) then return end
                                -- [COMBAT] Blizzard can re-Show this block during an
                                -- in-combat quest update; self:Hide() on a protected
                                -- tracker block would taint. Alpha is not protected,
                                -- so keep it off screen and let the deferred pass do
                                -- the real Hide once the lockdown lifts.
                                if InCombatLockdown() then
                                    CombatSuppressAlpha(self)
                                    return
                                end
                                self:Hide()
                            end)
                        end
                        block:Hide()

                        -- Masque item button + bouton "recherche de groupe" (right-edge
                        -- frames pooles, parentes au ContentsFrame : block:Hide() ne les
                        -- couvre pas). Voir HideBlockButtons pour le detail du garde.
                        HideBlockButtons(block)
                    end
                else
                    for _, block in ipairs(group) do
                        block._tmBucketKey = key
                        if not block._tmShowHooked then
                            block._tmShowHooked = true
                            hooksecurefunc(block, "Show", function(self)
                                if not bucketEnabled then return end
                                local k = self._tmBucketKey
                                if not (k and IsBucketCollapsed(k)) then return end
                                -- [COMBAT] Blizzard can re-Show this block during an
                                -- in-combat quest update; self:Hide() on a protected
                                -- tracker block would taint. Alpha is not protected,
                                -- so keep it off screen and let the deferred pass do
                                -- the real Hide once the lockdown lifts.
                                if InCombatLockdown() then
                                    CombatSuppressAlpha(self)
                                    return
                                end
                                self:Hide()
                            end)
                        end
                        if block:GetParent() ~= skinFrame then
                            if not block._tmOriginalParent then
                                block._tmOriginalParent = block:GetParent()
                            end
                            block:SetParent(skinFrame)
                        end
                        block:SetFrameStrata("MEDIUM")
                        block:SetFrameLevel(skinFrame:GetFrameLevel() + 5)
                        block:SetIgnoreParentAlpha(true)
                        block:SetAlpha(1)
                        block:ClearAllPoints()
                        block:SetPoint("TOPLEFT",  skinFrame, "TOPLEFT",  PAD_LEFT_BLOCK, yOffset)
                        block:SetPoint("TOPRIGHT", skinFrame, "TOPRIGHT", -PAD_RIGHT,    yOffset)

                        -- Save anchor so the SetPoint hook can restore it when
                        -- Blizzard repositions the block (e.g. quest journal open).
                        block._tmAnchorY = yOffset
                        block._tmAnchorL = PAD_LEFT_BLOCK
                        block._tmAnchorR = PAD_RIGHT

                        -- Install once: intercept any external SetPoint call and
                        -- immediately restore our anchor in the same WoW tick.
                        if not block._tmPositionHooked then
                            block._tmPositionHooked = true
                            hooksecurefunc(block, "SetPoint", function(self)
                                if _tmInLayout then return end
                                if not self._tmAnchorY or not skinFrame then return end
                                _tmInLayout = true
                                self:ClearAllPoints()
                                self:SetPoint("TOPLEFT",  skinFrame, "TOPLEFT",  self._tmAnchorL or PAD_LEFT_BLOCK, self._tmAnchorY)
                                self:SetPoint("TOPRIGHT", skinFrame, "TOPRIGHT", -(self._tmAnchorR or PAD_RIGHT),   self._tmAnchorY)
                                _tmInLayout = false
                            end)
                        end

                        block:Show()

                        -- Re-affiche item button + bouton "recherche de groupe" qu'on avait
                        -- masques a la reduction (uniquement les notres ; cf. ShowBlockButtons).
                        ShowBlockButtons(block)

                        -- Restyle this block (its HeaderText + objective lines)
                        ScanAndStyle(block, 0)

                        -- Force the block to recalculate its height based on visible lines
                        if block.Layout then pcall(block.Layout, block) end

                        -- Always measure the deepest visible descendant bottom — Blizzard's
                        -- block:GetHeight() is unreliable for profession recipe blocks and
                        -- other compound blocks that nest reagent lines several levels deep.
                        local bh = block:GetHeight() or 0
                        local top = block:GetTop()
                        local bottom
                        local function deepestBottom(f, d)
                            if d > 8 or not f or not f.IsShown or not f:IsShown() then return end
                            local b = f.GetBottom and f:GetBottom()
                            if b and (not bottom or b < bottom) then bottom = b end
                            if f.GetRegions then
                                for _, r in ipairs({ f:GetRegions() }) do
                                    if r.IsShown and r:IsShown() and r.GetBottom then
                                        local rb = r:GetBottom()
                                        if rb and (not bottom or rb < bottom) then bottom = rb end
                                    end
                                end
                            end
                            if f.GetChildren then
                                for _, c in ipairs({ f:GetChildren() }) do deepestBottom(c, d + 1) end
                            end
                        end
                        deepestBottom(block, 0)
                        if top and bottom then
                            local measured = top - bottom
                            if measured > bh then bh = measured end
                        end
                        if bh < 30 then bh = 30 end

                        yOffset = yOffset - bh - BLOCK_GAP
                    end
                end
                yOffset = yOffset - BUCKET_GAP
            end
        end
    end

    -- Hide bucket headers that are no longer used
    for k, bf in pairs(bucketFrames) do
        if not groups[k] then bf.frame:Hide() end
    end

    -- ── STEP 3: Suppress WorldQuest module containers (now empty after re-parenting) ──
    -- WQ module frames are nested inside BlocksFrame (not direct children of tracker),
    -- so walkForSkipped can't reach them. We walk the tracker tree here to find them.
    local function HideWorldQuestModules(frame, depth)
        if not frame or depth > 5 then return end
        if frame._tmBucket then return end
        local fn = frame.GetName and frame:GetName()
        if fn and fn:find("WorldQuest", 1, true) then
            -- Only hide if Blizzard still has it shown at its original position
            -- (i.e. it wasn't already reparented by us).
            if frame:GetParent() ~= skinFrame then
                frame:SetAlpha(0)
                _tmHiddenModules[#_tmHiddenModules + 1] = frame
            end
            return  -- don't recurse into it
        end
        if frame.GetChildren then
            for _, c in ipairs({ frame:GetChildren() }) do
                HideWorldQuestModules(c, depth + 1)
            end
        end
    end
    HideWorldQuestModules(tracker, 0)

    -- ── STEP 4: Hide orphan StatusBars left in the original tracker tree ────────
    -- (HideStrayBars is defined above STEP 2 because the delve-only branch of
    -- the emptiness verdict runs this same sweep and returns before this point.)
    HideStrayBars(tracker, 0)

    -- Resize skinFrame to fit our layout
    local totalH = math.abs(yOffset) + 10
    if totalH < 60 then totalH = 60 end
    skinFrame:SetHeight(totalH)

    -- How many blocks this pass actually placed under skinFrame. Read by the
    -- in-combat suppression: with nothing placed there is nothing to overlap.
    _tmPlacedCount = 0
    for _, b in ipairs(blocks) do
        if b.GetParent and b:GetParent() == skinFrame then
            _tmPlacedCount = _tmPlacedCount + 1
        end
    end

    _tmPendingLayout = false
    _tmInLayout = false
    -- Keep the silence window open for a few frames so Blizzard's own deferred
    -- MarkDirty/OnUpdate reactions (caused by our SetParent/SetPoint/Layout)
    -- don't immediately requeue another pump.
    _tmSilenceHook = _tmSilenceHook + 1
    C_Timer.After(0.20, function()
        _tmSilenceHook = math.max(0, _tmSilenceHook - 1)
    end)
end

local function DisableBuckets()
    bucketEnabled = false
    for _, bf in pairs(bucketFrames) do bf.frame:Hide() end
    -- Restore any re-parented quest blocks to their original parent so Blizzard regains control
    if InCombatLockdown() then MarkLayoutPending(); return end
    RestoreCombatSuppressedAlpha()
    local tracker = ObjectiveTrackerFrame
    if not tracker then return end
    local blocks = {}
    CollectQuestBlocks(tracker, 0, blocks)
    -- Non-bucket mode: blocks go back to their Blizzard parent, so the
    -- tracker really is where they live and this count is meaningful.
    -- Quest blocks are not the whole story though: a delve or a scenario
    -- tracks its criteria in its own module, with no quest block anywhere,
    -- and hiding the panel there takes the delve progress off screen.
    -- Both parents: a module re-parented by a previous bucketed pass is still
    -- under skinFrame until restoreSkipped puts it back at the end of this call.
    _tmHasContent = (#blocks > 0)
        or HasSpecialModuleContent(tracker)
        or HasSpecialModuleContent(skinFrame)
    for _, b in ipairs(blocks) do
        if b._tmOriginalParent then
            b:SetParent(b._tmOriginalParent)
            b._tmOriginalParent = nil
            b:ClearAllPoints()
        end
    end
    -- Restore any WorldQuest module frames we hid (alpha=0) this session.
    for _, f in ipairs(_tmHiddenModules) do
        f:SetAlpha(1)
    end
    _tmHiddenModules = {}

    -- Restore orphan status bars hidden by HideStrayBars.
    for _, bar in ipairs(_strayBars) do
        bar._tmStrayHidden = nil
        bar:Show()
    end
    _strayBars = {}

    -- Restore the original anchors of any skipped subtree (delves scenario,
    -- bonus objectives, UI widgets) we re-anchored under skinFrame.
    local function restoreSkipped(parent)
        if not parent or not parent.GetChildren then return end
        for _, child in ipairs({ parent:GetChildren() }) do
            if child._tmOriginalAnchor ~= nil then
                if child._tmOriginalParent2 then
                    child:SetParent(child._tmOriginalParent2)
                    child._tmOriginalParent2 = nil
                end
                child:ClearAllPoints()
                if type(child._tmOriginalAnchor) == "table" then
                    local p, parent2, rp, x, y = unpack(child._tmOriginalAnchor)
                    if p and parent2 then
                        child:SetPoint(p, parent2, rp, x, y)
                    end
                end
                child._tmOriginalAnchor = nil
            end
        end
    end
    restoreSkipped(tracker)
    restoreSkipped(skinFrame)
end

local function RefreshBucketsEnabled()
    local s = S()
    bucketEnabled = s and (s.buckets ~= false) or false
end

-- =====================================
-- MASTER UPDATE
-- =====================================

local function OnTrackerUpdate()
    if not IsEnabled() then return end
    if _tmInLayout then return end

    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    -- In M+: hide the entire skin and let Blizzard's challenge UI take over
    if IsInMythicPlus() then
        if skinFrame then skinFrame:Hide() end
        if headerBar then headerBar:Hide() end
        return
    end

    -- Reset font dedup and category cache so settings/status changes apply
    wipe(styledFonts)
    wipe(questCategoryCache)

    CreateOrUpdateBackground()
    CreateOrUpdateHeader()
    HideBlizzardHeader()
    ScanAndStyle(tracker, 0)
    UpdateQuestCount()
    RefreshBucketsEnabled()

    -- [fix 3.6.1] Under lockdown the layout below cannot run at all. Rather than
    -- letting a block Blizzard just created paint over the bucket stack for the
    -- rest of the fight, take it off screen with alpha (unprotected) and record
    -- that a real pass is owed. Nothing here touches _tmHasContent: leaving the
    -- panel exactly as the last successful pass left it is better than deriving
    -- a verdict from a tree we are not allowed to reorganise.
    if InCombatLockdown() then
        if bucketEnabled then SuppressUnplacedBlocksInCombat() end
        MarkLayoutPending()
        return
    end

    if bucketEnabled then
        LayoutBuckets()
    else
        DisableBuckets()
    end
    -- [FIX] maxQuestsShown must apply regardless of layout mode — previously it
    -- was only enforced when buckets were disabled, so the slider had no effect
    -- at all in the (default) bucketed layout.
    LimitDisplayedQuests()

    -- Visibility, driven by the layout passes rather than by guessing from
    -- Blizzard's frame tree (see _tmHasContent).
    if skinFrame then
        local s = S()
        local hasContent = _tmHasContent and tracker:IsShown()

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
                PumpUpdateSoon()
            end)
        end
    end

    -- Sync visibility: skinFrame is parented to UIParent, not tracker
    hooksecurefunc(tracker, "Hide", function()
        if skinFrame then skinFrame:Hide() end
        if headerBar then headerBar:Hide() end
    end)

    -- [MOVER FIX] Blizzard's Edit Mode manager (and other UI code, e.g. opening
    -- the Quest Journal or resizing action bars) can call SetPoint on the tracker
    -- at any time and silently override the position saved via our own mover,
    -- even though IsUserPlaced() is overridden to return true. Re-assert our
    -- saved anchor immediately (same tick) any time anyone else calls SetPoint
    -- on the tracker — matching the pattern already used for module/block frames.
    if not tracker._tmPositionHooked then
        tracker._tmPositionHooked = true
        hooksecurefunc(tracker, "SetPoint", function()
            if _tmApplyingPosition then return end
            if not OT.ApplyPosition then return end
            -- Never fight an active Blizzard Edit Mode session: while the user
            -- drags the tracker in native Edit Mode, Blizzard calls SetPoint to
            -- follow the cursor. Re-asserting our saved anchor here would cancel
            -- every move and freeze the tracker in place (reported bug). Let Edit
            -- Mode own the position; SavePosition picks it up when the user exits.
            if EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive
                and EditModeManagerFrame:IsEditModeActive() then
                return
            end
            _tmApplyingPosition = true
            OT.ApplyPosition()
            _tmApplyingPosition = false
        end)
    end

    -- [MOVER FIX] The hook above deliberately stands down while Blizzard's own
    -- Edit Mode is running, so the tracker can be dragged there -- but nothing
    -- ever wrote that new position back to our database. The comment above
    -- promised SavePosition would pick it up on exit; it never did. So a
    -- tracker moved through native Edit Mode looked fine until the next
    -- reload, where ApplyPosition snapped it back to the last anchor our own
    -- mover had saved. Capture it when the session ends, one frame later, once
    -- Blizzard has finished settling its layout.
    if EditModeManagerFrame and type(EditModeManagerFrame.ExitEditMode) == "function"
        and not tracker._tmEditModeHooked then
        tracker._tmEditModeHooked = true
        hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
            C_Timer.After(0, function()
                if not (OT.SavePosition and OT.ApplyPosition) then return end
                OT.SavePosition()
                _tmApplyingPosition = true
                OT.ApplyPosition()
                _tmApplyingPosition = false
            end)
        end)
    end

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
    evFrame:RegisterEvent("CHALLENGE_MODE_START")
    evFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    evFrame:RegisterEvent("CHALLENGE_MODE_RESET")
    -- [fix 3.6.1] The missing half of every InCombatLockdown() guard in this
    -- file. Without it, work skipped during a fight was skipped for good.
    evFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

    local lastUpdate = 0
    local trailingQueued = false

    local function FireUpdate()
        lastUpdate = GetTime()
        PumpUpdateSoon()
    end

    evFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            -- Combat exit bypasses the throttle entirely: this is the one moment
            -- the deferred layout is allowed to run, and a 0.25s window shared
            -- with the quest-event burst that usually accompanies it would drop
            -- exactly the pass we are waiting for.
            if _tmPendingDisable then
                _tmPendingDisable = false
                if OT.Disable then OT.Disable() end
                return
            end
            if _tmPendingLayout or next(_tmCombatAlpha) then
                FireUpdate()
                -- PumpUpdateSoon drops the request while the post-layout silence
                -- window is open. That window is what stops the hook feedback
                -- loop, so re-check shortly after instead of forcing past it.
                C_Timer.After(0.30, function()
                    if InCombatLockdown() then return end
                    if _tmPendingLayout or next(_tmCombatAlpha) then
                        PumpUpdateSoon()
                    end
                end)
            end
            return
        end

        local now = GetTime()
        if now - lastUpdate < 0.25 then
            -- [fix 3.6.1] The throttle used to drop the event outright. A quest
            -- accepted inside another event's window therefore never reached the
            -- layout, and nothing replayed it. Coalesce to the trailing edge
            -- instead of discarding.
            if not trailingQueued then
                trailingQueued = true
                C_Timer.After(0.25 - (now - lastUpdate), function()
                    trailingQueued = false
                    FireUpdate()
                end)
            end
            return
        end
        FireUpdate()
    end)
end

-- =====================================
-- MOVER / EDITMODE INTEGRATION
-- =====================================

local moverOverlay
local isMoverLocked = true
local positionApplied = false

local function ApplyPosition()
    local tracker = ObjectiveTrackerFrame
    if not tracker then return end
    local db = S()
    -- Mark as user-placed so Blizzard's UIParent_UpdateTopFramesOverObjectiveTracker
    -- and the Edit Mode manager stop repositioning it.
    if tracker.SetMovable then tracker:SetMovable(true) end
    -- [fix] Clamping was set on ObjectiveTrackerFrame, whose height is
    -- Blizzard's and far exceeds the visible content. Its bottom edge sits
    -- at or past the bottom of the screen, so the engine refused every
    -- downward drag while still allowing up/left/right. Off by default;
    -- "Reset position" in the settings remains the way back if the panel
    -- is dragged somewhere unreachable.
    if tracker.SetClampedToScreen then tracker:SetClampedToScreen(false) end
    tracker.IsUserPlaced = function() return true end

    -- Scale BEFORE the anchor: SetPoint offsets are read in the frame's own
    -- coordinate space, so scaling afterwards silently shifts a frame that was
    -- just placed. Anchoring first and scaling second moved the tracker a
    -- little further away on every apply pass.
    if db.scale and db.scale > 0 then
        tracker:SetScale(db.scale)
    end

    local pos = db.position
    if pos and (pos.point or pos.anchor) then
        -- V4's LayoutEngine migrates point/relativePoint into point/anchor and
        -- stamps refW/refH for resolution-independent positions. This module
        -- used to keep reading the deleted relativePoint key, so after a reload
        -- it silently fell back to pos.point and could jump to another anchor.
        if TomoMod_Layout and TomoMod_Layout.MigratePosition then
            TomoMod_Layout.MigratePosition(pos)
        end
        local point = pos.point or pos.anchor or "BOTTOMLEFT"
        local relativePoint = pos.anchor or pos.relativePoint or pos.relPoint or pos.relTo or point
        local x, y = pos.x or 0, pos.y or 0
        if TomoMod_Layout and TomoMod_Layout.Rescale then
            x, y = TomoMod_Layout.Rescale(x, y, pos.refW, pos.refH,
                UIParent:GetWidth(), UIParent:GetHeight())
        end

        -- Layout.Save stores UIParent-space coordinates. ObjectiveTracker can
        -- have its own scale, so SetPoint offsets must be converted back into
        -- the tracker's coordinate space for an exact save/apply round trip.
        local ratio = tracker:GetEffectiveScale() / UIParent:GetEffectiveScale()
        if not (ratio and ratio > 0) then ratio = 1 end
        tracker:ClearAllPoints()
        tracker:SetPoint(point, UIParent, relativePoint, x / ratio, y / ratio)
    end
    positionApplied = true
end
OT.ApplyPosition = ApplyPosition

local function SavePosition()
    local tracker = ObjectiveTrackerFrame
    if not tracker then return end
    local db = S()
    db.position = db.position or {}
    if TomoMod_Layout and TomoMod_Layout.Save then
        TomoMod_Layout.Save(db.position, tracker)
        return
    end

    -- Legacy fallback when the core layout engine is unavailable.
    local left, bottom = tracker:GetLeft(), tracker:GetBottom()
    if not left or not bottom then return end
    local scale = tracker:GetEffectiveScale() / UIParent:GetEffectiveScale()
    db.position.point = "BOTTOMLEFT"
    db.position.relativePoint = "BOTTOMLEFT"
    db.position.x = left * scale
    db.position.y = bottom * scale
end
OT.SavePosition = SavePosition

local function CreateMoverOverlay()
    if moverOverlay then return moverOverlay end
    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    moverOverlay = CreateFrame("Frame", "TomoModObjectiveTrackerMover", UIParent, "BackdropTemplate")
    moverOverlay:SetFrameStrata("HIGH")
    moverOverlay:SetFrameLevel(200)
    -- Rendu unifie du mode edition : degrade azur vers blanc et libelle azur
    -- avec contour noir. Une seule definition, dans Core/Utils.lua.
    if TomoMod_Utils and TomoMod_Utils.StyleMoverOverlay then
        TomoMod_Utils.StyleMoverOverlay(moverOverlay, (TomoMod_Layout and TomoMod_Layout.Label("objectiveTracker")))
    end
    moverOverlay:SetAllPoints(skinFrame or tracker)
    moverOverlay:EnableMouse(true)
    moverOverlay:SetMovable(true)
    moverOverlay:RegisterForDrag("LeftButton")
    moverOverlay:SetScript("OnDragStart", function()
        tracker:SetMovable(true)
        tracker:StartMoving()
    end)
    moverOverlay:SetScript("OnDragStop", function()
        tracker:StopMovingOrSizing()
        SavePosition()
        ApplyPosition()
    end)
    -- Mouse wheel = scale adjust (90% .. 150%)
    moverOverlay:EnableMouseWheel(true)
    moverOverlay:SetScript("OnMouseWheel", function(_, delta)
        local db = S()
        local s = (db.scale or 1.0) + (delta > 0 and 0.05 or -0.05)
        if s < 0.6 then s = 0.6 elseif s > 1.8 then s = 1.8 end
        db.scale = s
        ApplyPosition()
        if moverOverlay._label then
            moverOverlay:UpdateScaleLabel(s)
        end
    end)

    -- Reuse the unified, localized mover label instead of drawing a second
    -- hardcoded English label over it.
    moverOverlay._label = moverOverlay._tmMoverText

    function moverOverlay:UpdateScaleLabel(scale)
        if not self.SetMoverLabel then return end
        local base = (TomoMod_Layout and TomoMod_Layout.Label("objectiveTracker")) or "Objective Tracker"
        self:SetMoverLabel(("%s  -  %d%%"):format(base, math.floor((scale or 1) * 100 + 0.5)))
    end

    moverOverlay:Hide()
    return moverOverlay
end

function OT.IsLocked()
    return isMoverLocked
end

function OT.SetLocked(value)
    isMoverLocked = value and true or false
    local tracker = ObjectiveTrackerFrame
    if not tracker then return end
    if not positionApplied then ApplyPosition() end
    if isMoverLocked then
        if moverOverlay then moverOverlay:Hide() end
        SavePosition()
        ApplyPosition()
    else
        if not moverOverlay then CreateMoverOverlay() end
        if moverOverlay then
            local db = S()
            if moverOverlay._label then
                moverOverlay:UpdateScaleLabel((db.scale or 1.0))
            end
            moverOverlay:Show()
        end
    end
end

function OT.ToggleLock()
    OT.SetLocked(not isMoverLocked)
end

local function RegisterWithMovers()
    if not TomoMod_Movers or not TomoMod_Movers.RegisterEntry then return end
    TomoMod_Movers.RegisterEntry({
        label    = (TomoMod_L and TomoMod_L["mover_objectivetracker"]) or "Objective Tracker",
        unlock   = function() OT.SetLocked(false) end,
        lock     = function() OT.SetLocked(true) end,
        isActive = function()
            return TomoModDB and TomoModDB.objectiveTracker and TomoModDB.objectiveTracker.enabled
        end,
    })
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
    ApplyPosition()
    OnTrackerUpdate()
end

-- Internal handle used by PumpUpdateSoon to call OnTrackerUpdate without recursion.
OT._OnTrackerUpdate = OnTrackerUpdate

function OT.Enable()
    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    CreateOrUpdateBackground()
    CreateOrUpdateHeader()
    HideBlizzardHeader()
    InstallHooks()
    ApplyPosition()

    C_Timer.After(0.5, OnTrackerUpdate)
end

function OT.Disable()
    if skinFrame then skinFrame:Hide() end
    if headerBar then headerBar:Hide() end

    DisableBuckets()

    if InCombatLockdown() then _tmPendingDisable = true; return end
    _tmPendingDisable = false
    RestoreCombatSuppressedAlpha()
    RestoreNativeAlphaLocks()
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
            RegisterWithMovers()
        elseif attempts < 30 then
            C_Timer.After(0.5, TryInit)
        end
    end

    C_Timer.After(0.3, TryInit)
end

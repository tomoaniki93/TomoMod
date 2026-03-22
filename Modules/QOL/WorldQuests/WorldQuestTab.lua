-- =====================================
-- WorldQuestTab.lua — World Quest List Tab on the World Map
-- =====================================

TomoMod_WorldQuestTab = {}
local WQT = TomoMod_WorldQuestTab

local U = TomoMod_Utils
local L = TomoMod_L

-- =====================================
-- CONSTANTS
-- =====================================
local ADDON_FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ROW_HEIGHT      = 24
local HEADER_HEIGHT   = 28
local TAB_WIDTH       = 380

local REWARD_GOLD     = 1
local REWARD_GEAR     = 2
local REWARD_AP       = 3
local REWARD_REP      = 4
local REWARD_PET      = 5
local REWARD_CURRENCY = 6
local REWARD_ANIMA    = 7
local REWARD_OTHER    = 8

local REWARD_LABELS = {
    [REWARD_GOLD]     = "Gold",
    [REWARD_GEAR]     = "Gear",
    [REWARD_AP]       = "AP",
    [REWARD_REP]      = "Reputation",
    [REWARD_PET]      = "Pet",
    [REWARD_CURRENCY] = "Currency",
    [REWARD_ANIMA]    = "Anima",
    [REWARD_OTHER]    = "Other",
}

local SORT_TIME   = 1
local SORT_ZONE   = 2
local SORT_NAME   = 3
local SORT_REWARD = 4
local SORT_FACTION = 5

local QUALITY_COLORS = {
    [Enum.WorldQuestQuality.Common]   = { r = 1.00, g = 1.00, b = 1.00 },
    [Enum.WorldQuestQuality.Rare]     = { r = 0.00, g = 0.44, b = 0.87 },
    [Enum.WorldQuestQuality.Epic]     = { r = 0.64, g = 0.21, b = 0.93 },
}

-- Theme colors matching TomoMod
local BG_COLOR        = { 0.08, 0.08, 0.10, 0.95 }
local BG_ROW_ALT      = { 0.10, 0.10, 0.13, 0.80 }
local BG_ROW_HOVER    = { 0.047, 0.824, 0.624, 0.15 }
local BORDER_COLOR    = { 0.20, 0.20, 0.25, 1 }
local ACCENT_COLOR    = { 0.047, 0.824, 0.624, 1 }
local TEXT_COLOR      = { 0.90, 0.90, 0.92, 1 }
local TEXT_DIM_COLOR  = { 0.55, 0.55, 0.60, 1 }
local HEADER_BG_COLOR = { 0.06, 0.06, 0.08, 1 }

-- =====================================
-- STATE
-- =====================================
local questCache     = {}
local tabFrame       = nil
local scrollFrame    = nil
local contentFrame   = nil
local rows           = {}
local headerButtons  = {}
local initialized    = false
local currentSort    = SORT_TIME
local sortAscending  = true

-- =====================================
-- REWARD CLASSIFICATION
-- =====================================
local function ClassifyReward(questID)
    -- Check item rewards
    local numRewards = GetNumQuestLogRewards(questID)
    if numRewards and numRewards > 0 then
        local _, _, _, _, _, itemID, itemQuantity = GetQuestLogRewardInfo(1, questID)
        if itemID then
            local _, _, quality, baseIlvl, _, _, _, _, equipLoc = C_Item.GetItemInfo(itemID)
            if equipLoc and equipLoc ~= "" then
                -- Get accurate ilvl from tooltip (WQ rewards are scaled)
                local itemLevel = baseIlvl or 0
                local tooltipData = C_TooltipInfo.GetQuestLogItem("reward", 1, questID)
                if tooltipData and tooltipData.lines then
                    for _, line in ipairs(tooltipData.lines) do
                        if line.type == Enum.TooltipDataLineType.ItemLevel and line.itemLevel then
                            itemLevel = line.itemLevel
                            break
                        end
                    end
                end
                return REWARD_GEAR, itemLevel, itemID, itemQuantity or 1
            end
            -- Check for pet
            if quality and quality >= 3 then
                local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemID)
                if classID == 17 then -- LE_ITEM_CLASS_BATTLEPET
                    return REWARD_PET, 0, itemID, itemQuantity or 1
                end
            end
        end
    end

    -- Check currency rewards
    local currencyRewards = C_QuestLog.GetQuestRewardCurrencies(questID)
    if currencyRewards and #currencyRewards > 0 then
        for _, entry in ipairs(currencyRewards) do
            local currencyID = entry.currencyID
            local quantity = entry.totalRewardAmount or 0
            if currencyID then
                -- Anima (all variants)
                if currencyID == 1813 or currencyID == 1816 or currencyID == 1817 or currencyID == 1728 then
                    return REWARD_ANIMA, quantity, currencyID, quantity
                end
                -- Other currency
                local cInfo = C_CurrencyInfo.GetCurrencyInfo(currencyID)
                if cInfo then
                    return REWARD_CURRENCY, quantity, currencyID, quantity
                end
            end
        end
    end

    -- Check gold reward
    local gold = GetQuestLogRewardMoney(questID) or 0
    if gold > 0 then
        return REWARD_GOLD, math.floor(gold / 10000), nil, gold
    end

    -- Check reputation reward
    if C_QuestLog.GetQuestRewardReputation and C_QuestLog.GetQuestRewardReputation(questID) then
        local repRewards = C_QuestLog.GetQuestRewardReputation(questID)
        if repRewards and #repRewards > 0 then
            return REWARD_REP, 0, nil, 0
        end
    end

    return REWARD_OTHER, 0, nil, 0
end

-- =====================================
-- BUILD REWARD TEXT
-- =====================================
local function GetRewardText(data)
    if data.rewardType == REWARD_GOLD then
        return string.format("|cffffd700%dg|r", data.rewardValue)
    elseif data.rewardType == REWARD_GEAR then
        return string.format("|cff00aaff%s ilvl %d|r", REWARD_LABELS[REWARD_GEAR], data.rewardValue)
    elseif data.rewardType == REWARD_ANIMA then
        return string.format("|cff33bbff%d Anima|r", data.rewardValue)
    elseif data.rewardType == REWARD_CURRENCY then
        local info = data.rewardItemID and C_CurrencyInfo.GetCurrencyInfo(data.rewardItemID)
        local name = info and info.name or "Currency"
        return string.format("|cffa335ee%d %s|r", data.rewardValue, name)
    elseif data.rewardType == REWARD_REP then
        return "|cff00ff00" .. REWARD_LABELS[REWARD_REP] .. "|r"
    elseif data.rewardType == REWARD_PET then
        return "|cff00ccff" .. REWARD_LABELS[REWARD_PET] .. "|r"
    else
        return "|cff888888" .. REWARD_LABELS[REWARD_OTHER] .. "|r"
    end
end

-- =====================================
-- TIME FORMATTING (detailed)
-- =====================================
local function FormatTimeLeft(seconds)
    if not seconds or seconds <= 0 then return "|cffff0000Expired|r" end
    if seconds >= 86400 then
        local days = math.floor(seconds / 86400)
        local hours = math.floor((seconds % 86400) / 3600)
        return string.format("|cffffffff%dd %dh|r", days, hours)
    elseif seconds >= 3600 then
        local hours = math.floor(seconds / 3600)
        local mins = math.floor((seconds % 3600) / 60)
        return string.format("|cffffffff%dh %dm|r", hours, mins)
    elseif seconds >= 60 then
        return string.format("|cffffaa00%dm|r", math.floor(seconds / 60))
    else
        return string.format("|cffff4400%ds|r", math.floor(seconds))
    end
end

-- =====================================
-- FETCH WORLD QUESTS
-- (uses same API pattern as WorldQuestsList)
-- =====================================
local function GetCurrentMapQuests()
    local mapID = WorldMapFrame and WorldMapFrame:GetMapID()
    if not mapID then return {} end

    local quests = {}
    local seen = {}

    local function ProcessTasks(taskInfo, sourceMapID)
        if not taskInfo then return end
        for _, info in ipairs(taskInfo) do
            local questID = info.questID
            if questID and not seen[questID] and HaveQuestData(questID) and QuestUtils_IsQuestWorldQuest(questID) then
                seen[questID] = true

                local title, factionID = C_TaskQuest.GetQuestInfoByQuestID(questID)
                local tagInfo = C_QuestLog.GetQuestTagInfo(questID)
                local timeLeft = C_TaskQuest.GetQuestTimeLeftSeconds(questID)
                local questMapID = info.mapID or sourceMapID
                local mapInfo = C_Map.GetMapInfo(questMapID)
                local factionName = ""
                if factionID and factionID > 0 then
                    local factionData = C_Reputation.GetFactionDataByID(factionID)
                    factionName = factionData and factionData.name or ""
                end

                local rewardType, rewardValue, rewardItemID, rewardQuantity = ClassifyReward(questID)
                local quality = tagInfo and tagInfo.quality or Enum.WorldQuestQuality.Common

                quests[#quests + 1] = {
                    questID       = questID,
                    title         = title or ("Quest " .. questID),
                    mapID         = questMapID,
                    zoneName      = mapInfo and mapInfo.name or "",
                    x             = info.x or 0,
                    y             = info.y or 0,
                    timeLeft      = timeLeft or 0,
                    factionID     = factionID,
                    factionName   = factionName,
                    rewardType    = rewardType,
                    rewardValue   = rewardValue,
                    rewardItemID  = rewardItemID,
                    rewardQty     = rewardQuantity,
                    quality       = quality,
                    isElite       = tagInfo and tagInfo.isElite or false,
                    questType     = tagInfo and tagInfo.worldQuestType,
                }
            end
        end
    end

    -- Scan current map
    ProcessTasks(C_TaskQuest.GetQuestsOnMap(mapID), mapID)

    -- Scan all child maps (zones, sub-zones, etc.)
    local childMaps = C_Map.GetMapChildrenInfo(mapID, nil, true)
    if childMaps then
        for _, childInfo in ipairs(childMaps) do
            ProcessTasks(C_TaskQuest.GetQuestsOnMap(childInfo.mapID), childInfo.mapID)
        end
    end

    return quests
end

-- =====================================
-- SORTING
-- =====================================
local function SortQuests(quests)
    local field
    if currentSort == SORT_TIME then
        field = function(a, b)
            if sortAscending then return (a.timeLeft or 0) < (b.timeLeft or 0) end
            return (a.timeLeft or 0) > (b.timeLeft or 0)
        end
    elseif currentSort == SORT_ZONE then
        field = function(a, b)
            if sortAscending then return (a.zoneName or "") < (b.zoneName or "") end
            return (a.zoneName or "") > (b.zoneName or "")
        end
    elseif currentSort == SORT_NAME then
        field = function(a, b)
            if sortAscending then return (a.title or "") < (b.title or "") end
            return (a.title or "") > (b.title or "")
        end
    elseif currentSort == SORT_REWARD then
        field = function(a, b)
            if a.rewardType ~= b.rewardType then
                if sortAscending then return a.rewardType < b.rewardType end
                return a.rewardType > b.rewardType
            end
            if sortAscending then return (a.rewardValue or 0) > (b.rewardValue or 0) end
            return (a.rewardValue or 0) < (b.rewardValue or 0)
        end
    elseif currentSort == SORT_FACTION then
        field = function(a, b)
            if sortAscending then return (a.factionName or "") < (b.factionName or "") end
            return (a.factionName or "") > (b.factionName or "")
        end
    end

    if field then
        table.sort(quests, field)
    end
end

-- =====================================
-- FILTERING
-- =====================================
local function PassesFilter(data)
    local db = TomoModDB and TomoModDB.worldQuestTab
    if not db then return true end

    -- Reward type filters
    if db.filterGold     == false and data.rewardType == REWARD_GOLD     then return false end
    if db.filterGear     == false and data.rewardType == REWARD_GEAR     then return false end
    if db.filterAP       == false and data.rewardType == REWARD_AP       then return false end
    if db.filterRep      == false and data.rewardType == REWARD_REP      then return false end
    if db.filterPet      == false and data.rewardType == REWARD_PET      then return false end
    if db.filterCurrency == false and data.rewardType == REWARD_CURRENCY then return false end
    if db.filterAnima    == false and data.rewardType == REWARD_ANIMA    then return false end
    if db.filterOther    == false and data.rewardType == REWARD_OTHER    then return false end

    -- Time filter: only show quests with at least X minutes remaining
    if db.minTimeMinutes and db.minTimeMinutes > 0 then
        if (data.timeLeft or 0) < (db.minTimeMinutes * 60) then return false end
    end

    return true
end

-- =====================================
-- CREATE ROW
-- =====================================
local function CreateRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))
    row:SetPoint("TOPRIGHT", 0, -((index - 1) * ROW_HEIGHT))

    -- Alternating background
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    if index % 2 == 0 then
        row.bg:SetColorTexture(unpack(BG_ROW_ALT))
    else
        row.bg:SetColorTexture(0, 0, 0, 0)
    end

    -- Hover highlight
    row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlight:SetAllPoints()
    row.highlight:SetColorTexture(unpack(BG_ROW_HOVER))

    -- Quality indicator (thin left bar)
    row.qualityBar = row:CreateTexture(nil, "ARTWORK")
    row.qualityBar:SetWidth(3)
    row.qualityBar:SetPoint("TOPLEFT", 0, 0)
    row.qualityBar:SetPoint("BOTTOMLEFT", 0, 0)

    -- Quest name
    row.nameText = row:CreateFontString(nil, "OVERLAY")
    row.nameText:SetFont(ADDON_FONT, 11, "")
    row.nameText:SetPoint("LEFT", 8, 0)
    row.nameText:SetWidth(130)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWordWrap(false)

    -- Zone name
    row.zoneText = row:CreateFontString(nil, "OVERLAY")
    row.zoneText:SetFont(ADDON_FONT, 10, "")
    row.zoneText:SetPoint("LEFT", row.nameText, "RIGHT", 6, 0)
    row.zoneText:SetWidth(70)
    row.zoneText:SetJustifyH("LEFT")
    row.zoneText:SetWordWrap(false)
    row.zoneText:SetTextColor(unpack(TEXT_DIM_COLOR))

    -- Reward
    row.rewardText = row:CreateFontString(nil, "OVERLAY")
    row.rewardText:SetFont(ADDON_FONT, 10, "")
    row.rewardText:SetPoint("LEFT", row.zoneText, "RIGHT", 6, 0)
    row.rewardText:SetWidth(90)
    row.rewardText:SetJustifyH("LEFT")
    row.rewardText:SetWordWrap(false)

    -- Time left
    row.timeText = row:CreateFontString(nil, "OVERLAY")
    row.timeText:SetFont(ADDON_FONT, 10, "")
    row.timeText:SetPoint("RIGHT", -8, 0)
    row.timeText:SetWidth(55)
    row.timeText:SetJustifyH("RIGHT")
    row.timeText:SetWordWrap(false)

    -- Tooltip on hover
    row:SetScript("OnEnter", function(self)
        if self.data then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.data.title or "", 1, 1, 1)
            if self.data.zoneName and self.data.zoneName ~= "" then
                GameTooltip:AddLine(L["wq_zone"] .. ": " .. self.data.zoneName, 0.7, 0.7, 0.7)
            end
            if self.data.factionName and self.data.factionName ~= "" then
                GameTooltip:AddLine(L["wq_faction"] .. ": " .. self.data.factionName, 0.5, 0.8, 0.5)
            end
            GameTooltip:AddLine(L["wq_reward"] .. ": " .. GetRewardText(self.data), 1, 1, 1)
            GameTooltip:AddLine(L["wq_time_left"] .. ": " .. FormatTimeLeft(self.data.timeLeft), 1, 1, 1)
            if self.data.isElite then
                GameTooltip:AddLine(L["wq_elite"], 1, 0.5, 0)
            end
            if self.data.questID then
                GameTooltip:AddLine("|cff888888Quest ID: " .. self.data.questID .. "|r")
            end
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Click to super-track and navigate
    row:SetScript("OnClick", function(self)
        if self.data and self.data.questID then
            -- Super-track the quest
            C_SuperTrack.SetSuperTrackedQuestID(self.data.questID)
            -- Navigate to the quest's zone on the map
            if self.data.mapID and WorldMapFrame then
                WorldMapFrame:SetMapID(self.data.mapID)
            end
        end
    end)

    return row
end

-- =====================================
-- CREATE HEADER
-- =====================================
local function CreateHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetHeight(HEADER_HEIGHT)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)

    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(HEADER_BG_COLOR))

    local columns = {
        { key = SORT_NAME,    label = L["wq_col_name"],    width = 138, offset = 8 },
        { key = SORT_ZONE,    label = L["wq_col_zone"],    width = 76,  offset = 144 },
        { key = SORT_REWARD,  label = L["wq_col_reward"],  width = 96,  offset = 220 },
        { key = SORT_TIME,    label = L["wq_col_time"],    width = 63,  offset = 316 },
    }

    for _, col in ipairs(columns) do
        local btn = CreateFrame("Button", nil, header)
        btn:SetHeight(HEADER_HEIGHT)
        btn:SetWidth(col.width)
        btn:SetPoint("LEFT", col.offset, 0)

        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont(ADDON_FONT_BOLD, 11, "")
        text:SetAllPoints()
        text:SetJustifyH("LEFT")
        text:SetTextColor(unpack(ACCENT_COLOR))
        text:SetText(col.label)
        btn.text = text

        btn:SetScript("OnClick", function()
            if currentSort == col.key then
                sortAscending = not sortAscending
            else
                currentSort = col.key
                sortAscending = true
            end
            WQT.RefreshList()
        end)

        btn:SetScript("OnEnter", function(self)
            self.text:SetTextColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            self.text:SetTextColor(unpack(ACCENT_COLOR))
        end)

        headerButtons[col.key] = btn
    end

    -- Bottom border
    local border = header:CreateTexture(nil, "ARTWORK")
    border:SetHeight(1)
    border:SetPoint("BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", 0, 0)
    border:SetColorTexture(unpack(BORDER_COLOR))

    return header
end

-- =====================================
-- CREATE TAB BUTTON ON WORLD MAP
-- =====================================
local function CreateMapTabButton()
    if not WorldMapFrame then return end

    local tabBtn = CreateFrame("Button", "TomoMod_WQTabButton", WorldMapFrame)
    tabBtn:SetSize(100, 26)
    tabBtn:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -60, -2)

    local btnBg = tabBtn:CreateTexture(nil, "BACKGROUND")
    btnBg:SetAllPoints()
    btnBg:SetColorTexture(unpack(BG_COLOR))

    local btnBorder = CreateFrame("Frame", nil, tabBtn, "BackdropTemplate")
    btnBorder:SetAllPoints()
    btnBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btnBorder:SetBackdropBorderColor(unpack(BORDER_COLOR))

    local btnText = tabBtn:CreateFontString(nil, "OVERLAY")
    btnText:SetFont(ADDON_FONT_BOLD, 11, "")
    btnText:SetPoint("CENTER", 0, 0)
    btnText:SetTextColor(unpack(ACCENT_COLOR))
    btnText:SetText(L["wq_tab_title"])

    tabBtn:SetScript("OnClick", function()
        WQT.Toggle()
    end)

    tabBtn:SetScript("OnEnter", function()
        btnText:SetTextColor(1, 1, 1, 1)
    end)
    tabBtn:SetScript("OnLeave", function()
        btnText:SetTextColor(unpack(ACCENT_COLOR))
    end)

    return tabBtn
end

-- =====================================
-- STATUS BAR (count + faction sort btn)
-- =====================================
local function CreateStatusBar(parent)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetHeight(24)
    bar:SetPoint("BOTTOMLEFT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", 0, 0)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(HEADER_BG_COLOR))

    -- Top border
    local border = bar:CreateTexture(nil, "ARTWORK")
    border:SetHeight(1)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetPoint("TOPRIGHT", 0, 0)
    border:SetColorTexture(unpack(BORDER_COLOR))

    bar.countText = bar:CreateFontString(nil, "OVERLAY")
    bar.countText:SetFont(ADDON_FONT, 10, "")
    bar.countText:SetPoint("LEFT", 8, 0)
    bar.countText:SetTextColor(unpack(TEXT_DIM_COLOR))

    bar.sortText = bar:CreateFontString(nil, "OVERLAY")
    bar.sortText:SetFont(ADDON_FONT, 10, "")
    bar.sortText:SetPoint("RIGHT", -8, 0)
    bar.sortText:SetTextColor(unpack(TEXT_DIM_COLOR))

    return bar
end

-- =====================================
-- BUILD MAIN FRAME
-- =====================================
local function CreateTabFrame()
    if tabFrame then return tabFrame end

    tabFrame = CreateFrame("Frame", "TomoMod_WorldQuestTabFrame", WorldMapFrame, "BackdropTemplate")
    tabFrame:SetWidth(TAB_WIDTH)
    tabFrame:SetPoint("TOPLEFT", WorldMapFrame, "TOPRIGHT", 4, 0)
    tabFrame:SetPoint("BOTTOMLEFT", WorldMapFrame, "BOTTOMRIGHT", 4, 0)

    -- Background
    tabFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    tabFrame:SetBackdropColor(unpack(BG_COLOR))
    tabFrame:SetBackdropBorderColor(unpack(BORDER_COLOR))

    tabFrame:SetFrameStrata("HIGH")
    tabFrame:SetFrameLevel(500)
    tabFrame:SetClampedToScreen(true)

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, tabFrame)
    titleBar:SetHeight(30)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.06, 0.06, 0.08, 1)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY")
    titleText:SetFont(ADDON_FONT_BOLD, 13, "")
    titleText:SetPoint("LEFT", 10, 0)
    titleText:SetTextColor(unpack(ACCENT_COLOR))
    titleText:SetText(L["wq_panel_title"])

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(26, 26)
    closeBtn:SetPoint("RIGHT", -2, 0)
    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY")
    closeTxt:SetFont(ADDON_FONT_BOLD, 14, "")
    closeTxt:SetPoint("CENTER", 0, 0)
    closeTxt:SetText("X")
    closeTxt:SetTextColor(0.6, 0.6, 0.6)
    closeBtn:SetScript("OnClick", function() WQT.Toggle() end)
    closeBtn:SetScript("OnEnter", function() closeTxt:SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function() closeTxt:SetTextColor(0.6, 0.6, 0.6) end)

    -- Refresh button
    local refreshBtn = CreateFrame("Button", nil, titleBar)
    refreshBtn:SetSize(26, 26)
    refreshBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)
    local refreshTxt = refreshBtn:CreateFontString(nil, "OVERLAY")
    refreshTxt:SetFont(ADDON_FONT_BOLD, 13, "")
    refreshTxt:SetPoint("CENTER", 0, 0)
    refreshTxt:SetText("R")
    refreshTxt:SetTextColor(0.6, 0.6, 0.6)
    refreshBtn:SetScript("OnClick", function() WQT.RefreshList() end)
    refreshBtn:SetScript("OnEnter", function() refreshTxt:SetTextColor(unpack(ACCENT_COLOR)) end)
    refreshBtn:SetScript("OnLeave", function() refreshTxt:SetTextColor(0.6, 0.6, 0.6) end)

    -- Title bottom border
    local titleBorder = titleBar:CreateTexture(nil, "ARTWORK")
    titleBorder:SetHeight(1)
    titleBorder:SetPoint("BOTTOMLEFT", 0, 0)
    titleBorder:SetPoint("BOTTOMRIGHT", 0, 0)
    titleBorder:SetColorTexture(unpack(BORDER_COLOR))

    -- Header row
    local header = CreateHeader(tabFrame)
    header:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)

    -- Status bar
    tabFrame.statusBar = CreateStatusBar(tabFrame)

    -- Scroll frame (custom, no template — clean thin scrollbar)
    scrollFrame = CreateFrame("ScrollFrame", nil, tabFrame)
    scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", tabFrame.statusBar, "TOPRIGHT", 0, 0)

    contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetWidth(TAB_WIDTH - 4)
    contentFrame:SetHeight(1)
    scrollFrame:SetScrollChild(contentFrame)

    -- Thin scroll track + thumb
    local scrollTrack = CreateFrame("Frame", nil, scrollFrame)
    scrollTrack:SetWidth(4)
    scrollTrack:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)
    scrollTrack:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 0)
    local trackBg = scrollTrack:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(0, 0, 0, 0.3)

    local scrollThumb = scrollTrack:CreateTexture(nil, "OVERLAY")
    scrollThumb:SetWidth(4)
    scrollThumb:SetColorTexture(unpack(ACCENT_COLOR))
    scrollThumb:SetAlpha(0.6)
    scrollThumb:Hide()
    tabFrame.scrollTrack = scrollTrack
    tabFrame.scrollThumb = scrollThumb

    local function UpdateScrollIndicator()
        local viewH = scrollFrame:GetHeight()
        local contentH = contentFrame:GetHeight()
        if contentH <= viewH or contentH == 0 then
            scrollThumb:Hide()
            scrollTrack:SetAlpha(0)
            return
        end
        scrollTrack:SetAlpha(1)
        scrollThumb:Show()
        local ratio = viewH / contentH
        local thumbH = math.max(20, viewH * ratio)
        scrollThumb:SetHeight(thumbH)
        local scrollRange = contentH - viewH
        local scrollPos = scrollFrame:GetVerticalScroll()
        local thumbRange = viewH - thumbH
        local thumbOff = (scrollPos / scrollRange) * thumbRange
        scrollThumb:ClearAllPoints()
        scrollThumb:SetPoint("TOPRIGHT", scrollTrack, "TOPRIGHT", 0, -thumbOff)
    end
    tabFrame.UpdateScrollIndicator = UpdateScrollIndicator

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = math.max(0, contentFrame:GetHeight() - self:GetHeight())
        local newScroll = math.max(0, math.min(maxScroll, current - (delta * ROW_HEIGHT * 3)))
        self:SetVerticalScroll(newScroll)
        UpdateScrollIndicator()
    end)

    tabFrame:Hide()
    return tabFrame
end

-- =====================================
-- REFRESH / POPULATE LIST
-- =====================================
function WQT.RefreshList()
    if not tabFrame or not tabFrame:IsShown() then return end

    local db = TomoModDB and TomoModDB.worldQuestTab
    local maxRows = db and db.maxQuestsShown or 50

    -- Fetch quests
    questCache = GetCurrentMapQuests()

    -- Filter
    local filtered = {}
    for _, data in ipairs(questCache) do
        if PassesFilter(data) then
            filtered[#filtered + 1] = data
        end
    end

    -- Sort
    SortQuests(filtered)

    -- Limit
    if maxRows > 0 and #filtered > maxRows then
        local limited = {}
        for i = 1, maxRows do
            limited[i] = filtered[i]
        end
        filtered = limited
    end

    -- Clear old rows
    for _, r in ipairs(rows) do
        r:Hide()
    end

    -- Create/reuse rows
    for i, data in ipairs(filtered) do
        local row = rows[i]
        if not row then
            row = CreateRow(contentFrame, i)
            rows[i] = row
        end
        row:SetPoint("TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))
        row:SetPoint("TOPRIGHT", 0, -((i - 1) * ROW_HEIGHT))

        -- Update alternating bg
        if i % 2 == 0 then
            row.bg:SetColorTexture(unpack(BG_ROW_ALT))
        else
            row.bg:SetColorTexture(0, 0, 0, 0)
        end

        -- Quality bar color
        local qc = QUALITY_COLORS[data.quality] or QUALITY_COLORS[Enum.WorldQuestQuality.Common]
        row.qualityBar:SetColorTexture(qc.r, qc.g, qc.b, 1)

        -- Elite indicator (inline skull icon)
        local prefix = data.isElite and "|TInterface\\TARGETINGFRAME\\UI-TargetingFrame-Skull:0:0:0:0|t " or ""

        row.nameText:SetText(prefix .. (data.title or ""))
        row.nameText:SetTextColor(unpack(TEXT_COLOR))

        row.zoneText:SetText(data.zoneName or "")
        row.rewardText:SetText(GetRewardText(data))
        row.timeText:SetText(FormatTimeLeft(data.timeLeft))

        row.data = data
        row:Show()
    end

    -- Content height
    contentFrame:SetHeight(math.max(1, #filtered * ROW_HEIGHT))

    -- Update scroll indicator
    if tabFrame.UpdateScrollIndicator then
        tabFrame.UpdateScrollIndicator()
    end

    -- Update status bar
    if tabFrame.statusBar then
        local sortLabel = L["wq_sort_time"]
        if currentSort == SORT_ZONE then sortLabel = L["wq_sort_zone"]
        elseif currentSort == SORT_NAME then sortLabel = L["wq_sort_name"]
        elseif currentSort == SORT_REWARD then sortLabel = L["wq_sort_reward"]
        elseif currentSort == SORT_FACTION then sortLabel = L["wq_sort_faction"] end

        local arrow = sortAscending and "|TInterface\\Buttons\\Arrow-Up-Up:0:0:0:0|t" or "|TInterface\\Buttons\\Arrow-Down-Down:0:0:0:0|t"
        tabFrame.statusBar.countText:SetText(string.format(L["wq_status_count"], #filtered, #questCache))
        tabFrame.statusBar.sortText:SetText(sortLabel .. " " .. arrow)
    end
end

-- =====================================
-- TOGGLE
-- =====================================
function WQT.Toggle()
    if not tabFrame then CreateTabFrame() end
    if tabFrame:IsShown() then
        tabFrame:Hide()
    else
        tabFrame:Show()
        WQT.RefreshList()
    end
end

function WQT.Show()
    if not tabFrame then CreateTabFrame() end
    tabFrame:Show()
    WQT.RefreshList()
end

function WQT.Hide()
    if tabFrame then tabFrame:Hide() end
end

function WQT.IsShown()
    return tabFrame and tabFrame:IsShown()
end

-- =====================================
-- INITIALIZE
-- =====================================
function WQT.Initialize()
    local db = TomoModDB and TomoModDB.worldQuestTab
    if not db or not db.enabled then return end

    if initialized then return end
    initialized = true

    -- Wait for World Map to be loaded
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function(self, event, addon)
        if addon == "Blizzard_WorldMap" or WorldMapFrame then
            self:UnregisterAllEvents()
            C_Timer.After(0.5, function()
                CreateTabFrame()
                CreateMapTabButton()

                -- Auto-refresh when map changes (small delay for data loading)
                if WorldMapFrame then
                    hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
                        if tabFrame and tabFrame:IsShown() then
                            C_Timer.After(0.3, function()
                                if tabFrame and tabFrame:IsShown() then
                                    WQT.RefreshList()
                                end
                            end)
                        end
                    end)

                    -- Show/hide with world map (delay for quest data to load)
                    WorldMapFrame:HookScript("OnShow", function()
                        if db.enabled and db.autoShow then
                            C_Timer.After(0.5, function()
                                WQT.Show()
                            end)
                        end
                    end)

                    WorldMapFrame:HookScript("OnHide", function()
                        WQT.Hide()
                    end)
                end

                -- Listen for quest data updates to refresh the list
                local wqEventFrame = CreateFrame("Frame")
                wqEventFrame:RegisterEvent("QUEST_LOG_UPDATE")
                wqEventFrame:RegisterEvent("TASK_PROGRESS_UPDATE")
                wqEventFrame:SetScript("OnEvent", function()
                    if tabFrame and tabFrame:IsShown() then
                        C_Timer.After(0.2, function()
                            if tabFrame and tabFrame:IsShown() then
                                WQT.RefreshList()
                            end
                        end)
                    end
                end)

                -- Periodic time refresh (update time remaining every 60s)
                C_Timer.NewTicker(60, function()
                    if tabFrame and tabFrame:IsShown() then
                        -- Update time left in cached data
                        for _, data in ipairs(questCache) do
                            local timeLeft = C_TaskQuest.GetQuestTimeLeftSeconds(data.questID)
                            data.timeLeft = timeLeft or 0
                        end
                        -- Re-render rows with updated times
                        for _, row in ipairs(rows) do
                            if row:IsShown() and row.data then
                                row.timeText:SetText(FormatTimeLeft(row.data.timeLeft))
                            end
                        end
                    end
                end)
            end)
        end
    end)

    -- If WorldMapFrame already exists (was loaded before us)
    if WorldMapFrame then
        loader:GetScript("OnEvent")(loader, "ADDON_LOADED", "Blizzard_WorldMap")
    end
end

function WQT.ApplySettings()
    local db = TomoModDB and TomoModDB.worldQuestTab
    if not db then return end

    if not db.enabled then
        WQT.Hide()
        return
    end

    if not initialized then
        WQT.Initialize()
    end

    if tabFrame then
        WQT.RefreshList()
    end
end

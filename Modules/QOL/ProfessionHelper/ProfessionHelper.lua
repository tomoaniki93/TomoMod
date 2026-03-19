-- =====================================
-- ProfessionHelper.lua — Disenchant / Mill / Prospect batch helper
-- =====================================

TomoMod_ProfessionHelper = {}
local PH = TomoMod_ProfessionHelper
local L  = TomoMod_L

-- ─── Constants ───────────────────────────────────────────────────
local FONT   = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_B = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

local ACCENT  = { 0.047, 0.824, 0.624, 1 }
local BG      = { 0.08, 0.08, 0.10, 0.97 }
local BG_DARK = { 0.06, 0.06, 0.08, 1 }
local BORDER  = { 0.20, 0.20, 0.25, 1 }
local TEXT    = { 0.90, 0.90, 0.92, 1 }
local DIM     = { 0.55, 0.55, 0.60, 1 }

-- Spell IDs for the three operations
local SPELL_DISENCHANT = 13262
local SPELL_MILLING    = 51005
local SPELL_PROSPECT   = 31252

-- Quality constants (Enum.ItemQuality)
local QUALITY_UNCOMMON = 2  -- Green
local QUALITY_RARE     = 3  -- Blue
local QUALITY_EPIC     = 4  -- Purple

-- Quality colors
local QUALITY_COLORS = {
    [0] = { 0.62, 0.62, 0.62 },  -- Poor (grey)
    [1] = { 1.00, 1.00, 1.00 },  -- Common (white)
    [2] = { 0.12, 1.00, 0.00 },  -- Uncommon (green)
    [3] = { 0.00, 0.44, 0.87 },  -- Rare (blue)
    [4] = { 0.64, 0.21, 0.93 },  -- Epic (purple)
    [5] = { 1.00, 0.50, 0.00 },  -- Legendary (orange)
}

-- ─── Mode definitions ────────────────────────────────────────────
local MODES = {
    {
        key       = "disenchant",
        spellID   = SPELL_DISENCHANT,
        label     = function() return L["ph_tab_disenchant"] end,
        filter    = function(itemInfo, settings)
            -- Disenchantable: equipment (armor/weapons) of green+ quality
            if not itemInfo then return false end
            local quality = itemInfo.quality or 0
            local classID = itemInfo.classID
            -- classID 2 = Weapon, 4 = Armor
            if classID ~= 2 and classID ~= 4 then return false end
            if quality < QUALITY_UNCOMMON then return false end
            -- Apply quality filter from settings
            if settings.filterGreen and quality == QUALITY_UNCOMMON then return true end
            if settings.filterBlue and quality == QUALITY_RARE then return true end
            if settings.filterEpic and quality == QUALITY_EPIC then return true end
            return false
        end,
        minStack  = 1,
    },
    {
        key       = "milling",
        spellID   = SPELL_MILLING,
        label     = function() return L["ph_tab_milling"] end,
        filter    = function(itemInfo, settings)
            -- Millable herbs (classID 7 = Tradeskill, subclassID 9 = Herb)
            if not itemInfo then return false end
            if itemInfo.classID ~= 7 then return false end
            if itemInfo.subclassID ~= 9 then return false end
            return true
        end,
        minStack  = 5,
    },
    {
        key       = "prospecting",
        spellID   = SPELL_PROSPECT,
        label     = function() return L["ph_tab_prospecting"] end,
        filter    = function(itemInfo, settings)
            -- Prospectable ores (classID 7 = Tradeskill, subclassID 7 = Metal & Stone)
            if not itemInfo then return false end
            if itemInfo.classID ~= 7 then return false end
            if itemInfo.subclassID ~= 7 then return false end
            return true
        end,
        minStack  = 5,
    },
}

-- ─── State ───────────────────────────────────────────────────────
local mainFrame
local currentMode = 1  -- index into MODES
local itemButtons = {}
local selectedItems = {}     -- [itemID] = true/false
local isProcessing = false
local processQueue = {}
local processIndex = 0

-- ─── Helpers ─────────────────────────────────────────────────────

local function GetSettings()
    return TomoModDB and TomoModDB.professionHelper or {}
end

local function HasSpellLearned(spellID)
    return IsSpellKnown(spellID) or IsPlayerSpell(spellID)
end

local function GetAvailableModes()
    local available = {}
    for _, mode in ipairs(MODES) do
        if HasSpellLearned(mode.spellID) then
            table.insert(available, mode)
        end
    end
    return available
end

local pendingCacheRetry = nil

local function ScanBags(mode)
    local settings = GetSettings()
    local items = {}
    local seen = {}
    local hasMissing = false

    -- Scan all bags (0-4 normal, 5 reagent bag)
    for bag = 0, 5 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local itemID = info.itemID
                if not seen[itemID] then
                    seen[itemID] = {
                        count    = 0,
                        bag      = bag,
                        slot     = slot,
                        quality  = info.quality,
                        link     = info.hyperlink,
                        iconID   = info.iconFileID,
                    }
                end
                seen[itemID].count = seen[itemID].count + (info.stackCount or 1)
            end
        end
    end

    for itemID, data in pairs(seen) do
        -- GetItemInfo (global) returns full item details from cache
        local itemName, itemLink, itemQuality, itemLevel, _, _, _, _, _, itemTexture, _, classID, subclassID = GetItemInfo(itemID)
        if itemName then
            local itemInfo = {
                itemID     = itemID,
                name       = itemName,
                link       = itemLink or data.link,
                quality    = itemQuality or data.quality or 0,
                level      = itemLevel or 0,
                texture    = itemTexture or data.iconID,
                classID    = classID,
                subclassID = subclassID,
                count      = data.count,
            }
            if mode.filter(itemInfo, settings) and data.count >= mode.minStack then
                table.insert(items, itemInfo)
            end
        else
            -- Item not in cache yet — request it
            C_Item.RequestLoadItemDataByID(itemID)
            hasMissing = true
        end
    end

    -- If some items weren't cached, retry after a short delay
    if hasMissing and not pendingCacheRetry then
        pendingCacheRetry = true
        C_Timer.After(0.5, function()
            pendingCacheRetry = nil
            if mainFrame and mainFrame:IsShown() then
                PH.RefreshItems()
            end
        end)
    end

    table.sort(items, function(a, b)
        if a.quality ~= b.quality then return a.quality > b.quality end
        return a.name < b.name
    end)

    return items
end

local function FindItemInBags(itemID)
    for bag = 0, 5 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID == itemID then
                return bag, slot
            end
        end
    end
    return nil, nil
end

-- ─── Processing Logic ────────────────────────────────────────────

local function StopProcessing()
    isProcessing = false
    processQueue = {}
    processIndex = 0
    if mainFrame and mainFrame.processBtn then
        mainFrame.processBtn:SetText(L["ph_btn_process"])
        mainFrame.processBtn:Enable()
    end
    if mainFrame and mainFrame.statusText then
        mainFrame.statusText:SetText(L["ph_status_idle"])
    end
end

local function ProcessNext()
    if not isProcessing then return end
    processIndex = processIndex + 1
    if processIndex > #processQueue then
        StopProcessing()
        -- Refresh the list after processing
        C_Timer.After(0.5, function()
            if mainFrame and mainFrame:IsShown() then
                PH.RefreshItems()
            end
        end)
        return
    end

    local entry = processQueue[processIndex]
    local bag, slot = FindItemInBags(entry.itemID)
    if not bag then
        -- Item not found, skip
        C_Timer.After(0.1, ProcessNext)
        return
    end

    if mainFrame and mainFrame.statusText then
        mainFrame.statusText:SetText(string.format(L["ph_status_processing"], processIndex, #processQueue, entry.name))
    end

    local mode = MODES[currentMode]
    C_Container.UseContainerItem(bag, slot)

    -- Wait for spell cast to complete then process next
    C_Timer.After(1.5, ProcessNext)
end

local function StartProcessing()
    local mode = MODES[currentMode]
    if not mode then return end

    -- Build queue from selected items
    processQueue = {}
    local items = ScanBags(mode)
    for _, item in ipairs(items) do
        if selectedItems[item.itemID] then
            local timesToProcess = math.floor(item.count / mode.minStack)
            for i = 1, timesToProcess do
                table.insert(processQueue, item)
            end
        end
    end

    if #processQueue == 0 then return end

    isProcessing = true
    processIndex = 0

    if mainFrame and mainFrame.processBtn then
        mainFrame.processBtn:SetText(L["ph_btn_stop"])
    end

    -- Cast the profession spell and start processing
    local spellName = C_Spell.GetSpellName(mode.spellID)
    if spellName then
        CastSpellByName(spellName)
    end

    C_Timer.After(0.3, ProcessNext)
end

-- ─── UI Creation ─────────────────────────────────────────────────

local function CreateItemButton(parent, index)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(parent:GetWidth() - 10, 42)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.12, 0.12, 0.14, 1)
    btn:SetBackdropBorderColor(0.20, 0.20, 0.25, 0.8)

    -- Item icon
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("LEFT", 5, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    btn.icon = icon

    -- Quality stripe on the left
    local qualStripe = btn:CreateTexture(nil, "OVERLAY")
    qualStripe:SetSize(3, 32)
    qualStripe:SetPoint("LEFT", icon, "LEFT", -4, 0)
    btn.qualStripe = qualStripe

    -- Item name
    local nameText = btn:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(FONT, 12, "")
    nameText:SetPoint("LEFT", icon, "RIGHT", 8, 6)
    nameText:SetPoint("RIGHT", btn, "RIGHT", -60, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetTextColor(unpack(TEXT))
    btn.nameText = nameText

    -- Item level / sub info
    local subText = btn:CreateFontString(nil, "OVERLAY")
    subText:SetFont(FONT, 10, "")
    subText:SetPoint("LEFT", icon, "RIGHT", 8, -8)
    subText:SetJustifyH("LEFT")
    subText:SetTextColor(unpack(DIM))
    btn.subText = subText

    -- Stack count
    local countText = btn:CreateFontString(nil, "OVERLAY")
    countText:SetFont(FONT_B, 12, "OUTLINE")
    countText:SetPoint("RIGHT", -8, 0)
    countText:SetJustifyH("RIGHT")
    countText:SetTextColor(unpack(ACCENT))
    btn.countText = countText

    -- Selection indicator (checkmark overlay)
    local checkmark = btn:CreateTexture(nil, "OVERLAY")
    checkmark:SetSize(16, 16)
    checkmark:SetPoint("TOPRIGHT", -4, -4)
    checkmark:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    checkmark:Hide()
    btn.checkmark = checkmark

    -- Hover highlight
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.18, 0.18, 0.22, 1)
        self:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.8)
        -- Show tooltip
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function(self)
        local selected = self.itemID and selectedItems[self.itemID]
        if selected then
            self:SetBackdropColor(0.05, 0.20, 0.15, 1)
            self:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
        else
            self:SetBackdropColor(0.12, 0.12, 0.14, 1)
            self:SetBackdropBorderColor(0.20, 0.20, 0.25, 0.8)
        end
        GameTooltip:Hide()
    end)

    -- Click to toggle selection
    btn:SetScript("OnClick", function(self)
        if not self.itemID then return end
        selectedItems[self.itemID] = not selectedItems[self.itemID]
        PH.UpdateItemButton(self)
        PH.UpdateProcessButton()
    end)

    return btn
end

function PH.UpdateItemButton(btn)
    if not btn.itemID then
        btn:Hide()
        return
    end

    local selected = selectedItems[btn.itemID]
    btn.checkmark:SetShown(selected)
    if selected then
        btn:SetBackdropColor(0.05, 0.20, 0.15, 1)
        btn:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
    else
        btn:SetBackdropColor(0.12, 0.12, 0.14, 1)
        btn:SetBackdropBorderColor(0.20, 0.20, 0.25, 0.8)
    end
end

function PH.UpdateProcessButton()
    if not mainFrame or not mainFrame.processBtn then return end

    if isProcessing then
        mainFrame.processBtn:SetText(L["ph_btn_stop"])
        mainFrame.processBtn:Enable()
        return
    end

    local hasSelected = false
    for _, v in pairs(selectedItems) do
        if v then hasSelected = true; break end
    end

    mainFrame.processBtn:SetEnabled(hasSelected)
    mainFrame.processBtn:SetAlpha(hasSelected and 1 or 0.4)
end

function PH.RefreshItems()
    if not mainFrame or not mainFrame:IsShown() then return end

    local mode = MODES[currentMode]
    if not mode then return end

    local items = ScanBags(mode)
    local scrollChild = mainFrame.scrollChild

    -- Clean up old buttons
    for _, btn in ipairs(itemButtons) do
        btn:Hide()
        btn.itemID = nil
    end

    -- Create/reuse buttons
    for i, item in ipairs(items) do
        local btn = itemButtons[i]
        if not btn then
            btn = CreateItemButton(scrollChild, i)
            itemButtons[i] = btn
        end

        btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, -((i - 1) * 46) - 5)
        btn:SetSize(scrollChild:GetWidth() - 10, 42)
        btn.itemID = item.itemID
        btn.itemLink = item.link

        btn.icon:SetTexture(item.texture)
        btn.nameText:SetText(item.name)

        local qColor = QUALITY_COLORS[item.quality] or QUALITY_COLORS[1]
        btn.nameText:SetTextColor(qColor[1], qColor[2], qColor[3])
        btn.qualStripe:SetColorTexture(qColor[1], qColor[2], qColor[3], 1)

        local mode = MODES[currentMode]
        if mode.key == "disenchant" then
            btn.subText:SetText(string.format(L["ph_ilvl"], item.level))
        else
            btn.subText:SetText(string.format(L["ph_processable"], math.floor(item.count / mode.minStack)))
        end

        btn.countText:SetText("x" .. item.count)

        -- Preserve or default selection
        if selectedItems[item.itemID] == nil then
            selectedItems[item.itemID] = true
        end

        PH.UpdateItemButton(btn)
        btn:Show()
    end

    -- Update scroll height
    scrollChild:SetHeight(math.max(#items * 46 + 10, 100))

    -- Update custom scrollbar thumb
    if mainFrame.UpdateThumb then
        C_Timer.After(0.01, mainFrame.UpdateThumb)
    end

    -- Count text
    if mainFrame.countText then
        mainFrame.countText:SetText(string.format(L["ph_item_count"], #items))
    end

    PH.UpdateProcessButton()
end

-- ─── Tab Buttons ─────────────────────────────────────────────────

local function CreateTabButton(parent, modeIndex, mode, xOffset)
    local tab = CreateFrame("Button", nil, parent, "BackdropTemplate")
    tab:SetSize(110, 30)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -8)
    tab:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })

    local label = tab:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_B, 11, "")
    label:SetPoint("CENTER")
    label:SetText(mode.label())
    tab.label = label

    tab.modeIndex = modeIndex

    tab:SetScript("OnClick", function()
        if isProcessing then return end
        currentMode = modeIndex
        selectedItems = {}
        PH.UpdateTabs()
        PH.RefreshItems()
        PH.UpdateFilterSection()
    end)

    tab:SetScript("OnEnter", function(self)
        if self.modeIndex == currentMode then return end
        self:SetBackdropColor(0.15, 0.15, 0.18, 1)
    end)

    tab:SetScript("OnLeave", function(self)
        if self.modeIndex == currentMode then return end
        self:SetBackdropColor(0.10, 0.10, 0.12, 1)
    end)

    return tab
end

function PH.UpdateTabs()
    if not mainFrame or not mainFrame.tabs then return end
    for _, tab in ipairs(mainFrame.tabs) do
        if tab.modeIndex == currentMode then
            tab:SetBackdropColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.25)
            tab:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
            tab.label:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
        else
            tab:SetBackdropColor(0.10, 0.10, 0.12, 1)
            tab:SetBackdropBorderColor(unpack(BORDER))
            tab.label:SetTextColor(unpack(DIM))
        end
    end
end

-- ─── Filter Section (Disenchant quality filters) ─────────────────

function PH.UpdateFilterSection()
    if not mainFrame or not mainFrame.filterContainer then return end
    local mode = MODES[currentMode]
    -- Show quality filters only for disenchant
    mainFrame.filterContainer:SetShown(mode.key == "disenchant")
end

local function CreateFilterSection(parent)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(parent:GetWidth() - 20, 36)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -44)
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0.10, 0.10, 0.13, 1)
    container:SetBackdropBorderColor(unpack(BORDER))

    local settings = GetSettings()

    local function CreateQualityCheckbox(label, color, settingKey, x)
        local cb = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
        cb:SetSize(22, 22)
        cb:SetPoint("LEFT", x, 0)
        cb:SetChecked(settings[settingKey] ~= false)

        local text = cb:CreateFontString(nil, "OVERLAY")
        text:SetFont(FONT, 11, "")
        text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        text:SetText(label)
        text:SetTextColor(color[1], color[2], color[3])

        cb:SetScript("OnClick", function(self)
            local val = self:GetChecked()
            if TomoModDB and TomoModDB.professionHelper then
                TomoModDB.professionHelper[settingKey] = val
            end
            selectedItems = {}
            PH.RefreshItems()
        end)

        return cb, text
    end

    local filterLabel = container:CreateFontString(nil, "OVERLAY")
    filterLabel:SetFont(FONT_B, 11, "")
    filterLabel:SetPoint("LEFT", 8, 0)
    filterLabel:SetText(L["ph_filter_quality"])
    filterLabel:SetTextColor(unpack(TEXT))

    CreateQualityCheckbox(L["ph_quality_green"], QUALITY_COLORS[2], "filterGreen", 110)
    CreateQualityCheckbox(L["ph_quality_blue"],  QUALITY_COLORS[3], "filterBlue",  210)
    CreateQualityCheckbox(L["ph_quality_epic"],  QUALITY_COLORS[4], "filterEpic",  300)

    return container
end

-- ─── Select All / Deselect All ───────────────────────────────────

local function CreateActionButtons(parent, yOffset)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(parent:GetWidth() - 20, 28)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)

    -- Select All
    local selectAll = CreateFrame("Button", nil, container, "BackdropTemplate")
    selectAll:SetSize(100, 24)
    selectAll:SetPoint("LEFT", 0, 0)
    selectAll:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    selectAll:SetBackdropColor(0.15, 0.15, 0.18, 1)
    selectAll:SetBackdropBorderColor(unpack(BORDER))

    local saLabel = selectAll:CreateFontString(nil, "OVERLAY")
    saLabel:SetFont(FONT, 10, "")
    saLabel:SetPoint("CENTER")
    saLabel:SetText(L["ph_select_all"])
    saLabel:SetTextColor(unpack(TEXT))
    selectAll:SetScript("OnClick", function()
        for _, btn in ipairs(itemButtons) do
            if btn.itemID and btn:IsShown() then
                selectedItems[btn.itemID] = true
                PH.UpdateItemButton(btn)
            end
        end
        PH.UpdateProcessButton()
    end)
    selectAll:SetScript("OnEnter", function(self) self:SetBackdropColor(0.20, 0.20, 0.25, 1) end)
    selectAll:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.15, 0.18, 1) end)

    -- Deselect All
    local deselectAll = CreateFrame("Button", nil, container, "BackdropTemplate")
    deselectAll:SetSize(100, 24)
    deselectAll:SetPoint("LEFT", selectAll, "RIGHT", 6, 0)
    deselectAll:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    deselectAll:SetBackdropColor(0.15, 0.15, 0.18, 1)
    deselectAll:SetBackdropBorderColor(unpack(BORDER))

    local daLabel = deselectAll:CreateFontString(nil, "OVERLAY")
    daLabel:SetFont(FONT, 10, "")
    daLabel:SetPoint("CENTER")
    daLabel:SetText(L["ph_deselect_all"])
    daLabel:SetTextColor(unpack(TEXT))
    deselectAll:SetScript("OnClick", function()
        for _, btn in ipairs(itemButtons) do
            if btn.itemID and btn:IsShown() then
                selectedItems[btn.itemID] = false
                PH.UpdateItemButton(btn)
            end
        end
        PH.UpdateProcessButton()
    end)
    deselectAll:SetScript("OnEnter", function(self) self:SetBackdropColor(0.20, 0.20, 0.25, 1) end)
    deselectAll:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.15, 0.18, 1) end)

    -- Item count
    local countText = container:CreateFontString(nil, "OVERLAY")
    countText:SetFont(FONT, 10, "")
    countText:SetPoint("RIGHT", -4, 0)
    countText:SetJustifyH("RIGHT")
    countText:SetTextColor(unpack(DIM))

    return container, countText
end

-- ─── Main Frame Builder ──────────────────────────────────────────

local function BuildMainFrame()
    if mainFrame then return mainFrame end

    local f = CreateFrame("Frame", "TomoMod_ProfessionHelperFrame", UIParent, "BackdropTemplate")
    f:SetSize(420, 550)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(unpack(BG))
    f:SetBackdropBorderColor(unpack(BORDER))
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    titleBar:SetSize(f:GetWidth(), 32)
    titleBar:SetPoint("TOPLEFT")
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    titleBar:SetBackdropColor(0.05, 0.05, 0.07, 1)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_B, 13, "")
    title:SetPoint("LEFT", 12, 0)
    title:SetText(L["ph_title"])
    title:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("RIGHT", -6, 0)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetScript("OnClick", function()
        StopProcessing()
        f:Hide()
    end)

    -- Tab bar area
    local tabBar = CreateFrame("Frame", nil, f)
    tabBar:SetSize(f:GetWidth(), 42)
    tabBar:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)

    -- Create tabs for available modes
    f.tabs = {}
    local xOff = 10
    for i, mode in ipairs(MODES) do
        local tab = CreateTabButton(tabBar, i, mode, xOff)
        table.insert(f.tabs, tab)
        xOff = xOff + 116
    end

    -- Filter section (disenchant quality filters)
    local filterContainer = CreateFilterSection(f)
    filterContainer:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 10, -4)
    f.filterContainer = filterContainer

    -- Action buttons (select all / deselect all)
    local filterBottomOffset = -88  -- below tabs + filter
    local actionContainer, countText = CreateActionButtons(f, filterBottomOffset)
    actionContainer:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 10, -44)
    f.actionContainer = actionContainer
    f.countText = countText

    -- ── Custom themed scroll area ─────────────────────────────────
    local SCROLLBAR_W   = 6
    local SCROLLBAR_PAD = 12
    local TRACK_PAD_V   = 4
    local THUMB_MIN_H   = 24

    local scrollContainer = CreateFrame("Frame", nil, f)
    scrollContainer:SetPoint("TOPLEFT", actionContainer, "BOTTOMLEFT", 0, -6)
    scrollContainer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 70)

    -- Track background
    local track = scrollContainer:CreateTexture(nil, "BACKGROUND")
    track:SetWidth(SCROLLBAR_W)
    track:SetPoint("TOPRIGHT",    -2, -TRACK_PAD_V)
    track:SetPoint("BOTTOMRIGHT", -2,  TRACK_PAD_V)
    track:SetColorTexture(0.15, 0.15, 0.18, 1)

    -- Thumb
    local thumbFrame = CreateFrame("Frame", nil, scrollContainer)
    thumbFrame:SetWidth(SCROLLBAR_W)
    thumbFrame:SetPoint("TOPRIGHT", -2, -TRACK_PAD_V)
    local thumb = thumbFrame:CreateTexture(nil, "OVERLAY")
    thumb:SetAllPoints()
    thumb:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)

    -- Scroll frame (no template — plain)
    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollContainer)
    scrollFrame:SetPoint("TOPLEFT",     0,              0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -SCROLLBAR_PAD, 0)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() or 360)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild
    f.scrollFrame = scrollFrame

    -- Thumb update logic
    local function UpdateThumb()
        local scrollH   = scrollFrame:GetHeight() or 0
        local childH    = scrollChild:GetHeight() or 0
        local trackH    = scrollH - 2 * TRACK_PAD_V
        local maxScroll  = childH - scrollH
        if maxScroll <= 0 then
            thumbFrame:Hide(); track:Hide(); return
        end
        track:Show(); thumbFrame:Show()
        local ratio  = math.min(scrollH / childH, 1)
        local thumbH = math.max(math.floor(trackH * ratio), THUMB_MIN_H)
        thumbFrame:SetHeight(thumbH)
        local cur    = scrollFrame:GetVerticalScroll()
        local thumbY = (cur / maxScroll) * (trackH - thumbH)
        thumbFrame:ClearAllPoints()
        thumbFrame:SetPoint("TOPRIGHT", -2, -(TRACK_PAD_V + thumbY))
    end

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local maxS = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * 40, maxS)))
        UpdateThumb()
    end)

    -- Thumb drag
    thumbFrame:EnableMouse(true)
    thumbFrame:RegisterForDrag("LeftButton")
    local dragStartY, dragStartScroll
    thumbFrame:SetScript("OnDragStart", function(self)
        dragStartY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        dragStartScroll = scrollFrame:GetVerticalScroll()
        self:SetScript("OnUpdate", function()
            local curY     = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            local delta    = dragStartY - curY
            local scrollH  = scrollFrame:GetHeight() or 0
            local childH   = scrollChild:GetHeight() or 0
            local trackH   = scrollH - 2 * TRACK_PAD_V
            local ratio    = math.min(scrollH / childH, 1)
            local tH       = math.max(math.floor(trackH * ratio), THUMB_MIN_H)
            local maxS     = childH - scrollH
            local ns       = dragStartScroll + delta * (maxS / (trackH - tH))
            scrollFrame:SetVerticalScroll(math.max(0, math.min(ns, maxS)))
            UpdateThumb()
        end)
    end)
    thumbFrame:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    thumbFrame:SetScript("OnEnter", function() thumb:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.7) end)
    thumbFrame:SetScript("OnLeave", function() thumb:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1) end)

    -- Also allow mouse wheel on the container itself
    scrollContainer:EnableMouseWheel(true)
    scrollContainer:SetScript("OnMouseWheel", function(_, delta)
        local cur = scrollFrame:GetVerticalScroll()
        local maxS = scrollFrame:GetVerticalScrollRange()
        scrollFrame:SetVerticalScroll(math.max(0, math.min(cur - delta * 40, maxS)))
        UpdateThumb()
    end)

    f.UpdateThumb = UpdateThumb

    -- Bottom bar: process button + status
    local bottomBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    bottomBar:SetSize(f:GetWidth(), 60)
    bottomBar:SetPoint("BOTTOMLEFT")
    bottomBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    bottomBar:SetBackdropColor(0.05, 0.05, 0.07, 1)

    -- Process button
    local processBtn = CreateFrame("Button", nil, bottomBar, "BackdropTemplate")
    processBtn:SetSize(180, 34)
    processBtn:SetPoint("CENTER", 0, 6)
    processBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    processBtn:SetBackdropColor(ACCENT[1] * 0.6, ACCENT[2] * 0.6, ACCENT[3] * 0.6, 1)
    processBtn:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)

    local processLabel = processBtn:CreateFontString(nil, "OVERLAY")
    processLabel:SetFont(FONT_B, 13, "")
    processLabel:SetPoint("CENTER")
    processLabel:SetText(L["ph_btn_process"])
    processLabel:SetTextColor(1, 1, 1, 1)
    processBtn.label = processLabel
    processBtn.SetText = function(self, text) self.label:SetText(text) end

    processBtn:SetScript("OnClick", function()
        if isProcessing then
            StopProcessing()
        else
            StartProcessing()
        end
    end)
    processBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
        self.label:SetTextColor(0.05, 0.05, 0.08, 1)
    end)
    processBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(ACCENT[1] * 0.6, ACCENT[2] * 0.6, ACCENT[3] * 0.6, 1)
        self.label:SetTextColor(1, 1, 1, 1)
    end)
    f.processBtn = processBtn

    -- Status text
    local statusText = bottomBar:CreateFontString(nil, "OVERLAY")
    statusText:SetFont(FONT, 10, "")
    statusText:SetPoint("BOTTOM", bottomBar, "BOTTOM", 0, 6)
    statusText:SetTextColor(unpack(DIM))
    statusText:SetText(L["ph_status_idle"])
    f.statusText = statusText

    -- ESC to close
    tinsert(UISpecialFrames, f:GetName())

    -- Register events for auto-refresh
    f:RegisterEvent("BAG_UPDATE")
    f:SetScript("OnEvent", function(self, event)
        if event == "BAG_UPDATE" and not isProcessing then
            C_Timer.After(0.2, function()
                if self:IsShown() then
                    PH.RefreshItems()
                end
            end)
        end
    end)

    mainFrame = f
    return f
end

-- ─── Public API ──────────────────────────────────────────────────

function PH.Initialize()
    if not TomoModDB or not TomoModDB.professionHelper or not TomoModDB.professionHelper.enabled then return end
    -- Frame is built on demand via Toggle
end

function PH.Toggle()
    local f = BuildMainFrame()
    if f:IsShown() then
        StopProcessing()
        f:Hide()
    else
        currentMode = 1
        selectedItems = {}

        -- Auto-select the first available mode
        for i, mode in ipairs(MODES) do
            if HasSpellLearned(mode.spellID) then
                currentMode = i
                break
            end
        end

        PH.UpdateTabs()
        PH.UpdateFilterSection()
        f:Show()
        PH.RefreshItems()
    end
end

function PH.Show()
    local f = BuildMainFrame()
    if not f:IsShown() then
        PH.Toggle()
    end
end

function PH.Hide()
    if mainFrame and mainFrame:IsShown() then
        StopProcessing()
        mainFrame:Hide()
    end
end

TomoMod_RegisterModule("professionHelper", PH)

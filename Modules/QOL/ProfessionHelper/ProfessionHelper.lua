-- =====================================
-- ProfessionHelper.lua — Disenchant batch helper
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

-- [PERF] Hoisted sort comparator
local function SortItemsByQualityName(a, b)
    if a.quality ~= b.quality then return a.quality > b.quality end
    return a.name < b.name
end
local BORDER  = { 0.20, 0.20, 0.25, 1 }
local TEXT    = { 0.90, 0.90, 0.92, 1 }
local DIM     = { 0.55, 0.55, 0.60, 1 }

-- Spell ID for disenchant
local SPELL_DISENCHANT = 13262

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

-- ─── Mode definition (Disenchant only) ───────────────────────────
local MODE = {
    key       = "disenchant",
    spellID   = SPELL_DISENCHANT,
    label     = function() return L["ph_tab_disenchant"] end,
    filter    = function(itemInfo, settings)
        -- Disenchantable: equipment of green+ quality
        if not itemInfo then return false end
        local quality = itemInfo.quality or 0
        local classID = itemInfo.classID
        local subclassID = itemInfo.subclassID
        local itemSubType = itemInfo.itemSubType

        -- Must be green (2) through epic (4)
        if quality < QUALITY_UNCOMMON or quality > QUALITY_EPIC then return false end

        -- Must be a valid equipment type:
        -- classID 2 = Weapon (but not subclass 14 = Miscellaneous)
        -- classID 4 = Armor
        -- classID 19 = Profession Equipment
        -- classID 3 + subclass 11 = Gem (Artifact Relic)
        local isValidType = false
        if classID == 2 and subclassID ~= 14 then
            isValidType = true
        elseif classID == 4 then
            isValidType = true
        elseif classID == 19 then
            isValidType = true
        elseif classID == 3 and subclassID == 11 then
            isValidType = true
        end
        if not isValidType then return false end

        -- Cosmetic items cannot be disenchanted
        if itemSubType and ITEM_COSMETIC and itemSubType == ITEM_COSMETIC then return false end

        -- Apply quality filter from settings
        if settings.filterGreen and quality == QUALITY_UNCOMMON then return true end
        if settings.filterBlue and quality == QUALITY_RARE then return true end
        if settings.filterEpic and quality == QUALITY_EPIC then return true end
        return false
    end,
    minStack  = 1,
}

-- ─── State ───────────────────────────────────────────────────────
local mainFrame
local itemButtons = {}
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

local pendingCacheRetry = nil
local cacheRetryCount = 0
local MAX_CACHE_RETRIES = 5

local function ScanBags(mode)
    local settings = GetSettings()
    local items = {}
    local seen = {}
    local hasMissing = false

    -- Scan all bags: 0-4 normal, 5 reagent bag
    for bag = 0, 5 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local itemID = info.itemID
                if not seen[itemID] then
                    seen[itemID] = {
                        count       = 0,
                        bag         = bag,
                        slot        = slot,
                        quality     = info.quality,
                        link        = info.hyperlink,
                        iconID      = info.iconFileID,
                    }
                end
                seen[itemID].count = seen[itemID].count + (info.stackCount or 1)
            end
        end
    end

    for itemID, data in pairs(seen) do
        -- Use the hyperlink from container info — more reliable for cache lookups
        local source = data.link or itemID
        local itemName, itemLink, itemQuality, itemLevel, _, _, itemSubType, _, _, itemTexture, _, classID, subclassID = GetItemInfo(source)
        if itemName then
            local itemInfo = {
                itemID      = itemID,
                name        = itemName,
                link        = itemLink or data.link,
                quality     = itemQuality or data.quality or 0,
                level       = itemLevel or 0,
                texture     = itemTexture or data.iconID,
                classID     = classID,
                subclassID  = subclassID,
                itemSubType = itemSubType,
                count       = data.count,
            }
            if mode.filter(itemInfo, settings) and data.count >= mode.minStack then
                items[#items + 1] = itemInfo
            end
        else
            -- Item not in cache — request load
            C_Item.RequestLoadItemDataByID(itemID)
            hasMissing = true
        end
    end

    -- Retry with increasing delay if items not cached yet
    if hasMissing and (not pendingCacheRetry) and cacheRetryCount < MAX_CACHE_RETRIES then
        pendingCacheRetry = true
        cacheRetryCount = cacheRetryCount + 1
        C_Timer.After(0.3 + (cacheRetryCount * 0.2), function()
            pendingCacheRetry = nil
            if mainFrame and mainFrame:IsShown() then
                PH.RefreshItems()
            end
        end)
    end

    table.sort(items, SortItemsByQualityName)

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

-- ─── Secure Spell Button (hidden, casts the profession spell on a bag slot) ───
local spellButton = CreateFrame("Button", "TomoMod_PH_SpellButton", UIParent, "SecureActionButtonTemplate")
spellButton:RegisterForClicks("AnyUp", "AnyDown")
spellButton:SetAttribute("type", "spell")
spellButton:Hide()

-- ─── Processing Logic ────────────────────────────────────────────

local function BuildProcessQueue()
    local queue = {}
    local items = ScanBags(MODE)
    for _, item in ipairs(items) do
        local timesToProcess = math.floor(item.count / MODE.minStack)
        for _ = 1, timesToProcess do
            queue[#queue + 1] = { itemID = item.itemID, name = item.name }
        end
    end
    return queue
end

-- Configure spellButton + processBtn macro for the current processIndex
local function ConfigureNextTarget()
    if InCombatLockdown() then return false end
    if not isProcessing or processIndex > #processQueue then return false end

    local entry = processQueue[processIndex]
    if not entry then return false end

    local bag, slot = FindItemInBags(entry.itemID)
    if not bag then
        -- Item gone from bags — skip it
        return false
    end

    -- Point the hidden spell button at this bag/slot
    spellButton:SetAttribute("spell", tostring(MODE.spellID))
    spellButton:SetAttribute("target-bag", bag)
    spellButton:SetAttribute("target-slot", slot)

    -- Set the visible process button to /click the spell button
    local mouseClickSuffix = ""
    if GetCVar("ActionButtonUseKeyDown") == "1" then
        mouseClickSuffix = " LeftButton 1"
    end
    if mainFrame and mainFrame.processBtn then
        mainFrame.processBtn:SetAttribute("type", "macro")
        mainFrame.processBtn:SetAttribute("macrotext", "/click TomoMod_PH_SpellButton" .. mouseClickSuffix)
    end

    -- Update status text
    if mainFrame and mainFrame.statusText then
        mainFrame.statusText:SetText(string.format(L["ph_status_processing"], processIndex, #processQueue, entry.name))
    end

    return true
end

local function StopProcessing()
    isProcessing = false
    processQueue = {}
    processIndex = 0
    if not InCombatLockdown() then
        if mainFrame and mainFrame.processBtn then
            mainFrame.processBtn.label:SetText(L["ph_btn_process"])
            mainFrame.processBtn:SetAttribute("type", nil)
            mainFrame.processBtn:SetAttribute("macrotext", nil)
        end
    end
    if mainFrame and mainFrame.statusText then
        mainFrame.statusText:SetText(L["ph_status_idle"])
    end
end

-- Called by processBtn PreClick on the FIRST click only
local function StartProcessing()
    if InCombatLockdown() then return end

    processQueue = BuildProcessQueue()
    if #processQueue == 0 then return end

    isProcessing = true
    processIndex = 1  -- Start at first item

    if mainFrame and mainFrame.processBtn then
        mainFrame.processBtn.label:SetText(L["ph_btn_click_process"])
    end

    -- Configure target for the first click (this PreClick sets attrs BEFORE secure action fires)
    ConfigureNextTarget()
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
        self:SetBackdropColor(0.12, 0.12, 0.14, 1)
        self:SetBackdropBorderColor(0.20, 0.20, 0.25, 0.8)
        GameTooltip:Hide()
    end)

    return btn
end

function PH.UpdateItemButton(btn)
    if not btn.itemID then
        btn:Hide()
        return
    end
    btn:SetBackdropColor(0.12, 0.12, 0.14, 1)
    btn:SetBackdropBorderColor(0.20, 0.20, 0.25, 0.8)
end

function PH.UpdateProcessButton()
    if not mainFrame or not mainFrame.processBtn then return end
    if InCombatLockdown() then return end

    if isProcessing then
        -- Already processing — button is in macro mode, keep it
        return
    end

    -- When not processing, clear the macro so clicking does PreClick -> StartProcessing
    mainFrame.processBtn:SetAttribute("type", nil)
    mainFrame.processBtn:SetAttribute("macrotext", nil)
    mainFrame.processBtn.label:SetText(L["ph_btn_process"])

    -- Enable if there are any items to process
    local hasItems = false
    for _, btn in ipairs(itemButtons) do
        if btn.itemID and btn:IsShown() then
            hasItems = true
            break
        end
    end
    mainFrame.processBtn:SetAlpha(hasItems and 1 or 0.4)
end

function PH.RefreshItems()
    if not mainFrame or not mainFrame:IsShown() then return end

    local items = ScanBags(MODE)
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

        btn.subText:SetText(string.format(L["ph_ilvl"], item.level))

        btn.countText:SetText("x" .. item.count)

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

-- ─── Filter Section (Disenchant quality filters) ─────────────────

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

    -- Filter section (quality filters — always visible)
    local filterContainer = CreateFilterSection(f)
    filterContainer:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 10, -4)
    f.filterContainer = filterContainer

    -- Item count text (right-aligned below filter)
    local countText = f:CreateFontString(nil, "OVERLAY")
    countText:SetFont(FONT, 10, "")
    countText:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", -14, -44)
    countText:SetJustifyH("RIGHT")
    countText:SetTextColor(unpack(DIM))
    f.countText = countText

    -- ── Custom themed scroll area ─────────────────────────────────
    local SCROLLBAR_W   = 6
    local SCROLLBAR_PAD = 12
    local TRACK_PAD_V   = 4
    local THUMB_MIN_H   = 24

    local scrollContainer = CreateFrame("Frame", nil, f)
    scrollContainer:SetPoint("TOPLEFT", filterContainer, "BOTTOMLEFT", 0, -20)
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

    -- Process button — SecureActionButtonTemplate so it can /click the spell button
    local processBtn = CreateFrame("Button", "TomoMod_PH_ProcessButton", bottomBar, "SecureActionButtonTemplate, BackdropTemplate")
    processBtn:RegisterForClicks("AnyUp", "AnyDown")
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

    -- PreClick: runs BEFORE the secure action system processes the click.
    -- First click → StartProcessing (builds queue, sets index=1, configures item 1)
    -- Subsequent clicks → advance index, configure next item for THIS click
    processBtn:SetScript("PreClick", function(self, button, down)
        if InCombatLockdown() then return end

        if not isProcessing then
            StartProcessing()
            return
        end

        -- Already processing: advance to next item
        processIndex = processIndex + 1
        if processIndex > #processQueue then
            -- All done
            StopProcessing()
            if mainFrame and mainFrame.statusText then
                mainFrame.statusText:SetText(L["ph_status_done"])
            end
            C_Timer.After(0.5, function()
                if mainFrame and mainFrame:IsShown() then
                    PH.RefreshItems()
                end
            end)
            return
        end

        -- Skip any items that are no longer in bags
        while processIndex <= #processQueue do
            if ConfigureNextTarget() then
                return  -- configured successfully
            end
            processIndex = processIndex + 1
        end

        -- If we got here, all remaining items were gone
        StopProcessing()
        if mainFrame and mainFrame.statusText then
            mainFrame.statusText:SetText(L["ph_status_done"])
        end
        C_Timer.After(0.5, function()
            if mainFrame and mainFrame:IsShown() then
                PH.RefreshItems()
            end
        end)
    end)
    -- PostClick: no-op
    processBtn:SetScript("PostClick", function(self, button, down)
    end)
    processBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
        processLabel:SetTextColor(0.05, 0.05, 0.08, 1)
    end)
    processBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(ACCENT[1] * 0.6, ACCENT[2] * 0.6, ACCENT[3] * 0.6, 1)
        processLabel:SetTextColor(1, 1, 1, 1)
    end)
    f.processBtn = processBtn

    -- Stop button (separate, to cancel processing)
    local stopBtn = CreateFrame("Button", nil, bottomBar, "BackdropTemplate")
    stopBtn:SetSize(60, 34)
    stopBtn:SetPoint("LEFT", processBtn, "RIGHT", 8, 0)
    stopBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    stopBtn:SetBackdropColor(0.25, 0.08, 0.08, 1)
    stopBtn:SetBackdropBorderColor(0.60, 0.20, 0.20, 1)
    local stopLabel = stopBtn:CreateFontString(nil, "OVERLAY")
    stopLabel:SetFont(FONT_B, 11, "")
    stopLabel:SetPoint("CENTER")
    stopLabel:SetText(L["ph_btn_stop"])
    stopLabel:SetTextColor(1, 1, 1, 1)
    stopBtn:SetScript("OnClick", function()
        StopProcessing()
    end)
    stopBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.60, 0.20, 0.20, 1) end)
    stopBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.25, 0.08, 0.08, 1) end)
    f.stopBtn = stopBtn

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
    -- [PERF] Debounce flag prevents multiple timers from accumulating on rapid BAG_UPDATE bursts
    local bagUpdatePending = false
    local itemInfoPending = false
    f:RegisterEvent("BAG_UPDATE")
    f:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    f:SetScript("OnEvent", function(self, event, ...)
        if not self:IsShown() then return end
        if event == "BAG_UPDATE" and not isProcessing then
            if bagUpdatePending then return end
            bagUpdatePending = true
            C_Timer.After(0.2, function()
                bagUpdatePending = false
                if self:IsShown() then
                    PH.RefreshItems()
                end
            end)
        elseif event == "GET_ITEM_INFO_RECEIVED" then
            if itemInfoPending then return end
            itemInfoPending = true
            C_Timer.After(0.1, function()
                itemInfoPending = false
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
        cacheRetryCount = 0
        pendingCacheRetry = nil
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

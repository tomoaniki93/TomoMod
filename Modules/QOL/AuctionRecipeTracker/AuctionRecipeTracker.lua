-- =====================================
-- AuctionRecipeTracker.lua
-- QOL: when at an auctioneer (AH open), show tracked crafting recipes
-- with their reagents. Each reagent is clickable for a quick AH search.
-- Optional manual full AH scan to remember the lowest buyout per itemID.
-- =====================================

TomoMod_AuctionRecipeTracker = TomoMod_AuctionRecipeTracker or {}
local ART = TomoMod_AuctionRecipeTracker
local L = TomoMod_L or setmetatable({}, { __index = function(_, k) return k end })

-- ─── Constants ───────────────────────────────────────────────────
local FONT   = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_B = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

local ACCENT  = { 0.047, 0.824, 0.624, 1 }
local BG      = { 0.08, 0.08, 0.10, 0.97 }
local BG_DARK = { 0.06, 0.06, 0.08, 1 }
local BORDER  = { 0.20, 0.20, 0.25, 1 }
local TEXT    = { 0.90, 0.90, 0.92, 1 }
local DIM     = { 0.55, 0.55, 0.60, 1 }

local FRAME_W = 320
local FRAME_H = 460
local ROW_H   = 26
local HEADER_H = 22

local SCAN_COOLDOWN = 15 * 60 -- seconds (Blizzard hard cap on ReplicateItems)

-- ─── Saved data ──────────────────────────────────────────────────
local function GetDB()
    TomoModDB = TomoModDB or {}
    TomoModDB.auctionRecipeTracker = TomoModDB.auctionRecipeTracker or {
        prices = {},          -- [itemID] = copper (per unit)
        lastScan = 0,         -- epoch
        framePos = nil,       -- {point, relPoint, x, y}
    }
    return TomoModDB.auctionRecipeTracker
end

-- ─── State ───────────────────────────────────────────────────────
local mainFrame
local scrollChild
local rowPool = {}
local rowCount = 0
local scanInProgress = false
local scanAbortTimer

-- ─── Helpers ─────────────────────────────────────────────────────

local function FormatGold(copper)
    if not copper or copper <= 0 then return "—" end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    if g > 0 then
        return string.format("|cffffd100%dg|r %ds %dc", g, s, c)
    elseif s > 0 then
        return string.format("|cffc7c7cf%ds|r %dc", s, c)
    else
        return string.format("|cffeda55f%dc|r", c)
    end
end

local function SearchAH(searchString, qty)
    if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then return end
    if not searchString or searchString == "" then return end

    -- Switch to Buy/Browse view
    if AuctionHouseFrame.SetDisplayMode and AuctionHouseFrameDisplayMode and AuctionHouseFrameDisplayMode.Buy then
        AuctionHouseFrame:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
    end

    if AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.SetText then
        AuctionHouseFrame.SearchBar:SetText(searchString)
    end

    -- Browse by name: this is the only path that reliably drives the AH UI to
    -- display results. An exact item-key search (C_AuctionHouse.SendSearchQuery)
    -- loads the data but does not navigate the UI, so nothing appears on screen.
    if C_AuctionHouse and C_AuctionHouse.SendBrowseQuery then
        C_AuctionHouse.SendBrowseQuery({
            searchString = searchString,
            sorts = { { sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false } },
            minLevel = 0,
            maxLevel = 0,
            filters = {},
            itemClassFilters = {},
        })
    end
    if mainFrame and mainFrame.statusText then
        if qty and qty > 0 then
            mainFrame.statusText:SetText(string.format(
                L["art_searching_qty"] or "Recherche : %s \xc3\x97 %d",
                searchString, qty))
        else
            mainFrame.statusText:SetText(string.format(
                L["art_searching"] or "Recherche : %s", searchString))
        end
    end
end

-- ─── Recipe data gathering ───────────────────────────────────────
-- Returns a list of recipe groups:
-- { { recipeID, name, icon, reagents = { { itemID, name, icon, qty } ... } }, ... }
local function CollectTrackedRecipes()
    local out = {}
    if not C_TradeSkillUI or not C_TradeSkillUI.GetRecipesTracked then
        return out
    end

    local seen = {}

    local function AddRecipe(recipeID, isRecraft)
        if seen[recipeID .. ":" .. (isRecraft and 1 or 0)] then return end
        seen[recipeID .. ":" .. (isRecraft and 1 or 0)] = true

        local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
        if not info then return end

        local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, isRecraft)
        if not schematic then return end

        local entry = {
            recipeID = recipeID,
            name = info.name or ("Recipe " .. recipeID),
            icon = info.icon,
            isRecraft = isRecraft,
            reagents = {},
        }

        local reagentByItem = {}
        for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
            if slot.reagentType == Enum.CraftingReagentType.Basic and #slot.reagents > 0 then
                local itemID = slot.reagents[1].itemID
                if itemID then
                    if reagentByItem[itemID] then
                        reagentByItem[itemID].qty = reagentByItem[itemID].qty
                            + (slot.quantityRequired or 1)
                    else
                        local r = {
                            itemID = itemID,
                            qty = slot.quantityRequired or 1,
                            name = nil,
                            icon = nil,
                        }
                        reagentByItem[itemID] = r
                        table.insert(entry.reagents, r)
                    end
                end
            end
        end

        table.insert(out, entry)
    end

    for _, recipeID in ipairs(C_TradeSkillUI.GetRecipesTracked(false) or {}) do
        AddRecipe(recipeID, false)
    end
    for _, recipeID in ipairs(C_TradeSkillUI.GetRecipesTracked(true) or {}) do
        AddRecipe(recipeID, true)
    end

    return out
end

-- ─── UI: row pool ────────────────────────────────────────────────

local function CreateHeaderRow(parent)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(HEADER_H)
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    row:SetBackdropColor(0.10, 0.16, 0.14, 1)
    row:SetBackdropBorderColor(unpack(ACCENT))

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", 4, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_B, 11, "")
    label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(unpack(ACCENT))
    row.label = label

    -- Total cost of all reagents (right-aligned). Empty when no prices known.
    local total = row:CreateFontString(nil, "OVERLAY")
    total:SetFont(FONT_B, 11, "")
    total:SetPoint("RIGHT", -6, 0)
    total:SetJustifyH("RIGHT")
    total:SetTextColor(unpack(ACCENT))
    row.total = total

    label:SetPoint("RIGHT", total, "LEFT", -6, 0)

    return row
end

local function CreateReagentRow(parent)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetHeight(ROW_H)
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    row:SetBackdropColor(0.12, 0.12, 0.14, 0.9)
    row:SetBackdropBorderColor(unpack(BORDER))

    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.18, 0.22, 0.20, 0.95)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        elseif self.itemID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(self.itemID)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.14, 0.9)
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function(self)
        if self.itemName then
            SearchAH(self.itemName, self.reagentQty)
        end
    end)

    -- Quantity sits to the LEFT of the icon: "14x [icon] Item name ......... price"
    local qty = row:CreateFontString(nil, "OVERLAY")
    qty:SetFont(FONT_B, 12, "")
    qty:SetPoint("LEFT", 6, 0)
    qty:SetWidth(30)
    qty:SetJustifyH("RIGHT")
    qty:SetTextColor(unpack(ACCENT))
    row.qty = qty

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("LEFT", qty, "RIGHT", 4, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(FONT, 11, "")
    name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    name:SetJustifyH("LEFT")
    name:SetTextColor(unpack(TEXT))
    row.name = name

    local price = row:CreateFontString(nil, "OVERLAY")
    price:SetFont(FONT, 10, "")
    price:SetPoint("RIGHT", -6, 0)
    price:SetJustifyH("RIGHT")
    price:SetTextColor(unpack(DIM))
    row.price = price

    name:SetPoint("RIGHT", price, "LEFT", -6, 0)

    return row
end

local function AcquireRow(kind)
    rowCount = rowCount + 1
    local row = rowPool[rowCount]
    if not row or row.kind ~= kind then
        if row then row:Hide() end
        if kind == "header" then
            row = CreateHeaderRow(scrollChild)
        else
            row = CreateReagentRow(scrollChild)
        end
        row.kind = kind
        rowPool[rowCount] = row
    end
    row:SetWidth(scrollChild:GetWidth() - 4)
    row:Show()
    return row
end

local function ReleaseUnusedRows(fromIndex)
    for i = fromIndex, #rowPool do
        rowPool[i]:Hide()
    end
end

-- ─── Refresh / layout ────────────────────────────────────────────

local function RefreshUI()
    if not mainFrame or not mainFrame:IsShown() then return end

    local db = GetDB()
    rowCount = 0

    local recipes = CollectTrackedRecipes()

    -- Pending item lookups (resolve names + icons)
    local pending = false

    local y = -2
    if #recipes == 0 then
        local row = AcquireRow("header")
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 2, y)
        row:SetPoint("RIGHT", scrollChild, "RIGHT", -2, 0)
        row.icon:SetTexture(132036) -- generic
        row.label:SetText(L["art_no_recipes"] or "No tracked recipes")
        if row.total then row.total:SetText("") end
    else
        for _, recipe in ipairs(recipes) do
            local header = AcquireRow("header")
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 2, y)
            header:SetPoint("RIGHT", scrollChild, "RIGHT", -2, 0)
            header.icon:SetTexture(recipe.icon or 134400)
            header.label:SetText(recipe.name)
            y = y - HEADER_H - 2

            -- Somme globale des composants : cumulée pendant qu'on dessine les
            -- lignes, puis affichée dans le header au-dessus. Si au moins un
            -- prix est connu, on affiche le total ; sinon on laisse vide.
            local recipeTotal       = 0
            local hasAnyPrice       = false
            local missingPriceCount = 0

            for _, reagent in ipairs(recipe.reagents) do
                local name, link, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(reagent.itemID)
                if not name then
                    pending = true
                    C_Item.RequestLoadItemDataByID(reagent.itemID)
                end
                local row = AcquireRow("reagent")
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 2, y)
                row:SetPoint("RIGHT", scrollChild, "RIGHT", -2, 0)
                row.itemID = reagent.itemID
                row.itemName = name
                row.reagentQty = reagent.qty
                row.itemLink = link
                row.icon:SetTexture(icon or 134400)
                row.qty:SetText(reagent.qty > 0 and (reagent.qty .. "x") or "")
                row.name:SetText(name or ("item:" .. reagent.itemID))

                local unit = db.prices[reagent.itemID]
                if unit then
                    local total = unit * reagent.qty
                    row.price:SetText(FormatGold(total))
                    recipeTotal = recipeTotal + total
                    hasAnyPrice = true
                else
                    row.price:SetText("—")
                    missingPriceCount = missingPriceCount + 1
                end

                y = y - ROW_H - 1
            end

            if hasAnyPrice then
                local txt = FormatGold(recipeTotal)
                if missingPriceCount > 0 then
                    txt = txt .. " |cff808080(~)|r"
                end
                header.total:SetText(txt)
            else
                header.total:SetText("")
            end

            y = y - 4
        end
    end

    ReleaseUnusedRows(rowCount + 1)
    scrollChild:SetHeight(math.max(10, -y))
    if mainFrame and mainFrame.UpdateScrollBar then
        mainFrame.UpdateScrollBar()
    end

    if pending then
        C_Timer.After(0.5, RefreshUI)
    end
end

-- ─── Scan logic ──────────────────────────────────────────────────

local scanFrame = CreateFrame("Frame")

local function FinishScan(success, processed)
    scanInProgress = false
    if scanAbortTimer then
        scanAbortTimer:Cancel()
        scanAbortTimer = nil
    end
    scanFrame:UnregisterEvent("REPLICATE_ITEM_LIST_UPDATE")
    if mainFrame and mainFrame.scanBtn then
        mainFrame.scanBtn:Enable()
        mainFrame.scanBtn.label:SetText(L["art_scan_btn"] or "Scan AH")
    end
    if mainFrame and mainFrame.statusText then
        if success then
            mainFrame.statusText:SetText(string.format(L["art_scan_done"] or "Scan finished: %d items", processed or 0))
        else
            mainFrame.statusText:SetText(L["art_scan_failed"] or "Scan failed.")
        end
    end
    RefreshUI()
end

local function ProcessReplicateResults()
    if not C_AuctionHouse or not C_AuctionHouse.GetNumReplicateItems then
        FinishScan(false, 0)
        return
    end

    local db = GetDB()
    local num = C_AuctionHouse.GetNumReplicateItems()
    local minPrice = {} -- [itemID] = lowest unit copper

    for i = 0, num - 1 do
        local info = { C_AuctionHouse.GetReplicateItemInfo(i) }
        local count      = info[3]
        local buyout     = info[10]
        local itemID     = info[17]
        if itemID and buyout and buyout > 0 and count and count > 0 then
            local unit = math.ceil(buyout / count)
            if not minPrice[itemID] or unit < minPrice[itemID] then
                minPrice[itemID] = unit
            end
        end
    end

    -- Merge into DB (replace, since this is current market state)
    db.prices = minPrice
    db.lastScan = time()

    local count = 0
    for _ in pairs(minPrice) do count = count + 1 end

    FinishScan(true, count)
end

local function StartScan()
    if scanInProgress then
        if mainFrame and mainFrame.statusText then
            mainFrame.statusText:SetText("|cffff8080" .. (L["art_scan_already"] or "A scan is already in progress.") .. "|r")
        end
        return
    end
    if not (AuctionHouseFrame and AuctionHouseFrame:IsShown()) then
        if mainFrame and mainFrame.statusText then
            mainFrame.statusText:SetText("|cffff8080" .. (L["art_only_at_ah"] or "Open the Auction House first.") .. "|r")
        end
        return
    end
    if not (C_AuctionHouse and C_AuctionHouse.ReplicateItems) then
        if mainFrame and mainFrame.statusText then
            mainFrame.statusText:SetText("|cffff8080API C_AuctionHouse.ReplicateItems unavailable|r")
        end
        return
    end

    local db = GetDB()
    local now = time()
    if db.lastScan and (now - db.lastScan) < SCAN_COOLDOWN then
        local remain = SCAN_COOLDOWN - (now - db.lastScan)
        if mainFrame and mainFrame.statusText then
            mainFrame.statusText:SetText(string.format(
                L["art_scan_cooldown"] or "Next scan available in %dm %ds",
                math.floor(remain / 60), remain % 60
            ))
        end
        return
    end

    scanInProgress = true
    if mainFrame and mainFrame.scanBtn then
        mainFrame.scanBtn:Disable()
        mainFrame.scanBtn.label:SetText(L["art_scan_running"] or "Scanning...")
    end
    if mainFrame and mainFrame.statusText then
        mainFrame.statusText:SetText(L["art_scan_started"] or "Scan started — please wait...")
    end

    scanFrame:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
    C_AuctionHouse.ReplicateItems()

    -- Safety timeout (90s)
    scanAbortTimer = C_Timer.NewTimer(90, function()
        if scanInProgress then
            FinishScan(false, 0)
        end
    end)
end

scanFrame:SetScript("OnEvent", function(_, event)
    if event == "REPLICATE_ITEM_LIST_UPDATE" then
        scanFrame:UnregisterEvent("REPLICATE_ITEM_LIST_UPDATE")
        -- Small delay to let the API populate fully
        C_Timer.After(0.3, ProcessReplicateResults)
    end
end)

-- ─── Main frame ──────────────────────────────────────────────────

local function BuildFrame()
    if mainFrame then return mainFrame end

    local f = CreateFrame("Frame", "TomoMod_AuctionRecipeTrackerFrame", UIParent, "BackdropTemplate")
    f:SetSize(FRAME_W, FRAME_H)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local db = GetDB()
        -- [DRAG] screen-absolute coords instead of GetPoint
        local left, bottom = self:GetLeft(), self:GetBottom()
        if left and bottom then
            local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
            db.framePos = { point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT",
                            x = left * scale, y = bottom * scale }
        end
    end)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(unpack(BG))
    f:SetBackdropBorderColor(unpack(BORDER))
    f:Hide()

    local db = GetDB()
    if db.framePos then
        f:ClearAllPoints()
        f:SetPoint(db.framePos.point or "CENTER", UIParent,
            db.framePos.relPoint or "CENTER",
            db.framePos.x or 0, db.framePos.y or 0)
    else
        -- Default: glued to the right edge of the Auction House window.
        -- AuctionHouseFrame is built on demand; fall back to UIParent if not ready.
        f:ClearAllPoints()
        if AuctionHouseFrame then
            f:SetPoint("TOPLEFT", AuctionHouseFrame, "TOPRIGHT", 8, 0)
        else
            f:SetPoint("RIGHT", UIParent, "RIGHT", -40, 0)
        end
    end

    -- Title bar
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_B, 13, "")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("|cff2ed884Tomo|rMod — " .. (L["art_title"] or "Recipe Tracker"))
    title:SetTextColor(unpack(TEXT))

    -- Close button
    local close = CreateFrame("Button", nil, f)
    close:SetSize(18, 18)
    close:SetPoint("TOPRIGHT", -6, -6)
    local cx = close:CreateFontString(nil, "OVERLAY")
    cx:SetFont(FONT_B, 14, "")
    cx:SetPoint("CENTER")
    cx:SetText("×")
    cx:SetTextColor(0.8, 0.4, 0.4, 1)
    close:SetScript("OnClick", function() f:Hide() end)
    close:SetScript("OnEnter", function() cx:SetTextColor(1, 0.6, 0.6, 1) end)
    close:SetScript("OnLeave", function() cx:SetTextColor(0.8, 0.4, 0.4, 1) end)

    -- Scroll (plain ScrollFrame — we build our own modern scrollbar)
    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:SetPoint("TOPLEFT", 8, -32)
    scroll:SetPoint("BOTTOMRIGHT", -16, 64)
    scroll:EnableMouseWheel(true)
    f.scroll = scroll

    scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(FRAME_W - 28, 10)
    scroll:SetScrollChild(scrollChild)

    -- ─── Modern TomoMod scrollbar ─────────────────────────────────
    local SB_W = 4
    local sbTrack = CreateFrame("Frame", nil, f, "BackdropTemplate")
    sbTrack:SetWidth(SB_W)
    sbTrack:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 8, 0)
    sbTrack:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 8, 0)
    sbTrack:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    sbTrack:SetBackdropColor(0.12, 0.12, 0.14, 0.6)

    local sbThumb = CreateFrame("Button", nil, sbTrack, "BackdropTemplate")
    sbThumb:SetWidth(SB_W)
    sbThumb:SetHeight(40)
    sbThumb:SetPoint("TOP", sbTrack, "TOP", 0, 0)
    sbThumb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    sbThumb:SetBackdropColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.85)
    sbThumb:EnableMouse(true)
    sbThumb:RegisterForDrag("LeftButton")
    sbThumb:SetScript("OnEnter", function(s) s:SetBackdropColor(ACCENT[1], ACCENT[2], ACCENT[3], 1) end)
    sbThumb:SetScript("OnLeave", function(s) s:SetBackdropColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.85) end)

    local function GetMaxScroll()
        local h = scrollChild:GetHeight()
        local vh = scroll:GetHeight()
        return math.max(0, h - vh)
    end

    local function UpdateScrollBar()
        local h = scrollChild:GetHeight()
        local vh = scroll:GetHeight()
        local trackH = sbTrack:GetHeight()
        if h <= vh or vh <= 0 then
            sbTrack:Hide()
            return
        end
        sbTrack:Show()
        local thumbH = math.max(18, trackH * (vh / h))
        sbThumb:SetHeight(thumbH)

        local maxScroll = GetMaxScroll()
        local cur = scroll:GetVerticalScroll()
        local pct = (maxScroll > 0) and (cur / maxScroll) or 0
        local maxThumbY = trackH - thumbH
        sbThumb:ClearAllPoints()
        sbThumb:SetPoint("TOP", sbTrack, "TOP", 0, -pct * maxThumbY)
    end
    f.UpdateScrollBar = UpdateScrollBar

    -- Mouse wheel
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = GetMaxScroll()
        if maxScroll <= 0 then return end
        local step = ROW_H * 2
        local newVal = math.max(0, math.min(maxScroll, self:GetVerticalScroll() - delta * step))
        self:SetVerticalScroll(newVal)
        UpdateScrollBar()
    end)

    -- Drag thumb
    local dragging, dragOffsetY = false, 0
    sbThumb:SetScript("OnMouseDown", function(s)
        dragging = true
        local _, cursorY = GetCursorPosition()
        local scale = s:GetEffectiveScale()
        local _, thumbY = s:GetCenter()
        dragOffsetY = (cursorY / scale) - thumbY
        s:SetScript("OnUpdate", function()
            local cy = select(2, GetCursorPosition()) / s:GetEffectiveScale()
            local _, trackTop = sbTrack:GetCenter()
            local trackH = sbTrack:GetHeight()
            local thumbH = s:GetHeight()
            local localY = (trackTop + trackH / 2) - (cy - dragOffsetY) - thumbH / 2
            local maxThumbY = trackH - thumbH
            localY = math.max(0, math.min(maxThumbY, localY))
            local pct = (maxThumbY > 0) and (localY / maxThumbY) or 0
            scroll:SetVerticalScroll(pct * GetMaxScroll())
            s:ClearAllPoints()
            s:SetPoint("TOP", sbTrack, "TOP", 0, -localY)
        end)
    end)
    sbThumb:SetScript("OnMouseUp", function(s)
        dragging = false
        s:SetScript("OnUpdate", nil)
    end)

    -- Click on track jumps
    sbTrack:EnableMouse(true)
    sbTrack:SetScript("OnMouseDown", function(self)
        local _, cy = GetCursorPosition()
        cy = cy / self:GetEffectiveScale()
        local _, trackCenter = self:GetCenter()
        local trackH = self:GetHeight()
        local thumbH = sbThumb:GetHeight()
        local maxThumbY = trackH - thumbH
        local localY = (trackCenter + trackH / 2) - cy - thumbH / 2
        localY = math.max(0, math.min(maxThumbY, localY))
        local pct = (maxThumbY > 0) and (localY / maxThumbY) or 0
        scroll:SetVerticalScroll(pct * GetMaxScroll())
        UpdateScrollBar()
    end)

    scrollChild:HookScript("OnSizeChanged", UpdateScrollBar)
    scroll:HookScript("OnSizeChanged", UpdateScrollBar)

    -- Status text
    local status = f:CreateFontString(nil, "OVERLAY")
    status:SetFont(FONT, 10, "")
    status:SetPoint("BOTTOMLEFT", 10, 42)
    status:SetPoint("BOTTOMRIGHT", -10, 42)
    status:SetJustifyH("LEFT")
    status:SetTextColor(unpack(DIM))
    status:SetText(L["art_status_idle"] or "Click an ingredient to search the AH.")
    f.statusText = status

    -- Scan button
    local scanBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    scanBtn:SetSize(FRAME_W - 20, 28)
    scanBtn:SetPoint("BOTTOMLEFT", 10, 8)
    scanBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    scanBtn:SetBackdropColor(0.10, 0.16, 0.14, 1)
    scanBtn:SetBackdropBorderColor(unpack(ACCENT))
    local sbl = scanBtn:CreateFontString(nil, "OVERLAY")
    sbl:SetFont(FONT_B, 12, "")
    sbl:SetPoint("CENTER")
    sbl:SetText(L["art_scan_btn"] or "Scan AH")
    sbl:SetTextColor(unpack(ACCENT))
    scanBtn.label = sbl
    scanBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.14, 0.22, 0.20, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["art_scan_tip_title"] or "Full Auction House scan")
        GameTooltip:AddLine(L["art_scan_tip_desc"] or "Records the lowest buyout per item. Limited to once every 15 minutes.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    scanBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.16, 0.14, 1)
        GameTooltip:Hide()
    end)
    scanBtn:RegisterForClicks("LeftButtonUp")
    scanBtn:SetScript("OnClick", function(self, button)
        StartScan()
    end)
    f.scanBtn = scanBtn

    f:SetScript("OnShow", function(self)
        -- Defensive reset: a previous AH session could have left
        -- scanInProgress=true (e.g. AH closed mid-scan and OnEvent missed).
        -- Make sure the button is interactive every time the frame is shown.
        if scanInProgress and not (scanAbortTimer) then
            scanInProgress = false
        end
        if self.scanBtn then
            self.scanBtn:Enable()
            if self.scanBtn.label then
                self.scanBtn.label:SetText(L["art_scan_btn"] or "Scan AH")
            end
        end
        RefreshUI()
    end)

    mainFrame = f
    return f
end

-- ─── Event wiring ────────────────────────────────────────────────

local listener = CreateFrame("Frame")
listener:RegisterEvent("AUCTION_HOUSE_SHOW")
listener:RegisterEvent("AUCTION_HOUSE_CLOSED")
listener:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
listener:RegisterEvent("TRACKED_RECIPE_UPDATE")
listener:SetScript("OnEvent", function(_, event)
    if event == "AUCTION_HOUSE_SHOW" then
        -- Always show the frame at the AH so the user can launch a scan
        -- even when no recipes are tracked yet (the row list will simply
        -- display the "no tracked recipes" placeholder).
        BuildFrame():Show()
        RefreshUI()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        if mainFrame then mainFrame:Hide() end
        if scanInProgress then
            FinishScan(false, 0)
        end
    elseif event == "TRADE_SKILL_LIST_UPDATE" or event == "TRACKED_RECIPE_UPDATE" then
        if mainFrame and mainFrame:IsShown() then
            RefreshUI()
        end
    end
end)

-- Slash command
SLASH_TOMOMODARTRACKER1 = "/tmrecipe"
SlashCmdList["TOMOMODARTRACKER"] = function()
    if not (AuctionHouseFrame and AuctionHouseFrame:IsShown()) then
        print("|cff2ed884TomoMod|r: " .. (L["art_only_at_ah"] or "Open the Auction House first."))
        return
    end
    local f = BuildFrame()
    if f:IsShown() then f:Hide() else f:Show() end
end

-- API
ART.Show = function() if AuctionHouseFrame and AuctionHouseFrame:IsShown() then BuildFrame():Show() end end
ART.Hide = function() if mainFrame then mainFrame:Hide() end end
ART.Refresh = RefreshUI

-- ─── Tooltip injection: show "TomoHDV" line on items in bags / anywhere ──
-- Uses the modern TooltipDataProcessor API (retail 10.x+). Falls back to
-- HookScript on older clients.

local function FormatRelativeTime(seconds)
    if not seconds or seconds <= 0 then return nil end
    if seconds < 60 then
        return string.format(L["art_tt_just_now"] or "just now")
    end
    local m = math.floor(seconds / 60)
    if m < 60 then
        return string.format(L["art_tt_min_ago"] or "%dm ago", m)
    end
    local h = math.floor(m / 60)
    if h < 24 then
        return string.format(L["art_tt_hour_ago"] or "%dh ago", h)
    end
    local d = math.floor(h / 24)
    return string.format(L["art_tt_day_ago"] or "%dd ago", d)
end

local function AddPriceLines(tooltip, itemID, stackCount)
    if not itemID then return end
    local db = GetDB()
    if not db.prices then return end
    local unit = db.prices[itemID]
    if not unit then return end

    local label = "|cff2ed884TomoHDV|r"
    -- Per-unit price (always shown)
    tooltip:AddDoubleLine(label, FormatGold(unit))

    -- Stack price (only if stack > 1)
    if stackCount and stackCount > 1 then
        tooltip:AddDoubleLine(
            "|cffaaaaaa" .. (L["art_tt_stack"] or "Stack") .. " (" .. stackCount .. ")|r",
            FormatGold(unit * stackCount)
        )
    end

    -- Last scan time
    if db.lastScan and db.lastScan > 0 then
        local rel = FormatRelativeTime(time() - db.lastScan)
        if rel then
            tooltip:AddLine(
                "|cff666666" .. (L["art_tt_scanned"] or "Scanned") .. " " .. rel .. "|r"
            )
        end
    end
end

if TooltipDataProcessor and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if not tooltip or not data then return end
        if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip
            and tooltip ~= ShoppingTooltip1 and tooltip ~= ShoppingTooltip2 then
            return
        end
        -- 12.x: skip compare/EncounterJournal tooltips — injecting a price line
        -- there taints Blizzard's secret-money (sell price) arithmetic.
        if TomoMod_IsCompareOrMoneyTooltip and TomoMod_IsCompareOrMoneyTooltip(tooltip) then return end
        local itemID = data.id
        local stack
        local _, link = TooltipUtil and TooltipUtil.GetDisplayedItem
            and TooltipUtil.GetDisplayedItem(tooltip) or nil, nil
        -- Try to read stack count from the owner button (bag slot, etc.)
        local owner = tooltip:GetOwner()
        if owner and owner.GetObjectType and owner:GetObjectType() == "Button" then
            local cnt = owner.count or owner.Count
            if type(cnt) == "table" and cnt.GetText then
                stack = tonumber(cnt:GetText())
            elseif type(cnt) == "number" then
                stack = cnt
            end
        end
        AddPriceLines(tooltip, itemID, stack)
    end)
else
    -- Legacy fallback
    GameTooltip:HookScript("OnTooltipSetItem", function(self)
        if TomoMod_IsCompareOrMoneyTooltip and TomoMod_IsCompareOrMoneyTooltip(self) then return end
        local _, link = self:GetItem()
        if not link then return end
        local itemID = tonumber(link:match("item:(%d+)"))
        AddPriceLines(self, itemID, nil)
    end)
end


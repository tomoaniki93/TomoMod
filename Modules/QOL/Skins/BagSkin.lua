-- =====================================
-- BagSkin.lua
-- Unified bag grid skin
-- Features: unified/separate mode, quality borders, search/filter,
--           cooldown overlays, quantity badges, drag via Movers
-- Dark theme matching TomoMod palette
-- =====================================

TomoMod_BagSkin = TomoMod_BagSkin or {}
local BS = TomoMod_BagSkin

-- =====================================
-- CONSTANTS & LOCALS
-- =====================================

local ADDON_PATH       = "Interface\\AddOns\\TomoMod\\"
local ADDON_FONT       = ADDON_PATH .. "Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD  = ADDON_PATH .. "Assets\\Fonts\\Poppins-SemiBold.ttf"
local L = TomoMod_L

-- Palette
local ACCENT          = { 0.047, 0.824, 0.624 }
local BG_COLOR        = { 0.045, 0.045, 0.060 }
local HEADER_BG       = { 0.065, 0.065, 0.082 }
local BORDER_COLOR    = { 0.18,  0.18,  0.22 }
local SLOT_BG         = { 0.07,  0.07,  0.09 }
local SLOT_BORDER     = { 0.22,  0.22,  0.28 }
local SEPARATOR       = { 0.14,  0.14,  0.17 }
local TAB_IDLE_TEXT   = { 0.48,  0.48,  0.54 }
local TAB_ACTIVE_TEXT = { 0.92,  0.95,  0.93 }
local SEARCH_BG       = { 0.055, 0.055, 0.072 }
local FOOTER_H        = 28

-- Quality colors (matches WoW item quality enum)
local QUALITY_COLORS = {
    [0] = { 0.62, 0.62, 0.62 },  -- Poor (gray)
    [1] = { 1.00, 1.00, 1.00 },  -- Common (white)
    [2] = { 0.12, 1.00, 0.00 },  -- Uncommon (green)
    [3] = { 0.00, 0.44, 0.87 },  -- Rare (blue)
    [4] = { 0.64, 0.21, 0.93 },  -- Epic (purple)
    [5] = { 1.00, 0.50, 0.00 },  -- Legendary (orange)
    [6] = { 0.90, 0.80, 0.50 },  -- Artifact (gold)
    [7] = { 0.00, 0.80, 1.00 },  -- Heirloom (cyan)
    [8] = { 0.00, 0.80, 1.00 },  -- WoW Token (cyan)
}

-- Crafting quality icons (professions/reagents, tiers 1–5)
local CRAFTING_QUALITY_ATLAS = {
    [1] = "UI-TradeSkill-Quality-Tier1-Icon",
    [2] = "UI-TradeSkill-Quality-Tier2-Icon",
    [3] = "UI-TradeSkill-Quality-Tier3-Icon",
    [4] = "UI-TradeSkill-Quality-Tier4-Icon",
    [5] = "UI-TradeSkill-Quality-Tier5-Icon",
}

-- Sort functions
local SORT_FUNCS = {
    quality = function(a, b)
        if a.quality ~= b.quality then return (a.quality or 0) > (b.quality or 0) end
        return (a.name or "") < (b.name or "")
    end,
    name = function(a, b) return (a.name or "") < (b.name or "") end,
    type = function(a, b)
        if a.itemType ~= b.itemType then return (a.itemType or "") < (b.itemType or "") end
        return (a.name or "") < (b.name or "")
    end,
    recent = function(a, b) return (a.bagID or 0) < (b.bagID or 0) end,
}

-- Bag display names
local BAG_NAMES = {
    [0] = "Backpack",
    [1] = "Bag 1",
    [2] = "Bag 2",
    [3] = "Bag 3",
    [4] = "Bag 4",
}
if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
    BAG_NAMES[Enum.BagIndex.ReagentBag] = "Reagent Bag"
end

-- State
local isInitialized = false
local bagFrame      = nil
local slotButtons   = {}
local bagLabels     = {}  -- pool of FontStrings for bag section headers
local searchBox     = nil
local currentFilter = ""
local tomoButtonCount = 0  -- counter for unique button names (required by SetItemButtonDesaturated)

-- Bag IDs: 0 (backpack), 1-4 (bags), 5 (reagent bag in retail)
local BAG_IDS = { 0, 1, 2, 3, 4 }
-- In retail, also check for reagent bag
if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
    BAG_IDS[#BAG_IDS + 1] = Enum.BagIndex.ReagentBag
end

-- =====================================
-- SETTINGS
-- =====================================

local function S()
    return TomoModDB and TomoModDB.bagSkin or {}
end

local function IsEnabled()
    return S().enabled
end

-- =====================================
-- HELPER: 1px border
-- =====================================

local function CreateBorders(parent, r, g, b, a, layer)
    local borders = {}
    for _, info in ipairs({
        { "TOPLEFT", "TOPLEFT", "TOPRIGHT", "TOPRIGHT", nil, 1 },
        { "BOTTOMLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", nil, 1 },
        { "TOPLEFT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT", 1, nil },
        { "TOPRIGHT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMRIGHT", 1, nil },
    }) do
        local t = parent:CreateTexture(nil, layer or "BORDER")
        t:SetColorTexture(r, g, b, a or 1)
        t:SetPoint(info[1], parent, info[2])
        t:SetPoint(info[3], parent, info[4])
        if info[5] then t:SetWidth(info[5]) end
        if info[6] then t:SetHeight(info[6]) end
        borders[#borders + 1] = t
    end
    return borders
end

-- =====================================
-- FORMAT GOLD
-- =====================================

local function FormatGold(money)
    if not money or money <= 0 then return "|cff666677—|r" end
    return GetCoinTextureString(money)
end

-- =====================================
-- UPDATE FOOTER (gold + backpack currencies)
-- =====================================

local function UpdateFooter()
    if not bagFrame or not bagFrame._footer then return end
    local s = S()

    -- Gold (GetCoinTextureString generates proper |T...|t coin icon escapes)
    if s.showGold ~= false then
        bagFrame._goldText:SetText(FormatGold(GetMoney()))
        bagFrame._goldText:Show()
    else
        bagFrame._goldText:Hide()
    end

    -- Backpack-pinned currencies
    -- Uses global GetNumBackpackCurrencies / GetBackpackCurrencyInfo (available since Cata)
    -- which return texturePath directly usable in |T...|t
    if s.showCurrencies then
        local count = (GetNumBackpackCurrencies and GetNumBackpackCurrencies()) or 0
        if count == 0 then
            bagFrame._currencyText:SetText("|cff555566" .. L["bagskin_currencies_none"] .. "|r")
            bagFrame._currencyText:Show()
        else
            local parts = {}
            for i = 1, math.min(count, 8) do
                local name, amount, texturePath = GetBackpackCurrencyInfo(i)
                if amount then
                    local qty = amount >= 10000
                        and string.format("%d,%03d", math.floor(amount / 1000), amount % 1000)
                        or tostring(amount)
                    if texturePath and texturePath ~= "" then
                        parts[#parts + 1] = "|T" .. texturePath .. ":16:16|t |cffdddddd" .. qty .. "|r"
                    else
                        parts[#parts + 1] = "|cffdddddd" .. qty .. "|r"
                    end
                end
            end
            if #parts > 0 then
                bagFrame._currencyText:SetText(table.concat(parts, "  "))
                bagFrame._currencyText:Show()
            else
                bagFrame._currencyText:SetText("")
                bagFrame._currencyText:Hide()
            end
        end
    else
        bagFrame._currencyText:SetText("")
        bagFrame._currencyText:Hide()
    end
end

-- =====================================
-- COLLECT ALL ITEMS
-- =====================================

-- [PERF] Cache expensive item queries (ilvl, crafting quality) for 10 seconds
local _itemInfoCache = {}
local _itemInfoCacheTime = 0
local ITEM_CACHE_TTL = 10

local function GetCachedItemExtras(itemID, bagID, slotIndex, classID)
    local cacheKey = itemID .. ":" .. bagID .. ":" .. slotIndex
    local now = GetTime()
    -- Invalidate entire cache if TTL expired
    if (now - _itemInfoCacheTime) > ITEM_CACHE_TTL then
        wipe(_itemInfoCache)
        _itemInfoCacheTime = now
    end
    local cached = _itemInfoCache[cacheKey]
    if cached then return cached.ilvl, cached.craftingQuality end

    local ilvl, craftingQuality
    -- Item level for equippable items (Weapon=2, Armor=4)
    if classID == 2 or classID == 4 then
        local ok, loc = pcall(ItemLocation.CreateFromBagAndSlot, ItemLocation, bagID, slotIndex)
        if ok and loc and loc:IsValid() then
            local lvlOk, lvl = pcall(C_Item.GetCurrentItemLevel, loc)
            if lvlOk and lvl and lvl > 0 then ilvl = lvl end
        end
    end
    -- Crafting quality for tradeskill reagents (classID=7)
    if classID == 7 and C_TradeSkillUI and C_TradeSkillUI.GetItemReagentQualityByItemInfo then
        local link = C_Container.GetContainerItemLink(bagID, slotIndex)
        if link then
            local qOk, qual = pcall(C_TradeSkillUI.GetItemReagentQualityByItemInfo, link)
            if qOk then craftingQuality = qual end
        end
    end

    _itemInfoCache[cacheKey] = { ilvl = ilvl, craftingQuality = craftingQuality }
    return ilvl, craftingQuality
end

local function CollectBagItems()
    local items = {}
    for _, bagID in ipairs(BAG_IDS) do
        local numSlots = C_Container.GetContainerNumSlots(bagID)
        for slotIndex = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bagID, slotIndex)
            local entry = {
                bagID     = bagID,
                slotIndex = slotIndex,
                hasItem   = info ~= nil,
                itemID    = info and info.itemID,
                name      = info and info.itemName or "",
                quality   = info and info.quality or 0,
                icon      = info and info.iconFileID,
                count     = info and info.stackCount or 0,
                locked    = info and info.isLocked,
                itemType  = "",
                isFiltered = info and info.isFiltered,
            }
            -- Get item type, item level (gear) and crafting quality (reagents)
            if entry.itemID then
                local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(entry.itemID)
                entry.itemType = classID or ""
                local ilvl, craftingQuality = GetCachedItemExtras(entry.itemID, bagID, slotIndex, classID)
                entry.ilvl = ilvl
                entry.craftingQuality = craftingQuality
            end
            items[#items + 1] = entry
        end
    end
    return items
end

-- =====================================
-- DISENCHANT HELPERS
-- =====================================

-- Item classes that can be disenchanted (Armor=4, Weapon=2)
local DE_ITEM_CLASSES = { [2] = true, [4] = true }
-- Minimum quality for disenchanting (Uncommon=2)
local DE_MIN_QUALITY = 2

local isEnchanterCached = nil
local enchanterCheckTime = 0

local function IsPlayerEnchanter()
    local now = GetTime()
    if isEnchanterCached ~= nil and (now - enchanterCheckTime) < 60 then
        return isEnchanterCached
    end
    enchanterCheckTime = now
    isEnchanterCached = false
    local p1, p2, p3, p4, p5, p6 = GetProfessions()
    for _, idx in ipairs({ p1, p2, p3, p4, p5, p6 }) do
        if idx then
            local name = GetProfessionInfo(idx)
            if name and name:lower():find("enchant") then
                isEnchanterCached = true
                break
            end
        end
    end
    return isEnchanterCached
end

local function IsItemDisenchantable(bagID, slotID, quality, classID)
    if not IsPlayerEnchanter() then return false end
    if not quality or quality < DE_MIN_QUALITY then return false end
    if quality >= 7 then return false end  -- Heirloom / WoW Token: not DE-able
    if not DE_ITEM_CLASSES[classID] then return false end
    return true
end

-- =====================================
-- CREATE SLOT BUTTON
-- =====================================

local function CreateSlotButton(parent, size)
    -- ContainerFrameItemButtonTemplate's click handler calls:
    --   PickupContainerItem(self:GetParent():GetID(), self:GetID())
    -- so the DIRECT parent's ID must equal bagID, and the button's ID must equal slotIndex.
    -- We create a per-slot wrapper frame whose ID is set to bagID each update.
    -- The named ItemButton is a child of the wrapper. (Same pattern as BetterBags)
    tomoButtonCount = tomoButtonCount + 1
    local btnName = "TomoModBagBtn" .. tomoButtonCount

    -- Wrapper: positioned in the grid, holds the bagID
    local wrapper = CreateFrame("Frame", nil, parent)
    wrapper:SetSize(size, size)

    -- Named ItemButton parented to wrapper — template reads wrapper:GetID() = bagID
    local btn = CreateFrame("Button", btnName, wrapper, "ContainerFrameItemButtonTemplate")
    btn:SetAllPoints(wrapper)
    wrapper.btn = btn   -- expose for UpdateSlotButton

    -- Disable template auto-update scripts (they would re-read parent ID on every frame)
    btn:SetScript("OnEvent",  nil)
    btn:SetScript("OnShow",   nil)
    btn:SetScript("OnUpdate", nil)
    -- Disable mouse wheel so scroll events pass through to the bag scroll frame
    btn:SetScript("OnMouseWheel", nil)
    btn:EnableMouseWheel(false)

    -- Dark background on top of whatever the template draws (sub-level 2 > template default)
    local bg = btn:CreateTexture(nil, "BACKGROUND", nil, 2)
    bg:SetAllPoints()
    bg:SetColorTexture(SLOT_BG[1], SLOT_BG[2], SLOT_BG[3], 1)
    btn._bg = bg

    -- Create our own icon texture and redirect btn.icon to it.
    -- Blizzard helpers (SetItemButtonDesaturated, SetItemButtonTexture) check btn.icon
    -- first, then fall back to _G[name.."IconTexture"]. By aliasing btn.icon here we
    -- let those helpers operate on our custom texture. (BetterBags pattern)
    local icon = btn:CreateTexture(nil, "ARTWORK", nil, 1)
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:Hide()
    btn._icon = icon
    btn.icon  = icon  -- alias so Blizzard item-button helpers target our texture
    -- Hide the template's own IconTexture so it doesn't render behind our custom one
    if btn.IconTexture then btn.IconTexture:Hide() end

    -- Hide template's built-in quality border and count badge (we draw our own)
    if btn.IconBorder   then btn.IconBorder:Hide()   end
    if btn.IconOverlay  then btn.IconOverlay:Hide()  end
    if btn.Count        then btn.Count:Hide()        end
    -- Hide template's default slot textures (blue rounded-square empty-slot look)
    if btn.BagIndicator then btn.BagIndicator:Hide() end
    if btn.ExtendedSlot then btn.ExtendedSlot:Hide() end
    if btn.JunkIcon     then btn.JunkIcon:Hide()     end
    if btn.BattlepayItemTexture then btn.BattlepayItemTexture:Hide() end
    if btn.NewItemTexture       then btn.NewItemTexture:Hide()       end
    if btn.UpgradeIcon          then btn.UpgradeIcon:Hide()         end
    if btn.flash                then btn.flash:Hide()               end
    btn:SetNormalTexture("")
    btn:SetPushedTexture("")

    -- Custom 1px quality border lines at OVERLAY so they draw above the icon
    btn._qualBorders = CreateBorders(btn, SLOT_BORDER[1], SLOT_BORDER[2], SLOT_BORDER[3], 0.6, "OVERLAY")

    -- Reuse template's cooldown frame; fall back to creating one if absent
    btn._cooldown = btn.Cooldown
    if not btn._cooldown then
        local cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
        cd:SetAllPoints(icon)
        cd:SetDrawEdge(false)
        cd:SetHideCountdownNumbers(false)
        btn._cooldown = cd
    else
        btn._cooldown:SetAllPoints(icon)
    end

    -- Custom quantity badge (our font/style)
    local qty = btn:CreateFontString(nil, "OVERLAY")
    qty:SetFont(ADDON_FONT_BOLD, 10, "OUTLINE")
    qty:SetPoint("BOTTOMRIGHT", -2, 2)
    qty:SetTextColor(1, 1, 1, 1)
    btn._qtyText = qty

    -- Crafting quality icon (top-left, tier star for reagents)
    local qualIcon = btn:CreateTexture(nil, "OVERLAY", nil, 2)
    qualIcon:SetSize(14, 14)
    qualIcon:SetPoint("TOPLEFT", 2, -2)
    qualIcon:Hide()
    btn._qualIcon = qualIcon

    -- Item level badge (bottom-left, for equippable items)
    local ilvlBadge = btn:CreateFontString(nil, "OVERLAY")
    ilvlBadge:SetFont(ADDON_FONT_BOLD, 8, "OUTLINE")
    ilvlBadge:SetPoint("BOTTOMLEFT", 2, 2)
    ilvlBadge:SetTextColor(1, 0.82, 0.0, 1)
    ilvlBadge:Hide()
    btn._ilvlBadge = ilvlBadge

    -- Override tooltip (ANCHOR_RIGHT instead of template default)
    btn:SetScript("OnEnter", function(self)
        if self.bag and self:GetID() > 0 then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetBagItem(self.bag, self:GetID())
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- PostClick handles modifier actions only.
    -- All standard clicks (pickup, place, use, equip, craft-slot/DE routing) are
    -- handled securely by ContainerFrameItemButtonTemplate.
    btn:HookScript("PostClick", function(self, button, down)
        if down then return end
        if not self.bag or self:GetID() == 0 then return end
        if IsModifiedClick("CHATLINK") then
            local link = C_Container.GetContainerItemLink(self.bag, self:GetID())
            if link then ChatEdit_InsertLink(link) end
        elseif IsModifiedClick("SPLITSTACK") then
            local info = C_Container.GetContainerItemInfo(self.bag, self:GetID())
            if info and (info.stackCount or 0) > 1 then
                C_Container.SplitContainerItem(self.bag, self:GetID(), 1)
            end
        end
    end)

    return wrapper
end

-- =====================================
-- SET QUALITY BORDER COLOR
-- =====================================

local function SetQualityBorder(btn, quality)
    local s = S()
    if not s.showQualityBorders then
        for _, tex in ipairs(btn._qualBorders) do
            tex:SetColorTexture(SLOT_BORDER[1], SLOT_BORDER[2], SLOT_BORDER[3], 0.4)
        end
        return
    end

    local color = QUALITY_COLORS[quality or 0] or QUALITY_COLORS[1]
    local alpha = (quality and quality >= 2) and 0.8 or 0.3
    for _, tex in ipairs(btn._qualBorders) do
        tex:SetColorTexture(color[1], color[2], color[3], alpha)
    end
end

-- =====================================
-- UPDATE A SINGLE SLOT
-- =====================================

local function UpdateSlotButton(wrapper, item)
    if not wrapper then return end
    local btn = wrapper.btn
    if not btn then return end
    local s = S()

    -- ContainerFrameItemButtonTemplate's OnLoad calls SetHasItem(false) → btn:Hide().
    -- Showing the wrapper alone does NOT re-show an explicitly-hidden child button.
    -- Always show btn explicitly here (same as BetterBags self.button:Show()). 
    btn:Show()

    -- The template's click handler calls:
    --   PickupContainerItem(self:GetParent():GetID(), self:GetID())
    -- wrapper:SetID(bagID) ensures self:GetParent():GetID() = bagID (correct).
    -- btn:SetID(slotIndex) ensures self:GetID() = slotIndex (correct).
    wrapper:SetID(item.bagID)
    btn:SetID(item.slotIndex)

    -- Also store on btn for our custom OnEnter tooltip
    btn.bag       = item.bagID
    btn._bagID    = item.bagID
    btn._slotIndex = item.slotIndex
    btn._hasItem  = item.hasItem
    btn._count    = item.count

    -- Right-click /use macro kept as insurance (belt-and-suspenders with wrapper SetID)
    if not InCombatLockdown() then
        local macro = "/use " .. item.bagID .. " " .. item.slotIndex
        if btn._secMacro ~= macro then
            btn:SetAttribute("type2", "macro")
            btn:SetAttribute("macrotext2", macro)
            btn._secMacro = macro
        end
    end

    if item.hasItem and item.icon then
        if btn._icon then
            btn._icon:SetTexture(item.icon)
            btn._icon:Show()
        end
        SetQualityBorder(btn, item.quality)

        -- Quantity badge
        if s.showQuantityBadges and item.count > 1 then
            btn._qtyText:SetText(tostring(item.count))
            btn._qtyText:Show()
        else
            btn._qtyText:Hide()
        end

        -- Cooldown
        if s.showCooldowns and btn._cooldown then
            local start, duration, enable = C_Container.GetContainerItemCooldown(item.bagID, item.slotIndex)
            if start and duration and duration > 0 and enable == 1 then
                btn._cooldown:SetCooldown(start, duration)
                btn._cooldown:Show()
            else
                btn._cooldown:Hide()
            end
        elseif btn._cooldown then
            btn._cooldown:Hide()
        end

        -- Locked / search filter / normal state
        local desaturate = false
        local alpha = 1
        if item.locked then
            desaturate = true
            alpha = 0.4
        elseif currentFilter ~= "" then
            local name = (item.name or ""):lower()
            local match = name:find(currentFilter, 1, true) ~= nil
            desaturate = not match
            alpha = match and 1 or 0.3
        end
        SetItemButtonDesaturated(btn, desaturate)
        if btn._icon then btn._icon:SetAlpha(alpha) end

        -- Item level badge for equippable items (Weapon=2, Armor=4)
        if btn._ilvlBadge then
            if item.ilvl and (item.itemType == 2 or item.itemType == 4) then
                btn._ilvlBadge:SetText(tostring(item.ilvl))
                btn._ilvlBadge:Show()
            else
                btn._ilvlBadge:Hide()
            end
        end

        -- Crafting quality icon for tradeskill reagents (classID=7)
        if btn._qualIcon then
            local atlas = item.craftingQuality and CRAFTING_QUALITY_ATLAS[item.craftingQuality]
            if atlas then
                btn._qualIcon:SetAtlas(atlas, false)
                btn._qualIcon:SetSize(14, 14)
                btn._qualIcon:Show()
            else
                btn._qualIcon:Hide()
            end
        end
    else
        if btn._icon then
            btn._icon:SetTexture(nil)
            btn._icon:Hide()
        end
        btn._qtyText:Hide()
        if btn._cooldown then btn._cooldown:Hide() end
        if btn._ilvlBadge then btn._ilvlBadge:Hide() end
        if btn._qualIcon  then btn._qualIcon:Hide()  end
        SetItemButtonDesaturated(btn, false)
        for _, tex in ipairs(btn._qualBorders) do
            tex:SetColorTexture(SLOT_BORDER[1], SLOT_BORDER[2], SLOT_BORDER[3], 0.2)
        end
    end
end

-- =====================================
-- HELPER: get or create bag section label
-- =====================================

local function GetBagLabel(content, index)
    if bagLabels[index] then return bagLabels[index] end
    local lbl = content:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(ADDON_FONT_BOLD, 11, "")
    lbl:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.85)
    bagLabels[index] = lbl
    return lbl
end

-- =====================================
-- LAYOUT GRID
-- =====================================

local function LayoutGrid()
    if not bagFrame then return end
    local s = S()

    local columns   = s.columns or 12
    local slotSize  = s.slotSize or 36
    local spacing   = s.slotSpacing or 3
    local sortMode  = s.sortMode or "quality"
    local unified   = s.unified ~= false

    -- Collect items
    local items = CollectBagItems()
    local sortFn = SORT_FUNCS[sortMode] or SORT_FUNCS.quality

    local content = bagFrame._content
    local PADDING = 8
    local LABEL_H = 20  -- height reserved for bag section headers
    local SEP_GAP = 6   -- extra gap before each bag section header

    -- Ensure we have enough slot buttons
    while #slotButtons < #items do
        local wrapper = CreateSlotButton(content, slotSize)
        slotButtons[#slotButtons + 1] = wrapper
    end

    -- Hide all bag labels first
    for _, lbl in ipairs(bagLabels) do
        lbl:Hide()
    end

    if unified then
        -- Unified mode: merge all regular bags, keep reagent bag separate
        local reagentBagID = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag
        local mainItems = {}
        local reagentItems = {}

        for _, item in ipairs(items) do
            if reagentBagID and item.bagID == reagentBagID then
                reagentItems[#reagentItems + 1] = item
            else
                mainItems[#mainItems + 1] = item
            end
        end

        table.sort(mainItems, sortFn)
        table.sort(reagentItems, sortFn)

        local x, y = PADDING, -PADDING
        local col = 0
        local slotIdx = 0

        -- Layout main bag items
        for _, item in ipairs(mainItems) do
            slotIdx = slotIdx + 1
            local wrapper = slotButtons[slotIdx]
            wrapper:SetSize(slotSize, slotSize)
            wrapper:ClearAllPoints()
            wrapper:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
            wrapper:Show()
            UpdateSlotButton(wrapper, item)

            col = col + 1
            if col >= columns then
                col = 0
                x = PADDING
                y = y - slotSize - spacing
            else
                x = x + slotSize + spacing
            end
        end

        -- Finish last row of main items
        if col > 0 then
            y = y - slotSize - spacing
            col = 0
            x = PADDING
        end

        -- Reagent bag section (if it has items)
        if #reagentItems > 0 then
            local labelIdx = 1
            -- Separator
            y = y - SEP_GAP
            local sepKey = "_sep_reagent"
            if not content[sepKey] then
                local sep = content:CreateTexture(nil, "ARTWORK")
                sep:SetHeight(1)
                sep:SetColorTexture(SEPARATOR[1], SEPARATOR[2], SEPARATOR[3], 0.5)
                content[sepKey] = sep
            end
            local sep = content[sepKey]
            sep:ClearAllPoints()
            sep:SetPoint("TOPLEFT", content, "TOPLEFT", PADDING, y)
            sep:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PADDING, y)
            sep:Show()
            y = y - 4

            -- Header
            local lbl = GetBagLabel(content, labelIdx)
            lbl:ClearAllPoints()
            lbl:SetPoint("TOPLEFT", content, "TOPLEFT", PADDING, y)
            local numSlots = C_Container.GetContainerNumSlots(reagentBagID)
            lbl:SetText((BAG_NAMES[reagentBagID] or "Reagent Bag") .. "  |cff777788(" .. numSlots .. " slots)|r")
            lbl:Show()
            y = y - LABEL_H

            -- Layout reagent items
            for _, item in ipairs(reagentItems) do
                slotIdx = slotIdx + 1
                local wrapper = slotButtons[slotIdx]
                wrapper:SetSize(slotSize, slotSize)
                wrapper:ClearAllPoints()
                wrapper:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
                wrapper:Show()
                UpdateSlotButton(wrapper, item)

                col = col + 1
                if col >= columns then
                    col = 0
                    x = PADDING
                    y = y - slotSize - spacing
                else
                    x = x + slotSize + spacing
                end
            end

            if col > 0 then
                y = y - slotSize - spacing
            end
        else
            -- Hide reagent separator if no reagent items
            local sepKey = "_sep_reagent"
            if content[sepKey] then content[sepKey]:Hide() end
        end

        -- Hide unused buttons
        for i = slotIdx + 1, #slotButtons do
            slotButtons[i]:Hide()
        end

        -- Resize content
        local contentH = math.abs(y) + PADDING
        content:SetHeight(math.max(contentH, 10))
    else
        -- Separate mode: group items by bag, each bag gets a header + own grid
        local bagGroups = {}
        local bagOrder = {}
        for _, item in ipairs(items) do
            local bid = item.bagID
            if not bagGroups[bid] then
                bagGroups[bid] = {}
                bagOrder[#bagOrder + 1] = bid
            end
            bagGroups[bid][#bagGroups[bid] + 1] = item
        end

        local y = -PADDING
        local slotIdx = 0
        local labelIdx = 0

        for _, bid in ipairs(bagOrder) do
            local group = bagGroups[bid]
            if #group > 0 then
                -- Bag section header
                labelIdx = labelIdx + 1
                local lbl = GetBagLabel(content, labelIdx)
                lbl:ClearAllPoints()

                -- Add separator gap between bags (not before the first)
                if labelIdx > 1 then
                    y = y - SEP_GAP

                    -- Separator line
                    local sepKey = "_sep" .. labelIdx
                    if not content[sepKey] then
                        local sep = content:CreateTexture(nil, "ARTWORK")
                        sep:SetHeight(1)
                        sep:SetColorTexture(SEPARATOR[1], SEPARATOR[2], SEPARATOR[3], 0.5)
                        content[sepKey] = sep
                    end
                    local sep = content[sepKey]
                    sep:ClearAllPoints()
                    sep:SetPoint("TOPLEFT", content, "TOPLEFT", PADDING, y)
                    sep:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PADDING, y)
                    sep:Show()
                    y = y - 4
                end

                lbl:SetPoint("TOPLEFT", content, "TOPLEFT", PADDING, y)
                local bagName = BAG_NAMES[bid] or ("Bag " .. bid)
                local numSlots = C_Container.GetContainerNumSlots(bid)
                lbl:SetText(bagName .. "  |cff777788(" .. numSlots .. " slots)|r")
                lbl:Show()
                y = y - LABEL_H

                -- Layout this bag's grid
                local x = PADDING
                local col = 0
                for _, item in ipairs(group) do
                    slotIdx = slotIdx + 1
                    local wrapper = slotButtons[slotIdx]
                    wrapper:SetSize(slotSize, slotSize)
                    wrapper:ClearAllPoints()
                    wrapper:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
                    wrapper:Show()
                    UpdateSlotButton(wrapper, item)

                    col = col + 1
                    if col >= columns then
                        col = 0
                        x = PADDING
                        y = y - slotSize - spacing
                    else
                        x = x + slotSize + spacing
                    end
                end

                -- Finish the last row
                if col > 0 then
                    y = y - slotSize - spacing
                end
            end
        end

        -- Hide unused buttons
        for i = slotIdx + 1, #slotButtons do
            slotButtons[i]:Hide()
        end

        -- Resize content
        local contentH = math.abs(y) + PADDING
        content:SetHeight(math.max(contentH, 10))
    end

    -- Resize frame width
    local frameW = columns * (slotSize + spacing) - spacing + PADDING * 2
    bagFrame:SetWidth(frameW)

    -- Auto-resize frame height to fit content (capped at 75% screen height)
    local s2 = S()
    local HEADER_H = 32
    local SEARCH_H = (s2.showSearchBar ~= false) and 28 or 0
    local topOffset = HEADER_H + SEARCH_H
    local contentH = bagFrame._content:GetHeight()
    local maxH = (UIParent:GetHeight() / ((s2.scale or 100) / 100)) * 0.75
    local totalH = topOffset + contentH + FOOTER_H
    bagFrame:SetHeight(math.min(totalH, math.max(maxH, 200)))

    -- Update content frame width to match
    bagFrame._content:SetWidth(frameW)

    UpdateFooter()
end

-- =====================================
-- CREATE MAIN FRAME
-- =====================================

local function CreateBagFrame()
    if bagFrame then return bagFrame end

    local s = S()
    local HEADER_H = 32
    local SEARCH_H = 28

    local f = CreateFrame("Frame", "TomoMod_BagSkin_Main", UIParent)
    f:SetSize(500, 400)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)

    -- Position
    local pos = s.position
    if pos then
        f:SetPoint(pos.anchor or "BOTTOMRIGHT", UIParent, pos.relTo or "BOTTOMRIGHT", pos.x or -20, pos.y or 24)
    else
        f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 24)
    end

    f:SetScale((s.scale or 100) / 100)

    -- Background
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], (s.opacity or 92) / 100)
    f._bg = bg

    -- Border
    CreateBorders(f, BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], 0.6)

    -- Header
    local header = CreateFrame("Frame", nil, f)
    header:SetHeight(HEADER_H)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)

    local headerBg = header:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(HEADER_BG[1], HEADER_BG[2], HEADER_BG[3], 1)

    -- Header separator
    local headerSep = header:CreateTexture(nil, "ARTWORK")
    headerSep:SetHeight(1)
    headerSep:SetPoint("BOTTOMLEFT", 0, 0)
    headerSep:SetPoint("BOTTOMRIGHT", 0, 0)
    headerSep:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.30)

    -- Title
    local titleLbl = header:CreateFontString(nil, "OVERLAY")
    titleLbl:SetFont(ADDON_FONT_BOLD, 12, "")
    titleLbl:SetPoint("LEFT", 10, 0)
    titleLbl:SetText("|cff0cd29fBags|r")
    f._title = titleLbl

    -- Close button
    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(24, HEADER_H)
    closeBtn:SetPoint("RIGHT", -4, 0)
    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY")
    closeTxt:SetFont(ADDON_FONT_BOLD, 16, "")
    closeTxt:SetPoint("CENTER")
    closeTxt:SetText("×")
    closeTxt:SetTextColor(TAB_IDLE_TEXT[1], TAB_IDLE_TEXT[2], TAB_IDLE_TEXT[3], 1)
    closeBtn:SetScript("OnEnter", function()
        closeTxt:SetTextColor(0.90, 0.28, 0.28, 1)
    end)
    closeBtn:SetScript("OnLeave", function()
        closeTxt:SetTextColor(TAB_IDLE_TEXT[1], TAB_IDLE_TEXT[2], TAB_IDLE_TEXT[3], 1)
    end)
    closeBtn:SetScript("OnClick", function()
        f:Hide()
        if _G.CloseAllBags then CloseAllBags() end
    end)

    -- Sort button
    local sortBtn = CreateFrame("Button", nil, header, "BackdropTemplate")
    sortBtn:SetSize(50, 22)
    sortBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
    sortBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    sortBtn:SetBackdropColor(ACCENT[1] * 0.15, ACCENT[2] * 0.15, ACCENT[3] * 0.15, 0.8)
    sortBtn:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.4)
    local sortTxt = sortBtn:CreateFontString(nil, "OVERLAY")
    sortTxt:SetFont(ADDON_FONT, 10, "")
    sortTxt:SetPoint("CENTER")
    sortTxt:SetText("Sort")
    sortTxt:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
    sortBtn:SetScript("OnClick", function()
        C_Container.SortBags()
        C_Timer.After(0.5, LayoutGrid)
    end)
    sortBtn:SetScript("OnEnter", function()
        sortBtn:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
        sortTxt:SetTextColor(1, 1, 1, 1)
    end)
    sortBtn:SetScript("OnLeave", function()
        sortBtn:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.4)
        sortTxt:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
    end)

    -- Search bar (below header)
    local searchFrame = CreateFrame("Frame", nil, f)
    searchFrame:SetHeight(SEARCH_H)
    searchFrame:SetPoint("TOPLEFT", 0, -HEADER_H)
    searchFrame:SetPoint("TOPRIGHT", 0, -HEADER_H)
    f._searchFrame = searchFrame

    local searchBg = searchFrame:CreateTexture(nil, "BACKGROUND")
    searchBg:SetAllPoints()
    searchBg:SetColorTexture(SEARCH_BG[1], SEARCH_BG[2], SEARCH_BG[3], 0.9)

    local searchSep = searchFrame:CreateTexture(nil, "ARTWORK")
    searchSep:SetHeight(1)
    searchSep:SetPoint("BOTTOMLEFT", 0, 0)
    searchSep:SetPoint("BOTTOMRIGHT", 0, 0)
    searchSep:SetColorTexture(SEPARATOR[1], SEPARATOR[2], SEPARATOR[3], 1)

    local searchIcon = searchFrame:CreateFontString(nil, "OVERLAY")
    searchIcon:SetFont(ADDON_FONT, 13, "")
    searchIcon:SetPoint("LEFT", 8, 0)
    searchIcon:SetText("|TInterface\\Common\\UI-Searchbox-Icon:14:14|t")
    searchIcon:SetTextColor(TAB_IDLE_TEXT[1], TAB_IDLE_TEXT[2], TAB_IDLE_TEXT[3], 0.6)

    local searchEditBox = CreateFrame("EditBox", "TomoMod_BagSkin_Search", searchFrame)
    searchEditBox:SetPoint("LEFT", searchIcon, "RIGHT", 6, 0)
    searchEditBox:SetPoint("RIGHT", -8, 0)
    searchEditBox:SetHeight(SEARCH_H - 4)
    searchEditBox:SetFont(ADDON_FONT, 11, "")
    searchEditBox:SetTextColor(0.85, 0.85, 0.85, 1)
    searchEditBox:SetAutoFocus(false)
    searchEditBox:SetMaxLetters(50)
    searchEditBox:SetScript("OnTextChanged", function(self)
        currentFilter = (self:GetText() or ""):lower()
        LayoutGrid()
    end)
    searchEditBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
        currentFilter = ""
        LayoutGrid()
    end)
    searchBox = searchEditBox

    -- Content area (scrollable grid)
    local scrollFrame = CreateFrame("ScrollFrame", nil, f)
    local topOffset = HEADER_H + ((s.showSearchBar ~= false) and SEARCH_H or 0)
    scrollFrame:SetPoint("TOPLEFT", 0, -topOffset)
    scrollFrame:SetPoint("BOTTOMRIGHT", 0, FOOTER_H)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * 36, max)))
    end)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(scrollFrame:GetWidth() or 500)
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)
    f._content = content
    f._scrollFrame = scrollFrame

    -- Footer bar (gold + currencies)
    local footer = CreateFrame("Frame", nil, f)
    footer:SetHeight(FOOTER_H)
    footer:SetPoint("BOTTOMLEFT", 0, 0)
    footer:SetPoint("BOTTOMRIGHT", 0, 0)

    local footerBg = footer:CreateTexture(nil, "BACKGROUND")
    footerBg:SetAllPoints()
    footerBg:SetColorTexture(HEADER_BG[1], HEADER_BG[2], HEADER_BG[3], 1)

    local footerSep = footer:CreateTexture(nil, "ARTWORK")
    footerSep:SetHeight(1)
    footerSep:SetPoint("TOPLEFT", 0, 0)
    footerSep:SetPoint("TOPRIGHT", 0, 0)
    footerSep:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.20)

    local goldText = footer:CreateFontString(nil, "OVERLAY")
    goldText:SetFont(ADDON_FONT_BOLD, 11, "")
    goldText:SetPoint("LEFT", 10, 0)
    goldText:SetJustifyH("LEFT")
    f._goldText = goldText

    local currencyText = footer:CreateFontString(nil, "OVERLAY")
    currencyText:SetFont(ADDON_FONT, 10, "")
    currencyText:SetPoint("RIGHT", footer, "RIGHT", -10, 0)
    currencyText:SetJustifyH("RIGHT")
    currencyText:SetMaxLines(1)
    f._currencyText = currencyText

    f._footer = footer

    -- Drag handling
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local db = TomoModDB and TomoModDB.bagSkin
        if db then
            local point, _, relPoint, x, y = self:GetPoint(1)
            db.position = {
                anchor = point or "BOTTOMRIGHT",
                relTo  = relPoint or "BOTTOMRIGHT",
                x      = x or -20,
                y      = y or 24,
            }
        end
    end)

    -- Show/hide search bar based on setting
    if s.showSearchBar == false then
        searchFrame:Hide()
    end

    f:Hide()  -- start hidden; only show when player opens bags

    bagFrame = f
    return f
end

-- =====================================
-- SUPPRESS BLIZZARD BAG FRAMES
-- =====================================

local _suppressingBags = false

local function HideBlizzardBags()
    if _suppressingBags then return end
    _suppressingBags = true
    -- Hide the combined bag (retail ContainerFrameCombinedBags)
    if _G.ContainerFrameCombinedBags and _G.ContainerFrameCombinedBags:IsShown() then
        _G.ContainerFrameCombinedBags:Hide()
    end
    -- Hide all individual container frames
    for i = 1, 13 do
        local frame = _G["ContainerFrame" .. i]
        if frame and frame:IsShown() then
            frame:Hide()
        end
    end
    _suppressingBags = false
end

-- Hook :Show() on each Blizzard bag frame so they get immediately
-- re-hidden whenever Blizzard tries to display them (like MidnightUI does).
local _blizzardBagsHooked = false

local function HookBlizzardBagFrames()
    if _blizzardBagsHooked then return end
    _blizzardBagsHooked = true

    if _G.ContainerFrameCombinedBags then
        hooksecurefunc(_G.ContainerFrameCombinedBags, "Show", function(self)
            if not _suppressingBags and IsEnabled() then
                _suppressingBags = true
                self:Hide()
                _suppressingBags = false
            end
        end)
    end

    for i = 1, 13 do
        local cf = _G["ContainerFrame" .. i]
        if cf then
            hooksecurefunc(cf, "Show", function(self)
                if not _suppressingBags and IsEnabled() then
                    _suppressingBags = true
                    self:Hide()
                    _suppressingBags = false
                end
            end)
        end
    end

    -- BagsBar is the bag-slot icon row in the action bar area (not a bag window)
    -- — do NOT suppress it; the user needs it to open bags.
end

-- =====================================
-- HOOK BLIZZARD BAG OPEN/CLOSE
-- =====================================

local hooksInstalled = false
local hookHandledThisFrame = false

local function ShowCustomBags()
    if not IsEnabled() then return end
    if hookHandledThisFrame then return end
    hookHandledThisFrame = true
    C_Timer.After(0, function() hookHandledThisFrame = false end)

    HideBlizzardBags()
    if bagFrame then
        LayoutGrid()
        bagFrame:Show()
    end
end

local function ToggleCustomBags()
    if not IsEnabled() then return end
    if hookHandledThisFrame then return end
    hookHandledThisFrame = true
    C_Timer.After(0, function() hookHandledThisFrame = false end)

    HideBlizzardBags()
    if bagFrame then
        if bagFrame:IsShown() then
            bagFrame:Hide()
        else
            LayoutGrid()
            bagFrame:Show()
        end
    end
end

local function InstallBagHooks()
    if hooksInstalled then return end
    hooksInstalled = true

    -- Hook :Show() on all Blizzard bag frames so they can never appear
    HookBlizzardBagFrames()

    -- Blizzard's bag functions call each other in a chain
    -- (ToggleAllBags → ToggleBackpack → OpenBag×5)
    -- Only act on the FIRST hook in the chain, ignore the rest this frame.
    if _G.ToggleAllBags then
        hooksecurefunc("ToggleAllBags", ToggleCustomBags)
    end

    if _G.ToggleBackpack then
        hooksecurefunc("ToggleBackpack", ToggleCustomBags)
    end

    if _G.ToggleBag then
        hooksecurefunc("ToggleBag", function()
            ToggleCustomBags()
        end)
    end

    if _G.OpenAllBags then
        hooksecurefunc("OpenAllBags", ShowCustomBags)
    end

    if _G.OpenBackpack then
        hooksecurefunc("OpenBackpack", ShowCustomBags)
    end

    if _G.OpenBag then
        hooksecurefunc("OpenBag", function()
            ShowCustomBags()
        end)
    end

    if _G.CloseAllBags then
        hooksecurefunc("CloseAllBags", function()
            if bagFrame then bagFrame:Hide() end
        end)
    end

    if _G.CloseBackpack then
        hooksecurefunc("CloseBackpack", function()
            if not IsEnabled() then return end
            if bagFrame then bagFrame:Hide() end
        end)
    end

    -- Register for bag update events
    local events = CreateFrame("Frame")
    events:RegisterEvent("BAG_UPDATE")
    events:RegisterEvent("BAG_UPDATE_DELAYED")
    events:RegisterEvent("ITEM_LOCK_CHANGED")
    events:RegisterEvent("BAG_UPDATE_COOLDOWN")
    events:RegisterEvent("PLAYER_MONEY")
    events:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    events:SetScript("OnEvent", function(self, event)
        if not IsEnabled() then return end
        if event == "PLAYER_MONEY" or event == "CURRENCY_DISPLAY_UPDATE" then
            UpdateFooter()
            return
        end
        if bagFrame and bagFrame:IsShown() then
            C_Timer.After(0.1, LayoutGrid)
        end
    end)
end

-- =====================================
-- REGISTER WITH MOVERS
-- =====================================

local function RegisterWithMovers()
    if not TomoMod_Movers or not TomoMod_Movers.RegisterEntry then return end

    TomoMod_Movers.RegisterEntry({
        label = "Bag Skin",
        unlock = function()
            if bagFrame then
                bagFrame:SetMovable(true)
                bagFrame:EnableMouse(true)
            end
        end,
        lock = function()
            if bagFrame then
                local db = TomoModDB and TomoModDB.bagSkin
                if db then
                    local point, _, relPoint, x, y = bagFrame:GetPoint(1)
                    db.position = {
                        anchor = point or "BOTTOMRIGHT",
                        relTo  = relPoint or "BOTTOMRIGHT",
                        x      = x or -20,
                        y      = y or 24,
                    }
                end
            end
        end,
        isActive = function()
            return IsEnabled()
        end,
    })
end

-- =====================================
-- PUBLIC API
-- =====================================

function BS.ApplySettings()
    if not bagFrame then return end
    local s = S()

    bagFrame:SetScale((s.scale or 100) / 100)
    bagFrame._bg:SetColorTexture(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], (s.opacity or 92) / 100)

    -- Show/hide search bar
    if bagFrame._searchFrame then
        if s.showSearchBar ~= false then
            bagFrame._searchFrame:Show()
            bagFrame._scrollFrame:SetPoint("TOPLEFT", 0, -(32 + 28))
        else
            bagFrame._searchFrame:Hide()
            bagFrame._scrollFrame:SetPoint("TOPLEFT", 0, -32)
        end
    end

    LayoutGrid()
end

function BS.SetEnabled(enabled)
    local db = TomoModDB and TomoModDB.bagSkin
    if db then db.enabled = enabled end

    if enabled then
        if not bagFrame then CreateBagFrame() end
        InstallBagHooks()
    else
        if bagFrame then bagFrame:Hide() end
    end
end

function BS.Initialize()
    if isInitialized then return end
    isInitialized = true

    if not IsEnabled() then return end

    C_Timer.After(0.5, function()
        CreateBagFrame()
        InstallBagHooks()
        RegisterWithMovers()
        -- Don't auto-show; wait for player to open bags
    end)
end

-- =====================================
-- AUTO-INIT ON PLAYER_LOGIN
-- =====================================

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent("PLAYER_LOGIN")

    -- Ensure DB exists
    if TomoModDB and not TomoModDB.bagSkin then
        TomoModDB.bagSkin = {
            enabled = false,
            unified = true,
            columns = 12,
            slotSize = 36,
            slotSpacing = 3,
            scale = 100,
            opacity = 92,
            showQualityBorders = true,
            showCooldowns = true,
            showQuantityBadges = true,
            showSearchBar = true,
            sortMode = "quality",
            showGold = true,
            showCurrencies = false,
            position = { anchor = "BOTTOMRIGHT", relTo = "BOTTOMRIGHT", x = -20, y = 24 },
        }
    end

    BS.Initialize()
    RegisterWithMovers()
end)

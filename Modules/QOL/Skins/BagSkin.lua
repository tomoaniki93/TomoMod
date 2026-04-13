-- =====================================
-- BagSkin.lua (v4 — GW2_UI-inspired)
-- Combined resizable bag frame with custom slots,
-- quality borders, ilvl badges, junk icons, bag bar,
-- search, sort, categories/separate bags, money & currencies.
-- Built on GW2_UI inventory architecture + TomoMod dark theme.
-- =====================================

TomoMod_BagSkin = TomoMod_BagSkin or {}
local BS = TomoMod_BagSkin

-- =====================================
-- CONSTANTS
-- =====================================

local ADDON_PATH       = "Interface\\AddOns\\TomoMod\\"
local ADDON_FONT       = ADDON_PATH .. "Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD  = ADDON_PATH .. "Assets\\Fonts\\Poppins-SemiBold.ttf"
local L = TomoMod_L

-- Theme
local ACCENT          = { 0.047, 0.824, 0.624 }
local BG_COLOR        = { 0.045, 0.045, 0.060 }
local HEADER_BG       = { 0.065, 0.065, 0.082 }
local BORDER_COLOR    = { 0.18,  0.18,  0.22 }
local SLOT_BG         = { 0.07,  0.07,  0.09 }
local SLOT_BORDER     = { 0.22,  0.22,  0.28 }
local SEPARATOR       = { 0.14,  0.14,  0.17 }
local MUTED_TEXT      = { 0.48,  0.48,  0.54 }
local SEARCH_BG       = { 0.055, 0.055, 0.072 }
local SECTION_BG      = { 0.055, 0.055, 0.070 }
local SECTION_HDR_BG  = { 0.075, 0.075, 0.095 }
local FOOTER_H        = 28
local HEADER_H        = 36
local SEARCH_H        = 28
local SECTION_HDR_H   = 22
local SECTION_PAD     = 6
local SECTION_GAP     = 4
local BAGBAR_W        = 40
local SIDE_PAD        = 5
local MIN_WIDTH       = 320
local MIN_HEIGHT      = 280

local QUALITY_COLORS = {
    [0] = { 0.62, 0.62, 0.62 }, [1] = { 1.00, 1.00, 1.00 },
    [2] = { 0.12, 1.00, 0.00 }, [3] = { 0.00, 0.44, 0.87 },
    [4] = { 0.64, 0.21, 0.93 }, [5] = { 1.00, 0.50, 0.00 },
    [6] = { 0.90, 0.80, 0.50 }, [7] = { 0.00, 0.80, 1.00 },
    [8] = { 0.00, 0.80, 1.00 },
}

local CRAFTING_QUALITY_ATLAS = {
    [1] = "UI-TradeSkill-Quality-Tier1-Icon",
    [2] = "UI-TradeSkill-Quality-Tier2-Icon",
    [3] = "UI-TradeSkill-Quality-Tier3-Icon",
    [4] = "UI-TradeSkill-Quality-Tier4-Icon",
    [5] = "UI-TradeSkill-Quality-Tier5-Icon",
}

local SORT_FUNCS = {
    quality = function(a, b)
        if a.quality ~= b.quality then return (a.quality or 0) > (b.quality or 0) end
        return (a.name or "") < (b.name or "")
    end,
    name    = function(a, b) return (a.name or "") < (b.name or "") end,
    type    = function(a, b)
        if a.subType ~= b.subType then return (a.subType or "") < (b.subType or "") end
        return (a.name or "") < (b.name or "")
    end,
    ilvl    = function(a, b)
        if (a.ilvl or 0) ~= (b.ilvl or 0) then return (a.ilvl or 0) > (b.ilvl or 0) end
        return (a.name or "") < (b.name or "")
    end,
    recent  = function(a, b) return (a.bagID or 0) < (b.bagID or 0) end,
    none    = nil, -- nil = no sorting, keeps natural bag/slot order
}

-- =====================================
-- CATEGORY DEFINITIONS (layout = "categories")
-- =====================================

local REAGENT_BAG_ID = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag

local CATEGORIES = {
    { key="recentItems",  nameKey="bagskin_cat_recent",     fallback="Recent Items",        priority=1,   color={0.30,0.85,1.00},
      match=function(i) return i.hasItem and C_NewItems and C_NewItems.IsNewItem(i.bagID,i.slotIndex) end },
    { key="equipment",    nameKey="bagskin_cat_equipment",   fallback="Equipment",           priority=2,   color={0.90,0.70,0.30}, defaultSort="ilvl",
      match=function(i) return i.hasItem and (i.classID==2 or i.classID==4) end },
    { key="consumables",  nameKey="bagskin_cat_consumables", fallback="Consumables",         priority=3,   color={0.40,0.90,0.40},
      match=function(i) return i.hasItem and i.classID==0 end },
    { key="questItems",   nameKey="bagskin_cat_quest",       fallback="Quest Items",         priority=4,   color={1.00,0.80,0.20},
      match=function(i) return i.hasItem and i.classID==12 end },
    { key="tradeGoods",   nameKey="bagskin_cat_tradegoods",  fallback="Trade Goods",         priority=5,   color={0.70,0.55,0.35},
      match=function(i) return i.hasItem and i.classID==7 end },
    { key="reagents",     nameKey="bagskin_cat_reagents",    fallback="Reagents",            priority=6,   color={0.55,0.75,0.90},
      match=function(i) if not i.hasItem then return false end; if REAGENT_BAG_ID and i.bagID==REAGENT_BAG_ID then return true end; return i.classID==5 end },
    { key="gemsEnchants", nameKey="bagskin_cat_gems",        fallback="Gems & Enhancements", priority=7,   color={0.80,0.40,0.90},
      match=function(i) return i.hasItem and (i.classID==3 or i.classID==8) end },
    { key="recipes",      nameKey="bagskin_cat_recipes",     fallback="Recipes",             priority=8,   color={0.85,0.65,0.35},
      match=function(i) return i.hasItem and i.classID==9 end },
    { key="battlePets",   nameKey="bagskin_cat_pets",        fallback="Battle Pets",         priority=9,   color={0.50,0.80,0.95},
      match=function(i) return i.hasItem and i.classID==17 end },
    { key="junk",         nameKey="bagskin_cat_junk",        fallback="Junk",                priority=10,  color={0.62,0.62,0.62},
      match=function(i) return i.hasItem and (i.quality or 0)==0 end },
    { key="miscellaneous",nameKey="bagskin_cat_misc",        fallback="Miscellaneous",       priority=11,  color={0.60,0.60,0.70},
      match=function(i) return i.hasItem end },
    { key="freeSlots",    nameKey="bagskin_cat_free",        fallback="Free Slots",          priority=100, color={0.35,0.35,0.42},
      match=function(i) return not i.hasItem end },
}

-- =====================================
-- STATE
-- =====================================

local isInitialized   = false
local bagFrame        = nil
local slotButtons     = {}
local sectionFrames   = {}
local currentFilter   = ""
local tomoButtonCount = 0
local _layoutPending  = false

local BAG_IDS = { 0, 1, 2, 3, 4 }
if REAGENT_BAG_ID then BAG_IDS[#BAG_IDS+1] = REAGENT_BAG_ID end

-- =====================================
-- SETTINGS HELPER
-- =====================================

local function S()
    return TomoModDB and TomoModDB.bagSkin or {}
end

local function IsEnabled()
    return S().enabled
end

-- =====================================
-- HELPERS
-- =====================================

local function CreateBorders(parent, r, g, b, a, layer)
    local borders = {}
    for _, info in ipairs({
        {"TOPLEFT","TOPLEFT","TOPRIGHT","TOPRIGHT", nil, 1},
        {"BOTTOMLEFT","BOTTOMLEFT","BOTTOMRIGHT","BOTTOMRIGHT", nil, 1},
        {"TOPLEFT","TOPLEFT","BOTTOMLEFT","BOTTOMLEFT", 1, nil},
        {"TOPRIGHT","TOPRIGHT","BOTTOMRIGHT","BOTTOMRIGHT", 1, nil},
    }) do
        local t = parent:CreateTexture(nil, layer or "BORDER")
        t:SetColorTexture(r, g, b, a or 1)
        t:SetPoint(info[1], parent, info[2])
        t:SetPoint(info[3], parent, info[4])
        if info[5] then t:SetWidth(info[5]) end
        if info[6] then t:SetHeight(info[6]) end
        borders[#borders+1] = t
    end
    return borders
end

local function ColCount(slotSize, spacingX, frameWidth)
    local isize = slotSize + spacingX
    return math.max(1, math.floor((frameWidth - SIDE_PAD * 2 + spacingX) / isize))
end

local function FormatGold(money)
    if not money or money <= 0 then return "|cff666677---|r" end
    return GetCoinTextureString(money)
end

-- =====================================
-- ITEM INFO CACHE
-- =====================================

local _itemCache = {}
local _itemCacheTime = 0

local function GetItemExtras(itemID, bagID, slotIndex, classID)
    local key = itemID .. ":" .. bagID .. ":" .. slotIndex
    local now = GetTime()
    if (now - _itemCacheTime) > 10 then wipe(_itemCache); _itemCacheTime = now end
    if _itemCache[key] then return _itemCache[key].ilvl, _itemCache[key].cq end

    local ilvl, cq
    if classID == 2 or classID == 4 then
        local ok, loc = pcall(ItemLocation.CreateFromBagAndSlot, ItemLocation, bagID, slotIndex)
        if ok and loc and loc:IsValid() then
            local lOk, lv = pcall(C_Item.GetCurrentItemLevel, loc)
            if lOk and lv and lv > 0 then ilvl = lv end
        end
    end
    if classID == 7 and C_TradeSkillUI and C_TradeSkillUI.GetItemReagentQualityByItemInfo then
        local link = C_Container.GetContainerItemLink(bagID, slotIndex)
        if link then
            local qOk, q = pcall(C_TradeSkillUI.GetItemReagentQualityByItemInfo, link)
            if qOk then cq = q end
        end
    end

    _itemCache[key] = { ilvl = ilvl, cq = cq }
    return ilvl, cq
end

-- =====================================
-- COLLECT ALL ITEMS
-- =====================================

local function CollectItems()
    local items = {}
    for _, bagID in ipairs(BAG_IDS) do
        local numSlots = C_Container.GetContainerNumSlots(bagID)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bagID, slot)
            local entry = {
                bagID     = bagID,
                slotIndex = slot,
                hasItem   = info ~= nil,
                itemID    = info and info.itemID,
                name      = info and info.itemName or "",
                quality   = info and info.quality or 0,
                icon      = info and info.iconFileID,
                count     = info and info.stackCount or 0,
                locked    = info and info.isLocked,
                classID   = nil,
                subType   = "",
                ilvl      = nil,
                craftingQuality = nil,
            }
            if entry.itemID then
                local _, _, _, _, _, cid, scid = C_Item.GetItemInfoInstant(entry.itemID)
                entry.classID = cid
                entry.subType = scid or ""
                entry.ilvl, entry.craftingQuality = GetItemExtras(entry.itemID, bagID, slot, cid)
            end
            items[#items+1] = entry
        end
    end
    return items
end

-- =====================================
-- CATEGORIZE ITEMS
-- =====================================

local function Categorize(items)
    local cats = {}
    for _, cat in ipairs(CATEGORIES) do cats[cat.key] = {} end

    for _, item in ipairs(items) do
        for _, cat in ipairs(CATEGORIES) do
            if cat.match(item) then
                cats[cat.key][#cats[cat.key]+1] = item
                break
            end
        end
    end
    return cats
end

-- =====================================
-- STACK MERGING (optional)
-- =====================================

local function MergeStacks(items)
    local merged, seen = {}, {}
    for _, item in ipairs(items) do
        if not item.hasItem then
            local fk = "free_" .. item.bagID
            if seen[fk] then
                merged[seen[fk]].count = merged[seen[fk]].count + 1
            else
                local c = {}; for k,v in pairs(item) do c[k]=v end
                c.count = 1; c._isFreeSlot = true
                merged[#merged+1] = c; seen[fk] = #merged
            end
        elseif item.itemID and seen[item.itemID] then
            merged[seen[item.itemID]].count = merged[seen[item.itemID]].count + (item.count > 0 and item.count or 1)
            merged[seen[item.itemID]]._mergedSlots = merged[seen[item.itemID]]._mergedSlots or {{ merged[seen[item.itemID]].bagID, merged[seen[item.itemID]].slotIndex }}
            merged[seen[item.itemID]]._mergedSlots[#merged[seen[item.itemID]]._mergedSlots+1] = { item.bagID, item.slotIndex }
        else
            local c = {}; for k,v in pairs(item) do c[k]=v end
            merged[#merged+1] = c
            if item.itemID then seen[item.itemID] = #merged end
        end
    end
    return merged
end

-- =====================================
-- SLOT BUTTON POOL
-- =====================================

local function CreateSlotButton(parent, size)
    tomoButtonCount = tomoButtonCount + 1
    local btnName = "TomoModBagBtn" .. tomoButtonCount

    local wrapper = CreateFrame("Frame", nil, parent)
    wrapper:SetSize(size, size)
    wrapper:EnableMouse(true)

    local btn = CreateFrame("Button", btnName, wrapper, "SecureActionButtonTemplate")
    btn:SetAllPoints(wrapper)
    wrapper.btn = btn
    btn:EnableMouseWheel(false)

    -- Backdrop
    local bg = btn:CreateTexture(nil, "BACKGROUND", nil, 2)
    bg:SetAllPoints()
    bg:SetColorTexture(SLOT_BG[1], SLOT_BG[2], SLOT_BG[3], 1)
    btn._bg = bg

    -- Icon
    local icon = btn:CreateTexture(nil, "ARTWORK", nil, 1)
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:Hide()
    btn._icon = icon
    btn.icon  = icon

    -- Quality border
    btn._qualBorders = CreateBorders(btn, SLOT_BORDER[1], SLOT_BORDER[2], SLOT_BORDER[3], 0.6, "OVERLAY")

    -- Cooldown
    local cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    cd:SetAllPoints(icon)
    cd:SetDrawEdge(false)
    cd:SetHideCountdownNumbers(false)
    cd:EnableMouse(false)
    btn._cooldown = cd

    -- Count text
    local qty = btn:CreateFontString(nil, "OVERLAY")
    qty:SetFont(ADDON_FONT_BOLD, 10, "OUTLINE")
    qty:SetPoint("BOTTOMRIGHT", -2, 2)
    qty:SetTextColor(1, 1, 1, 1)
    btn._qtyText = qty

    -- Crafting quality icon
    local qualIcon = btn:CreateTexture(nil, "OVERLAY", nil, 2)
    qualIcon:SetSize(14, 14)
    qualIcon:SetPoint("TOPLEFT", 2, -2)
    qualIcon:Hide()
    btn._qualIcon = qualIcon

    -- Item level badge
    local ilvlBadge = btn:CreateFontString(nil, "OVERLAY")
    ilvlBadge:SetFont(ADDON_FONT_BOLD, 8, "OUTLINE")
    ilvlBadge:SetPoint("BOTTOMLEFT", 2, 2)
    ilvlBadge:SetTextColor(1, 0.82, 0.0, 1)
    ilvlBadge:Hide()
    btn._ilvlBadge = ilvlBadge

    -- Junk icon
    local junkIcon = btn:CreateTexture(nil, "OVERLAY", nil, 2)
    junkIcon:SetAtlas("bags-junkcoin", true)
    junkIcon:SetPoint("TOPLEFT", -3, 3)
    junkIcon:Hide()
    btn._junkIcon = junkIcon

    -- Highlight
    local high = btn:CreateTexture(nil, "HIGHLIGHT")
    high:SetAllPoints()
    high:SetColorTexture(1, 1, 1, 0.12)
    high:SetBlendMode("ADD")

    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:RegisterForDrag("LeftButton")

    -- Tooltip (like GW2_UI — native SetBagItem)
    btn:SetScript("OnEnter", function(self)
        if self.bag and self:GetID() > 0 then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetBagItem(self.bag, self:GetID())
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Click handling: PreClick intercepts special cases, otherwise secure macro handles it
    btn:SetScript("PreClick", function(self, button, down)
        if not self.bag or self:GetID() == 0 then return end
        if down then return end
        local bagID, slotID = self.bag, self:GetID()
        if button == "LeftButton" then
            local cursorType = GetCursorInfo()
            -- If cursor already holds an item, place/swap it here
            if cursorType == "item" then
                C_Container.PickupContainerItem(bagID, slotID)
                self:SetAttribute("type1", nil)
                return
            end
            if IsModifiedClick("CHATLINK") then
                local link = C_Container.GetContainerItemLink(bagID, slotID)
                if link then ChatEdit_InsertLink(link) end
                self:SetAttribute("type1", nil)
            elseif IsModifiedClick("SPLITSTACK") then
                local info = C_Container.GetContainerItemInfo(bagID, slotID)
                if info and (info.stackCount or 0) > 1 then
                    self.SplitStack = function(_, amount)
                        C_Container.SplitContainerItem(bagID, slotID, amount)
                    end
                    OpenStackSplitFrame(info.stackCount, self, "BOTTOMLEFT", "TOPLEFT")
                end
                self:SetAttribute("type1", nil)
            elseif SpellIsTargeting() then
                -- Spell on cursor (Disenchant, Milling, Prospecting) → secure /use
                self:SetAttribute("type1", "macro")
                self:SetAttribute("macrotext1", "/use " .. bagID .. " " .. slotID)
            else
                -- Normal click → pick up item for moving
                C_Container.PickupContainerItem(bagID, slotID)
                self:SetAttribute("type1", nil)
            end
        end
    end)

    btn:SetScript("OnDragStart", function(self)
        if self.bag and self:GetID() > 0 then
            C_Container.PickupContainerItem(self.bag, self:GetID())
        end
    end)

    btn:SetScript("OnReceiveDrag", function(self)
        if self.bag and self:GetID() > 0 then
            C_Container.PickupContainerItem(self.bag, self:GetID())
        end
    end)

    return wrapper
end

-- Slot pool management
local slotPoolIdx = 0

local function AcquireSlot(parent, size)
    slotPoolIdx = slotPoolIdx + 1
    if slotPoolIdx <= #slotButtons then
        local w = slotButtons[slotPoolIdx]
        w:SetParent(parent)
        w:SetSize(size, size)
        w:Show()
        w.btn._qtyText:SetTextColor(1, 1, 1, 1)
        return w
    end
    local w = CreateSlotButton(parent, size)
    slotButtons[#slotButtons+1] = w
    return w
end

local function ResetSlotPool() slotPoolIdx = 0 end

local function HideUnusedSlots()
    for i = slotPoolIdx+1, #slotButtons do slotButtons[i]:Hide() end
end

-- =====================================
-- SET QUALITY BORDER
-- =====================================

local function SetQualityBorder(btn, quality)
    local s = S()
    if not s.showQualityBorders then
        for _, t in ipairs(btn._qualBorders) do
            t:SetColorTexture(SLOT_BORDER[1], SLOT_BORDER[2], SLOT_BORDER[3], 0.4)
        end
        return
    end
    local c = QUALITY_COLORS[quality or 0] or QUALITY_COLORS[1]
    local a = (quality and quality >= 2) and 0.8 or 0.3
    for _, t in ipairs(btn._qualBorders) do t:SetColorTexture(c[1], c[2], c[3], a) end
end

-- =====================================
-- UPDATE SLOT BUTTON (item data → visual)
-- =====================================

local function UpdateSlot(wrapper, item)
    if not wrapper then return end
    local btn = wrapper.btn
    if not btn then return end
    local s = S()

    btn:Show()
    wrapper:SetID(item.bagID)
    btn:SetID(item.slotIndex)
    btn.bag = item.bagID

    -- Secure right-click use (like GW2_UI macro approach)
    if not InCombatLockdown() then
        btn:SetAttribute("type2", "macro")
        btn:SetAttribute("macrotext2", "/use " .. item.bagID .. " " .. item.slotIndex)
    end

    if item.hasItem and item.icon then
        btn._icon:SetTexture(item.icon)
        btn._icon:Show()
        SetQualityBorder(btn, item.quality)

        -- Quantity
        if s.showQuantityBadges and item.count > 1 then
            btn._qtyText:SetText(tostring(item.count))
            btn._qtyText:Show()
        else
            btn._qtyText:Hide()
        end

        -- Cooldown
        if s.showCooldowns and btn._cooldown then
            local start, dur, en = C_Container.GetContainerItemCooldown(item.bagID, item.slotIndex)
            if start and dur and dur > 0 and en == 1 then
                btn._cooldown:SetCooldown(start, dur)
                btn._cooldown:Show()
            else
                btn._cooldown:Hide()
            end
        elseif btn._cooldown then
            btn._cooldown:Hide()
        end

        -- Search filter / locked
        local desat, alpha = false, 1
        if item.locked then desat, alpha = true, 0.4
        elseif currentFilter ~= "" then
            local m = (item.name or ""):lower():find(currentFilter, 1, true)
            desat = not m; alpha = m and 1 or 0.3
        end
        btn._icon:SetDesaturated(desat)
        btn._icon:SetAlpha(alpha)

        -- Item level (GW2_UI-inspired)
        if s.showItemLevel and btn._ilvlBadge then
            if item.ilvl and (item.classID == 2 or item.classID == 4) then
                btn._ilvlBadge:SetText(tostring(item.ilvl))
                btn._ilvlBadge:Show()
            else btn._ilvlBadge:Hide() end
        elseif btn._ilvlBadge then btn._ilvlBadge:Hide() end

        -- Junk icon (GW2_UI-inspired)
        if s.showJunkIcon and btn._junkIcon then
            btn._junkIcon:SetShown((item.quality or 0) == 0 and item.hasItem)
        elseif btn._junkIcon then btn._junkIcon:Hide() end

        -- Crafting quality
        if btn._qualIcon then
            local atlas = item.craftingQuality and CRAFTING_QUALITY_ATLAS[item.craftingQuality]
            if atlas then btn._qualIcon:SetAtlas(atlas, false); btn._qualIcon:SetSize(14,14); btn._qualIcon:Show()
            else btn._qualIcon:Hide() end
        end
    else
        -- Empty slot
        btn._icon:SetTexture(nil); btn._icon:Hide()
        btn._qtyText:Hide()
        if btn._cooldown then btn._cooldown:Hide() end
        if btn._ilvlBadge then btn._ilvlBadge:Hide() end
        if btn._qualIcon then btn._qualIcon:Hide() end
        if btn._junkIcon then btn._junkIcon:Hide() end
        btn._icon:SetDesaturated(false)

        -- Free slot count
        if item._isFreeSlot and item.count > 1 then
            btn._qtyText:SetText(tostring(item.count))
            btn._qtyText:SetTextColor(MUTED_TEXT[1], MUTED_TEXT[2], MUTED_TEXT[3])
            btn._qtyText:Show()
        end

        for _, t in ipairs(btn._qualBorders) do
            t:SetColorTexture(SLOT_BORDER[1], SLOT_BORDER[2], SLOT_BORDER[3], 0.2)
        end
    end
end

-- =====================================
-- SECTION FRAME (categories / separate bags)
-- =====================================

local function CreateSectionFrame(parent, key, col, fallback)
    local section = CreateFrame("Frame", nil, parent)
    section:SetWidth(parent:GetWidth() or 400)

    local bg = section:CreateTexture(nil, "BACKGROUND", nil, 0)
    bg:SetAllPoints()
    bg:SetColorTexture(SECTION_BG[1], SECTION_BG[2], SECTION_BG[3], 0.4)

    CreateBorders(section, BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], 0.3)

    -- Header
    local hdr = CreateFrame("Button", nil, section)
    hdr:SetHeight(SECTION_HDR_H)
    hdr:SetPoint("TOPLEFT", 0, 0)
    hdr:SetPoint("TOPRIGHT", 0, 0)
    section._header = hdr

    local hdrBg = hdr:CreateTexture(nil, "BACKGROUND", nil, 1)
    hdrBg:SetAllPoints()
    hdrBg:SetColorTexture(SECTION_HDR_BG[1], SECTION_HDR_BG[2], SECTION_HDR_BG[3], 0.6)
    section._hdrBg = hdrBg

    -- Accent bar
    local accentBar = hdr:CreateTexture(nil, "ARTWORK", nil, 2)
    accentBar:SetWidth(3)
    accentBar:SetPoint("TOPLEFT", 0, 0)
    accentBar:SetPoint("BOTTOMLEFT", 0, 0)
    accentBar:SetColorTexture(col[1], col[2], col[3], 0.9)

    -- Arrow
    local arrow = hdr:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(ADDON_FONT, 10, "")
    arrow:SetPoint("LEFT", 8, 0)
    arrow:SetTextColor(MUTED_TEXT[1], MUTED_TEXT[2], MUTED_TEXT[3], 0.8)
    section._arrow = arrow

    -- Title
    local title = hdr:CreateFontString(nil, "OVERLAY")
    title:SetFont(ADDON_FONT_BOLD, 10, "")
    title:SetPoint("LEFT", arrow, "RIGHT", 4, 0)
    title:SetTextColor(col[1], col[2], col[3], 1)
    section._title = title

    -- Count
    local cnt = hdr:CreateFontString(nil, "OVERLAY")
    cnt:SetFont(ADDON_FONT, 9, "")
    cnt:SetPoint("LEFT", title, "RIGHT", 6, 0)
    cnt:SetTextColor(MUTED_TEXT[1], MUTED_TEXT[2], MUTED_TEXT[3], 0.8)
    section._countBadge = cnt

    -- Separator
    local sep = hdr:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1); sep:SetPoint("BOTTOMLEFT", 0, 0); sep:SetPoint("BOTTOMRIGHT", 0, 0)
    sep:SetColorTexture(SEPARATOR[1], SEPARATOR[2], SEPARATOR[3], 0.4)

    -- Grid area
    local grid = CreateFrame("Frame", nil, section)
    grid:SetPoint("TOPLEFT", 0, -SECTION_HDR_H)
    grid:SetPoint("TOPRIGHT", 0, -SECTION_HDR_H)
    grid:SetHeight(1)
    section._grid = grid

    -- Collapse click
    hdr:SetScript("OnClick", function()
        local db = TomoModDB and TomoModDB.bagSkin
        if not db then return end
        db.collapsedSections = db.collapsedSections or {}
        db.collapsedSections[key] = not db.collapsedSections[key]
        BS._LayoutGrid()
    end)

    hdr:SetScript("OnEnter", function()
        hdrBg:SetColorTexture(SECTION_HDR_BG[1]+0.03, SECTION_HDR_BG[2]+0.03, SECTION_HDR_BG[3]+0.03, 0.8)
    end)
    hdr:SetScript("OnLeave", function()
        hdrBg:SetColorTexture(SECTION_HDR_BG[1], SECTION_HDR_BG[2], SECTION_HDR_BG[3], 0.6)
    end)

    section._catKey = key
    return section
end

local function GetSection(content, key, col, fallback)
    if sectionFrames[key] then return sectionFrames[key] end
    local sec = CreateSectionFrame(content, key, col, fallback)
    sectionFrames[key] = sec
    return sec
end

-- =====================================
-- UPDATE FREE SLOTS (GW2_UI-style)
-- =====================================

local function UpdateFreeSlots()
    if not bagFrame or not bagFrame._spaceStr then return end
    local free, full = 0, 0
    for _, bagID in ipairs(BAG_IDS) do
        free = free + C_Container.GetContainerNumFreeSlots(bagID)
        full = full + C_Container.GetContainerNumSlots(bagID)
    end
    bagFrame._spaceStr:SetText((full - free) .. " / " .. full)
end

-- =====================================
-- UPDATE FOOTER (gold + currencies)
-- =====================================

local function UpdateFooter()
    if not bagFrame or not bagFrame._footer then return end
    local s = S()

    if s.showGold ~= false then
        bagFrame._goldText:SetText(FormatGold(GetMoney()))
        bagFrame._goldText:Show()
    else
        bagFrame._goldText:Hide()
    end

    if s.showCurrencies then
        local count = (C_CurrencyInfo and C_CurrencyInfo.GetNumTrackedCurrencies and C_CurrencyInfo.GetNumTrackedCurrencies()) or 0
        -- Hide all existing currency frames first
        for _, cf in ipairs(bagFrame._currencyFrames) do
            cf:Hide()
        end
        if count == 0 then
            bagFrame._currencyNoneText:SetText("|cff555566" .. (L and L["bagskin_currencies_none"] or "No tracked currencies") .. "|r")
            bagFrame._currencyNoneText:Show()
            bagFrame._currencyContainer:Hide()
        else
            bagFrame._currencyNoneText:Hide()
            bagFrame._currencyContainer:Show()
            local anchor = nil
            local shown = 0
            for i = 1, math.min(count, 7) do
                local ci = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
                if ci and ci.quantity ~= nil then
                    shown = shown + 1
                    local cf = bagFrame._currencyFrames[shown]
                    if not cf then
                        cf = CreateFrame("Frame", nil, bagFrame._currencyContainer)
                        cf:SetHeight(18)
                        cf:EnableMouse(true)
                        local icon = cf:CreateTexture(nil, "ARTWORK")
                        icon:SetSize(14, 14)
                        icon:SetPoint("LEFT", 0, 0)
                        cf._icon = icon
                        local text = cf:CreateFontString(nil, "OVERLAY")
                        text:SetFont(ADDON_FONT, 10, "")
                        text:SetPoint("LEFT", icon, "RIGHT", 3, 0)
                        cf._text = text
                        cf:SetScript("OnEnter", function(self)
                            GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 5)
                            if self._currencyID then
                                GameTooltip:SetCurrencyByID(self._currencyID)
                            end
                            GameTooltip:Show()
                        end)
                        cf:SetScript("OnLeave", function()
                            GameTooltip:Hide()
                        end)
                        bagFrame._currencyFrames[shown] = cf
                    end
                    cf._currencyID = ci.currencyTypesID
                    cf._icon:SetTexture(ci.iconFileID)
                    local qty = ci.quantity >= 10000
                        and string.format("%d,%03d", math.floor(ci.quantity/1000), ci.quantity%1000)
                        or tostring(ci.quantity)
                    cf._text:SetText("|cffdddddd" .. qty .. "|r")
                    cf:ClearAllPoints()
                    if anchor then
                        cf:SetPoint("RIGHT", anchor, "LEFT", -8, 0)
                    else
                        cf:SetPoint("RIGHT", bagFrame._currencyContainer, "RIGHT", 0, 0)
                    end
                    cf:SetWidth(cf._text:GetStringWidth() + 14 + 3)
                    cf:Show()
                    anchor = cf
                end
            end
        end
    else
        bagFrame._currencyNoneText:Hide()
        bagFrame._currencyContainer:Hide()
        for _, cf in ipairs(bagFrame._currencyFrames) do
            cf:Hide()
        end
    end
end

-- =====================================
-- LAYOUT: MAIN GRID
-- =====================================

local function LayoutGrid()
    if not bagFrame then return end
    local s = S()

    local slotSize   = s.slotSize or 40
    local spacingX   = s.slotSpacingX or 5
    local spacingY   = s.slotSpacingY or 5
    local sortMode   = s.sortMode or "quality"
    local doMerge    = s.stackMerge or false
    local showEmpty  = s.showEmptySlots ~= false
    local showRecent = s.showRecentItems ~= false
    local showBagBar = s.showBagBar ~= false
    local layoutMode = s.layoutMode or "combined"

    local content  = bagFrame._content
    local barOfs   = showBagBar and BAGBAR_W or 0
    local frameW   = bagFrame:GetWidth()
    local contentW = frameW - barOfs
    local columns  = ColCount(slotSize, spacingX, contentW)

    content:SetWidth(contentW)
    content:ClearAllPoints()
    content:SetPoint("TOPLEFT", bagFrame._scrollFrame, "TOPLEFT", 0, 0)
    content:SetPoint("TOPRIGHT", bagFrame._scrollFrame, "TOPRIGHT", 0, 0)

    -- Collect items
    local allItems = CollectItems()

    ResetSlotPool()

    -- ===== LAYOUT: COMBINED =====
    if layoutMode == "combined" then
        -- Hide all section frames
        for _, sec in pairs(sectionFrames) do sec:Hide() end

        -- Sort
        local display = {}
        if sortMode == "none" then
            -- Manual mode: keep natural bag/slot order, don't separate filled/empty
            for _, item in ipairs(allItems) do
                if item.hasItem or showEmpty then
                    display[#display+1] = item
                end
            end
        else
            local filled, empty = {}, {}
            for _, item in ipairs(allItems) do
                if item.hasItem then filled[#filled+1] = item
                else empty[#empty+1] = item end
            end
            local fn = SORT_FUNCS[sortMode]
            if fn then table.sort(filled, fn) end

            -- Reverse bag order
            if s.reverseBagOrder then
                for i = #filled, 1, -1 do display[#display+1] = filled[i] end
            else
                for _, item in ipairs(filled) do display[#display+1] = item end
            end
            if showEmpty then
                if doMerge then
                    local merged = MergeStacks(empty)
                    for _, item in ipairs(merged) do display[#display+1] = item end
                else
                    for _, item in ipairs(empty) do display[#display+1] = item end
                end
            end
        end

        -- Apply search filter
        if currentFilter ~= "" then
            local filtered = {}
            for _, item in ipairs(display) do
                if not item.hasItem or (item.name or ""):lower():find(currentFilter, 1, true) then
                    filtered[#filtered+1] = item
                end
            end
            display = filtered
        end

        -- Position in grid
        local gx, gy = SIDE_PAD, -SIDE_PAD
        local col = 0
        for _, item in ipairs(display) do
            local w = AcquireSlot(content, slotSize)
            w:ClearAllPoints()
            w:SetPoint("TOPLEFT", content, "TOPLEFT", gx, gy)
            UpdateSlot(w, item)
            col = col + 1
            if col >= columns then
                col = 0; gx = SIDE_PAD; gy = gy - slotSize - spacingY
            else
                gx = gx + slotSize + spacingX
            end
        end
        if col > 0 then gy = gy - slotSize - spacingY end
        content:SetHeight(math.abs(gy) + SIDE_PAD)

    -- ===== LAYOUT: CATEGORIES =====
    elseif layoutMode == "categories" then
        local cats = Categorize(allItems)
        local collapsedDB = s.collapsedSections or {}
        local y = 0

        for _, catDef in ipairs(CATEGORIES) do
            local items = cats[catDef.key]
            if not items or #items == 0 then
                if sectionFrames[catDef.key] then sectionFrames[catDef.key]:Hide() end
            elseif catDef.key == "recentItems" and not showRecent then
                if sectionFrames[catDef.key] then sectionFrames[catDef.key]:Hide() end
            elseif catDef.key == "freeSlots" and not showEmpty then
                if sectionFrames[catDef.key] then sectionFrames[catDef.key]:Hide() end
            else
                local section = GetSection(content, catDef.key, catDef.color, catDef.fallback)
                section:SetWidth(contentW)
                local collapsed = collapsedDB[catDef.key] or false
                local catName = (L and L[catDef.nameKey]) or catDef.fallback

                section._arrow:SetText(collapsed and ">" or "v")
                section._title:SetText(catName)
                section._countBadge:SetText("(" .. #items .. ")")

                if y > 0 then y = y + SECTION_GAP end
                section:ClearAllPoints()
                section:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)

                if collapsed then
                    section._grid:Hide()
                    section:SetHeight(SECTION_HDR_H)
                    y = y + SECTION_HDR_H
                else
                    section._grid:Show()
                    local displayItems = doMerge and MergeStacks(items) or items
                    local sSort = catDef.defaultSort or sortMode
                    local fn = SORT_FUNCS[sSort]
                    if fn and catDef.key ~= "freeSlots" then table.sort(displayItems, fn) end

                    -- Filter
                    local skipSection = false
                    if currentFilter ~= "" and catDef.key ~= "freeSlots" then
                        local f = {}
                        for _, item in ipairs(displayItems) do
                            if item.hasItem and (item.name or ""):lower():find(currentFilter, 1, true) then
                                f[#f+1] = item
                            end
                        end
                        if #f == 0 then
                            section:Hide()
                            skipSection = true
                        else
                            displayItems = f
                        end
                    end

                    if not skipSection then
                        local gx, gy = SIDE_PAD, -SECTION_PAD
                        local col = 0
                        for _, item in ipairs(displayItems) do
                            local w = AcquireSlot(section._grid, slotSize)
                            w:ClearAllPoints()
                            w:SetPoint("TOPLEFT", section._grid, "TOPLEFT", gx, gy)
                            UpdateSlot(w, item)
                            col = col + 1
                            if col >= columns then
                                col = 0; gx = SIDE_PAD; gy = gy - slotSize - spacingY
                            else gx = gx + slotSize + spacingX end
                        end
                        if col > 0 then gy = gy - slotSize - spacingY end

                        local gridH = math.abs(gy) + SECTION_PAD
                        section._grid:SetHeight(gridH)
                        section:SetHeight(SECTION_HDR_H + gridH)
                        y = y + SECTION_HDR_H + gridH
                        section:Show()
                    end
                end
            end
        end
        content:SetHeight(math.max(y + SIDE_PAD, 10))

    -- ===== LAYOUT: SEPARATE BAGS (GW2_UI-style) =====
    elseif layoutMode == "separateBags" then
        local collapsedDB = s.collapsedSections or {}
        local y = 0

        local bagOrder = {}
        for _, bagID in ipairs(BAG_IDS) do bagOrder[#bagOrder+1] = bagID end
        if s.reverseBagOrder then
            local rev = {}
            for i = #bagOrder, 1, -1 do rev[#rev+1] = bagOrder[i] end
            bagOrder = rev
        end

        local function processBag(bagID)
            local items = {}
            for _, item in ipairs(allItems) do
                if item.bagID == bagID then items[#items+1] = item end
            end
            if #items == 0 then return end

            -- Bag name
            local bagName
            if bagID == 0 then
                bagName = BACKPACK_TOOLTIP or "Backpack"
            else
                local slotName = (bagID == (REAGENT_BAG_ID or -1)) and "ReagentBag0Slot" or ("Bag" .. (bagID-1) .. "Slot")
                local slotID = GetInventorySlotInfo(slotName)
                local itemID = slotID and GetInventoryItemID("player", slotID)
                if itemID then
                    bagName = C_Item.GetItemInfo(itemID) or ("Bag " .. bagID)
                else
                    bagName = "Bag " .. bagID
                end
            end

            local secKey = "bag_" .. bagID
            local col = ACCENT
            local section = GetSection(content, secKey, col, bagName)
            section:SetWidth(contentW)
            local collapsed = collapsedDB[secKey] or false

            section._arrow:SetText(collapsed and ">" or "v")
            section._title:SetText(bagName)
            local filledCount, freeCount = 0, 0
            for _, item in ipairs(items) do
                if item.hasItem then filledCount = filledCount + 1
                else freeCount = freeCount + 1 end
            end
            section._countBadge:SetText("(" .. filledCount .. "/" .. #items .. ")")

            if y > 0 then y = y + SECTION_GAP end
            section:ClearAllPoints()
            section:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)

            if collapsed then
                section._grid:Hide()
                section:SetHeight(SECTION_HDR_H)
                y = y + SECTION_HDR_H
            else
                section._grid:Show()
                local displayItems = {}
                if sortMode == "none" then
                    -- Manual mode: keep natural slot order
                    for _, item in ipairs(items) do
                        if item.hasItem or showEmpty then
                            displayItems[#displayItems+1] = item
                        end
                    end
                else
                    local fn = SORT_FUNCS[sortMode]
                    local filled, empty = {}, {}
                    for _, item in ipairs(items) do
                        if item.hasItem then filled[#filled+1] = item
                        else empty[#empty+1] = item end
                    end
                    if fn then table.sort(filled, fn) end
                    for _, item in ipairs(filled) do displayItems[#displayItems+1] = item end
                    if showEmpty then
                        for _, item in ipairs(empty) do displayItems[#displayItems+1] = item end
                    end
                end

                if currentFilter ~= "" then
                    local f = {}
                    for _, item in ipairs(displayItems) do
                        if not item.hasItem or (item.name or ""):lower():find(currentFilter, 1, true) then
                            f[#f+1] = item
                        end
                    end
                    if #f == 0 then section:Hide(); return end
                    displayItems = f
                end

                local gx, gy = SIDE_PAD, -SECTION_PAD
                local c = 0
                for _, item in ipairs(displayItems) do
                    local w = AcquireSlot(section._grid, slotSize)
                    w:ClearAllPoints()
                    w:SetPoint("TOPLEFT", section._grid, "TOPLEFT", gx, gy)
                    UpdateSlot(w, item)
                    c = c + 1
                    if c >= columns then
                        c = 0; gx = SIDE_PAD; gy = gy - slotSize - spacingY
                    else gx = gx + slotSize + spacingX end
                end
                if c > 0 then gy = gy - slotSize - spacingY end

                local gridH = math.abs(gy) + SECTION_PAD
                section._grid:SetHeight(gridH)
                section:SetHeight(SECTION_HDR_H + gridH)
                y = y + SECTION_HDR_H + gridH
                section:Show()
            end
        end

        for _, bagID in ipairs(bagOrder) do
            processBag(bagID)
        end

        -- Hide unused sections
        for k, sec in pairs(sectionFrames) do
            local found = false
            for _, bagID in ipairs(bagOrder) do
                if k == "bag_" .. bagID then found = true; break end
            end
            if not found and layoutMode == "separateBags" then sec:Hide() end
        end
        content:SetHeight(math.max(y + SIDE_PAD, 10))
    end

    HideUnusedSlots()

    -- Auto-resize height (capped at 75% screen)
    local SEARCH_OFS = (s.showSearchBar ~= false) and SEARCH_H or 0
    local topOfs = HEADER_H + SEARCH_OFS
    local contentH = content:GetHeight()
    local maxH = (UIParent:GetHeight() / ((s.scale or 100)/100)) * 0.75
    local totalH = topOfs + contentH + FOOTER_H
    bagFrame:SetHeight(math.min(totalH, math.max(maxH, MIN_HEIGHT)))

    UpdateFreeSlots()
    UpdateFooter()
end

BS._LayoutGrid = LayoutGrid

-- =====================================
-- BAG BAR (GW2_UI-inspired sidebar)
-- =====================================

local function CreateBagBar(f)
    local bar = CreateFrame("Frame", nil, f)
    bar:SetWidth(BAGBAR_W)
    bar:SetPoint("TOPLEFT", 0, -HEADER_H)
    bar:SetPoint("BOTTOMLEFT", 0, FOOTER_H)
    f._bagBar = bar

    local barBg = bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints()
    barBg:SetColorTexture(HEADER_BG[1], HEADER_BG[2], HEADER_BG[3], 0.6)

    local sep = bar:CreateTexture(nil, "ARTWORK")
    sep:SetWidth(1)
    sep:SetPoint("TOPRIGHT", 0, 0)
    sep:SetPoint("BOTTOMRIGHT", 0, 0)
    sep:SetColorTexture(SEPARATOR[1], SEPARATOR[2], SEPARATOR[3], 0.6)

    bar._bagBtns = {}
    local bagSize = 28
    local pad = 4
    local y = -8

    for _, bagID in ipairs(BAG_IDS) do
        local btn = CreateFrame("Button", nil, bar)
        btn:SetSize(bagSize, bagSize)
        btn:SetPoint("TOP", bar, "TOP", 0, y)
        y = y - bagSize - pad

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        btn._icon = icon

        CreateBorders(btn, SLOT_BORDER[1], SLOT_BORDER[2], SLOT_BORDER[3], 0.4, "OVERLAY")

        local high = btn:CreateTexture(nil, "HIGHLIGHT")
        high:SetAllPoints()
        high:SetColorTexture(1, 1, 1, 0.15)

        -- Count
        local cnt = btn:CreateFontString(nil, "OVERLAY")
        cnt:SetFont(ADDON_FONT_BOLD, 8, "OUTLINE")
        cnt:SetPoint("BOTTOMRIGHT", -1, 1)
        cnt:SetTextColor(1, 1, 1, 0.8)
        btn._count = cnt

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if bagID == 0 then
                GameTooltip:SetText(BACKPACK_TOOLTIP or "Backpack")
            else
                local slotName = (bagID == (REAGENT_BAG_ID or -1)) and "ReagentBag0Slot" or ("Bag" .. (bagID-1) .. "Slot")
                local slotID = GetInventorySlotInfo(slotName)
                if slotID then GameTooltip:SetInventoryItem("player", slotID) end
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function(self, mb)
            if mb == "LeftButton" then
                if bagID > 0 then
                    local slotName = (bagID == (REAGENT_BAG_ID or -1)) and "ReagentBag0Slot" or ("Bag" .. (bagID-1) .. "Slot")
                    local slotID = GetInventorySlotInfo(slotName)
                    if slotID then PutItemInBag(slotID) end
                end
            end
        end)
        btn:RegisterForClicks("AnyUp")
        btn._bagID = bagID
        bar._bagBtns[#bar._bagBtns+1] = btn
    end
end

local function UpdateBagBar(f)
    if not f._bagBar then return end
    for _, btn in ipairs(f._bagBar._bagBtns) do
        local bagID = btn._bagID
        if bagID == 0 then
            btn._icon:SetTexture("Interface\\Buttons\\Button-Backpack-Up")
            local free = C_Container.GetContainerNumFreeSlots(0)
            btn._count:SetText(tostring(free))
        else
            local slotName = (bagID == (REAGENT_BAG_ID or -1)) and "ReagentBag0Slot" or ("Bag" .. (bagID-1) .. "Slot")
            local slotID = GetInventorySlotInfo(slotName)
            local tex = slotID and GetInventoryItemTexture("player", slotID)
            if tex then
                btn._icon:SetTexture(tex)
                btn._icon:SetDesaturated(slotID and IsInventoryItemLocked(slotID))
                local free = C_Container.GetContainerNumFreeSlots(bagID)
                btn._count:SetText(tostring(free))
            else
                btn._icon:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
                btn._icon:SetDesaturated(false)
                btn._count:SetText("")
            end
        end
    end
end

-- =====================================
-- SETTINGS CONTEXT MENU (GW2_UI-inspired)
-- =====================================

local function ShowSettingsMenu(anchor)
    if not MenuUtil or not MenuUtil.CreateContextMenu then return end
    MenuUtil.CreateContextMenu(anchor, function(_, root)
        root:SetMinimumWidth(1)
        local s = S()

        -- Layout mode
        local lmSub = root:CreateButton((L and L["opt_skin_bags_layout_mode"]) or "Layout Mode")
        for _, opt in ipairs({
            { "combined",      (L and L["opt_skin_bags_layout_combined"])   or "Combined Grid" },
            { "categories",    (L and L["opt_skin_bags_layout_categories"]) or "Categories" },
            { "separateBags",  (L and L["opt_skin_bags_layout_separate"])   or "Separate Bags" },
        }) do
            lmSub:CreateRadio(opt[2],
                function() return s.layoutMode == opt[1] end,
                function() s.layoutMode = opt[1]; LayoutGrid() end)
        end

        -- Sort mode
        local smSub = root:CreateButton((L and L["opt_skin_bags_sort_mode"]) or "Sort Mode")
        for _, opt in ipairs({
            { "none",    (L and L["opt_skin_bags_sort_none"])    or "Manual" },
            { "quality", (L and L["opt_skin_bags_sort_quality"]) or "Quality" },
            { "name",    (L and L["opt_skin_bags_sort_name"])    or "Name" },
            { "type",    (L and L["opt_skin_bags_sort_type"])    or "Type" },
            { "ilvl",    (L and L["opt_skin_bags_sort_ilvl"])    or "Item Level" },
        }) do
            smSub:CreateRadio(opt[2],
                function() return s.sortMode == opt[1] end,
                function() s.sortMode = opt[1]; LayoutGrid() end)
        end

        -- Toggles
        local function addCheck(label, key, cb)
            root:CreateCheckbox(label, function() return s[key] end, function()
                s[key] = not s[key]
                if cb then cb() else LayoutGrid() end
            end)
        end

        addCheck((L and L["opt_skin_bags_quality_borders"]) or "Quality Borders", "showQualityBorders")
        addCheck((L and L["opt_skin_bags_show_ilvl"])       or "Show Item Level",  "showItemLevel")
        addCheck((L and L["opt_skin_bags_show_junk_icon"])  or "Show Junk Icon",   "showJunkIcon")
        addCheck((L and L["opt_skin_bags_cooldowns"])       or "Cooldown Overlays", "showCooldowns")
        addCheck((L and L["opt_skin_bags_quantity"])         or "Quantity Badges",   "showQuantityBadges")
        addCheck((L and L["opt_skin_bags_search"])           or "Search Bar",        "showSearchBar", function()
            if bagFrame._searchFrame then
                bagFrame._searchFrame:SetShown(s.showSearchBar ~= false)
                local SEARCH_OFS = (s.showSearchBar ~= false) and SEARCH_H or 0
                bagFrame._scrollFrame:SetPoint("TOPLEFT", s.showBagBar ~= false and BAGBAR_W or 0, -(HEADER_H + SEARCH_OFS))
            end
            LayoutGrid()
        end)
        addCheck((L and L["opt_skin_bags_show_empty"]) or "Show Free Slots", "showEmptySlots")
        addCheck((L and L["opt_skin_bags_show_gold"])  or "Show Gold",        "showGold",  function() UpdateFooter() end)
        addCheck((L and L["opt_skin_bags_show_currencies"]) or "Show Currencies", "showCurrencies", function() UpdateFooter() end)
        addCheck((L and L["opt_skin_bags_reverse_order"]) or "Reverse Bag Order", "reverseBagOrder")
        addCheck((L and L["opt_skin_bags_stack_merge"]) or "Merge Stacks", "stackMerge")
        addCheck((L and L["opt_skin_bags_show_bag_bar"]) or "Show Bag Bar", "showBagBar", function()
            if bagFrame._bagBar then
                bagFrame._bagBar:SetShown(s.showBagBar ~= false)
                local barOfs = (s.showBagBar ~= false) and BAGBAR_W or 0
                local SEARCH_OFS = (s.showSearchBar ~= false) and SEARCH_H or 0
                bagFrame._scrollFrame:SetPoint("TOPLEFT", barOfs, -(HEADER_H + SEARCH_OFS))
                bagFrame._searchFrame:SetPoint("TOPLEFT", barOfs, -HEADER_H)
                bagFrame._searchFrame:SetPoint("TOPRIGHT", 0, -HEADER_H)
            end
            LayoutGrid()
        end)
    end)
end

-- =====================================
-- CREATE MAIN FRAME
-- =====================================

local function CreateBagFrame()
    if bagFrame then return bagFrame end
    local s = S()

    local f = CreateFrame("Frame", "TomoMod_BagSkin_Main", UIParent)
    f:SetSize(s.width or 480, 500)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT)
    f:EnableMouse(true)

    -- Position
    local pos = s.position
    if pos then
        f:SetPoint(pos.anchor or "BOTTOMRIGHT", UIParent, pos.relTo or "BOTTOMRIGHT", pos.x or -20, pos.y or 60)
    else
        f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 60)
    end
    f:SetScale((s.scale or 100) / 100)

    -- Background
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], (s.opacity or 92) / 100)
    f._bg = bg
    CreateBorders(f, BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], 0.6)

    -- ===== HEADER =====
    local header = CreateFrame("Frame", nil, f)
    header:SetHeight(HEADER_H)
    header:SetPoint("TOPLEFT", 0, 0); header:SetPoint("TOPRIGHT", 0, 0)

    local hBg = header:CreateTexture(nil, "BACKGROUND")
    hBg:SetAllPoints()
    hBg:SetColorTexture(HEADER_BG[1], HEADER_BG[2], HEADER_BG[3], 1)

    local hSep = header:CreateTexture(nil, "ARTWORK")
    hSep:SetHeight(1); hSep:SetPoint("BOTTOMLEFT", 0, 0); hSep:SetPoint("BOTTOMRIGHT", 0, 0)
    hSep:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.30)

    -- Title
    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont(ADDON_FONT_BOLD, 13, "")
    title:SetPoint("LEFT", 10, 0)
    title:SetText("|cff0cd29fBags|r")

    -- Space string
    local spaceStr = header:CreateFontString(nil, "OVERLAY")
    spaceStr:SetFont(ADDON_FONT, 10, "")
    spaceStr:SetPoint("LEFT", title, "RIGHT", 12, 0)
    spaceStr:SetTextColor(MUTED_TEXT[1], MUTED_TEXT[2], MUTED_TEXT[3])
    f._spaceStr = spaceStr

    -- Close button
    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(HEADER_H, HEADER_H)
    closeBtn:SetPoint("RIGHT", 0, 0)
    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY")
    closeTxt:SetFont(ADDON_FONT_BOLD, 16, ""); closeTxt:SetPoint("CENTER")
    closeTxt:SetText("\195\151"); closeTxt:SetTextColor(MUTED_TEXT[1], MUTED_TEXT[2], MUTED_TEXT[3])
    closeBtn:SetScript("OnEnter", function() closeTxt:SetTextColor(0.90, 0.28, 0.28, 1) end)
    closeBtn:SetScript("OnLeave", function() closeTxt:SetTextColor(MUTED_TEXT[1], MUTED_TEXT[2], MUTED_TEXT[3]) end)
    closeBtn:SetScript("OnClick", function()
        f:Hide()
        if CloseAllBags then CloseAllBags() end
    end)

    -- Settings button (GW2_UI-inspired kogwheel)
    local setBtn = CreateFrame("Button", nil, header)
    setBtn:SetSize(HEADER_H, HEADER_H)
    setBtn:SetPoint("RIGHT", closeBtn, "LEFT", 0, 0)
    local setTxt = setBtn:CreateFontString(nil, "OVERLAY")
    setTxt:SetFont(ADDON_FONT, 14, ""); setTxt:SetPoint("CENTER")
    setTxt:SetText("|TInterface\\GossipFrame\\BinderGossipIcon:16:16|t")
    setTxt:SetTextColor(MUTED_TEXT[1], MUTED_TEXT[2], MUTED_TEXT[3])
    setBtn:SetScript("OnEnter", function()
        setTxt:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(setBtn, "ANCHOR_TOP")
        GameTooltip:SetText((L and L["opt_skin_bags_settings"]) or "Bag Settings", 1, 1, 1)
        GameTooltip:Show()
    end)
    setBtn:SetScript("OnLeave", function() setTxt:SetTextColor(MUTED_TEXT[1], MUTED_TEXT[2], MUTED_TEXT[3]); GameTooltip:Hide() end)
    setBtn:SetScript("OnClick", function(self) ShowSettingsMenu(self) end)

    -- Sort button (GW2_UI-inspired)
    local sortBtn = CreateFrame("Button", nil, header, "BackdropTemplate")
    sortBtn:SetSize(50, 22); sortBtn:SetPoint("RIGHT", setBtn, "LEFT", -4, 0)
    sortBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    sortBtn:SetBackdropColor(ACCENT[1]*0.15, ACCENT[2]*0.15, ACCENT[3]*0.15, 0.8)
    sortBtn:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.4)
    local sortTxt = sortBtn:CreateFontString(nil, "OVERLAY")
    sortTxt:SetFont(ADDON_FONT, 10, ""); sortTxt:SetPoint("CENTER")
    sortTxt:SetText("Sort"); sortTxt:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
    sortBtn:SetScript("OnClick", function()
        C_Container.SortBags()
        C_Timer.After(0.5, LayoutGrid)
    end)
    sortBtn:SetScript("OnEnter", function()
        sortBtn:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
        sortTxt:SetTextColor(1, 1, 1)
    end)
    sortBtn:SetScript("OnLeave", function()
        sortBtn:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.4)
        sortTxt:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
    end)

    -- ===== SEARCH BAR =====
    local showBagBar = s.showBagBar ~= false
    local barOfs = showBagBar and BAGBAR_W or 0

    local searchFrame = CreateFrame("Frame", nil, f)
    searchFrame:SetHeight(SEARCH_H)
    searchFrame:SetPoint("TOPLEFT", barOfs, -HEADER_H)
    searchFrame:SetPoint("TOPRIGHT", 0, -HEADER_H)
    f._searchFrame = searchFrame

    local sBg = searchFrame:CreateTexture(nil, "BACKGROUND")
    sBg:SetAllPoints()
    sBg:SetColorTexture(SEARCH_BG[1], SEARCH_BG[2], SEARCH_BG[3], 0.9)

    local sSep = searchFrame:CreateTexture(nil, "ARTWORK")
    sSep:SetHeight(1); sSep:SetPoint("BOTTOMLEFT", 0, 0); sSep:SetPoint("BOTTOMRIGHT", 0, 0)
    sSep:SetColorTexture(SEPARATOR[1], SEPARATOR[2], SEPARATOR[3], 1)

    local sIcon = searchFrame:CreateFontString(nil, "OVERLAY")
    sIcon:SetFont(ADDON_FONT, 13, ""); sIcon:SetPoint("LEFT", 8, 0)
    sIcon:SetText("|TInterface\\Common\\UI-Searchbox-Icon:14:14|t")
    sIcon:SetTextColor(MUTED_TEXT[1], MUTED_TEXT[2], MUTED_TEXT[3], 0.6)

    local searchBox = CreateFrame("EditBox", "TomoMod_BagSkin_Search", searchFrame)
    searchBox:SetPoint("LEFT", sIcon, "RIGHT", 6, 0)
    searchBox:SetPoint("RIGHT", -8, 0)
    searchBox:SetHeight(SEARCH_H - 4)
    searchBox:SetFont(ADDON_FONT, 11, "")
    searchBox:SetTextColor(0.85, 0.85, 0.85)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(50)
    searchBox:SetScript("OnTextChanged", function(self)
        currentFilter = (self:GetText() or ""):lower()
        LayoutGrid()
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText(""); self:ClearFocus()
        currentFilter = ""; LayoutGrid()
    end)

    if s.showSearchBar == false then searchFrame:Hide() end

    -- ===== BAG BAR (left sidebar) =====
    CreateBagBar(f)
    if not showBagBar then f._bagBar:Hide() end

    -- ===== SCROLL BODY =====
    local SEARCH_OFS = (s.showSearchBar ~= false) and SEARCH_H or 0
    local scrollFrame = CreateFrame("ScrollFrame", nil, f)
    scrollFrame:SetPoint("TOPLEFT", barOfs, -(HEADER_H + SEARCH_OFS))
    scrollFrame:SetPoint("BOTTOMRIGHT", 0, FOOTER_H)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local mx  = self:GetVerticalScrollRange()
        local step = (s.slotSize or 40) + (s.slotSpacingY or 5)
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * step, mx)))
    end)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(scrollFrame:GetWidth() or 440)
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)
    f._content = content
    f._scrollFrame = scrollFrame

    -- ===== FOOTER =====
    local footer = CreateFrame("Frame", nil, f)
    footer:SetHeight(FOOTER_H)
    footer:SetPoint("BOTTOMLEFT", 0, 0); footer:SetPoint("BOTTOMRIGHT", 0, 0)

    local fBg = footer:CreateTexture(nil, "BACKGROUND")
    fBg:SetAllPoints()
    fBg:SetColorTexture(HEADER_BG[1], HEADER_BG[2], HEADER_BG[3], 1)

    local fSep = footer:CreateTexture(nil, "ARTWORK")
    fSep:SetHeight(1); fSep:SetPoint("TOPLEFT", 0, 0); fSep:SetPoint("TOPRIGHT", 0, 0)
    fSep:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.20)

    local goldText = footer:CreateFontString(nil, "OVERLAY")
    goldText:SetFont(ADDON_FONT_BOLD, 11, ""); goldText:SetPoint("LEFT", 10, 0)
    goldText:SetJustifyH("LEFT")
    f._goldText = goldText

    local currContainer = CreateFrame("Frame", nil, footer)
    currContainer:SetHeight(FOOTER_H)
    currContainer:SetPoint("RIGHT", -10, 0)
    currContainer:SetPoint("LEFT", goldText, "RIGHT", 10, 0)
    f._currencyContainer = currContainer
    f._currencyFrames = {}

    local currNone = footer:CreateFontString(nil, "OVERLAY")
    currNone:SetFont(ADDON_FONT, 10, "")
    currNone:SetPoint("RIGHT", -10, 0)
    currNone:SetJustifyH("RIGHT")
    currNone:Hide()
    f._currencyNoneText = currNone
    f._footer = footer

    -- ===== RESIZE HANDLE (GW2_UI-inspired) =====
    local sizer = CreateFrame("Frame", nil, f)
    sizer:SetSize(16, 16)
    sizer:SetPoint("BOTTOMRIGHT", 0, 0)
    sizer:EnableMouse(true)

    local sizerTex = sizer:CreateTexture(nil, "OVERLAY")
    sizerTex:SetAllPoints()
    sizerTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    sizer:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then f:StartSizing("BOTTOMRIGHT") end
    end)
    sizer:SetScript("OnMouseUp", function(self, btn)
        if btn == "LeftButton" then
            f:StopMovingOrSizing()
            local db = TomoModDB and TomoModDB.bagSkin
            if db then db.width = f:GetWidth() end
            LayoutGrid()
        end
    end)
    sizer:SetScript("OnEnter", function() sizerTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight") end)
    sizer:SetScript("OnLeave", function() sizerTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up") end)

    -- Resize callback (GW2_UI recalculates cols live during resize)
    local _lastCols = 0
    f:SetScript("OnSizeChanged", function(self, w, h)
        if self._content then
            local bOfs = (S().showBagBar ~= false) and BAGBAR_W or 0
            self._content:SetWidth(w - bOfs)
            -- Re-layout when column count changes (like GW2_UI's onBagFrameChangeSize)
            local newCols = ColCount(S().slotSize or 40, S().slotSpacingX or 5, w - bOfs)
            if newCols ~= _lastCols then
                _lastCols = newCols
                if not _layoutPending then
                    _layoutPending = true
                    C_Timer.After(0, function()
                        _layoutPending = false
                        LayoutGrid()
                    end)
                end
            end
        end
    end)

    -- ===== DRAG (header) =====
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local db = TomoModDB and TomoModDB.bagSkin
        if db then
            local pt, _, rel, x, y = f:GetPoint(1)
            db.position = { anchor = pt, relTo = rel, x = x, y = y }
        end
    end)

    -- Register as special frame for Escape close
    tinsert(UISpecialFrames, "TomoMod_BagSkin_Main")

    f:Hide()
    bagFrame = f
    return f
end

-- =====================================
-- BLIZZARD BAG SUPPRESSION
-- =====================================

local _suppressing = false

local function HideBlizzardBags()
    if _suppressing then return end
    _suppressing = true
    if ContainerFrameCombinedBags and ContainerFrameCombinedBags:IsShown() then
        ContainerFrameCombinedBags:Hide()
    end
    for i = 1, 13 do
        local cf = _G["ContainerFrame" .. i]
        if cf and cf:IsShown() then cf:Hide() end
    end
    _suppressing = false
end

local _blizzHooked = false

local function HookBlizzardBags()
    if _blizzHooked then return end
    _blizzHooked = true

    -- Parent ContainerFrameCombinedBags to a hidden frame (GW2_UI approach)
    if ContainerFrameCombinedBags then
        ContainerFrameCombinedBags:SetScript("OnShow", nil)
        ContainerFrameCombinedBags:SetScript("OnHide", nil)
        local hider = CreateFrame("Frame")
        hider:Hide()
        ContainerFrameCombinedBags:SetParent(hider)
        ContainerFrameCombinedBags:ClearAllPoints()
        ContainerFrameCombinedBags:SetPoint("BOTTOM")
    end

    -- Suppress individual bag frames
    for i = 1, 13 do
        local cf = _G["ContainerFrame" .. i]
        if cf then
            hooksecurefunc(cf, "Show", function(self)
                if not _suppressing and IsEnabled() then
                    _suppressing = true; self:Hide(); _suppressing = false
                end
            end)
        end
    end

    -- Disable combined bags CVar (like GW2_UI)
    if SetCVar then
        pcall(SetCVar, "combinedBags", "0")
    end
end

-- =====================================
-- BAG OPEN / CLOSE HOOKS
-- =====================================

local hooksInstalled = false
local hookGuard = false

local function ShowBag()
    if not IsEnabled() or hookGuard then return end
    hookGuard = true
    C_Timer.After(0, function() hookGuard = false end)
    HideBlizzardBags()
    if bagFrame then
        UpdateBagBar(bagFrame)
        LayoutGrid()
        bagFrame:Show()
    end
end

local function ToggleBag()
    if not IsEnabled() or hookGuard then return end
    hookGuard = true
    C_Timer.After(0, function() hookGuard = false end)
    HideBlizzardBags()
    if bagFrame then
        if bagFrame:IsShown() then
            bagFrame:Hide()
        else
            UpdateBagBar(bagFrame)
            LayoutGrid()
            bagFrame:Show()
        end
    end
end

local function InstallHooks()
    if hooksInstalled then return end
    hooksInstalled = true

    HookBlizzardBags()

    if ToggleAllBags   then hooksecurefunc("ToggleAllBags",   ToggleBag) end
    if ToggleBackpack  then hooksecurefunc("ToggleBackpack",  ToggleBag) end
    if ToggleBag       then hooksecurefunc("ToggleBag",       function() ToggleBag() end) end
    if OpenAllBags     then hooksecurefunc("OpenAllBags",     ShowBag) end
    if OpenBackpack    then hooksecurefunc("OpenBackpack",    ShowBag) end
    if OpenBag         then hooksecurefunc("OpenBag",         function() ShowBag() end) end
    if CloseAllBags    then hooksecurefunc("CloseAllBags",    function()
        if not InCombatLockdown() and bagFrame then bagFrame:Hide() end
    end) end
    if CloseBackpack   then hooksecurefunc("CloseBackpack",   function()
        if not InCombatLockdown() and IsEnabled() and bagFrame then bagFrame:Hide() end
    end) end

    -- Events
    local events = CreateFrame("Frame")
    events:RegisterEvent("BAG_UPDATE")
    events:RegisterEvent("BAG_UPDATE_DELAYED")
    events:RegisterEvent("ITEM_LOCK_CHANGED")
    events:RegisterEvent("BAG_UPDATE_COOLDOWN")
    events:RegisterEvent("PLAYER_MONEY")
    events:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    events:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
    events:RegisterEvent("CVAR_UPDATE")
    events:SetScript("OnEvent", function(_, event, ...)
        if not IsEnabled() then return end

        if event == "CVAR_UPDATE" then
            local name, val = ...
            if name == "combinedBags" and val == "1" then
                pcall(SetCVar, "combinedBags", "0")
            end
            return
        end

        if event == "PLAYER_MONEY" or event == "CURRENCY_DISPLAY_UPDATE" then
            UpdateFooter()
            return
        end

        if event == "ITEM_LOCK_CHANGED" then
            if bagFrame and bagFrame:IsShown() then UpdateBagBar(bagFrame) end
        end

        if bagFrame and bagFrame:IsShown() then
            if not _layoutPending then
                _layoutPending = true
                C_Timer.After(0.1, function()
                    _layoutPending = false
                    LayoutGrid()
                    UpdateBagBar(bagFrame)
                end)
            end
        end
    end)
end

-- =====================================
-- MOVERS INTEGRATION
-- =====================================

local function RegisterWithMovers()
    if not TomoMod_Movers or not TomoMod_Movers.RegisterEntry then return end
    TomoMod_Movers.RegisterEntry({
        label = "Bag Skin",
        unlock = function()
            if bagFrame then bagFrame:SetMovable(true); bagFrame:EnableMouse(true) end
        end,
        lock = function()
            if bagFrame then
                local db = TomoModDB and TomoModDB.bagSkin
                if db then
                    local pt, _, rel, x, y = bagFrame:GetPoint(1)
                    db.position = { anchor = pt, relTo = rel, x = x, y = y }
                end
            end
        end,
        isActive = function() return IsEnabled() end,
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

    local showBagBar = s.showBagBar ~= false
    local barOfs = showBagBar and BAGBAR_W or 0
    local SEARCH_OFS = (s.showSearchBar ~= false) and SEARCH_H or 0

    if bagFrame._searchFrame then
        bagFrame._searchFrame:SetShown(s.showSearchBar ~= false)
        bagFrame._searchFrame:SetPoint("TOPLEFT", barOfs, -HEADER_H)
        bagFrame._searchFrame:SetPoint("TOPRIGHT", 0, -HEADER_H)
    end
    if bagFrame._bagBar then
        bagFrame._bagBar:SetShown(showBagBar)
    end
    bagFrame._scrollFrame:SetPoint("TOPLEFT", barOfs, -(HEADER_H + SEARCH_OFS))

    LayoutGrid()
end

function BS.SetEnabled(enabled)
    local db = TomoModDB and TomoModDB.bagSkin
    if db then db.enabled = enabled end
    if enabled then
        if not bagFrame then CreateBagFrame() end
        InstallHooks()
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
        InstallHooks()
        RegisterWithMovers()
    end)
end

-- =====================================
-- AUTO-INIT
-- =====================================

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")

    if TomoModDB and not TomoModDB.bagSkin then
        TomoModDB.bagSkin = {}
    end
    if TomoModDB and TomoModDB.bagSkin then
        local db = TomoModDB.bagSkin
        local D = {
            enabled = false, slotSize = 40, slotSpacingX = 5, slotSpacingY = 5,
            width = 480, scale = 100, opacity = 92,
            showQualityBorders = true, showCooldowns = true, showQuantityBadges = true,
            showItemLevel = false, showJunkIcon = false, showSearchBar = true,
            showGold = true, showCurrencies = false,
            layoutMode = "combined", sortMode = "quality",
            reverseBagOrder = false, stackMerge = false,
            showEmptySlots = true, showRecentItems = true,
            showBagBar = true, collapsedSections = {},
        }
        for k, v in pairs(D) do
            if db[k] == nil then db[k] = v end
        end
        if db.position == nil then
            db.position = { anchor = "BOTTOMRIGHT", relTo = "BOTTOMRIGHT", x = -20, y = 60 }
        end
        -- Migrate old single slotSpacing → separate X/Y
        if db.slotSpacing and not db._migratedSpacing then
            db.slotSpacingX = db.slotSpacing
            db.slotSpacingY = db.slotSpacing
            db._migratedSpacing = true
        end
    end

    BS.Initialize()
    RegisterWithMovers()
end)
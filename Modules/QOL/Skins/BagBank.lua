-- =====================================
-- BagBank.lua
-- Bank window for the TomoMod bag rework (The War Within / Midnight).
--
-- Self-contained module (its own frame, slot pool, events) that mirrors the
-- visual language of BagSkin.lua and reuses TomoMod_BagCategories for the
-- category sidebar. Item buttons inherit ContainerFrameItemButtonTemplate so
-- click/use/withdraw/deposit is handled by Blizzard's secure code (taint-safe).
--
-- Bank types (Midnight): Enum.BankType.Character (personal) and
-- Enum.BankType.Account (Warband / account-wide). Tab bagIDs come from
-- C_Bank.FetchPurchasedBankTabIDs(bankType); the grid aggregates all tabs of
-- the selected type and filters by category. Every C_Bank call is guarded by
-- an existence check + pcall because parts of this API are version-sensitive.
--
-- Inspired by the bank model of EllesmereUIBags, fully reimplemented (no shared
-- code).
--
-- Public API: TomoMod_BagBank  (.Initialize / .SetEnabled / .ApplySettings)
-- Depends on: TomoMod_BagCategories (must load first), TomoMod_Movers (optional)
-- =====================================

TomoMod_BagBank = TomoMod_BagBank or {}
local BANK = TomoMod_BagBank
local L = TomoMod_L

-- =====================================
-- THEME / DIMENSIONS (mirrors BagSkin.lua)
-- =====================================

local ADDON_PATH      = "Interface\\AddOns\\TomoMod\\"
local ADDON_FONT      = ADDON_PATH .. "Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD = ADDON_PATH .. "Assets\\Fonts\\Poppins-SemiBold.ttf"

local ACCENT          = { 0.047, 0.824, 0.624 }   -- #0CD29F
local BG_COLOR        = { 0.045, 0.045, 0.060 }
local HEADER_BG       = { 0.065, 0.065, 0.082 }
local BORDER_COLOR    = { 0.18,  0.18,  0.22 }
local SLOT_BG         = { 0.07,  0.07,  0.09 }
local SLOT_BORDER     = { 0.22,  0.22,  0.28 }
local SEPARATOR       = { 0.14,  0.14,  0.17 }
local MUTED_TEXT      = { 0.48,  0.48,  0.54 }
local SEARCH_BG       = { 0.055, 0.055, 0.072 }
local SECTION_HDR_BG  = { 0.075, 0.075, 0.095 }
local SIDEBAR_BG      = { 0.050, 0.050, 0.064 }

local HEADER_H        = 36
local TYPEBAR_H       = 26
local SEARCH_H        = 28
local FOOTER_H        = 30
local SIDEBAR_W       = 44
local SECTION_HDR_H   = 20
local SIDE_PAD        = 5
local MIN_WIDTH       = 360
local MIN_HEIGHT      = 300

local QUALITY_COLORS = {
    [0] = { 0.62, 0.62, 0.62 }, [1] = { 1, 1, 1 },
    [2] = { 0.12, 1, 0 },       [3] = { 0, 0.44, 0.87 },
    [4] = { 0.64, 0.21, 0.93 }, [5] = { 1, 0.50, 0 },
    [6] = { 0.90, 0.80, 0.50 }, [7] = { 0, 0.8, 1 },
}

local CRAFTING_QUALITY_ATLAS = {
    [1] = "Professions-Icon-Quality-Tier1-Small",
    [2] = "Professions-Icon-Quality-Tier2-Small",
    [3] = "Professions-Icon-Quality-Tier3-Small",
    [4] = "Professions-Icon-Quality-Tier4-Small",
    [5] = "Professions-Icon-Quality-Tier5-Small",
}

local QUESTIONMARK = 134400

-- =====================================
-- BANK TYPE CONSTANTS
-- =====================================

local BANK_CHARACTER = Enum and Enum.BankType and Enum.BankType.Character
local BANK_ACCOUNT   = Enum and Enum.BankType and Enum.BankType.Account

-- =====================================
-- STATE
-- =====================================

local bankFrame
local isInitialized = false
local hooksInstalled = false
local currentFilter = ""
local selectedCategoryIndex = nil   -- nil = "All"
local _layoutPending = false
local _deferredRefresh = false      -- a refresh was skipped in combat; replay later

local slotButtons = {}              -- pool of bank item buttons (wrappers)
local slotPoolIdx = 0
local bankBtnCount = 0

-- Reusable item-collection table (perf: wiped, never reallocated in hot path)
local _items = {}

-- =====================================
-- SETTINGS
-- =====================================

local function S()
    return TomoModDB and TomoModDB.bagSkin or {}
end

local function IsEnabled()
    local s = S()
    return s.enabled and s.bankEnabled ~= false
end

local function BC()
    return TomoMod_BagCategories
end

-- =====================================
-- HELPERS (mirrors BagSkin.lua)
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

local function FormatGold(money)
    if not money or money <= 0 then return "|cff666677---|r" end
    return GetCoinTextureString(money)
end

local function ColCount(slotSize, spacingX, frameWidth)
    local isize = slotSize + spacingX
    return math.max(1, math.floor((frameWidth - SIDE_PAD * 2 + spacingX) / isize))
end

local function CN(key, fallback)
    return (L and L[key]) or fallback
end

-- Apply an icon that may be a fileID or an atlas; self-heal invalid atlases.
local function SafeSetIcon(tex, icon, isAtlas)
    if not tex then return end
    if isAtlas and type(icon) == "string" then
        tex:SetAtlas(icon, false)
        if not tex:GetAtlas() then tex:SetTexture(QUESTIONMARK) end
    else
        tex:SetTexture(icon or QUESTIONMARK)
    end
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

-- =====================================
-- BANK TYPE / TAB DISCOVERY
-- =====================================

local function IsBankAvailable()
    return (C_Bank ~= nil) and (BANK_CHARACTER ~= nil)
end

-- The selected bank type, as an Enum.BankType value.
local function CurrentBankType()
    local sel = S().bankSelectedType
    if sel == "account" and BANK_ACCOUNT then return BANK_ACCOUNT end
    return BANK_CHARACTER
end

-- bagIDs of all purchased tabs for a bank type. Prefers the dedicated API,
-- falls back to enumerating Enum.BagIndex keys.
local function GetTabBagIDs(bankType)
    local ids = {}
    if not bankType then return ids end
    if C_Bank and C_Bank.FetchPurchasedBankTabIDs then
        local ok, res = pcall(C_Bank.FetchPurchasedBankTabIDs, bankType)
        if ok and type(res) == "table" then
            for _, id in ipairs(res) do ids[#ids + 1] = id end
        end
    end
    if #ids == 0 and Enum and Enum.BagIndex then
        local prefix = (bankType == BANK_ACCOUNT) and "AccountBankTab_" or "CharacterBankTab_"
        local maxN   = (bankType == BANK_ACCOUNT) and 5 or 6
        for i = 1, maxN do
            local id = Enum.BagIndex[prefix .. i]
            if id then ids[#ids + 1] = id end
        end
    end
    return ids
end

local function IsTypeViewable(bankType)
    if not bankType then return false end
    if C_Bank and C_Bank.FetchViewableBankTypes then
        local ok, list = pcall(C_Bank.FetchViewableBankTypes)
        if ok and type(list) == "table" then
            for _, t in ipairs(list) do
                if t == bankType then return true end
            end
            return false
        end
    end
    if bankType == BANK_CHARACTER then return true end
    return #GetTabBagIDs(bankType) > 0
end

local function BankCall(fnName, ...)
    if not C_Bank or not C_Bank[fnName] then return nil end
    local ok, a, b = pcall(C_Bank[fnName], ...)
    if ok then return a, b end
    return nil
end

-- =====================================
-- SLOT FACTORY (taint-safe, ContainerFrameItemButtonTemplate)
-- The template routes click/use/withdraw/deposit through Blizzard's secure
-- code. We never write custom keys on the button during a secure path: bag is
-- carried by the wrapper's ID, slot by the button's ID (both official). Our
-- decorations are separate child regions updated by non-protected methods.
-- =====================================

-- Hide / neutralize the template's own decorations (methods only).
local function NeutralizeTemplate(btn, name)
    if btn.IconBorder then btn.IconBorder:Hide() end
    if btn.IconOverlay then btn.IconOverlay:Hide() end
    if btn.IconOverlay2 then btn.IconOverlay2:Hide() end
    if btn.NewItemTexture then btn.NewItemTexture:Hide() end
    if btn.BattlepayItemTexture then btn.BattlepayItemTexture:Hide() end
    if btn.IconQuestTexture then btn.IconQuestTexture:Hide() end
    if btn.JunkIcon then btn.JunkIcon:Hide() end
    if btn.UpgradeIcon then btn.UpgradeIcon:Hide() end
    if btn.ItemContextOverlay then btn.ItemContextOverlay:Hide() end
    local nt = btn.GetNormalTexture and btn:GetNormalTexture()
    if nt then nt:SetTexture("") ; nt:Hide() end
    if btn.SetNormalTexture then btn:SetNormalTexture("") end
    local pushed = btn.GetPushedTexture and btn:GetPushedTexture()
    if pushed then pushed:SetTexture("") ; pushed:Hide() end
    local count = btn.Count or (name and _G[name .. "Count"])
    if count then count:Hide() end           -- we draw our own quantity text
    local flash = name and _G[name .. "Flash"]
    if flash then flash:Hide() end
    if btn.flashAnim and btn.flashAnim.Stop then btn.flashAnim:Stop() end
    if btn.newitemglowAnim and btn.newitemglowAnim.Stop then btn.newitemglowAnim:Stop() end
end

local function CreateBankSlot(parent, size)
    bankBtnCount = bankBtnCount + 1
    local name = "TomoModBankBtn" .. bankBtnCount

    local wrapper = CreateFrame("Frame", nil, parent)
    wrapper:SetSize(size, size)

    local btn = CreateFrame("ItemButton", name, wrapper, "ContainerFrameItemButtonTemplate")
    btn:SetAllPoints(wrapper)
    wrapper.btn = btn

    NeutralizeTemplate(btn, name)

    -- Backdrop behind the icon
    local bg = btn:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetAllPoints()
    bg:SetColorTexture(SLOT_BG[1], SLOT_BG[2], SLOT_BG[3], 1)
    btn._bg = bg

    -- Icon (reuse the template's icon texture, restyled)
    local icon = btn.icon or _G[name .. "IconTexture"]
    if icon then
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", -1, 1)
    end
    btn._icon = icon

    -- Quality border
    btn._qualBorders = CreateBorders(btn, SLOT_BORDER[1], SLOT_BORDER[2], SLOT_BORDER[3], 0.6, "OVERLAY")

    -- Cooldown (reuse the template's cooldown frame if present)
    local cd = btn.Cooldown or _G[name .. "Cooldown"]
    if not cd then
        cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
        cd:SetAllPoints(icon or btn)
    end
    cd:SetDrawEdge(false)
    cd:EnableMouse(false)
    btn._cooldown = cd

    -- Our quantity text
    local qty = btn:CreateFontString(nil, "OVERLAY")
    qty:SetFont(ADDON_FONT_BOLD, 10, "OUTLINE")
    qty:SetPoint("BOTTOMRIGHT", -2, 2)
    qty:SetTextColor(1, 1, 1, 1)
    btn._qtyText = qty

    -- Crafting quality
    local qualIcon = btn:CreateTexture(nil, "OVERLAY", nil, 3)
    qualIcon:SetSize(14, 14)
    qualIcon:SetPoint("TOPLEFT", 2, -2)
    qualIcon:Hide()
    btn._qualIcon = qualIcon

    -- Item level
    local ilvlBadge = btn:CreateFontString(nil, "OVERLAY")
    ilvlBadge:SetFont(ADDON_FONT_BOLD, 8, "OUTLINE")
    ilvlBadge:SetPoint("BOTTOMLEFT", 2, 2)
    ilvlBadge:SetTextColor(1, 0.82, 0.0, 1)
    ilvlBadge:Hide()
    btn._ilvlBadge = ilvlBadge

    -- Junk icon
    local junkIcon = btn:CreateTexture(nil, "OVERLAY", nil, 3)
    junkIcon:SetAtlas("bags-junkcoin", true)
    junkIcon:SetPoint("TOPLEFT", -3, 3)
    junkIcon:Hide()
    btn._junkIcon = junkIcon

    -- Highlight
    local high = btn:CreateTexture(nil, "HIGHLIGHT")
    high:SetAllPoints()
    high:SetColorTexture(1, 1, 1, 0.12)
    high:SetBlendMode("ADD")

    -- Tooltip: read live from the container by bag/slot (no stored state).
    btn:SetScript("OnEnter", function(self)
        local b = self:GetParent() and self:GetParent():GetID()
        local sl = self:GetID()
        if b and sl and sl > 0 then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetBagItem(b, sl)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- NOTE: click/use/withdraw/deposit are intentionally left to the template's
    -- native secure handlers. We do not override OnClick.

    return wrapper
end

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

local function AcquireSlot(parent, size)
    slotPoolIdx = slotPoolIdx + 1
    if slotPoolIdx <= #slotButtons then
        local w = slotButtons[slotPoolIdx]
        w:SetParent(parent)
        w:SetSize(size, size)
        w:Show()
        return w
    end
    if InCombatLockdown() then
        -- Don't create secure buttons in combat; mark for replay and bail.
        slotPoolIdx = slotPoolIdx - 1
        _deferredRefresh = true
        return nil
    end
    local w = CreateBankSlot(parent, size)
    slotButtons[#slotButtons + 1] = w
    return w
end

local function ResetSlotPool() slotPoolIdx = 0 end

local function HideUnusedSlots()
    for i = slotPoolIdx + 1, #slotButtons do slotButtons[i]:Hide() end
end

-- Pre-warm a pool out of combat to minimize in-combat creation.
local function PrewarmPool(count)
    if InCombatLockdown() or not bankFrame then return end
    local parent = bankFrame._content or bankFrame
    while #slotButtons < count do
        local w = CreateBankSlot(parent, S().slotSize or 40)
        w:Hide()
        slotButtons[#slotButtons + 1] = w
    end
end

-- =====================================
-- UPDATE A SLOT (data -> visual)
-- =====================================

local function UpdateSlot(wrapper, item)
    if not wrapper then return end
    local btn = wrapper.btn
    if not btn then return end
    local s = S()

    btn:Show()
    wrapper:SetID(item.bagID)
    btn:SetID(item.slotIndex)

    if item.hasItem and item.icon and btn._icon then
        btn._icon:SetTexture(item.icon)
        btn._icon:Show()
        SetQualityBorder(btn, item.quality)

        if s.showQuantityBadges and item.count and item.count > 1 then
            btn._qtyText:SetText(tostring(item.count))
            btn._qtyText:SetTextColor(1, 1, 1, 1)
            btn._qtyText:Show()
        else
            btn._qtyText:Hide()
        end

        if s.showCooldowns and btn._cooldown then
            local start, dur, en = C_Container.GetContainerItemCooldown(item.bagID, item.slotIndex)
            if start and dur and dur > 0 and en == 1 then
                btn._cooldown:SetCooldown(start, dur); btn._cooldown:Show()
            else
                btn._cooldown:Hide()
            end
        elseif btn._cooldown then
            btn._cooldown:Hide()
        end

        local desat, alpha = false, 1
        if item.locked then
            desat, alpha = true, 0.4
        elseif currentFilter ~= "" then
            local m = (item.name or ""):lower():find(currentFilter, 1, true)
            desat = not m; alpha = m and 1 or 0.3
        end
        btn._icon:SetDesaturated(desat)
        btn._icon:SetAlpha(alpha)

        if s.showItemLevel and btn._ilvlBadge then
            if item.ilvl and (item.classID == 2 or item.classID == 4) then
                btn._ilvlBadge:SetText(tostring(item.ilvl)); btn._ilvlBadge:Show()
            else btn._ilvlBadge:Hide() end
        elseif btn._ilvlBadge then btn._ilvlBadge:Hide() end

        if s.showJunkIcon and btn._junkIcon then
            btn._junkIcon:SetShown((item.quality or 0) == 0)
        elseif btn._junkIcon then btn._junkIcon:Hide() end

        if btn._qualIcon then
            local atlas = item.craftingQuality and CRAFTING_QUALITY_ATLAS[item.craftingQuality]
            if atlas then btn._qualIcon:SetAtlas(atlas, false); btn._qualIcon:SetSize(14, 14); btn._qualIcon:Show()
            else btn._qualIcon:Hide() end
        end
    else
        if btn._icon then btn._icon:SetTexture(nil); btn._icon:Hide(); btn._icon:SetDesaturated(false); btn._icon:SetAlpha(1) end
        btn._qtyText:Hide()
        if btn._cooldown then btn._cooldown:Hide() end
        if btn._ilvlBadge then btn._ilvlBadge:Hide() end
        if btn._qualIcon then btn._qualIcon:Hide() end
        if btn._junkIcon then btn._junkIcon:Hide() end
        for _, t in ipairs(btn._qualBorders) do
            t:SetColorTexture(SLOT_BORDER[1], SLOT_BORDER[2], SLOT_BORDER[3], 0.2)
        end
    end
end

-- =====================================
-- COLLECT BANK ITEMS (selected type, all tabs)
-- =====================================

local SORT_FUNCS = {
    quality = function(a, b)
        if (a.quality or 0) ~= (b.quality or 0) then return (a.quality or 0) > (b.quality or 0) end
        return (a.name or "") < (b.name or "")
    end,
    name = function(a, b) return (a.name or "") < (b.name or "") end,
    ilvl = function(a, b)
        if (a.ilvl or 0) ~= (b.ilvl or 0) then return (a.ilvl or 0) > (b.ilvl or 0) end
        return (a.name or "") < (b.name or "")
    end,
}

local function CollectBankItems()
    wipe(_items)
    local bankType = CurrentBankType()
    local bagIDs = GetTabBagIDs(bankType)
    for _, bagID in ipairs(bagIDs) do
        local numSlots = C_Container.GetContainerNumSlots(bagID)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bagID, slot)
            local entry = {
                bagID = bagID, slotIndex = slot,
                hasItem = info ~= nil,
                itemLink = info and info.hyperlink,
                info = info,
            }
            if info then
                entry.icon = info.iconFileID
                entry.count = info.stackCount or 1
                entry.quality = info.quality
                entry.locked = info.isLocked
                entry.itemID = info.itemID
                local nm, _, _, ilvl, _, _, _, _, _, _, _, classID = nil, nil, nil, nil
                if info.hyperlink then
                    local gname, _, _, gilvl = GetItemInfo(info.hyperlink)
                    nm = gname; ilvl = gilvl
                end
                entry.name = nm
                entry.ilvl = ilvl
                local _, _, _, _, _, cid = GetItemInfoInstant(info.itemID or info.hyperlink or 0)
                entry.classID = cid
                if C_TradeSkillUI and C_TradeSkillUI.GetItemCraftedQualityByItemInfo and info.hyperlink then
                    entry.craftingQuality = C_TradeSkillUI.GetItemCraftedQualityByItemInfo(info.hyperlink)
                end
            end
            _items[#_items + 1] = entry
        end
    end
    return _items
end

-- =====================================
-- SIDEBAR (category filter; reuses TomoMod_BagCategories)
-- Advanced interactions (drag-reorder, rename/group menus, pin/assign modes)
-- are deferred to BagSidebar.lua, which will become the shared rich sidebar.
-- =====================================

-- Categories shown in the bank sidebar exclude the bag-only virtual buckets.
local function BankSidebarCategories()
    local out = {}
    local bc = BC()
    if not bc then return out end
    local cats = bc:GetCategories()
    for i, cat in ipairs(cats) do
        if not (cat.isPinned or cat.isRecent or cat.isReagentBag) then
            out[#out + 1] = { index = i, cat = cat }
        end
    end
    return out
end

local function CreateSidebar(f)
    local sb = CreateFrame("Frame", nil, f)
    sb:SetWidth(SIDEBAR_W)
    local bg = sb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(SIDEBAR_BG[1], SIDEBAR_BG[2], SIDEBAR_BG[3], 1)
    local sep = sb:CreateTexture(nil, "BORDER")
    sep:SetColorTexture(SEPARATOR[1], SEPARATOR[2], SEPARATOR[3], 1)
    sep:SetPoint("TOPRIGHT"); sep:SetPoint("BOTTOMRIGHT"); sep:SetWidth(1)
    sb._buttons = {}
    f._sidebar = sb
    return sb
end

local function MakeSidebarButton(sb, idx)
    local b = CreateFrame("Button", nil, sb)
    b:SetSize(34, 34)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(SLOT_BG[1], SLOT_BG[2], SLOT_BG[3], 0)
    b._bg = bg
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 3, -3); icon:SetPoint("BOTTOMRIGHT", -3, 3)
    b._icon = icon
    b._sel = CreateBorders(b, ACCENT[1], ACCENT[2], ACCENT[3], 1, "OVERLAY")
    for _, t in ipairs(b._sel) do t:Hide() end
    local high = b:CreateTexture(nil, "HIGHLIGHT")
    high:SetAllPoints(); high:SetColorTexture(1, 1, 1, 0.10); high:SetBlendMode("ADD")
    sb._buttons[idx] = b
    return b
end

local function UpdateSidebar()
    if not bankFrame or not bankFrame._sidebar then return end
    local sb = bankFrame._sidebar
    local list = BankSidebarCategories()

    -- "All" button (index 0)
    local allBtn = sb._buttons[0]
    if not allBtn then
        allBtn = CreateFrame("Button", nil, sb)
        allBtn:SetSize(34, 34)
        local bg = allBtn:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints()
        bg:SetColorTexture(SLOT_BG[1], SLOT_BG[2], SLOT_BG[3], 0); allBtn._bg = bg
        local icon = allBtn:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 3, -3); icon:SetPoint("BOTTOMRIGHT", -3, 3)
        SafeSetIcon(icon, "bags-icon-addslots", true)
        allBtn._icon = icon
        allBtn._sel = CreateBorders(allBtn, ACCENT[1], ACCENT[2], ACCENT[3], 1, "OVERLAY")
        for _, t in ipairs(allBtn._sel) do t:Hide() end
        local high = allBtn:CreateTexture(nil, "HIGHLIGHT"); high:SetAllPoints()
        high:SetColorTexture(1, 1, 1, 0.10); high:SetBlendMode("ADD")
        allBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(CN("bagcat_all", "All Items")); GameTooltip:Show()
        end)
        allBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        allBtn:SetScript("OnClick", function()
            selectedCategoryIndex = nil
            UpdateSidebar()
            BANK.Refresh()
        end)
        sb._buttons[0] = allBtn
    end
    allBtn:ClearAllPoints()
    allBtn:SetPoint("TOP", sb, "TOP", 0, -5)
    for _, t in ipairs(allBtn._sel) do t:SetShown(selectedCategoryIndex == nil) end
    allBtn:Show()

    local prev = allBtn
    local shown = {}
    for n, entry in ipairs(list) do
        local b = sb._buttons[n] or MakeSidebarButton(sb, n)
        b._catIndex = entry.index
        SafeSetIcon(b._icon, entry.cat.icon, entry.cat.isAtlas)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(entry.cat.name); GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        b:SetScript("OnClick", function(self)
            selectedCategoryIndex = self._catIndex
            UpdateSidebar()
            BANK.Refresh()
        end)
        for _, t in ipairs(b._sel) do t:SetShown(selectedCategoryIndex == entry.index) end
        b:ClearAllPoints()
        b:SetPoint("TOP", prev, "BOTTOM", 0, -4)
        b:Show()
        prev = b
        shown[n] = true
    end
    -- Hide leftover buttons
    for n, b in pairs(sb._buttons) do
        if type(n) == "number" and n > 0 and not shown[n] then b:Hide() end
    end
end

-- =====================================
-- LAYOUT GRID
-- =====================================

local function MatchesFilter(item)
    if currentFilter == "" then return true end
    return (item.name or ""):lower():find(currentFilter, 1, true) ~= nil
end

local function GetSectionHeader(content, n)
    content._headers = content._headers or {}
    local h = content._headers[n]
    if not h then
        h = CreateFrame("Frame", nil, content)
        h:SetHeight(SECTION_HDR_H)
        local bg = h:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(); bg:SetColorTexture(SECTION_HDR_BG[1], SECTION_HDR_BG[2], SECTION_HDR_BG[3], 1)
        local txt = h:CreateFontString(nil, "OVERLAY")
        txt:SetFont(ADDON_FONT_BOLD, 10, "")
        txt:SetPoint("LEFT", 6, 0)
        txt:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
        h._text = txt
        content._headers[n] = h
    end
    h:Show()
    return h
end

local function HideUnusedHeaders(content, used)
    if not content._headers then return end
    for n, h in ipairs(content._headers) do
        if n > used then h:Hide() end
    end
end

local function LayoutGrid()
    if not bankFrame or not bankFrame._content then return end
    if not IsBankAvailable() then return end
    local s = S()
    local content = bankFrame._content
    local size = s.slotSize or 40
    local spX = s.slotSpacingX or 5
    local spY = s.slotSpacingY or 5
    local width = content:GetWidth()
    if not width or width < 10 then width = (s.bankWidth or 460) - SIDEBAR_W end
    local cols = ColCount(size, spX, width)

    local items = CollectBankItems()
    local bc = BC()
    if bc then bc:ClassifyAll(items) end

    ResetSlotPool()
    local usedHeaders = 0
    local y = -SIDE_PAD
    local startX = SIDE_PAD

    local function placeRow(list)
        -- place a flat list of items into a grid starting at current y
        local i = 1
        while i <= #list do
            local rowMax = math.min(cols, #list - i + 1)
            for c = 0, rowMax - 1 do
                local item = list[i + c]
                local w = AcquireSlot(content, size)
                if w then
                    w:ClearAllPoints()
                    w:SetPoint("TOPLEFT", content, "TOPLEFT", startX + c * (size + spX), y)
                    UpdateSlot(w, item)
                end
            end
            y = y - (size + spY)
            i = i + cols
        end
    end

    if selectedCategoryIndex == nil then
        -- ALL: group by category with headers, in category display order
        local cats = bc and bc:GetCategories() or {}
        local buckets = {}
        for _, item in ipairs(items) do
            if item.hasItem and MatchesFilter(item) then
                local ci = item.categoryIndex
                if ci then
                    buckets[ci] = buckets[ci] or {}
                    buckets[ci][#buckets[ci] + 1] = item
                end
            end
        end
        local sortFn = SORT_FUNCS[s.sortMode or "quality"]
        for ci, cat in ipairs(cats) do
            if not (cat.isPinned or cat.isRecent or cat.isReagentBag) then
                local list = buckets[ci]
                if list and #list > 0 then
                    if sortFn then table.sort(list, sortFn) end
                    usedHeaders = usedHeaders + 1
                    local hdr = GetSectionHeader(content, usedHeaders)
                    hdr:ClearAllPoints()
                    hdr:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
                    hdr:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
                    hdr._text:SetText(cat.name .. "  |cff666677" .. #list .. "|r")
                    y = y - SECTION_HDR_H - 3
                    placeRow(list)
                    y = y - 4
                end
            end
        end
    else
        -- Single category: flat grid
        local list = {}
        for _, item in ipairs(items) do
            if item.hasItem and item.categoryIndex == selectedCategoryIndex and MatchesFilter(item) then
                list[#list + 1] = item
            end
        end
        local sortFn = SORT_FUNCS[s.sortMode or "quality"]
        if sortFn then table.sort(list, sortFn) end
        placeRow(list)
    end

    HideUnusedSlots()
    HideUnusedHeaders(content, usedHeaders)

    local totalH = math.abs(y) + SIDE_PAD
    content:SetHeight(math.max(totalH, 10))
end

-- =====================================
-- MONEY INPUT / TAB PURCHASE POPUPS
-- =====================================

local function RegisterPopups()
    if not StaticPopupDialogs then return end
    StaticPopupDialogs["TOMOMOD_BANK_DEPOSIT"] = {
        text = CN("bank_deposit_prompt", "Deposit how much gold into the Warband bank?"),
        button1 = ACCEPT, button2 = CANCEL,
        hasEditBox = true, maxLetters = 10,
        OnShow = function(self) self.editBox:SetText(""); self.editBox:SetFocus() end,
        OnAccept = function(self)
            local g = tonumber(self.editBox:GetText())
            if g and g > 0 and BANK_ACCOUNT then BankCall("DepositMoney", BANK_ACCOUNT, g * 10000) end
        end,
        EditBoxOnEnterPressed = function(self)
            local p = self:GetParent()
            local g = tonumber(self:GetText())
            if g and g > 0 and BANK_ACCOUNT then BankCall("DepositMoney", BANK_ACCOUNT, g * 10000) end
            p:Hide()
        end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopupDialogs["TOMOMOD_BANK_WITHDRAW"] = {
        text = CN("bank_withdraw_prompt", "Withdraw how much gold from the Warband bank?"),
        button1 = ACCEPT, button2 = CANCEL,
        hasEditBox = true, maxLetters = 10,
        OnShow = function(self) self.editBox:SetText(""); self.editBox:SetFocus() end,
        OnAccept = function(self)
            local g = tonumber(self.editBox:GetText())
            if g and g > 0 and BANK_ACCOUNT then BankCall("WithdrawMoney", BANK_ACCOUNT, g * 10000) end
        end,
        EditBoxOnEnterPressed = function(self)
            local p = self:GetParent()
            local g = tonumber(self:GetText())
            if g and g > 0 and BANK_ACCOUNT then BankCall("WithdrawMoney", BANK_ACCOUNT, g * 10000) end
            p:Hide()
        end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopupDialogs["TOMOMOD_BANK_BUYTAB"] = {
        text = CN("bank_buytab_prompt", "Purchase a new bank tab?"),
        button1 = YES, button2 = NO,
        OnAccept = function()
            BankCall("PurchaseBankTab", CurrentBankType())
        end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
end

-- =====================================
-- FOOTER (gold + bank actions)
-- =====================================

local function UpdateFooter()
    if not bankFrame or not bankFrame._footer then return end
    local bankType = CurrentBankType()

    -- Player gold (always)
    bankFrame._goldText:SetText(FormatGold(GetMoney()))

    -- Warband banked gold + deposit/withdraw (only when supported)
    local moneyTransfer = false
    if C_Bank and C_Bank.DoesBankTypeSupportMoneyTransfer then
        moneyTransfer = BankCall("DoesBankTypeSupportMoneyTransfer", bankType) and true or false
    elseif bankType == BANK_ACCOUNT then
        moneyTransfer = true
    end
    if moneyTransfer then
        local banked = BankCall("FetchDepositedMoney", bankType) or 0
        bankFrame._bankGoldText:SetText("|cff8888aa" .. CN("bank_warband_gold", "Warband") .. ":|r " .. FormatGold(banked))
        bankFrame._bankGoldText:Show()
        bankFrame._depositBtn:Show()
        bankFrame._withdrawBtn:Show()
    else
        bankFrame._bankGoldText:Hide()
        bankFrame._depositBtn:Hide()
        bankFrame._withdrawBtn:Hide()
    end

    -- Buy tab (only when not maxed and a next tab is purchasable)
    local canBuy = false
    if C_Bank then
        local maxed = false
        if C_Bank.HasMaxBankTabs then maxed = BankCall("HasMaxBankTabs", bankType) and true or false end
        if not maxed and C_Bank.FetchNextPurchasableBankTabData then
            local data = BankCall("FetchNextPurchasableBankTabData", bankType)
            if data then canBuy = true end
        end
    end
    bankFrame._buyTabBtn:SetShown(canBuy)

    -- Deposit reagents (only when the type supports auto-deposit)
    local autoDep = false
    if C_Bank and C_Bank.DoesBankTypeSupportAutoDeposit then
        autoDep = BankCall("DoesBankTypeSupportAutoDeposit", bankType) and true or false
    end
    bankFrame._depositReagentsBtn:SetShown(autoDep and C_Bank and C_Bank.AutoDepositItemsIntoBank ~= nil)
end

-- =====================================
-- TYPE TOGGLE BAR
-- =====================================

local function UpdateTypeBar()
    if not bankFrame or not bankFrame._typeBar then return end
    local sel = S().bankSelectedType or "character"
    local charBtn = bankFrame._typeBar._charBtn
    local wbBtn = bankFrame._typeBar._wbBtn

    local function style(btn, active)
        if active then
            btn._bg:SetColorTexture(ACCENT[1] * 0.20, ACCENT[2] * 0.20, ACCENT[3] * 0.20, 0.9)
            btn._txt:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
        else
            btn._bg:SetColorTexture(SLOT_BG[1], SLOT_BG[2], SLOT_BG[3], 0.5)
            btn._txt:SetTextColor(MUTED_TEXT[1], MUTED_TEXT[2], MUTED_TEXT[3], 1)
        end
    end
    style(charBtn, sel == "character")

    local wbViewable = IsTypeViewable(BANK_ACCOUNT)
    wbBtn:SetShown(wbViewable)
    if wbViewable then style(wbBtn, sel == "account") end
end

-- =====================================
-- FRAME CREATION
-- =====================================

local function MakeHeaderButton(parent, label, size)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size or 22, size or 22)
    local txt = b:CreateFontString(nil, "OVERLAY")
    txt:SetFont(ADDON_FONT_BOLD, 14, "")
    txt:SetPoint("CENTER")
    txt:SetTextColor(MUTED_TEXT[1], MUTED_TEXT[2], MUTED_TEXT[3])
    txt:SetText(label)
    b._txt = txt
    b:SetScript("OnEnter", function() txt:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3]) end)
    b:SetScript("OnLeave", function() txt:SetTextColor(MUTED_TEXT[1], MUTED_TEXT[2], MUTED_TEXT[3]) end)
    return b
end

local function MakeActionButton(parent, label)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    if not b.SetBackdrop then Mixin(b, BackdropTemplateMixin) end
    b:SetSize(70, 20)
    b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    b:SetBackdropColor(ACCENT[1] * 0.15, ACCENT[2] * 0.15, ACCENT[3] * 0.15, 0.85)
    b:SetBackdropBorderColor(ACCENT[1] * 0.5, ACCENT[2] * 0.5, ACCENT[3] * 0.5, 0.8)
    local txt = b:CreateFontString(nil, "OVERLAY")
    txt:SetFont(ADDON_FONT, 10, ""); txt:SetPoint("CENTER")
    txt:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3]); txt:SetText(label)
    b._txt = txt
    b:SetScript("OnEnter", function() b:SetBackdropColor(ACCENT[1] * 0.3, ACCENT[2] * 0.3, ACCENT[3] * 0.3, 0.95) end)
    b:SetScript("OnLeave", function() b:SetBackdropColor(ACCENT[1] * 0.15, ACCENT[2] * 0.15, ACCENT[3] * 0.15, 0.85) end)
    return b
end

local function CreateBankFrame()
    if bankFrame then return bankFrame end
    local s = S()

    local f = CreateFrame("Frame", "TomoMod_BagBank_Main", UIParent, "BackdropTemplate")
    if not f.SetBackdrop then Mixin(f, BackdropTemplateMixin) end
    f:SetSize(s.bankWidth or 460, 480)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:SetClampedToScreen(true)

    local pos = s.bankPosition or { anchor = "CENTER", relTo = "CENTER", x = 0, y = 0 }
    f:SetPoint(pos.anchor, UIParent, pos.relTo, pos.x, pos.y)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], (s.opacity or 92) / 100)
    f._bg = bg
    CreateBorders(f, BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], 1, "BORDER")

    -- ===== Header =====
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT"); header:SetPoint("TOPRIGHT")
    header:SetHeight(HEADER_H)
    local hbg = header:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints(); hbg:SetColorTexture(HEADER_BG[1], HEADER_BG[2], HEADER_BG[3], 1)

    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont(ADDON_FONT_BOLD, 13, "")
    title:SetPoint("LEFT", 10, 0)
    title:SetText("|cff0cd29f" .. CN("bank_title", "Bank") .. "|r")

    local closeBtn = MakeHeaderButton(header, "×", 22)
    closeBtn._txt:SetFont(ADDON_FONT_BOLD, 18, "")
    closeBtn:SetPoint("RIGHT", -6, 0)
    closeBtn:SetScript("OnClick", function()
        if CloseBankFrame then CloseBankFrame() end
        f:Hide()
    end)

    local sortBtn = MakeHeaderButton(header, "⇅", 22)
    sortBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)
    sortBtn:SetScript("OnEnter", function() sortBtn._txt:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
        GameTooltip:SetOwner(sortBtn, "ANCHOR_TOP"); GameTooltip:SetText(CN("bank_sort", "Sort bank")); GameTooltip:Show() end)
    sortBtn:SetScript("OnLeave", function() sortBtn._txt:SetTextColor(MUTED_TEXT[1], MUTED_TEXT[2], MUTED_TEXT[3]); GameTooltip:Hide() end)
    sortBtn:SetScript("OnClick", function()
        local bankType = CurrentBankType()
        if bankType == BANK_ACCOUNT then
            if C_Container and C_Container.SortAccountBankBags then pcall(C_Container.SortAccountBankBags)
            elseif C_Container and C_Container.SortBankBags then pcall(C_Container.SortBankBags) end
        else
            if C_Container and C_Container.SortBankBags then pcall(C_Container.SortBankBags) end
        end
        C_Timer.After(0.4, LayoutGrid)
    end)

    f._header = header

    -- ===== Type toggle bar =====
    local typeBar = CreateFrame("Frame", nil, f)
    typeBar:SetPoint("TOPLEFT", 0, -HEADER_H)
    typeBar:SetPoint("TOPRIGHT", 0, -HEADER_H)
    typeBar:SetHeight(TYPEBAR_H)
    local tbg = typeBar:CreateTexture(nil, "BACKGROUND")
    tbg:SetAllPoints(); tbg:SetColorTexture(BG_COLOR[1] * 1.3, BG_COLOR[2] * 1.3, BG_COLOR[3] * 1.3, 1)

    local function makeTypeBtn(labelKey, fallback, value)
        local b = CreateFrame("Button", nil, typeBar)
        b:SetSize(96, 18)
        local bbg = b:CreateTexture(nil, "BACKGROUND"); bbg:SetAllPoints()
        bbg:SetColorTexture(SLOT_BG[1], SLOT_BG[2], SLOT_BG[3], 0.5); b._bg = bbg
        local txt = b:CreateFontString(nil, "OVERLAY")
        txt:SetFont(ADDON_FONT_BOLD, 10, ""); txt:SetPoint("CENTER")
        txt:SetText(CN(labelKey, fallback)); b._txt = txt
        b:SetScript("OnClick", function()
            local db = TomoModDB and TomoModDB.bagSkin
            if db then db.bankSelectedType = value end
            selectedCategoryIndex = nil
            UpdateTypeBar(); UpdateSidebar(); BANK.Refresh()
        end)
        return b
    end
    typeBar._charBtn = makeTypeBtn("bank_tab_character", "Character", "character")
    typeBar._charBtn:SetPoint("LEFT", 8, 0)
    typeBar._wbBtn = makeTypeBtn("bank_tab_warband", "Warband", "account")
    typeBar._wbBtn:SetPoint("LEFT", typeBar._charBtn, "RIGHT", 4, 0)
    f._typeBar = typeBar

    -- ===== Search =====
    local searchFrame = CreateFrame("Frame", nil, f)
    searchFrame:SetPoint("TOPLEFT", 0, -(HEADER_H + TYPEBAR_H))
    searchFrame:SetPoint("TOPRIGHT", 0, -(HEADER_H + TYPEBAR_H))
    searchFrame:SetHeight(SEARCH_H)
    local sbg = searchFrame:CreateTexture(nil, "BACKGROUND")
    sbg:SetAllPoints(); sbg:SetColorTexture(SEARCH_BG[1], SEARCH_BG[2], SEARCH_BG[3], 1)
    local eb = CreateFrame("EditBox", nil, searchFrame)
    eb:SetFont(ADDON_FONT, 11, "")
    eb:SetPoint("LEFT", 10, 0); eb:SetPoint("RIGHT", -10, 0); eb:SetHeight(SEARCH_H - 6)
    eb:SetAutoFocus(false)
    eb:SetTextColor(0.9, 0.9, 0.9)
    eb:SetScript("OnTextChanged", function(self)
        currentFilter = (self:GetText() or ""):lower()
        if self:GetText() == "" then self._ph:Show() else self._ph:Hide() end
        LayoutGrid()
    end)
    eb:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    local ph = searchFrame:CreateFontString(nil, "OVERLAY")
    ph:SetFont(ADDON_FONT, 11, "")
    ph:SetPoint("LEFT", 10, 0)
    ph:SetTextColor(MUTED_TEXT[1], MUTED_TEXT[2], MUTED_TEXT[3])
    ph:SetText(CN("bagskin_search", "Search..."))
    eb._ph = ph
    f._searchFrame = searchFrame
    f._searchBox = eb

    -- ===== Sidebar =====
    local sidebar = CreateSidebar(f)
    sidebar:SetPoint("TOPLEFT", 0, -(HEADER_H + TYPEBAR_H + SEARCH_H))
    sidebar:SetPoint("BOTTOMLEFT", 0, FOOTER_H)

    -- ===== Scroll + content =====
    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:SetPoint("TOPLEFT", SIDEBAR_W, -(HEADER_H + TYPEBAR_H + SEARCH_H))
    scroll:SetPoint("BOTTOMRIGHT", 0, FOOTER_H)
    f._scrollFrame = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth((s.bankWidth or 460) - SIDEBAR_W)
    content:SetHeight(10)
    scroll:SetScrollChild(content)
    f._content = content

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local maxS = math.max(0, content:GetHeight() - self:GetHeight())
        local new = math.min(maxS, math.max(0, cur - delta * 40))
        self:SetVerticalScroll(new)
    end)

    -- ===== Footer =====
    local footer = CreateFrame("Frame", nil, f)
    footer:SetPoint("BOTTOMLEFT"); footer:SetPoint("BOTTOMRIGHT")
    footer:SetHeight(FOOTER_H)
    local fbg = footer:CreateTexture(nil, "BACKGROUND")
    fbg:SetAllPoints(); fbg:SetColorTexture(HEADER_BG[1], HEADER_BG[2], HEADER_BG[3], 1)

    local goldText = footer:CreateFontString(nil, "OVERLAY")
    goldText:SetFont(ADDON_FONT, 11, "")
    goldText:SetPoint("LEFT", 10, 0)
    footer._goldText = goldText
    f._goldText = goldText

    local bankGoldText = footer:CreateFontString(nil, "OVERLAY")
    bankGoldText:SetFont(ADDON_FONT, 10, "")
    bankGoldText:SetPoint("LEFT", goldText, "RIGHT", 14, 0)
    bankGoldText:Hide()
    f._bankGoldText = bankGoldText

    local buyTabBtn = MakeActionButton(footer, CN("bank_buytab", "Buy Tab"))
    buyTabBtn:SetPoint("RIGHT", -8, 0)
    buyTabBtn:SetScript("OnClick", function()
        if StaticPopup_Show then StaticPopup_Show("TOMOMOD_BANK_BUYTAB") end
    end)
    buyTabBtn:Hide()
    f._buyTabBtn = buyTabBtn

    local depositReagentsBtn = MakeActionButton(footer, CN("bank_deposit_reagents", "Reagents"))
    depositReagentsBtn:SetWidth(78)
    depositReagentsBtn:SetPoint("RIGHT", buyTabBtn, "LEFT", -6, 0)
    depositReagentsBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(ACCENT[1] * 0.3, ACCENT[2] * 0.3, ACCENT[3] * 0.3, 0.95)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(CN("bank_deposit_reagents_tip", "Deposit all reagents")); GameTooltip:Show()
    end)
    depositReagentsBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(ACCENT[1] * 0.15, ACCENT[2] * 0.15, ACCENT[3] * 0.15, 0.85); GameTooltip:Hide()
    end)
    depositReagentsBtn:SetScript("OnClick", function()
        BankCall("AutoDepositItemsIntoBank", CurrentBankType())
    end)
    depositReagentsBtn:Hide()
    f._depositReagentsBtn = depositReagentsBtn

    local withdrawBtn = MakeActionButton(footer, CN("bank_withdraw", "Withdraw"))
    withdrawBtn:SetWidth(64)
    withdrawBtn:SetPoint("RIGHT", depositReagentsBtn, "LEFT", -6, 0)
    withdrawBtn:SetScript("OnClick", function()
        if StaticPopup_Show then StaticPopup_Show("TOMOMOD_BANK_WITHDRAW") end
    end)
    withdrawBtn:Hide()
    f._withdrawBtn = withdrawBtn

    local depositBtn = MakeActionButton(footer, CN("bank_deposit", "Deposit"))
    depositBtn:SetWidth(64)
    depositBtn:SetPoint("RIGHT", withdrawBtn, "LEFT", -6, 0)
    depositBtn:SetScript("OnClick", function()
        if StaticPopup_Show then StaticPopup_Show("TOMOMOD_BANK_DEPOSIT") end
    end)
    depositBtn:Hide()
    f._depositBtn = depositBtn

    f._footer = footer

    -- ===== Drag =====
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local db = TomoModDB and TomoModDB.bagSkin
        if db then
            local pt, _, rel, x, y = f:GetPoint(1)
            db.bankPosition = { anchor = pt, relTo = rel, x = x, y = y }
        end
    end)

    tinsert(UISpecialFrames, "TomoMod_BagBank_Main")

    f:Hide()
    bankFrame = f
    return f
end

-- =====================================
-- REFRESH (full repaint)
-- =====================================

function BANK.Refresh()
    if not bankFrame or not bankFrame:IsShown() then return end
    UpdateTypeBar()
    UpdateSidebar()
    LayoutGrid()
    UpdateFooter()
end

local function ScheduleRefresh(delay)
    if _layoutPending then return end
    _layoutPending = true
    C_Timer.After(delay or 0.1, function()
        _layoutPending = false
        BANK.Refresh()
    end)
end

-- =====================================
-- BLIZZARD BANK SUPPRESSION (reparent, no Show/Hide hooks)
-- =====================================

local _blizzBankHider
local _blizzBankHooked = false

local function HideBlizzardBank()
    if _blizzBankHooked then return end
    _blizzBankHooked = true
    if not _blizzBankHider then
        _blizzBankHider = CreateFrame("Frame")
        _blizzBankHider:Hide()
    end
    -- Reparent the live bank frames to a hidden frame. Blizzard keeps updating
    -- them; they simply never render. No Show/Hide hooks -> no taint surface.
    for _, fname in ipairs({ "BankFrame", "BankPanel", "AccountBankPanel" }) do
        local bf = _G[fname]
        if bf and not bf._tmReparented then
            bf._tmReparented = true
            bf._tmOrigParent = bf:GetParent()
            bf:SetParent(_blizzBankHider)
        end
    end
end

-- =====================================
-- LIFECYCLE / EVENTS
-- =====================================

local function OnBankOpened()
    if not IsEnabled() then return end
    HideBlizzardBank()
    if not bankFrame then CreateBankFrame() end
    PrewarmPool(98)
    if S().bankAutoDeposit and C_Bank and C_Bank.AutoDepositItemsIntoBank then
        BankCall("AutoDepositItemsIntoBank", CurrentBankType())
    end
    bankFrame:Show()
    BANK.Refresh()
end

local function OnBankClosed()
    if bankFrame then bankFrame:Hide() end
end

local function InstallHooks()
    if hooksInstalled then return end
    hooksInstalled = true

    local events = CreateFrame("Frame")
    events:RegisterEvent("BANKFRAME_OPENED")
    events:RegisterEvent("BANKFRAME_CLOSED")
    events:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    events:RegisterEvent("PLAYER_MONEY")
    events:RegisterEvent("ITEM_LOCK_CHANGED")
    events:RegisterEvent("BAG_UPDATE_DELAYED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    -- Guarded optional events (may not exist on all builds)
    pcall(function() events:RegisterEvent("ACCOUNT_MONEY") end)
    pcall(function() events:RegisterEvent("BANK_TABS_CHANGED") end)
    pcall(function() events:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED") end)
    pcall(function() events:RegisterEvent("BANK_TAB_SETTINGS_UPDATED") end)

    events:SetScript("OnEvent", function(_, event, ...)
        if event == "BANKFRAME_OPENED" then
            OnBankOpened()
            return
        elseif event == "BANKFRAME_CLOSED" then
            OnBankClosed()
            return
        end

        if event == "PLAYER_REGEN_ENABLED" then
            if _deferredRefresh and bankFrame and bankFrame:IsShown() then
                _deferredRefresh = false
                BANK.Refresh()
            end
            return
        end

        if not bankFrame or not bankFrame:IsShown() then return end

        if event == "PLAYER_MONEY" or event == "ACCOUNT_MONEY" then
            UpdateFooter()
            return
        end

        ScheduleRefresh(0.1)
    end)
end

-- =====================================
-- MOVERS
-- =====================================

local function RegisterWithMovers()
    if not TomoMod_Movers or not TomoMod_Movers.RegisterEntry then return end
    TomoMod_Movers.RegisterEntry({
        label = "Bank Skin",
        unlock = function()
            if bankFrame then bankFrame:SetMovable(true); bankFrame:EnableMouse(true) end
        end,
        lock = function()
            if bankFrame then
                local db = TomoModDB and TomoModDB.bagSkin
                if db then
                    local pt, _, rel, x, y = bankFrame:GetPoint(1)
                    db.bankPosition = { anchor = pt, relTo = rel, x = x, y = y }
                end
            end
        end,
        isActive = function() return IsEnabled() end,
    })
end

-- =====================================
-- PUBLIC API
-- =====================================

function BANK.ApplySettings()
    if not bankFrame then return end
    local s = S()
    bankFrame:SetScale((s.bankScale or s.scale or 100) / 100)
    bankFrame._bg:SetColorTexture(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], (s.opacity or 92) / 100)
    if bankFrame._searchFrame then
        bankFrame._searchFrame:SetShown(s.showSearchBar ~= false)
    end
    if bankFrame:IsShown() then BANK.Refresh() end
end

function BANK.SetEnabled(enabled)
    local db = TomoModDB and TomoModDB.bagSkin
    if db then db.bankEnabled = enabled end
    if enabled then
        if not bankFrame and S().enabled then CreateBankFrame() end
        InstallHooks()
    else
        if bankFrame then bankFrame:Hide() end
    end
end

function BANK.Initialize()
    if isInitialized then return end
    isInitialized = true
    RegisterPopups()
    if not IsEnabled() then return end
    if not IsBankAvailable() then return end
    C_Timer.After(0.6, function()
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
    if TomoModDB and not TomoModDB.bagSkin then TomoModDB.bagSkin = {} end
    if TomoModDB and TomoModDB.bagSkin then
        local db = TomoModDB.bagSkin
        local D = {
            bankEnabled = true,
            bankSelectedType = "character",
            bankAutoDeposit = false,
            bankWidth = 460,
        }
        for k, v in pairs(D) do
            if db[k] == nil then db[k] = v end
        end
        if db.bankPosition == nil then
            db.bankPosition = { anchor = "CENTER", relTo = "CENTER", x = 0, y = 0 }
        end
    end
    BANK.Initialize()
end)

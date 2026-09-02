-- =====================================================================
-- BagSlots.lua — secure Blizzard item buttons rendered by TomoMod
-- =====================================================================

local Bags = TomoMod_BagSkin
if not Bags then return end

local Slots = {
    byKey = {},
    list = {},
}
Bags.RegisterModule("Slots", Slots)

local WHITE = "Interface\\Buttons\\WHITE8X8"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local NP_MEDIA = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Nameplates\\"
local EMPTY_BG_TEX = NP_MEDIA .. "background.png"
local EMPTY_BORDER_TEX = NP_MEDIA .. "border.png"
local ACCENT = { 0.18, 0.85, 0.52 }

local QUALITY = {
    [0] = { 0.45, 0.45, 0.48 },
    [1] = { 0.86, 0.86, 0.88 },
    [2] = { 0.12, 1.00, 0.00 },
    [3] = { 0.00, 0.44, 0.87 },
    [4] = { 0.64, 0.21, 0.93 },
    [5] = { 1.00, 0.50, 0.00 },
    [6] = { 0.90, 0.80, 0.50 },
    [7] = { 0.00, 0.80, 1.00 },
    [8] = { 0.00, 0.80, 1.00 },
}

local function AddEdge(parent, pointA, pointB, width, height)
    local tex = parent:CreateTexture(nil, "OVERLAY", nil, 7)
    tex:SetTexture(WHITE)
    tex:SetPoint(pointA)
    tex:SetPoint(pointB)
    if width then tex:SetWidth(width) end
    if height then tex:SetHeight(height) end
    return tex
end

local function BuildBorder(parent)
    return {
        AddEdge(parent, "TOPLEFT", "TOPRIGHT", nil, 2),
        AddEdge(parent, "BOTTOMLEFT", "BOTTOMRIGHT", nil, 2),
        AddEdge(parent, "TOPLEFT", "BOTTOMLEFT", 2, nil),
        AddEdge(parent, "TOPRIGHT", "BOTTOMRIGHT", 2, nil),
    }
end

local function SetBorder(border, r, g, b, a)
    for _, tex in ipairs(border) do
        tex:SetColorTexture(r, g, b, a or 1)
        tex:Show()
    end
end

local function ItemFor(wrapper)
    return Bags.Modules.Data and Bags.Modules.Data.byKey[wrapper.key]
end

local function ShowTooltip(button, wrapper)
    local item = ItemFor(wrapper)
    if not item or not item.hasItem then return end

    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if GameTooltip.SetBagItem then
        GameTooltip:SetBagItem(wrapper.bagID, wrapper.slotID)
    elseif item.link then
        GameTooltip:SetHyperlink(item.link)
    end
    GameTooltip:Show()
end

function Slots:CreatePhysicalSlot(bagID, slotID)
    local data = Bags.Modules.Data
    local key = data:Key(bagID, slotID)
    if self.byKey[key] then return self.byKey[key] end
    if InCombatLockdown and InCombatLockdown() then return nil end

    local content = Bags.Modules.Layout.content
    local size = Bags.GetDB().layout.slotSize or 38

    local wrapper = CreateFrame("Frame", nil, content)
    wrapper:SetSize(size, size)
    wrapper:SetID(bagID)
    wrapper:EnableMouse(false)

    -- The Blizzard template owns all protected bag actions. TomoMod only
    -- supplies visuals and an explicit tooltip. Keep it above every decorative
    -- region so hover/click/drag can never be swallowed by our renderer.
    local button = CreateFrame("ItemButton", nil, wrapper, "ContainerFrameItemButtonTemplate")
    button:SetAllPoints(wrapper)
    button:SetFrameLevel(wrapper:GetFrameLevel() + 10)
    button:SetID(slotID)
    button:EnableMouse(true)
    button:SetHitRectInsets(0, 0, 0, 0)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    button:RegisterForDrag("LeftButton")
    button:EnableMouseWheel(false)

    wrapper.button = button
    wrapper.key = key
    wrapper.bagID = bagID
    wrapper.slotID = slotID

    local bg = wrapper:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(WHITE)
    bg:SetColorTexture(0.04, 0.052, 0.056, 0.92)
    wrapper.bg = bg

    -- Existing TomoMod nameplate assets make empty slots readable without
    -- introducing another media set.
    local emptyBG = wrapper:CreateTexture(nil, "BORDER", nil, 1)
    emptyBG:SetPoint("TOPLEFT", 1, -1)
    emptyBG:SetPoint("BOTTOMRIGHT", -1, 1)
    emptyBG:SetTexture(EMPTY_BG_TEX)
    emptyBG:SetVertexColor(0.18, 0.22, 0.23, 0.55)
    emptyBG:Hide()
    wrapper.emptyBG = emptyBG

    local emptyBorder = wrapper:CreateTexture(nil, "BORDER", nil, 2)
    emptyBorder:SetAllPoints()
    emptyBorder:SetTexture(EMPTY_BORDER_TEX)
    emptyBorder:SetVertexColor(0.34, 0.40, 0.41, 0.70)
    emptyBorder:Hide()
    wrapper.emptyBorder = emptyBorder

    -- Do not depend on Blizzard's private visual region names. The secure
    -- button remains fully interactive while its native decoration is hidden.
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    if normal then normal:SetTexture(nil); normal:SetAlpha(0) end
    if button.NormalTexture then button.NormalTexture:SetAlpha(0) end
    if button.IconBorder then button.IconBorder:SetAlpha(0) end
    local nativeIcon = button.icon or button.IconTexture or button.Icon
    if nativeIcon then nativeIcon:SetAlpha(0) end
    local nativeCount = button.Count or button.count
    if nativeCount and nativeCount.SetAlpha then nativeCount:SetAlpha(0) end
    if button.NewItemTexture then button.NewItemTexture:Hide(); button.NewItemTexture:SetAlpha(0) end
    if button.BattlepayItemTexture then button.BattlepayItemTexture:Hide(); button.BattlepayItemTexture:SetAlpha(0) end
    if button.flash then button.flash:Hide(); button.flash:SetAlpha(0) end
    if button.newitemglowAnim then button.newitemglowAnim:Stop() end

    local itemIcon = button:CreateTexture(nil, "ARTWORK", nil, 1)
    itemIcon:SetPoint("TOPLEFT", 2, -2)
    itemIcon:SetPoint("BOTTOMRIGHT", -2, 2)
    itemIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    itemIcon:Hide()
    wrapper.itemIcon = itemIcon

    local hover = button:CreateTexture(nil, "HIGHLIGHT", nil, 6)
    hover:SetPoint("TOPLEFT", 1, -1)
    hover:SetPoint("BOTTOMRIGHT", -1, 1)
    hover:SetTexture(WHITE)
    hover:SetColorTexture(1, 1, 1, 0.12)
    hover:SetBlendMode("ADD")
    wrapper.hover = hover

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetPoint("TOPLEFT", itemIcon, "TOPLEFT")
    cooldown:SetPoint("BOTTOMRIGHT", itemIcon, "BOTTOMRIGHT")
    cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(false)
    cooldown:EnableMouse(false)
    cooldown:Hide()
    wrapper.cooldown = cooldown

    -- Text/borders live in a mouse-disabled frame above the cooldown swipe.
    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetAllPoints(button)
    overlay:SetFrameLevel(cooldown:GetFrameLevel() + 2)
    overlay:EnableMouse(false)
    wrapper.overlay = overlay

    local border = BuildBorder(overlay)
    SetBorder(border, 1, 1, 1, 0.12)
    wrapper.border = border

    local countText = overlay:CreateFontString(nil, "OVERLAY", nil, 7)
    countText:SetFont(FONT_BOLD, 10, "OUTLINE")
    countText:SetPoint("BOTTOMRIGHT", -3, 3)
    countText:SetTextColor(1, 1, 1, 1)
    countText:SetJustifyH("RIGHT")
    countText:Hide()
    wrapper.countText = countText

    local ilvl = overlay:CreateFontString(nil, "OVERLAY", nil, 7)
    ilvl:SetFont(FONT_BOLD, 9, "OUTLINE")
    ilvl:SetPoint("TOPLEFT", 3, -3)
    ilvl:SetTextColor(1.00, 0.88, 0.38, 1)
    ilvl:SetJustifyH("LEFT")
    wrapper.ilvl = ilvl

    local pin = overlay:CreateTexture(nil, "OVERLAY", nil, 7)
    pin:SetTexture(WHITE)
    pin:SetSize(6, 6)
    pin:SetPoint("TOPRIGHT", -3, -3)
    pin:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
    pin:Hide()
    wrapper.pin = pin

    -- Explicit tooltip handling means the V4 frame does not depend on any
    -- Blizzard container-parent implementation detail for mouse-over.
    button:SetScript("OnEnter", function(self)
        ShowTooltip(self, wrapper)
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:HookScript("OnMouseUp", function(_, mouseButton)
        if mouseButton ~= "MiddleButton" then return end
        local item = ItemFor(wrapper)
        if item and item.itemID then
            Bags.Modules.Data:TogglePinned(item.itemID)
        end
    end)

    self.byKey[key] = wrapper
    self.list[#self.list + 1] = wrapper
    return wrapper
end

function Slots:EnsurePool()
    if InCombatLockdown and InCombatLockdown() then
        Bags.State.layoutPending = true
        return
    end
    local data = Bags.Modules.Data
    for _, bagID in ipairs(data.BAG_IDS) do
        local slots = C_Container.GetContainerNumSlots(bagID) or 0
        for slotID = 1, slots do
            self:CreatePhysicalSlot(bagID, slotID)
        end
    end
end

function Slots:Render(wrapper, item)
    local button = wrapper.button
    if not button then return end

    button:SetID(wrapper.slotID)
    wrapper:SetID(wrapper.bagID)

    local size = Bags.GetDB().layout.slotSize or 38
    wrapper:SetSize(size, size)

    if not item or not item.hasItem then
        wrapper.itemIcon:SetTexture(nil)
        wrapper.itemIcon:Hide()
        wrapper.countText:SetText("")
        wrapper.countText:Hide()
        wrapper.cooldown:Hide()
        wrapper.bg:SetColorTexture(0.028, 0.038, 0.041, 0.94)
        wrapper.emptyBG:Show()
        wrapper.emptyBorder:Show()
        SetBorder(wrapper.border, 0.38, 0.44, 0.45, 0.38)
        wrapper.ilvl:SetText("")
        wrapper.pin:Hide()
        return
    end

    wrapper.emptyBG:Hide()
    wrapper.emptyBorder:Hide()

    wrapper.itemIcon:SetTexture(item.icon)
    wrapper.itemIcon:SetDesaturated(item.locked and true or false)
    wrapper.itemIcon:Show()

    local count = tonumber(item.count) or 1
    if count > 1 then
        wrapper.countText:SetText(count)
        wrapper.countText:Show()
    else
        wrapper.countText:SetText("")
        wrapper.countText:Hide()
    end

    if C_Container.GetContainerItemCooldown then
        local start, duration, enable = C_Container.GetContainerItemCooldown(item.bagID, item.slotID)
        start, duration = tonumber(start) or 0, tonumber(duration) or 0
        if duration > 0 and enable ~= 0 then
            if CooldownFrame_Set then
                CooldownFrame_Set(wrapper.cooldown, start, duration, true)
            elseif wrapper.cooldown.SetCooldown then
                wrapper.cooldown:SetCooldown(start, duration)
            end
            wrapper.cooldown:Show()
        else
            wrapper.cooldown:Hide()
        end
    else
        wrapper.cooldown:Hide()
    end

    wrapper.bg:SetColorTexture(0.020, 0.027, 0.030, 0.98)
    local db = Bags.GetDB().slots
    if db.qualityBorders ~= false then
        local c = QUALITY[item.quality or 0] or QUALITY[0]
        local alpha = (item.quality or 0) > 1 and 1.0 or 0.48
        SetBorder(wrapper.border, c[1], c[2], c[3], alpha)
    else
        SetBorder(wrapper.border, 1, 1, 1, 0.12)
    end

    if db.itemLevel ~= false and item.ilvl and item.ilvl > 0 then
        wrapper.ilvl:SetText(item.ilvl)
    else
        wrapper.ilvl:SetText("")
    end
    wrapper.pin:SetShown(Bags.Modules.Data:IsPinned(item.itemID))
end

function Slots:LayoutDisplay(items)
    if InCombatLockdown and InCombatLockdown() then
        Bags.State.layoutPending = true
        return
    end

    local db = Bags.GetDB()
    local ld = db.layout
    local columns = math.max(1, tonumber(ld.columns) or 12)
    local size = tonumber(ld.slotSize) or 38
    local gap = tonumber(ld.spacing) or 4

    for _, wrapper in ipairs(self.list) do wrapper:Hide() end

    for index, item in ipairs(items) do
        local wrapper = self.byKey[item.key]
        if wrapper then
            local col = (index - 1) % columns
            local row = math.floor((index - 1) / columns)
            wrapper:ClearAllPoints()
            wrapper:SetPoint("TOPLEFT", Bags.Modules.Layout.content, "TOPLEFT", col * (size + gap), -(row * (size + gap)))
            wrapper:Show()
            self:Render(wrapper, item)
        end
    end

    local rows = math.max(1, math.ceil(#items / columns))
    Bags.Modules.Layout.content:SetWidth(columns * size + math.max(0, columns - 1) * gap)
    Bags.Modules.Layout:SetContentHeight(rows * size + math.max(0, rows - 1) * gap)
end

function Slots:Refresh(layoutToo)
    self:EnsurePool()
    local data = Bags.Modules.Data
    data:Scan(true)

    -- Physical identities never change; layout changes are still deferred in
    -- lockdown because moving protected descendants in combat is unsafe.
    for key, wrapper in pairs(self.byKey) do
        self:Render(wrapper, data.byKey[key])
    end

    if layoutToo ~= false and not (InCombatLockdown and InCombatLockdown()) then
        local search = Bags.Modules.Search
        local query = search and search:GetQuery() or ""
        local db = Bags.GetDB()
        local display = data:GetDisplayItems(query, db.sorting.mode, db.slots.showEmpty)
        self:LayoutDisplay(display)
    elseif layoutToo then
        Bags.State.layoutPending = true
    end
end

function Slots:ApplySettings()
    if not Bags.Modules.Layout or not Bags.Modules.Layout.content then return end
    if InCombatLockdown and InCombatLockdown() then
        Bags.State.layoutPending = true
        return
    end
    self:EnsurePool()
    Bags.RequestRefresh(true)
end

function Slots:Initialize()
    self:EnsurePool()
end

-- =====================================================================
-- BagSlots.lua — secure Blizzard item buttons with minimal TomoMod visuals
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
local ACCENT = { 0.18, 0.62, 0.85 }

-- Reagent bag space keeps an azure-white outline so its reserved capacity
-- stays recognizable in the combined grid. Normal bag space no longer has an
-- identity colour of its own: it was drawn on every free slot at 0.48 alpha
-- and dominated the grid.
local REAGENT_SLOT = { 0.58, 0.88, 1.00 }
local REAGENT_BAG_ID = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag

-- Slot palette.
--
-- The grid used to sit at ~0.04 luminance with occupied slots DARKER than
-- empty ones, and every occupied slot carried a 2px full-alpha frame in its
-- quality colour. Players read the panel as a black hole and the frames as
-- noise, which is the whole point of this palette.
--
-- The base is now a light cool grey, empty slots sit slightly below it so
-- they still read as holes, and the quality colour is carried by the slot
-- fill. The fill is BLENDED towards the quality colour rather than replaced
-- by it, so overall grid luminance stays put whatever the bag holds -- a
-- naive `r * amount` would darken every slot instead of tinting it.
local SLOT_BASE   = { 0.102, 0.108, 0.116 }
local SLOT_EMPTY  = { 0.088, 0.094, 0.102 }
local SLOT_ALPHA  = 0.97
local EMPTY_ALPHA = 0.90

-- How far the slot fill travels from SLOT_BASE towards the quality colour.
-- Below ~0.12 the common/poor greys stop being separable from an empty slot;
-- above ~0.22 epic and legendary start shouting again, which is what we just
-- moved away from.
local TINT_AMOUNT = 0.16

-- Neutral hairline used whenever quality is not drawn as a frame. Low enough
-- to delimit the slot without competing with the fill.
local NEUTRAL_EDGE = 0.06

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
    local tex = parent:CreateTexture(nil, "OVERLAY")
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
    for _, tex in ipairs(border) do tex:SetColorTexture(r, g, b, a or 1) end
end

-- Reads the effective quality presentation. `qualityStyle` is the current
-- field; `qualityBorders` is the 4.0.x boolean and is still honoured for a
-- profile that has not been through the migration yet (a profile copied in
-- by hand, or an import from an older export string).
local function QualityStyle(db)
    local style = db and db.qualityStyle
    if style == "tint" or style == "border" or style == "both" or style == "none" then
        return style
    end
    if db and db.qualityBorders == false then return "none" end
    return "tint"
end

-- Blends `base` towards the quality colour by TINT_AMOUNT and paints `tex`.
-- Passing no colour paints the untinted base, which is what "none" and every
-- non-tinting style want.
local function ApplySlotFill(tex, r, g, b)
    if not r then
        tex:SetColorTexture(SLOT_BASE[1], SLOT_BASE[2], SLOT_BASE[3], SLOT_ALPHA)
        return
    end
    tex:SetColorTexture(
        SLOT_BASE[1] + (r - SLOT_BASE[1]) * TINT_AMOUNT,
        SLOT_BASE[2] + (g - SLOT_BASE[2]) * TINT_AMOUNT,
        SLOT_BASE[3] + (b - SLOT_BASE[3]) * TINT_AMOUNT,
        SLOT_ALPHA)
end

local function TextSizes(slotSize)
    slotSize = tonumber(slotSize) or 38
    if slotSize <= 30 then return 7, 7 end
    if slotSize <= 36 then return 8, 8 end
    if slotSize <= 42 then return 9, 8 end
    return 10, 9
end

local function CreateTextPlate(parent, anchor, x, y, width, height)
    local tex = parent:CreateTexture(nil, "OVERLAY", nil, 1)
    tex:SetTexture(WHITE)
    tex:SetSize(width, height)
    tex:SetPoint(anchor, x, y)
    tex:SetColorTexture(0.01, 0.015, 0.018, 0.78)
    tex:Hide()
    return tex
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

    local button = CreateFrame("ItemButton", nil, wrapper, "ContainerFrameItemButtonTemplate")
    button:SetAllPoints(wrapper)
    button:SetID(slotID)
    button:SetFrameLevel(wrapper:GetFrameLevel() + 2)
    button:EnableMouse(true)
    button:Show()
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:EnableMouseWheel(false)

    wrapper.button = button
    wrapper.key = key
    wrapper.bagID = bagID
    wrapper.slotID = slotID

    local bg = wrapper:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(WHITE)
    bg:SetColorTexture(SLOT_BASE[1], SLOT_BASE[2], SLOT_BASE[3], SLOT_ALPHA)
    wrapper.bg = bg

    -- Blizzard's ContainerFrameItemButtonTemplate remains the secure/input
    -- owner, but TomoMod renders the visible item itself. The internal
    -- texture/count region names have changed across client versions and
    -- relying on them caused perfectly valid bag slots to appear empty on
    -- Midnight. Keep every native decorative region transparent.
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
    if button.NormalTexture then button.NormalTexture:SetAlpha(0) end
    if button.IconBorder then button.IconBorder:SetAlpha(0); button.IconBorder:Hide() end
    if button.NewItemTexture then button.NewItemTexture:Hide(); button.NewItemTexture:SetAlpha(0) end
    if button.BattlepayItemTexture then button.BattlepayItemTexture:Hide(); button.BattlepayItemTexture:SetAlpha(0) end
    if button.flash then button.flash:Hide(); button.flash:SetAlpha(0) end
    if button.newitemglowAnim then button.newitemglowAnim:Stop() end
    local nativeIcon = button.icon or button.IconTexture or button.Icon
    if nativeIcon then nativeIcon:SetAlpha(0) end
    local nativeCount = button.Count or button.count
    if nativeCount and nativeCount.SetAlpha then nativeCount:SetAlpha(0) end

    local itemIcon = wrapper:CreateTexture(nil, "ARTWORK", nil, 1)
    itemIcon:SetPoint("TOPLEFT", 2, -2)
    itemIcon:SetPoint("BOTTOMRIGHT", -2, 2)
    itemIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    itemIcon:Hide()
    wrapper.itemIcon = itemIcon

    local countPlate = CreateTextPlate(button, "BOTTOMRIGHT", -2, 2, 22, 12)
    wrapper.countPlate = countPlate

    local countText = button:CreateFontString(nil, "OVERLAY", nil, 2)
    countText:SetFont(FONT_BOLD, 9, "OUTLINE")
    countText:SetPoint("BOTTOMRIGHT", -3, 3)
    countText:SetTextColor(1, 1, 1, 1)
    countText:SetJustifyH("RIGHT")
    countText:SetJustifyV("BOTTOM")
    countText:Hide()
    wrapper.countText = countText

    local cooldown = CreateFrame("Cooldown", nil, wrapper, "CooldownFrameTemplate")
    cooldown:SetPoint("TOPLEFT", itemIcon, "TOPLEFT")
    cooldown:SetPoint("BOTTOMRIGHT", itemIcon, "BOTTOMRIGHT")
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(false)
    cooldown:EnableMouse(false)
    cooldown:Hide()
    wrapper.cooldown = cooldown

    local border = BuildBorder(button)
    SetBorder(border, 1, 1, 1, NEUTRAL_EDGE)
    wrapper.border = border

    local ilvlPlate = CreateTextPlate(button, "TOPLEFT", 2, -2, 24, 12)
    wrapper.ilvlPlate = ilvlPlate

    local ilvl = button:CreateFontString(nil, "OVERLAY", nil, 2)
    ilvl:SetFont(FONT_BOLD, 8, "OUTLINE")
    ilvl:SetPoint("TOPLEFT", 3, -3)
    ilvl:SetTextColor(1.00, 0.82, 0.24, 1)
    ilvl:SetJustifyH("LEFT")
    ilvl:SetJustifyV("TOP")
    wrapper.ilvl = ilvl

    local pin = button:CreateTexture(nil, "OVERLAY")
    pin:SetTexture(WHITE)
    pin:SetSize(6, 6)
    pin:SetPoint("TOPRIGHT", -3, -3)
    pin:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
    pin:Hide()
    wrapper.pin = pin

    button:HookScript("OnEnter", function(self)
        local item = Bags.Modules.Data.byKey[key]
        if not item or not item.hasItem then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if GameTooltip.SetBagItem then
            GameTooltip:SetBagItem(bagID, slotID)
        elseif item.link then
            GameTooltip:SetHyperlink(item.link)
        end
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:HookScript("OnMouseUp", function(_, mouseButton)
        if mouseButton ~= "MiddleButton" then return end
        local item = Bags.Modules.Data.byKey[key]
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
    button:Show()
    button:EnableMouse(true)

    local size = Bags.GetDB().layout.slotSize or 38
    wrapper:SetSize(size, size)

    local countSize, ilvlSize = TextSizes(size)
    wrapper.countText:SetFont(FONT_BOLD, countSize, "OUTLINE")
    wrapper.ilvl:SetFont(FONT_BOLD, ilvlSize, "OUTLINE")

    if not item or not item.hasItem then
        wrapper.itemIcon:SetTexture(nil)
        wrapper.itemIcon:Hide()
        wrapper.countText:SetText("")
        wrapper.countText:Hide()
        wrapper.countPlate:Hide()
        wrapper.cooldown:Hide()
        wrapper.bg:SetColorTexture(SLOT_EMPTY[1], SLOT_EMPTY[2], SLOT_EMPTY[3], EMPTY_ALPHA)
        -- Empty slots used to carry the identity colour at 0.48/0.62 alpha, so
        -- a hundred and thirty free slots pulled as much attention as the items.
        -- The normal bag now delimits with the neutral hairline and only the
        -- reagent bag keeps a tinted edge, which is the one that carries
        -- information worth spending contrast on.
        if REAGENT_BAG_ID and wrapper.bagID == REAGENT_BAG_ID then
            SetBorder(wrapper.border, REAGENT_SLOT[1], REAGENT_SLOT[2], REAGENT_SLOT[3], 0.26)
        else
            SetBorder(wrapper.border, 1, 1, 1, NEUTRAL_EDGE)
        end
        wrapper.ilvl:SetText("")
        wrapper.ilvlPlate:Hide()
        wrapper.pin:Hide()
        button:SetAlpha(1)
        button:EnableMouse(true)
        return
    end

    -- Render independently from Blizzard's private template regions.
    wrapper.itemIcon:SetTexture(item.icon)
    wrapper.itemIcon:SetVertexColor(1, 1, 1, 1)
    wrapper.itemIcon:SetAlpha(1)
    wrapper.itemIcon:SetDesaturated(item.locked and true or false)
    wrapper.itemIcon:Show()
    button:SetAlpha(1)
    button:EnableMouse(true)

    local count = tonumber(item.count) or 1
    if count > 1 then
        wrapper.countText:SetText(count)
        wrapper.countText:Show()
        wrapper.countPlate:Show()
    else
        wrapper.countText:SetText("")
        wrapper.countText:Hide()
        wrapper.countPlate:Hide()
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

    local db = Bags.GetDB().slots
    local style = QualityStyle(db)
    local c = QUALITY[item.quality or 0] or QUALITY[0]

    if style == "tint" or style == "both" then
        ApplySlotFill(wrapper.bg, c[1], c[2], c[3])
    else
        ApplySlotFill(wrapper.bg)
    end

    if style == "border" then
        SetBorder(wrapper.border, c[1], c[2], c[3], item.quality and item.quality > 1 and 0.90 or 0.30)
    elseif style == "both" then
        -- Half the alpha of the legacy frame: the fill already carries the
        -- quality, the edge only sharpens it.
        SetBorder(wrapper.border, c[1], c[2], c[3], item.quality and item.quality > 1 and 0.45 or 0.20)
    else
        SetBorder(wrapper.border, 1, 1, 1, NEUTRAL_EDGE)
    end

    if db.itemLevel ~= false and item.ilvl and item.ilvl > 0 then
        wrapper.ilvl:SetText(item.ilvl)
        wrapper.ilvlPlate:Show()
    else
        wrapper.ilvl:SetText("")
        wrapper.ilvlPlate:Hide()
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
    local size = tonumber(ld.slotSize) or 38
    local gap = tonumber(ld.spacing) or 4
    local layout = Bags.Modules.Layout
    local columns = layout and layout:FitToContent(#items) or math.max(1, tonumber(ld.columns) or 12)

    for _, wrapper in ipairs(self.list) do wrapper:Hide() end

    for index, item in ipairs(items) do
        local wrapper = self.byKey[item.key]
        if wrapper then
            local col = (index - 1) % columns
            local row = math.floor((index - 1) / columns)
            wrapper:ClearAllPoints()
            wrapper:SetPoint("TOPLEFT", Bags.Modules.Layout.content, "TOPLEFT", col * (size + gap), -(row * (size + gap)))
            wrapper:Show()
            if wrapper.button then wrapper.button:Show() end
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

    -- Always refresh the physical buttons, even in combat. Their bag/slot
    -- identity is fixed; only layout/filter changes are deferred until combat
    -- ends so no protected descendant is moved by our code in lockdown.
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

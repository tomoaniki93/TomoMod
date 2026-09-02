-- =====================================================================
-- BagSidebar.lua — Pinned and Recent item previews
-- =====================================================================

local Bags = TomoMod_BagSkin
if not Bags then return end

local Sidebar = {
    pinnedButtons = {},
    recentButtons = {},
}
Bags.RegisterModule("Sidebar", Sidebar)

local WHITE = "Interface\\Buttons\\WHITE8X8"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ACCENT = { 0.18, 0.85, 0.52 }
local MINI = 32
local GAP = 5

local function L(key, fallback)
    local value = TomoMod_L and TomoMod_L[key]
    if type(value) == "string" and value ~= key and value ~= "" then return value end
    return fallback
end

local function CreateLabel(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT_BOLD, 9, "OUTLINE")
    fs:SetText(text)
    fs:SetTextColor(0.74, 0.79, 0.80, 1)
    return fs
end

local function CreateMini(parent, pinned)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(MINI, MINI)
    b:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    b:SetBackdropColor(0.03, 0.04, 0.043, 0.95)
    b:SetBackdropBorderColor(1, 1, 1, 0.10)

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", -2, 2)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b.icon = icon

    if pinned then
        local mark = b:CreateTexture(nil, "OVERLAY")
        mark:SetTexture(WHITE)
        mark:SetSize(5, 5)
        mark:SetPoint("TOPRIGHT", -2, -2)
        mark:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
        b.pinMark = mark
    end

    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.65)
        local item = self.item
        if item then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetBagItem(item.bagID, item.slotID)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L("bags_v4_sidebar_click", "Left-click: find in bags"), 0.65, 0.72, 0.74)
            if self.isPinned then
                GameTooltip:AddLine(L("bags_v4_sidebar_unpin", "Middle-click: unpin"), ACCENT[1], ACCENT[2], ACCENT[3])
            end
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(1, 1, 1, 0.10)
        GameTooltip:Hide()
    end)
    b:SetScript("OnMouseUp", function(self, button)
        local item = self.item
        if not item then return end
        if button == "MiddleButton" and self.isPinned then
            Bags.Modules.Data:TogglePinned(item.itemID)
        elseif button == "LeftButton" and Bags.GetDB().search.enabled ~= false then
            local search = Bags.Modules.Search
            if search and search.SetQuery then search:SetQuery(item.name or tostring(item.itemID)) end
        end
    end)
    b:Hide()
    return b
end

local function EnsureButtons(pool, count, parent, pinned)
    for i = #pool + 1, count do
        pool[i] = CreateMini(parent, pinned)
        pool[i].isPinned = pinned and true or false
    end
end

local function LayoutPool(pool, items, anchor, maxItems)
    for _, b in ipairs(pool) do b:Hide(); b.item = nil end
    local shown = math.min(#items, maxItems)
    for i = 1, shown do
        local b = pool[i]
        local item = items[i]
        b.item = item
        b.icon:SetTexture(item.icon)
        b:ClearAllPoints()
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        b:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", col * (MINI + GAP), -(5 + row * (MINI + GAP)))
        b:Show()
    end
    return math.ceil(shown / 2) * (MINI + GAP)
end

function Sidebar:Create()
    if self.root then return end
    local host = Bags.Modules.Layout.sidebarHost

    local root = CreateFrame("Frame", nil, host)
    root:SetPoint("TOPLEFT", 8, -10)
    root:SetPoint("TOPRIGHT", -8, -10)
    root:SetPoint("BOTTOM", 0, 8)
    self.root = root

    local pinnedLabel = CreateLabel(root, L("bags_v4_pinned", "Pinned"))
    pinnedLabel:SetPoint("TOPLEFT", 0, 0)
    self.pinnedLabel = pinnedLabel

    local recentLabel = CreateLabel(root, L("bags_v4_recent", "Recent"))
    self.recentLabel = recentLabel

    local emptyPinned = root:CreateFontString(nil, "OVERLAY")
    emptyPinned:SetFont(FONT, 8, "OUTLINE")
    emptyPinned:SetText(L("bags_v4_empty_pinned", "Middle-click an item"))
    emptyPinned:SetTextColor(0.46, 0.51, 0.53, 1)
    emptyPinned:SetJustifyH("LEFT")
    emptyPinned:SetJustifyV("TOP")
    emptyPinned:SetWordWrap(true)
    if emptyPinned.SetMaxLines then emptyPinned:SetMaxLines(2) end
    emptyPinned:SetHeight(22)
    self.emptyPinned = emptyPinned

    local emptyRecent = root:CreateFontString(nil, "OVERLAY")
    emptyRecent:SetFont(FONT, 8, "OUTLINE")
    emptyRecent:SetText(L("bags_v4_empty_recent", "No recent items"))
    emptyRecent:SetTextColor(0.46, 0.51, 0.53, 1)
    emptyRecent:SetJustifyH("LEFT")
    emptyRecent:SetJustifyV("TOP")
    emptyRecent:SetWordWrap(true)
    if emptyRecent.SetMaxLines then emptyRecent:SetMaxLines(2) end
    emptyRecent:SetHeight(22)
    self.emptyRecent = emptyRecent
end

function Sidebar:Refresh()
    if not self.root then return end
    local data = Bags.Modules.Data
    local db = Bags.GetDB().sidebar
    local pinned = data:GetPinnedItems()
    local recent = data:GetRecentItems()
    local pmax = math.max(1, tonumber(db.pinnedMax) or 8)
    local rmax = math.max(1, tonumber(db.recentMax) or 8)

    EnsureButtons(self.pinnedButtons, pmax, self.root, true)
    EnsureButtons(self.recentButtons, rmax, self.root, false)

    local pHeight = LayoutPool(self.pinnedButtons, pinned, self.pinnedLabel, pmax)
    local textWidth = math.max(46, (self.root:GetWidth() or 80) - 2)

    self.emptyPinned:ClearAllPoints()
    self.emptyPinned:SetPoint("TOPLEFT", self.pinnedLabel, "BOTTOMLEFT", 0, -7)
    self.emptyPinned:SetWidth(textWidth)
    self.emptyPinned:SetShown(#pinned == 0)

    local pinnedBlock = #pinned == 0 and 38 or (pHeight + 7)
    self.recentLabel:ClearAllPoints()
    self.recentLabel:SetPoint("TOPLEFT", self.pinnedLabel, "BOTTOMLEFT", 0, -(pinnedBlock + 8))

    LayoutPool(self.recentButtons, recent, self.recentLabel, rmax)
    self.emptyRecent:ClearAllPoints()
    self.emptyRecent:SetPoint("TOPLEFT", self.recentLabel, "BOTTOMLEFT", 0, -7)
    self.emptyRecent:SetWidth(textWidth)
    self.emptyRecent:SetShown(#recent == 0)
end

function Sidebar:Initialize()
    self:Create()
    self:Refresh()
end

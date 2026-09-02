-- =====================================================================
-- BagLayout.lua — TomoMod Bags V4 frame and chrome
-- =====================================================================

local Bags = TomoMod_BagSkin
if not Bags then return end

local Layout = {}
Bags.RegisterModule("Layout", Layout)

local WHITE = "Interface\\Buttons\\WHITE8X8"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ACCENT = { 0.18, 0.85, 0.52 }
local HEADER_H = 42
local SEARCH_H = 34
local FOOTER_H = 30

local SORT_LABELS = {
    natural = "bags_v4_sort_natural",
    quality = "bags_v4_sort_quality",
    name = "bags_v4_sort_name",
    ilvl = "bags_v4_sort_ilvl",
}
local SORT_ORDER = { "natural", "quality", "name", "ilvl" }

local function L(key, fallback)
    local loc = TomoMod_L and TomoMod_L[key]
    if type(loc) == "string" and loc ~= key and loc ~= "" then return loc end
    return fallback or key
end

local function Surface(frame, bgA, borderA)
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(0.025, 0.032, 0.035, bgA or 0.96)
    frame:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], borderA or 0.30)
end

local function CreateTextButton(parent, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height)
    Surface(button, 0.76, 0.18)

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFont(FONT, 10, "OUTLINE")
    text:SetPoint("CENTER")
    text:SetTextColor(0.82, 0.86, 0.88, 1)
    button.text = text

    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.04, 0.07, 0.065, 0.96)
        self:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.65)
        self.text:SetTextColor(1, 1, 1, 1)
    end)
    button:SetScript("OnLeave", function(self)
        Surface(self, 0.76, 0.18)
        self.text:SetTextColor(0.82, 0.86, 0.88, 1)
    end)
    return button
end

function Layout:CreateFrame()
    if self.frame then return end
    local db = Bags.GetDB()

    local f = CreateFrame("Frame", "TomoMod_BagsV4_Frame", UIParent, "BackdropTemplate")
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    Surface(f, db.appearance.alpha, 0.34)
    f:Hide()
    self.frame = f

    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(HEADER_H)
    header:EnableMouse(true)
    self.header = header

    local headerBG = header:CreateTexture(nil, "BACKGROUND")
    headerBG:SetAllPoints()
    headerBG:SetColorTexture(0.035, 0.045, 0.048, 0.96)

    local line = header:CreateTexture(nil, "ARTWORK")
    line:SetPoint("BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT")
    line:SetHeight(1)
    line:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.55)

    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_BOLD, 14, "OUTLINE")
    title:SetPoint("LEFT", 12, 0)
    title:SetText(L("bags_v4_title", "Bags"))
    title:SetTextColor(1, 1, 1, 1)
    self.title = title

    local count = header:CreateFontString(nil, "OVERLAY")
    count:SetFont(FONT, 10, "OUTLINE")
    count:SetPoint("LEFT", title, "RIGHT", 12, 0)
    count:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
    self.count = count

    local close = CreateTextButton(header, 24, 24)
    close:SetPoint("RIGHT", -8, 0)
    close.text:SetText("×")
    close.text:SetFont(FONT_BOLD, 15, "OUTLINE")
    close:SetScript("OnClick", function() Bags.Hide() end)
    self.closeButton = close

    local sort = CreateTextButton(header, 108, 24)
    sort:SetPoint("RIGHT", close, "LEFT", -6, 0)
    sort:SetScript("OnClick", function()
        local sdb = Bags.GetDB().sorting
        local current = sdb.mode or "natural"
        local index = 1
        for i, mode in ipairs(SORT_ORDER) do
            if mode == current then index = i break end
        end
        index = (index % #SORT_ORDER) + 1
        sdb.mode = SORT_ORDER[index]
        Layout:RefreshSortLabel()
        Bags.RequestRefresh(true)
    end)
    sort:SetScript("OnEnter", function(self)
        Surface(self, 0.96, 0.65)
        self.text:SetTextColor(1, 1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L("bags_v4_sort_tip", "Click to change visual sorting."), 1, 1, 1)
        GameTooltip:Show()
    end)
    sort:HookScript("OnLeave", function() GameTooltip:Hide() end)
    self.sortButton = sort

    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        if InCombatLockdown and InCombatLockdown() then return end
        f:StartMoving()
    end)
    header:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local point, _, relativePoint, x, y = f:GetPoint(1)
        local pos = Bags.GetDB().position
        pos.point = point
        pos.relativePoint = relativePoint
        pos.x = math.floor((x or 0) + 0.5)
        pos.y = math.floor((y or 0) + 0.5)
    end)

    local searchHost = CreateFrame("Frame", nil, f, "BackdropTemplate")
    searchHost:SetPoint("TOPLEFT", 1, -(HEADER_H + 1))
    searchHost:SetPoint("TOPRIGHT", -1, -(HEADER_H + 1))
    searchHost:SetHeight(SEARCH_H)
    searchHost:SetBackdrop({ bgFile = WHITE })
    searchHost:SetBackdropColor(0.018, 0.024, 0.026, 0.92)
    self.searchHost = searchHost

    local sidebar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    sidebar:SetBackdrop({ bgFile = WHITE })
    sidebar:SetBackdropColor(0.022, 0.029, 0.031, 0.94)
    self.sidebarHost = sidebar

    local sideLine = sidebar:CreateTexture(nil, "ARTWORK")
    sideLine:SetPoint("TOPRIGHT")
    sideLine:SetPoint("BOTTOMRIGHT")
    sideLine:SetWidth(1)
    sideLine:SetColorTexture(1, 1, 1, 0.07)

    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:EnableMouseWheel(true)
    self.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    self.content = content

    local track = CreateFrame("Frame", nil, f)
    track:SetWidth(5)
    track:EnableMouse(false)
    self.scrollTrack = track

    local trackBG = track:CreateTexture(nil, "BACKGROUND")
    trackBG:SetAllPoints()
    trackBG:SetColorTexture(1, 1, 1, 0.035)

    local thumb = track:CreateTexture(nil, "ARTWORK")
    thumb:SetWidth(3)
    thumb:SetPoint("TOP", 0, -1)
    thumb:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.65)
    self.scrollThumb = thumb

    local footer = CreateFrame("Frame", nil, f)
    footer:SetPoint("BOTTOMLEFT", 1, 1)
    footer:SetPoint("BOTTOMRIGHT", -1, 1)
    footer:SetHeight(FOOTER_H)
    self.footer = footer

    local footerBG = footer:CreateTexture(nil, "BACKGROUND")
    footerBG:SetAllPoints()
    footerBG:SetColorTexture(0.018, 0.024, 0.026, 0.94)

    local footerLine = footer:CreateTexture(nil, "ARTWORK")
    footerLine:SetPoint("TOPLEFT")
    footerLine:SetPoint("TOPRIGHT")
    footerLine:SetHeight(1)
    footerLine:SetColorTexture(1, 1, 1, 0.06)

    local gold = footer:CreateFontString(nil, "OVERLAY")
    gold:SetFont(FONT, 11, "OUTLINE")
    gold:SetPoint("LEFT", 10, 0)
    self.gold = gold

    local hint = footer:CreateFontString(nil, "OVERLAY")
    hint:SetFont(FONT, 9, "OUTLINE")
    hint:SetPoint("RIGHT", -10, 0)
    hint:SetText(L("bags_v4_pin_hint", "Middle-click an item to pin it"))
    hint:SetTextColor(0.48, 0.53, 0.55, 1)
    self.hint = hint

    scroll:SetScript("OnMouseWheel", function(_, delta)
        Layout:ScrollBy(delta > 0 and -48 or 48)
    end)

    f:SetScript("OnShow", function()
        Bags.RequestRefresh(true)
    end)
    f:SetScript("OnHide", function()
        GameTooltip:Hide()
    end)
end

function Layout:ScrollBy(amount)
    if not self.scroll then return end
    local range = self.scroll:GetVerticalScrollRange() or 0
    local value = self.scroll:GetVerticalScroll() or 0
    value = math.max(0, math.min(range, value + amount))
    self.scroll:SetVerticalScroll(value)
    self:RefreshScrollThumb()
end

function Layout:RefreshScrollThumb()
    if not self.scroll or not self.scrollThumb then return end
    local range = self.scroll:GetVerticalScrollRange() or 0
    local view = self.scroll:GetHeight() or 1
    local total = view + range
    local trackH = self.scrollTrack:GetHeight() or 1
    local thumbH = range <= 0 and trackH or math.max(24, trackH * (view / math.max(total, 1)))
    self.scrollThumb:SetHeight(thumbH)
    self.scrollThumb:ClearAllPoints()
    if range <= 0 then
        self.scrollThumb:SetPoint("TOP", self.scrollTrack, "TOP", 0, 0)
        self.scrollThumb:SetAlpha(0.20)
    else
        local progress = (self.scroll:GetVerticalScroll() or 0) / range
        local travel = math.max(0, trackH - thumbH)
        self.scrollThumb:SetPoint("TOP", self.scrollTrack, "TOP", 0, -(travel * progress))
        self.scrollThumb:SetAlpha(0.75)
    end
end

function Layout:SetContentHeight(height)
    if not self.content then return end
    self.content:SetHeight(math.max(height or 1, self.scroll:GetHeight() or 1))
    C_Timer.After(0, function()
        if self.scroll and self.scroll:IsVisible() then self:RefreshScrollThumb() end
    end)
end

function Layout:RefreshSortLabel()
    if not self.sortButton then return end
    local mode = Bags.GetDB().sorting.mode or "natural"
    local fallback = ({ natural = "Bag order", quality = "Quality", name = "Name", ilvl = "Item level" })[mode] or mode
    self.sortButton.text:SetText(L(SORT_LABELS[mode], fallback))
end

function Layout:RefreshHeader()
    if not self.frame then return end
    local data = Bags.Modules.Data
    if data then
        local used, total = data:GetCounts()
        self.count:SetText(string.format("%d / %d", used, total))
    end
    if self.gold then
        local money = GetMoney and GetMoney() or 0
        self.gold:SetText(GetCoinTextureString and GetCoinTextureString(money) or tostring(money))
    end
    self:RefreshSortLabel()
end

function Layout:ApplySettings()
    if not self.frame then return end
    local db = Bags.GetDB()
    local ld = db.layout
    local requestedColumns = math.max(6, math.min(16, tonumber(ld.columns) or 12))
    local slot = math.max(28, math.min(52, tonumber(ld.slotSize) or 38))
    local spacing = math.max(0, math.min(10, tonumber(ld.spacing) or 4))
    local sidebarW = math.max(82, math.min(116, tonumber(ld.sidebarWidth) or 94))
    local pad = math.max(6, tonumber(ld.padding) or 10)
    local scale = math.max(0.70, math.min(1.40, tonumber(db.appearance.scale) or 1))

    -- Never let a user setting build a window wider/taller than the usable
    -- screen. The configured column count is preserved in the DB; this only
    -- reduces the live layout when the current resolution cannot fit it.
    local uiWidth = UIParent and UIParent:GetWidth() or 1200
    local uiHeight = UIParent and UIParent:GetHeight() or 900
    local maxFrameW = math.max(360, (uiWidth * 0.94) / scale)
    local fixedW = sidebarW + pad * 3 + 8
    local maxColumns = math.floor((maxFrameW - fixedW + spacing) / math.max(1, slot + spacing))
    local columns = math.max(6, math.min(requestedColumns, maxColumns))

    local gridW = columns * slot + (columns - 1) * spacing
    local width = sidebarW + pad * 3 + gridW + 8

    local fixedH = HEADER_H + (db.search.enabled ~= false and SEARCH_H or 0) + FOOTER_H + pad * 2
    local maxFrameH = math.max(320, (uiHeight * 0.90) / scale)
    local maxRows = math.floor((maxFrameH - fixedH + spacing) / math.max(1, slot + spacing))
    local rowsVisible = math.max(5, math.min(9, maxRows))
    local gridH = rowsVisible * slot + (rowsVisible - 1) * spacing
    local height = fixedH + gridH

    self.frame:SetSize(width, height)
    self.frame:SetScale(scale)
    self.frame:SetAlpha(db.appearance.alpha or 0.96)

    self.sidebarHost:ClearAllPoints()
    self.sidebarHost:SetPoint("TOPLEFT", 1, -(HEADER_H + SEARCH_H + 1))
    self.sidebarHost:SetPoint("BOTTOMLEFT", 1, FOOTER_H + 1)
    self.sidebarHost:SetWidth(sidebarW)

    self.scroll:ClearAllPoints()
    self.scroll:SetPoint("TOPLEFT", self.sidebarHost, "TOPRIGHT", pad, -pad)
    self.scroll:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -(pad + 8), FOOTER_H + pad)

    self.scrollTrack:ClearAllPoints()
    self.scrollTrack:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -4, -(HEADER_H + SEARCH_H + pad))
    self.scrollTrack:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -4, FOOTER_H + pad)

    local pos = db.position
    if not self.frame._positionApplied then
        self.frame:ClearAllPoints()
        self.frame:SetPoint(pos.point or "BOTTOMRIGHT", UIParent, pos.relativePoint or "BOTTOMRIGHT", pos.x or -42, pos.y or 86)
        self.frame._positionApplied = true
    end

    self.searchHost:SetShown(db.search.enabled ~= false)
    if db.search.enabled == false then
        self.sidebarHost:SetPoint("TOPLEFT", 1, -(HEADER_H + 1))
        self.scroll:SetPoint("TOPLEFT", self.sidebarHost, "TOPRIGHT", pad, -pad)
        self.scrollTrack:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -4, -(HEADER_H + pad))
    end

    if ld.mode == "separate" then
        self.frame:Hide()
    end

    self:RefreshHeader()
    self:RefreshScrollThumb()
end

function Layout:Initialize()
    self:CreateFrame()
    self:ApplySettings()
end

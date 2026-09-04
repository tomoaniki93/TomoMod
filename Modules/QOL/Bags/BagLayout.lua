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
local ACCENT = { 0.18, 0.62, 0.85 }
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
    frame:SetBackdropColor(0.045, 0.052, 0.055, bgA or 0.96)
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
        self:SetBackdropColor(0.055, 0.078, 0.073, 0.96)
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
    headerBG:SetColorTexture(0.055, 0.064, 0.067, 0.96)

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
        local pos = Bags.GetDB().position
        -- GetPoint() apres un deplacement rapporte l'ancre d'AVANT le drag :
        -- c'est ce qui faisait deriver les positions d'un cran a chaque
        -- glissement. Layout.Save lit les bords reels et normalise l'echelle.
        if TomoMod_Layout and TomoMod_Layout.Save then
            TomoMod_Layout.Save(pos, f)
        else
            local point, _, relativePoint, x, y = f:GetPoint(1)
            pos.point = point
            pos.relativePoint = relativePoint
            pos.x = math.floor((x or 0) + 0.5)
            pos.y = math.floor((y or 0) + 0.5)
        end
    end)

    local searchHost = CreateFrame("Frame", nil, f, "BackdropTemplate")
    searchHost:SetPoint("TOPLEFT", 1, -(HEADER_H + 1))
    searchHost:SetPoint("TOPRIGHT", -1, -(HEADER_H + 1))
    searchHost:SetHeight(SEARCH_H)
    searchHost:SetBackdrop({ bgFile = WHITE })
    searchHost:SetBackdropColor(0.038, 0.045, 0.048, 0.94)
    self.searchHost = searchHost

    local sidebar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    sidebar:SetBackdrop({ bgFile = WHITE })
    sidebar:SetBackdropColor(0.042, 0.049, 0.052, 0.96)
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
    footerBG:SetColorTexture(0.038, 0.045, 0.048, 0.96)

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
    if not self.scroll or not self.scrollThumb or not self.scrollTrack then return end
    local range = self.scroll:GetVerticalScrollRange() or 0

    -- Combined bags should normally size themselves to the complete grid.
    -- Do not leave a decorative scrollbar visible when there is nothing to
    -- scroll; it makes the frame look artificially cropped.
    if range <= 1 then
        self.scroll:SetVerticalScroll(0)
        self.scrollTrack:Hide()
        return
    end

    self.scrollTrack:Show()
    local view = self.scroll:GetHeight() or 1
    local total = view + range
    local trackH = self.scrollTrack:GetHeight() or 1
    local thumbH = math.max(24, trackH * (view / math.max(total, 1)))
    self.scrollThumb:SetHeight(thumbH)
    self.scrollThumb:ClearAllPoints()

    local progress = (self.scroll:GetVerticalScroll() or 0) / range
    local travel = math.max(0, trackH - thumbH)
    self.scrollThumb:SetPoint("TOP", self.scrollTrack, "TOP", 0, -(travel * progress))
    self.scrollThumb:SetAlpha(0.75)
end

function Layout:SetContentHeight(height)
    if not self.content then return end
    local viewHeight = self.scroll:GetHeight() or 1
    local contentHeight = math.max(height or 1, viewHeight)
    self.content:SetHeight(contentHeight)
    if contentHeight <= viewHeight + 1 then
        self.scroll:SetVerticalScroll(0)
    end
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

local function GeometrySettings()
    local db = Bags.GetDB()
    local ld = db.layout
    return {
        db = db,
        ld = ld,
        requestedColumns = math.max(6, math.min(16, tonumber(ld.columns) or 12)),
        slot = math.max(28, math.min(52, tonumber(ld.slotSize) or 38)),
        spacing = math.max(0, math.min(10, tonumber(ld.spacing) or 4)),
        sidebarW = math.max(82, math.min(116, tonumber(ld.sidebarWidth) or 94)),
        pad = math.max(6, tonumber(ld.padding) or 10),
        scale = math.max(0.70, math.min(1.40, tonumber(db.appearance.scale) or 1)),
    }
end

local function MaxScreenGeometry(g)
    local uiWidth = UIParent and UIParent:GetWidth() or 1200
    local uiHeight = UIParent and UIParent:GetHeight() or 900
    local maxFrameW = math.max(360, (uiWidth * 0.94) / g.scale)
    local maxFrameH = math.max(320, (uiHeight * 0.90) / g.scale)
    local fixedW = g.sidebarW + g.pad * 3 + 8
    local fixedH = HEADER_H + (g.db.search.enabled ~= false and SEARCH_H or 0) + FOOTER_H + g.pad * 2
    local maxColumns = math.max(1, math.floor((maxFrameW - fixedW + g.spacing) / math.max(1, g.slot + g.spacing)))
    local maxRows = math.max(1, math.floor((maxFrameH - fixedH + g.spacing) / math.max(1, g.slot + g.spacing)))
    return maxFrameW, maxFrameH, fixedW, fixedH, maxColumns, maxRows
end

local function FrameDimensions(g, columns, rows)
    local gridW = columns * g.slot + math.max(0, columns - 1) * g.spacing
    local gridH = rows * g.slot + math.max(0, rows - 1) * g.spacing
    local width = g.sidebarW + g.pad * 3 + gridW + 8
    local fixedH = HEADER_H + (g.db.search.enabled ~= false and SEARCH_H or 0) + FOOTER_H + g.pad * 2
    return width, fixedH + gridH
end

function Layout:ApplyFrameGeometry(columns, rows, allowScroll)
    local g = GeometrySettings()
    local width, height = FrameDimensions(g, columns, rows)

    self.liveColumns = columns
    self.liveRows = rows
    self.allowScroll = allowScroll and true or false

    self.frame:SetSize(width, height)
    self.frame:SetScale(g.scale)
    self.frame:SetAlpha(g.db.appearance.alpha or 0.96)

    self.sidebarHost:ClearAllPoints()
    self.sidebarHost:SetPoint("TOPLEFT", 1, -(HEADER_H + SEARCH_H + 1))
    self.sidebarHost:SetPoint("BOTTOMLEFT", 1, FOOTER_H + 1)
    self.sidebarHost:SetWidth(g.sidebarW)

    self.scroll:ClearAllPoints()
    self.scroll:SetPoint("TOPLEFT", self.sidebarHost, "TOPRIGHT", g.pad, -g.pad)
    self.scroll:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -(g.pad + 8), FOOTER_H + g.pad)

    self.scrollTrack:ClearAllPoints()
    self.scrollTrack:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -4, -(HEADER_H + SEARCH_H + g.pad))
    self.scrollTrack:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -4, FOOTER_H + g.pad)

    self.searchHost:SetShown(g.db.search.enabled ~= false)
    if g.db.search.enabled == false then
        self.sidebarHost:SetPoint("TOPLEFT", 1, -(HEADER_H + 1))
        self.scroll:SetPoint("TOPLEFT", self.sidebarHost, "TOPRIGHT", g.pad, -g.pad)
        self.scrollTrack:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -4, -(HEADER_H + g.pad))
    end

    if not self.allowScroll then
        self.scroll:SetVerticalScroll(0)
        self.scrollTrack:Hide()
    end
end

-- Resize the combined bag to the actual number of displayed slots. The
-- configured column count is preferred, but when that would make the bag too
-- tall we first add columns (while staying on screen) instead of introducing a
-- scrollbar. Scrolling is therefore only a final fallback for an impossible
-- combination of resolution / scale / slot size.
function Layout:FitToContent(itemCount)
    if not self.frame then return nil end
    local g = GeometrySettings()
    local _, _, _, _, maxColumns, maxRows = MaxScreenGeometry(g)

    local count = math.max(1, tonumber(itemCount) or 1)
    local columns = math.max(1, math.min(g.requestedColumns, maxColumns))
    local rows = math.max(1, math.ceil(count / columns))

    if rows > maxRows then
        local neededColumns = math.ceil(count / maxRows)
        columns = math.max(columns, math.min(maxColumns, neededColumns))
        rows = math.max(1, math.ceil(count / columns))
    end

    local allowScroll = rows > maxRows
    local visibleRows = allowScroll and maxRows or rows
    self:ApplyFrameGeometry(columns, visibleRows, allowScroll)
    return columns
end

function Layout:ApplySettings()
    if not self.frame then return end
    local g = GeometrySettings()
    local _, _, _, _, maxColumns, maxRows = MaxScreenGeometry(g)

    -- Before the first data scan, use a small safe geometry. LayoutDisplay()
    -- immediately replaces it with the exact auto-fit geometry for the grid.
    local columns = math.max(1, math.min(g.requestedColumns, maxColumns))
    local rows = math.max(1, math.min(5, maxRows))
    self:ApplyFrameGeometry(columns, rows, false)

    local pos = g.db.position
    if not self.frame._positionApplied then
        -- Layout.Apply migre la forme heritee au passage et applique la
        -- conversion d'echelle inverse ; sans elle un cadre a l'echelle
        -- multiplie sa position par son ratio a chaque cycle.
        local DEFAULT_POS = { point = "BOTTOMRIGHT", anchor = "BOTTOMRIGHT", x = -42, y = 86 }
        if TomoMod_Layout and TomoMod_Layout.Apply then
            TomoMod_Layout.Apply(pos, self.frame, DEFAULT_POS)
        else
            self.frame:ClearAllPoints()
            self.frame:SetPoint(pos.point or "BOTTOMRIGHT", UIParent, pos.relativePoint or "BOTTOMRIGHT", pos.x or -42, pos.y or 86)
        end
        self.frame._positionApplied = true
    end

    if g.ld.mode == "separate" then
        self.frame:Hide()
    end

    self:RefreshHeader()
    self:RefreshScrollThumb()
end

function Layout:Initialize()
    self:CreateFrame()
    self:ApplySettings()
end

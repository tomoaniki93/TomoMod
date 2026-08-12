local ADDON_NAME, ns = ...
local L = ns.L

----------------------------------------------------------------------
-- SpellBreakdown: standalone window with player selector + spell list
----------------------------------------------------------------------

local WINDOW_WIDTH   = 420
local WINDOW_HEIGHT  = 520
local HEADER_HEIGHT  = 26
local PLAYER_STRIP_H = 24
local COLHEAD_HEIGHT = 16
local SPELL_BAR_H    = 20
local SPELL_BAR_SP   = 1
local ICON_PAD       = 2
local TEXT_PAD        = 6
local BORDER_SIZE    = 1

-- Column widths

-- Column budgets in characters. Converted to pixels at render time against the
-- active font size (ns.ColWidth), because these rows use ns.GetFontSize() and
-- fixed pixel widths silently clipped as soon as the user raised it.
local RANK_CHARS   = 4   -- "100."
local PCT_CHARS    = 6   -- "100.0%"
local PERSEC_CHARS = 6   -- "999.9K"
local TOTAL_CHARS  = 7   -- "999.9K" + margin

-- Dropdown constants
local DROPDOWN_WIDTH     = 200
local DROPDOWN_ROW_H     = 18
local DROPDOWN_SEARCH_H  = 22
local DROPDOWN_MAX_ROWS  = 12
local DROPDOWN_HINT_H    = 12

----------------------------------------------------------------------
-- Singleton
----------------------------------------------------------------------

local breakdownFrame = nil

-- Current state
local currentGUID = nil
local currentMeterType = nil
local currentSessionType = nil
local playerButtons = {}
local dropdownFrame = nil
local dropdownRows = {}

----------------------------------------------------------------------
-- Dropdown Menu (for raids with many players)
----------------------------------------------------------------------

local function HideDropdown()
    if dropdownFrame then
        dropdownFrame:Hide()
    end
end

-- Lays the dropdown out: applies the search filter, then shows a window of at
-- most DROPDOWN_MAX_ROWS matching rows starting at the current scroll offset.
--
-- The previous version positioned *every* matching row while capping only the
-- container height, and the container does not clip. In a raid, players 13+
-- were drawn straight through the bottom edge of the dropdown and over whatever
-- sat behind it — and there was no way to reach them except by typing a filter.
local function LayoutDropdownRows()
    local dd = dropdownFrame
    if not dd or not dd._allEntries then return end

    local entries = dd._allEntries
    local filterText = (dd._filter or ""):lower()

    -- Which rows match the filter, in display order.
    local matching = {}
    for i, entry in ipairs(entries) do
        if dropdownRows[i] then
            if filterText == "" or entry.name:lower():find(filterText, 1, true) then
                matching[#matching + 1] = i
            end
        end
    end

    local total = #matching
    local shown = math.min(total, DROPDOWN_MAX_ROWS)
    local maxOffset = math.max(0, total - DROPDOWN_MAX_ROWS)
    local offset = math.max(0, math.min(dd._scrollOffset or 0, maxOffset))
    dd._scrollOffset = offset
    dd._maxOffset = maxOffset

    for _, row in ipairs(dropdownRows) do row:Hide() end

    for slot = 1, shown do
        local row = dropdownRows[matching[offset + slot]]
        if row then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", dd._listContainer, "TOPLEFT", 0, -((slot - 1) * DROPDOWN_ROW_H))
            row:SetPoint("RIGHT", dd._listContainer, "RIGHT", 0, 0)
            row:Show()
        end
    end

    -- Scroll hint: shows the visible window only when there is more to reach.
    if dd._moreFS then
        if maxOffset > 0 then
            dd._moreFS:SetFormattedText("%d-%d / %d", offset + 1, offset + shown, total)
            dd._moreFS:Show()
        else
            dd._moreFS:Hide()
        end
    end

    local listH = math.max(shown * DROPDOWN_ROW_H, DROPDOWN_ROW_H)
    dd._listContainer:SetHeight(listH)
    dd:SetHeight(DROPDOWN_SEARCH_H + 1 + listH + 2 + (maxOffset > 0 and DROPDOWN_HINT_H or 0))
end

local function FilterDropdownRows(filterText)
    if not dropdownFrame then return end
    dropdownFrame._filter = filterText or ""
    dropdownFrame._scrollOffset = 0
    LayoutDropdownRows()
end

local function EnsureDropdown(parent)
    if dropdownFrame then return dropdownFrame end

    local dd = CreateFrame("Frame", "TomoDMPlayerDropdown", parent, "BackdropTemplate")
    dd:SetWidth(DROPDOWN_WIDTH)
    dd:SetFrameStrata("TOOLTIP")
    dd:SetClampedToScreen(true)
    dd:SetBackdrop({
        bgFile   = ns.FLAT,
        edgeFile = ns.FLAT,
        edgeSize = 1,
    })
    dd:SetBackdropColor(0.04, 0.07, 0.14, 0.97)
    dd:SetBackdropBorderColor(ns.ACCENT[1] * 0.5, ns.ACCENT[2] * 0.5, ns.ACCENT[3] * 0.5, 0.6)

    -- Search box
    local searchBG = CreateFrame("Frame", nil, dd)
    searchBG:SetPoint("TOPLEFT", dd, "TOPLEFT", 1, -1)
    searchBG:SetPoint("TOPRIGHT", dd, "TOPRIGHT", -1, -1)
    searchBG:SetHeight(DROPDOWN_SEARCH_H)

    local searchBGTex = searchBG:CreateTexture(nil, "BACKGROUND")
    searchBGTex:SetTexture(ns.FLAT)
    ns.Surface(searchBGTex, 1)
    searchBGTex:SetAllPoints()

    local searchBox = CreateFrame("EditBox", nil, searchBG)
    searchBox:SetPoint("LEFT", searchBG, "LEFT", 8, 0)
    searchBox:SetPoint("RIGHT", searchBG, "RIGHT", -4, 0)
    searchBox:SetHeight(DROPDOWN_SEARCH_H)
    searchBox:SetFont(ns.GetFont(), 9, "OUTLINE")
    ns.Tint(searchBox, "primary")
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(20)

    local placeholder = searchBox:CreateFontString(nil, "ARTWORK")
    placeholder:SetFont(ns.GetFont(), 9, "OUTLINE")
    ns.Tint(placeholder, "muted")
    placeholder:SetPoint("LEFT", 2, 0)
    placeholder:SetText(L["FILTER_PLAYERS"] or "Filter...")

    searchBox:HookScript("OnTextChanged", function(self)
        local text = self:GetText()
        placeholder:SetShown(text == "")
        FilterDropdownRows(text)
    end)
    searchBox:HookScript("OnEscapePressed", function(self)
        self:ClearFocus()
        HideDropdown()
    end)

    dd._searchBox = searchBox

    local searchSep = dd:CreateTexture(nil, "OVERLAY")
    searchSep:SetTexture(ns.FLAT)
    searchSep:SetVertexColor(unpack(ns.BORDER_COLOR))
    searchSep:SetHeight(0.8)
    searchSep:SetPoint("TOPLEFT", searchBG, "BOTTOMLEFT")
    searchSep:SetPoint("TOPRIGHT", searchBG, "BOTTOMRIGHT")

    -- List container. Clips, so a row that slips outside the window can never
    -- paint over whatever sits behind the dropdown.
    local listContainer = CreateFrame("Frame", nil, dd)
    listContainer:SetPoint("TOPLEFT", searchSep, "BOTTOMLEFT", 0, 0)
    listContainer:SetPoint("RIGHT", dd, "RIGHT", -1, 0)
    listContainer:SetHeight(DROPDOWN_MAX_ROWS * DROPDOWN_ROW_H)
    listContainer:SetClipsChildren(true)
    dd._listContainer = listContainer

    -- "13-24 / 30" hint, shown only when the list overflows.
    local moreFS = dd:CreateFontString(nil, "OVERLAY")
    moreFS:SetFont(ns.GetFont(), 8, "OUTLINE")
    ns.Tint(moreFS, "muted")
    moreFS:SetPoint("TOP", listContainer, "BOTTOM", 0, -1)
    moreFS:Hide()
    dd._moreFS = moreFS

    dd:EnableMouseWheel(true)
    dd:SetScript("OnMouseWheel", function(self, delta)
        if (self._maxOffset or 0) <= 0 then return end
        self._scrollOffset = (self._scrollOffset or 0) - delta
        LayoutDropdownRows()
    end)

    dd:Hide()
    dd:SetScript("OnShow", function(self)
        self._filter = ""
        self._scrollOffset = 0
        self._searchBox:SetText("")
        self._searchBox:SetFocus()
    end)

    dropdownFrame = dd
    return dd
end

local function PopulateDropdown(parent, sources, selectedGUID)
    local dd = EnsureDropdown(parent)

    -- Hide existing rows
    for _, row in ipairs(dropdownRows) do row:Hide() end

    local entries = {}
    for i, source in ipairs(sources) do
        local name = source.name
        local guid = source.sourceGUID
        local classFile = source.classFilename
        local perSec = source.amountPerSecond

        if issecretvalue(name) then name = "?" end
        if issecretvalue(guid) then guid = nil end
        if perSec and issecretvalue(perSec) then perSec = nil end

        if guid then
            entries[#entries + 1] = {
                name      = ns.StripRealm(name) or name,
                guid      = guid,
                classFile = classFile,
                perSec    = perSec,
            }
        end
    end

    dd._allEntries = entries

    for i, entry in ipairs(entries) do
        local row = dropdownRows[i]
        if not row then
            row = CreateFrame("Button", nil, dd._listContainer)
            row:SetHeight(DROPDOWN_ROW_H)
            row:SetPoint("LEFT", 0, 0)
            row:SetPoint("RIGHT", 0, 0)

            local rowHL = row:CreateTexture(nil, "HIGHLIGHT")
            rowHL:SetTexture(ns.FLAT)
            rowHL:SetVertexColor(1, 1, 1, 0.06)
            rowHL:SetAllPoints()

            local selBG = row:CreateTexture(nil, "BACKGROUND")
            selBG:SetTexture(ns.FLAT)
            selBG:SetAllPoints()
            row._selBG = selBG

            local accent = row:CreateTexture(nil, "OVERLAY")
            accent:SetTexture(ns.FLAT)
            accent:SetWidth(2)
            accent:SetPoint("TOPLEFT")
            accent:SetPoint("BOTTOMLEFT")
            row._accent = accent

            local dot = row:CreateTexture(nil, "ARTWORK")
            dot:SetTexture(ns.FLAT)
            dot:SetSize(6, 6)
            dot:SetPoint("LEFT", 8, 0)
            row._dot = dot

            local nameFS = row:CreateFontString(nil, "ARTWORK")
            nameFS:SetFont(ns.GetFont(), 9, "OUTLINE")
            nameFS:SetJustifyH("LEFT")
            nameFS:SetWordWrap(false)
            nameFS:SetNonSpaceWrap(false)
            nameFS:SetPoint("LEFT", dot, "RIGHT", 6, 0)
            nameFS:SetPoint("RIGHT", row, "RIGHT", -46, 0)
            row._nameFS = nameFS

            local dpsFS = row:CreateFontString(nil, "ARTWORK")
            dpsFS:SetFont(ns.GetFont(), 8, "OUTLINE")
            dpsFS:SetJustifyH("RIGHT")
            ns.Tint(dpsFS, "muted")
            dpsFS:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            dpsFS:SetWidth(38)
            row._dpsFS = dpsFS

            dropdownRows[i] = row
        end

        local cc = entry.classFile and RAID_CLASS_COLORS[entry.classFile]
        local isSelected = (entry.guid == selectedGUID)
        local r = cc and cc.r or 0.7
        local g = cc and cc.g or 0.7
        local b = cc and cc.b or 0.7

        row._dot:SetVertexColor(r, g, b, 1)

        if isSelected then
            row._selBG:SetVertexColor(r * 0.15, g * 0.15, b * 0.15, 0.9)
            row._accent:SetVertexColor(r, g, b, 1)
            row._accent:Show()
            row._nameFS:SetTextColor(r, g, b)
        else
            row._selBG:SetVertexColor(0, 0, 0, 0)
            row._accent:Hide()
            ns.Tint(row._nameFS, "secondary")
        end

        row._nameFS:SetText(entry.name)

        if entry.perSec and not issecretvalue(entry.perSec) and entry.perSec > 0 then
            row._dpsFS:SetText(ns.FormatNumber(entry.perSec, "1dec"))
        else
            row._dpsFS:SetText("-")
        end

        row._guid = entry.guid
        row._classFile = entry.classFile
        row._playerName = entry.name

        row:SetScript("OnClick", function(self)
            HideDropdown()
            ns.ShowSpellBreakdown(self._playerName, self._guid,
                currentMeterType, currentSessionType, self._classFile)
        end)

    end

    dd._filter = ""
    dd._scrollOffset = 0
    LayoutDropdownRows()

    return dd
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------

local function EnsureWindow()
    if breakdownFrame then return breakdownFrame end

    --------------------------------------------------------------------------
    -- Main Frame
    --------------------------------------------------------------------------

    local frame = CreateFrame("Frame", "TomoDMSpellBreakdown", UIParent, "BackdropTemplate")
    frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(360, 300, 600, 800)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    frame:SetBackdrop({
        bgFile   = ns.FLAT,
        edgeFile = ns.FLAT,
        edgeSize = BORDER_SIZE,
    })
    frame:SetBackdropColor(ns.BG[1], ns.BG[2], ns.BG[3], ns.db and ns.db.bgAlpha or ns.BG[4])
    frame:SetBackdropBorderColor(ns.BORDER_COLOR[1], ns.BORDER_COLOR[2], ns.BORDER_COLOR[3], ns.BORDER_COLOR[4])

    tinsert(UISpecialFrames, "TomoDMSpellBreakdown")

    --------------------------------------------------------------------------
    -- Header (title + close)
    --------------------------------------------------------------------------

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", BORDER_SIZE, -BORDER_SIZE)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -BORDER_SIZE, -BORDER_SIZE)
    header:SetHeight(HEADER_HEIGHT)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() frame:StartMoving() end)
    header:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    local headerBG = header:CreateTexture(nil, "BACKGROUND")
    headerBG:SetTexture(ns.FLAT)
    headerBG:SetVertexColor(unpack(ns.HEADER_BG))
    headerBG:SetAllPoints()

    local headerSep = frame:CreateTexture(nil, "OVERLAY")
    headerSep:SetTexture(ns.FLAT)
    headerSep:SetVertexColor(unpack(ns.BORDER_COLOR))
    headerSep:SetHeight(1)
    headerSep:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
    headerSep:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT")

    -- Details icon in header
    local detailsIcon = header:CreateTexture(nil, "ARTWORK")
    detailsIcon:SetTexture(ns.TEX_DETAILS)
    detailsIcon:SetSize(12, 12)
    detailsIcon:SetPoint("LEFT", header, "LEFT", TEXT_PAD, 0)
    detailsIcon:SetVertexColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3])

    -- Title
    local titleFS = header:CreateFontString(nil, "ARTWORK")
    titleFS:SetFont(ns.GetFont(), 12, "OUTLINE")
    ns.Tint(titleFS, "accent")
    titleFS:SetPoint("LEFT", detailsIcon, "RIGHT", 6, ns.GetFontNudge())
    titleFS:SetText(L["SPELL_BREAKDOWN"])

    -- Meter type label (right of title)
    local typeFS = header:CreateFontString(nil, "ARTWORK")
    typeFS:SetFont(ns.GetFont(), 10, "OUTLINE")
    ns.Tint(typeFS, "secondary")
    typeFS:SetPoint("LEFT", titleFS, "RIGHT", 8, 0)
    frame._typeFS = typeFS

    -- Close button
    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(HEADER_HEIGHT, HEADER_HEIGHT)
    closeBtn:SetPoint("TOPRIGHT", header, "TOPRIGHT")
    closeBtn:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT")
    local closeIcon = closeBtn:CreateTexture(nil, "ARTWORK")
    closeIcon:SetTexture(ns.TEX_CLOSE)
    closeIcon:SetSize(10, 10)
    closeIcon:SetPoint("CENTER")
    closeIcon:SetVertexColor(unpack(ns.TEXT_MUTED))
    closeBtn:SetScript("OnClick", function() frame:Hide(); HideDropdown() end)
    closeBtn:SetScript("OnEnter", function() closeIcon:SetVertexColor(1, 1, 1) end)
    closeBtn:SetScript("OnLeave", function() closeIcon:SetVertexColor(unpack(ns.TEXT_MUTED)) end)
    local closeHL = closeBtn:CreateTexture(nil, "HIGHLIGHT")
    closeHL:SetTexture(ns.FLAT)
    closeHL:SetVertexColor(1, 1, 1, 0.06)
    closeHL:SetAllPoints()

    --------------------------------------------------------------------------
    -- Player Strip (horizontal scrollable row + overflow dropdown button)
    --------------------------------------------------------------------------

    local playerStrip = CreateFrame("Frame", nil, frame)
    playerStrip:SetPoint("TOPLEFT", headerSep, "BOTTOMLEFT", BORDER_SIZE, 0)
    playerStrip:SetPoint("TOPRIGHT", headerSep, "BOTTOMRIGHT", -BORDER_SIZE, 0)
    playerStrip:SetHeight(PLAYER_STRIP_H)

    local stripBG = playerStrip:CreateTexture(nil, "BACKGROUND")
    stripBG:SetTexture(ns.FLAT)
    ns.Surface(stripBG, 1)
    stripBG:SetAllPoints()

    -- Dropdown toggle button (right side of strip)
    local ddToggle = CreateFrame("Button", nil, playerStrip)
    ddToggle:SetSize(28, PLAYER_STRIP_H)
    ddToggle:SetPoint("TOPRIGHT", playerStrip, "TOPRIGHT", 0, 0)
    ddToggle:SetPoint("BOTTOMRIGHT", playerStrip, "BOTTOMRIGHT", 0, 0)

    local ddToggleBG = ddToggle:CreateTexture(nil, "BACKGROUND")
    ddToggleBG:SetTexture(ns.FLAT)
    ns.Surface(ddToggleBG, 1)
    ddToggleBG:SetAllPoints()

    local ddToggleSep = ddToggle:CreateTexture(nil, "OVERLAY")
    ddToggleSep:SetTexture(ns.FLAT)
    ddToggleSep:SetVertexColor(unpack(ns.BORDER_COLOR))
    ddToggleSep:SetWidth(0.8)
    ddToggleSep:SetPoint("TOPLEFT", ddToggle, "TOPLEFT")
    ddToggleSep:SetPoint("BOTTOMLEFT", ddToggle, "BOTTOMLEFT")

    local ddCountFS = ddToggle:CreateFontString(nil, "ARTWORK")
    ddCountFS:SetFont(ns.GetFont(), 8, "OUTLINE")
    ns.Tint(ddCountFS, "accent")
    ddCountFS:SetPoint("CENTER", ddToggle, "CENTER", -2, 0)
    frame._ddCountFS = ddCountFS

    local ddChevron = ddToggle:CreateTexture(nil, "ARTWORK")
    ddChevron:SetTexture(ns.TEX_CHEVRON)
    ddChevron:SetSize(6, 6)
    ddChevron:SetPoint("LEFT", ddCountFS, "RIGHT", 1, 0)
    ddChevron:SetVertexColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3])
    ddChevron:SetTexCoord(0, 1, 0, 1)

    local ddToggleHL = ddToggle:CreateTexture(nil, "HIGHLIGHT")
    ddToggleHL:SetTexture(ns.FLAT)
    ddToggleHL:SetVertexColor(1, 1, 1, 0.06)
    ddToggleHL:SetAllPoints()

    frame._ddToggle = ddToggle

    -- Scroll frame for player buttons (left of toggle)
    local stripScroll = CreateFrame("ScrollFrame", nil, playerStrip)
    stripScroll:SetPoint("TOPLEFT", playerStrip, "TOPLEFT", 2, -2)
    stripScroll:SetPoint("BOTTOMRIGHT", ddToggle, "BOTTOMLEFT", -2, 2)
    stripScroll:EnableMouseWheel(true)
    stripScroll:SetScript("OnMouseWheel", function(self, delta)
        local h = self:GetHorizontalScroll()
        local maxH = math.max(0, (self._childWidth or 0) - self:GetWidth())
        self:SetHorizontalScroll(math.max(0, math.min(maxH, h - delta * 40)))
    end)

    local stripChild = CreateFrame("Frame", nil, stripScroll)
    stripChild:SetHeight(PLAYER_STRIP_H - 4)
    stripScroll:SetScrollChild(stripChild)

    frame._stripScroll = stripScroll
    frame._stripChild = stripChild
    frame._playerStrip = playerStrip

    local stripSep = frame:CreateTexture(nil, "OVERLAY")
    stripSep:SetTexture(ns.FLAT)
    stripSep:SetVertexColor(unpack(ns.BORDER_COLOR))
    stripSep:SetHeight(0.8)
    stripSep:SetPoint("TOPLEFT", playerStrip, "BOTTOMLEFT")
    stripSep:SetPoint("TOPRIGHT", playerStrip, "BOTTOMRIGHT")

    --------------------------------------------------------------------------
    -- Column Header Bar
    --------------------------------------------------------------------------

    local colHeader = CreateFrame("Frame", nil, frame)
    colHeader:SetPoint("TOPLEFT", stripSep, "BOTTOMLEFT", 0, 0)
    colHeader:SetPoint("TOPRIGHT", stripSep, "BOTTOMRIGHT", 0, 0)
    colHeader:SetHeight(COLHEAD_HEIGHT)

    local colHeaderBG = colHeader:CreateTexture(nil, "BACKGROUND")
    colHeaderBG:SetTexture(ns.FLAT)
    ns.Surface(colHeaderBG, 0.80)
    colHeaderBG:SetAllPoints()

    local colHeaderSep = frame:CreateTexture(nil, "OVERLAY")
    colHeaderSep:SetTexture(ns.FLAT)
    colHeaderSep:SetVertexColor(unpack(ns.BORDER_COLOR))
    colHeaderSep:SetHeight(0.8)
    colHeaderSep:SetPoint("TOPLEFT", colHeader, "BOTTOMLEFT", 1, 0)
    colHeaderSep:SetPoint("TOPRIGHT", colHeader, "BOTTOMRIGHT", -1, 0)

    local function MakeColLabel(parent, text, width, anchorTo)
        local fs = parent:CreateFontString(nil, "ARTWORK")
        fs:SetFont(ns.GetFont(), 9, "OUTLINE")
        ns.Tint(fs, "muted")
        fs:SetJustifyH("RIGHT")
        fs:SetWidth(width)
        if anchorTo then
            fs:SetPoint("RIGHT", anchorTo, "LEFT", -4, 0)
        else
            fs:SetPoint("RIGHT", parent, "RIGHT", -TEXT_PAD, 0)
        end
        fs:SetText(text)
        return fs
    end

    local colPct    = MakeColLabel(colHeader, "%",                     ns.ColWidth(PCT_CHARS),    nil)
    local colPerSec = MakeColLabel(colHeader, "/s",                    ns.ColWidth(PERSEC_CHARS), colPct)
    local colTotal  = MakeColLabel(colHeader, L["BREAKDOWN_COL_TOTAL"], ns.ColWidth(TOTAL_CHARS),  colPerSec)

    local colSpell = colHeader:CreateFontString(nil, "ARTWORK")
    colSpell:SetFont(ns.GetFont(), 9, "OUTLINE")
    ns.Tint(colSpell, "muted")
    colSpell:SetJustifyH("LEFT")
    colSpell:SetPoint("LEFT", colHeader, "LEFT", ns.ColWidth(RANK_CHARS) + SPELL_BAR_H + ICON_PAD + TEXT_PAD + 4, 0)
    colSpell:SetPoint("RIGHT", colTotal, "LEFT", -4, 0)
    colSpell:SetText(L["BREAKDOWN_COL_SPELL"])

    --------------------------------------------------------------------------
    -- Resize Handle
    --------------------------------------------------------------------------

    local resizeHandle = CreateFrame("Button", nil, frame)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
    resizeHandle:SetFrameLevel(frame:GetFrameLevel() + 10)
    local gripTex = resizeHandle:CreateTexture(nil, "OVERLAY")
    gripTex:SetTexture(ns.FLAT)
    gripTex:SetVertexColor(0.4, 0.4, 0.43, 0.5)
    gripTex:SetSize(6, 6)
    gripTex:SetPoint("BOTTOMRIGHT", -3, 3)
    resizeHandle:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then frame:StartSizing("BOTTOMRIGHT") end
    end)
    resizeHandle:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
    resizeHandle:SetScript("OnEnter", function() gripTex:SetVertexColor(0.7, 0.7, 0.73, 0.8) end)
    resizeHandle:SetScript("OnLeave", function() gripTex:SetVertexColor(0.4, 0.4, 0.43, 0.5) end)

    --------------------------------------------------------------------------
    -- Spell ScrollBox
    --------------------------------------------------------------------------

    local spellScroll = CreateFrame("Frame", nil, frame, "WowScrollBoxList")

    local spellScrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    spellScrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(BORDER_SIZE + 1), -(HEADER_HEIGHT + PLAYER_STRIP_H + COLHEAD_HEIGHT + 3))
    spellScrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(BORDER_SIZE + 1), BORDER_SIZE)
    spellScrollBar:SetWidth(ns.SCROLLBAR_WIDTH)

    -- Style scrollbar
    do
        if spellScrollBar.Back then spellScrollBar.Back:SetAlpha(0) end
        if spellScrollBar.Forward then spellScrollBar.Forward:SetAlpha(0) end
        local track = spellScrollBar.Track
        if track then
            track:ClearAllPoints()
            track:SetPoint("TOPLEFT", 0, 0)
            track:SetPoint("BOTTOMRIGHT", 0, 0)
            for _, key in ipairs({"Begin", "Middle", "End"}) do
                local tex = track[key]
                if tex then tex:SetAlpha(0) end
            end
            local thumb = track.Thumb
            if thumb then
                for _, key in ipairs({"Begin", "Middle", "End"}) do
                    local tex = thumb[key]
                    if tex then tex:SetAlpha(0) end
                end
                local thumbBG = thumb:CreateTexture(nil, "ARTWORK")
                thumbBG:SetTexture(ns.FLAT)
                thumbBG:SetVertexColor(ns.SCROLLBAR_THUMB[1], ns.SCROLLBAR_THUMB[2], ns.SCROLLBAR_THUMB[3], 0.7)
                thumbBG:SetPoint("TOPLEFT", 0, -1)
                thumbBG:SetPoint("BOTTOMRIGHT", 0, 1)
                thumb:HookScript("OnEnter", function()
                    thumbBG:SetVertexColor(0.55, 0.55, 0.60, 0.9)
                end)
                thumb:HookScript("OnLeave", function()
                    thumbBG:SetVertexColor(ns.SCROLLBAR_THUMB[1], ns.SCROLLBAR_THUMB[2], ns.SCROLLBAR_THUMB[3], 0.7)
                end)
            end
        end
    end

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(SPELL_BAR_H + SPELL_BAR_SP)
    view:SetPadding(0, 0, 0, 0, 0)

    local dataProvider = CreateDataProvider()
    frame._dataProvider = dataProvider

    --------------------------------------------------------------------------
    -- Spell bar element initializer
    --------------------------------------------------------------------------

    view:SetElementInitializer("Frame", function(button, data)
        if not button._init then
            button:SetHeight(SPELL_BAR_H + SPELL_BAR_SP)

            local rankFS = button:CreateFontString(nil, "ARTWORK")
            rankFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            ns.Tint(rankFS, "muted")
            rankFS:SetJustifyH("RIGHT")
            rankFS:SetWordWrap(false)
            rankFS:SetPoint("LEFT", 2, ns.GetFontNudge())
            button._rankFS = rankFS

            local icon = button:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("LEFT", rankFS, "RIGHT", 2, 0)
            icon:SetSize(SPELL_BAR_H - 2, SPELL_BAR_H - 2)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            button._icon = icon

            local bar = CreateFrame("StatusBar", nil, button)
            bar:SetStatusBarTexture(ns.FLAT)
            bar:SetPoint("TOPLEFT", icon, "TOPRIGHT", ICON_PAD, 0)
            bar:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, SPELL_BAR_SP)
            button._bar = bar

            local spellNameFS = bar:CreateFontString(nil, "OVERLAY")
            spellNameFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            spellNameFS:SetJustifyH("LEFT")
            spellNameFS:SetWordWrap(false)
            spellNameFS:SetNonSpaceWrap(false)
            spellNameFS:SetShadowOffset(1, -1)
            spellNameFS:SetShadowColor(0, 0, 0, 0.4)
            button._nameFS = spellNameFS

            local totalFS = bar:CreateFontString(nil, "OVERLAY")
            totalFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            totalFS:SetJustifyH("RIGHT")
            totalFS:SetWordWrap(false)
            totalFS:SetShadowOffset(1, -1)
            totalFS:SetShadowColor(0, 0, 0, 0.4)
            button._totalFS = totalFS

            local perSecFS = bar:CreateFontString(nil, "OVERLAY")
            perSecFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            perSecFS:SetJustifyH("RIGHT")
            perSecFS:SetWordWrap(false)
            ns.Tint(perSecFS, "secondary")
            perSecFS:SetShadowOffset(1, -1)
            perSecFS:SetShadowColor(0, 0, 0, 0.4)
            button._perSecFS = perSecFS

            local pctFS = bar:CreateFontString(nil, "OVERLAY")
            pctFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            pctFS:SetJustifyH("RIGHT")
            pctFS:SetWordWrap(false)
            pctFS:SetShadowOffset(1, -1)
            pctFS:SetShadowColor(0, 0, 0, 0.4)
            button._pctFS = pctFS

            local hl = button:CreateTexture(nil, "HIGHLIGHT")
            hl:SetTexture(ns.FLAT)
            hl:SetVertexColor(1, 1, 1, 0.08)
            hl:SetAllPoints()

            -- Hover tooltip: per-spell detail incl. Midnight extras
            -- (caster pet, overkill, avoidable / killing-blow flags).
            button:EnableMouse(true)
            button:SetScript("OnEnter", function(self)
                if self._data and ns.BuildSpellTooltip then
                    ns.BuildSpellTooltip(self, self._data)
                end
            end)
            button:SetScript("OnLeave", function() GameTooltip:Hide() end)

            button._init = true
        end

        button._data = data

        local nudge = ns.GetFontNudge()

        button._rankFS:SetWidth(ns.ColWidth(RANK_CHARS))
        button._rankFS:SetText(data.rank .. ".")
        button._icon:SetTexture(data.icon or 134400)

        local r, g, b = ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3]
        if data.classColor then
            r, g, b = data.classColor.r, data.classColor.g, data.classColor.b
        end
        button._bar:SetStatusBarColor(r, g, b, 1)
        local fill = button._bar:GetStatusBarTexture()
        fill:SetGradient("HORIZONTAL",
            CreateColor(r * 0.7, g * 0.7, b * 0.7, 1),
            CreateColor(r * 0.25, g * 0.25, b * 0.25, 1))
        fill:SetAlpha(ns.BAR_ALPHA)

        button._bar:SetMinMaxValues(0, data.maxTotal or 1)
        button._bar:SetValue(data.total or 0)

        button._nameFS:SetText(data.displayName or data.name or "?")
        ns.Tint(button._nameFS, "primary")

        button._pctFS:SetText(string.format("%.1f%%", data.pct or 0))
        button._pctFS:SetTextColor(r, g, b)

        -- ACTIONS meters count events, not damage: interrupts read "5", not
        -- "5.0". RATE_PRIMARY is false exactly for those types.
        local totalFmt = ns.RATE_PRIMARY[currentMeterType] and "1dec" or "int"
        button._totalFS:SetText(ns.FormatNumber(data.total or 0, totalFmt))
        ns.Tint(button._totalFS, "primary")

        if data.perSec and not issecretvalue(data.perSec) and data.perSec > 0 then
            button._perSecFS:SetText(ns.FormatNumber(data.perSec, "1dec"))
        else
            button._perSecFS:SetText("-")
        end

        button._pctFS:ClearAllPoints()
        button._pctFS:SetPoint("RIGHT", button._bar, "RIGHT", -TEXT_PAD, nudge)
        button._pctFS:SetWidth(ns.ColWidth(PCT_CHARS))

        button._perSecFS:ClearAllPoints()
        button._perSecFS:SetPoint("RIGHT", button._pctFS, "LEFT", -4, 0)
        button._perSecFS:SetWidth(ns.ColWidth(PERSEC_CHARS))

        button._totalFS:ClearAllPoints()
        button._totalFS:SetPoint("RIGHT", button._perSecFS, "LEFT", -4, 0)
        button._totalFS:SetWidth(ns.ColWidth(TOTAL_CHARS))

        button._nameFS:ClearAllPoints()
        button._nameFS:SetPoint("LEFT", button._bar, "LEFT", TEXT_PAD, nudge)
        button._nameFS:SetPoint("RIGHT", button._totalFS, "LEFT", -4, 0)
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(spellScroll, spellScrollBar, view)

    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", colHeaderSep, "BOTTOMLEFT", BORDER_SIZE, 0),
        CreateAnchor("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(ns.SCROLLBAR_WIDTH + BORDER_SIZE + 2), BORDER_SIZE),
    }
    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", colHeaderSep, "BOTTOMLEFT", BORDER_SIZE, 0),
        CreateAnchor("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -BORDER_SIZE, BORDER_SIZE),
    }
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(spellScroll, spellScrollBar,
        anchorsWithBar, anchorsWithoutBar)

    spellScroll:SetDataProvider(dataProvider)

    -- No data text
    local noDataFS = frame:CreateFontString(nil, "ARTWORK")
    noDataFS:SetFont(ns.GetFont(), 11, "OUTLINE")
    ns.Tint(noDataFS, "muted")
    noDataFS:SetPoint("CENTER", spellScroll, "CENTER", 0, 0)
    noDataFS:SetText(L["NO_DATA"])
    noDataFS:Hide()
    frame._noDataFS = noDataFS

    -- Close dropdown when main frame hides
    frame:HookScript("OnHide", HideDropdown)

    frame:Hide()
    breakdownFrame = frame
    return frame
end

----------------------------------------------------------------------
-- Player Strip: build clickable buttons (scrollable + dropdown)
----------------------------------------------------------------------

-- Re-tint the strip to mark `selectedGUID` as active. Cheap: touches only the
-- already-built buttons, so switching the selected player never rebuilds the
-- strip (and never allocates a frame).
local function UpdatePlayerStripSelection(selectedGUID)
    for _, btn in ipairs(playerButtons) do
        if btn:IsShown() then
            local cc = btn._classFile and RAID_CLASS_COLORS[btn._classFile]
            if btn._guid == selectedGUID then
                btn._bg:SetVertexColor(
                    cc and cc.r * 0.3 or ns.ACCENT[1] * 0.3,
                    cc and cc.g * 0.3 or ns.ACCENT[2] * 0.3,
                    cc and cc.b * 0.3 or ns.ACCENT[3] * 0.3, 0.90)
                btn._text:SetTextColor(cc and cc.r or 1, cc and cc.g or 1, cc and cc.b or 1)
            else
                ns.Surface(btn._bg, 0.70)
                ns.Tint(btn._text, "muted")
            end
        end
    end
end

local function BuildPlayerStrip(frame, meterType, sessionType, selectedGUID)
    local stripChild = frame._stripChild

    -- Hide old buttons. `playerButtons` is a persistent pool indexed 1..n and
    -- is deliberately NOT wiped: wiping it made `playerButtons[n]` nil on every
    -- pass, so each rebuild allocated a fresh Button that could never be
    -- reclaimed (WoW frames are not garbage collected).
    for _, btn in ipairs(playerButtons) do
        btn:Hide()
    end

    -- Get session data for player list
    local session = C_DamageMeter.GetCombatSessionFromType(sessionType, meterType)
    if not session or issecretvalue(session) then
        frame._ddToggle:Hide()
        return nil
    end
    local sources = session.combatSources
    if not sources or #sources == 0 then
        frame._ddToggle:Hide()
        return nil
    end

    local xOff = 0
    local firstGUID = nil
    local totalPlayers = 0

    for i, source in ipairs(sources) do
        local name = source.name
        local guid = source.sourceGUID
        local classFile = source.classFilename

        if not name or issecretvalue(name) then name = "?" end
        if issecretvalue(guid) then guid = nil end

        if guid then
            totalPlayers = totalPlayers + 1
            if not firstGUID then firstGUID = guid end

            local btn = playerButtons[totalPlayers]
            if not btn then
                btn = CreateFrame("Button", nil, stripChild)
                btn:SetHeight(PLAYER_STRIP_H - 4)
                playerButtons[totalPlayers] = btn

                local bg = btn:CreateTexture(nil, "BACKGROUND")
                bg:SetTexture(ns.FLAT)
                bg:SetAllPoints()
                btn._bg = bg

                local text = btn:CreateFontString(nil, "ARTWORK")
                text:SetFont(ns.GetFont(), 9, "OUTLINE")
                text:SetPoint("CENTER", 0, 0)
                text:SetWordWrap(false)
                text:SetNonSpaceWrap(false)
                btn._text = text

                local hl = btn:CreateTexture(nil, "HIGHLIGHT")
                hl:SetTexture(ns.FLAT)
                hl:SetVertexColor(1, 1, 1, 0.08)
                hl:SetAllPoints()
            end

            local shortName = ns.StripRealm(name) or name
            btn._text:SetText(shortName)

            -- Store data for click
            btn._guid = guid
            btn._classFile = classFile
            btn._playerName = shortName

            btn:SetScript("OnClick", function(self)
                HideDropdown()
                ns.ShowSpellBreakdown(self._playerName, self._guid,
                    currentMeterType, currentSessionType, self._classFile)
            end)

            local textW = btn._text:GetStringWidth()
            btn:SetWidth(math.max(textW + 12, 40))
            btn:ClearAllPoints()
            btn:SetPoint("LEFT", stripChild, "LEFT", xOff, 0)
            btn:Show()

            xOff = xOff + btn:GetWidth() + 2
        end
    end

    -- Update scroll child width for horizontal scrolling
    stripChild:SetWidth(math.max(xOff, 1))
    frame._stripScroll._childWidth = xOff

    -- Reset scroll position
    frame._stripScroll:SetHorizontalScroll(0)

    -- Show/update dropdown toggle with player count
    frame._ddCountFS:SetText(tostring(totalPlayers))
    frame._ddToggle:Show()

    -- Wire dropdown toggle. Reads `currentGUID` at click time rather than the
    -- `selectedGUID` upvalue, which goes stale as soon as the selection changes
    -- without a rebuild.
    frame._ddToggle:SetScript("OnClick", function(self)
        if dropdownFrame and dropdownFrame:IsShown() then
            HideDropdown()
            return
        end
        local dd = PopulateDropdown(breakdownFrame, sources, currentGUID)
        dd:ClearAllPoints()
        dd:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -2)
        dd:Show()
    end)

    UpdatePlayerStripSelection(selectedGUID)

    return firstGUID
end

----------------------------------------------------------------------
-- Populate spell list for a given player
----------------------------------------------------------------------

local function PopulateSpells(frame, sourceGUID, meterType, sessionType, classFilename)
    local classColor = classFilename and RAID_CLASS_COLORS[classFilename]
    local info = ns.TYPE_INFO[meterType]
    local rateKey = info and info.key

    local spells, grandTotal = ns.GetSpellBreakdown(sessionType, meterType, sourceGUID)

    frame._dataProvider:Flush()

    if not spells or #spells == 0 then
        frame._noDataFS:Show()
        frame:Show()
        return
    end

    frame._noDataFS:Hide()

    local maxTotal = spells[1].total
    local elements = {}
    for i, spell in ipairs(spells) do
        -- Pet / guardian attribution appended in a muted colour, while the
        -- raw spell name is kept on `name` for the tooltip title.
        local displayName = spell.name
        if spell.creatureName then
            displayName = displayName .. "  |cff8a8a99(" .. spell.creatureName .. ")|r"
        end
        elements[#elements + 1] = {
            rank        = i,
            name        = spell.name,
            displayName = displayName,
            icon        = spell.icon,
            total       = spell.total,
            perSec      = spell.perSec,
            pct         = spell.pct,
            maxTotal    = maxTotal,
            classColor  = classColor,
            rateKey     = rateKey,
            creatureName = spell.creatureName,
            overkill    = spell.overkill,
            isAvoidable = spell.isAvoidable,
            isDeadly    = spell.isDeadly,
        }
    end
    frame._dataProvider:InsertTable(elements)
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

function ns.ShowSpellBreakdown(playerName, sourceGUID, meterType, sessionType, classFilename)
    local frame = EnsureWindow()

    -- Apply opacity
    frame:SetAlpha(ns.db and ns.db.breakdownAlpha or 0.85)

    currentMeterType = meterType
    currentSessionType = sessionType

    -- Update meter type label
    local info = ns.TYPE_INFO[meterType]
    if info then
        frame._typeFS:SetText("— " .. (L[info.key] or info.key))
    else
        frame._typeFS:SetText("")
    end

    -- Build player strip and auto-select first if no GUID given
    local firstGUID = BuildPlayerStrip(frame, meterType, sessionType, sourceGUID)

    if not sourceGUID then
        sourceGUID = firstGUID
        -- Find classFilename for first player
        if sourceGUID then
            local session = C_DamageMeter.GetCombatSessionFromType(sessionType, meterType)
            if session and not issecretvalue(session) and session.combatSources then
                for _, src in ipairs(session.combatSources) do
                    local g = src.sourceGUID
                    -- Guard before the comparison: enemy / mid-combat sources can
                    -- carry a secret GUID, and comparing one in Lua errors out.
                    if g ~= nil and not issecretvalue(g) and g == sourceGUID then
                        classFilename = src.classFilename
                        local n = src.name
                        if n ~= nil and not issecretvalue(n) then
                            playerName = ns.StripRealm(n) or n
                        end
                        break
                    end
                end
            end
        end
    end

    currentGUID = sourceGUID

    if not sourceGUID then
        frame._dataProvider:Flush()
        frame._noDataFS:Show()
        frame:Show()
        return
    end

    -- Refresh player strip highlighting. Re-tint only — rebuilding here was the
    -- second of two full strip builds per open.
    UpdatePlayerStripSelection(sourceGUID)

    -- Populate spell list
    PopulateSpells(frame, sourceGUID, meterType, sessionType, classFilename)

    frame:Show()
end

function ns.HideSpellBreakdown()
    HideDropdown()
    if breakdownFrame then
        breakdownFrame:Hide()
        breakdownFrame._dataProvider:Flush()
    end
end

function ns.ApplyBreakdownAlpha()
    if breakdownFrame then
        local alpha = ns.db and ns.db.breakdownAlpha or 0.85
        breakdownFrame:SetAlpha(alpha)
    end
end

----------------------------------------------------------------------
-- ShowTargetSpells: open breakdown for an enemy target in a segment.
-- Uses GetCombatSessionSourceFromID + sourceCreatureID (no GUID needed).
----------------------------------------------------------------------

function ns.ShowTargetSpells(targetName, sourceCreatureID, sessionID)
    local frame = EnsureWindow()

    frame:SetAlpha(ns.db and ns.db.breakdownAlpha or 0.85)
    currentMeterType = Enum.DamageMeterType.DamageDone
    currentSessionType = nil

    -- Update header labels
    frame._typeFS:SetText("— " .. (targetName or L["ENEMY_DAMAGE"]))

    -- Hide player strip (not applicable for segment view)
    for _, btn in ipairs(playerButtons) do btn:Hide() end
    frame._ddToggle:Hide()

    local playerGUID = UnitGUID("player")
    currentGUID = playerGUID

    -- Fetch the player's spell breakdown for this segment via DamageDone
    local spells, grandTotal
    if sessionID and playerGUID then
        spells, grandTotal = ns.GetSpellBreakdownBySegment(
            sessionID, Enum.DamageMeterType.DamageDone, playerGUID)
    end

    -- Get player class for bar coloring
    local _, classFile = UnitClass("player")
    local classColor = classFile and RAID_CLASS_COLORS[classFile]

    frame._dataProvider:Flush()

    if not spells or #spells == 0 then
        frame._noDataFS:Show()
        frame:Show()
        return
    end

    frame._noDataFS:Hide()

    local maxTotal = spells[1].total
    local elements = {}
    for i, spell in ipairs(spells) do
        local displayName = spell.name
        if spell.creatureName then
            displayName = displayName .. "  |cff8a8a99(" .. spell.creatureName .. ")|r"
        end
        elements[#elements + 1] = {
            rank        = i,
            name        = spell.name,
            displayName = displayName,
            icon        = spell.icon,
            total       = spell.total,
            perSec      = spell.perSec,
            pct         = spell.pct,
            maxTotal    = maxTotal,
            classColor  = classColor,
            creatureName = spell.creatureName,
            overkill    = spell.overkill,
            isAvoidable = spell.isAvoidable,
            isDeadly    = spell.isDeadly,
        }
    end
    frame._dataProvider:InsertTable(elements)
    frame:Show()
end

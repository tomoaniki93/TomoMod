local ADDON_NAME, ns = ...
local L = ns.L

----------------------------------------------------------------------
-- TargetBreakdown: Segment Browser
-- Level 1: list of combat segments from GetAvailableCombatSessions()
-- Level 2: enemies (EnemyDamageTaken) for a selected segment
-- Click enemy → Spell Breakdown via sourceCreatureID
----------------------------------------------------------------------

local WINDOW_WIDTH   = 420
local WINDOW_HEIGHT  = 480
local HEADER_HEIGHT  = 26
local COLHEAD_HEIGHT = 16
local BAR_H          = 20
local BAR_SP         = 1
local TEXT_PAD       = 6
local BORDER_SIZE    = 1

-- Column widths

-- Column budgets in characters. Converted to pixels at render time against the
-- active font size (ns.ColWidth), because these rows use ns.GetFontSize() and
-- fixed pixel widths silently clipped as soon as the user raised it.
local RANK_CHARS   = 4   -- "100."
local PCT_CHARS    = 6   -- "100.0%"
local PERSEC_CHARS = 6   -- "999.9K"
local TOTAL_CHARS  = 7   -- "999.9K" + margin

----------------------------------------------------------------------
-- Singleton & State
----------------------------------------------------------------------

local breakdownFrame = nil
local viewMode = "segments"       -- "segments" or "enemies"
local selectedSessionID = nil
local selectedSegmentName = nil

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

-- Get a display name for a segment by looking at its top enemy target
local function GetSegmentLabel(sessionID)
    local ok, session = pcall(C_DamageMeter.GetCombatSessionFromID,
        sessionID, Enum.DamageMeterType.EnemyDamageTaken)
    if ok and session and not issecretvalue(session)
        and session.combatSources and #session.combatSources > 0 then
        local name = session.combatSources[1].name
        if name and not issecretvalue(name) then return name end
    end
    return nil
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------

local function EnsureWindow()
    if breakdownFrame then return breakdownFrame end

    --------------------------------------------------------------------------
    -- Main Frame
    --------------------------------------------------------------------------

    local frame = CreateFrame("Frame", "TomoDMTargetBreakdown", UIParent, "BackdropTemplate")
    frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", -200, 0)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(340, 250, 600, 800)
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

    tinsert(UISpecialFrames, "TomoDMTargetBreakdown")

    --------------------------------------------------------------------------
    -- Header
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

    -- Icon
    local targetIcon = header:CreateTexture(nil, "ARTWORK")
    targetIcon:SetTexture(ns.TEX_TARGET)
    targetIcon:SetSize(12, 12)
    targetIcon:SetPoint("LEFT", header, "LEFT", TEXT_PAD, 0)
    targetIcon:SetVertexColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3])

    -- Title
    local titleFS = header:CreateFontString(nil, "ARTWORK")
    titleFS:SetFont(ns.GetFont(), 12, "OUTLINE")
    ns.Tint(titleFS, "accent")
    titleFS:SetPoint("LEFT", targetIcon, "RIGHT", 6, ns.GetFontNudge())
    frame._titleFS = titleFS

    -- Subtitle (right of title)
    local subtitleFS = header:CreateFontString(nil, "ARTWORK")
    subtitleFS:SetFont(ns.GetFont(), 10, "OUTLINE")
    ns.Tint(subtitleFS, "secondary")
    subtitleFS:SetPoint("LEFT", titleFS, "RIGHT", 8, 0)
    frame._subtitleFS = subtitleFS

    -- Back button (visible in enemies view)
    local backBtn = CreateFrame("Button", nil, header)
    backBtn:SetSize(HEADER_HEIGHT, HEADER_HEIGHT)
    backBtn:SetPoint("TOPRIGHT", header, "TOPRIGHT", -HEADER_HEIGHT, 0)
    backBtn:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -HEADER_HEIGHT, 0)
    local backIcon = backBtn:CreateTexture(nil, "ARTWORK")
    backIcon:SetTexture(ns.TEX_CHEVRON)
    backIcon:SetSize(8, 8)
    backIcon:SetPoint("CENTER")
    backIcon:SetVertexColor(unpack(ns.TEXT_MUTED))
    backIcon:SetTexCoord(1, 0, 0, 1) -- flip horizontally for "back" arrow
    backBtn:SetScript("OnEnter", function() backIcon:SetVertexColor(1, 1, 1) end)
    backBtn:SetScript("OnLeave", function() backIcon:SetVertexColor(unpack(ns.TEXT_MUTED)) end)
    local backHL = backBtn:CreateTexture(nil, "HIGHLIGHT")
    backHL:SetTexture(ns.FLAT)
    backHL:SetVertexColor(1, 1, 1, 0.06)
    backHL:SetAllPoints()
    frame._backBtn = backBtn

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
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeIcon:SetVertexColor(1, 1, 1) end)
    closeBtn:SetScript("OnLeave", function() closeIcon:SetVertexColor(unpack(ns.TEXT_MUTED)) end)
    local closeHL = closeBtn:CreateTexture(nil, "HIGHLIGHT")
    closeHL:SetTexture(ns.FLAT)
    closeHL:SetVertexColor(1, 1, 1, 0.06)
    closeHL:SetAllPoints()

    --------------------------------------------------------------------------
    -- Column Header
    --------------------------------------------------------------------------

    local colHeader = CreateFrame("Frame", nil, frame)
    colHeader:SetPoint("TOPLEFT", headerSep, "BOTTOMLEFT", 0, 0)
    colHeader:SetPoint("TOPRIGHT", headerSep, "BOTTOMRIGHT", 0, 0)
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

    local colPct    = MakeColLabel(colHeader, "%",                      ns.ColWidth(PCT_CHARS),    nil)
    local colPerSec = MakeColLabel(colHeader, "/s",                     ns.ColWidth(PERSEC_CHARS), colPct)
    local colTotal  = MakeColLabel(colHeader, L["BREAKDOWN_COL_TOTAL"], ns.ColWidth(TOTAL_CHARS),  colPerSec)

    local colName = colHeader:CreateFontString(nil, "ARTWORK")
    colName:SetFont(ns.GetFont(), 9, "OUTLINE")
    ns.Tint(colName, "muted")
    colName:SetJustifyH("LEFT")
    colName:SetPoint("LEFT", colHeader, "LEFT", ns.ColWidth(RANK_CHARS) + TEXT_PAD + 4, 0)
    colName:SetPoint("RIGHT", colTotal, "LEFT", -4, 0)
    frame._colName = colName

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
    -- ScrollBox
    --------------------------------------------------------------------------

    local scroll = CreateFrame("Frame", nil, frame, "WowScrollBoxList")

    local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(BORDER_SIZE + 1), -(HEADER_HEIGHT + COLHEAD_HEIGHT + 3))
    scrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(BORDER_SIZE + 1), BORDER_SIZE)
    scrollBar:SetWidth(ns.SCROLLBAR_WIDTH)

    do
        if scrollBar.Back then scrollBar.Back:SetAlpha(0) end
        if scrollBar.Forward then scrollBar.Forward:SetAlpha(0) end
        local track = scrollBar.Track
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
    view:SetElementExtent(BAR_H + BAR_SP)
    view:SetPadding(0, 0, 0, 0, 0)

    local dataProvider = CreateDataProvider()
    frame._dataProvider = dataProvider

    --------------------------------------------------------------------------
    -- Bar element initializer (shared for both views)
    --------------------------------------------------------------------------

    view:SetElementInitializer("Frame", function(button, data)
        if not button._init then
            button:SetHeight(BAR_H + BAR_SP)
            button:EnableMouse(true)

            local rankFS = button:CreateFontString(nil, "ARTWORK")
            rankFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            ns.Tint(rankFS, "muted")
            rankFS:SetJustifyH("RIGHT")
            rankFS:SetWordWrap(false)
            rankFS:SetPoint("LEFT", 2, ns.GetFontNudge())
            button._rankFS = rankFS

            local bar = CreateFrame("StatusBar", nil, button)
            bar:SetStatusBarTexture(ns.FLAT)
            bar:EnableMouse(false)
            bar:SetPoint("TOPLEFT", rankFS, "TOPRIGHT", 2, 0)
            bar:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, BAR_SP)
            button._bar = bar

            local nameFS = bar:CreateFontString(nil, "OVERLAY")
            nameFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            nameFS:SetJustifyH("LEFT")
            nameFS:SetWordWrap(false)
            nameFS:SetNonSpaceWrap(false)
            nameFS:SetShadowOffset(1, -1)
            nameFS:SetShadowColor(0, 0, 0, 0.4)
            button._nameFS = nameFS

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

            button:SetScript("OnMouseUp", function(self, btn)
                if btn ~= "LeftButton" then return end
                local d = self._elementData
                if not d then return end
                if d.isSegment then
                    -- Drill into this segment → show enemies
                    ns.ShowSegmentEnemies(d.sessionID, d.name)
                elseif d.isEnemy then
                    -- Open spell breakdown for this enemy
                    if ns.ShowTargetSpells then
                        ns.ShowTargetSpells(d.name, d.sourceCreatureID, selectedSessionID)
                    end
                end
            end)

            button._init = true
        end

        button._elementData = data

        local nudge = ns.GetFontNudge()
        button._rankFS:SetWidth(ns.ColWidth(RANK_CHARS))
        button._rankFS:SetText(data.rank .. ".")

        -- Bar color: amber for segments, red for enemies
        local r, g, b
        if data.isSegment then
            r, g, b = ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3]
        else
            r, g, b = 0.85, 0.25, 0.20
        end
        button._bar:SetStatusBarColor(r, g, b, 1)
        local fill = button._bar:GetStatusBarTexture()
        fill:SetGradient("HORIZONTAL",
            CreateColor(r * 0.7, g * 0.7, b * 0.7, 1),
            CreateColor(r * 0.25, g * 0.25, b * 0.25, 1))
        fill:SetAlpha(ns.BAR_ALPHA)

        button._bar:SetMinMaxValues(0, data.maxTotal or 1)
        button._bar:SetValue(data.total or 0)

        button._nameFS:SetText(data.name or "?")
        ns.Tint(button._nameFS, "primary")

        -- Duration string for segments, percentage for enemies
        if data.isSegment then
            button._pctFS:SetText(data.durationText or "")
            ns.Tint(button._pctFS, "secondary")
        else
            button._pctFS:SetText(string.format("%.1f%%", data.pct or 0))
            button._pctFS:SetTextColor(r, g, b)
        end

        button._totalFS:SetText(ns.FormatNumber(data.total or 0, "1dec"))
        ns.Tint(button._totalFS, "primary")

        if data.perSec and not issecretvalue(data.perSec) and data.perSec > 0 then
            button._perSecFS:SetText(ns.FormatNumber(data.perSec, "1dec"))
        else
            button._perSecFS:SetText(data.isSegment and "" or "-")
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

    ScrollUtil.InitScrollBoxListWithScrollBar(scroll, scrollBar, view)

    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", colHeaderSep, "BOTTOMLEFT", BORDER_SIZE, 0),
        CreateAnchor("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(ns.SCROLLBAR_WIDTH + BORDER_SIZE + 2), BORDER_SIZE),
    }
    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", colHeaderSep, "BOTTOMLEFT", BORDER_SIZE, 0),
        CreateAnchor("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -BORDER_SIZE, BORDER_SIZE),
    }
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(scroll, scrollBar,
        anchorsWithBar, anchorsWithoutBar)

    scroll:SetDataProvider(dataProvider)

    -- No data text
    local noDataFS = frame:CreateFontString(nil, "ARTWORK")
    noDataFS:SetFont(ns.GetFont(), 11, "OUTLINE")
    ns.Tint(noDataFS, "muted")
    noDataFS:SetPoint("CENTER", scroll, "CENTER", 0, 0)
    noDataFS:SetText(L["NO_DATA"])
    noDataFS:Hide()
    frame._noDataFS = noDataFS

    frame:Hide()
    breakdownFrame = frame
    return frame
end

----------------------------------------------------------------------
-- Level 1: Populate segment list
----------------------------------------------------------------------

local function PopulateSegments(frame)
    frame._dataProvider:Flush()
    viewMode = "segments"
    selectedSessionID = nil

    frame._titleFS:SetText(L["SEGMENTS"])
    frame._subtitleFS:SetText("")
    frame._backBtn:Hide()
    frame._colName:SetText(L["SEGMENT_COL_NAME"])

    if not C_DamageMeter.GetAvailableCombatSessions then
        frame._noDataFS:Show()
        return
    end

    local ok, sessions = pcall(C_DamageMeter.GetAvailableCombatSessions)
    if not ok or not sessions or #sessions == 0 then
        frame._noDataFS:Show()
        return
    end

    frame._noDataFS:Hide()

    -- Compute max total for bar scaling
    local maxTotal = 0
    for _, s in ipairs(sessions) do
        local t = s.totalAmount
        if t and not issecretvalue(t) and t > maxTotal then
            maxTotal = t
        end
    end

    local elements = {}
    for i, s in ipairs(sessions) do
        local sessionID = s.sessionID
        local total = s.totalAmount or 0
        local duration = s.durationSeconds or 0

        if issecretvalue(total) then total = 0 end
        if issecretvalue(duration) then duration = 0 end

        -- Try to get boss name from EnemyDamageTaken
        local label = GetSegmentLabel(sessionID)
            or (L["SEGMENT"] .. " " .. i)

        local durationText = ns.FormatTimer(duration)

        elements[#elements + 1] = {
            rank         = i,
            name         = label,
            total        = total,
            maxTotal     = maxTotal > 0 and maxTotal or 1,
            durationText = durationText,
            sessionID    = sessionID,
            isSegment    = true,
        }
    end

    frame._dataProvider:InsertTable(elements)
end

----------------------------------------------------------------------
-- Level 2: Populate enemies for a selected segment
----------------------------------------------------------------------

local function PopulateEnemies(frame, sessionID)
    frame._dataProvider:Flush()
    viewMode = "enemies"
    selectedSessionID = sessionID

    frame._titleFS:SetText(selectedSegmentName or L["SEGMENTS"])
    frame._subtitleFS:SetText("— " .. L["ENEMY_DAMAGE"])
    frame._backBtn:Show()
    frame._colName:SetText(L["TARGET_COL_NAME"])

    local ok, session = pcall(C_DamageMeter.GetCombatSessionFromID,
        sessionID, Enum.DamageMeterType.EnemyDamageTaken)
    if not ok or not session or issecretvalue(session) then
        frame._noDataFS:Show()
        return
    end

    local sources = session.combatSources
    if not sources or #sources == 0 then
        frame._noDataFS:Show()
        return
    end

    frame._noDataFS:Hide()

    local grandTotal = 0
    for _, source in ipairs(sources) do
        local t = source.totalAmount or 0
        if not issecretvalue(t) then grandTotal = grandTotal + t end
    end

    local maxTotal = 0
    if not issecretvalue(sources[1].totalAmount) then
        maxTotal = sources[1].totalAmount or 0
    end

    local elements = {}
    for i, source in ipairs(sources) do
        local name = source.name
        local total = source.totalAmount or 0
        local perSec = source.amountPerSecond
        local creatureID = source.sourceCreatureID

        if issecretvalue(name) then name = "?" end
        if issecretvalue(total) then total = 0 end
        if creatureID and issecretvalue(creatureID) then creatureID = nil end

        local pct = (grandTotal > 0 and total > 0)
            and (total / grandTotal * 100) or 0

        elements[#elements + 1] = {
            rank             = i,
            name             = name,
            total            = total,
            perSec           = perSec,
            pct              = pct,
            maxTotal         = maxTotal > 0 and maxTotal or 1,
            sourceCreatureID = creatureID,
            isEnemy          = true,
        }
    end

    frame._dataProvider:InsertTable(elements)
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

function ns.ShowTargetBreakdown(sessionType)
    local frame = EnsureWindow()
    frame:SetAlpha(ns.db and ns.db.breakdownAlpha or 0.85)

    -- Back button: return to segment list
    frame._backBtn:SetScript("OnClick", function()
        PopulateSegments(frame)
    end)

    PopulateSegments(frame)
    frame:Show()
end

function ns.ShowSegmentEnemies(sessionID, segmentName)
    local frame = EnsureWindow()
    selectedSegmentName = segmentName
    PopulateEnemies(frame, sessionID)
end

function ns.HideTargetBreakdown()
    if breakdownFrame then
        breakdownFrame:Hide()
        breakdownFrame._dataProvider:Flush()
    end
end

function ns.RefreshTargetBreakdown()
    if not breakdownFrame or not breakdownFrame:IsShown() then return end
    if viewMode == "segments" then
        PopulateSegments(breakdownFrame)
    elseif viewMode == "enemies" and selectedSessionID then
        PopulateEnemies(breakdownFrame, selectedSessionID)
    end
end

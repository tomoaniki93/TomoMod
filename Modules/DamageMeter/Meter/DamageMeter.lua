local ADDON_NAME, ns = ...
local L = ns.L

----------------------------------------------------------------------
-- Window Factory
----------------------------------------------------------------------

local windowCounter = 0

function ns.CreateMeterWindow(cfg)
    windowCounter = windowCounter + 1

    local state = {
        cfg = cfg,
        meterType = cfg.meterType,
        sessionType = cfg.sessionType,
        dataGeneration = 0,
        elements = {},
        expandedGUID = nil,   -- GUID of the player whose spells are shown inline
    }

    -- Forward declaration: defined further down but referenced by the
    -- ScrollBox element initializer (and the self bar) above its definition.
    -- Declaring it local keeps each window bound to its own closure instead
    -- of clobbering a shared global across windows.
    local UpdateButton

    ----------------------------------------------------------------------
    -- Main Frame
    ----------------------------------------------------------------------

    state.window = CreateFrame("Frame", "TomoDamageMeterFrame" .. windowCounter, UIParent)
    local window = state.window
    window:SetSize(cfg.width, cfg.height)
    window:SetPoint(cfg.point, UIParent, cfg.relPoint, cfg.x, cfg.y)
    window:SetMovable(true)
    window:SetResizable(true)
    window:SetResizeBounds(200, ns.HEADER_COMBINED + 4 * 18, 600, 500)
    window:SetClampedToScreen(true)
    window:SetFrameStrata("MEDIUM")
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")

    -- Clamp on first frame
    C_Timer.After(0, function()
        local left = window:GetLeft()
        local top = window:GetTop()
        local w = window:GetWidth()
        local h = window:GetHeight()
        if not left or not top then return end
        local screenW = GetScreenWidth()
        local screenH = GetScreenHeight()
        local clamped = false
        if left < 0 then left = 0; clamped = true end
        if left + w > screenW then left = screenW - w; clamped = true end
        if top > screenH then top = screenH; clamped = true end
        if top - h < 0 then top = h; clamped = true end
        if clamped then
            window:ClearAllPoints()
            window:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        end
    end)

    -- Drag handling
    window:SetScript("OnDragStart", function(self)
        if cfg.locked then return end
        -- Pull away = unhook. A head window is not docked to anything, so this
        -- does nothing for it and its followers stay anchored — which is what
        -- makes dragging the head move the whole chain.
        if ns.SnapDetachFrame then ns.SnapDetachFrame(self) end
        self:StartMoving()
    end)
    window:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if ns.SnapTryFrame and ns.SnapTryFrame(self) then
            -- Docked: position is now expressed as an anchor, not coordinates.
            return
        end
        -- Save
        local left = self:GetLeft()
        local top = self:GetTop()
        if left and top then
            cfg.point = "TOPLEFT"
            cfg.relPoint = "BOTTOMLEFT"
            cfg.x = left
            cfg.y = top
        end
        cfg.width = self:GetWidth()
        cfg.height = self:GetHeight()
    end)

    -- Propagate drag from children
    local function MakeDraggable(child)
        child:RegisterForDrag("LeftButton")
        child:SetScript("OnDragStart", function()
            window:GetScript("OnDragStart")(window)
        end)
        child:SetScript("OnDragStop", function()
            window:GetScript("OnDragStop")(window)
        end)
    end

    -- Background
    local windowBG = window:CreateTexture(nil, "BACKGROUND", nil, -1)
    windowBG:SetTexture(ns.FLAT)
    windowBG:SetVertexColor(ns.BG[1], ns.BG[2], ns.BG[3], ns.db and ns.db.bgAlpha or ns.BG[4])
    windowBG:SetAllPoints(window)

    ----------------------------------------------------------------------
    -- Borders (subtle 1px)
    ----------------------------------------------------------------------

    local borderColor = ns.BORDER_COLOR
    local function MakeBorder(anchor1, frame1, rel, anchor2, frame2, rel2, width, height)
        local t = window:CreateTexture(nil, "OVERLAY")
        t:SetTexture(ns.FLAT)
        t:SetVertexColor(unpack(borderColor))
        if width then t:SetWidth(width) end
        if height then t:SetHeight(height) end
        t:SetPoint(anchor1, frame1, rel)
        if anchor2 then t:SetPoint(anchor2, frame2, rel2) end
        return t
    end
    -- Top
    local topBorder = window:CreateTexture(nil, "OVERLAY")
    topBorder:SetTexture(ns.FLAT); topBorder:SetVertexColor(unpack(borderColor))
    topBorder:SetHeight(1); topBorder:SetPoint("TOPLEFT"); topBorder:SetPoint("TOPRIGHT")
    -- Bottom
    local bottomBorder = window:CreateTexture(nil, "OVERLAY")
    bottomBorder:SetTexture(ns.FLAT); bottomBorder:SetVertexColor(unpack(borderColor))
    bottomBorder:SetHeight(1); bottomBorder:SetPoint("BOTTOMLEFT"); bottomBorder:SetPoint("BOTTOMRIGHT")
    -- Left
    local leftBorder = window:CreateTexture(nil, "OVERLAY")
    leftBorder:SetTexture(ns.FLAT); leftBorder:SetVertexColor(unpack(borderColor))
    leftBorder:SetWidth(1); leftBorder:SetPoint("TOPLEFT"); leftBorder:SetPoint("BOTTOMLEFT")
    -- Right
    local rightBorder = window:CreateTexture(nil, "OVERLAY")
    rightBorder:SetTexture(ns.FLAT); rightBorder:SetVertexColor(unpack(borderColor))
    rightBorder:SetWidth(1); rightBorder:SetPoint("TOPRIGHT"); rightBorder:SetPoint("BOTTOMRIGHT")

    ----------------------------------------------------------------------
    -- Sub-Header (session strip)
    ----------------------------------------------------------------------

    local headerLevel = window:GetFrameLevel() + 1

    local function ShowTip(owner, text)
        GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM")
        GameTooltip:SetText(text, 1, 1, 1)
        GameTooltip:Show()
    end
    local function HideTip() GameTooltip:Hide() end

    local subHeader = CreateFrame("Button", nil, window)
    subHeader:SetFrameLevel(headerLevel)
    subHeader:SetPoint("TOPLEFT", window, "TOPLEFT", 0, -1)
    subHeader:SetPoint("TOPRIGHT", window, "TOPRIGHT", 0, -1)
    subHeader:SetHeight(ns.SUBHEADER_HEIGHT)
    MakeDraggable(subHeader)

    local subHeaderBG = window:CreateTexture(nil, "BACKGROUND")
    subHeaderBG:SetTexture(ns.FLAT); subHeaderBG:SetVertexColor(unpack(ns.HEADER_BG))
    subHeaderBG:SetPoint("TOPLEFT", subHeader); subHeaderBG:SetPoint("BOTTOMRIGHT", subHeader)

    local subHeaderHL = window:CreateTexture(nil, "BACKGROUND", nil, 1)
    subHeaderHL:SetTexture(ns.FLAT); subHeaderHL:SetVertexColor(unpack(ns.HEADER_HOVER_BG))
    subHeaderHL:SetPoint("TOPLEFT", subHeader); subHeaderHL:SetPoint("BOTTOMRIGHT", subHeader)
    subHeaderHL:Hide()

    -- Separator between subheader and breadcrumb header
    local headerSep = window:CreateTexture(nil, "OVERLAY")
    headerSep:SetTexture(ns.FLAT); headerSep:SetVertexColor(unpack(ns.BORDER_COLOR))
    headerSep:SetHeight(1)
    headerSep:SetPoint("TOPLEFT", subHeader, "BOTTOMLEFT")
    headerSep:SetPoint("TOPRIGHT", subHeader, "BOTTOMRIGHT")

    -- Combat timer (left/right of subheader, GUI-configurable)
    local timerFS = subHeader:CreateFontString(nil, "ARTWORK")
    timerFS:SetFont(ns.GetFont(), ns.BAR_FONT_SIZE, "OUTLINE")
    ns.Tint(timerFS, "secondary")

    local function ApplyTimerPosition()
        local pos = (ns.db and ns.db.combatTimerPos) or "RIGHT"
        timerFS:ClearAllPoints()
        if pos == "LEFT" then
            timerFS:SetJustifyH("LEFT")
            timerFS:SetPoint("LEFT", subHeader, "LEFT", ns.TEXT_PAD, ns.GetFontNudge())
        else
            timerFS:SetJustifyH("RIGHT")
            timerFS:SetPoint("RIGHT", subHeader, "RIGHT", -ns.TEXT_PAD, ns.GetFontNudge())
        end
    end
    ApplyTimerPosition()

    -- Session text (centered)
    local sessionText = subHeader:CreateFontString(nil, "ARTWORK")
    sessionText:SetFont(ns.GetFont(), ns.BAR_FONT_SIZE, "OUTLINE")
    ns.Tint(sessionText, "secondary")
    sessionText:SetPoint("CENTER", subHeader, "CENTER", 0, ns.GetFontNudge())
    sessionText:SetJustifyH("CENTER")
    sessionText:SetWordWrap(false)

    subHeader:SetScript("OnEnter", function()
        subHeaderHL:Show()
        sessionText:SetTextColor(1, 1, 1)
        timerFS:SetTextColor(1, 1, 1)
        ShowTip(subHeader, L["TIP_SESSION"])
    end)
    subHeader:SetScript("OnLeave", function()
        subHeaderHL:Hide()
        ns.Tint(sessionText, "secondary")
        if ns.inCombat then
            ns.Tint(timerFS, "accent")
        else
            ns.Tint(timerFS, "secondary")
        end
        HideTip()
    end)

    -- Session cycling on click
    subHeader:SetScript("OnClick", function()
        local currentIdx = 1
        for i, opt in ipairs(ns.SESSION_OPTIONS) do
            if opt.type == state.sessionType then currentIdx = i; break end
        end
        local nextIdx = (currentIdx % #ns.SESSION_OPTIONS) + 1
        state.sessionType = ns.SESSION_OPTIONS[nextIdx].type
        state.dataGeneration = state.dataGeneration + 1
        if ns.HideSpellBreakdown then ns.HideSpellBreakdown() end
        state.CollectData()
        state.UpdateHeader()
    end)

    ----------------------------------------------------------------------
    -- Breadcrumb Header
    ----------------------------------------------------------------------

    local header = CreateFrame("Frame", nil, window)
    header:SetFrameLevel(headerLevel)
    header:SetPoint("TOPLEFT", headerSep, "BOTTOMLEFT")
    header:SetPoint("TOPRIGHT", headerSep, "BOTTOMRIGHT")
    header:SetHeight(ns.HEADER_TOTAL)

    local headerBG = window:CreateTexture(nil, "BACKGROUND")
    headerBG:SetTexture(ns.FLAT); headerBG:SetVertexColor(unpack(ns.HEADER_BG))
    headerBG:SetPoint("TOPLEFT", header); headerBG:SetPoint("BOTTOMRIGHT", header)

    local headerSep2 = window:CreateTexture(nil, "OVERLAY")
    headerSep2:SetTexture(ns.FLAT); headerSep2:SetVertexColor(unpack(ns.BORDER_COLOR))
    headerSep2:SetHeight(0.8)
    headerSep2:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 1, 0)
    headerSep2:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", -1, 0)

    -- Category button
    local catBtn = CreateFrame("Button", nil, header)
    catBtn:SetFrameLevel(headerLevel)
    catBtn:SetPoint("TOPLEFT", header, "TOPLEFT")
    catBtn:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT")
    MakeDraggable(catBtn)

    local catText = catBtn:CreateFontString(nil, "ARTWORK")
    catText:SetFont(ns.GetFont(), 11, "OUTLINE")
    ns.Tint(catText, "secondary")
    catText:SetPoint("LEFT", ns.TEXT_PAD, ns.GetFontNudge())

    local catHL = catBtn:CreateTexture(nil, "BACKGROUND")
    catHL:SetTexture(ns.FLAT); catHL:SetVertexColor(unpack(ns.HEADER_HOVER_BG))
    catHL:SetAllPoints(); catHL:Hide()

    catBtn:SetScript("OnEnter", function() catHL:Show(); catText:SetTextColor(1, 1, 1); ShowTip(catBtn, L["TIP_CATEGORY"]) end)
    catBtn:SetScript("OnLeave", function() catHL:Hide(); ns.Tint(catText, "secondary"); HideTip() end)

    -- Chevron separator (texture)
    local sep = header:CreateTexture(nil, "ARTWORK")
    sep:SetTexture(ns.TEX_CHEVRON)
    sep:SetSize(6, 6)
    sep:SetVertexColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3], 0.5)

    -- Type button
    local typeBtn = CreateFrame("Button", nil, header)
    typeBtn:SetFrameLevel(headerLevel)
    typeBtn:SetPoint("TOP", header, "TOP")
    typeBtn:SetPoint("BOTTOM", header, "BOTTOM")
    MakeDraggable(typeBtn)

    local typeText = typeBtn:CreateFontString(nil, "ARTWORK")
    typeText:SetFont(ns.GetFont(), 11, "OUTLINE")
    typeText:SetTextColor(unpack(ns.ACCENT))
    typeText:SetPoint("LEFT", ns.TEXT_PAD, ns.GetFontNudge())

    local typeHL = typeBtn:CreateTexture(nil, "BACKGROUND")
    typeHL:SetTexture(ns.FLAT)
    typeHL:SetVertexColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3], 0.15)
    typeHL:SetAllPoints(); typeHL:Hide()

    typeBtn:SetScript("OnEnter", function() typeHL:Show(); ShowTip(typeBtn, L["TIP_TYPE"]) end)
    typeBtn:SetScript("OnLeave", function() typeHL:Hide(); HideTip() end)

    -- Header icon buttons factory (texture-based)
    local ICON_SIZE = 10
    local function MakeHeaderBtn(anchorTo, texPath)
        local btn = CreateFrame("Button", nil, header)
        btn:SetFrameLevel(headerLevel)
        btn:SetSize(ns.HEADER_HEIGHT, ns.HEADER_HEIGHT)
        if anchorTo then
            btn:SetPoint("TOPRIGHT", anchorTo, "TOPLEFT")
            btn:SetPoint("BOTTOMRIGHT", anchorTo, "BOTTOMLEFT")
        else
            btn:SetPoint("TOPRIGHT", header, "TOPRIGHT")
            btn:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT")
        end
        MakeDraggable(btn)

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetTexture(texPath)
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetPoint("CENTER", 0, 0)
        icon:SetVertexColor(unpack(ns.TEXT_MUTED))
        btn._icon = icon

        local hl = btn:CreateTexture(nil, "BACKGROUND")
        hl:SetTexture(ns.FLAT); hl:SetVertexColor(unpack(ns.HEADER_HOVER_BG))
        hl:SetAllPoints(); hl:Hide()
        btn._hl = hl

        btn:SetScript("OnEnter", function() hl:Show(); icon:SetVertexColor(1, 1, 1) end)
        btn:SetScript("OnLeave", function() hl:Hide(); icon:SetVertexColor(unpack(ns.TEXT_MUTED)) end)
        return btn
    end

    -- Reset button (rightmost)
    local resetBtn = MakeHeaderBtn(nil, ns.TEX_RESET)
    resetBtn:SetScript("OnClick", function()
        C_DamageMeter.ResetAllCombatSessions()
    end)
    resetBtn:HookScript("OnEnter", function(self) ShowTip(self, L["TIP_RESET"]) end)
    resetBtn:HookScript("OnLeave", HideTip)

    -- Report button
    local reportBtn = MakeHeaderBtn(resetBtn, ns.TEX_REPORT)
    reportBtn:SetScript("OnClick", function()
        local snap = ns.SnapshotReportData(state.meterType, state.sessionType, state.elements)
        if not snap then
            print(L["ADDON_PREFIX"] .. L["REPORT_NO_DATA"])
            return
        end
        local channel = ns.db.reportChannel or "AUTO"
        local lines = ns.db.reportLines or 5
        ns.SendReport(snap, channel, lines)
    end)
    reportBtn:HookScript("OnEnter", function(self) ShowTip(self, L["TIP_REPORT"]) end)
    reportBtn:HookScript("OnLeave", HideTip)

    -- Lock button
    local lockBtn = MakeHeaderBtn(reportBtn, ns.TEX_LOCK)
    local function UpdateLockIcon()
        if cfg.locked then
            lockBtn._icon:SetTexture(ns.TEX_LOCK)
            lockBtn._icon:SetVertexColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3])
        else
            lockBtn._icon:SetTexture(ns.TEX_LOCK_OPEN)
            lockBtn._icon:SetVertexColor(unpack(ns.TEXT_MUTED))
        end
    end
    UpdateLockIcon()
    lockBtn:SetScript("OnClick", function()
        cfg.locked = not cfg.locked
        UpdateLockIcon()
    end)
    lockBtn:SetScript("OnEnter", function() lockBtn._hl:Show(); lockBtn._icon:SetVertexColor(1, 1, 1); ShowTip(lockBtn, L["TIP_LOCK"]) end)
    lockBtn:SetScript("OnLeave", function() lockBtn._hl:Hide(); UpdateLockIcon(); HideTip() end)

    -- Details button (spell breakdown)
    local detailsBtn = MakeHeaderBtn(lockBtn, ns.TEX_DETAILS)
    detailsBtn:SetScript("OnClick", function()
        if ns.ShowSpellBreakdown then
            ns.ShowSpellBreakdown(nil, nil, state.meterType, state.sessionType, nil)
        end
    end)
    detailsBtn:HookScript("OnEnter", function(self) ShowTip(self, L["TIP_DETAILS"]) end)
    detailsBtn:HookScript("OnLeave", HideTip)

    -- Target button (enemy damage breakdown)
    local targetBtn = MakeHeaderBtn(detailsBtn, ns.TEX_TARGET)
    targetBtn:SetScript("OnClick", function()
        if ns.ShowTargetBreakdown then
            ns.ShowTargetBreakdown(state.sessionType)
        end
    end)
    targetBtn:HookScript("OnEnter", function(self) ShowTip(self, L["TIP_TARGET"]) end)
    targetBtn:HookScript("OnLeave", HideTip)

    -- Gear button (settings)
    local gearBtn = MakeHeaderBtn(targetBtn, ns.TEX_GEAR)
    gearBtn:SetScript("OnClick", function()
        if InCombatLockdown() then
            print(L["ADDON_PREFIX"] .. L["COMBAT_SETTINGS_UNAVAILABLE"])
            return
        end
        if ns.ToggleSettings then
            ns.ToggleSettings()
        end
    end)
    gearBtn:HookScript("OnEnter", function(self) ShowTip(self, L["TIP_SETTINGS"]) end)
    gearBtn:HookScript("OnLeave", HideTip)

    ----------------------------------------------------------------------
    -- Category / Type Menus (click handlers)
    ----------------------------------------------------------------------

    catBtn:SetScript("OnClick", function()
        -- Cycle through enabled categories
        local info = ns.TYPE_INFO[state.meterType]
        local currentCat = info and info.catIdx or 1
        local nextCat = ns.GetNextEnabledCatIdx(currentCat)
        if not nextCat or nextCat == currentCat then return end
        local newType = ns.METER_CATEGORIES[nextCat].types[1].type
        state.meterType = newType
        state.dataGeneration = state.dataGeneration + 1
        if ns.HideSpellBreakdown then ns.HideSpellBreakdown() end
        state.CollectData()
        state.UpdateHeader()
    end)

    typeBtn:SetScript("OnClick", function()
        -- Cycle through types within current category
        local info = ns.TYPE_INFO[state.meterType]
        if not info then return end
        local cat = ns.METER_CATEGORIES[info.catIdx]
        local currentIdx = 1
        for i, t in ipairs(cat.types) do
            if t.type == state.meterType then currentIdx = i; break end
        end
        local nextIdx = (currentIdx % #cat.types) + 1
        state.meterType = cat.types[nextIdx].type
        state.dataGeneration = state.dataGeneration + 1
        if ns.HideSpellBreakdown then ns.HideSpellBreakdown() end
        state.CollectData()
        state.UpdateHeader()
    end)

    ----------------------------------------------------------------------
    -- Vertical Action Strip (right edge)
    ----------------------------------------------------------------------

    local STRIP_W = ns.STRIP_WIDTH
    local actionStrip = CreateFrame("Frame", nil, window)
    actionStrip:SetFrameLevel(headerLevel + 1)
    actionStrip:SetWidth(STRIP_W)
    actionStrip:SetPoint("TOPRIGHT", headerSep2, "BOTTOMRIGHT")
    actionStrip:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT")

    local stripBG = actionStrip:CreateTexture(nil, "BACKGROUND")
    stripBG:SetTexture(ns.FLAT); ns.Surface(stripBG, 0.60)
    stripBG:SetAllPoints()

    local stripSep = actionStrip:CreateTexture(nil, "OVERLAY")
    stripSep:SetTexture(ns.FLAT); stripSep:SetVertexColor(unpack(ns.BORDER_COLOR))
    stripSep:SetWidth(1)
    stripSep:SetPoint("TOPLEFT", actionStrip, "TOPLEFT")
    stripSep:SetPoint("BOTTOMLEFT", actionStrip, "BOTTOMLEFT")

    ----------------------------------------------------------------------
    -- Resize Handle (bottom-right corner)
    ----------------------------------------------------------------------

    local resizeHandle = CreateFrame("Button", nil, window)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT")
    resizeHandle:SetFrameLevel(window:GetFrameLevel() + 10)

    -- Subtle grip texture
    local gripTex = resizeHandle:CreateTexture(nil, "OVERLAY")
    gripTex:SetTexture(ns.FLAT)
    gripTex:SetVertexColor(0.4, 0.4, 0.43, 0.5)
    gripTex:SetSize(6, 6)
    gripTex:SetPoint("BOTTOMRIGHT", -3, 3)

    resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not cfg.locked then
            window:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeHandle:SetScript("OnMouseUp", function()
        window:StopMovingOrSizing()
        cfg.width = window:GetWidth()
        cfg.height = window:GetHeight()
        -- Followers inherit the new width through their anchors, but their
        -- columns are laid out against it and need re-measuring.
        if ns.SnapRefreshChain then ns.SnapRefreshChain(window) end
    end)
    resizeHandle:SetScript("OnEnter", function()
        gripTex:SetVertexColor(0.7, 0.7, 0.73, 0.8)
    end)
    resizeHandle:SetScript("OnLeave", function()
        gripTex:SetVertexColor(0.4, 0.4, 0.43, 0.5)
    end)

    ----------------------------------------------------------------------
    -- ScrollBox + Bar Entries
    ----------------------------------------------------------------------

    local scrollBox = CreateFrame("Frame", nil, window, "WowScrollBoxList")

    -- Bottom-right boundary helper. Sits at the action strip's left edge.
    -- Its vertical offset is raised by the self-bar height when that bar is
    -- shown, so the scroll list (anchored to it) shrinks to make room.
    local scrollBR = CreateFrame("Frame", nil, window)
    scrollBR:SetSize(1, 1)
    scrollBR:SetPoint("BOTTOMRIGHT", actionStrip, "BOTTOMLEFT", 0, 0)

    local scrollBar = CreateFrame("EventFrame", nil, window, "MinimalScrollBar")
    scrollBar:SetPoint("TOPRIGHT", actionStrip, "TOPLEFT", -1, 0)
    scrollBar:SetPoint("BOTTOMRIGHT", scrollBR, "BOTTOMRIGHT", -1, -1)
    scrollBar:SetWidth(ns.SCROLLBAR_WIDTH)

    -- Style the scrollbar
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
    view:SetElementExtent(ns.GetBarHeight())

    -- Inline spell sub-rows are a touch shorter than a player row so the
    -- hierarchy reads at a glance. The extent calculator switches the view
    -- to per-element heights (player rows keep GetBarHeight()); the fixed
    -- extent above stays as a harmless fallback.
    local function SpellRowHeight()
        return math.max(14, ns.GetBarHeight() - 3)
    end
    view:SetElementExtentCalculator(function(_, elementData)
        if elementData and elementData.kind == "spell" then
            return SpellRowHeight()
        end
        return ns.GetBarHeight()
    end)

    view:SetPadding(0, 0, 0, 0, 0)

    local dataProvider = CreateDataProvider()

    ----------------------------------------------------------------------
    -- Bar Visuals Builder
    -- Shared by ScrollBox row buttons AND the pinned self bar so both
    -- have identical visuals, hover behaviour and click handling.
    ----------------------------------------------------------------------

    local function BuildBarVisuals(button)
        button:SetHeight(ns.GetBarHeight())
        button:EnableMouse(true)
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        -- Accent stripe on the left edge: marks the expanded player row and
        -- brackets its inline spell sub-rows into a visual group. Hidden by
        -- default; toggled per-row in UpdateButton / UpdateSpellRow.
        local groupAccent = button:CreateTexture(nil, "OVERLAY")
        groupAccent:SetTexture(ns.FLAT)
        groupAccent:SetVertexColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3], 0.9)
        groupAccent:SetWidth(2)
        groupAccent:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        groupAccent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, ns.BAR_SPACING)
        groupAccent:Hide()
        button.groupAccent = groupAccent

        -- Spec icon
        local iconFrame = button:CreateTexture(nil, "ARTWORK")
        iconFrame:SetPoint("TOPLEFT", 0, 0)
        iconFrame:SetPoint("BOTTOMLEFT", 0, ns.BAR_SPACING)
        iconFrame:SetWidth(ns.GetBarHeight() - ns.BAR_SPACING)
        iconFrame:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon = iconFrame

        -- Status bar
        local bar = CreateFrame("StatusBar", nil, button)
        bar:SetStatusBarTexture(ns.GetBarTexture())
        button.bar = bar

        -- Name
        local nameFS = bar:CreateFontString(nil, "OVERLAY")
        -- ns.GetFontSize(), not the ns.BAR_FONT_SIZE constant: the constant is
        -- only the factory default, and a row born from it while the user runs
        -- a different size never matched the rows RefreshFonts had already
        -- corrected.
        nameFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
        nameFS:SetJustifyH("LEFT")
        nameFS:SetWordWrap(false)
        nameFS:SetShadowOffset(1, -1)
        nameFS:SetShadowColor(0, 0, 0, 0.4)
        button.nameFS = nameFS

        -- Value columns
        local function MakeValueFS(parent)
            local fs = parent:CreateFontString(nil, "OVERLAY")
            fs:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            fs:SetJustifyH("RIGHT")
            fs:SetShadowOffset(1, -1)
            fs:SetShadowColor(0, 0, 0, 0.4)
            return fs
        end
        button.rateFS = MakeValueFS(bar)
        button.totalFS = MakeValueFS(bar)
        button.pctFS = MakeValueFS(bar)

        -- Hover highlight
        local hl = button:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture(ns.FLAT)
        hl:SetVertexColor(1, 1, 1, 0.08)
        hl:SetAllPoints()

        button.fill = bar:GetStatusBarTexture()
        button:HookScript("OnEnter", function(self)
            if self.fill then self.fill:SetAlpha(1) end
            if self.icon then self.icon:SetAlpha(1) end
        end)
        button:HookScript("OnLeave", function(self)
            if self.fill then self.fill:SetAlpha(ns.BAR_ALPHA) end
            if self.icon then self.icon:SetAlpha(ns.ICON_ALPHA) end
        end)

        -- Informative hover tooltip: headline stat + a top-spell sublist for
        -- this player. Reads state.meterType/sessionType at hover time so it
        -- always reflects the window's current view.
        button:HookScript("OnEnter", function(self)
            if not (ns.db and ns.db.showBarTooltips) then return end
            local ed = self._elementData
            if not ed then return end
            if ed.kind == "spell" then
                if not ed.isEmpty and ns.BuildSpellTooltip then
                    ns.BuildSpellTooltip(self, ed)
                end
            elseif ns.BuildBarTooltip then
                ns.BuildBarTooltip(self, ed, state.meterType, state.sessionType)
            end
        end)
        button:HookScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        MakeDraggable(button)

        -- Click handling:
        --   Left  -> toggle the inline spell breakdown under this player row
        --   Right -> open the standalone breakdown window (searchable player
        --            strip, handy for full raids)
        button:SetScript("OnClick", function(self, btn)
            local ed = self._elementData
            if not ed or ed.kind == "spell" then return end

            -- Deaths category: open the death recap for this player (either
            -- mouse button). Uses deathRecapID, not the GUID, so it still works
            -- if the source GUID happens to be a secret value.
            if state.meterType == Enum.DamageMeterType.Deaths then
                local rid = ed.deathRecapID
                if rid and not issecretvalue(rid) and rid > 0 and ns.ShowDeathRecap then
                    local pname = (not issecretvalue(ed.name) and ns.db.stripRealm)
                        and ns.StripRealm(ed.name) or (not issecretvalue(ed.name) and ed.name or "?")
                    ns.ShowDeathRecap(rid, pname, ed.classFilename)
                end
                return
            end

            if not (ed.sourceGUID and not issecretvalue(ed.sourceGUID)) then return end

            if btn == "RightButton" then
                local playerName = (not issecretvalue(ed.name) and ns.db.stripRealm)
                    and ns.StripRealm(ed.name) or (not issecretvalue(ed.name) and ed.name or "?")
                if ns.ShowSpellBreakdown then
                    ns.ShowSpellBreakdown(playerName, ed.sourceGUID, state.meterType, state.sessionType, ed.classFilename)
                end
            else
                if state.expandedGUID == ed.sourceGUID then
                    state.expandedGUID = nil
                else
                    state.expandedGUID = ed.sourceGUID
                end
                state.CollectData()
            end
        end)
    end

    ----------------------------------------------------------------------
    -- Element Initializer (bar entries)
    ----------------------------------------------------------------------

    view:SetElementInitializer("Button", function(button, elementData)
        if not button.bar then
            BuildBarVisuals(button)
        end

        -- Store elementData reference for click handler
        button._elementData = elementData

        -- Update with data
        UpdateButton(button, elementData)
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    -- Managed scrollbar anchors
    local scrollBoxAnchorsWithBar = {
        CreateAnchor("TOPLEFT", headerSep2, "BOTTOMLEFT", 0, 0),
        CreateAnchor("BOTTOMRIGHT", scrollBR, "BOTTOMRIGHT", -(ns.SCROLLBAR_WIDTH + 2), 0),
    }
    local scrollBoxAnchorsWithoutBar = {
        CreateAnchor("TOPLEFT", headerSep2, "BOTTOMLEFT", 0, 0),
        CreateAnchor("BOTTOMRIGHT", scrollBR, "BOTTOMRIGHT", 0, 0),
    }
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, scrollBar,
        scrollBoxAnchorsWithBar, scrollBoxAnchorsWithoutBar)

    scrollBox:SetDataProvider(dataProvider)

    ----------------------------------------------------------------------
    -- Pinned Self Bar (always-visible local-player row)
    ----------------------------------------------------------------------

    local selfBar = CreateFrame("Button", nil, window)
    selfBar:SetFrameLevel(headerLevel + 2)
    selfBar:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", ns.BORDER_WIDTH, ns.BORDER_WIDTH)
    selfBar:SetPoint("BOTTOMRIGHT", actionStrip, "BOTTOMLEFT", 0, ns.BORDER_WIDTH)
    selfBar:SetHeight(ns.GetBarHeight())
    BuildBarVisuals(selfBar)
    selfBar:Hide()

    -- Accent separator drawn just above the self bar
    local selfSep = window:CreateTexture(nil, "OVERLAY")
    selfSep:SetTexture(ns.FLAT)
    selfSep:SetVertexColor(ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3], 0.5)
    selfSep:SetHeight(1)
    selfSep:SetPoint("BOTTOMLEFT", selfBar, "TOPLEFT", 0, 0)
    selfSep:SetPoint("BOTTOMRIGHT", selfBar, "TOPRIGHT", 0, 0)
    selfSep:Hide()

    -- Reserve (or release) vertical space for the self bar by moving the
    -- scroll list's bottom boundary frame.
    local function SetSelfBarShown(shown)
        scrollBR:ClearAllPoints()
        if shown then
            local bh = ns.GetBarHeight()
            selfBar:SetHeight(bh)
            selfBar.icon:SetWidth(bh - ns.BAR_SPACING)
            scrollBR:SetPoint("BOTTOMRIGHT", actionStrip, "BOTTOMLEFT", 0, bh + 1)
            selfBar:Show()
            selfSep:Show()
        else
            scrollBR:SetPoint("BOTTOMRIGHT", actionStrip, "BOTTOMLEFT", 0, 0)
            selfBar:Hide()
            selfSep:Hide()
        end
    end

    ----------------------------------------------------------------------
    -- UpdateSpellRow (inline spell sub-row rendering)
    ----------------------------------------------------------------------
    -- Renders one indented spell bar beneath its expanded player. Reuses the
    -- same widgets a player row uses (icon / bar / name / value columns) so
    -- the columns line up vertically; only the anchoring, colours and the
    -- indent differ. Element data comes from ns.AppendSpellRows, i.e. already
    -- fully-resolved plain numbers (no secret-value handling needed here).
    local SPELL_INDENT = 14

    local function UpdateSpellRow(button, data)
        local rowH = SpellRowHeight()

        -- Live skin swap (mirrors the player-row path)
        local barTex = ns.GetBarTexture()
        if button._tex ~= barTex then
            button.bar:SetStatusBarTexture(barTex)
            button._tex = barTex
            button.fill = button.bar:GetStatusBarTexture()
        end

        if button.groupAccent then button.groupAccent:Show() end

        -- Empty placeholder ("no data" under an expanded player)
        if data.isEmpty then
            button.icon:Hide()
            if button.actionFS then button.actionFS:Hide() end
            button.rateFS:SetText(""); button.rateFS:Hide()
            button.totalFS:SetText(""); button.totalFS:Hide()
            button.pctFS:SetText(""); button.pctFS:Hide()
            button.bar:ClearAllPoints()
            button.bar:SetPoint("TOPLEFT", SPELL_INDENT, 0)
            button.bar:SetPoint("BOTTOMRIGHT", 0, ns.BAR_SPACING)
            button.bar:SetMinMaxValues(0, 1)
            button.bar:SetValue(0)
            button.bar:SetStatusBarColor(0.3, 0.3, 0.33, 1)
            local efill = button.bar:GetStatusBarTexture()
            efill:SetAlpha(0)
            button.nameFS:ClearAllPoints()
            button.nameFS:SetPoint("LEFT", button.bar, "LEFT", 6, ns.GetFontNudge())
            button.nameFS:SetPoint("RIGHT", button.bar, "RIGHT", -6, 0)
            button.nameFS:SetText(data.name or "")
            ns.Tint(button.nameFS, "muted")
            return
        end

        -- Class-tinted, dimmer-than-player bar so sub-rows recede visually
        local cc = data.classFilename and RAID_CLASS_COLORS[data.classFilename]
        -- Fill goes through ns.ClassColor so a light skin can darken it; the
        -- name keeps the untouched class colour, since its black outline
        -- already carries it against any background.
        local r, g, b = ns.ClassColor(data.classFilename)
        button.bar:SetStatusBarColor(r, g, b, 1.0)
        local fill = button.bar:GetStatusBarTexture()
        fill:SetGradient("HORIZONTAL",
            CreateColor(r * 0.45, g * 0.45, b * 0.45, 1),
            CreateColor(r * 0.15, g * 0.15, b * 0.15, 1))
        fill:SetAlpha(ns.BAR_ALPHA)

        -- Indented spell icon
        local iconSize = math.max(8, rowH - ns.BAR_SPACING - 2)
        button.icon:SetTexture(data.icon or 134400)
        button.icon:ClearAllPoints()
        button.icon:SetPoint("LEFT", button, "LEFT", SPELL_INDENT, 0)
        button.icon:SetSize(iconSize, iconSize)
        button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon:SetAlpha(1)
        button.icon:Show()

        -- Bar fills the remaining width after the indented icon
        button.bar:ClearAllPoints()
        button.bar:SetPoint("TOPLEFT", button.icon, "TOPRIGHT", ns.BAR_SPACING + 1, 0)
        button.bar:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, ns.BAR_SPACING)
        button.bar:SetMinMaxValues(0, data.maxAmount or 1)
        button.bar:SetValue(data.totalAmount or 0)

        -- Fonts are re-applied here rather than trusted from creation time.
        -- The ScrollBox pool grows during a fight and reassigns which frame
        -- renders which row on every Flush/InsertTable, so a row could be drawn
        -- one pass by a frame born at the default size and the next by one
        -- RefreshFonts had already corrected — which read as the text pulsing
        -- larger and smaller several times a second. Guarded, so SetFont only
        -- fires when the row is actually out of date.
        local wantFont, wantSize = ns.GetFont(), ns.GetFontSize()
        if button._fontPath ~= wantFont or button._fontSize ~= wantSize then
            button.nameFS:SetFont(wantFont, wantSize, "OUTLINE")
            button.rateFS:SetFont(wantFont, wantSize, "OUTLINE")
            button.totalFS:SetFont(wantFont, wantSize, "OUTLINE")
            button.pctFS:SetFont(wantFont, wantSize, "OUTLINE")
            button._fontPath, button._fontSize = wantFont, wantSize
        end

        -- Spell name (rank prefix + optional pet attribution already folded in)
        button.nameFS:SetText(data.displayName or data.name or "?")
        ns.Tint(button.nameFS, "primary")

        -- Same column pipeline as player rows: rate / total / pct all line up.
        -- sessionTotal is set to the player's own total upstream, so the pct
        -- column reads as the spell's share of that player.
        ns.PopulateColumnValues(button, data)
        local prevFS = ns.AnchorColumns(button)

        button.nameFS:ClearAllPoints()
        button.nameFS:SetPoint("LEFT", button.bar, "LEFT", 6, ns.GetFontNudge())
        if prevFS then
            button.nameFS:SetPoint("RIGHT", prevFS, "LEFT", -4, 0)
        else
            button.nameFS:SetPoint("RIGHT", button.bar, "RIGHT", -6, 0)
        end
    end

    ----------------------------------------------------------------------
    -- UpdateButton
    ----------------------------------------------------------------------

    function UpdateButton(button, elementData)
        -- Inline spell sub-row: separate rendering path, then done.
        if elementData.kind == "spell" then
            UpdateSpellRow(button, elementData)
            return
        end

        -- Player row: hide the group stripe unless this is the expanded player.
        if button.groupAccent then
            local isExpanded = false
            local g = elementData.sourceGUID
            if g and not issecretvalue(g) and state.expandedGUID and g == state.expandedGUID then
                isExpanded = true
            end
            button.groupAccent:SetShown(isExpanded)
        end

        -- Class color
        local color = RAID_CLASS_COLORS[elementData.classFilename]
        local r, g, b = ns.ClassColor(elementData.classFilename)
        button.bar:SetStatusBarColor(r, g, b, 1.0)

        -- Live skin: swap the fill texture when the active skin/texture changed
        local barTex = ns.GetBarTexture()
        if button._tex ~= barTex then
            button.bar:SetStatusBarTexture(barTex)
            button._tex = barTex
            button.fill = button.bar:GetStatusBarTexture()
        end

        local fill = button.bar:GetStatusBarTexture()
        fill:SetGradient("HORIZONTAL",
            CreateColor(r * 0.7, g * 0.7, b * 0.7, 1),
            CreateColor(r * 0.3, g * 0.3, b * 0.3, 1))
        fill:SetAlpha(ns.BAR_ALPHA)
        button.icon:SetAlpha(ns.ICON_ALPHA)

        if button:IsMouseOver() then
            fill:SetAlpha(1)
            button.icon:SetAlpha(1)
        end

        -- Bar fill values
        local maxVal = elementData.maxAmount
        if not maxVal or (not issecretvalue(maxVal) and maxVal <= 0) then
            maxVal = 1
        end
        button.bar:SetMinMaxValues(0, maxVal)
        button.bar:SetValue(elementData.totalAmount or 0)

        -- Fonts are re-applied here rather than trusted from creation time.
        -- The ScrollBox pool grows during a fight and reassigns which frame
        -- renders which row on every Flush/InsertTable, so a row could be drawn
        -- one pass by a frame born at the default size and the next by one
        -- RefreshFonts had already corrected — which read as the text pulsing
        -- larger and smaller several times a second. Guarded, so SetFont only
        -- fires when the row is actually out of date.
        local wantFont, wantSize = ns.GetFont(), ns.GetFontSize()
        if button._fontPath ~= wantFont or button._fontSize ~= wantSize then
            button.nameFS:SetFont(wantFont, wantSize, "OUTLINE")
            button.rateFS:SetFont(wantFont, wantSize, "OUTLINE")
            button.totalFS:SetFont(wantFont, wantSize, "OUTLINE")
            button.pctFS:SetFont(wantFont, wantSize, "OUTLINE")
            button._fontPath, button._fontSize = wantFont, wantSize
        end

        -- Name
        button.nameFS:SetText(ns.db.stripRealm and ns.StripRealm(elementData.name) or elementData.name or "")

        -- Column values
        ns.PopulateColumnValues(button, elementData)

        -- Text colors
        ns.Tint(button.nameFS, "primary")
        ns.Tint(button.rateFS, "primary")
        ns.Tint(button.totalFS, "primary")
        ns.Tint(button.pctFS, "primary")

        -- Icon + bar anchoring
        button.bar:ClearAllPoints()
        button.nameFS:ClearAllPoints()
        if elementData.specIconID and not issecretvalue(elementData.specIconID)
            and elementData.specIconID > 0 then
            button.icon:SetTexture(elementData.specIconID)
            button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            -- Restore spec-icon geometry: a pooled frame may have just served
            -- as an inline spell sub-row, which re-anchors and resizes the icon.
            button.icon:ClearAllPoints()
            button.icon:SetPoint("TOPLEFT", 0, 0)
            button.icon:SetPoint("BOTTOMLEFT", 0, ns.BAR_SPACING)
            button.icon:SetWidth(ns.GetBarHeight() - ns.BAR_SPACING)
            button.icon:Show()
            local iconSpace = ns.GetBarHeight() - ns.BAR_SPACING
            button.bar:SetPoint("TOPLEFT", iconSpace, 0)
            button.bar:SetPoint("BOTTOMRIGHT", 0, ns.BAR_SPACING)
            button.nameFS:SetPoint("LEFT", button.bar, "LEFT", 4, ns.GetFontNudge())
        else
            button.icon:Hide()
            button.bar:SetPoint("TOPLEFT", 0, 0)
            button.bar:SetPoint("BOTTOMRIGHT", 0, ns.BAR_SPACING)
            button.nameFS:SetPoint("LEFT", button.bar, "LEFT", 6, ns.GetFontNudge())
        end

        local prevFS = ns.AnchorColumns(button)
        if prevFS then
            button.nameFS:SetPoint("RIGHT", prevFS, "LEFT", -4, 0)
        else
            button.nameFS:SetPoint("RIGHT", button.bar, "RIGHT", -6, 0)
        end

        -- Bar grow animation on generation change
        if button._dataGen ~= state.dataGeneration then
            button._dataGen = state.dataGeneration
            local aFill = button.bar:GetStatusBarTexture()
            if not aFill._growAnim then
                local ag = aFill:CreateAnimationGroup()
                local scale = ag:CreateAnimation("Scale")
                scale:SetScaleFrom(0, 1)
                scale:SetScaleTo(1, 1)
                scale:SetOrigin("LEFT", 0, 0)
                scale:SetDuration(0.2)
                scale:SetSmoothing("OUT")
                aFill._growAnim = ag
            end
            aFill._growAnim:Stop()
            aFill._growAnim:Play()
        end
    end

    ----------------------------------------------------------------------
    -- Data Collection
    ----------------------------------------------------------------------

    function state.CollectData()
        local session = C_DamageMeter.GetCombatSessionFromType(state.sessionType, state.meterType)
        dataProvider:Flush()

        -- Default: no self bar this pass; re-enabled below if data + setting allow.
        SetSelfBarShown(false)

        if not session or issecretvalue(session) then return end
        local sources = session.combatSources
        if not sources or #sources == 0 then return end

        -- Session total for percentage
        local sessionTotal = 0
        if not issecretvalue(sources[1].totalAmount) then
            for _, s in ipairs(sources) do
                if not issecretvalue(s.totalAmount) then
                    sessionTotal = sessionTotal + s.totalAmount
                end
            end
        end

        -- Max value for bar scaling
        local maxAmount = sources[1].totalAmount

        local isAction = ns.ACTIONS_TYPES[state.meterType] or false
        local maxEntries = isAction and 5 or #sources
        local elements = {}
        local expandFound = false
        for i, source in ipairs(sources) do
            if i > maxEntries then break end
            local guid = source.sourceGUID
            elements[#elements + 1] = {
                name = source.name,
                classFilename = source.classFilename,
                specIconID = source.specIconID,
                totalAmount = source.totalAmount,
                amountPerSecond = source.amountPerSecond,
                maxAmount = maxAmount,
                sessionTotal = sessionTotal,
                sourceGUID = guid,
                isLocalPlayer = source.isLocalPlayer,
                isActionType = isAction,
                deathRecapID = source.deathRecapID,
            }

            -- Inline spell breakdown: splice this player's spells in right
            -- after their row. Refetched every pass, so it updates live.
            if state.expandedGUID and guid and not issecretvalue(guid)
                and guid == state.expandedGUID then
                expandFound = true
                ns.AppendSpellRows(elements, state.sessionType, state.meterType,
                    guid, source.totalAmount, source.classFilename)
            end
        end

        -- Expanded player left the list (e.g. left group): collapse silently.
        if state.expandedGUID and not expandFound then
            state.expandedGUID = nil
        end

        -- Kept for consumers that run outside an event handler (the chat
        -- report is a click handler, where a live query returns secrets).
        state.elements = elements

        dataProvider:InsertTable(elements)

        -- Pinned self bar: locate the local player anywhere in the full list
        -- (not just the visible top N) and mirror their row at the bottom.
        if ns.db and ns.db.showSelfBar then
            local selfSource
            for _, source in ipairs(sources) do
                local isSelf = source.isLocalPlayer
                if isSelf ~= nil and not issecretvalue(isSelf) and isSelf then
                    selfSource = source
                    break
                end
            end
            if selfSource then
                selfBar._elementData = {
                    name = selfSource.name,
                    classFilename = selfSource.classFilename,
                    specIconID = selfSource.specIconID,
                    totalAmount = selfSource.totalAmount,
                    amountPerSecond = selfSource.amountPerSecond,
                    maxAmount = maxAmount,
                    sessionTotal = sessionTotal,
                    sourceGUID = selfSource.sourceGUID,
                    isLocalPlayer = true,
                    isActionType = isAction,
                    -- Deaths category: without this, clicking the pinned self
                    -- bar did nothing while the same row in the list opened
                    -- the death recap.
                    deathRecapID = selfSource.deathRecapID,
                }
                SetSelfBarShown(true)
                UpdateButton(selfBar, selfBar._elementData)
            end
        end
    end

    -- Data pass. Deliberately synchronous.
    --
    -- This used to hop through C_Timer.After(0). That single deferral pushed
    -- every C_DamageMeter read out of the DAMAGE_METER_* event handler, which is
    -- the only context where the API returns readable values: from a timer
    -- callback the same fields come back as secret values. That is what forced
    -- percentages to render as "-", the chat report to bail out, and any
    -- Lua-side aggregation (sorting, cross-pull comparison) to be impossible
    -- mid-combat. Throttling now lives in Core/Database.lua, where it can drop
    -- events instead of deferring them.
    function state.ScheduleRefresh()
        state.CollectData()
    end

    ----------------------------------------------------------------------
    -- Header Update
    ----------------------------------------------------------------------

    function state.UpdateHeader()
        local info = ns.TYPE_INFO[state.meterType]
        if not info then return end

        local catName = L[info.catName] or info.catName
        local typeName = L[info.key] or info.key
        local sessKey = ns.SESSION_KEYS[state.sessionType]
        local sessionName = sessKey and L[sessKey] or L["CURRENT"]

        catText:SetText(catName)
        typeText:SetText(typeName)
        sessionText:SetText(sessionName)

        -- Size category button to fit text
        local catWidth = catText:GetStringWidth() + ns.TEXT_PAD * 2
        catBtn:SetWidth(catWidth)

        -- Position chevron after category
        sep:ClearAllPoints()
        sep:SetPoint("LEFT", catBtn, "RIGHT", 2, ns.GetFontNudge())

        -- Position type button after chevron
        typeBtn:ClearAllPoints()
        typeBtn:SetPoint("TOPLEFT", sep, "TOPRIGHT", 2, 0)
        typeBtn:SetPoint("BOTTOM", header, "BOTTOM")
        local typeWidth = typeText:GetStringWidth() + ns.TEXT_PAD * 2
        typeBtn:SetWidth(typeWidth)

        -- Keep the combat timer in sync with the current meter type.
        state.UpdateTimer()
    end

    ----------------------------------------------------------------------
    -- Timer Update
    ----------------------------------------------------------------------

    function state.UpdateTimer()
        -- Combat timer is shown only on rate-based meters (DPS / HPS) and only
        -- when enabled. Other meter types clear it.
        if not (ns.db and ns.db.showCombatTimer) or not ns.RATE_PRIMARY[state.meterType] then
            timerFS:SetText("")
            return
        end

        local seconds
        local session = C_DamageMeter.GetCombatSessionFromType(state.sessionType, state.meterType)
        if session and not issecretvalue(session) then
            -- API field is `durationSeconds` (matching TargetBreakdown), not `duration`.
            local d = session.durationSeconds
            if d ~= nil and not issecretvalue(d) then
                seconds = d
            end
        end

        -- Fallback: dedicated duration API queried by session type.
        if seconds == nil and C_DamageMeter.GetSessionDurationSeconds then
            local ok, d = pcall(C_DamageMeter.GetSessionDurationSeconds, state.sessionType)
            if ok and d ~= nil and not issecretvalue(d) then
                seconds = d
            end
        end

        if seconds == nil or issecretvalue(seconds) then
            timerFS:SetText("")
            return
        end

        timerFS:SetText(ns.FormatTimer(seconds))
        if ns.inCombat then
            ns.Tint(timerFS, "accent")
        else
            ns.Tint(timerFS, "secondary")
        end
    end

    ----------------------------------------------------------------------
    -- Return window interface
    ----------------------------------------------------------------------

    local win = {
        frame = window,
        cfg = cfg,
        BumpGeneration = function() state.dataGeneration = state.dataGeneration + 1 end,
        Refresh = state.ScheduleRefresh,
        UpdateTimer = function() state.UpdateTimer() end,
        UpdateHeader = function() state.UpdateHeader() end,
        SetMeterType = function(meterType)
            state.meterType = meterType
            cfg.meterType = meterType
            state.dataGeneration = state.dataGeneration + 1
            if ns.HideSpellBreakdown then ns.HideSpellBreakdown() end
            state.CollectData()
            state.UpdateHeader()
        end,
        SetSessionType = function(sessionType)
            state.sessionType = sessionType
            cfg.sessionType = sessionType
            state.dataGeneration = state.dataGeneration + 1
            if ns.HideSpellBreakdown then ns.HideSpellBreakdown() end
            state.CollectData()
            state.UpdateHeader()
        end,
        GetMeterType = function() return state.meterType end,
        GetSessionType = function() return state.sessionType end,
        -- Re-sync the header lock icon after cfg.locked was changed externally
        -- (slash command, settings checkbox).
        RefreshLockIcon = UpdateLockIcon,
        SetCombatAlpha = function(inCombat)
            local oocAlpha = ns.db and ns.db.oocAlpha or 1
            if inCombat then
                window:SetAlpha(1)
            else
                window:SetAlpha(oocAlpha)
            end
        end,
        SetResizeHandleShown = function(shown)
            -- A docked window has one axis owned by the window it is docked
            -- to, so the grip is hidden rather than left to fight the anchors.
            resizeHandle:SetShown(shown and true or false)
        end,
        SavePosition = function()
            -- Docked windows keep their anchor in cfg.snap; overwriting the
            -- absolute coordinates here would fight the restore pass.
            if cfg.snap then
                cfg.meterType = state.meterType
                cfg.sessionType = state.sessionType
                return
            end
            local left = window:GetLeft()
            local top = window:GetTop()
            if left and top then
                cfg.point = "TOPLEFT"
                cfg.relPoint = "BOTTOMLEFT"
                cfg.x = left
                cfg.y = top
            end
            cfg.width = window:GetWidth()
            cfg.height = window:GetHeight()
            cfg.meterType = state.meterType
            cfg.sessionType = state.sessionType
        end,
        SetBGAlpha = function(alpha)
            windowBG:SetVertexColor(ns.BG[1], ns.BG[2], ns.BG[3], alpha)
        end,
        RefreshAccentColor = function()
            local a1, a2, a3 = ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3]
            sep:SetVertexColor(a1, a2, a3, 0.5)
            typeText:SetTextColor(a1, a2, a3, ns.ACCENT[4])
            typeHL:SetVertexColor(a1, a2, a3, 0.15)
            UpdateLockIcon()
        end,
        RefreshSkin = function()
            -- Re-tint all skin-driven chrome from the live Style tables
            windowBG:SetVertexColor(ns.BG[1], ns.BG[2], ns.BG[3], ns.db and ns.db.bgAlpha or ns.BG[4])
            local bc = ns.BORDER_COLOR
            topBorder:SetVertexColor(bc[1], bc[2], bc[3], bc[4])
            bottomBorder:SetVertexColor(bc[1], bc[2], bc[3], bc[4])
            leftBorder:SetVertexColor(bc[1], bc[2], bc[3], bc[4])
            rightBorder:SetVertexColor(bc[1], bc[2], bc[3], bc[4])
            headerSep:SetVertexColor(bc[1], bc[2], bc[3], bc[4])
            headerSep2:SetVertexColor(bc[1], bc[2], bc[3], bc[4])
            subHeaderBG:SetVertexColor(unpack(ns.HEADER_BG))
            headerBG:SetVertexColor(unpack(ns.HEADER_BG))
            subHeaderHL:SetVertexColor(unpack(ns.HEADER_HOVER_BG))
            catHL:SetVertexColor(unpack(ns.HEADER_HOVER_BG))
            -- Re-apply the active bar texture to every live row and the self bar
            local tex = ns.GetBarTexture()
            for _, button in scrollBox:EnumerateFrames() do
                if button.bar then
                    button.bar:SetStatusBarTexture(tex)
                    button._tex = tex
                    button.fill = button.bar:GetStatusBarTexture()
                end
            end
            if selfBar and selfBar.bar then
                selfBar.bar:SetStatusBarTexture(tex)
                selfBar._tex = tex
                selfBar.fill = selfBar.bar:GetStatusBarTexture()
            end
        end,
        RefreshTimerPos = function()
            ApplyTimerPosition()
        end,
        RefreshFonts = function()
            local fs = ns.GetFontSize()
            local font = ns.GetFont()
            -- Rows still pooled but not currently rendered are corrected by the
            -- guard in the update path on their next pass.
            local nudge = ns.GetFontNudge()
            for _, button in scrollBox:EnumerateFrames() do
                if button.nameFS then
                    button.nameFS:SetFont(font, fs, "OUTLINE")
                    button.rateFS:SetFont(font, fs, "OUTLINE")
                    button.totalFS:SetFont(font, fs, "OUTLINE")
                    button.pctFS:SetFont(font, fs, "OUTLINE")
                    button._fontPath, button._fontSize = font, fs
                    local prevFS = ns.AnchorColumns(button)
                    button.nameFS:ClearAllPoints()
                    local pad = button.icon:IsShown() and 4 or 6
                    button.nameFS:SetPoint("LEFT", button.bar, "LEFT", pad, nudge)
                    if prevFS then
                        button.nameFS:SetPoint("RIGHT", prevFS, "LEFT", -4, 0)
                    else
                        button.nameFS:SetPoint("RIGHT", button.bar, "RIGHT", -6, 0)
                    end
                end
            end
            -- Self bar shares the same font treatment as scroll rows.
            if selfBar.nameFS then
                selfBar.nameFS:SetFont(font, fs, "OUTLINE")
                selfBar.rateFS:SetFont(font, fs, "OUTLINE")
                selfBar.totalFS:SetFont(font, fs, "OUTLINE")
                selfBar.pctFS:SetFont(font, fs, "OUTLINE")
                selfBar._fontPath, selfBar._fontSize = font, fs
                local prevSelfFS = ns.AnchorColumns(selfBar)
                selfBar.nameFS:ClearAllPoints()
                local selfPad = selfBar.icon:IsShown() and 4 or 6
                selfBar.nameFS:SetPoint("LEFT", selfBar.bar, "LEFT", selfPad, nudge)
                if prevSelfFS then
                    selfBar.nameFS:SetPoint("RIGHT", prevSelfFS, "LEFT", -4, 0)
                else
                    selfBar.nameFS:SetPoint("RIGHT", selfBar.bar, "RIGHT", -6, 0)
                end
            end
            catText:SetFont(font, 11, "OUTLINE")
            typeText:SetFont(font, 11, "OUTLINE")
            timerFS:SetFont(font, ns.BAR_FONT_SIZE, "OUTLINE")
            sessionText:SetFont(font, ns.BAR_FONT_SIZE, "OUTLINE")
            catText:SetPoint("LEFT", ns.TEXT_PAD, nudge)
            typeText:SetPoint("LEFT", ns.TEXT_PAD, nudge)
            sessionText:SetPoint("CENTER", subHeader, "CENTER", 0, nudge)
            ApplyTimerPosition()
            state.UpdateHeader()
        end,
        RefreshBarHeight = function()
            local bh = ns.GetBarHeight()
            view:SetElementExtent(bh)
            for _, button in scrollBox:EnumerateFrames() do
                if button.bar then
                    button:SetHeight(bh)
                    button.icon:SetWidth(bh - ns.BAR_SPACING)
                end
            end
            state.CollectData()
        end,
    }

    return win
end
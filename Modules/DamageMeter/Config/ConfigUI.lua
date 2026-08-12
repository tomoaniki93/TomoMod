local ADDON_NAME, ns = ...
local L = ns.L

----------------------------------------------------------------------
-- Settings Panel (Tabbed)
----------------------------------------------------------------------

local settingsFrame = nil

-- Helper: get display name for a window's current meter type
local function GetWindowTabName(winIndex)
    local win = ns.windows[winIndex]
    if not win then return string.format(L["SETTINGS_TAB_WINDOW"], winIndex) end
    local meterType = win.GetMeterType()
    local info = ns.TYPE_INFO[meterType]
    if info then
        return L[info.key] or info.key
    end
    return string.format(L["SETTINGS_TAB_WINDOW"], winIndex)
end

local function CreateSettingsPanel()
    local frame = CreateFrame("Frame", "TomoDamageMeterSettings", UIParent, "BackdropTemplate")
    frame:SetSize(340, 690)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)

    frame:SetBackdrop({
        bgFile = ns.FLAT,
        edgeFile = ns.FLAT,
        edgeSize = 1,
    })
    -- Deliberately NOT skinned. The settings panel is a tool, not a HUD
    -- element: it has to stay legible whatever preset is active, and a preset
    -- tuned for readability over a game world is not automatically readable as
    -- a dense form. It keeps a fixed dark palette and borrows only the accent,
    -- corrected below when the skin's own accent is too dark to sit on it.
    frame:SetBackdropColor(0.00, 0.00, 0.00, 0.92)
    frame:SetBackdropBorderColor(ns.BORDER_COLOR[1], ns.BORDER_COLOR[2], ns.BORDER_COLOR[3], ns.BORDER_COLOR[4])

    -- Title
    local title = frame:CreateFontString(nil, "ARTWORK")
    title:SetFont(ns.GetFont(), 13, "OUTLINE")
    title:SetTextColor(ns.PanelAccent())
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText(L["SETTINGS_TITLE"])

    -- Close button (texture)
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -6, -6)
    local closeIcon = closeBtn:CreateTexture(nil, "ARTWORK")
    closeIcon:SetTexture(ns.TEX_CLOSE)
    closeIcon:SetSize(10, 10)
    closeIcon:SetPoint("CENTER")
    closeIcon:SetVertexColor(unpack(ns.TEXT_MUTED))
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeIcon:SetVertexColor(1, 1, 1) end)
    closeBtn:SetScript("OnLeave", function() closeIcon:SetVertexColor(unpack(ns.TEXT_MUTED)) end)

    ----------------------------------------------------------------------
    -- Tab Bar
    ----------------------------------------------------------------------

    local TAB_HEIGHT = 22
    local TAB_PAD = 2
    local tabBar = CreateFrame("Frame", nil, frame)
    tabBar:SetPoint("TOPLEFT", 12, -30)
    tabBar:SetPoint("TOPRIGHT", -12, -30)
    tabBar:SetHeight(TAB_HEIGHT)

    -- Tab separator line
    local tabSep = frame:CreateTexture(nil, "ARTWORK")
    tabSep:SetTexture(ns.FLAT)
    tabSep:SetVertexColor(ns.BORDER_COLOR[1], ns.BORDER_COLOR[2], ns.BORDER_COLOR[3], 0.5)
    tabSep:SetHeight(1)
    tabSep:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, 0)
    tabSep:SetPoint("TOPRIGHT", tabBar, "BOTTOMRIGHT", 0, 0)

    -- Content area: scrollable container below tabs
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
    scrollFrame:SetPoint("TOPLEFT", tabSep, "BOTTOMLEFT", 0, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", -12, 12)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        local step = 30
        local newVal = math.max(0, math.min(cur - delta * step, max))
        self:SetVerticalScroll(newVal)
    end)
    scrollFrame:SetScript("OnSizeChanged", function(self, w)
        local child = self:GetScrollChild()
        if child then child:SetWidth(w) end
    end)

    -- Tab system
    local tabs = {}
    local tabContents = {}
    local activeTab = nil

    -- Persistent state. Tabs, content frames and every widget inside them are
    -- built exactly once and reused: WoW frames cannot be destroyed, so the old
    -- "hide everything, wipe the tables, recreate from scratch" rebuild leaked a
    -- full panel's worth of frames on every open / skin change / category toggle.
    local tabCount = 0        -- tabs currently in use (1 = General, then windows)
    local contentBuilt = {}   -- index -> true once its widgets exist
    local refreshables = {}   -- widgets exposing :Refresh(), re-read on open
    local accentTexts = {}    -- FontStrings tinted with the accent colour

    local function RegisterAccentText(fs)
        accentTexts[#accentTexts + 1] = fs
        return fs
    end

    -- Re-read every widget's value from the DB and re-tint accent-driven text.
    -- Replaces the old rebuild for "the data changed" cases.
    local function RefreshWidgets()
        for _, w in ipairs(refreshables) do
            if w.Refresh then w.Refresh() end
        end
        for _, fs in ipairs(accentTexts) do
            fs:SetTextColor(ns.PanelAccent())
        end
        if activeTab and tabs[activeTab] then
            local pr, pg, pb = ns.PanelAccent(); tabs[activeTab].bg:SetVertexColor(pr * 0.3, pg * 0.3, pb * 0.3, 0.90)
            tabs[activeTab].text:SetTextColor(ns.PanelAccent())
        end
    end

    local buildContent  -- forward declaration (defined once the builders exist)

    local function SetActiveTab(index, force)
        if activeTab == index and not force then return end
        -- Content is built on first activation, then reused forever.
        if buildContent then buildContent(index) end
        -- Deactivate previous
        if activeTab and tabs[activeTab] then
            tabs[activeTab].bg:SetVertexColor(0.05, 0.08, 0.14, 0.70)
            tabs[activeTab].text:SetTextColor(0.40, 0.40, 0.43)
        end
        if activeTab and tabContents[activeTab] then
            tabContents[activeTab]:Hide()
        end
        -- Activate new
        activeTab = index
        if tabs[index] then
            local pr, pg, pb = ns.PanelAccent(); tabs[index].bg:SetVertexColor(pr * 0.3, pg * 0.3, pb * 0.3, 0.90)
            tabs[index].text:SetTextColor(ns.PanelAccent())
        end
        if tabContents[index] then
            scrollFrame:SetScrollChild(tabContents[index])
            tabContents[index]:SetWidth(scrollFrame:GetWidth())
            tabContents[index]:Show()
            scrollFrame:SetVerticalScroll(0)
        end
    end

    local function CreateTab(index, labelText)
        local tab = CreateFrame("Button", nil, tabBar)
        tab:SetHeight(TAB_HEIGHT)

        local bg = tab:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture(ns.FLAT)
        bg:SetVertexColor(0.05, 0.08, 0.14, 0.70)
        bg:SetAllPoints()

        local text = tab:CreateFontString(nil, "ARTWORK")
        text:SetFont(ns.GetFont(), 10, "OUTLINE")
        text:SetTextColor(0.40, 0.40, 0.43)
        text:SetWordWrap(false)
        text:SetNonSpaceWrap(false)
        text:SetText(labelText)

        local hl = tab:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture(ns.FLAT)
        hl:SetVertexColor(1, 1, 1, 0.06)
        hl:SetAllPoints()

        tab.bg = bg
        tab.text = text

        tab:SetScript("OnClick", function()
            SetActiveTab(index)
        end)

        return tab
    end

    local function CreateContentFrame()
        local c = CreateFrame("Frame", nil, scrollFrame)
        c:SetWidth(scrollFrame:GetWidth())
        c:Hide()
        return c
    end

    ----------------------------------------------------------------------
    -- Build General Tab Content
    ----------------------------------------------------------------------

    local function BuildGeneralContent(parent)
        local yOff = 0
        local function AddWidget(widget, height)
            widget:SetParent(parent)
            widget:ClearAllPoints()
            widget:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -yOff)
            widget:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
            yOff = yOff + (height or 50) + 6
            refreshables[#refreshables + 1] = widget
        end

        local function AddSection(text)
            local fs = parent:CreateFontString(nil, "ARTWORK")
            fs:SetFont(ns.GetFont(), 11, "OUTLINE")
            fs:SetTextColor(ns.PanelAccent())
            fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -yOff)
            fs:SetText(text)
            yOff = yOff + 18
            RegisterAccentText(fs)
        end

        -- Appearance
        AddSection(L["SETTINGS_APPEARANCE"])

        -- Skin preset (seeds accent / bg opacity / bar height / texture)
        local skinDD = ns.Widgets.CreateDropdown(parent, L["SETTINGS_SKIN"],
            ns.GetSkinList(),
            function() return ns.db.skin or "DARK" end,
            function(val)
                ns.ApplySkin(val, true)
                if settingsFrame and settingsFrame.Refresh then
                    settingsFrame.Refresh()
                end
            end)
        AddWidget(skinDD, 30)

        -- Bar texture (every statusbar registered in LibSharedMedia)
        local texDD = ns.Widgets.CreateDropdown(parent, L["SETTINGS_BAR_TEXTURE"],
            ns.GetTextureList,   -- live: LSM textures can be registered after us
            function() return ns.db.barTexture or ns.TEX_FLAT end,
            function(val)
                ns.db.barTexture = val
                for _, win in ipairs(ns.windows) do
                    if win.RefreshSkin then win.RefreshSkin() end
                    win.Refresh()
                end
            end)
        AddWidget(texDD, 30)

        local fontSlider = ns.Widgets.CreateSlider(parent, L["SETTINGS_FONT_SIZE"],
            8, 22, 1,
            function() return ns.db.fontSize end,
            function(val)
                ns.db.fontSize = val
                ns.ClearCharWidthCache()
                for _, win in ipairs(ns.windows) do
                    if win.RefreshFonts then win.RefreshFonts() end
                    win.Refresh()
                end
            end)
        AddWidget(fontSlider, 50)

        -- Font face dropdown
        local fontOptions = {}
        for _, entry in ipairs(ns.FONT_LIST) do
            fontOptions[#fontOptions + 1] = {
                value = entry.path,
                label = L[entry.key] or entry.key,
                fontPath = entry.path,
            }
        end
        local fontDD = ns.Widgets.CreateDropdown(parent, L["SETTINGS_FONT_FACE"],
            fontOptions,
            function() return ns.db.fontPath end,
            function(val)
                ns.db.fontPath = val
                ns.ClearCharWidthCache()
                for _, win in ipairs(ns.windows) do
                    if win.RefreshFonts then win.RefreshFonts() end
                    win.Refresh()
                end
                if ns.RefreshBreakdownFonts then ns.RefreshBreakdownFonts() end
                if ns.RefreshTargetBreakdownFonts then ns.RefreshTargetBreakdownFonts() end
            end)
        AddWidget(fontDD, 30)

        local barSlider = ns.Widgets.CreateSlider(parent, L["SETTINGS_BAR_HEIGHT"],
            14, 32, 1,
            function() return ns.db.barHeight end,
            function(val)
                ns.db.barHeight = val
                for _, win in ipairs(ns.windows) do
                    if win.RefreshBarHeight then win.RefreshBarHeight() end
                end
            end)
        AddWidget(barSlider, 50)

        local bgSlider = ns.Widgets.CreateSlider(parent, L["SETTINGS_BG_OPACITY"],
            0, 1, 0.05,
            function() return ns.db.bgAlpha end,
            function(val)
                ns.db.bgAlpha = val
                for _, win in ipairs(ns.windows) do
                    if win.SetBGAlpha then win.SetBGAlpha(val) end
                end
            end)
        AddWidget(bgSlider, 50)

        local oocSlider = ns.Widgets.CreateSlider(parent, L["SETTINGS_OOC_OPACITY"],
            0.1, 1, 0.05,
            function() return ns.db.oocAlpha end,
            function(val)
                ns.db.oocAlpha = val
                if not ns.inCombat then
                    for _, win in ipairs(ns.windows) do
                        win.SetCombatAlpha(false)
                    end
                end
            end)
        AddWidget(oocSlider, 50)

        local breakdownSlider = ns.Widgets.CreateSlider(parent, L["SETTINGS_BREAKDOWN_OPACITY"],
            0.1, 1, 0.05,
            function() return ns.db.breakdownAlpha end,
            function(val)
                ns.db.breakdownAlpha = val
                if ns.ApplyBreakdownAlpha then ns.ApplyBreakdownAlpha() end
            end)
        AddWidget(breakdownSlider, 50)

        local snapCB = ns.Widgets.CreateCheckbox(parent, L["SETTINGS_SNAP"],
            function() return ns.db.snapEnabled ~= false end,
            function(val) ns.db.snapEnabled = val and true or false end)
        AddWidget(snapCB, 24)

        local recapCB = ns.Widgets.CreateCheckbox(parent, L["SETTINGS_RUN_RECAP_AUTO"],
            function() return ns.db.runRecapAutoShow ~= false end,
            function(val) ns.db.runRecapAutoShow = val and true or false end)
        AddWidget(recapCB, 24)

        -- Columns
        AddSection(L["SETTINGS_COLUMNS"])

        -- Column config has existed in the DB (ns.db.columns / ns.FORMAT_OPTIONS)
        -- and in the renderer since the start, but was never exposed. Each column
        -- gets a visibility toggle and a format picker; both re-anchor the live
        -- rows, since AnchorColumns derives its widths from the active format.
        local COLUMN_LABELS = {
            rate  = "SETTINGS_COL_RATE",
            total = "SETTINGS_COL_TOTAL",
            pct   = "SETTINGS_COL_PCT",
        }
        local FORMAT_LABELS = {
            short  = "FMT_COMPACT",
            ["1dec"] = "FMT_1DEC",
            ["2dec"] = "FMT_2DEC",
            ["3dec"] = "FMT_3DEC",
            full   = "FMT_REGULAR",
            int    = "FMT_INT",
            dec    = "FMT_DEC",
        }

        local function GetColumn(key)
            if not ns.db.columns then return nil end
            for _, col in ipairs(ns.db.columns) do
                if col.key == key then return col end
            end
            return nil
        end

        local function ApplyColumnChange()
            for _, win in ipairs(ns.windows) do
                if win.RefreshFonts then win.RefreshFonts() end
                win.Refresh()
            end
        end

        for _, colKey in ipairs({ "rate", "total", "pct" }) do
            local labelKey = COLUMN_LABELS[colKey]
            local colLabel = L[labelKey] or labelKey

            local showCB = ns.Widgets.CreateCheckbox(parent, colLabel,
                function()
                    local col = GetColumn(colKey)
                    return col and col.show or false
                end,
                function(val)
                    local col = GetColumn(colKey)
                    if not col then return end
                    col.show = val and true or false
                    ApplyColumnChange()
                end)
            AddWidget(showCB, 24)

            local fmtDD = ns.Widgets.CreateDropdown(parent, L["SETTINGS_FORMAT"] or colLabel,
                function()
                    local out = {}
                    for _, fmt in ipairs(ns.FORMAT_OPTIONS[colKey] or {}) do
                        local lk = FORMAT_LABELS[fmt]
                        out[#out + 1] = { value = fmt, label = (lk and L[lk]) or fmt }
                    end
                    return out
                end,
                function()
                    local col = GetColumn(colKey)
                    return col and col.fmt or "1dec"
                end,
                function(val)
                    local col = GetColumn(colKey)
                    if not col then return end
                    col.fmt = val
                    ApplyColumnChange()
                end)
            AddWidget(fmtDD, 30)
        end

        -- General
        AddSection(L["SETTINGS_GENERAL"])

        local realmCB = ns.Widgets.CreateCheckbox(parent, L["SETTINGS_STRIP_REALM"],
            function() return ns.db.stripRealm end,
            function(val) ns.db.stripRealm = val; ns.Refresh() end)
        AddWidget(realmCB, 24)

        local classCB = ns.Widgets.CreateCheckbox(parent, L["SETTINGS_USE_CLASS_COLOR"],
            function() return ns.db.accentUseClassColor end,
            function(val)
                ns.db.accentUseClassColor = val
                ns.ApplyAccentColor()
                for _, win in ipairs(ns.windows) do
                    if win.RefreshAccentColor then win.RefreshAccentColor() end
                end
            end)
        AddWidget(classCB, 24)

        local autoResetCB = ns.Widgets.CreateCheckbox(parent, L["SETTINGS_AUTO_RESET_INSTANCE"],
            function() return ns.db.autoResetOnInstance end,
            function(val) ns.db.autoResetOnInstance = val end)
        AddWidget(autoResetCB, 24)

        local timerCB = ns.Widgets.CreateCheckbox(parent, L["SETTINGS_COMBAT_TIMER"],
            function() return ns.db.showCombatTimer end,
            function(val)
                ns.db.showCombatTimer = val
                for _, win in ipairs(ns.windows) do
                    if win.UpdateTimer then win.UpdateTimer() end
                end
            end)
        AddWidget(timerCB, 24)

        local timerPosDD = ns.Widgets.CreateDropdown(parent, L["SETTINGS_TIMER_POSITION"],
            {
                { value = "RIGHT", label = L["TIMER_POS_RIGHT"] },
                { value = "LEFT",  label = L["TIMER_POS_LEFT"] },
            },
            function() return ns.db.combatTimerPos or "RIGHT" end,
            function(val)
                ns.db.combatTimerPos = val
                for _, win in ipairs(ns.windows) do
                    if win.RefreshTimerPos then win.RefreshTimerPos() end
                end
            end)
        AddWidget(timerPosDD, 30)

        local selfBarCB = ns.Widgets.CreateCheckbox(parent, L["SETTINGS_SELF_BAR"],
            function() return ns.db.showSelfBar end,
            function(val)
                ns.db.showSelfBar = val
                ns.Refresh()
            end)
        AddWidget(selfBarCB, 24)

        local barTipCB = ns.Widgets.CreateCheckbox(parent, L["SETTINGS_BAR_TOOLTIPS"],
            function() return ns.db.showBarTooltips end,
            function(val) ns.db.showBarTooltips = val end)
        AddWidget(barTipCB, 24)

        -- Modules
        AddSection(L["SETTINGS_MODULES"])

        local deathRecapCB = ns.Widgets.CreateCheckbox(parent, L["SETTINGS_DEATH_RECAP_AUTO"],
            function() return ns.db.deathRecapAutoShow end,
            function(val) ns.db.deathRecapAutoShow = val end)
        AddWidget(deathRecapCB, 24)

        -- Categories
        AddSection(L["SETTINGS_CATEGORIES"])

        for catIdx, cat in ipairs(ns.METER_CATEGORIES) do
            local catLabel = L[cat.name] or cat.name
            local cb = ns.Widgets.CreateCheckbox(parent, catLabel,
                function()
                    return ns.IsCategoryEnabled(catIdx)
                end,
                function(val)
                    if not val then
                        -- Prevent disabling all categories
                        local enabledCount = 0
                        for ci = 1, #ns.METER_CATEGORIES do
                            if ns.IsCategoryEnabled(ci) then
                                enabledCount = enabledCount + 1
                            end
                        end
                        if enabledCount <= 1 then
                            print(L["ADDON_PREFIX"] .. L["SETTINGS_CATEGORIES_MIN"])
                            -- Re-read widget values to snap the checkbox back.
                            if settingsFrame and settingsFrame.Refresh then
                                settingsFrame.Refresh()
                            end
                            return
                        end
                        ns.db.disabledCategories[cat.name] = true
                    else
                        ns.db.disabledCategories[cat.name] = nil
                    end
                    ns.EnforceEnabledTypes()
                    -- Meter-type dropdowns resolve their options lazily, so a
                    -- value refresh + tab relabel is enough here.
                    if settingsFrame and settingsFrame.Refresh then
                        settingsFrame.Refresh()
                    end
                end)
            AddWidget(cb, 24)
        end

        -- Report
        AddSection(L["REPORT"])

        -- SAY and YELL are deliberately absent: the client only lets one such
        -- message through per hardware event, so a multi-line report can never
        -- arrive intact on them. See ns.RESTRICTED_CHANNELS in Core/Utils.lua.
        local channelOptions = {
            { value = "AUTO",          label = L["REPORT_CHANNEL_AUTO"] },
            { value = "INSTANCE_CHAT", label = L["REPORT_CHANNEL_INSTANCE"] },
            { value = "PARTY",         label = L["REPORT_CHANNEL_PARTY"] },
            { value = "RAID",          label = L["REPORT_CHANNEL_RAID"] },
            { value = "GUILD",         label = L["REPORT_CHANNEL_GUILD"] },
            { value = "WHISPER",       label = L["REPORT_CHANNEL_WHISPER"] },
            { value = "DEBUG",         label = L["REPORT_CHANNEL_SELF"] },
        }
        local channelDD = ns.Widgets.CreateDropdown(parent, L["SETTINGS_REPORT_CHANNEL"],
            channelOptions,
            function() return ns.db.reportChannel end,
            function(val) ns.db.reportChannel = val end)
        AddWidget(channelDD, 30)

        local linesSlider = ns.Widgets.CreateSlider(parent, L["SETTINGS_REPORT_LINES"],
            1, 20, 1,
            function() return ns.db.reportLines end,
            function(val) ns.db.reportLines = val end)
        AddWidget(linesSlider, 50)

        -- Set scroll child height to total content
        parent:SetHeight(yOff + 10)
    end

    ----------------------------------------------------------------------
    -- Build Window Tab Content
    ----------------------------------------------------------------------

    local function BuildWindowContent(parent, winIndex)
        local yOff = 0
        local function AddWidget(widget, height)
            widget:SetParent(parent)
            widget:ClearAllPoints()
            widget:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -yOff)
            widget:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
            yOff = yOff + (height or 50) + 6
            refreshables[#refreshables + 1] = widget
        end

        local function AddSection(text)
            local fs = parent:CreateFontString(nil, "ARTWORK")
            fs:SetFont(ns.GetFont(), 11, "OUTLINE")
            fs:SetTextColor(ns.PanelAccent())
            fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -yOff)
            fs:SetText(text)
            yOff = yOff + 18
            RegisterAccentText(fs)
        end

        AddSection(string.format(L["SETTINGS_TAB_WINDOW"], winIndex))

        -- Meter Type dropdown. Options are resolved on each click so that
        -- enabling / disabling a category is reflected immediately, without
        -- rebuilding the panel.
        local function MeterOptions()
            local out = {}
            for catIdx, cat in ipairs(ns.METER_CATEGORIES) do
                if ns.IsCategoryEnabled(catIdx) then
                    for _, t in ipairs(cat.types) do
                        out[#out + 1] = { value = t.type, label = L[t.key] or t.key }
                    end
                end
            end
            return out
        end
        local meterDD = ns.Widgets.CreateDropdown(parent, L["SETTINGS_METER_TYPE"],
            MeterOptions,
            function()
                local win = ns.windows[winIndex]
                return win and win.GetMeterType() or Enum.DamageMeterType.Dps
            end,
            function(val)
                local win = ns.windows[winIndex]
                if not win then return end
                win.SetMeterType(val)
                -- Update tab name
                C_Timer.After(0, function()
                    if tabs[winIndex + 1] then
                        tabs[winIndex + 1].text:SetText(GetWindowTabName(winIndex))
                    end
                end)
            end)
        AddWidget(meterDD, 30)

        -- Session Type dropdown
        local sessionOptions = {}
        for _, opt in ipairs(ns.SESSION_OPTIONS) do
            sessionOptions[#sessionOptions + 1] = {
                value = opt.type,
                label = L[opt.key] or opt.key,
            }
        end
        local sessionDD = ns.Widgets.CreateDropdown(parent, L["SETTINGS_SESSION_TYPE"],
            sessionOptions,
            function()
                local win = ns.windows[winIndex]
                return win and win.GetSessionType() or Enum.DamageMeterSessionType.Current
            end,
            function(val)
                local win = ns.windows[winIndex]
                if not win then return end
                win.SetSessionType(val)
            end)
        AddWidget(sessionDD, 30)

        -- Locked checkbox
        local lockCB = ns.Widgets.CreateCheckbox(parent, L["SETTINGS_LOCKED"],
            function()
                local win = ns.windows[winIndex]
                return win and win.cfg.locked or false
            end,
            function(val)
                local win = ns.windows[winIndex]
                if not win then return end
                win.cfg.locked = val
                if win.RefreshLockIcon then win.RefreshLockIcon() end
            end)
        AddWidget(lockCB, 24)

        -- Set scroll child height to total content
        parent:SetHeight(yOff + 10)
    end

    ----------------------------------------------------------------------
    -- Tab layout (pooled — nothing is ever destroyed and recreated)
    ----------------------------------------------------------------------

    -- Build the widgets of tab `index` the first time it is shown. Tab 1 is
    -- always General; tab i+1 always maps to window i, so the closures inside
    -- BuildWindowContent stay valid for the panel's whole lifetime.
    function buildContent(index)
        if contentBuilt[index] then return end
        local content = tabContents[index]
        if not content then return end
        contentBuilt[index] = true
        if index == 1 then
            BuildGeneralContent(content)
        else
            BuildWindowContent(content, index - 1)
        end
    end

    local function LayoutTabs()
        local wanted = #ns.windows + 1  -- General + one per window

        -- Ensure a tab + content frame exists for every slot, reusing the pool.
        for i = 1, wanted do
            if not tabs[i] then
                tabs[i] = CreateTab(i, "")
                tabContents[i] = CreateContentFrame()
            end
            tabs[i].text:SetText(i == 1 and L["SETTINGS_TAB_GENERAL"] or GetWindowTabName(i - 1))
        end

        -- Park the surplus (windows removed since last layout).
        for i = wanted + 1, #tabs do
            tabs[i]:Hide()
            if tabContents[i] then tabContents[i]:Hide() end
        end
        tabCount = wanted

        -- Layout tabs
        local TAB_MAX_WIDTH = 80
        local xOff = 0
        for i = 1, wanted do
            local tab = tabs[i]
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", tabBar, "TOPLEFT", xOff, 0)
            local textWidth = tab.text:GetStringWidth()
            local tabWidth = math.min(textWidth + 16, TAB_MAX_WIDTH)
            tab:SetWidth(tabWidth)
            -- Anchor text inside the tab with margins for truncation
            tab.text:ClearAllPoints()
            tab.text:SetPoint("LEFT", tab, "LEFT", 4, 0)
            tab.text:SetPoint("RIGHT", tab, "RIGHT", -4, 0)
            tab:Show()
            xOff = xOff + tab:GetWidth() + TAB_PAD
        end

        -- Add window management: + and - buttons in the tab bar
        if not frame._addTabBtn then
            local addBtn = CreateFrame("Button", nil, tabBar)
            addBtn:SetHeight(TAB_HEIGHT)
            addBtn:SetWidth(26)
            local addBG = addBtn:CreateTexture(nil, "BACKGROUND")
            addBG:SetTexture(ns.FLAT)
            addBG:SetVertexColor(0.05, 0.12, 0.20, 0.70)
            addBG:SetAllPoints()
            local addText = addBtn:CreateFontString(nil, "ARTWORK")
            addText:SetFont(ns.GetFont(), 11, "OUTLINE")
            addText:SetTextColor(1.00, 1.00, 1.00)
            addText:SetPoint("CENTER")
            addText:SetText("+")
            local addHL = addBtn:CreateTexture(nil, "HIGHLIGHT")
            addHL:SetTexture(ns.FLAT); addHL:SetVertexColor(1, 1, 1, 0.08)
            addHL:SetAllPoints()
            addBtn:SetScript("OnClick", function()
                if #ns.windows >= ns.MAX_WINDOWS then return end
                ns.CreateNewWindow()
                LayoutTabs()
                SetActiveTab(#ns.windows + 1)
            end)
            frame._addTabBtn = addBtn
            frame._addTabText = addText

            local removeBtn = CreateFrame("Button", nil, tabBar)
            removeBtn:SetHeight(TAB_HEIGHT)
            removeBtn:SetWidth(26)
            local removeBG = removeBtn:CreateTexture(nil, "BACKGROUND")
            removeBG:SetTexture(ns.FLAT)
            removeBG:SetVertexColor(0.05, 0.12, 0.20, 0.70)
            removeBG:SetAllPoints()
            local removeText = removeBtn:CreateFontString(nil, "ARTWORK")
            removeText:SetFont(ns.GetFont(), 11, "OUTLINE")
            removeText:SetTextColor(1.00, 1.00, 1.00)
            removeText:SetPoint("CENTER")
            removeText:SetText("-")
            local removeHL = removeBtn:CreateTexture(nil, "HIGHLIGHT")
            removeHL:SetTexture(ns.FLAT); removeHL:SetVertexColor(1, 1, 1, 0.08)
            removeHL:SetAllPoints()
            removeBtn:SetScript("OnClick", function()
                if #ns.windows <= 1 then return end
                ns.RemoveWindow()
                LayoutTabs()
                -- Clamp to the tabs still in use, and force: the index may be
                -- unchanged while the tab behind it now points elsewhere.
                SetActiveTab(math.min(activeTab or 1, tabCount), true)
            end)
            frame._removeTabBtn = removeBtn
            frame._removeTabText = removeText
        end

        -- Update +/- button colors based on state
        if #ns.windows >= ns.MAX_WINDOWS then
            frame._addTabText:SetTextColor(0.40, 0.40, 0.43)
        else
            frame._addTabText:SetTextColor(1.00, 1.00, 1.00)
        end
        if #ns.windows <= 1 then
            frame._removeTabText:SetTextColor(0.40, 0.40, 0.43)
        else
            frame._removeTabText:SetTextColor(1.00, 1.00, 1.00)
        end

        -- Position +/- buttons after tabs
        frame._addTabBtn:ClearAllPoints()
        frame._addTabBtn:SetPoint("TOPLEFT", tabBar, "TOPLEFT", xOff, 0)
        frame._addTabBtn:Show()
        xOff = xOff + frame._addTabBtn:GetWidth() + TAB_PAD

        frame._removeTabBtn:ClearAllPoints()
        frame._removeTabBtn:SetPoint("TOPLEFT", tabBar, "TOPLEFT", xOff, 0)
        frame._removeTabBtn:Show()

        -- Keep the current tab if it still exists, otherwise fall back to General.
        if activeTab and activeTab <= tabCount then
            SetActiveTab(activeTab, true)
        else
            SetActiveTab(1, true)
        end
    end

    -- Public surface. `Refresh` is what callers want in almost every case:
    -- it re-lays out the tab strip (window count / labels) and re-reads every
    -- widget value, without allocating anything.
    frame.LayoutTabs = LayoutTabs
    frame.Refresh = function()
        LayoutTabs()
        RefreshWidgets()
    end
    -- Back-compat alias for any call site still asking for a rebuild.
    frame.RebuildTabs = frame.Refresh

    LayoutTabs()

    frame:Hide()
    return frame
end

-- [MERGE] Minimal public surface for TomoMod's own config page. Exposing
-- two functions is deliberate: handing out `ns` would let anything reach
-- into the meter's internals.
_G.TomoMod_DamageMeterBridge = _G.TomoMod_DamageMeterBridge or {}
_G.TomoMod_DamageMeterBridge.ToggleSettings = function()
    if ns.Blocked and ns.Blocked() then return end
    if ns.ToggleSettings then ns.ToggleSettings() end
end
_G.TomoMod_DamageMeterBridge.ToggleWindows = function()
    if ns.Blocked and ns.Blocked() then return end
    for _, win in ipairs(ns.windows or {}) do
        if win.frame then win.frame:SetShown(not win.frame:IsShown()) end
    end
end

function ns.ToggleSettings()
    if not settingsFrame then
        settingsFrame = CreateSettingsPanel()
    end
    -- Re-sync tabs and widget values on open to reflect current window state.
    if not settingsFrame:IsShown() then
        settingsFrame.Refresh()
    end
    settingsFrame:SetShown(not settingsFrame:IsShown())
end
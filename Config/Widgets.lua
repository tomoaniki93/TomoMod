-- =====================================
-- Widgets.lua — Custom Config UI Widgets
-- Dark modern theme for TomoMod Config
-- =====================================

TomoMod_Widgets = {}
local W = TomoMod_Widgets

-- =====================================
-- THEME CONSTANTS
-- =====================================
W.Theme = {
    bg           = { 0.08, 0.08, 0.10, 0.97 },
    bgLight      = { 0.12, 0.12, 0.15, 1 },
    bgMid        = { 0.10, 0.10, 0.13, 1 },
    accent       = { 0.047, 0.824, 0.624, 1 },     -- #0cd29f tomo green
    accentDark   = { 0.035, 0.60, 0.45, 1 },
    accentHover  = { 0.07, 0.90, 0.70, 1 },
    border       = { 0.20, 0.20, 0.25, 1 },
    borderLight  = { 0.30, 0.30, 0.35, 1 },
    text         = { 0.90, 0.90, 0.92, 1 },
    textDim      = { 0.55, 0.55, 0.60, 1 },
    textHeader   = { 0.047, 0.824, 0.624, 1 },
    red          = { 0.90, 0.20, 0.20, 1 },
    yellow       = { 0.98, 0.82, 0.11, 1 },
    white        = { 1, 1, 1, 1 },
    separator    = { 0.20, 0.20, 0.25, 0.6 },
}

local T = W.Theme
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

-- =====================================
-- HELPERS
-- =====================================

local function SetColor(texture, colorTable)
    texture:SetColorTexture(unpack(colorTable))
end

-- =====================================
-- PANEL: Scroll container for a category
-- =====================================

function W.CreateScrollPanel(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", -14, 0)

    -- Style the scrollbar
    local scrollBar = scroll.ScrollBar
    if scrollBar then
        scrollBar:SetWidth(8)
    end

    local child = CreateFrame("Frame", nil, scroll)
    local childWidth = math.max(scroll:GetWidth(), 440)
    child:SetWidth(childWidth)
    child:SetHeight(1)
    scroll:SetScrollChild(child)

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * 30, max)))
    end)

    scroll.child = child

    -- Auto-resize child when scroll resizes
    scroll:SetScript("OnSizeChanged", function(self, w, h)
        child:SetWidth(math.max(w - 14, 440))
    end)

    -- Ensure child width is correct when first shown
    scroll:SetScript("OnShow", function(self)
        local w = self:GetWidth()
        if w and w > 0 then
            child:SetWidth(w - 14)
        end
    end)

    return scroll
end

-- =====================================
-- SECTION HEADER
-- =====================================

function W.CreateSectionHeader(parent, text, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY")
    header:SetFont(FONT_BOLD, 14, "")
    header:SetPoint("TOPLEFT", 16, yOffset)
    header:SetTextColor(unpack(T.textHeader))
    header:SetText(text)

    -- Separator line under
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 16, yOffset - 20)
    sep:SetPoint("TOPRIGHT", -16, yOffset - 20)
    SetColor(sep, T.separator)

    return header, yOffset - 30
end

-- =====================================
-- SUBSECTION LABEL
-- =====================================

function W.CreateSubLabel(parent, text, yOffset)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 11, "")
    label:SetPoint("TOPLEFT", 16, yOffset)
    label:SetTextColor(unpack(T.textDim))
    label:SetText(text)
    return label, yOffset - 18
end

-- =====================================
-- CHECKBOX
-- =====================================

function W.CreateCheckbox(parent, text, checked, yOffset, callback)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(math.max(parent:GetWidth(), 440), 28)
    frame:SetPoint("TOPLEFT", 16, yOffset)

    -- Clickable box
    local box = CreateFrame("Button", nil, frame)
    box:SetSize(18, 18)
    box:SetPoint("LEFT", 0, 0)

    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    SetColor(bg, T.bgLight)
    box.bg = bg

    local border = box:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    SetColor(border, T.border)
    box.border = border

    local check = box:CreateTexture(nil, "OVERLAY")
    check:SetSize(12, 12)
    check:SetPoint("CENTER")
    SetColor(check, T.accent)
    box.check = check

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 11, "")
    label:SetPoint("LEFT", box, "RIGHT", 8, 0)
    label:SetTextColor(unpack(T.text))
    label:SetText(text)

    -- State
    local isChecked = checked

    local function UpdateVisual()
        if isChecked then
            SetColor(check, T.accent)
            check:Show()
            SetColor(border, T.accentDark)
        else
            check:Hide()
            SetColor(border, T.border)
        end
    end
    UpdateVisual()

    box:SetScript("OnClick", function()
        isChecked = not isChecked
        UpdateVisual()
        if callback then callback(isChecked) end
    end)

    box:SetScript("OnEnter", function()
        SetColor(border, T.borderLight)
    end)
    box:SetScript("OnLeave", function()
        if isChecked then
            SetColor(border, T.accentDark)
        else
            SetColor(border, T.border)
        end
    end)

    frame.SetChecked = function(_, val)
        isChecked = val
        UpdateVisual()
    end
    frame.GetChecked = function()
        return isChecked
    end

    return frame, yOffset - 30
end

-- =====================================
-- SLIDER
-- =====================================

function W.CreateSlider(parent, text, value, minVal, maxVal, step, yOffset, callback, formatStr)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(math.max(parent:GetWidth(), 440), 50)
    frame:SetPoint("TOPLEFT", 16, yOffset)

    formatStr = formatStr or "%.0f"

    -- Label
    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 11, "")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetTextColor(unpack(T.text))

    -- Value text
    local valText = frame:CreateFontString(nil, "OVERLAY")
    valText:SetFont(FONT, 11, "")
    valText:SetPoint("TOPRIGHT", -30, 0)
    valText:SetTextColor(unpack(T.accent))

    local function UpdateLabel(v)
        label:SetText(text)
        valText:SetText(string.format(formatStr, v))
    end
    UpdateLabel(value)

    -- Slider track
    local slider = CreateFrame("Slider", nil, frame, "BackdropTemplate")
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(380, 8)
    slider:SetPoint("TOPLEFT", 0, -18)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(value)

    local trackBg = slider:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    SetColor(trackBg, T.bgLight)

    slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(12, 14)
    thumb:SetVertexColor(unpack(T.accent))

    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / step + 0.5) * step
        UpdateLabel(val)
        if callback then callback(val) end
    end)

    slider:SetScript("OnEnter", function()
        thumb:SetVertexColor(unpack(T.accentHover))
    end)
    slider:SetScript("OnLeave", function()
        thumb:SetVertexColor(unpack(T.accent))
    end)

    frame.slider = slider
    frame.SetValue = function(_, v) slider:SetValue(v); UpdateLabel(v) end
    frame.GetValue = function() return slider:GetValue() end

    return frame, yOffset - 52
end

-- =====================================
-- DROPDOWN
-- =====================================

function W.CreateDropdown(parent, text, options, selected, yOffset, callback)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(math.max(parent:GetWidth(), 440), 48)
    frame:SetPoint("TOPLEFT", 16, yOffset)

    -- Label
    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 11, "")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetTextColor(unpack(T.text))
    label:SetText(text)

    -- Button
    local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    btn:SetSize(200, 24)
    btn:SetPoint("TOPLEFT", 0, -16)
    btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    btn:SetBackdropColor(unpack(T.bgLight))
    btn:SetBackdropBorderColor(unpack(T.border))

    local btnText = btn:CreateFontString(nil, "OVERLAY")
    btnText:SetFont(FONT, 11, "")
    btnText:SetPoint("LEFT", 8, 0)
    btnText:SetTextColor(unpack(T.text))

    local arrow = btn:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(FONT, 11, "")
    arrow:SetPoint("RIGHT", -8, 0)
    arrow:SetText("▾")
    arrow:SetTextColor(unpack(T.textDim))

    -- Find display text
    local function GetDisplayText(val)
        for _, opt in ipairs(options) do
            if opt.value == val then return opt.text end
        end
        return tostring(val)
    end
    btnText:SetText(GetDisplayText(selected))

    -- Dropdown menu frame
    local menu = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    menu:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
    menu:SetSize(200, #options * 24 + 4)
    menu:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    menu:SetBackdropColor(unpack(T.bgMid))
    menu:SetBackdropBorderColor(unpack(T.border))
    menu:SetFrameStrata("DIALOG")
    menu:Hide()

    for i, opt in ipairs(options) do
        local item = CreateFrame("Button", nil, menu)
        item:SetSize(196, 24)
        item:SetPoint("TOPLEFT", 2, -(i - 1) * 24 - 2)

        local itemBg = item:CreateTexture(nil, "BACKGROUND")
        itemBg:SetAllPoints()
        SetColor(itemBg, { 0, 0, 0, 0 })

        local itemText = item:CreateFontString(nil, "OVERLAY")
        itemText:SetFont(FONT, 11, "")
        itemText:SetPoint("LEFT", 8, 0)
        itemText:SetTextColor(unpack(T.text))
        itemText:SetText(opt.text)

        item:SetScript("OnEnter", function()
            SetColor(itemBg, T.accentDark)
        end)
        item:SetScript("OnLeave", function()
            SetColor(itemBg, { 0, 0, 0, 0 })
        end)
        item:SetScript("OnClick", function()
            selected = opt.value
            btnText:SetText(opt.text)
            menu:Hide()
            if callback then callback(opt.value) end
        end)
    end

    btn:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide() else menu:Show() end
    end)

    -- Close on click elsewhere
    menu:SetScript("OnShow", function()
        menu:SetFrameLevel(100)
    end)

    frame.SetValue = function(_, val)
        selected = val
        btnText:SetText(GetDisplayText(val))
    end

    return frame, yOffset - 50
end

-- =====================================
-- COLOR PICKER BUTTON
-- =====================================

function W.CreateColorPicker(parent, text, color, yOffset, callback)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(math.max(parent:GetWidth(), 440), 30)
    frame:SetPoint("TOPLEFT", 16, yOffset)

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 11, "")
    label:SetPoint("LEFT", 0, 0)
    label:SetTextColor(unpack(T.text))
    label:SetText(text)

    local swatch = CreateFrame("Button", nil, frame, "BackdropTemplate")
    swatch:SetSize(24, 18)
    swatch:SetPoint("LEFT", label, "RIGHT", 10, 0)
    swatch:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    swatch:SetBackdropColor(color.r, color.g, color.b, 1)
    swatch:SetBackdropBorderColor(unpack(T.border))

    local rgbText = frame:CreateFontString(nil, "OVERLAY")
    rgbText:SetFont(FONT, 10, "")
    rgbText:SetPoint("LEFT", swatch, "RIGHT", 6, 0)
    rgbText:SetTextColor(unpack(T.textDim))

    local function UpdateRGB(r, g, b)
        swatch:SetBackdropColor(r, g, b, 1)
        rgbText:SetText(string.format("(%d, %d, %d)", r * 255, g * 255, b * 255))
    end
    UpdateRGB(color.r, color.g, color.b)

    swatch:SetScript("OnClick", function()
        local prev = { color.r, color.g, color.b }
        local function OnChanged()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            UpdateRGB(r, g, b)
            if callback then callback(r, g, b) end
        end
        local function OnCancel()
            UpdateRGB(prev[1], prev[2], prev[3])
            if callback then callback(prev[1], prev[2], prev[3]) end
        end

        -- TWW 11.0+ uses SetupColorPickerAndShow
        if ColorPickerFrame.SetupColorPickerAndShow then
            local info = {
                swatchFunc = OnChanged,
                cancelFunc = OnCancel,
                r = color.r,
                g = color.g,
                b = color.b,
                hasOpacity = false,
            }
            ColorPickerFrame:SetupColorPickerAndShow(info)
        else
            -- Legacy fallback (pre-TWW)
            ColorPickerFrame:SetColorRGB(color.r, color.g, color.b)
            ColorPickerFrame.hasOpacity = false
            ColorPickerFrame.func = OnChanged
            ColorPickerFrame.cancelFunc = OnCancel
            ColorPickerFrame:Hide()
            ColorPickerFrame:Show()
        end
    end)

    frame.UpdateColor = function(_, r, g, b)
        color.r, color.g, color.b = r, g, b
        UpdateRGB(r, g, b)
    end

    return frame, yOffset - 32
end

-- =====================================
-- BUTTON
-- =====================================

function W.CreateButton(parent, text, width, yOffset, callback)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width or 140, 28)
    btn:SetPoint("TOPLEFT", 16, yOffset)
    btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    btn:SetBackdropColor(unpack(T.accentDark))
    btn:SetBackdropBorderColor(unpack(T.accent))

    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_BOLD, 11, "")
    label:SetPoint("CENTER")
    label:SetTextColor(1, 1, 1, 1)
    label:SetText(text)

    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(unpack(T.accent))
        label:SetTextColor(0.08, 0.08, 0.10, 1)
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(unpack(T.accentDark))
        label:SetTextColor(1, 1, 1, 1)
    end)
    btn:SetScript("OnClick", function()
        if callback then callback() end
    end)

    return btn, yOffset - 36
end

-- =====================================
-- SEPARATOR
-- =====================================

function W.CreateSeparator(parent, yOffset)
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 16, yOffset)
    sep:SetPoint("TOPRIGHT", -16, yOffset)
    SetColor(sep, T.separator)
    return sep, yOffset - 12
end

-- =====================================
-- INFO TEXT
-- =====================================

function W.CreateInfoText(parent, text, yOffset)
    local info = parent:CreateFontString(nil, "OVERLAY")
    info:SetFont(FONT, 10, "")
    info:SetPoint("TOPLEFT", 24, yOffset)
    info:SetWidth(parent:GetWidth() - 48)
    info:SetJustifyH("LEFT")
    info:SetTextColor(unpack(T.textDim))
    info:SetText(text)
    local lines = math.ceil(info:GetStringHeight() / 12)
    return info, yOffset - (lines * 14 + 6)
end

-- =====================================
-- TAB PANEL (sub-tabs within a content area)
-- =====================================

function W.CreateTabPanel(parent, tabs)
    -- tabs = { { key="player", label="Joueur", builder=function(container) end }, ... }

    local wrapper = CreateFrame("Frame", nil, parent)
    wrapper:SetAllPoints()

    -- Tab bar background
    local tabBarHeight = 34
    local tabBar = CreateFrame("Frame", nil, wrapper)
    tabBar:SetPoint("TOPLEFT", 0, 0)
    tabBar:SetPoint("TOPRIGHT", 0, 0)
    tabBar:SetHeight(tabBarHeight)

    local tabBarBg = tabBar:CreateTexture(nil, "BACKGROUND")
    tabBarBg:SetAllPoints()
    tabBarBg:SetColorTexture(0.06, 0.06, 0.08, 1)

    local tabBarSep = tabBar:CreateTexture(nil, "ARTWORK")
    tabBarSep:SetHeight(1)
    tabBarSep:SetPoint("BOTTOMLEFT", 0, 0)
    tabBarSep:SetPoint("BOTTOMRIGHT", 0, 0)
    tabBarSep:SetColorTexture(unpack(T.border))

    -- Content area below tabs
    local content = CreateFrame("Frame", nil, wrapper)
    content:SetPoint("TOPLEFT", 0, -tabBarHeight)
    content:SetPoint("BOTTOMRIGHT", 0, 0)

    local tabButtons = {}
    local tabPanels = {}
    local currentTab = nil

    local function SwitchTab(key)
        if currentTab == key then return end

        -- Hide all panels
        for _, panel in pairs(tabPanels) do
            panel:Hide()
        end

        -- Update tab button visuals
        for tabKey, btn in pairs(tabButtons) do
            if tabKey == key then
                btn.bg:SetColorTexture(unpack(T.bgLight))
                btn.indicator:Show()
                btn.label:SetTextColor(unpack(T.accent))
            else
                btn.bg:SetColorTexture(0, 0, 0, 0)
                btn.indicator:Hide()
                btn.label:SetTextColor(unpack(T.textDim))
            end
        end

        -- Create or show the panel (lazy)
        if not tabPanels[key] then
            for _, tab in ipairs(tabs) do
                if tab.key == key and tab.builder then
                    local panel = tab.builder(content)
                    panel:SetAllPoints(content)
                    tabPanels[key] = panel
                    break
                end
            end
        end

        if tabPanels[key] then
            tabPanels[key]:Show()
        end

        currentTab = key
    end

    -- Create tab buttons
    local tabWidth = math.floor(math.max(parent:GetWidth(), 540) / #tabs)
    tabWidth = math.min(tabWidth, 110)

    for i, tab in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, tabBar)
        btn:SetSize(tabWidth, tabBarHeight)
        btn:SetPoint("TOPLEFT", (i - 1) * tabWidth, 0)

        local bg = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0)
        btn.bg = bg

        local indicator = btn:CreateTexture(nil, "OVERLAY")
        indicator:SetHeight(2)
        indicator:SetPoint("BOTTOMLEFT", 4, 0)
        indicator:SetPoint("BOTTOMRIGHT", -4, 0)
        indicator:SetColorTexture(unpack(T.accent))
        indicator:Hide()
        btn.indicator = indicator

        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont(FONT, 11, "")
        label:SetPoint("CENTER", 0, 1)
        label:SetTextColor(unpack(T.textDim))
        label:SetText(tab.label)
        btn.label = label

        btn:SetScript("OnEnter", function()
            if currentTab ~= tab.key then
                bg:SetColorTexture(0.10, 0.10, 0.13, 0.5)
            end
        end)
        btn:SetScript("OnLeave", function()
            if currentTab ~= tab.key then
                bg:SetColorTexture(0, 0, 0, 0)
            end
        end)
        btn:SetScript("OnClick", function()
            SwitchTab(tab.key)
        end)

        tabButtons[tab.key] = btn
    end

    -- Auto-select first tab immediately
    if #tabs > 0 then
        SwitchTab(tabs[1].key)
    end

    wrapper.SwitchTab = SwitchTab
    wrapper.content = content
    return wrapper
end

-- =====================================
-- MULTI-LINE EDITBOX (import/export)
-- =====================================
function W.CreateMultiLineEditBox(parent, labelText, height, yOffset, opts)
    opts = opts or {}

    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 10, yOffset)
    container:SetPoint("TOPRIGHT", -10, yOffset)
    container:SetHeight(height + 26)

    -- Label
    if labelText and labelText ~= "" then
        local label = container:CreateFontString(nil, "OVERLAY")
        label:SetFont(FONT, 11, "")
        label:SetPoint("TOPLEFT", 0, 0)
        label:SetText(labelText)
        label:SetTextColor(unpack(T.text))
        container.label = label
    end

    -- Background
    local bg = container:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 0, -20)
    bg:SetPoint("BOTTOMRIGHT", 0, 0)
    bg:SetColorTexture(0.06, 0.06, 0.08, 1)

    -- Border
    local bd = CreateFrame("Frame", nil, container, "BackdropTemplate")
    bd:SetPoint("TOPLEFT", -1, -19)
    bd:SetPoint("BOTTOMRIGHT", 1, -1)
    bd:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    bd:SetBackdropBorderColor(unpack(T.border))

    -- Scroll frame + editbox
    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, -22)
    scrollFrame:SetPoint("BOTTOMRIGHT", -24, 2)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFont(FONT, 10, "")
    editBox:SetTextColor(0.9, 0.9, 0.9, 1)
    editBox:SetWidth(scrollFrame:GetWidth() - 10)
    editBox:SetTextInsets(6, 6, 4, 4)

    scrollFrame:SetScrollChild(editBox)

    scrollFrame:SetScript("OnSizeChanged", function(self, w)
        editBox:SetWidth(math.max(w - 10, 100))
    end)

    if opts.readOnly then
        editBox:SetScript("OnChar", function(self) end)
        editBox:EnableKeyboard(false)
        editBox:SetScript("OnMouseUp", function(self)
            self:HighlightText()
        end)
    end

    if opts.onTextChanged then
        editBox:SetScript("OnTextChanged", function(self, userInput)
            if userInput then
                opts.onTextChanged(self:GetText())
            end
        end)
    end

    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    container.editBox = editBox
    container.scrollFrame = scrollFrame

    return container, yOffset - (height + 32)
end

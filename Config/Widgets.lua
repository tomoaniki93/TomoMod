-- =====================================
-- Widgets.lua — Config UI Widgets v2.7.0
-- Redesigned visual style to match new GUI:
--   • SectionHeader  : bg strip + left accent bar + bold title
--   • Card           : grouped container with framed border  [NEW]
--   • Checkbox       : pill-style with animated tick
--   • Slider         : filled-track with value badge
--   • Button         : solid accent with invert-on-hover
--   • Dropdown       : cleaner arrow + item highlight
--   • TwoColumnRow   : side-by-side widget layout           [NEW]
--   • ScrollPanel    : slim thumb, auto-hide
-- =====================================

TomoMod_Widgets = {}
local W = TomoMod_Widgets

-- =====================================================================
-- THEME
-- =====================================================================
W.Theme = {
    bg           = { 0.07,  0.07,  0.09,  0.97 },
    bgLight      = { 0.11,  0.11,  0.14,  1    },
    bgMid        = { 0.09,  0.09,  0.115, 1    },
    bgDark       = { 0.045, 0.045, 0.060, 1    },
    accent       = { 0.047, 0.824, 0.624, 1    },  -- #0cd29f
    accentDark   = { 0.030, 0.560, 0.420, 1    },
    accentHover  = { 0.080, 0.920, 0.710, 1    },
    accentBg     = { 0.047, 0.824, 0.624, 0.12 },  -- very transparent teal bg
    border       = { 0.18,  0.18,  0.22,  1    },
    borderLight  = { 0.28,  0.28,  0.34,  1    },
    text         = { 0.88,  0.90,  0.89,  1    },
    textDim      = { 0.48,  0.48,  0.54,  1    },
    textHeader   = { 0.047, 0.824, 0.624, 1    },
    red          = { 0.88,  0.22,  0.22,  1    },
    yellow       = { 0.96,  0.80,  0.10,  1    },
    white        = { 1,     1,     1,     1    },
    separator    = { 0.16,  0.16,  0.20,  0.7  },
    cardBg       = { 0.090, 0.090, 0.115, 1    },
    cardBorder   = { 0.20,  0.20,  0.26,  1    },
}

local T = W.Theme
local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

local function SC(tex, colorTable)
    local a = colorTable[4] or 1
    if tex.SetColorTexture then
        tex:SetColorTexture(colorTable[1], colorTable[2], colorTable[3], a)
    elseif tex.SetTextColor then
        tex:SetTextColor(colorTable[1], colorTable[2], colorTable[3], a)
    end
end

-- =====================================================================
-- SCROLL PANEL
-- =====================================================================
function W.CreateScrollPanel(parent)
    local SCROLLBAR_W   = 5
    local SCROLLBAR_PAD = 18
    local TRACK_PAD_V   = 8
    local THUMB_MIN_H   = 20

    local container = CreateFrame("Frame", nil, parent)
    container:SetAllPoints()

    local track = container:CreateTexture(nil, "BACKGROUND")
    track:SetWidth(SCROLLBAR_W)
    track:SetPoint("TOPRIGHT",    -4, -TRACK_PAD_V)
    track:SetPoint("BOTTOMRIGHT", -4,  TRACK_PAD_V)
    track:SetColorTexture(0.12, 0.12, 0.16, 0.8)

    local thumbFrame = CreateFrame("Frame", nil, container)
    thumbFrame:SetWidth(SCROLLBAR_W)
    thumbFrame:SetPoint("TOPRIGHT", -4, -TRACK_PAD_V)
    local thumb = thumbFrame:CreateTexture(nil, "OVERLAY")
    thumb:SetAllPoints()
    SC(thumb, T.accent)

    local scroll = CreateFrame("ScrollFrame", nil, container)
    scroll:SetPoint("TOPLEFT",     0,              0)
    scroll:SetPoint("BOTTOMRIGHT", -SCROLLBAR_PAD, 0)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(scroll:GetWidth() or 760)
    child:SetHeight(1)
    scroll:SetScrollChild(child)

    local function UpdateThumb()
        local scrollH = scroll:GetHeight() or 0
        local childH  = child:GetHeight()  or 0
        local trackH  = scrollH - 2 * TRACK_PAD_V
        local maxS    = childH - scrollH
        if maxS <= 0 then thumbFrame:Hide(); track:Hide(); return end
        track:Show(); thumbFrame:Show()
        local ratio  = math.min(scrollH / childH, 1)
        local thumbH = math.max(math.floor(trackH * ratio), THUMB_MIN_H)
        thumbFrame:SetHeight(thumbH)
        local cur    = scroll:GetVerticalScroll()
        local thumbY = (cur / maxS) * (trackH - thumbH)
        thumbFrame:SetPoint("TOPRIGHT", -4, -(TRACK_PAD_V + thumbY))
    end

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * 36, max)))
        UpdateThumb()
    end)

    thumbFrame:EnableMouse(true)
    thumbFrame:RegisterForDrag("LeftButton")
    local dragStartY, dragStartScroll
    thumbFrame:SetScript("OnDragStart", function(self)
        dragStartY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        dragStartScroll = scroll:GetVerticalScroll()
        self:SetScript("OnUpdate", function()
            local curY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            local delta     = dragStartY - curY
            local scrollH   = scroll:GetHeight() or 0
            local childH    = child:GetHeight()  or 0
            local trackH    = scrollH - 2 * TRACK_PAD_V
            local ratio     = math.min(scrollH / childH, 1)
            local thumbH    = math.max(math.floor(trackH * ratio), THUMB_MIN_H)
            local maxScroll = childH - scrollH
            local newScroll = dragStartScroll + delta * (maxScroll / (trackH - thumbH))
            scroll:SetVerticalScroll(math.max(0, math.min(newScroll, maxScroll)))
            UpdateThumb()
        end)
    end)
    thumbFrame:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    thumbFrame:SetScript("OnEnter", function() SC(thumb, T.accentHover) end)
    thumbFrame:SetScript("OnLeave", function() SC(thumb, T.accent) end)

    scroll:SetScript("OnSizeChanged", function(self, w, h)
        child:SetWidth(math.max(w, 10)); UpdateThumb()
    end)
    scroll:SetScript("OnShow", function(self)
        local w = self:GetWidth()
        if w and w > 0 then child:SetWidth(w) end
        UpdateThumb()
    end)

    container.UpdateScroll = UpdateThumb
    container.child  = child
    container.scroll = scroll
    scroll.child        = child
    scroll.UpdateScroll = UpdateThumb
    return scroll
end

-- =====================================================================
-- SECTION HEADER  — bg strip + left accent bar + bold title
-- =====================================================================
function W.CreateSectionHeader(parent, text, yOffset)
    local STRIP_H = 28

    local strip = parent:CreateTexture(nil, "BACKGROUND")
    strip:SetHeight(STRIP_H)
    strip:SetPoint("TOPLEFT",  8,  yOffset)
    strip:SetPoint("TOPRIGHT", -8, yOffset)
    strip:SetColorTexture(T.accent[1] * 0.10, T.accent[2] * 0.10, T.accent[3] * 0.10, 1)

    local bar = parent:CreateTexture(nil, "ARTWORK")
    bar:SetWidth(3)
    bar:SetHeight(STRIP_H)
    bar:SetPoint("TOPLEFT", 8, yOffset)
    SC(bar, T.accent)

    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_BOLD, 12, "")
    lbl:SetPoint("LEFT", bar, "RIGHT", 7, 0)
    SC(lbl, T.textHeader)
    lbl:SetText(text)

    return lbl, yOffset - STRIP_H - 8
end

-- =====================================================================
-- CARD  — frosted group container  [NEW]
-- Returns (card, innerY) where innerY is the Y offset for first child
-- Usage: local card, cy = W.CreateCard(c, "Titre", y)
--        W.CreateCheckbox(card.inner, ..., cy, ...)
--        W.FinalizeCard(card, cy)
-- =====================================================================
function W.CreateCard(parent, title, yOffset)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT",  8,  yOffset)
    card:SetPoint("TOPRIGHT", -8, yOffset)
    card:SetHeight(40) -- will be adjusted by FinalizeCard
    card:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    card:SetBackdropColor(T.cardBg[1], T.cardBg[2], T.cardBg[3], T.cardBg[4])
    card:SetBackdropBorderColor(T.cardBorder[1], T.cardBorder[2], T.cardBorder[3], T.cardBorder[4])

    -- Left accent thin stripe
    local accentBar = card:CreateTexture(nil, "ARTWORK")
    accentBar:SetWidth(2)
    accentBar:SetPoint("TOPLEFT",    0, -1)
    accentBar:SetPoint("BOTTOMLEFT", 0,  1)
    SC(accentBar, T.accentDark)

    local titleLbl
    local innerStartY
    if title and title ~= "" then
        -- Title area
        local titleBg = card:CreateTexture(nil, "BACKGROUND")
        titleBg:SetHeight(24)
        titleBg:SetPoint("TOPLEFT",  1, -1)
        titleBg:SetPoint("TOPRIGHT", -1, -1)
        titleBg:SetColorTexture(T.accent[1] * 0.08, T.accent[2] * 0.08, T.accent[3] * 0.08, 1)

        titleLbl = card:CreateFontString(nil, "OVERLAY")
        titleLbl:SetFont(FONT_BOLD, 11, "")
        titleLbl:SetPoint("TOPLEFT", 10, -6)
        titleLbl:SetText(title)
        SC(titleLbl, T.textHeader)

        local titleSep = card:CreateTexture(nil, "ARTWORK")
        titleSep:SetHeight(1)
        titleSep:SetPoint("TOPLEFT",  1, -24)
        titleSep:SetPoint("TOPRIGHT", -1, -24)
        titleSep:SetColorTexture(T.border[1], T.border[2], T.border[3], 0.5)

        innerStartY = -30
    else
        innerStartY = -8
    end

    -- Inner frame — children anchor to this
    local inner = CreateFrame("Frame", nil, card)
    inner:SetPoint("TOPLEFT",  6,   innerStartY)
    inner:SetPoint("TOPRIGHT", -6,  innerStartY)
    inner:SetHeight(1)
    card.inner        = inner
    card.innerStartY  = innerStartY
    card._startOffset = yOffset

    return card, -4  -- -4 = first child y inside inner
end

function W.FinalizeCard(card, lastY)
    local contentH = math.abs(lastY) + 8
    card.inner:SetHeight(contentH)
    local titleH = card.title and 24 or 0
    local totalH = math.abs(card.innerStartY) + contentH + 8
    card:SetHeight(totalH)
    return card._startOffset - totalH - 6  -- returns new Y for next item after card
end

-- =====================================================================
-- SUBSECTION LABEL
-- =====================================================================
function W.CreateSubLabel(parent, text, yOffset)
    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 10, "")
    lbl:SetPoint("TOPLEFT", 16, yOffset)
    SC(lbl, T.textDim)
    lbl:SetText(text)
    return lbl, yOffset - 16
end

-- =====================================================================
-- SEPARATOR
-- =====================================================================
function W.CreateSeparator(parent, yOffset)
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  16, yOffset - 4)
    sep:SetPoint("TOPRIGHT", -16, yOffset - 4)
    SC(sep, T.separator)
    return sep, yOffset - 14
end

-- =====================================================================
-- INFO TEXT  — with subtle ℹ badge
-- =====================================================================
function W.CreateInfoText(parent, text, yOffset)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -16, yOffset)

    local dot = frame:CreateTexture(nil, "ARTWORK")
    dot:SetSize(4, 4)
    dot:SetPoint("TOPLEFT", 0, -5)
    SC(dot, T.accentDark)

    local lbl = frame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 10, "")
    lbl:SetPoint("TOPLEFT",  8, 0)
    lbl:SetPoint("TOPRIGHT", 0, 0)
    lbl:SetJustifyH("LEFT")
    SC(lbl, T.textDim)
    lbl:SetText(text)

    local rawH = lbl:GetStringHeight()
    local h    = rawH or 0
    if h < 1 then h = 12 end
    local lines = math.max(1, math.ceil(h / 12))
    frame:SetHeight(lines * 14 + 4)
    return frame, yOffset - (lines * 14 + 10)
end

-- =====================================================================
-- CHECKBOX  — pill box with tick
-- =====================================================================
function W.CreateCheckbox(parent, text, checked, yOffset, callback)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(26)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -4, yOffset)

    -- The clickable box (16×16 square, slightly rounded via backdrop)
    local box = CreateFrame("Button", nil, frame, "BackdropTemplate")
    box:SetSize(16, 16)
    box:SetPoint("LEFT", 0, 0)
    box:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    box:SetBackdropColor(T.bgLight[1], T.bgLight[2], T.bgLight[3], 1)
    box:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)
    box.bg = box

    -- Tick — a simple accent-colored fill inside
    local tick = box:CreateTexture(nil, "OVERLAY")
    tick:SetPoint("TOPLEFT",     2, -2)
    tick:SetPoint("BOTTOMRIGHT", -2,  2)
    SC(tick, T.accent)

    -- Label
    local lbl = frame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, "")
    lbl:SetPoint("LEFT", box, "RIGHT", 8, 0)
    SC(lbl, T.text)
    lbl:SetText(text)

    local isChecked = checked

    local function UpdateVisual()
        if isChecked then
            tick:Show()
            box:SetBackdropColor(T.accentBg[1], T.accentBg[2], T.accentBg[3], T.accentBg[4])
            box:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 0.80)
        else
            tick:Hide()
            box:SetBackdropColor(T.bgLight[1], T.bgLight[2], T.bgLight[3], 1)
            box:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)
        end
    end
    UpdateVisual()

    local function Toggle()
        isChecked = not isChecked
        UpdateVisual()
        if callback then callback(isChecked) end
    end

    box:SetScript("OnClick", Toggle)
    -- Also allow clicking on the label
    frame:EnableMouse(true)
    frame:SetScript("OnMouseUp", function(_, btn)
        if btn == "LeftButton" then Toggle() end
    end)
    box:SetScript("OnEnter", function()
        box:SetBackdropBorderColor(T.borderLight[1], T.borderLight[2], T.borderLight[3], 1)
    end)
    box:SetScript("OnLeave", function()
        if isChecked then
            box:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 0.80)
        else
            box:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)
        end
    end)

    frame.SetChecked = function(_, val) isChecked = val; UpdateVisual() end
    frame.GetChecked = function() return isChecked end

    return frame, yOffset - 28
end

-- =====================================================================
-- SLIDER  — filled track + value badge
-- =====================================================================
function W.CreateSlider(parent, text, value, minVal, maxVal, step, yOffset, callback, formatStr)
    formatStr = formatStr or "%.0f"
    local TRACK_H = 6
    local THUMB_W = 11
    local THUMB_H = 18

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(52)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -16, yOffset)

    -- Label row
    local lbl = frame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, "")
    lbl:SetPoint("TOPLEFT", 0, 0)
    SC(lbl, T.text)
    lbl:SetText(text)

    -- Value badge (top-right)
    local valBox = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    valBox:SetSize(54, 18)
    valBox:SetPoint("TOPRIGHT", 0, 0)
    valBox:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    valBox:SetBackdropColor(T.accentBg[1], T.accentBg[2], T.accentBg[3], T.accentBg[4])
    valBox:SetBackdropBorderColor(T.accentDark[1], T.accentDark[2], T.accentDark[3], 0.5)

    local valTxt = valBox:CreateFontString(nil, "OVERLAY")
    valTxt:SetFont(FONT_BOLD, 10, "")
    valTxt:SetPoint("CENTER")
    SC(valTxt, T.accent)

    -- Track background
    local trackBg = frame:CreateTexture(nil, "BACKGROUND")
    trackBg:SetHeight(TRACK_H)
    trackBg:SetPoint("TOPLEFT",  0, -22)
    trackBg:SetPoint("TOPRIGHT", 0, -22)
    trackBg:SetColorTexture(T.bgLight[1], T.bgLight[2], T.bgLight[3], 1)

    -- Track fill (left side filled with accent)
    local trackFill = frame:CreateTexture(nil, "ARTWORK")
    trackFill:SetHeight(TRACK_H)
    trackFill:SetPoint("LEFT", trackBg, "LEFT")
    SC(trackFill, T.accentDark)

    -- Global name needed for WoW slider widget
    local sliderName = "TomoWidgetSlider_" .. tostring(math.random(1000000))
    local slider = CreateFrame("Slider", sliderName, frame, "BackdropTemplate")
    slider:SetOrientation("HORIZONTAL")
    slider:SetHeight(THUMB_H + 8)
    slider:SetPoint("TOPLEFT",  -2, -17)
    slider:SetPoint("TOPRIGHT",  2, -17)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(value)
    -- Transparent over the visible track
    slider:SetBackdropColor(0, 0, 0, 0)
    slider:SetBackdropBorderColor(0, 0, 0, 0)

    -- Custom thumb texture
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(THUMB_W, THUMB_H)
    SC(thumb, T.accent)

    local function UpdateFill(v)
        local range = maxVal - minVal
        local ratio = range > 0 and ((v - minVal) / range) or 0
        local w     = trackBg:GetWidth()
        if w and w > 0 then
            trackFill:SetWidth(math.max(0, ratio * w))
        end
    end

    local function UpdateVal(v)
        v = math.floor(v / step + 0.5) * step
        valTxt:SetText(string.format(formatStr, v))
        UpdateFill(v)
    end
    UpdateVal(value)

    slider:SetScript("OnValueChanged", function(_, v)
        v = math.floor(v / step + 0.5) * step
        UpdateVal(v)
        if callback then callback(v) end
    end)
    slider:SetScript("OnEnter", function() SC(thumb, T.accentHover) end)
    slider:SetScript("OnLeave", function() SC(thumb, T.accent) end)
    slider:SetScript("OnSizeChanged", function() UpdateFill(slider:GetValue()) end)

    frame.slider   = slider
    frame.SetValue = function(_, v) slider:SetValue(v); UpdateVal(v) end
    frame.GetValue = function() return slider:GetValue() end

    return frame, yOffset - 52
end

-- =====================================================================
-- DROPDOWN  — cleaner arrow + item highlight
-- =====================================================================
function W.CreateDropdown(parent, text, options, selected, yOffset, callback)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(46)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -16, yOffset)

    local lbl = frame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, "")
    lbl:SetPoint("TOPLEFT", 0, 0)
    SC(lbl, T.text)
    lbl:SetText(text)

    local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    btn:SetHeight(24)
    btn:SetPoint("TOPLEFT",  0, -18)
    btn:SetPoint("TOPRIGHT", 0, -18)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(T.bgLight[1], T.bgLight[2], T.bgLight[3], 1)
    btn:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)

    local btnTxt = btn:CreateFontString(nil, "OVERLAY")
    btnTxt:SetFont(FONT, 11, "")
    btnTxt:SetPoint("LEFT", 8, 0)
    btnTxt:SetPoint("RIGHT", -22, 0)
    SC(btnTxt, T.text)

    -- Arrow icon
    local arrow = btn:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(10, 6)
    arrow:SetPoint("RIGHT", -8, 0)
    arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Down")
    SC(arrow, T.textDim)

    local function GetDisplayText(val)
        for _, opt in ipairs(options) do
            if opt.value == val then return opt.text end
        end
        return tostring(val or "")
    end
    btnTxt:SetText(GetDisplayText(selected))

    -- Menu frame
    local menu = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    menu:SetPoint("TOPLEFT",  btn, "BOTTOMLEFT",  0, -2)
    menu:SetPoint("TOPRIGHT", btn, "BOTTOMRIGHT", 0, -2)
    menu:SetHeight(#options * 22 + 6)
    menu:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    menu:SetBackdropColor(T.bgMid[1], T.bgMid[2], T.bgMid[3], 1)
    menu:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)
    menu:SetFrameStrata("DIALOG")
    menu:Hide()

    for i, opt in ipairs(options) do
        local item = CreateFrame("Button", nil, menu)
        item:SetHeight(22)
        item:SetPoint("TOPLEFT",  3, -(i - 1) * 22 - 3)
        item:SetPoint("TOPRIGHT", -3, -(i - 1) * 22 - 3)

        local itemBg = item:CreateTexture(nil, "BACKGROUND")
        itemBg:SetAllPoints()
        itemBg:SetColorTexture(0, 0, 0, 0)

        local itemTxt = item:CreateFontString(nil, "OVERLAY")
        itemTxt:SetFont(FONT, 11, "")
        itemTxt:SetPoint("LEFT", 8, 0)
        SC(itemTxt, T.text)
        itemTxt:SetText(opt.text)

        item:SetScript("OnEnter", function() itemBg:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], 0.16) end)
        item:SetScript("OnLeave", function() itemBg:SetColorTexture(0, 0, 0, 0) end)
        item:SetScript("OnClick", function()
            selected = opt.value
            btnTxt:SetText(opt.text)
            menu:Hide()
            btn:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)
            if callback then callback(opt.value) end
        end)
    end

    btn:SetScript("OnClick", function()
        if menu:IsShown() then
            menu:Hide()
            btn:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)
        else
            menu:Show()
            menu:SetFrameLevel(btn:GetFrameLevel() + 50)
            btn:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 0.70)
        end
    end)
    btn:SetScript("OnEnter", function()
        btn:SetBackdropBorderColor(T.borderLight[1], T.borderLight[2], T.borderLight[3], 1)
    end)
    btn:SetScript("OnLeave", function()
        if not menu:IsShown() then
            btn:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)
        end
    end)

    frame.SetValue = function(_, val)
        selected = val; btnTxt:SetText(GetDisplayText(val))
    end
    return frame, yOffset - 48
end

-- =====================================================================
-- BUTTON  — accent fill, invert on hover
-- =====================================================================
function W.CreateButton(parent, text, width, yOffset, callback)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width or 160, 28)
    btn:SetPoint("TOPLEFT", 16, yOffset)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(T.accentDark[1], T.accentDark[2], T.accentDark[3], 0.9)
    btn:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 0.60)

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_BOLD, 11, "")
    lbl:SetPoint("CENTER")
    lbl:SetText(text)
    lbl:SetTextColor(1, 1, 1, 1)

    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(T.accent[1], T.accent[2], T.accent[3], 1)
        btn:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 1)
        lbl:SetTextColor(0.06, 0.06, 0.08, 1)
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(T.accentDark[1], T.accentDark[2], T.accentDark[3], 0.9)
        btn:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 0.60)
        lbl:SetTextColor(1, 1, 1, 1)
    end)
    btn:SetScript("OnClick", function() if callback then callback() end end)

    return btn, yOffset - 36
end

-- =====================================================================
-- COLOR PICKER
-- =====================================================================
function W.CreateColorPicker(parent, text, color, yOffset, callback)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(30)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -16, yOffset)

    local lbl = frame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, "")
    lbl:SetPoint("LEFT", 0, 0)
    SC(lbl, T.text)
    lbl:SetText(text)

    local swatch = CreateFrame("Button", nil, frame, "BackdropTemplate")
    swatch:SetSize(26, 18)
    swatch:SetPoint("RIGHT", 0, 0)
    swatch:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    swatch:SetBackdropColor(color.r, color.g, color.b, 1)
    swatch:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)

    local rgbTxt = frame:CreateFontString(nil, "OVERLAY")
    rgbTxt:SetFont(FONT, 9, "")
    rgbTxt:SetPoint("RIGHT", swatch, "LEFT", -6, 0)
    SC(rgbTxt, T.textDim)

    local function UpdateDisplay(r, g, b)
        swatch:SetBackdropColor(r, g, b, 1)
        rgbTxt:SetText(string.format("%d/%d/%d", r*255, g*255, b*255))
    end
    UpdateDisplay(color.r, color.g, color.b)

    swatch:SetScript("OnClick", function()
        local prev = { color.r, color.g, color.b }
        local function OnChanged()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            color.r, color.g, color.b = r, g, b
            UpdateDisplay(r, g, b)
            if callback then callback(r, g, b) end
        end
        local function OnCancel()
            color.r, color.g, color.b = prev[1], prev[2], prev[3]
            UpdateDisplay(prev[1], prev[2], prev[3])
            if callback then callback(prev[1], prev[2], prev[3]) end
        end
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc = OnChanged, cancelFunc = OnCancel,
                r = color.r, g = color.g, b = color.b, hasOpacity = false,
            })
        else
            ColorPickerFrame:SetColorRGB(color.r, color.g, color.b)
            ColorPickerFrame.hasOpacity = false
            ColorPickerFrame.func       = OnChanged
            ColorPickerFrame.cancelFunc = OnCancel
            ColorPickerFrame:Hide(); ColorPickerFrame:Show()
        end
    end)
    swatch:SetScript("OnEnter", function()
        swatch:SetBackdropBorderColor(T.borderLight[1], T.borderLight[2], T.borderLight[3], 1)
    end)
    swatch:SetScript("OnLeave", function()
        swatch:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)
    end)

    frame.UpdateColor = function(_, r, g, b)
        color.r, color.g, color.b = r, g, b; UpdateDisplay(r, g, b)
    end
    return frame, yOffset - 32
end

-- =====================================================================
-- TWO-COLUMN ROW  [NEW]  — place two slim items side by side
-- Usage: local _, ny = W.CreateTwoColumnRow(c, y, builderLeft, builderRight)
-- Each builder: function(container) -> yOffset after
-- =====================================================================
function W.CreateTwoColumnRow(parent, yOffset, builderLeft, builderRight)
    local ROW_H = 36
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(ROW_H)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -16, yOffset)

    local leftCol = CreateFrame("Frame", nil, frame)
    leftCol:SetPoint("TOPLEFT",  0, 0)
    leftCol:SetPoint("TOPRIGHT", frame, "TOP", -4, 0)
    leftCol:SetHeight(ROW_H)

    local rightCol = CreateFrame("Frame", nil, frame)
    rightCol:SetPoint("TOPLEFT",  frame, "TOP", 4, 0)
    rightCol:SetPoint("TOPRIGHT", 0, 0)
    rightCol:SetHeight(ROW_H)

    local ny_l, ny_r = 0, 0
    if builderLeft  then ny_l = builderLeft(leftCol)   end
    if builderRight then ny_r = builderRight(rightCol)  end

    local usedH = math.max(math.abs(ny_l), math.abs(ny_r), ROW_H)
    frame:SetHeight(usedH)
    leftCol:SetHeight(usedH)
    rightCol:SetHeight(usedH)
    return frame, yOffset - usedH - 4
end

-- =====================================================================
-- TAB PANEL
-- =====================================================================
function W.CreateTabPanel(parent, tabs)
    local wrapper = CreateFrame("Frame", nil, parent)
    wrapper:SetAllPoints()

    local TABS_PER_ROW = 6
    local totalTabs    = #tabs
    local numRows      = math.ceil(totalTabs / TABS_PER_ROW)
    local TAB_H        = 32

    -- Tab bar
    local tabBar = CreateFrame("Frame", nil, wrapper)
    tabBar:SetPoint("TOPLEFT")
    tabBar:SetPoint("TOPRIGHT")
    tabBar:SetHeight(TAB_H * numRows)

    local tabBarBg = tabBar:CreateTexture(nil, "BACKGROUND")
    tabBarBg:SetAllPoints()
    tabBarBg:SetColorTexture(0.052, 0.052, 0.066, 1)

    local tabBarBtm = tabBar:CreateTexture(nil, "ARTWORK")
    tabBarBtm:SetHeight(1)
    tabBarBtm:SetPoint("BOTTOMLEFT")
    tabBarBtm:SetPoint("BOTTOMRIGHT")
    tabBarBtm:SetColorTexture(0.14, 0.14, 0.17, 1)

    -- Content
    local content = CreateFrame("Frame", nil, wrapper)
    content:SetPoint("TOPLEFT",     0, -(TAB_H * numRows))
    content:SetPoint("BOTTOMRIGHT", 0, 0)

    local tabButtons = {}
    local tabPanels  = {}
    local currentTab = nil

    local function SwitchTab(key)
        if currentTab == key then return end
        for _, p in pairs(tabPanels) do p:Hide() end

        for k, btn in pairs(tabButtons) do
            if k == key then
                btn.indicator:Show()
                btn.bg:SetColorTexture(T.accentBg[1], T.accentBg[2], T.accentBg[3], T.accentBg[4])
                SC(btn.lbl, T.accent)
            else
                btn.indicator:Hide()
                btn.bg:SetColorTexture(0, 0, 0, 0)
                SC(btn.lbl, T.textDim)
            end
        end

        if not tabPanels[key] then
            for _, tab in ipairs(tabs) do
                if tab.key == key and tab.builder then
                    local p = tab.builder(content)
                    if p then p:SetAllPoints(content); tabPanels[key] = p end
                    break
                end
            end
        end

        if tabPanels[key] then tabPanels[key]:Show() end
        currentTab = key
    end

    local tabsInRow1 = math.min(totalTabs, TABS_PER_ROW)
    for i, tab in ipairs(tabs) do
        local row  = math.floor((i - 1) / TABS_PER_ROW)
        local col  = (i - 1) % TABS_PER_ROW
        local tpR  = math.min(TABS_PER_ROW, totalTabs - row * TABS_PER_ROW)
        local tW   = math.floor((parent:GetWidth() or 810) / tpR)

        local btn = CreateFrame("Button", nil, tabBar)
        btn:SetSize(tW, TAB_H)
        btn:SetPoint("TOPLEFT", col * tW, -(row * TAB_H))

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(); bg:SetColorTexture(0, 0, 0, 0)
        btn.bg = bg

        -- Bottom indicator line
        local ind = btn:CreateTexture(nil, "ARTWORK")
        ind:SetHeight(2)
        ind:SetPoint("BOTTOMLEFT",  3, 0)
        ind:SetPoint("BOTTOMRIGHT", -3, 0)
        SC(ind, T.accent)
        ind:Hide()
        btn.indicator = ind

        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT, 11, "")
        lbl:SetPoint("CENTER", 0, 1)
        SC(lbl, T.textDim)
        lbl:SetText(tab.label)
        btn.lbl = lbl

        btn:SetScript("OnEnter", function()
            if currentTab ~= tab.key then
                bg:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], 0.06)
                SC(lbl, T.text)
            end
        end)
        btn:SetScript("OnLeave", function()
            if currentTab ~= tab.key then
                bg:SetColorTexture(0, 0, 0, 0)
                SC(lbl, T.textDim)
            end
        end)
        btn:SetScript("OnClick", function() SwitchTab(tab.key) end)
        tabButtons[tab.key] = btn
    end

    if #tabs > 0 then SwitchTab(tabs[1].key) end
    wrapper.SwitchTab = SwitchTab
    wrapper.content   = content
    return wrapper
end

-- =====================================================================
-- MULTI-LINE EDITBOX
-- =====================================================================
function W.CreateMultiLineEditBox(parent, labelText, height, yOffset, opts)
    opts = opts or {}
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT",  10, yOffset)
    container:SetPoint("TOPRIGHT", -10, yOffset)
    container:SetHeight(height + 28)

    if labelText and labelText ~= "" then
        local lbl = container:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT, 11, "")
        lbl:SetPoint("TOPLEFT", 0, 0)
        SC(lbl, T.text)
        lbl:SetText(labelText)
        container.label = lbl
    end

    local bg = container:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT",  0, -20)
    bg:SetPoint("BOTTOMRIGHT", 0, 0)
    bg:SetColorTexture(T.bgDark[1], T.bgDark[2], T.bgDark[3], 1)

    local bd = CreateFrame("Frame", nil, container, "BackdropTemplate")
    bd:SetPoint("TOPLEFT",  -1, -19)
    bd:SetPoint("BOTTOMRIGHT", 1, -1)
    bd:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    bd:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)

    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",  0, -22)
    scrollFrame:SetPoint("BOTTOMRIGHT", -24, 2)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFont(FONT, 10, "")
    editBox:SetTextColor(0.88, 0.90, 0.89, 1)
    editBox:SetWidth(scrollFrame:GetWidth() - 10)
    editBox:SetTextInsets(6, 6, 4, 4)
    scrollFrame:SetScrollChild(editBox)
    scrollFrame:SetScript("OnSizeChanged", function(self, w) editBox:SetWidth(math.max(w - 10, 100)) end)

    if opts.readOnly then
        editBox._readOnlyText = ""
        editBox:SetScript("OnTextChanged", function(self, userInput)
            if userInput then self:SetText(self._readOnlyText); self:HighlightText() end
        end)
        editBox:SetScript("OnMouseUp", function(self) self:HighlightText() end)
        local origST = editBox.SetText
        editBox.SetText = function(self, text) self._readOnlyText = text; origST(self, text) end
    end

    if opts.onTextChanged then
        editBox:SetScript("OnTextChanged", function(self, userInput)
            if userInput then opts.onTextChanged(self:GetText()) end
        end)
    end
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    container.editBox    = editBox
    container.scrollFrame = scrollFrame
    return container, yOffset - (height + 32)
end

-- =====================================================================
-- CHECKBOX PAIR  — two checkboxes side by side  [NEW]
-- Usage: local _, ny = W.CreateCheckboxPair(c,
--            "Label A", valA, y, cbA,
--            "Label B", valB, cbB)
-- =====================================================================
function W.CreateCheckboxPair(parent, textA, valA, yOffset, cbA, textB, valB, cbB)
    local _, ny = W.CreateTwoColumnRow(parent, yOffset,
        function(col)
            local _, ny2 = W.CreateCheckbox(col, textA, valA, 0, cbA)
            return ny2
        end,
        function(col)
            local _, ny2 = W.CreateCheckbox(col, textB, valB, 0, cbB)
            return ny2
        end)
    return nil, ny
end

-- =====================================================================
-- COLOR PICKER PAIR  — two color pickers side by side  [NEW]
-- =====================================================================
function W.CreateColorPickerPair(parent, textA, colorA, textB, colorB, yOffset, cbA, cbB)
    local _, ny = W.CreateTwoColumnRow(parent, yOffset,
        function(col)
            local _, ny2 = W.CreateColorPicker(col, textA, colorA, 0, cbA)
            return ny2
        end,
        function(col)
            local _, ny2 = W.CreateColorPicker(col, textB, colorB, 0, cbB)
            return ny2
        end)
    return nil, ny
end

-- =====================================================================
-- CENTERED BUTTON GROUP  — multiple buttons in a horizontal row  [NEW]
-- buttons = { { text, width, cb }, ... }
-- =====================================================================
function W.CreateButtonRow(parent, buttons, yOffset)
    local GAP   = 10
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(32)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -16, yOffset)

    local totalW = 0
    for _, b in ipairs(buttons) do totalW = totalW + (b.width or 140) + GAP end
    totalW = totalW - GAP

    local x = 0
    for _, b in ipairs(buttons) do
        local w = b.width or 140
        local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        btn:SetSize(w, 28)
        btn:SetPoint("LEFT", x, 0)
        btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })

        local T2 = W.Theme
        btn:SetBackdropColor(T2.accentDark[1], T2.accentDark[2], T2.accentDark[3], 0.9)
        btn:SetBackdropBorderColor(T2.accent[1], T2.accent[2], T2.accent[3], 0.60)

        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf", 11, "")
        lbl:SetPoint("CENTER")
        lbl:SetText(b.text)
        lbl:SetTextColor(1, 1, 1, 1)

        btn:SetScript("OnEnter", function()
            btn:SetBackdropColor(T2.accent[1], T2.accent[2], T2.accent[3], 1)
            lbl:SetTextColor(0.06, 0.06, 0.08, 1)
        end)
        btn:SetScript("OnLeave", function()
            btn:SetBackdropColor(T2.accentDark[1], T2.accentDark[2], T2.accentDark[3], 0.9)
            lbl:SetTextColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnClick", function() if b.cb then b.cb() end end)

        x = x + w + GAP
    end

    return frame, yOffset - 38
end

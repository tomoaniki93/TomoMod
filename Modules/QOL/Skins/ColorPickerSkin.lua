-- =====================================================================
-- ColorPickerSkin.lua — TomoMod global skin for Blizzard ColorPickerFrame
-- Visual-only: Blizzard keeps ownership of color selection and callbacks.
-- =====================================================================

local WHITE = "Interface\\Buttons\\WHITE8X8"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

local ACCENT = { 0.18, 0.62, 0.85 }
local PANEL = { 0.075, 0.080, 0.088 }
local HEADER = { 0.105, 0.112, 0.122 }
local FOOTER = { 0.090, 0.096, 0.105 }
local CONTROL = { 0.055, 0.060, 0.068 }
local CONTROL_HOVER = { 0.120, 0.132, 0.142 }
local PRIMARY = { 0.060, 0.205, 0.270 }
local PRIMARY_HOVER = { 0.075, 0.265, 0.350 }
local BORDER = { 0.24, 0.27, 0.29 }
local TEXT = { 0.92, 0.95, 0.97 }
local MUTED = { 0.52, 0.57, 0.60 }

local function SetSolid(texture, color, alpha)
    if not texture then return end
    texture:SetTexture(WHITE)
    texture:SetColorTexture(color[1], color[2], color[3], alpha or 1)
end

local function HideRegion(region)
    if region and region.SetAlpha then region:SetAlpha(0) end
end

local function CreateBorders(parent, inset)
    inset = inset or 0
    local edges = {}

    local top = parent:CreateTexture(nil, "OVERLAY")
    top:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.62)
    top:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
    top:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, -inset)
    top:SetHeight(1)
    edges[#edges + 1] = top

    local bottom = parent:CreateTexture(nil, "OVERLAY")
    bottom:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.62)
    bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", inset, inset)
    bottom:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
    bottom:SetHeight(1)
    edges[#edges + 1] = bottom

    local left = parent:CreateTexture(nil, "OVERLAY")
    left:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.62)
    left:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
    left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", inset, inset)
    left:SetWidth(1)
    edges[#edges + 1] = left

    local right = parent:CreateTexture(nil, "OVERLAY")
    right:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.62)
    right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, -inset)
    right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
    right:SetWidth(1)
    edges[#edges + 1] = right

    return edges
end

local function SetBorderColor(edges, color, alpha)
    if not edges then return end
    for _, edge in ipairs(edges) do
        edge:SetColorTexture(color[1], color[2], color[3], alpha or 1)
    end
end

local function ClearButtonArtwork(button)
    if not button then return end

    -- Retail UIPanelButtonTemplate does not draw its main chrome through
    -- GetNormalTexture()/GetPushedTexture(). It uses three persistent
    -- BACKGROUND regions (Left, Middle, Right) that are retargeted by
    -- UIPanelButton_OnShow/OnMouseDown/OnMouseUp. Keep those regions
    -- transparent so Blizzard can still update their texture paths without
    -- ever painting over the TomoMod button skin.
    HideRegion(button.Left)
    HideRegion(button.Middle)
    HideRegion(button.Right)

    HideRegion(button:GetNormalTexture())
    HideRegion(button:GetPushedTexture())
    HideRegion(button:GetHighlightTexture())
    HideRegion(button:GetDisabledTexture())
end

local function RefreshButton(button, hovered, pressed)
    local skin = button and button._tomoColorPickerSkin
    if not skin then return end

    local bg
    if skin.primary then
        bg = hovered and PRIMARY_HOVER or PRIMARY
    else
        bg = hovered and CONTROL_HOVER or CONTROL
    end

    local alpha = pressed and 0.78 or 0.98
    skin.bg:SetColorTexture(bg[1], bg[2], bg[3], alpha)
    SetBorderColor(skin.border, ACCENT, hovered and 0.88 or (skin.primary and 0.62 or 0.30))

    local fs = button:GetFontString()
    if fs then
        fs:SetTextColor(pressed and 0.78 or TEXT[1], pressed and 0.84 or TEXT[2], pressed and 0.88 or TEXT[3], 1)
    end
end

local function SkinButton(button, primary)
    if not button then return end
    ClearButtonArtwork(button)

    if not button._tomoColorPickerSkin then
        local skin = { primary = primary and true or false }
        button._tomoColorPickerSkin = skin

        local bg = button:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        skin.bg = bg
        skin.border = CreateBorders(button, 0)

        button:HookScript("OnEnter", function(self)
            RefreshButton(self, true, false)
        end)
        button:HookScript("OnLeave", function(self)
            RefreshButton(self, false, false)
        end)
        button:HookScript("OnMouseDown", function(self)
            RefreshButton(self, true, true)
        end)
        button:HookScript("OnMouseUp", function(self)
            RefreshButton(self, self:IsMouseOver(), false)
        end)
    else
        button._tomoColorPickerSkin.primary = primary and true or false
    end

    local fs = button:GetFontString()
    if fs then
        fs:SetFont(FONT_BOLD, 10, "OUTLINE")
        fs:SetTextColor(TEXT[1], TEXT[2], TEXT[3], 1)
    end
    RefreshButton(button, false, false)
end

local function CreateOutline(owner, target, key)
    if not owner or not target then return nil end
    owner._tomoColorPickerOutlines = owner._tomoColorPickerOutlines or {}
    if owner._tomoColorPickerOutlines[key] then
        return owner._tomoColorPickerOutlines[key]
    end

    local holder = CreateFrame("Frame", nil, owner)
    holder:SetPoint("TOPLEFT", target, "TOPLEFT", -2, 2)
    holder:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 2, -2)
    holder:SetFrameLevel((owner:GetFrameLevel() or 1) + 2)
    holder.border = CreateBorders(holder, 0)
    SetBorderColor(holder.border, BORDER, 0.72)
    owner._tomoColorPickerOutlines[key] = holder
    return holder
end

local function CancelPicker(frame)
    if frame.cancelFunc then
        frame.cancelFunc(frame.previousValues)
    end
    if PlaySound and SOUNDKIT then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
    frame:Hide()
end

local function EnsureOuterSkin(frame)
    if frame._tomoColorPickerOuter then return frame._tomoColorPickerOuter end

    local skin = {}
    frame._tomoColorPickerOuter = skin

    local body = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    body:SetPoint("TOPLEFT", 1, -1)
    body:SetPoint("BOTTOMRIGHT", -1, 1)
    SetSolid(body, PANEL, 0.985)
    skin.body = body

    local header = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(32)
    SetSolid(header, HEADER, 0.99)
    skin.header = header

    local headerLine = frame:CreateTexture(nil, "ARTWORK", nil, -1)
    headerLine:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    headerLine:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
    headerLine:SetHeight(1)
    headerLine:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.70)
    skin.headerLine = headerLine

    local footer = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
    footer:SetPoint("BOTTOMLEFT", 1, 1)
    footer:SetPoint("BOTTOMRIGHT", -1, 1)
    footer:SetHeight(38)
    SetSolid(footer, FOOTER, 0.99)
    skin.footer = footer

    local footerLine = frame:CreateTexture(nil, "ARTWORK", nil, -1)
    footerLine:SetPoint("BOTTOMLEFT", footer, "TOPLEFT", 0, 0)
    footerLine:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", 0, 0)
    footerLine:SetHeight(1)
    footerLine:SetColorTexture(1, 1, 1, 0.07)
    skin.footerLine = footerLine

    skin.border = CreateBorders(frame, 0)
    SetBorderColor(skin.border, ACCENT, 0.56)

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(22, 22)
    close:SetPoint("TOPRIGHT", -6, -5)
    close:SetFrameLevel(frame:GetFrameLevel() + 12)

    local closeBG = close:CreateTexture(nil, "BACKGROUND")
    closeBG:SetAllPoints()
    closeBG:SetColorTexture(CONTROL[1], CONTROL[2], CONTROL[3], 0.98)
    close._bg = closeBG
    close._border = CreateBorders(close, 0)
    SetBorderColor(close._border, BORDER, 0.55)

    local closeText = close:CreateFontString(nil, "OVERLAY")
    closeText:SetFont(FONT_BOLD, 14, "OUTLINE")
    closeText:SetPoint("CENTER", 0, 1)
    closeText:SetText("×")
    closeText:SetTextColor(0.78, 0.83, 0.86, 1)
    close._text = closeText

    close:SetScript("OnEnter", function(self)
        self._bg:SetColorTexture(CONTROL_HOVER[1], CONTROL_HOVER[2], CONTROL_HOVER[3], 1)
        SetBorderColor(self._border, ACCENT, 0.82)
        self._text:SetTextColor(1, 1, 1, 1)
    end)
    close:SetScript("OnLeave", function(self)
        self._bg:SetColorTexture(CONTROL[1], CONTROL[2], CONTROL[3], 0.98)
        SetBorderColor(self._border, BORDER, 0.55)
        self._text:SetTextColor(0.78, 0.83, 0.86, 1)
    end)
    close:SetScript("OnClick", function()
        CancelPicker(frame)
    end)
    skin.close = close

    return skin
end

local function StyleHexBox(hex)
    if not hex then return end

    HideRegion(hex.Left)
    HideRegion(hex.Middle)
    HideRegion(hex.Right)

    if not hex._tomoColorPickerSkin then
        local skin = {}
        hex._tomoColorPickerSkin = skin

        local bg = hex:CreateTexture(nil, "BACKGROUND", nil, -1)
        bg:SetPoint("TOPLEFT", -2, 2)
        bg:SetPoint("BOTTOMRIGHT", 2, -2)
        bg:SetColorTexture(CONTROL[1], CONTROL[2], CONTROL[3], 0.98)
        skin.bg = bg

        skin.border = CreateBorders(hex, 0)
        SetBorderColor(skin.border, BORDER, 0.65)

        hex:HookScript("OnEditFocusGained", function(self)
            SetBorderColor(self._tomoColorPickerSkin.border, ACCENT, 0.88)
        end)
        hex:HookScript("OnEditFocusLost", function(self)
            SetBorderColor(self._tomoColorPickerSkin.border, BORDER, 0.65)
        end)
    end

    hex:SetFont(FONT, 10, "OUTLINE")
    hex:SetTextColor(TEXT[1], TEXT[2], TEXT[3], 1)
    if hex.Hash then
        hex.Hash:SetFont(FONT_BOLD, 11, "OUTLINE")
        hex.Hash:SetTextColor(MUTED[1], MUTED[2], MUTED[3], 1)
    end
    if hex.Instructions then
        hex.Instructions:SetFont(FONT, 9, "OUTLINE")
        hex.Instructions:SetTextColor(MUTED[1], MUTED[2], MUTED[3], 1)
    end
end

local function StyleMainline(frame)
    local content = frame.Content
    local footer = frame.Footer
    if not content or not footer or not content.ColorPicker then return false end

    EnsureOuterSkin(frame)

    if frame.Border then
        frame.Border:SetAlpha(0)
    end

    if frame.Header then
        HideRegion(frame.Header.LeftBG)
        HideRegion(frame.Header.CenterBG)
        HideRegion(frame.Header.RightBG)
        if frame.Header.Text then
            frame.Header.Text:SetFont(FONT_BOLD, 12, "OUTLINE")
            frame.Header.Text:SetTextColor(TEXT[1], TEXT[2], TEXT[3], 1)
        end
    end

    SkinButton(footer.OkayButton, true)
    SkinButton(footer.CancelButton, false)
    StyleHexBox(content.HexBox)

    if content.ColorSwatchCurrent then
        CreateOutline(content, content.ColorSwatchCurrent, "current")
    end
    if content.ColorSwatchOriginal then
        CreateOutline(content, content.ColorSwatchOriginal, "original")
    end

    local picker = content.ColorPicker
    if picker.Value then
        CreateOutline(picker, picker.Value, "value")
    end
    if picker.Alpha then
        local alphaOutline = CreateOutline(picker, picker.Alpha, "alpha")
        if alphaOutline then alphaOutline:SetShown(picker.Alpha:IsShown()) end
    end

    return true
end

local function StyleLegacy(frame)
    EnsureOuterSkin(frame)

    if frame.SetBackdrop then
        frame:SetBackdrop(nil)
    end

    HideRegion(_G.ColorPickerFrameHeader)

    local skin = frame._tomoColorPickerOuter
    if skin and not skin.legacyTitle then
        local title = frame:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT_BOLD, 12, "OUTLINE")
        title:SetPoint("TOP", 0, -9)
        title:SetText(COLOR_PICKER or "Color Picker")
        title:SetTextColor(TEXT[1], TEXT[2], TEXT[3], 1)
        skin.legacyTitle = title
    end

    SkinButton(_G.ColorPickerOkayButton, true)
    SkinButton(_G.ColorPickerCancelButton, false)

    if _G.ColorSwatch then
        CreateOutline(frame, _G.ColorSwatch, "legacySwatch")
    end

    return true
end

local function StyleOpacityFrame()
    local opacity = _G.OpacityFrame
    if not opacity then return end

    if opacity.Border then opacity.Border:SetAlpha(0) end
    if opacity.SetBackdrop then opacity:SetBackdrop(nil) end

    if not opacity._tomoColorPickerSkin then
        local skin = {}
        opacity._tomoColorPickerSkin = skin

        local bg = opacity:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetPoint("TOPLEFT", 1, -1)
        bg:SetPoint("BOTTOMRIGHT", -1, 1)
        bg:SetColorTexture(PANEL[1], PANEL[2], PANEL[3], 0.985)
        skin.bg = bg
        skin.border = CreateBorders(opacity, 0)
        SetBorderColor(skin.border, ACCENT, 0.56)
    end

    local slider = _G.OpacityFrameSlider
    if slider then
        if slider.SetBackdrop then
            slider:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
            slider:SetBackdropColor(CONTROL[1], CONTROL[2], CONTROL[3], 0.98)
            slider:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.38)
        end
        local thumb = slider:GetThumbTexture()
        if thumb then thumb:SetVertexColor(ACCENT[1], ACCENT[2], ACCENT[3], 1) end
    end

    local label = _G.OpacityFrameSliderText or _G.OpacityFrameText
    if label then
        label:SetFont(FONT_BOLD, 9, "OUTLINE")
        label:SetTextColor(TEXT[1], TEXT[2], TEXT[3], 1)
    end
end

local function StyleColorPicker()
    local frame = _G.ColorPickerFrame
    if not frame then return false end

    if frame.Content and frame.Footer then
        StyleMainline(frame)
    else
        StyleLegacy(frame)
    end
    StyleOpacityFrame()

    if not frame._tomoColorPickerHooked then
        frame._tomoColorPickerHooked = true
        frame:HookScript("OnShow", function(self)
            if self.Content and self.Footer then
                StyleMainline(self)
            else
                StyleLegacy(self)
            end
            StyleOpacityFrame()
        end)
    end

    return true
end

local loader = CreateFrame("Frame")

local function TryInitialize()
    if StyleColorPicker() then
        loader:UnregisterEvent("ADDON_LOADED")
        return true
    end
    return false
end

if not TryInitialize() then
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function(_, _, addonName)
        if addonName == "Blizzard_ColorPickerFrame" or _G.ColorPickerFrame then
            C_Timer.After(0, TryInitialize)
        end
    end)
end

-- A zero-delay pass also covers clients where Blizzard creates the frame at
-- the end of the current loading batch instead of before QOL.xml is parsed.
C_Timer.After(0, TryInitialize)

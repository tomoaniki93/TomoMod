-- =====================================================================
-- ChatCopy.lua — TomoMod Chat V4 copy window
-- Reuses TomoMod's proven copy UX inside the clean V4 module boundary.
-- Blizzard's live chat frame remains the source of truth; secret values are
-- never transformed, concatenated, or persisted by this module.
-- =====================================================================

local Chat = TomoMod_ChatFrameSkin
if not Chat then return end

local Copy = {}
Chat.RegisterModule("Copy", Copy)

local U = TomoMod_Utils
local L = TomoMod_L

local format, gsub, strlower = string.format, string.gsub, string.lower
local tconcat, wipe = table.concat, wipe
local floor = math.floor
local issecretvalue = issecretvalue

local AUTO_HIGHLIGHT_MAX = 8000
local copyFrame, urlPopup
local copyLines = {}

local THEME = {
    bg      = { 0.043, 0.047, 0.055, 0.95 },
    bgDark  = { 0.020, 0.024, 0.031, 1 },
    border  = { 1, 1, 1, 0.08 },
    text    = { 0.953, 0.957, 0.965, 1 },
    textDim = { 0.72,  0.72,  0.76,  1 },
}

local ADDON_PATH      = "Interface\\AddOns\\TomoMod\\"
local ADDON_FONT      = ADDON_PATH .. "Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD = ADDON_PATH .. "Assets\\Fonts\\Poppins-SemiBold.ttf"
local COPY_FONT       = UNIT_NAME_FONT or "Fonts\\ARIALN.TTF"

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function DB()
    return Chat.GetDB()
end

local function Accent()
    local brand = U and U.BRAND
    if brand then return brand[1], brand[2], brand[3] end
    return 0.180, 0.847, 0.518
end

local function Loc(key, fallback)
    local text = L and L[key]
    if type(text) == "string" and text ~= "" and text ~= key then return text end
    return fallback
end

local function Fill(texture, color, alphaOverride)
    if not texture or not color then return end
    texture:SetColorTexture(
        color[1] or 1,
        color[2] or 1,
        color[3] or 1,
        alphaOverride or color[4] or 1
    )
end

local function ApplySurface(frame, bg, border, thickness)
    thickness = thickness or 1

    if not frame._tmBG then
        frame._tmBG = frame:CreateTexture(nil, "BACKGROUND")
        frame._tmBG:SetAllPoints(frame)
    end
    Fill(frame._tmBG, bg)

    if not frame._tmEdges then
        local edges = {}
        for _, key in ipairs({ "top", "bottom", "left", "right" }) do
            edges[key] = frame:CreateTexture(nil, "BORDER")
        end
        edges.top:SetPoint("TOPLEFT")
        edges.top:SetPoint("TOPRIGHT")
        edges.bottom:SetPoint("BOTTOMLEFT")
        edges.bottom:SetPoint("BOTTOMRIGHT")
        edges.left:SetPoint("TOPLEFT")
        edges.left:SetPoint("BOTTOMLEFT")
        edges.right:SetPoint("TOPRIGHT")
        edges.right:SetPoint("BOTTOMRIGHT")
        frame._tmEdges = edges
    end

    local edges = frame._tmEdges
    edges.top:SetHeight(thickness)
    edges.bottom:SetHeight(thickness)
    edges.left:SetWidth(thickness)
    edges.right:SetWidth(thickness)
    for _, texture in pairs(edges) do Fill(texture, border) end
end

local function CreateFlatButton(parent, text, width, height, onClick, primary)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)

    local r, g, b = Accent()
    ApplySurface(
        button,
        { 1, 1, 1, 0.04 },
        primary and { r, g, b, 0.55 } or { 1, 1, 1, 0.20 },
        1
    )

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetFont(ADDON_FONT, 12, "")
    label:SetPoint("CENTER")
    label:SetText(text)
    if primary then
        label:SetTextColor(r, g, b, 1)
    else
        label:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 1)
    end
    button.text = label

    button:SetScript("OnEnter", function(self)
        Fill(self._tmBG, { r, g, b, 0.18 })
        self.text:SetTextColor(1, 1, 1, 1)
    end)
    button:SetScript("OnLeave", function(self)
        Fill(self._tmBG, { 1, 1, 1, 0.04 })
        if primary then
            self.text:SetTextColor(r, g, b, 1)
        else
            self.text:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 1)
        end
    end)
    button:SetScript("OnClick", onClick)

    return button
end

local function RGBToHex(r, g, b)
    return format(
        "|cff%02x%02x%02x",
        floor((r or 1) * 255 + 0.5),
        floor((g or 1) * 255 + 0.5),
        floor((b or 1) * 255 + 0.5)
    )
end

local raidIconFunc = function(x)
    x = x ~= "" and _G["RAID_TARGET_" .. x]
    return x and ("{" .. strlower(x) .. "}") or ""
end

local function ResolveBNetTags(text)
    local api = C_BattleNet and C_BattleNet.GetAccountInfoByID
    if not api then return text end

    return (gsub(text, "|HBNplayer:.-:(%d+):.-|h(%b[])|h", function(bnID)
        local id = tonumber(bnID)
        if not id then return nil end
        local ok, info = pcall(api, id)
        if not ok or type(info) ~= "table" then return nil end
        local tag = info.battleTag
        if type(tag) ~= "string" or tag == "" or tag:sub(1, 2) == "|K" then return nil end
        local hash = tag:find("#", 1, true)
        local name = hash and tag:sub(1, hash - 1) or tag
        if name ~= "" then return format("[%s]", name) end
        return nil
    end))
end

function Copy:CleanMessage(message, colorPrefix)
    if message == nil or IsSecret(message) or type(message) ~= "string" then return "" end

    local out = ResolveBNetTags(message)
    out = gsub(out, "%f[|]|K.-%f[|]|k", "???")
    out = gsub(out, "%f[|]|W(.-)%f[|]|w", "%1")
    out = gsub(out, "|TInterface\\TargetingFrame\\UI%-RaidTargetingIcon_(%d+):[^|]*|t", raidIconFunc)
    out = gsub(out, "|T[^|]*|t", "")
    out = gsub(out, "|A[^|]*|a", "")
    out = gsub(out, "|H[^|]*|h(%[.-%])|h", "%1")
    out = gsub(out, "|H[^|]*|h(.-)|h", "%1")
    out = gsub(out, "|n", "\n")

    if out ~= "" and colorPrefix then
        out = colorPrefix .. out .. "|r"
    end
    return out
end

function Copy:GetLines(chatFrame)
    wipe(copyLines)
    if not chatFrame or type(chatFrame.GetNumMessages) ~= "function" then return 0 end

    local okCount, total = pcall(chatFrame.GetNumMessages, chatFrame)
    if not okCount or type(total) ~= "number" or IsSecret(total) then return 0 end

    local maxLines = tonumber(DB().copy and DB().copy.maxLines) or 500
    if maxLines < 10 then maxLines = 10 end
    if maxLines > 1000 then maxLines = 1000 end
    local first = total <= maxLines and 1 or (total + 1 - maxLines)
    local index = 0

    for i = first, total do
        local ok, message, r, g, b = pcall(chatFrame.GetMessageInfo, chatFrame, i)
        if ok then
            local prefix
            if IsSecret(r) or IsSecret(g) or IsSecret(b) then
                prefix = nil
            elseif type(r) == "number" and type(g) == "number" and type(b) == "number"
                and not (r >= 1 and g >= 1 and b >= 1) then
                prefix = RGBToHex(r, g, b)
            end

            local cleaned = self:CleanMessage(message, prefix)
            if cleaned ~= "" then
                index = index + 1
                copyLines[index] = cleaned
            end
        end
    end

    return index
end

local function BuildURLPopup()
    if urlPopup then return urlPopup end

    local r, g, b = Accent()
    local frame = CreateFrame("Frame", "TomoMod_ChatV4URLPopup", UIParent)
    frame:SetSize(420, 92)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    ApplySurface(frame, THEME.bg, { r, g, b, 1 }, 2)

    if U and U.CloseOnEscape then U.CloseOnEscape(frame) end

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(ADDON_FONT_BOLD, 13, "")
    title:SetPoint("TOP", 0, -12)
    title:SetText(Loc("chat_copy_url_title", "Press Ctrl+C to copy"))
    title:SetTextColor(r, g, b, 1)

    local editBg = CreateFrame("Frame", nil, frame)
    editBg:SetPoint("LEFT", 16, 0)
    editBg:SetPoint("RIGHT", -16, 0)
    editBg:SetHeight(26)
    editBg:SetPoint("CENTER", 0, -8)
    ApplySurface(editBg, THEME.bgDark, THEME.border, 1)

    local edit = CreateFrame("EditBox", nil, editBg)
    edit:SetPoint("LEFT", 8, 0)
    edit:SetPoint("RIGHT", -8, 0)
    edit:SetHeight(22)
    edit:SetAutoFocus(true)
    edit:SetFont(COPY_FONT, 13, "")
    edit:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], 1)
    edit:SetScript("OnEscapePressed", function() frame:Hide() end)
    edit:SetScript("OnEnterPressed", function() frame:Hide() end)
    frame.editBox = edit

    local close = CreateFlatButton(frame, "x", 22, 22, function() frame:Hide() end, false)
    close:SetPoint("TOPRIGHT", -6, -6)

    urlPopup = frame
    return frame
end

function Copy:ShowURLPopup(url)
    if type(url) ~= "string" or url == "" then return end
    local frame = BuildURLPopup()
    frame.editBox:SetText(url)
    frame:Show()
    frame.editBox:SetFocus()
    frame.editBox:HighlightText()
end

local function StyleMinimalScrollBar(bar)
    if not bar then return end
    local r, g, b = Accent()

    local back = bar.GetBackStepper and bar:GetBackStepper()
    local forward = bar.GetForwardStepper and bar:GetForwardStepper()
    if back then back:SetAlpha(0) end
    if forward then forward:SetAlpha(0) end

    local function HideAtlas(region)
        for _, key in ipairs({ "Begin", "Middle", "End" }) do
            local sub = region and region[key]
            if sub and sub.SetAlpha then sub:SetAlpha(0) end
        end
    end

    local track = (bar.GetTrack and bar:GetTrack()) or bar.Track
    if track then
        HideAtlas(track)
        if not track._tmFill then
            local texture = track:CreateTexture(nil, "BACKGROUND")
            texture:SetAllPoints(track)
            track._tmFill = texture
        end
        track._tmFill:SetColorTexture(1, 1, 1, 0.08)
    end

    local thumb = bar.GetThumb and bar:GetThumb()
    if thumb then
        HideAtlas(thumb)
        if not thumb._tmFill then
            local texture = thumb:CreateTexture(nil, "ARTWORK")
            texture:SetAllPoints(thumb)
            thumb._tmFill = texture
        end
        thumb._tmFill:SetColorTexture(r, g, b, 0.9)
    end
end

local function CopyFontSize()
    local appearance = DB().appearance or {}
    return tonumber(appearance.fontSize) or 13
end

local function AttachScrollingEditBox(frame, parent)
    local ok, scrolling = pcall(
        CreateFrame,
        "Frame",
        "TomoMod_ChatV4CopyScrollingEditBox",
        parent,
        "ScrollingEditBoxTemplate"
    )
    if not ok or not scrolling or not scrolling.GetEditBox then return false end

    scrolling:SetPoint("TOPLEFT", 8, -8)
    scrolling:SetPoint("BOTTOMRIGHT", -8, 8)

    local edit = scrolling:GetEditBox()
    edit:SetAutoFocus(false)
    edit:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], 1)
    edit:SetScript("OnEscapePressed", function() frame:Hide() end)
    if scrolling.SetFontObject then
        pcall(scrolling.SetFontObject, scrolling, "ChatFontNormal")
    end
    pcall(edit.SetFont, edit, COPY_FONT, CopyFontSize(), "")

    if ScrollUtil and ScrollUtil.RegisterScrollBoxWithScrollBar then
        local bar = CreateFrame("EventFrame", nil, scrolling, "MinimalScrollBar")
        bar:SetPoint("TOPRIGHT", scrolling, "TOPRIGHT", -1, -2)
        bar:SetPoint("BOTTOMRIGHT", scrolling, "BOTTOMRIGHT", -1, 2)
        local box = scrolling:GetScrollBox()
        ScrollUtil.RegisterScrollBoxWithScrollBar(box, bar)
        if ScrollUtil.AddManagedScrollBarVisibilityBehavior and CreateAnchor then
            ScrollUtil.AddManagedScrollBarVisibilityBehavior(box, bar, {
                CreateAnchor("TOPLEFT", scrolling, "TOPLEFT", 0, 0),
                CreateAnchor("BOTTOMRIGHT", scrolling, "BOTTOMRIGHT", -16, 0),
            }, {
                CreateAnchor("TOPLEFT", scrolling, "TOPLEFT", 0, 0),
                CreateAnchor("BOTTOMRIGHT", scrolling, "BOTTOMRIGHT", 0, 0),
            })
        end
        StyleMinimalScrollBar(bar)
        frame.scrollBar = bar
    end

    frame.scrollingEditBox = scrolling
    frame.editBox = edit
    frame.SetCopyText = function(_, text) scrolling:SetText(text) end
    frame.HighlightAll = function()
        edit:SetFocus()
        edit:HighlightText()
    end
    frame.ScrollToEnd = function()
        local box = scrolling.GetScrollBox and scrolling:GetScrollBox()
        if box and box.ScrollToEnd then box:ScrollToEnd() end
    end
    return true
end

local function AttachLegacyEditBox(frame, parent)
    local scroll = CreateFrame("ScrollFrame", "TomoMod_ChatV4CopyScrollFrame", parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -26, 8)

    local edit = CreateFrame("EditBox", "TomoMod_ChatV4CopyEditBox", scroll)
    edit:SetMultiLine(true)
    edit:SetMaxLetters(0)
    edit:SetAutoFocus(false)
    edit:EnableMouse(true)
    edit:SetFontObject("ChatFontNormal")
    edit:SetFont(COPY_FONT, CopyFontSize(), "")
    edit:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], 1)
    edit:SetScript("OnEscapePressed", function() frame:Hide() end)
    scroll:SetScrollChild(edit)
    scroll:SetScript("OnSizeChanged", function(_, w, h) edit:SetSize(w, h) end)
    edit:SetSize(scroll:GetWidth(), scroll:GetHeight())

    frame.scrollFrame = scroll
    frame.editBox = edit
    frame.SetCopyText = function(_, text) edit:SetText(text) end
    frame.HighlightAll = function()
        edit:SetFocus()
        edit:HighlightText()
    end
    frame.ScrollToEnd = function()
        local bar = scroll.ScrollBar
        if bar then
            local _, maximum = bar:GetMinMaxValues()
            bar:SetValue(maximum or 0)
        end
    end
    return true
end

local function BuildCopyFrame()
    if copyFrame then return copyFrame end

    local r, g, b = Accent()
    local frame = CreateFrame("Frame", "TomoMod_ChatV4CopyFrame", UIParent)
    frame:SetSize(700, 360)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(380, 200, 1400, 900)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnHide", function(self) self:StopMovingOrSizing() end)
    frame:Hide()
    ApplySurface(frame, THEME.bg, { r, g, b, 1 }, 2)

    if U and U.CloseOnEscape then U.CloseOnEscape(frame) end

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(ADDON_FONT_BOLD, 14, "")
    title:SetPoint("TOP", 0, -10)
    title:SetText(Loc("chat_copy_title", "Copy Chat Text"))
    title:SetTextColor(r, g, b, 1)

    local hint = frame:CreateFontString(nil, "OVERLAY")
    hint:SetFont(ADDON_FONT, 11, "")
    hint:SetPoint("TOP", title, "BOTTOM", 0, -4)
    hint:SetText(Loc("chat_copy_hint", "Select all (Ctrl+A) then copy (Ctrl+C)"))
    hint:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 1)

    local editBg = CreateFrame("Frame", nil, frame)
    editBg:SetPoint("TOPLEFT", 12, -54)
    editBg:SetPoint("BOTTOMRIGHT", -12, 42)
    ApplySurface(editBg, THEME.bgDark, THEME.border, 1)
    frame.editBg = editBg

    if not AttachScrollingEditBox(frame, editBg) then
        AttachLegacyEditBox(frame, editBg)
    end

    local close = CreateFlatButton(frame, "x", 22, 22, function() frame:Hide() end, false)
    close:SetPoint("TOPRIGHT", -6, -6)

    local selectAll = CreateFlatButton(
        frame,
        Loc("chat_copy_select_all", "Select All"),
        100,
        22,
        function() frame.HighlightAll() end,
        true
    )
    selectAll:SetPoint("BOTTOMLEFT", 12, 10)

    local closeBottom = CreateFlatButton(
        frame,
        Loc("chat_copy_close", "Close"),
        80,
        22,
        function() frame:Hide() end,
        false
    )
    closeBottom:SetPoint("BOTTOMRIGHT", -30, 10)

    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -4, 4)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    for i, texture in ipairs({ grip:GetNormalTexture(), grip:GetHighlightTexture(), grip:GetPushedTexture() }) do
        if texture then
            if texture.SetDesaturated then texture:SetDesaturated(true) end
            texture:SetVertexColor(r, g, b, i == 2 and 0.9 or 0.55)
        end
    end
    grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)

    copyFrame = frame
    Copy.frame = frame
    Copy.edit = frame.editBox
    return frame
end

function Copy:Show(chatFrame)
    local frame = BuildCopyFrame()
    chatFrame = chatFrame
        or (Chat.Modules.Renderer and Chat.Modules.Renderer:GetSelectedFrame())
        or _G.ChatFrame1

    local count = self:GetLines(chatFrame)
    local text = count > 0 and tconcat(copyLines, "\n", 1, count)
        or Loc("chat_copy_empty", "No copyable messages in this window.")

    frame:SetCopyText(text)
    frame:Show()

    if #text <= AUTO_HIGHLIGHT_MAX then
        frame.HighlightAll()
    elseif frame.editBox then
        frame.editBox:SetFocus()
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if frame:IsShown() and frame.ScrollToEnd then frame.ScrollToEnd() end
        end)
    end
end

function Copy:Hide()
    if copyFrame and copyFrame:IsShown() then copyFrame:Hide() end
end

function Copy:Toggle(chatFrame)
    if copyFrame and copyFrame:IsShown() then
        self:Hide()
    else
        self:Show(chatFrame)
    end
end

function Copy:Initialize()
    BuildCopyFrame()
end

function Copy:ApplySettings(enabled)
    if copyFrame and copyFrame.editBox then
        pcall(copyFrame.editBox.SetFont, copyFrame.editBox, COPY_FONT, CopyFontSize(), "")
    end
    if not enabled then self:Hide() end
end

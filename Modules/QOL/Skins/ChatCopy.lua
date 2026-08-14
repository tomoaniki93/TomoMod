-- =====================================
-- ChatCopy.lua
-- Chat copy system for TomoMod - ported from TUI (TUI_Chat/chat/copy.lua)
-- ---------------------------------------------------------------------
-- Replaces the previous ScrollFrame + plain EditBox window with the TUI
-- presentation layer:
--   * ScrollingEditBoxTemplate + MinimalScrollBar (legacy fallback kept)
--   * brand-accented flat surface, Select All / Close, resize grip
--   * auto highlight + scroll-to-end on open
--   * per-window copy button with always / hover / hidden modes
--   * themed URL popup replacing the StaticPopup dialog
--
-- The line source stays TomoMod's: Blizzard's GetMessageInfo() on the live
-- chat frame. TUI reads its own MessageStore, which TomoMod does not have,
-- so only the presentation and the message cleaner are ported.
--
-- Compatible with WoW 12.x (TWW / Midnight)
-- =====================================

TomoMod_ChatCopy = TomoMod_ChatCopy or {}
local Copy = TomoMod_ChatCopy

local U = TomoMod_Utils
local L = TomoMod_L

local format, gsub, strlower = string.format, string.gsub, string.lower
local tconcat, tinsert, wipe = table.concat, table.insert, wipe
local floor, min = math.floor, math.min
local issecretvalue = issecretvalue

-- =====================================
-- CONSTANTS
-- =====================================

-- The old window capped extraction at 128 lines. Blizzard keeps up to 1000
-- per frame and the ScrollingEditBox handles far more text than the legacy
-- EditBox did, so the cap is raised -- still bounded, because concatenating
-- an unbounded buffer on click is a visible hitch.
local COPY_MAX_MESSAGES      = 500
local AUTO_HIGHLIGHT_MAX     = 8000   -- chars; above this, skip auto-highlight
local COPY_BUTTON_SIZE       = 20
local COPY_BUTTON_LEVEL      = 100
local COPY_HOVER_POLL        = 0.1    -- seconds between hover polls
local GLYPH_STROKE           = 2

local urlPopup, copyFrame
local copyLines = {}

-- =====================================
-- SETTINGS / THEME
-- =====================================

local function S()
    return TomoModDB and TomoModDB.chatFrameSkin or {}
end

local function Accent()
    local b = U and U.BRAND
    if b then return b[1], b[2], b[3] end
    return 0.180, 0.847, 0.518
end

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
-- ARIALN ships with the client and covers Cyrillic; Poppins does not, and the
-- copy window has to render whatever the chat rendered.
local COPY_FONT = UNIT_NAME_FONT or "Fonts\\ARIALN.TTF"

local function Loc(key, fallback)
    local s = L and L[key]
    -- The locale metatable hands back the raw key when it is undefined, so a
    -- plain `L[key] or fallback` never fires. Compare against the key instead.
    if type(s) == "string" and s ~= "" and s ~= key then return s end
    return fallback
end

-- =====================================
-- FLAT SURFACE HELPERS
-- =====================================

local function Fill(tex, c, alphaOverride)
    if not (tex and c) then return end
    tex:SetColorTexture(c[1] or 1, c[2] or 1, c[3] or 1, alphaOverride or c[4] or 1)
end

-- Flat 1-2px line border + solid fill, matching the TUI surface treatment.
-- Deliberately not a Backdrop: BackdropTemplate edge files scale badly at the
-- sizes used here and the tooltip border does not take a brand tint cleanly.
local function ApplySurface(frame, bg, border, thickness)
    thickness = thickness or 1

    if not frame._tmBG then
        frame._tmBG = frame:CreateTexture(nil, "BACKGROUND")
        frame._tmBG:SetAllPoints(frame)
    end
    Fill(frame._tmBG, bg)

    if not frame._tmEdges then
        local e = {}
        for _, key in ipairs({ "top", "bottom", "left", "right" }) do
            e[key] = frame:CreateTexture(nil, "BORDER")
        end
        e.top:SetPoint("TOPLEFT")
        e.top:SetPoint("TOPRIGHT")
        e.bottom:SetPoint("BOTTOMLEFT")
        e.bottom:SetPoint("BOTTOMRIGHT")
        e.left:SetPoint("TOPLEFT")
        e.left:SetPoint("BOTTOMLEFT")
        e.right:SetPoint("TOPRIGHT")
        e.right:SetPoint("BOTTOMRIGHT")
        frame._tmEdges = e
    end

    local e = frame._tmEdges
    e.top:SetHeight(thickness)
    e.bottom:SetHeight(thickness)
    e.left:SetWidth(thickness)
    e.right:SetWidth(thickness)
    for _, tex in pairs(e) do Fill(tex, border) end
end

-- =====================================
-- BUTTONS
-- =====================================

local function CreateFlatButton(parent, text, width, height, onClick, primary)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, height)

    local r, g, b = Accent()
    ApplySurface(btn, { 1, 1, 1, 0.04 },
        primary and { r, g, b, 0.55 } or { 1, 1, 1, 0.20 }, 1)

    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFont(ADDON_FONT, 12, "")
    fs:SetPoint("CENTER")
    fs:SetText(text)
    if primary then
        fs:SetTextColor(r, g, b, 1)
    else
        fs:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 1)
    end
    btn.text = fs

    btn:SetScript("OnEnter", function(self)
        Fill(self._tmBG, { r, g, b, 0.18 })
        self.text:SetTextColor(1, 1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        Fill(self._tmBG, { 1, 1, 1, 0.04 })
        if primary then
            self.text:SetTextColor(r, g, b, 1)
        else
            self.text:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 1)
        end
    end)
    btn:SetScript("OnClick", onClick)

    return btn
end

-- Vector copy glyph (two offset rectangles). Drawn rather than textured so it
-- inherits the brand accent and never depends on a .tga that can fail to
-- resolve -- the reason the old per-line copy icon had to be removed.
local function AddGlyphLine(parent)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture("Interface\\Buttons\\WHITE8x8")
    return t
end

local function BuildGlyph(button)
    if button._glyph then return end

    local parts = {}

    local back = CreateFrame("Frame", nil, button)
    back:SetSize(9, 11)
    back:SetPoint("CENTER", -2, 2)
    parts.backTop    = AddGlyphLine(back)
    parts.backBottom = AddGlyphLine(back)
    parts.backLeft   = AddGlyphLine(back)
    parts.backRight  = AddGlyphLine(back)
    parts.backTop:SetPoint("TOPLEFT")
    parts.backTop:SetPoint("TOPRIGHT")
    parts.backTop:SetHeight(GLYPH_STROKE)
    parts.backBottom:SetPoint("BOTTOMLEFT")
    parts.backBottom:SetPoint("BOTTOMRIGHT")
    parts.backBottom:SetHeight(GLYPH_STROKE)
    parts.backLeft:SetPoint("TOPLEFT")
    parts.backLeft:SetPoint("BOTTOMLEFT")
    parts.backLeft:SetWidth(GLYPH_STROKE)
    parts.backRight:SetPoint("TOPRIGHT")
    parts.backRight:SetPoint("BOTTOMRIGHT")
    parts.backRight:SetWidth(GLYPH_STROKE)

    local front = CreateFrame("Frame", nil, button)
    front:SetSize(11, 13)
    front:SetPoint("CENTER", 2, -2)
    parts.frontTop    = AddGlyphLine(front)
    parts.frontBottom = AddGlyphLine(front)
    parts.frontLeft   = AddGlyphLine(front)
    parts.frontRight  = AddGlyphLine(front)
    parts.frontTop:SetPoint("TOPLEFT")
    parts.frontTop:SetPoint("TOPRIGHT", -4, 0)
    parts.frontTop:SetHeight(GLYPH_STROKE)
    parts.frontBottom:SetPoint("BOTTOMLEFT")
    parts.frontBottom:SetPoint("BOTTOMRIGHT")
    parts.frontBottom:SetHeight(GLYPH_STROKE)
    parts.frontLeft:SetPoint("TOPLEFT")
    parts.frontLeft:SetPoint("BOTTOMLEFT")
    parts.frontLeft:SetWidth(GLYPH_STROKE)
    parts.frontRight:SetPoint("TOPRIGHT", 0, -4)
    parts.frontRight:SetPoint("BOTTOMRIGHT")
    parts.frontRight:SetWidth(GLYPH_STROKE)
    parts.foldA = AddGlyphLine(front)
    parts.foldB = AddGlyphLine(front)
    parts.foldA:SetPoint("TOPRIGHT", 0, -4)
    parts.foldA:SetSize(4, GLYPH_STROKE)
    parts.foldB:SetPoint("TOPRIGHT", -4, 0)
    parts.foldB:SetSize(GLYPH_STROKE, 4)

    button._glyph = parts
end

local function RefreshGlyph(button, hovered)
    if not button then return end
    BuildGlyph(button)

    local r, g, b = Accent()
    if button._hoverBG then
        if hovered then
            button._hoverBG:SetColorTexture(r, g, b, 0.18)
            button._hoverBG:Show()
        else
            button._hoverBG:Hide()
        end
    end

    for key, part in pairs(button._glyph) do
        if key:find("^back") then
            part:SetColorTexture(THEME.text[1], THEME.text[2], THEME.text[3], hovered and 0.72 or 0.55)
        else
            part:SetColorTexture(r, g, b, hovered and 1 or 0.95)
        end
    end
end

-- =====================================
-- MESSAGE CLEANING
-- =====================================

local function RGBToHex(r, g, b)
    return format("|cff%02x%02x%02x", floor((r or 1) * 255 + 0.5),
        floor((g or 1) * 255 + 0.5), floor((b or 1) * 255 + 0.5))
end

local raidIconFunc = function(x)
    x = x ~= "" and _G["RAID_TARGET_" .. x]
    return x and ("{" .. strlower(x) .. "}") or ""
end

-- Resolve a BNet tag reference to its account name. The old cleaner treated
-- every |K...|k message as protected and dropped it outright, which silently
-- excluded *all* BNet whispers from the copy window. TUI resolves the tag
-- instead, so real conversations survive the round trip.
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

function Copy.CleanMessage(message, colorPrefix)
    -- Secret values must never reach a gsub, a comparison or a concat.
    if message == nil then return "" end
    if issecretvalue and issecretvalue(message) then return "" end
    if type(message) ~= "string" then return "" end

    local out = ResolveBNetTags(message)

    -- Any |K tag that survived resolution stays masked: those carry data the
    -- client refuses to expose in plain text.
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

-- Pull the visible backlog out of a live chat frame.
function Copy.GetLines(chatFrame)
    wipe(copyLines)
    if not (chatFrame and chatFrame.GetNumMessages) then return 0 end

    local total = chatFrame:GetNumMessages() or 0
    local first = total <= COPY_MAX_MESSAGES and 1 or (total + 1 - COPY_MAX_MESSAGES)
    local index = 0

    for i = first, total do
        local message, r, g, b = chatFrame:GetMessageInfo(i)
        local prefix
        if issecretvalue and (issecretvalue(r) or issecretvalue(g) or issecretvalue(b)) then
            prefix = nil
        elseif type(r) == "number" and type(g) == "number" and type(b) == "number"
            and not (r >= 1 and g >= 1 and b >= 1) then
            prefix = RGBToHex(r, g, b)
        end

        local cleaned = Copy.CleanMessage(message, prefix)
        if cleaned ~= "" then
            index = index + 1
            copyLines[index] = cleaned
        end
    end

    return index
end

-- =====================================
-- URL POPUP
-- =====================================

local function BuildURLPopup()
    if urlPopup then return urlPopup end

    local r, g, b = Accent()
    local f = CreateFrame("Frame", "TomoModChatURLPopup", UIParent)
    f:SetSize(420, 92)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    ApplySurface(f, THEME.bg, { r, g, b, 1 }, 2)

    -- Escape is handled by the frame itself. Registering in UISpecialFrames
    -- routes it through ToggleGameMenu, whose protected calls get refused once
    -- the path is tainted -- and the player can no longer log out.
    if U and U.CloseOnEscape then U.CloseOnEscape(f) end

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(ADDON_FONT_BOLD, 13, "")
    title:SetPoint("TOP", 0, -12)
    title:SetText(Loc("chat_copy_url_title", "Press Ctrl+C to copy"))
    title:SetTextColor(r, g, b, 1)

    local editBg = CreateFrame("Frame", nil, f)
    editBg:SetPoint("LEFT", 16, 0)
    editBg:SetPoint("RIGHT", -16, 0)
    editBg:SetHeight(26)
    editBg:SetPoint("CENTER", 0, -8)
    ApplySurface(editBg, THEME.bgDark, THEME.border, 1)

    local eb = CreateFrame("EditBox", nil, editBg)
    eb:SetPoint("LEFT", 8, 0)
    eb:SetPoint("RIGHT", -8, 0)
    eb:SetHeight(22)
    eb:SetAutoFocus(true)
    eb:SetFont(COPY_FONT, 13, "")
    eb:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], 1)
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    eb:SetScript("OnEnterPressed", function() f:Hide() end)
    f.editBox = eb

    local close = CreateFlatButton(f, "x", 22, 22, function() f:Hide() end, false)
    close:SetPoint("TOPRIGHT", -6, -6)

    urlPopup = f
    return f
end

function Copy.ShowURLPopup(url)
    if type(url) ~= "string" or url == "" then return end
    local f = BuildURLPopup()
    f.editBox:SetText(url)
    f:Show()
    f.editBox:SetFocus()
    f.editBox:HighlightText()
end

-- =====================================
-- COPY WINDOW
-- =====================================

local function StyleMinimalScrollBar(bar)
    if not bar then return end
    local r, g, b = Accent()

    local back = bar.GetBackStepper and bar:GetBackStepper()
    local fwd  = bar.GetForwardStepper and bar:GetForwardStepper()
    if back then back:SetAlpha(0) end
    if fwd then fwd:SetAlpha(0) end

    local function hideAtlas(region)
        for _, key in ipairs({ "Begin", "Middle", "End" }) do
            local sub = region and region[key]
            if sub and sub.SetAlpha then sub:SetAlpha(0) end
        end
    end

    local track = (bar.GetTrack and bar:GetTrack()) or bar.Track
    if track then
        hideAtlas(track)
        if not track._tmFill then
            local t = track:CreateTexture(nil, "BACKGROUND")
            t:SetAllPoints(track)
            track._tmFill = t
        end
        track._tmFill:SetColorTexture(1, 1, 1, 0.08)
    end

    local thumb = bar.GetThumb and bar:GetThumb()
    if thumb then
        hideAtlas(thumb)
        if not thumb._tmFill then
            local t = thumb:CreateTexture(nil, "ARTWORK")
            t:SetAllPoints(thumb)
            thumb._tmFill = t
        end
        thumb._tmFill:SetColorTexture(r, g, b, 0.9)
    end
end

-- Modern path: ScrollingEditBoxTemplate + MinimalScrollBar.
local function AttachScrollingEditBox(frame, parent)
    local ok, seb = pcall(CreateFrame, "Frame", "TomoModCopyChatScrollingEditBox",
        parent, "ScrollingEditBoxTemplate")
    if not ok or not seb or not seb.GetEditBox then return false end

    seb:SetPoint("TOPLEFT", 8, -8)
    seb:SetPoint("BOTTOMRIGHT", -8, 8)

    local eb = seb:GetEditBox()
    eb:SetAutoFocus(false)
    eb:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], 1)
    eb:SetScript("OnEscapePressed", function() frame:Hide() end)

    if seb.SetFontObject then
        pcall(seb.SetFontObject, seb, "ChatFontNormal")
    end
    pcall(eb.SetFont, eb, COPY_FONT, tonumber(S().fontSize) or 13, "")

    if _G.ScrollUtil and _G.ScrollUtil.RegisterScrollBoxWithScrollBar then
        local bar = CreateFrame("EventFrame", nil, seb, "MinimalScrollBar")
        bar:SetPoint("TOPRIGHT", seb, "TOPRIGHT", -1, -2)
        bar:SetPoint("BOTTOMRIGHT", seb, "BOTTOMRIGHT", -1, 2)
        local box = seb:GetScrollBox()
        _G.ScrollUtil.RegisterScrollBoxWithScrollBar(box, bar)
        if _G.ScrollUtil.AddManagedScrollBarVisibilityBehavior and _G.CreateAnchor then
            _G.ScrollUtil.AddManagedScrollBarVisibilityBehavior(box, bar, {
                _G.CreateAnchor("TOPLEFT", seb, "TOPLEFT", 0, 0),
                _G.CreateAnchor("BOTTOMRIGHT", seb, "BOTTOMRIGHT", -16, 0),
            }, {
                _G.CreateAnchor("TOPLEFT", seb, "TOPLEFT", 0, 0),
                _G.CreateAnchor("BOTTOMRIGHT", seb, "BOTTOMRIGHT", 0, 0),
            })
        end
        StyleMinimalScrollBar(bar)
        frame.scrollBar = bar
    end

    frame.scrollingEditBox = seb
    frame.editBox = eb

    frame.SetCopyText = function(_, text)
        seb:SetText(text)
    end
    frame.HighlightAll = function()
        eb:SetFocus()
        eb:HighlightText()
    end
    frame.ScrollToEnd = function()
        local box = seb.GetScrollBox and seb:GetScrollBox()
        if box and box.ScrollToEnd then box:ScrollToEnd() end
    end

    return true
end

-- Fallback for any build where ScrollingEditBoxTemplate is unavailable.
local function AttachLegacyEditBox(frame, parent)
    local sf = CreateFrame("ScrollFrame", "TomoModCopyChatScrollFrame", parent,
        "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 8, -8)
    sf:SetPoint("BOTTOMRIGHT", -26, 8)

    local eb = CreateFrame("EditBox", "TomoModCopyChatEditBox", sf)
    eb:SetMultiLine(true)
    eb:SetMaxLetters(0)
    eb:SetAutoFocus(false)
    eb:EnableMouse(true)
    eb:SetFontObject("ChatFontNormal")
    eb:SetFont(COPY_FONT, tonumber(S().fontSize) or 13, "")
    eb:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], 1)
    eb:SetScript("OnEscapePressed", function() frame:Hide() end)
    sf:SetScrollChild(eb)
    sf:SetScript("OnSizeChanged", function(_, w, h) eb:SetSize(w, h) end)
    eb:SetSize(sf:GetWidth(), sf:GetHeight())

    frame.scrollFrame = sf
    frame.editBox = eb

    frame.SetCopyText  = function(_, text) eb:SetText(text) end
    frame.HighlightAll = function() eb:SetFocus(); eb:HighlightText() end
    frame.ScrollToEnd  = function()
        local bar = sf.ScrollBar
        if bar then
            local _, maxValue = bar:GetMinMaxValues()
            bar:SetValue(maxValue or 0)
        end
    end

    return true
end

local function BuildCopyFrame()
    if copyFrame then return copyFrame end

    local r, g, b = Accent()
    local f = CreateFrame("Frame", "TomoModCopyChatFrame", UIParent)
    f:SetSize(700, 360)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetResizeBounds(380, 200, 1400, 900)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnHide", function(self) self:StopMovingOrSizing() end)
    f:Hide()
    ApplySurface(f, THEME.bg, { r, g, b, 1 }, 2)

    if U and U.CloseOnEscape then U.CloseOnEscape(f) end

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(ADDON_FONT_BOLD, 14, "")
    title:SetPoint("TOP", 0, -10)
    title:SetText(Loc("chat_copy_title", "Copy Chat Text"))
    title:SetTextColor(r, g, b, 1)

    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont(ADDON_FONT, 11, "")
    hint:SetPoint("TOP", title, "BOTTOM", 0, -4)
    hint:SetText(Loc("chat_copy_hint", "Select all (Ctrl+A) then copy (Ctrl+C)"))
    hint:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 1)

    local editBg = CreateFrame("Frame", nil, f)
    editBg:SetPoint("TOPLEFT", 12, -54)
    editBg:SetPoint("BOTTOMRIGHT", -12, 42)
    ApplySurface(editBg, THEME.bgDark, THEME.border, 1)
    f.editBg = editBg

    if not AttachScrollingEditBox(f, editBg) then
        AttachLegacyEditBox(f, editBg)
    end

    local close = CreateFlatButton(f, "x", 22, 22, function() f:Hide() end, false)
    close:SetPoint("TOPRIGHT", -6, -6)

    local selectAll = CreateFlatButton(f, Loc("chat_copy_select_all", "Select All"), 100, 22,
        function() f.HighlightAll() end, true)
    selectAll:SetPoint("BOTTOMLEFT", 12, 10)

    local closeBottom = CreateFlatButton(f, Loc("chat_copy_close", "Close"), 80, 22,
        function() f:Hide() end, false)
    closeBottom:SetPoint("BOTTOMRIGHT", -30, 10)

    local grip = CreateFrame("Button", nil, f)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -4, 4)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    for i, tex in ipairs({ grip:GetNormalTexture(), grip:GetHighlightTexture(), grip:GetPushedTexture() }) do
        if tex then
            if tex.SetDesaturated then tex:SetDesaturated(true) end
            tex:SetVertexColor(r, g, b, (i == 2) and 0.9 or 0.55)
        end
    end
    grip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() f:StopMovingOrSizing() end)

    copyFrame = f
    return f
end

function Copy.Show(chatFrame)
    local f = BuildCopyFrame()
    local count = Copy.GetLines(chatFrame or _G.ChatFrame1)
    local text = count > 0 and tconcat(copyLines, "\n", 1, count)
        or Loc("chat_copy_empty", "No copyable messages in this window.")

    f:SetCopyText(text)
    f:Show()

    if #text <= AUTO_HIGHLIGHT_MAX then
        f.HighlightAll()
    elseif f.editBox then
        f.editBox:SetFocus()
    end

    -- The scroll box only knows its extent once the text has laid out.
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if f:IsShown() and f.ScrollToEnd then f.ScrollToEnd() end
        end)
    end
end

function Copy.Hide()
    if copyFrame and copyFrame:IsShown() then copyFrame:Hide() end
end

function Copy.Toggle(chatFrame)
    if copyFrame and copyFrame:IsShown() then
        Copy.Hide()
    else
        Copy.Show(chatFrame)
    end
end

-- =====================================
-- PER-WINDOW COPY BUTTON
-- =====================================

function Copy.ButtonMode()
    local mode = S().copyButtonMode
    if mode == "always" or mode == "hover" or mode == "hidden" then return mode end
    return "hover"
end

local function ApplyButtonMode(chatFrame, button)
    local mode = Copy.ButtonMode()

    if mode == "hidden" then
        button:Hide()
        chatFrame:SetScript("OnUpdate", chatFrame._tmPrevOnUpdate)
        return
    end

    if mode == "always" then
        button:Show()
        button:SetAlpha(0.35)
        chatFrame:SetScript("OnUpdate", chatFrame._tmPrevOnUpdate)
        return
    end

    -- Hover: poll rather than OnEnter/OnLeave. The chat frame is covered by
    -- the message area and the skin container, so enter/leave never fire
    -- reliably on the frame itself.
    button:Hide()
    button:SetAlpha(1)
    chatFrame._tmHovered = false
    chatFrame._tmPoll = 0
    chatFrame:SetScript("OnUpdate", function(self, elapsed)
        self._tmPoll = (self._tmPoll or 0) + (elapsed or COPY_HOVER_POLL)
        if self._tmPoll < COPY_HOVER_POLL then return end
        self._tmPoll = 0
        local over = (self.IsMouseOver and self:IsMouseOver()) or false
        if over ~= self._tmHovered then
            self._tmHovered = over
            button:SetShown(over)
        end
    end)
end

local function CreateChatFrameButton(chatFrame)
    local btn = CreateFrame("Button", nil, chatFrame)
    btn:SetSize(COPY_BUTTON_SIZE, COPY_BUTTON_SIZE)
    btn:SetPoint("TOPRIGHT", chatFrame, "TOPRIGHT", -2, 2)
    btn:SetFrameLevel(COPY_BUTTON_LEVEL)
    btn:EnableMouse(true)

    btn._hoverBG = btn:CreateTexture(nil, "BACKGROUND")
    btn._hoverBG:SetAllPoints(btn)
    btn._hoverBG:Hide()
    RefreshGlyph(btn, false)

    btn:SetScript("OnEnter", function(self)
        RefreshGlyph(self, true)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(Loc("chat_copy_title", "Copy Chat Text"))
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        RefreshGlyph(self, false)
        GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", function(self)
        Copy.Toggle(self:GetParent())
    end)

    return btn
end

-- Called by ChatFrameSkin on init and on every settings change.
function Copy.ApplyButtons(frameNames)
    if type(frameNames) ~= "table" then return end
    local mode = Copy.ButtonMode()

    for _, name in ipairs(frameNames) do
        local chatFrame = _G[name]
        if chatFrame then
            local btn = chatFrame.copyButton
            if not btn and mode ~= "hidden" then
                btn = CreateChatFrameButton(chatFrame)
                chatFrame.copyButton = btn
            end
            if btn then ApplyButtonMode(chatFrame, btn) end
        end
    end
end

-- Re-tint everything after a theme or font change.
function Copy.ApplySettings()
    if copyFrame and copyFrame.editBox then
        pcall(copyFrame.editBox.SetFont, copyFrame.editBox, COPY_FONT,
            tonumber(S().fontSize) or 13, "")
    end
end

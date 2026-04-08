-- =====================================
-- ChatFrameSkinV2.lua -- Complete Rewrite (v2.8)
-- Tabbed chat panel for TomoMod -- WoW 12.x Midnight compatible
--
-- Architecture (based on MidnightUI messenger.lua patterns):
--   * Persistent message history in TomoModDB.chatFrameSkinV2.history
--   * Single ScrollingMessageFrame -- RefreshDisplay() re-renders on tab switch
--   * RouteMessage() appends to DB + frame directly when tab is active
--   * Custom EditBox -- SendChatMessage() from OnEnterPressed (hardware event)
--   * Collapse -> small bubble button, click to expand
--   * ADDON_LOADED init (safe across all WoW versions)
--   * SetItemRef() for hyperlinks (no ChatFrame_OnHyperlinkShow dependency)
-- =====================================

TomoMod_ChatFrameSkinV2 = TomoMod_ChatFrameSkinV2 or {}
local CFS2 = TomoMod_ChatFrameSkinV2

-- =====================================
-- CONSTANTS
-- =====================================

local ADDON_PATH      = "Interface\\AddOns\\TomoMod\\"
local ADDON_FONT      = ADDON_PATH .. "Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD = ADDON_PATH .. "Assets\\Fonts\\Poppins-SemiBold.ttf"

local L = TomoMod_L

-- Palette
local A          = { 0.047, 0.824, 0.624 }   -- accent teal
local BG         = { 0.045, 0.045, 0.060 }
local SIDEBAR_BG = { 0.035, 0.035, 0.050 }
local HEADER_BG  = { 0.055, 0.055, 0.072 }
local BORDER     = { 0.18,  0.18,  0.22  }
local TAB_IDLE   = { 0.48,  0.48,  0.54  }
local TAB_ACT    = { 0.92,  0.95,  0.93  }
local BADGE_RED  = { 0.76,  0.18,  0.18  }

local SIDEBAR_W  = 130
local HEADER_H   = 32
local FOOT_H     = 28
local TAB_H      = 34
local MAX_HIST   = 200   -- messages kept per tab

-- =====================================
-- STATE
-- =====================================

local mainFrame     = nil
local bubbleFrame   = nil
local smf           = nil   -- single shared ScrollingMessageFrame
local activeTab     = nil
local tabButtons    = {}
local isInitialized          = false
local isCollapsed            = false
local hookInstalled          = false
local chatSuppressed         = false
local suppressHooksInstalled = false
local _blizChatWasShown      = {}  -- saved per-frame visibility before suppression

-- =====================================
-- TAB DEFINITIONS
-- =====================================

local TAB_DEFS = {
    {
        key      = "general",
        labelKey = "chatv2_tab_general",
        label    = "General",
        chatTypes = {
            "SAY", "YELL", "EMOTE", "TEXT_EMOTE",
            "CHANNEL", "SYSTEM", "RAID_WARNING",
            "MONSTER_SAY", "MONSTER_YELL", "MONSTER_EMOTE", "MONSTER_WHISPER",
            -- combat types duplicated here so they also appear in General
            "COMBAT_MISC_INFO",
            "COMBAT_XP_GAIN", "COMBAT_HONOR_GAIN", "COMBAT_FACTION_CHANGE",
            "LOOT", "MONEY", "SKILL",
        },
    },
    {
        key      = "instance",
        labelKey = "chatv2_tab_instance",
        label    = "Instance",
        chatTypes = {
            "PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER",
            "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER",
        },
    },
    {
        key      = "personnel",
        labelKey = "chatv2_tab_personnel",
        label    = "Personnel",
        chatTypes = {
            "GUILD", "GUILD_ACHIEVEMENT", "OFFICER",
        },
    },
    {
        key      = "chucho",
        labelKey = "chatv2_tab_chucho",
        label    = "Chucho",
        chatTypes = {
            "WHISPER", "WHISPER_INFORM",
            "BN_WHISPER", "BN_WHISPER_INFORM",
        },
    },
    {
        key      = "combat",
        labelKey = "chatv2_tab_combat",
        label    = "Combat",
        -- Only the actual combat log (player actions / what happened to the player).
        -- Rewards (XP, honor, loot, money, skill) are general-only.
        chatTypes = {
            "COMBAT_MISC_INFO",
        },
    },
}

-- chatType (no CHAT_MSG_ prefix) -> tabKey
local chatTypeToTab = {}

-- =====================================
-- DB HELPERS
-- =====================================

local function DB()
    return TomoModDB and TomoModDB.chatFrameSkinV2
end

local function IsEnabled()
    local db = DB()
    return db and db.enabled
end

-- Returns (lazily creates) the history bucket for a given tab key
local function GetHistory(key)
    local db = DB()
    if not db then return nil end
    if not db.history then db.history = {} end
    if not db.history[key] then
        db.history[key] = { messages = {}, unread = 0 }
    end
    return db.history[key]
end

-- =====================================
-- MESSAGE HELPERS
-- =====================================

local function GetShortName(fullName)
    if not fullName or fullName == "" then return "" end
    return fullName:match("^([^%-]+)") or fullName
end

-- In-place trim: keep last MAX_HIST entries
local function PruneHistory(key)
    local h = GetHistory(key)
    if not h or not h.messages then return end
    local msgs = h.messages
    local n = #msgs
    if n <= MAX_HIST then return end
    local cut = n - MAX_HIST
    for i = 1, MAX_HIST do
        msgs[i] = msgs[i + cut]
    end
    for i = MAX_HIST + 1, n do
        msgs[i] = nil
    end
end

-- Store one formatted string in the DB history
local function AppendMessage(tabKey, text)
    local h = GetHistory(tabKey)
    if not h then return end
    local msgs = h.messages
    msgs[#msgs + 1] = text
    if #msgs > MAX_HIST + 10 then
        PruneHistory(tabKey)
    end
    if activeTab ~= tabKey then
        h.unread = (h.unread or 0) + 1
    end
end

-- =====================================
-- DISPLAY REFRESH
-- Clears the SMF and re-adds all history for the active tab
-- =====================================

local function RefreshDisplay()
    if not smf then return end
    smf:Clear()
    if not activeTab then return end
    local h = GetHistory(activeTab)
    if not h or not h.messages then return end
    local db = DB()
    local fs = (db and db.fontSize) or 13
    smf:SetFont(ADDON_FONT, fs, "")
    for _, text in ipairs(h.messages) do
        pcall(smf.AddMessage, smf, text)
    end
    h.unread = 0
end

-- =====================================
-- BADGE UPDATE
-- =====================================

local function UpdateBadges()
    for _, def in ipairs(TAB_DEFS) do
        local btn = tabButtons[def.key]
        if btn and btn._badgeBg then
            local h = GetHistory(def.key)
            local n = (h and h.unread) or 0
            if n > 0 and activeTab ~= def.key then
                btn._badgeLbl:SetText(tostring(math.min(n, 99)))
                btn._badgeBg:SetWidth(math.max(14, btn._badgeLbl:GetStringWidth() + 8))
                btn._badgeBg:Show()
                btn._badgeLbl:Show()
            else
                btn._badgeBg:Hide()
                btn._badgeLbl:Hide()
            end
        end
    end
end

-- =====================================
-- TAB SWITCHING
-- =====================================

local function GetTabLabel(key)
    for _, def in ipairs(TAB_DEFS) do
        if def.key == key then return def.label or key end
    end
    return key
end

local function SwitchTab(key)
    activeTab = key
    for _, def in ipairs(TAB_DEFS) do
        local btn = tabButtons[def.key]
        if btn then
            if def.key == key then
                btn._activeLine:Show()
                btn._bg:SetColorTexture(A[1], A[2], A[3], 0.10)
                btn._lbl:SetTextColor(TAB_ACT[1], TAB_ACT[2], TAB_ACT[3], 1)
            else
                btn._activeLine:Hide()
                btn._bg:SetColorTexture(0, 0, 0, 0)
                btn._lbl:SetTextColor(TAB_IDLE[1], TAB_IDLE[2], TAB_IDLE[3], 1)
            end
        end
    end
    if mainFrame and mainFrame._headerTitle then
        mainFrame._headerTitle:SetText("|cff0cd29f#|r  " .. GetTabLabel(key))
    end
    RefreshDisplay()
    UpdateBadges()
end

-- =====================================
-- CLASS COLOR + CHAT TYPE COLOR HELPERS
-- =====================================

local function GetClassHexFromGUID(guid)
    if not guid or guid == "" then return nil end
    local _, _, _, _, classFile = GetPlayerInfoByGUID(guid)
    if not classFile or classFile == "" then return nil end
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if not c then return nil end
    return string.format("%02x%02x%02x",
        math.floor((c.r or 1) * 255),
        math.floor((c.g or 1) * 255),
        math.floor((c.b or 1) * 255))
end

local CHAT_COLOR = {
    WHISPER              = "ff69b4",
    WHISPER_INFORM       = "ff69b4",
    BN_WHISPER           = "7ec8e3",
    BN_WHISPER_INFORM    = "7ec8e3",
    GUILD                = "1eff00",
    GUILD_ACHIEVEMENT    = "1eff00",
    OFFICER              = "0a7a00",
    PARTY                = "4d9eff",
    PARTY_LEADER         = "4d9eff",
    RAID                 = "ff7700",
    RAID_LEADER          = "ff7700",
    INSTANCE_CHAT        = "ff7700",
    INSTANCE_CHAT_LEADER = "ff7700",
}

local CHANNEL_COLOR = {
    ["General"]      = "ffff66",
    ["Trade"]        = "ffff66",
    ["LocalDefense"] = "ff4444",
    ["Defense"]      = "ff4444",
}

local function GetMsgColor(chatType, channelBaseName)
    if chatType == "CHANNEL" and channelBaseName and channelBaseName ~= "" then
        return CHANNEL_COLOR[channelBaseName]
    end
    return CHAT_COLOR[chatType]
end

-- =====================================
-- MESSAGE ROUTING
-- =====================================

local function FormatMessage(chatType, msg, sender, channelBaseName, senderGUID)
    local db     = DB()
    local showTS = not (db and db.showTimestamp == false)
    local ts     = showTS and ("|cff444444[" .. date("%H:%M") .. "]|r ") or ""
    local short  = GetShortName(sender or "")
    local text   = msg or ""

    local msgHex     = GetMsgColor(chatType, channelBaseName)
    local coloredText = msgHex
        and string.format("|cff%s%s|r", msgHex, text)
        or  text

    if short ~= "" then
        local nameHex    = senderGUID and GetClassHexFromGUID(senderGUID) or nil
        local coloredName = nameHex
            and string.format("|cff%s%s|r", nameHex, short)
            or  string.format("|cff0cd29f%s|r", short)
        return ts .. coloredName .. ": " .. coloredText
    else
        return ts .. coloredText
    end
end

local function RouteMessage(chatType, msg, sender, channelBaseName, senderGUID)
    local dest = chatTypeToTab[chatType] or "general"
    local text  = FormatMessage(chatType, msg, sender, channelBaseName, senderGUID)
    -- dest can be a single string or a table of strings (multi-tab routing)
    if type(dest) == "string" then
        AppendMessage(dest, text)
        if activeTab == dest and smf then pcall(smf.AddMessage, smf, text) end
    else
        for _, tabKey in ipairs(dest) do
            AppendMessage(tabKey, text)
            if activeTab == tabKey and smf then pcall(smf.AddMessage, smf, text) end
        end
    end
    UpdateBadges()
end

-- =====================================
-- CHAT EVENT REGISTRATION
-- =====================================

local ALL_EVENTS = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_SYSTEM", "CHAT_MSG_CHANNEL", "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_GUILD_ACHIEVEMENT",
    "CHAT_MSG_LOOT", "CHAT_MSG_MONEY", "CHAT_MSG_SKILL",
    "CHAT_MSG_COMBAT_MISC_INFO", "CHAT_MSG_COMBAT_XP_GAIN",
    "CHAT_MSG_COMBAT_HONOR_GAIN", "CHAT_MSG_COMBAT_FACTION_CHANGE",
    "CHAT_MSG_MONSTER_SAY", "CHAT_MSG_MONSTER_YELL",
    "CHAT_MSG_MONSTER_EMOTE", "CHAT_MSG_MONSTER_WHISPER",
}

local function InstallChatHooks()
    if hookInstalled then return end
    hookInstalled = true
    local ev = CreateFrame("Frame")
    for _, name in ipairs(ALL_EVENTS) do
        ev:RegisterEvent(name)
    end
    ev:SetScript("OnEvent", function(_, event, msg, sender, language, channelString, target, flags, unknown, channelNumber, channelBaseName, unknown2, lineID, senderGUID)
        if not IsEnabled() then return end
        local chatType = event:gsub("^CHAT_MSG_", "")
        RouteMessage(chatType, msg, sender, channelBaseName, senderGUID)
    end)
end

-- =====================================
-- FRAME HELPERS
-- =====================================

-- 1px border using 4 CreateTexture segments
local function AddBorder(parent, r, g, b, a)
    a = a or 1
    local function Line(p1, p2, isVertical)
        local t = parent:CreateTexture(nil, "BORDER")
        t:SetColorTexture(r, g, b, a)
        t:SetPoint(p1, parent, p1)
        t:SetPoint(p2, parent, p2)
        if isVertical then t:SetWidth(1) else t:SetHeight(1) end
    end
    Line("TOPLEFT",    "TOPRIGHT",    false)
    Line("BOTTOMLEFT", "BOTTOMRIGHT", false)
    Line("TOPLEFT",    "BOTTOMLEFT",  true)
    Line("TOPRIGHT",   "BOTTOMRIGHT", true)
end

-- =====================================
-- BUILD MAIN FRAME
-- =====================================

local function BuildFrame()
    if mainFrame then return end

    local db = DB() or {}
    local W  = db.width  or 550
    local H  = db.height or 320

    -- Root frame
    local f = CreateFrame("Frame", "TomoMod_ChatFrameSkinV2_Main", UIParent)
    f:SetSize(W, H)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(10)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)

    local pos = db.position
    if pos then
        f:SetPoint(
            pos.anchor or "BOTTOMLEFT", UIParent,
            pos.relTo  or "BOTTOMLEFT", pos.x or 20, pos.y or 24
        )
    else
        f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 24)
    end
    f:SetScale((db.scale or 100) / 100)

    -- Main background
    local mainBg = f:CreateTexture(nil, "BACKGROUND")
    mainBg:SetAllPoints()
    mainBg:SetColorTexture(BG[1], BG[2], BG[3], (db.opacity or 88) / 100)
    f._bg = mainBg
    AddBorder(f, BORDER[1], BORDER[2], BORDER[3], 0.6)

    -- =========================================================
    -- SIDEBAR
    -- =========================================================
    local sidebar = CreateFrame("Frame", nil, f)
    sidebar:SetWidth(SIDEBAR_W)
    sidebar:SetPoint("TOPLEFT",    f, "TOPLEFT",    0, 0)
    sidebar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, FOOT_H)

    local sbBg = sidebar:CreateTexture(nil, "BACKGROUND")
    sbBg:SetAllPoints()
    sbBg:SetColorTexture(SIDEBAR_BG[1], SIDEBAR_BG[2], SIDEBAR_BG[3], 1)

    local sbSep = sidebar:CreateTexture(nil, "BORDER")
    sbSep:SetWidth(1)
    sbSep:SetPoint("TOPRIGHT",    sidebar, "TOPRIGHT",    0, 0)
    sbSep:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", 0, 0)
    sbSep:SetColorTexture(BORDER[1], BORDER[2], BORDER[3], 0.8)

    local sbTitle = sidebar:CreateFontString(nil, "OVERLAY")
    sbTitle:SetFont(ADDON_FONT_BOLD, 10, "")
    sbTitle:SetPoint("TOPLEFT", 10, -8)
    sbTitle:SetText("|cff0cd29f" .. (L and L["chatv2_sidebar_title"] or "CHAT") .. "|r")

    -- =========================================================
    -- CONTENT AREA
    -- =========================================================
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT",     sidebar, "TOPRIGHT",    0,  0)
    content:SetPoint("BOTTOMRIGHT", f,       "BOTTOMRIGHT", 0,  FOOT_H)

    -- Header
    local hdr = CreateFrame("Frame", nil, content)
    hdr:SetHeight(HEADER_H)
    hdr:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, 0)
    hdr:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)

    local hdrBg = hdr:CreateTexture(nil, "BACKGROUND")
    hdrBg:SetAllPoints()
    hdrBg:SetColorTexture(HEADER_BG[1], HEADER_BG[2], HEADER_BG[3], 1)

    local hdrAccent = hdr:CreateTexture(nil, "ARTWORK")
    hdrAccent:SetHeight(1)
    hdrAccent:SetPoint("BOTTOMLEFT",  hdr, "BOTTOMLEFT",  0, 0)
    hdrAccent:SetPoint("BOTTOMRIGHT", hdr, "BOTTOMRIGHT", 0, 0)
    hdrAccent:SetColorTexture(A[1], A[2], A[3], 0.30)

    local hdrTitle = hdr:CreateFontString(nil, "OVERLAY")
    hdrTitle:SetFont(ADDON_FONT_BOLD, 12, "")
    hdrTitle:SetPoint("LEFT", hdr, "LEFT", 10, 0)
    hdrTitle:SetTextColor(1, 1, 1, 1)
    f._headerTitle = hdrTitle

    -- Close (collapse) button
    local closeBtn = CreateFrame("Button", nil, hdr)
    closeBtn:SetSize(HEADER_H, HEADER_H)
    closeBtn:SetPoint("RIGHT", hdr, "RIGHT", 0, 0)
    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY")
    closeTxt:SetFont(ADDON_FONT_BOLD, 14, "")
    closeTxt:SetPoint("CENTER")
    closeTxt:SetText("x")
    closeTxt:SetTextColor(TAB_IDLE[1], TAB_IDLE[2], TAB_IDLE[3], 1)
    closeBtn:SetScript("OnEnter", function()
        closeTxt:SetTextColor(0.9, 0.3, 0.3, 1)
    end)
    closeBtn:SetScript("OnLeave", function()
        closeTxt:SetTextColor(TAB_IDLE[1], TAB_IDLE[2], TAB_IDLE[3], 1)
    end)
    closeBtn:SetScript("OnClick", function() CFS2.SetCollapsed(true) end)

    -- Message area
    local msgArea = CreateFrame("Frame", nil, content)
    msgArea:SetPoint("TOPLEFT",     content, "TOPLEFT",     0, -HEADER_H)
    msgArea:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0,  0)

    -- Single shared ScrollingMessageFrame
    local sf = CreateFrame("ScrollingMessageFrame", nil, msgArea)
    sf:SetPoint("TOPLEFT",     msgArea, "TOPLEFT",     6, -6)
    sf:SetPoint("BOTTOMRIGHT", msgArea, "BOTTOMRIGHT", -6,  6)
    sf:SetFont(ADDON_FONT, db.fontSize or 13, "")
    sf:SetJustifyH("LEFT")
    sf:SetFading(false)
    sf:SetMaxLines(500)
    sf:SetSpacing(3)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then self:ScrollUp() else self:ScrollDown() end
    end)
    sf:SetHyperlinksEnabled(true)
    -- SetItemRef: compatible with all WoW versions, no ChatFrame dependency
    sf:SetScript("OnHyperlinkClick", function(_, link, text, button)
        if SetItemRef then SetItemRef(link, text, button) end
    end)
    smf = sf
    f._smf = sf

    -- =========================================================
    -- FOOTER  (edit-box zone)
    -- =========================================================
    local footBg = f:CreateTexture(nil, "BACKGROUND")
    footBg:SetHeight(FOOT_H)
    footBg:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  0, 0)
    footBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    footBg:SetColorTexture(SIDEBAR_BG[1], SIDEBAR_BG[2], SIDEBAR_BG[3], 0.95)

    local footSep = f:CreateTexture(nil, "BORDER")
    footSep:SetHeight(1)
    footSep:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  0, FOOT_H)
    footSep:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, FOOT_H)
    footSep:SetColorTexture(BORDER[1], BORDER[2], BORDER[3], 0.8)

    local footAccent = f:CreateTexture(nil, "OVERLAY")
    footAccent:SetWidth(2)
    footAccent:SetHeight(FOOT_H)
    footAccent:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    footAccent:SetColorTexture(A[1], A[2], A[3], 0.5)

    -- Custom EditBox — uses no Blizzard templates, no taint risk
    local eb = CreateFrame("EditBox", "TomoMod_ChatSkinV2_EditBox", f)
    eb:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  SIDEBAR_W + 6, 4)
    eb:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 4)
    eb:SetHeight(FOOT_H - 8)
    eb:SetFont(ADDON_FONT, db.fontSize or 13, "")
    eb:SetTextColor(0.85, 0.85, 0.85, 1)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(255)
    eb:SetFrameLevel(f:GetFrameLevel() + 3)

    eb:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    -- OnEnterPressed is a hardware event in WoW — SendChatMessage allowed here
    eb:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        self:SetText("")
        self:ClearFocus()
        if not text or text == "" then return end

        local chan = "SAY"
        if activeTab == "instance" then
            local ok1, inRaid  = pcall(IsInRaid)
            local ok2, inGroup = pcall(IsInGroup)
            if ok1 and inRaid  then chan = "RAID"
            elseif ok2 and inGroup then chan = "PARTY"
            end
        elseif activeTab == "chucho" then
            local ok, info = pcall(GetGuildInfo, "player")
            if ok and info and info ~= "" then chan = "GUILD" end
        end

        pcall(SendChatMessage, text, chan)
    end)

    -- Placeholder hint (hidden while editbox is focused)
    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont(ADDON_FONT, 11, "")
    hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", SIDEBAR_W + 10, 8)
    hint:SetTextColor(TAB_IDLE[1], TAB_IDLE[2], TAB_IDLE[3], 0.40)
    hint:SetText(L and L["chatv2_input_hint"] or "Enter to type...")
    f._hint = hint

    eb:SetScript("OnEditFocusGained", function() if f._hint then f._hint:Hide() end end)
    eb:SetScript("OnEditFocusLost",   function() if f._hint then f._hint:Show() end end)

    -- Click zone so clicking anywhere in the footer focuses the editbox
    local clickZone = CreateFrame("Button", nil, f)
    clickZone:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  SIDEBAR_W, 0)
    clickZone:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    clickZone:SetHeight(FOOT_H)
    clickZone:SetFrameLevel(f:GetFrameLevel() + 2)
    clickZone:SetScript("OnClick", function() eb:SetFocus() end)

    f._editBox = eb

    -- =========================================================
    -- SIDEBAR TAB BUTTONS
    -- =========================================================
    local tabStartY = -22

    for i, def in ipairs(TAB_DEFS) do
        local btn = CreateFrame("Button", nil, sidebar)
        btn:SetSize(SIDEBAR_W, TAB_H)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 0, tabStartY + (i - 1) * (-TAB_H))

        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints()
        btnBg:SetColorTexture(0, 0, 0, 0)
        btn._bg = btnBg

        local activeLine = btn:CreateTexture(nil, "ARTWORK")
        activeLine:SetWidth(2)
        activeLine:SetPoint("TOPLEFT",    btn, "TOPLEFT",    0, -2)
        activeLine:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0,  2)
        activeLine:SetColorTexture(A[1], A[2], A[3], 1)
        activeLine:Hide()
        btn._activeLine = activeLine

        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(ADDON_FONT_BOLD, 11, "")
        lbl:SetPoint("LEFT", btn, "LEFT", 14, 0)
        lbl:SetText(def.label)
        lbl:SetTextColor(TAB_IDLE[1], TAB_IDLE[2], TAB_IDLE[3], 1)
        btn._lbl = lbl

        -- Unread badge
        local badgeBg = btn:CreateTexture(nil, "OVERLAY")
        badgeBg:SetSize(14, 14)
        badgeBg:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
        badgeBg:SetColorTexture(BADGE_RED[1], BADGE_RED[2], BADGE_RED[3], 0.90)
        badgeBg:Hide()
        btn._badgeBg = badgeBg

        local badgeLbl = btn:CreateFontString(nil, "OVERLAY")
        badgeLbl:SetFont(ADDON_FONT_BOLD, 9, "OUTLINE")
        badgeLbl:SetPoint("CENTER", badgeBg, "CENTER", 0, 0)
        badgeLbl:SetTextColor(1, 1, 1, 1)
        badgeLbl:Hide()
        btn._badgeLbl = badgeLbl

        -- Bottom separator line
        local sep = btn:CreateTexture(nil, "BORDER")
        sep:SetHeight(1)
        sep:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  6, 0)
        sep:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -6, 0)
        sep:SetColorTexture(BORDER[1], BORDER[2], BORDER[3], 0.3)

        -- Capture key by value for closure
        local key = def.key
        btn:SetScript("OnEnter", function()
            if activeTab ~= key then
                btnBg:SetColorTexture(A[1], A[2], A[3], 0.05)
                lbl:SetTextColor(A[1] * 0.9 + 0.1, A[2] * 0.9 + 0.1, A[3] * 0.9 + 0.1, 1)
            end
        end)
        btn:SetScript("OnLeave", function()
            if activeTab ~= key then
                btnBg:SetColorTexture(0, 0, 0, 0)
                lbl:SetTextColor(TAB_IDLE[1], TAB_IDLE[2], TAB_IDLE[3], 1)
            end
        end)
        btn:SetScript("OnClick", function() SwitchTab(key) end)

        tabButtons[def.key] = btn
    end

    -- =========================================================
    -- DRAG
    -- =========================================================
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",  function(self)
        self:StopMovingOrSizing()
        local d = DB()
        if d then
            local pt, _, rpt, x, y = self:GetPoint(1)
            d.position = {
                anchor = pt  or "BOTTOMLEFT",
                relTo  = rpt or "BOTTOMLEFT",
                x = x or 20, y = y or 24,
            }
            if bubbleFrame then
                bubbleFrame:ClearAllPoints()
                bubbleFrame:SetPoint(d.position.anchor, UIParent, d.position.relTo, d.position.x, d.position.y)
            end
        end
    end)

    mainFrame = f
end

-- =====================================
-- COLLAPSED BUBBLE
-- =====================================

local function BuildBubble()
    if bubbleFrame then return end

    local db  = DB() or {}
    local pos = db.position

    local btn = CreateFrame("Button", "TomoMod_ChatV2_Bubble", UIParent)
    btn:SetSize(40, 40)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(10)
    btn:SetClampedToScreen(true)
    if pos then
        btn:SetPoint(pos.anchor or "BOTTOMLEFT", UIParent, pos.relTo or "BOTTOMLEFT", pos.x or 20, pos.y or 24)
    else
        btn:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 24)
    end

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(SIDEBAR_BG[1], SIDEBAR_BG[2], SIDEBAR_BG[3], 0.92)
    AddBorder(btn, BORDER[1], BORDER[2], BORDER[3], 0.7)

    local icon = btn:CreateFontString(nil, "OVERLAY")
    icon:SetFont(ADDON_FONT_BOLD, 13, "")
    icon:SetPoint("CENTER")
    icon:SetText("|cff0cd29f#|r")

    btn:SetScript("OnEnter", function() bg:SetColorTexture(A[1], A[2], A[3], 0.15) end)
    btn:SetScript("OnLeave", function() bg:SetColorTexture(SIDEBAR_BG[1], SIDEBAR_BG[2], SIDEBAR_BG[3], 0.92) end)
    btn:SetScript("OnClick", function() CFS2.SetCollapsed(false) end)
    btn:Hide()

    bubbleFrame = btn
end

-- =====================================
-- COLLAPSE / EXPAND  (public)
-- =====================================

function CFS2.SetCollapsed(collapsed)
    isCollapsed = collapsed
    if mainFrame  then if collapsed then mainFrame:Hide()   else mainFrame:Show()  end end
    if bubbleFrame then if collapsed then bubbleFrame:Show() else bubbleFrame:Hide() end end
    local d = DB()
    if d then d.collapsed = collapsed end
end

-- =====================================
-- MOVERS REGISTRATION
-- =====================================

local function RegisterWithMovers()
    if not TomoMod_Movers or not TomoMod_Movers.RegisterEntry then return end
    TomoMod_Movers.RegisterEntry({
        label  = L and L["chatv2_mover_label"] or "Chat V2",
        unlock = function()
            if mainFrame then mainFrame:SetMovable(true); mainFrame:EnableMouse(true) end
        end,
        lock = function()
            if mainFrame then
                local d = DB()
                if d then
                    local pt, _, rpt, x, y = mainFrame:GetPoint(1)
                    d.position = { anchor = pt or "BOTTOMLEFT", relTo = rpt or "BOTTOMLEFT", x = x or 20, y = y or 24 }
                end
            end
        end,
        isActive = function() return IsEnabled() end,
    })
end

-- =====================================
-- APPLY SETTINGS  (public)
-- =====================================

function CFS2.ApplySettings()
    if not mainFrame then return end
    local db = DB() or {}
    mainFrame:SetSize(db.width or 550, db.height or 320)
    mainFrame:SetScale((db.scale or 100) / 100)
    mainFrame._bg:SetColorTexture(BG[1], BG[2], BG[3], (db.opacity or 88) / 100)
    local fs = db.fontSize or 13
    if smf then smf:SetFont(ADDON_FONT, fs, "") end
    if mainFrame._editBox then mainFrame._editBox:SetFont(ADDON_FONT, fs, "") end
end

-- =====================================
-- SUPPRESS / RESTORE DEFAULT BLIZZARD CHAT
-- Hides all native chat frames and redirects Enter-to-chat
-- to our custom editbox while V2 is active.
-- =====================================

local BLIZ_CHROME = {
    "ChatFrameMenuButton", "ChatFrameChannelButton",
    "ChatFrameToggleVoiceDeafenButton", "ChatFrameToggleVoiceMuteButton",
    "QuickJoinToastButton",
}

local function SuppressDefaultChat()
    chatSuppressed = true
    local n = NUM_CHAT_WINDOWS or 10
    -- Save visibility state so RestoreDefaultChat only shows what was actually visible
    wipe(_blizChatWasShown)
    for i = 1, n do
        local cf  = _G["ChatFrame"  .. i]
        local tab = _G["ChatFrame"  .. i .. "Tab"]
        _blizChatWasShown["f" .. i] = cf  and cf:IsShown()  or false
        _blizChatWasShown["t" .. i] = tab and tab:IsShown() or false
        if cf  then cf:Hide()  end
        if tab then tab:Hide() end
    end
    for _, name in ipairs(BLIZ_CHROME) do
        local f = _G[name]
        _blizChatWasShown[name] = f and f:IsShown() or false
        if f then f:Hide() end
    end

    if suppressHooksInstalled then return end
    suppressHooksInstalled = true

    -- Keep default frames hidden as long as chatSuppressed = true
    for i = 1, n do
        local cf  = _G["ChatFrame"  .. i]
        local tab = _G["ChatFrame"  .. i .. "Tab"]
        if cf  then cf:HookScript( "OnShow", function(s) if chatSuppressed then s:Hide() end end) end
        if tab then tab:HookScript("OnShow", function(s) if chatSuppressed then s:Hide() end end) end
    end
    for _, name in ipairs(BLIZ_CHROME) do
        local f = _G[name]
        if f and f.HookScript then
            f:HookScript("OnShow", function(s) if chatSuppressed then s:Hide() end end)
        end
    end

    -- Redirect Enter-to-chat to our custom editbox
    if ChatEdit_OpenChat then
        hooksecurefunc("ChatEdit_OpenChat", function()
            if not chatSuppressed then return end
            C_Timer.After(0, function()
                local ae = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
                if ae and ae.IsShown and ae:IsShown() then
                    if ChatEdit_DeactivateChat then ChatEdit_DeactivateChat(ae) end
                end
                if mainFrame and mainFrame:IsShown() and mainFrame._editBox then
                    mainFrame._editBox:SetFocus()
                end
            end)
        end)
    end
end

local function RestoreDefaultChat()
    chatSuppressed = false
    local n = NUM_CHAT_WINDOWS or 10
    local hasSaved = next(_blizChatWasShown) ~= nil
    for i = 1, n do
        local cf  = _G["ChatFrame"  .. i]
        local tab = _G["ChatFrame"  .. i .. "Tab"]
        -- If we have saved state, only restore what was visible.
        -- If no saved state (edge case), fall back to showing ChatFrame1 only.
        local showFrame = hasSaved and _blizChatWasShown["f" .. i] or (i == 1)
        local showTab   = hasSaved and _blizChatWasShown["t" .. i] or (i == 1)
        if cf  and showFrame then cf:Show()  end
        if tab and showTab   then tab:Show() end
    end
    for _, name in ipairs(BLIZ_CHROME) do
        local f = _G[name]
        local wasShown = hasSaved and _blizChatWasShown[name] or true
        if f and wasShown then f:Show() end
    end
    wipe(_blizChatWasShown)
end

-- =====================================
-- SET ENABLED  (public)
-- =====================================

function CFS2.SetEnabled(enabled)
    local d = DB()
    if d then d.enabled = enabled end
    if enabled then
        if not mainFrame then
            BuildFrame()
            BuildBubble()
        end
        local db = DB() or {}
        if db.collapsed then
            CFS2.SetCollapsed(true)
        else
            mainFrame:Show()
            if not activeTab then
                SwitchTab(db.defaultTab or "general")
            end
        end
        InstallChatHooks()
        SuppressDefaultChat()
    else
        if mainFrame   then mainFrame:Hide()   end
        if bubbleFrame then bubbleFrame:Hide()  end
        RestoreDefaultChat()
    end
end

-- =====================================
-- INITIALIZE  (public)
-- =====================================

function CFS2.Initialize()
    if isInitialized then return end
    isInitialized = true

    -- Resolve locale labels (L[] loaded by ADDON_LOADED time)
    for _, def in ipairs(TAB_DEFS) do
        if L and L[def.labelKey] then
            def.label = L[def.labelKey]
        end
    end

    -- Build chatType -> tabKey map (a type can appear in multiple tabs)
    for _, def in ipairs(TAB_DEFS) do
        for _, ct in ipairs(def.chatTypes) do
            local existing = chatTypeToTab[ct]
            if not existing then
                chatTypeToTab[ct] = def.key
            elseif type(existing) == "string" then
                chatTypeToTab[ct] = { existing, def.key }
            else
                existing[#existing + 1] = def.key
            end
        end
    end

    if not IsEnabled() then return end

    C_Timer.After(0.5, function()
        BuildFrame()
        BuildBubble()
        local db = DB() or {}
        if db.collapsed then
            CFS2.SetCollapsed(true)
        else
            mainFrame:Show()
            SwitchTab(db.defaultTab or "general")
        end
        InstallChatHooks()
        SuppressDefaultChat()
        RegisterWithMovers()
    end)
end

-- =====================================
-- AUTO-INIT on ADDON_LOADED
-- ADDON_LOADED fires after SavedVariables are populated — safe for DB access
-- =====================================

local _loader = CreateFrame("Frame")
_loader:RegisterEvent("ADDON_LOADED")
_loader:SetScript("OnEvent", function(self, _, addonName)
    if addonName ~= "TomoMod" then return end
    self:UnregisterEvent("ADDON_LOADED")

    -- Create DB section if missing (Database.lua usually creates it already)
    if TomoModDB and not TomoModDB.chatFrameSkinV2 then
        TomoModDB.chatFrameSkinV2 = {
            enabled    = false,
            width      = 550,
            height     = 320,
            scale      = 100,
            opacity    = 88,
            fontSize   = 13,
            defaultTab = "general",
            collapsed  = false,
            history    = {},
            position   = { anchor = "BOTTOMLEFT", relTo = "BOTTOMLEFT", x = 20, y = 24 },
        }
    elseif TomoModDB and TomoModDB.chatFrameSkinV2 and not TomoModDB.chatFrameSkinV2.history then
        -- Upgrade path: add missing history field to existing DB entry
        TomoModDB.chatFrameSkinV2.history = {}
    end

    CFS2.Initialize()
    RegisterWithMovers()
end)
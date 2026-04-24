-- =====================================
-- ChatFrameSkin.lua
-- Chat System for TomoMod â€“ rebuilt with TUI_Core visual style
-- Features: sidebar + window container, sidebar icons (professions,
--   shortcuts, copy chat, emotes, player status), tab bar texture,
--   scroll bar theming, notification flash, fading, short channel names,
--   timestamps, URL detection (popup copy), emoji, class-colored names,
--   keywords, copy chat, scroll, chat history
-- Compatible with WoW 12.x (TWW / Midnight)
-- =====================================

TomoMod_ChatFrameSkin = TomoMod_ChatFrameSkin or {}
local CFS = TomoMod_ChatFrameSkin

-- =====================================
-- LOCALS & CACHES
-- =====================================

local ADDON_PATH     = "Interface\\AddOns\\TomoMod\\"
local TEX_CHAT       = ADDON_PATH .. "Assets\\Textures\\Chat\\"
local ADDON_FONT     = ADDON_PATH .. "Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD = ADDON_PATH .. "Assets\\Fonts\\Poppins-SemiBold.ttf"

local L = TomoMod_L

local isInitialized = false
local chatModuleInit = false

local GetMentorChannelStatus = ChatFrameUtil and ChatFrameUtil.GetMentorChannelStatus or ChatFrame_GetMentorChannelStatus
local Chat_GetChatCategory = ChatFrameUtil and ChatFrameUtil.GetChatCategory or Chat_GetChatCategory
local ChatEdit_SetLastTellTarget = ChatFrameUtil and ChatFrameUtil.SetLastTellTarget or ChatEdit_SetLastTellTarget
local ChatFrame_AddMessageEventFilter = ChatFrame_AddMessageEventFilter
local GetClientTexture = BNet_GetClientEmbeddedAtlas or BNet_GetClientEmbeddedTexture
local GetMobileEmbeddedTexture = (ChatFrameUtil and ChatFrameUtil.GetMobileEmbeddedTexture) or ChatFrame_GetMobileEmbeddedTexture
local ResolvePrefixedChannelName = (ChatFrameUtil and ChatFrameUtil.ResolvePrefixedChannelName) or ChatFrame_ResolvePrefixedChannelName
local ShouldColorChatByClass = (ChatFrameUtil and ChatFrameUtil.ShouldColorChatByClass) or Chat_ShouldColorChatByClass
local IsChannelRegionalForChannelID = C_ChatInfo.IsChannelRegionalForChannelID
local GetChannelShortcutForChannelID = C_ChatInfo.GetChannelShortcutForChannelID
local C_GuildInfo_GetMOTD = C_GuildInfo and C_GuildInfo.GetMOTD or GetGuildRosterMOTD


local pairs, ipairs, type, next = pairs, ipairs, type, next
local format, gsub, strsub, strmatch, strlower, strupper, strlen, strtrim, gmatch, strfind =
    string.format, string.gsub, string.sub, string.match, string.lower, string.upper, string.len, strtrim, string.gmatch, string.find
local tinsert, tremove, wipe = table.insert, table.remove, wipe
local time, difftime = time, difftime
local select, tostring, tonumber = select, tostring, tonumber
local issecretvalue = issecretvalue

-- =====================================
-- SETTINGS
-- =====================================

local function S()
    return TomoModDB and TomoModDB.chatFrameSkin or {}
end

local function IsEnabled()
    return S().enabled
end

local function NoOp() end

-- =====================================
-- Tiny helpers
-- =====================================

local function RGBToHex(r, g, b)
    return format("|cff%02x%02x%02x", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
end

local function GetClassColorObj(class)
    if class and C_ClassColor and C_ClassColor.GetClassColor then
        return C_ClassColor.GetClassColor(class)
    end
    return class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
end

local function StripTextures(frame)
    if not frame or not frame.GetRegions then return end
    for _, region in pairs({ frame:GetRegions() }) do
        if region:IsObjectType("Texture") then
            region:SetTexture(nil)
            region:SetAlpha(0)
            region:Hide()
        end
    end
end

local function KillElement(element)
    if not element then return end
    if element.UnregisterAllEvents then element:UnregisterAllEvents() end
    if element.SetParent then element:SetParent(UIParent) end
    element:Hide()
    element:SetAlpha(0)
    element:SetSize(0.001, 0.001)
end

local function EscapeString(str)
    return gsub(str, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
end

-- =====================================
-- SHORT CHANNEL NAMES
-- =====================================

local DEFAULT_STRINGS = {
    GUILD = "G",
    PARTY = "P",
    RAID = "R",
    OFFICER = "O",
    PARTY_LEADER = "PL",
    RAID_LEADER = "RL",
    INSTANCE_CHAT = "I",
    INSTANCE_CHAT_LEADER = "IL",
    PET_BATTLE_COMBAT_LOG = PET_BATTLE_COMBAT_LOG,
}

-- =====================================
-- HYPERLINK TYPES, TEXTURES, ETC.
-- =====================================

local hyperlinkTypes = {
    achievement = true, apower = true, currency = true, enchant = true,
    glyph = true, instancelock = true, item = true, keystone = true,
    quest = true, spell = true, talent = true, unit = true
}

local CHAT_FRAME_TEXTURES = {
    "TopLeftTexture", "BottomLeftTexture", "TopRightTexture", "BottomRightTexture",
    "LeftTexture", "RightTexture", "BottomTexture", "TopTexture",
    "EditBox", "ResizeButton",
    "ButtonFrameBackground", "ButtonFrameTopLeftTexture", "ButtonFrameBottomLeftTexture",
    "ButtonFrameTopRightTexture", "ButtonFrameBottomRightTexture",
    "ButtonFrameLeftTexture", "ButtonFrameRightTexture",
    "ButtonFrameBottomTexture", "ButtonFrameTopTexture",
    "EditBoxMid", "EditBoxLeft", "EditBoxRight",
    "TabSelectedRight", "TabSelectedLeft", "TabSelectedMiddle",
    "TabRight", "TabLeft", "TabMiddle", "Tab"
}

local historyTypes = {
    CHAT_MSG_WHISPER            = "WHISPER",
    CHAT_MSG_WHISPER_INFORM     = "WHISPER",
    CHAT_MSG_BN_WHISPER         = "WHISPER",
    CHAT_MSG_BN_WHISPER_INFORM  = "WHISPER",
    CHAT_MSG_GUILD              = "GUILD",
    CHAT_MSG_GUILD_ACHIEVEMENT  = "GUILD",
    CHAT_MSG_PARTY              = "PARTY",
    CHAT_MSG_PARTY_LEADER       = "PARTY",
    CHAT_MSG_RAID               = "RAID",
    CHAT_MSG_RAID_LEADER        = "RAID",
    CHAT_MSG_RAID_WARNING       = "RAID",
    CHAT_MSG_INSTANCE_CHAT          = "INSTANCE",
    CHAT_MSG_INSTANCE_CHAT_LEADER   = "INSTANCE",
    CHAT_MSG_CHANNEL            = "CHANNEL",
    CHAT_MSG_SAY                = "SAY",
    CHAT_MSG_YELL               = "YELL",
    CHAT_MSG_OFFICER            = "OFFICER",
    CHAT_MSG_EMOTE              = "EMOTE"
}

local FindURL_Events = {
    "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_BN_INLINE_TOAST_BROADCAST",
    "CHAT_MSG_GUILD_ACHIEVEMENT", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_CHANNEL", "CHAT_MSG_SAY", "CHAT_MSG_YELL",
    "CHAT_MSG_EMOTE", "CHAT_MSG_AFK", "CHAT_MSG_DND",
    "CHAT_MSG_COMMUNITIES_CHANNEL",
}

local throttle = {}
local lfgRoles = {}
local GuidCache = {}
local ClassNames = {}
local Keywords = {}
local hooks = {}
local Smileys = {}
local SmileysForMenu = {}
local copyLines = {}
local ignoreChats = {[2] = "Log", [3] = "Voice"}

local SoundTimer

local myRealm = gsub(GetRealmName() or "", "[%s%-]", "")
local myName = UnitName("player") or "Unknown"
local PLAYER_REALM = myRealm
local PLAYER_NAME = format("%s-%s", myName, PLAYER_REALM)

local rolePaths = {
    TANK    = "|TInterface/AddOns/TomoMod/Assets/Textures/Roles/TANK.tga:12:12:0:0:64:64:2:56:2:56|t ",
    HEALER  = "|TInterface/AddOns/TomoMod/Assets/Textures/Roles/HEALER.tga:12:12:0:0:64:64:2:56:2:56|t ",
    DAMAGER = "|TInterface/AddOns/TomoMod/Assets/Textures/Roles/DAMAGER.tga:12:12:0:0:64:64:2:56:2:56|t ",
}

-- =====================================
-- CHAT ACCESS ID SYSTEM
-- =====================================

local ChatFunctions = {}

do
    local accessIndex = 1
    local accessInfo = {}
    local accessType = {}
    local accessTarget = {}
    local accessSender = {}

    local function GetToken(chatType, chatTarget, chanSender)
        return format("%s;;%s;;%s", strlower(chatType), chatTarget or "", chanSender or "")
    end

    function ChatFunctions:GetAccessID(chatType, chatTarget, chanSender)
        -- Skip secret/tainted values from NPC events
        if (issecretvalue and (issecretvalue(chatTarget) or issecretvalue(chanSender))) then
            return 0
        end

        local token = GetToken(chatType, chatTarget, chanSender)
        if not accessInfo[token] then
            accessInfo[token] = accessIndex
            accessType[accessIndex] = chatType
            accessTarget[accessIndex] = chatTarget
            accessSender[accessIndex] = chanSender
            accessIndex = accessIndex + 1
        end
        return accessInfo[token]
    end

    function ChatFunctions:GetAccessType(accessID)
        return accessType[accessID], accessTarget[accessID], accessSender[accessID]
    end
end

-- =====================================
-- GUID CACHE / CLASS COLORS
-- =====================================

local function TM_GetPlayerInfoByGUID(guid)
    if not guid then return end
    if issecretvalue and issecretvalue(guid) then return end
    if guid == "" then return end

    local data = GuidCache[guid]
    if not data then
        local ok, localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = pcall(GetPlayerInfoByGUID, guid)
        if not (ok and englishClass) then return end

        if realm == "" then realm = nil end
        local shortRealm = realm and gsub(realm, "[%s%-]", "") or nil
        local nameWithRealm
        if name and name ~= "" then
            nameWithRealm = (shortRealm and name .. "-" .. shortRealm) or name .. "-" .. PLAYER_REALM
        end

        data = {
            localizedClass = localizedClass,
            englishClass = englishClass,
            name = name,
            realm = realm,
            nameWithRealm = nameWithRealm
        }

        if name then ClassNames[strlower(name)] = englishClass end
        if nameWithRealm then ClassNames[strlower(nameWithRealm)] = englishClass end

        GuidCache[guid] = data
    end

    if data then data.classColor = GetClassColorObj(data.englishClass) end
    return data
end

function ChatFunctions:GetColoredName(event, _, arg2, _, _, _, _, _, arg8, _, _, _, arg12)
    if not arg2 then return end

    local chatType = strsub(event, 10)
    local subType = strsub(chatType, 1, 7)
    if subType == "WHISPER" then
        chatType = "WHISPER"
    elseif subType == "CHANNEL" then
        chatType = "CHANNEL" .. arg8
    end

    if issecretvalue and issecretvalue(arg2) then return arg2 end
    local name = Ambiguate(arg2, (chatType == "GUILD" and "guild") or "none")

    local info = name and arg12 and _G.ChatTypeInfo[chatType]
    if info and ShouldColorChatByClass(info) then
        local data = TM_GetPlayerInfoByGUID(arg12)
        local color = data and data.classColor
        if color then
            return color:WrapTextInColorCode(name)
        end
    end

    return name
end

-- =====================================
-- PLAYER LINK HELPERS
-- =====================================

do
    local function GetLink(linkType, displayText, ...)
        local text = ""
        for i, value in next, { ... } do
            text = text .. (i == 1 and format("|H%s:", linkType) or ":") .. value
        end
        return text .. (displayText and format("|h%s|h", displayText) or "|h")
    end

    function ChatFunctions:GetPlayerLink(characterName, displayText, lineID, chatType, chatTarget)
        if lineID or chatType or chatTarget then
            return GetLink("player", displayText, characterName, lineID or 0, chatType or 0, chatTarget or "")
        else
            return GetLink("player", displayText, characterName)
        end
    end

    function ChatFunctions:GetBNPlayerLink(name, displayText, bnetIDAccount, lineID, chatType, chatTarget)
        return GetLink("BNplayer", displayText, name, bnetIDAccount, lineID or 0, chatType, chatTarget)
    end
end

-- =====================================
-- MESSAGE PROTECTION CHECK
-- =====================================

local function canChangeMessage(arg1, id)
    if id and arg1 == "" then return id end
end

function ChatFunctions:IsMessageProtected(message)
    if not message then return true end
    if issecretvalue and issecretvalue(message) then return true end
    return message ~= gsub(message, "(:?|?)|K(.-)|k", canChangeMessage)
end

-- =====================================
-- COPY CHAT
-- =====================================

local removeIconFromLine
do
    local raidIconFunc = function(x)
        x = x ~= "" and _G["RAID_TARGET_" .. x]
        return x and ("{" .. strlower(x) .. "}") or ""
    end
    local stripTextureFunc = function(w, x, y)
        if x == "" then
            return (w ~= "" and w) or (y ~= "" and y) or ""
        end
    end
    local hyperLinkFunc = function(w, x, y)
        if w ~= "" then return end
        return y
    end
    local fourString = function(v, w, x, y)
        return format("%s%s%s", v, w, (v and v == "1" and x) or y)
    end

    removeIconFromLine = function(text)
        text = gsub(text, [[|TInterface\TargetingFrame\UI%-RaidTargetingIcon_(%d+):0|t]], raidIconFunc)
        text = gsub(text, "(%s?)(|?)|[TA].-|[ta](%s?)", stripTextureFunc)
        text = gsub(text, "(|?)|H(.-)|h(.-)|h", hyperLinkFunc)
        text = gsub(text, "(%d+)(.-)|4(.-):(.-);", fourString)
        return text
    end
end

local function colorizeLine(text, r, g, b)
    return format("%s%s|r", RGBToHex(r, g, b), text)
end

local function getLines(frame)
    local index = 1
    local maxMessages = 128
    local frameMessages = frame:GetNumMessages()
    local startLine = frameMessages <= maxMessages and 1 or frameMessages + 1 - maxMessages

    for i = startLine, frameMessages do
        local message, r, g, b = frame:GetMessageInfo(i)
        if message and not ChatFunctions:IsMessageProtected(message) then
            r, g, b = r or 1, g or 1, b or 1
            message = removeIconFromLine(message)
            message = colorizeLine(message, r, g, b)
            copyLines[index] = message
            index = index + 1
        end
    end

    return index - 1
end

-- =====================================
-- EMOJI / SMILEY SYSTEM
-- =====================================

local function AddSmiley(key, texture, showAtMenu)
    if key and type(key) == "string" and not strfind(key, ":%%", 1, true) and texture then
        Smileys[key] = texture
        if showAtMenu then
            SmileysForMenu[key] = texture
        end
    end
end

local function SetupSmileys()
    if next(Smileys) then wipe(Smileys) end
    if next(SmileysForMenu) then wipe(SmileysForMenu) end

    -- Smileys use standard WoW emoticon atlases if no custom textures exist
    AddSmiley(":%-%)",":-)")
    AddSmiley(":%)", ":)")
    AddSmiley(":D", ":D")
    AddSmiley(":%-D", ":-D")
    AddSmiley(";D", ";D")
    AddSmiley(":%-%(", ":-(")
    AddSmiley(":%(", ":(")
    AddSmiley(":P", ":P")
    AddSmiley(":p", ":p")
    AddSmiley(";%-%)", ";-)")
    AddSmiley(";%)", ";)")
end

local function InsertEmotions(msg)
    for word in gmatch(msg, "%s-%S+%s*") do
        word = strtrim(word)
        local pattern = EscapeString(word)
        local emoji = Smileys[pattern]
        if emoji and strmatch(msg, "[%s%p]-" .. pattern .. "[%s%p]*") then
            msg = gsub(msg, "([%s%p]-)" .. pattern .. "([%s%p]*)", "%1" .. emoji .. "%2")
        end
    end
    return msg
end

local function GetSmileyReplacementText(msg)
    if not msg or not S().emoji or strfind(msg, "/run") or strfind(msg, "/dump") or strfind(msg, "/script") then return msg end
    local outstr = ""
    local origlen = strlen(msg)
    local startpos = 1
    local endpos

    while (startpos <= origlen) do
        local pos = strfind(msg, "|H", startpos, true)
        endpos = pos or origlen
        outstr = outstr .. InsertEmotions(strsub(msg, startpos, endpos))
        startpos = endpos + 1
        if pos ~= nil then
            _, endpos = strfind(msg, "|h.-|h", startpos)
            endpos = endpos or origlen
            if startpos < endpos then
                outstr = outstr .. strsub(msg, startpos, endpos)
                startpos = endpos + 1
            end
        end
    end

    return outstr
end

-- =====================================
-- URL DETECTION (TUI_Core style â€” StaticPopup for copy)
-- =====================================

local function GetChatLink(url)
    return format("|Hurl:%s|h|cFFFFE29E[%s]|r|h", url, url)
end

local function SetupURLPopup()
    if not StaticPopupDialogs["TOMOMOD_URL_COPY"] then
        StaticPopupDialogs["TOMOMOD_URL_COPY"] = {
            text = "|cFF00CCFFTomoMod|r\n(CTRL+C to Copy, CTRL+V to Paste)",
            button1 = CLOSE,
            hasEditBox = true,
            maxLetters = 1024,
            editBoxWidth = 350,
            hideOnEscape = 1,
            timeout = 0,
            whileDead = 1,
            preferredIndex = 3,
        }
    end
end

local function OnHyperlinkClickURL(self, linkData, text, button)
    local linkType, value = linkData:match("(%a+):(.+)")
    if linkType == "url" then
        SetupURLPopup()
        local popup = StaticPopup_Show("TOMOMOD_URL_COPY")
        if popup then
            local editbox = _G[popup:GetName() .. "EditBox"]
            editbox:SetText(value)
            editbox:SetFocus()
            editbox:HighlightText()
        end
    elseif linkData == "weakauras" then
        ChatFrame_OnHyperlinkShow(self, linkData, text, button)
    else
        SetItemRef(linkData, text, button, self)
    end
end

local function ReplaceProtocol(self, arg1, arg2)
    local str = self .. "://" .. arg1
    return (self == "Houtfit") and str .. arg2 or GetChatLink(str)
end

-- =====================================
-- KEYWORD DETECTION
-- =====================================

local function UpdateChatKeywords()
    wipe(Keywords)
    local s = S()
    local kw = s.keywords or ""
    kw = gsub(kw, ",%s", ",")
    for sv in gmatch(kw, "[^,]+") do
        if sv ~= "" then
            Keywords[sv] = true
        end
    end
end

local protectLinks = {}
local function CheckKeyword(message, author)
    for hyperLink in gmatch(message, "|c%x-|H.-|h.-|h|r") do
        protectLinks[hyperLink] = gsub(hyperLink, "%s", "|s")
    end

    for hyperLink, tempLink in pairs(protectLinks) do
        message = gsub(message, EscapeString(hyperLink), tempLink)
    end

    local rebuiltString
    local isFirstWord = true
    for word in gmatch(message, "%s-%S+%s*") do
        if not next(protectLinks) or not protectLinks[gsub(gsub(word, "%s", ""), "|s", " ")] then
            local tempWord = gsub(word, "[%s%p]", "")
            local lowerCaseWord = strlower(tempWord)

            for keyword in pairs(Keywords) do
                if lowerCaseWord == strlower(keyword) or (lowerCaseWord == strlower(myName) and keyword == "%MYNAME%") then
                    word = gsub(word, tempWord, format("|cffFF6600%s|r", tempWord))
                end
            end

            local s = S()
            if s.classColorMentions then
                tempWord = gsub(word, "^[%s%p]-([^%s%p]+)([%-]?[^%s%p]-)[%s%p]*$", "%1%2")
                lowerCaseWord = strlower(tempWord)
                local classMatch = ClassNames[lowerCaseWord]
                if classMatch then
                    local cc = GetClassColorObj(classMatch)
                    if cc then
                        local colored = cc:WrapTextInColorCode(tempWord)
                        if colored then
                            word = gsub(word, gsub(tempWord, "%-", "%%-"), colored)
                        end
                    end
                end
            end
        end

        if isFirstWord then
            rebuiltString = word
            isFirstWord = false
        else
            rebuiltString = rebuiltString .. word
        end
    end

    for hyperLink, tempLink in pairs(protectLinks) do
        rebuiltString = gsub(rebuiltString, EscapeString(tempLink), hyperLink)
        protectLinks[hyperLink] = nil
    end

    return rebuiltString
end

local function FindURL(msg, author, ...)
    local s = S()
    if not s.findURL then
        msg = CheckKeyword(msg, author)
        msg = GetSmileyReplacementText(msg)
        return false, msg, author, ...
    end

    local text, tag = msg, strmatch(msg, "{(.-)}")
    if tag and ICON_TAG_LIST[strlower(tag)] then
        text = gsub(gsub(text, "(%S)({.-})", "%1 %2"), "({.-})(%S)", "%1 %2")
    end

    text = gsub(gsub(text, "(%S)(|c.-|H.-|h.-|h|r)", "%1 %2"), "(|c.-|H.-|h.-|h|r)(%S)", "%1 %2")

    -- URL patterns (TUI_Core style using GetChatLink)
    local newMsg, found
    -- http/https/ftp
    newMsg, found = gsub(text, "(%a+)://(%S+)(%s?)", ReplaceProtocol)
    if found > 0 then return false, GetSmileyReplacementText(CheckKeyword(newMsg, author)), author, ... end
    -- www.example.com
    newMsg, found = gsub(text, "www%.([_A-Za-z0-9-]+)%.(%S+)%s?", GetChatLink("www.%1.%2"))
    if found > 0 then return false, GetSmileyReplacementText(CheckKeyword(newMsg, author)), author, ... end
    -- email
    newMsg, found = gsub(text, "([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?", GetChatLink("%1@%2%3%4"))
    if found > 0 then return false, GetSmileyReplacementText(CheckKeyword(newMsg, author)), author, ... end
    -- IP with port
    newMsg, found = gsub(text, "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)(:%d+)%s?", GetChatLink("%1.%2.%3.%4%5"))
    if found > 0 then return false, GetSmileyReplacementText(CheckKeyword(newMsg, author)), author, ... end
    -- IP
    newMsg, found = gsub(text, "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?", GetChatLink("%1.%2.%3.%4"))
    if found > 0 then return false, GetSmileyReplacementText(CheckKeyword(newMsg, author)), author, ... end

    msg = CheckKeyword(msg, author)
    msg = GetSmileyReplacementText(msg)

    return false, msg, author, ...
end

-- =====================================
-- SPAM THROTTLE
-- =====================================

local function PrepareMessage(author, message)
    if author and author ~= "" and author ~= PLAYER_NAME and message and message ~= "" then
        return strupper(author) .. message
    end
end

local function ChatThrottleHandler(author, message, when)
    local msg = PrepareMessage(author, message)
    if not msg then return end
    for savedMessage, object in pairs(throttle) do
        if difftime(when, object.time) >= 10 then
            throttle[savedMessage] = nil
        end
    end
    if not throttle[msg] then
        throttle[msg] = {time = time(), count = 1}
    else
        throttle[msg].count = throttle[msg].count + 1
    end
end

local function ChatThrottleBlockFlag(author, message, when)
    local msg = PrepareMessage(author, message)
    local object = msg and throttle[msg]
    return object and object.time and object.count and object.count > 1 and (difftime(when, object.time) <= 10), object
end

local function ChatThrottleIntervalHandler(message, author, ...)
    local blockFlag, blockObject = ChatThrottleBlockFlag(author, message, time())
    if blockFlag then
        return true
    else
        if blockObject then blockObject.time = time() end
        return FindURL(message, author, ...)
    end
end

local function HandleChatMessageFilter(_, event, message, author, ...)
    if event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_SAY" then
        return ChatThrottleIntervalHandler(message, author, ...)
    else
        return FindURL(message, author, ...)
    end
end

-- =====================================
-- HYPERLINK TOOLTIP ON HOVER
-- =====================================

local hyperLinkEntered
local function OnHyperlinkEnter(self, refString)
    if InCombatLockdown() then return end
    local linkToken = strmatch(refString, "^([^:]+)")
    if hyperlinkTypes[linkToken] then
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(refString)
        GameTooltip:Show()
        hyperLinkEntered = self
    end
end

local function OnHyperlinkLeave()
    if hyperLinkEntered then
        hyperLinkEntered = nil
        GameTooltip:Hide()
    end
end

local function OnMouseWheel(frame)
    if hyperLinkEntered == frame then
        hyperLinkEntered = false
        GameTooltip:Hide()
    end
end

local function SetupHyperlink()
    for _, frameName in ipairs(CHAT_FRAMES) do
        local frame = _G[frameName]
        local hooked = hooks[frame] and hooks[frame].OnHyperlinkEnter
        if not hooked then
            hooks[frame] = hooks[frame] or {}
            hooks[frame].OnHyperlinkEnter = true
            frame:HookScript("OnHyperlinkEnter", OnHyperlinkEnter)
            frame:HookScript("OnHyperlinkLeave", OnHyperlinkLeave)
            frame:HookScript("OnMouseWheel", OnMouseWheel)
        end
    end
end

-- =====================================
-- LFG ROLE ICONS
-- =====================================

local function CollectLfgRolesForChatIcons()
    if not IsInGroup() then return end
    wipe(lfgRoles)

    local playerRole = UnitGroupRolesAssigned("player")
    if playerRole then
        lfgRoles[PLAYER_NAME] = rolePaths[playerRole]
    end

    local unit = (IsInRaid() and "raid" or "party")
    for i = 1, GetNumGroupMembers() do
        if UnitExists(unit .. i) and not UnitIsUnit(unit .. i, "player") then
            local role = UnitGroupRolesAssigned(unit .. i)
            local name, realm = UnitName(unit .. i)
            if role and name then
                name = (realm and realm ~= "" and name .. "-" .. realm) or name .. "-" .. PLAYER_REALM
                lfgRoles[name] = rolePaths[role]
            end
        end
    end
end

-- =====================================
-- BN FRIEND COLOR
-- =====================================

local function GetBNFriendColor(name, id, useBTag)
    if not name or not id then return name end

    local info = C_BattleNet.GetAccountInfoByID(id)
    local BNET_TAG = info and info.isBattleTagFriend and info.battleTag and strmatch(info.battleTag, "([^#]+)")
    local TAG = useBTag and BNET_TAG

    local Class
    local gameInfo = info and info.gameAccountID and C_BattleNet.GetGameAccountInfoByID(info.gameAccountID)
    if gameInfo and gameInfo.className then
        Class = gameInfo.className
        for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
            if v == Class then Class = k break end
        end
        for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
            if v == Class then Class = k break end
        end
    end

    local Color = Class and GetClassColorObj(Class)
    return (Color and format("|c%s%s|r", Color.colorStr, TAG or name)) or TAG or name, BNET_TAG
end

-- =====================================
-- FADING SYSTEM (TUI_Core style â€” disable Blizzard fading, use custom)
-- =====================================

local function handleChatFrameFadeIn(chatFrame, force)
    local s = S()
    if not s.fade and not force then return end

    local frameName = chatFrame:GetName()

    if chatFrame.copyButton then
        UIFrameFadeIn(chatFrame.copyButton, 0.5, chatFrame.copyButton:GetAlpha(), 0.35)
    end

    local chatTab = _G[frameName .. "Tab"]
    if chatTab then UIFrameFadeIn(chatTab, 0.5, chatTab:GetAlpha(), 1) end
end

local function handleChatFrameFadeOut(chatFrame, force)
    local s = S()
    if not s.fade and not force then return end

    if chatFrame.editboxHasFocus then
        handleChatFrameFadeIn(chatFrame)
        return
    end

    local frameName = chatFrame:GetName()

    if chatFrame.copyButton then
        UIFrameFadeOut(chatFrame.copyButton, 2, chatFrame.copyButton:GetAlpha(), 0)
    end

    local chatTab = _G[frameName .. "Tab"]
    if chatTab then UIFrameFadeOut(chatTab, 2, chatTab:GetAlpha(), 0) end
end

-- =====================================
-- ADD TIMESTAMP & STYLE EDITS TO MESSAGES
-- =====================================

local function AddMessageEdits(frame, msg, alwaysAddTimestamp, isHistory, historyTime)
    local isProtected = ChatFunctions:IsMessageProtected(msg)
    if isProtected or (not isProtected and (strmatch(msg, "^%s*$") or strmatch(msg, "^|Htmtime|h"))) then
        return msg
    end

    local s = S()

    -- Timestamp
    if s.showTimestamp then
        local fmt = s.timestampFormat or "%H:%M"
        local timeStr
        if isHistory and historyTime then
            timeStr = date(fmt, historyTime)
        else
            timeStr = date(fmt)
        end
        msg = format("|cFF999999%s|r %s", timeStr, msg)
    end

    if s.shortChannelNames then
        msg = msg:gsub(" |Hchannel:(.-)|h%[(.-)%]|h", function(channelLink, channelTag)
            return format("|Hchannel:%s|h|cFFD0D0D0[%s]|r|h", channelLink, channelTag)
        end)
        msg = msg:gsub("|h%[(|c(.-)|r)%]|h: ", function(coloredPlayer)
            return format("|h%s|h: ", coloredPlayer)
        end)
    end

    if s.copyChatLines then
        local T = TEX_CHAT:gsub("\\", "/")
        msg = format("|Hcpl:%s|h%s|h %s", frame:GetID(), format("|T%sarrow:14|t", T), msg)
    end

    -- ChatFrameUI text highlighting (MayronUI-style word groups with color + sound)
    if TomoMod_ChatFrameUI and TomoMod_ChatFrameUI.IsActive() and TomoMod_ChatFrameUI.HighlightText then
        msg = TomoMod_ChatFrameUI.HighlightText(msg)
    end

    return msg
end

local function AddMessage(self, msg, infoR, infoG, infoB, infoID, accessID, typeID, event, eventArgs, msgFormatter, isHistory, historyTime)
    local body = AddMessageEdits(self, msg, nil, isHistory, historyTime)
    self.OldAddMessage(self, body, infoR, infoG, infoB, infoID, accessID, typeID, event, eventArgs, msgFormatter)
end

-- =====================================
-- GET PFLAG
-- =====================================

local function GetPFlag(specialFlag, zoneChannelID, unitGUID)
    local flag = ""
    if specialFlag ~= "" then
        if specialFlag == "GM" or specialFlag == "DEV" then
            flag = "|TInterface\\ChatFrame\\UI-ChatIcon-Blizz:12:20:0:0:32:16:4:28:0:16|t "
        elseif specialFlag == "GUIDE" then
            if GetMentorChannelStatus(Enum.PlayerMentorshipStatus.Mentor, C_ChatInfo.GetChannelRulesetForChannelID(zoneChannelID)) == Enum.PlayerMentorshipStatus.Mentor then
                flag = gsub(NPEV2_CHAT_USER_TAG_GUIDE, "(|A.-|a).+", "%1") .. " "
            end
        elseif specialFlag == "NEWCOMER" then
            if GetMentorChannelStatus(Enum.PlayerMentorshipStatus.Newcomer, C_ChatInfo.GetChannelRulesetForChannelID(zoneChannelID)) == Enum.PlayerMentorshipStatus.Newcomer then
                flag = NPEV2_CHAT_USER_TAG_NEWCOMER
            end
        else
            flag = _G["CHAT_FLAG_" .. specialFlag] or ""
        end
    end

    if unitGUID and not issecretvalue(unitGUID) then
        if C_ChatInfo.IsTimerunningPlayer and C_ChatInfo.IsTimerunningPlayer(unitGUID) then
            flag = flag .. format("|A:timerunning-glues-icon-small:%s:%s:0:0|a ", 12, 10)
        end
        if C_RecentAllies and C_RecentAllies.IsRecentAllyByGUID and C_RecentAllies.IsRecentAllyByGUID(unitGUID) then
            flag = flag .. format("|A:friendslist-recentallies-yellow:%s:%s:0:0|a ", 11, 11)
        end
    end

    return flag
end

-- =====================================
-- SHORT CHANNEL NAME
-- =====================================

local function ShortChannel(self)
    return format("|Hchannel:%s|h[%s]|h", self, DEFAULT_STRINGS[strupper(self)] or gsub(self, "channel:", ""))
end

-- =====================================
-- ICON REPLACEMENT
-- =====================================

local seenGroups = {}
local function ChatFrame_ReplaceIconAndGroupExpressions(message, noIconReplacement, noGroupReplacement)
    wipe(seenGroups)

    local ICON_LIST, ICON_TAG_LIST, GROUP_TAG_LIST = _G.ICON_LIST, _G.ICON_TAG_LIST, _G.GROUP_TAG_LIST
    for tag in gmatch(message, "%b{}") do
        local term = strlower(gsub(tag, "[{}]", ""))
        if not noIconReplacement and ICON_TAG_LIST[term] and ICON_LIST[ICON_TAG_LIST[term]] then
            message = gsub(message, tag, ICON_LIST[ICON_TAG_LIST[term]] .. "0|t")
        elseif not noGroupReplacement and GROUP_TAG_LIST[term] then
            local groupIndex = GROUP_TAG_LIST[term]
            if not seenGroups[groupIndex] then
                seenGroups[groupIndex] = true
                local groupList = "["
                for i = 1, GetNumGroupMembers() do
                    local name, _, subgroup, _, _, classFileName = GetRaidRosterInfo(i)
                    if name and subgroup == groupIndex then
                        local cc = GetClassColorObj(classFileName)
                        if cc then name = cc:WrapTextInColorCode(name) end
                        groupList = groupList .. (groupList == "[" and "" or _G.PLAYER_LIST_DELIMITER) .. name
                    end
                end
                if groupList ~= "[" then
                    groupList = groupList .. "]"
                    message = gsub(message, tag, groupList, 1)
                end
            end
        end
    end

    return message
end

-- =====================================
-- FCFManager_GetChatTarget
-- =====================================

local function FCFManager_GetChatTarget(chatGroup, playerTarget, channelTarget)
    local chatTarget
    if chatGroup == "CHANNEL" then
        chatTarget = tostring(channelTarget)
    elseif chatGroup == "WHISPER" or chatGroup == "BN_WHISPER" then
        chatTarget = playerTarget and strupper(playerTarget) or playerTarget
    end
    return chatTarget
end

-- =====================================
-- FLASH TAB (TUI_Core style â€” notify icon flash)
-- =====================================

local function FlashTabIfNotShown(frame, info, chatType, chatGroup, chatTarget)
    if frame:IsShown() then return end
    local allowAlerts = ((frame ~= DEFAULT_CHAT_FRAME and info.flashTab) or (frame == DEFAULT_CHAT_FRAME and info.flashTabOnGeneral)) and ((chatType == "WHISPER" or chatType == "BN_WHISPER") or (CHAT_OPTIONS and not CHAT_OPTIONS.HIDE_FRAME_ALERTS))
    if allowAlerts and not FCFManager_ShouldSuppressMessageFlash(frame, chatGroup, chatTarget) then
        FCF_StartAlertFlash(frame)
    end
end

-- =====================================
-- MESSAGE FORMATTER
-- =====================================

local function MessageFormatter(frame, info, chatType, chatGroup, chatTarget, channelLength, coloredName, historySavedName, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, isHistory, historyTime, historyName, historyBTag)
    local body
    local s = S()

    if chatType == "WHISPER_INFORM" and GMChatFrame_IsGM and GMChatFrame_IsGM(arg2) then return end

    local showLink = true
    local isProtected = ChatFunctions:IsMessageProtected(arg1)
    local bossMonster = strsub(chatType, 1, 9) == "RAID_BOSS" or strsub(chatType, 1, 7) == "MONSTER"
    if bossMonster then
        showLink = false
        if not isProtected then
            arg1 = gsub(arg1, "(%d%s?%%)([^%%%a])", "%1%%%2")
            arg1 = gsub(arg1, "(%d%s?%%)$", "%1%%")
            arg1 = gsub(arg1, "^%%o", "%%s")
            arg1 = gsub(arg1, "^%%bur", "%%s")
        end
    elseif not isProtected then
        arg1 = gsub(arg1, "%%", "%%%%")
    end

    if not isProtected then
        arg1 = RemoveExtraSpaces(arg1)
        if ChatFrameUtil and ChatFrameUtil.CanChatGroupPerformExpressionExpansion then
            arg1 = ChatFrame_ReplaceIconAndGroupExpressions(arg1, arg17, not ChatFrameUtil.CanChatGroupPerformExpressionExpansion(chatGroup))
        else
            arg1 = ChatFrame_ReplaceIconAndGroupExpressions(arg1, arg17, not ChatFrame_CanChatGroupPerformExpressionExpansion(chatGroup))
        end
    end

    if chatType == "BN_WHISPER" or chatType == "BN_WHISPER_INFORM" then
        coloredName = historySavedName or GetBNFriendColor(arg2, arg13)
    end

    local nameWithRealm, realm
    local data = TM_GetPlayerInfoByGUID(arg12)
    if data then
        realm = data.realm
        nameWithRealm = data.nameWithRealm
    end

    local playerLink
    local playerLinkDisplayText = coloredName
    local relevantDefaultLanguage = frame.defaultLanguage
    if chatType == "SAY" or chatType == "YELL" then
        relevantDefaultLanguage = frame.alternativeDefaultLanguage
    end
    local usingDifferentLanguage = (arg3 ~= "") and (arg3 ~= relevantDefaultLanguage)
    local usingEmote = (chatType == "EMOTE") or (chatType == "TEXT_EMOTE")

    if usingDifferentLanguage or not usingEmote then
        playerLinkDisplayText = ("[%s]"):format(coloredName)
    end

    local playerName = (nameWithRealm ~= arg2 and nameWithRealm) or arg2
    if chatType == "COMMUNITIES_CHANNEL" then
        local messageInfo, clubId, streamId = C_Club.GetInfoFromLastCommunityChatLine()
        if messageInfo then
            if arg13 and arg13 ~= 0 then
                playerLink = GetBNPlayerCommunityLink(playerName, playerLinkDisplayText, arg13, clubId, streamId, messageInfo.messageId.epoch, messageInfo.messageId.position)
            else
                playerLink = GetPlayerCommunityLink(playerName, playerLinkDisplayText, clubId, streamId, messageInfo.messageId.epoch, messageInfo.messageId.position)
            end
        else
            playerLink = playerLinkDisplayText
        end
    elseif chatType == "BN_WHISPER" or chatType == "BN_WHISPER_INFORM" then
        playerLink = ChatFunctions:GetBNPlayerLink(playerName, playerLinkDisplayText, arg13, arg11, chatGroup, chatTarget)
    else
        playerLink = ChatFunctions:GetPlayerLink(playerName, playerLinkDisplayText, arg11, chatGroup, chatTarget)
    end

    local isMobile = arg14 and GetMobileEmbeddedTexture(info.r, info.g, info.b)
    local message = format("%s%s", isMobile or "", arg1)

    local pflag = GetPFlag(arg6, arg7, arg12)
    if not bossMonster and arg12 then
        local nameIsSecret = issecretvalue and issecretvalue(playerName)
        local lfgRole = not nameIsSecret and (chatType == "PARTY_LEADER" or chatType == "PARTY" or chatType == "RAID" or chatType == "RAID_LEADER" or chatType == "INSTANCE_CHAT" or chatType == "INSTANCE_CHAT_LEADER") and lfgRoles[playerName]
        if lfgRole then
            pflag = pflag .. lfgRole
        end
    end

    local senderLink = showLink and playerLink or arg2
    if usingDifferentLanguage then
        body = format(_G["CHAT_" .. chatType .. "_GET"] .. "[%s] %s", pflag .. senderLink, arg3, message)
    elseif chatType == "GUILD_ITEM_LOOTED" then
        body = not isProtected and gsub(message, "$s", senderLink, 1) or message
    elseif chatType == "TEXT_EMOTE" then
        local arg2Secret = issecretvalue and issecretvalue(arg2)
        local classLink = realm and playerLink and not isProtected and not arg2Secret and (info.colorNameByClass and gsub(playerLink, "(|h|c.-)|r|h$","%1-" .. realm .. "|r|h") or gsub(playerLink, "(|h.-)|h$","%1-" .. realm .. "|h"))
        if arg2Secret then
            body = message
        else
            body = (classLink and gsub(message, arg2 .. "%-" .. realm, pflag .. classLink, 1)) or ((arg2 ~= senderLink) and gsub(message, arg2, senderLink, 1)) or message
        end
    else
        body = format(_G["CHAT_" .. chatType .. "_GET"], pflag .. senderLink) .. message
    end

    if channelLength > 0 then
        body = "|Hchannel:channel:" .. arg8 .. "|h[" .. ResolvePrefixedChannelName(arg4) .. "]|h " .. body
    end

    if not isProtected and s.shortChannelNames and (chatType ~= "EMOTE" and chatType ~= "TEXT_EMOTE") then
        if chatType == "RAID_LEADER" or chatType == "PARTY_LEADER" or chatType == "INSTANCE_CHAT_LEADER" then
            body = gsub(body, "|Hchannel:(.-)|h%[(.-)%]|h", format("|Hchannel:%s|h[%s]|h", (chatType == "PARTY_LEADER" and "PARTY" or chatType == "RAID_LEADER" and "RAID" or chatType == "INSTANCE_CHAT_LEADER" and "INSTANCE_CHAT"), DEFAULT_STRINGS[strupper(chatType)] or gsub(chatType, "channel:", "")))
        else
            body = gsub(body, "|Hchannel:(.-)|h%[(.-)%]|h", ShortChannel)
        end
        body = gsub(body, "CHANNEL:", "")
        body = gsub(body, "^(.-|h) " .. CHAT_WHISPER_GET:format("~"):gsub("~ ", ""):gsub(": ", ""), "%1")
        body = gsub(body, "^(.-|h) " .. CHAT_SAY_GET:format("~"):gsub("~ ", ""):gsub(": ", ""), "%1")
        body = gsub(body, "^(.-|h) " .. CHAT_YELL_GET:format("~"):gsub("~ ", ""):gsub(": ", ""), "%1")
        body = gsub(body, "<" .. AFK .. ">", "[|cffFF0000" .. AFK .. "|r] ")
        body = gsub(body, "<" .. DND .. ">", "[|cffE7E716" .. DND .. "|r] ")
        body = gsub(body, "^%[" .. RAID_WARNING .. "%]", "[RW]")
    end

    return body
end

-- =====================================
-- MAIN MESSAGE EVENT HANDLER
-- =====================================

local function ChatFrame_GetZoneChannel(frame, index)
    return frame.zoneChannelList[index]
end

local function ChatFrame_MessageEventHandler(frame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, isHistory, historyTime, historyName, historyBTag)
    local notChatHistory, historySavedName
    if isHistory == "TM_ChatHistory" then
        if historyBTag then arg2 = historyBTag end
        historySavedName = historyName
    else
        notChatHistory = true
    end

    if TextToSpeechFrame_MessageEventHandler and notChatHistory then
        TextToSpeechFrame_MessageEventHandler(frame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17)
    end

    if strsub(event, 1, 8) == "CHAT_MSG" then
        if arg16 then return true end

        local chatType = strsub(event, 10)
        local info = ChatTypeInfo[chatType]

        if arg6 == "GM" and chatType == "WHISPER" then return end

        if ChatFrameUtil and ChatFrameUtil.ProcessMessageEventFilters then
            local filtered, new1, new2, new3, new4, new5, new6, new7, new8, new9, new10, new11, new12, new13, new14, new15, new16, new17 = ChatFrameUtil.ProcessMessageEventFilters(frame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17)
            if filtered then
                return true
            else
                arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17 = new1, new2, new3, new4, new5, new6, new7, new8, new9, new10, new11, new12, new13, new14, new15, new16, new17
            end
        else
            local chatFilters = ChatFrame_GetMessageEventFilters(event)
            if chatFilters then
                for _, filterFunc in next, chatFilters do
                    local filter, new1, new2, new3, new4, new5, new6, new7, new8, new9, new10, new11, new12, new13, new14, new15, new16, new17 = filterFunc(frame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17)
                    if filter then
                        return true
                    elseif new1 then
                        arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17 = new1, new2, new3, new4, new5, new6, new7, new8, new9, new10, new11, new12, new13, new14, new15, new16, new17
                    end
                end
            end
        end

        local coloredName = historySavedName or ChatFunctions:GetColoredName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)

        -- Guard secret/tainted values from NPC events (MONSTER_SAY, RAID_BOSS_EMOTE, etc.)
        local isMonsterEvent = strsub(chatType, 1, 7) == "MONSTER" or strsub(chatType, 1, 9) == "RAID_BOSS"
        if isMonsterEvent and issecretvalue then
            if issecretvalue(arg4) then arg4 = "" end
            if issecretvalue(arg9) then arg9 = "" end
        end

        local channelLength = strlen(arg4)
        local infoType = chatType

        if chatType == "VOICE_TEXT" and not GetCVarBool("speechToText") then
            return
        elseif chatType == "COMMUNITIES_CHANNEL" or ((strsub(chatType, 1, 7) == "CHANNEL") and (chatType ~= "CHANNEL_LIST") and ((arg1 ~= "INVITE") or (chatType ~= "CHANNEL_NOTICE_USER"))) then
            if arg1 == "WRONG_PASSWORD" then
                local _, popup = StaticPopup_Visible("CHAT_CHANNEL_PASSWORD")
                if popup and strupper(popup.data) == strupper(arg9) then return end
            end

            local found = false
            for index, value in pairs(frame.channelList) do
                if channelLength > strlen(value) then
                    local match = strupper(value) == strupper(arg9)
                    if not match then
                        local success, zoneChannel = pcall(ChatFrame_GetZoneChannel, frame, index)
                        match = success and arg7 > 0 and arg7 == zoneChannel
                    end
                    if match then
                        found = true
                        infoType = "CHANNEL" .. arg8
                        info = ChatTypeInfo[infoType]
                        if chatType == "CHANNEL_NOTICE" and arg1 == "YOU_LEFT" and frame.zoneChannelList then
                            frame.channelList[index] = nil
                            frame.zoneChannelList[index] = nil
                        end
                        break
                    end
                end
            end

            if not found or not info then
                local eventType, channelID = arg1, arg7
                if not IsChannelRegionalForChannelID or not IsChannelRegionalForChannelID(channelID) then
                    return true
                end
                if frame.AddChannel then
                    if not frame:AddChannel(GetChannelShortcutForChannelID(channelID)) then return true end
                else
                    if not ChatFrame_AddChannel(frame, GetChannelShortcutForChannelID(channelID)) then return true end
                end
            end
        end

        local chatGroup = Chat_GetChatCategory(chatType)
        local chatTarget = FCFManager_GetChatTarget(chatGroup, arg2, arg8)

        if FCFManager_ShouldSuppressMessage(frame, chatGroup, chatTarget) then return true end

        if (chatGroup == "WHISPER" or chatGroup == "BN_WHISPER") then
            local nameLower = strlower(arg2)
            if frame.privateMessageList and not frame.privateMessageList[nameLower] then
                return true
            elseif frame.excludePrivateMessageList and frame.excludePrivateMessageList[nameLower] then
                if GetCVar("whisperMode") ~= "popout_and_inline" then return true end
            end
        end

        if frame.privateMessageList then
            if chatGroup == "SYSTEM" then
                local msg = strlower(arg1 or "")
                local found = false
                if msg ~= "" then
                    for playerName in pairs(frame.privateMessageList) do
                        if msg == strlower(format(ERR_CHAT_PLAYER_NOT_FOUND_S, playerName))
                           or msg == strlower(format(ERR_FRIEND_ONLINE_SS, playerName, playerName))
                           or msg == strlower(format(ERR_FRIEND_OFFLINE_S, playerName)) then
                            found = true
                            break
                        end
                    end
                end
                if not found then return true end
            elseif chatGroup == "BN_INLINE_TOAST_ALERT" or chatGroup == "BN_WHISPER_PLAYER_OFFLINE" then
                local nameLower = strlower(arg2)
                if not frame.privateMessageList[nameLower] then return true end
            end
        end

        if (chatType == "SYSTEM" or chatType == "SKILL" or chatType == "CURRENCY" or chatType == "MONEY" or
            chatType == "OPENING" or chatType == "TRADESKILLS" or chatType == "PET_INFO" or chatType == "TARGETICONS" or chatType == "BN_WHISPER_PLAYER_OFFLINE") then
            frame:AddMessage(arg1, info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
        elseif chatType == "LOOT" then
            frame:AddMessage(arg1, info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
        elseif strsub(chatType, 1, 7) == "COMBAT_" then
            frame:AddMessage(arg1, info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
        elseif strsub(chatType, 1, 6) == "SPELL_" then
            frame:AddMessage(arg1, info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
        elseif strsub(chatType, 1, 10) == "BG_SYSTEM_" then
            frame:AddMessage(arg1, info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
        elseif strsub(chatType, 1, 11) == "ACHIEVEMENT" then
            frame:AddMessage(format(arg1, ChatFunctions:GetPlayerLink(arg2, format("[%s]", coloredName))), info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
        elseif strsub(chatType, 1, 18) == "GUILD_ACHIEVEMENT" then
            frame:AddMessage(format(arg1, ChatFunctions:GetPlayerLink(arg2, format("[%s]", coloredName))), info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
        elseif chatType == "PING" then
            frame:AddMessage(arg1, info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
        elseif chatType == "IGNORED" then
            frame:AddMessage(format(CHAT_IGNORED, arg2), info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
        elseif chatType == "FILTERED" then
            frame:AddMessage(format(CHAT_FILTERED, arg2), info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
        elseif chatType == "RESTRICTED" then
            frame:AddMessage(CHAT_RESTRICTED_TRIAL, info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
        elseif chatType == "CHANNEL_LIST" then
            if channelLength > 0 then
                frame:AddMessage(format(_G["CHAT_" .. chatType .. "_GET"], tonumber(arg8), arg4) .. arg1, info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
            else
                frame:AddMessage(arg1, info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
            end
        elseif chatType == "CHANNEL_NOTICE_USER" then
            local globalstring = _G["CHAT_" .. arg1 .. "_NOTICE_BN"] or _G["CHAT_" .. arg1 .. "_NOTICE"]
            if not globalstring then return end
            if arg5 ~= "" then
                frame:AddMessage(format(globalstring, arg8, arg4, arg2, arg5), info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
            elseif arg1 == "INVITE" then
                frame:AddMessage(format(globalstring, arg4, arg2), info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
            else
                frame:AddMessage(format(globalstring, arg8, arg4, arg2), info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
            end
            if arg1 == "INVITE" and GetCVarBool("blockChannelInvites") then
                frame:AddMessage(CHAT_MSG_BLOCK_CHAT_CHANNEL_INVITE, info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
            end
        elseif chatType == "CHANNEL_NOTICE" then
            if arg1 == "YOU_CHANGED" and C_ChatInfo.GetChannelRuleset and (C_ChatInfo.GetChannelRuleset(arg8) == Enum.ChatChannelRuleset.Mentor) then
                frame:UpdateDefaultChatTarget()
                frame.editBox:UpdateNewcomerEditBoxHint()
            else
                if arg1 == "YOU_LEFT" and frame.editBox and frame.editBox.UpdateNewcomerEditBoxHint then
                    frame.editBox:UpdateNewcomerEditBoxHint(arg8)
                end
                local globalstring = _G["CHAT_" .. arg1 .. "_NOTICE_TRIAL"] or _G["CHAT_" .. arg1 .. "_NOTICE_BN"] or _G["CHAT_" .. arg1 .. "_NOTICE"]
                if not globalstring then return end
                local accessID = ChatFunctions:GetAccessID(chatGroup, arg8)
                local typeID = ChatFunctions:GetAccessID(infoType, arg8, arg12)
                frame:AddMessage(format(globalstring, arg8, ResolvePrefixedChannelName(arg4)), info.r, info.g, info.b, info.id, accessID, typeID, nil, nil, nil, isHistory, historyTime)
            end
        elseif chatType == "BN_INLINE_TOAST_ALERT" then
            if issecretvalue(arg1) then return end
            local globalstring = _G["BN_INLINE_TOAST_" .. arg1]
            if not globalstring then return end
            local message
            if arg1 == "FRIEND_REQUEST" then
                message = globalstring
            elseif arg1 == "FRIEND_PENDING" then
                message = format(BN_INLINE_TOAST_FRIEND_PENDING, BNGetNumFriendInvites())
            elseif arg1 == "FRIEND_REMOVED" or arg1 == "BATTLETAG_FRIEND_REMOVED" then
                message = format(globalstring, arg2)
            elseif arg1 == "FRIEND_ONLINE" or arg1 == "FRIEND_OFFLINE" then
                local accountInfo = C_BattleNet.GetAccountInfoByID(arg13)
                local gameInfo = accountInfo and accountInfo.gameAccountInfo
                if accountInfo and gameInfo and gameInfo.clientProgram and gameInfo.clientProgram ~= "" then
                    local clientTexture = GetClientTexture and GetClientTexture(gameInfo.clientProgram, 14)
                    local charName = BNet_GetValidatedCharacterName and BNet_GetValidatedCharacterName(gameInfo.characterName, accountInfo.battleTag, gameInfo.clientProgram) or ""
                    local linkDisplayText = format("[%s] (%s%s)", arg2, clientTexture or "", charName)
                    local playerLink = ChatFunctions:GetBNPlayerLink(arg2, linkDisplayText, arg13, arg11, chatGroup, 0)
                    message = format(globalstring, playerLink)
                else
                    local linkDisplayText = format("[%s]", arg2)
                    local playerLink = ChatFunctions:GetBNPlayerLink(arg2, linkDisplayText, arg13, arg11, chatGroup, 0)
                    message = format(globalstring, playerLink)
                end
            else
                local linkDisplayText = format("[%s]", arg2)
                local playerLink = ChatFunctions:GetBNPlayerLink(arg2, linkDisplayText, arg13, arg11, chatGroup, 0)
                message = format(globalstring, playerLink)
            end
            frame:AddMessage(message, info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
        elseif chatType == "BN_INLINE_TOAST_BROADCAST" then
            if arg1 and arg1 ~= "" then
                arg1 = RemoveNewlines(RemoveExtraSpaces(arg1))
                local linkDisplayText = ("[%s]"):format(arg2)
                local playerLink = ChatFunctions:GetBNPlayerLink(arg2, linkDisplayText, arg13, arg11, chatGroup, 0)
                frame:AddMessage(format(BN_INLINE_TOAST_BROADCAST, playerLink, arg1), info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
            end
        elseif chatType == "BN_INLINE_TOAST_BROADCAST_INFORM" then
            if arg1 and arg1 ~= "" then
                frame:AddMessage(BN_INLINE_TOAST_BROADCAST_INFORM, info.r, info.g, info.b, info.id, nil, nil, nil, nil, nil, isHistory, historyTime)
            end
        else
            local isChatLineCensored, eventArgs, msgFormatter = C_ChatInfo.IsChatLineCensored(arg11)
            if isChatLineCensored then
                eventArgs = SafePack(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17)
                msgFormatter = function(msg)
                    local body = MessageFormatter(frame, info, chatType, chatGroup, chatTarget, channelLength, coloredName, historySavedName, msg, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, isHistory, historyTime, historyName, historyBTag)
                    return AddMessageEdits(frame, body, false, isHistory, historyTime)
                end
            end

            local accessID = ChatFunctions:GetAccessID(chatGroup, chatTarget)
            local typeID = ChatFunctions:GetAccessID(infoType, chatTarget, arg12 or arg13)
            local body = isChatLineCensored and arg1 or MessageFormatter(frame, info, chatType, chatGroup, chatTarget, channelLength, coloredName, historySavedName, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, isHistory, historyTime, historyName, historyBTag)

            frame:AddMessage(body, info.r, info.g, info.b, info.id, accessID, typeID, event, eventArgs, msgFormatter, isHistory, historyTime)
        end

        if notChatHistory and (chatType == "WHISPER" or chatType == "BN_WHISPER") then
            ChatEdit_SetLastTellTarget(arg2, chatType)
            FlashClientIcon()
        end

        if notChatHistory then
            FlashTabIfNotShown(frame, info, chatType, chatGroup, chatTarget)
        end

        return true
    elseif event == "VOICE_CHAT_CHANNEL_TRANSCRIBING_CHANGED" then
        if not frame.isTranscribing and arg2 then
            local infoSys = _G.ChatTypeInfo.SYSTEM
            frame:AddMessage(_G.SPEECH_TO_TEXT_STARTED, infoSys.r, infoSys.g, infoSys.b, infoSys.id, nil, nil, nil, nil, nil, isHistory, historyTime)
        end
        frame.isTranscribing = arg2
    end
end

-- =====================================
-- ON EVENT WRAPPERS
-- =====================================

local function ChatFrame_ConfigEventHandler(...)
    local handler = _G.ChatFrameMixin and _G.ChatFrameMixin.ConfigEventHandler or _G.ChatFrame_ConfigEventHandler
    return handler(...)
end

local function ChatFrame_SystemEventHandler(...)
    local handler = _G.ChatFrameMixin and _G.ChatFrameMixin.SystemEventHandler or _G.ChatFrame_SystemEventHandler
    return handler(...)
end

local function ChatFrame_OnEvent(frame, ...)
    if frame.customEventHandler and frame:customEventHandler(...) then return end
    if ChatFrame_ConfigEventHandler(frame, ...) then return end
    if ChatFrame_SystemEventHandler(frame, ...) then return end
    if ChatFrame_MessageEventHandler(frame, ...) then return end
end

local function FloatingChatFrameOnEvent(...)
    ChatFrame_OnEvent(...)
    if _G.FloatingChatFrame_OnEvent then _G.FloatingChatFrame_OnEvent(...) end
end

-- =====================================
-- MOUSE SCROLL (TUI_Core style â€” Ctrl=top/bottom, Shift=page)
-- =====================================

local function ChatFrame_OnMouseScroll(self, delta)
    if IsControlKeyDown() then
        if delta > 0 then self:ScrollToTop() else self:ScrollToBottom() end
    elseif IsShiftKeyDown() then
        if delta > 0 then self:PageUp() else self:PageDown() end
    else
        local numScrollMessages = 3
        if delta < 0 then
            for _ = 1, numScrollMessages do self:ScrollDown() end
        else
            for _ = 1, numScrollMessages do self:ScrollUp() end
        end
    end
end

local function ChatFrame_SetScript(self, script, func)
    if script == "OnMouseWheel" and func ~= ChatFrame_OnMouseScroll then
        self:SetScript(script, ChatFrame_OnMouseScroll)
    end
end

-- =====================================
-- EDIT BOX HISTORY
-- =====================================

local function EditBoxOnKeyDown(self, key)
    local lines = self.historyLines
    if not lines then return end
    if IsAltKeyDown() then return end
    local maxLines = #lines
    if maxLines == 0 then return end
    if key == "DOWN" then
        self.historyIndex = self.historyIndex - 1
        if self.historyIndex < 1 then
            self.historyIndex = 0
            self:SetText("")
            return
        end
    elseif key == "UP" then
        self.historyIndex = self.historyIndex + 1
        if self.historyIndex > maxLines then
            self.historyIndex = maxLines end
    else
        return
    end
    local historyLine = maxLines - (self.historyIndex - 1)
    local historyText = lines[historyLine]
    if historyText then self:SetText(historyText) end
end

local function ChatEdit_AddHistory(self, line)
    local lines = self.historyLines
    local msg = lines and line and strtrim(line)
    if not msg or strlen(msg) <= 0 then return end
    local cmd = strmatch(msg, "^/%w+")
    if cmd and IsSecureCmd(cmd) then return end
    for index, text in pairs(lines) do
        if text == msg then tremove(lines, index) break end
    end
    tinsert(lines, msg)
    if #lines > 20 then tremove(lines, 1) end
end

-- =====================================
-- EDIT BOX TEXT CHANGED
-- =====================================

do
    local charCount
    local function CountLinkCharacters(self)
        charCount = charCount + (strlen(self) + 4)
    end

    function CFS._EditBoxOnTextChanged(self, userInput)
        local text = self:GetText()
        local len = strlen(text)
        charCount = 0
        gsub(text, "(|c%x-|H.-|h).-|h|r", CountLinkCharacters)
        if charCount ~= 0 then len = len - charCount end
        if self.characterCount then
            self.characterCount:SetText(len > 0 and (255 - len) or "")
        end
    end
end

-- =====================================
-- GET TAB
-- =====================================

local function GetTab(chat)
    if not chat.tab then
        chat.tab = _G[format("ChatFrame%sTab", chat:GetID())]
    end
    return chat.tab
end

-- =====================================
-- TUI_Core SIDEBAR ICONS
-- =====================================

local sidebarIcons = {}

local function PositionSideBarIcon(iconFrame, anchor, offsetY)
    iconFrame:ClearAllPoints()
    if anchor then
        iconFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    else
        iconFrame:SetPoint("TOPLEFT", iconFrame:GetParent(), "TOPLEFT", 1, offsetY or -14)
    end
    iconFrame:SetSize(24, 24)
    iconFrame:Show()
end

local function CreateSideBarIcon_CopyChat(parent)
    local T = TEX_CHAT:gsub("\\", "/")
    local btn = CreateFrame("Button", "TomoMod_SideIcon_CopyChat", parent)
    btn:SetNormalTexture(T .. "copyIcon")
    btn:GetNormalTexture():SetVertexColor(0.9, 0.8, 0.0)
    btn:SetHighlightAtlas("chatframe-button-highlight")

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Copy Chat Text")
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    btn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        if not TomoModCopyChatFrame then return end
        if not TomoModCopyChatFrame:IsShown() then
            local count = getLines(ChatFrame1)
            local text = table.concat(copyLines, " \n", 1, count)
            TomoModCopyChatFrameEditBox:SetText(text)
            TomoModCopyChatFrame:Show()
        else
            TomoModCopyChatFrameEditBox:SetText("")
            TomoModCopyChatFrame:Hide()
        end
    end)

    return btn
end

local function CreateSideBarIcon_Emotes(parent)
    local T = TEX_CHAT:gsub("\\", "/")
    local btn = CreateFrame("Button", "TomoMod_SideIcon_Emotes", parent)
    btn:SetNormalTexture(T .. "speechIcon")
    btn:GetNormalTexture():SetVertexColor(0.9, 0.8, 0.0)
    btn:SetHighlightAtlas("chatframe-button-highlight")

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Show Chat Menu")
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    btn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        if ChatMenu then
            if ChatMenu:IsShown() then ChatMenu:Hide() else ChatMenu:Show() end
        else
            ChatFrame_OpenChat("/emote ")
        end
    end)

    return btn
end

local function CreateSideBarIcon_Professions(parent)
    local T = TEX_CHAT:gsub("\\", "/")
    local btn = CreateFrame("Button", "TomoMod_SideIcon_Professions", parent)
    btn:SetNormalTexture(T .. "book")
    btn:GetNormalTexture():SetVertexColor(0.9, 0.8, 0.0)
    btn:SetHighlightAtlas("chatframe-button-highlight")

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Loot Browser")
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    btn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        if SlashCmdList["TOMOMOD"] then
            SlashCmdList["TOMOMOD"]("loot")
        end
    end)

    return btn
end

local function CreateSideBarIcon_Shortcuts(parent)
    local T = TEX_CHAT:gsub("\\", "/")
    local btn = CreateFrame("Button", "TomoMod_SideIcon_Shortcuts", parent)
    btn:SetNormalTexture(T .. "shortcuts")
    btn:GetNormalTexture():SetVertexColor(0.9, 0.8, 0.0)
    btn:SetHighlightAtlas("chatframe-button-highlight")

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Addon Shortcuts")
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local menu
    btn:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        if not menu then
            menu = CreateFrame("Frame", "TomoMod_ShortcutsMenu", self, "BackdropTemplate")
            menu:SetSize(140, 52)
            menu:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 12,
                insets = { left = 2, right = 2, top = 2, bottom = 2 },
            })
            menu:SetBackdropColor(0.05, 0.05, 0.05, 0.92)
            menu:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            menu:SetFrameStrata("TOOLTIP")

            local items = {
                { text = "TomoMod Config", func = function() SlashCmdList["TOMOMOD"]("config") end },
                { text = "Reload UI",      func = ReloadUI },
            }
            for idx, item in ipairs(items) do
                local b = CreateFrame("Button", nil, menu)
                b:SetSize(136, 22)
                b:SetPoint("TOPLEFT", menu, "TOPLEFT", 2, -2 - (idx - 1) * 24)
                b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
                local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                fs:SetPoint("LEFT", 6, 0)
                fs:SetText(item.text)
                fs:SetTextColor(1, 1, 1)
                b:SetScript("OnClick", function() item.func(); menu:Hide() end)
            end
            menu:Hide()
        end
        menu:SetShown(not menu:IsShown())
        if menu:IsShown() then
            menu:ClearAllPoints()
            menu:SetPoint("TOPLEFT", self, "TOPRIGHT", 4, 0)
        end
    end)

    return btn
end

local function CreateSideBarIcon_PlayerStatus(parent)
    local btn = CreateFrame("Button", "TomoMod_SideIcon_Status", parent)
    btn:SetHighlightAtlas("chatframe-button-highlight")

    local function UpdateStatusIcon()
        local status = FRIENDS_TEXTURE_ONLINE
        local _, _, _, _, bnetAFK, bnetDND = BNGetInfo()
        if bnetAFK then
            status = FRIENDS_TEXTURE_AFK
        elseif bnetDND then
            status = FRIENDS_TEXTURE_DND
        end
        btn:SetNormalTexture(status)
    end
    UpdateStatusIcon()

    btn:RegisterEvent("BN_INFO_CHANGED")
    btn:SetScript("OnEvent", UpdateStatusIcon)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("AFK")
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    btn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        SendChatMessage("", "AFK")
    end)

    return btn
end

local function SetupSideBarIcons(container, sidebarTexture)
    local topIcons = {
        CreateSideBarIcon_Professions(container),
        CreateSideBarIcon_Shortcuts(container),
    }
    local midIcons = {
        CreateSideBarIcon_PlayerStatus(container),
        CreateSideBarIcon_CopyChat(container),
    }

    -- Top group: anchored to top of sidebar
    local prev = nil
    local idx = 1
    for _, icon in ipairs(topIcons) do
        if not prev then
            icon:ClearAllPoints()
            icon:SetPoint("TOPLEFT", sidebarTexture, "TOPLEFT", 0, -14)
            icon:SetSize(24, 24)
            icon:Show()
        else
            PositionSideBarIcon(icon, prev, -14)
        end
        prev = icon
        sidebarIcons[idx] = icon
        idx = idx + 1
    end

    -- Middle group: centered vertically in the sidebar
    local sH = sidebarTexture:GetHeight() or 300
    local groupH = #midIcons * 24 + (#midIcons - 1) * 2
    local startY = -(sH / 2) + (groupH / 2)

    prev = nil
    for _, icon in ipairs(midIcons) do
        if not prev then
            icon:ClearAllPoints()
            icon:SetPoint("TOPLEFT", sidebarTexture, "TOPLEFT", 0, startY)
            icon:SetSize(24, 24)
            icon:Show()
        else
            PositionSideBarIcon(icon, prev)
        end
        prev = icon
        sidebarIcons[idx] = icon
        idx = idx + 1
    end
end

-- =====================================
-- SKIN STYLE BUILDERS
-- =====================================

-- [PERF] Each of the 4 skin builders (TUI, Classic, Glass, Minimal) attaches an
-- OnUpdate to `container` that re-anchors and resizes it to match ChatFrame1 every
-- frame. Without dirty-check, that's 5+ frame API calls at 60 FPS even when the
-- chat window hasn't moved or resized — which is >99% of the time.
--
-- This helper wraps the pattern: it caches ChatFrame1's width+height, compares on
-- each tick, and only runs the updater when something actually changed. It also
-- keeps the re-anchor call inside the updater (not run every tick) because
-- SetPoint anchors auto-follow position changes — re-anchoring is only needed
-- to recover from our own state being cleared.
local function AttachChatFollowOnUpdate(container, updater)
    container._cf1w = -1  -- force first run
    container._cf1h = -1
    container:SetScript("OnUpdate", function(self)
        if not ChatFrame1 then return end
        local w = ChatFrame1:GetWidth()
        local h = ChatFrame1:GetHeight()
        if w == self._cf1w and h == self._cf1h then return end  -- [PERF] early-out
        self._cf1w = w
        self._cf1h = h
        updater(self, w, h)
    end)
end

-- Skin: TUI (current sidebar + window textures)
local function ApplySkin_TUI(container, T, s)
    -- Sidebar texture
    if not container.sidebar then
        container.sidebar = container:CreateTexture(nil, "ARTWORK")
    end
    container.sidebar:SetTexture(T .. "sidebar")
    container.sidebar:SetSize(24, 300)
    container.sidebar:ClearAllPoints()
    container.sidebar:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -10)
    container.sidebar:Show()

    -- Window texture
    if not container.window then
        container.window = CreateFrame("Frame", nil, container)
        container.window.texture = container.window:CreateTexture(nil, "ARTWORK")
        container.window.texture:SetAllPoints(true)
    end
    container.window:ClearAllPoints()
    container.window:SetSize(367, 248)
    container.window:SetPoint("TOPLEFT", container.sidebar, "TOPRIGHT", 2, -37)
    container.window.texture:SetTexture(T .. "window")
    container.window.texture:SetAlpha(s.bgAlpha or 0.70)
    container.window:Show()

    -- Tab bar texture
    if not container.tabsTex then
        container.tabsTex = container:CreateTexture(nil, "ARTWORK")
    end
    container.tabsTex:SetTexture(T .. "tabs")
    container.tabsTex:SetSize(358, 23)
    container.tabsTex:ClearAllPoints()
    container.tabsTex:SetPoint("TOPLEFT", container.sidebar, "TOPRIGHT", 0, -12)
    container.tabsTex:Show()

    -- Hide non-TUI elements
    if container.bgFrame then container.bgFrame:Hide() end

    -- Setup sidebar icons
    SetupSideBarIcons(container, container.sidebar)

    -- OnUpdate: follow ChatFrame1
    AttachChatFollowOnUpdate(container, function(self, w, h)
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", ChatFrame1, "TOPLEFT", -34, 25)
        self:SetHeight(h + 55)
        self:SetWidth(w + 48)
        self.sidebar:SetHeight(h + 30)
        self.window:SetSize(w + 10, h - 20)
    end)
end

-- Skin: Classic (old-style framed look, like the screenshot)
local function ApplySkin_Classic(container, T, s)
    -- Hide TUI-specific elements
    if container.sidebar then container.sidebar:Hide() end
    if container.tabsTex then container.tabsTex:Hide() end

    -- Background frame with classic border
    if not container.bgFrame then
        container.bgFrame = CreateFrame("Frame", nil, container, "BackdropTemplate")
    end
    local bg = container.bgFrame
    bg:ClearAllPoints()
    bg:SetAllPoints(container)
    bg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    bg:SetBackdropColor(0.06, 0.06, 0.08, s.bgAlpha or 0.70)
    bg:SetBackdropBorderColor(0.65, 0.55, 0.35, 1)
    bg:Show()

    -- Inner gradient overlay
    if not bg.gradient then
        bg.gradient = bg:CreateTexture(nil, "ARTWORK")
    end
    bg.gradient:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg.gradient:SetPoint("TOPLEFT", bg, "TOPLEFT", 4, -4)
    bg.gradient:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -4, 4)
    if bg.gradient.SetGradient then
        bg.gradient:SetGradient("VERTICAL", CreateColor(0.02, 0.02, 0.04, 0.6), CreateColor(0.08, 0.06, 0.12, 0.3))
    end
    bg.gradient:Show()

    -- Window (used for alpha tracking)
    if not container.window then
        container.window = CreateFrame("Frame", nil, container)
        container.window.texture = container.window:CreateTexture(nil, "ARTWORK")
        container.window.texture:SetAllPoints(true)
    end
    container.window:Hide()

    -- Hide sidebar icons
    for _, icon in ipairs(sidebarIcons) do
        if icon then icon:Hide() end
    end

    -- OnUpdate: follow ChatFrame1
    AttachChatFollowOnUpdate(container, function(self, w, h)
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", ChatFrame1, "TOPLEFT", -6, 18)
        self:SetHeight(h + 30)
        self:SetWidth(w + 12)
    end)
end

-- Skin: Glass (frosted glass look)
local function ApplySkin_Glass(container, T, s)
    -- Hide TUI-specific elements
    if container.sidebar then container.sidebar:Hide() end
    if container.tabsTex then container.tabsTex:Hide() end

    -- Background frame with glass effect
    if not container.bgFrame then
        container.bgFrame = CreateFrame("Frame", nil, container, "BackdropTemplate")
    end
    local bg = container.bgFrame
    bg:ClearAllPoints()
    bg:SetAllPoints(container)
    bg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    bg:SetBackdropColor(0.08, 0.10, 0.14, s.bgAlpha or 0.70)
    bg:SetBackdropBorderColor(0.047, 0.824, 0.624, 0.5)  -- accent teal border
    bg:Show()

    -- Inner gradient
    if not bg.gradient then
        bg.gradient = bg:CreateTexture(nil, "ARTWORK")
    end
    bg.gradient:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg.gradient:SetPoint("TOPLEFT", bg, "TOPLEFT", 1, -1)
    bg.gradient:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -1, 1)
    if bg.gradient.SetGradient then
        bg.gradient:SetGradient("VERTICAL", CreateColor(0.05, 0.12, 0.15, 0.45), CreateColor(0.02, 0.04, 0.06, 0.25))
    end
    bg.gradient:Show()

    -- Top accent line
    if not bg.topLine then
        bg.topLine = bg:CreateTexture(nil, "OVERLAY")
    end
    bg.topLine:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg.topLine:SetHeight(2)
    bg.topLine:SetPoint("TOPLEFT", bg, "TOPLEFT", 1, -1)
    bg.topLine:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -1, -1)
    bg.topLine:SetColorTexture(0.047, 0.824, 0.624, 0.7)
    bg.topLine:Show()

    -- Window (used for alpha tracking)
    if not container.window then
        container.window = CreateFrame("Frame", nil, container)
        container.window.texture = container.window:CreateTexture(nil, "ARTWORK")
        container.window.texture:SetAllPoints(true)
    end
    container.window:Hide()

    -- Hide sidebar icons
    for _, icon in ipairs(sidebarIcons) do
        if icon then icon:Hide() end
    end

    AttachChatFollowOnUpdate(container, function(self, w, h)
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", ChatFrame1, "TOPLEFT", -4, 14)
        self:SetHeight(h + 22)
        self:SetWidth(w + 8)
    end)
end

-- Skin: Minimal (no border, flat dark bg)
local function ApplySkin_Minimal(container, T, s)
    -- Hide TUI-specific elements
    if container.sidebar then container.sidebar:Hide() end
    if container.tabsTex then container.tabsTex:Hide() end

    -- Background frame
    if not container.bgFrame then
        container.bgFrame = CreateFrame("Frame", nil, container, "BackdropTemplate")
    end
    local bg = container.bgFrame
    bg:ClearAllPoints()
    bg:SetAllPoints(container)
    bg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    bg:SetBackdropColor(0.04, 0.04, 0.06, s.bgAlpha or 0.70)
    bg:Show()

    -- Hide gradient if it existed from another skin
    if bg.gradient then bg.gradient:Hide() end
    if bg.topLine then bg.topLine:Hide() end

    -- Window (used for alpha tracking)
    if not container.window then
        container.window = CreateFrame("Frame", nil, container)
        container.window.texture = container.window:CreateTexture(nil, "ARTWORK")
        container.window.texture:SetAllPoints(true)
    end
    container.window:Hide()

    -- Hide sidebar icons
    for _, icon in ipairs(sidebarIcons) do
        if icon then icon:Hide() end
    end

    AttachChatFollowOnUpdate(container, function(self, w, h)
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", ChatFrame1, "TOPLEFT", -2, 14)
        self:SetHeight(h + 18)
        self:SetWidth(w + 4)
    end)
end

-- Dispatch skin application
local skinApplicators = {
    tui     = ApplySkin_TUI,
    classic = ApplySkin_Classic,
    glass   = ApplySkin_Glass,
    minimal = ApplySkin_Minimal,
}

local function ApplyContainerSkin(container, T, s)
    local style = s.skinStyle or "tui"
    local applicator = skinApplicators[style] or skinApplicators.tui
    applicator(container, T, s)
end

-- =====================================
-- MOVER INTEGRATION — lock/unlock chat frame position
-- =====================================

local chatIsLocked = true
local chatMoverOverlay = nil

-- Minimum X offset for ChatFrame1 to keep the TUI sidebar (32 px) on-screen.
-- Other skins add at most 4 px, so 2 is fine for them.
local function GetSidebarMinX()
    local style = S().skinStyle or "tui"
    return (style == "tui") and 34 or 2
end

local function SaveChatPosition()
    if not ChatFrame1 then return end
    -- GetLeft/GetBottom always return UIParent-relative screen coords,
    -- independent of whatever frame ChatFrame1 is internally anchored to.
    local x = ChatFrame1:GetLeft()
    local y = ChatFrame1:GetBottom()
    if not x then return end
    local s = S()
    s.position = {
        anchor = "BOTTOMLEFT",
        relTo  = "BOTTOMLEFT",
        x      = x,
        y      = y,
    }
end

local function RestoreChatPosition()
    if not ChatFrame1 then return end
    local s = S()
    local pos = s.position
    local minX = GetSidebarMinX()
    local x = pos and pos.x or minX
    local y = pos and pos.y or 200
    -- Clamp: TUI sidebar extends 32 px left of ChatFrame1; must not go off-screen.
    x = math.max(x, minX)
    -- Do NOT call SetUserPlaced(true) — it lets WoW's layout system save its own
    -- version of the position and restore it on the next reload, fighting our save.
    ChatFrame1:ClearAllPoints()
    ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
end

function CFS.IsLocked()
    return chatIsLocked
end

function CFS.ToggleLock()
    chatIsLocked = not chatIsLocked
    if chatIsLocked then
        -- lock
        if chatMoverOverlay then chatMoverOverlay:Hide() end
        ChatFrame1:SetMovable(false)
        SaveChatPosition()
    else
        -- unlock
        ChatFrame1:SetMovable(true)
        -- Create mover overlay for visual feedback
        if not chatMoverOverlay then
            chatMoverOverlay = CreateFrame("Frame", "TomoMod_ChatMoverOverlay", ChatFrame1, "BackdropTemplate")
            chatMoverOverlay:SetAllPoints(ChatFrame1)
            chatMoverOverlay:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            chatMoverOverlay:SetBackdropColor(0.047, 0.824, 0.624, 0.15)
            chatMoverOverlay:SetBackdropBorderColor(0.047, 0.824, 0.624, 0.8)
            chatMoverOverlay:SetFrameStrata("HIGH")
            chatMoverOverlay:EnableMouse(true)
            chatMoverOverlay:RegisterForDrag("LeftButton")

            local label = chatMoverOverlay:CreateFontString(nil, "OVERLAY")
            label:SetFont(ADDON_FONT_BOLD, 14, "OUTLINE")
            label:SetPoint("CENTER")
            label:SetText("Chat Frame")
            label:SetTextColor(0.047, 0.824, 0.624, 1)

            chatMoverOverlay:SetScript("OnDragStart", function()
                ChatFrame1:StartMoving()
            end)
            chatMoverOverlay:SetScript("OnDragStop", function()
                ChatFrame1:StopMovingOrSizing()
                SaveChatPosition()
            end)
        end
        chatMoverOverlay:Show()
    end
end

-- =====================================
-- STYLE CHAT WINDOW (TUI_Core visual style)
-- =====================================

local function styleChatWindow(frame)
    local name = frame:GetName()
    local tab = GetTab(frame)
    local s = S()
    local T = TEX_CHAT:gsub("\\", "/")

    tab.Text:SetFont(ADDON_FONT_BOLD, (s.fontSize or 13), "")
    tab.Text:SetTextColor(1, 1, 1)

    if frame.styled then return end
    frame:SetFrameLevel(4)

    local id = frame:GetID()
    local _, fontSize, _, _, _, _, _, _, isDocked = GetChatWindowInfo(id)

    local editbox = frame.editBox
    local scrollBar = frame.ScrollBar
    local scrollToBottom = frame.ScrollToBottomButton

    -- =============================================
    -- SKINNED CONTAINER (dispatches to selected skin style)
    -- Skip when ChatFrameUI is active (it manages its own containers)
    -- =============================================
    if not frame.tuiContainer and id == 1 and not (TomoMod_ChatFrameUI and TomoMod_ChatFrameUI.IsActive()) then
        local container = CreateFrame("Frame", "TomoMod_ChatContainer", UIParent)
        container:SetFrameStrata("LOW")
        container:SetFrameLevel(1)
        container:SetSize(358, 310)
        container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 2, -2)

        frame.tuiContainer = container

        -- Apply the selected skin
        ApplyContainerSkin(container, T, s)
    end

    -- Kill Blizzard frame textures
    StripTextures(frame)
    _G[name .. "ButtonFrame"]:Hide()

    -- Kill tab textures (TUI_Core style)
    local killTexNames = {
        "TabSelectedLeft", "TabSelectedMiddle", "TabSelectedRight",
        "TabLeft", "TabMiddle", "TabRight",
        "TabHighlightLeft", "TabHighlightMiddle", "TabHighlightRight",
    }
    for _, texName in pairs(killTexNames) do
        local tex = _G[name .. texName]
        if tex then
            tex:SetTexture(nil)
            tex:SetAlpha(0)
        end
    end

    -- Tab styling (TUI_Core style â€” class color on inactive, white on active)
    tab:SetHeight(16)
    tab:SetFrameStrata("MEDIUM")

    local tabLabel = tab:GetFontString()
    if tabLabel then
        tabLabel:ClearAllPoints()
        tabLabel:SetPoint("CENTER", tab, "CENTER")
    end

    tab:DisableDrawLayer("BACKGROUND")
    tab:DisableDrawLayer("BORDER")
    tab:DisableDrawLayer("HIGHLIGHT")

    hooksecurefunc(tab, "SetAlpha", function(t, alpha)
        if alpha ~= 1 and (not t.isDocked or GeneralDockManager.selected:GetID() == t:GetID()) then
            t:SetAlpha(1)
        elseif alpha < 0.6 then
            t:SetAlpha(0.6)
        end
    end)

    tab.Text:SetTextColor(1, 1, 1)
    hooksecurefunc(tab.Text, "SetTextColor", function(tt, r, g, b)
        if r ~= 1 or g ~= 1 or b ~= 1 then
            tt:SetTextColor(1, 1, 1)
        end
    end)

    -- =============================================
    -- SCROLL BAR THEMING (TUI_Core style)
    -- =============================================
    if scrollBar then
        scrollBar:SetPoint("TOPLEFT", frame, "TOPRIGHT", 1, 0)

        local thumb = scrollBar.ThumbTexture or (scrollBar.GetThumb and scrollBar:GetThumb())
        local track = scrollBar.Track or (scrollBar.GetTrack and scrollBar:GetTrack())

        if track then
            if track.DisableDrawLayer then track:DisableDrawLayer("ARTWORK") end
        end

        if thumb then
            thumb:SetSize(8, 34)
            -- Use a theme color for the scroll bar thumb
            local r, g, b = 0.6, 0.4, 0.8
            if thumb:GetObjectType() == "Button" then
                KillElement(scrollBar.Forward)
                KillElement(scrollBar.Back)
                if thumb.Begin then KillElement(thumb.Begin) end
                if thumb.Middle then KillElement(thumb.Middle) end
                if thumb.End then KillElement(thumb.End) end
                local reskin = thumb:CreateTexture(nil, "BACKGROUND")
                reskin:SetColorTexture(r * 0.8, g * 0.8, b * 0.8)
                reskin:SetAllPoints(true)
            elseif thumb:GetObjectType() == "Texture" then
                thumb:SetColorTexture(r * 0.8, g * 0.8, b * 0.8)
            end
        end

        scrollBar:SetAlpha(0)
    end

    -- Scroll-to-bottom button (TUI_Core style â€” icon-based)
    if scrollToBottom then
        scrollToBottom:DisableDrawLayer("OVERLAY")
        scrollToBottom:SetSize(24, 21)
        scrollToBottom:SetPoint("BOTTOMRIGHT", frame.ResizeButton, "TOPRIGHT", 0, -2)

        if scrollToBottom.Flash then scrollToBottom.Flash:SetAlpha(0) end
    end

    -- OnScrollChanged callback (TUI_Core style â€” show/hide scroll indicator)
    if frame.SetOnScrollChangedCallback then
        frame:SetOnScrollChangedCallback(function(self, offset)
            if self.ScrollBar then
                if self.ScrollBar.SetValue then
                    self.ScrollBar:SetValue(self:GetNumMessages() - offset)
                end
                self.ScrollBar:SetAlpha(offset > 0 and 1 or 0)
            end
            local downBtn = self.ScrollToBottomButton
            if downBtn then
                downBtn:SetAlpha(offset > 0 and 1 or 0)
            end
        end)
    end

    -- =============================================
    -- EDIT BOX STYLING (TUI_Core style â€” backdrop)
    -- =============================================
    frame:SetClampRectInsets(0, 0, 0, 0)
    frame:SetClampedToScreen(false)

    -- Strip editbox focus textures
    local a, b, c = select(6, editbox:GetRegions())
    if a and a.SetAlpha then a:SetAlpha(0) end
    if b and b.SetAlpha then b:SetAlpha(0) end
    if c and c.SetAlpha then c:SetAlpha(0) end

    editbox:ClearAllPoints()
    editbox:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0)
    editbox:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    editbox:SetAltArrowKeyMode(false)
    editbox.editboxHasFocus = false
    editbox:Hide()

    -- Kill editbox textures
    local editBoxTexNames = {"EditBoxMid", "EditBoxLeft", "EditBoxRight", "EditBoxFocusMid", "EditBoxFocusLeft", "EditBoxFocusRight"}
    for _, texName in pairs(editBoxTexNames) do
        local tex = _G[name .. texName]
        if tex then tex:SetAlpha(0) end
    end

    -- Apply editBox backdrop (TUI_Core style)
    if editbox.SetBackdrop then
        editbox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        editbox:SetBackdropColor(0, 0, 0, 0.6)
        editbox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        -- Color editbox border by chat type
        hooksecurefunc("ChatEdit_UpdateHeader", function()
            local chatType = ChatFrame1EditBox:GetAttribute("chatType")
            if chatType then
                local r, g, b = GetMessageTypeColor(chatType)
                ChatFrame1EditBox:SetBackdropBorderColor(r, g, b, 1)
            end
        end)
    end

    -- Character count
    local charCount = editbox:CreateFontString(nil, "ARTWORK")
    charCount:SetFont(UNIT_NAME_FONT, 11, "")
    charCount:SetTextColor(190/255, 190/255, 190/255, 0.4)
    charCount:SetPoint("TOPRIGHT", editbox, "TOPRIGHT", -5, 0)
    charCount:SetPoint("BOTTOMRIGHT", editbox, "BOTTOMRIGHT", -5, 0)
    charCount:SetJustifyH("CENTER")
    charCount:SetWidth(40)
    editbox.characterCount = charCount

    editbox:HookScript("OnEditFocusGained", function(eb)
        frame.editboxHasFocus = true
        eb:Show()
    end)
    editbox:HookScript("OnEditFocusLost", function(eb)
        frame.editboxHasFocus = false
        eb:Hide()
        eb.historyIndex = 0
    end)

    editbox:HookScript("OnTextChanged", CFS._EditBoxOnTextChanged)
    editbox:HookScript("OnKeyDown", EditBoxOnKeyDown)

    editbox.historyLines = {}
    editbox.historyIndex = 0

    if editbox.AddHistoryLine then
        hooksecurefunc(editbox, "AddHistoryLine", ChatEdit_AddHistory)
    end

    if s.fontSize and s.fontSize > 0 then
        frame:SetFont(ADDON_FONT, s.fontSize, "")
        editbox:SetFont(ADDON_FONT, s.fontSize, "")
        local header = _G[editbox:GetName() .. "Header"]
        if header then header:SetFont(ADDON_FONT_BOLD, s.fontSize, "") end
    end

    -- =============================================
    -- URL click handler (TUI_Core style â€” via popup)
    -- =============================================
    frame:SetScript("OnHyperlinkClick", OnHyperlinkClickURL)

    frame.styled = true
end

-- =====================================
-- BUILD COPY CHAT FRAME
-- =====================================

local function BuildCopyChatFrame()
    local frame = CreateFrame("Frame", "TomoModCopyChatFrame", UIParent, "BackdropTemplate")
    tinsert(UISpecialFrames, "TomoModCopyChatFrame")

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    frame:SetSize(700, 200)
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 15)
    frame:Hide()
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(350, 100)
    frame:SetScript("OnMouseDown", function(cf, button)
        if button == "LeftButton" and not cf.isMoving then
            cf:StartMoving()
            cf.isMoving = true
        elseif button == "RightButton" and not cf.isSizing then
            cf:StartSizing()
            cf.isSizing = true
        end
    end)
    frame:SetScript("OnMouseUp", function(cf, button)
        if button == "LeftButton" and cf.isMoving then
            cf:StopMovingOrSizing()
            cf.isMoving = false
        elseif button == "RightButton" and cf.isSizing then
            cf:StopMovingOrSizing()
            cf.isSizing = false
        end
    end)
    frame:SetScript("OnHide", function(cf)
        if cf.isMoving or cf.isSizing then
            cf:StopMovingOrSizing()
            cf.isMoving = false
            cf.isSizing = false
        end
    end)
    frame:SetFrameStrata("DIALOG")

    -- Title bar
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(ADDON_FONT_BOLD, 14, "")
    title:SetPoint("TOP", 0, -8)
    title:SetText("Copy Chat Text")

    local editBox = CreateFrame("EditBox", "TomoModCopyChatFrameEditBox", frame)
    editBox:SetHeight(200)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(99999)
    editBox:EnableMouse(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetFont(ADDON_FONT, 14, "")
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    editBox:SetScript("OnTextChanged", function(_, userInput)
        if userInput then return end
        local _, maxValue = TomoModCopyChatFrameScrollFrame.ScrollBar:GetMinMaxValues()
        for _ = 1, maxValue do
            ScrollFrameTemplate_OnMouseWheel(TomoModCopyChatFrameScrollFrame, -1)
        end
    end)
    frame.editBox = editBox

    local scrollFrame = CreateFrame("ScrollFrame", "TomoModCopyChatFrameScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 8)
    scrollFrame:SetScript("OnSizeChanged", function(_, width, height)
        TomoModCopyChatFrameEditBox:SetSize(width, height)
    end)
    scrollFrame:SetScrollChild(editBox)
    editBox:SetWidth(scrollFrame:GetWidth())
    frame.scrollFrame = scrollFrame

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT")
    frame.close:SetFrameLevel(frame.close:GetFrameLevel() + 1)
    frame.close:EnableMouse(true)
    frame.close:SetSize(20, 20)
end

-- =====================================
-- SAVE / DISPLAY CHAT HISTORY
-- =====================================

local function SaveChatHistory(event, ...)
    local historyType = historyTypes[event]
    if historyType then
        local s = S()
        if not s.showHistory or not s.showHistory[historyType] then return end
    end
    if not S().chatHistory then return end
    local data = TomoModDB and TomoModDB.chatFrameSkin and TomoModDB.chatFrameSkin.history
    if not data then return end

    local tempHistory = {}
    for i = 1, select("#", ...) do
        tempHistory[i] = select(i, ...) or false
    end

    if #tempHistory > 0 and not ChatFunctions:IsMessageProtected(tempHistory[1]) then
        tempHistory[50] = event
        tempHistory[51] = time()

        local coloredName, battleTag
        if tempHistory[13] and tempHistory[13] > 0 then coloredName, battleTag = GetBNFriendColor(tempHistory[2], tempHistory[13], true) end
        if battleTag then tempHistory[53] = battleTag end
        tempHistory[52] = coloredName or ChatFunctions:GetColoredName(event, ...)

        tinsert(data, tempHistory)
        while #data >= 128 do
            tremove(data, 1)
        end
    end
end

local function DisplayChatHistory()
    local s = S()
    if not s.chatHistory then return end
    local data = TomoModDB and TomoModDB.chatFrameSkin and TomoModDB.chatFrameSkin.history
    if not (data and next(data)) then return end

    if not TM_GetPlayerInfoByGUID(UnitGUID("player")) then
        C_Timer.After(0.1, DisplayChatHistory)
        return
    end

    SoundTimer = true
    for _, chat in ipairs(CHAT_FRAMES) do
        for _, d in ipairs(data) do
            if type(d) == "table" then
                for _, messageType in pairs(_G[chat].messageTypeList) do
                    local historyType = historyTypes[d[50]]
                    local skip = false
                    if historyType then
                        if not s.showHistory or not s.showHistory[historyType] then skip = true end
                    end
                    if not skip and gsub(strsub(d[50], 10), "_INFORM", "") == messageType then
                        if d[1] and not ChatFunctions:IsMessageProtected(d[1]) then
                            ChatFrame_MessageEventHandler(_G[chat], d[50], d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8], d[9], d[10], d[11], d[12], d[13], d[14], d[15], d[16], d[17], "TM_ChatHistory", d[51], d[52], d[53])
                        end
                    end
                end
            end
        end
    end
    SoundTimer = nil
end

-- =====================================
-- GUILD MOTD DELAY
-- =====================================

local function DelayGuildMOTD()
    if ChatTypeGroup and ChatTypeGroup.GUILD then
        tremove(ChatTypeGroup.GUILD, 2)
    end
    local delay, checks, delayFrame = 0, 0, CreateFrame("Frame")
    if ChatTypeGroup and ChatTypeGroup.GUILD then
        tinsert(ChatTypeGroup.GUILD, 2, "GUILD_MOTD")
    end
    delayFrame:SetScript("OnUpdate", function(self, elapsed)
        delay = delay + elapsed
        if delay < 5 then return end
        local msg = not InCombatLockdown() and C_GuildInfo_GetMOTD()
        if msg and strlen(msg) > 0 then
            for _, frameName in ipairs(CHAT_FRAMES) do
                local chat = _G[frameName]
                if chat and chat:IsEventRegistered("CHAT_MSG_GUILD") then
                    ChatFrame_SystemEventHandler(chat, "GUILD_MOTD", msg)
                    chat:RegisterEvent("GUILD_MOTD")
                end
            end
            self:SetScript("OnUpdate", nil)
        else
            delay, checks = 0, checks + 1
            if checks >= 5 then self:SetScript("OnUpdate", nil) end
        end
    end)
end

-- =====================================
-- TAB NOTIFICATION FLASH (TUI_Core style)
-- =====================================

local function SetupTabNotificationFlash()
    hooksecurefunc("FCF_StartAlertFlash", function(chatFrame)
        local chatFrameName = chatFrame:GetName()
        local chatTab = _G[chatFrameName .. "Tab"]
        if not chatTab then return end

        if not chatTab.notifyIcon then
            local T = TEX_CHAT:gsub("\\", "/")
            chatTab.notifyIcon = chatTab:CreateTexture(nil, "OVERLAY")
            chatTab.notifyIcon:SetTexture(T .. "notify")
            chatTab.notifyIcon:SetPoint("LEFT", 0, 0)
            chatTab.notifyIcon:SetSize(14, 14)
        end

        UIFrameFlash(chatTab.notifyIcon, 1.0, 1.0, -1, false, 0, 0, "tomomod-chat-tab-notify")
    end)

    hooksecurefunc("FCF_StopAlertFlash", function(chatFrame)
        local chatFrameName = chatFrame:GetName()
        local chatTab = _G[chatFrameName .. "Tab"]
        if chatTab and chatTab.notifyIcon then
            UIFrameFlashStop(chatTab.notifyIcon)
        end
    end)
end

-- =====================================
-- TAB POSITIONING (TUI_Core style)
-- =====================================

local function UpdateTabs()
    local dock = GENERAL_CHAT_DOCK
    if not dock then return end
    local prev

    for _, chatFrame in ipairs(dock.DOCKED_CHAT_FRAMES) do
        local chatTab = _G[chatFrame:GetName() .. "Tab"]
        if chatTab then
            if prev then
                chatTab:SetPoint("LEFT", prev, "RIGHT", 1, 0)
            else
                chatTab:SetPoint("BOTTOMLEFT", dock, "BOTTOMLEFT", 28, 0)
            end
            chatTab:SetAlpha(1)
            chatTab:SetWidth(chatTab:GetFontString():GetStringWidth() + 28)
            chatTab:SetFrameStrata("MEDIUM")
            prev = chatTab
        end
    end
end

-- =====================================
-- MAIN LOAD / INITIALIZE
-- =====================================

local function LoadChat()
    local s = S()
    if not s.enabled then return end

    DelayGuildMOTD()

    local eventFrame = CreateFrame("Frame")
    chatModuleInit = true

    -- Kill Blizzard elements (TUI_Core style)
    KillElement(ChatFrameMenuButton)
    KillElement(QuickJoinToastButton)

    -- Kill StaticPopup editbox textures
    for i = 1, 20 do
        local staticPopupEditBox = format("StaticPopup%dEditBox", i)
        if not _G[staticPopupEditBox] then break end
        local left = _G[staticPopupEditBox .. "Left"]
        local mid = _G[staticPopupEditBox .. "Mid"]
        local right = _G[staticPopupEditBox .. "Right"]
        if left then KillElement(left) end
        if mid then KillElement(mid) end
        if right then KillElement(right) end
    end

    -- Disable Blizzard fading (TUI_Core style)
    FCF_FadeInChatFrame = NoOp
    FCF_FadeInScrollbar = NoOp
    FCF_FadeOutChatFrame = NoOp
    FCF_FadeOutScrollbar = NoOp

    -- Style & hook all chat frames
    for _, frameName in ipairs(CHAT_FRAMES) do
        local frame = _G[frameName]
        frame:SetMovable(true)
        frame:SetClampedToScreen(false)
        frame:SetUserPlaced(true)
        frame:SetFrameStrata("LOW")

        styleChatWindow(frame)
        frame:SetTimeVisible(100)
        frame:SetFading(false)
        frame:SetMaxLines(2500)

        local allowHooks = not ignoreChats[frame:GetID()]
        if allowHooks and not frame.OldAddMessage then
            frame.OldAddMessage = frame.AddMessage
            frame.AddMessage = AddMessage
        end

        if not frame.scriptsSet then
            if allowHooks then
                frame:SetScript("OnEvent", FloatingChatFrameOnEvent)
            end
            frame:SetScript("OnMouseWheel", ChatFrame_OnMouseScroll)
            hooksecurefunc(frame, "SetScript", ChatFrame_SetScript)
            frame.scriptsSet = true
        end
    end

    -- Hook temporary windows
    hooksecurefunc("FCF_SetTemporaryWindowType", function(chatFrame)
        styleChatWindow(chatFrame)
        chatFrame:SetTimeVisible(100)
        chatFrame:SetFading(false)
    end)

    -- Hook dock updates (TUI_Core style tabs)
    hooksecurefunc("FCFDock_UpdateTabs", UpdateTabs)
    UpdateTabs()

    -- Hook dedicated frame registration
    hooksecurefunc("FCFManager_RegisterDedicatedFrame", function(chatFrame)
        styleChatWindow(chatFrame:GetName() and _G[chatFrame:GetName()] or chatFrame)
    end)

    -- Reposition dock
    if GENERAL_CHAT_DOCK and ChatFrame1 then
        GENERAL_CHAT_DOCK:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 16, 12)
        GENERAL_CHAT_DOCK:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", 0, 12)
    end

    -- =============================================
    -- Disable Blizzard Edit Mode for chat frames
    -- =============================================
    if FCF_SetLocked then
        for _, frameName in ipairs(CHAT_FRAMES) do
            local frame = _G[frameName]
            if frame then FCF_SetLocked(frame, 1) end
        end
    end
    -- Prevent Blizzard from making chat frames draggable via their default handler
    if FCF_StartDragging then FCF_StartDragging = NoOp end
    if FCF_StopDragging then FCF_StopDragging = NoOp end

    -- Restore saved position
    RestoreChatPosition()

    -- Register with mover system
    if TomoMod_Movers and TomoMod_Movers.RegisterEntry then
        TomoMod_Movers.RegisterEntry({
            label    = (TomoMod_L and TomoMod_L["mover_chatframe"]) or "Chat Frame",
            unlock   = function()
                if CFS.IsLocked() then CFS.ToggleLock() end
            end,
            lock     = function()
                if not CFS.IsLocked() then CFS.ToggleLock() end
            end,
            isActive = function()
                return TomoModDB and TomoModDB.chatFrameSkin and TomoModDB.chatFrameSkin.enabled
            end,
        })
    end

    -- Hyperlink + keyword + emoji setup
    SetupHyperlink()
    UpdateChatKeywords()
    SetupSmileys()

    -- =============================================
    -- Tab update hooks (TUI_Core style)
    -- =============================================
    hooksecurefunc("FCFTab_UpdateColors", function(self)
        if self:GetFontString() then self:GetFontString():SetTextColor(1, 1, 1) end
        -- Disable drawing layers for clean look
        self:DisableDrawLayer("BACKGROUND")
        self:DisableDrawLayer("BORDER")
        self:DisableDrawLayer("HIGHLIGHT")
    end)

    -- Tab notification flash (TUI_Core style)
    SetupTabNotificationFlash()

    -- Message filters
    for _, event in pairs(FindURL_Events) do
        ChatFrame_AddMessageEventFilter(event, HandleChatMessageFilter)
        local nType = strsub(event, 10)
        if nType ~= "AFK" and nType ~= "DND" and nType ~= "COMMUNITIES_CHANNEL" then
            eventFrame:RegisterEvent(event)
        end
    end

    -- Chat history
    if s.chatHistory then DisplayChatHistory() end

    -- Disable double-click on tabs
    for _, frameName in pairs(CHAT_FRAMES) do
        _G[frameName .. "Tab"]:SetScript("OnDoubleClick", nil)
    end

    -- Combat log progress bar
    if CombatLogQuickButtonFrame_CustomProgressBar then
        CombatLogQuickButtonFrame_CustomProgressBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    end
    if CombatLogQuickButtonFrame_CustomTexture then
        CombatLogQuickButtonFrame_CustomTexture:Hide()
    end

    BuildCopyChatFrame()

    -- Events
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            CollectLfgRolesForChatIcons()
        elseif event == "GROUP_ROSTER_UPDATE" then
            CollectLfgRolesForChatIcons()
        else
            SaveChatHistory(event, ...)
        end
    end)
end

-- =====================================
-- PUBLIC API
-- =====================================

function CFS.ApplySettings()
    if not chatModuleInit then return end
    local s = S()
    local T = TEX_CHAT:gsub("\\", "/")

    -- Font size
    for _, frameName in ipairs(CHAT_FRAMES) do
        local frame = _G[frameName]
        if frame then
            if s.fontSize and s.fontSize > 0 then
                frame:SetFont(ADDON_FONT, s.fontSize, "")
                local editbox = frame.editBox
                if editbox then editbox:SetFont(ADDON_FONT, s.fontSize, "") end
                local tab = GetTab(frame)
                if tab and tab.Text then
                    tab.Text:SetFont(ADDON_FONT_BOLD, s.fontSize, "")
                end
            end
        end
    end

    -- Re-apply skin style to container (allows live switching)
    local container = ChatFrame1 and ChatFrame1.tuiContainer
    if container then
        ApplyContainerSkin(container, T, s)
    end

    -- Background alpha (for skins that use bgFrame)
    if container and container.bgFrame and container.bgFrame.SetBackdropColor then
        local r, g, b = container.bgFrame:GetBackdropColor()
        container.bgFrame:SetBackdropColor(r, g, b, s.bgAlpha or 0.70)
    end

    -- Fading: when fade=true, our custom handleChatFrameFadeIn/Out will work
    -- When fade=false, ensure everything stays visible
    if not s.fade then
        for _, frameName in ipairs(CHAT_FRAMES) do
            local frame = _G[frameName]
            if frame then
                frame:SetAlpha(1)
                local tab = GetTab(frame)
                if tab then tab:SetAlpha(1) end
                if frame.copyButton then frame.copyButton:SetAlpha(0.35) end
            end
        end
    end
end

function CFS.SetEnabled(value)
    if not TomoModDB or not TomoModDB.chatFrameSkin then return end
    TomoModDB.chatFrameSkin.enabled = value
    if value and not chatModuleInit then
        isInitialized = true
        LoadChat()
    end
end

-- Public helper for ChatFrameUI's copy-chat sidebar icon
function CFS.CopyChatToFrame()
    if not TomoModCopyChatFrame then return end
    local count = getLines(ChatFrame1)
    local text = table.concat(copyLines, " \n", 1, count)
    if TomoModCopyChatFrameEditBox then
        TomoModCopyChatFrameEditBox:SetText(text)
    end
end

function CFS.Initialize()
    if isInitialized then return end
    if not IsEnabled() then return end
    isInitialized = true

    C_Timer.After(0.5, function()
        myRealm = gsub(GetRealmName() or "", "[%s%-]", "")
        myName = UnitName("player") or "Unknown"
        PLAYER_REALM = myRealm
        PLAYER_NAME = format("%s-%s", myName, PLAYER_REALM)

        LoadChat()

        -- Initialize ChatFrameUI if enabled (loads after ChatFrameSkin)
        if TomoMod_ChatFrameUI and TomoMod_ChatFrameUI.Initialize then
            TomoMod_ChatFrameUI.Initialize()
        end
    end)
end

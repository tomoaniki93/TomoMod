-- =====================================================================
-- ChatMessages.lua — presentation transforms for TomoMod Chat V4
-- Operates only on non-secret strings after Blizzard has formatted them.
-- =====================================================================

local Chat = TomoMod_ChatFrameSkin
if not Chat then return end

local Messages = {}
Chat.RegisterModule("Messages", Messages)

Messages.classByName = {}

local TEAL = "|cff2ed884"
local RESET = "|r"
local issecretvalue = issecretvalue

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function EscapePattern(text)
    return (text:gsub("(%W)", "%%%1"))
end

local function StripColorCodes(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    return text
end

local function SplitLeadingTimestamp(text)
    -- Blizzard timestamp prefixes can be plain or wrapped in a colour code.
    -- Keep the original prefix so a GUI refresh does not rewrite old messages
    -- with the current clock time.
    local prefix, rest = text:match("^(|c%x%x%x%x%x%x%x%x%[?%d%d?:%d%d%]?|r%s*)(.*)$")
    if prefix then return rest, prefix end

    prefix, rest = text:match("^(%[?%d%d?:%d%d%]?%s+)(.*)$")
    if prefix then return rest, prefix end

    return text, nil
end

local function ShortenNamedChannel(text, label, short)
    if type(label) ~= "string" or label == "" then return text end
    local pattern = "%[" .. EscapePattern(label) .. "%]"
    return (text:gsub(pattern, "[" .. short .. "]"))
end

local function ShortenChannels(text)
    local out = text

    -- Numbered public channels are locale-independent in their prefix.
    -- [2. Trade - City] / [2. Commerce - Capitales] -> [2]
    out = out:gsub("%[(%d+)%.%s*[^%]]+%]", "[%1]")

    local labels = {
        { _G.GUILD,         "G"  },
        { _G.OFFICER,       "O"  },
        { _G.PARTY,         "P"  },
        { _G.RAID,          "R"  },
        { _G.RAID_WARNING,  "RW" },
        { _G.INSTANCE_CHAT, "I"  },
        { _G.INSTANCE,      "I"  },
        { _G.SAY,           "S"  },
        { _G.YELL,          "Y"  },
        { _G.WHISPER,       "W"  },
    }
    for _, row in ipairs(labels) do
        out = ShortenNamedChannel(out, row[1], row[2])
    end

    return out
end

local function ProtectHyperlinks(text)
    local links = {}
    local protected = text:gsub("|H.-|h.-|h", function(link)
        links[#links + 1] = link
        return string.format("\001TMCHATLINK%d\002", #links)
    end)
    return protected, links
end

local function RestoreHyperlinks(text, links)
    return (text:gsub("\001TMCHATLINK(%d+)\002", function(index)
        return links[tonumber(index)] or ""
    end))
end

local function LinkifyURLs(text)
    local protected, links = ProtectHyperlinks(text)

    local function Wrap(url)
        -- Trim punctuation that usually terminates a sentence but is commonly
        -- swallowed by a broad URL pattern.
        local trailing = ""
        while url:match("[%)%]%}%.,!;:]$") do
            trailing = url:sub(-1) .. trailing
            url = url:sub(1, -2)
        end
        if url == "" then return trailing end
        return "|Htmurl:" .. url .. "|h" .. TEAL .. url .. RESET .. "|h" .. trailing
    end

    protected = protected:gsub("https?://[%w%-%._~:/%?#%[%]@!$&'()*+,;=%%]+", Wrap)
    protected = protected:gsub("www%.[%w%-%._~:/%?#%[%]@!$&'()*+,;=%%]+", Wrap)

    return RestoreHyperlinks(protected, links)
end

local EMOJI = {
    { ":%-%)", "☺" },
    { ":%)",   "☺" },
    { ";%-%)", "☻" },
    { ";%)",   "☻" },
    { ":%-D",  "☻" },
    { ":D",    "☻" },
    { ":%-%(", "☹" },
    { ":%(",   "☹" },
}

local function ApplyEmoji(text)
    local protected, links = ProtectHyperlinks(text)
    for _, row in ipairs(EMOJI) do
        protected = protected:gsub(row[1], "|cffffcc33" .. row[2] .. RESET)
    end
    return RestoreHyperlinks(protected, links)
end

local function ApplyClassMentions(text, enabled)
    if not enabled then return text end
    local protected, links = ProtectHyperlinks(text)

    protected = protected:gsub("([^%s]+)", function(word)
        local plain = StripColorCodes(word)
        plain = plain:gsub("^[%p]+", ""):gsub("[%p]+$", "")
        if plain == "" then return word end

        local class = Messages.classByName[plain]
        local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if not color then return word end

        local hex
        if color.colorStr then
            hex = "|c" .. color.colorStr
        else
            hex = string.format("|cff%02x%02x%02x",
                math.floor((color.r or 1) * 255 + 0.5),
                math.floor((color.g or 1) * 255 + 0.5),
                math.floor((color.b or 1) * 255 + 0.5))
        end
        return (word:gsub(EscapePattern(plain), hex .. plain .. RESET, 1))
    end)

    return RestoreHyperlinks(protected, links)
end

function Messages:Format(message)
    if message == nil or IsSecret(message) or type(message) ~= "string" then
        return message
    end

    local settings = Chat.GetDB().messages or {}
    local out, nativeTimestamp = SplitLeadingTimestamp(message)

    if settings.shortChannelNames ~= false then
        out = ShortenChannels(out)
    end
    if settings.findURL ~= false then
        out = LinkifyURLs(out)
    end
    if settings.emoji ~= false then
        out = ApplyEmoji(out)
    end
    out = ApplyClassMentions(out, settings.classColorMentions ~= false)

    if settings.showTimestamp ~= false then
        if nativeTimestamp then
            out = nativeTimestamp .. out
        else
            local format = settings.timestampFormat or "%H:%M"
            local stamp = date and date(format) or ""
            if type(stamp) == "string" and stamp ~= "" then
                out = "|cff6f7f7f" .. stamp .. RESET .. " " .. out
            end
        end
    end

    return out
end

function Messages:SettingsSignature()
    local s = Chat.GetDB().messages or {}
    return table.concat({
        tostring(s.showTimestamp ~= false),
        tostring(s.timestampFormat or "%H:%M"),
        tostring(s.shortChannelNames ~= false),
        tostring(s.findURL ~= false),
        tostring(s.emoji ~= false),
        tostring(s.classColorMentions ~= false),
    }, "|")
end

local CHAT_EVENTS = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_EMOTE", "CHAT_MSG_AFK", "CHAT_MSG_DND", "CHAT_MSG_COMMUNITIES_CHANNEL",
}

local function CacheSenderClass(author, guid)
    if IsSecret(author) or IsSecret(guid) then return end
    if type(author) ~= "string" or author == "" or type(guid) ~= "string" or guid == "" then return end
    if not GetPlayerInfoByGUID then return end

    local _, class, _, _, _, name, realm = GetPlayerInfoByGUID(guid)
    if type(class) ~= "string" or class == "" then return end

    Messages.classByName[author] = class
    if type(name) == "string" and name ~= "" then
        Messages.classByName[name] = class
        if type(realm) == "string" and realm ~= "" then
            Messages.classByName[name .. "-" .. realm] = class
        end
    end
end

function Messages:Initialize()
    if self.events then return end
    local frame = CreateFrame("Frame")
    for _, event in ipairs(CHAT_EVENTS) do frame:RegisterEvent(event) end
    frame:SetScript("OnEvent", function(_, _, _, author, ...)
        local guid = select(10, ...)
        CacheSenderClass(author, guid)
    end)
    self.events = frame
end

function Messages:ApplySettings()
end

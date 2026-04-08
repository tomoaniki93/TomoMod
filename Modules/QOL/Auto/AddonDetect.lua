-- =====================================
-- AddonDetect.lua — TomoMod User Detection
-- Detects other players running TomoMod via addon messaging and
-- prefixes their chat messages with a teal "TM" badge.
--
-- Supported channels: SAY, YELL, GUILD, OFFICER, PARTY, RAID,
--                     RAID_WARNING, INSTANCE_CHAT, WHISPER (in/out)
-- =====================================

TomoMod_AddonDetect = TomoMod_AddonDetect or {}
local AD = TomoMod_AddonDetect

local PREFIX     = "TomoMod"
local BADGE      = "|cff0cd29fTM|r "
local knownUsers = {}   -- [baseName] = true
local _init      = false

-- =====================================
-- HELPERS
-- =====================================

local function StripRealm(name)
    if not name or name == "" then return nil end
    return name:match("^([^%-]+)") or name
end

local function PlayerBaseName()
    return UnitName("player") or ""
end

-- =====================================
-- BROADCAST PRESENCE
-- Sends an invisible addon message to all channels the player is in.
-- Other TomoMod clients will pick this up and add us to their table.
-- =====================================

local function Broadcast()
    -- Raid has priority over party
    if IsInRaid() then
        C_ChatInfo.SendAddonMessage(PREFIX, "HELLO", "RAID")
    elseif IsInGroup() then
        C_ChatInfo.SendAddonMessage(PREFIX, "HELLO", "PARTY")
    end

    if IsInGuild() then
        C_ChatInfo.SendAddonMessage(PREFIX, "HELLO", "GUILD")
    end

    -- Instance chat (LFG, arenas, battlegrounds)
    local inInstance, instanceType = IsInInstance()
    if inInstance and instanceType ~= "none" then
        pcall(C_ChatInfo.SendAddonMessage, PREFIX, "HELLO", "INSTANCE_CHAT")
    end
end

-- =====================================
-- CHAT EVENT FILTERS
-- ChatFrame_AddMessageEventFilter receives:
--   (chatFrame, event, msg, author, language, channelString, target, flags,
--    unknown, channelNumber, channelName, unknown2, lineID, authorGUID)
-- Returning false passes through (optionally with modified args).
-- Returning true suppresses the message entirely.
-- =====================================

-- Generic filter: badge if author is a known TM user
local function DefaultBadgeFilter(self, event, msg, author, ...)
    local baseName = StripRealm(author)
    if baseName and knownUsers[baseName] then
        return false, BADGE .. msg, author, ...
    end
    return false
end

-- Whisper INFORM filter: badge if the RECIPIENT (arg5 = target) is known
local function WhisperInformFilter(self, event, msg, author, lang, channel, target, ...)
    local baseName = StripRealm(target)
    if baseName and knownUsers[baseName] then
        return false, BADGE .. msg, author, lang, channel, target, ...
    end
    return false
end

-- =====================================
-- INITIALIZE
-- =====================================

function AD.Initialize()
    if _init then return end
    _init = true

    -- Check DB flag
    if TomoModDB and TomoModDB.addonDetect and TomoModDB.addonDetect.enabled == false then
        return
    end

    -- Register our addon message prefix
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

    -- ========================
    -- Event listener
    -- ========================
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("GROUP_JOINED")
    frame:RegisterEvent("GUILDBANKFRAME_OPENED")   -- triggers after guild roster loads
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    frame:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4)
        if event == "CHAT_MSG_ADDON" then
            -- arg1 = prefix, arg2 = message, arg3 = distribution, arg4 = sender
            if arg1 == PREFIX and arg2 == "HELLO" then
                local baseName = StripRealm(arg4)
                if baseName and baseName ~= PlayerBaseName() then
                    knownUsers[baseName] = true
                end
            end

        elseif event == "GROUP_JOINED" then
            C_Timer.After(2, Broadcast)

        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Re-announce on every zone transition (covers BGs, LFG, etc.)
            C_Timer.After(3, Broadcast)
        end
    end)

    -- ========================
    -- Chat event filters
    -- ========================
    local chatEvents = {
        "CHAT_MSG_SAY",
        "CHAT_MSG_YELL",
        "CHAT_MSG_GUILD",
        "CHAT_MSG_OFFICER",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_RAID_WARNING",
        "CHAT_MSG_INSTANCE_CHAT",
        "CHAT_MSG_INSTANCE_CHAT_LEADER",
        "CHAT_MSG_WHISPER",
    }

    for _, evName in ipairs(chatEvents) do
        ChatFrame_AddMessageEventFilter(evName, DefaultBadgeFilter)
    end

    -- Outgoing whispers: badge the recipient if they have TM
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", WhisperInformFilter)
end

-- =====================================
-- PUBLIC: manually add or query a user
-- =====================================

function AD.AddUser(name)
    local base = StripRealm(name)
    if base then knownUsers[base] = true end
end

function AD.IsKnownUser(name)
    return knownUsers[StripRealm(name)] == true
end

function AD.GetKnownUsers()
    return knownUsers
end

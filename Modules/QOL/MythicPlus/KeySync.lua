-- ---------------------------------------------------------------------
-- KeySync.lua -- keystone sharing, without LibOpenRaid
--
-- LibOpenRaid was carried purely for four keystone functions. It also
-- synchronises cooldowns, gear, talents and durability, and that cooldown
-- path is what flooded the taint log through AuraUtil.ForEachAura. This
-- module replaces the four functions and nothing else.
--
-- Your own keystone needs no library at all: C_MythicPlus hands it over
-- directly. Everything else here is transport -- one prefix, one line
-- format, and a table that survives a logout.
--
-- Wire protocol, pipe-free so realm names with punctuation stay intact:
--   1:K:<challengeMapID>:<level>:<classID>:<specID>:<rating>
--   1:?                                   (asks everyone to answer)
-- Unknown versions are ignored rather than guessed at, so a future
-- format can ship without older clients mangling it.
-- ---------------------------------------------------------------------

local U = TomoMod_Utils

TomoMod_KeySync = {}
local KS = TomoMod_KeySync

local PREFIX  = "TOMOKEYS"
local PROTO   = "1"
local PUSH_THROTTLE = 5      -- seconds between voluntary broadcasts
local REPLY_JITTER  = 2.5    -- spread replies so a party of five does not burst

KS.Data = {}                 -- [fullName] = entry
local callbacks = {}
local lastPush, pendingReply = 0, false

-- ---------------------------------------------------------------------
-- Secret value guard
--
-- Keystone getters are normally readable, but they are queried on events
-- that can land mid-combat. issecretvalue() runs BEFORE any comparison,
-- never after.
-- ---------------------------------------------------------------------
local function SafeNum(v)
    if v == nil then return nil end
    local builtin = rawget(_G, "issecretvalue")
    if type(builtin) == "function" then
        local ok, secret = pcall(builtin, v)
        if ok and secret then return nil end
    end
    return type(v) == "number" and v or nil
end

-- ---------------------------------------------------------------------
-- Store
-- ---------------------------------------------------------------------
local function DB()
    if type(TomoModDB) ~= "table" then return nil end
    if type(TomoModDB.Keystones) ~= "table" then TomoModDB.Keystones = {} end
    return TomoModDB.Keystones
end

-- Keystones reset weekly. Rather than ageing entries out one by one, note
-- when the current week ends and drop everything once it has.
local function PurgeIfNewWeek()
    local db = DB()
    if not db then return end
    local now = time()
    if TomoModDB.KeystonesResetAt and now < TomoModDB.KeystonesResetAt then return end

    wipe(KS.Data)
    TomoModDB.Keystones = {}
    local secs = C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset
        and C_DateAndTime.GetSecondsUntilWeeklyReset()
    TomoModDB.KeystonesResetAt = now + (SafeNum(secs) or 604800)
end

local function Store(fullName, entry)
    if not fullName or fullName == "" then return end
    entry.updated = time()
    KS.Data[fullName] = entry
    local db = DB()
    if db then db[fullName] = entry end
end

local function Fire(fullName)
    for _, cb in ipairs(callbacks) do
        local ok, err = pcall(cb.fn, fullName, KS.Data[fullName], KS.Data)
        if not ok then
            -- A broken listener must not take the sync down with it.
            print("|cff2ed884TomoMod|r KeySync: callback error (" .. tostring(cb.owner) .. "): " .. tostring(err))
        end
    end
end

-- ---------------------------------------------------------------------
-- Local player
-- ---------------------------------------------------------------------
local function PlayerFullName()
    local name  = UnitName("player")
    local realm = GetRealmName()
    if not name then return nil end
    if realm and realm ~= "" then
        return name .. "-" .. (realm:gsub("%s+", ""))
    end
    return name
end

function KS.ReadOwnKeystone()
    local level = SafeNum(C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel
        and C_MythicPlus.GetOwnedKeystoneLevel()) or 0
    local mapID = SafeNum(C_MythicPlus and C_MythicPlus.GetOwnedKeystoneChallengeMapID
        and C_MythicPlus.GetOwnedKeystoneChallengeMapID()) or 0

    local _, _, classID = UnitClass("player")
    local specID = 0
    if GetSpecialization then
        local index = GetSpecialization()
        if index then specID = SafeNum(GetSpecializationInfo(index)) or 0 end
    end

    local rating = 0
    if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        rating = summary and SafeNum(summary.currentSeasonScore) or 0
    end

    return {
        challengeMapID = mapID,
        mythicPlusMapID = mapID,   -- kept for call sites that read either name
        level   = level,
        classID = SafeNum(classID) or 0,
        specID  = specID,
        rating  = rating,
    }
end

-- ---------------------------------------------------------------------
-- Transport
-- ---------------------------------------------------------------------
local function GroupChannel()
    if IsInRaid() then
        return IsInRaid(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "RAID"
    elseif IsInGroup() then
        return IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
    end
    return nil
end

local function Send(msg, channel)
    if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return end
    if not channel then return end
    if channel == "GUILD" and not IsInGuild() then return end
    C_ChatInfo.SendAddonMessage(PREFIX, msg, channel)
end

local function Encode(entry)
    return string.format("%s:K:%d:%d:%d:%d:%d", PROTO,
        entry.challengeMapID or 0, entry.level or 0,
        entry.classID or 0, entry.specID or 0, entry.rating or 0)
end

-- Broadcast our key. `force` skips the throttle, for a genuine change or a
-- direct request; routine events go through it.
function KS.Broadcast(force)
    local me = PlayerFullName()
    if not me then return end

    local entry = KS.ReadOwnKeystone()
    local prev  = KS.Data[me]
    local changed = not prev or prev.level ~= entry.level
        or prev.challengeMapID ~= entry.challengeMapID

    Store(me, entry)
    if changed then Fire(me) end

    local now = GetTime()
    if not force and not changed and (now - lastPush) < PUSH_THROTTLE then return end
    lastPush = now

    local msg = Encode(entry)
    Send(msg, GroupChannel())
    Send(msg, "GUILD")
end

function KS.RequestKeystoneDataFromParty()
    local channel = GroupChannel()
    if not channel then return end
    Send(PROTO .. ":?", channel)
    -- Answer our own request locally: the client does not echo our message
    -- back to us, so without this the player's own row would be missing
    -- until the next event.
    KS.Broadcast(true)
end

function KS.RequestKeystoneDataFromGuild()
    Send(PROTO .. ":?", "GUILD")
end

-- ---------------------------------------------------------------------
-- Receive
-- ---------------------------------------------------------------------
local function OnMessage(msg, channel, sender)
    if type(msg) ~= "string" or not sender then return end
    local proto, rest = msg:match("^(%d+):(.+)$")
    if proto ~= PROTO then return end   -- unknown version: ignore, never guess

    if rest == "?" then
        if pendingReply then return end
        pendingReply = true
        C_Timer.After(math.random() * REPLY_JITTER, function()
            pendingReply = false
            KS.Broadcast(true)
        end)
        return
    end

    local mapID, level, classID, specID, rating =
        rest:match("^K:(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+)$")
    if not mapID then return end

    level = tonumber(level) or 0
    mapID = tonumber(mapID) or 0
    if level < 0 or level > 100 or mapID < 0 then return end   -- reject junk

    Store(sender, {
        challengeMapID  = mapID,
        mythicPlusMapID = mapID,
        level   = level,
        classID = tonumber(classID) or 0,
        specID  = tonumber(specID) or 0,
        rating  = tonumber(rating) or 0,
    })
    Fire(sender)
end

-- ---------------------------------------------------------------------
-- Public API -- deliberately the shape the call sites already expect, so
-- swapping the library out touches one line per consumer.
-- ---------------------------------------------------------------------
function KS.GetAllKeystonesInfo()
    return KS.Data
end

function KS.GetKeystoneInfo(unitId)
    if not unitId then return nil end
    if unitId == "player" then
        return KS.Data[PlayerFullName() or ""]
    end
    local name, realm = UnitName(unitId)
    if not name then return nil end
    if realm and realm ~= "" then
        return KS.Data[name .. "-" .. realm] or KS.Data[name]
    end
    -- A unit on our own realm reports no realm suffix, but the sender
    -- string on an addon message always carries one.
    return KS.Data[name] or KS.Data[name .. "-" .. (GetRealmName() or ""):gsub("%s+", "")]
end

function KS.RegisterCallback(owner, event, fn)
    if type(fn) ~= "function" then return end
    for _, cb in ipairs(callbacks) do
        if cb.owner == owner and cb.event == event then return end
    end
    callbacks[#callbacks + 1] = { owner = owner, event = event, fn = fn }
end

function KS.UnregisterCallback(owner, event)
    for i = #callbacks, 1, -1 do
        if callbacks[i].owner == owner and callbacks[i].event == event then
            table.remove(callbacks, i)
        end
    end
end

-- ---------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("CHALLENGE_MODE_COMPLETED")
f:RegisterEvent("WEEKLY_REWARDS_UPDATE")
f:RegisterEvent("CHAT_MSG_ADDON")

f:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, msg, channel, sender = ...
        if prefix == PREFIX then OnMessage(msg, channel, sender) end
        return
    end

    if event == "PLAYER_LOGIN" then
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
        end
        PurgeIfNewWeek()
        -- Reload what survived the logout, minus anything the purge dropped.
        local db = DB()
        if db then
            for name, entry in pairs(db) do KS.Data[name] = entry end
        end
        -- The keystone getters return stale data until the client has been
        -- asked for the weekly reward state at least once.
        if C_MythicPlus and C_MythicPlus.RequestRewards then C_MythicPlus.RequestRewards() end
        return
    end

    if event == "GROUP_ROSTER_UPDATE" then
        if GroupChannel() then
            C_Timer.After(1, function() KS.RequestKeystoneDataFromParty() end)
        end
        return
    end

    -- Everything else is "our own key may have changed".
    C_Timer.After(1, function() KS.Broadcast(false) end)
end)

-- ---------------------------------------------------------------------
-- Slash helper: /tmt keysync
-- ---------------------------------------------------------------------
function KS.Debug()
    local count = 0
    for name, entry in pairs(KS.Data) do
        count = count + 1
        print(string.format("|cff2ed884%s|r  +%d  map %d", name, entry.level or 0, entry.challengeMapID or 0))
    end
    print("|cff2ed884TomoMod|r KeySync: " .. count .. " entries.")
end

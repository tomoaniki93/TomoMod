-- =====================================
-- AutoSummon.lua
-- Auto-accept les summons de guilde/amis
-- =====================================

TomoModMini_AutoSummon = TomoModMini_AutoSummon or {}
local AS = TomoModMini_AutoSummon

-- =====================================
-- VARIABLES
-- =====================================
local mainFrame
local summonPending = false

-- =====================================
-- FONCTIONS UTILITAIRES
-- =====================================
local function GetSettings()
    if not TomoModMiniDB or not TomoModMiniDB.autoSummon then
        return nil
    end
    return TomoModMiniDB.autoSummon
end

--- Verifie si un nom est dans la liste d'amis du jeu
local function IsGameFriend(name)
    local numFriends = C_FriendList.GetNumFriends()
    for i = 1, numFriends do
        local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
        if friendInfo then
            if Ambiguate(friendInfo.name or "", "short") == name then
                return true
            end
        end
    end
    return false
end

--- Verifie si un nom est un ami BattleNet connecte
local function IsBNetFriend(name)
    local numBNet = BNGetNumFriends()
    for i = 1, numBNet do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo and accountInfo.gameAccountInfo then
            local charName = accountInfo.gameAccountInfo.characterName
            if charName and Ambiguate(charName, "short") == name then
                return true
            end
        end
    end
    return false
end

--- Verifie si un nom est dans la guilde
local function IsGuildMember(name)
    if not IsInGuild() then return false end
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local guildName = GetGuildRosterInfo(i)
        if guildName and Ambiguate(guildName, "short") == name then
            return true
        end
    end
    return false
end

--- Verifie si le summoner est de confiance
local function IsSummonerTrusted(summonerName)
    if not summonerName then return false end

    local settings = GetSettings()
    if not settings then return false end

    local shortName = Ambiguate(summonerName, "short")

    if settings.acceptFriends then
        if IsGameFriend(shortName) then return true, "ami" end
        if IsBNetFriend(shortName) then return true, "ami BattleNet" end
    end

    if settings.acceptGuild then
        if IsGuildMember(shortName) then return true, "membre de guilde" end
    end

    return false
end

-- =====================================
-- EVENEMENTS
-- =====================================
local function OnEvent(self, event, ...)
    local settings = GetSettings()
    if not settings or not settings.enabled then
        return
    end

    if event == "CONFIRM_SUMMON" then
        local summoner = GetSummonConfirmSummoner()
        local area = GetSummonConfirmAreaName()
        local timeLeft = GetSummonConfirmTimeLeft()

        if not summoner or not timeLeft or timeLeft <= 0 then
            return
        end

        summonPending = true
        local isTrusted, source = IsSummonerTrusted(summoner)

        if isTrusted then
            local delay = settings.delaySec or 1
            C_Timer.After(delay, function()
                if summonPending and GetSummonConfirmTimeLeft() > 0 then
                    C_SummonInfo.ConfirmSummon()
                    summonPending = false

                    if settings.showMessages then
                        print(string.format(
                            "|cffff3399TomoModMini:|r " .. TomoModMini_L["msg_sum_accepted"],
                            summoner, area or "?", source
                        ))
                    end
                end
            end)
        else
            if settings.showMessages then
                print("|cffff3399TomoModMini:|r " .. string.format(TomoModMini_L["msg_sum_ignored"], summoner))
            end
        end
    end
end

-- =====================================
-- FONCTIONS PUBLIQUES
-- =====================================
function AS.Initialize()
    if not TomoModMiniDB or not TomoModMiniDB.autoSummon then return end

    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    -- Creer le frame (evenement uniquement, pas d'OnUpdate)
    if not mainFrame then
        mainFrame = CreateFrame("Frame")
    end
    mainFrame:RegisterEvent("CONFIRM_SUMMON")
    mainFrame:SetScript("OnEvent", OnEvent)
end

function AS.SetEnabled(enabled)
    local settings = GetSettings()
    if not settings then return end

    settings.enabled = enabled

    if enabled then
        if not mainFrame then
            AS.Initialize()
        else
            mainFrame:RegisterEvent("CONFIRM_SUMMON")
            mainFrame:SetScript("OnEvent", OnEvent)
        end
        print("|cffff3399TomoModMini:|r " .. TomoModMini_L["msg_sum_enabled"])
    else
        if mainFrame then
            mainFrame:UnregisterAllEvents()
            mainFrame:SetScript("OnEvent", nil)
        end
        summonPending = false
        print("|cffff3399TomoModMini:|r " .. TomoModMini_L["msg_sum_disabled"])
    end
end

function AS.Toggle()
    local settings = GetSettings()
    if not settings then return end
    AS.SetEnabled(not settings.enabled)
end

function AS.AcceptNow()
    if GetSummonConfirmTimeLeft() and GetSummonConfirmTimeLeft() > 0 then
        C_SummonInfo.ConfirmSummon()
        summonPending = false
        print("|cffff3399TomoModMini:|r " .. TomoModMini_L["msg_sum_manual"])
    else
        print("|cffff3399TomoModMini:|r " .. TomoModMini_L["msg_sum_no_pending"])
    end
end

-- Export
_G.TomoModMini_AutoSummon = AS
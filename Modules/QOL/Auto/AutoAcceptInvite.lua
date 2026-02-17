-- =====================================
-- AutoAcceptInvite.lua
-- Auto-accept les invitations de groupe
-- de la part d'amis et membres de guilde
-- =====================================

TomoModMini_AutoAcceptInvite = TomoModMini_AutoAcceptInvite or {}
local AAI = TomoModMini_AutoAcceptInvite

-- =====================================
-- VARIABLES
-- =====================================
local mainFrame

-- =====================================
-- FONCTIONS UTILITAIRES
-- =====================================
local function GetSettings()
    if not TomoModMiniDB or not TomoModMiniDB.autoAcceptInvite then
        return nil
    end
    return TomoModMiniDB.autoAcceptInvite
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

--- Verifie si l'inviteur est de confiance
local function IsInviterTrusted(inviterName)
    if not inviterName then return false end

    local settings = GetSettings()
    if not settings then return false end

    local shortName = Ambiguate(inviterName, "short")

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

    if event == "PARTY_INVITE_REQUEST" then
        local inviterName = ...
        if not inviterName then return end

        local isTrusted, source = IsInviterTrusted(inviterName)

        if isTrusted then
            AcceptGroup()

            if settings.showMessages then
                print("|cffff3399TomoModMini:|r " .. TomoModMini_L["msg_aai_accepted"]
                    .. inviterName .. " (" .. source .. ")")
            end

            -- Petit delai pour laisser le popup apparaitre
            C_Timer.After(0.2, function()
                StaticPopup_Hide("PARTY_INVITE")
            end)
        else
            if settings.showMessages then
                print("|cffff3399TomoModMini:|r " .. TomoModMini_L["msg_aai_ignored"]
                    .. inviterName .. " (non fiable)")
            end
        end
    end
end

-- =====================================
-- FONCTIONS PUBLIQUES
-- =====================================
function AAI.Initialize()
    if not TomoModMiniDB or not TomoModMiniDB.autoAcceptInvite then return end

    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    -- Creer le frame (uniquement PARTY_INVITE_REQUEST)
    if not mainFrame then
        mainFrame = CreateFrame("Frame")
    end
    mainFrame:RegisterEvent("PARTY_INVITE_REQUEST")
    mainFrame:SetScript("OnEvent", OnEvent)
end

function AAI.SetEnabled(enabled)
    local settings = GetSettings()
    if not settings then return end

    settings.enabled = enabled

    if enabled then
        if not mainFrame then
            AAI.Initialize()
        else
            mainFrame:RegisterEvent("PARTY_INVITE_REQUEST")
            mainFrame:SetScript("OnEvent", OnEvent)
        end
        print("|cffff3399TomoModMini:|r " .. TomoModMini_L["msg_aai_enabled"])
    else
        if mainFrame then
            mainFrame:UnregisterAllEvents()
            mainFrame:SetScript("OnEvent", nil)
        end
        print("|cffff3399TomoModMini:|r " .. TomoModMini_L["msg_aai_disabled"])
    end
end

function AAI.Toggle()
    local settings = GetSettings()
    if not settings then return end
    AAI.SetEnabled(not settings.enabled)
end

-- Export
_G.TomoModMini_AutoAcceptInvite = AAI
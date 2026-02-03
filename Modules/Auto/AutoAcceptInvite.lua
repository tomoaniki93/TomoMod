-- =====================================
-- AutoAcceptInvite.lua
-- Auto-accept les invitations de groupe/guilde
-- =====================================

TomoMod_AutoAcceptInvite = TomoMod_AutoAcceptInvite or {}
local AAI = TomoMod_AutoAcceptInvite

-- =====================================
-- VARIABLES
-- =====================================
local mainFrame

-- =====================================
-- FONCTIONS UTILITAIRES
-- =====================================
local function GetSettings()
    if not TomoModDB or not TomoModDB.autoAcceptInvite then
        return nil
    end
    return TomoModDB.autoAcceptInvite
end

local function IsInviterTrusted(inviterName)
    if not inviterName then return false end
    
    local settings = GetSettings()
    if not settings then return false end
    
    -- Vérifier si c'est un ami
    if settings.acceptFriends then
        local numFriends = C_FriendList.GetNumFriends()
        for i = 1, numFriends do
            local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
            if friendInfo and friendInfo.name == inviterName then
                return true, "ami"
            end
        end
        
        -- Vérifier BattleNet friends
        local numBNetFriends = BNGetNumFriends()
        for i = 1, numBNetFriends do
            local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
            if accountInfo and accountInfo.gameAccountInfo then
                local gameInfo = accountInfo.gameAccountInfo
                if gameInfo.characterName == inviterName then
                    return true, "ami BattleNet"
                end
            end
        end
    end
    
    -- Vérifier si c'est un membre de guilde
    if settings.acceptGuild then
        if IsInGuild() then
            local numGuildMembers = GetNumGuildMembers()
            for i = 1, numGuildMembers do
                local name = GetGuildRosterInfo(i)
                if name and name == inviterName then
                    return true, "membre de guilde"
                end
            end
        end
    end
    
    return false
end

-- =====================================
-- ÉVÉNEMENTS
-- =====================================
local function OnEvent(self, event, ...)
    local settings = GetSettings()
    if not settings or not settings.enabled then
        return
    end
    
    if event == "PARTY_INVITE_REQUEST" then
        local inviterName = ...
        
        if inviterName then
            local isTrusted, source = IsInviterTrusted(inviterName)
            
            if isTrusted then
                AcceptGroup()
                
                if settings.showMessages then
                    print("|cff00ff00TomoMod:|r Invitation acceptée de " .. inviterName .. " (" .. source .. ")")
                end
                
                -- Cacher le popup d'invitation
                StaticPopup_Hide("PARTY_INVITE")
            end
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Optionnel: faire quelque chose quand le groupe change
    end
end

-- =====================================
-- FONCTIONS PUBLIQUES
-- =====================================
function AAI.Initialize()
    if not TomoModDB then
        print("|cffff0000TomoMod AutoAcceptInvite:|r TomoModDB non initialisée")
        return
    end
    
    -- Initialiser les settings
    if not TomoModDB.autoAcceptInvite then
        TomoModDB.autoAcceptInvite = {
            enabled = false, -- Désactivé par défaut
            acceptFriends = true,
            acceptGuild = true,
            showMessages = true,
        }
    end
    
    local settings = GetSettings()
    if not settings.enabled then
        return
    end
    
    -- Créer le frame principal
    mainFrame = CreateFrame("Frame")
    mainFrame:RegisterEvent("PARTY_INVITE_REQUEST")
    mainFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    mainFrame:SetScript("OnEvent", OnEvent)
    
    print("|cff00ff00TomoMod AutoAcceptInvite:|r Module initialisé")
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
            mainFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        end
        print("|cff00ff00TomoMod:|r Auto-accept invitations activé")
    else
        if mainFrame then
            mainFrame:UnregisterAllEvents()
        end
        print("|cff00ff00TomoMod:|r Auto-accept invitations désactivé")
    end
end

function AAI.Toggle()
    local settings = GetSettings()
    if not settings then return end
    
    AAI.SetEnabled(not settings.enabled)
end

-- Export
_G.TomoMod_AutoAcceptInvite = AAI

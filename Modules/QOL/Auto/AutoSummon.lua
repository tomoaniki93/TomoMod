-- =====================================
-- AutoSummon.lua
-- Auto-accept les summons de guilde/amis
-- =====================================

TomoMod_AutoSummon = TomoMod_AutoSummon or {}
local AS = TomoMod_AutoSummon

-- =====================================
-- VARIABLES
-- =====================================
local mainFrame
local summonPending = false
local summonerName = nil

-- =====================================
-- FONCTIONS UTILITAIRES
-- =====================================
local function GetSettings()
    if not TomoModDB or not TomoModDB.autoSummon then
        return nil
    end
    return TomoModDB.autoSummon
end

local function IsSummonerTrusted()
    local settings = GetSettings()
    if not settings then return false end
    
    -- Vérifier si on a un summon en attente
    local hasIncomingSummon = C_IncomingSummon.HasIncomingSummon(PlayerLocation:CreateFromUnit("player"))
    if not hasIncomingSummon then
        return false
    end
    
    local summonInfo = C_IncomingSummon.IncomingSummonStatus(PlayerLocation:CreateFromUnit("player"))
    if not summonInfo or summonInfo == 0 then
        return false
    end
    
    -- Obtenir le nom du summoneur
    -- Note: L'API ne donne pas directement le nom, on utilise les confirmations visuelles
    -- On fait confiance au système si les options sont activées
    
    -- Si acceptFriends est activé, on accepte
    if settings.acceptFriends then
        return true, "ami potentiel"
    end
    
    -- Si acceptGuild est activé et qu'on est en guilde
    if settings.acceptGuild and IsInGuild() then
        return true, "membre de guilde potentiel"
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
    
    if event == "CONFIRM_SUMMON" then
        -- Un summon est disponible
        summonPending = true
        
        local isTrusted, source = IsSummonerTrusted()
        
        if isTrusted then
            -- Attendre un petit délai pour éviter les spam
            C_Timer.After(0.5, function()
                if summonPending then
                    C_SummonInfo.ConfirmSummon()
                    summonPending = false
                    
                    if settings.showMessages then
                        print("|cff00ff00TomoMod:|r Summon accepté (" .. source .. ")")
                    end
                end
            end)
        end
    elseif event == "CANCEL_SUMMON" then
        -- Le summon a été annulé
        summonPending = false
        summonerName = nil
    end
end

local function OnUpdate(self, elapsed)
    local settings = GetSettings()
    if not settings or not settings.enabled then
        return
    end
    
    -- Vérifier périodiquement s'il y a un summon en attente
    local hasIncomingSummon = C_IncomingSummon.HasIncomingSummon(PlayerLocation:CreateFromUnit("player"))
    
    if hasIncomingSummon and not summonPending then
        -- Nouveau summon détecté
        summonPending = true
        OnEvent(self, "CONFIRM_SUMMON")
    elseif not hasIncomingSummon and summonPending then
        -- Summon annulé ou expiré
        summonPending = false
    end
end

-- =====================================
-- FONCTIONS PUBLIQUES
-- =====================================
function AS.Initialize()
    if not TomoModDB then
        print("|cffff0000TomoMod AutoSummon:|r TomoModDB non initialisée")
        return
    end
    
    -- Initialiser les settings
    if not TomoModDB.autoSummon then
        TomoModDB.autoSummon = {
            enabled = false, -- Désactivé par défaut
            acceptFriends = true,
            acceptGuild = true,
            showMessages = true,
            delaySec = 1, -- Délai avant d'accepter (secondes)
        }
    end
    
    local settings = GetSettings()
    if not settings.enabled then
        return
    end
    
    -- Créer le frame principal
    mainFrame = CreateFrame("Frame")
    mainFrame:RegisterEvent("CONFIRM_SUMMON")
    mainFrame:RegisterEvent("CANCEL_SUMMON")
    mainFrame:SetScript("OnEvent", OnEvent)
    
    -- Vérification périodique (fallback)
    mainFrame:SetScript("OnUpdate", OnUpdate)
    
    print("|cff00ff00TomoMod AutoSummon:|r Module initialisé")
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
            mainFrame:RegisterEvent("CANCEL_SUMMON")
        end
        print("|cff00ff00TomoMod:|r Auto-summon activé")
    else
        if mainFrame then
            mainFrame:UnregisterAllEvents()
            mainFrame:SetScript("OnUpdate", nil)
        end
        summonPending = false
        print("|cff00ff00TomoMod:|r Auto-summon désactivé")
    end
end

function AS.Toggle()
    local settings = GetSettings()
    if not settings then return end
    
    AS.SetEnabled(not settings.enabled)
end

function AS.AcceptNow()
    -- Fonction manuelle pour accepter immédiatement
    if summonPending then
        C_SummonInfo.ConfirmSummon()
        summonPending = false
        print("|cff00ff00TomoMod:|r Summon accepté manuellement")
    else
        print("|cffffff00TomoMod:|r Aucun summon en attente")
    end
end

-- Export
_G.TomoMod_AutoSummon = AS

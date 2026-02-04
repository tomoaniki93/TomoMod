-- =====================================
-- Core.lua
-- Initialisation principale de TomoMod
-- =====================================

local addonName = ...
local mainFrame = CreateFrame("Frame")

-- =====================================
-- MODULE SYSTEM
-- =====================================
TomoMod_Modules = TomoMod_Modules or {}

function TomoMod_RegisterModule(name, module)
    TomoMod_Modules[name] = module
end

function TomoMod_EnableModule(name)
    if not TomoModDB or not TomoModDB[name] then return end
    if not TomoModDB[name].enabled then return end

    local module = TomoMod_Modules[name]
    if module and module.Enable then
        module:Enable()
    end
end

-- =====================================

SLASH_TOMOMOD1 = "/tm"
SLASH_TOMOMOD2 = "/tomomod"
SlashCmdList["TOMOMOD"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "reset" then
        TomoMod_ResetDatabase()
        ReloadUI()
    elseif msg == "minimap" then
        TomoMod_ResetModule("minimap")
        if TomoMod_Minimap then TomoMod_Minimap.ApplySettings() end
    elseif msg == "panel" then
        TomoMod_ResetModule("infoPanel")
        if TomoMod_InfoPanel then TomoMod_InfoPanel.Initialize() end
    elseif msg == "cursor" then
        TomoMod_ResetModule("cursorRing")
        if TomoMod_CursorRing then TomoMod_CursorRing.ApplySettings() end
    elseif msg == "clearcinema" then
        if TomoMod_CinematicSkip then 
            TomoMod_CinematicSkip.ClearHistory() 
    elseif msg == "key" then
        TomoMod_EnableModule("MythicKeys")
        MK:Toggle()
    -- Nouvelles commandes pour SkyRide
    elseif msg == "skyride" then
        TomoMod_ResetModule("skyRide")
        if TomoMod_SkyRide then 
            TomoMod_SkyRide.Initialize()
            print("|cff00ff00TomoMod:|r SkyRide réinitialisé")
        end
    elseif msg == "skyride toggle" or msg == "sr" then
        if TomoMod_SkyRide and TomoMod_SkyRide.ToggleLock then
            TomoMod_SkyRide.ToggleLock()
        end
    -- Nouvelles commandes pour CombatInfo
    elseif msg == "cdm" or msg == "ci" then
        if TomoMod_CombatInfo then
            local enabled = TomoModDB and TomoModDB.combatInfo and TomoModDB.combatInfo.enabled
            print("|cff00ff00TomoMod CombatInfo:|r " .. (enabled and "Activé" or "Désactivé"))
        end
    -- Commande d'aide
    elseif msg == "help" or msg == "?" then
        print("|cff00ff00TomoMod|r Commandes disponibles:")
        print("  |cff00ff00/tm|r - Ouvrir la configuration")
        print("  |cff00ff00/tm reset|r - Réinitialiser la base de données")
        print("  |cff00ff00/tm minimap|r - Réinitialiser la minimap")
        print("  |cff00ff00/tm panel|r - Réinitialiser le panel d'infos")
        print("  |cff00ff00/tm cursor|r - Réinitialiser le cursor ring")
        print("  |cff00ff00/tm clearcinema|r - Effacer l'historique des cinématiques")
        print("  |cff00ff00/tm skyride|r - Réinitialiser SkyRide")
        print("  |cff00ff00/tm sr|r - Toggle Lock/Unlock SkyRide")
        print("  |cff00ff00/tm ci|r - Info CombatInfo")
        print("  |cff00ff00/tm help|r - Afficher cette aide")
    -- Par défaut: ouvrir la config
    else
        if TomoMod_Config and TomoMod_Config.Toggle then
            TomoMod_Config.Toggle()
        else
            print("|cff00ff00TomoMod|r Configuration à venir 🙂")
        end
    end
end

-- =====================================
-- EVENT HANDLERS
-- =====================================
mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:RegisterEvent("PLAYER_LOGIN")

mainFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialiser la base de données
        TomoMod_InitDatabase()
        
    elseif event == "PLAYER_LOGIN" then
        if not TomoModDB then return end
        -- ========================================
        -- MODULES EXISTANTS
        -- ========================================
        if TomoMod_Minimap then 
            TomoMod_Minimap.Initialize() 
        end
        if TomoMod_InfoPanel then 
            TomoMod_InfoPanel.Initialize() 
        end
        if TomoMod_CursorRing then 
            TomoMod_CursorRing.Initialize() 
        end
        if TomoMod_CinematicSkip then 
            TomoMod_CinematicSkip.Initialize() 
        end
        if TomoMod_AutoQuest then 
            TomoMod_AutoQuest.Initialize() 
        end
        -- ========================================
        -- NOUVEAUX MODULES
        -- ========================================
        if TomoMod_SkyRide then 
            TomoMod_SkyRide.Initialize() 
        end
        if TomoMod_CombatInfo then 
            TomoMod_CombatInfo.Initialize() 
        end
        if TomoMod_AutoAcceptInvite then
            TomoMod_AutoAcceptInvite.Initialize()
        end
        if TomoMod_AutoSummon then
            TomoMod_AutoSummon.Initialize()
        end
        if TomoMod_HideCastBar then
            TomoMod_HideCastBar.Initialize()
        end
        if TomoMod_AutoFillDelete then
            TomoMod_AutoFillDelete.Initialize()
        end
        -- Message de bienvenue
        print("|cff00ff00TomoMod|r v1.2 chargé - /tm pour config, /tm help pour aide")
    end
end)
-- =====================================
-- Init.lua — Addon Initialization & Module System
-- =====================================

local addonName = ...
local mainFrame = CreateFrame("Frame")

-- =====================================
-- MODULE SYSTEM (backward compat)
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
-- SLASH COMMANDS
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
        end
    elseif msg == "key" then
        TomoMod_EnableModule("MythicKeys")
        if MK then MK:Toggle() end
    elseif msg == "skyride" then
        TomoMod_ResetModule("skyRide")
        if TomoMod_SkyRide then
            TomoMod_SkyRide.Initialize()
        end
    elseif msg == "skyride toggle" or msg == "sr" then
        if TomoMod_SkyRide and TomoMod_SkyRide.ToggleLock then
            TomoMod_SkyRide.ToggleLock()
        end
    elseif msg == "cdm" or msg == "ci" then
        if TomoMod_CombatInfo then
            local enabled = TomoModDB and TomoModDB.combatInfo and TomoModDB.combatInfo.enabled
            print("|cff0cd29fTomoMod CombatInfo:|r " .. (enabled and "Activé" or "Désactivé"))
        end
    elseif msg == "uf" or msg == "unitframes" then
        if TomoMod_UnitFrames and TomoMod_UnitFrames.ToggleLock then
            TomoMod_UnitFrames.ToggleLock()
        end
    elseif msg == "uf reset" then
        TomoMod_ResetModule("unitFrames")
        ReloadUI()
    elseif msg == "np" or msg == "nameplates" then
        if TomoModDB and TomoModDB.nameplates then
            TomoModDB.nameplates.enabled = not TomoModDB.nameplates.enabled
            if TomoMod_Nameplates then
                if TomoModDB.nameplates.enabled then
                    TomoMod_Nameplates.Enable()
                else
                    TomoMod_Nameplates.Disable()
                end
            end
            print("|cff0cd29fTomoMod Nameplates:|r " .. (TomoModDB.nameplates.enabled and "Activées" or "Désactivées"))
        end
    elseif msg == "help" or msg == "?" then
        print("|cff0cd29fTomoMod|r v2.0 — Commandes:")
        print("  |cff0cd29f/tm|r — Ouvrir la configuration")
        print("  |cff0cd29f/tm reset|r — Réinitialiser tout + reload")
        print("  |cff0cd29f/tm uf|r — Toggle Lock/Unlock UnitFrames")
        print("  |cff0cd29f/tm uf reset|r — Réinitialiser UnitFrames")
        print("  |cff0cd29f/tm np|r — Toggle Nameplates on/off")
        print("  |cff0cd29f/tm minimap|r — Reset minimap")
        print("  |cff0cd29f/tm panel|r — Reset info panel")
        print("  |cff0cd29f/tm cursor|r — Reset cursor ring")
        print("  |cff0cd29f/tm clearcinema|r — Clear cinematic history")
        print("  |cff0cd29f/tm sr|r — Toggle SkyRide lock")
        print("  |cff0cd29f/tm key|r — Open Mythic+ Keys")
        print("  |cff0cd29f/tm help|r — This help")
    else
        -- Open config
        if TomoMod_Config and TomoMod_Config.Toggle then
            TomoMod_Config.Toggle()
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
        TomoMod_InitDatabase()

    elseif event == "PLAYER_LOGIN" then
        if not TomoModDB then return end

        -- QOL Modules
        if TomoMod_Minimap then TomoMod_Minimap.Initialize() end
        if TomoMod_InfoPanel then TomoMod_InfoPanel.Initialize() end
        if TomoMod_CursorRing then TomoMod_CursorRing.Initialize() end
        if TomoMod_CinematicSkip then TomoMod_CinematicSkip.Initialize() end
        if TomoMod_AutoQuest then TomoMod_AutoQuest.Initialize() end
        if TomoMod_SkyRide then TomoMod_SkyRide.Initialize() end
        if TomoMod_CombatInfo then TomoMod_CombatInfo.Initialize() end
        if TomoMod_AutoAcceptInvite then TomoMod_AutoAcceptInvite.Initialize() end
        if TomoMod_AutoSummon then TomoMod_AutoSummon.Initialize() end
        if TomoMod_HideCastBar then TomoMod_HideCastBar.Initialize() end
        if TomoMod_AutoFillDelete then TomoMod_AutoFillDelete.Initialize() end

        -- Interface Modules (new v2)
        if TomoMod_UnitFrames then TomoMod_UnitFrames.Initialize() end
        if TomoMod_Nameplates then TomoMod_Nameplates.Initialize() end

        -- Welcome
        local r, g, b = TomoMod_Utils.GetClassColor()
        print("|cff0cd29fTomoMod|r v2.0 chargé — " .. TomoMod_Utils.ColorText("/tm", r, g, b) .. " pour config")
    end
end)

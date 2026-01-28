-- =====================================
-- Core.lua
-- Initialisation principale de TomoMod
-- =====================================

local addonName = "TomoMod"
local mainFrame = CreateFrame("Frame")

SLASH_TOMOMOD1 = "/tomomod"
SLASH_TOMOMOD2 = "/tm"
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
        if TomoMod_CinematicSkip then TomoMod_CinematicSkip.ClearHistory() end
    elseif msg == "castbar" then
        TomoMod_ResetModule("castBars")
        print("|cff00ff00TomoMod:|r Cast Bar reset - /reload")
    elseif msg == "unitframes" or msg == "uf" then
        TomoMod_ResetModule("unitFrames")
        print("|cff00ff00TomoMod:|r UnitFrames reset - /reload")
    elseif msg == "preview" then
        TomoMod_PreviewMode.Toggle()
    else
        TomoMod_Config.Toggle()
    end
end

mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:RegisterEvent("PLAYER_LOGIN")

mainFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        TomoMod_InitDatabase()
        
    elseif event == "PLAYER_LOGIN" then
        if TomoMod_Minimap then TomoMod_Minimap.Initialize() end
        if TomoMod_InfoPanel then TomoMod_InfoPanel.Initialize() end
        if TomoMod_CursorRing then TomoMod_CursorRing.Initialize() end
        if TomoMod_CinematicSkip then TomoMod_CinematicSkip.Initialize() end
        if TomoMod_AutoQuest then TomoMod_AutoQuest.Initialize() end
        if TomoMod_CastBars then TomoMod_CastBars.Initialize() end
        if TomoMod_UnitFrames then TomoMod_UnitFrames.Initialize() end
        if TomoMod_Auras then TomoMod_Auras.Initialize() end
        if TomoMod_Tooltip then TomoMod_Tooltip.Initialize() end
        
        print("|cff00ff00TomoMod|r v1.14 - /tm pour config, /tm preview pour prévisualisation")
    end
end)
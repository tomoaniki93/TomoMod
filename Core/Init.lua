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

local L = TomoMod_L

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
        if TomoMod_FrameAnchors and TomoMod_FrameAnchors.ToggleLock then
            TomoMod_FrameAnchors.ToggleLock()
        end
        -- Player castbar (standalone drag & drop)
        if TomoMod_UnitFrames and TomoMod_UnitFrames.TogglePlayerCastbarLock then
            TomoMod_UnitFrames.TogglePlayerCastbarLock()
        end
    elseif msg == "cdm" or msg == "ci" then
        if TomoMod_CooldownManager then
            local enabled = TomoModDB and TomoModDB.cooldownManager and TomoModDB.cooldownManager.enabled
            print("|cff0cd29fTomoMod CDM:|r " .. (enabled and L["msg_cdm_status"] or L["msg_cdm_disabled"]))
        end
    elseif msg == "uf" or msg == "unitframes" then
        if TomoMod_UnitFrames and TomoMod_UnitFrames.ToggleLock then
            TomoMod_UnitFrames.ToggleLock()
        end
        if TomoMod_ResourceBars and TomoMod_ResourceBars.ToggleLock then
            TomoMod_ResourceBars.ToggleLock()
        end
    elseif msg == "rb" or msg == "resource" then
        if TomoMod_ResourceBars and TomoMod_ResourceBars.ToggleLock then
            TomoMod_ResourceBars.ToggleLock()
        end
    elseif msg == "rb sync" then
        if TomoMod_ResourceBars and TomoMod_ResourceBars.SyncWidth then
            TomoMod_ResourceBars.SyncWidth()
        end
    elseif msg == "uf reset" then
        TomoMod_ResetModule("unitFrames")
        ReloadUI()
    elseif msg == "cr" then
        if TomoMod_CombatResTracker and TomoMod_CombatResTracker.ToggleLock then
            TomoMod_CombatResTracker.ToggleLock()
        end
    elseif msg == "debugbuffs" then
        if UF_Elements then
            UF_Elements._debugEnemyBuffs = not UF_Elements._debugEnemyBuffs
            print("|cff0cd29fTomoMod|r Enemy buff debug: " .. (UF_Elements._debugEnemyBuffs and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
            if UF_Elements._debugEnemyBuffs then
                print("|cff0cd29fTomoMod|r Target an enemy with a buff, output will appear in chat.")
            end
        end
    elseif msg == "testbuff" then
        print("|cff0cd29f=== TomoMod Enemy Buff Diagnostic ===|r")

        -- Step 0: FORCE reset position to top-right
        local s = TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.target
        if s and s.enemyBuffs then
            s.enemyBuffs.position = { point = "BOTTOMRIGHT", relativePoint = "TOPRIGHT", x = 0, y = 6 }
            print("  [0] |cff00ff00Position RESET to top-right|r")
        end

        -- Step 1: Check settings
        print("  [1] target.enemyBuffs: " .. (s and s.enemyBuffs and "OK enabled=" .. tostring(s.enemyBuffs.enabled) or "|cffff0000MISSING|r"))

        -- Step 2: Check frame
        local frame = _G["TomoMod_UF_target"]
        print("  [2] TomoMod_UF_target: " .. (frame and "EXISTS shown=" .. tostring(frame:IsShown()) or "|cffff0000NIL|r"))

        -- Step 3: Target info (both checks)
        print("  [3] UnitExists target: " .. tostring(UnitExists("target"))
            .. " isEnemy: " .. tostring(UnitExists("target") and UnitIsEnemy("player", "target"))
            .. " canAttack: " .. tostring(UnitExists("target") and UnitCanAttack("player", "target")))

        -- Step 4: Destroy old container, force recreate with new position
        if frame then
            frame.enemyBuffContainer = nil
        end
        if frame and s and s.enemyBuffs then
            frame.enemyBuffContainer = UF_Elements.CreateEnemyBuffContainer(frame, "target", s)
            if frame.enemyBuffContainer then
                local c = frame.enemyBuffContainer
                c:Show()
                local p, _, rp, px, py = c:GetPoint()
                print("  [4] container pos: " .. tostring(p) .. "->" .. tostring(rp)
                    .. " (" .. tostring(px) .. "," .. tostring(py) .. ")"
                    .. " fLevel=" .. c:GetFrameLevel() .. " icons=" .. #c.icons)
                if c.icons and c.icons[1] then
                    c.icons[1].texture:SetTexture("Interface\\Icons\\Spell_Shadow_UnholyStrength")
                    c.icons[1]:Show()
                    print("  [4] |cff00ff00TEST ICON FORCED VISIBLE|r — look top-right of target HP bar!")
                end
            end
        end

        -- Step 5: Query auras
        if UnitExists("target") then
            local ok, err = pcall(function()
                local function testCollect(token, ...)
                    local n = select("#", ...)
                    print("  [5] HELPFUL slots: " .. n)
                    for i = 1, n do
                        local slot = select(i, ...)
                        local data = C_UnitAuras.GetAuraDataBySlot("target", slot)
                        print("      slot " .. i .. "=" .. tostring(slot) .. " data=" .. (data and "OK id=" .. tostring(data.auraInstanceID) or "NIL"))
                    end
                end
                testCollect(C_UnitAuras.GetAuraSlots("target", "HELPFUL"))
            end)
            if not ok then print("  [5] |cffff0000ERROR:|r " .. tostring(err)) end
        end

        -- Step 6: Enable debug
        UF_Elements._debugEnemyBuffs = true
        print("  [6] Debug ON — target a hostile mob, check chat. /tm debugbuffs to disable")

        print("|cff0cd29f=== End Diagnostic ===|r")
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
            print("|cff0cd29fTomoMod Nameplates:|r " .. (TomoModDB.nameplates.enabled and L["msg_np_enabled"] or L["msg_np_disabled"]))
        end
    elseif msg == "help" or msg == "?" then
        print("|cff0cd29fTomoMod|r " .. L["msg_help_title"])
        print("  |cff0cd29f/tm|r — " .. L["msg_help_open"])
        print("  |cff0cd29f/tm reset|r — " .. L["msg_help_reset"])
        print("  |cff0cd29f/tm uf|r — " .. L["msg_help_uf"])
        print("  |cff0cd29f/tm uf reset|r — " .. L["msg_help_uf_reset"])
        print("  |cff0cd29f/tm rb|r — " .. L["msg_help_rb"])
        print("  |cff0cd29f/tm rb sync|r — " .. L["msg_help_rb_sync"])
        print("  |cff0cd29f/tm np|r — " .. L["msg_help_np"])
        print("  |cff0cd29f/tm minimap|r — " .. L["msg_help_minimap"])
        print("  |cff0cd29f/tm panel|r — " .. L["msg_help_panel"])
        print("  |cff0cd29f/tm cursor|r — " .. L["msg_help_cursor"])
        print("  |cff0cd29f/tm clearcinema|r — " .. L["msg_help_clearcinema"])
        print("  |cff0cd29f/tm sr|r — " .. L["msg_help_sr"])
        print("  |cff0cd29f/tm key|r — " .. L["msg_help_key"])
        print("  |cff0cd29f/tm cr|r — " .. L["msg_help_cr"])
        print("  |cff0cd29f/tm help|r — " .. L["msg_help_help"])
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
mainFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

mainFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        TomoMod_InitDatabase()

    elseif event == "PLAYER_LOGIN" then
        if not TomoModDB then return end

        -- Initialiser le tracking des profils par spec
        if TomoMod_Profiles then
            TomoMod_Profiles.EnsureProfilesDB()
            TomoMod_Profiles.InitSpecTracking()
        end

        -- QOL Modules
        if TomoMod_Minimap then TomoMod_Minimap.Initialize() end
        if TomoMod_InfoPanel then TomoMod_InfoPanel.Initialize() end
        if TomoMod_CursorRing then TomoMod_CursorRing.Initialize() end
        if TomoMod_CinematicSkip then TomoMod_CinematicSkip.Initialize() end
        if TomoMod_AutoQuest then TomoMod_AutoQuest.Initialize() end
        if TomoMod_SkyRide then TomoMod_SkyRide.Initialize() end
        if TomoMod_CooldownManager then TomoMod_CooldownManager.Initialize() end
        if TomoMod_AutoAcceptInvite then TomoMod_AutoAcceptInvite.Initialize() end
        if TomoMod_AutoSkipRole then TomoMod_AutoSkipRole.Initialize() end
        if TomoMod_TooltipIDs then TomoMod_TooltipIDs.Initialize() end
        if TomoMod_TooltipSkin then TomoMod_TooltipSkin.Initialize() end
        if TomoMod_CombatResTracker then TomoMod_CombatResTracker.Initialize() end
        if TomoMod_AutoSummon then TomoMod_AutoSummon.Initialize() end
        if TomoMod_HideCastBar then TomoMod_HideCastBar.Initialize() end
        if TomoMod_AutoFillDelete then TomoMod_AutoFillDelete.Initialize() end
        if TomoMod_LustSound then TomoMod_LustSound.Initialize() end
        if TomoMod_FrameAnchors then TomoMod_FrameAnchors.Initialize() end
        if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.Initialize() end

        -- Interface Modules (new v2)
        if TomoMod_UnitFrames then TomoMod_UnitFrames.Initialize() end
        if TomoMod_BossFrames then TomoMod_BossFrames.Initialize() end
        if TomoMod_Nameplates then TomoMod_Nameplates.Initialize() end
        if TomoMod_ResourceBars then TomoMod_ResourceBars.Initialize() end

        -- Welcome
        local r, g, b = TomoMod_Utils.GetClassColor()
        print("|cff0cd29fTomoMod|r " .. string.format(L["msg_loaded"], TomoMod_Utils.ColorText("/tm", r, g, b)))

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 == "player" then
        if TomoMod_Profiles then
            local newSpecID = TomoMod_Profiles.GetCurrentSpecID()
            local needReload = TomoMod_Profiles.OnSpecChanged(newSpecID)
            if needReload then
                print("|cff0cd29fTomoMod|r " .. L["msg_spec_changed_reload"])
                C_Timer.After(0.5, function()
                    ReloadUI()
                end)
            end
        end
    end
end)
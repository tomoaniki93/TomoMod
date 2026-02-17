-- =====================================
-- Init.lua — Addon Initialization & Module System (TomoModMini)
-- =====================================

local addonName = ...
local mainFrame = CreateFrame("Frame")

-- =====================================
-- MODULE SYSTEM (backward compat)
-- =====================================
TomoModMini_Modules = TomoModMini_Modules or {}

function TomoModMini_RegisterModule(name, module)
    TomoModMini_Modules[name] = module
end

function TomoModMini_EnableModule(name)
    if not TomoModMiniDB or not TomoModMiniDB[name] then return end
    if not TomoModMiniDB[name].enabled then return end
    local module = TomoModMini_Modules[name]
    if module and module.Enable then
        module:Enable()
    end
end

local L = TomoModMini_L

-- =====================================
-- SLASH COMMANDS
-- =====================================

SLASH_TomoModMini1 = "/tm"
SLASH_TomoModMini2 = "/TomoModMini"
SlashCmdList["TomoModMini"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "reset" then
        TomoModMini_ResetDatabase()
        ReloadUI()
    elseif msg == "cursor" then
        TomoModMini_ResetModule("cursorRing")
        if TomoModMini_CursorRing then TomoModMini_CursorRing.ApplySettings() end
    elseif msg == "clearcinema" then
        if TomoModMini_CinematicSkip then
            TomoModMini_CinematicSkip.ClearHistory()
        end
    elseif msg == "uf" or msg == "unitframes" then
        if TomoModMini_UnitFrames and TomoModMini_UnitFrames.ToggleLock then
            TomoModMini_UnitFrames.ToggleLock()
        end
        if TomoModMini_ResourceBars and TomoModMini_ResourceBars.ToggleLock then
            TomoModMini_ResourceBars.ToggleLock()
        end
    elseif msg == "rb" or msg == "resource" then
        if TomoModMini_ResourceBars and TomoModMini_ResourceBars.ToggleLock then
            TomoModMini_ResourceBars.ToggleLock()
        end
    elseif msg == "rb sync" then
        if TomoModMini_ResourceBars and TomoModMini_ResourceBars.SyncWidth then
            TomoModMini_ResourceBars.SyncWidth()
        end
    elseif msg == "uf reset" then
        TomoModMini_ResetModule("unitFrames")
        ReloadUI()
    elseif msg == "debugbuffs" then
        if UF_Elements then
            UF_Elements._debugEnemyBuffs = not UF_Elements._debugEnemyBuffs
            print("|cffff3399TomoModMini|r Enemy buff debug: " .. (UF_Elements._debugEnemyBuffs and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
            if UF_Elements._debugEnemyBuffs then
                print("|cffff3399TomoModMini|r Target an enemy with a buff, output will appear in chat.")
            end
        end
    elseif msg == "testbuff" then
        print("|cffff3399=== TomoModMini Enemy Buff Diagnostic ===|r")

        -- Step 0: FORCE reset position to top-right
        local s = TomoModMiniDB and TomoModMiniDB.unitFrames and TomoModMiniDB.unitFrames.target
        if s and s.enemyBuffs then
            s.enemyBuffs.position = { point = "BOTTOMRIGHT", relativePoint = "TOPRIGHT", x = 0, y = 6 }
            print("  [0] |cff00ff00Position RESET to top-right|r")
        end

        -- Step 1: Check settings
        print("  [1] target.enemyBuffs: " .. (s and s.enemyBuffs and "OK enabled=" .. tostring(s.enemyBuffs.enabled) or "|cffff0000MISSING|r"))

        -- Step 2: Check frame
        local frame = _G["TomoModMini_UF_target"]
        print("  [2] TomoModMini_UF_target: " .. (frame and "EXISTS shown=" .. tostring(frame:IsShown()) or "|cffff0000NIL|r"))

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

        print("|cffff3399=== End Diagnostic ===|r")
    elseif msg == "np" or msg == "nameplates" then
        if TomoModMiniDB and TomoModMiniDB.nameplates then
            TomoModMiniDB.nameplates.enabled = not TomoModMiniDB.nameplates.enabled
            if TomoModMini_Nameplates then
                if TomoModMiniDB.nameplates.enabled then
                    TomoModMini_Nameplates.Enable()
                else
                    TomoModMini_Nameplates.Disable()
                end
            end
            print("|cffff3399TomoModMini Nameplates:|r " .. (TomoModMiniDB.nameplates.enabled and L["msg_np_enabled"] or L["msg_np_disabled"]))
        end
    elseif msg == "help" or msg == "?" then
        print("|cffff3399TomoModMini|r " .. L["msg_help_title"])
        print("  |cffff3399/tm|r — " .. L["msg_help_open"])
        print("  |cffff3399/tm reset|r — " .. L["msg_help_reset"])
        print("  |cffff3399/tm uf|r — " .. L["msg_help_uf"])
        print("  |cffff3399/tm uf reset|r — " .. L["msg_help_uf_reset"])
        print("  |cffff3399/tm rb|r — " .. L["msg_help_rb"])
        print("  |cffff3399/tm rb sync|r — " .. L["msg_help_rb_sync"])
        print("  |cffff3399/tm np|r — " .. L["msg_help_np"])
        print("  |cffff3399/tm cursor|r — " .. L["msg_help_cursor"])
        print("  |cffff3399/tm clearcinema|r — " .. L["msg_help_clearcinema"])
        print("  |cffff3399/tm help|r — " .. L["msg_help_help"])
    else
        -- Open config
        if TomoModMini_Config and TomoModMini_Config.Toggle then
            TomoModMini_Config.Toggle()
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
        TomoModMini_InitDatabase()

    elseif event == "PLAYER_LOGIN" then
        if not TomoModMiniDB then return end

        -- Initialiser le tracking des profils par spec
        if TomoModMini_Profiles then
            TomoModMini_Profiles.EnsureProfilesDB()
            TomoModMini_Profiles.InitSpecTracking()
        end

        -- QOL Modules
        if TomoModMini_CursorRing then TomoModMini_CursorRing.Initialize() end
        if TomoModMini_CinematicSkip then TomoModMini_CinematicSkip.Initialize() end
        if TomoModMini_AutoAcceptInvite then TomoModMini_AutoAcceptInvite.Initialize() end
        if TomoModMini_AutoSkipRole then TomoModMini_AutoSkipRole.Initialize() end
        if TomoModMini_AutoSummon then TomoModMini_AutoSummon.Initialize() end
        if TomoModMini_HideCastBar then TomoModMini_HideCastBar.Initialize() end
        if TomoModMini_AutoFillDelete then TomoModMini_AutoFillDelete.Initialize() end
        if TomoModMini_LustSound then TomoModMini_LustSound.Initialize() end
        if TomoModMini_CharacterSkin then TomoModMini_CharacterSkin.Initialize() end

        -- Interface Modules
        if TomoModMini_UnitFrames then TomoModMini_UnitFrames.Initialize() end
        if TomoModMini_Nameplates then TomoModMini_Nameplates.Initialize() end
        if TomoModMini_ResourceBars then TomoModMini_ResourceBars.Initialize() end

        -- Welcome
        local r, g, b = TomoModMini_Utils.GetClassColor()
        print("|cffff3399TomoModMini|r " .. string.format(L["msg_loaded"], TomoModMini_Utils.ColorText("/tm", r, g, b)))

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 == "player" then
        if TomoModMini_Profiles then
            local newSpecID = TomoModMini_Profiles.GetCurrentSpecID()
            local needReload = TomoModMini_Profiles.OnSpecChanged(newSpecID)
            if needReload then
                print("|cffff3399TomoModMini|r " .. L["msg_spec_changed_reload"])
                C_Timer.After(0.5, function()
                    ReloadUI()
                end)
            end
        end
    end
end)

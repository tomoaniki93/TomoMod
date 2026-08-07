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
-- STATIC POPUPS
-- =====================================
StaticPopupDialogs["TOMOMOD_SPEC_RELOAD"] = {
    text = "|cff2ed884TomoMod|r\n" .. (L and L["msg_spec_changed_reload"] or "Spec changed. Reload UI to apply profile?"),
    button1 = OKAY or "OK",
    button2 = CANCEL or "Cancel",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["TOMOMOD_MODULE_RELOAD"] = {
    text = "|cff2ed884TomoMod|r\n" .. (L and L["msg_module_reload"] or "This change requires a UI reload to take effect.\nReload now?"),
    button1 = OKAY or "OK",
    button2 = CANCEL or "Cancel",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- =====================================
-- SLASH COMMANDS
-- =====================================

SLASH_TOMOMOD1 = "/tm"
SLASH_TOMOMOD2 = "/tomomod"
SlashCmdList["TOMOMOD"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "install" or msg == "installer" then
        if TomoMod_Installer then TomoMod_Installer.Show() end
        return
    elseif msg == "reset" then
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
        if TomoMod_MythicKeys then TomoMod_MythicKeys:Toggle() end
    elseif msg == "score" or msg == "tscore" then
        if TomoMod_TomoScore then
            TomoMod_TomoScore:ShowPreview()
        end
    elseif msg == "forge log" or msg == "cdf log" then
        if TomoMod_CooldownForge and TomoMod_CooldownForge.DumpAuraLog then
            TomoMod_CooldownForge.DumpAuraLog()
        end
    elseif msg == "forge" or msg == "cdf" then
        if TomoMod_CooldownForge and TomoMod_CooldownForge.DumpAura then
            TomoMod_CooldownForge.DumpAura()
        end
    elseif msg == "keys" or msg == "key list" then
        -- Live group board: names, M+ score and everyone's keystone. Distinct
        -- from "score", which opens the sample data used to lay out the frame.
        if TomoMod_TomoScore then
            TomoMod_TomoScore:ShowGroup()
        end
    elseif msg == "score last" then
        if TomoMod_TomoScore then
            TomoMod_TomoScore:ShowLastRun()
        end
    elseif msg == "loot" or msg == "loots" then
        if TomoMod_Loots then
            TomoMod_Loots:Toggle()
        end
    elseif msg:sub(1, 3) == "way" then
        if TomoMod_Waypoint then
            local args = msg:sub(5)  -- strip "way" + space
            TomoMod_Waypoint.HandleSlashCommand(args)
        end
    elseif msg == "compass" then
        if TomoMod_Compass then TomoMod_Compass.Toggle() end
    elseif msg == "compass debug" then
        if TomoMod_Compass and TomoMod_Compass.Debug then TomoMod_Compass.Debug() end
    elseif msg == "mhub" or msg == "mythichub" then
        if TomoMod_MythicHub then
            TomoMod_MythicHub:Toggle()
        end
    elseif msg == "skyride" then
        TomoMod_ResetModule("skyRide")
        if TomoMod_SkyRide then
            TomoMod_SkyRide.Initialize()
        end
    elseif msg == "layout" or msg == "l" then
        -- Nouveau système unifié — ouvre le mode Layout pour tout déplacer
        if TomoMod_Movers and TomoMod_Movers.Toggle then
            TomoMod_Movers.Toggle()
        end
    elseif msg == "skyride toggle" or msg == "sr" then
        -- Rétrocompat: sr active aussi le mode Layout complet
        if TomoMod_Movers and TomoMod_Movers.Toggle then
            TomoMod_Movers.Toggle()
        else
            -- Fallback legacy
            if TomoMod_SkyRide and TomoMod_SkyRide.ToggleLock then
                TomoMod_SkyRide.ToggleLock()
            end
            if TomoMod_FrameAnchors and TomoMod_FrameAnchors.ToggleLock then
                TomoMod_FrameAnchors.ToggleLock()
            end
            if TomoMod_LevelingBar and TomoMod_LevelingBar.ToggleLock then
                TomoMod_LevelingBar.ToggleLock()
            end
        end
    elseif msg == "prof" or msg == "ph" then
        if TomoMod_ProfessionHelper then
            TomoMod_ProfessionHelper.Toggle()
        end
    elseif msg == "cdm" or msg == "ci" then
        if TomoMod_CooldownManager then
            local enabled = TomoModDB and TomoModDB.cooldownManager and TomoModDB.cooldownManager.enabled
            print("|cff2ed884TomoMod CDM:|r " .. (enabled and L["msg_cdm_status"] or L["msg_cdm_disabled"]))
        end
    elseif msg == "uf" or msg == "unitframes" then
        -- Rétrocompat: redirige vers le Layout Mode unifié
        if TomoMod_Movers and TomoMod_Movers.Toggle then
            TomoMod_Movers.Toggle()
        else
            if TomoMod_UnitFrames and TomoMod_UnitFrames.ToggleLock then
                TomoMod_UnitFrames.ToggleLock()
            end
            if TomoMod_ResourceBars and TomoMod_ResourceBars.ToggleLock then
                TomoMod_ResourceBars.ToggleLock()
            end
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
            print("|cff2ed884TomoMod|r Enemy buff debug: " .. (UF_Elements._debugEnemyBuffs and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
            if UF_Elements._debugEnemyBuffs then
                print("|cff2ed884TomoMod|r Target an enemy with a buff, output will appear in chat.")
            end
        end
    elseif msg == "testbuff" then
        print("|cff2ed884=== TomoMod Enemy Buff Diagnostic ===|r")

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

        print("|cff2ed884=== End Diagnostic ===|r")
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
            print("|cff2ed884TomoMod Nameplates:|r " .. (TomoModDB.nameplates.enabled and L["msg_np_enabled"] or L["msg_np_disabled"]))
        end
    elseif msg == "help" or msg == "?" then
        print("|cff2ed884TomoMod|r " .. L["msg_help_title"])
        print("  |cff2ed884/tm install|r — Relancer l'assistant de configuration")
        print("  |cff2ed884/tm layout|r — " .. L["msg_help_layout"])
        print("  |cff2ed884/tm|r — " .. L["msg_help_open"])
        print("  |cff2ed884/tm reset|r — " .. L["msg_help_reset"])
        print("  |cff2ed884/tm uf|r — " .. L["msg_help_uf"])
        print("  |cff2ed884/tm uf reset|r — " .. L["msg_help_uf_reset"])
        print("  |cff2ed884/tm rb|r — " .. L["msg_help_rb"])
        print("  |cff2ed884/tm rb sync|r — " .. L["msg_help_rb_sync"])
        print("  |cff2ed884/tm np|r — " .. L["msg_help_np"])
        print("  |cff2ed884/tm minimap|r — " .. L["msg_help_minimap"])
        print("  |cff2ed884/tm panel|r — " .. L["msg_help_panel"])
        print("  |cff2ed884/tm cursor|r — " .. L["msg_help_cursor"])
        print("  |cff2ed884/tm clearcinema|r — " .. L["msg_help_clearcinema"])
        print("  |cff2ed884/tm sr|r — " .. L["msg_help_sr"])
        print("  |cff2ed884/tm loot|r — Ouvrir le navigateur de loots (donjons & raids)")
        print("  |cff2ed884/tm way|r — " .. L["msg_help_way"])
        print("  |cff2ed884/tm way x y [name]|r — " .. L["msg_help_way_coords"])
        print("  |cff2ed884/tm way clear|r — " .. L["msg_help_way_clear"])
        print("  |cff2ed884/tm compass|r — " .. (L["msg_help_compass"] or "Toggle the heading compass bar"))
        print("  |cff2ed884/tm key|r — " .. L["msg_help_key"])
        print("  |cff2ed884/tm cr|r — " .. L["msg_help_cr"])
        print("  |cff2ed884/tm help|r — " .. L["msg_help_help"])
    else
        -- Argument purement numérique : soit une macro tierce (ex : RareScanner
        -- « marqueur sur la cible » → « /tm <1-8> »), soit une tentative d'utiliser
        -- la commande native « /tm <0-8> » (marqueur de raid) que TomoMod masque en
        -- possédant « /tm ».
        -- IMPORTANT : on ne peut PAS poser le marqueur ici — SetRaidTarget() est une
        -- fonction protégée et lève ADDON_ACTION_FORBIDDEN (taint) depuis du code
        -- addon. On ignore donc l'argument pour ne pas ouvrir la config par erreur.
        -- Pour poser un marqueur : commande native « /targetmarker <0-8> » (non
        -- interceptée par TomoMod).
        if msg:match("^%s*%d+%s*$") then
            return
        end
        -- Open config (/tm seul, ou argument inconnu non numérique)
        if TomoMod_Config and TomoMod_Config.Toggle then
            TomoMod_Config.Toggle()
        end
    end
end

-- =====================================
-- CONVENIENCE SLASH COMMANDS
-- =====================================

SLASH_TOMOMOD_RL1 = "/rl"
SlashCmdList["TOMOMOD_RL"] = ReloadUI

SLASH_TOMOMOD_KB1 = "/kb"
SlashCmdList["TOMOMOD_KB"] = function()
    Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID or BINDING_HEADER or "Keybindings")
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
            -- Auto-save : sauvegarder le profil actif à la fermeture du panneau Config
            C_Timer.After(1, function()
                local configFrame = _G["TomoModConfigFrame"]
                if configFrame and not configFrame._profileAutoSaveHooked then
                    configFrame._profileAutoSaveHooked = true
                    configFrame:HookScript("OnHide", function()
                        if TomoMod_Profiles then
                            TomoMod_Profiles.AutoSaveActiveProfile()
                        end
                    end)
                end
            end)
        end

        -- [SAFETY] Each Initialize() is wrapped so a single failing module
        -- (typically on a fresh install with missing DB fields) doesn't break
        -- the rest of the chain — notably TomoMod_Movers, which would leave
        -- the Layout button silently unresponsive.
        local function safeInit(name, mod)
            if not mod or not mod.Initialize then return end
            -- [fix] The handler used to be `debugstack` itself. Its first
            -- argument is a numeric START INDEX, not an error message, so the
            -- message xpcall handed it was silently discarded: "Init failed"
            -- reported a bare stack trace that said WHERE the xpcall was but
            -- never WHAT went wrong, which made these reports undiagnosable.
            -- Keep both, message first so it survives chat scrollback.
            local ok, err = xpcall(mod.Initialize, function(msg)
                -- level 2 = the error site (level 1 is this handler)
                return tostring(msg) .. "\n" .. debugstack(2)
            end)
            if not ok then
                print("|cff2ed884TomoMod|r |cffff4040Init failed:|r " .. name .. " — " .. tostring(err))
                local handler = geterrorhandler and geterrorhandler()
                if handler then handler("TomoMod " .. name .. " Initialize: " .. tostring(err)) end
            end
        end

        -- QOL Modules
        safeInit("Minimap",            TomoMod_Minimap)
        safeInit("InfoPanel",          TomoMod_InfoPanel)
        safeInit("CursorRing",         TomoMod_CursorRing)
        safeInit("CinematicSkip",      TomoMod_CinematicSkip)
        safeInit("AutoQuest",          TomoMod_AutoQuest)
        safeInit("ObjectiveTracker",   TomoMod_ObjectiveTracker)
        safeInit("SkyRide",            TomoMod_SkyRide)
        safeInit("LevelingBar",        TomoMod_LevelingBar)
        --safeInit("ConsumableBar",      TomoMod_ConsumableBar)
        safeInit("RareAlert",          TomoMod_RareAlert)
        safeInit("Compass",            TomoMod_Compass)
        safeInit("ReputationBar",      TomoMod_ReputationBar)
        safeInit("CooldownManager",    TomoMod_CooldownManager)
        safeInit("AddonDetect",        TomoMod_AddonDetect)
        safeInit("AutoAcceptInvite",   TomoMod_AutoAcceptInvite)
        safeInit("AutoSkipRole",       TomoMod_AutoSkipRole)
        safeInit("TooltipIDs",         TomoMod_TooltipIDs)
        safeInit("AutoSummon",         TomoMod_AutoSummon)
        safeInit("HideCastBar",        TomoMod_HideCastBar)
        safeInit("BagMicroMenu",       TomoMod_BagMicroMenu)
        safeInit("AutoFillDelete",     TomoMod_AutoFillDelete)
        safeInit("LustSound",          TomoMod_LustSound)
        safeInit("ClassReminder",      TomoMod_ClassReminder)
        safeInit("AFKDisplay",         TomoMod_AFKDisplay)
        safeInit("FrameAnchors",       TomoMod_FrameAnchors)
        safeInit("ProfessionHelper",   TomoMod_ProfessionHelper)
        safeInit("Waypoint",           TomoMod_Waypoint)
        safeInit("Loots",              TomoMod_Loots)
        safeInit("WorldQuestTab",      TomoMod_WorldQuestTab)
        safeInit("ActionBarSkin",      TomoMod_ActionBarSkin)
        safeInit("AuraTracker",        TomoMod_AuraTracker)
        safeInit("CharacterSkin",      TomoMod_CharacterSkin)
        safeInit("ChatFrameSkin",      TomoMod_ChatFrameSkin)
        safeInit("BuffSkin",           TomoMod_BuffSkin)
        safeInit("GameMenuSkin",       TomoMod_GameMenuSkin)
        safeInit("TooltipSkin",        TomoMod_TooltipSkin)
        safeInit("GroupManagerSkin",   TomoMod_GroupManagerSkin)

        -- Interface Modules (new v2)
        safeInit("UnitFrames",         TomoMod_UnitFrames)
        safeInit("BossFrames",         TomoMod_BossFrames)
        safeInit("Nameplates",         TomoMod_Nameplates)
        safeInit("ResourceBars",       TomoMod_ResourceBars)
        safeInit("Castbar",            TomoMod_Castbar)
        safeInit("PartyFrames",        TomoMod_PartyFrames)
        safeInit("PartyCooldowns",     TomoMod_PartyCooldowns)
        safeInit("ArenaFrames",        TomoMod_ArenaFrames)
        safeInit("RaidFrames",         TomoMod_RaidFrames)
        safeInit("ResurrectTracker",   TomoMod_ResurrectTracker)

        -- Layout Mover System (doit être après tous les autres modules)
        safeInit("Movers",             TomoMod_Movers)

        -- Welcome
        local r, g, b = TomoMod_Utils.GetClassColor()
        print("|cff2ed884TomoMod|r " .. string.format(L["msg_loaded"], TomoMod_Utils.ColorText("/tm", r, g, b)))
        print("|cff2ed884TomoMod|r |cffff3333" .. L["msg_report_issue"] .. "|r")

        -- What's New popup (after update)
        if TomoMod_WhatsNew then
            C_Timer.After(3, function() TomoMod_WhatsNew.TryShow() end)
        end

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 == "player" then
        if TomoMod_Profiles then
            local newSpecID = TomoMod_Profiles.GetCurrentSpecID()
            local needReload = TomoMod_Profiles.OnSpecChanged(newSpecID)
            if needReload then
                StaticPopup_Show("TOMOMOD_SPEC_RELOAD")
            end
        end
    end
end)
-- =====================================
-- AutoSkipRole.lua
-- Auto-confirm le Role Check (LFG) et
-- le Role Poll (vérification en groupe)
-- =====================================

TomoMod_AutoSkipRole = TomoMod_AutoSkipRole or {}
local ASR = TomoMod_AutoSkipRole

-- =====================================
-- VARIABLES
-- =====================================
local mainFrame

-- =====================================
-- FONCTIONS UTILITAIRES
-- =====================================
local function GetSettings()
    if not TomoModDB or not TomoModDB.autoSkipRole then
        return nil
    end
    return TomoModDB.autoSkipRole
end

-- =====================================
-- EVENEMENTS
-- =====================================
local function OnEvent(self, event, ...)
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    if event == "LFG_ROLE_CHECK_SHOW" then
        -- LFG role check (queue confirmation) — auto-accept
        CompleteLFGRoleCheck(true)

        if settings.showMessages then
            print("|cff0cd29fTomoMod:|r " .. TomoMod_L["msg_asr_lfg_accepted"])
        end

    elseif event == "ROLE_POLL_BEGIN" then
        -- In-group role poll — auto-accept after short delay
        -- (the popup needs a frame to render before we can click)
        C_Timer.After(0.1, function()
            if RolePollPopup and RolePollPopup:IsShown() then
                if RolePollPopup.acceptButton then
                    RolePollPopup.acceptButton:Click()
                end
            end

            if settings.showMessages then
                print("|cff0cd29fTomoMod:|r " .. TomoMod_L["msg_asr_poll_accepted"])
            end
        end)
    end
end

-- =====================================
-- FONCTIONS PUBLIQUES
-- =====================================
function ASR.Initialize()
    if not TomoModDB or not TomoModDB.autoSkipRole then return end

    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    if not mainFrame then
        mainFrame = CreateFrame("Frame")
    end
    mainFrame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
    mainFrame:RegisterEvent("ROLE_POLL_BEGIN")
    mainFrame:SetScript("OnEvent", OnEvent)
end

function ASR.SetEnabled(enabled)
    local settings = GetSettings()
    if not settings then return end

    settings.enabled = enabled

    if enabled then
        if not mainFrame then
            ASR.Initialize()
        else
            mainFrame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
            mainFrame:RegisterEvent("ROLE_POLL_BEGIN")
            mainFrame:SetScript("OnEvent", OnEvent)
        end
        print("|cff0cd29fTomoMod:|r " .. TomoMod_L["msg_asr_enabled"])
    else
        if mainFrame then
            mainFrame:UnregisterAllEvents()
            mainFrame:SetScript("OnEvent", nil)
        end
        print("|cff0cd29fTomoMod:|r " .. TomoMod_L["msg_asr_disabled"])
    end
end

function ASR.Toggle()
    local settings = GetSettings()
    if not settings then return end
    ASR.SetEnabled(not settings.enabled)
end

-- Export
_G.TomoMod_AutoSkipRole = ASR

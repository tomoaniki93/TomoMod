-- =====================================
-- HideCastBar.lua
-- Cache la barre de cast du joueur
-- =====================================

TomoModMini_HideCastBar = TomoModMini_HideCastBar or {}
local HCB = TomoModMini_HideCastBar

-- =====================================
-- FONCTION PRINCIPALE
-- =====================================
local function HideCastBar()
    local settings = TomoModMiniDB and TomoModMiniDB.hideCastBar
    if not settings or not settings.enabled then
        -- Réafficher si désactivé
        if PlayerCastingBarFrame then
            PlayerCastingBarFrame:SetAlpha(1)
        end
        return
    end
    
    -- Cacher la barre de cast du joueur
    if PlayerCastingBarFrame then
        PlayerCastingBarFrame:SetAlpha(0)
        PlayerCastingBarFrame:UnregisterAllEvents()
    end
end

-- =====================================
-- INITIALISATION
-- =====================================
function HCB.Initialize()
    if not TomoModMiniDB then
        print("|cffff0000TomoModMini HideCastBar:|r " .. TomoModMini_L["msg_hcb_db_not_init"])
        return
    end
    
    -- Initialiser les settings
    if not TomoModMiniDB.hideCastBar then
        TomoModMiniDB.hideCastBar = {
            enabled = false, -- Désactivé par défaut
        }
    end
    
    -- Attendre que l'interface soit chargée
    C_Timer.After(1, HideCastBar)
    
    print("|cff00ff00TomoModMini HideCastBar:|r " .. TomoModMini_L["msg_hcb_initialized"])
end

function HCB.SetEnabled(enabled)
    if not TomoModMiniDB or not TomoModMiniDB.hideCastBar then return end
    
    TomoModMiniDB.hideCastBar.enabled = enabled
    HideCastBar()
    
    if enabled then
        print("|cff00ff00TomoModMini:|r " .. TomoModMini_L["msg_hcb_hidden"])
    else
        print("|cff00ff00TomoModMini:|r " .. TomoModMini_L["msg_hcb_shown"])
    end
end

function HCB.Toggle()
    if not TomoModMiniDB or not TomoModMiniDB.hideCastBar then return end
    
    local newState = not TomoModMiniDB.hideCastBar.enabled
    HCB.SetEnabled(newState)
end

-- Export
_G.TomoModMini_HideCastBar = HCB

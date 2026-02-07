-- =====================================
-- HideCastBar.lua
-- Cache la barre de cast du joueur
-- =====================================

TomoMod_HideCastBar = TomoMod_HideCastBar or {}
local HCB = TomoMod_HideCastBar

-- =====================================
-- FONCTION PRINCIPALE
-- =====================================
local function HideCastBar()
    local settings = TomoModDB and TomoModDB.hideCastBar
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
    if not TomoModDB then
        print("|cffff0000TomoMod HideCastBar:|r " .. TomoMod_L["msg_hcb_db_not_init"])
        return
    end
    
    -- Initialiser les settings
    if not TomoModDB.hideCastBar then
        TomoModDB.hideCastBar = {
            enabled = false, -- Désactivé par défaut
        }
    end
    
    -- Attendre que l'interface soit chargée
    C_Timer.After(1, HideCastBar)
    
    print("|cff00ff00TomoMod HideCastBar:|r " .. TomoMod_L["msg_hcb_initialized"])
end

function HCB.SetEnabled(enabled)
    if not TomoModDB or not TomoModDB.hideCastBar then return end
    
    TomoModDB.hideCastBar.enabled = enabled
    HideCastBar()
    
    if enabled then
        print("|cff00ff00TomoMod:|r " .. TomoMod_L["msg_hcb_hidden"])
    else
        print("|cff00ff00TomoMod:|r " .. TomoMod_L["msg_hcb_shown"])
    end
end

function HCB.Toggle()
    if not TomoModDB or not TomoModDB.hideCastBar then return end
    
    local newState = not TomoModDB.hideCastBar.enabled
    HCB.SetEnabled(newState)
end

-- Export
_G.TomoMod_HideCastBar = HCB

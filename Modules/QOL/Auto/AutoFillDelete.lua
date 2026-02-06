-- =====================================
-- TomoMod_AutoFillDelete.lua
-- Auto-remplit "DELETE" dans les popups de destruction d'objets
-- =====================================

TomoMod_AutoFillDelete = TomoMod_AutoFillDelete or {}
local AFD = TomoMod_AutoFillDelete

-- =====================================
-- VARIABLES
-- =====================================
local isHooked = false

-- =====================================
-- FONCTIONS UTILITAIRES
-- =====================================
local function GetSettings()
    if not TomoModDB or not TomoModDB.autoFillDelete then
        return nil
    end
    return TomoModDB.autoFillDelete
end

-- =====================================
-- HOOK DE STATICPOPUP
-- =====================================
local function AutoFillDeleteText(dialog)
    local settings = GetSettings()
    if not settings or not settings.enabled then
        return
    end
    
    -- Vérifier que c'est bien un popup DELETE_ITEM
    if not dialog or dialog.which ~= "DELETE_ITEM" and dialog.which ~= "DELETE_GOOD_ITEM" and dialog.which ~= "DELETE_QUEST_ITEM" then
        return
    end
    
    -- Obtenir l'editbox
    local editBox = dialog.editBox
    if not editBox then
        return
    end
    
    -- Remplir automatiquement avec DELETE
    editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
    editBox:HighlightText()
    
    -- Focus sur le bouton OK pour permettre Enter
    if settings.focusButton and dialog.button1 then
        dialog.button1:SetFocus()
    end
    
    if settings.showMessages then
        print("|cff00ff00TomoMod:|r Texte 'DELETE' auto-rempli - Cliquez OK pour confirmer")
    end
end

local function HookStaticPopups()
    if isHooked then return end
    
    -- Hook la fonction StaticPopup_Show
    hooksecurefunc("StaticPopup_Show", function(which, text_arg1, text_arg2, data, insertedFrame)
        -- Vérifier si c'est un popup de suppression
        if which == "DELETE_ITEM" or which == "DELETE_GOOD_ITEM" or which == "DELETE_QUEST_ITEM" then
            -- Attendre que le popup soit créé
            C_Timer.After(0.1, function()
                for i = 1, STATICPOPUP_NUMDIALOGS do
                    local dialog = _G["StaticPopup" .. i]
                    if dialog and dialog:IsShown() and dialog.which == which then
                        AutoFillDeleteText(dialog)
                        break
                    end
                end
            end)
        end
    end)
    
    isHooked = true
end

-- =====================================
-- FONCTIONS PUBLIQUES
-- =====================================
function AFD.Initialize()
    if not TomoModDB then
        print("|cffff0000TomoMod AutoFillDelete:|r TomoModDB non initialisée")
        return
    end
    
    -- Initialiser les settings
    if not TomoModDB.autoFillDelete then
        TomoModDB.autoFillDelete = {
            enabled = true, -- Activé par défaut (juste un helper)
            focusButton = true, -- Focus sur OK après remplissage
            showMessages = false, -- Pas de spam
        }
    end
    
    local settings = GetSettings()
    if not settings.enabled then
        return
    end
    
    -- Hook les popups
    HookStaticPopups()
    
    print("|cff00ff00TomoMod AutoFillDelete:|r Module initialisé")
end

function AFD.SetEnabled(enabled)
    local settings = GetSettings()
    if not settings then return end
    
    settings.enabled = enabled
    
    if enabled then
        if not isHooked then
            HookStaticPopups()
        end
        print("|cff00ff00TomoMod:|r Auto-fill DELETE activé")
    else
        print("|cffffff00TomoMod:|r Auto-fill DELETE désactivé (hook reste actif)")
    end
end

function AFD.Toggle()
    local settings = GetSettings()
    if not settings then return end
    
    AFD.SetEnabled(not settings.enabled)
end

-- Export
_G.TomoMod_AutoFillDelete = AFD

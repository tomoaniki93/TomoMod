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

    -- Verifier que c'est bien un popup DELETE_ITEM
    if not dialog then return end
    if dialog.which ~= "DELETE_ITEM"
        and dialog.which ~= "DELETE_GOOD_ITEM"
        and dialog.which ~= "DELETE_QUEST_ITEM" then
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

    -- SetFocus() n'existe que sur les EditBox, pas les Button.
    -- On refocus l'editbox pour que Enter fonctionne directement.
    if settings.focusButton and editBox then
        editBox:SetFocus()
    end

    if settings.showMessages then
        print("|cff0cd29fTomoMod:|r Texte 'DELETE' auto-rempli - Cliquez OK pour confirmer")
    end
end

local function HookStaticPopups()
    if isHooked then return end

    hooksecurefunc("StaticPopup_Show", function(which)
        if which == "DELETE_ITEM" or which == "DELETE_GOOD_ITEM" or which == "DELETE_QUEST_ITEM" then
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
    if not TomoModDB or not TomoModDB.autoFillDelete then return end

    local settings = GetSettings()
    if not settings or not settings.enabled then
        return
    end

    HookStaticPopups()
end

function AFD.SetEnabled(enabled)
    local settings = GetSettings()
    if not settings then return end

    settings.enabled = enabled

    if enabled then
        if not isHooked then
            HookStaticPopups()
        end
        print("|cff0cd29fTomoMod:|r Auto-fill DELETE active")
    else
        print("|cff0cd29fTomoMod:|r Auto-fill DELETE desactive (hook reste actif)")
    end
end

function AFD.Toggle()
    local settings = GetSettings()
    if not settings then return end
    AFD.SetEnabled(not settings.enabled)
end

-- Export
_G.TomoMod_AutoFillDelete = AFD

-- =====================================
-- TomoMod_AutoFillDelete.lua
-- Auto-remplit "DELETE/SUPPRIMER" dans les popups de destruction d'objets
-- Compatible TWW (The War Within) — Interface 12.x
-- =====================================

TomoMod_AutoFillDelete = TomoMod_AutoFillDelete or {}
local AFD = TomoMod_AutoFillDelete

-- =====================================
-- VARIABLES
-- =====================================
local isHooked = false
local L = TomoMod_L

-- All known delete confirmation popup types (TWW compatible)
local DELETE_POPUPS = {
    ["DELETE_ITEM"]              = true,
    ["DELETE_GOOD_ITEM"]         = true,
    ["DELETE_QUEST_ITEM"]        = true,
    ["DELETE_GOOD_QUEST_ITEM"]   = true,
}

-- =====================================
-- SETTINGS
-- =====================================
local function GetSettings()
    if not TomoModDB or not TomoModDB.autoFillDelete then
        return nil
    end
    return TomoModDB.autoFillDelete
end

-- =====================================
-- CORE: AUTO-FILL THE EDITBOX
-- =====================================
local function TryAutoFill(dialog)
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    -- Verify it's a delete popup
    if not dialog or not dialog.which or not DELETE_POPUPS[dialog.which] then
        return
    end

    -- Get the editbox — try dialog.editBox first, then named fallback
    local editBox = dialog.editBox
    if not editBox and dialog.GetName then
        local name = dialog:GetName()
        if name then
            editBox = _G[name .. "EditBox"]
        end
    end

    if not editBox or not editBox.SetText then return end

    -- Fill with the localized confirm string (DELETE / SUPPRIMER / etc.)
    local confirmString = DELETE_ITEM_CONFIRM_STRING
    if not confirmString or confirmString == "" then return end

    editBox:SetText(confirmString)
    editBox:HighlightText()
    editBox:SetCursorPosition(#confirmString)

    -- Focus the editbox (NOT the button — buttons don't support SetFocus)
    if settings.focusButton then
        editBox:ClearFocus()
    end

    if settings.showMessages then
        print("|cff0cd29fTomoMod:|r " .. L["msg_afd_filled"])
    end
end

-- =====================================
-- HOOK SETUP
-- =====================================
local function HookStaticPopups()
    if isHooked then return end

    -- Method 1: Hook OnShow on each delete dialog template
    -- More reliable than hooking StaticPopup_Show + timer
    for popupType in pairs(DELETE_POPUPS) do
        local dialogInfo = StaticPopupDialogs[popupType]
        if dialogInfo then
            local origOnShow = dialogInfo.OnShow
            dialogInfo.OnShow = function(self, ...)
                if origOnShow then
                    origOnShow(self, ...)
                end
                -- Delay slightly to run AFTER Blizzard's OnShow clears the editbox
                C_Timer.After(0.05, function()
                    if self and self:IsShown() then
                        TryAutoFill(self)
                    end
                end)
            end
        end
    end

    -- Method 2: Fallback hook on StaticPopup_Show for any popup type
    -- that might be added later or that we missed
    hooksecurefunc("StaticPopup_Show", function(which)
        if not DELETE_POPUPS[which] then return end

        C_Timer.After(0.1, function()
            for i = 1, STATICPOPUP_NUMDIALOGS do
                local dialog = _G["StaticPopup" .. i]
                if dialog and dialog:IsShown() and dialog.which == which then
                    TryAutoFill(dialog)
                    break
                end
            end
        end)
    end)

    isHooked = true
end

-- =====================================
-- PUBLIC API
-- =====================================
function AFD.Initialize()
    if not TomoModDB then return end

    -- Ensure defaults exist
    if not TomoModDB.autoFillDelete then
        TomoModDB.autoFillDelete = {
            enabled = true,
            focusButton = true,
            showMessages = false,
        }
    end

    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    HookStaticPopups()
end

function AFD.SetEnabled(enabled)
    local settings = GetSettings()
    if not settings then return end

    settings.enabled = enabled

    if enabled and not isHooked then
        HookStaticPopups()
    end

    if enabled then
        print("|cff0cd29fTomoMod:|r " .. L["msg_afd_enabled"])
    else
        print("|cff0cd29fTomoMod:|r " .. L["msg_afd_disabled"])
    end
end

function AFD.Toggle()
    local settings = GetSettings()
    if not settings then return end
    AFD.SetEnabled(not settings.enabled)
end

-- Export
_G.TomoMod_AutoFillDelete = AFD
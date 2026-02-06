-- =====================================
-- Panels/Profiles.lua — Profiles & Import/Export
-- =====================================

local W = TomoMod_Widgets

function TomoMod_ConfigPanel_Profiles(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child

    local y = -10

    local _, ny = W.CreateSectionHeader(c, "Gestion des Profils", y)
    y = ny

    local _, ny = W.CreateInfoText(c, "Réinitialisez des modules individuellement ou exportez/importez vos paramètres.\nL'export copie vos settings dans le presse-papier (nécessite LibSerialize + LibDeflate).", y)
    y = ny

    -- Module resets
    local _, ny = W.CreateSectionHeader(c, "Réinitialiser un module", y)
    y = ny

    local modules = {
        { key = "unitFrames",  label = "UnitFrames" },
        { key = "nameplates",  label = "Nameplates" },
        { key = "minimap",     label = "Minimap" },
        { key = "infoPanel",   label = "Info Panel" },
        { key = "cursorRing",  label = "Cursor Ring" },
        { key = "skyRide",     label = "SkyRide" },
        { key = "cooldownManager", label = "Cooldown Manager" },
        { key = "autoQuest",   label = "Auto Quest" },
    }

    for _, mod in ipairs(modules) do
        local _, ny = W.CreateButton(c, "Reset: " .. mod.label, 220, y, function()
            TomoMod_ResetModule(mod.key)
            print("|cff0cd29fTomoMod|r " .. mod.label .. " réinitialisé")
        end)
        y = ny
    end

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateButton(c, "⚠ TOUT Réinitialiser + Reload", 260, y, function()
        StaticPopup_Show("TOMOMOD_RESET_ALL")
    end)
    y = ny - 20

    c:SetHeight(math.abs(y) + 20)
    return scroll
end

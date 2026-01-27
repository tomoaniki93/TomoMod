-- =====================================
-- Database.lua
-- =====================================

-- Variables par défaut pour TomoModDB
TomoMod_Defaults = {
    minimap = {
        enabled = true,
        scale = 1.0,
        borderColor = "class", -- "class" ou "black"
        size = 200,
    },
    infoPanel = {
        enabled = true,
        scale = 1.0,
        borderColor = "black", -- "black" ou "class"
        showDurability = true,
        showTime = true,
        showFPS = false,
        use24Hour = true,
        displayOrder = {"Gear", "Time", "Fps"},
        position = nil,
    },
    cursorRing = {
        enabled = false,
        scale = 1.0,
        useClassColor = false,
        anchorTooltip = false,
    },
    cinematicSkip = {
        enabled = true,
        viewedCinematics = {}, -- Liste des cinématiques déjà vues (partagée entre personnages)
    },
    autoQuest = {
        autoAccept = false,
        autoTurnIn = false,
        autoGossip = false,
    },
    castBars = {
        enabled = true,
        width = 250,
        height = 22,
        position = nil,
        showTargetName = true,
        showSpellName = true,
        flashOnTargeted = true,
        interruptibleColor = {0, 1, 1},
        notInterruptibleColor = {0.5, 0.5, 0.5},
        interruptedColor = {221/255, 160/255, 221/255},
    },
    unitFrames = {
        player = {
            enabled = true,
            width = 200,
            height = 30,
            scale = 1.0,
            minimalist = false,
            position = nil,
            -- Indicateurs visuels
            showLeader = true,
            showRaidMarker = true,
            -- Indicateurs textuels
            showName = true,
            showLevel = true,
            showCurrentHP = true,
            showPercentHP = true,
        },
        target = {
            enabled = true,
            width = 200,
            height = 30,
            scale = 1.0,
            minimalist = false,
            position = nil,
            -- Indicateurs visuels
            showLeader = true,
            showRaidMarker = true,
            -- Indicateurs textuels
            showName = true,
            showLevel = true,
            showCurrentHP = true,
            showPercentHP = true,
        },
        targetoftarget = {
            enabled = true,
            width = 90,
            height = 15, -- Hauteur fixe
            scale = 1.0,
            minimalist = false,
            position = nil,
        }
    },
}

-- Fonction pour initialiser la base de données
function TomoMod_InitDatabase()
    if not TomoModDB then
        TomoModDB = {}
    end
    
    -- Fusionner avec les valeurs par défaut
    TomoMod_MergeTables(TomoModDB, TomoMod_Defaults)
end

-- Fonction pour réinitialiser la base de données
function TomoMod_ResetDatabase()
    TomoModDB = CopyTable(TomoMod_Defaults)
    print("|cff00ff00TomoMod:|r Base de données réinitialisée")
end

-- Fonction pour réinitialiser un module spécifique
function TomoMod_ResetModule(moduleName)
    if TomoMod_Defaults[moduleName] then
        TomoModDB[moduleName] = CopyTable(TomoMod_Defaults[moduleName])
        print("|cff00ff00TomoMod:|r Module '" .. moduleName .. "' réinitialisé")
    end
end
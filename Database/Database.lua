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
            showLeader = true,
            showRaidMarker = true,
            showName = true,
            showLevel = true,
            showCurrentHP = true,
            showPercentHP = true,
            useClassColor = true, -- Nouvelle option: true = couleur classe, false = noir/gris
            showPowerBar = true, -- Nouvelle option: afficher/cacher la barre de ressource
        },
        target = {
            enabled = true,
            width = 200,
            height = 30,
            scale = 1.0,
            minimalist = false,
            position = nil,
            showLeader = true,
            showRaidMarker = true,
            showName = true,
            showLevel = true,
            showCurrentHP = true,
            showPercentHP = true,
            useClassColor = true, -- Nouvelle option: true = couleur classe/reaction, false = noir/gris
            showPowerBar = true, -- Nouvelle option: afficher/cacher la barre de ressource
            truncateName = true, -- Nouvelle option: tronquer le nom
            truncateNameLength = 8, -- Nouvelle option: longueur max du nom
        },
        targetoftarget = {
            enabled = true,
            width = 90,
            height = 15,
            scale = 1.0,
            minimalist = false,
            position = nil,
            useClassColor = true, -- Nouvelle option
            truncateName = true, -- Nouvelle option: tronquer le nom
            truncateNameLength = 8, -- Nouvelle option: longueur max du nom
        },
    },
    auras = {
        playerDebuffs = {
            enabled = true,
            position = nil,
            scale = 1.0,
            count = 8,                    -- Nombre de debuffs affichés (2-8)
            growDirection = "LEFT",       -- LEFT, RIGHT, UP, DOWN
        },
        targetDebuffs = {
            enabled = true,
            position = nil,
            scale = 1.0,
            countPerRow = 8,              -- Nombre de debuffs par ligne (2-8)
            rows = 1,                     -- Nombre de lignes (1-2)
            growDirection = "RIGHT",      -- LEFT, RIGHT (direction horizontale)
            rowDirection = "DOWN",        -- UP, DOWN (direction des lignes)
            onlyMine = false,             -- Afficher uniquement mes debuffs
        },
    },
    tooltip = {
        enabled = true,
        colorBorder = true,               -- Bordure colorée selon la cible
        colorName = true,                 -- Nom coloré selon la cible
        improveBackdrop = true,           -- Améliorer l'apparence du tooltip
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
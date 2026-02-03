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
    skyRide = {
        enabled = false, -- Désactivé par défaut
        width = 340,
        height = 20,
        comboHeight = 5,
        font = STANDARD_TEXT_FONT,
        fontSize = 12,
        fontOutline = "OUTLINE",
        barColor = {r = 1, g = 1, b = 0},
        position = {
            point = "BOTTOM",
            relativePoint = "CENTER",
            x = 0,
            y = -180,
        },
    },
    autoAcceptInvite = {
        enabled = false, -- false par défaut pour sécurité
        acceptFriends = true,
        acceptGuild = true,
        showMessages = true,
    },
    autoSummon = {
        enabled = false, -- false par défaut pour sécurité
        acceptFriends = true,
        acceptGuild = true,
        showMessages = true,
        delaySec = 1,
    },
    hideCastBar = {
        enabled = false, -- false par défaut, activer via config
    },
    MythicKeys = {
        enabled = true,
        miniFrame = true,
        autoRefresh = true,
        sendToChat = true,
    },
    autoFillDelete = {
        enabled = true,      -- Activé par défaut (juste un helper)
        focusButton = true,  -- Focus sur OK après remplissage
        showMessages = false, -- Pas de messages spam
    },
    combatInfo = {
        enabled = true,
        alignedBuff = false,
        combatAlphaChange = true,
        changeBuffBar = true,
        buffBarClassColor = true,
        showHotKey = false,
        hideBarName = true,
        alertAssistedSpell = false,
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
-- =====================================
-- Database.lua — Defaults & DB Management
-- =====================================

local ADDON_FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_TEXTURE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"

-- =====================================
-- DEFAULTS
-- =====================================

TomoMod_Defaults = {
    -- =====================
    -- QOL MODULES (preserved from v1.x)
    -- =====================
    minimap = {
        enabled = true,
        scale = 1.0,
        borderColor = "class",
        size = 200,
    },
    infoPanel = {
        enabled = true,
        scale = 1.0,
        borderColor = "black",
        showDurability = true,
        showTime = true,
        use24Hour = true,
        displayOrder = { "Gear", "Time", "Fps" },
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
        viewedCinematics = {},
    },
    autoQuest = {
        autoAccept = false,
        autoTurnIn = false,
        autoGossip = false,
    },
    skyRide = {
        enabled = false,
        width = 340,
        height = 20,
        comboHeight = 5,
        font = STANDARD_TEXT_FONT,
        fontSize = 12,
        fontOutline = "OUTLINE",
        barColor = { r = 1, g = 1, b = 0 },
        position = {
            point = "BOTTOM",
            relativePoint = "CENTER",
            x = 0,
            y = -180,
        },
    },
    autoAcceptInvite = {
        enabled = false,
        acceptFriends = true,
        acceptGuild = true,
        showMessages = true,
    },
    autoSummon = {
        enabled = false,
        acceptFriends = true,
        acceptGuild = true,
        showMessages = true,
        delaySec = 1,
    },
    hideCastBar = {
        enabled = false,
    },
    MythicKeys = {
        enabled = true,
        miniFrame = true,
        autoRefresh = true,
        sendToChat = true,
    },
    autoFillDelete = {
        enabled = true,
        focusButton = true,
        showMessages = false,
    },
    cooldownManager = {
        enabled = true,
        showHotKey = false,
        combatAlpha = true,
        alphaInCombat = 1.0,
        alphaWithTarget = 0.8,
        alphaOutOfCombat = 0.5,
    },

    -- =====================
    -- RESOURCE BARS
    -- =====================
    resourceBars = {
        enabled = true,
        visibilityMode = "always",   -- always, combat, target, hidden
        combatAlpha = 1.0,
        oocAlpha = 0.6,
        width = 260,
        primaryHeight = 16,
        secondaryHeight = 12,
        scale = 1.0,
        showText = true,
        textAlignment = "CENTER",    -- LEFT, CENTER, RIGHT
        font = ADDON_FONT,
        fontSize = 11,
        syncWidthWithCooldowns = false,
        position = {
            point = "BOTTOM",
            relativePoint = "CENTER",
            x = 0,
            y = -230,
        },
        colors = {
            mana            = { r = 0.00, g = 0.00, b = 1.00 },
            rage            = { r = 1.00, g = 0.00, b = 0.00 },
            energy          = { r = 1.00, g = 1.00, b = 0.00 },
            focus           = { r = 0.72, g = 0.55, b = 0.05 },
            runicPower      = { r = 0.00, g = 0.82, b = 1.00 },
            runes           = { r = 0.50, g = 0.50, b = 0.50 },
            runesReady      = { r = 0.75, g = 0.22, b = 0.22 },
            soulShards      = { r = 0.58, g = 0.51, b = 0.79 },
            astralPower     = { r = 0.30, g = 0.52, b = 0.90 },
            holyPower       = { r = 0.95, g = 0.90, b = 0.60 },
            maelstrom       = { r = 0.00, g = 0.50, b = 1.00 },
            chi             = { r = 0.71, g = 1.00, b = 0.92 },
            insanity        = { r = 0.40, g = 0.00, b = 0.80 },
            fury            = { r = 0.78, g = 0.26, b = 0.99 },
            comboPoints     = { r = 1.00, g = 0.96, b = 0.41 },
            arcaneCharges   = { r = 0.10, g = 0.10, b = 0.98 },
            essence         = { r = 0.00, g = 0.80, b = 0.60 },
            stagger         = { r = 0.52, g = 1.00, b = 0.52 },
            soulFragments   = { r = 0.80, g = 0.20, b = 1.00 },
            tipOfTheSpear   = { r = 0.20, g = 0.80, b = 0.20 },
            maelstromWeapon = { r = 0.00, g = 0.50, b = 1.00 },
        },
    },

    -- =====================
    -- UNIT FRAMES
    -- =====================
    unitFrames = {
        enabled = true,
        hideBlizzardFrames = true,
        texture = ADDON_TEXTURE,
        font = ADDON_FONT,
        fontSize = 12,
        fontOutline = "OUTLINE",
        borderSize = 1,
        borderColor = { r = 0, g = 0, b = 0, a = 1 },

        -- Per-unit settings
        player = {
            enabled = true,
            width = 260,
            height = 52,
            healthHeight = 38,
            powerHeight = 8,
            useClassColor = true,
            useFactionColor = false,
            showName = true,
            showLevel = false,
            showHealthText = true,
            healthTextFormat = "current_percent", -- current, percent, current_percent, current_max, deficit
            showPowerText = false,
            showAbsorb = true,
            showThreat = false,
            showLeaderIcon = true,
            leaderIconOffset = { x = -2, y = 0 },
            castbar = {
                enabled = true,
                width = 260,
                height = 20,
                showIcon = true,
                showTimer = true,
                color = { r = 1.0, g = 0.7, b = 0.0 },
                position = { point = "TOP", relativePoint = "BOTTOM", x = 0, y = -6 },
            },
            auras = {
                enabled = true,
                type = "HARMFUL",
                maxAuras = 8,
                size = 30,
                spacing = 3,
                growDirection = "LEFT",
                showDuration = true,
                showOnlyMine = false,
                position = { point = "BOTTOMRIGHT", relativePoint = "TOPRIGHT", x = 0, y = 6 },
            },
            elementOffsets = {
                name = { x = 6, y = 0 },
                level = { x = -6, y = 0 },
                healthText = { x = 0, y = 0 },
                power = { x = 0, y = 0 },
                castbar = { x = 0, y = 0 },
                auras = { x = 0, y = 0 },
            },
            position = { point = "BOTTOM", relativePoint = "CENTER", x = -280, y = -190 },
        },

        target = {
            enabled = true,
            width = 260,
            height = 52,
            healthHeight = 38,
            powerHeight = 8,
            useClassColor = true,
            useFactionColor = true,
            showName = true,
            showLevel = true,
            showHealthText = true,
            healthTextFormat = "current_percent",
            showPowerText = false,
            showAbsorb = false,
            showThreat = true,
            showRaidIcon = true,
            showLeaderIcon = true,
            leaderIconOffset = { x = -2, y = 0 },
            castbar = {
                enabled = true,
                width = 260,
                height = 20,
                showIcon = true,
                showTimer = true,
                color = { r = 1.0, g = 0.7, b = 0.0 },
                position = { point = "TOP", relativePoint = "BOTTOM", x = 0, y = -6 },
            },
            auras = {
                enabled = true,
                type = "HARMFUL",
                maxAuras = 8,
                size = 30,
                spacing = 3,
                growDirection = "RIGHT",
                showDuration = true,
                showOnlyMine = false,
                position = { point = "BOTTOMLEFT", relativePoint = "TOPLEFT", x = 0, y = 6 },
            },
            elementOffsets = {
                name = { x = 6, y = 0 },
                level = { x = -6, y = 0 },
                healthText = { x = 0, y = 0 },
                power = { x = 0, y = 0 },
                castbar = { x = 0, y = 0 },
                auras = { x = 0, y = 0 },
            },
            position = { point = "BOTTOM", relativePoint = "CENTER", x = 280, y = -190 },
        },

        targettarget = {
            enabled = true,
            width = 130,
            height = 32,
            healthHeight = 26,
            powerHeight = 0,
            useClassColor = true,
            useFactionColor = true,
            showName = true,
            showLevel = false,
            showHealthText = false,
            healthTextFormat = "percent",
            showPowerText = false,
            showAbsorb = false,
            showThreat = false,
            position = { point = "TOPLEFT", relativePoint = "TOPRIGHT", x = 8, y = 0 },
            anchorTo = "target",
        },

        pet = {
            enabled = true,
            width = 130,
            height = 32,
            healthHeight = 26,
            powerHeight = 0,
            useClassColor = false,
            useFactionColor = false,
            showName = true,
            showLevel = false,
            showHealthText = false,
            healthTextFormat = "percent",
            showPowerText = false,
            showAbsorb = false,
            showThreat = false,
            position = { point = "TOPRIGHT", relativePoint = "TOPLEFT", x = -8, y = 0 },
            anchorTo = "player",
        },

        focus = {
            enabled = true,
            width = 200,
            height = 44,
            healthHeight = 32,
            powerHeight = 6,
            useClassColor = true,
            useFactionColor = true,
            showName = true,
            showLevel = true,
            showHealthText = true,
            healthTextFormat = "percent",
            showPowerText = false,
            showAbsorb = false,
            showThreat = false,
            castbar = {
                enabled = true,
                width = 200,
                height = 16,
                showIcon = true,
                showTimer = true,
                color = { r = 1.0, g = 0.7, b = 0.0 },
                position = { point = "TOP", relativePoint = "BOTTOM", x = 0, y = -4 },
            },
            auras = {
                enabled = true,
                type = "HARMFUL",
                maxAuras = 6,
                size = 26,
                spacing = 3,
                growDirection = "RIGHT",
                showDuration = true,
                showOnlyMine = true,
                position = { point = "BOTTOMLEFT", relativePoint = "TOPLEFT", x = 0, y = 6 },
            },
            position = { point = "CENTER", relativePoint = "CENTER", x = -350, y = 150 },
        },
    },

    -- =====================
    -- NAMEPLATES
    -- =====================
    nameplates = {
        enabled = false,
        width = 150,
        height = 14,
        texture = ADDON_TEXTURE,
        font = ADDON_FONT,
        fontSize = 9,
        nameFontSize = 10,
        fontOutline = "OUTLINE",
        showName = true,
        showLevel = true,
        showHealthText = true,
        healthTextFormat = "percent",
        showClassification = true,
        showThreat = true,
        showCastbar = true,
        castbarHeight = 10,
        useClassColors = true,
        showAuras = true,
        auraSize = 20,
        maxAuras = 5,
        showOnlyMyAuras = true,
        friendlyPlates = false,
        tankMode = false,
        selectedAlpha = 1.0,
        unselectedAlpha = 0.8,
        overlapV = 1.6,          -- Vertical overlap (higher = plates closer together, 0.5-3.0)
        topInset = 0.065,        -- How high plates can go on screen (0.01=top, 0.5=middle)
        colors = {
            hostile  = { r = 0.78, g = 0.04, b = 0.04 },
            neutral  = { r = 0.98, g = 0.82, b = 0.11 },
            friendly = { r = 0.11, g = 0.82, b = 0.11 },
            tapped   = { r = 0.50, g = 0.50, b = 0.50 },
            -- Classification colors (hostile mobs)
            boss     = { r = 0.85, g = 0.10, b = 0.10 },  -- RED
            elite    = { r = 0.60, g = 0.20, b = 0.80 },  -- PURPLE
            rare     = { r = 0.00, g = 0.80, b = 0.80 },  -- CYAN
            normal   = { r = 0.60, g = 0.40, b = 0.20 },  -- BROWN
            trivial  = { r = 0.50, g = 0.50, b = 0.50 },  -- GREY
        },
        useClassificationColors = true,
        tankColors = {
            noThreat  = { r = 0.78, g = 0.04, b = 0.04 },
            lowThreat = { r = 0.98, g = 0.82, b = 0.11 },
            hasThreat = { r = 0.11, g = 0.82, b = 0.11 },
        },
    },
}

-- =====================================
-- DB FUNCTIONS
-- =====================================

function TomoMod_InitDatabase()
    if not TomoModDB then
        TomoModDB = {}
    end
    TomoMod_MergeTables(TomoModDB, TomoMod_Defaults)
end

function TomoMod_ResetDatabase()
    TomoModDB = CopyTable(TomoMod_Defaults)
    print("|cff0cd29fTomoMod|r Base de données réinitialisée")
end

function TomoMod_ResetModule(moduleName)
    if TomoMod_Defaults[moduleName] then
        TomoModDB[moduleName] = CopyTable(TomoMod_Defaults[moduleName])
        print("|cff0cd29fTomoMod|r Module '" .. moduleName .. "' réinitialisé")
    end
end

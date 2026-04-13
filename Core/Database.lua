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
        showTime = true,
        showCoords = true,
        showDurability = true,
        use24Hour = true,
        useServerTime = true,
    },
    cursorRing = {
        enabled = false,
        scale = 1.0,
        useClassColor = false,
        anchorTooltip = false,
    },
    installer = {
        completed = false,
        step      = 1,
    },
    cinematicSkip = {
        enabled = false,
        viewedCinematics = {},
    },
    frameAnchors = {
        enabled = true,
        alertFrame = {
            position = nil, -- {point, relPoint, x, y}
        },
        lootFrame = {
            position = nil,
        },
    },
    autoQuest = {
        autoAccept = false,
        autoTurnIn = false,
        autoGossip = false,
    },
    objectiveTracker = {
        enabled = true,
        bgAlpha = 0.65,
        showBorder = true,
        hideWhenEmpty = false,
        headerFontSize = 13,
        categoryFontSize = 11,
        questFontSize = 12,
        objectiveFontSize = 11,
        maxQuestsShown = 0,
    },
    skyRide = {
        enabled = true,
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
    levelingBar = {
        enabled = false,
        width = 500,
        height = 28,
        position = nil,
    },
    cvarOptimizer = {
        backup           = nil,
        individualBackup = nil,
    },
    reputationBar = {
        enabled         = true,
        width           = 350,
        height          = 22,
        hideBlizzRepBar = true,
        position        = nil,
    },
    autoAcceptInvite = {
        enabled = false,
        acceptFriends = true,
        acceptGuild = true,
        showMessages = true,
    },
    addonDetect = {
        enabled = true,
    },
    autoSkipRole = {
        enabled = false,
        showMessages = true,
    },
    tooltipIDs = {
        enabled = false,
        showSpellID = true,
        showItemID = true,
        showNPCID = true,
        showQuestID = true,
        showMountID = true,
        showCurrencyID = true,
        showAchievementID = true,
    },
    actionBarSkin = {
        enabled = false,
        skinStyle = "classic",
        useClassColor = true,
        shiftReveal = false,
        barOpacity = {
            ActionButton           = 100,
            MultiBarBottomLeft     = 100,
            MultiBarBottomRight    = 100,
            MultiBarRight          = 100,
            MultiBarLeft           = 100,
            MultiBar5              = 100,
            MultiBar6              = 100,
            MultiBar7              = 100,
            PetActionButton        = 100,
            StanceButton           = 100,
        },
        combatShow = {
            ActionButton           = false,
            MultiBarBottomLeft     = false,
            MultiBarBottomRight    = false,
            MultiBarRight          = false,
            MultiBarLeft           = false,
            MultiBar5              = false,
            MultiBar6              = false,
            MultiBar7              = false,
            PetActionButton        = false,
            StanceButton           = false,
        },
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
    combatText = {
        enabled = false,
        offsetX = 0,
        offsetY = 0,
    },
    bagMicroMenu = {
        bagBarMode = "show",
        microMenuMode = "show",
    },
    MythicKeys = {
        enabled = true,
        miniFrame = true,
        autoRefresh = true,
        sendToChat = true,
    },
    MythicTracker = {
        enabled      = true,
        position     = { anchor = "TOPRIGHT", relTo = "TOPRIGHT", x = -20, y = -260 },
        scale        = 1.0,
        alpha        = 0.95,
        locked       = true,
        hideBlizzard = true,
        showTimer    = true,
        showForces   = true,
        showBosses   = true,
    },
    TomoScore = {
        enabled       = true,
        position      = { anchor = "CENTER", relTo = "CENTER", x = 0, y = 100 },
        scale         = 1.0,
        alpha         = 0.95,
        autoShowMPlus = true,
        lastRun       = nil,
    },
    autoFillDelete = {
        enabled = true,
        focusButton = true,
        showMessages = false,
    },
    characterSkin = {
        enabled = true,
        skinCharacter = true,
        skinInspect = true,
        showItemInfo = true,
        showGems = true,
        midnightEnchants = false,
        scale = 1.0,
    },
    chatFrameSkin = {
        enabled = true,
        skinStyle = "tui",          -- "tui" (current sidebar+window), "classic" (old image-based), "glass", "minimal"
        bgAlpha = 0.70,
        fontSize = 13,
        fade = true,
        shortChannelNames = true,
        showTimestamp = true,
        timestampFormat = "%H:%M",
        findURL = true,
        emoji = true,
        classColorMentions = true,
        copyChatLines = false,
        chatHistory = true,
        keywords = "%MYNAME%",
        showHistory = {
            WHISPER = true,
            GUILD = true,
            PARTY = true,
            RAID = true,
            INSTANCE = true,
            CHANNEL = true,
            SAY = false,
            YELL = false,
            OFFICER = true,
            EMOTE = false,
        },
        history = {},
        position = { anchor = "BOTTOMLEFT", relTo = "BOTTOMLEFT", x = 2, y = 2 },
    },
    chatFrameSkinV2 = {
        enabled       = false,
        width         = 550,
        height        = 320,
        scale         = 100,
        opacity       = 88,
        fontSize      = 13,
        defaultTab    = "general",
        collapsed     = false,
        showTimestamp = true,
        history       = {},
        position      = { anchor = "BOTTOMLEFT", relTo = "BOTTOMLEFT", x = 20, y = 24 },
    },
    bagSkin = {
        enabled = false,
        slotSize = 40,
        slotSpacingX = 5,
        slotSpacingY = 5,
        width = 480,
        scale = 100,
        opacity = 92,
        showQualityBorders = true,
        showCooldowns = true,
        showQuantityBadges = true,
        showItemLevel = false,
        showJunkIcon = false,
        showSearchBar = true,
        showGold = true,
        showCurrencies = false,
        layoutMode = "combined",     -- "combined", "categories", "separateBags"
        sortMode = "quality",
        reverseBagOrder = false,
        stackMerge = false,
        showEmptySlots = true,
        showRecentItems = true,
        showBagBar = true,
        collapsedSections = {},
        position = { anchor = "BOTTOMRIGHT", relTo = "BOTTOMRIGHT", x = -20, y = 60 },
    },
    buffSkin = {
        enabled = false,
        skinBuffs = true,
        skinDebuffs = true,
        hideBuffFrame = false,
        hideDebuffFrame = false,
        colorByType = true,          -- border colorée par type de dispel (Magic/Poison/Curse/Disease)
        tealBorder = true,           -- border teal sur les buffs (accent TomoMod)
        desaturateDebuffs = false,   -- désaturer les icônes de debuff
        fontSize = 11,
    },
    gameMenuSkin = {
        enabled = true,
    },
    tooltipSkin = {
        enabled = true,
        bgAlpha = 0.92,
        borderAlpha = 0.8,
        fontSize = 12,
        hideHealthBar = false,
        useClassColorNames = true,
        hidePlayerServer = false,
        hidePlayerTitle = false,
        useGuildNameColor = true,
        guildNameColor = { r = 0.047, g = 0.824, b = 0.624 },
    },
    mailSkin = {
        enabled = true,
    },

    worldQuestTab = {
        enabled = false,
        autoShow = true,
        maxQuestsShown = 50,
        minTimeMinutes = 0,
        filterGold = true,
        filterGear = true,
        filterAP = true,
        filterRep = true,
        filterPet = true,
        filterCurrency = true,
        filterAnima = true,
        filterOther = true,
    },

    loots = {
        enabled     = true,
        position    = nil,  -- { point, relPoint, x, y } — saved on drag
        filterClass = nil,  -- nil = player class, 0 = "Tous", classID = specific class
        filterDiff  = 15,   -- 14=Normal 15=Héroïque 16=Mythique 17=LFR
        favorites   = {},
    },

    waypoint = {
        enabled      = true,
        beaconScale  = 1.0,   -- global scale multiplier on the in-world beacon
        showBeam     = true,  -- show the vertical teal beam below the beacon
        showETA      = true,  -- append arrival-time estimate to distance text
        sessionName  = nil,   -- restored label after /reload
        zoneOnly     = true,  -- hide waypoint when not in the same zone
        beaconSize   = 32,    -- icon diameter (px)
        shape        = "ring", -- "ring" or "arrow"
        color        = { r = 0.047, g = 0.824, b = 0.624 }, -- accent teal
    },

    professionHelper = {
        enabled = true,
        filterGreen = true,
        filterBlue = true,
        filterEpic = false,
    },

    classReminder = {
        enabled = true,
        scale = 1.0,
        textColor = { r = 1, g = 1, b = 1 },
        offsetX = 0,
        offsetY = 0,
    },

    afkDisplay = {
        enabled = true,
        rotateCamera = true,
        playerModel = true,
        modelScale = 1.0,
    },

    lustSound = {
        enabled = true,
        sound = "TALUANI",
        channel = "Master",
        forceSound = true,
        showChat = false,
        debug = false,
    },

    cooldownManager = {
        enabled = true,
        showHotKey = false,
        combatAlpha = true,
        alphaInCombat = 1.0,
        alphaWithTarget = 0.8,
        alphaOutOfCombat = 0.5,
        -- V2: overlay & swipe
        useCustomOverlay = false,
        overlayR = 1.0,
        overlayG = 1.0,
        overlayB = 1.0,
        customSwipeEnabled = false,
        swipeR = 1.0,
        swipeG = 0.95,
        swipeB = 0.57,
        swipeA = 0.55,
        -- V2: utility dimming
        dimUtility = false,
        dimOpacity = 0.35,
        -- V3: separate CD swipe color
        customCDSwipeEnabled = false,
        cdSwipeR = 0.0,
        cdSwipeG = 0.0,
        cdSwipeB = 0.0,
        cdSwipeA = 0.7,
        -- V3: GCD hiding
        hideGCD = false,
        -- V3: desaturation on cooldown
        desaturateOnCD = false,
        -- V3: buff icon alignment (CENTER, START, END)
        buffAlignment = "CENTER",
        -- V3: visibility rules (advanced)
        visibilityRules = {
            hideWhenMounted = false,
            hideInVehicles = false,
            hideOutOfCombat = false,
            showInCombat = false,
            showInInstance = false,
            showWithEnemyTarget = false,
        },
        -- V3.1: sound alerts
        soundAlertEnabled = false,
        soundAlertFile = "Interface\\AddOns\\TomoMod\\Assets\\Sounds\\Golden_Lust.ogg",
        -- V3.1: pandemic detection (buff refresh window)
        pandemicEnabled = false,
        pandemicThreshold = 0.3,
        -- V3.1: range check coloring
        rangeCheckEnabled = false,
    },

    -- =====================
    -- RESOURCE BARS
    -- =====================
    resourceBars = {
        enabled = true,
        displayMode = "icons",       -- "icons" (GW2 textures) or "bars" (flat colors)
        visibilityMode = "always",   -- always, combat, target, hidden
        combatAlpha = 1.0,
        oocAlpha = 0.6,
        width = 260,
        primaryHeight = 16,          -- class power display height
        secondaryHeight = 12,        -- druid mana bar height
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
            comboPoints     = { r = 1.00, g = 0.96, b = 0.41 },
            runes           = { r = 0.50, g = 0.50, b = 0.50 },
            runesReady      = { r = 0.75, g = 0.22, b = 0.22 },
            soulShards      = { r = 0.58, g = 0.51, b = 0.79 },
            holyPower       = { r = 0.95, g = 0.90, b = 0.60 },
            chi             = { r = 0.71, g = 1.00, b = 0.92 },
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
        fontFamily = ADDON_FONT,
        fontSize = 12,
        fontOutline = "OUTLINE",
        borderSize = 1,
        borderColor = { r = 0, g = 0, b = 0, a = 1 },
        castbarColor = { r = 0.80, g = 0.10, b = 0.10 },
        castbarNIColor = { r = 0.50, g = 0.50, b = 0.50 },
        castbarInterruptColor = { r = 0.10, g = 0.80, b = 0.10 },

        -- Per-unit settings
        player = {
            enabled = true,
            width = 260,
            height = 58,
            healthHeight = 38,
            powerHeight = 2,
            infoBarHeight = 18,
            useClassColor = true,
            useFactionColor = false,
            showName = true,
            showLevel = false,
            showHealthText = true,
            healthTextFormat = "percent", -- current, percent, current_percent, current_max, deficit
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
                showLatency = true,
                color = { r = 1.0, g = 0.7, b = 0.0 },
                position = { point = "BOTTOM", relativePoint = "CENTER", x = -280, y = -220 },
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
                auras = { x = 0, y = 0 },
            },
            position = { point = "BOTTOM", relativePoint = "CENTER", x = -280, y = -190 },
        },

        target = {
            enabled = true,
            width = 260,
            height = 58,
            healthHeight = 38,
            powerHeight = 2,
            infoBarHeight = 18,
            useClassColor = true,
            useFactionColor = true,
            useNameplateColors = true,
            showName = true,
            showLevel = true,
            nameTruncate = true,
            nameTruncateLength = 20,
            showHealthText = true,
            healthTextFormat = "percent",
            showPowerText = false,
            showAbsorb = false,
            showThreat = true,
            threatText = {
                enabled  = false,
                offsetX  = 0,
                offsetY  = 0,
                fontSize = 13,
            },
            showRaidIcon = true,
            raidIconOffset = { x = 0, y = 2 },
            showQuestIcon = true,
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
            enemyBuffs = {
                enabled = true,
                maxAuras = 4,
                size = 24,
                spacing = 2,
                growDirection = "UP",
                showDuration = true,
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
            nameTruncate = true,
            nameTruncateLength = 12,
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
            useNameplateColors = true,
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
            enemyBuffs = {
                enabled = true,
                maxAuras = 3,
                size = 22,
                spacing = 2,
                growDirection = "UP",
                showDuration = true,
                position = { point = "BOTTOMRIGHT", relativePoint = "TOPRIGHT", x = 0, y = 6 },
            },
            position = { point = "CENTER", relativePoint = "CENTER", x = -350, y = 150 },
        },

        -- Boss Frames (boss1–boss5)
        bossFrames = {
            enabled = true,
            width = 200,
            height = 28,
            spacing = 4,
            position = {
                point = "RIGHT",
                relativePoint = "RIGHT",
                x = -80,
                y = 200,
            },
        },
    },

    -- =====================
    -- NAMEPLATES
    -- =====================
    nameplates = {
        enabled = true,
        width = 156,
        height = 17,
        texture = ADDON_TEXTURE,
        font = ADDON_FONT,
        fontSize = 10,
        nameFontSize = 11,
        fontOutline = "OUTLINE",
        showName = true,
        showLevel = false,
        showHealthText = true,
        healthTextFormat = "current_percent",
        showClassification = true,
        showThreat = true,
        showCastbar = true,
        castbarHeight = 14,
        castbarColor = { r = 0.85, g = 0.15, b = 0.15 },           -- RED (interruptible)
        castbarUninterruptible = { r = 0.45, g = 0.45, b = 0.45 }, -- GREY (non-interruptible)
        useClassColors = true,
        showAbsorb = true,
        showAuras = true,
        auraSize = 24,
        maxAuras = 5,
        showOnlyMyAuras = true,
        showEnemyBuffs = true,
        enemyBuffSize = 22,
        maxEnemyBuffs = 4,
        enemyBuffYOffset = 4,
        friendlyPlates = false,
        friendlyNameOnly = true,
        friendlyRoleIcons = true,
        roleIconSize = 32,
        roleShowTank = true,
        roleShowHealer = true,
        roleShowDps = true,
        tankMode = false,
        selectedAlpha = 1.0,
        unselectedAlpha = 0.8,
        overlapV = 1.05,         -- Vertical overlap (higher = plates closer together, 0.5-3.0)
        topInset = 0.065,        -- How high plates can go on screen (0.01=top, 0.5=middle)
        colors = {
            hostile       = { r = 0.78, g = 0.04, b = 0.04 },
            neutral       = { r = 0.81, g = 0.72, b = 0.19 },
            friendly      = { r = 0.11, g = 0.82, b = 0.11 },
            tapped        = { r = 0.50, g = 0.50, b = 0.50 },
            focus         = { r = 0.05, g = 0.82, b = 0.62 },
            -- NPC type colors (Ellesmere-style)
            caster        = { r = 0.23, g = 0.51, b = 0.97 },  -- BLUE (caster mobs)
            miniboss      = { r = 0.52, g = 0.24, b = 0.98 },  -- PURPLE (elite + higher level)
            enemyInCombat = { r = 0.80, g = 0.14, b = 0.14 },  -- RED (default enemy in combat)
            -- Classification colors (kept for legacy)
            boss          = { r = 0.85, g = 0.10, b = 0.10 },
            elite         = { r = 0.52, g = 0.24, b = 0.98 },
            rare          = { r = 0.00, g = 0.80, b = 0.80 },
            normal        = { r = 0.80, g = 0.14, b = 0.14 },
            trivial       = { r = 0.50, g = 0.50, b = 0.50 },
        },
        useClassificationColors = true,
        raidIconAnchor = "TOPRIGHT",
        raidIconX = 2,
        raidIconY = 2,
        raidIconSize = 24,
        tankColors = {
            noThreat      = { r = 1.00, g = 0.22, b = 0.17 },
            lowThreat     = { r = 0.81, g = 0.72, b = 0.19 },
            hasThreat     = { r = 0.05, g = 0.82, b = 0.62 },
            dpsHasAggro   = { r = 1.00, g = 0.50, b = 0.00 },  -- ORANGE (DPS has aggro)
            dpsNearAggro  = { r = 0.81, g = 0.72, b = 0.19 },  -- YELLOW (DPS near aggro)
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
    print("|cff0cd29fTomoMod|r " .. TomoMod_L["msg_db_reset"])
end

function TomoMod_ResetModule(moduleName)
    if TomoMod_Defaults[moduleName] then
        TomoModDB[moduleName] = CopyTable(TomoMod_Defaults[moduleName])
        print("|cff0cd29fTomoMod|r " .. string.format(TomoMod_L["msg_module_reset"], moduleName))
    end
end

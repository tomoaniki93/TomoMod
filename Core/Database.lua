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
        position = { anchor = "TOPRIGHT", relTo = "TOPRIGHT", x = -20, y = -20 },
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
    lastSeenVersion = "",
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
    },
    actionBars = {
        enabled = true,
        shiftReveal = false,
        bars = {},       -- per-bar overrides (lazy-filled by ActionBars.lua)
        positions = {},  -- per-bar saved positions
    },
    diagnostics = {
        enabled = false,
        captureAll = false,
        suppressPopups = true,
        autoOpenOnError = false,
        sessionCount = 0,
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
    merchantTools = {
        alreadyKnown = {
            enabled = true,
            mode    = "MONOCHROME",  -- "MONOCHROME" ou "COLOR"
            color   = { r = 0.047, g = 0.824, b = 0.624 },
        },
        extendPages = {
            enabled       = false,
            numberOfPages = 2,
        },
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
    -- Chat Frame UI — multi-position containers, button bar, sidebar icons,
    -- layout switching, raid frame manager (adapted from MayronUI).
    chatFrameUI = {
        enabled = false,
        swapInCombat = false,
        raidFrameManager = true,
        chatFrames = {
            TOPLEFT = {
                enabled = true,
                xOffset = 2, yOffset = -2,
                tabBar  = { show = true, yOffset = -12 },
                window  = { yOffset = -37 },
                buttons = {
                    { "Character", "Spell Book", "Talents" },
                    { key = "C", "Reputation", "LFD", "Quest Log" },
                    { key = "S", "Achievements", "Collections Journal", "Encounter Journal" },
                },
            },
            TOPRIGHT = {
                enabled = false,
                xOffset = -2, yOffset = -2,
                tabBar  = { show = true, yOffset = -12 },
                window  = { yOffset = -37 },
                buttons = {
                    { "Character", "Spell Book", "Talents" },
                    { key = "C", "Reputation", "LFD", "Quest Log" },
                    { key = "S", "Achievements", "Collections Journal", "Encounter Journal" },
                },
            },
            BOTTOMLEFT = {
                enabled = false,
                xOffset = 2, yOffset = 2,
                tabBar  = { show = true, yOffset = -43 },
                window  = { yOffset = 12 },
                buttons = {
                    { "Character", "Spell Book", "Talents" },
                    { key = "C", "Reputation", "LFD", "Quest Log" },
                    { key = "S", "Achievements", "Collections Journal", "Encounter Journal" },
                },
            },
            BOTTOMRIGHT = {
                enabled = false,
                xOffset = -2, yOffset = 2,
                tabBar  = { show = true, yOffset = -43 },
                window  = { yOffset = 12 },
                buttons = {
                    { "Character", "Spell Book", "Talents" },
                    { key = "C", "Reputation", "LFD", "Quest Log" },
                    { key = "S", "Achievements", "Collections Journal", "Encounter Journal" },
                },
            },
        },
        iconsAnchor = "TOPLEFT",
        icons = {
            { type = "voiceChat" },
            { type = "professions" },
            { type = "shortcuts" },
            { type = "copyChat" },
            { type = "emotes" },
            { type = "playerStatus" },
        },
        brightness = 0.7,
        editBox = {
            position = "BOTTOM",
            yOffset = -8,
            height = 27,
            inset = 0,
            backdropColor = { r = 0, g = 0, b = 0, a = 0.6 },
        },
        highlighted = {},
        layouts = {},
        currentLayout = nil,
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
        -- Overlay
        useCustomOverlay = false,
        overlayR = 1.0,
        overlayG = 1.0,
        overlayB = 1.0,
        -- Active aura swipe color
        customSwipeEnabled = false,
        swipeR = 1.0,
        swipeG = 0.95,
        swipeB = 0.57,
        swipeA = 0.55,
        -- Cooldown swipe color
        customCDSwipeEnabled = false,
        cdSwipeR = 0.0,
        cdSwipeG = 0.0,
        cdSwipeB = 0.0,
        cdSwipeA = 0.7,
        -- Utility dimming
        dimUtility = false,
        dimOpacity = 0.35,
        -- GCD hiding
        hideGCD = false,
        -- Desaturation on cooldown
        desaturateOnCD = false,
        -- Visibility rules
        visibilityRules = {
            hideWhenMounted = false,
            hideInVehicles = false,
            hideOutOfCombat = false,
            showInCombat = false,
            showInInstance = false,
            showWithEnemyTarget = false,
        },
        -- Sound alerts
        soundAlertEnabled = false,
        soundAlertFile = "Interface\\AddOns\\TomoMod\\Assets\\Sounds\\Golden_Lust.ogg",
        -- Pandemic detection (buff refresh window)
        pandemicEnabled = false,
        pandemicThreshold = 0.3,
        -- Range check coloring
        rangeCheckEnabled = false,
        -- Buff bar layout
        buffBarDirection = "HORIZONTAL",
        buffBarWidth = 120,
        buffBarSpacing = 2,
        -- Buff icon direction
        buffIconDirection = "CENTERED",
        -- Proc glow
        procGlow = {
            enabled = true,
            glowType = "Pixel Glow",
            color = { 0.95, 0.95, 0.32, 1 },
            pixelLines = 5,
            pixelFrequency = 0.25,
            pixelLength = 8,
            pixelThickness = 1,
            autoParticles = 8,
            autoFrequency = 0.25,
            autoScale = 1.0,
            buttonFrequency = 0.25,
        },
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
        primaryPowerCentered = false, -- show primary power (mana/energy/rage) centered on screen
        primaryPowerBarHeight = 14,   -- height of centered primary power bar
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
    -- CASTBARS (standalone)
    -- =====================
    castbars = {
        enabled = true,
        hideBlizzardCastbar = true,

        -- Global visual
        barTexture = "blizzard",
        barTextureLSM = "",
        font = ADDON_FONT,
        fontLSM = "",
        fontSize = 12,
        backgroundMode = "black",
        customBackgroundPath = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Castbars\\background",
        useCustomBorder = false,
        customBorderPath = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Castbars\\border",

        -- Spark
        showSpark = true,
        sparkStyle = "Comet",
        customSparkPath = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Castbars\\cast_spark",
        sparkColor    = { r = 1.0, g = 1.0, b = 1.0 },
        sparkGlowColor = { r = 1.0, g = 0.9, b = 0.5 },
        sparkTailColor = { r = 1.0, g = 0.8, b = 0.3 },
        sparkGlowAlpha = 0.7,
        sparkTailAlpha = 0.6,

        -- Colors
        castbarColor       = { r = 1.0, g = 0.7, b = 0.0 },
        castbarNIColor     = { r = 0.5, g = 0.5, b = 0.5 },
        castbarInterruptColor = { r = 0.1, g = 0.8, b = 0.1 },
        useClassColor = true,

        -- Timer
        timerFormat = "remaining",
        spellNameMaxLen = 0,

        -- Transitions
        showTransitions = true,
        showChannelTicks = true,

        -- GCD
        showGCDSpark = false,
        gcdHeight = 4,
        gcdColor = { r = 1, g = 1, b = 1 },

        -- Interrupt feedback
        showInterruptFeedback = true,
        interruptFeedbackColor = { r = 0.1, g = 0.8, b = 0.1 },
        interruptFeedbackFontSize = 28,

        -- ===== PLAYER =====
        player = {
            enabled = true,
            width = 260,
            height = 22,
            showIcon = true,
            iconSide = "LEFT",
            showTimer = true,
            showLatency = true,
            position = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -150 },
        },

        -- ===== TARGET =====
        target = {
            enabled = true,
            width = 260,
            height = 22,
            showIcon = true,
            iconSide = "LEFT",
            showTimer = true,
            showLatency = false,
            anchorToUnitFrame = true,
            anchorOffsetY = -4,
            position = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -200 },
        },

        -- ===== FOCUS =====
        focus = {
            enabled = true,
            width = 200,
            height = 18,
            showIcon = true,
            iconSide = "LEFT",
            showTimer = true,
            showLatency = false,
            anchorToUnitFrame = true,
            anchorOffsetY = -4,
            position = { point = "CENTER", relativePoint = "CENTER", x = -350, y = 100 },
        },

        -- ===== PET =====
        pet = {
            enabled = false,
            width = 150,
            height = 14,
            showIcon = true,
            iconSide = "LEFT",
            showTimer = true,
            showLatency = false,
            anchorToUnitFrame = true,
            anchorOffsetY = -4,
            position = { point = "CENTER", relativePoint = "CENTER", x = -200, y = -150 },
        },

        -- ===== BOSS =====
        boss = {
            enabled = true,
            width = 200,
            height = 18,
            showIcon = true,
            iconSide = "LEFT",
            showTimer = true,
            showLatency = false,
            anchorToUnitFrame = true,
            anchorOffsetY = -4,
            position = { point = "RIGHT", relativePoint = "RIGHT", x = -80, y = 180 },
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

    -- =====================
    -- PARTY FRAMES
    -- =====================
    partyFrames = {
        enabled = true,
        hideBlizzardFrames = true,

        -- Layout
        width = 160,
        height = 40,
        spacing = 2,
        growDirection = "DOWN",  -- DOWN, UP, RIGHT, LEFT

        -- Health
        texture = ADDON_TEXTURE,
        healthColor = "class",  -- "class", "green", "gradient"
        showHealthText = true,
        healthTextFormat = "percent",  -- percent, current, current_percent, deficit
        font = ADDON_FONT,
        fontSize = 11,
        fontOutline = "OUTLINE",

        -- Power
        showPower = true,
        powerHeight = 3,

        -- Absorb
        showAbsorb = true,
        absorbColor = { r = 0.50, g = 0.50, b = 1.00, a = 0.50 },

        -- Heal Prediction
        showHealPrediction = true,

        -- Name & Role
        showName = true,
        nameMaxLength = 0,  -- 0 = no limit
        showRoleIcon = true,
        roleIconSize = 14,
        showRaidMarker = true,
        raidMarkerSize = 16,

        -- Range
        showRange = true,
        oorAlpha = 0.40,

        -- Dispel highlight
        showDispel = true,

        -- HoT tracking
        showHoTs = true,
        hotSize = 12,
        maxHoTs = 3,

        -- Cooldown trackers (M+)
        showInterruptCD = true,
        showBrezCD = true,
        cdIconSize = 18,
        cdLayout = "vertical",  -- "vertical" (on health bar), "horizontal" (below frame)

        -- Sort
        sortByRole = true,  -- Tank > Healer > DPS

        -- Position
        position = {
            point = "LEFT",
            relativePoint = "LEFT",
            x = 20,
            y = 0,
        },

        -- Arena (enemy frames)
        arena = {
            enabled = true,
            width = 160,
            height = 40,
            spacing = 2,
            showTrinketCD = true,
            trinketSize = 20,
            showSpecIcon = true,
            position = {
                point = "RIGHT",
                relativePoint = "RIGHT",
                x = -20,
                y = 0,
            },
        },
    },

    -- =====================
    -- RAID FRAMES
    -- =====================
    raidFrames = {
        enabled = true,
        hideBlizzardFrames = true,

        -- Layout
        layout = "grid",          -- "grid" or "list"
        width = 72,
        height = 36,
        spacing = 2,
        groupSpacing = 6,

        -- Health
        texture = ADDON_TEXTURE,
        healthColor = "class",
        showHealthText = false,
        healthTextFormat = "percent",
        font = ADDON_FONT,
        fontSize = 10,
        fontOutline = "OUTLINE",

        -- Power (healers only)
        showPower = true,
        powerHeight = 2,

        -- Absorb
        showAbsorb = true,
        absorbColor = { r = 0.50, g = 0.50, b = 1.00, a = 0.50 },

        -- Heal Prediction
        showHealPrediction = true,

        -- Name & Icons
        showName = true,
        nameMaxLength = 5,
        showRoleIcon = true,
        roleIconSize = 20,
        showRaidMarker = true,
        raidMarkerSize = 12,
        readyCheckSize = 20,

        -- Range
        showRange = true,
        oorAlpha = 0.40,

        -- Dispel highlight
        showDispel = true,

        -- HoT tracking
        showHoTs = true,
        hotSize = 10,
        maxHoTs = 3,

        -- Debuff tracking
        showDebuffs = true,
        debuffSize = 14,
        maxDebuffs = 3,

        -- Defensive CDs
        showDefensives = true,
        defensiveIconSize = 14,

        -- Sort
        sortByRole = true,

        -- Position
        position = {
            point = "TOPLEFT",
            relativePoint = "TOPLEFT",
            x = 20,
            y = -200,
        },
    },

    -- =====================
    -- AURA TRACKER (WeakAura-lite)
    -- =====================
    auraTracker = {
        enabled = false,
        iconSize = 36,
        spacing = 4,
        maxIcons = 8,
        growDirection = "RIGHT",  -- RIGHT, LEFT, UP, DOWN
        showTimer = true,
        showStacks = true,
        showGlow = true,          -- glow on fresh proc
        glowDuration = 0.6,
        oorFade = false,
        timerThreshold = 5,       -- flash timer below X seconds
        fontSize = 11,
        categories = {
            trinkets = true,
            enchants = true,
            selfBuffs = true,
            raidBuffs = false,
            defensives = true,
        },
        customSpells = {},        -- user-added spellIDs: { [spellID] = true }
        blacklist = {},           -- user-removed spellIDs: { [spellID] = true }
        position = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = -180,
        },
    },

    -- =====================
    -- HOUSING
    -- =====================
    housing = {
        enabled = true,

        -- Sub-modules (each can be toggled independently)
        decorHover = true,            -- Show name/cost/stock on hovered decor
        clock      = true,            -- Editor clock + time counter
        teleport   = true,            -- Enable /tm home + smart teleport
        itemAlert  = false,           -- Reserved for Phase 2

        -- DecorHover options
        decorHover_enableDupe    = true,   -- Allow modifier-key duplication
        decorHover_duplicateKey  = 2,      -- 1 = LCTRL, 2 = LALT

        -- Clock options
        clock_analog     = false,     -- true = analog dial, false = digital readout
        clock_totalTime  = 0,         -- Persisted total seconds spent in editor
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

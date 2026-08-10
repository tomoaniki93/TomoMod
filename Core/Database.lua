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
        showTracking = true,
        trackingStyle = "tomomod",    -- "tomomod" | "blizzard"
        collectorStyle = "tomomod",   -- "tomomod" | "blizzard"
        showMail = true,
        showDifficulty = true,
        showExpansion = true,
        showCraftingOrder = true,
        buttonBag = {
            enabled = true,
            anchor = "corner",   -- "corner" | "clock-left" | "clock-right"
            clockGap = 2,         -- écart en px par rapport à l'horloge
            corner = "BOTTOMLEFT",
            scale = 1.0,
            x = 2,
            y = 26,
            columns = 5,
            iconSize = 28,
        },
        position = { anchor = "TOPRIGHT", relTo = "TOPRIGHT", x = -20, y = -20 },
        indicators = {
            tracking   = { corner = "TOPLEFT",     scale = 1.0, x = 2,  y = -2 },
            mail       = { corner = "BOTTOMRIGHT", scale = 1.0, x = -2, y = 2  },
            crafting   = { corner = "BOTTOMRIGHT", scale = 1.0, x = -2, y = 26 },
            difficulty = { corner = "TOPRIGHT",    scale = 1.0, x = -2, y = -2 },
            expansion  = { corner = "BOTTOMLEFT",  scale = 1.0, x = 2,  y = 2  },
        },
    },
    infoPanel = {
        enabled = true,
        showTime = true,
        showCoords = true,
        showDurability = true,
        use24Hour = true,
        useServerTime = true,
        durabilityAnchor = "BOTTOMLEFT",
        durabilityX = 6,
        durabilityY = 6,
    },
    cursorRing = {
        enabled = false,
        scale = 1.0,
        useClassColor = false,
        anchorTooltip = false,
        shape = "ring",
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
        hideWhenEmpty = true,
        headerFontSize = 13,
        categoryFontSize = 11,
        questFontSize = 12,
        objectiveFontSize = 11,
        maxQuestsShown = 0,
        buckets = true,
        bucketsCollapsed = {},
        scale = 1.0,
        position = { point = "TOPRIGHT", relativePoint = "TOPRIGHT", x = -110, y = -260 },
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
        showGroundSpeed = true,
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
    consumableBar = {
        enabled     = false,
        iconSize    = 36,
        gap         = 4,
        showMissing = false,        -- afficher les slots manquants en fantôme
        orientation = "horizontal", -- "horizontal" | "vertical"
        timerPos    = "below",      -- "below" | "above" (H) | "right" | "left" (V)
        position    = nil,          -- { point, relativePoint, x, y }
    },
    rareAlert = {
        enabled  = false,
        sound    = true,
        duration = 20,              -- secondes d'affichage de la bannière
        position = nil,             -- { point, relativePoint, x, y } une fois déplacée
        scale    = 1.0,
    },
    compass = {
        enabled      = false,       -- opt-in (comme la barre de consommables)
        width        = 340,         -- largeur de la barre (px)
        height       = 28,          -- hauteur de la bande (px)
        fov          = 60,          -- demi-champ visible (degrés) : 45 / 60 / 90
        scale        = 1.0,
        bgAlpha      = 0.9,
        showQuest    = true,        -- marqueur ambre vers la quête super-suivie
        showWaypoint = true,        -- marqueur teal vers le point de route
        showDistance = true,        -- distance sous les marqueurs
        showHeading  = true,        -- readout de cap (ex. « 245° SO »)
        position     = nil,         -- { point, relativePoint, x, y }
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
    hideTalkingHead = {
        enabled = false,
    },
    -- Edit Mode's "Status Bar 2". Suppressed by alpha, never Hide(): the
    -- container is touched by Blizzard's secure code and forcing its shown
    -- state propagates taint.
    hideStatusBar2 = {
        enabled = false,
    },
    fastLoot = {
        enabled = true,
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
    -- =====================
    -- MICRO BAR
    -- Standalone bar of click-forwarders replacing the native micro menu.
    -- `order` is an array, and MergeTables fills arrays index by index, so a
    -- reordered list survives updates while a def appended in a later version
    -- still lands in the player's order.
    -- =====================
    microBar = {
        enabled       = false,
        hideNative    = true,          -- mute the Blizzard micro menu
        iconSize      = 26,
        spacing       = 4,
        scale         = 1.0,
        alpha         = 1.0,
        orientation   = "horizontal",  -- "horizontal" | "vertical"
        perLine       = 0,             -- 0 = single row / column
        colorMode     = "class",       -- "class" | "custom" | "native"
        color         = { r = 1, g = 1, b = 1 },
        desaturate    = true,
        hoverZoom     = true,
        memoryTooltip = true,
        fadeMode      = "always",      -- "always" | "hover" | "hovercombat"
        fadeAlpha     = 0,
        fadeIn        = 0.15,
        fadeOut       = 0.25,
        -- State parity with the native buttons: alert pulses, disabled state,
        -- keybind hints. alertStyle shares ClassReminder's vocabulary.
        alertStyle    = "Pixel Glow",   -- "None" | "Pixel Glow" | "Autocast Shine" | "Action Button Glow" | "Proc Glow"
        alertColor    = { r = 1.0, g = 0.82, b = 0.20 },
        dimDisabled   = true,
        disabledAlpha = 0.35,
        showKeybind   = false,
        keybindSize   = 10,
        -- `position` is written on first drag; absent means "use the default anchor".
        buttons = {
            character = true, spells = true, profession = true, achievement = true,
            quest = true, guild = true, lfd = true, collections = true,
            ej = true, housing = true, social = true, store = false,
            bags = true, mainmenu = true,
        },
        order = {
            "character", "spells", "profession", "achievement", "quest",
            "guild", "lfd", "collections", "ej", "housing",
            "social", "store", "bags", "mainmenu",
        },
    },
    MythicKeys = {
        enabled = true,
        miniFrame = true,
        autoRefresh = true,
        sendToChat = true,
    },
    -- Keystones shared by KeySync, kept across logouts and wiped at the
    -- weekly reset. Learned from other players, never authored.
    Keystones = {},
    KeystonesResetAt = 0,

    -- Cooldown Studio is a load-on-demand addon: once loaded it stays in
    -- memory for the session. The safety reload releases it on close.
    CDStudio = {
        safetyReload = true,
    },

    MythicTracker = {
        schemaVersion = 1,
        enabled      = true,
        position     = { anchor = "TOPRIGHT", relTo = "TOPRIGHT", x = -20, y = -260 },
        scale        = 1.0,
        alpha        = 0.95,
        locked       = true,
        hideBlizzard = true,
        showTimer    = true,
        showForces   = true,
        showBosses   = true,
        -- Style. "preset" is only a label for the combination below: it
        -- moves to "custom" as soon as one of these is changed by hand,
        -- so a named preset always means what it says.
        preset          = "panel",  -- "panel" | "hud" | "custom"
        showBackground  = true,
        showHeaderBlock = true,
        showDungeonName = false,
        objectiveStyle  = "rows",   -- "rows" | "text" | "none"
        timerLayout     = "stacked",-- "stacked" | "inline"
        segmentColors   = "palier", -- "palier" (mint/yellow/red) | "brand"
        -- Best run per dungeon and key level, recorded from your own runs.
        -- Feeds both the per-boss deltas and the forces checkpoints, so
        -- neither feature ships an authored table that could go stale.
        splits             = {},
        splitsEnabled      = true,
        checkpointsEnabled = true,
        fontLSM         = "",       -- "" = the preset's bundled font
        fontScale       = 1.0,
        -- challengeMapID -> journalInstanceID, learned at runtime from the
        -- live client. Never authored, so it cannot go stale at a patch.
        learnedEJ       = {},
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
    autoVendorRepair = {
        sellGrays    = true,
        autoRepair   = true,
        printSummary = true,
    },
    merchantTools = {
        alreadyKnown = {
            enabled = true,
            mode    = "MONOCHROME",  -- "MONOCHROME" ou "COLOR"
            color   = { r = 0.180, g = 0.847, b = 0.518 },
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
        movable = false,
        position = nil,  -- { x, y } en coordonnées écran (BOTTOMLEFT) une fois déplacé
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
        chatHistory = true,
        historyMaxLines = 128,       -- hard cap on stored lines (10-500)
        historyMaxAge = 21600,       -- seconds; 0 = no age limit (6h default)
        historySeparator = true,     -- print a session marker after the replay
        historyDelay = 2,            -- seconds after login before replaying;
                                     -- keeps addon load errors readable
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
        layoutMode = "combined",     -- "combined", "separateBags"
        sortMode = "quality",
        reverseBagOrder = false,
        stackMerge = false,
        showEmptySlots = true,
        showRecentItems = true,
        showBagBar = true,
        collapsedSections = {},
        position = { anchor = "BOTTOMRIGHT", relTo = "BOTTOMRIGHT", x = -20, y = 60 },
    },
    gameMenuSkin = {
        enabled = true,
    },
    tooltipSkin = {
        enabled = true,
        bgAlpha = 0.97,
        borderAlpha = 0.8,
        bgColor = { r = 0.06, g = 0.06, b = 0.08 },
        borderColor = { r = 0.20, g = 0.20, b = 0.24 },
        anchor = "default",        -- default | cursor | corner | custom
        anchorCorner = "BOTTOMRIGHT",
        fontSize = 12,
        -- Bars are out by design: the information layer replaces them.
        hideHealthBar = true,
        useClassColorNames = true,
        hidePlayerServer = false,
        hidePlayerTitle = false,
        useGuildNameColor = true,
        guildNameColor = { r = 0.180, g = 0.847, b = 0.518 },

        -- ---- Unit information layer (TooltipInfo.lua) ----
        showUnitInfo              = true,   -- master switch for the lines below
        infoIconSize              = 14,
        reactionBorder            = true,   -- border tinted by reaction/class
        colorTooltipLevel         = true,   -- level line by difficulty colour
        showTooltipRaidMarker     = true,
        showTooltipRoleIcon       = true,
        showTooltipClassIcon      = false,  -- redundant with the coloured name
        showTooltipGuildRank      = true,
        showTooltipGuildRankIndex = false,
        showTooltipGuildRealm     = true,
        showTooltipTarget         = true,
        showTooltipMythicScore    = true,
        showTooltipMount          = true,
        showTooltipSpeed          = false,  -- drives the refresh loop; opt-in
        showTooltipLocation       = false,  -- player/party only, see TooltipInfo

        -- ---- Inspection (TooltipInspect.lua) ----
        showTooltipItemLevel      = true,
        showTooltipSpec           = true,
        showTooltipSpecIcon       = true,
        inspectPendingText        = true,   -- show "..." while the reply lands
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
        color        = { r = 0.180, g = 0.847, b = 0.518 }, -- accent teal
    },

    professionHelper = {
        enabled = false,
        filterGreen = true,
        filterBlue = true,
        filterEpic = false,
    },

    classReminder = {
        enabled = false,
        scale = 1.0,
        textColor = { r = 1, g = 1, b = 1 },
        -- Icon row
        iconSize = 40,
        iconSpacing = 8,
        showText = true,
        textSize = 12,
        opacity = 1.0,
        glowType = "Pixel Glow",
        glowColor = { r = 1.0, g = 0.78, b = 0.14 },
        -- Context: where the row is allowed to appear, and the states that
        -- silence it regardless.
        showIn = "always",          -- always | instances | group
        hideWhenResting = true,
        -- Also remind when an in-range group member is missing a group buff.
        -- Off by default: it costs a broad UNIT_AURA registration.
        showOthersMissing = false,
        -- Per-entry opt-out from the coverage grid, keyed by locale name key.
        -- A missing key means enabled, so nothing has to be seeded here.
        entries = {},
        -- Placement is owned by the mover; offsetX/offsetY were migrated into
        -- this and removed (see crIconRework).
        position = nil,
    },

    afkDisplay = {
        enabled = true,
        rotateCamera = true,
        playerModel = true,
        modelScale = 1.0,
    },

    lustSound = {
        enabled = false,
        sound = "TALUANI",
        channel = "Master",
        forceSound = true,
        showChat = false,
        debug = false,
    },

    cooldownManager = {
        enabled = true,
        -- Masquage individuel des quatre viewers Blizzard (essential, utility,
        -- buffIcon, buffBar). Seules les clés à true sont stockées.
        hiddenViewers = {},
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
        -- Phase 4 : réglages par viewer (CDMHolders)
        -- Clés : iconSize (nil = auto), spacing, rowLimit (nil/0 = illimité),
        -- direction, secondaryDirection, position {x, y} (rel. CENTER UIParent),
        -- barWidth/barHeight/spacing pour buffBar.
        -- position volontairement absente des défauts : capturée depuis la
        -- position Edit Mode Blizzard actuelle au premier lancement (migration douce).
        viewerLayout = {
            essential = {},
            utility   = {},
            buffIcon  = {},
            buffBar   = {},
        },
    },

    -- =====================
    -- RESOURCE BARS
    -- =====================
    resourceBars = {
        enabled = true,
        displayMode = "bars",       -- "icons" (GW2 textures) or "bars" (flat colors)
        visibilityMode = "always",   -- always, combat, target, hidden
        combatAlpha = 1.0,
        oocAlpha = 0.6,
        width = 260,
        primaryHeight = 16,          -- class power display height
        secondaryHeight = 12,        -- druid mana bar height
        primaryPowerCentered = true, -- show primary power (mana/energy/rage) centered on screen
        primaryPowerBarHeight = 14,   -- height of centered primary power bar
        scale = 1.0,
        showText = true,
        textAlignment = "CENTER",    -- LEFT, CENTER, RIGHT
        font = ADDON_FONT,
        fontSize = 11,
        syncWidthWithCooldowns = false,
        -- v2.8 : Barre de vie HUD + animations + ticks + seuils
        healthBarEnabled = false,
        healthBarHeight = 14,
        healthTextFormat = "both",       -- none / value / percent / both
        healthClassColored = true,
        healthThresholdEnabled = true,
        healthThresholdPct = 30,
        smoothBars = true,
        powerTicks = "",                 -- % du max, ex : "25 50 75"
        powerThresholdEnabled = false,
        powerThresholdPct = 25,
        position = {
            point = "BOTTOM",
            relativePoint = "CENTER",
            x = 0,
            y = -230,
        },
        colors = {
            mana            = { r = 0.00, g = 0.00, b = 1.00 },
            comboPoints     = { r = 1.00, g = 0.96, b = 0.41 },
            chargedComboPoints = { r = 0.95, g = 0.20, b = 0.20 },
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
            icicles         = { r = 0.55, g = 0.85, b = 1.00 },
            -- v2.8
            health          = { r = 0.15, g = 0.75, b = 0.30 },
            healthLow       = { r = 1.00, g = 0.20, b = 0.20 },
            powerLow        = { r = 1.00, g = 0.25, b = 0.25 },
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

        -- Aperçu du panneau de configuration : alimente les cadres d'aperçu
        -- avec les vraies données quand l'unité existe (sinon, simulation).
        previewLiveData = true,

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
            focus         = { r = 0.180, g = 0.847, b = 0.518 },
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
            hasThreat     = { r = 0.180, g = 0.847, b = 0.518 },
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
        showLeaderIcon = true,
        leaderIconSize = 14,
        showRaidMarker = true,
        raidMarkerSize = 16,
        readyCheckSize = 24,
        summonSize = 30,

        -- Range
        showRange = true,
        oorAlpha = 0.40,

        -- Dispel highlight
        showDispel = true,
        dispelBorderSize = 2,

        -- HoT tracking
        showHoTs = true,
        hotSize = 12,
        maxHoTs = 3,

        -- Defensive cooldowns (active buffs on the member)
        -- Externals are what a healer needs mid-pull; raid-wide buffs light up
        -- every frame at once and personals are informative but noisy, so both
        -- start off.
        showDefensives = true,
        defensiveIconSize = 16,
        maxDefensives = 2,
        defensiveShowExternals = true,
        defensiveShowRaidWide = false,
        defensiveShowPersonals = false,

        -- Cooldown trackers (M+)
        showInterruptCD = true,
        showBrezCD = true,
        cdIconSize = 18,
        cdLayout = "vertical",  -- "vertical" (on health bar), "horizontal" (below frame)

        -- Resurrection indicator (incoming res cast on this member)
        showResurrectIndicator = true,
        resurrectIconSize = 26,

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
        skinGroupManager = true,

        -- Layout
        layout = "grid",          -- "grid" or "list"
        width = 72,
        height = 36,
        spacing = 2,
        groupSpacing = 6,

        -- Per-size layout overrides (10 / 25 / 40). When enabled, the matching
        -- bracket's non-nil fields override the base width/height/spacing above
        -- according to the current group size; nil fields inherit the base.
        raidSizeOverrides = {
            enabled = false,
            ["10"] = { width = 72, height = 40, spacing = 2, groupSpacing = 6 },
            ["25"] = { width = 72, height = 32, spacing = 2, groupSpacing = 5 },
            ["40"] = { width = 64, height = 28, spacing = 1, groupSpacing = 4 },
        },

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
        summonSize = 22,

        -- Resurrection indicator (incoming res cast on this member)
        showResurrectIndicator = true,
        resurrectIconSize = 22,

        -- Range
        showRange = true,
        oorAlpha = 0.40,

        -- Dispel highlight
        showDispel = true,
        dispelBorderSize = 2,

        -- HoT tracking
        showHoTs = true,
        hotSize = 10,
        maxHoTs = 3,

        -- Debuff tracking
        showDebuffs = true,
        debuffSize = 14,
        maxDebuffs = 3,

        -- Defensive cooldowns (active buffs on the member)
        showDefensives = true,
        defensiveIconSize = 14,
        maxDefensives = 2,
        defensiveShowExternals = true,
        defensiveShowRaidWide = false,
        defensiveShowPersonals = false,

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
    -- BATTLE-REZ COUNTER (standalone HUD)
    -- Reads the shared combat-resurrection charge pool (C_Spell.GetSpellCharges
    -- on Rebirth / 20484) so any class can see how many brez are available and
    -- the time to the next charge. The pool only exists in instanced content.
    -- =====================
    battleRez = {
        enabled = true,
        onlyInstance = true,   -- hide outside dungeons/raids (no shared pool there)
        size = 44,
        fontSize = 18,
        showSwipe = true,
        position = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 200 },
    },

    -- =====================
    -- HOUSING
    -- =====================
    housing = {
        enabled = true,

        -- Sub-modules (each can be toggled independently)
        decorHover = false,           -- Show name/cost/stock on hovered decor
        clock      = true,            -- Editor clock + time counter
        teleport   = false,           -- Enable /tm home + smart teleport
        itemAlert  = false,           -- Reserved for Phase 2

        -- DecorHover options
        decorHover_enableDupe    = false,  -- Allow modifier-key duplication
        decorHover_duplicateKey  = 2,      -- 1 = LCTRL, 2 = LALT

        -- Clock options
        clock_analog     = false,     -- true = analog dial, false = digital readout
        clock_totalTime  = 0,         -- Persisted total seconds spent in editor
    },

    -- =====================
    -- COOLDOWN FORGE (AstralForge Cooldown) -- schema V1
    -- Bars stored per class token; empty by default. Defensive merge
    -- fills only missing keys, so player bars are never clobbered on update.
    -- =====================
    cooldownForge = {
        -- Aura ids the client has been observed naming. Learned at runtime,
        -- never authored, so it cannot go stale at a patch.
        readableAuraIDs = {},
        schemaVersion = 1,
        enabled       = true,
        bars          = {},   -- [classToken] = { <BarSchema>, ... }
    },
}

-- =====================================
-- DB FUNCTIONS
-- =====================================

-- =====================================
-- ONE-TIME DATA MIGRATIONS
-- =====================================
-- MergeTables only fills in MISSING keys, so changing a default never
-- reaches an existing database. Anything that has to be corrected on
-- profiles already in the wild goes here, each step behind its own flag
-- so it runs exactly once whatever version the player is coming from.
--
-- The bookkeeping table is excluded from profile snapshots in
-- Core/Profiles.lua: otherwise restoring a profile saved before a
-- migration would clear the flag and let that migration fire again,
-- undoing a setting the player had deliberately changed back.
local function TomoMod_RunMigrations()
    if type(TomoModDB._migrations) ~= "table" then TomoModDB._migrations = {} end
    local done = TomoModDB._migrations

    -- With no quest tracked, the objective tracker used to leave an empty
    -- panel on screen -- and, because its height was measured from
    -- Blizzard's always-shown containers, a panel covering most of the
    -- screen. hideWhenEmpty now defaults to true; bring existing profiles
    -- along once. A player who prefers the old behaviour can turn it back
    -- off and it will stick.
    -- The tooltip now ships an information layer instead of bars, so bring
    -- existing profiles onto hideHealthBar = true once. A player who wants the
    -- bar back can untick it and it will stick.
    -- The aura tracker is gone: CooldownForge covers the same ground, and
    -- keeping a second overlay competing for the same screen space was the
    -- reason it existed at all. Drop the table rather than leave it
    -- orphaned in every profile -- nothing reads it now, and Profiles.lua
    -- would go on copying it around forever.
    -- The buff frame skin is gone. Blizzard's aura buttons report secret
    -- dimensions, so any backdrop we attached to them threw inside
    -- Blizzard's own Backdrop.lua, and the frames get reshaped every
    -- patch. Nothing here can be carried anywhere, so the table is simply
    -- dropped rather than left orphaned in every profile.
    if not done.dropBuffSkin then
        done.dropBuffSkin = true
        TomoModDB.buffSkin = nil
    end

    if not done.dropAuraTracker then
        done.dropAuraTracker = true
        -- customSpells was hand-typed by the player and has no equivalent
        -- in CooldownForge's schema, so it cannot be converted. Losing it
        -- silently would be the worst outcome; stash the IDs and let the
        -- login path report them once, so they can be recreated. Only the
        -- additions are worth keeping -- blacklist entries were removals
        -- from a default list that no longer exists.
        local at = TomoModDB.auraTracker
        if type(at) == "table" and type(at.customSpells) == "table" then
            local ids = {}
            for spellID, on in pairs(at.customSpells) do
                if on and tonumber(spellID) then
                    ids[#ids + 1] = tonumber(spellID)
                end
            end
            if #ids > 0 then
                table.sort(ids)
                TomoModDB._auraTrackerRescue = ids
            end
        end
        TomoModDB.auraTracker = nil
    end

    if not done.ttHideHealthBar then
        done.ttHideHealthBar = true
        if type(TomoModDB.tooltipSkin) == "table" then
            TomoModDB.tooltipSkin.hideHealthBar = true
        end
    end

    if not done.otHideWhenEmpty then
        done.otHideWhenEmpty = true
        if type(TomoModDB.objectiveTracker) == "table" then
            TomoModDB.objectiveTracker.hideWhenEmpty = true
        end
    end

    -- The bag "categories" layout is gone. A profile still set to it would
    -- fall through every branch of LayoutGrid and render an empty bag, so
    -- move those players onto the combined grid once.
    if not done.bagDropCategories then
        done.bagDropCategories = true
        local bs = TomoModDB.bagSkin
        if type(bs) == "table" then
            if bs.layoutMode == "categories" then bs.layoutMode = "combined" end
            bs.bagCategoryState, bs.bagCategoryOrder = nil, nil
        end
    end

    -- CoTankTracker stored posX/posY captured through GetPoint() right after
    -- StartMoving(), so they were offsets against an engine-chosen anchor, not
    -- the CENTER/CENTER the restore code applied them to. The new key holds
    -- screen coordinates against BOTTOMLEFT; the old pair cannot be converted
    -- (its origin was never recorded), so it is dropped and the frame falls
    -- back to its default spot once.
    if not done.coTankPositionV2 then
        done.coTankPositionV2 = true
        local ct = TomoModDB.coTankTracker
        if type(ct) == "table" then
            ct.posX, ct.posY = nil, nil
        end
    end

    -- The per-message chat copy icon is gone: its texture failed to resolve
    -- and left a placeholder glyph in front of every line. The option is no
    -- longer in the GUI, so clear it for anyone who had it on -- otherwise
    -- they would keep the glyphs with no way to switch them off.
    if not done.chatDropCopyLines then
        done.chatDropCopyLines = true
        if type(TomoModDB.chatFrameSkin) == "table" then
            TomoModDB.chatFrameSkin.copyChatLines = nil
        end
    end

    -- The contacts window skin is gone: Blizzard rebuilds that frame in 12.1,
    -- so skinning it would break on patch day. Drop the orphaned table rather
    -- than leave it sitting in every saved profile.
    if not done.dropFriendsSkin then
        done.dropFriendsSkin = true
        TomoModDB.friendsSkin = nil
    end

    -- The class reminder is an icon row now, not a line of text. Its two
    -- offset sliders are gone -- the row is placed with the mover like every
    -- other movable element -- so carry an existing offset over as a real
    -- anchor point once, then drop the dead keys. Profiles that never touched
    -- the sliders keep the default centre position.
    if not done.crIconRework then
        done.crIconRework = true
        local cr = TomoModDB.classReminder
        if type(cr) == "table" then
            if cr.position == nil
               and ((tonumber(cr.offsetX) or 0) ~= 0 or (tonumber(cr.offsetY) or 0) ~= 0) then
                cr.position = {
                    point         = "CENTER",
                    relativePoint = "CENTER",
                    x             = tonumber(cr.offsetX) or 0,
                    y             = tonumber(cr.offsetY) or 0,
                }
            end
            cr.offsetX, cr.offsetY = nil, nil
        end
    end
end

function TomoMod_InitDatabase()
    if not TomoModDB then
        TomoModDB = {}
    end
    TomoMod_MergeTables(TomoModDB, TomoMod_Defaults)
    TomoMod_RunMigrations()
end

function TomoMod_ResetDatabase()
    TomoModDB = CopyTable(TomoMod_Defaults)
    print("|cff2ed884TomoMod|r " .. TomoMod_L["msg_db_reset"])
end

function TomoMod_ResetModule(moduleName)
    if TomoMod_Defaults[moduleName] then
        TomoModDB[moduleName] = CopyTable(TomoMod_Defaults[moduleName])
        print("|cff2ed884TomoMod|r " .. string.format(TomoMod_L["msg_module_reset"], moduleName))
    end
end

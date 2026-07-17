-- ============================================================
-- Presets.lua — Archétypes de configuration (TomoMod 3.0)
-- ------------------------------------------------------------
-- Moteur de presets : chaque archétype écrit une configuration
-- cohérente et déterministe dans TomoModDB. Sert de fondation à
-- l'installeur « presets d'abord » et au bouton "Appliquer un
-- preset" du dashboard.
--
-- Modèle :
--   1. BASE  — état recommandé "complet" (on/off explicite pour
--              chaque toggle géré par l'installeur).
--   2. DELTA — chaque preset = BASE + un petit jeu de surcharges.
--   Apply(key) applique TOUJOURS BASE puis le DELTA, donc passer
--   d'un preset à l'autre est 100% déterministe et idempotent.
--
-- Les presets ne touchent QUE "ce qui est activé" + quelques
-- options signature. Ils ne modifient jamais les positions ni les
-- tailles d'éléments (layout = défauts / choix utilisateur).
-- ============================================================

TomoMod_Presets = TomoMod_Presets or {}
local P = TomoMod_Presets

-- ------------------------------------------------------------
-- LOCALES (autonome — pas besoin de toucher aux gros fichiers)
-- enUS = fallback de base ; frFR = langue principale.
-- Les autres langues retomberont proprement sur l'anglais via la
-- metatable de TomoMod_L jusqu'à leur traduction (Phase 2).
-- ------------------------------------------------------------
if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["preset_complet_name"]  = "Recommended",
        ["preset_complet_tag"]   = "The full TomoMod experience",
        ["preset_complet_desc"]  = "Enables every core module with sensible defaults: unit frames, party & raid frames, nameplates, castbars, resources, action bar skin, all visual skins, Mythic+ tools and the most useful quality-of-life features. The best starting point for most players.",
        ["preset_tank_name"]     = "Tank",
        ["preset_tank_tag"]      = "Threat-focused, wider nameplates",
        ["preset_tank_desc"]     = "The Recommended setup, tuned for tanking: threat-colored nameplates (Tank Mode) and slightly wider plates for better threat readability, plus the target threat indicator.",
        ["preset_healer_name"]   = "Healer",
        ["preset_healer_tag"]    = "Bigger raid frames, mana visible",
        ["preset_healer_desc"]   = "The Recommended setup, tuned for healing: larger, more clickable raid & party frames with power (mana) bars shown, HoT tracking, dispel highlights and defensive cooldowns front and center.",
        ["preset_dps_name"]      = "DPS",
        ["preset_dps_tag"]       = "Emphasized resources & cooldowns",
        ["preset_dps_desc"]      = "The Recommended setup, tuned for damage: a more prominent resource bar, target buff tracking for enemy defensives, and clean nameplates without tank threat coloring.",
        ["preset_minimal_name"]  = "Minimal",
        ["preset_minimal_tag"]   = "Just the essentials",
        ["preset_minimal_desc"]  = "A lightweight footprint: keeps unit frames, party & raid frames, castbars, resource bars, the minimap and the most essential automations — everything cosmetic (skins, chat, bags, nameplates, extra panels) stays off. Closest to a vanilla feel.",
        ["preset_custom_name"]   = "Custom",
        ["preset_custom_tag"]    = "Configure everything yourself",
        ["preset_custom_desc"]   = "Skip the presets and walk through every category step by step to enable exactly what you want. You can always change anything later from /tm.",
        ["preset_applied"]       = "Preset applied: %s — type /reload to see the result.",
        ["preset_unknown"]       = "Unknown preset '%s'. Available: complet, tank, healer, dps, minimal.",
        ["preset_usage"]         = "Usage: /tmpreset <complet|tank|healer|dps|minimal>",
    })

    TomoMod_RegisterLocale("frFR", {
        ["preset_complet_name"]  = "Recommandé",
        ["preset_complet_tag"]   = "L'expérience TomoMod complète",
        ["preset_complet_desc"]  = "Active tous les modules principaux avec des réglages cohérents : unit frames, cadres de groupe et de raid, nameplates, barres d'incantation, ressources, skin des barres d'action, tous les skins visuels, les outils Mythic+ et les fonctions de confort les plus utiles. Le meilleur point de départ pour la plupart des joueurs.",
        ["preset_tank_name"]     = "Tank",
        ["preset_tank_tag"]      = "Axé menace, nameplates élargies",
        ["preset_tank_desc"]     = "La configuration Recommandée, ajustée pour le tanking : nameplates colorées selon la menace (Mode Tank) et un peu plus larges pour mieux lire l'aggro, plus l'indicateur de menace sur la cible.",
        ["preset_healer_name"]   = "Soigneur",
        ["preset_healer_tag"]    = "Cadres de raid plus grands, mana visible",
        ["preset_healer_desc"]   = "La configuration Recommandée, ajustée pour le soin : cadres de raid et de groupe plus grands et plus faciles à cliquer, avec les barres de ressource (mana) affichées, le suivi des HoTs, la surbrillance de dissipation et les défensifs bien en évidence.",
        ["preset_dps_name"]      = "DPS",
        ["preset_dps_tag"]       = "Ressources et cooldowns mis en avant",
        ["preset_dps_desc"]      = "La configuration Recommandée, ajustée pour les dégâts : barre de ressource plus visible, suivi des buffs de la cible pour repérer les défensifs ennemis, et nameplates épurées sans coloration de menace tank.",
        ["preset_minimal_name"]  = "Minimal",
        ["preset_minimal_tag"]   = "Juste l'essentiel",
        ["preset_minimal_desc"]  = "Une empreinte légère : on garde les unit frames, les cadres de groupe et de raid, les barres d'incantation, les barres de ressource, la minimap et les automatisations essentielles — tout le cosmétique (skins, chat, sacs, nameplates, panneaux annexes) reste désactivé. Au plus proche d'une sensation vanilla.",
        ["preset_custom_name"]   = "Personnalisé",
        ["preset_custom_tag"]    = "Tout configurer soi-même",
        ["preset_custom_desc"]   = "Passez les presets et parcourez chaque catégorie étape par étape pour activer exactement ce que vous voulez. Tout reste modifiable ensuite via /tm.",
        ["preset_applied"]       = "Preset appliqué : %s — tapez /reload pour voir le résultat.",
        ["preset_unknown"]       = "Preset inconnu « %s ». Disponibles : complet, tank, healer, dps, minimal.",
        ["preset_usage"]         = "Usage : /tmpreset <complet|tank|healer|dps|minimal>",
    })
end

local L = TomoMod_L

-- ------------------------------------------------------------
-- Helper : SetPath(root, "a.b.c", value)
-- Crée les tables intermédiaires manquantes au besoin.
-- ------------------------------------------------------------
local function SplitPath(path)
    local segs = {}
    for seg in string.gmatch(path, "[^.]+") do
        segs[#segs + 1] = seg
    end
    return segs
end

local function SetPath(root, path, value)
    local segs = SplitPath(path)
    local node = root
    for i = 1, #segs - 1 do
        local k = segs[i]
        if type(node[k]) ~= "table" then node[k] = {} end
        node = node[k]
    end
    node[segs[#segs]] = value
end
P.SetPath = SetPath  -- exposé (utile au dashboard / installeur)

-- ============================================================
-- BASE — état "Complet recommandé"
-- On/off explicite pour CHAQUE toggle géré par l'installeur.
-- ============================================================
local BASE = {
    -- ── Cadres ────────────────────────────────────────────
    ["unitFrames.enabled"]              = true,
    ["unitFrames.hideBlizzardFrames"]   = true,
    ["unitFrames.target.showThreat"]    = true,

    ["partyFrames.enabled"]             = true,
    ["partyFrames.hideBlizzardFrames"]  = true,
    ["partyFrames.showInterruptCD"]     = true,
    ["partyFrames.showBrezCD"]          = true,
    ["partyFrames.showHoTs"]            = true,
    ["partyFrames.showDispel"]          = true,
    ["partyFrames.showPower"]           = true,
    ["partyFrames.sortByRole"]          = true,

    ["raidFrames.enabled"]              = true,
    ["raidFrames.hideBlizzardFrames"]   = true,
    ["raidFrames.skinGroupManager"]     = true,
    ["raidFrames.showDispel"]           = true,
    ["raidFrames.showHoTs"]             = true,
    ["raidFrames.showDebuffs"]          = true,
    ["raidFrames.showDefensives"]       = true,
    ["raidFrames.showPower"]            = true,
    ["raidFrames.sortByRole"]           = true,
    ["raidFrames.layout"]               = "grid",
    ["raidFrames.height"]               = 36,

    ["castbars.enabled"]                = true,
    ["castbars.hideBlizzardCastbar"]    = true,
    ["castbars.useClassColor"]          = true,

    ["nameplates.enabled"]              = true,
    ["nameplates.useClassColors"]       = true,
    ["nameplates.showCastbar"]          = true,
    ["nameplates.showAuras"]            = true,
    ["nameplates.showHealthText"]       = true,
    ["nameplates.friendlyRoleIcons"]    = true,
    ["nameplates.tankMode"]             = false,
    ["nameplates.width"]                = 170,

    ["resourceBars.enabled"]            = true,
    ["resourceBars.primaryHeight"]      = 16,

    ["cooldownManager.enabled"]         = true,
    ["auraTracker.enabled"]             = false,  -- avancé : opt-in

    -- ── Barres d'action ───────────────────────────────────
    ["actionBars.enabled"]              = true,
    ["actionBarSkin.enabled"]           = true,
    ["actionBarSkin.skinStyle"]         = "classic",
    ["actionBarSkin.useClassColor"]     = true,

    -- ── Skins ─────────────────────────────────────────────
    ["chatFrameSkin.enabled"]           = true,
    ["bagSkin.enabled"]                 = true,
    ["buffSkin.enabled"]                = true,
    ["tooltipSkin.enabled"]             = true,
    ["gameMenuSkin.enabled"]            = true,
    ["characterSkin.enabled"]           = true,
    ["objectiveTracker.enabled"]        = true,
    ["mailSkin.enabled"]                = true,
    ["reputationBar.enabled"]           = true,

    -- ── Mythic+ ───────────────────────────────────────────
    ["MythicTracker.enabled"]           = true,
    ["MythicTracker.hideBlizzard"]      = true,
    ["TomoScore.enabled"]               = true,
    ["TomoScore.autoShowMPlus"]         = true,
    ["MythicKeys.enabled"]              = true,
    ["loots.enabled"]                   = true,
    ["worldQuestTab.enabled"]           = false,  -- panneau annexe : opt-in

    -- ── Qualité de vie ────────────────────────────────────
    ["minimap.enabled"]                 = true,
    ["infoPanel.enabled"]               = true,
    ["cinematicSkip.enabled"]           = true,
    ["fastLoot.enabled"]                = true,
    ["autoVendorRepair.sellGrays"]      = true,
    ["autoVendorRepair.autoRepair"]     = true,
    ["classReminder.enabled"]           = true,
    ["waypoint.enabled"]                = true,
    ["afkDisplay.enabled"]              = true,
    ["professionHelper.enabled"]        = true,
    ["frameAnchors.enabled"]            = true,
    ["skyRide.enabled"]                 = true,
    ["lustSound.enabled"]               = true,

    -- Réglages conservateurs : off par défaut, l'utilisateur opte
    ["cursorRing.enabled"]              = false,
    ["levelingBar.enabled"]             = false,
    ["hideTalkingHead.enabled"]         = false,
    ["tooltipIDs.enabled"]              = false,
    ["autoFillDelete.enabled"]          = true,   -- inoffensif & pratique
    ["autoAcceptInvite.enabled"]        = false,
    ["autoSummon.enabled"]              = false,
    ["autoQuest.autoAccept"]            = false,
    ["autoQuest.autoTurnIn"]            = false,
}

-- ============================================================
-- DELTAS — surcharges par archétype (relatif à BASE)
-- ============================================================
local DELTAS = {
    -- Complet = BASE tel quel
    complet = {},

    -- Tank : menace en avant, plates plus larges
    tank = {
        ["nameplates.tankMode"]          = true,
        ["nameplates.width"]             = 190,
        ["unitFrames.target.showThreat"] = true,
    },

    -- Soigneur : cadres de raid plus grands, mana visible
    healer = {
        ["raidFrames.showPower"]   = true,
        ["raidFrames.height"]      = 40,
        ["partyFrames.showPower"]  = true,
        ["nameplates.tankMode"]    = false,
    },

    -- DPS : ressources mises en avant, plates épurées
    dps = {
        ["resourceBars.primaryHeight"]            = 18,
        ["unitFrames.target.enemyBuffs.enabled"]  = true,
        ["nameplates.tankMode"]                   = false,
    },

    -- Minimal : on garde le cœur, on coupe le reste
    minimal = {
        ["nameplates.enabled"]        = false,
        ["cooldownManager.enabled"]   = false,
        ["auraTracker.enabled"]       = false,

        ["actionBarSkin.enabled"]     = false,

        ["chatFrameSkin.enabled"]     = false,
        ["bagSkin.enabled"]           = false,
        ["buffSkin.enabled"]          = false,
        ["tooltipSkin.enabled"]       = false,
        ["gameMenuSkin.enabled"]      = false,
        ["characterSkin.enabled"]     = false,
        ["objectiveTracker.enabled"]  = false,
        ["mailSkin.enabled"]          = false,
        ["reputationBar.enabled"]     = false,

        ["TomoScore.enabled"]         = false,
        ["MythicKeys.enabled"]        = false,
        ["loots.enabled"]             = false,
        ["worldQuestTab.enabled"]     = false,

        ["infoPanel.enabled"]         = false,
        ["cinematicSkip.enabled"]     = false,
        ["classReminder.enabled"]     = false,
        ["waypoint.enabled"]          = false,
        ["afkDisplay.enabled"]        = false,
        ["professionHelper.enabled"]  = false,
        ["frameAnchors.enabled"]      = false,
        ["skyRide.enabled"]           = false,
        ["lustSound.enabled"]         = false,
        -- on garde : unitFrames, partyFrames, raidFrames, castbars,
        -- resourceBars, minimap, fastLoot, autoVendorRepair,
        -- MythicTracker, actionBars (le gestionnaire, inoffensif)
    },
}

-- ============================================================
-- LISTE POUR L'UI (cartes d'archétypes)
-- Résolue à chaque appel pour rester sensible à la locale active.
-- ============================================================
local ICON_ROLE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Roles\\"
local ICON      = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\icons\\"

local ORDER = {
    {
        key   = "complet",
        icon  = ICON .. "icon_general.tga",
        color = { TomoMod_Utils.BRAND[1], TomoMod_Utils.BRAND[2], TomoMod_Utils.BRAND[3] },   -- teal (accent)
        recommended = true,
    },
    {
        key   = "tank",
        icon  = ICON_ROLE .. "TANK.tga",
        color = { 0.28, 0.52, 0.92 },       -- bleu
    },
    {
        key   = "healer",
        icon  = ICON_ROLE .. "HEALER.tga",
        color = { 0.36, 0.82, 0.42 },       -- vert
    },
    {
        key   = "dps",
        icon  = ICON_ROLE .. "DAMAGER.tga",
        color = { 0.85, 0.32, 0.32 },       -- rouge
    },
    {
        key   = "minimal",
        icon  = ICON .. "icon_qol.tga",
        color = { 0.55, 0.55, 0.62 },       -- gris
    },
    {
        key   = "custom",
        icon  = ICON .. "icon_diagnostics.tga",
        color = { 0.78, 0.58, 0.16 },       -- or
        custom = true,                       -- ne touche pas la DB
    },
}

-- Retourne une liste fraîche { key, icon, color, recommended, custom,
-- name, tagline, desc } prête pour l'affichage.
function P.GetList()
    local out = {}
    for i, def in ipairs(ORDER) do
        out[i] = {
            key         = def.key,
            icon        = def.icon,
            color       = def.color,
            recommended = def.recommended,
            custom      = def.custom,
            name        = L["preset_" .. def.key .. "_name"],
            tagline     = L["preset_" .. def.key .. "_tag"],
            desc        = L["preset_" .. def.key .. "_desc"],
        }
    end
    return out
end

-- Retourne la définition (statique) d'un preset, ou nil.
function P.Get(key)
    for _, def in ipairs(ORDER) do
        if def.key == key then return def end
    end
    return nil
end

-- True si le preset existe et écrit réellement dans la DB.
function P.IsApplicable(key)
    return DELTAS[key] ~= nil
end

-- ============================================================
-- APPLY — écrit l'archétype dans TomoModDB
-- ============================================================
-- Écrit uniquement la DB ; les modules vivants se mettent à jour
-- au /reload (l'installeur recharge en fin de parcours, et le
-- dashboard proposera un reload). Pas de manipulation de valeurs
-- protégées ici : code 100% DB/chaînes, donc sans risque de taint.
function P.Apply(key)
    if not TomoModDB then return false end
    if key == "custom" then
        TomoModDB._lastPreset = "custom"
        return true
    end
    local delta = DELTAS[key]
    if not delta then return false end

    -- 1) BASE
    for path, val in pairs(BASE) do
        SetPath(TomoModDB, path, val)
    end
    -- 2) DELTA de l'archétype
    for path, val in pairs(delta) do
        SetPath(TomoModDB, path, val)
    end

    TomoModDB._lastPreset = key

    -- [Lot C] Config pages are cached; a preset rewrites the DB globally
    if TomoMod_Config and TomoMod_Config.InvalidatePanels then
        TomoMod_Config.InvalidatePanels()
    end
    return true
end

-- ============================================================
-- SLASH DEV/TEST — /tmpreset <key>
-- Permet de tester les presets en jeu dès la Phase 1, avant le
-- nouvel installeur. (Conformément à l'habitude TomoMod d'exposer
-- des commandes de diagnostic pendant le développement.)
-- ============================================================
SLASH_TOMOPRESET1 = "/tmpreset"
SlashCmdList["TOMOPRESET"] = function(msg)
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
    if msg == "" then
        print("|cff2ed884TomoMod|r " .. L["preset_usage"])
        return
    end
    if not P.IsApplicable(msg) then
        print("|cff2ed884TomoMod|r " .. string.format(L["preset_unknown"], msg))
        return
    end
    if P.Apply(msg) then
        local def  = P.Get(msg)
        local name = def and L["preset_" .. def.key .. "_name"] or msg
        print("|cff2ed884TomoMod|r " .. string.format(L["preset_applied"], name))
    end
end

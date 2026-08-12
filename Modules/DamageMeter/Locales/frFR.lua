local ADDON_NAME, TomoMod = ...

-- [MERGE] Standalone, `ns` was this addon's own private table. Embedded, the
-- vararg hands over TomoMod's, which every other file in the suite shares --
-- so 157 generic names (db, L, FONT, BG, ACCENT, Refresh, windows, inCombat)
-- would sit in the same table as everything TomoMod ever adds. Nothing
-- collides today, but the first core file that reaches for `ns.db` would
-- find this module's and neither would know.
--
-- One sub-table keeps the module's world to itself, and leaves every `ns.X`
-- below untouched.
local ns = TomoMod.DM

----------------------------------------------------------------------
-- Localization: French
----------------------------------------------------------------------

if GetLocale() ~= "frFR" then return end

local L = ns.L

-- General
L["ADDON_NAME"] = "TomoDamageMeter"
L["ADDON_SHORT"] = "Tomo"

-- Meter types
L["DPS"] = "DPS"
L["HPS"] = "HPS"
L["DAMAGE_TAKEN"] = "Dégâts subis"
L["AVOIDABLE"] = "Évitable"
L["ENEMY_DAMAGE"] = "Dégâts ennemis"
L["ABSORBS"] = "Absorptions"
L["INTERRUPTS"] = "Interruptions"
L["DISPELS"] = "Dissipations"
L["DEATHS"] = "Morts"

-- Categories
L["DAMAGE"] = "Dégâts"
L["HEALING"] = "Soins"
L["ACTIONS"] = "Actions"

-- Sessions
L["CURRENT"] = "Actuel"
L["OVERALL"] = "Global"

-- Header / UI
L["RESET"] = "Réinitialiser"
L["LOCK"] = "Verrouiller"
L["UNLOCK"] = "Déverrouiller"
L["SETTINGS"] = "Options"
L["REPORT"] = "Rapporter"
L["CLOSE"] = "Fermer"

-- Format labels
L["FMT_COMPACT"] = "Compact"
L["FMT_1DEC"] = "1 Déc"
L["FMT_2DEC"] = "2 Déc"
L["FMT_3DEC"] = "3 Déc"
L["FMT_REGULAR"] = "Normal"
L["FMT_INT"] = "Ent"
L["FMT_DEC"] = "Déc"

-- Report
L["REPORT_HEADER"] = "TomoDamageMeter : %s (%s)"
L["REPORT_NO_TARGET"] = "Pas de cible pour le chuchotement. Sélectionnez un joueur."
L["REPORT_NO_DATA"] = "Aucune donnée à rapporter."
L["REPORT_CHANNEL_SAY"] = "Dire"
L["REPORT_CHANNEL_PARTY"] = "Groupe"
L["REPORT_CHANNEL_RAID"] = "Raid"
L["REPORT_CHANNEL_GUILD"] = "Guilde"
L["REPORT_CHANNEL_WHISPER"] = "Chuchoter"
L["REPORT_CHANNEL_AUTO"] = "Auto (groupe)"
L["REPORT_CHANNEL_INSTANCE"] = "Instance"
L["REPORT_CHANNEL_SELF"] = "Afficher pour soi"
L["REPORT_CHANNEL_RESTRICTED"] = "Dire et Crier sont restreints par le jeu : un seul message d'addon passe par clic. Choisissez un canal de groupe dans les réglages."

-- Settings
L["SETTINGS_TITLE"] = "Options TomoDamageMeter"
L["SETTINGS_GENERAL"] = "Général"
L["SETTINGS_APPEARANCE"] = "Apparence"
L["SETTINGS_SKIN"] = "Skin"
L["SETTINGS_BAR_TEXTURE"] = "Texture des barres"
L["SKIN_DARK"] = "Tomo Dark"
L["SKIN_NEON"] = "Tomo Néon"
L["SKIN_MINIMAL"] = "Minimaliste"
L["SKIN_GLOSSY"] = "Glossy"
L["SKIN_EMBER"] = "Braise"
L["SKIN_FROST"] = "Givre"
L["SKIN_TERMINAL"] = "Console"
L["SKIN_VOID"] = "Abysse"
L["SKIN_PARCHMENT"] = "Parchemin"
L["SETTINGS_COLUMNS"] = "Colonnes"
L["SETTINGS_FONT_SIZE"] = "Taille de police"
L["SETTINGS_FONT_FACE"] = "Police"
L["SETTINGS_BAR_HEIGHT"] = "Hauteur des barres"
L["SETTINGS_BG_OPACITY"] = "Opacité du fond"
L["SETTINGS_OOC_OPACITY"] = "Opacité hors combat"
L["SETTINGS_BREAKDOWN_OPACITY"] = "Opacité détail des sorts"
L["SETTINGS_STRIP_REALM"] = "Masquer les noms de royaume"
L["SETTINGS_ACCENT_COLOR"] = "Couleur d'accentuation"
L["SETTINGS_USE_CLASS_COLOR"] = "Utiliser la couleur de classe"
L["SETTINGS_REPORT_CHANNEL"] = "Canal de rapport"
L["SETTINGS_REPORT_LINES"] = "Lignes du rapport"
L["SETTINGS_WINDOWS"] = "Fenêtres"
L["SETTINGS_ADD_WINDOW"] = "+ Ajouter"
L["SETTINGS_REMOVE_WINDOW"] = "- Supprimer"
L["SETTINGS_WINDOW_COUNT"] = "Fenêtres : %d / %d"
L["SETTINGS_COL_RATE"] = "Taux (DPS/HPS)"
L["SETTINGS_COL_TOTAL"] = "Total"
L["SETTINGS_COL_PCT"] = "Pourcentage"
L["SETTINGS_FORMAT"] = "Format"
L["SETTINGS_TAB_GENERAL"] = "Général"
L["SETTINGS_TAB_WINDOW"] = "Fenêtre %d"
L["SETTINGS_METER_TYPE"] = "Type de compteur"
L["SETTINGS_SESSION_TYPE"] = "Type de session"
L["SETTINGS_LOCKED"] = "Verrouiller la position"

-- Slash commands
L["CMD_RESET"] = "Données réinitialisées."
L["CMD_LOCKED"] = "Verrouillé"
L["CMD_UNLOCKED"] = "Déverrouillé"
L["CMD_HELP_HEADER"] = "Commandes :"
L["CMD_HELP_TOGGLE"] = "  /tdm — ouvrir les options"
L["CMD_HELP_TOGGLE_VIS"] = "  /tdm toggle — basculer la visibilité"
L["CMD_HELP_RESET"] = "  /tdm reset — réinitialiser les données"
L["CMD_HELP_LOCK"] = "  /tdm lock — verrouiller/déverrouiller la position"
L["CMD_HELP_DIAG"] = "  /tdm diag — tester la lisibilité des valeurs C_DamageMeter"
L["RUN_RECAP"] = "Récap de la run"
L["RUN_RECAP_NO_DATA"] = "Aucune run enregistrée"
L["RECAP_COL_INT"] = "Interr."
L["RECAP_COL_DEATHS"] = "Morts"
L["RECAP_COL_AVOIDABLE"] = "Évit."
L["SETTINGS_RUN_RECAP_AUTO"] = "Afficher le récap à la fin d'un donjon"
L["SETTINGS_SNAP"] = "Accoler les fenêtres entre elles"
L["CMD_HELP_RECAP"] = "  /tdm recap — afficher le dernier récap de run"
L["CMD_DIAG_ARMED"] = "Diagnostic armé — en attente de la prochaine mise à jour de combat."
L["CMD_HELP_HELP"] = "  /tdm help — ce message"

-- Auto-reset
L["SETTINGS_AUTO_RESET_INSTANCE"] = "Réinitialiser à l'entrée d'instance"
L["SETTINGS_COMBAT_TIMER"] = "Minuteur de combat (DPS/HPS)"
L["SETTINGS_SELF_BAR"] = "Épingler ma propre barre"
L["SETTINGS_BAR_TOOLTIPS"] = "Infobulles des barres (survol)"
L["SETTINGS_MODULES"] = "Modules"
L["SETTINGS_DEATH_RECAP_AUTO"] = "Récap. de mort à la mort"
L["SETTINGS_TIMER_POSITION"] = "Position du minuteur"
L["TIMER_POS_RIGHT"] = "Droite"
L["TIMER_POS_LEFT"] = "Gauche"
L["SETTINGS_CATEGORIES"] = "Catégories"
L["SETTINGS_CATEGORIES_MIN"] = "Au moins une catégorie doit rester activée."
L["AUTO_RESET_MSG"] = "Données réinitialisées (entrée d'instance)."

-- Combat
L["COMBAT_SETTINGS_UNAVAILABLE"] = "Options indisponibles en combat."
L["WAITING_COMBAT_END"] = "Indisponible jusqu'à la fin du combat"

-- Detail
L["SPELL_BREAKDOWN"] = "Détail des sorts"
L["NO_DATA"] = "Aucune donnée disponible"
L["DEATH_RECAP"] = "Récap. de mort"
L["DEATH_RECAP_NO_DATA"] = "Aucune mort enregistrée"
L["RECAP_HEAL"] = "Soin"
L["RECAP_MELEE"] = "Mêlée"
L["RECAP_UNKNOWN"] = "Inconnu"
L["BREAKDOWN_SPELLS_LABEL"] = "sorts"
L["BREAKDOWN_CRITS_LABEL"] = "crits"
L["BREAKDOWN_CRIT_RATE_LABEL"] = "crit"
L["BREAKDOWN_COL_SPELL"] = "Sort"
L["BREAKDOWN_COL_TOTAL"] = "Total"

-- Segments / Target Breakdown
L["SEGMENTS"] = "Segments"
L["SEGMENT"] = "Segment"
L["SEGMENT_COL_NAME"] = "Rencontre"
L["TARGET_BREAKDOWN"] = "Détail des cibles"
L["TARGET_COL_NAME"] = "Cible"

-- Tooltips
L["TIP_SETTINGS"] = "Ouvrir les options"
L["TIP_TARGET"] = "Détail des cibles"
L["TIP_DETAILS"] = "Détail des sorts"
L["TIP_LOCK"] = "Verrouiller/déverrouiller la position"
L["TIP_REPORT"] = "Rapporter dans le chat"
L["TIP_RESET"] = "Réinitialiser les données"
L["TIP_CATEGORY"] = "Cliquer pour changer de catégorie"
L["TIP_TYPE"] = "Cliquer pour changer de type"
L["TIP_SESSION"] = "Cliquer pour changer de session"

-- Infobulles de survol
L["TIP_TOP_SPELLS"] = "Meilleurs sorts"
L["TIP_TOTAL"] = "Total"
L["TIP_OVERKILL"] = "Surplus de dégâts"
L["TIP_AVOIDABLE"] = "Dégâts évitables"
L["TIP_KILLING_BLOW"] = "Coup fatal"
L["TIP_CAST_BY"] = "Lancé par %s"
L["TIP_CLICK_BREAKDOWN"] = "Cliquer pour le détail des sorts"
L["TIP_LEFT_EXPAND"] = "Clic gauche : sorts en ligne"
L["TIP_RIGHT_WINDOW"] = "Clic droit : fenêtre de détail"

-- Font names
L["FONT_FRIZ"] = "Fritz Quadrata"
L["FONT_ARIAL"] = "Arial Narrow"
L["FONT_2002"] = "2002"
L["FONT_MORPHEUS"] = "Morpheus"
L["FONT_SKURRI"] = "Skurri"
L["FILTER_PLAYERS"] = "Filtrer..."

L["ADDON_PREFIX"] = "|cffe0115fTomo DM :|r "

L["CMD_HELP_RESETPOS"] = "  /tdm resetpos — replacer le récap de mort au centre"
L["CMD_POS_RESET"] = "Position du récap de mort réinitialisée."

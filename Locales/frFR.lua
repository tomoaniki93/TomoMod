-- =====================================
-- frFR.lua — Français
-- =====================================

TomoMod_RegisterLocale("frFR", {

    -- =====================
    -- CONFIG: Categories (ConfigUI.lua)
    -- =====================
    ["cat_general"]         = "Général",
    ["cat_unitframes"]      = "UnitFrames",
    ["cat_nameplates"]      = "Nameplates",
    ["cat_cd_resource"]     = "CD & Ressource",
    ["cat_qol"]             = "QOL / Auto",
    ["cat_profiles"]        = "Profils",

    -- =====================
    -- CONFIG: General Panel
    -- =====================
    ["section_about"]                   = "À propos",
    ["about_text"]                      = "|cff0cd29fTomoMod|r v2.1.4 par TomoAniki\nInterface légère avec QOL, UnitFrames et Nameplates.\nTapez /tm help pour la liste des commandes.",
    ["section_general"]                 = "Général",
    ["btn_reset_all"]                   = "Réinitialiser tout",
    ["info_reset_all"]                  = "Cela réinitialise TOUS les paramètres et recharge l'UI.",

    -- Minimap
    ["section_minimap"]                 = "Minimap",
    ["opt_minimap_enable"]              = "Activer la minimap personnalisée",
    ["opt_size"]                        = "Taille",
    ["opt_scale"]                       = "Échelle",
    ["opt_border"]                      = "Bordure",
    ["border_class"]                    = "Couleur de classe",
    ["border_black"]                    = "Noir",

    -- Info Panel
    ["section_info_panel"]              = "Info Panel",
    ["opt_enable"]                      = "Activer",
    ["opt_durability"]                  = "Durabilité (Gear)",
    ["opt_time"]                        = "Heure",
    ["opt_24h_format"]                  = "Format 24h",
    ["btn_reset_position"]              = "Reset Position",

    -- Cursor Ring
    ["section_cursor_ring"]             = "Cursor Ring",
    ["opt_class_color"]                 = "Couleur de classe",
    ["opt_anchor_tooltip_ring"]         = "Ancrer Tooltip + Afficher Ring",

    -- =====================
    -- CONFIG: UnitFrames Panel
    -- =====================
    -- Tabs
    ["tab_general"]                     = "Général",
    ["tab_player"]                      = "Player",
    ["tab_target"]                      = "Target",
    ["tab_tot"]                         = "ToT",
    ["tab_pet"]                         = "Pet",
    ["tab_focus"]                       = "Focus",

    -- Sub-labels
    ["sublabel_dimensions"]             = "— Dimensions —",
    ["sublabel_display"]                = "— Affichage —",
    ["sublabel_castbar"]                = "— Castbar —",
    ["sublabel_auras"]                  = "— Auras —",
    ["sublabel_element_offsets"]        = "— Position des éléments —",

    -- Unit display names
    ["unit_player"]                     = "Joueur",
    ["unit_target"]                     = "Cible",
    ["unit_tot"]                        = "Cible de cible",
    ["unit_pet"]                        = "Familier",
    ["unit_focus"]                      = "Focus",

    -- General tab
    ["section_general_settings"]        = "Paramètres Généraux",
    ["opt_uf_enable"]                   = "Activer les UnitFrames TomoMod",
    ["opt_hide_blizzard"]               = "Masquer les frames Blizzard",
    ["opt_global_font_size"]            = "Taille de police globale",
    ["btn_toggle_lock"]                 = "Toggle Lock/Unlock (/tm uf)",
    ["info_unlock_drag"]                = "Déverrouillez pour déplacer les frames. Les positions sont sauvegardées automatiquement.",

    -- Per-unit options
    ["opt_width"]                       = "Largeur",
    ["opt_health_height"]               = "Hauteur vie",
    ["opt_power_height"]                = "Hauteur ressource",
    ["opt_show_name"]                   = "Afficher le nom",
    ["opt_show_level"]                  = "Afficher le niveau",
    ["opt_show_health_text"]            = "Afficher le texte de vie",
    ["opt_health_format"]               = "Format vie",
    ["fmt_current"]                     = "Courant (25.3K)",
    ["fmt_percent"]                     = "Pourcentage (75%)",
    ["fmt_current_percent"]             = "Courant + % (25.3K | 75%)",
    ["fmt_current_max"]                 = "Courant / Max",
    ["opt_class_color_uf"]              = "Couleur de classe",
    ["opt_faction_color"]               = "Couleur de faction (PNJ)",
    ["opt_show_absorb"]                 = "Barre d'absorption",
    ["opt_show_threat"]                 = "Indicateur de menace",
    ["opt_show_leader_icon"]            = "Icône leader",
    ["opt_leader_icon_x"]               = "Leader icône X",
    ["opt_leader_icon_y"]               = "Leader icône Y",

    -- Castbar
    ["opt_castbar_enable"]              = "Activer castbar",
    ["opt_castbar_width"]               = "Largeur castbar",
    ["opt_castbar_height"]              = "Hauteur castbar",
    ["opt_castbar_show_icon"]           = "Afficher icône",
    ["opt_castbar_show_timer"]          = "Afficher timer",

    -- Auras
    ["opt_auras_enable"]                = "Activer les auras",
    ["opt_auras_max"]                   = "Nombre max d'auras",
    ["opt_auras_size"]                  = "Taille des icônes",
    ["opt_auras_type"]                  = "Type d'auras",
    ["aura_harmful"]                    = "Debuffs (nocifs)",
    ["aura_helpful"]                    = "Buffs (bénéfiques)",
    ["aura_all"]                        = "Tous",
    ["opt_auras_direction"]             = "Direction de croissance",
    ["aura_dir_right"]                  = "Vers la droite",
    ["aura_dir_left"]                   = "Vers la gauche",
    ["opt_auras_only_mine"]             = "Seulement mes auras",

    -- Element offsets
    ["elem_name"]                       = "Nom",
    ["elem_level"]                      = "Niveau",
    ["elem_health_text"]                = "Texte de vie",
    ["elem_power"]                      = "Barre de ressource",
    ["elem_castbar"]                    = "Castbar",
    ["elem_auras"]                      = "Auras",

    -- =====================
    -- CONFIG: Nameplates Panel
    -- =====================
    ["section_np_general"]              = "Paramètres Généraux",
    ["opt_np_enable"]                   = "Activer les Nameplates TomoMod",
    ["info_np_description"]             = "Remplace les nameplates Blizzard par un style minimaliste personnalisable.",
    ["section_dimensions"]              = "Dimensions",
    ["opt_np_name_font_size"]           = "Taille police nom",

    -- Display
    ["section_display"]                 = "Affichage",
    ["opt_np_show_classification"]      = "Afficher classification (élite, rare, boss)",
    ["opt_np_class_colors"]             = "Couleurs de classe (joueurs)",

    -- Castbar
    ["section_castbar"]                 = "Castbar",
    ["opt_np_show_castbar"]             = "Afficher la castbar",
    ["opt_np_castbar_height"]           = "Hauteur castbar",

    -- Auras
    ["section_auras"]                   = "Auras",
    ["opt_np_show_auras"]               = "Afficher les auras",
    ["opt_np_aura_size"]                = "Taille des icônes",
    ["opt_np_max_auras"]                = "Nombre max",
    ["opt_np_only_my_debuffs"]          = "Seulement mes debuffs",

    -- Transparency
    ["section_transparency"]            = "Transparence",
    ["opt_np_selected_alpha"]           = "Alpha sélectionné",
    ["opt_np_unselected_alpha"]         = "Alpha non-sélectionné",

    -- Stacking
    ["section_stacking"]                = "Empilement",
    ["opt_np_overlap"]                  = "Chevauchement vertical",
    ["opt_np_top_inset"]                = "Limite haute écran",

    -- Colors
    ["section_colors"]                  = "Couleurs",
    ["color_hostile"]                   = "Hostile (Ennemi)",
    ["color_neutral"]                   = "Neutre",
    ["color_friendly"]                  = "Amical",
    ["color_tapped"]                    = "Tagué (tapped)",

    -- Classification colors
    ["section_classification_colors"]   = "Couleurs par Classification",
    ["opt_np_use_classification"]       = "Couleurs par type d'ennemi",
    ["color_boss"]                      = "Boss",
    ["color_elite"]                     = "Élite / Mini-boss",
    ["color_rare"]                      = "Rare",
    ["color_normal"]                    = "Normal",
    ["color_trivial"]                   = "Trivial",

    -- Tank mode
    ["section_tank_mode"]               = "Mode Tank",
    ["opt_np_tank_mode"]                = "Activer le mode Tank (couleur par menace)",
    ["color_no_threat"]                 = "Pas de menace",
    ["color_low_threat"]                = "Menace faible",
    ["color_has_threat"]                = "Menace tenue",

    -- NP health format
    ["np_fmt_percent"]                  = "Pourcentage (75%)",
    ["np_fmt_current"]                  = "Courant (25.3K)",
    ["np_fmt_current_percent"]          = "Courant + %",

    -- Reset
    ["btn_reset_nameplates"]            = "Réinitialiser Nameplates",

    -- =====================
    -- CONFIG: CD & Resource Panel
    -- =====================
    -- Resource colors
    ["section_resource_colors"]         = "Couleurs des Ressources",
    ["res_runes_ready"]                 = "Runes (prêtes)",
    ["res_runes_cd"]                    = "Runes (cooldown)",
    -- NOTE: Most resource names (Mana, Rage, Energy, etc.) are the same in French

    -- Cooldown Manager
    ["section_cdm"]                     = "Cooldown Manager",
    ["opt_cdm_enable"]                  = "Activer le Cooldown Manager",
    ["info_cdm_description"]            = "Reskin des icônes du CooldownManager Blizzard : bordures 1px, overlay de classe quand actif, texte de CD personnalisé, alignement centré des buffs. Placement via Edit Mode Blizzard.",
    ["opt_cdm_show_hotkeys"]            = "Afficher les hotkeys",
    ["opt_cdm_combat_alpha"]            = "Modifier l'opacité (combat / cible)",
    ["opt_cdm_alpha_combat"]            = "Alpha en combat",
    ["opt_cdm_alpha_target"]            = "Alpha avec cible (hors combat)",
    ["opt_cdm_alpha_ooc"]               = "Alpha hors combat",
    ["info_cdm_editmode"]               = "Le placement des barres se fait via le Edit Mode de Blizzard (Échap → Edit Mode).",

    -- Resource Bars
    ["section_resource_bars"]           = "Barres de Ressources",
    ["opt_rb_enable"]                   = "Activer les barres de ressources",
    ["info_rb_description"]             = "Affiche les ressources de classe (Mana, Rage, Energy, Combo Points, Runes, etc.) avec support adaptatif pour les Druides.",
    ["section_visibility"]              = "Visibilité",
    ["opt_rb_visibility_mode"]          = "Mode de visibilité",
    ["vis_always"]                      = "Toujours visible",
    ["vis_combat"]                      = "En combat seulement",
    ["vis_target"]                      = "Combat ou cible",
    ["vis_hidden"]                      = "Cachée",
    ["opt_rb_combat_alpha"]             = "Alpha en combat",
    ["opt_rb_ooc_alpha"]                = "Alpha hors combat",
    ["opt_rb_width"]                    = "Largeur",
    ["opt_rb_primary_height"]           = "Hauteur barre primaire",
    ["opt_rb_secondary_height"]         = "Hauteur barre secondaire",
    ["opt_rb_global_scale"]             = "Échelle globale",
    ["opt_rb_sync_width"]               = "Synchroniser la largeur avec Essential Cooldowns",
    ["btn_sync_now"]                    = "Sync maintenant",
    ["info_rb_sync"]                    = "Aligne la largeur avec le EssentialCooldownViewer du Cooldown Manager Blizzard.",

    -- Text & Font
    ["section_text_font"]               = "Texte & Police",
    ["opt_rb_show_text"]                = "Afficher le texte sur les barres",
    ["opt_rb_text_align"]               = "Alignement du texte",
    ["align_left"]                      = "Gauche",
    ["align_center"]                    = "Centre",
    ["align_right"]                     = "Droite",
    ["opt_rb_font_size"]                = "Taille de police",
    ["opt_rb_font"]                     = "Police",
    ["font_default_wow"]                = "Défaut WoW",

    -- Position
    ["section_position"]                = "Position",
    ["info_rb_position"]                = "Utilisez /tm uf pour déverrouiller et déplacer les barres. La position est sauvegardée automatiquement.",
    ["info_rb_druid"]                   = "Les barres s'adaptent automatiquement à votre classe et spé.\nDruide : la ressource change selon la forme (Ours → Rage, Chat → Energy, Moonkin → Astral Power).",

    -- =====================
    -- CONFIG: QOL Panel
    -- =====================
    -- Cinematic Skip
    ["section_cinematic"]               = "Cinematic Skip",
    ["opt_cinematic_auto_skip"]         = "Skip automatique après 1ère vue",
    ["info_cinematic_viewed"]           = "Cinématiques déjà vues: %s\nL'historique est partagé entre personnages.",
    ["btn_clear_history"]               = "Effacer l'historique",

    -- Auto Quest
    ["section_auto_quest"]              = "Auto Quest",
    ["opt_quest_auto_accept"]           = "Auto-accepter les quêtes",
    ["opt_quest_auto_turnin"]           = "Auto-compléter les quêtes",
    ["opt_quest_auto_gossip"]           = "Auto-sélectionner les dialogues",
    ["info_quest_shift"]                = "Maintenez SHIFT pour désactiver temporairement.\nLes quêtes avec choix multiples ne sont pas auto-complétées.",

    -- Automatisations
    ["section_automations"]             = "Automatisations",
    ["opt_hide_blizzard_castbar"]       = "Cacher la barre de cast Blizzard",

    -- Auto Accept Invite
    ["sublabel_auto_accept_invite"]     = "— Auto Accept Invite —",
    ["opt_accept_friends"]              = "Accepter des amis",
    ["opt_accept_guild"]                = "Accepter de la guilde",

    -- Auto Summon
    ["sublabel_auto_summon"]            = "— Auto Summon —",
    ["opt_summon_delay"]                = "Délai (secondes)",

    -- Auto Fill Delete
    ["sublabel_auto_fill_delete"]       = "— Auto Fill Delete —",
    ["opt_focus_ok_button"]             = "Focus sur OK après remplissage",

    -- Mythic+ Keys
    ["section_mythic_keys"]             = "Mythic+ Keys",
    ["opt_keys_enable_tracker"]         = "Activer le tracker",
    ["opt_keys_mini_frame"]             = "Mini-frame sur l'UI M+",
    ["opt_keys_auto_refresh"]           = "Actualisation automatique",

    -- SkyRide
    ["section_skyride"]                 = "SkyRide",
    ["opt_skyride_enable"]              = "Activer (affichage en vol)",
    ["opt_skyride_bar_height"]          = "Hauteur barre",
    ["opt_font_size"]                   = "Taille police",
    ["btn_reset_skyride"]               = "Reset Position SkyRide",

    -- =====================
    -- CONFIG: Profiles Panel
    -- =====================
    ["section_profile_mgmt"]            = "Gestion des Profils",
    ["info_profiles"]                   = "Réinitialisez des modules individuellement ou exportez/importez vos paramètres.\nL'export copie vos settings dans le presse-papier (nécessite LibSerialize + LibDeflate).",
    ["section_reset_module"]            = "Réinitialiser un module",
    ["btn_reset_prefix"]                = "Reset: ",
    ["btn_reset_all_reload"]            = "⚠ TOUT Réinitialiser + Reload",

    -- =====================
    -- PRINT MESSAGES: Core
    -- =====================
    ["msg_db_reset"]                    = "Base de données réinitialisée",
    ["msg_module_reset"]                = "Module '%s' réinitialisé",
    ["msg_db_not_init"]                 = "Base de données non initialisée",
    ["msg_loaded"]                      = "v2.0 chargé — %s pour config",
    ["msg_help_title"]                  = "v2.0 — Commandes:",
    ["msg_help_open"]                   = "Ouvrir la configuration",
    ["msg_help_reset"]                  = "Réinitialiser tout + reload",
    ["msg_help_uf"]                     = "Toggle Lock/Unlock UnitFrames + Resources",
    ["msg_help_uf_reset"]               = "Réinitialiser UnitFrames",
    ["msg_help_rb"]                     = "Toggle Lock/Unlock Resource Bars",
    ["msg_help_rb_sync"]                = "Sync largeur avec Essential Cooldowns",
    ["msg_help_np"]                     = "Toggle Nameplates on/off",
    ["msg_help_minimap"]                = "Reset minimap",
    ["msg_help_panel"]                  = "Reset info panel",
    ["msg_help_cursor"]                 = "Reset cursor ring",
    ["msg_help_clearcinema"]            = "Clear cinematic history",
    ["msg_help_sr"]                     = "Toggle SkyRide + Anchors lock",
    ["msg_help_key"]                    = "Open Mythic+ Keys",
    ["msg_help_help"]                   = "Cette aide",

    -- =====================
    -- PRINT MESSAGES: Modules
    -- =====================
    -- CDM
    ["msg_cdm_status"]                  = "Activé",
    ["msg_cdm_disabled"]                = "Désactivé",

    -- Nameplates
    ["msg_np_enabled"]                  = "Activées",
    ["msg_np_disabled"]                 = "Désactivées",

    -- UnitFrames
    ["msg_uf_locked"]                   = "Verrouillé",
    ["msg_uf_unlocked"]                 = "Déverrouillé — Glissez pour repositionner",
    ["msg_uf_initialized"]              = "Initialisé — /tm uf pour lock/unlock",
    ["msg_uf_enabled"]                  = "activé (reload nécessaire)",
    ["msg_uf_disabled"]                 = "désactivé (reload nécessaire)",
    ["msg_uf_position_reset"]           = "position réinitialisée",

    -- ResourceBars
    ["msg_rb_width_synced"]             = "Largeur synchronisée (%dpx)",
    ["msg_rb_locked"]                   = "Verrouillé",
    ["msg_rb_unlocked"]                 = "Déverrouillé — Glissez pour repositionner",
    ["msg_rb_position_reset"]           = "Position des barres de ressources réinitialisée",

    -- SkyRide
    ["msg_sr_pos_saved"]                = "Position SkyRide sauvegardée",
    ["msg_sr_locked"]                   = "SkyRide verrouillée",
    ["msg_sr_unlock"]                   = "Mode déplacement SkyRide activé - Cliquez et glissez",
    ["msg_sr_pos_reset"]                = "Position SkyRide réinitialisée",
    ["msg_sr_db_not_init"]              = "TomoModDB non initialisée",
    ["msg_sr_initialized"]              = "Module SkyRide initialisé",

    -- FrameAnchors
    ["anchor_alert"]                    = "Alertes",
    ["anchor_loot"]                     = "Loot",
    ["msg_anchors_locked"]              = "Verrouillés",
    ["msg_anchors_unlocked"]            = "Déverrouillés — déplacez les ancres",

    -- AutoVendorRepair
    ["msg_avr_sold"]                    = " Items gris vendus pour |cffffff00%s|r",
    ["msg_avr_repaired"]                = " Équipement réparé pour |cffffff00%s|r",

    -- AutoFillDelete
    ["msg_afd_filled"]                  = "Texte 'DELETE' auto-rempli - Cliquez OK pour confirmer",
    ["msg_afd_db_not_init"]             = "TomoModDB non initialisée",
    ["msg_afd_initialized"]             = "Module AutoFillDelete initialisé",
    ["msg_afd_enabled"]                 = "Auto-fill DELETE activé",
    ["msg_afd_disabled"]                = "Auto-fill DELETE désactivé (hook reste actif)",

    -- HideCastBar
    ["msg_hcb_db_not_init"]             = "TomoModDB non initialisée",
    ["msg_hcb_initialized"]             = "Module HideCastBar initialisé",
    ["msg_hcb_hidden"]                  = "Barre de cast cachée",
    ["msg_hcb_shown"]                   = "Barre de cast affichée",

    -- AutoAcceptInvite
    ["msg_aai_accepted"]                = "Invitation acceptée de ",
    ["msg_aai_ignored"]                 = "Invitation ignorée de ",
    ["msg_aai_enabled"]                 = "Auto-accept invitations activé",
    ["msg_aai_disabled"]                = "Auto-accept invitations désactivé",

    -- CinematicSkip
    ["msg_cin_skipped"]                 = "Cinématique skippée (déjà vue)",
    ["msg_vid_skipped"]                 = "Vidéo skippée (déjà vue)",
    ["msg_vid_id_skipped"]              = "Vidéo #%d skippée",
    ["msg_cin_cleared"]                 = "Historique des cinématiques effacé",

    -- AutoSummon
    ["msg_sum_accepted"]                = "Summon accepté de %s vers %s (%s)",
    ["msg_sum_ignored"]                 = "Summon ignoré de %s (non fiable)",
    ["msg_sum_enabled"]                 = "Auto-summon activé",
    ["msg_sum_disabled"]                = "Auto-summon désactivé",
    ["msg_sum_manual"]                  = "Summon accepté manuellement",
    ["msg_sum_no_pending"]              = "Aucun summon en attente",

    -- MythicKeys
    ["msg_keys_no_key"]                 = "Aucune clé à envoyer.",
    ["msg_keys_not_in_group"]           = "Tu dois être en groupe.",
    ["msg_keys_reload"]                 = "Changement appliqué au prochain /reload.",
    ["mk_not_in_group"]                 = "Tu n'es pas en groupe.",
    ["mk_not_in_group_short"]           = "Pas en groupe.",
    ["mk_title"]                        = "TM — Mythic Keys",
    ["mk_btn_send"]                     = "Envoyer chat",
    ["mk_btn_refresh"]                  = "Refresh",

    -- =====================
    -- PRINT MESSAGES: Config Panels
    -- =====================
    ["msg_np_reset"]                    = "Nameplates réinitialisées (reload recommandé)",
    ["msg_uf_toggle"]                   = "UnitFrames %s (reload)",
    ["msg_profile_reset"]               = "%s réinitialisé",

    -- =====================
    -- INFO PANEL (Minimap)
    -- =====================
    ["time_server"]                     = "Serveur",
    ["time_local"]                      = "Locale",
    ["time_tooltip_title"]              = "Heure (%s - %s)",
    ["time_tooltip_left_click"]         = "|cff0cd29fClic gauche:|r Calendrier",
    ["time_tooltip_right_click"]        = "|cff0cd29fClic droit:|r Serveur / Locale",
    ["time_tooltip_shift_right"]        = "|cff0cd29fShift + Clic droit:|r 12h / 24h",
    ["time_format_msg"]                 = "Format: %s",
    ["time_mode_msg"]                   = "Heure: %s",

    -- =====================
    -- ENABLED / DISABLED (generic)
    -- =====================
    ["enabled"]                         = "Activé",
    ["disabled"]                        = "Désactivé",

    -- Static Popups
    ["popup_reset_text"]                = "|cff0cd29fTomoMod|r\n\nRéinitialiser TOUS les paramètres ?\nCela rechargera votre UI.",
    ["popup_confirm"]                   = "Confirmer",
    ["popup_cancel"]                    = "Annuler",

    -- FPS element
    ["label_fps"]                       = "Fps",
})

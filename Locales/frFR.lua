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
    ["cat_qol"]             = "Qualité de vie",
    ["cat_profiles"]        = "Profils",

    -- =====================
    -- CONFIG: General Panel
    -- =====================
    ["section_about"]                   = "À propos",
    ["about_text"]                      = "|cff0cd29fTomoMod|r v2.4.3 par TomoAniki\nInterface légère avec Qualité de vie, UnitFrames et Nameplates.\nTapez /tm help pour la liste des commandes.",
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
    ["section_info_panel"]              = "Panneau d'information",
    ["opt_enable"]                      = "Activer",
    ["opt_durability"]                  = "Durabilité (Équipement)",
    ["opt_time"]                        = "Heure",
    ["opt_24h_format"]                  = "Format 24h",
    ["opt_show_coords"]                 = "Afficher les coordonnées",
    ["btn_reset_position"]              = "Réinitialiser la position",

    -- Cursor Ring
    ["section_cursor_ring"]             = "Anneau du curseur",
    ["opt_class_color"]                 = "Couleur de classe",
    ["opt_anchor_tooltip_ring"]         = "Ancrer l'infobulle au curseur",

    -- =====================
    -- CONFIG: UnitFrames Panel
    -- =====================
    -- Tabs
    ["tab_general"]                     = "Général",
    ["tab_player"]                      = "Joueur",
    ["tab_target"]                      = "Cible",
    ["tab_tot"]                         = "CdC",
    ["tab_pet"]                         = "Familier",
    ["tab_focus"]                       = "Focus",
    ["tab_colors"]                      = "Couleurs",

    -- Sub-tabs (Player, Target, Focus)
    ["subtab_dimensions"]               = "Dimensions",
    ["subtab_display"]                  = "Affichage",
    ["subtab_auras"]                    = "Auras",
    ["subtab_positioning"]              = "Position",

    -- Sub-labels
    ["sublabel_dimensions"]             = "— Dimensions —",
    ["sublabel_display"]                = "— Affichage —",
    ["sublabel_castbar"]                = "— Barre de sort —",
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
    ["sublabel_font"]                   = "— Police —",
    ["opt_font_family"]                 = "Police de texte",

    -- Castbar colors
    ["section_castbar_colors"]          = "Couleurs Castbar",
    ["info_castbar_colors"]             = "Personnalisez les couleurs des barres de cast pour les sorts interruptibles, non-interruptibles et interrompus.",
    ["opt_castbar_color"]               = "Sort interruptible",
    ["opt_castbar_ni_color"]            = "Sort non-interruptible",
    ["opt_castbar_interrupt_color"]     = "Sort interrompu",
    ["info_castbar_colors_reload"]      = "Les couleurs s'appliquent aux nouveaux casts. /reload pour un effet complet.",
    ["btn_toggle_lock"]                 = "Verrouiller/Déverrouiller (/tm uf)",
    ["info_unlock_drag"]                = "Déverrouillez pour déplacer les frames. Les positions sont sauvegardées automatiquement.",

    -- Per-unit options
    ["opt_width"]                       = "Largeur",
    ["opt_health_height"]               = "Hauteur vie",
    ["opt_power_height"]                = "Hauteur ressource",
    ["opt_show_name"]                   = "Afficher le nom",
    ["opt_name_truncate"]               = "Tronquer les noms longs",
    ["opt_name_truncate_length"]        = "Longueur max du nom",
    ["opt_show_level"]                  = "Afficher le niveau",
    ["opt_show_health_text"]            = "Afficher le texte de vie",
    ["opt_health_format"]               = "Format vie",
    ["fmt_current"]                     = "Courant (25.3K)",
    ["fmt_percent"]                     = "Pourcentage (75%)",
    ["fmt_current_percent"]             = "Courant + % (25.3K | 75%)",
    ["fmt_current_max"]                 = "Courant / Max",
    ["opt_class_color_uf"]              = "Couleur de classe",
    ["opt_faction_color"]               = "Couleur de faction (PNJ)",
    ["opt_use_nameplate_colors"]        = "Couleurs Nameplates (type de PNJ)",
    ["opt_show_absorb"]                 = "Barre d'absorption",
    ["opt_show_threat"]                 = "Indicateur de menace (contour)",
    ["section_threat_text"]             = "Texte % de Menace",
    ["opt_threat_text_enable"]          = "Afficher le % de menace sur la cible",
    ["opt_threat_text_font_size"]       = "Taille de la police",
    ["opt_threat_text_offset_x"]        = "Décalage X",
    ["opt_threat_text_offset_y"]        = "Décalage Y",
    ["info_threat_text"]                = "Vert = tank (avance sur le 2e), jaune = proche, rouge = aggro perdu",
    ["opt_show_leader_icon"]            = "Icône de Chef de groupe",
    ["opt_leader_icon_x"]               = "Icône de Chef de groupe X",
    ["opt_leader_icon_y"]               = "Icône de Chef de groupe Y",
    ["opt_raid_icon_x"]                 = "Marqueur raid X",
    ["opt_raid_icon_y"]                 = "Marqueur raid Y",

    -- Castbar
    ["opt_castbar_enable"]              = "Activer castbar",
    ["opt_castbar_width"]               = "Largeur castbar",
    ["opt_castbar_height"]              = "Hauteur castbar",
    ["opt_castbar_show_icon"]           = "Afficher icône",
    ["opt_castbar_show_timer"]          = "Afficher le timer",
    ["info_castbar_drag"]               = "Position: /tm sr pour déverrouiller et déplacer la castbar.",
    ["btn_reset_castbar_position"]      = "Réinitialiser la position de la castbar",
    ["opt_castbar_show_latency"]        = "Afficher la latence",

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
    -- Nameplate tabs
    ["tab_np_auras"]                    = "Auras",
    ["tab_np_advanced"]                 = "Avancé",
    ["info_np_colors_custom"]           = "Chaque couleur peut être personnalisée selon vos envies en cliquant sur le carré de couleur.",

    ["section_np_general"]              = "Paramètres Généraux",
    ["opt_np_enable"]                   = "Activer les Nameplates TomoMod",
    ["info_np_description"]             = "Remplace les nameplates Blizzard par un style minimaliste personnalisable.",
    ["section_dimensions"]              = "Dimensions",
    ["opt_np_name_font_size"]           = "Taille police nom",

    -- Display
    ["section_display"]                 = "Affichage",
    ["opt_np_show_classification"]      = "Afficher classification (élite, rare, boss)",
    ["opt_np_show_absorb"]               = "Afficher la barre d'absorption",
    ["opt_np_class_colors"]             = "Couleurs de classe (joueurs)",

    -- Raid Marker
    ["section_raid_marker"]             = "Marqueur de raid",
    ["opt_np_raid_icon_anchor"]         = "Position de l'icône",
    ["opt_np_raid_icon_x"]              = "Décalage X",
    ["opt_np_raid_icon_y"]              = "Décalage Y",
    ["opt_np_raid_icon_size"]           = "Taille de l'icône",

    -- Castbar
    ["section_castbar"]                 = "Barre de sort",
    ["opt_np_show_castbar"]             = "Afficher la barre de sort",
    ["opt_np_castbar_height"]           = "Hauteur de la barre de sort",
    ["color_castbar"]                   = "Barre de sort (interruptible)",
    ["color_castbar_uninterruptible"]   = "Barre de sort (non-interruptible)",

    -- Auras
    ["section_auras"]                   = "Auras",
    ["opt_np_show_auras"]               = "Afficher les auras",
    ["opt_np_aura_size"]                = "Taille des icônes",
    ["opt_np_max_auras"]                = "Nombre max",
    ["opt_np_only_my_debuffs"]          = "Seulement mes debuffs",

    -- Enemy Buffs
    ["section_enemy_buffs"]              = "Buffs ennemis",
    ["sublabel_enemy_buffs"]             = "— Buffs ennemis —",
    ["opt_enemy_buffs_enable"]           = "Afficher les buffs ennemis",
    ["opt_enemy_buffs_max"]              = "Nombre max de buffs",
    ["opt_enemy_buffs_size"]             = "Taille des icônes",
    ["info_enemy_buffs"]                 = "Affiche les buffs actifs (Enrage, boucliers...) sur les unités hostiles. Les icônes apparaissent en haut à droite, empilées vers le haut.",
    ["opt_np_show_enemy_buffs"]          = "Afficher les buffs ennemis",
    ["opt_np_enemy_buff_size"]           = "Taille des icônes buff",
    ["opt_np_max_enemy_buffs"]           = "Nombre max de buffs ennemis",
    ["opt_np_enemy_buff_y_offset"]       = "Décalage Y des buffs ennemis",

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
    ["color_focus"]                     = "Cible de focus",

    -- Couleurs par type de PNJ (style Ellesmere)
    ["section_npc_type_colors"]         = "Couleurs par Type de PNJ",
    ["color_caster"]                    = "Caster (lanceur de sorts)",
    ["color_miniboss"]                  = "Mini-boss (élite + niveau supérieur)",
    ["color_enemy_in_combat"]           = "Ennemi (par défaut)",
    ["info_np_darken_ooc"]              = "Les ennemis hors-combat sont automatiquement assombris.",

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
    ["color_dps_has_aggro"]             = "DPS/Heal a l'aggro",
    ["color_dps_near_aggro"]            = "DPS/Heal proche de l'aggro",

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
    -- CD & Resource tabs
    ["tab_cdm"]                         = "Cooldowns",
    ["tab_resource_bars"]               = "Barres de Ressource",
    ["tab_text_position"]               = "Texte & Position",
    ["tab_rb_colors"]                   = "Couleurs",
    ["info_rb_colors_custom"]           = "Chaque couleur peut être personnalisée selon vos envies en cliquant sur le carré de couleur.",

    ["section_cdm"]                     = "Cooldown Manager",
    ["opt_cdm_enable"]                  = "Activer le Cooldown Manager",
    ["info_cdm_description"]            = "Reskin des icônes du CooldownManager Blizzard : bordures arrondies, overlay de classe sur les auras actives, couleurs de balayage personnalisées, atténuation utilitaire, disposition centrée. Placement via Edit Mode Blizzard.",
    ["opt_cdm_show_hotkeys"]            = "Afficher les hotkeys",
    ["opt_cdm_combat_alpha"]            = "Modifier l'opacité (combat / cible)",
    ["opt_cdm_alpha_combat"]            = "Alpha en combat",
    ["opt_cdm_alpha_target"]            = "Alpha avec cible (hors combat)",
    ["opt_cdm_alpha_ooc"]               = "Alpha hors combat",
    ["section_cdm_overlay"]             = "Overlay et bordures",
    ["opt_cdm_custom_overlay"]          = "Couleur d'overlay personnalisée",
    ["opt_cdm_overlay_color"]           = "Couleur de l'overlay",
    ["opt_cdm_custom_swipe"]            = "Couleur de balayage actif personnalisée",
    ["opt_cdm_swipe_color"]             = "Couleur du balayage",
    ["opt_cdm_swipe_alpha"]             = "Opacité du balayage",
    ["section_cdm_utility"]             = "Utilitaire",
    ["opt_cdm_dim_utility"]             = "Atténuer les icônes utilitaires hors CD",
    ["opt_cdm_dim_opacity"]             = "Opacité d'atténuation",
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
    -- QOL tabs
    ["tab_qol_cinematic"]               = "Cinématique",
    ["tab_qol_auto_quest"]              = "Auto Quêtes",
    ["tab_qol_automations"]             = "Automatisation",
    ["tab_qol_mythic_keys"]             = "Clés M+",
    ["tab_qol_skyride"]                 = "SkyRide",
    ["tab_qol_action_bars"]             = "Barres d'action",
    ["section_action_bars"]             = "Skin barres d'action",
    ["cat_action_bars"]                 = "Barres d'action",
    ["opt_abs_enable"]                  = "Activer le skin des barres d'action",
    ["opt_abs_class_color"]             = "Couleur de classe pour les bordures",
    ["opt_abs_shift_reveal"]            = "Maintenir Shift pour révéler les barres masquées",
    ["sublabel_bar_opacity"]            = "— Opacité par barre —",
    ["opt_abs_select_bar"]              = "Sélectionner la barre",
    ["opt_abs_opacity"]                 = "Opacité",
    ["btn_abs_apply_all_opacity"]       = "Appliquer à toutes les barres",
    ["msg_abs_all_opacity"]             = "Opacité définie à %d%% sur toutes les barres",
    ["sublabel_bar_combat"]             = "— Visibilité en combat —",
    ["opt_abs_combat_show"]             = "Afficher uniquement en combat",

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

    -- Objective Tracker Skin
    ["tab_qol_obj_tracker"]             = "Objectifs",
    ["section_obj_tracker"]             = "Affichage du Suivi d'Objectifs",
    ["opt_obj_tracker_enable"]          = "Activer l'affichage du Suivi d'Objectifs",
    ["opt_obj_tracker_bg_alpha"]        = "Opacité du fond",
    ["opt_obj_tracker_border"]          = "Afficher la bordure",
    ["opt_obj_tracker_hide_empty"]      = "Masquer si vide",
    ["opt_obj_tracker_header_size"]     = "Taille police en-tête",
    ["opt_obj_tracker_cat_size"]        = "Taille police catégorie",
    ["opt_obj_tracker_quest_size"]      = "Taille police titre quête",
    ["opt_obj_tracker_obj_size"]        = "Taille police objectif",
    ["opt_obj_tracker_max_quests"]       = "Quêtes affichées max (0 = illimité)",
    ["ot_overflow_text"]                 = "%d quête(s) masquée(s)...",
    ["info_obj_tracker"]                = "Applique un affichage sombre au Suivi d'Objectifs Blizzard avec un panneau, des polices personnalisées et des catégories colorées.",
    ["ot_header_title"]                 = "OBJECTIFS",
    ["ot_header_options"]               = "Options",

    -- Automatisations
    ["section_automations"]             = "Automatisations",
    ["opt_hide_blizzard_castbar"]       = "Cacher la barre de cast Blizzard",

    -- Auto Accept Invite
    ["sublabel_auto_accept_invite"]     = "— Auto Accept Invite —",
    ["sublabel_auto_skip_role"]         = "— Auto Skip Role Check —",
    ["sublabel_tooltip_ids"]            = "— Tooltip IDs —",
    ["sublabel_combat_res_tracker"]     = "— Combat Res Tracker —",
    ["opt_cr_show_rating"]              = "Afficher le score M+",
    ["opt_show_messages"]               = "Afficher les messages chat",
    ["opt_tid_spell"]                   = "ID Sort / Aura",
    ["opt_tid_item"]                    = "ID Objet",
    ["opt_tid_npc"]                     = "ID PNJ",
    ["opt_tid_quest"]                   = "ID Quête",
    ["opt_tid_mount"]                   = "ID Monture",
    ["opt_tid_currency"]                = "ID Devise",
    ["opt_tid_achievement"]             = "ID Haut fait",
    ["opt_accept_friends"]              = "Accepter des amis",
    ["opt_accept_guild"]                = "Accepter de la guilde",

    -- Auto Summon
    ["sublabel_auto_summon"]            = "— Auto Summon —",
    ["opt_summon_delay"]                = "Délai (secondes)",

    -- Auto Fill Delete
    ["sublabel_auto_fill_delete"]       = "— Auto EFFACER —",
    ["opt_focus_ok_button"]             = "Focus sur OK après remplissage",

    -- Mythic+ Keys
    ["section_mythic_keys"]             = "Clés Mythic+",
    ["opt_keys_enable_tracker"]         = "Activer le tracker",
    ["opt_keys_mini_frame"]             = "Mini-frame sur l'UI M+",
    ["opt_keys_auto_refresh"]           = "Actualisation automatique",

    -- SkyRide
    ["section_skyride"]                 = "Vol Dynamique",
    ["opt_skyride_enable"]              = "Activer (affichage en vol)",
    ["section_skyride_dims"]            = "Dimensions",
    ["opt_skyride_bar_height"]          = "Hauteur barre vitesse",
    ["opt_skyride_charge_height"]       = "Hauteur cases charge",
    ["opt_skyride_charge_gap"]          = "Espace entre segments",
    ["section_skyride_text"]            = "Texte",
    ["opt_skyride_show_speed_text"]     = "Afficher le % de vitesse",
    ["opt_skyride_speed_font_size"]     = "Taille police vitesse",
    ["opt_skyride_show_charge_timer"]   = "Afficher le timer de charge",
    ["opt_skyride_charge_font_size"]    = "Taille police timer charge",
    ["btn_reset_skyride"]               = "Réinitialiser la position du Vol",

    -- =====================
    -- CONFIG: QOL — CVar Optimizer
    -- =====================
    ["tab_qol_cvar_opt"]                = "Perf CVars",
    ["section_cvar_optimizer"]          = "Optimisation CVars",
    ["info_cvar_optimizer"]             = "Applique les réglages graphiques/performance recommandés. Vos valeurs actuelles sont sauvegardées et restaurables à tout moment.",
    ["btn_cvar_apply_all"]              = ">> Tout appliquer",
    ["btn_cvar_revert_all"]             = "<< Tout restaurer",
    ["btn_cvar_apply"]                  = "Appliquer",
    ["btn_cvar_revert"]                 = "Restaurer",
    -- Catégories
    ["opt_cat_render"]                  = "Rendu & Affichage",
    ["opt_cat_graphics"]                = "Qualité Graphique",
    ["opt_cat_detail"]                  = "Distance de vue & Détails",
    ["opt_cat_advanced"]                = "Avancé",
    ["opt_cat_fps"]                     = "Limites FPS",
    ["opt_cat_post"]                    = "Post-traitement",
    -- Labels CVars
    ["opt_cvar_render_scale"]           = "Échelle de rendu",
    ["opt_cvar_vsync"]                  = "VSync",
    ["opt_cvar_msaa"]                   = "Multisampling (MSAA)",
    ["opt_cvar_low_latency"]            = "Mode basse latence",
    ["opt_cvar_anti_aliasing"]          = "Anti-aliasing",
    ["opt_cvar_shadow"]                 = "Qualité des ombres",
    ["opt_cvar_ssao"]                   = "SSAO",
    ["opt_cvar_depth"]                  = "Effets de profondeur",
    ["opt_cvar_compute"]                = "Effets calculés",
    ["opt_cvar_particle"]               = "Densité de particules",
    ["opt_cvar_liquid"]                 = "Détail des liquides",
    ["opt_cvar_spell_density"]          = "Densité des sorts",
    ["opt_cvar_projected"]              = "Textures projetées",
    ["opt_cvar_outline"]                = "Mode contour",
    ["opt_cvar_texture_res"]            = "Résolution des textures",
    ["opt_cvar_view_distance"]          = "Distance de vue",
    ["opt_cvar_env_detail"]             = "Détail de l'environnement",
    ["opt_cvar_ground"]                 = "Végétation au sol",
    ["opt_cvar_gfx_api"]                = "API graphique",
    ["opt_cvar_triple_buffering"]       = "Triple buffering",
    ["opt_cvar_texture_filtering"]      = "Filtrage de texture",
    ["opt_cvar_rt_shadows"]             = "Ombres ray-tracées",
    ["opt_cvar_resample_quality"]       = "Qualité de rééchantillonnage",
    ["opt_cvar_physics"]                = "Niveau de physique",
    ["opt_cvar_target_fps"]             = "FPS cible",
    ["opt_cvar_bg_fps_enable"]          = "Limite FPS en arrière-plan",
    ["opt_cvar_bg_fps"]                 = "Valeur FPS arrière-plan",
    ["opt_cvar_resample_sharpness"]     = "Netteté",
    ["opt_cvar_camera_shake"]           = "Tremblement de caméra",
    -- Messages
    ["msg_cvar_applied"]                = "CVars appliqués",
    ["msg_cvar_reverted"]               = "CVars restaurés",
    ["msg_cvar_no_backup"]              = "Aucune sauvegarde trouvée — appliquez d'abord.",
    ["tab_qol_leveling"]                = "Leveling",
    ["section_leveling_bar"]            = "Barre de Leveling",
    ["opt_leveling_enable"]             = "Activer la barre de leveling",
    ["opt_leveling_width"]              = "Largeur de la barre",
    ["opt_leveling_height"]             = "Hauteur de la barre",
    ["btn_reset_leveling_pos"]          = "Réinitialiser la position",
    ["leveling_bar_title"]              = "Barre de Leveling",
    ["leveling_level"]                  = "Niveau",
    ["leveling_progress"]               = "Progression :",
    ["leveling_rested"]                 = "Reposé",
    ["leveling_last_quest"]             = "Dernière quête :",
    ["leveling_ttl"]                    = "Temps pour level :",
    ["leveling_drag_hint"]              = "/tm sr pour débloquer & déplacer",

    -- =====================
    -- CONFIG: Profiles Panel (3 Onglets)
    -- =====================
    -- Labels des onglets
    ["tab_profiles"]                    = "Profils",
    ["tab_import_export"]               = "Import/Export",
    ["tab_resets"]                      = "Réinitialisation",

    -- Onglet 1 : Mode de profil & spécialisations
    -- Tab 1: Profils nommés & spécialisations
    ["section_named_profiles"]          = "Profils",
    ["info_named_profiles"]             = "Créez et gérez des profils nommés. Chaque profil sauvegarde un instantané complet de vos paramètres.",
    ["profile_active_label"]            = "Profil actif",
    ["opt_select_profile"]              = "Choisir un profil",
    ["sublabel_create_profile"]         = "— Créer un Nouveau Profil —",
    ["placeholder_profile_name"]        = "Nom du profil...",
    ["btn_create_profile"]              = "Créer le Profil",
    ["btn_delete_named_profile"]        = "Supprimer le profil",
    ["btn_save_profile"]                = "Sauvegarder le Profil Actif",
    ["info_save_profile"]               = "Sauvegarde tous les paramètres actuels dans le profil actif. Ceci est fait automatiquement lors du changement de profil.",

    ["section_profile_mode"]            = "Mode de Profil",
    ["info_spec_profiles"]              = "Activez les profils par spécialisation pour sauvegarder et charger automatiquement vos paramètres quand vous changez de spé.\nChaque spé obtient sa propre configuration indépendante.",
    ["opt_enable_spec_profiles"]        = "Activer les profils par spécialisation",
    ["profile_status"]                  = "Profil actif",
    ["profile_global"]                  = "Global (profil unique)",
    ["section_spec_list"]               = "Spécialisations",
    ["profile_badge_active"]            = "Actif",
    ["profile_badge_saved"]             = "Sauvegardé",
    ["profile_badge_none"]              = "Aucun profil",
    ["btn_copy_to_spec"]                = "Copier l'actuel",
    ["btn_delete_profile"]              = "Supprimer",
    ["info_spec_reload"]                = "Changer de spé avec les profils activés rechargera automatiquement votre UI pour appliquer le profil correspondant.",
    ["info_global_mode"]                = "Toutes les spécialisations partagent les mêmes paramètres. Activez les profils par spé ci-dessus pour utiliser des configs différentes.",

    -- Onglet 2 : Import / Export
    ["section_export"]                  = "Exporter les Paramètres",
    ["info_export"]                     = "Génère une chaîne compressée de tous vos paramètres actuels.\nCopiez-la pour la partager ou comme sauvegarde.",
    ["label_export_string"]             = "Chaîne d'export (cliquez pour tout sélectionner)",
    ["btn_export"]                      = "Générer la Chaîne d'Export",
    ["btn_copy_clipboard"]              = "Copier le Texte",
    ["section_import"]                  = "Importer des Paramètres",
    ["info_import"]                     = "Collez une chaîne d'export ci-dessous. Elle sera validée avant application.",
    ["label_import_string"]             = "Collez la chaîne d'import ici",
    ["btn_import"]                      = "Importer & Appliquer",
    ["btn_paste_clipboard"]             = "Coller le Texte",
    ["import_preview"]                  = "Classe: %s | Modules: %s | Date: %s",
    ["import_preview_valid"]            = "✓ Chaîne valide",
    ["import_preview_invalid"]          = "Chaîne invalide ou corrompue",
    ["info_import_warning"]             = "L'import va ÉCRASER tous vos paramètres actuels et recharger l'UI. Cette action est irréversible.",

    -- Onglet 3 : Réinitialisations
    ["section_profile_mgmt"]            = "Gestion des Profils",
    ["info_profiles"]                   = "Réinitialisez des modules individuellement ou exportez/importez vos paramètres.\nL'export copie vos settings dans le presse-papier (nécessite LibSerialize + LibDeflate).",
    ["section_reset_module"]            = "Réinitialiser un module",
    ["btn_reset_prefix"]                = "Réinitialiser: ",
    ["btn_reset_all_reload"]            = "TOUT Réinitialiser + Reload",
    ["section_reset_all"]               = "Réinitialisation Complète",
    ["info_resets"]                     = "Réinitialisez un module individuel à ses valeurs par défaut. Le module sera rechargé avec les paramètres d'usine.",
    ["info_reset_all_warning"]          = "Cela réinitialisera TOUS les modules et TOUS les paramètres aux valeurs d'usine, puis rechargera l'UI.",

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
    ["msg_afd_filled"]                  = "Texte 'EFFACER' auto-rempli - Cliquez OK pour confirmer",
    ["msg_afd_db_not_init"]             = "TomoModDB non initialisée",
    ["msg_afd_initialized"]             = "Module AutoFillDelete initialisé",
    ["msg_afd_enabled"]                 = "Auto-fill EFFACER activé",
    ["msg_afd_disabled"]                = "Auto-fill EFFACER désactivé (hook reste actif)",

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
    ["msg_asr_lfg_accepted"]            = "Vérification de rôle auto-confirmée",
    ["msg_asr_poll_accepted"]           = "Sondage de rôle auto-confirmé",
    ["msg_asr_enabled"]                 = "Auto skip role check activé",
    ["msg_asr_disabled"]                = "Auto skip role check désactivé",
    ["msg_tid_enabled"]                 = "Tooltip IDs activé",
    ["msg_tid_disabled"]                = "Tooltip IDs désactivé",
    ["msg_cr_enabled"]                  = "Combat Res Tracker activé",
    ["msg_cr_disabled"]                 = "Combat Res Tracker désactivé",
    ["msg_cr_locked"]                   = "Combat Res Tracker verrouillé",
    ["msg_cr_unlock"]                   = "Combat Res Tracker déverrouillé — glissez pour déplacer",
    ["msg_abs_enabled"]                 = "Skin barres d'action activé (reload recommandé)",
    ["msg_abs_disabled"]                = "Skin barres d'action désactivé",
    ["opt_buffskin_enable"]             = "Activer le skin des buffs",
    ["opt_buffskin_desc"]               = "Ajoute un contour noir et un timer coloré sur les buffs/débuffs du joueur",
    ["msg_buffskin_enabled"]            = "Skin buffs activé",
    ["msg_buffskin_disabled"]           = "Skin buffs désactivé",
    ["msg_help_cr"]                     = "Verrouiller/déverrouiller le Combat Res Tracker",
    ["msg_help_cs"]                     = "Verrouiller/déverrouiller la feuille de personnage",
    ["msg_help_cs_reset"]               = "Réinitialiser la position de la feuille de personnage",

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
    ["mk_no_key_self"]                  = "Aucune clé trouvée.",
    ["mk_title"]                        = "TM — Mythic Keys",
    ["mk_btn_send"]                     = "Envoyer chat",
    ["mk_btn_refresh"]                  = "Refresh",
    ["mk_tab_keys"]                     = "Clés",
    ["mk_tab_tp"]                       = "TP",
    ["mk_tp_click_to_tp"]              = "Cliquer pour se téléporter",
    ["mk_tp_not_unlocked"]             = "Non débloqué",
    ["msg_tp_not_owned"]               = "Vous ne possédez pas le TP pour %s",
    ["msg_tp_combat"]                  = "Impossible de mettre à jour les TP en combat.",

    -- =====================
    -- PRINT MESSAGES: Config Panels
    -- =====================
    ["msg_np_reset"]                    = "Nameplates réinitialisées (reload recommandé)",
    ["msg_uf_toggle"]                   = "UnitFrames %s (reload)",
    ["msg_profile_reset"]               = "%s réinitialisé",
    ["msg_profile_copied"]              = "Paramètres actuels copiés vers '%s'",
    ["msg_profile_deleted"]             = "Profil supprimé pour '%s'",
    ["msg_profile_loaded"]              = "Profil '%s' chargé — rechargez pour appliquer",
    ["msg_profile_load_failed"]         = "Échec du chargement du profil '%s'",
    ["msg_profile_created"]             = "Profil '%s' créé avec les paramètres actuels",
    ["msg_profile_name_empty"]          = "Veuillez entrer un nom de profil",
    ["msg_profile_saved"]               = "Paramètres sauvegardés dans le profil '%s'",

    -- Nouvelles clés profils v2.3.0
    ["btn_rename_profile"]              = "Renommer",
    ["btn_duplicate_profile"]           = "Dupliquer",
    ["btn_load_profile"]                = "Charger",
    ["btn_close"]                       = "Fermer",
    ["btn_cancel"]                      = "Annuler",
    ["section_spec_assign"]             = "Profils par Spécialisation",
    ["info_spec_assign"]                = "Associez chaque spécialisation à un profil nommé. TomoMod chargera automatiquement le bon profil lors d'un changement de spé.",
    ["spec_profile_none"]               = "— Aucun —",
    ["popup_rename_profile"]            = "|cff0cd29fTomoMod|r\n\nNouveau nom pour '%s' :",
    ["popup_duplicate_profile"]         = "|cff0cd29fTomoMod|r\n\nDupliquer '%s' sous le nom :",
    ["msg_profile_renamed"]             = "Profil '%s' renommé en '%s'",
    ["msg_profile_duplicated"]          = "Profil '%s' dupliqué en '%s'",
    ["msg_import_as_profile"]           = "Profil importé sous le nom '%s'",
    ["popup_export_title"]              = "Exporter le Profil",
    ["popup_export_hint"]               = "Sélectionnez tout (Ctrl+A) et copiez (Ctrl+C)",
    ["popup_import_title"]              = "Importer un Profil",
    ["popup_import_hint"]               = "Collez une chaîne d'export TomoMod, puis cliquez sur Importer",
    ["label_import_profile_name"]       = "Sauvegarder sous le nom :",
    ["placeholder_import_profile_name"] = "Nom du profil (optionnel)...",
    ["msg_profile_name_deleted"]        = "Profil '%s' supprimé",
    ["msg_export_success"]              = "Chaîne d'export générée — sélectionnez tout et copiez",
    ["msg_import_success"]              = "Paramètres importés avec succès — rechargement...",
    ["msg_import_empty"]                = "Rien à importer — collez une chaîne d'abord",
    ["msg_copy_hint"]                   = "Texte sélectionné — appuyez sur Ctrl+C pour copier",
    ["msg_copy_empty"]                  = "Générez d'abord une chaîne d'export",
    ["msg_paste_hint"]                  = "Appuyez sur Ctrl+V pour coller votre chaîne d'import",
    ["msg_spec_changed_reload"]         = "Spécialisation changée — chargement du profil...",

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
    ["popup_import_text"]               = "|cff0cd29fTomoMod|r\n\nImporter les paramètres ?\nCela va ÉCRASER tous vos paramètres actuels et recharger l'UI.",
    ["popup_profile_reload"]            = "|cff0cd29fTomoMod|r\n\nMode de profil modifié.\nRecharger l'UI pour appliquer ?",
    ["popup_delete_profile"]            = "|cff0cd29fTomoMod|r\n\nSupprimer le profil '%s' ?\nCette action est irréversible.",

    -- FPS element
    ["label_fps"]                       = "FPS",

    -- =====================
    -- BOSS FRAMES
    -- =====================
    ["tab_boss"]                        = "Boss",
    ["section_boss_frames"]             = "Barres de Boss",
    ["opt_boss_enable"]                 = "Activer les barres de Boss",
    ["opt_boss_height"]                 = "Hauteur des barres",
    ["opt_boss_spacing"]                = "Espacement entre les barres",
    ["info_boss_drag"]                  = "Déverrouillez (/tm uf) pour déplacer. Glissez Boss 1 pour repositionner les 5 barres ensemble.",
    ["info_boss_colors"]                = "Les couleurs utilisent les couleurs de classification Nameplates (Boss = rouge, Mini-boss = violet).",
    ["msg_boss_initialized"]            = "Barres de Boss chargées.",

    -- =====================
    -- SOUND / LUST DETECTION
    -- =====================
    ["cat_sound"]                       = "Son",
    ["section_sound_general"]           = "Son de Bloodlust",
    ["info_sound_desc"]                 = "Joue un son personnalisé quand un effet de type Bloodlust est détecté sur votre personnage. La détection vérifie directement les buffs de Lust et les debuffs Sated/Exhaustion.",
    ["opt_sound_enable"]                = "Activer la détection de Bloodlust",
    ["sublabel_sound_choice"]           = "Son & Canal",
    ["opt_sound_file"]                  = "Son à jouer",
    ["opt_sound_channel"]               = "Canal audio",
    ["btn_sound_preview"]               = "Écouter le son",
    ["btn_sound_stop"]                  = "Arrêter",
    ["opt_sound_chat"]                  = "Afficher les messages en chat",
    ["opt_sound_debug"]                 = "Mode debug",

    -- =====================
    -- BAG & MICRO MENU
    -- =====================
    ["tab_qol_bag_micro"]               = "Sac & Menu",
    ["section_bag_micro"]               = "Barre de sac & Micro Menu",
    ["info_bag_micro"]                  = "Choisissez d'afficher en permanence ou de révéler au survol de la souris.",
    ["sublabel_bag_bar"]                = "— Barre de sac —",
    ["sublabel_micro_menu"]             = "— Micro Menu —",
    ["opt_bag_bar_mode"]                = "Barre de sac",
    ["opt_micro_menu_mode"]             = "Micro Menu",
    ["mode_show"]                       = "Toujours visible",
    ["mode_hover"]                      = "Afficher au survol",

    -- =====================
    -- CHARACTER SKIN
    -- =====================
    ["tab_qol_char_skin"]               = "Skin Personnage",
    ["section_char_skin"]               = "Skin de la fiche personnage",
    ["info_char_skin_desc"]             = "Applique le thème sombre TomoMod à la fiche personnage, la réputation, les monnaies et la fenêtre d'inspection.",
    ["opt_char_skin_enable"]            = "Activer le skin personnage",
    ["opt_char_skin_character"]         = "Skin Personnage / Réputation / Monnaies",
    ["opt_char_skin_inspect"]           = "Skin fenêtre d'inspection",
    ["opt_char_skin_iteminfo"]          = "Afficher les infos d'objet sur les emplacements",
    ["opt_char_skin_gems"]              = "Afficher les gemmes sur les emplacements",
    ["opt_char_skin_midnight"]          = "Enchantements Midnight (Tête/Épaules au lieu de Brassard/Cape)",
    ["opt_char_skin_scale"]             = "Échelle de la fenêtre",
    ["msg_char_skin_reload"]            = "Skin Personnage : /reload pour appliquer.",

    -- =====================
    -- LAYOUT / MOVERS SYSTEM
    -- =====================
    ["btn_layout"]                      = "Layout",
    ["btn_layout_tooltip"]              = "Mode Layout : déverrouille tous les éléments pour les déplacer.",
    ["btn_reload_ui"]                   = "Recharger l'UI",
    ["layout_mode_title"]               = "TomoMod — Mode Layout",
    ["layout_mode_hint"]                = "Glissez les éléments pour les repositionner — cliquez Verrouiller quand c'est fait",
    ["layout_btn_lock"]                 = "Verrouiller",
    ["layout_btn_reload"]               = "RL",
    ["grid_dimmed"]                    = "Grille",
    ["grid_bright"]                    = "Grille +",
    ["grid_disabled"]                  = "Grille OFF",
    ["layout_unlocked"]                 = "Mode Layout ACTIF — glissez les éléments. Cliquez Verrouiller ou /tm layout pour finir.",
    ["layout_locked"]                   = "Mode Layout DÉSACTIVÉ — positions sauvegardées.",
    ["msg_help_layout"]                 = "Basculer le Mode Layout (déplacer tous les éléments UI)",
    ["mover_unitframes"]                = "Unit Frames",
    ["mover_resources"]                 = "Barres de ressources",
    ["mover_skyriding"]                 = "Barre Skyriding",
    ["mover_levelingbar"]               = "Barre XP / Expérience",
    ["mover_anchors"]                   = "Ancres Alertes & Butin",
    ["mover_cotank"]                    = "Suivi Co-Tank",
    ["mover_repbar"]                    = "Barre de réputation",
    ["mover_castbar"]                   = "Barre de cast (joueur)",

    -- =====================
    -- COMBAT TEXT
    -- =====================
    ["sublabel_combat_text"]             = "— Texte de combat —",
    ["opt_combat_text_enable"]           = "Activer le texte de combat",
    ["opt_combat_text_offset_x"]         = "Décalage X",
    ["opt_combat_text_offset_y"]         = "Décalage Y",

    -- =====================
    -- SKINS (Chat)
    -- =====================
    ["tab_qol_skins"]                    = "Skins",
    ["section_skins"]                    = "Skins d'interface",
    ["info_skins_desc"]                  = "Applique le thème sombre TomoMod à divers éléments de l'interface Blizzard. Un /reload peut être nécessaire pour revenir en arrière.",
    ["sublabel_chat_skin"]               = "— Fenêtre de chat —",
    ["opt_chat_skin_enable"]             = "Skin de la fenêtre de chat",
    ["opt_chat_skin_bg_alpha"]           = "Opacité du fond",
    ["opt_chat_skin_font_size"]          = "Taille de police du chat",
    ["msg_chat_skin_enabled"]            = "Skin du chat activé",
    ["msg_chat_skin_disabled"]           = "Skin du chat désactivé (reload pour revenir)",
    ["sublabel_mail_skin"]               = "— Courrier —",
    ["opt_mail_skin_enable"]             = "Skin du courrier",
    ["msg_mail_skin_enabled"]            = "Skin du courrier activé",
    ["msg_mail_skin_disabled"]           = "Skin du courrier désactivé (reload pour revenir)",

    -- =====================
    -- WORLD QUEST TAB
    -- =====================
    ["tab_qol_world_quests"]             = "Quêtes Monde",
    ["section_wq_tab"]                   = "Onglet Quêtes du monde",
    ["info_wq_tab_desc"]                 = "Affiche une liste des Quêtes du monde disponibles à côté de la carte avec les détails des récompenses, zone, faction et temps restant. Cliquez sur une quête pour naviguer vers sa zone, Maj-Clic pour super-tracker.",
    ["opt_wq_enable"]                    = "Activer l'onglet Quêtes du monde",
    ["opt_wq_auto_show"]                 = "Afficher automatiquement à l'ouverture de la carte",
    ["opt_wq_max_quests"]                = "Nombre max de quêtes (0 = illimité)",
    ["opt_wq_min_time"]                  = "Temps restant minimum (minutes, 0 = toutes)",
    ["section_wq_filters"]               = "Filtres de récompenses",
    ["opt_wq_filter_gold"]               = "Afficher les récompenses Or",
    ["opt_wq_filter_gear"]               = "Afficher les récompenses Équipement",
    ["opt_wq_filter_rep"]                = "Afficher les récompenses Réputation",
    ["opt_wq_filter_currency"]           = "Afficher les récompenses Monnaie",
    ["opt_wq_filter_anima"]              = "Afficher les récompenses Anima",
    ["opt_wq_filter_pet"]                = "Afficher les récompenses Mascotte",
    ["opt_wq_filter_other"]              = "Afficher les autres récompenses",
    ["wq_tab_title"]                     = "QM Liste",
    ["wq_panel_title"]                   = "Quêtes du monde",
    ["wq_col_name"]                      = "Nom",
    ["wq_col_zone"]                      = "Zone",
    ["wq_col_reward"]                    = "Récompense",
    ["wq_col_time"]                      = "Temps",
    ["wq_zone"]                          = "Zone",
    ["wq_faction"]                       = "Faction",
    ["wq_reward"]                        = "Récompense",
    ["wq_time_left"]                     = "Temps restant",
    ["wq_elite"]                         = "Quête du monde Élite",
    ["wq_sort_time"]                     = "Temps",
    ["wq_sort_zone"]                     = "Zone",
    ["wq_sort_name"]                     = "Nom",
    ["wq_sort_reward"]                   = "Récompense",
    ["wq_sort_faction"]                  = "Faction",
    ["wq_status_count"]                  = "Affichage %d / %d quêtes",

    -- =====================
    -- PROFESSION HELPER
    -- =====================
    ["tab_qol_prof_helper"]              = "Métiers",
    ["section_prof_helper"]              = "Assistant Métiers",
    ["info_prof_helper_desc"]            = "Désenchantez, mouturez et prospectez vos objets en lot. Ouvrez la fenêtre pour sélectionner les objets à traiter.",
    ["opt_prof_helper_enable"]           = "Activer l'assistant Métiers",
    ["sublabel_prof_de_filters"]         = "— Filtres de qualité (Désenchantement) —",
    ["opt_prof_filter_green"]            = "Inclure les objets Peu communs (Verts)",
    ["opt_prof_filter_blue"]             = "Inclure les objets Rares (Bleus)",
    ["opt_prof_filter_epic"]             = "Inclure les objets Épiques (Violets)",
    ["btn_prof_open_helper"]             = "Ouvrir l'assistant Métiers",
    ["ph_title"]                         = "Assistant Métiers",
    ["ph_tab_disenchant"]                = "Désenchantement",
    ["ph_filter_quality"]                = "Qualité :",
    ["ph_quality_green"]                 = "Vert",
    ["ph_quality_blue"]                  = "Bleu",
    ["ph_quality_epic"]                  = "Épique",
    ["ph_select_all"]                    = "Tout sélectionner",
    ["ph_deselect_all"]                  = "Tout désélectionner",
    ["ph_btn_process"]                   = "Traiter la sélection",
    ["ph_btn_click_process"]              = "Cliquez pour traiter",
    ["ph_btn_stop"]                      = "Arrêter",
    ["ph_status_idle"]                   = "Sélectionnez des objets puis cliquez Traiter",
    ["ph_status_processing"]             = "Traitement %d/%d : %s",
    ["ph_status_done"]                   = "Terminé ! Tous les objets traités.",
    ["ph_item_count"]                    = "%d objets disponibles",
    ["ph_ilvl"]                          = "iNiv %d",

    -- =====================
    -- CLASS REMINDER
    -- =====================
    ["tab_qol_class_reminder"]            = "Rappel de classe",
    ["section_class_reminder"]            = "Rappel Buff / Forme de classe",
    ["info_class_reminder"]               = "Affiche un texte clignotant au centre de l'écran quand il vous manque votre buff de classe, forme, posture ou aura.",
    ["opt_class_reminder_enable"]         = "Activer le rappel de classe",
    ["opt_class_reminder_scale"]          = "Échelle du texte",
    ["opt_class_reminder_color"]          = "Couleur du texte",
    ["sublabel_class_reminder_pos"]       = "— Décalage de position —",
    ["opt_class_reminder_x"]             = "Décalage X",
    ["opt_class_reminder_y"]             = "Décalage Y",

    -- Class Reminder: noms buffs/formes
    ["cr_fortitude"]                     = "Mot de pouvoir : Robustesse",
    ["cr_shadowform"]                    = "Forme d'ombre",
    ["cr_arcane_intellect"]              = "Intelligence des Arcanes",
    ["cr_skyfury"]                       = "Furie céleste",
    ["cr_mark_of_the_wild"]              = "Marque du fauve",
    ["cr_cat_form"]                      = "Forme de félin",
    ["cr_bear_form"]                     = "Forme d'ours",
    ["cr_moonkin_form"]                  = "Forme de sélénien",
    ["cr_battle_shout"]                  = "Cri de guerre",
    ["cr_stance"]                        = "Posture",
    ["cr_aura"]                          = "Aura",
    ["cr_blessing_bronze"]               = "Bénédiction du Bronze",
})
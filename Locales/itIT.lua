-- =====================================
-- itIT.lua — Italiano
-- =====================================

TomoMod_RegisterLocale("itIT", {

    -- =====================
    -- CONFIG: Categories (ConfigUI.lua)
    -- =====================
    ["cat_general"]         = "Generale",
    ["cat_unitframes"]      = "UnitFrames",
    ["cat_nameplates"]      = "Nameplates",
    ["cat_cd_resource"]     = "CD e Risorse",
    ["cat_qol"]             = "Qualità della vita",
    ["cat_profiles"]        = "Profili",

    -- =====================
    -- CONFIG: General Panel
    -- =====================
    ["section_about"]                   = "Informazioni",
    ["about_text"]                      = "|cff0cd29fTomoMod|r v2.4.2 di TomoAniki\nInterfaccia leggera con QOL, UnitFrames e Nameplates.\nDigita /tm help per la lista dei comandi.",
    ["section_general"]                 = "Generale",
    ["btn_reset_all"]                   = "Ripristina tutto",
    ["info_reset_all"]                  = "Questo ripristinerà TUTTE le impostazioni e ricaricherà l'interfaccia.",

    -- Minimap
    ["section_minimap"]                 = "Minimappa",
    ["opt_minimap_enable"]              = "Attiva minimappa personalizzata",
    ["opt_size"]                        = "Dimensione",
    ["opt_scale"]                       = "Scala",
    ["opt_border"]                      = "Bordo",
    ["border_class"]                    = "Colore di classe",
    ["border_black"]                    = "Nero",

    -- Info Panel
    ["section_info_panel"]              = "Pannello informazioni",
    ["opt_enable"]                      = "Attiva",
    ["opt_durability"]                  = "Durabilità (Equipaggiamento)",
    ["opt_time"]                        = "Orario",
    ["opt_24h_format"]                  = "Formato 24h",
    ["opt_show_coords"]                 = "Mostra coordinate",
    ["btn_reset_position"]              = "Ripristina posizione",

    -- Cursor Ring
    ["section_cursor_ring"]             = "Anello del cursore",
    ["opt_class_color"]                 = "Colore di classe",
    ["opt_anchor_tooltip_ring"]         = "Ancora tooltip al cursore",

    -- =====================
    -- CONFIG: UnitFrames Panel
    -- =====================
    -- Tabs
    ["tab_general"]                     = "Generale",
    ["tab_player"]                      = "Giocatore",
    ["tab_target"]                      = "Bersaglio",
    ["tab_tot"]                         = "BdB",
    ["tab_pet"]                         = "Famiglio",
    ["tab_focus"]                       = "Focus",
    ["tab_colors"]                      = "Colori",

    -- Sub-tabs (Player, Target, Focus)
    ["subtab_dimensions"]               = "Dimensioni",
    ["subtab_display"]                  = "Visualizzazione",
    ["subtab_auras"]                    = "Aure",
    ["subtab_positioning"]              = "Posizione",

    -- Sub-labels
    ["sublabel_dimensions"]             = "— Dimensioni —",
    ["sublabel_display"]                = "— Visualizzazione —",
    ["sublabel_castbar"]                = "— Barra di lancio —",
    ["sublabel_auras"]                  = "— Aure —",
    ["sublabel_element_offsets"]        = "— Posizioni elementi —",

    -- Unit display names
    ["unit_player"]                     = "Giocatore",
    ["unit_target"]                     = "Bersaglio",
    ["unit_tot"]                        = "Bersaglio del bersaglio",
    ["unit_pet"]                        = "Famiglio",
    ["unit_focus"]                      = "Focus",

    -- General tab
    ["section_general_settings"]        = "Impostazioni generali",
    ["opt_uf_enable"]                   = "Attiva UnitFrames di TomoMod",
    ["opt_hide_blizzard"]               = "Nascondi frame di Blizzard",
    ["opt_global_font_size"]            = "Dimensione font globale",
    ["sublabel_font"]                   = "— Font —",
    ["opt_font_family"]                 = "Famiglia di font",

    -- Castbar colors
    ["section_castbar_colors"]          = "Colori barra di lancio",
    ["info_castbar_colors"]             = "Personalizza i colori della barra di lancio per incantesimi interrompibili, non interrompibili e interrotti.",
    ["opt_castbar_color"]               = "Incantesimo interrompibile",
    ["opt_castbar_ni_color"]            = "Incantesimo non interrompibile",
    ["opt_castbar_interrupt_color"]     = "Incantesimo interrotto",
    ["info_castbar_colors_reload"]      = "Le modifiche ai colori si applicano ai nuovi lanci. /reload per effetto completo.",
    ["btn_toggle_lock"]                 = "Blocca/Sblocca (/tm uf)",
    ["info_unlock_drag"]                = "Sblocca per spostare i frame. Le posizioni vengono salvate automaticamente.",

    -- Per-unit options
    ["opt_width"]                       = "Larghezza",
    ["opt_health_height"]               = "Altezza vita",
    ["opt_power_height"]                = "Altezza risorsa",
    ["opt_show_name"]                   = "Mostra nome",
    ["opt_name_truncate"]               = "Tronca nomi lunghi",
    ["opt_name_truncate_length"]        = "Lunghezza max. nome",
    ["opt_show_level"]                  = "Mostra livello",
    ["opt_show_health_text"]            = "Mostra testo vita",
    ["opt_health_format"]               = "Formato vita",
    ["fmt_current"]                     = "Attuale (25.3K)",
    ["fmt_percent"]                     = "Percentuale (75%)",
    ["fmt_current_percent"]             = "Attuale + % (25.3K | 75%)",
    ["fmt_current_max"]                 = "Attuale / Max",
    ["opt_class_color_uf"]              = "Colore di classe",
    ["opt_faction_color"]               = "Colore di fazione (PNG)",
    ["opt_use_nameplate_colors"]        = "Colori Nameplate (tipo di PNG)",
    ["opt_show_absorb"]                 = "Barra di assorbimento",
    ["opt_show_threat"]                 = "Indicatore di minaccia (bagliore bordo)",
    ["section_threat_text"]             = "Testo % minaccia",
    ["opt_threat_text_enable"]          = "Mostra % di minaccia sul bersaglio",
    ["opt_threat_text_font_size"]       = "Dimensione font",
    ["opt_threat_text_offset_x"]        = "Offset X",
    ["opt_threat_text_offset_y"]        = "Offset Y",
    ["info_threat_text"]                = "Verde = tank (vantaggio), giallo = avviso, rosso = aggro perso",
    ["opt_show_leader_icon"]            = "Icona leader",
    ["opt_leader_icon_x"]               = "Icona leader X",
    ["opt_leader_icon_y"]               = "Icona leader Y",

    -- Castbar
    ["opt_castbar_enable"]              = "Attiva barra di lancio",
    ["opt_castbar_width"]               = "Larghezza barra di lancio",
    ["opt_castbar_height"]              = "Altezza barra di lancio",
    ["opt_castbar_show_icon"]           = "Mostra icona",
    ["opt_castbar_show_timer"]          = "Mostra timer",
    ["info_castbar_drag"]               = "Posizione: /tm sr per sbloccare e spostare la barra di lancio.",
    ["btn_reset_castbar_position"]      = "Ripristina posizione barra di lancio",
    ["opt_castbar_show_latency"]        = "Mostra latenza",

    -- Auras
    ["opt_auras_enable"]                = "Attiva aure",
    ["opt_auras_max"]                   = "Aure massime",
    ["opt_auras_size"]                  = "Dimensione icona",
    ["opt_auras_type"]                  = "Tipo di aura",
    ["aura_harmful"]                    = "Debuff (dannosi)",
    ["aura_helpful"]                    = "Buff (benefici)",
    ["aura_all"]                        = "Tutti",
    ["opt_auras_direction"]             = "Direzione di crescita",
    ["aura_dir_right"]                  = "Verso destra",
    ["aura_dir_left"]                   = "Verso sinistra",
    ["opt_auras_only_mine"]             = "Solo le mie aure",

    -- Element offsets
    ["elem_name"]                       = "Nome",
    ["elem_level"]                      = "Livello",
    ["elem_health_text"]                = "Testo vita",
    ["elem_power"]                      = "Barra risorsa",
    ["elem_castbar"]                    = "Barra di lancio",
    ["elem_auras"]                      = "Aure",

    -- =====================
    -- CONFIG: Nameplates Panel
    -- =====================
    -- Nameplate tabs
    ["tab_np_auras"]                    = "Aure",
    ["tab_np_advanced"]                 = "Avanzato",
    ["info_np_colors_custom"]           = "Ogni colore può essere personalizzato cliccando sul campione di colore.",

    ["section_np_general"]              = "Impostazioni generali",
    ["opt_np_enable"]                   = "Attiva Nameplates di TomoMod",
    ["info_np_description"]             = "Sostituisce le nameplates di Blizzard con uno stile minimalista personalizzabile.",
    ["section_dimensions"]              = "Dimensioni",
    ["opt_np_name_font_size"]           = "Dimensione font nome",

    -- Display
    ["section_display"]                 = "Visualizzazione",
    ["opt_np_show_classification"]      = "Mostra classificazione (élite, raro, boss)",
    ["opt_np_show_absorb"]               = "Mostra barra di assorbimento",
    ["opt_np_class_colors"]             = "Colori di classe (giocatori)",

    -- Raid Marker
    ["section_raid_marker"]             = "Indicatore del raid",
    ["opt_np_raid_icon_anchor"]         = "Posizione dell'icona",
    ["opt_np_raid_icon_x"]              = "Offset X",
    ["opt_np_raid_icon_y"]              = "Offset Y",
    ["opt_np_raid_icon_size"]           = "Dimensione icona",

    -- Castbar
    ["section_castbar"]                 = "Barra di lancio",
    ["opt_np_show_castbar"]             = "Mostra barra di lancio",
    ["opt_np_castbar_height"]           = "Altezza barra di lancio",
    ["color_castbar"]                   = "Barra di lancio (interrompibile)",
    ["color_castbar_uninterruptible"]   = "Barra di lancio (non interrompibile)",

    -- Auras
    ["section_auras"]                   = "Aure",
    ["opt_np_show_auras"]               = "Mostra aure",
    ["opt_np_aura_size"]                = "Dimensione icona",
    ["opt_np_max_auras"]                = "Conteggio massimo",
    ["opt_np_only_my_debuffs"]          = "Solo i miei debuff",

    -- Enemy Buffs
    ["section_enemy_buffs"]              = "Buff nemici",
    ["sublabel_enemy_buffs"]             = "— Buff nemici —",
    ["opt_enemy_buffs_enable"]           = "Mostra buff nemici",
    ["opt_enemy_buffs_max"]              = "Max. buff",
    ["opt_enemy_buffs_size"]             = "Dimensione icona buff",
    ["info_enemy_buffs"]                 = "Mostra i buff attivi (Furia, scudi...) sulle unità ostili. Le icone appaiono in alto a destra, impilate verso l'alto.",
    ["opt_np_show_enemy_buffs"]          = "Mostra buff nemici",
    ["opt_np_enemy_buff_size"]           = "Dimensione icona buff",
    ["opt_np_max_enemy_buffs"]           = "Max. buff nemici",
    ["opt_np_enemy_buff_y_offset"]       = "Offset Y buff nemici",

    -- Transparency
    ["section_transparency"]            = "Trasparenza",
    ["opt_np_selected_alpha"]           = "Alfa selezionato",
    ["opt_np_unselected_alpha"]         = "Alfa non selezionato",

    -- Stacking
    ["section_stacking"]                = "Impilamento",
    ["opt_np_overlap"]                  = "Sovrapposizione verticale",
    ["opt_np_top_inset"]                = "Limite superiore schermo",

    -- Colors
    ["section_colors"]                  = "Colori",
    ["color_hostile"]                   = "Ostile (Nemico)",
    ["color_neutral"]                   = "Neutrale",
    ["color_friendly"]                  = "Amichevole",
    ["color_tapped"]                    = "Contrassegnato (tapped)",
    ["color_focus"]                     = "Bersaglio focus",

    -- NPC Type Colors
    ["section_npc_type_colors"]         = "Colori tipo PNG",
    ["color_caster"]                    = "Incantatore",
    ["color_miniboss"]                  = "Mini-boss (élite + livello superiore)",
    ["color_enemy_in_combat"]           = "Nemico (predefinito)",
    ["info_np_darken_ooc"]              = "I nemici fuori combattimento vengono automaticamente oscurati.",

    -- Classification colors
    ["section_classification_colors"]   = "Colori classificazione",
    ["opt_np_use_classification"]       = "Colori per tipo di nemico",
    ["color_boss"]                      = "Boss",
    ["color_elite"]                     = "Élite / Mini-boss",
    ["color_rare"]                      = "Raro",
    ["color_normal"]                    = "Normale",
    ["color_trivial"]                   = "Insignificante",

    -- Tank mode
    ["section_tank_mode"]               = "Modalità tank",
    ["opt_np_tank_mode"]                = "Attiva modalità tank (colori minaccia)",
    ["color_no_threat"]                 = "Nessuna minaccia",
    ["color_low_threat"]                = "Minaccia bassa",
    ["color_has_threat"]                = "Minaccia mantenuta",
    ["color_dps_has_aggro"]             = "DPS/Guaritore ha aggro",
    ["color_dps_near_aggro"]            = "DPS/Guaritore vicino all'aggro",

    -- NP health format
    ["np_fmt_percent"]                  = "Percentuale (75%)",
    ["np_fmt_current"]                  = "Attuale (25.3K)",
    ["np_fmt_current_percent"]          = "Attuale + %",

    -- Reset
    ["btn_reset_nameplates"]            = "Ripristina Nameplates",

    -- =====================
    -- CONFIG: CD & Resource Panel
    -- =====================
    -- Resource colors
    ["section_resource_colors"]         = "Colori risorse",
    ["res_runes_ready"]                 = "Rune (pronte)",
    ["res_runes_cd"]                    = "Rune (ricarica)",

    -- Cooldown Manager
    ["tab_cdm"]                         = "Ricariche",
    ["tab_resource_bars"]               = "Barre risorse",
    ["tab_text_position"]               = "Testo e posizione",
    ["tab_rb_colors"]                   = "Colori",
    ["info_rb_colors_custom"]           = "Ogni colore può essere personalizzato cliccando sul campione di colore.",

    ["section_cdm"]                     = "Gestore ricariche",
    ["opt_cdm_enable"]                  = "Attiva gestore ricariche",
    ["info_cdm_description"]            = "Reskin delle icone del CooldownManager di Blizzard: bordi arrotondati, overlay di classe sulle aure attive, colori di sweep personalizzati, dimming utilità, layout centrato. Posizionamento tramite Edit Mode di Blizzard.",
    ["opt_cdm_show_hotkeys"]            = "Mostra tasti rapidi",
    ["opt_cdm_combat_alpha"]            = "Modifica opacità (combattimento / bersaglio)",
    ["opt_cdm_alpha_combat"]            = "Alfa in combattimento",
    ["opt_cdm_alpha_target"]            = "Alfa con bersaglio (fuori combattimento)",
    ["opt_cdm_alpha_ooc"]               = "Alfa fuori combattimento",
    ["section_cdm_overlay"]             = "Overlay e bordi",
    ["opt_cdm_custom_overlay"]          = "Colore overlay personalizzato",
    ["opt_cdm_overlay_color"]           = "Colore overlay",
    ["opt_cdm_custom_swipe"]            = "Colore sweep attivo personalizzato",
    ["opt_cdm_swipe_color"]             = "Colore sweep",
    ["opt_cdm_swipe_alpha"]             = "Opacità sweep",
    ["section_cdm_utility"]             = "Utilità",
    ["opt_cdm_dim_utility"]             = "Attenua icone utilità quando non in CD",
    ["opt_cdm_dim_opacity"]             = "Opacità attenuazione",
    ["info_cdm_editmode"]               = "Il posizionamento avviene tramite l'Edit Mode di Blizzard (Esc → Edit Mode).",

    -- Resource Bars
    ["section_resource_bars"]           = "Barre risorse",
    ["opt_rb_enable"]                   = "Attiva barre risorse",
    ["info_rb_description"]             = "Mostra le risorse di classe (Mana, Ira, Energia, Punti combo, Rune, ecc.) con supporto adattativo per i Druidi.",
    ["section_visibility"]              = "Visibilità",
    ["opt_rb_visibility_mode"]          = "Modalità visibilità",
    ["vis_always"]                      = "Sempre visibile",
    ["vis_combat"]                      = "Solo in combattimento",
    ["vis_target"]                      = "Combattimento o bersaglio",
    ["vis_hidden"]                      = "Nascosto",
    ["opt_rb_combat_alpha"]             = "Alfa in combattimento",
    ["opt_rb_ooc_alpha"]                = "Alfa fuori combattimento",
    ["opt_rb_width"]                    = "Larghezza",
    ["opt_rb_primary_height"]           = "Altezza barra primaria",
    ["opt_rb_secondary_height"]         = "Altezza barra secondaria",
    ["opt_rb_global_scale"]             = "Scala globale",
    ["opt_rb_sync_width"]               = "Sincronizza larghezza con Essential Cooldowns",
    ["btn_sync_now"]                    = "Sincronizza ora",
    ["info_rb_sync"]                    = "Allinea la larghezza con l'EssentialCooldownViewer del CooldownManager di Blizzard.",

    -- Text & Font
    ["section_text_font"]               = "Testo e font",
    ["opt_rb_show_text"]                = "Mostra testo sulle barre",
    ["opt_rb_text_align"]               = "Allineamento testo",
    ["align_left"]                      = "Sinistra",
    ["align_center"]                    = "Centro",
    ["align_right"]                     = "Destra",
    ["opt_rb_font_size"]                = "Dimensione font",
    ["opt_rb_font"]                     = "Font",
    ["font_default_wow"]                = "Predefinito WoW",

    -- Position
    ["section_position"]                = "Posizione",
    ["info_rb_position"]                = "Usa /tm uf per sbloccare e spostare le barre. La posizione viene salvata automaticamente.",
    ["info_rb_druid"]                   = "Le barre si adattano automaticamente alla tua classe e specializzazione.\nDruido: la risorsa cambia in base alla forma (Orso → Ira, Gatto → Energia, Gufo → Potere astrale).",

    -- =====================
    -- CONFIG: QOL Panel
    -- =====================
    ["tab_qol_cinematic"]               = "Filmato",
    ["tab_qol_auto_quest"]              = "Auto missioni",
    ["tab_qol_automations"]             = "Automazioni",
    ["tab_qol_mythic_keys"]             = "Chiavi M+",
    ["tab_qol_skyride"]                 = "SkyRide",
    ["tab_qol_action_bars"]             = "Barre d'azione",
    ["section_action_bars"]             = "Skin barre d'azione",
    ["cat_action_bars"]                 = "Barre d'azione",
    ["opt_abs_enable"]                  = "Attiva skin barre d'azione",
    ["opt_abs_class_color"]             = "Colore di classe per i bordi",
    ["opt_abs_shift_reveal"]            = "Tieni Shift per rivelare le barre nascoste",
    ["sublabel_bar_opacity"]            = "— Opacità per barra —",
    ["opt_abs_select_bar"]              = "Seleziona barra d'azione",
    ["opt_abs_opacity"]                 = "Opacità",
    ["btn_abs_apply_all_opacity"]       = "Applica a tutte le barre",
    ["msg_abs_all_opacity"]             = "Opacità impostata a %d%% su tutte le barre",
    ["sublabel_bar_combat"]             = "— Visibilità in combattimento —",
    ["opt_abs_combat_show"]             = "Mostra solo in combattimento",

    ["section_cinematic"]               = "Salta filmati",
    ["opt_cinematic_auto_skip"]         = "Salta automaticamente dopo la prima visione",
    ["info_cinematic_viewed"]           = "Filmati già visti: %s\nLa cronologia è condivisa tra i personaggi.",
    ["btn_clear_history"]               = "Cancella cronologia",

    -- Auto Quest
    ["section_auto_quest"]              = "Auto missioni",
    ["opt_quest_auto_accept"]           = "Accetta missioni automaticamente",
    ["opt_quest_auto_turnin"]           = "Completa missioni automaticamente",
    ["opt_quest_auto_gossip"]           = "Seleziona dialoghi automaticamente",
    ["info_quest_shift"]                = "Tieni SHIFT per disattivare temporaneamente.\nLe missioni con ricompense multiple non vengono completate automaticamente.",

    -- Objective Tracker Skin
    ["tab_qol_obj_tracker"]             = "Tracciatore",
    ["section_obj_tracker"]             = "Skin tracciatore obiettivi",
    ["opt_obj_tracker_enable"]          = "Attiva skin tracciatore",
    ["opt_obj_tracker_bg_alpha"]        = "Opacità sfondo",
    ["opt_obj_tracker_border"]          = "Mostra bordo",
    ["opt_obj_tracker_hide_empty"]      = "Nascondi se vuoto",
    ["opt_obj_tracker_header_size"]     = "Dimensione font intestazione",
    ["opt_obj_tracker_cat_size"]        = "Dimensione font categoria",
    ["opt_obj_tracker_quest_size"]      = "Dimensione font titolo missione",
    ["opt_obj_tracker_obj_size"]        = "Dimensione font obiettivo",
    ["opt_obj_tracker_max_quests"]       = "Max. missioni mostrate (0 = nessun limite)",
    ["ot_overflow_text"]                 = "%d missione/i nascosta/e...",
    ["info_obj_tracker"]                = "Applica una skin scura al tracciatore obiettivi di Blizzard con pannello, font personalizzati e intestazioni di categoria colorate.",
    ["ot_header_title"]                 = "OBIETTIVI",
    ["ot_header_options"]               = "Opzioni",

    -- Automations
    ["section_automations"]             = "Automazioni",
    ["opt_hide_blizzard_castbar"]       = "Nascondi barra di lancio di Blizzard",

    -- Auto Accept Invite
    ["sublabel_auto_accept_invite"]     = "— Accetta invito automaticamente —",
    ["sublabel_auto_skip_role"]         = "— Salta verifica ruolo —",
    ["sublabel_tooltip_ids"]            = "— ID Tooltip —",
    ["sublabel_combat_res_tracker"]     = "— Tracciatore res. in combattimento —",
    ["opt_cr_show_rating"]              = "Mostra punteggio M+",
    ["opt_show_messages"]               = "Mostra messaggi in chat",
    ["opt_tid_spell"]                   = "ID incantesimo / aura",
    ["opt_tid_item"]                    = "ID oggetto",
    ["opt_tid_npc"]                     = "ID PNG",
    ["opt_tid_quest"]                   = "ID missione",
    ["opt_tid_mount"]                   = "ID cavalcatura",
    ["opt_tid_currency"]                = "ID valuta",
    ["opt_tid_achievement"]             = "ID impresa",
    ["opt_accept_friends"]              = "Accetta dagli amici",
    ["opt_accept_guild"]                = "Accetta dalla gilda",

    -- Auto Summon
    ["sublabel_auto_summon"]            = "— Auto evocazione —",
    ["opt_summon_delay"]                = "Ritardo (secondi)",

    -- Auto Fill Delete
    ["sublabel_auto_fill_delete"]       = "— Auto compila ELIMINA —",
    ["opt_focus_ok_button"]             = "Focus su OK dopo compilazione",

    -- Mythic+ Keys
    ["section_mythic_keys"]             = "Chiavi Mitiche+",
    ["opt_keys_enable_tracker"]         = "Attiva tracciatore",
    ["opt_keys_mini_frame"]             = "Mini-frame sull'interfaccia M+",
    ["opt_keys_auto_refresh"]           = "Aggiornamento automatico",

    -- SkyRide
    ["section_skyride"]                 = "SkyRide",
    ["opt_skyride_enable"]              = "Attiva (display di volo)",
    ["section_skyride_dims"]            = "Dimensioni",
    ["opt_skyride_bar_height"]          = "Altezza barra velocità",
    ["opt_skyride_charge_height"]       = "Altezza barra carica",
    ["opt_skyride_charge_gap"]          = "Spazio tra segmenti",
    ["section_skyride_text"]            = "Testo",
    ["opt_skyride_show_speed_text"]     = "Mostra percentuale velocità",
    ["opt_skyride_speed_font_size"]     = "Dimensione font velocità",
    ["opt_skyride_show_charge_timer"]   = "Mostra timer carica",
    ["opt_skyride_charge_font_size"]    = "Dimensione font timer carica",
    ["btn_reset_skyride"]               = "Ripristina posizione SkyRide",

    -- =====================
    -- CONFIG: QOL — CVar Optimizer
    -- =====================
    ["tab_qol_cvar_opt"]                = "CVars Perf",
    ["section_cvar_optimizer"]          = "Ottimizzatore CVars",
    ["info_cvar_optimizer"]             = "Applica impostazioni grafiche/prestazioni raccomandate. I tuoi valori attuali vengono salvati e possono essere ripristinati in qualsiasi momento.",
    ["btn_cvar_apply_all"]              = ">> Applica tutto",
    ["btn_cvar_revert_all"]             = "<< Ripristina tutto",
    ["btn_cvar_apply"]                  = "Applica",
    ["btn_cvar_revert"]                 = "Ripristina",
    -- Categories
    ["opt_cat_render"]                  = "Rendering e display",
    ["opt_cat_graphics"]                = "Qualità grafica",
    ["opt_cat_detail"]                  = "Distanza visiva e dettagli",
    ["opt_cat_advanced"]                = "Avanzato",
    ["opt_cat_fps"]                     = "Limiti FPS",
    ["opt_cat_post"]                    = "Post-elaborazione",
    -- CVar labels
    ["opt_cvar_render_scale"]           = "Scala di rendering",
    ["opt_cvar_vsync"]                  = "VSync",
    ["opt_cvar_msaa"]                   = "Multisampling (MSAA)",
    ["opt_cvar_low_latency"]            = "Modalità bassa latenza",
    ["opt_cvar_anti_aliasing"]          = "Anti-aliasing",
    ["opt_cvar_shadow"]                 = "Qualità ombre",
    ["opt_cvar_ssao"]                   = "SSAO",
    ["opt_cvar_depth"]                  = "Effetti di profondità",
    ["opt_cvar_compute"]                = "Effetti di calcolo",
    ["opt_cvar_particle"]               = "Densità particelle",
    ["opt_cvar_liquid"]                 = "Dettaglio liquidi",
    ["opt_cvar_spell_density"]          = "Densità incantesimi",
    ["opt_cvar_projected"]              = "Texture proiettate",
    ["opt_cvar_outline"]                = "Modalità contorno",
    ["opt_cvar_texture_res"]            = "Risoluzione texture",
    ["opt_cvar_view_distance"]          = "Distanza visiva",
    ["opt_cvar_env_detail"]             = "Dettaglio ambiente",
    ["opt_cvar_ground"]                 = "Vegetazione del suolo",
    ["opt_cvar_gfx_api"]                = "API grafica",
    ["opt_cvar_triple_buffering"]       = "Triple buffering",
    ["opt_cvar_texture_filtering"]      = "Filtraggio texture",
    ["opt_cvar_rt_shadows"]             = "Ombre ray tracing",
    ["opt_cvar_resample_quality"]       = "Qualità di ricampionamento",
    ["opt_cvar_physics"]                = "Livello fisica",
    ["opt_cvar_target_fps"]             = "FPS obiettivo",
    ["opt_cvar_bg_fps_enable"]          = "Limite FPS in background",
    ["opt_cvar_bg_fps"]                 = "Valore FPS in background",
    ["opt_cvar_resample_sharpness"]     = "Nitidezza di ricampionamento",
    ["opt_cvar_camera_shake"]           = "Vibrazione telecamera",
    -- Messages
    ["msg_cvar_applied"]                = "CVars applicate",
    ["msg_cvar_reverted"]               = "CVars ripristinate",
    ["msg_cvar_no_backup"]              = "Nessun backup trovato — applica prima.",
    ["tab_qol_leveling"]                = "Leveling",
    ["section_leveling_bar"]            = "Barra di esperienza",
    ["opt_leveling_enable"]             = "Attiva barra di esperienza",
    ["opt_leveling_width"]              = "Larghezza barra",
    ["opt_leveling_height"]             = "Altezza barra",
    ["btn_reset_leveling_pos"]          = "Ripristina posizione",
    ["leveling_bar_title"]              = "Barra di esperienza",
    ["leveling_level"]                  = "Livello",
    ["leveling_progress"]               = "Progresso:",
    ["leveling_rested"]                 = "Riposato",
    ["leveling_last_quest"]             = "Ultima missione:",
    ["leveling_ttl"]                    = "Tempo per livello:",
    ["leveling_drag_hint"]              = "/tm sr per sbloccare e spostare",

    -- =====================
    -- CONFIG: Profiles Panel (3 Tabs)
    -- =====================
    ["tab_profiles"]                    = "Profili",
    ["tab_import_export"]               = "Importa/Esporta",
    ["tab_resets"]                      = "Ripristino",

    -- Tab 1: Named profiles & specializations
    ["section_named_profiles"]          = "Profili",
    ["info_named_profiles"]             = "Crea e gestisci profili con nome. Ogni profilo salva un'istantanea completa delle tue impostazioni.",
    ["profile_active_label"]            = "Profilo attivo",
    ["opt_select_profile"]              = "Scegli un profilo",
    ["sublabel_create_profile"]         = "— Crea nuovo profilo —",
    ["placeholder_profile_name"]        = "Nome profilo...",
    ["btn_create_profile"]              = "Crea profilo",
    ["btn_delete_named_profile"]        = "Elimina profilo",
    ["btn_save_profile"]                = "Salva profilo attuale",
    ["info_save_profile"]               = "Salva tutte le impostazioni attuali nel profilo attivo. Questo avviene automaticamente al cambio di profilo.",

    ["section_profile_mode"]            = "Modalità profilo",
    ["info_spec_profiles"]              = "Attiva i profili per specializzazione per salvare e caricare automaticamente le impostazioni quando cambi specializzazione.\nOgni specializzazione ha la propria configurazione indipendente.",
    ["opt_enable_spec_profiles"]        = "Attiva profili per specializzazione",
    ["profile_status"]                  = "Profilo attivo",
    ["profile_global"]                  = "Globale (profilo unico)",
    ["section_spec_list"]               = "Specializzazioni",
    ["profile_badge_active"]            = "Attivo",
    ["profile_badge_saved"]             = "Salvato",
    ["profile_badge_none"]              = "Nessun profilo",
    ["btn_copy_to_spec"]                = "Copia attuale",
    ["btn_delete_profile"]              = "Elimina",
    ["info_spec_reload"]                = "Cambiare specializzazione con i profili attivati ricaricherà automaticamente l'interfaccia per applicare il profilo corrispondente.",
    ["info_global_mode"]                = "Tutte le specializzazioni condividono le stesse impostazioni. Attiva i profili per specializzazione sopra per usare configurazioni diverse.",

    -- Tab 2: Import / Export
    ["section_export"]                  = "Esporta impostazioni",
    ["info_export"]                     = "Genera una stringa compressa di tutte le impostazioni attuali.\nCopiala per condividerla o come backup.",
    ["label_export_string"]             = "Stringa di esportazione (clicca per selezionare tutto)",
    ["btn_export"]                      = "Genera stringa di esportazione",
    ["btn_copy_clipboard"]              = "Copia testo",
    ["section_import"]                  = "Importa impostazioni",
    ["info_import"]                     = "Incolla una stringa di esportazione qui sotto. Verrà validata prima dell'applicazione.",
    ["label_import_string"]             = "Incolla la stringa di importazione qui",
    ["btn_import"]                      = "Importa e applica",
    ["btn_paste_clipboard"]             = "Incolla testo",
    ["import_preview"]                  = "Classe: %s | Moduli: %s | Data: %s",
    ["import_preview_valid"]            = "✓ Stringa valida",
    ["import_preview_invalid"]          = "Stringa invalida o corrotta",
    ["info_import_warning"]             = "L'importazione SOVRASCRIVERÀ tutte le impostazioni attuali e ricaricherà l'interfaccia. Questa azione non può essere annullata.",

    -- Tab 3: Resets
    ["section_profile_mgmt"]            = "Gestione profili",
    ["info_profiles"]                   = "Ripristina moduli singoli o esporta/importa le impostazioni.\nL'esportazione copia le impostazioni negli appunti (richiede LibSerialize + LibDeflate).",
    ["section_reset_module"]            = "Ripristina un modulo",
    ["btn_reset_prefix"]                = "Ripristina: ",
    ["btn_reset_all_reload"]            = "(!) RIPRISTINA TUTTO + Ricarica",
    ["section_reset_all"]               = "Ripristino completo",
    ["info_resets"]                     = "Ripristina un singolo modulo ai valori predefiniti. Il modulo verrà ricaricato con le impostazioni di fabbrica.",
    ["info_reset_all_warning"]          = "Questo ripristinerà TUTTI i moduli e TUTTE le impostazioni ai valori di fabbrica, poi ricaricherà l'interfaccia.",

    -- =====================
    -- PRINT MESSAGES: Core
    -- =====================
    ["msg_db_reset"]                    = "Database ripristinato",
    ["msg_module_reset"]                = "Modulo '%s' ripristinato",
    ["msg_db_not_init"]                 = "Database non inizializzato",
    ["msg_loaded"]                      = "v2.0 caricato — %s per configurazione",
    ["msg_help_title"]                  = "v2.0 — Comandi:",
    ["msg_help_open"]                   = "Apri configurazione",
    ["msg_help_reset"]                  = "Ripristina tutto + ricarica",
    ["msg_help_uf"]                     = "Blocca/Sblocca UnitFrames + Risorse",
    ["msg_help_uf_reset"]               = "Ripristina UnitFrames",
    ["msg_help_rb"]                     = "Blocca/Sblocca barre risorse",
    ["msg_help_rb_sync"]                = "Sincronizza larghezza con Essential Cooldowns",
    ["msg_help_np"]                     = "Attiva/disattiva Nameplates",
    ["msg_help_minimap"]                = "Ripristina minimappa",
    ["msg_help_panel"]                  = "Ripristina pannello info",
    ["msg_help_cursor"]                 = "Ripristina anello cursore",
    ["msg_help_clearcinema"]            = "Cancella cronologia filmati",
    ["msg_help_sr"]                     = "Blocca/Sblocca SkyRide + Ancore",
    ["msg_help_key"]                    = "Apri chiavi Mitiche+",
    ["msg_help_help"]                   = "Questo aiuto",

    -- =====================
    -- PRINT MESSAGES: Modules
    -- =====================
    -- CDM
    ["msg_cdm_status"]                  = "Attivato",
    ["msg_cdm_disabled"]                = "Disattivato",

    -- Nameplates
    ["msg_np_enabled"]                  = "Attivate",
    ["msg_np_disabled"]                 = "Disattivate",

    -- UnitFrames
    ["msg_uf_locked"]                   = "Bloccato",
    ["msg_uf_unlocked"]                 = "Sbloccato — Trascina per riposizionare",
    ["msg_uf_initialized"]              = "Inizializzato — /tm uf per bloccare/sbloccare",
    ["msg_uf_enabled"]                  = "attivato (ricarica necessaria)",
    ["msg_uf_disabled"]                 = "disattivato (ricarica necessaria)",
    ["msg_uf_position_reset"]           = "posizione ripristinata",

    -- ResourceBars
    ["msg_rb_width_synced"]             = "Larghezza sincronizzata (%dpx)",
    ["msg_rb_locked"]                   = "Bloccato",
    ["msg_rb_unlocked"]                 = "Sbloccato — Trascina per riposizionare",
    ["msg_rb_position_reset"]           = "Posizione barre risorse ripristinata",

    -- SkyRide
    ["msg_sr_pos_saved"]                = "Posizione SkyRide salvata",
    ["msg_sr_locked"]                   = "SkyRide bloccato",
    ["msg_sr_unlock"]                   = "Modalità spostamento SkyRide attivata – Clicca e trascina",
    ["msg_sr_pos_reset"]                = "Posizione SkyRide ripristinata",
    ["msg_sr_db_not_init"]              = "TomoModDB non inizializzato",
    ["msg_sr_initialized"]              = "Modulo SkyRide inizializzato",

    -- FrameAnchors
    ["anchor_alert"]                    = "Avvisi",
    ["anchor_loot"]                     = "Bottino",
    ["msg_anchors_locked"]              = "Bloccati",
    ["msg_anchors_unlocked"]            = "Sbloccati — sposta le ancore",

    -- AutoVendorRepair
    ["msg_avr_header"]                  = "[AutoVenditoreRipara]",
    ["msg_avr_sold"]                    = " Oggetti grigi venduti per |cffffff00%s|r",
    ["msg_avr_repaired"]                = " Equipaggiamento riparato per |cffffff00%s|r",

    -- AutoFillDelete
    ["msg_afd_filled"]                  = "Testo 'ELIMINA' auto-compilato – Clicca OK per confermare",
    ["msg_afd_db_not_init"]             = "TomoModDB non inizializzato",
    ["msg_afd_initialized"]             = "Modulo AutoFillDelete inizializzato",
    ["msg_afd_enabled"]                 = "Auto-compilazione ELIMINA attivata",
    ["msg_afd_disabled"]                = "Auto-compilazione ELIMINA disattivata (hook ancora attivo)",

    -- HideCastBar
    ["msg_hcb_db_not_init"]             = "TomoModDB non inizializzato",
    ["msg_hcb_initialized"]             = "Modulo HideCastBar inizializzato",
    ["msg_hcb_hidden"]                  = "Barra di lancio nascosta",
    ["msg_hcb_shown"]                   = "Barra di lancio mostrata",

    -- AutoAcceptInvite
    ["msg_aai_accepted"]                = "Invito accettato da ",
    ["msg_aai_ignored"]                 = "Invito ignorato da ",
    ["msg_aai_enabled"]                 = "Auto-accettazione inviti attivata",
    ["msg_aai_disabled"]                = "Auto-accettazione inviti disattivata",
    ["msg_asr_lfg_accepted"]            = "Verifica ruolo auto-confermata",
    ["msg_asr_poll_accepted"]           = "Sondaggio ruolo auto-confermato",
    ["msg_asr_enabled"]                 = "Auto salta verifica ruolo attivato",
    ["msg_asr_disabled"]                = "Auto salta verifica ruolo disattivato",
    ["msg_tid_enabled"]                 = "Tooltip IDs attivato",
    ["msg_tid_disabled"]                = "Tooltip IDs disattivato",
    ["msg_cr_enabled"]                  = "Tracciatore res. in combattimento attivato",
    ["msg_cr_disabled"]                 = "Tracciatore res. in combattimento disattivato",
    ["msg_cr_locked"]                   = "Tracciatore res. in combattimento bloccato",
    ["msg_cr_unlock"]                   = "Tracciatore res. in combattimento sbloccato — trascina per spostare",
    ["msg_abs_enabled"]                 = "Skin barre d'azione attivato (ricarica consigliata)",
    ["msg_abs_disabled"]                = "Skin barre d'azione disattivato",
    ["opt_buffskin_enable"]             = "Attiva skin buff",
    ["opt_buffskin_desc"]               = "Aggiunge bordi neri e timer colorato sui buff/debuff del giocatore",
    ["msg_buffskin_enabled"]            = "Skin buff attivato",
    ["msg_buffskin_disabled"]           = "Skin buff disattivato",
    ["msg_help_cr"]                     = "Blocca/sblocca tracciatore res. in combattimento",
    ["msg_help_cs"]                     = "Blocca/sblocca posizione scheda personaggio",
    ["msg_help_cs_reset"]               = "Ripristina posizione scheda personaggio",

    -- CinematicSkip
    ["msg_cin_skipped"]                 = "Filmato saltato (già visto)",
    ["msg_vid_skipped"]                 = "Video saltato (già visto)",
    ["msg_vid_id_skipped"]              = "Video #%d saltato",
    ["msg_cin_cleared"]                 = "Cronologia filmati cancellata",

    -- AutoSummon
    ["msg_sum_accepted"]                = "Evocazione accettata da %s verso %s (%s)",
    ["msg_sum_ignored"]                 = "Evocazione ignorata da %s (non fidato)",
    ["msg_sum_enabled"]                 = "Auto-evocazione attivata",
    ["msg_sum_disabled"]                = "Auto-evocazione disattivata",
    ["msg_sum_manual"]                  = "Evocazione accettata manualmente",
    ["msg_sum_no_pending"]              = "Nessuna evocazione in sospeso",

    -- MythicKeys
    ["msg_keys_no_key"]                 = "Nessuna chiave da inviare.",
    ["msg_keys_not_in_group"]           = "Devi essere in un gruppo.",
    ["msg_keys_reload"]                 = "Modifica applicata al prossimo /reload.",
    ["mk_not_in_group"]                 = "Non sei in un gruppo.",
    ["mk_not_in_group_short"]           = "Non in gruppo.",
    ["mk_no_key_self"]                  = "Nessuna chiave del trionfo trovata.",
    ["mk_title"]                        = "TM — Chiavi Mitiche",
    ["mk_btn_send"]                     = "Invia in chat",
    ["mk_btn_refresh"]                  = "Aggiorna",
    ["mk_tab_keys"]                     = "Chiavi",
    ["mk_tab_tp"]                       = "TP",
    ["mk_tp_click_to_tp"]              = "Clicca per teletrasportarti",
    ["mk_tp_not_unlocked"]             = "Non sbloccato",
    ["msg_tp_not_owned"]               = "Non possiedi il teletrasporto per %s",
    ["msg_tp_combat"]                  = "Impossibile aggiornare i teletrasporti in combattimento.",

    -- =====================
    -- PRINT MESSAGES: Config Panels
    -- =====================
    ["msg_np_reset"]                    = "Nameplates ripristinate (ricarica consigliata)",
    ["msg_uf_toggle"]                   = "UnitFrames %s (ricarica)",
    ["msg_profile_reset"]               = "%s ripristinato",
    ["msg_profile_copied"]              = "Impostazioni attuali copiate in '%s'",
    ["msg_profile_deleted"]             = "Profilo eliminato per '%s'",
    ["msg_profile_loaded"]              = "Profilo '%s' caricato — ricarica per applicare",
    ["msg_profile_load_failed"]         = "Caricamento del profilo '%s' fallito",
    ["msg_profile_created"]             = "Profilo '%s' creato con le impostazioni attuali",
    ["msg_profile_name_empty"]          = "Inserisci un nome per il profilo",
    ["msg_profile_saved"]               = "Impostazioni salvate nel profilo '%s'",

    -- New profile keys v2.3.0
    ["btn_rename_profile"]              = "Rinomina",
    ["btn_duplicate_profile"]           = "Duplica",
    ["btn_load_profile"]                = "Carica",
    ["btn_close"]                       = "Chiudi",
    ["btn_cancel"]                      = "Annulla",
    ["section_spec_assign"]             = "Profili per specializzazione",
    ["info_spec_assign"]                = "Assegna ogni specializzazione a un profilo con nome. TomoMod cambierà automaticamente profilo quando cambi specializzazione.",
    ["spec_profile_none"]               = "— Nessuno —",
    ["popup_rename_profile"]            = "|cff0cd29fTomoMod|r\n\nNuovo nome per '%s':",
    ["popup_duplicate_profile"]         = "|cff0cd29fTomoMod|r\n\nDuplica '%s' come:",
    ["msg_profile_renamed"]             = "Profilo '%s' rinominato in '%s'",
    ["msg_profile_duplicated"]          = "Profilo '%s' duplicato come '%s'",
    ["msg_import_as_profile"]           = "Profilo importato come '%s'",
    ["popup_export_title"]              = "Esporta profilo",
    ["popup_export_hint"]               = "Seleziona tutto (Ctrl+A) e copia (Ctrl+C)",
    ["popup_import_title"]              = "Importa profilo",
    ["popup_import_hint"]               = "Incolla una stringa di esportazione TomoMod, poi clicca su Importa",
    ["label_import_profile_name"]       = "Salva come nome profilo:",
    ["placeholder_import_profile_name"] = "Nome profilo (opzionale)...",
    ["msg_profile_name_deleted"]        = "Profilo '%s' eliminato",
    ["msg_export_success"]              = "Stringa di esportazione generata — seleziona tutto e copia",
    ["msg_import_success"]              = "Impostazioni importate con successo — ricaricamento...",
    ["msg_import_empty"]                = "Niente da importare — incolla prima una stringa",
    ["msg_copy_hint"]                   = "Testo selezionato — premi Ctrl+C per copiare",
    ["msg_copy_empty"]                  = "Genera prima una stringa di esportazione",
    ["msg_paste_hint"]                  = "Premi Ctrl+V per incollare la stringa di importazione",
    ["msg_spec_changed_reload"]         = "Specializzazione cambiata — caricamento profilo...",

    -- =====================
    -- INFO PANEL (Minimap)
    -- =====================
    ["time_server"]                     = "Server",
    ["time_local"]                      = "Locale",
    ["time_tooltip_title"]              = "Orario (%s - %s)",
    ["time_tooltip_left_click"]         = "|cff0cd29fClic sinistro:|r Calendario",
    ["time_tooltip_right_click"]        = "|cff0cd29fClic destro:|r Server / Locale",
    ["time_tooltip_shift_right"]        = "|cff0cd29fShift + Clic destro:|r 12h / 24h",
    ["time_format_msg"]                 = "Formato: %s",
    ["time_mode_msg"]                   = "Orario: %s",

    -- =====================
    -- ENABLED / DISABLED (generic)
    -- =====================
    ["enabled"]                         = "Attivato",
    ["disabled"]                        = "Disattivato",

    -- Static Popups
    ["popup_reset_text"]                = "|cff0cd29fTomoMod|r\n\nRipristinare TUTTE le impostazioni?\nQuesto ricaricherà l'interfaccia.",
    ["popup_confirm"]                   = "Conferma",
    ["popup_cancel"]                    = "Annulla",
    ["popup_import_text"]               = "|cff0cd29fTomoMod|r\n\nImportare le impostazioni?\nQuesto SOVRASCRIVERÀ tutte le impostazioni attuali e ricaricherà l'interfaccia.",
    ["popup_profile_reload"]            = "|cff0cd29fTomoMod|r\n\nModalità profilo cambiata.\nRicaricare l'interfaccia per applicare?",
    ["popup_delete_profile"]            = "|cff0cd29fTomoMod|r\n\nEliminare il profilo '%s'?\nQuesta azione non può essere annullata.",

    -- FPS element
    ["label_fps"]                       = "FPS",

    -- =====================
    -- BOSS FRAMES
    -- =====================
    ["tab_boss"]                        = "Boss",
    ["section_boss_frames"]             = "Barre boss",
    ["opt_boss_enable"]                 = "Attiva barre boss",
    ["opt_boss_height"]                 = "Altezza barre",
    ["opt_boss_spacing"]                = "Spaziatura tra le barre",
    ["info_boss_drag"]                  = "Sblocca (/tm uf) per spostare. Trascina Boss 1 per riposizionare tutte e 5 le barre insieme.",
    ["info_boss_colors"]                = "I colori delle barre usano i colori di classificazione Nameplate (Boss = rosso, Mini-boss = viola).",
    ["msg_boss_initialized"]            = "Barre boss caricate.",

    -- =====================
    -- SOUND / LUST DETECTION
    -- =====================
    ["cat_sound"]                       = "Suono",
    ["section_sound_general"]           = "Suono Bloodlust",
        ["info_sound_desc"]                 = "Riproduce un suono personalizzato quando viene rilevato un effetto Bloodlust. Il rilevamento verifica direttamente i buff di Lust e i debuff Sated/Exhaustion.",
    ["opt_sound_enable"]                = "Attiva rilevamento Bloodlust",
    ["sublabel_sound_choice"]           = "Suono e canale",
    ["opt_sound_file"]                  = "Suono da riprodurre",
    ["opt_sound_channel"]               = "Canale audio",
    ["btn_sound_preview"]               = ">> Ascolta suono",
    ["btn_sound_stop"]                  = "■  Ferma",
    ["opt_sound_chat"]                  = "Mostra messaggi in chat",
        ["opt_sound_debug"]                 = "Mode debug",

    -- =====================
    -- BAG & MICRO MENU
    -- =====================
    ["tab_qol_bag_micro"]               = "Borsa e menu",
    ["section_bag_micro"]               = "Barra borse e micro menu",
    ["info_bag_micro"]                  = "Scegli se mostrare sempre o rivelare al passaggio del mouse.",
    ["sublabel_bag_bar"]                = "— Barra borse —",
    ["sublabel_micro_menu"]             = "— Micro menu —",
    ["opt_bag_bar_mode"]                = "Barra borse",
    ["opt_micro_menu_mode"]             = "Micro menu",
    ["mode_show"]                       = "Sempre visibile",
    ["mode_hover"]                      = "Mostra al passaggio del mouse",

    -- =====================
    -- CHARACTER SKIN
    -- =====================
    ["tab_qol_char_skin"]               = "Skin personaggio",
    ["section_char_skin"]               = "Skin scheda personaggio",
    ["info_char_skin_desc"]             = "Applica il tema scuro TomoMod alla scheda personaggio, reputazione, valute e finestra di ispezione.",
    ["opt_char_skin_enable"]            = "Attiva skin personaggio",
    ["opt_char_skin_character"]         = "Skin Personaggio / Reputazione / Valute",
    ["opt_char_skin_inspect"]           = "Skin finestra di ispezione",
    ["opt_char_skin_iteminfo"]          = "Mostra info oggetto sugli slot",
    ["opt_char_skin_gems"]              = "Mostra gemme sugli slot",
    ["opt_char_skin_midnight"]          = "Incantamenti Midnight (Testa/Spalle invece di Polsi/Mantello)",
    ["opt_char_skin_scale"]             = "Scala finestra",
    ["msg_char_skin_reload"]            = "Skin personaggio: /reload per applicare le modifiche.",

    -- =====================
    -- LAYOUT / MOVERS SYSTEM
    -- =====================
    ["btn_layout"]                      = "Layout",
    ["btn_layout_tooltip"]              = "Modalità Layout: sblocca tutti gli elementi per spostarli.",
    ["btn_reload_ui"]                   = "Ricarica interfaccia",
    ["layout_mode_title"]               = "TomoMod — Modalità Layout",
    ["layout_mode_hint"]                = "Trascina gli elementi per riposizionare — clicca Blocca quando hai finito",
    ["layout_btn_lock"]                 = "Blocca",
    ["layout_btn_reload"]               = "RL",
    ["grid_dimmed"]                    = "Griglia",
    ["grid_bright"]                    = "Griglia +",
    ["grid_disabled"]                  = "Griglia OFF",
    ["layout_unlocked"]                 = "Modalità Layout ATTIVA — trascina gli elementi. Clicca Blocca o /tm layout quando hai finito.",
    ["layout_locked"]                   = "Modalità Layout DISATTIVATA — posizioni salvate.",
    ["msg_help_layout"]                 = "Attiva/disattiva modalità Layout (sposta tutti gli elementi UI)",
    ["mover_unitframes"]                = "Unit Frames",
    ["mover_resources"]                 = "Barre risorse",
    ["mover_skyriding"]                 = "Barra Skyriding",
    ["mover_levelingbar"]               = "Barra XP / Esperienza",
    ["mover_anchors"]                   = "Ancore avvisi e bottino",
    ["mover_cotank"]                    = "Tracciatore Co-Tank",
    ["mover_repbar"]                    = "Barra reputazione",
    ["mover_castbar"]                   = "Barra di lancio (giocatore)",

    -- =====================
    -- COMBAT TEXT
    -- =====================
    ["sublabel_combat_text"]             = "— Testo di combattimento —",
    ["opt_combat_text_enable"]           = "Attiva testo di combattimento",
    ["opt_combat_text_offset_x"]         = "Offset X",
    ["opt_combat_text_offset_y"]         = "Offset Y",

    -- =====================
    -- SKINS (Chat)
    -- =====================
    ["tab_qol_skins"]                    = "Skins",
    ["section_skins"]                    = "Skin dell'interfaccia",
    ["info_skins_desc"]                  = "Applica il tema scuro TomoMod a vari elementi dell'interfaccia Blizzard. Potrebbe essere necessario /reload per ripristinare.",
    ["sublabel_chat_skin"]               = "— Finestra chat —",
    ["opt_chat_skin_enable"]             = "Skin della finestra chat",
    ["opt_chat_skin_bg_alpha"]           = "Opacità dello sfondo",
    ["opt_chat_skin_font_size"]          = "Dimensione font chat",
    ["msg_chat_skin_enabled"]            = "Skin della chat attivato",
    ["msg_chat_skin_disabled"]           = "Skin della chat disattivato (reload per ripristinare)",
    ["sublabel_mail_skin"]               = "— Posta —",
    ["opt_mail_skin_enable"]             = "Skin della posta",
    ["msg_mail_skin_enabled"]            = "Skin della posta attivato",
    ["msg_mail_skin_disabled"]           = "Skin della posta disattivato (reload per ripristinare)",

    -- =====================
    -- WORLD QUEST TAB
    -- =====================
    ["tab_qol_world_quests"]             = "Missioni mondo",
    ["section_wq_tab"]                   = "Tab missioni del mondo",
    ["info_wq_tab_desc"]                 = "Mostra un elenco delle missioni del mondo disponibili accanto alla mappa del mondo con dettagli su ricompense, zona, fazione e tempo rimanente. Clicca su una missione per navigare alla sua zona, Shift-Clic per super-tracciare.",
    ["opt_wq_enable"]                    = "Attiva tab missioni del mondo",
    ["opt_wq_auto_show"]                 = "Mostra automaticamente all'apertura della mappa",
    ["opt_wq_max_quests"]                = "Max missioni mostrate (0 = illimitato)",
    ["opt_wq_min_time"]                  = "Tempo rimanente min. (minuti, 0 = tutte)",
    ["section_wq_filters"]               = "Filtri ricompense",
    ["opt_wq_filter_gold"]               = "Mostra ricompense oro",
    ["opt_wq_filter_gear"]               = "Mostra ricompense equipaggiamento",
    ["opt_wq_filter_rep"]                = "Mostra ricompense reputazione",
    ["opt_wq_filter_currency"]           = "Mostra ricompense valuta",
    ["opt_wq_filter_anima"]              = "Mostra ricompense anima",
    ["opt_wq_filter_pet"]                = "Mostra ricompense mascotte",
    ["opt_wq_filter_other"]              = "Mostra altre ricompense",
    ["wq_tab_title"]                     = "MM Lista",
    ["wq_panel_title"]                   = "Missioni del mondo",
    ["wq_col_name"]                      = "Nome",
    ["wq_col_zone"]                      = "Zona",
    ["wq_col_reward"]                    = "Ricompensa",
    ["wq_col_time"]                      = "Tempo",
    ["wq_zone"]                          = "Zona",
    ["wq_faction"]                       = "Fazione",
    ["wq_reward"]                        = "Ricompensa",
    ["wq_time_left"]                     = "Tempo rimanente",
    ["wq_elite"]                         = "Missione del mondo élite",
    ["wq_sort_time"]                     = "Tempo",
    ["wq_sort_zone"]                     = "Zona",
    ["wq_sort_name"]                     = "Nome",
    ["wq_sort_reward"]                   = "Ricompensa",
    ["wq_sort_faction"]                  = "Fazione",
    ["wq_status_count"]                  = "Mostrando %d / %d missioni",

    -- Profession Helper
    ["tab_qol_prof_helper"]              = "Professioni",
    ["section_prof_helper"]              = "Assistente professioni",
    ["info_prof_helper_desc"]            = "Disincanta, macina e prospezione di oggetti in blocco con un'interfaccia visiva.",
    ["opt_prof_helper_enable"]           = "Attiva assistente professioni",
    ["sublabel_prof_de_filters"]         = "— Filtri qualità disincantamento —",
    ["opt_prof_filter_green"]            = "Includi oggetti Non comuni (Verdi)",
    ["opt_prof_filter_blue"]             = "Includi oggetti Rari (Blu)",
    ["opt_prof_filter_epic"]             = "Includi oggetti Epici (Viola)",
    ["btn_prof_open_helper"]             = "Apri assistente professioni",
    ["ph_title"]                         = "Assistente professioni",
    ["ph_tab_disenchant"]                = "Disincanta",
    ["ph_filter_quality"]                = "Qualità:",
    ["ph_quality_green"]                 = "Verde",
    ["ph_quality_blue"]                  = "Blu",
    ["ph_quality_epic"]                  = "Epico",
    ["ph_select_all"]                    = "Seleziona tutto",
    ["ph_deselect_all"]                  = "Deseleziona tutto",
    ["ph_btn_process"]                   = "Elabora",
    ["ph_btn_click_process"]             = "Clicca per elaborare",
    ["ph_btn_stop"]                      = "Ferma",
    ["ph_status_idle"]                   = "Clicca su Elabora",
    ["ph_status_processing"]             = "Elaborazione %d/%d: %s",
    ["ph_status_done"]                   = "Fatto! Tutti gli oggetti elaborati.",
    ["ph_item_count"]                    = "%d oggetti disponibili",
    ["ph_ilvl"]                          = "iLvl %d",
})
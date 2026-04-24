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
    ["cat_mythicplus"]      = "Mythic+",
    ["cat_profiles"]        = "Profili",
    ["cat_diagnostics"]     = "Diagnostica",
    ["cat_housing"]         = "Housing",

    -- =====================
    -- CONFIG: General Panel
    -- =====================
    ["section_about"]                   = "Informazioni",
    ["about_text"]                      = "|cff0cd29fTomoMod|r %s di TomoAniki\nInterfaccia leggera con QOL, UnitFrames e Nameplates.\nDigita /tm help per la lista dei comandi.",
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
    ["opt_raid_icon_x"]                 = "Marcatore raid X",
    ["opt_raid_icon_y"]                 = "Marcatore raid Y",

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
    ["opt_np_friendly_name_only"]       = "Alleati: solo nome (senza barra vita)",
    ["opt_np_friendly_role_icons"]      = "Mostra icone ruolo (dungeon/delve)",
    ["opt_np_role_show_tank"]           = "Mostra icona Tank",
    ["opt_np_role_show_healer"]         = "Mostra icona Healer",
    ["opt_np_role_show_dps"]            = "Mostra icona DPS",
    ["opt_np_role_icon_size"]           = "Dimensione icona ruolo",

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
    ["info_cdm_editmode"]               = "Il posizionamento avviene tramite l'Edit Mode di Blizzard (Esc |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Edit Mode).",

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
    ["opt_rb_classpower_height"]        = "Altezza potere di classe",
    ["opt_rb_druidmana_height"]         = "Altezza mana druido",
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
    ["info_rb_druid"]                   = "Le barre si adattano automaticamente alla tua classe e specializzazione.\nDruido: la risorsa cambia in base alla forma (Orso |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Ira, Gatto |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Energia, Gufo |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Potere astrale).",

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
    ["import_preview_valid"]            = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t Stringa valida",
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
    ["msg_report_issue"]                = "Se riscontri un problema, lascia un commento su CurseForge.",
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
    ["opt_sound_force"]                 = "Forza il suono anche se il gioco è in muto",
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
    ["mover_mythictracker"]             = "Tracker M+",
    ["mover_chatframe"]                 = "Finestra chat",

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
    ["opt_chat_skin_style"]              = "Stile skin",
    ["opt_chat_skin_style_tui"]          = "TUI (Barra laterale + Finestra)",
    ["opt_chat_skin_style_classic"]      = "Classico (Incorniciato)",
    ["opt_chat_skin_style_glass"]        = "Vetro (Smerigliato)",
    ["opt_chat_skin_style_minimal"]      = "Minimale (Senza bordi)",
    ["opt_chat_skin_bg_alpha"]           = "Opacità dello sfondo",
    ["opt_chat_skin_font_size"]          = "Dimensione font chat",
    ["opt_chat_skin_fade"]               = "Fade chat when inactive",
    ["opt_chat_skin_short_channels"]     = "Short channel names (G, P, R…)",
    ["opt_chat_skin_timestamp"]          = "Show timestamps",
    ["opt_chat_skin_url"]                = "Clickable URLs",
    ["opt_chat_skin_emoji"]              = "Replace text emoticons with emoji",
    ["opt_chat_skin_class_colors"]       = "Class-color player names in chat",
    ["opt_chat_skin_history"]            = "Restore chat history on login",
    ["opt_chat_skin_copy_lines"]         = "Show copy icon per message",

    -- Buff Skin
    ["sublabel_buff_skin"]               = "— Skin Buff / Debuff —",
    ["opt_buff_skin_enable"]             = "Skin delle icone Buff/Debuff",
    ["opt_buff_skin_buffs"]              = "Applica ai Buff",
    ["opt_buff_skin_debuffs"]            = "Applica ai Debuff",
    ["opt_buff_skin_color_by_type"]       = "Colora il bordo per tipo di debuff (Magia/Veleno/Maledizione…)",
    ["opt_buff_skin_teal_border"]         = "Bordo verde acqua sui buff",
    ["opt_buff_skin_desaturate"]          = "Desatura le icone dei debuff",
    ["opt_buff_skin_hide_buffs"]         = "Nascondi riquadro Buff",
    ["opt_buff_skin_hide_debuffs"]       = "Nascondi riquadro Debuff",
    ["opt_buff_skin_font_size"]          = "Dimensione font timer",

    -- Game Menu Skin
    ["sublabel_game_menu_skin"]          = "— Menu di gioco (Escape) —",
    ["opt_game_menu_skin_enable"]        = "Skin del menu di gioco",
    ["info_game_menu_skin_reload"]       = "Necessario /reload per annullare la skin.",
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

    -- ── Class Reminder ──────────────────────────────────────────
    ["tab_qol_class_reminder"]           = "Promemoria classe",
    ["section_class_reminder"]           = "Promemoria buff / forma di classe",
    ["info_class_reminder"]              = "Mostra un testo pulsante al centro dello schermo quando manca un buff di classe, una forma, una postura o un'aura.",
    ["opt_class_reminder_enable"]        = "Attiva promemoria classe",
    ["opt_class_reminder_scale"]         = "Scala del testo",
    ["opt_class_reminder_color"]         = "Colore del testo",
    ["sublabel_class_reminder_pos"]      = "— Offset posizione —",
    ["opt_class_reminder_x"]             = "Offset X",
    ["opt_class_reminder_y"]             = "Offset Y",

    -- Buff / Form names
    ["cr_fortitude"]                     = "Parola del Potere: Tempra",
    ["cr_shadowform"]                    = "Forma d'Ombra",
    ["cr_arcane_intellect"]              = "Intelletto Arcano",
    ["cr_skyfury"]                       = "Furia Celeste",
    ["cr_mark_of_the_wild"]              = "Marchio del Selvaggio",
    ["cr_cat_form"]                      = "Forma di Felino",
    ["cr_bear_form"]                     = "Forma di Orso",
    ["cr_moonkin_form"]                  = "Forma di Lunagufo",
    ["cr_battle_shout"]                  = "Grido di Battaglia",
    ["cr_stance"]                        = "Postura",
    ["cr_aura"]                          = "Aura",
    ["cr_blessing_bronze"]               = "Benedizione del Bronzo",

    -- =====================
    -- MYTHIC TRACKER (TomoMythic integration)
    -- =====================
    ["tmt_cmd_usage"]               = "|cFF55B400/tmt|r : configurazione  |  |cFF55B400unlock|r : sposta  |  |cFF55B400lock|r : blocca  |  |cFF55B400preview|r : anteprima  |  |cFF55B400key|r : chiavi del gruppo  |  |cFF55B400kr|r : roulette",
    ["tmt_unlock_msg"]              = "|cff0cd29fTomoMod|r M+ Tracker: Riquadro sbloccato \226\128\148 trascina per riposizionare.",
    ["tmt_lock_msg"]                = "|cff0cd29fTomoMod|r M+ Tracker: Riquadro bloccato.",
    ["tmt_reset_msg"]               = "|cff0cd29fTomoMod|r M+ Tracker: Posizione reimpostata.",
    ["tmt_unknown_cmd"]             = "|cff0cd29fTomoMod|r M+ Tracker: Comando sconosciuto.",
    ["tmt_key_level"]               = "+%d",
    ["tmt_dungeon_unknown"]         = "Mitico+",
    ["tmt_overtime"]                = "TEMPO SCADUTO",
    ["tmt_completed_on_time"]       = "COMPLETATO",
    ["tmt_completed_depleted"]      = "FALLITO",
    ["tmt_forces"]                  = "FORZE",
    ["tmt_forces_done"]             = "COMPLETO",
    ["tmt_forces_pct"]              = "%.1f%%",
    ["tmt_forces_count"]            = "%d / %d",
    ["tmt_cfg_title"]               = "Mythic",
    ["tmt_cfg_panel_enable"]         = "Abilita tracker M+",
    ["tmt_cfg_show_timer"]          = "Mostra barra del timer",
    ["tmt_cfg_show_forces"]         = "Mostra forze nemiche",
    ["tmt_cfg_show_bosses"]         = "Mostra timer dei boss",
    ["tmt_cfg_hide_blizzard"]       = "Nascondi tracker di Blizzard",
    ["tmt_cfg_lock"]                = "Blocca riquadro",
    ["tmt_cfg_scale"]               = "Scala",
    ["tmt_cfg_alpha"]               = "Opacità sfondo",
    ["tmt_cfg_reset_pos"]           = "Reimposta posizione",
    ["tmt_cfg_preview"]             = "Anteprima",
    ["tmt_cfg_section_display"]     = "Visualizzazione",
    ["tmt_cfg_section_frame"]       = "Riquadro",
    ["tmt_cfg_section_actions"]     = "Azioni",
    ["tmt_key_not_available"]       = "non disponibile.",
    ["tmt_key_not_in_group"]        = "Non sei in un gruppo.",
    ["tmt_key_none_found"]          = "Nessuna chiave trovata.",
    ["tmt_kr_spin"]                 = "|TInterface\\Icons\\INV_Misc_Dice_02:14|t  Gira!",
    ["tmt_preview_active"]          = "|cff0cd29fTomoMod|r M+ Tracker: Anteprima attiva \226\128\148 |cFF55B400/tmt lock|r per bloccare.",

    -- MythicHub
    ["mhub_title"]                  = "Punteggio Mitica+",
    ["mhub_col_dungeon"]            = "Spedizione",
    ["mhub_col_level"]              = "Livello",
    ["mhub_col_rating"]             = "Punteggio",
    ["mhub_col_best"]               = "Migliore",
    ["mhub_tp_click"]               = "Clicca per teletrasportarti",
    ["mhub_tp_not_available"]        = "Teletrasporto non appreso",
    ["mhub_tp_not_learned"]          = "|cff0cd29fTomoMod|r: Incantesimo di teletrasporto non appreso.",
    ["mhub_vault_title"]            = "Grande Camera Blindata",
    ["mhub_vault_dungeons"]         = "Spedizioni",
    ["mhub_vault_raids"]            = "Incursioni",
    ["mhub_vault_world"]            = "Abissi",
    ["mhub_vault_ilvl"]             = "Livello oggetto",
    ["mhub_vault_locked"]           = "Bloccato",
    ["mhub_vault_claim"]            = "Torna alla Grande Camera Blindata per riscuotere la tua ricompensa",

    -- ══════════════════════════════════════════════════════════
    -- INSTALLER
    -- ══════════════════════════════════════════════════════════

    -- Navigation
    ["ins_header_title"]             = "|cff0cd29fTomo|r|cffe4e4e4Mod|r  \226\128\148  Assistente di configurazione",
    ["ins_step_counter"]             = "Passaggio %d / %d",
    ["ins_btn_prev"]                 = "|TInterface\\BUTTONS\\UI-SpellbookIcon-PrevPage:0|t Precedente",
    ["ins_btn_next"]                 = "Avanti |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t",
    ["ins_btn_finish"]               = "Termina |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t",
    ["ins_btn_skip"]                 = "Salta l'installazione",

    -- Step 1: Welcome
    ["ins_step1_title"]              = "Benvenuto in TomoMod",
    ["ins_subtitle"]                 = "Suite di interfaccia e QOL per The War Within",
    ["ins_welcome_desc"]             = "Questo assistente ti guider\195\160 in |cff0cd29f16 passaggi|r per configurare TomoMod\nsecondo le tue preferenze: unit frame, party frame, barre di lancio, nameplate, barre azione,\nrisorse, skin, suoni, Mythic+, QOL, ottimizzazioni e SkyRide.\n\nTutte queste opzioni possono essere modificate in qualsiasi momento con |cff0cd29f/tm|r.",

    -- Step 2: Profile
    ["ins_step2_title"]              = "Profilo di gioco",
    ["ins_profile_info"]             = "Crea un profilo con nome per salvare la tua configurazione.",
    ["ins_profile_section"]          = "Nome del profilo",
    ["ins_profile_placeholder"]      = "Il mio profilo",
    ["ins_profile_create"]           = "Crea profilo",
    ["ins_profile_created"]          = "Profilo creato: ",
    ["ins_spec_section"]             = "Assegnazione specializzazioni",
    ["ins_spec_info"]                = "Puoi assegnare questo profilo alle tue spec dal pannello Profili (/tm).\nOgni spec pu\195\178 usare una configurazione diversa.",

    -- Step 3: Visual Skins
    ["ins_step3_title"]              = "Skin visive",
    ["ins_skins_info"]               = "Personalizza l'interfaccia Blizzard con il tema scuro di TomoMod.",
    ["ins_skins_section"]            = "Skin disponibili",
    ["ins_skin_gamemenu"]            = "Skin del menu di gioco (Escape)",
    ["ins_skin_actionbar"]           = "Skin dei pulsanti barra azione",
    ["ins_skin_buffs"]               = "Skin buff / debuff",
    ["ins_skin_chat"]                = "Skin della chat",
    ["ins_skin_character"]           = "Skin della scheda personaggio",
    ["ins_skin_style_section"]       = "Stile pulsanti barra azione",
    ["ins_skin_style"]               = "Stile visivo",

    -- Step 4: Tank Mode
    ["ins_step4_title"]              = "Modalit\195\160 Tank",
    ["ins_tank_info"]                = "In modalit\195\160 tank, le nameplate e gli UnitFrame mostrano\nlo stato di minaccia a colori per ogni nemico.",
    ["ins_tank_np_section"]          = "Nameplate \226\128\148 Colori minaccia",
    ["ins_tank_enable_np"]           = "Attiva modalit\195\160 tank (nameplate)",
    ["ins_tank_colors_info"]         = "Verde = hai l'aggro  \194\183  Arancione = stai per perderlo  \194\183  Rosso = aggro perso",
    ["ins_tank_uf_section"]          = "UnitFrame \226\128\148 Indicatore di minaccia",
    ["ins_tank_threat_indicator"]    = "Mostra indicatore di minaccia sul bersaglio",
    ["ins_tank_threat_text"]         = "Mostra testo minaccia % sul bersaglio",
    ["ins_tank_cotank_section"]      = "CoTank Tracker",
    ["ins_tank_cotank_enable"]       = "Attiva tracciamento co-tank",
    ["ins_tank_cotank_info"]         = "Mostra la minaccia del secondo tank nelle istanze.",

    -- Step 5: Nameplates
    ["ins_step5_title"]              = "Nameplate",
    ["ins_np_general"]               = "Generale",
    ["ins_np_enable"]                = "Attiva nameplate di TomoMod",
    ["ins_np_reload_info"]           = "\195\136 necessario un reload per attivare/disattivare le nameplate.",
    ["ins_np_display"]               = "Visualizzazione",
    ["ins_np_class_colors"]          = "Colori di classe",
    ["ins_np_castbar"]               = "Mostra barra di lancio",
    ["ins_np_health_text"]           = "Mostra testo salute (percentuale)",
    ["ins_np_auras"]                 = "Mostra aure (debuff)",
    ["ins_np_role_icons"]            = "Mostra icone ruolo (dungeon)",
    ["ins_np_dimensions"]            = "Dimensioni",
    ["ins_np_width"]                 = "Larghezza",

    -- Step 6: Action Bars
    ["ins_step6_title"]              = "Barre azione",
    ["ins_ab_skin_section"]          = "Skin pulsanti",
    ["ins_ab_enable"]                = "Attiva skin sui pulsanti azione",
    ["ins_ab_class_color"]           = "Colore bordo = colore di classe",
    ["ins_ab_shift_reveal"]          = "Tieni Shift per mostrare le barre nascoste",
    ["ins_ab_opacity_section"]       = "Opacit\195\160 globale barre",
    ["ins_ab_opacity"]               = "Opacit\195\160",
    ["ins_ab_manage_section"]        = "Gestione barre",
    ["ins_ab_manage_info"]           = "Usa il pannello Barre azione (/tm |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Barre azione |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Gestione)\nper sbloccare e riposizionare ogni barra.",

    -- Step 7: LustSound
    ["ins_step7_title"]              = "Suono \226\128\148 Eroismo / Sete di sangue",
    ["ins_sound_info"]               = "Riproduce un suono personalizzato quando Eroismo o Sete di sangue\nviene lanciato da un membro del gruppo.",
    ["ins_sound_activation"]         = "Attivazione",
    ["ins_sound_enable"]             = "Attiva suono lust",
    ["ins_sound_choice"]             = "Selezione suono",
    ["ins_sound_sound"]              = "Suono",
    ["ins_sound_channel"]            = "Canale audio",
    ["ins_sound_default"]            = "Predefinito",
    ["ins_sound_preview_section"]    = "Anteprima",
    ["ins_sound_preview_btn"]        = "|TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Anteprima",

    -- Step 8: Mythic+
    ["ins_step8_title"]              = "Mythic+ \226\128\148 Tracker e Classifica",
    ["ins_mplus_tracker_section"]    = "M+ Tracker",
    ["ins_mplus_tracker_info"]       = "Mostra un timer, le forze, i boss e il progresso\ndel tuo dungeon Mythic+ in tempo reale.",
    ["ins_mplus_tracker_enable"]     = "Attiva M+ Tracker",
    ["ins_mplus_show_timer"]         = "Mostra timer",
    ["ins_mplus_show_forces"]        = "Mostra forze (%)",
    ["ins_mplus_hide_blizzard"]      = "Nascondi interfaccia Blizzard in Mythic+",
    ["ins_mplus_score_section"]      = "TomoScore \226\128\148 Classifica",
    ["ins_mplus_score_info"]         = "Mostra i punteggi personali e di gruppo alla fine di un Mythic+.",
    ["ins_mplus_score_enable"]       = "Attiva TomoScore",
    ["ins_mplus_score_auto"]         = "Mostra automaticamente in M+",

    -- Step 9: CVars
    ["ins_step9_title"]              = "Ottimizzazioni di sistema (CVars)",
    ["ins_cvar_info"]                = "TomoMod pu\195\178 applicare un set di CVars WoW consigliate\nper migliorare prestazioni e reattivit\195\160.",
    ["ins_cvar_section"]             = "Ottimizzazioni incluse",
    ["ins_cvar_opt1"]                = "Ridurre il Level of Detail (LOD) non necessario",
    ["ins_cvar_opt2"]                = "Ottimizzare il frustum culling",
    ["ins_cvar_opt3"]                = "Disattivare il temporal AA eccessivo",
    ["ins_cvar_opt4"]                = "Migliorare la reattivit\195\160 di rete",
    ["ins_cvar_opt5"]                = "Disattivare le animazioni UI non necessarie",
    ["ins_cvar_opt6"]                = "Ottimizzare lo streaming delle texture",
    ["ins_cvar_success"]             = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t  CVars applicate con successo!",
    ["ins_cvar_apply_btn"]           = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0|t Applica tutte le CVars",
    ["ins_cvar_applied"]             = "CVars ottimizzate applicate.",

    -- Step 10: QOL
    ["ins_step10_title"]             = "Qualit\195\160 della vita (QOL)",
    ["ins_qol_info"]                 = "Attiva i moduli QOL che desideri.\nTutti sono accessibili separatamente in /tm |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t QOL.",
    ["ins_qol_auto_section"]         = "Automatismi",
    ["ins_qol_auto_repair"]          = "Ripara automaticamente dal mercante",
    ["ins_qol_fast_loot"]            = "Loot veloce (raccolta rapida degli oggetti)",
    ["ins_qol_skip_cinematics"]      = "Salta cinematiche gi\195\160 viste",
    ["ins_qol_hide_talking_head"]    = "Nascondi Talking Head (dialoghi a scorrimento)",
    ["ins_qol_auto_accept"]          = "Accetta inv. di gruppo automaticamente (amici e gilda)",
    ["ins_qol_tooltip_ids"]          = "Mostra ID nei tooltip (spell ID, item ID...)",
    ["ins_qol_combat_section"]       = "Combattimento",
    ["ins_qol_combat_text"]          = "Testo di combattimento fluttuante personalizzato",
    ["ins_qol_hide_castbar"]         = "Nascondi barra di lancio Blizzard (usa quella di TomoMod)",

    -- Step 11: SkyRide
    ["ins_step11_title"]             = "SkyRide \226\128\148 Barra cavalcatura draconica",
    ["ins_skyride_info"]             = "SkyRide mostra una barra Vigore (6 cariche) e una barra\nSecondo Respiro (3 cariche) per la cavalcatura draconica.",
    ["ins_skyride_activation"]       = "Attivazione",
    ["ins_skyride_enable"]           = "Attiva barra SkyRide",
    ["ins_skyride_auto_info"]        = "La barra appare automaticamente in modalit\195\160 volo draconico\ne si nasconde al di fuori.",
    ["ins_skyride_dimensions"]       = "Dimensioni",
    ["ins_skyride_width"]            = "Larghezza",
    ["ins_skyride_height"]           = "Altezza",
    ["ins_skyride_reset_section"]    = "Ripristina posizione",
    ["ins_skyride_reset_btn"]        = "Ripristina posizione",

    -- Step 12: Done
    ["ins_step12_title"]             = "Configurazione completata!",
    ["ins_done_check"]               = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t  Tutto pronto!",
    ["ins_done_recap"]               = "La tua configurazione TomoMod \195\168 salvata. Ecco alcuni promemoria:\n\n|cff0cd29f/tm|r              |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Apri il pannello di configurazione\n|cff0cd29f/tm sr|r           |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Sblocca e sposta gli elementi\n|cff0cd29f/tm install|r      |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Rilancia questo installatore\n\nTutte le opzioni configurate qui possono essere modificate in qualsiasi momento\ndai pannelli corrispondenti nella GUI di TomoMod.\n\nUn |cff0cd29freload della UI|r \195\168 necessario per applicare alcune modifiche\n(nameplate, skin, UnitFrame).",
    ["ins_done_reload"]              = "|TInterface\\BUTTONS\\UI-RefreshButton:0|t  Ricarica UI",

    -- Step NEW: Unit Frames
    ["ins_uf_title"]                 = "Unit Frame",
    ["ins_uf_info"]                  = "TomoMod sostituisce i frame unit\195\160 predefiniti di Blizzard (giocatore, bersaglio, focus, famiglio)\ncon frame moderni e personalizzabili.",
    ["ins_uf_section"]               = "Generale",
    ["ins_uf_enable"]                = "Attiva UnitFrame di TomoMod",
    ["ins_uf_hide_blizzard"]         = "Nascondi frame predefiniti di Blizzard",
    ["ins_uf_reload_info"]           = "\195\136 necessario un reload per applicare le modifiche agli UnitFrame.",

    -- Step NEW: Party Frames
    ["ins_pf_title"]                 = "Party Frame",
    ["ins_pf_info"]                  = "Frame di gruppo personalizzati con icone ruolo, evidenziazione dispel\ne tracciamento cooldown per il gioco di gruppo.",
    ["ins_pf_section"]               = "Generale",
    ["ins_pf_enable"]                = "Attiva Party Frame di TomoMod",
    ["ins_pf_hide_blizzard"]         = "Nascondi Party Frame di Blizzard",
    ["ins_pf_cd_section"]            = "Tracker cooldown",
    ["ins_pf_cd_info"]               = "Traccia i cooldown di interruzione e resurrezione in combattimento\ndei tuoi compagni direttamente sui loro frame di gruppo.",
    ["ins_pf_show_interrupt"]        = "Mostra tracker cooldown interruzione",
    ["ins_pf_show_brez"]             = "Mostra tracker cooldown resurrezione in combattimento",
    ["ins_pf_reload_info"]           = "\195\136 necessario un reload per applicare le modifiche ai Party Frame.",

    -- Step NEW: Castbars
    ["ins_cb_title"]                 = "Barre di lancio",
    ["ins_cb_info"]                  = "Barre di lancio personalizzate per giocatore, bersaglio, focus e famiglio\ncon animazione scintilla e feedback di interruzione.",
    ["ins_cb_section"]               = "Generale",
    ["ins_cb_enable"]                = "Attiva barre di lancio di TomoMod",
    ["ins_cb_hide_blizzard"]         = "Nascondi barra di lancio predefinita di Blizzard",
    ["ins_cb_class_color"]           = "Usa colore di classe per il riempimento",
    ["ins_cb_reload_info"]           = "\195\136 necessario un reload per applicare le modifiche alle barre di lancio.",

    -- Step NEW: Resource Bars & Cooldown Manager
    ["ins_res_title"]                = "Risorse & Cooldown",
    ["ins_res_info"]                 = "Visualizzazione potere di classe (punti combo, rune, frammenti d'anima, ecc.)\nin modalit\195\160 icona o barra.",
    ["ins_res_section"]              = "Barre risorse",
    ["ins_res_enable"]               = "Attiva barre risorse",
    ["ins_res_display"]              = "Modalit\195\160 di visualizzazione",
    ["ins_cdm_section"]              = "Gestore cooldown",
    ["ins_cdm_info"]                 = "Spirale di cooldown sui pulsanti azione con\nalfa adattivo al combattimento e filtraggio GCD.",
    ["ins_cdm_enable"]               = "Attiva gestore cooldown",
    ["ins_cdm_hide_gcd"]             = "Nascondi spirale GCD",
    ["ins_cdm_desat"]                = "Desatura pulsanti in cooldown",

    -- Enhanced Skins
    ["ins_skin_bag"]                 = "Skin borse",
    ["ins_skin_tooltip"]             = "Skin tooltip",

    -- Enhanced QOL
    ["ins_qol_interface_section"]    = "Interfaccia",
    ["ins_qol_minimap"]              = "Minimappa personalizzata (bordo e scala)",
    ["ins_qol_cursor"]               = "Anello cursore luminoso",
    ["ins_qol_afk"]                  = "Schermata AFK personalizzata con modello 3D",
    ["ins_qol_diag"]                 = "Diagnostica (cattura errori senza popup)",
    ["ins_qol_aura_tracker"]         = "Aura Tracker (trinket, buff, difensivi)",

    -- =========== Config Panels — i18n ===========
    -- ActionBars panel
    ["opt_abs_style"]                = "Stile visivo",
    ["section_bar_opacity"]          = "Opacit\195\160 per barra",
    ["opt_abs_bar_select"]           = "Barra da configurare",
    ["opt_abs_opacity"]              = "Opacit\195\160",
    ["btn_abs_apply_all"]            = "Applica a tutte le barre",
    ["opt_abs_combat_only_label"]    = "Mostra solo in combattimento:",
    ["opt_abs_combat_only"]          = "Barra visibile solo in combattimento",
    ["section_bar_management"]       = "Gestione barre d'azione",
    ["btn_abs_unlock"]               = "Sblocca barre",
    ["info_abs_unlock"]              = "Sblocca le barre per mostrare le maniglie di trascinamento.\nClic destro su una maniglia per configurare una barra singolarmente.",
    ["section_bar_quick"]            = "Impostazioni rapide",
    ["tab_abs_skin"]                 = "Skin pulsanti",
    ["tab_abs_bars"]                 = "Gestione barre",
    -- General panel
    ["btn_relaunch_installer"]       = "Rilancia installatore",
    ["info_relaunch_installer"]      = "Avvia la procedura guidata di configurazione in 16 passaggi.",
    -- Sound panel
    ["section_sound_preview"]        = "Anteprima e opzioni",
    -- UFPreview
    ["preview_header"]               = "ANTEPRIMA DAL VIVO",
    ["preview_player"]               = "Giocatore",
    ["preview_target_name"]          = "Taurache",
    ["preview_focus_name"]           = "Sacerdotessa",
    ["preview_pet_name"]             = "Lupo d'acqua",
    ["preview_tot_name"]             = "Bersaglio-del-bersaglio",
    ["preview_cast_player"]          = "Saetta di Gelo",
    ["preview_cast_target"]          = "Palla di Fuoco",
    ["preview_lbl_player"]           = "GIOCATORE",
    ["preview_lbl_target"]           = "BERSAGLIO",
    ["preview_lbl_focus"]            = "FOCUS",
    ["preview_lbl_pet"]              = "PET",
    ["preview_lbl_tot"]              = "TOT",
    ["preview_click_nav"]            = "clicca per navigare",
    -- ConfigUI footer
    ["ui_footer_hint"]               = "/tm  \194\183  /tm sr per spostare gli elementi",

    -- =====================
    -- SKINS CATEGORY (top-level)
    -- =====================
    ["cat_skins"]                        = "Skins",

    -- Chat Frame V2 — etichette schede e interfaccia
    ["chatv2_tab_general"]               = "Generale",
    ["chatv2_tab_instance"]              = "Istanza",
    ["chatv2_tab_chucho"]                = "Chucho",
    ["chatv2_tab_personnel"]             = "Personale",
    ["chatv2_tab_combat"]                = "Combattimento",
    ["chatv2_sidebar_title"]             = "CHAT",
    ["chatv2_expand_btn"]                = "Chat",
    ["chatv2_mover_label"]               = "Finestra chat V2",
    ["chatv2_input_hint"]                = "Premi Invio per scrivere...",

    -- Skins > Chat Frame tab
    ["tab_skin_chatframe"]               = "Finestra di chat",
    ["section_skin_chatframe"]           = "Skin finestra di chat",
    ["info_skin_chatframe_desc"]         = "Pannello chat con barra laterale \226\128\148 Generale, Istanza, Chucho, Personale, Combattimento \226\128\148 con badge non letti e indicatori pin.",
    ["opt_skin_chatframe_enable"]        = "Attiva skin della chat",
    ["opt_skin_chatframe_width"]         = "Larghezza",
    ["opt_skin_chatframe_height"]        = "Altezza",
    ["opt_skin_chatframe_scale"]         = "Scala %",
    ["opt_skin_chatframe_opacity"]       = "Opacit\195\160 dello sfondo",
    ["opt_skin_chatframe_font_size"]     = "Dimensione del carattere",
    ["opt_skin_chatframe_timestamp"]     = "Mostra data e ora",

    -- Skins > Bags tab
    ["tab_skin_bags"]                    = "Borse",
    ["section_skin_bags"]                = "Skin delle borse",
    ["info_skin_bags_desc"]              = "Griglia borse per categoria ispirata a BetterBags. Oggetti raggruppati in sezioni comprimibili con bordi qualit\195\160, ricerca, tempi di ricarica e livello oggetto.",
    ["opt_skin_bags_enable"]             = "Attiva skin delle borse",
    -- Borse — Disincanto
    ["bagskin_de_badge"]                 = "DI",
    ["bagskin_de_tooltip"]               = "|cff0cd29f[Clic destro]|r Disincantare",
    ["bagskin_currencies_none"]          = "Nessuna valuta monitorata (clic destro su una valuta \226\134\146 Mostra nello zaino)",
    ["opt_skin_bags_stack_merge"]        = "Unisci pile identiche",
    ["opt_skin_bags_show_empty"]         = "Mostra sezione slot liberi",
    ["opt_skin_bags_show_recent"]        = "Mostra sezione oggetti recenti",
    ["opt_skin_bags_columns"]            = "Colonne",
    ["opt_skin_bags_slot_size"]          = "Dimensione slot",
    ["opt_skin_bags_slot_spacing"]       = "Spaziatura slot",
    ["opt_skin_bags_scale"]              = "Scala %",
    ["opt_skin_bags_opacity"]            = "Opacit\195\160 dello sfondo",
    ["opt_skin_bags_quality_borders"]    = "Mostra bordi qualit\195\160",
    ["opt_skin_bags_cooldowns"]          = "Mostra tempi di ricarica",
    ["opt_skin_bags_quantity"]           = "Mostra badge quantit\195\160",
    ["opt_skin_bags_search"]             = "Mostra barra di ricerca",
    ["opt_skin_bags_sort_mode"]          = "Modalit\195\160 di ordinamento",
    ["opt_skin_bags_sort_quality"]       = "Qualit\195\160",
    ["opt_skin_bags_sort_name"]          = "Nome",
    ["opt_skin_bags_sort_type"]          = "Tipo",
    ["opt_skin_bags_sort_ilvl"]          = "Livello oggetto",
    ["opt_skin_bags_sort_recent"]        = "Recente",
    ["opt_skin_bags_show_gold"]          = "Mostra oro (pi\195\168 di pagina)",
    ["opt_skin_bags_show_currencies"]    = "Mostra valute tracciate (pi\195\168 di pagina)",
    ["bagskin_cat_recent"]               = "Oggetti recenti",
    ["bagskin_cat_equipment"]            = "Equipaggiamento",
    ["bagskin_cat_consumables"]          = "Consumabili",
    ["bagskin_cat_quest"]                = "Oggetti missione",
    ["bagskin_cat_tradegoods"]           = "Merci commerciali",
    ["bagskin_cat_reagents"]             = "Reagenti",
    ["bagskin_cat_gems"]                 = "Gemme e potenziamenti",
    ["bagskin_cat_recipes"]              = "Ricette",
    ["bagskin_cat_pets"]                 = "Mascotte da combattimento",
    ["bagskin_cat_junk"]                 = "Cianfrusaglie",
    ["bagskin_cat_misc"]                 = "Varie",
    ["bagskin_cat_free"]                 = "Slot liberi",

    -- Skins > Objective Tracker tab
    ["tab_skin_objtracker"]              = "Obiettivi",

    -- Skins > Character tab
    ["tab_skin_character"]               = "Personaggio",

    -- Skins > Buffs tab
    ["tab_skin_buffs"]                   = "Buff",

    -- Skins > Game Menu tab
    ["tab_skin_gamemenu"]                = "Menu di gioco",

    -- Skins > Mail tab
    ["tab_skin_mail"]                    = "Posta",

    -- =====================
    -- MODULO WAYPOINT (/tm way)
    -- =====================
    -- GUI
    ["tab_qol_waypoint"]                  = "Waypoint",
    ["section_waypoint"]                  = "Waypoint",
    ["opt_way_zone_only"]                 = "Mostra solo nella zona corrente",
    ["opt_way_size"]                      = "Dimensione del segnale",
    ["opt_way_shape"]                     = "Forma",
    ["way_shape_ring"]                    = "Anello",
    ["way_shape_arrow"]                   = "Freccia",
    ["opt_way_color"]                     = "Colore del waypoint",
    -- Slash
    ["msg_help_way"]                     = "Posiziona un waypoint alla tua posizione attuale",
    ["msg_help_way_coords"]              = "Posiziona un waypoint alle coordinate (x, y)",
    ["msg_help_way_clear"]               = "Rimuovi il waypoint attivo",
    ["way_cleared"]                      = "Waypoint rimosso.",
    ["way_set"]                          = "Waypoint impostato su %s%s.",
    ["way_here"]                         = "Waypoint posizionato alla posizione attuale.",
    ["way_no_map"]                       = "Impossibile determinare la mappa attuale.",
    ["way_no_pos"]                       = "Impossibile determinare la posizione del giocatore.",
    ["way_bad_map"]                      = "Impossibile posizionare un waypoint su questa mappa.",
    ["way_bad_coords"]                   = "Le coordinate devono essere comprese tra 0 e 100.",
    ["way_usage"]                        = "Uso: /tm way [mapID] x y [nome]  |  /tm way clear",

    -- =====================
    -- Resource names
    -- =====================
    ["res_mana"]                        = "Mana (Druido)",
    ["res_soul_shards"]                 = "Frammenti d'anima",
    ["res_holy_power"]                  = "Potere sacro",
    ["res_chi"]                         = "Chi",
    ["res_combo_points"]                = "Punti combo",
    ["res_arcane_charges"]              = "Cariche arcane",
    ["res_essence"]                     = "Essenza",
    ["res_stagger"]                     = "Barcollamento",
    ["res_soul_fragments"]              = "Frammenti d'anima",
    ["res_tip_of_spear"]                = "Punta della lancia",
    ["res_maelstrom_weapon"]            = "Arma del Maelstrom",

    -- =====================
    -- Resource Bars display mode
    -- =====================
    ["opt_rb_display_mode"]             = "Modalità di visualizzazione",
    ["display_mode_icons"]              = "Icone (texture TUI)",
    ["display_mode_bars"]               = "Barre (colori piatti)",

    -- =====================
    -- Tooltip Skin
    -- =====================
    ["tab_skin_tooltip"]                 = "Tooltip",
    ["section_tooltip_skin"]             = "Skin Tooltip",
    ["opt_tooltip_skin_enable"]          = "Attiva skin tooltip",
    ["info_tooltip_skin_reload"]         = "Alcune modifiche richiedono di passare il cursore su un nuovo bersaglio.",
    ["opt_tooltip_bg_alpha"]             = "Opacità sfondo",
    ["opt_tooltip_border_alpha"]         = "Opacità bordo",
    ["opt_tooltip_font_size"]            = "Dimensione font",
    ["opt_tooltip_hide_healthbar"]       = "Nascondi barra vita",
    ["opt_tooltip_class_color"]          = "Nomi giocatore con colore di classe",
    ["opt_tooltip_hide_server"]          = "Nascondi server nei nomi giocatore",
    ["opt_tooltip_hide_title"]           = "Nascondi titolo nei nomi giocatore",
    ["opt_tooltip_guild_color"]          = "Colore personalizzato nome gilda",
    ["opt_tooltip_guild_color_pick"]     = "Colore nome gilda",

    -- =====================
    -- Bag Skin extras
    -- =====================
    ["opt_skin_bags_show_ilvl"]          = "Mostra livello oggetto sull'equipaggiamento",
    ["opt_skin_bags_show_junk_icon"]     = "Mostra icona spazzatura",
    ["opt_skin_bags_layout_mode"]        = "Modalità layout",
    ["opt_skin_bags_layout_combined"]    = "Griglia combinata",
    ["opt_skin_bags_layout_categories"]  = "Categorie",
    ["opt_skin_bags_layout_separate"]    = "Borse separate",
    ["opt_skin_bags_reverse_order"]      = "Inverti ordine borse",
    ["opt_skin_bags_show_bag_bar"]       = "Mostra barra borse",
    ["opt_skin_bags_settings"]           = "Impostazioni borse",
    ["opt_skin_bags_slot_spacing_x"]     = "Spaziatura slot X",
    ["opt_skin_bags_slot_spacing_y"]     = "Spaziatura slot Y",
    ["opt_skin_bags_sort_none"]          = "Manuale",

    -- =====================
    -- TOMOSCORE (Scoreboard)
    -- =====================
    ["ts_cfg_title"]                = "Tabellone",
    ["ts_cfg_enable"]               = "Attiva tabellone dungeon",
    ["ts_cfg_auto_show_mplus"]      = "Mostra automaticamente per Mythic+",
    ["ts_cfg_scale"]                = "Scala",
    ["ts_cfg_alpha"]                = "Opacità sfondo",
    ["ts_cfg_section_display"]      = "Visualizzazione",
    ["ts_cfg_section_frame"]        = "Cornice",
    ["ts_cfg_section_actions"]      = "Azioni",
    ["ts_cfg_preview"]              = "Anteprima",
    ["ts_cfg_last_run"]             = "Mostra ultima partita",
    ["ts_cfg_reset_pos"]            = "Ripristina posizione",
    ["ts_reset_msg"]                = "|cff0cd29fTomoMod|r Tabellone: Posizione ripristinata.",
    ["ts_no_data"]                  = "|cff0cd29fTomoMod|r Tabellone: Nessun dato dungeon disponibile.",
    ["ts_mythic_zero"]              = "Mitico",
    ["ts_key_level"]                = "+%d",
    ["ts_completed"]                = "COMPLETATO",
    ["ts_depleted"]                 = "ESAURITO",
    ["ts_duration"]                 = "Durata",
    ["ts_col_player"]               = "Giocatore",
    ["ts_col_rating"]               = "M+",
    ["ts_col_key_level"]            = "Chiave",
    ["ts_col_key_name"]             = "Dungeon",
    ["ts_col_damage"]               = "Danni",
    ["ts_col_healing"]              = "Cure",
    ["ts_col_interrupts"]           = "Interruzioni",
    ["ts_footer_total"]             = "Totale",
    ["ts_footer_players"]           = "%d giocatori",

    -- =====================
    -- CASTBARS (modulo autonomo)
    -- =====================
    ["cat_castbars"]                     = "Barre di lancio",

    ["cb_section_general"]               = "Generale",
    ["opt_cb_enable"]                    = "Attiva barre di lancio autonome",
    ["info_cb_description"]              = "Sostituisce le barre di lancio Blizzard con barre completamente personalizzabili per Giocatore, Bersaglio, Focus, Famiglio e Boss.",
    ["opt_cb_hide_blizzard"]             = "Nascondi barre di lancio Blizzard",
    ["opt_cb_class_color"]               = "Usa colore di classe",
    ["opt_cb_show_transitions"]          = "Animazioni di inizio/fine",
    ["opt_cb_show_channel_ticks"]        = "Mostra segni di canalizzazione",
    ["opt_cb_timer_format"]              = "Formato timer",
    ["cb_timer_remaining"]               = "Rimanente (1.5)",
    ["cb_timer_remaining_total"]         = "Rimanente / Totale (1.5 / 3.0)",
    ["cb_timer_elapsed"]                 = "Trascorso (1.5)",
    ["opt_cb_spell_max_len"]             = "Lunghezza max. nome (0 = illimitato)",

    ["cb_section_appearance"]            = "Aspetto",
    ["opt_cb_bar_texture"]               = "Texture della barra",
    ["cb_tex_blizzard"]                  = "Blizzard",
    ["cb_tex_smooth"]                    = "Liscio",
    ["cb_tex_flat"]                      = "Piatto",
    ["opt_cb_font_size"]                 = "Dimensione carattere",
    ["opt_cb_bg_mode"]                   = "Modalità sfondo",
    ["cb_bg_black"]                      = "Nero",
    ["cb_bg_transparent"]                = "Trasparente",
    ["cb_bg_custom"]                     = "Texture personalizzata",

    ["cb_section_colors"]                = "Colori",
    ["opt_cb_cast_color"]                = "Colore di lancio",
    ["opt_cb_ni_color"]                  = "Non interrompibile",
    ["opt_cb_interrupt_color"]           = "Colore interruzione",

    ["cb_section_spark"]                 = "Scintilla",
    ["opt_cb_show_spark"]                = "Mostra animazione scintilla",
    ["opt_cb_spark_style"]               = "Stile scintilla",
    ["opt_cb_spark_color"]               = "Colore scintilla",
    ["opt_cb_spark_glow_color"]          = "Colore bagliore",
    ["opt_cb_spark_tail_color"]          = "Colore scia",
    ["opt_cb_spark_glow_alpha"]          = "Opacità bagliore",
    ["opt_cb_spark_tail_alpha"]          = "Opacità scia",

    ["cb_section_gcd"]                   = "Scintilla GCD",
    ["opt_cb_show_gcd"]                  = "Mostra barra GCD sotto la barra del giocatore",
    ["opt_cb_gcd_height"]                = "Altezza barra GCD",
    ["opt_cb_gcd_color"]                 = "Colore GCD",

    ["cb_section_interrupt"]             = "Feedback interruzione",
    ["opt_cb_show_interrupt_feedback"]   = "Mostra testo di interruzione",
    ["opt_cb_interrupt_fb_color"]        = "Colore del testo",
    ["opt_cb_interrupt_fb_size"]         = "Dimensione carattere",
    ["cb_interrupt_feedback_text"]       = "INTERROTTO!",
    ["cb_interrupt_feedback_full"]       = "INTERROTTO: %s",
    ["cb_interrupted"]                   = "Interrotto",

    ["cb_tab_general"]                   = "Generale",
    ["cb_tab_player"]                    = "Giocatore",
    ["cb_tab_target"]                    = "Bersaglio",
    ["cb_tab_focus"]                     = "Focus",
    ["cb_tab_pet"]                       = "Famiglio",
    ["cb_tab_boss"]                      = "Boss",

    ["cb_section_unit"]                  = "Barra di %s",
    ["opt_cb_unit_enable"]               = "Attiva",
    ["opt_cb_unit_width"]                = "Larghezza",
    ["opt_cb_unit_height"]               = "Altezza",
    ["opt_cb_unit_show_icon"]            = "Mostra icona",
    ["opt_cb_unit_icon_side"]            = "Lato icona",
    ["cb_icon_left"]                     = "Sinistra",
    ["cb_icon_right"]                    = "Destra",
    ["opt_cb_unit_show_timer"]           = "Mostra timer",
    ["opt_cb_unit_show_latency"]         = "Mostra latenza",
    ["info_cb_latency"]                  = "Mostra un overlay scuro con la latenza di rete alla fine della barra.",
    ["info_cb_position"]                 = "Usa /tm layout per sbloccare e trascinare questa barra.",
    ["btn_cb_reset_position"]            = "Reimposta posizione",
    ["cb_move_label"]                    = "(Trascina per spostare)",
    ["cb_preview_castbar"]               = "Anteprima: %s",

    ["mover_castbar_standalone"]         = "Barre di lancio",

    -- ═══════════════════════════════════
    -- Riquadri di gruppo (Party Frames)
    -- ═══════════════════════════════════
    ["cat_partyframes"]                  = "Riquadri di gruppo",
    ["mover_partyframes"]                = "Riquadri di gruppo",

    ["pf_tab_general"]                   = "Generale",
    ["pf_tab_features"]                  = "Funzionalità",
    ["pf_tab_cooldowns"]                 = "Tempo di ricarica",
    ["pf_tab_arena"]                     = "Arena",

    ["pf_section_general"]               = "Generale",
    ["pf_opt_enable"]                    = "Attiva riquadri di gruppo",
    ["pf_info_description"]              = "Riquadri di gruppo personalizzati per M+ e Arena con salute, assorbimento, previsione cure, HoT, CD interruzioni/rez da combattimento e evidenziazione dissolvi.",
    ["pf_opt_hide_blizzard"]             = "Nascondi riquadri di gruppo Blizzard",
    ["pf_opt_sort_role"]                 = "Ordina per ruolo (Tank > Guaritore > DPS)",

    ["pf_section_dimensions"]            = "Dimensioni",
    ["pf_opt_width"]                     = "Larghezza riquadro",
    ["pf_opt_height"]                    = "Altezza riquadro",
    ["pf_opt_spacing"]                   = "Spaziatura",
    ["pf_opt_grow_direction"]            = "Direzione di crescita",
    ["pf_dir_down"]                      = "Giù",
    ["pf_dir_up"]                        = "Su",
    ["pf_dir_right"]                     = "Destra",
    ["pf_dir_left"]                      = "Sinistra",

    ["pf_section_display"]               = "Visualizzazione",
    ["pf_opt_show_name"]                 = "Mostra nome",
    ["pf_opt_show_health_text"]          = "Mostra testo salute",
    ["pf_opt_health_format"]             = "Formato salute",
    ["pf_fmt_deficit"]                   = "Deficit",
    ["pf_opt_health_color"]              = "Modalità colore salute",
    ["pf_color_green"]                   = "Verde",
    ["pf_color_gradient"]                = "Gradiente",
    ["pf_opt_show_power"]                = "Mostra barra potere",
    ["pf_opt_power_height"]              = "Altezza barra potere",
    ["pf_opt_show_role"]                 = "Mostra icona ruolo",
    ["pf_opt_role_size"]                 = "Dimensione icona ruolo",
    ["pf_opt_show_marker"]               = "Mostra marcatore raid",

    ["pf_section_font"]                  = "Carattere",
    ["pf_opt_font_size"]                 = "Dimensione carattere",

    ["pf_section_position"]              = "Posizione",
    ["pf_info_position"]                 = "Usa /tm layout per sbloccare e trascinare i riquadri di gruppo.",
    ["pf_btn_reset_position"]            = "Reimposta posizione",

    ["pf_section_health_extras"]         = "Extra salute",
    ["pf_opt_show_absorb"]               = "Mostra barra assorbimento",
    ["pf_opt_absorb_color"]              = "Colore assorbimento",
    ["pf_opt_show_heal_pred"]            = "Mostra previsione cure",

    ["pf_section_range"]                 = "Controllo raggio",
    ["pf_opt_show_range"]                = "Attenua membri fuori raggio",
    ["pf_opt_oor_alpha"]                 = "Opacità fuori raggio",

    ["pf_section_dispel"]                = "Evidenziazione dissolvi",
    ["pf_opt_show_dispel"]               = "Evidenzia debuff dissolvibili",
    ["pf_info_dispel"]                   = "Bagliore bordo per tipo di debuff: Magia (blu), Maledizione (viola), Malattia (marrone), Veleno (verde).",

    ["pf_section_hots"]                  = "Tracciamento HoT",
    ["pf_opt_show_hots"]                 = "Mostra indicatori HoT",
    ["pf_opt_hot_size"]                  = "Dimensione icona HoT",
    ["pf_opt_max_hots"]                  = "Max. HoT mostrati",
    ["pf_info_hots"]                     = "Mostra effetti di cura nel tempo con bordi colorati per classe. Supporta Sacerdote, Druido, Paladino, Sciamano, Monaco ed Evocatore.",

    ["pf_section_cooldowns"]             = "Tracciamento ricarica",
    ["pf_opt_show_kick"]                 = "Mostra CD interruzione",
    ["pf_opt_show_brez"]                 = "Mostra CD rez da combattimento",
    ["pf_opt_cd_size"]                   = "Dimensione icona CD",
    ["pf_opt_cd_layout"]                 = "Layout icone CD",
    ["pf_cd_vertical"]                   = "Verticale (sul riquadro)",
    ["pf_cd_horizontal"]                 = "Orizzontale (sotto)",
    ["pf_info_cooldowns"]                = "Traccia le ricariche di interruzione e rez da combattimento per ogni membro del gruppo.",

    ["pf_section_arena"]                 = "Riquadri nemici arena",
    ["pf_opt_arena_enable"]              = "Attiva riquadri arena",
    ["pf_info_arena"]                    = "Mostra salute, potere e CD bijou PvP del team nemico in Arena (2v2/3v3).",
    ["pf_section_arena_dims"]            = "Dimensioni arena",
    ["pf_opt_arena_width"]               = "Larghezza",
    ["pf_opt_arena_height"]              = "Altezza",
    ["pf_opt_arena_spacing"]             = "Spaziatura",
    ["pf_section_arena_trinket"]         = "Bijou PvP",
    ["pf_opt_show_trinket"]              = "Mostra CD bijou",
    ["pf_opt_trinket_size"]              = "Dimensione icona bijou",
    ["pf_opt_show_spec"]                 = "Mostra icona specializzazione",
    ["pf_section_arena_pos"]             = "Posizione arena",
    ["pf_info_arena_pos"]                = "Usa /tm layout per sbloccare e trascinare i riquadri arena.",
    ["pf_btn_reset_arena_pos"]           = "Reimposta posizione",

    -- ═══════════════════════════════════
    -- Raid Frames
    -- ═══════════════════════════════════
    ["cat_raidframes"]                   = "Riquadri incursione",
    ["mover_raidframes"]                 = "Riquadri incursione",
    ["rf_tab_general"]                   = "Generale",
    ["rf_tab_features"]                  = "Funzionalità",
    ["rf_section_general"]               = "Generale",
    ["rf_opt_enable"]                    = "Attiva riquadri incursione",
    ["rf_info_description"]              = "Riquadri incursione personalizzati con salute, assorbimento, previsione cure, HoT, debuff, evidenziazione dissolvi, CD difensivi e controllo distanza.",
    ["rf_opt_hide_blizzard"]             = "Nascondi riquadri incursione di Blizzard",
    ["rf_opt_sort_role"]                 = "Ordina per ruolo (Tank > Guaritore > DPS)",
    ["rf_section_layout"]                = "Layout",
    ["rf_opt_layout_mode"]               = "Modalità layout",
    ["rf_layout_grid"]                   = "Griglia (gruppi in colonne)",
    ["rf_layout_list"]                   = "Lista (colonna singola)",
    ["rf_opt_width"]                     = "Larghezza riquadro",
    ["rf_opt_height"]                    = "Altezza riquadro",
    ["rf_opt_spacing"]                   = "Spaziatura",
    ["rf_opt_group_spacing"]             = "Spaziatura gruppo",
    ["rf_section_display"]               = "Visualizzazione",
    ["rf_opt_show_name"]                 = "Mostra nome",
    ["rf_opt_name_max_length"]           = "Lettere max del nome",
    ["rf_opt_show_health_text"]          = "Mostra testo salute",
    ["rf_opt_health_format"]             = "Formato salute",
    ["rf_opt_health_color"]              = "Modalità colore salute",
    ["rf_opt_show_role"]                 = "Mostra icona ruolo",
    ["rf_opt_show_marker"]               = "Mostra marcatore incursione",
    ["rf_section_font"]                  = "Carattere",
    ["rf_opt_font_size"]                 = "Dimensione carattere",
    ["rf_section_position"]              = "Posizione",
    ["rf_info_position"]                 = "Usa /tm layout per sbloccare e trascinare i riquadri incursione.",
    ["rf_btn_reset_position"]            = "Reimposta posizione",
    ["rf_info_test_raid"]                = "Simula un'incursione di 20 giocatori per visualizzare l'anteprima del layout fuori combattimento.",
    ["rf_btn_test_raid"]                 = "Simula 20 giocatori",
    ["rf_btn_test_raid_stop"]            = "Interrompi simulazione",
    ["rf_preview_group"]                 = "G",
    ["rf_section_health_extras"]         = "Funzioni salute",
    ["rf_opt_show_power"]                = "Barra potere (solo guaritori)",
    ["rf_opt_power_height"]              = "Altezza barra potere",
    ["rf_opt_show_absorb"]               = "Mostra barra assorbimento",
    ["rf_opt_show_heal_pred"]            = "Mostra previsione cure",
    ["rf_section_range"]                 = "Controllo distanza",
    ["rf_opt_show_range"]                = "Sfuma membri fuori portata",
    ["rf_opt_oor_alpha"]                 = "Opacità fuori portata",
    ["rf_section_dispel"]                = "Evidenziazione dissolvi",
    ["rf_opt_show_dispel"]               = "Evidenzia debuff dissolubili",
    ["rf_section_hots"]                  = "Tracciamento HoT",
    ["rf_opt_show_hots"]                 = "Mostra indicatori HoT",
    ["rf_opt_hot_size"]                  = "Dimensione icona HoT",
    ["rf_opt_max_hots"]                  = "Max HoT mostrati",
    ["rf_section_debuffs"]               = "Tracciamento debuff",
    ["rf_opt_show_debuffs"]              = "Mostra icone debuff",
    ["rf_opt_debuff_size"]               = "Dimensione icona debuff",
    ["rf_opt_max_debuffs"]               = "Max debuff mostrati",
    ["rf_section_defensives"]            = "CD difensivi",
    ["rf_opt_show_defensives"]           = "Mostra buff difensivi attivi",
    ["rf_opt_defensive_size"]            = "Dimensione icona difensiva",
    ["rf_info_defensives"]               = "Mostra i CD difensivi attivi (es: Soppressione del Dolore, Corteccia di Ferro, Scudo Divino) su ogni membro dell'incursione.",

    -- ═══════════════════════════════════
    -- Aura Tracker
    -- ═══════════════════════════════════
    ["tab_qol_aura_tracker"]             = "Tracciatore aure",
    ["mover_auratracker"]                = "Tracciatore aure",

    ["at_section_general"]               = "Generale",
    ["at_opt_enable"]                    = "Attiva tracciatore aure",
    ["at_info_description"]              = "Traccia buff importanti: proc bijou, proc incantamento arma, buff personali e difensivi in un overlay di icone.",

    ["at_section_appearance"]            = "Aspetto",
    ["at_opt_icon_size"]                 = "Dimensione icona",
    ["at_opt_spacing"]                   = "Spaziatura",
    ["at_opt_max_icons"]                 = "Max. icone",
    ["at_opt_grow_direction"]            = "Direzione di crescita",
    ["at_opt_font_size"]                 = "Dimensione carattere",

    ["at_section_display"]               = "Visualizzazione",
    ["at_opt_show_timer"]                = "Mostra timer",
    ["at_opt_show_stacks"]               = "Mostra cumuli",
    ["at_opt_show_glow"]                 = "Bagliore su nuovo proc",
    ["at_opt_timer_threshold"]           = "Soglia lampeggio (sec)",

    ["at_section_categories"]            = "Categorie",
    ["at_info_categories"]               = "Scegli quali categorie di aure tracciare.",
    ["at_cat_trinkets"]                  = "Proc bijou",
    ["at_cat_enchants"]                  = "Proc incantamento arma",
    ["at_cat_selfbuffs"]                 = "Buff personali (CD)",
    ["at_cat_raidbuffs"]                 = "Buff raid",
    ["at_cat_defensives"]                = "Difensivi (esterni + personali)",

    ["at_section_position"]              = "Posizione",
    ["at_info_position"]                 = "Usa /tm layout per sbloccare e trascinare il tracciatore.",
    ["at_btn_reset_position"]            = "Reimposta posizione",

    -- ═══════════════════════════════════
    -- Battle Text
    -- ═══════════════════════════════════
    ["cat_battletext"]                   = "Testo di combattimento",
    ["mover_battletext"]                 = "Testo di combattimento",

    ["bt_section_general"]               = "Generale",
    ["bt_info_description"]              = "Testo di combattimento scorrevole: danni e cure, in entrata e in uscita.",
    ["bt_opt_enable"]                    = "Attiva testo di combattimento",

    ["bt_section_display"]               = "Visualizzazione",
    ["bt_opt_outgoing"]                  = "Mostra danni in uscita",
    ["bt_opt_incoming"]                  = "Mostra danni in entrata",
    ["bt_opt_overheal"]                  = "Mostra sovra-cura",
    ["bt_opt_throttle"]                  = "Unisci tick DoT/HoT",

    ["bt_section_appearance"]            = "Aspetto",
    ["bt_opt_font_size"]                 = "Dimensione carattere",
    ["bt_opt_throttle_window"]           = "Finestra di unione (sec)",

    ["bt_section_position"]              = "Posizione",
    ["bt_info_position"]                 = "Usa /tm layout per sbloccare e trascinare le zone.",
    ["bt_btn_reset_position"]            = "Reimposta posizioni",

    ["bt_zone_outgoing"]                 = "In uscita",
    ["bt_zone_incoming"]                 = "In entrata",
    ["bt_zone_heal_out"]                 = "Cure in uscita",
    ["bt_zone_heal_in"]                  = "Cure ricevute",

    ["bt_cmd_help"]                      = "/tm bt <cmd>",
    ["bt_enabled"]                       = "attivato",
    ["bt_disabled"]                      = "disattivato",
    ["bt_crit"]                          = "!",
    ["bt_zones_locked"]                  = "zone bloccate",
    ["bt_zones_unlocked"]                = "zone sbloccate",
    ["bt_reset_done"]                    = "posizioni reimpostate.",
    ["bt_miss_miss"]                     = "Mancato",
    ["bt_miss_dodge"]                    = "Schivato",
    ["bt_miss_parry"]                    = "Parato",
    ["bt_miss_block"]                    = "Bloccato",
    ["bt_miss_resist"]                   = "Resistito",
    ["bt_miss_absorb"]                   = "Assorbito",
    ["bt_miss_immune"]                   = "Immune",
    ["bt_miss_evade"]                    = "Evasione",
    ["bt_miss_deflect"]                  = "Deviato",
    ["bt_miss_reflect"]                  = "Riflesso",

    -- =========== What's New Popup ===========
    ["wn_title"]                         = "Novit\195\160",
    ["wn_version"]                       = "Versione %s",
    ["wn_subtitle"]                      = "Ecco cosa \195\168 cambiato dal tuo ultimo aggiornamento:",
    ["wn_btn_ok"]                        = "Capito!",
    ["wn_footer"]                        = "Tutte le impostazioni possono essere modificate in qualsiasi momento tramite |cff0cd29f/tm|r.",

    -- 2.9.8
    ["wn_298_housing"]                   = "Nuovo modulo Housing: hover decorazione, orologio editor e teletrasporto /tm home (Midnight+).",
    ["wn_298_housing_hover"]             = "Hover decorazione: mostra nome, costo di posizionamento e stock rimanente; tasto modificatore per duplicare.",
    ["wn_298_housing_clock"]             = "Orologio editor: orologio analogico/digitale con tracciamento del tempo per sessione e totale.",
    ["wn_298_housing_teleport"]          = "/tm home: ti teletrasporta a casa tua o esce automaticamente se sei in visita.",
    ["wn_298_icons"]                     = "Nuove icone categoria: icona casa per Housing, icona monitor per Diagnostica.",
    ["wn_298_locales"]                   = "Housing + pannello Diagnostica: supporto completo locale per frFR, deDE, esES, itIT, ptBR.",

    -- 2.9.6
    ["wn_296_raid_frames"]               = "Nuovo modulo Riquadri incursione: riquadri raid personalizzati in griglia o lista.",
    ["wn_296_raid_health"]               = "Barre salute, assorbimento e previsione cure + barra potere (solo guaritori).",
    ["wn_296_raid_auras"]                = "Tracciamento debuff e HoT con bordi colorati per tipo/classe.",
    ["wn_296_raid_utilities"]            = "Icone CD difensivi, evidenziazione dissolvi, sfumatura fuori portata, icone ruolo, marcatori raid e controllo pronto.",
    ["wn_296_raid_config"]               = "Pannello di configurazione completo con schede Generale e Funzionalità, 80+ chiavi locale in 6 lingue.",

    -- 2.9.7
    ["wn_297_rf_live_preview"]           = "Riquadri incursione: anteprima live nel pannello di configurazione — 20 membri simulati aggiornati in tempo reale.",
    ["wn_297_rf_preview_layout"]         = "L'anteprima mostra tutti i layout: griglia (etichette G1–G4) o lista (2 colonne), con ruoli e HoT.",
    ["wn_297_rf_preview_scaling"]        = "Scala automatica alla larghezza del pannello; riflette larghezza, altezza, spaziatura, colore, nome, barra potere e altro.",
    ["wn_297_taint_blizzard"]            = "Riquadri incursione: occultamento frame Blizzard riscritto (SetAlpha+SetScale) — risolve il taint di CompactPartyFrame e ArenaFrame.",
    ["wn_297_range_fix"]                 = "Riquadri incursione: dissolvenza per distanza corretta per i booleani segreti di Midnight+ (SetAlphaFromBoolean).",
    ["wn_297_actionbars_fix"]            = "Barre azioni: inizializzazione posticipata dopo il blocco combattimento — risolve il taint di SecureStateDriver all'accesso.",
    ["wn_297_mp_tracker"]                = "Mythic+: ObjectiveTrackerFrame ora viene correttamente nascosto durante la modalità sfida.",
    ["wn_297_role_icon"]                 = "Riquadri incursione: dimensione predefinita icona ruolo raddoppiata (10 → 20).",
    ["wn_297_castbar_fix"]               = "Barre incantesimo: la barra del giocatore non scompare più in combattimento — FadeOut è ora idempotente e il nil transitorio non nasconde più la barra.",
    ["wn_297_diag_exclusions"]           = "Diagnostica: messaggi di restrizione mount e limite mascotte esclusi dalla cattura degli errori.",

    -- 2.9.5
    ["wn_295_taint_fix"]                 = "CooldownTrackers: rimosso COMBAT_LOG_EVENT_UNFILTERED per correggere il taint (ADDON_ACTION_FORBIDDEN).",
    ["wn_295_diag_taint"]                = "Diagnostica: gli errori di taint vengono ora sempre catturati, anche con la diagnostica disattivata.",
    ["wn_295_tooltip_ids_moved"]         = "Opzioni Tooltip IDs spostate dal pannello QOL a Skin > scheda Tooltip.",
    ["wn_295_chat_text_offset"]          = "Skin chat: testo leggermente spostato a destra per liberare la barra laterale.",

    -- 2.9.4
    ["wn_294_installer"]                 = "Installatore esteso da 12 a 16 passaggi guidati.",
    ["wn_294_uf_pf"]                     = "Nuovi passaggi: configurazione di Unit Frame e Party Frame.",
    ["wn_294_cb_res"]                    = "Nuovi passaggi: Barre di lancio e Risorse / Gestore cooldown.",
    ["wn_294_skins_qol"]                 = "Passaggio Skin migliorato (borse, tooltip) e passaggio QOL (minimappa, cursore, AFK, diagnostica, aura tracker).",
    ["wn_294_bugfixes"]                  = "Correzioni di valori segreti per TooltipIDs e CooldownTrackers (taint Midnight).",
    ["wn_294_locales"]                   = "50+ nuove chiavi di traduzione in tutte le 6 lingue.",

    -- 2.9.3
    ["wn_293_partyframe"]                = "Party Frame: icone ready check, tooltip al passaggio, riscrittura marcatori raid.",
    ["wn_293_actionbar_fix"]             = "Barre azione: correzione interattivit\195\160 barre 1-4, correzione pulsanti vuoti.",
    ["wn_293_chat_taint"]                = "Skin chat: correzioni taint Midnight (guard GUID/BN segreti).",
    ["wn_293_diagnostics"]               = "Diagnostica: esclusione basata su pattern, parole chiave 6 lingue.",
    ["wn_293_autofill"]                  = "AutoFillDelete: correzione STATICPOPUP_NUMDIALOGS Midnight.",

    -- 2.9.2
    ["wn_292_actionbar"]                 = "Riscrittura completa barre azione: architettura contenitore, sistema fade, condizioni di visualizzazione.",
    ["wn_292_diagnostics"]               = "Nuova console diagnostica: cattura errori in background, esportazione, /tmdiag.",

    -- =====================
    -- CONFIG: Diagnostics Panel
    -- =====================
    ["section_diagnostics"]              = "Diagnostica",
    ["opt_diag_enabled"]                 = "Abilita cattura errori",
    ["opt_diag_capture_all"]             = "Cattura tutti gli addon",
    ["opt_diag_suppress_popups"]         = "Sopprimi finestre di errore",
    ["opt_diag_auto_open"]               = "Apri automaticamente con errore TomoMod",
    ["btn_diag_open_console"]            = "Apri console",
    ["btn_diag_clear"]                   = "Cancella errori",
    ["btn_diag_export"]                  = "Copia report",
    ["btn_diag_export_tracker"]          = "Esporta per Tracker",
    ["info_diag_desc"]                   = "Cattura errori Lua in background senza popup durante il combattimento. /tmdiag per aprire la console.",
    ["info_diag_session"]                = "Sessione: #%d \226\128\148 %d errori catturati (%d TomoMod)",
    ["info_diag_capture_all_desc"]       = "Quando disabilitato, vengono catturati solo gli errori di TomoMod. Attiva per catturare tutti gli errori degli addon.",

    -- =====================
    -- HOUSING
    -- =====================
    ["section_housing_general"]      = "Housing \226\128\148 Generale",
    ["section_housing_hover"]        = "Info decorazione (hover)",
    ["section_housing_clock"]        = "Orologio editor",
    ["section_housing_teleport"]     = "Teletrasporto",
    ["section_housing_commands"]     = "Comandi",

    ["info_housing_desc"]            = "Modulo Housing: migliora l'editor di case e aggiunge scorciatoie di teletrasporto. Richiede Midnight / The War Within.",
    ["info_housing_hover"]           = "In modalit\195\160 'Decorazione base', mostra nome, costo di posizionamento e stock rimanente. Consente anche di duplicare con tasto modificatore.",
    ["info_housing_clock"]           = "Mostra un orologio e registra il tempo nell'editor di case. Clic destro per passare tra analogico e digitale.",
    ["info_housing_teleport"]        = "Attiva /tm home: ti teletrasporta a casa tua o esci automaticamente se sei in visita.",
    ["info_housing_commands"]        = "\226\128\162 /tm home \226\128\148 teletrasportati a casa (o esci)\n\226\128\162 /tm housing \226\128\148 apri questo pannello\n\226\128\162 Clic destro sull'orologio \226\128\148 cambia analogico/digitale",

    ["opt_housing_enable"]           = "Abilita modulo Housing",
    ["opt_housing_decorhover"]       = "Abilita info decorazione",
    ["opt_housing_dupe"]             = "Abilita duplicazione rapida (modificatore)",
    ["opt_housing_dupekey"]          = "Tasto di duplicazione",
    ["opt_housing_clock"]            = "Abilita orologio",
    ["opt_housing_clock_analog"]     = "Modalit\195\160 analogica (altrimenti digitale)",
    ["opt_housing_teleport"]         = "Abilita teletrasporto /tm home",

    ["btn_housing_tp_home"]          = "Teletrasportati (test)",
    ["btn_housing_refresh"]          = "Aggiorna case",

    ["housing_duplicate"]            = "Duplica",
    ["housing_alliance_zone"]        = "Promontorio del Fondatore",
    ["housing_horde_zone"]           = "Coste di Vento Lama",
    ["housing_clock_title"]          = "TomoMod \226\128\148 Orologio",
    ["housing_clock_time"]           = "Ora",
    ["housing_clock_local"]          = "Ora locale:",
    ["housing_clock_realm"]          = "Ora del reame:",
    ["housing_clock_time_spent"]     = "Tempo nell'editor",
    ["housing_clock_session"]        = "Questa sessione:",
    ["housing_clock_total"]          = "Totale:",
    ["housing_clock_rightclick"]     = "Clic destro per passare analogico / digitale",

    ["msg_help_home"]                = "Teletrasportati a casa tua (o esci)",
    ["msg_help_housing"]             = "Apri il pannello Housing",
    ["msg_housing_refresh"]          = "Informazioni sulle case richieste.",
    ["msg_housing_unavailable"]      = "Modulo Housing non disponibile su questo client.",
})
-- =====================================
-- deDE.lua — Deutsch
-- =====================================

TomoMod_RegisterLocale("deDE", {

    -- =====================
    -- CONFIG: Categories (ConfigUI.lua)
    -- =====================
    ["cat_general"]         = "Allgemein",
    ["cat_unitframes"]      = "UnitFrames",
    ["cat_nameplates"]      = "Nameplates",
    ["cat_cd_resource"]     = "CD & Ressourcen",
    ["cat_qol"]             = "Lebensqualität",
    ["cat_profiles"]        = "Profile",

    -- =====================
    -- CONFIG: General Panel
    -- =====================
    ["section_about"]                   = "Über",
    ["about_text"]                      = "|cff0cd29fTomoMod|r v2.4.0 von TomoAniki\nLeichtgewichtige Oberfläche mit QOL, UnitFrames und Nameplates.\nTippe /tm help für die Befehlsliste.",
    ["section_general"]                 = "Allgemein",
    ["btn_reset_all"]                   = "Alles zurücksetzen",
    ["info_reset_all"]                  = "Dies setzt ALLE Einstellungen zurück und lädt die Oberfläche neu.",

    -- Minimap
    ["section_minimap"]                 = "Minimap",
    ["opt_minimap_enable"]              = "Eigene Minimap aktivieren",
    ["opt_size"]                        = "Größe",
    ["opt_scale"]                       = "Skalierung",
    ["opt_border"]                      = "Rahmen",
    ["border_class"]                    = "Klassenfarbe",
    ["border_black"]                    = "Schwarz",

    -- Info Panel
    ["section_info_panel"]              = "Infopanel",
    ["opt_enable"]                      = "Aktivieren",
    ["opt_durability"]                  = "Haltbarkeit (Ausrüstung)",
    ["opt_time"]                        = "Uhrzeit",
    ["opt_24h_format"]                  = "24h-Format",
    ["opt_show_coords"]                 = "Koordinaten anzeigen",
    ["btn_reset_position"]              = "Position zurücksetzen",

    -- Cursor Ring
    ["section_cursor_ring"]             = "Cursorring",
    ["opt_class_color"]                 = "Klassenfarbe",
    ["opt_anchor_tooltip_ring"]         = "Tooltip am Cursor verankern",

    -- =====================
    -- CONFIG: UnitFrames Panel
    -- =====================
    -- Tabs
    ["tab_general"]                     = "Allgemein",
    ["tab_player"]                      = "Spieler",
    ["tab_target"]                      = "Ziel",
    ["tab_tot"]                         = "ZdZ",
    ["tab_pet"]                         = "Begleiter",
    ["tab_focus"]                       = "Fokus",
    ["tab_colors"]                      = "Farben",

    -- Sub-tabs (Player, Target, Focus)
    ["subtab_dimensions"]               = "Abmessungen",
    ["subtab_display"]                  = "Anzeige",
    ["subtab_auras"]                    = "Auren",
    ["subtab_positioning"]              = "Position",

    -- Sub-labels
    ["sublabel_dimensions"]             = "— Abmessungen —",
    ["sublabel_display"]                = "— Anzeige —",
    ["sublabel_castbar"]                = "— Zauberleiste —",
    ["sublabel_auras"]                  = "— Auren —",
    ["sublabel_element_offsets"]        = "— Elementpositionen —",

    -- Unit display names
    ["unit_player"]                     = "Spieler",
    ["unit_target"]                     = "Ziel",
    ["unit_tot"]                        = "Ziel des Ziels",
    ["unit_pet"]                        = "Begleiter",
    ["unit_focus"]                      = "Fokus",

    -- General tab
    ["section_general_settings"]        = "Allgemeine Einstellungen",
    ["opt_uf_enable"]                   = "TomoMod UnitFrames aktivieren",
    ["opt_hide_blizzard"]               = "Blizzard-Frames ausblenden",
    ["opt_global_font_size"]            = "Globale Schriftgröße",
    ["sublabel_font"]                   = "— Schriftart —",
    ["opt_font_family"]                 = "Schriftfamilie",

    -- Castbar colors
    ["section_castbar_colors"]          = "Zauberleisten-Farben",
    ["info_castbar_colors"]             = "Passe die Farben der Zauberleiste für unterbrechbare, nicht unterbrechbare und unterbrochene Zauber an.",
    ["opt_castbar_color"]               = "Unterbrechbarer Zauber",
    ["opt_castbar_ni_color"]            = "Nicht unterbrechbarer Zauber",
    ["opt_castbar_interrupt_color"]     = "Unterbrochener Zauber",
    ["info_castbar_colors_reload"]      = "Farbänderungen gelten für neue Zauber. /reload für vollständige Wirkung.",
    ["btn_toggle_lock"]                 = "Sperren/Entsperren (/tm uf)",
    ["info_unlock_drag"]                = "Entsperren zum Verschieben. Positionen werden automatisch gespeichert.",

    -- Per-unit options
    ["opt_width"]                       = "Breite",
    ["opt_health_height"]               = "Lebenshöhe",
    ["opt_power_height"]                = "Ressourcenhöhe",
    ["opt_show_name"]                   = "Name anzeigen",
    ["opt_name_truncate"]               = "Lange Namen kürzen",
    ["opt_name_truncate_length"]        = "Max. Namenslänge",
    ["opt_show_level"]                  = "Stufe anzeigen",
    ["opt_show_health_text"]            = "Lebenstext anzeigen",
    ["opt_health_format"]               = "Lebensformat",
    ["fmt_current"]                     = "Aktuell (25.3K)",
    ["fmt_percent"]                     = "Prozent (75%)",
    ["fmt_current_percent"]             = "Aktuell + % (25.3K | 75%)",
    ["fmt_current_max"]                 = "Aktuell / Max",
    ["opt_class_color_uf"]              = "Klassenfarbe",
    ["opt_faction_color"]               = "Fraktionsfarbe (NSC)",
    ["opt_use_nameplate_colors"]        = "Nameplate-Farben (NSC-Typ)",
    ["opt_show_absorb"]                 = "Absorptionsleiste",
    ["opt_show_threat"]                 = "Bedrohungsanzeige (Randleuchten)",
    ["section_threat_text"]             = "Bedrohung % Text",
    ["opt_threat_text_enable"]          = "Bedrohung % auf dem Ziel anzeigen",
    ["opt_threat_text_font_size"]       = "Schriftgröße",
    ["opt_threat_text_offset_x"]        = "Versatz X",
    ["opt_threat_text_offset_y"]        = "Versatz Y",
    ["info_threat_text"]                = "Grün = Tank (Vorsprung), gelb = Warnung, rot = Aggro verloren",
    ["opt_show_leader_icon"]            = "Anführersymbol",
    ["opt_leader_icon_x"]               = "Anführersymbol X",
    ["opt_leader_icon_y"]               = "Anführersymbol Y",

    -- Castbar
    ["opt_castbar_enable"]              = "Zauberleiste aktivieren",
    ["opt_castbar_width"]               = "Zauberleistenbreite",
    ["opt_castbar_height"]              = "Zauberleistenhöhe",
    ["opt_castbar_show_icon"]           = "Symbol anzeigen",
    ["opt_castbar_show_timer"]          = "Timer anzeigen",
    ["info_castbar_drag"]               = "Position: /tm sr zum Entsperren und Verschieben der Zauberleiste.",
    ["btn_reset_castbar_position"]      = "Position der Zauberleiste zurücksetzen",
    ["opt_castbar_show_latency"]        = "Latenz anzeigen",

    -- Auras
    ["opt_auras_enable"]                = "Auren aktivieren",
    ["opt_auras_max"]                   = "Max. Auren",
    ["opt_auras_size"]                  = "Symbolgröße",
    ["opt_auras_type"]                  = "Aurentyp",
    ["aura_harmful"]                    = "Debuffs (schädlich)",
    ["aura_helpful"]                    = "Buffs (nützlich)",
    ["aura_all"]                        = "Alle",
    ["opt_auras_direction"]             = "Wachstumsrichtung",
    ["aura_dir_right"]                  = "Nach rechts",
    ["aura_dir_left"]                   = "Nach links",
    ["opt_auras_only_mine"]             = "Nur eigene Auren",

    -- Element offsets
    ["elem_name"]                       = "Name",
    ["elem_level"]                      = "Stufe",
    ["elem_health_text"]                = "Lebenstext",
    ["elem_power"]                      = "Ressourcenleiste",
    ["elem_castbar"]                    = "Zauberleiste",
    ["elem_auras"]                      = "Auren",

    -- =====================
    -- CONFIG: Nameplates Panel
    -- =====================
    -- Nameplate tabs
    ["tab_np_auras"]                    = "Auren",
    ["tab_np_advanced"]                 = "Erweitert",
    ["info_np_colors_custom"]           = "Jede Farbe kann durch Klick auf das Farbfeld individuell angepasst werden.",

    ["section_np_general"]              = "Allgemeine Einstellungen",
    ["opt_np_enable"]                   = "TomoMod Nameplates aktivieren",
    ["info_np_description"]             = "Ersetzt Blizzard-Nameplates durch einen anpassbaren minimalistischen Stil.",
    ["section_dimensions"]              = "Abmessungen",
    ["opt_np_name_font_size"]           = "Namensschriftgröße",

    -- Display
    ["section_display"]                 = "Anzeige",
    ["opt_np_show_classification"]      = "Klassifizierung anzeigen (Elite, Selten, Boss)",
    ["opt_np_show_absorb"]               = "Absorptionsleiste anzeigen",
    ["opt_np_class_colors"]             = "Klassenfarben (Spieler)",

    -- Castbar
    ["section_castbar"]                 = "Zauberleiste",
    ["opt_np_show_castbar"]             = "Zauberleiste anzeigen",
    ["opt_np_castbar_height"]           = "Zauberleistenhöhe",
    ["color_castbar"]                   = "Zauberleiste (unterbrechbar)",
    ["color_castbar_uninterruptible"]   = "Zauberleiste (nicht unterbrechbar)",

    -- Auras
    ["section_auras"]                   = "Auren",
    ["opt_np_show_auras"]               = "Auren anzeigen",
    ["opt_np_aura_size"]                = "Symbolgröße",
    ["opt_np_max_auras"]                = "Max. Anzahl",
    ["opt_np_only_my_debuffs"]          = "Nur eigene Debuffs",

    -- Enemy Buffs
    ["section_enemy_buffs"]              = "Feindliche Buffs",
    ["sublabel_enemy_buffs"]             = "— Feindliche Buffs —",
    ["opt_enemy_buffs_enable"]           = "Feindliche Buffs anzeigen",
    ["opt_enemy_buffs_max"]              = "Max. Buffs",
    ["opt_enemy_buffs_size"]             = "Buff-Symbolgröße",
    ["info_enemy_buffs"]                 = "Zeigt aktive Buffs (Wutanfall, Schilde...) auf feindlichen Einheiten. Symbole erscheinen oben rechts, stapeln sich nach oben.",
    ["opt_np_show_enemy_buffs"]          = "Feindliche Buffs anzeigen",
    ["opt_np_enemy_buff_size"]           = "Buff-Symbolgröße",
    ["opt_np_max_enemy_buffs"]           = "Max. feindliche Buffs",
    ["opt_np_enemy_buff_y_offset"]       = "Feindliche Buffs Y-Versatz",

    -- Transparency
    ["section_transparency"]            = "Transparenz",
    ["opt_np_selected_alpha"]           = "Alpha (ausgewählt)",
    ["opt_np_unselected_alpha"]         = "Alpha (nicht ausgewählt)",

    -- Stacking
    ["section_stacking"]                = "Stapeln",
    ["opt_np_overlap"]                  = "Vertikale Überlappung",
    ["opt_np_top_inset"]                = "Obere Bildschirmgrenze",

    -- Colors
    ["section_colors"]                  = "Farben",
    ["color_hostile"]                   = "Feindlich (Gegner)",
    ["color_neutral"]                   = "Neutral",
    ["color_friendly"]                  = "Freundlich",
    ["color_tapped"]                    = "Markiert (tapped)",
    ["color_focus"]                     = "Fokusziel",

    -- NPC Type Colors
    ["section_npc_type_colors"]         = "NSC-Typfarben",
    ["color_caster"]                    = "Zauberwirker",
    ["color_miniboss"]                  = "Mini-Boss (Elite + höhere Stufe)",
    ["color_enemy_in_combat"]           = "Feind (Standard)",
    ["info_np_darken_ooc"]              = "Feinde außerhalb des Kampfes werden automatisch abgedunkelt.",

    -- Classification colors
    ["section_classification_colors"]   = "Klassifizierungsfarben",
    ["opt_np_use_classification"]       = "Farben nach Gegnertyp",
    ["color_boss"]                      = "Boss",
    ["color_elite"]                     = "Elite / Mini-Boss",
    ["color_rare"]                      = "Selten",
    ["color_normal"]                    = "Normal",
    ["color_trivial"]                   = "Trivial",

    -- Tank mode
    ["section_tank_mode"]               = "Tank-Modus",
    ["opt_np_tank_mode"]                = "Tank-Modus aktivieren (Bedrohungsfarben)",
    ["color_no_threat"]                 = "Keine Bedrohung",
    ["color_low_threat"]                = "Niedrige Bedrohung",
    ["color_has_threat"]                = "Bedrohung gehalten",
    ["color_dps_has_aggro"]             = "DPS/Heiler hat Aggro",
    ["color_dps_near_aggro"]            = "DPS/Heiler nahe Aggro",

    -- NP health format
    ["np_fmt_percent"]                  = "Prozent (75%)",
    ["np_fmt_current"]                  = "Aktuell (25.3K)",
    ["np_fmt_current_percent"]          = "Aktuell + %",

    -- Reset
    ["btn_reset_nameplates"]            = "Nameplates zurücksetzen",

    -- =====================
    -- CONFIG: CD & Resource Panel
    -- =====================
    -- Resource colors
    ["section_resource_colors"]         = "Ressourcenfarben",
    ["res_runes_ready"]                 = "Runen (bereit)",
    ["res_runes_cd"]                    = "Runen (Abklingzeit)",

    -- Cooldown Manager
    ["tab_cdm"]                         = "Abklingzeiten",
    ["tab_resource_bars"]               = "Ressourcenleisten",
    ["tab_text_position"]               = "Text & Position",
    ["tab_rb_colors"]                   = "Farben",
    ["info_rb_colors_custom"]           = "Jede Farbe kann durch Klick auf das Farbfeld individuell angepasst werden.",

    ["section_cdm"]                     = "Abklingzeitenmanager",
    ["opt_cdm_enable"]                  = "Abklingzeitenmanager aktivieren",
    ["info_cdm_description"]            = "Reskin der Blizzard-CooldownManager-Symbole: abgerundete Ränder, Klassen-Overlay bei aktiven Auren, benutzerdefinierte Sweep-Farben, Utility-Dimmen, zentriertes Layout. Platzierung über Blizzard Edit Mode.",
    ["opt_cdm_show_hotkeys"]            = "Hotkeys anzeigen",
    ["opt_cdm_combat_alpha"]            = "Deckkraft ändern (Kampf / Ziel)",
    ["opt_cdm_alpha_combat"]            = "Alpha im Kampf",
    ["opt_cdm_alpha_target"]            = "Alpha mit Ziel (außerhalb Kampf)",
    ["opt_cdm_alpha_ooc"]               = "Alpha außerhalb Kampf",
    ["section_cdm_overlay"]             = "Overlay und Ränder",
    ["opt_cdm_custom_overlay"]          = "Benutzerdefinierte Overlay-Farbe",
    ["opt_cdm_overlay_color"]           = "Overlay-Farbe",
    ["opt_cdm_custom_swipe"]            = "Benutzerdefinierte aktive Sweep-Farbe",
    ["opt_cdm_swipe_color"]             = "Sweep-Farbe",
    ["opt_cdm_swipe_alpha"]             = "Sweep-Deckkraft",
    ["section_cdm_utility"]             = "Utility",
    ["opt_cdm_dim_utility"]             = "Utility-Symbole dimmen, wenn nicht auf CD",
    ["opt_cdm_dim_opacity"]             = "Dimm-Deckkraft",
    ["info_cdm_editmode"]               = "Die Platzierung erfolgt über den Blizzard Edit Mode (Esc → Edit Mode).",

    -- Resource Bars
    ["section_resource_bars"]           = "Ressourcenleisten",
    ["opt_rb_enable"]                   = "Ressourcenleisten aktivieren",
    ["info_rb_description"]             = "Zeigt Klassenressourcen (Mana, Wut, Energie, Kombopunkte, Runen usw.) mit adaptiver Druiden-Unterstützung.",
    ["section_visibility"]              = "Sichtbarkeit",
    ["opt_rb_visibility_mode"]          = "Sichtbarkeitsmodus",
    ["vis_always"]                      = "Immer sichtbar",
    ["vis_combat"]                      = "Nur im Kampf",
    ["vis_target"]                      = "Kampf oder Ziel",
    ["vis_hidden"]                      = "Versteckt",
    ["opt_rb_combat_alpha"]             = "Alpha im Kampf",
    ["opt_rb_ooc_alpha"]                = "Alpha außerhalb Kampf",
    ["opt_rb_width"]                    = "Breite",
    ["opt_rb_primary_height"]           = "Primärleistenhöhe",
    ["opt_rb_secondary_height"]         = "Sekundärleistenhöhe",
    ["opt_rb_global_scale"]             = "Globale Skalierung",
    ["opt_rb_sync_width"]               = "Breite mit Essential Cooldowns synchronisieren",
    ["btn_sync_now"]                    = "Jetzt synchronisieren",
    ["info_rb_sync"]                    = "Gleicht die Breite mit dem EssentialCooldownViewer des Blizzard-CooldownManagers ab.",

    -- Text & Font
    ["section_text_font"]               = "Text & Schrift",
    ["opt_rb_show_text"]                = "Text auf Leisten anzeigen",
    ["opt_rb_text_align"]               = "Textausrichtung",
    ["align_left"]                      = "Links",
    ["align_center"]                    = "Mitte",
    ["align_right"]                     = "Rechts",
    ["opt_rb_font_size"]                = "Schriftgröße",
    ["opt_rb_font"]                     = "Schriftart",
    ["font_default_wow"]                = "WoW-Standard",

    -- Position
    ["section_position"]                = "Position",
    ["info_rb_position"]                = "Verwende /tm uf zum Entsperren und Verschieben. Position wird automatisch gespeichert.",
    ["info_rb_druid"]                   = "Leisten passen sich automatisch an Klasse und Spezialisierung an.\nDruide: Ressource ändert sich mit Form (Bär → Wut, Katze → Energie, Eule → Astrale Macht).",

    -- =====================
    -- CONFIG: QOL Panel
    -- =====================
    ["tab_qol_cinematic"]               = "Zwischensequenz",
    ["tab_qol_auto_quest"]              = "Auto-Quest",
    ["tab_qol_automations"]             = "Automatisierungen",
    ["tab_qol_mythic_keys"]             = "M+-Schlüssel",
    ["tab_qol_skyride"]                 = "SkyRide",
    ["tab_qol_action_bars"]             = "Aktionsleisten",
    ["section_action_bars"]             = "Aktionsleisten-Skin",
    ["cat_action_bars"]                 = "Aktionsleisten",
    ["opt_abs_enable"]                  = "Aktionsleisten-Skin aktivieren",
    ["opt_abs_class_color"]             = "Klassenfarbe für Ränder",
    ["opt_abs_shift_reveal"]            = "Shift halten zum Einblenden versteckter Leisten",
    ["sublabel_bar_opacity"]            = "— Deckkraft pro Leiste —",
    ["opt_abs_select_bar"]              = "Aktionsleiste auswählen",
    ["opt_abs_opacity"]                 = "Deckkraft",
    ["btn_abs_apply_all_opacity"]       = "Auf alle Leisten anwenden",
    ["msg_abs_all_opacity"]             = "Deckkraft auf %d%% für alle Leisten gesetzt",
    ["sublabel_bar_combat"]             = "— Kampfsichtbarkeit —",
    ["opt_abs_combat_show"]             = "Nur im Kampf anzeigen",

    ["section_cinematic"]               = "Zwischensequenzen überspringen",
    ["opt_cinematic_auto_skip"]         = "Auto-überspringen nach erstem Ansehen",
    ["info_cinematic_viewed"]           = "Bereits gesehene Zwischensequenzen: %s\nVerlauf wird charakterübergreifend geteilt.",
    ["btn_clear_history"]               = "Verlauf löschen",

    -- Auto Quest
    ["section_auto_quest"]              = "Auto-Quest",
    ["opt_quest_auto_accept"]           = "Quests automatisch annehmen",
    ["opt_quest_auto_turnin"]           = "Quests automatisch abgeben",
    ["opt_quest_auto_gossip"]           = "Dialogoptionen automatisch wählen",
    ["info_quest_shift"]                = "SHIFT halten zum vorübergehenden Deaktivieren.\nQuests mit mehreren Belohnungen werden nicht automatisch abgegeben.",

    -- Objective Tracker Skin
    ["tab_qol_obj_tracker"]             = "Zielverfolgung",
    ["section_obj_tracker"]             = "Zielverfolgung-Skin",
    ["opt_obj_tracker_enable"]          = "Zielverfolgung-Skin aktivieren",
    ["opt_obj_tracker_bg_alpha"]        = "Hintergrund-Deckkraft",
    ["opt_obj_tracker_border"]          = "Rahmen anzeigen",
    ["opt_obj_tracker_hide_empty"]      = "Ausblenden wenn leer",
    ["opt_obj_tracker_header_size"]     = "Kopfzeilen-Schriftgröße",
    ["opt_obj_tracker_cat_size"]        = "Kategorie-Schriftgröße",
    ["opt_obj_tracker_quest_size"]      = "Quest-Titel-Schriftgröße",
    ["opt_obj_tracker_obj_size"]        = "Ziel-Schriftgröße",
    ["opt_obj_tracker_max_quests"]       = "Max. angezeigte Quests (0 = unbegrenzt)",
    ["ot_overflow_text"]                 = "%d weitere Quest(s) ausgeblendet...",
    ["info_obj_tracker"]                = "Skinnt die Blizzard-Zielverfolgung mit dunklem Panel, eigenen Schriften und farbigen Kategorieüberschriften.",
    ["ot_header_title"]                 = "ZIELE",
    ["ot_header_options"]               = "Optionen",

    -- Automations
    ["section_automations"]             = "Automatisierungen",
    ["opt_hide_blizzard_castbar"]       = "Blizzard-Zauberleiste ausblenden",

    -- Auto Accept Invite
    ["sublabel_auto_accept_invite"]     = "— Auto-Einladungsannahme —",
    ["sublabel_auto_skip_role"]         = "— Auto-Rollenprüfung überspringen —",
    ["sublabel_tooltip_ids"]            = "— Tooltip-IDs —",
    ["sublabel_combat_res_tracker"]     = "— Kampfwiederbelebungs-Tracker —",
    ["opt_cr_show_rating"]              = "M+-Wertung anzeigen",
    ["opt_show_messages"]               = "Chatnachrichten anzeigen",
    ["opt_tid_spell"]                   = "Zauber-/Aura-ID",
    ["opt_tid_item"]                    = "Gegenstands-ID",
    ["opt_tid_npc"]                     = "NSC-ID",
    ["opt_tid_quest"]                   = "Quest-ID",
    ["opt_tid_mount"]                   = "Reittier-ID",
    ["opt_tid_currency"]                = "Währungs-ID",
    ["opt_tid_achievement"]             = "Erfolgs-ID",
    ["opt_accept_friends"]              = "Von Freunden annehmen",
    ["opt_accept_guild"]                = "Von Gilde annehmen",

    -- Auto Summon
    ["sublabel_auto_summon"]            = "— Auto-Beschwörung —",
    ["opt_summon_delay"]                = "Verzögerung (Sekunden)",

    -- Auto Fill Delete
    ["sublabel_auto_fill_delete"]       = "— Auto-LÖSCHEN ausfüllen —",
    ["opt_focus_ok_button"]             = "OK-Button nach Ausfüllen fokussieren",

    -- Mythic+ Keys
    ["section_mythic_keys"]             = "Mythisch+-Schlüssel",
    ["opt_keys_enable_tracker"]         = "Tracker aktivieren",
    ["opt_keys_mini_frame"]             = "Mini-Frame auf M+-Oberfläche",
    ["opt_keys_auto_refresh"]           = "Automatisch aktualisieren",

    -- SkyRide
    ["section_skyride"]                 = "SkyRide",
    ["opt_skyride_enable"]              = "Aktivieren (Fluganzeige)",
    ["section_skyride_dims"]            = "Abmessungen",
    ["opt_skyride_bar_height"]          = "Geschwindigkeitsleistenhöhe",
    ["opt_skyride_charge_height"]       = "Aufladungsleistenhöhe",
    ["opt_skyride_charge_gap"]          = "Abstand zwischen Segmenten",
    ["section_skyride_text"]            = "Text",
    ["opt_skyride_show_speed_text"]     = "Geschwindigkeitsprozent anzeigen",
    ["opt_skyride_speed_font_size"]     = "Geschwindigkeitstext-Schriftgröße",
    ["opt_skyride_show_charge_timer"]   = "Aufladungstimer anzeigen",
    ["opt_skyride_charge_font_size"]    = "Aufladungstimer-Schriftgröße",
    ["btn_reset_skyride"]               = "SkyRide-Position zurücksetzen",

    -- =====================
    -- CONFIG: QOL — CVar Optimizer
    -- =====================
    ["tab_qol_cvar_opt"]                = "Perf CVars",
    ["section_cvar_optimizer"]          = "CVar-Optimierer",
    ["info_cvar_optimizer"]             = "Wendet empfohlene Grafik-/Leistungseinstellungen an. Deine aktuellen Werte werden gespeichert und können jederzeit wiederhergestellt werden.",
    ["btn_cvar_apply_all"]              = ">> Alle anwenden",
    ["btn_cvar_revert_all"]             = "<< Alle wiederherstellen",
    ["btn_cvar_apply"]                  = "Anwenden",
    ["btn_cvar_revert"]                 = "Wiederherstellen",
    -- Categories
    ["opt_cat_render"]                  = "Rendering & Anzeige",
    ["opt_cat_graphics"]                = "Grafikqualität",
    ["opt_cat_detail"]                  = "Sichtweite & Details",
    ["opt_cat_advanced"]                = "Erweitert",
    ["opt_cat_fps"]                     = "FPS-Begrenzungen",
    ["opt_cat_post"]                    = "Nachbearbeitung",
    -- CVar labels
    ["opt_cvar_render_scale"]           = "Renderskalierung",
    ["opt_cvar_vsync"]                  = "VSync",
    ["opt_cvar_msaa"]                   = "Multisampling (MSAA)",
    ["opt_cvar_low_latency"]            = "Niedriger Latenz-Modus",
    ["opt_cvar_anti_aliasing"]          = "Kantenglättung",
    ["opt_cvar_shadow"]                 = "Schattenqualität",
    ["opt_cvar_ssao"]                   = "SSAO",
    ["opt_cvar_depth"]                  = "Tiefeneffekte",
    ["opt_cvar_compute"]                = "Berechnungseffekte",
    ["opt_cvar_particle"]               = "Partikeldichte",
    ["opt_cvar_liquid"]                 = "Flüssigkeitsdetails",
    ["opt_cvar_spell_density"]          = "Zauberdichte",
    ["opt_cvar_projected"]              = "Projizierte Texturen",
    ["opt_cvar_outline"]                = "Umrissmodus",
    ["opt_cvar_texture_res"]            = "Texturauflösung",
    ["opt_cvar_view_distance"]          = "Sichtweite",
    ["opt_cvar_env_detail"]             = "Umgebungsdetails",
    ["opt_cvar_ground"]                 = "Bodenbewuchs",
    ["opt_cvar_gfx_api"]                = "Grafik-API",
    ["opt_cvar_triple_buffering"]       = "Dreifachpufferung",
    ["opt_cvar_texture_filtering"]      = "Texturfilterung",
    ["opt_cvar_rt_shadows"]             = "Raytracing-Schatten",
    ["opt_cvar_resample_quality"]       = "Resample-Qualität",
    ["opt_cvar_physics"]                = "Physikstufe",
    ["opt_cvar_target_fps"]             = "Ziel-FPS",
    ["opt_cvar_bg_fps_enable"]          = "Hintergrund-FPS-Begrenzung",
    ["opt_cvar_bg_fps"]                 = "Hintergrund-FPS-Wert",
    ["opt_cvar_resample_sharpness"]     = "Resample-Schärfe",
    ["opt_cvar_camera_shake"]           = "Kamerawackeln",
    -- Messages
    ["msg_cvar_applied"]                = "CVars angewendet",
    ["msg_cvar_reverted"]               = "CVars wiederhergestellt",
    ["msg_cvar_no_backup"]              = "Kein Backup gefunden — zuerst anwenden.",
    ["tab_qol_leveling"]                = "Leveling",
    ["section_leveling_bar"]            = "Leveling-Leiste",
    ["opt_leveling_enable"]             = "Leveling-Leiste aktivieren",
    ["opt_leveling_width"]              = "Leistenbreite",
    ["opt_leveling_height"]             = "Leistenhöhe",
    ["btn_reset_leveling_pos"]          = "Position zurücksetzen",
    ["leveling_bar_title"]              = "Leveling-Leiste",
    ["leveling_level"]                  = "Stufe",
    ["leveling_progress"]               = "Fortschritt:",
    ["leveling_rested"]                 = "Ausgeruht",
    ["leveling_last_quest"]             = "Letzte Quest:",
    ["leveling_ttl"]                    = "Zeit bis Level:",
    ["leveling_drag_hint"]              = "/tm sr zum Entsperren & Verschieben",

    -- =====================
    -- CONFIG: Profiles Panel (3 Tabs)
    -- =====================
    ["tab_profiles"]                    = "Profile",
    ["tab_import_export"]               = "Import/Export",
    ["tab_resets"]                      = "Zurücksetzen",

    -- Tab 1: Named profiles & specializations
    ["section_named_profiles"]          = "Profile",
    ["info_named_profiles"]             = "Erstelle und verwalte benannte Profile. Jedes Profil speichert einen vollständigen Schnappschuss deiner Einstellungen.",
    ["profile_active_label"]            = "Aktives Profil",
    ["opt_select_profile"]              = "Profil wählen",
    ["sublabel_create_profile"]         = "— Neues Profil erstellen —",
    ["placeholder_profile_name"]        = "Profilname...",
    ["btn_create_profile"]              = "Profil erstellen",
    ["btn_delete_named_profile"]        = "Profil löschen",
    ["btn_save_profile"]                = "Aktuelles Profil speichern",
    ["info_save_profile"]               = "Speichert alle aktuellen Einstellungen im aktiven Profil. Dies geschieht automatisch beim Profilwechsel.",

    ["section_profile_mode"]            = "Profilmodus",
    ["info_spec_profiles"]              = "Aktiviere Spezialisierungsprofile zum automatischen Speichern und Laden der Einstellungen beim Spezialisierungswechsel.\nJede Spezialisierung erhält eine eigene Konfiguration.",
    ["opt_enable_spec_profiles"]        = "Spezialisierungsprofile aktivieren",
    ["profile_status"]                  = "Aktives Profil",
    ["profile_global"]                  = "Global (einzelnes Profil)",
    ["section_spec_list"]               = "Spezialisierungen",
    ["profile_badge_active"]            = "Aktiv",
    ["profile_badge_saved"]             = "Gespeichert",
    ["profile_badge_none"]              = "Kein Profil",
    ["btn_copy_to_spec"]                = "Aktuelles kopieren",
    ["btn_delete_profile"]              = "Löschen",
    ["info_spec_reload"]                = "Spezialisierungswechsel mit aktivierten Profilen lädt die Oberfläche automatisch neu, um das entsprechende Profil anzuwenden.",
    ["info_global_mode"]                = "Alle Spezialisierungen teilen die gleichen Einstellungen. Aktiviere Spezialisierungsprofile oben, um verschiedene Konfigurationen zu nutzen.",

    -- Tab 2: Import / Export
    ["section_export"]                  = "Einstellungen exportieren",
    ["info_export"]                     = "Erstellt eine komprimierte Zeichenkette aller aktuellen Einstellungen.\nKopiere sie zum Teilen oder als Backup.",
    ["label_export_string"]             = "Exportstring (klicken um alles auszuwählen)",
    ["btn_export"]                      = "Exportstring generieren",
    ["btn_copy_clipboard"]              = "Text kopieren",
    ["section_import"]                  = "Einstellungen importieren",
    ["info_import"]                     = "Füge unten einen Exportstring ein. Er wird vor der Anwendung validiert.",
    ["label_import_string"]             = "Importstring hier einfügen",
    ["btn_import"]                      = "Importieren & Anwenden",
    ["btn_paste_clipboard"]             = "Text einfügen",
    ["import_preview"]                  = "Klasse: %s | Module: %s | Datum: %s",
    ["import_preview_valid"]            = "✓ Gültiger String",
    ["import_preview_invalid"]          = "Ungültiger oder beschädigter String",
    ["info_import_warning"]             = "Der Import ÜBERSCHREIBT alle aktuellen Einstellungen und lädt die Oberfläche neu. Dies kann nicht rückgängig gemacht werden.",

    -- Tab 3: Resets
    ["section_profile_mgmt"]            = "Profilverwaltung",
    ["info_profiles"]                   = "Setze einzelne Module zurück oder exportiere/importiere deine Einstellungen.\nExport kopiert Einstellungen in die Zwischenablage (benötigt LibSerialize + LibDeflate).",
    ["section_reset_module"]            = "Modul zurücksetzen",
    ["btn_reset_prefix"]                = "Zurücksetzen: ",
    ["btn_reset_all_reload"]            = "(!) ALLES ZURÜCKSETZEN + Neuladen",
    ["section_reset_all"]               = "Vollständiges Zurücksetzen",
    ["info_resets"]                     = "Setze ein einzelnes Modul auf Standardwerte zurück. Das Modul wird mit Werkseinstellungen neu geladen.",
    ["info_reset_all_warning"]          = "Dies setzt ALLE Module und ALLE Einstellungen auf Werkseinstellungen zurück und lädt dann die Oberfläche neu.",

    -- =====================
    -- PRINT MESSAGES: Core
    -- =====================
    ["msg_db_reset"]                    = "Datenbank zurückgesetzt",
    ["msg_module_reset"]                = "Modul '%s' zurückgesetzt",
    ["msg_db_not_init"]                 = "Datenbank nicht initialisiert",
    ["msg_loaded"]                      = "v2.0 geladen — %s für Konfiguration",
    ["msg_help_title"]                  = "v2.0 — Befehle:",
    ["msg_help_open"]                   = "Konfiguration öffnen",
    ["msg_help_reset"]                  = "Alles zurücksetzen + Neuladen",
    ["msg_help_uf"]                     = "UnitFrames + Ressourcen sperren/entsperren",
    ["msg_help_uf_reset"]               = "UnitFrames zurücksetzen",
    ["msg_help_rb"]                     = "Ressourcenleisten sperren/entsperren",
    ["msg_help_rb_sync"]                = "Breite mit Essential Cooldowns synchronisieren",
    ["msg_help_np"]                     = "Nameplates ein/ausschalten",
    ["msg_help_minimap"]                = "Minimap zurücksetzen",
    ["msg_help_panel"]                  = "Infopanel zurücksetzen",
    ["msg_help_cursor"]                 = "Cursorring zurücksetzen",
    ["msg_help_clearcinema"]            = "Zwischensequenz-Verlauf löschen",
    ["msg_help_sr"]                     = "SkyRide + Anker sperren/entsperren",
    ["msg_help_key"]                    = "Mythisch+-Schlüssel öffnen",
    ["msg_help_help"]                   = "Diese Hilfe",

    -- =====================
    -- PRINT MESSAGES: Modules
    -- =====================
    -- CDM
    ["msg_cdm_status"]                  = "Aktiviert",
    ["msg_cdm_disabled"]                = "Deaktiviert",

    -- Nameplates
    ["msg_np_enabled"]                  = "Aktiviert",
    ["msg_np_disabled"]                 = "Deaktiviert",

    -- UnitFrames
    ["msg_uf_locked"]                   = "Gesperrt",
    ["msg_uf_unlocked"]                 = "Entsperrt — Ziehen zum Neupositionieren",
    ["msg_uf_initialized"]              = "Initialisiert — /tm uf zum Sperren/Entsperren",
    ["msg_uf_enabled"]                  = "aktiviert (Neuladen erforderlich)",
    ["msg_uf_disabled"]                 = "deaktiviert (Neuladen erforderlich)",
    ["msg_uf_position_reset"]           = "Position zurückgesetzt",

    -- ResourceBars
    ["msg_rb_width_synced"]             = "Breite synchronisiert (%dpx)",
    ["msg_rb_locked"]                   = "Gesperrt",
    ["msg_rb_unlocked"]                 = "Entsperrt — Ziehen zum Neupositionieren",
    ["msg_rb_position_reset"]           = "Position der Ressourcenleisten zurückgesetzt",

    -- SkyRide
    ["msg_sr_pos_saved"]                = "SkyRide-Position gespeichert",
    ["msg_sr_locked"]                   = "SkyRide gesperrt",
    ["msg_sr_unlock"]                   = "SkyRide-Verschiebemodus aktiviert – Klicken und ziehen",
    ["msg_sr_pos_reset"]                = "SkyRide-Position zurückgesetzt",
    ["msg_sr_db_not_init"]              = "TomoModDB nicht initialisiert",
    ["msg_sr_initialized"]              = "SkyRide-Modul initialisiert",

    -- FrameAnchors
    ["anchor_alert"]                    = "Warnungen",
    ["anchor_loot"]                     = "Beute",
    ["msg_anchors_locked"]              = "Gesperrt",
    ["msg_anchors_unlocked"]            = "Entsperrt — Anker verschieben",

    -- AutoVendorRepair
    ["msg_avr_header"]                  = "[AutoHändlerReparatur]",
    ["msg_avr_sold"]                    = " Graue Gegenstände verkauft für |cffffff00%s|r",
    ["msg_avr_repaired"]                = " Ausrüstung repariert für |cffffff00%s|r",

    -- AutoFillDelete
    ["msg_afd_filled"]                  = "Text 'LÖSCHEN' automatisch ausgefüllt – Klicke OK zum Bestätigen",
    ["msg_afd_db_not_init"]             = "TomoModDB nicht initialisiert",
    ["msg_afd_initialized"]             = "AutoFillDelete-Modul initialisiert",
    ["msg_afd_enabled"]                 = "Auto-Ausfüllen LÖSCHEN aktiviert",
    ["msg_afd_disabled"]                = "Auto-Ausfüllen LÖSCHEN deaktiviert (Hook bleibt aktiv)",

    -- HideCastBar
    ["msg_hcb_db_not_init"]             = "TomoModDB nicht initialisiert",
    ["msg_hcb_initialized"]             = "HideCastBar-Modul initialisiert",
    ["msg_hcb_hidden"]                  = "Zauberleiste ausgeblendet",
    ["msg_hcb_shown"]                   = "Zauberleiste eingeblendet",

    -- AutoAcceptInvite
    ["msg_aai_accepted"]                = "Einladung angenommen von ",
    ["msg_aai_ignored"]                 = "Einladung ignoriert von ",
    ["msg_aai_enabled"]                 = "Auto-Einladungsannahme aktiviert",
    ["msg_aai_disabled"]                = "Auto-Einladungsannahme deaktiviert",
    ["msg_asr_lfg_accepted"]            = "Rollenprüfung automatisch bestätigt",
    ["msg_asr_poll_accepted"]           = "Rollenumfrage automatisch bestätigt",
    ["msg_asr_enabled"]                 = "Auto-Rollenprüfung überspringen aktiviert",
    ["msg_asr_disabled"]                = "Auto-Rollenprüfung überspringen deaktiviert",
    ["msg_tid_enabled"]                 = "Tooltip-IDs aktiviert",
    ["msg_tid_disabled"]                = "Tooltip-IDs deaktiviert",
    ["msg_cr_enabled"]                  = "Kampfwiederbelebungs-Tracker aktiviert",
    ["msg_cr_disabled"]                 = "Kampfwiederbelebungs-Tracker deaktiviert",
    ["msg_cr_locked"]                   = "Kampfwiederbelebungs-Tracker gesperrt",
    ["msg_cr_unlock"]                   = "Kampfwiederbelebungs-Tracker entsperrt — ziehen zum Verschieben",
    ["msg_abs_enabled"]                 = "Aktionsleisten-Skin aktiviert (Neuladen empfohlen)",
    ["msg_abs_disabled"]                = "Aktionsleisten-Skin deaktiviert",
    ["opt_buffskin_enable"]             = "Buff-Skin aktivieren",
    ["opt_buffskin_desc"]               = "Fügt schwarze Ränder und farbige Timer auf Spieler-Buffs/Debuffs hinzu",
    ["msg_buffskin_enabled"]            = "Buff-Skin aktiviert",
    ["msg_buffskin_disabled"]           = "Buff-Skin deaktiviert",
    ["msg_help_cr"]                     = "Kampfwiederbelebungs-Tracker sperren/entsperren",
    ["msg_help_cs"]                     = "Charakterbogen sperren/entsperren",
    ["msg_help_cs_reset"]               = "Charakterbogen auf Standardposition zurücksetzen",

    -- CinematicSkip
    ["msg_cin_skipped"]                 = "Zwischensequenz übersprungen (bereits gesehen)",
    ["msg_vid_skipped"]                 = "Video übersprungen (bereits gesehen)",
    ["msg_vid_id_skipped"]              = "Video #%d übersprungen",
    ["msg_cin_cleared"]                 = "Zwischensequenz-Verlauf gelöscht",

    -- AutoSummon
    ["msg_sum_accepted"]                = "Beschwörung angenommen von %s nach %s (%s)",
    ["msg_sum_ignored"]                 = "Beschwörung ignoriert von %s (nicht vertrauenswürdig)",
    ["msg_sum_enabled"]                 = "Auto-Beschwörung aktiviert",
    ["msg_sum_disabled"]                = "Auto-Beschwörung deaktiviert",
    ["msg_sum_manual"]                  = "Beschwörung manuell angenommen",
    ["msg_sum_no_pending"]              = "Keine ausstehende Beschwörung",

    -- MythicKeys
    ["msg_keys_no_key"]                 = "Kein Schlüssel zum Senden.",
    ["msg_keys_not_in_group"]           = "Du musst in einer Gruppe sein.",
    ["msg_keys_reload"]                 = "Änderung wird beim nächsten /reload angewendet.",
    ["mk_not_in_group"]                 = "Du bist nicht in einer Gruppe.",
    ["mk_not_in_group_short"]           = "Nicht in Gruppe.",
    ["mk_no_key_self"]                  = "Kein Schlüsselstein gefunden.",
    ["mk_title"]                        = "TM — Mythisch+ Schlüssel",
    ["mk_btn_send"]                     = "Im Chat senden",
    ["mk_btn_refresh"]                  = "Aktualisieren",
    ["mk_tab_keys"]                     = "Schlüssel",
    ["mk_tab_tp"]                       = "TP",
    ["mk_tp_click_to_tp"]              = "Klicken zum Teleportieren",
    ["mk_tp_not_unlocked"]             = "Nicht freigeschaltet",
    ["msg_tp_not_owned"]               = "Du besitzt den Teleport für %s nicht",
    ["msg_tp_combat"]                  = "Teleporte können im Kampf nicht aktualisiert werden.",

    -- =====================
    -- PRINT MESSAGES: Config Panels
    -- =====================
    ["msg_np_reset"]                    = "Nameplates zurückgesetzt (Neuladen empfohlen)",
    ["msg_uf_toggle"]                   = "UnitFrames %s (Neuladen)",
    ["msg_profile_reset"]               = "%s zurückgesetzt",
    ["msg_profile_copied"]              = "Aktuelle Einstellungen nach '%s' kopiert",
    ["msg_profile_deleted"]             = "Profil gelöscht für '%s'",
    ["msg_profile_loaded"]              = "Profil '%s' geladen — Neuladen zum Anwenden",
    ["msg_profile_load_failed"]         = "Laden des Profils '%s' fehlgeschlagen",
    ["msg_profile_created"]             = "Profil '%s' mit aktuellen Einstellungen erstellt",
    ["msg_profile_name_empty"]          = "Bitte einen Profilnamen eingeben",
    ["msg_profile_saved"]               = "Einstellungen im Profil '%s' gespeichert",

    -- New profile keys v2.3.0
    ["btn_rename_profile"]              = "Umbenennen",
    ["btn_duplicate_profile"]           = "Duplizieren",
    ["btn_load_profile"]                = "Laden",
    ["btn_close"]                       = "Schließen",
    ["btn_cancel"]                      = "Abbrechen",
    ["section_spec_assign"]             = "Profile pro Spezialisierung",
    ["info_spec_assign"]                = "Weise jeder Spezialisierung ein benanntes Profil zu. TomoMod wechselt automatisch das Profil beim Spezialisierungswechsel.",
    ["spec_profile_none"]               = "— Keins —",
    ["popup_rename_profile"]            = "|cff0cd29fTomoMod|r\n\nNeuer Name für '%s':",
    ["popup_duplicate_profile"]         = "|cff0cd29fTomoMod|r\n\n'%s' duplizieren als:",
    ["msg_profile_renamed"]             = "Profil '%s' umbenannt zu '%s'",
    ["msg_profile_duplicated"]          = "Profil '%s' dupliziert als '%s'",
    ["msg_import_as_profile"]           = "Profil importiert als '%s'",
    ["popup_export_title"]              = "Profil exportieren",
    ["popup_export_hint"]               = "Alles auswählen (Strg+A) und kopieren (Strg+C)",
    ["popup_import_title"]              = "Profil importieren",
    ["popup_import_hint"]               = "TomoMod-Exportstring einfügen, dann auf Importieren klicken",
    ["label_import_profile_name"]       = "Speichern als Profilname:",
    ["placeholder_import_profile_name"] = "Profilname (optional)...",
    ["msg_profile_name_deleted"]        = "Profil '%s' gelöscht",
    ["msg_export_success"]              = "Exportstring generiert — alles auswählen und kopieren",
    ["msg_import_success"]              = "Einstellungen erfolgreich importiert — Neuladen...",
    ["msg_import_empty"]                = "Nichts zu importieren — zuerst einen String einfügen",
    ["msg_copy_hint"]                   = "Text ausgewählt — Strg+C zum Kopieren drücken",
    ["msg_copy_empty"]                  = "Zuerst einen Exportstring generieren",
    ["msg_paste_hint"]                  = "Strg+V drücken um den Importstring einzufügen",
    ["msg_spec_changed_reload"]         = "Spezialisierung geändert — Profil wird geladen...",

    -- =====================
    -- INFO PANEL (Minimap)
    -- =====================
    ["time_server"]                     = "Server",
    ["time_local"]                      = "Lokal",
    ["time_tooltip_title"]              = "Uhrzeit (%s - %s)",
    ["time_tooltip_left_click"]         = "|cff0cd29fLinksklick:|r Kalender",
    ["time_tooltip_right_click"]        = "|cff0cd29fRechtsklick:|r Server / Lokal",
    ["time_tooltip_shift_right"]        = "|cff0cd29fShift + Rechtsklick:|r 12h / 24h",
    ["time_format_msg"]                 = "Format: %s",
    ["time_mode_msg"]                   = "Uhrzeit: %s",

    -- =====================
    -- ENABLED / DISABLED (generic)
    -- =====================
    ["enabled"]                         = "Aktiviert",
    ["disabled"]                        = "Deaktiviert",

    -- Static Popups
    ["popup_reset_text"]                = "|cff0cd29fTomoMod|r\n\nALLE Einstellungen zurücksetzen?\nDies lädt die Oberfläche neu.",
    ["popup_confirm"]                   = "Bestätigen",
    ["popup_cancel"]                    = "Abbrechen",
    ["popup_import_text"]               = "|cff0cd29fTomoMod|r\n\nEinstellungen importieren?\nDies ÜBERSCHREIBT alle aktuellen Einstellungen und lädt die Oberfläche neu.",
    ["popup_profile_reload"]            = "|cff0cd29fTomoMod|r\n\nProfilmodus geändert.\nOberfläche neu laden zum Anwenden?",
    ["popup_delete_profile"]            = "|cff0cd29fTomoMod|r\n\nProfil '%s' löschen?\nDies kann nicht rückgängig gemacht werden.",

    -- FPS element
    ["label_fps"]                       = "FPS",

    -- =====================
    -- BOSS FRAMES
    -- =====================
    ["tab_boss"]                        = "Boss",
    ["section_boss_frames"]             = "Boss-Leisten",
    ["opt_boss_enable"]                 = "Boss-Leisten aktivieren",
    ["opt_boss_height"]                 = "Leistenhöhe",
    ["opt_boss_spacing"]                = "Abstand zwischen Leisten",
    ["info_boss_drag"]                  = "Entsperren (/tm uf) zum Verschieben. Boss 1 ziehen, um alle 5 Leisten gemeinsam zu positionieren.",
    ["info_boss_colors"]                = "Leistenfarben nutzen Nameplate-Klassifizierungsfarben (Boss = rot, Mini-Boss = lila).",
    ["msg_boss_initialized"]            = "Boss-Leisten geladen.",

    -- =====================
    -- SOUND / LUST DETECTION
    -- =====================
    ["cat_sound"]                       = "Sound",
    ["tab_sound_general"]               = "Allgemein",
    ["tab_sound_detection"]             = "Erkennung",
    ["section_sound_general"]           = "Bloodlust-Sound",
    ["info_sound_desc"]                 = "Spielt einen benutzerdefinierten Sound ab, wenn ein Bloodlust-Effekt auf deinem Charakter erkannt wird. Die Erkennung nutzt eine Kombination aus Haste-Spitzen und Sated-Debuff-Erkennung.",
    ["opt_sound_enable"]                = "Bloodlust-Erkennung aktivieren",
    ["sublabel_sound_choice"]           = "Sound & Kanal",
    ["opt_sound_file"]                  = "Abzuspielender Sound",
    ["opt_sound_channel"]               = "Audiokanal",
    ["btn_sound_preview"]               = ">> Sound anhören",
    ["btn_sound_stop"]                  = "■  Stoppen",
    ["opt_sound_chat"]                  = "Chatnachrichten anzeigen",
    ["opt_sound_debug"]                 = "Debug-Modus (Haste in Echtzeit)",
    ["section_sound_detection"]         = "Erkennungseinstellungen",
    ["info_sound_detection_desc"]       = "Diese Einstellungen steuern die Empfindlichkeit der Bloodlust-Erkennung über Haste-Schwankungen. Niedrigere Werte lösen häufiger aus (z.B. Power Infusion).",
    ["opt_sound_spike_ratio"]           = "Spike-Verhältnis",
    ["info_sound_spike_tooltip"]        = "Verhältnis des aktuellen Haste zum Durchschnitt. 160% = Haste muss 1,6× den Durchschnitt betragen. (Standard: 160%)",
    ["opt_sound_jump_ratio"]            = "Sprung-Verhältnis",
    ["info_sound_jump_tooltip"]         = "Verhältnis zum letzten Maximum. Verhindert, dass langsame Anstiege die Erkennung auslösen. (Standard: 140%)",
    ["opt_sound_fade_ratio"]            = "Abkling-Verhältnis",
    ["info_sound_fade_tooltip"]         = "Wenn Haste unter dieses Verhältnis zur Baseline fällt, gilt der Effekt als beendet. (Standard: 115%)",
    ["btn_sound_reset_detection"]       = "Verhältnisse zurücksetzen",
    ["msg_sound_detection_reset"]       = "Erkennungsverhältnisse zurückgesetzt.",

    -- =====================
    -- BAG & MICRO MENU
    -- =====================
    ["tab_qol_bag_micro"]               = "Tasche & Menü",
    ["section_bag_micro"]               = "Taschenleiste & Mikromenü",
    ["info_bag_micro"]                  = "Wähle, ob immer angezeigt oder bei Mauszeigerkontakt eingeblendet wird.",
    ["sublabel_bag_bar"]                = "— Taschenleiste —",
    ["sublabel_micro_menu"]             = "— Mikromenü —",
    ["opt_bag_bar_mode"]                = "Taschenleiste",
    ["opt_micro_menu_mode"]             = "Mikromenü",
    ["mode_show"]                       = "Immer sichtbar",
    ["mode_hover"]                      = "Bei Hover anzeigen",

    -- =====================
    -- CHARACTER SKIN
    -- =====================
    ["tab_qol_char_skin"]               = "Charakter-Skin",
    ["section_char_skin"]               = "Charakterbogen-Skin",
    ["info_char_skin_desc"]             = "Wendet das dunkle TomoMod-Thema auf Charakterbogen, Ruf, Währungen und Inspektionsfenster an.",
    ["opt_char_skin_enable"]            = "Charakter-Skin aktivieren",
    ["opt_char_skin_character"]         = "Skin Charakter / Ruf / Währungen",
    ["opt_char_skin_inspect"]           = "Skin Inspektionsfenster",
    ["opt_char_skin_iteminfo"]          = "Gegenstandsinfo auf Plätzen anzeigen",
    ["opt_char_skin_gems"]              = "Edelstein-Sockel auf Plätzen anzeigen",
    ["opt_char_skin_midnight"]          = "Midnight-Verzauberungen (Kopf/Schultern statt Armschienen/Umhang)",
    ["opt_char_skin_scale"]             = "Fensterskalierung",
    ["msg_char_skin_reload"]            = "Charakter-Skin: /reload zum Anwenden.",

    -- =====================
    -- LAYOUT / MOVERS SYSTEM
    -- =====================
    ["btn_layout"]                      = "Layout",
    ["btn_layout_tooltip"]              = "Layout-Modus: alle UI-Elemente zum Verschieben entsperren.",
    ["btn_reload_ui"]                   = "UI neuladen",
    ["layout_mode_title"]               = "TomoMod — Layout-Modus",
    ["layout_mode_hint"]                = "Elemente ziehen zum Neupositionieren — Sperren klicken wenn fertig",
    ["layout_btn_lock"]                 = "Sperren",
    ["layout_btn_reload"]               = "RL",
    ["grid_dimmed"]                    = "Raster",
    ["grid_bright"]                    = "Raster +",
    ["grid_disabled"]                  = "Raster AUS",
    ["layout_unlocked"]                 = "Layout-Modus AN — Elemente ziehen. Sperren klicken oder /tm layout wenn fertig.",
    ["layout_locked"]                   = "Layout-Modus AUS — Positionen gespeichert.",
    ["msg_help_layout"]                 = "Layout-Modus umschalten (alle UI-Elemente verschieben)",
    ["mover_unitframes"]                = "Unit Frames",
    ["mover_resources"]                 = "Ressourcenleisten",
    ["mover_skyriding"]                 = "Skyriding-Leiste",
    ["mover_levelingbar"]               = "XP / Leveling-Leiste",
    ["mover_anchors"]                   = "Warn- & Beuteanker",
    ["mover_cotank"]                    = "Co-Tank-Tracker",
    ["mover_repbar"]                    = "Rufleiste",
    ["mover_castbar"]                   = "Spieler-Zauberleiste",

    -- =====================
    -- COMBAT TEXT
    -- =====================
    ["sublabel_combat_text"]             = "— Kampftext —",
    ["opt_combat_text_enable"]           = "Kampftext aktivieren",
    ["opt_combat_text_offset_x"]         = "Versatz X",
    ["opt_combat_text_offset_y"]         = "Versatz Y",

    -- =====================
    -- SKINS (Chat)
    -- =====================
    ["tab_qol_skins"]                    = "Skins",
    ["section_skins"]                    = "UI-Skins",
    ["info_skins_desc"]                  = "Wendet das dunkle TomoMod-Design auf verschiedene Blizzard-UI-Elemente an. Ein /reload kann nötig sein.",
    ["sublabel_chat_skin"]               = "— Chat-Fenster —",
    ["opt_chat_skin_enable"]             = "Chat-Fenster-Skin",
    ["opt_chat_skin_bg_alpha"]           = "Hintergrund-Deckkraft",
    ["opt_chat_skin_font_size"]          = "Chat-Schriftgröße",
    ["msg_chat_skin_enabled"]            = "Chat-Skin aktiviert",
    ["msg_chat_skin_disabled"]           = "Chat-Skin deaktiviert (Reload zum Zurücksetzen)",
    ["sublabel_mail_skin"]               = "— Postfenster —",
    ["opt_mail_skin_enable"]             = "Postfenster-Skin",
    ["msg_mail_skin_enabled"]            = "Post-Skin aktiviert",
    ["msg_mail_skin_disabled"]           = "Post-Skin deaktiviert (Reload zum Zurücksetzen)",
})
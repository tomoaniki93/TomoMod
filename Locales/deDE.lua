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
    ["cat_mythicplus"]      = "Mythic+",
    ["cat_profiles"]        = "Profile",

    -- =====================
    -- CONFIG: General Panel
    -- =====================
    ["section_about"]                   = "Über",
    ["about_text"]                      = "|cff0cd29fTomoMod|r v2.8.11 von TomoAniki\nLeichtgewichtige Oberfläche mit QOL, UnitFrames und Nameplates.\nTippe /tm help für die Befehlsliste.",
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
    ["opt_raid_icon_x"]                 = "Raidmarkierung X",
    ["opt_raid_icon_y"]                 = "Raidmarkierung Y",

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
    ["opt_np_friendly_name_only"]       = "Verbündete: nur Name (ohne Lebensbalken)",
    ["opt_np_friendly_role_icons"]      = "Rollensymbole anzeigen (Dungeon/Delve)",
    ["opt_np_role_show_tank"]           = "Tank-Symbol anzeigen",
    ["opt_np_role_show_healer"]         = "Heiler-Symbol anzeigen",
    ["opt_np_role_show_dps"]            = "DPS-Symbol anzeigen",
    ["opt_np_role_icon_size"]           = "Rollensymbol-Größe",

    -- Raid Marker
    ["section_raid_marker"]             = "Raid-Markierung",
    ["opt_np_raid_icon_anchor"]         = "Symbol-Position",
    ["opt_np_raid_icon_x"]              = "Versatz X",
    ["opt_np_raid_icon_y"]              = "Versatz Y",
    ["opt_np_raid_icon_size"]           = "Symbolgröße",

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
    ["info_cdm_editmode"]               = "Die Platzierung erfolgt über den Blizzard Edit Mode (Esc |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Edit Mode).",

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
    ["opt_rb_classpower_height"]        = "Klassenkrafthöhe",
    ["opt_rb_druidmana_height"]         = "Druiden-Manahöhe",
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
    ["info_rb_druid"]                   = "Leisten passen sich automatisch an Klasse und Spezialisierung an.\nDruide: Ressource ändert sich mit Form (Bär |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Wut, Katze |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Energie, Eule |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Astrale Macht).",

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
    ["import_preview_valid"]            = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t Gültiger String",
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
    ["msg_report_issue"]                = "Falls ein Problem auftritt, hinterlasst bitte einen Kommentar auf CurseForge.",
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
    ["section_sound_general"]           = "Bloodlust-Sound",
        ["info_sound_desc"]                 = "Spielt einen benutzerdefinierten Sound ab, wenn ein Bloodlust-Effekt erkannt wird. Die Erkennung prueft direkt die Lust-Buffs und Sated/Exhaustion-Debuffs.",
    ["opt_sound_enable"]                = "Bloodlust-Erkennung aktivieren",
    ["sublabel_sound_choice"]           = "Sound & Kanal",
    ["opt_sound_file"]                  = "Abzuspielender Sound",
    ["opt_sound_channel"]               = "Audiokanal",
    ["btn_sound_preview"]               = ">> Sound anhören",
    ["btn_sound_stop"]                  = "■  Stoppen",
    ["opt_sound_force"]                 = "Sound erzwingen, auch wenn das Spiel stummgeschaltet ist",
    ["opt_sound_chat"]                  = "Chatnachrichten anzeigen",
    ["opt_sound_debug"]                 = "Mode debug",

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
    ["mover_mythictracker"]             = "M+ Tracker",
    ["mover_chatframe"]                 = "Chat-Fenster",

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
    ["opt_chat_skin_style"]              = "Skin-Stil",
    ["opt_chat_skin_style_tui"]          = "TUI (Seitenleiste + Fenster)",
    ["opt_chat_skin_style_classic"]      = "Klassisch (Gerahmt)",
    ["opt_chat_skin_style_glass"]        = "Glas (Mattiert)",
    ["opt_chat_skin_style_minimal"]      = "Minimal (Randlos)",
    ["opt_chat_skin_bg_alpha"]           = "Hintergrund-Deckkraft",
    ["opt_chat_skin_font_size"]          = "Chat-Schriftgröße",
    ["opt_chat_skin_fade"]               = "Fade chat when inactive",
    ["opt_chat_skin_short_channels"]     = "Short channel names (G, P, R…)",
    ["opt_chat_skin_timestamp"]          = "Show timestamps",
    ["opt_chat_skin_url"]                = "Clickable URLs",
    ["opt_chat_skin_emoji"]              = "Replace text emoticons with emoji",
    ["opt_chat_skin_class_colors"]       = "Class-color player names in chat",
    ["opt_chat_skin_history"]            = "Restore chat history on login",
    ["opt_chat_skin_copy_lines"]         = "Show copy icon per message",

    -- Buff Skin
    ["sublabel_buff_skin"]               = "— Buff-/Debuff-Skin —",
    ["opt_buff_skin_enable"]             = "Buff-/Debuff-Symbole skinnen",
    ["opt_buff_skin_buffs"]              = "Auf Buffs anwenden",
    ["opt_buff_skin_debuffs"]            = "Auf Debuffs anwenden",
    ["opt_buff_skin_color_by_type"]       = "Rahmenfarbe nach Debuff-Typ (Magie/Gift/Fluch…)",
    ["opt_buff_skin_teal_border"]         = "Blaugrüner Rahmen für Buffs",
    ["opt_buff_skin_desaturate"]          = "Debuff-Icons entsättigen",
    ["opt_buff_skin_hide_buffs"]         = "Buff-Rahmen ausblenden",
    ["opt_buff_skin_hide_debuffs"]       = "Debuff-Rahmen ausblenden",
    ["opt_buff_skin_font_size"]          = "Timer-Schriftgröße",

    -- Game Menu Skin
    ["sublabel_game_menu_skin"]          = "— Spielmenü (Escape) —",
    ["opt_game_menu_skin_enable"]        = "Spielmenü skinnen",
    ["info_game_menu_skin_reload"]       = "Ein /reload ist nötig, um den Skin rückgängig zu machen.",
    ["msg_chat_skin_enabled"]            = "Chat-Skin aktiviert",
    ["msg_chat_skin_disabled"]           = "Chat-Skin deaktiviert (Reload zum Zurücksetzen)",
    ["sublabel_mail_skin"]               = "— Postfenster —",
    ["opt_mail_skin_enable"]             = "Postfenster-Skin",
    ["msg_mail_skin_enabled"]            = "Post-Skin aktiviert",
    ["msg_mail_skin_disabled"]           = "Post-Skin deaktiviert (Reload zum Zurücksetzen)",

    -- =====================
    -- WORLD QUEST TAB
    -- =====================
    ["tab_qol_world_quests"]             = "Weltquests",
    ["section_wq_tab"]                   = "Weltquest-Tab",
    ["info_wq_tab_desc"]                 = "Zeigt eine Liste verfügbarer Weltquests neben der Weltkarte mit Details zu Belohnungen, Zone, Fraktion und verbleibender Zeit. Klicke auf eine Quest, um zur Zone zu navigieren. Shift-Klick zum Super-Tracking.",
    ["opt_wq_enable"]                    = "Weltquest-Tab aktivieren",
    ["opt_wq_auto_show"]                 = "Automatisch beim Öffnen der Karte anzeigen",
    ["opt_wq_max_quests"]                = "Max. angezeigte Quests (0 = unbegrenzt)",
    ["opt_wq_min_time"]                  = "Min. verbleibende Zeit (Minuten, 0 = alle)",
    ["section_wq_filters"]               = "Belohnungsfilter",
    ["opt_wq_filter_gold"]               = "Goldbelohnungen anzeigen",
    ["opt_wq_filter_gear"]               = "Ausrüstungsbelohnungen anzeigen",
    ["opt_wq_filter_rep"]                = "Rufbelohnungen anzeigen",
    ["opt_wq_filter_currency"]           = "Währungsbelohnungen anzeigen",
    ["opt_wq_filter_anima"]              = "Animabelohnungen anzeigen",
    ["opt_wq_filter_pet"]                = "Haustierbelohnungen anzeigen",
    ["opt_wq_filter_other"]              = "Sonstige Belohnungen anzeigen",
    ["wq_tab_title"]                     = "WQ Liste",
    ["wq_panel_title"]                   = "Weltquests",
    ["wq_col_name"]                      = "Name",
    ["wq_col_zone"]                      = "Zone",
    ["wq_col_reward"]                    = "Belohnung",
    ["wq_col_time"]                      = "Zeit",
    ["wq_zone"]                          = "Zone",
    ["wq_faction"]                       = "Fraktion",
    ["wq_reward"]                        = "Belohnung",
    ["wq_time_left"]                     = "Verbleibende Zeit",
    ["wq_elite"]                         = "Elite-Weltquest",
    ["wq_sort_time"]                     = "Zeit",
    ["wq_sort_zone"]                     = "Zone",
    ["wq_sort_name"]                     = "Name",
    ["wq_sort_reward"]                   = "Belohnung",
    ["wq_sort_faction"]                  = "Fraktion",
    ["wq_status_count"]                  = "Zeige %d / %d Quests",

    -- Profession Helper
    ["tab_qol_prof_helper"]              = "Berufe",
    ["section_prof_helper"]              = "Berufshelfer",
    ["info_prof_helper_desc"]            = "Entzaubern, Mahlen und Sondieren von Gegenständen im Stapel mit einer visuellen Oberfläche.",
    ["opt_prof_helper_enable"]           = "Berufshelfer aktivieren",
    ["sublabel_prof_de_filters"]         = "— Entzauber-Qualitätsfilter —",
    ["opt_prof_filter_green"]            = "Ungewöhnliche (Grüne) einschließen",
    ["opt_prof_filter_blue"]             = "Seltene (Blaue) einschließen",
    ["opt_prof_filter_epic"]             = "Epische (Lila) einschließen",
    ["btn_prof_open_helper"]             = "Berufshelfer öffnen",
    ["ph_title"]                         = "Berufshelfer",
    ["ph_tab_disenchant"]                = "Entzaubern",
    ["ph_filter_quality"]                = "Qualität:",
    ["ph_quality_green"]                 = "Grün",
    ["ph_quality_blue"]                  = "Blau",
    ["ph_quality_epic"]                  = "Episch",
    ["ph_select_all"]                    = "Alle auswählen",
    ["ph_deselect_all"]                  = "Alle abwählen",
    ["ph_btn_process"]                   = "Verarbeiten",
    ["ph_btn_click_process"]             = "Klicken zum Verarbeiten",
    ["ph_btn_stop"]                      = "Stopp",
    ["ph_status_idle"]                   = "Klicke auf Verarbeiten",
    ["ph_status_processing"]             = "Verarbeite %d/%d: %s",
    ["ph_status_done"]                   = "Fertig! Alle Gegenstände verarbeitet.",
    ["ph_item_count"]                    = "%d Gegenstände verfügbar",
    ["ph_ilvl"]                          = "iLvl %d",

    -- ── Class Reminder ──────────────────────────────────────────
    ["tab_qol_class_reminder"]           = "Klassenerinnerung",
    ["section_class_reminder"]           = "Klassen-Buff / Form-Erinnerung",
    ["info_class_reminder"]              = "Zeigt eine pulsierende Textwarnung in der Bildschirmmitte an, wenn ein Klassen-Buff, eine Form, eine Haltung oder eine Aura fehlt.",
    ["opt_class_reminder_enable"]        = "Klassenerinnerung aktivieren",
    ["opt_class_reminder_scale"]         = "Textgröße",
    ["opt_class_reminder_color"]         = "Textfarbe",
    ["sublabel_class_reminder_pos"]      = "— Positionsversatz —",
    ["opt_class_reminder_x"]             = "Versatz X",
    ["opt_class_reminder_y"]             = "Versatz Y",

    -- Buff / Form names
    ["cr_fortitude"]                     = "Machtwort: Seelenstärke",
    ["cr_shadowform"]                    = "Schattengestalt",
    ["cr_arcane_intellect"]              = "Arkane Intelligenz",
    ["cr_skyfury"]                       = "Himmelszorn",
    ["cr_mark_of_the_wild"]              = "Mal der Wildnis",
    ["cr_cat_form"]                      = "Katzengestalt",
    ["cr_bear_form"]                     = "Bärengestalt",
    ["cr_moonkin_form"]                  = "Mondkingestalt",
    ["cr_battle_shout"]                  = "Schlachtruf",
    ["cr_stance"]                        = "Haltung",
    ["cr_aura"]                          = "Aura",
    ["cr_blessing_bronze"]               = "Segen der Bronze",

    -- =====================
    -- MYTHIC TRACKER (TomoMythic integration)
    -- =====================
    ["tmt_cmd_usage"]               = "|cFF55B400/tmt|r : Einstellungen  |  |cFF55B400unlock|r : verschieben  |  |cFF55B400lock|r : sperren  |  |cFF55B400preview|r : Vorschau  |  |cFF55B400key|r : Gruppenschlüssel  |  |cFF55B400kr|r : Roulette",
    ["tmt_unlock_msg"]              = "|cff0cd29fTomoMod|r M+ Tracker: Rahmen entsperrt \226\128\148 ziehen zum Verschieben.",
    ["tmt_lock_msg"]                = "|cff0cd29fTomoMod|r M+ Tracker: Rahmen gesperrt.",
    ["tmt_reset_msg"]               = "|cff0cd29fTomoMod|r M+ Tracker: Position zurückgesetzt.",
    ["tmt_unknown_cmd"]             = "|cff0cd29fTomoMod|r M+ Tracker: Unbekannter Befehl.",
    ["tmt_key_level"]               = "+%d",
    ["tmt_dungeon_unknown"]         = "Mythisch+",
    ["tmt_overtime"]                = "ÜBERZOGEN",
    ["tmt_completed_on_time"]       = "ABGESCHLOSSEN",
    ["tmt_completed_depleted"]      = "GESCHEITERT",
    ["tmt_forces"]                  = "KRÄFTE",
    ["tmt_forces_done"]             = "KOMPLETT",
    ["tmt_forces_pct"]              = "%.1f%%",
    ["tmt_forces_count"]            = "%d / %d",
    ["tmt_cfg_title"]               = "Mythic",
    ["tmt_cfg_panel_enable"]         = "M+ Tracker aktivieren",
    ["tmt_cfg_show_timer"]          = "Timerleiste anzeigen",
    ["tmt_cfg_show_forces"]         = "Feindkräfte anzeigen",
    ["tmt_cfg_show_bosses"]         = "Boss-Timer anzeigen",
    ["tmt_cfg_hide_blizzard"]       = "Blizzard-Tracker ausblenden",
    ["tmt_cfg_lock"]                = "Rahmen sperren",
    ["tmt_cfg_scale"]               = "Skalierung",
    ["tmt_cfg_alpha"]               = "Hintergrundtransparenz",
    ["tmt_cfg_reset_pos"]           = "Position zurücksetzen",
    ["tmt_cfg_preview"]             = "Vorschau",
    ["tmt_cfg_section_display"]     = "Anzeige",
    ["tmt_cfg_section_frame"]       = "Rahmen",
    ["tmt_cfg_section_actions"]     = "Aktionen",
    ["tmt_key_not_available"]       = "nicht verfügbar.",
    ["tmt_key_not_in_group"]        = "Du bist in keiner Gruppe.",
    ["tmt_key_none_found"]          = "Keine Schlüsselsteine gefunden.",
    ["tmt_kr_spin"]                 = "|TInterface\\Icons\\INV_Misc_Dice_02:14|t  Drehen!",
    ["tmt_preview_active"]          = "|cff0cd29fTomoMod|r M+ Tracker: Vorschau aktiv \226\128\148 |cFF55B400/tmt lock|r zum Sperren.",

    -- MythicHub
    ["mhub_title"]                  = "Mythisch+ Wertung",
    ["mhub_col_dungeon"]            = "Dungeon",
    ["mhub_col_level"]              = "Stufe",
    ["mhub_col_rating"]             = "Wertung",
    ["mhub_col_best"]               = "Beste",
    ["mhub_tp_click"]               = "Klicke zum Teleportieren",
    ["mhub_tp_not_available"]        = "Teleport nicht gelernt",
    ["mhub_tp_not_learned"]          = "|cff0cd29fTomoMod|r: Teleportzauber nicht gelernt.",
    ["mhub_vault_title"]            = "Die Gro\195\159e Schatzkammer",
    ["mhub_vault_dungeons"]         = "Dungeons",
    ["mhub_vault_raids"]            = "Schlachtz\195\188ge",
    ["mhub_vault_world"]            = "Tiefen",
    ["mhub_vault_ilvl"]             = "Gegenstandsstufe",
    ["mhub_vault_locked"]           = "Gesperrt",
    ["mhub_vault_claim"]            = "Kehre zur Gro\195\159en Schatzkammer zur\195\188ck, um deine Belohnung abzuholen",

    -- ══════════════════════════════════════════════════════════
    -- INSTALLER
    -- ══════════════════════════════════════════════════════════

    -- Navigation
    ["ins_header_title"]             = "|cff0cd29fTomo|r|cffe4e4e4Mod|r  \226\128\148  Einrichtungsassistent",
    ["ins_step_counter"]             = "Schritt %d / %d",
    ["ins_btn_prev"]                 = "|TInterface\\BUTTONS\\UI-SpellbookIcon-PrevPage:0|t Zur\195\188ck",
    ["ins_btn_next"]                 = "Weiter |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t",
    ["ins_btn_finish"]               = "Fertig |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t",
    ["ins_btn_skip"]                 = "Installation \195\188berspringen",

    -- Step 1: Welcome
    ["ins_step1_title"]              = "Willkommen bei TomoMod",
    ["ins_subtitle"]                 = "Interface- & QOL-Suite f\195\188r The War Within",
    ["ins_welcome_desc"]             = "Dieser Assistent f\195\188hrt Sie in |cff0cd29f12 Schritten|r durch die Konfiguration von TomoMod:\nProfil, Skins, Nameplates, Aktionsleisten, Sound, Mythic+,\nOptimierungen, QOL und SkyRide.\n\nAlle Optionen k\195\182nnen jederzeit \195\188ber |cff0cd29f/tm|r ge\195\164ndert werden.",

    -- Step 2: Profile
    ["ins_step2_title"]              = "Spielprofil",
    ["ins_profile_info"]             = "Erstelle ein benanntes Profil, um deine Konfiguration zu speichern.",
    ["ins_profile_section"]          = "Profilname",
    ["ins_profile_placeholder"]      = "Mein Profil",
    ["ins_profile_create"]           = "Profil erstellen",
    ["ins_profile_created"]          = "Profil erstellt: ",
    ["ins_spec_section"]             = "Spezialisierungszuweisung",
    ["ins_spec_info"]                = "Du kannst dieses Profil deinen Spezialisierungen im Profil-Panel (/tm) zuweisen.\nJede Spezialisierung kann eine andere Konfiguration verwenden.",

    -- Step 3: Visual Skins
    ["ins_step3_title"]              = "Visuelle Skins",
    ["ins_skins_info"]               = "Passe das Blizzard-UI mit dem dunklen Design von TomoMod an.",
    ["ins_skins_section"]            = "Verf\195\188gbare Skins",
    ["ins_skin_gamemenu"]            = "Spielmen\195\188-Skin (Escape-Men\195\188)",
    ["ins_skin_actionbar"]           = "Aktionsleisten-Button-Skin",
    ["ins_skin_buffs"]               = "Buff-/Debuff-Skin",
    ["ins_skin_chat"]                = "Chat-Fenster-Skin",
    ["ins_skin_character"]           = "Charakterbogen-Skin",
    ["ins_skin_style_section"]       = "Aktionsleisten-Button-Stil",
    ["ins_skin_style"]               = "Visueller Stil",

    -- Step 4: Tank Mode
    ["ins_step4_title"]              = "Tank-Modus",
    ["ins_tank_info"]                = "Im Tank-Modus zeigen Nameplates und UnitFrames\nden Bedrohungsstatus farblich f\195\188r jeden Gegner an.",
    ["ins_tank_np_section"]          = "Nameplates \226\128\148 Bedrohungsfarben",
    ["ins_tank_enable_np"]           = "Tank-Modus aktivieren (Nameplates)",
    ["ins_tank_colors_info"]         = "Gr\195\188n = Aggro gehalten  \194\183  Orange = kurz vor Verlust  \194\183  Rot = Aggro verloren",
    ["ins_tank_uf_section"]          = "UnitFrames \226\128\148 Bedrohungsanzeige",
    ["ins_tank_threat_indicator"]    = "Bedrohungsanzeige beim Ziel anzeigen",
    ["ins_tank_threat_text"]         = "Bedrohungs-% beim Ziel anzeigen",
    ["ins_tank_cotank_section"]      = "CoTank-Tracker",
    ["ins_tank_cotank_enable"]       = "Co-Tank-Verfolgung aktivieren",
    ["ins_tank_cotank_info"]         = "Zeigt die Bedrohung des zweiten Tanks in Instanzen an.",

    -- Step 5: Nameplates
    ["ins_step5_title"]              = "Nameplates",
    ["ins_np_general"]               = "Allgemein",
    ["ins_np_enable"]                = "TomoMod-Nameplates aktivieren",
    ["ins_np_reload_info"]           = "Ein Reload ist erforderlich, um Nameplates zu aktivieren/deaktivieren.",
    ["ins_np_display"]               = "Anzeige",
    ["ins_np_class_colors"]          = "Klassenfarben",
    ["ins_np_castbar"]               = "Zauberbalken anzeigen",
    ["ins_np_health_text"]           = "Gesundheitstext anzeigen (Prozent)",
    ["ins_np_auras"]                 = "Auren anzeigen (Debuffs)",
    ["ins_np_role_icons"]            = "Rollensymbole anzeigen (Dungeon)",
    ["ins_np_dimensions"]            = "Abmessungen",
    ["ins_np_width"]                 = "Breite",

    -- Step 6: Action Bars
    ["ins_step6_title"]              = "Aktionsleisten",
    ["ins_ab_skin_section"]          = "Button-Skin",
    ["ins_ab_enable"]                = "Skin auf Aktionsleisten-Buttons aktivieren",
    ["ins_ab_class_color"]           = "Randfarbe = Klassenfarbe",
    ["ins_ab_shift_reveal"]          = "Shift halten, um versteckte Leisten anzuzeigen",
    ["ins_ab_opacity_section"]       = "Globale Leistendeckkraft",
    ["ins_ab_opacity"]               = "Deckkraft",
    ["ins_ab_manage_section"]        = "Leistenverwaltung",
    ["ins_ab_manage_info"]           = "Verwende das Aktionsleisten-Panel (/tm |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Aktionsleisten |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Verwaltung),\num jede Leiste einzeln zu entsperren und zu verschieben.",

    -- Step 7: LustSound
    ["ins_step7_title"]              = "Sound \226\128\148 Heldentum / Kampfrausch",
    ["ins_sound_info"]               = "Spielt einen benutzerdefinierten Sound ab, wenn Heldentum oder\nKampfrausch von einem Gruppenmitglied gewirkt wird.",
    ["ins_sound_activation"]         = "Aktivierung",
    ["ins_sound_enable"]             = "Lust-Sound aktivieren",
    ["ins_sound_choice"]             = "Soundauswahl",
    ["ins_sound_sound"]              = "Sound",
    ["ins_sound_channel"]            = "Audiokanal",
    ["ins_sound_default"]            = "Standard",
    ["ins_sound_preview_section"]    = "Vorschau",
    ["ins_sound_preview_btn"]        = "|TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Vorschau",

    -- Step 8: Mythic+
    ["ins_step8_title"]              = "Mythic+ \226\128\148 Tracker & Rangliste",
    ["ins_mplus_tracker_section"]    = "M+ Tracker",
    ["ins_mplus_tracker_info"]       = "Zeigt Timer, Kr\195\164fte, Bosse und Fortschritt\ndeines Mythic+-Dungeons in Echtzeit an.",
    ["ins_mplus_tracker_enable"]     = "M+ Tracker aktivieren",
    ["ins_mplus_show_timer"]         = "Timer anzeigen",
    ["ins_mplus_show_forces"]        = "Kr\195\164fte anzeigen (%)",
    ["ins_mplus_hide_blizzard"]      = "Blizzard-UI in Mythic+ ausblenden",
    ["ins_mplus_score_section"]      = "TomoScore \226\128\148 Rangliste",
    ["ins_mplus_score_info"]         = "Zeigt pers\195\182nliche und Gruppenscores am Ende eines Mythic+ an.",
    ["ins_mplus_score_enable"]       = "TomoScore aktivieren",
    ["ins_mplus_score_auto"]         = "Automatisch in M+ anzeigen",

    -- Step 9: CVars
    ["ins_step9_title"]              = "Systemoptimierungen (CVars)",
    ["ins_cvar_info"]                = "TomoMod kann empfohlene WoW-CVars anwenden,\num Leistung und Reaktionsf\195\164higkeit zu verbessern.",
    ["ins_cvar_section"]             = "Enthaltene Optimierungen",
    ["ins_cvar_opt1"]                = "Unn\195\182tiges Level of Detail (LOD) reduzieren",
    ["ins_cvar_opt2"]                = "Frustum Culling optimieren",
    ["ins_cvar_opt3"]                = "\195\156berm\195\164\195\159iges Temporal AA deaktivieren",
    ["ins_cvar_opt4"]                = "Netzwerkreaktivit\195\164t verbessern",
    ["ins_cvar_opt5"]                = "Unn\195\182tige UI-Animationen deaktivieren",
    ["ins_cvar_opt6"]                = "Textur-Streaming optimieren",
    ["ins_cvar_success"]             = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t  CVars erfolgreich angewendet!",
    ["ins_cvar_apply_btn"]           = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0|t Alle CVars anwenden",
    ["ins_cvar_applied"]             = "Optimierte CVars angewendet.",

    -- Step 10: QOL
    ["ins_step10_title"]             = "Lebensqualit\195\164t (QOL)",
    ["ins_qol_info"]                 = "Aktiviere die QOL-Module, die du m\195\182chtest.\nAlle sind separat unter /tm |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t QOL erreichbar.",
    ["ins_qol_auto_section"]         = "Automatisierungen",
    ["ins_qol_auto_repair"]          = "Automatisch beim H\195\164ndler reparieren",
    ["ins_qol_fast_loot"]            = "Schnelles Looten (schnelle Gegenstandsaufnahme)",
    ["ins_qol_skip_cinematics"]      = "Bereits gesehene Zwischensequenzen \195\188berspringen",
    ["ins_qol_hide_talking_head"]    = "Talking Head ausblenden (Scrolldialoge)",
    ["ins_qol_auto_accept"]          = "Gruppeneinladungen automatisch annehmen (Freunde & Gilde)",
    ["ins_qol_tooltip_ids"]          = "IDs in Tooltips anzeigen (Spell-ID, Item-ID...)",
    ["ins_qol_combat_section"]       = "Kampf",
    ["ins_qol_combat_text"]          = "Benutzerdefinierter schwebender Kampftext",
    ["ins_qol_hide_castbar"]         = "Blizzard-Zauberbalken ausblenden (TomoMod verwenden)",

    -- Step 11: SkyRide
    ["ins_step11_title"]             = "SkyRide \226\128\148 Drachenreit-Leiste",
    ["ins_skyride_info"]             = "SkyRide zeigt eine Vigor-Leiste (6 Ladungen) und eine\nZweiter-Wind-Leiste (3 Ladungen) f\195\188r das Drachenreiten an.",
    ["ins_skyride_activation"]       = "Aktivierung",
    ["ins_skyride_enable"]           = "SkyRide-Leiste aktivieren",
    ["ins_skyride_auto_info"]        = "Die Leiste erscheint automatisch im Drachenreit-Modus\nund verschwindet au\195\159erhalb davon.",
    ["ins_skyride_dimensions"]       = "Abmessungen",
    ["ins_skyride_width"]            = "Breite",
    ["ins_skyride_height"]           = "H\195\182he",
    ["ins_skyride_reset_section"]    = "Position zur\195\188cksetzen",
    ["ins_skyride_reset_btn"]        = "Position zur\195\188cksetzen",

    -- Step 12: Done
    ["ins_step12_title"]             = "Einrichtung abgeschlossen!",
    ["ins_done_check"]               = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t  Alles bereit!",
    ["ins_done_recap"]               = "Deine TomoMod-Konfiguration ist gespeichert. Hier einige Hinweise:\n\n|cff0cd29f/tm|r              |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Konfigurationspanel \195\182ffnen\n|cff0cd29f/tm sr|r           |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Elemente entsperren und verschieben\n|cff0cd29f/tm install|r      |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Diesen Installer neu starten\n\nAlle hier konfigurierten Optionen k\195\182nnen jederzeit\n\195\188ber die entsprechenden Panels in der TomoMod-GUI ge\195\164ndert werden.\n\nEin |cff0cd29fUI-Reload|r ist erforderlich, um bestimmte \195\132nderungen anzuwenden\n(Nameplates, Skins, UnitFrames).",
    ["ins_done_reload"]              = "|TInterface\\BUTTONS\\UI-RefreshButton:0|t  UI neu laden",

    -- =========== Config Panels — i18n ===========
    -- ActionBars panel
    ["opt_abs_style"]                = "Visueller Stil",
    ["section_bar_opacity"]          = "Deckkraft pro Leiste",
    ["opt_abs_bar_select"]           = "Leiste konfigurieren",
    ["opt_abs_opacity"]              = "Deckkraft",
    ["btn_abs_apply_all"]            = "Auf alle Leisten anwenden",
    ["opt_abs_combat_only_label"]    = "Nur im Kampf anzeigen:",
    ["opt_abs_combat_only"]          = "Leiste nur im Kampf sichtbar",
    ["section_bar_management"]       = "Aktionsleisten-Verwaltung",
    ["btn_abs_unlock"]               = "Leisten entsperren",
    ["info_abs_unlock"]              = "Entsperre die Leisten, um die Ziehgriffe anzuzeigen.\nRechtsklick auf einen Griff, um eine Leiste individuell zu konfigurieren.",
    ["section_bar_quick"]            = "Schnelleinstellungen",
    ["tab_abs_skin"]                 = "Button-Skin",
    ["tab_abs_bars"]                 = "Leisten-Verwaltung",
    -- General panel
    ["btn_relaunch_installer"]       = "Installer neu starten",
    ["info_relaunch_installer"]      = "Startet den 12-Schritte-Einrichtungsassistenten.",
    -- Sound panel
    ["section_sound_preview"]        = "Vorschau & Optionen",
    -- UFPreview
    ["preview_header"]               = "LIVE-VORSCHAU",
    ["preview_player"]               = "Spieler",
    ["preview_target_name"]          = "Taurache",
    ["preview_focus_name"]           = "Priestella",
    ["preview_pet_name"]             = "Wasserwolf",
    ["preview_tot_name"]             = "Ziel-des-Ziels",
    ["preview_cast_player"]          = "Frostblitz",
    ["preview_cast_target"]          = "Feuerball",
    ["preview_lbl_player"]           = "SPIELER",
    ["preview_lbl_target"]           = "ZIEL",
    ["preview_lbl_focus"]            = "FOKUS",
    ["preview_lbl_pet"]              = "PET",
    ["preview_lbl_tot"]              = "TOT",
    ["preview_click_nav"]            = "Klicken zum Navigieren",
    -- ConfigUI footer
    ["ui_footer_hint"]               = "/tm  \194\183  /tm sr zum Verschieben der Elemente",

    -- =====================
    -- SKINS CATEGORY (top-level)
    -- =====================
    ["cat_skins"]                        = "Skins",

    -- Chat Frame V2 — Reiter-Bezeichnungen & UI
    ["chatv2_tab_general"]               = "Allgemein",
    ["chatv2_tab_instance"]              = "Instanz",
    ["chatv2_tab_chucho"]                = "Chucho",
    ["chatv2_tab_personnel"]             = "Pers\195\182nlich",
    ["chatv2_tab_combat"]                = "Kampf",
    ["chatv2_sidebar_title"]             = "CHAT",
    ["chatv2_expand_btn"]                = "Chat",
    ["chatv2_mover_label"]               = "Chatfenster V2",
    ["chatv2_input_hint"]                = "Enter zum Tippen...",

    -- Skins > Chat Frame tab
    ["tab_skin_chatframe"]               = "Chatfenster",
    ["section_skin_chatframe"]           = "Chatfenster-Skin",
    ["info_skin_chatframe_desc"]         = "Chat-Panel mit Seitenleiste \226\128\148 Allgemein, Instanz, Chucho, Pers\195\182nlich, Kampf \226\128\148 mit Abzeichen f\195\188r ungelesene Nachrichten.",
    ["opt_skin_chatframe_enable"]        = "Chatfenster-Skin aktivieren",
    ["opt_skin_chatframe_width"]         = "Breite",
    ["opt_skin_chatframe_height"]        = "H\195\182he",
    ["opt_skin_chatframe_scale"]         = "Skalierung %",
    ["opt_skin_chatframe_opacity"]       = "Hintergrund-Transparenz",
    ["opt_skin_chatframe_font_size"]     = "Schriftgr\195\182\195\159e",
    ["opt_skin_chatframe_timestamp"]     = "Zeitstempel anzeigen",

    -- Skins > Bags tab
    -- Taschen — Entzauberung
    ["bagskin_de_badge"]                 = "DE",
    ["bagskin_de_tooltip"]               = "|cff0cd29f[Rechtsklick]|r Entzaubern",
    ["bagskin_currencies_none"]          = "Keine verfolgten W\195\164hrungen (Rechtsklick auf W\195\164hrung \226\134\146 In Rucksack anzeigen)",
    ["tab_skin_bags"]                    = "Taschen",
    ["section_skin_bags"]                = "Taschen-Skin",
    ["info_skin_bags_desc"]              = "Kategoriebasiertes Taschenraster inspiriert von BetterBags. Gegenst\195\164nde in einklappbare Abschnitte mit Qualit\195\164tsrahmen, Suche, Abklingzeiten und Gegenstandslevel-Abzeichen.",
    ["opt_skin_bags_enable"]             = "Taschen-Skin aktivieren",
    ["opt_skin_bags_stack_merge"]        = "Identische Stapel zusammenf\195\188hren",
    ["opt_skin_bags_show_empty"]         = "Freie Pl\195\164tze anzeigen",
    ["opt_skin_bags_show_recent"]        = "Neue Gegenst\195\164nde anzeigen",
    ["opt_skin_bags_columns"]            = "Spalten",
    ["opt_skin_bags_slot_size"]          = "Platzgr\195\182\195\159e",
    ["opt_skin_bags_slot_spacing"]       = "Platzabstand",
    ["opt_skin_bags_scale"]              = "Skalierung %",
    ["opt_skin_bags_opacity"]            = "Hintergrund-Transparenz",
    ["opt_skin_bags_quality_borders"]    = "Qualit\195\164tsrahmen anzeigen",
    ["opt_skin_bags_cooldowns"]          = "Abklingzeiten anzeigen",
    ["opt_skin_bags_quantity"]           = "Mengenabzeichen anzeigen",
    ["opt_skin_bags_search"]             = "Suchleiste anzeigen",
    ["opt_skin_bags_sort_mode"]          = "Sortiermodus",
    ["opt_skin_bags_sort_quality"]       = "Qualit\195\164t",
    ["opt_skin_bags_sort_name"]          = "Name",
    ["opt_skin_bags_sort_type"]          = "Typ",
    ["opt_skin_bags_sort_ilvl"]          = "Gegenstandslevel",
    ["opt_skin_bags_sort_recent"]        = "Neueste",
    ["opt_skin_bags_show_gold"]          = "Gold anzeigen (Fu\195\159zeile)",
    ["opt_skin_bags_show_currencies"]    = "Verfolgte W\195\164hrungen anzeigen (Fu\195\159zeile)",
    ["bagskin_cat_recent"]               = "Neue Gegenst\195\164nde",
    ["bagskin_cat_equipment"]            = "Ausr\195\188stung",
    ["bagskin_cat_consumables"]          = "Verbrauchsgegenst\195\164nde",
    ["bagskin_cat_quest"]                = "Questgegenst\195\164nde",
    ["bagskin_cat_tradegoods"]           = "Handwerkswaren",
    ["bagskin_cat_reagents"]             = "Reagenzien",
    ["bagskin_cat_gems"]                 = "Edelsteine & Verzauberungen",
    ["bagskin_cat_recipes"]              = "Rezepte",
    ["bagskin_cat_pets"]                 = "Kampfhaustiere",
    ["bagskin_cat_junk"]                 = "Plunder",
    ["bagskin_cat_misc"]                 = "Verschiedenes",
    ["bagskin_cat_free"]                 = "Freie Pl\195\164tze",

    -- Skins > Objective Tracker tab
    ["tab_skin_objtracker"]              = "Zieltracker",

    -- Skins > Character tab
    ["tab_skin_character"]               = "Charakter",

    -- Skins > Buffs tab
    ["tab_skin_buffs"]                   = "Buffs",

    -- Skins > Game Menu tab
    ["tab_skin_gamemenu"]                = "Spielmen\195\188",

    -- Skins > Mail tab
    ["tab_skin_mail"]                    = "Post",

    -- =====================
    -- WEGPUNKT-MODUL (/tm way)
    -- =====================
    -- GUI
    ["tab_qol_waypoint"]                  = "Wegpunkt",
    ["section_waypoint"]                  = "Wegpunkt",
    ["opt_way_zone_only"]                 = "Nur in der aktuellen Zone anzeigen",
    ["opt_way_size"]                      = "Gr\195\182\195\159e des Leuchtfeuers",
    ["opt_way_shape"]                     = "Form",
    ["way_shape_ring"]                    = "Ring",
    ["way_shape_arrow"]                   = "Pfeil",
    ["opt_way_color"]                     = "Wegpunkt-Farbe",
    -- Slash
    ["msg_help_way"]                     = "Wegpunkt an aktueller Position setzen",
    ["msg_help_way_coords"]              = "Wegpunkt bei Koordinaten (x, y) setzen",
    ["msg_help_way_clear"]               = "Aktiven Wegpunkt entfernen",
    ["way_cleared"]                      = "Wegpunkt entfernt.",
    ["way_set"]                          = "Wegpunkt gesetzt auf %s%s.",
    ["way_here"]                         = "Wegpunkt an aktueller Position gesetzt.",
    ["way_no_map"]                       = "Aktuelle Karte konnte nicht ermittelt werden.",
    ["way_no_pos"]                       = "Spielerposition konnte nicht ermittelt werden.",
    ["way_bad_map"]                      = "Auf dieser Karte kann kein Wegpunkt gesetzt werden.",
    ["way_bad_coords"]                   = "Koordinaten m\195\188ssen zwischen 0 und 100 liegen.",
    ["way_usage"]                        = "Verwendung: /tm way [MapID] x y [Name]  |  /tm way clear",

    -- =====================
    -- Resource names
    -- =====================
    ["res_mana"]                        = "Mana (Druide)",
    ["res_soul_shards"]                 = "Seelensplitter",
    ["res_holy_power"]                  = "Heilige Kraft",
    ["res_chi"]                         = "Chi",
    ["res_combo_points"]                = "Kombopunkte",
    ["res_arcane_charges"]              = "Arkane Aufladungen",
    ["res_essence"]                     = "Essenz",
    ["res_stagger"]                     = "Staffelung",
    ["res_soul_fragments"]              = "Seelenfragmente",
    ["res_tip_of_spear"]                = "Spitze des Speers",
    ["res_maelstrom_weapon"]            = "Mahlstromwaffe",

    -- =====================
    -- Resource Bars display mode
    -- =====================
    ["opt_rb_display_mode"]             = "Anzeigemodus",
    ["display_mode_icons"]              = "Symbole (GW2-Texturen)",
    ["display_mode_bars"]               = "Leisten (flache Farben)",

    -- =====================
    -- Tooltip Skin
    -- =====================
    ["tab_skin_tooltip"]                 = "Tooltip",
    ["section_tooltip_skin"]             = "Tooltip-Skin",
    ["opt_tooltip_skin_enable"]          = "Tooltip-Skin aktivieren",
    ["info_tooltip_skin_reload"]         = "Einige Änderungen erfordern das Überfahren eines neuen Ziels.",
    ["opt_tooltip_bg_alpha"]             = "Hintergrund-Deckkraft",
    ["opt_tooltip_border_alpha"]         = "Rahmen-Deckkraft",
    ["opt_tooltip_font_size"]            = "Schriftgröße",
    ["opt_tooltip_hide_healthbar"]       = "Lebensleiste ausblenden",
    ["opt_tooltip_class_color"]          = "Klassenfarbige Spielernamen",
    ["opt_tooltip_hide_server"]          = "Server in Spielernamen ausblenden",
    ["opt_tooltip_hide_title"]           = "Titel in Spielernamen ausblenden",
    ["opt_tooltip_guild_color"]          = "Benutzerdefinierte Gildennamenfarbe",
    ["opt_tooltip_guild_color_pick"]     = "Gildennamenfarbe",

    -- =====================
    -- Bag Skin extras
    -- =====================
    ["opt_skin_bags_show_ilvl"]          = "Gegenstandsstufe auf Ausrüstung anzeigen",
    ["opt_skin_bags_show_junk_icon"]     = "Trödel-Münzsymbol anzeigen",
    ["opt_skin_bags_layout_mode"]        = "Layout-Modus",
    ["opt_skin_bags_layout_combined"]    = "Kombiniertes Raster",
    ["opt_skin_bags_layout_categories"]  = "Kategorien",
    ["opt_skin_bags_layout_separate"]    = "Separate Taschen",
    ["opt_skin_bags_reverse_order"]      = "Taschenreihenfolge umkehren",
    ["opt_skin_bags_show_bag_bar"]       = "Taschenleiste anzeigen",
    ["opt_skin_bags_settings"]           = "Tascheneinstellungen",
    ["opt_skin_bags_slot_spacing_x"]     = "Fach-Abstand X",
    ["opt_skin_bags_slot_spacing_y"]     = "Fach-Abstand Y",
    ["opt_skin_bags_sort_none"]          = "Manuell",

    -- =====================
    -- TOMOSCORE (Scoreboard)
    -- =====================
    ["ts_cfg_title"]                = "Anzeigetafel",
    ["ts_cfg_enable"]               = "Dungeon-Anzeigetafel aktivieren",
    ["ts_cfg_auto_show_mplus"]      = "Automatisch für Mythic+ anzeigen",
    ["ts_cfg_scale"]                = "Skalierung",
    ["ts_cfg_alpha"]                = "Hintergrund-Deckkraft",
    ["ts_cfg_section_display"]      = "Anzeige",
    ["ts_cfg_section_frame"]        = "Rahmen",
    ["ts_cfg_section_actions"]      = "Aktionen",
    ["ts_cfg_preview"]              = "Vorschau",
    ["ts_cfg_last_run"]             = "Letzten Lauf anzeigen",
    ["ts_cfg_reset_pos"]            = "Position zurücksetzen",
    ["ts_reset_msg"]                = "|cff0cd29fTomoMod|r Anzeigetafel: Position zurückgesetzt.",
    ["ts_no_data"]                  = "|cff0cd29fTomoMod|r Anzeigetafel: Keine Dungeon-Daten verfügbar.",
    ["ts_mythic_zero"]              = "Mythisch",
    ["ts_key_level"]                = "+%d",
    ["ts_completed"]                = "ABGESCHLOSSEN",
    ["ts_depleted"]                 = "ERSCHÖPFT",
    ["ts_duration"]                 = "Dauer",
    ["ts_col_player"]               = "Spieler",
    ["ts_col_rating"]               = "M+",
    ["ts_col_key_level"]            = "Schlüssel",
    ["ts_col_key_name"]             = "Dungeon",
    ["ts_col_damage"]               = "Schaden",
    ["ts_col_healing"]              = "Heilung",
    ["ts_col_interrupts"]           = "Unterbrechungen",
    ["ts_footer_total"]             = "Gesamt",
    ["ts_footer_players"]           = "%d Spieler",
})
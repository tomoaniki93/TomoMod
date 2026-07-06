-- =====================================
-- esES.lua — Español
-- =====================================

TomoMod_RegisterLocale("esES", {

    -- =====================
    -- CONFIG: Categories (ConfigUI.lua)
    -- =====================
    ["cat_general"]         = "General",
    ["cat_unitframes"]      = "UnitFrames",
    ["cat_nameplates"]      = "Nameplates",
    ["cat_cd_resource"]     = "CD y Recursos",
    ["cat_qol"]             = "Calidad de vida",
    ["cat_mythicplus"]      = "Mythic+",
    ["cat_profiles"]        = "Perfiles",
    ["cat_diagnostics"]     = "Diagnósticos",
    ["cat_housing"]         = "Housing",

    -- =====================
    -- CONFIG: General Panel
    -- =====================
    ["section_about"]                   = "Acerca de",
    ["about_text"]                      = "|cff2ed884TomoMod|r %s por TomoAniki\nInterfaz ligera con QOL, UnitFrames y Nameplates.\nEscribe /tm help para la lista de comandos.",
    ["section_general"]                 = "General",
    ["btn_reset_all"]                   = "Reiniciar todo",
    ["info_reset_all"]                  = "Esto reiniciará TODOS los ajustes y recargará la interfaz.",

    -- Minimap
    ["section_minimap"]                 = "Minimapa",
    ["opt_minimap_enable"]              = "Activar minimapa personalizado",
    ["opt_size"]                        = "Tamaño",
    ["opt_scale"]                       = "Escala",
    ["opt_border"]                      = "Borde",
    ["border_class"]                    = "Color de clase",
    ["border_black"]                    = "Negro",

    -- Info Panel
    ["section_info_panel"]              = "Panel de información",
    ["opt_enable"]                      = "Activar",
    ["opt_durability"]                  = "Durabilidad (Equipo)",
    ["info_durability_position"]        = "Posición del texto de durabilidad — útil si un botón (p. ej. expansión) se superpone a la esquina predeterminada.",
    ["opt_durability_corner"]           = "Esquina (durabilidad)",
    ["opt_time"]                        = "Hora",
    ["opt_24h_format"]                  = "Formato 24h",
    ["opt_show_coords"]                 = "Mostrar coordenadas",
    ["btn_reset_position"]              = "Reiniciar posición",

    -- Cursor Ring
    ["section_cursor_ring"]             = "Anillo del cursor",
    ["opt_class_color"]                 = "Color de clase",
    ["opt_anchor_tooltip_ring"]         = "Anclar tooltip al cursor",

    -- =====================
    -- CONFIG: UnitFrames Panel
    -- =====================
    -- Tabs
    ["tab_general"]                     = "General",
    ["tab_player"]                      = "Jugador",
    ["tab_target"]                      = "Objetivo",
    ["tab_tot"]                         = "OdO",
    ["tab_pet"]                         = "Mascota",
    ["tab_focus"]                       = "Foco",
    ["tab_colors"]                      = "Colores",

    -- Sub-tabs (Player, Target, Focus)
    ["subtab_dimensions"]               = "Dimensiones",
    ["subtab_display"]                  = "Visualización",
    ["subtab_auras"]                    = "Auras",
    ["subtab_positioning"]              = "Posición",

    -- Sub-labels
    ["sublabel_dimensions"]             = "— Dimensiones —",
    ["sublabel_display"]                = "— Visualización —",
    ["sublabel_castbar"]                = "— Barra de lanzamiento —",
    ["sublabel_auras"]                  = "— Auras —",
    ["sublabel_element_offsets"]        = "— Posiciones de elementos —",

    -- Unit display names
    ["unit_player"]                     = "Jugador",
    ["unit_target"]                     = "Objetivo",
    ["unit_tot"]                        = "Objetivo del objetivo",
    ["unit_pet"]                        = "Mascota",
    ["unit_focus"]                      = "Foco",

    -- General tab
    ["section_general_settings"]        = "Ajustes generales",
    ["opt_uf_enable"]                   = "Activar UnitFrames de TomoMod",
    ["opt_hide_blizzard"]               = "Ocultar marcos de Blizzard",
    ["opt_global_font_size"]            = "Tamaño de fuente global",
    ["sublabel_font"]                   = "— Fuente —",
    ["opt_font_family"]                 = "Familia de fuente",

    -- Castbar colors
    ["section_castbar_colors"]          = "Colores de la barra de lanzamiento",
    ["info_castbar_colors"]             = "Personaliza los colores de la barra de lanzamiento para hechizos interrumpibles, no interrumpibles e interrumpidos.",
    ["opt_castbar_color"]               = "Hechizo interrumpible",
    ["opt_castbar_ni_color"]            = "Hechizo no interrumpible",
    ["opt_castbar_interrupt_color"]     = "Hechizo interrumpido",
    ["info_castbar_colors_reload"]      = "Los cambios de color se aplican a nuevos lanzamientos. /reload para efecto completo.",
    ["btn_toggle_lock"]                 = "Bloquear/Desbloquear (/tm uf)",
    ["info_unlock_drag"]                = "Desbloquea para mover los marcos. Las posiciones se guardan automáticamente.",

    -- Per-unit options
    ["opt_width"]                       = "Ancho",
    ["opt_health_height"]               = "Altura de vida",
    ["opt_power_height"]                = "Altura de recurso",
    ["opt_show_name"]                   = "Mostrar nombre",
    ["opt_name_truncate"]               = "Truncar nombres largos",
    ["opt_name_truncate_length"]        = "Longitud máx. del nombre",
    ["opt_show_level"]                  = "Mostrar nivel",
    ["opt_show_health_text"]            = "Mostrar texto de vida",
    ["opt_health_format"]               = "Formato de vida",
    ["fmt_current"]                     = "Actual (25.3K)",
    ["fmt_percent"]                     = "Porcentaje (75%)",
    ["fmt_current_percent"]             = "Actual + % (25.3K | 75%)",
    ["fmt_current_max"]                 = "Actual / Máx",
    ["opt_class_color_uf"]              = "Color de clase",
    ["opt_faction_color"]               = "Color de facción (PNJ)",
    ["opt_use_nameplate_colors"]        = "Colores de Nameplate (tipo de PNJ)",
    ["opt_show_absorb"]                 = "Barra de absorción",
    ["opt_show_threat"]                 = "Indicador de amenaza (brillo de borde)",
    ["section_threat_text"]             = "Texto % de amenaza",
    ["opt_threat_text_enable"]          = "Mostrar % de amenaza en el objetivo",
    ["opt_threat_text_font_size"]       = "Tamaño de fuente",
    ["opt_threat_text_offset_x"]        = "Desplazamiento X",
    ["opt_threat_text_offset_y"]        = "Desplazamiento Y",
    ["info_threat_text"]                = "Verde = tanqueando (ventaja), amarillo = advertencia, rojo = aggro perdido",
    ["opt_show_leader_icon"]            = "Icono de líder",
    ["opt_leader_icon_x"]               = "Icono de líder X",
    ["opt_leader_icon_y"]               = "Icono de líder Y",
    ["opt_raid_icon_x"]                 = "Marcador de raid X",
    ["opt_raid_icon_y"]                 = "Marcador de raid Y",

    -- Castbar
    ["opt_castbar_enable"]              = "Activar barra de lanzamiento",
    ["opt_castbar_width"]               = "Ancho de barra de lanzamiento",
    ["opt_castbar_height"]              = "Altura de barra de lanzamiento",
    ["opt_castbar_show_icon"]           = "Mostrar icono",
    ["opt_castbar_show_timer"]          = "Mostrar temporizador",
    ["info_castbar_drag"]               = "Posición: /tm sr para desbloquear y mover la barra de lanzamiento.",
    ["btn_reset_castbar_position"]      = "Reiniciar posición de la barra de lanzamiento",
    ["opt_castbar_show_latency"]        = "Mostrar latencia",

    -- Auras
    ["opt_auras_enable"]                = "Activar auras",
    ["opt_auras_max"]                   = "Auras máximas",
    ["opt_auras_size"]                  = "Tamaño de icono",
    ["opt_auras_type"]                  = "Tipo de aura",
    ["aura_harmful"]                    = "Debuffs (perjudiciales)",
    ["aura_helpful"]                    = "Buffs (beneficiosos)",
    ["aura_all"]                        = "Todos",
    ["opt_auras_direction"]             = "Dirección de crecimiento",
    ["aura_dir_right"]                  = "Hacia la derecha",
    ["aura_dir_left"]                   = "Hacia la izquierda",
    ["opt_auras_only_mine"]             = "Solo mis auras",

    -- Element offsets
    ["elem_name"]                       = "Nombre",
    ["elem_level"]                      = "Nivel",
    ["elem_health_text"]                = "Texto de vida",
    ["elem_power"]                      = "Barra de recurso",
    ["elem_castbar"]                    = "Barra de lanzamiento",
    ["elem_auras"]                      = "Auras",

    -- =====================
    -- CONFIG: Nameplates Panel
    -- =====================
    -- Nameplate tabs
    ["tab_np_auras"]                    = "Auras",
    ["tab_np_advanced"]                 = "Avanzado",
    ["info_np_colors_custom"]           = "Cada color se puede personalizar haciendo clic en la muestra de color.",

    ["section_np_general"]              = "Ajustes generales",
    ["opt_np_enable"]                   = "Activar Nameplates de TomoMod",
    ["info_np_description"]             = "Reemplaza las nameplates de Blizzard con un estilo minimalista personalizable.",
    ["section_dimensions"]              = "Dimensiones",
    ["opt_np_name_font_size"]           = "Tamaño de fuente del nombre",

    -- Display
    ["section_display"]                 = "Visualización",
    ["opt_np_show_classification"]      = "Mostrar clasificación (élite, raro, jefe)",
    ["opt_np_show_absorb"]               = "Mostrar barra de absorción",
    ["opt_np_class_colors"]             = "Colores de clase (jugadores)",
    ["opt_np_friendly_name_only"]       = "Aliados: solo nombre (sin barra de vida)",
    ["opt_np_friendly_role_icons"]      = "Mostrar iconos de rol (mazmorra/delve)",
    ["opt_np_role_show_tank"]           = "Mostrar icono de Tanque",
    ["opt_np_role_show_healer"]         = "Mostrar icono de Sanador",
    ["opt_np_role_show_dps"]            = "Mostrar icono de DPS",
    ["opt_np_role_icon_size"]           = "Tamaño del icono de rol",

    -- Raid Marker
    ["section_raid_marker"]             = "Marcador de banda",
    ["opt_np_raid_icon_anchor"]         = "Posición del icono",
    ["opt_np_raid_icon_x"]              = "Desplazamiento X",
    ["opt_np_raid_icon_y"]              = "Desplazamiento Y",
    ["opt_np_raid_icon_size"]           = "Tamaño del icono",

    -- Castbar
    ["section_castbar"]                 = "Barra de lanzamiento",
    ["opt_np_show_castbar"]             = "Mostrar barra de lanzamiento",
    ["opt_np_castbar_height"]           = "Altura de la barra de lanzamiento",
    ["color_castbar"]                   = "Barra de lanzamiento (interrumpible)",
    ["color_castbar_uninterruptible"]   = "Barra de lanzamiento (no interrumpible)",

    -- Auras
    ["section_auras"]                   = "Auras",
    ["opt_np_show_auras"]               = "Mostrar auras",
    ["opt_np_aura_size"]                = "Tamaño de icono",
    ["opt_np_max_auras"]                = "Cantidad máxima",
    ["opt_np_only_my_debuffs"]          = "Solo mis debuffs",

    -- Enemy Buffs
    ["section_enemy_buffs"]              = "Buffs enemigos",
    ["sublabel_enemy_buffs"]             = "— Buffs enemigos —",
    ["opt_enemy_buffs_enable"]           = "Mostrar buffs enemigos",
    ["opt_enemy_buffs_max"]              = "Máx. buffs",
    ["opt_enemy_buffs_size"]             = "Tamaño de icono de buff",
    ["info_enemy_buffs"]                 = "Muestra buffs activos (Enfurecer, escudos...) en unidades hostiles. Los iconos aparecen arriba a la derecha, apilándose hacia arriba.",
    ["opt_np_show_enemy_buffs"]          = "Mostrar buffs enemigos",
    ["opt_np_enemy_buff_size"]           = "Tamaño de icono de buff",
    ["opt_np_max_enemy_buffs"]           = "Máx. buffs enemigos",
    ["opt_np_enemy_buff_y_offset"]       = "Desplazamiento Y de buffs enemigos",

    -- Transparency
    ["section_transparency"]            = "Transparencia",
    ["opt_np_selected_alpha"]           = "Alfa seleccionado",
    ["opt_np_unselected_alpha"]         = "Alfa no seleccionado",

    -- Stacking
    ["section_stacking"]                = "Apilamiento",
    ["opt_np_overlap"]                  = "Superposición vertical",
    ["opt_np_top_inset"]                = "Límite superior de pantalla",

    -- Colors
    ["section_colors"]                  = "Colores",
    ["color_hostile"]                   = "Hostil (Enemigo)",
    ["color_neutral"]                   = "Neutral",
    ["color_friendly"]                  = "Amistoso",
    ["color_tapped"]                    = "Marcado (tapped)",
    ["color_focus"]                     = "Objetivo de foco",

    -- NPC Type Colors
    ["section_npc_type_colors"]         = "Colores por tipo de PNJ",
    ["color_caster"]                    = "Lanzador de hechizos",
    ["color_miniboss"]                  = "Mini-jefe (élite + nivel superior)",
    ["color_enemy_in_combat"]           = "Enemigo (predeterminado)",
    ["info_np_darken_ooc"]              = "Los enemigos fuera de combate se oscurecen automáticamente.",

    -- Classification colors
    ["section_classification_colors"]   = "Colores de clasificación",
    ["opt_np_use_classification"]       = "Colores por tipo de enemigo",
    ["color_boss"]                      = "Jefe",
    ["color_elite"]                     = "Élite / Mini-jefe",
    ["color_rare"]                      = "Raro",
    ["color_normal"]                    = "Normal",
    ["color_trivial"]                   = "Trivial",

    -- Tank mode
    ["section_tank_mode"]               = "Modo tanque",
    ["opt_np_tank_mode"]                = "Activar modo tanque (colores de amenaza)",
    ["color_no_threat"]                 = "Sin amenaza",
    ["color_low_threat"]                = "Amenaza baja",
    ["color_has_threat"]                = "Amenaza mantenida",
    ["color_dps_has_aggro"]             = "DPS/Sanador tiene aggro",
    ["color_dps_near_aggro"]            = "DPS/Sanador cerca del aggro",

    -- NP health format
    ["np_fmt_percent"]                  = "Porcentaje (75%)",
    ["np_fmt_current"]                  = "Actual (25.3K)",
    ["np_fmt_current_percent"]          = "Actual + %",

    -- Reset
    ["btn_reset_nameplates"]            = "Reiniciar Nameplates",

    -- =====================
    -- CONFIG: CD & Resource Panel
    -- =====================
    -- Resource colors
    ["section_resource_colors"]         = "Colores de recursos",
    ["res_runes_ready"]                 = "Runas (listas)",
    ["res_runes_cd"]                    = "Runas (enfriamiento)",

    -- Cooldown Manager
    ["tab_cdm"]                         = "Enfriamientos",
    ["tab_cdm_bars"]                    = "Barras",
    ["tab_resource_bars"]               = "Barras de recursos",
    ["tab_text_position"]               = "Texto y posición",
    ["tab_rb_colors"]                   = "Colores",
    ["info_rb_colors_custom"]           = "Cada color se puede personalizar haciendo clic en la muestra de color.",

    ["section_cdm"]                     = "Gestor de enfriamientos",
    ["opt_cdm_enable"]                  = "Activar gestor de enfriamientos",
    ["info_cdm_description"]            = "Reskin de los iconos del CooldownManager de Blizzard: bordes redondeados, overlay de clase en auras activas, colores de barrido personalizados, atenuación de utilidades, diseño centrado. Colocación mediante Edit Mode de Blizzard.",
    ["opt_cdm_show_hotkeys"]            = "Mostrar atajos de teclado",
    ["opt_cdm_combat_alpha"]            = "Modificar opacidad (combate / objetivo)",
    ["opt_cdm_alpha_combat"]            = "Alfa en combate",
    ["opt_cdm_alpha_target"]            = "Alfa con objetivo (fuera de combate)",
    ["opt_cdm_alpha_ooc"]               = "Alfa fuera de combate",
    ["section_cdm_overlay"]             = "Overlay y bordes",
    ["opt_cdm_custom_overlay"]          = "Color de overlay personalizado",
    ["opt_cdm_overlay_color"]           = "Color del overlay",
    ["opt_cdm_custom_swipe"]            = "Color de barrido activo personalizado",
    ["opt_cdm_swipe_color"]             = "Color del barrido",
    ["opt_cdm_swipe_alpha"]             = "Opacidad del barrido",
    ["section_cdm_utility"]             = "Utilidad",
    ["opt_cdm_dim_utility"]             = "Atenuar iconos de utilidad fuera de CD",
    ["opt_cdm_dim_opacity"]             = "Opacidad de atenuación",
    ["opt_cdm_bufficon_direction"]        = "Dirección iconos de buff",
    ["opt_cdm_buffbar_direction"]         = "Dirección BuffBar",
    ["opt_cdm_buffbar_width"]             = "Ancho barra (horizontal)",
    ["buffbar_vertical"]                  = "Vertical",
    ["buffbar_horizontal"]                = "Horizontal",
    ["dir_centered"]                      = "Centrado (horizontal)",
    ["dir_left"]                          = "Izquierda",
    ["dir_right"]                         = "Derecha",
    ["dir_up"]                            = "Arriba",
    ["dir_down"]                          = "Abajo",
    ["info_cdm_editmode"]               = "La colocación se realiza mediante el Edit Mode de Blizzard (Esc |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Edit Mode).",

    -- CDM V3.2: Colocación y tarjetas de viewer (Phase 4)
    ["section_cdm_placement"]            = "Colocación y vista previa en vivo",
    ["info_cdm_placement"]               = "Las barras del CDM ahora son posicionadas por TomoMod (ya no se necesita el Edit Mode de Blizzard). El modo de colocación muestra iconos ficticios y permite arrastrar cada barra.",
    ["btn_cdm_unlock"]                   = "Modo de colocación (en vivo)",
    ["opt_cdm_preview"]                  = "Vista previa (iconos ficticios)",
    ["info_cdm_preview_live"]            = "Ajustes por barra en la pestaña «Barras» — todo se aplica en vivo.",
    ["info_cdm_bars"]                    = "Cada barra tiene su propia posición y disposición. Activa la vista previa para ver los cambios en vivo, o el modo de colocación para arrastrar las barras con el ratón.",
    ["btn_cdm_reset_pos"]                = "Restablecer posiciones",
    ["msg_cdm_pos_reset"]                = "Posiciones del CDM restablecidas.",
    ["section_cdm_essential"]            = "Essential (hechizos principales)",
    ["section_cdm_utility_bar"]          = "Utility (hechizos de utilidad)",
    ["section_cdm_bufficons"]            = "Iconos de buff (auras — iconos)",
    ["section_cdm_buffbars"]             = "Barras de buff (auras — barras)",
    ["opt_cdm_pos_x"]                    = "Posición X",
    ["opt_cdm_pos_y"]                    = "Posición Y",
    ["opt_cdm_icon_size"]                = "Tamaño de icono (0 = automático)",
    ["opt_cdm_spacing"]                  = "Espaciado",
    ["opt_cdm_row_limit"]                = "Por fila (0 = ilimitado)",
    ["opt_cdm_direction"]                = "Dirección",
    ["opt_cdm_secondary_direction"]      = "Dirección secundaria",
    ["opt_cdm_buffbar_spacing"]          = "Espaciado",
    ["secdir_auto"]                      = "Auto",
    ["secdir_down"]                      = "Filas hacia abajo",
    ["secdir_up"]                        = "Filas hacia arriba",
    ["secdir_right"]                     = "Columnas hacia la derecha",
    ["secdir_left"]                      = "Columnas hacia la izquierda",

    -- Resource Bars
    ["section_resource_bars"]           = "Barras de recursos",
    ["opt_rb_enable"]                   = "Activar barras de recursos",
    ["info_rb_description"]             = "Muestra recursos de clase (Maná, Ira, Energía, Puntos de combo, Runas, etc.) con soporte adaptativo para Druidas.",
    ["section_visibility"]              = "Visibilidad",
    ["opt_rb_visibility_mode"]          = "Modo de visibilidad",
    ["vis_always"]                      = "Siempre visible",
    ["vis_combat"]                      = "Solo en combate",
    ["vis_target"]                      = "Combate u objetivo",
    ["vis_hidden"]                      = "Oculto",
    ["opt_rb_combat_alpha"]             = "Alfa en combate",
    ["opt_rb_ooc_alpha"]                = "Alfa fuera de combate",
    ["opt_rb_width"]                    = "Ancho",
    ["opt_rb_classpower_height"]        = "Altura del poder de clase",
    ["opt_rb_druidmana_height"]         = "Altura de maná de druida",
    ["opt_rb_global_scale"]             = "Escala global",

    -- v2.9: Barra de vida (HUD)
    ["section_rb_healthbar"]            = "Barra de vida (HUD)",
    ["opt_rb_hb_enable"]                = "Mostrar barra de vida",
    ["info_rb_healthbar"]               = "Barra de vida centrada sobre los recursos. Texto y color de umbral gestionados en el cliente (compatible con Midnight).",
    ["opt_rb_hb_height"]                = "Altura",
    ["opt_rb_hb_text"]                  = "Texto",
    ["hb_text_none"]                    = "Ninguno",
    ["hb_text_value"]                   = "Valor",
    ["hb_text_percent"]                 = "Porcentaje",
    ["hb_text_both"]                    = "Valor | %",
    ["opt_rb_hb_classcolor"]            = "Color de clase",
    ["opt_rb_hb_color"]                 = "Color personalizado (si el color de clase está desactivado)",
    ["opt_rb_hb_threshold"]             = "Umbral de vida baja (cambia el color)",
    ["opt_rb_hb_threshold_pct"]         = "Umbral (%)",
    ["opt_rb_hb_threshold_color"]       = "Color de vida baja",

    -- v2.9: Animaciones y barra de poder
    ["section_rb_anim"]                 = "Animaciones y barra de poder",
    ["opt_rb_smooth"]                   = "Animaciones suaves de las barras",
    ["opt_rb_power_ticks"]              = "Marcas en la barra de poder (% del máx.)",
    ["ticks_none"]                      = "Ninguno",
    ["opt_rb_power_threshold"]          = "Umbral de recurso bajo (barra de poder)",
    ["opt_rb_power_threshold_pct"]      = "Umbral (%)",
    ["opt_rb_power_threshold_color"]    = "Color de recurso bajo",
    ["info_rb_anim"]                    = "Las marcas y el umbral se aplican a la barra de poder centrada. El suavizado también se aplica a la barra de vida, al maná de druida y a las barras de auras.",

    ["opt_rb_sync_width"]               = "Sincronizar ancho con Essential Cooldowns",
    ["btn_sync_now"]                    = "Sincronizar ahora",
    ["info_rb_sync"]                    = "Alinea el ancho con el EssentialCooldownViewer del CooldownManager de Blizzard.",

    -- Text & Font
    ["section_text_font"]               = "Texto y fuente",
    ["opt_rb_show_text"]                = "Mostrar texto en barras",
    ["opt_rb_text_align"]               = "Alineación del texto",
    ["align_left"]                      = "Izquierda",
    ["align_center"]                    = "Centro",
    ["align_right"]                     = "Derecha",
    ["opt_rb_font_size"]                = "Tamaño de fuente",
    ["opt_rb_font"]                     = "Fuente",
    ["font_default_wow"]                = "WoW predeterminado",

    -- Position
    ["section_position"]                = "Posición",
    ["info_rb_position"]                = "Usa /tm uf para desbloquear y mover las barras. La posición se guarda automáticamente.",
    ["info_rb_druid"]                   = "Las barras se adaptan automáticamente a tu clase y especialización.\nDruida: el recurso cambia con la forma (Oso |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Ira, Gato |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Energía, Equilibrio |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Poder astral).",

    -- =====================
    -- CONFIG: QOL Panel
    -- =====================
    ["tab_qol_cinematic"]               = "Cinemática",
    ["tab_qol_auto_quest"]              = "Auto misiones",
    ["tab_qol_automations"]             = "Automatizaciones",
    ["tab_qol_mythic_keys"]             = "Llaves M+",
    ["tab_qol_skyride"]                 = "SkyRide",
    ["tab_qol_action_bars"]             = "Barras de acción",
    ["section_action_bars"]             = "Skin de barras de acción",
    ["section_ab_system"]               = "Action Bar System",
    ["opt_ab_system_enable"]            = "Enable TomoMod Action Bar system (requires reload)",
    ["opt_ab_system_reload"]            = "Disabling this fully restores Blizzard action bars after /reload.",
    ["section_ab_skin"]                 = "Visual Skin",
    ["cat_action_bars"]                 = "Barras de acción",
    ["opt_abs_enable"]                  = "Activar skin de barras de acción",
    ["opt_abs_class_color"]             = "Color de clase para bordes",
    ["opt_abs_shift_reveal"]            = "Mantener Shift para revelar barras ocultas",
    ["sublabel_bar_opacity"]            = "— Opacidad por barra —",
    ["opt_abs_select_bar"]              = "Seleccionar barra de acción",
    ["opt_abs_opacity"]                 = "Opacidad",
    ["btn_abs_apply_all_opacity"]       = "Aplicar a todas las barras",
    ["msg_abs_all_opacity"]             = "Opacidad establecida a %d%% en todas las barras",
    ["sublabel_bar_combat"]             = "— Visibilidad en combate —",
    ["opt_abs_combat_show"]             = "Mostrar solo en combate",

    ["section_cinematic"]               = "Saltar cinemáticas",
    ["opt_cinematic_auto_skip"]         = "Saltar automáticamente después de verla una vez",
    ["info_cinematic_viewed"]           = "Cinemáticas ya vistas: %s\nEl historial se comparte entre personajes.",
    ["btn_clear_history"]               = "Borrar historial",

    -- Auto Quest
    ["section_auto_quest"]              = "Auto misiones",
    ["opt_quest_auto_accept"]           = "Aceptar misiones automáticamente",
    ["opt_quest_auto_turnin"]           = "Entregar misiones automáticamente",
    ["opt_quest_auto_gossip"]           = "Seleccionar diálogos automáticamente",
    ["info_quest_shift"]                = "Mantén SHIFT para desactivar temporalmente.\nLas misiones con múltiples recompensas no se entregan automáticamente.",

    -- Objective Tracker Skin
    ["tab_qol_obj_tracker"]             = "Rastreador",
    ["section_obj_tracker"]             = "Skin del rastreador de objetivos",
    ["opt_obj_tracker_enable"]          = "Activar skin del rastreador",
    ["opt_obj_tracker_bg_alpha"]        = "Opacidad del fondo",
    ["opt_obj_tracker_border"]          = "Mostrar borde",
    ["opt_obj_tracker_hide_empty"]      = "Ocultar si está vacío",
    ["opt_obj_tracker_buckets"]         = "Agrupar misiones en categorías plegables",
    ["opt_obj_tracker_header_size"]     = "Tamaño de fuente de encabezado",
    ["opt_obj_tracker_cat_size"]        = "Tamaño de fuente de categoría",
    ["opt_obj_tracker_quest_size"]      = "Tamaño de fuente de título de misión",
    ["opt_obj_tracker_obj_size"]        = "Tamaño de fuente de objetivo",
    ["opt_obj_tracker_max_quests"]       = "Máx. misiones mostradas (0 = sin límite)",
    ["ot_overflow_text"]                 = "%d misión(es) más oculta(s)...",
    ["info_obj_tracker"]                = "Aplica un skin oscuro al rastreador de objetivos de Blizzard con un panel, fuentes personalizadas y encabezados de categoría coloreados.",
    ["ot_header_title"]                 = "OBJETIVOS",
    ["ot_header_options"]               = "Opciones",

    -- Automations
    ["section_automations"]             = "Automatizaciones",
    ["opt_hide_blizzard_castbar"]       = "Ocultar barra de lanzamiento de Blizzard",
    ["opt_hide_talking_head"]           = "Ocultar Talking Head (di\195\161logos de desplazamiento)",

    -- Auto Accept Invite
    ["sublabel_auto_accept_invite"]     = "— Aceptar invitación automáticamente —",
    ["sublabel_auto_skip_role"]         = "— Saltar verificación de rol —",
    ["sublabel_tooltip_ids"]            = "— IDs de Tooltip —",
    ["sublabel_combat_res_tracker"]     = "— Rastreador de res. en combate —",
    ["opt_cr_show_rating"]              = "Mostrar puntuación M+",
    ["opt_show_messages"]               = "Mostrar mensajes en chat",
    ["opt_tid_spell"]                   = "ID de hechizo / aura",
    ["opt_tid_item"]                    = "ID de objeto",
    ["opt_tid_npc"]                     = "ID de PNJ",
    ["opt_tid_quest"]                   = "ID de misión",
    ["opt_tid_mount"]                   = "ID de montura",
    ["opt_tid_currency"]                = "ID de moneda",
    ["opt_tid_achievement"]             = "ID de logro",
    ["opt_accept_friends"]              = "Aceptar de amigos",
    ["opt_accept_guild"]                = "Aceptar de hermandad",

    -- Auto Summon
    ["sublabel_auto_summon"]            = "— Auto invocación —",
    ["opt_summon_delay"]                = "Retraso (segundos)",

    -- Auto Fill Delete
    ["sublabel_auto_fill_delete"]       = "— Auto rellenar ELIMINAR —",
    ["sublabel_auto_vendor_repair"]     = "— Auto Vendedor / Reparación —",
    ["opt_avr_auto_repair"]             = "Reparación automática en el comerciante",
    ["opt_avr_sell_grays"]              = "Vender automáticamente objetos grises (pobres)",
    ["opt_focus_ok_button"]             = "Enfocar botón OK tras rellenar",

    -- Mythic+ Keys
    ["section_mythic_keys"]             = "Llaves Míticas+",
    ["opt_keys_enable_tracker"]         = "Activar rastreador",
    ["opt_keys_mini_frame"]             = "Mini-marco en interfaz M+",
    ["opt_keys_auto_refresh"]           = "Actualización automática",

    -- SkyRide
    ["section_skyride"]                 = "SkyRide",
    ["opt_skyride_enable"]              = "Activar (pantalla de vuelo)",
    ["section_skyride_dims"]            = "Dimensiones",
    ["opt_skyride_bar_height"]          = "Altura de barra de velocidad",
    ["opt_skyride_charge_height"]       = "Altura de barra de carga",
    ["opt_skyride_charge_gap"]          = "Espacio entre segmentos",
    ["section_skyride_text"]            = "Texto",
    ["opt_skyride_show_speed_text"]     = "Mostrar porcentaje de velocidad",
    ["opt_skyride_speed_font_size"]     = "Tamaño de fuente de velocidad",
    ["opt_skyride_show_charge_timer"]   = "Mostrar temporizador de carga",
    ["opt_skyride_charge_font_size"]    = "Tamaño de fuente del temporizador",
    ["btn_reset_skyride"]               = "Reiniciar posición de SkyRide",

    -- =====================
    -- CONFIG: QOL — CVar Optimizer
    -- =====================
    ["tab_qol_cvar_opt"]                = "CVars Perf",
    ["section_cvar_optimizer"]          = "Optimizador de CVars",
    ["info_cvar_optimizer"]             = "Aplica ajustes gráficos/rendimiento recomendados. Tus valores actuales se guardan y pueden restaurarse en cualquier momento.",
    ["btn_cvar_apply_all"]              = ">> Aplicar todo",
    ["btn_cvar_revert_all"]             = "<< Restaurar todo",
    ["btn_cvar_apply"]                  = "Aplicar",
    ["btn_cvar_revert"]                 = "Restaurar",
    -- Categories
    ["opt_cat_render"]                  = "Renderizado y pantalla",
    ["opt_cat_graphics"]                = "Calidad gráfica",
    ["opt_cat_detail"]                  = "Distancia de visión y detalles",
    ["opt_cat_advanced"]                = "Avanzado",
    ["opt_cat_fps"]                     = "Límites de FPS",
    ["opt_cat_post"]                    = "Post-procesado",
    -- CVar labels
    ["opt_cvar_render_scale"]           = "Escala de renderizado",
    ["opt_cvar_vsync"]                  = "VSync",
    ["opt_cvar_msaa"]                   = "Multisampling (MSAA)",
    ["opt_cvar_low_latency"]            = "Modo de baja latencia",
    ["opt_cvar_anti_aliasing"]          = "Anti-aliasing",
    ["opt_cvar_shadow"]                 = "Calidad de sombras",
    ["opt_cvar_ssao"]                   = "SSAO",
    ["opt_cvar_depth"]                  = "Efectos de profundidad",
    ["opt_cvar_compute"]                = "Efectos de cálculo",
    ["opt_cvar_particle"]               = "Densidad de partículas",
    ["opt_cvar_liquid"]                 = "Detalle de líquidos",
    ["opt_cvar_spell_density"]          = "Densidad de hechizos",
    ["opt_cvar_projected"]              = "Texturas proyectadas",
    ["opt_cvar_outline"]                = "Modo de contorno",
    ["opt_cvar_texture_res"]            = "Resolución de texturas",
    ["opt_cvar_view_distance"]          = "Distancia de visión",
    ["opt_cvar_env_detail"]             = "Detalle del entorno",
    ["opt_cvar_ground"]                 = "Vegetación del suelo",
    ["opt_cvar_gfx_api"]                = "API gráfica",
    ["opt_cvar_triple_buffering"]       = "Triple buffering",
    ["opt_cvar_texture_filtering"]      = "Filtrado de texturas",
    ["opt_cvar_rt_shadows"]             = "Sombras ray tracing",
    ["opt_cvar_resample_quality"]       = "Calidad de remuestreo",
    ["opt_cvar_physics"]                = "Nivel de física",
    ["opt_cvar_target_fps"]             = "FPS objetivo",
    ["opt_cvar_bg_fps_enable"]          = "Límite de FPS en segundo plano",
    ["opt_cvar_bg_fps"]                 = "Valor de FPS en segundo plano",
    ["opt_cvar_resample_sharpness"]     = "Nitidez de remuestreo",
    ["opt_cvar_camera_shake"]           = "Vibración de cámara",
    -- Messages
    ["msg_cvar_applied"]                = "CVars aplicadas",
    ["msg_cvar_reverted"]               = "CVars restauradas",
    ["msg_cvar_no_backup"]              = "No se encontró respaldo — aplica primero.",
    ["tab_qol_leveling"]                = "Leveling",
    ["section_leveling_bar"]            = "Barra de experiencia",
    ["opt_leveling_enable"]             = "Activar barra de experiencia",
    ["opt_leveling_width"]              = "Ancho de la barra",
    ["opt_leveling_height"]             = "Altura de la barra",
    ["btn_reset_leveling_pos"]          = "Reiniciar posición",
    ["leveling_bar_title"]              = "Barra de experiencia",
    ["leveling_level"]                  = "Nivel",
    ["leveling_progress"]               = "Progreso:",
    ["leveling_rested"]                 = "Descansado",
    ["leveling_last_quest"]             = "Última misión:",
    ["leveling_ttl"]                    = "Tiempo para nivel:",
    ["leveling_drag_hint"]              = "/tm sr para desbloquear y mover",

    -- =====================
    -- CONFIG: Profiles Panel (3 Tabs)
    -- =====================
    ["tab_profiles"]                    = "Perfiles",
    ["tab_import_export"]               = "Importar/Exportar",
    ["tab_resets"]                      = "Reinicio",

    -- Tab 1: Named profiles & specializations
    ["section_named_profiles"]          = "Perfiles",
    ["info_named_profiles"]             = "Crea y gestiona perfiles con nombre. Cada perfil guarda una instantánea completa de tus ajustes.",
    ["profile_active_label"]            = "Perfil activo",
    ["opt_select_profile"]              = "Elegir un perfil",
    ["sublabel_create_profile"]         = "— Crear nuevo perfil —",
    ["placeholder_profile_name"]        = "Nombre del perfil...",
    ["btn_create_profile"]              = "Crear perfil",
    ["btn_delete_named_profile"]        = "Eliminar perfil",
    ["btn_save_profile"]                = "Guardar perfil actual",
    ["info_save_profile"]               = "Guarda todos los ajustes actuales en el perfil activo. Esto se hace automáticamente al cambiar de perfil.",

    ["section_profile_mode"]            = "Modo de perfil",
    ["info_spec_profiles"]              = "Activa perfiles por especialización para guardar y cargar ajustes automáticamente al cambiar de especialización.\nCada especialización tiene su propia configuración independiente.",
    ["opt_enable_spec_profiles"]        = "Activar perfiles por especialización",
    ["profile_status"]                  = "Perfil activo",
    ["profile_global"]                  = "Global (perfil único)",
    ["section_spec_list"]               = "Especializaciones",
    ["profile_badge_active"]            = "Activo",
    ["profile_badge_saved"]             = "Guardado",
    ["profile_badge_none"]              = "Sin perfil",
    ["btn_copy_to_spec"]                = "Copiar actual",
    ["btn_delete_profile"]              = "Eliminar",
    ["info_spec_reload"]                = "Cambiar de especialización con perfiles activados recargará automáticamente la interfaz para aplicar el perfil correspondiente.",
    ["info_global_mode"]                = "Todas las especializaciones comparten los mismos ajustes. Activa perfiles por especialización arriba para usar configuraciones diferentes.",

    -- Tab 2: Import / Export
    ["section_export"]                  = "Exportar ajustes",
    ["info_export"]                     = "Genera una cadena comprimida de todos tus ajustes actuales.\nCópiala para compartirla o como copia de seguridad.",
    ["label_export_string"]             = "Cadena de exportación (clic para seleccionar todo)",
    ["btn_export"]                      = "Generar cadena de exportación",
    ["btn_copy_clipboard"]              = "Copiar texto",
    ["section_import"]                  = "Importar ajustes",
    ["info_import"]                     = "Pega una cadena de exportación abajo. Se validará antes de aplicarla.",
    ["label_import_string"]             = "Pega la cadena de importación aquí",
    ["btn_import"]                      = "Importar y aplicar",
    ["btn_paste_clipboard"]             = "Pegar texto",
    ["import_preview"]                  = "Clase: %s | Módulos: %s | Fecha: %s",
    ["import_preview_valid"]            = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t Cadena válida",
    ["import_preview_invalid"]          = "Cadena inválida o corrupta",
    ["info_import_warning"]             = "La importación SOBRESCRIBIRÁ todos tus ajustes actuales y recargará la interfaz. Esta acción no se puede deshacer.",

    -- Tab 3: Resets
    ["section_profile_mgmt"]            = "Gestión de perfiles",
    ["info_profiles"]                   = "Reinicia módulos individuales o exporta/importa tus ajustes.\nExportar copia los ajustes al portapapeles (requiere LibSerialize + LibDeflate).",
    ["section_reset_module"]            = "Reiniciar un módulo",
    ["btn_reset_prefix"]                = "Reiniciar: ",
    ["btn_reset_all_reload"]            = "(!) REINICIAR TODO + Recargar",
    ["section_reset_all"]               = "Reinicio completo",
    ["info_resets"]                     = "Reinicia un módulo individual a sus valores predeterminados. El módulo se recargará con los ajustes de fábrica.",
    ["info_reset_all_warning"]          = "Esto reiniciará TODOS los módulos y TODOS los ajustes a valores de fábrica, y luego recargará la interfaz.",

    -- =====================
    -- PRINT MESSAGES: Core
    -- =====================
    ["msg_db_reset"]                    = "Base de datos reiniciada",
    ["msg_module_reset"]                = "Módulo '%s' reiniciado",
    ["msg_db_not_init"]                 = "Base de datos no inicializada",
    ["msg_loaded"]                      = "v2.0 cargado — %s para configuración",
    ["msg_report_issue"]                = "Si encuentras algún problema, deja un comentario en CurseForge.",
    ["msg_help_title"]                  = "v2.0 — Comandos:",
    ["msg_help_open"]                   = "Abrir configuración",
    ["msg_help_reset"]                  = "Reiniciar todo + recargar",
    ["msg_help_uf"]                     = "Bloquear/Desbloquear UnitFrames + Recursos",
    ["msg_help_uf_reset"]               = "Reiniciar UnitFrames",
    ["msg_help_rb"]                     = "Bloquear/Desbloquear barras de recursos",
    ["msg_help_rb_sync"]                = "Sincronizar ancho con Essential Cooldowns",
    ["msg_help_np"]                     = "Activar/desactivar Nameplates",
    ["msg_help_minimap"]                = "Reiniciar minimapa",
    ["msg_help_panel"]                  = "Reiniciar panel de info",
    ["msg_help_cursor"]                 = "Reiniciar anillo de cursor",
    ["msg_help_clearcinema"]            = "Borrar historial de cinemáticas",
    ["msg_help_sr"]                     = "Bloquear/Desbloquear SkyRide + Anclas",
    ["msg_help_key"]                    = "Abrir llaves Míticas+",
    ["msg_help_help"]                   = "Esta ayuda",

    -- =====================
    -- PRINT MESSAGES: Modules
    -- =====================
    -- CDM
    ["msg_cdm_status"]                  = "Activado",
    ["msg_cdm_disabled"]                = "Desactivado",

    -- Nameplates
    ["msg_np_enabled"]                  = "Activadas",
    ["msg_np_disabled"]                 = "Desactivadas",

    -- UnitFrames
    ["msg_uf_locked"]                   = "Bloqueado",
    ["msg_uf_unlocked"]                 = "Desbloqueado — Arrastra para reposicionar",
    ["msg_uf_initialized"]              = "Inicializado — /tm uf para bloquear/desbloquear",
    ["msg_uf_enabled"]                  = "activado (recarga necesaria)",
    ["msg_uf_disabled"]                 = "desactivado (recarga necesaria)",
    ["msg_uf_position_reset"]           = "posición reiniciada",

    -- ResourceBars
    ["msg_rb_width_synced"]             = "Ancho sincronizado (%dpx)",
    ["msg_rb_locked"]                   = "Bloqueado",
    ["msg_rb_unlocked"]                 = "Desbloqueado — Arrastra para reposicionar",
    ["msg_rb_position_reset"]           = "Posición de barras de recursos reiniciada",

    -- SkyRide
    ["msg_sr_pos_saved"]                = "Posición de SkyRide guardada",
    ["msg_sr_locked"]                   = "SkyRide bloqueado",
    ["msg_sr_unlock"]                   = "Modo de movimiento de SkyRide activado – Haz clic y arrastra",
    ["msg_sr_pos_reset"]                = "Posición de SkyRide reiniciada",
    ["msg_sr_db_not_init"]              = "TomoModDB no inicializada",
    ["msg_sr_initialized"]              = "Módulo SkyRide inicializado",

    -- FrameAnchors
    ["anchor_alert"]                    = "Alertas",
    ["anchor_loot"]                     = "Botín",
    ["msg_anchors_locked"]              = "Bloqueados",
    ["msg_anchors_unlocked"]            = "Desbloqueados — mueve las anclas",

    -- AutoVendorRepair
    ["msg_avr_header"]                  = "[AutoVendedorReparar]",
    ["msg_avr_sold"]                    = " Objetos grises vendidos por |cffffff00%s|r",
    ["msg_avr_repaired"]                = " Equipo reparado por |cffffff00%s|r",

    -- AutoFillDelete
    ["msg_afd_filled"]                  = "Texto 'ELIMINAR' auto-rellenado – Haz clic en OK para confirmar",
    ["msg_afd_db_not_init"]             = "TomoModDB no inicializada",
    ["msg_afd_initialized"]             = "Módulo AutoFillDelete inicializado",
    ["msg_afd_enabled"]                 = "Auto-rellenar ELIMINAR activado",
    ["msg_afd_disabled"]                = "Auto-rellenar ELIMINAR desactivado (el hook permanece activo)",

    -- HideCastBar
    ["msg_hcb_db_not_init"]             = "TomoModDB no inicializada",
    ["msg_hcb_initialized"]             = "Módulo HideCastBar inicializado",
    ["msg_hcb_hidden"]                  = "Barra de lanzamiento oculta",
    ["msg_hcb_shown"]                   = "Barra de lanzamiento mostrada",

    -- AutoAcceptInvite
    ["msg_aai_accepted"]                = "Invitación aceptada de ",
    ["msg_aai_ignored"]                 = "Invitación ignorada de ",
    ["msg_aai_enabled"]                 = "Auto-aceptar invitaciones activado",
    ["msg_aai_disabled"]                = "Auto-aceptar invitaciones desactivado",
    ["msg_asr_lfg_accepted"]            = "Verificación de rol auto-confirmada",
    ["msg_asr_poll_accepted"]           = "Encuesta de rol auto-confirmada",
    ["msg_asr_enabled"]                 = "Auto saltar verificación de rol activado",
    ["msg_asr_disabled"]                = "Auto saltar verificación de rol desactivado",
    ["msg_tid_enabled"]                 = "Tooltip IDs activado",
    ["msg_tid_disabled"]                = "Tooltip IDs desactivado",
    ["msg_cr_enabled"]                  = "Rastreador de res. en combate activado",
    ["msg_cr_disabled"]                 = "Rastreador de res. en combate desactivado",
    ["msg_cr_locked"]                   = "Rastreador de res. en combate bloqueado",
    ["msg_cr_unlock"]                   = "Rastreador de res. en combate desbloqueado — arrastra para mover",
    ["msg_abs_enabled"]                 = "Skin de barras de acción activado (recarga recomendada)",
    ["msg_abs_disabled"]                = "Skin de barras de acción desactivado",
    ["opt_buffskin_enable"]             = "Activar skin de buffs",
    ["opt_buffskin_desc"]               = "Añade bordes negros y temporizador coloreado en buffs/debuffs del jugador",
    ["msg_buffskin_enabled"]            = "Skin de buffs activado",
    ["msg_buffskin_disabled"]           = "Skin de buffs desactivado",
    ["msg_help_cr"]                     = "Bloquear/desbloquear rastreador de res. en combate",
    ["msg_help_cs"]                     = "Bloquear/desbloquear posición de hoja de personaje",
    ["msg_help_cs_reset"]               = "Reiniciar posición de hoja de personaje",

    -- CinematicSkip
    ["msg_cin_skipped"]                 = "Cinemática saltada (ya vista)",
    ["msg_vid_skipped"]                 = "Video saltado (ya visto)",
    ["msg_vid_id_skipped"]              = "Video #%d saltado",
    ["msg_cin_cleared"]                 = "Historial de cinemáticas borrado",

    -- AutoSummon
    ["msg_sum_accepted"]                = "Invocación aceptada de %s a %s (%s)",
    ["msg_sum_ignored"]                 = "Invocación ignorada de %s (no confiable)",
    ["msg_sum_enabled"]                 = "Auto-invocación activada",
    ["msg_sum_disabled"]                = "Auto-invocación desactivada",
    ["msg_sum_manual"]                  = "Invocación aceptada manualmente",
    ["msg_sum_no_pending"]              = "Sin invocación pendiente",

    -- MythicKeys
    ["msg_keys_no_key"]                 = "Sin llave para enviar.",
    ["msg_keys_not_in_group"]           = "Debes estar en un grupo.",
    ["msg_keys_reload"]                 = "Cambio aplicado en el próximo /reload.",
    ["mk_not_in_group"]                 = "No estás en un grupo.",
    ["mk_not_in_group_short"]           = "No estás en grupo.",
    ["mk_no_key_self"]                  = "No se encontró piedra angular.",
    ["mk_title"]                        = "TM — Llaves Míticas",
    ["mk_btn_send"]                     = "Enviar al chat",
    ["mk_btn_refresh"]                  = "Actualizar",
    ["mk_tab_keys"]                     = "Llaves",
    ["mk_tab_tp"]                       = "TP",
    ["mk_tp_click_to_tp"]              = "Clic para teletransportarse",
    ["mk_tp_not_unlocked"]             = "No desbloqueado",
    ["msg_tp_not_owned"]               = "No tienes el teletransporte para %s",
    ["msg_tp_combat"]                  = "No se pueden actualizar teletransportes en combate.",

    -- =====================
    -- PRINT MESSAGES: Config Panels
    -- =====================
    ["msg_np_reset"]                    = "Nameplates reiniciadas (recarga recomendada)",
    ["msg_uf_toggle"]                   = "UnitFrames %s (recarga)",
    ["msg_profile_reset"]               = "%s reiniciado",
    ["msg_profile_copied"]              = "Ajustes actuales copiados a '%s'",
    ["msg_profile_deleted"]             = "Perfil eliminado para '%s'",
    ["msg_profile_loaded"]              = "Perfil '%s' cargado — recarga para aplicar",
    ["msg_profile_load_failed"]         = "Error al cargar el perfil '%s'",
    ["msg_profile_created"]             = "Perfil '%s' creado con los ajustes actuales",
    ["msg_profile_name_empty"]          = "Por favor, introduce un nombre de perfil",
    ["msg_profile_saved"]               = "Ajustes guardados en el perfil '%s'",

    -- New profile keys v2.3.0
    ["btn_rename_profile"]              = "Renombrar",
    ["btn_duplicate_profile"]           = "Duplicar",
    ["btn_load_profile"]                = "Cargar",
    ["btn_close"]                       = "Cerrar",
    ["btn_cancel"]                      = "Cancelar",
    ["section_spec_assign"]             = "Perfiles por especialización",
    ["info_spec_assign"]                = "Asigna cada especialización a un perfil con nombre. TomoMod cambiará automáticamente de perfil al cambiar de especialización.",
    ["spec_profile_none"]               = "— Ninguno —",
    ["popup_rename_profile"]            = "|cff2ed884TomoMod|r\n\nNuevo nombre para '%s':",
    ["popup_duplicate_profile"]         = "|cff2ed884TomoMod|r\n\nDuplicar '%s' como:",
    ["msg_profile_renamed"]             = "Perfil '%s' renombrado a '%s'",
    ["msg_profile_duplicated"]          = "Perfil '%s' duplicado como '%s'",
    ["msg_import_as_profile"]           = "Perfil importado como '%s'",
    ["popup_export_title"]              = "Exportar perfil",
    ["popup_export_hint"]               = "Selecciona todo (Ctrl+A) y copia (Ctrl+C)",
    ["popup_import_title"]              = "Importar perfil",
    ["popup_import_hint"]               = "Pega una cadena de exportación de TomoMod, luego haz clic en Importar",
    ["label_import_profile_name"]       = "Guardar como nombre de perfil:",
    ["placeholder_import_profile_name"] = "Nombre del perfil (opcional)...",
    ["msg_profile_name_deleted"]        = "Perfil '%s' eliminado",
    ["msg_export_success"]              = "Cadena de exportación generada — selecciona todo y copia",
    ["msg_import_success"]              = "Ajustes importados con éxito — recargando...",
    ["msg_import_empty"]                = "Nada que importar — pega una cadena primero",
    ["msg_copy_hint"]                   = "Texto seleccionado — pulsa Ctrl+C para copiar",
    ["msg_copy_empty"]                  = "Genera primero una cadena de exportación",
    ["msg_paste_hint"]                  = "Pulsa Ctrl+V para pegar tu cadena de importación",
    ["msg_spec_changed_reload"]         = "Especialización cambiada — cargando perfil...",

    -- =====================
    -- INFO PANEL (Minimap)
    -- =====================
    ["time_server"]                     = "Servidor",
    ["time_local"]                      = "Local",
    ["time_tooltip_title"]              = "Hora (%s - %s)",
    ["time_tooltip_left_click"]         = "|cff2ed884Clic izquierdo:|r Calendario",
    ["time_tooltip_right_click"]        = "|cff2ed884Clic derecho:|r Servidor / Local",
    ["time_tooltip_shift_right"]        = "|cff2ed884Shift + Clic derecho:|r 12h / 24h",
    ["time_format_msg"]                 = "Formato: %s",
    ["time_mode_msg"]                   = "Hora: %s",

    -- =====================
    -- ENABLED / DISABLED (generic)
    -- =====================
    ["enabled"]                         = "Activado",
    ["disabled"]                        = "Desactivado",

    -- Static Popups
    ["popup_reset_text"]                = "|cff2ed884TomoMod|r\n\n¿Reiniciar TODOS los ajustes?\nEsto recargará tu interfaz.",
    ["popup_confirm"]                   = "Confirmar",
    ["popup_cancel"]                    = "Cancelar",
    ["popup_import_text"]               = "|cff2ed884TomoMod|r\n\n¿Importar ajustes?\nEsto SOBRESCRIBIRÁ todos tus ajustes actuales y recargará la interfaz.",
    ["popup_profile_reload"]            = "|cff2ed884TomoMod|r\n\nModo de perfil cambiado.\n¿Recargar interfaz para aplicar?",
    ["popup_delete_profile"]            = "|cff2ed884TomoMod|r\n\n¿Eliminar perfil '%s'?\nEsta acción no se puede deshacer.",

    -- FPS element
    ["label_fps"]                       = "FPS",

    -- =====================
    -- BOSS FRAMES
    -- =====================
    ["tab_boss"]                        = "Jefe",
    ["section_boss_frames"]             = "Barras de jefe",
    ["opt_boss_enable"]                 = "Activar barras de jefe",
    ["opt_boss_height"]                 = "Altura de barras",
    ["opt_boss_spacing"]                = "Espacio entre barras",
    ["info_boss_drag"]                  = "Desbloquea (/tm uf) para mover. Arrastra Jefe 1 para reposicionar las 5 barras juntas.",
    ["info_boss_colors"]                = "Los colores de barra usan colores de clasificación de Nameplate (Jefe = rojo, Mini-jefe = morado).",
    ["msg_boss_initialized"]            = "Barras de jefe cargadas.",

    -- =====================
    -- SOUND / LUST DETECTION
    -- =====================
    ["cat_sound"]                       = "Sonido",
    ["section_sound_general"]           = "Sonido de Bloodlust",
        ["info_sound_desc"]                 = "Reproduce un sonido personalizado cuando se detecta un efecto de Bloodlust. La deteccion verifica directamente los buffs de Lust y los debuffs Sated/Exhaustion.",
    ["opt_sound_enable"]                = "Activar detección de Bloodlust",
    ["sublabel_sound_choice"]           = "Sonido y canal",
    ["opt_sound_file"]                  = "Sonido a reproducir",
    ["opt_sound_channel"]               = "Canal de audio",
    ["btn_sound_preview"]               = ">> Escuchar sonido",
    ["btn_sound_stop"]                  = "■  Detener",
    ["opt_sound_force"]                 = "Forzar sonido aunque el juego esté silenciado",
    ["opt_sound_chat"]                  = "Mostrar mensajes en chat",
    ["opt_sound_debug"]                 = "Mode debug",

    -- =====================
    -- BAG & MICRO MENU
    -- =====================
    ["tab_qol_bag_micro"]               = "Bolsa y menú",
    ["section_bag_micro"]               = "Barra de bolsa y micro menú",
    ["info_bag_micro"]                  = "Elige si mostrar siempre o revelar al pasar el ratón.",
    ["sublabel_bag_bar"]                = "— Barra de bolsa —",
    ["sublabel_micro_menu"]             = "— Micro menú —",
    ["opt_bag_bar_mode"]                = "Barra de bolsa",
    ["opt_micro_menu_mode"]             = "Micro menú",
    ["mode_show"]                       = "Siempre visible",
    ["mode_hover"]                      = "Mostrar al pasar el ratón",

    -- =====================
    -- CHARACTER SKIN
    -- =====================
    ["tab_qol_char_skin"]               = "Skin de personaje",
    ["section_char_skin"]               = "Skin de hoja de personaje",
    ["info_char_skin_desc"]             = "Aplica el tema oscuro de TomoMod a la hoja de personaje, reputación, monedas y ventana de inspección.",
    ["opt_char_skin_enable"]            = "Activar skin de personaje",
    ["opt_char_skin_character"]         = "Skin Personaje / Reputación / Monedas",
    ["opt_char_skin_inspect"]           = "Skin ventana de inspección",
    ["opt_char_skin_iteminfo"]          = "Mostrar info de objeto en huecos",
    ["opt_char_skin_gems"]              = "Mostrar gemas en los huecos",
    ["opt_char_skin_midnight"]          = "Encantamientos Midnight (Cabeza/Hombros en vez de Muñequeras/Capa)",
    ["opt_char_skin_scale"]             = "Escala de ventana",
    ["msg_char_skin_reload"]            = "Skin de personaje: /reload para aplicar cambios.",

    -- =====================
    -- LAYOUT / MOVERS SYSTEM
    -- =====================
    ["btn_layout"]                      = "EditMode",
    ["btn_layout_tooltip"]              = "EditMode: desbloquea todos los elementos para moverlos.",
    ["btn_reload_ui"]                   = "Recargar interfaz",
    ["layout_mode_title"]               = "TomoMod — EditMode",
    ["layout_mode_hint"]                = "Arrastra los elementos para reposicionar — haz clic en Bloquear cuando termines",
    ["layout_btn_lock"]                 = "Bloquear",
    ["layout_btn_reload"]               = "RL",
    ["layout_btn_gui"]                  = "GUI",
    ["grid_dimmed"]                    = "Cuadrícula",
    ["grid_bright"]                    = "Cuadrícula +",
    ["grid_disabled"]                  = "Cuadrícula OFF",
    ["layout_unlocked"]                 = "EditMode ACTIVO — arrastra los elementos. Haz clic en Bloquear o /tm layout cuando termines.",
    ["layout_locked"]                   = "EditMode DESACTIVADO — posiciones guardadas.",
    ["msg_help_layout"]                 = "Alternar EditMode (mover todos los elementos UI)",
    ["mover_unitframes"]                = "Unit Frames",
    ["mover_resources"]                 = "Barras de recursos",
    ["mover_skyriding"]                 = "Barra de Skyriding",
    ["mover_levelingbar"]               = "Barra XP / Experiencia",
    ["mover_anchors"]                   = "Anclas de alertas y botín",
    ["mover_cotank"]                    = "Rastreador de Co-Tank",
    ["mover_repbar"]                    = "Barra de reputación",
    ["mover_castbar"]                   = "Barra de lanzamiento (jugador)",
    ["mover_mythictracker"]             = "Tracker M+",
    ["mover_chatframe"]                 = "Ventana de chat",

    -- =====================
    -- COMBAT TEXT
    -- =====================
    ["sublabel_combat_text"]             = "— Texto de combate —",
    ["opt_combat_text_enable"]           = "Activar texto de combate",
    ["opt_combat_text_offset_x"]         = "Desplazamiento X",
    ["opt_combat_text_offset_y"]         = "Desplazamiento Y",

    -- =====================
    -- SKINS (Chat)
    -- =====================
    ["tab_qol_skins"]                    = "Skins",
    ["section_skins"]                    = "Skins de interfaz",
    ["info_skins_desc"]                  = "Aplica el tema oscuro de TomoMod a varios elementos de la interfaz de Blizzard. Puede necesitar /reload para revertir.",
    ["sublabel_chat_skin"]               = "— Ventana de chat —",
    ["opt_chat_skin_enable"]             = "Skin de la ventana de chat",
    ["opt_chat_skin_style"]              = "Estilo del skin",
    ["opt_chat_skin_style_tui"]          = "TUI (Barra lateral + Ventana)",
    ["opt_chat_skin_style_classic"]      = "Clásico (Enmarcado)",
    ["opt_chat_skin_style_glass"]        = "Cristal (Esmerilado)",
    ["opt_chat_skin_style_minimal"]      = "Mínimo (Sin bordes)",
    ["opt_chat_skin_bg_alpha"]           = "Opacidad del fondo",
    ["opt_chat_skin_font_size"]          = "Tamaño de fuente del chat",
    ["opt_chat_skin_fade"]               = "Fade chat when inactive",
    ["opt_chat_skin_short_channels"]     = "Short channel names (G, P, R…)",
    ["opt_chat_skin_timestamp"]          = "Show timestamps",
    ["opt_chat_skin_url"]                = "Clickable URLs",
    ["opt_chat_skin_emoji"]              = "Replace text emoticons with emoji",
    ["opt_chat_skin_class_colors"]       = "Class-color player names in chat",
    ["opt_chat_skin_history"]            = "Restore chat history on login",
    ["opt_chat_skin_copy_lines"]         = "Show copy icon per message",

    -- Buff Skin
    ["sublabel_buff_skin"]               = "— Skin de Buffs / Debuffs —",
    ["opt_buff_skin_enable"]             = "Skinear iconos de Buff/Debuff",
    ["opt_buff_skin_buffs"]              = "Aplicar a Buffs",
    ["opt_buff_skin_debuffs"]            = "Aplicar a Debuffs",
    ["opt_buff_skin_color_by_type"]       = "Colorear borde por tipo de debuff (Magia/Veneno/Maldición…)",
    ["opt_buff_skin_teal_border"]         = "Borde turquesa en buffs",
    ["opt_buff_skin_desaturate"]          = "Desaturar iconos de debuff",
    ["opt_buff_skin_hide_buffs"]         = "Ocultar marco de Buffs",
    ["opt_buff_skin_hide_debuffs"]       = "Ocultar marco de Debuffs",
    ["opt_buff_skin_font_size"]          = "Tamaño de fuente del temporizador",

    -- Game Menu Skin
    ["sublabel_game_menu_skin"]          = "— Menú de juego (Escape) —",
    ["opt_game_menu_skin_enable"]        = "Skinear menú de juego",
    ["info_game_menu_skin_reload"]       = "Se necesita /reload para revertir este skin.",
    ["msg_chat_skin_enabled"]            = "Skin del chat activado",
    ["msg_chat_skin_disabled"]           = "Skin del chat desactivado (reload para revertir)",
    ["sublabel_mail_skin"]               = "— Correo —",
    ["opt_mail_skin_enable"]             = "Skin del correo",
    ["msg_mail_skin_enabled"]            = "Skin del correo activado",
    ["msg_mail_skin_disabled"]           = "Skin del correo desactivado (reload para revertir)",

    -- =====================
    -- WORLD QUEST TAB
    -- =====================
    ["tab_qol_world_quests"]             = "Misiones de mundo",
    ["section_wq_tab"]                   = "Pestaña de misiones de mundo",
    ["info_wq_tab_desc"]                 = "Muestra una lista de misiones de mundo disponibles junto al mapa del mundo con detalles de recompensas, zona, facción y tiempo restante. Haz clic en una misión para navegar a su zona, Shift-Clic para super-rastrear.",
    ["opt_wq_enable"]                    = "Activar pestaña de misiones de mundo",
    ["opt_wq_auto_show"]                 = "Mostrar automáticamente al abrir el mapa",
    ["opt_wq_max_quests"]                = "Máx. misiones mostradas (0 = ilimitado)",
    ["opt_wq_min_time"]                  = "Tiempo restante mín. (minutos, 0 = todas)",
    ["section_wq_filters"]               = "Filtros de recompensa",
    ["opt_wq_filter_gold"]               = "Mostrar recompensas de oro",
    ["opt_wq_filter_gear"]               = "Mostrar recompensas de equipo",
    ["opt_wq_filter_rep"]                = "Mostrar recompensas de reputación",
    ["opt_wq_filter_currency"]           = "Mostrar recompensas de moneda",
    ["opt_wq_filter_anima"]              = "Mostrar recompensas de ánima",
    ["opt_wq_filter_pet"]                = "Mostrar recompensas de mascota",
    ["opt_wq_filter_other"]              = "Mostrar otras recompensas",
    ["wq_tab_title"]                     = "MM Lista",
    ["wq_panel_title"]                   = "Misiones de mundo",
    ["wq_col_name"]                      = "Nombre",
    ["wq_col_zone"]                      = "Zona",
    ["wq_col_reward"]                    = "Recompensa",
    ["wq_col_time"]                      = "Tiempo",
    ["wq_zone"]                          = "Zona",
    ["wq_faction"]                       = "Facción",
    ["wq_reward"]                        = "Recompensa",
    ["wq_time_left"]                     = "Tiempo restante",
    ["wq_elite"]                         = "Misión de mundo élite",
    ["wq_sort_time"]                     = "Tiempo",
    ["wq_sort_zone"]                     = "Zona",
    ["wq_sort_name"]                     = "Nombre",
    ["wq_sort_reward"]                   = "Recompensa",
    ["wq_sort_faction"]                  = "Facción",
    ["wq_status_count"]                  = "Mostrando %d / %d misiones",

    -- Profession Helper
    ["tab_qol_prof_helper"]              = "Profesiones",
    ["section_prof_helper"]              = "Asistente de profesiones",
    ["info_prof_helper_desc"]            = "Desencantar, moler y prospectar objetos en lote con una interfaz visual.",
    ["opt_prof_helper_enable"]           = "Activar asistente de profesiones",
    ["sublabel_prof_de_filters"]         = "— Filtros de calidad de desencantamiento —",
    ["opt_prof_filter_green"]            = "Incluir objetos Poco común (Verdes)",
    ["opt_prof_filter_blue"]             = "Incluir objetos Raros (Azules)",
    ["opt_prof_filter_epic"]             = "Incluir objetos Épicos (Morados)",
    ["btn_prof_open_helper"]             = "Abrir asistente de profesiones",
    ["ph_title"]                         = "Asistente de profesiones",
    ["ph_tab_disenchant"]                = "Desencantar",
    ["ph_filter_quality"]                = "Calidad:",
    ["ph_quality_green"]                 = "Verde",
    ["ph_quality_blue"]                  = "Azul",
    ["ph_quality_epic"]                  = "Épico",
    ["ph_select_all"]                    = "Seleccionar todo",
    ["ph_deselect_all"]                  = "Deseleccionar todo",
    ["ph_btn_process"]                   = "Procesar",
    ["ph_btn_click_process"]             = "Clic para procesar",
    ["ph_btn_stop"]                      = "Detener",
    ["ph_status_idle"]                   = "Haz clic en Procesar",
    ["ph_status_processing"]             = "Procesando %d/%d: %s",
    ["ph_status_done"]                   = "¡Listo! Todos los objetos procesados.",
    ["ph_item_count"]                    = "%d objetos disponibles",
    ["ph_ilvl"]                          = "iLvl %d",

    -- ── Class Reminder ──────────────────────────────────────────
    ["tab_qol_class_reminder"]           = "Recordatorio de clase",
    ["section_class_reminder"]           = "Recordatorio de buff / forma de clase",
    ["info_class_reminder"]              = "Muestra un texto pulsante en el centro de la pantalla cuando falta un buff de clase, forma, postura o aura.",
    ["opt_class_reminder_enable"]        = "Activar recordatorio de clase",
    ["opt_class_reminder_scale"]         = "Escala del texto",
    ["opt_class_reminder_color"]         = "Color del texto",
    ["sublabel_class_reminder_pos"]      = "— Desplazamiento de posición —",
    ["opt_class_reminder_x"]             = "Desplazamiento X",
    ["opt_class_reminder_y"]             = "Desplazamiento Y",

    -- Buff / Form names
    ["cr_fortitude"]                     = "Palabra de poder: Entereza",
    ["cr_shadowform"]                    = "Forma de las Sombras",
    ["cr_arcane_intellect"]              = "Intelecto Arcano",
    ["cr_skyfury"]                       = "Furia celeste",
    ["cr_mark_of_the_wild"]              = "Marca de lo Salvaje",
    ["cr_cat_form"]                      = "Forma de felino",
    ["cr_bear_form"]                     = "Forma de oso",
    ["cr_moonkin_form"]                  = "Forma de lechúcico lunar",
    ["cr_battle_shout"]                  = "Grito de batalla",
    ["cr_stance"]                        = "Postura",
    ["cr_aura"]                          = "Aura",
    ["cr_blessing_bronze"]               = "Bendición del Bronce",

    -- =====================
    -- MYTHIC TRACKER (TomoMythic integration)
    -- =====================
    ["tmt_cmd_usage"]               = "|cFF55B400/tmt|r : configuración  |  |cFF55B400unlock|r : mover  |  |cFF55B400lock|r : bloquear  |  |cFF55B400preview|r : vista previa  |  |cFF55B400key|r : llaves del grupo  |  |cFF55B400kr|r : ruleta",
    ["tmt_unlock_msg"]              = "|cff2ed884TomoMod|r M+ Tracker: Marco desbloqueado \226\128\148 arrastra para reposicionar.",
    ["tmt_lock_msg"]                = "|cff2ed884TomoMod|r M+ Tracker: Marco bloqueado.",
    ["tmt_reset_msg"]               = "|cff2ed884TomoMod|r M+ Tracker: Posición reiniciada.",
    ["tmt_unknown_cmd"]             = "|cff2ed884TomoMod|r M+ Tracker: Comando desconocido.",
    ["tmt_key_level"]               = "+%d",
    ["tmt_dungeon_unknown"]         = "Mítico+",
    ["tmt_overtime"]                = "TIEMPO AGOTADO",
    ["tmt_completed_on_time"]       = "COMPLETADO",
    ["tmt_completed_depleted"]      = "FRACASADO",
    ["tmt_forces"]                  = "FUERZAS",
    ["tmt_forces_done"]             = "COMPLETO",
    ["tmt_forces_pct"]              = "%.1f%%",
    ["tmt_forces_count"]            = "%d / %d",
    ["tmt_cfg_title"]               = "Mythic",
    ["tmt_cfg_panel_enable"]         = "Activar tracker M+",
    ["tmt_cfg_show_timer"]          = "Mostrar barra de tiempo",
    ["tmt_cfg_show_forces"]         = "Mostrar fuerzas enemigas",
    ["tmt_cfg_show_bosses"]         = "Mostrar temporizadores de jefe",
    ["tmt_cfg_hide_blizzard"]       = "Ocultar rastreador de Blizzard",
    ["tmt_cfg_lock"]                = "Bloquear marco",
    ["tmt_cfg_scale"]               = "Escala",
    ["tmt_cfg_alpha"]               = "Opacidad de fondo",
    ["tmt_cfg_reset_pos"]           = "Reiniciar posición",
    ["tmt_cfg_preview"]             = "Vista previa",
    ["tmt_cfg_section_display"]     = "Pantalla",
    ["tmt_cfg_section_frame"]       = "Marco",
    ["tmt_cfg_section_actions"]     = "Acciones",
    ["tmt_key_not_available"]       = "no disponible.",
    ["tmt_key_not_in_group"]        = "No estás en un grupo.",
    ["tmt_key_none_found"]          = "No se encontraron piedras angulares.",
    ["tmt_kr_spin"]                 = "|TInterface\\Icons\\INV_Misc_Dice_02:14|t  ¡Girar!",
    ["tmt_preview_active"]          = "|cff2ed884TomoMod|r M+ Tracker: Vista previa activa \226\128\148 |cFF55B400/tmt lock|r para bloquear.",

    -- MythicHub
    ["mhub_title"]                  = "Puntuaci\195\179n M\195\173tica+",
    ["mhub_col_dungeon"]            = "Mazmorra",
    ["mhub_col_level"]              = "Nivel",
    ["mhub_col_rating"]             = "Puntuaci\195\179n",
    ["mhub_col_best"]               = "Mejor",
    ["mhub_tp_click"]               = "Clic para teletransportarte",
    ["mhub_tp_not_available"]        = "Teletransporte no aprendido",
    ["mhub_tp_not_learned"]          = "|cff2ed884TomoMod|r: Hechizo de teletransporte no aprendido.",
    ["mhub_vault_title"]            = "Gran C\195\161mara",
    ["mhub_vault_dungeons"]         = "Mazmorras",
    ["mhub_vault_raids"]            = "Bandas",
    ["mhub_vault_world"]            = "Profundidades",
    ["mhub_vault_ilvl"]             = "Nivel de objeto",
    ["mhub_vault_locked"]           = "Bloqueado",
    ["mhub_vault_claim"]            = "Vuelve a la Gran C\195\161mara para reclamar tu recompensa",

    -- ══════════════════════════════════════════════════════════
    -- INSTALLER
    -- ══════════════════════════════════════════════════════════

    -- Navigation
    ["ins_header_title"]             = "|cff2ed884Tomo|r|cffe4e4e4Mod|r  \226\128\148  Asistente de configuraci\195\179n",
    ["ins_step_counter"]             = "Paso %d / %d",
    ["ins_btn_prev"]                 = "|TInterface\\BUTTONS\\UI-SpellbookIcon-PrevPage:0|t Anterior",
    ["ins_btn_next"]                 = "Siguiente |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t",
    ["ins_btn_finish"]               = "Finalizar |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t",
    ["ins_btn_skip"]                 = "Omitir instalaci\195\179n",

    -- Step 1: Welcome
    ["ins_step1_title"]              = "Bienvenido a TomoMod",
    ["ins_subtitle"]                 = "Suite de interfaz y QOL para The War Within",
    ["ins_welcome_desc"]             = "Este asistente te guiar\195\161 en |cff2ed88416 pasos|r para configurar TomoMod seg\195\186n\ntus preferencias: unit frames, party frames, castbars, nameplates, barras de acci\195\179n,\nrecursos, skins, sonido, Mythic+, QOL, optimizaciones y SkyRide.\n\nTodas estas opciones pueden cambiarse en cualquier momento con |cff2ed884/tm|r.",

    -- Step 2: Profile
    ["ins_step2_title"]              = "Perfil de juego",
    ["ins_profile_info"]             = "Crea un perfil con nombre para guardar tu configuraci\195\179n.",
    ["ins_profile_section"]          = "Nombre del perfil",
    ["ins_profile_placeholder"]      = "Mi perfil",
    ["ins_profile_create"]           = "Crear perfil",
    ["ins_profile_created"]          = "Perfil creado: ",
    ["ins_spec_section"]             = "Asignaci\195\179n de especializaci\195\179n",
    ["ins_spec_info"]                = "Puedes asignar este perfil a tus especializaciones desde el panel Perfiles (/tm).\nCada especializaci\195\179n puede usar una configuraci\195\179n diferente.",

    -- Step 3: Visual Skins
    ["ins_step3_title"]              = "Skins visuales",
    ["ins_skins_info"]               = "Personaliza la interfaz de Blizzard con el tema oscuro de TomoMod.",
    ["ins_skins_section"]            = "Skins disponibles",
    ["ins_skin_gamemenu"]            = "Skin del men\195\186 de juego (Escape)",
    ["ins_skin_actionbar"]           = "Skin de botones de barra de acci\195\179n",
    ["ins_skin_buffs"]               = "Skin de buffs / debuffs",
    ["ins_skin_chat"]                = "Skin del chat",
    ["ins_skin_character"]           = "Skin de la hoja de personaje",
    ["ins_skin_style_section"]       = "Estilo de botones de barra de acci\195\179n",
    ["ins_skin_style"]               = "Estilo visual",

    -- Step 4: Tank Mode
    ["ins_step4_title"]              = "Modo Tank",
    ["ins_tank_info"]                = "En modo tank, las nameplates y UnitFrames muestran\nel estado de amenaza por color para cada enemigo.",
    ["ins_tank_np_section"]          = "Nameplates \226\128\148 Colores de amenaza",
    ["ins_tank_enable_np"]           = "Activar modo tank (nameplates)",
    ["ins_tank_colors_info"]         = "Verde = tienes aggro  \194\183  Naranja = cerca de perderlo  \194\183  Rojo = aggro perdido",
    ["ins_tank_uf_section"]          = "UnitFrames \226\128\148 Indicador de amenaza",
    ["ins_tank_threat_indicator"]    = "Mostrar indicador de amenaza en el objetivo",
    ["ins_tank_threat_text"]         = "Mostrar texto de amenaza % en el objetivo",
    ["ins_tank_cotank_section"]      = "CoTank Tracker",
    ["ins_tank_cotank_enable"]       = "Activar seguimiento del co-tank",
    ["ins_tank_cotank_info"]         = "Muestra la amenaza del segundo tank en instancias.",

    -- Step 5: Nameplates
    ["ins_step5_title"]              = "Nameplates",
    ["ins_np_general"]               = "General",
    ["ins_np_enable"]                = "Activar nameplates de TomoMod",
    ["ins_np_reload_info"]           = "Se necesita un reload para activar/desactivar las nameplates.",
    ["ins_np_display"]               = "Visualizaci\195\179n",
    ["ins_np_class_colors"]          = "Colores de clase",
    ["ins_np_castbar"]               = "Mostrar barra de lanzamiento",
    ["ins_np_health_text"]           = "Mostrar texto de salud (porcentaje)",
    ["ins_np_auras"]                 = "Mostrar auras (debuffs)",
    ["ins_np_role_icons"]            = "Mostrar iconos de rol (mazmorra)",
    ["ins_np_dimensions"]            = "Dimensiones",
    ["ins_np_width"]                 = "Ancho",

    -- Step 6: Action Bars
    ["ins_step6_title"]              = "Barras de acci\195\179n",
    ["ins_ab_system_section"]        = "Action Bar System",
    ["ins_ab_system_info"]           = "TomoMod replaces Blizzard's action bars with custom containers,\npositioning, fade system and display conditions.\nDisable this to fully restore the default Blizzard action bars.",
    ["ins_ab_system_enable"]         = "Enable TomoMod Action Bar system",
    ["ins_ab_system_reload_info"]    = "Requires a /reload to take effect.",
    ["ins_ab_skin_section"]          = "Skin de botones",
    ["ins_ab_enable"]                = "Activar skin en botones de acci\195\179n",
    ["ins_ab_class_color"]           = "Color de borde = color de clase",
    ["ins_ab_shift_reveal"]          = "Mantener Shift para mostrar barras ocultas",
    ["ins_ab_opacity_section"]       = "Opacidad global de barras",
    ["ins_ab_opacity"]               = "Opacidad",
    ["ins_ab_manage_section"]        = "Gesti\195\179n de barras",
    ["ins_ab_manage_info"]           = "Usa el panel Barras de acci\195\179n (/tm |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Barras de acci\195\179n |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Gesti\195\179n)\npara desbloquear y reposicionar cada barra.",

    -- Step 7: LustSound
    ["ins_step7_title"]              = "Sonido \226\128\148 Hero\195\173smo / Sed de sangre",
    ["ins_sound_info"]               = "Reproduce un sonido personalizado cuando Hero\195\173smo o Sed de sangre\nes lanzado por cualquier miembro del grupo.",
    ["ins_sound_activation"]         = "Activaci\195\179n",
    ["ins_sound_enable"]             = "Activar sonido de lust",
    ["ins_sound_choice"]             = "Selecci\195\179n de sonido",
    ["ins_sound_sound"]              = "Sonido",
    ["ins_sound_channel"]            = "Canal de audio",
    ["ins_sound_default"]            = "Por defecto",
    ["ins_sound_preview_section"]    = "Vista previa",
    ["ins_sound_preview_btn"]        = "|TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Vista previa",

    -- Step 8: Mythic+
    ["ins_step8_title"]              = "Mythic+ \226\128\148 Tracker y Tabla de puntuaci\195\179n",
    ["ins_mplus_tracker_section"]    = "M+ Tracker",
    ["ins_mplus_tracker_info"]       = "Muestra un temporizador, fuerzas, jefes y progreso\nde tu mazmorra Mythic+ en tiempo real.",
    ["ins_mplus_tracker_enable"]     = "Activar M+ Tracker",
    ["ins_mplus_show_timer"]         = "Mostrar temporizador",
    ["ins_mplus_show_forces"]        = "Mostrar fuerzas (%)",
    ["ins_mplus_hide_blizzard"]      = "Ocultar interfaz Blizzard en Mythic+",
    ["ins_mplus_score_section"]      = "TomoScore \226\128\148 Tabla de puntuaci\195\179n",
    ["ins_mplus_score_info"]         = "Muestra puntuaciones personales y de grupo al final de un Mythic+.",
    ["ins_mplus_score_enable"]       = "Activar TomoScore",
    ["ins_mplus_score_auto"]         = "Mostrar autom\195\161ticamente en M+",

    -- Step 9: CVars
    ["ins_step9_title"]              = "Optimizaciones del sistema (CVars)",
    ["ins_cvar_info"]                = "TomoMod puede aplicar un conjunto de CVars de WoW recomendadas\npara mejorar el rendimiento y la capacidad de respuesta.",
    ["ins_cvar_section"]             = "Optimizaciones incluidas",
    ["ins_cvar_opt1"]                = "Reducir el Level of Detail (LOD) innecesario",
    ["ins_cvar_opt2"]                = "Optimizar el frustum culling",
    ["ins_cvar_opt3"]                = "Desactivar el temporal AA excesivo",
    ["ins_cvar_opt4"]                = "Mejorar la capacidad de respuesta de red",
    ["ins_cvar_opt5"]                = "Desactivar animaciones de interfaz innecesarias",
    ["ins_cvar_opt6"]                = "Optimizar el streaming de texturas",
    ["ins_cvar_success"]             = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t  \194\161CVars aplicadas con \195\169xito!",
    ["ins_cvar_apply_btn"]           = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0|t Aplicar todas las CVars",
    ["ins_cvar_applied"]             = "CVars optimizadas aplicadas.",

    -- Step 10: QOL
    ["ins_step10_title"]             = "Calidad de vida (QOL)",
    ["ins_qol_info"]                 = "Activa los m\195\179dulos QOL que desees.\nTodos son accesibles por separado en /tm |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t QOL.",
    ["ins_qol_auto_section"]         = "Automatizaciones",
    ["ins_qol_auto_repair"]          = "Reparar autom\195\161ticamente en el comerciante",
    ["ins_qol_fast_loot"]            = "Saqueo r\195\161pido (recogida r\195\161pida de objetos)",
    ["ins_qol_skip_cinematics"]      = "Omitir cinem\195\161ticas ya vistas",
    ["ins_qol_hide_talking_head"]    = "Ocultar Talking Head (di\195\161logos de desplazamiento)",
    ["ins_qol_auto_accept"]          = "Aceptar inv. de grupo autom\195\161ticamente (amigos y hermandad)",
    ["ins_qol_tooltip_ids"]          = "Mostrar IDs en tooltips (spell ID, item ID...)",
    ["ins_qol_combat_section"]       = "Combate",
    ["ins_qol_combat_text"]          = "Texto flotante de combate personalizado",
    ["ins_qol_hide_castbar"]         = "Ocultar barra de lanzamiento de Blizzard (usar la de TomoMod)",

    -- Step 11: SkyRide
    ["ins_step11_title"]             = "SkyRide \226\128\148 Barra de cabalgata drac\195\179nica",
    ["ins_skyride_info"]             = "SkyRide muestra una barra de Vigor (6 cargas) y una barra\nde Segundo Aliento (3 cargas) para la cabalgata drac\195\179nica.",
    ["ins_skyride_activation"]       = "Activaci\195\179n",
    ["ins_skyride_enable"]           = "Activar barra SkyRide",
    ["ins_skyride_auto_info"]        = "La barra aparece autom\195\161ticamente en modo de vuelo drac\195\179nico\ny se oculta fuera de \195\169l.",
    ["ins_skyride_dimensions"]       = "Dimensiones",
    ["ins_skyride_width"]            = "Ancho",
    ["ins_skyride_height"]           = "Altura",
    ["ins_skyride_reset_section"]    = "Reiniciar posici\195\179n",
    ["ins_skyride_reset_btn"]        = "Reiniciar posici\195\179n",

    -- Step 12: Done
    ["ins_step12_title"]             = "\194\161Configuraci\195\179n completada!",
    ["ins_done_check"]               = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t  \194\161Todo listo!",
    ["ins_done_recap"]               = "Tu configuraci\195\179n de TomoMod est\195\161 guardada. Algunos recordatorios:\n\n|cff2ed884/tm|r              |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Abrir el panel de configuraci\195\179n\n|cff2ed884/tm sr|r           |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Desbloquear y mover elementos\n|cff2ed884/tm install|r      |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Relanzar este instalador\n\nTodas las opciones configuradas aqu\195\173 pueden cambiarse en cualquier momento\ndesde los paneles correspondientes en la GUI de TomoMod.\n\nSe necesita un |cff2ed884reload de la UI|r para aplicar ciertos cambios\n(nameplates, skins, UnitFrames).",
    ["ins_done_reload"]              = "|TInterface\\BUTTONS\\UI-RefreshButton:0|t  Recargar UI",

    -- Step NEW: Unit Frames
    ["ins_uf_title"]                 = "Unit Frames",
    ["ins_uf_info"]                  = "TomoMod reemplaza los marcos de unidad predeterminados de Blizzard (jugador, objetivo, foco, mascota)\ncon marcos modernos y personalizables.",
    ["ins_uf_section"]               = "General",
    ["ins_uf_enable"]                = "Activar UnitFrames de TomoMod",
    ["ins_uf_hide_blizzard"]         = "Ocultar marcos predeterminados de Blizzard",
    ["ins_uf_reload_info"]           = "Se necesita un reload para aplicar cambios a los UnitFrames.",

    -- Step NEW: Party Frames
    ["ins_pf_title"]                 = "Party Frames",
    ["ins_pf_info"]                  = "Marcos de grupo personalizados con iconos de rol, resaltado de disipaci\195\179n\ny seguimiento de cooldowns para juego en grupo.",
    ["ins_pf_section"]               = "General",
    ["ins_pf_enable"]                = "Activar Party Frames de TomoMod",
    ["ins_pf_hide_blizzard"]         = "Ocultar Party Frames de Blizzard",
    ["ins_pf_cd_section"]            = "Rastreadores de cooldown",
    ["ins_pf_cd_info"]               = "Rastrea los cooldowns de interrupci\195\179n y resurrecci\195\179n de combate\nde tus compa\195\177eros directamente en sus marcos de grupo.",
    ["ins_pf_show_interrupt"]        = "Mostrar rastreador de cooldown de interrupci\195\179n",
    ["ins_pf_show_brez"]             = "Mostrar rastreador de cooldown de resurrecci\195\179n de combate",
    ["ins_pf_reload_info"]           = "Se necesita un reload para aplicar cambios a los Party Frames.",

    -- Step 5: Raid Frames
    ["ins_rf_title"]                 = "Raid Frames",
    ["ins_rf_info"]                  = "Custom raid frames for groups of 6-40 players.\nGrid or list layout with dispel highlights, HoT tracking, and debuff icons.",
    ["ins_rf_section"]               = "General",
    ["ins_rf_enable"]                = "Enable TomoMod raid frames",
    ["ins_rf_hide_blizzard"]         = "Hide Blizzard raid frames",
    ["ins_rf_features_section"]      = "Features",
    ["ins_rf_show_dispel"]           = "Dispel highlight (border glow by debuff type)",
    ["ins_rf_show_hots"]             = "HoT tracking (healer spell indicators)",
    ["ins_rf_show_debuffs"]          = "Show debuff icons on raid members",
    ["ins_rf_show_defensives"]       = "Show defensive cooldown icons",
    ["ins_rf_layout_section"]        = "Layout",
    ["ins_rf_layout"]                = "Raid layout mode",
    ["ins_rf_reload_info"]           = "A reload is required to apply changes to raid frames.",

    -- Step NEW: Castbars
    ["ins_cb_title"]                 = "Barras de lanzamiento",
    ["ins_cb_info"]                  = "Barras de lanzamiento personalizadas para jugador, objetivo, foco y mascota\ncon animaci\195\179n de chispa y feedback de interrupci\195\179n.",
    ["ins_cb_section"]               = "General",
    ["ins_cb_enable"]                = "Activar castbars de TomoMod",
    ["ins_cb_hide_blizzard"]         = "Ocultar castbar predeterminada de Blizzard",
    ["ins_cb_class_color"]           = "Usar color de clase para el relleno",
    ["ins_cb_reload_info"]           = "Se necesita un reload para aplicar cambios a las castbars.",

    -- Step NEW: Resource Bars & Cooldown Manager
    ["ins_res_title"]                = "Recursos y Cooldowns",
    ["ins_res_info"]                 = "Visualizaci\195\179n de poder de clase (puntos de combo, runas, fragmentos de alma, etc.)\nen modo icono o barra.",
    ["ins_res_section"]              = "Barras de recursos",
    ["ins_res_enable"]               = "Activar barras de recursos",
    ["ins_res_display"]              = "Modo de visualizaci\195\179n",
    ["ins_cdm_section"]              = "Gestor de cooldowns",
    ["ins_cdm_info"]                 = "Espiral de cooldown en botones de acci\195\179n con\nalfa adaptativo al combate y filtrado de GCD.",
    ["ins_cdm_enable"]               = "Activar gestor de cooldowns",
    ["ins_cdm_hide_gcd"]             = "Ocultar espiral de GCD",
    ["ins_cdm_desat"]                = "Desaturar botones en cooldown",

    -- Enhanced Skins
    ["ins_skin_bag"]                 = "Skin de bolsas",
    ["ins_skin_tooltip"]             = "Skin de tooltips",
    ["ins_skin_objective"]           = "Objective Tracker skin (color-coded quest types)",
    ["ins_skin_mail"]                = "Mail skin",
    ["ins_skin_reputation"]          = "Reputation bar",

    -- Enhanced QOL
    ["ins_qol_interface_section"]    = "Interfaz",
    ["ins_qol_minimap"]              = "Minimapa personalizado (borde y escala)",
    ["ins_qol_cursor"]               = "Anillo de cursor luminoso",
    ["ins_qol_afk"]                  = "Pantalla AFK personalizada con modelo 3D",
    ["ins_qol_diag"]                 = "Diagn\195\179sticos (captura de errores sin popups)",
    ["ins_qol_aura_tracker"]         = "Rastreador de auras (trinkets, buffs, defensivos)",
    ["ins_qol_auto_summon"]          = "Auto-accept summons",
    ["ins_qol_auto_fill_delete"]     = "Auto-fill DELETE in destroy popups",
    ["ins_qol_auto_quest"]           = "Auto accept/turn in quests (Shift to override)",
    ["ins_qol_class_reminder"]       = "Class buff reminder (Fortitude, Intellect, etc.)",
    ["ins_qol_leveling_bar"]         = "Leveling bar (XP/hour, rested XP overlay)",
    ["ins_qol_waypoint"]             = "Waypoint navigation system",
    ["ins_qol_world_quest_tab"]      = "World Quest browser on World Map",
    ["ins_qol_frame_anchors"]        = "Movable frame anchors (Alert, Loot)",
    ["ins_qol_profession_helper"]    = "Profession Helper (batch disenchant)",

    -- =========== Config Panels — i18n ===========
    -- ActionBars panel
    ["opt_abs_style"]                = "Estilo visual",
    ["section_bar_opacity"]          = "Opacidad por barra",
    ["opt_abs_bar_select"]           = "Barra a configurar",
    ["opt_abs_opacity"]              = "Opacidad",
    ["btn_abs_apply_all"]            = "Aplicar a todas las barras",
    ["opt_abs_combat_only_label"]    = "Mostrar solo en combate:",
    ["opt_abs_combat_only"]          = "Barra visible solo en combate",
    ["section_bar_management"]       = "Gesti\195\179n de barras de acci\195\179n",
    ["btn_abs_unlock"]               = "Desbloquear barras",
    ["info_abs_unlock"]              = "Desbloquea las barras para mostrar los controles de arrastre.\nHaz clic derecho en un control para configurar una barra individualmente.",
    ["section_bar_quick"]            = "Ajustes r\195\161pidos",
    ["tab_abs_skin"]                 = "Skin de botones",
    ["tab_abs_bars"]                 = "Gesti\195\179n de barras",
    -- General panel
    ["btn_relaunch_installer"]       = "Relanzar instalador",
    ["info_relaunch_installer"]      = "Inicia el asistente de configuraci\195\179n de 16 pasos.",
    -- Sound panel
    ["section_sound_preview"]        = "Vista previa y opciones",
    -- UFPreview
    ["preview_header"]               = "VISTA PREVIA EN VIVO",
    ["preview_player"]               = "Jugador",
    ["preview_target_name"]          = "Taurache",
    ["preview_focus_name"]           = "Sacerdotisa",
    ["preview_pet_name"]             = "Lobo de agua",
    ["preview_tot_name"]             = "Objetivo-del-objetivo",
    ["preview_cast_player"]          = "Descarga de Escarcha",
    ["preview_cast_target"]          = "Bola de Fuego",
    ["preview_lbl_player"]           = "JUGADOR",
    ["preview_lbl_target"]           = "OBJETIVO",
    ["preview_lbl_focus"]            = "FOCO",
    ["preview_lbl_pet"]              = "MASCOTA",
    ["preview_lbl_tot"]              = "TOT",
    ["preview_click_nav"]            = "clic para navegar",
    ["preview_click_isolate"]         = "clic para aislar",
    ["preview_click_show_all"]        = "clic para mostrar todo",
    ["preview_show_all"]              = "Mostrar todo",
    -- ConfigUI footer
    ["ui_footer_hint"]               = "/tm  \194\183  /tm sr para mover elementos",

    -- =====================
    -- SKINS CATEGORY (top-level)
    -- =====================
    ["cat_skins"]                        = "Skins",

    -- Chat Frame V2 — etiquetas de pesta\195\177as e interfaz
    ["chatv2_tab_general"]               = "General",
    ["chatv2_tab_instance"]              = "Instancia",
    ["chatv2_tab_chucho"]                = "Chucho",
    ["chatv2_tab_personnel"]             = "Personal",
    ["chatv2_tab_combat"]                = "Combate",
    ["chatv2_sidebar_title"]             = "CHAT",
    ["chatv2_expand_btn"]                = "Chat",
    ["chatv2_mover_label"]               = "Ventana de chat V2",
    ["chatv2_input_hint"]                = "Pulsa Intro para escribir...",

    -- Skins > Chat Frame tab
    ["tab_skin_chatframe"]               = "Ventana de chat",
    ["section_skin_chatframe"]           = "Skin de ventana de chat",
    ["info_skin_chatframe_desc"]         = "Panel de chat con barra lateral \226\128\148 General, Instancia, Chucho, Personal, Combate \226\128\148 con emblemas de no le\195\173dos e indicadores de pin.",
    ["opt_skin_chatframe_enable"]        = "Activar skin de chat",
    ["opt_skin_chatframe_width"]         = "Ancho",
    ["opt_skin_chatframe_height"]        = "Alto",
    ["opt_skin_chatframe_scale"]         = "Escala %",
    ["opt_skin_chatframe_opacity"]       = "Opacidad del fondo",
    ["opt_skin_chatframe_font_size"]     = "Tama\195\177o de fuente",
    ["opt_skin_chatframe_timestamp"]     = "Mostrar marca de tiempo",

    -- Skins > Bags tab
    ["tab_skin_bags"]                    = "Bolsas",
    ["section_skin_bags"]                = "Skin de bolsas",
    ["info_skin_bags_desc"]              = "Bolsas por categor\195\173a inspirada en BetterBags. Objetos agrupados en secciones plegables con bordes de calidad, b\195\186squeda, enfriamientos y nivel de objeto.",
    ["opt_skin_bags_enable"]             = "Activar skin de bolsas",
    -- Bolsas — Desencantar
    ["bagskin_de_badge"]                 = "DE",
    ["bagskin_de_tooltip"]               = "|cff2ed884[Clic derecho]|r Desencantar",
    ["bagskin_currencies_none"]          = "Sin divisas seguidas (clic derecho en una divisa \226\134\146 Mostrar en la mochila)",
    ["opt_skin_bags_stack_merge"]        = "Fusionar pilas id\195\169nticas",
    ["opt_skin_bags_show_empty"]         = "Mostrar secci\195\179n de ranuras libres",
    ["opt_skin_bags_show_recent"]        = "Mostrar secci\195\179n de objetos recientes",
    ["opt_skin_bags_columns"]            = "Columnas",
    ["opt_skin_bags_slot_size"]          = "Tama\195\177o de ranura",
    ["opt_skin_bags_slot_spacing"]       = "Espaciado de ranuras",
    ["opt_skin_bags_scale"]              = "Escala %",
    ["opt_skin_bags_opacity"]            = "Opacidad del fondo",
    ["opt_skin_bags_quality_borders"]    = "Mostrar bordes de calidad",
    ["opt_skin_bags_cooldowns"]          = "Mostrar enfriamientos",
    ["opt_skin_bags_quantity"]           = "Mostrar distintivos de cantidad",
    ["opt_skin_bags_search"]             = "Mostrar barra de b\195\186squeda",
    ["opt_skin_bags_sort_mode"]          = "Modo de orden",
    ["opt_skin_bags_sort_quality"]       = "Calidad",
    ["opt_skin_bags_sort_name"]          = "Nombre",
    ["opt_skin_bags_sort_type"]          = "Tipo",
    ["opt_skin_bags_sort_ilvl"]          = "Nivel de objeto",
    ["opt_skin_bags_sort_recent"]        = "Reciente",
    ["opt_skin_bags_show_gold"]          = "Mostrar oro (pie de p\195\161gina)",
    ["opt_skin_bags_show_currencies"]    = "Mostrar divisas seguidas (pie de p\195\161gina)",
    ["bagskin_cat_recent"]               = "Objetos recientes",
    ["bagskin_cat_equipment"]            = "Equipamiento",
    ["bagskin_cat_consumables"]          = "Consumibles",
    ["bagskin_cat_quest"]                = "Objetos de misi\195\179n",
    ["bagskin_cat_tradegoods"]           = "Bienes comerciales",
    ["bagskin_cat_reagents"]             = "Reactivos",
    ["bagskin_cat_gems"]                 = "Gemas y mejoras",
    ["bagskin_cat_recipes"]              = "Recetas",
    ["bagskin_cat_pets"]                 = "Mascotas de combate",
    ["bagskin_cat_junk"]                 = "Basura",
    ["bagskin_cat_misc"]                 = "Varios",
    ["bagskin_cat_free"]                 = "Ranuras libres",

    -- Skins > Objective Tracker tab
    ["tab_skin_objtracker"]              = "Rastreador",

    -- Skins > Character tab
    ["tab_skin_character"]               = "Personaje",

    -- Skins > Buffs tab
    ["tab_skin_buffs"]                   = "Buffs",

    -- Skins > Game Menu tab
    ["tab_skin_gamemenu"]                = "Men\195\186 de juego",

    -- Skins > Mail tab
    ["tab_skin_mail"]                    = "Correo",

    -- =====================
    -- MÓDULO WAYPOINT (/tm way)
    -- =====================
    -- GUI
    ["tab_qol_waypoint"]                  = "Marcador",
    ["section_waypoint"]                  = "Marcador",
    ["opt_way_zone_only"]                 = "Mostrar solo en la zona actual",
    ["opt_way_size"]                      = "Tamaño del marcador",
    ["opt_way_shape"]                     = "Forma",
    ["way_shape_ring"]                    = "Anillo",
    ["way_shape_arrow"]                   = "Flecha",
    ["opt_way_color"]                     = "Color del marcador",
    -- Slash
    ["msg_help_way"]                     = "Colocar un marcador en tu posición actual",
    ["msg_help_way_coords"]              = "Colocar un marcador en las coordenadas (x, y)",
    ["msg_help_way_clear"]               = "Eliminar el marcador activo",
    ["way_cleared"]                      = "Marcador eliminado.",
    ["way_set"]                          = "Marcador establecido en %s%s.",
    ["way_here"]                         = "Marcador colocado en la posición actual.",
    ["way_no_map"]                       = "No se puede determinar el mapa actual.",
    ["way_no_pos"]                       = "No se puede determinar la posición del jugador.",
    ["way_bad_map"]                      = "No se puede colocar un marcador en este mapa.",
    ["way_bad_coords"]                   = "Las coordenadas deben estar entre 0 y 100.",
    ["way_usage"]                        = "Uso: /tm way [mapID] x y [nombre]  |  /tm way clear",

    -- =====================
    -- Resource names
    -- =====================
    ["res_mana"]                        = "Maná (Druida)",
    ["res_soul_shards"]                 = "Fragmentos de alma",
    ["res_holy_power"]                  = "Poder sagrado",
    ["res_chi"]                         = "Chi",
    ["res_combo_points"]                = "Puntos de combo",
    ["res_arcane_charges"]              = "Cargas arcanas",
    ["res_essence"]                     = "Esencia",
    ["res_stagger"]                     = "Tambaleo",
    ["res_soul_fragments"]              = "Fragmentos de alma",
    ["res_tip_of_spear"]                = "Punta de la lanza",
    ["res_maelstrom_weapon"]            = "Arma de Maelström",
    ["res_icicles"]                      = "Carámbanos",

    -- =====================
    -- Resource Bars display mode
    -- =====================
    ["opt_rb_display_mode"]             = "Modo de visualización",
    ["display_mode_icons"]              = "Iconos (texturas TUI)",
    ["display_mode_bars"]               = "Barras (colores planos)",

    -- =====================
    -- Tooltip Skin
    -- =====================
    ["tab_skin_tooltip"]                 = "Tooltip",
    ["section_tooltip_skin"]             = "Skin de Tooltip",
    ["opt_tooltip_skin_enable"]          = "Activar skin de tooltip",
    ["info_tooltip_skin_reload"]         = "Algunos cambios requieren pasar el cursor sobre un nuevo objetivo.",
    ["opt_tooltip_bg_alpha"]             = "Opacidad del fondo",
    ["opt_tooltip_border_alpha"]         = "Opacidad del borde",
    ["opt_tooltip_bg_color"]              = "Color de fondo",
    ["opt_tooltip_border_color"]          = "Color del borde",
    ["opt_tooltip_font_size"]             = "Tamaño de fuente",
    ["opt_tooltip_hide_healthbar"]       = "Ocultar barra de vida",
    ["opt_tooltip_class_color"]          = "Nombres de jugador con color de clase",
    ["opt_tooltip_hide_server"]          = "Ocultar servidor en nombres de jugador",
    ["opt_tooltip_hide_title"]           = "Ocultar título en nombres de jugador",
    ["opt_tooltip_guild_color"]          = "Color personalizado de nombre de hermandad",
    ["opt_tooltip_guild_color_pick"]     = "Color de nombre de hermandad",

    -- =====================
    -- Bag Skin extras
    -- =====================
    ["opt_skin_bags_show_ilvl"]          = "Mostrar nivel de objeto en equipo",
    ["opt_skin_bags_show_junk_icon"]     = "Mostrar icono de basura",
    ["opt_skin_bags_layout_mode"]        = "Modo de disposición",
    ["opt_skin_bags_layout_combined"]    = "Cuadrícula combinada",
    ["opt_skin_bags_layout_categories"]  = "Categorías",
    ["opt_skin_bags_layout_separate"]    = "Bolsas separadas",
    ["opt_skin_bags_reverse_order"]      = "Invertir orden de bolsas",
    ["opt_skin_bags_show_bag_bar"]       = "Mostrar barra de bolsas",
    ["opt_skin_bags_settings"]           = "Ajustes de bolsas",
    ["opt_skin_bags_slot_spacing_x"]     = "Espaciado de ranuras X",
    ["opt_skin_bags_slot_spacing_y"]     = "Espaciado de ranuras Y",
    ["opt_skin_bags_sort_none"]          = "Manual",

    -- =====================
    -- TOMOSCORE (Scoreboard)
    -- =====================
    ["ts_cfg_title"]                = "Marcador",
    ["ts_cfg_enable"]               = "Activar marcador de mazmorra",
    ["ts_cfg_auto_show_mplus"]      = "Mostrar automáticamente en M+",
    ["ts_cfg_scale"]                = "Escala",
    ["ts_cfg_alpha"]                = "Opacidad del fondo",
    ["ts_cfg_section_display"]      = "Visualización",
    ["ts_cfg_section_frame"]        = "Marco",
    ["ts_cfg_section_actions"]      = "Acciones",
    ["ts_cfg_preview"]              = "Vista previa",
    ["ts_cfg_last_run"]             = "Mostrar última partida",
    ["ts_cfg_reset_pos"]            = "Reiniciar posición",
    ["ts_reset_msg"]                = "|cff2ed884TomoMod|r Marcador: Posición reiniciada.",
    ["ts_no_data"]                  = "|cff2ed884TomoMod|r Marcador: No hay datos de mazmorra disponibles.",
    ["ts_mythic_zero"]              = "Mítica",
    ["ts_key_level"]                = "+%d",
    ["ts_completed"]                = "COMPLETADO",
    ["ts_depleted"]                 = "AGOTADO",
    ["ts_duration"]                 = "Duración",
    ["ts_col_player"]               = "Jugador",
    ["ts_col_rating"]               = "M+",
    ["ts_col_key_level"]            = "Llave",
    ["ts_col_key_name"]             = "Mazmorra",
    ["ts_col_damage"]               = "Daño",
    ["ts_col_healing"]              = "Sanación",
    ["ts_col_interrupts"]           = "Interrupciones",
    ["ts_footer_total"]             = "Total",
    ["ts_footer_players"]           = "%d jugadores",

    -- =====================
    -- CASTBARS (módulo independiente)
    -- =====================
    ["cat_castbars"]                     = "Barras de lanzamiento",

    ["cb_section_general"]               = "General",
    ["opt_cb_enable"]                    = "Activar barras de lanzamiento independientes",
    ["info_cb_description"]              = "Reemplaza las barras de lanzamiento de Blizzard con barras totalmente personalizables para Jugador, Objetivo, Foco, Mascota y Jefe.",
    ["btn_cb_toggle_preview"]            = "Show / Hide Preview",
    ["info_cb_preview_hint"]             = "Unlocks every castbar and shows a live mock spell so you can see your tweaks instantly.",
    ["opt_cb_hide_blizzard"]             = "Ocultar barras de lanzamiento de Blizzard",
    ["opt_cb_class_color"]               = "Usar color de clase",
    ["opt_cb_show_transitions"]          = "Animaciones de inicio/fin",
    ["opt_cb_show_channel_ticks"]        = "Mostrar marcas de canalización",
    ["opt_cb_timer_format"]              = "Formato del temporizador",
    ["cb_timer_remaining"]               = "Restante (1.5)",
    ["cb_timer_remaining_total"]         = "Restante / Total (1.5 / 3.0)",
    ["cb_timer_elapsed"]                 = "Transcurrido (1.5)",
    ["opt_cb_spell_max_len"]             = "Largo máx. del nombre (0 = sin límite)",

    ["cb_section_appearance"]            = "Apariencia",
    ["opt_cb_bar_texture"]               = "Textura de la barra",
    ["cb_tex_blizzard"]                  = "Blizzard",
    ["cb_tex_smooth"]                    = "Suave",
    ["cb_tex_flat"]                      = "Plano",
    ["opt_cb_font_size"]                 = "Tamaño de fuente",
    ["opt_cb_bg_mode"]                   = "Modo de fondo",
    ["cb_bg_black"]                      = "Negro",
    ["cb_bg_transparent"]                = "Transparente",
    ["cb_bg_custom"]                     = "Textura personalizada",

    ["cb_section_colors"]                = "Colores",
    ["opt_cb_cast_color"]                = "Color de lanzamiento",
    ["opt_cb_ni_color"]                  = "No interrumpible",
    ["opt_cb_interrupt_color"]           = "Color de interrupción",

    ["cb_section_spark"]                 = "Chispa",
    ["opt_cb_show_spark"]                = "Mostrar animación de chispa",
    ["opt_cb_spark_style"]               = "Estilo de chispa",
    ["opt_cb_spark_color"]               = "Color de chispa",
    ["opt_cb_spark_glow_color"]          = "Color de brillo",
    ["opt_cb_spark_tail_color"]          = "Color de estela",
    ["opt_cb_spark_glow_alpha"]          = "Opacidad del brillo",
    ["opt_cb_spark_tail_alpha"]          = "Opacidad de estela",

    ["cb_section_gcd"]                   = "Chispa GCD",
    ["opt_cb_show_gcd"]                  = "Mostrar barra GCD bajo la barra del jugador",
    ["opt_cb_gcd_height"]                = "Altura de la barra GCD",
    ["opt_cb_gcd_color"]                 = "Color GCD",

    ["cb_section_interrupt"]             = "Retroalimentación de interrupción",
    ["opt_cb_show_interrupt_feedback"]   = "Mostrar texto de interrupción",
    ["opt_cb_interrupt_fb_color"]        = "Color del texto",
    ["opt_cb_interrupt_fb_size"]         = "Tamaño de fuente",
    ["cb_interrupt_feedback_text"]       = "¡INTERRUMPIDO!",
    ["cb_interrupt_feedback_full"]       = "INTERRUMPIDO: %s",
    ["cb_interrupted"]                   = "Interrumpido",

    ["cb_tab_general"]                   = "General",
    ["cb_tab_player"]                    = "Jugador",
    ["cb_tab_target"]                    = "Objetivo",
    ["cb_tab_focus"]                     = "Foco",
    ["cb_tab_pet"]                       = "Mascota",
    ["cb_tab_boss"]                      = "Jefe",

    ["cb_section_unit"]                  = "Barra de %s",
    ["opt_cb_unit_enable"]               = "Activar",
    ["opt_cb_unit_width"]                = "Ancho",
    ["opt_cb_unit_height"]               = "Alto",
    ["opt_cb_unit_show_icon"]            = "Mostrar icono",
    ["opt_cb_unit_icon_side"]            = "Lado del icono",
    ["cb_icon_left"]                     = "Izquierda",
    ["cb_icon_right"]                    = "Derecha",
    ["opt_cb_unit_show_timer"]           = "Mostrar temporizador",
    ["opt_cb_unit_show_latency"]         = "Mostrar latencia",
    ["info_cb_latency"]                  = "Muestra una capa oscura con la latencia de red al final de la barra.",
    ["info_cb_position"]                 = "Usa /tm layout para desbloquear y arrastrar esta barra.",
    ["btn_cb_reset_position"]            = "Restablecer posición",
    ["cb_move_label"]                    = "(Arrastra para mover)",
    ["cb_preview_castbar"]               = "Vista previa: %s",

    ["mover_castbar_standalone"]         = "Barras de lanzamiento",

    -- ═══════════════════════════════════
    -- Marcos de grupo (Party Frames)
    -- ═══════════════════════════════════
    ["cat_partyframes"]                  = "Marcos de grupo",
    ["mover_partyframes"]                = "Marcos de grupo",

    ["pf_tab_general"]                   = "General",
    ["pf_tab_features"]                  = "Funciones",
    ["pf_tab_cooldowns"]                 = "Enfriamientos",
    ["pf_tab_arena"]                     = "Arena",

    ["pf_section_general"]               = "General",
    ["pf_opt_enable"]                    = "Activar marcos de grupo",
    ["pf_info_description"]              = "Marcos de grupo personalizados para M+ y Arena con salud, absorción, predicción de curación, HoTs, CD de interrupción/rez de combate y resaltado de disipación.",
    ["pf_opt_hide_blizzard"]             = "Ocultar marcos de grupo de Blizzard",
    ["pf_opt_sort_role"]                 = "Ordenar por rol (Tanque > Sanador > DPS)",

    ["pf_section_dimensions"]            = "Dimensiones",
    ["pf_opt_width"]                     = "Ancho del marco",
    ["pf_opt_height"]                    = "Alto del marco",
    ["pf_opt_spacing"]                   = "Espaciado",
    ["pf_opt_grow_direction"]            = "Dirección de crecimiento",
    ["pf_dir_down"]                      = "Abajo",
    ["pf_dir_up"]                        = "Arriba",
    ["pf_dir_right"]                     = "Derecha",
    ["pf_dir_left"]                      = "Izquierda",

    ["pf_section_display"]               = "Visualización",
    ["pf_opt_show_name"]                 = "Mostrar nombre",
    ["pf_opt_show_health_text"]          = "Mostrar texto de salud",
    ["pf_opt_health_format"]             = "Formato de salud",
    ["pf_fmt_deficit"]                   = "Déficit",
    ["pf_opt_health_color"]              = "Modo de color de salud",
    ["pf_color_green"]                   = "Verde",
    ["pf_color_gradient"]                = "Degradado",
    ["pf_opt_show_power"]                = "Mostrar barra de poder",
    ["pf_opt_power_height"]              = "Altura de barra de poder",
    ["pf_opt_show_role"]                 = "Mostrar icono de rol",
    ["pf_opt_role_size"]                 = "Tamaño del icono de rol",
    ["pf_opt_show_marker"]               = "Mostrar marca de banda",
    ["pf_opt_readycheck_size"]            = "Tamaño del icono de preparación",
    ["pf_opt_summon_size"]               = "Tamaño del indicador de invocación",

    ["pf_section_font"]                  = "Fuente",
    ["pf_opt_font_size"]                 = "Tamaño de fuente",

    ["pf_section_position"]              = "Posición",
    ["pf_info_position"]                 = "Usa /tm layout para desbloquear y arrastrar los marcos de grupo.",
    ["pf_btn_reset_position"]            = "Restablecer posición",

    ["pf_section_health_extras"]         = "Extras de salud",
    ["pf_opt_show_absorb"]               = "Mostrar barra de absorción",
    ["pf_opt_absorb_color"]              = "Color de absorción",
    ["pf_opt_show_heal_pred"]            = "Mostrar predicción de curación",

    ["pf_section_range"]                 = "Comprobación de rango",
    ["pf_opt_show_range"]                = "Atenuar miembros fuera de rango",
    ["pf_opt_oor_alpha"]                 = "Opacidad fuera de rango",

    ["pf_section_dispel"]                = "Resaltado de disipación",
    ["pf_opt_show_dispel"]               = "Resaltar debuffs disipables",
    ["pf_info_dispel"]                   = "Brillo del borde por tipo de debuff: Magia (azul), Maldición (morado), Enfermedad (marrón), Veneno (verde).",

    ["pf_section_hots"]                  = "Rastreo de HoTs",
    ["pf_opt_show_hots"]                 = "Mostrar indicadores de HoT",
    ["pf_opt_hot_size"]                  = "Tamaño de icono HoT",
    ["pf_opt_max_hots"]                  = "Max. HoTs mostrados",
    ["pf_info_hots"]                     = "Muestra efectos de curación con el tiempo con bordes de color de clase. Compatible con Sacerdote, Druida, Paladín, Chamán, Monje y Evocador.",

    ["pf_section_cooldowns"]             = "Rastreador de enfriamiento",
    ["pf_opt_show_kick"]                 = "Mostrar CD de interrupción",
    ["pf_opt_show_brez"]                 = "Mostrar CD de rez de combate",
    ["pf_opt_cd_size"]                   = "Tamaño del icono CD",
    ["pf_opt_cd_layout"]                 = "Disposición de iconos CD",
    ["pf_cd_vertical"]                   = "Vertical (sobre marco)",
    ["pf_cd_horizontal"]                 = "Horizontal (debajo)",
    ["pf_info_cooldowns"]                = "Las interrupciones se detectan mediante UNIT_SPELLCAST_SUCCEEDED. El rez de combate lee el pool de cargas compartido, por lo que el icono se apaga para todos cuando se usa un rez en la instancia.",

    -- Indicador de resurrección (grupo)
    ["pf_section_resurrect"]             = "Indicador de resurrección",
    ["pf_opt_show_resurrect"]            = "Mostrar icono de resurrección entrante",
    ["pf_opt_resurrect_size"]            = "Tamaño del icono de resurrección",
    ["pf_info_resurrect"]                = "Muestra un icono de rez en un miembro mientras se está lanzando una resurrección sobre él.",

    ["pf_section_arena"]                 = "Marcos de enemigos de arena",
    ["pf_opt_arena_enable"]              = "Activar marcos de arena",
    ["pf_info_arena"]                    = "Muestra salud, poder y CD de abalorio PvP del equipo enemigo en Arena (2v2/3v3).",
    ["pf_section_arena_dims"]            = "Dimensiones de arena",
    ["pf_opt_arena_width"]               = "Ancho",
    ["pf_opt_arena_height"]              = "Alto",
    ["pf_opt_arena_spacing"]             = "Espaciado",
    ["pf_section_arena_trinket"]         = "Abalorio PvP",
    ["pf_opt_show_trinket"]              = "Mostrar CD de abalorio",
    ["pf_opt_trinket_size"]              = "Tamaño del icono de abalorio",
    ["pf_opt_show_spec"]                 = "Mostrar icono de especialización",
    ["pf_section_arena_pos"]             = "Posición de arena",
    ["pf_info_arena_pos"]                = "Usa /tm layout para desbloquear y arrastrar los marcos de arena.",
    ["pf_btn_reset_arena_pos"]           = "Restablecer posición",

    -- ═══════════════════════════════════
    -- Raid Frames
    -- ═══════════════════════════════════
    ["cat_raidframes"]                   = "Marcos de banda",
    ["mover_raidframes"]                 = "Marcos de banda",
    ["rf_tab_general"]                   = "General",
    ["rf_tab_features"]                  = "Funciones",
    ["rf_section_general"]               = "General",
    ["rf_opt_enable"]                    = "Activar marcos de banda",
    ["rf_info_description"]              = "Marcos de banda personalizados con salud, absorción, predicción de curación, HoTs, debuffs, resaltado de disipación, CDs defensivos y verificación de rango.",
    ["rf_opt_hide_blizzard"]             = "Ocultar marcos de banda de Blizzard",
    ["rf_opt_skin_group_manager"]       = "Reskinear el panel de líder de grupo (comprobación, marcadores, abandonar grupo)",
    ["rf_opt_sort_role"]                 = "Ordenar por rol (Tanque > Sanador > DPS)",
    ["rf_section_layout"]                = "Disposición",
    ["rf_opt_layout_mode"]               = "Modo de disposición",
    ["rf_layout_grid"]                   = "Cuadrícula (grupos en columnas)",
    ["rf_layout_list"]                   = "Lista (columna única)",
    ["rf_opt_width"]                     = "Ancho del marco",
    ["rf_opt_height"]                    = "Alto del marco",
    ["rf_opt_spacing"]                   = "Espaciado",
    ["rf_opt_group_spacing"]             = "Espaciado de grupo",
    ["rf_section_display"]               = "Visualización",
    ["rf_opt_show_name"]                 = "Mostrar nombre",
    ["rf_opt_name_max_length"]           = "Letras máximas del nombre",
    ["rf_opt_show_health_text"]          = "Mostrar texto de salud",
    ["rf_opt_health_format"]             = "Formato de salud",
    ["rf_opt_health_color"]              = "Modo de color de salud",
    ["rf_opt_show_role"]                 = "Mostrar icono de rol",
    ["rf_opt_show_marker"]               = "Mostrar marcador de banda",
    ["rf_opt_readycheck_size"]            = "Tamaño del icono de preparación",
    ["rf_opt_summon_size"]               = "Tamaño del indicador de invocación",
    ["rf_section_font"]                  = "Fuente",
    ["rf_opt_font_size"]                 = "Tamaño de fuente",
    ["rf_section_position"]              = "Posición",
    ["rf_info_position"]                 = "Usa /tm layout para desbloquear y mover los marcos de banda.",
    ["rf_btn_reset_position"]            = "Restablecer posición",
    ["rf_info_test_raid"]                = "Simula una banda de 20 jugadores para previsualizar el diseño fuera de combate.",
    ["rf_btn_test_raid"]                 = "Simular 20 jugadores",
    ["rf_btn_test_raid_stop"]            = "Detener simulación",
    ["rf_preview_group"]                 = "G",
    ["rf_mode_raid"]                     = "Raid",
    ["rf_mode_solo"]                     = "Solo",
    ["rf_section_health_extras"]         = "Funciones de salud",
    ["rf_opt_show_power"]                = "Barra de poder (solo sanadores)",
    ["rf_opt_power_height"]              = "Altura de la barra de poder",
    ["rf_opt_show_absorb"]               = "Mostrar barra de absorción",
    ["rf_opt_show_heal_pred"]            = "Mostrar predicción de curación",
    ["rf_section_range"]                 = "Verificación de rango",
    ["rf_opt_show_range"]                = "Desvanecer miembros fuera de rango",
    ["rf_opt_oor_alpha"]                 = "Opacidad fuera de rango",
    ["rf_section_dispel"]                = "Resaltado de disipación",
    ["rf_opt_show_dispel"]               = "Resaltar debuffs disipables",
    ["rf_section_hots"]                  = "Rastreo de HoTs",
    ["rf_opt_show_hots"]                 = "Mostrar indicadores HoT",
    ["rf_opt_hot_size"]                  = "Tamaño de icono HoT",
    ["rf_opt_max_hots"]                  = "Máx. HoTs mostrados",
    ["rf_section_debuffs"]               = "Rastreo de debuffs",
    ["rf_opt_show_debuffs"]              = "Mostrar iconos de debuff",
    ["rf_opt_debuff_size"]               = "Tamaño de icono de debuff",
    ["rf_opt_max_debuffs"]               = "Máx. debuffs mostrados",
    ["rf_section_defensives"]            = "CDs defensivos",
    ["rf_opt_show_defensives"]           = "Mostrar buffs defensivos activos",
    ["rf_opt_defensive_size"]            = "Tamaño de icono defensivo",
    ["rf_info_defensives"]               = "Muestra CDs defensivos activos (ej: Supresión del dolor, Piel de hierro, Escudo divino) en cada miembro de la banda.",

    -- Indicador de resurrección (banda)
    ["rf_section_resurrect"]             = "Indicador de resurrección",
    ["rf_opt_show_resurrect"]            = "Mostrar icono de resurrección entrante",
    ["rf_opt_resurrect_size"]            = "Tamaño del icono de resurrección",
    ["rf_info_resurrect"]                = "Muestra un icono de rez en un miembro mientras se está lanzando una resurrección sobre él (rez de combate o normal).",

    -- Contador de rez de combate
    ["rf_section_battlerez"]             = "Contador de rez de combate",
    ["rf_opt_br_enable"]                 = "Mostrar contador de rez de combate",
    ["rf_opt_br_only_instance"]          = "Solo en mazmorras/bandas",
    ["rf_opt_br_size"]                   = "Tamaño del contador",
    ["rf_opt_br_font"]                   = "Tamaño de fuente del contador",
    ["rf_info_battlerez"]                = "Un contador movible que muestra cuántas rez de combate hay disponibles y el tiempo hasta la siguiente carga. Lee el pool compartido, funciona en cualquier clase. Muévelo con /tm layout.",

    -- Diseño por tamaño
    ["rf_section_size_overrides"]        = "Diseño por tamaño (10/25/40)",
    ["rf_opt_overrides_enable"]          = "Activar diseños por tamaño",
    ["rf_info_size_overrides"]           = "Cuando está activado, el tamaño del marco se adapta automáticamente al tamaño del grupo (el espaciado se ajusta por tramo).",
    ["rf_ov_small"]                      = "Pequeño  (hasta 10)",
    ["rf_ov_medium"]                     = "Mediano  (hasta 25)",
    ["rf_ov_large"]                      = "Grande  (26-40)",
    ["rf_ov_width"]                      = "Anchura",
    ["rf_ov_height"]                     = "Altura",

    -- ═══════════════════════════════════
    -- Aura Tracker
    -- ═══════════════════════════════════
    ["tab_qol_aura_tracker"]             = "Rastreador de auras",
    ["mover_auratracker"]                = "Rastreador de auras",
    ["mover_battlerez"]                  = "Rez de combate",

    ["at_section_general"]               = "General",
    ["at_opt_enable"]                    = "Activar rastreador de auras",
    ["at_info_description"]              = "Rastrea buffs importantes: procs de abalorios, procs de encantamientos, buffs personales y defensivas en un overlay de iconos.",

    ["at_section_appearance"]            = "Apariencia",
    ["at_opt_icon_size"]                 = "Tamaño de icono",
    ["at_opt_spacing"]                   = "Espaciado",
    ["at_opt_max_icons"]                 = "Máx. iconos",
    ["at_opt_grow_direction"]            = "Dirección de crecimiento",
    ["at_opt_font_size"]                 = "Tamaño de fuente",

    ["at_section_display"]               = "Visualización",
    ["at_opt_show_timer"]                = "Mostrar temporizador",
    ["at_opt_show_stacks"]               = "Mostrar pilas",
    ["at_opt_show_glow"]                 = "Brillo en nuevo proc",
    ["at_opt_timer_threshold"]           = "Umbral de parpadeo (seg.)",

    ["at_section_categories"]            = "Categorías",
    ["at_info_categories"]               = "Elige qué categorías de auras rastrear.",
    ["at_cat_trinkets"]                  = "Procs de abalorio",
    ["at_cat_enchants"]                  = "Procs de encantamiento",
    ["at_cat_selfbuffs"]                 = "Buffs personales (CDs)",
    ["at_cat_raidbuffs"]                 = "Buffs de banda",
    ["at_cat_defensives"]                = "Defensivas (externas + personales)",

    ["at_section_position"]              = "Posición",
    ["at_info_position"]                 = "Usa /tm layout para desbloquear y arrastrar el rastreador.",
    ["at_btn_reset_position"]            = "Restablecer posición",

    -- ═══════════════════════════════════
    -- Battle Text
    -- ═══════════════════════════════════
    ["cat_battletext"]                   = "Texto de combate",
    ["mover_battletext"]                 = "Texto de combate",

    ["bt_section_general"]               = "General",
    ["bt_info_description"]              = "Texto de combate desplazable: daño y curación, entrante y saliente.",
    ["bt_opt_enable"]                    = "Activar texto de combate",

    ["bt_section_display"]               = "Visualización",
    ["bt_opt_outgoing"]                  = "Mostrar daño saliente",
    ["bt_opt_incoming"]                  = "Mostrar daño entrante",
    ["bt_opt_overheal"]                  = "Mostrar sobrecuración",
    ["bt_opt_throttle"]                  = "Fusionar ticks DoT/HoT",

    ["bt_section_appearance"]            = "Apariencia",
    ["bt_opt_font_size"]                 = "Tamaño de fuente",
    ["bt_opt_throttle_window"]           = "Ventana de fusión (seg)",

    ["bt_section_position"]              = "Posición",
    ["bt_info_position"]                 = "Usa /tm layout para desbloquear y arrastrar las zonas.",
    ["bt_btn_reset_position"]            = "Restablecer posiciones",

    ["bt_zone_outgoing"]                 = "Saliente",
    ["bt_zone_incoming"]                 = "Entrante",
    ["bt_zone_heal_out"]                 = "Curación saliente",
    ["bt_zone_heal_in"]                  = "Curación recibida",

    ["bt_cmd_help"]                      = "/tm bt <cmd>",
    ["bt_enabled"]                       = "activado",
    ["bt_disabled"]                      = "desactivado",
    ["bt_crit"]                          = "!",
    ["bt_zones_locked"]                  = "zonas bloqueadas",
    ["bt_zones_unlocked"]                = "zonas desbloqueadas",
    ["bt_reset_done"]                    = "posiciones restablecidas.",
    ["bt_miss_miss"]                     = "Fallo",
    ["bt_miss_dodge"]                    = "Esquivado",
    ["bt_miss_parry"]                    = "Parado",
    ["bt_miss_block"]                    = "Bloqueado",
    ["bt_miss_resist"]                   = "Resistido",
    ["bt_miss_absorb"]                   = "Absorbido",
    ["bt_miss_immune"]                   = "Inmune",
    ["bt_miss_evade"]                    = "Evasión",
    ["bt_miss_deflect"]                  = "Desviado",
    ["bt_miss_reflect"]                  = "Reflejado",

    -- =========== What's New Popup ===========
    ["wn_title"]                         = "Novedades",
    ["wn_version"]                       = "Versi\195\179n %s",
    ["wn_subtitle"]                      = "Esto es lo que cambi\195\179 desde tu \195\186ltima actualizaci\195\179n:",
    ["wn_btn_ok"]                        = "\194\161Entendido!",
    ["wn_footer"]                        = "Todos los ajustes pueden cambiarse en cualquier momento con |cff2ed884/tm|r.",

    -- 2.9.8
    ["wn_298_housing"]                   = "Nuevo m\195\179dulo Housing: hover de decoraci\195\179n, reloj del editor y /tm home (Midnight+).",
    ["wn_298_housing_hover"]             = "Hover de decoraci\195\179n: muestra nombre, coste de colocaci\195\179n y stock restante; tecla modificadora para duplicar.",
    ["wn_298_housing_clock"]             = "Reloj del editor: reloj anal\195\179gico/digital con seguimiento de tiempo por sesi\195\179n y total.",
    ["wn_298_housing_teleport"]          = "/tm home: te teletransporta a tu casa o sale autom\195\161ticamente si est\195\161s de visita.",
    ["wn_298_icons"]                     = "Nuevos iconos de categor\195\173a: icono de casa para Housing, icono de monitor para Diagn\195\179sticos.",
    ["wn_298_locales"]                   = "Housing + panel Diagn\195\179sticos: soporte completo de locales frFR, deDE, esES, itIT, ptBR.",

    -- 2.9.6
    ["wn_296_raid_frames"]               = "Nuevo módulo Marcos de banda: marcos de raid personalizados en cuadrícula o lista.",
    ["wn_296_raid_health"]               = "Barras de salud, absorción y predicción de curación + barra de poder (solo sanadores).",
    ["wn_296_raid_auras"]                = "Rastreo de debuffs y HoTs con bordes coloreados por tipo/clase.",
    ["wn_296_raid_utilities"]            = "Iconos de CDs defensivos, resaltado de disipación, desvanecimiento fuera de rango, iconos de rol, marcadores de banda y verificación de preparación.",
    ["wn_296_raid_config"]               = "Panel de configuración completo con pestañas General y Funciones, 80+ claves de idioma en 6 lenguas.",

    -- 2.9.7
    ["wn_297_rf_live_preview"]           = "Marcos de banda: vista previa en vivo en el panel de configuración — 20 miembros simulados se actualizan en tiempo real.",
    ["wn_297_rf_preview_layout"]         = "La vista previa muestra todos los modos: cuadrícula (etiquetas G1–G4) o lista (2 columnas), con roles y HoTs.",
    ["wn_297_rf_preview_scaling"]        = "Escala automática al ancho del panel; refleja anchura, altura, espaciado, color, nombre, barra de poder y más.",
    ["wn_297_taint_blizzard"]            = "Marcos de banda: ocultación de frames Blizzard reescrita (SetAlpha+SetScale) — corrige el taint de CompactPartyFrame y ArenaFrame.",
    ["wn_297_range_fix"]                 = "Marcos de banda: desvanecimiento por distancia corregido para booleanos secretos de Midnight+ (SetAlphaFromBoolean).",
    ["wn_297_actionbars_fix"]            = "Barras de acción: inicialización aplazada tras el bloqueo de combate — corrige el taint de SecureStateDriver al iniciar.",
    ["wn_297_mp_tracker"]                = "Mythic+: ObjectiveTrackerFrame ahora se oculta correctamente durante el modo desafío.",
    ["wn_297_role_icon"]                 = "Marcos de banda: tamaño predeterminado del icono de rol duplicado (10 → 20).",
    ["wn_297_castbar_fix"]               = "Barras de lanzamiento: la barra del jugador ya no desaparece en combate — FadeOut ahora es idempotente y el nil transitorio ya no oculta la barra.",
    ["wn_297_diag_exclusions"]           = "Diagnósticos: mensajes de restricción de montura y límite de mascotas excluidos de la captura de errores.",

    -- 2.9.5
    ["wn_295_taint_fix"]                 = "CooldownTrackers: eliminado COMBAT_LOG_EVENT_UNFILTERED para corregir taint (ADDON_ACTION_FORBIDDEN).",
    ["wn_295_diag_taint"]                = "Diagnósticos: los errores de taint ahora siempre se capturan, incluso con diagnósticos desactivados.",
    ["wn_295_tooltip_ids_moved"]         = "Opciones de Tooltip IDs movidas del panel QOL a Skins > pestaña Tooltip.",
    ["wn_295_chat_text_offset"]          = "Skin del chat: texto ligeramente desplazado a la derecha para despejar la barra lateral.",

    -- 2.9.4
    ["wn_294_installer"]                 = "Instalador ampliado de 12 a 16 pasos guiados.",
    ["wn_294_uf_pf"]                     = "Nuevos pasos: configuraci\195\179n de Unit Frames y Party Frames.",
    ["wn_294_cb_res"]                    = "Nuevos pasos: Barras de lanzamiento y Recursos / Gestor de cooldowns.",
    ["wn_294_skins_qol"]                 = "Paso Skins mejorado (bolsas, tooltips) y paso QOL (minimapa, cursor, AFK, diagn\195\179sticos, rastreador de auras).",
    ["wn_294_bugfixes"]                  = "Correcciones de valores secretos para TooltipIDs y CooldownTrackers (taint Midnight).",
    ["wn_294_locales"]                   = "50+ nuevas claves de traducci\195\179n en los 6 idiomas.",

    -- 2.9.3
    ["wn_293_partyframe"]                = "Party Frames: iconos de ready check, tooltip al pasar el cursor, reescritura de marcadores raid.",
    ["wn_293_actionbar_fix"]             = "Barras de acci\195\179n: correcci\195\179n de interactividad barras 1-4, correcci\195\179n botones vac\195\173os.",
    ["wn_293_chat_taint"]                = "Skin del chat: correcciones taint Midnight (guards GUID/BN secretos).",
    ["wn_293_diagnostics"]               = "Diagn\195\179sticos: exclusi\195\179n por patr\195\179n, palabras clave en 6 idiomas.",
    ["wn_293_autofill"]                  = "AutoFillDelete: correcci\195\179n STATICPOPUP_NUMDIALOGS Midnight.",

    -- 2.9.2
    ["wn_292_actionbar"]                 = "Reescritura completa de barras de acci\195\179n: arquitectura contenedor, sistema de fade, condiciones de visualizaci\195\179n.",
    ["wn_292_diagnostics"]               = "Nueva consola de diagn\195\179sticos: captura de errores en segundo plano, exportaci\195\179n, /tmdiag.",

    -- =====================
    -- CONFIG: Diagnostics Panel
    -- =====================
    ["section_diagnostics"]              = "Diagn\195\179sticos",
    ["opt_diag_enabled"]                 = "Activar captura de errores",
    ["opt_diag_capture_all"]             = "Capturar todos los addons",
    ["opt_diag_suppress_popups"]         = "Suprimir ventanas de error",
    ["opt_diag_auto_open"]               = "Abrir auto. con error de TomoMod",
    ["btn_diag_open_console"]            = "Abrir consola",
    ["btn_diag_clear"]                   = "Borrar errores",
    ["btn_diag_export"]                  = "Copiar informe",
    ["btn_diag_export_tracker"]          = "Exportar para Tracker",
    ["info_diag_desc"]                   = "Captura errores Lua en segundo plano sin ventanas emergentes en combate. /tmdiag para abrir la consola.",
    ["info_diag_session"]                = "Sesi\195\179n: #%d \226\128\148 %d errores capturados (%d TomoMod)",
    ["info_diag_capture_all_desc"]       = "Cuando est\195\161 desactivado, solo se capturan errores de TomoMod. Activa para capturar todos los errores de addons.",

    -- =====================
    -- HOUSING
    -- =====================
    ["section_housing_general"]      = "Housing \226\128\148 General",
    ["section_housing_hover"]        = "Info decoraci\195\179n (hover)",
    ["section_housing_clock"]        = "Reloj del editor",
    ["section_housing_teleport"]     = "Teletransportaci\195\179n",
    ["section_housing_commands"]     = "Comandos",

    ["info_housing_desc"]            = "M\195\179dulo Housing: mejora el editor de casas y a\195\177ade atajos de teletransportaci\195\179n. Requiere Midnight / The War Within.",
    ["info_housing_hover"]           = "En el modo 'Decoraci\195\179n base', muestra nombre, coste de colocaci\195\179n y stock restante. Tambi\195\169n permite duplicar con tecla modificadora.",
    ["info_housing_clock"]           = "Muestra un reloj y registra el tiempo en el editor de casas. Clic derecho para cambiar entre anal\195\179gico y digital.",
    ["info_housing_teleport"]        = "Activa /tm home: te teletransporta a tu casa o sales autom\195\161ticamente si est\195\161s de visita.",
    ["info_housing_commands"]        = "\226\128\162 /tm home \226\128\148 teletransportarte a tu casa (o salir)\n\226\128\162 /tm housing \226\128\148 abrir este panel\n\226\128\162 Clic derecho en el reloj \226\128\148 cambiar anal\195\179gico/digital",

    ["opt_housing_enable"]           = "Activar m\195\179dulo Housing",
    ["opt_housing_decorhover"]       = "Activar info decoraci\195\179n",
    ["opt_housing_dupe"]             = "Activar duplicaci\195\179n r\195\161pida (modificador)",
    ["opt_housing_dupekey"]          = "Tecla de duplicaci\195\179n",
    ["opt_housing_clock"]            = "Activar reloj",
    ["opt_housing_clock_analog"]     = "Modo anal\195\179gico (si no, digital)",
    ["opt_housing_teleport"]         = "Activar teletransportaci\195\179n /tm home",

    ["btn_housing_tp_home"]          = "Teletransportar (prueba)",
    ["btn_housing_refresh"]          = "Actualizar casas",

    ["housing_duplicate"]            = "Duplicar",
    ["housing_alliance_zone"]        = "Promontorio del Fundador",
    ["housing_horde_zone"]           = "Costas de Viento Filo",
    ["housing_clock_title"]          = "TomoMod \226\128\148 Reloj",
    ["housing_clock_time"]           = "Hora",
    ["housing_clock_local"]          = "Hora local:",
    ["housing_clock_realm"]          = "Hora del reino:",
    ["housing_clock_time_spent"]     = "Tiempo en el editor",
    ["housing_clock_session"]        = "Esta sesi\195\179n:",
    ["housing_clock_total"]          = "Total:",
    ["housing_clock_rightclick"]     = "Clic derecho para cambiar anal\195\179gico / digital",

    ["msg_help_home"]                = "Teletransportarte a tu casa (o salir)",
    ["msg_help_housing"]             = "Abrir el panel Housing",
    ["msg_housing_refresh"]          = "Informaci\195\179n de casas solicitada.",
    ["msg_housing_unavailable"]      = "M\195\179dulo Housing no disponible en este cliente.",

    -- =====================
    -- CONFIG: Diagnostics Panel
    -- =====================
    ["section_diagnostics"]              = "Diagn\195\179sticos",
    ["opt_diag_enabled"]                 = "Activar captura de errores",
    ["opt_diag_capture_all"]             = "Capturar todos los addons",
    ["opt_diag_suppress_popups"]         = "Suprimir ventanas de error",
    ["opt_diag_auto_open"]               = "Abrir auto. con error de TomoMod",
    ["btn_diag_open_console"]            = "Abrir consola",
    ["btn_diag_clear"]                   = "Borrar errores",
    ["btn_diag_export"]                  = "Copiar informe",
    ["btn_diag_export_tracker"]          = "Exportar para Tracker",
    ["info_diag_desc"]                   = "Captura errores Lua en segundo plano sin ventanas emergentes en combate. /tmdiag para abrir la consola.",
    ["info_diag_session"]                = "Sesi\195\179n: #%d \226\128\148 %d errores capturados (%d TomoMod)",
    ["info_diag_capture_all_desc"]       = "Cuando est\195\161 desactivado, solo se capturan errores de TomoMod. Activa para capturar todos los errores de addons.",

    -- =====================
    -- HOUSING
    -- =====================
    ["cat_housing"]                  = "Housing",
    ["section_housing_general"]      = "Housing \226\128\148 General",
    ["section_housing_hover"]        = "Info decoraci\195\179n (hover)",
    ["section_housing_clock"]        = "Reloj del editor",
    ["section_housing_teleport"]     = "Teletransportaci\195\179n",
    ["section_housing_commands"]     = "Comandos",

    ["info_housing_desc"]            = "M\195\179dulo Housing: mejora el editor de casas y a\195\177ade atajos de teletransportaci\195\179n. Requiere Midnight / The War Within.",
    ["info_housing_hover"]           = "En el modo 'Decoraci\195\179n base', muestra nombre, coste de colocaci\195\179n y stock restante. Tambi\195\169n permite duplicar con tecla modificadora.",
    ["info_housing_clock"]           = "Muestra un reloj y registra el tiempo en el editor de casas. Clic derecho para cambiar entre anal\195\179gico y digital.",
    ["info_housing_teleport"]        = "Activa /tm home: te teletransporta a tu casa o sales autom\195\161ticamente si est\195\161s de visita.",
    ["info_housing_commands"]        = "\226\128\162 /tm home \226\128\148 teletransportarte a tu casa (o salir)\n\226\128\162 /tm housing \226\128\148 abrir este panel\n\226\128\162 Clic derecho en el reloj \226\128\148 cambiar anal\195\179gico/digital",

    ["opt_housing_enable"]           = "Activar m\195\179dulo Housing",
    ["opt_housing_decorhover"]       = "Activar info decoraci\195\179n",
    ["opt_housing_dupe"]             = "Activar duplicaci\195\179n r\195\161pida (modificador)",
    ["opt_housing_dupekey"]          = "Tecla de duplicaci\195\179n",
    ["opt_housing_clock"]            = "Activar reloj",
    ["opt_housing_clock_analog"]     = "Modo anal\195\179gico (si no, digital)",
    ["opt_housing_teleport"]         = "Activar teletransportaci\195\179n /tm home",

    ["btn_housing_tp_home"]          = "Teletransportar (prueba)",
    ["btn_housing_refresh"]          = "Actualizar casas",

    ["housing_duplicate"]            = "Duplicar",
    ["housing_alliance_zone"]        = "Promontorio del Fundador",
    ["housing_horde_zone"]           = "Costas de Viento Filo",
    ["housing_clock_title"]          = "TomoMod \226\128\148 Reloj",
    ["housing_clock_time"]           = "Hora",
    ["housing_clock_local"]          = "Hora local:",
    ["housing_clock_realm"]          = "Hora del reino:",
    ["housing_clock_time_spent"]     = "Tiempo en el editor",
    ["housing_clock_session"]        = "Esta sesi\195\179n:",
    ["housing_clock_total"]          = "Total:",
    ["housing_clock_rightclick"]     = "Clic derecho para cambiar anal\195\179gico / digital",

    ["msg_help_home"]                = "Teletransportarte a tu casa (o salir)",
    ["msg_help_housing"]             = "Abrir el panel Housing",
    ["msg_housing_refresh"]          = "Informaci\195\179n de casas solicitada.",
    ["msg_housing_unavailable"]      = "M\195\179dulo Housing no disponible en este cliente.",

    -- ═══════════════════════════════════
    -- Merchant Tools (2.9.9)
    -- ═══════════════════════════════════
    ["wn_299_merchant_tools"]             = "Nuevo módulo Herramientas vendedor: Ya conocido + Páginas extendidas (pestaña QOL).",
    ["wn_299_already_known"]              = "Ya conocido: atenúa o tinta los artículos del vendedor/recompra que ya posees (monturas, mascotas, juguetes, transmog, recetas).",
    ["wn_299_extend_pages"]               = "Páginas extendidas: la ventana del vendedor puede mostrar hasta 4 columnas de 10 artículos.",
    ["wn_299_locales"]                    = "Herramientas vendedor: soporte completo en los 6 idiomas.",
    ["wn_299_lustsound"]                   = "LustSound: corregida alerta de sonido falsa provocada por la breve desaparición del debuff Saciado durante resincronización del servidor o cambios de zona.",

    ["tab_qol_merchant_tools"]           = "Herramientas vendedor",

    ["section_already_known"]            = "Ya conocido",
    ["info_already_known"]               = "Atenúa o tinta los artículos del vendedor/recompra que ya posees (monturas, mascotas, juguetes, conjuntos de transmog, recetas).",
    ["opt_ak_enable"]                    = "Activar Ya conocido",
    ["opt_ak_mode"]                      = "Modo de visualización",
    ["ak_mode_mono"]                     = "Monocromático (gris)",
    ["ak_mode_color"]                    = "Tinte de color",
    ["opt_ak_color"]                     = "Color del tinte",

    ["section_extend_pages"]             = "Páginas de vendedor extendidas",
    ["info_extend_pages"]                = "Añade columnas extra a la ventana del vendedor.\nRequiere recargar la interfaz tras activar o cambiar el número de columnas.",
    ["opt_ep_enable"]                    = "Activar páginas extendidas",
    ["opt_ep_columns"]                   = "Número de columnas",

    ["preset_complet_name"]  = "Recomendado",
    ["preset_complet_tag"]   = "La experiencia TomoMod completa",
    ["preset_complet_desc"]  = "Activa todos los módulos principales con valores predeterminados sensatos: UnitFrames, marcos de grupo y banda, Nameplates, barras de lanzamiento, recursos, skin de barras de acción, todos los skins visuales, herramientas Mythic+ y las funciones de comodidad más útiles. El mejor punto de partida para la mayoría.",
    ["preset_tank_name"]     = "Tank",
    ["preset_tank_tag"]      = "Centrado en amenaza, Nameplates más anchas",
    ["preset_tank_desc"]     = "La configuración Recomendada, ajustada para tanquear: Nameplates coloreadas por amenaza (Modo Tank) y un poco más anchas para leer mejor la aggro, además del indicador de amenaza en el objetivo.",
    ["preset_healer_name"]   = "Sanador",
    ["preset_healer_tag"]    = "Marcos de banda más grandes, maná visible",
    ["preset_healer_desc"]   = "La configuración Recomendada, ajustada para sanar: marcos de banda y grupo más grandes y fáciles de clicar, con barras de recurso (maná) visibles, seguimiento de HoTs, resaltado de disipación y defensivos bien a la vista.",
    ["preset_dps_name"]      = "DPS",
    ["preset_dps_tag"]       = "Recursos y cooldowns destacados",
    ["preset_dps_desc"]      = "La configuración Recomendada, ajustada para daño: una barra de recursos más visible, seguimiento de buffs del objetivo para defensivos enemigos y Nameplates limpias sin coloración de amenaza de tank.",
    ["preset_minimal_name"]  = "Mínimo",
    ["preset_minimal_tag"]   = "Solo lo esencial",
    ["preset_minimal_desc"]  = "Una huella ligera: mantiene UnitFrames, marcos de grupo y banda, barras de lanzamiento, barras de recursos, el minimapa y las automatizaciones esenciales — todo lo cosmético (skins, chat, bolsas, Nameplates, paneles extra) queda desactivado. Lo más parecido a una sensación vanilla.",
    ["preset_custom_name"]   = "Personalizado",
    ["preset_custom_tag"]    = "Configúralo todo tú mismo",
    ["preset_custom_desc"]   = "Omite los presets y recorre cada categoría paso a paso para activar exactamente lo que quieras. Siempre puedes cambiar cualquier cosa después desde /tm.",
    ["preset_applied"]       = "Preset aplicado: %s — escribe /reload para ver el resultado.",
    ["preset_unknown"]       = "Preset desconocido « %s ». Disponibles: complet, tank, healer, dps, minimal.",
    ["preset_usage"]         = "Uso: /tmpreset <complet|tank|healer|dps|minimal>",
    ["ins_v3_welcome_desc"]      = "¡Bienvenido! Este asistente rápido te deja una interfaz limpia y completa en segundos.\n\nElige una configuración acorde a tu forma de jugar — podrás ajustarlo todo después desde |cff2ed884/tm|r. ¿Prefieres elegir cada opción tú mismo? Elige |cffc89530Personalizado|r.",
    ["ins_pick_title"]           = "Elige tu configuración",
    ["ins_pick_subtitle"]        = "Selecciona un estilo de juego abajo. Todo queda ajustable después vía /tm.",
    ["ins_pick_recommended"]     = "Recomendado",
    ["ins_custom_frames_title"]  = "Marcos",
    ["ins_custom_barsskins_title"] = "Barras y Skins",
    ["ins_custom_mythicqol_title"] = "Mythic+ y Comodidad",
    ["ins_custom_frames_intro"]  = "Activa los marcos que quieras. Las opciones sensatas vienen preseleccionadas.",
    ["ins_custom_barsskins_intro"] = "Skin de barras de acción y skins visuales de chat, bolsas, tooltips y más.",
    ["ins_custom_mythicqol_intro"] = "Herramientas Mythic+, extras de interfaz, automatizaciones y sonido.",
    ["ins_recap_title"]          = "Todo listo",
    ["ins_recap_preset"]         = "Configuración aplicada: |cff2ed884%s|r",
    ["ins_recap_custom"]         = "Tu configuración personalizada está lista",
    ["ins_recap_desc"]           = "Recarga tu interfaz para aplicarlo todo. Puedes reabrir este asistente cuando quieras con |cff2ed884/tm install|r, y abrir el panel de configuración completo con |cff2ed884/tm|r.",
    ["cat_accueil"]              = "Inicio",
    ["ui_search_placeholder"]    = "Buscar módulo...",
    ["dash_welcome"]             = "Vista rápida de TomoMod. Activa módulos, aplica una configuración, cambia de perfil o relanza el asistente.",
    ["dash_modules_section"]     = "Módulos",
    ["dash_quickcfg_section"]    = "Configuración rápida",
    ["dash_profile_section"]     = "Perfil",
    ["dash_maint_section"]       = "Mantenimiento",
    ["dash_reload_hint"]         = "Activar módulos guarda tus ajustes — recarga para aplicar los cambios de módulo.",
    ["dash_reload_now"]          = "Recargar ahora",
    ["dash_apply_preset"]        = "Preset de configuración",
    ["dash_apply_preset_btn"]    = "Aplicar este preset",
    ["dash_apply_preset_info"]   = "Aplicar un preset reinicia qué módulos están activados o no, y luego recarga.",
    ["dash_active_profile"]      = "Perfil activo",
    ["dash_manage_profiles"]     = "Gestionar perfiles",
    ["dash_profile_info"]        = "Cambiar de perfil recarga la interfaz para aplicarlo.",
    ["dash_relaunch_info"]       = "Reabre el asistente de configuración « presets primero ».",
    ["dash_mod_resources"]       = "Recursos",
    ["dash_mod_cdm"]             = "Cooldown Manager",
    ["dash_mod_abskin"]          = "Skin de barras de acción",
    ["dash_mod_chatskin"]        = "Skin del chat",
    ["dash_mod_bagskin"]         = "Skin de bolsas",
    ["dash_mod_mtracker"]        = "Rastreador Mythic+",
    ["dash_mod_score"]           = "Puntuación Mythic+",
    ["dash_reload_popup"]        = "¿Recargar la interfaz ahora para aplicar tus cambios?",

    -- ═══════════════════════════════════
    -- MythicTracker Nombres EJ (2.9.10)
    -- ═══════════════════════════════════
    -- ═══════════════════════════════════
    -- Corrección CD PartyFrame + Rendimiento (2.9.12)
    -- ═══════════════════════════════════
    -- ═══════════════════════════════════
    -- Installer Overhaul & AB Toggle (2.9.17)
    -- ═══════════════════════════════════
    -- Objective Tracker Quest Buckets (2.9.18)
    -- ═══════════════════════════════════
    -- Smart Waypoint (2.9.20)
    -- ═══════════════════════════════════
    ["wn_2920_waypoint_redirect"]       = "Smart Waypoint — cross-zone redirect: the waypoint now tracks the next path step on your current map (portal, dungeon entrance) via C_SuperTrack.GetNextWaypointForMap(), updated on SUPER_TRACKING_PATH_UPDATED and zone changes.",
    ["wn_2920_waypoint_blob"]           = "Smart Waypoint — stuck 0 m fix: the beacon now hides automatically when the player is inside the quest objective area (C_Minimap.IsInsideQuestBlob), preventing the waypoint from freezing at 0 m.",
    ["wn_2920_waypoint_label"]          = "Smart Waypoint — dynamic label: the destination now shows the redirect step description (e.g. 'Travel to Durotar') or the tracked quest title instead of a blank field.",
    -- Objective Tracker Stability (2.9.19)
    -- ═══════════════════════════════════
    ["wn_2919_antiflicker"]             = "Anti-flicker — eliminated the visible 'trembling' of the Objective Tracker caused by a feedback loop between TomoMod's bucket layout and Blizzard's native Update / MarkDirty hooks. New re-entry guard, deferred pump coalescing, and a 0.20 s post-layout silence window break the recursion.",
    ["wn_2919_collapsed_persist"]       = "Collapsed bucket persistence — quest blocks under a collapsed bucket header no longer reappear when Blizzard re-runs its layout; each block gets a one-time Show hook that re-hides it while its bucket is folded.",
    ["wn_2919_header_detection"]        = "Module header detection — accent- and case-insensitive matching (Métier / métier / MÉTIER all resolve to the same keyword) and added singular variants. Quest titles and objective lines are now explicitly excluded so the full quest description is never accidentally hidden.",
    ["wn_2919_recipe_height"]           = "Recipe block height — Profession recipe blocks no longer overlap the next quest. The deepest-descendant measurement now runs unconditionally and walks 8 levels deep to reach reagent FontStrings (TrackedRecipe → Lines → Line[i]).",
    ["wn_2919_reward_preview"]          = "Reward preview exclusion — Delves (e.g. 'La Sombrevoie'), M+ scenarios, world quest reward popups and weekly vault reward blocks (e.g. 'Halte de l'Ombre-Garde' with ilvl preview) are now skipped from the bucket system. They stay in Blizzard's native location and no longer overlap our quests.",
    ["wn_2918_buckets"]                 = "Objective Tracker quest buckets — quests, world quests, weeklies, dailies, dungeons, raids, professions and achievements are now grouped into collapsible categories with colored headers and live count badges.",
    ["wn_2918_bucket_toggle"]           = "New 'Group quests into collapsible categories' checkbox in Config → Skins → Objective Tracker; disabling it instantly restores Blizzard's native module layout, no /reload required.",
    ["wn_2918_tracker_width"]           = "Tracker panel widened by 10 px so quest item icons no longer clip against the right edge.",
    ["wn_2918_layout_fix"]              = "Re-parented quest blocks now anchor both TOPLEFT and TOPRIGHT to prevent width collapse, and stale heights after collapse/expand are corrected via multi-pass layout.",

    ["wn_2917_ab_master_toggle"]        = "Action Bar master toggle — a new checkbox lets you fully disable bar management; after /reload, Blizzard's default action bars are fully restored.",
    ["wn_2917_installer_raid"]          = "Installer step 5 — Raid Frames: enable/disable, hide Blizzard frames, dispel highlights, HoT tracking, debuff and defensive icons, grid/list layout.",
    ["wn_2917_installer_coverage"]      = "Installer expanded — Skins step adds Objective Tracker, Mail, Reputation Bar; QOL step adds Auto Summon, Auto Quest, Class Reminder, Leveling Bar, Waypoint, World Quests, Frame Anchors, Profession Helper.",
    ["wn_2917_chat_skin_fix"]           = "Chat Skin fix — installer wrote to orphan key instead of the actual chatFrameSkin key.",
    ["wn_2917_talking_head_fix"]        = "HideTalkingHead fix — module now checks its DB toggle before suppressing the TalkingHead frame.",
    ["wn_2917_minimal_style"]           = "Action Bar Minimal style — the 5th skin style was missing from the Installer dropdown; now selectable.",

    -- AuctionRecipeTracker (2.9.15)
    -- ═══════════════════════════════════
    ["wn_2916_layout_fix"]              = "Fallo silencioso del botón Layout corregido — en una instalación nueva, hacer clic en 'Layout' no hacía nada porque el sistema de movers no completaba la inicialización. Toggle ahora se inicializa de forma diferida vía pcall y muestra cualquier error en el chat en lugar de fallar en silencio.",
    ["wn_2916_safe_init"]               = "Refuerzo de la cadena de init de módulos — cada llamada Initialize() de los módulos de TomoMod ahora se envuelve en xpcall mediante un helper safeInit; un módulo defectuoso ya no rompe los ~45 módulos que se inician después de él, y el módulo culpable se reporta en el chat.",
    ["wn_2916_art_total"]               = "AuctionRecipeTracker — cada cabecera de receta seguida muestra ahora el coste total global de sus reactivos a la derecha; si al menos un reactivo no tiene precio registrado, un (~) gris indica que el total es una estimación parcial.",
    ["wn_2916_avr_gui"]                 = "GUI Auto Vendedor / Reparación — dos nuevas casillas en Config → QOL → Automatizaciones permiten activar de forma independiente la reparación automática en el comerciante y la venta automática de objetos grises (pobres); los ajustes se persisten en TomoModDB y se aplican en vivo sin /reload.",
    ["wn_2915_art_module"]              = "Nuevo módulo QOL — AuctionRecipeTracker: una GUI se abre automáticamente en el subastador cuando se sigue al menos una receta de profesión; las filas muestran '14x icono Nombre del objeto precio', clic para buscar en la CS y un botón de escaneo completo manual.",
    ["wn_2915_art_tooltip"]             = "Línea TomoHDV en las descripciones — tras un escaneo, cada objeto (bolsas, banco, enlaces del chat, equipamiento) muestra el precio unitario registrado, más el precio total de la pila si stack > 1, y hace cuánto se realizó el escaneo.",
    ["wn_2915_art_scrollbar"]           = "Barra de desplazamiento moderna TomoMod — reemplaza la barra de Blizzard por una pista delgada de 4 px con un pulgar en color de acento dimensionado proporcionalmente al contenido; admite arrastrar, clic en la pista para saltar, rueda del ratón, y se oculta automáticamente cuando el contenido cabe.",
    ["wn_2915_art_anchor"]              = "Anclaje por defecto del AuctionRecipeTracker — la ventana se adhiere al borde derecho de la ventana de la CS (TOPLEFT, AuctionHouseFrame, TOPRIGHT, 8, 0); las posiciones personalizadas por arrastre se conservan y tienen prioridad.",
    ["wn_2915_art_scan_fix"]            = "Fiabilidad del botón de escaneo — OnShow ahora restablece scanInProgress, reactiva el botón y restaura su etiqueta; los retornos tempranos silenciosos (escaneo en curso, CS cerrada, API no disponible) ahora muestran un mensaje rojo en lugar de no hacer nada.",

    -- ═══════════════════════════════════
    -- MythicTracker Boss Names Fix (2.9.13)
    -- ═══════════════════════════════════
    ["wn_2913_boss_names"]               = "MythicTracker: los nombres de los jefes ahora se muestran correctamente en lugar de \"Boss 1\", \"Boss 2\" etc. — en WoW 12.x el campo de criterios de escenario se renombró de criteriaString a description; TomoMod ahora lee description primero con criteriaString como fallback.",
    ["wn_2913_boss_checkmark"]           = "MythicTracker: el prefijo de marca de verificación de Blizzard (añadido a los objetivos de jefe completados en 12.x) ahora se elimina antes de la visualización.",
    ["wn_2913_ej_pcall"]                 = "MythicTracker: la llamada a EncounterJournal_OpenJournal en FetchEJBossNames ahora está envuelta en pcall para prevenir posible taint en 12.x.",

    ["wn_2912_party_cd_fix"]             = "PartyFrame: el seguimiento de CD de interrupt y resurrección de combate usa ahora UNIT_SPELLCAST_SUCCEEDED con resolución segura de spellID (string.format); se ha eliminado COMBAT_LOG_EVENT_UNFILTERED — registrarlo desde un addon causa taint en 12.x.",
    ["wn_2912_healer_interrupt"]         = "PartyFrame: el icono del tracker de interrupt ahora se oculta para los sanadores — desde el parche 12.x los sanadores ya no tienen habilidad de interrupt.",
    ["wn_2912_perf_cdm"]                 = "CooldownManager: UpdateButtonState almacena en caché GetCooldownTimes, GetCachedCooldownID y GetCooldownViewerCooldownInfo una sola vez por botón y tick en lugar de dos; ~50% menos llamadas API en el bucle principal.",
    ["wn_2912_perf_aura"]                = "AuraTracker: tasa de actualización reducida de 10 fps (0,1 s) a 5 fps (0,2 s); ninguna diferencia visible, la carga del ticker se reduce a la mitad.",
    ["wn_2912_perf_resbars"]             = "ResourceBars: umbral OnUpdate para runas DK / stagger Monje aumentado de 50 ms a 100 ms; frecuencia de ejecución a la mitad sin impacto perceptible en la visualización.",

    -- ═══════════════════════════════════
    -- Correcciones CooldownManager / ProcGlow / BuffSkin (2.9.11)
    -- ═══════════════════════════════════
    ["wn_2911_cdm_hooks"]                = "CooldownManager: colores de swipe y ocultación del GCD fusionados en un único hook por botón; la detección del GCD ahora usa la caché del Scanner en lugar de pcall(C_CooldownViewer).",
    ["wn_2911_procglow_fixes"]           = "CDMProcGlow: el glow se aplica de forma síncrona en ShowAlert para evitar una race condition con HideAlert en el mismo frame; timers por frame reemplazados por un ticker global único; RefreshAll ahora filtra correctamente los procs activos.",
    ["wn_2911_buffskin_fixes"]           = "BuffSkin: SkinButton vuelve a aplicar anclas y máscaras de icono en frames reciclados por Blizzard; hooks instalados una sola vez mediante hooksInstalled (activar/desactivar funciona ahora correctamente); TemporaryEnchantFrame enganchado para actualizaciones de encantamientos; hooks instalados inmediatamente.",

    -- ═══════════════════════════════════
    -- MythicTracker Nombres EJ (2.9.10)
    -- ═══════════════════════════════════
    ["wn_2910_ej_boss_names"]            = "MythicTracker: nombres de jefes resueltos mediante el Diario de encuentros — localizados, compatibles con acentos, cubriendo todas las mazmorras desde Cata hasta The War Within.",
    ["wn_2910_ej_fallback"]              = "MythicTracker: resolución de nombres en 3 niveles — dungeonEncounterID > índice EJ > criteriaString filtrado como alternativa, con reintento automático (×5) si el EJ no está cargado aún.",

    -- Player Auras Mover (v2.9.5)
    ["mover_player_auras"]       = "Auras del jugador",
    ["opt_auras_spacing"]        = "Espaciado entre iconos",
    ["btn_reset_aura_position"]  = "Restablecer posición de auras",

    -- Module Reload Safety (v2.9.21)
    ["msg_module_reload"]        = "Este cambio requiere recargar la interfaz.\n¿Recargar ahora?",
    ["info_module_reload"]       = "Requiere /reload para aplicarse.",
    ["wn_2921_aura_mover"]       = "Las auras del jugador ahora tienen su propio mover en el modo Layout (overlay coloreado, etiqueta, arrastre independiente).",
    ["wn_2921_aura_gui"]         = "Nuevo control de espaciado de auras y botón de reinicio de posición en la pestaña Auras de la configuración.",
    ["wn_2921_reload_safety"]    = "Activar/desactivar un módulo principal (UnitFrames, Nameplates, Castbars, ActionBars, Party, Raid) ahora ofrece un /reload automático.",

    -- Waypoint Arrow Reversed (v2.9.22)
    ["wn_2922_waypoint_arrow"]    = "La flecha del navegador fuera de pantalla del waypoint está ahora en el lado opuesto de la órbita: cuando el objetivo está delante, la flecha aparece abajo y apunta hacia arriba.",

    -- 3.0.3
    -- 3.0.4
    ["wn_304_consumable_bar"]    = "ConsumableBar — nuevo módulo QOL que muestra los iconos del Frasco y Bien Alimentado con temporizador de cuenta atrás. Totalmente configurable (tamaño, separación, orientación, posición del temporizador) y movible en el Modo de Diseño.",
    ["wn_304_cursor_textures"]   = "Anillo del cursor — dos nuevas texturas añadidas (Cygle y Corazón). Selector de textura disponible en General → Anillo del cursor.",
    ["wn_304_mythichub_tp"]      = "Teleportación de MythicHub corregida — sin más taint (ADDON_ACTION_FORBIDDEN) ni errores de anclaje al hacer clic en las filas de mazmorra. IDs de hechizo para Maisara Caverns y Windrunner Spire también corregidos.",

    -- 3.0.3
    ["wn_303_tracking_panel"]    = "Panel de seguimiento personalizado — hacer clic en el botón de seguimiento ahora abre un panel estilo TomoMod a la izquierda del minimapa en lugar del desplegable nativo de Blizzard.",
    ["wn_303_collector_panel"]   = "Rediseño del panel colector — los botones de addon se agrupan en un panel TomoMod (fondo oscuro, título en verde azulado, borde del color de clase) anclado a la izquierda del minimapa.",
    ["wn_303_collector_autoclose"] = "El colector se cierra automáticamente 0,5 s tras el login/recarga una vez capturados los botones — se abre normalmente al hacer clic.",
    ["wn_303_tooltip_fix"]       = "Corrección del skin de tooltip — se ha resuelto el gran rectángulo negro que aparecía al pasar sobre unidades o hechizos.",
    ["wn_303_coords_pos"]        = "Las coordenadas del minimapa se han trasladado a la parte inferior central para mayor legibilidad.",

    -- 3.0.0
    ["wn_300_installer"]  = "Asistente de configuración totalmente nuevo — presets primero: elige Recomendado, Tank, Sanador, DPS, Mínimo o Personalizado y quedas listo en segundos.",
    ["wn_300_presets"]    = "Presets de configuración — un clic aplica una configuración coherente y ajustada al rol en todos los módulos; reutilizable cuando quieras desde /tm.",
    ["wn_300_dashboard"]  = "Nuevo panel de Inicio en /tm — interruptores rápidos de módulos, relanzar el asistente, aplicar un preset, cambiar de perfil y reiniciar, todo en un sitio.",
    ["wn_300_search"]     = "Barra lateral con búsqueda — filtra las categorías por nombre o palabra clave (escribe 'heal', 'cd', 'bag'…).",
    ["wn_300_locales"]    = "Localización completa de todos los textos nuevos de 3.0 en los 6 idiomas soportados.",

    -- 3.0.5
    ["wn_305_rare_alert"]           = "Alerta de Raro — nuevo módulo QOL: reproduce un sonido y muestra un banner cuando un PNJ raro entra en el radio del minimapa. Clic izquierdo: apuntar + marcador de calavera + waypoint. Clic derecho: cerrar.",
    ["wn_305_consumable_fix"]       = "ConsumableBar — corregido un error por el que la barra se mostraba como un rectángulo negro aunque el módulo estuviera desactivado.",
    ["wn_305_tm_marker"]            = "/tm 0-8 — restaurado el atajo nativo de Blizzard para marcadores de banda: /tm <0-8> ahora coloca el marcador en tu objetivo en lugar de abrir la config.",
    ["wn_305_minimap_clock_anchor"] = "Minimapa — el botón del colector ahora se ancla con precisión al texto del reloj en la barra completa del InfoPanel (modos clock-left / clock-right).",

    -- =====================
    -- Extra Action Button (v3.0.6)
    -- =====================
    ["mover_ab_extra"] = "Acción extra",
    ["section_extra_button"] = "Botón de acción extra",
    ["opt_extra_enabled"] = "Gestionar el botón de acción extra (recarga para liberar)",
    ["opt_extra_scale"] = "Escala del botón extra",
    ["btn_extra_reset_pos"] = "Restablecer posición",
    ["info_extra_button"] = "Coloca el botón de acción extra en el modo Diseño. Aparece durante misiones y encuentros. Al desactivarlo se devuelve a Blizzard tras un /reload.",
    ["wn_306_extra_button"] = "Nuevo — el botón de acción extra ahora forma parte del sistema de barras de acción de TomoMod.",
    ["wn_306_extra_mover"] = "Nuevo — reposiciona el botón de acción extra (y el botón de habilidad de zona) en el modo Diseño, como cualquier otra barra. La posición y la escala se guardan en tu perfil.",
    ["wn_306_extra_scale"] = "Nuevo — opciones del botón de acción extra en Barras de acción, pestaña Gestión de barras: activar, escala y restablecer posición.",
    ["wn_306_compass"] = "Corrección — Brújula: corregido un error de Lua frecuente (x417) en la conversión de coordenadas mundo (C_Map.GetWorldPosFromMapPos devuelve continentID + worldPosition; el continentID ahora se descarta correctamente).",
    ["wn_306_bagskin"] = "BagSkin — los slots ahora usan ContainerFrameItemButtonTemplate de Blizzard: clic, uso, recoger y dividir son gestionados por código seguro nativo (sin más PreClick con riesgo de taint). Los slots diferidos en combate se repiten automáticamente al salir del combate.",
    -- 3.0.7
    ["wn_307_objective_tracker"] = "Seguimiento de objetivos — Los bloques de misiones mundiales ahora se clasifican en el grupo Misiones Mundiales en lugar de flotar sobre el rastreador. Las barras de progreso (fuerzas enemigas, % semanal) se ocultan cuando su grupo está contraído.",
    ["wn_307_guardian_rage"]     = "Barras de recursos — Los druidas Guardianes ven ahora su barra de Rabia centrada en pantalla por defecto. El maná permanece como barra secundaria. La barra de poder del marco de unidad se oculta automáticamente.",
    ["wn_307_resource_bars"]     = "Barras de recursos — Corregido: los controles de altura para poder de clase y maná de druida ahora se aplican correctamente (conflicto de nombre de frame global resuelto). Nuevo control para la altura de la barra central. Nueva casilla en Marcos de unidad › Jugador › Dimensiones.",
    ["wn_310_brez_counter"]       = "Contador de resurrección de combate — Nuevo HUD móvil que muestra cuántas resurrecciones de combate están disponibles y el tiempo hasta la próxima carga. Lee el pool compartido, funciona en cualquier clase. Configurable en Marcos de raid → Características.",
    ["wn_310_resurrect"]          = "Indicador de resurrección — Ahora aparece un icono de rez en un miembro del grupo o raid mientras se está lanzando una resurrección sobre él.",
    ["wn_310_raid_sizes"]         = "Marcos de raid — Nuevas disposiciones opcionales por tamaño (10 / 25 / 40): el ancho y alto de los marcos se adaptan automáticamente al tamaño del grupo actual. Configurable en Marcos de raid → Características.",
    ["wn_310_brez_fix"]           = "Marcos de grupo — Corregido: el rastreador de enfriamiento de resurrección de combate ahora muestra correctamente el icono en gris y el temporizador de recarga cuando se consume un brez por cualquiera en la instancia.",

    -- 3.1.1
    ["art_searching"]        = "Buscando: %s",
    ["art_searching_qty"]    = "Buscando: %s × %d",
    ["wn_311_icicles"]        = "Mago Escarcha: nuevo rastreador de Carámbanos en la barra de recursos (5 segmentos + brillo de Pico Glacial al máximo). Color personalizable en CD & Recursos → Colores.",
    ["wn_311_taint_money"]   = "Corregido un error de taint (Midnight): pasar el ratón sobre objetos en el Compendio de bandas ya no provoca el error de 'número secreto' en el valor de oro — TomoMod ya no contamina las descripciones de comparación.",
    ["wn_311_art_qty"]       = "AuctionRecipeTracker: al hacer clic en un reactivo se busca el objeto en la Casa de subastas y se muestra la cantidad requerida en la barra de estado (ej. Buscando: Fuego Despertado × 14).",

    -- 3.1.2
    ["wn_312_brand"]         = "Color de acento actualizado de #0cd29f a #2ed884 (verde menta) en toda la interfaz — barra de título, paneles, mensajes de chat, ventanas emergentes y valores de color predeterminados.",
    ["wn_312_brand_api"]     = "Nuevas constantes TomoMod_Utils.BRAND / BRAND_DARK / BRAND_HOVER centralizan el color de acento: los paneles de configuración y el tema de Widgets ahora leen desde una única fuente.",
    ["wn_312_companion_fix"] = "CompanionStatus: corregida una fuga de variable global (UpdateIcon se declaraba sin 'local').",

    -- 3.1.3
    ["wn_313_nav"]        = "Interfaz de configuración rediseñada: 16 paneles consolidados en 6 categorías agrupadas (Interfaz, Unidades, Combate, Confort, Herramientas), cada una con su propio color de acento y encabezado.",
    ["wn_313_accent"]     = "Los widgets ahora adoptan automáticamente el color de acento de su panel anfitrión — tarjetas, encabezados, separadores, casillas, botones y pestañas reaccionan al contexto de categoría activo.",
    ["wn_313_segmented"]  = "Nuevo widget SegmentedControl reemplaza los desplegables cortos (Barra de bolsas, Menú Micro, Estilo de chat, Diseño de bolsas, Ordenación, Canal de audio).",
    ["wn_313_dashboard"]  = "Panel de inicio completamente rediseñado: banner hero con estado de diagnóstico en vivo, accesos directos (Instalador, Perfiles, Diagnósticos, Recargar) y controles de módulos renovados.",
    ["wn_313_np_preview"] = "Placas de nombre: nuevo panel de vista previa en tiempo real al inicio de la configuración — muestra aliado, hostil y jefe, se actualiza al cambiar anchura, altura, barra de conjuro y tamaño de fuente.",
    ["wn_313_loot_filter"] = "Corrección del filtro de clase de botín: los objetos sin entrada en el IDB (p. ej. drops de nuevos raids) ahora usan el tipo de armadura como alternativa en lugar de mostrarse a todas las clases.",
    ["wn_313_sporefall"]   = "Datos de botín: raid Sporefall (ejEncounterID 2711) añadido con 15 objetos desde KeystoneLoot build 12.0.7.",
    ["wn_313_diag"]       = "Diagnósticos: 7 nuevas palabras clave de exclusión UIError (comerciante, montura, inventario, eliminar, mejora, apariencia, duelo) + la consola ahora siempre aparece encima del menú de configuración.",
    ["wn_313_tooltip_anchor"] = "Posición del tooltip: nuevo sistema de anclaje con 4 modos — Predeterminado, Cursor (sigue el ratón), Esquina (anclado en una esquina de la pantalla) y Personalizado (marco arrastrable).",

    -- Anclaje del tooltip
    ["opt_tooltip_anchor"]        = "Posición del tooltip",
    ["tooltip_anchor_default"]    = "Predeterminado",
    ["tooltip_anchor_cursor"]     = "Cursor",
    ["tooltip_anchor_corner"]     = "Esquina de pantalla",
    ["tooltip_anchor_custom"]     = "Personalizado",
    ["opt_tooltip_anchor_corner"] = "Esquina (modo Esquina)",
    ["corner_br"]                 = "Inferior derecha",
    ["corner_bl"]                 = "Inferior izquierda",
    ["corner_tr"]                 = "Superior derecha",
    ["corner_tl"]                 = "Superior izquierda",
    ["info_tooltip_anchor"]       = "Personalizado: selecciona este modo y arrastra el marco teal a la posición deseada.",
    ["btn_tooltip_toggle_anchor"] = "Mostrar/Ocultar el ancla",
    ["mover_tooltip_anchor"]      = "Ancla del tooltip",

    -- Nameplates preview
    ["np_preview_title"]   = "Vista previa de placas",
    ["np_preview_hint"]    = "Legibilidad rápida: color, conjuro, auras y amenaza en un solo lugar.",
    ["preview_np_friendly"] = "Aliado",
    ["preview_np_target"]  = "Objetivo hostil",
    ["preview_np_boss"]    = "Jefe marcado",

    -- 3.1.4
    ["wn_314_tooltip_anchor"] = "Posición del tooltip: nuevo sistema de 4 modos — Predeterminado, Cursor (sigue el ratón), Esquina (esquina de pantalla) y Personalizado (marco arrastrable). Configurable en Skins → Tooltip.",
    ["wn_314_locale_fix"]     = "Corregidas las etiquetas de color del tooltip que faltaban: los selectores de color de fondo y borde en Skins → Tooltip ahora se muestran correctamente.",

    -- 3.1.5
    ["wn_315_ot_itembutton"] = "Rastreador de objetivos: los botones de objeto de misión ahora se ocultan correctamente al contraer su categoría (el botón está vinculado al rastreador nativo, no al bloque — antes permanecía visible sobre las categorías contraídas).",
    ["wn_315_talkinghead"] = "QOL: la opción «Ocultar Talking Head» vuelve al GUI de configuración (QOL → Automatizaciones). Ahora se aplica al instante sin /reload y es reversible — al desmarcarla se restauran los diálogos de desplazamiento.",

    -- 3.1.6
    ["wn_316_party_combat"] = "Marcos de grupo: corregidos errores de visibilidad cuando un miembro se une, abandona, o el grupo se convierte en banda en pleno combate — los marcos ahora se muestran/ocultan de forma fiable en cualquier situación.",
    ["wn_316_raid_combat"] = "Marcos de banda: corregido que los marcos se quedaran visibles u ocultos al unirse o abandonar miembros de la banda durante el combate — la visibilidad ahora la gestiona un sistema seguro y compatible con el combate.",
    ["wn_316_roster_repaint"] = "Marcos de grupo y banda: corregida información obsoleta (color de clase, absorciones, resaltado de disipación) que mostraba brevemente al jugador equivocado tras un cambio de composición, incluso en combate.",
    ["wn_317_cdm_holders"] = "Gestor de cooldowns: nuevo sistema de 'Holders' — mueve y bloquea libremente cada visor de cooldown (Esencial, Utilidad, Iconos de buff, Barras de buff) independientemente de la cuadrícula del Modo Edición de Blizzard, con vista previa en vivo de iconos/barras mientras están vacíos.",
    ["wn_317_resourcebars_health"] = "Barras de recursos: nueva barra de vida opcional — altura configurable, formato (%, valor o ambos), relleno con color de clase, animación suave y un umbral de color para vida baja.",
    ["wn_317_config_cards"] = "Interfaz de configuración: el panel de Cooldown y Recursos ahora tiene un diseño de tarjetas y una nueva pestaña Barras que agrupa todos los ajustes de la barra de vida.",
    ["wn_316_locale_cdm"] = "Corregido: la pestaña Barras, las tarjetas de colocación/vista previa en vivo y la sección de barra de vida y animaciones mostraban claves sin traducir en lugar de texto traducido — traducido en los 6 idiomas.",
    ["wn_316_taint_chat"] = "Corregido un error de taint ('secret string value') en el skin del chat al recibir mensajes de canal.",
    ["wn_316_taint_skyride"] = "Corregido un error de taint ('secret number value') en la barra de velocidad de Skyriding, causado por los valores protegidos de velocidad de vuelo/planeo del juego.",
    ["wn_316_durability_pos"] = "Minimapa: la posición del texto de durabilidad ahora es configurable (esquina + desplazamiento X/Y) en Interfaz → General → Info Panel — útil para evitar la superposición con el nuevo botón de expansión del parche 12.0.7.",

    -- 3.1.7
    ["wn_317_libserialize_namespace"] = "Perfiles: la biblioteca LibSerialize incorporada ahora usa un espacio de nombres privado ('TomoSerialize-1.0') en lugar del nombre compartido 'LibSerialize', evitando conflictos de exportación/importación con otros addons que también incorporan LibSerialize.",
    ["wn_317_drag_absolute_coords"] = "Marcos movibles: corregido que las posiciones guardadas se desviaran o invirtieran tras arrastrar en la Barra de nivel, Movers, AuctionRecipeTracker, el Rastreador Mítico+, TomoScore, Frame Anchors, Bag Skin, las barras de lanzamiento, los anclajes de marcos de grupo/banda, la Brújula, la Barra de consumibles, el Explorador de botín, el Minimapa, el Rastreador de objetivos, la barra de Skyriding, las Barras de recursos y los UnitFrames — las posiciones ahora se guardan como coordenadas absolutas de pantalla, estables.",
    ["wn_317_ot_combat_taint"] = "Rastreador de objetivos: corregido un posible error de taint cuando Blizzard vuelve a mostrar un bloque de categoría de misión contraído durante una actualización de misión en pleno combate.",
    ["wn_317_deadcode_cleanup"] = "Limpieza interna: se eliminaron varios módulos no utilizados/desactivados para reducir el tamaño del addon — no se vio afectada ninguna función visible para el usuario.",
    ["wn_317_raidmanager_fix"] = "Marcos de banda: corregido que el panel de líder de grupo predeterminado de Blizzard (comprobación de preparación, marcadores de objetivo de banda, convertir en banda, límite de pings, abandonar grupo) se ocultara junto con los marcos de banda al activar «Ocultar marcos de banda de Blizzard» — ahora solo se suprime el contenedor de marcos de miembros, la barra de herramientas del líder permanece disponible.",
    ["wn_317_groupmanager_skin"] = "Marcos de banda: la opción «Reskinear el panel de líder de grupo» ahora aplica un reskin completo a la barra de herramientas de Blizzard con el tema oscuro/verde menta de TomoMod — menús desplegables de modo y límite de pings, filtros de rol/grupo, botones de la barra de herramientas (modo edición, ajustes, comprobación de preparación, encuesta de rol, cuenta atrás), botones de marcadores de banda con sus pestañas Unidad/Suelo, y botones de abandonar grupo con estilo rojo — todo ello sin alterar ningún icono de Blizzard, y con cambio en vivo sin necesidad de recargar.",
    ["wn_317_groupmanager_collapsetab"] = "Marcos de banda: corregido que el interruptor de colapso del panel de líder de grupo dejaba una franja residual en el borde de la pantalla, ahora con una auténtica pestaña verde menta en lugar de un simple botón reskinneado.",

    -- 3.1.8
    ["wn_318_bagskin_itemclass_enum"] = "Bag Skin: la coincidencia de categorías ahora usa las constantes Enum.ItemClass de Blizzard (con reserva numérica) en lugar de números de clase de objeto codificados, manteniendo la categorización correcta en todos los clientes.",
    ["wn_318_bagskin_cat_order"] = "Bag Skin: orden de categorías predeterminado actualizado — los Objetos de misión ahora se agrupan justo después del Equipo, antes de los Consumibles y los Materiales.",
    ["wn_318_bagskin_cat_foundation"] = "Bag Skin: se añadió la base interna para una futura opción de ocultar/reordenar categorías — Miscelánea y Espacios libres siempre permanecen visibles para que ningún objeto pueda desaparecer nunca.",

    -- 3.1.9
    ["wn_319_ot_mover_fix"] = "Rastreador de objetivos: corregido que la posición del ancla a veces se reiniciaba sola (el Modo Edición de Blizzard podía sobrescribirla silenciosamente) — ahora arrastrarlo se mantiene de forma fiable.",
    ["wn_319_ot_quest_limit"] = "Rastreador de objetivos: corregido que el control «Máx. misiones mostradas» no tenía ningún efecto en el diseño por Categorías predeterminado.",
    ["wn_319_minimap_drift"] = "Minimapa: corregido que el minimapa a veces se movía solo a otra posición tras un /reload.",
    ["wn_319_minimap_collector"] = "Minimapa: corregido que el recolector de botones seguía ocultando los botones de otros addons tras un reload incluso estando desactivado.",
    ["wn_319_minimap_tracking"] = "Minimapa: corregido que el botón de rastreo a veces desaparecía, y que el botón de rastreo nativo de Blizzard quedaba sin poder pulsarse tras revelarse.",
    ["wn_319_repbar_hide"] = "Barra de reputación: corregida la barra de reputación/honor propia de Blizzard que a veces seguía mostrándose con la opción «Ocultar barra de reputación de Blizzard» activada.",
    ["wn_319_tooltip_bg"] = "Tooltip: fondo predeterminado menos transparente (opacidad 92% → 97%) — sigue siendo totalmente ajustable mediante el control de opacidad del fondo.",
    ["wn_319_tooltip_anchor"] = "Tooltip: el ancla de posición «Personalizado» ya no permanece visible en pantalla fuera del modo Layout, y se añadió un nuevo botón «Mostrar/Ocultar el ancla» en Skins → Tooltip.",
    ["wn_319_diag_copy"] = "Diagnóstico: corregido que el botón «Copy Report» parecía no hacer nada — la ventana de exportación podía abrirse oculta detrás de la consola.",
})

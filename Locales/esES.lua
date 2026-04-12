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

    -- =====================
    -- CONFIG: General Panel
    -- =====================
    ["section_about"]                   = "Acerca de",
    ["about_text"]                      = "|cff0cd29fTomoMod|r v2.8.11 por TomoAniki\nInterfaz ligera con QOL, UnitFrames y Nameplates.\nEscribe /tm help para la lista de comandos.",
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
    ["info_cdm_editmode"]               = "La colocación se realiza mediante el Edit Mode de Blizzard (Esc |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Edit Mode).",

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
    ["popup_rename_profile"]            = "|cff0cd29fTomoMod|r\n\nNuevo nombre para '%s':",
    ["popup_duplicate_profile"]         = "|cff0cd29fTomoMod|r\n\nDuplicar '%s' como:",
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
    ["time_tooltip_left_click"]         = "|cff0cd29fClic izquierdo:|r Calendario",
    ["time_tooltip_right_click"]        = "|cff0cd29fClic derecho:|r Servidor / Local",
    ["time_tooltip_shift_right"]        = "|cff0cd29fShift + Clic derecho:|r 12h / 24h",
    ["time_format_msg"]                 = "Formato: %s",
    ["time_mode_msg"]                   = "Hora: %s",

    -- =====================
    -- ENABLED / DISABLED (generic)
    -- =====================
    ["enabled"]                         = "Activado",
    ["disabled"]                        = "Desactivado",

    -- Static Popups
    ["popup_reset_text"]                = "|cff0cd29fTomoMod|r\n\n¿Reiniciar TODOS los ajustes?\nEsto recargará tu interfaz.",
    ["popup_confirm"]                   = "Confirmar",
    ["popup_cancel"]                    = "Cancelar",
    ["popup_import_text"]               = "|cff0cd29fTomoMod|r\n\n¿Importar ajustes?\nEsto SOBRESCRIBIRÁ todos tus ajustes actuales y recargará la interfaz.",
    ["popup_profile_reload"]            = "|cff0cd29fTomoMod|r\n\nModo de perfil cambiado.\n¿Recargar interfaz para aplicar?",
    ["popup_delete_profile"]            = "|cff0cd29fTomoMod|r\n\n¿Eliminar perfil '%s'?\nEsta acción no se puede deshacer.",

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
    ["btn_layout"]                      = "Layout",
    ["btn_layout_tooltip"]              = "Modo Layout: desbloquea todos los elementos para moverlos.",
    ["btn_reload_ui"]                   = "Recargar interfaz",
    ["layout_mode_title"]               = "TomoMod — Modo Layout",
    ["layout_mode_hint"]                = "Arrastra los elementos para reposicionar — haz clic en Bloquear cuando termines",
    ["layout_btn_lock"]                 = "Bloquear",
    ["layout_btn_reload"]               = "RL",
    ["grid_dimmed"]                    = "Cuadrícula",
    ["grid_bright"]                    = "Cuadrícula +",
    ["grid_disabled"]                  = "Cuadrícula OFF",
    ["layout_unlocked"]                 = "Modo Layout ACTIVO — arrastra los elementos. Haz clic en Bloquear o /tm layout cuando termines.",
    ["layout_locked"]                   = "Modo Layout DESACTIVADO — posiciones guardadas.",
    ["msg_help_layout"]                 = "Alternar modo Layout (mover todos los elementos UI)",
    ["mover_unitframes"]                = "Unit Frames",
    ["mover_resources"]                 = "Barras de recursos",
    ["mover_skyriding"]                 = "Barra de Skyriding",
    ["mover_levelingbar"]               = "Barra XP / Experiencia",
    ["mover_anchors"]                   = "Anclas de alertas y botín",
    ["mover_cotank"]                    = "Rastreador de Co-Tank",
    ["mover_repbar"]                    = "Barra de reputación",
    ["mover_castbar"]                   = "Barra de lanzamiento (jugador)",
    ["mover_mythictracker"]             = "Tracker M+",

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
    ["tmt_unlock_msg"]              = "|cff0cd29fTomoMod|r M+ Tracker: Marco desbloqueado \226\128\148 arrastra para reposicionar.",
    ["tmt_lock_msg"]                = "|cff0cd29fTomoMod|r M+ Tracker: Marco bloqueado.",
    ["tmt_reset_msg"]               = "|cff0cd29fTomoMod|r M+ Tracker: Posición reiniciada.",
    ["tmt_unknown_cmd"]             = "|cff0cd29fTomoMod|r M+ Tracker: Comando desconocido.",
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
    ["tmt_preview_active"]          = "|cff0cd29fTomoMod|r M+ Tracker: Vista previa activa \226\128\148 |cFF55B400/tmt lock|r para bloquear.",

    -- MythicHub
    ["mhub_title"]                  = "Puntuaci\195\179n M\195\173tica+",
    ["mhub_col_dungeon"]            = "Mazmorra",
    ["mhub_col_level"]              = "Nivel",
    ["mhub_col_rating"]             = "Puntuaci\195\179n",
    ["mhub_col_best"]               = "Mejor",
    ["mhub_tp_click"]               = "Clic para teletransportarte",
    ["mhub_tp_not_available"]        = "Teletransporte no aprendido",
    ["mhub_tp_not_learned"]          = "|cff0cd29fTomoMod|r: Hechizo de teletransporte no aprendido.",
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
    ["ins_header_title"]             = "|cff0cd29fTomo|r|cffe4e4e4Mod|r  \226\128\148  Asistente de configuraci\195\179n",
    ["ins_step_counter"]             = "Paso %d / %d",
    ["ins_btn_prev"]                 = "|TInterface\\BUTTONS\\UI-SpellbookIcon-PrevPage:0|t Anterior",
    ["ins_btn_next"]                 = "Siguiente |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t",
    ["ins_btn_finish"]               = "Finalizar |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t",
    ["ins_btn_skip"]                 = "Omitir instalaci\195\179n",

    -- Step 1: Welcome
    ["ins_step1_title"]              = "Bienvenido a TomoMod",
    ["ins_subtitle"]                 = "Suite de interfaz y QOL para The War Within",
    ["ins_welcome_desc"]             = "Este asistente te guiar\195\161 en |cff0cd29f12 pasos|r para configurar TomoMod seg\195\186n\ntus preferencias: perfil, skins, nameplates, barras de acci\195\179n, sonido, Mythic+,\noptimizaciones, QOL y SkyRide.\n\nTodas estas opciones pueden cambiarse en cualquier momento con |cff0cd29f/tm|r.",

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
    ["ins_done_recap"]               = "Tu configuraci\195\179n de TomoMod est\195\161 guardada. Algunos recordatorios:\n\n|cff0cd29f/tm|r              |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Abrir el panel de configuraci\195\179n\n|cff0cd29f/tm sr|r           |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Desbloquear y mover elementos\n|cff0cd29f/tm install|r      |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Relanzar este instalador\n\nTodas las opciones configuradas aqu\195\173 pueden cambiarse en cualquier momento\ndesde los paneles correspondientes en la GUI de TomoMod.\n\nSe necesita un |cff0cd29freload de la UI|r para aplicar ciertos cambios\n(nameplates, skins, UnitFrames).",
    ["ins_done_reload"]              = "|TInterface\\BUTTONS\\UI-RefreshButton:0|t  Recargar UI",

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
    ["info_relaunch_installer"]      = "Inicia el asistente de configuraci\195\179n de 12 pasos.",
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
    ["bagskin_de_tooltip"]               = "|cff0cd29f[Clic derecho]|r Desencantar",
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

    -- =====================
    -- Resource Bars display mode
    -- =====================
    ["opt_rb_display_mode"]             = "Modo de visualización",
    ["display_mode_icons"]              = "Iconos (texturas GW2)",
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
    ["opt_tooltip_font_size"]            = "Tamaño de fuente",
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
    ["ts_reset_msg"]                = "|cff0cd29fTomoMod|r Marcador: Posición reiniciada.",
    ["ts_no_data"]                  = "|cff0cd29fTomoMod|r Marcador: No hay datos de mazmorra disponibles.",
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
})
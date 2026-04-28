-- =====================================
-- ptBR.lua — Português (Brasil)
-- =====================================

TomoMod_RegisterLocale("ptBR", {

    -- =====================
    -- CONFIG: Categories (ConfigUI.lua)
    -- =====================
    ["cat_general"]         = "Geral",
    ["cat_unitframes"]      = "UnitFrames",
    ["cat_nameplates"]      = "Nameplates",
    ["cat_cd_resource"]     = "CD e Recursos",
    ["cat_qol"]             = "Qualidade de vida",
    ["cat_mythicplus"]      = "Mythic+",
    ["cat_profiles"]        = "Perfis",
    ["cat_diagnostics"]     = "Diagn\195\179sticos",
    ["cat_housing"]         = "Housing",

    -- =====================
    -- CONFIG: General Panel
    -- =====================
    ["section_about"]                   = "Sobre",
    ["about_text"]                      = "|cff0cd29fTomoMod|r %s por TomoAniki\nInterface leve com QOL, UnitFrames e Nameplates.\nDigite /tm help para a lista de comandos.",
    ["section_general"]                 = "Geral",
    ["btn_reset_all"]                   = "Redefinir tudo",
    ["info_reset_all"]                  = "Isso redefinirá TODAS as configurações e recarregará a interface.",

    -- Minimap
    ["section_minimap"]                 = "Minimapa",
    ["opt_minimap_enable"]              = "Ativar minimapa personalizado",
    ["opt_size"]                        = "Tamanho",
    ["opt_scale"]                       = "Escala",
    ["opt_border"]                      = "Borda",
    ["border_class"]                    = "Cor da classe",
    ["border_black"]                    = "Preto",

    -- Info Panel
    ["section_info_panel"]              = "Painel de informações",
    ["opt_enable"]                      = "Ativar",
    ["opt_durability"]                  = "Durabilidade (Equipamento)",
    ["opt_time"]                        = "Hora",
    ["opt_24h_format"]                  = "Formato 24h",
    ["opt_show_coords"]                 = "Mostrar coordenadas",
    ["btn_reset_position"]              = "Redefinir posição",

    -- Cursor Ring
    ["section_cursor_ring"]             = "Anel do cursor",
    ["opt_class_color"]                 = "Cor da classe",
    ["opt_anchor_tooltip_ring"]         = "Ancorar tooltip ao cursor",

    -- =====================
    -- CONFIG: UnitFrames Panel
    -- =====================
    -- Tabs
    ["tab_general"]                     = "Geral",
    ["tab_player"]                      = "Jogador",
    ["tab_target"]                      = "Alvo",
    ["tab_tot"]                         = "AdA",
    ["tab_pet"]                         = "Pet",
    ["tab_focus"]                       = "Foco",
    ["tab_colors"]                      = "Cores",

    -- Sub-tabs (Player, Target, Focus)
    ["subtab_dimensions"]               = "Dimensões",
    ["subtab_display"]                  = "Exibição",
    ["subtab_auras"]                    = "Auras",
    ["subtab_positioning"]              = "Posição",

    -- Sub-labels
    ["sublabel_dimensions"]             = "— Dimensões —",
    ["sublabel_display"]                = "— Exibição —",
    ["sublabel_castbar"]                = "— Barra de lançamento —",
    ["sublabel_auras"]                  = "— Auras —",
    ["sublabel_element_offsets"]        = "— Posições dos elementos —",

    -- Unit display names
    ["unit_player"]                     = "Jogador",
    ["unit_target"]                     = "Alvo",
    ["unit_tot"]                        = "Alvo do alvo",
    ["unit_pet"]                        = "Pet",
    ["unit_focus"]                      = "Foco",

    -- General tab
    ["section_general_settings"]        = "Configurações gerais",
    ["opt_uf_enable"]                   = "Ativar UnitFrames do TomoMod",
    ["opt_hide_blizzard"]               = "Ocultar quadros da Blizzard",
    ["opt_global_font_size"]            = "Tamanho de fonte global",
    ["sublabel_font"]                   = "— Fonte —",
    ["opt_font_family"]                 = "Família de fonte",

    -- Castbar colors
    ["section_castbar_colors"]          = "Cores da barra de lançamento",
    ["info_castbar_colors"]             = "Personalize as cores da barra de lançamento para feitiços interrompíveis, não interrompíveis e interrompidos.",
    ["opt_castbar_color"]               = "Feitiço interrompível",
    ["opt_castbar_ni_color"]            = "Feitiço não interrompível",
    ["opt_castbar_interrupt_color"]     = "Feitiço interrompido",
    ["info_castbar_colors_reload"]      = "As mudanças de cor se aplicam a novos lançamentos. /reload para efeito completo.",
    ["btn_toggle_lock"]                 = "Bloquear/Desbloquear (/tm uf)",
    ["info_unlock_drag"]                = "Desbloqueie para mover os quadros. As posições são salvas automaticamente.",

    -- Per-unit options
    ["opt_width"]                       = "Largura",
    ["opt_health_height"]               = "Altura de vida",
    ["opt_power_height"]                = "Altura de recurso",
    ["opt_show_name"]                   = "Mostrar nome",
    ["opt_name_truncate"]               = "Truncar nomes longos",
    ["opt_name_truncate_length"]        = "Comprimento máx. do nome",
    ["opt_show_level"]                  = "Mostrar nível",
    ["opt_show_health_text"]            = "Mostrar texto de vida",
    ["opt_health_format"]               = "Formato de vida",
    ["fmt_current"]                     = "Atual (25.3K)",
    ["fmt_percent"]                     = "Porcentagem (75%)",
    ["fmt_current_percent"]             = "Atual + % (25.3K | 75%)",
    ["fmt_current_max"]                 = "Atual / Máx",
    ["opt_class_color_uf"]              = "Cor da classe",
    ["opt_faction_color"]               = "Cor de facção (NPC)",
    ["opt_use_nameplate_colors"]        = "Cores de Nameplate (tipo de NPC)",
    ["opt_show_absorb"]                 = "Barra de absorção",
    ["opt_show_threat"]                 = "Indicador de ameaça (brilho de borda)",
    ["section_threat_text"]             = "Texto % de ameaça",
    ["opt_threat_text_enable"]          = "Mostrar % de ameaça no alvo",
    ["opt_threat_text_font_size"]       = "Tamanho de fonte",
    ["opt_threat_text_offset_x"]        = "Deslocamento X",
    ["opt_threat_text_offset_y"]        = "Deslocamento Y",
    ["info_threat_text"]                = "Verde = tanqueando (vantagem), amarelo = aviso, vermelho = aggro perdido",
    ["opt_show_leader_icon"]            = "Ícone de líder",
    ["opt_leader_icon_x"]               = "Ícone de líder X",
    ["opt_leader_icon_y"]               = "Ícone de líder Y",
    ["opt_raid_icon_x"]                 = "Marcador de raid X",
    ["opt_raid_icon_y"]                 = "Marcador de raid Y",

    -- Castbar
    ["opt_castbar_enable"]              = "Ativar barra de lançamento",
    ["opt_castbar_width"]               = "Largura da barra de lançamento",
    ["opt_castbar_height"]              = "Altura da barra de lançamento",
    ["opt_castbar_show_icon"]           = "Mostrar ícone",
    ["opt_castbar_show_timer"]          = "Mostrar temporizador",
    ["info_castbar_drag"]               = "Posição: /tm sr para desbloquear e mover a barra de lançamento.",
    ["btn_reset_castbar_position"]      = "Redefinir posição da barra de lançamento",
    ["opt_castbar_show_latency"]        = "Mostrar latência",

    -- Auras
    ["opt_auras_enable"]                = "Ativar auras",
    ["opt_auras_max"]                   = "Auras máximas",
    ["opt_auras_size"]                  = "Tamanho do ícone",
    ["opt_auras_type"]                  = "Tipo de aura",
    ["aura_harmful"]                    = "Debuffs (prejudiciais)",
    ["aura_helpful"]                    = "Buffs (benéficos)",
    ["aura_all"]                        = "Todos",
    ["opt_auras_direction"]             = "Direção de crescimento",
    ["aura_dir_right"]                  = "Para a direita",
    ["aura_dir_left"]                   = "Para a esquerda",
    ["opt_auras_only_mine"]             = "Apenas minhas auras",

    -- Element offsets
    ["elem_name"]                       = "Nome",
    ["elem_level"]                      = "Nível",
    ["elem_health_text"]                = "Texto de vida",
    ["elem_power"]                      = "Barra de recurso",
    ["elem_castbar"]                    = "Barra de lançamento",
    ["elem_auras"]                      = "Auras",

    -- =====================
    -- CONFIG: Nameplates Panel
    -- =====================
    -- Nameplate tabs
    ["tab_np_auras"]                    = "Auras",
    ["tab_np_advanced"]                 = "Avançado",
    ["info_np_colors_custom"]           = "Cada cor pode ser personalizada clicando na amostra de cor.",

    ["section_np_general"]              = "Configurações gerais",
    ["opt_np_enable"]                   = "Ativar Nameplates do TomoMod",
    ["info_np_description"]             = "Substitui as nameplates da Blizzard por um estilo minimalista personalizável.",
    ["section_dimensions"]              = "Dimensões",
    ["opt_np_name_font_size"]           = "Tamanho de fonte do nome",

    -- Display
    ["section_display"]                 = "Exibição",
    ["opt_np_show_classification"]      = "Mostrar classificação (elite, raro, chefe)",
    ["opt_np_show_absorb"]               = "Mostrar barra de absorção",
    ["opt_np_class_colors"]             = "Cores de classe (jogadores)",
    ["opt_np_friendly_name_only"]       = "Aliados: apenas nome (sem barra de vida)",
    ["opt_np_friendly_role_icons"]      = "Mostrar ícones de função (dungeon/delve)",
    ["opt_np_role_show_tank"]           = "Mostrar ícone de Tank",
    ["opt_np_role_show_healer"]         = "Mostrar ícone de Healer",
    ["opt_np_role_show_dps"]            = "Mostrar ícone de DPS",
    ["opt_np_role_icon_size"]           = "Tamanho do ícone de função",

    -- Raid Marker
    ["section_raid_marker"]             = "Marcador de raide",
    ["opt_np_raid_icon_anchor"]         = "Posição do ícone",
    ["opt_np_raid_icon_x"]              = "Deslocamento X",
    ["opt_np_raid_icon_y"]              = "Deslocamento Y",
    ["opt_np_raid_icon_size"]           = "Tamanho do ícone",

    -- Castbar
    ["section_castbar"]                 = "Barra de lançamento",
    ["opt_np_show_castbar"]             = "Mostrar barra de lançamento",
    ["opt_np_castbar_height"]           = "Altura da barra de lançamento",
    ["color_castbar"]                   = "Barra de lançamento (interrompível)",
    ["color_castbar_uninterruptible"]   = "Barra de lançamento (não interrompível)",

    -- Auras
    ["section_auras"]                   = "Auras",
    ["opt_np_show_auras"]               = "Mostrar auras",
    ["opt_np_aura_size"]                = "Tamanho do ícone",
    ["opt_np_max_auras"]                = "Quantidade máxima",
    ["opt_np_only_my_debuffs"]          = "Apenas meus debuffs",

    -- Enemy Buffs
    ["section_enemy_buffs"]              = "Buffs inimigos",
    ["sublabel_enemy_buffs"]             = "— Buffs inimigos —",
    ["opt_enemy_buffs_enable"]           = "Mostrar buffs inimigos",
    ["opt_enemy_buffs_max"]              = "Máx. buffs",
    ["opt_enemy_buffs_size"]             = "Tamanho do ícone de buff",
    ["info_enemy_buffs"]                 = "Mostra buffs ativos (Enfurecer, escudos...) em unidades hostis. Os ícones aparecem acima à direita, empilhando para cima.",
    ["opt_np_show_enemy_buffs"]          = "Mostrar buffs inimigos",
    ["opt_np_enemy_buff_size"]           = "Tamanho do ícone de buff",
    ["opt_np_max_enemy_buffs"]           = "Máx. buffs inimigos",
    ["opt_np_enemy_buff_y_offset"]       = "Deslocamento Y de buffs inimigos",

    -- Transparency
    ["section_transparency"]            = "Transparência",
    ["opt_np_selected_alpha"]           = "Alfa selecionado",
    ["opt_np_unselected_alpha"]         = "Alfa não selecionado",

    -- Stacking
    ["section_stacking"]                = "Empilhamento",
    ["opt_np_overlap"]                  = "Sobreposição vertical",
    ["opt_np_top_inset"]                = "Limite superior da tela",

    -- Colors
    ["section_colors"]                  = "Cores",
    ["color_hostile"]                   = "Hostil (Inimigo)",
    ["color_neutral"]                   = "Neutro",
    ["color_friendly"]                  = "Amigável",
    ["color_tapped"]                    = "Marcado (tapped)",
    ["color_focus"]                     = "Alvo de foco",

    -- NPC Type Colors
    ["section_npc_type_colors"]         = "Cores por tipo de NPC",
    ["color_caster"]                    = "Lançador de feitiços",
    ["color_miniboss"]                  = "Mini-chefe (elite + nível superior)",
    ["color_enemy_in_combat"]           = "Inimigo (padrão)",
    ["info_np_darken_ooc"]              = "Inimigos fora de combate são escurecidos automaticamente.",

    -- Classification colors
    ["section_classification_colors"]   = "Cores de classificação",
    ["opt_np_use_classification"]       = "Cores por tipo de inimigo",
    ["color_boss"]                      = "Chefe",
    ["color_elite"]                     = "Elite / Mini-chefe",
    ["color_rare"]                      = "Raro",
    ["color_normal"]                    = "Normal",
    ["color_trivial"]                   = "Trivial",

    -- Tank mode
    ["section_tank_mode"]               = "Modo tanque",
    ["opt_np_tank_mode"]                = "Ativar modo tanque (cores de ameaça)",
    ["color_no_threat"]                 = "Sem ameaça",
    ["color_low_threat"]                = "Ameaça baixa",
    ["color_has_threat"]                = "Ameaça mantida",
    ["color_dps_has_aggro"]             = "DPS/Curandeiro tem aggro",
    ["color_dps_near_aggro"]            = "DPS/Curandeiro perto do aggro",

    -- NP health format
    ["np_fmt_percent"]                  = "Porcentagem (75%)",
    ["np_fmt_current"]                  = "Atual (25.3K)",
    ["np_fmt_current_percent"]          = "Atual + %",

    -- Reset
    ["btn_reset_nameplates"]            = "Redefinir Nameplates",

    -- =====================
    -- CONFIG: CD & Resource Panel
    -- =====================
    -- Resource colors
    ["section_resource_colors"]         = "Cores de recursos",
    ["res_runes_ready"]                 = "Runas (prontas)",
    ["res_runes_cd"]                    = "Runas (recarga)",

    -- Cooldown Manager
    ["tab_cdm"]                         = "Recargas",
    ["tab_resource_bars"]               = "Barras de recursos",
    ["tab_text_position"]               = "Texto e posição",
    ["tab_rb_colors"]                   = "Cores",
    ["info_rb_colors_custom"]           = "Cada cor pode ser personalizada clicando na amostra de cor.",

    ["section_cdm"]                     = "Gerenciador de recargas",
    ["opt_cdm_enable"]                  = "Ativar gerenciador de recargas",
    ["info_cdm_description"]            = "Reskin dos ícones do CooldownManager da Blizzard: bordas arredondadas, overlay de classe em auras ativas, cores de varredura personalizadas, esmaecimento de utilitários, layout centralizado. Posicionamento pelo Edit Mode da Blizzard.",
    ["opt_cdm_show_hotkeys"]            = "Mostrar atalhos de teclado",
    ["opt_cdm_combat_alpha"]            = "Modificar opacidade (combate / alvo)",
    ["opt_cdm_alpha_combat"]            = "Alfa em combate",
    ["opt_cdm_alpha_target"]            = "Alfa com alvo (fora de combate)",
    ["opt_cdm_alpha_ooc"]               = "Alfa fora de combate",
    ["section_cdm_overlay"]             = "Overlay e bordas",
    ["opt_cdm_custom_overlay"]          = "Cor de overlay personalizada",
    ["opt_cdm_overlay_color"]           = "Cor do overlay",
    ["opt_cdm_custom_swipe"]            = "Cor de varredura ativa personalizada",
    ["opt_cdm_swipe_color"]             = "Cor da varredura",
    ["opt_cdm_swipe_alpha"]             = "Opacidade da varredura",
    ["section_cdm_utility"]             = "Utilitário",
    ["opt_cdm_dim_utility"]             = "Esmaecer ícones utilitários fora de CD",
    ["opt_cdm_dim_opacity"]             = "Opacidade de esmaecimento",
    ["opt_cdm_bufficon_direction"]        = "Direção ícones de buff",
    ["opt_cdm_buffbar_direction"]         = "Direção BuffBar",
    ["opt_cdm_buffbar_width"]             = "Largura barra (horizontal)",
    ["buffbar_vertical"]                  = "Vertical",
    ["buffbar_horizontal"]                = "Horizontal",
    ["dir_centered"]                      = "Centralizado (horizontal)",
    ["dir_left"]                          = "Esquerda",
    ["dir_right"]                         = "Direita",
    ["dir_up"]                            = "Cima",
    ["dir_down"]                          = "Baixo",
    ["info_cdm_editmode"]               = "O posicionamento é feito pelo Edit Mode da Blizzard (Esc |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Edit Mode).",

    -- Resource Bars
    ["section_resource_bars"]           = "Barras de recursos",
    ["opt_rb_enable"]                   = "Ativar barras de recursos",
    ["info_rb_description"]             = "Mostra recursos de classe (Mana, Fúria, Energia, Pontos de combo, Runas, etc.) com suporte adaptativo para Druidas.",
    ["section_visibility"]              = "Visibilidade",
    ["opt_rb_visibility_mode"]          = "Modo de visibilidade",
    ["vis_always"]                      = "Sempre visível",
    ["vis_combat"]                      = "Apenas em combate",
    ["vis_target"]                      = "Combate ou alvo",
    ["vis_hidden"]                      = "Oculto",
    ["opt_rb_combat_alpha"]             = "Alfa em combate",
    ["opt_rb_ooc_alpha"]                = "Alfa fora de combate",
    ["opt_rb_width"]                    = "Largura",
    ["opt_rb_classpower_height"]        = "Altura do poder de classe",
    ["opt_rb_druidmana_height"]         = "Altura de mana do druida",
    ["opt_rb_global_scale"]             = "Escala global",
    ["opt_rb_sync_width"]               = "Sincronizar largura com Essential Cooldowns",
    ["btn_sync_now"]                    = "Sincronizar agora",
    ["info_rb_sync"]                    = "Alinha a largura com o EssentialCooldownViewer do CooldownManager da Blizzard.",

    -- Text & Font
    ["section_text_font"]               = "Texto e fonte",
    ["opt_rb_show_text"]                = "Mostrar texto nas barras",
    ["opt_rb_text_align"]               = "Alinhamento do texto",
    ["align_left"]                      = "Esquerda",
    ["align_center"]                    = "Centro",
    ["align_right"]                     = "Direita",
    ["opt_rb_font_size"]                = "Tamanho de fonte",
    ["opt_rb_font"]                     = "Fonte",
    ["font_default_wow"]                = "WoW padrão",

    -- Position
    ["section_position"]                = "Posição",
    ["info_rb_position"]                = "Use /tm uf para desbloquear e mover as barras. A posição é salva automaticamente.",
    ["info_rb_druid"]                   = "As barras se adaptam automaticamente à sua classe e especialização.\nDruida: o recurso muda com a forma (Urso |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Fúria, Gato |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Energia, Equilíbrio |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Poder astral).",

    -- =====================
    -- CONFIG: QOL Panel
    -- =====================
    ["tab_qol_cinematic"]               = "Cinemática",
    ["tab_qol_auto_quest"]              = "Auto missões",
    ["tab_qol_automations"]             = "Automações",
    ["tab_qol_mythic_keys"]             = "Chaves M+",
    ["tab_qol_skyride"]                 = "SkyRide",
    ["tab_qol_action_bars"]             = "Barras de ação",
    ["section_action_bars"]             = "Skin de barras de ação",
    ["cat_action_bars"]                 = "Barras de ação",
    ["opt_abs_enable"]                  = "Ativar skin de barras de ação",
    ["opt_abs_class_color"]             = "Cor da classe para bordas",
    ["opt_abs_shift_reveal"]            = "Segurar Shift para revelar barras ocultas",
    ["sublabel_bar_opacity"]            = "— Opacidade por barra —",
    ["opt_abs_select_bar"]              = "Selecionar barra de ação",
    ["opt_abs_opacity"]                 = "Opacidade",
    ["btn_abs_apply_all_opacity"]       = "Aplicar a todas as barras",
    ["msg_abs_all_opacity"]             = "Opacidade definida em %d%% em todas as barras",
    ["sublabel_bar_combat"]             = "— Visibilidade em combate —",
    ["opt_abs_combat_show"]             = "Mostrar apenas em combate",

    ["section_cinematic"]               = "Pular cinemáticas",
    ["opt_cinematic_auto_skip"]         = "Pular automaticamente após assistir uma vez",
    ["info_cinematic_viewed"]           = "Cinemáticas já assistidas: %s\nO histórico é compartilhado entre personagens.",
    ["btn_clear_history"]               = "Limpar histórico",

    -- Auto Quest
    ["section_auto_quest"]              = "Auto missões",
    ["opt_quest_auto_accept"]           = "Aceitar missões automaticamente",
    ["opt_quest_auto_turnin"]           = "Entregar missões automaticamente",
    ["opt_quest_auto_gossip"]           = "Selecionar diálogos automaticamente",
    ["info_quest_shift"]                = "Segure SHIFT para desativar temporariamente.\nMissões com múltiplas recompensas não são entregues automaticamente.",

    -- Objective Tracker Skin
    ["tab_qol_obj_tracker"]             = "Rastreador",
    ["section_obj_tracker"]             = "Skin do rastreador de objetivos",
    ["opt_obj_tracker_enable"]          = "Ativar skin do rastreador",
    ["opt_obj_tracker_bg_alpha"]        = "Opacidade do fundo",
    ["opt_obj_tracker_border"]          = "Mostrar borda",
    ["opt_obj_tracker_hide_empty"]      = "Ocultar se vazio",
    ["opt_obj_tracker_header_size"]     = "Tamanho de fonte do cabeçalho",
    ["opt_obj_tracker_cat_size"]        = "Tamanho de fonte de categoria",
    ["opt_obj_tracker_quest_size"]      = "Tamanho de fonte do título da missão",
    ["opt_obj_tracker_obj_size"]        = "Tamanho de fonte do objetivo",
    ["opt_obj_tracker_max_quests"]       = "Máx. missões mostradas (0 = sem limite)",
    ["ot_overflow_text"]                 = "%d missão(ões) oculta(s)...",
    ["info_obj_tracker"]                = "Aplica um skin escuro ao rastreador de objetivos da Blizzard com um painel, fontes personalizadas e cabeçalhos de categoria coloridos.",
    ["ot_header_title"]                 = "OBJETIVOS",
    ["ot_header_options"]               = "Opções",

    -- Automations
    ["section_automations"]             = "Automações",
    ["opt_hide_blizzard_castbar"]       = "Ocultar barra de lançamento da Blizzard",

    -- Auto Accept Invite
    ["sublabel_auto_accept_invite"]     = "— Aceitar convite automaticamente —",
    ["sublabel_auto_skip_role"]         = "— Pular verificação de papel —",
    ["sublabel_tooltip_ids"]            = "— IDs de Tooltip —",
    ["sublabel_combat_res_tracker"]     = "— Rastreador de res. em combate —",
    ["opt_cr_show_rating"]              = "Mostrar pontuação M+",
    ["opt_show_messages"]               = "Mostrar mensagens no chat",
    ["opt_tid_spell"]                   = "ID de feitiço / aura",
    ["opt_tid_item"]                    = "ID de item",
    ["opt_tid_npc"]                     = "ID de NPC",
    ["opt_tid_quest"]                   = "ID de missão",
    ["opt_tid_mount"]                   = "ID de montaria",
    ["opt_tid_currency"]                = "ID de moeda",
    ["opt_tid_achievement"]             = "ID de conquista",
    ["opt_accept_friends"]              = "Aceitar de amigos",
    ["opt_accept_guild"]                = "Aceitar da guilda",

    -- Auto Summon
    ["sublabel_auto_summon"]            = "— Auto invocação —",
    ["opt_summon_delay"]                = "Atraso (segundos)",

    -- Auto Fill Delete
    ["sublabel_auto_fill_delete"]       = "— Auto preencher DELETAR —",
    ["opt_focus_ok_button"]             = "Focar botão OK após preencher",

    -- Mythic+ Keys
    ["section_mythic_keys"]             = "Chaves Míticas+",
    ["opt_keys_enable_tracker"]         = "Ativar rastreador",
    ["opt_keys_mini_frame"]             = "Mini-quadro na interface M+",
    ["opt_keys_auto_refresh"]           = "Atualização automática",

    -- SkyRide
    ["section_skyride"]                 = "SkyRide",
    ["opt_skyride_enable"]              = "Ativar (tela de voo)",
    ["section_skyride_dims"]            = "Dimensões",
    ["opt_skyride_bar_height"]          = "Altura da barra de velocidade",
    ["opt_skyride_charge_height"]       = "Altura da barra de carga",
    ["opt_skyride_charge_gap"]          = "Espaço entre segmentos",
    ["section_skyride_text"]            = "Texto",
    ["opt_skyride_show_speed_text"]     = "Mostrar porcentagem de velocidade",
    ["opt_skyride_speed_font_size"]     = "Tamanho de fonte de velocidade",
    ["opt_skyride_show_charge_timer"]   = "Mostrar temporizador de carga",
    ["opt_skyride_charge_font_size"]    = "Tamanho de fonte do temporizador",
    ["btn_reset_skyride"]               = "Redefinir posição do SkyRide",

    -- =====================
    -- CONFIG: QOL — CVar Optimizer
    -- =====================
    ["tab_qol_cvar_opt"]                = "CVars Perf",
    ["section_cvar_optimizer"]          = "Otimizador de CVars",
    ["info_cvar_optimizer"]             = "Aplica ajustes gráficos/desempenho recomendados. Seus valores atuais são salvos e podem ser restaurados a qualquer momento.",
    ["btn_cvar_apply_all"]              = ">> Aplicar tudo",
    ["btn_cvar_revert_all"]             = "<< Restaurar tudo",
    ["btn_cvar_apply"]                  = "Aplicar",
    ["btn_cvar_revert"]                 = "Restaurar",
    -- Categories
    ["opt_cat_render"]                  = "Renderização e tela",
    ["opt_cat_graphics"]                = "Qualidade gráfica",
    ["opt_cat_detail"]                  = "Distância de visão e detalhes",
    ["opt_cat_advanced"]                = "Avançado",
    ["opt_cat_fps"]                     = "Limites de FPS",
    ["opt_cat_post"]                    = "Pós-processamento",
    -- CVar labels
    ["opt_cvar_render_scale"]           = "Escala de renderização",
    ["opt_cvar_vsync"]                  = "VSync",
    ["opt_cvar_msaa"]                   = "Multisampling (MSAA)",
    ["opt_cvar_low_latency"]            = "Modo de baixa latência",
    ["opt_cvar_anti_aliasing"]          = "Anti-aliasing",
    ["opt_cvar_shadow"]                 = "Qualidade de sombras",
    ["opt_cvar_ssao"]                   = "SSAO",
    ["opt_cvar_depth"]                  = "Efeitos de profundidade",
    ["opt_cvar_compute"]                = "Efeitos de cálculo",
    ["opt_cvar_particle"]               = "Densidade de partículas",
    ["opt_cvar_liquid"]                 = "Detalhe de líquidos",
    ["opt_cvar_spell_density"]          = "Densidade de feitiços",
    ["opt_cvar_projected"]              = "Texturas projetadas",
    ["opt_cvar_outline"]                = "Modo de contorno",
    ["opt_cvar_texture_res"]            = "Resolução de texturas",
    ["opt_cvar_view_distance"]          = "Distância de visão",
    ["opt_cvar_env_detail"]             = "Detalhe do ambiente",
    ["opt_cvar_ground"]                 = "Vegetação do solo",
    ["opt_cvar_gfx_api"]                = "API gráfica",
    ["opt_cvar_triple_buffering"]       = "Triple buffering",
    ["opt_cvar_texture_filtering"]      = "Filtragem de texturas",
    ["opt_cvar_rt_shadows"]             = "Sombras ray tracing",
    ["opt_cvar_resample_quality"]       = "Qualidade de reamostragem",
    ["opt_cvar_physics"]                = "Nível de física",
    ["opt_cvar_target_fps"]             = "FPS alvo",
    ["opt_cvar_bg_fps_enable"]          = "Limite de FPS em segundo plano",
    ["opt_cvar_bg_fps"]                 = "Valor de FPS em segundo plano",
    ["opt_cvar_resample_sharpness"]     = "Nitidez de reamostragem",
    ["opt_cvar_camera_shake"]           = "Vibração de câmera",
    -- Messages
    ["msg_cvar_applied"]                = "CVars aplicadas",
    ["msg_cvar_reverted"]               = "CVars restauradas",
    ["msg_cvar_no_backup"]              = "Nenhum backup encontrado — aplique primeiro.",
    ["tab_qol_leveling"]                = "Leveling",
    ["section_leveling_bar"]            = "Barra de experiência",
    ["opt_leveling_enable"]             = "Ativar barra de experiência",
    ["opt_leveling_width"]              = "Largura da barra",
    ["opt_leveling_height"]             = "Altura da barra",
    ["btn_reset_leveling_pos"]          = "Redefinir posição",
    ["leveling_bar_title"]              = "Barra de experiência",
    ["leveling_level"]                  = "Nível",
    ["leveling_progress"]               = "Progresso:",
    ["leveling_rested"]                 = "Descansado",
    ["leveling_last_quest"]             = "Última missão:",
    ["leveling_ttl"]                    = "Tempo para nível:",
    ["leveling_drag_hint"]              = "/tm sr para desbloquear e mover",

    -- =====================
    -- CONFIG: Profiles Panel (3 Tabs)
    -- =====================
    ["tab_profiles"]                    = "Perfis",
    ["tab_import_export"]               = "Importar/Exportar",
    ["tab_resets"]                      = "Redefinição",

    -- Tab 1: Named profiles & specializations
    ["section_named_profiles"]          = "Perfis",
    ["info_named_profiles"]             = "Crie e gerencie perfis nomeados. Cada perfil salva uma cópia completa das suas configurações.",
    ["profile_active_label"]            = "Perfil ativo",
    ["opt_select_profile"]              = "Escolher um perfil",
    ["sublabel_create_profile"]         = "— Criar novo perfil —",
    ["placeholder_profile_name"]        = "Nome do perfil...",
    ["btn_create_profile"]              = "Criar perfil",
    ["btn_delete_named_profile"]        = "Excluir perfil",
    ["btn_save_profile"]                = "Salvar perfil atual",
    ["info_save_profile"]               = "Salva todas as configurações atuais no perfil ativo. Isso é feito automaticamente ao trocar de perfil.",

    ["section_profile_mode"]            = "Modo de perfil",
    ["info_spec_profiles"]              = "Ative perfis por especialização para salvar e carregar configurações automaticamente ao trocar de especialização.\nCada especialização tem sua própria configuração independente.",
    ["opt_enable_spec_profiles"]        = "Ativar perfis por especialização",
    ["profile_status"]                  = "Perfil ativo",
    ["profile_global"]                  = "Global (perfil único)",
    ["section_spec_list"]               = "Especializações",
    ["profile_badge_active"]            = "Ativo",
    ["profile_badge_saved"]             = "Salvo",
    ["profile_badge_none"]              = "Sem perfil",
    ["btn_copy_to_spec"]                = "Copiar atual",
    ["btn_delete_profile"]              = "Excluir",
    ["info_spec_reload"]                = "Trocar de especialização com perfis ativados recarregará automaticamente a interface para aplicar o perfil correspondente.",
    ["info_global_mode"]                = "Todas as especializações compartilham as mesmas configurações. Ative perfis por especialização acima para usar configurações diferentes.",

    -- Tab 2: Import / Export
    ["section_export"]                  = "Exportar configurações",
    ["info_export"]                     = "Gera uma string comprimida de todas as suas configurações atuais.\nCopie para compartilhar ou como backup.",
    ["label_export_string"]             = "String de exportação (clique para selecionar tudo)",
    ["btn_export"]                      = "Gerar string de exportação",
    ["btn_copy_clipboard"]              = "Copiar texto",
    ["section_import"]                  = "Importar configurações",
    ["info_import"]                     = "Cole uma string de exportação abaixo. Ela será validada antes de ser aplicada.",
    ["label_import_string"]             = "Cole a string de importação aqui",
    ["btn_import"]                      = "Importar e aplicar",
    ["btn_paste_clipboard"]             = "Colar texto",
    ["import_preview"]                  = "Classe: %s | Módulos: %s | Data: %s",
    ["import_preview_valid"]            = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t String válida",
    ["import_preview_invalid"]          = "String inválida ou corrompida",
    ["info_import_warning"]             = "A importação SOBRESCREVERÁ todas as suas configurações atuais e recarregará a interface. Esta ação não pode ser desfeita.",

    -- Tab 3: Resets
    ["section_profile_mgmt"]            = "Gerenciamento de perfis",
    ["info_profiles"]                   = "Redefina módulos individuais ou exporte/importe suas configurações.\nExportar copia as configurações para a área de transferência (requer LibSerialize + LibDeflate).",
    ["section_reset_module"]            = "Redefinir um módulo",
    ["btn_reset_prefix"]                = "Redefinir: ",
    ["btn_reset_all_reload"]            = "(!) REDEFINIR TUDO + Recarregar",
    ["section_reset_all"]               = "Redefinição completa",
    ["info_resets"]                     = "Redefine um módulo individual para seus valores padrão. O módulo será recarregado com as configurações de fábrica.",
    ["info_reset_all_warning"]          = "Isso redefinirá TODOS os módulos e TODAS as configurações para os valores de fábrica, e então recarregará a interface.",

    -- =====================
    -- PRINT MESSAGES: Core
    -- =====================
    ["msg_db_reset"]                    = "Banco de dados redefinido",
    ["msg_module_reset"]                = "Módulo '%s' redefinido",
    ["msg_db_not_init"]                 = "Banco de dados não inicializado",
    ["msg_loaded"]                      = "v2.0 carregado — %s para configuração",
    ["msg_report_issue"]                = "Se encontrar algum problema, deixe um comentário no CurseForge.",
    ["msg_help_title"]                  = "v2.0 — Comandos:",
    ["msg_help_open"]                   = "Abrir configuração",
    ["msg_help_reset"]                  = "Redefinir tudo + recarregar",
    ["msg_help_uf"]                     = "Bloquear/Desbloquear UnitFrames + Recursos",
    ["msg_help_uf_reset"]               = "Redefinir UnitFrames",
    ["msg_help_rb"]                     = "Bloquear/Desbloquear barras de recursos",
    ["msg_help_rb_sync"]                = "Sincronizar largura com Essential Cooldowns",
    ["msg_help_np"]                     = "Ativar/desativar Nameplates",
    ["msg_help_minimap"]                = "Redefinir minimapa",
    ["msg_help_panel"]                  = "Redefinir painel de info",
    ["msg_help_cursor"]                 = "Redefinir anel do cursor",
    ["msg_help_clearcinema"]            = "Limpar histórico de cinemáticas",
    ["msg_help_sr"]                     = "Bloquear/Desbloquear SkyRide + Âncoras",
    ["msg_help_key"]                    = "Abrir chaves Míticas+",
    ["msg_help_help"]                   = "Esta ajuda",

    -- =====================
    -- PRINT MESSAGES: Modules
    -- =====================
    -- CDM
    ["msg_cdm_status"]                  = "Ativado",
    ["msg_cdm_disabled"]                = "Desativado",

    -- Nameplates
    ["msg_np_enabled"]                  = "Ativadas",
    ["msg_np_disabled"]                 = "Desativadas",

    -- UnitFrames
    ["msg_uf_locked"]                   = "Bloqueado",
    ["msg_uf_unlocked"]                 = "Desbloqueado — Arraste para reposicionar",
    ["msg_uf_initialized"]              = "Inicializado — /tm uf para bloquear/desbloquear",
    ["msg_uf_enabled"]                  = "ativado (recarga necessária)",
    ["msg_uf_disabled"]                 = "desativado (recarga necessária)",
    ["msg_uf_position_reset"]           = "posição redefinida",

    -- ResourceBars
    ["msg_rb_width_synced"]             = "Largura sincronizada (%dpx)",
    ["msg_rb_locked"]                   = "Bloqueado",
    ["msg_rb_unlocked"]                 = "Desbloqueado — Arraste para reposicionar",
    ["msg_rb_position_reset"]           = "Posição das barras de recursos redefinida",

    -- SkyRide
    ["msg_sr_pos_saved"]                = "Posição do SkyRide salva",
    ["msg_sr_locked"]                   = "SkyRide bloqueado",
    ["msg_sr_unlock"]                   = "Modo de movimento do SkyRide ativado – Clique e arraste",
    ["msg_sr_pos_reset"]                = "Posição do SkyRide redefinida",
    ["msg_sr_db_not_init"]              = "TomoModDB não inicializado",
    ["msg_sr_initialized"]              = "Módulo SkyRide inicializado",

    -- FrameAnchors
    ["anchor_alert"]                    = "Alertas",
    ["anchor_loot"]                     = "Saque",
    ["msg_anchors_locked"]              = "Bloqueados",
    ["msg_anchors_unlocked"]            = "Desbloqueados — mova as âncoras",

    -- AutoVendorRepair
    ["msg_avr_header"]                  = "[AutoVendedorReparar]",
    ["msg_avr_sold"]                    = " Itens cinzas vendidos por |cffffff00%s|r",
    ["msg_avr_repaired"]                = " Equipamento reparado por |cffffff00%s|r",

    -- AutoFillDelete
    ["msg_afd_filled"]                  = "Texto 'DELETAR' preenchido automaticamente – Clique em OK para confirmar",
    ["msg_afd_db_not_init"]             = "TomoModDB não inicializado",
    ["msg_afd_initialized"]             = "Módulo AutoFillDelete inicializado",
    ["msg_afd_enabled"]                 = "Auto-preencher DELETAR ativado",
    ["msg_afd_disabled"]                = "Auto-preencher DELETAR desativado (o hook permanece ativo)",

    -- HideCastBar
    ["msg_hcb_db_not_init"]             = "TomoModDB não inicializado",
    ["msg_hcb_initialized"]             = "Módulo HideCastBar inicializado",
    ["msg_hcb_hidden"]                  = "Barra de lançamento oculta",
    ["msg_hcb_shown"]                   = "Barra de lançamento exibida",

    -- AutoAcceptInvite
    ["msg_aai_accepted"]                = "Convite aceito de ",
    ["msg_aai_ignored"]                 = "Convite ignorado de ",
    ["msg_aai_enabled"]                 = "Auto-aceitar convites ativado",
    ["msg_aai_disabled"]                = "Auto-aceitar convites desativado",
    ["msg_asr_lfg_accepted"]            = "Verificação de papel auto-confirmada",
    ["msg_asr_poll_accepted"]           = "Enquete de papel auto-confirmada",
    ["msg_asr_enabled"]                 = "Auto pular verificação de papel ativado",
    ["msg_asr_disabled"]                = "Auto pular verificação de papel desativado",
    ["msg_tid_enabled"]                 = "Tooltip IDs ativado",
    ["msg_tid_disabled"]                = "Tooltip IDs desativado",
    ["msg_cr_enabled"]                  = "Rastreador de res. em combate ativado",
    ["msg_cr_disabled"]                 = "Rastreador de res. em combate desativado",
    ["msg_cr_locked"]                   = "Rastreador de res. em combate bloqueado",
    ["msg_cr_unlock"]                   = "Rastreador de res. em combate desbloqueado — arraste para mover",
    ["msg_abs_enabled"]                 = "Skin de barras de ação ativado (recarga recomendada)",
    ["msg_abs_disabled"]                = "Skin de barras de ação desativado",
    ["opt_buffskin_enable"]             = "Ativar skin de buffs",
    ["opt_buffskin_desc"]               = "Adiciona bordas pretas e temporizador colorido em buffs/debuffs do jogador",
    ["msg_buffskin_enabled"]            = "Skin de buffs ativado",
    ["msg_buffskin_disabled"]           = "Skin de buffs desativado",
    ["msg_help_cr"]                     = "Bloquear/desbloquear rastreador de res. em combate",
    ["msg_help_cs"]                     = "Bloquear/desbloquear posição da ficha de personagem",
    ["msg_help_cs_reset"]               = "Redefinir posição da ficha de personagem",

    -- CinematicSkip
    ["msg_cin_skipped"]                 = "Cinemática pulada (já assistida)",
    ["msg_vid_skipped"]                 = "Vídeo pulado (já assistido)",
    ["msg_vid_id_skipped"]              = "Vídeo #%d pulado",
    ["msg_cin_cleared"]                 = "Histórico de cinemáticas limpo",

    -- AutoSummon
    ["msg_sum_accepted"]                = "Invocação aceita de %s para %s (%s)",
    ["msg_sum_ignored"]                 = "Invocação ignorada de %s (não confiável)",
    ["msg_sum_enabled"]                 = "Auto-invocação ativada",
    ["msg_sum_disabled"]                = "Auto-invocação desativada",
    ["msg_sum_manual"]                  = "Invocação aceita manualmente",
    ["msg_sum_no_pending"]              = "Sem invocação pendente",

    -- MythicKeys
    ["msg_keys_no_key"]                 = "Sem chave para enviar.",
    ["msg_keys_not_in_group"]           = "Você precisa estar em um grupo.",
    ["msg_keys_reload"]                 = "Mudança aplicada no próximo /reload.",
    ["mk_not_in_group"]                 = "Você não está em um grupo.",
    ["mk_not_in_group_short"]           = "Não está em grupo.",
    ["mk_no_key_self"]                  = "Pedra angular não encontrada.",
    ["mk_title"]                        = "TM — Chaves Míticas",
    ["mk_btn_send"]                     = "Enviar no chat",
    ["mk_btn_refresh"]                  = "Atualizar",
    ["mk_tab_keys"]                     = "Chaves",
    ["mk_tab_tp"]                       = "TP",
    ["mk_tp_click_to_tp"]              = "Clique para se teletransportar",
    ["mk_tp_not_unlocked"]             = "Não desbloqueado",
    ["msg_tp_not_owned"]               = "Você não tem o teletransporte para %s",
    ["msg_tp_combat"]                  = "Não é possível atualizar teletransportes em combate.",

    -- =====================
    -- PRINT MESSAGES: Config Panels
    -- =====================
    ["msg_np_reset"]                    = "Nameplates redefinidas (recarga recomendada)",
    ["msg_uf_toggle"]                   = "UnitFrames %s (recarga)",
    ["msg_profile_reset"]               = "%s redefinido",
    ["msg_profile_copied"]              = "Configurações atuais copiadas para '%s'",
    ["msg_profile_deleted"]             = "Perfil excluído para '%s'",
    ["msg_profile_loaded"]              = "Perfil '%s' carregado — recarga para aplicar",
    ["msg_profile_load_failed"]         = "Erro ao carregar o perfil '%s'",
    ["msg_profile_created"]             = "Perfil '%s' criado com as configurações atuais",
    ["msg_profile_name_empty"]          = "Por favor, insira um nome de perfil",
    ["msg_profile_saved"]               = "Configurações salvas no perfil '%s'",

    -- New profile keys v2.3.0
    ["btn_rename_profile"]              = "Renomear",
    ["btn_duplicate_profile"]           = "Duplicar",
    ["btn_load_profile"]                = "Carregar",
    ["btn_close"]                       = "Fechar",
    ["btn_cancel"]                      = "Cancelar",
    ["section_spec_assign"]             = "Perfis por especialização",
    ["info_spec_assign"]                = "Atribua cada especialização a um perfil nomeado. TomoMod trocará automaticamente de perfil ao mudar de especialização.",
    ["spec_profile_none"]               = "— Nenhum —",
    ["popup_rename_profile"]            = "|cff0cd29fTomoMod|r\n\nNovo nome para '%s':",
    ["popup_duplicate_profile"]         = "|cff0cd29fTomoMod|r\n\nDuplicar '%s' como:",
    ["msg_profile_renamed"]             = "Perfil '%s' renomeado para '%s'",
    ["msg_profile_duplicated"]          = "Perfil '%s' duplicado como '%s'",
    ["msg_import_as_profile"]           = "Perfil importado como '%s'",
    ["popup_export_title"]              = "Exportar perfil",
    ["popup_export_hint"]               = "Selecione tudo (Ctrl+A) e copie (Ctrl+C)",
    ["popup_import_title"]              = "Importar perfil",
    ["popup_import_hint"]               = "Cole uma string de exportação do TomoMod, depois clique em Importar",
    ["label_import_profile_name"]       = "Salvar como nome de perfil:",
    ["placeholder_import_profile_name"] = "Nome do perfil (opcional)...",
    ["msg_profile_name_deleted"]        = "Perfil '%s' excluído",
    ["msg_export_success"]              = "String de exportação gerada — selecione tudo e copie",
    ["msg_import_success"]              = "Configurações importadas com sucesso — recarregando...",
    ["msg_import_empty"]                = "Nada para importar — cole uma string primeiro",
    ["msg_copy_hint"]                   = "Texto selecionado — pressione Ctrl+C para copiar",
    ["msg_copy_empty"]                  = "Gere primeiro uma string de exportação",
    ["msg_paste_hint"]                  = "Pressione Ctrl+V para colar sua string de importação",
    ["msg_spec_changed_reload"]         = "Especialização alterada — carregando perfil...",

    -- =====================
    -- INFO PANEL (Minimap)
    -- =====================
    ["time_server"]                     = "Servidor",
    ["time_local"]                      = "Local",
    ["time_tooltip_title"]              = "Hora (%s - %s)",
    ["time_tooltip_left_click"]         = "|cff0cd29fClique esquerdo:|r Calendário",
    ["time_tooltip_right_click"]        = "|cff0cd29fClique direito:|r Servidor / Local",
    ["time_tooltip_shift_right"]        = "|cff0cd29fShift + Clique direito:|r 12h / 24h",
    ["time_format_msg"]                 = "Formato: %s",
    ["time_mode_msg"]                   = "Hora: %s",

    -- =====================
    -- ENABLED / DISABLED (generic)
    -- =====================
    ["enabled"]                         = "Ativado",
    ["disabled"]                        = "Desativado",

    -- Static Popups
    ["popup_reset_text"]                = "|cff0cd29fTomoMod|r\n\nRedefinir TODAS as configurações?\nIsso recarregará sua interface.",
    ["popup_confirm"]                   = "Confirmar",
    ["popup_cancel"]                    = "Cancelar",
    ["popup_import_text"]               = "|cff0cd29fTomoMod|r\n\nImportar configurações?\nIsso SOBRESCREVERÁ todas as suas configurações atuais e recarregará a interface.",
    ["popup_profile_reload"]            = "|cff0cd29fTomoMod|r\n\nModo de perfil alterado.\nRecarregar interface para aplicar?",
    ["popup_delete_profile"]            = "|cff0cd29fTomoMod|r\n\nExcluir perfil '%s'?\nEsta ação não pode ser desfeita.",

    -- FPS element
    ["label_fps"]                       = "FPS",

    -- =====================
    -- BOSS FRAMES
    -- =====================
    ["tab_boss"]                        = "Chefe",
    ["section_boss_frames"]             = "Barras de chefe",
    ["opt_boss_enable"]                 = "Ativar barras de chefe",
    ["opt_boss_height"]                 = "Altura das barras",
    ["opt_boss_spacing"]                = "Espaço entre barras",
    ["info_boss_drag"]                  = "Desbloqueie (/tm uf) para mover. Arraste Chefe 1 para reposicionar as 5 barras juntas.",
    ["info_boss_colors"]                = "As cores da barra usam cores de classificação de Nameplate (Chefe = vermelho, Mini-chefe = roxo).",
    ["msg_boss_initialized"]            = "Barras de chefe carregadas.",

    -- =====================
    -- SOUND / LUST DETECTION
    -- =====================
    ["cat_sound"]                       = "Som",
    ["section_sound_general"]           = "Som de Bloodlust",
        ["info_sound_desc"]                 = "Reproduz um som personalizado quando um efeito de Bloodlust e detectado. A deteccao verifica diretamente os buffs de Lust e os debuffs Sated/Exhaustion.",
    ["opt_sound_enable"]                = "Ativar detecção de Bloodlust",
    ["sublabel_sound_choice"]           = "Som e canal",
    ["opt_sound_file"]                  = "Som a reproduzir",
    ["opt_sound_channel"]               = "Canal de áudio",
    ["btn_sound_preview"]               = ">> Ouvir som",
    ["btn_sound_stop"]                  = "■  Parar",
    ["opt_sound_force"]                 = "Forçar som mesmo com o jogo no mudo",
    ["opt_sound_chat"]                  = "Mostrar mensagens no chat",
    ["opt_sound_debug"]                 = "Mode debug",

    -- =====================
    -- BAG & MICRO MENU
    -- =====================
    ["tab_qol_bag_micro"]               = "Bolsa e menu",
    ["section_bag_micro"]               = "Barra de bolsa e micro menu",
    ["info_bag_micro"]                  = "Escolha se deseja mostrar sempre ou revelar ao passar o mouse.",
    ["sublabel_bag_bar"]                = "— Barra de bolsa —",
    ["sublabel_micro_menu"]             = "— Micro menu —",
    ["opt_bag_bar_mode"]                = "Barra de bolsa",
    ["opt_micro_menu_mode"]             = "Micro menu",
    ["mode_show"]                       = "Sempre visível",
    ["mode_hover"]                      = "Mostrar ao passar o mouse",

    -- =====================
    -- CHARACTER SKIN
    -- =====================
    ["tab_qol_char_skin"]               = "Skin de personagem",
    ["section_char_skin"]               = "Skin da ficha de personagem",
    ["info_char_skin_desc"]             = "Aplica o tema escuro do TomoMod à ficha de personagem, reputação, moedas e janela de inspeção.",
    ["opt_char_skin_enable"]            = "Ativar skin de personagem",
    ["opt_char_skin_character"]         = "Skin Personagem / Reputação / Moedas",
    ["opt_char_skin_inspect"]           = "Skin janela de inspeção",
    ["opt_char_skin_iteminfo"]          = "Mostrar info do item nos espaços",
    ["opt_char_skin_gems"]              = "Mostrar gemas nos espaços",
    ["opt_char_skin_midnight"]          = "Encantamentos Midnight (Cabeça/Ombros em vez de Pulsos/Capa)",
    ["opt_char_skin_scale"]             = "Escala da janela",
    ["msg_char_skin_reload"]            = "Skin de personagem: /reload para aplicar mudanças.",

    -- =====================
    -- LAYOUT / MOVERS SYSTEM
    -- =====================
    ["btn_layout"]                      = "Layout",
    ["btn_layout_tooltip"]              = "Modo Layout: desbloqueia todos os elementos para movê-los.",
    ["btn_reload_ui"]                   = "Recarregar interface",
    ["layout_mode_title"]               = "TomoMod — Modo Layout",
    ["layout_mode_hint"]                = "Arraste os elementos para reposicionar — clique em Bloquear quando terminar",
    ["layout_btn_lock"]                 = "Bloquear",
    ["layout_btn_reload"]               = "RL",
    ["grid_dimmed"]                    = "Grade",
    ["grid_bright"]                    = "Grade +",
    ["grid_disabled"]                  = "Grade OFF",
    ["layout_unlocked"]                 = "Modo Layout ATIVO — arraste os elementos. Clique em Bloquear ou /tm layout quando terminar.",
    ["layout_locked"]                   = "Modo Layout DESATIVADO — posições salvas.",
    ["msg_help_layout"]                 = "Alternar modo Layout (mover todos os elementos UI)",
    ["mover_unitframes"]                = "Unit Frames",
    ["mover_resources"]                 = "Barras de recursos",
    ["mover_skyriding"]                 = "Barra de Skyriding",
    ["mover_levelingbar"]               = "Barra XP / Experiência",
    ["mover_anchors"]                   = "Âncoras de alertas e saque",
    ["mover_cotank"]                    = "Rastreador de Co-Tank",
    ["mover_repbar"]                    = "Barra de reputação",
    ["mover_castbar"]                   = "Barra de lançamento (jogador)",
    ["mover_mythictracker"]             = "Tracker M+",
    ["mover_chatframe"]                 = "Janela de chat",

    -- =====================
    -- COMBAT TEXT
    -- =====================
    ["sublabel_combat_text"]             = "— Texto de combate —",
    ["opt_combat_text_enable"]           = "Ativar texto de combate",
    ["opt_combat_text_offset_x"]         = "Deslocamento X",
    ["opt_combat_text_offset_y"]         = "Deslocamento Y",

    -- =====================
    -- SKINS (Chat)
    -- =====================
    ["tab_qol_skins"]                    = "Skins",
    ["section_skins"]                    = "Skins da interface",
    ["info_skins_desc"]                  = "Aplica o tema escuro do TomoMod a vários elementos da interface da Blizzard. Pode ser necessário /reload para reverter.",
    ["sublabel_chat_skin"]               = "— Janela de chat —",
    ["opt_chat_skin_enable"]             = "Skin da janela de chat",
    ["opt_chat_skin_style"]              = "Estilo do skin",
    ["opt_chat_skin_style_tui"]          = "TUI (Barra lateral + Janela)",
    ["opt_chat_skin_style_classic"]      = "Clássico (Emoldurado)",
    ["opt_chat_skin_style_glass"]        = "Vidro (Fosco)",
    ["opt_chat_skin_style_minimal"]      = "Mínimo (Sem bordas)",
    ["opt_chat_skin_bg_alpha"]           = "Opacidade do fundo",
    ["opt_chat_skin_font_size"]          = "Tamanho da fonte do chat",
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
    ["opt_buff_skin_enable"]             = "Skinear ícones de Buff/Debuff",
    ["opt_buff_skin_buffs"]              = "Aplicar aos Buffs",
    ["opt_buff_skin_debuffs"]            = "Aplicar aos Debuffs",
    ["opt_buff_skin_color_by_type"]       = "Colorir borda por tipo de debuff (Magia/Veneno/Maldição…)",
    ["opt_buff_skin_teal_border"]         = "Borda verde-azulado nos buffs",
    ["opt_buff_skin_desaturate"]          = "Dessaturar ícones de debuff",
    ["opt_buff_skin_hide_buffs"]         = "Ocultar quadro de Buffs",
    ["opt_buff_skin_hide_debuffs"]       = "Ocultar quadro de Debuffs",
    ["opt_buff_skin_font_size"]          = "Tamanho da fonte do temporizador",

    -- Game Menu Skin
    ["sublabel_game_menu_skin"]          = "— Menu do jogo (Escape) —",
    ["opt_game_menu_skin_enable"]        = "Skinear menu do jogo",
    ["info_game_menu_skin_reload"]       = "Necessário /reload para reverter a skin.",
    ["msg_chat_skin_enabled"]            = "Skin do chat ativado",
    ["msg_chat_skin_disabled"]           = "Skin do chat desativado (reload para reverter)",
    ["sublabel_mail_skin"]               = "— Correio —",
    ["opt_mail_skin_enable"]             = "Skin do correio",
    ["msg_mail_skin_enabled"]            = "Skin do correio ativado",
    ["msg_mail_skin_disabled"]           = "Skin do correio desativado (reload para reverter)",

    -- =====================
    -- WORLD QUEST TAB
    -- =====================
    ["tab_qol_world_quests"]             = "Missões do mundo",
    ["section_wq_tab"]                   = "Aba de missões do mundo",
    ["info_wq_tab_desc"]                 = "Exibe uma lista de missões do mundo disponíveis ao lado do mapa-múndi com detalhes de recompensas, zona, facção e tempo restante. Clique em uma missão para navegar até a zona, Shift-Clique para super-rastrear.",
    ["opt_wq_enable"]                    = "Ativar aba de missões do mundo",
    ["opt_wq_auto_show"]                 = "Mostrar automaticamente ao abrir o mapa",
    ["opt_wq_max_quests"]                = "Máx. missões exibidas (0 = ilimitado)",
    ["opt_wq_min_time"]                  = "Tempo restante mín. (minutos, 0 = todas)",
    ["section_wq_filters"]               = "Filtros de recompensa",
    ["opt_wq_filter_gold"]               = "Mostrar recompensas de ouro",
    ["opt_wq_filter_gear"]               = "Mostrar recompensas de equipamento",
    ["opt_wq_filter_rep"]                = "Mostrar recompensas de reputação",
    ["opt_wq_filter_currency"]           = "Mostrar recompensas de moeda",
    ["opt_wq_filter_anima"]              = "Mostrar recompensas de ânima",
    ["opt_wq_filter_pet"]                = "Mostrar recompensas de mascote",
    ["opt_wq_filter_other"]              = "Mostrar outras recompensas",
    ["wq_tab_title"]                     = "MM Lista",
    ["wq_panel_title"]                   = "Missões do mundo",
    ["wq_col_name"]                      = "Nome",
    ["wq_col_zone"]                      = "Zona",
    ["wq_col_reward"]                    = "Recompensa",
    ["wq_col_time"]                      = "Tempo",
    ["wq_zone"]                          = "Zona",
    ["wq_faction"]                       = "Facção",
    ["wq_reward"]                        = "Recompensa",
    ["wq_time_left"]                     = "Tempo restante",
    ["wq_elite"]                         = "Missão do mundo elite",
    ["wq_sort_time"]                     = "Tempo",
    ["wq_sort_zone"]                     = "Zona",
    ["wq_sort_name"]                     = "Nome",
    ["wq_sort_reward"]                   = "Recompensa",
    ["wq_sort_faction"]                  = "Facção",
    ["wq_status_count"]                  = "Exibindo %d / %d missões",

    -- Profession Helper
    ["tab_qol_prof_helper"]              = "Profissões",
    ["section_prof_helper"]              = "Auxiliar de profissões",
    ["info_prof_helper_desc"]            = "Desencantar, triturar e prospectar itens em lote com uma interface visual.",
    ["opt_prof_helper_enable"]           = "Ativar auxiliar de profissões",
    ["sublabel_prof_de_filters"]         = "— Filtros de qualidade de desencantamento —",
    ["opt_prof_filter_green"]            = "Incluir itens Incomuns (Verdes)",
    ["opt_prof_filter_blue"]             = "Incluir itens Raros (Azuis)",
    ["opt_prof_filter_epic"]             = "Incluir itens Épicos (Roxos)",
    ["btn_prof_open_helper"]             = "Abrir auxiliar de profissões",
    ["ph_title"]                         = "Auxiliar de profissões",
    ["ph_tab_disenchant"]                = "Desencantar",
    ["ph_filter_quality"]                = "Qualidade:",
    ["ph_quality_green"]                 = "Verde",
    ["ph_quality_blue"]                  = "Azul",
    ["ph_quality_epic"]                  = "Épico",
    ["ph_select_all"]                    = "Selecionar tudo",
    ["ph_deselect_all"]                  = "Desmarcar tudo",
    ["ph_btn_process"]                   = "Processar",
    ["ph_btn_click_process"]             = "Clique para processar",
    ["ph_btn_stop"]                      = "Parar",
    ["ph_status_idle"]                   = "Clique em Processar",
    ["ph_status_processing"]             = "Processando %d/%d: %s",
    ["ph_status_done"]                   = "Pronto! Todos os itens processados.",
    ["ph_item_count"]                    = "%d itens disponíveis",
    ["ph_ilvl"]                          = "iLvl %d",

    -- ── Class Reminder ──────────────────────────────────────────
    ["tab_qol_class_reminder"]           = "Lembrete de classe",
    ["section_class_reminder"]           = "Lembrete de buff / forma de classe",
    ["info_class_reminder"]              = "Exibe um texto pulsante no centro da tela quando um buff de classe, forma, postura ou aura estiver ausente.",
    ["opt_class_reminder_enable"]        = "Ativar lembrete de classe",
    ["opt_class_reminder_scale"]         = "Escala do texto",
    ["opt_class_reminder_color"]         = "Cor do texto",
    ["sublabel_class_reminder_pos"]      = "— Deslocamento de posição —",
    ["opt_class_reminder_x"]             = "Deslocamento X",
    ["opt_class_reminder_y"]             = "Deslocamento Y",

    -- Buff / Form names
    ["cr_fortitude"]                     = "Palavra de Poder: Fortitude",
    ["cr_shadowform"]                    = "Forma de Sombra",
    ["cr_arcane_intellect"]              = "Intelecto Arcano",
    ["cr_skyfury"]                       = "Fúria Celeste",
    ["cr_mark_of_the_wild"]              = "Marca da Natureza",
    ["cr_cat_form"]                      = "Forma de Felino",
    ["cr_bear_form"]                     = "Forma de Urso",
    ["cr_moonkin_form"]                  = "Forma de Lua-Coruja",
    ["cr_battle_shout"]                  = "Grito de Batalha",
    ["cr_stance"]                        = "Postura",
    ["cr_aura"]                          = "Aura",
    ["cr_blessing_bronze"]               = "Bênção do Bronze",

    -- =====================
    -- MYTHIC TRACKER (TomoMythic integration)
    -- =====================
    ["tmt_cmd_usage"]               = "|cFF55B400/tmt|r : configurações  |  |cFF55B400unlock|r : mover  |  |cFF55B400lock|r : travar  |  |cFF55B400preview|r : pré-visualizar  |  |cFF55B400key|r : chaves do grupo  |  |cFF55B400kr|r : roleta",
    ["tmt_unlock_msg"]              = "|cff0cd29fTomoMod|r M+ Tracker: Moldura destravada \226\128\148 arraste para reposicionar.",
    ["tmt_lock_msg"]                = "|cff0cd29fTomoMod|r M+ Tracker: Moldura travada.",
    ["tmt_reset_msg"]               = "|cff0cd29fTomoMod|r M+ Tracker: Posição redefinida.",
    ["tmt_unknown_cmd"]             = "|cff0cd29fTomoMod|r M+ Tracker: Comando desconhecido.",
    ["tmt_key_level"]               = "+%d",
    ["tmt_dungeon_unknown"]         = "Mítico+",
    ["tmt_overtime"]                = "TEMPO ESGOTADO",
    ["tmt_completed_on_time"]       = "CONCLUÍDO",
    ["tmt_completed_depleted"]      = "FRACASSADO",
    ["tmt_forces"]                  = "FORÇAS",
    ["tmt_forces_done"]             = "COMPLETO",
    ["tmt_forces_pct"]              = "%.1f%%",
    ["tmt_forces_count"]            = "%d / %d",
    ["tmt_cfg_title"]               = "Mythic",
    ["tmt_cfg_panel_enable"]         = "Ativar tracker M+",
    ["tmt_cfg_show_timer"]          = "Mostrar barra de tempo",
    ["tmt_cfg_show_forces"]         = "Mostrar forças inimigas",
    ["tmt_cfg_show_bosses"]         = "Mostrar temporizadores de chefe",
    ["tmt_cfg_hide_blizzard"]       = "Ocultar rastreador da Blizzard",
    ["tmt_cfg_lock"]                = "Travar moldura",
    ["tmt_cfg_scale"]               = "Escala",
    ["tmt_cfg_alpha"]               = "Opacidade do fundo",
    ["tmt_cfg_reset_pos"]           = "Redefinir posição",
    ["tmt_cfg_preview"]             = "Pré-visualizar",
    ["tmt_cfg_section_display"]     = "Exibição",
    ["tmt_cfg_section_frame"]       = "Moldura",
    ["tmt_cfg_section_actions"]     = "Ações",
    ["tmt_key_not_available"]       = "não disponível.",
    ["tmt_key_not_in_group"]        = "Você não está em um grupo.",
    ["tmt_key_none_found"]          = "Nenhuma chave encontrada.",
    ["tmt_kr_spin"]                 = "|TInterface\\Icons\\INV_Misc_Dice_02:14|t  Girar!",
    ["tmt_preview_active"]          = "|cff0cd29fTomoMod|r M+ Tracker: Pré-visualização ativa \226\128\148 |cFF55B400/tmt lock|r para travar.",

    -- MythicHub
    ["mhub_title"]                  = "Pontua\195\167\195\163o M\195\173tica+",
    ["mhub_col_dungeon"]            = "Masmorra",
    ["mhub_col_level"]              = "N\195\173vel",
    ["mhub_col_rating"]             = "Pontua\195\167\195\163o",
    ["mhub_col_best"]               = "Melhor",
    ["mhub_tp_click"]               = "Clique para se teletransportar",
    ["mhub_tp_not_available"]        = "Teletransporte n\195\163o aprendido",
    ["mhub_tp_not_learned"]          = "|cff0cd29fTomoMod|r: Feiti\195\167o de teletransporte n\195\163o aprendido.",
    ["mhub_vault_title"]            = "Grande C\195\162mara",
    ["mhub_vault_dungeons"]         = "Masmorras",
    ["mhub_vault_raids"]            = "Raides",
    ["mhub_vault_world"]            = "Abismos",
    ["mhub_vault_ilvl"]             = "N\195\173vel do item",
    ["mhub_vault_locked"]           = "Bloqueado",
    ["mhub_vault_claim"]            = "Volte \195\160 Grande C\195\162mara para reivindicar sua recompensa",

    -- ══════════════════════════════════════════════════════════
    -- INSTALLER
    -- ══════════════════════════════════════════════════════════

    -- Navigation
    ["ins_header_title"]             = "|cff0cd29fTomo|r|cffe4e4e4Mod|r  \226\128\148  Assistente de configura\195\167\195\163o",
    ["ins_step_counter"]             = "Etapa %d / %d",
    ["ins_btn_prev"]                 = "|TInterface\\BUTTONS\\UI-SpellbookIcon-PrevPage:0|t Anterior",
    ["ins_btn_next"]                 = "Pr\195\179ximo |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t",
    ["ins_btn_finish"]               = "Concluir |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t",
    ["ins_btn_skip"]                 = "Pular instala\195\167\195\163o",

    -- Step 1: Welcome
    ["ins_step1_title"]              = "Bem-vindo ao TomoMod",
    ["ins_subtitle"]                 = "Suite de interface e QOL para The War Within",
    ["ins_welcome_desc"]             = "Este assistente ir\195\161 gui\195\161-lo em |cff0cd29f16 etapas|r para configurar o TomoMod de\nacordo com suas prefer\195\170ncias: unit frames, party frames, castbars, nameplates, barras de a\195\167\195\163o,\nrecursos, skins, som, Mythic+, QOL, otimiza\195\167\195\181es e SkyRide.\n\nTodas essas op\195\167\195\181es podem ser alteradas a qualquer momento via |cff0cd29f/tm|r.",

    -- Step 2: Profile
    ["ins_step2_title"]              = "Perfil de jogo",
    ["ins_profile_info"]             = "Crie um perfil nomeado para salvar sua configura\195\167\195\163o.",
    ["ins_profile_section"]          = "Nome do perfil",
    ["ins_profile_placeholder"]      = "Meu perfil",
    ["ins_profile_create"]           = "Criar perfil",
    ["ins_profile_created"]          = "Perfil criado: ",
    ["ins_spec_section"]             = "Atribui\195\167\195\163o de especializa\195\167\195\163o",
    ["ins_spec_info"]                = "Voc\195\170 pode atribuir este perfil \195\160s suas specs no painel Perfis (/tm).\nCada spec pode usar uma configura\195\167\195\163o diferente.",

    -- Step 3: Visual Skins
    ["ins_step3_title"]              = "Skins visuais",
    ["ins_skins_info"]               = "Personalize a interface da Blizzard com o tema escuro do TomoMod.",
    ["ins_skins_section"]            = "Skins dispon\195\173veis",
    ["ins_skin_gamemenu"]            = "Skin do menu do jogo (Escape)",
    ["ins_skin_actionbar"]           = "Skin dos bot\195\181es da barra de a\195\167\195\163o",
    ["ins_skin_buffs"]               = "Skin de buffs / debuffs",
    ["ins_skin_chat"]                = "Skin do chat",
    ["ins_skin_character"]           = "Skin da ficha de personagem",
    ["ins_skin_style_section"]       = "Estilo dos bot\195\181es da barra de a\195\167\195\163o",
    ["ins_skin_style"]               = "Estilo visual",

    -- Step 4: Tank Mode
    ["ins_step4_title"]              = "Modo Tank",
    ["ins_tank_info"]                = "No modo tank, as nameplates e UnitFrames exibem\no status de amea\195\167a por cor para cada inimigo.",
    ["ins_tank_np_section"]          = "Nameplates \226\128\148 Cores de amea\195\167a",
    ["ins_tank_enable_np"]           = "Ativar modo tank (nameplates)",
    ["ins_tank_colors_info"]         = "Verde = voc\195\170 tem aggro  \194\183  Laranja = perto de perder  \194\183  Vermelho = aggro perdido",
    ["ins_tank_uf_section"]          = "UnitFrames \226\128\148 Indicador de amea\195\167a",
    ["ins_tank_threat_indicator"]    = "Mostrar indicador de amea\195\167a no alvo",
    ["ins_tank_threat_text"]         = "Mostrar texto de amea\195\167a % no alvo",
    ["ins_tank_cotank_section"]      = "CoTank Tracker",
    ["ins_tank_cotank_enable"]       = "Ativar rastreamento do co-tank",
    ["ins_tank_cotank_info"]         = "Exibe a amea\195\167a do segundo tank nas inst\195\162ncias.",

    -- Step 5: Nameplates
    ["ins_step5_title"]              = "Nameplates",
    ["ins_np_general"]               = "Geral",
    ["ins_np_enable"]                = "Ativar nameplates do TomoMod",
    ["ins_np_reload_info"]           = "Um reload \195\169 necess\195\161rio para ativar/desativar as nameplates.",
    ["ins_np_display"]               = "Exibi\195\167\195\163o",
    ["ins_np_class_colors"]          = "Cores de classe",
    ["ins_np_castbar"]               = "Mostrar barra de lan\195\167amento",
    ["ins_np_health_text"]           = "Mostrar texto de sa\195\186de (porcentagem)",
    ["ins_np_auras"]                 = "Mostrar auras (debuffs)",
    ["ins_np_role_icons"]            = "Mostrar \195\173cones de fun\195\167\195\163o (masmorra)",
    ["ins_np_dimensions"]            = "Dimens\195\181es",
    ["ins_np_width"]                 = "Largura",

    -- Step 6: Action Bars
    ["ins_step6_title"]              = "Barras de a\195\167\195\163o",
    ["ins_ab_skin_section"]          = "Skin dos bot\195\181es",
    ["ins_ab_enable"]                = "Ativar skin nos bot\195\181es de a\195\167\195\163o",
    ["ins_ab_class_color"]           = "Cor da borda = cor da classe",
    ["ins_ab_shift_reveal"]          = "Segure Shift para revelar barras ocultas",
    ["ins_ab_opacity_section"]       = "Opacidade global das barras",
    ["ins_ab_opacity"]               = "Opacidade",
    ["ins_ab_manage_section"]        = "Gerenciamento de barras",
    ["ins_ab_manage_info"]           = "Use o painel Barras de a\195\167\195\163o (/tm |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Barras de a\195\167\195\163o |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Gerenciamento)\npara desbloquear e reposicionar cada barra.",

    -- Step 7: LustSound
    ["ins_step7_title"]              = "Som \226\128\148 Hero\195\173smo / Sede de sangue",
    ["ins_sound_info"]               = "Reproduz um som personalizado quando Hero\195\173smo ou Sede de sangue\n\195\169 lan\195\167ado por qualquer membro do grupo.",
    ["ins_sound_activation"]         = "Ativa\195\167\195\163o",
    ["ins_sound_enable"]             = "Ativar som de lust",
    ["ins_sound_choice"]             = "Sele\195\167\195\163o de som",
    ["ins_sound_sound"]              = "Som",
    ["ins_sound_channel"]            = "Canal de \195\161udio",
    ["ins_sound_default"]            = "Padr\195\163o",
    ["ins_sound_preview_section"]    = "Pr\195\169-visualiza\195\167\195\163o",
    ["ins_sound_preview_btn"]        = "|TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Pr\195\169-visualizar",

    -- Step 8: Mythic+
    ["ins_step8_title"]              = "Mythic+ \226\128\148 Tracker e Placar",
    ["ins_mplus_tracker_section"]    = "M+ Tracker",
    ["ins_mplus_tracker_info"]       = "Exibe um temporizador, for\195\167as, chefes e progresso\nda sua masmorra Mythic+ em tempo real.",
    ["ins_mplus_tracker_enable"]     = "Ativar M+ Tracker",
    ["ins_mplus_show_timer"]         = "Mostrar temporizador",
    ["ins_mplus_show_forces"]        = "Mostrar for\195\167as (%)",
    ["ins_mplus_hide_blizzard"]      = "Ocultar interface Blizzard em Mythic+",
    ["ins_mplus_score_section"]      = "TomoScore \226\128\148 Placar",
    ["ins_mplus_score_info"]         = "Exibe pontua\195\167\195\181es pessoais e de grupo ao final de um Mythic+.",
    ["ins_mplus_score_enable"]       = "Ativar TomoScore",
    ["ins_mplus_score_auto"]         = "Mostrar automaticamente em M+",

    -- Step 9: CVars
    ["ins_step9_title"]              = "Otimiza\195\167\195\181es do sistema (CVars)",
    ["ins_cvar_info"]                = "O TomoMod pode aplicar um conjunto de CVars WoW recomendadas\npara melhorar desempenho e responsividade.",
    ["ins_cvar_section"]             = "Otimiza\195\167\195\181es inclu\195\173das",
    ["ins_cvar_opt1"]                = "Reduzir Level of Detail (LOD) desnecess\195\161rio",
    ["ins_cvar_opt2"]                = "Otimizar frustum culling",
    ["ins_cvar_opt3"]                = "Desativar temporal AA excessivo",
    ["ins_cvar_opt4"]                = "Melhorar responsividade de rede",
    ["ins_cvar_opt5"]                = "Desativar anima\195\167\195\181es de interface desnecess\195\161rias",
    ["ins_cvar_opt6"]                = "Otimizar streaming de texturas",
    ["ins_cvar_success"]             = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t  CVars aplicadas com sucesso!",
    ["ins_cvar_apply_btn"]           = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0|t Aplicar todas as CVars",
    ["ins_cvar_applied"]             = "CVars otimizadas aplicadas.",

    -- Step 10: QOL
    ["ins_step10_title"]             = "Qualidade de vida (QOL)",
    ["ins_qol_info"]                 = "Ative os m\195\179dulos QOL que desejar.\nTodos s\195\163o acess\195\173veis separadamente em /tm |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t QOL.",
    ["ins_qol_auto_section"]         = "Automatiza\195\167\195\181es",
    ["ins_qol_auto_repair"]          = "Reparar automaticamente no comerciante",
    ["ins_qol_fast_loot"]            = "Loot r\195\161pido (coleta r\195\161pida de itens)",
    ["ins_qol_skip_cinematics"]      = "Pular cinem\195\161ticas j\195\161 vistas",
    ["ins_qol_hide_talking_head"]    = "Ocultar Talking Head (di\195\161logos de rolagem)",
    ["ins_qol_auto_accept"]          = "Aceitar convites de grupo automaticamente (amigos e guilda)",
    ["ins_qol_tooltip_ids"]          = "Mostrar IDs nos tooltips (spell ID, item ID...)",
    ["ins_qol_combat_section"]       = "Combate",
    ["ins_qol_combat_text"]          = "Texto flutuante de combate personalizado",
    ["ins_qol_hide_castbar"]         = "Ocultar barra de lan\195\167amento da Blizzard (usar a do TomoMod)",

    -- Step 11: SkyRide
    ["ins_step11_title"]             = "SkyRide \226\128\148 Barra de montaria drac\195\180nica",
    ["ins_skyride_info"]             = "SkyRide exibe uma barra de Vigor (6 cargas) e uma barra de\nSegundo F\195\180lego (3 cargas) para montaria drac\195\180nica.",
    ["ins_skyride_activation"]       = "Ativa\195\167\195\163o",
    ["ins_skyride_enable"]           = "Ativar barra SkyRide",
    ["ins_skyride_auto_info"]        = "A barra aparece automaticamente no modo de voo drac\195\180nico\ne se oculta fora dele.",
    ["ins_skyride_dimensions"]       = "Dimens\195\181es",
    ["ins_skyride_width"]            = "Largura",
    ["ins_skyride_height"]           = "Altura",
    ["ins_skyride_reset_section"]    = "Redefinir posi\195\167\195\163o",
    ["ins_skyride_reset_btn"]        = "Redefinir posi\195\167\195\163o",

    -- Step 12: Done
    ["ins_step12_title"]             = "Configura\195\167\195\163o conclu\195\173da!",
    ["ins_done_check"]               = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t  Tudo pronto!",
    ["ins_done_recap"]               = "Sua configura\195\167\195\163o do TomoMod est\195\161 salva. Alguns lembretes:\n\n|cff0cd29f/tm|r              |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Abrir o painel de configura\195\167\195\163o\n|cff0cd29f/tm sr|r           |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Desbloquear e mover elementos\n|cff0cd29f/tm install|r      |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Relan\195\167ar este instalador\n\nTodas as op\195\167\195\181es configuradas aqui podem ser alteradas a qualquer momento\nnos pain\195\169is correspondentes na GUI do TomoMod.\n\nUm |cff0cd29freload da UI|r \195\169 necess\195\161rio para aplicar certas altera\195\167\195\181es\n(nameplates, skins, UnitFrames).",
    ["ins_done_reload"]              = "|TInterface\\BUTTONS\\UI-RefreshButton:0|t  Recarregar UI",

    -- Step NEW: Unit Frames
    ["ins_uf_title"]                 = "Unit Frames",
    ["ins_uf_info"]                  = "O TomoMod substitui os quadros de unidade padr\195\163o da Blizzard (jogador, alvo, foco, pet)\npor quadros modernos e personaliz\195\161veis.",
    ["ins_uf_section"]               = "Geral",
    ["ins_uf_enable"]                = "Ativar UnitFrames do TomoMod",
    ["ins_uf_hide_blizzard"]         = "Ocultar quadros padr\195\163o da Blizzard",
    ["ins_uf_reload_info"]           = "Um reload \195\169 necess\195\161rio para aplicar altera\195\167\195\181es nos UnitFrames.",

    -- Step NEW: Party Frames
    ["ins_pf_title"]                 = "Party Frames",
    ["ins_pf_info"]                  = "Quadros de grupo personalizados com \195\173cones de fun\195\167\195\163o, destaque de dissipa\195\167\195\163o\ne rastreamento de cooldowns para jogo em grupo.",
    ["ins_pf_section"]               = "Geral",
    ["ins_pf_enable"]                = "Ativar Party Frames do TomoMod",
    ["ins_pf_hide_blizzard"]         = "Ocultar Party Frames da Blizzard",
    ["ins_pf_cd_section"]            = "Rastreadores de cooldown",
    ["ins_pf_cd_info"]               = "Rastreie os cooldowns de interrup\195\167\195\163o e ressurrei\195\167\195\163o de combate\ndos seus companheiros diretamente nos quadros de grupo.",
    ["ins_pf_show_interrupt"]        = "Mostrar rastreador de cooldown de interrup\195\167\195\163o",
    ["ins_pf_show_brez"]             = "Mostrar rastreador de cooldown de ressurrei\195\167\195\163o de combate",
    ["ins_pf_reload_info"]           = "Um reload \195\169 necess\195\161rio para aplicar altera\195\167\195\181es nos Party Frames.",

    -- Step NEW: Castbars
    ["ins_cb_title"]                 = "Barras de lan\195\167amento",
    ["ins_cb_info"]                  = "Barras de lan\195\167amento personalizadas para jogador, alvo, foco e pet\ncom anima\195\167\195\163o de fa\195\173sca e feedback de interrup\195\167\195\163o.",
    ["ins_cb_section"]               = "Geral",
    ["ins_cb_enable"]                = "Ativar castbars do TomoMod",
    ["ins_cb_hide_blizzard"]         = "Ocultar castbar padr\195\163o da Blizzard",
    ["ins_cb_class_color"]           = "Usar cor da classe para o preenchimento",
    ["ins_cb_reload_info"]           = "Um reload \195\169 necess\195\161rio para aplicar altera\195\167\195\181es nas castbars.",

    -- Step NEW: Resource Bars & Cooldown Manager
    ["ins_res_title"]                = "Recursos & Cooldowns",
    ["ins_res_info"]                 = "Exibi\195\167\195\163o de poder de classe (pontos de combo, runas, fragmentos de alma, etc.)\nem modo \195\173cone ou barra.",
    ["ins_res_section"]              = "Barras de recursos",
    ["ins_res_enable"]               = "Ativar barras de recursos",
    ["ins_res_display"]              = "Modo de exibi\195\167\195\163o",
    ["ins_cdm_section"]              = "Gerenciador de cooldowns",
    ["ins_cdm_info"]                 = "Espiral de cooldown nos bot\195\181es de a\195\167\195\163o com\nalfa adaptativo ao combate e filtragem de GCD.",
    ["ins_cdm_enable"]               = "Ativar gerenciador de cooldowns",
    ["ins_cdm_hide_gcd"]             = "Ocultar espiral de GCD",
    ["ins_cdm_desat"]                = "Dessaturar bot\195\181es em cooldown",

    -- Enhanced Skins
    ["ins_skin_bag"]                 = "Skin de bolsas",
    ["ins_skin_tooltip"]             = "Skin de tooltips",

    -- Enhanced QOL
    ["ins_qol_interface_section"]    = "Interface",
    ["ins_qol_minimap"]              = "Minimapa personalizado (borda e escala)",
    ["ins_qol_cursor"]               = "Anel de cursor luminoso",
    ["ins_qol_afk"]                  = "Tela AFK personalizada com modelo 3D",
    ["ins_qol_diag"]                 = "Diagn\195\179sticos (captura de erros sem popups)",
    ["ins_qol_aura_tracker"]         = "Rastreador de auras (trinkets, buffs, defensivos)",

    -- =========== Config Panels — i18n ===========
    -- ActionBars panel
    ["opt_abs_style"]                = "Estilo visual",
    ["section_bar_opacity"]          = "Opacidade por barra",
    ["opt_abs_bar_select"]           = "Barra a configurar",
    ["opt_abs_opacity"]              = "Opacidade",
    ["btn_abs_apply_all"]            = "Aplicar a todas as barras",
    ["opt_abs_combat_only_label"]    = "Exibir apenas em combate:",
    ["opt_abs_combat_only"]          = "Barra vis\195\173vel apenas em combate",
    ["section_bar_management"]       = "Gerenciamento de barras de a\195\167\195\163o",
    ["btn_abs_unlock"]               = "Desbloquear barras",
    ["info_abs_unlock"]              = "Desbloqueie as barras para exibir as al\195\167as de arrasto.\nClique com o bot\195\163o direito em uma al\195\167a para configurar uma barra individualmente.",
    ["section_bar_quick"]            = "Configura\195\167\195\181es r\195\161pidas",
    ["tab_abs_skin"]                 = "Skin de bot\195\181es",
    ["tab_abs_bars"]                 = "Gerenciamento de barras",
    -- General panel
    ["btn_relaunch_installer"]       = "Relan\195\167ar instalador",
    ["info_relaunch_installer"]      = "Inicia o assistente de configura\195\167\195\163o de 16 etapas.",
    -- Sound panel
    ["section_sound_preview"]        = "Pr\195\169-visualiza\195\167\195\163o e op\195\167\195\181es",
    -- UFPreview
    ["preview_header"]               = "PR\195\137-VISUALIZA\195\135\195\131O AO VIVO",
    ["preview_player"]               = "Jogador",
    ["preview_target_name"]          = "Taurache",
    ["preview_focus_name"]           = "Sacerdotisa",
    ["preview_pet_name"]             = "Lobo d'\195\161gua",
    ["preview_tot_name"]             = "Alvo-do-alvo",
    ["preview_cast_player"]          = "Rel\195\162mpago de Gelo",
    ["preview_cast_target"]          = "Bola de Fogo",
    ["preview_lbl_player"]           = "JOGADOR",
    ["preview_lbl_target"]           = "ALVO",
    ["preview_lbl_focus"]            = "FOCO",
    ["preview_lbl_pet"]              = "PET",
    ["preview_lbl_tot"]              = "TOT",
    ["preview_click_nav"]            = "clique para navegar",
    ["preview_click_isolate"]         = "clique para isolar",
    ["preview_click_show_all"]        = "clique para mostrar tudo",
    ["preview_show_all"]              = "Mostrar tudo",
    -- ConfigUI footer
    ["ui_footer_hint"]               = "/tm  \194\183  /tm sr para mover elementos",

    -- =====================
    -- SKINS CATEGORY (top-level)
    -- =====================
    ["cat_skins"]                        = "Skins",

    -- Chat Frame V2 — r\195\179tulos das abas e interface
    ["chatv2_tab_general"]               = "Geral",
    ["chatv2_tab_instance"]              = "Inst\195\162ncia",
    ["chatv2_tab_chucho"]                = "Chucho",
    ["chatv2_tab_personnel"]             = "Pessoal",
    ["chatv2_tab_combat"]                = "Combate",
    ["chatv2_sidebar_title"]             = "CHAT",
    ["chatv2_expand_btn"]                = "Chat",
    ["chatv2_mover_label"]               = "Janela de chat V2",
    ["chatv2_input_hint"]                = "Pressione Enter para digitar...",

    -- Skins > Chat Frame tab
    ["tab_skin_chatframe"]               = "Janela de chat",
    ["section_skin_chatframe"]           = "Skin da janela de chat",
    ["info_skin_chatframe_desc"]         = "Painel de chat com barra lateral \226\128\148 Geral, Inst\195\162ncia, Chucho, Pessoal, Combate \226\128\148 com emblemas de n\195\163o lidos e indicadores de pin.",
    ["opt_skin_chatframe_enable"]        = "Ativar skin de chat",
    ["opt_skin_chatframe_width"]         = "Largura",
    ["opt_skin_chatframe_height"]        = "Altura",
    ["opt_skin_chatframe_scale"]         = "Escala %",
    ["opt_skin_chatframe_opacity"]       = "Opacidade do fundo",
    ["opt_skin_chatframe_font_size"]     = "Tamanho da fonte",
    ["opt_skin_chatframe_timestamp"]     = "Mostrar data/hora",

    -- Skins > Bags tab
    ["tab_skin_bags"]                    = "Bolsas",
    ["section_skin_bags"]                = "Skin das bolsas",
    ["info_skin_bags_desc"]              = "Grade de bolsas por categoria inspirada no BetterBags. Itens agrupados em se\195\167\195\181es dobr\195\161veis com bordas de qualidade, busca, tempos de recarga e n\195\173vel de item.",
    ["opt_skin_bags_enable"]             = "Ativar skin das bolsas",
    -- Bolsas — Desencantamento
    ["bagskin_de_badge"]                 = "DE",
    ["bagskin_de_tooltip"]               = "|cff0cd29f[Clique direito]|r Desencantamento",
    ["bagskin_currencies_none"]          = "Nenhuma moeda rastreada (clique direito em uma moeda \226\134\146 Mostrar na mochila)",
    ["opt_skin_bags_stack_merge"]        = "Fundir pilhas id\195\170nticas",
    ["opt_skin_bags_show_empty"]         = "Mostrar se\195\167\195\163o de espa\195\167os livres",
    ["opt_skin_bags_show_recent"]        = "Mostrar se\195\167\195\163o de itens recentes",
    ["opt_skin_bags_columns"]            = "Colunas",
    ["opt_skin_bags_slot_size"]          = "Tamanho do espa\195\167o",
    ["opt_skin_bags_slot_spacing"]       = "Espa\195\167amento",
    ["opt_skin_bags_scale"]              = "Escala %",
    ["opt_skin_bags_opacity"]            = "Opacidade do fundo",
    ["opt_skin_bags_quality_borders"]    = "Mostrar bordas de qualidade",
    ["opt_skin_bags_cooldowns"]          = "Mostrar tempos de recarga",
    ["opt_skin_bags_quantity"]           = "Mostrar emblemas de quantidade",
    ["opt_skin_bags_search"]             = "Mostrar barra de busca",
    ["opt_skin_bags_sort_mode"]          = "Modo de ordena\195\167\195\163o",
    ["opt_skin_bags_sort_quality"]       = "Qualidade",
    ["opt_skin_bags_sort_name"]          = "Nome",
    ["opt_skin_bags_sort_type"]          = "Tipo",
    ["opt_skin_bags_sort_ilvl"]          = "N\195\173vel de item",
    ["opt_skin_bags_sort_recent"]        = "Recente",
    ["opt_skin_bags_show_gold"]          = "Mostrar ouro (rodap\195\169)",
    ["opt_skin_bags_show_currencies"]    = "Mostrar moedas rastreadas (rodap\195\169)",
    ["bagskin_cat_recent"]               = "Itens recentes",
    ["bagskin_cat_equipment"]            = "Equipamento",
    ["bagskin_cat_consumables"]          = "Consum\195\173veis",
    ["bagskin_cat_quest"]                = "Itens de miss\195\163o",
    ["bagskin_cat_tradegoods"]           = "Bens comerciais",
    ["bagskin_cat_reagents"]             = "Reagentes",
    ["bagskin_cat_gems"]                 = "Gemas e melhorias",
    ["bagskin_cat_recipes"]              = "Receitas",
    ["bagskin_cat_pets"]                 = "Mascotes de combate",
    ["bagskin_cat_junk"]                 = "Lixo",
    ["bagskin_cat_misc"]                 = "Diversos",
    ["bagskin_cat_free"]                 = "Espa\195\167os livres",

    -- Skins > Objective Tracker tab
    ["tab_skin_objtracker"]              = "Rastreador",

    -- Skins > Character tab
    ["tab_skin_character"]               = "Personagem",

    -- Skins > Buffs tab
    ["tab_skin_buffs"]                   = "Buffs",

    -- Skins > Game Menu tab
    ["tab_skin_gamemenu"]                = "Menu do jogo",

    -- Skins > Mail tab
    ["tab_skin_mail"]                    = "Correio",

    -- =====================
    -- MÓDULO WAYPOINT (/tm way)
    -- =====================
    -- GUI
    ["tab_qol_waypoint"]                  = "Waypoint",
    ["section_waypoint"]                  = "Waypoint",
    ["opt_way_zone_only"]                 = "Mostrar apenas na zona atual",
    ["opt_way_size"]                      = "Tamanho do sinal",
    ["opt_way_shape"]                     = "Forma",
    ["way_shape_ring"]                    = "Anel",
    ["way_shape_arrow"]                   = "Seta",
    ["opt_way_color"]                     = "Cor do waypoint",
    -- Slash
    ["msg_help_way"]                     = "Colocar um waypoint na sua posição atual",
    ["msg_help_way_coords"]              = "Colocar um waypoint nas coordenadas (x, y)",
    ["msg_help_way_clear"]               = "Remover o waypoint ativo",
    ["way_cleared"]                      = "Waypoint removido.",
    ["way_set"]                          = "Waypoint definido em %s%s.",
    ["way_here"]                         = "Waypoint colocado na posição atual.",
    ["way_no_map"]                       = "Não foi possível determinar o mapa atual.",
    ["way_no_pos"]                       = "Não foi possível determinar a posição do jogador.",
    ["way_bad_map"]                      = "Não é possível colocar um waypoint neste mapa.",
    ["way_bad_coords"]                   = "As coordenadas devem estar entre 0 e 100.",
    ["way_usage"]                        = "Uso: /tm way [mapID] x y [nome]  |  /tm way clear",

    -- =====================
    -- Resource names
    -- =====================
    ["res_mana"]                        = "Mana (Druida)",
    ["res_soul_shards"]                 = "Estilhaços de Alma",
    ["res_holy_power"]                  = "Poder Sagrado",
    ["res_chi"]                         = "Chi",
    ["res_combo_points"]                = "Pontos de Combo",
    ["res_arcane_charges"]              = "Cargas Arcanas",
    ["res_essence"]                     = "Essência",
    ["res_stagger"]                     = "Cambalear",
    ["res_soul_fragments"]              = "Fragmentos de Alma",
    ["res_tip_of_spear"]                = "Ponta da Lança",
    ["res_maelstrom_weapon"]            = "Arma de Maelstrom",

    -- =====================
    -- Resource Bars display mode
    -- =====================
    ["opt_rb_display_mode"]             = "Modo de exibição",
    ["display_mode_icons"]              = "Ícones (texturas TUI)",
    ["display_mode_bars"]               = "Barras (cores planas)",

    -- =====================
    -- Tooltip Skin
    -- =====================
    ["tab_skin_tooltip"]                 = "Tooltip",
    ["section_tooltip_skin"]             = "Skin de Tooltip",
    ["opt_tooltip_skin_enable"]          = "Ativar skin de tooltip",
    ["info_tooltip_skin_reload"]         = "Algumas mudanças exigem passar o cursor sobre um novo alvo.",
    ["opt_tooltip_bg_alpha"]             = "Opacidade do fundo",
    ["opt_tooltip_border_alpha"]         = "Opacidade da borda",
    ["opt_tooltip_font_size"]            = "Tamanho de fonte",
    ["opt_tooltip_hide_healthbar"]       = "Ocultar barra de vida",
    ["opt_tooltip_class_color"]          = "Nomes de jogador com cor da classe",
    ["opt_tooltip_hide_server"]          = "Ocultar servidor nos nomes de jogador",
    ["opt_tooltip_hide_title"]           = "Ocultar título nos nomes de jogador",
    ["opt_tooltip_guild_color"]          = "Cor personalizada do nome da guilda",
    ["opt_tooltip_guild_color_pick"]     = "Cor do nome da guilda",

    -- =====================
    -- Bag Skin extras
    -- =====================
    ["opt_skin_bags_show_ilvl"]          = "Mostrar nível de item no equipamento",
    ["opt_skin_bags_show_junk_icon"]     = "Ícone de lixo",
    ["opt_skin_bags_layout_mode"]        = "Modo de layout",
    ["opt_skin_bags_layout_combined"]    = "Grade combinada",
    ["opt_skin_bags_layout_categories"]  = "Categorias",
    ["opt_skin_bags_layout_separate"]    = "Bolsas separadas",
    ["opt_skin_bags_reverse_order"]      = "Inverter ordem das bolsas",
    ["opt_skin_bags_show_bag_bar"]       = "Mostrar barra de bolsas",
    ["opt_skin_bags_settings"]           = "Configurações de bolsas",
    ["opt_skin_bags_slot_spacing_x"]     = "Espaçamento de slot X",
    ["opt_skin_bags_slot_spacing_y"]     = "Espaçamento de slot Y",
    ["opt_skin_bags_sort_none"]          = "Manual",

    -- =====================
    -- TOMOSCORE (Scoreboard)
    -- =====================
    ["ts_cfg_title"]                = "Placar",
    ["ts_cfg_enable"]               = "Ativar placar de dungeon",
    ["ts_cfg_auto_show_mplus"]      = "Mostrar automaticamente no M+",
    ["ts_cfg_scale"]                = "Escala",
    ["ts_cfg_alpha"]                = "Opacidade do fundo",
    ["ts_cfg_section_display"]      = "Exibição",
    ["ts_cfg_section_frame"]        = "Quadro",
    ["ts_cfg_section_actions"]      = "Ações",
    ["ts_cfg_preview"]              = "Pré-visualização",
    ["ts_cfg_last_run"]             = "Mostrar última partida",
    ["ts_cfg_reset_pos"]            = "Redefinir posição",
    ["ts_reset_msg"]                = "|cff0cd29fTomoMod|r Placar: Posição redefinida.",
    ["ts_no_data"]                  = "|cff0cd29fTomoMod|r Placar: Nenhum dado de dungeon disponível.",
    ["ts_mythic_zero"]              = "Mítico",
    ["ts_key_level"]                = "+%d",
    ["ts_completed"]                = "COMPLETO",
    ["ts_depleted"]                 = "ESGOTADO",
    ["ts_duration"]                 = "Duração",
    ["ts_col_player"]               = "Jogador",
    ["ts_col_rating"]               = "M+",
    ["ts_col_key_level"]            = "Chave",
    ["ts_col_key_name"]             = "Dungeon",
    ["ts_col_damage"]               = "Dano",
    ["ts_col_healing"]              = "Cura",
    ["ts_col_interrupts"]           = "Interrupções",
    ["ts_footer_total"]             = "Total",
    ["ts_footer_players"]           = "%d jogadores",

    -- =====================
    -- CASTBARS (módulo autônomo)
    -- =====================
    ["cat_castbars"]                     = "Barras de lançamento",

    ["cb_section_general"]               = "Geral",
    ["opt_cb_enable"]                    = "Ativar barras de lançamento autônomas",
    ["info_cb_description"]              = "Substitui as barras de lançamento da Blizzard por barras totalmente personalizáveis para Jogador, Alvo, Foco, Bichano e Chefe.",
    ["opt_cb_hide_blizzard"]             = "Ocultar barras de lançamento da Blizzard",
    ["opt_cb_class_color"]               = "Usar cor de classe",
    ["opt_cb_show_transitions"]          = "Animações de início/fim",
    ["opt_cb_show_channel_ticks"]        = "Mostrar marcas de canalização",
    ["opt_cb_timer_format"]              = "Formato do temporizador",
    ["cb_timer_remaining"]               = "Restante (1.5)",
    ["cb_timer_remaining_total"]         = "Restante / Total (1.5 / 3.0)",
    ["cb_timer_elapsed"]                 = "Decorrido (1.5)",
    ["opt_cb_spell_max_len"]             = "Comprimento máx. do nome (0 = ilimitado)",

    ["cb_section_appearance"]            = "Aparência",
    ["opt_cb_bar_texture"]               = "Textura da barra",
    ["cb_tex_blizzard"]                  = "Blizzard",
    ["cb_tex_smooth"]                    = "Suave",
    ["cb_tex_flat"]                      = "Plano",
    ["opt_cb_font_size"]                 = "Tamanho da fonte",
    ["opt_cb_bg_mode"]                   = "Modo de fundo",
    ["cb_bg_black"]                      = "Preto",
    ["cb_bg_transparent"]                = "Transparente",
    ["cb_bg_custom"]                     = "Textura personalizada",

    ["cb_section_colors"]                = "Cores",
    ["opt_cb_cast_color"]                = "Cor de lançamento",
    ["opt_cb_ni_color"]                  = "Não interrompível",
    ["opt_cb_interrupt_color"]           = "Cor de interrupção",

    ["cb_section_spark"]                 = "Faísca",
    ["opt_cb_show_spark"]                = "Mostrar animação de faísca",
    ["opt_cb_spark_style"]               = "Estilo de faísca",
    ["opt_cb_spark_color"]               = "Cor da faísca",
    ["opt_cb_spark_glow_color"]          = "Cor do brilho",
    ["opt_cb_spark_tail_color"]          = "Cor da cauda",
    ["opt_cb_spark_glow_alpha"]          = "Opacidade do brilho",
    ["opt_cb_spark_tail_alpha"]          = "Opacidade da cauda",

    ["cb_section_gcd"]                   = "Faísca GCD",
    ["opt_cb_show_gcd"]                  = "Mostrar barra GCD abaixo da barra do jogador",
    ["opt_cb_gcd_height"]                = "Altura da barra GCD",
    ["opt_cb_gcd_color"]                 = "Cor GCD",

    ["cb_section_interrupt"]             = "Feedback de interrupção",
    ["opt_cb_show_interrupt_feedback"]   = "Mostrar texto de interrupção",
    ["opt_cb_interrupt_fb_color"]        = "Cor do texto",
    ["opt_cb_interrupt_fb_size"]         = "Tamanho da fonte",
    ["cb_interrupt_feedback_text"]       = "INTERROMPIDO!",
    ["cb_interrupt_feedback_full"]       = "INTERROMPIDO: %s",
    ["cb_interrupted"]                   = "Interrompido",

    ["cb_tab_general"]                   = "Geral",
    ["cb_tab_player"]                    = "Jogador",
    ["cb_tab_target"]                    = "Alvo",
    ["cb_tab_focus"]                     = "Foco",
    ["cb_tab_pet"]                       = "Bichano",
    ["cb_tab_boss"]                      = "Chefe",

    ["cb_section_unit"]                  = "Barra de %s",
    ["opt_cb_unit_enable"]               = "Ativar",
    ["opt_cb_unit_width"]                = "Largura",
    ["opt_cb_unit_height"]               = "Altura",
    ["opt_cb_unit_show_icon"]            = "Mostrar ícone",
    ["opt_cb_unit_icon_side"]            = "Lado do ícone",
    ["cb_icon_left"]                     = "Esquerda",
    ["cb_icon_right"]                    = "Direita",
    ["opt_cb_unit_show_timer"]           = "Mostrar temporizador",
    ["opt_cb_unit_show_latency"]         = "Mostrar latência",
    ["info_cb_latency"]                  = "Exibe uma sobreposição escura mostrando a latência da rede no final da barra.",
    ["info_cb_position"]                 = "Use /tm layout para desbloquear e arrastar esta barra.",
    ["btn_cb_reset_position"]            = "Redefinir posição",
    ["cb_move_label"]                    = "(Arraste para mover)",
    ["cb_preview_castbar"]               = "Prévia: %s",

    ["mover_castbar_standalone"]         = "Barras de lançamento",

    -- ═══════════════════════════════════
    -- Quadros de grupo (Party Frames)
    -- ═══════════════════════════════════
    ["cat_partyframes"]                  = "Quadros de grupo",
    ["mover_partyframes"]                = "Quadros de grupo",

    ["pf_tab_general"]                   = "Geral",
    ["pf_tab_features"]                  = "Recursos",
    ["pf_tab_cooldowns"]                 = "Recarga",
    ["pf_tab_arena"]                     = "Arena",

    ["pf_section_general"]               = "Geral",
    ["pf_opt_enable"]                    = "Ativar quadros de grupo",
    ["pf_info_description"]              = "Quadros de grupo personalizados para M+ e Arena com saúde, absorção, previsão de cura, HoTs, CD de interrupção/rez de combate e destaque de dissipação.",
    ["pf_opt_hide_blizzard"]             = "Ocultar quadros de grupo da Blizzard",
    ["pf_opt_sort_role"]                 = "Ordenar por função (Tanque > Curador > DPS)",

    ["pf_section_dimensions"]            = "Dimensões",
    ["pf_opt_width"]                     = "Largura do quadro",
    ["pf_opt_height"]                    = "Altura do quadro",
    ["pf_opt_spacing"]                   = "Espaçamento",
    ["pf_opt_grow_direction"]            = "Direção de crescimento",
    ["pf_dir_down"]                      = "Baixo",
    ["pf_dir_up"]                        = "Cima",
    ["pf_dir_right"]                     = "Direita",
    ["pf_dir_left"]                      = "Esquerda",

    ["pf_section_display"]               = "Exibição",
    ["pf_opt_show_name"]                 = "Mostrar nome",
    ["pf_opt_show_health_text"]          = "Mostrar texto de saúde",
    ["pf_opt_health_format"]             = "Formato de saúde",
    ["pf_fmt_deficit"]                   = "Déficit",
    ["pf_opt_health_color"]              = "Modo de cor de saúde",
    ["pf_color_green"]                   = "Verde",
    ["pf_color_gradient"]                = "Gradiente",
    ["pf_opt_show_power"]                = "Mostrar barra de poder",
    ["pf_opt_power_height"]              = "Altura da barra de poder",
    ["pf_opt_show_role"]                 = "Mostrar ícone de função",
    ["pf_opt_role_size"]                 = "Tamanho do ícone de função",
    ["pf_opt_show_marker"]               = "Mostrar marcador de raide",

    ["pf_section_font"]                  = "Fonte",
    ["pf_opt_font_size"]                 = "Tamanho da fonte",

    ["pf_section_position"]              = "Posição",
    ["pf_info_position"]                 = "Use /tm layout para desbloquear e arrastar os quadros de grupo.",
    ["pf_btn_reset_position"]            = "Redefinir posição",

    ["pf_section_health_extras"]         = "Extras de saúde",
    ["pf_opt_show_absorb"]               = "Mostrar barra de absorção",
    ["pf_opt_absorb_color"]              = "Cor de absorção",
    ["pf_opt_show_heal_pred"]            = "Mostrar previsão de cura",

    ["pf_section_range"]                 = "Verificação de alcance",
    ["pf_opt_show_range"]                = "Esmaecer membros fora de alcance",
    ["pf_opt_oor_alpha"]                 = "Opacidade fora de alcance",

    ["pf_section_dispel"]                = "Destaque de dissipação",
    ["pf_opt_show_dispel"]               = "Destacar debuffs dissipiáveis",
    ["pf_info_dispel"]                   = "Brilho da borda por tipo de debuff: Magia (azul), Maldição (roxo), Doença (marrom), Veneno (verde).",

    ["pf_section_hots"]                  = "Rastreamento de HoTs",
    ["pf_opt_show_hots"]                 = "Mostrar indicadores HoT",
    ["pf_opt_hot_size"]                  = "Tamanho do ícone HoT",
    ["pf_opt_max_hots"]                  = "Máx. HoTs mostrados",
    ["pf_info_hots"]                     = "Exibe efeitos de cura ao longo do tempo com bordas coloridas por classe. Suporta Sacerdote, Druida, Paladino, Xamã, Monge e Evocador.",

    ["pf_section_cooldowns"]             = "Rastreador de recarga",
    ["pf_opt_show_kick"]                 = "Mostrar CD de interrupção",
    ["pf_opt_show_brez"]                 = "Mostrar CD de rez de combate",
    ["pf_opt_cd_size"]                   = "Tamanho do ícone CD",
    ["pf_opt_cd_layout"]                 = "Layout de ícones CD",
    ["pf_cd_vertical"]                   = "Vertical (no quadro)",
    ["pf_cd_horizontal"]                 = "Horizontal (abaixo)",
    ["pf_info_cooldowns"]                = "Rastreia recargas de interrupção e rez de combate de cada membro do grupo.",

    ["pf_section_arena"]                 = "Quadros inimigos de arena",
    ["pf_opt_arena_enable"]              = "Ativar quadros de arena",
    ["pf_info_arena"]                    = "Exibe saúde, poder e CD de bijuteria PvP da equipe inimiga na Arena (2v2/3v3).",
    ["pf_section_arena_dims"]            = "Dimensões de arena",
    ["pf_opt_arena_width"]               = "Largura",
    ["pf_opt_arena_height"]              = "Altura",
    ["pf_opt_arena_spacing"]             = "Espaçamento",
    ["pf_section_arena_trinket"]         = "Bijuteria PvP",
    ["pf_opt_show_trinket"]              = "Mostrar CD de bijuteria",
    ["pf_opt_trinket_size"]              = "Tamanho do ícone de bijuteria",
    ["pf_opt_show_spec"]                 = "Mostrar ícone de especialização",
    ["pf_section_arena_pos"]             = "Posição de arena",
    ["pf_info_arena_pos"]                = "Use /tm layout para desbloquear e arrastar os quadros de arena.",
    ["pf_btn_reset_arena_pos"]           = "Redefinir posição",

    -- ═══════════════════════════════════
    -- Raid Frames
    -- ═══════════════════════════════════
    ["cat_raidframes"]                   = "Quadros de raide",
    ["mover_raidframes"]                 = "Quadros de raide",
    ["rf_tab_general"]                   = "Geral",
    ["rf_tab_features"]                  = "Recursos",
    ["rf_section_general"]               = "Geral",
    ["rf_opt_enable"]                    = "Ativar quadros de raide",
    ["rf_info_description"]              = "Quadros de raide personalizados com vida, absorção, previsão de cura, HoTs, debuffs, destaque de dissipação, CDs defensivos e verificação de alcance.",
    ["rf_opt_hide_blizzard"]             = "Ocultar quadros de raide da Blizzard",
    ["rf_opt_sort_role"]                 = "Ordenar por função (Tanque > Curandeiro > DPS)",
    ["rf_section_layout"]                = "Layout",
    ["rf_opt_layout_mode"]               = "Modo de layout",
    ["rf_layout_grid"]                   = "Grade (grupos em colunas)",
    ["rf_layout_list"]                   = "Lista (coluna única)",
    ["rf_opt_width"]                     = "Largura do quadro",
    ["rf_opt_height"]                    = "Altura do quadro",
    ["rf_opt_spacing"]                   = "Espaçamento",
    ["rf_opt_group_spacing"]             = "Espaçamento de grupo",
    ["rf_section_display"]               = "Exibição",
    ["rf_opt_show_name"]                 = "Mostrar nome",
    ["rf_opt_name_max_length"]           = "Letras máx. do nome",
    ["rf_opt_show_health_text"]          = "Mostrar texto de vida",
    ["rf_opt_health_format"]             = "Formato de vida",
    ["rf_opt_health_color"]              = "Modo de cor da vida",
    ["rf_opt_show_role"]                 = "Mostrar ícone de função",
    ["rf_opt_show_marker"]               = "Mostrar marcador de raide",
    ["rf_section_font"]                  = "Fonte",
    ["rf_opt_font_size"]                 = "Tamanho da fonte",
    ["rf_section_position"]              = "Posição",
    ["rf_info_position"]                 = "Use /tm layout para desbloquear e arrastar os quadros de raide.",
    ["rf_btn_reset_position"]            = "Redefinir posição",
    ["rf_info_test_raid"]                = "Simule uma raide de 20 jogadores para pré-visualizar o layout fora de combate.",
    ["rf_btn_test_raid"]                 = "Simular 20 jogadores",
    ["rf_btn_test_raid_stop"]            = "Parar simulação",
    ["rf_preview_group"]                 = "G",
    ["rf_mode_raid"]                     = "Raid",
    ["rf_mode_solo"]                     = "Solo",
    ["rf_section_health_extras"]         = "Recursos de vida",
    ["rf_opt_show_power"]                = "Barra de poder (apenas curandeiros)",
    ["rf_opt_power_height"]              = "Altura da barra de poder",
    ["rf_opt_show_absorb"]               = "Mostrar barra de absorção",
    ["rf_opt_show_heal_pred"]            = "Mostrar previsão de cura",
    ["rf_section_range"]                 = "Verificação de alcance",
    ["rf_opt_show_range"]                = "Esmaecer membros fora de alcance",
    ["rf_opt_oor_alpha"]                 = "Opacidade fora de alcance",
    ["rf_section_dispel"]                = "Destaque de dissipação",
    ["rf_opt_show_dispel"]               = "Destacar debuffs dissipaveis",
    ["rf_section_hots"]                  = "Rastreamento de HoTs",
    ["rf_opt_show_hots"]                 = "Mostrar indicadores HoT",
    ["rf_opt_hot_size"]                  = "Tamanho do ícone HoT",
    ["rf_opt_max_hots"]                  = "Máx. HoTs mostrados",
    ["rf_section_debuffs"]               = "Rastreamento de debuffs",
    ["rf_opt_show_debuffs"]              = "Mostrar ícones de debuff",
    ["rf_opt_debuff_size"]               = "Tamanho do ícone de debuff",
    ["rf_opt_max_debuffs"]               = "Máx. debuffs mostrados",
    ["rf_section_defensives"]            = "CDs defensivos",
    ["rf_opt_show_defensives"]           = "Mostrar buffs defensivos ativos",
    ["rf_opt_defensive_size"]            = "Tamanho do ícone defensivo",
    ["rf_info_defensives"]               = "Exibe CDs defensivos ativos (ex: Supressão de Dor, Casca de Ferro, Escudo Divino) em cada membro da raide.",

    -- ═══════════════════════════════════
    -- Aura Tracker
    -- ═══════════════════════════════════
    ["tab_qol_aura_tracker"]             = "Rastreador de auras",
    ["mover_auratracker"]                = "Rastreador de auras",

    ["at_section_general"]               = "Geral",
    ["at_opt_enable"]                    = "Ativar rastreador de auras",
    ["at_info_description"]              = "Rastreia buffs importantes: procs de bijuteria, procs de encantamento, buffs pessoais e defensivos em um overlay de ícones.",

    ["at_section_appearance"]            = "Aparência",
    ["at_opt_icon_size"]                 = "Tamanho do ícone",
    ["at_opt_spacing"]                   = "Espaçamento",
    ["at_opt_max_icons"]                 = "Máx. ícones",
    ["at_opt_grow_direction"]            = "Direção de crescimento",
    ["at_opt_font_size"]                 = "Tamanho da fonte",

    ["at_section_display"]               = "Exibição",
    ["at_opt_show_timer"]                = "Mostrar temporizador",
    ["at_opt_show_stacks"]               = "Mostrar acumulações",
    ["at_opt_show_glow"]                 = "Brilho em novo proc",
    ["at_opt_timer_threshold"]           = "Limiar de piscamento (seg)",

    ["at_section_categories"]            = "Categorias",
    ["at_info_categories"]               = "Escolha quais categorias de auras rastrear.",
    ["at_cat_trinkets"]                  = "Procs de bijuteria",
    ["at_cat_enchants"]                  = "Procs de encantamento de arma",
    ["at_cat_selfbuffs"]                 = "Buffs pessoais (CDs)",
    ["at_cat_raidbuffs"]                 = "Buffs de raide",
    ["at_cat_defensives"]                = "Defensivos (externos + pessoais)",

    ["at_section_position"]              = "Posição",
    ["at_info_position"]                 = "Use /tm layout para desbloquear e arrastar o rastreador.",
    ["at_btn_reset_position"]            = "Redefinir posição",

    -- ═══════════════════════════════════
    -- Battle Text
    -- ═══════════════════════════════════
    ["cat_battletext"]                   = "Texto de combate",
    ["mover_battletext"]                 = "Texto de combate",

    ["bt_section_general"]               = "Geral",
    ["bt_info_description"]              = "Texto de combate rolante: dano e cura, recebido e causado.",
    ["bt_opt_enable"]                    = "Ativar texto de combate",

    ["bt_section_display"]               = "Exibição",
    ["bt_opt_outgoing"]                  = "Mostrar dano causado",
    ["bt_opt_incoming"]                  = "Mostrar dano recebido",
    ["bt_opt_overheal"]                  = "Mostrar sobrecura",
    ["bt_opt_throttle"]                  = "Agrupar ticks DoT/HoT",

    ["bt_section_appearance"]            = "Aparência",
    ["bt_opt_font_size"]                 = "Tamanho da fonte",
    ["bt_opt_throttle_window"]           = "Janela de agrupamento (seg)",

    ["bt_section_position"]              = "Posição",
    ["bt_info_position"]                 = "Use /tm layout para desbloquear e arrastar as zonas.",
    ["bt_btn_reset_position"]            = "Redefinir posições",

    ["bt_zone_outgoing"]                 = "Causado",
    ["bt_zone_incoming"]                 = "Recebido",
    ["bt_zone_heal_out"]                 = "Cura causada",
    ["bt_zone_heal_in"]                  = "Cura recebida",

    ["bt_cmd_help"]                      = "/tm bt <cmd>",
    ["bt_enabled"]                       = "ativado",
    ["bt_disabled"]                      = "desativado",
    ["bt_crit"]                          = "!",
    ["bt_zones_locked"]                  = "zonas bloqueadas",
    ["bt_zones_unlocked"]                = "zonas desbloqueadas",
    ["bt_reset_done"]                    = "posições redefinidas.",
    ["bt_miss_miss"]                     = "Errou",
    ["bt_miss_dodge"]                    = "Esquivou",
    ["bt_miss_parry"]                    = "Aparou",
    ["bt_miss_block"]                    = "Bloqueou",
    ["bt_miss_resist"]                   = "Resistiu",
    ["bt_miss_absorb"]                   = "Absorveu",
    ["bt_miss_immune"]                   = "Imune",
    ["bt_miss_evade"]                    = "Evasão",
    ["bt_miss_deflect"]                  = "Desviou",
    ["bt_miss_reflect"]                  = "Refletiu",

    -- =========== What's New Popup ===========
    ["wn_title"]                         = "Novidades",
    ["wn_version"]                       = "Vers\195\163o %s",
    ["wn_subtitle"]                      = "Veja o que mudou desde sua \195\186ltima atualiza\195\167\195\163o:",
    ["wn_btn_ok"]                        = "Entendi!",
    ["wn_footer"]                        = "Todas as configura\195\167\195\181es podem ser alteradas a qualquer momento via |cff0cd29f/tm|r.",

    -- 2.9.8
    ["wn_298_housing"]                   = "Novo m\195\179dulo Housing: hover de decora\195\167\195\163o, rel\195\179gio do editor e teleporte /tm home (Midnight+).",
    ["wn_298_housing_hover"]             = "Hover de decora\195\167\195\163o: mostra nome, custo de posicionamento e estoque restante; tecla modificadora para duplicar.",
    ["wn_298_housing_clock"]             = "Rel\195\179gio do editor: rel\195\179gio anal\195\179gico/digital com rastreamento de tempo por sess\195\163o e total.",
    ["wn_298_housing_teleport"]          = "/tm home: teleporta para sua casa ou sai automaticamente se estiver visitando.",
    ["wn_298_icons"]                     = "Novos \195\173cones de categoria: \195\173cone de casa para Housing, \195\173cone de monitor para Diagn\195\179sticos.",
    ["wn_298_locales"]                   = "Housing + painel Diagn\195\179sticos: suporte completo de locale para frFR, deDE, esES, itIT, ptBR.",

    -- 2.9.6
    ["wn_296_raid_frames"]               = "Novo módulo Quadros de raide: quadros de raid personalizados em grade ou lista.",
    ["wn_296_raid_health"]               = "Barras de vida, absorção e previsão de cura + barra de poder (apenas curandeiros).",
    ["wn_296_raid_auras"]                = "Rastreamento de debuffs e HoTs com bordas coloridas por tipo/classe.",
    ["wn_296_raid_utilities"]            = "Ícones de CDs defensivos, destaque de dissipação, esmaecimento fora de alcance, ícones de função, marcadores de raide e verificação de prontidão.",
    ["wn_296_raid_config"]               = "Painel de configuração completo com abas Geral e Recursos, 80+ chaves de idioma em 6 línguas.",

    -- 2.9.7
    ["wn_297_rf_live_preview"]           = "Quadros de raide: pré-visualização ao vivo no painel de configuração — 20 membros simulados atualizados em tempo real.",
    ["wn_297_rf_preview_layout"]         = "A pré-visualização mostra todos os modos: grade (rótulos G1–G4) ou lista (2 colunas), com funções e HoTs.",
    ["wn_297_rf_preview_scaling"]        = "Escala automática à largura do painel; reflete largura, altura, espaçamento, cor, nome, barra de poder e mais.",
    ["wn_297_taint_blizzard"]            = "Quadros de raide: ocultação de frames Blizzard reescrita (SetAlpha+SetScale) — corrige o taint de CompactPartyFrame e ArenaFrame.",
    ["wn_297_range_fix"]                 = "Quadros de raide: esmaecimento por distância corrigido para booleanos secretos do Midnight+ (SetAlphaFromBoolean).",
    ["wn_297_actionbars_fix"]            = "Barras de ação: inicialização adiada após o bloqueio de combate — corrige o taint de SecureStateDriver ao fazer login.",
    ["wn_297_mp_tracker"]                = "Mythic+: ObjectiveTrackerFrame agora é corretamente ocultado durante o modo desafio.",
    ["wn_297_role_icon"]                 = "Quadros de raide: tamanho padrão do ícone de função duplicado (10 → 20).",
    ["wn_297_castbar_fix"]               = "Barras de conjuração: a barra do jogador não desaparece mais em combate — FadeOut agora é idempotente e nil transitório não oculta mais a barra.",
    ["wn_297_diag_exclusions"]           = "Diagnósticos: mensagens de restrição de montaria e limite de mascotes excluídas da captura de erros.",

    -- 2.9.5
    ["wn_295_taint_fix"]                 = "CooldownTrackers: removido COMBAT_LOG_EVENT_UNFILTERED para corrigir taint (ADDON_ACTION_FORBIDDEN).",
    ["wn_295_diag_taint"]                = "Diagnósticos: erros de taint agora são sempre capturados, mesmo com diagnósticos desativados.",
    ["wn_295_tooltip_ids_moved"]         = "Opções de Tooltip IDs movidas do painel QOL para Skins > aba Tooltip.",
    ["wn_295_chat_text_offset"]          = "Skin do chat: texto levemente deslocado para a direita para liberar a barra lateral.",

    -- 2.9.4
    ["wn_294_installer"]                 = "Instalador expandido de 12 para 16 etapas guiadas.",
    ["wn_294_uf_pf"]                     = "Novas etapas: configura\195\167\195\163o de Unit Frames e Party Frames.",
    ["wn_294_cb_res"]                    = "Novas etapas: Barras de lan\195\167amento e Recursos / Gerenciador de cooldowns.",
    ["wn_294_skins_qol"]                 = "Etapa Skins aprimorada (bolsas, tooltips) e etapa QOL (minimapa, cursor, AFK, diagn\195\179sticos, rastreador de auras).",
    ["wn_294_bugfixes"]                  = "Corre\195\167\195\181es de valores secretos para TooltipIDs e CooldownTrackers (taint Midnight).",
    ["wn_294_locales"]                   = "50+ novas chaves de tradu\195\167\195\163o em todos os 6 idiomas.",

    -- 2.9.3
    ["wn_293_partyframe"]                = "Party Frames: \195\173cones de ready check, tooltip ao passar o mouse, reescrita de marcadores raid.",
    ["wn_293_actionbar_fix"]             = "Barras de a\195\167\195\163o: corre\195\167\195\163o de interatividade barras 1-4, corre\195\167\195\163o bot\195\181es vazios.",
    ["wn_293_chat_taint"]                = "Skin do chat: corre\195\167\195\181es de taint Midnight (guards GUID/BN secretos).",
    ["wn_293_diagnostics"]               = "Diagn\195\179sticos: exclus\195\163o por padr\195\163o, palavras-chave em 6 idiomas.",
    ["wn_293_autofill"]                  = "AutoFillDelete: corre\195\167\195\163o STATICPOPUP_NUMDIALOGS Midnight.",

    -- 2.9.2
    ["wn_292_actionbar"]                 = "Reescrita completa das barras de a\195\167\195\163o: arquitetura de container, sistema de fade, condi\195\167\195\181es de exibi\195\167\195\163o.",
    ["wn_292_diagnostics"]               = "Novo console de diagn\195\179sticos: captura de erros em segundo plano, exporta\195\167\195\163o, /tmdiag.",

    -- =====================
    -- CONFIG: Diagnostics Panel
    -- =====================
    ["section_diagnostics"]              = "Diagn\195\179sticos",
    ["opt_diag_enabled"]                 = "Ativar captura de erros",
    ["opt_diag_capture_all"]             = "Capturar todos os addons",
    ["opt_diag_suppress_popups"]         = "Suprimir janelas de erro",
    ["opt_diag_auto_open"]               = "Abrir automaticamente com erro do TomoMod",
    ["btn_diag_open_console"]            = "Abrir console",
    ["btn_diag_clear"]                   = "Limpar erros",
    ["btn_diag_export"]                  = "Copiar relat\195\179rio",
    ["btn_diag_export_tracker"]          = "Exportar para Tracker",
    ["info_diag_desc"]                   = "Captura erros Lua em segundo plano sem popups durante o combate. /tmdiag para abrir o console.",
    ["info_diag_session"]                = "Sess\195\163o: #%d \226\128\148 %d erros capturados (%d TomoMod)",
    ["info_diag_capture_all_desc"]       = "Quando desativado, apenas erros do TomoMod s\195\163o capturados. Ative para capturar todos os erros de addons.",

    -- =====================
    -- HOUSING
    -- =====================
    ["section_housing_general"]      = "Housing \226\128\148 Geral",
    ["section_housing_hover"]        = "Info decora\195\167\195\163o (hover)",
    ["section_housing_clock"]        = "Rel\195\179gio do editor",
    ["section_housing_teleport"]     = "Teleporte",
    ["section_housing_commands"]     = "Comandos",

    ["info_housing_desc"]            = "M\195\179dulo Housing: melhora o editor de casas e adiciona atalhos de teleporte. Requer Midnight / The War Within.",
    ["info_housing_hover"]           = "No modo 'Decora\195\167\195\163o base', exibe nome, custo de posicionamento e estoque restante. Tamb\195\169m permite duplicar com tecla modificadora.",
    ["info_housing_clock"]           = "Exibe um rel\195\179gio e registra o tempo no editor de casas. Clique direito para alternar entre anal\195\179gico e digital.",
    ["info_housing_teleport"]        = "Ativa /tm home: teleporta voc\195\170 para sua casa ou sai automaticamente se estiver visitando.",
    ["info_housing_commands"]        = "\226\128\162 /tm home \226\128\148 teleportar para sua casa (ou sair)\n\226\128\162 /tm housing \226\128\148 abrir este painel\n\226\128\162 Clique direito no rel\195\179gio \226\128\148 alternar anal\195\179gico/digital",

    ["opt_housing_enable"]           = "Ativar m\195\179dulo Housing",
    ["opt_housing_decorhover"]       = "Ativar info de decora\195\167\195\163o",
    ["opt_housing_dupe"]             = "Ativar duplica\195\167\195\163o r\195\161pida (modificador)",
    ["opt_housing_dupekey"]          = "Tecla de duplica\195\167\195\163o",
    ["opt_housing_clock"]            = "Ativar rel\195\179gio",
    ["opt_housing_clock_analog"]     = "Modo anal\195\179gico (sen\195\163o, digital)",
    ["opt_housing_teleport"]         = "Ativar teleporte /tm home",

    ["btn_housing_tp_home"]          = "Teleportar (teste)",
    ["btn_housing_refresh"]          = "Atualizar casas",

    ["housing_duplicate"]            = "Duplicar",
    ["housing_alliance_zone"]        = "Promontório do Fundador",
    ["housing_horde_zone"]           = "Costa do Vento Lâmina",
    ["housing_clock_title"]          = "TomoMod \226\128\148 Rel\195\179gio",
    ["housing_clock_time"]           = "Hora",
    ["housing_clock_local"]          = "Hora local:",
    ["housing_clock_realm"]          = "Hora do reino:",
    ["housing_clock_time_spent"]     = "Tempo no editor",
    ["housing_clock_session"]        = "Esta sess\195\163o:",
    ["housing_clock_total"]          = "Total:",
    ["housing_clock_rightclick"]     = "Clique direito para alternar anal\195\179gico / digital",

    ["msg_help_home"]                = "Teleportar para sua casa (ou sair)",
    ["msg_help_housing"]             = "Abrir o painel Housing",
    ["msg_housing_refresh"]          = "Informa\195\167\195\181es de casas solicitadas.",
    ["msg_housing_unavailable"]      = "M\195\179dulo Housing n\195\163o dispon\195\173vel neste cliente.",

    -- ═══════════════════════════════════
    -- Merchant Tools (2.9.9)
    -- ═══════════════════════════════════
    ["wn_299_merchant_tools"]             = "Novo módulo Ferramentas de vendedor: Já conhecido + Páginas estendidas (aba QOL).",
    ["wn_299_already_known"]              = "Já conhecido: dessatura ou tinge itens do vendedor/recompra que você já possui (montarias, mascotes, brinquedos, transmog, receitas).",
    ["wn_299_extend_pages"]               = "Páginas estendidas: a janela do vendedor pode mostrar até 4 colunas de 10 itens.",
    ["wn_299_locales"]                    = "Ferramentas de vendedor: suporte completo nos 6 idiomas.",

    ["tab_qol_merchant_tools"]           = "Ferramentas de vendedor",

    ["section_already_known"]            = "Já conhecido",
    ["info_already_known"]               = "Dessatura ou tinge itens do vendedor/recompra que você já possui (montarias, mascotes, brinquedos, conjuntos de transmog, receitas).",
    ["opt_ak_enable"]                    = "Ativar Já conhecido",
    ["opt_ak_mode"]                      = "Modo de exibição",
    ["ak_mode_mono"]                     = "Monocromático (cinza)",
    ["ak_mode_color"]                    = "Tonalidade de cor",
    ["opt_ak_color"]                     = "Cor da tonalidade",

    ["section_extend_pages"]             = "Páginas de vendedor estendidas",
    ["info_extend_pages"]                = "Adiciona colunas extras à janela do vendedor.\nRequer recarregamento da interface após ativar ou alterar o número de colunas.",
    ["opt_ep_enable"]                    = "Ativar páginas estendidas",
    ["opt_ep_columns"]                   = "Número de colunas",
})
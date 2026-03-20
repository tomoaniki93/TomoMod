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
    ["cat_profiles"]        = "Perfis",

    -- =====================
    -- CONFIG: General Panel
    -- =====================
    ["section_about"]                   = "Sobre",
    ["about_text"]                      = "|cff0cd29fTomoMod|r v2.4.2 por TomoAniki\nInterface leve com QOL, UnitFrames e Nameplates.\nDigite /tm help para a lista de comandos.",
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
    ["info_cdm_editmode"]               = "O posicionamento é feito pelo Edit Mode da Blizzard (Esc → Edit Mode).",

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
    ["opt_rb_primary_height"]           = "Altura da barra primária",
    ["opt_rb_secondary_height"]         = "Altura da barra secundária",
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
    ["info_rb_druid"]                   = "As barras se adaptam automaticamente à sua classe e especialização.\nDruida: o recurso muda com a forma (Urso → Fúria, Gato → Energia, Equilíbrio → Poder astral).",

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
    ["import_preview_valid"]            = "✓ String válida",
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
    ["opt_chat_skin_bg_alpha"]           = "Opacidade do fundo",
    ["opt_chat_skin_font_size"]          = "Tamanho da fonte do chat",
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
})

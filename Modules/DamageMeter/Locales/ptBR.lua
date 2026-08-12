local ADDON_NAME, TomoMod = ...

-- [MERGE] Standalone, `ns` was this addon's own private table. Embedded, the
-- vararg hands over TomoMod's, which every other file in the suite shares --
-- so 157 generic names (db, L, FONT, BG, ACCENT, Refresh, windows, inCombat)
-- would sit in the same table as everything TomoMod ever adds. Nothing
-- collides today, but the first core file that reaches for `ns.db` would
-- find this module's and neither would know.
--
-- One sub-table keeps the module's world to itself, and leaves every `ns.X`
-- below untouched.
local ns = TomoMod.DM

----------------------------------------------------------------------
-- Localization: Portuguese (Brazil)
----------------------------------------------------------------------

if GetLocale() ~= "ptBR" then return end

local L = ns.L

-- General
L["ADDON_NAME"]     = "TomoDamageMeter"
L["ADDON_SHORT"]    = "Tomo"

-- Meter types
L["DPS"]            = "DPS"
L["HPS"]            = "HPS"
L["DAMAGE_TAKEN"]   = "Dano recebido"
L["AVOIDABLE"]      = "Evitável"
L["ENEMY_DAMAGE"]   = "Dano inimigo"
L["ABSORBS"]        = "Absorções"
L["INTERRUPTS"]     = "Interrupções"
L["DISPELS"]        = "Dissipações"
L["DEATHS"]         = "Mortes"

-- Categories
L["DAMAGE"]         = "Dano"
L["HEALING"]        = "Cura"
L["ACTIONS"]        = "Ações"

-- Sessions
L["CURRENT"]        = "Atual"
L["OVERALL"]        = "Total"

-- Header / UI
L["RESET"]          = "Redefinir"
L["LOCK"]           = "Travar"
L["UNLOCK"]         = "Destravar"
L["SETTINGS"]       = "Configurações"
L["REPORT"]         = "Relatório"
L["CLOSE"]          = "Fechar"

-- Format labels
L["FMT_COMPACT"]    = "Compacto"
L["FMT_1DEC"]       = "1 Dec"
L["FMT_2DEC"]       = "2 Dec"
L["FMT_REGULAR"]    = "Regular"
L["FMT_INT"]        = "Inteiro"
L["FMT_DEC"]        = "Decimal"

-- Report
L["REPORT_HEADER"]          = "TomoDamageMeter: %s (%s)"
L["REPORT_NO_TARGET"]       = "Nenhum alvo de sussurro. Selecione um jogador primeiro."
L["REPORT_NO_DATA"]         = "Sem dados para relatar."
L["REPORT_CHANNEL_SAY"]     = "Dizer"
L["REPORT_CHANNEL_PARTY"]   = "Grupo"
L["REPORT_CHANNEL_RAID"]    = "Raide"
L["REPORT_CHANNEL_GUILD"]   = "Guilda"
L["REPORT_CHANNEL_WHISPER"] = "Sussurrar"
L["REPORT_CHANNEL_AUTO"] = "Auto (grupo)"
L["REPORT_CHANNEL_INSTANCE"] = "Instância"
L["REPORT_CHANNEL_SELF"] = "Exibir só para mim"
L["REPORT_CHANNEL_RESTRICTED"] = "Falar e Gritar são restritos pelo jogo: só passa uma mensagem por clique. Escolha um canal de grupo nas configurações."

-- Settings
L["SETTINGS_TITLE"]             = "Configurações do TomoDamageMeter"
L["SETTINGS_GENERAL"]           = "Geral"
L["SETTINGS_APPEARANCE"]        = "Aparência"
L["SETTINGS_SKIN"] = "Skin"
L["SETTINGS_BAR_TEXTURE"] = "Textura das barras"
L["SKIN_DARK"] = "Tomo Dark"
L["SKIN_NEON"] = "Tomo Neon"
L["SKIN_MINIMAL"] = "Minimalista"
L["SKIN_GLOSSY"] = "Brilhante"
L["SKIN_EMBER"] = "Brasa"
L["SKIN_FROST"] = "Geada"
L["SKIN_TERMINAL"] = "Terminal"
L["SKIN_VOID"] = "Vazio"
L["SKIN_PARCHMENT"] = "Pergaminho"
L["SETTINGS_COLUMNS"]           = "Colunas"
L["SETTINGS_FONT_SIZE"]         = "Tamanho da fonte"
L["SETTINGS_FONT_FACE"]         = "Fonte"
L["SETTINGS_BAR_HEIGHT"]        = "Altura da barra"
L["SETTINGS_BG_OPACITY"]        = "Opacidade do fundo"
L["SETTINGS_OOC_OPACITY"]       = "Opacidade fora de combate"
L["SETTINGS_BREAKDOWN_OPACITY"] = "Opacidade detalhamento de feitiço"
L["SETTINGS_STRIP_REALM"]       = "Remover nome de reino"
L["SETTINGS_ACCENT_COLOR"]      = "Cor de destaque"
L["SETTINGS_USE_CLASS_COLOR"]   = "Usar cor da classe"
L["SETTINGS_REPORT_CHANNEL"]    = "Canal de relatório"
L["SETTINGS_REPORT_LINES"]      = "Linhas do relatório"
L["SETTINGS_WINDOWS"]           = "Janelas"
L["SETTINGS_ADD_WINDOW"]        = "+ Adicionar"
L["SETTINGS_REMOVE_WINDOW"]     = "- Remover"
L["SETTINGS_WINDOW_COUNT"]      = "Janelas: %d / %d"
L["SETTINGS_COL_RATE"]          = "Taxa (DPS/HPS)"
L["SETTINGS_COL_TOTAL"]         = "Total"
L["SETTINGS_COL_PCT"]           = "Percentual"
L["SETTINGS_TAB_GENERAL"]       = "Geral"
L["SETTINGS_TAB_WINDOW"]        = "Janela %d"
L["SETTINGS_METER_TYPE"]        = "Tipo de medidor"
L["SETTINGS_SESSION_TYPE"]      = "Tipo de sessão"
L["SETTINGS_LOCKED"]            = "Posição travada"

-- Slash commands
L["CMD_RESET"]          = "Dados redefinidos."
L["CMD_LOCKED"]         = "Travado"
L["CMD_UNLOCKED"]       = "Destravado"
L["CMD_HELP_HEADER"]    = "Comandos:"
L["CMD_HELP_TOGGLE"]    = "  /tdm — abrir configurações"
L["CMD_HELP_TOGGLE_VIS"]= "  /tdm toggle — alternar visibilidade da janela"
L["CMD_HELP_RESET"]     = "  /tdm reset — redefinir todos os dados de combate"
L["CMD_HELP_LOCK"]      = "  /tdm lock — travar/destravar posição da janela"
L["CMD_HELP_HELP"]      = "  /tdm help — esta mensagem"

-- Auto-reset
L["SETTINGS_AUTO_RESET_INSTANCE"] = "Redefinição automática ao entrar em instância"
L["SETTINGS_COMBAT_TIMER"] = "Cronômetro de combate (DPS/HPS)"
L["SETTINGS_SELF_BAR"] = "Fixar minha própria barra"
L["SETTINGS_BAR_TOOLTIPS"] = "Dicas das barras (ao passar)"
L["SETTINGS_MODULES"] = "Módulos"
L["SETTINGS_DEATH_RECAP_AUTO"] = "Recapitulação de morte ao morrer"
L["SETTINGS_TIMER_POSITION"] = "Posição do cronômetro"
L["TIMER_POS_RIGHT"] = "Direita"
L["TIMER_POS_LEFT"] = "Esquerda"
L["SETTINGS_CATEGORIES"] = "Categorias"
L["SETTINGS_CATEGORIES_MIN"] = "Pelo menos uma categoria deve permanecer ativada."
L["AUTO_RESET_MSG"]                = "Dados redefinidos automaticamente (entrada em instância)."

-- Combat
L["COMBAT_SETTINGS_UNAVAILABLE"] = "Configurações indisponíveis durante o combate."
L["WAITING_COMBAT_END"]          = "Indisponível até o fim do combate"

-- Detail
L["SPELL_BREAKDOWN"] = "Detalhamento de feitiço"
L["NO_DATA"]         = "Nenhum dado disponível"
L["DEATH_RECAP"] = "Recapitulação de morte"
L["DEATH_RECAP_NO_DATA"] = "Nenhuma morte registrada"
L["RECAP_HEAL"] = "Cura"
L["RECAP_MELEE"] = "Corpo a corpo"
L["RECAP_UNKNOWN"] = "Desconhecido"
L["BREAKDOWN_SPELLS_LABEL"] = "feitiços"
L["BREAKDOWN_CRITS_LABEL"]  = "críts"
L["BREAKDOWN_CRIT_RATE_LABEL"] = "crít"
L["BREAKDOWN_COL_SPELL"] = "Feitiço"
L["BREAKDOWN_COL_TOTAL"] = "Total"

-- Segments / Target Breakdown
L["SEGMENTS"] = "Segmentos"
L["SEGMENT"] = "Segmento"
L["SEGMENT_COL_NAME"] = "Encontro"
L["TARGET_BREAKDOWN"] = "Detalhamento de alvos"
L["TARGET_COL_NAME"] = "Alvo"

-- Tooltips
L["TIP_SETTINGS"] = "Abrir configurações"
L["TIP_TARGET"] = "Detalhamento de alvos"
L["TIP_DETAILS"] = "Detalhamento de feitiço"
L["TIP_LOCK"] = "Travar/destravar posição"
L["TIP_REPORT"] = "Relatar no chat"
L["TIP_RESET"] = "Redefinir todos os dados"
L["TIP_CATEGORY"] = "Clique para mudar categoria"
L["TIP_TYPE"] = "Clique para mudar tipo"
L["TIP_SESSION"] = "Clique para mudar sessão"

-- Dicas ao passar o mouse
L["TIP_TOP_SPELLS"] = "Principais magias"
L["TIP_TOTAL"] = "Total"
L["TIP_OVERKILL"] = "Dano excedente"
L["TIP_AVOIDABLE"] = "Dano evitável"
L["TIP_KILLING_BLOW"] = "Golpe fatal"
L["TIP_CAST_BY"] = "Conjurado por %s"
L["TIP_CLICK_BREAKDOWN"] = "Clique para detalhar as magias"
L["TIP_LEFT_EXPAND"] = "Clique esquerdo: mostrar magias em linha"
L["TIP_RIGHT_WINDOW"] = "Clique direito: abrir janela de detalhes"

-- Font names
L["FONT_FRIZ"] = "Fritz Quadrata"
L["FONT_ARIAL"] = "Arial Narrow"
L["FONT_2002"] = "2002"
L["FONT_MORPHEUS"] = "Morpheus"
L["FONT_SKURRI"] = "Skurri"

L["FILTER_PLAYERS"] = "Filtrar..."

L["ADDON_PREFIX"] = "|cffe0115fTomo DM :|r "

L["FMT_3DEC"] = "3 Dec"
L["SETTINGS_FORMAT"] = "Formato"
L["SETTINGS_SNAP"] = "Encaixar as janelas entre si"
L["SETTINGS_RUN_RECAP_AUTO"] = "Mostrar o resumo ao fim de uma masmorra"
L["RUN_RECAP"] = "Resumo da run"
L["RUN_RECAP_NO_DATA"] = "Nenhuma run registrada"
L["RECAP_COL_INT"] = "Interr."
L["RECAP_COL_DEATHS"] = "Mortes"
L["RECAP_COL_AVOIDABLE"] = "Evit."
L["CMD_HELP_RECAP"] = "  /tdm recap — mostrar o último resumo"
L["CMD_HELP_DIAG"] = "  /tdm diag — testar a legibilidade dos valores de C_DamageMeter"
L["CMD_DIAG_ARMED"] = "Diagnóstico armado — aguardando a próxima atualização de dados de combate."

L["CMD_HELP_RESETPOS"] = "  /tdm resetpos — devolver o resumo de morte ao centro"
L["CMD_POS_RESET"] = "Posição do resumo de morte redefinida."

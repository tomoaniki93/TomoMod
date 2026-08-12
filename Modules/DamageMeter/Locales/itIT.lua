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
-- Localization: Italian
----------------------------------------------------------------------

if GetLocale() ~= "itIT" then return end

local L = ns.L

-- General
L["ADDON_NAME"]     = "TomoDamageMeter"
L["ADDON_SHORT"]    = "Tomo"

-- Meter types
L["DPS"]            = "DPS"
L["HPS"]            = "HPS"
L["DAMAGE_TAKEN"]   = "Danno subito"
L["AVOIDABLE"]      = "Evitabile"
L["ENEMY_DAMAGE"]   = "Danno nemico"
L["ABSORBS"]        = "Assorbimenti"
L["INTERRUPTS"]     = "Interruzioni"
L["DISPELS"]        = "Dissoluzioni"
L["DEATHS"]         = "Morti"

-- Categories
L["DAMAGE"]         = "Danno"
L["HEALING"]        = "Cura"
L["ACTIONS"]        = "Azioni"

-- Sessions
L["CURRENT"]        = "Attuale"
L["OVERALL"]        = "Totale"

-- Header / UI
L["RESET"]          = "Resetta"
L["LOCK"]           = "Blocca"
L["UNLOCK"]         = "Sblocca"
L["SETTINGS"]       = "Impostazioni"
L["REPORT"]         = "Rapporto"
L["CLOSE"]          = "Chiudi"

-- Format labels
L["FMT_COMPACT"]    = "Compatto"
L["FMT_1DEC"]       = "1 Dec"
L["FMT_2DEC"]       = "2 Dec"
L["FMT_REGULAR"]    = "Regolare"
L["FMT_INT"]        = "Intero"
L["FMT_DEC"]        = "Decimale"

-- Report
L["REPORT_HEADER"]          = "TomoDamageMeter: %s (%s)"
L["REPORT_NO_TARGET"]       = "Nessun bersaglio sussurrato. Seleziona prima un giocatore."
L["REPORT_NO_DATA"]         = "Nessun dato da riportare."
L["REPORT_CHANNEL_SAY"]     = "Dire"
L["REPORT_CHANNEL_PARTY"]   = "Gruppo"
L["REPORT_CHANNEL_RAID"]    = "Incursione"
L["REPORT_CHANNEL_GUILD"]   = "Gilda"
L["REPORT_CHANNEL_WHISPER"] = "Sussurro"
L["REPORT_CHANNEL_AUTO"] = "Auto (gruppo)"
L["REPORT_CHANNEL_INSTANCE"] = "Istanza"
L["REPORT_CHANNEL_SELF"] = "Mostra solo a me"
L["REPORT_CHANNEL_RESTRICTED"] = "Dire e Urlare sono limitati dal gioco: passa un solo messaggio per clic. Scegli un canale di gruppo nelle impostazioni."

-- Settings
L["SETTINGS_TITLE"]             = "Impostazioni TomoDamageMeter"
L["SETTINGS_GENERAL"]           = "Generale"
L["SETTINGS_APPEARANCE"]        = "Aspetto"
L["SETTINGS_SKIN"] = "Skin"
L["SETTINGS_BAR_TEXTURE"] = "Texture barre"
L["SKIN_DARK"] = "Tomo Dark"
L["SKIN_NEON"] = "Tomo Neon"
L["SKIN_MINIMAL"] = "Minimale"
L["SKIN_GLOSSY"] = "Lucido"
L["SKIN_EMBER"] = "Brace"
L["SKIN_FROST"] = "Gelo"
L["SKIN_TERMINAL"] = "Terminale"
L["SKIN_VOID"] = "Vuoto"
L["SKIN_PARCHMENT"] = "Pergamena"
L["SETTINGS_COLUMNS"]           = "Colonne"
L["SETTINGS_FONT_SIZE"]         = "Dimensione carattere"
L["SETTINGS_FONT_FACE"]         = "Carattere"
L["SETTINGS_BAR_HEIGHT"]        = "Altezza barra"
L["SETTINGS_BG_OPACITY"]        = "Opacità sfondo"
L["SETTINGS_OOC_OPACITY"]       = "Opacità fuori combattimento"
L["SETTINGS_BREAKDOWN_OPACITY"] = "Opacità dettaglio incantesimi"
L["SETTINGS_OPACITY"] = "Opacità"
L["SETTINGS_RECAPS"] = "Riepiloghi"
L["SETTINGS_SHOW_SELF"] = "Mostra sempre la mia barra"
L["SETTINGS_BAR_TOOLTIPS"] = "Descrizioni sulle barre"
L["SETTINGS_TIMER_POS"] = "Posizione del timer"
L["SETTINGS_TIMER_LEFT"] = "Sinistra"
L["SETTINGS_TIMER_RIGHT"] = "Destra"
L["SETTINGS_AUTO_RESET"] = "Azzera entrando in un'istanza"
L["SETTINGS_DEATH_RECAP_AUTO"] = "Mostra il riepilogo morte automaticamente"
L["DM_STANDALONE"] = "L'addon TomoDamageMeter autonomo è installato e gestisce il misuratore; le sue impostazioni sono nella sua finestra. Il modulo integrato resta inattivo."
L["DM_UNAVAILABLE"] = "Il misuratore di danni di Blizzard non è disponibile su questo client, il modulo è inattivo."
L["DM_WINDOWS_HINT"] = "Colonne, aggiunta di finestre e filtri per categoria si impostano nella finestra del misuratore."
L["DM_OPEN_WINDOW_SETTINGS"] = "Impostazioni finestre"
L["DM_TOGGLE_WINDOWS"] = "Mostra / nascondi"
L["SETTINGS_STRIP_REALM"]       = "Rimuovi nome reame"
L["SETTINGS_ACCENT_COLOR"]      = "Colore accento"
L["SETTINGS_USE_CLASS_COLOR"]   = "Usa colore classe"
L["SETTINGS_REPORT_CHANNEL"]    = "Canale rapporto"
L["SETTINGS_REPORT_LINES"]      = "Righe rapporto"
L["SETTINGS_WINDOWS"]           = "Finestre"
L["SETTINGS_ADD_WINDOW"]        = "+ Aggiungi"
L["SETTINGS_REMOVE_WINDOW"]     = "- Rimuovi"
L["SETTINGS_WINDOW_COUNT"]      = "Finestre: %d / %d"
L["SETTINGS_COL_RATE"]          = "Tasso (DPS/HPS)"
L["SETTINGS_COL_TOTAL"]         = "Totale"
L["SETTINGS_COL_PCT"]           = "Percentuale"
L["SETTINGS_TAB_GENERAL"]       = "Generale"
L["SETTINGS_TAB_WINDOW"]        = "Finestra %d"
L["SETTINGS_METER_TYPE"]        = "Tipo di misuratore"
L["SETTINGS_SESSION_TYPE"]      = "Tipo di sessione"
L["SETTINGS_LOCKED"]            = "Posizione bloccata"

-- Slash commands
L["CMD_RESET"]          = "Dati resettati."
L["CMD_LOCKED"]         = "Bloccato"
L["CMD_UNLOCKED"]       = "Sbloccato"
L["CMD_HELP_HEADER"]    = "Comandi:"
L["CMD_HELP_TOGGLE"]    = "  /tdm — apri impostazioni"
L["CMD_HELP_TOGGLE_VIS"]= "  /tdm toggle — mostra/nascondi finestra"
L["CMD_HELP_RESET"]     = "  /tdm reset — resetta tutti i dati di combattimento"
L["CMD_HELP_LOCK"]      = "  /tdm lock — blocca/sblocca posizione finestra"
L["CMD_HELP_HELP"]      = "  /tdm help — questo messaggio"

-- Auto-reset
L["SETTINGS_AUTO_RESET_INSTANCE"] = "Auto-reset all'ingresso in istanza"
L["SETTINGS_COMBAT_TIMER"] = "Timer di combattimento (DPS/HPS)"
L["SETTINGS_SELF_BAR"] = "Fissa la mia barra"
L["SETTINGS_BAR_TOOLTIPS"] = "Tooltip delle barre (al passaggio)"
L["SETTINGS_MODULES"] = "Moduli"
L["SETTINGS_DEATH_RECAP_AUTO"] = "Riepilogo morte alla morte"
L["SETTINGS_TIMER_POSITION"] = "Posizione del timer"
L["TIMER_POS_RIGHT"] = "Destra"
L["TIMER_POS_LEFT"] = "Sinistra"
L["SETTINGS_CATEGORIES"] = "Categorie"
L["SETTINGS_CATEGORIES_MIN"] = "Almeno una categoria deve rimanere attivata."
L["AUTO_RESET_MSG"]                = "Dati resettati automaticamente (ingresso in istanza)."

-- Combat
L["COMBAT_SETTINGS_UNAVAILABLE"] = "Impostazioni non disponibili durante il combattimento."
L["WAITING_COMBAT_END"]          = "Non disponibile fino a dopo il combattimento"

-- Detail
L["SPELL_BREAKDOWN"] = "Dettaglio incantesimi"
L["NO_DATA"]         = "Nessun dato disponibile"
L["DEATH_RECAP"] = "Riepilogo morte"
L["DEATH_RECAP_NO_DATA"] = "Nessuna morte registrata"
L["RECAP_HEAL"] = "Cura"
L["RECAP_MELEE"] = "Mischia"
L["RECAP_UNKNOWN"] = "Sconosciuto"
L["BREAKDOWN_SPELLS_LABEL"] = "incantesimi"
L["BREAKDOWN_CRITS_LABEL"]  = "critici"
L["BREAKDOWN_CRIT_RATE_LABEL"] = "crit"
L["BREAKDOWN_COL_SPELL"] = "Incantesimo"
L["BREAKDOWN_COL_TOTAL"] = "Totale"

-- Segments / Target Breakdown
L["SEGMENTS"] = "Segmenti"
L["SEGMENT"] = "Segmento"
L["SEGMENT_COL_NAME"] = "Incontro"
L["TARGET_BREAKDOWN"] = "Dettaglio bersagli"
L["TARGET_COL_NAME"] = "Bersaglio"

-- Tooltips
L["TIP_SETTINGS"] = "Apri impostazioni"
L["TIP_TARGET"] = "Dettaglio bersagli"
L["TIP_DETAILS"] = "Dettaglio incantesimi"
L["TIP_LOCK"] = "Blocca/sblocca posizione"
L["TIP_REPORT"] = "Invia rapporto in chat"
L["TIP_RESET"] = "Resetta tutti i dati"
L["TIP_CATEGORY"] = "Clicca per cambiare categoria"
L["TIP_TYPE"] = "Clicca per cambiare tipo"
L["TIP_SESSION"] = "Clicca per cambiare sessione"

-- Tooltip al passaggio
L["TIP_TOP_SPELLS"] = "Migliori incantesimi"
L["TIP_TOTAL"] = "Totale"
L["TIP_OVERKILL"] = "Danno in eccesso"
L["TIP_AVOIDABLE"] = "Danno evitabile"
L["TIP_KILLING_BLOW"] = "Colpo mortale"
L["TIP_CAST_BY"] = "Lanciato da %s"
L["TIP_CLICK_BREAKDOWN"] = "Clicca per il dettaglio incantesimi"
L["TIP_LEFT_EXPAND"] = "Clic sinistro: mostra incantesimi in linea"
L["TIP_RIGHT_WINDOW"] = "Clic destro: apri finestra dettaglio"

-- Font names
L["FONT_FRIZ"] = "Fritz Quadrata"
L["FONT_ARIAL"] = "Arial Narrow"
L["FONT_2002"] = "2002"
L["FONT_MORPHEUS"] = "Morpheus"
L["FONT_SKURRI"] = "Skurri"

L["FILTER_PLAYERS"] = "Filtra..."

L["ADDON_PREFIX"] = "|cffe0115fTomo DM :|r "

L["FMT_3DEC"] = "3 Dec"
L["SETTINGS_FORMAT"] = "Formato"
L["SETTINGS_SNAP"] = "Aggancia le finestre tra loro"
L["SETTINGS_RUN_RECAP_AUTO"] = "Mostra il riepilogo alla fine di una spedizione"
L["RUN_RECAP"] = "Riepilogo della run"
L["RUN_RECAP_NO_DATA"] = "Nessuna run registrata"
L["RECAP_COL_INT"] = "Interr."
L["RECAP_COL_DEATHS"] = "Morti"
L["RECAP_COL_AVOIDABLE"] = "Evit."
L["CMD_HELP_RECAP"] = "  /tdm recap — mostra l'ultimo riepilogo"
L["CMD_HELP_DIAG"] = "  /tdm diag — verifica la leggibilità dei valori di C_DamageMeter"
L["CMD_DIAG_ARMED"] = "Diagnostica attivata — in attesa del prossimo aggiornamento dei dati di combattimento."

L["CMD_HELP_RESETPOS"] = "  /tdm resetpos — riporta il riepilogo di morte al centro"
L["CMD_POS_RESET"] = "Posizione del riepilogo di morte reimpostata."

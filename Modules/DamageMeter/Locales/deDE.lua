local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- Localization: German
----------------------------------------------------------------------

if GetLocale() ~= "deDE" then return end

local L = ns.L

-- General
L["ADDON_NAME"]     = "TomoDamageMeter"
L["ADDON_SHORT"]    = "Tomo"

-- Meter types
L["DPS"]            = "DPS"
L["HPS"]            = "HPS"
L["DAMAGE_TAKEN"]   = "Erlittener Schaden"
L["AVOIDABLE"]      = "Vermeidbar"
L["ENEMY_DAMAGE"]   = "Feindschaden"
L["ABSORBS"]        = "Absorbierungen"
L["INTERRUPTS"]     = "Unterbrechungen"
L["DISPELS"]        = "Entzauberungen"
L["DEATHS"]         = "Tode"

-- Categories
L["DAMAGE"]         = "Schaden"
L["HEALING"]        = "Heilung"
L["ACTIONS"]        = "Aktionen"

-- Sessions
L["CURRENT"]        = "Aktuell"
L["OVERALL"]        = "Gesamt"

-- Header / UI
L["RESET"]          = "Zurücksetzen"
L["LOCK"]           = "Sperren"
L["UNLOCK"]         = "Entsperren"
L["SETTINGS"]       = "Einstellungen"
L["REPORT"]         = "Bericht"
L["CLOSE"]          = "Schließen"

-- Format labels
L["FMT_COMPACT"]    = "Kompakt"
L["FMT_1DEC"]       = "1 Dez"
L["FMT_2DEC"]       = "2 Dez"
L["FMT_REGULAR"]    = "Regulär"
L["FMT_INT"]        = "Ganzzahl"
L["FMT_DEC"]        = "Dezimal"

-- Report
L["REPORT_HEADER"]          = "TomoDamageMeter: %s (%s)"
L["REPORT_NO_TARGET"]       = "Kein Flüsterziel. Wähle zuerst einen Spieler."
L["REPORT_NO_DATA"]         = "Keine Daten zum Berichten."
L["REPORT_CHANNEL_SAY"]     = "Sagen"
L["REPORT_CHANNEL_PARTY"]   = "Gruppe"
L["REPORT_CHANNEL_RAID"]    = "Schlachtzug"
L["REPORT_CHANNEL_GUILD"]   = "Gilde"
L["REPORT_CHANNEL_WHISPER"] = "Flüstern"
L["REPORT_CHANNEL_AUTO"] = "Auto (Gruppe)"
L["REPORT_CHANNEL_INSTANCE"] = "Instanz"
L["REPORT_CHANNEL_SELF"] = "Nur für mich anzeigen"
L["REPORT_CHANNEL_RESTRICTED"] = "Sagen und Schreien sind vom Spiel eingeschränkt: pro Klick kommt nur eine Addon-Nachricht durch. Wähle in den Einstellungen einen Gruppenkanal."

-- Settings
L["SETTINGS_TITLE"]             = "TomoDamageMeter Einstellungen"
L["SETTINGS_GENERAL"]           = "Allgemein"
L["SETTINGS_APPEARANCE"]        = "Aussehen"
L["SETTINGS_SKIN"] = "Skin"
L["SETTINGS_BAR_TEXTURE"] = "Balkentextur"
L["SKIN_DARK"] = "Tomo Dark"
L["SKIN_NEON"] = "Tomo Neon"
L["SKIN_MINIMAL"] = "Minimal"
L["SKIN_GLOSSY"] = "Glänzend"
L["SKIN_EMBER"] = "Glut"
L["SKIN_FROST"] = "Frost"
L["SKIN_TERMINAL"] = "Terminal"
L["SKIN_VOID"] = "Leere"
L["SKIN_PARCHMENT"] = "Pergament"
L["SETTINGS_COLUMNS"]           = "Spalten"
L["SETTINGS_FONT_SIZE"]         = "Schriftgröße"
L["SETTINGS_FONT_FACE"]         = "Schriftart"
L["SETTINGS_BAR_HEIGHT"]        = "Balkenhöhe"
L["SETTINGS_BG_OPACITY"]        = "Hintergrundtransparenz"
L["SETTINGS_OOC_OPACITY"]       = "Transparenz außerhalb des Kampfes"
L["SETTINGS_BREAKDOWN_OPACITY"] = "Zauberdetail-Transparenz"
L["SETTINGS_STRIP_REALM"]       = "Realmname ausblenden"
L["SETTINGS_ACCENT_COLOR"]      = "Akzentfarbe"
L["SETTINGS_USE_CLASS_COLOR"]   = "Klassenfarbe verwenden"
L["SETTINGS_REPORT_CHANNEL"]    = "Berichtskanal"
L["SETTINGS_REPORT_LINES"]      = "Berichtszeilen"
L["SETTINGS_WINDOWS"]           = "Fenster"
L["SETTINGS_ADD_WINDOW"]        = "+ Hinzufügen"
L["SETTINGS_REMOVE_WINDOW"]     = "- Entfernen"
L["SETTINGS_WINDOW_COUNT"]      = "Fenster: %d / %d"
L["SETTINGS_COL_RATE"]          = "Rate (DPS/HPS)"
L["SETTINGS_COL_TOTAL"]         = "Gesamt"
L["SETTINGS_COL_PCT"]           = "Prozent"
L["SETTINGS_TAB_GENERAL"]       = "Allgemein"
L["SETTINGS_TAB_WINDOW"]        = "Fenster %d"
L["SETTINGS_METER_TYPE"]        = "Anzeigetyp"
L["SETTINGS_SESSION_TYPE"]      = "Sitzungstyp"
L["SETTINGS_LOCKED"]            = "Position gesperrt"

-- Slash commands
L["CMD_RESET"]          = "Daten zurückgesetzt."
L["CMD_LOCKED"]         = "Gesperrt"
L["CMD_UNLOCKED"]       = "Entsperrt"
L["CMD_HELP_HEADER"]    = "Befehle:"
L["CMD_HELP_TOGGLE"]    = "  /tdm — Einstellungen öffnen"
L["CMD_HELP_TOGGLE_VIS"]= "  /tdm toggle — Fenster ein-/ausblenden"
L["CMD_HELP_RESET"]     = "  /tdm reset — Alle Kampfdaten zurücksetzen"
L["CMD_HELP_LOCK"]      = "  /tdm lock — Fensterposition sperren/entsperren"
L["CMD_HELP_HELP"]      = "  /tdm help — diese Nachricht"

-- Auto-reset
L["SETTINGS_AUTO_RESET_INSTANCE"] = "Auto-Reset beim Instanzbeitritt"
L["SETTINGS_COMBAT_TIMER"] = "Kampf-Timer (DPS/HPS)"
L["SETTINGS_SELF_BAR"] = "Eigene Leiste anheften"
L["SETTINGS_BAR_TOOLTIPS"] = "Leisten-Tooltips (Mauszeiger)"
L["SETTINGS_MODULES"] = "Module"
L["SETTINGS_DEATH_RECAP_AUTO"] = "Todes-Rückblick beim Tod anzeigen"
L["SETTINGS_TIMER_POSITION"] = "Position des Kampf-Timers"
L["TIMER_POS_RIGHT"] = "Rechts"
L["TIMER_POS_LEFT"] = "Links"
L["SETTINGS_CATEGORIES"] = "Kategorien"
L["SETTINGS_CATEGORIES_MIN"] = "Mindestens eine Kategorie muss aktiviert bleiben."
L["AUTO_RESET_MSG"]                = "Daten automatisch zurückgesetzt (Instanzbeitritt)."

-- Combat
L["COMBAT_SETTINGS_UNAVAILABLE"] = "Einstellungen im Kampf nicht verfügbar."
L["WAITING_COMBAT_END"]          = "Nicht verfügbar bis nach dem Kampf"

-- Detail
L["SPELL_BREAKDOWN"] = "Zauberaufteilung"
L["NO_DATA"]         = "Keine Daten verfügbar"
L["DEATH_RECAP"] = "Todes-Rückblick"
L["DEATH_RECAP_NO_DATA"] = "Kein Tod aufgezeichnet"
L["RECAP_HEAL"] = "Heilung"
L["RECAP_MELEE"] = "Nahkampf"
L["RECAP_UNKNOWN"] = "Unbekannt"
L["BREAKDOWN_SPELLS_LABEL"] = "Zauber"
L["BREAKDOWN_CRITS_LABEL"]  = "Krits"
L["BREAKDOWN_CRIT_RATE_LABEL"] = "Krit"
L["BREAKDOWN_COL_SPELL"] = "Zauber"
L["BREAKDOWN_COL_TOTAL"] = "Total"

-- Segments / Target Breakdown
L["SEGMENTS"] = "Segmente"
L["SEGMENT"] = "Segment"
L["SEGMENT_COL_NAME"] = "Begegnung"
L["TARGET_BREAKDOWN"] = "Zielaufschlüsselung"
L["TARGET_COL_NAME"] = "Ziel"

-- Tooltips
L["TIP_SETTINGS"] = "Einstellungen öffnen"
L["TIP_TARGET"] = "Zielaufschlüsselung"
L["TIP_DETAILS"] = "Zauberaufteilung"
L["TIP_LOCK"] = "Position sperren/entsperren"
L["TIP_REPORT"] = "Im Chat melden"
L["TIP_RESET"] = "Alle Daten zurücksetzen"
L["TIP_CATEGORY"] = "Klicken zum Kategoriewechsel"
L["TIP_TYPE"] = "Klicken zum Typwechsel"
L["TIP_SESSION"] = "Klicken zum Sitzungswechsel"

-- Tooltips (Mauszeiger)
L["TIP_TOP_SPELLS"] = "Top-Zauber"
L["TIP_TOTAL"] = "Gesamt"
L["TIP_OVERKILL"] = "Overkill"
L["TIP_AVOIDABLE"] = "Vermeidbarer Schaden"
L["TIP_KILLING_BLOW"] = "Todesstoß"
L["TIP_CAST_BY"] = "Gewirkt von %s"
L["TIP_CLICK_BREAKDOWN"] = "Klicken für Zauberaufschlüsselung"
L["TIP_LEFT_EXPAND"] = "Linksklick: Zauber inline anzeigen"
L["TIP_RIGHT_WINDOW"] = "Rechtsklick: Aufschlüsselungsfenster öffnen"

-- Font names
L["FONT_FRIZ"] = "Fritz Quadrata"
L["FONT_ARIAL"] = "Arial Narrow"
L["FONT_2002"] = "2002"
L["FONT_MORPHEUS"] = "Morpheus"
L["FONT_SKURRI"] = "Skurri"

L["FILTER_PLAYERS"] = "Filtern..."

L["ADDON_PREFIX"] = "|cffe0115fTomo DM :|r "

L["FMT_3DEC"] = "3 Dez."
L["SETTINGS_FORMAT"] = "Format"
L["SETTINGS_SNAP"] = "Fenster aneinander andocken"
L["SETTINGS_RUN_RECAP_AUTO"] = "Run-Auswertung am Ende eines Dungeons anzeigen"
L["RUN_RECAP"] = "Run-Auswertung"
L["RUN_RECAP_NO_DATA"] = "Kein Run aufgezeichnet"
L["RECAP_COL_INT"] = "Unterbr."
L["RECAP_COL_DEATHS"] = "Tode"
L["RECAP_COL_AVOIDABLE"] = "Verm."
L["CMD_HELP_RECAP"] = "  /tdm recap — letzte Run-Auswertung anzeigen"
L["CMD_HELP_DIAG"] = "  /tdm diag — Lesbarkeit der C_DamageMeter-Werte prüfen"
L["CMD_DIAG_ARMED"] = "Diagnose scharf — warte auf die nächste Kampfdaten-Aktualisierung."

L["CMD_HELP_RESETPOS"] = "  /tdm resetpos — Todesrückblick zurück in die Mitte"
L["CMD_POS_RESET"] = "Position des Todesrückblicks zurückgesetzt."

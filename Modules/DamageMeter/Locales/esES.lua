local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- Localization: Spanish
----------------------------------------------------------------------

if GetLocale() ~= "esES" and GetLocale() ~= "esMX" then return end

local L = ns.L

-- General
L["ADDON_NAME"]     = "TomoDamageMeter"
L["ADDON_SHORT"]    = "Tomo"

-- Meter types
L["DPS"]            = "DPS"
L["HPS"]            = "HPS"
L["DAMAGE_TAKEN"]   = "Daño recibido"
L["AVOIDABLE"]      = "Evadible"
L["ENEMY_DAMAGE"]   = "Daño enemigo"
L["ABSORBS"]        = "Absorciones"
L["INTERRUPTS"]     = "Interrupciones"
L["DISPELS"]        = "Disipaciones"
L["DEATHS"]         = "Muertes"

-- Categories
L["DAMAGE"]         = "Daño"
L["HEALING"]        = "Sanación"
L["ACTIONS"]        = "Acciones"

-- Sessions
L["CURRENT"]        = "Actual"
L["OVERALL"]        = "Global"

-- Header / UI
L["RESET"]          = "Reiniciar"
L["LOCK"]           = "Bloquear"
L["UNLOCK"]         = "Desbloquear"
L["SETTINGS"]       = "Ajustes"
L["REPORT"]         = "Informe"
L["CLOSE"]          = "Cerrar"

-- Format labels
L["FMT_COMPACT"]    = "Compacto"
L["FMT_1DEC"]       = "1 Dec"
L["FMT_2DEC"]       = "2 Dec"
L["FMT_REGULAR"]    = "Regular"
L["FMT_INT"]        = "Entero"
L["FMT_DEC"]        = "Decimal"

-- Report
L["REPORT_HEADER"]          = "TomoDamageMeter: %s (%s)"
L["REPORT_NO_TARGET"]       = "Sin objetivo de susurro. Selecciona un jugador primero."
L["REPORT_NO_DATA"]         = "No hay datos para informar."
L["REPORT_CHANNEL_SAY"]     = "Decir"
L["REPORT_CHANNEL_PARTY"]   = "Grupo"
L["REPORT_CHANNEL_RAID"]    = "Banda"
L["REPORT_CHANNEL_GUILD"]   = "Hermandad"
L["REPORT_CHANNEL_WHISPER"] = "Susurrar"
L["REPORT_CHANNEL_AUTO"] = "Auto (grupo)"
L["REPORT_CHANNEL_INSTANCE"] = "Instancia"
L["REPORT_CHANNEL_SELF"] = "Mostrar solo para mí"
L["REPORT_CHANNEL_RESTRICTED"] = "Decir y Gritar están restringidos por el juego: solo pasa un mensaje de accesorio por clic. Elige un canal de grupo en los ajustes."

-- Settings
L["SETTINGS_TITLE"]             = "Ajustes de TomoDamageMeter"
L["SETTINGS_GENERAL"]           = "General"
L["SETTINGS_APPEARANCE"]        = "Apariencia"
L["SETTINGS_SKIN"] = "Skin"
L["SETTINGS_BAR_TEXTURE"] = "Textura de barras"
L["SKIN_DARK"] = "Tomo Dark"
L["SKIN_NEON"] = "Tomo Neon"
L["SKIN_MINIMAL"] = "Minimalista"
L["SKIN_GLOSSY"] = "Brillante"
L["SKIN_EMBER"] = "Brasa"
L["SKIN_FROST"] = "Escarcha"
L["SKIN_TERMINAL"] = "Terminal"
L["SKIN_VOID"] = "Vacío"
L["SKIN_PARCHMENT"] = "Pergamino"
L["SETTINGS_COLUMNS"]           = "Columnas"
L["SETTINGS_FONT_SIZE"]         = "Tamaño de fuente"
L["SETTINGS_FONT_FACE"]         = "Fuente"
L["SETTINGS_BAR_HEIGHT"]        = "Altura de barra"
L["SETTINGS_BG_OPACITY"]        = "Opacidad de fondo"
L["SETTINGS_OOC_OPACITY"]       = "Opacidad fuera de combate"
L["SETTINGS_BREAKDOWN_OPACITY"] = "Opacidad desglose de hechizos"
L["SETTINGS_STRIP_REALM"]       = "Quitar nombre de reino"
L["SETTINGS_ACCENT_COLOR"]      = "Color de acento"
L["SETTINGS_USE_CLASS_COLOR"]   = "Usar color de clase"
L["SETTINGS_REPORT_CHANNEL"]    = "Canal de informe"
L["SETTINGS_REPORT_LINES"]      = "Líneas de informe"
L["SETTINGS_WINDOWS"]           = "Ventanas"
L["SETTINGS_ADD_WINDOW"]        = "+ Añadir"
L["SETTINGS_REMOVE_WINDOW"]     = "- Eliminar"
L["SETTINGS_WINDOW_COUNT"]      = "Ventanas: %d / %d"
L["SETTINGS_COL_RATE"]          = "Tasa (DPS/HPS)"
L["SETTINGS_COL_TOTAL"]         = "Total"
L["SETTINGS_COL_PCT"]           = "Porcentaje"
L["SETTINGS_TAB_GENERAL"]       = "General"
L["SETTINGS_TAB_WINDOW"]        = "Ventana %d"
L["SETTINGS_METER_TYPE"]        = "Tipo de medidor"
L["SETTINGS_SESSION_TYPE"]      = "Tipo de sesión"
L["SETTINGS_LOCKED"]            = "Posición bloqueada"

-- Slash commands
L["CMD_RESET"]          = "Datos reiniciados."
L["CMD_LOCKED"]         = "Bloqueado"
L["CMD_UNLOCKED"]       = "Desbloqueado"
L["CMD_HELP_HEADER"]    = "Comandos:"
L["CMD_HELP_TOGGLE"]    = "  /tdm — abrir ajustes"
L["CMD_HELP_TOGGLE_VIS"]= "  /tdm toggle — alternar visibilidad de ventana"
L["CMD_HELP_RESET"]     = "  /tdm reset — reiniciar todos los datos de combate"
L["CMD_HELP_LOCK"]      = "  /tdm lock — bloquear/desbloquear posición de ventana"
L["CMD_HELP_HELP"]      = "  /tdm help — este mensaje"

-- Auto-reset
L["SETTINGS_AUTO_RESET_INSTANCE"] = "Autoreinicio al entrar en instancia"
L["SETTINGS_COMBAT_TIMER"] = "Cronómetro de combate (DPS/HPS)"
L["SETTINGS_SELF_BAR"] = "Fijar mi propia barra"
L["SETTINGS_BAR_TOOLTIPS"] = "Información de barras (al pasar)"
L["SETTINGS_MODULES"] = "Módulos"
L["SETTINGS_DEATH_RECAP_AUTO"] = "Resumen de muerte al morir"
L["SETTINGS_TIMER_POSITION"] = "Posición del temporizador"
L["TIMER_POS_RIGHT"] = "Derecha"
L["TIMER_POS_LEFT"] = "Izquierda"
L["SETTINGS_CATEGORIES"] = "Categorías"
L["SETTINGS_CATEGORIES_MIN"] = "Al menos una categoría debe permanecer activada."
L["AUTO_RESET_MSG"]                = "Datos reiniciados automáticamente (entrada en instancia)."

-- Combat
L["COMBAT_SETTINGS_UNAVAILABLE"] = "Ajustes no disponibles durante el combate."
L["WAITING_COMBAT_END"]          = "No disponible hasta después del combate"

-- Detail
L["SPELL_BREAKDOWN"] = "Desglose de hechizos"
L["NO_DATA"]         = "No hay datos disponibles"
L["DEATH_RECAP"] = "Resumen de muerte"
L["DEATH_RECAP_NO_DATA"] = "Ninguna muerte registrada"
L["RECAP_HEAL"] = "Curación"
L["RECAP_MELEE"] = "Cuerpo a cuerpo"
L["RECAP_UNKNOWN"] = "Desconocido"
L["BREAKDOWN_SPELLS_LABEL"] = "hechizos"
L["BREAKDOWN_CRITS_LABEL"]  = "críts"
L["BREAKDOWN_CRIT_RATE_LABEL"] = "crít"
L["BREAKDOWN_COL_SPELL"] = "Hechizo"
L["BREAKDOWN_COL_TOTAL"] = "Total"

-- Segments / Target Breakdown
L["SEGMENTS"] = "Segmentos"
L["SEGMENT"] = "Segmento"
L["SEGMENT_COL_NAME"] = "Encuentro"
L["TARGET_BREAKDOWN"] = "Desglose de objetivos"
L["TARGET_COL_NAME"] = "Objetivo"

-- Tooltips
L["TIP_SETTINGS"] = "Abrir ajustes"
L["TIP_TARGET"] = "Desglose de objetivos"
L["TIP_DETAILS"] = "Desglose de hechizos"
L["TIP_LOCK"] = "Bloquear/desbloquear posición"
L["TIP_REPORT"] = "Informar en el chat"
L["TIP_RESET"] = "Reiniciar todos los datos"
L["TIP_CATEGORY"] = "Clic para cambiar categoría"
L["TIP_TYPE"] = "Clic para cambiar tipo"
L["TIP_SESSION"] = "Clic para cambiar sesión"

-- Información al pasar el ratón
L["TIP_TOP_SPELLS"] = "Mejores hechizos"
L["TIP_TOTAL"] = "Total"
L["TIP_OVERKILL"] = "Daño excedente"
L["TIP_AVOIDABLE"] = "Daño evitable"
L["TIP_KILLING_BLOW"] = "Golpe mortal"
L["TIP_CAST_BY"] = "Lanzado por %s"
L["TIP_CLICK_BREAKDOWN"] = "Clic para ver el detalle de hechizos"
L["TIP_LEFT_EXPAND"] = "Clic izquierdo: mostrar hechizos en línea"
L["TIP_RIGHT_WINDOW"] = "Clic derecho: abrir ventana de detalle"

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
L["SETTINGS_SNAP"] = "Acoplar las ventanas entre sí"
L["SETTINGS_RUN_RECAP_AUTO"] = "Mostrar el resumen al final de una mazmorra"
L["RUN_RECAP"] = "Resumen del recorrido"
L["RUN_RECAP_NO_DATA"] = "Ningún recorrido registrado"
L["RECAP_COL_INT"] = "Interr."
L["RECAP_COL_DEATHS"] = "Muertes"
L["RECAP_COL_AVOIDABLE"] = "Evit."
L["CMD_HELP_RECAP"] = "  /tdm recap — mostrar el último resumen del recorrido"
L["CMD_HELP_DIAG"] = "  /tdm diag — comprobar la legibilidad de los valores de C_DamageMeter"
L["CMD_DIAG_ARMED"] = "Diagnóstico activado — esperando la próxima actualización de datos de combate."

L["CMD_HELP_RESETPOS"] = "  /tdm resetpos — devolver el resumen de muerte al centro"
L["CMD_POS_RESET"] = "Posición del resumen de muerte restablecida."

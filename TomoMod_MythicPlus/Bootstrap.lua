-- =====================================================================
-- TomoMod_MythicPlus / Bootstrap.lua
-- LoadOnDemand Mythic+ control centre. Runtime combat modules remain in
-- TomoMod for V1; this addon owns the dashboard, history and statistics.
-- =====================================================================

TomoMod_MythicPlus = TomoMod_MythicPlus or {}
local MP = TomoMod_MythicPlus

MP.VERSION = 4
MP.Frame = MP.Frame or nil
MP.page = MP.page or "dashboard"

local DEFAULTS = {
    version = 4,
    modules = {
        runHistory = true,
        statistics = true,
    },
    ui = {
        point = "CENTER",
        relPoint = "CENTER",
        x = 0,
        y = 20,
        lastPage = "dashboard",
        textScale = 1.00,
        windowScale = 1.00,
        backgroundAlpha = 0.98,
        useCustomAccent = false,
        accent = { r = 0.18, g = 0.85, b = 0.52 },
    },
    history = {
        maxRuns = 100,
        runs = {},
    },
    goals = {
        score = 3000,
        bestLevel = 15,
        timedLevel = 12,
        timedCount = 50,
        totalRuns = 100,
        allDungeonsLevel = 10,
    },
}

local function Merge(dst, src)
    for key, value in pairs(src) do
        if type(value) == "table" then
            if type(dst[key]) ~= "table" then dst[key] = {} end
            Merge(dst[key], value)
        elseif dst[key] == nil then
            dst[key] = value
        end
    end
end

TomoModMythicPlusDB = TomoModMythicPlusDB or {}
local _previousVersion = tonumber(TomoModMythicPlusDB.version) or 0
Merge(TomoModMythicPlusDB, DEFAULTS)

-- V1.1 keeps a deliberately small local history. V1 shipped with a 500-run
-- default; cap existing databases immediately as well, not only after the
-- next completed key. The cap is fixed at 100 so this store cannot grow
-- silently when profiles are copied between characters.
TomoModMythicPlusDB.history = TomoModMythicPlusDB.history or { runs = {} }
TomoModMythicPlusDB.history.runs = TomoModMythicPlusDB.history.runs or {}
TomoModMythicPlusDB.history.maxRuns = 100
while #TomoModMythicPlusDB.history.runs > 100 do
    table.remove(TomoModMythicPlusDB.history.runs)
end
TomoModMythicPlusDB.ui = TomoModMythicPlusDB.ui or {}
TomoModMythicPlusDB.ui.textScale = tonumber(TomoModMythicPlusDB.ui.textScale) or 1.00
TomoModMythicPlusDB.ui.windowScale = tonumber(TomoModMythicPlusDB.ui.windowScale) or 1.00
TomoModMythicPlusDB.ui.backgroundAlpha = tonumber(TomoModMythicPlusDB.ui.backgroundAlpha) or 0.98
TomoModMythicPlusDB.ui.useCustomAccent = TomoModMythicPlusDB.ui.useCustomAccent == true
TomoModMythicPlusDB.ui.accent = type(TomoModMythicPlusDB.ui.accent) == "table" and TomoModMythicPlusDB.ui.accent or { r=0.18, g=0.85, b=0.52 }
TomoModMythicPlusDB.ui.accent.r = tonumber(TomoModMythicPlusDB.ui.accent.r or TomoModMythicPlusDB.ui.accent[1]) or 0.18
TomoModMythicPlusDB.ui.accent.g = tonumber(TomoModMythicPlusDB.ui.accent.g or TomoModMythicPlusDB.ui.accent[2]) or 0.85
TomoModMythicPlusDB.ui.accent.b = tonumber(TomoModMythicPlusDB.ui.accent.b or TomoModMythicPlusDB.ui.accent[3]) or 0.52
TomoModMythicPlusDB.version = MP.VERSION

function MP:GetDB()
    return TomoModMythicPlusDB
end

-- The Studio is reachable even when TomoMod_Options has never been loaded,
-- so it cannot use TomoMod_L as its only source of strings.  Keep the V1
-- vocabulary local to this LoD addon and cover the same six locales as core.
local I18N = {
    enUS = {
        title="Mythic+ Studio", subtitle="Mythic+ control centre",
        dashboard="Dashboard", tracker="Dungeon Tracker", score="TomoScore", keys="Keys", history="Run History", statistics="Statistics", modules="Modules",
        current_score="Current score", owned_key="Owned keystone", weekly_runs="Runs this week", tracked_runs="Tracked runs", vault="Great Vault — Dungeons", recent_runs="Recent runs",
        no_key="No keystone", no_data="No data yet", detailed_hub="Detailed dungeons / vault view", refresh="Refresh",
        tracker_enable="Enable Mythic+ Tracker", tracker_timer="Show timer", tracker_forces="Show enemy forces", tracker_bosses="Show bosses", tracker_hide_blizzard="Hide Blizzard tracker", tracker_splits="Enable splits", tracker_checkpoints="Enable checkpoints", tracker_lock="Lock tracker", tracker_scale="Scale", tracker_alpha="Opacity", tracker_preview="Preview tracker", tracker_reset="Reset position", preset="Preset", preset_panel="Panel", preset_hud="HUD", preset_minimal="Minimal",
        score_enable="Enable TomoScore", score_auto="Show automatically after Mythic+", score_scale="Scale", score_alpha="Opacity", score_preview="Preview TomoScore", score_reset="Reset position",
        own_key="Your keystone", party_keys="Party keystones", request_keys="Refresh party keys", roulette="Keystone roulette", keys_chat="Send keys to chat", not_grouped="You are not in a group.", no_party_keys="No party keystones received yet.",
        h_date="Date", h_dungeon="Dungeon", h_level="Level", h_result="Result", h_time="Time", h_deaths="Deaths", h_score="Score", timed="Timed", depleted="Depleted",
        stat_total="Tracked runs", stat_timed="Timed runs", stat_depleted="Depleted runs", stat_rate="Success rate", stat_best="Highest key", stat_average="Average level", stat_score="Tracked score gain", stat_week="Tracked this week", dungeon_stats="By dungeon",
        mod_history="Run History", mod_history_desc="Record every Mythic+ completion from now on. Existing Blizzard history is not rewritten into the local log.", mod_stats="Statistics", mod_stats_desc="Build season and per-dungeon statistics from the local Run History.", mod_tracker="Mythic+ Tracker", mod_tracker_desc="Runtime timer, forces and boss tracker. Remains loaded in TomoMod so it never misses a key.", mod_score="TomoScore", mod_score_desc="End-of-run group scoreboard. Remains loaded in TomoMod for automatic display.",
        week="Week", season="Season", runs="runs", close="Close", unknown="Unknown", score_gain="Score gain", practice="Practice", module_disabled="This module is disabled on the Modules page.",
        v1_note="V1 centralizes configuration without moving combat-critical runtime code out of TomoMod. This keeps the tracker, score and key sync available before the Studio is opened.",
    },
    frFR = {
        title="Studio Mythic+", subtitle="Centre de contrôle Mythic+",
        dashboard="Tableau de bord", tracker="Suivi en donjon", score="TomoScore", keys="Clés", history="Historique", statistics="Statistiques", modules="Modules",
        current_score="Score actuel", owned_key="Clé possédée", weekly_runs="Clés cette semaine", tracked_runs="Clés enregistrées", vault="Grande chambre — Donjons", recent_runs="Dernières clés",
        no_key="Aucune clé", no_data="Aucune donnée pour le moment", detailed_hub="Vue détaillée donjons / chambre", refresh="Actualiser",
        tracker_enable="Activer le tracker Mythic+", tracker_timer="Afficher le timer", tracker_forces="Afficher les forces ennemies", tracker_bosses="Afficher les boss", tracker_hide_blizzard="Masquer le tracker Blizzard", tracker_splits="Activer les splits", tracker_checkpoints="Activer les checkpoints", tracker_lock="Verrouiller le tracker", tracker_scale="Échelle", tracker_alpha="Opacité", tracker_preview="Aperçu du tracker", tracker_reset="Réinitialiser la position", preset="Préréglage", preset_panel="Panneau", preset_hud="HUD", preset_minimal="Minimal",
        score_enable="Activer TomoScore", score_auto="Afficher automatiquement après une clé", score_scale="Échelle", score_alpha="Opacité", score_preview="Aperçu de TomoScore", score_reset="Réinitialiser la position",
        own_key="Votre clé", party_keys="Clés du groupe", request_keys="Actualiser les clés", roulette="Roulette des clés", keys_chat="Envoyer les clés dans le chat", not_grouped="Vous n'êtes pas en groupe.", no_party_keys="Aucune clé de groupe reçue pour le moment.",
        h_date="Date", h_dungeon="Donjon", h_level="Niveau", h_result="Résultat", h_time="Temps", h_deaths="Morts", h_score="Score", timed="Dans le temps", depleted="Hors temps",
        stat_total="Clés enregistrées", stat_timed="Clés timées", stat_depleted="Clés hors temps", stat_rate="Taux de réussite", stat_best="Plus haute clé", stat_average="Niveau moyen", stat_score="Gain de score enregistré", stat_week="Enregistrées cette semaine", dungeon_stats="Par donjon",
        mod_history="Historique des clés", mod_history_desc="Enregistre chaque fin de clé Mythic+ à partir de maintenant. L'historique Blizzard existant n'est pas recopié artificiellement.", mod_stats="Statistiques", mod_stats_desc="Construit les statistiques de saison et par donjon à partir de l'historique local.", mod_tracker="Tracker Mythic+", mod_tracker_desc="Timer, forces et boss pendant la clé. Reste chargé dans TomoMod afin de ne jamais manquer un départ.", mod_score="TomoScore", mod_score_desc="Tableau de score de fin de clé. Reste chargé dans TomoMod pour son affichage automatique.",
        week="Semaine", season="Saison", runs="clés", close="Fermer", unknown="Inconnu", score_gain="Gain de score", practice="Entraînement", module_disabled="Ce module est désactivé dans la page Modules.",
        v1_note="La V1 centralise la configuration sans déplacer le code runtime critique hors de TomoMod. Le tracker, TomoScore et la synchronisation des clés restent donc disponibles avant même l'ouverture du Studio.",
    },
    deDE = {
        title="Mythisch+ Studio", subtitle="Mythisch+ Kontrollzentrum",
        dashboard="Übersicht", tracker="Dungeon-Tracker", score="TomoScore", keys="Schlüssel", history="Laufhistorie", statistics="Statistiken", modules="Module",
        current_score="Aktuelle Wertung", owned_key="Eigener Schlüssel", weekly_runs="Läufe diese Woche", tracked_runs="Gespeicherte Läufe", vault="Große Schatzkammer — Dungeons", recent_runs="Letzte Läufe",
        no_key="Kein Schlüssel", no_data="Noch keine Daten", detailed_hub="Detailansicht Dungeons / Schatzkammer", refresh="Aktualisieren",
        tracker_enable="Mythisch+ Tracker aktivieren", tracker_timer="Timer anzeigen", tracker_forces="Gegnerische Streitkräfte anzeigen", tracker_bosses="Bosse anzeigen", tracker_hide_blizzard="Blizzard-Tracker ausblenden", tracker_splits="Splits aktivieren", tracker_checkpoints="Checkpoints aktivieren", tracker_lock="Tracker sperren", tracker_scale="Skalierung", tracker_alpha="Deckkraft", tracker_preview="Tracker-Vorschau", tracker_reset="Position zurücksetzen", preset="Voreinstellung", preset_panel="Panel", preset_hud="HUD", preset_minimal="Minimal",
        score_enable="TomoScore aktivieren", score_auto="Nach Mythisch+ automatisch anzeigen", score_scale="Skalierung", score_alpha="Deckkraft", score_preview="TomoScore-Vorschau", score_reset="Position zurücksetzen",
        own_key="Dein Schlüssel", party_keys="Gruppenschlüssel", request_keys="Gruppenschlüssel aktualisieren", roulette="Schlüssel-Roulette", keys_chat="Schlüssel im Chat senden", not_grouped="Du bist in keiner Gruppe.", no_party_keys="Noch keine Gruppenschlüssel empfangen.",
        h_date="Datum", h_dungeon="Dungeon", h_level="Stufe", h_result="Ergebnis", h_time="Zeit", h_deaths="Tode", h_score="Wertung", timed="Rechtzeitig", depleted="Nicht rechtzeitig",
        stat_total="Gespeicherte Läufe", stat_timed="Rechtzeitig", stat_depleted="Nicht rechtzeitig", stat_rate="Erfolgsquote", stat_best="Höchster Schlüssel", stat_average="Durchschnittsstufe", stat_score="Gespeicherter Wertungsgewinn", stat_week="Diese Woche gespeichert", dungeon_stats="Nach Dungeon",
        mod_history="Laufhistorie", mod_history_desc="Speichert ab jetzt jeden abgeschlossenen Mythisch+-Lauf. Die vorhandene Blizzard-Historie wird nicht künstlich importiert.", mod_stats="Statistiken", mod_stats_desc="Erstellt Saison- und Dungeon-Statistiken aus der lokalen Laufhistorie.", mod_tracker="Mythisch+ Tracker", mod_tracker_desc="Timer, Streitkräfte und Bosse während des Laufs. Bleibt in TomoMod geladen, damit kein Start verpasst wird.", mod_score="TomoScore", mod_score_desc="Gruppenwertung am Ende des Laufs. Bleibt für die automatische Anzeige in TomoMod geladen.",
        week="Woche", season="Saison", runs="Läufe", close="Schließen", unknown="Unbekannt", score_gain="Wertungsgewinn", practice="Übung", module_disabled="Dieses Modul ist auf der Seite Module deaktiviert.", v1_note="V1 zentralisiert die Konfiguration, ohne kampfkritischen Laufzeitcode aus TomoMod zu verschieben.",
    },
    esES = {
        title="Estudio Mítico+", subtitle="Centro de control Mítico+", dashboard="Panel", tracker="Rastreador", score="TomoScore", keys="Piedras", history="Historial", statistics="Estadísticas", modules="Módulos",
        current_score="Puntuación actual", owned_key="Piedra propia", weekly_runs="Mazmorras esta semana", tracked_runs="Mazmorras registradas", vault="Gran Cámara — Mazmorras", recent_runs="Últimas mazmorras", no_key="Sin piedra", no_data="Aún no hay datos", detailed_hub="Vista detallada de mazmorras / cámara", refresh="Actualizar",
        tracker_enable="Activar rastreador Mítico+", tracker_timer="Mostrar temporizador", tracker_forces="Mostrar fuerzas enemigas", tracker_bosses="Mostrar jefes", tracker_hide_blizzard="Ocultar rastreador de Blizzard", tracker_splits="Activar parciales", tracker_checkpoints="Activar puntos de control", tracker_lock="Bloquear rastreador", tracker_scale="Escala", tracker_alpha="Opacidad", tracker_preview="Vista previa", tracker_reset="Restablecer posición", preset="Preajuste", preset_panel="Panel", preset_hud="HUD", preset_minimal="Mínimo",
        score_enable="Activar TomoScore", score_auto="Mostrar automáticamente tras Mítico+", score_scale="Escala", score_alpha="Opacidad", score_preview="Vista previa de TomoScore", score_reset="Restablecer posición",
        own_key="Tu piedra", party_keys="Piedras del grupo", request_keys="Actualizar piedras", roulette="Ruleta de piedras", keys_chat="Enviar piedras al chat", not_grouped="No estás en un grupo.", no_party_keys="Aún no se han recibido piedras del grupo.",
        h_date="Fecha", h_dungeon="Mazmorra", h_level="Nivel", h_result="Resultado", h_time="Tiempo", h_deaths="Muertes", h_score="Puntuación", timed="A tiempo", depleted="Fuera de tiempo",
        stat_total="Mazmorras registradas", stat_timed="A tiempo", stat_depleted="Fuera de tiempo", stat_rate="Tasa de éxito", stat_best="Piedra más alta", stat_average="Nivel medio", stat_score="Ganancia registrada", stat_week="Registradas esta semana", dungeon_stats="Por mazmorra",
        mod_history="Historial", mod_history_desc="Registra cada Mítico+ completado a partir de ahora. El historial anterior de Blizzard no se inventa ni se copia.", mod_stats="Estadísticas", mod_stats_desc="Crea estadísticas de temporada y por mazmorra desde el historial local.", mod_tracker="Rastreador Mítico+", mod_tracker_desc="Temporizador, fuerzas y jefes durante la piedra. Permanece cargado en TomoMod.", mod_score="TomoScore", mod_score_desc="Marcador al final de la piedra. Permanece cargado para su visualización automática.", week="Semana", season="Temporada", runs="mazmorras", close="Cerrar", unknown="Desconocido", score_gain="Ganancia", practice="Práctica", module_disabled="Este módulo está desactivado en Módulos.", v1_note="V1 centraliza la configuración sin mover fuera de TomoMod el código crítico durante una piedra.",
    },
    itIT = {
        title="Studio Mitica+", subtitle="Centro di controllo Mitica+", dashboard="Dashboard", tracker="Tracker dungeon", score="TomoScore", keys="Chiavi", history="Cronologia", statistics="Statistiche", modules="Moduli",
        current_score="Punteggio attuale", owned_key="Chiave posseduta", weekly_runs="Run questa settimana", tracked_runs="Run registrate", vault="Gran Banca — Dungeon", recent_runs="Run recenti", no_key="Nessuna chiave", no_data="Nessun dato", detailed_hub="Vista dettagliata dungeon / banca", refresh="Aggiorna",
        tracker_enable="Attiva tracker Mitica+", tracker_timer="Mostra timer", tracker_forces="Mostra forze nemiche", tracker_bosses="Mostra boss", tracker_hide_blizzard="Nascondi tracker Blizzard", tracker_splits="Attiva split", tracker_checkpoints="Attiva checkpoint", tracker_lock="Blocca tracker", tracker_scale="Scala", tracker_alpha="Opacità", tracker_preview="Anteprima tracker", tracker_reset="Ripristina posizione", preset="Preset", preset_panel="Pannello", preset_hud="HUD", preset_minimal="Minimo",
        score_enable="Attiva TomoScore", score_auto="Mostra automaticamente dopo Mitica+", score_scale="Scala", score_alpha="Opacità", score_preview="Anteprima TomoScore", score_reset="Ripristina posizione",
        own_key="La tua chiave", party_keys="Chiavi del gruppo", request_keys="Aggiorna chiavi", roulette="Roulette delle chiavi", keys_chat="Invia chiavi in chat", not_grouped="Non sei in un gruppo.", no_party_keys="Nessuna chiave del gruppo ricevuta.",
        h_date="Data", h_dungeon="Dungeon", h_level="Livello", h_result="Risultato", h_time="Tempo", h_deaths="Morti", h_score="Punteggio", timed="In tempo", depleted="Fuori tempo",
        stat_total="Run registrate", stat_timed="In tempo", stat_depleted="Fuori tempo", stat_rate="Tasso di successo", stat_best="Chiave più alta", stat_average="Livello medio", stat_score="Guadagno punteggio registrato", stat_week="Registrate questa settimana", dungeon_stats="Per dungeon",
        mod_history="Cronologia run", mod_history_desc="Registra ogni Mitica+ completata da ora in poi. La cronologia Blizzard precedente non viene ricreata.", mod_stats="Statistiche", mod_stats_desc="Crea statistiche stagionali e per dungeon dalla cronologia locale.", mod_tracker="Tracker Mitica+", mod_tracker_desc="Timer, forze e boss durante la chiave. Resta caricato in TomoMod.", mod_score="TomoScore", mod_score_desc="Tabellone a fine chiave. Resta caricato per l'apertura automatica.", week="Settimana", season="Stagione", runs="run", close="Chiudi", unknown="Sconosciuto", score_gain="Guadagno punteggio", practice="Pratica", module_disabled="Questo modulo è disattivato nella pagina Moduli.", v1_note="V1 centralizza la configurazione senza spostare da TomoMod il codice runtime critico.",
    },
    ptBR = {
        title="Estúdio Mítico+", subtitle="Central de controle Mítico+", dashboard="Painel", tracker="Rastreador", score="TomoScore", keys="Chaves", history="Histórico", statistics="Estatísticas", modules="Módulos",
        current_score="Pontuação atual", owned_key="Chave própria", weekly_runs="Runs nesta semana", tracked_runs="Runs registradas", vault="Grande Cofre — Masmorras", recent_runs="Runs recentes", no_key="Sem chave", no_data="Ainda sem dados", detailed_hub="Visão detalhada masmorras / cofre", refresh="Atualizar",
        tracker_enable="Ativar rastreador Mítico+", tracker_timer="Mostrar cronômetro", tracker_forces="Mostrar forças inimigas", tracker_bosses="Mostrar chefes", tracker_hide_blizzard="Ocultar rastreador Blizzard", tracker_splits="Ativar parciais", tracker_checkpoints="Ativar checkpoints", tracker_lock="Bloquear rastreador", tracker_scale="Escala", tracker_alpha="Opacidade", tracker_preview="Prévia do rastreador", tracker_reset="Redefinir posição", preset="Predefinição", preset_panel="Painel", preset_hud="HUD", preset_minimal="Mínimo",
        score_enable="Ativar TomoScore", score_auto="Mostrar automaticamente após Mítico+", score_scale="Escala", score_alpha="Opacidade", score_preview="Prévia do TomoScore", score_reset="Redefinir posição",
        own_key="Sua chave", party_keys="Chaves do grupo", request_keys="Atualizar chaves", roulette="Roleta de chaves", keys_chat="Enviar chaves no chat", not_grouped="Você não está em um grupo.", no_party_keys="Nenhuma chave do grupo recebida ainda.",
        h_date="Data", h_dungeon="Masmorra", h_level="Nível", h_result="Resultado", h_time="Tempo", h_deaths="Mortes", h_score="Pontuação", timed="No tempo", depleted="Fora do tempo",
        stat_total="Runs registradas", stat_timed="No tempo", stat_depleted="Fora do tempo", stat_rate="Taxa de sucesso", stat_best="Maior chave", stat_average="Nível médio", stat_score="Ganho de pontuação registrado", stat_week="Registradas nesta semana", dungeon_stats="Por masmorra",
        mod_history="Histórico de runs", mod_history_desc="Registra cada Mítico+ concluída a partir de agora. O histórico anterior da Blizzard não é recriado.", mod_stats="Estatísticas", mod_stats_desc="Cria estatísticas de temporada e por masmorra usando o histórico local.", mod_tracker="Rastreador Mítico+", mod_tracker_desc="Cronômetro, forças e chefes durante a chave. Continua carregado no TomoMod.", mod_score="TomoScore", mod_score_desc="Placar de fim de chave. Continua carregado para exibição automática.", week="Semana", season="Temporada", runs="runs", close="Fechar", unknown="Desconhecido", score_gain="Ganho de pontuação", practice="Treino", module_disabled="Este módulo está desativado na página Módulos.", v1_note="V1 centraliza a configuração sem mover o código crítico de execução para fora do TomoMod.",
    },
 }

-- V1.1 vocabulary is kept separate from the original V1 table so the
-- migration stays reviewable. Every supported TomoMod locale receives real
-- strings; enUS remains the final safety net only for unknown client locales.
local V11_I18N = {
    enUS = {
        weekly_planner="Weekly Planner", score_planner="Score Planner", level_analysis="Level Analysis", season_goals="Season Goals",
        tracker_live_preview="Live HUD preview", tracker_colors="Tracker colours", tracker_custom_colors="Use custom tracker colours", tracker_color_accent="Accent", tracker_color_background="Background", tracker_color_header="Header", tracker_color_text="Text", tracker_color_forces="Enemy forces", tracker_color_comfort="Comfort / +3", tracker_color_warning="Warning / +2", tracker_color_danger="Danger / +1", tracker_colors_reset="Reset colours", tracker_editmode="Position tracker", tracker_real_preview="Open real tracker preview", tracker_edit_title="Tracker positioning", tracker_edit_done="Done", tracker_edit_cancel="Cancel", tracker_edit_reset="Reset position", tracker_edit_blocked="Tracker positioning is unavailable during an active Mythic+ run.",
        compare="Run A / B comparison", compare_run_a="Run A", compare_run_b="Run B", compare_swap="Swap A / B", compare_different="The selected runs are from different dungeons; boss splits are shown by position only.", compare_forces="Forces 100%", compare_delta="Delta", compare_no_splits="No split snapshot for this run", previous="Previous", next="Next",
        weekly_remaining="Remaining", weekly_complete="Complete", weekly_best="Best this week", weekly_current_key="Current keystone", weekly_recommendation="Weekly recommendation", weekly_all_done="All three dungeon slots are complete.", weekly_runs_needed="%d more completed run(s) for the next dungeon slot.", weekly_slot="Dungeon slot %d",
        score_current="Current best", score_target="Suggested next key", score_est_gain="Indicative gain", score_estimate_note="Score gains are indicative planning values. Blizzard's recorded dungeon score remains the authoritative value.", score_new="New score", score_potential_high="High", score_potential_medium="Medium", score_potential_low="Low", score_potential="Potential",
        analysis_comfort="Comfort level", analysis_comfort_desc="Highest level with at least 3 tracked runs and a 70% timed rate.", analysis_level="Level", analysis_runs="Runs", analysis_timed="Timed", analysis_rate="Success", analysis_avg_time="Avg time", analysis_avg_deaths="Avg deaths",
        goals_score="Season score", goals_best="Highest key", goals_timed="Timed keys at target level", goals_runs="Tracked season runs", goals_all_dungeons="All season dungeons at level", goals_target_level="Target key level", goals_target_count="Target count", goals_progress="Progress", goals_local_note="Run-count goals use TomoMod's local history, so they start when Run History is enabled.",
        history_cap="Run History keeps the latest 100 Mythic+ runs.", v11_note="V1.1 adds the live tracker editor, custom colours, targeted tracker positioning, run A/B comparison, Weekly Planner, Score Planner, level analysis and season goals. Keystone, DataKeys and KeySync stay permanently loaded in TomoMod.",
    },
    frFR = {
        weekly_planner="Planning hebdomadaire", score_planner="Planificateur de score", level_analysis="Analyse par niveau", season_goals="Objectifs de saison",
        tracker_live_preview="Aperçu HUD en direct", tracker_colors="Couleurs du tracker", tracker_custom_colors="Utiliser des couleurs personnalisées", tracker_color_accent="Accent", tracker_color_background="Fond", tracker_color_header="En-tête", tracker_color_text="Texte", tracker_color_forces="Forces ennemies", tracker_color_comfort="Confort / +3", tracker_color_warning="Avertissement / +2", tracker_color_danger="Danger / +1", tracker_colors_reset="Réinitialiser les couleurs", tracker_editmode="Position du tracker", tracker_real_preview="Ouvrir l'aperçu réel", tracker_edit_title="Position du tracker", tracker_edit_done="Valider", tracker_edit_cancel="Annuler", tracker_edit_reset="Réinitialiser", tracker_edit_blocked="Le positionnement du tracker est indisponible pendant une clé Mythic+ active.",
        compare="Comparaison de runs A / B", compare_run_a="Run A", compare_run_b="Run B", compare_swap="Permuter A / B", compare_different="Les runs sélectionnés sont de donjons différents ; les splits de boss sont comparés uniquement par position.", compare_forces="Forces 100 %", compare_delta="Écart", compare_no_splits="Aucun snapshot de splits pour ce run", previous="Précédent", next="Suivant",
        weekly_remaining="Restant", weekly_complete="Terminé", weekly_best="Meilleure clé de la semaine", weekly_current_key="Clé actuelle", weekly_recommendation="Recommandation hebdomadaire", weekly_all_done="Les trois emplacements Donjons sont terminés.", weekly_runs_needed="Encore %d clé(s) terminée(s) pour le prochain emplacement Donjons.", weekly_slot="Emplacement Donjons %d",
        score_current="Meilleur actuel", score_target="Prochaine clé conseillée", score_est_gain="Gain indicatif", score_estimate_note="Les gains de score sont des estimations de planification. Le score de donjon enregistré par Blizzard reste la valeur de référence.", score_new="Nouveau score", score_potential_high="Élevé", score_potential_medium="Moyen", score_potential_low="Faible", score_potential="Potentiel",
        analysis_comfort="Niveau de confort", analysis_comfort_desc="Plus haut niveau avec au moins 3 runs enregistrés et 70 % de réussite dans le temps.", analysis_level="Niveau", analysis_runs="Runs", analysis_timed="Timées", analysis_rate="Réussite", analysis_avg_time="Temps moyen", analysis_avg_deaths="Morts moyennes",
        goals_score="Score de saison", goals_best="Plus haute clé", goals_timed="Clés timées au niveau cible", goals_runs="Runs de saison enregistrés", goals_all_dungeons="Tous les donjons de saison au niveau", goals_target_level="Niveau cible", goals_target_count="Nombre cible", goals_progress="Progression", goals_local_note="Les objectifs basés sur le nombre de runs utilisent l'historique local TomoMod et commencent donc lorsque l'Historique est activé.",
        history_cap="L'historique conserve les 100 dernières clés Mythic+.", v11_note="La V1.1 ajoute l'éditeur visuel du tracker, les couleurs personnalisées, le positionnement ciblé, la comparaison A/B, le planning hebdomadaire, le planificateur de score, l'analyse par niveau et les objectifs de saison. Keystone, DataKeys et KeySync restent chargés en permanence dans TomoMod.",
    },
    deDE = {
        weekly_planner="Wochenplaner", score_planner="Wertungsplaner", level_analysis="Stufenanalyse", season_goals="Saisonziele",
        tracker_live_preview="Live-HUD-Vorschau", tracker_colors="Tracker-Farben", tracker_custom_colors="Eigene Tracker-Farben verwenden", tracker_color_accent="Akzent", tracker_color_background="Hintergrund", tracker_color_header="Kopfzeile", tracker_color_text="Text", tracker_color_forces="Gegnerkräfte", tracker_color_comfort="Komfort / +3", tracker_color_warning="Warnung / +2", tracker_color_danger="Gefahr / +1", tracker_colors_reset="Farben zurücksetzen", tracker_editmode="Tracker positionieren", tracker_real_preview="Echte Tracker-Vorschau öffnen", tracker_edit_title="Tracker-Positionierung", tracker_edit_done="Fertig", tracker_edit_cancel="Abbrechen", tracker_edit_reset="Position zurücksetzen", tracker_edit_blocked="Die Tracker-Positionierung ist während eines aktiven Mythisch+-Laufs nicht verfügbar.",
        compare="Laufvergleich A / B", compare_run_a="Lauf A", compare_run_b="Lauf B", compare_swap="A / B tauschen", compare_different="Die ausgewählten Läufe stammen aus verschiedenen Dungeons; Boss-Splits werden nur nach Position verglichen.", compare_forces="Kräfte 100 %", compare_delta="Differenz", compare_no_splits="Keine Split-Aufzeichnung für diesen Lauf", previous="Zurück", next="Weiter",
        weekly_remaining="Verbleibend", weekly_complete="Abgeschlossen", weekly_best="Beste Woche", weekly_current_key="Aktueller Schlüssel", weekly_recommendation="Wochenempfehlung", weekly_all_done="Alle drei Dungeon-Plätze sind abgeschlossen.", weekly_runs_needed="Noch %d abgeschlossene Lauf/Läufe für den nächsten Dungeon-Platz.", weekly_slot="Dungeon-Platz %d",
        score_current="Aktuell bester", score_target="Empfohlener nächster Schlüssel", score_est_gain="Ungefährer Gewinn", score_estimate_note="Wertungsgewinne sind Planungswerte. Blizzards gespeicherte Dungeon-Wertung bleibt maßgeblich.", score_new="Neue Wertung", score_potential_high="Hoch", score_potential_medium="Mittel", score_potential_low="Niedrig", score_potential="Potenzial",
        analysis_comfort="Komfortstufe", analysis_comfort_desc="Höchste Stufe mit mindestens 3 gespeicherten Läufen und 70 % rechtzeitig abgeschlossenen Läufen.", analysis_level="Stufe", analysis_runs="Läufe", analysis_timed="Rechtzeitig", analysis_rate="Erfolg", analysis_avg_time="Ø Zeit", analysis_avg_deaths="Ø Tode",
        goals_score="Saisonwertung", goals_best="Höchster Schlüssel", goals_timed="Rechtzeitige Schlüssel auf Zielstufe", goals_runs="Gespeicherte Saisonläufe", goals_all_dungeons="Alle Saison-Dungeons auf Stufe", goals_target_level="Zielstufe", goals_target_count="Zielanzahl", goals_progress="Fortschritt", goals_local_note="Laufanzahl-Ziele verwenden TomoMods lokale Historie und beginnen mit aktiviertem Run History.",
        history_cap="Run History behält die letzten 100 Mythisch+-Läufe.", v11_note="V1.1 ergänzt Live-Tracker-Editor, eigene Farben, gezielte Positionierung, A/B-Vergleich, Wochenplaner, Wertungsplaner, Stufenanalyse und Saisonziele. Keystone, DataKeys und KeySync bleiben dauerhaft in TomoMod geladen.",
    },
    esES = {
        weekly_planner="Plan semanal", score_planner="Planificador de puntuación", level_analysis="Análisis por nivel", season_goals="Objetivos de temporada",
        tracker_live_preview="Vista previa HUD en directo", tracker_colors="Colores del rastreador", tracker_custom_colors="Usar colores personalizados", tracker_color_accent="Acento", tracker_color_background="Fondo", tracker_color_header="Cabecera", tracker_color_text="Texto", tracker_color_forces="Fuerzas enemigas", tracker_color_comfort="Comodidad / +3", tracker_color_warning="Aviso / +2", tracker_color_danger="Peligro / +1", tracker_colors_reset="Restablecer colores", tracker_editmode="Posicionar rastreador", tracker_real_preview="Abrir vista previa real", tracker_edit_title="Posición del rastreador", tracker_edit_done="Aceptar", tracker_edit_cancel="Cancelar", tracker_edit_reset="Restablecer posición", tracker_edit_blocked="No se puede posicionar el rastreador durante una piedra Mítica+ activa.",
        compare="Comparación de runs A / B", compare_run_a="Run A", compare_run_b="Run B", compare_swap="Intercambiar A / B", compare_different="Los runs seleccionados son de mazmorras distintas; los splits de jefes se comparan solo por posición.", compare_forces="Fuerzas 100 %", compare_delta="Diferencia", compare_no_splits="Este run no tiene snapshot de splits", previous="Anterior", next="Siguiente",
        weekly_remaining="Restante", weekly_complete="Completo", weekly_best="Mejor de la semana", weekly_current_key="Piedra actual", weekly_recommendation="Recomendación semanal", weekly_all_done="Los tres huecos de mazmorras están completos.", weekly_runs_needed="Faltan %d run(s) completado(s) para el siguiente hueco de mazmorras.", weekly_slot="Hueco de mazmorras %d",
        score_current="Mejor actual", score_target="Siguiente piedra sugerida", score_est_gain="Ganancia indicativa", score_estimate_note="Las ganancias de puntuación son estimaciones de planificación. La puntuación registrada por Blizzard es la referencia.", score_new="Nueva puntuación", score_potential_high="Alto", score_potential_medium="Medio", score_potential_low="Bajo", score_potential="Potencial",
        analysis_comfort="Nivel de comodidad", analysis_comfort_desc="Nivel más alto con al menos 3 runs registrados y un 70 % dentro de tiempo.", analysis_level="Nivel", analysis_runs="Runs", analysis_timed="En tiempo", analysis_rate="Éxito", analysis_avg_time="Tiempo medio", analysis_avg_deaths="Muertes medias",
        goals_score="Puntuación de temporada", goals_best="Piedra más alta", goals_timed="Piedras en tiempo al nivel objetivo", goals_runs="Runs de temporada registrados", goals_all_dungeons="Todas las mazmorras de temporada al nivel", goals_target_level="Nivel objetivo", goals_target_count="Cantidad objetivo", goals_progress="Progreso", goals_local_note="Los objetivos por cantidad de runs usan el historial local de TomoMod y empiezan cuando se activa Run History.",
        history_cap="Run History conserva los últimos 100 runs Míticos+.", v11_note="V1.1 añade editor visual del rastreador, colores personalizados, posicionamiento dedicado, comparación A/B, plan semanal, planificador de puntuación, análisis por nivel y objetivos de temporada. Keystone, DataKeys y KeySync permanecen cargados en TomoMod.",
    },
    itIT = {
        weekly_planner="Pianificazione settimanale", score_planner="Pianificatore punteggio", level_analysis="Analisi per livello", season_goals="Obiettivi stagionali",
        tracker_live_preview="Anteprima HUD in tempo reale", tracker_colors="Colori tracker", tracker_custom_colors="Usa colori personalizzati", tracker_color_accent="Accento", tracker_color_background="Sfondo", tracker_color_header="Intestazione", tracker_color_text="Testo", tracker_color_forces="Forze nemiche", tracker_color_comfort="Comfort / +3", tracker_color_warning="Avviso / +2", tracker_color_danger="Pericolo / +1", tracker_colors_reset="Ripristina colori", tracker_editmode="Posiziona tracker", tracker_real_preview="Apri anteprima reale", tracker_edit_title="Posizionamento tracker", tracker_edit_done="Conferma", tracker_edit_cancel="Annulla", tracker_edit_reset="Ripristina posizione", tracker_edit_blocked="Il posizionamento del tracker non è disponibile durante una chiave Mitica+ attiva.",
        compare="Confronto run A / B", compare_run_a="Run A", compare_run_b="Run B", compare_swap="Scambia A / B", compare_different="I run selezionati appartengono a spedizioni diverse; gli split dei boss sono confrontati solo per posizione.", compare_forces="Forze 100%", compare_delta="Differenza", compare_no_splits="Nessuno snapshot degli split per questo run", previous="Precedente", next="Successivo",
        weekly_remaining="Rimanenti", weekly_complete="Completo", weekly_best="Migliore della settimana", weekly_current_key="Chiave attuale", weekly_recommendation="Consiglio settimanale", weekly_all_done="Tutti e tre gli slot spedizione sono completi.", weekly_runs_needed="Servono ancora %d run completati per il prossimo slot spedizione.", weekly_slot="Slot spedizione %d",
        score_current="Migliore attuale", score_target="Prossima chiave consigliata", score_est_gain="Guadagno indicativo", score_estimate_note="I guadagni di punteggio sono stime di pianificazione. Il punteggio registrato da Blizzard resta il riferimento.", score_new="Nuovo punteggio", score_potential_high="Alto", score_potential_medium="Medio", score_potential_low="Basso", score_potential="Potenziale",
        analysis_comfort="Livello di comfort", analysis_comfort_desc="Livello più alto con almeno 3 run registrati e il 70% completato in tempo.", analysis_level="Livello", analysis_runs="Run", analysis_timed="In tempo", analysis_rate="Successo", analysis_avg_time="Tempo medio", analysis_avg_deaths="Morti medie",
        goals_score="Punteggio stagionale", goals_best="Chiave più alta", goals_timed="Chiavi in tempo al livello obiettivo", goals_runs="Run stagionali registrati", goals_all_dungeons="Tutte le spedizioni stagionali al livello", goals_target_level="Livello obiettivo", goals_target_count="Numero obiettivo", goals_progress="Progresso", goals_local_note="Gli obiettivi basati sul numero di run usano la cronologia locale di TomoMod e iniziano quando Run History è attivo.",
        history_cap="Run History conserva gli ultimi 100 run Mitica+.", v11_note="V1.1 aggiunge editor visivo del tracker, colori personalizzati, posizionamento dedicato, confronto A/B, pianificazione settimanale, planner del punteggio, analisi per livello e obiettivi stagionali. Keystone, DataKeys e KeySync restano sempre caricati in TomoMod.",
    },
    ptBR = {
        weekly_planner="Planejamento semanal", score_planner="Planejador de pontuação", level_analysis="Análise por nível", season_goals="Objetivos da temporada",
        tracker_live_preview="Prévia HUD ao vivo", tracker_colors="Cores do rastreador", tracker_custom_colors="Usar cores personalizadas", tracker_color_accent="Destaque", tracker_color_background="Fundo", tracker_color_header="Cabeçalho", tracker_color_text="Texto", tracker_color_forces="Forças inimigas", tracker_color_comfort="Conforto / +3", tracker_color_warning="Aviso / +2", tracker_color_danger="Perigo / +1", tracker_colors_reset="Redefinir cores", tracker_editmode="Posicionar rastreador", tracker_real_preview="Abrir prévia real", tracker_edit_title="Posicionamento do rastreador", tracker_edit_done="Concluir", tracker_edit_cancel="Cancelar", tracker_edit_reset="Redefinir posição", tracker_edit_blocked="O posicionamento do rastreador não está disponível durante uma chave Mítico+ ativa.",
        compare="Comparação de runs A / B", compare_run_a="Run A", compare_run_b="Run B", compare_swap="Trocar A / B", compare_different="Os runs selecionados são de masmorras diferentes; os splits de chefes são comparados apenas por posição.", compare_forces="Forças 100%", compare_delta="Diferença", compare_no_splits="Nenhum snapshot de splits para este run", previous="Anterior", next="Próximo",
        weekly_remaining="Restante", weekly_complete="Completo", weekly_best="Melhor da semana", weekly_current_key="Chave atual", weekly_recommendation="Recomendação semanal", weekly_all_done="Os três espaços de masmorra estão completos.", weekly_runs_needed="Faltam %d run(s) concluído(s) para o próximo espaço de masmorra.", weekly_slot="Espaço de masmorra %d",
        score_current="Melhor atual", score_target="Próxima chave sugerida", score_est_gain="Ganho indicativo", score_estimate_note="Os ganhos de pontuação são estimativas de planejamento. A pontuação registrada pela Blizzard continua sendo a referência.", score_new="Nova pontuação", score_potential_high="Alto", score_potential_medium="Médio", score_potential_low="Baixo", score_potential="Potencial",
        analysis_comfort="Nível de conforto", analysis_comfort_desc="Maior nível com pelo menos 3 runs registrados e 70% concluídos no tempo.", analysis_level="Nível", analysis_runs="Runs", analysis_timed="No tempo", analysis_rate="Sucesso", analysis_avg_time="Tempo médio", analysis_avg_deaths="Mortes médias",
        goals_score="Pontuação da temporada", goals_best="Maior chave", goals_timed="Chaves no tempo no nível alvo", goals_runs="Runs da temporada registrados", goals_all_dungeons="Todas as masmorras da temporada no nível", goals_target_level="Nível alvo", goals_target_count="Quantidade alvo", goals_progress="Progresso", goals_local_note="Os objetivos por quantidade de runs usam o histórico local do TomoMod e começam quando Run History está ativo.",
        history_cap="Run History mantém os últimos 100 runs Mítico+.", v11_note="V1.1 adiciona editor visual do rastreador, cores personalizadas, posicionamento dedicado, comparação A/B, planejamento semanal, planejador de pontuação, análise por nível e objetivos da temporada. Keystone, DataKeys e KeySync permanecem sempre carregados no TomoMod.",
    },
}
for locale, values in pairs(V11_I18N) do
    I18N[locale] = I18N[locale] or {}
    for key, value in pairs(values) do I18N[locale][key] = value end
end

local V11_STYLE_I18N = {
    enUS={tracker_background="Background",tracker_header="Header block",tracker_dungeon="Dungeon name",tracker_objectives="Objectives",tracker_objectives_rows="Rows",tracker_objectives_text="Text",tracker_objectives_none="Hidden",tracker_timer_layout="Timer layout",tracker_timer_stacked="Stacked",tracker_timer_inline="Inline",tracker_segment_colors="Timer colours",tracker_segment_tiers="+3 / +2 / +1",tracker_segment_brand="Single colour",tracker_font_scale="Tracker font scale"},
    frFR={tracker_background="Fond",tracker_header="Bloc d'en-tête",tracker_dungeon="Nom du donjon",tracker_objectives="Objectifs",tracker_objectives_rows="Lignes",tracker_objectives_text="Texte",tracker_objectives_none="Masqués",tracker_timer_layout="Disposition du timer",tracker_timer_stacked="Empilé",tracker_timer_inline="En ligne",tracker_segment_colors="Couleurs du timer",tracker_segment_tiers="+3 / +2 / +1",tracker_segment_brand="Couleur unique",tracker_font_scale="Échelle de police du tracker"},
    deDE={tracker_background="Hintergrund",tracker_header="Kopfbereich",tracker_dungeon="Dungeonname",tracker_objectives="Ziele",tracker_objectives_rows="Zeilen",tracker_objectives_text="Text",tracker_objectives_none="Ausgeblendet",tracker_timer_layout="Timer-Layout",tracker_timer_stacked="Gestapelt",tracker_timer_inline="Inline",tracker_segment_colors="Timer-Farben",tracker_segment_tiers="+3 / +2 / +1",tracker_segment_brand="Eine Farbe",tracker_font_scale="Tracker-Schriftgröße"},
    esES={tracker_background="Fondo",tracker_header="Bloque de cabecera",tracker_dungeon="Nombre de mazmorra",tracker_objectives="Objetivos",tracker_objectives_rows="Filas",tracker_objectives_text="Texto",tracker_objectives_none="Ocultos",tracker_timer_layout="Diseño del temporizador",tracker_timer_stacked="Apilado",tracker_timer_inline="En línea",tracker_segment_colors="Colores del temporizador",tracker_segment_tiers="+3 / +2 / +1",tracker_segment_brand="Un solo color",tracker_font_scale="Escala de fuente del rastreador"},
    itIT={tracker_background="Sfondo",tracker_header="Blocco intestazione",tracker_dungeon="Nome dungeon",tracker_objectives="Obiettivi",tracker_objectives_rows="Righe",tracker_objectives_text="Testo",tracker_objectives_none="Nascosti",tracker_timer_layout="Layout timer",tracker_timer_stacked="Impilato",tracker_timer_inline="In linea",tracker_segment_colors="Colori timer",tracker_segment_tiers="+3 / +2 / +1",tracker_segment_brand="Colore singolo",tracker_font_scale="Scala carattere tracker"},
    ptBR={tracker_background="Fundo",tracker_header="Bloco do cabeçalho",tracker_dungeon="Nome da masmorra",tracker_objectives="Objetivos",tracker_objectives_rows="Linhas",tracker_objectives_text="Texto",tracker_objectives_none="Ocultos",tracker_timer_layout="Layout do cronômetro",tracker_timer_stacked="Empilhado",tracker_timer_inline="Em linha",tracker_segment_colors="Cores do cronômetro",tracker_segment_tiers="+3 / +2 / +1",tracker_segment_brand="Cor única",tracker_font_scale="Escala da fonte do rastreador"},
}
for locale, values in pairs(V11_STYLE_I18N) do
    for key, value in pairs(values) do I18N[locale][key] = value end
end


local V111_I18N = {
    enUS={window_text_scale="Window text size", appearance="Appearance", tracker_preview_show="Open real tracker preview", tracker_preview_hide="Hide real tracker preview", weekly_reward_ilvl="Reward ilvl %d", weekly_reward_ilvl_unknown="Reward ilvl —"},
    frFR={window_text_scale="Taille du texte des fenêtres", appearance="Apparence", tracker_preview_show="Ouvrir l'aperçu réel", tracker_preview_hide="Masquer l'aperçu réel", weekly_reward_ilvl="Ilvl de récompense %d", weekly_reward_ilvl_unknown="Ilvl de récompense —"},
    deDE={window_text_scale="Fenster-Textgröße", appearance="Darstellung", tracker_preview_show="Echte Tracker-Vorschau öffnen", tracker_preview_hide="Echte Tracker-Vorschau ausblenden", weekly_reward_ilvl="Belohnungs-Itemlevel %d", weekly_reward_ilvl_unknown="Belohnungs-Itemlevel —"},
    esES={window_text_scale="Tamaño del texto de la ventana", appearance="Apariencia", tracker_preview_show="Abrir vista previa real", tracker_preview_hide="Ocultar vista previa real", weekly_reward_ilvl="Nivel de objeto %d", weekly_reward_ilvl_unknown="Nivel de objeto —"},
    itIT={window_text_scale="Dimensione testo finestre", appearance="Aspetto", tracker_preview_show="Apri anteprima reale", tracker_preview_hide="Nascondi anteprima reale", weekly_reward_ilvl="Livello oggetto ricompensa %d", weekly_reward_ilvl_unknown="Livello oggetto ricompensa —"},
    ptBR={window_text_scale="Tamanho do texto das janelas", appearance="Aparência", tracker_preview_show="Abrir prévia real", tracker_preview_hide="Ocultar prévia real", weekly_reward_ilvl="Nível de item da recompensa %d", weekly_reward_ilvl_unknown="Nível de item da recompensa —"},
}
local V113_I18N = {
    enUS={tracker_preview_button_show="Real preview", tracker_preview_button_hide="Hide preview", tracker_reset_short="Reset position"},
    frFR={tracker_preview_button_show="Aperçu réel", tracker_preview_button_hide="Masquer aperçu", tracker_reset_short="Réinit. position"},
    deDE={tracker_preview_button_show="Echte Vorschau", tracker_preview_button_hide="Vorschau aus", tracker_reset_short="Position zurücksetzen"},
    esES={tracker_preview_button_show="Vista real", tracker_preview_button_hide="Ocultar vista", tracker_reset_short="Restablecer posición"},
    itIT={tracker_preview_button_show="Anteprima reale", tracker_preview_button_hide="Nascondi antepr.", tracker_reset_short="Reset posizione"},
    ptBR={tracker_preview_button_show="Prévia real", tracker_preview_button_hide="Ocultar prévia", tracker_reset_short="Resetar posição"},
}
for locale, values in pairs(V113_I18N) do
    I18N[locale] = I18N[locale] or {}
    for key, value in pairs(values) do I18N[locale][key] = value end
end

for locale, values in pairs(V111_I18N) do
    I18N[locale] = I18N[locale] or {}
    for key, value in pairs(values) do I18N[locale][key] = value end
end


local V112_I18N = {
    enUS={appearance_window="Window",appearance_theme="Theme",appearance_preview="Preview",window_scale="Window scale",window_opacity="Background opacity",use_custom_accent="Use custom accent colour",studio_accent="Studio accent",appearance_reset="Reset appearance",appearance_note="These settings affect only the Mythic+ Studio. Tracker colours remain independent in Dungeon Tracker."},
    frFR={appearance_window="Fenêtre",appearance_theme="Thème",appearance_preview="Aperçu",window_scale="Échelle de la fenêtre",window_opacity="Opacité du fond",use_custom_accent="Utiliser une couleur d'accent personnalisée",studio_accent="Accent du Studio",appearance_reset="Réinitialiser l'apparence",appearance_note="Ces réglages concernent uniquement le Studio Mythic+. Les couleurs du tracker restent indépendantes dans Suivi en donjon."},
    deDE={appearance_window="Fenster",appearance_theme="Thema",appearance_preview="Vorschau",window_scale="Fensterskalierung",window_opacity="Hintergrunddeckkraft",use_custom_accent="Eigene Akzentfarbe verwenden",studio_accent="Studio-Akzent",appearance_reset="Darstellung zurücksetzen",appearance_note="Diese Einstellungen betreffen nur das Mythisch+ Studio. Tracker-Farben bleiben im Dungeon-Tracker unabhängig."},
    esES={appearance_window="Ventana",appearance_theme="Tema",appearance_preview="Vista previa",window_scale="Escala de la ventana",window_opacity="Opacidad del fondo",use_custom_accent="Usar color de acento personalizado",studio_accent="Acento del Studio",appearance_reset="Restablecer apariencia",appearance_note="Estos ajustes afectan solo al Studio Mítico+. Los colores del rastreador siguen siendo independientes en Seguimiento de mazmorra."},
    itIT={appearance_window="Finestra",appearance_theme="Tema",appearance_preview="Anteprima",window_scale="Scala finestra",window_opacity="Opacità sfondo",use_custom_accent="Usa colore accento personalizzato",studio_accent="Accento Studio",appearance_reset="Ripristina aspetto",appearance_note="Queste impostazioni riguardano solo Mythic+ Studio. I colori del tracker restano indipendenti nella pagina Tracker dungeon."},
    ptBR={appearance_window="Janela",appearance_theme="Tema",appearance_preview="Prévia",window_scale="Escala da janela",window_opacity="Opacidade do fundo",use_custom_accent="Usar cor de destaque personalizada",studio_accent="Destaque do Studio",appearance_reset="Redefinir aparência",appearance_note="Estas configurações afetam apenas o Mythic+ Studio. As cores do rastreador continuam independentes em Rastreador de masmorra."},
}
for locale, values in pairs(V112_I18N) do
    I18N[locale] = I18N[locale] or {}
    for key, value in pairs(values) do I18N[locale][key] = value end
end

function MP:T(key)
    local locale = GetLocale and GetLocale() or "enUS"
    local set = I18N[locale] or I18N.enUS
    return set[key] or I18N.enUS[key] or key
end

function MP:Open(page)
    if not self.BuildStudio then return end
    self:BuildStudio()
    local db = self:GetDB()
    if self.ApplyStudioAppearance then self:ApplyStudioAppearance() end
    self.page = page or db.ui.lastPage or "dashboard"
    db.ui.lastPage = self.page

    -- The content frame is anchored to the Studio shell. On the very first
    -- open those anchors have not been resolved yet while the shell is hidden,
    -- so content:GetWidth() can still be zero and Dashboard cards collapse.
    -- Position/show the shell first, then build the selected page from the
    -- resolved dimensions. Subsequent page switches already happened to work
    -- because the shell was visible by then.
    self.Frame:ClearAllPoints()
    self.Frame:SetPoint(db.ui.point or "CENTER", UIParent, db.ui.relPoint or "CENTER", db.ui.x or 0, db.ui.y or 20)
    self.Frame:Show()
    self:SelectPage(self.page)
end

function MP:Toggle(page)
    if self.Frame and self.Frame:IsShown() then
        self:Hide()
    else
        self:Open(page)
    end
end

function MP:Hide()
    if self.HideTrackerStandalonePreview then self:HideTrackerStandalonePreview(false) end
    if self.Frame then self.Frame:Hide() end
end

function MP:OnChallengeStart()
    if self.RunHistory and self.RunHistory.Start then self.RunHistory:Start() end
end

function MP:OnChallengeCompleted()
    if self.RunHistory and self.RunHistory.Complete then self.RunHistory:Complete() end
end

if C_MythicPlus and C_MythicPlus.RequestMapInfo then
    C_MythicPlus.RequestMapInfo()
end

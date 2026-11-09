-- v4.1.2 release notes: combat-safe TomoScore closing, Forever support removed,
-- cursor tooltip anchors, per-bar fade checkboxes, paging/fade diagnostics, GUI v2.

TomoMod_RegisterLocale("enUS", {
    ["wn_412_tomoscore_combat_close"] = "Fixed — Closing the TomoScore scoreboard during combat no longer calls a protected function. Its secure teleport buttons protect the parent frame too, so closing is deferred until combat ends.",
    ["wn_412_forever_removed"] = "Removed — TomoMod no longer supports WoW: Forever and now targets Retail (Midnight) only. Mythic+, Housing, Skyriding, Compass, Consumables, Prey Tracker and action bars no longer go through a client compatibility check, and the chat Reload shortcut reloads directly again.",
    ["wn_412_tooltip_anchor"] = "Fixed — The cursor tooltip now clears all of its anchors before following the cursor, removing the \"anchor family connection\" error on map pins and HandyNotes.",
    ["wn_412_fade_checkboxes"] = "Fixed — In the action-bar Fade tab, a bar without its own setting now follows the global switch. Unchecking and rechecking it no longer leaves the bar faded for good.",
    ["wn_412_diag_paging_fade"] = "New — The diagnostic report now explains Bar 1 paging (driver, current page, conditions true in stealth, forms or skyriding) and the mouseover fade decision and opacity for each bar.",
    ["wn_412_gui_v2"] = "New — The /tm options window has been rebuilt: one compact window docked to the side of the screen, settings applied live, a ghost mode that fades it while you adjust a slider or hold Alt, simple and expert modes, and a search that opens and highlights any option.",
    ["wn_412_gui_pages"] = "Changed — The new My frames, Party & raid and Nameplates pages replace Astral Forge, the Resource & Cast Studio and the Party & Raid Studio, with live previews and the real frame pulsing on screen. Only the Cooldown and Mythic+ Studios keep their own editors.",
})

TomoMod_RegisterLocale("frFR", {
    ["wn_412_tomoscore_combat_close"] = "Correction — Fermer le tableau TomoScore en combat n’appelle plus une fonction protégée. Ses boutons de téléportation sécurisés protègent aussi le cadre parent : la fermeture attend maintenant la fin du combat.",
    ["wn_412_forever_removed"] = "Retiré — TomoMod ne prend plus en charge WoW : Forever et vise désormais uniquement Retail (Midnight). Le Mythique+, le logement, le vol dynamique, la boussole, les consommables, le traqueur de proie et les barres d’action ne passent plus par un contrôle de compatibilité client, et le raccourci Recharger du chat recharge de nouveau directement l’interface.",
    ["wn_412_tooltip_anchor"] = "Correction — L’infobulle suivant le curseur efface désormais tous ses points d’ancrage avant de se déplacer, ce qui supprime l’erreur « anchor family connection » sur les marqueurs de carte et HandyNotes.",
    ["wn_412_fade_checkboxes"] = "Correction — Dans l’onglet Fondu des barres d’action, une barre sans réglage propre suit maintenant l’interrupteur global. La décocher puis la recocher ne la laisse plus estompée définitivement.",
    ["wn_412_diag_paging_fade"] = "Nouveau — Le rapport de diagnostic détaille la pagination de la barre 1 (driver, page active, conditions vraies en furtivité, en forme ou en vol dynamique) ainsi que la décision de fondu et l’opacité de chaque barre.",
    ["wn_412_gui_v2"] = "Nouveauté — La fenêtre d’options /tm a été reconstruite : une fenêtre compacte ancrée sur le côté de l’écran, des réglages appliqués en direct, un mode fantôme qui l’estompe pendant que vous réglez un curseur ou maintenez Alt, des modes simple et expert, et une recherche qui ouvre et met en évidence n’importe quelle option.",
    ["wn_412_gui_pages"] = "Changement — Les nouvelles pages Mes cadres, Groupe & raid et Plaques de nom remplacent Astral Forge, le Studio Ressources & Incantations et le Studio Groupe & Raid, avec des aperçus en direct et le vrai cadre qui pulse à l’écran. Seuls les Studios Cooldown et Mythique+ gardent leur propre éditeur.",
})

TomoMod_RegisterLocale("deDE", {
    ["wn_412_tomoscore_combat_close"] = "Behoben — Das TomoScore-Ergebnisfenster ruft beim Schließen im Kampf keine geschützte Funktion mehr auf. Die sicheren Teleport-Schaltflächen schützen auch den übergeordneten Frame; das Fenster schließt jetzt nach dem Kampf.",
    ["wn_412_forever_removed"] = "Entfernt — TomoMod unterstützt WoW: Forever nicht mehr und richtet sich jetzt nur noch an Retail (Midnight). Mythisch+, Wohnen, Himmelsreiten, Kompass, Verbrauchsgüter, Beutejagd-Tracker und Aktionsleisten durchlaufen keine Client-Kompatibilitätsprüfung mehr, und die Neu-laden-Verknüpfung im Chat lädt die Oberfläche wieder direkt neu.",
    ["wn_412_tooltip_anchor"] = "Behoben — Der Tooltip am Mauszeiger entfernt jetzt alle Ankerpunkte, bevor er dem Zeiger folgt. Der Fehler „anchor family connection“ bei Kartenmarkierungen und HandyNotes tritt nicht mehr auf.",
    ["wn_412_fade_checkboxes"] = "Behoben — Im Reiter „Ausblenden“ der Aktionsleisten folgt eine Leiste ohne eigene Einstellung jetzt dem globalen Schalter. Abwählen und erneutes Anwählen lässt die Leiste nicht mehr dauerhaft ausgeblendet.",
    ["wn_412_diag_paging_fade"] = "Neu — Der Diagnosebericht erklärt jetzt das Seitenwechseln von Leiste 1 (Treiber, aktuelle Seite, zutreffende Bedingungen in Verstohlenheit, Gestalten oder beim Himmelsreiten) sowie Ausblendentscheidung und Deckkraft jeder Leiste.",
    ["wn_412_gui_v2"] = "Neu — Das Optionsfenster /tm wurde neu aufgebaut: ein kompaktes Fenster am Bildschirmrand, live übernommene Einstellungen, ein Geistermodus, der es beim Verschieben eines Reglers oder bei gedrückter Alt-Taste ausblendet, ein einfacher und ein Expertenmodus sowie eine Suche, die jede Option öffnet und hervorhebt.",
    ["wn_412_gui_pages"] = "Geändert — Die neuen Seiten Meine Rahmen, Gruppe & Schlachtzug und Namensplaketten ersetzen Astral Forge, das Ressourcen- & Zauber-Studio und das Gruppen- & Schlachtzug-Studio, mit Live-Vorschau und pulsierendem echtem Rahmen auf dem Bildschirm. Nur das Cooldown- und das Mythisch+-Studio behalten einen eigenen Editor.",
})

TomoMod_RegisterLocale("esES", {
    ["wn_412_tomoscore_combat_close"] = "Corrección — Cerrar el marcador de TomoScore durante el combate ya no llama a una función protegida. Sus botones seguros de teletransporte también protegen el marco principal, así que se cierra al terminar el combate.",
    ["wn_412_forever_removed"] = "Retirado — TomoMod ya no es compatible con WoW: Forever y ahora solo se dirige a Retail (Midnight). Mítico+, la vivienda, el vuelo dinámico, la brújula, los consumibles, el rastreador de presas y las barras de acción ya no pasan por una comprobación de compatibilidad del cliente, y el atajo Recargar del chat vuelve a recargar la interfaz directamente.",
    ["wn_412_tooltip_anchor"] = "Corrección — El tooltip que sigue al cursor ahora borra todos sus anclajes antes de moverse, lo que elimina el error «anchor family connection» en los marcadores del mapa y HandyNotes.",
    ["wn_412_fade_checkboxes"] = "Corrección — En la pestaña Desvanecido de las barras de acción, una barra sin ajuste propio ahora sigue el interruptor global. Desmarcarla y volver a marcarla ya no la deja desvanecida para siempre.",
    ["wn_412_diag_paging_fade"] = "Nuevo — El informe de diagnóstico detalla ahora la paginación de la barra 1 (driver, página actual, condiciones verdaderas en sigilo, formas o vuelo dinámico) y la decisión de desvanecido y la opacidad de cada barra.",
    ["wn_412_gui_v2"] = "Novedad — La ventana de opciones /tm se ha reconstruido: una ventana compacta anclada al lateral de la pantalla, ajustes aplicados en directo, un modo fantasma que la atenúa mientras ajustas un control deslizante o mantienes Alt, modos simple y experto, y una búsqueda que abre y resalta cualquier opción.",
    ["wn_412_gui_pages"] = "Cambio — Las nuevas páginas Mis marcos, Grupo y banda y Placas de nombre sustituyen a Astral Forge, al Estudio de recursos y lanzamientos y al Estudio de grupo y banda, con vistas previas en directo y el marco real parpadeando en pantalla. Solo los Estudios de reutilización y Mítico+ conservan su propio editor.",
})

TomoMod_RegisterLocale("itIT", {
    ["wn_412_tomoscore_combat_close"] = "Correzione — Chiudere il tabellone TomoScore durante il combattimento non richiama più una funzione protetta. I pulsanti sicuri di teletrasporto proteggono anche il frame principale, quindi la chiusura viene rinviata alla fine del combattimento.",
    ["wn_412_forever_removed"] = "Rimosso — TomoMod non supporta più WoW: Forever e ora è pensato solo per Retail (Midnight). Mitiche+, alloggi, volo dinamico, bussola, consumabili, tracciatore di prede e barre delle azioni non passano più per un controllo di compatibilità del client, e la scorciatoia Ricarica della chat ricarica di nuovo direttamente l’interfaccia.",
    ["wn_412_tooltip_anchor"] = "Correzione — Il tooltip che segue il cursore ora rimuove tutti i suoi ancoraggi prima di spostarsi, eliminando l’errore «anchor family connection» sui segnalini della mappa e con HandyNotes.",
    ["wn_412_fade_checkboxes"] = "Correzione — Nella scheda Dissolvenza delle barre delle azioni, una barra senza impostazione propria ora segue l’interruttore globale. Deselezionarla e riselezionarla non la lascia più dissolta per sempre.",
    ["wn_412_diag_paging_fade"] = "Novità — Il rapporto diagnostico ora descrive la paginazione della barra 1 (driver, pagina attuale, condizioni vere in furtività, nelle forme o in volo dinamico) e la decisione di dissolvenza e l’opacità di ogni barra.",
    ["wn_412_gui_v2"] = "Novità — La finestra delle opzioni /tm è stata ricostruita: una finestra compatta ancorata al lato dello schermo, impostazioni applicate in tempo reale, una modalità fantasma che la attenua mentre regoli un cursore o tieni premuto Alt, modalità semplice ed esperta e una ricerca che apre ed evidenzia qualsiasi opzione.",
    ["wn_412_gui_pages"] = "Modifica — Le nuove pagine I miei riquadri, Gruppo e incursione e Targhette sostituiscono Astral Forge, lo Studio risorse e lanci e lo Studio gruppo e incursione, con anteprime in tempo reale e il riquadro reale che pulsa sullo schermo. Solo gli Studi Cooldown e Mitiche+ mantengono un proprio editor.",
})

TomoMod_RegisterLocale("ptBR", {
    ["wn_412_tomoscore_combat_close"] = "Correção — Fechar o placar do TomoScore durante o combate não chama mais uma função protegida. Os botões seguros de teleporte também protegem o quadro principal, então ele será fechado quando o combate terminar.",
    ["wn_412_forever_removed"] = "Removido — O TomoMod não oferece mais suporte ao WoW: Forever e agora é voltado apenas para o Retail (Midnight). Mítico+, moradia, voo dinâmico, bússola, consumíveis, rastreador de presas e barras de ação não passam mais por uma verificação de compatibilidade do cliente, e o atalho Recarregar do chat volta a recarregar a interface diretamente.",
    ["wn_412_tooltip_anchor"] = "Correção — A dica de ferramenta que segue o cursor agora limpa todas as suas âncoras antes de se mover, eliminando o erro \"anchor family connection\" nos marcadores do mapa e no HandyNotes.",
    ["wn_412_fade_checkboxes"] = "Correção — Na aba Esmaecimento das barras de ação, uma barra sem configuração própria agora segue a chave global. Desmarcá-la e marcá-la de novo não a deixa mais esmaecida para sempre.",
    ["wn_412_diag_paging_fade"] = "Novo — O relatório de diagnóstico agora detalha a paginação da barra 1 (driver, página atual, condições verdadeiras em furtividade, formas ou voo dinâmico) e a decisão de esmaecimento e a opacidade de cada barra.",
    ["wn_412_gui_v2"] = "Novo — A janela de opções /tm foi reconstruída: uma janela compacta ancorada na lateral da tela, configurações aplicadas ao vivo, um modo fantasma que a esmaece enquanto você ajusta um controle deslizante ou segura Alt, modos simples e avançado, e uma busca que abre e destaca qualquer opção.",
    ["wn_412_gui_pages"] = "Alterado — As novas páginas Meus quadros, Grupo e raide e Placas de nome substituem o Astral Forge, o Estúdio de recursos e lançamentos e o Estúdio de grupo e raide, com prévias ao vivo e o quadro real pulsando na tela. Apenas os Estúdios de Recarga e Mítico+ mantêm seu próprio editor.",
})

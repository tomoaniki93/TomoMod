-- v4.1.2 release notes: combat-safe TomoScore closing, Forever layout,
-- cursor tooltip anchors, per-bar fade checkboxes, paging/fade diagnostics.

TomoMod_RegisterLocale("enUS", {
    ["wn_412_tomoscore_combat_close"] = "Fixed — Closing the TomoScore scoreboard during combat no longer calls a protected function. Its secure teleport buttons protect the parent frame too, so closing is deferred until combat ends.",
    ["wn_412_forever_layout"] = "Fixed — Layout mode no longer selects or opens settings for Mythic+, Prey, Skyriding, action bars, Compass or Consumables on WoW: Forever. The character-sheet M+ Score widget is also hidden when Mythic+ is unavailable.",
    ["wn_412_tooltip_anchor"] = "Fixed — The cursor tooltip now clears all of its anchors before following the cursor, removing the \"anchor family connection\" error on map pins and HandyNotes.",
    ["wn_412_fade_checkboxes"] = "Fixed — In the action-bar Fade tab, a bar without its own setting now follows the global switch. Unchecking and rechecking it no longer leaves the bar faded for good.",
    ["wn_412_diag_paging_fade"] = "New — The diagnostic report now explains Bar 1 paging (driver, current page, conditions true in stealth, forms or skyriding) and the mouseover fade decision and opacity for each bar.",
})

TomoMod_RegisterLocale("frFR", {
    ["wn_412_tomoscore_combat_close"] = "Correction — Fermer le tableau TomoScore en combat n’appelle plus une fonction protégée. Ses boutons de téléportation sécurisés protègent aussi le cadre parent : la fermeture attend maintenant la fin du combat.",
    ["wn_412_forever_layout"] = "Correction — Sur WoW : Forever, le mode Layout ne permet plus de sélectionner les éléments ni d’ouvrir les réglages du Mythique+, de Prey, du vol dynamique, des barres d’action, de la boussole ou des consommables. Le score M+ de la fiche personnage est également masqué si le Mythique+ est indisponible.",
    ["wn_412_tooltip_anchor"] = "Correction — L’infobulle suivant le curseur efface désormais tous ses points d’ancrage avant de se déplacer, ce qui supprime l’erreur « anchor family connection » sur les marqueurs de carte et HandyNotes.",
    ["wn_412_fade_checkboxes"] = "Correction — Dans l’onglet Fondu des barres d’action, une barre sans réglage propre suit maintenant l’interrupteur global. La décocher puis la recocher ne la laisse plus estompée définitivement.",
    ["wn_412_diag_paging_fade"] = "Nouveau — Le rapport de diagnostic détaille la pagination de la barre 1 (driver, page active, conditions vraies en furtivité, en forme ou en vol dynamique) ainsi que la décision de fondu et l’opacité de chaque barre.",
})

TomoMod_RegisterLocale("deDE", {
    ["wn_412_tomoscore_combat_close"] = "Behoben — Das TomoScore-Ergebnisfenster ruft beim Schließen im Kampf keine geschützte Funktion mehr auf. Die sicheren Teleport-Schaltflächen schützen auch den übergeordneten Frame; das Fenster schließt jetzt nach dem Kampf.",
    ["wn_412_forever_layout"] = "Behoben — Der Layoutmodus kann auf WoW: Forever keine Mythic+-, Beutejagd-, Himmelsreiten-, Aktionsleisten-, Kompass- oder Verbrauchsmaterial-Elemente mehr auswählen und deren Einstellungen öffnen. Das M+ Score-Widget im Charakterfenster wird ebenfalls ausgeblendet, wenn Mythic+ nicht verfügbar ist.",
    ["wn_412_tooltip_anchor"] = "Behoben — Der Tooltip am Mauszeiger entfernt jetzt alle Ankerpunkte, bevor er dem Zeiger folgt. Der Fehler „anchor family connection“ bei Kartenmarkierungen und HandyNotes tritt nicht mehr auf.",
    ["wn_412_fade_checkboxes"] = "Behoben — Im Reiter „Ausblenden“ der Aktionsleisten folgt eine Leiste ohne eigene Einstellung jetzt dem globalen Schalter. Abwählen und erneutes Anwählen lässt die Leiste nicht mehr dauerhaft ausgeblendet.",
    ["wn_412_diag_paging_fade"] = "Neu — Der Diagnosebericht erklärt jetzt das Seitenwechseln von Leiste 1 (Treiber, aktuelle Seite, zutreffende Bedingungen in Verstohlenheit, Gestalten oder beim Himmelsreiten) sowie Ausblendentscheidung und Deckkraft jeder Leiste.",
})

TomoMod_RegisterLocale("esES", {
    ["wn_412_tomoscore_combat_close"] = "Corrección — Cerrar el marcador de TomoScore durante el combate ya no llama a una función protegida. Sus botones seguros de teletransporte también protegen el marco principal, así que se cierra al terminar el combate.",
    ["wn_412_forever_layout"] = "Corrección — En WoW: Forever, el modo Layout ya no permite seleccionar elementos ni abrir los ajustes de Mítico+, Prey, vuelo dinámico, barras de acción, brújula o consumibles. También se oculta el indicador M+ Score de la ficha del personaje cuando Mítico+ no está disponible.",
    ["wn_412_tooltip_anchor"] = "Corrección — El tooltip que sigue al cursor ahora borra todos sus anclajes antes de moverse, lo que elimina el error «anchor family connection» en los marcadores del mapa y HandyNotes.",
    ["wn_412_fade_checkboxes"] = "Corrección — En la pestaña Desvanecido de las barras de acción, una barra sin ajuste propio ahora sigue el interruptor global. Desmarcarla y volver a marcarla ya no la deja desvanecida para siempre.",
    ["wn_412_diag_paging_fade"] = "Nuevo — El informe de diagnóstico detalla ahora la paginación de la barra 1 (driver, página actual, condiciones verdaderas en sigilo, formas o vuelo dinámico) y la decisión de desvanecido y la opacidad de cada barra.",
})

TomoMod_RegisterLocale("itIT", {
    ["wn_412_tomoscore_combat_close"] = "Correzione — Chiudere il tabellone TomoScore durante il combattimento non richiama più una funzione protetta. I pulsanti sicuri di teletrasporto proteggono anche il frame principale, quindi la chiusura viene rinviata alla fine del combattimento.",
    ["wn_412_forever_layout"] = "Correzione — Su WoW: Forever, la modalità Layout non consente più di selezionare elementi o aprire le impostazioni di Mitiche+, Prey, Volo dinamico, barre delle azioni, bussola o consumabili. Anche il riquadro M+ Score nella scheda del personaggio viene nascosto quando Mitiche+ non è disponibile.",
    ["wn_412_tooltip_anchor"] = "Correzione — Il tooltip che segue il cursore ora rimuove tutti i suoi ancoraggi prima di spostarsi, eliminando l’errore «anchor family connection» sui segnalini della mappa e con HandyNotes.",
    ["wn_412_fade_checkboxes"] = "Correzione — Nella scheda Dissolvenza delle barre delle azioni, una barra senza impostazione propria ora segue l’interruttore globale. Deselezionarla e riselezionarla non la lascia più dissolta per sempre.",
    ["wn_412_diag_paging_fade"] = "Novità — Il rapporto diagnostico ora descrive la paginazione della barra 1 (driver, pagina attuale, condizioni vere in furtività, nelle forme o in volo dinamico) e la decisione di dissolvenza e l’opacità di ogni barra.",
})

TomoMod_RegisterLocale("ptBR", {
    ["wn_412_tomoscore_combat_close"] = "Correção — Fechar o placar do TomoScore durante o combate não chama mais uma função protegida. Os botões seguros de teleporte também protegem o quadro principal, então ele será fechado quando o combate terminar.",
    ["wn_412_forever_layout"] = "Correção — No WoW: Forever, o modo Layout não permite mais selecionar elementos nem abrir configurações de Mítico+, Prey, voo dinâmico, barras de ação, bússola ou consumíveis. O indicador M+ Score da ficha do personagem também fica oculto quando Mítico+ não está disponível.",
    ["wn_412_tooltip_anchor"] = "Correção — A dica de ferramenta que segue o cursor agora limpa todas as suas âncoras antes de se mover, eliminando o erro \"anchor family connection\" nos marcadores do mapa e no HandyNotes.",
    ["wn_412_fade_checkboxes"] = "Correção — Na aba Esmaecimento das barras de ação, uma barra sem configuração própria agora segue a chave global. Desmarcá-la e marcá-la de novo não a deixa mais esmaecida para sempre.",
    ["wn_412_diag_paging_fade"] = "Novo — O relatório de diagnóstico agora detalha a paginação da barra 1 (driver, página atual, condições verdadeiras em furtividade, formas ou voo dinâmico) e a decisão de esmaecimento e a opacidade de cada barra.",
})

-- v4.1.2 release notes: combat-safe TomoScore closing.

TomoMod_RegisterLocale("enUS", {
    ["wn_412_tomoscore_combat_close"] = "Fixed — Closing the TomoScore scoreboard during combat no longer calls a protected function. Its secure teleport buttons protect the parent frame too, so closing is deferred until combat ends.",
    ["wn_412_forever_layout"] = "Fixed — Layout mode no longer selects or opens settings for Mythic+, Prey, Skyriding, action bars, Compass or Consumables on WoW: Forever. The character-sheet M+ Score widget is also hidden when Mythic+ is unavailable.",
})

TomoMod_RegisterLocale("frFR", {
    ["wn_412_tomoscore_combat_close"] = "Correction — Fermer le tableau TomoScore en combat n’appelle plus une fonction protégée. Ses boutons de téléportation sécurisés protègent aussi le cadre parent : la fermeture attend maintenant la fin du combat.",
    ["wn_412_forever_layout"] = "Correction — Sur WoW : Forever, le mode Layout ne permet plus de sélectionner les éléments ni d’ouvrir les réglages du Mythique+, de Prey, du vol dynamique, des barres d’action, de la boussole ou des consommables. Le score M+ de la fiche personnage est également masqué si le Mythique+ est indisponible.",
})

TomoMod_RegisterLocale("deDE", {
    ["wn_412_tomoscore_combat_close"] = "Behoben — Das TomoScore-Ergebnisfenster ruft beim Schließen im Kampf keine geschützte Funktion mehr auf. Die sicheren Teleport-Schaltflächen schützen auch den übergeordneten Frame; das Fenster schließt jetzt nach dem Kampf.",
    ["wn_412_forever_layout"] = "Behoben — Der Layoutmodus kann auf WoW: Forever keine Mythic+-, Beutejagd-, Himmelsreiten-, Aktionsleisten-, Kompass- oder Verbrauchsmaterial-Elemente mehr auswählen und deren Einstellungen öffnen. Das M+ Score-Widget im Charakterfenster wird ebenfalls ausgeblendet, wenn Mythic+ nicht verfügbar ist.",
})

TomoMod_RegisterLocale("esES", {
    ["wn_412_tomoscore_combat_close"] = "Corrección — Cerrar el marcador de TomoScore durante el combate ya no llama a una función protegida. Sus botones seguros de teletransporte también protegen el marco principal, así que se cierra al terminar el combate.",
    ["wn_412_forever_layout"] = "Corrección — En WoW: Forever, el modo Layout ya no permite seleccionar elementos ni abrir los ajustes de Mítico+, Prey, vuelo dinámico, barras de acción, brújula o consumibles. También se oculta el indicador M+ Score de la ficha del personaje cuando Mítico+ no está disponible.",
})

TomoMod_RegisterLocale("itIT", {
    ["wn_412_tomoscore_combat_close"] = "Correzione — Chiudere il tabellone TomoScore durante il combattimento non richiama più una funzione protetta. I pulsanti sicuri di teletrasporto proteggono anche il frame principale, quindi la chiusura viene rinviata alla fine del combattimento.",
    ["wn_412_forever_layout"] = "Correzione — Su WoW: Forever, la modalità Layout non consente più di selezionare elementi o aprire le impostazioni di Mitiche+, Prey, Volo dinamico, barre delle azioni, bussola o consumabili. Anche il riquadro M+ Score nella scheda del personaggio viene nascosto quando Mitiche+ non è disponibile.",
})

TomoMod_RegisterLocale("ptBR", {
    ["wn_412_tomoscore_combat_close"] = "Correção — Fechar o placar do TomoScore durante o combate não chama mais uma função protegida. Os botões seguros de teleporte também protegem o quadro principal, então ele será fechado quando o combate terminar.",
    ["wn_412_forever_layout"] = "Correção — No WoW: Forever, o modo Layout não permite mais selecionar elementos nem abrir configurações de Mítico+, Prey, voo dinâmico, barras de ação, bússola ou consumíveis. O indicador M+ Score da ficha do personagem também fica oculto quando Mítico+ não está disponível.",
})

-- v4.1.1 release notes: InfoPanel artwork, protected item levels Forever fixes and diagnostic exclusions.

TomoMod_RegisterLocale("enUS", {
    ["wn_411_infopanel_icons"] = "Changed — The InfoPanel now uses a golden key, parchment scroll and potion for the keystone shortcut, addon collector and consumable tracker. Full-color transparent artwork replaces the square monochrome buttons, preserving click actions and tooltips.",
    ["wn_411_consumable_status"] = "Changed — The flask keeps its original colors. A small green or red indicator shows consumable readiness in group content and stays hidden outside eligible content.",
    ["wn_411_loots_secret_level"] = "Fixed — Loots checks protected item levels before calculating preview adjustments. When the base level is secret, it uses the plain item link. Regression coverage was added and the CI secret-value lint passes without baseline changes.",
    ["wn_411_forever_specializations"] = "Fixed — On WoW: Forever, CompanionStatus and ResourceBars now check for specialization APIs before using them, preventing Lua errors when retail specialization information is unavailable.",
    ["wn_411_forever_cooldowns"] = "Fixed — Action-bar cooldowns now recognize the modern duration API on WoW: Forever despite its 16001 interface number, avoiding the incompatible legacy update path.",
    ["wn_411_diagnostics_exclusions"] = "Changed — Diagnostics now excludes normal loot-access and busy-object feedback, plus the French Kindo’jan labyrinth progression messages for Nalorakk, Halazzi, Akil’zon and Jan’alai.",
    ["wn_411_forever_reputation"] = "Fixed — Opening the Reputation tab on WoW: Forever no longer causes a Lua error. The character skin now supports its Fill-based progress bars as well as Retail StatusBars.",
    ["wn_411_forever_game_menu"] = "Fixed — On WoW: Forever, the TomoMod game-menu button now appears below Options. Retail keeps its existing placement below Store.",
    ["wn_411_forever_character_score"] = "Changed — The character-sheet M+ Score widget is now disabled on WoW: Forever, including its update hooks and challenge-mode event listeners. It remains available on Retail.",
    ["wn_411_forever_chat_reload"] = "Fixed — On WoW: Forever, the chat sidebar Reload interface shortcut now prepares /reload in chat for you to submit with Enter, avoiding the blocked direct reload call. Retail keeps the direct reload action.",
})

TomoMod_RegisterLocale("frFR", {
    ["wn_411_infopanel_icons"] = "Modification — L’InfoPanel utilise désormais une clé dorée, un parchemin et une fiole pour le raccourci de clé mythique, le collecteur d’addons et le suivi des consommables. Les images en couleur sur fond transparent remplacent les boutons carrés monochromes, avec les mêmes clics et infobulles.",
    ["wn_411_consumable_status"] = "Modification — La fiole conserve ses couleurs d’origine. Un petit témoin vert ou rouge indique l’état des consommables en contenu de groupe et reste masqué en dehors des contenus concernés.",
    ["wn_411_loots_secret_level"] = "Correction — Loots vérifie les niveaux d’objet protégés avant de calculer les ajustements d’aperçu. Si le niveau de base est secret, le lien simple est utilisé. Un test de régression a été ajouté et le contrôle CI des valeurs secrètes passe sans modifier la liste des exceptions.",
    ["wn_411_forever_specializations"] = "Correction — Sur WoW : Forever, CompanionStatus et ResourceBars vérifient désormais la présence des API de spécialisation avant de les utiliser, évitant les erreurs Lua lorsque les informations de spécialisation de Retail sont indisponibles.",
    ["wn_411_forever_cooldowns"] = "Correction — Les temps de recharge des barres d’action reconnaissent désormais l’API moderne de durée sur WoW : Forever malgré son numéro d’interface 16001, évitant l’ancien traitement incompatible.",
    ["wn_411_diagnostics_exclusions"] = "Modification — Le diagnostic exclut désormais les messages normaux de butin inaccessible et d’objet déjà utilisé, ainsi que les messages français de progression du labyrinthe de Kindo’jan pour Nalorakk, Halazzi, Akil’zon et Jan’alai.",
    ["wn_411_forever_reputation"] = "Correction — L’ouverture de l’onglet Réputation sur WoW : Forever ne provoque plus d’erreur Lua. Le skin de personnage gère désormais ses barres de progression à texture Fill ainsi que les StatusBar de Retail.",
    ["wn_411_forever_game_menu"] = "Correction — Sur WoW : Forever, le bouton TomoMod du menu de jeu apparaît désormais sous Options. Sur Retail, il conserve sa position sous Boutique.",
    ["wn_411_forever_character_score"] = "Modification — Le widget M+ Score de la fiche personnage est désormais désactivé sur WoW : Forever, ainsi que ses mises à jour et ses événements de mode défi. Il reste disponible sur Retail.",
    ["wn_411_forever_chat_reload"] = "Correction — Sur WoW : Forever, le raccourci Recharger l’interface de la barre latérale du chat prépare désormais /reload dans le chat, à valider avec Entrée, pour éviter l’appel direct bloqué. Retail conserve le rechargement direct.",
})

TomoMod_RegisterLocale("deDE", {
    ["wn_411_infopanel_icons"] = "Änderung — Das Infopanel verwendet jetzt einen goldenen Schlüssel, eine Schriftrolle und einen Trank für den Schlüsselsteinzugriff, die Addon-Sammlung und die Verbrauchsmaterialanzeige. Farbige Grafiken mit transparentem Hintergrund ersetzen die quadratischen einfarbigen Schaltflächen; Klickaktionen und Tooltips bleiben erhalten.",
    ["wn_411_consumable_status"] = "Änderung — Der Trank behält seine ursprünglichen Farben. Eine kleine grüne oder rote Anzeige zeigt in Gruppeninhalten den Verbrauchsmaterialstatus und bleibt außerhalb der betreffenden Inhalte ausgeblendet.",
    ["wn_411_loots_secret_level"] = "Behoben — Loots prüft geschützte Gegenstandsstufen vor der Berechnung der Vorschau. Ist die Basisstufe geheim, wird der einfache Gegenstandslink verwendet. Ein Regressionstest wurde ergänzt; die CI-Prüfung auf geheime Werte besteht ohne Änderungen an der Ausnahmeliste.",
    ["wn_411_forever_specializations"] = "Behoben — CompanionStatus und ResourceBars prüfen auf WoW: Forever jetzt vor der Nutzung, ob die Spezialisierungs-APIs vorhanden sind. Dadurch werden Lua-Fehler bei fehlenden Retail-Spezialisierungsinformationen verhindert.",
    ["wn_411_forever_cooldowns"] = "Behoben — Die Abklingzeiten der Aktionsleisten erkennen die moderne Dauer-API auf WoW: Forever jetzt trotz der Interfacenummer 16001 und vermeiden den inkompatiblen alten Aktualisierungspfad.",
    ["wn_411_diagnostics_exclusions"] = "Änderung — Die Diagnose filtert jetzt normale Meldungen zu unzugänglicher Beute und bereits benutzten Objekten sowie die französischen Fortschrittsmeldungen im Labyrinth von Kindo’jan für Nalorakk, Halazzi, Akil’zon und Jan’alai.",
    ["wn_411_forever_reputation"] = "Behoben — Das Öffnen des Rufs-Tabs auf WoW: Forever verursacht keinen Lua-Fehler mehr. Der Charakter-Skin unterstützt jetzt dessen Fortschrittsleisten mit Fill-Textur sowie die StatusBars von Retail.",
    ["wn_411_forever_game_menu"] = "Behoben — Auf WoW: Forever erscheint die TomoMod-Schaltfläche im Spielmenü jetzt unter Optionen. Auf Retail bleibt sie unter Shop.",
    ["wn_411_forever_character_score"] = "Änderung — Das M+ Score-Widget im Charakterfenster ist auf WoW: Forever jetzt deaktiviert, einschließlich seiner Aktualisierungshooks und Ereignisbehandlung für den Herausforderungsmodus. Auf Retail bleibt es verfügbar.",
    ["wn_411_forever_chat_reload"] = "Behoben — Auf WoW: Forever trägt die Funktion zum Neuladen der Oberfläche in der Chat-Seitenleiste jetzt /reload in den Chat ein. Mit Eingabe bestätigen, um den blockierten direkten Aufruf zu vermeiden. Auf Retail wird die Oberfläche weiterhin direkt neu geladen.",
})

TomoMod_RegisterLocale("esES", {
    ["wn_411_infopanel_icons"] = "Cambio — El panel de información usa una llave dorada, un pergamino y una poción para el acceso a piedras angulares, el colector de addons y el seguimiento de consumibles. Las imágenes a color con fondo transparente sustituyen a los botones cuadrados monocromos y conservan los clics y las ayudas.",
    ["wn_411_consumable_status"] = "Cambio — La poción conserva sus colores originales. Un pequeño indicador verde o rojo muestra el estado de los consumibles en contenido de grupo y permanece oculto fuera del contenido correspondiente.",
    ["wn_411_loots_secret_level"] = "Corrección — Loots comprueba los niveles de objeto protegidos antes de calcular los ajustes de la vista previa. Si el nivel base es secreto, usa el enlace simple. Se añadió una prueba de regresión y el control de valores secretos de CI pasa sin cambiar la lista de excepciones.",
    ["wn_411_forever_specializations"] = "Corrección — En WoW: Forever, CompanionStatus y ResourceBars comprueban que las API de especialización están disponibles antes de usarlas, evitando errores de Lua cuando no hay información de especializaciones de Retail.",
    ["wn_411_forever_cooldowns"] = "Corrección — Los tiempos de reutilización de las barras de acción reconocen la API moderna de duración en WoW: Forever pese a su número de interfaz 16001, evitando el método antiguo incompatible.",
    ["wn_411_diagnostics_exclusions"] = "Cambio — El diagnóstico excluye los avisos normales de botín inaccesible y objetos en uso, además de los mensajes franceses de progreso del laberinto de Kindo’jan para Nalorakk, Halazzi, Akil’zon y Jan’alai.",
    ["wn_411_forever_reputation"] = "Corrección — Abrir la pestaña Reputación en WoW: Forever ya no provoca un error de Lua. El aspecto de personaje admite sus barras de progreso con textura Fill y las StatusBar de Retail.",
    ["wn_411_forever_game_menu"] = "Corrección — En WoW: Forever, el botón TomoMod del menú de juego aparece ahora debajo de Opciones. En Retail conserva su posición debajo de Tienda.",
    ["wn_411_forever_character_score"] = "Cambio — El indicador M+ Score de la ficha de personaje está ahora desactivado en WoW: Forever, incluidas sus actualizaciones y la gestión de eventos del modo desafío. Sigue disponible en Retail.",
    ["wn_411_forever_chat_reload"] = "Corrección — En WoW: Forever, el acceso para recargar la interfaz de la barra lateral del chat ahora prepara /reload en el chat para confirmarlo con Intro, evitando la llamada directa bloqueada. Retail mantiene la recarga directa.",
})

TomoMod_RegisterLocale("itIT", {
    ["wn_411_infopanel_icons"] = "Modifica — Il pannello informazioni usa una chiave dorata, una pergamena e una pozione per l’accesso alle Chiavi del Potere, il raccoglitore di addon e il monitoraggio dei consumabili. Le immagini a colori su sfondo trasparente sostituiscono i pulsanti quadrati monocromatici, mantenendo clic e descrizioni.",
    ["wn_411_consumable_status"] = "Modifica — La pozione mantiene i colori originali. Un piccolo indicatore verde o rosso mostra lo stato dei consumabili nei contenuti di gruppo e resta nascosto al di fuori dei contenuti interessati.",
    ["wn_411_loots_secret_level"] = "Correzione — Loots controlla i livelli oggetto protetti prima di calcolare gli adeguamenti dell’anteprima. Se il livello base è segreto, usa il collegamento semplice. Aggiunto un test di regressione; il controllo CI dei valori segreti passa senza modificare l’elenco delle eccezioni.",
    ["wn_411_forever_specializations"] = "Correzione — Su WoW: Forever, CompanionStatus e ResourceBars verificano ora la presenza delle API di specializzazione prima di usarle, evitando errori Lua quando le informazioni sulle specializzazioni di Retail non sono disponibili.",
    ["wn_411_forever_cooldowns"] = "Correzione — I tempi di recupero delle barre delle azioni riconoscono ora la moderna API di durata su WoW: Forever nonostante il numero di interfaccia 16001, evitando il vecchio percorso di aggiornamento incompatibile.",
    ["wn_411_diagnostics_exclusions"] = "Modifica — La diagnostica esclude ora i normali messaggi di bottino inaccessibile e oggetti già in uso, oltre ai messaggi francesi di avanzamento nel labirinto di Kindo’jan per Nalorakk, Halazzi, Akil’zon e Jan’alai.",
    ["wn_411_forever_reputation"] = "Correzione — Aprire la scheda Reputazione su WoW: Forever non causa più un errore Lua. La skin del personaggio supporta ora le barre di avanzamento con texture Fill e le StatusBar di Retail.",
    ["wn_411_forever_game_menu"] = "Correzione — Su WoW: Forever, il pulsante TomoMod nel menu di gioco appare ora sotto Opzioni. Su Retail mantiene la posizione sotto Negozio.",
    ["wn_411_forever_character_score"] = "Modifica — Il riquadro M+ Score nella scheda del personaggio è ora disattivato su WoW: Forever, insieme agli aggiornamenti e alla gestione degli eventi della modalità sfida. Resta disponibile su Retail.",
    ["wn_411_forever_chat_reload"] = "Correzione — Su WoW: Forever, il comando per ricaricare l’interfaccia nella barra laterale della chat prepara ora /reload nella chat, da confermare con Invio, evitando la chiamata diretta bloccata. Retail mantiene il ricaricamento diretto.",
})

TomoMod_RegisterLocale("ptBR", {
    ["wn_411_infopanel_icons"] = "Alteração — O painel de informações usa uma chave dourada, um pergaminho e uma poção para o atalho de pedras-chave, o coletor de addons e o rastreador de consumíveis. Imagens coloridas com fundo transparente substituem os botões quadrados monocromáticos, mantendo os cliques e as dicas.",
    ["wn_411_consumable_status"] = "Alteração — A poção mantém as cores originais. Um pequeno indicador verde ou vermelho mostra o estado dos consumíveis em conteúdo de grupo e fica oculto fora dos conteúdos correspondentes.",
    ["wn_411_loots_secret_level"] = "Correção — O Loots verifica níveis de item protegidos antes de calcular os ajustes da prévia. Se o nível básico for secreto, usa o link simples. Foi adicionado um teste de regressão, e a verificação de valores secretos da CI passa sem alterar a lista de exceções.",
    ["wn_411_forever_specializations"] = "Correção — No WoW: Forever, CompanionStatus e ResourceBars agora verificam a presença das APIs de especialização antes de usá-las, evitando erros de Lua quando as informações de especialização do Retail não estão disponíveis.",
    ["wn_411_forever_cooldowns"] = "Correção — As recargas das barras de ação agora reconhecem a API moderna de duração no WoW: Forever apesar do número de interface 16001, evitando o método antigo de atualização incompatível.",
    ["wn_411_diagnostics_exclusions"] = "Alteração — O diagnóstico agora exclui avisos normais de saque inacessível e objetos em uso, além das mensagens francesas de progressão do labirinto de Kindo’jan para Nalorakk, Halazzi, Akil’zon e Jan’alai.",
    ["wn_411_forever_reputation"] = "Correção — Abrir a aba Reputação no WoW: Forever não causa mais um erro de Lua. O visual do personagem agora aceita as barras de progresso com textura Fill e as StatusBar do Retail.",
    ["wn_411_forever_game_menu"] = "Correção — No WoW: Forever, o botão TomoMod do menu do jogo agora aparece abaixo de Opções. No Retail, ele mantém a posição abaixo de Loja.",
    ["wn_411_forever_character_score"] = "Alteração — O indicador M+ Score da ficha de personagem agora está desativado no WoW: Forever, incluindo suas atualizações e o tratamento de eventos do modo desafio. Ele continua disponível no Retail.",
    ["wn_411_forever_chat_reload"] = "Correção — No WoW: Forever, o atalho para recarregar a interface na barra lateral do bate-papo agora prepara /reload no bate-papo para confirmar com Enter, evitando a chamada direta bloqueada. O Retail mantém a recarga direta.",
})

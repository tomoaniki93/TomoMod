-- =====================================================================
-- Locale_300.lua — Chaînes de la 3.0 (6 langues)
-- ---------------------------------------------------------------------
-- Source unique pour toutes les nouvelles chaînes 3.0 :
--   • Presets (preset_*)
--   • Installeur « presets d'abord » (ins_v3_*, ins_pick_*, ins_custom_*,
--     ins_recap_*)
--   • Accueil / Dashboard (dash_*) + recherche (cat_accueil, ui_search_*)
--   • What's New 3.0 (wn_300_*)
--
-- Chargé dans la section Locales du .toc (donc AVANT Core et Config),
-- pour que cat_accueil / wn_300_* soient résolus à temps.
-- enUS = fallback de base ; les autres langues le surchargent.
-- =====================================================================

-- =====================
-- enUS (base)
-- =====================
TomoMod_RegisterLocale("enUS", {
    -- [3.0.5] Compass (Waypoint 2.0)
    ["mover_compass"] = "Compass",
    ["ready_tracker_section"] = "Consumable readiness",
    ["ready_tracker_info"] = "Shows Flask, Well Fed and Thalassian Phoenix Oil below the minimap, next to the clock. The button is available everywhere; it only turns green or red in dungeons, raids, scenarios and delves.",
    ["ready_tracker_enable"] = "Enable consumable tracker",
    ["ready_tracker_button_side"] = "Button position",
    ["ready_tracker_button_size"] = "Button size",
    ["ready_tracker_tracker_size"] = "Tracker size",
    ["ready_tracker_side_left"] = "Left of the clock",
    ["ready_tracker_side_right"] = "Right of the clock",
    ["compass_dir_n"] = "N",
    ["compass_dir_e"] = "E",
    ["compass_dir_s"] = "S",
    ["compass_dir_w"] = "W",
    ["msg_help_compass"] = "Toggle the heading compass bar",
    ["wn_305_compass"] = "New Compass bar (Waypoint 2.0): an optional heading bar at the top of the screen that scrolls through the cardinal directions as you turn, with amber/teal markers pointing toward your tracked quest and map waypoint. Fully movable in Layout mode and configurable in Quality of Life > Compass.",
    -- [3.0.2] Changelog (What is New)
    ["wn_302_collector_capture"] = "Minimap button collector is much more reliable: it now captures addon buttons it previously missed - including ones that floated on the minimap ring or vanished when dragged.",
    ["wn_302_collector_clean"] = "Collected buttons get a clean, uniform look: decorative borders are stripped, icons normalized, and LibDBIcon's locked layering is unlocked so every button renders correctly.",
    ["wn_302_collector_poll"] = "Buttons from addons that load late are now detected automatically (no manual rescan needed).",
    ["wn_302_native_choice"] = "Blizzard's native tracking button and addon compartment are now hidden by default. A new GUI option lets you choose, for each, between the TomoMod version and Blizzard's.",
    -- [3.0.2] Minimap : style pistage + collecteur
    -- [3.0.1] Changelog (What is New)
    ["wn_301_locale_fix"] = "Fixed a startup crash in the localization file that left many config panels showing raw keys (Minimap, ButtonBag, Skins, Resource Bars...) - all labels are now correctly translated.",
    ["wn_301_combat_movers"] = "Layout mode no longer triggers blocked-action errors when toggled in combat: it is safely refused, and if combat starts while unlocked, frames re-lock automatically once combat ends.",
    ["wn_301_procglow_taint"] = "Fixed a taint error on Cooldown Manager proc glows caused by comparing a protected spell ID value.",
    ["wn_301_ground_speed"] = "Ground movement speed is now shown by default on the SkyRide bar (toggle in the SkyRide tab).",
    ["wn_301_buttonbag_clock"] = "The minimap button collector can now be placed to the left or right of the clock so it no longer covers the map.",
    -- [3.0.1] ButtonBag : ancrage horloge
    -- [3.0.1] Clés ajoutées (movers anti-combat + libellés de panels manquants)
    ["layout_combat_blocked"] = "You can't move the interface while in combat.",
    ["btn_housing_leave"] = "Leave house",
    ["mover_actionbars"] = "Action Bars",
    ["wn_2921_waypoint_arrow"] = "Smart Waypoint - direction arrow: an on-screen arrow now points toward the tracked waypoint, with live distance, so you always know which way to go.",
    -- Presets
    -- Installeur v3
    -- Accueil / recherche
    ["gs_no_results"]           = "No matching option",
    ["minimap_buttonbag"] = "Addon buttons",
    ["minimap_buttonbag_hint"] = "Click: show/hide",
    ["minimap_buttonbag_empty"] = "No buttons detected",
    ["cr_preview_sample"] = "Example: missing class buff",
    ["section_cdm_preview"] = "Preview",
    ["info_cdm_preview"] = "Cooldown bars only show icons when spells are actually on cooldown. To see and position them with examples, open Blizzard's Edit Mode.",
    ["section_rb_preview"] = "Preview",
    ["info_rb_preview"] = "Resource bars show your real resource (mana, energy, combo points…). To position them with a preview, open Blizzard's Edit Mode or unlock them from the Text tab.",
    ["btn_open_editmode"] = "Open Edit Mode",
    ["info_editmode_combat"] = "Edit Mode can't be opened in combat.",
    -- What's New 3.0
    ["wn_300_locales"]    = "Full localization for all new 3.0 strings across the 6 supported languages.",
})

-- =====================
-- frFR
-- =====================
TomoMod_RegisterLocale("frFR", {
    -- [3.0.5] Compass (Waypoint 2.0)
    ["mover_compass"] = "Boussole",
    ["ready_tracker_section"] = "Préparation des consommables",
    ["ready_tracker_info"] = "Affiche Flacon, Bien nourri et Huile de phénix thalassienne sous la minicarte, à côté de l'heure. Le bouton est disponible partout ; il ne passe au vert ou au rouge qu'en donjon, raid, scénario et gouffre.",
    ["ready_tracker_enable"] = "Activer le suivi des consommables",
    ["ready_tracker_button_side"] = "Position du bouton",
    ["ready_tracker_button_size"] = "Taille du bouton",
    ["ready_tracker_tracker_size"] = "Taille du tracker",
    ["ready_tracker_side_left"] = "À gauche de l'heure",
    ["ready_tracker_side_right"] = "À droite de l'heure",
    ["compass_dir_n"] = "N",
    ["compass_dir_e"] = "E",
    ["compass_dir_s"] = "S",
    ["compass_dir_w"] = "O",
    ["msg_help_compass"] = "Afficher/masquer la barre de boussole",
    ["wn_305_compass"] = "Nouvelle barre de Boussole (Waypoint 2.0) : une barre de cap optionnelle en haut de l'écran qui fait défiler les points cardinaux quand vous tournez, avec des marqueurs ambre/teal pointant vers la quête suivie et le point de route. Entièrement déplaçable en mode Placement et configurable dans Confort de jeu > Boussole.",
    -- [3.0.2] Changelog (What is New)
    ["wn_302_collector_capture"] = "Le collecteur de boutons de la minimap est bien plus fiable : il capture désormais des boutons d'addon qu'il manquait avant - y compris ceux qui flottaient sur l'anneau de la minimap ou disparaissaient quand on les déplaçait.",
    ["wn_302_collector_clean"] = "Les boutons collectés ont un rendu propre et uniforme : bordures décoratives retirées, icônes normalisées, et le calque verrouillé de LibDBIcon est déverrouillé pour que chaque bouton s'affiche correctement.",
    ["wn_302_collector_poll"] = "Les boutons des addons chargés tardivement sont désormais détectés automatiquement (plus besoin de rescanner à la main).",
    ["wn_302_native_choice"] = "Le bouton de pistage natif de Blizzard et le compartiment d'addons sont désormais masqués par défaut. Une nouvelle option du GUI permet de choisir, pour chacun, entre la version TomoMod et celle de Blizzard.",
    -- [3.0.2] Minimap : style pistage + collecteur
    -- [3.0.1] Changelog (What is New)
    ["wn_301_locale_fix"] = "Correction d'un crash au chargement du fichier de localisation qui laissait de nombreux panneaux de config en clés brutes (Minimap, ButtonBag, Skins, Barres de ressources...) - tous les libellés sont désormais correctement traduits.",
    ["wn_301_combat_movers"] = "Le mode placement ne provoque plus d'erreurs de blocage en combat : il est refusé proprement, et si le combat démarre alors que l'interface est déverrouillée, les cadres se re-verrouillent automatiquement à la fin du combat.",
    ["wn_301_procglow_taint"] = "Correction d'une erreur de taint sur les effets de proc du Cooldown Manager, causée par la comparaison d'une valeur d'ID de sort protégée.",
    ["wn_301_ground_speed"] = "La vitesse de déplacement au sol est désormais affichée par défaut sur la barre SkyRide (option dans l'onglet SkyRide).",
    ["wn_301_buttonbag_clock"] = "Le collecteur de boutons de la minimap peut désormais se placer à gauche ou à droite de l'horloge pour ne plus recouvrir la carte.",
    -- [3.0.1] ButtonBag : ancrage horloge
    -- [3.0.1] Clés ajoutées (movers anti-combat + libellés de panels manquants)
    ["layout_combat_blocked"] = "Impossible de déplacer l'interface en combat.",
    ["btn_housing_leave"] = "Quitter la maison",
    ["mover_actionbars"] = "Barres d'action",
    ["wn_2921_waypoint_arrow"] = "Waypoint intelligent - flèche directionnelle : une flèche à l'écran pointe désormais vers le waypoint suivi, avec la distance en temps réel, pour toujours savoir où aller.",
    ["gs_no_results"]           = "Aucune option correspondante",
    ["minimap_buttonbag"] = "Boutons d'addon",
    ["minimap_buttonbag_hint"] = "Clic : afficher/masquer",
    ["minimap_buttonbag_empty"] = "Aucun bouton détecté",
    ["cr_preview_sample"] = "Exemple : buff de classe manquant",
    ["section_cdm_preview"] = "Aperçu",
    ["info_cdm_preview"] = "Les barres de cooldown n'affichent des icônes que lorsque des sorts sont réellement en recharge. Pour les voir et les positionner avec des exemples, ouvre l'Edit Mode de Blizzard.",
    ["section_rb_preview"] = "Aperçu",
    ["info_rb_preview"] = "Les barres de ressources affichent ta ressource réelle (mana, énergie, points de combo…). Pour les positionner avec un aperçu, ouvre l'Edit Mode de Blizzard ou déverrouille-les depuis l'onglet Texte.",
    ["btn_open_editmode"] = "Ouvrir l'Edit Mode",
    ["info_editmode_combat"] = "L'Edit Mode ne peut pas être ouvert en combat.",
    ["wn_300_locales"]    = "Localisation complète de toutes les nouvelles chaînes 3.0 dans les 6 langues supportées.",
})

-- =====================
-- deDE
-- =====================
TomoMod_RegisterLocale("deDE", {
    -- [3.0.5] Compass (Waypoint 2.0)
    ["mover_compass"] = "Kompass",
    ["ready_tracker_section"] = "Verbrauchsbereitschaft",
    ["ready_tracker_info"] = "Zeigt Fläschchen, Satt und Thalassisches Phönixöl unter der Minikarte, neben der Uhr. Die Schaltfläche ist überall verfügbar; sie wird nur in Dungeons, Schlachtzügen, Szenarien und Tiefen grün oder rot.",
    ["ready_tracker_enable"] = "Verbrauchs-Tracker aktivieren",
    ["ready_tracker_button_side"] = "Schaltflächenposition",
    ["ready_tracker_button_size"] = "Schaltflächengröße",
    ["ready_tracker_tracker_size"] = "Tracker-Größe",
    ["ready_tracker_side_left"] = "Links von der Uhr",
    ["ready_tracker_side_right"] = "Rechts von der Uhr",
    ["compass_dir_n"] = "N",
    ["compass_dir_e"] = "O",
    ["compass_dir_s"] = "S",
    ["compass_dir_w"] = "W",
    ["msg_help_compass"] = "Kompassleiste umschalten",
    ["wn_305_compass"] = "Neue Kompassleiste (Waypoint 2.0): eine optionale Richtungsleiste am oberen Bildschirmrand, die beim Drehen die Himmelsrichtungen durchläuft, mit bernstein-/türkisfarbenen Markern in Richtung verfolgter Quest und Karten-Wegpunkt. Im Layout-Modus frei verschiebbar und unter Komfort > Kompass einstellbar.",
    -- [3.0.2] Changelog (What is New)
    ["wn_302_collector_capture"] = "Der Minimap-Button-Sammler ist deutlich zuverlässiger: Er erfasst nun Addon-Schaltflächen, die er zuvor übersehen hat - auch solche, die am Minimap-Ring schwebten oder beim Ziehen verschwanden.",
    ["wn_302_collector_clean"] = "Gesammelte Schaltflächen erhalten ein sauberes, einheitliches Aussehen: dekorative Ränder werden entfernt, Symbole normalisiert und die feste Ebenen-Sperre von LibDBIcon aufgehoben, damit jede Schaltfläche korrekt dargestellt wird.",
    ["wn_302_collector_poll"] = "Schaltflächen von spät ladenden Addons werden jetzt automatisch erkannt (kein manuelles Neuscannen nötig).",
    ["wn_302_native_choice"] = "Blizzards native Verfolgungsschaltfläche und das Addon-Fach sind nun standardmäßig ausgeblendet. Eine neue GUI-Option erlaubt dir, für beide zwischen der TomoMod- und der Blizzard-Version zu wählen.",
    -- [3.0.2] Minimap : style pistage + collecteur
    -- [3.0.1] Changelog (What is New)
    ["wn_301_locale_fix"] = "Behebt einen Absturz beim Laden der Lokalisierungsdatei, durch den viele Konfigurationsfenster Roh-Schlüssel anzeigten (Minimap, ButtonBag, Skins, Ressourcenleisten...) - alle Beschriftungen sind nun korrekt übersetzt.",
    ["wn_301_combat_movers"] = "Der Platzierungsmodus löst keine blockierten Aktionen mehr aus, wenn er im Kampf umgeschaltet wird: Er wird sauber abgelehnt, und falls der Kampf bei entsperrter Oberfläche beginnt, werden die Rahmen nach Kampfende automatisch wieder gesperrt.",
    ["wn_301_procglow_taint"] = "Behebt einen Taint-Fehler bei den Proc-Effekten des Cooldown-Managers, der durch den Vergleich eines geschützten Zauber-ID-Werts verursacht wurde.",
    ["wn_301_ground_speed"] = "Die Bodenbewegungsgeschwindigkeit wird jetzt standardmäßig auf der SkyRide-Leiste angezeigt (umschaltbar im SkyRide-Tab).",
    ["wn_301_buttonbag_clock"] = "Der Minimap-Button-Sammler kann nun links oder rechts neben der Uhr platziert werden, sodass er die Karte nicht mehr verdeckt.",
    -- [3.0.1] ButtonBag : ancrage horloge
    -- [3.0.1] Clés ajoutées (movers anti-combat + libellés de panels manquants)
    ["layout_combat_blocked"] = "Die Benutzeroberfläche kann im Kampf nicht verschoben werden.",
    ["btn_housing_leave"] = "Haus verlassen",
    ["mover_actionbars"] = "Aktionsleisten",
    ["wn_2921_waypoint_arrow"] = "Intelligenter Wegpunkt - Richtungspfeil: Ein Pfeil auf dem Bildschirm zeigt nun zum verfolgten Wegpunkt, mit Live-Entfernung, damit du immer weißt, wohin du musst.",
    ["gs_no_results"]           = "Keine passende Option",
    ["minimap_buttonbag"] = "Addon-Knöpfe",
    ["minimap_buttonbag_hint"] = "Klick: ein/aus",
    ["minimap_buttonbag_empty"] = "Keine Knöpfe erkannt",
    ["cr_preview_sample"] = "Beispiel: fehlender Klassen-Buff",
    ["section_cdm_preview"] = "Vorschau",
    ["info_cdm_preview"] = "Abklingzeitleisten zeigen nur Symbole, wenn Zauber tatsächlich abklingen. Um sie mit Beispielen zu sehen und zu positionieren, öffne Blizzards Bearbeitungsmodus.",
    ["section_rb_preview"] = "Vorschau",
    ["info_rb_preview"] = "Ressourcenleisten zeigen deine echte Ressource (Mana, Energie, Combopunkte…). Zum Positionieren mit Vorschau öffne Blizzards Bearbeitungsmodus oder entsperre sie im Reiter „Text“.",
    ["btn_open_editmode"] = "Bearbeitungsmodus öffnen",
    ["info_editmode_combat"] = "Der Bearbeitungsmodus kann im Kampf nicht geöffnet werden.",
})

-- =====================
-- esES
-- =====================
TomoMod_RegisterLocale("esES", {
    -- [3.0.5] Compass (Waypoint 2.0)
    ["mover_compass"] = "Brújula",
    ["ready_tracker_section"] = "Preparación de consumibles",
    ["ready_tracker_info"] = "Muestra Frasco, Bien alimentado y Aceite de fénix thalassiano bajo el minimapa, junto al reloj. El botón está disponible en todas partes; solo se pone verde o rojo en mazmorras, bandas, escenarios y simas.",
    ["ready_tracker_enable"] = "Activar seguimiento de consumibles",
    ["ready_tracker_button_side"] = "Posición del botón",
    ["ready_tracker_button_size"] = "Tamaño del botón",
    ["ready_tracker_tracker_size"] = "Tamaño del rastreador",
    ["ready_tracker_side_left"] = "A la izquierda del reloj",
    ["ready_tracker_side_right"] = "A la derecha del reloj",
    ["compass_dir_n"] = "N",
    ["compass_dir_e"] = "E",
    ["compass_dir_s"] = "S",
    ["compass_dir_w"] = "O",
    ["msg_help_compass"] = "Alternar la barra de brújula",
    ["wn_305_compass"] = "Nueva barra de Brújula (Waypoint 2.0): una barra de rumbo opcional en la parte superior de la pantalla que recorre los puntos cardinales al girar, con marcadores ámbar/turquesa que apuntan hacia tu misión seguida y un punto de mapa. Totalmente movible en modo Diseño y configurable en Calidad de vida > Brújula.",
    -- [3.0.2] Changelog (What is New)
    ["wn_302_collector_capture"] = "El recopilador de botones del minimapa es mucho más fiable: ahora captura botones de addons que antes se le escapaban, incluidos los que flotaban en el anillo del minimapa o desaparecían al arrastrarlos.",
    ["wn_302_collector_clean"] = "Los botones recopilados tienen un aspecto limpio y uniforme: se eliminan los bordes decorativos, se normalizan los iconos y se desbloquea el nivel fijo de LibDBIcon para que cada botón se muestre correctamente.",
    ["wn_302_collector_poll"] = "Los botones de addons que cargan tarde ahora se detectan automáticamente (sin necesidad de reescanear manualmente).",
    ["wn_302_native_choice"] = "El botón de rastreo nativo de Blizzard y el compartimento de addons ahora están ocultos por defecto. Una nueva opción del GUI permite elegir, para cada uno, entre la versión de TomoMod y la de Blizzard.",
    -- [3.0.2] Minimap : style pistage + collecteur
    -- [3.0.1] Changelog (What is New)
    ["wn_301_locale_fix"] = "Corregido un fallo al cargar el archivo de localización que dejaba muchos paneles de configuración mostrando claves sin traducir (Minimapa, ButtonBag, Skins, Barras de recursos...) - todas las etiquetas ahora se traducen correctamente.",
    ["wn_301_combat_movers"] = "El modo de colocación ya no provoca errores de acción bloqueada al activarlo en combate: se rechaza de forma segura, y si el combate empieza con la interfaz desbloqueada, los marcos se vuelven a bloquear automáticamente al terminar el combate.",
    ["wn_301_procglow_taint"] = "Corregido un error de taint en los destellos de proc del Gestor de reutilizaciones, causado por comparar un valor de ID de hechizo protegido.",
    ["wn_301_ground_speed"] = "La velocidad de movimiento en tierra ahora se muestra por defecto en la barra de SkyRide (se puede activar en la pestaña SkyRide).",
    ["wn_301_buttonbag_clock"] = "El recopilador de botones del minimapa ahora puede colocarse a la izquierda o a la derecha del reloj para no tapar el mapa.",
    -- [3.0.1] ButtonBag : ancrage horloge
    -- [3.0.1] Clés ajoutées (movers anti-combat + libellés de panels manquants)
    ["layout_combat_blocked"] = "No puedes mover la interfaz en combate.",
    ["btn_housing_leave"] = "Salir de la casa",
    ["mover_actionbars"] = "Barras de acción",
    ["wn_2921_waypoint_arrow"] = "Waypoint inteligente - flecha de dirección: una flecha en pantalla apunta ahora hacia el waypoint seguido, con distancia en tiempo real, para que siempre sepas hacia dónde ir.",
    ["gs_no_results"]           = "Ninguna opción coincidente",
    ["minimap_buttonbag"] = "Botones de addon",
    ["minimap_buttonbag_hint"] = "Clic: mostrar/ocultar",
    ["minimap_buttonbag_empty"] = "No se detectaron botones",
    ["cr_preview_sample"] = "Ejemplo: falta una mejora de clase",
    ["section_cdm_preview"] = "Vista previa",
    ["info_cdm_preview"] = "Las barras de reutilización solo muestran iconos cuando los hechizos están realmente en reutilización. Para verlas y colocarlas con ejemplos, abre el Modo Edición de Blizzard.",
    ["section_rb_preview"] = "Vista previa",
    ["info_rb_preview"] = "Las barras de recursos muestran tu recurso real (maná, energía, puntos de combo…). Para colocarlas con vista previa, abre el Modo Edición de Blizzard o desbloquéalas desde la pestaña Texto.",
    ["btn_open_editmode"] = "Abrir Modo Edición",
    ["info_editmode_combat"] = "El Modo Edición no se puede abrir en combate.",
})

-- =====================
-- itIT
-- =====================
TomoMod_RegisterLocale("itIT", {
    -- [3.0.5] Compass (Waypoint 2.0)
    ["mover_compass"] = "Bussola",
    ["ready_tracker_section"] = "Preparazione consumabili",
    ["ready_tracker_info"] = "Mostra Fiala, Ben nutrito e Olio di fenice thalassiano sotto la minimappa, accanto all'orologio. Il pulsante è disponibile ovunque; diventa verde o rosso solo in spedizioni, incursioni, scenari e cavità.",
    ["ready_tracker_enable"] = "Attiva monitor consumabili",
    ["ready_tracker_button_side"] = "Posizione del pulsante",
    ["ready_tracker_button_size"] = "Dimensione pulsante",
    ["ready_tracker_tracker_size"] = "Dimensione tracker",
    ["ready_tracker_side_left"] = "A sinistra dell'orologio",
    ["ready_tracker_side_right"] = "A destra dell'orologio",
    ["compass_dir_n"] = "N",
    ["compass_dir_e"] = "E",
    ["compass_dir_s"] = "S",
    ["compass_dir_w"] = "O",
    ["msg_help_compass"] = "Attiva/disattiva la barra bussola",
    ["wn_305_compass"] = "Nuova barra Bussola (Waypoint 2.0): una barra di direzione opzionale in alto sullo schermo che scorre i punti cardinali mentre ti giri, con indicatori ambra/turchese che puntano verso la missione tracciata e un punto sulla mappa. Completamente spostabile in modalità Layout e configurabile in Comfort di gioco > Bussola.",
    -- [3.0.2] Changelog (What is New)
    ["wn_302_collector_capture"] = "Il raccoglitore di pulsanti della minimappa è molto più affidabile: ora cattura pulsanti di addon che prima gli sfuggivano, compresi quelli che fluttuavano sull'anello della minimappa o sparivano quando li si trascinava.",
    ["wn_302_collector_clean"] = "I pulsanti raccolti hanno un aspetto pulito e uniforme: i bordi decorativi vengono rimossi, le icone normalizzate e il livello bloccato di LibDBIcon viene sbloccato perché ogni pulsante venga visualizzato correttamente.",
    ["wn_302_collector_poll"] = "I pulsanti degli addon che si caricano in ritardo ora vengono rilevati automaticamente (nessuna riscansione manuale necessaria).",
    ["wn_302_native_choice"] = "Il pulsante di tracciamento nativo di Blizzard e il vano addon ora sono nascosti per impostazione predefinita. Una nuova opzione del GUI permette di scegliere, per ciascuno, tra la versione TomoMod e quella di Blizzard.",
    -- [3.0.2] Minimap : style pistage + collecteur
    -- [3.0.1] Changelog (What is New)
    ["wn_301_locale_fix"] = "Corretto un crash al caricamento del file di localizzazione che lasciava molti pannelli di configurazione con chiavi grezze (Minimappa, ButtonBag, Skin, Barre delle risorse...) - tutte le etichette sono ora tradotte correttamente.",
    ["wn_301_combat_movers"] = "La modalità posizionamento non causa più errori di azione bloccata quando viene attivata in combattimento: viene rifiutata in modo sicuro e, se il combattimento inizia con l'interfaccia sbloccata, i riquadri si ribloccano automaticamente al termine del combattimento.",
    ["wn_301_procglow_taint"] = "Corretto un errore di taint sugli effetti proc del Gestore ricariche, causato dal confronto di un valore di ID incantesimo protetto.",
    ["wn_301_ground_speed"] = "La velocità di movimento a terra è ora mostrata per impostazione predefinita sulla barra SkyRide (attivabile nella scheda SkyRide).",
    ["wn_301_buttonbag_clock"] = "Il raccoglitore di pulsanti della minimappa ora può essere posizionato a sinistra o a destra dell'orologio per non coprire più la mappa.",
    -- [3.0.1] ButtonBag : ancrage horloge
    -- [3.0.1] Clés ajoutées (movers anti-combat + libellés de panels manquants)
    ["layout_combat_blocked"] = "Non puoi spostare l'interfaccia durante il combattimento.",
    ["btn_housing_leave"] = "Esci dalla casa",
    ["mover_actionbars"] = "Barre delle azioni",
    ["wn_2921_waypoint_arrow"] = "Waypoint intelligente - freccia direzionale: una freccia sullo schermo punta ora verso il waypoint seguito, con distanza in tempo reale, così sai sempre dove andare.",
    ["gs_no_results"]           = "Nessuna opzione corrispondente",
    ["minimap_buttonbag"] = "Pulsanti addon",
    ["minimap_buttonbag_hint"] = "Clic: mostra/nascondi",
    ["minimap_buttonbag_empty"] = "Nessun pulsante rilevato",
    ["cr_preview_sample"] = "Esempio: potenziamento di classe mancante",
    ["section_cdm_preview"] = "Anteprima",
    ["info_cdm_preview"] = "Le barre di ricarica mostrano le icone solo quando le abilità sono effettivamente in ricarica. Per vederle e posizionarle con esempi, apri la Modalità Modifica di Blizzard.",
    ["section_rb_preview"] = "Anteprima",
    ["info_rb_preview"] = "Le barre delle risorse mostrano la tua risorsa reale (mana, energia, punti combo…). Per posizionarle con un'anteprima, apri la Modalità Modifica di Blizzard o sbloccale dalla scheda Testo.",
    ["btn_open_editmode"] = "Apri Modalità Modifica",
    ["info_editmode_combat"] = "La Modalità Modifica non può essere aperta in combattimento.",
})

-- =====================
-- ptBR
-- =====================
TomoMod_RegisterLocale("ptBR", {
    -- [3.0.5] Compass (Waypoint 2.0)
    ["mover_compass"] = "Bússola",
    ["ready_tracker_section"] = "Preparação de consumíveis",
    ["ready_tracker_info"] = "Mostra Frasco, Bem alimentado e Óleo de fênix thalassiano abaixo do minimapa, ao lado do relógio. O botão está disponível em qualquer lugar; ele só fica verde ou vermelho em masmorras, raides, cenários e delves.",
    ["ready_tracker_enable"] = "Ativar rastreador de consumíveis",
    ["ready_tracker_button_side"] = "Posição do botão",
    ["ready_tracker_button_size"] = "Tamanho do botão",
    ["ready_tracker_tracker_size"] = "Tamanho do rastreador",
    ["ready_tracker_side_left"] = "À esquerda do relógio",
    ["ready_tracker_side_right"] = "À direita do relógio",
    ["compass_dir_n"] = "N",
    ["compass_dir_e"] = "L",
    ["compass_dir_s"] = "S",
    ["compass_dir_w"] = "O",
    ["msg_help_compass"] = "Alternar a barra de bússola",
    ["wn_305_compass"] = "Nova barra de Bússola (Waypoint 2.0): uma barra de direção opcional no topo da tela que percorre os pontos cardeais ao girar, com marcadores âmbar/turquesa apontando para sua missão rastreada e um ponto no mapa. Totalmente móvel no modo Layout e configurável em Qualidade de vida > Bússola.",
    -- [3.0.2] Changelog (What is New)
    ["wn_302_collector_capture"] = "O coletor de botões do minimapa é muito mais confiável: agora captura botões de addons que antes ele perdia, incluindo os que flutuavam no anel do minimapa ou sumiam ao serem arrastados.",
    ["wn_302_collector_clean"] = "Os botões coletados ganham um visual limpo e uniforme: bordas decorativas são removidas, ícones normalizados e a camada travada do LibDBIcon é destravada para que cada botão seja exibido corretamente.",
    ["wn_302_collector_poll"] = "Botões de addons que carregam tarde agora são detectados automaticamente (sem necessidade de reescanear manualmente).",
    ["wn_302_native_choice"] = "O botão de rastreamento nativo da Blizzard e o compartimento de addons agora ficam ocultos por padrão. Uma nova opção no GUI permite escolher, para cada um, entre a versão do TomoMod e a da Blizzard.",
    -- [3.0.2] Minimap : style pistage + collecteur
    -- [3.0.1] Changelog (What is New)
    ["wn_301_locale_fix"] = "Corrigida uma falha no carregamento do arquivo de localização que deixava vários painéis de configuração exibindo chaves brutas (Minimapa, ButtonBag, Skins, Barras de recursos...) - todos os rótulos agora são traduzidos corretamente.",
    ["wn_301_combat_movers"] = "O modo de posicionamento não causa mais erros de ação bloqueada ao ser alternado em combate: ele é recusado com segurança e, se o combate começar com a interface desbloqueada, os quadros são re-travados automaticamente ao fim do combate.",
    ["wn_301_procglow_taint"] = "Corrigido um erro de taint nos efeitos de proc do Gerenciador de recargas, causado pela comparação de um valor de ID de magia protegido.",
    ["wn_301_ground_speed"] = "A velocidade de movimento no solo agora é exibida por padrão na barra SkyRide (ativável na aba SkyRide).",
    ["wn_301_buttonbag_clock"] = "O coletor de botões do minimapa agora pode ser posicionado à esquerda ou à direita do relógio para não cobrir mais o mapa.",
    -- [3.0.1] ButtonBag : ancrage horloge
    -- [3.0.1] Clés ajoutées (movers anti-combat + libellés de panels manquants)
    ["layout_combat_blocked"] = "Não é possível mover a interface em combate.",
    ["btn_housing_leave"] = "Sair da casa",
    ["mover_actionbars"] = "Barras de ação",
    ["wn_2921_waypoint_arrow"] = "Waypoint inteligente - seta de direção: uma seta na tela agora aponta para o waypoint rastreado, com distância em tempo real, para você sempre saber para onde ir.",
    ["gs_no_results"]           = "Nenhuma opção correspondente",
    ["minimap_buttonbag"] = "Botões de addon",
    ["minimap_buttonbag_hint"] = "Clique: mostrar/ocultar",
    ["minimap_buttonbag_empty"] = "Nenhum botão detectado",
    ["cr_preview_sample"] = "Exemplo: bônus de classe ausente",
    ["section_cdm_preview"] = "Pré-visualização",
    ["info_cdm_preview"] = "As barras de recarga só mostram ícones quando as magias estão realmente em recarga. Para vê-las e posicioná-las com exemplos, abra o Modo de Edição da Blizzard.",
    ["section_rb_preview"] = "Pré-visualização",
    ["info_rb_preview"] = "As barras de recurso mostram seu recurso real (mana, energia, pontos de combo…). Para posicioná-las com pré-visualização, abra o Modo de Edição da Blizzard ou desbloqueie-as na aba Texto.",
    ["btn_open_editmode"] = "Abrir Modo de Edição",
    ["info_editmode_combat"] = "O Modo de Edição não pode ser aberto em combate.",
})

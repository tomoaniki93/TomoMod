-- =====================================================================
-- TomoMod AstralForge (A2) -- dedicated LoadOnDemand designer for unit
-- frame elements. Window chrome from Forge.Studio, element sidebar from
-- Forge.Registry, drag surface from Forge.Canvas, subject frame from the
-- SAME factories the live frames and the config preview use
-- (UFP.CreateStandalone -> UF.BuildVisuals).
--
-- The subject is a detached preview clone. Nothing here ever touches a
-- live oUF frame: those are protected in Midnight and dragging one would
-- taint it. Edits land in TomoModDB.unitFrames[unit].elements and are
-- pushed to the game frames through UF.RefreshUnit, which is gated on
-- combat by the engine itself.
-- =====================================================================

local W = TomoMod_Widgets
if not W then
    -- Nothing can be built without the widget kit. Publish a marker global
    -- so the launcher can report *why* the window never opened, instead of
    -- a click that silently does nothing.
    TomoMod_AstralForge = { loadError = "TomoMod_Widgets indisponible" }
    return
end

local Forge = TomoMod_Forge
if not (Forge and Forge.Registry and Forge.Canvas and Forge.Studio) then
    TomoMod_AstralForge = { loadError = "TomoMod_Forge incomplet" }
    return
end

local R   = Forge.Registry
local A   = Forge.Assets
local UFE = TomoMod_UFElements
if not UFE then
    TomoMod_AstralForge = { loadError = "registre UnitFrames indisponible" }
    return
end
local NPE = TomoMod_NPElements

-- ---------------------------------------------------------------------
-- Astral Forge Studio V2 - Frame Editor locales
-- Every new player-facing string added by this lot lives in all six
-- supported locales. enUS remains the fallback through TomoMod_L.
-- ---------------------------------------------------------------------
if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["af_frame_button"]           = "Frame",
        ["af_frame_title"]            = "Frame editor",
        ["af_frame_info"]             = "Edit the dimensions and core display of the selected Player, Target or Nameplate frame. Changes are applied live to the preview and the game frames.",
        ["af_frame_unavailable"]      = "Frame editing is available for Player, Target and Nameplates in this version. Select one of these subjects above.",
        ["af_frame_dimensions"]       = "Dimensions",
        ["af_frame_display"]          = "Display",
        ["af_frame_info_height"]      = "Info bar height",
        ["af_frame_cast_height"]      = "Cast bar height",
        ["af_frame_name_size"]        = "Name font size",
        ["af_frame_health_format"]    = "Health text format",
        ["af_frame_reset"]            = "Reset frame settings",
        ["af_frame_reset_done"]       = "Frame settings restored to TomoMod defaults.",
        ["af_frame_refresh"]          = "Refresh preview",
        ["af_fmt_current"]            = "Current",
        ["af_fmt_percent"]            = "Percent",
        ["af_fmt_current_percent"]    = "Current + percent",
        ["af_fmt_current_max"]        = "Current / maximum",
        ["af_bars_button"]             = "Bars",
        ["af_bars_title"]              = "Custom bars",
        ["af_bars_info"]               = "Create independent bars, then drag them directly in the preview like any other Forge element.",
        ["af_bars_unavailable"]        = "Custom bars are available for Player, Target and Nameplates in this version.",
        ["af_bars_add"]                = "+ New bar",
        ["af_bars_none"]               = "No custom bar has been created for this subject.",
        ["af_bars_count"]              = "%d / %d custom bars",
        ["af_bars_max"]                = "The maximum number of custom bars has been reached.",
        ["af_elem_custom_bar"]         = "Custom bar",
        ["af_bar_source"]              = "Data source",
        ["af_bar_source_health"]       = "Health",
        ["af_bar_source_power"]        = "Power",
        ["af_bar_source_static"]       = "Static / decorative",
        ["af_bar_width"]               = "Bar width",
        ["af_bar_height"]              = "Bar height",
        ["af_bar_style"]               = "Bar appearance",
        ["af_bar_color_mode"]          = "Bar color",
        ["af_bar_color_source"]        = "Follow source",
        ["af_bar_color_class"]         = "Class color",
        ["af_bar_color_custom"]        = "Custom color",
        ["af_bar_custom_color"]        = "Custom color",
        ["af_bar_background"]          = "Background opacity",
        ["af_bar_reverse"]             = "Reverse fill",
        ["af_studio_title"]            = "Astral Forge Studio",
        ["af_subject_label"]           = "Editing",
        ["af_sidebar_title"]           = "ELEMENTS",
        ["af_nav_frame"]               = "Frame",
        ["af_nav_elements"]            = "Elements",
        ["af_nav_bars"]                = "Bars",
        ["af_nav_presets"]             = "Presets",
        ["af_help"]                    = "Help",
        ["af_refresh"]                 = "Refresh preview",
        ["af_reset_all"]               = "Reset all elements",
        ["af_hint"]                    = "Drag an element to place it  •  Shift: free placement  •  Esc: close",
        ["af_select_element_help"]     = "Select an element in the list or click it directly in the preview.",
        ["af_tutorial_progress"]       = "Step %d / %d",
        ["af_tutorial_back"]           = "Back",
        ["af_tutorial_next"]           = "Next",
        ["af_tutorial_skip"]           = "Skip",
        ["af_tutorial_finish"]         = "Finish",
        ["af_tutorial_1_title"]        = "Welcome to Astral Forge Studio",
        ["af_tutorial_1_body"]         = "Astral Forge is the visual editor for TomoMod UnitFrames and Nameplates. Design the frame, move its elements and create your own bars without touching the protected live frame.",
        ["af_tutorial_2_title"]        = "Choose what you want to edit",
        ["af_tutorial_2_body"]         = "Use the subject selector to switch between Player, Target and Nameplates. Other supported Forge subjects remain available for element editing.",
        ["af_tutorial_3_title"]        = "Edit the frame itself",
        ["af_tutorial_3_body"]         = "The Frame tab controls the main dimensions and display of Player, Target and Nameplates. Changes are reflected immediately in the detached preview.",
        ["af_tutorial_4_title"]        = "Move elements directly",
        ["af_tutorial_4_body"]         = "The Elements tab is the visual canvas. Select an element in the sidebar or preview, then drag it. Hold Shift to temporarily disable snapping.",
        ["af_tutorial_5_title"]        = "Create your own bars",
        ["af_tutorial_5_body"]         = "The Bars tab creates independent Health, Power or decorative bars. Every bar becomes a normal Forge element that can be positioned and styled freely.",
        ["af_tutorial_6_title"]        = "Reuse your layouts",
        ["af_tutorial_6_body"]         = "Presets let you save, duplicate, export and restore Forge layouts. The Help button in the title bar can restart this guide at any time.",
    })
    TomoMod_RegisterLocale("frFR", {
        ["af_frame_button"]           = "Cadre",
        ["af_frame_title"]            = "Éditeur de cadre",
        ["af_frame_info"]             = "Modifie les dimensions et l'affichage principal du cadre Player, Target ou Nameplate sélectionné. Les changements sont appliqués en direct à l'aperçu et aux cadres en jeu.",
        ["af_frame_unavailable"]      = "L'édition du cadre est disponible pour Player, Target et Nameplates dans cette version. Sélectionne l'un de ces sujets ci-dessus.",
        ["af_frame_dimensions"]       = "Dimensions",
        ["af_frame_display"]          = "Affichage",
        ["af_frame_info_height"]      = "Hauteur de la barre d'informations",
        ["af_frame_cast_height"]      = "Hauteur de la barre d'incantation",
        ["af_frame_name_size"]        = "Taille du nom",
        ["af_frame_health_format"]    = "Format du texte de vie",
        ["af_frame_reset"]            = "Réinitialiser le cadre",
        ["af_frame_reset_done"]       = "Les réglages du cadre ont été restaurés aux valeurs TomoMod.",
        ["af_frame_refresh"]          = "Rafraîchir l\'aperçu",
        ["af_fmt_current"]            = "Actuel",
        ["af_fmt_percent"]            = "Pourcentage",
        ["af_fmt_current_percent"]    = "Actuel + pourcentage",
        ["af_fmt_current_max"]        = "Actuel / maximum",
        ["af_bars_button"]             = "Barres",
        ["af_bars_title"]              = "Barres personnalisées",
        ["af_bars_info"]               = "Crée des barres indépendantes puis déplace-les directement dans l'aperçu comme n'importe quel élément Forge.",
        ["af_bars_unavailable"]        = "Les barres personnalisées sont disponibles pour Player, Target et Nameplates dans cette version.",
        ["af_bars_add"]                = "+ Nouvelle barre",
        ["af_bars_none"]               = "Aucune barre personnalisée n'a encore été créée pour ce sujet.",
        ["af_bars_count"]              = "%d / %d barres personnalisées",
        ["af_bars_max"]                = "Le nombre maximal de barres personnalisées est atteint.",
        ["af_elem_custom_bar"]         = "Barre personnalisée",
        ["af_bar_source"]              = "Source de données",
        ["af_bar_source_health"]       = "Santé",
        ["af_bar_source_power"]        = "Puissance",
        ["af_bar_source_static"]       = "Statique / décorative",
        ["af_bar_width"]               = "Largeur de la barre",
        ["af_bar_height"]              = "Hauteur de la barre",
        ["af_bar_style"]               = "Apparence de la barre",
        ["af_bar_color_mode"]          = "Couleur de la barre",
        ["af_bar_color_source"]        = "Suivre la source",
        ["af_bar_color_class"]         = "Couleur de classe",
        ["af_bar_color_custom"]        = "Couleur personnalisée",
        ["af_bar_custom_color"]        = "Couleur personnalisée",
        ["af_bar_background"]          = "Opacité du fond",
        ["af_bar_reverse"]             = "Inverser le remplissage",
        ["af_studio_title"]            = "Astral Forge Studio",
        ["af_subject_label"]           = "Sujet édité",
        ["af_sidebar_title"]           = "ÉLÉMENTS",
        ["af_nav_frame"]               = "Cadre",
        ["af_nav_elements"]            = "Éléments",
        ["af_nav_bars"]                = "Barres",
        ["af_nav_presets"]             = "Presets",
        ["af_help"]                    = "Aide",
        ["af_refresh"]                 = "Rafraîchir l'aperçu",
        ["af_reset_all"]               = "Tout réinitialiser",
        ["af_hint"]                    = "Glisse un élément pour le placer  •  Maj : placement libre  •  Échap : fermer",
        ["af_select_element_help"]     = "Sélectionne un élément dans la liste ou clique-le directement dans l'aperçu.",
        ["af_tutorial_progress"]       = "Étape %d / %d",
        ["af_tutorial_back"]           = "Retour",
        ["af_tutorial_next"]           = "Suivant",
        ["af_tutorial_skip"]           = "Passer",
        ["af_tutorial_finish"]         = "Terminer",
        ["af_tutorial_1_title"]        = "Bienvenue dans Astral Forge Studio",
        ["af_tutorial_1_body"]         = "Astral Forge est l'éditeur visuel des UnitFrames et Nameplates de TomoMod. Modifie le cadre, déplace ses éléments et crée tes propres barres sans toucher directement aux frames protégées en jeu.",
        ["af_tutorial_2_title"]        = "Choisis ce que tu veux éditer",
        ["af_tutorial_2_body"]         = "Le sélecteur de sujet permet de passer rapidement de Player à Target ou aux Nameplates. Les autres sujets Forge restent disponibles pour l'édition de leurs éléments.",
        ["af_tutorial_3_title"]        = "Modifie le cadre lui-même",
        ["af_tutorial_3_body"]         = "L'onglet Cadre règle les dimensions et l'affichage principal de Player, Target et Nameplates. Les changements apparaissent immédiatement dans l'aperçu détaché.",
        ["af_tutorial_4_title"]        = "Déplace les éléments directement",
        ["af_tutorial_4_body"]         = "L'onglet Éléments est ton Canvas visuel. Sélectionne un élément dans la liste ou l'aperçu puis glisse-le. Maintiens Maj pour désactiver temporairement le magnétisme.",
        ["af_tutorial_5_title"]        = "Crée tes propres barres",
        ["af_tutorial_5_body"]         = "L'onglet Barres permet de créer des barres Santé, Puissance ou décoratives indépendantes. Chaque barre devient un élément Forge librement positionnable et personnalisable.",
        ["af_tutorial_6_title"]        = "Réutilise tes compositions",
        ["af_tutorial_6_body"]         = "Les Presets permettent de sauvegarder, dupliquer, exporter et restaurer tes compositions Forge. Le bouton Aide dans le titre permet de relancer ce guide à tout moment.",
    })
    TomoMod_RegisterLocale("deDE", {
        ["af_frame_button"]           = "Rahmen",
        ["af_frame_title"]            = "Rahmen-Editor",
        ["af_frame_info"]             = "Bearbeite Abmessungen und zentrale Anzeige des gewählten Spieler-, Ziel- oder Namensplaketten-Rahmens. Änderungen erscheinen sofort in Vorschau und Spiel.",
        ["af_frame_unavailable"]      = "Der Rahmen-Editor ist in dieser Version für Spieler, Ziel und Namensplaketten verfügbar. Wähle oben eines dieser Ziele.",
        ["af_frame_dimensions"]       = "Abmessungen",
        ["af_frame_display"]          = "Anzeige",
        ["af_frame_info_height"]      = "Höhe der Infoleiste",
        ["af_frame_cast_height"]      = "Höhe der Zauberleiste",
        ["af_frame_name_size"]        = "Schriftgröße des Namens",
        ["af_frame_health_format"]    = "Format des Gesundheitstexts",
        ["af_frame_reset"]            = "Rahmeneinstellungen zurücksetzen",
        ["af_frame_reset_done"]       = "Die Rahmeneinstellungen wurden auf die TomoMod-Standardwerte zurückgesetzt.",
        ["af_frame_refresh"]          = "Vorschau aktualisieren",
        ["af_fmt_current"]            = "Aktuell",
        ["af_fmt_percent"]            = "Prozent",
        ["af_fmt_current_percent"]    = "Aktuell + Prozent",
        ["af_fmt_current_max"]        = "Aktuell / Maximum",
        ["af_bars_button"]             = "Leisten",
        ["af_bars_title"]              = "Eigene Leisten",
        ["af_bars_info"]               = "Erstelle unabhängige Leisten und verschiebe sie wie jedes Forge-Element direkt in der Vorschau.",
        ["af_bars_unavailable"]        = "Eigene Leisten sind in dieser Version für Spieler, Ziel und Namensplaketten verfügbar.",
        ["af_bars_add"]                = "+ Neue Leiste",
        ["af_bars_none"]               = "Für dieses Ziel wurde noch keine eigene Leiste erstellt.",
        ["af_bars_count"]              = "%d / %d eigene Leisten",
        ["af_bars_max"]                = "Die maximale Anzahl eigener Leisten wurde erreicht.",
        ["af_elem_custom_bar"]         = "Eigene Leiste",
        ["af_bar_source"]              = "Datenquelle",
        ["af_bar_source_health"]       = "Gesundheit",
        ["af_bar_source_power"]        = "Ressource",
        ["af_bar_source_static"]       = "Statisch / dekorativ",
        ["af_bar_width"]               = "Leistenbreite",
        ["af_bar_height"]              = "Leistenhöhe",
        ["af_bar_style"]               = "Leistendarstellung",
        ["af_bar_color_mode"]          = "Leistenfarbe",
        ["af_bar_color_source"]        = "Quelle übernehmen",
        ["af_bar_color_class"]         = "Klassenfarbe",
        ["af_bar_color_custom"]        = "Eigene Farbe",
        ["af_bar_custom_color"]        = "Eigene Farbe",
        ["af_bar_background"]          = "Hintergrunddeckkraft",
        ["af_bar_reverse"]             = "Füllrichtung umkehren",
        ["af_studio_title"]            = "Astral Forge Studio",
        ["af_subject_label"]           = "Bearbeitet",
        ["af_sidebar_title"]           = "ELEMENTE",
        ["af_nav_frame"]               = "Rahmen",
        ["af_nav_elements"]            = "Elemente",
        ["af_nav_bars"]                = "Leisten",
        ["af_nav_presets"]             = "Presets",
        ["af_help"]                    = "Hilfe",
        ["af_refresh"]                 = "Vorschau aktualisieren",
        ["af_reset_all"]               = "Alle Elemente zurücksetzen",
        ["af_hint"]                    = "Element ziehen zum Platzieren  •  Umschalt: frei platzieren  •  Esc: schließen",
        ["af_select_element_help"]     = "Wähle ein Element in der Liste oder direkt in der Vorschau aus.",
        ["af_tutorial_progress"]       = "Schritt %d / %d",
        ["af_tutorial_back"]           = "Zurück",
        ["af_tutorial_next"]           = "Weiter",
        ["af_tutorial_skip"]           = "Überspringen",
        ["af_tutorial_finish"]         = "Fertig",
        ["af_tutorial_1_title"]        = "Willkommen im Astral Forge Studio",
        ["af_tutorial_1_body"]         = "Astral Forge ist der visuelle Editor für TomoMod-UnitFrames und Namensplaketten. Gestalte Rahmen, verschiebe Elemente und erstelle eigene Leisten ohne die geschützten Live-Rahmen direkt anzufassen.",
        ["af_tutorial_2_title"]        = "Wähle dein Bearbeitungsziel",
        ["af_tutorial_2_body"]         = "Mit der Zielauswahl wechselst du zwischen Spieler, Ziel und Namensplaketten. Weitere Forge-Ziele bleiben für die Elementbearbeitung verfügbar.",
        ["af_tutorial_3_title"]        = "Bearbeite den Rahmen selbst",
        ["af_tutorial_3_body"]         = "Der Reiter Rahmen steuert Abmessungen und Hauptanzeige von Spieler, Ziel und Namensplaketten. Änderungen erscheinen sofort in der getrennten Vorschau.",
        ["af_tutorial_4_title"]        = "Elemente direkt verschieben",
        ["af_tutorial_4_body"]         = "Elemente ist dein visueller Canvas. Wähle ein Element in Liste oder Vorschau und ziehe es. Halte Umschalt, um das Einrasten vorübergehend zu deaktivieren.",
        ["af_tutorial_5_title"]        = "Erstelle eigene Leisten",
        ["af_tutorial_5_body"]         = "Im Reiter Leisten kannst du unabhängige Gesundheits-, Ressourcen- oder dekorative Leisten erstellen. Jede Leiste ist ein frei positionierbares Forge-Element.",
        ["af_tutorial_6_title"]        = "Layouts wiederverwenden",
        ["af_tutorial_6_body"]         = "Presets speichern, duplizieren, exportieren und stellen Forge-Layouts wieder her. Mit Hilfe in der Titelleiste kannst du diese Einführung jederzeit neu starten.",
    })
    TomoMod_RegisterLocale("esES", {
        ["af_frame_button"]           = "Marco",
        ["af_frame_title"]            = "Editor de marco",
        ["af_frame_info"]             = "Edita las dimensiones y la visualización principal del marco de Jugador, Objetivo o Placa de nombre seleccionado. Los cambios se aplican en directo.",
        ["af_frame_unavailable"]      = "La edición de marcos está disponible para Jugador, Objetivo y Placas de nombre en esta versión. Selecciona uno de ellos arriba.",
        ["af_frame_dimensions"]       = "Dimensiones",
        ["af_frame_display"]          = "Visualización",
        ["af_frame_info_height"]      = "Altura de la barra de información",
        ["af_frame_cast_height"]      = "Altura de la barra de lanzamiento",
        ["af_frame_name_size"]        = "Tamaño del nombre",
        ["af_frame_health_format"]    = "Formato del texto de salud",
        ["af_frame_reset"]            = "Restablecer ajustes del marco",
        ["af_frame_reset_done"]       = "Los ajustes del marco se restauraron a los valores de TomoMod.",
        ["af_frame_refresh"]          = "Actualizar vista previa",
        ["af_fmt_current"]            = "Actual",
        ["af_fmt_percent"]            = "Porcentaje",
        ["af_fmt_current_percent"]    = "Actual + porcentaje",
        ["af_fmt_current_max"]        = "Actual / máximo",
        ["af_bars_button"]             = "Barras",
        ["af_bars_title"]              = "Barras personalizadas",
        ["af_bars_info"]               = "Crea barras independientes y arrástralas directamente en la vista previa como cualquier elemento Forge.",
        ["af_bars_unavailable"]        = "Las barras personalizadas están disponibles para Jugador, Objetivo y Placas de nombre en esta versión.",
        ["af_bars_add"]                = "+ Nueva barra",
        ["af_bars_none"]               = "Todavía no se ha creado ninguna barra personalizada para este sujeto.",
        ["af_bars_count"]              = "%d / %d barras personalizadas",
        ["af_bars_max"]                = "Se ha alcanzado el número máximo de barras personalizadas.",
        ["af_elem_custom_bar"]         = "Barra personalizada",
        ["af_bar_source"]              = "Fuente de datos",
        ["af_bar_source_health"]       = "Salud",
        ["af_bar_source_power"]        = "Recurso",
        ["af_bar_source_static"]       = "Estática / decorativa",
        ["af_bar_width"]               = "Ancho de la barra",
        ["af_bar_height"]              = "Alto de la barra",
        ["af_bar_style"]               = "Apariencia de la barra",
        ["af_bar_color_mode"]          = "Color de la barra",
        ["af_bar_color_source"]        = "Seguir la fuente",
        ["af_bar_color_class"]         = "Color de clase",
        ["af_bar_color_custom"]        = "Color personalizado",
        ["af_bar_custom_color"]        = "Color personalizado",
        ["af_bar_background"]          = "Opacidad del fondo",
        ["af_bar_reverse"]             = "Invertir relleno",
        ["af_studio_title"]            = "Astral Forge Studio",
        ["af_subject_label"]           = "Editando",
        ["af_sidebar_title"]           = "ELEMENTOS",
        ["af_nav_frame"]               = "Marco",
        ["af_nav_elements"]            = "Elementos",
        ["af_nav_bars"]                = "Barras",
        ["af_nav_presets"]             = "Presets",
        ["af_help"]                    = "Ayuda",
        ["af_refresh"]                 = "Actualizar vista previa",
        ["af_reset_all"]               = "Restablecer todos los elementos",
        ["af_hint"]                    = "Arrastra un elemento para colocarlo  •  Mayús: posición libre  •  Esc: cerrar",
        ["af_select_element_help"]     = "Selecciona un elemento de la lista o haz clic directamente en la vista previa.",
        ["af_tutorial_progress"]       = "Paso %d / %d",
        ["af_tutorial_back"]           = "Atrás",
        ["af_tutorial_next"]           = "Siguiente",
        ["af_tutorial_skip"]           = "Omitir",
        ["af_tutorial_finish"]         = "Terminar",
        ["af_tutorial_1_title"]        = "Bienvenido a Astral Forge Studio",
        ["af_tutorial_1_body"]         = "Astral Forge es el editor visual de UnitFrames y Placas de nombre de TomoMod. Diseña el marco, mueve sus elementos y crea tus propias barras sin manipular directamente los marcos protegidos.",
        ["af_tutorial_2_title"]        = "Elige lo que quieres editar",
        ["af_tutorial_2_body"]         = "El selector permite cambiar entre Jugador, Objetivo y Placas de nombre. Los demás sujetos Forge siguen disponibles para editar sus elementos.",
        ["af_tutorial_3_title"]        = "Edita el propio marco",
        ["af_tutorial_3_body"]         = "La pestaña Marco controla las dimensiones y la visualización principal de Jugador, Objetivo y Placas de nombre. Los cambios aparecen al instante en la vista previa.",
        ["af_tutorial_4_title"]        = "Mueve los elementos directamente",
        ["af_tutorial_4_body"]         = "Elementos es tu lienzo visual. Selecciona un elemento en la lista o vista previa y arrástralo. Mantén Mayús para desactivar temporalmente el ajuste.",
        ["af_tutorial_5_title"]        = "Crea tus propias barras",
        ["af_tutorial_5_body"]         = "Barras permite crear barras independientes de Salud, Recurso o decorativas. Cada barra se convierte en un elemento Forge que puedes colocar y personalizar libremente.",
        ["af_tutorial_6_title"]        = "Reutiliza tus diseños",
        ["af_tutorial_6_body"]         = "Los Presets permiten guardar, duplicar, exportar y restaurar diseños Forge. El botón Ayuda de la barra de título reinicia esta guía cuando quieras.",
    })
    TomoMod_RegisterLocale("itIT", {
        ["af_frame_button"]           = "Riquadro",
        ["af_frame_title"]            = "Editor del riquadro",
        ["af_frame_info"]             = "Modifica dimensioni e visualizzazione principale del riquadro Giocatore, Bersaglio o Nameplate selezionato. Le modifiche vengono applicate in tempo reale.",
        ["af_frame_unavailable"]      = "In questa versione l'editor del riquadro è disponibile per Giocatore, Bersaglio e Nameplate. Selezionane uno qui sopra.",
        ["af_frame_dimensions"]       = "Dimensioni",
        ["af_frame_display"]          = "Visualizzazione",
        ["af_frame_info_height"]      = "Altezza barra informazioni",
        ["af_frame_cast_height"]      = "Altezza barra di lancio",
        ["af_frame_name_size"]        = "Dimensione nome",
        ["af_frame_health_format"]    = "Formato testo salute",
        ["af_frame_reset"]            = "Ripristina impostazioni riquadro",
        ["af_frame_reset_done"]       = "Le impostazioni del riquadro sono state ripristinate ai valori TomoMod.",
        ["af_frame_refresh"]          = "Aggiorna anteprima",
        ["af_fmt_current"]            = "Attuale",
        ["af_fmt_percent"]            = "Percentuale",
        ["af_fmt_current_percent"]    = "Attuale + percentuale",
        ["af_fmt_current_max"]        = "Attuale / massimo",
        ["af_bars_button"]             = "Barre",
        ["af_bars_title"]              = "Barre personalizzate",
        ["af_bars_info"]               = "Crea barre indipendenti e trascinale direttamente nell'anteprima come qualsiasi elemento Forge.",
        ["af_bars_unavailable"]        = "Le barre personalizzate sono disponibili per Giocatore, Bersaglio e Nameplate in questa versione.",
        ["af_bars_add"]                = "+ Nuova barra",
        ["af_bars_none"]               = "Non è stata ancora creata alcuna barra personalizzata per questo soggetto.",
        ["af_bars_count"]              = "%d / %d barre personalizzate",
        ["af_bars_max"]                = "È stato raggiunto il numero massimo di barre personalizzate.",
        ["af_elem_custom_bar"]         = "Barra personalizzata",
        ["af_bar_source"]              = "Fonte dati",
        ["af_bar_source_health"]       = "Salute",
        ["af_bar_source_power"]        = "Risorsa",
        ["af_bar_source_static"]       = "Statica / decorativa",
        ["af_bar_width"]               = "Larghezza barra",
        ["af_bar_height"]              = "Altezza barra",
        ["af_bar_style"]               = "Aspetto barra",
        ["af_bar_color_mode"]          = "Colore barra",
        ["af_bar_color_source"]        = "Segui fonte",
        ["af_bar_color_class"]         = "Colore classe",
        ["af_bar_color_custom"]        = "Colore personalizzato",
        ["af_bar_custom_color"]        = "Colore personalizzato",
        ["af_bar_background"]          = "Opacità sfondo",
        ["af_bar_reverse"]             = "Inverti riempimento",
        ["af_studio_title"]            = "Astral Forge Studio",
        ["af_subject_label"]           = "Modifica",
        ["af_sidebar_title"]           = "ELEMENTI",
        ["af_nav_frame"]               = "Riquadro",
        ["af_nav_elements"]            = "Elementi",
        ["af_nav_bars"]                = "Barre",
        ["af_nav_presets"]             = "Preset",
        ["af_help"]                    = "Aiuto",
        ["af_refresh"]                 = "Aggiorna anteprima",
        ["af_reset_all"]               = "Ripristina tutti gli elementi",
        ["af_hint"]                    = "Trascina un elemento per posizionarlo  •  Maiusc: posizione libera  •  Esc: chiudi",
        ["af_select_element_help"]     = "Seleziona un elemento nell'elenco o fai clic direttamente nell'anteprima.",
        ["af_tutorial_progress"]       = "Passaggio %d / %d",
        ["af_tutorial_back"]           = "Indietro",
        ["af_tutorial_next"]           = "Avanti",
        ["af_tutorial_skip"]           = "Salta",
        ["af_tutorial_finish"]         = "Fine",
        ["af_tutorial_1_title"]        = "Benvenuto in Astral Forge Studio",
        ["af_tutorial_1_body"]         = "Astral Forge è l'editor visivo di UnitFrame e Nameplate di TomoMod. Progetta il riquadro, sposta gli elementi e crea barre personali senza manipolare direttamente i frame protetti.",
        ["af_tutorial_2_title"]        = "Scegli cosa modificare",
        ["af_tutorial_2_body"]         = "Il selettore permette di passare tra Giocatore, Bersaglio e Nameplate. Gli altri soggetti Forge restano disponibili per modificare i loro elementi.",
        ["af_tutorial_3_title"]        = "Modifica il riquadro",
        ["af_tutorial_3_body"]         = "La scheda Riquadro controlla dimensioni e visualizzazione principale di Giocatore, Bersaglio e Nameplate. Le modifiche appaiono subito nell'anteprima separata.",
        ["af_tutorial_4_title"]        = "Sposta gli elementi direttamente",
        ["af_tutorial_4_body"]         = "Elementi è il tuo canvas visivo. Seleziona un elemento nell'elenco o anteprima e trascinalo. Tieni Maiusc per disattivare temporaneamente l'aggancio.",
        ["af_tutorial_5_title"]        = "Crea le tue barre",
        ["af_tutorial_5_body"]         = "Barre permette di creare barre Salute, Risorsa o decorative indipendenti. Ogni barra diventa un elemento Forge liberamente posizionabile e personalizzabile.",
        ["af_tutorial_6_title"]        = "Riutilizza i layout",
        ["af_tutorial_6_body"]         = "I Preset consentono di salvare, duplicare, esportare e ripristinare i layout Forge. Il pulsante Aiuto nella barra del titolo riavvia questa guida in qualsiasi momento.",
    })
    TomoMod_RegisterLocale("ptBR", {
        ["af_frame_button"]           = "Quadro",
        ["af_frame_title"]            = "Editor de quadro",
        ["af_frame_info"]             = "Edite as dimensões e a exibição principal do quadro de Jogador, Alvo ou Placa de nome selecionado. As alterações são aplicadas ao vivo.",
        ["af_frame_unavailable"]      = "A edição de quadros está disponível para Jogador, Alvo e Placas de nome nesta versão. Selecione um deles acima.",
        ["af_frame_dimensions"]       = "Dimensões",
        ["af_frame_display"]          = "Exibição",
        ["af_frame_info_height"]      = "Altura da barra de informações",
        ["af_frame_cast_height"]      = "Altura da barra de lançamento",
        ["af_frame_name_size"]        = "Tamanho do nome",
        ["af_frame_health_format"]    = "Formato do texto de vida",
        ["af_frame_reset"]            = "Redefinir ajustes do quadro",
        ["af_frame_reset_done"]       = "Os ajustes do quadro foram restaurados aos padrões do TomoMod.",
        ["af_frame_refresh"]          = "Atualizar prévia",
        ["af_fmt_current"]            = "Atual",
        ["af_fmt_percent"]            = "Porcentagem",
        ["af_fmt_current_percent"]    = "Atual + porcentagem",
        ["af_fmt_current_max"]        = "Atual / máximo",
        ["af_bars_button"]             = "Barras",
        ["af_bars_title"]              = "Barras personalizadas",
        ["af_bars_info"]               = "Crie barras independentes e arraste-as diretamente na prévia como qualquer elemento Forge.",
        ["af_bars_unavailable"]        = "As barras personalizadas estão disponíveis para Jogador, Alvo e Placas de nome nesta versão.",
        ["af_bars_add"]                = "+ Nova barra",
        ["af_bars_none"]               = "Nenhuma barra personalizada foi criada para este assunto.",
        ["af_bars_count"]              = "%d / %d barras personalizadas",
        ["af_bars_max"]                = "O número máximo de barras personalizadas foi atingido.",
        ["af_elem_custom_bar"]         = "Barra personalizada",
        ["af_bar_source"]              = "Fonte de dados",
        ["af_bar_source_health"]       = "Vida",
        ["af_bar_source_power"]        = "Recurso",
        ["af_bar_source_static"]       = "Estática / decorativa",
        ["af_bar_width"]               = "Largura da barra",
        ["af_bar_height"]              = "Altura da barra",
        ["af_bar_style"]               = "Aparência da barra",
        ["af_bar_color_mode"]          = "Cor da barra",
        ["af_bar_color_source"]        = "Seguir a fonte",
        ["af_bar_color_class"]         = "Cor da classe",
        ["af_bar_color_custom"]        = "Cor personalizada",
        ["af_bar_custom_color"]        = "Cor personalizada",
        ["af_bar_background"]          = "Opacidade do fundo",
        ["af_bar_reverse"]             = "Inverter preenchimento",
        ["af_studio_title"]            = "Astral Forge Studio",
        ["af_subject_label"]           = "Editando",
        ["af_sidebar_title"]           = "ELEMENTOS",
        ["af_nav_frame"]               = "Quadro",
        ["af_nav_elements"]            = "Elementos",
        ["af_nav_bars"]                = "Barras",
        ["af_nav_presets"]             = "Predefinições",
        ["af_help"]                    = "Ajuda",
        ["af_refresh"]                 = "Atualizar prévia",
        ["af_reset_all"]               = "Redefinir todos os elementos",
        ["af_hint"]                    = "Arraste um elemento para posicioná-lo  •  Shift: posição livre  •  Esc: fechar",
        ["af_select_element_help"]     = "Selecione um elemento na lista ou clique diretamente na prévia.",
        ["af_tutorial_progress"]       = "Etapa %d / %d",
        ["af_tutorial_back"]           = "Voltar",
        ["af_tutorial_next"]           = "Próximo",
        ["af_tutorial_skip"]           = "Pular",
        ["af_tutorial_finish"]         = "Concluir",
        ["af_tutorial_1_title"]        = "Bem-vindo ao Astral Forge Studio",
        ["af_tutorial_1_body"]         = "Astral Forge é o editor visual das UnitFrames e Placas de nome do TomoMod. Crie o quadro, mova seus elementos e crie barras próprias sem manipular diretamente os quadros protegidos.",
        ["af_tutorial_2_title"]        = "Escolha o que deseja editar",
        ["af_tutorial_2_body"]         = "O seletor permite alternar entre Jogador, Alvo e Placas de nome. Os outros assuntos Forge continuam disponíveis para edição de seus elementos.",
        ["af_tutorial_3_title"]        = "Edite o próprio quadro",
        ["af_tutorial_3_body"]         = "A aba Quadro controla dimensões e exibição principal de Jogador, Alvo e Placas de nome. As alterações aparecem imediatamente na prévia destacada.",
        ["af_tutorial_4_title"]        = "Mova elementos diretamente",
        ["af_tutorial_4_body"]         = "Elementos é seu canvas visual. Selecione um elemento na lista ou prévia e arraste-o. Segure Shift para desativar temporariamente o encaixe.",
        ["af_tutorial_5_title"]        = "Crie suas próprias barras",
        ["af_tutorial_5_body"]         = "Barras permite criar barras independentes de Vida, Recurso ou decorativas. Cada barra se torna um elemento Forge livremente posicionável e personalizável.",
        ["af_tutorial_6_title"]        = "Reutilize seus layouts",
        ["af_tutorial_6_body"]         = "As Predefinições permitem salvar, duplicar, exportar e restaurar layouts Forge. O botão Ajuda na barra de título reinicia este guia a qualquer momento.",
    })
end

local S = { state = {
    subject = "player", element = nil, preset = nil, importText = "",
    showFrameEditor = false,
    showBars = false,
} }
TomoMod_AstralForge = S

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local BRAND     = { 0.18, 0.62, 0.85 }

local PANEL_W, PANEL_H = 1180, 780
local SIDE_W           = 230
local TITLE_H          = 52
local FOOTER_H         = 44
local STAGE_H          = 300

-- ---------------------------------------------------------------------
-- Sujets editables
-- ---------------------------------------------------------------------
-- Une table plutot qu'une chaine de « if ». Avant, ajouter un domaine
-- voulait dire toucher Registry(), Settings(), Apply() et
-- RebuildSubject(), quatre endroits qu'il fallait penser a garder
-- d'accord ; il en reste un seul, et chaque entree decrit tout ce que le
-- studio a besoin de savoir :
--
--   value    identifiant stable, aussi la valeur du menu deroulant
--   labelKey cle de locale. Les libelles etaient ecrits en francais en
--            dur : un client allemand ou espagnol lisait « Cible de la
--            cible » dans son menu. Les cles viennent du lot 2, elles
--            existent deja dans les six langues.
--   registry le module de descripteurs (UFE, NPE, CBE...)
--   settings ou vit la configuration dans TomoModDB
--   build    fabrique le sujet d'apercu sur la scene
--   apply    repousse vers les frames vivantes
-- ---------------------------------------------------------------------

local SUBJECTS = {
    { value = "player",       labelKey = "frame_player",
      registry = function() return TomoMod_UFElements end,
      settings = function() return TomoModDB.unitFrames and TomoModDB.unitFrames.player end },
    { value = "target",       labelKey = "frame_target",
      registry = function() return TomoMod_UFElements end,
      settings = function() return TomoModDB.unitFrames and TomoModDB.unitFrames.target end },
    { value = "focus",        labelKey = "frame_focus",
      registry = function() return TomoMod_UFElements end,
      settings = function() return TomoModDB.unitFrames and TomoModDB.unitFrames.focus end },
    { value = "pet",          labelKey = "frame_pet",
      registry = function() return TomoMod_UFElements end,
      settings = function() return TomoModDB.unitFrames and TomoModDB.unitFrames.pet end },
    { value = "targettarget", labelKey = "frame_targettarget",
      registry = function() return TomoMod_UFElements end,
      settings = function() return TomoModDB.unitFrames and TomoModDB.unitFrames.targettarget end },
    { value = "nameplate",    labelKey = "frame_nameplate",
      registry = function() return TomoMod_NPElements end,
      settings = function() return TomoModDB.nameplates end },
    { value = "castbar_player", labelKey = "frame_cast_player", castUnit = "player",
      registry = function() return TomoMod_CBElements end,
      settings = function() return TomoModDB.castbars and TomoModDB.castbars.player end },
    { value = "castbar_target", labelKey = "frame_cast_target", castUnit = "target",
      registry = function() return TomoMod_CBElements end,
      settings = function() return TomoModDB.castbars and TomoModDB.castbars.target end },
    { value = "castbar_focus",  labelKey = "frame_cast_focus",  castUnit = "focus",
      registry = function() return TomoMod_CBElements end,
      settings = function() return TomoModDB.castbars and TomoModDB.castbars.focus end },
    { value = "castbar_pet",    labelKey = "frame_cast_pet",    castUnit = "pet",
      registry = function() return TomoMod_CBElements end,
      settings = function() return TomoModDB.castbars and TomoModDB.castbars.pet end },
    { value = "castbar_boss",   labelKey = "frame_cast_boss",   castUnit = "boss",
      registry = function() return TomoMod_CBElements end,
      settings = function() return TomoModDB.castbars and TomoModDB.castbars.boss end },
}

local SUBJECT_BY_VALUE = {}
for _, sub in ipairs(SUBJECTS) do SUBJECT_BY_VALUE[sub.value] = sub end

local NAMEPLATE = "nameplate"

local function Subject()
    return SUBJECT_BY_VALUE[S.state.subject] or SUBJECTS[1]
end

local function IsPlate()
    return S.state.subject == NAMEPLATE
end

local function Registry()
    local sub = Subject()
    return sub and sub.registry()
end

-- Le menu deroulant lit les libelles a l'ouverture, pas au chargement du
-- fichier : TomoMod_L n'est pas encore garni quand ce fichier s'execute.
local function BuildSubjectOptions()
    local out = {}
    for i, sub in ipairs(SUBJECTS) do
        local text = TomoMod_L and TomoMod_L[sub.labelKey]
        if not text or text == sub.labelKey then text = sub.value end
        out[i] = { value = sub.value, text = text }
    end
    return out
end

local L = TomoMod_L

local frame, sidebarList, contentHost
local canvas, stageHost, inspectorHost, subject, plateSubjectBase
local navigationHost, selectorHighlightHost
local rowButtons = {}
local navButtons = {}
local tutorialUI
local TUTORIAL_VERSION = 1

-- ---------------------------------------------------------------------
-- Data access
-- ---------------------------------------------------------------------
local function Settings()
    if not TomoModDB then return nil end
    local sub = Subject()
    if not sub then return nil end
    local ok, s = pcall(sub.settings)
    return ok and s or nil
end

local function Store()
    local s   = Settings()
    local reg = Registry()
    if not (s and reg) then return nil end
    if type(s.elements) ~= "table" then s.elements = {} end
    reg.Ensure(s.elements)
    return s.elements
end

-- Push to the live frames AND to the config panel preview, so closing the
-- studio never reveals a frame that disagrees with what was just designed.
local function Apply()
    local sub = Subject()
    if not sub then return end

    if sub.castUnit then
        local CB = TomoMod_Castbar
        if CB and CB.ApplySettings then CB.ApplySettings() end
        return
    end
    if sub.value == NAMEPLATE then
        local NP = TomoMod_Nameplates
        if NP and NP.RefreshAll then NP.RefreshAll() end
        return
    end
    local UF = TomoMod_UnitFrames
    if UF and UF.RefreshUnit then UF.RefreshUnit(sub.value) end
    if TomoMod_UFPreview and TomoMod_UFPreview.Refresh then
        TomoMod_UFPreview.Refresh()
    end
end

-- ---------------------------------------------------------------------
-- Stage: the detached subject frame
-- ---------------------------------------------------------------------
-- Les frames WoW ne se detruisent pas : la plaque d'apercu precedente part
-- dans un bac cache, comme le fait UFPreview pour les cadres d'unite.
local plateBin

local function RebuildSubject()
    if not (canvas and stageHost) then return end
    local reg = Registry()
    if not reg then return end

    if reg.CreatePreview then
        -- Domaine qui fabrique son propre sujet de scene (castbars).
        local sub = Subject()
        local bar = reg.CreatePreview(canvas.stage, sub and sub.castUnit, { recycle = subject })
        if not bar then return end
        subject = bar
        bar:ClearAllPoints()
        bar:SetPoint("CENTER", canvas.stage, "CENTER", 0, 0)
        bar:Show()
    elseif IsPlate() then
        local NP = TomoMod_Nameplates
        if not (NP and NP.CreatePreviewPlate) then return end
        if not plateBin then
            plateBin = CreateFrame("Frame")
            plateBin:Hide()
        end
        if plateSubjectBase then
            plateSubjectBase:Hide()
            plateSubjectBase:ClearAllPoints()
            plateSubjectBase:SetParent(plateBin)
        end
        local plate, base = NP.CreatePreviewPlate(canvas.stage)
        if not plate then return end
        subject, plateSubjectBase = plate, base
        base:ClearAllPoints()
        base:SetPoint("CENTER", canvas.stage, "CENTER", 0, 0)
        base:Show()
        plate:Show()
    else
        local UFP = TomoMod_UFPreview
        if not (UFP and UFP.CreateStandalone) then return end
        subject = UFP.CreateStandalone(canvas.stage, S.state.subject, { recycle = subject })
        if not subject then return end
        subject:ClearAllPoints()
        subject:SetPoint("CENTER", canvas.stage, "CENTER", 0, 0)
        subject:Show()
    end

    local store = Store()
    if store then
        reg.ApplyAll(subject, store)
        -- Detached previews deliberately use demonstration values; no unit
        -- API is read by the Studio itself.
        if reg.RefreshCustomBars then
            reg.RefreshCustomBars(subject, store, true)
        end
    end
    canvas:SetSubject(subject, store, reg.DOMAIN)
end

-- ---------------------------------------------------------------------
-- Sidebar: element list
-- ---------------------------------------------------------------------
function S.RebuildSidebar()
    for _, b in ipairs(rowButtons) do b:Hide() end
    if not sidebarList then return end

    local store = Store()
    local rows = {}
    for _, desc in ipairs(Registry().List()) do
        rows[#rows + 1] = { key = desc.id, labelKey = desc.labelKey }
    end
    -- Les elements instancies viennent apres les elements fixes, numerotes
    -- pour qu'on distingue « Texte personnalise 1 » de « ... 2 ».
    for _, inst in ipairs(R.ListInstances(Registry().DOMAIN, store)) do
        rows[#rows + 1] = {
            key      = inst.key,
            labelKey = inst.desc.labelKey,
            suffix   = " " .. inst.index,
        }
    end

    local y = -4
    local i = 0
    for _, row in ipairs(rows) do
        i = i + 1
        local b = rowButtons[i]
        if not b then
            b = CreateFrame("Button", nil, sidebarList, "BackdropTemplate")
            b:SetHeight(24)
            b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
            b._txt = b:CreateFontString(nil, "OVERLAY")
            b._txt:SetFont(FONT, 11, "")
            b._txt:SetPoint("LEFT", 10, 0)
            rowButtons[i] = b
        end
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", 6, y)
        b:SetPoint("TOPRIGHT", -6, y)

        local selected = (S.state.element == row.key)
        b:SetBackdropColor(BRAND[1], BRAND[2], BRAND[3], selected and 0.22 or 0)
        b._txt:SetText(L[row.labelKey] .. (row.suffix or ""))
        b._txt:SetTextColor(selected and 1 or 0.72, selected and 1 or 0.74, selected and 1 or 0.78, 1)

        local id = row.key
        b:SetScript("OnClick", function() S.SelectElement(id) end)
        b:Show()
        y = y - 26
    end
end

-- ---------------------------------------------------------------------
-- Frame Editor V2
-- ---------------------------------------------------------------------
-- This is intentionally limited to the three subjects requested for the
-- first frame-editing lot. Other subjects keep their existing element
-- editor until their own frame-level model is defined.
local FRAME_EDITOR_SUBJECTS = {
    player = true,
    target = true,
    nameplate = true,
}

local UNIT_FRAME_FIELDS = {
    "width", "healthHeight", "powerHeight", "infoBarHeight",
    "showName", "showLevel", "showHealthText", "healthTextFormat",
    "useClassColor", "showAbsorb", "showThreat",
}

local NAMEPLATE_FRAME_FIELDS = {
    "width", "height", "castbarHeight", "nameFontSize",
    "showName", "showLevel", "showHealthText", "healthTextFormat",
    "showClassification", "showCastbar", "useClassColors",
}

local function FrameEditorSupported()
    return FRAME_EDITOR_SUBJECTS[S.state.subject] == true
end

local function SyncLegacyUnitHeight(db)
    -- Keep the same compatibility field written by the normal UnitFrames
    -- dimensions panel. The live factory itself uses the explicit heights.
    db.height = (db.healthHeight or 38) + (db.powerHeight or 0) + 6
end

local function CommitFrameEdit()
    -- Same DB, same runtime refresh path as the ordinary config panels.
    Apply()
    RebuildSubject()
end

local function ResetFrameFields(db)
    local defaults
    local fields
    if IsPlate() then
        defaults = TomoMod_Defaults and TomoMod_Defaults.nameplates
        fields = NAMEPLATE_FRAME_FIELDS
    else
        defaults = TomoMod_Defaults and TomoMod_Defaults.unitFrames
            and TomoMod_Defaults.unitFrames[S.state.subject]
        fields = UNIT_FRAME_FIELDS
    end
    if not defaults then return false end

    for _, key in ipairs(fields) do
        if defaults[key] ~= nil then
            db[key] = defaults[key]
        end
    end
    if not IsPlate() then SyncLegacyUnitHeight(db) end
    return true
end

function S.BuildFrameEditor(c)
    local db = Settings()
    local y = -8

    local _, ny = W.CreateSectionHeader(c, L["af_frame_title"], y, "F")
    y = ny
    local _, ny = W.CreateInfoText(c, L["af_frame_info"], y)
    y = ny

    if not (db and FrameEditorSupported()) then
        local _, ny = W.CreateInfoText(c, L["af_frame_unavailable"], y)
        y = ny
        c:SetHeight(math.abs(y) + 40)
        return
    end

    local _, ny = W.CreateSubLabel(c, L["af_frame_dimensions"], y)
    y = ny

    if IsPlate() then
        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_width"], db.width or 156,
                    60, 300, 5, 0, function(v)
                        db.width = v
                        CommitFrameEdit()
                    end)
                return n
            end,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_health_height"], db.height or 17,
                    6, 40, 1, 0, function(v)
                        db.height = v
                        CommitFrameEdit()
                    end)
                return n
            end)
        y = ny

        if db.castbarHeight ~= nil then
            local _, ny = W.CreateSlider(c, L["af_frame_cast_height"],
                db.castbarHeight or 5, 3, 24, 1, y, function(v)
                    db.castbarHeight = v
                    CommitFrameEdit()
                end)
            y = ny
        end

        local _, ny = W.CreateSlider(c, L["af_frame_name_size"],
            db.nameFontSize or 11, 6, 20, 1, y, function(v)
                db.nameFontSize = v
                CommitFrameEdit()
            end)
        y = ny
    else
        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_width"], db.width or 220,
                    80, 400, 5, 0, function(v)
                        db.width = v
                        CommitFrameEdit()
                    end)
                return n
            end,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_health_height"], db.healthHeight or 38,
                    10, 80, 2, 0, function(v)
                        db.healthHeight = v
                        SyncLegacyUnitHeight(db)
                        CommitFrameEdit()
                    end)
                return n
            end)
        y = ny

        if db.powerHeight ~= nil then
            local _, ny = W.CreateSlider(c, L["opt_power_height"], db.powerHeight or 0,
                0, 20, 1, y, function(v)
                    db.powerHeight = v
                    SyncLegacyUnitHeight(db)
                    CommitFrameEdit()
                end)
            y = ny
        end

        if db.infoBarHeight ~= nil then
            local _, ny = W.CreateSlider(c, L["af_frame_info_height"],
                db.infoBarHeight or 0, 0, 30, 1, y, function(v)
                    db.infoBarHeight = v
                    CommitFrameEdit()
                end)
            y = ny
        end
    end

    local _, ny = W.CreateSubLabel(c, L["af_frame_display"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_name"], db.showName ~= false, y, function(v)
        db.showName = v
        CommitFrameEdit()
    end)
    y = ny

    if db.showLevel ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_level"], db.showLevel ~= false, y, function(v)
            db.showLevel = v
            CommitFrameEdit()
        end)
        y = ny
    end

    if db.showHealthText ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_health_text"], db.showHealthText ~= false, y, function(v)
            db.showHealthText = v
            CommitFrameEdit()
        end)
        y = ny
    end

    if db.healthTextFormat ~= nil then
        local formats = {
            { text = L["af_fmt_current"],         value = "current" },
            { text = L["af_fmt_percent"],         value = "percent" },
            { text = L["af_fmt_current_percent"], value = "current_percent" },
        }
        if not IsPlate() then
            formats[#formats + 1] = {
                text = L["af_fmt_current_max"], value = "current_max",
            }
        end
        local _, ny = W.CreateDropdown(c, L["af_frame_health_format"],
            formats, db.healthTextFormat, y, function(v)
                db.healthTextFormat = v
                CommitFrameEdit()
            end)
        y = ny
    end

    if IsPlate() then
        if db.showClassification ~= nil then
            local _, ny = W.CreateCheckbox(c, L["opt_np_show_classification"],
                db.showClassification ~= false, y, function(v)
                    db.showClassification = v
                    CommitFrameEdit()
                end)
            y = ny
        end

        if db.showCastbar ~= nil then
            local _, ny = W.CreateCheckbox(c, L["opt_np_show_castbar"],
                db.showCastbar ~= false, y, function(v)
                    db.showCastbar = v
                    CommitFrameEdit()
                end)
            y = ny
        end

        if db.useClassColors ~= nil then
            local _, ny = W.CreateCheckbox(c, L["opt_np_class_colors"],
                db.useClassColors ~= false, y, function(v)
                    db.useClassColors = v
                    CommitFrameEdit()
                end)
            y = ny
        end
    else
        if db.useClassColor ~= nil then
            local _, ny = W.CreateCheckbox(c, L["opt_class_color_uf"],
                db.useClassColor ~= false, y, function(v)
                    db.useClassColor = v
                    CommitFrameEdit()
                end)
            y = ny
        end

        if db.showAbsorb ~= nil then
            local _, ny = W.CreateCheckbox(c, L["opt_show_absorb"],
                db.showAbsorb ~= false, y, function(v)
                    db.showAbsorb = v
                    CommitFrameEdit()
                end)
            y = ny
        end

        if db.showThreat ~= nil then
            local _, ny = W.CreateCheckbox(c, L["opt_show_threat"],
                db.showThreat ~= false, y, function(v)
                    db.showThreat = v
                    CommitFrameEdit()
                end)
            y = ny
        end
    end

    local _, ny = W.CreateButton(c, L["af_frame_reset"], 240, y, function()
        if ResetFrameFields(db) then
            CommitFrameEdit()
            print("|cff2e9dd8TomoMod|r : " .. L["af_frame_reset_done"])
            S.RebuildInspector()
        end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
end

-- ---------------------------------------------------------------------
-- Custom Bars manager
-- ---------------------------------------------------------------------
local BAR_SUBJECTS = {
    player = true,
    target = true,
    nameplate = true,
}

function S.BuildBarsPanel(c)
    local y = -8
    local _, ny = W.CreateSectionHeader(c, L["af_bars_title"], y, "B")
    y = ny
    local _, ny = W.CreateInfoText(c, L["af_bars_info"], y)
    y = ny

    if not BAR_SUBJECTS[S.state.subject] then
        local _, ny = W.CreateInfoText(c, L["af_bars_unavailable"], y)
        y = ny
        c:SetHeight(math.abs(y) + 40)
        return
    end

    local reg = Registry()
    local store = Store()
    local dom = reg and reg.DOMAIN
    local barType = dom and R.GetType(dom, "customBar")
    if not (store and barType) then
        local _, ny = W.CreateInfoText(c, L["af_bars_unavailable"], y)
        y = ny
        c:SetHeight(math.abs(y) + 40)
        return
    end

    local count = R.CountInstances(dom, store, "customBar")
    local _, ny = W.CreateInfoText(c,
        string.format(L["af_bars_count"], count, barType.max or 0), y)
    y = ny

    local _, ny = W.CreateButton(c, L["af_bars_add"], 240, y, function()
        local key, why = R.AddInstance(dom, store, "customBar")
        if not key then
            if why == "max" then
                print("|cff2e9dd8TomoMod|r " .. L["af_bars_max"])
            end
            return
        end
        S.state.showBars = false
        S.state.element = key
        Apply()
        RebuildSubject()
        S.RebuildSidebar()
        if canvas and canvas.Select then canvas:Select(key) end
        S.RebuildInspector()
    end)
    y = ny

    local found = false
    for _, inst in ipairs(R.ListInstances(dom, store)) do
        if inst.typeID == "customBar" then
            found = true
            local label = L["af_elem_custom_bar"] .. " " .. inst.index
            local key = inst.key
            local _, ny = W.CreateButton(c, label, 240, y, function()
                S.state.showBars = false
                S.SelectElement(key)
            end)
            y = ny
        end
    end

    if not found then
        local _, ny = W.CreateInfoText(c, L["af_bars_none"], y)
        y = ny
    end

    c:SetHeight(math.abs(y) + 40)
end

-- ---------------------------------------------------------------------
-- Inspector: the selected element's anchor record
-- ---------------------------------------------------------------------
function S.RebuildInspector()
    if not inspectorHost then return end

    -- Les frames WoW ne se detruisent pas : le panneau precedent part dans
    -- un bac cache, comme dans le Cooldown Studio. Le bac doit exister AVANT
    -- le reparentage, sinon le premier rebuild reparente vers nil.
    if not inspectorHost._bin then
        local bin = CreateFrame("Frame", nil, inspectorHost)
        bin:Hide()
        inspectorHost._bin = bin
    end
    if inspectorHost._scroll then
        inspectorHost._scroll:Hide()
        inspectorHost._scroll:ClearAllPoints()
        inspectorHost._scroll:SetParent(inspectorHost._bin)
    end

    local scroll = W.CreateScrollPanel(inspectorHost)
    inspectorHost._scroll = scroll
    local c = scroll.child
    local y = -8

    local store = Store()

    if S.state.showFrameEditor then
        S.BuildFrameEditor(c)
        return
    end

    if S.state.showBars then
        S.BuildBarsPanel(c)
        return
    end

    -- Panneau presets : occupe l'inspecteur quand il est ouvert, plutot que
    -- d'ajouter une troisieme colonne dans une fenetre deja dense.
    if S.state.showPresets then
        S.BuildPresetPanel(c, store)
        return
    end

    local id = S.state.element
    if not id or not store then
        W.CreateInfoText(c, L["af_select_element_help"], y)
        return
    end

    local dom  = Registry().DOMAIN
    local desc = R.Describe(dom, id)
    local cfg  = store[id]
    if not (desc and cfg) then return end

    local _, index = R.SplitKey(id)
    local _, ny = W.CreateSectionHeader(c,
        L[desc.labelKey] .. (index and (" " .. index) or ""), y, "A")
    y = ny

    -- Modele de texte : reserve aux elements instancies.
    if desc.instanced and desc.id == "customText" then
        -- Le widget ne pre-remplit pas : on pose le texte courant a la main,
        -- sinon le champ apparaitrait vide et le premier caractere ecraserait
        -- le modele existant.
        local box, ny = W.CreateMultiLineEditBox(c, L["opt_custom_text_template"], 24, y, {
            onTextChanged = function(t)
                cfg.text = t
                Apply()
                if TomoMod_UFElements and TomoMod_UFElements.RefreshCustomTexts then
                    TomoMod_UFElements.RefreshCustomTexts(subject, store)
                end
            end,
        })
        y = ny
        if box and box.editBox and box.editBox.SetText then
            box.editBox:SetText(cfg.text or "")
        end

        local tokens = {}
        for _, t in ipairs(TomoMod_UFElements.TOKENS or {}) do
            tokens[#tokens + 1] = "[" .. t.token .. "]"
        end
        local _, ny = W.CreateInfoText(c,
            L["info_custom_text_tokens"] .. " " .. table.concat(tokens, "  "), y)
        y = ny
    end

    if desc.instanced and desc.id == "customBar" then
        local sourceOpts = {
            { text = L["af_bar_source_health"], value = "health" },
        }
        if not IsPlate() then
            sourceOpts[#sourceOpts + 1] = {
                text = L["af_bar_source_power"], value = "power"
            }
        end
        sourceOpts[#sourceOpts + 1] = {
            text = L["af_bar_source_static"], value = "static"
        }

        local _, ny = W.CreateDropdown(c, L["af_bar_source"],
            sourceOpts, cfg.source or "health", y, function(v)
                cfg.source = v
                Apply(); RebuildSubject(); S.RebuildInspector()
            end)
        y = ny

        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                local _, n = W.CreateSlider(col, L["af_bar_width"],
                    cfg.width or 180, 20, 500, 5, 0, function(v)
                        cfg.width = v
                        Apply(); RebuildSubject()
                    end)
                return n
            end,
            function(col)
                local _, n = W.CreateSlider(col, L["af_bar_height"],
                    cfg.height or 10, 2, 80, 1, 0, function(v)
                        cfg.height = v
                        Apply(); RebuildSubject()
                    end)
                return n
            end)
        y = ny

        local _, ny = W.CreateSubLabel(c, L["af_bar_style"], y)
        y = ny

        local colorOpts = {
            { text = L["af_bar_color_source"], value = "source" },
            { text = L["af_bar_color_class"],  value = "class" },
            { text = L["af_bar_color_custom"], value = "custom" },
        }
        local _, ny = W.CreateDropdown(c, L["af_bar_color_mode"],
            colorOpts, cfg.colorMode or "source", y, function(v)
                cfg.colorMode = v
                Apply(); RebuildSubject(); S.RebuildInspector()
            end)
        y = ny

        if cfg.colorMode == "custom" then
            local _, ny = W.CreateColorPicker(c, L["af_bar_custom_color"],
                cfg.color or { r = 0.18, g = 0.62, b = 0.85 }, y,
                function(r, g, b)
                    cfg.color = cfg.color or {}
                    cfg.color.r, cfg.color.g, cfg.color.b = r, g, b
                    Apply(); RebuildSubject()
                end)
            y = ny
        end

        local _, ny = W.CreateSlider(c, L["af_bar_background"],
            (cfg.backgroundAlpha or 0.35) * 100, 0, 100, 5, y, function(v)
                cfg.backgroundAlpha = v / 100
                Apply(); RebuildSubject()
            end)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["af_bar_reverse"],
            cfg.reverse == true, y, function(v)
                cfg.reverse = v
                Apply(); RebuildSubject()
            end)
        y = ny
    end

    -- Point de l'element
    local pointOpts = {}
    for _, p in ipairs(R.POINTS) do pointOpts[#pointOpts + 1] = { text = p, value = p } end

    local _, ny = W.CreateDropdown(c, "Point de l'element", pointOpts, cfg.point, y, function(v)
        cfg.point = v
        Apply(); RebuildSubject(); S.RebuildInspector()
    end)
    y = ny

    -- Cible d'ancrage : structures (barre de vie, cadre...) ET elements
    -- freres. Le registre filtre deja la liste blanche statique et toute
    -- option qui fermerait une boucle, donc ce qui est propose est
    -- toujours applicable -- l'interface ne peut pas creer de cycle.
    local targetOpts = {}
    for _, t in ipairs(R.AllowedTargets(Registry().DOMAIN, id, store)) do
        local prefix = (t.kind == "host") and L["target_kind_host"] or L["target_kind_element"]
        targetOpts[#targetOpts + 1] = { text = prefix .. L[t.labelKey], value = t.id }
    end
    -- La cible courante peut ne plus figurer dans la liste (donnees
    -- importees) : on l'ajoute pour que le menu affiche l'etat reel plutot
    -- qu'une valeur vide.
    local present = false
    for _, o in ipairs(targetOpts) do
        if o.value == cfg.relTo then present = true break end
    end
    if not present then
        targetOpts[#targetOpts + 1] = { text = cfg.relTo, value = cfg.relTo }
    end

    local _, ny = W.CreateDropdown(c, "Ancre sur", targetOpts, cfg.relTo, y, function(v)
        cfg.relTo = v
        Apply(); RebuildSubject(); S.RebuildInspector()
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, "Point de la cible", pointOpts, cfg.relPoint, y, function(v)
        cfg.relPoint = v
        Apply(); RebuildSubject(); S.RebuildInspector()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Decalage X", cfg.x, -300, 300, 1, y, function(v)
        cfg.x = v
        Apply(); RebuildSubject()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Decalage Y", cfg.y, -300, 300, 1, y, function(v)
        cfg.y = v
        Apply(); RebuildSubject()
    end)
    y = ny

    -- ── Proprietes visuelles ────────────────────────────────────────
    -- Le registre ne propose que ce que le TYPE de widget sait honorer :
    -- pas d'echelle sur une chaine de texte, pas de taille de police sur
    -- une texture. Couleur, visibilite et taille restent pilotees par les
    -- modules, qui les recalculent en permanence.
    local props = R.Props(Registry().DOMAIN, id)
    if #props > 0 then
        local _, ny = W.CreateSubLabel(c, L["sublabel_element_props"], y)
        y = ny

        for _, prop in ipairs(props) do
            if prop == "alpha" then
                local _, n = W.CreateSlider(c, L["opt_element_alpha"],
                    (cfg.alpha or 1) * 100, 0, 100, 1, y, function(v)
                        cfg.alpha = v / 100
                        Apply(); RebuildSubject()
                    end)
                y = n
            elseif prop == "scale" then
                local _, n = W.CreateSlider(c, L["opt_element_scale"],
                    (cfg.scale or 1) * 100, 25, 400, 5, y, function(v)
                        cfg.scale = v / 100
                        Apply(); RebuildSubject()
                    end)
                y = n
            elseif prop == "fontSize" then
                -- 0 = on garde la taille calculee par le module.
                local _, n = W.CreateSlider(c, L["opt_element_font_size"],
                    cfg.fontSize or 0, 0, 64, 1, y, function(v)
                        cfg.fontSize = v
                        Apply(); RebuildSubject()
                    end)
                y = n
                local _, n2 = W.CreateInfoText(c, L["info_element_font_size"], y)
                y = n2
            end
        end
    end

    local _, ny = W.CreateButton(c, L["btn_reset_element"], 220, y, function()
        store[id] = R.Default(dom, id)
        Apply(); RebuildSubject(); S.RebuildInspector()
    end)
    y = ny

    if desc.instanced then
        W.CreateButton(c, L["btn_delete_element"], 220, y, function()
            R.RemoveInstance(dom, store, id)
            S.state.element = nil
            Apply(); RebuildSubject()
            S.RebuildSidebar(); S.RebuildInspector()
        end)
    end
end

-- ---------------------------------------------------------------------
-- Presets de disposition
-- ---------------------------------------------------------------------
function S.BuildPresetPanel(c, store)
    local dom = Registry().DOMAIN
    local y = -8

    if not A then
        W.CreateInfoText(c, L["msg_presets_unavailable"], y)
        return
    end

    local _, ny = W.CreateSectionHeader(c, L["section_forge_presets"], y, "P")
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_forge_presets"], y)
    y = ny

    -- Enregistrer / remplacer
    local nameBox, ny = W.CreateMultiLineEditBox(c, L["opt_preset_name"], 24, y, {
        onTextChanged = function(t) S.state.presetName = t end,
    })
    y = ny
    if nameBox and nameBox.editBox and nameBox.editBox.SetText then
        nameBox.editBox:SetText(S.state.presetName or "")
    end

    local _, ny = W.CreateButton(c, L["btn_preset_save"], 220, y, function()
        local ok, err = A.Save(dom, S.state.presetName, store)
        print("|cff2e9dd8TomoMod|r " ..
            (ok and L["msg_preset_saved"] or (err or L["msg_preset_error"])))
        if ok then S.RebuildInspector() end
    end)
    y = ny

    -- Liste des presets enregistres
    local names = A.List(dom)
    if #names == 0 then
        local _, ny = W.CreateInfoText(c, L["info_no_preset"], y)
        y = ny
    else
        local opts = {}
        for _, n in ipairs(names) do opts[#opts + 1] = { text = n, value = n } end
        if not S.state.preset or not A.Exists(dom, S.state.preset) then
            S.state.preset = names[1]
        end

        local _, ny = W.CreateDropdown(c, L["opt_preset_saved"], opts, S.state.preset, y, function(v)
            S.state.preset = v
            S.RebuildInspector()
        end)
        y = ny

        local _, ny = W.CreateButton(c, L["btn_preset_apply"], 220, y, function()
            local ok, err = A.Apply(dom, S.state.preset, store)
            if ok then
                Apply(); RebuildSubject(); S.RebuildSidebar()
                print("|cff2e9dd8TomoMod|r " .. L["msg_preset_applied"])
            else
                print("|cff2e9dd8TomoMod|r " .. (err or L["msg_preset_error"]))
            end
            S.RebuildInspector()
        end)
        y = ny

        local _, ny = W.CreateButton(c, L["btn_preset_delete"], 220, y, function()
            A.Delete(dom, S.state.preset)
            S.state.preset = nil
            S.RebuildInspector()
        end)
        y = ny

        local _, ny = W.CreateButton(c, L["btn_preset_export"], 220, y, function()
            local str, err = A.Export(dom, S.state.preset)
            if not str then
                print("|cff2e9dd8TomoMod|r " .. (err or L["msg_preset_error"]))
                return
            end
            S.state.exportText = str
            S.RebuildInspector()
        end)
        y = ny
    end

    -- La chaine de partage s'affiche en lecture seule : on ne peut pas
    -- ecrire dans le presse-papier depuis un addon, donc l'utilisateur la
    -- selectionne lui-meme (Ctrl+A / Ctrl+C).
    if S.state.exportText and S.state.exportText ~= "" then
        local box, ny = W.CreateMultiLineEditBox(c, L["opt_preset_share_string"], 60, y, {
            readOnly = true,
        })
        y = ny
        if box and box.editBox and box.editBox.SetText then
            box.editBox:SetText(S.state.exportText)
        end
        local _, ny = W.CreateInfoText(c, L["info_preset_copy"], y)
        y = ny
    end

    -- Import
    local importBox, ny = W.CreateMultiLineEditBox(c, L["opt_preset_import"], 48, y, {
        onTextChanged = function(t) S.state.importText = t end,
    })
    y = ny
    if importBox and importBox.editBox and importBox.editBox.SetText then
        importBox.editBox:SetText(S.state.importText or "")
    end

    W.CreateButton(c, L["btn_preset_import"], 220, y, function()
        -- Le domaine est verifie, pas suppose : appliquer une disposition de
        -- plaque a un cadre d'unite ne resoudrait rien et viderait le cadre,
        -- ce qui se lit comme un bug et non comme une erreur de manipulation.
        local name, err = A.Import(S.state.importText, dom)
        if not name then
            print("|cff2e9dd8TomoMod|r " .. (err or L["msg_preset_error"]))
            return
        end
        S.state.preset = name
        S.state.importText = ""
        print("|cff2e9dd8TomoMod|r " .. L["msg_preset_imported"] .. " " .. name)
        S.RebuildInspector()
    end)
end

-- ---------------------------------------------------------------------
-- Studio V2 navigation
-- ---------------------------------------------------------------------
local function CurrentStudioView()
    if S.state.showFrameEditor then return "frame" end
    if S.state.showBars then return "bars" end
    if S.state.showPresets then return "presets" end
    return "elements"
end

local function UpdateNavigation()
    local active = CurrentStudioView()
    for id, b in pairs(navButtons) do
        local on = id == active
        b:SetBackdropColor(
            on and BRAND[1] or 0.045,
            on and BRAND[2] or 0.050,
            on and BRAND[3] or 0.065,
            on and 0.20 or 1)
        b:SetBackdropBorderColor(
            BRAND[1], BRAND[2], BRAND[3], on and 1 or 0.25)
        if b._label then
            b._label:SetTextColor(
                on and 1 or 0.58,
                on and 1 or 0.62,
                on and 1 or 0.70, 1)
        end
    end
end

local function SetStudioView(view)
    S.state.showFrameEditor = view == "frame"
    S.state.showBars        = view == "bars"
    S.state.showPresets     = view == "presets"

    if view == "elements" then
        if not S.state.element then
            local reg = Registry()
            local list = reg and reg.List and reg.List() or {}
            local first = list[1]
            if first then S.state.element = first.id end
        end
        if canvas and canvas.Select and S.state.element then
            canvas:Select(S.state.element)
        end
    else
        S.state.element = nil
        if canvas and canvas.Select then canvas:Select(nil) end
    end

    S.RebuildSidebar()
    S.RebuildInspector()
    UpdateNavigation()
end

local function CreateNavigationButton(parent, id, text, x)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(132, 30)
    b:SetPoint("LEFT", x, 0)
    b:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })

    local fs = b:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT_BOLD, 11, "")
    fs:SetPoint("CENTER")
    fs:SetText(text)
    b._label = fs

    b:SetScript("OnEnter", function(self)
        if CurrentStudioView() ~= id then
            self:SetBackdropBorderColor(BRAND[1], BRAND[2], BRAND[3], 0.70)
            fs:SetTextColor(0.88, 0.92, 0.98, 1)
        end
    end)
    b:SetScript("OnLeave", UpdateNavigation)
    b:SetScript("OnClick", function() SetStudioView(id) end)
    navButtons[id] = b
    return b
end

-- ---------------------------------------------------------------------
-- First-run onboarding
-- ---------------------------------------------------------------------
local function TutorialDB()
    if not TomoModDB then return nil end
    if type(TomoModDB.astralForgeStudio) ~= "table" then
        TomoModDB.astralForgeStudio = {}
    end
    return TomoModDB.astralForgeStudio
end

local TUTORIAL_STEPS = {
    {
        title = "af_tutorial_1_title", body = "af_tutorial_1_body",
        target = function() return frame end,
    },
    {
        title = "af_tutorial_2_title", body = "af_tutorial_2_body",
        target = function() return selectorHighlightHost end,
    },
    {
        title = "af_tutorial_3_title", body = "af_tutorial_3_body",
        view = "frame",
        target = function() return inspectorHost end,
    },
    {
        title = "af_tutorial_4_title", body = "af_tutorial_4_body",
        view = "elements",
        target = function() return stageHost end,
    },
    {
        title = "af_tutorial_5_title", body = "af_tutorial_5_body",
        view = "bars",
        target = function() return inspectorHost end,
    },
    {
        title = "af_tutorial_6_title", body = "af_tutorial_6_body",
        view = "presets",
        target = function() return inspectorHost end,
    },
}

local function TutorialButton(parent, width)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width or 100, 28)
    b:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    b:SetBackdropColor(0.055, 0.065, 0.085, 1)
    b:SetBackdropBorderColor(BRAND[1], BRAND[2], BRAND[3], 0.58)

    local fs = b:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT_BOLD, 10, "")
    fs:SetPoint("CENTER")
    fs:SetTextColor(0.92, 0.95, 1, 1)
    b._label = fs
    return b
end

local function EnsureTutorialUI()
    if tutorialUI or not frame then return tutorialUI end

    local overlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    overlay:SetAllPoints(frame)
    overlay:SetFrameLevel(frame:GetFrameLevel() + 100)
    overlay:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    overlay:SetBackdropColor(0.008, 0.012, 0.020, 0.56)
    overlay:EnableMouse(true)
    overlay:Hide()

    local highlight = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
    highlight:SetFrameLevel(overlay:GetFrameLevel() + 2)
    highlight:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    highlight:SetBackdropBorderColor(BRAND[1], BRAND[2], BRAND[3], 1)

    local card = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
    card:SetSize(560, 190)
    card:SetPoint("BOTTOM", overlay, "BOTTOM", 0, 56)
    card:SetFrameLevel(overlay:GetFrameLevel() + 5)
    card:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    card:SetBackdropColor(0.035, 0.040, 0.055, 0.985)
    card:SetBackdropBorderColor(BRAND[1], BRAND[2], BRAND[3], 0.88)

    local progress = card:CreateFontString(nil, "OVERLAY")
    progress:SetFont(FONT_BOLD, 9, "")
    progress:SetPoint("TOPLEFT", 20, -16)
    progress:SetTextColor(BRAND[1], BRAND[2], BRAND[3], 1)

    local title = card:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_BOLD, 16, "")
    title:SetPoint("TOPLEFT", progress, "BOTTOMLEFT", 0, -8)
    title:SetPoint("RIGHT", card, "RIGHT", -20, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(1, 1, 1, 1)

    local body = card:CreateFontString(nil, "OVERLAY")
    body:SetFont(FONT, 11, "")
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    body:SetPoint("RIGHT", card, "RIGHT", -20, 0)
    body:SetWidth(520)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetWordWrap(true)
    body:SetTextColor(0.72, 0.76, 0.84, 1)

    local skip = TutorialButton(card, 92)
    skip:SetPoint("BOTTOMLEFT", 20, 16)
    skip._label:SetText(L["af_tutorial_skip"])

    local back = TutorialButton(card, 92)
    back:SetPoint("BOTTOMRIGHT", -218, 16)
    back._label:SetText(L["af_tutorial_back"])

    local nextB = TutorialButton(card, 112)
    nextB:SetPoint("BOTTOMRIGHT", -20, 16)

    tutorialUI = {
        overlay = overlay, highlight = highlight, card = card,
        progress = progress, title = title, body = body,
        skip = skip, back = back, next = nextB,
        step = 1,
    }
    return tutorialUI
end

local function EndTutorial(markDone)
    local ui = tutorialUI
    if not ui then return end
    ui.overlay:Hide()

    if markDone then
        local db = TutorialDB()
        if db then db.tutorialVersion = TUTORIAL_VERSION end
    end

    local restore = ui.restoreView or "elements"
    local restoreElement = ui.restoreElement
    SetStudioView(restore)
    if restore == "elements" and restoreElement then
        S.SelectElement(restoreElement)
    end
end

local function ShowTutorialStep(index)
    local ui = EnsureTutorialUI()
    local step = TUTORIAL_STEPS[index]
    if not (ui and step) then return end

    ui.step = index
    if step.view then SetStudioView(step.view) end

    ui.progress:SetText(string.format(
        L["af_tutorial_progress"], index, #TUTORIAL_STEPS))
    ui.title:SetText(L[step.title])
    ui.body:SetText(L[step.body])
    ui.back:SetShown(index > 1)
    ui.next._label:SetText(
        index == #TUTORIAL_STEPS
            and L["af_tutorial_finish"]
            or L["af_tutorial_next"])

    ui.highlight:ClearAllPoints()
    local target = step.target and step.target()
    if target then
        ui.highlight:SetPoint("TOPLEFT", target, "TOPLEFT", -5, 5)
        ui.highlight:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 5, -5)
        ui.highlight:Show()
    else
        ui.highlight:Hide()
    end
    ui.overlay:Show()
end

function S.StartTutorial()
    local ui = EnsureTutorialUI()
    if not ui then return end

    ui.restoreView = CurrentStudioView()
    ui.restoreElement = S.state.element

    ui.skip:SetScript("OnClick", function() EndTutorial(true) end)
    ui.back:SetScript("OnClick", function()
        ShowTutorialStep(math.max(1, ui.step - 1))
    end)
    ui.next:SetScript("OnClick", function()
        if ui.step >= #TUTORIAL_STEPS then
            EndTutorial(true)
        else
            ShowTutorialStep(ui.step + 1)
        end
    end)

    ShowTutorialStep(1)
end

function S.SelectElement(id)
    S.state.element = id
    S.state.showFrameEditor = false
    S.state.showBars = false
    S.state.showPresets = false
    if canvas and canvas.GetSelection and canvas:GetSelection() ~= id then
        canvas:Select(id)
    end
    S.RebuildSidebar()
    S.RebuildInspector()
    UpdateNavigation()
end

-- ---------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------
local function BuildWindow()
    local shell = Forge.Studio.CreateShell({
        name         = "TomoModAstralForgeFrame",
        title        = "|cff2e9dd8Astral Forge|r |cffffffffStudio|r",
        width        = PANEL_W,
        height       = PANEL_H,
        sideWidth    = SIDE_W,
        titleH       = TITLE_H,
        footerH      = FOOTER_H,
        -- Navigation moved to real tabs above the Canvas; only Refresh stays
        -- in the sidebar action area, which gives the element list more room.
        crudHeight   = 48,
        accent       = BRAND,
        sidebarTitle = L["af_sidebar_title"],
        selector = {
            label   = L["af_subject_label"],
            options = BuildSubjectOptions(),
            get     = function() return S.state.subject end,
            set     = function(v)
                S.state.subject = v
                S.state.element = nil
                S.state.showFrameEditor = false
                S.state.showBars = false
                S.state.showPresets = false
                RebuildSubject()
                S.RebuildSidebar()
                S.RebuildInspector()
                UpdateNavigation()
            end,
        },
        footerButtons = {
            { text = L["btn_add_custom_text"], width = 190, callback = function()
                local dom = Registry().DOMAIN
                local store = Store()
                if not store then return end
                local key, why = R.AddInstance(dom, store, "customText")
                if not key then
                    if why == "max" then
                        print("|cff2e9dd8TomoMod|r " .. L["msg_element_max_reached"])
                    end
                    return
                end
                S.state.element = key
                S.state.showFrameEditor = false
                S.state.showBars = false
                S.state.showPresets = false
                Apply(); RebuildSubject()
                S.RebuildSidebar(); S.RebuildInspector(); UpdateNavigation()
            end },
            { text = L["af_reset_all"], width = 170, callback = function()
                local store = Store()
                if not store then return end
                for _, desc in ipairs(Registry().List()) do
                    store[desc.id] = R.Default(Registry().DOMAIN, desc.id)
                end
                Apply(); RebuildSubject(); S.RebuildInspector()
            end },
        },
        hint = L["af_hint"],
    })
    frame       = shell.frame
    sidebarList = shell.sidebarList
    contentHost = shell.contentHost

    -- Header help: stays next to Close and relaunches onboarding at will.
    local helpBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    helpBtn:SetSize(82, 26)
    helpBtn:SetPoint("TOPRIGHT", -46, -10)
    helpBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    helpBtn:SetBackdropColor(0.055, 0.065, 0.085, 1)
    helpBtn:SetBackdropBorderColor(BRAND[1], BRAND[2], BRAND[3], 0.48)
    local helpText = helpBtn:CreateFontString(nil, "OVERLAY")
    helpText:SetFont(FONT_BOLD, 10, "")
    helpText:SetPoint("CENTER")
    helpText:SetText("? " .. L["af_help"])
    helpText:SetTextColor(0.80, 0.86, 0.94, 1)
    helpBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(BRAND[1], BRAND[2], BRAND[3], 0.14)
        self:SetBackdropBorderColor(BRAND[1], BRAND[2], BRAND[3], 0.95)
        helpText:SetTextColor(1, 1, 1, 1)
    end)
    helpBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.055, 0.065, 0.085, 1)
        self:SetBackdropBorderColor(BRAND[1], BRAND[2], BRAND[3], 0.48)
        helpText:SetTextColor(0.80, 0.86, 0.94, 1)
    end)
    helpBtn:SetScript("OnClick", function() S.StartTutorial() end)

    -- Invisible tutorial target matching the selector area owned by the
    -- shared Studio shell.
    selectorHighlightHost = CreateFrame("Frame", nil, frame)
    selectorHighlightHost:SetSize(300, 48)
    selectorHighlightHost:SetPoint("TOPLEFT", 200, -6)
    selectorHighlightHost:EnableMouse(false)

    W.CreateButton(shell.crudHost, L["af_refresh"], 200, -6, function()
        RebuildSubject()
        S.RebuildInspector()
    end)

    -- Main navigation: four Studio modes with an explicit active state.
    navigationHost = CreateFrame("Frame", nil, contentHost, "BackdropTemplate")
    navigationHost:SetPoint("TOPLEFT", 12, -10)
    navigationHost:SetPoint("TOPRIGHT", -12, -10)
    navigationHost:SetHeight(38)
    navigationHost:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    navigationHost:SetBackdropColor(0.025, 0.030, 0.042, 1)
    navigationHost:SetBackdropBorderColor(0.10, 0.12, 0.16, 1)

    CreateNavigationButton(navigationHost, "frame",     L["af_nav_frame"],     8)
    CreateNavigationButton(navigationHost, "elements",  L["af_nav_elements"], 148)
    CreateNavigationButton(navigationHost, "bars",      L["af_nav_bars"],     288)
    CreateNavigationButton(navigationHost, "presets",   L["af_nav_presets"],  428)
    UpdateNavigation()

    -- Stage (haut) : fond sombre neutre, le cadre d'apercu au centre.
    stageHost = CreateFrame("Frame", nil, contentHost, "BackdropTemplate")
    stageHost:SetPoint("TOPLEFT", navigationHost, "BOTTOMLEFT", 0, -8)
    stageHost:SetPoint("TOPRIGHT", navigationHost, "BOTTOMRIGHT", 0, -8)
    stageHost:SetHeight(STAGE_H)
    stageHost:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    stageHost:SetBackdropColor(0.02, 0.03, 0.04, 1)
    stageHost:SetBackdropBorderColor(0.14, 0.15, 0.19, 1)

    canvas = Forge.Canvas.Create(stageHost, {
        domain = UFE.DOMAIN,   -- remplace par SetSubject a chaque changement
        accent = BRAND,
        onSelect = function(id)
            local modeChanged = S.state.showFrameEditor or S.state.showBars
                or S.state.showPresets
            S.state.showFrameEditor = false
            S.state.showBars = false
            S.state.showPresets = false
            if S.state.element == id and not modeChanged then return end
            S.state.element = id
            S.RebuildSidebar()
            S.RebuildInspector()
            UpdateNavigation()
        end,
        onChange = function()
            Apply()
            S.RebuildInspector()
        end,
    })
    canvas.stage:SetPoint("TOPLEFT", stageHost, "TOPLEFT", 1, -1)
    canvas.stage:SetPoint("BOTTOMRIGHT", stageHost, "BOTTOMRIGHT", -1, 1)

    inspectorHost = CreateFrame("Frame", nil, contentHost)
    inspectorHost:SetPoint("TOPLEFT", stageHost, "BOTTOMLEFT", 0, -10)
    inspectorHost:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT", -12, 10)
end

function S.Open()
    if not frame then BuildWindow() end
    if not frame then return end
    frame:Show()

    -- La construction du sujet touche des widgets de jeu : si elle echoue,
    -- la fenetre doit rester utilisable (liste, inspecteur, presets) plutot
    -- que de s'ouvrir vide. C'est exactement ce qui se passait quand une
    -- mesure sur rect secret levait au milieu de Rebuild.
    local ok, err = pcall(RebuildSubject)
    if not ok then
        print("|cff2e9dd8TomoMod|r AstralForge : apercu indisponible ("
            .. tostring(err) .. ")")
    end

    S.RebuildSidebar()
    S.RebuildInspector()
    UpdateNavigation()

    -- Versioned first-run guide. A later redesign can bump the version and
    -- show only the new onboarding without resetting any Forge layout.
    local tdb = TutorialDB()
    if tdb and (tonumber(tdb.tutorialVersion) or 0) < TUTORIAL_VERSION then
        C_Timer.After(0, function()
            if frame and frame:IsShown() then S.StartTutorial() end
        end)
    end
end

function S.Close()
    if frame then frame:Hide() end
end

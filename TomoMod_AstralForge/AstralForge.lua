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
        ["af_tutorial_2_body"]         = "Use the subject selector to choose a UnitFrame, Boss Frames, Nameplates or one of the supported non-player cast bars.",
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
        ["af_tutorial_2_body"]         = "Le sélecteur permet de choisir une UnitFrame, les Boss Frames, les Nameplates ou l'une des barres d'incantation prises en charge hors Player.",
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
        ["af_tutorial_2_body"]         = "Mit der Auswahl bearbeitest du UnitFrames, Boss-Rahmen, Namensplaketten oder eine der unterstützten Zauberleisten außer Spieler.",
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
        ["af_tutorial_2_body"]         = "El selector permite editar UnitFrames, Marcos de jefe, Placas de nombre o una de las barras de lanzamiento compatibles excepto la del Jugador.",
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
        ["af_tutorial_2_body"]         = "Il selettore permette di modificare UnitFrame, Boss Frame, Nameplate o una delle barre di lancio supportate tranne quella del Giocatore.",
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
        ["af_tutorial_2_body"]         = "O seletor permite editar UnitFrames, Quadros de chefe, Placas de nome ou uma das barras de lançamento compatíveis, exceto a do Jogador.",
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

-- ---------------------------------------------------------------------
-- Astral Forge Studio V2.1 - Lot 2 locales
-- Existing TomoMod option labels are reused wherever possible; only the
-- Studio-specific grouping/help text is declared here.
-- ---------------------------------------------------------------------
if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["af_v21_global_uf"]          = "Global UnitFrame settings",
        ["af_v21_global_uf_info"]     = "These settings are shared by Player, Target, Focus, Pet, Target of Target and Boss Frames.",
        ["af_v21_frame_behavior"]     = "Frame behavior",
        ["af_v21_auras"]              = "Auras",
        ["af_v21_enemy_buffs"]        = "Enemy buffs",
        ["af_v21_np_roles"]           = "Friendly role icons",
        ["af_v21_np_advanced"]        = "Advanced Nameplate behavior",
        ["af_v21_np_colors"]          = "Context colors",
        ["af_v21_np_classification"]  = "Classification colors",
        ["af_v21_np_tank"]            = "Tank / threat mode",
        ["af_v21_boss_info"]          = "Boss Frames share one layout: width, height and spacing are applied to all five boss frames.",
        ["af_v21_bar_note"]           = "Textures, absorb appearance and detailed bar styling are configured in the Bars tab.",
    })
    TomoMod_RegisterLocale("frFR", {
        ["af_v21_global_uf"]          = "Réglages globaux UnitFrames",
        ["af_v21_global_uf_info"]     = "Ces réglages sont partagés par Player, Target, Focus, Pet, Target of Target et les Boss Frames.",
        ["af_v21_frame_behavior"]     = "Comportement du cadre",
        ["af_v21_auras"]              = "Auras",
        ["af_v21_enemy_buffs"]        = "Buffs ennemis",
        ["af_v21_np_roles"]           = "Icônes de rôle alliées",
        ["af_v21_np_advanced"]        = "Comportement avancé des Nameplates",
        ["af_v21_np_colors"]          = "Couleurs contextuelles",
        ["af_v21_np_classification"]  = "Couleurs de classification",
        ["af_v21_np_tank"]            = "Mode Tank / menace",
        ["af_v21_boss_info"]          = "Les Boss Frames partagent une même disposition : largeur, hauteur et espacement sont appliqués aux cinq cadres de boss.",
        ["af_v21_bar_note"]           = "Les textures, l'apparence de l'absorbe et le style détaillé des barres se règlent dans l'onglet Barres.",
    })
    TomoMod_RegisterLocale("deDE", {
        ["af_v21_global_uf"]          = "Globale UnitFrame-Einstellungen",
        ["af_v21_global_uf_info"]     = "Diese Einstellungen gelten gemeinsam für Spieler, Ziel, Fokus, Begleiter, Ziel des Ziels und Boss-Rahmen.",
        ["af_v21_frame_behavior"]     = "Rahmenverhalten",
        ["af_v21_auras"]              = "Auren",
        ["af_v21_enemy_buffs"]        = "Gegnerische Buffs",
        ["af_v21_np_roles"]           = "Rollen-Symbole für Verbündete",
        ["af_v21_np_advanced"]        = "Erweitertes Namensplaketten-Verhalten",
        ["af_v21_np_colors"]          = "Kontextfarben",
        ["af_v21_np_classification"]  = "Klassifizierungsfarben",
        ["af_v21_np_tank"]            = "Tank- / Bedrohungsmodus",
        ["af_v21_boss_info"]          = "Boss-Rahmen teilen sich ein Layout: Breite, Höhe und Abstand gelten für alle fünf Boss-Rahmen.",
        ["af_v21_bar_note"]           = "Texturen, Absorb-Darstellung und detailliertes Leisten-Design werden im Reiter Leisten eingestellt.",
    })
    TomoMod_RegisterLocale("esES", {
        ["af_v21_global_uf"]          = "Ajustes globales de UnitFrames",
        ["af_v21_global_uf_info"]     = "Estos ajustes se comparten entre Jugador, Objetivo, Foco, Mascota, Objetivo del objetivo y Marcos de jefe.",
        ["af_v21_frame_behavior"]     = "Comportamiento del marco",
        ["af_v21_auras"]              = "Auras",
        ["af_v21_enemy_buffs"]        = "Beneficios enemigos",
        ["af_v21_np_roles"]           = "Iconos de rol aliados",
        ["af_v21_np_advanced"]        = "Comportamiento avanzado de Placas de nombre",
        ["af_v21_np_colors"]          = "Colores contextuales",
        ["af_v21_np_classification"]  = "Colores de clasificación",
        ["af_v21_np_tank"]            = "Modo Tanque / amenaza",
        ["af_v21_boss_info"]          = "Los Marcos de jefe comparten una disposición: ancho, alto y separación se aplican a los cinco marcos.",
        ["af_v21_bar_note"]           = "Las texturas, el aspecto de absorción y el estilo detallado de las barras se configuran en la pestaña Barras.",
    })
    TomoMod_RegisterLocale("itIT", {
        ["af_v21_global_uf"]          = "Impostazioni globali UnitFrame",
        ["af_v21_global_uf_info"]     = "Queste impostazioni sono condivise da Giocatore, Bersaglio, Focus, Famiglio, Bersaglio del bersaglio e Boss Frame.",
        ["af_v21_frame_behavior"]     = "Comportamento del riquadro",
        ["af_v21_auras"]              = "Aure",
        ["af_v21_enemy_buffs"]        = "Buff nemici",
        ["af_v21_np_roles"]           = "Icone ruolo alleati",
        ["af_v21_np_advanced"]        = "Comportamento avanzato Nameplate",
        ["af_v21_np_colors"]          = "Colori contestuali",
        ["af_v21_np_classification"]  = "Colori classificazione",
        ["af_v21_np_tank"]            = "Modalità Tank / minaccia",
        ["af_v21_boss_info"]          = "I Boss Frame condividono una disposizione: larghezza, altezza e spaziatura si applicano a tutti e cinque.",
        ["af_v21_bar_note"]           = "Texture, aspetto degli assorbimenti e stile dettagliato delle barre si configurano nella scheda Barre.",
    })
    TomoMod_RegisterLocale("ptBR", {
        ["af_v21_global_uf"]          = "Ajustes globais de UnitFrames",
        ["af_v21_global_uf_info"]     = "Esses ajustes são compartilhados por Jogador, Alvo, Foco, Ajudante, Alvo do alvo e Quadros de chefe.",
        ["af_v21_frame_behavior"]     = "Comportamento do quadro",
        ["af_v21_auras"]              = "Auras",
        ["af_v21_enemy_buffs"]        = "Bônus inimigos",
        ["af_v21_np_roles"]           = "Ícones de função aliados",
        ["af_v21_np_advanced"]        = "Comportamento avançado das Placas de nome",
        ["af_v21_np_colors"]          = "Cores contextuais",
        ["af_v21_np_classification"]  = "Cores de classificação",
        ["af_v21_np_tank"]            = "Modo Tanque / ameaça",
        ["af_v21_boss_info"]          = "Os Quadros de chefe compartilham um layout: largura, altura e espaçamento valem para os cinco quadros.",
        ["af_v21_bar_note"]           = "Texturas, aparência de absorção e estilo detalhado das barras são configurados na aba Barras.",
    })
end

-- ---------------------------------------------------------------------
-- Astral Forge Studio V2.1 - Lot 2 follow-up
-- Cadre tab UX refinement: dedicated setting sections in the left sidebar,
-- cleaner preview in Cadre mode, and less scrolling by showing only the
-- selected settings block.
-- ---------------------------------------------------------------------
if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["af_v22_editor_title"]      = "Frame editor",
        ["af_v22_editor_info"]       = "Select a settings category on the left. Only the selected block is shown below the preview.",
        ["af_v22_sec_global"]        = "Global settings",
        ["af_v22_sec_dimensions"]    = "Dimensions",
        ["af_v22_sec_display"]       = "Display",
        ["af_v22_sec_colors"]        = "Colors & threat",
        ["af_v22_sec_auras"]         = "Auras",
        ["af_v22_sec_enemy_buffs"]   = "Enemy buffs",
        ["af_v22_sec_roles"]         = "Role icons",
        ["af_v22_sec_castbar"]       = "Castbar",
        ["af_v22_sec_advanced"]      = "Advanced",
        ["af_v22_sec_context_colors"] = "Context colors",
        ["af_v22_sec_classification"] = "Classification",
        ["af_v22_sec_tank"]          = "Tank mode",
    })
    TomoMod_RegisterLocale("frFR", {
        ["af_v22_editor_title"]      = "Éditeur de cadre",
        ["af_v22_editor_info"]       = "Sélectionne une catégorie de réglages à gauche. Seul le bloc choisi est affiché sous l'aperçu.",
        ["af_v22_sec_global"]        = "Réglages globaux",
        ["af_v22_sec_dimensions"]    = "Dimensions",
        ["af_v22_sec_display"]       = "Affichage",
        ["af_v22_sec_colors"]        = "Couleurs & menace",
        ["af_v22_sec_auras"]         = "Auras",
        ["af_v22_sec_enemy_buffs"]   = "Buffs ennemis",
        ["af_v22_sec_roles"]         = "Icônes de rôle",
        ["af_v22_sec_castbar"]       = "Barre d'incantation",
        ["af_v22_sec_advanced"]      = "Avancé",
        ["af_v22_sec_context_colors"] = "Couleurs contextuelles",
        ["af_v22_sec_classification"] = "Classification",
        ["af_v22_sec_tank"]          = "Mode Tank",
    })
    TomoMod_RegisterLocale("deDE", {
        ["af_v22_editor_title"]      = "Rahmen-Editor",
        ["af_v22_editor_info"]       = "Wähle links eine Einstellungskategorie. Unter der Vorschau wird nur der gewählte Block angezeigt.",
        ["af_v22_sec_global"]        = "Globale Einstellungen",
        ["af_v22_sec_dimensions"]    = "Abmessungen",
        ["af_v22_sec_display"]       = "Anzeige",
        ["af_v22_sec_colors"]        = "Farben & Bedrohung",
        ["af_v22_sec_auras"]         = "Auren",
        ["af_v22_sec_enemy_buffs"]   = "Gegnerische Buffs",
        ["af_v22_sec_roles"]         = "Rollen-Symbole",
        ["af_v22_sec_castbar"]       = "Zauberleiste",
        ["af_v22_sec_advanced"]      = "Erweitert",
        ["af_v22_sec_context_colors"] = "Kontextfarben",
        ["af_v22_sec_classification"] = "Klassifizierung",
        ["af_v22_sec_tank"]          = "Tankmodus",
    })
    TomoMod_RegisterLocale("esES", {
        ["af_v22_editor_title"]      = "Editor de marco",
        ["af_v22_editor_info"]       = "Selecciona a la izquierda una categoría de ajustes. Solo se muestra debajo de la vista previa el bloque elegido.",
        ["af_v22_sec_global"]        = "Ajustes globales",
        ["af_v22_sec_dimensions"]    = "Dimensiones",
        ["af_v22_sec_display"]       = "Visualización",
        ["af_v22_sec_colors"]        = "Colores y amenaza",
        ["af_v22_sec_auras"]         = "Auras",
        ["af_v22_sec_enemy_buffs"]   = "Beneficios enemigos",
        ["af_v22_sec_roles"]         = "Iconos de rol",
        ["af_v22_sec_castbar"]       = "Barra de lanzamiento",
        ["af_v22_sec_advanced"]      = "Avanzado",
        ["af_v22_sec_context_colors"] = "Colores contextuales",
        ["af_v22_sec_classification"] = "Clasificación",
        ["af_v22_sec_tank"]          = "Modo tanque",
    })
    TomoMod_RegisterLocale("itIT", {
        ["af_v22_editor_title"]      = "Editor del riquadro",
        ["af_v22_editor_info"]       = "Seleziona a sinistra una categoria di impostazioni. Sotto l'anteprima viene mostrato solo il blocco scelto.",
        ["af_v22_sec_global"]        = "Impostazioni globali",
        ["af_v22_sec_dimensions"]    = "Dimensioni",
        ["af_v22_sec_display"]       = "Visualizzazione",
        ["af_v22_sec_colors"]        = "Colori e minaccia",
        ["af_v22_sec_auras"]         = "Aure",
        ["af_v22_sec_enemy_buffs"]   = "Buff nemici",
        ["af_v22_sec_roles"]         = "Icone ruolo",
        ["af_v22_sec_castbar"]       = "Barra di lancio",
        ["af_v22_sec_advanced"]      = "Avanzato",
        ["af_v22_sec_context_colors"] = "Colori contestuali",
        ["af_v22_sec_classification"] = "Classificazione",
        ["af_v22_sec_tank"]          = "Modalità tank",
    })
    TomoMod_RegisterLocale("ptBR", {
        ["af_v22_editor_title"]      = "Editor de quadro",
        ["af_v22_editor_info"]       = "Selecione à esquerda uma categoria de ajustes. Abaixo da prévia é exibido apenas o bloco escolhido.",
        ["af_v22_sec_global"]        = "Ajustes globais",
        ["af_v22_sec_dimensions"]    = "Dimensões",
        ["af_v22_sec_display"]       = "Exibição",
        ["af_v22_sec_colors"]        = "Cores e ameaça",
        ["af_v22_sec_auras"]         = "Auras",
        ["af_v22_sec_enemy_buffs"]   = "Bônus inimigos",
        ["af_v22_sec_roles"]         = "Ícones de função",
        ["af_v22_sec_castbar"]       = "Barra de lançamento",
        ["af_v22_sec_advanced"]      = "Avançado",
        ["af_v22_sec_context_colors"] = "Cores contextuais",
        ["af_v22_sec_classification"] = "Classificação",
        ["af_v22_sec_tank"]          = "Modo tanque",
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
    { value = "player", kind = "unitframe", labelKey = "frame_player",
      registry = function() return TomoMod_UFElements end,
      settings = function() return TomoModDB.unitFrames and TomoModDB.unitFrames.player end },
    { value = "target", kind = "unitframe", labelKey = "frame_target",
      registry = function() return TomoMod_UFElements end,
      settings = function() return TomoModDB.unitFrames and TomoModDB.unitFrames.target end },
    { value = "focus", kind = "unitframe", labelKey = "frame_focus",
      registry = function() return TomoMod_UFElements end,
      settings = function() return TomoModDB.unitFrames and TomoModDB.unitFrames.focus end },
    { value = "pet", kind = "unitframe", labelKey = "frame_pet",
      registry = function() return TomoMod_UFElements end,
      settings = function() return TomoModDB.unitFrames and TomoModDB.unitFrames.pet end },
    { value = "targettarget", kind = "unitframe", labelKey = "frame_targettarget",
      registry = function() return TomoMod_UFElements end,
      settings = function() return TomoModDB.unitFrames and TomoModDB.unitFrames.targettarget end },

    { value = "bossframe", kind = "bossframe", labelKey = "frame_boss",
      registry = function() return TomoMod_BossFrameElements end,
      settings = function()
          return TomoModDB.unitFrames and TomoModDB.unitFrames.bossFrames
      end },

    { value = "nameplate", kind = "nameplate", labelKey = "frame_nameplate",
      registry = function() return TomoMod_NPElements end,
      settings = function() return TomoModDB.nameplates end },

    -- Player castbar deliberately leaves Astral Forge. It will belong to the
    -- future CastBars / ResourceBars Studio. Target/Focus/Pet/Boss remain here.
    { value = "castbar_target", kind = "castbar",
      labelKey = "frame_cast_target", castUnit = "target",
      registry = function() return TomoMod_CBElements end,
      settings = function() return TomoModDB.castbars and TomoModDB.castbars.target end },
    { value = "castbar_focus", kind = "castbar",
      labelKey = "frame_cast_focus", castUnit = "focus",
      registry = function() return TomoMod_CBElements end,
      settings = function() return TomoModDB.castbars and TomoModDB.castbars.focus end },
    { value = "castbar_pet", kind = "castbar",
      labelKey = "frame_cast_pet", castUnit = "pet",
      registry = function() return TomoMod_CBElements end,
      settings = function() return TomoModDB.castbars and TomoModDB.castbars.pet end },
    { value = "castbar_boss", kind = "castbar",
      labelKey = "frame_cast_boss", castUnit = "boss",
      registry = function() return TomoMod_CBElements end,
      settings = function() return TomoModDB.castbars and TomoModDB.castbars.boss end },
}

local SUBJECT_BY_VALUE = {}
for _, sub in ipairs(SUBJECTS) do SUBJECT_BY_VALUE[sub.value] = sub end

local NAMEPLATE = "nameplate"

local function Subject()
    return SUBJECT_BY_VALUE[S.state.subject] or SUBJECTS[1]
end

local function SubjectKind()
    local sub = Subject()
    return sub and sub.kind or "unitframe"
end

local function IsPlate()
    return SubjectKind() == "nameplate"
end

local function IsBoss()
    return SubjectKind() == "bossframe"
end

local function IsCastbar()
    return SubjectKind() == "castbar"
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
local suppressCanvasSelect = false
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

    if sub.kind == "castbar" then
        local CB = TomoMod_Castbar
        if CB and CB.ApplySettings then CB.ApplySettings() end
        return
    elseif sub.kind == "bossframe" then
        local BF = TomoMod_BossFrames
        if BF and BF.RefreshAll then BF.RefreshAll() end
        return
    elseif sub.kind == "nameplate" then
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
-- WoW frames cannot be destroyed. Every replaced preview is explicitly
-- retired into one hidden bin before the next subject is created. This is
-- stricter than relying on each factory's recycle path and guarantees that
-- Player -> Target -> Nameplate can never leave two visible subjects stacked
-- on the canvas.
local subjectBin

local function SubjectBin()
    if not subjectBin then
        subjectBin = CreateFrame("Frame")
        subjectBin:Hide()
    end
    return subjectBin
end

local function RetireSubject()
    -- Hide every handle before the old widget tree leaves the stage.
    if canvas and canvas.SetSubject then
        canvas:SetSubject(nil, nil)
    end

    -- A Nameplate preview has a base frame that owns the visible plate.
    if plateSubjectBase then
        plateSubjectBase:Hide()
        plateSubjectBase:ClearAllPoints()
        plateSubjectBase:SetParent(SubjectBin())
        plateSubjectBase = nil
        subject = nil
        return
    end

    if subject then
        subject:Hide()
        subject:ClearAllPoints()
        if subject.SetParent then subject:SetParent(SubjectBin()) end
        subject = nil
    end
end

local function CreateBossPreview(parent)
    local db = Settings()
    if not (parent and db) then return nil end

    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(db.width or 200, db.height or 28)

    local tex = TomoModDB.unitFrames.texture
        or "Interface\\Buttons\\WHITE8x8"
    local font = TomoModDB.unitFrames.fontFamily
        or TomoModDB.unitFrames.font
        or "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
    local fontSize = TomoModDB.unitFrames.fontSize or 12

    local health = CreateFrame("StatusBar", nil, f)
    health:SetAllPoints()
    health:SetStatusBarTexture(tex)
    health:SetMinMaxValues(0, 100)
    health:SetValue(72)
    health:SetStatusBarColor(0.82, 0.16, 0.18, 1)
    f.health = health

    local bg = health:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(tex)
    bg:SetVertexColor(0.08, 0.08, 0.10, 0.88)
    health.bg = bg

    local raidIcon = health:CreateTexture(nil, "OVERLAY")
    raidIcon:SetSize(16, 16)
    raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    SetRaidTargetIconTexture(raidIcon, 8)
    f.raidIcon = raidIcon

    local nameText = health:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(font, math.max(8, fontSize - 1), "OUTLINE")
    nameText:SetText("Boss - Taurache")
    nameText:SetTextColor(1, 1, 1, 0.95)
    nameText:SetJustifyH("LEFT")
    nameText:SetWidth((db.width or 200) * 0.55)
    f.nameText = nameText

    local healthText = health:CreateFontString(nil, "OVERLAY")
    healthText:SetFont(font, fontSize, "OUTLINE")
    healthText:SetText("72%")
    healthText:SetTextColor(1, 1, 1, 1)
    healthText:SetJustifyH("RIGHT")
    f.healthText = healthText

    return f
end

local function RebuildSubject()
    if not (canvas and stageHost) then return end
    local sub = Subject()
    local reg = Registry()
    if not (sub and reg) then return end

    RetireSubject()

    if sub.kind == "castbar" and reg.CreatePreview then
        subject = reg.CreatePreview(canvas.stage, sub.castUnit)
        if not subject then return end
        subject:ClearAllPoints()
        subject:SetPoint("CENTER", canvas.stage, "CENTER", 0, 0)
        subject:Show()

    elseif sub.kind == "nameplate" then
        local NP = TomoMod_Nameplates
        if not (NP and NP.CreatePreviewPlate) then return end
        local plate, base = NP.CreatePreviewPlate(canvas.stage)
        if not (plate and base) then return end
        subject, plateSubjectBase = plate, base
        base:ClearAllPoints()
        base:SetPoint("CENTER", canvas.stage, "CENTER", 0, 0)
        base:Show()
        plate:Show()

    elseif sub.kind == "bossframe" then
        subject = CreateBossPreview(canvas.stage)
        if not subject then return end
        subject:ClearAllPoints()
        subject:SetPoint("CENTER", canvas.stage, "CENTER", 0, 0)
        subject:Show()

    else
        local UFP = TomoMod_UFPreview
        if not (UFP and UFP.CreateStandalone) then return end
        -- Never recycle a preview belonging to another subject. The previous
        -- tree was already retired above, so the factory must build from the
        -- settings of the newly selected unit.
        subject = UFP.CreateStandalone(canvas.stage, sub.value)
        if not subject then return end
        subject:ClearAllPoints()
        subject:SetPoint("CENTER", canvas.stage, "CENTER", 0, 0)
        subject:Show()
    end

    local store = Store()
    if store then
        reg.ApplyAll(subject, store)
        if reg.RefreshCustomBars then
            reg.RefreshCustomBars(subject, store, true)
        end
    end
    canvas:SetSubject(subject, store, reg.DOMAIN)
end

-- ---------------------------------------------------------------------
-- Nameplates Cadre Preview Parity
-- ---------------------------------------------------------------------
-- The normal Forge nameplate subject is perfect for Elements because it
-- exposes each draggable widget. Cadre has a different job: quickly show
-- how the configured plate reads in common situations. Reuse the visual
-- language of Options > Nameplates instead of trying to coerce the live-like
-- Forge subject into being both a drag canvas and a configuration preview.
local nameplateCadreParity

local function NPPreviewText(key, fallback)
    local value = L and L[key]
    if value and value ~= key then return value end
    return fallback or key
end

local function NPPreviewClamp(v, lo, hi, fallback)
    v = tonumber(v) or fallback
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function NPPreviewColor(db, key, fallback)
    local c = db and db.colors and db.colors[key]
    if type(c) == "table" then
        return tonumber(c.r or c[1]) or fallback[1],
               tonumber(c.g or c[2]) or fallback[2],
               tonumber(c.b or c[3]) or fallback[3]
    end
    return fallback[1], fallback[2], fallback[3]
end

local function CreateNameplateCadreParity(parent)
    if nameplateCadreParity then
        nameplateCadreParity:SetParent(parent)
        nameplateCadreParity:ClearAllPoints()
        nameplateCadreParity:SetAllPoints(parent)
        return nameplateCadreParity
    end

    local WHITE = "Interface\\Buttons\\WHITE8x8"
    local root = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    root:SetAllPoints(parent)
    root:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    root:SetBackdropColor(0.022, 0.026, 0.036, 0.98)
    root:SetBackdropBorderColor(BRAND[1], BRAND[2], BRAND[3], 0.22)
    if root.SetClipsChildren then root:SetClipsChildren(true) end

    local wash = root:CreateTexture(nil, "BACKGROUND", nil, -1)
    wash:SetAllPoints()
    if wash.SetGradientAlpha then
        wash:SetGradientAlpha(
            "HORIZONTAL",
            BRAND[1], BRAND[2], BRAND[3], 0.08,
            0.02, 0.03, 0.05, 0.01)
    else
        wash:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 0.035)
    end

    local title = root:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_BOLD, 11, "")
    title:SetPoint("TOPLEFT", 18, -14)
    title:SetText(NPPreviewText("np_preview_title", "Nameplate preview"))
    title:SetTextColor(BRAND[1], BRAND[2], BRAND[3], 1)
    root._title = title

    local hint = root:CreateFontString(nil, "OVERLAY")
    hint:SetFont(FONT, 9, "")
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    hint:SetText(NPPreviewText(
        "np_preview_hint",
        "Quick readability: color, cast, auras and threat in one place."))
    hint:SetTextColor(0.52, 0.56, 0.64, 1)
    root._hint = hint

    root._plates = {}

    local function CreatePlate(slot, labelKey, fallbackLabel, value, hostile)
        local plate = CreateFrame("Frame", nil, root, "BackdropTemplate")
        plate:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
        plate:SetBackdropColor(0.020, 0.022, 0.030, 0.90)
        plate._slot = slot
        plate._value = value
        plate._hostile = hostile

        local name = plate:CreateFontString(nil, "OVERLAY")
        name:SetFont(
            "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf",
            10, "OUTLINE")
        name:SetPoint("BOTTOMLEFT", plate, "TOPLEFT", 1, 3)
        name:SetText(NPPreviewText(labelKey, fallbackLabel))
        plate._name = name

        local hp = CreateFrame("StatusBar", nil, plate)
        hp:SetPoint("TOPLEFT", 3, -4)
        hp:SetPoint("TOPRIGHT", -3, -4)
        hp:SetStatusBarTexture(WHITE)
        hp:SetMinMaxValues(0, 100)
        hp:SetValue(value)
        plate._hp = hp

        local hpBg = hp:CreateTexture(nil, "BACKGROUND")
        hpBg:SetAllPoints()
        plate._hpBg = hpBg

        local pct = hp:CreateFontString(nil, "OVERLAY")
        pct:SetFont(
            "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf",
            8, "OUTLINE")
        pct:SetPoint("RIGHT", -4, 0)
        pct:SetText(value .. "%")
        pct:SetTextColor(1, 1, 1, 0.84)
        plate._pct = pct

        local cast = CreateFrame("StatusBar", nil, plate)
        cast:SetPoint("TOPLEFT", hp, "BOTTOMLEFT", 0, -3)
        cast:SetPoint("TOPRIGHT", hp, "BOTTOMRIGHT", 0, -3)
        cast:SetStatusBarTexture(WHITE)
        cast:SetMinMaxValues(0, 100)
        cast:SetValue(hostile and 68 or 0)
        cast:SetStatusBarColor(0.95, 0.58, 0.20, hostile and 0.92 or 0)
        plate._cast = cast

        local castBg = cast:CreateTexture(nil, "BACKGROUND")
        castBg:SetAllPoints()
        castBg:SetColorTexture(0.16, 0.10, 0.04, hostile and 0.82 or 0.20)
        plate._castBg = castBg

        plate._dots = {}
        for i = 1, hostile and 4 or 2 do
            local dot = plate:CreateTexture(nil, "OVERLAY")
            dot:SetSize(7, 7)
            dot:SetPoint("TOPLEFT", plate, "BOTTOMLEFT", 4 + (i - 1) * 9, -4)
            if i == 1 then
                dot:SetColorTexture(0.82, 0.18, 0.22, 0.92)
            elseif i == 2 then
                dot:SetColorTexture(0.55, 0.24, 0.90, 0.92)
            elseif i == 3 then
                dot:SetColorTexture(0.22, 0.56, 0.95, 0.92)
            else
                dot:SetColorTexture(0.25, 0.78, 0.34, 0.92)
            end
            plate._dots[#plate._dots + 1] = dot
        end

        root._plates[#root._plates + 1] = plate
        return plate
    end

    CreatePlate(1, "preview_np_friendly", "Friendly",       92, false)
    CreatePlate(2, "preview_np_target",   "Hostile target", 48, true)
    CreatePlate(3, "preview_np_boss",     "Marked boss",    71, true)

    function root:Refresh()
        if not self:IsShown() then return end
        local db = TomoModDB and TomoModDB.nameplates
        if not db then return end

        local stageW = self:GetWidth() or 0
        local stageH = self:GetHeight() or 0
        if stageW < 200 or stageH < 120 then return end

        local sourceW = NPPreviewClamp(db.width, 120, 300, 170)
        local sourceH = NPPreviewClamp(db.height, 8, 40, 12)
        local castH = NPPreviewClamp(db.castbarHeight, 3, 14, 5)

        -- Cadre's canvas is considerably larger than the Options card.
        -- Keep the configured proportions, but cap the visual size so all
        -- three examples remain readable at once.
        local baseW = math.min(sourceW, math.max(130, (stageW - 84) * 0.38))
        local baseH = math.min(sourceH, 28)

        local margin = math.max(22, math.floor(stageW * 0.035))
        local gap = math.max(26, math.floor(stageW * 0.055))

        local specs = {
            {
                plate = self._plates[1],
                w = baseW,
                h = baseH,
                x = margin,
                y = -82,
                colorKey = "friendly",
                fallback = { 0.38, 0.88, 0.72 },
            },
            {
                plate = self._plates[2],
                w = math.min(baseW + 28, (stageW - margin * 2 - gap) * 0.48),
                h = baseH + 2,
                x = stageW - margin,
                y = -78,
                right = true,
                colorKey = "hostile",
                fallback = { 0.95, 0.35, 0.28 },
            },
            {
                plate = self._plates[3],
                w = math.min(baseW + 18, stageW - margin * 2),
                h = baseH,
                x = stageW * 0.5,
                y = math.min(-158, -stageH * 0.52),
                center = true,
                colorKey = "boss",
                fallback = { 0.96, 0.70, 0.26 },
            },
        }

        for _, spec in ipairs(specs) do
            local plate = spec.plate
            local r, g, b = NPPreviewColor(db, spec.colorKey, spec.fallback)

            plate:ClearAllPoints()
            if spec.right then
                plate:SetPoint("TOPRIGHT", self, "TOPLEFT", spec.x, spec.y)
            elseif spec.center then
                plate:SetPoint("TOP", self, "TOPLEFT", spec.x, spec.y)
            else
                plate:SetPoint("TOPLEFT", self, "TOPLEFT", spec.x, spec.y)
            end
            plate:SetSize(spec.w, spec.h + castH + 12)
            plate:SetBackdropBorderColor(r, g, b, plate._hostile and 0.72 or 0.46)

            plate._hp:SetHeight(spec.h)
            plate._hp:SetStatusBarColor(r, g, b, 0.96)
            plate._hpBg:SetColorTexture(r * 0.12, g * 0.12, b * 0.12, 1)

            plate._name:SetTextColor(r, g, b, 1)
            plate._name:SetShown(db.showName ~= false)
            plate._name:SetFont(
                "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf",
                NPPreviewClamp(db.nameFontSize, 6, 20, 10),
                "OUTLINE")

            plate._pct:SetShown(db.showHealthText ~= false)
            plate._pct:SetText((plate._value or 0) .. "%")

            plate._cast:SetHeight(castH)
            plate._cast:SetShown(db.showCastbar ~= false and plate._hostile)

            local showDots = db.showAuras ~= false or db.showEnemyBuffs ~= false
            for _, dot in ipairs(plate._dots) do
                dot:SetShown(showDots)
            end
        end
    end

    root:SetScript("OnSizeChanged", function(self)
        if not self:IsShown() then return end
        C_Timer.After(0, function()
            if self and self:IsShown() and self.Refresh then self:Refresh() end
        end)
    end)

    nameplateCadreParity = root
    return root
end

local function ShowNameplateCadreParity()
    if SubjectKind() ~= "nameplate" or not S.state.showFrameEditor then return end
    if not stageHost then return end

    local preview = CreateNameplateCadreParity(stageHost)

    -- Cadre intentionally uses the Options-style readability preview.
    -- Keep the Forge nameplate tree alive for Elements, but hidden here.
    if plateSubjectBase and plateSubjectBase.Hide then plateSubjectBase:Hide() end
    if subject and subject.Hide then subject:Hide() end

    preview:Show()
    preview:Refresh()
end

local function HideNameplateCadreParity(restoreForgePreview)
    if nameplateCadreParity then nameplateCadreParity:Hide() end

    if restoreForgePreview and SubjectKind() == "nameplate" then
        if plateSubjectBase and plateSubjectBase.Show then plateSubjectBase:Show() end
        if subject and subject.Show then subject:Show() end
        RebuildSubject()
    end
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
    focus = true,
    pet = true,
    targettarget = true,
    bossframe = true,
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

local BOSS_FRAME_FIELDS = {
    "width", "height", "spacing",
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
    elseif IsBoss() then
        defaults = TomoMod_Defaults and TomoMod_Defaults.unitFrames
            and TomoMod_Defaults.unitFrames.bossFrames
        fields = BOSS_FRAME_FIELDS
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
    if not IsPlate() and not IsBoss() then SyncLegacyUnitHeight(db) end
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
    elseif IsBoss() then
        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_width"], db.width or 200,
                    100, 350, 5, 0, function(v)
                        db.width = v
                        CommitFrameEdit()
                    end)
                return n
            end,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_boss_height"], db.height or 28,
                    16, 50, 2, 0, function(v)
                        db.height = v
                        CommitFrameEdit()
                    end)
                return n
            end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_boss_spacing"], db.spacing or 4,
            0, 20, 1, y, function(v)
                db.spacing = v
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

    if not IsBoss() then
        local _, ny = W.CreateSubLabel(c, L["af_frame_display"], y)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_show_name"], db.showName ~= false, y, function(v)
            db.showName = v
            CommitFrameEdit()
        end)
        y = ny
    end

    if not IsBoss() and db.showLevel ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_level"], db.showLevel ~= false, y, function(v)
            db.showLevel = v
            CommitFrameEdit()
        end)
        y = ny
    end

    if not IsBoss() and db.showHealthText ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_health_text"], db.showHealthText ~= false, y, function(v)
            db.showHealthText = v
            CommitFrameEdit()
        end)
        y = ny
    end

    if not IsBoss() and db.healthTextFormat ~= nil then
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
    elseif not IsBoss() then
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

-- =====================================================================
-- Astral Forge V2.1 - Cadre / Lot 2
-- Full structural + behaviour editor, backed by the SAME TomoModDB fields
-- as TomoMod_Options. Element offsets stay in Elements; bar textures and
-- absorb/castbar artwork stay in Bars.
-- =====================================================================

local AF_FONT_PATH = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\"
local AF_FONT_LIST = {
    { text = "Poppins Medium",      value = AF_FONT_PATH .. "Poppins-Medium.ttf" },
    { text = "Poppins SemiBold",    value = AF_FONT_PATH .. "Poppins-SemiBold.ttf" },
    { text = "Poppins Bold",        value = AF_FONT_PATH .. "Poppins-Bold.ttf" },
    { text = "Poppins Black",       value = AF_FONT_PATH .. "Poppins-Black.ttf" },
    { text = "Expressway",          value = AF_FONT_PATH .. "Expressway.TTF" },
    { text = "Accidental Pres.",    value = AF_FONT_PATH .. "accidental_pres.ttf" },
    { text = "Tomo",                value = AF_FONT_PATH .. "Tomo.ttf" },
    { text = "Friz Quadrata (WoW)", value = "Fonts\\FRIZQT__.TTF" },
    { text = "Arial Narrow (WoW)",  value = "Fonts\\ARIALN.TTF" },
    { text = "Morpheus (WoW)",      value = "Fonts\\MORPHEUS.TTF" },
}

local function V21RefreshAllUnitFrames()
    local UF = TomoMod_UnitFrames
    if UF and UF.RefreshAllUnits then UF.RefreshAllUnits() end
    local BF = TomoMod_BossFrames
    if BF and BF.RefreshAll then BF.RefreshAll() end
    RebuildSubject()
end

local function V21RefreshNameplateCVars()
    local NP = TomoMod_Nameplates
    if NP and NP.ApplySettings then NP.ApplySettings() end
    if NP and NP.RefreshAll then NP.RefreshAll() end
    RebuildSubject()
end

local function V21Separator(c, y)
    local _, ny = W.CreateSeparator(c, y)
    return ny
end

local function V21Color(c, label, color, y, cb)
    if type(color) ~= "table" then return y end
    local _, ny = W.CreateColorPicker(c, label, color, y, cb)
    return ny
end

local function BuildGlobalUnitFrameSettings(c, y)
    local g = TomoModDB and TomoModDB.unitFrames
    if not g then return y end

    local _, ny = W.CreateSectionHeader(c, L["af_v21_global_uf"], y, "G")
    y = ny
    local _, ny = W.CreateInfoText(c, L["af_v21_global_uf_info"], y)
    y = ny

    if g.enabled ~= nil and g.hideBlizzardFrames ~= nil then
        local _, ny = W.CreateCheckboxPair(c,
            L["opt_uf_enable"], g.enabled, y,
            function(v)
                g.enabled = v
                if TomoMod_Lifecycle then
                    TomoMod_Lifecycle.RequestReload("unitFrames")
                end
            end,
            L["opt_hide_blizzard"], g.hideBlizzardFrames,
            function(v)
                g.hideBlizzardFrames = v
                if TomoMod_Lifecycle then
                    TomoMod_Lifecycle.RequestReload("unitFrames")
                end
            end)
        y = ny
    end

    local _, ny = W.CreateDropdown(c, L["opt_font_family"], AF_FONT_LIST,
        g.fontFamily or g.font, y, function(v)
            g.fontFamily = v
            g.font = v
            V21RefreshAllUnitFrames()
        end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_global_font_size"],
        g.fontSize or 12, 8, 20, 1, y, function(v)
            g.fontSize = v
            V21RefreshAllUnitFrames()
        end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_module_reload"], y)
    y = ny
    return y
end

local function BuildUnitFrameCadre(c, y, db, unitKey)
    if not db then return y end

    local _, ny = W.CreateSectionHeader(c, L["af_frame_dimensions"], y, "D")
    y = ny

    if db.enabled ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_enable"], db.enabled, y, function(v)
            db.enabled = v
            if TomoMod_Lifecycle then TomoMod_Lifecycle.RequestReload("unitFrames") end
            CommitFrameEdit()
        end)
        y = ny
    end

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
            local _, n = W.CreateSlider(col, L["opt_health_height"],
                db.healthHeight or 38, 10, 80, 2, 0, function(v)
                    db.healthHeight = v
                    SyncLegacyUnitHeight(db)
                    CommitFrameEdit()
                end)
            return n
        end)
    y = ny

    if db.powerHeight ~= nil then
        local _, ny = W.CreateSlider(c, L["opt_power_height"],
            db.powerHeight or 0, 0, 20, 1, y, function(v)
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

    y = V21Separator(c, y)
    local _, ny = W.CreateSubLabel(c, L["af_v21_frame_behavior"], y)
    y = ny

    if db.showName ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_name"], db.showName, y, function(v)
            db.showName = v; CommitFrameEdit()
        end)
        y = ny
    end

    if db.nameTruncate ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_name_truncate"],
            db.nameTruncate, y, function(v)
                db.nameTruncate = v; CommitFrameEdit()
            end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_name_truncate_length"],
            db.nameTruncateLength or 20, 5, 40, 1, y, function(v)
                db.nameTruncateLength = v; CommitFrameEdit()
            end)
        y = ny
    end

    if db.showLevel ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_level"], db.showLevel, y, function(v)
            db.showLevel = v; CommitFrameEdit()
        end)
        y = ny
    end

    if db.showHealthText ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_health_text"],
            db.showHealthText, y, function(v)
                db.showHealthText = v; CommitFrameEdit()
            end)
        y = ny
    end

    if db.healthTextFormat then
        local _, ny = W.CreateDropdown(c, L["opt_health_format"], {
            { text = L["fmt_current"],         value = "current" },
            { text = L["fmt_percent"],         value = "percent" },
            { text = L["fmt_current_percent"], value = "current_percent" },
            { text = L["fmt_current_max"],     value = "current_max" },
        }, db.healthTextFormat, y, function(v)
            db.healthTextFormat = v; CommitFrameEdit()
        end)
        y = ny
    end

    if db.useFactionColor ~= nil then
        local _, ny = W.CreateCheckboxPair(c,
            L["opt_class_color_uf"], db.useClassColor, y,
            function(v) db.useClassColor = v; CommitFrameEdit() end,
            L["opt_faction_color"], db.useFactionColor,
            function(v) db.useFactionColor = v; CommitFrameEdit() end)
        y = ny
    elseif db.useClassColor ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_class_color_uf"],
            db.useClassColor, y, function(v)
                db.useClassColor = v; CommitFrameEdit()
            end)
        y = ny
    end

    if db.useNameplateColors ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_use_nameplate_colors"],
            db.useNameplateColors, y, function(v)
                db.useNameplateColors = v; CommitFrameEdit()
            end)
        y = ny
    end

    if db.showAbsorb ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_absorb"],
            db.showAbsorb, y, function(v)
                db.showAbsorb = v; CommitFrameEdit()
            end)
        y = ny
    end

    if db.showThreat ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_threat"],
            db.showThreat, y, function(v)
                db.showThreat = v; CommitFrameEdit()
            end)
        y = ny
    end

    if db.showLeaderIcon ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_leader_icon"],
            db.showLeaderIcon, y, function(v)
                db.showLeaderIcon = v; CommitFrameEdit()
            end)
        y = ny
    end

    if type(db.threatText) == "table" then
        y = V21Separator(c, y)
        local _, ny = W.CreateSubLabel(c, L["section_threat_text"], y)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_threat_text_enable"],
            db.threatText.enabled, y, function(v)
                db.threatText.enabled = v; CommitFrameEdit()
            end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_threat_text_font_size"],
            db.threatText.fontSize or 13, 8, 24, 1, y, function(v)
                db.threatText.fontSize = v; CommitFrameEdit()
            end)
        y = ny
    end

    if type(db.auras) == "table" then
        y = V21Separator(c, y)
        local _, ny = W.CreateSubLabel(c, L["af_v21_auras"], y)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_auras_enable"],
            db.auras.enabled, y, function(v)
                db.auras.enabled = v; CommitFrameEdit()
            end)
        y = ny

        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_auras_max"],
                    db.auras.maxAuras or 6, 1, 16, 1, 0, function(v)
                        db.auras.maxAuras = v; CommitFrameEdit()
                    end)
                return n
            end,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_auras_size"],
                    db.auras.size or 24, 16, 48, 1, 0, function(v)
                        db.auras.size = v; CommitFrameEdit()
                    end)
                return n
            end)
        y = ny

        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_auras_spacing"],
                    db.auras.spacing or 3, 0, 16, 1, 0, function(v)
                        db.auras.spacing = v; CommitFrameEdit()
                    end)
                return n
            end,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_auras_per_row"],
                    db.auras.perRow or 6, 1, 8, 1, 0, function(v)
                        db.auras.perRow = v; CommitFrameEdit()
                    end)
                return n
            end)
        y = ny

        local _, ny = W.CreateDropdown(c, L["opt_auras_type"], {
            { text = L["aura_harmful"], value = "HARMFUL" },
            { text = L["aura_helpful"], value = "HELPFUL" },
            { text = L["aura_all"],     value = "ALL" },
        }, db.auras.type or "HARMFUL", y, function(v)
            db.auras.type = v; CommitFrameEdit()
        end)
        y = ny

        local _, ny = W.CreateDropdown(c, L["opt_auras_direction"], {
            { text = L["aura_dir_right"], value = "RIGHT" },
            { text = L["aura_dir_left"],  value = "LEFT" },
        }, db.auras.growDirection or "RIGHT", y, function(v)
            db.auras.growDirection = v; CommitFrameEdit()
        end)
        y = ny

        local _, ny = W.CreateDropdown(c, L["opt_auras_direction_v"], {
            { text = L["aura_dir_down"], value = "DOWN" },
            { text = L["aura_dir_up"],   value = "UP" },
        }, db.auras.growVertical or "DOWN", y, function(v)
            db.auras.growVertical = (v == "UP") and "UP" or nil
            CommitFrameEdit()
        end)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_auras_only_mine"],
            db.auras.showOnlyMine, y, function(v)
                db.auras.showOnlyMine = v; CommitFrameEdit()
            end)
        y = ny
    end

    if type(db.enemyBuffs) == "table"
        and (unitKey == "target" or unitKey == "focus") then
        y = V21Separator(c, y)
        local _, ny = W.CreateSubLabel(c, L["af_v21_enemy_buffs"], y)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_enemy_buffs_enable"],
            db.enemyBuffs.enabled, y, function(v)
                db.enemyBuffs.enabled = v; CommitFrameEdit()
            end)
        y = ny

        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_enemy_buffs_max"],
                    db.enemyBuffs.maxAuras or 3, 1, 12, 1, 0, function(v)
                        db.enemyBuffs.maxAuras = v; CommitFrameEdit()
                    end)
                return n
            end,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_enemy_buffs_size"],
                    db.enemyBuffs.size or 18, 14, 40, 1, 0, function(v)
                        db.enemyBuffs.size = v; CommitFrameEdit()
                    end)
                return n
            end)
        y = ny

        local _, ny = W.CreateDropdown(c, L["opt_enemy_buffs_direction"], {
            { text = L["aura_dir_right"], value = "RIGHT" },
            { text = L["aura_dir_left"],  value = "LEFT" },
        }, db.enemyBuffs.growDirection or "RIGHT", y, function(v)
            db.enemyBuffs.growDirection = v; CommitFrameEdit()
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_enemy_buffs_per_row"],
            db.enemyBuffs.perRow or 3, 1, 8, 1, y, function(v)
                db.enemyBuffs.perRow = v; CommitFrameEdit()
            end)
        y = ny

        local _, ny = W.CreateDropdown(c, L["opt_enemy_buffs_row_orientation"], {
            { text = L["aura_dir_up"],   value = "UP" },
            { text = L["aura_dir_down"], value = "DOWN" },
        }, db.enemyBuffs.growVertical or "UP", y, function(v)
            db.enemyBuffs.growVertical = v; CommitFrameEdit()
        end)
        y = ny
    end

    local _, ny = W.CreateInfoText(c, L["af_v21_bar_note"], y)
    y = ny
    return y
end

local function BuildBossCadre(c, y, db)
    local _, ny = W.CreateSectionHeader(c, L["section_boss_frames"], y, "B")
    y = ny
    local _, ny = W.CreateInfoText(c, L["af_v21_boss_info"], y)
    y = ny

    if db.enabled ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_boss_enable"],
            db.enabled, y, function(v)
                db.enabled = v
                if TomoMod_Lifecycle then TomoMod_Lifecycle.RequestReload("bossFrames") end
                CommitFrameEdit()
            end)
        y = ny
    end

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_width"], db.width or 200,
                100, 350, 5, 0, function(v)
                    db.width = v; CommitFrameEdit()
                end)
            return n
        end,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_boss_height"], db.height or 28,
                16, 50, 2, 0, function(v)
                    db.height = v; CommitFrameEdit()
                end)
            return n
        end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_boss_spacing"],
        db.spacing or 4, 0, 20, 1, y, function(v)
            db.spacing = v; CommitFrameEdit()
        end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["af_v21_bar_note"], y)
    y = ny
    return y
end

local function BuildNameplateCadre(c, y, db)
    local _, ny = W.CreateSectionHeader(c, L["section_np_general"], y, "N")
    y = ny

    if db.enabled ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_enable"],
            db.enabled, y, function(v)
                db.enabled = v
                local NP = TomoMod_Nameplates
                if NP then
                    if v and NP.Enable then NP.Enable()
                    elseif not v and NP.Disable then NP.Disable() end
                end
                if TomoMod_Lifecycle then TomoMod_Lifecycle.RequestReload("nameplates") end
                RebuildSubject()
            end)
        y = ny
    end

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_width"], db.width or 156,
                60, 300, 5, 0, function(v)
                    db.width = v; CommitFrameEdit()
                end)
            return n
        end,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_health_height"], db.height or 17,
                6, 40, 1, 0, function(v)
                    db.height = v; CommitFrameEdit()
                end)
            return n
        end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_np_name_font_size"],
        db.nameFontSize or 10, 6, 20, 1, y, function(v)
            db.nameFontSize = v; CommitFrameEdit()
        end)
    y = ny

    y = V21Separator(c, y)
    local _, ny = W.CreateSubLabel(c, L["af_v21_frame_behavior"], y)
    y = ny

    if db.showName ~= nil and db.showLevel ~= nil then
        local _, ny = W.CreateCheckboxPair(c,
            L["opt_show_name"], db.showName, y,
            function(v) db.showName = v; CommitFrameEdit() end,
            L["opt_show_level"], db.showLevel,
            function(v) db.showLevel = v; CommitFrameEdit() end)
        y = ny
    end

    if db.showHealthText ~= nil and db.showClassification ~= nil then
        local _, ny = W.CreateCheckboxPair(c,
            L["opt_show_health_text"], db.showHealthText, y,
            function(v) db.showHealthText = v; CommitFrameEdit() end,
            L["opt_np_show_classification"], db.showClassification,
            function(v) db.showClassification = v; CommitFrameEdit() end)
        y = ny
    end

    if db.showThreat ~= nil and db.useClassColors ~= nil then
        local _, ny = W.CreateCheckboxPair(c,
            L["opt_show_threat"], db.showThreat, y,
            function(v) db.showThreat = v; CommitFrameEdit() end,
            L["opt_np_class_colors"], db.useClassColors,
            function(v) db.useClassColors = v; CommitFrameEdit() end)
        y = ny
    end

    if db.showAbsorb ~= nil and db.friendlyNameOnly ~= nil then
        local _, ny = W.CreateCheckboxPair(c,
            L["opt_np_show_absorb"], db.showAbsorb, y,
            function(v) db.showAbsorb = v; CommitFrameEdit() end,
            L["opt_np_friendly_name_only"], db.friendlyNameOnly,
            function(v) db.friendlyNameOnly = v; CommitFrameEdit() end)
        y = ny
    end

    if db.healthTextFormat then
        local _, ny = W.CreateDropdown(c, L["opt_health_format"], {
            { text = L["np_fmt_percent"],         value = "percent" },
            { text = L["np_fmt_current"],         value = "current" },
            { text = L["np_fmt_current_percent"], value = "current_percent" },
        }, db.healthTextFormat, y, function(v)
            db.healthTextFormat = v; CommitFrameEdit()
        end)
        y = ny
    end

    y = V21Separator(c, y)
    local _, ny = W.CreateSubLabel(c, L["af_v21_np_roles"], y)
    y = ny

    if db.friendlyRoleIcons ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_friendly_role_icons"],
            db.friendlyRoleIcons, y, function(v)
                db.friendlyRoleIcons = v; CommitFrameEdit()
            end)
        y = ny
    end

    if db.roleShowTank ~= nil and db.roleShowHealer ~= nil then
        local _, ny = W.CreateCheckboxPair(c,
            L["opt_np_role_show_tank"], db.roleShowTank, y,
            function(v) db.roleShowTank = v; CommitFrameEdit() end,
            L["opt_np_role_show_healer"], db.roleShowHealer,
            function(v) db.roleShowHealer = v; CommitFrameEdit() end)
        y = ny
    end

    if db.roleShowDps ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_role_show_dps"],
            db.roleShowDps, y, function(v)
                db.roleShowDps = v; CommitFrameEdit()
            end)
        y = ny
    end

    if db.roleIconSize ~= nil then
        local _, ny = W.CreateSlider(c, L["opt_np_role_icon_size"],
            db.roleIconSize, 16, 60, 2, y, function(v)
                db.roleIconSize = v; CommitFrameEdit()
            end)
        y = ny
    end

    y = V21Separator(c, y)
    local _, ny = W.CreateSubLabel(c, L["section_castbar"], y)
    y = ny

    if db.showCastbar ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_show_castbar"],
            db.showCastbar, y, function(v)
                db.showCastbar = v; CommitFrameEdit()
            end)
        y = ny
    end

    if db.castbarHeight ~= nil then
        local _, ny = W.CreateSlider(c, L["opt_np_castbar_height"],
            db.castbarHeight, 4, 20, 1, y, function(v)
                db.castbarHeight = v; CommitFrameEdit()
            end)
        y = ny
    end

    y = V21Separator(c, y)
    local _, ny = W.CreateSubLabel(c, L["af_v21_auras"], y)
    y = ny

    if db.showAuras ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_show_auras"],
            db.showAuras, y, function(v)
                db.showAuras = v; CommitFrameEdit()
            end)
        y = ny
    end

    if db.showOnlyMyAuras ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_only_my_debuffs"],
            db.showOnlyMyAuras, y, function(v)
                db.showOnlyMyAuras = v; CommitFrameEdit()
            end)
        y = ny
    end

    if db.auraSize ~= nil and db.maxAuras ~= nil then
        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_aura_size"],
                    db.auraSize, 12, 36, 1, 0, function(v)
                        db.auraSize = v; CommitFrameEdit()
                    end)
                return n
            end,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_max_auras"],
                    db.maxAuras, 1, 10, 1, 0, function(v)
                        db.maxAuras = v; CommitFrameEdit()
                    end)
                return n
            end)
        y = ny
    end

    y = V21Separator(c, y)
    local _, ny = W.CreateSubLabel(c, L["af_v21_enemy_buffs"], y)
    y = ny

    if db.showEnemyBuffs ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_show_enemy_buffs"],
            db.showEnemyBuffs, y, function(v)
                db.showEnemyBuffs = v; CommitFrameEdit()
            end)
        y = ny
    end

    if db.enemyBuffSize ~= nil and db.maxEnemyBuffs ~= nil then
        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_enemy_buff_size"],
                    db.enemyBuffSize, 12, 36, 1, 0, function(v)
                        db.enemyBuffSize = v; CommitFrameEdit()
                    end)
                return n
            end,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_max_enemy_buffs"],
                    db.maxEnemyBuffs, 1, 8, 1, 0, function(v)
                        db.maxEnemyBuffs = v; CommitFrameEdit()
                    end)
                return n
            end)
        y = ny
    end

    if db.enemyBuffYOffset ~= nil then
        local _, ny = W.CreateSlider(c, L["opt_np_enemy_buff_y_offset"],
            db.enemyBuffYOffset, 0, 20, 1, y, function(v)
                db.enemyBuffYOffset = v; CommitFrameEdit()
            end)
        y = ny
    end

    y = V21Separator(c, y)
    local _, ny = W.CreateSubLabel(c, L["af_v21_np_advanced"], y)
    y = ny

    if db.selectedAlpha ~= nil and db.unselectedAlpha ~= nil then
        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_selected_alpha"],
                    db.selectedAlpha, 0.3, 1.0, 0.05, 0,
                    function(v) db.selectedAlpha = v end, "%.2f")
                return n
            end,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_unselected_alpha"],
                    db.unselectedAlpha, 0.3, 1.0, 0.05, 0,
                    function(v) db.unselectedAlpha = v end, "%.2f")
                return n
            end)
        y = ny
    end

    if db.overlapV ~= nil and db.topInset ~= nil then
        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_overlap"],
                    db.overlapV, 0.5, 3.0, 0.1, 0,
                    function(v)
                        db.overlapV = v; V21RefreshNameplateCVars()
                    end, "%.1f")
                return n
            end,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_top_inset"],
                    db.topInset, 0.01, 0.5, 0.005, 0,
                    function(v)
                        db.topInset = v; V21RefreshNameplateCVars()
                    end, "%.3f")
                return n
            end)
        y = ny
    end

    if type(db.colors) == "table" then
        y = V21Separator(c, y)
        local _, ny = W.CreateSubLabel(c, L["af_v21_np_colors"], y)
        y = ny

        local colorKeys = {
            { "color_hostile",         "hostile" },
            { "color_neutral",         "neutral" },
            { "color_friendly",        "friendly" },
            { "color_tapped",          "tapped" },
            { "color_focus",           "focus" },
            { "color_caster",          "caster" },
            { "color_miniboss",        "miniboss" },
            { "color_enemy_in_combat", "enemyInCombat" },
        }
        for _, rec in ipairs(colorKeys) do
            local key = rec[2]
            if type(db.colors[key]) == "table" then
                y = V21Color(c, L[rec[1]], db.colors[key], y, function(r, g, b)
                    db.colors[key] = { r = r, g = g, b = b }
                    CommitFrameEdit()
                end)
            end
        end

        local _, ny = W.CreateSubLabel(c, L["af_v21_np_classification"], y)
        y = ny

        if db.useClassificationColors ~= nil then
            local _, ny = W.CreateCheckbox(c, L["opt_np_use_classification"],
                db.useClassificationColors, y, function(v)
                    db.useClassificationColors = v; CommitFrameEdit()
                end)
            y = ny
        end

        local classColors = {
            { "color_boss",    "boss" },
            { "color_elite",   "elite" },
            { "color_rare",    "rare" },
            { "color_normal",  "normal" },
            { "color_trivial", "trivial" },
        }
        for _, rec in ipairs(classColors) do
            local key = rec[2]
            if type(db.colors[key]) == "table" then
                y = V21Color(c, L[rec[1]], db.colors[key], y, function(r, g, b)
                    db.colors[key] = { r = r, g = g, b = b }
                    CommitFrameEdit()
                end)
            end
        end
    end

    if type(db.tankColors) == "table" then
        y = V21Separator(c, y)
        local _, ny = W.CreateSubLabel(c, L["af_v21_np_tank"], y)
        y = ny

        if db.tankMode ~= nil then
            local _, ny = W.CreateCheckbox(c, L["opt_np_tank_mode"],
                db.tankMode, y, function(v)
                    db.tankMode = v; CommitFrameEdit()
                end)
            y = ny
        end

        local tankColors = {
            { "color_no_threat",      "noThreat" },
            { "color_low_threat",     "lowThreat" },
            { "color_has_threat",     "hasThreat" },
            { "color_dps_has_aggro",  "dpsHasAggro" },
            { "color_dps_near_aggro", "dpsNearAggro" },
        }
        for _, rec in ipairs(tankColors) do
            local key = rec[2]
            if type(db.tankColors[key]) == "table" then
                y = V21Color(c, L[rec[1]], db.tankColors[key], y, function(r, g, b)
                    db.tankColors[key] = { r = r, g = g, b = b }
                    CommitFrameEdit()
                end)
            end
        end
    end

    local _, ny = W.CreateInfoText(c, L["af_v21_bar_note"], y)
    y = ny
    return y
end

function S.BuildFrameEditorV21(c)
    local db = Settings()
    local y = -8

    local _, ny = W.CreateSectionHeader(c, L["af_frame_title"], y, "F")
    y = ny
    local _, ny = W.CreateInfoText(c, L["af_frame_info"], y)
    y = ny

    if not db then
        local _, ny = W.CreateInfoText(c, L["af_frame_unavailable"], y)
        y = ny
        c:SetHeight(math.abs(y) + 40)
        return
    end

    local kind = SubjectKind()

    if kind == "unitframe" then
        y = BuildGlobalUnitFrameSettings(c, y)
        y = V21Separator(c, y)
        y = BuildUnitFrameCadre(c, y, db, S.state.subject)

    elseif kind == "bossframe" then
        y = BuildGlobalUnitFrameSettings(c, y)
        y = V21Separator(c, y)
        y = BuildBossCadre(c, y, db)

    elseif kind == "nameplate" then
        y = BuildNameplateCadre(c, y, db)

    else
        local _, ny = W.CreateInfoText(c, L["af_frame_unavailable"], y)
        y = ny
    end

    c:SetHeight(math.abs(y) + 56)
end

-- ---------------------------------------------------------------------
-- Cadre UX refinement (follow-up)
-- ---------------------------------------------------------------------
local function V22HideFramePreviewNoise()
    if not canvas then return end
    canvas.selected = nil
    if type(canvas.handles) == "table" then
        for _, h in pairs(canvas.handles) do
            if h.Hide then h:Hide() end
            if h.EnableMouse then h:EnableMouse(false) end
        end
    end
end

local function V22EnsureFramePreview()
    if not (canvas and stageHost) then return end

    local kind = SubjectKind()
    if kind == "nameplate" then
        if (not plateSubjectBase) or (not subject)
            or (plateSubjectBase.IsShown and not plateSubjectBase:IsShown())
            or (subject.IsShown and not subject:IsShown()) then
            RebuildSubject()
        else
            if plateSubjectBase.SetParent and plateSubjectBase:GetParent() ~= canvas.stage then
                plateSubjectBase:SetParent(canvas.stage)
            end
            if subject.SetParent and subject:GetParent() ~= plateSubjectBase then
                subject:SetParent(plateSubjectBase)
            end
            plateSubjectBase:Show()
            subject:Show()
        end
    elseif kind == "unitframe" or kind == "bossframe" then
        if (not subject) or (subject.IsShown and not subject:IsShown()) then
            RebuildSubject()
        else
            subject:Show()
        end
    end
end

local function V22RestoreCanvasInteractivity()
    if not canvas or type(canvas.handles) ~= "table" then return end
    for _, h in pairs(canvas.handles) do
        if h.EnableMouse then h:EnableMouse(true) end
    end
end

local function V22CommitFrameEdit()
    CommitFrameEdit()
    if SubjectKind() == "nameplate" and S.state.showFrameEditor then
        ShowNameplateCadreParity()
    end
    V22HideFramePreviewNoise()
end

local function V22GetFrameSections()
    local kind = SubjectKind()
    local subject = S.state.subject

    if kind == "unitframe" then
        local t = {
            { id = "global",      label = L["af_v22_sec_global"] },
            { id = "dimensions",  label = L["af_v22_sec_dimensions"] },
            { id = "display",     label = L["af_v22_sec_display"] },
            { id = "colors",      label = L["af_v22_sec_colors"] },
            { id = "auras",       label = L["af_v22_sec_auras"] },
        }
        if subject == "target" or subject == "focus" then
            table.insert(t, { id = "enemyBuffs", label = L["af_v22_sec_enemy_buffs"] })
        end
        return t
    elseif kind == "bossframe" then
        return {
            { id = "global",     label = L["af_v22_sec_global"] },
            { id = "dimensions", label = L["af_v22_sec_dimensions"] },
        }
    elseif kind == "nameplate" then
        return {
            { id = "dimensions",    label = L["af_v22_sec_dimensions"] },
            { id = "display",       label = L["af_v22_sec_display"] },
            { id = "roles",         label = L["af_v22_sec_roles"] },
            { id = "castbar",       label = L["af_v22_sec_castbar"] },
            { id = "auras",         label = L["af_v22_sec_auras"] },
            { id = "enemyBuffs",    label = L["af_v22_sec_enemy_buffs"] },
            { id = "advanced",      label = L["af_v22_sec_advanced"] },
            { id = "contextColors", label = L["af_v22_sec_context_colors"] },
            { id = "classification",label = L["af_v22_sec_classification"] },
            { id = "tank",          label = L["af_v22_sec_tank"] },
        }
    end

    return {
        { id = "dimensions", label = L["af_v22_sec_dimensions"] },
    }
end

local function V22EnsureFrameSection()
    local sections = V22GetFrameSections()
    local current = S.state.frameSection
    for _, sec in ipairs(sections) do
        if sec.id == current then
            return sections, current
        end
    end
    current = sections[1] and sections[1].id or nil
    S.state.frameSection = current
    return sections, current
end

local function V22CreateSidebarButton(parent, idx)
    parent._afFrameButtons = parent._afFrameButtons or {}
    local b = parent._afFrameButtons[idx]
    if b then return b end

    b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetHeight(28)
    b:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    b:SetBackdropColor(0.040, 0.048, 0.065, 1)
    b:SetBackdropBorderColor(BRAND[1], BRAND[2], BRAND[3], 0.22)

    local fs = b:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT_BOLD, 11, "")
    fs:SetPoint("LEFT", 10, 0)
    fs:SetJustifyH("LEFT")
    fs:SetTextColor(0.78, 0.82, 0.90, 1)
    b._label = fs

    parent._afFrameButtons[idx] = b
    return b
end

local function V22BuildFrameSidebar()
    if not sidebarList then return end

    for _, row in pairs(rowButtons or {}) do
        if row and row.Hide then row:Hide() end
    end

    local sections, active = V22EnsureFrameSection()
    local previous
    for i, sec in ipairs(sections) do
        local b = V22CreateSidebarButton(sidebarList, i)
        b:ClearAllPoints()
        if previous then
            b:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -6)
        else
            b:SetPoint("TOPLEFT", 6, -4)
        end
        b:SetPoint("TOPRIGHT", -6, 0)
        b._label:SetText(sec.label)

        local on = sec.id == active
        b:SetBackdropColor(
            on and BRAND[1] or 0.040,
            on and BRAND[2] or 0.048,
            on and BRAND[3] or 0.065,
            on and 0.18 or 1)
        b:SetBackdropBorderColor(BRAND[1], BRAND[2], BRAND[3], on and 0.95 or 0.22)
        b._label:SetTextColor(
            on and 1 or 0.78,
            on and 1 or 0.82,
            on and 1 or 0.90,
            1)

        b:SetScript("OnClick", function()
            S.state.frameSection = sec.id
            S.RebuildSidebar()
            S.RebuildInspector()
            V22HideFramePreviewNoise()
        end)
        b:Show()
        previous = b
    end

    if sidebarList._afFrameButtons then
        for i = #sections + 1, #sidebarList._afFrameButtons do
            sidebarList._afFrameButtons[i]:Hide()
        end
    end
end

local function V22HideFrameSidebarButtons()
    if sidebarList and sidebarList._afFrameButtons then
        for _, b in ipairs(sidebarList._afFrameButtons) do
            if b then b:Hide() end
        end
    end
end

local function V22SectionHeader(c, y, text, icon)
    local _, ny = W.CreateSectionHeader(c, text, y, icon or "S")
    return ny
end

local function V22BuildUnitDimensions(c, y, db)
    y = V22SectionHeader(c, y, L["af_v22_sec_dimensions"], "D")

    if db.enabled ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_enable"], db.enabled, y, function(v)
            db.enabled = v
            if TomoMod_Lifecycle then TomoMod_Lifecycle.RequestReload("unitFrames") end
            V22CommitFrameEdit()
        end)
        y = ny
    end

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_width"], db.width or 220,
                80, 400, 5, 0, function(v)
                    db.width = v
                    V22CommitFrameEdit()
                end)
            return n
        end,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_health_height"], db.healthHeight or 38,
                10, 80, 2, 0, function(v)
                    db.healthHeight = v
                    SyncLegacyUnitHeight(db)
                    V22CommitFrameEdit()
                end)
            return n
        end)
    y = ny

    if db.powerHeight ~= nil or db.infoBarHeight ~= nil then
        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                if db.powerHeight ~= nil then
                    local _, n = W.CreateSlider(col, L["opt_power_height"], db.powerHeight or 0,
                        0, 20, 1, 0, function(v)
                            db.powerHeight = v
                            SyncLegacyUnitHeight(db)
                            V22CommitFrameEdit()
                        end)
                    return n
                end
                return 0
            end,
            function(col)
                if db.infoBarHeight ~= nil then
                    local _, n = W.CreateSlider(col, L["af_frame_info_height"], db.infoBarHeight or 0,
                        0, 30, 1, 0, function(v)
                            db.infoBarHeight = v
                            V22CommitFrameEdit()
                        end)
                    return n
                end
                return 0
            end)
        y = ny
    end

    return y
end

local function V22BuildUnitDisplay(c, y, db)
    y = V22SectionHeader(c, y, L["af_v22_sec_display"], "V")

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            if db.showName ~= nil then
                local _, n = W.CreateCheckbox(col, L["opt_show_name"], db.showName, 0, function(v)
                    db.showName = v
                    V22CommitFrameEdit()
                end)
                return n
            end
            return 0
        end,
        function(col)
            if db.showLevel ~= nil then
                local _, n = W.CreateCheckbox(col, L["opt_show_level"], db.showLevel, 0, function(v)
                    db.showLevel = v
                    V22CommitFrameEdit()
                end)
                return n
            end
            return 0
        end)
    y = ny

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            if db.showHealthText ~= nil then
                local _, n = W.CreateCheckbox(col, L["opt_show_health_text"], db.showHealthText, 0, function(v)
                    db.showHealthText = v
                    V22CommitFrameEdit()
                end)
                return n
            end
            return 0
        end,
        function(col)
            if db.showLeaderIcon ~= nil then
                local _, n = W.CreateCheckbox(col, L["opt_show_leader_icon"], db.showLeaderIcon, 0, function(v)
                    db.showLeaderIcon = v
                    V22CommitFrameEdit()
                end)
                return n
            end
            return 0
        end)
    y = ny

    if db.healthTextFormat ~= nil then
        local _, ny = W.CreateDropdown(c, L["opt_health_format"], {
            { text = L["fmt_current"],         value = "current" },
            { text = L["fmt_percent"],         value = "percent" },
            { text = L["fmt_current_percent"], value = "current_percent" },
            { text = L["fmt_current_max"],     value = "current_max" },
        }, db.healthTextFormat, y, function(v)
            db.healthTextFormat = v
            V22CommitFrameEdit()
        end)
        y = ny
    end

    if db.nameTruncate ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_name_truncate"], db.nameTruncate, y, function(v)
            db.nameTruncate = v
            V22CommitFrameEdit()
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_name_truncate_length"], db.nameTruncateLength or 20,
            5, 40, 1, y, function(v)
                db.nameTruncateLength = v
                V22CommitFrameEdit()
            end)
        y = ny
    end

    return y
end

local function V22BuildUnitColors(c, y, db)
    y = V22SectionHeader(c, y, L["af_v22_sec_colors"], "C")

    if db.useClassColor ~= nil and db.useFactionColor ~= nil then
        local _, ny = W.CreateCheckboxPair(c,
            L["opt_class_color_uf"], db.useClassColor, y,
            function(v) db.useClassColor = v; V22CommitFrameEdit() end,
            L["opt_faction_color"], db.useFactionColor,
            function(v) db.useFactionColor = v; V22CommitFrameEdit() end)
        y = ny
    elseif db.useClassColor ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_class_color_uf"], db.useClassColor, y, function(v)
            db.useClassColor = v
            V22CommitFrameEdit()
        end)
        y = ny
    end

    if db.useNameplateColors ~= nil and db.showAbsorb ~= nil then
        local _, ny = W.CreateCheckboxPair(c,
            L["opt_use_nameplate_colors"], db.useNameplateColors, y,
            function(v) db.useNameplateColors = v; V22CommitFrameEdit() end,
            L["opt_show_absorb"], db.showAbsorb,
            function(v) db.showAbsorb = v; V22CommitFrameEdit() end)
        y = ny
    elseif db.showAbsorb ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_absorb"], db.showAbsorb, y, function(v)
            db.showAbsorb = v
            V22CommitFrameEdit()
        end)
        y = ny
    end

    if db.showThreat ~= nil and db.showLeaderIcon ~= nil then
        local _, ny = W.CreateCheckboxPair(c,
            L["opt_show_threat"], db.showThreat, y,
            function(v) db.showThreat = v; V22CommitFrameEdit() end,
            L["opt_show_leader_icon"], db.showLeaderIcon,
            function(v) db.showLeaderIcon = v; V22CommitFrameEdit() end)
        y = ny
    elseif db.showThreat ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_threat"], db.showThreat, y, function(v)
            db.showThreat = v
            V22CommitFrameEdit()
        end)
        y = ny
    end

    if type(db.threatText) == "table" then
        local _, ny = W.CreateCheckbox(c, L["opt_threat_text_enable"], db.threatText.enabled, y, function(v)
            db.threatText.enabled = v
            V22CommitFrameEdit()
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_threat_text_font_size"], db.threatText.fontSize or 13,
            8, 24, 1, y, function(v)
                db.threatText.fontSize = v
                V22CommitFrameEdit()
            end)
        y = ny
    end

    return y
end

local function V22BuildUnitAuras(c, y, db)
    y = V22SectionHeader(c, y, L["af_v22_sec_auras"], "A")
    if type(db.auras) ~= "table" then return y end

    local _, ny = W.CreateCheckbox(c, L["opt_auras_enable"], db.auras.enabled, y, function(v)
        db.auras.enabled = v
        V22CommitFrameEdit()
    end)
    y = ny

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_auras_max"], db.auras.maxAuras or 6,
                1, 16, 1, 0, function(v)
                    db.auras.maxAuras = v
                    V22CommitFrameEdit()
                end)
            return n
        end,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_auras_size"], db.auras.size or 24,
                16, 48, 1, 0, function(v)
                    db.auras.size = v
                    V22CommitFrameEdit()
                end)
            return n
        end)
    y = ny

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_auras_spacing"], db.auras.spacing or 3,
                0, 16, 1, 0, function(v)
                    db.auras.spacing = v
                    V22CommitFrameEdit()
                end)
            return n
        end,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_auras_per_row"], db.auras.perRow or 6,
                1, 8, 1, 0, function(v)
                    db.auras.perRow = v
                    V22CommitFrameEdit()
                end)
            return n
        end)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_auras_type"], {
        { text = L["aura_harmful"], value = "HARMFUL" },
        { text = L["aura_helpful"], value = "HELPFUL" },
        { text = L["aura_all"],     value = "ALL" },
    }, db.auras.type or "HARMFUL", y, function(v)
        db.auras.type = v
        V22CommitFrameEdit()
    end)
    y = ny

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, n = W.CreateDropdown(col, L["opt_auras_direction"], {
                { text = L["aura_dir_right"], value = "RIGHT" },
                { text = L["aura_dir_left"],  value = "LEFT" },
            }, db.auras.growDirection or "RIGHT", 0, function(v)
                db.auras.growDirection = v
                V22CommitFrameEdit()
            end)
            return n
        end,
        function(col)
            local _, n = W.CreateDropdown(col, L["opt_auras_direction_v"], {
                { text = L["aura_dir_down"], value = "DOWN" },
                { text = L["aura_dir_up"],   value = "UP" },
            }, db.auras.growVertical or "DOWN", 0, function(v)
                db.auras.growVertical = (v == "UP") and "UP" or nil
                V22CommitFrameEdit()
            end)
            return n
        end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_auras_only_mine"], db.auras.showOnlyMine, y, function(v)
        db.auras.showOnlyMine = v
        V22CommitFrameEdit()
    end)
    y = ny
    return y
end

local function V22BuildUnitEnemyBuffs(c, y, db)
    if type(db.enemyBuffs) ~= "table" then return y end
    y = V22SectionHeader(c, y, L["af_v22_sec_enemy_buffs"], "E")

    local _, ny = W.CreateCheckbox(c, L["opt_enemy_buffs_enable"], db.enemyBuffs.enabled, y, function(v)
        db.enemyBuffs.enabled = v
        V22CommitFrameEdit()
    end)
    y = ny

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_enemy_buffs_max"], db.enemyBuffs.maxAuras or 3,
                1, 12, 1, 0, function(v)
                    db.enemyBuffs.maxAuras = v
                    V22CommitFrameEdit()
                end)
            return n
        end,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_enemy_buffs_size"], db.enemyBuffs.size or 18,
                14, 40, 1, 0, function(v)
                    db.enemyBuffs.size = v
                    V22CommitFrameEdit()
                end)
            return n
        end)
    y = ny

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, n = W.CreateDropdown(col, L["opt_enemy_buffs_direction"], {
                { text = L["aura_dir_right"], value = "RIGHT" },
                { text = L["aura_dir_left"],  value = "LEFT" },
            }, db.enemyBuffs.growDirection or "RIGHT", 0, function(v)
                db.enemyBuffs.growDirection = v
                V22CommitFrameEdit()
            end)
            return n
        end,
        function(col)
            local _, n = W.CreateDropdown(col, L["opt_enemy_buffs_row_orientation"], {
                { text = L["aura_dir_up"],   value = "UP" },
                { text = L["aura_dir_down"], value = "DOWN" },
            }, db.enemyBuffs.growVertical or "UP", 0, function(v)
                db.enemyBuffs.growVertical = v
                V22CommitFrameEdit()
            end)
            return n
        end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_enemy_buffs_per_row"], db.enemyBuffs.perRow or 3,
        1, 8, 1, y, function(v)
            db.enemyBuffs.perRow = v
            V22CommitFrameEdit()
        end)
    y = ny
    return y
end

local function V22BuildBossDimensions(c, y, db)
    y = V22SectionHeader(c, y, L["af_v22_sec_dimensions"], "B")
    local _, ny = W.CreateInfoText(c, L["af_v21_boss_info"], y)
    y = ny

    if db.enabled ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_boss_enable"], db.enabled, y, function(v)
            db.enabled = v
            if TomoMod_Lifecycle then TomoMod_Lifecycle.RequestReload("bossFrames") end
            V22CommitFrameEdit()
        end)
        y = ny
    end

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_width"], db.width or 200,
                100, 350, 5, 0, function(v)
                    db.width = v
                    V22CommitFrameEdit()
                end)
            return n
        end,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_boss_height"], db.height or 28,
                16, 50, 2, 0, function(v)
                    db.height = v
                    V22CommitFrameEdit()
                end)
            return n
        end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_boss_spacing"], db.spacing or 4,
        0, 20, 1, y, function(v)
            db.spacing = v
            V22CommitFrameEdit()
        end)
    y = ny
    return y
end

local function V22BuildNameplateDimensions(c, y, db)
    y = V22SectionHeader(c, y, L["af_v22_sec_dimensions"], "N")

    if db.enabled ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_enable"], db.enabled, y, function(v)
            db.enabled = v
            local NP = TomoMod_Nameplates
            if NP then
                if v and NP.Enable then NP.Enable()
                elseif not v and NP.Disable then NP.Disable() end
            end
            if TomoMod_Lifecycle then TomoMod_Lifecycle.RequestReload("nameplates") end
            RebuildSubject()
            ShowNameplateCadreParity()
            V22HideFramePreviewNoise()
        end)
        y = ny
    end

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_width"], db.width or 156,
                60, 300, 5, 0, function(v)
                    db.width = v
                    V22CommitFrameEdit()
                end)
            return n
        end,
        function(col)
            local _, n = W.CreateSlider(col, L["opt_health_height"], db.height or 17,
                6, 40, 1, 0, function(v)
                    db.height = v
                    V22CommitFrameEdit()
                end)
            return n
        end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_np_name_font_size"], db.nameFontSize or 10,
        6, 20, 1, y, function(v)
            db.nameFontSize = v
            V22CommitFrameEdit()
        end)
    y = ny
    return y
end

local function V22BuildNameplateDisplay(c, y, db)
    y = V22SectionHeader(c, y, L["af_v22_sec_display"], "V")

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, n = W.CreateCheckbox(col, L["opt_show_name"], db.showName, 0, function(v)
                db.showName = v
                V22CommitFrameEdit()
            end)
            return n
        end,
        function(col)
            local _, n = W.CreateCheckbox(col, L["opt_show_level"], db.showLevel, 0, function(v)
                db.showLevel = v
                V22CommitFrameEdit()
            end)
            return n
        end)
    y = ny

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, n = W.CreateCheckbox(col, L["opt_show_health_text"], db.showHealthText, 0, function(v)
                db.showHealthText = v
                V22CommitFrameEdit()
            end)
            return n
        end,
        function(col)
            local _, n = W.CreateCheckbox(col, L["opt_np_show_classification"], db.showClassification, 0, function(v)
                db.showClassification = v
                V22CommitFrameEdit()
            end)
            return n
        end)
    y = ny

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, n = W.CreateCheckbox(col, L["opt_show_threat"], db.showThreat, 0, function(v)
                db.showThreat = v
                V22CommitFrameEdit()
            end)
            return n
        end,
        function(col)
            local _, n = W.CreateCheckbox(col, L["opt_np_class_colors"], db.useClassColors, 0, function(v)
                db.useClassColors = v
                V22CommitFrameEdit()
            end)
            return n
        end)
    y = ny

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, n = W.CreateCheckbox(col, L["opt_np_show_absorb"], db.showAbsorb, 0, function(v)
                db.showAbsorb = v
                V22CommitFrameEdit()
            end)
            return n
        end,
        function(col)
            local _, n = W.CreateCheckbox(col, L["opt_np_friendly_name_only"], db.friendlyNameOnly, 0, function(v)
                db.friendlyNameOnly = v
                V22CommitFrameEdit()
            end)
            return n
        end)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_health_format"], {
        { text = L["np_fmt_percent"],         value = "percent" },
        { text = L["np_fmt_current"],         value = "current" },
        { text = L["np_fmt_current_percent"], value = "current_percent" },
    }, db.healthTextFormat or "percent", y, function(v)
        db.healthTextFormat = v
        V22CommitFrameEdit()
    end)
    y = ny
    return y
end

local function V22BuildNameplateRoles(c, y, db)
    y = V22SectionHeader(c, y, L["af_v22_sec_roles"], "R")
    if db.friendlyRoleIcons ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_friendly_role_icons"], db.friendlyRoleIcons, y, function(v)
            db.friendlyRoleIcons = v
            V22CommitFrameEdit()
        end)
        y = ny
    end

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            if db.roleShowTank ~= nil then
                local _, n = W.CreateCheckbox(col, L["opt_np_role_show_tank"], db.roleShowTank, 0, function(v)
                    db.roleShowTank = v
                    V22CommitFrameEdit()
                end)
                return n
            end
            return 0
        end,
        function(col)
            if db.roleShowHealer ~= nil then
                local _, n = W.CreateCheckbox(col, L["opt_np_role_show_healer"], db.roleShowHealer, 0, function(v)
                    db.roleShowHealer = v
                    V22CommitFrameEdit()
                end)
                return n
            end
            return 0
        end)
    y = ny

    if db.roleShowDps ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_role_show_dps"], db.roleShowDps, y, function(v)
            db.roleShowDps = v
            V22CommitFrameEdit()
        end)
        y = ny
    end

    if db.roleIconSize ~= nil then
        local _, ny = W.CreateSlider(c, L["opt_np_role_icon_size"], db.roleIconSize,
            16, 60, 2, y, function(v)
                db.roleIconSize = v
                V22CommitFrameEdit()
            end)
        y = ny
    end
    return y
end

local function V22BuildNameplateCastbar(c, y, db)
    y = V22SectionHeader(c, y, L["af_v22_sec_castbar"], "C")
    if db.showCastbar ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_show_castbar"], db.showCastbar, y, function(v)
            db.showCastbar = v
            V22CommitFrameEdit()
        end)
        y = ny
    end
    if db.castbarHeight ~= nil then
        local _, ny = W.CreateSlider(c, L["opt_np_castbar_height"], db.castbarHeight,
            4, 20, 1, y, function(v)
                db.castbarHeight = v
                V22CommitFrameEdit()
            end)
        y = ny
    end
    local _, ny = W.CreateInfoText(c, L["af_v21_bar_note"], y)
    y = ny
    return y
end

local function V22BuildNameplateAuras(c, y, db)
    y = V22SectionHeader(c, y, L["af_v22_sec_auras"], "A")
    if db.showAuras ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_show_auras"], db.showAuras, y, function(v)
            db.showAuras = v
            V22CommitFrameEdit()
        end)
        y = ny
    end
    if db.showOnlyMyAuras ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_only_my_debuffs"], db.showOnlyMyAuras, y, function(v)
            db.showOnlyMyAuras = v
            V22CommitFrameEdit()
        end)
        y = ny
    end
    if db.auraSize ~= nil and db.maxAuras ~= nil then
        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_aura_size"], db.auraSize,
                    12, 36, 1, 0, function(v)
                        db.auraSize = v
                        V22CommitFrameEdit()
                    end)
                return n
            end,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_max_auras"], db.maxAuras,
                    1, 10, 1, 0, function(v)
                        db.maxAuras = v
                        V22CommitFrameEdit()
                    end)
                return n
            end)
        y = ny
    end
    return y
end

local function V22BuildNameplateEnemyBuffs(c, y, db)
    y = V22SectionHeader(c, y, L["af_v22_sec_enemy_buffs"], "E")
    if db.showEnemyBuffs ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_show_enemy_buffs"], db.showEnemyBuffs, y, function(v)
            db.showEnemyBuffs = v
            V22CommitFrameEdit()
        end)
        y = ny
    end
    if db.enemyBuffSize ~= nil and db.maxEnemyBuffs ~= nil then
        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_enemy_buff_size"], db.enemyBuffSize,
                    12, 36, 1, 0, function(v)
                        db.enemyBuffSize = v
                        V22CommitFrameEdit()
                    end)
                return n
            end,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_max_enemy_buffs"], db.maxEnemyBuffs,
                    1, 8, 1, 0, function(v)
                        db.maxEnemyBuffs = v
                        V22CommitFrameEdit()
                    end)
                return n
            end)
        y = ny
    end
    if db.enemyBuffYOffset ~= nil then
        local _, ny = W.CreateSlider(c, L["opt_np_enemy_buff_y_offset"], db.enemyBuffYOffset,
            0, 20, 1, y, function(v)
                db.enemyBuffYOffset = v
                V22CommitFrameEdit()
            end)
        y = ny
    end
    return y
end

local function V22BuildNameplateAdvanced(c, y, db)
    y = V22SectionHeader(c, y, L["af_v22_sec_advanced"], "+")
    if db.selectedAlpha ~= nil and db.unselectedAlpha ~= nil then
        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_selected_alpha"], db.selectedAlpha,
                    0.3, 1.0, 0.05, 0, function(v)
                        db.selectedAlpha = v
                        V22CommitFrameEdit()
                    end, "%.2f")
                return n
            end,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_unselected_alpha"], db.unselectedAlpha,
                    0.3, 1.0, 0.05, 0, function(v)
                        db.unselectedAlpha = v
                        V22CommitFrameEdit()
                    end, "%.2f")
                return n
            end)
        y = ny
    end
    if db.overlapV ~= nil and db.topInset ~= nil then
        local _, ny = W.CreateTwoColumnRow(c, y,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_overlap"], db.overlapV,
                    0.5, 3.0, 0.1, 0, function(v)
                        db.overlapV = v
                        V21RefreshNameplateCVars()
                        ShowNameplateCadreParity()
                        V22HideFramePreviewNoise()
                    end, "%.1f")
                return n
            end,
            function(col)
                local _, n = W.CreateSlider(col, L["opt_np_top_inset"], db.topInset,
                    0.01, 0.5, 0.005, 0, function(v)
                        db.topInset = v
                        V21RefreshNameplateCVars()
                        ShowNameplateCadreParity()
                        V22HideFramePreviewNoise()
                    end, "%.3f")
                return n
            end)
        y = ny
    end
    return y
end

local function V22BuildNameplateContextColors(c, y, db)
    y = V22SectionHeader(c, y, L["af_v22_sec_context_colors"], "C")
    if type(db.colors) ~= "table" then return y end
    local colorKeys = {
        { "color_hostile",         "hostile" },
        { "color_neutral",         "neutral" },
        { "color_friendly",        "friendly" },
        { "color_tapped",          "tapped" },
        { "color_focus",           "focus" },
        { "color_caster",          "caster" },
        { "color_miniboss",        "miniboss" },
        { "color_enemy_in_combat", "enemyInCombat" },
    }
    for _, rec in ipairs(colorKeys) do
        local key = rec[2]
        if type(db.colors[key]) == "table" then
            y = V21Color(c, L[rec[1]], db.colors[key], y, function(r, g, b)
                db.colors[key] = { r = r, g = g, b = b }
                V22CommitFrameEdit()
            end)
        end
    end
    return y
end

local function V22BuildNameplateClassification(c, y, db)
    y = V22SectionHeader(c, y, L["af_v22_sec_classification"], "K")
    if db.useClassificationColors ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_use_classification"], db.useClassificationColors, y, function(v)
            db.useClassificationColors = v
            V22CommitFrameEdit()
        end)
        y = ny
    end
    if type(db.colors) == "table" then
        local classColors = {
            { "color_boss",    "boss" },
            { "color_elite",   "elite" },
            { "color_rare",    "rare" },
            { "color_normal",  "normal" },
            { "color_trivial", "trivial" },
        }
        for _, rec in ipairs(classColors) do
            local key = rec[2]
            if type(db.colors[key]) == "table" then
                y = V21Color(c, L[rec[1]], db.colors[key], y, function(r, g, b)
                    db.colors[key] = { r = r, g = g, b = b }
                    V22CommitFrameEdit()
                end)
            end
        end
    end
    return y
end

local function V22BuildNameplateTank(c, y, db)
    y = V22SectionHeader(c, y, L["af_v22_sec_tank"], "T")
    if db.tankMode ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_np_tank_mode"], db.tankMode, y, function(v)
            db.tankMode = v
            V22CommitFrameEdit()
        end)
        y = ny
    end
    if type(db.tankColors) == "table" then
        local tankColors = {
            { "color_no_threat",      "noThreat" },
            { "color_low_threat",     "lowThreat" },
            { "color_has_threat",     "hasThreat" },
            { "color_dps_has_aggro",  "dpsHasAggro" },
            { "color_dps_near_aggro", "dpsNearAggro" },
        }
        for _, rec in ipairs(tankColors) do
            local key = rec[2]
            if type(db.tankColors[key]) == "table" then
                y = V21Color(c, L[rec[1]], db.tankColors[key], y, function(r, g, b)
                    db.tankColors[key] = { r = r, g = g, b = b }
                    V22CommitFrameEdit()
                end)
            end
        end
    end
    return y
end

function S.BuildFrameEditorV22(c)
    local db = Settings()
    local y = -8

    V22EnsureFramePreview()
    if SubjectKind() == "nameplate" then
        ShowNameplateCadreParity()
    else
        HideNameplateCadreParity(false)
    end
    V22HideFramePreviewNoise()

    local _, current = V22EnsureFrameSection()

    local _, ny = W.CreateSectionHeader(c, L["af_v22_editor_title"], y, "F")
    y = ny
    local _, ny = W.CreateInfoText(c, L["af_v22_editor_info"], y)
    y = ny

    if not db then
        local _, ny = W.CreateInfoText(c, L["af_frame_unavailable"], y)
        y = ny
        c:SetHeight(math.abs(y) + 40)
        return
    end

    local kind = SubjectKind()

    if kind == "unitframe" then
        if current == "global" then
            y = BuildGlobalUnitFrameSettings(c, y)
        elseif current == "dimensions" then
            y = V22BuildUnitDimensions(c, y, db)
        elseif current == "display" then
            y = V22BuildUnitDisplay(c, y, db)
        elseif current == "colors" then
            y = V22BuildUnitColors(c, y, db)
        elseif current == "auras" then
            y = V22BuildUnitAuras(c, y, db)
        elseif current == "enemyBuffs" then
            y = V22BuildUnitEnemyBuffs(c, y, db)
        end
    elseif kind == "bossframe" then
        if current == "global" then
            y = BuildGlobalUnitFrameSettings(c, y)
        else
            y = V22BuildBossDimensions(c, y, db)
        end
    elseif kind == "nameplate" then
        if current == "dimensions" then
            y = V22BuildNameplateDimensions(c, y, db)
        elseif current == "display" then
            y = V22BuildNameplateDisplay(c, y, db)
        elseif current == "roles" then
            y = V22BuildNameplateRoles(c, y, db)
        elseif current == "castbar" then
            y = V22BuildNameplateCastbar(c, y, db)
        elseif current == "auras" then
            y = V22BuildNameplateAuras(c, y, db)
        elseif current == "enemyBuffs" then
            y = V22BuildNameplateEnemyBuffs(c, y, db)
        elseif current == "advanced" then
            y = V22BuildNameplateAdvanced(c, y, db)
        elseif current == "contextColors" then
            y = V22BuildNameplateContextColors(c, y, db)
        elseif current == "classification" then
            y = V22BuildNameplateClassification(c, y, db)
        elseif current == "tank" then
            y = V22BuildNameplateTank(c, y, db)
        end
    else
        local _, ny = W.CreateInfoText(c, L["af_frame_unavailable"], y)
        y = ny
    end

    c:SetHeight(math.abs(y) + 56)
end

-- ---------------------------------------------------------------------
-- Custom Bars manager
-- ---------------------------------------------------------------------
local BAR_SUBJECTS = {
    player = true,
    target = true,
    focus = true,
    pet = true,
    targettarget = true,
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
        S.BuildFrameEditorV22(c)
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

local function SelectCanvasSilently(id)
    if not (canvas and canvas.Select) then return end
    suppressCanvasSelect = true
    canvas:Select(id)
    suppressCanvasSelect = false
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
        if S.state.element then
            SelectCanvasSilently(S.state.element)
        end
    else
        S.state.element = nil
        -- IMPORTANT: Canvas.Select() invokes the Studio's onSelect callback.
        -- Without suppression that callback immediately cleared the requested
        -- Frame/Bars/Presets mode and switched back to Elements.
        SelectCanvasSilently(nil)
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

do
    local _RebuildSidebar = S.RebuildSidebar
    function S.RebuildSidebar()
        if S.state.showFrameEditor then
            if SubjectKind() ~= "nameplate" then
                HideNameplateCadreParity(false)
            end
            V22BuildFrameSidebar()
            return
        end
        HideNameplateCadreParity(true)
        V22HideFrameSidebarButtons()
        V22RestoreCanvasInteractivity()
        return _RebuildSidebar()
    end
end

function S.SelectElement(id)
    S.state.element = id
    S.state.showFrameEditor = false
    S.state.showBars = false
    S.state.showPresets = false
    if canvas and canvas.GetSelection and canvas:GetSelection() ~= id then
        SelectCanvasSilently(id)
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
            if suppressCanvasSelect then return end
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

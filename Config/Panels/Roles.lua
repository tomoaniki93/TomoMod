-- =====================================================================
-- Panels/Roles.lua — Role guides (Tank / Healer / DPS)
-- ---------------------------------------------------------------------
-- These pages own NO setting. Every card explains why something matters
-- for a role and then deep-links to the real option, which keeps living
-- in its own panel. Duplicating widgets here would mean duplicating the
-- callbacks that refresh the live modules, and the two copies would drift
-- apart the first time one of them changed.
--
-- Degrades cleanly: without Config/Presets.lua the "apply preset" button
-- is dropped, without the role filter (Widgets.lua) the focus button is
-- dropped, and without Config/GlobalSearch.lua the links fall back to
-- opening the right category.
-- =====================================================================

local L = TomoMod_L
local W = TomoMod_Widgets

-- TomoMod_Config is created by Config/ConfigUI.lua, which the .toc loads
-- immediately AFTER this file (it has to: ConfigUI reads cat_roles at load
-- time, and those strings are registered here). Capturing it in a file-scope
-- local would therefore capture nil for the whole session, so every use reads
-- the global at call time instead — same as Config/Panels/_Suite.lua.

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ROLE_TEX  = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Roles\\"
local WHITE8    = "Interface\\Buttons\\WHITE8x8"

-- ---------------------------------------------------------------------
-- LOCALES (self-contained, all six languages)
-- Registered here rather than in Locales/*.lua because ConfigUI.lua
-- reads cat_roles / cfg_tab_role_* at load time and this file loads
-- immediately before it in the .toc.
-- ---------------------------------------------------------------------
if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["cat_roles"]                         = "Roles",
        ["cat_roles_desc"]                    = "Guides for tanking, healing and damage — what matters, and where to set it.",
        ["cfg_tab_role_tank"]                 = "Tank",
        ["cfg_tab_role_healer"]               = "Healer",
        ["cfg_tab_role_dps"]                  = "DPS",
        ["roles_title_tank"]                  = "Playing tank",
        ["roles_title_healer"]                = "Playing healer",
        ["roles_title_dps"]                   = "Playing damage",
        ["roles_intro_tank"]                  = "Tanking is about reading the whole pull, not just your target: threat, interrupt windows and your own health. These are the settings that carry the most weight.",
        ["roles_intro_healer"]                = "Healing turns the party and raid frames into your main interface. Everything below makes them faster to read and to click.",
        ["roles_intro_dps"]                   = "Damage lives on your own resources, cooldowns and debuffs. These settings keep them readable without cluttering the screen.",
        ["roles_goto"]                        = "Go to the setting",
        ["roles_goto_tip"]                    = "Opens the panel that holds this setting and highlights it.",
        ["roles_apply_preset"]                = "Apply this preset",
        ["roles_focus_filter"]                = "Focus the interface on this role",

        -- tank
        ["roles_tank_np_tankmode_title"]       = "Tank mode on nameplates",
        ["roles_tank_np_tankmode_desc"]        = "Plates are coloured by threat, so a pack slipping away is visible at a glance. The single most important setting of the role.",
        ["roles_tank_np_buffs_title"]          = "Enemy buffs on plates",
        ["roles_tank_np_buffs_desc"]           = "Enrages, shields and absorbs show above the plate. Essential for knowing when to stall or dispel.",
        ["roles_tank_np_cast_title"]           = "Plate castbar",
        ["roles_tank_np_cast_desc"]            = "A thicker bar keeps interrupt windows readable in the middle of a pull, and makes uninterruptible casts obvious.",
        ["roles_tank_uf_threat_title"]         = "Numeric threat on your target",
        ["roles_tank_uf_threat_desc"]          = "Shows your threat percentage instead of a plain indicator, so you can tell when a damage dealer is about to pull off you.",
        ["roles_tank_pf_cd_title"]             = "Party cooldowns",
        ["roles_tank_pf_cd_desc"]              = "Your allies' interrupts and battle resurrections tracked on the party frames. Calling kicks is the tank's job.",
        ["roles_tank_rb_health_title"]         = "Personal health bar",
        ["roles_tank_rb_health_desc"]          = "Your own health in front of you, with a warning threshold, so you never have to look up at the player frame mid-pull.",
        -- healer
        ["roles_healer_pf_hots_title"]         = "HoT tracking",
        ["roles_healer_pf_hots_desc"]          = "Your heals over time shown on each frame. Without it you refresh into nothing, or let them expire.",
        ["roles_healer_pf_dispel_title"]       = "Dispel highlight",
        ["roles_healer_pf_dispel_desc"]        = "The frame borders in the colour of the dispellable debuff type. Far quicker to read than an icon.",
        ["roles_healer_rf_extras_title"]       = "Heal prediction and shields",
        ["roles_healer_rf_extras_desc"]        = "Shows incoming heals and absorbs already applied. This is what stops overhealing and doubling up with the other healer.",
        ["roles_healer_rf_debuffs_title"]      = "Raid debuffs",
        ["roles_healer_rf_debuffs_desc"]       = "Important debuffs surface on the affected player's frame. Worth tuning to whatever the current content throws at you.",
        ["roles_healer_rf_range_title"]        = "Range indicator",
        ["roles_healer_rf_range_desc"]         = "Out-of-range frames fade out. The most underrated setting of the role: you stop casting into nothing.",
        ["roles_healer_rf_defs_title"]         = "Defensive tracking",
        ["roles_healer_rf_defs_desc"]          = "Seeing who has already mitigated saves you from burning a big heal on someone in no danger.",
        -- dps
        ["roles_dps_rb_bars_title"]            = "Resource bars",
        ["roles_dps_rb_bars_desc"]             = "Combo points, runes, shards — reading your resource drives the whole rotation. Do not hesitate to make it bigger.",
        ["roles_dps_cdm_title"]                = "Cooldowns and procs",
        ["roles_dps_cdm_desc"]                 = "Cooldown tracking plus proc glow. The range check keeps you from pressing while out of reach.",
        ["roles_dps_np_auras_title"]           = "Your auras on plates",
        ["roles_dps_np_auras_desc"]            = "Showing only your own debuffs makes multi-target DoT tracking readable again.",
        ["roles_dps_np_buffs_title"]           = "Enemy defensive buffs",
        ["roles_dps_np_buffs_desc"]            = "Spotting a shield or a damage reduction on your target keeps you from wasting your burst.",
        ["roles_dps_cb_gcd_title"]             = "GCD spark",
        ["roles_dps_cb_gcd_desc"]              = "A visual marker on the castbar to tighten your rotation and cut dead time between casts.",
        ["roles_dps_cb_kick_title"]            = "Interrupt feedback",
        ["roles_dps_cb_kick_desc"]             = "Visible confirmation when your kick lands. Useful when several players share an interrupt rotation.",
    })

    TomoMod_RegisterLocale("frFR", {
        ["cat_roles"]                         = "Rôles",
        ["cat_roles_desc"]                    = "Guides tank, soigneur et DPS — ce qui compte, et où le régler.",
        ["cfg_tab_role_tank"]                 = "Tank",
        ["cfg_tab_role_healer"]               = "Soigneur",
        ["cfg_tab_role_dps"]                  = "DPS",
        ["roles_title_tank"]                  = "Jouer tank",
        ["roles_title_healer"]                = "Jouer soigneur",
        ["roles_title_dps"]                   = "Jouer DPS",
        ["roles_intro_tank"]                  = "Tanker, c'est lire tout le pull et pas seulement sa cible : la menace, les fenêtres d'interruption et sa propre vie. Voici les réglages qui pèsent le plus.",
        ["roles_intro_healer"]                = "Soigner fait des cadres de groupe et de raid ton interface principale. Tout ce qui suit les rend plus rapides à lire et à cliquer.",
        ["roles_intro_dps"]                   = "Le DPS vit sur ses ressources, ses cooldowns et ses debuffs. Ces réglages les gardent lisibles sans encombrer l'écran.",
        ["roles_goto"]                        = "Aller au réglage",
        ["roles_goto_tip"]                    = "Ouvre le panneau qui contient ce réglage et le met en surbrillance.",
        ["roles_apply_preset"]                = "Appliquer ce preset",
        ["roles_focus_filter"]                = "Filtrer l'interface sur ce rôle",

        -- tank
        ["roles_tank_np_tankmode_title"]       = "Mode Tank sur les nameplates",
        ["roles_tank_np_tankmode_desc"]        = "Les plaques se colorent selon la menace : un pack qui t'échappe se voit immédiatement. Le réglage le plus important du rôle.",
        ["roles_tank_np_buffs_title"]          = "Buffs ennemis sur les plaques",
        ["roles_tank_np_buffs_desc"]           = "Enrages, boucliers et absorptions apparaissent au-dessus de la plaque. Indispensable pour savoir quand temporiser ou dissiper.",
        ["roles_tank_np_cast_title"]           = "Barre d'incantation des plaques",
        ["roles_tank_np_cast_desc"]            = "Une barre plus épaisse rend les fenêtres d'interruption lisibles en pleine mêlée, et les sorts non interruptibles évidents.",
        ["roles_tank_uf_threat_title"]         = "Menace chiffrée sur la cible",
        ["roles_tank_uf_threat_desc"]          = "Affiche ton pourcentage de menace plutôt qu'un simple indicateur : tu vois venir le DPS qui est sur le point de t'arracher l'aggro.",
        ["roles_tank_pf_cd_title"]             = "Cooldowns du groupe",
        ["roles_tank_pf_cd_desc"]              = "Les interruptions et les résurrections de combat de tes alliés suivies sur les cadres de groupe. C'est le tank qui appelle les kicks.",
        ["roles_tank_rb_health_title"]         = "Barre de vie personnelle",
        ["roles_tank_rb_health_desc"]          = "Ta propre vie sous les yeux, avec un seuil d'alerte : plus besoin de remonter au cadre du joueur en plein pull.",
        -- healer
        ["roles_healer_pf_hots_title"]         = "Suivi des HoTs",
        ["roles_healer_pf_hots_desc"]          = "Tes soins sur la durée affichés sur chaque cadre. Sans ça, tu réappliques dans le vide ou tu les laisses expirer.",
        ["roles_healer_pf_dispel_title"]       = "Surbrillance de dissipation",
        ["roles_healer_pf_dispel_desc"]        = "Le cadre se borde de la couleur du type de debuff dissipable. Bien plus rapide à lire qu'une icône.",
        ["roles_healer_rf_extras_title"]       = "Prévision de soin et boucliers",
        ["roles_healer_rf_extras_desc"]        = "Montre les soins en vol et les absorptions déjà posées. C'est ce qui évite le surheal et les doublons avec l'autre soigneur.",
        ["roles_healer_rf_debuffs_title"]      = "Debuffs de raid",
        ["roles_healer_rf_debuffs_desc"]       = "Les debuffs importants remontent sur le cadre du joueur touché. À régler selon ce que le contenu du moment t'envoie.",
        ["roles_healer_rf_range_title"]        = "Indicateur de portée",
        ["roles_healer_rf_range_desc"]         = "Les cadres hors de portée s'estompent. Le réglage le plus sous-estimé du rôle : tu arrêtes de lancer dans le vide.",
        ["roles_healer_rf_defs_title"]         = "Défensifs suivis",
        ["roles_healer_rf_defs_desc"]          = "Voir qui a déjà mitigé t'évite de brûler un gros soin sur quelqu'un qui ne risque rien.",
        -- dps
        ["roles_dps_rb_bars_title"]            = "Barres de ressource",
        ["roles_dps_rb_bars_desc"]             = "Points de combo, runes, éclats — la lecture de ta ressource conditionne toute la rotation. À agrandir sans hésiter.",
        ["roles_dps_cdm_title"]                = "Cooldowns et procs",
        ["roles_dps_cdm_desc"]                 = "Le suivi des temps de recharge et l'illumination des procs. La vérification de portée évite d'appuyer hors d'atteinte.",
        ["roles_dps_np_auras_title"]           = "Tes auras sur les plaques",
        ["roles_dps_np_auras_desc"]            = "N'afficher que tes propres debuffs rend le suivi des DoT en multi-cible de nouveau lisible.",
        ["roles_dps_np_buffs_title"]           = "Buffs défensifs ennemis",
        ["roles_dps_np_buffs_desc"]            = "Repérer un bouclier ou une réduction de dégâts sur la cible t'évite de gâcher ton burst.",
        ["roles_dps_cb_gcd_title"]             = "Étincelle de GCD",
        ["roles_dps_cb_gcd_desc"]              = "Un repère visuel sur la barre d'incantation pour serrer ta rotation et réduire le temps mort entre deux sorts.",
        ["roles_dps_cb_kick_title"]            = "Retour d'interruption",
        ["roles_dps_cb_kick_desc"]             = "Confirmation visible quand ton kick passe. Utile quand plusieurs joueurs tournent sur la même rotation d'interruptions.",
    })

    TomoMod_RegisterLocale("deDE", {
        ["cat_roles"]                         = "Rollen",
        ["cat_roles_desc"]                    = "Leitfäden für Tank, Heiler und Schaden — was zählt und wo man es einstellt.",
        ["cfg_tab_role_tank"]                 = "Tank",
        ["cfg_tab_role_healer"]               = "Heiler",
        ["cfg_tab_role_dps"]                  = "DPS",
        ["roles_title_tank"]                  = "Als Tank spielen",
        ["roles_title_healer"]                = "Als Heiler spielen",
        ["roles_title_dps"]                   = "Auf Schaden spielen",
        ["roles_intro_tank"]                  = "Tanken heißt, die ganze Gegnergruppe zu lesen, nicht nur das eigene Ziel: Bedrohung, Unterbrechungsfenster und die eigene Gesundheit. Das sind die Einstellungen mit dem größten Gewicht.",
        ["roles_intro_healer"]                = "Beim Heilen werden Gruppen- und Schlachtzugsfenster zur Hauptoberfläche. Alles Folgende macht sie schneller lesbar und anklickbar.",
        ["roles_intro_dps"]                   = "Schaden lebt von den eigenen Ressourcen, Abklingzeiten und Schwächungszaubern. Diese Einstellungen halten sie lesbar, ohne den Bildschirm zu überladen.",
        ["roles_goto"]                        = "Zur Einstellung",
        ["roles_goto_tip"]                    = "Öffnet das Panel mit dieser Einstellung und hebt sie hervor.",
        ["roles_apply_preset"]                = "Dieses Preset anwenden",
        ["roles_focus_filter"]                = "Oberfläche auf diese Rolle fokussieren",

        -- tank
        ["roles_tank_np_tankmode_title"]       = "Tank-Modus für Namensplaketten",
        ["roles_tank_np_tankmode_desc"]        = "Plaketten werden nach Bedrohung eingefärbt, sodass eine entgleitende Gruppe sofort auffällt. Die wichtigste Einstellung der Rolle.",
        ["roles_tank_np_buffs_title"]          = "Gegnerische Stärkungszauber auf Plaketten",
        ["roles_tank_np_buffs_desc"]           = "Wutanfälle, Schilde und Absorptionen erscheinen über der Plakette. Unverzichtbar, um zu wissen, wann man abwartet oder entzaubert.",
        ["roles_tank_np_cast_title"]           = "Zauberleiste auf Plaketten",
        ["roles_tank_np_cast_desc"]            = "Eine dickere Leiste hält Unterbrechungsfenster mitten im Kampf lesbar und macht nicht unterbrechbare Zauber offensichtlich.",
        ["roles_tank_uf_threat_title"]         = "Numerische Bedrohung am Ziel",
        ["roles_tank_uf_threat_desc"]          = "Zeigt deinen Bedrohungsanteil statt nur einer Anzeige, sodass du erkennst, wann ein Schadensausteiler dir gleich die Aggro abnimmt.",
        ["roles_tank_pf_cd_title"]             = "Gruppenabklingzeiten",
        ["roles_tank_pf_cd_desc"]              = "Unterbrechungen und Kampfwiederbelebungen deiner Verbündeten, verfolgt auf den Gruppenfenstern. Das Ansagen der Unterbrechungen ist Tankaufgabe.",
        ["roles_tank_rb_health_title"]         = "Eigene Lebensleiste",
        ["roles_tank_rb_health_desc"]          = "Deine eigene Gesundheit direkt vor dir, mit Warnschwelle, sodass du mitten im Kampf nie zum Spielerfenster hochschauen musst.",
        -- healer
        ["roles_healer_pf_hots_title"]         = "HoT-Verfolgung",
        ["roles_healer_pf_hots_desc"]          = "Deine Heilung über Zeit auf jedem Fenster sichtbar. Ohne sie erneuerst du ins Leere oder lässt sie auslaufen.",
        ["roles_healer_pf_dispel_title"]       = "Entzauberungs-Hervorhebung",
        ["roles_healer_pf_dispel_desc"]        = "Das Fenster wird in der Farbe des entzauberbaren Effekttyps umrandet. Deutlich schneller lesbar als ein Symbol.",
        ["roles_healer_rf_extras_title"]       = "Heilvorhersage und Schilde",
        ["roles_healer_rf_extras_desc"]        = "Zeigt eingehende Heilung und bereits gesetzte Absorptionen. Genau das verhindert Überheilung und Doppelarbeit mit dem zweiten Heiler.",
        ["roles_healer_rf_debuffs_title"]      = "Schlachtzugs-Schwächungszauber",
        ["roles_healer_rf_debuffs_desc"]       = "Wichtige Effekte erscheinen auf dem Fenster des betroffenen Spielers. Lohnt sich, auf den aktuellen Inhalt abzustimmen.",
        ["roles_healer_rf_range_title"]        = "Reichweitenanzeige",
        ["roles_healer_rf_range_desc"]         = "Fenster außer Reichweite werden ausgeblendet. Die unterschätzteste Einstellung der Rolle: du zauberst nicht mehr ins Leere.",
        ["roles_healer_rf_defs_title"]         = "Verfolgung von Verteidigungszaubern",
        ["roles_healer_rf_defs_desc"]          = "Zu sehen, wer bereits abgeschwächt hat, bewahrt dich davor, eine große Heilung an jemanden zu verschwenden, der nicht in Gefahr ist.",
        -- dps
        ["roles_dps_rb_bars_title"]            = "Ressourcenleisten",
        ["roles_dps_rb_bars_desc"]             = "Combopunkte, Runen, Splitter — das Ablesen der Ressource bestimmt die gesamte Rotation. Ruhig größer machen.",
        ["roles_dps_cdm_title"]                = "Abklingzeiten und Procs",
        ["roles_dps_cdm_desc"]                 = "Verfolgung der Abklingzeiten plus Proc-Leuchten. Die Reichweitenprüfung verhindert Drücken außer Reichweite.",
        ["roles_dps_np_auras_title"]           = "Eigene Auren auf Plaketten",
        ["roles_dps_np_auras_desc"]            = "Nur die eigenen Schwächungszauber anzuzeigen macht die DoT-Verfolgung bei mehreren Zielen wieder lesbar.",
        ["roles_dps_np_buffs_title"]           = "Gegnerische Verteidigungszauber",
        ["roles_dps_np_buffs_desc"]            = "Einen Schild oder eine Schadensreduzierung am Ziel zu erkennen bewahrt dich davor, deinen Burst zu verschwenden.",
        ["roles_dps_cb_gcd_title"]             = "GCD-Funke",
        ["roles_dps_cb_gcd_desc"]              = "Eine visuelle Markierung auf der Zauberleiste, um die Rotation zu straffen und Totzeit zwischen Zaubern zu reduzieren.",
        ["roles_dps_cb_kick_title"]            = "Unterbrechungs-Rückmeldung",
        ["roles_dps_cb_kick_desc"]             = "Sichtbare Bestätigung, wenn deine Unterbrechung sitzt. Nützlich, wenn mehrere Spieler sich eine Unterbrechungsrotation teilen.",
    })

    TomoMod_RegisterLocale("esES", {
        ["cat_roles"]                         = "Roles",
        ["cat_roles_desc"]                    = "Guías de tanque, sanador y daño: qué importa y dónde ajustarlo.",
        ["cfg_tab_role_tank"]                 = "Tanque",
        ["cfg_tab_role_healer"]               = "Sanador",
        ["cfg_tab_role_dps"]                  = "DPS",
        ["roles_title_tank"]                  = "Jugar de tanque",
        ["roles_title_healer"]                = "Jugar de sanador",
        ["roles_title_dps"]                   = "Jugar de daño",
        ["roles_intro_tank"]                  = "Tanquear consiste en leer todo el grupo de enemigos, no solo tu objetivo: amenaza, ventanas de interrupción y tu propia vida. Estos son los ajustes que más pesan.",
        ["roles_intro_healer"]                = "Sanar convierte los marcos de grupo y banda en tu interfaz principal. Todo lo siguiente los hace más rápidos de leer y de pulsar.",
        ["roles_intro_dps"]                   = "El daño vive de tus recursos, reutilizaciones y perjuicios. Estos ajustes los mantienen legibles sin saturar la pantalla.",
        ["roles_goto"]                        = "Ir al ajuste",
        ["roles_goto_tip"]                    = "Abre el panel que contiene este ajuste y lo resalta.",
        ["roles_apply_preset"]                = "Aplicar este preset",
        ["roles_focus_filter"]                = "Centrar la interfaz en este rol",

        -- tank
        ["roles_tank_np_tankmode_title"]       = "Modo tanque en las placas",
        ["roles_tank_np_tankmode_desc"]        = "Las placas se colorean por amenaza, así se ve al instante un grupo que se te escapa. El ajuste más importante del rol.",
        ["roles_tank_np_buffs_title"]          = "Beneficios enemigos en las placas",
        ["roles_tank_np_buffs_desc"]           = "Enfurecimientos, escudos y absorciones aparecen sobre la placa. Imprescindible para saber cuándo aguantar o disipar.",
        ["roles_tank_np_cast_title"]           = "Barra de lanzamiento en las placas",
        ["roles_tank_np_cast_desc"]            = "Una barra más gruesa mantiene legibles las ventanas de interrupción en plena pelea y hace evidentes los lanzamientos ininterrumpibles.",
        ["roles_tank_uf_threat_title"]         = "Amenaza numérica en el objetivo",
        ["roles_tank_uf_threat_desc"]          = "Muestra tu porcentaje de amenaza en vez de un indicador simple, así ves venir al DPS que va a quitarte la aggro.",
        ["roles_tank_pf_cd_title"]             = "Reutilizaciones del grupo",
        ["roles_tank_pf_cd_desc"]              = "Las interrupciones y resurrecciones de combate de tus aliados, seguidas en los marcos de grupo. Cantar los kicks es tarea del tanque.",
        ["roles_tank_rb_health_title"]         = "Barra de vida propia",
        ["roles_tank_rb_health_desc"]          = "Tu propia vida delante de ti, con un umbral de aviso, para no tener que mirar el marco de jugador en pleno pull.",
        -- healer
        ["roles_healer_pf_hots_title"]         = "Seguimiento de HoTs",
        ["roles_healer_pf_hots_desc"]          = "Tus sanaciones por tiempo mostradas en cada marco. Sin esto, refrescas en vano o las dejas expirar.",
        ["roles_healer_pf_dispel_title"]       = "Resaltado de disipación",
        ["roles_healer_pf_dispel_desc"]        = "El marco se bordea con el color del tipo de perjuicio disipable. Mucho más rápido de leer que un icono.",
        ["roles_healer_rf_extras_title"]       = "Predicción de sanación y escudos",
        ["roles_healer_rf_extras_desc"]        = "Muestra las sanaciones en camino y las absorciones ya aplicadas. Es lo que evita el exceso de sanación y duplicarse con el otro sanador.",
        ["roles_healer_rf_debuffs_title"]      = "Perjuicios de banda",
        ["roles_healer_rf_debuffs_desc"]       = "Los perjuicios importantes aparecen en el marco del jugador afectado. Conviene ajustarlo al contenido del momento.",
        ["roles_healer_rf_range_title"]        = "Indicador de alcance",
        ["roles_healer_rf_range_desc"]         = "Los marcos fuera de alcance se atenúan. El ajuste más infravalorado del rol: dejas de lanzar en vano.",
        ["roles_healer_rf_defs_title"]         = "Seguimiento de defensivas",
        ["roles_healer_rf_defs_desc"]          = "Ver quién ya ha mitigado te evita quemar una sanación grande en alguien que no corre peligro.",
        -- dps
        ["roles_dps_rb_bars_title"]            = "Barras de recurso",
        ["roles_dps_rb_bars_desc"]             = "Puntos de combo, runas, fragmentos: leer tu recurso condiciona toda la rotación. Agrándala sin dudar.",
        ["roles_dps_cdm_title"]                = "Reutilizaciones y procs",
        ["roles_dps_cdm_desc"]                 = "Seguimiento de reutilizaciones y brillo de procs. La comprobación de alcance evita pulsar fuera de rango.",
        ["roles_dps_np_auras_title"]           = "Tus auras en las placas",
        ["roles_dps_np_auras_desc"]            = "Mostrar solo tus propios perjuicios vuelve legible el seguimiento de DoT en varios objetivos.",
        ["roles_dps_np_buffs_title"]           = "Beneficios defensivos enemigos",
        ["roles_dps_np_buffs_desc"]            = "Detectar un escudo o una reducción de daño en el objetivo evita que malgastes tu burst.",
        ["roles_dps_cb_gcd_title"]             = "Chispa de GCD",
        ["roles_dps_cb_gcd_desc"]              = "Una marca visual en la barra de lanzamiento para apretar tu rotación y reducir el tiempo muerto entre hechizos.",
        ["roles_dps_cb_kick_title"]            = "Confirmación de interrupción",
        ["roles_dps_cb_kick_desc"]             = "Confirmación visible cuando tu kick entra. Útil cuando varios jugadores comparten una rotación de interrupciones.",
    })

    TomoMod_RegisterLocale("itIT", {
        ["cat_roles"]                         = "Ruoli",
        ["cat_roles_desc"]                    = "Guide per difensore, guaritore e danno: cosa conta e dove regolarlo.",
        ["cfg_tab_role_tank"]                 = "Difensore",
        ["cfg_tab_role_healer"]               = "Guaritore",
        ["cfg_tab_role_dps"]                  = "DPS",
        ["roles_title_tank"]                  = "Giocare da difensore",
        ["roles_title_healer"]                = "Giocare da guaritore",
        ["roles_title_dps"]                   = "Giocare da danno",
        ["roles_intro_tank"]                  = "Fare il difensore significa leggere l'intero gruppo di nemici, non solo il proprio bersaglio: minaccia, finestre di interruzione e la propria salute. Ecco le impostazioni che pesano di più.",
        ["roles_intro_healer"]                = "Curare rende i riquadri gruppo e incursione la tua interfaccia principale. Tutto quanto segue li rende più rapidi da leggere e da cliccare.",
        ["roles_intro_dps"]                   = "Il danno vive delle tue risorse, ricariche e debuff. Queste impostazioni li mantengono leggibili senza intasare lo schermo.",
        ["roles_goto"]                        = "Vai all'impostazione",
        ["roles_goto_tip"]                    = "Apre il pannello che contiene questa impostazione e la evidenzia.",
        ["roles_apply_preset"]                = "Applicare questo preset",
        ["roles_focus_filter"]                = "Focalizzare l'interfaccia su questo ruolo",

        -- tank
        ["roles_tank_np_tankmode_title"]       = "Modalità difensore sulle targhette",
        ["roles_tank_np_tankmode_desc"]        = "Le targhette si colorano in base alla minaccia: un gruppo che ti sfugge si vede subito. L'impostazione più importante del ruolo.",
        ["roles_tank_np_buffs_title"]          = "Potenziamenti nemici sulle targhette",
        ["roles_tank_np_buffs_desc"]           = "Furie, scudi e assorbimenti appaiono sopra la targhetta. Indispensabile per sapere quando temporeggiare o dissolvere.",
        ["roles_tank_np_cast_title"]           = "Barra di lancio sulle targhette",
        ["roles_tank_np_cast_desc"]            = "Una barra più spessa mantiene leggibili le finestre di interruzione in piena mischia e rende evidenti gli incantesimi non interrompibili.",
        ["roles_tank_uf_threat_title"]         = "Minaccia numerica sul bersaglio",
        ["roles_tank_uf_threat_desc"]          = "Mostra la tua percentuale di minaccia invece di un semplice indicatore, così vedi arrivare il DPS che sta per strapparti l'aggro.",
        ["roles_tank_pf_cd_title"]             = "Ricariche del gruppo",
        ["roles_tank_pf_cd_desc"]              = "Le interruzioni e le rianimazioni in combattimento dei tuoi alleati, monitorate sui riquadri gruppo. Chiamare le interruzioni spetta al difensore.",
        ["roles_tank_rb_health_title"]         = "Barra della salute personale",
        ["roles_tank_rb_health_desc"]          = "La tua salute davanti agli occhi, con una soglia di avviso: non devi più risalire al riquadro del giocatore in pieno combattimento.",
        -- healer
        ["roles_healer_pf_hots_title"]         = "Monitoraggio degli HoT",
        ["roles_healer_pf_hots_desc"]          = "Le tue cure nel tempo mostrate su ogni riquadro. Senza, le riapplichi a vuoto o le lasci scadere.",
        ["roles_healer_pf_dispel_title"]       = "Evidenziazione della dissolvenza",
        ["roles_healer_pf_dispel_desc"]        = "Il riquadro si borda del colore del tipo di debuff dissolvibile. Molto più rapido da leggere di un'icona.",
        ["roles_healer_rf_extras_title"]       = "Previsione di cura e scudi",
        ["roles_healer_rf_extras_desc"]        = "Mostra le cure in arrivo e gli assorbimenti già applicati. È ciò che evita la sovracura e le sovrapposizioni con l'altro guaritore.",
        ["roles_healer_rf_debuffs_title"]      = "Debuff da incursione",
        ["roles_healer_rf_debuffs_desc"]       = "I debuff importanti emergono sul riquadro del giocatore colpito. Da regolare in base al contenuto del momento.",
        ["roles_healer_rf_range_title"]        = "Indicatore di portata",
        ["roles_healer_rf_range_desc"]         = "I riquadri fuori portata si attenuano. L'impostazione più sottovalutata del ruolo: smetti di lanciare a vuoto.",
        ["roles_healer_rf_defs_title"]         = "Monitoraggio delle difensive",
        ["roles_healer_rf_defs_desc"]          = "Vedere chi ha già mitigato ti evita di sprecare una cura grossa su qualcuno che non rischia nulla.",
        -- dps
        ["roles_dps_rb_bars_title"]            = "Barre delle risorse",
        ["roles_dps_rb_bars_desc"]             = "Punti combo, rune, frammenti: leggere la risorsa condiziona tutta la rotazione. Ingrandiscila senza esitare.",
        ["roles_dps_cdm_title"]                = "Ricariche e proc",
        ["roles_dps_cdm_desc"]                 = "Monitoraggio delle ricariche e bagliore dei proc. Il controllo della portata evita di premere fuori raggio.",
        ["roles_dps_np_auras_title"]           = "Le tue aure sulle targhette",
        ["roles_dps_np_auras_desc"]            = "Mostrare solo i tuoi debuff rende di nuovo leggibile il monitoraggio dei DoT su più bersagli.",
        ["roles_dps_np_buffs_title"]           = "Potenziamenti difensivi nemici",
        ["roles_dps_np_buffs_desc"]            = "Notare uno scudo o una riduzione del danno sul bersaglio ti evita di sprecare il burst.",
        ["roles_dps_cb_gcd_title"]             = "Scintilla del GCD",
        ["roles_dps_cb_gcd_desc"]              = "Un riferimento visivo sulla barra di lancio per stringere la rotazione e ridurre i tempi morti tra un incantesimo e l'altro.",
        ["roles_dps_cb_kick_title"]            = "Riscontro dell'interruzione",
        ["roles_dps_cb_kick_desc"]             = "Conferma visibile quando la tua interruzione va a segno. Utile quando più giocatori condividono una rotazione di interruzioni.",
    })

    TomoMod_RegisterLocale("ptBR", {
        ["cat_roles"]                         = "Funções",
        ["cat_roles_desc"]                    = "Guias de tanque, curandeiro e dano: o que importa e onde ajustar.",
        ["cfg_tab_role_tank"]                 = "Tanque",
        ["cfg_tab_role_healer"]               = "Curandeiro",
        ["cfg_tab_role_dps"]                  = "DPS",
        ["roles_title_tank"]                  = "Jogar de tanque",
        ["roles_title_healer"]                = "Jogar de curandeiro",
        ["roles_title_dps"]                   = "Jogar de dano",
        ["roles_intro_tank"]                  = "Tanquear é ler todo o grupo de inimigos, não só o seu alvo: ameaça, janelas de interrupção e a sua própria vida. Estes são os ajustes que mais pesam.",
        ["roles_intro_healer"]                = "Curar transforma os quadros de grupo e raide na sua interface principal. Tudo abaixo os torna mais rápidos de ler e de clicar.",
        ["roles_intro_dps"]                   = "O dano vive dos seus recursos, recargas e debuffs. Estes ajustes os mantêm legíveis sem entulhar a tela.",
        ["roles_goto"]                        = "Ir ao ajuste",
        ["roles_goto_tip"]                    = "Abre o painel que contém este ajuste e o destaca.",
        ["roles_apply_preset"]                = "Aplicar este preset",
        ["roles_focus_filter"]                = "Focar a interface nesta função",

        -- tank
        ["roles_tank_np_tankmode_title"]       = "Modo tanque nas placas",
        ["roles_tank_np_tankmode_desc"]        = "As placas são coloridas por ameaça, então um grupo escapando aparece na hora. O ajuste mais importante da função.",
        ["roles_tank_np_buffs_title"]          = "Bônus inimigos nas placas",
        ["roles_tank_np_buffs_desc"]           = "Fúrias, escudos e absorções aparecem acima da placa. Essencial para saber quando segurar ou dissipar.",
        ["roles_tank_np_cast_title"]           = "Barra de conjuração nas placas",
        ["roles_tank_np_cast_desc"]            = "Uma barra mais espessa mantém as janelas de interrupção legíveis no meio da luta e deixa óbvias as conjurações ininterruptíveis.",
        ["roles_tank_uf_threat_title"]         = "Ameaça numérica no alvo",
        ["roles_tank_uf_threat_desc"]          = "Mostra sua porcentagem de ameaça em vez de um indicador simples, então você vê o DPS que está prestes a puxar de você.",
        ["roles_tank_pf_cd_title"]             = "Recargas do grupo",
        ["roles_tank_pf_cd_desc"]              = "As interrupções e ressurreições em combate dos seus aliados, rastreadas nos quadros de grupo. Chamar os kicks é tarefa do tanque.",
        ["roles_tank_rb_health_title"]         = "Barra de vida própria",
        ["roles_tank_rb_health_desc"]          = "Sua própria vida à frente, com um limiar de aviso, para nunca precisar olhar o quadro do jogador no meio do pull.",
        -- healer
        ["roles_healer_pf_hots_title"]         = "Rastreio de HoTs",
        ["roles_healer_pf_hots_desc"]          = "Suas curas ao longo do tempo mostradas em cada quadro. Sem isso, você renova à toa ou deixa expirar.",
        ["roles_healer_pf_dispel_title"]       = "Destaque de dissipação",
        ["roles_healer_pf_dispel_desc"]        = "O quadro ganha a borda na cor do tipo de debuff dissipável. Muito mais rápido de ler do que um ícone.",
        ["roles_healer_rf_extras_title"]       = "Previsão de cura e escudos",
        ["roles_healer_rf_extras_desc"]        = "Mostra as curas a caminho e as absorções já aplicadas. É o que evita cura em excesso e duplicação com o outro curandeiro.",
        ["roles_healer_rf_debuffs_title"]      = "Debuffs de raide",
        ["roles_healer_rf_debuffs_desc"]       = "Os debuffs importantes aparecem no quadro do jogador afetado. Vale ajustar ao conteúdo do momento.",
        ["roles_healer_rf_range_title"]        = "Indicador de alcance",
        ["roles_healer_rf_range_desc"]         = "Os quadros fora de alcance esmaecem. O ajuste mais subestimado da função: você para de conjurar à toa.",
        ["roles_healer_rf_defs_title"]         = "Rastreio de defensivas",
        ["roles_healer_rf_defs_desc"]          = "Ver quem já mitigou evita queimar uma cura grande em alguém que não corre risco.",
        -- dps
        ["roles_dps_rb_bars_title"]            = "Barras de recurso",
        ["roles_dps_rb_bars_desc"]             = "Pontos de combo, runas, fragmentos — ler seu recurso guia toda a rotação. Aumente sem hesitar.",
        ["roles_dps_cdm_title"]                = "Recargas e procs",
        ["roles_dps_cdm_desc"]                 = "Rastreio de recargas e brilho de procs. A verificação de alcance evita apertar fora de alcance.",
        ["roles_dps_np_auras_title"]           = "Suas auras nas placas",
        ["roles_dps_np_auras_desc"]            = "Mostrar apenas seus próprios debuffs torna o rastreio de DoT em vários alvos legível de novo.",
        ["roles_dps_np_buffs_title"]           = "Bônus defensivos inimigos",
        ["roles_dps_np_buffs_desc"]            = "Perceber um escudo ou redução de dano no alvo evita desperdiçar seu burst.",
        ["roles_dps_cb_gcd_title"]             = "Faísca de GCD",
        ["roles_dps_cb_gcd_desc"]              = "Uma marca visual na barra de conjuração para apertar sua rotação e reduzir o tempo morto entre magias.",
        ["roles_dps_cb_kick_title"]            = "Retorno de interrupção",
        ["roles_dps_cb_kick_desc"]             = "Confirmação visível quando seu kick acerta. Útil quando vários jogadores dividem uma rotação de interrupções.",
    })

end

local function Localize(key, fallback)
    local v = L and L[key]
    if v and v ~= key then return v end
    return fallback or key
end

-- ---------------------------------------------------------------------
-- Guide data
-- ---------------------------------------------------------------------
-- cat      : nav category the setting lives in
-- path     : one tab key per nesting level, outermost first. Declared
--            explicitly rather than looked up: only the first tab of a tab
--            panel is built eagerly, so a section in any other sub-tab was
--            absent from the search index and the link fell back to merely
--            opening the category — which re-showed the cached page on
--            whatever tab the player had last used.
-- section  : LOCALE KEY of the section header to land on. Resolved at
--            display time so it follows the active language; the search
--            index stores the resolved string.
local ROLE_DEFS = {
    tank = {
        preset = "tank",
        role   = "TANK",
        icon   = ROLE_TEX .. "TANK.tga",
        color  = { 0.28, 0.52, 0.92 },
        cards  = {
            { key = "np_tankmode",  cat = "units",     path = { "nameplates", "advanced" }, section = "section_tank_mode" },
            { key = "np_buffs",    cat = "units",     path = { "nameplates", "auras" }, section = "section_enemy_buffs" },
            { key = "np_cast",     cat = "units",     path = { "nameplates", "general" }, section = "section_castbar" },
            { key = "uf_threat",   cat = "units",     path = { "unitframes", "target", "display" }, section = "section_threat_text" },
            { key = "pf_cd",       cat = "units",     path = { "partyframes", "cooldowns" }, section = "pf_section_cooldowns" },
            { key = "rb_health",   cat = "combat",    path = { "resources", "resource" }, section = "section_rb_healthbar" },
        },
    },
    healer = {
        preset = "healer",
        role   = "HEALER",
        icon   = ROLE_TEX .. "HEALER.tga",
        color  = { 0.36, 0.82, 0.42 },
        cards  = {
            { key = "pf_hots",     cat = "units",     path = { "partyframes", "features" }, section = "pf_section_hots" },
            { key = "pf_dispel",   cat = "units",     path = { "partyframes", "features" }, section = "pf_section_dispel" },
            { key = "rf_extras",   cat = "units",     path = { "raidframes", "features" }, section = "rf_section_health_extras" },
            { key = "rf_debuffs",  cat = "units",     path = { "raidframes", "features" }, section = "rf_section_debuffs" },
            { key = "rf_range",    cat = "units",     path = { "raidframes", "features" }, section = "rf_section_range" },
            { key = "rf_defs",     cat = "units",     path = { "raidframes", "features" }, section = "rf_section_defensives" },
        },
    },
    dps = {
        preset = "dps",
        role   = "DAMAGER",
        icon   = ROLE_TEX .. "DAMAGER.tga",
        color  = { 0.85, 0.32, 0.32 },
        cards  = {
            { key = "rb_bars",     cat = "combat",    path = { "resources", "resource" }, section = "section_dimensions" },
            { key = "cdm",         cat = "combat",    path = { "resources", "cdm" }, section = "section_cdm_extras" },
            { key = "np_auras",    cat = "units",     path = { "nameplates", "auras" }, section = "section_auras" },
            { key = "np_buffs",    cat = "units",     path = { "nameplates", "auras" }, section = "section_enemy_buffs" },
            { key = "cb_gcd",      cat = "combat",    path = { "castbars", "general" }, section = "cb_section_gcd" },
            { key = "cb_kick",     cat = "combat",    path = { "castbars", "general" }, section = "cb_section_interrupt" },
        },
    },
}

-- ---------------------------------------------------------------------
-- Navigation
-- ---------------------------------------------------------------------
-- Hoisted: one closure for every link button rather than one per button.
local function OnGotoClick(self)
    local GS = TomoMod_GlobalSearch
    -- The declared route wins: it names the exact tab at every level, so it
    -- lands on a page that has never been built and never depends on how far
    -- ghost indexing has got. JumpToSection stays as the fallback for a card
    -- with no path, and for a section the route no longer resolves to.
    if GS and GS.JumpToPath and self._path
       and GS.JumpToPath(self._cat, self._path, self._sectionText) then
        return
    end
    if GS and GS.JumpToSection then
        GS.JumpToSection(self._cat, self._sectionText)
        return
    end
    -- GlobalSearch.lua absent: land on the category, no section highlight.
    local C = TomoMod_Config
    if C and C.SwitchCategory then C.SwitchCategory(self._cat) end
end

local function OnGotoEnter(self)
    self:SetBackdropBorderColor(self._color[1], self._color[2], self._color[3], 1)
    self._lbl:SetTextColor(1, 1, 1, 1)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self._sectionText, 1, 1, 1)
    GameTooltip:AddLine(Localize("roles_goto_tip",
        "Ouvre le panneau qui contient ce réglage et le met en surbrillance."),
        0.62, 0.62, 0.70, true)
    GameTooltip:Show()
end

local function OnGotoLeave(self)
    self:SetBackdropBorderColor(self._color[1], self._color[2], self._color[3], 0.45)
    self._lbl:SetTextColor(self._color[1], self._color[2], self._color[3], 1)
    GameTooltip:Hide()
end

local function CreateGotoButton(parent, def, color, sectionText, yOffset)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(210, 24)
    btn:SetPoint("TOPLEFT", 16, yOffset)
    btn:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    btn:SetBackdropColor(color[1] * 0.14, color[2] * 0.14, color[3] * 0.14, 0.9)
    btn:SetBackdropBorderColor(color[1], color[2], color[3], 0.45)

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 10, "")
    lbl:SetPoint("CENTER")
    lbl:SetText(Localize("roles_goto", "Aller au réglage →"))
    lbl:SetTextColor(color[1], color[2], color[3], 1)

    btn._cat         = def.cat
    btn._path        = def.path
    btn._sectionText = sectionText
    btn._color       = color
    btn._lbl         = lbl

    btn:SetScript("OnEnter", OnGotoEnter)
    btn:SetScript("OnLeave", OnGotoLeave)
    btn:SetScript("OnClick", OnGotoClick)

    return btn, yOffset - 32
end

-- ---------------------------------------------------------------------
-- Header
-- ---------------------------------------------------------------------
local function OnPresetClick(self)
    local P = TomoMod_Presets
    if not (P and P.Apply) then return end
    if P.Apply(self._presetKey) then
        StaticPopup_Show("TOMOMOD_ROLE_PRESET_RELOAD")
    end
end

local function OnFocusClick(self)
    if W and W.SetRoleFilter then W.SetRoleFilter(self._roleKey) end

    -- Persisted exactly like the sidebar's own role buttons write it, so a
    -- focus set from a guide page survives closing the window. ConfigUI's
    -- GuiDB() is a local there; the table it hands back is this one.
    if TomoModDB then
        TomoModDB.configGUI = TomoModDB.configGUI or {}
        TomoModDB.configGUI.roleFilter = (self._roleKey ~= "ALL") and self._roleKey or nil
    end

    local C = TomoMod_Config
    if C and C.RefreshRoleButtons then C.RefreshRoleButtons() end
end

local function CreateRoleHeader(parent, roleKey, def, y)
    local color = def.color
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetPoint("TOPLEFT",  8, y)
    panel:SetPoint("TOPRIGHT", -8, y)
    panel:SetHeight(104)
    panel:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    panel:SetBackdropColor(0.045, 0.042, 0.065, 0.96)
    panel:SetBackdropBorderColor(color[1], color[2], color[3], 0.40)

    local bar = panel:CreateTexture(nil, "ARTWORK")
    bar:SetWidth(3)
    bar:SetPoint("TOPLEFT", 0, -1)
    bar:SetPoint("BOTTOMLEFT", 0, 1)
    bar:SetColorTexture(color[1], color[2], color[3], 0.95)

    local wash = panel:CreateTexture(nil, "BACKGROUND", nil, -1)
    wash:SetPoint("TOPLEFT", 1, -1)
    wash:SetPoint("BOTTOMRIGHT", -1, 1)
    if wash.SetGradientAlpha then
        wash:SetGradientAlpha("HORIZONTAL", color[1], color[2], color[3], 0.14, 0, 0, 0, 0)
    else
        wash:SetColorTexture(color[1], color[2], color[3], 0.07)
    end

    local icon = panel:CreateTexture(nil, "OVERLAY")
    icon:SetSize(44, 44)
    icon:SetPoint("TOPLEFT", 18, -14)
    icon:SetTexture(def.icon)
    icon:SetVertexColor(color[1], color[2], color[3], 1)

    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_BOLD, 16, "")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 14, -2)
    title:SetText(Localize("roles_title_" .. roleKey, roleKey))
    title:SetTextColor(color[1], color[2], color[3], 1)

    local intro = panel:CreateFontString(nil, "OVERLAY")
    intro:SetFont(FONT, 11, "")
    intro:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    intro:SetPoint("RIGHT", panel, "RIGHT", -18, 0)
    intro:SetJustifyH("LEFT")
    intro:SetJustifyV("TOP")
    intro:SetHeight(30)
    intro:SetSpacing(2)
    intro:SetText(Localize("roles_intro_" .. roleKey, ""))
    intro:SetTextColor(0.70, 0.70, 0.78, 1)

    -- Action row. Both buttons are optional: they only appear when the
    -- feature they drive is actually installed.
    local x = 18
    local function ActionButton(text, width, handler, tag, value)
        local btn = CreateFrame("Button", nil, panel, "BackdropTemplate")
        btn:SetSize(width, 22)
        btn:SetPoint("BOTTOMLEFT", x, 12)
        btn:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
        btn:SetBackdropColor(color[1] * 0.16, color[2] * 0.16, color[3] * 0.16, 0.92)
        btn:SetBackdropBorderColor(color[1], color[2], color[3], 0.55)
        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT, 10, "")
        lbl:SetPoint("CENTER")
        lbl:SetText(text)
        lbl:SetTextColor(color[1], color[2], color[3], 1)
        btn[tag] = value
        btn._color, btn._lbl = color, lbl
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(color[1], color[2], color[3], 1)
            lbl:SetTextColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(color[1], color[2], color[3], 0.55)
            lbl:SetTextColor(color[1], color[2], color[3], 1)
        end)
        btn:SetScript("OnClick", handler)
        x = x + width + 8
        return btn
    end

    if TomoMod_Presets and TomoMod_Presets.Apply and TomoMod_Presets.IsApplicable
        and TomoMod_Presets.IsApplicable(def.preset) then
        ActionButton(Localize("roles_apply_preset", "Appliquer ce preset"), 190,
            OnPresetClick, "_presetKey", def.preset)
    end

    if W and W.SetRoleFilter then
        ActionButton(Localize("roles_focus_filter", "Filtrer l'interface sur ce rôle"), 220,
            OnFocusClick, "_roleKey", def.role)
    end

    return y - 104 - 10
end

-- ---------------------------------------------------------------------
-- Page builder
-- ---------------------------------------------------------------------
local function BuildRolePage(parent, roleKey)
    local def = ROLE_DEFS[roleKey]
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -12

    y = CreateRoleHeader(c, roleKey, def, y)

    for _, entry in ipairs(def.cards) do
        local sectionText = L[entry.section]
        local titleKey = "roles_" .. roleKey .. "_" .. entry.key .. "_title"
        local descKey  = "roles_" .. roleKey .. "_" .. entry.key .. "_desc"

        local card, cy = W.CreateCard(c, Localize(titleKey, sectionText), y)

        local body = card.inner:CreateFontString(nil, "OVERLAY")
        body:SetFont(FONT, 11, "")
        body:SetPoint("TOPLEFT",  16, cy - 2)
        body:SetPoint("RIGHT", card.inner, "RIGHT", -16, 0)
        body:SetJustifyH("LEFT")
        body:SetJustifyV("TOP")
        body:SetSpacing(2)
        body:SetText(Localize(descKey, ""))
        body:SetTextColor(0.72, 0.72, 0.80, 1)

        local rawH  = body:GetStringHeight() or 0
        if rawH < 12 then rawH = 12 end
        local lines = math.max(1, math.ceil(rawH / 13))
        body:SetHeight(lines * 14)
        cy = cy - (lines * 14) - 12

        local _, afterBtn = CreateGotoButton(card.inner, entry, def.color, sectionText, cy)
        cy = afterBtn

        y = W.FinalizeCard(card, cy)
    end

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

function TomoMod_ConfigPanel_RoleTank(parent)   return BuildRolePage(parent, "tank")   end
function TomoMod_ConfigPanel_RoleHealer(parent) return BuildRolePage(parent, "healer") end
function TomoMod_ConfigPanel_RoleDps(parent)    return BuildRolePage(parent, "dps")    end

StaticPopupDialogs["TOMOMOD_ROLE_PRESET_RELOAD"] = {
    text     = Localize("dash_reload_popup", "Recharger l'interface maintenant ?"),
    button1  = Localize("popup_confirm", "Confirmer"),
    button2  = Localize("popup_cancel", "Annuler"),
    OnAccept = function() ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

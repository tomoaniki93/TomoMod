-- ============================================================
-- Presets.lua — Configuration archetypes (TomoMod 3.0)
-- ------------------------------------------------------------
-- Preset engine: each archetype writes a coherent, deterministic
-- configuration into TomoModDB. Backs both the "presets first"
-- installer and the dashboard preset cards.
--
-- Model:
--   1. BASE  — the role-neutral recommended state. Explicit on/off
--              (or explicit value) for EVERY key any delta may
--              touch, so switching archetypes never leaves residue.
--   2. DELTA — each preset = BASE + a set of overrides.
--   Apply(key) ALWAYS writes BASE then the DELTA, so moving from
--   one preset to another is 100% deterministic and idempotent.
--
-- INVARIANT: every path used in a DELTA must also exist in BASE.
-- Without it, going tank -> healer would keep the tank value for
-- any key healer does not restate. BASE is the reset floor.
--
-- Presets only write "what is enabled" plus the role-signature
-- values (sizes, thresholds, aura counts). They never move frames:
-- positions stay defaults / user choice.
-- ============================================================

TomoMod_Presets = TomoMod_Presets or {}
local P = TomoMod_Presets

-- ------------------------------------------------------------
-- LOCALES (self-contained — no need to touch the big files)
-- enUS = base fallback; frFR = primary language. Every key is
-- defined in all six locales: the locale metatable returns the
-- raw key string for undefined keys, so it is not a safety net.
-- ------------------------------------------------------------
if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["preset_complet_name"]  = "Recommended",
        ["preset_complet_tag"]   = "The full TomoMod experience",
        ["preset_complet_desc"]  = "Enables every core module with balanced settings: unit frames, party & raid frames, nameplates, castbars, resources, action bar skin, all visual skins, Mythic+ tools and the most useful quality-of-life features. No role is favoured — this is the foundation the Tank, Healer and DPS presets build on.",
        ["preset_complet_h1"]    = "Every core module enabled",
        ["preset_complet_h2"]    = "Balanced settings, no role favoured",
        ["preset_complet_h3"]    = "The best place to start",

        ["preset_tank_name"]     = "Tank",
        ["preset_tank_tag"]      = "Threat-focused, wider nameplates",
        ["preset_tank_desc"]     = "The Recommended base, retuned for tanking: wider threat-coloured nameplates, unselected plates kept bright so you can read the whole pull, larger enemy buffs (enrages and shields), a thicker plate castbar for interrupts, numeric threat on your target, party interrupt and battle-res cooldowns, and a personal health bar warning at 40%. HoTs are hidden to reduce clutter.",
        ["preset_tank_h1"]       = "Wide, threat-coloured nameplates",
        ["preset_tank_h2"]       = "Numeric threat on your target",
        ["preset_tank_h3"]       = "Personal health bar, 40% warning",

        ["preset_healer_name"]   = "Healer",
        ["preset_healer_tag"]    = "Bigger frames, healing info up front",
        ["preset_healer_desc"]   = "The Recommended base, retuned for healing: noticeably larger and more clickable party & raid frames, more and bigger HoT icons, a thicker dispel border, defensive and absorb tracking, heal prediction and missing health shown, stronger out-of-range fading and a mana warning at 30%. Nameplates are dimmed and thinned out to keep the play area clear.",
        ["preset_healer_h1"]     = "Larger party and raid frames",
        ["preset_healer_h2"]     = "HoTs, dispels and shields up front",
        ["preset_healer_h3"]     = "Missing health shown, mana warning",

        ["preset_dps_name"]      = "DPS",
        ["preset_dps_tag"]       = "Emphasized resources & cooldowns",
        ["preset_dps_desc"]      = "The Recommended base, retuned for damage: taller resource bars with a low-resource threshold, cooldowns and procs emphasized with range checking, only your own debuffs shown on the target and on nameplates, enemy defensive buffs tracked, and the GCD spark enabled. Raid frames are compacted and HoTs hidden to free up screen space.",
        ["preset_dps_h1"]        = "Resources and cooldowns emphasized",
        ["preset_dps_h2"]        = "Only your own debuffs on the target",
        ["preset_dps_h3"]        = "Enemy defensives tracked",

        ["preset_minimal_name"]  = "Minimal",
        ["preset_minimal_tag"]   = "Just the essentials",
        ["preset_minimal_desc"]  = "A lightweight footprint: keeps unit frames, party & raid frames, castbars, resource bars, the minimap and the most essential automations — everything cosmetic (skins, chat, bags, nameplates, extra panels) stays off, and the heavier frame trackers (HoTs, defensives, debuffs) are switched off too. Closest to a vanilla feel.",
        ["preset_minimal_h1"]    = "Frames, castbars and resources only",
        ["preset_minimal_h2"]    = "No skins, no side panels",
        ["preset_minimal_h3"]    = "Smaller memory footprint",

        ["preset_custom_name"]   = "Custom",
        ["preset_custom_tag"]    = "Configure everything yourself",
        ["preset_custom_desc"]   = "Skip the presets and walk through every category step by step to enable exactly what you want. You can always change anything later from /tm.",
        ["preset_custom_h1"]     = "Step-by-step walkthrough",
        ["preset_custom_h2"]     = "Nothing is written until you choose",
        ["preset_custom_h3"]     = "Everything stays editable from /tm",

        ["preset_badge_recommended"] = "Recommended",
        ["preset_badge_active"]      = "Active",
        ["preset_applied"]       = "Preset applied: %s — type /reload to see the result.",
        ["preset_unknown"]       = "Unknown preset '%s'. Available: complet, tank, healer, dps, minimal.",
        ["preset_usage"]         = "Usage: /tmpreset <complet|tank|healer|dps|minimal>",
    })

    TomoMod_RegisterLocale("frFR", {
        ["preset_complet_name"]  = "Recommandé",
        ["preset_complet_tag"]   = "L'expérience TomoMod complète",
        ["preset_complet_desc"]  = "Active tous les modules principaux avec des réglages équilibrés : unit frames, cadres de groupe et de raid, nameplates, barres d'incantation, ressources, skin des barres d'action, tous les skins visuels, les outils Mythic+ et le confort. Aucun rôle n'est privilégié — c'est la base sur laquelle les presets Tank, Soigneur et DPS se greffent.",
        ["preset_complet_h1"]    = "Tous les modules principaux activés",
        ["preset_complet_h2"]    = "Réglages équilibrés, aucun rôle privilégié",
        ["preset_complet_h3"]    = "Le meilleur point de départ",

        ["preset_tank_name"]     = "Tank",
        ["preset_tank_tag"]      = "Axé menace, nameplates élargies",
        ["preset_tank_desc"]     = "La base Recommandée, retravaillée pour le tanking : nameplates élargies et colorées selon la menace, plaques non ciblées gardées lisibles pour suivre tout le pull, buffs ennemis agrandis (enrages, boucliers), barre d'incantation des plaques épaissie pour les interruptions, menace chiffrée sur la cible, cooldowns d'interruption et de résurrection du groupe, et barre de vie personnelle avec alerte à 40 %. Les HoTs sont masqués pour désencombrer.",
        ["preset_tank_h1"]       = "Nameplates larges, colorées selon la menace",
        ["preset_tank_h2"]       = "Menace chiffrée sur la cible",
        ["preset_tank_h3"]       = "Barre de vie perso, alerte à 40 %",

        ["preset_healer_name"]   = "Soigneur",
        ["preset_healer_tag"]    = "Cadres agrandis, infos de soin en avant",
        ["preset_healer_desc"]   = "La base Recommandée, retravaillée pour le soin : cadres de groupe et de raid nettement agrandis et plus faciles à cliquer, HoTs plus nombreux et plus gros, bordure de dissipation épaissie, suivi des défensifs et des boucliers, prévision de soin et vie manquante affichées, hors de portée plus marqué, alerte de mana à 30 %. Les nameplates sont estompées et allégées pour dégager la zone de jeu.",
        ["preset_healer_h1"]     = "Cadres de groupe et de raid agrandis",
        ["preset_healer_h2"]     = "HoTs, dissipations et boucliers en évidence",
        ["preset_healer_h3"]     = "Vie manquante affichée, alerte de mana",

        ["preset_dps_name"]      = "DPS",
        ["preset_dps_tag"]       = "Ressources et cooldowns mis en avant",
        ["preset_dps_desc"]      = "La base Recommandée, retravaillée pour les dégâts : barres de ressource agrandies avec seuil bas, cooldowns et procs mis en avant avec vérification de portée, seuls tes propres debuffs s'affichent sur la cible et sur les nameplates, buffs défensifs ennemis suivis, étincelle de GCD activée. Les cadres de raid sont compactés et les HoTs masqués pour libérer de la place.",
        ["preset_dps_h1"]        = "Ressources et cooldowns mis en avant",
        ["preset_dps_h2"]        = "Uniquement tes propres debuffs sur la cible",
        ["preset_dps_h3"]        = "Défensifs ennemis suivis",

        ["preset_minimal_name"]  = "Minimal",
        ["preset_minimal_tag"]   = "Juste l'essentiel",
        ["preset_minimal_desc"]  = "Une empreinte légère : on garde les unit frames, les cadres de groupe et de raid, les barres d'incantation, les barres de ressource, la minimap et les automatisations essentielles — tout le cosmétique (skins, chat, sacs, nameplates, panneaux annexes) reste désactivé, et les suivis lourds des cadres (HoTs, défensifs, debuffs) sont coupés également. Au plus proche d'une sensation vanilla.",
        ["preset_minimal_h1"]    = "Cadres, incantations et ressources uniquement",
        ["preset_minimal_h2"]    = "Aucun skin, aucun panneau annexe",
        ["preset_minimal_h3"]    = "Empreinte mémoire réduite",

        ["preset_custom_name"]   = "Personnalisé",
        ["preset_custom_tag"]    = "Tout configurer soi-même",
        ["preset_custom_desc"]   = "Passez les presets et parcourez chaque catégorie étape par étape pour activer exactement ce que vous voulez. Tout reste modifiable ensuite via /tm.",
        ["preset_custom_h1"]     = "Parcours étape par étape",
        ["preset_custom_h2"]     = "Rien n'est écrit avant votre choix",
        ["preset_custom_h3"]     = "Tout reste modifiable via /tm",

        ["preset_badge_recommended"] = "Recommandé",
        ["preset_badge_active"]      = "Actif",
        ["preset_applied"]       = "Preset appliqué : %s — tapez /reload pour voir le résultat.",
        ["preset_unknown"]       = "Preset inconnu « %s ». Disponibles : complet, tank, healer, dps, minimal.",
        ["preset_usage"]         = "Usage : /tmpreset <complet|tank|healer|dps|minimal>",
    })

    TomoMod_RegisterLocale("deDE", {
        ["preset_complet_name"]  = "Empfohlen",
        ["preset_complet_tag"]   = "Das komplette TomoMod-Erlebnis",
        ["preset_complet_desc"]  = "Aktiviert alle Kernmodule mit ausgewogenen Einstellungen: Einheitenfenster, Gruppen- und Schlachtzugsfenster, Namensplaketten, Zauberleisten, Ressourcen, Aktionsleisten-Skin, alle visuellen Skins, Mythisch+-Werkzeuge und Komfortfunktionen. Keine Rolle wird bevorzugt — dies ist die Grundlage für die Presets Tank, Heiler und DPS.",
        ["preset_complet_h1"]    = "Alle Kernmodule aktiviert",
        ["preset_complet_h2"]    = "Ausgewogen, keine Rolle bevorzugt",
        ["preset_complet_h3"]    = "Der beste Ausgangspunkt",

        ["preset_tank_name"]     = "Tank",
        ["preset_tank_tag"]      = "Bedrohungsfokus, breitere Plaketten",
        ["preset_tank_desc"]     = "Die empfohlene Grundlage, auf das Tanken abgestimmt: breitere, nach Bedrohung eingefärbte Namensplaketten, nicht ausgewählte Plaketten bleiben gut lesbar, größere Gegnerstärkungen (Wutanfälle, Schilde), dickere Zauberleiste auf Plaketten für Unterbrechungen, numerische Bedrohung am Ziel, Unterbrechungs- und Kampfwiederbelebungs-Abklingzeiten der Gruppe sowie eine eigene Lebensleiste mit Warnung bei 40%. HoTs werden ausgeblendet.",
        ["preset_tank_h1"]       = "Breite, bedrohungsgefärbte Plaketten",
        ["preset_tank_h2"]       = "Numerische Bedrohung am Ziel",
        ["preset_tank_h3"]       = "Eigene Lebensleiste, Warnung bei 40%",

        ["preset_healer_name"]   = "Heiler",
        ["preset_healer_tag"]    = "Größere Fenster, Heilinfos im Fokus",
        ["preset_healer_desc"]   = "Die empfohlene Grundlage, auf das Heilen abgestimmt: deutlich größere und besser anklickbare Gruppen- und Schlachtzugsfenster, mehr und größere HoT-Symbole, dickerer Entzauberungsrahmen, Verfolgung von Verteidigungszaubern und Absorptionen, Heilvorhersage und fehlende Gesundheit sichtbar, stärkeres Ausblenden außer Reichweite und eine Mana-Warnung bei 30%. Namensplaketten werden abgedunkelt und ausgedünnt.",
        ["preset_healer_h1"]     = "Größere Gruppen- und Schlachtzugsfenster",
        ["preset_healer_h2"]     = "HoTs, Entzauberungen und Schilde im Fokus",
        ["preset_healer_h3"]     = "Fehlende Gesundheit, Mana-Warnung",

        ["preset_dps_name"]      = "DPS",
        ["preset_dps_tag"]       = "Ressourcen und Abklingzeiten betont",
        ["preset_dps_desc"]      = "Die empfohlene Grundlage, auf Schaden abgestimmt: höhere Ressourcenleisten mit Schwellenwarnung, hervorgehobene Abklingzeiten und Procs mit Reichweitenprüfung, nur eigene Schwächungszauber am Ziel und auf Namensplaketten, Verfolgung gegnerischer Verteidigungszauber und aktivierter GCD-Funke. Schlachtzugsfenster werden kompakter, HoTs ausgeblendet.",
        ["preset_dps_h1"]        = "Ressourcen und Abklingzeiten betont",
        ["preset_dps_h2"]        = "Nur eigene Schwächungszauber am Ziel",
        ["preset_dps_h3"]        = "Gegnerische Verteidigungszauber verfolgt",

        ["preset_minimal_name"]  = "Minimal",
        ["preset_minimal_tag"]   = "Nur das Nötigste",
        ["preset_minimal_desc"]  = "Ein schlanker Fußabdruck: Einheitenfenster, Gruppen- und Schlachtzugsfenster, Zauberleisten, Ressourcenleisten, die Minikarte und die wichtigsten Automatisierungen bleiben erhalten — alles Kosmetische (Skins, Chat, Taschen, Namensplaketten, Zusatzpanels) bleibt aus, ebenso die aufwendigen Fenster-Tracker (HoTs, Verteidigungszauber, Schwächungszauber).",
        ["preset_minimal_h1"]    = "Nur Fenster, Zauberleisten, Ressourcen",
        ["preset_minimal_h2"]    = "Keine Skins, keine Zusatzpanels",
        ["preset_minimal_h3"]    = "Geringerer Speicherbedarf",

        ["preset_custom_name"]   = "Benutzerdefiniert",
        ["preset_custom_tag"]    = "Alles selbst einrichten",
        ["preset_custom_desc"]   = "Überspringe die Presets und gehe jede Kategorie Schritt für Schritt durch, um genau das zu aktivieren, was du möchtest. Alles lässt sich später über /tm ändern.",
        ["preset_custom_h1"]     = "Schritt-für-Schritt-Durchlauf",
        ["preset_custom_h2"]     = "Nichts wird vor deiner Wahl geschrieben",
        ["preset_custom_h3"]     = "Alles bleibt über /tm änderbar",

        ["preset_badge_recommended"] = "Empfohlen",
        ["preset_badge_active"]      = "Aktiv",
        ["preset_applied"]       = "Preset angewendet: %s — gib /reload ein, um das Ergebnis zu sehen.",
        ["preset_unknown"]       = "Unbekanntes Preset '%s'. Verfügbar: complet, tank, healer, dps, minimal.",
        ["preset_usage"]         = "Verwendung: /tmpreset <complet|tank|healer|dps|minimal>",
    })

    TomoMod_RegisterLocale("esES", {
        ["preset_complet_name"]  = "Recomendado",
        ["preset_complet_tag"]   = "La experiencia TomoMod completa",
        ["preset_complet_desc"]  = "Activa todos los módulos principales con ajustes equilibrados: marcos de unidad, marcos de grupo y banda, placas de nombre, barras de lanzamiento, recursos, skin de barras de acción, todos los skins visuales, herramientas de Mítica+ y funciones de comodidad. No se favorece ningún rol — es la base sobre la que se apoyan los presets Tanque, Sanador y DPS.",
        ["preset_complet_h1"]    = "Todos los módulos principales activados",
        ["preset_complet_h2"]    = "Equilibrado, sin favorecer un rol",
        ["preset_complet_h3"]    = "El mejor punto de partida",

        ["preset_tank_name"]     = "Tanque",
        ["preset_tank_tag"]      = "Centrado en amenaza, placas más anchas",
        ["preset_tank_desc"]     = "La base Recomendada, reajustada para tanquear: placas de nombre más anchas y coloreadas por amenaza, placas no seleccionadas legibles para seguir todo el grupo de enemigos, beneficios enemigos más grandes (enfurecimientos, escudos), barra de lanzamiento de placa más gruesa para interrupciones, amenaza numérica en el objetivo, reutilizaciones de interrupción y resurrección del grupo, y barra de vida propia con aviso al 40 %. Los HoTs se ocultan.",
        ["preset_tank_h1"]       = "Placas anchas, coloreadas por amenaza",
        ["preset_tank_h2"]       = "Amenaza numérica en el objetivo",
        ["preset_tank_h3"]       = "Barra de vida propia, aviso al 40 %",

        ["preset_healer_name"]   = "Sanador",
        ["preset_healer_tag"]    = "Marcos más grandes, info de sanación",
        ["preset_healer_desc"]   = "La base Recomendada, reajustada para sanar: marcos de grupo y banda notablemente más grandes y fáciles de pulsar, más iconos de HoT y más grandes, borde de disipación más grueso, seguimiento de defensivas y absorciones, predicción de sanación y vida que falta visibles, desvanecido fuera de alcance más marcado y aviso de maná al 30 %. Las placas de nombre se atenúan y aligeran.",
        ["preset_healer_h1"]     = "Marcos de grupo y banda más grandes",
        ["preset_healer_h2"]     = "HoTs, disipaciones y escudos destacados",
        ["preset_healer_h3"]     = "Vida que falta visible, aviso de maná",

        ["preset_dps_name"]      = "DPS",
        ["preset_dps_tag"]       = "Recursos y reutilizaciones destacados",
        ["preset_dps_desc"]      = "La base Recomendada, reajustada para el daño: barras de recurso más altas con umbral bajo, reutilizaciones y procs destacados con comprobación de alcance, solo tus propios perjuicios en el objetivo y en las placas de nombre, seguimiento de beneficios defensivos enemigos y chispa de GCD activada. Los marcos de banda se compactan y los HoTs se ocultan.",
        ["preset_dps_h1"]        = "Recursos y reutilizaciones destacados",
        ["preset_dps_h2"]        = "Solo tus propios perjuicios en el objetivo",
        ["preset_dps_h3"]        = "Defensivas enemigas rastreadas",

        ["preset_minimal_name"]  = "Mínimo",
        ["preset_minimal_tag"]   = "Solo lo esencial",
        ["preset_minimal_desc"]  = "Una huella ligera: se mantienen los marcos de unidad, de grupo y de banda, las barras de lanzamiento, las barras de recurso, el minimapa y las automatizaciones esenciales — todo lo cosmético (skins, chat, bolsas, placas de nombre, paneles adicionales) queda desactivado, así como los rastreadores pesados de marcos (HoTs, defensivas, perjuicios).",
        ["preset_minimal_h1"]    = "Solo marcos, lanzamiento y recursos",
        ["preset_minimal_h2"]    = "Sin skins ni paneles adicionales",
        ["preset_minimal_h3"]    = "Menor consumo de memoria",

        ["preset_custom_name"]   = "Personalizado",
        ["preset_custom_tag"]    = "Configurarlo todo tú mismo",
        ["preset_custom_desc"]   = "Omite los presets y recorre cada categoría paso a paso para activar exactamente lo que quieras. Siempre podrás cambiarlo después desde /tm.",
        ["preset_custom_h1"]     = "Recorrido paso a paso",
        ["preset_custom_h2"]     = "No se escribe nada hasta que elijas",
        ["preset_custom_h3"]     = "Todo sigue siendo editable desde /tm",

        ["preset_badge_recommended"] = "Recomendado",
        ["preset_badge_active"]      = "Activo",
        ["preset_applied"]       = "Preset aplicado: %s — escribe /reload para ver el resultado.",
        ["preset_unknown"]       = "Preset desconocido «%s». Disponibles: complet, tank, healer, dps, minimal.",
        ["preset_usage"]         = "Uso: /tmpreset <complet|tank|healer|dps|minimal>",
    })

    TomoMod_RegisterLocale("itIT", {
        ["preset_complet_name"]  = "Consigliato",
        ["preset_complet_tag"]   = "L'esperienza TomoMod completa",
        ["preset_complet_desc"]  = "Attiva tutti i moduli principali con impostazioni equilibrate: riquadri unità, riquadri gruppo e incursione, targhette, barre di lancio, risorse, skin delle barre azione, tutte le skin visive, strumenti Mitica+ e funzioni di comodità. Nessun ruolo è favorito — è la base su cui si innestano i preset Difensore, Guaritore e DPS.",
        ["preset_complet_h1"]    = "Tutti i moduli principali attivi",
        ["preset_complet_h2"]    = "Equilibrato, nessun ruolo favorito",
        ["preset_complet_h3"]    = "Il miglior punto di partenza",

        ["preset_tank_name"]     = "Difensore",
        ["preset_tank_tag"]      = "Focus minaccia, targhette più larghe",
        ["preset_tank_desc"]     = "La base Consigliata, ritarata per il tanking: targhette più larghe e colorate in base alla minaccia, targhette non selezionate ben leggibili per seguire l'intero gruppo di nemici, potenziamenti nemici ingranditi (furie, scudi), barra di lancio della targhetta più spessa per le interruzioni, minaccia numerica sul bersaglio, ricariche di interruzione e rianimazione del gruppo e barra della salute personale con avviso al 40%. Gli HoT sono nascosti.",
        ["preset_tank_h1"]       = "Targhette larghe, colorate per minaccia",
        ["preset_tank_h2"]       = "Minaccia numerica sul bersaglio",
        ["preset_tank_h3"]       = "Barra salute personale, avviso al 40%",

        ["preset_healer_name"]   = "Guaritore",
        ["preset_healer_tag"]    = "Riquadri più grandi, info di cura",
        ["preset_healer_desc"]   = "La base Consigliata, ritarata per la cura: riquadri gruppo e incursione decisamente più grandi e più facili da cliccare, icone HoT più numerose e più grandi, bordo di dissolvenza più spesso, monitoraggio di difensive e assorbimenti, previsione di cura e salute mancante visibili, dissolvenza fuori portata più marcata e avviso mana al 30%. Le targhette vengono attenuate e alleggerite.",
        ["preset_healer_h1"]     = "Riquadri gruppo e incursione più grandi",
        ["preset_healer_h2"]     = "HoT, dissolvenze e scudi in evidenza",
        ["preset_healer_h3"]     = "Salute mancante visibile, avviso mana",

        ["preset_dps_name"]      = "DPS",
        ["preset_dps_tag"]       = "Risorse e ricariche in evidenza",
        ["preset_dps_desc"]      = "La base Consigliata, ritarata per il danno: barre delle risorse più alte con soglia bassa, ricariche e proc in evidenza con controllo della portata, solo i tuoi debuff sul bersaglio e sulle targhette, monitoraggio delle difensive nemiche e scintilla del GCD attiva. I riquadri incursione vengono compattati e gli HoT nascosti.",
        ["preset_dps_h1"]        = "Risorse e ricariche in evidenza",
        ["preset_dps_h2"]        = "Solo i tuoi debuff sul bersaglio",
        ["preset_dps_h3"]        = "Difensive nemiche monitorate",

        ["preset_minimal_name"]  = "Minimo",
        ["preset_minimal_tag"]   = "Solo l'essenziale",
        ["preset_minimal_desc"]  = "Un'impronta leggera: restano i riquadri unità, gruppo e incursione, le barre di lancio, le barre delle risorse, la minimappa e le automazioni essenziali — tutto ciò che è estetico (skin, chat, borse, targhette, pannelli extra) resta disattivato, così come i monitoraggi pesanti dei riquadri (HoT, difensive, debuff).",
        ["preset_minimal_h1"]    = "Solo riquadri, lancio e risorse",
        ["preset_minimal_h2"]    = "Nessuna skin, nessun pannello extra",
        ["preset_minimal_h3"]    = "Impronta di memoria ridotta",

        ["preset_custom_name"]   = "Personalizzato",
        ["preset_custom_tag"]    = "Configurare tutto da sé",
        ["preset_custom_desc"]   = "Salta i preset e percorri ogni categoria passo dopo passo per attivare esattamente ciò che vuoi. Potrai sempre cambiare tutto in seguito da /tm.",
        ["preset_custom_h1"]     = "Percorso passo dopo passo",
        ["preset_custom_h2"]     = "Nulla viene scritto prima della scelta",
        ["preset_custom_h3"]     = "Tutto resta modificabile da /tm",

        ["preset_badge_recommended"] = "Consigliato",
        ["preset_badge_active"]      = "Attivo",
        ["preset_applied"]       = "Preset applicato: %s — digita /reload per vedere il risultato.",
        ["preset_unknown"]       = "Preset sconosciuto «%s». Disponibili: complet, tank, healer, dps, minimal.",
        ["preset_usage"]         = "Uso: /tmpreset <complet|tank|healer|dps|minimal>",
    })

    TomoMod_RegisterLocale("ptBR", {
        ["preset_complet_name"]  = "Recomendado",
        ["preset_complet_tag"]   = "A experiência TomoMod completa",
        ["preset_complet_desc"]  = "Ativa todos os módulos principais com ajustes equilibrados: quadros de unidade, quadros de grupo e raide, placas de nome, barras de conjuração, recursos, skin das barras de ação, todas as skins visuais, ferramentas de Mítica+ e funções de conforto. Nenhuma função é favorecida — é a base sobre a qual os presets Tanque, Curandeiro e DPS se apoiam.",
        ["preset_complet_h1"]    = "Todos os módulos principais ativados",
        ["preset_complet_h2"]    = "Equilibrado, sem favorecer função",
        ["preset_complet_h3"]    = "O melhor ponto de partida",

        ["preset_tank_name"]     = "Tanque",
        ["preset_tank_tag"]      = "Foco em ameaça, placas mais largas",
        ["preset_tank_desc"]     = "A base Recomendada, reajustada para tanquear: placas de nome mais largas e coloridas por ameaça, placas não selecionadas legíveis para acompanhar todo o grupo de inimigos, bônus inimigos ampliados (fúrias, escudos), barra de conjuração da placa mais espessa para interrupções, ameaça numérica no alvo, recargas de interrupção e ressurreição do grupo, e barra de vida própria com aviso em 40%. Os HoTs ficam ocultos.",
        ["preset_tank_h1"]       = "Placas largas, coloridas por ameaça",
        ["preset_tank_h2"]       = "Ameaça numérica no alvo",
        ["preset_tank_h3"]       = "Barra de vida própria, aviso em 40%",

        ["preset_healer_name"]   = "Curandeiro",
        ["preset_healer_tag"]    = "Quadros maiores, info de cura à frente",
        ["preset_healer_desc"]   = "A base Recomendada, reajustada para a cura: quadros de grupo e raide bem maiores e mais fáceis de clicar, mais ícones de HoT e maiores, borda de dissipação mais espessa, rastreio de defensivas e absorções, previsão de cura e vida faltante visíveis, esmaecimento fora de alcance mais marcado e aviso de mana em 30%. As placas de nome são atenuadas e aliviadas.",
        ["preset_healer_h1"]     = "Quadros de grupo e raide maiores",
        ["preset_healer_h2"]     = "HoTs, dissipações e escudos em destaque",
        ["preset_healer_h3"]     = "Vida faltante visível, aviso de mana",

        ["preset_dps_name"]      = "DPS",
        ["preset_dps_tag"]       = "Recursos e recargas em destaque",
        ["preset_dps_desc"]      = "A base Recomendada, reajustada para o dano: barras de recurso mais altas com limiar baixo, recargas e procs em destaque com verificação de alcance, apenas seus próprios debuffs no alvo e nas placas de nome, rastreio de bônus defensivos inimigos e faísca de GCD ativada. Os quadros de raide ficam compactos e os HoTs ocultos.",
        ["preset_dps_h1"]        = "Recursos e recargas em destaque",
        ["preset_dps_h2"]        = "Apenas seus próprios debuffs no alvo",
        ["preset_dps_h3"]        = "Defensivas inimigas rastreadas",

        ["preset_minimal_name"]  = "Mínimo",
        ["preset_minimal_tag"]   = "Apenas o essencial",
        ["preset_minimal_desc"]  = "Uma pegada leve: mantém os quadros de unidade, de grupo e de raide, as barras de conjuração, as barras de recurso, o minimapa e as automações essenciais — tudo o que é cosmético (skins, bate-papo, bolsas, placas de nome, painéis extras) fica desativado, assim como os rastreadores pesados dos quadros (HoTs, defensivas, debuffs).",
        ["preset_minimal_h1"]    = "Apenas quadros, conjuração e recursos",
        ["preset_minimal_h2"]    = "Sem skins nem painéis extras",
        ["preset_minimal_h3"]    = "Menor uso de memória",

        ["preset_custom_name"]   = "Personalizado",
        ["preset_custom_tag"]    = "Configurar tudo você mesmo",
        ["preset_custom_desc"]   = "Pule os presets e percorra cada categoria passo a passo para ativar exatamente o que quiser. Você sempre poderá mudar tudo depois em /tm.",
        ["preset_custom_h1"]     = "Percurso passo a passo",
        ["preset_custom_h2"]     = "Nada é escrito antes da sua escolha",
        ["preset_custom_h3"]     = "Tudo continua editável via /tm",

        ["preset_badge_recommended"] = "Recomendado",
        ["preset_badge_active"]      = "Ativo",
        ["preset_applied"]       = "Preset aplicado: %s — digite /reload para ver o resultado.",
        ["preset_unknown"]       = "Preset desconhecido «%s». Disponíveis: complet, tank, healer, dps, minimal.",
        ["preset_usage"]         = "Uso: /tmpreset <complet|tank|healer|dps|minimal>",
    })
end

local L = TomoMod_L

-- ------------------------------------------------------------
-- Helper : SetPath(root, "a.b.c", value)
-- Creates the missing intermediate tables as needed.
-- ------------------------------------------------------------
local function SplitPath(path)
    local segs = {}
    for seg in string.gmatch(path, "[^.]+") do
        segs[#segs + 1] = seg
    end
    return segs
end

local function SetPath(root, path, value)
    local segs = SplitPath(path)
    local node = root
    for i = 1, #segs - 1 do
        local k = segs[i]
        if type(node[k]) ~= "table" then node[k] = {} end
        node = node[k]
    end
    node[segs[#segs]] = value
end
P.SetPath = SetPath  -- exposed (used by the dashboard / installer)

-- ============================================================
-- BASE — "Recommended", role-neutral
-- Explicit value for EVERY key any delta may override, so BASE
-- doubles as the reset floor when switching archetypes.
-- ============================================================
local BASE = {
    -- ── Frames: module switches ───────────────────────────
    ["unitFrames.enabled"]              = true,
    ["unitFrames.hideBlizzardFrames"]   = true,

    ["partyFrames.enabled"]             = true,
    ["partyFrames.hideBlizzardFrames"]  = true,

    ["raidFrames.enabled"]              = true,
    ["raidFrames.hideBlizzardFrames"]   = true,
    ["raidFrames.skinGroupManager"]     = true,

    ["castbars.enabled"]                = true,
    ["castbars.hideBlizzardCastbar"]    = true,
    ["castbars.useClassColor"]          = true,

    ["nameplates.enabled"]              = true,
    ["nameplates.useClassColors"]       = true,
    ["nameplates.friendlyRoleIcons"]    = true,

    ["resourceBars.enabled"]            = true,
    ["cooldownManager.enabled"]         = true,

    -- ── Role axis: party frames ───────────────────────────
    ["partyFrames.width"]                    = 160,
    ["partyFrames.height"]                   = 40,
    ["partyFrames.showHoTs"]                 = true,
    ["partyFrames.maxHoTs"]                  = 3,
    ["partyFrames.hotSize"]                  = 12,
    ["partyFrames.hotShowDuration"]          = true,
    ["partyFrames.showDispel"]               = true,
    ["partyFrames.dispelSize"]               = 16,
    ["partyFrames.showDefensives"]           = true,
    ["partyFrames.maxDefensives"]            = 2,
    ["partyFrames.defensiveShowExternals"]   = true,
    ["partyFrames.defensiveShowPersonals"]   = false,
    ["partyFrames.showHealPrediction"]       = true,
    ["partyFrames.showAbsorb"]               = true,
    ["partyFrames.showPower"]                = true,
    ["partyFrames.powerHeight"]              = 3,
    ["partyFrames.showRange"]                = true,
    ["partyFrames.oorAlpha"]                 = 0.40,
    ["partyFrames.showHealthText"]           = true,
    ["partyFrames.healthTextFormat"]         = "percent",
    ["partyFrames.showInterruptCD"]          = true,
    ["partyFrames.showBrezCD"]               = true,
    ["partyFrames.sortByRole"]               = true,
    ["partyFrames.showRoleIcon"]             = true,

    -- ── Role axis: raid frames ────────────────────────────
    ["raidFrames.width"]                     = 72,
    ["raidFrames.height"]                    = 36,
    ["raidFrames.layout"]                    = "grid",
    ["raidFrames.showHoTs"]                  = true,
    ["raidFrames.maxHoTs"]                   = 3,
    ["raidFrames.hotSize"]                   = 10,
    ["raidFrames.hotShowDuration"]           = true,
    ["raidFrames.showDispel"]                = true,
    ["raidFrames.dispelSize"]                = 16,
    ["raidFrames.showDebuffs"]               = true,
    ["raidFrames.maxDebuffs"]                = 3,
    ["raidFrames.debuffSize"]                = 14,
    ["raidFrames.showDefensives"]            = true,
    ["raidFrames.maxDefensives"]             = 2,
    ["raidFrames.showHealPrediction"]        = true,
    ["raidFrames.showAbsorb"]                = true,
    ["raidFrames.showPower"]                 = true,
    ["raidFrames.powerHeight"]               = 2,
    ["raidFrames.showRange"]                 = true,
    ["raidFrames.oorAlpha"]                  = 0.40,
    ["raidFrames.showHealthText"]            = false,
    ["raidFrames.healthTextFormat"]          = "percent",
    ["raidFrames.sortByRole"]                = true,

    -- ── Role axis: nameplates ─────────────────────────────
    ["nameplates.width"]                     = 170,
    ["nameplates.height"]                    = 17,
    ["nameplates.tankMode"]                  = false,
    ["nameplates.showThreat"]                = true,
    ["nameplates.showCastbar"]               = true,
    ["nameplates.castbarHeight"]             = 14,
    ["nameplates.showAuras"]                 = true,
    ["nameplates.showOnlyMyAuras"]           = true,
    ["nameplates.maxAuras"]                  = 5,
    ["nameplates.auraSize"]                  = 24,
    ["nameplates.showEnemyBuffs"]            = true,
    ["nameplates.maxEnemyBuffs"]             = 4,
    ["nameplates.enemyBuffSize"]             = 22,
    ["nameplates.showHealthText"]            = true,
    ["nameplates.selectedAlpha"]             = 1.00,
    ["nameplates.unselectedAlpha"]           = 0.80,

    -- ── Role axis: target / focus ─────────────────────────
    ["unitFrames.target.showThreat"]             = true,
    ["unitFrames.target.threatText.enabled"]     = false,
    ["unitFrames.target.auras.showOnlyMine"]     = false,
    ["unitFrames.target.auras.maxAuras"]         = 8,
    ["unitFrames.target.enemyBuffs.enabled"]     = true,
    ["unitFrames.target.enemyBuffs.maxAuras"]    = 4,
    ["unitFrames.target.enemyBuffs.size"]        = 24,
    ["unitFrames.focus.enabled"]                 = true,

    -- ── Role axis: resources & cooldowns ──────────────────
    ["resourceBars.primaryHeight"]           = 16,
    ["resourceBars.secondaryHeight"]         = 12,
    ["resourceBars.showText"]                = true,
    ["resourceBars.healthBarEnabled"]        = false,
    ["resourceBars.healthThresholdEnabled"]  = true,
    ["resourceBars.healthThresholdPct"]      = 30,
    ["resourceBars.powerThresholdEnabled"]   = false,
    ["resourceBars.powerThresholdPct"]       = 25,
    ["cooldownManager.procGlow.enabled"]     = true,
    ["cooldownManager.rangeCheckEnabled"]    = false,

    -- ── Role axis: castbars ───────────────────────────────
    ["castbars.target.enabled"]              = true,
    ["castbars.focus.enabled"]               = true,
    ["castbars.boss.enabled"]                = true,
    ["castbars.showInterruptFeedback"]       = true,
    ["castbars.showGCDSpark"]                = false,

    -- ── Action bars ───────────────────────────────────────
    ["actionBars.enabled"]              = true,
    ["actionBarSkin.enabled"]           = true,
    ["actionBarSkin.skinStyle"]         = "classic",
    ["actionBarSkin.useClassColor"]     = true,

    -- ── Skins ─────────────────────────────────────────────
    ["chatV4.enabled"]           = true,
    ["bagSkin.enabled"]                 = true,
    ["tooltipSkin.enabled"]             = true,
    ["gameMenuSkin.enabled"]            = true,
    ["characterSkin.enabled"]           = true,
    ["objectiveTracker.enabled"]        = true,
    ["mailSkin.enabled"]                = true,
    ["reputationBar.enabled"]           = true,

    -- ── Mythic+ ───────────────────────────────────────────
    ["MythicTracker.enabled"]           = true,
    ["MythicTracker.hideBlizzard"]      = true,
    ["TomoScore.enabled"]               = true,
    ["TomoScore.autoShowMPlus"]         = true,
    ["MythicKeys.enabled"]              = true,
    ["loots.enabled"]                   = true,
    ["worldQuestTab.enabled"]           = false,  -- side panel: opt-in

    -- ── Quality of life ───────────────────────────────────
    ["minimap.enabled"]                 = true,
    ["infoPanel.enabled"]               = true,
    ["cinematicSkip.enabled"]           = true,
    ["fastLoot.enabled"]                = true,
    ["autoVendorRepair.sellGrays"]      = true,
    ["autoVendorRepair.autoRepair"]     = true,
    ["classReminder.enabled"]           = true,
    ["waypoint.enabled"]                = true,
    ["afkDisplay.enabled"]              = true,
    ["professionHelper.enabled"]        = true,
    ["frameAnchors.enabled"]            = true,
    ["skyRide.enabled"]                 = true,
    ["lustSound.enabled"]               = true,

    -- Conservative settings: off by default, user opts in
    ["cursorRing.enabled"]              = false,
    ["levelingBar.enabled"]             = false,
    ["hideTalkingHead.enabled"]         = false,
    ["tooltipIDs.enabled"]              = false,
    ["autoFillDelete.enabled"]          = true,   -- harmless & handy
    ["autoAcceptInvite.enabled"]        = false,
    ["autoSummon.enabled"]              = false,
    ["autoQuest.autoAccept"]            = false,
    ["autoQuest.autoTurnIn"]            = false,
}

-- ============================================================
-- DELTAS — per-archetype overrides (relative to BASE)
-- Every path below MUST exist in BASE (see invariant above).
-- ============================================================
local DELTAS = {
    -- Recommended = BASE as-is (BASE *is* the role-neutral full setup)
    complet = {},

    -- ── Tank ──────────────────────────────────────────────
    -- Read the whole pull, not just the current target: wider and
    -- brighter plates, threat colouring, bigger enemy buffs (enrage
    -- / shield), thicker plate castbar for interrupt windows, and
    -- your own health always in view. HoT tracking is dropped.
    tank = {
        ["nameplates.tankMode"]                  = true,
        ["nameplates.width"]                     = 190,
        ["nameplates.height"]                    = 20,
        ["nameplates.unselectedAlpha"]           = 0.95,
        ["nameplates.castbarHeight"]             = 18,
        ["nameplates.maxEnemyBuffs"]             = 5,
        ["nameplates.enemyBuffSize"]             = 26,

        ["unitFrames.target.showThreat"]         = true,
        ["unitFrames.target.threatText.enabled"] = true,

        ["partyFrames.showInterruptCD"]          = true,
        ["partyFrames.showBrezCD"]               = true,
        ["partyFrames.defensiveShowPersonals"]   = true,
        ["partyFrames.maxDefensives"]            = 3,
        ["partyFrames.showHoTs"]                 = false,
        ["raidFrames.showHoTs"]                  = false,

        ["resourceBars.healthBarEnabled"]        = true,
        ["resourceBars.healthThresholdEnabled"]  = true,
        ["resourceBars.healthThresholdPct"]      = 40,
    },

    -- ── Healer ────────────────────────────────────────────
    -- Group and raid frames become the primary interface: bigger,
    -- more clickable, with HoTs / dispels / absorbs / heal
    -- prediction and missing health all readable at a glance.
    -- Nameplates step back so they do not fight for attention.
    healer = {
        ["partyFrames.width"]                    = 180,
        ["partyFrames.height"]                   = 52,
        ["partyFrames.showHoTs"]                 = true,
        ["partyFrames.maxHoTs"]                  = 4,
        ["partyFrames.hotSize"]                  = 14,
        ["partyFrames.hotShowDuration"]          = true,
        ["partyFrames.showDispel"]               = true,
        ["partyFrames.dispelSize"]               = 20,
        ["partyFrames.showDefensives"]           = true,
        ["partyFrames.maxDefensives"]            = 3,
        ["partyFrames.defensiveShowExternals"]   = true,
        ["partyFrames.showHealPrediction"]       = true,
        ["partyFrames.showAbsorb"]               = true,
        ["partyFrames.showPower"]                = true,
        ["partyFrames.powerHeight"]              = 5,
        ["partyFrames.showRange"]                = true,
        ["partyFrames.oorAlpha"]                 = 0.30,
        ["partyFrames.showHealthText"]           = true,
        ["partyFrames.healthTextFormat"]         = "deficit",

        ["raidFrames.width"]                     = 84,
        ["raidFrames.height"]                    = 46,
        ["raidFrames.showHoTs"]                  = true,
        ["raidFrames.maxHoTs"]                   = 4,
        ["raidFrames.hotSize"]                   = 12,
        ["raidFrames.hotShowDuration"]           = true,
        ["raidFrames.showDispel"]                = true,
        ["raidFrames.dispelSize"]                = 20,
        ["raidFrames.showDebuffs"]               = true,
        ["raidFrames.maxDebuffs"]                = 3,
        ["raidFrames.debuffSize"]                = 16,
        ["raidFrames.showDefensives"]            = true,
        ["raidFrames.maxDefensives"]             = 3,
        ["raidFrames.showHealPrediction"]        = true,
        ["raidFrames.showAbsorb"]                = true,
        ["raidFrames.showPower"]                 = true,
        ["raidFrames.powerHeight"]               = 4,
        ["raidFrames.showRange"]                 = true,
        ["raidFrames.oorAlpha"]                  = 0.30,
        ["raidFrames.showHealthText"]            = true,
        ["raidFrames.healthTextFormat"]          = "deficit",

        ["nameplates.tankMode"]                  = false,
        ["nameplates.unselectedAlpha"]           = 0.55,
        ["nameplates.maxAuras"]                  = 3,
        ["nameplates.showEnemyBuffs"]            = false,

        ["resourceBars.powerThresholdEnabled"]   = true,
        ["resourceBars.powerThresholdPct"]       = 30,

        ["castbars.focus.enabled"]               = true,
        ["unitFrames.target.enemyBuffs.enabled"] = false,
    },

    -- ── DPS ───────────────────────────────────────────────
    -- Your own resources, cooldowns and debuffs are what matter:
    -- taller resource bars with a low-resource threshold, proc
    -- glow + range check, and aura displays filtered down to your
    -- own casts so DoT tracking stays readable.
    dps = {
        ["resourceBars.primaryHeight"]            = 20,
        ["resourceBars.secondaryHeight"]          = 14,
        ["resourceBars.showText"]                 = true,
        ["resourceBars.powerThresholdEnabled"]    = true,
        ["resourceBars.powerThresholdPct"]        = 20,

        ["cooldownManager.enabled"]               = true,
        ["cooldownManager.procGlow.enabled"]      = true,
        ["cooldownManager.rangeCheckEnabled"]     = true,

        ["unitFrames.target.auras.showOnlyMine"]  = true,
        ["unitFrames.target.auras.maxAuras"]      = 6,
        ["unitFrames.target.enemyBuffs.enabled"]  = true,
        ["unitFrames.target.enemyBuffs.maxAuras"] = 5,
        ["unitFrames.target.enemyBuffs.size"]     = 26,

        ["nameplates.tankMode"]                   = false,
        ["nameplates.showOnlyMyAuras"]            = true,
        ["nameplates.maxAuras"]                   = 6,
        ["nameplates.auraSize"]                   = 26,
        ["nameplates.unselectedAlpha"]            = 0.70,
        ["nameplates.showEnemyBuffs"]             = true,
        ["nameplates.maxEnemyBuffs"]              = 4,

        ["partyFrames.showHoTs"]                  = false,
        ["partyFrames.showInterruptCD"]           = true,
        ["raidFrames.showHoTs"]                   = false,
        ["raidFrames.height"]                     = 30,

        ["castbars.showGCDSpark"]                 = true,
        ["castbars.focus.enabled"]                = true,
    },

    -- ── Minimal ───────────────────────────────────────────
    -- Keep the core, cut everything else — including the heavier
    -- per-frame trackers, which are the expensive part.
    minimal = {
        ["nameplates.enabled"]        = false,
        ["cooldownManager.enabled"]   = false,

        ["actionBarSkin.enabled"]     = false,

        ["chatV4.enabled"]     = false,
        ["bagSkin.enabled"]           = false,
        ["tooltipSkin.enabled"]       = false,
        ["gameMenuSkin.enabled"]      = false,
        ["characterSkin.enabled"]     = false,
        ["objectiveTracker.enabled"]  = false,
        ["mailSkin.enabled"]          = false,
        ["reputationBar.enabled"]     = false,

        ["TomoScore.enabled"]         = false,
        ["MythicKeys.enabled"]        = false,
        ["loots.enabled"]             = false,
        ["worldQuestTab.enabled"]     = false,

        ["infoPanel.enabled"]         = false,
        ["cinematicSkip.enabled"]     = false,
        ["classReminder.enabled"]     = false,
        ["waypoint.enabled"]          = false,
        ["afkDisplay.enabled"]        = false,
        ["professionHelper.enabled"]  = false,
        ["frameAnchors.enabled"]      = false,
        ["skyRide.enabled"]           = false,
        ["lustSound.enabled"]         = false,

        -- Frame trackers off: this is where the per-update cost is
        ["partyFrames.showHoTs"]                 = false,
        ["partyFrames.showDefensives"]           = false,
        ["partyFrames.showHealPrediction"]       = false,
        ["raidFrames.showHoTs"]                  = false,
        ["raidFrames.showDefensives"]            = false,
        ["raidFrames.showDebuffs"]               = false,
        ["raidFrames.showHealPrediction"]        = false,
        ["unitFrames.target.enemyBuffs.enabled"] = false,
        -- kept: unitFrames, partyFrames, raidFrames, castbars,
        -- resourceBars, minimap, fastLoot, autoVendorRepair,
        -- MythicTracker, actionBars (the manager, harmless)
    },
}

-- ============================================================
-- UI LIST (archetype cards)
-- Resolved on every call so it stays sensitive to the active locale.
-- ============================================================
local ICON_ROLE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Roles\\"
local ICON      = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\icons\\"

local ORDER = {
    {
        key   = "complet",
        icon  = ICON .. "icon_general.tga",
        color = { TomoMod_Utils.BRAND[1], TomoMod_Utils.BRAND[2], TomoMod_Utils.BRAND[3] },   -- teal (accent)
        recommended = true,
    },
    {
        key   = "tank",
        icon  = ICON_ROLE .. "TANK.tga",
        color = { 0.28, 0.52, 0.92 },       -- blue
        role  = "TANK",
    },
    {
        key   = "healer",
        icon  = ICON_ROLE .. "HEALER.tga",
        color = { 0.36, 0.82, 0.42 },       -- green
        role  = "HEALER",
    },
    {
        key   = "dps",
        icon  = ICON_ROLE .. "DAMAGER.tga",
        color = { 0.85, 0.32, 0.32 },       -- red
        role  = "DAMAGER",
    },
    {
        key   = "minimal",
        icon  = ICON .. "icon_qol.tga",
        color = { 0.55, 0.55, 0.62 },       -- grey
    },
    {
        key   = "custom",
        icon  = ICON .. "icon_diagnostics.tga",
        color = { 0.78, 0.58, 0.16 },       -- gold
        custom = true,                       -- does not touch the DB
    },
}

-- Returns a fresh list { key, icon, color, role, recommended, custom,
-- name, tagline, desc, highlights } ready for display.
function P.GetList()
    local out = {}
    for i, def in ipairs(ORDER) do
        out[i] = {
            key         = def.key,
            icon        = def.icon,
            color       = def.color,
            role        = def.role,
            recommended = def.recommended,
            custom      = def.custom,
            name        = L["preset_" .. def.key .. "_name"],
            tagline     = L["preset_" .. def.key .. "_tag"],
            desc        = L["preset_" .. def.key .. "_desc"],
            highlights  = P.GetHighlights(def.key),
        }
    end
    return out
end

-- Returns the (static) definition of a preset, or nil.
function P.Get(key)
    for _, def in ipairs(ORDER) do
        if def.key == key then return def end
    end
    return nil
end

-- Three short localized bullets summarizing what an archetype does.
-- Used by the dashboard cards; the installer keeps using .desc.
function P.GetHighlights(key)
    if not key then return nil end
    local out = {}
    for i = 1, 3 do
        local lk  = "preset_" .. key .. "_h" .. i
        local txt = L[lk]
        -- The locale metatable returns the raw key for unknown keys.
        if txt and txt ~= lk then out[#out + 1] = txt end
    end
    if #out == 0 then return nil end
    return out
end

-- Key of the last applied preset, or nil if the user never applied one
-- (or configured everything by hand).
function P.GetActive()
    local key = TomoModDB and TomoModDB._lastPreset
    if type(key) ~= "string" then return nil end
    return key
end

-- True if the preset exists and actually writes to the DB.
function P.IsApplicable(key)
    return DELTAS[key] ~= nil
end

-- ============================================================
-- APPLY — writes the archetype into TomoModDB
-- ============================================================
-- Only writes the DB; live modules refresh on /reload (the installer
-- reloads at the end of its flow, and the dashboard prompts for one).
-- No protected values are touched here: this is 100% DB/string code,
-- so there is no taint risk.
function P.Apply(key)
    if not TomoModDB then return false end
    if key == "custom" then
        TomoModDB._lastPreset = "custom"
        return true
    end
    local delta = DELTAS[key]
    if not delta then return false end

    -- 1) BASE (also acts as the reset floor for every delta key)
    for path, val in pairs(BASE) do
        SetPath(TomoModDB, path, val)
    end
    -- 2) archetype DELTA
    for path, val in pairs(delta) do
        SetPath(TomoModDB, path, val)
    end

    TomoModDB._lastPreset = key

    -- [Lot C] Config pages are cached; a preset rewrites the DB globally
    if TomoMod_Config and TomoMod_Config.InvalidatePanels then
        TomoMod_Config.InvalidatePanels()
    end
    return true
end

-- ============================================================
-- SLASH DEV/TEST — /tmpreset <key>
-- ============================================================
SLASH_TOMOPRESET1 = "/tmpreset"
SlashCmdList["TOMOPRESET"] = function(msg)
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
    if msg == "" then
        print("|cff2e9dd8TomoMod|r " .. L["preset_usage"])
        return
    end
    if not P.IsApplicable(msg) then
        print("|cff2e9dd8TomoMod|r " .. string.format(L["preset_unknown"], msg))
        return
    end
    if P.Apply(msg) then
        local def  = P.Get(msg)
        local name = def and L["preset_" .. def.key .. "_name"] or msg
        print("|cff2e9dd8TomoMod|r " .. string.format(L["preset_applied"], name))
    end
end

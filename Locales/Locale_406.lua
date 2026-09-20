-- =====================================================================
-- Locale_406.lua — v4.0.6 release notes and feature highlights
-- =====================================================================

TomoMod_RegisterLocale("enUS", {
    ["wn_406_gear_weight_import"] = "New — TomoGear V1.2 can import Pawn v1, Ask Mr. Robot and compatible key=value stat scales for the current specialization. Primary stat, Stamina, Critical Strike, Haste, Mastery and Versatility are supported.",
    ["wn_406_gear_import_validation"] = "New — Each specialization keeps its own imported profile. Class, specialization and primary-stat mismatches are rejected, unsupported values are ignored, and item level has no implicit weight unless ItemLevel= is provided.",
    ["wn_406_gear_independent_db"] = "Changed — TomoGear preferences and weights now live in the dedicated TomoGearDB SavedVariable, independently from TomoMod profiles and imports. Existing Gear Advisor settings are migrated automatically once.",
    ["wn_406_gear_signed_percent"] = "Changed — Item tooltips now show signed percentages for upgrades, downgrades and equal items in green, red and neutral colours. The minimum-upgrade threshold applies only to the bag arrow.",
    ["wn_406_gear_itemref"] = "Fixed — Opening an item link from chat no longer raises an 'attempt to call a nil value' error when ItemRefTooltip reaches the item post-processor without an addon-accessible AddLine method on some Midnight builds.",
    ["wn_406_gear_tooltip_guard"] = "Changed — TomoGear now checks tooltip line support and isolates every advice-line insertion. Unsupported tooltip implementations are skipped safely while the normal GameTooltip path remains unchanged.",
})

TomoMod_RegisterLocale("frFR", {
    ["wn_406_gear_weight_import"] = "Nouveauté — TomoGear V1.2 peut importer des échelles Pawn v1, Ask Mr. Robot et key=value compatibles pour la spécialisation actuelle. La caractéristique principale, l'Endurance, le Critique, la Hâte, la Maîtrise et la Polyvalence sont pris en charge.",
    ["wn_406_gear_import_validation"] = "Nouveauté — Chaque spécialisation conserve son propre profil importé. Les incompatibilités de classe, de spécialisation ou de caractéristique principale sont refusées, les valeurs non prises en charge sont ignorées et le niveau d'objet ne reçoit aucun poids implicite sans ItemLevel=.",
    ["wn_406_gear_independent_db"] = "Modification — Les préférences et les poids de TomoGear résident maintenant dans la variable sauvegardée dédiée TomoGearDB, indépendamment des profils et imports TomoMod. Les anciens réglages du conseiller sont migrés automatiquement une seule fois.",
    ["wn_406_gear_signed_percent"] = "Modification — Les infobulles affichent maintenant un pourcentage signé pour les améliorations, régressions et objets équivalents, respectivement en vert, rouge et neutre. Le seuil minimal ne s'applique plus qu'à la flèche des sacs.",
    ["wn_406_gear_itemref"] = "Correction — Ouvrir un lien d'objet depuis la discussion ne provoque plus d'erreur 'attempt to call a nil value' lorsque ItemRefTooltip atteint le post-traitement des objets sans méthode AddLine accessible aux addons sur certaines versions de Midnight.",
    ["wn_406_gear_tooltip_guard"] = "Modification — TomoGear vérifie désormais que l'infobulle accepte l'ajout de lignes et isole chaque insertion de conseil. Les implémentations incompatibles sont ignorées proprement tandis que le fonctionnement normal de GameTooltip reste inchangé.",
})

TomoMod_RegisterLocale("deDE", {
    ["wn_406_gear_weight_import"] = "Neu — TomoGear V1.2 kann Pawn-v1-, Ask-Mr.-Robot- und kompatible key=value-Attributgewichtungen für die aktuelle Spezialisierung importieren. Primärattribut, Ausdauer, Krit, Tempo, Meisterschaft und Vielseitigkeit werden unterstützt.",
    ["wn_406_gear_import_validation"] = "Neu — Jede Spezialisierung behält ihr eigenes importiertes Profil. Unpassende Klassen, Spezialisierungen oder Primärattribute werden abgelehnt, nicht unterstützte Werte ignoriert und die Gegenstandsstufe erhält ohne ItemLevel= kein stillschweigendes Gewicht.",
    ["wn_406_gear_independent_db"] = "Geändert — TomoGear-Einstellungen und -Gewichtungen liegen jetzt unabhängig von TomoMod-Profilen und -Importen in der eigenen gespeicherten Variable TomoGearDB. Vorhandene Berater-Einstellungen werden einmalig automatisch übernommen.",
    ["wn_406_gear_signed_percent"] = "Geändert — Gegenstands-Tooltips zeigen jetzt vorzeichenbehaftete Prozentwerte für Verbesserungen, Verschlechterungen und gleichwertige Gegenstände in Grün, Rot beziehungsweise neutral an. Der Mindestwert gilt nur noch für den Taschenpfeil.",
    ["wn_406_gear_itemref"] = "Behoben — Beim Öffnen eines Gegenstandslinks aus dem Chat tritt kein Fehler 'attempt to call a nil value' mehr auf, wenn ItemRefTooltip auf manchen Midnight-Versionen den Gegenstands-Nachbearbeiter ohne eine für Addons zugängliche AddLine-Methode erreicht.",
    ["wn_406_gear_tooltip_guard"] = "Geändert — TomoGear prüft jetzt, ob ein Tooltip das Hinzufügen von Zeilen unterstützt, und sichert jedes Einfügen eines Hinweises einzeln ab. Nicht unterstützte Tooltip-Implementierungen werden sicher übersprungen, während der normale GameTooltip-Pfad unverändert bleibt.",
})

TomoMod_RegisterLocale("esES", {
    ["wn_406_gear_weight_import"] = "Novedad — TomoGear V1.2 puede importar escalas Pawn v1, Ask Mr. Robot y key=value compatibles para la especialización actual. Se admiten la estadística principal, Aguante, Crítico, Celeridad, Maestría y Versatilidad.",
    ["wn_406_gear_import_validation"] = "Novedad — Cada especialización conserva su propio perfil importado. Se rechazan las escalas de otra clase, especialización o estadística principal, se ignoran los valores no compatibles y el nivel de objeto no recibe peso implícito sin ItemLevel=.",
    ["wn_406_gear_independent_db"] = "Cambio — Las preferencias y los pesos de TomoGear ahora residen en la variable guardada independiente TomoGearDB, al margen de los perfiles e importaciones de TomoMod. Los ajustes existentes del asesor se migran automáticamente una sola vez.",
    ["wn_406_gear_signed_percent"] = "Cambio — Las descripciones de objetos ahora muestran porcentajes con signo para mejoras, empeoramientos y objetos equivalentes en verde, rojo y color neutro. El umbral mínimo solo se aplica a la flecha de las bolsas.",
    ["wn_406_gear_itemref"] = "Corrección — Abrir un enlace de objeto desde el chat ya no provoca el error 'attempt to call a nil value' cuando ItemRefTooltip llega al posprocesador de objetos sin un método AddLine accesible para addons en algunas versiones de Midnight.",
    ["wn_406_gear_tooltip_guard"] = "Cambio — TomoGear ahora comprueba si la descripción admite líneas adicionales y aísla cada inserción de consejo. Las implementaciones incompatibles se omiten de forma segura, mientras que la ruta normal de GameTooltip permanece sin cambios.",
})

TomoMod_RegisterLocale("itIT", {
    ["wn_406_gear_weight_import"] = "Novità — TomoGear V1.2 può importare scale Pawn v1, Ask Mr. Robot e key=value compatibili per la specializzazione attuale. Sono supportati statistica primaria, Tempra, Critico, Celerità, Maestria e Versatilità.",
    ["wn_406_gear_import_validation"] = "Novità — Ogni specializzazione conserva il proprio profilo importato. Le scale con classe, specializzazione o statistica primaria errate vengono rifiutate, i valori non supportati ignorati e il livello oggetto non riceve alcun peso implicito senza ItemLevel=.",
    ["wn_406_gear_independent_db"] = "Modifica — Preferenze e pesi di TomoGear ora risiedono nella variabile salvata dedicata TomoGearDB, indipendentemente dai profili e dalle importazioni di TomoMod. Le impostazioni esistenti vengono migrate automaticamente una sola volta.",
    ["wn_406_gear_signed_percent"] = "Modifica — I tooltip degli oggetti mostrano ora percentuali con segno per miglioramenti, peggioramenti e oggetti equivalenti in verde, rosso e colore neutro. La soglia minima si applica soltanto alla freccia nelle borse.",
    ["wn_406_gear_itemref"] = "Correzione — L'apertura di un collegamento a un oggetto dalla chat non genera più l'errore 'attempt to call a nil value' quando ItemRefTooltip raggiunge il post-processore degli oggetti senza un metodo AddLine accessibile agli addon in alcune versioni di Midnight.",
    ["wn_406_gear_tooltip_guard"] = "Modifica — TomoGear ora verifica che il tooltip supporti l'aggiunta di righe e protegge ogni inserimento dei consigli. Le implementazioni non supportate vengono ignorate in sicurezza, mentre il normale percorso GameTooltip resta invariato.",
})

TomoMod_RegisterLocale("ptBR", {
    ["wn_406_gear_weight_import"] = "Novidade — O TomoGear V1.2 pode importar escalas Pawn v1, Ask Mr. Robot e key=value compatíveis para a especialização atual. Atributo primário, Vigor, Crítico, Aceleração, Maestria e Versatilidade são aceitos.",
    ["wn_406_gear_import_validation"] = "Novidade — Cada especialização mantém seu próprio perfil importado. Escalas com classe, especialização ou atributo primário incompatíveis são recusadas, valores não aceitos são ignorados e o nível do item não recebe peso implícito sem ItemLevel=.",
    ["wn_406_gear_independent_db"] = "Alteração — As preferências e os pesos do TomoGear agora ficam na variável salva dedicada TomoGearDB, independentemente dos perfis e das importações do TomoMod. As configurações existentes são migradas automaticamente uma única vez.",
    ["wn_406_gear_signed_percent"] = "Alteração — As dicas de item agora mostram percentuais com sinal para melhorias, pioras e itens equivalentes em verde, vermelho e cor neutra. O limite mínimo se aplica apenas à seta nas bolsas.",
    ["wn_406_gear_itemref"] = "Correção — Abrir um link de item pelo bate-papo não causa mais o erro 'attempt to call a nil value' quando o ItemRefTooltip chega ao pós-processador de itens sem um método AddLine acessível a addons em algumas versões do Midnight.",
    ["wn_406_gear_tooltip_guard"] = "Alteração — O TomoGear agora verifica se a dica aceita linhas adicionais e protege cada inserção de recomendação. Implementações incompatíveis são ignoradas com segurança, enquanto o fluxo normal do GameTooltip permanece inalterado.",
})

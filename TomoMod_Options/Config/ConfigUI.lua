-- =====================================
-- ConfigUI.lua — Dark Config Panel v2.7.1
-- Icônes .tga originales redimensionnées, sidebar sobre
-- Default size 1240 × 820 — resizable (bottom-right grip) + user scale
-- =====================================

local L = TomoMod_L

StaticPopupDialogs["TOMOMOD_MODULE_RELOAD"] = StaticPopupDialogs["TOMOMOD_MODULE_RELOAD"] or {
    -- Raised above the config window, which sits at FULLSCREEN_DIALOG
    -- level 500 and would otherwise hide this prompt entirely.
    OnShow   = function(self)
        local U = TomoMod_Utils
        if U and U.RaiseAboveTomoUI then U.RaiseAboveTomoUI(self) end
    end,
    OnHide   = function(self)
        local U = TomoMod_Utils
        if U and U.RestoreTomoUILayer then U.RestoreTomoUILayer(self) end
    end,
    text     = L["cfg_reload_text"],
    button1  = L["cfg_reload_confirm"],
    button2  = L["cfg_reload_later"],
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Locales additionnelles utilisées par ce panneau (FR + EN, autonome)
if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["cat_accueil"]           = "Home",
        ["ui_search_placeholder"] = "Search settings...",
        ["opt_gui_scale"]         = "Config window scale",
        ["info_gui_scale"]        = "Scale of the /tm window — you can also resize it by dragging its bottom-right corner.",
        ["btn_gui_reset_size"]    = "Reset window size & scale",
        ["gs_no_results"]         = "No matching option",
    })
    TomoMod_RegisterLocale("frFR", {
        ["cat_accueil"]           = "Accueil",
        ["ui_search_placeholder"] = "Rechercher un réglage...",
        ["opt_gui_scale"]         = "Échelle de la fenêtre de configuration",
        ["info_gui_scale"]        = "Échelle de la fenêtre /tm — elle est aussi redimensionnable en tirant son coin inférieur droit.",
        ["btn_gui_reset_size"]    = "Réinitialiser taille et échelle",
        ["gs_no_results"]         = "Aucune option correspondante",
    })
end

-- Multi-step help for the main TomoMod_Options window.
-- Kept here rather than in a Studio locale file because this guide belongs to
-- the always-visible /tm shell itself.
if TomoMod_RegisterLocale then
    local HELP_LOCALES = {
        enUS = {
            ["cfg_help_button"] = "? Help",
            ["cfg_help_progress"] = "Step %d / %d",
            ["cfg_help_back"] = "Back",
            ["cfg_help_close"] = "Close",
            ["cfg_help_next"] = "Next",
            ["cfg_help_finish"] = "Finish",
            ["cfg_help_1_title"] = "Welcome to TomoMod",
            ["cfg_help_1_body"] = "This short guide presents the main navigation, search, role filters, configuration workspaces, Layout mode, profiles and diagnostics.",
            ["cfg_help_2_title"] = "Main navigation",
            ["cfg_help_2_body"] = "The left sidebar lists every section: Home, Roles, Interface, Comfort, Damage Meter, What's New, Profiles and Diagnostics. The open section unfolds its pages in place, and the Studios block opens each dedicated editor in one click.",
            ["cfg_help_3_title"] = "Search",
            ["cfg_help_3_body"] = "Type a module, feature or option here. TomoMod filters the navigation and can surface matching settings without forcing you to remember where they live.",
            ["cfg_help_4_title"] = "Role filter",
            ["cfg_help_4_body"] = "The four role buttons prioritize settings for Everyone, Tank, Healer or Damage. Other settings remain visible but are visually de-emphasized.",
            ["cfg_help_5_title"] = "Workspaces and Studios",
            ["cfg_help_5_body"] = "Interface and Comfort list their pages in the sidebar; a page with several parts shows them as tabs above its content. Unit frames, nameplates, castbars, party and raid frames, resources, cooldowns and Mythic+ are edited in the Studios, opened from the sidebar, the Home Studios card or the EditMode gear.",
            ["cfg_help_6_title"] = "Layout / EditMode",
            ["cfg_help_6_body"] = "Use EditMode to unlock movable TomoMod elements. Hover a supported element to access its contextual configuration gear, move it, then lock the layout again when finished.",
            ["cfg_help_7_title"] = "Profiles",
            ["cfg_help_7_body"] = "Profiles let you save, switch, import and export complete configurations. Use them before major UI changes or when sharing a setup between characters.",
            ["cfg_help_8_title"] = "Diagnostics",
            ["cfg_help_8_body"] = "If something behaves unexpectedly, Diagnostics is the first place to check. It gathers module state, performance information and error/report data useful for troubleshooting.",
        },
        frFR = {
            ["cfg_help_button"] = "? Aide",
            ["cfg_help_progress"] = "Étape %d / %d",
            ["cfg_help_back"] = "Retour",
            ["cfg_help_close"] = "Fermer",
            ["cfg_help_next"] = "Suivant",
            ["cfg_help_finish"] = "Terminer",
            ["cfg_help_1_title"] = "Bienvenue dans TomoMod",
            ["cfg_help_1_body"] = "Ce petit guide présente la navigation principale, la recherche, les filtres de rôle, les espaces de configuration, le mode Layout, les profils et les diagnostics.",
            ["cfg_help_2_title"] = "Navigation principale",
            ["cfg_help_2_body"] = "La barre latérale liste toutes les sections : Accueil, Rôles, Interface, Confort, Damage Meter, Nouveautés, Profils et Diagnostics. La section ouverte déplie ses pages sur place, et le bloc Studios ouvre chaque éditeur dédié en un clic.",
            ["cfg_help_3_title"] = "Recherche",
            ["cfg_help_3_body"] = "Saisis ici le nom d'un module, d'une fonction ou d'un réglage. TomoMod filtre la navigation et peut retrouver les options correspondantes sans devoir mémoriser leur emplacement.",
            ["cfg_help_4_title"] = "Filtre par rôle",
            ["cfg_help_4_body"] = "Les quatre boutons mettent en avant les réglages utiles à Tous, Tank, Healer ou DPS. Les autres réglages restent visibles mais sont volontairement atténués.",
            ["cfg_help_5_title"] = "Espaces et Studios",
            ["cfg_help_5_body"] = "Interface et Confort listent leurs pages dans la barre latérale ; une page en plusieurs parties les affiche en onglets au-dessus de son contenu. UnitFrames, Nameplates, barres d'incantation, cadres de groupe et de raid, ressources, cooldowns et Mythic+ se règlent dans les Studios, ouverts depuis la barre latérale, la carte Studios de l'Accueil ou l'engrenage d'EditMode.",
            ["cfg_help_6_title"] = "Layout / EditMode",
            ["cfg_help_6_body"] = "Utilise EditMode pour déverrouiller les éléments TomoMod déplaçables. Survole un élément compatible pour accéder à son engrenage de configuration, déplace-le puis reverrouille le Layout.",
            ["cfg_help_7_title"] = "Profils",
            ["cfg_help_7_body"] = "Les Profils permettent de sauvegarder, changer, importer et exporter une configuration complète. Ils sont pratiques avant une grosse modification ou pour partager un setup entre personnages.",
            ["cfg_help_8_title"] = "Diagnostics",
            ["cfg_help_8_body"] = "Si quelque chose se comporte anormalement, commence par Diagnostics. Cette page rassemble l'état des modules, les informations de performance et les données utiles au rapport d'erreur.",
        },
        deDE = {
            ["cfg_help_button"] = "? Hilfe",
            ["cfg_help_progress"] = "Schritt %d / %d",
            ["cfg_help_back"] = "Zurück",
            ["cfg_help_close"] = "Schließen",
            ["cfg_help_next"] = "Weiter",
            ["cfg_help_finish"] = "Fertig",
            ["cfg_help_1_title"] = "Willkommen bei TomoMod",
            ["cfg_help_1_body"] = "Diese kurze Hilfe zeigt die Hauptnavigation, Suche, Rollenfilter, Konfigurationsbereiche, den Layout-Modus, Profile und Diagnose.",
            ["cfg_help_2_title"] = "Hauptnavigation",
            ["cfg_help_2_body"] = "Die linke Seitenleiste listet alle Bereiche: Start, Rollen, Interface, Komfort, Damage Meter, Neuerungen, Profile und Diagnose. Der geoeffnete Bereich klappt seine Seiten an Ort und Stelle auf, und der Studios-Block oeffnet jeden Editor mit einem Klick.",
            ["cfg_help_3_title"] = "Suche",
            ["cfg_help_3_body"] = "Gib hier ein Modul, eine Funktion oder eine Option ein. TomoMod filtert die Navigation und findet passende Einstellungen, ohne dass du ihren genauen Ort kennen musst.",
            ["cfg_help_4_title"] = "Rollenfilter",
            ["cfg_help_4_body"] = "Die vier Rollen-Schaltflächen heben Einstellungen für Alle, Tank, Heiler oder Schaden hervor. Andere Einstellungen bleiben sichtbar, werden aber optisch zurückgenommen.",
            ["cfg_help_5_title"] = "Bereiche und Studios",
            ["cfg_help_5_body"] = "Interface und Komfort listen ihre Seiten in der Seitenleiste; eine Seite mit mehreren Teilen zeigt sie als Reiter ueber dem Inhalt. Einheitenrahmen, Namensplaketten, Zauberleisten, Gruppen- und Schlachtzugrahmen, Ressourcen, Abklingzeiten und Mythisch+ werden in den Studios bearbeitet, die ueber die Seitenleiste, die Studios-Karte der Startseite oder das EditMode-Zahnrad starten.",
            ["cfg_help_6_title"] = "Layout / EditMode",
            ["cfg_help_6_body"] = "Mit EditMode entsperrst du verschiebbare TomoMod-Elemente. Fahre über ein unterstütztes Element, um das Kontext-Zahnrad zu öffnen, verschiebe es und sperre das Layout danach wieder.",
            ["cfg_help_7_title"] = "Profile",
            ["cfg_help_7_body"] = "Profile speichern, wechseln, importieren und exportieren komplette Konfigurationen. Nutze sie vor größeren UI-Änderungen oder zum Teilen eines Setups zwischen Charakteren.",
            ["cfg_help_8_title"] = "Diagnose",
            ["cfg_help_8_body"] = "Wenn sich etwas unerwartet verhält, prüfe zuerst Diagnose. Dort findest du Modulstatus, Leistungsinformationen sowie Fehler- und Berichtsdaten für die Fehlersuche.",
        },
        esES = {
            ["cfg_help_button"] = "? Ayuda",
            ["cfg_help_progress"] = "Paso %d / %d",
            ["cfg_help_back"] = "Atrás",
            ["cfg_help_close"] = "Cerrar",
            ["cfg_help_next"] = "Siguiente",
            ["cfg_help_finish"] = "Finalizar",
            ["cfg_help_1_title"] = "Bienvenido a TomoMod",
            ["cfg_help_1_body"] = "Esta guía breve presenta la navegación principal, la búsqueda, los filtros de rol, los espacios de configuración, el modo Layout, los perfiles y los diagnósticos.",
            ["cfg_help_2_title"] = "Navegación principal",
            ["cfg_help_2_body"] = "La barra lateral muestra todas las secciones: Inicio, Roles, Interfaz, Comodidad, Damage Meter, Novedades, Perfiles y Diagnósticos. La sección abierta despliega sus páginas en el sitio y el bloque Studios abre cada editor dedicado con un clic.",
            ["cfg_help_3_title"] = "Búsqueda",
            ["cfg_help_3_body"] = "Escribe aquí un módulo, función u opción. TomoMod filtra la navegación y puede encontrar los ajustes relacionados sin que tengas que recordar dónde están.",
            ["cfg_help_4_title"] = "Filtro por rol",
            ["cfg_help_4_body"] = "Los cuatro botones de rol destacan los ajustes para Todos, Tanque, Sanador o Daño. Los demás ajustes siguen visibles, pero se muestran atenuados.",
            ["cfg_help_5_title"] = "Espacios y Studios",
            ["cfg_help_5_body"] = "Interfaz y Comodidad muestran sus páginas en la barra lateral; una página con varias partes las muestra como pestañas sobre su contenido. Los marcos de unidad, las placas de nombre, las barras de lanzamiento, los marcos de grupo y banda, los recursos, los tiempos de reutilización y Míticas+ se editan en los Studios, que se abren desde la barra lateral, la tarjeta Studios de Inicio o el engranaje de EditMode.",
            ["cfg_help_6_title"] = "Layout / EditMode",
            ["cfg_help_6_body"] = "Usa EditMode para desbloquear los elementos móviles de TomoMod. Pasa el cursor sobre un elemento compatible para acceder a su engranaje contextual, muévelo y vuelve a bloquear el Layout.",
            ["cfg_help_7_title"] = "Perfiles",
            ["cfg_help_7_body"] = "Los Perfiles permiten guardar, cambiar, importar y exportar configuraciones completas. Úsalos antes de grandes cambios de interfaz o para compartir un setup entre personajes.",
            ["cfg_help_8_title"] = "Diagnósticos",
            ["cfg_help_8_body"] = "Si algo se comporta de forma inesperada, empieza por Diagnósticos. Reúne el estado de los módulos, información de rendimiento y datos de errores e informes útiles para localizar problemas.",
        },
        itIT = {
            ["cfg_help_button"] = "? Aiuto",
            ["cfg_help_progress"] = "Passo %d / %d",
            ["cfg_help_back"] = "Indietro",
            ["cfg_help_close"] = "Chiudi",
            ["cfg_help_next"] = "Avanti",
            ["cfg_help_finish"] = "Fine",
            ["cfg_help_1_title"] = "Benvenuto in TomoMod",
            ["cfg_help_1_body"] = "Questa breve guida presenta la navigazione principale, la ricerca, i filtri ruolo, le aree di configurazione, la modalità Layout, i profili e la diagnostica.",
            ["cfg_help_2_title"] = "Navigazione principale",
            ["cfg_help_2_body"] = "La barra laterale elenca tutte le sezioni: Home, Ruoli, Interfaccia, Comodità, Damage Meter, Novità, Profili e Diagnostica. La sezione aperta mostra le sue pagine sul posto e il blocco Studio apre ogni editor dedicato con un clic.",
            ["cfg_help_3_title"] = "Ricerca",
            ["cfg_help_3_body"] = "Inserisci qui un modulo, una funzione o un'opzione. TomoMod filtra la navigazione e può trovare le impostazioni corrispondenti senza doverne ricordare la posizione.",
            ["cfg_help_4_title"] = "Filtro ruolo",
            ["cfg_help_4_body"] = "I quattro pulsanti ruolo evidenziano le impostazioni per Tutti, Tank, Healer o Danni. Le altre impostazioni restano visibili ma vengono attenuate.",
            ["cfg_help_5_title"] = "Aree e Studio",
            ["cfg_help_5_body"] = "Interfaccia e Comodità elencano le loro pagine nella barra laterale; una pagina in più parti le mostra come schede sopra il contenuto. Riquadri unità, barre del nome, barre di lancio, riquadri di gruppo e incursione, risorse, recuperi e Mitiche+ si modificano negli Studio, aperti dalla barra laterale, dalla scheda Studio della Home o dall'ingranaggio di EditMode.",
            ["cfg_help_6_title"] = "Layout / EditMode",
            ["cfg_help_6_body"] = "Usa EditMode per sbloccare gli elementi TomoMod spostabili. Passa su un elemento supportato per aprire l'ingranaggio contestuale, spostalo e poi blocca nuovamente il Layout.",
            ["cfg_help_7_title"] = "Profili",
            ["cfg_help_7_body"] = "I Profili permettono di salvare, cambiare, importare ed esportare configurazioni complete. Usali prima di grandi modifiche alla UI o per condividere un setup tra personaggi.",
            ["cfg_help_8_title"] = "Diagnostica",
            ["cfg_help_8_body"] = "Se qualcosa si comporta in modo inatteso, controlla prima Diagnostica. Raccoglie stato dei moduli, informazioni sulle prestazioni e dati di errori e report utili alla risoluzione dei problemi.",
        },
        ptBR = {
            ["cfg_help_button"] = "? Ajuda",
            ["cfg_help_progress"] = "Etapa %d / %d",
            ["cfg_help_back"] = "Voltar",
            ["cfg_help_close"] = "Fechar",
            ["cfg_help_next"] = "Próximo",
            ["cfg_help_finish"] = "Concluir",
            ["cfg_help_1_title"] = "Bem-vindo ao TomoMod",
            ["cfg_help_1_body"] = "Este guia rápido apresenta a navegação principal, a busca, os filtros de função, as áreas de configuração, o modo Layout, os perfis e os diagnósticos.",
            ["cfg_help_2_title"] = "Navegação principal",
            ["cfg_help_2_body"] = "A barra lateral lista todas as seções: Início, Funções, Interface, Conforto, Damage Meter, Novidades, Perfis e Diagnósticos. A seção aberta expande suas páginas no lugar, e o bloco Studios abre cada editor dedicado com um clique.",
            ["cfg_help_3_title"] = "Busca",
            ["cfg_help_3_body"] = "Digite aqui um módulo, recurso ou opção. O TomoMod filtra a navegação e pode encontrar as configurações correspondentes sem exigir que você memorize onde elas ficam.",
            ["cfg_help_4_title"] = "Filtro por função",
            ["cfg_help_4_body"] = "Os quatro botões de função destacam configurações para Todos, Tank, Healer ou Dano. As demais configurações continuam visíveis, mas ficam visualmente atenuadas.",
            ["cfg_help_5_title"] = "Áreas e Studios",
            ["cfg_help_5_body"] = "Interface e Conforto listam suas páginas na barra lateral; uma página com várias partes as mostra como abas acima do conteúdo. Quadros de unidade, placas de nome, barras de conjuração, quadros de grupo e raide, recursos, recargas e Mítica+ são editados nos Studios, abertos pela barra lateral, pelo cartão Studios do Início ou pela engrenagem do EditMode.",
            ["cfg_help_6_title"] = "Layout / EditMode",
            ["cfg_help_6_body"] = "Use o EditMode para desbloquear elementos móveis do TomoMod. Passe o cursor sobre um elemento compatível para acessar a engrenagem contextual, mova-o e depois bloqueie o Layout novamente.",
            ["cfg_help_7_title"] = "Perfis",
            ["cfg_help_7_body"] = "Perfis permitem salvar, alternar, importar e exportar configurações completas. Use-os antes de grandes mudanças na interface ou para compartilhar um setup entre personagens.",
            ["cfg_help_8_title"] = "Diagnósticos",
            ["cfg_help_8_body"] = "Se algo se comportar de forma inesperada, comece por Diagnósticos. A página reúne estado dos módulos, informações de desempenho e dados de erros e relatórios úteis para solução de problemas.",
        },
    }
    for locale, strings in pairs(HELP_LOCALES) do
        TomoMod_RegisterLocale(locale, strings)
    end
end

TomoMod_Config = TomoMod_Config or {}
local C = TomoMod_Config
local W = TomoMod_Widgets
local T = W.Theme

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ADDON_PATH = "Interface\\AddOns\\TomoMod\\"

local function LT(key, fallback)
    local value = L and L[key]
    if value and value ~= key then return value end
    return fallback or key
end

-- =====================================================================
-- LAYOUT CONSTANTS
-- =====================================================================
local PANEL_W   = 1240
local PANEL_H   = 820
local NAV_W     = 210
local PANEL_MIN_W, PANEL_MIN_H = 1020, 720
local PANEL_MAX_W, PANEL_MAX_H = 1680, 1080
local TITLE_H   = 52
local FOOTER_H  = 36

-- =====================================================================
-- CATEGORIES
-- =====================================================================
local ICON_PATH = ADDON_PATH .. "Assets\\Textures\\icons\\"

local categories = {
    { key = "accueil",   label = LT("cat_accueil", "Accueil"), icon = ICON_PATH .. "ico_gui.tga",          accent = { 0.180, 0.616, 0.847 }, desc = L["cat_accueil_desc"], kw = "accueil home dashboard tableau bord vue" },
    { key = "roles",     label = L["cat_roles"],                      icon = ICON_PATH .. "icon_partyframes.tga", accent = { 0.94, 0.74, 0.35 }, desc = L["cat_roles_desc"], kw = "role roles tank tanking heal healer soigneur dps damage degats guide" },
    { key = "interface", label = L["cat_interface"],                   icon = ICON_PATH .. "icon_general.tga",    accent = { 0.49, 0.91, 1.00 }, desc = L["cat_interface_desc"], kw = "general minimap actionbar skins son audio chat sacs tooltip" },
    { key = "comfort",   label = L["cat_comfort"],                     icon = ICON_PATH .. "icon_qol.tga",        accent = { 0.38, 0.86, 0.56 }, desc = L["cat_comfort_desc"], kw = "qol confort quete afk housing logement automatisation" },
    { key = "damagemeter", label = LT("cat_damagemeter", "Damage Meter"),  icon = ICON_PATH .. "icon_damagemeter.tga", accent = { 0.80, 0.27, 1.00 }, desc = LT("cat_damagemeter_desc", "Compteur de degats, recap de mort et recap de donjon."), kw = "damage meter dps hps degats soins recap mort donjon compteur tdm" },
    { key = "changelog", label = LT("cat_changelog", "Nouveautes"), icon = ICON_PATH .. "icon_qol.tga", accent = { 0.36, 0.78, 0.98 }, desc = LT("cat_changelog_desc", "Toutes les notes de version, de la plus recente a la plus ancienne."), kw = "changelog nouveautes notes version patch historique whatsnew quoi de neuf" },
    { key = "profiles",    label = L["cat_profiles"],                  icon = ICON_PATH .. "icon_profiles.tga",    accent = { 0.67, 0.52, 1.00 }, desc = L["cat_profiles_desc"], kw = "profil profils specialisation spec import export sauvegarde backup reinitialiser reset" },
    { key = "diagnostics", label = L["cat_diagnostics"],               icon = ICON_PATH .. "icon_diagnostics.tga", accent = { 0.94, 0.48, 0.48 }, desc = L["cat_diagnostics_desc"], kw = "diagnostics diagnostic debug erreurs lua performance memoire etat modules" },
}

-- Exposed for Config/GlobalSearch.lua (ghost indexing needs the labels)
C.Categories = categories

-- =====================================================================
-- STUDIOS
-- The dedicated LoadOnDemand editors own Unit Frames, Nameplates, castbars,
-- group frames, resources, cooldowns and Mythic+. They are first-class
-- entries of the sidebar; every old deep link to those settings (EditMode
-- gear routes, /tmt, saved bookmarks) resolves to the matching Studio.
-- =====================================================================
local STUDIOS = {
    { key = "astral", addon = "TomoMod_AstralForge", global = "TomoMod_AstralForge",
      icon = ICON_PATH .. "icon_unitframes.tga", navKey = "nav_studio_astral", navFallback = "Unit frames & nameplates",
      title = "dash_studio_astral_title", titleFallback = "Astral Forge Studio", desc = "dash_studio_astral_desc",
      kw = "astral forge studio unit frames unitframes nameplates plaques cadres joueur cible focus familier boss castbar incantation" },
    { key = "group", addon = "TomoMod_GroupStudio", global = "TomoMod_GroupStudio", defaultArg = "party",
      icon = ICON_PATH .. "icon_partyframes.tga", navKey = "nav_studio_group", navFallback = "Party & raid",
      title = "dash_studio_group_title", titleFallback = "Party & Raid Studio", desc = "dash_studio_group_desc",
      kw = "party raid groupe frames healer soigneur hots dispel defensifs" },
    { key = "resourcecast", addon = "TomoMod_ResourceCastStudio", global = "TomoMod_ResourceCastStudio", defaultArg = "resources",
      icon = ICON_PATH .. "icon_resources.tga", navKey = "nav_studio_resourcecast", navFallback = "Resources & castbar",
      title = "dash_studio_resourcecast_title", titleFallback = "Resource & Cast Studio", desc = "dash_studio_resourcecast_desc",
      kw = "resources ressources resource bars castbar incantation gcd player joueur sante health" },
    { key = "cooldown", addon = "TomoMod_CDStudio", global = "TomoMod_CDStudio",
      icon = ICON_PATH .. "icon_castbars.tga", navKey = "nav_studio_cooldown", navFallback = "Cooldowns",
      title = "dash_studio_cooldown_title", titleFallback = "Cooldown Studio", desc = "dash_studio_cooldown_desc",
      kw = "cooldown cooldowns cd forge studio sorts spells barres bars" },
    { key = "mythic", addon = "TomoMod_MythicPlus", launcher = "mythic",
      icon = ICON_PATH .. "icon_mythicplus.tga", navKey = "nav_studio_mythic", navFallback = "Mythic+",
      title = "dash_studio_mythic_title", titleFallback = "Mythic+ Studio", desc = "dash_studio_mythic_desc",
      kw = "mythic mythique m+ mplus keystone cle score donjon tracker" },
}
-- A Studio whose game system this client does not have is not offered.
if TomoMod_Compat and TomoMod_Compat.IsAddOnBlocked then
    for i = #STUDIOS, 1, -1 do
        if TomoMod_Compat.IsAddOnBlocked(STUDIOS[i].addon) then table.remove(STUDIOS, i) end
    end
end
local STUDIO_BY_KEY = {}
for _, def in ipairs(STUDIOS) do
    def.label = LT(def.navKey, def.navFallback)
    STUDIO_BY_KEY[def.key] = def
end
C.Studios = STUDIOS

-- Old category keys whose settings now live in a Studio. Quoted keys on
-- purpose: Tools/test_layout_gear.lua checks every EditMode route name
-- against this file as a quoted string.
local STUDIO_ALIASES = {
    ["unitframes"]  = { studio = "astral" },
    ["nameplates"]  = { studio = "astral", arg = "nameplate" },
    ["partyframes"] = { studio = "group", arg = "party" },
    ["raidframes"]  = { studio = "group", arg = "raid" },
    ["castbars"]    = { studio = "resourcecast", arg = "cast" },
    ["resources"]   = { studio = "resourcecast", arg = "resources" },
    ["cdforge"]     = { studio = "cooldown" },
    ["mythicplus"]  = { studio = "mythic" },
    -- Removed legacy workspaces.
    ["units"]       = { studio = "astral" },
    ["combat"]      = { studio = "resourcecast" },
}

function C.OpenStudio(key, arg)
    local def = STUDIO_BY_KEY[key]
    if not def then return false end
    local Forge = TomoMod_Forge
    if def.launcher == "mythic" then
        if Forge and Forge.Studio and Forge.Studio.ClearSearchBuildContext then
            Forge.Studio.ClearSearchBuildContext()
        end
        local B = TomoMod_MythicPlusLauncher
        if B and B.Open then
            B:Open(arg or "dashboard")
            return true
        end
        return false
    end
    if not (Forge and Forge.Studio and Forge.Studio.Launch) then return false end
    return Forge.Studio.Launch({
        addon  = def.addon,
        global = def.global,
        label  = LT(def.title, def.titleFallback),
        arg    = arg or def.defaultArg,
    })
end

-- Kept as a global: the dashboard and older bookmarks call it by name.
function TomoMod_OpenCooldownStudio() return C.OpenStudio("cooldown") end

local categoryAliases = {
    general     = { key = "interface", tab = "general" },
    actionbars  = { key = "interface", tab = "actionbars" },
    skins       = { key = "interface", tab = "skins" },
    sound       = { key = "interface", tab = "sound" },
    cdm         = { key = "interface", tab = "cdm" },

    qol         = { key = "comfort", tab = "qol" },
    housing     = { key = "comfort", tab = "housing" },

    -- Legacy: the old grouped "Tools" category was split back into two
    -- standalone entries. Kept so any stale deep-link still resolves.
    tools       = { key = "profiles" },
}

-- Second navigation level, drawn in the sidebar under its category while
-- that category is open. The panel builders stay untouched.
local INTERFACE_WORKSPACE_ITEMS = {
    { key = "general",    label = L["cfg_tab_general"],    kw = "general minimap interface" },
    { key = "actionbars", label = L["cfg_tab_actionbars"], kw = "action bars barres action" },
    { key = "skins",      label = L["cfg_tab_skins"],      kw = "skins apparence chat sacs menu" },
    { key = "sound",      label = L["cfg_tab_sound"],      kw = "sound son audio" },
    { key = "cdm",        label = LT("dash_mod_cdm", "Cooldown Manager"), kw = "cooldown manager cdm blizzard viewers essentiels utilitaires buffs" },
}

-- Confort groups are its second level (sidebar); their pages are the third
-- level (horizontal bar above the page), the same depth Interface pages
-- reach with their own tab bars. Grouped by what the player is doing.
local COMFORT_WORKSPACE_GROUPS = {
    {
        key = "automation", label = LT("comfort_grp_automation", "Automation"), default = "automations",
        pages = {
            { key = "automations", label = LT("comfort_page_general", "General"), kw = "automation automatisation general invite summon delete combat text prey" },
            { key = "cinematic",   label = L["tab_qol_cinematic"],      kw = "cinematic cinematique skip" },
            { key = "autoquest",   label = L["tab_qol_auto_quest"],     kw = "auto quest quete" },
            { key = "merchant",    label = L["tab_qol_merchant_tools"], kw = "merchant vendeur repair reparer vendor" },
        },
    },
    {
        key = "world", label = LT("comfort_grp_world", "World & travel"), default = "worldquests",
        pages = {
            { key = "worldquests", label = L["tab_qol_world_quests"], kw = "world quest quetes monde" },
            { key = "waypoint",    label = L["tab_qol_waypoint"],     kw = "waypoint point navigation" },
            { key = "compass",     label = L["tab_qol_compass"],      kw = "compass boussole" },
            { key = "rarealert",   label = L["tab_qol_rare_alert"],   kw = "rare alert alerte rares" },
            { key = "skyride",     label = L["tab_qol_skyride"],      kw = "skyride vol flying dynamique" },
        },
    },
    {
        key = "character", label = LT("comfort_grp_character", "Character & professions"), default = "leveling",
        pages = {
            { key = "leveling",    label = L["tab_qol_leveling"],    kw = "leveling level niveau" },
            { key = "gearadvisor", label = (TomoMod_GearAdvisor and TomoMod_GearAdvisor.L and TomoMod_GearAdvisor.L("tab")) or LT("comfort_page_gearadvisor", "Gear Advisor"), kw = "gear advisor tomogear equipment equipement upgrade score stats" },
            { key = "profhelper",  label = L["tab_qol_prof_helper"], kw = "profession helper metier" },
            { key = "consumables", label = LT("tab_qol_consumable_bar", LT("comfort_page_consumables", "Consumables")), kw = "consumables consommables flask food huile oil ready tracker" },
        },
    },
    {
        key = "classgroup", label = LT("comfort_grp_classgroup", "Class & group"), default = "classremind",
        pages = {
            { key = "classremind", label = L["tab_qol_class_reminder"], kw = "class reminder classe rappel" },
            { key = "companion",   label = L["tab_qol_companion"],      kw = "companion compagnon" },
            { key = "mythickeys",  label = L["tab_qol_mythic_keys"],    kw = "mythic keys clefs cles" },
        },
    },
    { key = "cvars", label = LT("comfort_grp_cvars", "CVars"), default = "cvaropt", direct = true, kw = "cvars optimizer optimisation" },
    {
        key = "menus", label = LT("comfort_grp_menus", "Menus & housing"), default = "bagmicro",
        pages = {
            -- Bag & Micro Menu will move to Interface > Skins in the later
            -- content pass.
            { key = "bagmicro", label = L["tab_qol_bag_micro"], kw = "bag micro menu sacs" },
            { key = "housing",  label = L["cfg_tab_housing"],   kw = "housing logement maison" },
        },
    },
}

local COMFORT_QOL_PAGES = {
    automations = true, cinematic = true, autoquest = true, mythickeys = true,
    skyride = true, leveling = true, gearadvisor = true, merchant = true, rarealert = true,
    profhelper = true, classremind = true, companion = true, cvaropt = true,
    worldquests = true, waypoint = true, compass = true, bagmicro = true,
}

-- Pages whose game system this client does not have are dropped from the
-- Confort navigation, exactly like CATEGORY_TREE below. QOL leaves follow
-- the QOL tab bar (Compat.IsTabBlocked); the two pages Confort builds
-- itself are checked against their own feature. A group left without any
-- page disappears; a group whose default page is gone opens its first one.
local function ComfortPageBlocked(key)
    local Compat = TomoMod_Compat
    if not Compat then return false end
    if key == "consumables" then
        return Compat.Blocked and Compat.Blocked("consumables") or false
    elseif key == "housing" then
        return Compat.IsPageBlocked and Compat.IsPageBlocked("housing") or false
    end
    return Compat.IsTabBlocked and Compat.IsTabBlocked(key) or false
end

for gi = #COMFORT_WORKSPACE_GROUPS, 1, -1 do
    local group = COMFORT_WORKSPACE_GROUPS[gi]
    if group.direct then
        if ComfortPageBlocked(group.default) then
            table.remove(COMFORT_WORKSPACE_GROUPS, gi)
        end
    else
        local pages = group.pages or {}
        for pi = #pages, 1, -1 do
            if ComfortPageBlocked(pages[pi].key) then table.remove(pages, pi) end
        end
        if #pages == 0 then
            table.remove(COMFORT_WORKSPACE_GROUPS, gi)
        else
            local keep = false
            for _, page in ipairs(pages) do
                if page.key == group.default then keep = true; break end
            end
            if not keep then group.default = pages[1].key end
        end
    end
end
for key in pairs(COMFORT_QOL_PAGES) do
    if ComfortPageBlocked(key) then COMFORT_QOL_PAGES[key] = nil end
end

local COMFORT_PAGE_TO_GROUP = {}
local COMFORT_PAGE_LABEL = {}
for _, group in ipairs(COMFORT_WORKSPACE_GROUPS) do
    if group.direct then
        COMFORT_PAGE_TO_GROUP[group.default] = group.key
        COMFORT_PAGE_LABEL[group.default] = group.label
    else
        for _, page in ipairs(group.pages or {}) do
            COMFORT_PAGE_TO_GROUP[page.key] = group.key
            COMFORT_PAGE_LABEL[page.key] = page.label
        end
    end
end

-- State
local configFrame
local currentCategory = nil
local currentInterfacePage = "general"
local currentComfortPage = "automations"
local comfortLastPageByGroup = {}
local categoryPanels  = {}
local categoryButtons = {}
local interfaceSubButtons = {}
local comfortSubButtons = {}
local studioButtons = {}
local activeCategoryPanel = nil
local hiddenPanelBin = nil

-- [Lot C] Categories re-shown from cache on revisit. Accueil (dashboard,
-- preset tiles), Profiles (profile list) and Diagnostics (live readings)
-- always rebuild so their dynamic content stays fresh.
local NO_CACHE = { accueil = true, profiles = true, diagnostics = true, changelog = true, damagemeter = true }

-- =====================================================================
-- HELPERS
-- =====================================================================
local function GetAccent() return T.accent[1], T.accent[2], T.accent[3] end

local function GuiDB()
    if not TomoModDB then return {} end
    TomoModDB.configGUI = TomoModDB.configGUI or {}
    return TomoModDB.configGUI
end

local function CategoryAccent(cat)
    local c = cat and cat.accent or T.accent
    return c[1] or T.accent[1], c[2] or T.accent[2], c[3] or T.accent[3]
end

local function GetCategory(key)
    for _, cat in ipairs(categories) do
        if cat.key == key then return cat end
    end
    return nil
end

local function GetHiddenPanelBin()
    if hiddenPanelBin then return hiddenPanelBin end
    hiddenPanelBin = CreateFrame("Frame", nil, UIParent)
    hiddenPanelBin:SetSize(1, 1)
    hiddenPanelBin:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -10000, -10000)
    hiddenPanelBin:Hide()
    return hiddenPanelBin
end

local function ParkPanel(panel)
    if not panel then return end
    if panel.Hide then pcall(panel.Hide, panel) end
    if panel.SetScript then pcall(panel.SetScript, panel, "OnUpdate", nil) end
    if panel.GetChildren then
        local children = { panel:GetChildren() }
        for _, child in ipairs(children) do
            ParkPanel(child)
        end
    end
    if panel.IsProtected and panel:IsProtected() then return end
    if panel.ClearAllPoints then pcall(panel.ClearAllPoints, panel) end
    if panel.SetParent then pcall(panel.SetParent, panel, GetHiddenPanelBin()) end
end

local function ClearContentArea()
    if not configFrame or not configFrame.content or not configFrame.content.GetChildren then return end

    local children = { configFrame.content:GetChildren() }
    for _, child in ipairs(children) do
        ParkPanel(child)
    end

    activeCategoryPanel = nil
    categoryPanels = {}
end

-- Performance ticker
local perfTicker
local function StopPerfTicker()
    if perfTicker then perfTicker:Cancel() end
    perfTicker = nil
end

local function StartPerfTicker(label)
    if not label then return end
    local function Sample()
        if not (label and label:IsShown()) then StopPerfTicker(); return end
        local fps = math.floor(GetFramerate() + 0.5)
        local mem = 0
        if UpdateAddOnMemoryUsage then
            UpdateAddOnMemoryUsage()
            local raw = GetAddOnMemoryUsage and GetAddOnMemoryUsage("TomoMod")
            mem = (raw and raw > 0) and raw or 0
        end
        local memStr
        if mem >= 1024 then
            memStr = string.format("%.1f MB", mem / 1024)
        else
            memStr = string.format("%d KB", math.floor(mem + 0.5))
        end
        label:SetText(string.format(L["cfg_footer_perf"], fps, memStr))
    end
    Sample()
    perfTicker = C_Timer.NewTicker(2, Sample)
end

-- =====================================================================
-- NAV BUTTON  — icône .tga simple, redimensionnée pour le nouveau GUI
-- Même logique que l'ancien GUI mais adapté à 210px de sidebar
-- =====================================================================
local NAV_BTN_H = 40   -- légèrement plus grand que les 36px de l'ancien GUI

local function CreateNavButton(parent, cat, yOffset)
    local aR, aG, aB = CategoryAccent(cat)

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(NAV_W, NAV_BTN_H)
    btn:SetPoint("TOPLEFT", 0, yOffset)

    -- Fond de sélection
    local selBg = btn:CreateTexture(nil, "BACKGROUND", nil, -1)
    selBg:SetAllPoints()
    selBg:SetColorTexture(aR, aG, aB, 0)
    btn.selBg = selBg

    -- Barre accent gauche (3px, identique à l'ancien)
    local selBar = btn:CreateTexture(nil, "OVERLAY")
    selBar:SetWidth(3)
    selBar:SetPoint("TOPLEFT")
    selBar:SetPoint("BOTTOMLEFT")
    selBar:SetColorTexture(aR, aG, aB, 1)
    selBar:Hide()
    btn.selBar = selBar

    -- Icône .tga — 22×22 (vs 18×18 dans l'ancien GUI)
    local ico = btn:CreateTexture(nil, "OVERLAY")
    ico:SetSize(22, 22)
    ico:SetPoint("LEFT", 16, 0)
    ico:SetTexture(cat.icon)
    ico:SetVertexColor(0.46, 0.46, 0.52, 1)
    btn.ico = ico

    -- Label — police légèrement plus grande
    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 12, "")
    lbl:SetPoint("LEFT", ico, "RIGHT", 10, 0)
    lbl:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetTextColor(T.textDim[1], T.textDim[2], T.textDim[3], 1)
    lbl:SetText(cat.label)
    btn.lbl = lbl

    -- Micro-séparateur bas
    local micro = btn:CreateTexture(nil, "ARTWORK")
    micro:SetHeight(1)
    micro:SetPoint("BOTTOMLEFT", 8, 0)
    micro:SetPoint("BOTTOMRIGHT", -8, 0)
    micro:SetColorTexture(1, 1, 1, 0.03)

    -- États actif / inactif
    local function SetActive(active)
        if active then
            selBg:SetColorTexture(aR, aG, aB, 0.10)
            selBar:Show()
            ico:SetVertexColor(aR, aG, aB, 1)
            lbl:SetTextColor(0.92, 0.95, 0.93, 1)
        else
            selBg:SetColorTexture(aR, aG, aB, 0)
            selBar:Hide()
            ico:SetVertexColor(0.46, 0.46, 0.52, 1)
            lbl:SetTextColor(T.textDim[1], T.textDim[2], T.textDim[3], 1)
        end
    end
    btn.SetActive = SetActive

    btn:SetScript("OnEnter", function()
        if currentCategory ~= cat.key then
            selBg:SetColorTexture(aR, aG, aB, 0.05)
            ico:SetVertexColor(aR * 0.7 + 0.2, aG * 0.7 + 0.2, aB * 0.7 + 0.2, 1)
            lbl:SetTextColor(0.70, 0.72, 0.71, 1)
        end
    end)
    btn:SetScript("OnLeave", function()
        SetActive(currentCategory == cat.key)
    end)
    btn:SetScript("OnClick", function()
        C.SwitchCategory(cat.key)
    end)

    return btn
end

-- Sub-items of an open category. The caller says what "active" means and
-- what a click does: Interface pages and Confort groups share the widget.
local SUB_BTN_H = 30

local function CreateSubNavButton(parent, item, categoryKey, isActive, onClick)
    local cat = GetCategory(categoryKey)
    local aR, aG, aB = CategoryAccent(cat)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(NAV_W, SUB_BTN_H)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 28, 0)
    bg:SetPoint("BOTTOMRIGHT", -8, 0)
    bg:SetColorTexture(aR, aG, aB, 0)

    local dot = btn:CreateTexture(nil, "OVERLAY")
    dot:SetSize(4, 4)
    dot:SetPoint("LEFT", 34, 0)
    dot:SetColorTexture(aR, aG, aB, 0.30)

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, "")
    lbl:SetPoint("LEFT", 48, 0)
    lbl:SetPoint("RIGHT", -10, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(item.label or item.key)

    local function SetActive(active)
        if active then
            bg:SetColorTexture(aR, aG, aB, 0.11)
            dot:SetColorTexture(aR, aG, aB, 1)
            lbl:SetTextColor(aR, aG, aB, 1)
        else
            bg:SetColorTexture(aR, aG, aB, 0)
            dot:SetColorTexture(aR, aG, aB, 0.30)
            lbl:SetTextColor(T.textDim[1], T.textDim[2], T.textDim[3], 1)
        end
    end
    btn.SetActive = SetActive
    SetActive(false)

    local function IsActive()
        return currentCategory == categoryKey and isActive(item) or false
    end

    btn:SetScript("OnEnter", function()
        if not IsActive() then
            bg:SetColorTexture(aR, aG, aB, 0.05)
            lbl:SetTextColor(0.76, 0.78, 0.80, 1)
        end
    end)
    btn:SetScript("OnLeave", function()
        SetActive(IsActive())
    end)
    btn:SetScript("OnClick", function()
        onClick(item)
    end)

    return btn
end

-- Studio entries: an icon and a label, like a category, but a click opens
-- the dedicated editor instead of a page. The tooltip carries the Studio's
-- full name and description, so the short sidebar label can stay short.
local function CreateStudioNavButton(parent, def)
    local aR, aG, aB = GetAccent()
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(NAV_W, SUB_BTN_H + 2)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 8, 0)
    bg:SetPoint("BOTTOMRIGHT", -8, 0)
    bg:SetColorTexture(aR, aG, aB, 0)

    local ico = btn:CreateTexture(nil, "OVERLAY")
    ico:SetSize(16, 16)
    ico:SetPoint("LEFT", 19, 0)
    ico:SetTexture(def.icon)
    ico:SetVertexColor(0.46, 0.46, 0.52, 1)

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, "")
    lbl:SetPoint("LEFT", ico, "RIGHT", 10, 0)
    lbl:SetPoint("RIGHT", -10, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetWordWrap(false)
    lbl:SetText(def.label)
    lbl:SetTextColor(0.62, 0.62, 0.68, 1)

    btn:SetScript("OnEnter", function(self)
        bg:SetColorTexture(aR, aG, aB, 0.08)
        ico:SetVertexColor(aR, aG, aB, 1)
        lbl:SetTextColor(0.92, 0.95, 0.93, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(LT(def.title, def.titleFallback), 1, 1, 1)
        local desc = def.desc and LT(def.desc, "") or ""
        if desc ~= "" then GameTooltip:AddLine(desc, 0.72, 0.72, 0.78, true) end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        bg:SetColorTexture(aR, aG, aB, 0)
        ico:SetVertexColor(0.46, 0.46, 0.52, 1)
        lbl:SetTextColor(0.62, 0.62, 0.68, 1)
        GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", function()
        GameTooltip:Hide()
        C.OpenStudio(def.key)
    end)
    return btn
end

-- Page shell: carries the category design (accent) for the widgets inside.
-- It used to draw a 92px header repeating the category title and
-- description, which the title bar already shows (context title + desc);
-- the page now starts at the top of the content area.
local function CreatePageShell(parent, cat)
    if not cat or cat.key == "accueil" then
        return parent, nil
    end

    local shell = CreateFrame("Frame", nil, parent)
    shell:SetAllPoints()
    shell._muiDesign = cat

    local body = CreateFrame("Frame", nil, shell)
    body:SetPoint("TOPLEFT", 0, 0)
    body:SetPoint("BOTTOMRIGHT", 0, 0)
    body._muiDesign = cat

    return body, shell
end

local function BuildPanelByName(parent, globalName)
    local builder = globalName and _G[globalName]
    if builder then return builder(parent) end
    return nil
end

-- Applies (and always consumes) a pending deep-link tab on a panel that
-- owns a tab bar. Unknown keys are ignored: CreateTabPanel.SwitchTab has
-- no guard of its own and would leave the page blank.
local function SwitchPendingTab(panel)
    local key = C._pendingGroupTab
    C._pendingGroupTab = nil
    if not (key and panel and panel.SwitchTab) then return end
    if panel.HasTab and not panel.HasTab(key) then return end
    panel.SwitchTab(key)
end

local function BuildGroupedPanel(parent, tabs, defaultKey)
    -- A pending deep-link path names the outermost tab at index 1 and takes
    -- precedence over the legacy single-key hint. The path itself is NOT
    -- consumed here: nested tab bars further down still need to read it.
    local path = C._pendingTabPath
    local selected = (path and path[1]) or C._pendingGroupTab or defaultKey or (tabs[1] and tabs[1].key)
    C._pendingGroupTab = nil

    local exists = false
    for _, tab in ipairs(tabs) do
        if tab.key == selected then exists = true; break end
    end
    if not exists then selected = tabs[1] and tabs[1].key end

    local panel = W.CreateTabPanel(parent, tabs)
    if panel and selected and panel.SwitchTab then
        panel.SwitchTab(selected)
    end
    return panel
end

-- Category → tabs tree, shared by SwitchCategory and by
-- Config/GlobalSearch.lua (ghost indexing needs the full mapping as data).
local CATEGORY_TREE = {
    interface = {
        { key = "general",    label = L["cfg_tab_general"],          global = "TomoMod_ConfigPanel_General" },
        { key = "actionbars", label = L["cfg_tab_actionbars"],  global = "TomoMod_ConfigPanel_ActionBars" },
        { key = "skins",      label = L["cfg_tab_skins"],            global = "TomoMod_ConfigPanel_Skins" },
        { key = "sound",      label = L["cfg_tab_sound"],              global = "TomoMod_ConfigPanel_Sound" },
        { key = "cdm",        label = LT("dash_mod_cdm", "Cooldown Manager"), global = "TomoMod_ConfigPanel_CooldownManager" },
    },
    roles = {
        { key = "tank",   label = L["cfg_tab_role_tank"],   global = "TomoMod_ConfigPanel_RoleTank" },
        { key = "healer", label = L["cfg_tab_role_healer"], global = "TomoMod_ConfigPanel_RoleHealer" },
        { key = "dps",    label = L["cfg_tab_role_dps"],    global = "TomoMod_ConfigPanel_RoleDps" },
    },
    comfort = {
        { key = "qol",     label = L["cfg_tab_qol"], global = "TomoMod_ConfigPanel_QOL" },
        { key = "housing", label = L["cfg_tab_housing"],        global = "TomoMod_ConfigPanel_Housing" },
    },
}
-- Pages whose game system this client does not have are removed from the
-- navigation rather than shown empty or greyed. Done on the tree itself
-- so Config/GlobalSearch.lua, which ghost-indexes from the same data,
-- cannot offer a deep link to a page that is no longer reachable.
if TomoMod_Compat and TomoMod_Compat.IsPageBlocked then
    for _, tabs in pairs(CATEGORY_TREE) do
        for i = #tabs, 1, -1 do
            if TomoMod_Compat.IsPageBlocked(tabs[i].key) then
                table.remove(tabs, i)
            end
        end
    end
end

-- The Interface sub-navigation is drawn from its own list: keep only the
-- pages the filtered tree still holds, or a blocked page (Action Bars on
-- WoW: Forever) stays in the sidebar as a button that does nothing.
do
    local present = {}
    for _, t in ipairs(CATEGORY_TREE.interface or {}) do present[t.key] = true end
    for i = #INTERFACE_WORKSPACE_ITEMS, 1, -1 do
        if not present[INTERFACE_WORKSPACE_ITEMS[i].key] then
            table.remove(INTERFACE_WORKSPACE_ITEMS, i)
        end
    end
end

C.CategoryTree = CATEGORY_TREE

-- Categories that are a single page (no tab bar of their own at this
-- level). Shared with Config/GlobalSearch.lua so ghost indexing covers
-- them exactly like the grouped ones.
local SINGLE_PAGES = {
    accueil     = "TomoMod_ConfigPanel_Accueil",
    damagemeter = "TomoMod_ConfigPanel_DamageMeter",
    changelog   = "TomoMod_ConfigPanel_Changelog",
    profiles    = "TomoMod_ConfigPanel_Profiles",
    diagnostics = "TomoMod_ConfigPanel_Diagnostics",
}
C.SinglePages = SINGLE_PAGES

local function BuildGroupedFromTree(parent, catKey)
    local tabs = {}
    for i, t in ipairs(CATEGORY_TREE[catKey] or {}) do
        local globalName = t.global
        tabs[i] = {
            key = t.key, label = t.label,
            builder = function(p) return BuildPanelByName(p, globalName) end,
        }
    end
    return BuildGroupedPanel(parent, tabs, tabs[1] and tabs[1].key)
end

-- Interface workspace: same lazy panel caching as CreateTabPanel, but the
-- first navigation level lives in the left sidebar instead of a horizontal
-- tab bar. Nested tabs inside General/ActionBars/Skins/Sound are unchanged.
local function BuildInterfaceWorkspacePanel(parent)
    local tabs = CATEGORY_TREE.interface or {}
    local wrapper = CreateFrame("Frame", nil, parent)
    wrapper:SetAllPoints()
    wrapper._muiDesign = GetCategory("interface")

    local content = CreateFrame("Frame", nil, wrapper)
    content:SetAllPoints()
    content._muiDesign = wrapper._muiDesign

    local tabPanels = {}
    local currentTab = nil

    local function FindTab(key)
        for _, tab in ipairs(tabs) do
            if tab.key == key then return tab end
        end
        return nil
    end

    local function SwitchTab(key)
        local tab = FindTab(key)
        if not tab then return end

        if currentTab and tabPanels[currentTab] and tabPanels[currentTab].Hide then
            tabPanels[currentTab]:Hide()
        end

        if not tabPanels[key] then
            -- Reproduce the outer-tab build path that CreateTabPanel normally
            -- establishes, so Global Search and nested deep-links keep the
            -- exact same category > tab path as before this GUI refactor.
            if W._RestoreTabPath then W._RestoreTabPath({}) end
            if W._SetBuildTabAt then
                W._SetBuildTabAt(1, tab.key, tab.label)
            elseif W._SetBuildTab then
                W._SetBuildTab(tab.key, tab.label)
            end

            local panel = BuildPanelByName(content, tab.global)
            if panel then
                if panel:GetParent() ~= content then panel:SetParent(content) end
                panel:SetAllPoints(content)
                tabPanels[key] = panel
            end
        end

        if tabPanels[key] then tabPanels[key]:Show() end
        currentTab = key
        currentInterfacePage = key

        if configFrame and configFrame._contextTitle then
            local cat = GetCategory("interface")
            configFrame._contextTitle:SetText(
                string.format("%s  /  %s", cat and cat.label or "Interface", tab.label or key))
        end
        if C.RefreshWorkspaceNav then C.RefreshWorkspaceNav() end
        if W.ApplyRoleFilter then W.ApplyRoleFilter() end
    end

    local pendingPath = C._pendingTabPath
    local startKey = (pendingPath and pendingPath[1]) or C._pendingGroupTab or currentInterfacePage
    if not FindTab(startKey) then startKey = tabs[1] and tabs[1].key end

    wrapper.SwitchTab = SwitchTab
    wrapper.HasTab = function(key) return FindTab(key) ~= nil end
    wrapper.content = content
    wrapper:SetScript("OnShow", function()
        if currentTab then SwitchTab(currentTab) end
    end)

    if startKey then SwitchTab(startKey) end
    return wrapper
end

local function BuildReadyTrackerComfortPanel(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["ready_tracker_section"], y)
    y = ny
    local _, ny = W.CreateInfoText(c, L["ready_tracker_info"], y)
    y = ny

    local function ReadyDB()
        TomoModDB.consumableBar = TomoModDB.consumableBar or {}
        return TomoModDB.consumableBar
    end
    local function Apply()
        if TomoMod_ConsumableBar and TomoMod_ConsumableBar.ApplySettings then
            TomoMod_ConsumableBar.ApplySettings()
        end
    end

    local db = ReadyDB()
    local _, ny = W.CreateCheckbox(c, L["ready_tracker_enable"], db.enabled ~= false, y, function(v)
        ReadyDB().enabled = v
        Apply()
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, L["ready_tracker_button_side"], {
        { text = L["ready_tracker_side_left"],  value = "left" },
        { text = L["ready_tracker_side_right"], value = "right" },
    }, db.buttonSide or "left", y, function(v)
        ReadyDB().buttonSide = v
        Apply()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["ready_tracker_button_size"], db.buttonSize or 20,
        14, 32, 1, y, function(v)
            ReadyDB().buttonSize = v
            Apply()
        end, "%d px")
    y = ny

    local _, ny = W.CreateSlider(c, L["ready_tracker_tracker_size"], db.iconSize or 36,
        24, 56, 2, y, function(v)
            ReadyDB().iconSize = v
            Apply()
        end, "%d px")
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- Confort workspace: QOL remains the rendering engine. Its groups are the
-- second level and live in the sidebar, like the Interface pages; the
-- pages of the open group are the third level, one tab bar above the
-- content -- the same place and size as the tab bars inside Interface
-- pages, so every category reads the same way.
local function BuildComfortWorkspacePanel(parent)
    local wrapper = CreateFrame("Frame", nil, parent)
    wrapper:SetAllPoints()
    wrapper._muiDesign = GetCategory("comfort")

    local cat = GetCategory("comfort")
    local aR, aG, aB = CategoryAccent(cat)
    local PAGE_H = 32   -- W.CreateTabPanel's TAB_H

    -- Pages of the selected group (hidden for single-page groups).
    local pageBar = CreateFrame("Frame", nil, wrapper)
    pageBar:SetPoint("TOPLEFT")
    pageBar:SetPoint("TOPRIGHT")
    pageBar:SetHeight(PAGE_H)
    local pageBg = pageBar:CreateTexture(nil, "BACKGROUND")
    pageBg:SetAllPoints()
    pageBg:SetColorTexture(0.043, 0.043, 0.056, 1)
    local pageLine = pageBar:CreateTexture(nil, "ARTWORK")
    pageLine:SetHeight(1)
    pageLine:SetPoint("BOTTOMLEFT")
    pageLine:SetPoint("BOTTOMRIGHT")
    pageLine:SetColorTexture(aR, aG, aB, 0.14)

    local content = CreateFrame("Frame", nil, wrapper)
    content:SetPoint("TOPLEFT", pageBar, "BOTTOMLEFT", 0, -1)
    content:SetPoint("BOTTOMRIGHT", 0, 0)
    content._muiDesign = wrapper._muiDesign

    local qolPanel, housingPanel, readyPanel
    local currentSurface
    local pageButtons = {}

    local function FindGroup(groupKey)
        for _, group in ipairs(COMFORT_WORKSPACE_GROUPS) do
            if group.key == groupKey then return group end
        end
        return nil
    end

    local function CreateRightTabButton(parentFrame, label, height)
        local btn = CreateFrame("Button", nil, parentFrame)
        btn:SetHeight(height)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0)
        btn._bg = bg

        local indicator = btn:CreateTexture(nil, "ARTWORK")
        indicator:SetHeight(2)
        indicator:SetPoint("BOTTOMLEFT", 4, 0)
        indicator:SetPoint("BOTTOMRIGHT", -4, 0)
        indicator:SetColorTexture(aR, aG, aB, 1)
        indicator:Hide()
        btn._indicator = indicator

        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT, 11, "")
        lbl:SetPoint("LEFT", 7, 0)
        lbl:SetPoint("RIGHT", -7, 0)
        lbl:SetJustifyH("CENTER")
        lbl:SetText(label or "")
        lbl:SetTextColor(T.textDim[1], T.textDim[2], T.textDim[3], 1)
        btn._label = lbl

        btn.SetActive = function(_, active)
            if active then
                bg:SetColorTexture(aR, aG, aB, 0.11)
                indicator:Show()
                lbl:SetTextColor(aR, aG, aB, 1)
            else
                bg:SetColorTexture(0, 0, 0, 0)
                indicator:Hide()
                lbl:SetTextColor(T.textDim[1], T.textDim[2], T.textDim[3], 1)
            end
        end
        btn:SetScript("OnEnter", function(self)
            if not self._active then
                bg:SetColorTexture(aR, aG, aB, 0.05)
                lbl:SetTextColor(0.76, 0.78, 0.80, 1)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetActive(self._active)
        end)
        return btn
    end

    local function LayoutButtons(bar, buttons, orderedKeys, height)
        local count = #orderedKeys
        if count == 0 then return end
        local width = bar:GetWidth() or 0
        if width < 100 then width = parent:GetWidth() or 1000 end
        if width < 100 then width = 1000 end
        local each = math.max(80, math.floor(width / count))
        for i, key in ipairs(orderedKeys) do
            local btn = buttons[key]
            if btn then
                btn:ClearAllPoints()
                btn:SetSize((i == count) and math.max(80, width - each * (count - 1)) or each, height)
                btn:SetPoint("TOPLEFT", bar, "TOPLEFT", (i - 1) * each, 0)
            end
        end
    end

    for _, group in ipairs(COMFORT_WORKSPACE_GROUPS) do
        for _, page in ipairs(group.pages or {}) do
            local pageDef = page
            local pageBtn = CreateRightTabButton(pageBar, pageDef.label, PAGE_H)
            pageBtn:SetScript("OnClick", function()
                if wrapper.SwitchTab then wrapper.SwitchTab(pageDef.key) end
            end)
            pageBtn:Hide()
            pageButtons[pageDef.key] = pageBtn
        end
    end

    local function RefreshRightNav(key)
        local groupKey = COMFORT_PAGE_TO_GROUP[key]
        local group = FindGroup(groupKey)
        for _, btn in pairs(pageButtons) do btn:Hide() end

        local orderedPages = {}
        if group and not group.direct and #(group.pages or {}) > 1 then
            for _, page in ipairs(group.pages or {}) do
                orderedPages[#orderedPages + 1] = page.key
                local btn = pageButtons[page.key]
                if btn then
                    btn._active = (page.key == key)
                    btn:SetActive(btn._active)
                    btn:Show()
                end
            end
            pageBar:Show()
            content:ClearAllPoints()
            content:SetPoint("TOPLEFT", pageBar, "BOTTOMLEFT", 0, -1)
            content:SetPoint("BOTTOMRIGHT", 0, 0)
            LayoutButtons(pageBar, pageButtons, orderedPages, PAGE_H)
        else
            pageBar:Hide()
            content:ClearAllPoints()
            content:SetPoint("TOPLEFT", 0, 0)
            content:SetPoint("BOTTOMRIGHT", 0, 0)
        end
    end

    pageBar:SetScript("OnSizeChanged", function() RefreshRightNav(currentComfortPage) end)

    local function HideCurrent()
        if currentSurface and currentSurface.Hide then currentSurface:Hide() end
        currentSurface = nil
    end

    local function SetOuterPath(key, label)
        if W._RestoreTabPath then W._RestoreTabPath({}) end
        if W._SetBuildTabAt then
            W._SetBuildTabAt(1, key, label)
        elseif W._SetBuildTab then
            W._SetBuildTab(key, label)
        end
    end

    local function EnsureQOLPanel()
        if qolPanel then return qolPanel end
        SetOuterPath("qol", L["cfg_tab_qol"])
        qolPanel = BuildPanelByName(content, "TomoMod_ConfigPanel_QOL")
        if not qolPanel then return nil end
        if qolPanel:GetParent() ~= content then qolPanel:SetParent(content) end
        qolPanel:SetAllPoints(content)

        -- W.CreateTabPanel exposes its content frame. Hide only the sibling
        -- tab bar and let the content reclaim the full available height.
        if qolPanel.content then
            local children = { qolPanel:GetChildren() }
            for _, child in ipairs(children) do
                if child ~= qolPanel.content and child.Hide then child:Hide() end
            end
            qolPanel.content:ClearAllPoints()
            qolPanel.content:SetAllPoints(qolPanel)
        end
        return qolPanel
    end

    local function EnsureHousingPanel()
        if housingPanel then return housingPanel end
        SetOuterPath("housing", L["cfg_tab_housing"])
        housingPanel = BuildPanelByName(content, "TomoMod_ConfigPanel_Housing")
        if housingPanel then
            if housingPanel:GetParent() ~= content then housingPanel:SetParent(content) end
            housingPanel:SetAllPoints(content)
        end
        return housingPanel
    end

    local function EnsureReadyPanel()
        if readyPanel then return readyPanel end
        SetOuterPath("consumables", COMFORT_PAGE_LABEL.consumables)
        readyPanel = BuildReadyTrackerComfortPanel(content)
        if readyPanel then
            if readyPanel:GetParent() ~= content then readyPanel:SetParent(content) end
            readyPanel:SetAllPoints(content)
        end
        return readyPanel
    end

    -- Only pages that survived the client filter are known, so a stale
    -- deep link or a remembered page can never open a blocked one.
    local function IsKnownPage(key)
        return key ~= nil and COMFORT_PAGE_TO_GROUP[key] ~= nil
    end

    local function SwitchTab(key)
        if key == "qol" then key = currentComfortPage end
        if not IsKnownPage(key) then key = "automations" end
        HideCurrent()

        if COMFORT_QOL_PAGES[key] then
            local panel = EnsureQOLPanel()
            if panel then
                -- CreateTabPanel.SwitchTab has no guard of its own: an
                -- unknown key would leave the page blank.
                if panel.HasTab and not panel.HasTab(key) then
                    key = "automations"
                end
                panel:Show()
                if panel.SwitchTab then panel.SwitchTab(key) end
                currentSurface = panel
            end
        elseif key == "consumables" then
            local panel = EnsureReadyPanel()
            if panel then panel:Show(); currentSurface = panel end
        elseif key == "housing" then
            local panel = EnsureHousingPanel()
            if panel then panel:Show(); currentSurface = panel end
        end

        currentComfortPage = key
        local groupKey = COMFORT_PAGE_TO_GROUP[key]
        if groupKey then comfortLastPageByGroup[groupKey] = key end
        RefreshRightNav(key)

        if configFrame and configFrame._contextTitle then
            local group = FindGroup(groupKey)
            local groupLabel = group and group.label
            local pageLabel = COMFORT_PAGE_LABEL[key] or key
            if groupLabel and groupLabel ~= pageLabel then
                configFrame._contextTitle:SetText(string.format("%s  /  %s  /  %s",
                    cat and cat.label or "Confort", groupLabel, pageLabel))
            else
                configFrame._contextTitle:SetText(string.format("%s  /  %s",
                    cat and cat.label or "Confort", pageLabel))
            end
        end

        if C.RefreshWorkspaceNav then C.RefreshWorkspaceNav() end
        if W.ApplyRoleFilter then W.ApplyRoleFilter() end
    end

    local pendingPath = C._pendingTabPath
    local requested = C._pendingGroupTab
    C._pendingGroupTab = nil
    local startKey = currentComfortPage
    if pendingPath and pendingPath[1] == "qol" then
        startKey = pendingPath[2] or startKey
    elseif pendingPath and pendingPath[1] then
        startKey = pendingPath[1]
    elseif requested then
        startKey = requested
    end
    if startKey == "qol" or not IsKnownPage(startKey) then startKey = currentComfortPage end
    if not IsKnownPage(startKey) then startKey = "automations" end

    wrapper.SwitchTab = SwitchTab
    wrapper.HasTab = function(key) return key == "qol" or IsKnownPage(key) end
    wrapper.content = content
    wrapper:SetScript("OnShow", function() SwitchTab(currentComfortPage) end)

    SwitchTab(startKey)
    return wrapper
end

function C.OpenComfortPage(key)
    if not key then return end
    C._pendingGroupTab = key
    C.SwitchCategory("comfort")
end

-- =====================================================================
-- MAIN OPTIONS MULTI-STEP HELP
-- =====================================================================
local OPTIONS_HELP_STEPS = {
    { title = "cfg_help_1_title", body = "cfg_help_1_body", target = "title",   category = "accueil" },
    { title = "cfg_help_2_title", body = "cfg_help_2_body", target = "sidebar" },
    { title = "cfg_help_3_title", body = "cfg_help_3_body", target = "search" },
    { title = "cfg_help_4_title", body = "cfg_help_4_body", target = "role" },
    { title = "cfg_help_5_title", body = "cfg_help_5_body", target = "content", category = "interface" },
    { title = "cfg_help_6_title", body = "cfg_help_6_body", target = "layout" },
    { title = "cfg_help_7_title", body = "cfg_help_7_body", target = "content", category = "profiles" },
    { title = "cfg_help_8_title", body = "cfg_help_8_body", target = "content", category = "diagnostics" },
}

local optionsHelp

local function HelpButton(parent, width, text)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width, 26)
    b:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    b:SetBackdropColor(0.055, 0.060, 0.078, 0.98)
    b:SetBackdropBorderColor(0.18, 0.62, 0.85, 0.70)

    local fs = b:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT_BOLD, 10, "")
    fs:SetPoint("CENTER")
    fs:SetText(text or "")
    fs:SetTextColor(0.88, 0.91, 0.95, 1)
    b._label = fs

    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.08, 0.20, 0.30, 0.98)
        self:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 1)
        fs:SetTextColor(1, 1, 1, 1)
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.055, 0.060, 0.078, 0.98)
        self:SetBackdropBorderColor(0.18, 0.62, 0.85, 0.70)
        fs:SetTextColor(0.88, 0.91, 0.95, 1)
    end)
    return b
end

local function EnsureOptionsHelp()
    if optionsHelp or not configFrame then return optionsHelp end

    local shade = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
    shade:SetAllPoints(configFrame)
    shade:SetFrameLevel(configFrame:GetFrameLevel() + 100)
    shade:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    shade:SetBackdropColor(0.005, 0.008, 0.014, 0.58)
    shade:EnableMouse(true)
    shade:Hide()

    local highlight = CreateFrame("Frame", nil, shade, "BackdropTemplate")
    highlight:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    highlight:SetBackdropColor(0.18, 0.62, 0.85, 0.07)
    highlight:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 1)
    highlight:EnableMouse(false)

    local card = CreateFrame("Frame", nil, shade, "BackdropTemplate")
    card:SetSize(500, 238)
    card:SetPoint("BOTTOMRIGHT", shade, "BOTTOMRIGHT", -24, 52)
    card:SetFrameLevel(shade:GetFrameLevel() + 5)
    card:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    card:SetBackdropColor(0.035, 0.038, 0.052, 1)
    card:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 0.85)

    local accent = card:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", 0, 0)
    accent:SetWidth(3)
    accent:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], 1)

    local progress = card:CreateFontString(nil, "OVERLAY")
    progress:SetFont(FONT, 10, "")
    progress:SetPoint("TOPLEFT", 18, -16)
    progress:SetTextColor(0.46, 0.50, 0.58, 1)

    local title = card:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_BOLD, 17, "")
    title:SetPoint("TOPLEFT", progress, "BOTTOMLEFT", 0, -10)
    title:SetPoint("RIGHT", card, "RIGHT", -42, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(T.accent[1], T.accent[2], T.accent[3], 1)

    local body = card:CreateFontString(nil, "OVERLAY")
    body:SetFont(FONT, 11, "")
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    body:SetPoint("RIGHT", card, "RIGHT", -20, 0)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetWordWrap(true)
    body:SetTextColor(0.78, 0.80, 0.85, 1)

    local closeX = CreateFrame("Button", nil, card)
    closeX:SetSize(26, 26)
    closeX:SetPoint("TOPRIGHT", -7, -7)
    local closeXText = closeX:CreateFontString(nil, "OVERLAY")
    closeXText:SetFont(FONT_BOLD, 18, "")
    closeXText:SetPoint("CENTER")
    closeXText:SetText("×")
    closeXText:SetTextColor(0.46, 0.46, 0.52, 1)
    closeX:SetScript("OnEnter", function() closeXText:SetTextColor(0.95, 0.35, 0.35, 1) end)
    closeX:SetScript("OnLeave", function() closeXText:SetTextColor(0.46, 0.46, 0.52, 1) end)

    local back = HelpButton(card, 92, L["cfg_help_back"] or "Back")
    back:SetPoint("BOTTOMLEFT", 18, 16)
    local close = HelpButton(card, 92, L["cfg_help_close"] or "Close")
    close:SetPoint("BOTTOM", 0, 16)
    local nextBtn = HelpButton(card, 112, L["cfg_help_next"] or "Next")
    nextBtn:SetPoint("BOTTOMRIGHT", -18, 16)

    optionsHelp = shade
    shade.highlight = highlight
    shade.card = card
    shade.progress = progress
    shade.title = title
    shade.body = body
    shade.back = back
    shade.close = close
    shade.next = nextBtn
    shade.closeX = closeX
    shade.step = 1
    shade.returnCategory = nil
    return shade
end

local function CloseOptionsHelp(restore)
    local ui = optionsHelp
    if not ui then return end
    ui:Hide()
    if restore and ui.returnCategory and C.SwitchCategory then
        C.SwitchCategory(ui.returnCategory)
    end
    ui.returnCategory = nil
end

local function ShowOptionsHelpStep(index)
    local ui = EnsureOptionsHelp()
    local count = #OPTIONS_HELP_STEPS
    index = math.max(1, math.min(tonumber(index) or 1, count))
    local step = OPTIONS_HELP_STEPS[index]
    if not ui or not step then return end

    if step.category and C.SwitchCategory then
        C.SwitchCategory(step.category)
    end

    ui.step = index
    ui.progress:SetText(string.format(L["cfg_help_progress"] or "Step %d / %d", index, count))
    ui.title:SetText(L[step.title] or step.title)
    ui.body:SetText(L[step.body] or step.body)
    ui.back:SetShown(index > 1)
    ui.next._label:SetText(index == count
        and (L["cfg_help_finish"] or "Finish")
        or (L["cfg_help_next"] or "Next"))

    local target = configFrame._helpTargets and configFrame._helpTargets[step.target]
    target = target or configFrame
    ui.highlight:ClearAllPoints()
    ui.highlight:SetPoint("TOPLEFT", target, "TOPLEFT", -4, 4)
    ui.highlight:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 4, -4)
    ui.highlight:Show()
end

local function OpenOptionsHelp()
    if not configFrame then return end
    local ui = EnsureOptionsHelp()
    if not ui then return end
    ui.returnCategory = currentCategory or "accueil"
    ui:Show()
    ShowOptionsHelpStep(1)

    ui.back:SetScript("OnClick", function()
        ShowOptionsHelpStep((ui.step or 1) - 1)
    end)
    ui.close:SetScript("OnClick", function()
        CloseOptionsHelp(true)
    end)
    ui.closeX:SetScript("OnClick", function()
        CloseOptionsHelp(true)
    end)
    ui.next:SetScript("OnClick", function()
        if (ui.step or 1) >= #OPTIONS_HELP_STEPS then
            CloseOptionsHelp(true)
        else
            ShowOptionsHelpStep((ui.step or 1) + 1)
        end
    end)
end

C.ShowHelp = OpenOptionsHelp
C.HideHelp = function() CloseOptionsHelp(true) end

-- =====================================================================
-- CREATE MAIN FRAME
-- =====================================================================
-- The default 1240x820 (min 720 high) is taller than the screen at a UI
-- scale of 1.0 (UIParent is 768 units then), and SetClampedToScreen cannot
-- shrink a frame larger than the screen: the footer and the resize grip
-- ended up off-screen. Bound size and resize limits to what UIParent can
-- show at the window's own scale, like Forge.Studio.CreateShell does.
local SCREEN_MARGIN = 24
local function FitToScreen()
    if not configFrame then return end
    local scale = configFrame:GetScale() or 1
    if scale <= 0 then scale = 1 end
    local availW = math.floor(((UIParent:GetWidth()  or PANEL_MAX_W) - SCREEN_MARGIN) / scale)
    local availH = math.floor(((UIParent:GetHeight() or PANEL_MAX_H) - SCREEN_MARGIN) / scale)
    local maxW = math.max(480, math.min(PANEL_MAX_W, availW))
    local maxH = math.max(400, math.min(PANEL_MAX_H, availH))
    local minW = math.min(PANEL_MIN_W, maxW)
    local minH = math.min(PANEL_MIN_H, maxH)
    if configFrame.SetResizeBounds then
        configFrame:SetResizeBounds(minW, minH, maxW, maxH)
    elseif configFrame.SetMinResize then
        configFrame:SetMinResize(minW, minH)
        configFrame:SetMaxResize(maxW, maxH)
    end
    local w = configFrame:GetWidth() or PANEL_W
    local h = configFrame:GetHeight() or PANEL_H
    if w > maxW or h > maxH then
        configFrame:SetSize(math.min(w, maxW), math.min(h, maxH))
    end
end

local function CreateConfigFrame()
    if configFrame then return end

    configFrame = CreateFrame("Frame", "TomoModConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(PANEL_W, PANEL_H)
    configFrame:SetPoint("CENTER")
    configFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    configFrame:SetFrameLevel(500)
    configFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    configFrame:SetBackdropColor(0.035, 0.035, 0.052, 1)
    configFrame:SetBackdropBorderColor(0.14, 0.14, 0.17, 1)
    configFrame:SetMovable(true)
    configFrame:SetClampedToScreen(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop",  configFrame.StopMovingOrSizing)
    configFrame:Hide()
    -- [fix] Escape captured by the window itself. Going through
    -- UISpecialFrames routes it via ToggleGameMenu, whose protected
    -- ClearTarget/SpellStopCasting calls are then refused once anything
    -- has tainted the path -- and the player can no longer quit.
    TomoMod_Utils.CloseOnEscape(_G["TomoModConfigFrame"])

    -- Restore saved size / scale, enable resizing (bounds clamp saved values)
    local gdb = GuiDB()
    if gdb.width and gdb.height then
        configFrame:SetSize(
            math.max(PANEL_MIN_W, math.min(gdb.width,  PANEL_MAX_W)),
            math.max(PANEL_MIN_H, math.min(gdb.height, PANEL_MAX_H)))
    end
    configFrame:SetScale(gdb.scale or 1)
    configFrame:SetResizable(true)
    FitToScreen()

    configFrame:SetScript("OnShow", function(self)
        C.isOpen = true
        FitToScreen()
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        self:SetFrameLevel(500)
        StartPerfTicker(self._perfLabel)
    end)
    configFrame:SetScript("OnHide", function(self)
        C.isOpen = false
        if TomoMod_Profiles and TomoMod_Profiles.AutoSaveActiveProfile then
            TomoMod_Profiles.AutoSaveActiveProfile()
        end
        StopPerfTicker()
        CloseOptionsHelp(false)
        if GameTooltip then GameTooltip:Hide() end
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshThreatPreview then
            TomoMod_UnitFrames.RefreshThreatPreview(false)
        end
        if TomoMod_Castbar and TomoMod_Castbar.SetPreview then
            TomoMod_Castbar.SetPreview(false)
        end
    end)

    -- ==============================================================
    -- TITLE BAR
    -- ==============================================================
    local titleBar = CreateFrame("Frame", nil, configFrame)
    titleBar:SetPoint("TOPLEFT")
    titleBar:SetPoint("TOPRIGHT")
    titleBar:SetHeight(TITLE_H)

    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.05, 0.05, 0.065, 1)

    -- Thin accent line at bottom of title
    local titleLine = configFrame:CreateTexture(nil, "ARTWORK")
    titleLine:SetHeight(1)
    titleLine:SetPoint("TOPLEFT",  0, -TITLE_H)
    titleLine:SetPoint("TOPRIGHT", 0, -TITLE_H)
    titleLine:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], 0.20)
    configFrame._titleLine = titleLine

    -- Gradient wash in header area of content side
    local headerGlow = configFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
    headerGlow:SetPoint("TOPLEFT",  NAV_W + 1, -TITLE_H)
    headerGlow:SetPoint("TOPRIGHT", 0, -TITLE_H)
    headerGlow:SetHeight(60)
    if headerGlow.SetGradientAlpha then
        headerGlow:SetGradientAlpha("VERTICAL",
            T.accent[1] * 0.12, T.accent[2] * 0.12, T.accent[3] * 0.12, 0.40,
            0, 0, 0, 0)
    else
        headerGlow:SetColorTexture(T.accent[1] * 0.12, T.accent[2] * 0.12, T.accent[3] * 0.12, 0.25)
    end
    configFrame._headerGlow = headerGlow

    -- Logo
    local logo = titleBar:CreateTexture(nil, "OVERLAY")
    logo:SetSize(32, 32)
    logo:SetPoint("LEFT", 14, 0)
    logo:SetTexture(ADDON_PATH .. "Assets\\Textures\\Logo.tga")
    logo:SetVertexColor(1, 1, 1, 1)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY")
    titleText:SetFont(FONT_BOLD, 16, "")
    titleText:SetPoint("LEFT", logo, "RIGHT", 8, 1)
    titleText:SetText("|cff2e9dd8Tomo|r|cffe4e4e4Mod|r")

    local versionText = titleBar:CreateFontString(nil, "OVERLAY")
    versionText:SetFont(FONT, 10, "")
    versionText:SetPoint("LEFT", titleText, "RIGHT", 8, -2)
    versionText:SetTextColor(T.textFaint[1], T.textFaint[2], T.textFaint[3], 1)
    versionText:SetText("v" .. (C_AddOns.GetAddOnMetadata("TomoMod", "Version") or "?"))

    local contextTitle = titleBar:CreateFontString(nil, "OVERLAY")
    contextTitle:SetFont(FONT_BOLD, 12, "")
    contextTitle:SetPoint("LEFT", titleText, "RIGHT", 96, 8)
    contextTitle:SetPoint("RIGHT", -282, 0)
    contextTitle:SetJustifyH("LEFT")
    contextTitle:SetTextColor(T.accent[1], T.accent[2], T.accent[3], 1)
    configFrame._contextTitle = contextTitle

    local contextDesc = titleBar:CreateFontString(nil, "OVERLAY")
    contextDesc:SetFont(FONT, 11, "")
    contextDesc:SetPoint("TOPLEFT", contextTitle, "BOTTOMLEFT", 0, -3)
    contextDesc:SetPoint("RIGHT", -282, 0)
    contextDesc:SetJustifyH("LEFT")
    contextDesc:SetTextColor(T.textDim[1], T.textDim[2], T.textDim[3], 1)
    configFrame._contextDesc = contextDesc

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(32, 32)
    closeBtn:SetPoint("RIGHT", -10, 0)
    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY")
    closeTxt:SetFont(FONT_BOLD, 22, "")
    closeTxt:SetPoint("CENTER", 0, 1)
    closeTxt:SetText("×")
    closeTxt:SetTextColor(0.36, 0.36, 0.40, 1)
    closeBtn:SetScript("OnEnter", function() closeTxt:SetTextColor(0.90, 0.28, 0.28, 1) end)
    closeBtn:SetScript("OnLeave", function() closeTxt:SetTextColor(0.36, 0.36, 0.40, 1) end)
    closeBtn:SetScript("OnClick", function() configFrame:Hide() end)

    -- Layout button
    local layoutBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    layoutBtn:SetSize(84, 26)
    layoutBtn:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)
    layoutBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })

    local function UpdateLayoutStyle()
        local unlocked = TomoMod_Movers and TomoMod_Movers.IsUnlocked and TomoMod_Movers.IsUnlocked()
        if unlocked then
            layoutBtn:SetBackdropColor(0.03, 0.20, 0.14, 0.9)
            layoutBtn:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 0.90)
        else
            layoutBtn:SetBackdropColor(0.07, 0.07, 0.09, 0.8)
            layoutBtn:SetBackdropBorderColor(0.20, 0.20, 0.25, 0.8)
        end
    end
    UpdateLayoutStyle()

    local layoutTxt = layoutBtn:CreateFontString(nil, "OVERLAY")
    layoutTxt:SetFont(FONT, 11, "")
    layoutTxt:SetPoint("CENTER")
    layoutTxt:SetText(L["btn_layout"] or "EditMode")
    layoutTxt:SetTextColor(T.accent[1], T.accent[2], T.accent[3], 1)
    layoutBtn:SetScript("OnEnter", function()
        layoutBtn:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 1)
        layoutTxt:SetTextColor(1, 1, 1, 1)
        GameTooltip:SetOwner(layoutBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["btn_layout_tooltip"] or "Toggle Layout Mode", 1, 1, 1)
        GameTooltip:Show()
    end)
    layoutBtn:SetScript("OnLeave", function()
        UpdateLayoutStyle()
        layoutTxt:SetTextColor(T.accent[1], T.accent[2], T.accent[3], 1)
        GameTooltip:Hide()
    end)
    layoutBtn:SetScript("OnClick", function()
        if TomoMod_Movers and TomoMod_Movers.Toggle then TomoMod_Movers.Toggle() end
        UpdateLayoutStyle()
    end)

    -- Multi-step help, matching the dedicated Studios' discoverability without
    -- forcing an onboarding popup every time the main options are opened.
    local helpBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    helpBtn:SetSize(78, 26)
    helpBtn:SetPoint("RIGHT", layoutBtn, "LEFT", -6, 0)
    helpBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    helpBtn:SetBackdropColor(0.07, 0.07, 0.09, 0.8)
    helpBtn:SetBackdropBorderColor(0.20, 0.20, 0.25, 0.8)
    local helpTxt = helpBtn:CreateFontString(nil, "OVERLAY")
    helpTxt:SetFont(FONT, 11, "")
    helpTxt:SetPoint("CENTER")
    helpTxt:SetText(L["cfg_help_button"] or "? Help")
    helpTxt:SetTextColor(0.78, 0.80, 0.84, 1)
    helpBtn:SetScript("OnEnter", function()
        helpBtn:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 1)
        helpTxt:SetTextColor(T.accent[1], T.accent[2], T.accent[3], 1)
    end)
    helpBtn:SetScript("OnLeave", function()
        helpBtn:SetBackdropBorderColor(0.20, 0.20, 0.25, 0.8)
        helpTxt:SetTextColor(0.78, 0.80, 0.84, 1)
    end)
    helpBtn:SetScript("OnClick", OpenOptionsHelp)

    -- ==============================================================
    -- SIDEBAR
    -- ==============================================================
    local sidebar = CreateFrame("Frame", nil, configFrame)
    sidebar:SetPoint("TOPLEFT",    0, -TITLE_H)
    sidebar:SetPoint("BOTTOMLEFT", 0, FOOTER_H)
    sidebar:SetWidth(NAV_W)

    local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND")
    sidebarBg:SetAllPoints()
    sidebarBg:SetColorTexture(0.052, 0.052, 0.066, 1)

    local navSep = configFrame:CreateTexture(nil, "ARTWORK")
    navSep:SetWidth(1)
    navSep:SetPoint("TOPLEFT",    NAV_W, -TITLE_H)
    navSep:SetPoint("BOTTOMLEFT", NAV_W, FOOTER_H)
    navSep:SetColorTexture(0.14, 0.14, 0.17, 1)

    -- ── Barre de recherche ─────────────────────────────────────
    local WHITE8 = "Interface\\Buttons\\WHITE8x8"
    local aR, aG, aB = GetAccent()
    local SEARCH_H = 28

    local searchWrap = CreateFrame("Frame", nil, sidebar, "BackdropTemplate")
    searchWrap:SetPoint("TOPLEFT",  8, -8)
    searchWrap:SetPoint("TOPRIGHT", -8, -8)
    searchWrap:SetHeight(SEARCH_H)
    searchWrap:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    searchWrap:SetBackdropColor(0.09, 0.09, 0.115, 1)
    searchWrap:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

    local mag = searchWrap:CreateTexture(nil, "OVERLAY")
    mag:SetSize(14, 14); mag:SetPoint("LEFT", 7, 0)
    mag:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    mag:SetVertexColor(0.50, 0.50, 0.56, 1)

    local searchBox = CreateFrame("EditBox", nil, searchWrap)
    searchBox:SetPoint("LEFT", mag, "RIGHT", 4, 0)
    searchBox:SetPoint("RIGHT", -22, 0)
    searchBox:SetPoint("TOP", 0, 0)
    searchBox:SetPoint("BOTTOM", 0, 0)
    searchBox:SetFont(FONT, 12, "")
    searchBox:SetTextColor(0.88, 0.90, 0.89, 1)
    searchBox:SetAutoFocus(false)
    searchBox:SetTextInsets(0, 0, 0, 0)

    local placeholder = searchBox:CreateFontString(nil, "OVERLAY")
    placeholder:SetFont(FONT, 12, ""); placeholder:SetPoint("LEFT", 1, 0)
    placeholder:SetTextColor(T.textFaint[1], T.textFaint[2], T.textFaint[3], 1)
    placeholder:SetText(L["ui_search_placeholder"] or "Rechercher...")

    local clearBtn = CreateFrame("Button", nil, searchWrap)
    clearBtn:SetSize(18, 18); clearBtn:SetPoint("RIGHT", -3, 0); clearBtn:Hide()
    local clearTxt = clearBtn:CreateFontString(nil, "OVERLAY")
    clearTxt:SetFont(FONT_BOLD, 14, ""); clearTxt:SetPoint("CENTER", 0, 1); clearTxt:SetText("×")
    clearTxt:SetTextColor(0.45, 0.45, 0.50, 1)
    clearBtn:SetScript("OnEnter", function() clearTxt:SetTextColor(0.90, 0.30, 0.30, 1) end)
    clearBtn:SetScript("OnLeave", function() clearTxt:SetTextColor(0.45, 0.45, 0.50, 1) end)

    -- Exposed for Config/GlobalSearch.lua (results popup anchor + input)
    configFrame._searchWrap = searchWrap
    configFrame._searchBox  = searchBox

    -- ── Filtre par rôle ────────────────────────────────────────
    -- Dims settings that belong to other roles instead of hiding them,
    -- so a player never loses track of an option they already know.
    local ROLEBAR_H  = 24
    local ROLEBAR_Y  = 8 + SEARCH_H + 6

    local roleBar = CreateFrame("Frame", nil, sidebar)
    roleBar:SetPoint("TOPLEFT",  8, -ROLEBAR_Y)
    roleBar:SetPoint("TOPRIGHT", -8, -ROLEBAR_Y)
    roleBar:SetHeight(ROLEBAR_H)

    local ROLE_SLOTS = {
        { key = "ALL" },
        { key = "TANK" },
        { key = "HEALER" },
        { key = "DAMAGER" },
    }
    local RB_GAP = 2
    local RB_W   = math.floor((NAV_W - 16 - RB_GAP * (#ROLE_SLOTS - 1)) / #ROLE_SLOTS)

    local roleButtons = {}

    local function SetRoleButtonVisual(btn, active)
        local c = btn._roleColor
        if active then
            btn:SetBackdropColor(c[1] * 0.30, c[2] * 0.30, c[3] * 0.30, 0.95)
            btn:SetBackdropBorderColor(c[1], c[2], c[3], 0.95)
            if btn._icon then btn._icon:SetVertexColor(c[1], c[2], c[3], 1) end
            if btn._lbl  then btn._lbl:SetTextColor(c[1], c[2], c[3], 1) end
        else
            btn:SetBackdropColor(0.075, 0.075, 0.095, 1)
            btn:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)
            if btn._icon then btn._icon:SetVertexColor(0.42, 0.42, 0.48, 1) end
            if btn._lbl  then btn._lbl:SetTextColor(0.46, 0.46, 0.52, 1) end
        end
    end

    local function RefreshRoleButtons()
        local active = (W and W.GetRoleFilter and W.GetRoleFilter()) or "ALL"
        for _, btn in ipairs(roleButtons) do
            SetRoleButtonVisual(btn, btn._roleKey == active)
        end
    end
    C.RefreshRoleButtons = RefreshRoleButtons

    for i, slot in ipairs(ROLE_SLOTS) do
        local info = (slot.key ~= "ALL") and W.ROLE_INFO and W.ROLE_INFO[slot.key] or nil

        local btn = CreateFrame("Button", nil, roleBar, "BackdropTemplate")
        btn:SetSize(RB_W, ROLEBAR_H)
        btn:SetPoint("TOPLEFT", (i - 1) * (RB_W + RB_GAP), 0)
        btn:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
        btn._roleKey   = slot.key
        btn._roleColor = info and info.color or { aR, aG, aB }

        if info then
            local ico = btn:CreateTexture(nil, "OVERLAY")
            ico:SetSize(14, 14)
            ico:SetPoint("CENTER")
            ico:SetTexture(info.icon)
            btn._icon = ico
            btn._roleName = (W.Loc and W.Loc(info.lk, slot.key)) or slot.key
        else
            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT, 10, "")
            lbl:SetPoint("CENTER")
            lbl:SetText((W.Loc and W.Loc("cfg_rolefilter_all", "Tous")) or "Tous")
            btn._lbl = lbl
        end

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText((W.Loc and W.Loc("cfg_rolefilter_label", "Focus rôle")) or "Focus rôle", 1, 1, 1)
            if self._roleName then
                GameTooltip:AddLine(
                    string.format((W.Loc and W.Loc("cfg_rolefilter_tip", "%s")) or "%s", self._roleName),
                    0.72, 0.72, 0.78, true)
            else
                GameTooltip:AddLine(
                    (W.Loc and W.Loc("cfg_rolefilter_tip_all", "")) or "", 0.72, 0.72, 0.78, true)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function(self)
            if W and W.SetRoleFilter then W.SetRoleFilter(self._roleKey) end
            local gdb = GuiDB()
            gdb.roleFilter = (self._roleKey ~= "ALL") and self._roleKey or nil
            RefreshRoleButtons()
        end)

        roleButtons[#roleButtons + 1] = btn
    end

    -- Restore the saved focus before any page is built.
    if W and W.SetRoleFilter then W.SetRoleFilter(GuiDB().roleFilter or "ALL") end
    RefreshRoleButtons()

    -- ── Zone de navigation défilante ───────────────────────────
    local NAV_TOP    = ROLEBAR_Y + ROLEBAR_H + 8
    local NAV_BOTTOM = 26
    local navScroll = CreateFrame("ScrollFrame", nil, sidebar)
    navScroll:SetPoint("TOPLEFT", 0, -NAV_TOP)
    navScroll:SetPoint("BOTTOMRIGHT", 0, NAV_BOTTOM)

    local navChild = CreateFrame("Frame", nil, navScroll)
    navChild:SetWidth(NAV_W); navChild:SetHeight(1)
    navScroll:SetScrollChild(navChild)

    local navThumb = navScroll:CreateTexture(nil, "OVERLAY")
    navThumb:SetWidth(3); navThumb:SetColorTexture(aR, aG, aB, 0.5); navThumb:Hide()

    local function UpdateNavThumb()
        local sh = navScroll:GetHeight() or 0
        local ch = navChild:GetHeight() or 0
        local maxS = ch - sh
        if maxS <= 1 then navThumb:Hide(); return end
        navThumb:Show()
        local ratio = sh / ch
        local th    = math.max(20, math.floor(sh * ratio))
        local cur   = navScroll:GetVerticalScroll()
        local ty    = (cur / maxS) * (sh - th)
        navThumb:ClearAllPoints()
        navThumb:SetHeight(th)
        navThumb:SetPoint("TOPRIGHT", navScroll, "TOPRIGHT", -2, -ty)
    end

    navScroll:EnableMouseWheel(true)
    navScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * 40, max)))
        UpdateNavThumb()
    end)
    navScroll:SetScript("OnShow", function() C_Timer.After(0, UpdateNavThumb) end)

    -- Boutons de nav (dans le child défilant).
    for _, cat in ipairs(categories) do
        local btn = CreateNavButton(navChild, cat, 0)
        categoryButtons[cat.key] = btn
        btn._cat = cat
    end

    local function InterfaceSubActive(item) return currentInterfacePage == item.key end
    local function InterfaceSubClick(item) C.SwitchCategory(item.key) end
    for _, item in ipairs(INTERFACE_WORKSPACE_ITEMS) do
        interfaceSubButtons[item.key] = CreateSubNavButton(navChild, item, "interface",
            InterfaceSubActive, InterfaceSubClick)
        interfaceSubButtons[item.key]:Hide()
    end

    local function ComfortGroupActive(group)
        return COMFORT_PAGE_TO_GROUP[currentComfortPage] == group.key
    end
    local function ComfortGroupClick(group)
        C.OpenComfortPage(comfortLastPageByGroup[group.key] or group.default)
    end
    for _, group in ipairs(COMFORT_WORKSPACE_GROUPS) do
        comfortSubButtons[group.key] = CreateSubNavButton(navChild, group, "comfort",
            ComfortGroupActive, ComfortGroupClick)
        comfortSubButtons[group.key]:Hide()
    end

    -- Studios block: section label, one entry per Studio, then a hairline
    -- before the utility categories (What's New, Profiles, Diagnostics).
    local STUDIO_HEAD_H, STUDIO_SEP_H = 26, 9
    local studioHead = navChild:CreateFontString(nil, "OVERLAY")
    studioHead:SetFont(FONT_BOLD, 9, "")
    studioHead:SetTextColor(0.56, 0.58, 0.64, 1)
    studioHead:SetText(LT("nav_studios_header", "STUDIOS"))
    studioHead:Hide()
    local studioSep = navChild:CreateTexture(nil, "ARTWORK")
    studioSep:SetHeight(1)
    studioSep:SetColorTexture(1, 1, 1, 0.06)
    studioSep:Hide()
    for _, def in ipairs(STUDIOS) do
        local btn = CreateStudioNavButton(navChild, def)
        btn._def = def
        btn:Hide()
        studioButtons[#studioButtons + 1] = btn
    end

    -- Sub-items drawn under each category while it is open.
    local SUB_ITEMS = {
        interface = { list = INTERFACE_WORKSPACE_ITEMS, buttons = interfaceSubButtons },
        comfort   = { list = COMFORT_WORKSPACE_GROUPS,  buttons = comfortSubButtons },
    }

    -- Every category stays visible at all times: the open one unfolds its
    -- sub-items in place, so nothing disappears from the menu and the
    -- player never has to go back through Home to reach a sibling. While a
    -- search is typed, matching sub-items show under their category even
    -- when it is closed.
    local lastFilter
    local function RelayoutNav(filter)
        filter = (filter or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        local yy = -4

        for _, btn in pairs(categoryButtons) do btn:Hide() end
        for _, btn in pairs(interfaceSubButtons) do btn:Hide() end
        for _, btn in pairs(comfortSubButtons) do btn:Hide() end
        for _, btn in ipairs(studioButtons) do btn:Hide() end
        studioHead:Hide(); studioSep:Hide()

        local function Match(label, key, kw)
            if filter == "" then return true end
            local hay = ((label or "") .. " " .. (key or "") .. " " .. (kw or "")):lower()
            return hay:find(filter, 1, true) ~= nil
        end

        local function Place(region, height, x)
            region:ClearAllPoints()
            region:SetPoint("TOPLEFT", navChild, "TOPLEFT", x or 0, yy)
            region:Show()
            yy = yy - height
        end

        local function SubMatches(item)
            if Match(item.label, item.key, item.kw) then return true end
            for _, page in ipairs(item.pages or {}) do
                if Match(page.label, page.key, page.kw) then return true end
            end
            return item.direct and Match(item.label, item.default, item.kw) or false
        end

        local function PlaceStudios()
            local visible = {}
            for _, btn in ipairs(studioButtons) do
                local def = btn._def
                if Match(def.label, def.key, def.kw .. " " .. LT(def.title, def.titleFallback)) then
                    visible[#visible + 1] = btn
                end
            end
            if #visible == 0 then return end
            yy = yy - 4
            Place(studioHead, STUDIO_HEAD_H - 4, 18)
            for _, btn in ipairs(visible) do Place(btn, SUB_BTN_H + 2) end
            yy = yy - 4
            studioSep:ClearAllPoints()
            studioSep:SetPoint("TOPLEFT", navChild, "TOPLEFT", 12, yy)
            studioSep:SetPoint("TOPRIGHT", navChild, "TOPRIGHT", -12, yy)
            studioSep:Show()
            yy = yy - (STUDIO_SEP_H - 4)
        end

        for _, cat in ipairs(categories) do
            local btn = categoryButtons[cat.key]
            local sub = SUB_ITEMS[cat.key]
            local subsToShow = {}
            if sub then
                local open = (currentCategory == cat.key)
                for _, item in ipairs(sub.list) do
                    local b = sub.buttons[item.key]
                    if b and ((filter == "" and open) or (filter ~= "" and SubMatches(item))) then
                        subsToShow[#subsToShow + 1] = b
                    end
                end
            end
            if btn and (Match(cat.label, cat.key, cat.kw) or #subsToShow > 0) then
                Place(btn, NAV_BTN_H)
                for _, b in ipairs(subsToShow) do Place(b, SUB_BTN_H) end
            end
            if cat.key == "damagemeter" then PlaceStudios() end
        end

        navChild:SetHeight(math.max(math.abs(yy) + 8, 1))
        -- Only a new search starts again from the top; a click on an item
        -- low in the list must not throw the menu back up.
        if filter ~= lastFilter then
            navScroll:SetVerticalScroll(0)
        else
            local maxS = math.max(0, (navChild:GetHeight() or 0) - (navScroll:GetHeight() or 0))
            if navScroll:GetVerticalScroll() > maxS then navScroll:SetVerticalScroll(maxS) end
        end
        lastFilter = filter
        UpdateNavThumb()
    end
    C.RelayoutNav = RelayoutNav
    C.RefreshWorkspaceNav = function()
        for key, btn in pairs(interfaceSubButtons) do
            btn.SetActive(currentCategory == "interface" and currentInterfacePage == key)
        end
        for key, btn in pairs(comfortSubButtons) do
            btn.SetActive(currentCategory == "comfort" and COMFORT_PAGE_TO_GROUP[currentComfortPage] == key)
        end
        RelayoutNav(searchBox:GetText() or "")
    end

    searchBox:SetScript("OnTextChanged", function(self)
        local txt = self:GetText() or ""
        placeholder:SetShown(txt == "")
        clearBtn:SetShown(txt ~= "")
        RelayoutNav(txt)
        if C.NotifySearchText then C.NotifySearchText(txt) end
    end)
    searchBox:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    searchBox:SetScript("OnEnterPressed",  function(self)
        if C.SubmitSearch and C.SubmitSearch() then return end
        self:ClearFocus()
    end)
    searchBox:SetScript("OnEditFocusGained", function() searchWrap:SetBackdropBorderColor(aR, aG, aB, 0.70) end)
    searchBox:SetScript("OnEditFocusLost",   function() searchWrap:SetBackdropBorderColor(0.18, 0.18, 0.22, 1) end)
    clearBtn:SetScript("OnClick", function() searchBox:SetText(""); searchBox:ClearFocus() end)

    RelayoutNav("")

    -- Branding at bottom of sidebar
    local brandTxt = sidebar:CreateFontString(nil, "OVERLAY")
    brandTxt:SetFont(FONT, 9, "")
    brandTxt:SetPoint("BOTTOM", 0, 11)
    brandTxt:SetTextColor(0.36, 0.36, 0.42, 1)
    brandTxt:SetText("TomoMod · TomoAniki")

    -- ==============================================================
    -- CONTENT AREA
    -- ==============================================================
    local content = CreateFrame("Frame", nil, configFrame)
    content:SetPoint("TOPLEFT",     NAV_W + 1, -TITLE_H)
    content:SetPoint("BOTTOMRIGHT", 0,          FOOTER_H)
    configFrame.content = content

    -- Stable targets used by the multi-step help overlay.  They are references
    -- to the shell, not to lazily rebuilt option panels, so the guide survives
    -- category switches, profile refreshes and NO_CACHE pages.
    configFrame._helpTargets = {
        title   = titleBar,
        sidebar = sidebar,
        search  = searchWrap,
        role    = roleBar,
        content = content,
        layout  = layoutBtn,
    }

    local contentShield = content:CreateTexture(nil, "BACKGROUND", nil, -8)
    contentShield:SetAllPoints()
    contentShield:SetColorTexture(0.032, 0.032, 0.048, 0.985)

    -- ==============================================================
    -- FOOTER
    -- ==============================================================
    local footer = CreateFrame("Frame", nil, configFrame)
    footer:SetPoint("BOTTOMLEFT")
    footer:SetPoint("BOTTOMRIGHT")
    footer:SetHeight(FOOTER_H)

    local footerBg = footer:CreateTexture(nil, "BACKGROUND")
    footerBg:SetAllPoints()
    footerBg:SetColorTexture(0.04, 0.04, 0.055, 1)

    local footerLine = footer:CreateTexture(nil, "ARTWORK")
    footerLine:SetHeight(1)
    footerLine:SetPoint("TOPLEFT")
    footerLine:SetPoint("TOPRIGHT")
    footerLine:SetColorTexture(0.14, 0.14, 0.17, 1)

    local hintTxt = footer:CreateFontString(nil, "OVERLAY")
    hintTxt:SetFont(FONT, 10, "")
    hintTxt:SetPoint("LEFT", NAV_W + 14, 0)
    hintTxt:SetTextColor(T.textFaint[1], T.textFaint[2], T.textFaint[3], 1)
    hintTxt:SetText(L["ui_footer_hint"])

    local perfLabel = footer:CreateFontString(nil, "OVERLAY")
    perfLabel:SetFont(FONT, 10, "")
    perfLabel:SetPoint("RIGHT", -26, 0)
    perfLabel:SetTextColor(T.textFaint[1], T.textFaint[2], T.textFaint[3], 1)
    configFrame._perfLabel = perfLabel

    -- ==============================================================
    -- RESIZE GRIP (bottom-right)
    -- ==============================================================
    local grip = CreateFrame("Button", nil, configFrame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -3, 3)
    grip:SetFrameLevel(configFrame:GetFrameLevel() + 20)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    local gripTex = grip:GetNormalTexture()
    if gripTex then gripTex:SetVertexColor(0.45, 0.45, 0.52, 1) end
    grip:SetScript("OnMouseDown", function(_, btn)
        if btn == "LeftButton" then configFrame:StartSizing("BOTTOMRIGHT") end
    end)
    grip:SetScript("OnMouseUp", function()
        configFrame:StopMovingOrSizing()
        local db = GuiDB()
        db.width  = math.floor((configFrame:GetWidth()  or PANEL_W) + 0.5)
        db.height = math.floor((configFrame:GetHeight() or PANEL_H) + 0.5)
    end)
end

-- =====================================================================
-- SWITCH CATEGORY
-- =====================================================================
function C.SwitchCategory(key)
    if W and W.CloseDropdowns then W.CloseDropdowns() end

    -- Settings that moved into a Studio: open it instead of a page.
    local studio = STUDIO_ALIASES[key]
    if studio then
        C.OpenStudio(studio.studio, studio.arg)
        return
    end

    local alias = categoryAliases[key]
    if alias then
        C._pendingGroupTab = alias.tab
        key = alias.key
    end

    -- An unknown key (stale bookmark, removed page) lands on Home rather
    -- than on an empty content area.
    if not GetCategory(key) then
        C._pendingGroupTab = nil
        key = "accueil"
    end

    local catMeta = GetCategory(key)
    if W and W.SetPanelContext then W.SetPanelContext(catMeta) end
    if W and W.SetBuildContext then W.SetBuildContext(key, catMeta and catMeta.label or key) end
    local cr, cg, cb = CategoryAccent(catMeta)

    if configFrame then
        if configFrame._contextTitle then
            configFrame._contextTitle:SetText(catMeta and catMeta.label or "")
            configFrame._contextTitle:SetTextColor(cr, cg, cb, 1)
        end
        if configFrame._contextDesc then
            configFrame._contextDesc:SetText(catMeta and catMeta.desc or "")
        end
        if configFrame._titleLine then
            configFrame._titleLine:SetColorTexture(cr, cg, cb, 0.35)
        end
        if configFrame._headerGlow then
            if configFrame._headerGlow.SetGradientAlpha then
                configFrame._headerGlow:SetGradientAlpha("VERTICAL", cr * 0.12, cg * 0.12, cb * 0.12, 0.40, 0, 0, 0, 0)
            else
                configFrame._headerGlow:SetColorTexture(cr * 0.12, cg * 0.12, cb * 0.12, 0.25)
            end
        end
    end

    -- [Lot C] Hide the current page instead of destroying it. Cached
    -- pages are re-shown as-is; NO_CACHE ones are parked and rebuilt.
    if activeCategoryPanel and activeCategoryPanel.Hide then
        activeCategoryPanel:Hide()
    end
    activeCategoryPanel = nil

    for catKey, btn in pairs(categoryButtons) do
        btn.SetActive(catKey == key)
    end

    local cached = (not NO_CACHE[key]) and categoryPanels[key] or nil
    if cached and cached.root then
        activeCategoryPanel = cached.root
        SwitchPendingTab(cached.tabPanel)
    else
        if categoryPanels[key] and categoryPanels[key].root then
            ParkPanel(categoryPanels[key].root)
            categoryPanels[key] = nil
        end

        local builderMap = {
            interface = function(p) return BuildInterfaceWorkspacePanel(p) end,
            roles     = function(p) return BuildGroupedFromTree(p, "roles") end,
            comfort   = function(p) return BuildComfortWorkspacePanel(p) end,
        }
        local builder = builderMap[key] or SINGLE_PAGES[key]
        if type(builder) == "string" then builder = _G[builder] end
        if builder then
            local bodyParent, shell = CreatePageShell(configFrame.content, catMeta)
            local panel = builder(bodyParent)
            if panel then
                if W and W.ApplyPanelContext then W.ApplyPanelContext(panel, catMeta) end
                panel:SetAllPoints(bodyParent)
                activeCategoryPanel = shell or panel
                categoryPanels[key] = { root = activeCategoryPanel, tabPanel = panel }
            end
            -- Single pages do not go through BuildGroupedPanel, so the
            -- pending deep-link tab is honoured (and cleared) here: some
            -- of them own an inner tab bar (Profiles), others none.
            SwitchPendingTab(panel)
        end
    end

    if activeCategoryPanel then activeCategoryPanel:Show() end

    -- [Lot A] Pages are built lazily and cached: a freshly built page has
    -- just registered its tagged sections, so the filter is re-applied here.
    if W and W.ApplyRoleFilter then W.ApplyRoleFilter() end

    currentCategory = key
    if C.RefreshWorkspaceNav then C.RefreshWorkspaceNav() end
end

-- =====================================================================
-- PUBLIC API
-- =====================================================================
function C.Toggle()
    if not TomoModDB then
        print("|cffff0000TomoMod|r " .. (L["msg_db_not_init"] or "DB not initialized"))
        return
    end
    if not configFrame then CreateConfigFrame() end
    if configFrame:IsShown() then
        configFrame:Hide()
    else
        configFrame:Show()
        if not currentCategory then C.SwitchCategory("accueil") end
    end
end

function C.Show()
    if not configFrame then C.Toggle()
    elseif not configFrame:IsShown() then
        configFrame:Show()
        if not currentCategory then C.SwitchCategory("accueil") end
    end
end

function C.Hide()
    if configFrame and configFrame:IsShown() then configFrame:Hide() end
end

function C.OpenCategory(key)
    C.Show()
    if key then C.SwitchCategory(key) end
end

function C.ApplyGUIScale()
    if not configFrame then return end
    configFrame:SetScale(GuiDB().scale or 1)
    FitToScreen()
end

function C.ResetGUISize()
    local db = GuiDB()
    db.width, db.height, db.scale = nil, nil, nil
    if configFrame then
        configFrame:SetSize(PANEL_W, PANEL_H)
        configFrame:SetScale(1)
        FitToScreen()
        configFrame:ClearAllPoints()
        configFrame:SetPoint("CENTER")
    end
end

-- [Lot C] Drops every cached page (presets / profile swaps rewrite the DB
-- outside the panels, so cached widget values would be stale). The rebuild
-- of the open page is deferred one frame so any running click handler of
-- the old page finishes safely first.
-- Drops one cached page so the next SwitchCategory rebuilds it. Deep-links
-- need this: a cached page is re-shown without rebuilding, so no tab bar is
-- created and a pending tab path would never be read.
function C.InvalidateCategory(key)
    local cached = key and categoryPanels[key]
    if not cached then return end
    if cached.root then
        if activeCategoryPanel == cached.root then activeCategoryPanel = nil end
        ParkPanel(cached.root)
    end
    categoryPanels[key] = nil
end

function C.InvalidatePanels()
    ClearContentArea()
    if configFrame and configFrame:IsShown() and currentCategory then
        local key = currentCategory
        C_Timer.After(0, function()
            if configFrame and configFrame:IsShown() and currentCategory == key then
                C.SwitchCategory(key)
            end
        end)
    end
end

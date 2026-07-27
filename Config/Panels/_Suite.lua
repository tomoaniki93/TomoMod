-- =====================================================================
-- Panels/_Suite.lua — carte « Suite Tomo », partagée entre panneaux
-- =====================================================================
--
-- Une seule implémentation, appelée depuis le panneau Mythique+ et depuis
-- l'Accueil. Deux copies dériveraient : l'une gagnerait un correctif que
-- l'autre n'aurait pas, et le comportement diffèrerait selon la page.
--
-- Principes de conduite, volontairement stricts :
--   * on ne propose JAMAIS un addon déjà installé — on affiche un raccourci ;
--   * un refus est définitif et vaut pour tous les panneaux (drapeau unique) ;
--   * aucune adresse cliquable : un addon ne peut pas ouvrir de navigateur,
--     seule une zone de texte sélectionnable est utile ;
--   * aucun message au login, aucune popup, rien de répété.

local W = TomoMod_Widgets

TomoMod_Suite = TomoMod_Suite or {}
local S = TomoMod_Suite

S.TOMOBOSS_URL = "https://www.curseforge.com/wow/addons/tomoboss"

if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["suite_card_title"]   = "Tomo suite",
        ["suite_tb_desc"]      = "TomoBoss — boss timers with spoken callouts, French and English voice packs included.",
        ["suite_tb_short"]     = "TomoBoss — boss timers with spoken callouts.",
        ["suite_tb_installed"] = "TomoBoss is installed. Type /tmb to configure it.",
        ["suite_tb_disabled"]  = "TomoBoss is installed but disabled for this character. Enable it from the addon list, then reload.",
        ["suite_tb_get"]       = "Not installed. Copy the address below (Ctrl+C) to open it in your browser.",
        ["suite_tb_url_label"] = "Address",
        ["suite_tb_open"]      = "Open TomoBoss options",
        ["suite_tb_hide"]      = "Don't show again",
    })
    TomoMod_RegisterLocale("frFR", {
        ["suite_card_title"]   = "Suite Tomo",
        ["suite_tb_desc"]      = "TomoBoss — minuteurs de boss avec annonces vocales, packs français et anglais inclus.",
        ["suite_tb_short"]     = "TomoBoss — minuteurs de boss avec annonces vocales.",
        ["suite_tb_installed"] = "TomoBoss est installé. Tapez /tmb pour le configurer.",
        ["suite_tb_disabled"]  = "TomoBoss est installé mais désactivé pour ce personnage. Activez-le dans la liste des addons, puis rechargez.",
        ["suite_tb_get"]       = "Non installé. Copiez l'adresse ci-dessous (Ctrl+C) pour l'ouvrir dans votre navigateur.",
        ["suite_tb_url_label"] = "Adresse",
        ["suite_tb_open"]      = "Ouvrir les options TomoBoss",
        ["suite_tb_hide"]      = "Ne plus afficher",
    })
    TomoMod_RegisterLocale("deDE", {
        ["suite_card_title"]   = "Tomo-Suite",
        ["suite_tb_desc"]      = "TomoBoss — Boss-Timer mit gesprochenen Ansagen, französische und englische Sprachpakete inklusive.",
        ["suite_tb_short"]     = "TomoBoss — Boss-Timer mit gesprochenen Ansagen.",
        ["suite_tb_installed"] = "TomoBoss ist installiert. Tippe /tmb, um es zu konfigurieren.",
        ["suite_tb_disabled"]  = "TomoBoss ist installiert, aber für diesen Charakter deaktiviert. Aktiviere es in der Addon-Liste und lade das Spiel neu.",
        ["suite_tb_get"]       = "Nicht installiert. Kopiere die Adresse unten (Strg+C), um sie im Browser zu öffnen.",
        ["suite_tb_url_label"] = "Adresse",
        ["suite_tb_open"]      = "TomoBoss-Optionen öffnen",
        ["suite_tb_hide"]      = "Nicht mehr anzeigen",
    })
    TomoMod_RegisterLocale("esES", {
        ["suite_card_title"]   = "Suite Tomo",
        ["suite_tb_desc"]      = "TomoBoss — temporizadores de jefes con avisos hablados, packs de voz en francés e inglés incluidos.",
        ["suite_tb_short"]     = "TomoBoss — temporizadores de jefes con avisos hablados.",
        ["suite_tb_installed"] = "TomoBoss está instalado. Escribe /tmb para configurarlo.",
        ["suite_tb_disabled"]  = "TomoBoss está instalado pero desactivado para este personaje. Actívalo desde la lista de addons y recarga.",
        ["suite_tb_get"]       = "No instalado. Copia la dirección de abajo (Ctrl+C) para abrirla en tu navegador.",
        ["suite_tb_url_label"] = "Dirección",
        ["suite_tb_open"]      = "Abrir las opciones de TomoBoss",
        ["suite_tb_hide"]      = "No volver a mostrar",
    })
    TomoMod_RegisterLocale("itIT", {
        ["suite_card_title"]   = "Suite Tomo",
        ["suite_tb_desc"]      = "TomoBoss — timer dei boss con annunci vocali, pacchetti voce francese e inglese inclusi.",
        ["suite_tb_short"]     = "TomoBoss — timer dei boss con annunci vocali.",
        ["suite_tb_installed"] = "TomoBoss è installato. Digita /tmb per configurarlo.",
        ["suite_tb_disabled"]  = "TomoBoss è installato ma disattivato per questo personaggio. Attivalo dalla lista degli addon e ricarica.",
        ["suite_tb_get"]       = "Non installato. Copia l'indirizzo qui sotto (Ctrl+C) per aprirlo nel browser.",
        ["suite_tb_url_label"] = "Indirizzo",
        ["suite_tb_open"]      = "Apri le opzioni di TomoBoss",
        ["suite_tb_hide"]      = "Non mostrare più",
    })
    TomoMod_RegisterLocale("ptBR", {
        ["suite_card_title"]   = "Suíte Tomo",
        ["suite_tb_desc"]      = "TomoBoss — temporizadores de chefes com avisos falados, pacotes de voz em francês e inglês incluídos.",
        ["suite_tb_short"]     = "TomoBoss — temporizadores de chefes com avisos falados.",
        ["suite_tb_installed"] = "O TomoBoss está instalado. Digite /tmb para configurá-lo.",
        ["suite_tb_disabled"]  = "TomoBoss está instalado mas desativado para este personagem. Ative-o na lista de addons e recarregue.",
        ["suite_tb_get"]       = "Não instalado. Copie o endereço abaixo (Ctrl+C) para abri-lo no navegador.",
        ["suite_tb_url_label"] = "Endereço",
        ["suite_tb_open"]      = "Abrir as opções do TomoBoss",
        ["suite_tb_hide"]      = "Não mostrar novamente",
    })
end

local function Loc(key, fallback)
    local L = TomoMod_L
    local v = L and L[key]
    if v and v ~= key then return v end
    return fallback or key
end

-- État RÉEL de l'addon, en trois valeurs.
--
-- Tester la seule présence via GetAddOnInfo était faux : les addons vivent dans
-- Interface/AddOns, partagé par toute l'installation, alors que l'activation
-- est PAR PERSONNAGE. Sur un personnage où TomoBoss est désactivé, il reste
-- donc présent sur le disque et GetAddOnInfo répond « connu » — la carte
-- annonçait « installé, tapez /tmb » alors que la commande n'existe pas.
--
--   "loaded"   chargé, utilisable tout de suite
--   "disabled" présent mais non chargé pour ce personnage
--   "absent"   pas installé
function S.State(name)
    local C = C_AddOns
    if not C then return "absent" end

    if C.IsAddOnLoaded then
        local ok, loaded = pcall(C.IsAddOnLoaded, name)
        if ok and loaded then return "loaded" end
    end
    if C.GetAddOnInfo then
        local ok, found = pcall(C.GetAddOnInfo, name)
        if ok and found ~= nil then return "disabled" end
    end
    return "absent"
end

function S.IsInstalled(name)
    return S.State(name) ~= "absent"
end

function S.Hidden()
    TomoModDB = TomoModDB or {}
    TomoModDB.Suite = TomoModDB.Suite or {}
    return TomoModDB.Suite.hideTomoBoss == true
end

-- Faut-il dessiner la carte ? Installé => oui (raccourci utile).
-- Non installé et masqué => non.
function S.ShouldShow()
    return S.State("TomoBoss") ~= "absent" or not S.Hidden()
end

-- Dessine la carte dans le conteneur `c` à l'ordonnée `y`, rend la nouvelle
-- ordonnée. `compact` allège le contenu pour le tableau de bord, qui est une
-- vue de synthèse et non une page de détail.
function S.CreateCard(c, y, compact)
    if not S.ShouldShow() then return y end

    local state = S.State("TomoBoss")
    local installed = (state == "loaded")
    local card, cy = W.CreateCard(c, Loc("suite_card_title", "Suite Tomo"), y)

    -- La description est un ARGUMENT : elle ne s'adresse qu'à quelqu'un qui n'a
    -- pas encore l'addon. L'afficher au-dessus de « TomoBoss est installé »
    -- donnait deux lignes commençant toutes deux par « TomoBoss », dont la
    -- première ne servait à rien. En état installé, la carte se réduit donc à
    -- son utilité réelle : rappeler la commande et offrir le raccourci.
    if not installed then
        local _, ny = W.CreateInfoText(card.inner,
            compact and Loc("suite_tb_short") or Loc("suite_tb_desc"), cy)
        cy = ny
    end

    if state == "disabled" then
        -- Ni bouton ni adresse : l'addon est là, la commande n'existe pas
        -- encore, et proposer un lien de téléchargement serait absurde.
        local _, y2 = W.CreateInfoText(card.inner, Loc("suite_tb_disabled"), cy)
        return W.FinalizeCard(card, y2)
    end

    if installed then
        local _, y2 = W.CreateInfoText(card.inner, Loc("suite_tb_installed"), cy)
        cy = y2
        local _, y3 = W.CreateButton(card.inner, Loc("suite_tb_open"), 200, cy, function()
            if SlashCmdList and SlashCmdList["TOMOBOSS"] then
                SlashCmdList["TOMOBOSS"]("")
            end
        end)
        cy = y3
    else
        local _, y2 = W.CreateInfoText(card.inner, Loc("suite_tb_get"), cy)
        cy = y2
        local box, y3 = W.CreateMultiLineEditBox(card.inner,
            Loc("suite_tb_url_label", "Adresse"), 22, cy, { readOnly = true })
        box.editBox:SetText(S.TOMOBOSS_URL)
        cy = y3
        local _, y4 = W.CreateButton(card.inner, Loc("suite_tb_hide"), 160, cy, function()
            TomoModDB.Suite = TomoModDB.Suite or {}
            TomoModDB.Suite.hideTomoBoss = true
            -- reconstruit le panneau courant : la carte disparaît partout
            if TomoMod_Config and TomoMod_Config.InvalidatePanels then
                TomoMod_Config.InvalidatePanels()
            end
        end)
        cy = y4
    end

    return W.FinalizeCard(card, cy)
end
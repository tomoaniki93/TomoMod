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
        ["suite_tb_get"]       = "Non installé. Copiez l'adresse ci-dessous (Ctrl+C) pour l'ouvrir dans votre navigateur.",
        ["suite_tb_url_label"] = "Adresse",
        ["suite_tb_open"]      = "Ouvrir les options TomoBoss",
        ["suite_tb_hide"]      = "Ne plus afficher",
    })
end

local function Loc(key, fallback)
    local L = TomoMod_L
    local v = L and L[key]
    if v and v ~= key then return v end
    return fallback or key
end

function S.IsInstalled(name)
    local api = C_AddOns and C_AddOns.GetAddOnInfo
    if not api then return false end
    local ok, found = pcall(api, name)
    return ok and found ~= nil
end

function S.Hidden()
    TomoModDB = TomoModDB or {}
    TomoModDB.Suite = TomoModDB.Suite or {}
    return TomoModDB.Suite.hideTomoBoss == true
end

-- Faut-il dessiner la carte ? Installé => oui (raccourci utile).
-- Non installé et masqué => non.
function S.ShouldShow()
    return S.IsInstalled("TomoBoss") or not S.Hidden()
end

-- Dessine la carte dans le conteneur `c` à l'ordonnée `y`, rend la nouvelle
-- ordonnée. `compact` allège le contenu pour le tableau de bord, qui est une
-- vue de synthèse et non une page de détail.
function S.CreateCard(c, y, compact)
    if not S.ShouldShow() then return y end

    local installed = S.IsInstalled("TomoBoss")
    local card, cy = W.CreateCard(c, Loc("suite_card_title", "Suite Tomo"), y)

    local _, ny = W.CreateInfoText(card.inner,
        compact and Loc("suite_tb_short") or Loc("suite_tb_desc"), cy)
    cy = ny

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
-- =====================================
-- Panels/Housing.lua — Housing module config panel
-- =====================================

local W = TomoMod_Widgets
local L = TomoMod_L

local DUPE_KEY_OPTIONS = {
    { text = CTRL_KEY_TEXT or "Ctrl", value = 1 },
    { text = ALT_KEY_TEXT  or "Alt",  value = 2 },
}

local function ApplyHousingRefresh()
    if TomoMod_Housing and TomoMod_Housing.Refresh then
        TomoMod_Housing.Refresh()
    end
end

function TomoMod_ConfigPanel_Housing(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB and TomoModDB.housing
    if not db then return scroll end

    local y = -12

    -- ═══════════════════════════════════════════════
    -- ACTIVATION GÉNÉRALE
    -- ═══════════════════════════════════════════════
    local card, cy = W.CreateCard(c, (L and L["section_housing_general"]) or "Housing — Général", y)

    local _, cy = W.CreateInfoText(card.inner,
        (L and L["info_housing_desc"]) or "Module Housing : améliore l'éditeur de maison et ajoute des raccourcis de téléportation. Nécessite l'extension Midnight / The War Within.",
        cy)

    local _, cy = W.CreateCheckbox(card.inner,
        (L and L["opt_housing_enable"]) or "Activer le module Housing",
        db.enabled, cy, function(v)
            db.enabled = v
            -- Disable every sub-handler at once if master is off
            if not v then
                if TomoMod_Housing and TomoMod_Housing.Handlers then
                    for _, h in pairs(TomoMod_Housing.Handlers) do
                        if h.SetEnabled then h:SetEnabled(false) end
                    end
                end
            else
                ApplyHousingRefresh()
            end
        end)

    y = W.FinalizeCard(card, cy)

    -- ═══════════════════════════════════════════════
    -- INFO DÉCOR (HOVER)
    -- ═══════════════════════════════════════════════
    local card2, cy = W.CreateCard(c, (L and L["section_housing_hover"]) or "Info décor (survol)", y)

    local _, cy = W.CreateInfoText(card2.inner,
        (L and L["info_housing_hover"]) or "En mode 'Décor de base', affiche le nom, le coût de placement et le stock restant du décor survolé. Permet aussi de dupliquer un décor avec une touche modificatrice.",
        cy)

    local _, cy = W.CreateCheckbox(card2.inner,
        (L and L["opt_housing_decorhover"]) or "Activer l'info décor",
        db.decorHover, cy, function(v)
            db.decorHover = v
            ApplyHousingRefresh()
        end)

    local _, cy = W.CreateCheckbox(card2.inner,
        (L and L["opt_housing_dupe"]) or "Activer la duplication rapide (modificateur)",
        db.decorHover_enableDupe, cy, function(v)
            db.decorHover_enableDupe = v
            if TomoMod_Housing and TomoMod_Housing.Handlers and TomoMod_Housing.Handlers.DecorHover then
                TomoMod_Housing.Handlers.DecorHover:LoadSettings()
            end
        end)

    local _, cy = W.CreateDropdown(card2.inner,
        (L and L["opt_housing_dupekey"]) or "Touche de duplication",
        DUPE_KEY_OPTIONS, db.decorHover_duplicateKey, cy, function(v)
            db.decorHover_duplicateKey = v
            if TomoMod_Housing and TomoMod_Housing.Handlers and TomoMod_Housing.Handlers.DecorHover then
                TomoMod_Housing.Handlers.DecorHover:LoadSettings()
            end
        end)

    y = W.FinalizeCard(card2, cy)

    -- ═══════════════════════════════════════════════
    -- HORLOGE DE L'ÉDITEUR
    -- ═══════════════════════════════════════════════
    local card3, cy = W.CreateCard(c, (L and L["section_housing_clock"]) or "Horloge de l'éditeur", y)

    local _, cy = W.CreateInfoText(card3.inner,
        (L and L["info_housing_clock"]) or "Affiche une horloge et comptabilise le temps passé dans l'éditeur de maison. Clic droit sur l'horloge pour basculer analogique / digital.",
        cy)

    local _, cy = W.CreateCheckbox(card3.inner,
        (L and L["opt_housing_clock"]) or "Activer l'horloge",
        db.clock, cy, function(v)
            db.clock = v
            ApplyHousingRefresh()
        end)

    local _, cy = W.CreateCheckbox(card3.inner,
        (L and L["opt_housing_clock_analog"]) or "Mode analogique (sinon digital)",
        db.clock_analog, cy, function(v)
            db.clock_analog = v
            if TomoMod_Housing and TomoMod_Housing.Handlers and TomoMod_Housing.Handlers.Clock then
                local clockFrame = TomoMod_Housing.Handlers.Clock.ClockFrame
                if clockFrame and clockFrame.Refresh then clockFrame:Refresh() end
            end
        end)

    y = W.FinalizeCard(card3, cy)

    -- ═══════════════════════════════════════════════
    -- TÉLÉPORTATION
    -- ═══════════════════════════════════════════════
    local card4, cy = W.CreateCard(c, (L and L["section_housing_teleport"]) or "Téléportation", y)

    local _, cy = W.CreateInfoText(card4.inner,
        (L and L["info_housing_teleport"]) or "Active la commande /tm home : téléporte vers votre maison ou la quitte automatiquement si vous êtes en visite.",
        cy)

    local _, cy = W.CreateCheckbox(card4.inner,
        (L and L["opt_housing_teleport"]) or "Activer la téléportation /tm home",
        db.teleport, cy, function(v)
            db.teleport = v
        end)

    local _, cy = W.CreateTwoColumnRow(card4.inner, cy,
        function(col)
            local _, ny = W.CreateButton(col,
                (L and L["btn_housing_tp_home"]) or "Téléporter (test)",
                180, 0, function()
                    if TomoMod_Housing and TomoMod_Housing.ShowTeleportPrompt then
                        TomoMod_Housing.ShowTeleportPrompt()
                    end
                end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateButton(col,
                (L and L["btn_housing_refresh"]) or "Rafraîchir les maisons",
                180, 0, function()
                    if TomoMod_Housing and TomoMod_Housing.API and TomoMod_Housing.API.RequestUpdateHouseInfo then
                        TomoMod_Housing.API.RequestUpdateHouseInfo()
                        print("|cff0cd29fTomoMod|r " .. ((L and L["msg_housing_refresh"]) or "Informations maisons demandées."))
                    end
                end)
            return ny
        end)

    y = W.FinalizeCard(card4, cy)

    -- ═══════════════════════════════════════════════
    -- COMMANDES DISPONIBLES
    -- ═══════════════════════════════════════════════
    local card5, cy = W.CreateCard(c, (L and L["section_housing_commands"]) or "Commandes", y)

    local _, cy = W.CreateInfoText(card5.inner,
        (L and L["info_housing_commands"]) or "• /tm home — téléporter vers votre maison (ou la quitter)\n• /tm housing — ouvre ce panneau\n• Clic droit sur l'horloge — bascule analogique/digital",
        cy)

    y = W.FinalizeCard(card5, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end
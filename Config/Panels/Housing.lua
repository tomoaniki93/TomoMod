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
        (L and L["info_housing_desc"]) or "Module Housing : améliore l'éditeur de maison.",
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

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end
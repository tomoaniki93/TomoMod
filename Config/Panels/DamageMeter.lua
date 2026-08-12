-- Panels/DamageMeter.lua
--
-- Lot 1 bridge panel. The damage meter still owns its own settings window;
-- this page states where it lives and opens it, rather than presenting a
-- half-ported set of options that would disagree with the real ones.
-- Lot 2 replaces this with the settings themselves.

local W = TomoMod_Widgets
local L = TomoMod_L

local function LT(key, fallback)
    local v = L and L[key]
    if v == nil or v == key then return fallback end
    return v
end

-- The meter lives in TomoMod's addon-private namespace, which is not
-- reachable from here. Its own window exposes the entry point globally.
local function Meter()
    return _G.TomoMod_DamageMeterBridge
end

function TomoMod_ConfigPanel_DamageMeter(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -12

    local card, cy = W.CreateCard(c, LT("dm_cfg_title", "Damage Meter"), y)

    local bridge = Meter()
    local standalone = C_AddOns and C_AddOns.IsAddOnLoaded
        and C_AddOns.IsAddOnLoaded("TomoDamageMeter")

    if standalone then
        -- Not an error: the guard hands over to the standalone addon on
        -- purpose. Say so plainly instead of showing dead buttons.
        local _, ny = W.CreateInfoText(card.inner, LT("dm_cfg_standalone",
            "L'addon TomoDamageMeter autonome est installe : c'est lui qui "
            .. "gere le compteur. Le module integre reste en veille pour "
            .. "eviter deux fenetres concurrentes."), cy)
        cy = ny
    elseif not bridge then
        local _, ny = W.CreateInfoText(card.inner, LT("dm_cfg_unavailable",
            "Le compteur de degats de Blizzard n'est pas disponible sur ce "
            .. "client, le module est inactif."), cy)
        cy = ny
    else
        local _, ny = W.CreateInfoText(card.inner, LT("dm_cfg_intro",
            "Le compteur conserve pour l'instant sa propre fenetre de "
            .. "reglages. Elle sera integree ici prochainement."), cy)
        cy = ny

        local _, ny2 = W.CreateButton(card.inner, LT("dm_cfg_open",
            "Ouvrir les reglages du damage meter"), 280, cy, function()
                if bridge.ToggleSettings then bridge.ToggleSettings() end
            end)
        cy = ny2

        local _, ny3 = W.CreateButton(card.inner, LT("dm_cfg_toggle",
            "Afficher / masquer les fenetres"), 280, cy, function()
                if bridge.ToggleWindows then bridge.ToggleWindows() end
            end)
        cy = ny3
    end

    y = W.FinalizeCard(card, cy)

    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

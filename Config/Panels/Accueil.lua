-- =====================================================================
-- Panels/Accueil.lua — Tableau de bord (TomoMod 3.0)
-- ---------------------------------------------------------------------
-- Page d'accueil du panneau /tm : vue d'ensemble avec gros toggles de
-- modules, relance de l'assistant, application d'un preset, changement
-- de profil et réinitialisation.
--
-- Les toggles écrivent la DB ; certains modules ne se rafraîchissent
-- qu'au /reload (bouton dédié + RL du bandeau), cohérent avec les
-- presets et l'installeur.
-- =====================================================================

local W = TomoMod_Widgets

-- ── Locales (FR + EN, autonome) ──────────────────────────────────────
if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["dash_welcome"]         = "Quick overview of TomoMod. Toggle modules, apply a setup, switch profile, or relaunch the setup assistant.",
        ["dash_modules_section"] = "Modules",
        ["dash_quickcfg_section"]= "Quick configuration",
        ["dash_profile_section"] = "Profile",
        ["dash_maint_section"]   = "Maintenance",
        ["dash_reload_hint"]     = "Toggling modules writes your settings — reload to apply module changes.",
        ["dash_reload_now"]      = "Reload now",
        ["dash_apply_preset"]    = "Setup preset",
        ["dash_apply_preset_btn"]= "Apply this preset",
        ["dash_apply_preset_info"] = "Applying a preset resets which modules are on or off, then reloads.",
        ["dash_active_profile"]  = "Active profile",
        ["dash_manage_profiles"] = "Manage profiles",
        ["dash_profile_info"]    = "Switching profile reloads the interface to apply it.",
        ["dash_relaunch_info"]   = "Reopens the presets-first setup assistant.",
        ["dash_mod_resources"]   = "Resources",
        ["dash_mod_cdm"]         = "Cooldown Manager",
        ["dash_mod_abskin"]      = "Action bar skin",
        ["dash_mod_chatskin"]    = "Chat skin",
        ["dash_mod_bagskin"]     = "Bag skin",
        ["dash_mod_mtracker"]    = "Mythic+ tracker",
        ["dash_mod_score"]       = "Mythic+ score",
        ["dash_reload_popup"]    = "Reload the interface now to apply your changes?",
    })
    TomoMod_RegisterLocale("frFR", {
        ["dash_welcome"]         = "Vue d'ensemble de TomoMod. Active des modules, applique une configuration, change de profil ou relance l'assistant.",
        ["dash_modules_section"] = "Modules",
        ["dash_quickcfg_section"]= "Configuration rapide",
        ["dash_profile_section"] = "Profil",
        ["dash_maint_section"]   = "Maintenance",
        ["dash_reload_hint"]     = "Les toggles enregistrent tes réglages — recharge pour appliquer les changements de module.",
        ["dash_reload_now"]      = "Recharger maintenant",
        ["dash_apply_preset"]    = "Preset de configuration",
        ["dash_apply_preset_btn"]= "Appliquer ce preset",
        ["dash_apply_preset_info"] = "Appliquer un preset réinitialise quels modules sont activés ou non, puis recharge.",
        ["dash_active_profile"]  = "Profil actif",
        ["dash_manage_profiles"] = "Gérer les profils",
        ["dash_profile_info"]    = "Changer de profil recharge l'interface pour l'appliquer.",
        ["dash_relaunch_info"]   = "Rouvre l'assistant de configuration « presets d'abord ».",
        ["dash_mod_resources"]   = "Ressources",
        ["dash_mod_cdm"]         = "Cooldown Manager",
        ["dash_mod_abskin"]      = "Skin des barres d'action",
        ["dash_mod_chatskin"]    = "Skin du chat",
        ["dash_mod_bagskin"]     = "Skin des sacs",
        ["dash_mod_mtracker"]    = "Suivi Mythic+",
        ["dash_mod_score"]       = "Score Mythic+",
        ["dash_reload_popup"]    = "Recharger l'interface maintenant pour appliquer tes changements ?",
    })
end

local L = TomoMod_L

-- Toggle de module générique (écrit TomoModDB[tbl][key])
local function ModToggle(col, label, tbl, key)
    local cur = TomoModDB[tbl] and TomoModDB[tbl][key]
    local _, ny = W.CreateCheckbox(col, label, cur ~= false, 0, function(v)
        if not TomoModDB[tbl] then TomoModDB[tbl] = {} end
        TomoModDB[tbl][key] = v
    end)
    return ny
end

function TomoMod_ConfigPanel_Accueil(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -12

    local _, y = W.CreateInfoText(c, L["dash_welcome"], y)

    -- ═══════════════════════════════════════════════
    -- MODULES (gros toggles)
    -- ═══════════════════════════════════════════════
    local card, cy = W.CreateCard(c, L["dash_modules_section"], y)

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col) return ModToggle(col, L["cat_unitframes"], "unitFrames", "enabled") end,
        function(col) return ModToggle(col, L["cat_nameplates"], "nameplates", "enabled") end)

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col) return ModToggle(col, L["cat_partyframes"], "partyFrames", "enabled") end,
        function(col) return ModToggle(col, L["cat_raidframes"],  "raidFrames",  "enabled") end)

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col) return ModToggle(col, L["cat_castbars"],     "castbars",     "enabled") end,
        function(col) return ModToggle(col, L["dash_mod_resources"], "resourceBars", "enabled") end)

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col) return ModToggle(col, L["dash_mod_cdm"],    "cooldownManager", "enabled") end,
        function(col) return ModToggle(col, L["dash_mod_abskin"], "actionBarSkin",   "enabled") end)

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col) return ModToggle(col, L["dash_mod_chatskin"], "chatFrameSkin", "enabled") end,
        function(col) return ModToggle(col, L["dash_mod_bagskin"],  "bagSkin",       "enabled") end)

    local _, cy = W.CreateTwoColumnRow(card.inner, cy,
        function(col) return ModToggle(col, L["dash_mod_mtracker"], "MythicTracker", "enabled") end,
        function(col) return ModToggle(col, L["dash_mod_score"],    "TomoScore",     "enabled") end)

    local _, cy = W.CreateInfoText(card.inner, L["dash_reload_hint"], cy)
    local _, cy = W.CreateButton(card.inner, L["dash_reload_now"], 200, cy, function() ReloadUI() end)

    y = W.FinalizeCard(card, cy)

    -- ═══════════════════════════════════════════════
    -- CONFIGURATION RAPIDE (installeur + preset)
    -- ═══════════════════════════════════════════════
    local card2, cy = W.CreateCard(c, L["dash_quickcfg_section"], y)

    local _, cy = W.CreateButton(card2.inner, L["btn_relaunch_installer"] or "Relancer l'assistant", 220, cy, function()
        if TomoMod_Installer then
            TomoMod_Installer.Show()
            if TomoMod_Config and TomoMod_Config.Hide then TomoMod_Config.Hide() end
        end
    end)
    local _, cy = W.CreateInfoText(card2.inner, L["dash_relaunch_info"], cy)

    -- Liste des presets (hors "Personnalisé")
    local presetOpts = {}
    if TomoMod_Presets and TomoMod_Presets.GetList then
        for _, def in ipairs(TomoMod_Presets.GetList()) do
            if not def.custom then
                presetOpts[#presetOpts+1] = { text = def.name, value = def.key }
            end
        end
    end
    local chosenPreset = (TomoModDB and TomoModDB._lastPreset) or "complet"

    local _, cy = W.CreateDropdown(card2.inner, L["dash_apply_preset"], presetOpts, chosenPreset, cy, function(v)
        chosenPreset = v
    end)
    local _, cy = W.CreateButton(card2.inner, L["dash_apply_preset_btn"], 220, cy, function()
        if TomoMod_Presets and TomoMod_Presets.Apply and chosenPreset then
            TomoMod_Presets.Apply(chosenPreset)
            StaticPopup_Show("TOMOMOD_DASH_RELOAD")
        end
    end)
    local _, cy = W.CreateInfoText(card2.inner, L["dash_apply_preset_info"], cy)

    y = W.FinalizeCard(card2, cy)

    -- ═══════════════════════════════════════════════
    -- PROFIL
    -- ═══════════════════════════════════════════════
    local card3, cy = W.CreateCard(c, L["dash_profile_section"], y)

    local profOpts, active = {}, "Default"
    if TomoMod_Profiles then
        local order = TomoMod_Profiles.GetProfileList()
        for _, n in ipairs(order or {}) do
            profOpts[#profOpts+1] = { text = n, value = n }
        end
        active = TomoMod_Profiles.GetActiveProfileName() or "Default"
    end
    if #profOpts == 0 then profOpts[1] = { text = active, value = active } end

    local _, cy = W.CreateDropdown(card3.inner, L["dash_active_profile"], profOpts, active, cy, function(v)
        if TomoMod_Profiles and v and v ~= TomoMod_Profiles.GetActiveProfileName() then
            TomoMod_Profiles.LoadNamedProfile(v)
            StaticPopup_Show("TOMOMOD_DASH_RELOAD")
        end
    end)
    local _, cy = W.CreateButton(card3.inner, L["dash_manage_profiles"], 220, cy, function()
        if TomoMod_Config and TomoMod_Config.OpenCategory then
            TomoMod_Config.OpenCategory("profiles")
        end
    end)
    local _, cy = W.CreateInfoText(card3.inner, L["dash_profile_info"], cy)

    y = W.FinalizeCard(card3, cy)

    -- ═══════════════════════════════════════════════
    -- MAINTENANCE
    -- ═══════════════════════════════════════════════
    local card4, cy = W.CreateCard(c, L["dash_maint_section"], y)

    local _, cy = W.CreateButton(card4.inner, L["btn_reset_all"] or "Réinitialiser tout", 220, cy, function()
        StaticPopup_Show("TOMOMOD_DASH_RESET")
    end)
    local _, cy = W.CreateInfoText(card4.inner, L["info_reset_all"] or "Réinitialise tous les paramètres et recharge l'UI.", cy)

    y = W.FinalizeCard(card4, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ── Popups ──────────────────────────────────────────────────────────
StaticPopupDialogs["TOMOMOD_DASH_RELOAD"] = {
    text     = L["dash_reload_popup"] or "Recharger l'interface maintenant ?",
    button1  = L["popup_confirm"] or "Confirmer",
    button2  = L["popup_cancel"]  or "Annuler",
    OnAccept = function() ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["TOMOMOD_DASH_RESET"] = {
    text     = L["popup_reset_text"] or "Réinitialiser tous les paramètres ?",
    button1  = L["popup_confirm"] or "Confirmer",
    button2  = L["popup_cancel"]  or "Annuler",
    OnAccept = function() TomoMod_ResetDatabase(); ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

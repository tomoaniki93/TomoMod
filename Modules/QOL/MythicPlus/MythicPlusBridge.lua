-- =====================================================================
-- MythicPlusBridge.lua -- tiny always-loaded bridge for the dedicated
-- TomoMod_MythicPlus LoadOnDemand control centre.
--
-- Existing runtime modules (tracker, score, key sync, legacy MythicHub)
-- remain in TomoMod for V1.  This file only owns entry points and makes
-- sure the LoD history recorder is present before a key starts.
-- =====================================================================

TomoMod_MythicPlusLauncher = TomoMod_MythicPlusLauncher or {}
local B = TomoMod_MythicPlusLauncher

local ADDON = "TomoMod_MythicPlus"
local PREFIX = "|cff2ed884TomoMod|r Mythic+ : "

local STRINGS = {
    enUS = {
        studio_title = "Mythic+ Studio",
        studio_blurb = "Central dashboard for Mythic+ settings, run history, statistics, keys and weekly progress.",
        open_studio  = "Open Mythic+ Studio",
        load_error   = "Mythic+ Studio could not be loaded",
        combat_wait  = "Mythic+ Studio will open when combat ends.",
    },
    frFR = {
        studio_title = "Studio Mythic+",
        studio_blurb = "Tableau de bord central pour les reglages Mythic+, l'historique des cles, les statistiques, les cles du groupe et la progression hebdomadaire.",
        open_studio  = "Ouvrir le Studio Mythic+",
        load_error   = "Le Studio Mythic+ n'a pas pu etre charge",
        combat_wait  = "Le Studio Mythic+ s'ouvrira a la fin du combat.",
    },
    deDE = {
        studio_title = "Mythisch+ Studio",
        studio_blurb = "Zentrale Uebersicht fuer Mythisch+-Einstellungen, Laufhistorie, Statistiken, Schluessel und Wochenfortschritt.",
        open_studio  = "Mythisch+ Studio oeffnen",
        load_error   = "Das Mythisch+ Studio konnte nicht geladen werden",
        combat_wait  = "Das Mythisch+ Studio wird nach dem Kampf geoeffnet.",
    },
    esES = {
        studio_title = "Estudio Mitico+",
        studio_blurb = "Panel central para ajustes de Mitico+, historial, estadisticas, piedras y progreso semanal.",
        open_studio  = "Abrir Estudio Mitico+",
        load_error   = "No se pudo cargar el Estudio Mitico+",
        combat_wait  = "El Estudio Mitico+ se abrira al terminar el combate.",
    },
    itIT = {
        studio_title = "Studio Mitica+",
        studio_blurb = "Dashboard centrale per impostazioni Mitica+, cronologia, statistiche, chiavi e progresso settimanale.",
        open_studio  = "Apri Studio Mitica+",
        load_error   = "Impossibile caricare lo Studio Mitica+",
        combat_wait  = "Lo Studio Mitica+ si aprira alla fine del combattimento.",
    },
    ptBR = {
        studio_title = "Estudio Mitico+",
        studio_blurb = "Painel central para configuracoes de Mitico+, historico, estatisticas, chaves e progresso semanal.",
        open_studio  = "Abrir Estudio Mitico+",
        load_error   = "Nao foi possivel carregar o Estudio Mitico+",
        combat_wait  = "O Estudio Mitico+ abrira quando o combate terminar.",
    },
}

local function Text(key)
    local locale = GetLocale and GetLocale() or "enUS"
    local set = STRINGS[locale] or STRINGS.enUS
    return set[key] or STRINGS.enUS[key] or key
end

TomoMod_MythicPlusText = Text
B.Text = Text

local function EnsureLoaded()
    if C_AddOns.IsAddOnLoaded(ADDON) then return true, false end

    local ok, reason = C_AddOns.LoadAddOn(ADDON)
    if not ok and reason == "DISABLED" and C_AddOns.EnableAddOn then
        pcall(C_AddOns.EnableAddOn, ADDON)
        ok, reason = C_AddOns.LoadAddOn(ADDON)
    end

    if not ok then
        return false, false, reason
    end
    return true, true
end

local function Studio()
    return _G.TomoMod_MythicPlus
end

function B:Open(page)
    if InCombatLockdown() then
        self._pendingPage = page or "dashboard"
        print(PREFIX .. Text("combat_wait"))
        return false
    end

    local ok, _, reason = EnsureLoaded()
    if not ok then
        print(PREFIX .. Text("load_error") .. (reason and (" (" .. tostring(reason) .. ")") or "") .. ".")
        return false
    end

    if TomoMod_Config and TomoMod_Config.Hide then
        TomoMod_Config.Hide()
    end

    local mp = Studio()
    if not (mp and mp.Open) then
        print(PREFIX .. Text("load_error") .. ".")
        return false
    end

    -- If the old detail window was left open, close it before showing the
    -- control centre.  Never hide its secure-button parent during combat.
    local hub = _G.TomoMod_MythicHub
    if hub and hub.Frame and hub.Frame:IsShown() then
        hub.Frame:Hide()
    end

    mp:Open(page or "dashboard")
    return true
end

function B:Toggle(page)
    local mp = Studio()
    if mp and mp.Frame and mp.Frame:IsShown() then
        mp:Hide()
        return true
    end
    return self:Open(page or "dashboard")
end

-- V1 keeps the old MythicHub implementation as the detailed dungeon/vault
-- view.  Its normal entry points are redirected to the new dashboard, but
-- the Studio can deliberately call the preserved method from a button.
function B:OpenLegacyHub()
    if InCombatLockdown() then
        print(PREFIX .. Text("combat_wait"))
        return false
    end
    local hub = _G.TomoMod_MythicHub
    if not hub then return false end

    local mp = Studio()
    if mp and mp.Hide then mp:Hide() end

    if self._legacyHubShow then
        self._legacyHubShow(hub)
        return true
    elseif hub.Show then
        hub:Show()
        return true
    end
    return false
end

local function RedirectLegacyHub()
    if B._hubRedirected then return end
    local hub = _G.TomoMod_MythicHub
    if not hub then return end

    B._legacyHubToggle = hub.Toggle
    B._legacyHubShow   = hub.Show
    B._legacyHubHide   = hub.Hide

    hub.Toggle = function()
        return B:Toggle("dashboard")
    end
    hub.Show = function()
        return B:Open("dashboard")
    end

    B._hubRedirected = true
end

RedirectLegacyHub()

-- Load the LoD recorder at challenge start.  When loading is triggered by
-- this very event, the newly-created event frame cannot receive the event
-- retroactively, so forward it exactly once after a successful fresh load.
local events = CreateFrame("Frame")
events:RegisterEvent("CHALLENGE_MODE_START")
events:RegisterEvent("CHALLENGE_MODE_COMPLETED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if B._pendingPage then
            local page = B._pendingPage
            B._pendingPage = nil
            B:Open(page)
        end
        return
    end

    local ok = EnsureLoaded()
    if not ok then return end

    -- The bridge owns start/completion delivery.  This works both for the
    -- event that caused the LoD addon to load (which its own frames cannot
    -- receive retroactively) and for every later run in the same session.
    local mp = Studio()
    if not mp then return end
    if event == "CHALLENGE_MODE_START" and mp.OnChallengeStart then
        mp:OnChallengeStart()
    elseif event == "CHALLENGE_MODE_COMPLETED" and mp.OnChallengeCompleted then
        mp:OnChallengeCompleted()
    end
end)

SLASH_TOMOMODMYTHICPLUS1 = "/tmplus"
SLASH_TOMOMODMYTHICPLUS2 = "/tmmplus"
SlashCmdList.TOMOMODMYTHICPLUS = function()
    B:Toggle("dashboard")
end

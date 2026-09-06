-- =====================================================================
-- Panels/Accueil.lua - Tableau de bord TomoMod
-- =====================================================================

local W = TomoMod_Widgets

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local LOGO_TEX  = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Logo.tga"

local A  = W.Theme.accent
local AD = W.Theme.accentDark
local TX = W.Theme.text
local DM = W.Theme.textDim
local CY = { 0.49, 0.91, 1.00, 1 }
local GD = { 0.96, 0.70, 0.26, 1 }

if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["dash_welcome"]             = "Mission control for TomoMod.",
        ["dash_hero_title"]          = "TomoMod Control",
        ["dash_hero_subtitle"]       = "Profiles, modules, presets and Installer in one place.",
        ["dash_actions_section"]     = "Quick actions",
        ["dash_modules_section"]     = "Essential modules",
        ["dash_quickcfg_section"]    = "Quick configuration",
        ["dash_profile_section"]     = "Profile",
        ["dash_maint_section"]       = "Maintenance",
        ["dash_modules_enabled"]     = "Modules active",
        ["dash_status_ready"]        = "Ready",
        ["dash_status_attention"]    = "Check",
        ["dash_status_external"]     = "External",
        ["dash_status_ready_tip"]    = "No TomoMod issue is currently captured by diagnostics.",
        ["dash_status_attention_tip"] = "TomoMod diagnostics have captured %d issue(s). Open Diagnostics for details.",
        ["dash_status_external_tip"] = "%d issue(s) are captured, but not attributed to TomoMod.",
        ["dash_reload_hint"]         = "Module toggles are saved instantly. Reload to fully apply module startup changes.",
        ["dash_action_forge"]        = "Installer",
        ["dash_action_profiles"]     = "Profiles",
        ["dash_action_diagnostics"]  = "Diagnostics",
        ["dash_action_reload"]       = "Reload",
        ["dash_apply_preset"]        = "Setup preset",
        ["dash_apply_preset_btn"]    = "Apply this preset",
        ["dash_apply_preset_info"]   = "Applying a preset changes enabled modules and then asks for a reload.",
        ["dash_active_profile"]      = "Active profile",
        ["dash_manage_profiles"]     = "Manage profiles",
        ["dash_profile_info"]        = "Switching profile reloads the interface to apply it cleanly.",
        ["dash_mod_resources"]       = "Resources",
        ["dash_mod_cdm"]             = "Cooldown Manager",
        ["dash_mod_abskin"]          = "Action bar skin",
        ["dash_mod_chatskin"]        = "Chat V4",
        ["dash_mod_bagskin"]         = "Bags V4",
        ["dash_mod_mtracker"]        = "Mythic+ tracker",
        ["dash_mod_score"]           = "Mythic+ score",
        ["dash_toggle_on"]           = "On",
        ["dash_toggle_off"]          = "Off",
        ["dash_reload_popup"]        = "Reload the interface now to apply your changes?",
    })
    TomoMod_RegisterLocale("frFR", {
        ["dash_welcome"]             = "Centre de pilotage TomoMod.",
        ["dash_hero_title"]          = "Accueil TomoMod",
        ["dash_hero_subtitle"]       = "Profils, modules, presets et Forge astrale au même endroit.",
        ["dash_actions_section"]     = "Actions rapides",
        ["dash_modules_section"]     = "Modules essentiels",
        ["dash_quickcfg_section"]    = "Configuration rapide",
        ["dash_profile_section"]     = "Profil",
        ["dash_maint_section"]       = "Maintenance",
        ["dash_modules_enabled"]     = "Modules actifs",
        ["dash_status_ready"]        = "Prêt",
        ["dash_status_attention"]    = "À vérifier",
        ["dash_status_external"]     = "Externe",
        ["dash_status_ready_tip"]    = "Aucun souci TomoMod n'est capturé par les diagnostics.",
        ["dash_status_attention_tip"] = "Les diagnostics TomoMod ont capturé %d souci(s). Ouvre Diagnostics pour le détail.",
        ["dash_status_external_tip"] = "%d souci(s) sont capturés, mais pas attribués à TomoMod.",
        ["dash_reload_hint"]         = "Les modules sont enregistrés immédiatement. Recharge pour appliquer proprement les changements de démarrage.",
        ["dash_action_forge"]        = "Installeur",
        ["dash_action_profiles"]     = "Profils",
        ["dash_action_diagnostics"]  = "Diagnostics",
        ["dash_action_reload"]       = "Recharger",
        ["dash_apply_preset"]        = "Preset de configuration",
        ["dash_apply_preset_btn"]    = "Appliquer ce preset",
        ["dash_apply_preset_info"]   = "Appliquer un preset change les modules activés puis propose un rechargement.",
        ["dash_active_profile"]      = "Profil actif",
        ["dash_manage_profiles"]     = "Gérer les profils",
        ["dash_profile_info"]        = "Changer de profil recharge l'interface pour l'appliquer proprement.",
        ["dash_mod_resources"]       = "Ressources",
        ["dash_mod_cdm"]             = "Cooldown Manager",
        ["dash_mod_abskin"]          = "Skin des barres d'action",
        ["dash_mod_chatskin"]        = "Chat V4",
        ["dash_mod_bagskin"]         = "Sacs V4",
        ["dash_mod_mtracker"]        = "Suivi Mythic+",
        ["dash_mod_score"]           = "Score Mythic+",
        ["dash_toggle_on"]           = "Actif",
        ["dash_toggle_off"]          = "Off",
        ["dash_reload_popup"]        = "Recharger l'interface maintenant pour appliquer tes changements ?",
    })
end

-- Dashboard Studio Hub -- localised in all six supported languages.
-- Kept here with the dashboard renderer so the hub can evolve without
-- coupling these labels to the individual LoadOnDemand studio addons.
if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["dash_studios_section"]          = "TomoMod Studios",
        ["dash_studios_info"]             = "Advanced visual editors for the main TomoMod systems.",
        ["dash_studio_cooldown_title"]     = "Cooldown Studio",
        ["dash_studio_cooldown_desc"]      = "Full-screen cooldown bar editor: layout, style, spells, visibility and presets.",
        ["dash_studio_cooldown_open"]      = "Open Cooldown Studio",
        ["dash_studio_mythic_title"]       = "Mythic+ Studio",
        ["dash_studio_mythic_desc"]        = "Configure Mythic+ tracking, score, run history, keys, widgets and dungeon elements.",
        ["dash_studio_mythic_open"]        = "Open Mythic+ Studio",
        ["dash_studio_healer_title"]       = "Healer Studio",
        ["dash_studio_healer_desc"]        = "Configure HoTs, shields and healing indicators on PartyFrames and RaidFrames.",
        ["dash_studio_healer_open"]        = "Open Healer Studio",
        ["dash_studio_astral_title"]       = "Astral Forge Studio",
        ["dash_studio_astral_desc"]        = "Advanced creation and editing studio for UnitFrame and Nameplate elements, with layout tools and visual customisation.",
        ["dash_studio_astral_open"]        = "Open Astral Forge Studio",
        ["dash_studio_status_available"]   = "Available",
        ["dash_studio_status_missing"]     = "Not installed",
        ["dash_studio_status_soon"]        = "Coming soon",
        ["btn_open_astralforge"]           = "Open Astral Forge Studio",
    })
    TomoMod_RegisterLocale("frFR", {
        ["dash_studios_section"]          = "Studios TomoMod",
        ["dash_studios_info"]             = "Éditeurs visuels avancés pour les principaux systèmes de TomoMod.",
        ["dash_studio_cooldown_title"]     = "Cooldown Studio",
        ["dash_studio_cooldown_desc"]      = "Éditeur plein écran des barres de cooldowns : disposition, style, sorts, visibilité et presets.",
        ["dash_studio_cooldown_open"]      = "Ouvrir Cooldown Studio",
        ["dash_studio_mythic_title"]       = "Studio Mythic+",
        ["dash_studio_mythic_desc"]        = "Configuration du suivi Mythique+, score, historique, clés, widgets et éléments de donjon.",
        ["dash_studio_mythic_open"]        = "Ouvrir le Studio Mythic+",
        ["dash_studio_healer_title"]       = "Healer Studio",
        ["dash_studio_healer_desc"]        = "Configuration des HoTs, boucliers et indicateurs de soins sur les PartyFrames et RaidFrames.",
        ["dash_studio_healer_open"]        = "Ouvrir Healer Studio",
        ["dash_studio_astral_title"]       = "Astral Forge Studio",
        ["dash_studio_astral_desc"]        = "Studio de création et d’édition avancée pour les éléments UnitFrame et Nameplates, avec outils de disposition et personnalisation visuelle.",
        ["dash_studio_astral_open"]        = "Ouvrir Astral Forge Studio",
        ["dash_studio_status_available"]   = "Disponible",
        ["dash_studio_status_missing"]     = "Non installé",
        ["dash_studio_status_soon"]        = "Bientôt disponible",
        ["btn_open_astralforge"]           = "Ouvrir Astral Forge Studio",
    })
    TomoMod_RegisterLocale("deDE", {
        ["dash_studios_section"]          = "TomoMod Studios",
        ["dash_studios_info"]             = "Erweiterte visuelle Editoren für die wichtigsten TomoMod-Systeme.",
        ["dash_studio_cooldown_title"]     = "Cooldown Studio",
        ["dash_studio_cooldown_desc"]      = "Vollbild-Editor für Cooldown-Leisten: Layout, Stil, Zauber, Sichtbarkeit und Presets.",
        ["dash_studio_cooldown_open"]      = "Cooldown Studio öffnen",
        ["dash_studio_mythic_title"]       = "Mythisch+ Studio",
        ["dash_studio_mythic_desc"]        = "Konfiguriere Mythisch+-Tracking, Wertung, Laufhistorie, Schlüssel, Widgets und Dungeonelemente.",
        ["dash_studio_mythic_open"]        = "Mythisch+ Studio öffnen",
        ["dash_studio_healer_title"]       = "Heiler-Studio",
        ["dash_studio_healer_desc"]        = "Konfiguriere HoTs, Schilde und Heilungsindikatoren auf Gruppen- und Schlachtzugsrahmen.",
        ["dash_studio_healer_open"]        = "Heiler-Studio öffnen",
        ["dash_studio_astral_title"]       = "Astral Forge Studio",
        ["dash_studio_astral_desc"]        = "Erweitertes Studio zum Erstellen und Bearbeiten von UnitFrame- und Nameplate-Elementen mit Layout- und visuellen Anpassungswerkzeugen.",
        ["dash_studio_astral_open"]        = "Astral Forge Studio öffnen",
        ["dash_studio_status_available"]   = "Verfügbar",
        ["dash_studio_status_missing"]     = "Nicht installiert",
        ["dash_studio_status_soon"]        = "Demnächst",
        ["btn_open_astralforge"]           = "Astral Forge Studio öffnen",
    })
    TomoMod_RegisterLocale("esES", {
        ["dash_studios_section"]          = "Estudios TomoMod",
        ["dash_studios_info"]             = "Editores visuales avanzados para los principales sistemas de TomoMod.",
        ["dash_studio_cooldown_title"]     = "Estudio de reutilizaciones",
        ["dash_studio_cooldown_desc"]      = "Editor a pantalla completa de barras de reutilización: disposición, estilo, hechizos, visibilidad y preajustes.",
        ["dash_studio_cooldown_open"]      = "Abrir Estudio de reutilizaciones",
        ["dash_studio_mythic_title"]       = "Estudio Mítico+",
        ["dash_studio_mythic_desc"]        = "Configura seguimiento Mítico+, puntuación, historial, piedras, widgets y elementos de mazmorra.",
        ["dash_studio_mythic_open"]        = "Abrir Estudio Mítico+",
        ["dash_studio_healer_title"]       = "Estudio de sanador",
        ["dash_studio_healer_desc"]        = "Configura HoTs, escudos e indicadores de sanación en marcos de grupo y banda.",
        ["dash_studio_healer_open"]        = "Abrir Estudio de sanador",
        ["dash_studio_astral_title"]       = "Astral Forge Studio",
        ["dash_studio_astral_desc"]        = "Estudio avanzado de creación y edición para elementos de UnitFrame y Nameplates, con herramientas de disposición y personalización visual.",
        ["dash_studio_astral_open"]        = "Abrir Astral Forge Studio",
        ["dash_studio_status_available"]   = "Disponible",
        ["dash_studio_status_missing"]     = "No instalado",
        ["dash_studio_status_soon"]        = "Próximamente",
        ["btn_open_astralforge"]           = "Abrir Astral Forge Studio",
    })
    TomoMod_RegisterLocale("itIT", {
        ["dash_studios_section"]          = "Studi TomoMod",
        ["dash_studios_info"]             = "Editor visuali avanzati per i principali sistemi di TomoMod.",
        ["dash_studio_cooldown_title"]     = "Studio recuperi",
        ["dash_studio_cooldown_desc"]      = "Editor a schermo intero delle barre dei tempi di recupero: disposizione, stile, abilità, visibilità e preset.",
        ["dash_studio_cooldown_open"]      = "Apri Studio recuperi",
        ["dash_studio_mythic_title"]       = "Studio Mitica+",
        ["dash_studio_mythic_desc"]        = "Configura tracciamento Mitica+, punteggio, cronologia, chiavi, widget ed elementi dei dungeon.",
        ["dash_studio_mythic_open"]        = "Apri Studio Mitica+",
        ["dash_studio_healer_title"]       = "Studio guaritore",
        ["dash_studio_healer_desc"]        = "Configura HoT, scudi e indicatori di cura sui riquadri di gruppo e incursione.",
        ["dash_studio_healer_open"]        = "Apri Studio guaritore",
        ["dash_studio_astral_title"]       = "Astral Forge Studio",
        ["dash_studio_astral_desc"]        = "Studio avanzato per creare e modificare elementi UnitFrame e Nameplates, con strumenti di disposizione e personalizzazione visiva.",
        ["dash_studio_astral_open"]        = "Apri Astral Forge Studio",
        ["dash_studio_status_available"]   = "Disponibile",
        ["dash_studio_status_missing"]     = "Non installato",
        ["dash_studio_status_soon"]        = "Prossimamente",
        ["btn_open_astralforge"]           = "Apri Astral Forge Studio",
    })
    TomoMod_RegisterLocale("ptBR", {
        ["dash_studios_section"]          = "Estúdios TomoMod",
        ["dash_studios_info"]             = "Editores visuais avançados para os principais sistemas do TomoMod.",
        ["dash_studio_cooldown_title"]     = "Estúdio de recargas",
        ["dash_studio_cooldown_desc"]      = "Editor em tela cheia das barras de recarga: layout, estilo, habilidades, visibilidade e predefinições.",
        ["dash_studio_cooldown_open"]      = "Abrir Estúdio de recargas",
        ["dash_studio_mythic_title"]       = "Estúdio Mítico+",
        ["dash_studio_mythic_desc"]        = "Configure rastreamento Mítico+, pontuação, histórico, chaves, widgets e elementos de masmorra.",
        ["dash_studio_mythic_open"]        = "Abrir Estúdio Mítico+",
        ["dash_studio_healer_title"]       = "Estúdio de cura",
        ["dash_studio_healer_desc"]        = "Configure HoTs, escudos e indicadores de cura nos quadros de grupo e raide.",
        ["dash_studio_healer_open"]        = "Abrir Estúdio de cura",
        ["dash_studio_astral_title"]       = "Astral Forge Studio",
        ["dash_studio_astral_desc"]        = "Estúdio avançado para criação e edição de elementos de UnitFrame e Nameplates, com ferramentas de layout e personalização visual.",
        ["dash_studio_astral_open"]        = "Abrir Astral Forge Studio",
        ["dash_studio_status_available"]   = "Disponível",
        ["dash_studio_status_missing"]     = "Não instalado",
        ["dash_studio_status_soon"]        = "Em breve",
        ["btn_open_astralforge"]           = "Abrir Astral Forge Studio",
    })
end

-- Party & Raid Studio dashboard card. The old Healer Studio remains present
-- during the transition; both editors use the same HealerIndicators DB.
if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["dash_studio_group_title"] = "Party & Raid Studio",
        ["dash_studio_group_desc"]  = "Configure PartyFrames, RaidFrames and healer indicators with real-time visual previews.",
        ["dash_studio_group_open"]  = "Open Party & Raid Studio",
    })
    TomoMod_RegisterLocale("frFR", {
        ["dash_studio_group_title"] = "Studio Party & Raid",
        ["dash_studio_group_desc"]  = "Configure les PartyFrames, RaidFrames et indicateurs Healer avec des aperçus visuels en temps réel.",
        ["dash_studio_group_open"]  = "Ouvrir le Studio Party & Raid",
    })
    TomoMod_RegisterLocale("deDE", {
        ["dash_studio_group_title"] = "Gruppen- & Schlachtzug-Studio",
        ["dash_studio_group_desc"]  = "Konfiguriere PartyFrames, RaidFrames und Heileranzeigen mit visueller Echtzeitvorschau.",
        ["dash_studio_group_open"]  = "Gruppen- & Schlachtzug-Studio öffnen",
    })
    TomoMod_RegisterLocale("esES", {
        ["dash_studio_group_title"] = "Estudio Grupo y Banda",
        ["dash_studio_group_desc"]  = "Configura PartyFrames, RaidFrames e indicadores de sanador con vistas previas visuales en tiempo real.",
        ["dash_studio_group_open"]  = "Abrir Estudio Grupo y Banda",
    })
    TomoMod_RegisterLocale("itIT", {
        ["dash_studio_group_title"] = "Studio Gruppo e Incursione",
        ["dash_studio_group_desc"]  = "Configura PartyFrame, RaidFrame e indicatori guaritore con anteprime visive in tempo reale.",
        ["dash_studio_group_open"]  = "Apri Studio Gruppo e Incursione",
    })
    TomoMod_RegisterLocale("ptBR", {
        ["dash_studio_group_title"] = "Estúdio Grupo e Raide",
        ["dash_studio_group_desc"]  = "Configure PartyFrames, RaidFrames e indicadores de curador com prévias visuais em tempo real.",
        ["dash_studio_group_open"]  = "Abrir Estúdio Grupo e Raide",
    })
end

local L = TomoMod_L

local MODULES = {
    { label = "cat_unitframes",        tbl = "unitFrames",       key = "enabled" },
    { label = "cat_nameplates",        tbl = "nameplates",       key = "enabled" },
    { label = "cat_partyframes",       tbl = "partyFrames",      key = "enabled" },
    { label = "cat_raidframes",        tbl = "raidFrames",       key = "enabled" },
    { label = "cat_castbars",          tbl = "castbars",         key = "enabled" },
    { label = "dash_mod_resources",    tbl = "resourceBars",     key = "enabled" },
    { label = "dash_mod_cdm",          tbl = "cooldownManager",  key = "enabled" },
    { label = "dash_mod_abskin",       tbl = "actionBarSkin",    key = "enabled" },
    { label = "dash_mod_chatskin",     tbl = "chatV4",           key = "enabled" },
    { label = "dash_mod_bagskin",      tbl = "bagsV4",           key = "enabled" },
    { label = "dash_mod_mtracker",     tbl = "MythicTracker",    key = "enabled" },
    { label = "dash_mod_score",        tbl = "MysticScore",      key = "enabled" },
}

local function Localize(key, fallback)
    local value = L and L[key]
    if value and value ~= key then return value end
    return fallback or key
end

local function EnsureDBTable(name)
    TomoModDB = TomoModDB or {}
    TomoModDB[name] = TomoModDB[name] or {}
    return TomoModDB[name]
end

local function GetModuleState(def)
    local db = TomoModDB and TomoModDB[def.tbl]
    if not db then return true end
    return db[def.key] ~= false
end

local function SetModuleState(def, value)
    local enabled = value and true or false
    local db = EnsureDBTable(def.tbl)
    db[def.key] = enabled

    -- Chat V4 is fully reversible at runtime: unlike legacy ChatFrameSkin,
    -- the dashboard switch can apply immediately without a UI reload.
    if def.tbl == "chatV4" and TomoMod_ChatFrameSkin and TomoMod_ChatFrameSkin.SetEnabled then
        TomoMod_ChatFrameSkin.SetEnabled(enabled)
    end

    -- Bags V4 is also fully reversible at runtime. Keep the dashboard bound
    -- to the clean bagsV4 DB, but mirror the old flag while the remaining
    -- Phase-1 presets and installer still use it. This also prevents the
    -- compatibility bridge from restoring a stale enabled state.
    if def.tbl == "bagsV4" then
        EnsureDBTable("bagSkin").enabled = enabled
        if TomoMod_BagSkin and TomoMod_BagSkin.SetEnabled then
            TomoMod_BagSkin.SetEnabled(enabled)
        end
    end
end

local function CountEnabledModules()
    local count = 0
    for _, def in ipairs(MODULES) do
        if GetModuleState(def) then count = count + 1 end
    end
    return count
end

local function GetActiveProfile()
    if TomoMod_Profiles and TomoMod_Profiles.GetActiveProfileName then
        return TomoMod_Profiles.GetActiveProfileName() or "Default"
    end
    return "Default"
end

local function GetDashboardStatus()
    local D = TomoMod_Diagnostics
    if D then
        local own = 0
        local total = 0
        if D.GetTomoModErrorCount then
            own = tonumber(D.GetTomoModErrorCount()) or 0
        end
        if D.GetErrorCount then
            total = tonumber(D.GetErrorCount()) or 0
        end

        if own > 0 then
            return Localize("dash_status_attention", "À vérifier"),
                   string.format(Localize("dash_status_attention_tip", "Les diagnostics TomoMod ont capturé %d souci(s). Ouvre Diagnostics pour le détail."), own),
                   0.95, 0.36, 0.28
        elseif total > 0 then
            return Localize("dash_status_external", "Externe"),
                   string.format(Localize("dash_status_external_tip", "%d souci(s) sont capturés, mais pas attribués à TomoMod."), total),
                   0.96, 0.70, 0.26
        end
    end

    return Localize("dash_status_ready", "Prêt"),
           Localize("dash_status_ready_tip", "Aucun souci TomoMod n'est capturé par les diagnostics."),
           0.30, 0.85, 0.55
end

local function SetPanelBackdrop(frame, r, g, b, alpha)
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.045, 0.042, 0.065, alpha or 0.95)
    frame:SetBackdropBorderColor(r or A[1], g or A[2], b or A[3], 0.38)
end

local function CreatePanel(parent, title, y, height, r, g, b)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", 8, y)
    frame:SetPoint("TOPRIGHT", -8, y)
    frame:SetHeight(height)
    SetPanelBackdrop(frame, r, g, b, 0.95)

    local wash = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    wash:SetPoint("TOPLEFT", 1, -1)
    wash:SetPoint("BOTTOMRIGHT", -1, 1)
    if wash.SetGradientAlpha then
        wash:SetGradientAlpha("HORIZONTAL", r or A[1], g or A[2], b or A[3], 0.13, 0, 0, 0, 0)
    else
        wash:SetColorTexture(r or A[1], g or A[2], b or A[3], 0.08)
    end

    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetWidth(3)
    line:SetPoint("TOPLEFT", 0, -1)
    line:SetPoint("BOTTOMLEFT", 0, 1)
    line:SetColorTexture(r or A[1], g or A[2], b or A[3], 0.9)

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_BOLD, 12, "")
    label:SetPoint("TOPLEFT", 16, -12)
    label:SetText(title)
    label:SetTextColor(r or A[1], g or A[2], b or A[3], 1)

    return frame, y - height - 10
end

local function CreateChip(parent, title, value, x, y, width, r, g, b)
    local chip = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    chip:SetSize(width, 42)
    chip:SetPoint("TOPLEFT", x, y)
    SetPanelBackdrop(chip, r, g, b, 0.62)

    local titleText = chip:CreateFontString(nil, "OVERLAY")
    titleText:SetFont(FONT, 9, "")
    titleText:SetPoint("TOPLEFT", 10, -7)
    titleText:SetText(title)
    titleText:SetTextColor(DM[1], DM[2], DM[3], 1)

    local valueText = chip:CreateFontString(nil, "OVERLAY")
    valueText:SetFont(FONT_BOLD, 13, "")
    valueText:SetPoint("BOTTOMLEFT", 10, 7)
    valueText:SetPoint("RIGHT", -8, 0)
    valueText:SetJustifyH("LEFT")
    valueText:SetText(value)
    valueText:SetTextColor(TX[1], TX[2], TX[3], 1)
    return chip
end

local function CreateActionButton(parent, text, x, y, width, r, g, b, callback)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, 38)
    btn:SetPoint("TOPLEFT", x, y)
    SetPanelBackdrop(btn, r, g, b, 0.82)

    local accent = btn:CreateTexture(nil, "ARTWORK")
    accent:SetHeight(2)
    accent:SetPoint("TOPLEFT", 1, -1)
    accent:SetPoint("TOPRIGHT", -1, -1)
    accent:SetColorTexture(r, g, b, 0.9)

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_BOLD, 11, "")
    lbl:SetPoint("CENTER")
    lbl:SetText(text)
    lbl:SetTextColor(1, 1, 1, 1)

    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(r * 0.18, g * 0.18, b * 0.18, 0.95)
        btn:SetBackdropBorderColor(r, g, b, 0.85)
        lbl:SetTextColor(r, g, b, 1)
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(0.045, 0.042, 0.065, 0.82)
        btn:SetBackdropBorderColor(r, g, b, 0.38)
        lbl:SetTextColor(1, 1, 1, 1)
    end)
    btn:SetScript("OnClick", function()
        if callback then callback() end
    end)
    return btn
end

local function CreateHero(parent, y)
    local hero, nextY = CreatePanel(parent, "", y, 124, A[1], A[2], A[3])

    local logoGlow = hero:CreateTexture(nil, "BACKGROUND", nil, 1)
    logoGlow:SetSize(92, 92)
    logoGlow:SetPoint("LEFT", 12, 0)
    logoGlow:SetColorTexture(A[1], A[2], A[3], 0.13)

    local logo = hero:CreateTexture(nil, "OVERLAY")
    logo:SetSize(74, 74)
    logo:SetPoint("LEFT", 21, 0)
    logo:SetTexture(LOGO_TEX)
    logo:SetVertexColor(1, 1, 1, 1)

    local title = hero:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_BOLD, 22, "")
    title:SetPoint("TOPLEFT", 114, -25)
    title:SetText(Localize("dash_hero_title", "Accueil TomoMod"))
    title:SetTextColor(1, 1, 1, 1)

    local subtitle = hero:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(FONT, 12, "")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetPoint("RIGHT", -24, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText(Localize("dash_hero_subtitle", "Profils, modules, presets et Forge astrale au même endroit."))
    subtitle:SetTextColor(DM[1], DM[2], DM[3], 1)

    local version = "v" .. (C_AddOns.GetAddOnMetadata("TomoMod", "Version") or "?")
    local status, statusTip, sr, sg, sb = GetDashboardStatus()
    CreateChip(hero, Localize("dash_modules_enabled", "Modules actifs"), CountEnabledModules() .. " / " .. #MODULES, 114, -78, 150, A[1], A[2], A[3])
    CreateChip(hero, Localize("dash_active_profile", "Profil actif"), GetActiveProfile(), 274, -78, 170, CY[1], CY[2], CY[3])
    CreateChip(hero, "Version", version, 454, -78, 110, GD[1], GD[2], GD[3])
    local statusChip = CreateChip(hero, "État", status, 574, -78, 110, sr, sg, sb)
    statusChip:EnableMouse(true)
    statusChip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("État TomoMod", 1, 1, 1)
        GameTooltip:AddLine(statusTip, DM[1], DM[2], DM[3], true)
        GameTooltip:Show()
    end)
    statusChip:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return nextY
end

local function CreateQuickActions(parent, y)
    local panel, nextY = CreatePanel(parent, Localize("dash_actions_section", "Actions rapides"), y, 90, CY[1], CY[2], CY[3])
    CreateActionButton(panel, Localize("dash_action_forge", "Installeur"), 18, -38, 160, A[1], A[2], A[3], function()
        if TomoMod_OpenInstaller then
            TomoMod_OpenInstaller(true)
            if TomoMod_Config and TomoMod_Config.Hide then TomoMod_Config.Hide() end
        end
    end)
    CreateActionButton(panel, Localize("dash_action_profiles", "Profils"), 188, -38, 150, CY[1], CY[2], CY[3], function()
        if TomoMod_Config and TomoMod_Config.OpenCategory then
            TomoMod_Config.OpenCategory("profiles")
        end
    end)
    CreateActionButton(panel, Localize("dash_action_diagnostics", "Diagnostics"), 348, -38, 160, GD[1], GD[2], GD[3], function()
        if TomoMod_Config and TomoMod_Config.OpenCategory then
            TomoMod_Config.OpenCategory("diagnostics")
        end
    end)
    CreateActionButton(panel, Localize("dash_action_reload", "Recharger"), 518, -38, 150, 0.38, 0.86, 0.56, function()
        ReloadUI()
    end)
    return nextY
end

local function CreateModuleTile(parent, def, x, y)
    local tile = CreateFrame("Button", nil, parent, "BackdropTemplate")
    tile:SetSize(300, 30)
    tile:SetPoint("TOPLEFT", x, y)
    SetPanelBackdrop(tile, A[1], A[2], A[3], 0.55)

    local box = tile:CreateTexture(nil, "OVERLAY")
    box:SetSize(14, 14)
    box:SetPoint("LEFT", 10, 0)

    local label = tile:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 11, "")
    label:SetPoint("LEFT", box, "RIGHT", 9, 0)
    label:SetPoint("RIGHT", -58, 0)
    label:SetJustifyH("LEFT")
    label:SetText(Localize(def.label, def.label))

    local state = tile:CreateFontString(nil, "OVERLAY")
    state:SetFont(FONT_BOLD, 9, "")
    state:SetPoint("RIGHT", -10, 0)

    local function Refresh()
        local enabled = GetModuleState(def)
        if enabled then
            box:SetColorTexture(A[1], A[2], A[3], 0.95)
            label:SetTextColor(TX[1], TX[2], TX[3], 1)
            state:SetText(Localize("dash_toggle_on", "Actif"))
            state:SetTextColor(CY[1], CY[2], CY[3], 1)
        else
            box:SetColorTexture(0.22, 0.22, 0.27, 0.8)
            label:SetTextColor(DM[1], DM[2], DM[3], 1)
            state:SetText(Localize("dash_toggle_off", "Off"))
            state:SetTextColor(DM[1], DM[2], DM[3], 1)
        end
    end

    tile:SetScript("OnEnter", function()
        tile:SetBackdropBorderColor(A[1], A[2], A[3], 0.85)
    end)
    tile:SetScript("OnLeave", function()
        tile:SetBackdropBorderColor(A[1], A[2], A[3], 0.38)
    end)
    tile:SetScript("OnClick", function()
        SetModuleState(def, not GetModuleState(def))
        Refresh()
    end)
    Refresh()
    return tile
end

local function CreateModules(parent, y)
    local panel, nextY = CreatePanel(parent, Localize("dash_modules_section", "Modules essentiels"), y, 276, A[1], A[2], A[3])
    local colW = 318
    local startY = -42
    for i, def in ipairs(MODULES) do
        local col = ((i - 1) % 2)
        local row = math.floor((i - 1) / 2)
        CreateModuleTile(panel, def, 18 + col * colW, startY - row * 32)
    end

    local hint = panel:CreateFontString(nil, "OVERLAY")
    hint:SetFont(FONT, 10, "")
    hint:SetPoint("BOTTOMLEFT", 18, 14)
    hint:SetPoint("RIGHT", -18, 0)
    hint:SetJustifyH("LEFT")
    hint:SetText(Localize("dash_reload_hint", "Recharge pour appliquer les changements de module."))
    hint:SetTextColor(DM[1], DM[2], DM[3], 1)
    return nextY
end

-- =====================================================================
-- STUDIOS HUB
-- Centralises every dedicated LoadOnDemand editor in one dashboard card.
-- Each studio keeps its own launcher: this hub only presents and routes.
-- =====================================================================
local function OpenCooldownStudio()
    if TomoMod_OpenCooldownStudio then TomoMod_OpenCooldownStudio() end
end

local function OpenMythicPlusStudio()
    if TomoMod_MythicPlusLauncher and TomoMod_MythicPlusLauncher.Open then
        TomoMod_MythicPlusLauncher:Open("dashboard")
    end
end

local function OpenHealerStudio()
    if TomoMod_OpenHealerStudio then TomoMod_OpenHealerStudio("party") end
end

local function OpenGroupStudio()
    local Forge = TomoMod_Forge
    if not (Forge and Forge.Studio and Forge.Studio.Launch) then return end
    Forge.Studio.Launch({
        addon  = "TomoMod_GroupStudio",
        global = "TomoMod_GroupStudio",
        label  = Localize("dash_studio_group_title", "Party & Raid Studio"),
        arg    = "party",
    })
end

local function OpenAstralForgeStudio()
    local Forge = TomoMod_Forge
    if not (Forge and Forge.Studio and Forge.Studio.Launch) then return end
    Forge.Studio.Launch({
        addon  = "TomoMod_AstralForge",
        global = "TomoMod_AstralForge",
        label  = Localize("dash_studio_astral_title", "Astral Forge Studio"),
    })
end

local STUDIO_DEFS = {
    {
        addon = "TomoMod_CDStudio",
        title = "dash_studio_cooldown_title",
        titleFallback = "Cooldown Studio",
        desc = "dash_studio_cooldown_desc",
        descFallback = "Full-screen cooldown bar editor: layout, style, spells, visibility and presets.",
        open = "dash_studio_cooldown_open",
        openFallback = "Open Cooldown Studio",
        callback = OpenCooldownStudio,
    },
    {
        addon = "TomoMod_MythicPlus",
        title = "dash_studio_mythic_title",
        titleFallback = "Mythic+ Studio",
        desc = "dash_studio_mythic_desc",
        descFallback = "Configure Mythic+ tracking, score, run history, keys, widgets and dungeon elements.",
        open = "dash_studio_mythic_open",
        openFallback = "Open Mythic+ Studio",
        callback = OpenMythicPlusStudio,
    },
    {
        addon = "TomoMod_GroupStudio",
        title = "dash_studio_group_title",
        titleFallback = "Party & Raid Studio",
        desc = "dash_studio_group_desc",
        descFallback = "Configure PartyFrames, RaidFrames and healer indicators with real-time visual previews.",
        open = "dash_studio_group_open",
        openFallback = "Open Party & Raid Studio",
        callback = OpenGroupStudio,
    },
    {
        addon = "TomoMod_HealerStudio",
        title = "dash_studio_healer_title",
        titleFallback = "Healer Studio",
        desc = "dash_studio_healer_desc",
        descFallback = "Configure HoTs, shields and healing indicators on PartyFrames and RaidFrames.",
        open = "dash_studio_healer_open",
        openFallback = "Open Healer Studio",
        callback = OpenHealerStudio,
    },
    {
        addon = "TomoMod_AstralForge",
        title = "dash_studio_astral_title",
        titleFallback = "Astral Forge Studio",
        desc = "dash_studio_astral_desc",
        descFallback = "Advanced creation and editing studio for UnitFrame and Nameplate elements, with layout tools and visual customisation.",
        open = "dash_studio_astral_open",
        openFallback = "Open Astral Forge Studio",
        callback = OpenAstralForgeStudio,
    },
}

local STUDIO_TILE_H = 122
local STUDIO_GAP    = 10

local function GetStudioStatus(def)
    if def.comingSoon then
        return Localize("dash_studio_status_soon", "Coming soon"), GD[1], GD[2], GD[3]
    end

    -- _Suite.lua already owns the reliable installed-state detector. It
    -- enumerates addons by index because GetAddOnInfo("missing-name") echoes
    -- the requested name and therefore cannot be used as a presence test.
    local state = TomoMod_Suite and TomoMod_Suite.State
        and TomoMod_Suite.State(def.addon) or "loaded"
    if state == "absent" then
        return Localize("dash_studio_status_missing", "Not installed"),
               DM[1], DM[2], DM[3]
    end
    return Localize("dash_studio_status_available", "Available"),
           0.30, 0.85, 0.55
end

local function CreateStudioTile(grid, def)
    local tile = CreateFrame("Frame", nil, grid, "BackdropTemplate")
    tile:SetHeight(STUDIO_TILE_H)
    SetPanelBackdrop(tile, A[1], A[2], A[3], 0.72)

    local bar = tile:CreateTexture(nil, "ARTWORK")
    bar:SetWidth(3)
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("BOTTOMLEFT", 1, 1)
    bar:SetColorTexture(A[1], A[2], A[3], 0.95)

    local title = tile:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_BOLD, 12, "")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetPoint("RIGHT", -112, 0)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    title:SetText(Localize(def.title, def.titleFallback))
    title:SetTextColor(A[1], A[2], A[3], 1)

    local statusText, sr, sg, sb = GetStudioStatus(def)
    local status = tile:CreateFontString(nil, "OVERLAY")
    status:SetFont(FONT_BOLD, 8, "")
    status:SetPoint("TOPRIGHT", -12, -14)
    status:SetText(statusText)
    status:SetTextColor(sr, sg, sb, 1)

    local desc = tile:CreateFontString(nil, "OVERLAY")
    desc:SetFont(FONT, 9, "")
    desc:SetPoint("TOPLEFT", 14, -34)
    desc:SetPoint("TOPRIGHT", -14, -34)
    desc:SetHeight(42)
    desc:SetJustifyH("LEFT")
    desc:SetJustifyV("TOP")
    desc:SetWordWrap(true)
    desc:SetText(Localize(def.desc, def.descFallback))
    desc:SetTextColor(DM[1], DM[2], DM[3], 1)

    local btn = CreateFrame("Button", nil, tile, "BackdropTemplate")
    btn:SetHeight(28)
    btn:SetPoint("BOTTOMLEFT", 14, 12)
    btn:SetPoint("BOTTOMRIGHT", -14, 12)
    SetPanelBackdrop(btn, A[1], A[2], A[3], 0.82)

    local bt = btn:CreateFontString(nil, "OVERLAY")
    bt:SetFont(FONT_BOLD, 10, "")
    bt:SetPoint("CENTER")
    bt:SetText(Localize(def.open, def.openFallback))
    bt:SetTextColor(1, 1, 1, 1)

    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(A[1] * 0.18, A[2] * 0.18, A[3] * 0.18, 0.95)
        btn:SetBackdropBorderColor(A[1], A[2], A[3], 0.9)
        bt:SetTextColor(A[1], A[2], A[3], 1)
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(0.045, 0.042, 0.065, 0.82)
        btn:SetBackdropBorderColor(A[1], A[2], A[3], 0.38)
        bt:SetTextColor(1, 1, 1, 1)
    end)
    btn:SetScript("OnClick", function()
        if def.callback then def.callback() end
    end)

    return tile
end

local function LayoutStudioGrid(grid)
    local tiles = grid._tiles
    if not tiles then return end
    local width = grid:GetWidth() or 0
    if width < 2 then return end

    local tileW = math.max(180, math.floor((width - STUDIO_GAP) / 2))
    for i = 1, #tiles do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local tile = tiles[i]
        tile:ClearAllPoints()
        tile:SetPoint("TOPLEFT", grid, "TOPLEFT",
            col * (tileW + STUDIO_GAP),
            -row * (STUDIO_TILE_H + STUDIO_GAP))
        tile:SetWidth(tileW)
    end
end

local function CreateStudiosHub(parent, y)
    local card, cy = W.CreateCard(parent,
        Localize("dash_studios_section", "TomoMod Studios"), y)

    local _, ny = W.CreateInfoText(card.inner,
        Localize("dash_studios_info",
            "Advanced visual editors for the main TomoMod systems."), cy)
    cy = ny

    local rows = math.ceil(#STUDIO_DEFS / 2)
    local gridH = STUDIO_TILE_H * rows + STUDIO_GAP * math.max(0, rows - 1)
    local grid = CreateFrame("Frame", nil, card.inner)
    grid:SetPoint("TOPLEFT", 12, cy - 2)
    grid:SetPoint("TOPRIGHT", -12, cy - 2)
    grid:SetHeight(gridH)

    local tiles = {}
    for i = 1, #STUDIO_DEFS do
        tiles[i] = CreateStudioTile(grid, STUDIO_DEFS[i])
    end
    grid._tiles = tiles
    grid:SetScript("OnSizeChanged", LayoutStudioGrid)
    grid:SetScript("OnShow", LayoutStudioGrid)
    LayoutStudioGrid(grid)

    cy = cy - gridH - 10
    return W.FinalizeCard(card, cy)
end

-- =====================================================================
-- PRESET CARDS
-- All the display data (icon, role colour, name, tagline, highlights,
-- description) comes from Config/Presets.lua — this only renders it.
-- Handlers are hoisted to module scope: OnSizeChanged fires on every
-- config window resize, so no closure is allocated per event.
-- =====================================================================
local PRESET_COLS   = 3
local PRESET_GAP    = 10
local PRESET_CARD_H = 136

local function LayoutPresetGrid(grid)
    local cards = grid._cards
    if not cards or #cards == 0 then return end
    local total = grid:GetWidth() or 0
    if total < 1 then return end        -- not sized yet; OnSizeChanged retries
    local cardW = math.floor((total - PRESET_GAP * (PRESET_COLS - 1)) / PRESET_COLS)
    if cardW < 100 then cardW = 100 end
    for i = 1, #cards do
        local card = cards[i]
        local col  = (i - 1) % PRESET_COLS
        local row  = math.floor((i - 1) / PRESET_COLS)
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", grid, "TOPLEFT",
            col * (cardW + PRESET_GAP),
            -row * (PRESET_CARD_H + PRESET_GAP))
        card:SetWidth(cardW)
    end
end

local function OnPresetGridResize(self)
    LayoutPresetGrid(self)
end

local function SetPresetCardState(card, active)
    local c = card._color
    card._active = active
    if active then
        card:SetBackdropColor(c[1] * 0.16, c[2] * 0.16, c[3] * 0.16, 0.95)
        card:SetBackdropBorderColor(c[1], c[2], c[3], 0.95)
        card._bar:SetAlpha(1)
        card._badge:SetText(Localize("preset_badge_active", "Actif"))
        card._badge:SetTextColor(c[1], c[2], c[3], 1)
        card._badge:Show()
    else
        card:SetBackdropColor(0.045, 0.042, 0.065, 0.88)
        card:SetBackdropBorderColor(c[1], c[2], c[3], 0.34)
        card._bar:SetAlpha(0.55)
        if card._recommended then
            card._badge:SetText(Localize("preset_badge_recommended", "Recommandé"))
            card._badge:SetTextColor(DM[1], DM[2], DM[3], 1)
            card._badge:Show()
        else
            card._badge:Hide()
        end
    end
end

local function RefreshPresetGrid(grid)
    if not (grid and grid._cards) then return end
    local active = TomoMod_Presets and TomoMod_Presets.GetActive
        and TomoMod_Presets.GetActive() or nil
    for i = 1, #grid._cards do
        local card = grid._cards[i]
        SetPresetCardState(card, card._presetKey == active)
    end
end

local function OnPresetCardEnter(self)
    local c = self._color
    self:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    if not self._active then
        self:SetBackdropColor(c[1] * 0.10, c[2] * 0.10, c[3] * 0.10, 0.95)
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self._presetName, c[1], c[2], c[3])
    if self._presetDesc then
        GameTooltip:AddLine(self._presetDesc, 0.80, 0.80, 0.86, true)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(Localize("dash_apply_preset_btn", "Appliquer ce preset"), A[1], A[2], A[3])
    GameTooltip:Show()
end

local function OnPresetCardLeave(self)
    SetPresetCardState(self, self._active)
    GameTooltip:Hide()
end

local function OnPresetCardClick(self)
    if not (TomoMod_Presets and TomoMod_Presets.Apply) then return end
    if not TomoMod_Presets.Apply(self._presetKey) then return end
    RefreshPresetGrid(self:GetParent())
    StaticPopup_Show("TOMOMOD_DASH_RELOAD")
end

local function CreatePresetCard(grid, def)
    local c = def.color or { A[1], A[2], A[3] }

    local card = CreateFrame("Button", nil, grid, "BackdropTemplate")
    card:SetSize(200, PRESET_CARD_H)
    card:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    card._presetKey   = def.key
    card._presetName  = def.name
    card._presetDesc  = def.desc
    card._recommended = def.recommended
    card._color       = c

    local bar = card:CreateTexture(nil, "ARTWORK")
    bar:SetWidth(3)
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("BOTTOMLEFT", 1, 1)
    bar:SetColorTexture(c[1], c[2], c[3], 1)
    card._bar = bar

    local wash = card:CreateTexture(nil, "BACKGROUND", nil, -1)
    wash:SetPoint("TOPLEFT", 1, -1)
    wash:SetPoint("BOTTOMRIGHT", -1, 1)
    if wash.SetGradientAlpha then
        wash:SetGradientAlpha("HORIZONTAL", c[1], c[2], c[3], 0.12, 0, 0, 0, 0)
    else
        wash:SetColorTexture(c[1], c[2], c[3], 0.07)
    end

    local icon = card:CreateTexture(nil, "OVERLAY")
    icon:SetSize(30, 30)
    icon:SetPoint("TOPLEFT", 14, -12)
    icon:SetTexture(def.icon)
    icon:SetVertexColor(c[1], c[2], c[3], 1)

    local name = card:CreateFontString(nil, "OVERLAY")
    name:SetFont(FONT_BOLD, 13, "")
    name:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    name:SetText(def.name)
    name:SetTextColor(c[1], c[2], c[3], 1)

    local badge = card:CreateFontString(nil, "OVERLAY")
    badge:SetFont(FONT_BOLD, 8, "")
    badge:SetPoint("TOPRIGHT", -10, -12)
    badge:Hide()
    card._badge = badge

    local tag = card:CreateFontString(nil, "OVERLAY")
    tag:SetFont(FONT, 9, "")
    tag:SetPoint("TOPLEFT", 14, -48)
    tag:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    tag:SetJustifyH("LEFT")
    tag:SetWordWrap(false)
    tag:SetText(def.tagline or "")
    tag:SetTextColor(DM[1], DM[2], DM[3], 1)

    local hl = def.highlights
    if hl then
        local hy = -64
        for i = 1, #hl do
            local dot = card:CreateTexture(nil, "ARTWORK")
            dot:SetSize(3, 3)
            dot:SetPoint("TOPLEFT", 16, hy - 5)
            dot:SetColorTexture(c[1], c[2], c[3], 0.85)

            local txt = card:CreateFontString(nil, "OVERLAY")
            txt:SetFont(FONT, 9, "")
            txt:SetPoint("TOPLEFT", 25, hy)
            txt:SetPoint("RIGHT", card, "RIGHT", -10, 0)
            txt:SetJustifyH("LEFT")
            txt:SetJustifyV("TOP")
            txt:SetHeight(20)
            txt:SetSpacing(1)
            txt:SetText(hl[i])
            txt:SetTextColor(TX[1], TX[2], TX[3], 0.72)

            hy = hy - 22
        end
    end

    card:SetScript("OnEnter", OnPresetCardEnter)
    card:SetScript("OnLeave", OnPresetCardLeave)
    card:SetScript("OnClick", OnPresetCardClick)

    return card
end

local function CreateProfileOptions()
    local profOpts, active = {}, GetActiveProfile()
    if TomoMod_Profiles then
        local order = TomoMod_Profiles.GetProfileList()
        for _, name in ipairs(order or {}) do
            profOpts[#profOpts + 1] = { text = name, value = name }
        end
    end
    if #profOpts == 0 then profOpts[1] = { text = active, value = active } end
    return profOpts, active
end

-- =====================================================================
-- RESOLUTION PRESET
-- Core/ResolutionPresets.lua shipped with a full engine, a bench and six
-- locales, but no way in beyond /tm resolution. This is the entry point.
--
-- Placed before the archetype grid on purpose: the type sizes a preset
-- writes are the ground the role presets then build on, so choosing the
-- screen first and the role second is the order that does not undo work.
-- =====================================================================

local function ResolutionSummary(RES)
    local pw, ph = RES.PhysicalSize()
    local detected = RES.Detect()
    if not ph then
        return Localize("respreset_unknown", "Résolution indisponible."), detected
    end
    return string.format(
        Localize("respreset_detected_fmt", "Écran %sx%s — palier détecté : %s"),
        tostring(pw), tostring(ph), detected), detected
end

local function CreateResolution(parent, y)
    local RES = TomoMod_Resolution
    -- The engine lives in the base addon; the options addon must not
    -- assume it loaded.
    if not RES or not RES.Tiers then return y end

    local card, cy = W.CreateCard(parent,
        Localize("respreset_section", "Résolution"), y)

    local summary, detected = ResolutionSummary(RES)
    local _, sy = W.CreateInfoText(card.inner, summary, cy)
    cy = sy

    local opts, floored = {}, {}
    for _, t in ipairs(RES.Tiers()) do
        local d = RES.DescribeTier(t.key)
        local label = Localize(t.label, t.key)
        if d and d.hasCapture then
            -- Un glyphe encode en octets Lua ne se dessine pas dans toutes
            -- les polices : il sortait en carre vide. Un mot traduit ne peut
            -- pas manquer a l'appel.
            label = label .. "  |cff00ff00"
                .. Localize("respreset_capture_tag", "capture") .. "|r"
        end
        -- Tiers are listed tallest first by the engine; the control reads
        -- better the other way round.
        table.insert(opts, 1, { text = label, value = t.key })
        if d and d.floored then floored[t.key] = true end
    end

    local current = RES.Applied() or detected
    local _, ry = W.CreateSegmentedControl(card.inner,
        Localize("respreset_choose", "Palier"), opts, current, cy, function(v)
            local rep = RES.Apply(v)
            if not rep or not rep.ok then return end
            print("|cff2e9dd8TomoMod|r " .. string.format(
                Localize("respreset_applied_fmt", "Palier %s appliqué (%d polices, %d ancres)."),
                v, rep.fonts or 0, rep.stamped or 0))
            if rep.floored then
                print("  |cff888888" .. Localize("res_floored", "") .. "|r")
            end
            StaticPopup_Show("TOMOMOD_DASH_RELOAD")
        end, 3)
    cy = ry

    if floored[detected] then
        local _, fy = W.CreateInfoText(card.inner, Localize("res_floored", ""), cy)
        cy = fy
    end

    local _, capY = W.CreateButton(card.inner,
        Localize("respreset_capture", "Capturer ma disposition"), 240, cy, function()
            local tier = RES.Detect()
            local okCap = RES.Capture(tier)
            print("|cff2e9dd8TomoMod|r " .. (okCap
                and string.format(Localize("respreset_capture_ok", "Disposition capturée pour %s."), tier)
                or  Localize("respreset_capture_fail", "Capture impossible.")))
            if TomoMod_Config and TomoMod_Config.InvalidatePanels then
                TomoMod_Config.InvalidatePanels()
            end
        end)
    cy = capY

    if RES.HasCapture(detected) then
        local _, clrY = W.CreateButton(card.inner,
            Localize("respreset_capture_clear", "Effacer la capture"), 240, cy, function()
                RES.ClearCapture(detected)
                print("|cff2e9dd8TomoMod|r " .. string.format(
                    Localize("respreset_capture_cleared", "Capture effacée pour %s."), detected))
                if TomoMod_Config and TomoMod_Config.InvalidatePanels then
                    TomoMod_Config.InvalidatePanels()
                end
            end)
        cy = clrY
    end

    local _, infoY = W.CreateInfoText(card.inner,
        Localize("respreset_info",
            "Une capture prime toujours sur les valeurs calculées : réglez votre interface, puis capturez."),
        cy)
    cy = infoY

    return W.FinalizeCard(card, cy)
end

local function CreateQuickConfig(parent, y)
    local list = {}
    if TomoMod_Presets and TomoMod_Presets.GetList then
        for _, def in ipairs(TomoMod_Presets.GetList()) do
            -- "custom" writes nothing: it only makes sense inside the
            -- installer flow, not as a one-click dashboard tile.
            if not def.custom then list[#list + 1] = def end
        end
    end

    local hintText = Localize("dash_apply_preset_info",
        "Appliquer un preset propose ensuite un rechargement.")

    if #list == 0 then
        -- Presets.lua failed to load: say so rather than fake a tile.
        local panel, nextY = CreatePanel(parent,
            Localize("dash_quickcfg_section", "Configuration rapide"),
            y, 76, A[1], A[2], A[3])
        local hint = panel:CreateFontString(nil, "OVERLAY")
        hint:SetFont(FONT, 10, "")
        hint:SetPoint("TOPLEFT", 18, -40)
        hint:SetPoint("RIGHT", -18, 0)
        hint:SetJustifyH("LEFT")
        hint:SetText(hintText)
        hint:SetTextColor(DM[1], DM[2], DM[3], 1)
        return nextY
    end

    local rows   = math.ceil(#list / PRESET_COLS)
    local gridH  = rows * PRESET_CARD_H + (rows - 1) * PRESET_GAP
    local panel, nextY = CreatePanel(parent,
        Localize("dash_quickcfg_section", "Configuration rapide"),
        y, 36 + gridH + 30, A[1], A[2], A[3])

    local grid = CreateFrame("Frame", nil, panel)
    grid:SetPoint("TOPLEFT",  16, -34)
    grid:SetPoint("TOPRIGHT", -16, -34)
    grid:SetHeight(gridH)

    local cards = {}
    for i = 1, #list do
        cards[i] = CreatePresetCard(grid, list[i])
    end
    grid._cards = cards

    grid:SetScript("OnSizeChanged", OnPresetGridResize)
    LayoutPresetGrid(grid)
    RefreshPresetGrid(grid)

    local hint = panel:CreateFontString(nil, "OVERLAY")
    hint:SetFont(FONT, 10, "")
    hint:SetPoint("BOTTOMLEFT", 18, 10)
    hint:SetPoint("RIGHT", -18, 0)
    hint:SetJustifyH("LEFT")
    hint:SetText(hintText)
    hint:SetTextColor(DM[1], DM[2], DM[3], 1)

    return nextY
end

function TomoMod_ConfigPanel_Accueil(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -12

    y = CreateHero(c, y)
    y = CreateQuickActions(c, y)
    y = CreateModules(c, y)
    y = CreateStudiosHub(c, y)
    -- Carte partagée (Config/Panels/_Suite.lua), en version compacte : le
    -- tableau de bord est une vue de synthèse. Placée AVANT Maintenance, qui
    -- contient la réinitialisation totale et doit rester la dernière chose lue.
    y = TomoMod_Suite.CreateCard(c, y, true)
    y = CreateResolution(c, y)
    y = CreateQuickConfig(c, y)

    local card3, py = W.CreateCard(c, Localize("dash_profile_section", "Profil"), y)
    local profOpts, active = CreateProfileOptions()
    local _, profileY = W.CreateDropdown(card3.inner, Localize("dash_active_profile", "Profil actif"), profOpts, active, py, function(v)
        if TomoMod_Profiles and v and v ~= TomoMod_Profiles.GetActiveProfileName() then
            TomoMod_Profiles.LoadNamedProfile(v)
            StaticPopup_Show("TOMOMOD_DASH_RELOAD")
        end
    end)
    py = profileY
    local _, manageY = W.CreateButton(card3.inner, Localize("dash_manage_profiles", "Gérer les profils"), 220, py, function()
        if TomoMod_Config and TomoMod_Config.OpenCategory then
            TomoMod_Config.OpenCategory("profiles")
        end
    end)
    py = manageY
    local _, profileInfoY = W.CreateInfoText(card3.inner, Localize("dash_profile_info", "Changer de profil recharge l'interface."), py)
    py = profileInfoY
    y = W.FinalizeCard(card3, py)

    local card4, my = W.CreateCard(c, Localize("dash_maint_section", "Maintenance"), y)
    local _, resetY = W.CreateButton(card4.inner, L["btn_reset_all"] or "Réinitialiser tout", 220, my, function()
        StaticPopup_Show("TOMOMOD_DASH_RESET")
    end)
    my = resetY
    local _, resetInfoY = W.CreateInfoText(card4.inner, L["info_reset_all"] or "Réinitialise tous les paramètres et recharge l'UI.", my)
    my = resetInfoY
    y = W.FinalizeCard(card4, my)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

StaticPopupDialogs["TOMOMOD_DASH_RELOAD"] = {
    text     = Localize("dash_reload_popup", "Recharger l'interface maintenant ?"),
    button1  = Localize("popup_confirm", "Confirmer"),
    button2  = Localize("popup_cancel", "Annuler"),
    OnAccept = function() ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["TOMOMOD_DASH_RESET"] = {
    text     = Localize("popup_reset_text", "Réinitialiser tous les paramètres ?"),
    button1  = Localize("popup_confirm", "Confirmer"),
    button2  = Localize("popup_cancel", "Annuler"),
    OnAccept = function() TomoMod_ResetDatabase(); ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

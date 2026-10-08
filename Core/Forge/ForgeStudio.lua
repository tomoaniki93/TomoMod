-- =====================================================================
-- TomoMod Forge -- Studio (L2)
-- Shell factory for dedicated editor windows (Cooldown Studio today,
-- the UnitFrames studio tomorrow): window chrome, header with optional
-- selector dropdown, sidebar (title + list host + action host), content
-- host, footer buttons and hint. The consumer keeps its own list
-- rendering, tabs and business wiring -- the factory only owns the
-- chrome so every studio looks and behaves the same.
-- Uses TomoMod_Widgets, resolved lazily (Forge loads before Config).
-- =====================================================================

local Forge = TomoMod_Forge
if not Forge then return end

Forge.Studio = Forge.Studio or {}

local WHITE8 = "Interface\\Buttons\\WHITE8x8"

-- ---------------------------------------------------------------------
-- Options hand-off
--
-- Studios replace the main options window while they are open. Every Studio
-- must hide Options, even when its frame already exists or it was opened by
-- another entry point. Most shells restore the GUI when they close; Cooldown
-- Studio opts out because its established close flow owns the reload prompt.
-- ---------------------------------------------------------------------
-- Studio widgets come from the Options widget kit, whose builders
-- self-register into the /tm global search under the current build
-- context. That context still names the last /tm category (usually Home),
-- so a studio built under it filled the index with entries that sent the
-- player back to that page. Neutralise it whenever a studio builds or shows.
local function ClearSearchBuildContext()
    local W = TomoMod_Widgets
    if W and W.SetBuildContext then W.SetBuildContext(nil, nil) end
end
Forge.Studio.ClearSearchBuildContext = ClearSearchBuildContext

function Forge.Studio.CaptureConfigReturn(frame, returnToConfig)
    if not frame then return false end
    ClearSearchBuildContext()
    frame._tomoStudioReturnToConfig = returnToConfig ~= false and true or nil
    if TomoMod_Config and TomoMod_Config.Hide then
        TomoMod_Config.Hide()
    end
    return true
end

function Forge.Studio.RestoreConfigAfterClose(frame)
    if not (frame and frame._tomoStudioReturnToConfig) then return false end
    if frame._tomoStudioTransientHide then return false end

    frame._tomoStudioReturnToConfig = nil
    C_Timer.After(0, function()
        -- Hide/Show transitions used by an editor must keep ownership until
        -- the player really closes the Studio.
        if frame:IsShown() then
            frame._tomoStudioReturnToConfig = true
            return
        end
        if TomoMod_Config and TomoMod_Config.Show then
            TomoMod_Config.Show()
        end
    end)
    return true
end

-- ---------------------------------------------------------------------
-- LoadOnDemand launcher
--
-- Studios ship as sibling LoadOnDemand addons, so every failure the client
-- can report has to become something the player can act on. LoadAddOn
-- returns a locale-independent token: "DISABLED" means the folder is
-- installed but unticked in the addon list, "MISSING" means it is genuinely
-- absent -- two very different fixes that a single catch-all message
-- conflates. The client localises the reason itself through
-- _G["ADDON_"..token]; what it never says is what to DO about it.
-- ---------------------------------------------------------------------

-- Hints and launcher messages, in all six languages. They live in the base
-- addon because a studio can be launched (EditMode gear, healer frames)
-- before the Options addon is loaded.
local REASON_KEY = {
    MISSING               = "studio_reason_missing",
    DISABLED              = "studio_reason_disabled",
    DEP_DISABLED          = "studio_reason_dep_disabled",
    DEP_MISSING           = "studio_reason_dep_missing",
    INTERFACE_VERSION     = "studio_reason_outdated",
    DEP_INTERFACE_VERSION = "studio_reason_dep_outdated",
    CORRUPT               = "studio_reason_corrupt",
    DEP_CORRUPT           = "studio_reason_dep_corrupt",
    BANNED                = "studio_reason_banned",
    NOT_DEMAND_LOADED     = "studio_reason_not_lod",
    DEMAND_LOADED         = "studio_reason_not_lod",
    INSECURE              = "studio_reason_insecure",
}

if TomoMod_RegisterLocale then
    local STUDIO_LOCALES = {
        enUS = {
            ["studio_reason_missing"]      = "the %s folder is missing from Interface/AddOns. It installs next to TomoMod, never inside it.",
            ["studio_reason_disabled"]     = "the sub-addon is unticked in the addon list. Tick it, then reload the interface.",
            ["studio_reason_dep_disabled"] = "a dependency of the studio is unticked in the addon list.",
            ["studio_reason_dep_missing"]  = "a dependency of the studio is missing.",
            ["studio_reason_outdated"]     = "the studio is flagged out of date for this game version. Tick \"Load out of date AddOns\" on the character selection screen.",
            ["studio_reason_dep_outdated"] = "a dependency of the studio is flagged out of date for this game version.",
            ["studio_reason_corrupt"]      = "the studio files are damaged. Reinstall TomoMod.",
            ["studio_reason_dep_corrupt"]  = "a dependency of the studio is damaged.",
            ["studio_reason_banned"]       = "the studio is blocked by the client.",
            ["studio_reason_not_lod"]      = "the studio is not flagged LoadOnDemand.",
            ["studio_reason_insecure"]     = "the studio was refused by the client.",
            ["studio_msg_enabled_reload"]  = "%s enabled. Reload the interface (/reload) to open it.",
            ["studio_msg_unavailable"]     = "%s unavailable: %s.",
            ["studio_msg_reason_unknown"]  = "unknown reason",
            ["studio_msg_not_initialized"] = "%s loaded but not initialised%s. Reload the interface (/reload).",
        },
        frFR = {
            ["studio_reason_missing"]      = "le dossier %s est absent de Interface/AddOns. Il s'installe à côté de TomoMod, jamais dedans.",
            ["studio_reason_disabled"]     = "le sous-addon est décoché dans la liste des addons. Coche-le, puis recharge l'interface.",
            ["studio_reason_dep_disabled"] = "une dépendance du studio est décochée dans la liste des addons.",
            ["studio_reason_dep_missing"]  = "une dépendance du studio est absente.",
            ["studio_reason_outdated"]     = "le studio est marqué obsolète pour cette version du jeu. Coche « Charger les AddOns obsolètes » à l'écran de sélection de personnage.",
            ["studio_reason_dep_outdated"] = "une dépendance du studio est marquée obsolète pour cette version du jeu.",
            ["studio_reason_corrupt"]      = "les fichiers du studio sont endommagés. Réinstalle TomoMod.",
            ["studio_reason_dep_corrupt"]  = "une dépendance du studio est endommagée.",
            ["studio_reason_banned"]       = "le studio est bloqué par le client.",
            ["studio_reason_not_lod"]      = "le studio n'est pas marqué LoadOnDemand.",
            ["studio_reason_insecure"]     = "le studio a été refusé par le client.",
            ["studio_msg_enabled_reload"]  = "%s activé. Recharge l'interface (/reload) pour l'ouvrir.",
            ["studio_msg_unavailable"]     = "%s indisponible : %s.",
            ["studio_msg_reason_unknown"]  = "raison inconnue",
            ["studio_msg_not_initialized"] = "%s chargé mais non initialisé%s. Recharge l'interface (/reload).",
        },
        deDE = {
            ["studio_reason_missing"]      = "der Ordner %s fehlt in Interface/AddOns. Er wird neben TomoMod installiert, nie darin.",
            ["studio_reason_disabled"]     = "das Unter-Addon ist in der Addon-Liste deaktiviert. Aktiviere es und lade die Oberflaeche neu.",
            ["studio_reason_dep_disabled"] = "eine Abhaengigkeit des Studios ist in der Addon-Liste deaktiviert.",
            ["studio_reason_dep_missing"]  = "eine Abhaengigkeit des Studios fehlt.",
            ["studio_reason_outdated"]     = "das Studio ist fuer diese Spielversion als veraltet markiert. Aktiviere \"Veraltete AddOns laden\" in der Charakterauswahl.",
            ["studio_reason_dep_outdated"] = "eine Abhaengigkeit des Studios ist fuer diese Spielversion als veraltet markiert.",
            ["studio_reason_corrupt"]      = "die Studio-Dateien sind beschaedigt. Installiere TomoMod neu.",
            ["studio_reason_dep_corrupt"]  = "eine Abhaengigkeit des Studios ist beschaedigt.",
            ["studio_reason_banned"]       = "das Studio wird vom Client blockiert.",
            ["studio_reason_not_lod"]      = "das Studio ist nicht als LoadOnDemand markiert.",
            ["studio_reason_insecure"]     = "das Studio wurde vom Client abgelehnt.",
            ["studio_msg_enabled_reload"]  = "%s aktiviert. Lade die Oberflaeche neu (/reload), um es zu oeffnen.",
            ["studio_msg_unavailable"]     = "%s nicht verfuegbar: %s.",
            ["studio_msg_reason_unknown"]  = "unbekannter Grund",
            ["studio_msg_not_initialized"] = "%s geladen, aber nicht initialisiert%s. Lade die Oberflaeche neu (/reload).",
        },
        esES = {
            ["studio_reason_missing"]      = "falta la carpeta %s en Interface/AddOns. Se instala junto a TomoMod, nunca dentro.",
            ["studio_reason_disabled"]     = "el subaddon está desmarcado en la lista de addons. Márcalo y recarga la interfaz.",
            ["studio_reason_dep_disabled"] = "una dependencia del estudio está desmarcada en la lista de addons.",
            ["studio_reason_dep_missing"]  = "falta una dependencia del estudio.",
            ["studio_reason_outdated"]     = "el estudio está marcado como obsoleto para esta versión del juego. Marca «Cargar addons obsoletos» en la pantalla de selección de personaje.",
            ["studio_reason_dep_outdated"] = "una dependencia del estudio está marcada como obsoleta para esta versión del juego.",
            ["studio_reason_corrupt"]      = "los archivos del estudio están dañados. Reinstala TomoMod.",
            ["studio_reason_dep_corrupt"]  = "una dependencia del estudio está dañada.",
            ["studio_reason_banned"]       = "el cliente bloquea el estudio.",
            ["studio_reason_not_lod"]      = "el estudio no está marcado como LoadOnDemand.",
            ["studio_reason_insecure"]     = "el cliente rechazó el estudio.",
            ["studio_msg_enabled_reload"]  = "%s activado. Recarga la interfaz (/reload) para abrirlo.",
            ["studio_msg_unavailable"]     = "%s no disponible: %s.",
            ["studio_msg_reason_unknown"]  = "motivo desconocido",
            ["studio_msg_not_initialized"] = "%s cargado pero no inicializado%s. Recarga la interfaz (/reload).",
        },
        itIT = {
            ["studio_reason_missing"]      = "la cartella %s manca in Interface/AddOns. Va installata accanto a TomoMod, mai al suo interno.",
            ["studio_reason_disabled"]     = "il sotto-addon è disattivato nell'elenco degli addon. Attivalo, poi ricarica l'interfaccia.",
            ["studio_reason_dep_disabled"] = "una dipendenza dello studio è disattivata nell'elenco degli addon.",
            ["studio_reason_dep_missing"]  = "manca una dipendenza dello studio.",
            ["studio_reason_outdated"]     = "lo studio è segnato come obsoleto per questa versione del gioco. Attiva \"Carica AddOn obsoleti\" nella schermata di selezione del personaggio.",
            ["studio_reason_dep_outdated"] = "una dipendenza dello studio è segnata come obsoleta per questa versione del gioco.",
            ["studio_reason_corrupt"]      = "i file dello studio sono danneggiati. Reinstalla TomoMod.",
            ["studio_reason_dep_corrupt"]  = "una dipendenza dello studio è danneggiata.",
            ["studio_reason_banned"]       = "lo studio è bloccato dal client.",
            ["studio_reason_not_lod"]      = "lo studio non è contrassegnato come LoadOnDemand.",
            ["studio_reason_insecure"]     = "lo studio è stato rifiutato dal client.",
            ["studio_msg_enabled_reload"]  = "%s attivato. Ricarica l'interfaccia (/reload) per aprirlo.",
            ["studio_msg_unavailable"]     = "%s non disponibile: %s.",
            ["studio_msg_reason_unknown"]  = "motivo sconosciuto",
            ["studio_msg_not_initialized"] = "%s caricato ma non inizializzato%s. Ricarica l'interfaccia (/reload).",
        },
        ptBR = {
            ["studio_reason_missing"]      = "a pasta %s não está em Interface/AddOns. Ela é instalada ao lado do TomoMod, nunca dentro dele.",
            ["studio_reason_disabled"]     = "o subaddon está desmarcado na lista de addons. Marque-o e recarregue a interface.",
            ["studio_reason_dep_disabled"] = "uma dependência do estúdio está desmarcada na lista de addons.",
            ["studio_reason_dep_missing"]  = "uma dependência do estúdio está ausente.",
            ["studio_reason_outdated"]     = "o estúdio está marcado como desatualizado para esta versão do jogo. Marque \"Carregar AddOns desatualizados\" na tela de seleção de personagem.",
            ["studio_reason_dep_outdated"] = "uma dependência do estúdio está marcada como desatualizada para esta versão do jogo.",
            ["studio_reason_corrupt"]      = "os arquivos do estúdio estão danificados. Reinstale o TomoMod.",
            ["studio_reason_dep_corrupt"]  = "uma dependência do estúdio está danificada.",
            ["studio_reason_banned"]       = "o estúdio está bloqueado pelo cliente.",
            ["studio_reason_not_lod"]      = "o estúdio não está marcado como LoadOnDemand.",
            ["studio_reason_insecure"]     = "o estúdio foi recusado pelo cliente.",
            ["studio_msg_enabled_reload"]  = "%s ativado. Recarregue a interface (/reload) para abri-lo.",
            ["studio_msg_unavailable"]     = "%s indisponível: %s.",
            ["studio_msg_reason_unknown"]  = "motivo desconhecido",
            ["studio_msg_not_initialized"] = "%s carregado, mas não inicializado%s. Recarregue a interface (/reload).",
        },
    }
    for locale, strings in pairs(STUDIO_LOCALES) do
        TomoMod_RegisterLocale(locale, strings)
    end
end

-- TomoMod_L returns the key itself for a missing entry: never show that.
local function T(key, fallback)
    local L = TomoMod_L
    local v = L and L[key]
    if v and v ~= key then return v end
    return fallback
end

function Forge.Studio.ReasonText(addon, reason)
    if not reason then return nil end
    local key   = REASON_KEY[reason]
    local hint  = key and T(key)
    local label = _G["ADDON_" .. reason]
    if hint then
        return (label and (label .. " - ") or "") .. hint:format(addon or "")
    end
    return label or reason
end

-- Pre-flight state used to decorate a launcher card. Never let a bad addon
-- name bubble an error up through a panel build.
function Forge.Studio.LoadReason(addon)
    if C_AddOns.IsAddOnLoaded(addon) then return nil end
    local ok, _, _, _, _, reason = pcall(C_AddOns.GetAddOnInfo, addon)
    if not ok then return nil end
    return reason
end

-- opts = { addon, global, label, arg }
-- Loads the sibling addon on demand and calls its Open(opts.arg). Returns
-- true when the window was actually asked to open. arg is optional and
-- forwarded verbatim: studios that open on a single subject ignore it,
-- studios that edit several profiles use it to pick one.
function Forge.Studio.Launch(opts)
    local addon  = opts and opts.addon
    local global = opts and opts.global
    local label  = (opts and opts.label) or addon or "Studio"
    local PREFIX = "|cff2e9dd8TomoMod|r : "
    if not addon or not global then return false end

    if not C_AddOns.IsAddOnLoaded(addon) then
        local ok, reason = C_AddOns.LoadAddOn(addon)

        -- Self-heal the overwhelmingly common case: installed but unticked.
        -- Enabling flips the client flag; the LoD load then succeeds straight
        -- away on most clients, and where it does not the enable still sticks
        -- so a single reload finishes the job.
        if not ok and reason == "DISABLED" and C_AddOns.EnableAddOn then
            pcall(C_AddOns.EnableAddOn, addon)
            ok, reason = C_AddOns.LoadAddOn(addon)
            if not ok then
                print(PREFIX .. string.format(T("studio_msg_enabled_reload",
                    "%s enabled. Reload the interface (/reload) to open it."), label))
                return false
            end
        end

        if not ok then
            print(PREFIX .. string.format(T("studio_msg_unavailable", "%s unavailable: %s."), label,
                Forge.Studio.ReasonText(addon, reason) or T("studio_msg_reason_unknown", "unknown reason")))
            return false
        end
    end

    -- LoadAddOn reported success but the entry point is missing: the
    -- sub-addon bailed out during its own load (they return early when
    -- TomoMod_Widgets is unavailable) and publish loadError to say why.
    -- Report it rather than swallowing the click.
    local S = _G[global]
    if not (S and S.Open) then
        local why = type(S) == "table" and S.loadError or nil
        print(PREFIX .. string.format(T("studio_msg_not_initialized",
            "%s loaded but not initialised%s. Reload the interface (/reload)."),
            label, why and (" (" .. tostring(why) .. ")") or ""))
        return false
    end

    if TomoMod_Config and TomoMod_Config.Hide then TomoMod_Config.Hide() end
    ClearSearchBuildContext()
    S.Open(opts.arg)
    return true
end

-- opts:
--   name          : global frame name (used for the frame handle)
--   title         : header title text (can contain color codes)
--   width, height : window size (default 1280x840)
--   sideWidth     : sidebar width (default 250)
--   titleH        : header height (default 52)
--   footerH       : footer height (default 44)
--   crudHeight    : sidebar action-host height (default 112)
--   accent        : {r,g,b} (default Forge.BRAND)
--   sidebarTitle  : small caps label above the list (default "ELEMENTS")
--   selector      : optional { label, options, get, set } header dropdown
--   footerButtons : array of { text, width, callback }
--   hint          : footer right-side hint text
-- Returns { frame, sidebarList, crudHost, contentHost }.
function Forge.Studio.CreateShell(opts)
    local W = TomoMod_Widgets
    opts = opts or {}
    local accent  = opts.accent or Forge.BRAND
    local PW      = opts.width or 1280
    local PH      = opts.height or 840
    local SIDE_W  = opts.sideWidth or 250
    local TITLE_H = opts.titleH or 52
    local FOOT_H  = opts.footerH or 44

    -- The requested size is a target, not a promise. SetClampedToScreen keeps
    -- a frame inside the screen but cannot shrink one that is larger than it,
    -- so a studio sized for a wide monitor loses its edges on a small one --
    -- and the sidebar buttons are the first thing off. Fit to UIParent, minus
    -- a margin so the border is never flush with the screen edge.
    local availW = UIParent and UIParent:GetWidth()  or PW
    local availH = UIParent and UIParent:GetHeight() or PH
    if availW and availW > 0 then PW = math.min(PW, math.floor(availW) - 24) end
    if availH and availH > 0 then PH = math.min(PH, math.floor(availH) - 24) end

    local frame = CreateFrame("Frame", opts.name, UIParent, "BackdropTemplate")
    frame:SetSize(PW, PH)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(100)
    frame:SetToplevel(true)
    frame:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    frame:SetBackdropColor(0.043, 0.047, 0.061, 1)
    frame:SetBackdropBorderColor(0.16, 0.18, 0.22, 1)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    -- Hide Options immediately for a newly-created (already shown) frame,
    -- then on every later Show for a reused shell. The close policy belongs
    -- to the shell so Cooldown Studio can retain its reload-only exit flow.
    local returnToConfig = opts.returnToConfig ~= false
    Forge.Studio.CaptureConfigReturn(frame, returnToConfig)
    frame:HookScript("OnShow", function(self)
        Forge.Studio.CaptureConfigReturn(self, returnToConfig)
    end)
    frame:HookScript("OnHide", function(self)
        Forge.Studio.RestoreConfigAfterClose(self)
    end)
    -- [fix] Close on Escape WITHOUT UISpecialFrames. Going through
    -- UISpecialFrames routes Escape via ToggleGameMenu, which calls the
    -- protected ClearTarget() and taints (ADDON_ACTION_FORBIDDEN). We
    -- capture Escape on the frame itself, consume it, and propagate every
    -- other key so game shortcuts keep working.
    frame:EnableKeyboard(true)
    frame:SetScript("OnKeyDown", function(self, key)
        -- SetPropagateKeyboardInput is a PROTECTED action: calling it during
        -- combat throws ADDON_ACTION_BLOCKED (fired on every keypress while the
        -- studio is open in combat). Guard it. In combat we simply let all keys
        -- propagate normally -- Escape won't close the studio then, which is
        -- fine: you shouldn't be reconfiguring cooldown bars mid-fight.
        if InCombatLockdown() then return end
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            self:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    -- Widgets built inside inherit the studio accent (FindDesign walks up
    -- to _muiDesign; without this they fall back to the default accent).
    if W and W.ApplyPanelContext then
        W.ApplyPanelContext(frame, { key = opts.name or "studio", label = opts.title, accent = accent })
    end

    -- Header
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(Forge.FONT_BOLD, 15, "")
    title:SetPoint("TOPLEFT", 18, -17)
    title:SetText(opts.title or "Studio")

    local selectorDropdown
    if opts.selector and W and W.CreateDropdown then
        local sel = opts.selector
        local host = CreateFrame("Frame", nil, frame)
        host:SetSize(300, 48)
        host:SetPoint("TOPLEFT", 200, -6)
        selectorDropdown = W.CreateDropdown(host, sel.label or "", sel.options or {},
            sel.get and sel.get() or nil, 0, function(v)
                if sel.set then sel.set(v) end
            end)
    end

    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(26, 26)
    closeBtn:SetPoint("TOPRIGHT", -10, -10)
    local ct = closeBtn:CreateFontString(nil, "OVERLAY")
    ct:SetFont(Forge.FONT_BOLD, 15, "")
    ct:SetPoint("CENTER", 0, 0)
    ct:SetText("X")
    ct:SetTextColor(0.5, 0.5, 0.55, 1)
    closeBtn:SetScript("OnEnter", function() ct:SetTextColor(1, 0.4, 0.4, 1) end)
    closeBtn:SetScript("OnLeave", function() ct:SetTextColor(0.5, 0.5, 0.55, 1) end)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    local function sep()
        local t = frame:CreateTexture(nil, "ARTWORK")
        t:SetColorTexture(0.14, 0.15, 0.19, 1)
        return t
    end
    local hsep = sep()
    hsep:SetPoint("TOPLEFT", 0, -TITLE_H)
    hsep:SetPoint("TOPRIGHT", 0, -TITLE_H)
    hsep:SetHeight(1)

    -- Sidebar
    local side = CreateFrame("Frame", nil, frame)
    side:SetPoint("TOPLEFT", 0, -TITLE_H - 1)
    side:SetPoint("BOTTOMLEFT", 0, FOOT_H)
    side:SetWidth(SIDE_W)

    local vsep = sep()
    vsep:SetPoint("TOPLEFT", SIDE_W, -TITLE_H)
    vsep:SetPoint("BOTTOMLEFT", SIDE_W, FOOT_H)
    vsep:SetWidth(1)

    local sideTitle = side:CreateFontString(nil, "OVERLAY")
    sideTitle:SetFont(Forge.FONT, 10, "")
    sideTitle:SetPoint("TOPLEFT", 12, -10)
    sideTitle:SetTextColor(0.42, 0.44, 0.5, 1)
    sideTitle:SetText(opts.sidebarTitle or "ELEMENTS")

    local crudH = opts.crudHeight or 112
    local sidebarList = CreateFrame("Frame", nil, side)
    sidebarList:SetPoint("TOPLEFT", 0, -26)
    sidebarList:SetPoint("BOTTOMRIGHT", 0, crudH + 6)

    local crudHost = CreateFrame("Frame", nil, side)
    crudHost:SetPoint("BOTTOMLEFT", 0, 4)
    crudHost:SetPoint("BOTTOMRIGHT", 0, 4)
    crudHost:SetHeight(crudH)

    -- Content host
    local contentHost = CreateFrame("Frame", nil, frame)
    contentHost:SetPoint("TOPLEFT", SIDE_W + 1, -TITLE_H - 1)
    contentHost:SetPoint("BOTTOMRIGHT", 0, FOOT_H)
    -- [fix] contentHost is created after the sidebar, so at equal frame
    -- level it would sit ON TOP of the sidebar CRUD buttons and swallow
    -- their clicks. Keep content below the sidebar so its buttons get input.
    contentHost:SetFrameLevel(frame:GetFrameLevel() + 1)
    side:SetFrameLevel(frame:GetFrameLevel() + 5)

    -- Footer
    local fsep = sep()
    fsep:SetPoint("BOTTOMLEFT", 0, FOOT_H)
    fsep:SetPoint("BOTTOMRIGHT", 0, FOOT_H)
    fsep:SetHeight(1)

    local fx = 14
    local footerButtons = {}
    for _, def in ipairs(opts.footerButtons or {}) do
        local b = CreateFrame("Button", nil, frame, "BackdropTemplate")
        b:SetSize(def.width or 180, 28)
        b:SetPoint("BOTTOMLEFT", fx, 8)
        b:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
        b:SetBackdropColor(0.07, 0.11, 0.09, 1)
        b:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.5)
        local bt = b:CreateFontString(nil, "OVERLAY")
        bt:SetFont(Forge.FONT_BOLD, 11, "")
        bt:SetPoint("CENTER")
        bt:SetTextColor(0.92, 0.95, 0.93, 1)
        bt:SetText(def.text or "")
        b:SetScript("OnClick", def.callback)
        footerButtons[#footerButtons + 1] = b
        fx = fx + (def.width or 180) + 10
    end

    local hint
    if opts.hint then
        hint = frame:CreateFontString(nil, "OVERLAY")
        hint:SetFont(Forge.FONT, 9, "")
        hint:SetPoint("BOTTOMRIGHT", -16, 16)
        hint:SetTextColor(0.36, 0.38, 0.44, 1)
        hint:SetText(opts.hint)
    end

    return {
        frame         = frame,
        side          = side,
        sideTitle     = sideTitle,
        sidebarList   = sidebarList,
        crudHost      = crudHost,
        contentHost   = contentHost,
        footerButtons = footerButtons,
        hint          = hint,
        selector      = selectorDropdown,
    }
end

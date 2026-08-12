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
        ["dash_mod_chatskin"]        = "Chat skin",
        ["dash_mod_bagskin"]         = "Bag skin",
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
        ["dash_mod_chatskin"]        = "Skin du chat",
        ["dash_mod_bagskin"]         = "Skin des sacs",
        ["dash_mod_mtracker"]        = "Suivi Mythic+",
        ["dash_mod_score"]           = "Score Mythic+",
        ["dash_toggle_on"]           = "Actif",
        ["dash_toggle_off"]          = "Off",
        ["dash_reload_popup"]        = "Recharger l'interface maintenant pour appliquer tes changements ?",
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
    { label = "dash_mod_chatskin",     tbl = "chatFrameSkin",    key = "enabled" },
    { label = "dash_mod_bagskin",      tbl = "bagSkin",          key = "enabled" },
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
    local db = EnsureDBTable(def.tbl)
    db[def.key] = value and true or false
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
        if TomoMod_Installer then
            TomoMod_Installer.Show()
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

-- Cooldown Studio shortcut.
--
-- The Studio is a LoadOnDemand sibling addon, so this cannot simply call a
-- function: it may not be in memory, may be disabled, or may be missing
-- from the folder entirely. The CooldownForge panel already owns that
-- dance and publishes it, so the dashboard delegates rather than keeping
-- a second copy of the load-and-self-heal logic that would drift.
local function OpenCooldownStudio()
    -- Defined at file scope in Panels/CooldownForge.lua, which the TOC loads
    -- before this one, so the guard is belt and braces rather than a real
    -- fallback path.
    if TomoMod_OpenCooldownStudio then TomoMod_OpenCooldownStudio() end
end

local function CreateStudioShortcut(parent, y)
    local card, cy = W.CreateCard(parent,
        Localize("dash_studio_section", "Cooldown Studio"), y)

    local _, ny = W.CreateInfoText(card.inner, Localize("dash_studio_info",
        "Editeur plein ecran des barres de cooldowns : disposition, style, "
        .. "sorts et visibilite."), cy)
    cy = ny

    local _, ny2 = W.CreateButton(card.inner,
        Localize("dash_studio_open", "Ouvrir le Cooldown Studio"), 240, cy,
        OpenCooldownStudio)
    cy = ny2

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
    -- Carte partagée (Config/Panels/_Suite.lua), en version compacte : le
    -- tableau de bord est une vue de synthèse. Placée AVANT Maintenance, qui
    -- contient la réinitialisation totale et doit rester la dernière chose lue.
    y = TomoMod_Suite.CreateCard(c, y, true)
    y = CreateQuickConfig(c, y)
    y = CreateStudioShortcut(c, y)

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

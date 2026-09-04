-- ============================================================
-- Installer.lua — Assistant d'installation « presets d'abord »
-- ------------------------------------------------------------
-- TomoMod 3.0
--
-- Flow :
--   1. Bienvenue
--   2. Choix d'archétype (cartes) -> applique un preset
--   3a. Si preset : Récap / Reload          (~3 écrans, 30 s)
--   3b. Si "Personnalisé" : 3 pages groupées (Cadres / Barres &
--       Skins / Mythic+ & Confort) -> Récap / Reload
--
-- S'appuie sur TomoMod_Presets (Config/Presets.lua) pour écrire
-- une configuration cohérente. La navigation opère sur une liste
-- `flow` reconstruite selon le chemin choisi (preset vs custom).
--
-- API publique conservée : INS.Show / INS.Hide / INS.Toggle
-- (référencées par Init.lua et Panels/General.lua).
-- ============================================================

TomoMod_Installer = TomoMod_Installer or {}
local INS = TomoMod_Installer
local P   = TomoMod_Presets

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local LOGO_TEX  = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Logo2.tga"
local ICON_PATH = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\icons\\"
local WHITE     = "Interface\\Buttons\\WHITE8x8"

-- ------------------------------------------------------------
-- LOCALES (nouvelles chaînes du flow v3 — FR + EN, autonome)
-- ------------------------------------------------------------
if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["ins_v3_welcome_desc"]      = "Welcome! This quick setup gets you a clean, complete interface in seconds.\n\nPick a setup that matches how you play — you can fine-tune everything afterwards from |cff2e9dd8/tm|r. Prefer to choose every option yourself? Pick |cffc89530Custom|r.",
        ["ins_pick_title"]           = "Choose your setup",
        ["ins_pick_subtitle"]        = "Select a play style below. Everything stays adjustable later via /tm.",
        ["ins_pick_recommended"]     = "Recommended",
        ["ins_custom_frames_title"]  = "Frames",
        ["ins_custom_barsskins_title"] = "Bars & Skins",
        ["ins_custom_mythicqol_title"] = "Mythic+ & Comfort",
        ["ins_custom_frames_intro"]  = "Enable the frames you want. Sensible options are pre-selected.",
        ["ins_custom_barsskins_intro"] = "Action bar skin and the visual skins for chat, bags, tooltips and more.",
        ["ins_custom_mythicqol_intro"] = "Mythic+ tools, interface extras, automations and sound.",
        ["ins_recap_title"]          = "All set",
        ["ins_recap_preset"]         = "Setup applied: |cff2e9dd8%s|r",
        ["ins_recap_custom"]         = "Your custom setup is ready",
        ["ins_recap_desc"]           = "Reload your interface to apply everything. You can reopen this assistant anytime with |cff2e9dd8/tm install|r, and open the full configuration panel with |cff2e9dd8/tm|r.",
    })
    TomoMod_RegisterLocale("frFR", {
        ["ins_v3_welcome_desc"]      = "Bienvenue ! Cet assistant rapide te prépare une interface propre et complète en quelques secondes.\n\nChoisis une configuration qui correspond à ta façon de jouer — tu pourras tout ajuster ensuite via |cff2e9dd8/tm|r. Tu préfères choisir chaque option toi-même ? Prends |cffc89530Personnalisé|r.",
        ["ins_pick_title"]           = "Choisis ta configuration",
        ["ins_pick_subtitle"]        = "Sélectionne un style de jeu ci-dessous. Tout reste ajustable ensuite via /tm.",
        ["ins_pick_recommended"]     = "Recommandé",
        ["ins_custom_frames_title"]  = "Cadres",
        ["ins_custom_barsskins_title"] = "Barres & Skins",
        ["ins_custom_mythicqol_title"] = "Mythic+ & Confort",
        ["ins_custom_frames_intro"]  = "Active les cadres que tu veux. Les options conseillées sont pré-cochées.",
        ["ins_custom_barsskins_intro"] = "Skin des barres d'action et skins visuels : chat, sacs, infobulles et plus.",
        ["ins_custom_mythicqol_intro"] = "Outils Mythic+, options d'interface, automatisations et son.",
        ["ins_recap_title"]          = "Tout est prêt",
        ["ins_recap_preset"]         = "Configuration appliquée : |cff2e9dd8%s|r",
        ["ins_recap_custom"]         = "Ta configuration personnalisée est prête",
        ["ins_recap_desc"]           = "Recharge ton interface pour tout appliquer. Tu peux rouvrir cet assistant à tout moment avec |cff2e9dd8/tm install|r, et ouvrir le panneau de configuration complet avec |cff2e9dd8/tm|r.",
    })
end

local L = TomoMod_L

-- Palette
local A  = { TomoMod_Utils.BRAND[1], TomoMod_Utils.BRAND[2], TomoMod_Utils.BRAND[3] }   -- teal accent
local AD = { TomoMod_Utils.BRAND_DARK[1], TomoMod_Utils.BRAND_DARK[2], TomoMod_Utils.BRAND_DARK[3] }   -- teal dark
local BG = { 0.07,  0.07,  0.09,  0.98 }
local BG2= { 0.10,  0.10,  0.13,  1    }
local BD = { 0.18,  0.18,  0.22,  1    }
local TX = { 0.88,  0.90,  0.89,  1    }
local DM = { 0.48,  0.48,  0.54,  1    }

-- Dimensions & chrome
local PANEL_W   = 820
local PANEL_H   = 600
local HEADER_H  = 50
local DOTS_H    = 22
local TITLE_H   = 40
local NAV_H     = 56
local SF_INSET  = 16
local CONTENT_W = PANEL_W - SF_INSET

-- State
local frame, dimmer
local contentHost
local pagePanels    = {}     -- pagePanels[key] = frame (cached)
local stepDots      = {}     -- pool of MAX_DOTS dot textures
local prevBtn, nextBtn, skipBtn, stepLabel
local MAX_DOTS      = 6

local selectedPreset = "complet"
local currentIndex   = 1

local FLOW_PRESET = { "welcome", "picker", "recap" }
local FLOW_CUSTOM = { "welcome", "picker", "custom_frames", "custom_barsskins", "custom_mythicqol", "recap" }
local flow = FLOW_PRESET

local function RebuildFlow()
    if selectedPreset == "custom" then flow = FLOW_CUSTOM else flow = FLOW_PRESET end
end

-- ============================================================
-- WIDGET HELPERS (légers, propres au look installeur)
-- ============================================================
local function Sec(parent, text, y)
    local strip = parent:CreateTexture(nil, "BACKGROUND")
    strip:SetHeight(24)
    strip:SetPoint("TOPLEFT",  8, y)
    strip:SetPoint("TOPRIGHT", -8, y)
    strip:SetColorTexture(A[1]*0.10, A[2]*0.10, A[3]*0.10, 1)
    local bar = parent:CreateTexture(nil, "ARTWORK")
    bar:SetWidth(3); bar:SetHeight(24)
    bar:SetPoint("TOPLEFT", 8, y)
    bar:SetColorTexture(A[1], A[2], A[3], 1)
    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_BOLD, 11, "")
    lbl:SetPoint("LEFT", strip, "LEFT", 6, 0)
    lbl:SetTextColor(A[1], A[2], A[3], 1)
    lbl:SetText(text)
    return y - 30
end

local function Info(parent, text, y)
    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 10, "")
    lbl:SetPoint("TOPLEFT",  12, y)
    lbl:SetPoint("TOPRIGHT", -12, y)
    lbl:SetJustifyH("LEFT")
    lbl:SetSpacing(2)
    lbl:SetTextColor(DM[1], DM[2], DM[3], 1)
    lbl:SetText(text)
    local rawH = lbl:GetStringHeight()
    local h    = tonumber(tostring(rawH)) or 12
    return y - (math.ceil(h / 12) * 14 + 8)
end

local function Cb(parent, text, val, y, cb)
    local f = CreateFrame("Button", nil, parent)
    f:SetSize(CONTENT_W - 28, 24); f:SetPoint("TOPLEFT", 14, y)
    local box = CreateFrame("Frame", nil, f, "BackdropTemplate")
    box:SetSize(14, 14); box:SetPoint("LEFT")
    box:SetBackdrop({ bgFile=WHITE, edgeFile=WHITE, edgeSize=1 })
    box:SetBackdropColor(BG2[1], BG2[2], BG2[3], 1)
    box:SetBackdropBorderColor(BD[1], BD[2], BD[3], 1)
    local tick = box:CreateTexture(nil, "OVERLAY")
    tick:SetPoint("TOPLEFT", 2, -2); tick:SetPoint("BOTTOMRIGHT", -2, 2)
    tick:SetColorTexture(A[1], A[2], A[3], 1)
    local lbl = f:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, ""); lbl:SetPoint("LEFT", box, "RIGHT", 8, 0)
    lbl:SetTextColor(TX[1], TX[2], TX[3], 1); lbl:SetText(text)
    local state = val
    local function Upd()
        if state then
            tick:Show()
            box:SetBackdropBorderColor(A[1], A[2], A[3], 0.80)
            box:SetBackdropColor(A[1]*0.12, A[2]*0.12, A[3]*0.12, 1)
        else
            tick:Hide()
            box:SetBackdropBorderColor(BD[1], BD[2], BD[3], 1)
            box:SetBackdropColor(BG2[1], BG2[2], BG2[3], 1)
        end
    end
    Upd()
    f:SetScript("OnEnter", function() lbl:SetTextColor(1, 1, 1, 1) end)
    f:SetScript("OnLeave", function() lbl:SetTextColor(TX[1], TX[2], TX[3], 1) end)
    f:SetScript("OnClick", function()
        state = not state; Upd()
        if cb then cb(state) end
    end)
    return f, y - 27
end

local function BigBtn(parent, text, y, clickCb, accent, width)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width or 260, 38); btn:SetPoint("TOP", 0, y)
    btn:SetBackdrop({ bgFile=WHITE, edgeFile=WHITE, edgeSize=1 })
    if accent then
        btn:SetBackdropColor(AD[1], AD[2], AD[3], 0.9); btn:SetBackdropBorderColor(A[1], A[2], A[3], 0.75)
    else
        btn:SetBackdropColor(BG2[1], BG2[2], BG2[3], 1); btn:SetBackdropBorderColor(BD[1], BD[2], BD[3], 1)
    end
    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_BOLD, 13, ""); lbl:SetPoint("CENTER"); lbl:SetText(text)
    lbl:SetTextColor(accent and 1 or TX[1], accent and 1 or TX[2], accent and 1 or TX[3], 1)
    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(A[1], A[2], A[3], 1); lbl:SetTextColor(0.05, 0.05, 0.07, 1)
    end)
    btn:SetScript("OnLeave", function()
        if accent then btn:SetBackdropColor(AD[1], AD[2], AD[3], 0.9); lbl:SetTextColor(1, 1, 1, 1)
        else btn:SetBackdropColor(BG2[1], BG2[2], BG2[3], 1); lbl:SetTextColor(TX[1], TX[2], TX[3], 1) end
    end)
    btn:SetScript("OnClick", function() if clickCb then clickCb() end end)
    return btn
end

-- ============================================================
-- DB helpers pour les pages personnalisées (path -> get/set)
-- ============================================================
local function dbGet(path, default)
    local node = TomoModDB
    for seg in string.gmatch(path, "[^.]+") do
        if type(node) ~= "table" then return default end
        node = node[seg]
    end
    if node == nil then return default end
    return node
end

local function dbSet(path, value)
    if P and P.SetPath then P.SetPath(TomoModDB, path, value) end
end

-- Checkbox liée à un seul chemin DB booléen
local function CbPath(parent, label, path, default, y)
    local f, ny = Cb(parent, label, dbGet(path, default) ~= false, y, function(v)
        dbSet(path, v)
    end)
    return f, ny
end

-- ============================================================
-- PAGE DEFINITIONS
-- pages[key] = { title, icon, build = function(c, p) ... return finalY end, onNext }
-- ============================================================
local pages = {}

-- ── Bienvenue ──────────────────────────────────────────────
pages.welcome = {
    title = L["ins_pick_title"],
    icon  = ICON_PATH .. "icon_general.tga",
    showStepTitle = false,
    build = function(c)
        local logo = c:CreateTexture(nil, "OVERLAY")
        logo:SetSize(60, 60); logo:SetPoint("TOP", 0, -18)
        logo:SetTexture(LOGO_TEX); logo:SetVertexColor(A[1], A[2], A[3], 1)

        local title = c:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT_BOLD, 20, ""); title:SetPoint("TOP", 0, -88)
        title:SetText("|cff2e9dd8Tomo|r|cffe8e8e8Mod|r  v" .. (C_AddOns.GetAddOnMetadata("TomoMod", "Version") or "?"))

        local sub = c:CreateFontString(nil, "OVERLAY")
        sub:SetFont(FONT, 12, ""); sub:SetPoint("TOP", 0, -116)
        sub:SetTextColor(DM[1], DM[2], DM[3], 1)
        sub:SetText(L["ins_subtitle"])

        local desc = c:CreateFontString(nil, "OVERLAY")
        desc:SetFont(FONT, 12, ""); desc:SetPoint("TOPLEFT", 50, -160); desc:SetPoint("TOPRIGHT", -50, -160)
        desc:SetJustifyH("LEFT"); desc:SetSpacing(4); desc:SetWordWrap(true)
        desc:SetTextColor(TX[1], TX[2], TX[3], 0.88)
        desc:SetText(L["ins_v3_welcome_desc"])

        return -320
    end,
}

-- ── Choix d'archétype (cartes) ─────────────────────────────
pages.picker = {
    title = L["ins_pick_title"],
    icon  = ICON_PATH .. "icon_general.tga",
    build = function(c, p)
        -- Sous-titre
        local sub = c:CreateFontString(nil, "OVERLAY")
        sub:SetFont(FONT, 11, ""); sub:SetPoint("TOPLEFT", 14, -6); sub:SetPoint("TOPRIGHT", -14, -6)
        sub:SetJustifyH("LEFT"); sub:SetTextColor(DM[1], DM[2], DM[3], 1)
        sub:SetText(L["ins_pick_subtitle"])

        -- Grille de cartes (2 colonnes)
        local list   = P and P.GetList() or {}
        local COLS   = 2
        local MARGIN = 14
        local GAP    = 12
        local CARD_W = math.floor((CONTENT_W - MARGIN*2 - GAP*(COLS-1)) / COLS)
        local CARD_H = 80
        local ROW_GAP= 10
        local startY = -32

        local cards = {}

        local rows    = math.ceil(#list / COLS)
        local gridH   = rows * CARD_H + (rows - 1) * ROW_GAP
        local descTop = startY - gridH - 14

        -- Boîte de description (sous la grille)
        local descBox = CreateFrame("Frame", nil, c, "BackdropTemplate")
        descBox:SetPoint("TOPLEFT", MARGIN, descTop)
        descBox:SetPoint("TOPRIGHT", -MARGIN, descTop)
        descBox:SetHeight(96)
        descBox:SetBackdrop({ bgFile=WHITE, edgeFile=WHITE, edgeSize=1 })
        descBox:SetBackdropColor(0.055, 0.055, 0.07, 1)
        descBox:SetBackdropBorderColor(BD[1], BD[2], BD[3], 1)

        local descTitle = descBox:CreateFontString(nil, "OVERLAY")
        descTitle:SetFont(FONT_BOLD, 12, ""); descTitle:SetPoint("TOPLEFT", 12, -10)
        descTitle:SetTextColor(A[1], A[2], A[3], 1)

        local descBody = descBox:CreateFontString(nil, "OVERLAY")
        descBody:SetFont(FONT, 11, "")
        descBody:SetPoint("TOPLEFT", 12, -30); descBody:SetPoint("BOTTOMRIGHT", -12, 8)
        descBody:SetJustifyH("LEFT"); descBody:SetJustifyV("TOP"); descBody:SetSpacing(3)
        descBody:SetWordWrap(true); descBody:SetTextColor(TX[1], TX[2], TX[3], 0.85)

        -- Sélection (visuel + état + flow + dots)
        local function Select(key)
            selectedPreset = key
            for _, card in ipairs(cards) do
                card:SetSelected(card.presetKey == key)
            end
            for _, def in ipairs(list) do
                if def.key == key then
                    descTitle:SetText(def.name)
                    descTitle:SetTextColor(def.color[1], def.color[2], def.color[3], 1)
                    descBody:SetText(def.desc)
                    break
                end
            end
            RebuildFlow()
            if INS._LayoutDots then INS._LayoutDots() end
        end
        p.Select = Select

        -- Fabrique une carte
        local function MakeCard(def, idx)
            local col = (idx - 1) % COLS
            local row = math.floor((idx - 1) / COLS)
            local x = MARGIN + col * (CARD_W + GAP)
            local y = startY - row * (CARD_H + ROW_GAP)

            local btn = CreateFrame("Button", nil, c, "BackdropTemplate")
            btn:SetSize(CARD_W, CARD_H); btn:SetPoint("TOPLEFT", x, y)
            btn:SetBackdrop({ bgFile=WHITE, edgeFile=WHITE, edgeSize=1 })
            btn.presetKey = def.key

            local accent = btn:CreateTexture(nil, "ARTWORK")
            accent:SetWidth(3); accent:SetPoint("TOPLEFT"); accent:SetPoint("BOTTOMLEFT")
            accent:SetColorTexture(def.color[1], def.color[2], def.color[3], 1)

            local ico = btn:CreateTexture(nil, "OVERLAY")
            ico:SetSize(38, 38); ico:SetPoint("LEFT", 16, 0)
            ico:SetTexture(def.icon)

            local name = btn:CreateFontString(nil, "OVERLAY")
            name:SetFont(FONT_BOLD, 14, ""); name:SetPoint("TOPLEFT", ico, "TOPRIGHT", 12, -2)
            name:SetText(def.name)

            local tag = btn:CreateFontString(nil, "OVERLAY")
            tag:SetFont(FONT, 10, ""); tag:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
            tag:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
            tag:SetJustifyH("LEFT"); tag:SetTextColor(DM[1], DM[2], DM[3], 1)
            tag:SetText(def.tagline)

            -- Badge "Recommandé"
            if def.recommended then
                local badge = CreateFrame("Frame", nil, btn, "BackdropTemplate")
                badge:SetSize(86, 16); badge:SetPoint("TOPRIGHT", -8, -8)
                badge:SetBackdrop({ bgFile=WHITE, edgeFile=WHITE, edgeSize=1 })
                badge:SetBackdropColor(A[1]*0.18, A[2]*0.18, A[3]*0.18, 1)
                badge:SetBackdropBorderColor(A[1], A[2], A[3], 0.6)
                local bt = badge:CreateFontString(nil, "OVERLAY")
                bt:SetFont(FONT_BOLD, 9, ""); bt:SetPoint("CENTER")
                bt:SetTextColor(A[1], A[2], A[3], 1); bt:SetText(L["ins_pick_recommended"])
            end

            local function SetSelected(sel)
                btn._selected = sel
                if sel then
                    btn:SetBackdropColor(def.color[1]*0.16, def.color[2]*0.16, def.color[3]*0.16, 1)
                    btn:SetBackdropBorderColor(def.color[1], def.color[2], def.color[3], 0.9)
                    name:SetTextColor(1, 1, 1, 1)
                    ico:SetVertexColor(1, 1, 1, 1)
                else
                    btn:SetBackdropColor(0.085, 0.085, 0.105, 1)
                    btn:SetBackdropBorderColor(BD[1], BD[2], BD[3], 1)
                    name:SetTextColor(0.86, 0.88, 0.87, 1)
                    ico:SetVertexColor(0.78, 0.78, 0.82, 1)
                end
            end
            btn.SetSelected = SetSelected

            btn:SetScript("OnEnter", function()
                if not btn._selected then
                    btn:SetBackdropBorderColor(def.color[1]*0.7, def.color[2]*0.7, def.color[3]*0.7, 0.8)
                end
            end)
            btn:SetScript("OnLeave", function() SetSelected(btn._selected) end)
            btn:SetScript("OnClick", function() Select(def.key) end)
            btn:SetScript("OnDoubleClick", function() Select(def.key); INS.Next() end)

            SetSelected(false)
            return btn
        end

        for i, def in ipairs(list) do
            cards[i] = MakeCard(def, i)
        end

        Select(selectedPreset or "complet")

        return descTop - 96 - 12
    end,
    onNext = function()
        if selectedPreset ~= "custom" and P and P.Apply then
            P.Apply(selectedPreset)
        end
    end,
}

-- ── Personnalisé : Cadres ──────────────────────────────────
pages.custom_frames = {
    title = L["ins_custom_frames_title"],
    icon  = ICON_PATH .. "icon_unitframes.tga",
    build = function(c)
        local y = -8
        y = Info(c, L["ins_custom_frames_intro"], y)

        y = Sec(c, L["ins_uf_section"], y)
        local _, ny = CbPath(c, L["ins_uf_enable"],        "unitFrames.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_uf_hide_blizzard"], "unitFrames.hideBlizzardFrames", true, y); y = ny

        y = Sec(c, L["ins_pf_section"], y)
        local _, ny = CbPath(c, L["ins_pf_enable"],         "partyFrames.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_pf_show_interrupt"], "partyFrames.showInterruptCD", true, y); y = ny
        local _, ny = CbPath(c, L["ins_pf_show_brez"],      "partyFrames.showBrezCD", true, y); y = ny

        y = Sec(c, L["ins_rf_section"], y)
        local _, ny = CbPath(c, L["ins_rf_enable"],          "raidFrames.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_rf_show_dispel"],     "raidFrames.showDispel", true, y); y = ny
        local _, ny = CbPath(c, L["ins_rf_show_hots"],       "raidFrames.showHoTs", true, y); y = ny
        local _, ny = CbPath(c, L["ins_rf_show_defensives"], "raidFrames.showDefensives", true, y); y = ny

        y = Sec(c, L["ins_cb_section"], y)
        local _, ny = CbPath(c, L["ins_cb_enable"],      "castbars.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_cb_class_color"], "castbars.useClassColor", true, y); y = ny

        y = Sec(c, L["ins_np_general"], y)
        local _, ny = CbPath(c, L["ins_np_enable"],       "nameplates.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_np_class_colors"], "nameplates.useClassColors", true, y); y = ny
        local _, ny = CbPath(c, L["ins_np_castbar"],      "nameplates.showCastbar", true, y); y = ny
        local _, ny = CbPath(c, L["ins_np_auras"],        "nameplates.showAuras", true, y); y = ny
        local _, ny = CbPath(c, L["ins_tank_enable_np"],  "nameplates.tankMode", false, y); y = ny

        y = Sec(c, L["ins_res_section"], y)
        local _, ny = CbPath(c, L["ins_res_enable"], "resourceBars.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_cdm_enable"], "cooldownManager.enabled", true, y); y = ny

        return y
    end,
}

-- ── Personnalisé : Barres & Skins ──────────────────────────
pages.custom_barsskins = {
    title = L["ins_custom_barsskins_title"],
    icon  = ICON_PATH .. "icon_skins.tga",
    build = function(c)
        local y = -8
        y = Info(c, L["ins_custom_barsskins_intro"], y)

        y = Sec(c, L["ins_ab_skin_section"], y)
        local _, ny = CbPath(c, L["ins_ab_system_enable"], "actionBars.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_ab_enable"],        "actionBarSkin.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_ab_class_color"],   "actionBarSkin.useClassColor", true, y); y = ny
        local _, ny = CbPath(c, L["ins_ab_shift_reveal"],  "actionBarSkin.shiftReveal", false, y); y = ny

        y = Sec(c, L["ins_skins_section"], y)
        local _, ny = CbPath(c, L["ins_skin_chat"],       "chatV4.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_skin_bag"],        "bagSkin.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_skin_tooltip"],    "tooltipSkin.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_skin_gamemenu"],   "gameMenuSkin.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_skin_character"],  "characterSkin.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_skin_objective"],  "objectiveTracker.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_skin_mail"],       "mailSkin.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_skin_reputation"], "reputationBar.enabled", true, y); y = ny

        return y
    end,
}

-- ── Personnalisé : Mythic+ & Confort ───────────────────────
pages.custom_mythicqol = {
    title = L["ins_custom_mythicqol_title"],
    icon  = ICON_PATH .. "icon_mythicplus.tga",
    build = function(c)
        local y = -8
        y = Info(c, L["ins_custom_mythicqol_intro"], y)

        y = Sec(c, L["ins_mplus_tracker_section"], y)
        local _, ny = CbPath(c, L["ins_mplus_tracker_enable"], "MythicTracker.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_mplus_score_enable"],   "TomoScore.enabled", true, y); y = ny

        y = Sec(c, L["ins_qol_interface_section"], y)
        local _, ny = CbPath(c, L["ins_qol_minimap"],          "minimap.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_qol_class_reminder"],   "classReminder.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_qol_waypoint"],         "waypoint.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_qol_afk"],              "afkDisplay.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_skyride_enable"],       "skyRide.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_qol_frame_anchors"],    "frameAnchors.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_qol_profession_helper"],"professionHelper.enabled", true, y); y = ny

        y = Sec(c, L["ins_qol_auto_section"], y)
        local _, ny = CbPath(c, L["ins_qol_fast_loot"],        "fastLoot.enabled", true, y); y = ny
        -- autoVendorRepair : 2 clés liées (vendre gris + réparer)
        local _, ny = Cb(c, L["ins_qol_auto_repair"],
            (dbGet("autoVendorRepair.sellGrays", true) ~= false) or (dbGet("autoVendorRepair.autoRepair", true) ~= false),
            y, function(v)
                dbSet("autoVendorRepair.sellGrays", v)
                dbSet("autoVendorRepair.autoRepair", v)
            end); y = ny
        local _, ny = CbPath(c, L["ins_qol_skip_cinematics"],   "cinematicSkip.enabled", true, y); y = ny
        local _, ny = CbPath(c, L["ins_qol_hide_talking_head"], "hideTalkingHead.enabled", false, y); y = ny
        local _, ny = CbPath(c, L["ins_qol_auto_accept"],       "autoAcceptInvite.enabled", false, y); y = ny
        local _, ny = CbPath(c, L["ins_qol_auto_summon"],       "autoSummon.enabled", false, y); y = ny
        local _, ny = CbPath(c, L["ins_qol_auto_fill_delete"],  "autoFillDelete.enabled", true, y); y = ny
        -- autoQuest : 2 clés liées (accept + turn-in)
        local _, ny = Cb(c, L["ins_qol_auto_quest"],
            (dbGet("autoQuest.autoAccept", false) ~= false),
            y, function(v)
                dbSet("autoQuest.autoAccept", v)
                dbSet("autoQuest.autoTurnIn", v)
            end); y = ny

        y = Sec(c, L["ins_sound_activation"], y)
        local _, ny = CbPath(c, L["ins_sound_enable"], "lustSound.enabled", true, y); y = ny

        return y
    end,
}

-- ── Récap / Reload ─────────────────────────────────────────
pages.recap = {
    title = L["ins_recap_title"],
    icon  = ICON_PATH .. "icon_general.tga",
    build = function(c, p)
        local logo = c:CreateTexture(nil, "OVERLAY")
        logo:SetSize(52, 52); logo:SetPoint("TOP", 0, -22)
        logo:SetTexture(LOGO_TEX); logo:SetVertexColor(A[1], A[2], A[3], 1)

        local check = c:CreateFontString(nil, "OVERLAY")
        check:SetFont(FONT_BOLD, 22, ""); check:SetPoint("TOP", 0, -86)
        check:SetTextColor(A[1], A[2], A[3], 1); check:SetText(L["ins_done_check"])

        local presetLbl = c:CreateFontString(nil, "OVERLAY")
        presetLbl:SetFont(FONT, 13, ""); presetLbl:SetPoint("TOP", 0, -120)
        presetLbl:SetTextColor(TX[1], TX[2], TX[3], 1)

        local desc = c:CreateFontString(nil, "OVERLAY")
        desc:SetFont(FONT, 11, ""); desc:SetPoint("TOPLEFT", 50, -152); desc:SetPoint("TOPRIGHT", -50, -152)
        desc:SetJustifyH("LEFT"); desc:SetSpacing(4); desc:SetWordWrap(true)
        desc:SetTextColor(TX[1], TX[2], TX[3], 0.82)
        desc:SetText(L["ins_recap_desc"])

        BigBtn(c, L["ins_done_reload"], -240, function()
            if TomoModDB and TomoModDB.installer then TomoModDB.installer.completed = true end
            ReloadUI()
        end, true, 280)

        -- Rafraîchit le libellé de preset à l'entrée
        p.Refresh = function()
            if selectedPreset == "custom" then
                presetLbl:SetText(L["ins_recap_custom"])
            else
                local def  = P and P.Get and P.Get(selectedPreset)
                local name = def and L["preset_" .. def.key .. "_name"] or selectedPreset
                presetLbl:SetText(string.format(L["ins_recap_preset"], name))
            end
        end

        return -300
    end,
}

-- ============================================================
-- PAGE PANEL FACTORY (conteneur scrollable + build)
-- ============================================================
local function GetOrBuildPage(key)
    if pagePanels[key] then return pagePanels[key] end

    local SCROLL_W, SCROLL_PAD = 5, 8
    local p = CreateFrame("Frame", nil, contentHost)
    p:Hide()
    p:SetAllPoints(contentHost)

    local track = p:CreateTexture(nil, "BACKGROUND")
    track:SetWidth(SCROLL_W)
    track:SetPoint("TOPRIGHT",    -SCROLL_PAD, -SCROLL_PAD)
    track:SetPoint("BOTTOMRIGHT", -SCROLL_PAD,  SCROLL_PAD)
    track:SetColorTexture(0.12, 0.12, 0.16, 0.70)
    track:Hide()

    local thumbF = CreateFrame("Frame", nil, p)
    thumbF:SetWidth(SCROLL_W)
    local thumbTex = thumbF:CreateTexture(nil, "OVERLAY")
    thumbTex:SetAllPoints(); thumbTex:SetColorTexture(A[1], A[2], A[3], 0.75)
    thumbF:Hide()

    local sf = CreateFrame("ScrollFrame", nil, p)
    sf:SetPoint("TOPLEFT", 0, 0)
    sf:SetPoint("BOTTOMRIGHT", -SF_INSET, 0)
    p._sf = sf

    local c = CreateFrame("Frame", nil, sf)
    c:SetWidth(CONTENT_W); c:SetHeight(1)
    sf:SetScrollChild(c)

    local finalY = pages[key] and pages[key].build and pages[key].build(c, p) or -10
    c:SetHeight(math.max(math.abs(finalY) + 20, 100))

    local function Upd()
        local sfH  = sf:GetHeight() or 0
        local cH   = c:GetHeight()  or 0
        local maxS = cH - sfH
        if maxS <= 0 then track:Hide(); thumbF:Hide(); return end
        track:Show(); thumbF:Show()
        local trkH  = sfH - 2 * SCROLL_PAD
        local ratio = sfH / cH
        local thH   = math.max(20, math.floor(trkH * ratio))
        thumbF:SetHeight(thH)
        local cur = sf:GetVerticalScroll()
        local thY = (maxS > 0) and (cur / maxS) * (trkH - thH) or 0
        thumbF:ClearAllPoints()
        thumbF:SetPoint("TOPRIGHT", p, "TOPRIGHT", -SCROLL_PAD, -(SCROLL_PAD + thY))
    end
    p._upd = Upd

    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * 36, self:GetVerticalScrollRange())))
        Upd()
    end)
    sf:SetScript("OnShow",        function(self) C_Timer.After(0, Upd) end)
    sf:SetScript("OnSizeChanged", function(self, w) if w and w > 10 then c:SetWidth(w) end; Upd() end)

    pagePanels[key] = p
    return p
end

-- ============================================================
-- CHROME UPDATE (dots, counter, step title, nav buttons)
-- ============================================================
function INS._LayoutDots()
    local n = #flow
    local DOT_SIZE, DOT_GAP = 9, 8
    local totalW = n * DOT_SIZE + (n - 1) * DOT_GAP
    local startX = (PANEL_W - totalW) / 2
    for i = 1, MAX_DOTS do
        local dot = stepDots[i]
        if not dot then break end
        if i <= n then
            dot:Show()
            dot:ClearAllPoints()
            dot:SetPoint("LEFT", dot:GetParent(), "LEFT", startX + (i-1)*(DOT_SIZE+DOT_GAP), 0)
            if i == currentIndex then
                dot:SetColorTexture(A[1], A[2], A[3], 1); dot:SetSize(11, 11)
            elseif i < currentIndex then
                dot:SetColorTexture(AD[1], AD[2], AD[3], 0.85); dot:SetSize(9, 9)
            else
                dot:SetColorTexture(BD[1], BD[2], BD[3], 1); dot:SetSize(9, 9)
            end
        else
            dot:Hide()
        end
    end
end

local function UpdateChrome()
    local key  = flow[currentIndex]
    local page = pages[key]

    INS._LayoutDots()

    if stepLabel then
        stepLabel:SetText(string.format(L["ins_step_counter"], currentIndex, #flow))
    end
    if frame._stepTitle then
        if page and page.showStepTitle == false then
            frame._stepTitle:SetText("")
            if frame._stepIcon then frame._stepIcon:Hide() end
        else
            frame._stepTitle:SetText(page and page.title or "")
            if frame._stepIcon then
                frame._stepIcon:Show()
                frame._stepIcon:SetTexture(page and page.icon)
                frame._stepIcon:SetVertexColor(A[1], A[2], A[3], 1)
            end
        end
    end

    prevBtn:SetShown(currentIndex > 1)

    local isRecap = (key == "recap")
    nextBtn:SetShown(not isRecap)
    skipBtn:SetShown(not isRecap)
    if not isRecap then
        local nextTxt = nextBtn:GetFontString()
        if nextTxt then
            local nextKey = flow[currentIndex + 1]
            nextTxt:SetText(nextKey == "recap" and L["ins_btn_finish"] or L["ins_btn_next"])
        end
    end
end

-- ============================================================
-- NAVIGATION
-- ============================================================
function INS.GoTo(index)
    if not frame then return end
    index = math.max(1, math.min(#flow, index))
    local key = flow[index]

    for _, p in pairs(pagePanels) do
        p:Hide()
        if p._sf then p._sf:SetVerticalScroll(0) end
    end

    local panel = GetOrBuildPage(key)
    panel:Show()
    currentIndex = index

    if key == "picker" and panel.Select  then panel.Select(selectedPreset) end
    if key == "recap"  and panel.Refresh then panel.Refresh() end

    if panel._upd then C_Timer.After(0, panel._upd) end
    UpdateChrome()
end

function INS.Next()
    local key  = flow[currentIndex]
    local page = pages[key]
    if page and page.onNext then page.onNext() end
    RebuildFlow()  -- onNext (picker) peut avoir changé selectedPreset
    INS.GoTo(currentIndex + 1)
end

function INS.Prev()
    INS.GoTo(currentIndex - 1)
end

-- ============================================================
-- FRAME CONSTRUCTION
-- ============================================================
local function BuildFrame()
    dimmer = CreateFrame("Frame", nil, UIParent)
    dimmer:SetFrameStrata("DIALOG")
    dimmer:SetAllPoints(UIParent)
    dimmer:EnableMouse(true)
    local dimTex = dimmer:CreateTexture(nil, "BACKGROUND")
    dimTex:SetAllPoints(); dimTex:SetColorTexture(0, 0, 0, 0.60)
    dimmer:Hide()

    frame = CreateFrame("Frame", "TomoModInstallerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(PANEL_W, PANEL_H)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(150)
    frame:SetBackdrop({ bgFile=WHITE, edgeFile=WHITE, edgeSize=2 })
    frame:SetBackdropColor(BG[1], BG[2], BG[3], BG[4])
    frame:SetBackdropBorderColor(A[1], A[2], A[3], 0.40)
    frame:SetMovable(true); frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    -- [fix] Escape captured by the window itself. Going through
    -- UISpecialFrames routes it via ToggleGameMenu, whose protected
    -- ClearTarget/SpellStopCasting calls are then refused once anything
    -- has tainted the path -- and the player can no longer quit.
    TomoMod_Utils.CloseOnEscape(_G["TomoModInstallerFrame"])

    -- ── HEADER ─────────────────────────────────────────────
    local hBar = CreateFrame("Frame", nil, frame)
    hBar:SetPoint("TOPLEFT"); hBar:SetPoint("TOPRIGHT"); hBar:SetHeight(HEADER_H)
    local hBg = hBar:CreateTexture(nil, "BACKGROUND")
    hBg:SetAllPoints(); hBg:SetColorTexture(0.05, 0.05, 0.065, 1)
    local hLine = frame:CreateTexture(nil, "ARTWORK")
    hLine:SetHeight(1); hLine:SetPoint("TOPLEFT", 0, -HEADER_H); hLine:SetPoint("TOPRIGHT", 0, -HEADER_H)
    hLine:SetColorTexture(A[1], A[2], A[3], 0.22)

    local hLogo = hBar:CreateTexture(nil, "OVERLAY")
    hLogo:SetSize(24, 24); hLogo:SetPoint("LEFT", 14, 0)
    hLogo:SetTexture(LOGO_TEX); hLogo:SetVertexColor(A[1], A[2], A[3], 1)
    local hTitle = hBar:CreateFontString(nil, "OVERLAY")
    hTitle:SetFont(FONT_BOLD, 14, ""); hTitle:SetPoint("LEFT", hLogo, "RIGHT", 8, 1)
    hTitle:SetText(L["ins_header_title"])

    stepLabel = hBar:CreateFontString(nil, "OVERLAY")
    stepLabel:SetFont(FONT, 10, ""); stepLabel:SetPoint("RIGHT", -42, 0)
    stepLabel:SetTextColor(DM[1], DM[2], DM[3], 1)

    -- Bouton fermer (= skip)
    local closeBtn = CreateFrame("Button", nil, hBar)
    closeBtn:SetSize(28, 28); closeBtn:SetPoint("RIGHT", -8, 0)
    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY")
    closeTxt:SetFont(FONT_BOLD, 20, ""); closeTxt:SetPoint("CENTER", 0, 1); closeTxt:SetText("×")
    closeTxt:SetTextColor(0.36, 0.36, 0.40, 1)
    closeBtn:SetScript("OnEnter", function() closeTxt:SetTextColor(0.90, 0.28, 0.28, 1) end)
    closeBtn:SetScript("OnLeave", function() closeTxt:SetTextColor(0.36, 0.36, 0.40, 1) end)
    closeBtn:SetScript("OnClick", function()
        if TomoModDB and TomoModDB.installer then TomoModDB.installer.completed = true end
        INS.Hide()
    end)

    -- ── DOTS ───────────────────────────────────────────────
    local dotHost = CreateFrame("Frame", nil, frame)
    dotHost:SetPoint("TOPLEFT", 0, -HEADER_H); dotHost:SetPoint("TOPRIGHT", 0, -HEADER_H); dotHost:SetHeight(DOTS_H)
    local dotBg = dotHost:CreateTexture(nil, "BACKGROUND")
    dotBg:SetAllPoints(); dotBg:SetColorTexture(0.07, 0.07, 0.09, 1)
    for i = 1, MAX_DOTS do
        local dot = dotHost:CreateTexture(nil, "OVERLAY")
        dot:SetSize(9, 9)
        dot:SetPoint("LEFT", dotHost, "LEFT", 0, 0)
        dot:SetColorTexture(BD[1], BD[2], BD[3], 1)
        dot:Hide()
        stepDots[i] = dot
    end

    -- ── STEP TITLE ─────────────────────────────────────────
    local stFrame = CreateFrame("Frame", nil, frame)
    stFrame:SetPoint("TOPLEFT", 0, -(HEADER_H + DOTS_H)); stFrame:SetPoint("TOPRIGHT", 0, -(HEADER_H + DOTS_H))
    stFrame:SetHeight(TITLE_H)
    local stBg = stFrame:CreateTexture(nil, "BACKGROUND")
    stBg:SetAllPoints(); stBg:SetColorTexture(0.052, 0.052, 0.066, 1)

    local stepIcon = stFrame:CreateTexture(nil, "OVERLAY")
    stepIcon:SetSize(22, 22); stepIcon:SetPoint("LEFT", 16, 0)
    frame._stepIcon = stepIcon
    local stepTitleLbl = stFrame:CreateFontString(nil, "OVERLAY")
    stepTitleLbl:SetFont(FONT_BOLD, 13, ""); stepTitleLbl:SetPoint("LEFT", stepIcon, "RIGHT", 10, 0)
    stepTitleLbl:SetTextColor(0.90, 0.92, 0.91, 1)
    frame._stepTitle = stepTitleLbl

    local stLine = frame:CreateTexture(nil, "ARTWORK")
    stLine:SetHeight(1)
    stLine:SetPoint("TOPLEFT", 0, -(HEADER_H + DOTS_H + TITLE_H)); stLine:SetPoint("TOPRIGHT", 0, -(HEADER_H + DOTS_H + TITLE_H))
    stLine:SetColorTexture(A[1], A[2], A[3], 0.15)

    -- ── CONTENT HOST ───────────────────────────────────────
    contentHost = CreateFrame("Frame", nil, frame)
    contentHost:SetPoint("TOPLEFT", 0, -(HEADER_H + DOTS_H + TITLE_H + 1))
    contentHost:SetPoint("BOTTOMRIGHT", 0, NAV_H)
    contentHost:SetClipsChildren(true)

    -- ── NAV BAR ────────────────────────────────────────────
    local navBar = CreateFrame("Frame", nil, frame)
    navBar:SetPoint("BOTTOMLEFT"); navBar:SetPoint("BOTTOMRIGHT"); navBar:SetHeight(NAV_H)
    local navBg = navBar:CreateTexture(nil, "BACKGROUND")
    navBg:SetAllPoints(); navBg:SetColorTexture(0.05, 0.05, 0.065, 1)
    local navLine = navBar:CreateTexture(nil, "ARTWORK")
    navLine:SetHeight(1); navLine:SetPoint("TOPLEFT"); navLine:SetPoint("TOPRIGHT")
    navLine:SetColorTexture(BD[1], BD[2], BD[3], 1)

    prevBtn = CreateFrame("Button", nil, navBar, "BackdropTemplate")
    prevBtn:SetSize(140, 32); prevBtn:SetPoint("LEFT", 16, 0)
    prevBtn:SetBackdrop({ bgFile=WHITE, edgeFile=WHITE, edgeSize=1 })
    prevBtn:SetBackdropColor(BG2[1], BG2[2], BG2[3], 1); prevBtn:SetBackdropBorderColor(BD[1], BD[2], BD[3], 1)
    local prevTxt = prevBtn:CreateFontString(nil, "OVERLAY")
    prevTxt:SetFont(FONT, 12, ""); prevTxt:SetPoint("CENTER"); prevTxt:SetText(L["ins_btn_prev"])
    prevTxt:SetTextColor(TX[1], TX[2], TX[3], 1)
    prevBtn:SetScript("OnEnter", function() prevBtn:SetBackdropBorderColor(A[1], A[2], A[3], 0.6); prevTxt:SetTextColor(A[1], A[2], A[3], 1) end)
    prevBtn:SetScript("OnLeave", function() prevBtn:SetBackdropBorderColor(BD[1], BD[2], BD[3], 1); prevTxt:SetTextColor(TX[1], TX[2], TX[3], 1) end)
    prevBtn:SetScript("OnClick", function() INS.Prev() end)

    nextBtn = CreateFrame("Button", nil, navBar, "BackdropTemplate")
    nextBtn:SetSize(160, 32); nextBtn:SetPoint("RIGHT", -16, 0)
    nextBtn:SetBackdrop({ bgFile=WHITE, edgeFile=WHITE, edgeSize=1 })
    nextBtn:SetBackdropColor(AD[1], AD[2], AD[3], 0.85); nextBtn:SetBackdropBorderColor(A[1], A[2], A[3], 0.7)
    local nextTxt = nextBtn:CreateFontString(nil, "OVERLAY")
    nextTxt:SetFont(FONT_BOLD, 12, ""); nextTxt:SetPoint("CENTER"); nextTxt:SetText(L["ins_btn_next"])
    nextTxt:SetTextColor(1, 1, 1, 1)
    nextBtn:SetScript("OnEnter", function() nextBtn:SetBackdropColor(A[1], A[2], A[3], 1); nextTxt:SetTextColor(0.05, 0.05, 0.07, 1) end)
    nextBtn:SetScript("OnLeave", function() nextBtn:SetBackdropColor(AD[1], AD[2], AD[3], 0.85); nextTxt:SetTextColor(1, 1, 1, 1) end)
    nextBtn:SetScript("OnClick", function() INS.Next() end)

    skipBtn = CreateFrame("Button", nil, navBar)
    skipBtn:SetSize(120, 20); skipBtn:SetPoint("CENTER")
    local skipTxt = skipBtn:CreateFontString(nil, "OVERLAY")
    skipTxt:SetFont(FONT, 10, ""); skipTxt:SetPoint("CENTER")
    skipTxt:SetTextColor(DM[1], DM[2], DM[3], 1); skipTxt:SetText(L["ins_btn_skip"])
    skipBtn:SetScript("OnEnter", function() skipTxt:SetTextColor(TX[1], TX[2], TX[3], 1) end)
    skipBtn:SetScript("OnLeave", function() skipTxt:SetTextColor(DM[1], DM[2], DM[3], 1) end)
    skipBtn:SetScript("OnClick", function()
        if TomoModDB and TomoModDB.installer then TomoModDB.installer.completed = true end
        INS.Hide()
    end)
end

-- ============================================================
-- PUBLIC API
-- ============================================================
function INS.Show()
    if not frame then BuildFrame() end
    -- Repart d'un état neuf : on reconstruit les pages depuis la DB
    -- actuelle (évite des cases en cache divergeant de la DB).
    for _, p in pairs(pagePanels) do p:Hide() end
    pagePanels = {}
    selectedPreset = "complet"
    RebuildFlow()
    dimmer:Show()
    frame:Show()
    INS.GoTo(1)
end

function INS.Hide()
    if dimmer then dimmer:Hide() end
    if frame  then frame:Hide()  end
end

function INS.Toggle()
    if frame and frame:IsShown() then INS.Hide() else INS.Show() end
end

-- First-run auto-opening is bootstrapped from Core/OptionsLoader.lua.
-- This file is LoadOnDemand and therefore cannot reliably own PLAYER_LOGIN.

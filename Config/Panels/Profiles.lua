-- =====================================
-- Panels/Profiles.lua — Gestion de profils (3 onglets)
-- Tab 1: Profils nommés (créer, renommer, dupliquer, assigner aux specs)
-- Tab 2: Import / Export — popup modal plein écran (pattern EllesmereUI)
-- Tab 3: Réinitialisations modules
-- =====================================

local W    = TomoMod_Widgets
local L    = TomoMod_L
local T    = W.Theme
local P    = TomoMod_Profiles
local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ACCENT    = T.accent       -- { r, g, b, a }
local BG        = T.bg
local BG_LIGHT  = T.bgLight
local BORDER    = T.border
local TEXT      = T.text
local TEXT_DIM  = T.textDim

-- =====================================
-- WIDGET HELPERS LOCAUX
-- =====================================

local function MkEditBox(parent, placeholder, width, yOff)
    local fr = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    fr:SetSize(width, 26)
    fr:SetPoint("TOPLEFT", 16, yOff)
    fr:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    fr:SetBackdropColor(0.06, 0.06, 0.08, 1)
    fr:SetBackdropBorderColor(unpack(BORDER))

    local eb = CreateFrame("EditBox", nil, fr)
    eb:SetAllPoints()
    eb:SetFont(FONT, 11, "")
    eb:SetTextColor(0.9, 0.9, 0.9)
    eb:SetAutoFocus(false)
    eb:SetTextInsets(8, 8, 4, 4)
    eb:SetMaxLetters(64)

    local ph = eb:CreateFontString(nil, "OVERLAY")
    ph:SetFont(FONT, 11, "")
    ph:SetPoint("LEFT", 8, 0)
    ph:SetTextColor(unpack(TEXT_DIM))
    ph:SetText(placeholder)
    eb:SetScript("OnTextChanged", function(self, u)
        if self:GetText() ~= "" then ph:Hide() else ph:Show() end
    end)
    eb:SetScript("OnEscapePressed",   function(self) self:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function() fr:SetBackdropBorderColor(unpack(ACCENT)) end)
    eb:SetScript("OnEditFocusLost",   function() fr:SetBackdropBorderColor(unpack(BORDER)) end)

    fr.editBox = eb
    return fr, yOff - 32
end

-- Petit bouton inline (pour actions sur les lignes de liste)
local function MkSmallBtn(parent, label, w, onClickFn, red)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w, 22)
    btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    btn:SetBackdropColor(red and 0.15 or BG_LIGHT[1], red and 0.05 or BG_LIGHT[2], red and 0.05 or BG_LIGHT[3], 0.9)
    btn:SetBackdropBorderColor(unpack(BORDER))

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 9, "")
    lbl:SetPoint("CENTER")
    if red then
        lbl:SetTextColor(T.red[1], T.red[2], T.red[3], T.red[4] or 1)
    else
        lbl:SetTextColor(TEXT[1], TEXT[2], TEXT[3], TEXT[4] or 1)
    end
    lbl:SetText(label)

    local hR = red and T.red[1] or ACCENT[1]
    local hG = red and T.red[2] or ACCENT[2]
    local hB = red and T.red[3] or ACCENT[3]
    btn:SetScript("OnEnter", function(b) b:SetBackdropBorderColor(hR, hG, hB) end)
    btn:SetScript("OnLeave", function(b) b:SetBackdropBorderColor(unpack(BORDER)) end)
    btn:SetScript("OnClick", onClickFn)
    return btn
end

-- =====================================
-- POPUP MODAL EXPORT/IMPORT (pattern EllesmereUI)
-- =====================================

local function ShowExportPopup(exportStr)
    -- Dimmer plein écran
    local dimmer = CreateFrame("Frame", nil, UIParent)
    dimmer:SetFrameStrata("FULLSCREEN_DIALOG")
    dimmer:SetAllPoints(UIParent)
    dimmer:EnableMouse(true)
    dimmer:EnableMouseWheel(true)
    dimmer:SetScript("OnMouseWheel", function() end)
    local dimTex = dimmer:CreateTexture(nil, "BACKGROUND")
    dimTex:SetAllPoints()
    dimTex:SetColorTexture(0, 0, 0, 0.55)

    -- Popup
    local pop = CreateFrame("Frame", nil, dimmer, "BackdropTemplate")
    pop:SetSize(560, 280)
    pop:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    pop:SetFrameStrata("FULLSCREEN_DIALOG")
    pop:SetFrameLevel(dimmer:GetFrameLevel() + 10)
    pop:EnableMouse(true)
    pop:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    pop:SetBackdropColor(0.05, 0.06, 0.08, 1)
    pop:SetBackdropBorderColor(unpack(ACCENT))

    -- Ligne accent haut
    local acc = pop:CreateTexture(nil, "OVERLAY")
    acc:SetHeight(2)
    acc:SetPoint("TOPLEFT"); acc:SetPoint("TOPRIGHT")
    acc:SetColorTexture(unpack(ACCENT))

    -- Titre
    local title = pop:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_BOLD, 15, "")
    title:SetPoint("TOPLEFT", 20, -18)
    title:SetTextColor(1, 1, 1)
    title:SetText(L["popup_export_title"] or "Exporter le Profil")

    local sub = pop:CreateFontString(nil, "OVERLAY")
    sub:SetFont(FONT, 10, "")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetTextColor(unpack(TEXT_DIM))
    sub:SetText(L["popup_export_hint"] or "Sélectionnez tout (Ctrl+A) et copiez (Ctrl+C)")

    -- EditBox scrollable
    local scrollBg = CreateFrame("Frame", nil, pop, "BackdropTemplate")
    scrollBg:SetPoint("TOPLEFT", 16, -68)
    scrollBg:SetPoint("BOTTOMRIGHT", -16, 52)
    scrollBg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    scrollBg:SetBackdropColor(0.03, 0.03, 0.04, 1)
    scrollBg:SetBackdropBorderColor(unpack(BORDER))

    local eb = CreateFrame("EditBox", nil, scrollBg)
    eb:SetAllPoints()
    eb:SetFont(FONT, 10, "")
    eb:SetTextColor(0.80, 0.95, 0.80, 1)
    eb:SetTextInsets(8, 8, 6, 6)
    eb:SetAutoFocus(false)
    eb:SetMultiLine(false)
    eb:SetText(exportStr or "")
    eb._readOnly = exportStr
    eb:SetScript("OnChar", function(self)
        if self._readOnly then self:SetText(self._readOnly); self:HighlightText() end
    end)
    eb:SetScript("OnTextChanged", function(self, u)
        if u and self._readOnly then self:SetText(self._readOnly); self:HighlightText() end
    end)
    eb:SetScript("OnMouseUp", function(self)
        C_Timer.After(0, function() self:SetFocus(); self:HighlightText() end)
    end)

    -- Fermer
    local closeBtn = CreateFrame("Button", nil, pop, "BackdropTemplate")
    closeBtn:SetSize(130, 30)
    closeBtn:SetPoint("BOTTOMRIGHT", pop, "BOTTOMRIGHT", -16, 12)
    closeBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    closeBtn:SetBackdropColor(BG_LIGHT[1], BG_LIGHT[2], BG_LIGHT[3], 0.9)
    closeBtn:SetBackdropBorderColor(unpack(BORDER))
    local closeLbl = closeBtn:CreateFontString(nil, "OVERLAY")
    closeLbl:SetFont(FONT_BOLD, 11, ""); closeLbl:SetPoint("CENTER")
    closeLbl:SetTextColor(unpack(TEXT)); closeLbl:SetText(L["btn_close"] or "Fermer")
    closeBtn:SetScript("OnEnter", function(b) b:SetBackdropBorderColor(unpack(ACCENT)) end)
    closeBtn:SetScript("OnLeave", function(b) b:SetBackdropBorderColor(unpack(BORDER)) end)
    closeBtn:SetScript("OnClick", function() dimmer:Hide() end)

    -- Fermer sur clic hors popup ou Escape
    dimmer:SetScript("OnMouseDown", function(s)
        if not pop:IsMouseOver() then s:Hide() end
    end)
    pop:EnableKeyboard(true)
    pop:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then self:SetPropagateKeyboardInput(false); dimmer:Hide()
        else self:SetPropagateKeyboardInput(true) end
    end)

    dimmer:Show()
    C_Timer.After(0.05, function() eb:SetFocus(); eb:HighlightText() end)
end

local function ShowImportPopup(onImport)
    local dimmer = CreateFrame("Frame", nil, UIParent)
    dimmer:SetFrameStrata("FULLSCREEN_DIALOG")
    dimmer:SetAllPoints(UIParent)
    dimmer:EnableMouse(true)
    dimmer:EnableMouseWheel(true)
    dimmer:SetScript("OnMouseWheel", function() end)
    local dimTex = dimmer:CreateTexture(nil, "BACKGROUND")
    dimTex:SetAllPoints()
    dimTex:SetColorTexture(0, 0, 0, 0.55)

    local pop = CreateFrame("Frame", nil, dimmer, "BackdropTemplate")
    pop:SetSize(560, 320)
    pop:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    pop:SetFrameStrata("FULLSCREEN_DIALOG")
    pop:SetFrameLevel(dimmer:GetFrameLevel() + 10)
    pop:EnableMouse(true)
    pop:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    pop:SetBackdropColor(0.05, 0.06, 0.08, 1)
    pop:SetBackdropBorderColor(unpack(ACCENT))

    local acc = pop:CreateTexture(nil, "OVERLAY")
    acc:SetHeight(2)
    acc:SetPoint("TOPLEFT"); acc:SetPoint("TOPRIGHT")
    acc:SetColorTexture(unpack(ACCENT))

    local title = pop:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_BOLD, 15, "")
    title:SetPoint("TOPLEFT", 20, -18)
    title:SetTextColor(1, 1, 1)
    title:SetText(L["popup_import_title"] or "Importer un Profil")

    local sub = pop:CreateFontString(nil, "OVERLAY")
    sub:SetFont(FONT, 10, "")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetTextColor(unpack(TEXT_DIM))
    sub:SetText(L["popup_import_hint"] or "Collez une chaîne d'export TomoMod, puis cliquez sur Importer")

    -- Preview
    local preview = pop:CreateFontString(nil, "OVERLAY")
    preview:SetFont(FONT, 10, "")
    preview:SetPoint("TOPLEFT", 20, -54)
    preview:SetPoint("RIGHT", -20, 0)
    preview:SetJustifyH("LEFT")
    preview:SetTextColor(unpack(TEXT_DIM))
    preview:SetText("")

    -- EditBox
    local scrollBg = CreateFrame("Frame", nil, pop, "BackdropTemplate")
    scrollBg:SetPoint("TOPLEFT", 16, -80)
    scrollBg:SetPoint("BOTTOMRIGHT", -16, 96)
    scrollBg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    scrollBg:SetBackdropColor(0.03, 0.03, 0.04, 1)
    scrollBg:SetBackdropBorderColor(unpack(BORDER))

    local eb = CreateFrame("EditBox", nil, scrollBg)
    eb:SetAllPoints()
    eb:SetFont(FONT, 10, "")
    eb:SetTextColor(0.80, 0.95, 0.80, 1)
    eb:SetTextInsets(8, 8, 6, 6)
    eb:SetAutoFocus(false)
    eb:SetMultiLine(false)
    eb:SetText("")
    eb:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        local txt = self:GetText()
        if txt and txt ~= "" then
            local meta = P.PreviewImport(txt)
            if meta then
                preview:SetText(
                    "|cff0cd29f✓|r " ..
                    (L["import_preview"] and string.format(L["import_preview"],
                        meta.class or "?", tostring(meta.moduleCount or 0), meta.date or "?")
                    or ("Classe : " .. (meta.class or "?") .. " · " .. tostring(meta.moduleCount or 0) .. " modules · " .. (meta.date or "?")))
                )
            else
                preview:SetText("|cffff4444✗|r " .. (L["import_preview_invalid"] or "Chaîne invalide"))
            end
        else
            preview:SetText("")
        end
    end)

    -- Nom du profil à créer
    local nameBox, _ = MkEditBox(pop, L["placeholder_import_profile_name"] or "Nom du profil...", 260, -230)
    nameBox:SetPoint("BOTTOMLEFT", pop, "BOTTOMLEFT", 16, 58)
    nameBox:ClearAllPoints()
    nameBox:SetPoint("BOTTOMLEFT", pop, "BOTTOMLEFT", 16, 58)

    local nameLbl = pop:CreateFontString(nil, "OVERLAY")
    nameLbl:SetFont(FONT, 10, "")
    nameLbl:SetPoint("BOTTOMLEFT", nameBox, "TOPLEFT", 0, 2)
    nameLbl:SetTextColor(unpack(TEXT_DIM))
    nameLbl:SetText(L["label_import_profile_name"] or "Sauvegarder sous le nom :")

    -- Boutons
    local cancelBtn = CreateFrame("Button", nil, pop, "BackdropTemplate")
    cancelBtn:SetSize(120, 30)
    cancelBtn:SetPoint("BOTTOMLEFT", pop, "BOTTOMLEFT", 16, 14)
    cancelBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    cancelBtn:SetBackdropColor(BG_LIGHT[1], BG_LIGHT[2], BG_LIGHT[3], 0.9)
    cancelBtn:SetBackdropBorderColor(unpack(BORDER))
    local cancelLbl = cancelBtn:CreateFontString(nil, "OVERLAY")
    cancelLbl:SetFont(FONT_BOLD, 11, ""); cancelLbl:SetPoint("CENTER")
    cancelLbl:SetTextColor(unpack(TEXT)); cancelLbl:SetText(L["btn_cancel"] or "Annuler")
    cancelBtn:SetScript("OnEnter", function(b) b:SetBackdropBorderColor(unpack(T.red)) end)
    cancelBtn:SetScript("OnLeave", function(b) b:SetBackdropBorderColor(unpack(BORDER)) end)
    cancelBtn:SetScript("OnClick", function() dimmer:Hide() end)

    local importBtn = CreateFrame("Button", nil, pop, "BackdropTemplate")
    importBtn:SetSize(160, 30)
    importBtn:SetPoint("BOTTOMRIGHT", pop, "BOTTOMRIGHT", -16, 14)
    importBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    importBtn:SetBackdropColor(ACCENT[1] * 0.2, ACCENT[2] * 0.2, ACCENT[3] * 0.2, 0.9)
    importBtn:SetBackdropBorderColor(unpack(ACCENT))
    local importLbl = importBtn:CreateFontString(nil, "OVERLAY")
    importLbl:SetFont(FONT_BOLD, 11, ""); importLbl:SetPoint("CENTER")
    importLbl:SetTextColor(unpack(ACCENT)); importLbl:SetText(L["btn_import"] or "Importer")
    importBtn:SetScript("OnEnter", function(b)
        b:SetBackdropColor(ACCENT[1] * 0.4, ACCENT[2] * 0.4, ACCENT[3] * 0.4, 0.9)
        importLbl:SetTextColor(1, 1, 1)
    end)
    importBtn:SetScript("OnLeave", function(b)
        b:SetBackdropColor(ACCENT[1] * 0.2, ACCENT[2] * 0.2, ACCENT[3] * 0.2, 0.9)
        importLbl:SetTextColor(unpack(ACCENT))
    end)
    importBtn:SetScript("OnClick", function()
        local str = eb:GetText()
        if not str or str == "" then
            preview:SetText("|cffff4444✗|r " .. (L["msg_import_empty"] or "Chaîne vide"))
            return
        end
        local profName = nameBox.editBox:GetText()
        if profName and not profName:match("^%s*$") then
            profName = profName:match("^%s*(.-)%s*$")
        else
            profName = nil
        end
        dimmer:Hide()
        if onImport then onImport(str, profName) end
    end)

    dimmer:SetScript("OnMouseDown", function(s)
        if not pop:IsMouseOver() then s:Hide() end
    end)
    pop:EnableKeyboard(true)
    pop:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then self:SetPropagateKeyboardInput(false); dimmer:Hide()
        else self:SetPropagateKeyboardInput(true) end
    end)

    dimmer:Show()
    C_Timer.After(0.05, function() eb:SetFocus() end)
end

-- =====================================
-- TAB 1 : PROFILS NOMMÉS + SPECS
-- =====================================

local function BuildProfileTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    P.EnsureProfilesDB()
    local order, named = P.GetProfileList()
    local activeName   = P.GetActiveProfileName()

    -- ── Profil actif ────────────────────────────────────────────────────────
    local _, ny = W.CreateSectionHeader(c, L["section_named_profiles"] or "Profils", y)
    y = ny

    local activeDisp = c:CreateFontString(nil, "OVERLAY")
    activeDisp:SetFont(FONT, 11, "")
    activeDisp:SetPoint("TOPLEFT", 16, y)
    activeDisp:SetTextColor(1, 1, 1)
    activeDisp:SetText((L["profile_active_label"] or "Profil actif") .. " : |cff0cd29f" .. activeName .. "|r")
    y = y - 22

    -- ── Liste des profils ────────────────────────────────────────────────────
    local _, ny = W.CreateSeparator(c, y); y = ny

    for _, name in ipairs(order) do
        if named[name] then
            local row = CreateFrame("Frame", nil, c)
            row:SetPoint("TOPLEFT", 10, y)
            row:SetPoint("RIGHT", -10, 0)
            row:SetHeight(30)

            -- Indicateur actif
            local dot = row:CreateFontString(nil, "OVERLAY")
            dot:SetFont(FONT_BOLD, 12, "")
            dot:SetPoint("LEFT", 0, 0)
            if name == activeName then
                dot:SetTextColor(unpack(ACCENT))
                dot:SetText(">>")
            else
                dot:SetTextColor(0.25, 0.25, 0.25)
                dot:SetText("  ")
            end

            local nameFS = row:CreateFontString(nil, "OVERLAY")
            nameFS:SetFont(FONT, 11, "")
            nameFS:SetPoint("LEFT", dot, "RIGHT", 6, 0)
            nameFS:SetTextColor(name == activeName and 1 or 0.80,
                                name == activeName and 1 or 0.80,
                                name == activeName and 1 or 0.80)
            nameFS:SetText(name)

            -- Spec badges (profils assignés à cette spec)
            local specBadge = row:CreateFontString(nil, "OVERLAY")
            specBadge:SetFont(FONT, 9, "")
            specBadge:SetPoint("LEFT", nameFS, "RIGHT", 8, 0)
            specBadge:SetTextColor(0.60, 0.75, 0.95)
            local badges = {}
            for specID, pName in pairs(TomoModDB._profiles.specProfiles) do
                if pName == name then
                    for _, s in ipairs(P.GetAllSpecs()) do
                        if s.id == specID then
                            badges[#badges + 1] = s.name; break
                        end
                    end
                end
            end
            if #badges > 0 then
                specBadge:SetText("[" .. table.concat(badges, ", ") .. "]")
            end

            -- Boutons inline (droite) — seulement si pas "Default" pour certains
            local btnX = -4
            if name ~= "Default" then
                -- Supprimer
                local delBtn = MkSmallBtn(row, L["btn_delete_profile"] or "Suppr.", 70, function()
                    StaticPopup_Show("TOMOMOD_DELETE_PROFILE", name, nil, { name = name })
                end, true)
                delBtn:SetPoint("RIGHT", btnX, 0); btnX = btnX - 76

                -- Renommer
                local renBtn = MkSmallBtn(row, L["btn_rename_profile"] or "Renommer", 80, function()
                    StaticPopup_Show("TOMOMOD_RENAME_PROFILE", name, nil, { name = name })
                end)
                renBtn:SetPoint("RIGHT", btnX, 0); btnX = btnX - 86
            end

            -- Dupliquer
            local dupBtn = MkSmallBtn(row, L["btn_duplicate_profile"] or "Dupliquer", 80, function()
                StaticPopup_Show("TOMOMOD_DUPLICATE_PROFILE", name, nil, { name = name })
            end)
            dupBtn:SetPoint("RIGHT", btnX, 0); btnX = btnX - 86

            -- Charger (si pas actif)
            if name ~= activeName then
                local loadBtn = MkSmallBtn(row, L["btn_load_profile"] or "Charger", 70, function()
                    local ok = P.LoadNamedProfile(name)
                    if ok then
                        print("|cff0cd29fTomoMod|r " .. string.format(L["msg_profile_loaded"] or "Profil '%s' chargé", name))
                        StaticPopup_Show("TOMOMOD_PROFILE_RELOAD")
                    end
                end)
                loadBtn:SetPoint("RIGHT", btnX, 0)
            end

            y = y - 34
        end
    end

    -- ── Créer un nouveau profil ──────────────────────────────────────────────
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_create_profile"] or "— Créer un Nouveau Profil —", y); y = ny

    local nameBox, ny = MkEditBox(c, L["placeholder_profile_name"] or "Nom du profil...", 260, y); y = ny

    local _, ny = W.CreateButton(c, L["btn_create_profile"] or "Créer le Profil", 180, y, function()
        local name = nameBox.editBox:GetText()
        if not name or name:match("^%s*$") then
            print("|cffff0000TomoMod|r " .. (L["msg_profile_name_empty"] or "Nom vide"))
            return
        end
        local ok, err = P.CreateNamedProfile(name)
        if ok then
            print("|cff0cd29fTomoMod|r " .. string.format(L["msg_profile_created"] or "Profil '%s' créé", name))
            nameBox.editBox:SetText("")
            nameBox.editBox:ClearFocus()
        else
            print("|cffff0000TomoMod|r " .. (err or "Erreur"))
        end
    end)
    y = ny

    nameBox.editBox:SetScript("OnEnterPressed", function(self)
        local name = self:GetText()
        if name and not name:match("^%s*$") then
            local ok = P.CreateNamedProfile(name)
            if ok then
                print("|cff0cd29fTomoMod|r " .. string.format(L["msg_profile_created"] or "Profil '%s' créé", name))
                self:SetText("")
            end
        end
        self:ClearFocus()
    end)

    -- Save courant
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateButton(c, L["btn_save_profile"] or "Sauvegarder le Profil Actif", 240, y, function()
        P.AutoSaveActiveProfile()
        print("|cff0cd29fTomoMod|r " .. string.format(L["msg_profile_saved"] or "Sauvegardé dans '%s'", activeName))
    end)
    y = ny
    local _, ny = W.CreateInfoText(c, L["info_save_profile"] or "Sauvegarde automatique à la fermeture du panneau.", y); y = ny

    -- ── Assignation Spec → Profil ────────────────────────────────────────────
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSectionHeader(c, L["section_spec_assign"] or "Profils par Spécialisation", y); y = ny
    local _, ny = W.CreateInfoText(c, L["info_spec_assign"] or "Associez chaque spécialisation à un profil nommé. TomoMod chargera le profil correspondant automatiquement.", y); y = ny

    local allSpecs = P.GetAllSpecs()
    local profileOptions = {}
    for _, n in ipairs(order) do
        if named[n] then
            table.insert(profileOptions, { text = n, value = n })
        end
    end
    -- Option "Aucun"
    table.insert(profileOptions, 1, { text = L["spec_profile_none"] or "— Aucun —", value = "" })

    for _, spec in ipairs(allSpecs) do
        local assigned = P.GetSpecAssignedProfile(spec.id) or ""
        local isCurrent = (spec.id == P.GetCurrentSpecID())

        local row = CreateFrame("Frame", nil, c, "BackdropTemplate")
        row:SetPoint("TOPLEFT", 10, y)
        row:SetPoint("RIGHT", -10, 0)
        row:SetHeight(36)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        row:SetBackdropColor(0.07, 0.07, 0.09, 0.6)
        row:SetBackdropBorderColor(unpack(BORDER))

        -- Icône spec
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(22, 22)
        icon:SetPoint("LEFT", 8, 0)
        icon:SetTexture(spec.icon)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- Nom de la spec
        local specNameFS = row:CreateFontString(nil, "OVERLAY")
        specNameFS:SetFont(FONT, 11, "")
        specNameFS:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        if isCurrent then
            specNameFS:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
        else
            specNameFS:SetTextColor(0.80, 0.80, 0.80)
        end
        local txt = spec.name
        if isCurrent then txt = txt .. " [actif]" end
        specNameFS:SetText(txt)

        -- ── Dropdown profil inline ────────────────────────────────────────────
        -- Bouton principal du dropdown
        local DROP_W = 200
        local dropBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        dropBtn:SetSize(DROP_W, 26)
        dropBtn:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        dropBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        dropBtn:SetBackdropColor(0.06, 0.06, 0.08, 1)
        dropBtn:SetBackdropBorderColor(unpack(BORDER))

        -- Trouver le texte affiché depuis la valeur
        local function GetOptDisplay(val)
            if val == "" then return L["spec_profile_none"] or "— Aucun —" end
            for _, opt in ipairs(profileOptions) do
                if opt.value == val then return opt.text end
            end
            return val
        end

        local dropLabel = dropBtn:CreateFontString(nil, "OVERLAY")
        dropLabel:SetFont(FONT, 10, "")
        dropLabel:SetPoint("LEFT", 8, 0)
        dropLabel:SetPoint("RIGHT", -18, 0)
        dropLabel:SetJustifyH("LEFT")
        dropLabel:SetTextColor(0.85, 0.85, 0.85)
        dropLabel:SetText(GetOptDisplay(assigned))

        local arrow = dropBtn:CreateFontString(nil, "OVERLAY")
        arrow:SetFont(FONT, 10, "")
        arrow:SetPoint("RIGHT", -6, 0)
        arrow:SetTextColor(unpack(TEXT_DIM))
        arrow:SetText("v")

        -- Menu déroulant
        local menu = CreateFrame("Frame", nil, dropBtn, "BackdropTemplate")
        menu:SetSize(DROP_W, #profileOptions * 22 + 4)
        menu:SetPoint("TOPLEFT", dropBtn, "BOTTOMLEFT", 0, -2)
        menu:SetFrameStrata("DIALOG")
        menu:SetFrameLevel(dropBtn:GetFrameLevel() + 10)
        menu:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        menu:SetBackdropColor(0.06, 0.07, 0.10, 1)
        menu:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.7)
        menu:Hide()

        for mi, opt in ipairs(profileOptions) do
            local item = CreateFrame("Button", nil, menu)
            item:SetSize(DROP_W - 4, 22)
            item:SetPoint("TOPLEFT", 2, -(mi - 1) * 22 - 2)

            local itemBg = item:CreateTexture(nil, "BACKGROUND")
            itemBg:SetAllPoints()
            itemBg:SetColorTexture(0, 0, 0, 0)

            local itemTxt = item:CreateFontString(nil, "OVERLAY")
            itemTxt:SetFont(FONT, 10, "")
            itemTxt:SetPoint("LEFT", 8, 0)
            itemTxt:SetTextColor(0.85, 0.85, 0.85)
            itemTxt:SetText(opt.text)

            item:SetScript("OnEnter", function()
                itemBg:SetColorTexture(ACCENT[1] * 0.15, ACCENT[2] * 0.15, ACCENT[3] * 0.15, 1)
                itemTxt:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
            end)
            item:SetScript("OnLeave", function()
                itemBg:SetColorTexture(0, 0, 0, 0)
                itemTxt:SetTextColor(0.85, 0.85, 0.85)
            end)
            item:SetScript("OnClick", function()
                local val = opt.value
                if val == "" then
                    P.UnassignSpec(spec.id)
                else
                    P.AssignSpecToProfile(spec.id, val)
                end
                dropLabel:SetText(GetOptDisplay(val))
                menu:Hide()
            end)
        end

        dropBtn:SetScript("OnEnter", function(b)
            b:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.8)
        end)
        dropBtn:SetScript("OnLeave", function(b)
            if not menu:IsShown() then b:SetBackdropBorderColor(unpack(BORDER)) end
        end)
        dropBtn:SetScript("OnClick", function(b)
            if menu:IsShown() then
                menu:Hide()
                b:SetBackdropBorderColor(unpack(BORDER))
            else
                -- Fermer tous les autres menus ouverts
                CloseDropDownMenus()
                menu:Show()
                b:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.8)
            end
        end)

        -- Fermer si clic ailleurs
        menu:SetScript("OnHide", function()
            dropBtn:SetBackdropBorderColor(unpack(BORDER))
        end)

        y = y - 42
    end

    local _, ny = W.CreateInfoText(c, L["info_spec_reload"] or "Le changement de spec recharge automatiquement le profil associé.", y); y = ny

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB 2 : IMPORT / EXPORT — Boutons → Popups modales
-- =====================================

local function BuildImportExportTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    -- Export
    local _, ny = W.CreateSectionHeader(c, L["section_export"] or "Exporter", y); y = ny
    local _, ny = W.CreateInfoText(c, L["info_export"] or "Crée une chaîne compressée de vos paramètres actuels. Partagez-la avec d'autres joueurs.", y); y = ny

    local _, ny = W.CreateButton(c, L["btn_export"] or "Exporter le Profil Actif", 240, y, function()
        P.AutoSaveActiveProfile()
        local str, err = P.Export()
        if str then
            ShowExportPopup(str)
        else
            print("|cffff0000TomoMod|r " .. (err or "Export échoué"))
        end
    end)
    y = ny

    -- Import
    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSectionHeader(c, L["section_import"] or "Importer", y); y = ny
    local _, ny = W.CreateInfoText(c, L["info_import"] or "Collez une chaîne d'export TomoMod. Vous pouvez la sauvegarder sous un nouveau nom de profil.", y); y = ny

    local _, ny = W.CreateButton(c, L["btn_import"] or "Importer un Profil...", 240, y, function()
        ShowImportPopup(function(str, profName)
            if profName and not profName:match("^%s*$") then
                -- Importer comme nouveau profil nommé
                profName = profName:match("^%s*(.-)%s*$")
                local ok, err = P.ImportAsProfile(str, profName)
                if ok then
                    print("|cff0cd29fTomoMod|r " .. string.format(L["msg_import_as_profile"] or "Importé sous '%s'", profName))
                    StaticPopup_Show("TOMOMOD_PROFILE_RELOAD")
                else
                    print("|cffff0000TomoMod|r " .. (err or "Import échoué"))
                end
            else
                -- Importer et écraser le profil actif
                StaticPopup_Show("TOMOMOD_IMPORT_CONFIRM", nil, nil, { text = str })
            end
        end)
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, "|cffff8800(!)|r " .. (L["info_import_warning"] or "L'import sans nom de profil remplace vos paramètres actuels."), y); y = ny

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- TAB 3 : RÉINITIALISATIONS
-- =====================================

local function BuildResetsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_reset_module"] or "Réinitialiser un Module", y); y = ny
    local _, ny = W.CreateInfoText(c, L["info_resets"] or "Réinitialise les paramètres d'un module aux valeurs par défaut.", y); y = ny

    local modules = {
        { key = "unitFrames",       label = "UnitFrames" },
        { key = "nameplates",       label = "Nameplates" },
        { key = "resourceBars",     label = "Resource Bars" },
        { key = "cooldownManager",  label = "Cooldown Manager" },
        { key = "minimap",          label = "Minimap" },
        { key = "infoPanel",        label = "Info Panel" },
        { key = "cursorRing",       label = "Cursor Ring" },
        { key = "skyRide",          label = "SkyRide" },
        { key = "autoQuest",        label = "Auto Quest" },
        { key = "autoAcceptInvite", label = "Auto Accept Invite" },
        { key = "autoSummon",       label = "Auto Summon" },
        { key = "autoFillDelete",   label = "Auto Fill Delete" },
        { key = "frameAnchors",     label = "Frame Anchors" },
        { key = "cinematicSkip",    label = "Cinematic Skip" },
        { key = "hideCastBar",      label = "Hide CastBar" },
        { key = "MythicKeys",       label = "Mythic Keys" },
    }

    for _, mod in ipairs(modules) do
        local _, ny = W.CreateButton(c, (L["btn_reset_prefix"] or "Réinitialiser ") .. mod.label, 260, y, function()
            TomoMod_ResetModule(mod.key)
            print("|cff0cd29fTomoMod|r " .. string.format(L["msg_profile_reset"] or "%s réinitialisé", mod.label))
        end)
        y = ny
    end

    local _, ny = W.CreateSeparator(c, y); y = ny
    local _, ny = W.CreateSectionHeader(c, L["section_reset_all"] or "Réinitialisation Complète", y); y = ny
    local _, ny = W.CreateInfoText(c, L["info_reset_all_warning"] or "Réinitialise TOUS les paramètres. Cette action est irréversible.", y); y = ny
    local _, ny = W.CreateButton(c, L["btn_reset_all_reload"] or "Tout Réinitialiser et Recharger", 280, y, function()
        StaticPopup_Show("TOMOMOD_RESET_ALL")
    end)
    y = ny - 20

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- POINT D'ENTRÉE
-- =====================================

function TomoMod_ConfigPanel_Profiles(parent)
    local tabs = {
        { key = "profiles",     label = L["tab_profiles"]      or "Profils",    builder = BuildProfileTab },
        { key = "importexport", label = L["tab_import_export"] or "Import/Export", builder = BuildImportExportTab },
        { key = "resets",       label = L["tab_resets"]        or "Reset",      builder = BuildResetsTab },
    }
    return W.CreateTabPanel(parent, tabs)
end

-- =====================================
-- STATIC POPUPS
-- =====================================

StaticPopupDialogs["TOMOMOD_IMPORT_CONFIRM"] = {
    text = L["popup_import_text"] or "|cff0cd29fTomoMod|r\n\nImporter ce profil ?\nVos paramètres actuels seront remplacés.",
    button1 = L["popup_confirm"] or "Importer",
    button2 = L["popup_cancel"] or "Annuler",
    OnAccept = function(self, data)
        if data and data.text then
            local ok, err = P.Import(data.text)
            if ok then
                print("|cff0cd29fTomoMod|r " .. (L["msg_import_success"] or "Import réussi"))
                ReloadUI()
            else
                print("|cffff0000TomoMod|r " .. (err or "Import échoué"))
            end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["TOMOMOD_PROFILE_RELOAD"] = {
    text = L["popup_profile_reload"] or "|cff0cd29fTomoMod|r\n\nProfil modifié.\nRecharger l'UI pour appliquer ?",
    button1 = L["popup_confirm"] or "Recharger",
    button2 = L["popup_cancel"] or "Annuler",
    OnAccept = function() ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["TOMOMOD_DELETE_PROFILE"] = {
    text = L["popup_delete_profile"] or "|cff0cd29fTomoMod|r\n\nSupprimer le profil '%s' ?\nCette action est irréversible.",
    button1 = L["popup_confirm"] or "Supprimer",
    button2 = L["popup_cancel"] or "Annuler",
    OnAccept = function(self, data)
        if data and data.name then
            P.DeleteNamedProfile(data.name)
            print("|cff0cd29fTomoMod|r " .. string.format(L["msg_profile_name_deleted"] or "Profil '%s' supprimé", data.name))
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["TOMOMOD_RENAME_PROFILE"] = {
    text = L["popup_rename_profile"] or "|cff0cd29fTomoMod|r\n\nNouveau nom pour '%s' :",
    button1 = L["popup_confirm"] or "Renommer",
    button2 = L["popup_cancel"] or "Annuler",
    hasEditBox = true,
    OnAccept = function(self, data)
        if data and data.name then
            local newName = self.editBox:GetText()
            local ok, err = P.RenameProfile(data.name, newName)
            if ok then
                print("|cff0cd29fTomoMod|r " .. string.format(L["msg_profile_renamed"] or "'%s' renommé en '%s'", data.name, newName))
            else
                print("|cffff0000TomoMod|r " .. (err or "Erreur renommage"))
            end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["TOMOMOD_DUPLICATE_PROFILE"] = {
    text = L["popup_duplicate_profile"] or "|cff0cd29fTomoMod|r\n\nDupliquer '%s' sous le nom :",
    button1 = L["popup_confirm"] or "Dupliquer",
    button2 = L["popup_cancel"] or "Annuler",
    hasEditBox = true,
    OnAccept = function(self, data)
        if data and data.name then
            local toName = self.editBox:GetText()
            local ok, err = P.DuplicateProfile(data.name, toName)
            if ok then
                print("|cff0cd29fTomoMod|r " .. string.format(L["msg_profile_duplicated"] or "'%s' dupliqué en '%s'", data.name, toName))
            else
                print("|cffff0000TomoMod|r " .. (err or "Erreur duplication"))
            end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

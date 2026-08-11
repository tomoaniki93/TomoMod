-- =====================================================================
-- TomoMod AstralForge (A2) -- dedicated LoadOnDemand designer for unit
-- frame elements. Window chrome from Forge.Studio, element sidebar from
-- Forge.Registry, drag surface from Forge.Canvas, subject frame from the
-- SAME factories the live frames and the config preview use
-- (UFP.CreateStandalone -> UF.BuildVisuals).
--
-- The subject is a detached preview clone. Nothing here ever touches a
-- live oUF frame: those are protected in Midnight and dragging one would
-- taint it. Edits land in TomoModDB.unitFrames[unit].elements and are
-- pushed to the game frames through UF.RefreshUnit, which is gated on
-- combat by the engine itself.
-- =====================================================================

local W = TomoMod_Widgets
if not W then
    -- Nothing can be built without the widget kit. Publish a marker global
    -- so the launcher can report *why* the window never opened, instead of
    -- a click that silently does nothing.
    TomoMod_AstralForge = { loadError = "TomoMod_Widgets indisponible" }
    return
end

local Forge = TomoMod_Forge
if not (Forge and Forge.Registry and Forge.Canvas and Forge.Studio) then
    TomoMod_AstralForge = { loadError = "TomoMod_Forge incomplet" }
    return
end

local R   = Forge.Registry
local A   = Forge.Assets
local UFE = TomoMod_UFElements
if not UFE then
    TomoMod_AstralForge = { loadError = "registre UnitFrames indisponible" }
    return
end
local NPE = TomoMod_NPElements

local S = { state = { subject = "player", element = nil, preset = nil, importText = "" } }
TomoMod_AstralForge = S

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local BRAND     = { 0.18, 0.85, 0.52 }

local PANEL_W, PANEL_H = 1180, 780
local SIDE_W           = 230
local TITLE_H          = 52
local FOOTER_H         = 44
local STAGE_H          = 300

-- Sujets editables. Les cinq premiers sont des cadres d'unite, le dernier
-- une plaque de nom : meme canvas, meme inspecteur, registre different.
local SUBJECT_LIST = {
    { value = "player",       text = "Joueur" },
    { value = "target",       text = "Cible" },
    { value = "focus",        text = "Focus" },
    { value = "pet",          text = "Familier" },
    { value = "targettarget", text = "Cible de la cible" },
    { value = "nameplate",    text = "Plaque de nom" },
}

local NAMEPLATE = "nameplate"

local function IsPlate()
    return S.state.subject == NAMEPLATE
end

-- Registre actif. Tout le reste du fichier passe par ici : ajouter un
-- domaine se limite a etendre cette fonction et Settings().
local function Registry()
    if IsPlate() then return NPE end
    return UFE
end

local L = TomoMod_L

local frame, sidebarList, contentHost
local canvas, stageHost, inspectorHost, subject, plateSubjectBase
local rowButtons = {}

-- ---------------------------------------------------------------------
-- Data access
-- ---------------------------------------------------------------------
local function Settings()
    if not TomoModDB then return nil end
    if IsPlate() then return TomoModDB.nameplates end
    return TomoModDB.unitFrames and TomoModDB.unitFrames[S.state.subject]
end

local function Store()
    local s   = Settings()
    local reg = Registry()
    if not (s and reg) then return nil end
    if type(s.elements) ~= "table" then s.elements = {} end
    reg.Ensure(s.elements)
    return s.elements
end

-- Push to the live frames AND to the config panel preview, so closing the
-- studio never reveals a frame that disagrees with what was just designed.
local function Apply()
    if IsPlate() then
        local NP = TomoMod_Nameplates
        if NP and NP.RefreshAll then NP.RefreshAll() end
        return
    end
    local UF = TomoMod_UnitFrames
    if UF and UF.RefreshUnit then UF.RefreshUnit(S.state.subject) end
    if TomoMod_UFPreview and TomoMod_UFPreview.Refresh then
        TomoMod_UFPreview.Refresh()
    end
end

-- ---------------------------------------------------------------------
-- Stage: the detached subject frame
-- ---------------------------------------------------------------------
-- Les frames WoW ne se detruisent pas : la plaque d'apercu precedente part
-- dans un bac cache, comme le fait UFPreview pour les cadres d'unite.
local plateBin

local function RebuildSubject()
    if not (canvas and stageHost) then return end
    local reg = Registry()
    if not reg then return end

    if IsPlate() then
        local NP = TomoMod_Nameplates
        if not (NP and NP.CreatePreviewPlate) then return end
        if not plateBin then
            plateBin = CreateFrame("Frame")
            plateBin:Hide()
        end
        if plateSubjectBase then
            plateSubjectBase:Hide()
            plateSubjectBase:ClearAllPoints()
            plateSubjectBase:SetParent(plateBin)
        end
        local plate, base = NP.CreatePreviewPlate(canvas.stage)
        if not plate then return end
        subject, plateSubjectBase = plate, base
        base:ClearAllPoints()
        base:SetPoint("CENTER", canvas.stage, "CENTER", 0, 0)
        base:Show()
        plate:Show()
    else
        local UFP = TomoMod_UFPreview
        if not (UFP and UFP.CreateStandalone) then return end
        subject = UFP.CreateStandalone(canvas.stage, S.state.subject, { recycle = subject })
        if not subject then return end
        subject:ClearAllPoints()
        subject:SetPoint("CENTER", canvas.stage, "CENTER", 0, 0)
        subject:Show()
    end

    local store = Store()
    if store then reg.ApplyAll(subject, store) end
    canvas:SetSubject(subject, store, reg.DOMAIN)
end

-- ---------------------------------------------------------------------
-- Sidebar: element list
-- ---------------------------------------------------------------------
function S.RebuildSidebar()
    for _, b in ipairs(rowButtons) do b:Hide() end
    if not sidebarList then return end

    local store = Store()
    local rows = {}
    for _, desc in ipairs(Registry().List()) do
        rows[#rows + 1] = { key = desc.id, labelKey = desc.labelKey }
    end
    -- Les elements instancies viennent apres les elements fixes, numerotes
    -- pour qu'on distingue « Texte personnalise 1 » de « ... 2 ».
    for _, inst in ipairs(R.ListInstances(Registry().DOMAIN, store)) do
        rows[#rows + 1] = {
            key      = inst.key,
            labelKey = inst.desc.labelKey,
            suffix   = " " .. inst.index,
        }
    end

    local y = -4
    local i = 0
    for _, row in ipairs(rows) do
        i = i + 1
        local b = rowButtons[i]
        if not b then
            b = CreateFrame("Button", nil, sidebarList, "BackdropTemplate")
            b:SetHeight(24)
            b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
            b._txt = b:CreateFontString(nil, "OVERLAY")
            b._txt:SetFont(FONT, 11, "")
            b._txt:SetPoint("LEFT", 10, 0)
            rowButtons[i] = b
        end
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", 6, y)
        b:SetPoint("TOPRIGHT", -6, y)

        local selected = (S.state.element == row.key)
        b:SetBackdropColor(BRAND[1], BRAND[2], BRAND[3], selected and 0.22 or 0)
        b._txt:SetText(L[row.labelKey] .. (row.suffix or ""))
        b._txt:SetTextColor(selected and 1 or 0.72, selected and 1 or 0.74, selected and 1 or 0.78, 1)

        local id = row.key
        b:SetScript("OnClick", function() S.SelectElement(id) end)
        b:Show()
        y = y - 26
    end
end

-- ---------------------------------------------------------------------
-- Inspector: the selected element's anchor record
-- ---------------------------------------------------------------------
function S.RebuildInspector()
    if not inspectorHost then return end

    -- Les frames WoW ne se detruisent pas : le panneau precedent part dans
    -- un bac cache, comme dans le Cooldown Studio. Le bac doit exister AVANT
    -- le reparentage, sinon le premier rebuild reparente vers nil.
    if not inspectorHost._bin then
        local bin = CreateFrame("Frame", nil, inspectorHost)
        bin:Hide()
        inspectorHost._bin = bin
    end
    if inspectorHost._scroll then
        inspectorHost._scroll:Hide()
        inspectorHost._scroll:ClearAllPoints()
        inspectorHost._scroll:SetParent(inspectorHost._bin)
    end

    local scroll = W.CreateScrollPanel(inspectorHost)
    inspectorHost._scroll = scroll
    local c = scroll.child
    local y = -8

    local store = Store()

    -- Panneau presets : occupe l'inspecteur quand il est ouvert, plutot que
    -- d'ajouter une troisieme colonne dans une fenetre deja dense.
    if S.state.showPresets then
        S.BuildPresetPanel(c, store)
        return
    end

    local id = S.state.element
    if not id or not store then
        W.CreateInfoText(c, "Selectionne un element dans la liste ou clique-le directement sur l'apercu.", y)
        return
    end

    local dom  = Registry().DOMAIN
    local desc = R.Describe(dom, id)
    local cfg  = store[id]
    if not (desc and cfg) then return end

    local _, index = R.SplitKey(id)
    local _, ny = W.CreateSectionHeader(c,
        L[desc.labelKey] .. (index and (" " .. index) or ""), y, "A")
    y = ny

    -- Modele de texte : reserve aux elements instancies.
    if desc.instanced and desc.id == "customText" then
        -- Le widget ne pre-remplit pas : on pose le texte courant a la main,
        -- sinon le champ apparaitrait vide et le premier caractere ecraserait
        -- le modele existant.
        local box, ny = W.CreateMultiLineEditBox(c, L["opt_custom_text_template"], 24, y, {
            onTextChanged = function(t)
                cfg.text = t
                Apply()
                if TomoMod_UFElements and TomoMod_UFElements.RefreshCustomTexts then
                    TomoMod_UFElements.RefreshCustomTexts(subject, store)
                end
            end,
        })
        y = ny
        if box and box.editBox and box.editBox.SetText then
            box.editBox:SetText(cfg.text or "")
        end

        local tokens = {}
        for _, t in ipairs(TomoMod_UFElements.TOKENS or {}) do
            tokens[#tokens + 1] = "[" .. t.token .. "]"
        end
        local _, ny = W.CreateInfoText(c,
            L["info_custom_text_tokens"] .. " " .. table.concat(tokens, "  "), y)
        y = ny
    end

    -- Point de l'element
    local pointOpts = {}
    for _, p in ipairs(R.POINTS) do pointOpts[#pointOpts + 1] = { text = p, value = p } end

    local _, ny = W.CreateDropdown(c, "Point de l'element", pointOpts, cfg.point, y, function(v)
        cfg.point = v
        Apply(); RebuildSubject(); S.RebuildInspector()
    end)
    y = ny

    -- Cible d'ancrage : structures (barre de vie, cadre...) ET elements
    -- freres. Le registre filtre deja la liste blanche statique et toute
    -- option qui fermerait une boucle, donc ce qui est propose est
    -- toujours applicable -- l'interface ne peut pas creer de cycle.
    local targetOpts = {}
    for _, t in ipairs(R.AllowedTargets(Registry().DOMAIN, id, store)) do
        local prefix = (t.kind == "host") and L["target_kind_host"] or L["target_kind_element"]
        targetOpts[#targetOpts + 1] = { text = prefix .. L[t.labelKey], value = t.id }
    end
    -- La cible courante peut ne plus figurer dans la liste (donnees
    -- importees) : on l'ajoute pour que le menu affiche l'etat reel plutot
    -- qu'une valeur vide.
    local present = false
    for _, o in ipairs(targetOpts) do
        if o.value == cfg.relTo then present = true break end
    end
    if not present then
        targetOpts[#targetOpts + 1] = { text = cfg.relTo, value = cfg.relTo }
    end

    local _, ny = W.CreateDropdown(c, "Ancre sur", targetOpts, cfg.relTo, y, function(v)
        cfg.relTo = v
        Apply(); RebuildSubject(); S.RebuildInspector()
    end)
    y = ny

    local _, ny = W.CreateDropdown(c, "Point de la cible", pointOpts, cfg.relPoint, y, function(v)
        cfg.relPoint = v
        Apply(); RebuildSubject(); S.RebuildInspector()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Decalage X", cfg.x, -300, 300, 1, y, function(v)
        cfg.x = v
        Apply(); RebuildSubject()
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Decalage Y", cfg.y, -300, 300, 1, y, function(v)
        cfg.y = v
        Apply(); RebuildSubject()
    end)
    y = ny

    -- ── Proprietes visuelles ────────────────────────────────────────
    -- Le registre ne propose que ce que le TYPE de widget sait honorer :
    -- pas d'echelle sur une chaine de texte, pas de taille de police sur
    -- une texture. Couleur, visibilite et taille restent pilotees par les
    -- modules, qui les recalculent en permanence.
    local props = R.Props(Registry().DOMAIN, id)
    if #props > 0 then
        local _, ny = W.CreateSubLabel(c, L["sublabel_element_props"], y)
        y = ny

        for _, prop in ipairs(props) do
            if prop == "alpha" then
                local _, n = W.CreateSlider(c, L["opt_element_alpha"],
                    (cfg.alpha or 1) * 100, 0, 100, 1, y, function(v)
                        cfg.alpha = v / 100
                        Apply(); RebuildSubject()
                    end)
                y = n
            elseif prop == "scale" then
                local _, n = W.CreateSlider(c, L["opt_element_scale"],
                    (cfg.scale or 1) * 100, 25, 400, 5, y, function(v)
                        cfg.scale = v / 100
                        Apply(); RebuildSubject()
                    end)
                y = n
            elseif prop == "fontSize" then
                -- 0 = on garde la taille calculee par le module.
                local _, n = W.CreateSlider(c, L["opt_element_font_size"],
                    cfg.fontSize or 0, 0, 64, 1, y, function(v)
                        cfg.fontSize = v
                        Apply(); RebuildSubject()
                    end)
                y = n
                local _, n2 = W.CreateInfoText(c, L["info_element_font_size"], y)
                y = n2
            end
        end
    end

    local _, ny = W.CreateButton(c, L["btn_reset_element"], 220, y, function()
        store[id] = R.Default(dom, id)
        Apply(); RebuildSubject(); S.RebuildInspector()
    end)
    y = ny

    if desc.instanced then
        W.CreateButton(c, L["btn_delete_element"], 220, y, function()
            R.RemoveInstance(dom, store, id)
            S.state.element = nil
            Apply(); RebuildSubject()
            S.RebuildSidebar(); S.RebuildInspector()
        end)
    end
end

-- ---------------------------------------------------------------------
-- Presets de disposition
-- ---------------------------------------------------------------------
function S.BuildPresetPanel(c, store)
    local dom = Registry().DOMAIN
    local y = -8

    if not A then
        W.CreateInfoText(c, L["msg_presets_unavailable"], y)
        return
    end

    local _, ny = W.CreateSectionHeader(c, L["section_forge_presets"], y, "P")
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_forge_presets"], y)
    y = ny

    -- Enregistrer / remplacer
    local nameBox, ny = W.CreateMultiLineEditBox(c, L["opt_preset_name"], 24, y, {
        onTextChanged = function(t) S.state.presetName = t end,
    })
    y = ny
    if nameBox and nameBox.editBox and nameBox.editBox.SetText then
        nameBox.editBox:SetText(S.state.presetName or "")
    end

    local _, ny = W.CreateButton(c, L["btn_preset_save"], 220, y, function()
        local ok, err = A.Save(dom, S.state.presetName, store)
        print("|cff2ed884TomoMod|r " ..
            (ok and L["msg_preset_saved"] or (err or L["msg_preset_error"])))
        if ok then S.RebuildInspector() end
    end)
    y = ny

    -- Liste des presets enregistres
    local names = A.List(dom)
    if #names == 0 then
        local _, ny = W.CreateInfoText(c, L["info_no_preset"], y)
        y = ny
    else
        local opts = {}
        for _, n in ipairs(names) do opts[#opts + 1] = { text = n, value = n } end
        if not S.state.preset or not A.Exists(dom, S.state.preset) then
            S.state.preset = names[1]
        end

        local _, ny = W.CreateDropdown(c, L["opt_preset_saved"], opts, S.state.preset, y, function(v)
            S.state.preset = v
            S.RebuildInspector()
        end)
        y = ny

        local _, ny = W.CreateButton(c, L["btn_preset_apply"], 220, y, function()
            local ok, err = A.Apply(dom, S.state.preset, store)
            if ok then
                Apply(); RebuildSubject(); S.RebuildSidebar()
                print("|cff2ed884TomoMod|r " .. L["msg_preset_applied"])
            else
                print("|cff2ed884TomoMod|r " .. (err or L["msg_preset_error"]))
            end
            S.RebuildInspector()
        end)
        y = ny

        local _, ny = W.CreateButton(c, L["btn_preset_delete"], 220, y, function()
            A.Delete(dom, S.state.preset)
            S.state.preset = nil
            S.RebuildInspector()
        end)
        y = ny

        local _, ny = W.CreateButton(c, L["btn_preset_export"], 220, y, function()
            local str, err = A.Export(dom, S.state.preset)
            if not str then
                print("|cff2ed884TomoMod|r " .. (err or L["msg_preset_error"]))
                return
            end
            S.state.exportText = str
            S.RebuildInspector()
        end)
        y = ny
    end

    -- La chaine de partage s'affiche en lecture seule : on ne peut pas
    -- ecrire dans le presse-papier depuis un addon, donc l'utilisateur la
    -- selectionne lui-meme (Ctrl+A / Ctrl+C).
    if S.state.exportText and S.state.exportText ~= "" then
        local box, ny = W.CreateMultiLineEditBox(c, L["opt_preset_share_string"], 60, y, {
            readOnly = true,
        })
        y = ny
        if box and box.editBox and box.editBox.SetText then
            box.editBox:SetText(S.state.exportText)
        end
        local _, ny = W.CreateInfoText(c, L["info_preset_copy"], y)
        y = ny
    end

    -- Import
    local importBox, ny = W.CreateMultiLineEditBox(c, L["opt_preset_import"], 48, y, {
        onTextChanged = function(t) S.state.importText = t end,
    })
    y = ny
    if importBox and importBox.editBox and importBox.editBox.SetText then
        importBox.editBox:SetText(S.state.importText or "")
    end

    W.CreateButton(c, L["btn_preset_import"], 220, y, function()
        -- Le domaine est verifie, pas suppose : appliquer une disposition de
        -- plaque a un cadre d'unite ne resoudrait rien et viderait le cadre,
        -- ce qui se lit comme un bug et non comme une erreur de manipulation.
        local name, err = A.Import(S.state.importText, dom)
        if not name then
            print("|cff2ed884TomoMod|r " .. (err or L["msg_preset_error"]))
            return
        end
        S.state.preset = name
        S.state.importText = ""
        print("|cff2ed884TomoMod|r " .. L["msg_preset_imported"] .. " " .. name)
        S.RebuildInspector()
    end)
end

function S.SelectElement(id)
    S.state.element = id
    S.state.showPresets = false
    if canvas and canvas.GetSelection and canvas:GetSelection() ~= id then
        canvas:Select(id)
    end
    S.RebuildSidebar()
    S.RebuildInspector()
end

-- ---------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------
local function BuildWindow()
    local shell = Forge.Studio.CreateShell({
        name         = "TomoModAstralForgeFrame",
        title        = "|cff2ed884Astral|rForge",
        width        = PANEL_W,
        height       = PANEL_H,
        sideWidth    = SIDE_W,
        titleH       = TITLE_H,
        footerH      = FOOTER_H,
        crudHeight   = 76,
        accent       = BRAND,
        sidebarTitle = "ELEMENTS",
        selector = {
            label   = "Sujet edite",
            options = SUBJECT_LIST,
            get     = function() return S.state.subject end,
            set     = function(v)
                S.state.subject = v
                S.state.element = nil
                RebuildSubject()
                S.RebuildSidebar()
                S.RebuildInspector()
            end,
        },
        footerButtons = {
            { text = L["btn_add_custom_text"], width = 190, callback = function()
                local dom = Registry().DOMAIN
                local store = Store()
                if not store then return end
                local key, why = R.AddInstance(dom, store, "customText")
                if not key then
                    if why == "max" then
                        print("|cff2ed884TomoMod|r " .. L["msg_element_max_reached"])
                    end
                    return
                end
                S.state.element = key
                Apply(); RebuildSubject()
                S.RebuildSidebar(); S.RebuildInspector()
            end },
            { text = "Tout reinitialiser", width = 170, callback = function()
                local store = Store()
                if not store then return end
                for _, desc in ipairs(Registry().List()) do
                    store[desc.id] = R.Default(Registry().DOMAIN, desc.id)
                end
                Apply(); RebuildSubject(); S.RebuildInspector()
            end },
        },
        hint = "Glisser un element pour le placer  -  Maj : sans magnetisme  -  Echap pour fermer",
    })
    frame       = shell.frame
    sidebarList = shell.sidebarList
    contentHost = shell.contentHost

    W.CreateButton(shell.crudHost, "Recharger l'apercu", 200, -6, function()
        RebuildSubject()
        S.RebuildInspector()
    end)

    W.CreateButton(shell.crudHost, L["btn_forge_presets"], 200, -34, function()
        S.state.showPresets = not S.state.showPresets
        S.RebuildInspector()
    end)

    -- Stage (haut) : fond sombre neutre, le cadre d'apercu au centre.
    stageHost = CreateFrame("Frame", nil, contentHost, "BackdropTemplate")
    stageHost:SetPoint("TOPLEFT", 12, -12)
    stageHost:SetPoint("TOPRIGHT", -12, -12)
    stageHost:SetHeight(STAGE_H)
    stageHost:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    stageHost:SetBackdropColor(0.02, 0.03, 0.04, 1)
    stageHost:SetBackdropBorderColor(0.14, 0.15, 0.19, 1)

    canvas = Forge.Canvas.Create(stageHost, {
        domain = UFE.DOMAIN,   -- remplace par SetSubject a chaque changement
        accent = BRAND,
        onSelect = function(id)
            if S.state.element == id then return end
            S.state.element = id
            S.RebuildSidebar()
            S.RebuildInspector()
        end,
        onChange = function()
            Apply()
            S.RebuildInspector()
        end,
    })
    canvas.stage:SetPoint("TOPLEFT", stageHost, "TOPLEFT", 1, -1)
    canvas.stage:SetPoint("BOTTOMRIGHT", stageHost, "BOTTOMRIGHT", -1, 1)

    inspectorHost = CreateFrame("Frame", nil, contentHost)
    inspectorHost:SetPoint("TOPLEFT", stageHost, "BOTTOMLEFT", 0, -10)
    inspectorHost:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT", -12, 10)
end

function S.Open()
    if not frame then BuildWindow() end
    if not frame then return end
    frame:Show()

    -- La construction du sujet touche des widgets de jeu : si elle echoue,
    -- la fenetre doit rester utilisable (liste, inspecteur, presets) plutot
    -- que de s'ouvrir vide. C'est exactement ce qui se passait quand une
    -- mesure sur rect secret levait au milieu de Rebuild.
    local ok, err = pcall(RebuildSubject)
    if not ok then
        print("|cff2ed884TomoMod|r AstralForge : apercu indisponible ("
            .. tostring(err) .. ")")
    end

    S.RebuildSidebar()
    S.RebuildInspector()
end

function S.Close()
    if frame then frame:Hide() end
end

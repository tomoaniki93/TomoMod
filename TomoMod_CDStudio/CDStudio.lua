-- =====================================================================
-- TomoMod Cooldown Studio (S1) -- dedicated LoadOnDemand editor shell
-- for CooldownForge bars. Window chrome + bar sidebar (CRUD) + per-bar
-- tabs (Disposition / Style / Sorts / Visibilite / Partage) + edit-mode
-- toggle wired to CDF_Movers and share tools wired to CDF_IO.
--
-- Loaded on demand from the config panel launcher; requires TomoMod
-- (TomoMod_Widgets + TomoMod_CooldownForge). Reuses the W widget kit,
-- so styling stays consistent with the main GUI.
-- =====================================================================

local W = TomoMod_Widgets
if not W then return end

local S = { state = { class = nil, barId = nil } }
TomoMod_CDStudio = S

local CDF -- resolved lazily (main addon is loaded, but stay defensive)

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local WHITE8    = "Interface\\Buttons\\WHITE8x8"

local PANEL_W, PANEL_H = 1280, 840
local SIDE_W           = 250
local TITLE_H          = 52
local FOOTER_H         = 44
local BRAND            = { 0.18, 0.85, 0.52 }

local CLASS_LIST = {
    { value = "WARRIOR",     text = "Guerrier" },
    { value = "PALADIN",     text = "Paladin" },
    { value = "HUNTER",      text = "Chasseur" },
    { value = "ROGUE",       text = "Voleur" },
    { value = "PRIEST",      text = "Pretre" },
    { value = "DEATHKNIGHT", text = "Chevalier de la mort" },
    { value = "SHAMAN",      text = "Chaman" },
    { value = "MAGE",        text = "Mage" },
    { value = "WARLOCK",     text = "Demoniste" },
    { value = "MONK",        text = "Moine" },
    { value = "DRUID",       text = "Druide" },
    { value = "DEMONHUNTER", text = "Chasseur de demons" },
    { value = "EVOKER",      text = "Evocateur" },
}

local frame, sidebarList, contentHost, editBtnTxt
local hiddenBin

local function Bin()
    if not hiddenBin then
        hiddenBin = CreateFrame("Frame")
        hiddenBin:Hide()
    end
    return hiddenBin
end

local function Apply()
    if CDF and CDF.RefreshAll then CDF.RefreshAll() end
end

local function colorProxy(arr) return { r = arr[1] or 1, g = arr[2] or 1, b = arr[3] or 1 } end
local function writeColor(arr, r, g, b) arr[1] = r; arr[2] = g; arr[3] = b end

local function Bars()
    return (CDF and CDF.GetClassBars(S.state.class)) or {}
end

local function SelectedBar()
    return S.state.barId and CDF and CDF.GetBar(S.state.class, S.state.barId) or nil
end

local function EntryDesc(e)
    local k, who = e.kind, "?"
    if k == "spell" then who = "Sort " .. tostring(e.id)
    elseif k == "item" then who = "Objet " .. tostring(e.id)
    elseif k == "itemPreset" then
        local p = CDF.PRESETS and CDF.PRESETS[e.preset]
        who = "Preset " .. ((p and p.name) or e.preset or "?")
    elseif k == "equippedTrinket" then who = "Bijou (slot " .. tostring(e.slot) .. ")"
    elseif k == "racial" then who = "Racial"
    end
    local spec = (not e.spec or e.spec == 0) and "toutes spes" or ("spe " .. tostring(e.spec))
    return who .. "  -  " .. spec
end

local function SpecOptions(class)
    local opts = { { text = "Toutes spes", value = 0 } }
    if class == (CDF and CDF.PlayerClass()) and GetNumSpecializations then
        for i = 1, (GetNumSpecializations() or 0) do
            local id, name = GetSpecializationInfo(i)
            if id then opts[#opts + 1] = { text = name or ("Spe " .. i), value = id } end
        end
    end
    return opts
end

-- ---------------------------------------------------------------------
-- Tab builders (each receives the tab content frame, returns the panel)
-- ---------------------------------------------------------------------
local addState = { kind = "spell", id = "", spec = 0 }

-- [S4/L1] accent folding, delegated to the shared Forge.Util.
local function Fold(s)
    local F = TomoMod_Forge
    if F and F.Util then return F.Util.Fold(s) end
    return tostring(s or ""):lower()
end

-- [S2] tri-state helpers for per-entry overrides
local TRI_OPTS = {
    { text = "Heriter de la barre", value = "inherit" },
    { text = "Oui",                 value = "on" },
    { text = "Non",                 value = "off" },
}
local function triVal(v)
    if v == nil then return "inherit" end
    return v and "on" or "off"
end
local function triSet(o, k, v)
    if v == "inherit" then o[k] = nil else o[k] = (v == "on") end
end

local function TabDisposition(parent)
    S.state.tab = "layout"
    local scroll = W.CreateScrollPanel(parent)
    local c, y = scroll.child, -12
    local bar = SelectedBar()
    if not bar then return scroll end
    local card, cy

    card, cy = W.CreateCard(c, "Disposition", y)
    _, cy = W.CreateSegmentedControl(card.inner, "Orientation",
        { { text = "Horizontale", value = "horizontal" }, { text = "Verticale", value = "vertical" } },
        bar.orientation, cy, function(v) bar.orientation = v; Apply() end, 2)
    _, cy = W.CreateDropdown(card.inner, "Direction de croissance",
        { { text = "Droite", value = "RIGHT" }, { text = "Gauche", value = "LEFT" },
          { text = "Bas", value = "DOWN" }, { text = "Haut", value = "UP" } },
        bar.growth, cy, function(v) bar.growth = v; Apply() end)
    _, cy = W.CreateTripleSlider(card.inner, cy,
        { text = "Taille icones", value = bar.iconSize, min = 24, max = 64, step = 1,
          callback = function(v) bar.iconSize = v; Apply() end },
        { text = "Espacement", value = bar.spacing, min = 0, max = 16, step = 1,
          callback = function(v) bar.spacing = v; Apply() end },
        { text = "Retour (icones/ligne)", value = bar.wrap, min = 0, max = 12, step = 1,
          callback = function(v) bar.wrap = v; Apply() end })
    _, cy = W.CreateInfoText(card.inner, "Retour a 0 = une seule ligne. La position se regle via le mode edition (footer).", cy)
    W.FinalizeCard(card, cy)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

local function TabStyle(parent)
    S.state.tab = "style"
    local scroll = W.CreateScrollPanel(parent)
    local c, y = scroll.child, -12
    local bar = SelectedBar()
    if not bar then return scroll end
    local card, cy

    card, cy = W.CreateCard(c, "Style visuel", y)
    bar.style = bar.style or { preset = "tomo" }
    _, cy = W.CreateDropdown(card.inner, "Preset de style",
        { { text = "Tomo (carte)", value = "tomo" },
          { text = "Net (pixel)", value = "net" },
          { text = "Verre (moderne)", value = "verre" } },
        bar.style.preset or "tomo", cy, function(v) bar.style.preset = v; Apply(); S.RebuildContent() end)
    _, cy = W.CreateCheckbox(card.inner, "Griser pendant le cooldown", bar.style.desatOnCooldown == true, cy,
        function(v) bar.style.desatOnCooldown = v; Apply() end)
    y = W.FinalizeCard(card, cy)

    -- [S7] fine style axes. Editing any of these marks the style custom.
    local eff = (CDF.ResolveStyle and CDF.ResolveStyle(bar)) or {}
    local function markCustom() bar.style.preset = "custom" end
    card, cy = W.CreateCard(c, "Reglages fins", y)
    _, cy = W.CreateSlider(card.inner, "Opacite", math.floor(((eff.opacity or 1) * 100) + 0.5), 20, 100, 5, cy,
        function(v) markCustom(); bar.style.opacity = v / 100; Apply() end, "%d %%")

    local bd = eff.border or {}
    _, cy = W.CreateDropdown(card.inner, "Couleur de bordure",
        { { text = "Couleur de classe", value = "class" },
          { text = "Neutre", value = "flat" },
          { text = "Personnalisee", value = "bar" } },
        bd.mode or "class", cy, function(v)
            markCustom()
            bar.style.border = bar.style.border or {}
            bar.style.border.mode = v
            if v == "bar" and not bar.style.border.color then
                local r, g, b = CDF.ClassColor()
                bar.style.border.color = { r, g, b }
            end
            Apply(); S.RebuildContent()
        end)
    if (bar.style.border and bar.style.border.mode or bd.mode) == "bar" then
        local col = (bar.style.border and bar.style.border.color) or { 1, 1, 1 }
        _, cy = W.CreateColorPicker(card.inner, "Couleur de bordure (perso)", colorProxy(col), cy,
            function(r, g, b)
                markCustom()
                bar.style.border = bar.style.border or {}
                bar.style.border.color = { r, g, b }
                Apply()
            end)
    end
    _, cy = W.CreateSlider(card.inner, "Epaisseur de bordure", math.floor((bd.thickness or 1) + 0.5), 1, 4, 1, cy,
        function(v)
            markCustom()
            bar.style.border = bar.style.border or {}
            bar.style.border.thickness = v
            Apply()
        end)

    local hasTimerColor = (bar.style.timerColor ~= nil)
    _, cy = W.CreateCheckbox(card.inner, "Couleur de timer personnalisee", hasTimerColor, cy, function(v)
        markCustom()
        if v then
            bar.style.timerColor = bar.style.timerColor or { 1, 1, 1 }
        else
            bar.style.timerColor = nil
        end
        Apply(); S.RebuildContent()
    end)
    if hasTimerColor then
        _, cy = W.CreateColorPicker(card.inner, "Couleur du timer", colorProxy(bar.style.timerColor), cy,
            function(r, g, b) markCustom(); writeColor(bar.style.timerColor, r, g, b); Apply() end)
    end
    _, cy = W.CreateCheckbox(card.inner, "Ombre portee", eff.shadow == true, cy, function(v)
        markCustom(); bar.style.shadow = v; Apply()
    end)
    _, cy = W.CreateInfoText(card.inner,
        "Modifier un reglage fin bascule le style en \"Personnalise\".", cy)
    y = W.FinalizeCard(card, cy)

    card, cy = W.CreateCard(c, "Glow (quand pret)", y)
    _, cy = W.CreateCheckbox(card.inner, "Activer le glow", bar.glow.enabled, cy,
        function(v) bar.glow.enabled = v; Apply() end)
    _, cy = W.CreateDropdown(card.inner, "Type de glow",
        { { text = "Pixel", value = "Pixel" }, { text = "Autocast", value = "Autocast" }, { text = "Button", value = "Button" } },
        bar.glow.type, cy, function(v) bar.glow.type = v; Apply() end)
    _, cy = W.CreateColorPicker(card.inner, "Couleur du glow", colorProxy(bar.glow.color), cy,
        function(r, g, b) writeColor(bar.glow.color, r, g, b); Apply() end)
    y = W.FinalizeCard(card, cy)

    card, cy = W.CreateCard(c, "Swipe & texte", y)
    _, cy = W.CreateCheckbox(card.inner, "Swipe", bar.swipe.draw, cy,
        function(v) bar.swipe.draw = v; Apply() end)
    _, cy = W.CreateCheckbox(card.inner, "Swipe inverse", bar.swipe.reverse, cy,
        function(v) bar.swipe.reverse = v; Apply() end)
    _, cy = W.CreateDropdown(card.inner, "Texte",
        { { text = "Timer", value = "timer" }, { text = "Nom du sort", value = "name" }, { text = "Aucun", value = "none" } },
        bar.text.mode, cy, function(v) bar.text.mode = v; Apply() end)
    _, cy = W.CreateSlider(card.inner, "Taille du texte", bar.text.size or 13, 9, 20, 1, cy,
        function(v) bar.text.size = v; Apply() end)
    _, cy = W.CreateCheckbox(card.inner, "Afficher les stacks/charges", bar.text.stacks ~= false, cy,
        function(v) bar.text.stacks = v; Apply() end)
    W.FinalizeCard(card, cy)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

local function TabSorts(parent)
    S.state.tab = "spells"
    local scroll = W.CreateScrollPanel(parent)
    local c, y = scroll.child, -12
    local bar = SelectedBar()
    if not bar then return scroll end
    local card, cy

    card, cy = W.CreateCard(c, "Entrees de la barre", y)
    local es = bar.entries or {}
    if #es == 0 then
        _, cy = W.CreateInfoText(card.inner, "Aucune entree pour l'instant.", cy)
    end
    for i = 1, #es do
        local idx = i
        _, cy = W.CreateInfoText(card.inner, i .. ". " .. EntryDesc(es[i]), cy)
        _, cy = W.CreateButtonRow(card.inner, {
            { text = (S.state.fxIdx == idx) and "Fermer les options" or "Options", width = 150, callback = function()
                S.state.fxIdx = (S.state.fxIdx ~= idx) and idx or nil
                S.RebuildContent()
            end },
            { text = "Retirer", width = 110, callback = function()
                if S.state.fxIdx == idx then S.state.fxIdx = nil end
                CDF.RemoveEntry(S.state.class, S.state.barId, idx)
                Apply(); S.RebuildContent()
            end },
        }, cy)
    end
    y = W.FinalizeCard(card, cy)

    -- [S2] per-entry override editor
    local fxE = S.state.fxIdx and es[S.state.fxIdx] or nil
    if fxE then
        card, cy = W.CreateCard(c, "Options -- " .. S.state.fxIdx .. ". " .. EntryDesc(fxE), y)
        fxE.override = fxE.override or {}
        local o = fxE.override
        local function tri(label, key)
            _, cy = W.CreateDropdown(card.inner, label, TRI_OPTS, triVal(o[key]), cy, function(v)
                triSet(o, key, v)
                Apply()
            end)
        end
        tri("Glow quand pret", "glow")
        local hasColor = o.glowColor ~= nil
        _, cy = W.CreateCheckbox(card.inner, "Couleur de glow personnalisee", hasColor, cy, function(v)
            if v then
                o.glowColor = o.glowColor or { 1, 0.85, 0.2, 1 }
            else
                o.glowColor = nil
            end
            Apply(); S.RebuildContent()
        end)
        if hasColor then
            _, cy = W.CreateColorPicker(card.inner, "Couleur du glow (entree)", colorProxy(o.glowColor), cy,
                function(r, g, b) writeColor(o.glowColor, r, g, b); Apply() end)
        end
        tri("Griser pendant le cooldown", "desat")
        tri("Swipe", "swipe")
        tri("Timer", "timer")
        tri("Stacks / charges", "stacks")
        _, cy = W.CreateSlider(card.inner, "Emphase (taille relative)",
            math.floor(((tonumber(o.emphasis) or 1) * 100) + 0.5), 100, 130, 5, cy, function(v)
                o.emphasis = (v > 100) and (v / 100) or nil
                Apply()
            end, "%d %%")
        _, cy = W.CreateInfoText(card.inner,
            "Heriter = suivre les reglages de la barre. L'emphase agrandit l'icone autour du centre de sa case sans casser la grille.", cy)
        y = W.FinalizeCard(card, cy)
    end

    card, cy = W.CreateCard(c, "Ajouter", y)
    _, cy = W.CreateDropdown(card.inner, "Type",
        { { text = "Sort (spellID)", value = "spell" }, { text = "Objet (itemID)", value = "item" },
          { text = "Bijou equipe (slot)", value = "equippedTrinket" } },
        addState.kind, cy, function(v) addState.kind = v end)
    _, cy = W.CreateMultiLineEditBox(card.inner, "ID / slot", 24, cy, {
        onTextChanged = function(t) addState.id = t end,
    })
    _, cy = W.CreateDropdown(card.inner, "Visibilite (spec)", SpecOptions(S.state.class), addState.spec, cy,
        function(v) addState.spec = v end)
    _, cy = W.CreateButton(card.inner, "Ajouter", 130, cy, function()
        local data = { kind = addState.kind, spec = addState.spec }
        if addState.kind == "equippedTrinket" then data.slot = tonumber(addState.id)
        else data.id = tonumber(addState.id) end
        if CDF.AddEntry(S.state.class, S.state.barId, data) then
            addState.id = ""
            Apply(); S.RebuildContent()
        end
    end)

    _, cy = W.CreateSubLabel(card.inner, "Presets rapides", cy)
    local function addPreset(data)
        CDF.AddEntry(S.state.class, S.state.barId, data)
        Apply(); S.RebuildContent()
    end
    _, cy = W.CreateButtonRow(card.inner, {
        { text = "Bijou (13)", callback = function() addPreset({ kind = "equippedTrinket", slot = 13 }) end },
        { text = "Bijou (14)", callback = function() addPreset({ kind = "equippedTrinket", slot = 14 }) end },
        { text = "Racial",     callback = function() addPreset({ kind = "racial" }) end },
    }, cy)
    for key, p in pairs((CDF and CDF.PRESETS) or {}) do
        local pk = key
        _, cy = W.CreateButton(card.inner, "Preset : " .. ((p and p.name) or key), 220, cy, function()
            addPreset({ kind = "itemPreset", preset = pk })
        end)
    end
    W.FinalizeCard(card, cy)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- [S4] Library tab: spellbook scan + in-place name filter. Rows are laid
-- out once for the full list; filtering repositions the visible rows and
-- hides the rest (the card keeps its full-list height -- cheap and jank-free).
local function TabBibliotheque(parent)
    S.state.tab = "library"
    local scroll = W.CreateScrollPanel(parent)
    local c, y = scroll.child, -12
    local bar = SelectedBar()
    local card, cy

    if S.state.class ~= (CDF and CDF.PlayerClass()) then
        card, cy = W.CreateCard(c, "Bibliotheque de sorts", y)
        _, cy = W.CreateInfoText(card.inner,
            "La bibliotheque scanne le grimoire du personnage connecte : elle n'est disponible "
            .. "que pour sa classe. Connecte-toi avec un personnage de cette classe, ou ajoute "
            .. "les sorts par ID dans l'onglet Sorts.", cy)
        W.FinalizeCard(card, cy)
        if scroll.UpdateScroll then scroll.UpdateScroll() end
        return scroll
    end

    card, cy = W.CreateCard(c, "Bibliotheque -- grimoire", y)
    if not bar then
        _, cy = W.CreateInfoText(card.inner, "Selectionne (ou cree) une barre pour y ajouter des sorts.", cy)
        W.FinalizeCard(card, cy)
        if scroll.UpdateScroll then scroll.UpdateScroll() end
        return scroll
    end

    -- Which spellIDs are already in the bar (any spec)
    local inBar = {}
    for _, e in ipairs(bar.entries or {}) do
        if e.kind == "spell" and e.id then inBar[e.id] = true end
    end

    local filterText = ""
    local rows = {}
    local ROW_H = 28
    local listTop

    local function Reflow()
        local q = Fold(filterText)
        local shown = 0
        for _, row in ipairs(rows) do
            local match = (q == "") or (row.fold:find(q, 1, true) ~= nil)
            if row.isHeader then
                -- headers handled in a second pass (only shown if a child matches)
                row._match = false
            elseif match then
                row._match = true
            else
                row._match = false
            end
        end
        -- headers: visible when at least one following spell row matches
        local i = 1
        while i <= #rows do
            local row = rows[i]
            if row.isHeader then
                local any = false
                local j = i + 1
                while j <= #rows and not rows[j].isHeader do
                    if rows[j]._match then any = true end
                    j = j + 1
                end
                row._match = any
            end
            i = i + 1
        end
        for _, row in ipairs(rows) do
            if row._match then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT",  16, listTop - shown * ROW_H)
                row:SetPoint("TOPRIGHT", -16, listTop - shown * ROW_H)
                row:Show()
                shown = shown + 1
            else
                row:Hide()
            end
        end
    end

    _, cy = W.CreateMultiLineEditBox(card.inner, "Filtrer par nom", 24, cy, {
        onTextChanged = function(t)
            filterText = t or ""
            Reflow()
        end,
    })
    _, cy = W.CreateInfoText(card.inner,
        "Clique un sort pour l'ajouter a la barre selectionnee. Les sorts d'une ligne de "
        .. "specialisation sont ajoutes avec cette visibilite de spe.", cy)

    listTop = cy - 4
    local groups = CDF.ScanSpellbook and CDF.ScanSpellbook() or {}
    local total = 0

    for _, g in ipairs(groups) do
        -- section header row
        local h = CreateFrame("Frame", nil, card.inner)
        h:SetHeight(ROW_H)
        h.isHeader = true
        h.fold = ""
        local ht = h:CreateFontString(nil, "OVERLAY")
        ht:SetFont(FONT_BOLD, 10, "")
        ht:SetPoint("BOTTOMLEFT", 2, 5)
        ht:SetTextColor(BRAND[1], BRAND[2], BRAND[3], 0.9)
        ht:SetText(string.upper(g.name or ""))
        rows[#rows + 1] = h
        total = total + 1

        for _, sp in ipairs(g.spells) do
            local row = CreateFrame("Button", nil, card.inner, "BackdropTemplate")
            row:SetHeight(ROW_H)
            row.fold = Fold(sp.name)
            row:SetBackdrop({ bgFile = WHITE8 })
            row:SetBackdropColor(1, 1, 1, 0)

            local ic = row:CreateTexture(nil, "ARTWORK")
            ic:SetSize(20, 20)
            ic:SetPoint("LEFT", 2, 0)
            ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            if sp.icon then ic:SetTexture(sp.icon) end

            local nm = row:CreateFontString(nil, "OVERLAY")
            nm:SetFont(FONT, 11, "")
            nm:SetPoint("LEFT", ic, "RIGHT", 8, 0)
            nm:SetPoint("RIGHT", -120, 0)
            nm:SetJustifyH("LEFT")
            nm:SetWordWrap(false)
            nm:SetText(sp.name)

            local idfs = row:CreateFontString(nil, "OVERLAY")
            idfs:SetFont(FONT, 9, "")
            idfs:SetPoint("RIGHT", -66, 0)
            idfs:SetTextColor(0.4, 0.42, 0.48, 1)
            idfs:SetText(tostring(sp.spellID))

            local act = row:CreateFontString(nil, "OVERLAY")
            act:SetFont(FONT_BOLD, 10, "")
            act:SetPoint("RIGHT", -6, 0)
            row.act = act

            local function paint()
                if inBar[sp.spellID] then
                    act:SetText("Dans la barre")
                    act:SetTextColor(0.42, 0.45, 0.5, 1)
                    nm:SetTextColor(0.5, 0.52, 0.56, 1)
                else
                    act:SetText("+ Ajouter")
                    act:SetTextColor(BRAND[1], BRAND[2], BRAND[3], 1)
                    nm:SetTextColor(0.85, 0.87, 0.86, 1)
                end
            end
            paint()

            row:SetScript("OnEnter", function(self) self:SetBackdropColor(1, 1, 1, 0.05) end)
            row:SetScript("OnLeave", function(self) self:SetBackdropColor(1, 1, 1, 0) end)
            local specForLine = g.offSpecID or 0
            row:SetScript("OnClick", function()
                if inBar[sp.spellID] then return end
                if CDF.AddEntry(S.state.class, S.state.barId,
                        { kind = "spell", id = sp.spellID, spec = specForLine }) then
                    inBar[sp.spellID] = true
                    paint()
                    Apply()
                end
            end)

            rows[#rows + 1] = row
            total = total + 1
        end
    end

    if total == 0 then
        _, cy = W.CreateInfoText(card.inner, "Grimoire vide ou API indisponible.", cy)
        W.FinalizeCard(card, cy)
    else
        Reflow()
        W.FinalizeCard(card, listTop - total * ROW_H - 8)
    end
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- [S6] tri-state condition helper (Indifferent / Oui / Non)
local VIS_OPTS = {
    { text = "Indifferent", value = "any" },
    { text = "Oui",         value = "yes" },
    { text = "Non",         value = "no" },
}
local function visVal(v)
    if v == nil then return "any" end
    return v and "yes" or "no"
end
local function visSet(t, k, v)
    if v == "any" then t[k] = nil else t[k] = (v == "yes") end
end

local function TabVisibilite(parent)
    S.state.tab = "vis"
    local scroll = W.CreateScrollPanel(parent)
    local c, y = scroll.child, -12
    local bar = SelectedBar()
    if not bar then
        local card, cy = W.CreateCard(c, "Visibilite", y)
        _, cy = W.CreateInfoText(card.inner, "Selectionne (ou cree) une barre.", cy)
        W.FinalizeCard(card, cy)
        if scroll.UpdateScroll then scroll.UpdateScroll() end
        return scroll
    end
    local card, cy

    card, cy = W.CreateCard(c, "Conditions d'affichage", y)
    _, cy = W.CreateInfoText(card.inner,
        "La barre ne s'affiche que si toutes les conditions ci-dessous sont remplies. "
        .. "Indifferent = la condition est ignoree.", cy)
    local v = bar.visibility or {}
    local function cond(label, key)
        _, cy = W.CreateDropdown(card.inner, label, VIS_OPTS, visVal(v[key]), cy, function(val)
            bar.visibility = bar.visibility or {}
            visSet(bar.visibility, key, val)
            if next(bar.visibility) == nil then bar.visibility = nil end
            v = bar.visibility or {}
            Apply()
        end)
    end
    cond("En combat", "inCombat")
    cond("En instance (donjon/raid)", "inInstance")
    cond("En groupe", "inGroup")
    cond("En raid", "inRaid")
    y = W.FinalizeCard(card, cy)

    card, cy = W.CreateCard(c, "Visibilite par sort", y)
    _, cy = W.CreateInfoText(card.inner,
        "La visibilite par specialisation se regle entree par entree dans l'onglet Sorts.", cy)
    W.FinalizeCard(card, cy)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

local function TabPartage(parent)
    S.state.tab = "share"
    local scroll = W.CreateScrollPanel(parent)
    local c, y = scroll.child, -12
    local card, cy

    card, cy = W.CreateCard(c, "Exporter (toute la classe)", y)
    local exportBox
    exportBox, cy = W.CreateMultiLineEditBox(card.inner, "Chaine d'export", 90, cy, {})
    _, cy = W.CreateButtonRow(card.inner, {
        { text = "Exporter la classe", width = 170, callback = function()
            local str = CDF.Export and CDF.Export(S.state.class)
            if str and exportBox and exportBox.editBox then
                exportBox.editBox:SetText(str)
                exportBox.editBox:HighlightText()
                exportBox.editBox:SetFocus()
            end
        end },
        { text = "Exporter la barre", width = 170, callback = function()
            local str = CDF.ExportBar and S.state.barId
                and CDF.ExportBar(S.state.class, S.state.barId)
            if str and exportBox and exportBox.editBox then
                exportBox.editBox:SetText(str)
                exportBox.editBox:HighlightText()
                exportBox.editBox:SetFocus()
            end
        end },
    }, cy)
    y = W.FinalizeCard(card, cy)

    card, cy = W.CreateCard(c, "Importer", y)
    local importText = ""
    _, cy = W.CreateMultiLineEditBox(card.inner, "Coller une chaine", 90, cy, {
        onTextChanged = function(t) importText = t end,
    })
    _, cy = W.CreateButton(card.inner, "Importer", 130, cy, function()
        if importText == "" then return end
        local ok, err = CDF.Import(importText)
        if ok then
            Apply(); S.RebuildSidebar(); S.RebuildContent()
        else
            print("|cff2ed884TomoMod|r CD Studio : import echoue (" .. tostring(err or "?") .. ")")
        end
    end)
    _, cy = W.CreateInfoText(card.inner, "L'import ecrase les barres de la classe contenue dans la chaine (backup automatique cote schema).", cy)
    W.FinalizeCard(card, cy)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- ---------------------------------------------------------------------
-- Sidebar (bar list + CRUD)
-- ---------------------------------------------------------------------
local sideButtons = {}

function S.RebuildSidebar()
    for _, b in ipairs(sideButtons) do b:Hide() end
    local bars = Bars()
    if #bars > 0 and (not S.state.barId or not CDF.GetBar(S.state.class, S.state.barId)) then
        S.state.barId = bars[1].id
    elseif #bars == 0 then
        S.state.barId = nil
    end
    for i, bar in ipairs(bars) do
        local btn = sideButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, sidebarList, "BackdropTemplate")
            btn:SetHeight(30)
            btn:SetPoint("TOPLEFT", 8, -((i - 1) * 34) - 6)
            btn:SetPoint("TOPRIGHT", -8, -((i - 1) * 34) - 6)
            btn:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
            btn.txt = btn:CreateFontString(nil, "OVERLAY")
            btn.txt:SetFont(FONT, 11, "")
            btn.txt:SetPoint("LEFT", 10, 0)
            btn.txt:SetPoint("RIGHT", -8, 0)
            btn.txt:SetJustifyH("LEFT")
            btn.txt:SetWordWrap(false)
            sideButtons[i] = btn
        end
        btn.barId = bar.id
        btn.txt:SetText(bar.name or ("Barre " .. i))
        local sel = (bar.id == S.state.barId)
        btn:SetBackdropColor(sel and 0.10 or 0.06, sel and 0.16 or 0.07, sel and 0.12 or 0.09, 1)
        btn:SetBackdropBorderColor(BRAND[1], BRAND[2], BRAND[3], sel and 0.65 or 0.14)
        btn.txt:SetTextColor(sel and 0.92 or 0.62, sel and 0.95 or 0.65, sel and 0.93 or 0.68, 1)
        btn:SetScript("OnClick", function(self)
            S.state.barId = self.barId
            S.state.fxIdx = nil
            S.RebuildSidebar()
            S.RebuildContent()
        end)
        btn:Show()
    end
end

-- ---------------------------------------------------------------------
-- Content (tab panel for the selected bar)
-- ---------------------------------------------------------------------
local activePanel

function S.RebuildContent()
    -- Keep the global-search index clean: studio widgets must not register
    if W.SetBuildContext then W.SetBuildContext(nil, nil) end
    if activePanel then
        activePanel:Hide()
        activePanel:ClearAllPoints()
        activePanel:SetParent(Bin())
        activePanel = nil
    end
    if not SelectedBar() then
        local p = CreateFrame("Frame", nil, contentHost)
        p:SetAllPoints(contentHost)
        local fs = p:CreateFontString(nil, "OVERLAY")
        fs:SetFont(FONT, 12, "")
        fs:SetPoint("CENTER")
        fs:SetTextColor(0.5, 0.52, 0.56, 1)
        fs:SetText("Aucune barre : cree ta premiere barre avec le bouton + Nouvelle.")
        activePanel = p
        return
    end
    activePanel = W.CreateTabPanel(contentHost, {
        { key = "layout",  label = "Disposition",  builder = TabDisposition },
        { key = "style",   label = "Style",        builder = TabStyle },
        { key = "spells",  label = "Sorts",        builder = TabSorts },
        { key = "library", label = "Bibliotheque", builder = TabBibliotheque },
        { key = "vis",     label = "Visibilite",   builder = TabVisibilite },
        { key = "share",   label = "Partage",      builder = TabPartage },
    }, S.state.tab or "layout")
    activePanel:SetAllPoints(contentHost)
    activePanel:Show()
end

-- ---------------------------------------------------------------------
-- Edit mode (CDF_Movers) + floating resume button
-- ---------------------------------------------------------------------
local resumeBtn

local function EnsureResumeBtn()
    if resumeBtn then return end
    resumeBtn = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    resumeBtn:SetSize(230, 34)
    resumeBtn:SetPoint("TOP", 0, -120)
    resumeBtn:SetFrameStrata("FULLSCREEN_DIALOG")
    resumeBtn:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    resumeBtn:SetBackdropColor(0.05, 0.07, 0.06, 0.96)
    resumeBtn:SetBackdropBorderColor(BRAND[1], BRAND[2], BRAND[3], 0.8)
    local t = resumeBtn:CreateFontString(nil, "OVERLAY")
    t:SetFont(FONT_BOLD, 11, "")
    t:SetPoint("CENTER")
    t:SetTextColor(0.92, 0.95, 0.93, 1)
    t:SetText("Terminer l'edition des barres")
    resumeBtn:SetScript("OnClick", function()
        if CDF and CDF.SetLocked then CDF.SetLocked(true) end
        resumeBtn:Hide()
        S.Open()
    end)
    resumeBtn:Hide()
end

local function StartEditMode()
    if not (CDF and CDF.SetLocked) then return end
    EnsureResumeBtn()
    frame:Hide()
    CDF.SetLocked(false)
    resumeBtn:Show()
end

-- ---------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------
-- [L2] Window chrome now comes from the shared Forge.Studio shell
-- factory; this file keeps only the CDF wiring (CRUD rows, tabs, edit
-- mode) so the future UnitFrames studio gets the same chrome for free.
local function BuildWindow()
    local shell = TomoMod_Forge.Studio.CreateShell({
        name         = "TomoModCDStudioFrame",
        title        = "|cff2ed884Cooldown|r Studio",
        width        = PANEL_W,
        height       = PANEL_H,
        sideWidth    = SIDE_W,
        titleH       = TITLE_H,
        footerH      = FOOTER_H,
        crudHeight   = 150,
        accent       = BRAND,
        sidebarTitle = "BARRES",
        selector = {
            label   = "Classe editee",
            options = CLASS_LIST,
            get     = function() return S.state.class end,
            set     = function(v)
                S.state.class = v
                S.state.barId = nil
                S.state.fxIdx = nil
                S.RebuildSidebar()
                S.RebuildContent()
            end,
        },
        footerButtons = {
            { text = "Mode edition (deplacer les barres)", width = 210, callback = StartEditMode },
        },
        hint = "Echap pour fermer  -  les reglages s'appliquent en direct",
    })
    frame       = shell.frame
    sidebarList = shell.sidebarList
    contentHost = shell.contentHost

    local crudHost = shell.crudHost
    local _, cy2 = W.CreateButtonRow(crudHost, {
        { text = "+ Nouvelle", callback = function()
            local _, id = CDF.CreateBar(S.state.class, "Nouvelle barre")
            if id then S.state.barId = id end
            Apply(); S.RebuildSidebar(); S.RebuildContent()
        end },
        { text = "Dupliquer", callback = function()
            if not S.state.barId then return end
            local _, id = CDF.DuplicateBar(S.state.class, S.state.barId)
            if id then S.state.barId = id end
            Apply(); S.RebuildSidebar(); S.RebuildContent()
        end },
    }, -2)
    local _, cy3 = W.CreateButtonRow(crudHost, {
        { text = "Renommer", callback = function()
            if S.state.barId then StaticPopup_Show("TOMOMOD_CDS_RENAME") end
        end },
        { text = "Supprimer", callback = function()
            if not S.state.barId then return end
            CDF.DeleteBar(S.state.class, S.state.barId)
            S.state.barId = nil
            Apply(); S.RebuildSidebar(); S.RebuildContent()
        end },
    }, cy2)
    -- [S5] one-click blueprint bars
    local function fromBlueprint(key)
        local id = CDF.CreateBarFromBlueprint and CDF.CreateBarFromBlueprint(S.state.class, key)
        if id then S.state.barId = id end
        Apply(); S.RebuildSidebar(); S.RebuildContent()
    end
    W.CreateButtonRow(crudHost, {
        { text = "Modele : Conso",  callback = function() fromBlueprint("conso") end },
        { text = "Modele : Utils",  callback = function() fromBlueprint("utils") end },
    }, cy3)
end

StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs["TOMOMOD_CDS_RENAME"] = {
    text = "|cff2ed884Cooldown Studio|r\n\nNouveau nom de la barre :",
    button1 = "Renommer",
    button2 = "Annuler",
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnShow = function(self)
        local bar = SelectedBar()
        if bar and self.editBox then self.editBox:SetText(bar.name or "") end
    end,
    OnAccept = function(self)
        local txt = self.editBox and self.editBox:GetText()
        if txt and txt ~= "" and CDF and CDF.RenameBar then
            CDF.RenameBar(S.state.class, S.state.barId, txt)
            Apply(); S.RebuildSidebar(); S.RebuildContent()
        end
    end,
}

-- ---------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------
function S.Open()
    CDF = CDF or TomoMod_CooldownForge
    if not (CDF and CDF.DB and CDF.DB()) then
        print("|cff2ed884TomoMod|r CD Studio : CooldownForge indisponible.")
        return
    end
    S.state.class = S.state.class or CDF.PlayerClass() or "WARRIOR"
    if not frame then BuildWindow() end
    S.RebuildSidebar()
    S.RebuildContent()
    frame:Show()
end

function S.Close()
    if frame then frame:Hide() end
end

function S.Toggle()
    if frame and frame:IsShown() then S.Close() else S.Open() end
end

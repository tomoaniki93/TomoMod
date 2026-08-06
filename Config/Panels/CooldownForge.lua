-- =====================================================================
-- Panels/CooldownForge.lua -- AstralForge Cooldown editor (Lot 5)
-- Class selector, per-class bar CRUD, bar settings, entry editor + preset
-- flyout. Mutations write straight to the schema (CRUD from CDF_API) and
-- call Apply() so the live bars update. The whole panel rebuilds
-- on any structural change. Import/Export lands in Lot 6.
-- =====================================================================

local W   = TomoMod_Widgets
-- CooldownForge lives in Modules/QOL (loaded AFTER Config/Panels in the
-- TOC), so it is NOT available at file scope here. Resolve it lazily at
-- build time; every function below sees it through this upvalue.
local CDF

local abs = math.abs

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

local state = { class = nil, barId = nil, scroll = nil,
                addKind = "spell", addId = "", addSpec = 0, renameText = nil }

local hiddenBin
local function GetBin()
    if not hiddenBin then hiddenBin = CreateFrame("Frame"); hiddenBin:Hide() end
    return hiddenBin
end

-- ---------------------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------------------
local function colorProxy(arr) return { r = arr[1] or 1, g = arr[2] or 1, b = arr[3] or 1 } end
local function writeColor(arr, r, g, b) arr[1] = r; arr[2] = g; arr[3] = b end

-- Push schema changes to the live bars (Render provides RefreshAll).
local function Apply() if CDF.RefreshAll then CDF.RefreshAll() end end

local function SpecOptions(class)
    local opts = { { text = "Toutes spes", value = 0 } }
    if class == CDF.PlayerClass() and GetNumSpecializations then
        for i = 1, (GetNumSpecializations() or 0) do
            local id, name = GetSpecializationInfo(i)
            if id then opts[#opts + 1] = { text = name or ("Spe " .. i), value = id } end
        end
    end
    return opts
end

local function EntryDesc(e)
    local k, who = e.kind, "?"
    if k == "spell" then who = "Sort " .. tostring(e.id)
    elseif k == "item" then who = "Objet " .. tostring(e.id)
    elseif k == "itemPreset" then
        local p = CDF.PRESETS[e.preset]
        who = "Preset " .. ((p and p.name) or e.preset or "?")
    elseif k == "equippedTrinket" then who = "Bijou (slot " .. tostring(e.slot) .. ")"
    elseif k == "racial" then who = "Racial"
    end
    local spec = (not e.spec or e.spec == 0) and "toutes spes" or ("spe " .. tostring(e.spec))
    return who .. "  -  " .. spec
end

local function Bars() return CDF.GetClassBars(state.class) end
local function SelectedBar() return state.barId and CDF.GetBar(state.class, state.barId) or nil end
local function Refresh() -- forward decl
end

-- ---------------------------------------------------------------------
-- Cooldown Studio launcher
--
-- The Studio ships as a sibling LoadOnDemand addon (TomoMod_CDStudio), so
-- every load failure the client can report has to be turned into something
-- the player can act on. LoadAddOn hands back a locale-independent token:
-- "DISABLED" means the folder is installed but left unchecked in the addon
-- list, "MISSING" means it is genuinely absent -- two very different fixes
-- that the old single catch-all message conflated.
-- ---------------------------------------------------------------------
local STUDIO = "TomoMod_CDStudio"
local PREFIX = "|cff2ed884TomoMod|r : "

-- Per-token remediation advice. The client already localises the reason
-- itself through _G["ADDON_"..token]; what it never says is what to do.
local STUDIO_HINT = {
    MISSING               = "le dossier TomoMod_CDStudio est absent de Interface/AddOns. Il s'installe a cote de TomoMod, jamais dedans.",
    DISABLED              = "le sous-addon est decoche dans la liste des addons. Coche \"TomoMod Cooldown Studio\", puis recharge l'interface.",
    DEP_DISABLED          = "une dependance du Studio est decochee dans la liste des addons.",
    DEP_MISSING           = "une dependance du Studio est absente.",
    INTERFACE_VERSION     = "le Studio est marque obsolete pour cette version du jeu. Coche \"Charger les AddOns obsoletes\" a l'ecran de selection de personnage.",
    DEP_INTERFACE_VERSION = "une dependance du Studio est marquee obsolete pour cette version du jeu.",
    CORRUPT               = "les fichiers du Studio sont endommages. Reinstalle TomoMod.",
    DEP_CORRUPT           = "une dependance du Studio est endommagee.",
    BANNED                = "le Studio est bloque par le client.",
    NOT_DEMAND_LOADED     = "le Studio n'est pas marque LoadOnDemand.",
    DEMAND_LOADED         = "le Studio n'est pas marque LoadOnDemand.",
    INSECURE              = "le Studio a ete refuse par le client.",
}

local function StudioReasonText(reason)
    if not reason then return nil end
    local hint  = STUDIO_HINT[reason]
    local label = _G["ADDON_" .. reason] -- client wording, already localised
    if hint then
        return (label and (label .. " - ") or "") .. hint
    end
    return label or reason
end

-- Pre-flight state used to decorate the card. Never let a bad addon name
-- bubble an error up through the panel build.
local function StudioLoadReason()
    if C_AddOns.IsAddOnLoaded(STUDIO) then return nil end
    local ok, _, _, _, _, reason = pcall(C_AddOns.GetAddOnInfo, STUDIO)
    if not ok then return nil end
    return reason
end

-- Hoisted to module scope: BuildContent runs on every structural change, so
-- keeping this out of the button closure avoids re-allocating it per rebuild.
local function OpenStudio()
    if not C_AddOns.IsAddOnLoaded(STUDIO) then
        local ok, reason = C_AddOns.LoadAddOn(STUDIO)

        -- Self-heal the overwhelmingly common case: installed but unchecked.
        -- Enabling flips the client flag; the LoD load then succeeds straight
        -- away on most clients, and where it does not the enable still sticks
        -- so a single reload finishes the job.
        if not ok and reason == "DISABLED" and C_AddOns.EnableAddOn then
            pcall(C_AddOns.EnableAddOn, STUDIO)
            ok, reason = C_AddOns.LoadAddOn(STUDIO)
            if not ok then
                print(PREFIX .. "Cooldown Studio active. Recharge l'interface (/reload) pour l'ouvrir.")
                return
            end
        end

        if not ok then
            print(PREFIX .. "Cooldown Studio indisponible : "
                .. (StudioReasonText(reason) or "raison inconnue") .. ".")
            return
        end
    end

    -- LoadAddOn reported success but the entry point is missing: the sub-addon
    -- bailed out during its own load (it returns early when TomoMod_Widgets is
    -- unavailable) and publishes loadError to say why. Report it rather than
    -- swallowing the click.
    if not (TomoMod_CDStudio and TomoMod_CDStudio.Open) then
        local why = type(TomoMod_CDStudio) == "table" and TomoMod_CDStudio.loadError or nil
        print(PREFIX .. "Cooldown Studio charge mais non initialise"
            .. (why and (" (" .. why .. ")") or "") .. ". Recharge l'interface (/reload).")
        return
    end

    if TomoMod_Config and TomoMod_Config.Hide then TomoMod_Config.Hide() end
    TomoMod_CDStudio.Open()
end

-- ---------------------------------------------------------------------
-- Content builder
-- ---------------------------------------------------------------------
local function BuildContent(c)
    CDF = CDF or TomoMod_CooldownForge
    if not CDF or not CDF.DB or not CDF.DB() then
        W.CreateInfoText(c, "CooldownForge indisponible.", -12)
        c:SetHeight(80)
        return
    end
    state.class = state.class or CDF.PlayerClass() or "WARRIOR"

    local y = -12
    local card, cy

    -- STUDIO LAUNCHER [S1] ----------------------------------------------
    card, cy = W.CreateCard(c, "Cooldown Studio", y)
    _, cy = W.CreateInfoText(card.inner,
        "Editeur dedie plein ecran : barres, sorts, styles, partage et mode edition.", cy)
    _, cy = W.CreateButton(card.inner, "Ouvrir le Cooldown Studio", 240, cy, OpenStudio)
    -- Surface a blocking reason before the click. The button deliberately stays
    -- enabled: for DISABLED, clicking it is exactly what repairs the situation.
    local blocked = StudioLoadReason()
    if blocked then
        _, cy = W.CreateInfoText(card.inner,
            "Studio indisponible : " .. (StudioReasonText(blocked) or blocked), cy)
    end
    y = W.FinalizeCard(card, cy)

    -- CLASS ------------------------------------------------------------
    card, cy = W.CreateCard(c, "Classe editee", y)
    _, cy = W.CreateDropdown(card.inner, "Classe", CLASS_LIST, state.class, cy, function(v)
        state.class = v; state.barId = nil; Refresh()
    end)
    _, cy = W.CreateInfoText(card.inner, "Configure n'importe quelle classe depuis ce personnage.", cy)
    y = W.FinalizeCard(card, cy)

    -- BARS -------------------------------------------------------------
    card, cy = W.CreateCard(c, "Barres", y)
    local bars = Bars() or {}
    if #bars > 0 then
        if not state.barId or not CDF.GetBar(state.class, state.barId) then state.barId = bars[1].id end
        local opts = {}
        for i = 1, #bars do opts[i] = { text = bars[i].name or ("Bar " .. i), value = bars[i].id } end
        _, cy = W.CreateDropdown(card.inner, "Barre", opts, state.barId, cy, function(v)
            state.barId = v; Refresh()
        end)
    else
        state.barId = nil
        _, cy = W.CreateInfoText(card.inner, "Aucune barre pour cette classe.", cy)
    end
    _, cy = W.CreateButton(card.inner, "+ Nouvelle barre", 170, cy, function()
        local _, id = CDF.CreateBar(state.class, "Nouvelle barre")
        state.barId = id; Apply(); Refresh()
    end)
    if state.barId then
        _, cy = W.CreateButton(card.inner, "Dupliquer", 130, cy, function()
            local _, id = CDF.DuplicateBar(state.class, state.barId)
            if id then state.barId = id end
            Apply(); Refresh()
        end)
        _, cy = W.CreateButton(card.inner, "Supprimer", 130, cy, function()
            CDF.DeleteBar(state.class, state.barId); state.barId = nil
            Apply(); Refresh()
        end)
        _, cy = W.CreateMultiLineEditBox(card.inner, "Renommer", 24, cy, {
            onTextChanged = function(t) state.renameText = t end,
        })
        _, cy = W.CreateButton(card.inner, "Appliquer le nom", 170, cy, function()
            if state.renameText and state.renameText ~= "" then
                CDF.RenameBar(state.class, state.barId, state.renameText); Refresh()
            end
        end)
    end
    y = W.FinalizeCard(card, cy)

    local bar = SelectedBar()
    if bar then
        -- SETTINGS -----------------------------------------------------
        card, cy = W.CreateCard(c, "Reglages -- " .. (bar.name or ""), y)
        _, cy = W.CreateDropdown(card.inner, "Style visuel",
            { { text = "Tomo (carte)", value = "tomo" },
              { text = "Net (pixel)", value = "net" },
              { text = "Verre (moderne)", value = "verre" } },
            (bar.style and bar.style.preset) or "tomo", cy, function(v)
                bar.style = bar.style or {}
                bar.style.preset = v
                Apply()
            end)
        _, cy = W.CreateCheckbox(card.inner, "Griser pendant le cooldown",
            (bar.style and bar.style.desatOnCooldown) == true, cy, function(v)
                bar.style = bar.style or {}
                bar.style.desatOnCooldown = v
                Apply()
            end)
        -- [S9] castability tint (hors cooldown mais pas lancable)
        _, cy = W.CreateDropdown(card.inner, "Ressource insuffisante",
            { { text = "Aucun effet", value = "off" },
              { text = "Griser", value = "dim" },
              { text = "Griser + teinte bleue (ressource)", value = "resource" } },
            (bar.style and bar.style.unusableMode) or "off", cy, function(v)
                bar.style = bar.style or {}
                bar.style.unusableMode = (v ~= "off") and v or nil
                Apply()
            end)
        local mode = bar.layout or "line"
        _, cy = W.CreateSegmentedControl(card.inner, "Disposition",
            { { text = "En ligne", value = "line" }, { text = "En cercle", value = "radial" } },
            mode, cy, function(v) bar.layout = v; Apply(); Refresh() end, 2)
        _, cy = W.CreateSlider(card.inner, "Taille des icones", bar.iconSize, 24, 64, 1, cy,
            function(v) bar.iconSize = v; Apply() end, "%.0f px")
        if mode == "radial" then
            bar.radial = bar.radial or { radius = 90, startAngle = 90, arc = 360, clockwise = true }
            local rad = bar.radial
            _, cy = W.CreateSlider(card.inner, "Rayon", rad.radius or 90, 20, 400, 5, cy,
                function(v) rad.radius = v; Apply() end, "%.0f px")
            _, cy = W.CreateSlider(card.inner, "Angle de depart", rad.startAngle or 90, 0, 359, 5, cy,
                function(v) rad.startAngle = v; Apply() end, "%.0f deg")
            _, cy = W.CreateSlider(card.inner, "Amplitude de l'arc", rad.arc or 360, 30, 360, 5, cy,
                function(v) rad.arc = v; Apply() end, "%.0f deg")
            _, cy = W.CreateCheckbox(card.inner, "Sens horaire", rad.clockwise ~= false, cy,
                function(v) rad.clockwise = v; Apply() end)
        else
            _, cy = W.CreateSegmentedControl(card.inner, "Orientation",
                { { text = "Horizontale", value = "horizontal" }, { text = "Verticale", value = "vertical" } },
                bar.orientation, cy, function(v) bar.orientation = v; Apply() end, 2)
            _, cy = W.CreateDropdown(card.inner, "Direction",
                { { text = "Droite", value = "RIGHT" }, { text = "Gauche", value = "LEFT" },
                  { text = "Bas", value = "DOWN" }, { text = "Haut", value = "UP" } },
                bar.growth, cy, function(v) bar.growth = v; Apply() end)
            _, cy = W.CreateSlider(card.inner, "Espacement (dans la ligne)", bar.spacing, 0, 64, 1, cy,
                function(v) bar.spacing = v; Apply() end, "%.0f px")
            _, cy = W.CreateSlider(card.inner, "Espacement (entre les lignes)",
                bar.spacingCross or bar.spacing or 4, 0, 64, 1, cy,
                function(v) bar.spacingCross = v; Apply() end, "%.0f px")
            _, cy = W.CreateSlider(card.inner, "Retour ligne apres (0 = off)", bar.wrap, 0, 12, 1, cy,
                function(v) bar.wrap = v; Apply() end, "%.0f")
        end
        _, cy = W.CreateCheckbox(card.inner, "Masquer une icone pendant son cooldown",
            bar.hideOnCooldown == true, cy, function(v) bar.hideOnCooldown = v; Apply() end)
        _, cy = W.CreateCheckbox(card.inner, "Masquer une icone quand la ressource manque",
            bar.hideOnUnusable == true, cy, function(v) bar.hideOnUnusable = v; Apply() end)
        _, cy = W.CreateDropdown(card.inner, "Texte",
            { { text = "Minuteur", value = "timer" }, { text = "Nom", value = "name" }, { text = "Aucun", value = "none" } },
            bar.text.mode, cy, function(v) bar.text.mode = v; Apply() end)
        _, cy = W.CreateCheckbox(card.inner, "Afficher les charges (stacks)", bar.text.stacks, cy,
            function(v) bar.text.stacks = v; Apply() end)
        _, cy = W.CreateCheckbox(card.inner, "Glow", bar.glow.enabled, cy,
            function(v) bar.glow.enabled = v; Apply() end)
        _, cy = W.CreateDropdown(card.inner, "Condition du glow",
            { { text = "Quand le sort est pret", value = "ready" },
              { text = "Quand le sort est utilisable", value = "usable" },
              { text = "Quand le buff est actif", value = "aura" },
              { text = "Toujours", value = "always" } },
            bar.glow.condition or "ready", cy, function(v)
                bar.glow.condition = v; Apply()
            end)
        _, cy = W.CreateDropdown(card.inner, "Type de glow",
            { { text = "Pixel", value = "Pixel" }, { text = "Autocast", value = "Autocast" }, { text = "Button", value = "Button" } },
            bar.glow.type, cy, function(v) bar.glow.type = v; Apply() end)
        _, cy = W.CreateColorPicker(card.inner, "Couleur du glow", colorProxy(bar.glow.color), cy,
            function(r, g, b) writeColor(bar.glow.color, r, g, b); Apply() end)
        _, cy = W.CreateCheckbox(card.inner, "Swipe", bar.swipe.draw, cy,
            function(v) bar.swipe.draw = v; Apply() end)
        _, cy = W.CreateColorPicker(card.inner, "Couleur du swipe", colorProxy(bar.swipe.color), cy,
            function(r, g, b) writeColor(bar.swipe.color, r, g, b); Apply() end)
        _, cy = W.CreateCheckbox(card.inner, "Swipe inverse", bar.swipe.reverse, cy,
            function(v) bar.swipe.reverse = v; Apply() end)
        y = W.FinalizeCard(card, cy)

        -- ENTRIES ------------------------------------------------------
        card, cy = W.CreateCard(c, "Entrees", y)
        local es = bar.entries or {}
        if #es == 0 then
            _, cy = W.CreateInfoText(card.inner, "Aucune entree.", cy)
        end
        for i = 1, #es do
            local idx = i
            _, cy = W.CreateInfoText(card.inner, i .. ". " .. EntryDesc(es[i]), cy)
            _, cy = W.CreateButton(card.inner, "Retirer", 110, cy, function()
                CDF.RemoveEntry(state.class, state.barId, idx)
                Apply(); Refresh()
            end)
        end

        _, cy = W.CreateSubLabel(card.inner, "Ajouter par ID", cy)
        _, cy = W.CreateDropdown(card.inner, "Type",
            { { text = "Sort (spellID)", value = "spell" }, { text = "Objet (itemID)", value = "item" },
              { text = "Bijou equipe (slot)", value = "equippedTrinket" } },
            state.addKind, cy, function(v) state.addKind = v end)
        _, cy = W.CreateMultiLineEditBox(card.inner, "ID / slot", 24, cy, {
            onTextChanged = function(t) state.addId = t end,
        })
        _, cy = W.CreateDropdown(card.inner, "Visibilite (spec)", SpecOptions(state.class), state.addSpec, cy,
            function(v) state.addSpec = v end)
        _, cy = W.CreateButton(card.inner, "Ajouter", 130, cy, function()
            local data = { kind = state.addKind, spec = state.addSpec }
            if state.addKind == "equippedTrinket" then data.slot = tonumber(state.addId)
            else data.id = tonumber(state.addId) end
            if CDF.AddEntry(state.class, state.barId, data) then
                state.addId = ""
                Apply(); Refresh()
            end
        end)

        _, cy = W.CreateSubLabel(card.inner, "Presets (communs a la classe)", cy)
        local function addPreset(data)
            CDF.AddEntry(state.class, state.barId, data)
            Apply(); Refresh()
        end
        _, cy = W.CreateButton(card.inner, "Bijou (slot 13)", 160, cy, function() addPreset({ kind = "equippedTrinket", slot = 13 }) end)
        _, cy = W.CreateButton(card.inner, "Bijou (slot 14)", 160, cy, function() addPreset({ kind = "equippedTrinket", slot = 14 }) end)
        _, cy = W.CreateButton(card.inner, "Racial (auto)", 160, cy, function() addPreset({ kind = "racial" }) end)
        for key, p in pairs(CDF.PRESETS or {}) do
            local pk = key
            _, cy = W.CreateButton(card.inner, "Preset: " .. ((p and p.name) or key), 200, cy, function()
                addPreset({ kind = "itemPreset", preset = pk })
            end)
        end
        y = W.FinalizeCard(card, cy)
    end

    -- IMPORT / EXPORT --------------------------------------------------
    card, cy = W.CreateCard(c, "Import / Export", y)
    _, cy = W.CreateInfoText(card.inner, "Exporte la classe " .. state.class .. " (position retiree ; fusion par barre a l'import).", cy)
    _, cy = W.CreateButton(card.inner, "Exporter", 130, cy, function()
        local s = CDF.Export and CDF.Export(state.class)
        state.exportText = s or ""
        Refresh()
    end)
    local exBox
    exBox, cy = W.CreateMultiLineEditBox(card.inner, "Chaine export (lecture seule)", 56, cy, { readOnly = true })
    if exBox and exBox.editBox then exBox.editBox:SetText(state.exportText or "") end
    _, cy = W.CreateMultiLineEditBox(card.inner, "Coller une chaine a importer", 56, cy, {
        onTextChanged = function(t) state.importText = t end,
    })
    _, cy = W.CreateButton(card.inner, "Importer", 130, cy, function()
        local okI, res = CDF.Import and CDF.Import(state.importText or "")
        if okI then
            state.importText = ""
            if type(res) == "table" and res.class then state.class = res.class; state.barId = nil end
            Apply(); Refresh()
        end
    end)
    y = W.FinalizeCard(card, cy)

    c:SetHeight(abs(y) + 20)
end

-- Rebuild the currently open panel in place.
Refresh = function()
    local scroll = state.scroll
    if not scroll or not scroll.child or not scroll:IsShown() then return end
    if W.CloseDropdowns then W.CloseDropdowns() end
    local c = scroll.child
    local bin = GetBin()
    local kids = { c:GetChildren() }
    for i = 1, #kids do kids[i]:Hide(); kids[i]:SetParent(bin) end
    BuildContent(c)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
end

-- ---------------------------------------------------------------------
-- Panel entry point (consumed by ConfigUI via _G lookup)
-- ---------------------------------------------------------------------
function TomoMod_ConfigPanel_CooldownForge(parent)
    CDF = CDF or TomoMod_CooldownForge
    if CDF then CDF.EditorRefresh = Refresh end
    local scroll = W.CreateScrollPanel(parent)
    state.scroll = scroll
    BuildContent(scroll.child)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

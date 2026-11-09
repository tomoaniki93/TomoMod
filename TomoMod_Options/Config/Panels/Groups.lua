-- =====================================================================
-- Panels/Groups.lua -- "Groupe" : party and raid frames
-- Replaces the Party & Raid Studio. While a page is open and the player
-- is not grouped, stand-in frames are drawn where the real ones go and
-- follow every slider live.
-- =====================================================================

local K = TomoMod_Kit
local T = K.T

local SECTION = "group"

-- Healer indicator editor state (see the end of this file).
local HS = { mode = "party", class = nil, sel = nil, layout = nil }

local HEALTH_COLORS = {
    { text = T("Classe", "Class"),     value = "class" },
    { text = T("Vert", "Green"),       value = "green" },
    { text = T("Dégradé", "Gradient"), value = "gradient" },
}

local GROW = {
    { text = T("Vers le bas", "Down"),     value = "DOWN" },
    { text = T("Vers le haut", "Up"),      value = "UP" },
    { text = T("Vers la droite", "Right"), value = "RIGHT" },
    { text = T("Vers la gauche", "Left"),  value = "LEFT" },
}

local function ModuleToggle(c, key, label, apply)
    c:Toggle(label, {
        get = function() return K.IsModuleOn(key) end,
        set = function(v) K.SetModule(key, v) end,
    }, apply)
end

-- Shared between party and raid: both modules use the same field names.
local function CommonCards(page, root, ap)
    local p = root .. "."

    local c = page:Card(T("Vie", "Health"))
    c:Seg(T("Couleur de la barre", "Bar colour"), p .. "healthColor", HEALTH_COLORS, ap, 3)
    c:Select(T("Texture", "Texture"), p .. "texture", K.TEXTURES, ap)
    c:Pair(function(l) l:Toggle(T("Vie en texte", "Health text"), p .. "showHealthText", ap) end,
           function(r) r:Select(T("Format", "Format"), p .. "healthTextFormat", {
                { text = T("Pourcentage", "Percent"), value = "percent" },
                { text = T("Valeur", "Current"), value = "current" },
                { text = T("Valeur + %", "Current + %"), value = "current_percent" },
                { text = T("Manquant", "Deficit"), value = "deficit" },
            }, ap) end)
    c:Pair(function(l) l:Toggle(T("Boucliers", "Shields"), p .. "showAbsorb", ap) end,
           function(r) r:Toggle(T("Soins entrants", "Incoming heals"), p .. "showHealPrediction", ap) end)
    c:Pair(function(l) l:Toggle(T("Barre de mana", "Mana bar"), p .. "showPower", ap) end,
           function(r) r:Slider(T("Hauteur mana", "Mana height"), p .. "powerHeight", 1, 10, 1, ap) end)
    c:Done()

    c = page:Card(T("Nom et icônes", "Name and icons"))
    c:Pair(function(l) l:Toggle(T("Nom", "Name"), p .. "showName", ap) end,
           function(r) r:Slider(T("Lettres max (0 = tout)", "Max letters (0 = all)"), p .. "nameMaxLength", 0, 20, 1, ap) end)
    c:Pair(function(l) l:Toggle(T("Icône de rôle", "Role icon"), p .. "showRoleIcon", ap) end,
           function(r) r:Toggle(T("Marque de raid", "Raid marker"), p .. "showRaidMarker", ap) end)
    c:Select(T("Police", "Font"), p .. "font", K.FONTS, ap)
    c:Slider(T("Taille du texte", "Text size"), p .. "fontSize", 7, 18, 1, ap)
    c:Done()

    c = page:Card(T("Soins et dissipation", "Healing and dispels"))
    c:Toggle(T("Alerte de débuff à dissiper (contour + icône)", "Dispellable debuff alert (outline + icon)"), p .. "showDispel", ap)
    c:Pair(function(l) l:Toggle(T("Mes soins sur la durée", "My heals over time"), p .. "showHoTs", ap) end,
           function(r) r:Slider(T("Nombre max", "Max count"), p .. "maxHoTs", 1, 6, 1, ap) end)
    c:Pair(function(l) l:Toggle(T("Défensifs reçus", "External defensives"), p .. "showDefensives", ap) end,
           function(r) r:Toggle(T("Résurrection en cours", "Incoming resurrection"), p .. "showResurrectIndicator", ap) end)
    c:Button(T("Placer mes soins sur le cadre...", "Place my heals on the frame..."), function()
        HS.mode = (root == "raidFrames") and "raid" or "party"
        HS.sel = nil
        local C = TomoMod_Config
        if C and C.OpenCategory then C.OpenCategory("healer") end
    end, 260)
    c:Done()

    c = page:Card(T("Portée", "Range"))
    c:Toggle(T("Assombrir les membres hors de portée", "Fade out-of-range members"), p .. "showRange", ap)
    c:Slider(T("Opacité hors de portée", "Out of range opacity"), p .. "oorAlpha", 0.1, 1, 0.05, ap, "%.2f")
    c:Done()

    c = page:Card(T("Tailles des icônes", "Icon sizes"), { adv = true })
    c:Pair(function(l) l:Slider(T("Soins sur la durée", "Heals over time"), p .. "hotSize", 6, 30, 1, ap) end,
           function(r) r:Slider(T("Dissipation", "Dispel"), p .. "dispelSize", 8, 40, 1, ap) end)
    c:Pair(function(l) l:Slider(T("Défensifs", "Defensives"), p .. "defensiveIconSize", 8, 30, 1, ap) end,
           function(r) r:Slider(T("Rôle", "Role"), p .. "roleIconSize", 8, 30, 1, ap) end)
    c:Pair(function(l) l:Slider(T("Épaisseur du contour", "Outline thickness"), p .. "dispelBorderSize", 1, 6, 1, ap) end,
           function(r) r:Toggle(T("Durée sur les soins", "Duration on heals"), p .. "hotShowDuration", ap) end)
    c:Done()
end

-- ---------------------------------------------------------------------
-- Party
-- ---------------------------------------------------------------------
K.RegisterPage({
    key = "party",
    section = SECTION,
    label = T("Groupe (5)", "Party (5)"),
    kw = "party group groupe frames cadres donjon dungeon healer soigneur",
    locate = "TomoMod_PartyAnchor",
    onShow = function() K.PartyPreview(true) end,
    onHide = function() K.PartyPreview(false) end,
    build = function(parent)
        return K.Page(parent, function(page)
            page:Hero(T("Cadres de groupe", "Party frames"),
                T("Hors groupe, un aperçu de 5 membres s'affiche à l'emplacement réel pendant que tu règles.",
                  "Outside a group, a 5-member preview is drawn at the real spot while you tune it."),
                function() return _G.TomoMod_PartyAnchor end, T("Groupe", "Party"))

            local c = page:Card(T("Activation", "On / off"))
            ModuleToggle(c, "partyFrames", T("Utiliser les cadres de groupe TomoMod", "Use TomoMod party frames"), "party")
            c:Toggle(T("Trier par rôle (tank, soigneur, dégâts)", "Sort by role (tank, healer, damage)"), "partyFrames.sortByRole", "party")
            c:Done()

            c = page:Card(T("Taille et disposition", "Size and layout"))
            c:Pair(function(l) l:Slider(T("Largeur", "Width"), "partyFrames.width", 60, 300, 1, "party") end,
                   function(r) r:Slider(T("Hauteur", "Height"), "partyFrames.height", 16, 100, 1, "party") end)
            c:Slider(T("Espace entre les membres", "Space between members"), "partyFrames.spacing", 0, 30, 1, "party")
            c:Seg(T("Direction", "Direction"), "partyFrames.growDirection", GROW, "party", 4)
            c:Done()

            CommonCards(page, "partyFrames", "party")
            page:StudioLink("group", "party", "Party & Raid Studio")
        end)
    end,
})

-- ---------------------------------------------------------------------
-- Raid
-- ---------------------------------------------------------------------
K.RegisterPage({
    key = "raid",
    section = SECTION,
    label = T("Raid", "Raid"),
    kw = "raid frames cadres raid grille grid healer soigneur",
    locate = "TomoMod_RaidAnchor",
    onShow = function() K.RaidPreview(true) end,
    onHide = function() K.RaidPreview(false) end,
    build = function(parent)
        return K.Page(parent, function(page)
            page:Hero(T("Cadres de raid", "Raid frames"),
                T("Hors raid, une grille de 20 membres s'affiche pour régler la taille et l'espacement.",
                  "Outside a raid, a 20-member grid is drawn so you can tune size and spacing."),
                function() return _G.TomoMod_RaidAnchor end, T("Raid", "Raid"))
            page:RaidPreview()

            local c = page:Card(T("Activation", "On / off"))
            ModuleToggle(c, "raidFrames", T("Utiliser les cadres de raid TomoMod", "Use TomoMod raid frames"), "raid")
            c:Toggle(T("Trier par rôle", "Sort by role"), "raidFrames.sortByRole", "raid")
            c:Done()

            c = page:Card(T("Taille et disposition", "Size and layout"))
            c:Seg(T("Disposition", "Layout"), "raidFrames.layout", {
                { text = T("Grille", "Grid"), value = "grid" },
                { text = T("Liste", "List"), value = "list" },
            }, "raid", 2)
            c:Pair(function(l) l:Slider(T("Largeur", "Width"), "raidFrames.width", 30, 200, 1, "raid") end,
                   function(r) r:Slider(T("Hauteur", "Height"), "raidFrames.height", 14, 80, 1, "raid") end)
            c:Pair(function(l) l:Slider(T("Espace", "Spacing"), "raidFrames.spacing", 0, 20, 1, "raid") end,
                   function(r) r:Slider(T("Espace entre groupes", "Group spacing"), "raidFrames.groupSpacing", 0, 30, 1, "raid") end)
            c:Done()

            CommonCards(page, "raidFrames", "raid")

            c = page:Card(T("Débuffs", "Debuffs"))
            c:Toggle(T("Afficher les débuffs", "Show debuffs"), "raidFrames.showDebuffs", "raid")
            c:Pair(function(l) l:Slider(T("Nombre", "Count"), "raidFrames.maxDebuffs", 1, 6, 1, "raid") end,
                   function(r) r:Slider(T("Taille", "Size"), "raidFrames.debuffSize", 8, 30, 1, "raid") end)
            c:Done()

            c = page:Card(T("Taille selon le raid (10 / 25 / 40)", "Size by raid size (10 / 25 / 40)"), { adv = true })
            c:Toggle(T("Adapter la taille au nombre de joueurs", "Adapt size to player count"), "raidFrames.raidSizeOverrides.enabled", "raid")
            for _, n in ipairs({ "10", "25", "40" }) do
                local p = "raidFrames.raidSizeOverrides." .. n .. "."
                c:Label(n .. T(" joueurs", " players"))
                c:Pair(function(l) l:Slider(T("Largeur", "Width"), p .. "width", 30, 200, 1, "raid") end,
                       function(r) r:Slider(T("Hauteur", "Height"), p .. "height", 14, 80, 1, "raid") end)
            end
            c:Done()

            c = page:Card(T("Compteur de résurrections de combat", "Battle-rez counter"), { adv = true })
            c:Toggle(T("Afficher", "Show"), "battleRez.enabled", "rez")
            c:Toggle(T("Seulement en instance", "Instances only"), "battleRez.onlyInstance", "rez")
            c:Slider(T("Taille", "Size"), "battleRez.size", 24, 80, 1, "rez")
            c:Done()

            c = page:Card(T("Habillage du gestionnaire de groupe", "Group manager skin"), { adv = true })
            c:Toggle(T("Habiller le gestionnaire de raid Blizzard", "Skin Blizzard's raid manager"), "raidFrames.skinGroupManager", function()
                local GM = TomoMod_GroupManagerSkin
                if GM and GM.ApplySettings then GM.ApplySettings() end
            end)
            c:Done()
            page:StudioLink("group", "raid", "Party & Raid Studio")
        end)
    end,
})

-- ---------------------------------------------------------------------
-- Healer indicators (was the "Healer" tab of the Party & Raid Studio)
-- Each healer spell (HoT, shield, beacon...) gets its own icon, placed
-- anywhere on the party or raid cell. Drag the icons on the preview.
-- ---------------------------------------------------------------------
local W  = TomoMod_Widgets
local TH = W.Theme
local WHITE = K.WHITE or "Interface\\Buttons\\WHITE8x8"


local CATEGORY = {
    hot      = { "Soin sur la durée", "Heal over time" },
    shield   = { "Bouclier", "Shield" },
    beacon   = { "Guide", "Beacon" },
    marker   = { "Marqueur", "Marker" },
    external = { "Défensif", "External" },
}

local function HIe() return TomoMod_HealerIndicators end

local function DefaultClass()
    local HI = HIe()
    local cls = HI and HI.GetPlayerClass and HI.GetPlayerClass()
    if HI and HI.IsHealerClass(cls) then return cls end
    return HI and HI.CLASS_ORDER[1] or "PRIEST"
end

local function NotInCombat()
    if InCombatLockdown() then
        K.Toast(T("En combat : réessaie après le combat", "In combat: try again after combat"), 1, 0.4, 0.3)
        return false
    end
    return true
end

local function Entry(spellID)
    local HI = HIe()
    return HI and spellID and HI.GetEntry(HS.mode, HS.class, spellID) or nil
end

local function CellSize()
    local db = TomoModDB and TomoModDB[HS.mode == "raid" and "raidFrames" or "partyFrames"] or {}
    if HS.mode == "raid" then return tonumber(db.width) or 72, tonumber(db.height) or 36 end
    return tonumber(db.width) or 160, tonumber(db.height) or 40
end

local function Clamp(v, a, b) if v < a then return a elseif v > b then return b end return v end
local function Round(v) return math.floor(v + 0.5) end

local function AnchorXY(f, point)
    local l, r, b, t = f:GetLeft(), f:GetRight(), f:GetBottom(), f:GetTop()
    if not (l and r and b and t) then return nil end
    local x = point:find("LEFT") and l or point:find("RIGHT") and r or (l + r) / 2
    local y = point:find("TOP") and t or point:find("BOTTOM") and b or (b + t) / 2
    return x, y
end

-- The interactive cell. Returns the new y.
local function BuildHealerPreview(parent, y)
    local HI = HIe()
    local holder = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    holder:SetPoint("TOPLEFT", 16, y)
    holder:SetPoint("TOPRIGHT", -16, y)
    holder:SetHeight(190)
    holder:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    holder:SetBackdropColor(0.025, 0.025, 0.032, 0.9)
    holder:SetBackdropBorderColor(TH.border[1], TH.border[2], TH.border[3], 1)

    local cell = CreateFrame("Frame", nil, holder, "BackdropTemplate")
    cell:SetPoint("CENTER")
    cell:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    cell:SetBackdropColor(0.045, 0.045, 0.060, 1)
    cell:SetBackdropBorderColor(0, 0, 0, 1)
    local hp = cell:CreateTexture(nil, "BORDER")
    hp:SetTexture(WHITE)
    local r, g, b = 0.2, 0.75, 0.35
    local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[HS.class]
    if cc then r, g, b = cc.r, cc.g, cc.b end
    hp:SetVertexColor(r * 0.8, g * 0.8, b * 0.8, 1)
    local pw = cell:CreateTexture(nil, "BORDER")
    pw:SetTexture(WHITE)
    pw:SetVertexColor(0.2, 0.45, 1, 1)
    local nm = cell:CreateFontString(nil, "OVERLAY")
    nm:SetFont(K.FONT, 11, "OUTLINE")
    nm:SetPoint("CENTER")
    nm:SetText(UnitName("player") or "Tomo")

    local hint = holder:CreateFontString(nil, "OVERLAY")
    hint:SetFont(K.FONT, 10, "")
    hint:SetPoint("BOTTOM", 0, 6)
    hint:SetTextColor(TH.textDim[1], TH.textDim[2], TH.textDim[3], 1)
    hint:SetText(T("Glisse les icônes pour les placer. Clic : choisir.", "Drag the icons to place them. Click: select."))

    local icons = {}
    local scale = 2

    local function Place(icon, e)
        local size = Clamp(tonumber(e.size) or 12, HI.MIN_SIZE, HI.MAX_SIZE)
        icon:SetSize(size * scale, size * scale)
        local p = e.point or "TOPLEFT"
        icon:ClearAllPoints()
        icon:SetPoint(p, cell, p, (tonumber(e.x) or 0) * scale, (tonumber(e.y) or 0) * scale)
        local mode = HI.GetModeDB(HS.mode)
        icon.dur:SetFont(K.FONT, math.max(6, 9 * scale), "OUTLINE")
        icon.dur:SetShown(not (mode and mode.showDuration == false))
    end

    local function Layout()
        local w, h = CellSize()
        local avail = (holder:GetWidth() or 0) - 24
        if avail < 60 then avail = 320 end
        scale = Clamp(math.min(avail / math.max(w, 1), 150 / math.max(h, 1)), 1, 4)
        cell:SetSize(w * scale, h * scale)
        local pH = math.max(3, h * scale * 0.08)
        hp:ClearAllPoints()
        hp:SetPoint("TOPLEFT", 1, -1)
        hp:SetPoint("BOTTOMRIGHT", -1, 1 + pH)
        pw:ClearAllPoints()
        pw:SetPoint("BOTTOMLEFT", 1, 1)
        pw:SetPoint("BOTTOMRIGHT", -1, 1)
        pw:SetHeight(pH)
        local classDB = HI.EnsureClass(HS.mode, HS.class)
        local shown = {}
        for _, id in ipairs(HI.GetSpellsForClass(HS.class)) do
            local e = classDB and classDB.spells[id]
            if e and e.enabled then
                local icon = icons[id]
                if not icon then
                    icon = CreateFrame("Button", nil, cell, "BackdropTemplate")
                    icon:SetMovable(true)
                    icon:RegisterForDrag("LeftButton")
                    icon:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
                    icon:SetBackdropColor(0, 0, 0, 0)
                    icon.tex = icon:CreateTexture(nil, "ARTWORK")
                    icon.tex:SetPoint("TOPLEFT", 1, -1)
                    icon.tex:SetPoint("BOTTOMRIGHT", -1, 1)
                    icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    icon.dur = icon:CreateFontString(nil, "OVERLAY")
                    icon.dur:SetFont(K.FONT, 9, "OUTLINE") -- a font before any SetText
                    icon.dur:SetPoint("CENTER")
                    icon.dur:SetText("12")
                    icon:SetScript("OnClick", function()
                        if HS.sel ~= id then HS.sel = id; K.RefreshPage() end
                    end)
                    icon:SetScript("OnDragStart", function(self)
                        if not NotInCombat() then return end
                        self:StartMoving()
                    end)
                    icon:SetScript("OnDragStop", function(self)
                        self:StopMovingOrSizing()
                        local en = Entry(id)
                        if not en then return end
                        local pl, pr, pb, pt = cell:GetLeft(), cell:GetRight(), cell:GetBottom(), cell:GetTop()
                        local cx, cy = self:GetCenter()
                        if pl and cx then
                            local hw, hh = self:GetWidth() / 2, self:GetHeight() / 2
                            cx = Clamp(cx, pl + hw, pr - hw)
                            cy = Clamp(cy, pb + hh, pt - hh)
                            self:ClearAllPoints()
                            self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
                            local mx, my = cell:GetCenter()
                            local cw, ch = cell:GetWidth(), cell:GetHeight()
                            local ho = cx < mx - cw / 6 and "LEFT" or cx > mx + cw / 6 and "RIGHT" or ""
                            local ve = cy > my + ch / 6 and "TOP" or cy < my - ch / 6 and "BOTTOM" or ""
                            local point = (ve .. ho ~= "") and (ve .. ho) or "CENTER"
                            local ix, iy = AnchorXY(self, point)
                            local hx, hy = AnchorXY(cell, point)
                            if ix and hx then
                                en.point = point
                                en.x = Round((ix - hx) / scale)
                                en.y = Round((iy - hy) / scale)
                            end
                            HI.Touch(HS.mode)
                        end
                        HS.sel = id
                        K.RefreshPage()
                    end)
                    icons[id] = icon
                end
                local _, tex = HI.GetSpellDisplay(id)
                icon.tex:SetTexture(tex)
                if id == HS.sel then
                    icon:SetBackdropBorderColor(TH.accent[1], TH.accent[2], TH.accent[3], 1)
                else
                    icon:SetBackdropBorderColor(0, 0, 0, 0.85)
                end
                Place(icon, e)
                icon:Show()
                shown[id] = true
            end
        end
        for id, icon in pairs(icons) do if not shown[id] then icon:Hide() end end
    end

    HS.layout = Layout
    holder:SetScript("OnSizeChanged", Layout)
    holder:SetScript("OnShow", Layout)
    Layout()
    return y - 200
end

-- One row per spell: tick to show it, click the row to edit it.
local function BuildSpellList(parent, y)
    local HI = HIe()
    local classDB = HI.EnsureClass(HS.mode, HS.class)
    for _, id in ipairs(HI.GetSpellsForClass(HS.class)) do
        local e = classDB and classDB.spells[id]
        local name, tex, cat = HI.GetSpellDisplay(id)
        local sel = (id == HS.sel)
        local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
        row:SetPoint("TOPLEFT", 16, y)
        row:SetPoint("TOPRIGHT", -16, y)
        row:SetHeight(32)
        row:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
        row:SetBackdropColor(TH.accent[1], TH.accent[2], TH.accent[3], sel and 0.20 or 0.03)
        row:SetBackdropBorderColor(TH.accent[1], TH.accent[2], TH.accent[3], sel and 0.9 or 0.15)

        local box = CreateFrame("Button", nil, row, "BackdropTemplate")
        box:SetSize(18, 18)
        box:SetPoint("LEFT", 8, 0)
        box:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
        box:SetBackdropColor(TH.bgDark[1], TH.bgDark[2], TH.bgDark[3], 1)
        local on = e and e.enabled
        box:SetBackdropBorderColor(on and TH.accent[1] or 0.35, on and TH.accent[2] or 0.3, on and TH.accent[3] or 0.25, 1)
        local fill = box:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", 4, -4)
        fill:SetPoint("BOTTOMRIGHT", -4, 4)
        fill:SetColorTexture(TH.accent[1], TH.accent[2], TH.accent[3], 1)
        fill:SetShown(on and true or false)
        box:SetScript("OnClick", function()
            if not NotInCombat() then return end
            local en = Entry(id)
            if not en then return end
            en.enabled = not en.enabled
            HS.sel = id
            HI.Commit(HS.mode)
            K.Toast(T("Appliqué", "Applied"))
            K.RefreshPage()
        end)

        local ic = row:CreateTexture(nil, "ARTWORK")
        ic:SetSize(22, 22)
        ic:SetPoint("LEFT", box, "RIGHT", 8, 0)
        ic:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        ic:SetTexture(tex)

        local nmText = row:CreateFontString(nil, "OVERLAY")
        nmText:SetFont(K.FONT, 11, "")
        nmText:SetPoint("LEFT", ic, "RIGHT", 8, 0)
        nmText:SetPoint("RIGHT", row, "RIGHT", -110, 0)
        nmText:SetJustifyH("LEFT")
        nmText:SetWordWrap(false)
        nmText:SetText(name)
        if sel then nmText:SetTextColor(1, 1, 1, 1) else nmText:SetTextColor(TH.text[1], TH.text[2], TH.text[3], 1) end

        local ct = row:CreateFontString(nil, "OVERLAY")
        ct:SetFont(K.FONT, 9, "")
        ct:SetPoint("RIGHT", -10, 0)
        ct:SetTextColor(TH.textDim[1], TH.textDim[2], TH.textDim[3], 1)
        local cl = CATEGORY[cat or "hot"] or CATEGORY.hot
        ct:SetText(T(cl[1], cl[2]))

        row:SetScript("OnClick", function()
            if HS.sel ~= id then HS.sel = id; K.RefreshPage() end
        end)
        y = y - 36
    end
    return y - 4
end

K.RegisterPage({
    key = "healer",
    section = SECTION,
    label = T("Indicateurs de soins", "Healer indicators"),
    kw = "healer soigneur soins hot bouclier shield guide beacon indicateurs indicators studio placement",
    build = function(parent)
        return K.Page(parent, function(page)
            local HI = HIe()
            page:Hero(T("Indicateurs de soins", "Healer indicators"),
                T("Une icône par sort de soin (soins sur la durée, boucliers, guides...), placée où tu veux sur tes cadres de groupe et de raid.",
                  "One icon per healing spell (heals over time, shields, beacons...), placed wherever you like on your party and raid frames."))
            if not HI then
                local c = page:Card(T("Indisponible", "Unavailable"))
                c:Done()
                return
            end
            if not (HS.class and HI.IsHealerClass(HS.class)) then HS.class = DefaultClass() end

            local c = page:Card(T("Cadres et classe", "Frames and class"))
            c:Seg(T("Cadres", "Frames"), {
                get = function() return HS.mode end,
                set = function(v) HS.mode = (v == "raid") and "raid" or "party"; HS.sel = nil; K.RefreshPage() end,
            }, {
                { text = T("Groupe", "Party"), value = "party" },
                { text = T("Raid", "Raid"),    value = "raid" },
            }, nil, 2)
            local classes = {}
            for _, tok in ipairs(HI.CLASS_ORDER) do
                classes[#classes + 1] = { text = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[tok]) or tok, value = tok }
            end
            c:Seg(T("Classe", "Class"), {
                get = function() return HS.class end,
                set = function(v) if HI.IsHealerClass(v) then HS.class = v; HS.sel = nil; K.RefreshPage() end end,
            }, classes, nil, 4)
            local modeDB = HI.GetModeDB(HS.mode)
            c:Toggle(T("Activer les indicateurs de soins", "Enable healer indicators"), {
                get = function() return modeDB and modeDB.enabled end,
                set = function(v)
                    if not NotInCombat() then return end
                    HI.SetModeEnabled(HS.mode, v, HS.class)
                    K.RefreshPage()
                end,
            }, nil, T("Remplace la rangée de soins sur la durée par tes icônes placées.",
                      "Replaces the heal-over-time row with your placed icons."))
            c:Pair(function(l) l:Toggle(T("Seulement en spécialisation soins", "Healer specialization only"), {
                        get = function() local r = HI.GetRootDB(); return r and r.onlyHealerSpec ~= false end,
                        set = function(v) local r = HI.GetRootDB(); if r then r.onlyHealerSpec = v and true or false end; HI.Commit() end,
                    }, nil) end,
                   function(r) r:Toggle(T("Durée restante", "Remaining duration"), {
                        get = function() return modeDB and modeDB.showDuration ~= false end,
                        set = function(v) if modeDB then modeDB.showDuration = v and true or false end; HI.Touch(HS.mode); K.RefreshPage() end,
                    }, nil) end)
            c:Pair(function(l) l:Button(T("Disposition de départ", "Starter layout"), function()
                        if not NotInCombat() then return end
                        HI.ApplyStarterPreset(HS.mode, HS.class); HI.Commit(HS.mode); K.RefreshPage()
                    end, 190) end,
                   function(r) r:Button(T("Réinitialiser la classe", "Reset this class"), function()
                        if not NotInCombat() then return end
                        HI.ResetClass(HS.mode, HS.class, false); HI.Commit(HS.mode); HS.sel = nil; K.RefreshPage()
                    end, 190) end)
            c:Done()

            c = page:Card(T("Aperçu", "Preview"))
            c:Custom(BuildHealerPreview)
            c:Done()

            c = page:Card(T("Sorts", "Spells"))
            c:Info(T("Coche un sort pour l'afficher, clique sur la ligne pour le régler.",
                     "Tick a spell to show it, click the row to adjust it."))
            c:Custom(BuildSpellList)
            c:Done()

            local e = Entry(HS.sel)
            if e then
                local name = HI.GetSpellDisplay(HS.sel)
                local cw, ch = CellSize()
                local function bind(field, after)
                    return {
                        get = function() local en = Entry(HS.sel); return en and en[field] end,
                        set = function(v)
                            local en = Entry(HS.sel); if not en then return end
                            en[field] = after and after(v) or v
                            HI.Touch(HS.mode)
                        end,
                    }
                end
                -- Live: the preview follows the slider without rebuilding the page.
                local touch = function() if HS.layout then HS.layout() end end
                c = page:Card(name)
                c:Slider(T("Taille de l'icône", "Icon size"), bind("size", function(v) return Clamp(v, HI.MIN_SIZE, HI.MAX_SIZE) end),
                    HI.MIN_SIZE, HI.MAX_SIZE, 1, touch)
                local points = {}
                for _, p in ipairs(HI.ANCHOR_POINTS) do points[#points + 1] = { text = p, value = p } end
                c:Select(T("Point d'ancrage", "Anchor"), bind("point"), points, touch)
                c:Pair(function(l) l:Slider(T("Décalage X", "Offset X"), bind("x", Round), -Round(cw), Round(cw), 1, touch) end,
                       function(r) r:Slider(T("Décalage Y", "Offset Y"), bind("y", Round), -Round(ch), Round(ch), 1, touch) end)
                c:Button(T("Remettre à sa place", "Reset its position"), function()
                    HI.ResetSpellPosition(HS.mode, HS.class, HS.sel); HI.Commit(HS.mode); K.RefreshPage()
                end, 200)
                c:Done()
            end
            page:StudioLink("group", "party", "Party & Raid Studio")
        end)
    end,
})

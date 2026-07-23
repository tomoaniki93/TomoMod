-- =====================================
-- CDMHolders.lua — v3.2.0 (Phase 4 : architecture "holders"
--
-- 4 conteneurs 100% TomoMod (un par viewer Blizzard) :
--   TomoModCDM_Essential / _Utility / _BuffIcon / _BuffBar
--
-- Principe :
--   * Blizzard gère tout l'état (cooldowns, swipes, secretvalues).
--   * On ne fait JAMAIS SetParent / Hide / Show / SetScale sur les frames Blizzard.
--   * Les icônes Blizzard sont seulement RÉ-ANCRÉES (SetPoint) sur nos holders
--     par CDMLayout — l'ancrage ne reparente pas, zéro taint.
--   * Les holders sont librement déplaçables (drag) et sauvegardés dans
--     TomoModDB.cooldownManager.viewerLayout[key].position (relatif CENTER UIParent).
--
-- Fournit :
--   * Mode placement live (drag + intégration TomoMod_Movers)
--   * Aperçu live : icônes/barres factices (frames à nous, toggle par alpha)
--     pour voir la disposition des viewers vides (buffs hors combat)
--   * Migration douce : au premier lancement, la position actuelle du viewer
--     Blizzard (Edit Mode) est capturée comme position de départ.
--
-- Chargé APRÈS CDMScanner, AVANT CDMLayout (CDMLayout s'y réfère en lazy).
-- =====================================

TomoMod_CDMHolders = TomoMod_CDMHolders or {}
local H = TomoMod_CDMHolders

local floor, max, min, ceil = math.floor, math.max, math.min, math.ceil

-- =====================================
-- CONSTANTES
-- =====================================
local FONT       = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local BORDER_TEX = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Nameplates\\border.png"
local BORDER_CORNER = 4
local ACCENT     = { r = 0.18, g = 0.85, b = 0.52 }   -- vert TomoMod (#2ED884)
local QUESTION_MARK_ICON = 134400                      -- INV_Misc_QuestionMark

-- Définition des 4 viewers
-- key       : clé canonique dans viewerLayout
-- frameName : nom global du viewer Blizzard
-- label     : libellé mover / GUI
-- defX/defY : position par défaut si le viewer Blizzard est introuvable
local VIEWER_DEFS = {
    { key = "essential", frameName = "EssentialCooldownViewer", label = "CDM Essential",  defX = 0,    defY = -180 },
    { key = "utility",   frameName = "UtilityCooldownViewer",   label = "CDM Utility",    defX = 0,    defY = -230 },
    { key = "buffIcon",  frameName = "BuffIconCooldownViewer",  label = "CDM Buff Icons", defX = 0,    defY = -120 },
    { key = "buffBar",   frameName = "BuffBarCooldownViewer",   label = "CDM Buff Bars",  defX = -320, defY = -100 },
}

-- =====================================
-- ÉTAT
-- =====================================
local holders       = {}    -- key -> holder frame
local holderByFrame = {}    -- viewer frame -> holder (weak keys)
setmetatable(holderByFrame, { __mode = "k" })
local defByKey      = {}
for _, def in ipairs(VIEWER_DEFS) do defByKey[def.key] = def end

local isLocked      = true
local previewActive = false
local initialized   = false

-- =====================================
-- DB
-- =====================================
local function GetCDMDB()
    return TomoModDB and TomoModDB.cooldownManager
end

local function VL(key)
    local db = GetCDMDB()
    if not db then return nil end
    db.viewerLayout = db.viewerLayout or {}
    db.viewerLayout[key] = db.viewerLayout[key] or {}
    return db.viewerLayout[key]
end
H.VL = VL   -- exporté pour le panneau de config

-- =====================================
-- 9-SLICE BORDER (copie locale, holders/placeholders uniquement)
-- =====================================
local function Create9SliceBorder(parent, r, g, b, a, sublevel)
    sublevel = sublevel or 7
    a = a or 1
    local parts = {}
    local function Tex()
        local t = parent:CreateTexture(nil, "OVERLAY", nil, sublevel)
        t:SetTexture(BORDER_TEX)
        if r then t:SetVertexColor(r, g, b, a) end
        parts[#parts + 1] = t
        return t
    end
    local tl = Tex(); tl:SetSize(BORDER_CORNER, BORDER_CORNER)
    tl:SetPoint("TOPLEFT"); tl:SetTexCoord(0, 0.5, 0, 0.5)
    local tr = Tex(); tr:SetSize(BORDER_CORNER, BORDER_CORNER)
    tr:SetPoint("TOPRIGHT"); tr:SetTexCoord(0.5, 1, 0, 0.5)
    local bl = Tex(); bl:SetSize(BORDER_CORNER, BORDER_CORNER)
    bl:SetPoint("BOTTOMLEFT"); bl:SetTexCoord(0, 0.5, 0.5, 1)
    local br = Tex(); br:SetSize(BORDER_CORNER, BORDER_CORNER)
    br:SetPoint("BOTTOMRIGHT"); br:SetTexCoord(0.5, 1, 0.5, 1)
    local top = Tex(); top:SetHeight(BORDER_CORNER)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("TOPRIGHT", tr, "TOPLEFT")
    top:SetTexCoord(0.5, 0.5, 0, 0.5)
    local bot = Tex(); bot:SetHeight(BORDER_CORNER)
    bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT"); bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
    bot:SetTexCoord(0.5, 0.5, 0.5, 1)
    local left = Tex(); left:SetWidth(BORDER_CORNER)
    left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT")
    left:SetTexCoord(0, 0.5, 0.5, 0.5)
    local right = Tex(); right:SetWidth(BORDER_CORNER)
    right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT"); right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
    right:SetTexCoord(0.5, 1, 0.5, 0.5)
    return parts
end

-- =====================================
-- POSITION
-- =====================================

--- Position sauvegardée (ou dérivée du viewer Blizzard au premier passage).
--- @return number x, number y  — offsets relatifs au CENTER de UIParent
function H.GetPosition(key)
    local vl = VL(key)
    if vl and vl.position and vl.position.x then
        return vl.position.x, vl.position.y
    end

    -- Migration douce : capture la position actuelle du viewer Blizzard
    local def = defByKey[key]
    local viewer = def and _G[def.frameName]
    if viewer and viewer.GetCenter then
        local vx, vy = viewer:GetCenter()
        local ux, uy = UIParent:GetCenter()
        if vx and ux then
            local scale = viewer:GetEffectiveScale() / UIParent:GetEffectiveScale()
            local x = floor(vx * scale - ux + 0.5)
            local y = floor(vy * scale - uy + 0.5)
            if vl then vl.position = { x = x, y = y } end
            return x, y
        end
    end

    return (def and def.defX) or 0, (def and def.defY) or -180
end

function H.SetPosition(key, x, y)
    local vl = VL(key)
    if not vl then return end
    vl.position = { x = floor(x + 0.5), y = floor(y + 0.5) }
    H.ApplyPosition(key)
end

function H.ApplyPosition(key)
    local holder = holders[key]
    if not holder then return end
    local x, y = H.GetPosition(key)
    holder:ClearAllPoints()
    holder:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

function H.ApplyAllPositions()
    for key in pairs(holders) do H.ApplyPosition(key) end
end

function H.ResetPosition(key)
    local vl = VL(key)
    if vl then vl.position = nil end
    local def = defByKey[key]
    if vl and def then vl.position = { x = def.defX, y = def.defY } end
    H.ApplyPosition(key)
end

local function SavePositionFromFrame(key)
    local holder = holders[key]
    if not holder then return end
    local hx, hy = holder:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not hx or not ux then return end
    local vl = VL(key)
    if not vl then return end
    vl.position = { x = floor(hx - ux + 0.5), y = floor(hy - uy + 0.5) }
end

-- =====================================
-- OVERLAY DE PLACEMENT (par holder)
-- =====================================
local function EnsureOverlay(holder)
    if holder._tm_overlay then return holder._tm_overlay end

    local o = CreateFrame("Frame", nil, holder)
    o:SetAllPoints(holder)
    o:SetFrameStrata("HIGH")
    o:SetFrameLevel(holder:GetFrameLevel() + 30)
    o:EnableMouse(true)
    o:RegisterForDrag("LeftButton")
    o:Hide()

    local bg = o:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 0.18)

    o._borders = Create9SliceBorder(o, ACCENT.r, ACCENT.g, ACCENT.b, 0.9, 7)

    local label = o:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 12, "OUTLINE")
    label:SetPoint("CENTER")
    label:SetTextColor(1, 1, 1)
    label:SetText(holder._tm_label or "CDM")
    o._label = label

    local hint = o:CreateFontString(nil, "OVERLAY")
    hint:SetFont(FONT, 9, "OUTLINE")
    hint:SetPoint("TOP", label, "BOTTOM", 0, -2)
    hint:SetTextColor(1, 1, 1, 0.7)
    hint:SetText((TomoMod_L and TomoMod_L["cdm_drag_hint"]) or "Glisser pour déplacer")

    o:SetScript("OnDragStart", function()
        holder:StartMoving()
    end)
    o:SetScript("OnDragStop", function()
        holder:StopMovingOrSizing()
        SavePositionFromFrame(holder._tm_key)
        -- Re-normalise l'ancre sur CENTER/UIParent
        H.ApplyPosition(holder._tm_key)
    end)
    o:SetScript("OnEnter", function() bg:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 0.30) end)
    o:SetScript("OnLeave", function() bg:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 0.18) end)

    holder._tm_overlay = o
    return o
end

-- =====================================
-- PLACEHOLDERS (aperçu live)
-- Frames 100% TomoMod, enfants du holder, toggle par alpha.
-- =====================================
local function EnsurePlaceholderIcon(holder, index)
    holder._tm_ph = holder._tm_ph or {}
    local ph = holder._tm_ph[index]
    if ph then return ph end

    ph = CreateFrame("Frame", nil, holder)
    ph:SetFrameLevel(holder:GetFrameLevel() + 5)

    local bg = ph:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 1)

    local icon = ph:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", -3, 3)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetDesaturated(true)
    icon:SetVertexColor(0.85, 0.85, 0.85)
    ph._icon = icon

    ph._borders = Create9SliceBorder(ph, nil, nil, nil, nil, 7)

    local num = ph:CreateFontString(nil, "OVERLAY")
    num:SetFont(FONT, 10, "OUTLINE")
    num:SetPoint("CENTER")
    num:SetTextColor(1, 1, 1, 0.85)
    ph._num = num

    holder._tm_ph[index] = ph
    return ph
end

local function EnsurePlaceholderBar(holder, index)
    holder._tm_phb = holder._tm_phb or {}
    local ph = holder._tm_phb[index]
    if ph then return ph end

    ph = CreateFrame("Frame", nil, holder)
    ph:SetFrameLevel(holder:GetFrameLevel() + 5)

    local bg = ph:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", -1, 1)
    bg:SetPoint("BOTTOMRIGHT", 1, -1)
    bg:SetColorTexture(0, 0, 0, 1)

    local _, playerClass = UnitClass("player")
    local cc = RAID_CLASS_COLORS[playerClass] or { r = 0.2, g = 0.8, b = 0.5 }

    local fill = ph:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT")
    fill:SetPoint("BOTTOMLEFT")
    fill:SetColorTexture(cc.r, cc.g, cc.b, 0.85)
    ph._fill = fill

    local icon = ph:CreateTexture(nil, "OVERLAY")
    icon:SetPoint("TOPLEFT", ph, "TOPLEFT", 1, -1)
    icon:SetTexture(QUESTION_MARK_ICON)
    icon:SetTexCoord(0.07, 0.93, 0.1, 0.9)
    icon:SetDesaturated(true)
    ph._icon = icon

    local label = ph:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 10, "OUTLINE")
    label:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    label:SetTextColor(1, 1, 1, 0.9)
    ph._label = label

    holder._tm_phb[index] = ph
    return ph
end

local function HideAllPlaceholders(holder)
    holder._tm_phActive = false
    if holder._tm_ph then
        for _, ph in pairs(holder._tm_ph) do ph:SetAlpha(0); ph:Hide() end
    end
    if holder._tm_phb then
        for _, ph in pairs(holder._tm_phb) do ph:SetAlpha(0); ph:Hide() end
    end
end

--- Récupère les textures d'icônes réelles depuis les enfants du viewer
--- (lecture seule — GetTexture sur nos accès visuels, aucun write Blizzard).
local function CollectChildIconTextures(viewer, cap)
    local out = {}
    if not viewer then return out end
    local children = { viewer:GetChildren() }
    for _, child in ipairs(children) do
        local tex
        local iconRegion = child.Icon or child.icon
        if iconRegion and iconRegion.GetTexture then
            tex = iconRegion:GetTexture()
        end
        if tex then
            out[#out + 1] = tex
            if #out >= cap then break end
        end
    end
    return out
end

--- Layout simple d'une grille de placeholders selon les réglages du viewer.
local function LayoutPlaceholderGrid(holder, key, count)
    local vl = VL(key) or {}
    local size    = (vl.iconSize and vl.iconSize > 0) and vl.iconSize or 32
    local spacing = vl.spacing or 2
    local rowLimit = vl.rowLimit or 0
    local perRow  = (rowLimit > 0) and rowLimit or count
    local rows    = ceil(count / perRow)

    local vertical = (vl.direction == "UP" or vl.direction == "DOWN")
    if vertical then
        perRow = (rowLimit > 0) and rowLimit or count
        rows   = ceil(count / perRow)
    end

    local iconH = size * ((key == "buffIcon") and 0.85 or 0.92)

    local totalW, totalH
    if vertical then
        totalW = rows * size + (rows - 1) * spacing
        totalH = min(count, perRow) * iconH + (min(count, perRow) - 1) * spacing
    else
        totalW = min(count, perRow) * size + (min(count, perRow) - 1) * spacing
        totalH = rows * iconH + (rows - 1) * spacing
    end

    for i = 1, count do
        local ph = EnsurePlaceholderIcon(holder, i)
        ph:SetSize(size, iconH)
        ph:ClearAllPoints()

        local col, row
        if vertical then
            row = (i - 1) % perRow
            col = floor((i - 1) / perRow)
            local x = -totalW / 2 + size / 2 + col * (size + spacing)
            local yDir = (vl.direction == "UP") and 1 or -1
            local y0 = (yDir == 1) and (-totalH / 2 + iconH / 2) or (totalH / 2 - iconH / 2)
            ph:SetPoint("CENTER", holder, "CENTER", x, y0 + row * (iconH + spacing) * yDir)
        else
            col = (i - 1) % perRow
            row = floor((i - 1) / perRow)
            local rowCount = min(perRow, count - row * perRow)
            local rowW = rowCount * size + (rowCount - 1) * spacing
            local baseX
            if vl.direction == "LEFT" then
                baseX = -totalW / 2 + size / 2
            elseif vl.direction == "RIGHT" then
                baseX = totalW / 2 - size / 2 - (rowCount - 1) * (size + spacing)
            else
                baseX = -rowW / 2 + size / 2
            end
            local x = baseX + col * (size + spacing)
            local y = (totalH / 2 - iconH / 2) - row * (iconH + spacing)
            ph:SetPoint("CENTER", holder, "CENTER", x, y)
        end
        ph:Show()
        ph:SetAlpha(1)
    end

    holder:SetSize(max(totalW, 20), max(totalH, 20))
    holder._tm_phActive = true
end

local function LayoutPlaceholderBars(holder, key, count)
    local db = GetCDMDB() or {}
    local vl = VL(key) or {}
    local barW   = vl.barWidth or db.buffBarWidth or 120
    local barH   = vl.barHeight or 16
    local gap    = vl.spacing or db.buffBarSpacing or 2
    local horizontal = (vl.direction or db.buffBarDirection) == "HORIZONTAL"

    local totalW, totalH
    if horizontal then
        totalW = count * barW + (count - 1) * gap
        totalH = barH
    else
        totalW = barW
        totalH = count * barH + (count - 1) * gap
    end

    for i = 1, count do
        local ph = EnsurePlaceholderBar(holder, i)
        ph:SetSize(barW, barH)
        ph._icon:SetSize(barH - 2, barH - 2)
        ph._fill:SetWidth(max(4, barW * (1 - (i - 1) * 0.25)))
        ph._label:SetText(((TomoMod_L and TomoMod_L["cdm_preview_aura"]) or "Aura") .. " " .. i)
        ph:ClearAllPoints()
        if horizontal then
            ph:SetPoint("LEFT", holder, "LEFT", (i - 1) * (barW + gap), 0)
        else
            ph:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -(i - 1) * (barH + gap))
        end
        ph:Show()
        ph:SetAlpha(1)
    end

    holder:SetSize(totalW, totalH)
    holder._tm_phActive = true
end

--- (Re)construit les placeholders d'un holder selon l'état courant.
local function BuildPlaceholders(key)
    local holder = holders[key]
    if not holder then return end
    HideAllPlaceholders(holder)
    if not previewActive then return end

    local def = defByKey[key]
    local viewer = def and _G[def.frameName]

    if key == "buffBar" then
        LayoutPlaceholderBars(holder, key, 3)
        return
    end

    -- Essential/Utility : icônes déjà visibles hors combat → placeholders
    -- uniquement si le viewer n'affiche rien (feature off / vide).
    local shownCount = 0
    if viewer then
        local children = { viewer:GetChildren() }
        for _, c in ipairs(children) do
            if c:IsShown() then shownCount = shownCount + 1 end
        end
    end
    if (key == "essential" or key == "utility") and shownCount > 0 then
        return
    end

    local count = (key == "buffIcon") and 5 or 6
    local textures = CollectChildIconTextures(viewer, count)

    LayoutPlaceholderGrid(holder, key, count)
    for i = 1, count do
        local ph = holder._tm_ph[i]
        if ph then
            ph._icon:SetTexture(textures[i] or QUESTION_MARK_ICON)
            ph._num:SetText("")
        end
    end
end

function H.RefreshPreview()
    if not initialized then return end
    for _, def in ipairs(VIEWER_DEFS) do
        BuildPlaceholders(def.key)
    end
end

function H.SetPreview(enabled)
    previewActive = not not enabled
    if previewActive then
        for key, holder in pairs(holders) do
            holder:SetAlpha(1)
        end
    end
    H.RefreshPreview()
    -- Re-synchronise l'alpha des viewers (géré par CooldownManager.UpdateAlpha)
    if TomoMod_CooldownManager and TomoMod_CooldownManager.ApplySettings then
        TomoMod_CooldownManager.ApplySettings()
    end
end

function H.IsPreviewActive()
    return previewActive
end

-- =====================================
-- LOCK / UNLOCK (mode placement live)
-- =====================================
function H.IsLocked()
    return isLocked
end

function H.SetLocked(locked)
    if not initialized then return end
    isLocked = not not locked

    for key, holder in pairs(holders) do
        local o = EnsureOverlay(holder)
        if isLocked then
            o:Hide()
        else
            -- Taille mini pour rester attrapable même vide
            local w, h = holder:GetSize()
            if (w or 0) < 40 or (h or 0) < 24 then
                holder:SetSize(max(w or 0, 120), max(h or 0, 34))
            end
            o:Show()
        end
    end

    -- Le mode placement active l'aperçu automatiquement
    if not isLocked then
        H.SetPreview(true)
    else
        H.SetPreview(false)
        -- Sauvegarde finale de toutes les positions
        for key in pairs(holders) do SavePositionFromFrame(key) end
    end
end

function H.ToggleLock()
    H.SetLocked(not isLocked)
end

-- =====================================
-- ACCÈS POUR CDMLayout / CooldownManager
-- =====================================

--- Holder associé à un viewer Blizzard (nil si non initialisé).
function H.GetContainer(viewer)
    return holderByFrame[viewer]
end

function H.GetHolderByKey(key)
    return holders[key]
end

function H.KeyForViewer(viewer)
    local holder = holderByFrame[viewer]
    return holder and holder._tm_key or nil
end

--- Appelé par CDMLayout après chaque layout : dimensionne le holder
--- sur le contenu réel (sert au drag overlay et au rendu placeholder).
function H.SetContentSize(viewer, w, h)
    local holder = holderByFrame[viewer]
    if not holder then return end
    if previewActive and holder._tm_phActive then
        -- En preview avec placeholders actifs, la taille vient du placeholder grid
        return
    end
    if w and h and w > 0 and h > 0 then
        holder:SetSize(w, h)
    end
end

--- Miroir d'alpha : quand CooldownManager fade les viewers, on fade aussi
--- nos holders (placeholders inclus) — sauf en preview (toujours visibles).
function H.MirrorAlpha(viewer, alpha)
    local holder = holderByFrame[viewer]
    if not holder then return end
    if previewActive then
        holder:SetAlpha(1)
    else
        holder:SetAlpha(alpha or 1)
    end
end

-- =====================================
-- INIT
-- =====================================
local moversRegistered = false
local function RegisterWithMovers()
    if moversRegistered then return end
    if not TomoMod_Movers or not TomoMod_Movers.RegisterEntry then return end
    moversRegistered = true
    local L = TomoMod_L or {}
    TomoMod_Movers.RegisterEntry({
        label    = L["mover_cdm"] or "Cooldown Manager",
        unlock   = function() if H.IsLocked() then H.SetLocked(false) end end,
        lock     = function() if not H.IsLocked() then H.SetLocked(true) end end,
        isActive = function()
            local db = GetCDMDB()
            return db and db.enabled
        end,
    })
end

--- Initialise les holders. Appelé par CooldownManager.InitViewers()
--- une fois les viewers Blizzard disponibles.
function H.Initialize()
    if initialized then
        H.ApplyAllPositions()
        return
    end

    for _, def in ipairs(VIEWER_DEFS) do
        local holder = CreateFrame("Frame", "TomoModCDM_" .. def.key, UIParent)
        holder:SetSize(120, 34)
        holder:SetMovable(true)
        holder:SetClampedToScreen(true)
        holder:SetFrameStrata("MEDIUM")
        holder._tm_key   = def.key
        holder._tm_label = def.label
        holders[def.key] = holder

        local viewer = _G[def.frameName]
        if viewer then
            holderByFrame[viewer] = holder
        end

        H.ApplyPosition(def.key)
    end

    initialized = true
    RegisterWithMovers()
end

--- Ré-associe un viewer apparu tardivement (Blizzard_CooldownManager lazy load).
function H.BindViewer(frameName)
    local viewer = _G[frameName]
    if not viewer then return end
    for _, def in ipairs(VIEWER_DEFS) do
        if def.frameName == frameName and holders[def.key] then
            holderByFrame[viewer] = holders[def.key]
        end
    end
end

-- Export
_G.TomoMod_CDMHolders = H

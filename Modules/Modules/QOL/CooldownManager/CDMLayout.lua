-- =====================================
-- CDMLayout.lua — v3.2.0 (Phase 2 layout engine + Phase 4 holders)
--
-- Moteur de layout TomoMod pour les 4 viewers Blizzard CDM.
--
-- v3.2 — architecture "holders" :
--   * Les icônes Blizzard sont ancrées sur les HOLDERS TomoMod
--     (TomoMod_CDMHolders) au lieu du viewer Blizzard.
--     → position libre, indépendante de l'Edit Mode Blizzard.
--   * On ne redimensionne PLUS le viewer Blizzard (zéro interférence
--     Edit Mode). La taille de contenu est reportée sur le holder.
--   * Réglages par viewer via TomoModDB.cooldownManager.viewerLayout[key]
--     (clés canoniques : "essential", "utility", "buffIcon", "buffBar").
--   * _cdm_stableSlot déplacé dans une weak table (hygiène anti-taint,
--     cohérent Phase 1 : aucun write custom sur frames Blizzard).
--
-- Règles taint conservées :
--   * SetPoint/ClearAllPoints uniquement sur les enfants (jamais SetParent,
--     jamais Show/Hide, jamais de clé custom sur les frames Blizzard).
--   * Skip pendant l'Edit Mode Blizzard actif.
-- =====================================

TomoMod_CDMLayout = TomoMod_CDMLayout or {}
local Layout = TomoMod_CDMLayout

local floor, ceil, max, min, abs = math.floor, math.ceil, math.max, math.min, math.abs

-- =====================================
-- CONSTANTS
-- =====================================
local DEFAULT_SPACING   = 1
local SNAP_TOLERANCE    = 1    -- pixels — skip repositioning if delta < this

-- Clé canonique par nom de frame Blizzard
local KEY_BY_FRAMENAME = {
    EssentialCooldownViewer = "essential",
    UtilityCooldownViewer   = "utility",
    BuffIconCooldownViewer  = "buffIcon",
    BuffBarCooldownViewer   = "buffBar",
}

-- =====================================
-- VIEWER STATE (weak tables — zero taint on secure frames)
-- =====================================
local viewerState = setmetatable({}, { __mode = "k" })

local function VS(viewer)
    local s = viewerState[viewer]
    if not s then
        s = {
            lastDirKey     = nil,   -- for change detection
            lastIconCount  = nil,
            -- Pre-allocated tables per viewer (no shared wipe)
            visibleIcons   = {},
            rowMeta        = {},
        }
        viewerState[viewer] = s
    end
    return s
end

-- v3.2 : slots stables des buff bars — weak table au lieu d'un write
-- direct sur les frames Blizzard (item._cdm_stableSlot supprimé).
local stableSlots = setmetatable({}, { __mode = "k" })

-- Export for other modules
Layout._viewerState = viewerState
Layout.GetViewerState = VS

-- =====================================
-- HOLDERS ACCESS (lazy — module chargé juste avant)
-- =====================================
local function Holders()
    return TomoMod_CDMHolders
end

--- Conteneur d'ancrage : le holder TomoMod si dispo, sinon le viewer
--- (fallback de sécurité si Holders pas encore initialisé).
local function GetContainer(viewer)
    local Hd = Holders()
    local holder = Hd and Hd.GetContainer and Hd.GetContainer(viewer)
    return holder or viewer
end

local function GetViewerKey(viewer)
    local name = viewer.GetName and viewer:GetName()
    return name and KEY_BY_FRAMENAME[name] or nil
end

-- =====================================
-- PIXEL SNAPPING
-- =====================================
local function Snap(value)
    return max(0, floor((value or 0) + 0.5))
end

-- =====================================
-- DIRECTION SYSTEM
-- =====================================
-- Primary direction: how icons flow within a row/column
-- Secondary direction: how rows/columns stack when rowLimit is reached
--
-- Combos:
--   CENTERED + DOWN  → centered row, rows grow downward (default Essential/Utility)
--   CENTERED + UP    → centered row, rows grow upward
--   LEFT + DOWN      → left-aligned row, rows grow downward
--   RIGHT + DOWN     → right-aligned row, rows grow downward
--   UP + RIGHT       → vertical column going up, columns grow right
--   DOWN + LEFT      → vertical column going down, columns grow left
--   CENTERED + nil   → single centered row (no wrapping)

local DIR_HORIZONTAL = {
    CENTERED = true,
    LEFT     = true,
    RIGHT    = true,
}

local DIR_VERTICAL = {
    UP   = true,
    DOWN = true,
}

local SECONDARY_FOR = {
    -- horizontal primary → vertical secondary
    CENTERED = { default = "DOWN", allowed = { UP = true, DOWN = true } },
    LEFT     = { default = "DOWN", allowed = { UP = true, DOWN = true } },
    RIGHT    = { default = "DOWN", allowed = { UP = true, DOWN = true } },
    -- vertical primary → horizontal secondary
    UP       = { default = "RIGHT", allowed = { LEFT = true, RIGHT = true } },
    DOWN     = { default = "RIGHT", allowed = { LEFT = true, RIGHT = true } },
}

--- Resolve primary + secondary direction from settings + viewer defaults.
local function ResolveDirections(settings, viewer)
    local primary, secondary, rowLimit

    if settings then
        primary   = settings.direction
        secondary = settings.secondaryDirection
        rowLimit  = settings.rowLimit or 0
    end

    -- Fall back to Blizzard viewer properties
    if not primary then
        local isHoriz = viewer.isHorizontal
        if isHoriz == nil then isHoriz = true end

        if isHoriz then
            primary = "CENTERED"
        else
            local dir = viewer.iconDirection
            primary = (dir == 1) and "UP" or "DOWN"
        end
    end

    rowLimit = rowLimit or 0
    if rowLimit <= 0 then
        -- Use Blizzard's stride/iconLimit as fallback
        rowLimit = (settings and settings.rowLimit) or viewer.iconLimit or viewer.stride or 0
    end

    -- Validate secondary
    if rowLimit > 0 then
        local sec = SECONDARY_FOR[primary]
        if sec then
            if not secondary or not sec.allowed[secondary] then
                secondary = sec.default
            end
        end
    else
        secondary = nil
    end

    return primary, secondary, rowLimit
end

-- =====================================
-- SETTINGS ACCESSOR
-- =====================================

--- Réglages par viewer. Lit la clé canonique ("essential"...) et,
--- pour compat, l'ancienne clé par nom de frame si elle existait.
--- @return table settings (never nil)
local function GetViewerSettings(viewer)
    local db = TomoModDB and TomoModDB.cooldownManager
    if not db or not db.viewerLayout then return {} end

    local key = GetViewerKey(viewer)
    local byKey = key and db.viewerLayout[key]

    -- Legacy : entrées indexées par nom de frame (anciennes installs)
    local name = viewer.GetName and viewer:GetName()
    local legacy = name and db.viewerLayout[name]

    if byKey and legacy then
        -- byKey prioritaire, legacy comble les trous
        for k, v in pairs(legacy) do
            if byKey[k] == nil then byKey[k] = v end
        end
        return byKey
    end
    return byKey or legacy or {}
end

--- Get icon dimensions, applying per-viewer iconSize override.
local function GetIconDimensions(settings, viewer, children)
    local size = settings.iconSize
    if size and size > 0 then
        return Snap(size), Snap(size)
    end
    -- Use the first visible child's actual size
    if children and #children > 0 then
        local w = children[1]:GetWidth()
        local h = children[1]:GetHeight()
        if w and w > 0 and h and h > 0 then
            return Snap(w), Snap(h)
        end
    end
    return 32, 32
end

--- Get spacing from settings or viewer properties.
local function GetSpacing(settings, viewer)
    if settings.spacing and settings.spacing >= 0 then
        return Snap(settings.spacing)
    end
    return Snap(viewer.childXPadding or DEFAULT_SPACING)
end

-- =====================================
-- COLLECT VISIBLE CHILDREN
-- =====================================

local SortByLayoutIndex = function(a, b)
    return (a.layoutIndex or 0) < (b.layoutIndex or 0)
end

--- Collect visible, sorted children of a viewer into a pre-allocated table.
local function CollectVisible(viewer, vs, filterBuff)
    local icons = vs.visibleIcons
    wipe(icons)
    local children = { viewer:GetChildren() }
    for _, child in ipairs(children) do
        if child:IsShown() then
            if filterBuff then
                -- Buff icons: must have Icon sub-frame and layoutIndex
                if (child.Icon or child.icon) and child.layoutIndex then
                    icons[#icons + 1] = child
                end
            else
                if child.layoutIndex then
                    icons[#icons + 1] = child
                end
            end
        end
    end
    table.sort(icons, SortByLayoutIndex)
    return icons, #icons
end

-- =====================================
-- POSITION APPLY (dirty-check incluant le frame relatif — v3.2)
-- =====================================
local function ApplyPoint(icon, container, x, y)
    local pt, rel, rp, ox, oy = icon:GetPoint()
    if pt == "CENTER" and rp == "CENTER" and rel == container and ox and oy then
        if abs(x - ox) < SNAP_TOLERANCE and abs(y - oy) < SNAP_TOLERANCE then
            return
        end
    end
    icon:ClearAllPoints()
    icon:SetPoint("CENTER", container, "CENTER", x, y)
end

-- =====================================
-- HORIZONTAL LAYOUT (CENTERED / LEFT / RIGHT + secondary UP/DOWN)
-- =====================================
local function LayoutHorizontal(icons, container, primary, secondary, iconW, iconH, spacing, rowLimit)
    local count = #icons
    if count == 0 then return 0, 0 end

    local iconsPerRow = (rowLimit > 0) and max(1, rowLimit) or count
    local numRows = ceil(count / iconsPerRow)
    local rowDir = (secondary == "UP") and 1 or -1

    -- Total height for vertical centering
    local totalHeight = numRows * iconH + (numRows - 1) * spacing

    -- Y anchor: center the block vertically, row 1 at top (DOWN) or bottom (UP)
    local startY
    if rowDir == -1 then
        startY = (totalHeight / 2) - (iconH / 2)
    else
        startY = -(totalHeight / 2) + (iconH / 2)
    end

    local maxRowWidth = 0
    local iconIdx = 1
    local currentY = startY

    for row = 1, numRows do
        local rowCount = min(iconsPerRow, count - iconIdx + 1)
        local rowWidth = rowCount * iconW + (rowCount - 1) * spacing
        maxRowWidth = max(maxRowWidth, rowWidth)

        -- X origin depends on alignment
        local baseX
        if primary == "CENTERED" then
            baseX = -rowWidth / 2 + iconW / 2
        elseif primary == "LEFT" then
            local totalMaxWidth = min(count, iconsPerRow) * iconW + (min(count, iconsPerRow) - 1) * spacing
            baseX = -totalMaxWidth / 2 + iconW / 2
        elseif primary == "RIGHT" then
            local totalMaxWidth = min(count, iconsPerRow) * iconW + (min(count, iconsPerRow) - 1) * spacing
            baseX = totalMaxWidth / 2 - iconW / 2
        else
            baseX = -rowWidth / 2 + iconW / 2
        end

        for i = 0, rowCount - 1 do
            local icon = icons[iconIdx]
            if not icon then break end

            local x
            if primary == "RIGHT" then
                x = baseX - i * (iconW + spacing)
            else
                x = baseX + i * (iconW + spacing)
            end

            ApplyPoint(icon, container, x, currentY)
            iconIdx = iconIdx + 1
        end

        currentY = currentY + (iconH + spacing) * rowDir
    end

    return Snap(maxRowWidth), Snap(totalHeight)
end

-- =====================================
-- VERTICAL LAYOUT (UP / DOWN + secondary LEFT/RIGHT)
-- =====================================
local function LayoutVertical(icons, container, primary, secondary, iconW, iconH, spacing, rowLimit)
    local count = #icons
    if count == 0 then return 0, 0 end

    local iconsPerCol = (rowLimit > 0) and max(1, rowLimit) or count
    local numCols = ceil(count / iconsPerCol)
    local colDir = (secondary == "LEFT") and -1 or 1
    local vertDir = (primary == "UP") and 1 or -1

    local totalWidth = numCols * iconW + (numCols - 1) * spacing
    local totalHeight = min(count, iconsPerCol) * iconH + (min(count, iconsPerCol) - 1) * spacing

    -- X anchor: center block horizontally
    local startX
    if colDir == 1 then
        startX = -(totalWidth / 2) + (iconW / 2)
    else
        startX = (totalWidth / 2) - (iconW / 2)
    end

    -- Y anchor: center block vertically
    local anchorY
    if vertDir == -1 then
        anchorY = (totalHeight / 2) - (iconH / 2)
    else
        anchorY = -(totalHeight / 2) + (iconH / 2)
    end

    local iconIdx = 1
    local currentX = startX

    for col = 1, numCols do
        local colCount = min(iconsPerCol, count - iconIdx + 1)
        local currentY = anchorY

        for i = 0, colCount - 1 do
            local icon = icons[iconIdx]
            if not icon then break end

            local y = currentY + i * (iconH + spacing) * vertDir
            ApplyPoint(icon, container, currentX, y)
            iconIdx = iconIdx + 1
        end

        currentX = currentX + (iconW + spacing) * colDir
    end

    return Snap(totalWidth), Snap(totalHeight)
end

-- =====================================
-- BUFF BAR LAYOUT (stable-slot stack — vertical or horizontal)
-- v3.2 : ancrage sur le holder + slots stables en weak table
--        + overrides par viewer (viewerLayout.buffBar)
-- =====================================
local SortByStableSlot = function(a, b)
    return (stableSlots[a] or 0) < (stableSlots[b] or 0)
end

local function LayoutBuffBar(viewer)
    local vs = VS(viewer)
    local container = GetContainer(viewer)
    local icons = vs.visibleIcons
    wipe(icons)

    local children = { viewer:GetChildren() }
    for _, child in ipairs(children) do
        if child:IsShown() then
            icons[#icons + 1] = child
        end
    end

    if #icons == 0 then
        vs._nextSlot = nil
        for _, child in ipairs(children) do stableSlots[child] = nil end
        return
    end

    -- Assign stable slots for consistent ordering (weak table — no Blizzard write)
    for _, item in ipairs(icons) do
        if not stableSlots[item] then
            vs._nextSlot = (vs._nextSlot or 0) + 1
            stableSlots[item] = vs._nextSlot
        end
    end

    table.sort(icons, SortByStableSlot)

    -- Réglages : par-viewer d'abord, fallback top-level (compat v3.1)
    local db = TomoModDB and TomoModDB.cooldownManager
    local s  = GetViewerSettings(viewer)
    local direction = s.direction or (db and db.buffBarDirection) or "VERTICAL"
    local BAR_GAP   = s.spacing or (db and db.buffBarSpacing) or 2
    local barWidth  = s.barWidth or (db and db.buffBarWidth) or 120

    local contentW, contentH = 0, 0

    if direction == "HORIZONTAL" then
        -- Horizontal: bars side by side, left to right
        local xOff = 0
        local barH = icons[1]:GetHeight() or 14
        for _, item in ipairs(icons) do
            item:ClearAllPoints()
            item:SetWidth(barWidth)
            item:SetPoint("TOPLEFT", container, "TOPLEFT", xOff, 0)
            item:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", xOff, 0)
            xOff = xOff + barWidth + BAR_GAP
        end
        contentW = xOff - BAR_GAP
        contentH = barH
    else
        -- Vertical (default): bars stacked top to bottom
        local yOff = 0
        for _, item in ipairs(icons) do
            local h = item:GetHeight()
            item:ClearAllPoints()
            item:SetWidth(barWidth)
            item:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -yOff)
            yOff = yOff + h + BAR_GAP
        end
        contentW = barWidth
        contentH = yOff - BAR_GAP
    end

    -- Report content size on the holder (never resize the Blizzard viewer)
    local Hd = Holders()
    if Hd and Hd.SetContentSize and contentW > 0 and contentH > 0 then
        Hd.SetContentSize(viewer, contentW, contentH)
    end
end

-- =====================================
-- RUNTIME CHECK (inspired by CooldownManagerCentered)
-- =====================================

local function IsReady(viewer)
    if not viewer then return false end
    if not viewer.IsInitialized or not EditModeManagerFrame then return false end
    if EditModeManagerFrame.layoutApplyInProgress then return false end
    if not viewer:IsInitialized() then return false end
    -- Skip during active Blizzard Edit Mode (on ne se bat pas avec lui)
    if EditModeManagerFrame:IsEditModeActive() then return false end
    return true
end

-- =====================================
-- MAIN ENTRY POINT
-- =====================================

--- Layout a single CDM viewer.
--- @param viewer table — EssentialCooldownViewer, UtilityCooldownViewer, etc.
--- @param isBuff boolean — true for BuffIconCooldownViewer
--- @param force boolean|nil — if true, skip IsReady check (for Layout hook calls)
function Layout.LayoutViewer(viewer, isBuff, force)
    if not force then
        if not IsReady(viewer) then return end
    else
        -- Minimal safety: skip only during active Edit Mode
        if not viewer then return end
        if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then return end
    end

    local vs = VS(viewer)

    -- BuffBar: special stable-slot layout
    if viewer == BuffBarCooldownViewer then
        LayoutBuffBar(viewer)
        return
    end

    local container = GetContainer(viewer)

    -- Collect visible, sorted children
    local icons, count = CollectVisible(viewer, vs, isBuff)
    if count == 0 then return end

    -- Resolve per-viewer settings
    local settings = GetViewerSettings(viewer)

    -- Top-level DB override for buff icon direction (compat v3.1)
    if isBuff then
        local db = TomoModDB and TomoModDB.cooldownManager
        if db and db.buffIconDirection then
            if not settings.direction then
                settings.direction = db.buffIconDirection
            end
            -- Blizzard sets viewer.iconLimit/stride = 1 for buff icons,
            -- which makes LayoutHorizontal create N rows of 1 icon (= vertical).
            -- Force unlimited row so all icons go in a single horizontal line.
            if not settings.rowLimit and DIR_HORIZONTAL[settings.direction] then
                settings.rowLimit = 999
            end
        end
    end

    local primary, secondary, rowLimit = ResolveDirections(settings, viewer)
    local iconW, iconH = GetIconDimensions(settings, viewer, icons)
    local spacing = GetSpacing(settings, viewer)

    -- Change detection bookkeeping (positions re-verified anyway — Blizzard
    -- peut avoir repositionné les icônes via son propre Layout()).
    local dirKey = primary .. "_" .. (secondary or "X") .. "_" .. rowLimit .. "_" .. count
    vs.lastDirKey    = dirKey
    vs.lastIconCount = count

    -- Apply layout (v3.2 : sur le holder, plus sur le viewer)
    local contentW, contentH
    if DIR_HORIZONTAL[primary] then
        contentW, contentH = LayoutHorizontal(icons, container, primary, secondary, iconW, iconH, spacing, rowLimit)
    elseif DIR_VERTICAL[primary] then
        contentW, contentH = LayoutVertical(icons, container, primary, secondary, iconW, iconH, spacing, rowLimit)
    else
        contentW, contentH = LayoutHorizontal(icons, container, "CENTERED", secondary, iconW, iconH, spacing, rowLimit)
    end

    -- Report content size on the holder (never resize the Blizzard viewer)
    local Hd = Holders()
    if Hd and Hd.SetContentSize and contentW and contentH and contentW > 0 and contentH > 0 then
        Hd.SetContentSize(viewer, contentW, contentH)
    end
end

--- Refresh layout on all tracked viewers.
function Layout.RefreshAll(viewers)
    for _, viewer in ipairs(viewers) do
        if viewer then
            local isBuff = (viewer == BuffIconCooldownViewer)
            Layout.LayoutViewer(viewer, isBuff)
        end
    end
end

--- Invalidate cached state for a viewer (force re-layout next time).
function Layout.Invalidate(viewer)
    local vs = viewerState[viewer]
    if vs then
        vs.lastDirKey    = nil
        vs.lastIconCount = nil
    end
end

-- Export
_G.TomoMod_CDMLayout = Layout

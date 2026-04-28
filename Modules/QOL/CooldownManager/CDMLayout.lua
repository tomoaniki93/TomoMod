-- =====================================
-- CDMLayout.lua — Phase 2: Own Layout Engine
-- Replaces inline LayoutEngine + LayoutViewer from CooldownManager.lua
--
-- Features:
--   • Unified direction system: CENTERED, LEFT, RIGHT, UP, DOWN
--   • Secondary direction for row wrapping
--   • Weak tables for viewer state (zero taint on secure frames)
--   • Viewer container resize (Edit Mode compatible)
--   • Per-viewer configurable: direction, spacing, iconSize, rowLimit
--   • Pixel snapping for crisp borders
--   • Dirty-check positioning (skip unchanged)
--   • BuffBar stable-slot vertical stack
--
-- Usage:
--   CDMLayout.LayoutViewer(viewer, isBuff)
--   CDMLayout.RefreshAll(viewers)
-- =====================================

TomoMod_CDMLayout = TomoMod_CDMLayout or {}
local Layout = TomoMod_CDMLayout

local ceil  = math.ceil
local floor = math.floor
local abs   = math.abs
local min   = math.min
local max   = math.max
local wipe  = wipe

-- =====================================
-- CONSTANTS
-- =====================================
local DEFAULT_SPACING   = 1
local DEFAULT_ROW_LIMIT = 0    -- 0 = unlimited (single row)
local SNAP_TOLERANCE    = 1    -- pixels — skip repositioning if delta < this

-- =====================================
-- VIEWER STATE (weak tables — zero taint on secure frames)
-- =====================================
-- Instead of writing viewer._cdm_foo = bar (which taints EditMode frames),
-- all per-viewer state lives in this weak-keyed table.
local viewerState = setmetatable({}, { __mode = "k" })

local function VS(viewer)
    local s = viewerState[viewer]
    if not s then
        s = {
            origWidth      = nil,   -- Blizzard's original width (for Edit Mode restore)
            origHeight     = nil,
            lastDirKey     = nil,   -- for change detection
            lastIconCount  = nil,
            anchorShiftX   = 0,
            anchorShiftY   = 0,
            skipNextAdjust = false,
            -- Pre-allocated tables per viewer (no shared wipe)
            visibleIcons   = {},
            rowMeta        = {},
        }
        viewerState[viewer] = s
    end
    return s
end

-- Export for other modules
Layout._viewerState = viewerState
Layout.GetViewerState = VS

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
--- @param settings table|nil — per-viewer layout settings from DB
--- @param viewer table — Blizzard CooldownViewer frame
--- @return string primary, string|nil secondary, number rowLimit
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

--- Get per-viewer layout settings from DB, with sensible defaults.
--- @param viewerName string
--- @return table settings (never nil)
local function GetViewerSettings(viewerName)
    local db = TomoModDB and TomoModDB.cooldownManager
    if not db or not db.viewerLayout then return {} end
    return db.viewerLayout[viewerName] or {}
end

--- Get icon dimensions, applying per-viewer iconSize override.
--- @param settings table
--- @param viewer table
--- @return number width, number height
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
--- @param settings table
--- @param viewer table
--- @return number
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
--- @param viewer table
--- @param vs table — viewer state (for the pre-allocated table)
--- @param filterBuff boolean — if true, filter to aura-type icons only
--- @return table icons, number count
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
-- HORIZONTAL LAYOUT (CENTERED / LEFT / RIGHT + secondary UP/DOWN)
-- =====================================

--- Position icons in horizontal rows.
--- @param icons table — sorted visible icons
--- @param container table — the viewer frame to anchor to
--- @param primary string — "CENTERED", "LEFT", or "RIGHT"
--- @param secondary string|nil — "UP" or "DOWN"
--- @param iconW number
--- @param iconH number
--- @param spacing number
--- @param rowLimit number — 0 = single row
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
        local rowStart = iconIdx
        local rowCount = min(iconsPerRow, count - iconIdx + 1)
        local rowWidth = rowCount * iconW + (rowCount - 1) * spacing
        maxRowWidth = max(maxRowWidth, rowWidth)

        -- X origin depends on alignment
        local baseX
        if primary == "CENTERED" then
            baseX = -rowWidth / 2 + iconW / 2
        elseif primary == "LEFT" then
            -- Left-aligned from viewer left edge → anchor is CENTER, so shift
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

            -- Apply position (skip if unchanged — dirty check)
            local needSet = true
            local pt, _, rp, ox, oy = icon:GetPoint()
            if pt == "CENTER" and rp == "CENTER" and ox and oy then
                if abs(x - ox) < SNAP_TOLERANCE and abs(currentY - oy) < SNAP_TOLERANCE then
                    needSet = false
                end
            end

            if needSet then
                icon:ClearAllPoints()
                icon:SetPoint("CENTER", container, "CENTER", x, currentY)
            end

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

            local needSet = true
            local pt, _, rp, ox, oy = icon:GetPoint()
            if pt == "CENTER" and rp == "CENTER" and ox and oy then
                if abs(currentX - ox) < SNAP_TOLERANCE and abs(y - oy) < SNAP_TOLERANCE then
                    needSet = false
                end
            end

            if needSet then
                icon:ClearAllPoints()
                icon:SetPoint("CENTER", container, "CENTER", currentX, y)
            end

            iconIdx = iconIdx + 1
        end

        currentX = currentX + (iconW + spacing) * colDir
    end

    return Snap(totalWidth), Snap(totalHeight)
end

-- =====================================
-- BUFF BAR LAYOUT (stable-slot stack — vertical or horizontal)
-- Direction read from TomoModDB.cooldownManager.buffBarDirection
-- =====================================
local SortByStableSlot = function(a, b)
    return (a._cdm_stableSlot or 0) < (b._cdm_stableSlot or 0)
end

local function LayoutBuffBar(viewer)
    local vs = VS(viewer)
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
        for _, child in ipairs(children) do child._cdm_stableSlot = nil end
        return
    end

    -- Assign stable slots for consistent ordering
    for _, item in ipairs(icons) do
        if not item._cdm_stableSlot then
            vs._nextSlot = (vs._nextSlot or 0) + 1
            item._cdm_stableSlot = vs._nextSlot
        end
    end

    table.sort(icons, SortByStableSlot)

    -- Read direction directly from cooldownManager settings (top-level, not viewerLayout)
    local db = TomoModDB and TomoModDB.cooldownManager
    local direction = db and db.buffBarDirection or "VERTICAL"
    local BAR_GAP = (db and db.buffBarSpacing) or 2

    if direction == "HORIZONTAL" then
        -- Horizontal: bars side by side, left to right
        -- Each item needs an explicit width since we only anchor LEFT edges
        local barWidth = (db and db.buffBarWidth) or 120
        local xOff = 0
        for _, item in ipairs(icons) do
            item:ClearAllPoints()
            item:SetWidth(barWidth)
            item:SetPoint("TOPLEFT", viewer, "TOPLEFT", xOff, 0)
            item:SetPoint("BOTTOMLEFT", viewer, "BOTTOMLEFT", xOff, 0)
            xOff = xOff + barWidth + BAR_GAP
        end
    else
        -- Vertical (default): bars stacked top to bottom
        local yOff = 0
        for _, item in ipairs(icons) do
            local h = item:GetHeight()
            item:ClearAllPoints()
            item:SetPoint("TOPLEFT", viewer, "TOPLEFT", 0, -yOff)
            item:SetPoint("TOPRIGHT", viewer, "TOPRIGHT", 0, -yOff)
            yOff = yOff + h + BAR_GAP
        end
    end
end

-- =====================================
-- VIEWER CONTAINER RESIZE + EDIT MODE
-- =====================================

local function SaveOrigSize(viewer, vs)
    if vs.origWidth then return end -- already saved
    local ok, w, h = pcall(viewer.GetSize, viewer)
    if ok and w and h and w > 0 and h > 0 then
        vs.origWidth  = w
        vs.origHeight = h
    end
end

local function ResizeViewer(viewer, vs, contentW, contentH)
    if InCombatLockdown() then return end
    SaveOrigSize(viewer, vs)
    viewer:SetSize(contentW, contentH)
end

-- =====================================
-- EDIT MODE INTEGRATION
-- =====================================
local editModeHooked = false

local function HookEditMode()
    if editModeHooked then return end
    if not EditModeManagerFrame then return end
    editModeHooked = true

    -- Enter Edit Mode: restore Blizzard's original viewer size
    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function()
        if InCombatLockdown() then return end
        for viewer, vs in pairs(viewerState) do
            if viewer and viewer.GetName and vs.origWidth and vs.origHeight then
                pcall(viewer.SetSize, viewer, vs.origWidth, vs.origHeight)
            end
        end
    end)

    -- Exit Edit Mode: re-apply our layout
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
        for viewer, vs in pairs(viewerState) do
            if viewer and viewer.GetName then
                vs.skipNextAdjust = true
                -- Schedule re-layout on next frame
                C_Timer.After(0, function()
                    Layout.LayoutViewer(viewer, (viewer == BuffIconCooldownViewer))
                end)
            end
        end
    end)
end

-- Try to hook immediately, retry if not ready
C_Timer.After(0.5, HookEditMode)
local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
hookFrame:SetScript("OnEvent", function()
    HookEditMode()
end)

-- =====================================
-- RUNTIME CHECK (inspired by CooldownManagerCentered)
-- =====================================

local function IsReady(viewer)
    if not viewer then return false end
    if not viewer.IsInitialized or not EditModeManagerFrame then return false end
    if EditModeManagerFrame.layoutApplyInProgress then return false end
    if not viewer:IsInitialized() then return false end
    -- Skip during active Edit Mode
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

    -- Collect visible, sorted children
    local icons, count = CollectVisible(viewer, vs, isBuff)
    if count == 0 then return end

    -- Resolve per-viewer settings
    local viewerName = viewer:GetName() or ""
    local settings = GetViewerSettings(viewerName)

    -- Top-level DB override for buff icon direction (same pattern as buffBarDirection)
    if isBuff then
        local db = TomoModDB and TomoModDB.cooldownManager
        if db and db.buffIconDirection then
            settings = settings or {}
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

    -- Change detection: skip layout if nothing changed
    local dirKey = primary .. "_" .. (secondary or "X") .. "_" .. rowLimit .. "_" .. count
    if dirKey == vs.lastDirKey and count == vs.lastIconCount then
        -- Count unchanged, direction unchanged — still need to verify positions
        -- (icons may have been repositioned by Blizzard's Layout())
        -- Fall through to re-apply
    end
    vs.lastDirKey    = dirKey
    vs.lastIconCount = count

    -- Apply layout
    local contentW, contentH
    if DIR_HORIZONTAL[primary] then
        contentW, contentH = LayoutHorizontal(icons, viewer, primary, secondary, iconW, iconH, spacing, rowLimit)
    elseif DIR_VERTICAL[primary] then
        contentW, contentH = LayoutVertical(icons, viewer, primary, secondary, iconW, iconH, spacing, rowLimit)
    else
        -- Fallback to centered horizontal
        contentW, contentH = LayoutHorizontal(icons, viewer, "CENTERED", secondary, iconW, iconH, spacing, rowLimit)
    end

    -- Resize viewer container to match content
    if contentW and contentH and contentW > 0 and contentH > 0 then
        ResizeViewer(viewer, vs, contentW, contentH)
    end
end

--- Refresh layout on all tracked viewers.
--- @param viewers table — array of viewer frames
function Layout.RefreshAll(viewers)
    for _, viewer in ipairs(viewers) do
        if viewer then
            local isBuff = (viewer == BuffIconCooldownViewer)
            Layout.LayoutViewer(viewer, isBuff)
        end
    end
end

--- Invalidate cached state for a viewer (force re-layout next time).
--- @param viewer table
function Layout.Invalidate(viewer)
    local vs = viewerState[viewer]
    if vs then
        vs.lastDirKey    = nil
        vs.lastIconCount = nil
    end
end

-- Export
_G.TomoMod_CDMLayout = Layout
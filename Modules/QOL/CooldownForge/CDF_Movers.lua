-- =====================================================================
-- CooldownForge -- Movers (dynamic per-bar placement)
-- AstralForge Cooldown -- Lot 4. Registers a single "Cooldown Bars" entry
-- in the unified Movers manager and makes every bar of the current class
-- draggable via its own overlay while unlocked. Positions are saved to the
-- bar schema. Requires CDF_Core + CDF_Watch + CDF_Render.
--
-- Frames are our own (UIParent children), so drag works in and out of
-- combat with no taint. Position is stored as a CENTER-anchored offset from
-- UIParent (GetCenter delta -- scale-agnostic, matching the CDM holders),
-- never via GetPoint().
-- =====================================================================

local CDF = TomoMod_CooldownForge
local U   = TomoMod_Utils

local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local max, floor = math.max, math.floor

local isLocked = true

-- [S3] Snap step (release rounds the CENTER offset to this, unless Shift
-- is held) and drawn grid step (coarser than the snap for readability).
local SNAP_STEP = 16
local GRID_STEP = 32

-- ---------------------------------------------------------------------
-- [S3] Fullscreen grid overlay (built lazily, rebuilt if the UI resizes)
-- ---------------------------------------------------------------------
local grid

local function buildGrid()
    local uw = floor((UIParent:GetWidth() or 0) + 0.5)
    local uh = floor((UIParent:GetHeight() or 0) + 0.5)
    if uw <= 0 or uh <= 0 then return end
    if grid and grid._w == uw and grid._h == uh then return end

    if not grid then
        grid = CreateFrame("Frame", nil, UIParent)
        grid:SetFrameStrata("BACKGROUND")
        grid:SetAllPoints(UIParent)
        grid:Hide()
        grid._lines = {}
    end
    for _, t in ipairs(grid._lines) do t:Hide() end

    local br = U.BRAND
    local li = 0
    local function line(isV, offset, isAxis)
        li = li + 1
        local t = grid._lines[li]
        if not t then
            t = grid:CreateTexture(nil, "BACKGROUND")
            grid._lines[li] = t
        end
        t:ClearAllPoints()
        if isAxis then
            t:SetColorTexture(br[1], br[2], br[3], 0.55)
        else
            t:SetColorTexture(1, 1, 1, 0.06)
        end
        if isV then
            t:SetPoint("TOP",    grid, "TOPLEFT",    offset, 0)
            t:SetPoint("BOTTOM", grid, "BOTTOMLEFT", offset, 0)
            t:SetWidth(1)
        else
            t:SetPoint("LEFT",  grid, "TOPLEFT",  0, -offset)
            t:SetPoint("RIGHT", grid, "TOPRIGHT", 0, -offset)
            t:SetHeight(1)
        end
        t:Show()
    end

    local cx, cy = uw / 2, uh / 2
    for x = cx % GRID_STEP, uw, GRID_STEP do line(true, x, false) end
    for y = cy % GRID_STEP, uh, GRID_STEP do line(false, y, false) end
    line(true, cx, true)   -- vertical center axis
    line(false, cy, true)  -- horizontal center axis

    grid._w, grid._h = uw, uh
end

local function snapValue(v)
    return floor(v / SNAP_STEP + 0.5) * SNAP_STEP
end

-- ---------------------------------------------------------------------
-- Position save (CENTER offset from UIParent center; never GetPoint)
-- ---------------------------------------------------------------------
local function savePosition(bar, f)
    if not bar or not f then return end
    local hx, hy = f:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not hx or not ux then return end
    bar.position = {
        point = "CENTER", relPoint = "CENTER",
        x = floor(hx - ux + 0.5), y = floor(hy - uy + 0.5),
    }
end

local function place(f, bar)
    local pos = bar.position or {}
    local point = pos.point or "CENTER"
    f:ClearAllPoints()
    f:SetPoint(point, UIParent, pos.relPoint or point, pos.x or 0, pos.y or 0)
end

-- ---------------------------------------------------------------------
-- Placement overlay (one per bar container)
-- ---------------------------------------------------------------------
local function addBorder(o, r, g, b, a)
    local t = 1
    local function edge(p1, p2, w, h)
        local tex = o:CreateTexture(nil, "OVERLAY")
        tex:SetColorTexture(r, g, b, a)
        tex:ClearAllPoints()
        tex:SetPoint(p1); tex:SetPoint(p2)
        if w then tex:SetWidth(w) end
        if h then tex:SetHeight(h) end
        return tex
    end
    edge("TOPLEFT", "TOPRIGHT", nil, t)
    edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, t)
    edge("TOPLEFT", "BOTTOMLEFT", t, nil)
    edge("TOPRIGHT", "BOTTOMRIGHT", t, nil)
end

-- [S3] Generic mover overlay. `onStop(x, y)` receives the SNAPPED (unless
-- Shift) CENTER offset from UIParent center and must persist + re-place
-- the frame. `onReset()` handles right-click (center on screen).
local HINT_TEXT = "Glisser : deplacer  |  Maj : sans grille  |  Clic droit : centrer"

local function centerOffset(f)
    local hx, hy = f:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not hx or not ux then return end
    return floor(hx - ux + 0.5), floor(hy - uy + 0.5)
end

local function ensureOverlay(f, onStop, onReset)
    if f._cdfOverlay then return f._cdfOverlay end
    local br = U.BRAND
    local o = CreateFrame("Frame", nil, f)
    o:SetAllPoints(f)
    o:SetFrameStrata("HIGH")
    o:SetFrameLevel(f:GetFrameLevel() + 30)
    o:EnableMouse(true)
    o:RegisterForDrag("LeftButton")
    o:Hide()

    local bg = o:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(br[1], br[2], br[3], 0.18)
    o._bg = bg
    addBorder(o, br[1], br[2], br[3], 0.9)

    local label = o:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 12, "OUTLINE")
    label:SetPoint("CENTER")
    label:SetTextColor(1, 1, 1)
    o._label = label

    local hint = o:CreateFontString(nil, "OVERLAY")
    hint:SetFont(FONT, 9, "OUTLINE")
    hint:SetPoint("TOP", label, "BOTTOM", 0, -2)
    hint:SetTextColor(1, 1, 1, 0.7)
    hint:SetText(HINT_TEXT)
    o._hint = hint

    o:SetScript("OnDragStart", function()
        f:StartMoving()
        -- [S3] live coordinates while dragging
        o:SetScript("OnUpdate", function()
            local x, y = centerOffset(f)
            if x then hint:SetText(x .. " , " .. y) end
        end)
    end)
    o:SetScript("OnDragStop", function()
        o:SetScript("OnUpdate", nil)
        hint:SetText(HINT_TEXT)
        f:StopMovingOrSizing()
        local x, y = centerOffset(f)
        if not x then return end
        if not IsShiftKeyDown() then
            x, y = snapValue(x), snapValue(y)
        end
        onStop(x, y)
    end)
    o:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" and onReset then onReset() end
    end)
    o:SetScript("OnEnter", function() bg:SetColorTexture(br[1], br[2], br[3], 0.30) end)
    o:SetScript("OnLeave", function() bg:SetColorTexture(br[1], br[2], br[3], 0.18) end)

    f._cdfOverlay = o
    return o
end

-- Bar-flavoured overlay: persists into the bar schema.
local function ensureBarOverlay(f, bar)
    return ensureOverlay(f,
        function(x, y)
            bar.position = { point = "CENTER", relPoint = "CENTER", x = x, y = y }
            place(f, bar)
        end,
        function()
            bar.position = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 }
            place(f, bar)
        end)
end

-- ---------------------------------------------------------------------
-- Lock / unlock (placement mode)
-- ---------------------------------------------------------------------
function CDF.IsLocked()
    return isLocked
end

function CDF.SetLocked(locked)
    isLocked = not not locked
    if not CDF.DB() then return end

    -- Render enabled bars first (positions + icons).
    if CDF.RefreshAll then CDF.RefreshAll() end

    local arr = CDF.GetClassBars()
    if not arr then return end

    if isLocked then
        for i = 1, #arr do
            local bar = arr[i]
            local f = CDF.GetBarFrame(bar)
            savePosition(bar, f)
            if f._cdfOverlay then f._cdfOverlay:Hide() end
            f:SetMovable(false)
        end
        -- [S3] external movables + grid off
        for _, m in ipairs(CDF._movables) do
            if m.frame._cdfOverlay then m.frame._cdfOverlay:Hide() end
            m.frame:SetMovable(false)
        end
        if grid then grid:Hide() end
        -- Restore normal rendering (hides empty/disabled bars).
        if CDF.RefreshAll then CDF.RefreshAll() end
    else
        buildGrid()
        if grid then grid:Show() end
        for i = 1, #arr do
            local bar = arr[i]
            local f = CDF.GetBarFrame(bar)
            place(f, bar)
            local o = ensureBarOverlay(f, bar)
            o._label:SetText(bar.name or "Bar")
            -- Keep empty/disabled bars grabbable with a minimum footprint.
            local w, h = f:GetSize()
            if (w or 0) < 40 or (h or 0) < 24 then
                f:SetSize(max(w or 0, 120), max(h or 0, 34))
            end
            f:SetMovable(true)
            f:SetClampedToScreen(true)
            f:Show()
            o:Show()
        end
        -- [S3] external movables join the same session
        for _, m in ipairs(CDF._movables) do
            local mf2 = m.frame
            local o = ensureOverlay(mf2, m.onStop, m.onReset)
            o._label:SetText(m.label or "Element")
            local w, h = mf2:GetSize()
            if (w or 0) < (m.minW or 40) or (h or 0) < (m.minH or 24) then
                mf2:SetSize(max(w or 0, m.minW or 120), max(h or 0, m.minH or 34))
            end
            mf2:SetMovable(true)
            mf2:SetClampedToScreen(true)
            mf2:Show()
            o:Show()
        end
    end
end

function CDF.ToggleLock()
    CDF.SetLocked(not isLocked)
end

-- ---------------------------------------------------------------------
-- [S3] External registration API. Lets other TomoMod elements (resource
-- bars, future custom widgets) join the CDF edit-mode session.
--   frame : a movable-capable frame parented under UIParent (our frames
--           only -- never a protected Blizzard frame).
--   opts  : {
--     label   = string shown on the overlay,
--     onStop  = function(x, y)  -- snapped CENTER offset from UIParent
--                               -- center; persist it AND re-place the
--                               -- frame yourself,
--     onReset = function() end, -- optional; right-click (center on screen)
--     minW, minH = numbers,     -- optional grab footprint minimums
--   }
-- Registering while unlocked activates the overlay immediately.
-- ---------------------------------------------------------------------
CDF._movables = {}

function CDF.RegisterMovable(frame, opts)
    if not frame or type(opts) ~= "table" or type(opts.onStop) ~= "function" then
        return false
    end
    for _, m in ipairs(CDF._movables) do
        if m.frame == frame then return false end
    end
    local m = {
        frame   = frame,
        label   = opts.label,
        onStop  = opts.onStop,
        onReset = opts.onReset,
        minW    = opts.minW,
        minH    = opts.minH,
    }
    CDF._movables[#CDF._movables + 1] = m
    if not isLocked then
        local o = ensureOverlay(frame, m.onStop, m.onReset)
        o._label:SetText(m.label or "Element")
        frame:SetMovable(true)
        frame:SetClampedToScreen(true)
        frame:Show()
        o:Show()
    end
    return true
end

-- ---------------------------------------------------------------------
-- Register with the unified Movers manager (deferred to login so
-- TomoMod_Movers exists regardless of file load order).
-- ---------------------------------------------------------------------
local function registerMover()
    if CDF._moverRegistered then return end
    if not (TomoMod_Movers and TomoMod_Movers.RegisterEntry) then return end
    TomoMod_Movers.RegisterEntry({
        label    = "Cooldown Bars",
        unlock   = function() if CDF.IsLocked() then CDF.ToggleLock() end end,
        lock     = function() if not CDF.IsLocked() then CDF.ToggleLock() end end,
        isActive = function() local db = CDF.DB(); return db and db.enabled end,
    })
    CDF._moverRegistered = true
end

local mf = CreateFrame("Frame")
mf:RegisterEvent("PLAYER_LOGIN")
mf:SetScript("OnEvent", registerMover)
CDF._moverFrame = mf

-- =====================================================================
-- TomoMod Forge -- Edit (L1)
-- The addon-wide edit session, promoted from the CooldownForge movers so
-- every deep element (cooldown bars, resource bars, future AstralForge
-- frames) shares ONE unlock: same grid, same snap, same overlays.
--
-- Providers  : modules with DYNAMIC element sets (e.g. class bars)
--              register a function(locked) fired on every transition.
-- Movables   : standalone frames register once with callbacks.
-- Frames are always our own UIParent children -- never a protected
-- Blizzard frame. Positions travel as CENTER offsets from UIParent
-- center (GetCenter delta, scale-agnostic, never GetPoint()).
-- =====================================================================

local Forge = TomoMod_Forge
if not Forge then return end

local E = Forge.Edit or {}
Forge.Edit = E

local FONT = Forge.FONT
local max, floor = math.max, math.floor

local isLocked = true
local providers = {}
local movables  = {}

-- Snap step (release rounds the CENTER offset to this, unless Shift is
-- held) and drawn grid step (coarser than the snap for readability).
local SNAP_STEP = 16
local GRID_STEP = 32

local HINT_TEXT = "Glisser : deplacer  |  Maj : sans grille  |  Clic droit : centrer"

-- ---------------------------------------------------------------------
-- Grid overlay (built lazily, rebuilt if the UI resizes)
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

    local br = Forge.BRAND
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
    line(true, cx, true)
    line(false, cy, true)

    grid._w, grid._h = uw, uh
end

-- ---------------------------------------------------------------------
-- Geometry helpers
-- ---------------------------------------------------------------------
function E.Snap(v)
    return floor(v / SNAP_STEP + 0.5) * SNAP_STEP
end

function E.CenterOffset(f)
    local hx, hy = f:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not hx or not ux then return end
    return floor(hx - ux + 0.5), floor(hy - uy + 0.5)
end

-- ---------------------------------------------------------------------
-- Overlay (shared visual + behavior for every movable element)
-- ---------------------------------------------------------------------
local function addBorder(f, r, g, b, a)
    local function edge(...)
        local t = f:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(r, g, b, a or 1)
        return t
    end
    local top = edge()
    top:SetPoint("TOPLEFT", 0, 0);      top:SetPoint("TOPRIGHT", 0, 0);      top:SetHeight(1)
    local bot = edge()
    bot:SetPoint("BOTTOMLEFT", 0, 0);   bot:SetPoint("BOTTOMRIGHT", 0, 0);   bot:SetHeight(1)
    local lef = edge()
    lef:SetPoint("TOPLEFT", 0, 0);      lef:SetPoint("BOTTOMLEFT", 0, 0);    lef:SetWidth(1)
    local rig = edge()
    rig:SetPoint("TOPRIGHT", 0, 0);     rig:SetPoint("BOTTOMRIGHT", 0, 0);   rig:SetWidth(1)
end

-- onStop(x, y) : SNAPPED (unless Shift) CENTER offset from UIParent
--                center; persist it AND re-place the frame yourself.
-- onReset()    : optional; right-click (center on screen).
function E.AttachOverlay(f, onStop, onReset)
    if f._forgeOverlay then return f._forgeOverlay end
    local br = Forge.BRAND
    local o = CreateFrame("Frame", nil, f)
    o:SetAllPoints(f)
    o:SetFrameStrata("HIGH")
    -- CooldownForge owns this overlay instead of U.StyleMoverOverlay(), so it
    -- must opt into TomoLayout's temporary EditMode layer explicitly. The
    -- shared layer manager lowers both the overlay and its bar owner only
    -- while Layout Mode is active, then restores their original strata.
    if TomoMod_Utils and TomoMod_Utils.RegisterMoverLayer then
        TomoMod_Utils.RegisterMoverLayer(o, f)
    end
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
        o:SetScript("OnUpdate", function()
            local x, y = E.CenterOffset(f)
            if x then hint:SetText(x .. " , " .. y) end
        end)
    end)
    o:SetScript("OnDragStop", function()
        o:SetScript("OnUpdate", nil)
        hint:SetText(HINT_TEXT)
        f:StopMovingOrSizing()
        local x, y = E.CenterOffset(f)
        if not x then return end
        if not IsShiftKeyDown() then
            x, y = E.Snap(x), E.Snap(y)
        end
        onStop(x, y)
    end)
    o:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" and onReset then onReset() end
    end)
    o:SetScript("OnEnter", function() bg:SetColorTexture(br[1], br[2], br[3], 0.30) end)
    o:SetScript("OnLeave", function() bg:SetColorTexture(br[1], br[2], br[3], 0.18) end)

    f._forgeOverlay = o
    return o
end

-- ---------------------------------------------------------------------
-- Registration
-- ---------------------------------------------------------------------
-- Providers own DYNAMIC element sets; fn(locked) fires on every
-- transition (and immediately if registered while unlocked).
function E.RegisterProvider(fn)
    if type(fn) ~= "function" then return false end
    providers[#providers + 1] = fn
    if not isLocked then fn(false) end
    return true
end

-- Standalone frames; opts = { label, onStop(x, y), onReset, minW, minH }.
function E.RegisterMovable(frame, opts)
    if not frame or type(opts) ~= "table" or type(opts.onStop) ~= "function" then
        return false
    end
    for _, m in ipairs(movables) do
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
    movables[#movables + 1] = m
    if not isLocked then
        local o = E.AttachOverlay(frame, m.onStop, m.onReset)
        o._label:SetText(m.label or "Element")
        frame:SetMovable(true)
        frame:SetClampedToScreen(true)
        frame:Show()
        o:Show()
    end
    return true
end

-- ---------------------------------------------------------------------
-- Session
-- ---------------------------------------------------------------------
function E.IsLocked()
    return isLocked
end

function E.SetLocked(locked)
    locked = not not locked
    if isLocked == locked then return end
    isLocked = locked

    if locked then
        for _, m in ipairs(movables) do
            if m.frame._forgeOverlay then m.frame._forgeOverlay:Hide() end
            m.frame:SetMovable(false)
        end
        if grid then grid:Hide() end
    else
        buildGrid()
        if grid then grid:Show() end
        for _, m in ipairs(movables) do
            local mf = m.frame
            local o = E.AttachOverlay(mf, m.onStop, m.onReset)
            o._label:SetText(m.label or "Element")
            local w, h = mf:GetSize()
            if (w or 0) < (m.minW or 40) or (h or 0) < (m.minH or 24) then
                mf:SetSize(max(w or 0, m.minW or 120), max(h or 0, m.minH or 34))
            end
            mf:SetMovable(true)
            mf:SetClampedToScreen(true)
            mf:Show()
            o:Show()
        end
    end

    for _, fn in ipairs(providers) do
        local ok, err = pcall(fn, locked)
        if not ok then
            print("|cff2e9dd8TomoMod|r Forge.Edit: provider error -- " .. tostring(err))
        end
    end
end

function E.Toggle()
    E.SetLocked(not isLocked)
end

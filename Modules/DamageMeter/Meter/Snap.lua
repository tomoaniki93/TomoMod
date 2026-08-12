local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- Snap: edge-to-edge window docking.
--
-- WHY THERE IS NO SIZE-SYNC CODE HERE.
--
-- A docked window is anchored by TWO points on the shared edge rather than
-- one. Docking B under A anchors B's TOPLEFT to A's BOTTOMLEFT *and* B's
-- TOPRIGHT to A's BOTTOMRIGHT, so B's width is A's width by construction —
-- permanently, including when A is resized. Docking side by side anchors both
-- top and bottom corners instead, and the height follows the same way.
--
-- The same property gives group movement for free: dragging A moves B, because
-- B is anchored to A and the engine resolves it.
--
-- Behaviour, as chosen:
--   * dragging a docked window detaches it (pull away = unhook)
--   * dragging the head moves the whole chain
--   * a docked window hides its resize grip: the constrained axis now belongs
--     to the window it is docked to
----------------------------------------------------------------------

local SNAP_DISTANCE = 12   -- px between edges to trigger a dock
local MIN_OVERLAP   = 40   -- px of overlap needed on the perpendicular axis

-- Anchor pairs per edge. `edge` names where the window sits relative to its
-- target: "BOTTOM" means the window sits below the target.
-- Each entry: { ownPoint, targetPoint, xOff, yOff }
local EDGES = {
    BOTTOM = {
        { "TOPLEFT",     "BOTTOMLEFT",  0, 0 },
        { "TOPRIGHT",    "BOTTOMRIGHT", 0, 0 },
    },
    TOP = {
        { "BOTTOMLEFT",  "TOPLEFT",     0, 0 },
        { "BOTTOMRIGHT", "TOPRIGHT",    0, 0 },
    },
    RIGHT = {
        { "TOPLEFT",     "TOPRIGHT",    0, 0 },
        { "BOTTOMLEFT",  "BOTTOMRIGHT", 0, 0 },
    },
    LEFT = {
        { "TOPRIGHT",    "TOPLEFT",     0, 0 },
        { "BOTTOMRIGHT", "BOTTOMLEFT",  0, 0 },
    },
}

----------------------------------------------------------------------
-- Lookup helpers
----------------------------------------------------------------------

local function WindowById(id)
    if not id or not ns.windows then return nil end
    for _, win in ipairs(ns.windows) do
        if win.cfg and win.cfg.id == id then return win end
    end
    return nil
end

local function WindowByFrame(frame)
    if not frame or not ns.windows then return nil end
    for _, win in ipairs(ns.windows) do
        if win.frame == frame then return win end
    end
    return nil
end

-- True when `candidate` appears anywhere up `win`'s dock chain. Used to refuse
-- a dock that would close a loop: circular anchors raise a WoW error.
-- The `seen` set also guards against a corrupt saved chain looping forever.
local function IsAncestor(candidate, win)
    local seen, cur = {}, win
    while cur and cur.cfg and cur.cfg.snap do
        local parent = WindowById(cur.cfg.snap.to)
        if not parent or seen[parent] then return false end
        if parent == candidate then return true end
        seen[parent] = true
        cur = parent
    end
    return false
end

local function Rect(frame)
    local l, r, t, b = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
    if not (l and r and t and b) then return nil end
    return { left = l, right = r, top = t, bottom = b }
end

----------------------------------------------------------------------
-- Visual state
----------------------------------------------------------------------

function ns.UpdateSnapVisuals(win)
    if not win or not win.SetResizeHandleShown then return end
    win.SetResizeHandleShown(not (win.cfg and win.cfg.snap))
end

-- Refresh a window and everything docked below it. Called after a resize, so
-- the followers re-lay their columns against their new width.
function ns.SnapRefreshChain(frame)
    local head = WindowByFrame(frame)
    if not head then return end
    if head.RefreshFonts then head.RefreshFonts() end
    head.Refresh()
    for _, win in ipairs(ns.windows) do
        if win ~= head and win.cfg and win.cfg.snap and IsAncestor(head, win) then
            if win.RefreshFonts then win.RefreshFonts() end
            win.Refresh()
        end
    end
end

----------------------------------------------------------------------
-- Attach / detach
----------------------------------------------------------------------

local function Attach(win, target, edge)
    local spec = EDGES[edge]
    if not spec then return false end

    local f, t = win.frame, target.frame
    -- Freeze the current size first: the two anchors take over one axis, and
    -- the other must keep a definite value of its own.
    local w, h = f:GetWidth(), f:GetHeight()
    f:ClearAllPoints()
    f:SetSize(w, h)
    for _, pt in ipairs(spec) do
        f:SetPoint(pt[1], t, pt[2], pt[3], pt[4])
    end

    win.cfg.snap = { to = target.cfg.id, edge = edge }
    ns.UpdateSnapVisuals(win)
    return true
end

local function Detach(win)
    local cfg = win.cfg
    if not cfg or not cfg.snap then return false end

    local f = win.frame
    -- Capture the geometry the window had while docked, before dropping the
    -- anchors that were defining it.
    local left, top = f:GetLeft(), f:GetTop()
    local w, h = f:GetWidth(), f:GetHeight()

    cfg.snap = nil
    f:ClearAllPoints()
    f:SetSize(w, h)
    if left and top then
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        cfg.point, cfg.relPoint, cfg.x, cfg.y = "TOPLEFT", "BOTTOMLEFT", left, top
    end
    cfg.width, cfg.height = w, h

    ns.UpdateSnapVisuals(win)
    return true
end

----------------------------------------------------------------------
-- Public entry points, called from the window's drag scripts
----------------------------------------------------------------------

--- Detach the window owning `frame`, if it is docked. A head window has no
--- dock of its own, so this is a no-op for it and its followers stay anchored
--- — which is exactly what makes dragging the head move the chain.
function ns.SnapDetachFrame(frame)
    local win = WindowByFrame(frame)
    if not win then return false end
    return Detach(win)
end

--- Try to dock the window owning `frame` against any other window.
function ns.SnapTryFrame(frame)
    if ns.db and ns.db.snapEnabled == false then return false end

    local win = WindowByFrame(frame)
    if not win or not win.cfg then return false end

    local a = Rect(win.frame)
    if not a then return false end

    local best, bestDist, bestEdge
    for _, other in ipairs(ns.windows) do
        -- Refusing when `win` is already an ancestor of `other` is what keeps
        -- the anchor graph acyclic.
        if other ~= win and other.frame:IsShown() and other.cfg
           and not IsAncestor(win, other) then
            local b = Rect(other.frame)
            if b then
                local hOverlap = math.min(a.right, b.right) - math.max(a.left, b.left)
                local vOverlap = math.min(a.top, b.top) - math.max(a.bottom, b.bottom)

                local function Consider(dist, edge)
                    if dist <= SNAP_DISTANCE and (not bestDist or dist < bestDist) then
                        best, bestDist, bestEdge = other, dist, edge
                    end
                end

                if hOverlap >= MIN_OVERLAP then
                    Consider(math.abs(a.top - b.bottom), "BOTTOM")
                    Consider(math.abs(a.bottom - b.top), "TOP")
                end
                if vOverlap >= MIN_OVERLAP then
                    Consider(math.abs(a.left - b.right), "RIGHT")
                    Consider(math.abs(a.right - b.left), "LEFT")
                end
            end
        end
    end

    if best then
        return Attach(win, best, bestEdge)
    end
    return false
end

--- Detach every window docked to `win`. Called before a window is removed:
--- otherwise its followers would be anchored to a hidden frame.
function ns.SnapDetachChildrenOf(win)
    if not win or not win.cfg or not ns.windows then return end
    for _, other in ipairs(ns.windows) do
        if other ~= win and other.cfg and other.cfg.snap
           and other.cfg.snap.to == win.cfg.id then
            Detach(other)
        end
    end
end

--- Re-apply saved docks. Must run after every window exists: a window cannot
--- anchor to one that has not been created yet, which is why this is a second
--- pass rather than part of window construction.
function ns.RestoreSnaps()
    if not ns.windows then return end
    for _, win in ipairs(ns.windows) do
        local snap = win.cfg and win.cfg.snap
        if snap then
            local target = WindowById(snap.to)
            if target and target ~= win and EDGES[snap.edge]
               and not IsAncestor(win, target) then
                Attach(win, target, snap.edge)
            else
                -- Stale or looping saved state: drop it and leave the window
                -- wherever its absolute position put it.
                win.cfg.snap = nil
            end
        end
        ns.UpdateSnapVisuals(win)
    end
end

-- =====================================================================
-- TomoMod Forge -- Canvas (L2)
-- The WYSIWYG editing surface of AstralForge. Given a SUBJECT (a frame
-- built by a module's own factories) and its element store, it lays a
-- draggable handle over every registered element and turns a drop into a
-- sanitised anchor record.
--
-- Two rules govern this file.
--
--   1. The subject is ALWAYS a detached preview clone, never a live unit
--      frame. Live frames are protected in Midnight (SetPoint / Show /
--      UnitWatch are blocked in combat) and dragging one would taint the
--      whole frame. The canvas has no idea what a unit is -- it only ever
--      sees widgets handed to it -- which is what keeps that guarantee
--      cheap to hold.
--
--   2. Positions are NEVER read back with GetPoint(). A drop is measured
--      as the delta between the element's anchor point and the host's
--      anchor point, both converted to screen pixels through their own
--      effective scale, then divided back by the element's scale. That
--      survives SetScale on any ancestor -- the failure mode that bit the
--      minimap mover.
--
-- Geometry helpers are pure and duck-typed (anything exposing GetLeft /
-- GetRight / GetTop / GetBottom works), so the static bench can exercise
-- them without a game client.
-- =====================================================================

local Forge = TomoMod_Forge
if not Forge or not Forge.Registry then return end

Forge.Canvas = Forge.Canvas or {}
local C = Forge.Canvas
local R = Forge.Registry

local floor, abs, max = math.floor, math.abs, math.max
local tonumber, type, ipairs, pairs = tonumber, type, ipairs, pairs

local WHITE8 = "Interface\\Buttons\\WHITE8x8"

-- ---------------------------------------------------------------------
-- Secret values
--
-- In Midnight a widget's rect becomes SECRET as soon as its content was
-- derived from protected data -- a font string fed by UnitHealth is the
-- textbook case. GetLeft() then returns a secret number, and the very next
-- `r - l` raises "attempt to perform arithmetic on a secret number value".
--
-- The cardinal rule is that issecretvalue() must come BEFORE any
-- arithmetic OR comparison, so every coordinate entering this file passes
-- through Plain() first. A secret coordinate degrades to nil, which the
-- callers already treat as "not measurable yet": the handle hides and the
-- rest of the canvas keeps working, instead of one element taking down the
-- whole Rebuild.
--
-- The studio also avoids producing secret rects in the first place (its
-- preview runs on simulated data), so this is the second line of defence,
-- not the first.
-- ---------------------------------------------------------------------

local issecretvalue = issecretvalue

local function IsSecret(v)
    if not issecretvalue then return false end
    return issecretvalue(v) and true or false
end

-- Returns v when it is a usable plain number, nil otherwise. Never compares
-- or operates on v before the secret check.
local function Plain(v)
    if v == nil then return nil end
    if IsSecret(v) then return nil end
    if type(v) ~= "number" then return nil end
    return v
end

C.IsSecret = IsSecret
C.Plain    = Plain

C.SNAP_STEP  = 2    -- pixels; hold Shift while dropping for free placement
C.GUIDE_TOL  = 4    -- magnetic alignment threshold, screen pixels
C.MIN_HIT    = 14   -- minimum grabbable size, via hit rect (never geometry)

-- ---------------------------------------------------------------------
-- Geometry (pure)
-- ---------------------------------------------------------------------

-- Which edges each anchor point reads. L/C/R horizontally, T/M/B vertically.
local EDGE = {
    TOPLEFT     = { "L", "T" }, TOP    = { "C", "T" }, TOPRIGHT    = { "R", "T" },
    LEFT        = { "L", "M" }, CENTER = { "C", "M" }, RIGHT       = { "R", "M" },
    BOTTOMLEFT  = { "L", "B" }, BOTTOM = { "C", "B" }, BOTTOMRIGHT = { "R", "B" },
}

-- FontStrings and Textures are regions: they have no GetEffectiveScale.
-- Their coordinates live in their parent's space, so that is the scale to
-- use. Frames answer for themselves.
function C.EffectiveScale(o)
    if not o then return 1 end
    if o.GetEffectiveScale then
        local s = Plain(o:GetEffectiveScale())
        if s and s > 0 then return s end
    end
    local p = o.GetParent and o:GetParent()
    if p and p.GetEffectiveScale then
        local s = Plain(p:GetEffectiveScale())
        if s and s > 0 then return s end
    end
    return 1
end

-- Screen-pixel coordinates of `point` on `o`. Returns nil while the widget
-- has no resolved rect (not laid out yet, or hidden with no anchor).
function C.PointCoord(o, point)
    if not o then return nil end
    -- Plain() runs before anything touches these: a secret rect must not
    -- reach the arithmetic below.
    local l, r = Plain(o:GetLeft()), Plain(o:GetRight())
    local b, t = Plain(o:GetBottom()), Plain(o:GetTop())
    if not (l and r and b and t) then return nil end
    local s = C.EffectiveScale(o)
    local e = EDGE[point] or EDGE.CENTER
    local x = (e[1] == "L" and l) or (e[1] == "R" and r) or ((l + r) * 0.5)
    local y = (e[2] == "T" and t) or (e[2] == "B" and b) or ((b + t) * 0.5)
    return x * s, y * s
end

-- The (x, y) that SetPoint(point, host, relPoint, x, y) would need for the
-- element to stay exactly where it currently sits.
function C.ComputeOffset(element, host, point, relPoint)
    local ex, ey = C.PointCoord(element, point)
    local hx, hy = C.PointCoord(host, relPoint)
    if not ex or not hx then return nil end
    local s = C.EffectiveScale(element)
    return (ex - hx) / s, (ey - hy) / s
end

function C.Snap(v, step)
    step = step or C.SNAP_STEP
    if step <= 0 then return v end
    return floor(v / step + 0.5) * step
end

-- Magnetic alignment: when the element's own centre lands within GUIDE_TOL
-- screen pixels of the host's centre, the offset is nudged onto it exactly
-- and the caller is told to light the guide.
-- Returns x, y, snappedX, snappedY.
function C.ApplyGuides(element, host, point, relPoint, x, y, tol)
    tol = tol or C.GUIDE_TOL
    local ecx, ecy = C.PointCoord(element, "CENTER")
    local hcx, hcy = C.PointCoord(host, "CENTER")
    if not ecx or not hcx then return x, y, false, false end
    local s = C.EffectiveScale(element)
    if s <= 0 then s = 1 end

    local gx, gy = false, false
    local dx, dy = hcx - ecx, hcy - ecy
    if abs(dx) <= tol then x, gx = x + dx / s, true end
    if abs(dy) <= tol then y, gy = y + dy / s, true end
    return x, y, gx, gy
end

-- ---------------------------------------------------------------------
-- Canvas object
-- ---------------------------------------------------------------------

local CanvasMT = {}
CanvasMT.__index = CanvasMT

-- opts:
--   domain    : registry domain name
--   accent    : {r,g,b}
--   snap      : snap step (default C.SNAP_STEP)
--   onSelect  : function(id) -- selection changed (id may be nil)
--   onChange  : function(id) -- a drop wrote a new record
function C.Create(parent, opts)
    opts = opts or {}
    local accent = opts.accent or Forge.BRAND

    local self = setmetatable({
        domain   = opts.domain,
        accent   = accent,
        snap     = tonumber(opts.snap) or C.SNAP_STEP,
        onSelect = opts.onSelect,
        onChange = opts.onChange,
        handles  = {},
        selected = nil,
    }, CanvasMT)

    -- Stage: where the subject lives. Sized by the consumer.
    local stage = CreateFrame("Frame", nil, parent)
    self.stage = stage

    -- Overlay: handles and guides, always above the subject's own widgets.
    local overlay = CreateFrame("Frame", nil, stage)
    overlay:SetAllPoints(stage)
    overlay:SetFrameLevel(stage:GetFrameLevel() + 40)
    self.overlay = overlay

    local function guide(vertical)
        local t = overlay:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(accent[1], accent[2], accent[3], 0.75)
        if vertical then t:SetWidth(1) else t:SetHeight(1) end
        t:Hide()
        return t
    end
    self.guideV, self.guideH = guide(true), guide(false)

    return self
end

-- Attach the frame being edited and the store its elements read from.
-- `domain` is optional: pass it when the same canvas is reused across
-- domains (the studio switches between unit frames and nameplates), so the
-- handles are rebuilt against the right registry.
function CanvasMT:SetSubject(frame, store, domain)
    if domain and domain ~= self.domain then
        -- Handles are per-element and the element sets differ: drop them
        -- rather than leave stale ones pointing at a widget that no longer
        -- exists on the new subject.
        for _, h in pairs(self.handles) do
            h:Hide()
            h:SetScript("OnUpdate", nil)
        end
        self.handles  = {}
        self.selected = nil
        self.domain   = domain
    end
    self.subject = frame
    self.store   = store
    self:Rebuild()
end

function CanvasMT:GetSelection()
    return self.selected
end

-- ---------------------------------------------------------------------
-- Handles
-- ---------------------------------------------------------------------

local function styleHandle(h, accent, selected)
    local a = selected and 0.30 or 0.0
    h._bg:SetColorTexture(accent[1], accent[2], accent[3], a)
    local ea = selected and 0.95 or 0.45
    for _, e in ipairs(h._edges) do
        e:SetColorTexture(accent[1], accent[2], accent[3], ea)
    end
end

function CanvasMT:_CreateHandle(id)
    local accent = self.accent
    local h = CreateFrame("Frame", nil, self.overlay)
    h:SetFrameLevel(self.overlay:GetFrameLevel() + 5)
    h:EnableMouse(true)
    h:RegisterForDrag("LeftButton")
    h:SetMovable(true)

    local bg = h:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    h._bg = bg

    h._edges = {}
    local function edge(p1, p2, w, ht)
        local t = h:CreateTexture(nil, "OVERLAY")
        t:SetPoint(p1); t:SetPoint(p2)
        if w then t:SetWidth(w) end
        if ht then t:SetHeight(ht) end
        h._edges[#h._edges + 1] = t
        return t
    end
    edge("TOPLEFT", "TOPRIGHT", nil, 1)
    edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    edge("TOPLEFT", "BOTTOMLEFT", 1, nil)
    edge("TOPRIGHT", "BOTTOMRIGHT", 1, nil)

    h._id = id
    h:SetScript("OnMouseDown", function() self:Select(id) end)
    h:SetScript("OnEnter", function() if self.selected ~= id then styleHandle(h, accent, true) end end)
    h:SetScript("OnLeave", function() styleHandle(h, accent, self.selected == id) end)

    h:SetScript("OnDragStart", function(hh)
        self:Select(id)
        hh:StartMoving()
        hh:SetScript("OnUpdate", function() self:_DragUpdate(id) end)
    end)
    h:SetScript("OnDragStop", function(hh)
        hh:SetScript("OnUpdate", nil)
        hh:StopMovingOrSizing()
        self:_DragStop(id)
    end)

    styleHandle(h, accent, false)
    return h
end

-- The handle sits exactly on the element's rect; a negative hit rect gives
-- small elements a grabbable area WITHOUT distorting the geometry the drop
-- is measured from.
--
-- Both the size and the anchor offsets are converted through screen pixels:
-- SetPoint and SetSize read in the HANDLE's coordinate space, while the
-- element's rect is expressed in its own. Those two scales are equal today
-- (nothing between them calls SetScale) but assuming it is exactly the
-- double-scaling bug that bit the minimap mover, so the conversion is done
-- explicitly rather than left implicit.
function CanvasMT:_SyncHandle(id)
    local h = self.handles[id]
    local desc = R.Get(self.domain, id)
    if not h or not desc then return end
    local ok, el = pcall(desc.resolve, self.subject)
    if not ok or not el then h:Hide(); return end

    -- Idem : un rect secret rend nil, et la poignee se masque au lieu de
    -- faire lever toute la reconstruction.
    local l, r = C.Plain(el:GetLeft()), C.Plain(el:GetRight())
    local b, t = C.Plain(el:GetBottom()), C.Plain(el:GetTop())
    if not (l and r and b and t) then h:Hide(); return end

    local es = C.EffectiveScale(el)
    local hs = C.EffectiveScale(h)
    if hs <= 0 then hs = 1 end
    local k = es / hs

    local w  = max((r - l) * k, 1)
    local ht = max((t - b) * k, 1)

    h:ClearAllPoints()
    h:SetSize(w, ht)
    h:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l * k, b * k)

    local padX = max((C.MIN_HIT - w) * 0.5, 0)
    local padY = max((C.MIN_HIT - ht) * 0.5, 0)
    h:SetHitRectInsets(-padX, -padX, -padY, -padY)
    h:Show()
end

function CanvasMT:Rebuild()
    for _, h in pairs(self.handles) do h:Hide() end
    if not self.subject then return end
    for _, desc in ipairs(R.List(self.domain)) do
        local h = self.handles[desc.id]
        if not h then
            h = self:_CreateHandle(desc.id)
            self.handles[desc.id] = h
        end
        self:_SyncHandle(desc.id)
        styleHandle(h, self.accent, self.selected == desc.id)
    end
end

-- ---------------------------------------------------------------------
-- Selection
-- ---------------------------------------------------------------------
function CanvasMT:Select(id)
    if id ~= nil and not R.Get(self.domain, id) then return end
    self.selected = id
    for hid, h in pairs(self.handles) do
        styleHandle(h, self.accent, hid == id)
    end
    if self.onSelect then self.onSelect(id) end
end

-- ---------------------------------------------------------------------
-- Drag
-- ---------------------------------------------------------------------

-- AstralForge now follows the same drag model as Healer Studio: the visible
-- element follows the cursor, and the drop chooses the nearest 3x3 anchor on
-- its CURRENT target. `relTo` is deliberately preserved, so advanced layouts
-- anchored to a sibling element keep that relationship instead of being
-- flattened back onto the unit frame.
--
-- The nearest anchor is picked in screen pixels. This is important when the
-- preview or one of its ancestors is scaled: comparing raw UI coordinates is
-- the exact source of the old minimap double-scale bug.
local function PickAnchor(source, host)
    local cx, cy = C.PointCoord(source, "CENTER")
    local left, top = C.PointCoord(host, "TOPLEFT")
    local right, bottom = C.PointCoord(host, "BOTTOMRIGHT")
    if not (cx and cy and left and right and top and bottom) then return "CENTER" end

    local w, h = right - left, top - bottom
    local midX, midY = (left + right) * 0.5, (bottom + top) * 0.5

    local horizontal = ""
    if cx < midX - w / 6 then horizontal = "LEFT"
    elseif cx > midX + w / 6 then horizontal = "RIGHT" end

    local vertical = ""
    if cy > midY + h / 6 then vertical = "TOP"
    elseif cy < midY - h / 6 then vertical = "BOTTOM" end

    local point = vertical .. horizontal
    if point == "" then point = "CENTER" end
    return point
end

function CanvasMT:_Measure(id, source, autoAnchor)
    local desc = R.Get(self.domain, id)
    if not desc or not self.subject then return end
    local cfg    = R.Sanitize(self.domain, id, self.store and self.store[id])
    local target = R.ResolveTarget(self.domain, cfg.relTo, self.subject)
    if not target then
        cfg.relTo = desc.default.relTo
        target = R.ResolveTarget(self.domain, cfg.relTo, self.subject)
        if not target then return end
    end
    if autoAnchor then
        local point = PickAnchor(source, target)
        cfg.point, cfg.relPoint = point, point
    end
    local x, y = C.ComputeOffset(source, target, cfg.point, cfg.relPoint)
    if not x then return end
    return cfg, target, x, y
end

function CanvasMT:_DragUpdate(id)
    local h = self.handles[id]
    local desc = R.Get(self.domain, id)
    if not h or not desc then return end
    local cfg, target, x, y = self:_Measure(id, h, true)
    if not cfg then return end

    local ok, el = pcall(desc.resolve, self.subject)
    if not ok or not el then return end

    local gx, gy = false, false
    if not IsShiftKeyDown() then
        x, y = C.Snap(x, self.snap), C.Snap(y, self.snap)
        x, y, gx, gy = C.ApplyGuides(el, target, cfg.point, cfg.relPoint, x, y)
    end

    el:ClearAllPoints()
    el:SetPoint(cfg.point, target, cfg.relPoint, x, y)
    self:_ShowGuides(target, gx, gy)
end

function CanvasMT:_DragStop(id)
    local h = self.handles[id]
    local desc = R.Get(self.domain, id)
    if not h or not desc then return end

    local ok, el = pcall(desc.resolve, self.subject)
    if not ok or not el then return end

    -- Measure from the ELEMENT, not the handle: _DragUpdate already moved
    -- the element onto the snapped/guided position, and the handle still
    -- carries the raw cursor delta.
    local cfg, target, x, y = self:_Measure(id, el, true)
    self:_ShowGuides(nil, false, false)
    if not cfg then return end

    if not IsShiftKeyDown() then
        x, y = C.Snap(x, self.snap), C.Snap(y, self.snap)
    end

    if type(self.store) == "table" then
        local rec = self.store[id]
        if type(rec) ~= "table" then
            rec = R.Default(self.domain, id)
            self.store[id] = rec
        end
        rec.point, rec.relTo, rec.relPoint = cfg.point, cfg.relTo, cfg.relPoint
        rec.x, rec.y = x, y
    end

    if self.onChange then self.onChange(id) end
    self:Rebuild()
end

function CanvasMT:_ShowGuides(target, gx, gy)
    if not target or not (gx or gy) then
        self.guideV:Hide(); self.guideH:Hide()
        return
    end
    if gx then
        self.guideV:ClearAllPoints()
        self.guideV:SetPoint("TOP", target, "TOP", 0, 12)
        self.guideV:SetPoint("BOTTOM", target, "BOTTOM", 0, -12)
        self.guideV:Show()
    else
        self.guideV:Hide()
    end
    if gy then
        self.guideH:ClearAllPoints()
        self.guideH:SetPoint("LEFT", target, "LEFT", -12, 0)
        self.guideH:SetPoint("RIGHT", target, "RIGHT", 12, 0)
        self.guideH:Show()
    end
    if not gy then self.guideH:Hide() end
end

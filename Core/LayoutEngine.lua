-- =====================================================================
-- LayoutEngine.lua — Resolution-independent positions (v4 Lot 2)
-- ---------------------------------------------------------------------
-- What this fixes.
--
-- Positions are stored today in three different shapes that grew
-- independently -- point/relativePoint (21 anchors), anchor/relTo (6)
-- and point/relPoint (2) -- and all three store raw offsets against
-- UIParent with no record of the screen they were captured on. Move a
-- profile from 2560x1440 to 1920x1080 and every element keeps its pixel
-- offset, which means anything placed near an edge ends up somewhere
-- else, and anything placed far from its anchor can land off-screen.
--
-- The v2 shape adds two things: one name for the two anchor points, and
-- the dimensions the offsets were captured at.
--
--     position = {
--         v      = 2,
--         point  = "BOTTOMLEFT",   -- the point on the frame
--         anchor = "BOTTOMLEFT",   -- the point on UIParent
--         x, y   = <offset, in UIParent units>,
--         refW, refH = <UIParent size when captured>,
--     }
--
-- Migration is a pure rename and stamps no refW/refH. That is
-- deliberate: a position with no reference size is applied exactly as
-- written, so upgrading moves nothing. Only positions saved after the
-- migration carry a reference and get rescaled on a different screen.
-- An upgrade that silently rearranged someone's UI would be a worse bug
-- than the one being fixed.
--
-- Why an anchor point rather than a pure fraction of the screen.
-- Fractions are resolution-independent but wrong for the common case:
-- a bar sitting 40 units above the bottom edge should stay 40 units
-- above the bottom edge, not move to 3% of the height. Saving picks the
-- nearest of nine points on UIParent, so an element near a corner keeps
-- its distance to that corner and only elements in open space are
-- rescaled proportionally.
-- =====================================================================

TomoMod_Layout = TomoMod_Layout or {}
local Layout = TomoMod_Layout

Layout.SCHEMA_VERSION = 2

local R = TomoMod_Registry

-- ---------------------------------------------------------------------
-- ANCHOR GEOMETRY
-- ---------------------------------------------------------------------
-- Each of the nine points, as a fraction of UIParent. Used both to
-- resolve a stored anchor into coordinates and to choose one at save
-- time.
-- ---------------------------------------------------------------------

local ANCHORS = {
    BOTTOMLEFT  = { 0.0, 0.0 },
    BOTTOM      = { 0.5, 0.0 },
    BOTTOMRIGHT = { 1.0, 0.0 },
    LEFT        = { 0.0, 0.5 },
    CENTER      = { 0.5, 0.5 },
    RIGHT       = { 1.0, 0.5 },
    TOPLEFT     = { 0.0, 1.0 },
    TOP         = { 0.5, 1.0 },
    TOPRIGHT    = { 1.0, 1.0 },
}
Layout.ANCHORS = ANCHORS

--- Legacy key names, mapped onto the two v2 fields. The three shapes
--- differ only in spelling, which is why the conversion is exact.
local LEGACY_POINT  = { "point",  "anchor" }
local LEGACY_ANCHOR = { "relativePoint", "relPoint", "relTo" }

local function ScreenSize()
    if not UIParent then return nil, nil end
    local w, h = UIParent:GetWidth(), UIParent:GetHeight()
    if not w or not h or w <= 0 or h <= 0 then return nil, nil end
    return w, h
end
Layout.ScreenSize = ScreenSize

-- ---------------------------------------------------------------------
-- PURE MATH
-- ---------------------------------------------------------------------
-- Split out so the headless suites can exercise the rescaling without a
-- single frame in existence. Everything below that touches a frame is a
-- thin wrapper over these.
-- ---------------------------------------------------------------------

--- Offsets captured on a refW x refH screen, expressed for curW x curH.
--- With no reference recorded the offsets are returned untouched: that
--- is the migrated-but-never-moved case, and guessing would move things.
function Layout.Rescale(x, y, refW, refH, curW, curH)
    x, y = x or 0, y or 0
    if not refW or not refH or not curW or not curH then return x, y end
    if refW <= 0 or refH <= 0 then return x, y end
    return x * (curW / refW), y * (curH / refH)
end

--- Coordinates of an anchor point, in UIParent units.
function Layout.AnchorPoint(anchor, w, h)
    local a = ANCHORS[anchor] or ANCHORS.CENTER
    return a[1] * (w or 0), a[2] * (h or 0)
end

--- The nine-way choice. Thirds rather than halves, so the middle band
--- is genuinely "not near an edge" instead of everything on one side of
--- the centre line snapping to that edge.
function Layout.PickAnchor(cx, cy, w, h)
    if not w or not h or w <= 0 or h <= 0 then return "CENTER" end
    local horiz = (cx < w / 3) and "LEFT" or (cx > w * 2 / 3) and "RIGHT" or ""
    local vert  = (cy < h / 3) and "BOTTOM" or (cy > h * 2 / 3) and "TOP" or ""
    local name  = vert .. horiz
    if name == "" then return "CENTER" end
    return ANCHORS[name] and name or "CENTER"
end

-- ---------------------------------------------------------------------
-- READ / MIGRATE
-- ---------------------------------------------------------------------

--- True when the table is already in the v2 shape.
local function IsV2(pos)
    return type(pos) == "table" and pos.v == Layout.SCHEMA_VERSION
end

--- Converts one legacy position table in place. Returns true when
--- something was converted, so callers can count.
---
--- No refW/refH is stamped. See the header: a converted position must
--- land exactly where it landed before.
function Layout.MigratePosition(pos)
    if type(pos) ~= "table" then return false end
    if IsV2(pos) then return false end

    local point, anchor
    for _, k in ipairs(LEGACY_POINT) do
        if type(pos[k]) == "string" then point = pos[k] break end
    end
    for _, k in ipairs(LEGACY_ANCHOR) do
        if type(pos[k]) == "string" then anchor = pos[k] break end
    end
    -- Nothing recognisable: leave it alone rather than invent a shape.
    -- Apply() falls back to the caller's defaults for these.
    if not point and not anchor then return false end

    pos.point  = point  or anchor or "CENTER"
    pos.anchor = anchor or point  or "CENTER"
    pos.x      = tonumber(pos.x) or 0
    pos.y      = tonumber(pos.y) or 0
    pos.v      = Layout.SCHEMA_VERSION

    -- Drop the spellings that are no longer read, so a profile does not
    -- carry three names for one concept forever.
    pos.relativePoint, pos.relPoint, pos.relTo = nil, nil, nil
    return true
end

--- Walks every anchor the manifests declare and migrates it. Driven by
--- the registry rather than a hand-written list: the anchors and their
--- storage shapes were declared in lot 0 precisely so this could be a
--- table walk instead of twenty-nine special cases.
function Layout.MigrateAll(db)
    db = db or TomoModDB
    if type(db) ~= "table" or not R then return 0, 0 end
    local converted, seen = 0, 0
    for _, a in ipairs(R.Anchors()) do
        local pos = R.GetPath(db, a.path)
        if type(pos) == "table" then
            seen = seen + 1
            if Layout.MigratePosition(pos) then converted = converted + 1 end
        end
    end
    return converted, seen
end

-- ---------------------------------------------------------------------
-- SAVE
-- ---------------------------------------------------------------------

--- Captures where `frame` currently sits into `store`.
---
--- Reads GetLeft/GetBottom/GetTop/GetRight rather than GetPoint:
--- StartMoving/StopMovingOrSizing leave GetPoint reporting the anchor
--- the frame had before the drag, which is how positions used to drift
--- by exactly one drag's worth every time.
function Layout.Save(store, frame)
    if type(store) ~= "table" or not frame then return false end
    local w, h = ScreenSize()
    if not w then return false end

    local scale = 1
    if frame.GetEffectiveScale and UIParent.GetEffectiveScale then
        local fs, us = frame:GetEffectiveScale(), UIParent:GetEffectiveScale()
        if fs and us and us > 0 then scale = fs / us end
    end

    local left, bottom = frame:GetLeft(), frame:GetBottom()
    local right, top   = frame:GetRight(), frame:GetTop()
    if not left or not bottom or not right or not top then return false end

    left, bottom = left * scale, bottom * scale
    right, top   = right * scale, top * scale

    local cx, cy = (left + right) / 2, (bottom + top) / 2
    local anchor = Layout.PickAnchor(cx, cy, w, h)

    -- The frame anchors by the same-named point, so an element in the
    -- top-right corner keeps its distance to the top-right corner.
    local fx, fy
    if anchor:find("LEFT")   then fx = left
    elseif anchor:find("RIGHT") then fx = right
    else fx = cx end
    if anchor:find("BOTTOM") then fy = bottom
    elseif anchor:find("TOP")    then fy = top
    else fy = cy end

    local ax, ay = Layout.AnchorPoint(anchor, w, h)

    store.v      = Layout.SCHEMA_VERSION
    store.point  = anchor
    store.anchor = anchor
    store.x      = fx - ax
    store.y      = fy - ay
    store.refW   = w
    store.refH   = h
    store.relativePoint, store.relPoint, store.relTo = nil, nil, nil
    return true
end

-- ---------------------------------------------------------------------
-- APPLY
-- ---------------------------------------------------------------------

--- Places `frame` from `store`, falling back to `defaults` when the
--- store holds nothing usable. `defaults` takes the same shape as a
--- position table and is normally the module's entry in TomoMod_Defaults.
function Layout.Apply(store, frame, defaults)
    if not frame or not frame.SetPoint then return false end

    local pos = store
    if type(pos) ~= "table" or (not pos.point and not pos.anchor) then
        pos = defaults
    end
    if type(pos) ~= "table" then return false end

    if not IsV2(pos) then Layout.MigratePosition(pos) end

    local point  = pos.point  or pos.anchor or "CENTER"
    local anchor = pos.anchor or pos.point  or "CENTER"
    local w, h   = ScreenSize()
    local x, y   = Layout.Rescale(pos.x, pos.y, pos.refW, pos.refH, w, h)

    -- Save() stores offsets in UIParent units. SetPoint() offsets are in the
    -- moved frame's own coordinate space, so scaled frames need the inverse
    -- conversion here or every save/reload cycle multiplies their position by
    -- their scale (Minimap, ResourceBars, MythicTracker, ObjectiveTracker...).
    local ratio = 1
    if frame.GetEffectiveScale and UIParent.GetEffectiveScale then
        local fs, us = frame:GetEffectiveScale(), UIParent:GetEffectiveScale()
        if fs and us and fs > 0 and us > 0 then ratio = fs / us end
    end

    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, anchor, x / ratio, y / ratio)
    return true
end

--- True when `frame` is already at the physical position represented by
--- `store`. Comparison happens in UIParent units and is therefore independent
--- of the frame's own scale. Used by frames such as the Minimap which Blizzard
--- may harmlessly re-anchor internally without actually moving on screen.
function Layout.Matches(store, frame, tolerance)
    if type(store) ~= "table" or not frame then return false end
    if not (frame.GetLeft and frame.GetBottom and frame.GetRight and frame.GetTop) then return false end
    if not IsV2(store) then Layout.MigratePosition(store) end

    local point  = store.point  or store.anchor or "CENTER"
    local anchor = store.anchor or store.point  or "CENTER"
    local w, h   = ScreenSize()
    if not w then return false end

    local x, y = Layout.Rescale(store.x, store.y, store.refW, store.refH, w, h)
    local ax, ay = Layout.AnchorPoint(anchor, w, h)
    local expectedX, expectedY = ax + x, ay + y

    local ratio = 1
    if frame.GetEffectiveScale and UIParent.GetEffectiveScale then
        local fs, us = frame:GetEffectiveScale(), UIParent:GetEffectiveScale()
        if fs and us and fs > 0 and us > 0 then ratio = fs / us end
    end

    local left, bottom = frame:GetLeft(), frame:GetBottom()
    local right, top   = frame:GetRight(), frame:GetTop()
    if not left or not bottom or not right or not top then return false end
    left, bottom, right, top = left * ratio, bottom * ratio, right * ratio, top * ratio

    local currentX
    if point:find("LEFT", 1, true) then currentX = left
    elseif point:find("RIGHT", 1, true) then currentX = right
    else currentX = (left + right) / 2 end

    local currentY
    if point:find("BOTTOM", 1, true) then currentY = bottom
    elseif point:find("TOP", 1, true) then currentY = top
    else currentY = (bottom + top) / 2 end

    tolerance = tonumber(tolerance) or 1
    return math.abs(currentX - expectedX) <= tolerance
       and math.abs(currentY - expectedY) <= tolerance
end

--- Marks every declared anchor with the current screen size, so that
--- positions which came through the migration -- and therefore carry no
--- reference and are applied verbatim -- start following a resolution
--- change from here on.
---
--- Never called by the migration itself, on purpose: doing it there
--- would rescale everyone's layout on upgrade, which is the one thing
--- the v2 conversion is built to avoid. It belongs to a moment when the
--- player has just said the layout suits this screen, which is exactly
--- what applying a resolution preset means.
function Layout.StampReference(db)
    db = db or TomoModDB
    if type(db) ~= "table" or not R then return 0 end
    local w, h = ScreenSize()
    if not w then return 0 end

    local n = 0
    for _, a in ipairs(R.Anchors()) do
        local pos = R.GetPath(db, a.path)
        if type(pos) == "table" then
            if not IsV2(pos) then Layout.MigratePosition(pos) end
            if pos.point or pos.anchor then
                pos.refW, pos.refH = w, h
                n = n + 1
            end
        end
    end
    return n
end

-- ---------------------------------------------------------------------
-- LABELS
-- ---------------------------------------------------------------------
-- The drag overlay used to print a hardcoded French "Déplacer" whenever
-- a call site passed no label, which is what every unit frame and the
-- resource bar container did. Anchors carry a label locale key in their
-- manifest; this resolves it.
-- ---------------------------------------------------------------------

local anchorLabels

local function BuildLabelIndex()
    anchorLabels = {}
    if not R then return end
    for _, a in ipairs(R.Anchors()) do
        if a.label then anchorLabels[a.id] = a.label end
    end
end

--- Human-readable name for an anchor, in the player's language.
--- Falls back to the anchor id, which is at least specific, rather than
--- to a generic verb that tells the player nothing about what they are
--- about to drag.
function Layout.Label(anchorID, fallback)
    if not anchorID then return fallback end
    if not anchorLabels then BuildLabelIndex() end
    local key = anchorLabels[anchorID]
    if not key then return fallback or anchorID end
    local L = TomoMod_L
    local text = L and L[key]
    -- The localisation metatable hands back the raw key for an unknown
    -- one, so an unresolved key would otherwise read "frame_player".
    if not text or text == key then return fallback or anchorID end
    return text
end

--- Test seam: the index is built once and cached.
function Layout._ResetLabels()
    anchorLabels = nil
end

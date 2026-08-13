-- =====================================================================
-- Core/TuiCompat/UIKitShim.lua
--
-- The ported action bar code touches exactly two of ns.UIKit's functions.
-- Rather than extract them from Tui's 3177-line uikit.lua -- where they sit
-- on top of an internal scale-refresh registry, an edge-texture builder and a
-- shared state table -- this is a self-contained equivalent with the same
-- signatures. Fewer moving parts, and nothing else in TomoMod has to inherit
-- that registry.
-- =====================================================================

local ns = TomoMod_TuiNS
local UIKit = ns.UIKit or {}
ns.UIKit = UIKit

local state = setmetatable({}, { __mode = "k" })

local function Pixel(frame)
    -- One physical pixel at the frame's effective scale.
    local scale = frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
    if type(scale) ~= "number" or scale <= 0 then scale = 1 end
    return 1 / scale
end

function UIKit.CreateBorderLines(frame)
    if not frame or not frame.CreateTexture then return nil end
    local s = state[frame]
    if s and s.edges then return s.edges end

    local edges = {}
    for _, side in ipairs({ "top", "bottom", "left", "right" }) do
        local t = frame:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(0, 0, 0, 1)
        edges[side] = t
    end

    state[frame] = { edges = edges, size = 1, color = { 0, 0, 0, 1 }, hidden = false }
    UIKit.UpdateBorderLines(frame, 1, 0, 0, 0, 1, false)
    return edges
end

function UIKit.UpdateBorderLines(frame, sizePixels, r, g, b, a, hide)
    if not frame then return end
    local s = state[frame]
    if not s then
        UIKit.CreateBorderLines(frame)
        s = state[frame]
        if not s then return end
    end

    local size = tonumber(sizePixels) or s.size or 1
    r, g, b, a = r or 0, g or 0, b or 0, a or 1
    local hidden = (hide and true or false) or size <= 0

    s.size = size
    s.color[1], s.color[2], s.color[3], s.color[4] = r, g, b, a
    s.hidden = hidden

    local edges = s.edges
    if hidden then
        for _, t in pairs(edges) do t:Hide() end
        return
    end

    local thickness = size * Pixel(frame)

    edges.top:ClearAllPoints()
    edges.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    edges.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    edges.top:SetHeight(thickness)

    edges.bottom:ClearAllPoints()
    edges.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    edges.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    edges.bottom:SetHeight(thickness)

    edges.left:ClearAllPoints()
    edges.left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -thickness)
    edges.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, thickness)
    edges.left:SetWidth(thickness)

    edges.right:ClearAllPoints()
    edges.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -thickness)
    edges.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, thickness)
    edges.right:SetWidth(thickness)

    for _, t in pairs(edges) do
        t:SetColorTexture(r, g, b, a)
        t:Show()
    end
end

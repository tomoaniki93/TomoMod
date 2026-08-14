-- =====================================================================
-- Core/TuiCompat/Bridges.lua
--
-- Where a ported module reaches for a Tui subsystem that TomoMod already has
-- an equivalent of, the call is routed here instead of dragging the Tui
-- version across. Each of these is one function deep in practice.
-- =====================================================================

local ns = TomoMod_TuiNS

-- Frame anchoring: TomoMod owns this in Modules/QOL/FrameAnchors, which
-- exposes ApplyAnchor(def) per anchor rather than an apply-all, so the loop
-- lives here. ANCHOR_DEFS is module-local upstream; we go through the public
-- accessor when there is one and degrade quietly when there is not, because a
-- missing re-anchor is cosmetic while an error here would break a bar refresh.
ns.TUI_Anchoring = ns.TUI_Anchoring or {}
function ns.TUI_Anchoring.ApplyAllFrameAnchors()
    local FA = TomoMod_FrameAnchors
    if not FA then return end
    if FA.ApplyAll then
        pcall(FA.ApplyAll)
        return
    end
    local defs = FA.ANCHOR_DEFS or FA.GetAnchorDefs and FA.GetAnchorDefs()
    if type(defs) == "table" and FA.ApplyAnchor then
        for _, def in ipairs(defs) do
            pcall(FA.ApplyAnchor, def)
        end
    end
end

-- Layout / move mode: TomoMod owns this in Modules/QOL/Movers.
ns.TUI_LayoutMode = ns.TUI_LayoutMode or {}
function ns.TUI_LayoutMode.IsActive()
    local M = TomoMod_Movers
    if M and M.IsUnlocked then
        local ok, res = pcall(M.IsUnlocked)
        return (ok and res) and true or false
    end
    return false
end

function ns.TUI_LayoutMode.Toggle()
    local M = TomoMod_Movers
    if M and M.Toggle then pcall(M.Toggle) end
end

-- Ported TUI action-bar code registers its layout-mode elements via this hook.
-- TomoMod does not implement the full TUI layout-mode registry, so this is a
-- safe compatibility shim that keeps the ported code from crashing when the
-- feature is not active.
function ns.TUI_LayoutMode.RegisterElement()
end

ns.TUI_LayoutMode_Utils = ns.TUI_LayoutMode_Utils or {}

-- Pixel backdrop: Tui ships this as a two-line file. Kept as a thin wrapper
-- so ported skinning code finds it where it expects.
-- Real call sites (actionbars_editmode.lua, actionbars_extra_buttons.lua) use
-- Tui's actual signature: (frame, borderSize, filled, glow, borderColor, glowColor)
-- with borderColor/glowColor as {r,g,b,a} tables — not the (frame,r,g,b,a) floats
-- this shim originally assumed. Both callers create their frame with
-- "BackdropTemplate", so this goes through SetBackdrop instead of a raw texture.
ns.SkinBase = ns.SkinBase or {}
local PIXEL_BACKDROP_SOLID = "Interface\\Buttons\\WHITE8X8"
function ns.SkinBase.ApplyPixelBackdrop(frame, borderSize, filled, glow, borderColor, glowColor)
    if not frame or not frame.SetBackdrop then return end
    borderSize = tonumber(borderSize) or 1
    borderColor = borderColor or { 1, 1, 1, 1 }

    frame:SetBackdrop({
        bgFile   = PIXEL_BACKDROP_SOLID,
        edgeFile = PIXEL_BACKDROP_SOLID,
        edgeSize = borderSize,
        insets   = { left = borderSize, right = borderSize, top = borderSize, bottom = borderSize },
    })

    if filled then
        frame:SetBackdropColor(borderColor[1] or 1, borderColor[2] or 1, borderColor[3] or 1, (borderColor[4] or 1) * 0.25)
    else
        frame:SetBackdropColor(0, 0, 0, 0)
    end

    -- glow/glowColor accepted for signature compatibility; the border itself
    -- carries enough contrast for a move-mode highlight, so no separate layer.
    local edgeColor = (glow and glowColor) or borderColor
    frame:SetBackdropBorderColor(edgeColor[1] or 1, edgeColor[2] or 1, edgeColor[3] or 1, edgeColor[4] or 1)
end

-- Settings search routing is a Tui options-framework feature with no TomoMod
-- counterpart. Ported code only ever calls it, never reads a result.
ns.Settings = ns.Settings or {}
function ns.Settings.SearchRoute() end

-- Not present in the Tui core we ported from; only gse_compat references it,
-- which is out of scope until lot P7.
ns.Multiclick = ns.Multiclick or nil

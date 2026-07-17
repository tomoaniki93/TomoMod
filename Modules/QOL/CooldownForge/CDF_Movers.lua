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

local function ensureOverlay(f, bar)
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
    hint:SetText("Glisser pour deplacer")

    o:SetScript("OnDragStart", function() f:StartMoving() end)
    o:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        savePosition(bar, f)
        place(f, bar)
    end)
    o:SetScript("OnEnter", function() bg:SetColorTexture(br[1], br[2], br[3], 0.30) end)
    o:SetScript("OnLeave", function() bg:SetColorTexture(br[1], br[2], br[3], 0.18) end)

    f._cdfOverlay = o
    return o
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
        -- Restore normal rendering (hides empty/disabled bars).
        if CDF.RefreshAll then CDF.RefreshAll() end
    else
        for i = 1, #arr do
            local bar = arr[i]
            local f = CDF.GetBarFrame(bar)
            place(f, bar)
            local o = ensureOverlay(f, bar)
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
    end
end

function CDF.ToggleLock()
    CDF.SetLocked(not isLocked)
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

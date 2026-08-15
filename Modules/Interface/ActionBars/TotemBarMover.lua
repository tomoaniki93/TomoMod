-- =====================================================================
-- TotemBarMover.lua -- registers the ported totem bar with TomoMod's Movers
--
-- TomoMod glue, NOT a ported file: keep it out of tui/ so re-importing a
-- newer Tui revision never touches it.
--
-- The totem bar carries its own OnDragStart/OnDragStop, gated on db.locked.
-- That is all TomoMod's layout mode needs to drive it, so this entry toggles
-- that flag rather than reimplementing dragging. The overlay exists purely so
-- the bar is visible and labelled while unlocked, even when the player has no
-- totems out and the container would otherwise be empty.
-- =====================================================================

local ACCENT = { 0.05, 0.82, 0.62 }   -- same accent Movers.lua uses

local overlay

local function GetDB()
    return TomoModDB and TomoModDB.totemBar
end

local function GetContainer()
    return _G["TUI_TotemBar"]
end

local function EnsureOverlay(container)
    if overlay then return overlay end

    overlay = CreateFrame("Frame", "TomoModTotemBarMoverOverlay", container)
    overlay:SetAllPoints(container)
    overlay:SetFrameStrata("DIALOG")
    overlay:Hide()

    local bg = overlay:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.25)

    for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local edge = overlay:CreateTexture(nil, "OVERLAY")
        edge:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
        if side == "TOP" or side == "BOTTOM" then
            edge:SetPoint(side .. "LEFT")
            edge:SetPoint(side .. "RIGHT")
            edge:SetHeight(1)
        else
            edge:SetPoint("TOP" .. side)
            edge:SetPoint("BOTTOM" .. side)
            edge:SetWidth(1)
        end
    end

    local label = overlay:CreateFontString(nil, "OVERLAY")
    label:SetPoint("CENTER")
    label:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf", 11, "OUTLINE")
    label:SetTextColor(1, 1, 1, 1)
    local L = TomoMod_L
    label:SetText(L and L["mover_totembar"] or "Totems")

    return overlay
end

local function SetLocked(locked)
    local db = GetDB()
    if not db then return end
    db.locked = locked and true or false

    local container = GetContainer()
    if not container then return end

    -- An empty totem bar has zero visible buttons, so without a minimum the
    -- unlocked frame would be too small to grab.
    if not locked then
        local o = EnsureOverlay(container)
        if container:GetWidth() < 40 or container:GetHeight() < 20 then
            container:SetSize(math.max(container:GetWidth(), 120),
                              math.max(container:GetHeight(), 36))
        end
        container:Show()
        o:Show()
    elseif overlay then
        overlay:Hide()
    end
end

local function Register()
    local M = TomoMod_Movers
    if not M or not M.RegisterEntry then return end
    local L = TomoMod_L

    M.RegisterEntry({
        label    = (L and L["mover_totembar"]) or "Totems",
        unlock   = function() SetLocked(false) end,
        lock     = function() SetLocked(true) end,
        isActive = function()
            local db = GetDB()
            return db and db.enabled and true or false
        end,
    })
end

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    -- After the totem bar has built its container.
    C_Timer.After(1.5, Register)
end)

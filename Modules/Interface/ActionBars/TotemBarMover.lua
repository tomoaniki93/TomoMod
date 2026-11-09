-- =====================================================================
-- TotemBarMover.lua -- registers the ported totem bar with TomoMod's Movers
--
-- TomoMod glue, NOT a ported file: keep it out of tui/ so re-importing a
-- newer Tui revision never touches it.
--
-- The totem bar carries its own saved-position path, gated on db.locked. The
-- layout overlay starts the parent movement and delegates its stop to that path,
-- because the runtime container disables mouse input when no totem is active.
-- The overlay also keeps the empty bar visible and labelled while unlocked.
-- =====================================================================

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
    -- Totem buttons own frame levels above their container. Once TomoLayout
    -- lowers every edit surface to LOW, the mover still needs to sit above
    -- those buttons so its opaque shared skin actually masks the live bar.
    overlay:SetFrameLevel(container:GetFrameLevel() + 20)
    overlay:EnableMouse(true)
    overlay:RegisterForDrag("LeftButton")
    if TomoMod_Utils and TomoMod_Utils.StyleMoverOverlay then
        TomoMod_Utils.StyleMoverOverlay(
            overlay,
            (TomoMod_L and TomoMod_L["mover_totembar"]) or "Totem Bar"
        )
    end
    -- The runtime container disables mouse input while no totem is active.
    -- Drive its existing movement/save path from the layout overlay instead,
    -- so the empty bar remains draggable as promised by the layout mode.
    overlay:SetScript("OnDragStart", function(self)
        local db = GetDB()
        if InCombatLockdown() or not db or db.locked then return end
        container:StartMoving()
        self._tmDragging = true
    end)
    overlay:SetScript("OnDragStop", function(self)
        if not self._tmDragging then return end
        self._tmDragging = nil
        local stop = container:GetScript("OnDragStop")
        if stop then
            stop(container)
        else
            container:StopMovingOrSizing()
        end
    end)
    overlay:Hide()

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
        -- Parent alpha is inherited by the child overlay. The normal totem
        -- runtime sets it to zero when the bar is empty, so layout mode must
        -- temporarily expose it and mark the state for a clean refresh later.
        container:SetAlpha(1)
        container.visible = true
        container:EnableMouse(true)
        container:Show()
        o:Show()
    elseif overlay then
        overlay._tmDragging = nil
        overlay:Hide()
        -- Re-evaluate real totems immediately: this restores alpha and mouse
        -- input for both the empty and active runtime states.
        if type(_G.TUI_RefreshTotemBar) == "function" then
            _G.TUI_RefreshTotemBar()
        end
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

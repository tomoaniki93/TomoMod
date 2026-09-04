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

-- [L1] The edit-session machinery (grid, snap, generic overlays and the
-- external-movable registry) moved to Core/Forge/ForgeEdit.lua and is now
-- shared addon-wide. This file keeps only the CooldownForge specifics:
-- bar placement/persistence and the bars provider for the shared session.

local Forge = TomoMod_Forge

local function savePosition(bar, f)
    local hx, hy = f:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not hx or not ux then return end
    bar.position = {
        point = "CENTER", relPoint = "CENTER",
        x = floor(hx - ux + 0.5), y = floor(hy - uy + 0.5),
    }
end

local function place(f, bar)
    local p = bar.position or {}
    f:ClearAllPoints()
    f:SetPoint(p.point or "CENTER", UIParent, p.relPoint or "CENTER", p.x or 0, p.y or 0)
end

-- [P3] Contextual preset members are one visual element. Moving any member
-- updates every sibling in the pack so Solo/Mythic+/Raid never jump to three
-- different places when the group context changes.
local function setLinkedPosition(bar, x, y)
    local pos = { point = "CENTER", relPoint = "CENTER", x = x, y = y }
    local packID = bar.contextPackID
    if not packID then
        bar.position = pos
        place(CDF.GetBarFrame(bar), bar)
        return
    end

    for _, sibling in ipairs(CDF.GetClassBars(CDF.PlayerClass()) or {}) do
        if sibling.contextPackID == packID then
            sibling.position = { point = "CENTER", relPoint = "CENTER", x = x, y = y }
            place(CDF.GetBarFrame(sibling), sibling)
        end
    end
end

local function ensureBarOverlay(f, bar)
    return Forge.Edit.AttachOverlay(f,
        function(x, y)
            setLinkedPosition(bar, x, y)
        end,
        function()
            setLinkedPosition(bar, 0, 0)
        end)
end

-- Bars provider: fired by the shared session on every lock transition.
local function BarsProvider(locked)
    local arr = CDF.GetClassBars(CDF.PlayerClass())
    if not arr then return end
    if locked then
        for i = 1, #arr do
            local bar = arr[i]
            local f = CDF.GetBarFrame(bar)
            savePosition(bar, f)
            if f._forgeOverlay then f._forgeOverlay:Hide() end
            f:SetMovable(false)
        end
        -- Restore normal rendering (hides empty/disabled bars).
        if CDF.RefreshAll then CDF.RefreshAll() end
    else
        local shownPacks = {}
        for i = 1, #arr do
            local bar = arr[i]
            local f = CDF.GetBarFrame(bar)
            place(f, bar)

            -- Only one mover is needed for a linked contextual pack. The
            -- sibling frames still follow it through setLinkedPosition.
            local showOverlay = true
            if bar.contextPackID then
                if shownPacks[bar.contextPackID] then
                    showOverlay = false
                else
                    shownPacks[bar.contextPackID] = true
                end
            end

            if showOverlay then
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
            else
                if f._forgeOverlay then f._forgeOverlay:Hide() end
                f:SetMovable(false)
                f:Show()
            end
        end
    end
end

if Forge and Forge.Edit then
    Forge.Edit.RegisterProvider(BarsProvider)
end

-- [L1] Public API preserved as thin aliases over the shared session
-- (studio, config panel and the Movers-manager glue keep working as-is).
function CDF.IsLocked()
    if Forge and Forge.Edit then return Forge.Edit.IsLocked() end
    return true
end

function CDF.SetLocked(locked)
    if Forge and Forge.Edit then Forge.Edit.SetLocked(locked) end
end

function CDF.ToggleLock()
    if Forge and Forge.Edit then Forge.Edit.Toggle() end
end

function CDF.RegisterMovable(frame, opts)
    if Forge and Forge.Edit then return Forge.Edit.RegisterMovable(frame, opts) end
    return false
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

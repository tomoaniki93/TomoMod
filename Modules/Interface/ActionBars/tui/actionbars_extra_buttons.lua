-- =====================================================================
-- Ported from Tui: TUI_ActionBars/actionbars/actionbars_extra_buttons.lua
--
-- Every edit made to this file is marked with "TOMOMOD:" so upstream changes
-- stay diffable. Do not reformat: the point of keeping it verbatim is that a
-- newer Tui revision can be re-imported by replaying the same edits.
-- =====================================================================
local ADDON_NAME, ns = "TomoMod", TomoMod_TuiNS -- TOMOMOD: was `...`
local env = ns.ActionBarsEnv
env.ADDON_NAME = ADDON_NAME
env.ns = ns
env.SetChunkEnv(1, env)

---@diagnostic disable: lowercase-global -- SetChunkEnv installs a setfenv

do

extraBtnState = {
    extraActionHolder = nil,
    extraActionMover = nil,
    zoneAbilityHolder = nil,
    zoneAbilityMover = nil,
    zoneAbilityProxies = {},
    zoneAbilityNativeButtons = {},
    zoneAbilityNativeMouseStates = {},
    zoneAbilityNativeBridgeButtons = {},
    zoneAbilityNativeLayoutState = nil,
    zoneAbilityNativeBridgePositioned = false,
    zoneAbilityProxyEvents = nil,
    zoneAbilityResyncGeneration = 0,
    leaveVehicleProxy = nil,
    leaveVehicleStateDriverInstalled = false,
    moversVisible = false,
    hookingSetPoint = false,
    zoneAbilitySetPointHooked = false,
    extraAbilityContainerSetPointHooked = false,
    hookingSetParent = false,
    zoneAbilitySetParentHooked = false,
    extraAbilityContainerSetParentHooked = false,
    extraActionShowHooked = false,
    zoneAbilityShowHooked = false,
    extraAbilityContainerShowHooked = false,
    containerOwned = false,
    containerNeutralized = false,
    zoneOwned = false,
}

function GetExtraButtonDB(buttonType)
    local core = GetCore()
    if not core or not core.db or not core.db.profile then return nil end
    return core.db.profile.actionBars and core.db.profile.actionBars.bars
        and core.db.profile.actionBars.bars[buttonType]
end

function GetSavedExtraButtonFrameAnchor(buttonType)
    local core = GetCore()
    local profile = core and core.db and core.db.profile
    local fa = profile and profile.frameAnchoring
    if type(fa) ~= "table" or not buttonType then return nil end
    local entry = rawget(fa, buttonType)
    if type(entry) == "table" then
        return entry
    end
    return nil
end

-- NO-OVERRIDE FALLBACK on refresh: a profile whose mover was never dragged
function ApplyExtraButtonHolderFallbackPosition(buttonType, holder)
    if not holder then return end
    local settings = GetExtraButtonDB(buttonType)
    local point, relativeTo, relPoint, x, y =
        GetExtraButtonInitialPosition(buttonType, settings and settings.position)
    if not point then
        point, relativeTo, relPoint = "CENTER", UIParent, "CENTER"
        x = buttonType == "extraActionButton" and -100 or 100
        y = -200
    end
    holder:ClearAllPoints()
    holder:SetPoint(point, relativeTo or UIParent, relPoint or point, x or 0, y or 0)
end

function ApplyExtraButtonFrameAnchor(buttonType)
    -- COMBAT GATE (extra path): the extra holder hosts the anchored
    if buttonType == "extraActionButton"
        and InCombatLockdown()
    then
        ActionBarsOwned.pendingExtraButtonRefresh = true
        return
    end
    local HasAnchor = _G.TUI_HasFrameAnchor
    local ApplyAnchor = _G.TUI_ApplyFrameAnchor
    if HasAnchor and ApplyAnchor and HasAnchor(buttonType) then
        ApplyAnchor(buttonType)
        return
    end
    -- NO-OVERRIDE FALLBACK (see ApplyExtraButtonHolderFallbackPosition).
    local holder = buttonType == "extraActionButton"
        and extraBtnState.extraActionHolder
        or extraBtnState.zoneAbilityHolder
    if not holder then return end
    if InCombatLockdown()
        and Helpers.FrameMutationRestricted(holder)
    then
        ActionBarsOwned.pendingExtraButtonRefresh = true
        return
    end
    ApplyExtraButtonHolderFallbackPosition(buttonType, holder)
end

function SaveExtraButtonFrameAnchor(buttonType, point, relPoint, x, y)
    local core = GetCore()
    local profile = core and core.db and core.db.profile
    if not profile or not buttonType or not point then return end

    if type(profile.frameAnchoring) ~= "table" then
        profile.frameAnchoring = {}
    end

    local fa = profile.frameAnchoring
    local entry = rawget(fa, buttonType)
    if type(entry) ~= "table" then
        entry = {}
        fa[buttonType] = entry
    end

    entry.parent = "screen"
    entry.point = point
    entry.relative = relPoint or point
    entry.offsetX = x or 0
    entry.offsetY = y or 0
    entry.sizeStable = true
    entry.autoWidth = false
    entry.autoHeight = false
    entry.hideWithParent = false
    entry.keepInPlace = true
    entry.widthAdjust = 0
    entry.heightAdjust = 0
end

function SaveExtraButtonHolderPosition(buttonType, holder)
    if not holder then return end

    local core = GetCore()
    local point, relPoint, x, y

    if core and core.SnapFramePosition then
        local snappedPoint, _, snappedRelPoint, snappedX, snappedY = core:SnapFramePosition(holder)
        point, relPoint, x, y = snappedPoint, snappedRelPoint, snappedX, snappedY
    end

    if Helpers.HasSecretValue(point, relPoint, x, y) then return end

    if not point and holder.GetPoint then
        local fallbackPoint, _, fallbackRelPoint, fallbackX, fallbackY = holder:GetPoint(1)
        point, relPoint, x, y = fallbackPoint, fallbackRelPoint, fallbackX, fallbackY
    end

    if Helpers.HasSecretValue(point, relPoint, x, y) then return end

    if not point then return end

    x = tonumber(x) or 0
    y = tonumber(y) or 0
    relPoint = relPoint or point

    local db = GetExtraButtonDB(buttonType)
    if db then
        db.position = { point = point, relPoint = relPoint, x = x, y = y }
    end

    SaveExtraButtonFrameAnchor(buttonType, point, relPoint, x, y)
    ApplyExtraButtonFrameAnchor(buttonType)

    -- Zone Ability uses Blizzard's real native button as the
    -- trusted physical click target. When the owned mover is dragged, refresh
    -- immediately so the native bridge follows the saved TomoMod holder.
    if buttonType == "zoneAbility" and RefreshExtraButtons then
        RefreshExtraButtons()
    end

    if _G.TUI and _G.TUI.SendMessage then
        _G.TUI:SendMessage("TUI_FRAME_ANCHOR_CHANGED", buttonType)
    end
end

function GetExtraButtonInitialPosition(buttonType, fallbackPosition)
    local anchor = GetSavedExtraButtonFrameAnchor(buttonType)
    if anchor then
        local parentKey = anchor.parent
        local parentFrame
        if not parentKey or parentKey == "screen" or parentKey == "disabled" then
            parentFrame = UIParent
        elseif parentKey == "extraActionButton" and buttonType ~= "extraActionButton" then
            parentFrame = extraBtnState.extraActionHolder or _G["TUI_extraActionButtonHolder"]
        elseif parentKey == "zoneAbility" and buttonType ~= "zoneAbility" then
            parentFrame = extraBtnState.zoneAbilityHolder or _G["TUI_zoneAbilityHolder"]
        end

        if parentFrame then
            local point = anchor.point or "CENTER"
            return point, parentFrame, anchor.relative or point, anchor.offsetX or 0, anchor.offsetY or 0
        end
    end

    if fallbackPosition and fallbackPosition.point then
        return fallbackPosition.point, UIParent, fallbackPosition.relPoint or fallbackPosition.point,
            fallbackPosition.x or 0, fallbackPosition.y or 0
    end

    return nil
end

function CreateExtraButtonHolder(buttonType, displayName)
    local settings = GetExtraButtonDB(buttonType)
    if not settings then return nil, nil end

    local holder = CreateFrame("Frame", "TUI_" .. buttonType .. "Holder", UIParent)
    holder:SetSize(64, 64)
    holder:SetMovable(true)
    holder:SetClampedToScreen(true)

    ApplyExtraButtonHolderFallbackPosition(buttonType, holder)

    local mover = CreateFrame("Frame", "TUI_" .. buttonType .. "Mover", holder, "BackdropTemplate")
    mover:SetAllPoints(holder)
    -- TomoMod teal, matching the rest of the /tm layout movers
    ns.SkinBase.ApplyPixelBackdrop(mover, 2, true, false, {0.047, 0.824, 0.624, 1}, {0.047, 0.824, 0.624, 0.5})
    mover:EnableMouse(true)
    mover:SetMovable(true)
    mover:RegisterForDrag("LeftButton")
    mover:SetFrameStrata("HIGH")
    mover:Hide()

    local text = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetTextColor(1, 1, 1, 1)
    text:SetText(displayName)
    mover.text = text

    mover:SetScript("OnDragStart", function(self)
        holder:StartMoving()
    end)

    mover:SetScript("OnDragStop", function(self)
        holder:StopMovingOrSizing()
        SaveExtraButtonHolderPosition(buttonType, holder)
    end)

    return holder, mover
end

extraButtonOriginalParents = {}

function GetExtraButtonVisualFrame(buttonType, blizzFrame)
    if not blizzFrame then return nil end

    if buttonType == "extraActionButton" then
        return blizzFrame.button or _G["ExtraActionButton1"]
    end

    local container = blizzFrame.SpellButtonContainer
    if container then
        if container.EnumerateActive then
            for button in container:EnumerateActive() do
                if button then
                    return button
                end
            end
        end
        return container
    end

    return blizzFrame.SpellButton
end

function GetExtraButtonHolderSize(buttonType, blizzFrame, settings, scale)
    local width = Helpers.SafeToNumber(blizzFrame:GetWidth(), 64)
    local height = Helpers.SafeToNumber(blizzFrame:GetHeight(), 64)

    if settings.enabled == true and settings.hideArtwork then
        local visualFrame = GetExtraButtonVisualFrame(buttonType, blizzFrame)
        if visualFrame then
            local visualWidth = visualFrame.GetWidth and Helpers.SafeToNumber(visualFrame:GetWidth(), width) or width
            local visualHeight = visualFrame.GetHeight and Helpers.SafeToNumber(visualFrame:GetHeight(), height) or height
            if visualWidth > 0 then width = visualWidth end
            if visualHeight > 0 then height = visualHeight end
        end
    end

    scale = tonumber(scale) or 1
    if scale <= 0 then scale = 1 end

    return math.max(width * scale, 64), math.max(height * scale, 64)
end

local function GetExtraActionContainerAnchorOffset(container, bar, scale, offsetX, offsetY)
    scale = tonumber(scale) or 1
    if scale <= 0 then scale = 1 end

    offsetX = tonumber(offsetX) or 0
    offsetY = tonumber(offsetY) or 0
    if not container or not bar then return offsetX, offsetY end

    local barWidth = Helpers.SafeToNumber(bar:GetWidth(), 0)
    local barHeight = Helpers.SafeToNumber(bar:GetHeight(), 0)
    if barWidth <= 0 or barHeight <= 0 then return offsetX, offsetY end

    local childLayoutWidth = barWidth
    local childLayoutHeight = barHeight
    if container.respectChildScale then
        childLayoutWidth = childLayoutWidth * scale
        childLayoutHeight = childLayoutHeight * scale
    end

    local layoutWidth = Helpers.SafeToNumber(container.fixedWidth, 0)
    if layoutWidth <= 0 then layoutWidth = childLayoutWidth end
    local minimumWidth = Helpers.SafeToNumber(container.minimumWidth, 0)
    local maximumWidth = Helpers.SafeToNumber(container.maximumWidth, 0)
    if minimumWidth > 0 then layoutWidth = math.max(layoutWidth, minimumWidth) end
    if maximumWidth > 0 then layoutWidth = math.min(layoutWidth, maximumWidth) end

    local layoutHeight = Helpers.SafeToNumber(container.fixedHeight, 0)
    if layoutHeight <= 0 then layoutHeight = childLayoutHeight end
    local minimumHeight = Helpers.SafeToNumber(container.minimumHeight, 0)
    local maximumHeight = Helpers.SafeToNumber(container.maximumHeight, 0)
    if minimumHeight > 0 then layoutHeight = math.max(layoutHeight, minimumHeight) end
    if maximumHeight > 0 then layoutHeight = math.min(layoutHeight, maximumHeight) end

    local visualWidth = barWidth * scale
    local visualHeight = barHeight * scale
    return offsetX + (layoutWidth - visualWidth) / 2,
        offsetY + (visualHeight - layoutHeight) / 2
end

-- drags it back.  We never call ExtraAbilityContainer:RemoveFrame -- it does
function ApplyExtraActionContainerAnchor(holder, offsetX, offsetY, scale)
    local container = ExtraAbilityContainer
    if not container or not holder then return end

    if not extraButtonOriginalParents["extraActionButton"] then
        extraButtonOriginalParents["extraActionButton"] = container:GetParent()
    end

    container.ignoreInLayout = true
    container.ignoreFramePositionManager = true
    ns.SafeCallMethodIfPresent("best-effort-style", container, "SetIsLayoutFrame", false)

    -- takeover is already registered in the manager's showingFrames, and
    -- ourselves: an insecure write into the manager's showingFrames table

    extraBtnState.containerOwned = true

    extraBtnState.hookingSetParent = true
    container:SetParent(holder)
    extraBtnState.hookingSetParent = false

    local anchorX, anchorY = GetExtraActionContainerAnchorOffset(
        container, ExtraActionBarFrame, scale, offsetX, offsetY)

    extraBtnState.hookingSetPoint = true
    if container.ClearAllPointsBase and container.SetPointBase then
        container:ClearAllPointsBase()
        container:SetPointBase("CENTER", holder, "CENTER", anchorX, anchorY)
    else
        container:ClearAllPoints()
        container:SetPoint("CENTER", holder, "CENTER", anchorX, anchorY)
    end
    extraBtnState.hookingSetPoint = false
end

function NeutralizeExtraAbilityContainer()
    local container = ExtraAbilityContainer
    if not container or extraBtnState.containerNeutralized then return end
    if InCombatLockdown() then return end
    extraBtnState.containerNeutralized = true

    container:SetScript("OnShow", nil)
    container:SetScript("OnHide", nil)

    local sel = container.Selection
    if sel then
        sel:SetAlpha(0)
        if sel.EnableMouse then sel:EnableMouse(false) end
        if sel.SetMouseClickEnabled then sel:SetMouseClickEnabled(false) end
        if sel.SetMouseMotionEnabled then sel:SetMouseMotionEnabled(false) end
        if not extraBtnState.containerSelectionHooked then
            extraBtnState.containerSelectionHooked = true
            hooksecurefunc(sel, "Show", function(self)
                self:SetAlpha(0)
                if self.EnableMouse and not InCombatLockdown() then
                    self:EnableMouse(false)
                    if self.SetMouseClickEnabled then self:SetMouseClickEnabled(false) end
                    if self.SetMouseMotionEnabled then self:SetMouseMotionEnabled(false) end
                end
            end)
        end
    end

    if ExtraActionBarFrame then
        if ExtraActionBarFrame:IsMouseEnabled() then
            ExtraActionBarFrame:EnableMouse(false)
        end
        if ExtraActionBarFrame.SetMouseClickEnabled then ExtraActionBarFrame:SetMouseClickEnabled(false) end
        if ExtraActionBarFrame.SetMouseMotionEnabled then ExtraActionBarFrame:SetMouseMotionEnabled(false) end
    end

    if container.AddFrame and not extraBtnState.containerAddFrameHooked then
        extraBtnState.containerAddFrameHooked = true
        hooksecurefunc(container, "AddFrame", function(_, frame)
            if frame and frame.EnableMouse and not InCombatLockdown() then
                frame:EnableMouse(true)
            end
        end)
    end
end

-- DELIBERATE SAFETY EXCEPTION to the dual-mover invariant: when this
local function ZoneFrameCombatMutable(frame, holder)
    if not InCombatLockdown() then return true end
    if Helpers.FrameMutationRestricted(frame) then return false end
    if holder and Helpers.FrameMutationRestricted(holder) then return false end
    return true
end

local function IsExtraButtonEnabled(buttonType)
    local settings = GetExtraButtonDB(buttonType)
    return (settings and settings.enabled) == true
end

-- SESSION-LONG OWNERSHIP: either enabled surface acquires the shared
function ShouldOwnExtraAbilityContainer()
    return extraBtnState.containerOwned
        or extraBtnState.zoneOwned
        or IsExtraButtonEnabled("extraActionButton")
        or IsExtraButtonEnabled("zoneAbility")
end

-- DUAL-MOVER INVARIANT (user requirement): extra action and zone ability
-- each keep their OWN mover; outside the deliberate safety exception above
function IsZoneAbilityManaged()
    return extraBtnState.zoneOwned or ShouldOwnExtraAbilityContainer()
end

local function EvictZoneAbilityFrame(scale, offsetX, offsetY)
    local blizzFrame = ZoneAbilityFrame
    local holder = extraBtnState.zoneAbilityHolder
    if not blizzFrame or not holder then return nil, nil end
    if not ZoneFrameCombatMutable(blizzFrame, holder) then
        ActionBarsOwned.pendingExtraButtonRefresh = true
        return nil, nil
    end
    blizzFrame:SetScale(scale)
    blizzFrame.ignoreInLayout = true
    blizzFrame.ignoreFramePositionManager = true
    extraBtnState.hookingSetParent = true
    blizzFrame:SetParent(holder)
    extraBtnState.hookingSetParent = false
    extraBtnState.hookingSetPoint = true
    blizzFrame:ClearAllPoints()
    blizzFrame:SetPoint("CENTER", holder, "CENTER", offsetX, offsetY)
    extraBtnState.hookingSetPoint = false
    extraBtnState.zoneOwned = true
    local container = ExtraAbilityContainer
    if container then
        if not InCombatLockdown() then
            ns.SafeCallMethodIfPresent("defer-ooc", container, "MarkDirty")
        else
            ActionBarsOwned.pendingExtraButtonRefresh = true
        end
    end
    return blizzFrame, holder
end

function ApplyExtraButtonSettings(buttonType)
    local settings = GetExtraButtonDB(buttonType)
    local enabled = (settings and settings.enabled) == true
    local effectiveSettings = settings or {}
    local scale = enabled and (effectiveSettings.scale or 1.0) or 1.0
    local offsetX = enabled and (effectiveSettings.offsetX or 0) or 0
    local offsetY = enabled and (effectiveSettings.offsetY or 0) or 0

    local blizzFrame
    local holder

    if buttonType == "extraActionButton" then
        if not ShouldOwnExtraAbilityContainer() then return end
        -- COMBAT GATE (load-bearing).  ExtraActionBarFrame owns the secure
        if InCombatLockdown() then
            ActionBarsOwned.pendingExtraButtonRefresh = true
            return
        end
        blizzFrame = ExtraActionBarFrame
        holder = extraBtnState.extraActionHolder
        if not blizzFrame or not holder then return end
        blizzFrame:SetScale(scale)
        ApplyExtraActionContainerAnchor(holder, offsetX, offsetY, scale)
        NeutralizeExtraAbilityContainer()
    else
        if not IsZoneAbilityManaged() then return end
        blizzFrame, holder = EvictZoneAbilityFrame(scale, offsetX, offsetY)
        if not blizzFrame or not holder then return end
    end

    local holderWidth, holderHeight = GetExtraButtonHolderSize(
        buttonType, blizzFrame, effectiveSettings, scale)
    holder:SetSize(holderWidth, holderHeight)

    if enabled and effectiveSettings.hideArtwork then
        if buttonType == "extraActionButton" and blizzFrame.button and blizzFrame.button.style then
            blizzFrame.button.style:SetAlpha(0)
        end
        if buttonType == "zoneAbility" and blizzFrame.Style then
            blizzFrame.Style:SetAlpha(0)
        end
    else
        if buttonType == "extraActionButton" and blizzFrame.button and blizzFrame.button.style then
            blizzFrame.button.style:SetAlpha(1)
        end
        if buttonType == "zoneAbility" and blizzFrame.Style then
            blizzFrame.Style:SetAlpha(1)
        end
    end

    if not enabled or not effectiveSettings.fadeEnabled then
        blizzFrame:SetAlpha(1)
    end

    if not enabled and type(SetupBarMouseover) == "function" then
        SetupBarMouseover(buttonType)
    end
end

pendingExtraButtonReanchor = {}

function QueueExtraButtonReanchor(buttonType)
    if pendingExtraButtonReanchor[buttonType] then return end
    pendingExtraButtonReanchor[buttonType] = true

    C_Timer.After(0, function()
        pendingExtraButtonReanchor[buttonType] = false

        local active
        if buttonType == "zoneAbility" then
            active = IsZoneAbilityManaged()
        else
            active = ShouldOwnExtraAbilityContainer()
        end
        if active then
            ApplyExtraButtonSettings(buttonType)
            ApplyExtraButtonFrameAnchor(buttonType)
        end
    end)
end

function QueueManagedExtraButtonReanchor(buttonType)
    local holder = buttonType == "extraActionButton"
        and extraBtnState.extraActionHolder
        or extraBtnState.zoneAbilityHolder
    local active
    if buttonType == "zoneAbility" then
        active = IsZoneAbilityManaged()
    else
        active = ShouldOwnExtraAbilityContainer()
    end
    if holder and active then
        QueueExtraButtonReanchor(buttonType)
    end
end

function HookExtraButtonPositioning()
    if ExtraActionBarFrame and not extraBtnState.extraActionShowHooked then
        extraBtnState.extraActionShowHooked = true
        hooksecurefunc(ExtraActionBarFrame, "Show", function()
            QueueExtraButtonReanchor("extraActionButton")
        end)
    end

    if ExtraAbilityContainer and not extraBtnState.extraAbilityContainerSetPointHooked then
        extraBtnState.extraAbilityContainerSetPointHooked = true
        hooksecurefunc(ExtraAbilityContainer, "SetPoint", function()
            if extraBtnState.hookingSetPoint then return end
            C_Timer.After(0, function()
                if extraBtnState.hookingSetPoint then return end
                QueueManagedExtraButtonReanchor("extraActionButton")
            end)
        end)
    end

    if ExtraAbilityContainer and not extraBtnState.extraAbilityContainerSetParentHooked then
        extraBtnState.extraAbilityContainerSetParentHooked = true
        hooksecurefunc(ExtraAbilityContainer, "SetParent", function()
            if extraBtnState.hookingSetParent then return end
            C_Timer.After(0, function()
                if extraBtnState.hookingSetParent then return end
                QueueManagedExtraButtonReanchor("extraActionButton")
            end)
        end)
    end

    if ExtraAbilityContainer and not extraBtnState.extraAbilityContainerShowHooked then
        extraBtnState.extraAbilityContainerShowHooked = true
        hooksecurefunc(ExtraAbilityContainer, "Show", function()
            QueueManagedExtraButtonReanchor("extraActionButton")
        end)
    end

    if ExtraAbilityContainer and ExtraAbilityContainer.ApplySystemAnchor
        and not extraBtnState.extraAbilityContainerAnchorHooked then
        extraBtnState.extraAbilityContainerAnchorHooked = true
        hooksecurefunc(ExtraAbilityContainer, "ApplySystemAnchor", function()
            QueueManagedExtraButtonReanchor("extraActionButton")
        end)
    end

    -- legal: the frame has no secure descendant.  The C_Timer.After(0) hop
    local function HookSetParentForType(blizzFrame, buttonType, holder)
        if not blizzFrame then return end
        hooksecurefunc(blizzFrame, "SetParent", function(self, newParent)
            if extraBtnState.hookingSetParent then return end
            if newParent == holder then return end
            C_Timer.After(0, function()
                if extraBtnState.hookingSetParent then return end
                if holder and IsZoneAbilityManaged() then
                    if not ZoneFrameCombatMutable(blizzFrame, holder) then
                        ActionBarsOwned.pendingExtraButtonRefresh = true
                        return
                    end
                    extraBtnState.hookingSetParent = true
                    blizzFrame:SetParent(holder)
                    extraBtnState.hookingSetParent = false
                    QueueExtraButtonReanchor(buttonType)
                end
            end)
        end)
    end

    if ZoneAbilityFrame and not extraBtnState.zoneAbilitySetPointHooked then
        extraBtnState.zoneAbilitySetPointHooked = true
        hooksecurefunc(ZoneAbilityFrame, "SetPoint", function(self)
            if extraBtnState.hookingSetPoint then return end
            C_Timer.After(0, function()
                if extraBtnState.hookingSetPoint then return end
                QueueManagedExtraButtonReanchor("zoneAbility")
            end)
        end)
    end
    if ZoneAbilityFrame and not extraBtnState.zoneAbilitySetParentHooked then
        extraBtnState.zoneAbilitySetParentHooked = true
        HookSetParentForType(ZoneAbilityFrame, "zoneAbility", extraBtnState.zoneAbilityHolder)
    end
    if ZoneAbilityFrame and not extraBtnState.zoneAbilityShowHooked then
        extraBtnState.zoneAbilityShowHooked = true
        hooksecurefunc(ZoneAbilityFrame, "Show", function()
            QueueExtraButtonReanchor("zoneAbility")
        end)
    end

end

function ShowExtraButtonMovers()
    extraBtnState.moversVisible = true
    if extraBtnState.extraActionMover then extraBtnState.extraActionMover:Show() end
    if extraBtnState.zoneAbilityMover then extraBtnState.zoneAbilityMover:Show() end
end

function HideExtraButtonMovers()
    extraBtnState.moversVisible = false
    if extraBtnState.extraActionMover then extraBtnState.extraActionMover:Hide() end
    if extraBtnState.zoneAbilityMover then extraBtnState.zoneAbilityMover:Hide() end
end

function ToggleExtraButtonMovers()
    if extraBtnState.moversVisible then
        HideExtraButtonMovers()
    else
        ShowExtraButtonMovers()
    end
end

-- Unified special-button presentation.
-- Extra Action and Zone Ability are TomoMod-owned presentation frames, so they
-- can safely use the exact same SkinButton() path as the normal TUI action
-- buttons.  Keep all legacy diagnostic artwork hidden; the trusted Blizzard
-- click/action frames underneath remain completely separate from this cosmetic
-- layer.
local function ApplyOwnedSpecialButtonActionSkin(proxy)
    if not proxy then return end

    -- Remove legacy placeholder artwork before applying the normal action-button skin.
    -- Hide it explicitly before SkinButton() creates/updates the normal TUI
    -- backdrop, border and gloss regions.
    if proxy.LegacyBackdrop then proxy.LegacyBackdrop:Hide() end
    if proxy.LegacyBorder then proxy.LegacyBorder:Hide() end
    if proxy.LegacyGloss then proxy.LegacyGloss:Hide() end
    if proxy.Backdrop then proxy.Backdrop:Hide() end
    if proxy.Border then proxy.Border:Hide() end
    if proxy.Gloss then proxy.Gloss:Hide() end

    local settings = GetEffectiveSettings and GetEffectiveSettings("bar1") or nil
    if settings and SkinButton then
        SkinButton(proxy, settings)
        return
    end

    -- Extremely early-load fallback: keep a clean icon if ActionBar skinning has
    -- not been initialised yet. The next normal refresh will apply SkinButton().
    if proxy.Icon then
        proxy.Icon:ClearAllPoints()
        proxy.Icon:SetAllPoints(proxy)
        proxy.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

-- Extra Action secure proxy:
-- Restore Extra Action without ever mutating Blizzard's native action-bar graph.
-- The TUI button is a standalone SecureActionButtonTemplate configured as a
-- secure click proxy to ExtraActionButton1.  Blizzard keeps complete ownership
-- of ExtraActionBarFrame / ExtraActionButton1 and all of their scripts, events,
-- cooldowns, attributes, parentage, visibility and artwork.
local function GetExtraActionProxySpellID(native)
    if not native then return nil end

    -- ExtraActionButton1 is still Blizzard-owned and maintains its resolved
    -- action slot internally. Read only that public runtime field; never call
    -- UpdateAction(), CalculateAction() or touch the native cooldown widget.
    local action = native.action
    if action == nil or Helpers.IsSecretValue(action) then
        return nil
    end

    action = Helpers.SafeToNumber(action, 0)
    if action <= 0 or type(GetActionInfo) ~= "function" then
        return nil
    end

    local ok, actionType, id, subType = pcall(GetActionInfo, action)
    if not ok or Helpers.IsSecretValue(actionType) or Helpers.IsSecretValue(id)
        or Helpers.IsSecretValue(subType)
    then
        return nil
    end

    if actionType == "spell" then
        id = Helpers.SafeToNumber(id, 0)
        return id > 0 and id or nil
    end

    -- Defensive fallback for an action that resolves through a macro-backed
    -- spell. This should be uncommon for Extra Action but costs nothing.
    if actionType == "macro" and subType == "spell" then
        id = Helpers.SafeToNumber(id, 0)
        return id > 0 and id or nil
    end

    return nil
end

local function RefreshExtraActionProxyCooldown(proxy, spellID)
    if not proxy then return end

    local cooldown = proxy.Cooldown
    local chargeCooldown = proxy.ChargeCooldown

    if not spellID or not C_Spell then
        if cooldown then cooldown:Clear() end
        if chargeCooldown then chargeCooldown:Clear() end
        return
    end

    -- Use the same secret-safe DurationObject path as Zone Ability.
    -- in game for Zone Ability. Never unpack startTime/duration scalars from
    -- Blizzard's native ExtraActionButton1 cooldown.
    -- ignoreGCD=false is intentional: the proxy must show the global cooldown.
    if cooldown and type(C_Spell.GetSpellCooldownDuration) == "function" then
        local ok, duration = ns.SafeCall(
            "best-effort-style", C_Spell.GetSpellCooldownDuration, spellID, false)
        if ok and duration then
            cooldown:SetCooldownFromDurationObject(duration)
        else
            cooldown:Clear()
        end
    elseif cooldown then
        cooldown:Clear()
    end

    if chargeCooldown and type(C_Spell.GetSpellChargeDuration) == "function" then
        local ok, duration = ns.SafeCall(
            "best-effort-style", C_Spell.GetSpellChargeDuration, spellID)
        if ok and duration then
            chargeCooldown:SetCooldownFromDurationObject(duration)
        else
            chargeCooldown:Clear()
        end
    elseif chargeCooldown then
        chargeCooldown:Clear()
    end
end

local function RefreshExtraActionProxyVisual()
    local proxy = extraBtnState.extraActionProxy
    if not proxy then return end

    local native = _G.ExtraActionButton1
    local texture
    if native then
        local icon = native.icon or native.Icon
        if icon and icon.GetTexture then
            local ok, value = pcall(icon.GetTexture, icon)
            if ok and not Helpers.IsSecretValue(value) then
                texture = value
            end
        end
    end

    if proxy.Icon then
        proxy.Icon:SetTexture(texture or 134400) -- INV_Misc_QuestionMark fallback
    end

    ApplyOwnedSpecialButtonActionSkin(proxy)

    -- SkinButton() may normalize the cooldown anchor; keep both owned layers
    -- pinned to the full special-action button afterwards.
    if proxy.Cooldown then
        proxy.Cooldown:ClearAllPoints()
        proxy.Cooldown:SetAllPoints(proxy)
    end
    if proxy.ChargeCooldown then
        proxy.ChargeCooldown:ClearAllPoints()
        proxy.ChargeCooldown:SetAllPoints(proxy)
    end

    local spellID = GetExtraActionProxySpellID(native)
    proxy._tomomodExtraActionSpellID = spellID
    RefreshExtraActionProxyCooldown(proxy, spellID)
end

local function EnsureExtraActionProxy()
    if extraBtnState.extraActionProxy then
        return extraBtnState.extraActionProxy
    end
    if InCombatLockdown() then
        ActionBarsOwned.pendingExtraButtonInit = true
        return nil
    end

    local native = _G.ExtraActionButton1
    if not native then
        ActionBarsOwned.pendingExtraButtonInit = true
        return nil
    end

    if not extraBtnState.extraActionHolder then
        local holder, mover = CreateExtraButtonHolder("extraActionButton", "Extra Action")
        extraBtnState.extraActionHolder = holder
        extraBtnState.extraActionMover = mover
    end

    local holder = extraBtnState.extraActionHolder
    if not holder then return nil end

    local proxy = CreateFrame("Button", "TUI_ExtraActionProxyButton", holder, "SecureActionButtonTemplate")
    proxy:SetAllPoints(holder)
    proxy:RegisterForClicks("AnyUp", "AnyDown")
    proxy:SetAttribute("type", "click")
    proxy:SetAttribute("clickbutton", native)

    local icon = proxy:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", -3, 3)
    proxy.Icon = icon

    local bg = proxy:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(proxy)
    bg:SetColorTexture(0.03, 0.03, 0.03, 0.92)
    proxy.LegacyBackdrop = bg

    -- Midnight 12.1:
    -- Extra Action gets its own TomoMod cooldown layers just like Zone Ability.
    -- They are fed only with C_Spell DurationObjects and never mirror the
    -- native ExtraActionButton1 cooldown scalars, preserving native ownership.
    local cooldown = CreateFrame("Cooldown", nil, proxy, "CooldownFrameTemplate")
    cooldown:SetAllPoints(proxy)
    cooldown:SetDrawBling(false)
    cooldown:SetDrawEdge(false)
    cooldown:EnableMouse(false)
    if cooldown.SetMouseClickEnabled then cooldown:SetMouseClickEnabled(false) end
    if cooldown.SetMouseMotionEnabled then cooldown:SetMouseMotionEnabled(false) end
    proxy.Cooldown = cooldown

    local chargeCooldown = CreateFrame("Cooldown", nil, proxy, "CooldownFrameTemplate")
    chargeCooldown:SetAllPoints(proxy)
    chargeCooldown:SetDrawSwipe(false)
    chargeCooldown:SetHideCountdownNumbers(true)
    chargeCooldown:EnableMouse(false)
    if chargeCooldown.SetMouseClickEnabled then chargeCooldown:SetMouseClickEnabled(false) end
    if chargeCooldown.SetMouseMotionEnabled then chargeCooldown:SetMouseMotionEnabled(false) end
    proxy.ChargeCooldown = chargeCooldown

    local border = CreateFrame("Frame", nil, proxy, "BackdropTemplate")
    border:SetAllPoints(proxy)
    ns.SkinBase.ApplyPixelBackdrop(border, 2, true, false,
        {0.047, 0.824, 0.624, 1}, {0, 0, 0, 0})
    border:EnableMouse(false)
    proxy.LegacyBorder = border
    proxy.Border = border

    -- Match the normal action-button interaction artwork as well. SkinButton()
    -- will normalize these textures through StripBlizzardArtwork().
    local highlight = proxy:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture(TEXTURES.highlight)
    highlight:SetAllPoints(proxy)
    proxy:SetHighlightTexture(highlight)

    local pushed = proxy:CreateTexture(nil, "ARTWORK")
    pushed:SetTexture(TEXTURES.pushed)
    pushed:SetAllPoints(proxy)
    proxy:SetPushedTexture(pushed)

    proxy:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Extra Action")
        GameTooltip:Show()
    end)
    proxy:SetScript("OnLeave", function() GameTooltip:Hide() end)
    proxy:SetScript("PostClick", function()
        -- The native click happens first. Refresh on the next frame and once
        -- more after the spell event has propagated so the GCD appears
        -- immediately even for encounter/quest Extra Actions.
        C_Timer.After(0, RefreshExtraActionProxyVisual)
        C_Timer.After(0.05, RefreshExtraActionProxyVisual)
    end)

    extraBtnState.extraActionProxy = proxy

    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("UPDATE_EXTRA_ACTIONBAR")
    events:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    events:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    events:RegisterEvent("SPELL_UPDATE_CHARGES")
    events:RegisterEvent("SPELL_UPDATE_ICON")
    events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    events:SetScript("OnEvent", function()
        RefreshExtraActionProxyVisual()
    end)
    extraBtnState.extraActionProxyEvents = events

    RefreshExtraActionProxyVisual()
    return proxy
end

-- Native Extra Action visual/input suppression:
-- Alpha suppression hides the native Extra Action while mouse-channel suppression
-- removes its otherwise invisible hitbox while the TUI proxy
-- is active.  Do NOT Hide/Show, reparent, move, unregister events, alter secure
-- attributes, replace methods/scripts, touch cooldown state, or hook the native
-- button/frame.  All saved presentation/input state lives in TomoMod side data.
local function ApplyNativeExtraActionVisualSuppression(suppress)
    if InCombatLockdown() then
        ActionBarsOwned.pendingExtraButtonRefresh = true
        return
    end

    suppress = suppress == true

    local native = _G.ExtraActionButton1
    if not native or type(native.SetAlpha) ~= "function" then
        return
    end

    -- Midnight 12.1:
    -- An alpha-zero
    -- ExtraActionButton1 remains a real mouse hit target.  When Edit Mode places
    -- that invisible button over the TUI Zone Ability it steals both clicks and
    -- hover/tooltips.  Disable only the native button's mouse click/motion
    -- channels while its TUI proxy is active.  Preserve the original state in
    -- TomoMod's side table and never write addon fields onto the Blizzard frame.
    if suppress then
        if not extraBtnState.nativeExtraActionMouseState then
            local clickEnabled = true
            local motionEnabled = true
            if type(native.IsMouseClickEnabled) == "function" then
                local ok, value = pcall(native.IsMouseClickEnabled, native)
                if ok then clickEnabled = value == true end
            end
            if type(native.IsMouseMotionEnabled) == "function" then
                local ok, value = pcall(native.IsMouseMotionEnabled, native)
                if ok then motionEnabled = value == true end
            end
            extraBtnState.nativeExtraActionMouseState = {
                click = clickEnabled,
                motion = motionEnabled,
            }
        end

        native:SetAlpha(0)
        if native.SetMouseClickEnabled then native:SetMouseClickEnabled(false) end
        if native.SetMouseMotionEnabled then native:SetMouseMotionEnabled(false) end
    else
        native:SetAlpha(1)
        local saved = extraBtnState.nativeExtraActionMouseState
        if saved then
            if native.SetMouseClickEnabled then native:SetMouseClickEnabled(saved.click) end
            if native.SetMouseMotionEnabled then native:SetMouseMotionEnabled(saved.motion) end
            extraBtnState.nativeExtraActionMouseState = nil
        end
    end

    extraBtnState.nativeExtraActionAlphaSuppressed = suppress
end

local function ApplyExtraActionProxySettings()
    if InCombatLockdown() then
        ActionBarsOwned.pendingExtraButtonRefresh = true
        return
    end

    local settings = GetExtraButtonDB("extraActionButton")
    local proxy = EnsureExtraActionProxy()
    local holder = extraBtnState.extraActionHolder
    if not proxy or not holder then return end

    local enabled = settings and settings.enabled == true
    local scale = tonumber(settings and settings.scale) or 1
    if scale <= 0 then scale = 1 end

    holder:SetSize(64 * scale, 64 * scale)
    ApplyExtraButtonFrameAnchor("extraActionButton")

    if enabled then
        UnregisterStateDriver(proxy, "visibility")
        RegisterStateDriver(proxy, "visibility", "[extrabar] show; hide")
    else
        UnregisterStateDriver(proxy, "visibility")
        proxy:Hide()
    end

    -- Suppress the native Extra Action visual and its invisible mouse
    -- hitbox while the TUI proxy is enabled; no protected action state is changed.
    ApplyNativeExtraActionVisualSuppression(enabled)
    RefreshExtraActionProxyVisual()
end


-- Zone Ability presentation bridge:
-- Zone Ability follows the same native-ownership rule as Extra Action.
-- ZoneAbilityFrame and its SpellButtonContainer remain entirely Blizzard-owned.
-- TUI creates up to three standalone secure click proxies and only READS the
-- active native button references/icons.  We never reparent, move, skin, hook,
-- hide, alpha-change, change attributes on, or otherwise mutate a native zone
-- ability button/frame.
local MAX_ZONE_ABILITY_PROXIES = 3

-- Zone Ability active-state source of truth:
-- C_ZoneAbility.GetActiveAbilities() is Blizzard's source of truth. The pooled
-- SpellButtonContainer may still enumerate a button for a short time after an
-- instance/zone transition, so never let a stale native pool entry keep a TUI
-- proxy alive after the API says that spell is no longer a zone ability.
local function GetCurrentZoneAbilitySpellSet()
    local spellSet = {}
    if not C_ZoneAbility or type(C_ZoneAbility.GetActiveAbilities) ~= "function" then
        return spellSet, false
    end

    local ok, abilities = ns.SafeCall(
        "best-effort-style", C_ZoneAbility.GetActiveAbilities)
    if not ok or type(abilities) ~= "table" then
        return spellSet, false
    end

    for _, info in ipairs(abilities) do
        local spellID = info and info.spellID
        if spellID and not Helpers.IsSecretValue(spellID) then
            spellID = Helpers.SafeToNumber(spellID, 0)
            if spellID > 0 then
                spellSet[spellID] = true
            end
        end
    end
    return spellSet, true
end

local function GetNativeZoneAbilityBaseSpellID(native)
    if not native then return nil end

    local spellID
    if type(native.GetSpellID) == "function" then
        local ok, value = pcall(native.GetSpellID, native)
        if ok then spellID = value end
    end
    if not spellID then spellID = native.spellID end
    if Helpers.IsSecretValue(spellID) then return nil end

    spellID = Helpers.SafeToNumber(spellID, 0)
    return spellID > 0 and spellID or nil
end

-- Some quest Zone Abilities rely on Blizzard's exact native physical-click
-- semantics. The TomoMod frame is presentation-only; the real Blizzard button
-- remains the hardware target underneath it.
local function ConfigureZoneAbilityProxyAction(proxy, native)
    if not proxy or not native then return false end

    local baseSpellID = GetNativeZoneAbilityBaseSpellID(native)

    -- Every Zone Ability keeps Blizzard's
    -- exact native PHYSICAL mouse path. Quest abilities can use native OnClick
    -- semantics that SecureActionButtonTemplate spell/click emulation does not
    -- reproduce exactly, so the TUI frame is presentation-only and the real
    -- Blizzard button remains the hardware hit target underneath it.
    proxy:SetAttribute("clickbutton", nil)
    proxy:SetAttribute("spell", nil)
    proxy:SetAttribute("type", nil)
    proxy._tomomodZoneAbilityActionMode = "native-physical"
    proxy._tomomodZoneAbilityBaseSpellID = baseSpellID
    return true

end

local function CollectActiveZoneAbilityButtons()
    local active = {}
    local currentSpellSet, hasAuthoritativeAPI = GetCurrentZoneAbilitySpellSet()

    -- An authoritative empty list means the player has no zone ability now.
    -- Do not trust pooled native buttons that have not been released yet.
    if hasAuthoritativeAPI and not next(currentSpellSet) then
        return active
    end

    local frame = _G.ZoneAbilityFrame
    local container = frame and frame.SpellButtonContainer
    if not container or type(container.EnumerateActive) ~= "function" then
        return active
    end

    local ok = pcall(function()
        for button in container:EnumerateActive() do
            if button then
                local baseSpellID = GetNativeZoneAbilityBaseSpellID(button)
                if not hasAuthoritativeAPI
                    or (baseSpellID and currentSpellSet[baseSpellID])
                then
                    active[#active + 1] = button
                    if #active >= MAX_ZONE_ABILITY_PROXIES then break end
                end
            end
        end
    end)
    if not ok then
        wipe(active)
    end
    return active
end

local function GetNativeProxyTexture(native)
    if not native then return nil end
    local icon = native.icon or native.Icon
    if not icon or type(icon.GetTexture) ~= "function" then return nil end
    local ok, texture = pcall(icon.GetTexture, icon)
    if not ok or Helpers.IsSecretValue(texture) then return nil end
    return texture
end

-- Zone Ability live visuals:
-- Zone Ability proxy visuals now follow Blizzard's live Refresh() semantics,
-- but remain strictly read-only toward the native ZoneAbility button.  The
-- native implementation recalculates the override spell, dynamic zone icon,
-- cooldown and charges on SPELL_UPDATE_* events.  Mirror that data onto our
-- own textures/cooldowns without ever mutating the Blizzard button/frame.
local function GetNativeZoneAbilitySpellID(native)
    if not native then return nil end

    local spellID
    if type(native.GetOverrideSpellID) == "function" then
        local ok, value = pcall(native.GetOverrideSpellID, native)
        if ok then spellID = value end
    end
    if not spellID and type(native.GetSpellID) == "function" then
        local ok, value = pcall(native.GetSpellID, native)
        if ok then spellID = value end
    end
    if not spellID then
        spellID = native.spellID
    end

    if Helpers.IsSecretValue(spellID) then return nil end
    spellID = Helpers.SafeToNumber(spellID, 0)
    return spellID > 0 and spellID or nil
end

local function GetLiveZoneAbilityTexture(native, spellID)
    if spellID and C_ZoneAbility and type(C_ZoneAbility.GetZoneAbilityIcon) == "function" then
        local ok, texture = ns.SafeCall("best-effort-style", C_ZoneAbility.GetZoneAbilityIcon, spellID)
        if ok and texture and not Helpers.IsSecretValue(texture) then
            return texture
        end
    end
    return GetNativeProxyTexture(native)
end

local function RefreshZoneAbilityProxyCooldown(proxy, spellID)
    if not proxy then return end

    local cooldown = proxy.Cooldown
    local chargeCooldown = proxy.ChargeCooldown
    if not spellID or not C_Spell then
        if cooldown then cooldown:Clear() end
        if chargeCooldown then chargeCooldown:Clear() end
        return
    end

    -- Do NOT unpack SpellCooldownInfo.startTime/duration here: on Midnight those
    -- scalars can be secret. LuaDurationObject is the supported taint-safe path.
    -- ignoreGCD=false intentionally keeps the GCD swipe visible on this proxy.
    if cooldown and type(C_Spell.GetSpellCooldownDuration) == "function" then
        local ok, duration = ns.SafeCall(
            "best-effort-style", C_Spell.GetSpellCooldownDuration, spellID, false)
        if ok and duration then
            cooldown:SetCooldownFromDurationObject(duration)
        else
            cooldown:Clear()
        end
    elseif cooldown then
        cooldown:Clear()
    end

    if chargeCooldown and type(C_Spell.GetSpellChargeDuration) == "function" then
        local ok, duration = ns.SafeCall(
            "best-effort-style", C_Spell.GetSpellChargeDuration, spellID)
        if ok and duration then
            chargeCooldown:SetCooldownFromDurationObject(duration)
        else
            chargeCooldown:Clear()
        end
    elseif chargeCooldown then
        chargeCooldown:Clear()
    end
end

-- Final Zone Ability presentation.
-- The proxy is presentation-only while Blizzard's native Zone Ability button
-- remains the trusted hardware click target. Mirror TomoMod's normal ActionBar
-- icon skin onto the owned proxy without touching native artwork or scripts.
local function ApplyZoneAbilityProxyTUISkin(proxy)
    ApplyOwnedSpecialButtonActionSkin(proxy)

    -- Cooldown layers are owned by TomoMod and remain pinned to the full button
    -- after SkinButton() has applied the same icon crop/border/gloss as bar1.
    if proxy and proxy.Cooldown then
        proxy.Cooldown:ClearAllPoints()
        proxy.Cooldown:SetAllPoints(proxy)
    end
    if proxy and proxy.ChargeCooldown then
        proxy.ChargeCooldown:ClearAllPoints()
        proxy.ChargeCooldown:SetAllPoints(proxy)
    end
end

local function RefreshZoneAbilityProxyVisual(index)
    local proxy = extraBtnState.zoneAbilityProxies[index]
    if not proxy then return end

    local native = extraBtnState.zoneAbilityNativeButtons[index]
    ApplyZoneAbilityProxyTUISkin(proxy)
    local spellID = GetNativeZoneAbilitySpellID(native)
    proxy._tomomodZoneAbilitySpellID = spellID

    if proxy.Icon then
        proxy.Icon:SetTexture(GetLiveZoneAbilityTexture(native, spellID) or 134400)
    end

    -- Count is presentation-only; mirror the already-rendered Blizzard value
    -- when it is readable. Never inspect secret charge/cast-count scalars here.
    if proxy.Count then
        local text = ""
        local nativeCount = native and native.Count
        if nativeCount and type(nativeCount.GetText) == "function" then
            local ok, value = pcall(nativeCount.GetText, nativeCount)
            if ok and value ~= nil and not Helpers.IsSecretValue(value) then
                text = value
            end
        end
        proxy.Count:SetText(text)
    end

    RefreshZoneAbilityProxyCooldown(proxy, spellID)
end

local function RefreshAllZoneAbilityProxyVisuals()
    for i = 1, MAX_ZONE_ABILITY_PROXIES do
        local proxy = extraBtnState.zoneAbilityProxies[i]
        if proxy and proxy:IsShown() then
            RefreshZoneAbilityProxyVisual(i)
        end
    end
end

local function QueueZoneAbilityProxyVisualRefresh(index)
    -- The native OnClick can toggle an override/icon immediately, while the
    -- corresponding spell events may arrive a frame later. Refresh at both the
    -- next frame and shortly after so stateful follower/lead buttons keep up.
    C_Timer.After(0, function() RefreshZoneAbilityProxyVisual(index) end)
    C_Timer.After(0.05, function() RefreshZoneAbilityProxyVisual(index) end)
end

local function SetZoneAbilityProxyMouseEnabled(proxy, enabled)
    if not proxy then return end
    enabled = enabled == true
    proxy:EnableMouse(enabled)
    if proxy.SetMouseClickEnabled then proxy:SetMouseClickEnabled(enabled) end
    if proxy.SetMouseMotionEnabled then proxy:SetMouseMotionEnabled(enabled) end
end

local function CreateZoneAbilityProxy(index, holder)
    local proxy = CreateFrame("Button", "TUI_ZoneAbilityProxyButton" .. index,
        holder, "SecureActionButtonTemplate")

    -- Physical-mouse bridge:
    -- WoW 12.x exposes the split mouse channels through SetMouseClickEnabled()
    -- and SetMouseMotionEnabled(). Older probing of non-existent
    -- EnableMouseClicks/EnableMouseMotion methods, so the owned secure proxy was
    -- not explicitly enabling those channels. Keep EnableMouse(true) for legacy
    -- compatibility, then explicitly enable both modern channels. Physical secure
    -- action buttons execute on mouse-up in Blizzard's current SecureTemplates,
    -- so register the two real mouse buttons on Up only.
    proxy:EnableMouse(true)
    if proxy.SetMouseClickEnabled then proxy:SetMouseClickEnabled(true) end
    if proxy.SetMouseMotionEnabled then proxy:SetMouseMotionEnabled(true) end
    if proxy.SetPropagateMouseClicks then proxy:SetPropagateMouseClicks(false) end
    if proxy.SetPropagateMouseMotion then proxy:SetPropagateMouseMotion(false) end
    proxy:SetFrameStrata("HIGH")
    proxy:SetFrameLevel(math.max((holder and holder:GetFrameLevel() or 0) + 20, 20))
    proxy:SetHitRectInsets(-2, -2, -2, -2)
    proxy:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    proxy:Hide()

    local icon = proxy:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(proxy)
    proxy.Icon = icon

    local bg = proxy:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints(proxy)
    bg:SetColorTexture(0, 0, 0, 1)
    proxy.Backdrop = bg
    proxy.LegacyBackdrop = bg

    -- Owned cooldown layers: never mirror secret scalar start/duration values
    -- from Blizzard. They are driven by LuaDurationObject in the live refresh.
    local cooldown = CreateFrame("Cooldown", nil, proxy, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetDrawBling(false)
    cooldown:SetDrawEdge(false)
    cooldown:EnableMouse(false)
    if cooldown.SetMouseClickEnabled then cooldown:SetMouseClickEnabled(false) end
    if cooldown.SetMouseMotionEnabled then cooldown:SetMouseMotionEnabled(false) end
    proxy.Cooldown = cooldown

    local chargeCooldown = CreateFrame("Cooldown", nil, proxy, "CooldownFrameTemplate")
    chargeCooldown:SetAllPoints(icon)
    chargeCooldown:SetDrawSwipe(false)
    chargeCooldown:SetHideCountdownNumbers(true)
    chargeCooldown:EnableMouse(false)
    if chargeCooldown.SetMouseClickEnabled then chargeCooldown:SetMouseClickEnabled(false) end
    if chargeCooldown.SetMouseMotionEnabled then chargeCooldown:SetMouseMotionEnabled(false) end
    proxy.ChargeCooldown = chargeCooldown

    local count = proxy:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    count:SetPoint("BOTTOMRIGHT", proxy, "BOTTOMRIGHT", -4, 4)
    count:SetText("")
    proxy.Count = count

    -- Use the same Normal/Gloss artwork and icon
    -- crop as TomoMod action buttons instead of the temporary teal diagnostic box.
    local border = proxy:CreateTexture(nil, "OVERLAY", nil, 1)
    border:SetAllPoints(proxy)
    border:SetTexture(TEXTURES.normal)
    border:SetVertexColor(0, 0, 0, 1)
    proxy.Border = border
    proxy.LegacyBorder = border

    local gloss = proxy:CreateTexture(nil, "OVERLAY", nil, 2)
    gloss:SetAllPoints(proxy)
    gloss:SetTexture(TEXTURES.gloss)
    gloss:SetBlendMode("ADD")
    proxy.Gloss = gloss
    proxy.LegacyGloss = gloss

    proxy:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Zone Ability" .. (index > 1 and (" " .. index) or ""))
        GameTooltip:Show()
    end)
    proxy:SetScript("OnLeave", function() GameTooltip:Hide() end)
    proxy:SetScript("PostClick", function()
        QueueZoneAbilityProxyVisualRefresh(index)
    end)

    return proxy
end

-- ZoneAbilityFrameUpdater itself cleans on the next frame. During instance
-- transitions our zone/loading event can therefore arrive before its pooled
-- button container has caught up. Debounce a few out-of-combat structural
-- retries so new abilities can bind after Blizzard refreshes, while stale ones
-- disappear immediately via C_ZoneAbility above.
local function QueueZoneAbilityStructuralResync()
    extraBtnState.zoneAbilityResyncGeneration =
        (extraBtnState.zoneAbilityResyncGeneration or 0) + 1
    local generation = extraBtnState.zoneAbilityResyncGeneration

    for _, delay in ipairs({ 0, 0.10, 0.50 }) do
        C_Timer.After(delay, function()
            if generation ~= extraBtnState.zoneAbilityResyncGeneration then
                return
            end
            if InCombatLockdown() then
                ActionBarsOwned.pendingExtraButtonRefresh = true
                return
            end
            if RefreshExtraButtons then RefreshExtraButtons() end
        end)
    end
end

local function EnsureZoneAbilityProxies()
    if InCombatLockdown() then
        ActionBarsOwned.pendingExtraButtonInit = true
        return nil, nil
    end

    if not extraBtnState.zoneAbilityHolder then
        local holder, mover = CreateExtraButtonHolder("zoneAbility", "Zone Ability")
        extraBtnState.zoneAbilityHolder = holder
        extraBtnState.zoneAbilityMover = mover
    end

    local holder = extraBtnState.zoneAbilityHolder
    if not holder then return nil, nil end

    -- Keep the owned hit surface above the still-live, alpha-zero Blizzard
    -- ZoneAbilityFrame.  This changes only TomoMod-owned frames.
    holder:SetFrameStrata("HIGH")

    for i = 1, MAX_ZONE_ABILITY_PROXIES do
        if not extraBtnState.zoneAbilityProxies[i] then
            extraBtnState.zoneAbilityProxies[i] = CreateZoneAbilityProxy(i, holder)
        end
    end

    if not extraBtnState.zoneAbilityProxyEvents then
        local events = CreateFrame("Frame")
        events:RegisterEvent("PLAYER_ENTERING_WORLD")
        events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        events:RegisterEvent("ZONE_CHANGED")
        events:RegisterEvent("ZONE_CHANGED_INDOORS")
        events:RegisterEvent("SPELLS_CHANGED")
        events:RegisterEvent("QUEST_LOG_UPDATE")
        events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")

        -- Same live presentation triggers used by Blizzard's own zone button.
        -- These only mutate TUI-owned textures/cooldowns and are combat-safe.
        events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        events:RegisterEvent("SPELL_UPDATE_USABLE")
        events:RegisterEvent("SPELL_UPDATE_CHARGES")
        events:RegisterEvent("SPELL_UPDATE_ICON")
        events:RegisterUnitEvent("UNIT_AURA", "player")
        events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        events:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
        events:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")

        local visualOnlyEvents = {
            SPELL_UPDATE_COOLDOWN = true,
            SPELL_UPDATE_USABLE = true,
            SPELL_UPDATE_CHARGES = true,
            SPELL_UPDATE_ICON = true,
            UNIT_SPELLCAST_SUCCEEDED = true,
        }
        local transitionEvents = {
            PLAYER_ENTERING_WORLD = true,
            ZONE_CHANGED_NEW_AREA = true,
            ZONE_CHANGED = true,
            ZONE_CHANGED_INDOORS = true,
        }

        events:SetScript("OnEvent", function(_, event)
            -- Always allow the read-only/live visual path, including in combat.
            RefreshAllZoneAbilityProxyVisuals()

            if visualOnlyEvents[event] then
                return
            end

            -- Structural changes may alter which native button each secure click
            -- proxy targets. Those attributes remain deferred during combat.
            if InCombatLockdown() then
                ActionBarsOwned.pendingExtraButtonRefresh = true
                return
            end
            if RefreshExtraButtons then RefreshExtraButtons() end

            -- Loading/zone events can precede Blizzard's deferred container clean.
            -- Retry after it has had a chance to SetContents()/release pooled buttons.
            if transitionEvents[event] then
                QueueZoneAbilityStructuralResync()
            end
        end)
        extraBtnState.zoneAbilityProxyEvents = events
    end

    return extraBtnState.zoneAbilityProxies, holder
end

-- Native Zone Ability visual suppression:
-- Native Zone Ability visual suppression uses alpha-only
-- suppression for ExtraActionButton1 without reintroducing action-bar taint.
-- Apply the same presentation-only rule to the Zone Ability parent frame.
-- Do NOT Hide/Show, reparent, move, unregister events, alter attributes, hook
-- scripts, skin, or touch native cooldown/action state. Alpha and, as of
-- Mouse hit channels are the only native presentation/input mutations.
-- Midnight 12.1:
-- Alpha-zero native Zone Ability buttons remain real mouse hit targets.  While
-- their TUI proxies are enabled, disable only the native buttons' mouse click
-- and motion channels so an invisible pooled button cannot consume the hardware
-- click before the owned SecureActionButtonTemplate sees it.  Do not touch any
-- native scripts, events, secure attributes, parentage, points or cooldowns.
-- Original mouse-channel states are kept entirely in TomoMod and restored when
-- the proxy feature is disabled. This is performed only outside combat.
local function SetNativeZoneAbilityMouseSuppressed(native, suppress)
    if not native then return end

    local states = extraBtnState.zoneAbilityNativeMouseStates
    if suppress then
        if not states[native] then
            local clickEnabled = true
            local motionEnabled = true
            if type(native.IsMouseClickEnabled) == "function" then
                local ok, value = pcall(native.IsMouseClickEnabled, native)
                if ok then clickEnabled = value == true end
            end
            if type(native.IsMouseMotionEnabled) == "function" then
                local ok, value = pcall(native.IsMouseMotionEnabled, native)
                if ok then motionEnabled = value == true end
            end
            states[native] = { click = clickEnabled, motion = motionEnabled }
        end
        if native.SetMouseClickEnabled then native:SetMouseClickEnabled(false) end
        if native.SetMouseMotionEnabled then native:SetMouseMotionEnabled(false) end
        return
    end

    local saved = states[native]
    if saved then
        if native.SetMouseClickEnabled then native:SetMouseClickEnabled(saved.click) end
        if native.SetMouseMotionEnabled then native:SetMouseMotionEnabled(saved.motion) end
        states[native] = nil
    end
end

local function ApplyNativeZoneAbilityMouseSuppression(suppress, activeButtons, bridgeButtons)
    if InCombatLockdown() then
        ActionBarsOwned.pendingExtraButtonRefresh = true
        return
    end

    suppress = suppress == true
    if suppress then
        local activeSet = {}
        bridgeButtons = bridgeButtons or {}
        for _, native in ipairs(activeButtons or {}) do
            activeSet[native] = true
            if bridgeButtons[native] then
                -- This native button is the trusted physical click target.
                -- Restore its original mouse channels and let our visual pass through.
                SetNativeZoneAbilityMouseSuppressed(native, false)
            else
                SetNativeZoneAbilityMouseSuppressed(native, true)
            end
        end

        -- Release saved mouse state for pooled buttons that are no longer active.
        local restore = {}
        for native in pairs(extraBtnState.zoneAbilityNativeMouseStates) do
            if not activeSet[native] or bridgeButtons[native] then
                restore[#restore + 1] = native
            end
        end
        for _, native in ipairs(restore) do
            SetNativeZoneAbilityMouseSuppressed(native, false)
        end
    else
        local restore = {}
        for native in pairs(extraBtnState.zoneAbilityNativeMouseStates) do
            restore[#restore + 1] = native
        end
        for _, native in ipairs(restore) do
            SetNativeZoneAbilityMouseSuppressed(native, false)
        end
    end
end

local function ApplyNativeZoneAbilityVisualSuppression(suppress)
    if InCombatLockdown() then
        ActionBarsOwned.pendingExtraButtonRefresh = true
        return
    end

    suppress = suppress == true
    if extraBtnState.nativeZoneAbilityAlphaSuppressed == suppress then
        return
    end

    local native = _G.ZoneAbilityFrame
    if not native or type(native.SetAlpha) ~= "function" then
        return
    end

    native:SetAlpha(suppress and 0 or 1)
    extraBtnState.nativeZoneAbilityAlphaSuppressed = suppress
end

-- Final native mouse-bridge positioning.
-- An alpha-zero ExtraActionButton1 hitbox
-- overlapping Zone Ability. With that hitbox suppressed, keep Blizzard's native
-- ZoneAbilityFrame as the click authority but position it at TomoMod's owned
-- holder. Only out-of-combat scale/points are changed; no parent, events, secure
-- attributes, scripts, cooldowns or button internals are modified.
local function CaptureNativeZoneAbilityLayout(frame)
    if extraBtnState.zoneAbilityNativeLayoutState or not frame then return end

    local state = { points = {}, scale = 1 }
    if type(frame.GetScale) == "function" then
        local ok, value = pcall(frame.GetScale, frame)
        if ok and value and not Helpers.IsSecretValue(value) then
            state.scale = tonumber(value) or 1
        end
    end

    local numPoints = 0
    if type(frame.GetNumPoints) == "function" then
        local ok, value = pcall(frame.GetNumPoints, frame)
        if ok and value and not Helpers.IsSecretValue(value) then
            numPoints = tonumber(value) or 0
        end
    end
    for i = 1, numPoints do
        local ok, point, relativeTo, relativePoint, x, y = pcall(frame.GetPoint, frame, i)
        if ok and point and not Helpers.HasSecretValue(point, relativePoint, x, y) then
            state.points[#state.points + 1] = {
                point = point, relativeTo = relativeTo, relativePoint = relativePoint,
                x = tonumber(x) or 0, y = tonumber(y) or 0,
            }
        end
    end
    extraBtnState.zoneAbilityNativeLayoutState = state
end

local function ApplyNativeZoneAbilityBridgePosition(enabled, holder, settings)
    if InCombatLockdown() then
        ActionBarsOwned.pendingExtraButtonRefresh = true
        return
    end

    local frame = _G.ZoneAbilityFrame
    if not frame then return end

    if enabled and holder then
        CaptureNativeZoneAbilityLayout(frame)
        local scale = tonumber(settings and settings.scale) or 1
        if scale <= 0 then scale = 1 end
        local offsetX = tonumber(settings and settings.offsetX) or 0
        local offsetY = tonumber(settings and settings.offsetY) or 0

        if frame.SetScale then frame:SetScale(scale) end
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", holder, "CENTER", offsetX, offsetY)
        extraBtnState.zoneAbilityNativeBridgePositioned = true
        return
    end

    if not extraBtnState.zoneAbilityNativeBridgePositioned then return end
    local state = extraBtnState.zoneAbilityNativeLayoutState
    if state then
        if frame.SetScale then frame:SetScale(state.scale or 1) end
        frame:ClearAllPoints()
        for _, point in ipairs(state.points or {}) do
            frame:SetPoint(point.point, point.relativeTo, point.relativePoint or point.point,
                point.x or 0, point.y or 0)
        end
    end
    extraBtnState.zoneAbilityNativeBridgePositioned = false
    extraBtnState.zoneAbilityNativeLayoutState = nil
end

local function ApplyZoneAbilityProxySettings()
    if InCombatLockdown() then
        ActionBarsOwned.pendingExtraButtonRefresh = true
        return
    end

    local settings = GetExtraButtonDB("zoneAbility")
    local proxies, holder = EnsureZoneAbilityProxies()
    if not proxies or not holder then return end

    local enabled = settings and settings.enabled == true
    local scale = tonumber(settings and settings.scale) or 1
    if scale <= 0 then scale = 1 end

    local active = enabled and CollectActiveZoneAbilityButtons() or {}
    local count = math.min(#active, MAX_ZONE_ABILITY_PROXIES)
    local buttonSize = 64 * scale
    local spacing = 4 * scale
    local visibleWidth = count > 0 and (count * buttonSize + (count - 1) * spacing) or buttonSize

    holder:SetSize(math.max(visibleWidth, 64), math.max(buttonSize, 64))
    ApplyExtraButtonFrameAnchor("zoneAbility")
    ApplyNativeZoneAbilityBridgePosition(enabled, holder, settings)

    wipe(extraBtnState.zoneAbilityNativeButtons)
    wipe(extraBtnState.zoneAbilityNativeBridgeButtons)

    for i = 1, MAX_ZONE_ABILITY_PROXIES do
        local proxy = proxies[i]
        local native = active[i]

        proxy:ClearAllPoints()
        proxy:SetSize(buttonSize, buttonSize)
        proxy:SetPoint("LEFT", holder, "LEFT", (i - 1) * (buttonSize + spacing), 0)

        if enabled and native and ConfigureZoneAbilityProxyAction(proxy, native) then
            extraBtnState.zoneAbilityNativeButtons[i] = native

            if proxy._tomomodZoneAbilityActionMode == "native-physical" then
                -- Preserve Blizzard's exact physical mouse
                -- execution path while ZoneAbilityFrame itself follows TomoMod's
                -- owned holder out of combat. The proxy is visual-only and overlays
                -- the native button at its final TomoMod position.
                extraBtnState.zoneAbilityNativeBridgeButtons[native] = true
                proxy:ClearAllPoints()
                proxy:SetAllPoints(native)
                SetZoneAbilityProxyMouseEnabled(proxy, false)
            else
                SetZoneAbilityProxyMouseEnabled(proxy, true)
            end

            RefreshZoneAbilityProxyVisual(i)
            proxy:Show()
        else
            proxy:SetAttribute("clickbutton", nil)
            proxy:SetAttribute("spell", nil)
            proxy:SetAttribute("type", nil)
            proxy._tomomodZoneAbilityActionMode = nil
            proxy._tomomodZoneAbilityBaseSpellID = nil
            SetZoneAbilityProxyMouseEnabled(proxy, false)
            proxy:Hide()
            RefreshZoneAbilityProxyVisual(i)
        end
    end

    -- Native-physical bridge buttons deliberately keep the real
    -- Blizzard mouse surface active underneath our mouse-transparent TUI skin.
    ApplyNativeZoneAbilityMouseSuppression(enabled, active,
        extraBtnState.zoneAbilityNativeBridgeButtons)

    -- Suppress only the native Zone Ability presentation while its
    -- independent TUI proxy is enabled.
    ApplyNativeZoneAbilityVisualSuppression(enabled)
end

-- Native Leave Vehicle visual suppression:
-- Leave Vehicle uses the same alpha-only native visual suppression rule:
-- alpha-only suppression does not contaminate Blizzard's protected action-bar
-- pipeline. Apply the same presentation-only rule to the native vehicle-leave
-- controls, while preserving Blizzard's taxi-only early-landing button.
--
-- IMPORTANT: never Hide/Show, reparent, move, unregister events, alter secure
-- attributes, replace scripts/methods or touch OverrideActionBar itself. Only
-- SetAlpha(0/1) is allowed here, and only outside combat. State is tracked in
-- TomoMod's side table rather than written onto Blizzard frames.
local function ApplyNativeLeaveVehicleVisualSuppression(suppress)
    if InCombatLockdown() then
        ActionBarsOwned.pendingExtraButtonRefresh = true
        return
    end

    suppress = suppress == true

    -- Blizzard's MainMenuBarVehicleLeaveButton has special taxi behavior:
    -- OnClicked() calls TaxiRequestEarlyLanding(), while our secure
    -- type="leavevehicle" proxy intentionally only performs VehicleExit().
    -- Keep the native button visible on taxis so that functionality is retained.
    local onTaxi = UnitOnTaxi and UnitOnTaxi("player") or false
    local desiredSuppressed = suppress and not onTaxi

    extraBtnState.nativeLeaveVehicleAlphaStates =
        extraBtnState.nativeLeaveVehicleAlphaStates or {}
    local states = extraBtnState.nativeLeaveVehicleAlphaStates
    local seen = {}

    local function ApplyOne(native)
        if not native or seen[native] or type(native.SetAlpha) ~= "function" then
            return
        end
        seen[native] = true
        if states[native] == desiredSuppressed then
            return
        end
        native:SetAlpha(desiredSuppressed and 0 or 1)
        states[native] = desiredSuppressed
    end

    ApplyOne(_G.MainMenuBarVehicleLeaveButton)

    -- Some controller states/builds expose a distinct leave button through the
    -- override bar. Treat it identically if present, without mutating its parent.
    local overrideBar = _G.OverrideActionBar
    ApplyOne(overrideBar and overrideBar.LeaveButton)
end

-- Leave Vehicle secure proxy:
-- Restore the Leave Vehicle control without touching Blizzard's native action
-- logic. SecureTemplates exposes a native "leavevehicle" secure action whose
-- protected handler calls VehicleExit(). This button is owned entirely by
-- TomoMod, parented to UIParent and shown by a secure [vehicleui] state driver.
local function EnsureLeaveVehicleProxy()
    if extraBtnState.leaveVehicleProxy then
        return extraBtnState.leaveVehicleProxy
    end
    if InCombatLockdown() then
        ActionBarsOwned.pendingExtraButtonInit = true
        return nil
    end

    local proxy = CreateFrame("Button", "TUI_LeaveVehicleProxyButton", UIParent,
        "SecureActionButtonTemplate")
    proxy:SetSize(40, 40)
    proxy:SetFrameStrata("HIGH")
    proxy:RegisterForClicks("AnyUp", "AnyDown")
    proxy:SetAttribute("type", "leavevehicle")

    local anchor = ActionBarsOwned.containers and ActionBarsOwned.containers.bar1
    if anchor then
        proxy:SetPoint("BOTTOM", anchor, "TOP", 0, 8)
    else
        proxy:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 180)
    end

    -- Give Leave Vehicle the same owned presentation path as the
    -- other special buttons.  The exit artwork becomes the button Icon so
    -- SkinButton() can apply the current crop/backdrop/border/gloss preset
    -- without touching Blizzard's native vehicle-leave controls.
    local icon = proxy:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(proxy)
    icon:SetTexture([[Interface\Vehicles\UI-Vehicles-Button-Exit-Up]])
    icon:SetTexCoord(0.140625, 0.859375, 0.140625, 0.859375)
    proxy.Icon = icon
    proxy.icon = icon

    -- Keep a normal texture as a compatibility fallback for Button APIs; once
    -- SkinButton() sees proxy.Icon it hides this legacy layer and draws the
    -- standard TomoMod skin around the owned icon instead.
    local normal = proxy:CreateTexture(nil, "ARTWORK")
    normal:SetAllPoints(proxy)
    normal:SetTexture([[Interface\Vehicles\UI-Vehicles-Button-Exit-Up]])
    normal:SetTexCoord(0.140625, 0.859375, 0.140625, 0.859375)
    proxy:SetNormalTexture(normal)

    local pushed = proxy:CreateTexture(nil, "ARTWORK")
    pushed:SetAllPoints(proxy)
    pushed:SetTexture([[Interface\Vehicles\UI-Vehicles-Button-Exit-Down]])
    pushed:SetTexCoord(0.140625, 0.859375, 0.140625, 0.859375)
    proxy:SetPushedTexture(pushed)

    local highlight = proxy:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(proxy)
    highlight:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
    highlight:SetBlendMode("ADD")
    proxy:SetHighlightTexture(highlight)

    proxy:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(LEAVE_VEHICLE or "Leave Vehicle")
        GameTooltip:Show()
    end)
    proxy:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Cosmetic only: this is a TomoMod-owned SecureActionButtonTemplate, so it
    -- can safely use the same SkinButton() pipeline already validated on Extra
    -- Action and Zone Ability.  The secure type="leavevehicle" action itself
    -- is unchanged.
    ApplyOwnedSpecialButtonActionSkin(proxy)

    extraBtnState.leaveVehicleProxy = proxy

    -- Keep alpha suppression synchronized when vehicle/taxi state changes. This
    -- event frame is TomoMod-owned and never hooks a Blizzard frame.
    if not extraBtnState.leaveVehicleProxyEvents then
        local events = CreateFrame("Frame")
        events:RegisterEvent("PLAYER_ENTERING_WORLD")
        events:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
        events:RegisterEvent("UNIT_ENTERED_VEHICLE")
        events:RegisterEvent("UNIT_EXITED_VEHICLE")
        events:RegisterEvent("VEHICLE_UPDATE")
        events:RegisterEvent("PLAYER_CONTROL_LOST")
        events:RegisterEvent("PLAYER_CONTROL_GAINED")
        events:SetScript("OnEvent", function(_, event, unit)
            if (event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE")
                and unit and unit ~= "player" then
                return
            end
            if InCombatLockdown() then
                ActionBarsOwned.pendingExtraButtonRefresh = true
                return
            end
            ApplyNativeLeaveVehicleVisualSuppression(true)
        end)
        extraBtnState.leaveVehicleProxyEvents = events
    end

    return proxy
end

local function ApplyLeaveVehicleProxySettings()
    if InCombatLockdown() then
        ActionBarsOwned.pendingExtraButtonRefresh = true
        return
    end

    local proxy = EnsureLeaveVehicleProxy()
    if not proxy then return end

    if not extraBtnState.leaveVehicleStateDriverInstalled then
        RegisterStateDriver(proxy, "visibility", "[vehicleui] show; hide")
        extraBtnState.leaveVehicleStateDriverInstalled = true
    end

    -- Reapply the owned visual skin so changing the global ActionBar icon-skin
    -- preset also updates the Leave Vehicle button on the next refresh.
    ApplyOwnedSpecialButtonActionSkin(proxy)
    ApplyNativeLeaveVehicleVisualSuppression(true)
end

InitializeExtraButtons = function()
    -- Extra Action and Leave Vehicle stay independent secure TUI
    -- controls. Zone Ability uses a presentation-only TUI skin over Blizzard's
    -- trusted physical button, positioned at TomoMod's holder out of combat.
    -- Native action/cooldown/event ownership remains with Blizzard throughout.
    ActionBarsOwned.pendingExtraButtonInit = false
    ActionBarsOwned.pendingExtraButtonRefresh = false
    ApplyExtraActionProxySettings()
    ApplyZoneAbilityProxySettings()
    ApplyLeaveVehicleProxySettings()
end

RefreshExtraButtons = function()
    ActionBarsOwned.pendingExtraButtonRefresh = false
    ApplyExtraActionProxySettings()
    ApplyZoneAbilityProxySettings()
    ApplyLeaveVehicleProxySettings()
end

_G.TUI_ToggleExtraButtonMovers = ToggleExtraButtonMovers
_G.TUI_ShowExtraButtonMovers = ShowExtraButtonMovers
_G.TUI_HideExtraButtonMovers = HideExtraButtonMovers
_G.TUI_RefreshExtraButtons = RefreshExtraButtons
ActionBarsOwned.extraBtnState = extraBtnState

end

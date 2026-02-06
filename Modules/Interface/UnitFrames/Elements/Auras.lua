-- =====================================
-- Elements/Auras.lua — Aura Icons for UnitFrames
-- =====================================

local UF_Elements = UF_Elements or {}

local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"

-- =====================================
-- CREATE AURA CONTAINER
-- =====================================

function UF_Elements.CreateAuraContainer(parent, unit, settings)
    if not settings or not settings.auras or not settings.auras.enabled then return nil end

    local auraSettings = settings.auras
    local container = CreateFrame("Frame", "TomoMod_Auras_" .. unit, parent)
    container:SetSize(300, auraSettings.size + 4)
    container.unit = unit
    container.parentFrame = parent
    container.icons = {}

    -- Position
    local pos = auraSettings.position
    if pos then
        container:SetPoint(pos.point, parent, pos.relativePoint, pos.x, pos.y)
    else
        container:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, 6)
    end

    -- Create icons
    for i = 1, auraSettings.maxAuras do
        UF_Elements.CreateAuraIcon(container, i, auraSettings)
    end

    -- Draggable support (uses global lock state)
    container:SetMovable(true)
    container:SetClampedToScreen(true)
    container:EnableMouse(false)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    container:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, relativePoint, x, y = self:GetPoint()
        auraSettings.position = { point = point, relativePoint = relativePoint, x = x, y = y }
    end)

    return container
end

-- =====================================
-- CREATE SINGLE AURA ICON
-- =====================================

function UF_Elements.CreateAuraIcon(container, index, auraSettings)
    local size = auraSettings.size or 30
    local spacing = auraSettings.spacing or 3
    local grow = auraSettings.growDirection or "RIGHT"

    local icon = CreateFrame("Frame", nil, container)
    icon:SetSize(size, size)

    -- Position
    if index == 1 then
        if grow == "RIGHT" then
            icon:SetPoint("LEFT", container, "LEFT", 0, 0)
        else
            icon:SetPoint("RIGHT", container, "RIGHT", 0, 0)
        end
    else
        local prev = container.icons[index - 1]
        if grow == "RIGHT" then
            icon:SetPoint("LEFT", prev, "RIGHT", spacing, 0)
        else
            icon:SetPoint("RIGHT", prev, "LEFT", -spacing, 0)
        end
    end

    -- Texture
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints()
    icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Border (colored by debuff type)
    icon.border = CreateFrame("Frame", nil, icon)
    icon.border:SetPoint("TOPLEFT", -1, 1)
    icon.border:SetPoint("BOTTOMRIGHT", 1, -1)
    UF_Elements.CreateBorder(icon.border)

    -- Cooldown overlay
    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints(icon.texture)
    icon.cooldown:SetDrawEdge(false)
    icon.cooldown:SetReverse(true)
    icon.cooldown:SetHideCountdownNumbers(true)

    -- Stack count
    icon.count = icon:CreateFontString(nil, "OVERLAY")
    icon.count:SetFont(FONT, 9, "OUTLINE")
    icon.count:SetPoint("BOTTOMRIGHT", -1, 1)
    icon.count:SetTextColor(1, 1, 1, 1)

    -- Duration
    if auraSettings.showDuration then
        icon.duration = icon:CreateFontString(nil, "OVERLAY")
        icon.duration:SetFont(FONT, 8, "OUTLINE")
        icon.duration:SetPoint("TOP", icon, "BOTTOM", 0, -1)
        icon.duration:SetTextColor(1, 1, 1, 0.9)
    end

    -- Tooltip
    icon:EnableMouse(true)
    icon:SetScript("OnEnter", function(self)
        if self.auraInstanceID and UnitExists(container.unit) then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
            -- SetUnitBuffByAuraInstanceID / SetUnitDebuffByAuraInstanceID are C-side
            -- and accept secret auraInstanceID values
            if self.auraIsHarmful then
                GameTooltip:SetUnitDebuffByAuraInstanceID(container.unit, self.auraInstanceID)
            else
                GameTooltip:SetUnitBuffByAuraInstanceID(container.unit, self.auraInstanceID)
            end
            GameTooltip:Show()
        end
    end)
    icon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    icon:Hide()
    container.icons[index] = icon
end

-- =====================================
-- UPDATE AURAS
-- =====================================

function UF_Elements.UpdateAuras(frame)
    if not frame or not frame.auraContainer then return end

    local unit = frame.unit
    local container = frame.auraContainer
    local settings = TomoModDB.unitFrames[unit]

    if not settings or not settings.auras or not settings.auras.enabled then
        container:Hide()
        return
    end

    if not UnitExists(unit) then
        container:Hide()
        return
    end

    container:Show()

    local auraSettings = settings.auras
    local maxAuras = auraSettings.maxAuras or 8
    local showOnlyMine = auraSettings.showOnlyMine
    local auraType = auraSettings.type or "HARMFUL"

    -- Collect auras
    -- In TWW, ALL aura data fields are secret — cannot do ANY Lua operations on them.
    -- Use |PLAYER filter string so C-side handles "only mine" filtering.
    local auras = {}
    local filters = {}

    if auraType == "ALL" then
        if showOnlyMine then
            filters = { "HARMFUL|PLAYER", "HELPFUL|PLAYER" }
        else
            filters = { "HARMFUL", "HELPFUL" }
        end
    else
        if showOnlyMine then
            filters = { auraType .. "|PLAYER" }
        else
            filters = { auraType }
        end
    end

    for _, filter in ipairs(filters) do
        -- GetAuraSlots returns: continuationToken, slot1, slot2, ... (varargs, NOT a table)
        local results = {C_UnitAuras.GetAuraSlots(unit, filter)}
        -- results[1] = continuationToken, results[2..n] = slot indices
        for i = 2, #results do
            if #auras >= maxAuras then break end
            local data = C_UnitAuras.GetAuraDataBySlot(unit, results[i])
            if data then
                -- Store only non-secret metadata we set ourselves
                data._filter = filter
                data._slotIndex = results[i]
                data._unit = unit
                table.insert(auras, data)
            end
        end
    end

    -- Update icons
    -- TWW: Aura data fields are SECRET values — can't do Lua operations on them.
    -- BUT: C_UnitAuras.GetAuraDuration() returns a Duration object with non-secret methods.
    -- AND: C_UnitAuras.GetAuraApplicationDisplayCount() returns a non-secret stack string.
    for i = 1, maxAuras do
        local iconFrame = container.icons[i]
        local aura = auras[i]

        if aura and iconFrame then
            -- Icon texture (SetTexture is C-side, accepts secrets)
            iconFrame.texture:SetTexture(aura.icon)

            -- Store secret auraInstanceID for tooltip (C-side methods accept it)
            iconFrame.auraInstanceID = aura.auraInstanceID
            -- _filter is non-secret (we set it), check if harmful
            iconFrame.auraIsHarmful = (aura._filter == "HARMFUL" or aura._filter == "HARMFUL|PLAYER")

            -- Duration object (non-secret GetRemainingDuration/GetTotalDuration)
            local durObj = C_UnitAuras.GetAuraDuration(aura._unit or unit, aura.auraInstanceID)
            iconFrame._durObj = durObj
            iconFrame._auraUnit = aura._unit or unit
            iconFrame._auraInstanceID = aura.auraInstanceID

            if durObj then
                -- TWW: GetRemainingDuration/GetTotalDuration return secrets too
                -- Can't compare them, but string.format (C function) accepts them
                -- Cooldown swipe: can't compute startTime (arithmetic on secrets forbidden)
                iconFrame.cooldown:Hide()

                -- Duration text: pass directly to string.format (no comparison)
                if iconFrame.duration then
                    iconFrame.duration:SetText(string.format("%.0f", durObj:GetRemainingDuration()))
                    iconFrame.duration:Show()
                end
            else
                iconFrame.cooldown:Hide()
                if iconFrame.duration then iconFrame.duration:Hide() end
            end

            -- Stack count (non-secret display string, empty if < 2)
            local stackStr = C_UnitAuras.GetAuraApplicationDisplayCount(aura._unit or unit, aura.auraInstanceID, 2, 1000)
            iconFrame.count:SetText(stackStr or "")
            iconFrame.count:Show()

            iconFrame:Show()
        elseif iconFrame then
            iconFrame._durObj = nil
            iconFrame._auraUnit = nil
            iconFrame._auraInstanceID = nil
            iconFrame:Hide()
        end
    end
end

-- =====================================
-- DURATION UPDATER TICKER
-- =====================================

local auraDurationTicker
function UF_Elements.StartAuraDurationUpdater(frames)
    if auraDurationTicker then return end
    -- TWW: C_UnitAuras.GetAuraDuration returns Duration objects with non-secret methods.
    -- Re-query duration every 0.1s to update remaining time text.
    auraDurationTicker = C_Timer.NewTicker(0.1, function()
        for _, frame in pairs(frames) do
            if frame.auraContainer and frame.auraContainer:IsVisible() then
                for _, icon in ipairs(frame.auraContainer.icons) do
                    if icon:IsShown() and icon.duration and icon._auraUnit and icon._auraInstanceID then
                        local durObj = C_UnitAuras.GetAuraDuration(icon._auraUnit, icon._auraInstanceID)
                        if durObj then
                            -- string.format is C function, accepts secret numbers — no comparison
                            icon.duration:SetText(string.format("%.0f", durObj:GetRemainingDuration()))
                        end
                    end
                end
            end
        end
    end)
end

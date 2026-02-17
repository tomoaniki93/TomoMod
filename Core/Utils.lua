-- =====================================
-- Utils.lua — Utility Functions
-- Backward compatible with all QOL modules
-- =====================================

-- Keep global namespace for QOL backward compat
TomoModMini_Utils = TomoModMini_Utils or {}
local U = TomoModMini_Utils

-- =====================================
-- TABLE UTILITIES
-- =====================================

function TomoModMini_MergeTables(dest, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dest[k]) ~= "table" then
                dest[k] = {}
            end
            TomoModMini_MergeTables(dest[k], v)
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
end

function U.DeepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[U.DeepCopy(k)] = U.DeepCopy(v)
    end
    return setmetatable(copy, getmetatable(orig))
end

-- =====================================
-- COLOR UTILITIES
-- =====================================

function U.GetClassColor(unit)
    unit = unit or "player"
    local _, class = UnitClass(unit)
    if class and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return c.r, c.g, c.b, 1
    end
    return 0.5, 0.5, 0.5, 1
end

function U.GetPowerColor(powerType)
    local info = PowerBarColor[powerType]
    if info then
        return info.r, info.g, info.b
    end
    return 0.5, 0.5, 0.5
end

function U.GetReactionColor(unit)
    local reaction = UnitReaction(unit, "player")
    if not reaction then return 0.5, 0.5, 0.5 end
    if reaction >= 5 then return 0.11, 0.82, 0.11 end
    if reaction == 4 then return 0.98, 0.82, 0.11 end
    return 0.78, 0.04, 0.04
end

function U.HexColor(r, g, b)
    return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

function U.ColorText(text, r, g, b)
    return string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, text)
end

function U.ClassColorText(text, unit)
    local r, g, b = U.GetClassColor(unit or "player")
    return U.ColorText(text, r, g, b)
end

-- =====================================
-- NUMBER FORMATTING
-- =====================================

function U.FormatNumber(num)
    if not num then return "0" end
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

function U.AbbreviateNumber(num)
    if not num then return "0" end
    if num >= 1000000000 then
        return string.format("%.1fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(math.floor(num))
    end
end

function U.FormatTime(seconds)
    if not seconds or seconds <= 0 then return "" end
    if seconds >= 86400 then
        return string.format("%dd", math.floor(seconds / 86400))
    elseif seconds >= 3600 then
        return string.format("%dh", math.floor(seconds / 3600))
    elseif seconds >= 60 then
        return string.format("%dm", math.floor(seconds / 60))
    elseif seconds >= 10 then
        return string.format("%d", math.floor(seconds))
    else
        return string.format("%.1f", seconds)
    end
end

-- =====================================
-- FRAME POSITION UTILITIES
-- =====================================

function U.SaveFramePosition(frame, dbTable)
    if not frame or not dbTable then return end
    local point, _, relativePoint, x, y = frame:GetPoint()
    dbTable.point = point or "CENTER"
    dbTable.relativePoint = relativePoint or "CENTER"
    dbTable.x = x or 0
    dbTable.y = y or 0
end

function U.ApplyFramePosition(frame, dbTable)
    if not frame or not dbTable then return end
    frame:ClearAllPoints()
    frame:SetPoint(
        dbTable.point or "CENTER",
        UIParent,
        dbTable.relativePoint or "CENTER",
        dbTable.x or 0,
        dbTable.y or 0
    )
end

function U.ResetFramePosition(frame, defaultPoint, defaultRelativePoint, defaultX, defaultY)
    if not frame then return end
    frame:ClearAllPoints()
    frame:SetPoint(
        defaultPoint or "CENTER",
        UIParent,
        defaultRelativePoint or "CENTER",
        defaultX or 0,
        defaultY or 0
    )
end

-- =====================================
-- LOCK/UNLOCK DRAG SYSTEM
-- =====================================

function U.SetupDraggable(frame, savePositionCallback)
    if not frame then return end
    frame.isLocked = true
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    -- Create a SEPARATE overlay Frame for drag handling.
    -- This sits on top of the main frame and captures mouse events ONLY when unlocked.
    -- When locked/hidden, clicks pass through to the SecureUnitButtonTemplate below.
    local dragFrame = CreateFrame("Frame", nil, frame)
    dragFrame:SetAllPoints(frame)
    dragFrame:SetFrameLevel(frame:GetFrameLevel() + 20)
    dragFrame:EnableMouse(false)
    dragFrame:Hide()

    local dragOverlay = dragFrame:CreateTexture(nil, "OVERLAY")
    dragOverlay:SetAllPoints(dragFrame)
    dragOverlay:SetColorTexture(1, 1, 0, 0.1)
    frame.dragOverlay = dragOverlay

    local dragLabel = dragFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dragLabel:SetPoint("CENTER", dragFrame, "CENTER")
    dragLabel:SetTextColor(1, 1, 0)
    dragLabel:SetText("(Déplacer)")
    frame.dragLabel = dragLabel

    -- Drag handlers on the OVERLAY frame, not the main secure frame
    dragFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            frame:StartMoving()
        end
    end)

    dragFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            frame:StopMovingOrSizing()
            if savePositionCallback then
                savePositionCallback()
            end
        end
    end)

    frame.dragFrame = dragFrame

    frame.SetLocked = function(self, locked)
        self.isLocked = locked
        if locked then
            -- Hide drag overlay — clicks pass to SecureUnitButtonTemplate
            dragFrame:EnableMouse(false)
            dragFrame:Hide()
        else
            -- Show drag overlay — it captures mouse for dragging
            dragFrame:EnableMouse(true)
            dragFrame:Show()
            self:SetAlpha(1)
            self:Show()
        end
    end

    frame.IsLocked = function(self)
        return self.isLocked
    end

    frame:SetLocked(true)
    return frame
end

-- =====================================
-- BACKWARD COMPAT: CreateSlider / CreateCheckbox
-- (used by old Config.lua and some QOL modules)
-- =====================================

function U.CreateSlider(parent, name, point, x, y, minVal, maxVal, step, width, label, callback)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint(point, x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(width)
    _G[name .. "Low"]:SetText(minVal)
    _G[name .. "High"]:SetText(maxVal)
    _G[name .. "Text"]:SetText(label)
    if callback then
        slider:SetScript("OnValueChanged", callback)
    end
    return slider
end

function U.CreateCheckbox(parent, point, x, y, text, checked, callback)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint(point, x, y)
    checkbox:SetChecked(checked)
    checkbox.text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkbox.text:SetText(text)
    if callback then
        checkbox:SetScript("OnClick", callback)
    end
    return checkbox
end

-- =====================================
-- DEBUG
-- =====================================

function U.Debug(...)
    if TomoModMiniDB and TomoModMiniDB.debug then
        print("|cff00ff00[TomoModMini Debug]|r", ...)
    end
end

function U.DumpTable(tbl, indent)
    indent = indent or 0
    local formatting = string.rep("  ", indent)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            print(formatting .. tostring(k) .. ":")
            U.DumpTable(v, indent + 1)
        else
            print(formatting .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

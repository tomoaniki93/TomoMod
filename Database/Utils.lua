-- =====================================
-- Utils.lua
-- =====================================

-- Namespace pour les utilitaires
TomoMod_Utils = {}

-- Fusionner les tables (pour appliquer les defaults)
function TomoMod_MergeTables(dest, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dest[k]) ~= "table" then
                dest[k] = {}
            end
            TomoMod_MergeTables(dest[k], v)
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
end

-- Obtenir la couleur de classe
function TomoMod_Utils.GetClassColor()
    local _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class]
    return color.r, color.g, color.b, 1
end

-- Créer un slider standard
function TomoMod_Utils.CreateSlider(parent, name, point, x, y, minVal, maxVal, step, width, label, callback)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint(point, x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(width)
    _G[name.."Low"]:SetText(minVal)
    _G[name.."High"]:SetText(maxVal)
    _G[name.."Text"]:SetText(label)
    
    if callback then
        slider:SetScript("OnValueChanged", callback)
    end
    
    return slider
end

-- Créer une checkbox standard
function TomoMod_Utils.CreateCheckbox(parent, point, x, y, text, checked, callback)
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
-- LOCK/UNLOCK UTILITIES
-- =====================================

-- Créer un système de drag & drop avec Lock/Unlock pour un frame
function TomoMod_Utils.SetupDraggable(frame, savePositionCallback)
    if not frame then return end
    
    -- Propriétés
    frame.isLocked = true
    
    -- Rendre le frame déplaçable
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    
    -- Créer l'overlay de déplacement (jaune transparent)
    local dragOverlay = frame:CreateTexture(nil, "OVERLAY")
    dragOverlay:SetAllPoints(frame)
    dragOverlay:SetColorTexture(1, 1, 0, 0.1)
    dragOverlay:Hide()
    frame.dragOverlay = dragOverlay
    
    -- Créer le label d'instructions
    local dragLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dragLabel:SetPoint("CENTER", frame, "CENTER")
    dragLabel:SetTextColor(1, 1, 0)
    dragLabel:SetText("(Cliquez et glissez)")
    dragLabel:Hide()
    frame.dragLabel = dragLabel
    
    -- Handlers de drag
    frame:SetScript("OnMouseDown", function(self, button)
        if not self.isLocked and button == "LeftButton" then
            self:StartMoving()
        end
    end)
    
    frame:SetScript("OnMouseUp", function(self, button)
        if not self.isLocked and button == "LeftButton" then
            self:StopMovingOrSizing()
            if savePositionCallback then
                savePositionCallback()
            end
        end
    end)
    
    -- Fonction pour lock/unlock
    frame.SetLocked = function(self, locked)
        self.isLocked = locked
        
        if locked then
            -- Mode verrouillé
            self:EnableMouse(false)
            if self.dragOverlay then self.dragOverlay:Hide() end
            if self.dragLabel then self.dragLabel:Hide() end
        else
            -- Mode déplacement
            self:EnableMouse(true)
            if self.dragOverlay then self.dragOverlay:Show() end
            if self.dragLabel then self.dragLabel:Show() end
            -- Forcer l'affichage en mode déplacement
            self:SetAlpha(1)
            self:Show()
        end
    end
    
    -- Fonction pour obtenir l'état
    frame.IsLocked = function(self)
        return self.isLocked
    end
    
    -- Verrouiller par défaut
    frame:SetLocked(true)
    
    return frame
end

-- Sauvegarder la position d'un frame dans la DB
function TomoMod_Utils.SaveFramePosition(frame, dbTable)
    if not frame or not dbTable then return end
    
    local point, _, relativePoint, x, y = frame:GetPoint()
    dbTable.point = point or "CENTER"
    dbTable.relativePoint = relativePoint or "CENTER"
    dbTable.x = x or 0
    dbTable.y = y or 0
end

-- Appliquer une position sauvegardée à un frame
function TomoMod_Utils.ApplyFramePosition(frame, dbTable)
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

-- Réinitialiser la position d'un frame
function TomoMod_Utils.ResetFramePosition(frame, defaultPoint, defaultRelativePoint, defaultX, defaultY)
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
-- TEXT FORMATTING UTILITIES
-- =====================================

-- Formater un nombre avec séparateurs
function TomoMod_Utils.FormatNumber(num)
    if not num then return "0" end
    
    local formatted = tostring(num)
    local k
    
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    
    return formatted
end

-- Abréger les grands nombres (1000 = 1k, 1000000 = 1M)
function TomoMod_Utils.AbbreviateNumber(num)
    if not num then return "0" end
    
    if num >= 1000000000 then
        return string.format("%.1fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

-- Obtenir un texte coloré
function TomoMod_Utils.ColorText(text, r, g, b)
    return string.format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, text)
end

-- =====================================
-- DEBUG UTILITIES
-- =====================================

-- Print debug (avec prefix TomoMod)
function TomoMod_Utils.Debug(...)
    if TomoModDB and TomoModDB.debug then
        print("|cff00ff00[TomoMod Debug]|r", ...)
    end
end

-- Dump une table (pour debug)
function TomoMod_Utils.DumpTable(tbl, indent)
    indent = indent or 0
    local formatting = string.rep("  ", indent)
    
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            print(formatting .. tostring(k) .. ":")
            TomoMod_Utils.DumpTable(v, indent + 1)
        else
            print(formatting .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

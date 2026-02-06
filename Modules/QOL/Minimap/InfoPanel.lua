-- =====================================
-- InfoPanel.lua
-- =====================================

TomoMod_InfoPanel = {}
local infoPanel

-- Cacher l'heure de Blizzard
function TomoMod_InfoPanel.HideBlizzardClock()
    if TimeManagerClockButton then
        TimeManagerClockButton:Hide()
    end
    if GameTimeFrame then
        GameTimeFrame:Hide()
    end
end

-- Calculer la durabilité moyenne
function TomoMod_InfoPanel.GetAverageDurability()
    local total, count = 0, 0
    for slot = 1, 18 do
        local current, maximum = GetInventoryItemDurability(slot)
        if current and maximum and maximum > 0 then
            total = total + (current / maximum * 100)
            count = count + 1
        end
    end
    return count > 0 and (total / count) or 100
end

-- Obtenir l'heure formatée
function TomoMod_InfoPanel.GetFormattedTime()
    local hour, minute = GetGameTime()
    if TomoModDB.infoPanel.use24Hour then
        return string.format("%02d:%02d", hour, minute)
    else
        local suffix = hour >= 12 and "PM" or "AM"
        hour = hour % 12
        if hour == 0 then hour = 12 end
        return string.format("%d:%02d %s", hour, minute, suffix)
    end
end

-- Calculer la taille du panneau
function TomoMod_InfoPanel.CalculateSize()
    local count = 0
    if TomoModDB.infoPanel.showDurability then count = count + 1 end
    if TomoModDB.infoPanel.showTime then count = count + 1 end
    
    if count == 0 then count = 1 end
    
    local width = 115 + (count - 1) * 50
    local height = 24
    
    return width, height
end

-- Créer le panneau d'informations
function TomoMod_InfoPanel.Create()
    if infoPanel then return infoPanel end
    
    infoPanel = CreateFrame("Frame", "TomoModInfoPanel", UIParent, "BackdropTemplate")
    infoPanel:SetFrameStrata("MEDIUM")
    infoPanel:SetFrameLevel(100)
    infoPanel:SetSize(200, 24)
    
    -- Rendre déplaçable
    infoPanel:SetMovable(true)
    infoPanel:SetUserPlaced(true)
    infoPanel:SetClampedToScreen(true)
    infoPanel:EnableMouse(true)
    infoPanel:RegisterForDrag("LeftButton")
    infoPanel:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self:StartMoving()
        end
    end)
    infoPanel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        TomoModDB.infoPanel.position = {point, relativePoint, xOfs, yOfs}
    end)
    
    -- Texte d'affichage
    infoPanel.text = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoPanel.text:SetPoint("CENTER")
    infoPanel.text:SetTextColor(1, 1, 1, 1)
    infoPanel.text:SetText("Info Panel")
    
    -- Afficher immédiatement
    infoPanel:Show()
    
    return infoPanel
end

-- Mettre à jour l'apparence
function TomoMod_InfoPanel.UpdateAppearance()
    if not infoPanel then return end
    
    local r, g, b, a = 0, 0, 0, 1
    if TomoModDB.infoPanel.borderColor == "class" then
        r, g, b, a = TomoMod_Utils.GetClassColor()
    end
    
    infoPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    infoPanel:SetBackdropColor(0, 0, 0, 0.8)
    infoPanel:SetBackdropBorderColor(r, g, b, a)
    
    infoPanel:SetScale(TomoModDB.infoPanel.scale)
    infoPanel:Show()
end

-- Mettre à jour le contenu
function TomoMod_InfoPanel.Update()
    if not infoPanel or not TomoModDB.infoPanel.enabled then return end
    
    local elements = {}
    
    for _, key in ipairs(TomoModDB.infoPanel.displayOrder) do
        if key == "Gear" and TomoModDB.infoPanel.showDurability then
            local durability = TomoMod_InfoPanel.GetAverageDurability()
            local color = durability > 50 and "|cff00ff00" or (durability > 25 and "|cffffff00" or "|cffff0000")
            table.insert(elements, string.format("%sGear: %d%%|r", color, durability))
        elseif key == "Time" and TomoModDB.infoPanel.showTime then
            table.insert(elements, "|cffffffffTime: " .. TomoMod_InfoPanel.GetFormattedTime() .. "|r")
        end
    end
    
    if #elements > 0 then
        infoPanel.text:SetText(table.concat(elements, "  "))
        infoPanel:Show()
    else
        infoPanel:Hide()
    end
    
    local width, height = TomoMod_InfoPanel.CalculateSize()
    infoPanel:SetSize(width, height)
end

-- Positionner le panneau
function TomoMod_InfoPanel.SetPosition()
    if not infoPanel then return end
    
    infoPanel:ClearAllPoints()
    
    if TomoModDB.infoPanel.position then
        local pos = TomoModDB.infoPanel.position
        infoPanel:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        -- Position par défaut au-dessus de la minimap
        infoPanel:SetPoint("BOTTOM", Minimap, "TOP", 0, 5)
    end
    
    infoPanel:Show()
end

-- Initialisation du module
function TomoMod_InfoPanel.Initialize()
    if not TomoModDB or not TomoModDB.infoPanel or not TomoModDB.infoPanel.enabled then
        return
    end
    
    C_Timer.After(1, function()
        TomoMod_InfoPanel.HideBlizzardClock()
        TomoMod_InfoPanel.Create()
        TomoMod_InfoPanel.SetPosition()
        TomoMod_InfoPanel.UpdateAppearance()
        
        -- Configurer le timer OnUpdate APRÈS toute l'initialisation
        infoPanel.elapsed = 0
        infoPanel:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= 1 then
                self.elapsed = 0
                TomoMod_InfoPanel.Update()
            end
        end)
        
        -- Premier update immédiat
        TomoMod_InfoPanel.Update()
    end)
end
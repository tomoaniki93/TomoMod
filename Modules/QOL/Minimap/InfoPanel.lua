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

-- Obtenir l'heure formatée (serveur ou locale)
function TomoMod_InfoPanel.GetFormattedTime()
    local hour, minute
    local db = TomoModDB.infoPanel

    if db.useServerTime then
        hour, minute = GetGameTime()
    else
        local d = date("*t")
        hour, minute = d.hour, d.min
    end

    if db.use24Hour then
        return string.format("%02d:%02d", hour, minute)
    else
        local suffix = hour >= 12 and "PM" or "AM"
        hour = hour % 12
        if hour == 0 then hour = 12 end
        return string.format("%d:%02d %s", hour, minute, suffix)
    end
end

-- Label du mode heure actif (S = Serveur, L = Locale)
local function GetTimeLabel()
    return TomoModDB.infoPanel.useServerTime and "S" or "L"
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

-- Créer un élément dans le panneau
local function CreateElement(parent)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(24)

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetTextColor(1, 1, 1, 1)
    btn.text = text

    return btn
end

-- Créer le panneau d'informations
function TomoMod_InfoPanel.Create()
    if infoPanel then return infoPanel end

    infoPanel = CreateFrame("Frame", "TomoModInfoPanel", UIParent, "BackdropTemplate")
    infoPanel:SetFrameStrata("MEDIUM")
    infoPanel:SetFrameLevel(100)
    infoPanel:SetSize(200, 24)

    -- Rendre déplaçable (Shift + drag)
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

    -- Éléments individuels
    infoPanel.elements = {}

    -- Gear element (non-cliquable, juste hover)
    local gear = CreateElement(infoPanel)
    gear:SetScript("OnEnter", function(self)
        self.text:SetTextColor(0.047, 0.824, 0.624, 1)
    end)
    gear:SetScript("OnLeave", function(self)
        self.text:SetTextColor(1, 1, 1, 1)
    end)
    infoPanel.elements.gear = gear

    -- Time element (cliquable)
    local timeBtn = CreateElement(infoPanel)
    timeBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    timeBtn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            -- Ouvrir le calendrier
            ToggleCalendar()
        elseif button == "RightButton" then
            if IsShiftKeyDown() then
                -- Shift + clic droit → toggle 12h / 24h
                TomoModDB.infoPanel.use24Hour = not TomoModDB.infoPanel.use24Hour
                local fmt = TomoModDB.infoPanel.use24Hour and "24h" or "12h"
                print("|cff0cd29fTomoMod|r " .. string.format(TomoMod_L["time_format_msg"], fmt))
            else
                -- Clic droit → toggle Serveur / Locale
                TomoModDB.infoPanel.useServerTime = not TomoModDB.infoPanel.useServerTime
                local mode = TomoModDB.infoPanel.useServerTime and TomoMod_L["time_server"] or TomoMod_L["time_local"]
                print("|cff0cd29fTomoMod|r " .. string.format(TomoMod_L["time_mode_msg"], mode))
            end
            TomoMod_InfoPanel.Update()
        end
    end)
    timeBtn:SetScript("OnEnter", function(self)
        self.text:SetTextColor(0.047, 0.824, 0.624, 1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -4)
        GameTooltip:ClearLines()
        local mode = TomoModDB.infoPanel.useServerTime and TomoMod_L["time_server"] or TomoMod_L["time_local"]
        local fmt = TomoModDB.infoPanel.use24Hour and "24h" or "12h"
        GameTooltip:AddLine(string.format(TomoMod_L["time_tooltip_title"], mode, fmt), 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(TomoMod_L["time_tooltip_left_click"], 0.8, 0.8, 0.8)
        GameTooltip:AddLine(TomoMod_L["time_tooltip_right_click"], 0.8, 0.8, 0.8)
        GameTooltip:AddLine(TomoMod_L["time_tooltip_shift_right"], 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    timeBtn:SetScript("OnLeave", function(self)
        self.text:SetTextColor(1, 1, 1, 1)
        GameTooltip:Hide()
    end)
    infoPanel.elements.time = timeBtn

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

    local db = TomoModDB.infoPanel
    local elements = infoPanel.elements

    -- Cacher tous les éléments d'abord
    elements.gear:Hide()
    elements.time:Hide()

    -- Construire la liste des éléments visibles dans l'ordre
    local visible = {}

    for _, key in ipairs(db.displayOrder) do
        if key == "Gear" and db.showDurability then
            local durability = TomoMod_InfoPanel.GetAverageDurability()
            local color = durability > 50 and "|cff00ff00" or (durability > 25 and "|cffffff00" or "|cffff0000")
            elements.gear.text:SetText(string.format("%sGear: %d%%|r", color, durability))
            table.insert(visible, elements.gear)
        elseif key == "Time" and db.showTime then
            local label = GetTimeLabel()
            elements.time.text:SetText("|cffffffffTime: " .. TomoMod_InfoPanel.GetFormattedTime() .. " |cff888888" .. label .. "|r")
            table.insert(visible, elements.time)
        end
    end

    if #visible == 0 then
        infoPanel:Hide()
        return
    end

    -- Layout horizontal centré avec padding
    local padding = 12
    local totalWidth = 0

    -- Mesurer la largeur de chaque élément
    for _, elem in ipairs(visible) do
        local textWidth = elem.text:GetStringWidth()
        elem:SetWidth(textWidth + padding)
        totalWidth = totalWidth + textWidth + padding
    end

    -- Ajouter un peu de marge aux bords
    local margin = 10
    infoPanel:SetSize(totalWidth + margin * 2, 24)

    -- Positionner les éléments de gauche à droite
    local xOffset = margin
    for _, elem in ipairs(visible) do
        elem:ClearAllPoints()
        elem:SetPoint("LEFT", infoPanel, "LEFT", xOffset, 0)
        elem:Show()
        xOffset = xOffset + elem:GetWidth()
    end
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

    -- Appliquer le défaut useServerTime si absent (migration)
    if TomoModDB.infoPanel.useServerTime == nil then
        TomoModDB.infoPanel.useServerTime = true
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

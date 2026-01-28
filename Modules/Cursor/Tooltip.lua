-- =====================================
-- Tooltip.lua
-- Amélioration du tooltip avec couleurs dynamiques
-- Bordure et nom colorés selon la cible
-- =====================================

TomoMod_Tooltip = {}

local function GetUnitColor(unit)
    if not unit or not UnitExists(unit) then
        return 1, 1, 1 -- Blanc par défaut
    end
    
    -- Joueur : couleur de classe
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class and RAID_CLASS_COLORS[class] then
            local color = RAID_CLASS_COLORS[class]
            return color.r, color.g, color.b
        end
        return 1, 1, 1
    end
    
    -- PNJ : couleur de réaction
    local reaction = UnitReaction(unit, "player")
    if reaction then
        if reaction >= 5 then
            -- Amical (vert)
            return 0, 0.8, 0
        elseif reaction == 4 then
            -- Neutre (jaune)
            return 1, 0.82, 0
        else
            -- Hostile (rouge)
            return 0.8, 0, 0
        end
    end
    
    -- Dead ou tap denied
    if UnitIsDead(unit) then
        return 0.5, 0.5, 0.5 -- Gris
    end
    
    return 1, 1, 1
end

local function StyleTooltip(tooltip, unit)
    if not unit or not UnitExists(unit) then return end
    
    local db = TomoModDB.tooltip
    if not db.enabled then return end
    
    local r, g, b = GetUnitColor(unit)
    
    -- Bordure colorée
    if db.colorBorder then
        tooltip:SetBackdropBorderColor(r, g, b, 1)
    end
    
    -- Nom coloré (première ligne du tooltip)
    if db.colorName then
        local name = UnitName(unit)
        if name then
            local tooltipName = _G[tooltip:GetName() .. "TextLeft1"]
            if tooltipName then
                tooltipName:SetTextColor(r, g, b)
            end
        end
    end
end

local function OnTooltipSetUnit(tooltip)
    if not TomoModDB.tooltip.enabled then return end
    
    local _, unit = tooltip:GetUnit()
    if unit then
        StyleTooltip(tooltip, unit)
    end
end

-- Hook pour quand le tooltip est cleared/hidden
local function OnTooltipCleared(tooltip)
    if not TomoModDB.tooltip.enabled then return end
    
    -- Reset la bordure à la couleur par défaut
    if TomoModDB.tooltip.colorBorder then
        tooltip:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end
end

-- =====================================
-- INITIALISATION
-- =====================================

function TomoMod_Tooltip.Initialize()
    local db = TomoModDB.tooltip
    if not db.enabled then return end
    
    -- Hook sur GameTooltip
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        -- WoW 10.0+ (Dragonflight et après)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
            local _, unit = tooltip:GetUnit()
            if unit then
                StyleTooltip(tooltip, unit)
            end
        end)
    else
        -- Fallback pour anciennes versions
        GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
    end
    
    GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
    
    -- Améliorer le backdrop du tooltip si nécessaire
    if db.improveBackdrop then
        GameTooltip:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 2,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        GameTooltip:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
        GameTooltip:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end
end

-- =====================================
-- FONCTIONS PUBLIQUES
-- =====================================

function TomoMod_Tooltip.UpdateSettings()
    -- Les changements prendront effet au prochain tooltip affiché
end
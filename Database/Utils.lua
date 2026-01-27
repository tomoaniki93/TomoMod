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
    local _, class = GetUnitClass("player")
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
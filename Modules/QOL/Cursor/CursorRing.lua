-- =====================================
-- CursorRing.lua
-- =====================================

TomoMod_CursorRing = {}

local cursorFrame
local ringTexture
local updateTimer = 0

-- Créer le frame du cursor ring
function TomoMod_CursorRing.Create()
    if cursorFrame then return cursorFrame end
    
    cursorFrame = CreateFrame("Frame", "TomoModCursorRing", UIParent)
    cursorFrame:SetSize(64, 64)
    cursorFrame:SetFrameStrata("TOOLTIP")
    cursorFrame:SetFrameLevel(100)
    
    -- Créer la texture du ring
    ringTexture = cursorFrame:CreateTexture(nil, "ARTWORK")
    ringTexture:SetAllPoints(cursorFrame)
    ringTexture:SetTexture("Interface\\AddOns\\TomoMod\\Assets\\Textures\\Ring")
    ringTexture:SetBlendMode("ADD")
    
    -- Animation de rotation
    local animGroup = ringTexture:CreateAnimationGroup()
    local rotation = animGroup:CreateAnimation("Rotation")
    rotation:SetDuration(3) -- 3 secondes par rotation complète
    rotation:SetDegrees(360)
    animGroup:SetLooping("REPEAT")
    animGroup:Play()
    
    -- Update la position selon le curseur
    cursorFrame:SetScript("OnUpdate", function(self, elapsed)
        if not TomoModDB.cursorRing.enabled then
            self:Hide()
            return
        end
        
        self:Show()
        
        updateTimer = updateTimer + elapsed
        if updateTimer >= 0.01 then -- Update toutes les 0.01 secondes
            updateTimer = 0
            
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
        end
    end)
    
    return cursorFrame
end

-- Appliquer la couleur
function TomoMod_CursorRing.ApplyColor()
    if not ringTexture then return end
    
    if TomoModDB.cursorRing.useClassColor then
        local r, g, b = TomoMod_Utils.GetClassColor()
        ringTexture:SetVertexColor(r, g, b, 0.8)
    else
        ringTexture:SetVertexColor(1, 1, 1, 0.8)
    end
end

-- Appliquer le scale
function TomoMod_CursorRing.ApplyScale()
    if not cursorFrame then return end
    
    local size = 64 * TomoModDB.cursorRing.scale
    cursorFrame:SetSize(size, size)
end

-- Gérer l'ancrage du tooltip
local tooltipHooked = false
function TomoMod_CursorRing.SetupTooltipAnchor()
    if not tooltipHooked then
        -- Hook le positionnement par défaut du tooltip
        GameTooltip:HookScript("OnUpdate", function(self, elapsed)
            if TomoModDB.cursorRing.anchorTooltip and self:IsShown() then
                local x, y = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()
                self:ClearAllPoints()
                self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (x / scale) + 15, (y / scale) + 15)
            end
        end)
        tooltipHooked = true
    end
end

-- Afficher/Cacher le ring
function TomoMod_CursorRing.Toggle(show)
    if not cursorFrame then
        TomoMod_CursorRing.Create()
    end
    
    if show and TomoModDB.cursorRing.enabled then
        cursorFrame:Show()
    else
        cursorFrame:Hide()
    end
end

-- Appliquer tous les paramètres
function TomoMod_CursorRing.ApplySettings()
    if not TomoModDB.cursorRing.enabled then 
        if cursorFrame then
            cursorFrame:Hide()
        end
        return 
    end
    
    TomoMod_CursorRing.Create()
    TomoMod_CursorRing.ApplyColor()
    TomoMod_CursorRing.ApplyScale()
    TomoMod_CursorRing.SetupTooltipAnchor()
    TomoMod_CursorRing.Toggle(true)
end

-- Initialisation du module
function TomoMod_CursorRing.Initialize()
    TomoMod_CursorRing.ApplySettings()
end

-- =====================================
-- CursorRing.lua
-- =====================================

TomoModMini_CursorRing = {}

local cursorFrame
local ringTexture
local updateTimer = 0

-- Créer le frame du cursor ring
function TomoModMini_CursorRing.Create()
    if cursorFrame then return cursorFrame end
    
    cursorFrame = CreateFrame("Frame", "TomoModMiniCursorRing", UIParent)
    cursorFrame:SetSize(64, 64)
    cursorFrame:SetFrameStrata("TOOLTIP")
    cursorFrame:SetFrameLevel(100)
    
    -- Créer la texture du ring
    ringTexture = cursorFrame:CreateTexture(nil, "ARTWORK")
    ringTexture:SetAllPoints(cursorFrame)
    ringTexture:SetTexture("Interface\\AddOns\\TomoModMini\\Assets\\Textures\\Ring")
    ringTexture:SetBlendMode("ADD")
    
    -- Update la position selon le curseur
    -- [PERF] Frame is hidden when disabled; OnUpdate only runs when visible
    cursorFrame:SetScript("OnUpdate", function(self, elapsed)
        updateTimer = updateTimer + elapsed
        if updateTimer >= 0.016 then -- [PERF] 60fps instead of 100fps
            updateTimer = 0
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
        end
    end)
    
    return cursorFrame
end

-- Appliquer la couleur
function TomoModMini_CursorRing.ApplyColor()
    if not ringTexture then return end
    
    if TomoModMiniDB.cursorRing.useClassColor then
        local r, g, b = TomoModMini_Utils.GetClassColor()
        ringTexture:SetVertexColor(r, g, b, 0.8)
    else
        ringTexture:SetVertexColor(1, 1, 1, 0.8)
    end
end

-- Appliquer le scale
function TomoModMini_CursorRing.ApplyScale()
    if not cursorFrame then return end
    
    local size = 64 * TomoModMiniDB.cursorRing.scale
    cursorFrame:SetSize(size, size)
end

-- Gérer l'ancrage du tooltip
local tooltipHooked = false
function TomoModMini_CursorRing.SetupTooltipAnchor()
    if not tooltipHooked then
        -- Hook le positionnement par défaut du tooltip
        -- [PERF] Early-exit when not active
        GameTooltip:HookScript("OnUpdate", function(self, elapsed)
            if not TomoModMiniDB.cursorRing.enabled or not TomoModMiniDB.cursorRing.anchorTooltip then return end
            if not self:IsShown() then return end
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            self:ClearAllPoints()
            self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (x / scale) + 15, (y / scale) + 15)
        end)
        tooltipHooked = true
    end
end

-- Afficher/Cacher le ring
function TomoModMini_CursorRing.Toggle(show)
    if not cursorFrame then
        TomoModMini_CursorRing.Create()
    end
    
    if show and TomoModMiniDB.cursorRing.enabled then
        cursorFrame:Show()
    else
        cursorFrame:Hide()
    end
end

-- Appliquer tous les paramètres
function TomoModMini_CursorRing.ApplySettings()
    if not TomoModMiniDB.cursorRing.enabled then 
        if cursorFrame then
            cursorFrame:Hide()
        end
        return 
    end
    
    TomoModMini_CursorRing.Create()
    TomoModMini_CursorRing.ApplyColor()
    TomoModMini_CursorRing.ApplyScale()
    TomoModMini_CursorRing.SetupTooltipAnchor()
    TomoModMini_CursorRing.Toggle(true)
end

-- Initialisation du module
function TomoModMini_CursorRing.Initialize()
    TomoModMini_CursorRing.ApplySettings()
end

-- =====================================
-- CursorRing.lua
-- =====================================

TomoMod_CursorRing = {}

local cursorFrame
local ringTexture

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
    
    -- Update la position selon le curseur.
    -- Inspiré de Ellesmere : tourne CHAQUE frame (pas de throttle) mais saute SetPoint
    -- si la position pixel n'a pas changé → aucun overhead quand la souris est immobile.
    -- math.floor(x/s + 0.5) snape à la grille pixel et évite le jitter sub-pixel.
    -- Pas de ClearAllPoints → pas d'invalidation layout à chaque frame.
    local lastPX, lastPY = nil, nil
    cursorFrame:SetScript("OnUpdate", function(self)
        local s = UIParent:GetEffectiveScale()
        local x, y = GetCursorPosition()
        local px = math.floor(x / s + 0.5)
        local py = math.floor(y / s + 0.5)
        if px ~= lastPX or py ~= lastPY then
            lastPX, lastPY = px, py
            self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", px, py)
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

-- Gérer l'ancrage du tooltip (fonctionne même si le ring est désactivé)
local tooltipHooked = false
function TomoMod_CursorRing.SetupTooltipAnchor()
    if not tooltipHooked then
        -- Hook le positionnement par défaut du tooltip
        -- [PERF] Early-exit when anchorTooltip is off; skip layout when position unchanged
        local ttLastPX, ttLastPY = 0, 0
        local ttElapsed = 0
        GameTooltip:HookScript("OnUpdate", function(self, elapsed)
            if not TomoModDB.cursorRing.anchorTooltip then return end
            if not self:IsShown() then return end
            ttElapsed = ttElapsed + elapsed
            if ttElapsed < 0.05 then return end  -- throttle to ~20fps
            ttElapsed = 0
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            local px = math.floor((x / scale) + 0.5) + 15
            local py = math.floor((y / scale) + 0.5) + 15
            if px == ttLastPX and py == ttLastPY then return end
            ttLastPX, ttLastPY = px, py
            -- [PERF] SetPoint(1) replaces anchor #1 in-place (avoids ClearAllPoints layout invalidation)
            self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", px, py)
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
    -- Tooltip anchor works independently of ring enabled state
    TomoMod_CursorRing.SetupTooltipAnchor()
    TomoMod_CursorRing.ApplySettings()
end

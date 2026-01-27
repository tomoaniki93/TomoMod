-- =====================================
-- Minimap.lua
-- =====================================

TomoMod_Minimap = {}
local minimapBorder

-- Masquer la forme ronde et rendre carré
function TomoMod_Minimap.MakeSquare()
    Minimap:SetMaskTexture("Interface\\Buttons\\WHITE8X8")
    Minimap:SetArchBlobRingScalar(0)
    Minimap:SetQuestBlobRingScalar(0)
    Minimap:SetSize(TomoModDB.minimap.size, TomoModDB.minimap.size)
    
    -- Cache les éléments ronds de Blizzard
    local framesToHide = {
        MinimapBorder,
        MinimapBorderTop,
        MinimapZoomIn,
        MinimapZoomOut,
        MiniMapTracking,
        MiniMapWorldMapButton,
        MinimapCompassTexture,
    }
    
    for _, frame in pairs(framesToHide) do
        if frame then
            frame:Hide()
            frame:SetAlpha(0)
            frame:EnableMouse(false)
        end
    end
    
    -- Sécurité supplémentaire
    if MinimapBorder then MinimapBorder:Hide() end
    if MinimapBorderTop then MinimapBorderTop:Hide() end
    if MinimapZoomIn then MinimapZoomIn:Hide() end
    if MinimapZoomOut then MinimapZoomOut:Hide() end
    
    Minimap:SetClampedToScreen(true)
end

-- Créer la bordure personnalisée
function TomoMod_Minimap.CreateBorder()
    if not minimapBorder then
        minimapBorder = CreateFrame("Frame", "TomoModMinimapBorder", Minimap, "BackdropTemplate")
        minimapBorder:SetAllPoints(Minimap)
        minimapBorder:SetFrameLevel(Minimap:GetFrameLevel() + 1)
    end
    
    local r, g, b, a = 0, 0, 0, 1
    if TomoModDB.minimap.borderColor == "class" then
        r, g, b, a = TomoMod_Utils.GetClassColor()
    end
    
    minimapBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    minimapBorder:SetBackdropBorderColor(r, g, b, a)
end

-- Appliquer le scale
function TomoMod_Minimap.ApplyScale()
    Minimap:SetScale(TomoModDB.minimap.scale)
end

-- Rendre compatible avec Edit Mode
function TomoMod_Minimap.SetupEditMode()
    if EditModeManagerFrame then
        Minimap:SetMovable(true)
        Minimap:SetUserPlaced(true)
        Minimap:SetClampedToScreen(true)
    end
end

-- Appliquer tous les paramètres
function TomoMod_Minimap.ApplySettings()
    if not TomoModDB.minimap.enabled then return end
    
    TomoMod_Minimap.MakeSquare()
    TomoMod_Minimap.CreateBorder()
    TomoMod_Minimap.ApplyScale()
    TomoMod_Minimap.SetupEditMode()
end

-- Initialisation du module
function TomoMod_Minimap.Initialize()
    C_Timer.After(0.5, function()
        TomoMod_Minimap.ApplySettings()
    end)
end
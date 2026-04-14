-- =====================================
-- Minimap.lua
-- =====================================

TomoMod_Minimap = TomoMod_Minimap or {}
local minimapBorder
local isLocked = true
local moverOverlay

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

    -- Sync InfoPanel bars border color
    if TomoMod_InfoPanel and TomoMod_InfoPanel.UpdateAppearance then
        TomoMod_InfoPanel.UpdateAppearance()
    end
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

-- =====================================
-- POSITION SAVE / RESTORE
-- =====================================

local function SavePosition()
    local db = TomoModDB and TomoModDB.minimap
    if not db then return end
    local point, _, relPoint, x, y = Minimap:GetPoint(1)
    if point then
        db.position = { anchor = point, relTo = relPoint, x = x, y = y }
    end
end

local function RestorePosition()
    local db = TomoModDB and TomoModDB.minimap
    if not db or not db.position then return end
    local p = db.position
    Minimap:ClearAllPoints()
    Minimap:SetPoint(p.anchor, UIParent, p.relTo, p.x, p.y)
end

-- =====================================
-- MOVER OVERLAY
-- =====================================

local function CreateMoverOverlay()
    if moverOverlay then return end
    local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
    moverOverlay = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
    moverOverlay:SetAllPoints(Minimap)
    moverOverlay:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    moverOverlay:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    moverOverlay:SetBackdropColor(0.047, 0.824, 0.624, 0.25)
    moverOverlay:SetBackdropBorderColor(0.047, 0.824, 0.624, 0.8)
    local label = moverOverlay:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 12, "OUTLINE")
    label:SetPoint("CENTER")
    label:SetText("Minimap")
    label:SetTextColor(1, 1, 1, 1)
    moverOverlay:Hide()
end

-- =====================================
-- LOCK / UNLOCK
-- =====================================

local function SetLocked(locked)
    isLocked = locked
    if locked then
        Minimap:SetScript("OnDragStart", nil)
        Minimap:SetScript("OnDragStop", nil)
        Minimap:RegisterForDrag()
        if moverOverlay then moverOverlay:Hide() end
        SavePosition()
    else
        CreateMoverOverlay()
        Minimap:RegisterForDrag("LeftButton")
        Minimap:SetScript("OnDragStart", function(self) self:StartMoving() end)
        Minimap:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            SavePosition()
        end)
        moverOverlay:Show()
    end
end

function TomoMod_Minimap.ToggleLock()
    SetLocked(not isLocked)
end

function TomoMod_Minimap.IsLocked()
    return isLocked
end

-- Appliquer tous les paramètres
function TomoMod_Minimap.ApplySettings()
    if not TomoModDB.minimap.enabled then return end
    
    TomoMod_Minimap.MakeSquare()
    TomoMod_Minimap.CreateBorder()
    TomoMod_Minimap.ApplyScale()
    TomoMod_Minimap.SetupEditMode()
    RestorePosition()
end

-- Initialisation du module
function TomoMod_Minimap.Initialize()
    C_Timer.After(0.5, function()
        TomoMod_Minimap.ApplySettings()
    end)
end
-- =====================================
-- Compass.lua — Boussole de cap (« Waypoint 2.0 »)
-- =====================================
-- Une barre horizontale en haut de l'écran qui fait défiler les points
-- cardinaux (N / E / S / O) selon GetPlayerFacing(). Un marqueur d'azimut
-- pointe vers la quête super-suivie (la même cible que le beam de Waypoint)
-- et/ou vers un point de route utilisateur (C_Map user waypoint).
--
-- 100 % LECTURE SEULE — aucune fonction protégée n'est appelée, donc
-- AUCUN risque de taint (TWW/Midnight). On ne fait que LIRE l'orientation
-- et les positions, puis dessiner nos propres textures.
--
-- Intégré au système de placement unifié (Movers) et au GUI (onglet QOL).
-- =====================================

TomoMod_Compass = TomoMod_Compass or {}
local C = TomoMod_Compass

local pcall, ipairs = pcall, ipairs
local atan2  = math.atan2
local sqrt   = math.sqrt
local pi     = math.pi
local TWO_PI = pi * 2
local rad    = math.rad
local deg    = math.deg
local floor  = math.floor
local abs    = math.abs
local max    = math.max
local min    = math.min
local format = string.format

local GetPlayerFacing = GetPlayerFacing

-- =====================================
-- CONSTANTES
-- =====================================

local FONT       = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD  = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local SOLID      = "Interface\\BUTTONS\\WHITE8X8"

local TEAL       = { 0.047, 0.824, 0.624 }   -- point de route / accent
local AMBER      = { 0.937, 0.624, 0.153 }   -- quête suivie (#EF9F27)

-- Pas angulaire des graduations (en degrés). Cardinales = 0/90/180/270.
local TICK_STEP  = 15
-- Marge d'affichage au-delà du champ visible (pour que les graduations
-- entrent/sortent en douceur sous le clip).
local FOV_MARGIN = rad(6)

-- 8 libellés affichés sur la barre (sens horaire depuis le Nord).
-- Construits depuis les 4 lettres localisées dans BuildDirStrings().
local LABEL_BEARINGS = { 0, 45, 90, 135, 180, 225, 270, 315 }

-- =====================================
-- STATE
-- =====================================

local frame, stripClip
local ticks      = {}     -- { tex, bearingRad, isMajor }
local labels     = {}     -- { fs, bearingRad, isCardinal }
local centerLine, centerTri
local qMarker, wpMarker   -- marqueurs { head, headBack, stem, dist }
local headingFS
local dragOverlay, dragLabel
local isLocked   = true
local initialized = false
local L          = nil

local lastFacing = nil     -- pour ne repositionner les graduations que si le cap change
local elapsedAcc = 0
local THROTTLE   = 0.03    -- ~33 fps : rotation fluide, coût négligeable

local dir16      = nil     -- table des 16 abréviations (heading readout)
local labelText  = nil     -- table des 8 libellés de barre

-- Cache dérivé (recalculé dans ApplyDimensions)
local halfWidth  = 170
local fovRad     = rad(60)
local pixPerRad  = halfWidth / fovRad

-- =====================================
-- HELPERS
-- =====================================

local function DB()
    return TomoModDB and TomoModDB.compass
end

-- Normalise un angle dans (-pi, pi].
local function Normalize(a)
    while a > pi  do a = a - TWO_PI end
    while a <= -pi do a = a + TWO_PI end
    return a
end

-- Distance formatée en yards / km (cohérent avec le module Waypoint).
local function FormatDist(yds)
    if not yds or yds < 0 then return "" end
    yds = math.ceil(yds)
    if yds >= 1000 then
        return format("%.1f km", yds * 0.9144 / 1000)
    end
    return yds .. " yds"
end

-- Convertit une position de carte (0-1) en coordonnées monde (yards).
-- Renvoie wx, wy ou nil. +wx = Nord, +wy = Ouest (convention WoW).
local function MapToWorld(mapID, x, y)
    if not (mapID and C_Map and C_Map.GetWorldPosFromMapPos) then return nil end
    -- C_Map.GetWorldPosFromMapPos returns (continentID, worldPosition).
    -- pcall therefore returns (ok, continentID, worldPosition).
    local ok, _, worldPos = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x, y))
    if ok and worldPos and worldPos.GetXY then
        local wx, wy = worldPos:GetXY()
        if wx and wy then return wx, wy end
    end
    return nil
end

-- Construit les chaînes de direction depuis les 4 lettres cardinales localisées.
local function BuildDirStrings()
    local n = (L and L["compass_dir_n"]) or "N"
    local e = (L and L["compass_dir_e"]) or "E"
    local s = (L and L["compass_dir_s"]) or "S"
    local w = (L and L["compass_dir_w"]) or "W"

    -- 8 libellés de barre (sens horaire depuis le Nord)
    labelText = { n, n..e, e, s..e, s, s..w, w, n..w }

    -- 16 abréviations pour le readout de cap
    dir16 = {
        n, n..n..e, n..e, e..n..e,
        e, e..s..e, s..e, s..s..e,
        s, s..s..w, s..w, w..s..w,
        w, w..n..w, n..w, n..n..w,
    }
end

-- Abréviation 16 points pour un cap horaire (degrés 0-360).
local function HeadingLabel(headingDeg)
    if not dir16 then BuildDirStrings() end
    local idx = floor((headingDeg + 11.25) / 22.5) % 16
    return dir16[idx + 1] or ""
end

-- =====================================
-- POSITION
-- =====================================

local function SavePosition()
    local db = DB()
    if not db or not frame then return end
    local point, _, rp, x, y = frame:GetPoint()
    db.position = {
        point         = point or "TOP",
        relativePoint = rp    or "TOP",
        x             = x     or 0,
        y             = y     or -12,
    }
end

local function ApplyPosition()
    local db = DB()
    if not db or not frame then return end
    frame:ClearAllPoints()
    local p = db.position
    if p and p.point then
        frame:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, -12)
    end
end

-- =====================================
-- CRÉATION DES MARQUEURS
-- =====================================
-- Un marqueur = losange coloré (tête) + losange noir derrière (contraste)
-- + tige verticale traversant la barre + texte de distance dessous.

local function CreateMarker(color)
    local m = {}

    -- Losange de contraste (légèrement plus grand, noir)
    local back = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    back:SetColorTexture(0, 0, 0, 0.85)
    back:SetRotation(rad(45))
    m.headBack = back

    -- Losange coloré
    local head = frame:CreateTexture(nil, "ARTWORK", nil, 2)
    head:SetColorTexture(color[1], color[2], color[3], 1)
    head:SetRotation(rad(45))
    m.head = head

    -- Tige verticale (suit la tête horizontalement)
    local stem = frame:CreateTexture(nil, "ARTWORK", nil, 0)
    stem:SetColorTexture(color[1], color[2], color[3], 0.85)
    stem:SetPoint("TOP", head, "BOTTOM", 0, 2)
    m.stem = stem

    -- Distance (sous la barre, suit la tige)
    local dist = frame:CreateFontString(nil, "OVERLAY")
    dist:SetFont(FONT, 10, "OUTLINE")
    dist:SetTextColor(color[1], color[2], color[3])
    dist:SetPoint("TOP", stem, "BOTTOM", 0, -1)
    dist:SetJustifyH("CENTER")
    m.dist = dist

    return m
end

local function HideMarker(m)
    if not m then return end
    m.head:Hide(); m.headBack:Hide(); m.stem:Hide(); m.dist:Hide()
end

-- Place un marqueur à l'angle écran `a` (rad, +=droite), avec distance optionnelle.
local function PlaceMarker(m, a, distYds, showDist)
    local x = a * pixPerRad
    -- Le marqueur se colle au bord quand la cible sort du champ.
    if x >  halfWidth then x =  halfWidth end
    if x < -halfWidth then x = -halfWidth end

    m.head:ClearAllPoints()
    m.head:SetPoint("BOTTOM", frame, "TOP", x, 1)
    m.headBack:ClearAllPoints()
    m.headBack:SetPoint("CENTER", m.head, "CENTER", 0, 0)

    m.head:Show(); m.headBack:Show(); m.stem:Show()

    if showDist and distYds then
        m.dist:SetText(FormatDist(distYds))
        m.dist:Show()
    else
        m.dist:Hide()
    end
end

-- =====================================
-- CRÉATION DE LA BARRE
-- =====================================

local function CreateBar()
    if frame then return end
    local db = DB()
    if not db then return end

    frame = CreateFrame("Frame", "TomoMod_Compass", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(50)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(false)   -- activé seulement en mode placement

    frame:SetBackdrop({
        bgFile   = SOLID,
        edgeFile = SOLID,
        edgeSize = 1,
    })

    ApplyPosition()

    -- Sous-cadre clippé : contient les graduations + libellés (qui glissent et
    -- doivent être coupés proprement aux bords de la barre).
    stripClip = CreateFrame("Frame", nil, frame)
    stripClip:SetAllPoints(frame)
    if stripClip.SetClipsChildren then stripClip:SetClipsChildren(true) end

    -- Graduations (toutes les 15°)
    for d = 0, 359, TICK_STEP do
        local isMajor = (d % 90 == 0)        -- N/E/S/O
        local isMid   = (d % 45 == 0)        -- intercardinales
        local tex = stripClip:CreateTexture(nil, "ARTWORK")
        if isMajor then
            tex:SetColorTexture(1, 1, 1, 0.85)
        elseif isMid then
            tex:SetColorTexture(0.7, 0.7, 0.7, 0.6)
        else
            tex:SetColorTexture(0.5, 0.5, 0.5, 0.45)
        end
        ticks[#ticks + 1] = { tex = tex, bearingRad = rad(d), isMajor = isMajor, isMid = isMid }
    end

    -- 8 libellés (N, NE, E, SE, S, SO, O, NO)
    if not labelText then BuildDirStrings() end
    for i, bearing in ipairs(LABEL_BEARINGS) do
        local isCardinal = (bearing % 90 == 0)
        local fs = stripClip:CreateFontString(nil, "OVERLAY")
        fs:SetFont(isCardinal and FONT_BOLD or FONT, isCardinal and 13 or 10, "OUTLINE")
        if isCardinal then
            fs:SetTextColor(1, 1, 1)
        else
            fs:SetTextColor(0.6, 0.6, 0.6)
        end
        fs:SetText(labelText[i] or "")
        labels[#labels + 1] = { fs = fs, bearingRad = rad(bearing), isCardinal = isCardinal }
    end

    -- Repère central (là où regarde le joueur)
    centerLine = frame:CreateTexture(nil, "OVERLAY", nil, 1)
    centerLine:SetColorTexture(TEAL[1], TEAL[2], TEAL[3], 0.9)
    centerLine:SetPoint("CENTER", frame, "CENTER", 0, 0)

    centerTri = frame:CreateTexture(nil, "OVERLAY", nil, 2)
    centerTri:SetColorTexture(TEAL[1], TEAL[2], TEAL[3], 1)
    centerTri:SetRotation(rad(45))
    centerTri:SetPoint("CENTER", frame, "TOP", 0, 0)

    -- Marqueurs (créés après le repère central pour passer au-dessus)
    qMarker  = CreateMarker(AMBER)
    wpMarker = CreateMarker(TEAL)
    HideMarker(qMarker)
    HideMarker(wpMarker)

    -- Readout de cap (sous la barre, centré)
    headingFS = frame:CreateFontString(nil, "OVERLAY")
    headingFS:SetFont(FONT_BOLD, 12, "OUTLINE")
    headingFS:SetTextColor(0.85, 0.85, 0.85)
    headingFS:SetPoint("TOP", frame, "BOTTOM", 0, -3)

    -- Overlay de placement (capte le drag, couvre tout)
    dragOverlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    dragOverlay:SetAllPoints(frame)
    dragOverlay:SetBackdrop({
        bgFile   = SOLID,
        edgeFile = SOLID,
        edgeSize = 1,
    })
    dragOverlay:SetBackdropColor(TEAL[1], TEAL[2], TEAL[3], 0.18)
    dragOverlay:SetBackdropBorderColor(TEAL[1], TEAL[2], TEAL[3], 0.80)
    dragOverlay:SetFrameLevel(frame:GetFrameLevel() + 30)
    dragOverlay:EnableMouse(true)
    dragOverlay:RegisterForDrag("LeftButton")
    dragOverlay:SetScript("OnDragStart", function() frame:StartMoving() end)
    dragOverlay:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        SavePosition()
    end)

    dragLabel = dragOverlay:CreateFontString(nil, "OVERLAY")
    dragLabel:SetFont(FONT_BOLD, 10, "OUTLINE")
    dragLabel:SetPoint("CENTER")
    dragLabel:SetTextColor(TEAL[1], TEAL[2], TEAL[3])
    dragLabel:SetText((L and L["mover_compass"]) or "Compass")
    dragOverlay:Hide()

    frame:SetScript("OnUpdate", C._OnUpdate)
end

-- =====================================
-- DIMENSIONS (taille, échelle, champ visible)
-- =====================================

function C.ApplyDimensions()
    if not frame then return end
    local db = DB()
    if not db then return end

    local width  = db.width  or 340
    local height = db.height or 28
    local scale  = db.scale  or 1.0
    local bgA    = db.bgAlpha or 0.9

    frame:SetScale(scale)
    frame:SetSize(width, height)
    frame:SetBackdropColor(0.04, 0.04, 0.06, bgA)
    frame:SetBackdropBorderColor(0.12, 0.12, 0.14, 1)

    halfWidth = width / 2
    fovRad    = rad(db.fov or 60)
    pixPerRad = halfWidth / fovRad

    -- Graduations : hauteur selon importance
    local hMajor = height * 0.55
    local hMid   = height * 0.40
    local hMin   = height * 0.25
    for _, t in ipairs(ticks) do
        local h = t.isMajor and hMajor or (t.isMid and hMid or hMin)
        t.tex:SetSize(t.isMajor and 2 or 1, h)
    end

    -- Repère central
    centerLine:SetSize(2, height)
    centerTri:SetSize(height * 0.30, height * 0.30)

    -- Marqueurs : tige = hauteur de la barre, têtes proportionnelles
    local headQ = max(7, height * 0.34)
    local headW = max(6, height * 0.30)
    qMarker.head:SetSize(headQ, headQ)
    qMarker.headBack:SetSize(headQ + 2, headQ + 2)
    qMarker.stem:SetSize(2, height)
    wpMarker.head:SetSize(headW, headW)
    wpMarker.headBack:SetSize(headW + 2, headW + 2)
    wpMarker.stem:SetSize(2, height)

    -- Forcer un repositionnement complet au prochain tick
    lastFacing = nil
end

-- =====================================
-- POSITIONNEMENT DES GRADUATIONS / LIBELLÉS
-- =====================================

local function PositionStrip(facing)
    local fovVisible = fovRad + FOV_MARGIN

    for _, t in ipairs(ticks) do
        local a = Normalize(facing + t.bearingRad)
        if abs(a) <= fovVisible then
            local x = a * pixPerRad
            if x >  halfWidth then x =  halfWidth end
            if x < -halfWidth then x = -halfWidth end
            t.tex:ClearAllPoints()
            t.tex:SetPoint("TOP", stripClip, "TOP", x, 0)
            t.tex:Show()
        else
            t.tex:Hide()
        end
    end

    for _, l in ipairs(labels) do
        local a = Normalize(facing + l.bearingRad)
        if abs(a) <= fovVisible then
            local x = a * pixPerRad
            if x >  halfWidth then x =  halfWidth end
            if x < -halfWidth then x = -halfWidth end
            l.fs:ClearAllPoints()
            -- Cardinales un peu plus haut, intercardinales centrées plus bas
            local yOff = l.isCardinal and -2 or -4
            l.fs:SetPoint("CENTER", stripClip, "CENTER", x, yOff)
            l.fs:Show()
        else
            l.fs:Hide()
        end
    end
end

-- =====================================
-- RÉSOLUTION DES CIBLES (quête / point de route)
-- =====================================
-- Renvoie l'angle CCW monde (comparable à GetPlayerFacing) vers (tx,ty) sur la
-- carte mapID, depuis la position monde joueur (pwx,pwy). + distance en yards.
local function WorldAngleTo(mapID, tx, ty, pwx, pwy)
    if not (pwx and tx) then return nil end
    local twx, twy = MapToWorld(mapID, tx, ty)
    if not twx then return nil end
    local dx = twx - pwx   -- +Nord
    local dy = twy - pwy   -- +Ouest
    local angleCCW = atan2(dy, dx)             -- 0=N, pi/2=O (comme GetPlayerFacing)
    local dist = sqrt(dx * dx + dy * dy)
    return angleCCW, dist
end

-- =====================================
-- OnUpdate
-- =====================================

function C._OnUpdate(self, e)
    elapsedAcc = elapsedAcc + e
    if elapsedAcc < THROTTLE then return end
    elapsedAcc = 0

    local facing = GetPlayerFacing()
    if not facing then return end   -- nil en véhicule / carte ouverte : on gèle

    -- Graduations/libellés : ne bougent qu'avec le cap → on saute si inchangé.
    if not lastFacing or abs(facing - lastFacing) > 0.0035 then
        PositionStrip(facing)
        -- Readout de cap (boussole = sens horaire depuis le Nord)
        if headingFS then
            local headingDeg = deg((TWO_PI - facing) % TWO_PI)
            headingFS:SetText(format("%d\194\176 %s", floor(headingDeg + 0.5) % 360, HeadingLabel(headingDeg)))
        end
        lastFacing = facing
    end

    -- ── Marqueurs ──────────────────────────────────────────────────────
    local db = DB()
    if not db then return end

    -- Mode placement : marqueurs factices fixes
    if not isLocked then
        if db.showQuest    then PlaceMarker(qMarker,  rad(28), 230, db.showDistance) else HideMarker(qMarker) end
        if db.showWaypoint then PlaceMarker(wpMarker, rad(-52), 540, db.showDistance) else HideMarker(wpMarker) end
        if headingFS then headingFS:SetShown(db.showHeading ~= false) end
        return
    end

    if headingFS then headingFS:SetShown(db.showHeading ~= false) end

    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local pwx, pwy
    if mapID and C_Map.GetPlayerMapPosition then
        local ppos = C_Map.GetPlayerMapPosition(mapID, "player")
        if ppos then
            local px, py = ppos.x, ppos.y
            if px then pwx, pwy = MapToWorld(mapID, px, py) end
        end
    end

    local superQuest = false
    local superUserWP = false
    if C_SuperTrack then
        if C_SuperTrack.IsSuperTrackingUserWaypoint then superUserWP = C_SuperTrack.IsSuperTrackingUserWaypoint() end
        if C_SuperTrack.GetSuperTrackedQuestID then
            local qid = C_SuperTrack.GetSuperTrackedQuestID()
            superQuest = qid and qid ~= 0
        end
    end

    -- ── Marqueur QUÊTE (ambre) : cible super-suivie = beam ───────────────
    local qShown = false
    if db.showQuest and pwx and superQuest and not superUserWP
       and C_SuperTrack and C_SuperTrack.GetNextWaypointForMap then
        local qx, qy = C_SuperTrack.GetNextWaypointForMap(mapID)
        if qx then
            local angleCCW, dist = WorldAngleTo(mapID, qx, qy, pwx, pwy)
            if angleCCW then
                PlaceMarker(qMarker, Normalize(facing - angleCCW), dist, db.showDistance)
                qShown = true
            end
        end
    end
    if not qShown then HideMarker(qMarker) end

    -- ── Marqueur POINT DE ROUTE (teal) : user waypoint ──────────────────
    local wShown = false
    if db.showWaypoint and pwx and C_Map and C_Map.HasUserWaypoint and C_Map.HasUserWaypoint() then
        local uwp = C_Map.GetUserWaypoint and C_Map.GetUserWaypoint()
        if uwp and uwp.position and uwp.uiMapID == mapID then
            -- Point de route posé sur la carte courante → direction directe
            local ux, uy = uwp.position:GetXY()
            if ux then
                local angleCCW, dist = WorldAngleTo(mapID, ux, uy, pwx, pwy)
                if angleCCW then
                    PlaceMarker(wpMarker, Normalize(facing - angleCCW), dist, db.showDistance)
                    wShown = true
                end
            end
        elseif superUserWP and C_SuperTrack and C_SuperTrack.GetNextWaypointForMap then
            -- Point de route super-suivi (potentiellement cross-zone) → next step
            local qx, qy = C_SuperTrack.GetNextWaypointForMap(mapID)
            if qx then
                local angleCCW, dist = WorldAngleTo(mapID, qx, qy, pwx, pwy)
                if angleCCW then
                    PlaceMarker(wpMarker, Normalize(facing - angleCCW), dist, db.showDistance)
                    wShown = true
                end
            end
        end
    end
    if not wShown then HideMarker(wpMarker) end
end

-- =====================================
-- VISIBILITÉ
-- =====================================

local function UpdateVisibility()
    if not frame then return end
    local db = DB()
    if not db or not db.enabled then
        frame:Hide()
        return
    end
    frame:Show()
end

-- =====================================
-- LOCK / UNLOCK (Mover)
-- =====================================

local function SetLockedInternal(locked)
    isLocked = locked
    if not frame then return end

    if locked then
        if dragOverlay then dragOverlay:Hide() end
        frame:EnableMouse(false)
        UpdateVisibility()
    else
        -- Mode placement : toujours visible + overlay de drag
        frame:Show()
        frame:EnableMouse(true)
        if dragOverlay then dragOverlay:Show() end
    end
    lastFacing = nil   -- force un refresh complet
end

function C.SetLocked(locked) SetLockedInternal(locked) end
function C.ToggleLock() SetLockedInternal(not isLocked); return isLocked end
function C.IsLocked() return isLocked end

-- =====================================
-- APPLY SETTINGS (appelé depuis le GUI)
-- =====================================

function C.ApplySettings()
    if not frame then return end
    local db = DB()
    if not db then return end

    C.ApplyDimensions()
    UpdateVisibility()

    if dragLabel and L then
        dragLabel:SetText(L["mover_compass"] or "Compass")
    end

    -- Rafraîchir libellés (si la langue a changé) + repositionnement
    BuildDirStrings()
    for i, l in ipairs(labels) do
        l.fs:SetText(labelText[i] or "")
    end
    lastFacing = nil
end

-- =====================================
-- TOGGLE (slash /tm compass)
-- =====================================

function C.Toggle()
    if not TomoModDB then return end
    if not TomoModDB.compass then TomoModDB.compass = {} end
    TomoModDB.compass.enabled = not TomoModDB.compass.enabled
    UpdateVisibility()
    print("|cff0cd29fTomoMod Compass:|r " ..
        (TomoModDB.compass.enabled and "|cff00ff00ON|r" or "|cffff4040OFF|r"))
end

function C.Debug()
    local db = DB()
    print("|cff0cd29f=== TomoMod Compass debug ===|r")
    print("  enabled: " .. tostring(db and db.enabled))
    local f = GetPlayerFacing()
    print("  GetPlayerFacing(): " .. tostring(f))
    if f then
        print("  heading: " .. floor(deg((TWO_PI - f) % TWO_PI) + 0.5) .. "\194\176 " .. HeadingLabel(deg((TWO_PI - f) % TWO_PI)))
    end
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    print("  mapID: " .. tostring(mapID))
    if C_SuperTrack then
        print("  SuperTrackingAnything: " .. tostring(C_SuperTrack.IsSuperTrackingAnything and C_SuperTrack.IsSuperTrackingAnything()))
        print("  SuperTrackedQuestID: " .. tostring(C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID()))
        print("  SuperTrackingUserWaypoint: " .. tostring(C_SuperTrack.IsSuperTrackingUserWaypoint and C_SuperTrack.IsSuperTrackingUserWaypoint()))
    end
    print("  HasUserWaypoint: " .. tostring(C_Map and C_Map.HasUserWaypoint and C_Map.HasUserWaypoint()))
end

-- =====================================
-- EVENTS
-- =====================================

local function OnEvent(_, event)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        UpdateVisibility()
        lastFacing = nil
    end
end

-- =====================================
-- INITIALIZE
-- =====================================

function C.Initialize()
    if initialized then return end
    initialized = true

    L = TomoMod_L
    BuildDirStrings()

    CreateBar()
    C.ApplyDimensions()

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:RegisterEvent("PLAYER_LOGIN")
    ev:SetScript("OnEvent", OnEvent)

    UpdateVisibility()
end

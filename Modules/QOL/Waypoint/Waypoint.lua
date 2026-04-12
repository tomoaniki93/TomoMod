-- =====================================================================
-- Waypoint.lua — In-world waypoint system  (QOL Module)
-- Modules > QOL > Waypoint  |  /tm way [x y] | /tm way clear
--
-- Ported from WaypointUI (AdaptiveX) — MIT-compatible adaptation:
--   • MapPin   : C_Map / C_SuperTrack waypoint management
--   • Beacon   : teal circle + beam anchored to C_Navigation.GetFrame()
--   • Navigator: rotating edge-arrow when target is off-screen
--   • ArrivalTime: moving-average ETA
-- =====================================================================

local L               = TomoMod_L
local ADDON_FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local TEX_RING        = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Ring"
local TEX_ARROW       = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\arrow_right"
local TEX_SOLID       = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\solid"

-- ── Palette (matches TomoMod teal) ───────────────────────────────────
local TR, TG, TB = 0.047, 0.824, 0.624   -- accent teal (default, overridden by DB)
local WR, WG, WB = 0.92,  0.94,  0.92   -- near-white text

-- ── Layout ───────────────────────────────────────────────────────────
local BEACON_SIZE    = 32     -- icon diameter (px, default; DB overrides)
local BEACON_GLOW    = 56     -- outer glow ring
local BEAM_W         = 5      -- beam strip width
local BEAM_H         = 280    -- beam strip height
local ARROW_SIZE     = 38     -- navigator arrow
local ORBIT_DEFAULT  = 175    -- px from screen centre to arrow (at zoom ~35)
local CLAMP_EDGE     = 0.06   -- fraction of screen from edge = "clamped"
local SCALE_BASE_D   = 1800   -- distance (yds) where beacon is base-scale
local SCALE_MIN      = 0.35
local SCALE_MAX      = 2.20
local TICK           = 0.05   -- OnUpdate throttle (seconds)

-- ── Module ───────────────────────────────────────────────────────────
TomoMod_Waypoint = TomoMod_Waypoint or {}
local WP = TomoMod_Waypoint

-- ══ Frame Construction ═══════════════════════════════════════════════

-- Root: parented to WorldFrame so frames survive UIParent scale changes;
-- stays invisible itself.
local Root = CreateFrame("Frame", "TomoMod_WaypointRoot", WorldFrame)
Root:SetFrameStrata("BACKGROUND")
Root:SetFrameLevel(1)
Root:SetSize(1, 1)
Root:SetPoint("CENTER")
Root:Hide()

-- ── Beacon (shown when target is on-screen) ───────────────────────────
local Beacon = CreateFrame("Frame", nil, Root)
Beacon:SetSize(BEACON_SIZE, BEACON_SIZE)
Beacon:SetFrameLevel(3)
Beacon:Hide()

-- Outer glow ring
local BeaconGlow = Beacon:CreateTexture(nil, "BACKGROUND")
BeaconGlow:SetTexture(TEX_RING)
BeaconGlow:SetSize(BEACON_GLOW, BEACON_GLOW)
BeaconGlow:SetPoint("CENTER")
BeaconGlow:SetVertexColor(TR, TG, TB, 0.30)

-- Inner icon circle (solid teal disc)
local BeaconIcon = Beacon:CreateTexture(nil, "ARTWORK")
BeaconIcon:SetAllPoints()
BeaconIcon:SetTexture(TEX_RING)
BeaconIcon:SetVertexColor(TR, TG, TB, 0.90)

-- Teal dot at the very centre
local BeaconDot = Beacon:CreateTexture(nil, "OVERLAY")
BeaconDot:SetSize(6, 6)
BeaconDot:SetPoint("CENTER")
BeaconDot:SetColorTexture(1, 1, 1, 0.85)

-- Beam: vertical strip below the icon, fades to transparent at bottom
local Beam = Root:CreateTexture(nil, "BACKGROUND")
Beam:SetSize(BEAM_W, BEAM_H)
-- Position is updated dynamically (see UpdateBeam)
Beam:SetVertexColor(TR, TG, TB, 0.55)
Beam:Hide()

-- Beam gradient achieved with a second texture (alpha 0 at top)
local BeamFade = Root:CreateTexture(nil, "BACKGROUND")
BeamFade:SetSize(BEAM_W, BEAM_H)
BeamFade:SetColorTexture(0, 0, 0, 0)  -- transparent overlay; used to mask bottom
BeamFade:Hide()

-- Destination name text
local NameText = CreateFrame("Frame", nil, Root)
NameText:SetSize(200, 16)
NameText:Hide()
local NameFS = NameText:CreateFontString(nil, "OVERLAY")
NameFS:SetFont(ADDON_FONT_BOLD, 11, "OUTLINE")
NameFS:SetTextColor(WR, WG, WB, 1)
NameFS:SetShadowColor(0, 0, 0, 0.9)
NameFS:SetShadowOffset(1, -1)
NameFS:SetAllPoints()
NameFS:SetJustifyH("CENTER")

-- Distance text
local DistText = CreateFrame("Frame", nil, Root)
DistText:SetSize(160, 14)
DistText:Hide()
local DistFS = DistText:CreateFontString(nil, "OVERLAY")
DistFS:SetFont(ADDON_FONT, 10, "OUTLINE")
DistFS:SetTextColor(TR, TG, TB, 1)
DistFS:SetShadowColor(0, 0, 0, 0.8)
DistFS:SetShadowOffset(1, -1)
DistFS:SetAllPoints()
DistFS:SetJustifyH("CENTER")

-- ── Navigator (shown when target is off-screen) ───────────────────────
local Navigator = CreateFrame("Frame", nil, Root)
Navigator:SetSize(ARROW_SIZE, ARROW_SIZE)
Navigator:SetFrameLevel(3)
Navigator:Hide()

local NavArrow = Navigator:CreateTexture(nil, "ARTWORK")
NavArrow:SetAllPoints()
NavArrow:SetTexture(TEX_ARROW)
NavArrow:SetVertexColor(TR, TG, TB, 1)

-- Small dot on navigator arrow (direction indicator)
local NavDot = Navigator:CreateTexture(nil, "OVERLAY")
NavDot:SetSize(4, 4)
NavDot:SetPoint("CENTER")
NavDot:SetColorTexture(1, 1, 1, 0.7)

local NavDistFS = Navigator:CreateFontString(nil, "OVERLAY")
NavDistFS:SetFont(ADDON_FONT, 9, "OUTLINE")
NavDistFS:SetTextColor(WR, WG, WB, 0.9)
NavDistFS:SetShadowColor(0, 0, 0, 0.8)
NavDistFS:SetShadowOffset(1, -1)
NavDistFS:SetPoint("TOP", Navigator, "BOTTOM", 0, -2)

-- ══ State ════════════════════════════════════════════════════════════

local navFrame       = nil   -- C_Navigation.GetFrame()
local sessionName    = nil   -- destination label
local currentMode    = "HIDDEN"  -- "HIDDEN" | "WAYPOINT" | "NAVIGATOR"
local isActive       = false
local tickTimer      = 0
local waypointMapID  = nil   -- mapID of the active waypoint (for zone check)

-- ArrivalTime (moving-average ETA)
local atLastDist   = nil
local atLastTime   = nil
local atAvgSpeed   = nil
local atSeconds    = -1

-- Navigator smoothing
local navCurrX     = 0
local navCurrY     = 0
local navCurrAngle = 0

-- ══ Helper functions ═════════════════════════════════════════════════

local function GetNavFrameSafe()
    if C_Navigation and C_Navigation.GetFrame then
        local f = C_Navigation.GetFrame()
        if f then navFrame = f end
    end
    return navFrame
end

local function IsOffScreen(frame)
    if not frame then return true end
    local cx, cy = frame:GetCenter()
    if not cx then return true end
    local sw, sh = GetScreenWidth(), GetScreenHeight()
    if sw == 0 or sh == 0 then return false end
    local nx, ny = cx / sw, cy / sh
    return nx < CLAMP_EDGE or nx > (1 - CLAMP_EDGE)
        or ny < CLAMP_EDGE or ny > (1 - CLAMP_EDGE)
end

local function FormatDist(yds)
    if not yds or yds < 0 then return "" end
    yds = math.ceil(yds)
    if yds >= 1000 then
        return string.format("%.1f km", yds * 0.9144 / 1000)
    end
    return yds .. " yds"
end

local function FormatETA(secs)
    if secs <= 0 then return "" end
    if secs < 60 then return secs .. "s" end
    local m = math.floor(secs / 60)
    local s = secs % 60
    if m < 60 then return string.format("%dm%02ds", m, s) end
    return string.format("%dh%02dm", math.floor(m / 60), m % 60)
end

local function GetScaleForDist(d)
    if not d or d <= 0 then return SCALE_MAX end
    local s = SCALE_MAX * (SCALE_BASE_D / (d + SCALE_BASE_D * 0.1))
    return math.max(SCALE_MIN, math.min(SCALE_MAX, s))
end

local function UpdateArrivalTime(dist)
    if not dist or dist <= 0 then atSeconds = 0 return end
    local now = GetTime()
    if not atLastDist then atLastDist, atLastTime = dist, now return end
    local dt = now - atLastTime
    if dt < 0.1 then return end
    local dd = atLastDist - dist
    atLastDist, atLastTime = dist, now
    if dd <= 0 then atSeconds = -1 return end
    local speed = dd / dt
    atAvgSpeed = atAvgSpeed and (atAvgSpeed + 0.2 * (speed - atAvgSpeed)) or speed
    if atAvgSpeed < 0.5 then atSeconds = -1 return end
    atSeconds = math.floor(dist / atAvgSpeed + 0.5)
    if atSeconds > 86400 then atSeconds = -1 end
end

-- ══ Visual updates ═══════════════════════════════════════════════════

local function AnchorBeacon()
    if not navFrame then return end
    Beacon:ClearAllPoints()
    Beacon:SetPoint("CENTER", navFrame, "CENTER")
    -- Beam starts at bottom of icon and extends down
    Beam:ClearAllPoints()
    Beam:SetPoint("TOP", navFrame, "CENTER", 0, -BEACON_SIZE * 0.5)
    BeamFade:ClearAllPoints()
    BeamFade:SetPoint("TOP", Beam, "TOP")
    BeamFade:SetSize(BEAM_W, BEAM_H)
    -- Name + dist below beacon
    NameText:ClearAllPoints()
    NameText:SetPoint("TOP", navFrame, "CENTER", 0, -(BEACON_SIZE * 0.5 + 4))
    DistText:ClearAllPoints()
    DistText:SetPoint("TOP", NameText, "BOTTOM", 0, -1)
end

-- [PERF] Localize math functions used in hot path
local sqrt  = math.sqrt
local atan2 = math.atan2
local pi    = math.pi
local TWO_PI = 2 * pi

local _prevNavX, _prevNavY, _prevNavAngle = 0, 0, 0

local function UpdateNavigator()
    if not navFrame then return end
    local cx, cy = navFrame:GetCenter()
    if not cx then return end

    local ww, wh = WorldFrame:GetWidth(), WorldFrame:GetHeight()
    local screenCX = ww * 0.5
    local screenCY = wh * 0.5

    local dx = cx - screenCX
    local dy = cy - screenCY
    local len = sqrt(dx * dx + dy * dy)
    if len < 1 then return end

    -- Project to orbit circle
    local ratio = ORBIT_DEFAULT / len
    local tx = dx * ratio
    local ty = dy * ratio

    -- Smooth interpolation
    navCurrX = navCurrX + (tx - navCurrX) * 0.4
    navCurrY = navCurrY + (ty - navCurrY) * 0.4

    -- [PERF] Only call SetPoint if position changed significantly (>0.5px)
    local ddx = navCurrX - _prevNavX
    local ddy = navCurrY - _prevNavY
    if ddx * ddx + ddy * ddy > 0.25 then
        Navigator:ClearAllPoints()
        Navigator:SetPoint("CENTER", WorldFrame, "CENTER", navCurrX, navCurrY)
        _prevNavX, _prevNavY = navCurrX, navCurrY
    end

    -- Rotation: arrow_right points east (0°), we want it to point toward target
    -- atan2(dy,dx) gives angle from east; we subtract pi/2 because texture is east-pointing
    local targetAngle = atan2(dy, dx) - pi * 0.5
    local diff = targetAngle - navCurrAngle
    -- [PERF] Modulo-based normalization instead of while loops
    diff = ((diff + pi) % TWO_PI) - pi
    navCurrAngle = navCurrAngle + diff * 0.35

    -- [PERF] Only call SetRotation if angle changed significantly
    if navCurrAngle ~= _prevNavAngle then
        NavArrow:SetRotation(-navCurrAngle)
        _prevNavAngle = navCurrAngle
    end
end

-- ══ Mode management ══════════════════════════════════════════════════

function WP.SetMode(mode)
    if mode == currentMode then return end
    currentMode = mode

    if mode == "WAYPOINT" then
        Root:Show()
        Beacon:Show()
        Beam:Show()
        NameText:Show()
        DistText:Show()
        Navigator:Hide()
        navCurrX, navCurrY, navCurrAngle = 0, 0, 0  -- reset smoothing
    elseif mode == "NAVIGATOR" then
        Root:Show()
        Beacon:Hide()
        Beam:Hide()
        NameText:Hide()
        DistText:Hide()
        Navigator:Show()
    else  -- HIDDEN
        Root:Hide()
        Beacon:Hide()
        Beam:Hide()
        NameText:Hide()
        DistText:Hide()
        Navigator:Hide()
    end
end

-- ══ Tick (OnUpdate) ══════════════════════════════════════════════════

local Ticker = CreateFrame("Frame")
Ticker:SetScript("OnUpdate", function(_, elapsed)
    if not isActive then return end
    tickTimer = tickTimer + elapsed
    if tickTimer < TICK then return end
    tickTimer = 0

    local nf = GetNavFrameSafe()
    local dist = (C_Navigation and C_Navigation.GetDistance) and C_Navigation.GetDistance() or nil

    if not nf then
        WP.SetMode("HIDDEN")
        return
    end

    local offScreen = IsOffScreen(nf)
    local newMode = offScreen and "NAVIGATOR" or "WAYPOINT"
    WP.SetMode(newMode)

    if currentMode == "WAYPOINT" then
        AnchorBeacon()
        local scale = GetScaleForDist(dist)
        Beacon:SetScale(scale)
        if dist then
            UpdateArrivalTime(dist)
            local distStr = FormatDist(dist)
            local etaStr = atSeconds > 0 and ("  " .. FormatETA(atSeconds)) or ""
            DistFS:SetText(distStr .. etaStr)
        end
    elseif currentMode == "NAVIGATOR" then
        UpdateNavigator()
        if dist then
            NavDistFS:SetText(FormatDist(dist))
        end
    end
end)
Ticker:Hide()

-- ══ Activation ═══════════════════════════════════════════════════════

local function IsInWaypointZone()
    if not waypointMapID then return true end
    -- If the player has a valid position on the waypoint map, they are in that zone
    local pos = C_Map.GetPlayerMapPosition(waypointMapID, "player")
    return pos ~= nil
end

local function ShouldBeActive()
    if not C_SuperTrack then return false end
    if not C_SuperTrack.IsSuperTrackingAnything() then return false end
    -- Zone-only restriction
    local db = TomoModDB and TomoModDB.waypoint
    if db and db.zoneOnly and not IsInWaypointZone() then return false end
    local inInst, instType = IsInInstance()
    -- Active in open world; also allow in outdoor-style instances
    return not inInst or instType == "none"
end

local function SetActive(active)
    if active == isActive then return end
    isActive = active
    if active then
        navFrame = GetNavFrameSafe()
        if navFrame then AnchorBeacon() end
        WP.SetMode(navFrame and "WAYPOINT" or "NAVIGATOR")
        Ticker:Show()
    else
        Ticker:Hide()
        WP.SetMode("HIDDEN")
        -- Reset arrival time tracking
        atLastDist, atLastTime, atAvgSpeed = nil, nil, nil
        atSeconds = -1
    end
end

local function CheckActive()
    SetActive(ShouldBeActive())
end

-- Public wrapper used by the config UI
function WP.CheckActivePublic()
    CheckActive()
end

-- ── Event frame ───────────────────────────────────────────────────────
local EL = CreateFrame("Frame")
EL:RegisterEvent("SUPER_TRACKING_CHANGED")
EL:RegisterEvent("USER_WAYPOINT_UPDATED")
EL:RegisterEvent("ZONE_CHANGED_NEW_AREA")
EL:RegisterEvent("ZONE_CHANGED")
EL:RegisterEvent("PLAYER_ENTERING_WORLD")
EL:RegisterEvent("NAVIGATION_FRAME_CREATED")
EL:RegisterEvent("NAVIGATION_FRAME_DESTROYED")
EL:SetScript("OnEvent", function(_, event)
    if event == "NAVIGATION_FRAME_CREATED" then
        navFrame = GetNavFrameSafe()
        if isActive and navFrame then AnchorBeacon() end
    elseif event == "NAVIGATION_FRAME_DESTROYED" then
        navFrame = nil
    else
        CheckActive()
    end
end)

-- ══ Public API ═══════════════════════════════════════════════════════

--[[
    WP.NewWaypoint(name, mapID, x, y)
        Creates a user waypoint and super-tracks it.
        x, y are in map coordinates (0–100).
        Returns true on success.
]]
function WP.NewWaypoint(name, mapID, x, y)
    if not mapID or not x or not y then
        print("|cff0cd29fTomoMod Waypoint:|r " .. L["way_usage"])
        return false
    end
    -- Clamp to valid range
    if x < 0 or x > 100 or y < 0 or y > 100 then
        print("|cff0cd29fTomoMod Waypoint:|r " .. L["way_bad_coords"])
        return false
    end
    if not C_Map.CanSetUserWaypointOnMap(mapID) then
        print("|cff0cd29fTomoMod Waypoint:|r " .. L["way_bad_map"])
        return false
    end
    local pos = CreateVector2D(x / 100, y / 100)
    local mapPoint = UiMapPoint.CreateFromVector2D(mapID, pos)
    C_Map.SetUserWaypoint(mapPoint)
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    waypointMapID = mapID
    sessionName = name ~= "" and name or nil
    NameFS:SetText(sessionName or "")
    DistFS:SetText("")
    return true
end

--[[
    WP.ClearWaypoint()
        Removes the current waypoint and stops tracking.
]]
function WP.ClearWaypoint()
    if C_Map.HasUserWaypoint() then
        C_Map.ClearUserWaypoint()
    end
    if C_SuperTrack.IsSuperTrackingUserWaypoint() then
        C_SuperTrack.ClearAllSuperTracked()
    end
    sessionName = nil
    waypointMapID = nil
    SetActive(false)
    WP.SetMode("HIDDEN")
    print("|cff0cd29fTomoMod Waypoint:|r " .. L["way_cleared"])
end

--[[
    WP.NewWaypointHere([name])
        Places a waypoint at the player's current map position.
]]
function WP.NewWaypointHere(name)
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        print("|cff0cd29fTomoMod Waypoint:|r " .. L["way_no_map"])
        return false
    end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then
        print("|cff0cd29fTomoMod Waypoint:|r " .. L["way_no_pos"])
        return false
    end
    return WP.NewWaypoint(name or "", mapID, pos.x * 100, pos.y * 100)
end

-- ══ Slash command handler ═════════════════════════════════════════════

--[[
    /tm way             → waypoint at player position
    /tm way clear       → clear waypoint
    /tm way x y         → waypoint at (x, y) on current map
    /tm way x y name    → with label
    /tm way mapID x y   → on specific map
    /tm way mapID x y name → full form
]]
function WP.HandleSlashCommand(args)
    args = args or ""
    local parts = {}
    for p in args:gmatch("%S+") do parts[#parts + 1] = p end

    if #parts == 0 then
        -- No args: place here
        local ok = WP.NewWaypointHere()
        if ok then
            print("|cff0cd29fTomoMod Waypoint:|r " .. L["way_here"])
        end
        return
    end

    if parts[1] == "clear" or parts[1] == "off" then
        WP.ClearWaypoint()
        return
    end

    -- Detect: "x y [name...]" vs "mapID x y [name...]"
    local n1 = tonumber(parts[1])
    local n2 = tonumber(parts[2])
    local n3 = tonumber(parts[3])

    local mapID, x, y, nameStart
    if n1 and n2 and n3 then
        -- mapID x y [name...]
        mapID, x, y, nameStart = math.floor(n1), n2, n3, 4
    elseif n1 and n2 then
        -- x y [name...]
        mapID = C_Map.GetBestMapForUnit("player")
        x, y, nameStart = n1, n2, 3
    else
        print("|cff0cd29fTomoMod Waypoint:|r " .. L["way_usage"])
        return
    end

    local nameParts = {}
    for i = nameStart, #parts do nameParts[#nameParts + 1] = parts[i] end
    local name = #nameParts > 0 and table.concat(nameParts, " ") or nil

    local ok = WP.NewWaypoint(name or "", mapID, x, y)
    if ok then
        local coords = string.format("%.1f, %.1f", x, y)
        -- |T...|t arrow escape instead of Unicode em-dash (Poppins compatibility)
        local sep = name and (" |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t " .. name) or ""
        print(string.format("|cff0cd29fTomoMod Waypoint:|r " .. L["way_set"], coords, sep))
    end
end

-- ══ Apply Settings (color / shape / size) ════════════════════════════

function WP.ApplySettings()
    local db = TomoModDB and TomoModDB.waypoint
    local r = (db and db.color and db.color.r) or TR
    local g = (db and db.color and db.color.g) or TG
    local b = (db and db.color and db.color.b) or TB

    BeaconGlow:SetVertexColor(r, g, b, 0.30)
    BeaconIcon:SetVertexColor(r, g, b, 0.90)
    NavArrow:SetVertexColor(r, g, b, 1)
    Beam:SetVertexColor(r, g, b, 0.55)
    DistFS:SetTextColor(r, g, b, 1)

    -- Shape: ring or arrow
    local shape = (db and db.shape) or "ring"
    if shape == "arrow" then
        BeaconIcon:SetTexture(TEX_ARROW)
    else
        BeaconIcon:SetTexture(TEX_RING)
    end

    -- Size
    local sz = (db and db.beaconSize) or BEACON_SIZE
    Beacon:SetSize(sz, sz)
    local glowSz = sz * (BEACON_GLOW / BEACON_SIZE)
    BeaconGlow:SetSize(glowSz, glowSz)
end

-- ══ Initialize ═══════════════════════════════════════════════════════

function WP.Initialize()
    -- Fetch nav frame if super-tracking is already active
    navFrame = GetNavFrameSafe()
    if navFrame and isActive then AnchorBeacon() end
    -- Apply visual settings from DB
    WP.ApplySettings()
    -- Check if something is already being tracked on login
    CheckActive()
    -- Restore any persisted session label
    local db = TomoModDB and TomoModDB.waypoint
    if db and db.sessionName then
        sessionName = db.sessionName
        NameFS:SetText(sessionName)
    end
end

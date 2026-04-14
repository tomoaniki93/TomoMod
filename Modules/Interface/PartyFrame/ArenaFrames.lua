-- =====================================
-- PartyFrame/ArenaFrames.lua — Arena Enemy Frames
-- 2v2 / 3v3 with PvP trinket cooldown tracking
-- Uses ARENA_* events + C_PvP API (NO COMBAT_LOG_EVENT_UNFILTERED)
-- =====================================

TomoMod_ArenaFrames = TomoMod_ArenaFrames or {}
local AF = TomoMod_ArenaFrames

local pcall, pairs, ipairs = pcall, pairs, ipairs
local issecretvalue = issecretvalue
local UnitExists     = UnitExists
local UnitHealth     = UnitHealth
local UnitHealthMax  = UnitHealthMax
local UnitName       = UnitName
local UnitClass      = UnitClass
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitPower      = UnitPower
local UnitPowerMax   = UnitPowerMax
local UnitPowerType  = UnitPowerType
local GetTime        = GetTime

local ADDON_FONT    = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ADDON_TEXTURE = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"

-- State
AF.frames      = {}       -- [1..3] = arena1..arena3
AF.anchor      = nil
AF.isLocked    = true
AF.initialized = false

-- PvP Trinket CD: 120s
local TRINKET_CD = 120

-- =====================================
-- POWER COLORS (reuse from Core.lua)
-- =====================================
local POWER_COLORS = {
    [0]  = { r = 0.00, g = 0.00, b = 1.00 },
    [1]  = { r = 1.00, g = 0.00, b = 0.00 },
    [2]  = { r = 1.00, g = 0.50, b = 0.25 },
    [3]  = { r = 1.00, g = 1.00, b = 0.00 },
    [6]  = { r = 0.00, g = 0.82, b = 1.00 },
}

-- =====================================
-- CLASS COLOR
-- =====================================
local function GetClassColor(unit)
    if not unit or not UnitExists(unit) then return 0.8, 0.04, 0.04 end
    local _, cls = UnitClass(unit)
    if cls then
        local c = RAID_CLASS_COLORS[cls]
        if c then return c.r, c.g, c.b end
    end
    return 0.8, 0.04, 0.04
end

-- =====================================
-- CREATE ARENA FRAME
-- =====================================
function AF.CreateFrame(index)
    local db = TomoModDB and TomoModDB.partyFrames and TomoModDB.partyFrames.arena
    if not db then return end

    local unit = "arena" .. index
    local frameName = "TomoMod_Arena_" .. index

    local f = CreateFrame("Button", frameName, UIParent, "SecureUnitButtonTemplate, BackdropTemplate")
    f:SetSize(db.width or 160, db.height or 40)
    f.unit = unit
    f.index = index

    f:SetAttribute("unit", unit)
    f:SetAttribute("type1", "target")
    RegisterUnitWatch(f)

    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.04, 0.04, 0.06, 0.92)
    f:SetBackdropBorderColor(0.6, 0.04, 0.04, 0.8)

    local content = CreateFrame("Frame", nil, f)
    content:SetAllPoints()
    content:SetFrameLevel(f:GetFrameLevel() + 2)
    f.content = content

    local globalDB = TomoModDB.partyFrames
    local font     = globalDB.font or ADDON_FONT
    local fontSize = globalDB.fontSize or 11
    local outline  = globalDB.fontOutline or "OUTLINE"
    local texture  = globalDB.texture or ADDON_TEXTURE

    -- Health bar
    local health = CreateFrame("StatusBar", nil, f)
    health:SetPoint("TOPLEFT", 0, 0)
    health:SetPoint("TOPRIGHT", 0, 0)
    health:SetHeight((db.height or 40) - 3)
    health:SetStatusBarTexture(texture)
    health:SetMinMaxValues(0, 1)
    health:SetValue(1)
    health:SetFrameLevel(f:GetFrameLevel() + 1)
    f.health = health

    local healthBG = health:CreateTexture(nil, "BACKGROUND")
    healthBG:SetAllPoints()
    healthBG:SetColorTexture(0.08, 0.08, 0.10, 0.90)

    -- Power bar
    local power = CreateFrame("StatusBar", nil, f)
    power:SetPoint("BOTTOMLEFT", 0, 0)
    power:SetPoint("BOTTOMRIGHT", 0, 0)
    power:SetHeight(3)
    power:SetStatusBarTexture(texture)
    power:SetMinMaxValues(0, 1)
    power:SetValue(1)
    power:SetFrameLevel(f:GetFrameLevel() + 1)
    f.power = power

    local powerBG = power:CreateTexture(nil, "BACKGROUND")
    powerBG:SetAllPoints()
    powerBG:SetColorTexture(0.04, 0.04, 0.06, 0.90)

    -- Name text
    local nameText = content:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(font, fontSize, outline)
    nameText:SetPoint("LEFT", content, "LEFT", 4, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    nameText:SetWidth((db.width or 160) - 30)
    f.nameText = nameText

    -- Health text
    local healthText = content:CreateFontString(nil, "OVERLAY")
    healthText:SetFont(font, fontSize - 1, outline)
    healthText:SetPoint("RIGHT", content, "RIGHT", -4, 0)
    healthText:SetJustifyH("RIGHT")
    f.healthText = healthText

    -- Spec icon
    if db.showSpecIcon then
        local specIcon = content:CreateTexture(nil, "OVERLAY")
        specIcon:SetSize(16, 16)
        specIcon:SetPoint("TOPLEFT", content, "TOPLEFT", 2, -2)
        specIcon:Hide()
        f.specIcon = specIcon
    end

    -- Trinket icon (PvP trinket CD)
    if db.showTrinketCD then
        local trinketSize = db.trinketSize or 20
        local trinket = CreateFrame("Frame", nil, content, "BackdropTemplate")
        trinket:SetSize(trinketSize, trinketSize)
        trinket:SetPoint("LEFT", f, "RIGHT", 2, 0)
        trinket:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        trinket:SetBackdropColor(0.08, 0.08, 0.10, 0.9)
        trinket:SetBackdropBorderColor(0, 0, 0, 1)

        local trinketIcon = trinket:CreateTexture(nil, "ARTWORK")
        trinketIcon:SetAllPoints()
        trinketIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        trinketIcon:SetTexture("Interface\\Icons\\INV_Jewelry_TrinketPVP_01")
        trinket.icon = trinketIcon

        local trinketCD = CreateFrame("Cooldown", nil, trinket, "CooldownFrameTemplate")
        trinketCD:SetAllPoints()
        trinketCD:SetDrawEdge(false)
        trinketCD:SetSwipeColor(0, 0, 0, 0.6)
        trinket.cooldown = trinketCD

        local trinketText = trinket:CreateFontString(nil, "OVERLAY")
        trinketText:SetFont(font, 10, "OUTLINE")
        trinketText:SetPoint("CENTER", 0, 0)
        trinket.durationText = trinketText

        trinket:Show()
        f.trinket = trinket
    end

    f:SetFrameLevel(10)
    f:Hide()

    AF.frames[index] = f
    return f
end

-- =====================================
-- UPDATE: HEALTH
-- =====================================
function AF.UpdateHealth(f)
    if not f or not f.health or not f.unit then return end
    if not UnitExists(f.unit) then return end

    local cur = UnitHealth(f.unit)
    local max = UnitHealthMax(f.unit)

    f.health:SetMinMaxValues(0, max)
    f.health:SetValue(cur)

    local r, g, b = GetClassColor(f.unit)
    f.health:SetStatusBarColor(r, g, b, 1)

    if UnitIsDeadOrGhost(f.unit) then
        f.health:SetStatusBarColor(0.5, 0.5, 0.5, 0.6)
    end

    if f.healthText then
        local pct = (max > 0) and (cur / max * 100) or 0
        f.healthText:SetFormattedText("%.0f%%", pct)
    end
end

-- =====================================
-- UPDATE: POWER
-- =====================================
function AF.UpdatePower(f)
    if not f or not f.power then return end
    if not UnitExists(f.unit) then return end

    local pType = UnitPowerType(f.unit)
    local cur = UnitPower(f.unit)
    local max = UnitPowerMax(f.unit)

    f.power:SetMinMaxValues(0, max)
    f.power:SetValue(cur)

    local pc = POWER_COLORS[pType]
    if pc then
        f.power:SetStatusBarColor(pc.r, pc.g, pc.b, 1)
    else
        f.power:SetStatusBarColor(0.5, 0.5, 0.5, 1)
    end
end

-- =====================================
-- UPDATE: NAME
-- =====================================
function AF.UpdateName(f)
    if not f or not f.nameText then return end
    if not UnitExists(f.unit) then f.nameText:SetText(""); return end

    local name = UnitName(f.unit)
    if not name then f.nameText:SetText(""); return end

    local r, g, b = GetClassColor(f.unit)
    f.nameText:SetTextColor(r, g, b, 1)
    f.nameText:SetFormattedText("%s", name)
end

-- =====================================
-- UPDATE: TRINKET CD
-- =====================================
function AF.UpdateTrinket(f)
    if not f or not f.trinket then return end

    local db = TomoModDB and TomoModDB.partyFrames and TomoModDB.partyFrames.arena
    if not db or not db.showTrinketCD then f.trinket:Hide(); return end
    if not UnitExists(f.unit) then return end

    -- Use C_PvP API for arena CC/trinket data
    if C_PvP and C_PvP.GetArenaCrowdControlInfo then
        local ok, startTime, duration = pcall(C_PvP.GetArenaCrowdControlInfo, f.unit)
        if ok and startTime and duration and not issecretvalue(startTime) and duration > 0 then
            f.trinket.cooldown:SetCooldown(startTime, duration)
            local remaining = (startTime + duration) - GetTime()
            if remaining > 0 then
                f.trinket.durationText:SetText(string.format("%.0f", remaining))
                f.trinket.icon:SetDesaturated(true)
            else
                f.trinket.durationText:SetText("")
                f.trinket.icon:SetDesaturated(false)
            end
        else
            f.trinket.cooldown:Clear()
            f.trinket.durationText:SetText("")
            f.trinket.icon:SetDesaturated(false)
        end
    end
end

-- =====================================
-- FULL UPDATE
-- =====================================
function AF.UpdateFrame(f)
    if not f or not f.unit then return end
    AF.UpdateHealth(f)
    AF.UpdatePower(f)
    AF.UpdateName(f)
    AF.UpdateTrinket(f)
end

-- =====================================
-- LAYOUT FRAMES
-- =====================================
function AF.LayoutFrames()
    local db = TomoModDB and TomoModDB.partyFrames and TomoModDB.partyFrames.arena
    if not db or not AF.anchor then return end

    local spacing = db.spacing or 2
    for i, f in ipairs(AF.frames) do
        if f then
            f:ClearAllPoints()
            local offset = (i - 1) * ((db.height or 40) + spacing)
            f:SetPoint("TOPLEFT", AF.anchor, "TOPLEFT", 0, -offset)
            f:SetSize(db.width or 160, db.height or 40)
        end
    end
end

-- =====================================
-- CREATE ANCHOR
-- =====================================
function AF.CreateAnchor()
    local db = TomoModDB and TomoModDB.partyFrames and TomoModDB.partyFrames.arena
    if not db then return end

    local anchor = CreateFrame("Frame", "TomoMod_ArenaAnchor", UIParent)
    local totalH = (db.height or 40) * 3 + (db.spacing or 2) * 2
    anchor:SetSize(db.width or 160, totalH)

    local pos = db.position
    if pos and pos.point then
        anchor:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
    else
        anchor:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)
    end

    anchor:SetMovable(false)
    anchor:EnableMouse(false)

    -- Mover overlay
    local mover = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
    mover:SetAllPoints()
    mover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    mover:SetBackdropColor(0.8, 0.2, 0.2, 0.3)
    mover:SetBackdropBorderColor(0.8, 0.2, 0.2, 0.8)
    mover:SetFrameLevel(500)
    mover:EnableMouse(true)
    mover:RegisterForDrag("LeftButton")
    mover:SetScript("OnDragStart", function() anchor:StartMoving() end)
    mover:SetScript("OnDragStop", function()
        anchor:StopMovingOrSizing()
        local p, _, rp, x, y = anchor:GetPoint()
        if db then
            db.position = { point = p, relativePoint = rp, x = x, y = y }
        end
    end)

    local label = mover:CreateFontString(nil, "OVERLAY")
    label:SetFont(ADDON_FONT, 11, "OUTLINE")
    label:SetPoint("CENTER")
    label:SetText("Arena Frames")
    label:SetTextColor(0.8, 0.2, 0.2, 1)
    mover:Hide()
    anchor.moverOverlay = mover

    AF.anchor = anchor
end

-- =====================================
-- MOVER SYSTEM
-- =====================================
function AF.ToggleLock()
    AF.isLocked = not AF.isLocked
    if AF.anchor then
        AF.anchor:SetMovable(not AF.isLocked)
        AF.anchor:EnableMouse(not AF.isLocked)
        if not AF.isLocked then
            AF.anchor.moverOverlay:Show()
        else
            AF.anchor.moverOverlay:Hide()
            local db = TomoModDB and TomoModDB.partyFrames and TomoModDB.partyFrames.arena
            if db and AF.anchor then
                local p, _, rp, x, y = AF.anchor:GetPoint()
                db.position = { point = p, relativePoint = rp, x = x, y = y }
            end
        end
    end
end

function AF.IsLocked()
    return AF.isLocked
end

-- =====================================
-- EVENT HANDLER
-- =====================================
local eventFrame = CreateFrame("Frame")

local function OnEvent(self, event, arg1, ...)
    if not AF.initialized then return end

    if event == "ARENA_OPPONENT_UPDATE" then
        local unit = arg1
        local status = ...
        for _, f in ipairs(AF.frames) do
            if f and f.unit == unit then
                AF.UpdateFrame(f)
                break
            end
        end

    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        -- Update spec icons if available
        for i, f in ipairs(AF.frames) do
            if f and f.specIcon then
                local ok, specID = pcall(GetArenaOpponentSpec, i)
                if ok and specID and specID > 0 then
                    local _, _, _, icon = GetSpecializationInfoByID(specID)
                    if icon then
                        f.specIcon:SetTexture(icon)
                        f.specIcon:Show()
                    end
                end
            end
        end

    elseif event == "ARENA_COOLDOWNS_UPDATE" or event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" then
        for _, f in ipairs(AF.frames) do
            if f then AF.UpdateTrinket(f) end
        end

    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        for _, f in ipairs(AF.frames) do
            if f and f.unit == arg1 then
                AF.UpdateHealth(f)
                break
            end
        end

    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        for _, f in ipairs(AF.frames) do
            if f and f.unit == arg1 then
                AF.UpdatePower(f)
                break
            end
        end

    elseif event == "UNIT_NAME_UPDATE" then
        for _, f in ipairs(AF.frames) do
            if f and f.unit == arg1 then
                AF.UpdateName(f)
                break
            end
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, function()
            for _, f in ipairs(AF.frames) do
                if f and f:IsShown() then AF.UpdateFrame(f) end
            end
            AF.LayoutFrames()
        end)
    end
end

-- =====================================
-- TRINKET TICKER (0.5s)
-- =====================================
local trinketTicker = nil

function AF.StartTrinketTicker()
    if trinketTicker then return end
    trinketTicker = C_Timer.NewTicker(0.5, function()
        for _, f in ipairs(AF.frames) do
            if f and f:IsShown() then
                AF.UpdateTrinket(f)
            end
        end
    end)
end

function AF.StopTrinketTicker()
    if trinketTicker then trinketTicker:Cancel(); trinketTicker = nil end
end

-- =====================================
-- INITIALIZE
-- =====================================
function AF.Initialize()
    local db = TomoModDB and TomoModDB.partyFrames and TomoModDB.partyFrames.arena
    if not db or not db.enabled then return end

    AF.CreateAnchor()

    -- Create arena1..arena3
    for i = 1, 3 do
        AF.CreateFrame(i)
    end
    AF.LayoutFrames()

    -- Register events
    eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
    eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    eventFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
    eventFrame:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
    eventFrame:RegisterEvent("UNIT_HEALTH")
    eventFrame:RegisterEvent("UNIT_MAXHEALTH")
    eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
    eventFrame:RegisterEvent("UNIT_MAXPOWER")
    eventFrame:RegisterEvent("UNIT_NAME_UPDATE")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", OnEvent)

    AF.initialized = true
    AF.StartTrinketTicker()
end

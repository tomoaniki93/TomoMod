-- =====================================
-- Units/BossFrames.lua — Boss Unit Frames (boss1–boss5)
-- All 5 frames move together via boss1 drag handle.
-- Display: Name, Raid Marker (left), Health % only.
-- Bar color: Nameplate boss/miniboss classification colors.
-- =====================================

TomoMod_BossFrames = TomoMod_BossFrames or {}
local BF = TomoMod_BossFrames
local E = UF_Elements

local MAX_BOSSES = 5
local bossFrames = {}
local isLocked = true

-- =====================================
-- RAID ICON — C-side SetRaidTargetIconTexture
-- =====================================

local function UpdateRaidIcon(frame)
    if not frame or not frame.raidIcon then return end
    if not UnitExists(frame.unit) then
        frame.raidIcon:Hide()
        return
    end
    local index = GetRaidTargetIndex(frame.unit)
    if index then
        SetRaidTargetIconTexture(frame.raidIcon, index)
        frame.raidIcon:Show()
    else
        frame.raidIcon:Hide()
    end
end

-- =====================================
-- BOSS BAR COLOR
-- Uses nameplate classification colors:
--   worldboss → nameplates.colors.boss (red)
--   elite/rareelite → nameplates.colors.miniboss (purple)
--   fallback → nameplates.colors.hostile (red)
-- =====================================

local function GetBossBarColor(unit)
    local npDB = TomoModDB and TomoModDB.nameplates
    local colors = npDB and npDB.colors

    if not colors then return 0.85, 0.10, 0.10 end

    local classification = UnitClassification(unit)

    if classification == "worldboss" then
        local c = colors.boss or colors.hostile
        if c then return c.r, c.g, c.b end
    elseif classification == "elite" or classification == "rareelite" then
        local c = colors.miniboss or colors.elite or colors.hostile
        if c then return c.r, c.g, c.b end
    end

    -- Fallback: hostile color
    local c = colors.hostile or colors.enemyInCombat
    if c then return c.r, c.g, c.b end

    return 0.85, 0.10, 0.10
end

-- =====================================
-- HEALTH TEXT — Percent only (C-side safe)
-- =====================================

local ScaleTo100 = CurveConstants and CurveConstants.ScaleTo100

local function SetBossHealthText(fontString, unit)
    if not fontString or not unit then return end
    if not UnitExists(unit) then fontString:SetText(""); return end

    if UnitIsDead(unit) then
        fontString:SetText("Dead")
        return
    end

    -- Percent only via C-side SetFormattedText
    fontString:SetFormattedText("%d%%", UnitHealthPercent(unit, true, ScaleTo100))
end

-- =====================================
-- CREATE A SINGLE BOSS FRAME
-- =====================================

local function CreateBossFrame(bossIndex)
    local unit = "boss" .. bossIndex
    local db = TomoModDB.unitFrames.bossFrames
    if not db then return nil end

    local tex = TomoModDB.unitFrames.texture or "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
    local font = TomoModDB.unitFrames.fontFamily or TomoModDB.unitFrames.font or "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
    local fontSize = TomoModDB.unitFrames.fontSize or 12

    local width = db.width or 200
    local height = db.height or 28

    -- Main frame (SecureUnitButtonTemplate for click-targeting)
    local frame = CreateFrame("Button", "TomoMod_Boss_" .. bossIndex, UIParent, "SecureUnitButtonTemplate")
    frame:SetSize(width, height)
    frame.unit = unit
    frame.bossIndex = bossIndex
    frame:SetAttribute("unit", unit)
    frame:SetAttribute("type1", "target")
    frame:SetAttribute("type2", "togglemenu")
    frame:RegisterForClicks("AnyDown", "AnyUp")
    RegisterUnitWatch(frame)

    -- ===== Health Bar =====
    local health = CreateFrame("StatusBar", nil, frame)
    health:SetSize(width, height)
    health:SetPoint("TOP", frame, "TOP", 0, 0)
    health:SetStatusBarTexture(tex)
    health:GetStatusBarTexture():SetHorizTile(false)
    health:SetMinMaxValues(0, 100)
    health:SetValue(100)
    health:EnableMouse(false)

    -- Background
    local bg = health:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(tex)
    bg:SetVertexColor(0.12, 0.12, 0.15, 0.8)
    health.bg = bg

    -- Border
    E.CreateBorder(health)

    frame.health = health

    -- ===== Raid Icon (LEFT of name) =====
    local raidIcon = health:CreateTexture(nil, "OVERLAY")
    raidIcon:SetSize(16, 16)
    raidIcon:SetPoint("LEFT", health, "LEFT", 4, 0)
    raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    raidIcon:Hide()
    frame.raidIcon = raidIcon

    -- ===== Name text (left side, after potential raid icon space) =====
    local nameText = health:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(font, fontSize - 1, "OUTLINE")
    nameText:SetPoint("LEFT", health, "LEFT", 22, 0)
    nameText:SetTextColor(1, 1, 1, 0.95)
    nameText:SetJustifyH("LEFT")
    nameText:SetWidth(width * 0.55)
    nameText:SetWordWrap(false)
    nameText:SetNonSpaceWrap(false)
    frame.nameText = nameText

    -- ===== Health percent text (right side) =====
    local healthText = health:CreateFontString(nil, "OVERLAY")
    healthText:SetFont(font, fontSize, "OUTLINE")
    healthText:SetPoint("RIGHT", health, "RIGHT", -6, 0)
    healthText:SetTextColor(1, 1, 1, 1)
    healthText:SetJustifyH("RIGHT")
    frame.healthText = healthText

    return frame
end

-- =====================================
-- UPDATE FUNCTIONS
-- =====================================

local function UpdateBossFrame(frame)
    if not frame or not frame.unit then return end
    if not UnitExists(frame.unit) then return end

    local unit = frame.unit
    local db = TomoModDB.unitFrames.bossFrames
    if not db then return end

    -- Health bar (C-side: handles secret numbers)
    local current = UnitHealth(unit)
    local max = UnitHealthMax(unit)
    frame.health:SetMinMaxValues(0, max)
    frame.health:SetValue(current)

    -- Bar color (boss/miniboss classification from nameplates)
    local r, g, b = GetBossBarColor(unit)
    frame.health:SetStatusBarColor(r, g, b, 1)

    -- Name (C-side SetFormattedText for secret strings)
    local name = UnitName(unit)
    if name then
        frame.nameText:SetFormattedText("%s", name)
    else
        frame.nameText:SetText("")
    end

    -- Health text (percent only)
    SetBossHealthText(frame.healthText, unit)

    -- Raid icon
    UpdateRaidIcon(frame)
end

-- =====================================
-- POSITIONING (boss2–5 anchored below boss1)
-- =====================================

local function PositionBossFrames()
    local db = TomoModDB.unitFrames.bossFrames
    if not db then return end
    local spacing = db.spacing or 4

    -- Boss1 uses its saved position
    if bossFrames[1] then
        local pos = db.position
        if pos then
            bossFrames[1]:ClearAllPoints()
            bossFrames[1]:SetPoint(
                pos.point or "RIGHT",
                UIParent,
                pos.relativePoint or "RIGHT",
                pos.x or -80,
                pos.y or 200
            )
        end
    end

    -- Boss2–5 stack below boss1
    for i = 2, MAX_BOSSES do
        if bossFrames[i] and bossFrames[i - 1] then
            bossFrames[i]:ClearAllPoints()
            bossFrames[i]:SetPoint("TOP", bossFrames[i - 1], "BOTTOM", 0, -spacing)
        end
    end
end

-- =====================================
-- DRAG SYSTEM — Only boss1 is draggable; boss2–5 follow
-- =====================================

local function SetupBossDrag()
    local boss1 = bossFrames[1]
    if not boss1 then return end

    boss1:SetMovable(true)
    boss1:SetClampedToScreen(true)

    -- Create drag overlay (same pattern as UnitFrame.lua SetupDraggable)
    local dragFrame = CreateFrame("Frame", nil, boss1)
    dragFrame:SetAllPoints(boss1)
    dragFrame:SetFrameLevel(boss1:GetFrameLevel() + 20)
    dragFrame:EnableMouse(false)
    dragFrame:Hide()

    local dragOverlay = dragFrame:CreateTexture(nil, "OVERLAY")
    dragOverlay:SetAllPoints(dragFrame)
    dragOverlay:SetColorTexture(1, 1, 0, 0.1)

    local dragLabel = dragFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dragLabel:SetPoint("CENTER", dragFrame, "CENTER")
    dragLabel:SetTextColor(1, 1, 0)
    dragLabel:SetText("(Boss)")

    dragFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            boss1:StartMoving()
        end
    end)

    dragFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            boss1:StopMovingOrSizing()
            -- Save position
            local db = TomoModDB.unitFrames.bossFrames
            if db then
                local point, _, relativePoint, x, y = boss1:GetPoint()
                db.position = db.position or {}
                db.position.point = point
                db.position.relativePoint = relativePoint
                db.position.x = x
                db.position.y = y
            end
            -- Re-anchor boss2–5 below boss1
            PositionBossFrames()
        end
    end)

    boss1.dragFrame = dragFrame
    boss1.dragOverlay = dragOverlay
    boss1.dragLabel = dragLabel

    -- Boss2–5: not movable individually, just show overlay labels when unlocked
    for i = 2, MAX_BOSSES do
        local f = bossFrames[i]
        if f then
            f:SetMovable(false)
            local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("CENTER")
            label:SetTextColor(1, 1, 0, 0.7)
            label:SetText("Boss " .. i)
            label:Hide()
            f.lockLabel = label
        end
    end
end

-- =====================================
-- EVENTS
-- =====================================

local eventFrame = CreateFrame("Frame")
local bossEventFrames = {}

local bossEvents = {
    "UNIT_HEALTH", "UNIT_MAXHEALTH",
}

local function RegisterBossEvents()
    for i = 1, MAX_BOSSES do
        local unit = "boss" .. i
        if bossFrames[i] and not bossEventFrames[unit] then
            local uef = CreateFrame("Frame")
            for _, ev in ipairs(bossEvents) do
                uef:RegisterUnitEvent(ev, unit)
            end
            uef:SetScript("OnEvent", function(_, event, u)
                if bossFrames[i] and UnitExists(u) then
                    C_Timer.After(0, function() UpdateBossFrame(bossFrames[i]) end)
                end
            end)
            bossEventFrames[unit] = uef
        end
    end
end

-- Throttled update (boss health can change rapidly)
-- [PERF] Hidden by default, only shown when bosses are present
local updateTimer = 0
local throttleFrame = CreateFrame("Frame")
throttleFrame:Hide()
throttleFrame:SetScript("OnUpdate", function(self, elapsed)
    updateTimer = updateTimer + elapsed
    if updateTimer >= 0.15 then
        updateTimer = 0
        local hasBoss = false
        for i = 1, MAX_BOSSES do
            if bossFrames[i] and UnitExists("boss" .. i) then
                UpdateBossFrame(bossFrames[i])
                hasBoss = true
            end
        end
        if not hasBoss then
            self:Hide()
        end
    end
end)

-- Global events
eventFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
eventFrame:RegisterEvent("UNIT_TARGETABLE_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("RAID_TARGET_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" or event == "UNIT_TARGETABLE_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.1, function()
            local hasBoss = false
            for i = 1, MAX_BOSSES do
                if bossFrames[i] then
                    UpdateBossFrame(bossFrames[i])
                    if UnitExists("boss" .. i) then hasBoss = true end
                end
            end
            -- [PERF] Only enable throttle OnUpdate when bosses are present
            if hasBoss then
                throttleFrame:Show()
            else
                throttleFrame:Hide()
            end
        end)
    elseif event == "RAID_TARGET_UPDATE" then
        for i = 1, MAX_BOSSES do
            if bossFrames[i] then
                UpdateRaidIcon(bossFrames[i])
            end
        end
    end
end)

-- =====================================
-- PUBLIC API
-- =====================================

function BF.ToggleLock()
    isLocked = not isLocked

    for i = 1, MAX_BOSSES do
        local frame = bossFrames[i]
        if frame then
            if not isLocked then
                -- Unlock: show all frames for positioning
                UnregisterUnitWatch(frame)
                frame:Show()

                if i == 1 and frame.dragFrame then
                    frame.dragFrame:EnableMouse(true)
                    frame.dragFrame:Show()
                elseif frame.lockLabel then
                    frame.lockLabel:Show()
                end
            else
                -- Lock: re-register unit watch
                frame:SetAttribute("unit", "boss" .. i)
                RegisterUnitWatch(frame)

                if i == 1 and frame.dragFrame then
                    frame.dragFrame:EnableMouse(false)
                    frame.dragFrame:Hide()
                elseif frame.lockLabel then
                    frame.lockLabel:Hide()
                end

                if UnitExists("boss" .. i) then
                    UpdateBossFrame(frame)
                end
            end
        end
    end
end

function BF.RefreshAll()
    local db = TomoModDB.unitFrames.bossFrames
    if not db then return end

    local font = TomoModDB.unitFrames.fontFamily or TomoModDB.unitFrames.font or "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
    local fontSize = TomoModDB.unitFrames.fontSize or 12

    for i = 1, MAX_BOSSES do
        local frame = bossFrames[i]
        if frame then
            frame:SetSize(db.width, db.height)
            frame.health:SetSize(db.width, db.height)

            -- Update fonts
            if frame.nameText then
                frame.nameText:SetFont(font, fontSize - 1, "OUTLINE")
                frame.nameText:SetWidth(db.width * 0.55)
            end
            if frame.healthText then
                frame.healthText:SetFont(font, fontSize, "OUTLINE")
            end

            -- Update raid icon position
            if frame.raidIcon then
                frame.raidIcon:ClearAllPoints()
                frame.raidIcon:SetPoint("LEFT", frame.health, "LEFT", 4, 0)
            end

            UpdateBossFrame(frame)
        end
    end

    PositionBossFrames()
end

function BF.Initialize()
    if not TomoModDB or not TomoModDB.unitFrames then return end
    if not TomoModDB.unitFrames.enabled then return end

    local db = TomoModDB.unitFrames.bossFrames
    if not db or not db.enabled then return end

    -- Create 5 boss frames
    for i = 1, MAX_BOSSES do
        bossFrames[i] = CreateBossFrame(i)
    end

    -- Position them
    PositionBossFrames()

    -- Setup drag (boss1 only)
    SetupBossDrag()

    -- Register per-unit events
    RegisterBossEvents()

    print("|cff0cd29fTomoMod Boss:|r " .. TomoMod_L["msg_boss_initialized"])
end

-- =====================================
-- MODULE REGISTRATION
-- =====================================

TomoMod_RegisterModule("bossFrames", BF)

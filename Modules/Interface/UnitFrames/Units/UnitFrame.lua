-- =====================================
-- Units/UnitFrame.lua — Main UnitFrame Engine
-- Supports: player, target, targettarget, pet, focus
-- =====================================

TomoMod_UnitFrames = TomoMod_UnitFrames or {}
local UF = TomoMod_UnitFrames
local E = UF_Elements

local frames = {}
local isLocked = true

-- =====================================
-- TWW SECRET NUMBER STRATEGY (same as oUF / Ellesmere):
-- StatusBar:SetMinMaxValues() and SetValue() are C-side
-- widget methods that accept "secret numbers" natively.
-- For text display, use C-side functions:
--   AbbreviateLargeNumbers()  — Blizzard C-side
--   UnitHealthPercent()       — TWW API
--   string.format("%d", val)  — C-side format
-- NO tonumber(), NO C_Timer.After(0) needed.
-- =====================================

-- =====================================
-- RAID ICON COORDS
-- =====================================
local raidIconCoords = {
    [1] = { 0, 0.25, 0, 0.25 },        -- Star
    [2] = { 0.25, 0.5, 0, 0.25 },       -- Circle
    [3] = { 0.5, 0.75, 0, 0.25 },       -- Diamond
    [4] = { 0.75, 1, 0, 0.25 },         -- Triangle
    [5] = { 0, 0.25, 0.25, 0.5 },       -- Moon
    [6] = { 0.25, 0.5, 0.25, 0.5 },     -- Square
    [7] = { 0.5, 0.75, 0.25, 0.5 },     -- Cross
    [8] = { 0.75, 1, 0.25, 0.5 },       -- Skull
}

-- =====================================
-- CREATE A UNIT FRAME
-- =====================================

local function CreateUnitFrame(unit, settings)
    local frame = CreateFrame("Button", "TomoMod_UF_" .. unit, UIParent, "SecureUnitButtonTemplate")
    frame:SetSize(settings.width, settings.healthHeight + (settings.powerHeight or 0))
    frame.unit = unit
    frame:SetAttribute("unit", unit)
    frame:SetAttribute("type1", "target")
    frame:SetAttribute("type2", "togglemenu")
    frame:RegisterForClicks("AnyDown", "AnyUp")
    RegisterUnitWatch(frame)

    -- Health
    frame.health = E.CreateHealth(frame, unit, settings)

    -- Power
    if settings.powerHeight and settings.powerHeight > 0 then
        frame.power = E.CreatePower(frame, unit, settings)
        if frame.power then
            frame.power:SetPoint("TOP", frame.health, "BOTTOM", 0, 0)
        end
    end

    -- Absorb (player only by default)
    if settings.showAbsorb then
        frame.absorb = E.CreateAbsorb(frame, frame.health, settings)
    end

    -- Threat indicator
    if settings.showThreat then
        frame.threat = E.CreateThreatIndicator(frame.health)
    end

    -- Castbar
    if settings.castbar and settings.castbar.enabled then
        frame.castbar = E.CreateCastbar(frame, unit, settings)
    end

    -- Auras
    if settings.auras and settings.auras.enabled then
        frame.auraContainer = E.CreateAuraContainer(frame, unit, settings)
    end

    -- Position: anchor to another frame or to UIParent
    if settings.anchorTo and frames[settings.anchorTo] then
        local pos = settings.position
        frame:ClearAllPoints()
        frame:SetPoint(
            pos.point or "TOPLEFT",
            frames[settings.anchorTo],
            pos.relativePoint or "TOPRIGHT",
            pos.x or 8,
            pos.y or 0
        )
    elseif settings.position then
        frame:ClearAllPoints()
        frame:SetPoint(
            settings.position.point or "CENTER",
            UIParent,
            settings.position.relativePoint or "CENTER",
            settings.position.x or 0,
            settings.position.y or 0
        )
    end

    -- Draggable
    TomoMod_Utils.SetupDraggable(frame, function()
        local point, _, relativePoint, x, y = frame:GetPoint()
        settings.position = settings.position or {}
        settings.position.point = point
        settings.position.relativePoint = relativePoint
        settings.position.x = x
        settings.position.y = y
    end)

    return frame
end

-- =====================================
-- UPDATE FUNCTIONS
-- SetMinMaxValues/SetValue are C-side and accept secret numbers.
-- SetHealthText uses SetFormattedText (C-side) — zero tainted Lua strings.
-- =====================================

local function UpdateHealth(frame)
    if not frame or not frame.health or not frame.unit then return end
    if not UnitExists(frame.unit) then return end

    local unit = frame.unit
    local settings = TomoModDB.unitFrames[unit]
    if not settings then return end

    local current = UnitHealth(unit)
    local max = UnitHealthMax(unit)

    -- C-side widget methods — accept secret numbers natively
    frame.health:SetMinMaxValues(0, max)
    frame.health:SetValue(current)

    -- Color
    local r, g, b = E.GetHealthColor(unit, settings)
    frame.health:SetStatusBarColor(r, g, b, 1)

    -- Health text (SetHealthText uses C-side SetFormattedText — zero Lua taint)
    if settings.showHealthText and frame.health.text then
        E.SetHealthText(frame.health.text, current, max, settings.healthTextFormat, unit)
        if frame.health.nameText then
            frame.health.nameText:Show()
        end
    else
        frame.health.text:SetText("")
    end
end

local function UpdateAbsorb(frame)
    if not frame or not frame.absorb then return end
    if not UnitExists(frame.unit) then return end

    local absorb = UnitGetTotalAbsorbs(frame.unit)
    local max = UnitHealthMax(frame.unit)

    -- C-side widget methods — accept secret numbers natively
    frame.absorb:SetMinMaxValues(0, max)
    frame.absorb:SetValue(absorb)
    -- Always show; at value 0 the bar is visually empty (no Lua comparison needed)
    frame.absorb:Show()
end

local function UpdateName(frame)
    if not frame or not frame.health or not frame.health.nameText then return end
    if not UnitExists(frame.unit) then return end

    local settings = TomoModDB.unitFrames[frame.unit]
    if not settings or not settings.showName then
        frame.health.nameText:SetText("")
        return
    end

    -- Color
    if UnitIsPlayer(frame.unit) then
        local r, g, b = TomoMod_Utils.GetClassColor(frame.unit)
        frame.health.nameText:SetTextColor(r, g, b, 1)
    else
        frame.health.nameText:SetTextColor(1, 1, 1, 0.95)
    end

    -- TWW: UnitName = secret string, UnitLevel = secret number.
    -- SetFormattedText is C-side, handles both.
    local name = UnitName(frame.unit)
    if not name then frame.health.nameText:SetText(""); return end

    if settings.showLevel then
        -- Combined format: "90 - Tomo" — both secrets handled C-side
        local level = UnitLevel(frame.unit)
        frame.health.nameText:SetFormattedText("%d - %s", level, name)
        -- Hide separate levelText since info is combined
        if frame.health.levelText then
            frame.health.levelText:SetText("")
        end
    else
        frame.health.nameText:SetFormattedText("%s", name)
    end
end

local function UpdateLevel(frame)
    if not frame or not frame.health or not frame.health.levelText then return end
    if not UnitExists(frame.unit) then return end

    local settings = TomoModDB.unitFrames[frame.unit]
    if not settings or not settings.showLevel then
        frame.health.levelText:SetText("")
        return
    end

    -- If showName is also enabled, level is shown combined in nameText ("90 - Tomo")
    if settings.showName then
        frame.health.levelText:SetText("")
        return
    end

    -- Level only (no name) — SetFormattedText handles secret numbers C-side
    local level = UnitLevel(frame.unit)
    frame.health.levelText:SetTextColor(1, 0.82, 0, 0.9)
    frame.health.levelText:SetFormattedText("%d", level)
end

local function UpdateThreat(frame)
    if not frame or not frame.threat then return end
    if not UnitExists(frame.unit) then
        frame.threat:Hide()
        return
    end

    local settings = TomoModDB.unitFrames[frame.unit]
    if not settings or not settings.showThreat then
        frame.threat:Hide()
        return
    end

    local status = UnitThreatSituation("player", frame.unit)
    if status and status >= 2 then
        local r, g, b = GetThreatStatusColor(status)
        frame.threat:SetThreatColor(r, g, b)
        frame.threat:Show()
    else
        frame.threat:Hide()
    end
end

local function UpdateRaidIcon(frame)
    if not frame or not frame.health or not frame.health.raidIcon then return end

    local settings = TomoModDB.unitFrames[frame.unit]
    if not settings or not settings.showRaidIcon then
        frame.health.raidIcon:Hide()
        return
    end

    if not UnitExists(frame.unit) then
        frame.health.raidIcon:Hide()
        return
    end

    -- TWW: GetRaidTargetIndex returns a secret number — can't use as Lua table key.
    -- SetRaidTargetIconTexture is C-side and accepts secret numbers.
    local index = GetRaidTargetIndex(frame.unit)
    if index then
        SetRaidTargetIconTexture(frame.health.raidIcon, index)
        frame.health.raidIcon:Show()
    else
        frame.health.raidIcon:Hide()
    end
end

local function UpdateLeaderIcon(frame)
    if not frame or not frame.health or not frame.health.leaderIcon then return end

    local settings = TomoModDB.unitFrames[frame.unit]
    if not settings or not settings.showLeaderIcon then
        frame.health.leaderIcon:Hide()
        return
    end

    if not UnitExists(frame.unit) then
        frame.health.leaderIcon:Hide()
        return
    end

    if UnitIsGroupLeader(frame.unit) then
        frame.health.leaderIcon:Show()
    else
        frame.health.leaderIcon:Hide()
    end
end

local function UpdateFrame(frame)
    if not frame then return end
    UpdateHealth(frame)
    UpdateAbsorb(frame)
    if frame.power then E.UpdatePower(frame) end
    UpdateName(frame)
    UpdateLevel(frame)
    UpdateThreat(frame)
    UpdateRaidIcon(frame)
    UpdateLeaderIcon(frame)
    E.UpdateAuras(frame)
end

-- =====================================
-- EVENTS
-- Use per-unit event frames with RegisterUnitEvent to ONLY fire for our tracked units.
-- Global RegisterEvent("UNIT_HEALTH") fires for ALL units including
-- Blizzard's arena/raid frames, tainting their execution context and breaking Edit Mode.
-- =====================================

local eventFrame = CreateFrame("Frame")

-- Global events (no unit arg, safe)
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("RAID_TARGET_UPDATE")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PARTY_LEADER_CHANGED")

-- Unit event handler (called from per-unit frames)
local function HandleUnitEvent(event, unit)
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        if frames[unit] then
            local f = frames[unit]
            C_Timer.After(0, function() UpdateHealth(f) end)
        end
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        if frames[unit] and frames[unit].power then
            local f = frames[unit]
            C_Timer.After(0, function() E.UpdatePower(f) end)
        end
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        if frames[unit] and frames[unit].absorb then
            local f = frames[unit]
            C_Timer.After(0, function() UpdateAbsorb(f) end)
        end
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" then
        if frames[unit] then UpdateThreat(frames[unit]) end
    elseif event == "UNIT_AURA" then
        if frames[unit] then
            local f = frames[unit]
            C_Timer.After(0, function() E.UpdateAuras(f) end)
        end
    end
end

-- Per-unit event registration (called after frames are created)
local unitEventFrames = {}
local unitEvents = {
    "UNIT_HEALTH", "UNIT_MAXHEALTH",
    "UNIT_POWER_UPDATE", "UNIT_MAXPOWER",
    "UNIT_ABSORB_AMOUNT_CHANGED",
    "UNIT_THREAT_SITUATION_UPDATE",
    "UNIT_AURA",
}

local function RegisterUnitEvents()
    for unit, _ in pairs(frames) do
        if not unitEventFrames[unit] then
            local uef = CreateFrame("Frame")
            for _, ev in ipairs(unitEvents) do
                uef:RegisterUnitEvent(ev, unit)
            end
            uef:SetScript("OnEvent", function(_, event, u)
                HandleUnitEvent(event, u)
            end)
            unitEventFrames[unit] = uef
        end
    end
end

eventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0, function()
            for _, f in pairs(frames) do UpdateFrame(f) end
        end)
    elseif event == "PLAYER_TARGET_CHANGED" then
        C_Timer.After(0, function()
            if frames.target then UpdateFrame(frames.target) end
            if frames.targettarget then UpdateFrame(frames.targettarget) end
        end)
    elseif event == "PLAYER_FOCUS_CHANGED" then
        C_Timer.After(0, function()
            if frames.focus then UpdateFrame(frames.focus) end
        end)
    elseif event == "UNIT_PET" then
        if frames.pet then
            C_Timer.After(0, function() UpdateFrame(frames.pet) end)
        end
    elseif event == "RAID_TARGET_UPDATE" then
        for _, f in pairs(frames) do UpdateRaidIcon(f) end
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LEADER_CHANGED" then
        for _, f in pairs(frames) do UpdateLeaderIcon(f) end
    end
end)

-- Throttled update for ToT (no dedicated event)
local updateTimer = 0
local throttleFrame = CreateFrame("Frame")
throttleFrame:SetScript("OnUpdate", function(self, elapsed)
    updateTimer = updateTimer + elapsed
    if updateTimer >= 0.15 then
        updateTimer = 0
        if frames.targettarget then UpdateFrame(frames.targettarget) end
    end
end)

-- =====================================
-- HIDE BLIZZARD FRAMES
-- =====================================

local function HideBlizzardFrames()
    -- Unit frames — hide but don't override Show (Edit Mode needs to manage these)
    local blizzFrames = { PlayerFrame, TargetFrame, FocusFrame, PetFrame }
    for _, f in ipairs(blizzFrames) do
        if f then
            f:UnregisterAllEvents()
            f:Hide()
            -- Move offscreen instead of overriding Show (Edit Mode compatible)
            f:ClearAllPoints()
            f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -9999, 9999)
            f:SetAlpha(0)
        end
    end

    -- Castbar (TWW: PlayerCastingBarFrame, PetCastingBarFrame)
    for _, castName in ipairs({ "PlayerCastingBarFrame", "PetCastingBarFrame" }) do
        local castFrame = _G[castName]
        if castFrame then
            castFrame:UnregisterAllEvents()
            castFrame:Hide()
            castFrame:ClearAllPoints()
            castFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -9999, 9999)
            castFrame:SetAlpha(0)
        end
    end
end

-- =====================================
-- PUBLIC API
-- =====================================

function UF.ToggleLock()
    isLocked = not isLocked

    for unit, frame in pairs(frames) do
        if frame.SetLocked then
            frame:SetLocked(isLocked)
        end

        if not isLocked then
            -- Unlock: remove unit watch so frame stays visible for dragging
            UnregisterUnitWatch(frame)
            frame:Show()
            if frame.auraContainer then
                frame.auraContainer:EnableMouse(true)
                frame.auraContainer:Show()
            end
        else
            -- Lock: re-register unit watch for proper visibility
            frame:SetAttribute("unit", unit)
            RegisterUnitWatch(frame)
            if frame.auraContainer then
                frame.auraContainer:EnableMouse(false)
            end
            if UnitExists(unit) then
                UpdateFrame(frame)
            end
        end
    end

    if isLocked then
        print("|cff0cd29fTomoMod UF:|r " .. TomoMod_L["msg_uf_locked"])
    else
        print("|cff0cd29fTomoMod UF:|r " .. TomoMod_L["msg_uf_unlocked"])
    end
end

function UF.RefreshUnit(unitKey)
    local frame = frames[unitKey]
    local settings = TomoModDB.unitFrames[unitKey]
    if not frame or not settings then return end

    frame:SetSize(settings.width, settings.healthHeight + (settings.powerHeight or 0))
    frame.health:SetSize(settings.width, settings.healthHeight)

    if frame.power and settings.powerHeight then
        frame.power:SetSize(settings.width, settings.powerHeight)
    end

    if frame.castbar and settings.castbar then
        frame.castbar:SetSize(settings.castbar.width, settings.castbar.height)
    end

    -- Apply element offsets if defined
    local offsets = settings.elementOffsets
    if offsets then
        -- Name text
        if frame.health.nameText and offsets.name then
            frame.health.nameText:ClearAllPoints()
            frame.health.nameText:SetPoint("LEFT", offsets.name.x, offsets.name.y)
        end
        -- Level text
        if frame.health.levelText and offsets.level then
            frame.health.levelText:ClearAllPoints()
            frame.health.levelText:SetPoint("RIGHT", offsets.level.x, offsets.level.y)
        end
        -- Health text
        if frame.health.text and offsets.healthText then
            frame.health.text:ClearAllPoints()
            frame.health.text:SetPoint("CENTER", offsets.healthText.x, offsets.healthText.y)
        end
        -- Power bar
        if frame.power and offsets.power then
            frame.power:ClearAllPoints()
            frame.power:SetPoint("TOP", frame.health, "BOTTOM", offsets.power.x, offsets.power.y)
        end
        -- Castbar
        if frame.castbar and settings.castbar and offsets.castbar then
            local cbPos = settings.castbar.position
            if cbPos then
                frame.castbar:ClearAllPoints()
                frame.castbar:SetPoint(
                    cbPos.point or "TOP",
                    frame,
                    cbPos.relativePoint or "BOTTOM",
                    (cbPos.x or 0) + offsets.castbar.x,
                    (cbPos.y or -6) + offsets.castbar.y
                )
            end
        end
        -- Auras
        if frame.auraContainer and offsets.auras then
            local auraPos = settings.auras and settings.auras.position
            if auraPos then
                frame.auraContainer:ClearAllPoints()
                frame.auraContainer:SetPoint(
                    auraPos.point or "BOTTOMLEFT",
                    frame,
                    auraPos.relativePoint or "TOPLEFT",
                    (auraPos.x or 0) + offsets.auras.x,
                    (auraPos.y or 6) + offsets.auras.y
                )
            end
        end
    end

    -- Leader icon offset
    if frame.health and frame.health.leaderIcon and settings.leaderIconOffset then
        local ofs = settings.leaderIconOffset
        frame.health.leaderIcon:ClearAllPoints()
        frame.health.leaderIcon:SetPoint("BOTTOMLEFT", frame.health, "TOPLEFT", ofs.x, ofs.y)
    end

    -- Resize aura icons if size changed
    if frame.auraContainer and frame.auraContainer.icons and settings.auras then
        local auraSize = settings.auras.size or 30
        local spacing = settings.auras.spacing or 3
        frame.auraContainer:SetSize(300, auraSize + 4)
        for idx, icon in ipairs(frame.auraContainer.icons) do
            icon:SetSize(auraSize, auraSize)
            if icon.texture then icon.texture:SetAllPoints(icon) end
            -- Reposition
            icon:ClearAllPoints()
            if idx == 1 then
                icon:SetPoint("LEFT", 0, 0)
            else
                icon:SetPoint("LEFT", frame.auraContainer.icons[idx - 1], "RIGHT", spacing, 0)
            end
        end
    end

    UpdateFrame(frame)
end

function UF.Initialize()
    if not TomoModDB or not TomoModDB.unitFrames then return end
    if not TomoModDB.unitFrames.enabled then return end

    local buildOrder = { "player", "target", "focus", "targettarget", "pet" }

    for _, unit in ipairs(buildOrder) do
        local settings = TomoModDB.unitFrames[unit]
        if settings and settings.enabled then
            frames[unit] = CreateUnitFrame(unit, settings)
        end
    end

    -- Handle anchored frames (ToT → Target, Pet → Player)
    for _, unit in ipairs({ "targettarget", "pet" }) do
        local settings = TomoModDB.unitFrames[unit]
        if settings and settings.anchorTo and frames[settings.anchorTo] and frames[unit] then
            local pos = settings.position
            frames[unit]:ClearAllPoints()
            frames[unit]:SetPoint(
                pos.point or "TOPLEFT",
                frames[settings.anchorTo],
                pos.relativePoint or "TOPRIGHT",
                pos.x or 8,
                pos.y or 0
            )
        end
    end

    -- Hide Blizzard
    if TomoModDB.unitFrames.hideBlizzardFrames then
        HideBlizzardFrames()
    end

    -- Register per-unit events (after frames table is populated)
    RegisterUnitEvents()

    -- Start aura duration updater
    E.StartAuraDurationUpdater(frames)

    print("|cff0cd29fTomoMod UF:|r " .. TomoMod_L["msg_uf_initialized"])
end

-- =====================================
-- MODULE REGISTRATION
-- =====================================

TomoMod_RegisterModule("unitFrames", UF)

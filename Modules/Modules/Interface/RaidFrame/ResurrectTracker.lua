-- =====================================
-- RaidFrame/ResurrectTracker.lua
--   (1) Per-unit RESURRECTION INDICATOR on party AND raid frames:
--       UnitHasIncomingResurrection(unit) → shows a rez icon while a res cast
--       (combat-res or normal) is incoming on that member. Event-driven.
--   (2) Standalone BATTLE-REZ COUNTER HUD: reads the SHARED combat-resurrection
--       charge pool via C_Spell.GetSpellCharges(20484) — readable from ANY class
--       inside instanced content — so you can see how many brez are available
--       and a MM:SS countdown to the next charge. Movable (unified mover system).
--
-- 100% read-only / no taint:
--   * No arithmetic on secret values: pool fields are issecretvalue-guarded and
--     reported as "no pool" if secret.
--   * No Show/Hide hooks on protected frames; the counter is a plain UIParent
--     child and the per-unit icon is a plain child of each frame's content.
--   * No COMBAT_LOG_EVENT_UNFILTERED.
-- Loaded from RaidFrame.xml (so TomoMod_PartyFrames AND TomoMod_RaidFrames both
-- exist) and initialized after RaidFrames in Init.lua.
-- =====================================

TomoMod_ResurrectTracker = TomoMod_ResurrectTracker or {}
local RT = TomoMod_ResurrectTracker

local pairs, pcall, type, tostring = pairs, pcall, type, tostring
local issecretvalue = issecretvalue
local GetTime = GetTime
local UnitExists = UnitExists
local UnitHasIncomingResurrection = UnitHasIncomingResurrection
local IsInInstance = IsInInstance
local CreateFrame = CreateFrame
local floor = math.floor
local smax = math.max

local REBIRTH_SPELLID = 20484
local RES_ICON  = "Interface\\RaidFrame\\RaidFrame-Icon-Rez"
local BREZ_ICON = "Interface\\Icons\\Spell_Nature_Rebirth"
local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local SOLID     = "Interface\\Buttons\\WHITE8X8"
local TEAL  = { 0.047, 0.824, 0.624 }
local GREEN = { 0.30, 0.90, 0.40 }
local RED   = { 0.85, 0.25, 0.25 }

-- =====================================
-- SHARED BATTLE-REZ CHARGE POOL READER
-- C_Spell.GetSpellCharges(20484) returns the pooled combat-res charges and is
-- readable from any class while in instanced content (nil elsewhere — that is
-- the natural visibility gate). Secret-value guarded.
-- Returns: current, max, cooldownStartTime, cooldownDuration  (or nil).
-- =====================================
function RT.GetBrezCharges()
    if not (C_Spell and C_Spell.GetSpellCharges) then return nil end
    local info = C_Spell.GetSpellCharges(REBIRTH_SPELLID)
    if type(info) ~= "table" then return nil end
    local cur, maxC  = info.currentCharges, info.maxCharges
    local start, dur = info.cooldownStartTime, info.cooldownDuration
    if issecretvalue and (issecretvalue(cur) or issecretvalue(maxC)
        or issecretvalue(start) or issecretvalue(dur)) then
        return nil
    end
    return cur, maxC, start, dur
end

-- =====================================
-- BATTLE-REZ COUNTER HUD
-- =====================================
local brezFrame  = nil
local brezTicker = nil
local isLocked   = true

local function DB()
    return TomoModDB and TomoModDB.battleRez
end

local function SavePosition()
    local db = DB()
    if not db or not brezFrame then return end
    -- GetLeft/GetBottom (never GetPoint after a drag) → re-anchor to BOTTOMLEFT.
    local l, b = brezFrame:GetLeft(), brezFrame:GetBottom()
    if not l or not b then return end
    db.position = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = l, y = b }
end

local function ApplyPosition()
    local db = DB()
    if not brezFrame then return end
    brezFrame:ClearAllPoints()
    local p = db and db.position
    if p and p.point then
        brezFrame:SetPoint(p.point, UIParent, p.relativePoint or p.point, p.x or 0, p.y or 0)
    else
        brezFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end
end

local function FmtTime(sec)
    if not sec or sec < 0 then sec = 0 end
    if sec >= 60 then
        return string.format("%d:%02d", floor(sec / 60), floor(sec % 60))
    end
    return string.format("%d", floor(sec + 0.5))
end

local function CreateBrezFrame()
    if brezFrame then return end
    local db = DB() or {}
    local size = db.size or 44

    brezFrame = CreateFrame("Frame", "TomoMod_BattleRezCounter", UIParent, "BackdropTemplate")
    brezFrame:SetSize(size, size)
    brezFrame:SetFrameStrata("MEDIUM")
    brezFrame:SetMovable(true)
    brezFrame:SetClampedToScreen(true)
    brezFrame:SetBackdrop({
        bgFile   = SOLID,
        edgeFile = SOLID,
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    brezFrame:SetBackdropColor(0.05, 0.05, 0.06, 0.85)
    brezFrame:SetBackdropBorderColor(TEAL[1], TEAL[2], TEAL[3], 0.9)

    local ico = brezFrame:CreateTexture(nil, "ARTWORK")
    ico:SetPoint("TOPLEFT", 2, -2)
    ico:SetPoint("BOTTOMRIGHT", -2, 2)
    ico:SetTexture(BREZ_ICON)
    ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- trim the default icon border
    brezFrame.icon = ico

    local cd = CreateFrame("Cooldown", nil, brezFrame, "CooldownFrameTemplate")
    cd:SetAllPoints(ico)
    cd:SetDrawEdge(false)
    if cd.SetHideCountdownNumbers then cd:SetHideCountdownNumbers(true) end
    if cd.SetSwipeColor then cd:SetSwipeColor(0, 0, 0, 0.7) end
    brezFrame.cooldown = cd

    -- charge count (bottom-right)
    local count = brezFrame:CreateFontString(nil, "OVERLAY")
    count:SetFont(FONT, db.fontSize or 18, "OUTLINE")
    count:SetPoint("BOTTOMRIGHT", brezFrame, "BOTTOMRIGHT", -2, 2)
    count:SetText("")
    brezFrame.count = count

    -- recharge timer (centered)
    local timer = brezFrame:CreateFontString(nil, "OVERLAY")
    timer:SetFont(FONT, smax(9, (db.fontSize or 18) - 4), "OUTLINE")
    timer:SetPoint("CENTER", brezFrame, "CENTER", 0, 0)
    timer:SetText("")
    timer:SetTextColor(1, 1, 1)
    brezFrame.timer = timer

    -- drag handling (placement mode only — guarded by isLocked)
    brezFrame:RegisterForDrag("LeftButton")
    brezFrame:SetScript("OnDragStart", function(self) if not isLocked then self:StartMoving() end end)
    brezFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    brezFrame:EnableMouse(false)

    local dl = brezFrame:CreateFontString(nil, "OVERLAY")
    dl:SetFont(FONT, 9, "OUTLINE")
    dl:SetPoint("TOP", brezFrame, "BOTTOM", 0, -2)
    dl:SetTextColor(TEAL[1], TEAL[2], TEAL[3])
    dl:SetText((TomoMod_L and TomoMod_L["mover_battlerez"]) or "Battle Rez")
    dl:Hide()
    brezFrame.dragLabel = dl

    ApplyPosition()
    brezFrame:Hide()
end

function RT.UpdateBrezCounter()
    if not brezFrame then return end
    local db = DB()

    -- Placement mode: always show a representative state, ignore the gates.
    if not isLocked then
        brezFrame:Show()
        brezFrame.icon:SetDesaturated(false)
        brezFrame.count:SetText("2")
        brezFrame.count:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
        brezFrame.timer:SetText("")
        brezFrame.cooldown:Clear()
        return
    end

    if not db or not db.enabled then
        brezFrame:Hide()
        return
    end

    local cur, maxC, start, dur = RT.GetBrezCharges()
    if cur == nil then
        -- No shared pool (not in instanced content / unreadable).
        brezFrame:Hide()
        return
    end
    if db.onlyInstance then
        local inInstance = IsInInstance()
        if not inInstance then brezFrame:Hide(); return end
    end

    brezFrame:Show()
    maxC = maxC or cur

    brezFrame.count:SetText(tostring(cur))
    if cur > 0 then
        brezFrame.count:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
        brezFrame.icon:SetDesaturated(false)
    else
        brezFrame.count:SetTextColor(RED[1], RED[2], RED[3])
        brezFrame.icon:SetDesaturated(true)
    end

    local recharging = (cur < maxC) and start and dur and start > 0 and dur > 0
    if recharging then
        local remaining = (start + dur) - GetTime()
        if remaining < 0 then remaining = 0 end
        brezFrame.timer:SetText(FmtTime(remaining))
        if db.showSwipe ~= false and cur <= 0 then
            brezFrame.cooldown:SetCooldown(start, dur)
        else
            brezFrame.cooldown:Clear()
        end
    else
        brezFrame.timer:SetText("")
        brezFrame.cooldown:Clear()
    end
end

function RT.StartTicker()
    if brezTicker then return end
    -- 0.5s is enough for a smooth MM:SS countdown; the body is a single charge
    -- query + a couple of SetText calls, and no-ops quickly when there's no pool.
    brezTicker = C_Timer.NewTicker(0.5, function()
        RT.UpdateBrezCounter()
    end)
end

function RT.StopTicker()
    if brezTicker then brezTicker:Cancel(); brezTicker = nil end
end

-- =====================================
-- LOCK / UNLOCK (mover placement mode)
-- =====================================
function RT.SetLocked(locked)
    isLocked = locked and true or false
    if not brezFrame then return end
    if isLocked then
        brezFrame:EnableMouse(false)
        if brezFrame.dragLabel then brezFrame.dragLabel:Hide() end
    else
        brezFrame:EnableMouse(true)
        brezFrame:Show()
        if brezFrame.dragLabel then brezFrame.dragLabel:Show() end
    end
    RT.UpdateBrezCounter()
end

function RT.ToggleLock() RT.SetLocked(not isLocked); return isLocked end
function RT.IsLocked() return isLocked end

-- =====================================
-- APPLY SETTINGS (config live-update)
-- =====================================
function RT.ApplySettings()
    local db = DB()
    if brezFrame and db then
        local size = db.size or 44
        brezFrame:SetSize(size, size)
        if brezFrame.count then brezFrame.count:SetFont(FONT, db.fontSize or 18, "OUTLINE") end
        if brezFrame.timer then brezFrame.timer:SetFont(FONT, smax(9, (db.fontSize or 18) - 4), "OUTLINE") end
        ApplyPosition()
    end
    RT.UpdateBrezCounter()
    RT.UpdateResurrect()
end

-- =====================================
-- PER-UNIT RESURRECTION INDICATOR
-- A plain Frame + OVERLAY texture on each frame's content, lazily created.
-- Show/Hide on a non-secure child is combat-safe (battle-reses happen in combat).
-- =====================================
local function EnsureResIcon(f)
    if f.tomoResIcon then return f.tomoResIcon end
    local parent = f.content or f
    local ico = CreateFrame("Frame", nil, parent)
    ico:SetFrameLevel((parent:GetFrameLevel() or 0) + 15)
    ico:SetPoint("CENTER", f, "CENTER", 0, 0)
    local tex = ico:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetDrawLayer("OVERLAY", 7)
    tex:SetTexture(RES_ICON)
    ico.texture = tex
    ico:Hide()
    f.tomoResIcon = ico
    return ico
end

local function UpdateOneFrame(f, db)
    if not f or not f.unit then return end
    if not db or not db.showResurrectIndicator then
        if f.tomoResIcon then f.tomoResIcon:Hide() end
        return
    end
    if not f:IsShown() or not UnitExists(f.unit) then
        if f.tomoResIcon then f.tomoResIcon:Hide() end
        return
    end
    local incoming = false
    if UnitHasIncomingResurrection then
        local ok, res = pcall(UnitHasIncomingResurrection, f.unit)
        if ok and res then incoming = true end
    end
    if incoming then
        local ico = EnsureResIcon(f)
        local size = db.resurrectIconSize or 22
        ico:SetSize(size, size)
        ico:Show()
    elseif f.tomoResIcon then
        f.tomoResIcon:Hide()
    end
end

function RT.UpdateResurrect()
    local PF = TomoMod_PartyFrames
    if PF and PF.frames then
        local pdb = TomoModDB and TomoModDB.partyFrames
        for _, f in pairs(PF.frames) do
            UpdateOneFrame(f, pdb)
        end
    end
    local RF = TomoMod_RaidFrames
    if RF and RF.frames then
        local rdb = TomoModDB and TomoModDB.raidFrames
        for _, f in pairs(RF.frames) do
            UpdateOneFrame(f, rdb)
        end
    end
end

-- =====================================
-- EVENTS
-- =====================================
local function OnEvent(_, event)
    if event == "INCOMING_RESURRECT_CHANGED" then
        RT.UpdateResurrect()
    elseif event == "SPELL_UPDATE_CHARGES" or event == "SPELL_UPDATE_COOLDOWN"
        or event == "ENCOUNTER_START" or event == "ENCOUNTER_END" then
        RT.UpdateBrezCounter()
    else
        RT.UpdateResurrect()
        RT.UpdateBrezCounter()
    end
end

-- =====================================
-- INITIALIZE
-- =====================================
function RT.Initialize()
    if RT.initialized then return end
    RT.initialized = true

    CreateBrezFrame()

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("INCOMING_RESURRECT_CHANGED")
    ev:RegisterEvent("GROUP_ROSTER_UPDATE")
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    ev:RegisterEvent("SPELL_UPDATE_CHARGES")
    ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    ev:RegisterEvent("ENCOUNTER_START")
    ev:RegisterEvent("ENCOUNTER_END")
    ev:SetScript("OnEvent", OnEvent)
    RT.eventFrame = ev

    RT.StartTicker()

    -- Register with the unified mover system (/tm layout)
    if TomoMod_Movers and TomoMod_Movers.RegisterEntry then
        TomoMod_Movers.RegisterEntry({
            label    = (TomoMod_L and TomoMod_L["mover_battlerez"]) or "Battle Rez",
            unlock   = function() if RT.IsLocked() then RT.SetLocked(false) end end,
            lock     = function() if not RT.IsLocked() then RT.SetLocked(true) end end,
            isActive = function()
                return TomoModDB and TomoModDB.battleRez and TomoModDB.battleRez.enabled
            end,
        })
    end

    C_Timer.After(0.2, function()
        RT.UpdateBrezCounter()
        RT.UpdateResurrect()
    end)
end

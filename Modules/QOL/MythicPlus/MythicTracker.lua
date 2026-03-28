-- =====================================================================
-- MythicTracker.lua — Mythic+ Dungeon Tracker (integrated from TomoMythic)
-- Replaces Blizzard's M+ objective tracker with a custom dark panel:
--   header (dungeon name, key level, affixes, deaths),
--   timer bar with chest countdowns,
--   forces bar,
--   boss kill timers,
--   completion banner.
-- =====================================================================

local L = TomoMod_L
local TMT = {}
TomoMod_MythicTracker = TMT

-- ═══════════════════════════════════════════════════════════════════════
--  COLOR PALETTE (matches TomoMod dark UI)
-- ═══════════════════════════════════════════════════════════════════════
TMT.C = {
    BG          = { 0.00, 0.00, 0.00, 0.80 },
    BG_HEADER   = { 0.04, 0.08, 0.16, 1.00 },
    BG_ROW_ALT  = { 0.05, 0.09, 0.16, 0.50 },
    ACCENT      = { 0.33, 0.70, 0.00, 1.00 },
    BORDER      = { 0.25, 0.25, 0.30, 0.70 },
    BORDER_BLUE = { 0.15, 0.32, 0.60, 0.90 },
    SEP         = { 0.18, 0.38, 0.18, 0.80 },
    BAR_GREEN   = { 0.33, 0.70, 0.00, 0.90 },
    BAR_YELLOW  = { 0.95, 0.78, 0.00, 0.90 },
    BAR_RED     = { 0.85, 0.15, 0.10, 0.90 },
    BAR_BLUE    = { 0.15, 0.38, 0.72, 0.85 },
    BAR_TEAL    = { 0.10, 0.68, 0.72, 0.85 },
    BAR_TRACK   = { 0.04, 0.08, 0.14, 1.00 },
    TEXT_WHITE  = { 1.00, 1.00, 1.00, 1.00 },
    TEXT_GREY   = { 0.55, 0.55, 0.55, 1.00 },
    TEXT_GREEN  = { 0.55, 0.90, 0.20, 1.00 },
    TEXT_YELLOW = { 1.00, 0.82, 0.10, 1.00 },
    TEXT_RED    = { 1.00, 0.30, 0.20, 1.00 },
    TEXT_TEAL   = { 0.30, 0.85, 0.90, 1.00 },
    TEXT_SKULL  = { 1.00, 0.35, 0.30, 1.00 },
    TEXT_BLUE   = { 0.50, 0.72, 1.00, 1.00 },
}

-- ═══════════════════════════════════════════════════════════════════════
--  LAYOUT CONSTANTS
-- ═══════════════════════════════════════════════════════════════════════
TMT.W           = 260
TMT.HEADER_H    = 38
TMT.BAR_H       = 20
TMT.BOSS_H      = 18
TMT.GAP         = 2
TMT.EDGE        = 1
TMT.UPDATE_RATE  = 0.25

-- ═══════════════════════════════════════════════════════════════════════
--  DB ACCESS
-- ═══════════════════════════════════════════════════════════════════════
local function GetDB()
    return TomoModDB and TomoModDB.MythicTracker
end

-- ═══════════════════════════════════════════════════════════════════════
--  FONT / UTILITY HELPERS
-- ═══════════════════════════════════════════════════════════════════════
function TMT:GetFont(size, flags)
    return "Fonts\\FRIZQT__.TTF", size or 12, flags or "OUTLINE"
end

function TMT:FormatTime(sec, doCeil)
    if not sec then return "--:--" end
    if doCeil then sec = math.ceil(sec) else sec = math.floor(sec) end
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s)
    else          return string.format("%d:%02d", m, s) end
end

function TMT:FormatDelta(diff)
    local sign = diff >= 0 and "+" or "-"
    return sign .. self:FormatTime(math.abs(diff))
end

function TMT:MakeBG(parent, r, g, b, a)
    local t = parent:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints(parent)
    t:SetColorTexture(r, g, b, a)
    return t
end

function TMT:MakeBorder(parent, r, g, b, a, size)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetAllPoints(parent)
    f:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = size or TMT.EDGE })
    f:SetBackdropBorderColor(r, g, b, a or 1)
    return f
end

function TMT:MakeLineBorders(parent, r, g, b, a, size)
    size = size or 1
    local c = { r, g, b, a or 1 }
    for _, info in ipairs({
        { "TOPLEFT",    "TOPRIGHT",    "h", size },
        { "BOTTOMLEFT", "BOTTOMRIGHT", "h", size },
        { "TOPLEFT",    "BOTTOMLEFT",  "v", size },
        { "TOPRIGHT",   "BOTTOMRIGHT", "v", size },
    }) do
        local t = parent:CreateTexture(nil, "BORDER")
        t:SetColorTexture(unpack(c))
        t:SetPoint(info[1], parent, info[1])
        t:SetPoint(info[2], parent, info[2])
        if info[3] == "h" then t:SetHeight(info[4])
        else                    t:SetWidth(info[4]) end
    end
end

function TMT:MakeFS(parent, size, flags, anchor, relTo, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(self:GetFont(size, flags))
    fs:SetShadowColor(0, 0, 0, 0.9)
    fs:SetShadowOffset(1, -1)
    if anchor then
        fs:SetPoint(anchor, relTo or parent, anchor, x or 0, y or 0)
    end
    return fs
end

-- ═══════════════════════════════════════════════════════════════════════
--  BUILD FRAME
-- ═══════════════════════════════════════════════════════════════════════
function TMT:BuildFrame()
    if self.Frame then return end
    local db = GetDB()
    if not db then return end

    local C = self.C
    local W = self.W
    local F = CreateFrame("Frame", "TomoMod_MythicTrackerFrame", UIParent)
    self.Frame = F

    F:SetSize(W, 300)
    F:SetFrameStrata("MEDIUM")
    F:SetFrameLevel(50)
    F:SetClampedToScreen(true)
    F:Hide()

    -- Outer panel
    F._bg = self:MakeBG(F, 0, 0, 0, 0.82)

    F._accent = F:CreateTexture(nil, "ARTWORK")
    F._accent:SetWidth(3)
    F._accent:SetPoint("TOPLEFT",    F, "TOPLEFT",    0, 0)
    F._accent:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", 0, 0)
    F._accent:SetColorTexture(unpack(C.ACCENT))

    self:MakeLineBorders(F, unpack(C.BORDER))

    F._bdrFrame = self:MakeBorder(F, unpack(C.BORDER))
    F._bdrFrame:SetFrameLevel(F:GetFrameLevel() + 8)

    -- Drag
    F:SetScript("OnDragStart", function(s) s:StartMoving() end)
    F:SetScript("OnDragStop",  function(s)
        s:StopMovingOrSizing()
        local a, _, ra, x, y = s:GetPoint()
        x = math.floor(x * 10 + 0.5) / 10
        y = math.floor(y * 10 + 0.5) / 10
        self:SetPos(a, ra, x, y)
    end)

    -- ── HEADER ────────────────────────────────────────────────────────
    local HDR = CreateFrame("Frame", nil, F)
    F.Hdr = HDR
    HDR:SetHeight(self.HEADER_H)
    HDR:SetPoint("TOPLEFT",  F, "TOPLEFT",  0, 0)
    HDR:SetPoint("TOPRIGHT", F, "TOPRIGHT", 0, 0)

    HDR._bg = HDR:CreateTexture(nil, "BACKGROUND")
    HDR._bg:SetAllPoints(HDR)
    HDR._bg:SetColorTexture(unpack(C.BG_HEADER))

    HDR.dungeonName = self:MakeFS(HDR, 13, "OUTLINE")
    HDR.dungeonName:SetPoint("TOPLEFT", HDR, "TOPLEFT", 8, -5)
    HDR.dungeonName:SetWordWrap(false)
    HDR.dungeonName:SetNonSpaceWrap(false)
    HDR.dungeonName:SetTextColor(unpack(C.TEXT_WHITE))

    HDR.keyLevel = self:MakeFS(HDR, 16, "OUTLINE")
    HDR.keyLevel:SetPoint("TOPRIGHT", HDR, "TOPRIGHT", -8, -4)
    HDR.keyLevel:SetTextColor(unpack(C.TEXT_GREEN))

    HDR.deaths = self:MakeFS(HDR, 11, "OUTLINE")
    HDR.deaths:SetPoint("BOTTOMRIGHT", HDR, "BOTTOMRIGHT", -8, 5)
    HDR.deaths:SetTextColor(unpack(C.TEXT_SKULL))

    HDR.affixes = {}
    for i = 1, 4 do
        local ic = HDR:CreateTexture(nil, "OVERLAY")
        ic:SetSize(16, 16)
        ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        HDR.affixes[i] = ic
        ic:Hide()
    end

    F._sep1 = F:CreateTexture(nil, "ARTWORK")
    F._sep1:SetHeight(1)
    F._sep1:SetPoint("TOPLEFT",  HDR, "BOTTOMLEFT",  0, 0)
    F._sep1:SetPoint("TOPRIGHT", HDR, "BOTTOMRIGHT", 0, 0)
    F._sep1:SetColorTexture(unpack(C.ACCENT))

    -- ── TIMER BAR ─────────────────────────────────────────────────────
    local TB = CreateFrame("StatusBar", nil, F)
    F.TimerBar = TB
    TB:SetHeight(self.BAR_H)
    TB:SetPoint("TOPLEFT",  F._sep1, "BOTTOMLEFT",  0, -self.GAP)
    TB:SetPoint("TOPRIGHT", F._sep1, "BOTTOMRIGHT", 0, -self.GAP)
    TB:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    TB:SetMinMaxValues(0, 1)
    TB:SetValue(0)

    TB._bg = TB:CreateTexture(nil, "BACKGROUND")
    TB._bg:SetAllPoints(TB)
    TB._bg:SetColorTexture(unpack(C.BAR_TRACK))

    TB.elapsed = self:MakeFS(TB, 13, "OUTLINE")
    TB.elapsed:SetPoint("LEFT", TB, "LEFT", 8, 0)
    TB.elapsed:SetTextColor(unpack(C.TEXT_WHITE))

    TB.delta = self:MakeFS(TB, 11, "OUTLINE")
    TB.delta:SetPoint("CENTER", TB, "CENTER", 0, 0)

    TB.limit = self:MakeFS(TB, 11, "OUTLINE")
    TB.limit:SetPoint("RIGHT", TB, "RIGHT", -8, 0)
    TB.limit:SetTextColor(unpack(C.TEXT_GREY))

    TB.ticks = {}
    for i = 1, 2 do
        local tick = TB:CreateTexture(nil, "OVERLAY")
        tick:SetSize(1, self.BAR_H)
        tick:SetColorTexture(1, 1, 1, 0.40)
        tick:Hide()
        TB.ticks[i] = tick
    end

    -- ── CHEST COUNTDOWN ROW ───────────────────────────────────────────
    local CR = CreateFrame("Frame", nil, F)
    F.ChestRow = CR
    CR:SetHeight(14)
    CR:SetPoint("TOPLEFT",  TB, "BOTTOMLEFT",  0, -1)
    CR:SetPoint("TOPRIGHT", TB, "BOTTOMRIGHT", 0, -1)

    CR.chest2 = self:MakeFS(CR, 10, "OUTLINE")
    CR.chest2:SetPoint("LEFT", CR, "LEFT", 8, 0)
    CR.chest2:SetTextColor(unpack(C.TEXT_GREEN))
    CR.chest2:Hide()

    CR.chest1 = self:MakeFS(CR, 10, "OUTLINE")
    CR.chest1:SetPoint("RIGHT", CR, "RIGHT", -8, 0)
    CR.chest1:SetTextColor(unpack(C.TEXT_YELLOW))
    CR.chest1:Hide()

    -- ── SEPARATOR 2 ───────────────────────────────────────────────────
    F._sep2 = F:CreateTexture(nil, "ARTWORK")
    F._sep2:SetHeight(1)
    F._sep2:SetPoint("TOPLEFT",  CR, "BOTTOMLEFT",  0, -self.GAP)
    F._sep2:SetPoint("TOPRIGHT", CR, "BOTTOMRIGHT", 0, -self.GAP)
    F._sep2:SetColorTexture(unpack(C.SEP))

    -- ── FORCES BAR ────────────────────────────────────────────────────
    local FB = CreateFrame("StatusBar", nil, F)
    F.ForcesBar = FB
    FB:SetHeight(self.BAR_H)
    FB:SetPoint("TOPLEFT",  F._sep2, "BOTTOMLEFT",  0, -self.GAP)
    FB:SetPoint("TOPRIGHT", F._sep2, "BOTTOMRIGHT", 0, -self.GAP)
    FB:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    FB:SetMinMaxValues(0, 1)
    FB:SetValue(0)

    FB._bg = FB:CreateTexture(nil, "BACKGROUND")
    FB._bg:SetAllPoints(FB)
    FB._bg:SetColorTexture(unpack(C.BAR_TRACK))

    FB.label = self:MakeFS(FB, 10, "OUTLINE")
    FB.label:SetPoint("LEFT", FB, "LEFT", 8, 0)
    FB.label:SetText(L["tmt_forces"])
    FB.label:SetTextColor(unpack(C.TEXT_TEAL))

    FB.pct = self:MakeFS(FB, 12, "OUTLINE")
    FB.pct:SetPoint("CENTER", FB, "CENTER", 0, 0)
    FB.pct:SetTextColor(unpack(C.TEXT_WHITE))

    FB.count = self:MakeFS(FB, 10, "OUTLINE")
    FB.count:SetPoint("RIGHT", FB, "RIGHT", -8, 0)
    FB.count:SetTextColor(unpack(C.TEXT_GREY))

    -- ── SEPARATOR 3 ───────────────────────────────────────────────────
    F._sep3 = F:CreateTexture(nil, "ARTWORK")
    F._sep3:SetHeight(1)
    F._sep3:SetPoint("TOPLEFT",  FB, "BOTTOMLEFT",  0, -self.GAP)
    F._sep3:SetPoint("TOPRIGHT", FB, "BOTTOMRIGHT", 0, -self.GAP)
    F._sep3:SetColorTexture(unpack(C.SEP))

    -- ── BOSS ROWS (up to 8) ──────────────────────────────────────────
    F.BossRows = {}
    local prevAnchor = F._sep3
    for i = 1, 8 do
        local row = CreateFrame("Frame", nil, F)
        row:SetHeight(self.BOSS_H)
        row:SetPoint("TOPLEFT",  prevAnchor, "BOTTOMLEFT",  0, i == 1 and -self.GAP or 0)
        row:SetPoint("TOPRIGHT", prevAnchor, "BOTTOMRIGHT", 0, i == 1 and -self.GAP or 0)

        row._bg = row:CreateTexture(nil, "BACKGROUND")
        row._bg:SetAllPoints(row)
        row._bg:SetColorTexture(0, 0, 0, 0)

        row.dot = row:CreateTexture(nil, "ARTWORK")
        row.dot:SetSize(7, 7)
        row.dot:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.dot:SetColorTexture(0.35, 0.35, 0.35, 1)

        row.name = self:MakeFS(row, 11, "OUTLINE")
        row.name:SetPoint("LEFT", row, "LEFT", 20, 0)
        row.name:SetTextColor(unpack(C.TEXT_GREY))

        row.time = self:MakeFS(row, 11, "OUTLINE")
        row.time:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        row.time:SetTextColor(unpack(C.TEXT_GREY))

        row:Hide()
        F.BossRows[i] = row
        prevAnchor = row
    end

    -- ── COMPLETION BANNER ─────────────────────────────────────────────
    local BNR = CreateFrame("Frame", nil, F)
    F.Banner = BNR
    BNR:SetHeight(24)
    BNR:SetPoint("LEFT",  F, "LEFT",  0, 0)
    BNR:SetPoint("RIGHT", F, "RIGHT", 0, 0)

    BNR._bg = BNR:CreateTexture(nil, "BACKGROUND")
    BNR._bg:SetAllPoints(BNR)
    BNR._bg:SetColorTexture(0, 0.20, 0.04, 0.92)

    BNR.text = self:MakeFS(BNR, 13, "OUTLINE")
    BNR.text:SetPoint("CENTER", BNR, "CENTER", 0, 0)
    BNR.text:SetTextColor(unpack(C.TEXT_GREEN))
    BNR:Hide()

    -- Apply initial lock state
    self:SetMovable(not (db and db.locked))
end

-- ═══════════════════════════════════════════════════════════════════════
--  SHOW / HIDE
-- ═══════════════════════════════════════════════════════════════════════
function TMT:ShowFrame()
    local db = GetDB()
    if self.Frame then
        self.Frame:SetAlpha(db and db.alpha or 0.95)
        self.Frame:Show()
    end
end

function TMT:HideFrame()
    if self.Frame then self.Frame:Hide() end
end

-- ═══════════════════════════════════════════════════════════════════════
--  MOVABLE / POSITION
-- ═══════════════════════════════════════════════════════════════════════
function TMT:SetMovable(enable)
    if not self.Frame then return end
    local db = GetDB()
    if db then db.locked = not enable end
    local F = self.Frame
    F:SetMovable(enable)
    F:EnableMouse(enable)
    if enable then
        F:RegisterForDrag("LeftButton")
        if F._bdrFrame then
            F._bdrFrame:SetBackdropBorderColor(0.9, 0.75, 0.1, 1)
        end
    else
        if F._bdrFrame then
            local c = self.C.BORDER
            F._bdrFrame:SetBackdropBorderColor(unpack(c))
        end
    end
end

function TMT:SetPos(anchor, relTo, x, y)
    local db = GetDB()
    if not db then return end
    db.position.anchor = anchor
    db.position.relTo  = relTo
    db.position.x      = x
    db.position.y      = y
end

function TMT:ResetPosition()
    local def = TomoMod_Defaults.MythicTracker.position
    self:SetPos(def.anchor, def.relTo, def.x, def.y)
    if self.Frame then
        self.Frame:ClearAllPoints()
        self.Frame:SetPoint(def.anchor, UIParent, def.relTo, def.x, def.y)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  UPDATE — HEADER
-- ═══════════════════════════════════════════════════════════════════════
function TMT:UpdateHeader(preview)
    local HDR = self.Frame.Hdr
    local C = self.C

    local name = L["tmt_dungeon_unknown"]
    if preview then
        name = "Priory of the Sacred Flame"
    elseif self.mapID and self.mapID > 0 then
        local n = C_ChallengeMode.GetMapUIInfo(self.mapID)
        if n then name = n end
    end
    HDR.dungeonName:SetText(name)

    local lvl = preview and 20 or (self.level or 0)
    HDR.keyLevel:SetText(lvl > 0 and string.format(L["tmt_key_level"], lvl) or "")

    local skullIcon = "|TInterface\\Icons\\spell_shadow_soulleech_3:13:13:0:-1|t"
    local deaths, timeLost = 0, 0
    if preview then
        deaths, timeLost = 1, 5
    else
        deaths, timeLost = C_ChallengeMode.GetDeathCount()
        deaths   = deaths   or 0
        timeLost = timeLost or 0
    end

    if deaths > 0 then
        HDR.deaths:SetText(skullIcon
            .. " |cFFE03030" .. deaths .. "|r"
            .. " |cFF777777(+" .. self:FormatTime(timeLost) .. ")|r")
    else
        HDR.deaths:SetText("")
    end

    local affixes = preview and {9, 12, 134, 11} or (self.affixes or {})
    local lastShown = nil
    for i = 1, 4 do
        local ic = HDR.affixes[i]
        ic:ClearAllPoints()
        if affixes[i] then
            local _, _, icon = C_ChallengeMode.GetAffixInfo(affixes[i])
            if icon then
                ic:SetTexture(icon)
                if lastShown == nil then
                    ic:SetPoint("BOTTOMLEFT", HDR, "BOTTOMLEFT", 8, 5)
                else
                    ic:SetPoint("LEFT", lastShown, "RIGHT", 3, 0)
                end
                ic:Show()
                lastShown = ic
            else
                ic:Hide()
            end
        else
            ic:Hide()
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  UPDATE — TIMER BAR + CHEST COUNTDOWN
-- ═══════════════════════════════════════════════════════════════════════
function TMT:UpdateTimerBar(preview)
    local TB = self.Frame.TimerBar
    local CR = self.Frame.ChestRow
    local db = GetDB()
    if not db or not db.showTimer then
        TB:Hide(); CR:Hide()
        return
    end
    TB:Show()

    local C = self.C
    local elapsed   = 0
    local timeLimit = self.timeLimit or 1800

    if preview then
        elapsed, timeLimit = 179, 1800
    elseif self.completionTime then
        elapsed = self.completionTime / 1000
    elseif C_ChallengeMode.IsChallengeModeActive() then
        elapsed = select(2, GetWorldElapsedTime(1)) or 0
    end
    if timeLimit <= 0 then timeLimit = 1800 end

    local ratio    = math.min(elapsed / timeLimit, 1)
    local overtime = elapsed > timeLimit

    local r, g, b
    if overtime then
        r, g, b = C.BAR_RED[1], C.BAR_RED[2], C.BAR_RED[3]
        TB:SetValue(1)
    elseif ratio < 0.70 then
        local t = ratio / 0.70
        r = C.BAR_GREEN[1]  + (C.BAR_YELLOW[1] - C.BAR_GREEN[1])  * t
        g = C.BAR_GREEN[2]  + (C.BAR_YELLOW[2] - C.BAR_GREEN[2])  * t
        b = C.BAR_GREEN[3]  + (C.BAR_YELLOW[3] - C.BAR_GREEN[3])  * t
        TB:SetValue(ratio)
    else
        local t = (ratio - 0.70) / 0.30
        r = C.BAR_YELLOW[1] + (C.BAR_RED[1] - C.BAR_YELLOW[1]) * t
        g = C.BAR_YELLOW[2] + (C.BAR_RED[2] - C.BAR_YELLOW[2]) * t
        b = C.BAR_YELLOW[3] + (C.BAR_RED[3] - C.BAR_YELLOW[3]) * t
        TB:SetValue(ratio)
    end
    TB:SetStatusBarColor(r, g, b, 0.85)

    TB.elapsed:SetText(self:FormatTime(elapsed))
    if overtime then
        TB.elapsed:SetTextColor(unpack(C.TEXT_RED))
    else
        TB.elapsed:SetTextColor(unpack(C.TEXT_WHITE))
    end

    TB.limit:SetText("/ " .. self:FormatTime(timeLimit))

    local diff = timeLimit - elapsed
    local ds   = self:FormatDelta(diff)
    if diff >= 0 then
        local hex = string.format("|cFF%02x%02x%02x", math.floor(r*255), math.floor(g*255), math.floor(b*255))
        TB.delta:SetText(hex .. ds .. "|r")
    else
        TB.delta:SetText("|cFFE03020" .. ds .. "|r")
    end

    local ct = preview and {timeLimit, math.floor(timeLimit * 0.80)} or (self.chestTimes or {})
    for i = 1, 2 do
        local tick  = TB.ticks[i]
        local ctime = ct[i]
        if ctime and ctime > 0 and ctime < timeLimit then
            local px = (ctime / timeLimit) * self.W
            tick:ClearAllPoints()
            tick:SetPoint("LEFT", TB, "LEFT", math.floor(px), 0)
            tick:Show()
        else
            tick:Hide()
        end
    end

    -- Chest countdown row
    local anyChest = false
    local ct2 = ct[2]
    if ct2 and ct2 > 0 and ct2 < timeLimit then
        local rem2 = ct2 - elapsed
        local txt2
        if rem2 > 0 then
            txt2 = "|cFF55E210+2|r  " .. self:FormatTime(rem2)
            CR.chest2:SetTextColor(unpack(C.TEXT_GREEN))
        else
            txt2 = "|cFF55E210+2|r  |cFF888888-" .. self:FormatTime(-rem2) .. "|r"
        end
        CR.chest2:SetText(txt2)
        CR.chest2:Show()
        anyChest = true
    else
        CR.chest2:Hide()
    end

    local ct1 = ct[1]
    if ct1 and ct1 > 0 then
        local rem1 = ct1 - elapsed
        local txt1
        if rem1 > 0 then
            txt1 = self:FormatTime(rem1) .. "  |cFFFFCC00\194\1770|r"
            CR.chest1:SetTextColor(unpack(C.TEXT_YELLOW))
        else
            txt1 = "|cFF888888-" .. self:FormatTime(-rem1) .. "|r  |cFFE03020OT|r"
        end
        CR.chest1:SetText(txt1)
        CR.chest1:Show()
        anyChest = true
    else
        CR.chest1:Hide()
    end

    if anyChest then CR:Show() else CR:Hide() end
end

-- ═══════════════════════════════════════════════════════════════════════
--  UPDATE — FORCES BAR
-- ═══════════════════════════════════════════════════════════════════════
function TMT:UpdateForcesBar(preview)
    local FB  = self.Frame.ForcesBar
    local sep = self.Frame._sep3
    local db  = GetDB()
    if not db or not db.showForces then
        FB:Hide(); sep:Hide()
        return
    end
    FB:Show(); sep:Show()

    local C = self.C
    local qty, total, pct = 0, 1, 0

    if preview then
        qty, total = 730, 1000
    else
        local steps = select(3, C_Scenario.GetStepInfo())
        if steps and steps > 0 then
            for i = 1, steps do
                local cr = C_ScenarioInfo.GetCriteriaInfo(i)
                if cr and cr.isWeightedProgress and cr.totalQuantity and cr.totalQuantity > 0 then
                    qty   = cr.quantityString and tonumber(cr.quantityString:match("%d+")) or 0
                    total = cr.totalQuantity
                    break
                end
            end
        end
    end
    pct = (total > 0) and (qty / total * 100) or 0

    local ratio = math.min(pct / 100, 1)
    FB:SetValue(ratio)

    if pct >= 100 then
        FB:SetStatusBarColor(unpack(C.BAR_GREEN))
        FB.pct:SetText(L["tmt_forces_done"])
        FB.pct:SetTextColor(unpack(C.TEXT_GREEN))
    else
        local r = C.BAR_BLUE[1] + (C.BAR_TEAL[1] - C.BAR_BLUE[1]) * ratio
        local g = C.BAR_BLUE[2] + (C.BAR_TEAL[2] - C.BAR_BLUE[2]) * ratio
        local b = C.BAR_BLUE[3] + (C.BAR_TEAL[3] - C.BAR_BLUE[3]) * ratio
        FB:SetStatusBarColor(r, g, b, 0.88)
        FB.pct:SetText(string.format(L["tmt_forces_pct"], pct))
        FB.pct:SetTextColor(unpack(C.TEXT_WHITE))
    end
    FB.count:SetText(string.format(L["tmt_forces_count"], qty, total))
end

-- ═══════════════════════════════════════════════════════════════════════
--  UPDATE — BOSS ROWS
-- ═══════════════════════════════════════════════════════════════════════
function TMT:UpdateBossRows(preview)
    for _, row in ipairs(self.Frame.BossRows) do row:Hide() end
    local db = GetDB()
    if not db or not db.showBosses then return end

    local C       = self.C
    local elapsed = 0

    if not preview and C_ChallengeMode.IsChallengeModeActive() then
        elapsed = select(2, GetWorldElapsedTime(1)) or 0
    end

    local criteria = {}
    if preview then
        criteria = {
            { criteriaString = "Prioress Murrpray",   completed = true,  elapsed = 340 },
            { criteriaString = "Sergeant Shaynemail", completed = true,  elapsed = 560 },
            { criteriaString = "Captain Dailcry",     completed = false, elapsed = nil },
            { criteriaString = "High Priest Aemya",   completed = false, elapsed = nil },
        }
        elapsed = 900
    else
        local steps = select(3, C_Scenario.GetStepInfo()) or 0
        for i = 1, steps do
            local cr = C_ScenarioInfo.GetCriteriaInfo(i)
            if cr and not cr.isWeightedProgress then
                table.insert(criteria, cr)
            end
        end
    end

    self.bossKillTimes = self.bossKillTimes or {}

    for i, cr in ipairs(criteria) do
        local row = self.Frame.BossRows[i]
        if not row then break end
        row:Show()

        if i % 2 == 0 then
            row._bg:SetColorTexture(unpack(C.BG_ROW_ALT))
        else
            row._bg:SetColorTexture(0, 0, 0, 0)
        end

        row.name:SetText(cr.criteriaString or ("Boss " .. i))

        if cr.completed then
            row.dot:SetColorTexture(unpack(C.ACCENT))
            row.name:SetTextColor(unpack(C.TEXT_WHITE))

            local kt = self.bossKillTimes[i]
            if not kt and cr.elapsed and elapsed > 0 then
                kt = elapsed - cr.elapsed
                self.bossKillTimes[i] = kt
            end
            local checkIcon = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:12:12:0:0|t"
            row.time:SetText(kt and (checkIcon .. "  " .. self:FormatTime(kt)) or checkIcon)
            row.time:SetTextColor(unpack(C.TEXT_GREEN))
        else
            row.dot:SetColorTexture(0.30, 0.30, 0.30, 1)
            row.name:SetTextColor(unpack(C.TEXT_GREY))
            row.time:SetText("\226\128\148")
            row.time:SetTextColor(unpack(C.TEXT_GREY))
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  UPDATE — COMPLETION BANNER
-- ═══════════════════════════════════════════════════════════════════════
function TMT:UpdateBanner()
    local BNR = self.Frame.Banner
    local info = C_ChallengeMode.GetChallengeCompletionInfo()
    if info and info.time and info.time > 0 then
        local sec    = info.time / 1000
        local inTime = self.timeLimit and (sec <= self.timeLimit)
        if inTime then
            BNR._bg:SetColorTexture(0, 0.22, 0.04, 0.92)
            BNR.text:SetText("|cFF55E210" .. L["tmt_completed_on_time"] .. "|r  " .. self:FormatTime(sec))
        else
            BNR._bg:SetColorTexture(0.22, 0.04, 0, 0.92)
            BNR.text:SetText("|cFFE03020" .. L["tmt_completed_depleted"] .. "|r  " .. self:FormatTime(sec))
        end
        BNR:Show()
    else
        BNR:Hide()
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  LAYOUT — dynamic frame height
-- ═══════════════════════════════════════════════════════════════════════
function TMT:LayoutFrame()
    if not self.Frame then return end
    local db = GetDB()
    if not db then return end
    local F   = self.Frame
    local GAP = self.GAP

    local h = self.HEADER_H + 1 + GAP

    if db.showTimer then
        h = h + self.BAR_H
        if F.ChestRow:IsShown() then
            h = h + 1 + 14
        end
    end

    if db.showForces then
        h = h + GAP + 1 + GAP + self.BAR_H
    end

    local bossCnt  = 0
    local lastRow  = nil
    for _, row in ipairs(F.BossRows) do
        if row:IsShown() then bossCnt = bossCnt + 1; lastRow = row end
    end
    if bossCnt > 0 then
        h = h + GAP + 1 + GAP
        h = h + bossCnt * self.BOSS_H
    end

    if F.Banner:IsShown() then
        h = h + GAP + 24
    end
    h = h + 4

    F:SetHeight(math.max(h, self.HEADER_H + self.BAR_H * 2 + 20))

    F._bg:SetAllPoints(F)
    F._accent:ClearAllPoints()
    F._accent:SetPoint("TOPLEFT",    F, "TOPLEFT",    0, 0)
    F._accent:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", 0, 0)
    if F._bdrFrame then F._bdrFrame:SetAllPoints(F) end

    local bannerAnchor = (lastRow and lastRow:IsShown()) and lastRow
                         or (db.showForces and F.ForcesBar)
                         or F.TimerBar
    F.Banner:ClearAllPoints()
    F.Banner:SetPoint("TOPLEFT",  bannerAnchor, "BOTTOMLEFT",  0, -GAP)
    F.Banner:SetPoint("TOPRIGHT", bannerAnchor, "BOTTOMRIGHT", 0, -GAP)
end

-- ═══════════════════════════════════════════════════════════════════════
--  REFRESH ALL
-- ═══════════════════════════════════════════════════════════════════════
function TMT:RefreshAll(preview)
    if not self.Frame then return end
    self:UpdateHeader(preview)
    self:UpdateTimerBar(preview)
    self:UpdateForcesBar(preview)
    self:UpdateBossRows(preview)
    self:UpdateBanner()
    self:LayoutFrame()
end

-- ═══════════════════════════════════════════════════════════════════════
--  PREVIEW
-- ═══════════════════════════════════════════════════════════════════════
function TMT:Preview()
    if not self.Frame then self:BuildFrame() end
    self.mapID          = 0
    self.level          = 20
    self.affixes        = {}
    self.timeLimit      = 1800
    self.chestTimes     = { [1] = 1800, [2] = 1440 }
    self.bossKillTimes  = {}
    self.completionTime = nil
    self:RefreshAll(true)
    self:ShowFrame()
    print(L["tmt_preview_active"])
end

-- ═══════════════════════════════════════════════════════════════════════
--  BLIZZARD UI SUPPRESSION
-- ═══════════════════════════════════════════════════════════════════════

local BLIZZARD_FRAMES = {
    "ScenarioFrame",
    "ScenarioTrackerProgressBar",
    function() return ObjectiveTrackerFrame and ObjectiveTrackerFrame.CHALLENGE_BLOCK end,
    function() return ObjectiveTrackerFrame and ObjectiveTrackerFrame.BONUS_OBJECTIVE_TRACKER_MODULE end,
    "ScenarioStageBlock",
    function() return ScenarioObjectiveTracker end,
    function()
        if ObjectiveTrackerFrame and ObjectiveTrackerFrame.CHALLENGE_BLOCK then
            return ObjectiveTrackerFrame.CHALLENGE_BLOCK
        end
    end,
}

local BLIZZARD_OT_MODULES = {
    "CHALLENGE_BLOCK",
    "SCENARIO_CONTENT_TRACKER_MODULE",
    "BONUS_OBJECTIVE_TRACKER_MODULE",
    "UI_WIDGET_SCENARIO_TRACKER_MODULE",
}

TMT._blizzHooked   = false
TMT._inChallenge   = false

local function HookHide(frame)
    if not frame or frame._tmtHooked then return end
    frame._tmtHooked = true
    frame:Hide()
    hooksecurefunc(frame, "Show", function(f)
        if TMT._inChallenge then f:Hide() end
    end)
end

local function HookSetShown(frame)
    if not frame or frame._tmtShownHooked then return end
    frame._tmtShownHooked = true
    hooksecurefunc(frame, "SetShown", function(f, val)
        if TMT._inChallenge and val then f:Hide() end
    end)
end

local function SuppressOTModules()
    local OT = ObjectiveTrackerFrame
    if not OT then return end
    HookHide(OT)
    HookSetShown(OT)
    for _, modKey in ipairs(BLIZZARD_OT_MODULES) do
        local mod = OT[modKey]
        if mod then
            HookHide(mod)
            HookSetShown(mod)
            if mod.Header   then HookHide(mod.Header) end
            if mod.contents then HookHide(mod.contents) end
        end
    end
end

local function SuppressNamedFrames()
    for _, entry in ipairs(BLIZZARD_FRAMES) do
        local frame
        if type(entry) == "string" then
            frame = _G[entry]
        elseif type(entry) == "function" then
            local ok, result = pcall(entry)
            if ok then frame = result end
        end
        if frame then HookHide(frame) end
    end
end

function TMT:SuppressBlizzardUI()
    TMT._inChallenge = true
    SuppressOTModules()
    SuppressNamedFrames()
    local attempts = 0
    local function retry()
        attempts = attempts + 1
        SuppressOTModules()
        SuppressNamedFrames()
        if attempts < 5 then
            C_Timer.After(2, retry)
        end
    end
    C_Timer.After(1, retry)
end

function TMT:RestoreBlizzardUI()
    TMT._inChallenge = false
end

function TMT:InitBlizzardSuppress()
    if TMT._blizzHooked then return end
    TMT._blizzHooked = true

    if ObjectiveTrackerFrame then
        hooksecurefunc(ObjectiveTrackerFrame, "Show", function(f)
            if TMT._inChallenge then f:Hide() end
        end)
    end

    if UIWidgetBelowMinimapContainerFrame then
        hooksecurefunc(UIWidgetBelowMinimapContainerFrame, "Show", function(f)
            if TMT._inChallenge then f:Hide() end
        end)
    end

    if ScenarioObjectiveTracker then
        hooksecurefunc(ScenarioObjectiveTracker, "Show", function(f)
            if TMT._inChallenge then f:Hide() end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  EVENTS & TICKER
-- ═══════════════════════════════════════════════════════════════════════
TMT._ticker = nil

function TMT:StartTicker()
    if self._ticker then return end
    local function tick()
        TMT._ticker = nil
        if TMT.Frame and C_ChallengeMode.IsChallengeModeActive() then
            TMT:UpdateTimerBar()
            TMT:UpdateForcesBar()
            TMT:UpdateHeader()
            TMT._ticker = C_Timer.NewTimer(TMT.UPDATE_RATE, tick)
        end
    end
    self._ticker = C_Timer.NewTimer(self.UPDATE_RATE, tick)
end

function TMT:StopTicker()
    if self._ticker then self._ticker:Cancel(); self._ticker = nil end
end

function TMT:_LoadActiveKey()
    self.mapID  = C_ChallengeMode.GetActiveChallengeMapID()
    self.level, self.affixes = C_ChallengeMode.GetActiveKeystoneInfo()
    local _, _, tl = C_ChallengeMode.GetMapUIInfo(self.mapID or 0)
    self.timeLimit  = tl or 1800
    self.chestTimes = {
        [1] = self.timeLimit,
        [2] = math.floor(self.timeLimit * 0.80),
    }
end

local EF = CreateFrame("Frame")
EF:RegisterEvent("PLAYER_ENTERING_WORLD")
EF:RegisterEvent("CHALLENGE_MODE_START")
EF:RegisterEvent("CHALLENGE_MODE_COMPLETED")
EF:RegisterEvent("CHALLENGE_MODE_DEATH_COUNT_UPDATED")
EF:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
EF:RegisterEvent("SCENARIO_POI_UPDATE")
EF:SetScript("OnEvent", function(_, event, ...)
    local db = GetDB()
    if not db or not db.enabled then return end

    if event == "PLAYER_ENTERING_WORLD" then
        if not TMT.Frame then
            TMT:BuildFrame()
            TMT:InitBlizzardSuppress()
            local p = db.position
            TMT.Frame:ClearAllPoints()
            TMT.Frame:SetPoint(p.anchor, UIParent, p.relTo, p.x, p.y)
            TMT.Frame:SetScale(db.scale)
        end
        C_MythicPlus.RequestMapInfo()
        if C_ChallengeMode.IsChallengeModeActive() then
            if db.hideBlizzard then TMT:SuppressBlizzardUI() end
            TMT:_LoadActiveKey()
            TMT:RefreshAll(false)
            TMT:ShowFrame()
            TMT:StartTicker()
        else
            TMT:RestoreBlizzardUI()
            TMT:HideFrame()
        end

    elseif event == "CHALLENGE_MODE_START" then
        TMT.bossKillTimes = {}
        TMT.completionTime = nil
        if db.hideBlizzard then TMT:SuppressBlizzardUI() end
        TMT:_LoadActiveKey()
        TMT:RefreshAll(false)
        TMT:ShowFrame()
        TMT:StartTicker()

    elseif event == "CHALLENGE_MODE_COMPLETED" then
        TMT:StopTicker()
        local info = C_ChallengeMode.GetChallengeCompletionInfo()
        TMT.completionTime = info and info.time or nil
        TMT:UpdateTimerBar(false)
        TMT:UpdateBossRows(false)
        TMT:UpdateBanner()
        TMT:LayoutFrame()

    elseif event == "CHALLENGE_MODE_DEATH_COUNT_UPDATED" then
        TMT:UpdateHeader()

    elseif event == "SCENARIO_CRITERIA_UPDATE"
        or event == "SCENARIO_POI_UPDATE" then
        if TMT.Frame and C_ChallengeMode.IsChallengeModeActive() then
            TMT:UpdateBossRows()
            TMT:UpdateForcesBar()
            TMT:LayoutFrame()
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
--  CONFIG PANEL
-- ═══════════════════════════════════════════════════════════════════════
function TMT:BuildConfigPanel()
    if self.ConfigPanel then return end
    local C = self.C
    local W, H = 300, 434

    local P = CreateFrame("Frame", "TomoMod_MythicTrackerConfig", UIParent, "BackdropTemplate")
    self.ConfigPanel = P
    P:SetSize(W, H)
    P:SetPoint("CENTER", UIParent, "CENTER", 280, 20)
    P:SetFrameStrata("HIGH")
    P:SetFrameLevel(200)
    P:SetMovable(true)
    P:EnableMouse(true)
    P:RegisterForDrag("LeftButton")
    P:SetClampedToScreen(true)
    P:SetScript("OnDragStart", function(s) s:StartMoving() end)
    P:SetScript("OnDragStop",  function(s) s:StopMovingOrSizing() end)
    P:Hide()

    P:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    P:SetBackdropColor(0, 0, 0, 0.88)
    P:SetBackdropBorderColor(unpack(C.BORDER))

    local accent = P:CreateTexture(nil, "ARTWORK")
    accent:SetWidth(3)
    accent:SetPoint("TOPLEFT",    P, "TOPLEFT",    0, 0)
    accent:SetPoint("BOTTOMLEFT", P, "BOTTOMLEFT", 0, 0)
    accent:SetColorTexture(unpack(C.ACCENT))

    local hdrBG = P:CreateTexture(nil, "BACKGROUND")
    hdrBG:SetSize(W, 30)
    hdrBG:SetPoint("TOPLEFT", P, "TOPLEFT", 0, 0)
    hdrBG:SetColorTexture(unpack(C.BG_HEADER))

    local titleFS = self:MakeFS(P, 14, "OUTLINE")
    titleFS:SetPoint("LEFT", P, "TOPLEFT", 10, -15)
    titleFS:SetText("|cff0cd29fTomo|r|cFF3377CC" .. L["tmt_cfg_title"] .. "|r"
        .. "  |cFF445566M+ Tracker|r")

    local closeBtn = CreateFrame("Button", nil, P)
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", P, "TOPRIGHT", -4, -4)
    local closeX = self:MakeFS(closeBtn, 13, "OUTLINE")
    closeX:SetPoint("CENTER")
    closeX:SetText("|cFFCC3322\226\156\149|r")
    closeBtn:SetScript("OnClick", function() TMT:ToggleConfig() end)

    -- ── Helpers ──────────────────────────────────────────────────
    local function SectionHdr(text, yOff)
        local lbl = TMT:MakeFS(P, 10, "OUTLINE")
        lbl:SetPoint("TOPLEFT", P, "TOPLEFT", 10, yOff)
        lbl:SetText("|cFF3377CC" .. text:upper() .. "|r")
        lbl:SetTextColor(unpack(C.TEXT_BLUE))
        local line = P:CreateTexture(nil, "ARTWORK")
        line:SetSize(W - 12, 1)
        line:SetPoint("TOPLEFT", P, "TOPLEFT", 8, yOff - 13)
        line:SetColorTexture(0.15, 0.32, 0.55, 0.60)
    end

    local checkboxes = {}
    local function CB(label, yOff, dbKey, onChange)
        local db = GetDB()
        local cb = CreateFrame("CheckButton", nil, P, "UICheckButtonTemplate")
        cb:SetSize(18, 18)
        cb:SetPoint("TOPLEFT", P, "TOPLEFT", 10, yOff)
        cb:SetChecked(db[dbKey])
        local lbl = TMT:MakeFS(P, 12, "OUTLINE")
        lbl:SetPoint("LEFT", cb, "RIGHT", 3, 0)
        lbl:SetText(label)
        lbl:SetTextColor(unpack(C.TEXT_WHITE))
        cb:SetScript("OnClick", function(self)
            local db = GetDB()
            db[dbKey] = (self:GetChecked() == true)
            if onChange then onChange(db[dbKey]) end
        end)
        checkboxes[dbKey] = cb
        return cb
    end

    local sliderCount = 0
    local function Slider(label, yOff, minV, maxV, step, dbKey, fmt, onChange)
        local db = GetDB()
        local lbl = TMT:MakeFS(P, 10, "OUTLINE")
        lbl:SetPoint("TOPLEFT", P, "TOPLEFT", 10, yOff)
        lbl:SetText(label)
        lbl:SetTextColor(unpack(C.TEXT_GREY))

        sliderCount = sliderCount + 1
        local slName = "TomoMod_TMTConfigSlider" .. sliderCount
        local sl = CreateFrame("Slider", slName, P, "OptionsSliderTemplate")
        sl:SetSize(W - 60, 14)
        sl:SetPoint("TOPLEFT", P, "TOPLEFT", 10, yOff - 17)
        sl:SetMinMaxValues(minV, maxV)
        sl:SetValueStep(step)
        sl:SetObeyStepOnDrag(true)
        sl:SetValue(db[dbKey])

        local lowLbl  = _G[slName .. "Low"]
        local highLbl = _G[slName .. "High"]
        if lowLbl  then lowLbl:SetText( fmt and string.format(fmt, minV) or tostring(minV)) end
        if highLbl then highLbl:SetText(fmt and string.format(fmt, maxV) or tostring(maxV)) end

        local valLbl = TMT:MakeFS(P, 10, "OUTLINE")
        valLbl:SetPoint("LEFT", sl, "RIGHT", 4, 0)
        valLbl:SetText(fmt and string.format(fmt, db[dbKey]) or tostring(db[dbKey]))
        valLbl:SetTextColor(unpack(C.TEXT_GREEN))

        sl:SetScript("OnValueChanged", function(self, val)
            val = math.floor(val / step + 0.5) * step
            local db = GetDB()
            db[dbKey] = val
            valLbl:SetText(fmt and string.format(fmt, val) or tostring(val))
            if onChange then onChange(val) end
        end)
        return sl
    end

    local function Btn(label, yOff, xOff, onClick)
        local b = CreateFrame("Button", nil, P, "BackdropTemplate")
        b:SetSize(118, 20)
        b:SetPoint("TOPLEFT", P, "TOPLEFT", xOff or 10, yOff)
        b:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
        b:SetBackdropColor(0.05, 0.12, 0.26, 0.92)
        b:SetBackdropBorderColor(unpack(C.BORDER_BLUE))
        local fs = TMT:MakeFS(b, 11, "OUTLINE")
        fs:SetPoint("CENTER"); fs:SetText(label)
        fs:SetTextColor(unpack(C.TEXT_WHITE))
        b:SetScript("OnEnter", function(s) s:SetBackdropColor(0.10, 0.22, 0.44, 0.95) end)
        b:SetScript("OnLeave", function(s) s:SetBackdropColor(0.05, 0.12, 0.26, 0.92) end)
        b:SetScript("OnClick", onClick)
        return b
    end

    -- ── Layout ──────────────────────────────────────────────────
    local y = -38
    SectionHdr(L["tmt_cfg_section_display"], y) ; y = y - 20

    CB(L["tmt_cfg_show_timer"],  y, "showTimer",  function(v) if TMT.Frame then TMT.Frame.TimerBar:SetShown(v); TMT:LayoutFrame() end end) ; y = y - 24
    CB(L["tmt_cfg_show_forces"], y, "showForces", function(v) if TMT.Frame then TMT.Frame.ForcesBar:SetShown(v); TMT:LayoutFrame() end end) ; y = y - 24
    CB(L["tmt_cfg_show_bosses"], y, "showBosses", function() TMT:UpdateBossRows(); TMT:LayoutFrame() end) ; y = y - 24
    CB(L["tmt_cfg_hide_blizzard"], y, "hideBlizzard", function(v) if v and TMT._inChallenge then TMT:SuppressBlizzardUI() end end) ; y = y - 24
    SectionHdr(L["tmt_cfg_section_frame"], y) ; y = y - 20
    CB(L["tmt_cfg_lock"], y, "locked", function(v) TMT:SetMovable(not v) end) ; y = y - 30

    Slider(L["tmt_cfg_scale"], y, 0.5, 2.0, 0.05, "scale", "%.2f", function(v) if TMT.Frame then TMT.Frame:SetScale(v) end end)
    y = y - 48

    Slider(L["tmt_cfg_alpha"], y, 0.2, 1.0, 0.05, "alpha", "%.2f", function(v) if TMT.Frame then TMT.Frame:SetAlpha(v) end end)
    y = y - 44

    SectionHdr(L["tmt_cfg_section_actions"], y) ; y = y - 24

    Btn(L["tmt_cfg_preview"],   y,  10, function() TMT:Preview() end)
    Btn(L["tmt_cfg_reset_pos"], y, 150, function() TMT:ResetPosition(); print(L["tmt_reset_msg"]) end)

    local ver = TMT:MakeFS(P, 9, "OUTLINE")
    ver:SetPoint("BOTTOMRIGHT", P, "BOTTOMRIGHT", -8, 6)
    ver:SetText("|cFF334455M+ Tracker 1.0|r")

    P._checkboxes = checkboxes
end

function TMT:ToggleConfig()
    if not self.ConfigPanel then self:BuildConfigPanel() end
    if self.ConfigPanel:IsShown() then
        self.ConfigPanel:Hide()
    else
        if self.ConfigPanel._checkboxes then
            local db = GetDB()
            for key, cb in pairs(self.ConfigPanel._checkboxes) do
                cb:SetChecked(db[key])
            end
        end
        self.ConfigPanel:Show()
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  SLASH COMMANDS
-- ═══════════════════════════════════════════════════════════════════════
SLASH_TOMOMYTHICTRACKER1 = "/tmt"
SlashCmdList["TOMOMYTHICTRACKER"] = function(msg)
    msg = strtrim(msg or ""):lower()
    if     msg == ""        then
        if TomoMod_Config and TomoMod_Config.Toggle then
            TomoMod_Config.Show()
            TomoMod_Config.SwitchCategory("mythicplus")
        end
    elseif msg == "unlock"  then TMT:SetMovable(true);  print(L["tmt_unlock_msg"])
    elseif msg == "lock"    then TMT:SetMovable(false); print(L["tmt_lock_msg"])
    elseif msg == "reset"   then TMT:ResetPosition();   print(L["tmt_reset_msg"])
    elseif msg == "preview" then TMT:Preview()
    elseif msg == "key"     then
        if TomoMod_MythicPartyKeys then
            TomoMod_MythicPartyKeys:SendKeysToChat()
        end
    elseif msg == "kr"      then
        if TomoMod_MythicPartyKeys then
            TomoMod_MythicPartyKeys:ShowKeyRoulette()
        end
    elseif msg == "help"    then print(L["tmt_cmd_usage"])
    else print(L["tmt_unknown_cmd"]); print(L["tmt_cmd_usage"])
    end
end

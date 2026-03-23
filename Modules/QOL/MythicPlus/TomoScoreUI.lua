-- =====================================================================
-- TomoScoreUI.lua — Scoreboard frame + event-driven triggers
-- End-of-dungeon scoreboard with dark/teal aesthetic.
-- =====================================================================

local L = TomoMod_L
local TS = TomoMod_TomoScore

local FRAME_NAME = "TomoScoreFrame"
local FOOTER_H   = 28

-- ═════════════════════════════════════════════════════════════════════════════
--  BUILD SCOREBOARD
-- ═════════════════════════════════════════════════════════════════════════════
function TS:BuildScoreboard()
    if self.SB then return self.SB end

    local C   = self.C
    local W   = self.FRAME_W
    local COL = self.COL

    -- Main frame
    local F = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
    self.SB = F
    F:SetSize(W, 300)
    F:SetFrameStrata("DIALOG")
    F:SetFrameLevel(100)
    F:SetClampedToScreen(true)
    F:SetMovable(true)
    F:EnableMouse(true)
    F:RegisterForDrag("LeftButton")
    F:SetScript("OnDragStart", function(s) s:StartMoving() end)
    F:SetScript("OnDragStop",  function(s)
        s:StopMovingOrSizing()
        local a, _, ra, x, y = s:GetPoint()
        local db = TS:GetDB()
        if db then
            db.position.anchor = a
            db.position.relTo  = ra
            db.position.x      = math.floor(x + 0.5)
            db.position.y      = math.floor(y + 0.5)
        end
    end)
    F:Hide()

    tinsert(UISpecialFrames, FRAME_NAME)

    -- Background
    self:MakeBG(F, unpack(C.BG))

    -- Teal accent strip (left edge)
    local accent = F:CreateTexture(nil, "ARTWORK")
    accent:SetWidth(3)
    accent:SetPoint("TOPLEFT",    F, "TOPLEFT",    0, 0)
    accent:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", 0, 0)
    accent:SetColorTexture(unpack(C.ACCENT))

    -- 1px border lines on 3 sides
    do
        local r, g, b, a = unpack(C.BORDER)
        local bTop = F:CreateTexture(nil, "BORDER")
        bTop:SetColorTexture(r, g, b, a)
        bTop:SetPoint("TOPLEFT", F, "TOPLEFT", 3, 0)
        bTop:SetPoint("TOPRIGHT", F, "TOPRIGHT")
        bTop:SetHeight(1)

        local bBot = F:CreateTexture(nil, "BORDER")
        bBot:SetColorTexture(r, g, b, a)
        bBot:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", 3, 0)
        bBot:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT")
        bBot:SetHeight(1)

        local bRight = F:CreateTexture(nil, "BORDER")
        bRight:SetColorTexture(r, g, b, a)
        bRight:SetPoint("TOPRIGHT", F, "TOPRIGHT")
        bRight:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT")
        bRight:SetWidth(1)
    end

    -- Outer teal glow
    do
        local gr, gg, gb, ga = unpack(C.BORDER_TEAL)
        local glowTop = F:CreateTexture(nil, "BACKGROUND", nil, -7)
        glowTop:SetColorTexture(gr, gg, gb, ga)
        glowTop:SetPoint("TOPLEFT", F, "TOPLEFT", 3, 1)
        glowTop:SetPoint("TOPRIGHT", F, "TOPRIGHT", 1, 1)
        glowTop:SetHeight(1)

        local glowBot = F:CreateTexture(nil, "BACKGROUND", nil, -7)
        glowBot:SetColorTexture(gr, gg, gb, ga)
        glowBot:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", 3, -1)
        glowBot:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", 1, -1)
        glowBot:SetHeight(1)

        local glowRight = F:CreateTexture(nil, "BACKGROUND", nil, -7)
        glowRight:SetColorTexture(gr, gg, gb, ga)
        glowRight:SetPoint("TOPRIGHT", F, "TOPRIGHT", 1, 1)
        glowRight:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", 1, -1)
        glowRight:SetWidth(1)
    end

    -- Close button
    local closeBtn = CreateFrame("Button", nil, F, "UIPanelCloseButtonNoScripts")
    closeBtn:SetPoint("TOPRIGHT", F, "TOPRIGHT", -2, -2)
    closeBtn:SetSize(20, 20)
    closeBtn:SetScript("OnClick", function() F:Hide() end)

    -- HEADER
    local HDR = CreateFrame("Frame", nil, F)
    F.Header = HDR
    HDR:SetHeight(TS.HEADER_H)
    HDR:SetPoint("TOPLEFT",  F, "TOPLEFT",  0, 0)
    HDR:SetPoint("TOPRIGHT", F, "TOPRIGHT", 0, 0)

    HDR._bg = HDR:CreateTexture(nil, "BACKGROUND")
    HDR._bg:SetAllPoints(HDR)
    HDR._bg:SetColorTexture(unpack(C.BG_HEADER))

    HDR.dungeonName = self:MakeFS(HDR, 14, "OUTLINE")
    HDR.dungeonName:SetPoint("LEFT", HDR, "LEFT", 12, 6)
    HDR.dungeonName:SetTextColor(unpack(C.TEXT_WHITE))

    HDR.keyLevel = self:MakeFS(HDR, 14, "OUTLINE")
    HDR.keyLevel:SetPoint("LEFT", HDR.dungeonName, "RIGHT", 6, 0)
    HDR.keyLevel:SetTextColor(unpack(C.TEXT_TEAL))

    HDR.status = self:MakeFS(HDR, 12, "OUTLINE")
    HDR.status:SetPoint("RIGHT", HDR, "RIGHT", -28, 6)

    HDR.duration = self:MakeFS(HDR, 11, "OUTLINE")
    HDR.duration:SetPoint("LEFT", HDR, "LEFT", 12, -8)
    HDR.duration:SetTextColor(unpack(C.TEXT_GREY))

    local sep1 = F:CreateTexture(nil, "ARTWORK")
    sep1:SetHeight(2)
    sep1:SetPoint("TOPLEFT",  HDR, "BOTTOMLEFT",  0, 0)
    sep1:SetPoint("TOPRIGHT", HDR, "BOTTOMRIGHT", 0, 0)
    sep1:SetColorTexture(unpack(C.ACCENT))
    F._sep1 = sep1

    -- COLUMN HEADERS
    local CH = CreateFrame("Frame", nil, F)
    F.ColHeader = CH
    CH:SetHeight(TS.COL_HEADER_H)
    CH:SetPoint("TOPLEFT",  sep1, "BOTTOMLEFT",  0, 0)
    CH:SetPoint("TOPRIGHT", sep1, "BOTTOMRIGHT", 0, 0)

    CH._bg = CH:CreateTexture(nil, "BACKGROUND")
    CH._bg:SetAllPoints(CH)
    CH._bg:SetColorTexture(0.03, 0.03, 0.06, 0.80)

    local colX = COL.ICON + 4
    local function makeColLabel(text, width, justify)
        local fs = self:MakeFS(CH, 9, "OUTLINE")
        fs:SetPoint("LEFT", CH, "LEFT", colX, 0)
        fs:SetWidth(width)
        fs:SetJustifyH(justify or "LEFT")
        fs:SetText(text)
        fs:SetTextColor(unpack(C.TEXT_GREY))
        colX = colX + width
        return fs
    end

    CH.colPlayer     = makeColLabel(L["ts_col_player"],     COL.NAME,       "LEFT")
    CH.colRating     = makeColLabel(L["ts_col_rating"],     COL.RATING,     "CENTER")
    CH.colDamage     = makeColLabel(L["ts_col_damage"],     COL.DAMAGE,     "RIGHT")
    CH.colHealing    = makeColLabel(L["ts_col_healing"],    COL.HEALING,    "RIGHT")
    CH.colInterrupts = makeColLabel(L["ts_col_interrupts"], COL.INTERRUPTS, "CENTER")

    local sep2 = F:CreateTexture(nil, "ARTWORK")
    sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT",  CH, "BOTTOMLEFT",  0, 0)
    sep2:SetPoint("TOPRIGHT", CH, "BOTTOMRIGHT", 0, 0)
    sep2:SetColorTexture(unpack(C.ACCENT_DIM))
    F._sep2 = sep2

    -- PLAYER ROWS (pool)
    F.Rows = {}

    -- FOOTER
    local sepF = F:CreateTexture(nil, "ARTWORK")
    sepF:SetHeight(1)
    sepF:SetColorTexture(unpack(C.ACCENT_DIM))
    F._sepFooter = sepF

    local FTR = CreateFrame("Frame", nil, F)
    F.Footer = FTR
    FTR:SetHeight(FOOTER_H)

    FTR._bg = FTR:CreateTexture(nil, "BACKGROUND")
    FTR._bg:SetAllPoints(FTR)
    FTR._bg:SetColorTexture(unpack(C.BG_HEADER))

    FTR.label = self:MakeFS(FTR, 10, "OUTLINE")
    FTR.label:SetPoint("LEFT", FTR, "LEFT", 12, 0)
    FTR.label:SetTextColor(unpack(C.TEXT_TEAL))

    colX = COL.ICON + 4 + COL.NAME
    FTR.avgRating = self:MakeFS(FTR, 10, "OUTLINE")
    FTR.avgRating:SetPoint("LEFT", FTR, "LEFT", colX, 0)
    FTR.avgRating:SetWidth(COL.RATING)
    FTR.avgRating:SetJustifyH("CENTER")
    FTR.avgRating:SetTextColor(unpack(C.TEXT_TEAL))
    colX = colX + COL.RATING

    FTR.totalDmg = self:MakeFS(FTR, 10, "OUTLINE")
    FTR.totalDmg:SetPoint("LEFT", FTR, "LEFT", colX, 0)
    FTR.totalDmg:SetWidth(COL.DAMAGE)
    FTR.totalDmg:SetJustifyH("CENTER")
    FTR.totalDmg:SetTextColor(unpack(C.TEXT_WHITE))
    colX = colX + COL.DAMAGE

    FTR.totalHeal = self:MakeFS(FTR, 10, "OUTLINE")
    FTR.totalHeal:SetPoint("LEFT", FTR, "LEFT", colX, 0)
    FTR.totalHeal:SetWidth(COL.HEALING)
    FTR.totalHeal:SetJustifyH("CENTER")
    FTR.totalHeal:SetTextColor(unpack(C.TEXT_WHITE))
    colX = colX + COL.HEALING

    FTR.totalInt = self:MakeFS(FTR, 10, "OUTLINE")
    FTR.totalInt:SetPoint("LEFT", FTR, "LEFT", colX, 0)
    FTR.totalInt:SetWidth(COL.INTERRUPTS)
    FTR.totalInt:SetJustifyH("CENTER")
    FTR.totalInt:SetTextColor(unpack(C.TEXT_WHITE))

    return F
end

-- ═════════════════════════════════════════════════════════════════════════════
--  GET OR CREATE ROW
-- ═════════════════════════════════════════════════════════════════════════════
function TS:GetRow(index)
    local F = self.SB
    if not F.Rows[index] then
        F.Rows[index] = self:CreatePlayerRow(F, index)
    end
    return F.Rows[index]
end

function TS:CreatePlayerRow(parent, index)
    local C   = self.C
    local COL = self.COL

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(self.ROW_H)
    row.index = index

    row._bg = row:CreateTexture(nil, "BACKGROUND")
    row._bg:SetAllPoints(row)
    row._bg:SetColorTexture(0, 0, 0, 0)

    row.specIcon = row:CreateTexture(nil, "ARTWORK")
    row.specIcon:SetSize(24, 24)
    row.specIcon:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local colX = COL.ICON + 4

    row.nameFS = self:MakeFS(row, 12, "OUTLINE")
    row.nameFS:SetPoint("LEFT", row, "LEFT", colX, 0)
    row.nameFS:SetWidth(COL.NAME)
    row.nameFS:SetJustifyH("LEFT")
    row.nameFS:SetWordWrap(false)
    colX = colX + COL.NAME

    row.ratingFS = self:MakeFS(row, 11, "OUTLINE")
    row.ratingFS:SetPoint("LEFT", row, "LEFT", colX, 0)
    row.ratingFS:SetWidth(COL.RATING)
    row.ratingFS:SetJustifyH("CENTER")
    colX = colX + COL.RATING

    row.dmgBar = self:CreateStatBar(row, colX, COL.DAMAGE)
    colX = colX + COL.DAMAGE

    row.healBar = self:CreateStatBar(row, colX, COL.HEALING)
    colX = colX + COL.HEALING

    row.intFS = self:MakeFS(row, 12, "OUTLINE")
    row.intFS:SetPoint("LEFT", row, "LEFT", colX, 0)
    row.intFS:SetWidth(COL.INTERRUPTS)
    row.intFS:SetJustifyH("CENTER")

    row:Hide()
    return row
end

-- ═════════════════════════════════════════════════════════════════════════════
--  STAT BAR
-- ═════════════════════════════════════════════════════════════════════════════
function TS:CreateStatBar(parent, xOffset, width)
    local C = self.C
    local barH = 14

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width - 4, self.ROW_H)
    container:SetPoint("LEFT", parent, "LEFT", xOffset, 0)

    local track = container:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT",  container, "LEFT",  2, 0)
    track:SetPoint("RIGHT", container, "RIGHT", -2, 0)
    track:SetHeight(barH)
    track:SetColorTexture(unpack(C.BAR_TRACK))

    local fill = container:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", track, "TOPLEFT", 0, 0)
    fill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 0, 0)
    fill:SetWidth(1)
    fill:SetColorTexture(unpack(C.BAR_TEAL))

    local fs = self:MakeFS(container, 10, "OUTLINE")
    fs:SetPoint("CENTER", track, "CENTER", 0, 0)
    fs:SetTextColor(unpack(C.TEXT_WHITE))

    return {
        container = container,
        track     = track,
        fill      = fill,
        text      = fs,
        width     = width - 8,
    }
end

-- ═════════════════════════════════════════════════════════════════════════════
--  LAYOUT
-- ═════════════════════════════════════════════════════════════════════════════
function TS:LayoutScoreboard(numPlayers)
    local F = self.SB
    if not F then return end

    numPlayers = math.max(numPlayers or 0, 0)
    local C = self.C

    local prevAnchor = F._sep2
    for i = 1, numPlayers do
        local row = self:GetRow(i)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT",  prevAnchor, "BOTTOMLEFT",  0, 0)
        row:SetPoint("TOPRIGHT", prevAnchor, "BOTTOMRIGHT", 0, 0)
        local bgColor = (i % 2 == 1) and C.BG_ROW_ODD or C.BG_ROW_EVEN
        row._bg:SetColorTexture(unpack(bgColor))
        row:Show()
        prevAnchor = row
    end

    for i = numPlayers + 1, #F.Rows do
        F.Rows[i]:Hide()
    end

    F._sepFooter:ClearAllPoints()
    F._sepFooter:SetPoint("TOPLEFT",  prevAnchor, "BOTTOMLEFT",  0, -1)
    F._sepFooter:SetPoint("TOPRIGHT", prevAnchor, "BOTTOMRIGHT", 0, -1)

    F.Footer:ClearAllPoints()
    F.Footer:SetPoint("TOPLEFT",  F._sepFooter, "BOTTOMLEFT",  0, 0)
    F.Footer:SetPoint("TOPRIGHT", F._sepFooter, "BOTTOMRIGHT", 0, 0)

    local totalH = TS.HEADER_H + 2 + TS.COL_HEADER_H + 1
                 + (numPlayers * TS.ROW_H)
                 + 1 + FOOTER_H
    F:SetSize(TS.FRAME_W, totalH)
end

-- ═════════════════════════════════════════════════════════════════════════════
--  POPULATE
-- ═════════════════════════════════════════════════════════════════════════════
function TS:PopulateScoreboard(data)
    local F = self.SB
    if not F then return end
    local C = self.C

    F.Header.dungeonName:SetText(data.dungeonName or "?")

    if data.isMPlus and data.keyLevel and data.keyLevel > 0 then
        F.Header.keyLevel:SetText(string.format(L["ts_key_level"], data.keyLevel))
        F.Header.keyLevel:SetTextColor(unpack(C.TEXT_TEAL))
        F.Header.keyLevel:Show()
    elseif data.keyLevel == 0 then
        F.Header.keyLevel:SetText(L["ts_mythic_zero"])
        F.Header.keyLevel:SetTextColor(unpack(C.TEXT_GREY))
        F.Header.keyLevel:Show()
    else
        F.Header.keyLevel:Hide()
    end

    if data.isMPlus then
        if data.onTime then
            F.Header.status:SetText(L["ts_completed"])
            F.Header.status:SetTextColor(unpack(C.TEXT_GREEN))
        else
            F.Header.status:SetText(L["ts_depleted"])
            F.Header.status:SetTextColor(unpack(C.TEXT_RED))
        end
    else
        F.Header.status:SetText(L["ts_completed"])
        F.Header.status:SetTextColor(unpack(C.TEXT_GREEN))
    end

    if data.duration and data.duration > 0 then
        F.Header.duration:SetText(L["ts_duration"] .. ": " .. self:FormatTime(data.duration))
    else
        F.Header.duration:SetText("")
    end

    local maxDmg  = 1
    local maxHeal = 1
    for _, p in ipairs(data.players) do
        if (p.damage  or 0) > maxDmg  then maxDmg  = p.damage  end
        if (p.healing or 0) > maxHeal then maxHeal = p.healing end
    end

    local numPlayers  = math.min(#data.players, TS.MAX_PLAYERS)
    local totalDmg    = 0
    local totalHeal   = 0
    local totalInt    = 0
    local totalRating = 0
    local ratingCount = 0

    for i = 1, numPlayers do
        local p   = data.players[i]
        local row = self:GetRow(i)

        if p.specIcon then
            row.specIcon:SetTexture(p.specIcon)
            row.specIcon:Show()
        else
            local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[p.class]
            if coords then
                row.specIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
                row.specIcon:SetTexCoord(unpack(coords))
            else
                row.specIcon:SetTexture(134400)
            end
            row.specIcon:Show()
        end

        local cr, cg, cb = self:GetClassColor(p.class)
        row.nameFS:SetText(p.name or "?")
        row.nameFS:SetTextColor(cr, cg, cb)

        local rating = p.rating or 0
        if rating > 0 then
            row.ratingFS:SetText(tostring(rating))
            if rating >= 2500 then
                row.ratingFS:SetTextColor(1.00, 0.50, 0.00)
            elseif rating >= 2000 then
                row.ratingFS:SetTextColor(0.30, 0.85, 0.90)
            elseif rating >= 1500 then
                row.ratingFS:SetTextColor(0.00, 0.44, 0.87)
            elseif rating >= 1000 then
                row.ratingFS:SetTextColor(0.12, 1.00, 0.00)
            else
                row.ratingFS:SetTextColor(unpack(C.TEXT_GREY))
            end
            totalRating = totalRating + rating
            ratingCount = ratingCount + 1
        else
            row.ratingFS:SetText("\226\128\148")
            row.ratingFS:SetTextColor(unpack(C.TEXT_GREY))
        end

        local dmg = p.damage or 0
        self:FillStatBar(row.dmgBar, dmg, maxDmg, self:GetBarColorForRole(p.role, "damage"))
        totalDmg = totalDmg + dmg

        local heal = p.healing or 0
        self:FillStatBar(row.healBar, heal, maxHeal, self:GetBarColorForRole(p.role, "healing"))
        totalHeal = totalHeal + heal

        local ints = p.interrupts or 0
        row.intFS:SetText(ints > 0 and tostring(ints) or "\226\128\148")
        if ints >= 15 then
            row.intFS:SetTextColor(unpack(C.TEXT_GREEN))
        elseif ints > 0 then
            row.intFS:SetTextColor(unpack(C.TEXT_WHITE))
        else
            row.intFS:SetTextColor(unpack(C.TEXT_GREY))
        end
        totalInt = totalInt + ints
    end

    local FTR = F.Footer
    FTR.label:SetText(L["ts_footer_total"] .. "  \226\128\148  " .. string.format(L["ts_footer_players"], numPlayers))

    if ratingCount > 0 then
        FTR.avgRating:SetText(tostring(math.floor(totalRating / ratingCount + 0.5)))
    else
        FTR.avgRating:SetText("\226\128\148")
    end

    FTR.totalDmg:SetText(self:FormatNumber(totalDmg))
    FTR.totalHeal:SetText(self:FormatNumber(totalHeal))
    FTR.totalInt:SetText(tostring(totalInt))

    self:LayoutScoreboard(numPlayers)
end

-- ═════════════════════════════════════════════════════════════════════════════
--  BAR HELPERS
-- ═════════════════════════════════════════════════════════════════════════════
function TS:FillStatBar(bar, value, maxVal, color)
    bar.text:SetText(self:FormatNumber(value))
    local ratio = 0
    if maxVal > 0 and value > 0 then
        ratio = value / maxVal
    end
    local fillW = math.max(1, math.floor(bar.width * ratio))
    bar.fill:SetWidth(fillW)
    bar.fill:SetColorTexture(color[1], color[2], color[3], color[4] or 0.75)
    if value == 0 then
        bar.text:SetTextColor(unpack(self.C.TEXT_GREY))
    else
        bar.text:SetTextColor(unpack(self.C.TEXT_WHITE))
    end
end

function TS:GetBarColorForRole(role, stat)
    local C = self.C
    if stat == "healing" then
        return { 0.18, 0.70, 0.30, 0.75 }
    end
    if role == "TANK" then
        return { 0.40, 0.55, 0.80, 0.70 }
    elseif role == "HEALER" then
        return { 0.30, 0.60, 0.40, 0.65 }
    else
        return { C.ACCENT[1], C.ACCENT[2], C.ACCENT[3], 0.70 }
    end
end

-- ═════════════════════════════════════════════════════════════════════════════
--  PUBLIC API
-- ═════════════════════════════════════════════════════════════════════════════
function TS:ShowScoreboard(data)
    if not data then return end
    local F = self:BuildScoreboard()
    self:PopulateScoreboard(data)
    local db = self:GetDB()
    if db then
        local p = db.position
        F:ClearAllPoints()
        F:SetPoint(p.anchor, UIParent, p.relTo, p.x, p.y)
        F:SetScale(db.scale or 1)
        F:SetAlpha(db.alpha or 0.95)
    else
        F:ClearAllPoints()
        F:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    end
    F:Show()
end

function TS:ShowPreview()
    self:ShowScoreboard(self:GetPreviewData())
end

function TS:HideScoreboard()
    if self.SB then self.SB:Hide() end
end

function TS:ResetPosition()
    local db = self:GetDB()
    if db then
        db.position = { anchor = "CENTER", relTo = "CENTER", x = 0, y = 100 }
    end
    if self.SB then
        self.SB:ClearAllPoints()
        self.SB:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    end
end

-- ═════════════════════════════════════════════════════════════════════════════
--  EVENT SYSTEM — auto-detect dungeon end
-- ═════════════════════════════════════════════════════════════════════════════
TS._inMythicDungeon = false
TS._challengeActive = false
TS._totalBosses     = 0
TS._bossesKilled    = 0
TS._completionShown = false

local EF = CreateFrame("Frame")
TS._eventFrame = EF

EF:RegisterEvent("PLAYER_LOGIN")
EF:RegisterEvent("PLAYER_ENTERING_WORLD")
EF:RegisterEvent("CHALLENGE_MODE_START")
EF:RegisterEvent("CHALLENGE_MODE_COMPLETED")
EF:RegisterEvent("ENCOUNTER_END")
EF:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
EF:RegisterEvent("SCENARIO_COMPLETED")

EF:SetScript("OnEvent", function(_, event, ...) TS:OnScoreEvent(event, ...) end)

function TS:OnScoreEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        -- Module enabled check
        local db = self:GetDB()
        if not db or not db.enabled then
            EF:UnregisterAllEvents()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        self._completionShown = false
        local _, _, difficultyID = GetInstanceInfo()
        if difficultyID == 8 then
            self._inMythicDungeon = true
            self._challengeActive = true
            self:_UpdateBossCount()
        elseif difficultyID == 23 then
            self._inMythicDungeon = true
            self._challengeActive = false
            self:_UpdateBossCount()
        else
            self._inMythicDungeon = false
            self._challengeActive = false
        end

    elseif event == "CHALLENGE_MODE_START" then
        self._challengeActive = true
        self._completionShown = false
        self._bossesKilled = 0
        self:_UpdateBossCount()

    elseif event == "CHALLENGE_MODE_COMPLETED" then
        if self._completionShown then return end
        self._completionShown = true
        local db = self:GetDB()
        if db and not db.autoShowMPlus then return end
        C_Timer.After(1.5, function()
            self:_TriggerScoreboard()
        end)

    elseif event == "ENCOUNTER_END" then
        if not self._inMythicDungeon or self._challengeActive then return end
        local _, _, _, _, success = ...
        if success == 1 then
            self._bossesKilled = self._bossesKilled + 1
            self:_CheckM0Completion()
        end

    elseif event == "SCENARIO_CRITERIA_UPDATE" or event == "SCENARIO_COMPLETED" then
        if not self._inMythicDungeon or self._challengeActive then return end
        self:_UpdateBossProgress()
        self:_CheckM0Completion()
    end
end

function TS:_UpdateBossCount()
    local _, _, numSteps = C_Scenario.GetStepInfo()
    if numSteps and numSteps > 0 then
        local totalBosses = 0
        local killed = 0
        for stepIdx = 1, numSteps do
            local stepInfo = C_ScenarioInfo.GetCriteriaInfo(stepIdx)
            if stepInfo then
                totalBosses = totalBosses + 1
                if stepInfo.completed then
                    killed = killed + 1
                end
            end
        end
        if totalBosses == 0 then
            totalBosses = numSteps
        end
        self._totalBosses  = totalBosses
        self._bossesKilled = killed
    end
end

function TS:_UpdateBossProgress()
    local _, _, numSteps = C_Scenario.GetStepInfo()
    if not numSteps or numSteps == 0 then return end
    local killed = 0
    local total  = 0
    for stepIdx = 1, numSteps do
        local stepInfo = C_ScenarioInfo.GetCriteriaInfo(stepIdx)
        if stepInfo then
            total = total + 1
            if stepInfo.completed then
                killed = killed + 1
            end
        end
    end
    if total > 0 then
        self._totalBosses  = total
        self._bossesKilled = killed
    end
end

function TS:_CheckM0Completion()
    if self._completionShown then return end
    if self._totalBosses <= 0 then return end
    if self._bossesKilled >= self._totalBosses then
        self._completionShown = true
        local db = self:GetDB()
        if db and not db.autoShowM0 then return end
        C_Timer.After(2.0, function()
            self:_TriggerScoreboard()
        end)
    end
end

function TS:_TriggerScoreboard()
    local data = self:CollectRunData()
    if not data or #data.players == 0 then
        C_Timer.After(2.0, function()
            local data2 = self:CollectRunData()
            if data2 and #data2.players > 0 then
                self:SaveRunData(data2)
                self:ShowScoreboard(data2)
            end
        end)
        return
    end
    self:SaveRunData(data)
    self:ShowScoreboard(data)
end

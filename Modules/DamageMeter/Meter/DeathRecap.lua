local ADDON_NAME, TomoMod = ...

-- [MERGE] Standalone, `ns` was this addon's own private table. Embedded, the
-- vararg hands over TomoMod's, which every other file in the suite shares --
-- so 157 generic names (db, L, FONT, BG, ACCENT, Refresh, windows, inCombat)
-- would sit in the same table as everything TomoMod ever adds. Nothing
-- collides today, but the first core file that reaches for `ns.db` would
-- find this module's and neither would know.
--
-- One sub-table keeps the module's world to itself, and leaves every `ns.X`
-- below untouched.
local ns = TomoMod.DM
local L = ns.L

----------------------------------------------------------------------
-- DeathRecap: standalone window showing the last events before a death.
-- Data comes from C_DeathRecap (via ns.GetDeathRecap); the recapID is the
-- per-source deathRecapID carried by the C_DamageMeter Deaths category.
--
-- Opened by clicking a player in the Deaths category, or (optionally) auto
-- on the local player's death when db.deathRecapAutoShow is set.
----------------------------------------------------------------------

local WINDOW_WIDTH  = 340
local HEADER_HEIGHT = 26
local ROW_HEIGHT    = 22
local ROW_SPACING   = 1
local MAX_ROWS      = 16
local BORDER_SIZE   = 1
local TEXT_PAD      = 6
local ICON_PAD      = 2

-- Key under which this window's position is stored in ns.db.framePositions.
local POSITION_KEY = "deathRecap"

local recapFrame = nil
local rows = {}

----------------------------------------------------------------------
-- Window construction (singleton)
----------------------------------------------------------------------

local function EnsureWindow()
    if recapFrame then return recapFrame end

    local frame = CreateFrame("Frame", "TomoDMDeathRecap", UIParent, "BackdropTemplate")
    frame:SetSize(WINDOW_WIDTH, HEADER_HEIGHT + 4 * (ROW_HEIGHT + ROW_SPACING) + BORDER_SIZE)
    -- Centred only until the window has been moved once; after that the saved
    -- position wins. Restoring here rather than on every Show means dragging
    -- the window while it is open is never fought by a re-anchor.
    if not ns.RestoreFramePosition(frame, POSITION_KEY) then
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    end
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        ns.SaveFramePosition(self, POSITION_KEY)
    end)

    frame:SetBackdrop({
        bgFile   = ns.FLAT,
        edgeFile = ns.FLAT,
        edgeSize = BORDER_SIZE,
    })
    frame:SetBackdropColor(ns.BG[1], ns.BG[2], ns.BG[3], ns.db and ns.db.bgAlpha or ns.BG[4])
    frame:SetBackdropBorderColor(unpack(ns.BORDER_COLOR))

    tinsert(UISpecialFrames, "TomoDMDeathRecap")

    -- Header
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", BORDER_SIZE, -BORDER_SIZE)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -BORDER_SIZE, -BORDER_SIZE)
    header:SetHeight(HEADER_HEIGHT)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() frame:StartMoving() end)
    header:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        ns.SaveFramePosition(frame, POSITION_KEY)
    end)

    local headerBG = header:CreateTexture(nil, "BACKGROUND")
    headerBG:SetTexture(ns.FLAT); headerBG:SetVertexColor(unpack(ns.HEADER_BG))
    headerBG:SetAllPoints()

    local headerSep = frame:CreateTexture(nil, "OVERLAY")
    headerSep:SetTexture(ns.FLAT); headerSep:SetVertexColor(unpack(ns.BORDER_COLOR))
    headerSep:SetHeight(1)
    headerSep:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
    headerSep:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT")
    frame._headerSep = headerSep

    local icon = header:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(135771) -- generic skull-ish spell icon
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", header, "LEFT", TEXT_PAD, 0)

    local titleFS = header:CreateFontString(nil, "ARTWORK")
    titleFS:SetFont(ns.GetFont(), 12, "OUTLINE")
    ns.Tint(titleFS, "accent")
    titleFS:SetPoint("LEFT", icon, "RIGHT", 6, ns.GetFontNudge())
    titleFS:SetText(L["DEATH_RECAP"])

    local nameFS = header:CreateFontString(nil, "ARTWORK")
    nameFS:SetFont(ns.GetFont(), 11, "OUTLINE")
    ns.Tint(nameFS, "secondary")
    nameFS:SetPoint("LEFT", titleFS, "RIGHT", 8, 0)
    nameFS:SetWordWrap(false)
    frame._nameFS = nameFS

    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(HEADER_HEIGHT, HEADER_HEIGHT)
    closeBtn:SetPoint("TOPRIGHT", header, "TOPRIGHT")
    local closeIcon = closeBtn:CreateTexture(nil, "ARTWORK")
    closeIcon:SetTexture(ns.TEX_CLOSE); closeIcon:SetSize(10, 10); closeIcon:SetPoint("CENTER")
    closeIcon:SetVertexColor(unpack(ns.TEXT_MUTED))
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeIcon:SetVertexColor(1, 1, 1) end)
    closeBtn:SetScript("OnLeave", function() closeIcon:SetVertexColor(unpack(ns.TEXT_MUTED)) end)
    local closeHL = closeBtn:CreateTexture(nil, "HIGHLIGHT")
    closeHL:SetTexture(ns.FLAT); closeHL:SetVertexColor(1, 1, 1, 0.06); closeHL:SetAllPoints()

    -- No-data label
    local noDataFS = frame:CreateFontString(nil, "ARTWORK")
    noDataFS:SetFont(ns.GetFont(), 11, "OUTLINE")
    ns.Tint(noDataFS, "muted")
    noDataFS:SetPoint("TOP", headerSep, "BOTTOM", 0, -20)
    noDataFS:SetText(L["DEATH_RECAP_NO_DATA"])
    noDataFS:Hide()
    frame._noDataFS = noDataFS

    frame:Hide()
    recapFrame = frame
    return frame
end

----------------------------------------------------------------------
-- Row pool
----------------------------------------------------------------------

local function EnsureRow(i)
    if rows[i] then return rows[i] end
    local frame = recapFrame

    local row = CreateFrame("Frame", nil, frame)
    row:SetHeight(ROW_HEIGHT)

    local rowIcon = row:CreateTexture(nil, "ARTWORK")
    rowIcon:SetPoint("LEFT", row, "LEFT", 0, 0)
    rowIcon:SetSize(ROW_HEIGHT - 2, ROW_HEIGHT - 2)
    rowIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row._icon = rowIcon

    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetPoint("TOPLEFT", rowIcon, "TOPRIGHT", ICON_PAD, 0)
    bar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    bar:SetStatusBarTexture(ns.GetBarTexture())
    row._bar = bar

    -- Faint track behind the HP bar
    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetTexture(ns.FLAT); track:SetVertexColor(0.10, 0.10, 0.12, 0.5)
    track:SetAllPoints()

    local labelFS = bar:CreateFontString(nil, "OVERLAY")
    labelFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
    labelFS:SetJustifyH("LEFT")
    labelFS:SetWordWrap(false)
    labelFS:SetShadowOffset(1, -1); labelFS:SetShadowColor(0, 0, 0, 0.5)
    labelFS:SetPoint("LEFT", bar, "LEFT", TEXT_PAD, ns.GetFontNudge())
    row._label = labelFS

    local amountFS = bar:CreateFontString(nil, "OVERLAY")
    amountFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
    amountFS:SetJustifyH("RIGHT")
    amountFS:SetShadowOffset(1, -1); amountFS:SetShadowColor(0, 0, 0, 0.5)
    amountFS:SetPoint("RIGHT", bar, "RIGHT", -TEXT_PAD, ns.GetFontNudge())
    row._amount = amountFS

    labelFS:SetPoint("RIGHT", amountFS, "LEFT", -6, 0)

    -- Spell tooltip on hover (only for rows with a real spellID)
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        if self._spellID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(self._spellID)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    rows[i] = row
    return row
end

----------------------------------------------------------------------
-- Populate
----------------------------------------------------------------------

local function Populate(frame, recapID)
    local events, maxHP = ns.GetDeathRecap(recapID)

    for _, r in ipairs(rows) do r:Hide() end

    if not events or #events == 0 then
        frame._noDataFS:Show()
        frame:SetHeight(HEADER_HEIGHT + 60 + BORDER_SIZE)
        return
    end
    frame._noDataFS:Hide()

    local total = #events
    local count = math.min(MAX_ROWS, total)
    local startIdx = total - count -- keep the most recent (pre-death) events
    -- May be nil: timestamps are secretvalue-guarded upstream and can be
    -- dropped. Rows then fall back to a plain spell label instead of doing
    -- arithmetic on a missing value.
    local deathTime = events[total].timestamp

    local stride = ROW_HEIGHT + ROW_SPACING
    local yTop = -(HEADER_HEIGHT + BORDER_SIZE + 1)

    for i = 1, count do
        local ev = events[startIdx + i]
        local row = EnsureRow(i)
        local isFatal = (i == count and not ev.isHeal)

        row._icon:SetTexture(ev.icon or 135274)

        -- Bar = HP% remaining at this event (drains toward the death)
        local hpPct = maxHP > 0 and (ev.currentHP / maxHP) or 0
        if hpPct < 0 then hpPct = 0 elseif hpPct > 1 then hpPct = 1 end
        local barTex = ns.GetBarTexture()
        row._bar:SetStatusBarTexture(barTex)
        row._bar:SetMinMaxValues(0, 1)
        row._bar:SetValue(hpPct)
        if ev.isHeal then
            row._bar:SetStatusBarColor(0.12, 0.55, 0.12, 1)
        elseif isFatal then
            row._bar:SetStatusBarColor(0.85, 0.12, 0.12, 1)
        else
            row._bar:SetStatusBarColor(0.55, 0.10, 0.10, 1)
        end
        local fill = row._bar:GetStatusBarTexture()
        if fill then fill:SetAlpha(ns.BAR_ALPHA) end

        -- Label: time-before-death + spell name (the delta is dropped when
        -- either timestamp is unavailable).
        local spellLabel = ev.name or "?"
        if deathTime and ev.timestamp then
            spellLabel = string.format("-%.1fs  ", deathTime - ev.timestamp) .. spellLabel
        end
        row._label:SetText(spellLabel)
        ns.Tint(row._label, "primary")

        -- Amount: signed value, overkill on the fatal blow, HP% remaining
        local amtStr
        if ev.isHeal then
            amtStr = "|cff40d040+" .. ns.FormatNumber(math.abs(ev.amount), "short") .. "|r"
        else
            amtStr = "-" .. ns.FormatNumber(ev.amount, "short")
        end
        local pctStr = string.format("  (%d%%)", math.floor(hpPct * 100 + 0.5))
        if isFatal and ev.overkill and ev.overkill > 0 then
            row._amount:SetText(amtStr .. " |cffff3333(" .. ns.FormatNumber(ev.overkill, "short") .. ")|r" .. pctStr)
        else
            row._amount:SetText(amtStr .. pctStr)
        end
        ns.Tint(row._amount, "primary")

        row._spellID = ev.spellID
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", BORDER_SIZE, yTop - (i - 1) * stride)
        row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -BORDER_SIZE, yTop - (i - 1) * stride)
        row:SetHeight(ROW_HEIGHT)
        row:Show()
    end

    frame:SetHeight(HEADER_HEIGHT + BORDER_SIZE + 1 + count * stride + 2)
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

function ns.ShowDeathRecap(recapID, playerName, classFilename)
    local frame = EnsureWindow()
    frame:SetAlpha(ns.db and ns.db.breakdownAlpha or 0.85)

    local name = playerName
    if name and issecretvalue(name) then name = "?" end
    if name and ns.db and ns.db.stripRealm then name = ns.StripRealm(name) end
    local cc = classFilename and RAID_CLASS_COLORS[classFilename]
    if cc then
        frame._nameFS:SetText(name or "")
        frame._nameFS:SetTextColor(cc.r, cc.g, cc.b)
    else
        frame._nameFS:SetText(name or "")
        ns.Tint(frame._nameFS, "secondary")
    end

    Populate(frame, recapID)
    frame:Show()
    -- Populate has just set the final height, so the clamp can see the real
    -- size. Deferred by a frame because GetLeft/GetTop are only meaningful
    -- after the layout pass that Show() schedules.
    C_Timer.After(0, function()
        if frame:IsShown() then ns.ClampFrameToScreen(frame) end
    end)
end

function ns.HideDeathRecap()
    if recapFrame then recapFrame:Hide() end
end

-- Back to centre, for when the window has been parked somewhere unreachable
-- (or off a monitor that is no longer attached).
function ns.ResetDeathRecapPosition()
    ns.ResetFramePosition(POSITION_KEY)
    if recapFrame then
        recapFrame:ClearAllPoints()
        recapFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    end
end

function ns.ApplyDeathRecapAlpha()
    if recapFrame then
        recapFrame:SetAlpha(ns.db and ns.db.breakdownAlpha or 0.85)
    end
end

----------------------------------------------------------------------
-- Optional auto-popup on the local player's death
----------------------------------------------------------------------

local deathFrame = CreateFrame("Frame")
ns._deathRecapFrame = deathFrame
deathFrame:RegisterEvent("PLAYER_DEAD")
deathFrame:SetScript("OnEvent", function()
    if ns.Blocked and ns.Blocked() then return end
    if not (ns.db and ns.db.deathRecapAutoShow) then return end
    -- Small delay: the Deaths session / recap data lands a beat after PLAYER_DEAD.
    C_Timer.After(0.5, function()
        if not (ns.db and ns.db.deathRecapAutoShow) then return end
        local rid, name, classFile = ns.FindLocalDeathRecap()
        if rid then
            if not name then
                name = UnitName("player")
                local _, cf = UnitClass("player")
                classFile = classFile or cf
            end
            ns.ShowDeathRecap(rid, name, classFile)
        end
    end)
end)

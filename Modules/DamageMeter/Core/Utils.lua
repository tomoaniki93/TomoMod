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

----------------------------------------------------------------------
-- Number Formatting
----------------------------------------------------------------------

-- Custom breakpoints for AbbreviateNumbers (compact / no decimals)
local BREAKPOINTS_SHORT = {
    { breakpoint = 1000000000, significandDivisor = 1000000000, fractionDivisor = 1, abbreviation = "B", abbreviationIsGlobal = false },
    { breakpoint = 1000000,    significandDivisor = 1000000,    fractionDivisor = 1, abbreviation = "M", abbreviationIsGlobal = false },
    { breakpoint = 1000,       significandDivisor = 1000,       fractionDivisor = 1, abbreviation = "K", abbreviationIsGlobal = false },
    { breakpoint = 1,          significandDivisor = 1,          fractionDivisor = 1, abbreviation = "",  abbreviationIsGlobal = false },
}
local OPTS_SHORT = { breakpointData = BREAKPOINTS_SHORT }

-- 1-decimal
local BREAKPOINTS_1DEC = {
    { breakpoint = 1000000000, significandDivisor = 100000000, fractionDivisor = 10, abbreviation = "B", abbreviationIsGlobal = false },
    { breakpoint = 1000000,    significandDivisor = 100000,    fractionDivisor = 10, abbreviation = "M", abbreviationIsGlobal = false },
    { breakpoint = 1000,       significandDivisor = 100,       fractionDivisor = 10, abbreviation = "K", abbreviationIsGlobal = false },
    { breakpoint = 1,          significandDivisor = 0.1,       fractionDivisor = 10, abbreviation = "",  abbreviationIsGlobal = false },
}
local OPTS_1DEC = { breakpointData = BREAKPOINTS_1DEC }

-- 2-decimal
local BREAKPOINTS_2DEC = {
    { breakpoint = 1000000000, significandDivisor = 10000000, fractionDivisor = 100, abbreviation = "B", abbreviationIsGlobal = false },
    { breakpoint = 1000000,    significandDivisor = 10000,    fractionDivisor = 100, abbreviation = "M", abbreviationIsGlobal = false },
    { breakpoint = 1000,       significandDivisor = 10,       fractionDivisor = 100, abbreviation = "K", abbreviationIsGlobal = false },
    { breakpoint = 1,          significandDivisor = 0.01,      fractionDivisor = 100, abbreviation = "",  abbreviationIsGlobal = false },
}
local OPTS_2DEC = { breakpointData = BREAKPOINTS_2DEC }

-- 3-decimal. Keeps every significant digit of a 5-figure thousands value while
-- still rolling the unit over: 16,156,000 reads "16.156M" rather than the
-- "16156 K" AbbreviateLargeNumbers produces, which pins the unit at K forever
-- and just lets the number grow. Same shape as the tables above:
-- significandDivisor = breakpoint / fractionDivisor.
local BREAKPOINTS_3DEC = {
    { breakpoint = 1000000000, significandDivisor = 1000000, fractionDivisor = 1000, abbreviation = "B", abbreviationIsGlobal = false },
    { breakpoint = 1000000,    significandDivisor = 1000,    fractionDivisor = 1000, abbreviation = "M", abbreviationIsGlobal = false },
    { breakpoint = 1000,       significandDivisor = 1,       fractionDivisor = 1000, abbreviation = "K", abbreviationIsGlobal = false },
    { breakpoint = 1,          significandDivisor = 0.001,   fractionDivisor = 1000, abbreviation = "",  abbreviationIsGlobal = false },
}
local OPTS_3DEC = { breakpointData = BREAKPOINTS_3DEC }

-- "full" = no abbreviation at all. Routed through AbbreviateNumbers with a
-- single pass-through breakpoint instead of AbbreviateLargeNumbers, which does
-- its comparisons in Lua and therefore errors on a secret value. Since "full"
-- is the fmt seeded for legacy DB rows, that path was reachable in normal play.
local BREAKPOINTS_FULL = {
    { breakpoint = 0, significandDivisor = 1, fractionDivisor = 1, abbreviation = "", abbreviationIsGlobal = false },
}
local OPTS_FULL = { breakpointData = BREAKPOINTS_FULL }

function ns.FormatNumber(value, fmt)
    if value == nil then return "0" end
    -- Secret values (mid-combat under Midnight) must NOT be intercepted:
    -- AbbreviateNumbers is secret-tolerant (C-side) and returns a string
    -- that C-side text setters render fine. Only the sub-1000 Lua branch
    -- below is skipped, because comparing/formatting a secret in Lua errors.
    -- (Same pattern as EUI's AbbrevNumber: no secret guard before
    -- AbbreviateNumbers. A "..." placeholder here blanked all combat values
    -- in v1.6.1.)
    if not issecretvalue(value) and value < 1000 then
        if fmt == "short" then
            return tostring(math.floor(value + 0.5))
        elseif fmt == "1dec" then
            return string.format("%.1f", value)
        elseif fmt == "2dec" then
            return string.format("%.2f", value)
        elseif fmt == "3dec" then
            return string.format("%.3f", value)
        else -- "full"
            return string.format("%.0f", value)
        end
    end
    if fmt == "short" then
        return AbbreviateNumbers(value, OPTS_SHORT)
    elseif fmt == "1dec" then
        return AbbreviateNumbers(value, OPTS_1DEC)
    elseif fmt == "2dec" then
        return AbbreviateNumbers(value, OPTS_2DEC)
    elseif fmt == "3dec" then
        return AbbreviateNumbers(value, OPTS_3DEC)
    else
        return AbbreviateNumbers(value, OPTS_FULL)
    end
end

----------------------------------------------------------------------
-- Column width measurement
----------------------------------------------------------------------

local FORMAT_CHARS = {
    short = 4,
    ["1dec"] = 6,
    ["2dec"] = 8,
    ["3dec"] = 8,   -- "16.156M"
    -- "full" prints the unabbreviated number, so it needs room for a raw
    -- 9-10 digit total, not the 7 chars an abbreviated one takes.
    full  = 11,
    int   = 4,
    dec   = 6,
}

-- Extra chars for the total column (parentheses)
local TOTAL_EXTRA_CHARS = 2

local charWidthCache = {}
local measureFS = nil

local function GetCharWidth(fontSize)
    local fontPath = ns.db and ns.db.fontPath or ns.FONT
    local key = fontPath .. ":" .. fontSize
    if charWidthCache[key] then return charWidthCache[key] end
    if not measureFS then
        measureFS = UIParent:CreateFontString(nil, "ARTWORK")
    end
    measureFS:SetFont(fontPath, fontSize, "OUTLINE")
    measureFS:SetText("0000000000")
    local w = measureFS:GetStringWidth()
    local cw = w / 10
    charWidthCache[key] = cw
    return cw
end

function ns.ClearCharWidthCache()
    charWidthCache = {}
end

local COL_PAD = 4

local function ColPixelWidth(chars, fontSize)
    return math.ceil(chars * GetCharWidth(fontSize)) + COL_PAD
end

-- Exposed so the breakdown windows size their columns the same way the main
-- meter does. They used hard-coded pixel constants while rendering with the
-- user's font size, so anything above the default clipped: ranks past "9."
-- collapsed to an ellipsis and two-digit percentages were cut off.
-- @param chars number widest expected content, in characters
-- @param fontSize number|nil defaults to the configured bar font size
function ns.ColWidth(chars, fontSize)
    return ColPixelWidth(chars, fontSize or ns.GetFontSize())
end

----------------------------------------------------------------------
-- Timer formatting
----------------------------------------------------------------------

function ns.FormatTimer(seconds)
    if not seconds or seconds <= 0 then return "" end
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    if m > 0 then
        return string.format("%d:%02d", m, s)
    else
        return string.format("0:%02d", s)
    end
end

----------------------------------------------------------------------
-- Strip realm from "Name-Server"
----------------------------------------------------------------------

function ns.StripRealm(name)
    if not name then return name end
    if issecretvalue(name) then return name end
    local short = name:match("^([^%-]+)")
    return short or name
end

----------------------------------------------------------------------
-- Instance identity
----------------------------------------------------------------------

-- Instance types worth tracking. Everything else (world, arena, pvp) is
-- ignored by both the auto-reset and the run recap.
ns.TRACKED_INSTANCE_TYPES = {
    party    = true,
    raid     = true,
    scenario = true,
}

-- Stable identifier for the instance the player is standing in, or nil when
-- the current zone is not tracked.
--
-- This exists so "I walked into a new dungeon" can be told apart from "I
-- reloaded the UI inside the dungeon I was already in". A Lua local cannot
-- answer that question: /reload rebuilds the Lua state, so anything held in a
-- local comes back at its default and the first PLAYER_ENTERING_WORLD after a
-- reload looks exactly like a fresh entry. A string in SavedVariables does
-- survive the reload, which is why the key is a string.
function ns.GetInstanceKey()
    local inInstance, instanceType = IsInInstance()
    if not inInstance or not ns.TRACKED_INSTANCE_TYPES[instanceType] then
        return nil
    end
    local ok, _, _, difficultyID, _, _, _, _, instanceID = pcall(GetInstanceInfo)
    if not ok then return nil end
    return instanceType .. ":" .. tostring(instanceID or 0) .. ":" .. tostring(difficultyID or 0)
end

----------------------------------------------------------------------
-- Column value population
----------------------------------------------------------------------

-- Actions category types: display as simple integer count
ns.ACTIONS_TYPES = {
    [Enum.DamageMeterType.Interrupts] = true,
    [Enum.DamageMeterType.Dispels] = true,
    [Enum.DamageMeterType.Deaths] = true,
}

function ns.PopulateColumnValues(button, elementData)
    local total = elementData.totalAmount or 0
    local rate = elementData.amountPerSecond
    local sessionTotal = elementData.sessionTotal

    -- Actions category: show only integer total with trailing dot
    if elementData.isActionType then
        button.rateFS:SetText("")
        button.rateFS:Hide()
        button.totalFS:SetText("")
        button.totalFS:Hide()
        button.pctFS:SetText("")
        button.pctFS:Hide()

        if not button.actionFS then
            local fs = button.bar:CreateFontString(nil, "OVERLAY")
            fs:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            fs:SetJustifyH("RIGHT")
            fs:SetShadowOffset(1, -1)
            fs:SetShadowColor(0, 0, 0, 0.4)
            button.actionFS = fs
        end
        button.actionFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
        -- totalAmount is a secret value during combat for action types.
        -- SetFormattedText is a C-side widget method: the formatting happens
        -- in C, not Lua, so it can accept secret values without taint.
        button.actionFS:SetFormattedText("%.0f", total)
        ns.Tint(button.actionFS, "primary")
        button.actionFS:ClearAllPoints()
        button.actionFS:SetPoint("RIGHT", button.bar, "RIGHT", -6, ns.GetFontNudge())
        button.actionFS:Show()
        return
    end

    -- Hide actionFS if it was created from a previous Actions view
    if button.actionFS then
        button.actionFS:Hide()
    end

    local fsMap = { rate = button.rateFS, total = button.totalFS, pct = button.pctFS }
    for _, col in ipairs(ns.db.columns) do
        local fs = fsMap[col.key]
        if col.show and col.key == "rate" and rate then
            fs:SetText(ns.FormatNumber(rate, col.fmt))
            fs:Show()
        elseif col.show and col.key == "total" then
            fs:SetText("(" .. ns.FormatNumber(total, col.fmt) .. ")")
            fs:Show()
        elseif col.show and col.key == "pct" and not issecretvalue(total)
            and sessionTotal and not issecretvalue(sessionTotal) and sessionTotal > 0 then
            local pctFmt = col.fmt == "dec" and "%.1f%%" or "%d%%"
            fs:SetText(string.format(pctFmt, total / sessionTotal * 100))
            fs:Show()
        elseif col.show and col.key == "pct" then
            fs:SetText("-")
            fs:Show()
        else
            fs:SetText("")
            fs:Hide()
        end
    end
end

----------------------------------------------------------------------
-- Column anchoring
----------------------------------------------------------------------

function ns.AnchorColumns(button)
    button.pctFS:ClearAllPoints()
    button.totalFS:ClearAllPoints()
    button.rateFS:ClearAllPoints()

    -- Actions mode: actionFS is the only right-side element
    if button.actionFS and button.actionFS:IsShown() then
        return button.actionFS
    end

    local fontSize = ns.GetFontSize()
    local fsMap = { rate = button.rateFS, total = button.totalFS, pct = button.pctFS }
    local prevFS = nil
    for i = #ns.db.columns, 1, -1 do
        local col = ns.db.columns[i]
        if col.show then
            local fs = fsMap[col.key]
            local chars = FORMAT_CHARS[col.fmt] or 6
            if col.key == "total" then chars = chars + TOTAL_EXTRA_CHARS end
            fs:SetWidth(ColPixelWidth(chars, fontSize))
            if not prevFS then
                fs:SetPoint("RIGHT", button.bar, "RIGHT", -4, ns.GetFontNudge())
            else
                fs:SetPoint("RIGHT", prevFS, "LEFT", -2, 0)
            end
            prevFS = fs
        end
    end
    return prevFS
end

----------------------------------------------------------------------
-- Inline spell sub-rows (expanded player in the main meter)
----------------------------------------------------------------------
-- Appends this player's spells as `kind == "spell"` element-data entries into
-- an existing element list, right after their player row. Pure data shaping:
-- ns.GetSpellBreakdown already returns fully-resolved plain numbers, so no
-- secret-value handling is needed past the parent-total fallback. The columns
-- reuse ns.PopulateColumnValues via totalAmount / amountPerSecond / sessionTotal,
-- where sessionTotal = the player's own total so the pct column reads as the
-- spell's share of that player (matching how a breakdown should look).
function ns.AppendSpellRows(elements, sessionType, meterType, guid, parentTotal, classFilename)
    local L = ns.L
    local spells = ns.GetSpellBreakdown(sessionType, meterType, guid)

    if not spells or #spells == 0 then
        elements[#elements + 1] = {
            kind = "spell",
            isEmpty = true,
            name = L["NO_DATA"],
            classFilename = classFilename,
        }
        return
    end

    -- Parent total may be a secret value mid-combat; fall back to the sum of
    -- the (already-resolved) spell totals so the pct column stays meaningful.
    local ptotal = parentTotal
    if ptotal == nil or issecretvalue(ptotal) then
        ptotal = 0
        for _, s in ipairs(spells) do ptotal = ptotal + (s.total or 0) end
    end

    local maxTotal = spells[1].total
    local info = ns.TYPE_INFO[meterType]
    local rateKey = info and info.key

    for i, s in ipairs(spells) do
        local dn = "|cff6a6a72" .. i .. ".|r " .. (s.name or "?")
        if s.creatureName then
            dn = dn .. "  |cff8a8a99(" .. s.creatureName .. ")|r"
        end
        elements[#elements + 1] = {
            kind            = "spell",
            classFilename   = classFilename,
            name            = s.name,          -- tooltip title
            displayName     = dn,              -- rendered label (rank + pet)
            icon            = s.icon,
            totalAmount     = s.total,
            amountPerSecond = s.perSec,
            sessionTotal    = ptotal,          -- pct column => share of player
            maxAmount       = maxTotal,        -- bar scale within the group
            isActionType    = false,
            -- Tooltip extras (read by ns.BuildSpellTooltip):
            total           = s.total,
            perSec          = s.perSec,
            pct             = s.pct,
            rateKey         = rateKey,
            creatureName    = s.creatureName,
            overkill        = s.overkill,
            isAvoidable     = s.isAvoidable,
            isDeadly        = s.isDeadly,
        }
    end
end

----------------------------------------------------------------------
-- Informative hover tooltips
----------------------------------------------------------------------
-- Both builders are pure display helpers. They run only on hover (never on
-- the combat hot path) and guard every value with issecretvalue before any
-- Lua-side arithmetic. Anything still secret is simply omitted from the
-- tooltip rather than risking taint.

local ICON_ESCAPE = "|T%d:14:14:0:0:64:64:5:59:5:59|t "

-- Player bar tooltip: identity + headline stat + a top-spell sublist.
-- @param owner Frame the tooltip anchors to
-- @param ed table the bar's element data (name / classFilename / totals / GUID)
-- @param meterType number Enum.DamageMeterType
-- @param sessionType number Enum.DamageMeterSessionType
function ns.BuildBarTooltip(owner, ed, meterType, sessionType)
    local L = ns.L
    local GT = GameTooltip
    GT:SetOwner(owner, "ANCHOR_RIGHT")
    GT:ClearLines()

    -- Title: player name, class-coloured when the class is known.
    local name = ed.name
    if name ~= nil and issecretvalue(name) then name = "?" end
    if name and ns.db and ns.db.stripRealm then name = ns.StripRealm(name) end
    local cc = ed.classFilename and RAID_CLASS_COLORS[ed.classFilename]
    if cc then
        GT:AddLine(name or "?", cc.r, cc.g, cc.b)
    else
        GT:AddLine(name or "?", 1, 1, 1)
    end

    local isAction = ns.ACTIONS_TYPES[meterType]

    -- Headline rate (DPS / HPS) for rate-primary meters, when readable.
    if ns.RATE_PRIMARY[meterType] then
        local rate = ed.amountPerSecond
        if rate ~= nil and not issecretvalue(rate) then
            local info = ns.TYPE_INFO[meterType]
            local label = (info and L[info.key]) or L["DPS"]
            GT:AddDoubleLine(label, ns.FormatNumber(rate, "1dec"), 0.7, 0.7, 0.7, 1, 1, 1)
        end
    end

    -- Total (+ share of the session) when readable.
    local total = ed.totalAmount
    if total ~= nil and not issecretvalue(total) then
        local right = ns.FormatNumber(total, isAction and "short" or "1dec")
        local st = ed.sessionTotal
        if st and not issecretvalue(st) and st > 0 then
            right = right .. string.format("  (%.1f%%)", total / st * 100)
        end
        GT:AddDoubleLine(L["TIP_TOTAL"], right, 0.7, 0.7, 0.7, 1, 1, 1)
    end

    -- Top-spell sublist (reuses the same data path as the breakdown window).
    if ed.sourceGUID and not issecretvalue(ed.sourceGUID) then
        local spells = ns.GetSpellBreakdown(sessionType, meterType, ed.sourceGUID)
        if spells and #spells > 0 then
            GT:AddLine(" ")
            GT:AddLine(L["TIP_TOP_SPELLS"], ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3])
            for i = 1, math.min(5, #spells) do
                local s = spells[i]
                local label = s.name or "?"
                if s.creatureName then
                    label = label .. "  |cff8a8a99(" .. s.creatureName .. ")|r"
                end
                if s.icon then label = ICON_ESCAPE:format(s.icon) .. label end
                local right = ns.FormatNumber(s.total, "1dec")
                if s.pct and s.pct > 0 then
                    right = string.format("%.0f%%  ", s.pct) .. right
                end
                GT:AddDoubleLine(label, right, 0.9, 0.9, 0.9, 0.78, 0.78, 0.82)
            end
        end
        GT:AddLine(" ")
        GT:AddLine(L["TIP_LEFT_EXPAND"], 0.2, 1, 0.2)
        GT:AddLine(L["TIP_RIGHT_WINDOW"], 0.45, 0.8, 0.45)
    end

    GT:Show()
end

-- Spell row tooltip (breakdown window): per-spell detail incl. the Midnight
-- extras (caster pet, overkill, avoidable / killing-blow flags).
-- @param owner Frame the tooltip anchors to
-- @param data table the spell row's element data
function ns.BuildSpellTooltip(owner, data)
    local L = ns.L
    local GT = GameTooltip
    GT:SetOwner(owner, "ANCHOR_RIGHT")
    GT:ClearLines()

    GT:AddLine(data.name or "?", 1, 1, 1)
    if data.creatureName then
        GT:AddLine(string.format(L["TIP_CAST_BY"], data.creatureName), 0.6, 0.6, 0.7)
    end

    if data.perSec and not issecretvalue(data.perSec) and data.perSec > 0 then
        local label = (data.rateKey and L[data.rateKey]) or L["DPS"]
        GT:AddDoubleLine(label, ns.FormatNumber(data.perSec, "1dec"), 0.7, 0.7, 0.7, 1, 1, 1)
    end

    if data.total and not issecretvalue(data.total) then
        local right = ns.FormatNumber(data.total, "1dec")
        if data.pct and data.pct > 0 then
            right = right .. string.format("  (%.1f%%)", data.pct)
        end
        GT:AddDoubleLine(L["TIP_TOTAL"], right, 0.7, 0.7, 0.7, 1, 1, 1)
    end

    if data.overkill and not issecretvalue(data.overkill) and data.overkill > 0 then
        GT:AddDoubleLine(L["TIP_OVERKILL"], ns.FormatNumber(data.overkill, "1dec"),
            0.7, 0.7, 0.7, 1, 0.5, 0.5)
    end

    if data.isAvoidable then
        GT:AddLine(L["TIP_AVOIDABLE"], 1, 0.82, 0.2)
    end
    if data.isDeadly then
        GT:AddLine(L["TIP_KILLING_BLOW"], 1, 0.3, 0.3)
    end

    GT:Show()
end

----------------------------------------------------------------------
-- Frame position persistence
----------------------------------------------------------------------

-- Shared by the secondary windows (death recap, breakdowns, run recap). The
-- main meter windows keep their own copy because their position lives inside
-- a per-window cfg table alongside size and docking state.
--
-- Positions are always stored as TOPLEFT anchored to UIParent's BOTTOMLEFT.
-- That matters for windows whose height changes between openings: anchoring by
-- the top edge means extra rows grow downward and the title bar stays exactly
-- where it was dropped. Anchoring by CENTER would make the window creep upward
-- every time it got taller.

local function PositionStore()
    if not ns.db then return nil end
    ns.db.framePositions = ns.db.framePositions or {}
    return ns.db.framePositions
end

function ns.SaveFramePosition(frame, key)
    local store = PositionStore()
    if not store then return end
    -- GetLeft/GetTop return nil for a frame that has never been laid out.
    -- Writing nil coordinates would leave a half-filled table that the restore
    -- pass then has to distrust, so bail instead.
    local left, top = frame:GetLeft(), frame:GetTop()
    if not left or not top then return end
    store[key] = { point = "TOPLEFT", relPoint = "BOTTOMLEFT", x = left, y = top }
end

-- Keeps a restored window on screen. SetClampedToScreen only governs dragging,
-- so a position saved at one resolution (or UI scale) can still land a window
-- off the edge when it is re-anchored programmatically. Height is read live
-- rather than from the saved data because these windows are resized by their
-- own content just before this runs.
function ns.ClampFrameToScreen(frame)
    local left, top = frame:GetLeft(), frame:GetTop()
    if not left or not top then return end
    local w, h = frame:GetWidth(), frame:GetHeight()
    local screenW, screenH = GetScreenWidth(), GetScreenHeight()
    local moved = false

    if left < 0 then left = 0; moved = true end
    if left + w > screenW then left = screenW - w; moved = true end
    if top > screenH then top = screenH; moved = true end
    if top - h < 0 then top = h; moved = true end

    if moved then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    end
end

-- Returns true when a saved position was applied, so callers can fall back to
-- their own default placement on the first ever opening.
function ns.RestoreFramePosition(frame, key)
    local store = PositionStore()
    local pos = store and store[key]
    if not pos or not pos.x or not pos.y then return false end
    frame:ClearAllPoints()
    frame:SetPoint(pos.point or "TOPLEFT", UIParent, pos.relPoint or "BOTTOMLEFT", pos.x, pos.y)
    return true
end

function ns.ResetFramePosition(key)
    local store = PositionStore()
    if store then store[key] = nil end
end

----------------------------------------------------------------------
-- Report to chat: data snapshot
----------------------------------------------------------------------

-- @param elements table|nil the window's last collected rows. Preferred source:
--        those were read inside a DAMAGE_METER_* handler, so their values are
--        plain numbers even mid-combat. The report button is a click handler,
--        where a fresh query comes back secret and the whole report bails out.
function ns.SnapshotReportData(meterType, sessionType, elements)
    local L = ns.L

    local info = ns.TYPE_INFO[meterType]
    local typeName = info and L[info.key] or "Unknown"
    local sessKey = ns.SESSION_KEYS[sessionType]
    local sessionName = sessKey and L[sessKey] or L["CURRENT"]
    local header = string.format(L["REPORT_HEADER"], typeName, sessionName)

    local isRate = ns.RATE_PRIMARY[meterType]
    local lines = {}

    local function AddRow(name, value)
        if name == nil or issecretvalue(name) then return false end
        if value == nil or issecretvalue(value) then return false end
        local rank = #lines + 1
        lines[rank] = rank .. ". " .. ns.FormatNumber(value, "1dec")
            .. "  " .. (ns.StripRealm(name) or "Unknown")
        return true
    end

    -- Preferred path: captured rows.
    if elements then
        for _, ed in ipairs(elements) do
            if ed.kind ~= "spell" then
                local value = isRate and ed.amountPerSecond or ed.totalAmount
                if not AddRow(ed.name, value) then break end
            end
        end
    end

    -- Fallback: live query. Fine out of combat, and covers the case where the
    -- window has not collected anything yet.
    if #lines == 0 then
        local session = C_DamageMeter.GetCombatSessionFromType(sessionType, meterType)
        if not session or issecretvalue(session) then return nil end
        local sources = session.combatSources
        if not sources or #sources == 0 then return nil end
        for _, source in ipairs(sources) do
            local value = isRate and source.amountPerSecond or source.totalAmount
            if not AddRow(source.name, value) then break end
        end
    end

    if #lines == 0 then return nil end
    return { header = header, lines = lines }
end

----------------------------------------------------------------------
-- Report to chat: send helper
----------------------------------------------------------------------

-- Chat types the client gates behind a hardware event, and lets through only
-- ONCE per event. A report is a header plus N lines, so on these channels the
-- first message goes out and every one after it raises ADDON_ACTION_BLOCKED —
-- which is what "TomoDamageMeter tried to call the protected function
-- UNKNOWN() (x4)" was. pcall does not help: a blocked call does not raise a
-- Lua error, it fires the event. The only fix is not to make the call.
ns.RESTRICTED_CHANNELS = {
    SAY     = true,
    YELL    = true,
    CHANNEL = true,
}

-- The global SendChatMessage is a deprecation shim in Midnight
-- (Blizzard_DeprecatedChatInfo), which is why it showed up in the middle of
-- the taint stack. Call the real entry point when the client has it.
local function ChatSend(message, channel, target)
    local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    pcall(send, message, channel, nil, target)
end

-- "AUTO" means "wherever the group actually is right now", which is what the
-- report almost always wants and, conveniently, is never a restricted channel.
function ns.ResolveReportChannel(channel)
    if channel ~= "AUTO" then return channel end

    local instanceCategory = (Enum and Enum.PartyCategory and Enum.PartyCategory.Instance)
        or LE_PARTY_CATEGORY_INSTANCE
    if instanceCategory and IsInGroup(instanceCategory) then return "INSTANCE_CHAT" end
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
    return "DEBUG"  -- solo: printing beats announcing to nobody
end

function ns.SendReport(snapshot, channel, maxLines)
    local L = ns.L
    local lines = snapshot.lines
    if maxLines > 0 and maxLines < #lines then
        lines = { unpack(lines, 1, maxLines) }
    end

    channel = ns.ResolveReportChannel(channel or "AUTO")

    if ns.RESTRICTED_CHANNELS[channel] then
        print(L["ADDON_PREFIX"] .. L["REPORT_CHANNEL_RESTRICTED"])
        return
    end

    if channel == "DEBUG" then
        print(L["ADDON_PREFIX"] .. snapshot.header)
        for _, line in ipairs(lines) do
            print(L["ADDON_PREFIX"] .. line)
        end
        return
    end

    local target = nil
    if channel == "WHISPER" then
        target = UnitIsPlayer("target") and GetUnitName("target", true) or nil
        if not target or target == "" then
            print(L["ADDON_PREFIX"] .. L["REPORT_NO_TARGET"])
            return
        end
    end

    ChatSend(snapshot.header, channel, target)
    for _, line in ipairs(lines) do
        ChatSend(line, channel, target)
    end
end
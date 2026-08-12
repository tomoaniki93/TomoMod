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
-- RunRecap: end-of-run group scoreboard.
--
-- ARCHITECTURE NOTE — why this accumulates instead of querying.
--
-- The obvious implementation reads C_DamageMeter when the dungeon ends. It
-- does not work. CHALLENGE_MODE_COMPLETED, LFG_COMPLETION_REWARD and zone
-- changes are not DAMAGE_METER_* events, and outside those handlers the API
-- returns secret values: no sorting, no comparison, no string.format. The
-- recap could not even rank players.
--
-- So nothing is read at the end. A snapshot is taken at every
-- PLAYER_REGEN_ENABLED — inside an event handler, where values are readable
-- and names have resolved. The Overall session is cumulative, so the last
-- snapshot of the run IS the run total; there is nothing to add up. One
-- snapshot per pull, roughly fifteen per key: the cost is nil.
--
-- Values that come back secret are skipped rather than written, so a player's
-- last readable figure survives. Overall totals only ever grow, which makes
-- keeping the previous value strictly better than blanking it.
----------------------------------------------------------------------

local WINDOW_WIDTH  = 470
local HEADER_HEIGHT = 26
local COLHDR_HEIGHT = 18
local ROW_HEIGHT    = 22
local ROW_SPACING   = 1
local MAX_ROWS      = 20
local BORDER_SIZE   = 1
local TEXT_PAD      = 6
local MAX_HISTORY   = 10

-- Tracked metrics. `rate` picks amountPerSecond over totalAmount.
-- Interrupts, Deaths and AvoidableDamageTaken cost the same API call as
-- DPS/HPS and answer the question the other three cannot: not who played well,
-- but why the run went wrong.
local METRICS = {
    { field = "dps",        mtype = Enum.DamageMeterType.Dps,                  rate = true,  labelKey = "DPS",                 fmt = "1dec" },
    { field = "hps",        mtype = Enum.DamageMeterType.Hps,                  rate = true,  labelKey = "HPS",                 fmt = "1dec" },
    { field = "interrupts", mtype = Enum.DamageMeterType.Interrupts,           rate = false, labelKey = "RECAP_COL_INT",       fmt = "int"  },
    { field = "deaths",     mtype = Enum.DamageMeterType.Deaths,               rate = false, labelKey = "RECAP_COL_DEATHS",    fmt = "int"  },
    { field = "avoidable",  mtype = Enum.DamageMeterType.AvoidableDamageTaken, rate = false, labelKey = "RECAP_COL_AVOIDABLE", fmt = "1dec" },
}

local COL_CHARS  = 7    -- widest numeric value, in characters
local NAME_CHARS = 13   -- name column budget

-- The window is sized from its columns, not the other way round. It used to be
-- a fixed 470px while the columns scale with the font: at size 14 the five
-- numeric columns ate the entire width and the name column was squeezed to
-- nothing, so end-of-run recaps showed rows of numbers with no player names.
local function ColumnWidth() return ns.ColWidth(COL_CHARS) end

local function DesiredWidth()
    return TEXT_PAD * 2 + ns.ColWidth(NAME_CHARS)
         + #METRICS * (ColumnWidth() + 4)
end

local currentRun = nil
local lastRun    = nil
local recapFrame = nil
local rows       = {}
local sortField  = "dps"

----------------------------------------------------------------------
-- Collection
----------------------------------------------------------------------

-- Merge one meter type's Overall session into the run. Caller must be inside
-- an event handler; see the architecture note above.
local function ReadInto(run, metric)
    local ok, session = pcall(C_DamageMeter.GetCombatSessionFromType,
        Enum.DamageMeterSessionType.Overall, metric.mtype)
    if not ok or not session or issecretvalue(session) then return end

    local sources = session.combatSources
    if not sources or issecretvalue(sources) then return end

    for _, src in ipairs(sources) do
        local guid = src.sourceGUID
        if guid ~= nil and not issecretvalue(guid) then
            local p = run.players[guid]
            if not p then
                p = { guid = guid }
                run.players[guid] = p
                run.order[#run.order + 1] = guid
            end

            local name = src.name
            if name ~= nil and not issecretvalue(name) then
                p.name = ns.StripRealm(name) or name
            end

            local cls = src.classFilename
            if cls ~= nil and not issecretvalue(cls) then p.class = cls end

            local value = metric.rate and src.amountPerSecond or src.totalAmount
            if value ~= nil and not issecretvalue(value) then
                p[metric.field] = value
            end
        end
    end
end

-- Called from the PLAYER_REGEN_ENABLED handler in Core/Database.lua.
function ns.RunRecapSnapshot()
    if not currentRun then return end
    for _, metric in ipairs(METRICS) do
        ReadInto(currentRun, metric)
    end
    currentRun.snapshots = (currentRun.snapshots or 0) + 1
end

----------------------------------------------------------------------
-- Run lifecycle
----------------------------------------------------------------------

local STALE_RUN_SECONDS = 4 * 60 * 60

local function ReadKeyLevel()
    local ok, level = pcall(function() return C_ChallengeMode.GetActiveKeystoneInfo() end)
    if ok and type(level) == "number" and level > 0 then return level end
    return nil
end

-- Pick up an in-progress run left behind by a /reload.
--
-- The run table is kept in SavedVariables as the live table, so it comes back
-- with every player and every snapshot already in it. Only the clock has to be
-- rebuilt: GetTime() counts from client start, so its value from before the
-- reload is still on the same scale, but the wall clock is what proves how long
-- ago the run began, and it is the one that would also survive a relog.
-- A nil `key` means "adopt whatever is saved", which is what the exit path
-- needs: it runs from outside the instance, where there is no key to match.
local function RestoreRun(key)
    local saved = ns.db and ns.db.activeRun
    if type(saved) ~= "table" then return nil end
    if key and saved.key ~= key then return nil end
    if type(saved.players) ~= "table" or type(saved.order) ~= "table" then return nil end

    local elapsed = time() - (saved.startWall or time())
    if elapsed < 0 or elapsed > STALE_RUN_SECONDS then
        ns.db.activeRun = nil
        return nil
    end

    saved.startTime = GetTime() - elapsed
    saved.endTime   = nil
    saved.duration  = nil
    saved.keyLevel  = saved.keyLevel or ReadKeyLevel()
    return saved
end

-- `forceNew` is passed by CHALLENGE_MODE_START: activating a keystone starts a
-- run whatever was accumulated in the same instance beforehand. Every other
-- caller is a zone-in, where an existing run for this instance must be adopted
-- rather than overwritten.
local function StartRun(forceNew)
    local key = ns.GetInstanceKey()
    if not key then
        currentRun = nil
        if ns.db then ns.db.activeRun = nil end
        return
    end

    if not forceNew then
        local restored = RestoreRun(key)
        if restored then
            currentRun = restored
            return
        end
    end

    local ok, name, instanceType, difficultyID, _, _, _, _, instanceMapID = pcall(GetInstanceInfo)
    if not ok then
        currentRun = nil
        return
    end

    currentRun = {
        key          = key,
        mapID        = instanceMapID,
        zoneName     = name,
        instanceType = instanceType,
        difficultyID = difficultyID,
        startTime    = GetTime(),
        startWall    = time(),
        players      = {},
        order        = {},
        snapshots    = 0,
        keyLevel     = ReadKeyLevel(),  -- purely decorative
    }

    -- The live run IS the saved one: no copy step, no save-on-a-timer. Every
    -- snapshot written from here on is already on disk by the time the next
    -- reload happens, because SavedVariables are flushed on /reload too.
    if ns.db then ns.db.activeRun = currentRun end
end

local function SaveToHistory(run)
    if not ns.db then return end
    ns.db.runHistory = ns.db.runHistory or {}

    local key = tostring(run.mapID or 0)
    local list = ns.db.runHistory[key]
    if not list then
        list = {}
        ns.db.runHistory[key] = list
    end

    -- Compact, plain-number record. Deliberately keyed by mapID and GUID so a
    -- later "your DPS versus your last five runs here" can read it directly.
    local entry = {
        finished = time(),
        duration = run.duration or ((run.endTime or GetTime()) - (run.startTime or GetTime())),
        keyLevel = run.keyLevel,
        zoneName = run.zoneName,
        players  = {},
    }
    for _, guid in ipairs(run.order) do
        local p = run.players[guid]
        entry.players[guid] = {
            name       = p.name,
            class      = p.class,
            dps        = p.dps,
            hps        = p.hps,
            interrupts = p.interrupts,
            deaths     = p.deaths,
            avoidable  = p.avoidable,
        }
    end

    table.insert(list, 1, entry)
    while #list > MAX_HISTORY do
        table.remove(list)
    end
end

local function FinishRun()
    if not currentRun then return end

    -- Best-effort final read. It may write nothing at all if the values come
    -- back secret here, which is exactly why the per-pull snapshots exist: the
    -- last PLAYER_REGEN_ENABLED already captured the totals.
    ns.RunRecapSnapshot()

    currentRun.endTime = GetTime()
    -- Frozen once, here. A restored run has no usable GetTime() origin, so the
    -- recap window and the public API both read this in preference to
    -- recomputing from timestamps that may have crossed a reload.
    currentRun.duration = currentRun.endTime - (currentRun.startTime or currentRun.endTime)
    lastRun = currentRun
    SaveToHistory(lastRun)
    currentRun = nil

    if ns.db then
        ns.db.activeRun = nil
        ns.db.lastRun   = lastRun   -- so /tdm recap still works after a reload
    end

    if #lastRun.order > 0 and (not ns.db or ns.db.runRecapAutoShow ~= false) then
        ns.ShowRunRecap()
    end
end

----------------------------------------------------------------------
-- Public API
--
-- The one intentional global besides the saved-variables table. TomoScore
-- (shipped in TomoMod) can consume this when both addons are installed, while
-- TomoDamageMeter never depends on anything of TomoMod's: the dependency only
-- runs in the direction that costs nothing.
----------------------------------------------------------------------

local function CopyRun(run)
    if not run then return nil end
    local out = {
        mapID    = run.mapID,
        zoneName = run.zoneName,
        keyLevel = run.keyLevel,
        duration = run.duration or ((run.endTime or GetTime()) - (run.startTime or GetTime())),
        players  = {},
    }
    for _, guid in ipairs(run.order) do
        local p = run.players[guid]
        out.players[#out.players + 1] = {
            guid       = guid,
            name       = p.name,
            class      = p.class,
            dps        = p.dps,
            hps        = p.hps,
            interrupts = p.interrupts,
            deaths     = p.deaths,
            avoidable  = p.avoidable,
        }
    end
    return out
end

function ns.GetRunSnapshot()
    -- The saved tail is the fallback: TomoScore may well ask for the run
    -- during the very load that follows a reload, before any event has had a
    -- chance to hand the in-memory copies back.
    return CopyRun(lastRun or currentRun or (ns.db and (ns.db.activeRun or ns.db.lastRun)))
end

_G.TomoDamageMeter = _G.TomoDamageMeter or {}

--- Most recent completed run, or the one in progress. Returns nil if none.
_G.TomoDamageMeter.GetRunSnapshot = function()
    return ns.GetRunSnapshot()
end

--- Stored history for a map, newest first. Returns an empty table if none.
_G.TomoDamageMeter.GetRunHistory = function(mapID)
    if not ns.db or not ns.db.runHistory then return {} end
    return ns.db.runHistory[tostring(mapID or 0)] or {}
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------

local function SortedPlayers(run)
    local list = {}
    for _, guid in ipairs(run.order) do
        list[#list + 1] = run.players[guid]
    end
    table.sort(list, function(a, b)
        local av, bv = a[sortField] or -1, b[sortField] or -1
        if av == bv then
            return (a.name or "") < (b.name or "")
        end
        return av > bv
    end)
    return list
end

local function EnsureWindow()
    if recapFrame then return recapFrame end

    local frame = CreateFrame("Frame", "TomoDMRunRecap", UIParent, "BackdropTemplate")
    frame:SetSize(WINDOW_WIDTH, HEADER_HEIGHT + COLHDR_HEIGHT + 5 * (ROW_HEIGHT + ROW_SPACING) + BORDER_SIZE)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    frame:SetBackdrop({ bgFile = ns.FLAT, edgeFile = ns.FLAT, edgeSize = BORDER_SIZE })
    frame:SetBackdropColor(ns.BG[1], ns.BG[2], ns.BG[3], ns.db and ns.db.bgAlpha or ns.BG[4])
    frame:SetBackdropBorderColor(unpack(ns.BORDER_COLOR))

    tinsert(UISpecialFrames, "TomoDMRunRecap")

    -- Header
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", BORDER_SIZE, -BORDER_SIZE)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -BORDER_SIZE, -BORDER_SIZE)
    header:SetHeight(HEADER_HEIGHT)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() frame:StartMoving() end)
    header:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    local headerBG = header:CreateTexture(nil, "BACKGROUND")
    headerBG:SetTexture(ns.FLAT); headerBG:SetVertexColor(unpack(ns.HEADER_BG))
    headerBG:SetAllPoints()

    local titleFS = header:CreateFontString(nil, "ARTWORK")
    titleFS:SetFont(ns.GetFont(), 12, "OUTLINE")
    ns.Tint(titleFS, "accent")
    titleFS:SetPoint("LEFT", header, "LEFT", TEXT_PAD, ns.GetFontNudge())
    titleFS:SetText(L["RUN_RECAP"])

    local subFS = header:CreateFontString(nil, "ARTWORK")
    subFS:SetFont(ns.GetFont(), 11, "OUTLINE")
    ns.Tint(subFS, "secondary")
    subFS:SetPoint("LEFT", titleFS, "RIGHT", 8, 0)
    subFS:SetWordWrap(false)
    frame._subFS = subFS

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

    local headerSep = frame:CreateTexture(nil, "OVERLAY")
    headerSep:SetTexture(ns.FLAT); headerSep:SetVertexColor(unpack(ns.BORDER_COLOR))
    headerSep:SetHeight(1)
    headerSep:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
    headerSep:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT")

    -- Column header. Each label is a button: clicking sorts by that metric.
    local colHeader = CreateFrame("Frame", nil, frame)
    colHeader:SetPoint("TOPLEFT", headerSep, "BOTTOMLEFT", 0, 0)
    colHeader:SetPoint("TOPRIGHT", headerSep, "BOTTOMRIGHT", 0, 0)
    colHeader:SetHeight(COLHDR_HEIGHT)
    frame._colHeader = colHeader
    frame._colButtons = {}

    for i = #METRICS, 1, -1 do
        local metric = METRICS[i]
        local btn = CreateFrame("Button", nil, colHeader)
        btn:SetHeight(COLHDR_HEIGHT)

        local fs = btn:CreateFontString(nil, "ARTWORK")
        fs:SetFont(ns.GetFont(), 10, "OUTLINE")
        fs:SetJustifyH("RIGHT")
        fs:SetWordWrap(false)
        fs:SetAllPoints()
        fs:SetText(L[metric.labelKey] or metric.labelKey)
        btn._fs = fs
        btn._field = metric.field

        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture(ns.FLAT); hl:SetVertexColor(1, 1, 1, 0.06); hl:SetAllPoints()

        btn:SetScript("OnClick", function(self)
            sortField = self._field
            ns.ShowRunRecap()
        end)

        frame._colButtons[#frame._colButtons + 1] = btn
    end

    local colSep = frame:CreateTexture(nil, "OVERLAY")
    colSep:SetTexture(ns.FLAT); colSep:SetVertexColor(unpack(ns.BORDER_COLOR))
    colSep:SetHeight(1)
    colSep:SetPoint("TOPLEFT", colHeader, "BOTTOMLEFT")
    colSep:SetPoint("TOPRIGHT", colHeader, "BOTTOMRIGHT")
    frame._colSep = colSep

    local noDataFS = frame:CreateFontString(nil, "ARTWORK")
    noDataFS:SetFont(ns.GetFont(), 11, "OUTLINE")
    ns.Tint(noDataFS, "muted")
    noDataFS:SetPoint("TOP", colSep, "BOTTOM", 0, -20)
    noDataFS:SetText(L["RUN_RECAP_NO_DATA"])
    noDataFS:Hide()
    frame._noDataFS = noDataFS

    frame:Hide()
    recapFrame = frame
    return frame
end

local function GetRow(index, parent, anchor)
    local row = rows[index]
    if not row then
        row = CreateFrame("Frame", nil, parent)
        row:SetHeight(ROW_HEIGHT)

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture(ns.FLAT)
        bg:SetAllPoints()
        row._bg = bg

        local nameFS = row:CreateFontString(nil, "ARTWORK")
        nameFS:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
        nameFS:SetJustifyH("LEFT")
        nameFS:SetWordWrap(false)
        row._nameFS = nameFS

        row._values = {}
        for i = #METRICS, 1, -1 do
            local fs = row:CreateFontString(nil, "ARTWORK")
            fs:SetFont(ns.GetFont(), ns.GetFontSize(), "OUTLINE")
            fs:SetJustifyH("RIGHT")
            fs:SetWordWrap(false)
            row._values[i] = fs
        end

        rows[index] = row
    end

    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, index == 1 and -1 or -ROW_SPACING)
    row:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, index == 1 and -1 or -ROW_SPACING)
    return row
end

-- Position the header buttons right-to-left. `_colButtons` was built in the
-- same order, so index 1 is the rightmost. The previous version advanced the
-- offset by a flat 4px instead of the column width, which stacked all five
-- labels on top of each other in the top-right corner.
local function LayoutHeaderColumns(frame)
    local w = ColumnWidth()
    local xOff = -TEXT_PAD
    for i = 1, #frame._colButtons do
        local btn = frame._colButtons[i]
        btn:ClearAllPoints()
        btn:SetWidth(w)
        btn:SetPoint("RIGHT", frame._colHeader, "RIGHT", xOff, 0)
        xOff = xOff - w - 4
    end
end

-- Lay a row's numeric columns out right-to-left, measured against the active
-- font so they cannot clip the way the breakdown columns used to.
local function LayoutRowColumns(row)
    local w = ColumnWidth()
    local xOff = -TEXT_PAD
    local last = nil
    for i = #METRICS, 1, -1 do
        local fs = row._values[i]
        fs:ClearAllPoints()
        fs:SetWidth(w)
        fs:SetPoint("RIGHT", row, "RIGHT", xOff, ns.GetFontNudge())
        xOff = xOff - w - 4
        last = fs
    end
    row._nameFS:ClearAllPoints()
    row._nameFS:SetPoint("LEFT", row, "LEFT", TEXT_PAD, ns.GetFontNudge())
    row._nameFS:SetPoint("RIGHT", last, "LEFT", -4, ns.GetFontNudge())
end

function ns.ShowRunRecap(run)
    run = run or lastRun or currentRun or (ns.db and ns.db.lastRun)
    local frame = EnsureWindow()

    frame:SetBackdropColor(ns.BG[1], ns.BG[2], ns.BG[3], ns.db and ns.db.bgAlpha or ns.BG[4])
    frame:SetAlpha(ns.db and ns.db.breakdownAlpha or 1)
    frame:SetWidth(DesiredWidth())
    LayoutHeaderColumns(frame)

    for _, row in ipairs(rows) do row:Hide() end

    if not run or #run.order == 0 then
        frame._subFS:SetText("")
        frame._noDataFS:Show()
        frame:SetHeight(HEADER_HEIGHT + COLHDR_HEIGHT + 60 + BORDER_SIZE)
        frame:Show()
        return
    end
    frame._noDataFS:Hide()

    -- Sub-title: zone, keystone level, duration.
    local parts = {}
    if run.zoneName then parts[#parts + 1] = run.zoneName end
    if run.keyLevel then parts[#parts + 1] = "+" .. run.keyLevel end
    local duration = run.duration or ((run.endTime or GetTime()) - (run.startTime or GetTime()))
    parts[#parts + 1] = ns.FormatTimer(duration)
    frame._subFS:SetText(table.concat(parts, "  -  "))

    -- Highlight the active sort column.
    for _, btn in ipairs(frame._colButtons) do
        if btn._field == sortField then
            ns.Tint(btn._fs, "accent")
        else
            ns.Tint(btn._fs, "muted")
        end
    end

    local players = SortedPlayers(run)
    local count = math.min(#players, MAX_ROWS)
    local anchor = frame._colSep

    for i = 1, count do
        local p = players[i]
        local row = GetRow(i, frame, anchor)
        LayoutRowColumns(row)

        row._bg:SetVertexColor(0, 0, 0, (i % 2 == 0) and 0.18 or 0)

        local cc = p.class and RAID_CLASS_COLORS[p.class]
        row._nameFS:SetText(p.name or "?")
        row._nameFS:SetTextColor(cc and cc.r or 1, cc and cc.g or 1, cc and cc.b or 1)

        for m = 1, #METRICS do
            local metric = METRICS[m]
            local value = p[metric.field]
            row._values[m]:SetText(value and ns.FormatNumber(value, metric.fmt) or "-")
            row._values[m]:SetTextColor(unpack(
                metric.field == sortField and ns.TEXT_PRIMARY or ns.TEXT_SECONDARY))
        end

        row:Show()
        anchor = row
    end

    frame:SetHeight(HEADER_HEIGHT + COLHDR_HEIGHT + count * (ROW_HEIGHT + ROW_SPACING) + BORDER_SIZE + 2)
    frame:Show()
end

function ns.ToggleRunRecap()
    if recapFrame and recapFrame:IsShown() then
        recapFrame:Hide()
    else
        ns.ShowRunRecap()
    end
end

----------------------------------------------------------------------
-- Events
----------------------------------------------------------------------

local runFrame = CreateFrame("Frame")
runFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
runFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
runFrame:RegisterEvent("CHALLENGE_MODE_START")
runFrame:RegisterEvent("LFG_COMPLETION_REWARD")

runFrame:SetScript("OnEvent", function(_, event)
    if ns.Blocked and ns.Blocked() then return end
    if event == "PLAYER_ENTERING_WORLD" then
        local key = ns.GetInstanceKey()

        -- Adopt anything the reload left behind before deciding what to do, so
        -- the exit path below closes the run out properly rather than dropping
        -- it on the floor.
        if not currentRun then
            currentRun = RestoreRun(key)
            if ns.db and lastRun == nil then lastRun = ns.db.lastRun end
        end

        -- Doubles as the exit path: stepping out of the instance ends whatever
        -- run was open, which is the only "dungeon finished" signal a manual
        -- (non-keystone, non-LFG) run ever produces.
        if currentRun and not key then
            FinishRun()
            return
        end
        StartRun()

    elseif event == "CHALLENGE_MODE_START" then
        StartRun(true)

    elseif event == "CHALLENGE_MODE_COMPLETED" or event == "LFG_COMPLETION_REWARD" then
        FinishRun()
    end
end)

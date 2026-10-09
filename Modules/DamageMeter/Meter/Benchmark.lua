local ADDON_NAME, TomoMod = ...
local ns = TomoMod.DM
local L = ns.L
if ns.Blocked and ns.Blocked() then return end

----------------------------------------------------------------------
-- Damage Benchmark - 2.8.3
--
-- A timed, local damage test built on Blizzard's C_DamageMeter data.
-- Important: C_DamageMeter values are read only from damage-meter/combat event
-- handlers. The temporary ticker updates the clock and finalizes from the last
-- plain-number sample; it never polls C_DamageMeter from a timer callback.
----------------------------------------------------------------------

local BENCHMARK_LOCAL = {
    enUS = {
        BENCHMARK_TITLE="Damage Benchmark", BENCHMARK_TIP="Open Damage Benchmark",
        BENCHMARK_READY="Ready for a new test.", BENCHMARK_ARMED="Waiting for combat...",
        BENCHMARK_WAIT_DATA="Waiting for native DPS data...", BENCHMARK_RUNNING="Test in progress...",
        BENCHMARK_COMPLETE="DPS captured.", BENCHMARK_CANCELLED="Test cancelled.",
        BENCHMARK_SECRET_SNAPSHOT="Test recorded. DPS visible until reload, but protected by WoW.",
        BENCHMARK_PROTECTED_SHORT="Protected",
        BENCHMARK_NO_DAMAGE="No native DPS sample available.", BENCHMARK_DURATION="Duration",
        BENCHMARK_AUTO_DUMMY_ON="Auto dummy: On", BENCHMARK_AUTO_DUMMY_OFF="Auto dummy: Off",
        BENCHMARK_START="Start", BENCHMARK_STOP="Stop", BENCHMARK_DPS="Average DPS",
        BENCHMARK_DAMAGE="Damage", BENCHMARK_TOP5="Local Top 5", BENCHMARK_CLEAR="Clear history",
        BENCHMARK_EMPTY="No benchmark recorded yet.", BENCHMARK_COL_PLAYER="Character",
        BENCHMARK_COL_SPEC="Spec", BENCHMARK_COL_ILVL="iLvl", BENCHMARK_COL_TIME="Time", BENCHMARK_COL_DATE="Date",
    },
    frFR = {
        BENCHMARK_TITLE="Test de dégâts", BENCHMARK_TIP="Ouvrir le test de dégâts",
        BENCHMARK_READY="Prêt pour un nouveau test.", BENCHMARK_ARMED="En attente du combat...",
        BENCHMARK_WAIT_DATA="En attente du DPS natif...", BENCHMARK_RUNNING="Test en cours...",
        BENCHMARK_COMPLETE="DPS capturé.", BENCHMARK_CANCELLED="Test annulé.",
        BENCHMARK_SECRET_SNAPSHOT="Test conservé. DPS visible jusqu'au reload, mais protégé par WoW.",
        BENCHMARK_PROTECTED_SHORT="Protégé",
        BENCHMARK_NO_DAMAGE="Aucune valeur DPS disponible.", BENCHMARK_DURATION="Durée",
        BENCHMARK_AUTO_DUMMY_ON="Mannequin auto : Oui", BENCHMARK_AUTO_DUMMY_OFF="Mannequin auto : Non",
        BENCHMARK_START="Démarrer", BENCHMARK_STOP="Arrêter", BENCHMARK_DPS="DPS moyen",
        BENCHMARK_DAMAGE="Dégâts", BENCHMARK_TOP5="Top 5 local", BENCHMARK_CLEAR="Effacer l'historique",
        BENCHMARK_EMPTY="Aucun test enregistré.", BENCHMARK_COL_PLAYER="Personnage",
        BENCHMARK_COL_SPEC="Spé", BENCHMARK_COL_ILVL="iLvl", BENCHMARK_COL_TIME="Durée", BENCHMARK_COL_DATE="Date",
    },
}
do
    local chosen = BENCHMARK_LOCAL[GetLocale()] or BENCHMARK_LOCAL.enUS
    for key, fallback in pairs(BENCHMARK_LOCAL.enUS) do
        if L[key] == nil then L[key] = chosen[key] or fallback end
    end
end

local HISTORY_LIMIT = 50
local DURATIONS = { 30, 60, 120 }
local TICK_INTERVAL = 0.10
local LAUNCHER_ICON = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Meter\\benchmark"

-- NPC IDs are used instead of localized names so dummy detection works on all
-- supported clients.  The list covers legacy capitals through Dragonflight /
-- The War Within plus Midnight Silvermoon damage / tanking dummies.
local TRAINING_DUMMY_IDS = {}
for _, id in ipairs({
    4952, 5652, 25225, 25297, 31144, 31146, 32541, 32542, 32543, 32545, 32546,
    32666, 32667, 44171, 44389, 44548, 44614, 44703, 44794, 44820, 44848, 44937,
    46647, 48304, 60197, 64446, 67127, 70245, 79414, 87317, 87318, 87320, 87322,
    87329, 87760, 87761, 87762, 88288, 88314, 88836, 88837, 88906, 89078, 92164,
    92165, 92166, 92168, 92169, 93828, 97668, 98581, 107104, 108420, 109066,
    109096, 111824, 113858, 113859, 113860, 113862, 113863, 113864, 113871,
    114832, 114840,
    126712, 126781, 127019, 131983, 131989, 131990, 131992, 132976, 134324,
    138048, 143119, 143509, 144073, 144077, 144081, 144085, 144086, 153285,
    153292, 172452, 173942, 174565, 174566, 174567, 174568, 175449, 175450,
    175451, 189082, 193394, 193563, 194643, 194644, 194648, 194649, 197833, 198594, 199057,
    216458, 219250, 222275, 225976, 225977, 225982, 225983, 225984, 225985,
    235830,
    -- Midnight / Silvermoon City
    243167, -- Dungeoneer's Training Dummy <Tanking>
    243205, -- Reinforced Golem <Raider's Training Dummy>
    243207, -- Training Dummy <Damage>
    243208, -- Cleave Training Dummy <Damage>
    243211, -- PvP Training Dummy <Damage>
}) do
    TRAINING_DUMMY_IDS[id] = true
end

local dummyAutoStartedThisCombat = false

local benchmark = {
    mode = "idle", -- idle, armed, waitingData, running, complete, cancelled, noDamage
    duration = 60,
    startedAt = nil,
    accumulated = 0,
    -- Native DPS is sampled from C_DamageMeter; it can be secret in combat.
    -- A secret is only passed to a permitted FontString C setter, never
    -- converted, compared, rounded, or written to SavedVariables.
    latestDps = nil,
    frozenDps = nil,
    captureUntil = nil,
    -- Keeps protected snapshots for visual display in this UI session only.
    -- Never place these values into SavedVariables (TomoModDamageMeterDB).
    visualHistory = setmetatable({}, { __mode = "k" }),
    ticker = nil,
    result = nil,
    profile = nil,
}

local frame
local launcherButtons = setmetatable({}, { __mode = "k" })

local function Safe(v)
    return v ~= nil and not issecretvalue(v)
end

local function Accent()
    local c = ns.ACCENT or { 0.88, 0.08, 0.18, 1 }
    return c[1] or 0.88, c[2] or 0.08, c[3] or 0.18
end

local function SetBackdrop(target, r, g, b, a, br, bg, bb, ba)
    target:SetBackdrop({
        bgFile = ns.FLAT or "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = ns.FLAT or "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    target:SetBackdropColor(r, g, b, a)
    target:SetBackdropBorderColor(br, bg, bb, ba)
end

local function Font(parent, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont((ns.GetFont and ns.GetFont()) or STANDARD_TEXT_FONT, size, "OUTLINE")
    fs:SetJustifyH(justify or "LEFT")
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 0.55)
    local c = color or ns.TEXT_PRIMARY or { 1, 1, 1 }
    fs:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1)
    return fs
end

local function FormatNumber(value)
    value = tonumber(value) or 0
    local abs = math.abs(value)
    if abs >= 1000000000 then
        return string.format("%.2fB", value / 1000000000)
    elseif abs >= 1000000 then
        return string.format("%.2fM", value / 1000000)
    elseif abs >= 1000 then
        return string.format("%.1fK", value / 1000)
    end
    return string.format("%.0f", value)
end

local function FormatClock(seconds)
    seconds = math.max(0, math.floor((seconds or 0) + 0.5))
    return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function EnsureDB()
    if not ns.db then return nil end
    if type(ns.db.benchmarkHistory) ~= "table" then ns.db.benchmarkHistory = {} end
    if ns.db.benchmarkAutoDummy == nil then ns.db.benchmarkAutoDummy = true end
    if ns.db.benchmarkDuration ~= 30 and ns.db.benchmarkDuration ~= 60 and ns.db.benchmarkDuration ~= 120 then
        ns.db.benchmarkDuration = 60
    end
    benchmark.duration = ns.db.benchmarkDuration
    return ns.db
end

local function PlayerProfile()
    local name, realm = UnitFullName("player")
    name = name or UnitName("player") or "Player"
    realm = realm or GetRealmName()
    local fullName = name
    if realm and realm ~= "" then fullName = name .. "-" .. realm end

    local _, classFile = UnitClass("player")
    local specID, specName
    if GetSpecialization and GetSpecializationInfo then
        local okIndex, specIndex = pcall(GetSpecialization)
        if okIndex and Safe(specIndex) and specIndex then
            local okSpec, id, sName = pcall(GetSpecializationInfo, specIndex)
            if okSpec then
                if Safe(id) then specID = id end
                if Safe(sName) then specName = sName end
            end
        end
    end

    local itemLevel
    if GetAverageItemLevel then
        local ok, overall, equipped = pcall(GetAverageItemLevel)
        if ok then
            if Safe(equipped) then
                itemLevel = equipped
            elseif Safe(overall) then
                itemLevel = overall
            end
        end
    end

    return {
        player = fullName,
        classFile = classFile,
        specID = specID,
        specName = specName or "-",
        itemLevel = itemLevel,
    }
end

-- Same source and field used by the live DPS meter, not DamageDone totals.
-- Secret DPS values may be DISPLAYED by FontString:SetFormattedText but cannot
-- be inspected in Lua or turned into persistent numbers.
local function HasNativeDps(value)
    if issecretvalue and issecretvalue(value) then return true end
    return type(value) == "number" and value >= 0
end

local function ReadPlayerDps()
    if not (C_DamageMeter and C_DamageMeter.GetCombatSessionFromType) then return nil end
    if not (Enum and Enum.DamageMeterSessionType and Enum.DamageMeterType) then return nil end
    local sessionType = Enum.DamageMeterSessionType.Current
    local meterType = Enum.DamageMeterType.Dps
    if sessionType == nil or meterType == nil then return nil end

    local ok, session = pcall(C_DamageMeter.GetCombatSessionFromType, sessionType, meterType)
    if not ok or not session or issecretvalue(session) then return nil end
    local sources = session.combatSources
    if not sources or issecretvalue(sources) then return nil end

    local playerGUID = UnitGUID("player")
    if playerGUID ~= nil and issecretvalue(playerGUID) then playerGUID = nil end
    for _, source in ipairs(sources) do
        local isSelf = source.isLocalPlayer
        local matches = Safe(isSelf) and isSelf
        if not matches and playerGUID then
            local sourceGUID = source.sourceGUID
            if Safe(sourceGUID) then matches = sourceGUID == playerGUID end
        end
        if matches then
            local value = source.amountPerSecond
            if HasNativeDps(value) then return value end
            return nil
        end
    end
    return nil
end

local function UnitNPCID(unit)
    local guid = UnitGUID and UnitGUID(unit)
    if not Safe(guid) or type(guid) ~= "string" then return nil end
    local unitType, _, _, _, _, npcID = strsplit("-", guid)
    if unitType ~= "Creature" and unitType ~= "Vehicle" then return nil end
    return tonumber(npcID)
end

function ns.IsTrainingDummyUnit(unit)
    local npcID = UnitNPCID(unit or "target")
    return npcID ~= nil and TRAINING_DUMMY_IDS[npcID] == true
end

local function CancelTicker()
    if benchmark.ticker then
        benchmark.ticker:Cancel()
        benchmark.ticker = nil
    end
end

local function IsActive()
    return benchmark.mode == "armed" or benchmark.mode == "waitingData"
        or benchmark.mode == "running" or benchmark.mode == "capturing"
end

local function UpdateLauncherButtons()
    local active = IsActive()
    local ar, ag, ab = Accent()
    for button in pairs(launcherButtons) do
        if active then
            button:SetBackdropColor(ar * 0.16, ag * 0.16, ab * 0.16, 0.98)
            button:SetBackdropBorderColor(ar, ag, ab, 0.94)
            if button._icon then button._icon:SetVertexColor(1, 1, 1) end
        else
            button:SetBackdropColor(0.025, 0.025, 0.032, 0.94)
            button:SetBackdropBorderColor(0.20, 0.20, 0.23, 0.86)
            if button._icon then
                local c = ns.TEXT_MUTED or { 0.40, 0.40, 0.43 }
                button._icon:SetVertexColor(c[1], c[2], c[3])
            end
        end
    end
end

local function TopHistory()
    local db = EnsureDB()
    local copy = {}
    if not db then return copy end
    local recentProtected = {}
    for _, entry in ipairs(db.benchmarkHistory) do
        if type(entry) == "table" then
            if type(entry.dps) == "number" then
                copy[#copy + 1] = entry
            elseif entry.protectedSnapshot and #recentProtected < 5 then
                -- Keep the newest protected attempts visible above ranked runs.
                -- Saved metadata contains no protected numeric DPS.
                recentProtected[#recentProtected + 1] = entry
            end
        end
    end
    table.sort(copy, function(a, b)
        if a.dps == b.dps then return (a.damage or 0) > (b.damage or 0) end
        return a.dps > b.dps
    end)
    for i = #recentProtected, 1, -1 do
        table.insert(copy, 1, recentProtected[i])
    end
    while #copy > 5 do table.remove(copy) end
    return copy
end

local function SaveResult(result)
    local db = EnsureDB()
    if not db then return end
    table.insert(db.benchmarkHistory, 1, result)
    while #db.benchmarkHistory > HISTORY_LIMIT do
        table.remove(db.benchmarkHistory)
    end
end

local function StatusText()
    if benchmark.mode == "armed" then return L["BENCHMARK_ARMED"] end
    if benchmark.mode == "waitingData" then return L["BENCHMARK_WAIT_DATA"] end
    if benchmark.mode == "running" or benchmark.mode == "capturing" then
        return L["BENCHMARK_RUNNING"]
    end
    if benchmark.mode == "secretSnapshot" then return L["BENCHMARK_SECRET_SNAPSHOT"] end
    if benchmark.mode == "complete" then return L["BENCHMARK_COMPLETE"] end
    if benchmark.mode == "cancelled" then return L["BENCHMARK_CANCELLED"] end
    if benchmark.mode == "noDamage" then return L["BENCHMARK_NO_DAMAGE"] end
    return L["BENCHMARK_READY"]
end

local function SetDuration(seconds)
    if IsActive() then return end
    if seconds ~= 30 and seconds ~= 60 and seconds ~= 120 then return end
    local db = EnsureDB()
    benchmark.duration = seconds
    benchmark.result = nil
    if benchmark.mode == "complete" or benchmark.mode == "secretSnapshot"
        or benchmark.mode == "cancelled" or benchmark.mode == "noDamage" then
        benchmark.mode = "idle"
        benchmark.frozenDps = nil
    end
    if db then db.benchmarkDuration = seconds end
end

local function UpdateUI()
    if not frame then
        UpdateLauncherButtons()
        return
    end

    frame._status:SetText(StatusText() or "")

    for seconds, button in pairs(frame._durationButtons) do
        local selected = seconds == benchmark.duration
        local ar, ag, ab = Accent()
        if selected then
            button:SetBackdropColor(ar * 0.18, ag * 0.18, ab * 0.18, 0.98)
            button:SetBackdropBorderColor(ar, ag, ab, 0.92)
            button._text:SetTextColor(1, 1, 1)
        else
            button:SetBackdropColor(0.025, 0.025, 0.032, 0.92)
            button:SetBackdropBorderColor(0.20, 0.20, 0.23, 0.82)
            local c = ns.TEXT_SECONDARY or { 0.55, 0.55, 0.55 }
            button._text:SetTextColor(c[1], c[2], c[3])
        end
    end

    frame._startButton._text:SetText(IsActive() and (L["BENCHMARK_STOP"] or "Stop") or (L["BENCHMARK_START"] or "Start"))
    if frame._autoDummyButton then
        local enabled = EnsureDB() and ns.db.benchmarkAutoDummy ~= false
        frame._autoDummyButton._text:SetText(enabled
            and (L["BENCHMARK_AUTO_DUMMY_ON"] or "Auto dummy: On")
            or (L["BENCHMARK_AUTO_DUMMY_OFF"] or "Auto dummy: Off"))
        local ar, ag, ab = Accent()
        if enabled then
            frame._autoDummyButton:SetBackdropBorderColor(ar, ag, ab, 0.82)
        else
            frame._autoDummyButton:SetBackdropBorderColor(0.20, 0.20, 0.23, 0.82)
        end
    end

    local elapsed = 0
    local shownDps
    if (benchmark.mode == "running" or benchmark.mode == "capturing") and benchmark.startedAt then
        elapsed = math.min(benchmark.duration, math.max(0, GetTime() - benchmark.startedAt))
        shownDps = benchmark.latestDps
    elseif benchmark.result then
        elapsed = benchmark.result.duration or benchmark.duration
        shownDps = benchmark.frozenDps
    end

    frame._timer:SetText(FormatClock(elapsed) .. " / " .. FormatClock(benchmark.duration))
    -- A direct C-side widget setter is compatible with a secret amountPerSecond.
    -- Do not call FormatNumber, tostring, string.format or do Lua math on it.
    if HasNativeDps(shownDps) then
        frame._dps:SetFormattedText("%.0f", shownDps)
    else
        frame._dps:SetText("-")
    end
    frame._damage:Hide()

    local top = TopHistory()
    frame._empty:SetShown(#top == 0)
    for i, row in ipairs(frame._rows) do
        local entry = top[i]
        row:SetShown(entry ~= nil)
        if entry then
            row.rank:SetText(entry.protectedSnapshot and "*" or i)
            if type(entry.dps) == "number" then
                row.dps:SetText(FormatNumber(entry.dps))
            elseif entry.protectedSnapshot then
                local liveValue = benchmark.visualHistory[entry]
                if HasNativeDps(liveValue) then
                    -- Display-only: C-side setter accepts WoW protected values.
                    row.dps:SetFormattedText("%.0f", liveValue)
                else
                    -- After /reload the value cannot legally be reconstructed.
                    row.dps:SetText(L["BENCHMARK_PROTECTED_SHORT"] or "Protected")
                end
            else
                row.dps:SetText("-")
            end
            row.time:SetText((entry.duration or 0) .. "s")
            row.player:SetText(entry.player or "-")
            row.spec:SetText(entry.specName or "-")
            row.ilvl:SetText(entry.itemLevel and string.format("%.1f", entry.itemLevel) or "-")
            row.date:SetText(entry.date or "-")

            local cc = entry.classFile and RAID_CLASS_COLORS[entry.classFile]
            if cc then row.player:SetTextColor(cc.r, cc.g, cc.b) else row.player:SetTextColor(1, 1, 1) end
        end
    end

    UpdateLauncherButtons()
end

local function FinishBenchmark(nativeDps)
    if benchmark.mode ~= "running" and benchmark.mode ~= "capturing" then return end
    CancelTicker()

    local valid = HasNativeDps(nativeDps)
    local plainDps
    if valid and not issecretvalue(nativeDps) then
        plainDps = nativeDps -- ordinary Lua number; can be saved to history
    end
    local profile = benchmark.profile or PlayerProfile()

    if valid then benchmark.frozenDps = nativeDps else benchmark.frozenDps = nil end
    benchmark.result = {
        dps = plainDps,
        duration = benchmark.duration,
        player = profile.player,
        classFile = profile.classFile,
        specID = profile.specID,
        specName = profile.specName,
        itemLevel = profile.itemLevel,
        timestamp = time(),
        date = date("%Y-%m-%d %H:%M"),
    }

    if not valid then
        benchmark.mode = "noDamage"
    elseif plainDps == nil then
        -- Persist the benchmark ATTEMPT, not the protected number itself.
        -- The exact frozen DPS remains visible in-session via visualHistory.
        benchmark.result.protectedSnapshot = true
        benchmark.visualHistory[benchmark.result] = nativeDps
        SaveResult(benchmark.result)
        benchmark.mode = "secretSnapshot"
    else
        if plainDps > 0 then SaveResult(benchmark.result) end
        benchmark.mode = "complete"
    end
    benchmark.startedAt = nil
    benchmark.latestDps = nil
    benchmark.captureUntil = nil
    UpdateUI()
end

local function TickBenchmark()
    if (benchmark.mode ~= "running" and benchmark.mode ~= "capturing")
        or not benchmark.startedAt then return end
    local now = GetTime()
    if benchmark.mode == "running" and now - benchmark.startedAt >= benchmark.duration then
        -- The next native DamageMeter update at/after the threshold is best.
        benchmark.mode = "capturing"
        benchmark.captureUntil = now + 0.6
    end
    if benchmark.mode == "capturing" and now >= benchmark.captureUntil then
        -- No fresh event: freeze the latest sample instead of showing fake 0.
        FinishBenchmark(benchmark.latestDps)
        return
    end
    UpdateUI()
end

local function BeginBenchmarkClock()
    CancelTicker()
    benchmark.mode = "running"
    benchmark.startedAt = GetTime()
    benchmark.latestDps = nil
    benchmark.frozenDps = nil
    benchmark.captureUntil = nil
    benchmark.profile = PlayerProfile()
    benchmark.result = nil
    benchmark.ticker = C_Timer.NewTicker(TICK_INTERVAL, TickBenchmark)
    UpdateUI()
end

local function CancelBenchmark()
    CancelTicker()
    benchmark.mode = "cancelled"
    benchmark.startedAt = nil
    benchmark.latestDps = nil
    benchmark.frozenDps = nil
    benchmark.captureUntil = nil
    UpdateUI()
end

local function StartBenchmark()
    if IsActive() then
        CancelBenchmark()
        return
    end

    EnsureDB()
    benchmark.latestDps = nil
    benchmark.frozenDps = nil
    benchmark.result = nil
    benchmark.profile = nil
    benchmark.captureUntil = nil

    if UnitAffectingCombat and UnitAffectingCombat("player") then
        BeginBenchmarkClock()
    else
        benchmark.mode = "armed"
        UpdateUI()
    end
end

local function ObserveDps()
    -- Called synchronously from native meter events, never by the ticker.
    local nativeDps = ReadPlayerDps()
    if not HasNativeDps(nativeDps) then return end
    local now = GetTime()

    if benchmark.mode == "armed" or benchmark.mode == "waitingData" then
        if UnitAffectingCombat and UnitAffectingCombat("player") then
            BeginBenchmarkClock()
        else
            return
        end
    end
    if benchmark.mode ~= "running" and benchmark.mode ~= "capturing" then return end

    benchmark.latestDps = nativeDps
    if now - benchmark.startedAt >= benchmark.duration then
        -- Prefer the FIRST C_DamageMeter DPS event at/after the chosen time.
        FinishBenchmark(nativeDps)
    else
        UpdateUI()
    end
end

local function TryAutoStartOnDummy()
    local db = EnsureDB()
    if not db or db.benchmarkAutoDummy == false or dummyAutoStartedThisCombat or IsActive() then return false end
    if not ns.IsTrainingDummyUnit or not ns.IsTrainingDummyUnit("target") then return false end

    dummyAutoStartedThisCombat = true
    if ns.OpenBenchmark then ns.OpenBenchmark() end
    benchmark.result = nil
    benchmark.profile = nil
    BeginBenchmarkClock()
    return true
end

local function MakeButton(parent, width, height, label)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height)
    SetBackdrop(button, 0.025, 0.025, 0.032, 0.92, 0.20, 0.20, 0.23, 0.82)
    local text = Font(button, 10, ns.TEXT_SECONDARY, "CENTER")
    text:SetPoint("CENTER")
    text:SetText(label or "")
    button._text = text
    button:SetScript("OnEnter", function(self)
        local ar, ag, ab = Accent()
        self:SetBackdropColor(ar * 0.14, ag * 0.14, ab * 0.14, 0.98)
        self:SetBackdropBorderColor(ar, ag, ab, 0.86)
        self._text:SetTextColor(1, 1, 1)
    end)
    button:SetScript("OnLeave", function()
        UpdateUI()
    end)
    return button
end

local function SavePosition(self)
    if not EnsureDB() then return end
    local point, _, relPoint, x, y = self:GetPoint(1)
    ns.db.benchmarkPosition = { point = point, relPoint = relPoint, x = x, y = y }
end

local function RestorePosition(self)
    local db = EnsureDB()
    local p = db and db.benchmarkPosition
    self:ClearAllPoints()
    if type(p) == "table" and p.point and p.relPoint and type(p.x) == "number" and type(p.y) == "number" then
        self:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    else
        self:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    end
end

local function EnsureFrame()
    if frame then return frame end

    frame = CreateFrame("Frame", "TomoDMBenchmark", UIParent, "BackdropTemplate")
    frame:SetSize(620, 425)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    SetBackdrop(frame, 0.005, 0.005, 0.008, 0.96, 0.28, 0.28, 0.31, 0.92)
    RestorePosition(frame)
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePosition(self) end)
    UISpecialFrames = UISpecialFrames or {}
    table.insert(UISpecialFrames, "TomoDMBenchmark")

    local accent = frame:CreateTexture(nil, "OVERLAY")
    frame._accent = accent
    accent:SetTexture(ns.FLAT or "Interface\\BUTTONS\\WHITE8X8")
    accent:SetPoint("TOPLEFT", 1, -1)
    accent:SetPoint("TOPRIGHT", -1, -1)
    accent:SetHeight(3)
    local ar, ag, ab = Accent()
    accent:SetVertexColor(ar, ag, ab, 1)

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 1, -4)
    header:SetPoint("TOPRIGHT", -1, -4)
    header:SetHeight(38)
    local headerBG = header:CreateTexture(nil, "BACKGROUND")
    headerBG:SetTexture(ns.FLAT or "Interface\\BUTTONS\\WHITE8X8")
    headerBG:SetAllPoints()
    local h = ns.HEADER_BG or { 0.055, 0.055, 0.065, 1 }
    headerBG:SetVertexColor(h[1], h[2], h[3], 0.98)

    local icon = header:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(LAUNCHER_ICON)
    icon:SetSize(25, 25)
    icon:SetPoint("LEFT", 9, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = Font(header, 15, ns.TEXT_PRIMARY)
    title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    title:SetText(L["BENCHMARK_TITLE"] or "Damage Benchmark")

    local close = CreateFrame("Button", nil, header)
    close:SetSize(26, 26)
    close:SetPoint("RIGHT", -6, 0)
    local closeIcon = close:CreateTexture(nil, "ARTWORK")
    closeIcon:SetTexture(ns.TEX_CLOSE or "Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeIcon:SetSize(12, 12)
    closeIcon:SetPoint("CENTER")
    close:SetScript("OnClick", function() frame:Hide() end)

    local status = Font(frame, 11, ns.TEXT_SECONDARY)
    status:SetPoint("TOPLEFT", 18, -54)
    status:SetPoint("TOPRIGHT", -18, -54)
    status:SetJustifyH("CENTER")
    frame._status = status

    local durationLabel = Font(frame, 10, ns.TEXT_LABEL)
    durationLabel:SetPoint("TOPLEFT", 22, -82)
    durationLabel:SetText(L["BENCHMARK_DURATION"] or "Duration")

    frame._durationButtons = {}
    local previous
    for _, seconds in ipairs(DURATIONS) do
        local duration = seconds
        local button = MakeButton(frame, 54, 24, duration .. "s")
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", 6, 0)
        else
            button:SetPoint("LEFT", durationLabel, "RIGHT", 12, 0)
        end
        button:SetScript("OnClick", function()
            SetDuration(duration)
            UpdateUI()
        end)
        frame._durationButtons[duration] = button
        previous = button
    end

    local autoDummy = MakeButton(frame, 126, 24, L["BENCHMARK_AUTO_DUMMY_ON"] or "Auto dummy: On")
    autoDummy:SetPoint("LEFT", previous, "RIGHT", 8, 0)
    autoDummy:SetScript("OnClick", function()
        local db = EnsureDB()
        if db then db.benchmarkAutoDummy = not (db.benchmarkAutoDummy ~= false) end
        UpdateUI()
    end)
    frame._autoDummyButton = autoDummy

    local start = MakeButton(frame, 112, 28, L["BENCHMARK_START"] or "Start")
    start:SetPoint("TOPRIGHT", -22, -75)
    start:SetScript("OnClick", StartBenchmark)
    frame._startButton = start

    local timer = Font(frame, 20, ns.TEXT_PRIMARY, "CENTER")
    timer:SetPoint("TOP", 0, -118)
    timer:SetText("00:00 / 01:00")
    frame._timer = timer

    local dpsLabel = Font(frame, 9, ns.TEXT_MUTED, "CENTER")
    dpsLabel:SetPoint("TOP", timer, "BOTTOM", 0, -8)
    dpsLabel:SetText(L["BENCHMARK_DPS"] or "Average DPS")

    local dps = Font(frame, 27, ns.TEXT_PRIMARY, "CENTER")
    dps:SetPoint("TOP", dpsLabel, "BOTTOM", 0, -2)
    dps:SetText("0")
    frame._dps = dps

    local damage = Font(frame, 11, ns.TEXT_SECONDARY, "CENTER")
    damage:SetPoint("TOP", dps, "BOTTOM", 0, -5)
    damage:SetText((L["BENCHMARK_DAMAGE"] or "Damage") .. ": 0")
    frame._damage = damage

    local sep = frame:CreateTexture(nil, "ARTWORK")
    sep:SetTexture(ns.FLAT or "Interface\\BUTTONS\\WHITE8X8")
    sep:SetPoint("TOPLEFT", 18, -228)
    sep:SetPoint("TOPRIGHT", -18, -228)
    sep:SetHeight(1)
    sep:SetVertexColor(0.22, 0.22, 0.25, 0.82)

    local topTitle = Font(frame, 12, ns.TEXT_PRIMARY)
    topTitle:SetPoint("TOPLEFT", 22, -244)
    topTitle:SetText(L["BENCHMARK_TOP5"] or "Local Top 5")

    local clear = MakeButton(frame, 105, 22, L["BENCHMARK_CLEAR"] or "Clear history")
    clear:SetPoint("TOPRIGHT", -22, -238)
    clear:SetScript("OnClick", function()
        if EnsureDB() then ns.db.benchmarkHistory = {} end
        UpdateUI()
    end)

    local columns = {
        { key = "rank",   text = "#",                                  x = 24,  w = 22,  align = "CENTER" },
        { key = "dps",    text = "DPS",                                x = 50,  w = 110, align = "RIGHT" },
        { key = "time",   text = L["BENCHMARK_COL_TIME"] or "Time",   x = 174, w = 50,  align = "CENTER" },
        { key = "player", text = L["BENCHMARK_COL_PLAYER"] or "Player",x = 231, w = 129, align = "LEFT" },
        { key = "spec",   text = L["BENCHMARK_COL_SPEC"] or "Spec",   x = 367, w = 76,  align = "LEFT" },
        { key = "ilvl",   text = L["BENCHMARK_COL_ILVL"] or "iLvl",   x = 452, w = 50,  align = "RIGHT" },
        { key = "date",   text = L["BENCHMARK_COL_DATE"] or "Date",   x = 515, w = 83,  align = "RIGHT" },
    }

    for _, col in ipairs(columns) do
        local fs = Font(frame, 8, ns.TEXT_MUTED, col.align)
        fs:SetPoint("TOPLEFT", col.x, -271)
        fs:SetWidth(col.w)
        fs:SetText(col.text)
    end

    frame._rows = {}
    for i = 1, 5 do
        local row = CreateFrame("Frame", nil, frame)
        row:SetPoint("TOPLEFT", 18, -288 - ((i - 1) * 24))
        row:SetPoint("TOPRIGHT", -18, -288 - ((i - 1) * 24))
        row:SetHeight(22)
        if i % 2 == 0 then
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetTexture(ns.FLAT or "Interface\\BUTTONS\\WHITE8X8")
            bg:SetAllPoints()
            bg:SetVertexColor(1, 1, 1, 0.025)
        end
        for _, col in ipairs(columns) do
            local fs = Font(row, 9, ns.TEXT_SECONDARY, col.align)
            fs:SetPoint("LEFT", row, "LEFT", col.x - 18, 0)
            fs:SetWidth(col.w)
            row[col.key] = fs
        end
        frame._rows[i] = row
    end

    local empty = Font(frame, 10, ns.TEXT_MUTED, "CENTER")
    empty:SetPoint("TOP", 0, -320)
    empty:SetText(L["BENCHMARK_EMPTY"] or "No benchmark recorded yet.")
    frame._empty = empty

    frame:Hide()
    UpdateUI()
    return frame
end

function ns.OpenBenchmark()
    EnsureFrame():Show()
    UpdateUI()
end

function ns.ToggleBenchmark()
    local f = EnsureFrame()
    f:SetShown(not f:IsShown())
    if f:IsShown() then UpdateUI() end
end

function ns.StartBenchmark()
    EnsureFrame():Show()
    StartBenchmark()
end

local function AttachLauncher(win)
    if not win or not win.frame or win._benchmarkLauncher then return end

    -- Second-row utility button.  Its center is aligned exactly under the
    -- right-most 20 px action button (Reset), while staying clear of the logo
    -- and the main header controls.  History mirrors this one column to the left.
    local button = CreateFrame("Button", nil, win.frame, "BackdropTemplate")
    button:SetSize(20, 20)
    if win.BenchmarkLauncherAnchor then
        button:SetAllPoints(win.BenchmarkLauncherAnchor)
    else
        button:SetPoint("TOPRIGHT", win.frame, "TOPRIGHT", -7, -30)
    end
    button:SetFrameLevel(win.frame:GetFrameLevel() + 12)
    SetBackdrop(button, 0.025, 0.025, 0.032, 0.94, 0.20, 0.20, 0.23, 0.86)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(LAUNCHER_ICON)
    icon:SetSize(11, 11)
    icon:SetPoint("CENTER")
    local muted = ns.TEXT_MUTED or { 0.40, 0.40, 0.43 }
    icon:SetVertexColor(muted[1], muted[2], muted[3])
    button._icon = icon

    button:SetScript("OnClick", function()
        if ns.ToggleBenchmark then ns.ToggleBenchmark() end
    end)
    button:SetScript("OnEnter", function(self)
        local ar, ag, ab = Accent()
        self:SetBackdropColor(ar * 0.18, ag * 0.18, ab * 0.18, 0.98)
        self:SetBackdropBorderColor(ar, ag, ab, 0.96)
        self._icon:SetVertexColor(1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["BENCHMARK_TIP"] or "Open Damage Benchmark", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
        UpdateLauncherButtons()
    end)

    win._benchmarkLauncher = button
    launcherButtons[button] = true
    UpdateLauncherButtons()
end

-- Wrap the final V3 window factory. ADDON_LOADED fires only after every addon
-- file has loaded, so this wrapper is installed before Database creates windows.
if not ns._embeddedNativeUtilityButtons and ns.CreateMeterWindow and not ns._benchmarkWrappedCreateMeterWindow then
    ns._benchmarkWrappedCreateMeterWindow = true
    local CreateMeterWindow = ns.CreateMeterWindow
    ns.CreateMeterWindow = function(cfg)
        local win = CreateMeterWindow(cfg)
        AttachLauncher(win)
        return win
    end
end

if ns.OnAccentChanged then
    ns.OnAccentChanged(function()
        if frame and frame._accent then
            local ar, ag, ab = Accent()
            frame._accent:SetVertexColor(ar, ag, ab, 1)
        end
        UpdateUI()
    end)
end

----------------------------------------------------------------------
-- Event-side data sampling
----------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
local function Register(event)
    if ns.SafeRegisterEvent then
        ns.SafeRegisterEvent(eventFrame, event)
    else
        pcall(eventFrame.RegisterEvent, eventFrame, event)
    end
end

Register("ADDON_LOADED")
Register("DAMAGE_METER_COMBAT_SESSION_UPDATED")
Register("DAMAGE_METER_CURRENT_SESSION_UPDATED")
Register("DAMAGE_METER_RESET")
Register("PLAYER_REGEN_DISABLED")
Register("PLAYER_REGEN_ENABLED")
Register("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then EnsureDB(); UpdateUI() end
        return
    end

    if event == "PLAYER_LOGOUT" then
        CancelTicker()
        return
    end

    if event == "DAMAGE_METER_RESET" then
        -- A reset changes the denominator of native average DPS; do not
        -- silently mix two sessions inside a single timed benchmark.
        if IsActive() then CancelBenchmark() end
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        if TryAutoStartOnDummy() then return end
        if benchmark.mode == "armed" then BeginBenchmarkClock() end
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        -- A shorter combat is not a 30/60/120-second result.
        if benchmark.startedAt and IsActive()
            and GetTime() - benchmark.startedAt < benchmark.duration then
            CancelBenchmark()
        else
            ObserveDps()
        end
        dummyAutoStartedThisCombat = false
        return
    end

    -- DAMAGE_METER_*: capture C_DamageMeter's native average DPS in-handler.
    if UnitAffectingCombat and UnitAffectingCombat("player") then TryAutoStartOnDummy() end
    ObserveDps()
end)

----------------------------------------------------------------------
-- Slash command integration
----------------------------------------------------------------------

if SlashCmdList and SlashCmdList["TDM"] and not ns._benchmarkSlashWrapped then
    ns._benchmarkSlashWrapped = true
    local previous = SlashCmdList["TDM"]
    SlashCmdList["TDM"] = function(msg)
        local raw = tostring(msg or "")
        local command, arg = raw:match("^%s*(%S*)%s*(.-)%s*$")
        command = string.lower(command or "")

        if command == "benchmark" or command == "bench" then
            local seconds = tonumber(arg)
            if seconds == 30 or seconds == 60 or seconds == 120 then SetDuration(seconds) end
            ns.OpenBenchmark()
            return
        end

        previous(msg)
        if command == "help" then
            print((L["ADDON_PREFIX"] or "TDM: ") .. (L["CMD_HELP_BENCHMARK"] or "  /tdm benchmark - open Damage Benchmark"))
        end
    end
end

----------------------------------------------------------------------
-- Small read-only public API for future TomoSuite integrations.
----------------------------------------------------------------------

_G.TomoMod_DamageMeterBridge = _G.TomoMod_DamageMeterBridge or {}
_G.TomoMod_DamageMeterBridge.GetBenchmarkHistory = function()
    local db = EnsureDB()
    if not db then return {} end
    local out = {}
    for i, entry in ipairs(db.benchmarkHistory) do
        out[i] = CopyTable(entry)
    end
    return out
end

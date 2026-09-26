local ADDON_NAME, TomoMod = ...
local ns = TomoMod.DM
local L = ns.L
if ns.Blocked and ns.Blocked() then return end

----------------------------------------------------------------------
-- Fight History
-- Embedded TomoMod port of TomoDamageMeter's persistent fight history.
-- Reads C_DamageMeter only from event handlers and stores plain values.
----------------------------------------------------------------------

local HISTORY_LIMIT = 80
local LEFT_ROWS = 11
local PLAYER_ROWS = 14
local HISTORY_ICON = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Meter\\history"

local STRINGS = {
    enUS = {
        FIGHT_HISTORY="Fight History", FIGHT_HISTORY_TIP="Open persistent fight history",
        FIGHT_HISTORY_ALL="All fights", FIGHT_HISTORY_BOSSES="Bosses only",
        FIGHT_HISTORY_CLEAR="Clear history", FIGHT_HISTORY_EMPTY="No saved dungeon or raid fights yet.",
        FIGHT_HISTORY_DAMAGE="Damage", FIGHT_HISTORY_HEALING="Healing",
        FIGHT_HISTORY_BOSS="Boss", FIGHT_HISTORY_TRASH="Trash",
        FIGHT_HISTORY_PLAYER="Player", FIGHT_HISTORY_INTERRUPTS="Int", FIGHT_HISTORY_DEATHS="Deaths",
        FIGHT_HISTORY_PREV="Previous", FIGHT_HISTORY_NEXT="Next",
        FIGHT_HISTORY_KILL="Kill", FIGHT_HISTORY_WIPE="Wipe",
        HISTORY_GUI="History", HISTORY_GUI_DESC="Persistent dungeon and raid fight history.",
    },
    frFR = {
        FIGHT_HISTORY="Historique des combats", FIGHT_HISTORY_TIP="Ouvrir l'historique persistant des combats",
        FIGHT_HISTORY_ALL="Tous les combats", FIGHT_HISTORY_BOSSES="Boss uniquement",
        FIGHT_HISTORY_CLEAR="Effacer l'historique", FIGHT_HISTORY_EMPTY="Aucun combat de donjon ou raid enregistré.",
        FIGHT_HISTORY_DAMAGE="Dégâts", FIGHT_HISTORY_HEALING="Soins",
        FIGHT_HISTORY_BOSS="Boss", FIGHT_HISTORY_TRASH="Trash",
        FIGHT_HISTORY_PLAYER="Joueur", FIGHT_HISTORY_INTERRUPTS="Int", FIGHT_HISTORY_DEATHS="Morts",
        FIGHT_HISTORY_PREV="Précédent", FIGHT_HISTORY_NEXT="Suivant",
        FIGHT_HISTORY_KILL="Tué", FIGHT_HISTORY_WIPE="Échec",
        HISTORY_GUI="Historique", HISTORY_GUI_DESC="Historique persistant des combats de donjon et de raid.",
    },
}
do
    local chosen = STRINGS[GetLocale()] or STRINGS.enUS
    for key, fallback in pairs(STRINGS.enUS) do
        if L[key] == nil then L[key] = chosen[key] or fallback end
    end
end

local frame
local selectedFight
local page = 1
local playerPage = 1
local bossesOnly = false
local mode = "damage"
local activeEncounter
local UpdateUI

local function Secret(v)
    return v ~= nil and issecretvalue and issecretvalue(v)
end

local function SafeNumber(v)
    if type(v) == "number" and not Secret(v) then return v end
    return 0
end

local function SafeText(v, fallback)
    if type(v) == "string" and not Secret(v) and v ~= "" then return v end
    return fallback or "?"
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

local function Font(parent, size, role, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont((ns.GetFont and ns.GetFont()) or STANDARD_TEXT_FONT, size, "OUTLINE")
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(false)
    local c = role == "muted" and ns.TEXT_MUTED
        or role == "secondary" and ns.TEXT_SECONDARY
        or role == "label" and ns.TEXT_LABEL
        or ns.TEXT_PRIMARY
        or { 1, 1, 1 }
    fs:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1)
    return fs
end

local function MakeButton(parent, width, label)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, 24)
    SetBackdrop(button, 0.025, 0.025, 0.032, 0.92, 0.20, 0.20, 0.23, 0.82)
    local text = Font(button, 9, "secondary", "CENTER")
    text:SetPoint("CENTER")
    text:SetText(label or "")
    button._text = text
    button:SetScript("OnEnter", function(self)
        local r, g, b = Accent()
        self:SetBackdropColor(r * 0.14, g * 0.14, b * 0.14, 0.98)
        self:SetBackdropBorderColor(r, g, b, 0.86)
        self._text:SetTextColor(1, 1, 1)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.025, 0.025, 0.032, 0.92)
        self:SetBackdropBorderColor(0.20, 0.20, 0.23, 0.82)
        local c = ns.TEXT_SECONDARY or { .55, .55, .55 }
        self._text:SetTextColor(c[1], c[2], c[3])
    end)
    return button
end

local function FormatNumber(v)
    v = SafeNumber(v)
    local a = math.abs(v)
    if a >= 1000000000 then return string.format("%.2fB", v / 1000000000) end
    if a >= 1000000 then return string.format("%.2fM", v / 1000000) end
    if a >= 1000 then return string.format("%.1fK", v / 1000) end
    return tostring(math.floor(v + 0.5))
end

local function FormatClock(seconds)
    seconds = math.max(0, math.floor(SafeNumber(seconds) + 0.5))
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function EnsureDB()
    if not ns.db then return nil end
    if type(ns.db.fightHistory) ~= "table" then ns.db.fightHistory = {} end
    return ns.db
end

local function TrackedInstance()
    local ok, name, instanceType, difficultyID, _, _, _, instanceID = pcall(GetInstanceInfo)
    if not ok or Secret(instanceType) then return nil end
    if instanceType ~= "party" and instanceType ~= "raid" and instanceType ~= "scenario" then return nil end
    return {
        instanceName = SafeText(name, "?"),
        instanceType = instanceType,
        difficultyID = SafeNumber(difficultyID),
        instanceID = SafeNumber(instanceID),
    }
end

local function LatestSessionInfo()
    if not C_DamageMeter or not C_DamageMeter.GetAvailableCombatSessions then return nil, nil end
    local ok, sessions = pcall(C_DamageMeter.GetAvailableCombatSessions)
    if not ok or not sessions or Secret(sessions) or #sessions == 0 then return nil, nil end
    local info = sessions[#sessions]
    if not info or Secret(info) then return nil, nil end
    local id = info.sessionID
    if Secret(id) or type(id) ~= "number" then id = nil end
    return id, SafeText(info.name, nil)
end

local function ReadSession(sessionID, meterType)
    if meterType == nil or not C_DamageMeter then return nil end
    if sessionID ~= nil and C_DamageMeter.GetCombatSessionFromID then
        local ok, session = pcall(C_DamageMeter.GetCombatSessionFromID, sessionID, meterType)
        if ok and session and not Secret(session) then return session end
        return nil
    end
    if not C_DamageMeter.GetCombatSessionFromType then return nil end
    local st = Enum and Enum.DamageMeterSessionType and Enum.DamageMeterSessionType.Current
    if st == nil then return nil end
    local ok, session = pcall(C_DamageMeter.GetCombatSessionFromType, st, meterType)
    if ok and session and not Secret(session) then return session end
    return nil
end

local function PlayerKey(source)
    local guid = source.sourceGUID
    if Secret(guid) then guid = nil end
    local name = SafeText(source.name, nil)
    if not name then return nil, nil, nil end
    return guid or name, guid, name
end

local function EnsurePlayer(players, source)
    local key, guid, name = PlayerKey(source)
    if not key then return nil end
    local p = players[key]
    if not p then
        p = {
            guid = guid,
            name = name,
            classFile = not Secret(source.classFilename) and source.classFilename or nil,
            specIconID = not Secret(source.specIconID) and source.specIconID or nil,
            damage = 0, healing = 0, damageTaken = 0, avoidable = 0,
            absorbs = 0, interrupts = 0, dispels = 0, deaths = 0,
        }
        players[key] = p
    end
    return p
end

local function ReadMetric(players, sessionID, meterType, field)
    local session = ReadSession(sessionID, meterType)
    if not session then return 0 end
    local sources = session.combatSources
    if not sources or Secret(sources) then return SafeNumber(session.durationSeconds) end
    for _, source in ipairs(sources) do
        local total = source.totalAmount
        if type(total) == "number" and not Secret(total) and total >= 0 then
            local p = EnsurePlayer(players, source)
            if p then p[field] = (p[field] or 0) + total end
        end
    end
    return SafeNumber(session.durationSeconds)
end

local function ReadTopEnemy(sessionID)
    local D = Enum and Enum.DamageMeterType
    local mt = D and D.EnemyDamageTaken
    local session = ReadSession(sessionID, mt)
    if not session then return nil end
    local sources = session.combatSources
    if not sources or Secret(sources) or #sources == 0 then return nil end
    return SafeText(sources[1].name, nil)
end

local function CaptureSnapshot(sessionID, sessionName)
    local instance = TrackedInstance()
    if not instance then return nil end
    local D = Enum and Enum.DamageMeterType
    if not D then return nil end

    local players = {}
    local duration = 0
    local function add(mt, field)
        if mt ~= nil then duration = math.max(duration, ReadMetric(players, sessionID, mt, field)) end
    end
    add(D.DamageDone or D.Dps, "damage")
    add(D.HealingDone or D.Hps, "healing")
    add(D.DamageTaken, "damageTaken")
    add(D.AvoidableDamageTaken, "avoidable")
    add(D.Absorbs, "absorbs")
    add(D.Interrupts, "interrupts")
    add(D.Dispels, "dispels")
    add(D.Deaths, "deaths")

    local list, meaningful = {}, false
    for _, p in pairs(players) do
        if (p.damage or 0) > 0 or (p.healing or 0) > 0 then meaningful = true end
        list[#list + 1] = p
    end
    if not meaningful then return nil end

    instance.players = list
    instance.duration = duration
    instance.sessionID = sessionID
    instance.enemy = sessionName or ReadTopEnemy(sessionID)
    instance.finished = time()
    return instance
end

local function CaptureCurrent()
    local id, name = LatestSessionInfo()
    return CaptureSnapshot(id, name)
end

local function CaptureLiveCurrent()
    return CaptureSnapshot(nil, nil)
end

local function MergeParts(parts)
    if not parts or #parts == 0 then return nil end
    local last = parts[#parts]
    local merged = {
        instanceName = last.instanceName, instanceType = last.instanceType,
        difficultyID = last.difficultyID, instanceID = last.instanceID,
        enemy = last.enemy, finished = last.finished, duration = 0, players = {},
    }
    if #parts == 1 then merged.sessionID = parts[1].sessionID end
    local byKey = {}
    local fields = { "damage", "healing", "damageTaken", "avoidable", "absorbs", "interrupts", "dispels", "deaths" }
    for _, part in ipairs(parts) do
        merged.duration = merged.duration + SafeNumber(part.duration)
        for _, source in ipairs(part.players or {}) do
            local key = source.guid or source.name
            local target = byKey[key]
            if not target then
                target = {
                    guid=source.guid, name=source.name, classFile=source.classFile, specIconID=source.specIconID,
                    damage=0, healing=0, damageTaken=0, avoidable=0, absorbs=0, interrupts=0, dispels=0, deaths=0,
                }
                byKey[key] = target
                merged.players[#merged.players + 1] = target
            end
            for _, field in ipairs(fields) do
                target[field] = (target[field] or 0) + SafeNumber(source[field])
            end
        end
    end
    return merged
end

local function SaveFight(snapshot, encounter)
    local db = EnsureDB()
    if not db or not snapshot then return end

    snapshot.isBoss = encounter ~= nil
    snapshot.encounterID = encounter and encounter.id or nil
    snapshot.name = encounter and encounter.name or (snapshot.enemy or L["FIGHT_HISTORY_TRASH"] or "Trash")
    snapshot.success = encounter and encounter.success or nil
    snapshot.groupSize = encounter and encounter.groupSize or nil
    if encounter and encounter.difficultyID and encounter.difficultyID > 0 then
        snapshot.difficultyID = encounter.difficultyID
    end

    if snapshot.sessionID ~= nil then
        for i, saved in ipairs(db.fightHistory) do
            if type(saved) == "table" and saved.sessionID == snapshot.sessionID then
                if snapshot.isBoss and not saved.isBoss then
                    db.fightHistory[i] = snapshot
                    if selectedFight == saved then selectedFight = snapshot end
                    if frame and frame:IsShown() then UpdateUI() end
                end
                return
            end
        end
    end

    table.insert(db.fightHistory, 1, snapshot)
    while #db.fightHistory > HISTORY_LIMIT do table.remove(db.fightHistory) end
    if frame and frame:IsShown() then
        selectedFight = snapshot
        UpdateUI()
    end
end

local function AppendEncounterPart(encounter, snapshot)
    if not encounter or not snapshot then return false end
    if #encounter.parts == 0 and snapshot.sessionID ~= nil
        and encounter.baselineSessionID ~= nil and snapshot.sessionID == encounter.baselineSessionID then
        return false
    end
    local last = encounter.parts[#encounter.parts]
    if snapshot.sessionID ~= nil and last and last.sessionID == snapshot.sessionID then
        encounter.parts[#encounter.parts] = snapshot
    else
        encounter.parts[#encounter.parts + 1] = snapshot
    end
    return true
end

local function FinalizeEncounter(encounter)
    if not encounter or encounter.saved then return end
    local merged = MergeParts(encounter.parts)
    if not merged then merged = encounter.fallbackSnapshot end
    if not merged then return end
    encounter.saved = true
    SaveFight(merged, encounter)
end

local function FilteredHistory()
    local db = EnsureDB()
    local out = {}
    if not db then return out end
    for _, fight in ipairs(db.fightHistory) do
        if type(fight) == "table" and (not bossesOnly or fight.isBoss) then out[#out + 1] = fight end
    end
    return out
end

local function SortedPlayers(fight)
    local out = {}
    if not fight then return out end
    for _, p in ipairs(fight.players or {}) do out[#out + 1] = p end
    local field = mode == "healing" and "healing" or "damage"
    table.sort(out, function(a, b)
        local av, bv = SafeNumber(a[field]), SafeNumber(b[field])
        if av == bv then return SafeText(a.name, "") < SafeText(b.name, "") end
        return av > bv
    end)
    return out
end

UpdateUI = function()
    if not frame then return end
    local history = FilteredHistory()
    local pages = math.max(1, math.ceil(#history / LEFT_ROWS))
    page = math.max(1, math.min(page, pages))
    frame._page:SetText(string.format("%d/%d", page, pages))
    frame._empty:SetShown(#history == 0)

    local first = (page - 1) * LEFT_ROWS + 1
    for i, row in ipairs(frame._fightRows) do
        local entry = history[first + i - 1]
        row._fight = entry
        row:SetShown(entry ~= nil)
        if entry then
            row.kind:SetText(entry.isBoss and (L["FIGHT_HISTORY_BOSS"] or "Boss") or (L["FIGHT_HISTORY_TRASH"] or "Trash"))
            row.name:SetText(SafeText(entry.name, "?"))
            row.meta:SetText(string.format("%s  ·  %s", date("%d/%m %H:%M", entry.finished or time()), FormatClock(entry.duration)))
            local r, g, b = Accent()
            if entry == selectedFight then
                row:SetBackdropColor(r * .16, g * .16, b * .16, .96)
                row:SetBackdropBorderColor(r, g, b, .92)
            else
                row:SetBackdropColor(.018, .018, .024, .86)
                row:SetBackdropBorderColor(.16, .16, .19, .76)
            end
        end
    end

    local fight = selectedFight
    if fight then
        local present = false
        for _, e in ipairs(history) do if e == fight then present = true break end end
        if not present then fight = history[1]; selectedFight = fight end
    else
        fight = history[1]
        selectedFight = fight
    end

    frame._detailEmpty:SetShown(fight == nil)
    frame._detailTitle:SetText(fight and SafeText(fight.name, "?") or "")
    if fight then
        local result = ""
        if fight.isBoss and fight.success ~= nil then
            result = " · " .. (fight.success and (L["FIGHT_HISTORY_KILL"] or "Kill") or (L["FIGHT_HISTORY_WIPE"] or "Wipe"))
        end
        frame._detailMeta:SetText(string.format("%s · %s · %s%s",
            SafeText(fight.instanceName, "?"), date("%d/%m/%y %H:%M", fight.finished or time()),
            FormatClock(fight.duration), result))
    else
        frame._detailMeta:SetText("")
    end

    frame._damageButton._text:SetTextColor(mode == "damage" and 1 or .6, mode == "damage" and 1 or .6, mode == "damage" and 1 or .62)
    frame._healingButton._text:SetTextColor(mode == "healing" and 1 or .6, mode == "healing" and 1 or .6, mode == "healing" and 1 or .62)
    frame._rateHeader:SetText(mode == "healing" and "HPS" or "DPS")
    frame._totalHeader:SetText(mode == "healing" and (L["FIGHT_HISTORY_HEALING"] or "Healing") or (L["FIGHT_HISTORY_DAMAGE"] or "Damage"))

    local players = SortedPlayers(fight)
    local playerPages = math.max(1, math.ceil(#players / PLAYER_ROWS))
    playerPage = math.max(1, math.min(playerPage, playerPages))
    frame._playerPage:SetText(string.format("%d/%d", playerPage, playerPages))
    local playerFirst = (playerPage - 1) * PLAYER_ROWS + 1
    local field = mode == "healing" and "healing" or "damage"
    for i, row in ipairs(frame._playerRows) do
        local rank = playerFirst + i - 1
        local p = players[rank]
        row:SetShown(p ~= nil)
        if p then
            local total = SafeNumber(p[field])
            local rate = (fight and fight.duration or 0) > 0 and total / fight.duration or 0
            row.rank:SetText(rank)
            row.name:SetText(ns.StripRealm and ns.StripRealm(p.name) or p.name)
            row.rate:SetText(FormatNumber(rate))
            row.total:SetText(FormatNumber(total))
            row.interrupts:SetText(tostring(math.floor(SafeNumber(p.interrupts) + .5)))
            row.deaths:SetText(tostring(math.floor(SafeNumber(p.deaths) + .5)))
            local cc = p.classFile and RAID_CLASS_COLORS[p.classFile]
            if cc then row.name:SetTextColor(cc.r, cc.g, cc.b) else row.name:SetTextColor(1,1,1) end
        end
    end
end

local function EnsureFrame()
    if frame then return frame end
    frame = CreateFrame("Frame", "TomoModDMFightHistory", UIParent, "BackdropTemplate")
    frame:SetSize(900, 565)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    SetBackdrop(frame, .005, .005, .008, .97, .28, .28, .31, .92)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    UISpecialFrames = UISpecialFrames or {}
    table.insert(UISpecialFrames, "TomoModDMFightHistory")

    local r, g, b = Accent()
    local accent = frame:CreateTexture(nil, "OVERLAY")
    accent:SetTexture(ns.FLAT or "Interface\\BUTTONS\\WHITE8X8")
    accent:SetPoint("TOPLEFT", 1, -1); accent:SetPoint("TOPRIGHT", -1, -1); accent:SetHeight(3)
    accent:SetVertexColor(r, g, b, 1)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(HISTORY_ICON); icon:SetSize(24, 24); icon:SetPoint("TOPLEFT", 12, -8)
    local title = Font(frame, 15, "primary")
    title:SetPoint("LEFT", icon, "RIGHT", 8, 0); title:SetText(L["FIGHT_HISTORY"] or "Fight History")
    local close = MakeButton(frame, 28, "X")
    close:SetPoint("TOPRIGHT", -10, -8); close:SetScript("OnClick", function() frame:Hide() end)

    local all = MakeButton(frame, 92, L["FIGHT_HISTORY_ALL"] or "All fights")
    all:SetPoint("TOPLEFT", 16, -45)
    all:SetScript("OnClick", function() bossesOnly=false; page=1; playerPage=1; UpdateUI() end)
    local bosses = MakeButton(frame, 98, L["FIGHT_HISTORY_BOSSES"] or "Bosses only")
    bosses:SetPoint("LEFT", all, "RIGHT", 6, 0)
    bosses:SetScript("OnClick", function() bossesOnly=true; page=1; playerPage=1; UpdateUI() end)
    local clear = MakeButton(frame, 104, L["FIGHT_HISTORY_CLEAR"] or "Clear history")
    clear:SetPoint("TOPRIGHT", -16, -45)
    clear:SetScript("OnClick", function()
        local db=EnsureDB(); if db then db.fightHistory={} end
        selectedFight=nil; page=1; playerPage=1; UpdateUI()
    end)

    local left = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    left:SetPoint("TOPLEFT", 16, -78); left:SetSize(300, 438)
    SetBackdrop(left, .012,.012,.018,.90,.15,.15,.18,.78)
    frame._fightRows = {}
    for i=1,LEFT_ROWS do
        local row=CreateFrame("Button",nil,left,"BackdropTemplate")
        row:SetPoint("TOPLEFT",6,-6-((i-1)*36)); row:SetSize(288,33)
        SetBackdrop(row,.018,.018,.024,.86,.16,.16,.19,.76)
        row.kind=Font(row,7,"muted"); row.kind:SetPoint("TOPLEFT",7,-5); row.kind:SetWidth(52)
        row.name=Font(row,10,"primary"); row.name:SetPoint("TOPLEFT",61,-4); row.name:SetPoint("RIGHT",-7,0)
        row.meta=Font(row,8,"muted"); row.meta:SetPoint("BOTTOMLEFT",61,4); row.meta:SetPoint("RIGHT",-7,0)
        row:SetScript("OnClick",function(self) selectedFight=self._fight; playerPage=1; UpdateUI() end)
        frame._fightRows[i]=row
    end
    frame._empty=Font(left,10,"muted","CENTER"); frame._empty:SetPoint("CENTER"); frame._empty:SetWidth(260)
    frame._empty:SetText(L["FIGHT_HISTORY_EMPTY"] or "No saved fights yet.")

    local prev=MakeButton(frame,80,L["FIGHT_HISTORY_PREV"] or "Previous")
    prev:SetPoint("BOTTOMLEFT",16,10); prev:SetScript("OnClick",function() page=math.max(1,page-1); UpdateUI() end)
    frame._page=Font(frame,9,"secondary","CENTER"); frame._page:SetPoint("BOTTOMLEFT",112,18); frame._page:SetWidth(100)
    local nextb=MakeButton(frame,80,L["FIGHT_HISTORY_NEXT"] or "Next")
    nextb:SetPoint("BOTTOMLEFT",226,10); nextb:SetScript("OnClick",function() page=page+1; UpdateUI() end)

    local detail=CreateFrame("Frame",nil,frame,"BackdropTemplate")
    detail:SetPoint("TOPLEFT",328,-78); detail:SetPoint("BOTTOMRIGHT",-16,49)
    SetBackdrop(detail,.012,.012,.018,.90,.15,.15,.18,.78)
    frame._detailTitle=Font(detail,14,"primary"); frame._detailTitle:SetPoint("TOPLEFT",12,-10); frame._detailTitle:SetPoint("RIGHT",-12,0)
    frame._detailMeta=Font(detail,8,"muted"); frame._detailMeta:SetPoint("TOPLEFT",12,-31); frame._detailMeta:SetPoint("RIGHT",-12,0)
    frame._damageButton=MakeButton(detail,86,L["FIGHT_HISTORY_DAMAGE"] or "Damage")
    frame._damageButton:SetPoint("TOPLEFT",12,-52); frame._damageButton:SetScript("OnClick",function() mode="damage"; playerPage=1; UpdateUI() end)
    frame._healingButton=MakeButton(detail,86,L["FIGHT_HISTORY_HEALING"] or "Healing")
    frame._healingButton:SetPoint("LEFT",frame._damageButton,"RIGHT",6,0); frame._healingButton:SetScript("OnClick",function() mode="healing"; playerPage=1; UpdateUI() end)
    local pprev=MakeButton(detail,26,"<"); pprev:SetPoint("LEFT",frame._healingButton,"RIGHT",16,0)
    pprev:SetScript("OnClick",function() playerPage=math.max(1,playerPage-1); UpdateUI() end)
    frame._playerPage=Font(detail,8,"muted","CENTER"); frame._playerPage:SetPoint("LEFT",pprev,"RIGHT",4,0); frame._playerPage:SetWidth(56)
    local pnext=MakeButton(detail,26,">"); pnext:SetPoint("LEFT",frame._playerPage,"RIGHT",4,0)
    pnext:SetScript("OnClick",function() playerPage=playerPage+1; UpdateUI() end)

    local headers={
        {key="rank",text="#",x=12,w=24,align="CENTER"},
        {key="name",text=L["FIGHT_HISTORY_PLAYER"] or "Player",x=42,w=180,align="LEFT"},
        {key="rate",text="DPS",x=232,w=76,align="RIGHT"},
        {key="total",text=L["FIGHT_HISTORY_DAMAGE"] or "Damage",x=316,w=92,align="RIGHT"},
        {key="interrupts",text=L["FIGHT_HISTORY_INTERRUPTS"] or "Int",x=418,w=44,align="RIGHT"},
        {key="deaths",text=L["FIGHT_HISTORY_DEATHS"] or "Deaths",x=470,w=55,align="RIGHT"},
    }
    for _,h in ipairs(headers) do
        local fs=Font(detail,8,"muted",h.align); fs:SetPoint("TOPLEFT",h.x,-88); fs:SetWidth(h.w); fs:SetText(h.text)
        if h.key=="rate" then frame._rateHeader=fs elseif h.key=="total" then frame._totalHeader=fs end
    end
    frame._playerRows={}
    for i=1,PLAYER_ROWS do
        local row=CreateFrame("Frame",nil,detail)
        row:SetPoint("TOPLEFT",8,-106-((i-1)*23)); row:SetPoint("TOPRIGHT",-8,-106-((i-1)*23)); row:SetHeight(21)
        if i%2==0 then local bg=row:CreateTexture(nil,"BACKGROUND"); bg:SetTexture(ns.FLAT); bg:SetAllPoints(); bg:SetVertexColor(1,1,1,.025) end
        for _,h in ipairs(headers) do
            local fs=Font(row,9,"secondary",h.align); fs:SetPoint("LEFT",h.x-8,0); fs:SetWidth(h.w); row[h.key]=fs
        end
        frame._playerRows[i]=row
    end
    frame._detailEmpty=Font(detail,11,"muted","CENTER"); frame._detailEmpty:SetPoint("CENTER"); frame._detailEmpty:SetWidth(420)
    frame._detailEmpty:SetText(L["FIGHT_HISTORY_EMPTY"] or "No saved fights yet.")
    frame:Hide()
    UpdateUI()
    return frame
end

function ns.OpenFightHistory()
    EnsureDB()
    local history=FilteredHistory()
    if not selectedFight then selectedFight=history[1] end
    EnsureFrame():Show()
    UpdateUI()
end

function ns.ToggleFightHistory()
    local f=EnsureFrame()
    if f:IsShown() then f:Hide() else ns.OpenFightHistory() end
end

----------------------------------------------------------------------
-- Capture events
----------------------------------------------------------------------

local eventFrame=CreateFrame("Frame")
local function Register(event)
    if ns.SafeRegisterEvent then ns.SafeRegisterEvent(eventFrame,event)
    else pcall(eventFrame.RegisterEvent,eventFrame,event) end
end

Register("ADDON_LOADED")
Register("ENCOUNTER_START")
Register("ENCOUNTER_END")
Register("PLAYER_REGEN_ENABLED")
Register("DAMAGE_METER_CURRENT_SESSION_UPDATED")
Register("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent",function(_,event,...)
    if event=="ADDON_LOADED" then
        local addon=...
        if addon==ADDON_NAME then EnsureDB() end
        return
    end
    if event=="PLAYER_LOGOUT" then return end

    if event=="ENCOUNTER_START" then
        if activeEncounter and activeEncounter.ended then FinalizeEncounter(activeEncounter) end
        local id,name,difficultyID,groupSize=...
        local baseline=LatestSessionInfo()
        activeEncounter={
            id=not Secret(id) and id or nil, name=SafeText(name,L["FIGHT_HISTORY_BOSS"] or "Boss"),
            difficultyID=SafeNumber(difficultyID), groupSize=SafeNumber(groupSize),
            success=nil, ended=false, sawRegen=false, saved=false,
            baselineSessionID=baseline, parts={},
        }
        return
    end

    if event=="ENCOUNTER_END" then
        local id,_,difficultyID,groupSize,success=...
        if activeEncounter and (activeEncounter.id==nil or Secret(id) or activeEncounter.id==id) then
            activeEncounter.difficultyID=SafeNumber(difficultyID)>0 and SafeNumber(difficultyID) or activeEncounter.difficultyID
            activeEncounter.groupSize=SafeNumber(groupSize)>0 and SafeNumber(groupSize) or activeEncounter.groupSize
            activeEncounter.success=not Secret(success) and success==1 or false
            activeEncounter.ended=true
            activeEncounter.fallbackSnapshot=CaptureLiveCurrent() or activeEncounter.fallbackSnapshot
            AppendEncounterPart(activeEncounter,CaptureCurrent())
            if activeEncounter.sawRegen and (#activeEncounter.parts>0 or activeEncounter.fallbackSnapshot) then
                FinalizeEncounter(activeEncounter); activeEncounter=nil
            end
        end
        return
    end

    if event=="PLAYER_REGEN_ENABLED" then
        local snapshot=CaptureCurrent()
        if activeEncounter then
            activeEncounter.sawRegen=true
            activeEncounter.fallbackSnapshot=CaptureLiveCurrent() or activeEncounter.fallbackSnapshot
            AppendEncounterPart(activeEncounter,snapshot)
            if activeEncounter.ended then FinalizeEncounter(activeEncounter); activeEncounter=nil end
        elseif snapshot then
            SaveFight(snapshot,nil)
        end
        if frame and frame:IsShown() then UpdateUI() end
        return
    end

    if event=="DAMAGE_METER_CURRENT_SESSION_UPDATED" and activeEncounter and activeEncounter.ended then
        activeEncounter.fallbackSnapshot=CaptureLiveCurrent() or activeEncounter.fallbackSnapshot
        AppendEncounterPart(activeEncounter,CaptureCurrent())
        if #activeEncounter.parts>0 or activeEncounter.fallbackSnapshot then
            FinalizeEncounter(activeEncounter); activeEncounter=nil
            if frame and frame:IsShown() then UpdateUI() end
        end
    end
end)

_G.TomoMod_DamageMeterBridge=_G.TomoMod_DamageMeterBridge or {}
_G.TomoMod_DamageMeterBridge.GetFightHistory=function()
    local db=EnsureDB()
    if not db then return {} end
    local out={}
    for i,fight in ipairs(db.fightHistory) do out[i]=CopyTable(fight) end
    return out
end

-- =====================================================================
-- TomoMod_MythicPlus / RunAnalysis.lua
-- Post-run Mythic+ analysis V1 inspired by Hindsight's analysis workflow.
-- This is an original TomoMod implementation using TomoScore, RunHistory and
-- TomoDamageMeter data; no Hindsight source code is embedded here.
-- =====================================================================

local MP = TomoMod_MythicPlus
if not MP then return end

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local WHITE8    = "Interface\\Buttons\\WHITE8x8"

local W, H = 980, 638
local PAD = 18

local C = {
    bg      = { 0.035, 0.043, 0.055, 0.985 },
    panel   = { 0.055, 0.065, 0.082, 0.97 },
    panel2  = { 0.070, 0.082, 0.102, 0.92 },
    border  = { 0.16, 0.18, 0.22, 1 },
    accent  = { 0.18, 0.85, 0.52, 1 },
    text    = { 0.94, 0.96, 0.95, 1 },
    dim     = { 0.50, 0.54, 0.58, 1 },
    green   = { 0.55, 0.90, 0.20, 1 },
    yellow  = { 0.95, 0.76, 0.14, 1 },
    red     = { 0.90, 0.26, 0.24, 1 },
}

local STRINGS = {
    enUS = {
        title = "Run Analysis",
        subtitle = "Mythic+ post-run analysis · V1",
        summary = "Run summary",
        performance = "Group performance",
        splits = "Splits & progression",
        status = "Status",
        timed = "Timed",
        depleted = "Depleted",
        duration = "Duration",
        deaths = "Deaths",
        score_gain = "Score gain",
        key_level = "Keystone",
        player = "Player",
        dps = "DPS",
        hps = "HPS",
        interrupts = "Interrupts",
        avoidable = "Avoidable",
        forces = "Enemy forces 100%",
        no_data = "No completed Mythic+ run is available.",
        no_meter = "Detailed combat data is not available for this run.",
        no_splits = "No boss/forces splits were recorded for this run.",
        unknown = "Unknown",
    },
    frFR = {
        title = "Analyse du run",
        subtitle = "Analyse post-run Mythic+ · V1",
        summary = "Résumé du run",
        performance = "Performance du groupe",
        splits = "Splits et progression",
        status = "Statut",
        timed = "Terminée à temps",
        depleted = "Hors délai",
        duration = "Durée",
        deaths = "Morts",
        score_gain = "Gain de score",
        key_level = "Clé",
        player = "Joueur",
        dps = "DPS",
        hps = "HPS",
        interrupts = "Interruptions",
        avoidable = "Évitable",
        forces = "Forces ennemies 100 %",
        no_data = "Aucune clé Mythic+ terminée n'est disponible.",
        no_meter = "Les données de combat détaillées ne sont pas disponibles pour ce run.",
        no_splits = "Aucun split de boss/forces n'a été enregistré pour ce run.",
        unknown = "Inconnu",
    },
    deDE = {
        title = "Run-Analyse",
        subtitle = "Mythisch+ Nachanalyse · V1",
        summary = "Run-Zusammenfassung",
        performance = "Gruppenleistung",
        splits = "Splits & Fortschritt",
        status = "Status",
        timed = "In Zeit",
        depleted = "Nicht in Zeit",
        duration = "Dauer",
        deaths = "Tode",
        score_gain = "Wertungsgewinn",
        key_level = "Schlüssel",
        player = "Spieler",
        dps = "DPS",
        hps = "HPS",
        interrupts = "Unterbrechungen",
        avoidable = "Vermeidbar",
        forces = "Gegnerkräfte 100 %",
        no_data = "Kein abgeschlossener Mythisch+-Run verfügbar.",
        no_meter = "Für diesen Run sind keine detaillierten Kampfdaten verfügbar.",
        no_splits = "Für diesen Run wurden keine Boss-/Kräfte-Splits gespeichert.",
        unknown = "Unbekannt",
    },
    esES = {
        title = "Análisis del run",
        subtitle = "Análisis post-run de Mítico+ · V1",
        summary = "Resumen del run",
        performance = "Rendimiento del grupo",
        splits = "Splits y progreso",
        status = "Estado",
        timed = "En tiempo",
        depleted = "Fuera de tiempo",
        duration = "Duración",
        deaths = "Muertes",
        score_gain = "Ganancia de puntuación",
        key_level = "Piedra",
        player = "Jugador",
        dps = "DPS",
        hps = "HPS",
        interrupts = "Interrupciones",
        avoidable = "Evitable",
        forces = "Fuerzas enemigas 100 %",
        no_data = "No hay ningún run de Mítico+ completado disponible.",
        no_meter = "No hay datos de combate detallados para este run.",
        no_splits = "No se registraron splits de jefes/fuerzas para este run.",
        unknown = "Desconocido",
    },
    itIT = {
        title = "Analisi run",
        subtitle = "Analisi post-run Mitica+ · V1",
        summary = "Riepilogo run",
        performance = "Prestazioni del gruppo",
        splits = "Split e progressione",
        status = "Stato",
        timed = "In tempo",
        depleted = "Fuori tempo",
        duration = "Durata",
        deaths = "Morti",
        score_gain = "Guadagno punteggio",
        key_level = "Chiave",
        player = "Giocatore",
        dps = "DPS",
        hps = "HPS",
        interrupts = "Interruzioni",
        avoidable = "Evitabile",
        forces = "Forze nemiche 100 %",
        no_data = "Nessuna run Mitica+ completata disponibile.",
        no_meter = "I dati di combattimento dettagliati non sono disponibili per questa run.",
        no_splits = "Nessuno split boss/forze registrato per questa run.",
        unknown = "Sconosciuto",
    },
    ptBR = {
        title = "Análise da run",
        subtitle = "Análise pós-run Mítico+ · V1",
        summary = "Resumo da run",
        performance = "Desempenho do grupo",
        splits = "Splits e progresso",
        status = "Status",
        timed = "No tempo",
        depleted = "Fora do tempo",
        duration = "Duração",
        deaths = "Mortes",
        score_gain = "Ganho de pontuação",
        key_level = "Chave",
        player = "Jogador",
        dps = "DPS",
        hps = "HPS",
        interrupts = "Interrupções",
        avoidable = "Evitável",
        forces = "Forças inimigas 100 %",
        no_data = "Nenhuma run Mítico+ concluída está disponível.",
        no_meter = "Os dados detalhados de combate não estão disponíveis para esta run.",
        no_splits = "Nenhum split de chefe/forças foi registrado para esta run.",
        unknown = "Desconhecido",
    },
}

local function T(key)
    local locale = GetLocale and GetLocale() or "enUS"
    local set = STRINGS[locale] or STRINGS.enUS
    return set[key] or STRINGS.enUS[key] or key
end

local function Backdrop(frame, bg, border)
    frame:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    frame:SetBackdropColor(unpack(bg or C.panel))
    frame:SetBackdropBorderColor(unpack(border or C.border))
end

local function Text(parent, value, size, bold)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(bold and FONT_BOLD or FONT, size or 11, "")
    fs:SetTextColor(unpack(C.text))
    fs:SetText(value or "")
    return fs
end

local function Card(parent, x, y, w, h, title)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetPoint("TOPLEFT", x, y)
    f:SetSize(w, h)
    Backdrop(f, C.panel, C.border)
    if title then
        local t = Text(f, title, 11, true)
        t:SetPoint("TOPLEFT", 12, -10)
        t:SetTextColor(unpack(C.accent))
    end
    return f
end

local function Divider(parent, y)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", 10, y)
    line:SetPoint("TOPRIGHT", -10, y)
    line:SetHeight(1)
    line:SetColorTexture(C.border[1], C.border[2], C.border[3], 0.85)
    return line
end

local function Number(v)
    return type(v) == "number" and v or nil
end

local function FormatTime(seconds)
    seconds = Number(seconds)
    if not seconds or seconds < 0 then return "—" end
    seconds = math.floor(seconds + 0.5)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%d:%02d", m, s)
end

local function FormatNumber(value)
    value = Number(value)
    if not value then return "—" end
    local abs = math.abs(value)
    if abs >= 1000000000 then return string.format("%.2fB", value / 1000000000) end
    if abs >= 1000000 then return string.format("%.1fM", value / 1000000) end
    if abs >= 1000 then return string.format("%.1fK", value / 1000) end
    return tostring(math.floor(value + 0.5))
end

local function ShortName(name)
    if type(name) ~= "string" then return nil end
    return name:match("^[^-]+") or name
end

local function NameKey(name)
    name = ShortName(name)
    return name and string.lower(name) or nil
end

local function FindHistoryRun(runData)
    local rh = MP.RunHistory
    if not (rh and rh.GetRuns) then return nil end
    local runs = rh:GetRuns()
    if type(runs) ~= "table" then return nil end

    local meta = type(runData._tmRunAnalysis) == "table" and runData._tmRunAnalysis or nil
    local wantedID = meta and meta.historyID
    if wantedID then
        for _, run in ipairs(runs) do
            if type(run) == "table" and run.id == wantedID then return run end
        end
    end

    local mapID = meta and Number(meta.mapID) or nil
    local level = Number(runData.keyLevel)
    local duration = Number(runData.duration)
    local finished = meta and Number(meta.completedAt) or nil
    local best, bestRank

    for i = 1, math.min(#runs, 20) do
        local run = runs[i]
        if type(run) == "table" then
            local mapOK = not mapID or not Number(run.mapID) or mapID == Number(run.mapID)
            local levelOK = not level or level <= 0 or not Number(run.level) or level == Number(run.level)
            if mapOK and levelOK then
                local rank = 0
                if duration and Number(run.durationMS) then
                    rank = rank + math.abs(run.durationMS / 1000 - duration)
                else
                    rank = rank + 20
                end
                if finished and Number(run.finishedAt) then
                    rank = rank + math.min(math.abs(run.finishedAt - finished) / 10, 20)
                end
                if not bestRank or rank < bestRank then
                    best, bestRank = run, rank
                end
            end
        end
    end

    if best and bestRank and bestRank <= 12 then return best end
    return nil
end

local function MeterSnapshot(runData)
    local meta = type(runData._tmRunAnalysis) == "table" and runData._tmRunAnalysis or nil
    if meta and type(meta.meter) == "table" then return meta.meter end

    -- Only borrow the live DamageMeter snapshot for a just-finished run. For
    -- an old saved TomoScore run this could otherwise belong to another key.
    if meta and Number(meta.completedAt) and math.abs(time() - meta.completedAt) <= 300 then
        local dm = _G.TomoDamageMeter
        if dm and dm.GetRunSnapshot then
            local ok, snapshot = pcall(dm.GetRunSnapshot)
            if ok and type(snapshot) == "table" then return snapshot end
        end
    end
    return nil
end

local function BuildPlayers(runData, meter)
    local result, used = {}, {}
    local meterByName = {}

    if meter and type(meter.players) == "table" then
        for _, player in ipairs(meter.players) do
            local key = NameKey(player and player.name)
            if key then meterByName[key] = player end
        end
    end

    for _, base in ipairs(type(runData.players) == "table" and runData.players or {}) do
        local key = NameKey(base.name or base.fullName)
        local metric = key and meterByName[key] or nil
        if key then used[key] = true end
        result[#result + 1] = {
            name = base.name or ShortName(base.fullName) or T("unknown"),
            class = base.class or (metric and metric.class),
            role = base.role,
            specIcon = base.specIcon,
            dps = metric and metric.dps or nil,
            hps = metric and metric.hps or nil,
            interrupts = metric and metric.interrupts or nil,
            deaths = metric and metric.deaths or nil,
            avoidable = metric and metric.avoidable or nil,
        }
    end

    if meter and type(meter.players) == "table" then
        for _, metric in ipairs(meter.players) do
            local key = NameKey(metric and metric.name)
            if key and not used[key] then
                result[#result + 1] = {
                    name = ShortName(metric.name) or T("unknown"),
                    class = metric.class,
                    dps = metric.dps,
                    hps = metric.hps,
                    interrupts = metric.interrupts,
                    deaths = metric.deaths,
                    avoidable = metric.avoidable,
                }
            end
        end
    end

    return result
end

local function ClassColor(class)
    local cc = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if cc then return cc.r, cc.g, cc.b end
    return C.text[1], C.text[2], C.text[3]
end

local function SumPlayerDeaths(players)
    local total, found = 0, false
    for _, player in ipairs(players or {}) do
        if Number(player.deaths) then
            total = total + player.deaths
            found = true
        end
    end
    return found and total or nil
end

local function EnsureFrame()
    if MP.RunAnalysisFrame then return MP.RunAnalysisFrame end

    local f = CreateFrame("Frame", "TomoModMythicPlusRunAnalysis", UIParent, "BackdropTemplate")
    MP.RunAnalysisFrame = f
    f:SetSize(W, H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(140)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    Backdrop(f, C.bg, C.border)
    f:Hide()

    if TomoMod_Utils and TomoMod_Utils.CloseOnEscape then
        TomoMod_Utils.CloseOnEscape(f)
    end

    local accent = f:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT")
    accent:SetPoint("BOTTOMLEFT")
    accent:SetWidth(3)
    accent:SetColorTexture(unpack(C.accent))

    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 3, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(56)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    local hbg = header:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints()
    hbg:SetColorTexture(C.panel[1], C.panel[2], C.panel[3], 0.96)

    local title = Text(header, T("title"), 18, true)
    title:SetPoint("TOPLEFT", 16, -10)
    f._title = title

    local subtitle = Text(header, T("subtitle"), 9, false)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    subtitle:SetTextColor(unpack(C.dim))
    f._subtitle = subtitle

    local dungeon = Text(header, "", 12, true)
    dungeon:SetPoint("RIGHT", header, "RIGHT", -42, 0)
    dungeon:SetWidth(400)
    dungeon:SetJustifyH("RIGHT")
    dungeon:SetTextColor(unpack(C.accent))
    f._dungeon = dungeon

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButtonNoScripts")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetSize(22, 22)
    close:SetScript("OnClick", function() f:Hide() end)

    local summary = Card(f, PAD, -72, W - PAD * 2, 110, T("summary"))
    f._summary = summary
    f._summaryStats = {}
    local statW = (W - PAD * 2 - 24) / 5
    local statKeys = { "key_level", "status", "duration", "deaths", "score_gain" }
    for i, key in ipairs(statKeys) do
        local x = 12 + (i - 1) * statW
        local host = CreateFrame("Frame", nil, summary)
        host:SetPoint("TOPLEFT", x, -34)
        host:SetSize(statW - 4, 64)
        if i > 1 then
            local sep = host:CreateTexture(nil, "ARTWORK")
            sep:SetPoint("LEFT", -4, 0)
            sep:SetSize(1, 44)
            sep:SetColorTexture(C.border[1], C.border[2], C.border[3], 0.8)
        end
        local value = Text(host, "—", 18, true)
        value:SetPoint("TOP", 0, -2)
        local label = Text(host, T(key), 8, false)
        label:SetPoint("TOP", value, "BOTTOM", 0, -5)
        label:SetTextColor(unpack(C.dim))
        f._summaryStats[key] = value
    end

    local performance = Card(f, PAD, -194, W - PAD * 2, 250, T("performance"))
    f._performance = performance
    f._perfNote = Text(performance, "", 8, false)
    f._perfNote:SetPoint("TOPRIGHT", -12, -11)
    f._perfNote:SetTextColor(unpack(C.dim))

    local columns = {
        { key = "player",     x = 14,  w = 300, justify = "LEFT" },
        { key = "dps",        x = 324, w = 105, justify = "RIGHT" },
        { key = "hps",        x = 444, w = 105, justify = "RIGHT" },
        { key = "interrupts", x = 565, w = 100, justify = "RIGHT" },
        { key = "deaths",     x = 680, w = 85,  justify = "RIGHT" },
        { key = "avoidable",  x = 780, w = 140, justify = "RIGHT" },
    }
    for _, col in ipairs(columns) do
        local h = Text(performance, T(col.key), 8, true)
        h:SetPoint("TOPLEFT", col.x, -38)
        h:SetWidth(col.w)
        h:SetJustifyH(col.justify)
        h:SetTextColor(unpack(C.dim))
    end
    Divider(performance, -58)

    f._playerRows = {}
    for i = 1, 5 do
        local row = CreateFrame("Frame", nil, performance)
        row:SetPoint("TOPLEFT", 10, -62 - (i - 1) * 34)
        row:SetPoint("TOPRIGHT", -10, -62 - (i - 1) * 34)
        row:SetHeight(32)

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        if i % 2 == 1 then
            bg:SetColorTexture(C.panel2[1], C.panel2[2], C.panel2[3], 0.30)
        else
            bg:SetColorTexture(0, 0, 0, 0)
        end

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", 4, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row._icon = icon

        local name = Text(row, "", 10, true)
        name:SetPoint("LEFT", 30, 0)
        name:SetWidth(270)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        row._name = name

        local function Value(x, w)
            local fs = Text(row, "—", 9, false)
            fs:SetPoint("LEFT", x - 10, 0)
            fs:SetWidth(w)
            fs:SetJustifyH("RIGHT")
            return fs
        end
        row._dps = Value(324, 105)
        row._hps = Value(444, 105)
        row._interrupts = Value(565, 100)
        row._deaths = Value(680, 85)
        row._avoidable = Value(780, 140)
        row:Hide()
        f._playerRows[i] = row
    end

    local splits = Card(f, PAD, -456, W - PAD * 2, 164, T("splits"))
    f._splits = splits
    f._splitCells = {}
    local cellW = (W - PAD * 2 - 36) / 3
    for i = 1, 6 do
        local col = (i - 1) % 3
        local row = math.floor((i - 1) / 3)
        local cell = CreateFrame("Frame", nil, splits)
        cell:SetPoint("TOPLEFT", 12 + col * cellW, -36 - row * 54)
        cell:SetSize(cellW - 8, 46)
        local label = Text(cell, "", 8, false)
        label:SetPoint("TOPLEFT", 0, -2)
        label:SetWidth(cellW - 12)
        label:SetWordWrap(false)
        label:SetTextColor(unpack(C.dim))
        local value = Text(cell, "", 14, true)
        value:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
        value:SetTextColor(unpack(C.text))
        cell._label = label
        cell._value = value
        cell:Hide()
        f._splitCells[i] = cell
    end
    f._splitEmpty = Text(splits, T("no_splits"), 9, false)
    f._splitEmpty:SetPoint("TOPLEFT", 14, -46)
    f._splitEmpty:SetTextColor(unpack(C.dim))
    f._splitEmpty:Hide()

    return f
end

local function Populate(runData)
    local f = EnsureFrame()
    f._runData = runData

    if type(runData) ~= "table" then
        f._dungeon:SetText(T("no_data"))
        for _, value in pairs(f._summaryStats) do value:SetText("—") end
        for _, row in ipairs(f._playerRows) do row:Hide() end
        for _, cell in ipairs(f._splitCells) do cell:Hide() end
        f._splitEmpty:SetText(T("no_data"))
        f._splitEmpty:Show()
        return
    end

    local history = FindHistoryRun(runData)
    local meter = MeterSnapshot(runData)
    local players = BuildPlayers(runData, meter)
    local meta = type(runData._tmRunAnalysis) == "table" and runData._tmRunAnalysis or {}

    local dungeon = runData.dungeonName or (history and history.mapName) or T("unknown")
    local level = Number(runData.keyLevel) or (history and Number(history.level)) or 0
    f._dungeon:SetText(level > 0 and string.format("%s  +%d", dungeon, level) or dungeon)

    local onTime = history and history.onTime
    if onTime == nil then onTime = runData.onTime end
    if onTime == nil then onTime = meta.onTime end

    local duration = history and Number(history.durationMS) and history.durationMS / 1000 or Number(runData.duration)
    local deaths = history and Number(history.deaths) or SumPlayerDeaths(players)
    local scoreGain = history and Number(history.scoreGain) or Number(meta.scoreGain)

    local stats = f._summaryStats
    stats.key_level:SetText(level > 0 and ("+" .. level) or "—")
    stats.key_level:SetTextColor(unpack(C.accent))
    stats.status:SetText(onTime == true and T("timed") or (onTime == false and T("depleted") or "—"))
    stats.status:SetTextColor(unpack(onTime == true and C.green or (onTime == false and C.red or C.text)))
    stats.duration:SetText(FormatTime(duration))
    stats.duration:SetTextColor(unpack(C.text))
    stats.deaths:SetText(deaths ~= nil and tostring(math.floor(deaths + 0.5)) or "—")
    stats.deaths:SetTextColor(unpack((deaths or 0) > 0 and C.yellow or C.text))
    stats.score_gain:SetText(scoreGain ~= nil and string.format("+%.0f", scoreGain) or "—")
    stats.score_gain:SetTextColor(unpack((scoreGain or 0) > 0 and C.green or C.text))

    f._perfNote:SetText(meter and "" or T("no_meter"))
    for i, row in ipairs(f._playerRows) do
        local player = players[i]
        if player then
            if player.specIcon then
                row._icon:SetTexture(player.specIcon)
                row._icon:Show()
            else
                row._icon:Hide()
            end
            row._name:SetText(player.name or T("unknown"))
            row._name:SetTextColor(ClassColor(player.class))
            row._dps:SetText(FormatNumber(player.dps))
            row._hps:SetText(FormatNumber(player.hps))
            row._interrupts:SetText(player.interrupts ~= nil and tostring(math.floor(player.interrupts + 0.5)) or "—")
            row._deaths:SetText(player.deaths ~= nil and tostring(math.floor(player.deaths + 0.5)) or "—")
            row._avoidable:SetText(FormatNumber(player.avoidable))
            row._deaths:SetTextColor(unpack((player.deaths or 0) > 0 and C.yellow or C.text))
            row._avoidable:SetTextColor(unpack((player.avoidable or 0) > 0 and C.yellow or C.text))
            row:Show()
        else
            row:Hide()
        end
    end

    local splitItems = {}
    local splitData = history and history.splits or nil
    if splitData and Number(splitData.forcesDone) then
        splitItems[#splitItems + 1] = { T("forces"), FormatTime(splitData.forcesDone) }
    end
    if splitData and type(splitData.bosses) == "table" then
        for i, boss in ipairs(splitData.bosses) do
            if #splitItems >= 6 then break end
            if type(boss) == "table" and Number(boss.time) then
                splitItems[#splitItems + 1] = {
                    boss.name or ("Boss " .. i),
                    FormatTime(boss.time),
                }
            end
        end
    end

    for i, cell in ipairs(f._splitCells) do
        local item = splitItems[i]
        if item then
            cell._label:SetText(item[1])
            cell._value:SetText(item[2])
            cell:Show()
        else
            cell:Hide()
        end
    end
    f._splitEmpty:SetShown(#splitItems == 0)
    if #splitItems == 0 then f._splitEmpty:SetText(T("no_splits")) end
end

function MP:OpenRunAnalysis(runData)
    if InCombatLockdown() then return false end

    if type(runData) ~= "table" then
        local ts = _G.TomoMod_TomoScore
        local db = ts and ts.GetDB and ts:GetDB() or nil
        runData = db and db.lastRun or nil
    end

    if self.Frame and self.Frame:IsShown() and self.Hide then
        self:Hide()
    end

    local f = EnsureFrame()
    Populate(runData)
    f:Show()
    f:Raise()
    return true
end

function MP:HideRunAnalysis()
    if self.RunAnalysisFrame then self.RunAnalysisFrame:Hide() end
end

function MP:IsRunAnalysisShown()
    return self.RunAnalysisFrame and self.RunAnalysisFrame:IsShown() or false
end

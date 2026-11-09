-- =====================================================================
-- TomoMod_MythicPlus / SurvivalAnalysis.lua
-- Run Analysis V2: death chronology + detailed local-player death recap.
-- =====================================================================

local MP = TomoMod_MythicPlus
if not MP then return end

local SA = {}
MP.SurvivalAnalysis = SA

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local WHITE8    = "Interface\\Buttons\\WHITE8x8"

local brand = TomoMod_Utils.BRAND
local C = {
    panel  = { 0.055, 0.065, 0.082, 0.97 },
    panel2 = { 0.070, 0.082, 0.102, 0.92 },
    border = { 0.16, 0.18, 0.22, 1 },
    accent = { brand[1], brand[2], brand[3], 1 },
    text   = { 0.94, 0.96, 0.95, 1 },
    dim    = { 0.50, 0.54, 0.58, 1 },
    green  = { 0.55, 0.90, 0.20, 1 },
    yellow = { 0.95, 0.76, 0.14, 1 },
    red    = { 0.90, 0.26, 0.24, 1 },
}

local STRINGS = {
    enUS = {
        summary="Summary", survival="Survival", chronology="Death chronology", detail="Death detail",
        no_data="No survival data was recorded for this run.", complete="complete tracking",
        partial="partial tracking", observed="%d observed / %d total", deaths="%d deaths",
        local_detail="Recap", party_detail="Blizzard's detailed recap was not available for this death.",
        local_missing="The death was recorded, but Blizzard's detailed recap was not readable in time.",
        select="Select a death to inspect it.", fatal="Fatal event", timeline="Last events before death",
        damage="Damage", overkill="Overkill", max_health="Max health", unknown="Unknown",
        more="+%d additional deaths not shown", heal="Heal",
    },
    frFR = {
        summary="Résumé", survival="Survie", chronology="Chronologie des morts", detail="Détail de la mort",
        no_data="Aucune donnée de survie n'a été enregistrée pour ce run.", complete="suivi complet",
        partial="suivi partiel", observed="%d observées / %d au total", deaths="%d morts",
        local_detail="Récap", party_detail="Le récap détaillé Blizzard n'est pas disponible pour cette mort.",
        local_missing="La mort a été enregistrée, mais le récap Blizzard n'a pas été lisible à temps.",
        select="Sélectionne une mort pour l'analyser.", fatal="Événement fatal", timeline="Derniers événements avant la mort",
        damage="Dégâts", overkill="Overkill", max_health="Vie max", unknown="Inconnu",
        more="+%d morts supplémentaires non affichées", heal="Soin",
    },
    deDE = {
        summary="Übersicht", survival="Überleben", chronology="Todeschronologie", detail="Todesdetails",
        no_data="Für diesen Run wurden keine Überlebensdaten gespeichert.", complete="vollständige Erfassung",
        partial="teilweise Erfassung", observed="%d beobachtet / %d gesamt", deaths="%d Tode",
        local_detail="Rückblick", party_detail="Blizzards detaillierter Rückblick ist für diesen Tod nicht verfügbar.",
        local_missing="Der Tod wurde erfasst, aber Blizzards Todesrückblick war nicht rechtzeitig lesbar.",
        select="Wähle einen Tod zur Analyse.", fatal="Tödliches Ereignis", timeline="Letzte Ereignisse vor dem Tod",
        damage="Schaden", overkill="Overkill", max_health="Max. Gesundheit", unknown="Unbekannt",
        more="+%d weitere Tode nicht angezeigt", heal="Heilung",
    },
    esES = {
        summary="Resumen", survival="Supervivencia", chronology="Cronología de muertes", detail="Detalle de muerte",
        no_data="No se registraron datos de supervivencia para esta run.", complete="seguimiento completo",
        partial="seguimiento parcial", observed="%d observadas / %d totales", deaths="%d muertes",
        local_detail="Resumen", party_detail="El resumen detallado de Blizzard no está disponible para esta muerte.",
        local_missing="La muerte fue registrada, pero el resumen de Blizzard no estuvo disponible a tiempo.",
        select="Selecciona una muerte para analizarla.", fatal="Evento fatal", timeline="Últimos eventos antes de morir",
        damage="Daño", overkill="Overkill", max_health="Salud máxima", unknown="Desconocido",
        more="+%d muertes adicionales no mostradas", heal="Sanación",
    },
    itIT = {
        summary="Riepilogo", survival="Sopravvivenza", chronology="Cronologia morti", detail="Dettaglio morte",
        no_data="Nessun dato di sopravvivenza registrato per questa run.", complete="tracciamento completo",
        partial="tracciamento parziale", observed="%d osservate / %d totali", deaths="%d morti",
        local_detail="Riepilogo", party_detail="Il riepilogo dettagliato Blizzard non è disponibile per questa morte.",
        local_missing="La morte è stata registrata, ma il riepilogo Blizzard non era leggibile in tempo.",
        select="Seleziona una morte da analizzare.", fatal="Evento fatale", timeline="Ultimi eventi prima della morte",
        damage="Danni", overkill="Overkill", max_health="Salute massima", unknown="Sconosciuto",
        more="+%d morti aggiuntive non mostrate", heal="Cura",
    },
    ptBR = {
        summary="Resumo", survival="Sobrevivência", chronology="Cronologia de mortes", detail="Detalhe da morte",
        no_data="Nenhum dado de sobrevivência foi registrado para esta run.", complete="rastreamento completo",
        partial="rastreamento parcial", observed="%d observadas / %d no total", deaths="%d mortes",
        local_detail="Resumo", party_detail="O resumo detalhado da Blizzard não está disponível para esta morte.",
        local_missing="A morte foi registrada, mas o resumo da Blizzard não ficou legível a tempo.",
        select="Selecione uma morte para analisá-la.", fatal="Evento fatal", timeline="Últimos eventos antes da morte",
        damage="Dano", overkill="Overkill", max_health="Vida máxima", unknown="Desconhecido",
        more="+%d mortes adicionais não exibidas", heal="Cura",
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
    fs:SetFont(bold and FONT_BOLD or FONT, size or 10, "")
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

local function FormatTime(seconds)
    if type(seconds) ~= "number" or seconds < 0 then return "—" end
    seconds = math.floor(seconds + 0.5)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%d:%02d", m, s)
end

local function FormatNumber(value)
    if type(value) ~= "number" then return "—" end
    local abs = math.abs(value)
    if abs >= 1000000000 then return string.format("%.2fB", value / 1000000000) end
    if abs >= 1000000 then return string.format("%.1fM", value / 1000000) end
    if abs >= 1000 then return string.format("%.1fK", value / 1000) end
    return tostring(math.floor(value + 0.5))
end

local function ClassColor(class)
    local cc = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if cc then return cc.r, cc.g, cc.b end
    return C.text[1], C.text[2], C.text[3]
end

local function SurvivalFromRun(runData)
    local meta = type(runData) == "table" and type(runData._tmRunAnalysis) == "table"
        and runData._tmRunAnalysis or nil
    return meta and type(meta.survival) == "table" and meta.survival or nil
end

local function Tab(parent, label, x, callback)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetPoint("TOPLEFT", x, -16)
    b:SetSize(92, 24)

    -- The V1 header is a mouse-enabled drag surface covering the first 56 px
    -- of the window.  V2 tabs live inside that same area; at the default
    -- sibling frame level the header can win mouse hit-testing even though the
    -- button artwork is visible.  Keep the tabs explicitly above that drag
    -- surface and register the click we actually consume.
    b:SetFrameLevel(parent:GetFrameLevel() + 20)
    b:EnableMouse(true)
    b:RegisterForClicks("LeftButtonUp")

    Backdrop(b, { 0.04, 0.05, 0.06, 0.90 }, C.border)
    local t = Text(b, label, 9, true)
    t:SetPoint("CENTER")
    b._text = t
    b:SetScript("OnClick", callback)
    return b
end

local function SetTabStyle(button, selected)
    if not button then return end
    if selected then
        button:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.20)
        button:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.90)
        button._text:SetTextColor(1, 1, 1, 1)
    else
        button:SetBackdropColor(0.04, 0.05, 0.06, 0.90)
        button:SetBackdropBorderColor(unpack(C.border))
        button._text:SetTextColor(unpack(C.dim))
    end
end

local function EnsureTimelineRow(parent, index)
    parent._timelineRows = parent._timelineRows or {}
    if parent._timelineRows[index] then return parent._timelineRows[index] end

    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 12, -194 - (index - 1) * 28)
    row:SetPoint("TOPRIGHT", -12, -194 - (index - 1) * 28)
    row:SetHeight(26)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", 0, 0)
    icon:SetSize(20, 20)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row._icon = icon

    local when = Text(row, "", 8, false)
    when:SetPoint("LEFT", 28, 0)
    when:SetWidth(52)
    when:SetTextColor(unpack(C.dim))
    row._when = when

    local name = Text(row, "", 9, false)
    name:SetPoint("LEFT", 86, 0)
    name:SetWidth(250)
    name:SetWordWrap(false)
    row._name = name

    local amount = Text(row, "", 9, false)
    amount:SetPoint("RIGHT", -4, 0)
    amount:SetWidth(170)
    amount:SetJustifyH("RIGHT")
    row._amount = amount

    parent._timelineRows[index] = row
    return row
end

function SA:Ensure(frame)
    if not frame or frame._survivalRoot then return end

    frame._subtitle:SetText("Analyse post-run Mythic+ · V2.1")

    frame._summaryTab = Tab(frame, T("summary"), 320, function()
        SA:SetPage("summary")
    end)
    frame._survivalTab = Tab(frame, T("survival"), 418, function()
        SA:SetPage("survival")
    end)

    local root = CreateFrame("Frame", nil, frame)
    root:SetPoint("TOPLEFT", 18, -72)
    root:SetPoint("BOTTOMRIGHT", -18, 18)
    root:Hide()
    frame._survivalRoot = root

    local left = Card(root, 0, 0, 300, 548, T("chronology"))
    local right = Card(root, 312, 0, 632, 548, T("detail"))
    root._left = left
    root._right = right

    local status = Text(left, "", 9, false)
    status:SetPoint("TOPLEFT", 12, -34)
    status:SetPoint("RIGHT", left, "RIGHT", -12, 0)
    status:SetTextColor(unpack(C.dim))
    left._status = status

    left._rows = {}
    for i = 1, 18 do
        local row = CreateFrame("Button", nil, left, "BackdropTemplate")
        row:SetPoint("TOPLEFT", 10, -58 - (i - 1) * 25)
        row:SetPoint("TOPRIGHT", -10, -58 - (i - 1) * 25)
        row:SetHeight(23)
        Backdrop(row, { 0, 0, 0, 0 }, { 0, 0, 0, 0 })

        local when = Text(row, "", 8, false)
        when:SetPoint("LEFT", 6, 0)
        when:SetWidth(48)
        when:SetTextColor(unpack(C.dim))
        row._when = when

        local name = Text(row, "", 9, true)
        name:SetPoint("LEFT", 58, 0)
        name:SetWidth(150)
        name:SetWordWrap(false)
        row._name = name

        local flag = Text(row, "", 8, false)
        flag:SetPoint("RIGHT", -6, 0)
        flag:SetWidth(64)
        flag:SetJustifyH("RIGHT")
        flag:SetTextColor(unpack(C.accent))
        row._flag = flag

        local rowIndex = i
        row:SetScript("OnClick", function()
            if row._deathIndex then SA:SelectDeath(row._deathIndex) end
        end)
        row:SetScript("OnEnter", function(self)
            if self._deathIndex ~= SA.selectedDeath then
                self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.08)
            end
        end)
        row:SetScript("OnLeave", function(self)
            if self._deathIndex ~= SA.selectedDeath then
                self:SetBackdropColor(0, 0, 0, 0)
            end
        end)
        row._rowIndex = rowIndex
        row:Hide()
        left._rows[i] = row
    end

    local more = Text(left, "", 8, false)
    more:SetPoint("BOTTOMLEFT", 12, 10)
    more:SetTextColor(unpack(C.dim))
    left._more = more

    local player = Text(right, "", 16, true)
    player:SetPoint("TOPLEFT", 14, -38)
    right._player = player

    local at = Text(right, "", 11, true)
    at:SetPoint("TOPRIGHT", -14, -40)
    at:SetTextColor(unpack(C.accent))
    right._at = at

    local note = Text(right, T("select"), 10, false)
    note:SetPoint("TOPLEFT", 14, -78)
    note:SetPoint("RIGHT", right, "RIGHT", -14, 0)
    note:SetWordWrap(true)
    note:SetTextColor(unpack(C.dim))
    right._note = note

    local fatal = CreateFrame("Frame", nil, right, "BackdropTemplate")
    fatal:SetPoint("TOPLEFT", 12, -76)
    fatal:SetPoint("TOPRIGHT", -12, -76)
    fatal:SetHeight(92)
    Backdrop(fatal, C.panel2, C.border)
    fatal:Hide()
    right._fatal = fatal

    local fatalTitle = Text(fatal, T("fatal"), 8, true)
    fatalTitle:SetPoint("TOPLEFT", 10, -8)
    fatalTitle:SetTextColor(unpack(C.accent))

    local fatalIcon = fatal:CreateTexture(nil, "ARTWORK")
    fatalIcon:SetPoint("LEFT", 10, -8)
    fatalIcon:SetSize(40, 40)
    fatalIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    fatal._icon = fatalIcon

    local fatalName = Text(fatal, "", 12, true)
    fatalName:SetPoint("TOPLEFT", 60, -30)
    fatalName:SetWidth(300)
    fatalName:SetWordWrap(false)
    fatal._name = fatalName

    local fatalAmount = Text(fatal, "", 10, false)
    fatalAmount:SetPoint("TOPRIGHT", -10, -30)
    fatalAmount:SetWidth(220)
    fatalAmount:SetJustifyH("RIGHT")
    fatal._amount = fatalAmount

    local timelineTitle = Text(right, T("timeline"), 10, true)
    timelineTitle:SetPoint("TOPLEFT", 14, -176)
    timelineTitle:SetTextColor(unpack(C.accent))
    right._timelineTitle = timelineTitle
    timelineTitle:Hide()

    right._timelineRows = {}
    for i = 1, 10 do
        local row = EnsureTimelineRow(right, i)
        row:Hide()
    end
end

function SA:SetPage(page)
    local frame = MP.RunAnalysisFrame
    if not frame or not frame._survivalRoot then return end
    page = page == "survival" and "survival" or "summary"
    SA.page = page

    local summary = page == "summary"
    if frame._summary then frame._summary:SetShown(summary) end
    if frame._performance then frame._performance:SetShown(summary) end
    if frame._splits then frame._splits:SetShown(summary) end
    frame._survivalRoot:SetShown(not summary)

    SetTabStyle(frame._summaryTab, summary)
    SetTabStyle(frame._survivalTab, not summary)
end

local function FatalEvent(detail)
    if type(detail) ~= "table" or type(detail.events) ~= "table" then return nil end
    local index = tonumber(detail.fatalIndex)
    if index and detail.events[index] then return detail.events[index] end
    for i = #detail.events, 1, -1 do
        if not detail.events[i].isHeal then return detail.events[i] end
    end
    return detail.events[#detail.events]
end

function SA:SelectDeath(index)
    local frame = MP.RunAnalysisFrame
    local root = frame and frame._survivalRoot
    local survival = SA.survival
    if not root or type(survival) ~= "table" then return end
    local death = type(survival.deaths) == "table" and survival.deaths[index] or nil
    if not death then return end

    SA.selectedDeath = index
    for _, row in ipairs(root._left._rows) do
        local selected = row._deathIndex == index
        row:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], selected and 0.16 or 0)
    end

    local right = root._right
    right._player:SetText(death.name or T("unknown"))
    right._player:SetTextColor(ClassColor(death.class))
    right._at:SetText(FormatTime(death.at))

    for _, row in ipairs(right._timelineRows) do row:Hide() end
    right._fatal:Hide()
    right._timelineTitle:Hide()

    local detail = type(death.detail) == "table" and death.detail or nil
    if not detail or type(detail.events) ~= "table" or #detail.events == 0 then
        right._note:SetText(death.detailUnavailable and T("local_missing") or T("party_detail"))
        right._note:Show()
        return
    end

    right._note:Hide()
    local fatal = FatalEvent(detail)
    if fatal then
        right._fatal._icon:SetTexture(fatal.icon or 135274)
        right._fatal._name:SetText(fatal.name or T("unknown"))
        local amount = T("damage") .. "  " .. FormatNumber(fatal.amount)
        if type(fatal.overkill) == "number" and fatal.overkill > 0 then
            amount = amount .. "   |cffff5a5a" .. T("overkill") .. " " .. FormatNumber(fatal.overkill) .. "|r"
        end
        if type(detail.maxHP) == "number" and detail.maxHP > 0 then
            amount = amount .. "   " .. T("max_health") .. " " .. FormatNumber(detail.maxHP)
        end
        right._fatal._amount:SetText(amount)
        right._fatal:Show()
    end

    right._timelineTitle:Show()
    local events = detail.events
    local count = math.min(10, #events)
    local startAt = #events - count + 1
    local deathTime = fatal and fatal.timestamp or events[#events].timestamp

    for i = 1, count do
        local ev = events[startAt + i - 1]
        local row = right._timelineRows[i]
        row._icon:SetTexture(ev.icon or 135274)

        if type(deathTime) == "number" and type(ev.timestamp) == "number" then
            row._when:SetText(string.format("-%.1fs", math.max(0, deathTime - ev.timestamp)))
        else
            row._when:SetText("#" .. tostring(startAt + i - 1))
        end
        row._name:SetText(ev.name or T("unknown"))

        local prefix = ev.isHeal and "+" or "-"
        local amount = prefix .. FormatNumber(math.abs(tonumber(ev.amount) or 0))
        if type(detail.maxHP) == "number" and detail.maxHP > 0 and type(ev.currentHP) == "number" then
            local pct = math.max(0, math.min(100, ev.currentHP / detail.maxHP * 100))
            amount = amount .. string.format("  %.0f%%", pct)
        end
        row._amount:SetText(amount)
        row._amount:SetTextColor(unpack(ev.isHeal and C.green or C.text))
        row:Show()
    end
end

function SA:Populate(runData)
    local frame = MP.RunAnalysisFrame
    if not frame then return end
    self:Ensure(frame)

    local root = frame._survivalRoot
    local left = root._left
    local right = root._right
    local survival = SurvivalFromRun(runData)
    SA.survival = survival
    SA.selectedDeath = nil

    for _, row in ipairs(left._rows) do
        row._deathIndex = nil
        row:Hide()
    end
    left._more:SetText("")
    right._player:SetText("")
    right._at:SetText("")
    right._fatal:Hide()
    right._timelineTitle:Hide()
    for _, row in ipairs(right._timelineRows) do row:Hide() end

    if not survival or type(survival.deaths) ~= "table" then
        left._status:SetText(T("no_data"))
        right._note:SetText(T("no_data"))
        right._note:Show()
        return
    end

    local observed = tonumber(survival.observedDeaths) or #survival.deaths
    local total = tonumber(survival.totalDeaths) or observed
    if survival.reliable == true then
        left._status:SetText(string.format(T("deaths"), total) .. " · " .. T("complete"))
        left._status:SetTextColor(unpack(C.green))
    else
        left._status:SetText(string.format(T("observed"), observed, total) .. " · " .. T("partial"))
        left._status:SetTextColor(unpack(C.yellow))
    end

    local shown = math.min(18, #survival.deaths)
    local firstDetail
    for i = 1, shown do
        local death = survival.deaths[i]
        local row = left._rows[i]
        row._deathIndex = i
        row._when:SetText(FormatTime(death.at))
        row._name:SetText(death.name or T("unknown"))
        row._name:SetTextColor(ClassColor(death.class))
        row._flag:SetText(death.detail and T("local_detail") or "")
        row:SetBackdropColor(0, 0, 0, 0)
        row:Show()
        if not firstDetail and death.detail then firstDetail = i end
    end

    if #survival.deaths > shown then
        left._more:SetText(string.format(T("more"), #survival.deaths - shown))
    end

    if shown == 0 then
        right._note:SetText(T("select"))
        right._note:Show()
        return
    end

    SA:SelectDeath(firstDetail or 1)
end

function MP:SetRunAnalysisPage(page)
    SA:SetPage(page)
end

-- RunAnalysis.lua is loaded immediately before this file. Wrapping its public
-- entry point lets V2 decorate the existing V1 window without duplicating or
-- destabilising the summary/performance/splits implementation.
if MP.OpenRunAnalysis and not MP._survivalAnalysisWrapped then
    MP._survivalAnalysisWrapped = true
    local OpenRunAnalysis = MP.OpenRunAnalysis
    function MP:OpenRunAnalysis(runData)
        local result = OpenRunAnalysis(self, runData)
        local frame = self.RunAnalysisFrame
        if frame then
            SA:Ensure(frame)
            SA:Populate(frame._runData or runData)
            SA:SetPage("summary")
        end
        return result
    end
end

-- =====================================================================
-- GlobalSearch.lua — [Lot B] Per-option global search for the config GUI
--
-- Every option widget built by Config/Widgets.lua self-registers here
-- through the optional W._RegisterSearchEntry hook. Typing 2+ characters
-- in the sidebar search box shows a results popup; clicking a result
-- deep-links to the exact category/tab, scrolls to the option and
-- flashes it. Pages never visited are ghost-built once (offscreen) on
-- the first search so the index covers the whole GUI.
--
-- Self-contained: removing this file (and its .toc line) disables the
-- feature entirely — the hooks in Widgets.lua/ConfigUI.lua are opt-in.
-- =====================================================================

local W = TomoMod_Widgets
local C = TomoMod_Config
local L = TomoMod_L
if not (W and C) then return end

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local WHITE8    = "Interface\\Buttons\\WHITE8x8"

local SEP         = "\1"
local MAX_RESULTS = 8
local ROW_H       = 34

local GS = {
    entries      = {},   -- ordered entry list
    byKey        = {},   -- composite key -> true (dedupe across rebuilds)
    regionByKey  = {},   -- composite key -> last live region (cache hits)
    indexed      = false,
    pendingKey   = nil,
    pendingUntil = 0,
}
TomoMod_GlobalSearch = GS

-- ---------------------------------------------------------------------
-- Accent folding (French UI: "echelle" must match "Échelle")
-- ---------------------------------------------------------------------
-- [L1] accent folding now lives in Forge.Util (shared with the studio
-- and every future filter).
local function Fold(s)
    local F = TomoMod_Forge
    if F and F.Util then return F.Util.Fold(s) end
    return tostring(s or ""):lower()
end

-- ---------------------------------------------------------------------
-- Highlight overlay (gold flash on the landed option)
-- ---------------------------------------------------------------------
local flash

local function EnsureFlash()
    if flash then return end
    flash = CreateFrame("Frame", nil, UIParent)
    flash.tex = flash:CreateTexture(nil, "OVERLAY")
    flash.tex:SetAllPoints()
    flash.tex:SetColorTexture(1, 0.82, 0.25, 1)
    flash:Hide()
end

local function ScrollToRegion(region)
    local p = region.GetParent and region:GetParent()
    local scrollFrame
    while p and p ~= UIParent do
        if p.GetObjectType and p:GetObjectType() == "ScrollFrame" then
            scrollFrame = p
            break
        end
        p = p:GetParent()
    end
    if not scrollFrame then return end
    local child = scrollFrame:GetScrollChild()
    if not child then return end
    local childTop, regionTop = child:GetTop(), region:GetTop()
    if not childTop or not regionTop then return end
    local offset = childTop - regionTop
    local range  = scrollFrame:GetVerticalScrollRange() or 0
    scrollFrame:SetVerticalScroll(math.max(0, math.min(offset - 70, range)))
    local cont = scrollFrame:GetParent()
    if cont and cont.UpdateScroll then cont.UpdateScroll() end
end

function GS.ScheduleHighlight(region)
    if not region then return end
    -- C_Timer.After(0): let the freshly built panel lay out first
    C_Timer.After(0, function()
        ScrollToRegion(region)
        C_Timer.After(0, function()
            if not (region.GetTop and region:GetTop()) then return end
            EnsureFlash()
            local host = (region.GetParent and region:GetParent()) or UIParent
            flash:SetParent(host)
            flash:SetFrameLevel((host.GetFrameLevel and host:GetFrameLevel() or 10) + 20)
            flash:ClearAllPoints()
            flash:SetPoint("TOPLEFT",     region, "TOPLEFT",     -5,  4)
            flash:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT",  5, -4)
            flash.t0 = GetTime()
            flash:Show()
            flash:SetScript("OnUpdate", function(self)
                local e = GetTime() - self.t0
                if e >= 1.8 then
                    self:Hide()
                    self:SetScript("OnUpdate", nil)
                    return
                end
                local pulse = math.cos(e * math.pi * 3.5) * 0.5 + 0.5
                self:SetAlpha((0.12 + 0.26 * pulse) * (1 - e / 1.8))
            end)
        end)
    end)
end

-- ---------------------------------------------------------------------
-- Registration hook — called by Widgets.lua during every panel build
-- ---------------------------------------------------------------------
function W._RegisterSearchEntry(label, region, kind)
    if type(label) ~= "string" or label == "" then return end
    local ctx = W._buildCtx
    if not ctx or not ctx.cat then return end
    kind = kind or "option"
    local section = (kind == "section") and nil or ctx.section
    -- Keyed on the FULL tab path, not just ctx.tab. Panels reuse one builder
    -- across sibling tabs (every castbar unit, every unit frame), so two
    -- different pages produce the same innermost tab key and the same section
    -- label — with only that key they collapsed into one entry and every copy
    -- but the first vanished from the index.
    local pathKey = (W.GetBuildTabPath and table.concat(W.GetBuildTabPath(), ">")) or (ctx.tab or "")
    local key = table.concat({ ctx.cat, pathKey, section or "", kind, label }, SEP)
    -- A ghost frame is always offscreen, so it must never replace the live region
    -- the cached-page fallback relies on.
    if not GS.ghostBuilding then GS.regionByKey[key] = region end

    if not GS.byKey[key] then
        GS.byKey[key] = true
        local e = {
            key      = key,
            kind     = kind,
            label    = label,
            cat      = ctx.cat,
            catLabel = ctx.catLabel or ctx.cat,
            tab      = ctx.tab,
            tabLabel = ctx.tabLabel,
            tabPath  = W.GetBuildTabPath and W.GetBuildTabPath() or nil,
            section  = section,
        }
        e.labelFold = Fold(label)
        e.hay = e.labelFold .. " "
            .. (section and Fold(section) or "") .. " "
            .. (e.tabLabel and Fold(e.tabLabel) or "") .. " "
            .. Fold(e.catLabel)
        GS.entries[#GS.entries + 1] = e
    end

    -- Deep-link landing: this exact entry was requested, capture its frame.
    -- Skipped during ghost indexing: the run is asynchronous now, so it can
    -- overlap a jump and would otherwise flash a hidden offscreen frame.
    if not GS.ghostBuilding and GS.pendingKey == key and GetTime() < GS.pendingUntil then
        GS.pendingKey = nil
        GS.ScheduleHighlight(region)
    end
end

-- ---------------------------------------------------------------------
-- Ghost indexing — build every page and every tab once, spread over frames
-- ---------------------------------------------------------------------
-- Previously this walked the category tree and called each page builder
-- once. But CreateTabPanel only builds its FIRST tab eagerly, so anything
-- living in a second or third sub-tab never entered the index at all —
-- roughly two thirds of the GUI. Walking every tab means building far more
-- panels, so the work is queued and drained across frames instead of
-- freezing the client on the first search.
local GHOST_BUDGET_MS = 6      -- work per tick
local GHOST_INTERVAL  = 0.05   -- pause between ticks

local ghostQueue, ghostBin, ghostLabels
local GhostTick

local function GhostSchedule()
    if ghostQueue and #ghostQueue > 0 then
        C_Timer.After(GHOST_INTERVAL, GhostTick)
    else
        ghostQueue, ghostBin, ghostLabels = nil, nil, nil
        GS.indexing = false
        GS.indexReady = true
        -- Results typed before the index finished were incomplete: refresh
        -- them rather than leave the player looking at a stale list.
        if GS.RefreshOpenSearch then GS.RefreshOpenSearch() end
    end
end

-- Runs one unit of work with the sink active, then queues whatever tab
-- panels that unit created. `cat` rides along on every job: the build
-- context is wiped between ticks (the player can navigate mid-run), so each
-- job has to re-establish its own category before touching a panel.
local function GhostRun(cat, fn)
    local sink = {}
    W._ghostSink = sink
    GS.ghostBuilding = true
    pcall(fn)
    GS.ghostBuilding = false
    W._ghostSink = nil

    for i = 1, #sink do
        local panel = sink[i]
        local keys  = panel.tabKeys
        if keys then
            for k = 1, #keys do
                -- SwitchTab on the already-built tab is a cheap no-op, so
                -- there is no need to know which one was built eagerly.
                ghostQueue[#ghostQueue + 1] = { cat = cat, panel = panel, tab = keys[k] }
            end
        end
    end
end

local function GhostPage(job)
    local builder = _G[job.global]
    if not builder then return end
    W.SetBuildContext(job.cat, ghostLabels[job.cat] or job.cat)
    if job.tabKey then W._SetBuildTab(job.tabKey, job.tabLabel) end
    local host = CreateFrame("Frame", nil, ghostBin)
    host:SetSize(1000, 600)
    host:Hide()
    GhostRun(job.cat, function() builder(host) end)
end

local function GhostTab(job)
    -- SwitchTab restores its own ancestors from the path it captured at
    -- creation, so only the category has to be put back here.
    W.SetBuildContext(job.cat, ghostLabels[job.cat] or job.cat)
    GhostRun(job.cat, function() job.panel.SwitchTab(job.tab) end)
end

function GhostTick()
    local t0 = debugprofilestop and debugprofilestop() or nil
    local guard = 0
    while ghostQueue and #ghostQueue > 0 do
        local job = table.remove(ghostQueue, 1)
        if job.global then
            GhostPage(job)
        elseif job.panel and job.panel.SwitchTab then
            GhostTab(job)
        end
        guard = guard + 1
        if t0 then
            if debugprofilestop() - t0 >= GHOST_BUDGET_MS then break end
        elseif guard >= 2 then
            break
        end
    end
    -- Leave the build context neutral between ticks: the player can navigate
    -- while indexing runs, and a stale context would mislabel their entries.
    W.SetBuildContext(nil, nil)
    GhostSchedule()
end

local function GhostIndexAll()
    if GS.indexed then return end
    GS.indexed = true
    local tree = C.CategoryTree
    if not tree then return end

    ghostLabels = {}
    if C.Categories then
        for _, cat in ipairs(C.Categories) do
            ghostLabels[cat.key] = cat.label
        end
    end

    ghostBin = CreateFrame("Frame", nil, UIParent)
    ghostBin:Hide()
    ghostQueue = {}

    for catKey, tabs in pairs(tree) do
        for _, t in ipairs(tabs) do
            ghostQueue[#ghostQueue + 1] =
                { cat = catKey, tabKey = t.key, tabLabel = t.label, global = t.global }
        end
    end
    for catKey, globalName in pairs(C.SinglePages or { accueil = "TomoMod_ConfigPanel_Accueil" }) do
        ghostQueue[#ghostQueue + 1] = { cat = catKey, global = globalName }
    end

    GS.indexing = true
    GhostSchedule()
end

-- ---------------------------------------------------------------------
-- Scoring — every token must match; label hits beat path hits
-- ---------------------------------------------------------------------
local function MatchScore(e, tokens)
    local score = 0
    for _, tk in ipairs(tokens) do
        local inLabel = e.labelFold:find(tk, 1, true)
        if inLabel then
            score = score + 300 - inLabel + (inLabel == 1 and 60 or 0)
        else
            local pos = e.hay:find(tk, 1, true)
            if not pos then return nil end
            score = score + 120 - math.min(pos, 100)
        end
    end
    if e.kind == "section" then score = score - 25 end
    return score
end

local function Search(query)
    local q = Fold(query):gsub("^%s+", ""):gsub("%s+$", "")
    if #q < 2 then return nil end
    local tokens = {}
    for tk in q:gmatch("%S+") do
        tokens[#tokens + 1] = tk
    end
    if #tokens == 0 then return nil end
    local results = {}
    for _, e in ipairs(GS.entries) do
        local s = MatchScore(e, tokens)
        if s then
            results[#results + 1] = { e = e, s = s }
        end
    end
    table.sort(results, function(a, b)
        if a.s ~= b.s then return a.s > b.s end
        return a.e.label < b.e.label
    end)
    return results
end

-- ---------------------------------------------------------------------
-- Deep-link
-- ---------------------------------------------------------------------
local popup

local function JumpTo(entry)
    GS.pendingKey   = entry.key
    GS.pendingUntil = GetTime() + 3

    -- entry.tab is the INNERMOST tab key. Handing that to the category's
    -- outer tab bar never matched, so a result inside a nested panel
    -- (raid frame HoTs, resource bars, ...) used to land on the first tab
    -- of the category instead. The stored path names one tab per level.
    if entry.tabPath and #entry.tabPath > 0 then
        C._pendingTabPath = entry.tabPath
        C._pendingGroupTab = nil
        -- A cached page is re-shown without rebuilding, so no tab bar is
        -- created and the path would be ignored: force the rebuild.
        if C.InvalidateCategory then C.InvalidateCategory(entry.cat) end
    elseif entry.tab then
        C._pendingGroupTab = entry.tab
    end

    C.SwitchCategory(entry.cat)

    -- SwitchCategory builds the page synchronously, so every tab bar has
    -- read its level by now. Clearing here rather than inside SwitchCategory
    -- keeps this lot off a hunk other lots also touch, and a stale path
    -- would otherwise hijack the next category build.
    C._pendingTabPath = nil
    -- [Lot C] Cached pages re-show without rebuilding, so no registration
    -- fires to consume the pending key: fall back to the last live region.
    if GS.pendingKey == entry.key then
        C_Timer.After(0, function()
            if GS.pendingKey ~= entry.key then return end
            local r = GS.regionByKey[entry.key]
            if r and r.IsVisible and r:IsVisible() then
                GS.pendingKey = nil
                GS.ScheduleHighlight(r)
            end
        end)
    end
    if popup then popup:Hide() end
    local cf = _G["TomoModConfigFrame"]
    if cf and cf._searchBox then
        cf._searchBox:SetText("")
        cf._searchBox:ClearFocus()
    end
end

-- ---------------------------------------------------------------------
-- Public deep-link: jump to a section by its localized header text
-- ---------------------------------------------------------------------
-- Used by the Roles guide pages. It resolves against the live index rather
-- than rebuilding a composite key on the caller's side, because a section
-- registers under the tab path that actually produced it — and with nested
-- tab bars the caller has no way to know that path.
--
-- Returns true when the section was found and targeted, false when it only
-- managed to open the right category.
function GS.JumpToSection(cat, sectionLabel)
    if not (cat and sectionLabel and sectionLabel ~= "") then return false end

    -- Guarantees the index covers pages the player has never opened.
    GhostIndexAll()

    for _, e in ipairs(GS.entries) do
        if e.kind == "section" and e.cat == cat and e.label == sectionLabel then
            JumpTo(e)
            return true
        end
    end

    -- Index miss (renamed section, panel failed to build): still put the
    -- player on the right category rather than silently doing nothing.
    C.SwitchCategory(cat)
    return false
end

-- ---------------------------------------------------------------------
-- Public deep-link by explicit tab path
-- ---------------------------------------------------------------------
-- The caller names the exact route (category + one tab key per level) and
-- the section header to land on. Nothing is looked up in the index, so this
-- works on a cold client and is unaffected by how far ghost indexing has
-- got. The composite key is reconstructible here because registration keys
-- are built from the same tab path this caller declares.
function GS.JumpToPath(cat, path, sectionLabel)
    if not (cat and path and #path > 0 and sectionLabel and sectionLabel ~= "") then
        return false
    end
    GS.pendingKey   = table.concat({ cat, table.concat(path, ">"), "", "section", sectionLabel }, SEP)
    GS.pendingUntil = GetTime() + 3

    C._pendingGroupTab = nil
    C._pendingTabPath  = path
    -- Force a rebuild: a cached page is re-shown without building, which is
    -- what made these links land on whatever tab the player last used.
    if C.InvalidateCategory then C.InvalidateCategory(cat) end
    C.SwitchCategory(cat)
    C._pendingTabPath = nil
    return true
end

-- ---------------------------------------------------------------------
-- Results popup (anchored under the sidebar search box)
-- ---------------------------------------------------------------------
local function EnsurePopup()
    if popup then return end
    local cf = _G["TomoModConfigFrame"]
    if not (cf and cf._searchWrap) then return end

    popup = CreateFrame("Frame", nil, cf, "BackdropTemplate")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(560)
    popup:SetPoint("TOPLEFT", cf._searchWrap, "BOTTOMLEFT", 0, -4)
    popup:SetWidth(340)
    popup:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    popup:SetBackdropColor(0.055, 0.055, 0.075, 0.98)
    popup:SetBackdropBorderColor(0.20, 0.20, 0.25, 1)
    popup:Hide()

    popup.empty = popup:CreateFontString(nil, "OVERLAY")
    popup.empty:SetFont(FONT, 11, "")
    popup.empty:SetPoint("CENTER")
    popup.empty:SetTextColor(0.40, 0.40, 0.46, 1)
    -- No `or "..."` fallback here: TomoMod_L's __index returns the key itself
    -- for an undefined key, so the right-hand side of an `or` is unreachable
    -- and the raw key would have been what showed on screen. The key is defined
    -- in all six locales (Locale_300.lua) instead.
    popup.empty:SetText(L["gs_no_results"])

    popup.rows = {}
    for i = 1, MAX_RESULTS do
        local row = CreateFrame("Button", nil, popup)
        row:SetHeight(ROW_H)
        row:SetPoint("TOPLEFT",  1, -((i - 1) * ROW_H) - 4)
        row:SetPoint("TOPRIGHT", -1, -((i - 1) * ROW_H) - 4)

        local hl = row:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0)
        row.hl = hl

        local lbl = row:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT_BOLD, 11, "")
        lbl:SetPoint("TOPLEFT", 8, -4)
        lbl:SetPoint("RIGHT", -8, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetWordWrap(false)
        lbl:SetTextColor(0.88, 0.90, 0.89, 1)
        row.lbl = lbl

        local sub = row:CreateFontString(nil, "OVERLAY")
        sub:SetFont(FONT, 9, "")
        sub:SetPoint("BOTTOMLEFT", 8, 4)
        sub:SetPoint("RIGHT", -8, 0)
        sub:SetJustifyH("LEFT")
        sub:SetWordWrap(false)
        sub:SetTextColor(0.42, 0.42, 0.50, 1)
        row.sub = sub

        row:SetScript("OnEnter", function(self) self.hl:SetColorTexture(1, 1, 1, 0.06) end)
        row:SetScript("OnLeave", function(self) self.hl:SetColorTexture(1, 1, 1, 0) end)
        row:SetScript("OnClick", function(self)
            if self.entry then JumpTo(self.entry) end
        end)
        popup.rows[i] = row
    end
end

local function ShowResults(results)
    EnsurePopup()
    if not popup then return end
    local n = math.min(#results, MAX_RESULTS)
    for i = 1, MAX_RESULTS do
        local row = popup.rows[i]
        if i <= n then
            local e = results[i].e
            row.entry = e
            row.lbl:SetText(e.label)
            local path = e.catLabel
            if e.tabLabel then path = path .. "  ›  " .. e.tabLabel end
            if e.section and e.section ~= e.label then path = path .. "  ›  " .. e.section end
            row.sub:SetText(path)
            row:Show()
        else
            row.entry = nil
            row:Hide()
        end
    end
    if n == 0 then
        popup.empty:Show()
        popup:SetHeight(ROW_H + 8)
    else
        popup.empty:Hide()
        popup:SetHeight(n * ROW_H + 8)
    end
    popup:Show()
end

-- ---------------------------------------------------------------------
-- Entry points wired from ConfigUI.lua (sidebar search box)
-- ---------------------------------------------------------------------
local lastResults

function C.NotifySearchText(txt)
    txt = txt or ""
    if #txt < 2 then
        lastResults = nil
        if popup then popup:Hide() end
        return
    end
    GhostIndexAll()
    lastResults = Search(txt)
    if lastResults then
        ShowResults(lastResults)
    elseif popup then
        popup:Hide()
    end
end

-- Enter in the search box jumps to the best result
-- Called when ghost indexing drains: anything typed while the index was
-- still filling produced a partial list.
function GS.RefreshOpenSearch()
    if not (popup and popup:IsShown()) then return end
    local cf = _G["TomoModConfigFrame"]
    local box = cf and cf._searchBox
    local txt = box and box.GetText and box:GetText() or nil
    if not txt or #txt < 2 then return end
    lastResults = Search(txt)
    if lastResults then ShowResults(lastResults) end
end

function C.SubmitSearch()
    if lastResults and lastResults[1] and popup and popup:IsShown() then
        JumpTo(lastResults[1].e)
        return true
    end
    return false
end

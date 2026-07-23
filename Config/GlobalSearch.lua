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
    local key = table.concat({ ctx.cat, ctx.tab or "", section or "", kind, label }, SEP)
    GS.regionByKey[key] = region

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
            section  = section,
        }
        e.labelFold = Fold(label)
        e.hay = e.labelFold .. " "
            .. (section and Fold(section) or "") .. " "
            .. (e.tabLabel and Fold(e.tabLabel) or "") .. " "
            .. Fold(e.catLabel)
        GS.entries[#GS.entries + 1] = e
    end

    -- Deep-link landing: this exact entry was requested, capture its frame
    if GS.pendingKey == key and GetTime() < GS.pendingUntil then
        GS.pendingKey = nil
        GS.ScheduleHighlight(region)
    end
end

-- ---------------------------------------------------------------------
-- Ghost indexing — build every page once, offscreen, on first search
-- ---------------------------------------------------------------------
local function GhostIndexAll()
    if GS.indexed then return end
    GS.indexed = true
    local tree = C.CategoryTree
    if not tree then return end

    local catLabels = {}
    if C.Categories then
        for _, cat in ipairs(C.Categories) do
            catLabels[cat.key] = cat.label
        end
    end

    local bin = CreateFrame("Frame", nil, UIParent)
    bin:Hide()

    local function BuildOne(catKey, tabKey, tabLabel, globalName)
        local builder = _G[globalName]
        if not builder then return end
        W.SetBuildContext(catKey, catLabels[catKey] or catKey)
        if tabKey then W._SetBuildTab(tabKey, tabLabel) end
        local host = CreateFrame("Frame", nil, bin)
        host:SetSize(1000, 600)
        host:Hide()
        pcall(builder, host)
    end

    for catKey, tabs in pairs(tree) do
        for _, t in ipairs(tabs) do
            BuildOne(catKey, t.key, t.label, t.global)
        end
    end
    BuildOne("accueil", nil, nil, "TomoMod_ConfigPanel_Accueil")

    -- Neutralize the build context: the open page re-registers under its
    -- real location on its next rebuild (SwitchCategory resets it anyway)
    W.SetBuildContext(nil, nil)
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
    if entry.tab then C._pendingGroupTab = entry.tab end
    C.SwitchCategory(entry.cat)
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
    popup.empty:SetText(L["gs_no_results"] or "Aucune option correspondante")

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
function C.SubmitSearch()
    if lastResults and lastResults[1] and popup and popup:IsShown() then
        JumpTo(lastResults[1].e)
        return true
    end
    return false
end

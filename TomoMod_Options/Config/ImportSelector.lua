-- =====================================================================
-- ImportSelector.lua — Choosing what an import brings in (v4 Lot 7)
-- ---------------------------------------------------------------------
-- The visible half of lot 6. Core/SelectiveImport.lua decides what a
-- payload contains and what applying it would change; this decides
-- nothing, it only draws that and collects the ticks.
--
-- Nine collapsible groups, drill-down inside each (arbitration C). The
-- groups and their order come from the module registry, so nothing here
-- lists modules and nothing here can fall out of step with the
-- inventory.
--
-- Rows are pooled
-- ---------------
-- A full profile carries sixty-two modules, and the tree is rebuilt
-- every time the payload changes or a group is folded. WoW frames cannot
-- be destroyed, so building a fresh row each time would leak exactly the
-- way the config panels used to: quietly, and only noticeably after an
-- hour of fiddling. Rows are taken from a pool and handed back.
--
-- What a row has to show to be worth reading
-- ------------------------------------------
-- Everything in a profile looks importable until you know that three
-- modules out of sixty-two actually hold anything new. Rows that change
-- nothing are dimmed and unticked by default; rows that cost a reload
-- say so. The default selection is "only what changes", because that is
-- what someone pasting a friend's nameplate profile actually wants.
-- =====================================================================

local SI = TomoMod_SelectiveImport
local R  = TomoMod_Registry
if not SI or not R then return end

TomoMod_ImportSelector = TomoMod_ImportSelector or {}
local IS = TomoMod_ImportSelector

local L = TomoMod_L
local ACCENT = { 0.18, 0.85, 0.52 }

local ROW_H, GROUP_H, INDENT = 22, 26, 18

-- ---------------------------------------------------------------------
-- STATE
-- ---------------------------------------------------------------------

local dimmer, pop, scrollChild, summaryFS
local rowPool, groupPool = {}, {}
local usedRows, usedGroups = {}, {}

local groups          -- tree from SI.Inspect
local selected = {}   -- module key -> true
local collapsed = {}  -- group key -> true
local currentSettings
local onAccept

local function T(key, fallback)
    local v = L and L[key]
    -- The localisation metatable returns the raw key when it knows
    -- nothing, so an unresolved key would print as "imp_select_all".
    if not v or v == key then return fallback end
    return v
end

-- ---------------------------------------------------------------------
-- POOLS
-- ---------------------------------------------------------------------

local function ReleaseAll()
    for _, f in ipairs(usedRows) do
        f:Hide(); f:ClearAllPoints()
        rowPool[#rowPool + 1] = f
    end
    for _, f in ipairs(usedGroups) do
        f:Hide(); f:ClearAllPoints()
        groupPool[#groupPool + 1] = f
    end
    usedRows, usedGroups = {}, {}
end

local function AcquireRow()
    local f = table.remove(rowPool)
    if f then usedRows[#usedRows + 1] = f; return f end

    f = CreateFrame("Frame", nil, scrollChild)
    f:SetHeight(ROW_H)

    local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    cb:SetSize(20, 20)
    cb:SetPoint("LEFT", f, "LEFT", INDENT, 0)
    f.check = cb

    local name = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    name:SetJustifyH("LEFT")
    f.name = name

    local tag = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    tag:SetPoint("RIGHT", f, "RIGHT", -8, 0)
    tag:SetJustifyH("RIGHT")
    f.tag = tag

    usedRows[#usedRows + 1] = f
    return f
end

local function AcquireGroup()
    local f = table.remove(groupPool)
    if f then usedGroups[#usedGroups + 1] = f; return f end

    f = CreateFrame("Button", nil, scrollChild)
    f:SetHeight(GROUP_H)

    local arrow = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arrow:SetPoint("LEFT", f, "LEFT", 2, 0)
    f.arrow = arrow

    local name = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("LEFT", arrow, "RIGHT", 4, 0)
    name:SetTextColor(unpack(ACCENT))
    f.name = name

    local count = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    count:SetPoint("RIGHT", f, "RIGHT", -8, 0)
    f.count = count

    usedGroups[#usedGroups + 1] = f
    return f
end

-- ---------------------------------------------------------------------
-- RENDER
-- ---------------------------------------------------------------------

local Render   -- forward declaration: the handlers below re-enter it

local function UpdateSummary()
    if not summaryFS then return end
    local total, changed, reloads = SI.Summarize(groups, selected)
    summaryFS:SetText(string.format(
        T("imp_summary", "%d modules, %d changed, %d need a reload"),
        total, changed, reloads))
end

Render = function()
    ReleaseAll()
    local y = -4

    for _, g in ipairs(groups) do
        local gf = AcquireGroup()
        gf:SetParent(scrollChild)
        gf:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, y)
        gf:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

        local isCollapsed = collapsed[g.key]
        gf.arrow:SetText(isCollapsed and "+" or "-")
        gf.name:SetText(T(g.label, g.key))

        local picked, changed = 0, 0
        for _, row in ipairs(g.modules) do
            if selected[row.key] then picked = picked + 1 end
            if row.differs then changed = changed + 1 end
        end
        gf.count:SetText(("%d/%d  |cff888888%s %d|r"):format(
            picked, #g.modules, T("imp_changed", "changed"), changed))

        gf:SetScript("OnClick", function()
            collapsed[g.key] = not collapsed[g.key]
            Render()
        end)
        -- Right-click ticks or unticks a whole group: with nine groups
        -- and sixty-two modules, doing it row by row is the difference
        -- between usable and not.
        gf:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        gf:SetScript("OnMouseUp", function(_, button)
            if button ~= "RightButton" then return end
            local keys = SI.GroupKeys(groups, g.key)
            local allOn = true
            for _, k in ipairs(keys) do
                if not selected[k] then allOn = false break end
            end
            for _, k in ipairs(keys) do selected[k] = (not allOn) or nil end
            Render()
        end)
        gf:Show()
        y = y - GROUP_H

        if not isCollapsed then
            for _, row in ipairs(g.modules) do
                local rf = AcquireRow()
                rf:SetParent(scrollChild)
                rf:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, y)
                rf:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

                rf.name:SetText(T(row.label, row.key))
                if row.differs then
                    rf.name:SetTextColor(1, 1, 1, 1)
                    rf.tag:SetText(row.requiresReload and "|cffff8800/reload|r" or "")
                else
                    rf.name:SetTextColor(0.45, 0.45, 0.45, 1)
                    rf.tag:SetText("|cff555555" .. T("imp_unchanged", "identical") .. "|r")
                end

                rf.check:SetChecked(selected[row.key] and true or false)
                rf.check:SetScript("OnClick", function(btn)
                    selected[row.key] = btn:GetChecked() and true or nil
                    UpdateSummary()
                    -- Only the group counter needs redrawing, but a full
                    -- pass costs nothing now that rows are pooled.
                    Render()
                end)
                rf:Show()
                y = y - ROW_H
            end
        end
    end

    scrollChild:SetHeight(math.abs(y) + 10)
    UpdateSummary()
end

-- ---------------------------------------------------------------------
-- FRAME
-- ---------------------------------------------------------------------

local function Build()
    if pop then return end

    dimmer = CreateFrame("Frame", nil, UIParent)
    dimmer:SetAllPoints(UIParent)
    dimmer:SetFrameStrata("FULLSCREEN_DIALOG")
    dimmer:EnableMouse(true)
    dimmer:Hide()
    local bg = dimmer:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.6)

    pop = CreateFrame("Frame", "TomoModImportSelector", dimmer, "BackdropTemplate")
    pop:SetSize(520, 520)
    pop:SetPoint("CENTER")
    if pop.SetBackdrop then
        pop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
        })
        pop:SetBackdropColor(0.06, 0.06, 0.07, 0.97)
        pop:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.8)
    end

    local title = pop:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", pop, "TOPLEFT", 16, -14)
    title:SetText(T("imp_title", "Selective import"))
    title:SetTextColor(unpack(ACCENT))

    summaryFS = pop:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    summaryFS:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)

    local scroll = CreateFrame("ScrollFrame", nil, pop, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", pop, "TOPLEFT", 12, -56)
    scroll:SetPoint("BOTTOMRIGHT", pop, "BOTTOMRIGHT", -30, 84)

    scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(460, 10)
    scroll:SetScrollChild(scrollChild)

    local function MkBtn(text, w, anchorPoint, x, y, fn)
        local b = CreateFrame("Button", nil, pop, "UIPanelButtonTemplate")
        b:SetSize(w, 22)
        b:SetPoint(anchorPoint, pop, anchorPoint, x, y)
        b:SetText(text)
        b:SetScript("OnClick", fn)
        return b
    end

    MkBtn(T("imp_select_changed", "Only what changes"), 170, "BOTTOMLEFT", 16, 52, function()
        selected = {}
        for _, k in ipairs(SI.AllKeys(groups, true)) do selected[k] = true end
        Render()
    end)
    MkBtn(T("imp_select_all", "Select all"), 130, "BOTTOMLEFT", 194, 52, function()
        selected = {}
        for _, k in ipairs(SI.AllKeys(groups)) do selected[k] = true end
        Render()
    end)

    MkBtn(CANCEL or "Cancel", 110, "BOTTOMRIGHT", -16, 16, function()
        dimmer:Hide()
    end)
    MkBtn(ACCEPT or "Accept", 130, "BOTTOMRIGHT", -134, 16, function()
        local keys = {}
        for k in pairs(selected) do keys[#keys + 1] = k end
        table.sort(keys)
        dimmer:Hide()
        if #keys == 0 then
            print("|cff2ed884TomoMod|r " .. T("imp_nothing", "Nothing selected."))
            return
        end
        local report = SI.Apply(currentSettings, keys)
        print("|cff2ed884TomoMod|r " .. string.format(
            T("imp_applied", "%d modules imported"), report.applied))
        if onAccept then onAccept(report) end
    end)

    if TomoMod_Utils and TomoMod_Utils.CloseOnEscape then
        TomoMod_Utils.CloseOnEscape(pop, function() dimmer:Hide() end)
    end
    dimmer:SetScript("OnMouseDown", function(s)
        if not pop:IsMouseOver() then s:Hide() end
    end)
end

-- ---------------------------------------------------------------------
-- PUBLIC
-- ---------------------------------------------------------------------

--- Opens the selector for a decoded payload's settings table.
--- `cb` is called with the apply report once the player accepts.
function IS.Show(settings, cb)
    local tree, _, unknown = SI.Inspect(settings)
    if not tree or #tree == 0 then return false end

    Build()
    groups, currentSettings, onAccept = tree, settings, cb

    -- Default to what actually changes. Ticking all sixty-two modules by
    -- default would make the panel a formality, which is the behaviour it
    -- exists to replace.
    selected, collapsed = {}, {}
    for _, k in ipairs(SI.AllKeys(groups, true)) do selected[k] = true end

    if unknown and #unknown > 0 then
        print("|cff2ed884TomoMod|r |cffff8800"
            .. T("imp_unknown", "Unrecognised entries") .. "|r "
            .. table.concat(unknown, ", "))
    end

    Render()
    dimmer:Show()
    return true
end

--- Decode-and-show, for callers holding a raw import string.
function IS.ShowString(str, cb)
    local P = TomoMod_Profiles
    if not P or not P.DecodeImport then return false, "Profiles indisponible" end
    local payload, err = P.DecodeImport(str)
    if not payload then return false, err end
    return IS.Show(payload.settings, cb)
end

--- Pool figures, for the diagnostics panel.
function IS.PoolStats()
    return #rowPool, #groupPool, #usedRows, #usedGroups
end

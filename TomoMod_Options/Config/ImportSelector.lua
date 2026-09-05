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
local W = TomoMod_Widgets

-- The panel was the one piece of the v4 GUI that never went through
-- TomoMod_Widgets: Blizzard templates for the buttons, ticks and scrollbar,
-- Blizzard fonts, and an accent written in by hand. On a player who has
-- moved the suite off azure, the selector stayed blue while everything
-- around it did not. Everything visual now comes from W.Theme.
--
-- The fallbacks below are the shipped defaults, and exist so the file still
-- loads if Widgets.lua ever stops being a hard prerequisite -- the headless
-- bench relies on that too.
local TH = (W and W.Theme) or {}
local function Col(key, r, g, b, a)
    local c = TH[key]
    if type(c) == "table" and c[1] then return c end
    return { r, g, b, a or 1 }
end

local ACCENT    = Col("accent",     0.180, 0.616, 0.847)
local BG        = Col("bg",         0.070, 0.070, 0.090, 0.97)
local BG_LIGHT  = Col("bgLight",    0.110, 0.110, 0.140)
local BG_MID    = Col("bgMid",      0.090, 0.090, 0.115)
local BORDER    = Col("border",     0.180, 0.180, 0.220)
local TEXT      = Col("text",       0.880, 0.900, 0.890)
local TEXT_DIM  = Col("textDim",    0.480, 0.480, 0.540)
local YELLOW    = Col("yellow",     0.960, 0.800, 0.100)
local RED       = Col("red",        0.880, 0.220, 0.220)

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local WHITE8    = "Interface\\Buttons\\WHITE8X8"

-- Inline colour codes have to be hex strings, so they cannot read the theme
-- table directly. Built once from it instead of being typed in.
local function Hex(c)
    return ("|cff%02x%02x%02x"):format(
        math.floor((c[1] or 0) * 255 + 0.5),
        math.floor((c[2] or 0) * 255 + 0.5),
        math.floor((c[3] or 0) * 255 + 0.5))
end
local HEX_BRAND  = Hex(ACCENT)
local HEX_DIM    = Hex(TEXT_DIM)
local HEX_YELLOW = Hex(YELLOW)
local HEX_FAINT  = Hex({ TEXT_DIM[1] * 0.7, TEXT_DIM[2] * 0.7, TEXT_DIM[3] * 0.7 })

-- Small helper so every font string in the panel is declared the same way.
local function FS(parent, size, bold, color)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(bold and FONT_BOLD or FONT, size, "")
    fs:SetTextColor(unpack(color or TEXT))
    return fs
end

local ROW_H, GROUP_H, INDENT = 22, 26, 18

-- ---------------------------------------------------------------------
-- STATE
-- ---------------------------------------------------------------------

local dimmer, pop, scrollChild, summaryFS, destFS
local rowPool, groupPool = {}, {}
local usedRows, usedGroups = {}, {}

local groups          -- tree from SI.Inspect
local selected = {}   -- module key -> true
local collapsed = {}  -- group key -> true
local currentSettings
local onAccept
-- Name to freeze the result under once applied, or nil to leave the import
-- in the active configuration. Set per call, cleared on close: a stale name
-- would silently create a profile on the next import.
local destProfile

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

-- A themed tick, replacing the Blizzard check template. Keeps
-- SetChecked/GetChecked so the render pass below is unchanged, and stays a
-- Button so OnClick keeps working the way it did.
local function MakeCheck(parent)
    local cb = CreateFrame("Button", nil, parent, "BackdropTemplate")
    cb:SetSize(16, 16)
    if cb.SetBackdrop then
        cb:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
        cb:SetBackdropColor(BG_MID[1], BG_MID[2], BG_MID[3], 1)
        cb:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], 1)
    end

    local fill = cb:CreateTexture(nil, "OVERLAY")
    fill:SetPoint("TOPLEFT", 3, -3)
    fill:SetPoint("BOTTOMRIGHT", -3, 3)
    fill:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
    fill:Hide()

    function cb:SetChecked(v)
        self._checked = v and true or false
        if self._checked then fill:Show() else fill:Hide() end
        if self.SetBackdropBorderColor then
            local c = self._checked and ACCENT or BORDER
            self:SetBackdropBorderColor(c[1], c[2], c[3], 1)
        end
    end
    function cb:GetChecked() return self._checked end

    cb:SetScript("OnEnter", function(b)
        if b.SetBackdropBorderColor then
            b:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
        end
    end)
    cb:SetScript("OnLeave", function(b)
        if b.SetBackdropBorderColor then
            local c = b._checked and ACCENT or BORDER
            b:SetBackdropBorderColor(c[1], c[2], c[3], 1)
        end
    end)
    return cb
end

local function AcquireRow()
    local f = table.remove(rowPool)
    if f then usedRows[#usedRows + 1] = f; return f end

    f = CreateFrame("Frame", nil, scrollChild)
    f:SetHeight(ROW_H)

    local cb = MakeCheck(f)
    cb:SetPoint("LEFT", f, "LEFT", INDENT, 0)
    f.check = cb

    local name = FS(f, 11, false, TEXT)
    name:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    name:SetJustifyH("LEFT")
    f.name = name

    local tag = FS(f, 10, false, TEXT_DIM)
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

    -- A left accent bar, as on the section headers elsewhere in the config.
    local bar = f:CreateTexture(nil, "ARTWORK")
    bar:SetPoint("TOPLEFT", 0, -3)
    bar:SetPoint("BOTTOMLEFT", 0, 3)
    bar:SetWidth(2)
    bar:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)

    local arrow = FS(f, 12, true, ACCENT)
    arrow:SetPoint("LEFT", f, "LEFT", 8, 0)
    f.arrow = arrow

    local name = FS(f, 12, true, ACCENT)
    name:SetPoint("LEFT", arrow, "RIGHT", 5, 0)
    f.name = name

    local count = FS(f, 10, false, TEXT_DIM)
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
        gf.count:SetText(("%d/%d  " .. HEX_DIM .. "%s %d|r"):format(
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
                    rf.name:SetTextColor(unpack(TEXT))
                    rf.tag:SetText(row.requiresReload
                        and (HEX_YELLOW .. "/reload|r") or "")
                else
                    rf.name:SetTextColor(unpack(TEXT_DIM))
                    rf.tag:SetText(HEX_FAINT .. T("imp_unchanged", "identical") .. "|r")
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
    bg:SetColorTexture(0, 0, 0, 0.55)

    pop = CreateFrame("Frame", "TomoModImportSelector", dimmer, "BackdropTemplate")
    pop:SetSize(520, 520)
    pop:SetPoint("CENTER")
    if pop.SetBackdrop then
        pop:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
        pop:SetBackdropColor(BG[1], BG[2], BG[3], BG[4] or 0.97)
        pop:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.8)
    end

    -- Accent rule across the top, as on the import and export popups.
    local accentBar = pop:CreateTexture(nil, "OVERLAY")
    accentBar:SetHeight(2)
    accentBar:SetPoint("TOPLEFT")
    accentBar:SetPoint("TOPRIGHT")
    accentBar:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)

    local title = FS(pop, 15, true, ACCENT)
    title:SetPoint("TOPLEFT", pop, "TOPLEFT", 16, -16)
    title:SetText(T("imp_title", "Selective import"))

    summaryFS = FS(pop, 10, false, TEXT_DIM)
    summaryFS:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)

    -- Where the ticked modules land. Overwriting the live configuration and
    -- creating a named profile look identical once the panel is up, and only
    -- one of the two is reversible.
    destFS = FS(pop, 10, false, TEXT_DIM)
    destFS:SetPoint("TOPLEFT", summaryFS, "BOTTOMLEFT", 0, -3)

    -- The list sits in an inset well so the rows read as content rather than
    -- as floating text on the panel background.
    local well = CreateFrame("Frame", nil, pop, "BackdropTemplate")
    well:SetPoint("TOPLEFT", pop, "TOPLEFT", 14, -74)
    well:SetPoint("BOTTOMRIGHT", pop, "BOTTOMRIGHT", -14, 82)
    if well.SetBackdrop then
        well:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
        well:SetBackdropColor(BG_MID[1], BG_MID[2], BG_MID[3], 1)
        well:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], 1)
    end

    -- W.CreateScrollPanel fills its parent and brings the suite's slim
    -- accent scrollbar. The Blizzard template is kept as a fallback for the
    -- same reason as the colour fallbacks above.
    local scroll
    if W and W.CreateScrollPanel then
        scroll = W.CreateScrollPanel(well)
        scrollChild = scroll.child
    else
        scroll = CreateFrame("ScrollFrame", nil, well, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 4, -4)
        scroll:SetPoint("BOTTOMRIGHT", -20, 4)
        scrollChild = CreateFrame("Frame", nil, scroll)
        scrollChild:SetSize(460, 10)
        scroll:SetScrollChild(scrollChild)
    end

    -- Themed button: solid dim accent, inverting to full accent on hover,
    -- matching the import and export popups.
    local function MkBtn(text, w, anchorPoint, x, y, fn, danger)
        local tone = danger and RED or ACCENT
        local b = CreateFrame("Button", nil, pop, "BackdropTemplate")
        b:SetSize(w, 24)
        b:SetPoint(anchorPoint, pop, anchorPoint, x, y)
        if b.SetBackdrop then
            b:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
            b:SetBackdropColor(tone[1] * 0.20, tone[2] * 0.20, tone[3] * 0.20, 0.9)
            b:SetBackdropBorderColor(tone[1], tone[2], tone[3], 1)
        end
        local lbl = FS(b, 11, true, tone)
        lbl:SetPoint("CENTER")
        lbl:SetText(text)
        b:SetScript("OnEnter", function(s2)
            if s2.SetBackdropColor then
                s2:SetBackdropColor(tone[1], tone[2], tone[3], 1)
            end
            lbl:SetTextColor(BG[1], BG[2], BG[3], 1)
        end)
        b:SetScript("OnLeave", function(s2)
            if s2.SetBackdropColor then
                s2:SetBackdropColor(tone[1] * 0.20, tone[2] * 0.20, tone[3] * 0.20, 0.9)
            end
            lbl:SetTextColor(unpack(tone))
        end)
        b:SetScript("OnClick", fn)
        return b
    end

    MkBtn(T("imp_select_changed", "Only what changes"), 170, "BOTTOMLEFT", 16, 50, function()
        selected = {}
        for _, k in ipairs(SI.AllKeys(groups, true)) do selected[k] = true end
        Render()
    end)
    MkBtn(T("imp_select_all", "Select all"), 130, "BOTTOMLEFT", 194, 50, function()
        selected = {}
        for _, k in ipairs(SI.AllKeys(groups)) do selected[k] = true end
        Render()
    end)

    MkBtn(CANCEL or "Cancel", 110, "BOTTOMRIGHT", -16, 16, function()
        dimmer:Hide()
    end, true)
    MkBtn(ACCEPT or "Accept", 130, "BOTTOMRIGHT", -134, 16, function()
        local keys = {}
        for k in pairs(selected) do keys[#keys + 1] = k end
        table.sort(keys)
        -- Read the destination BEFORE hiding: the OnHide hook below clears it
        -- so a cancelled run cannot leak a name into the next import.
        local dest = destProfile
        dimmer:Hide()
        if #keys == 0 then
            print(HEX_BRAND .. "TomoMod|r " .. T("imp_nothing", "Nothing selected."))
            return
        end
        local report = SI.Apply(currentSettings, keys)
        print(HEX_BRAND .. "TomoMod|r " .. string.format(
            T("imp_applied", "%d modules imported"), report.applied))

        -- SI.Apply has written the selection into the live configuration.
        -- Freezing it under a name is the same two-step the non-selective
        -- named import already performs, so both routes leave the same state.
        if dest then
            local Prof = TomoMod_Profiles
            if Prof and Prof.SaveActiveAs then
                local okSave = Prof.SaveActiveAs(dest)
                if okSave then
                    print(HEX_BRAND .. "TomoMod|r " .. string.format(
                        T("imp_saved_as", "Saved as profile '%s'"), dest))
                end
            end
        end

        if onAccept then onAccept(report) end
    end)

    -- Covers cancel, Escape, click-outside AND the accept path in one place.
    -- The accept handler has already taken its copy by the time this fires.
    dimmer:HookScript("OnHide", function() destProfile = nil end)

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
--- `opts.profileName` freezes the result under that name instead of leaving
--- it in the active configuration.
function IS.Show(settings, cb, opts)
    local tree, _, unknown = SI.Inspect(settings)
    if not tree or #tree == 0 then
        return false, T("imp_no_modules", "No recognised module in this string")
    end

    Build()
    groups, currentSettings, onAccept = tree, settings, cb

    local name = opts and opts.profileName
    if type(name) == "string" then name = name:match("^%s*(.-)%s*$") end
    destProfile = (type(name) == "string" and name ~= "") and name or nil

    if destProfile then
        destFS:SetText(string.format(
            T("imp_dest_profile", "Destination: new profile '%s'"), destProfile))
    else
        destFS:SetText(T("imp_dest_active", "Destination: active configuration (overwritten)"))
    end

    -- Default to what actually changes. Ticking all sixty-two modules by
    -- default would make the panel a formality, which is the behaviour it
    -- exists to replace.
    selected, collapsed = {}, {}
    for _, k in ipairs(SI.AllKeys(groups, true)) do selected[k] = true end

    if unknown and #unknown > 0 then
        print(HEX_BRAND .. "TomoMod|r " .. HEX_YELLOW
            .. T("imp_unknown", "Unrecognised entries") .. "|r "
            .. table.concat(unknown, ", "))
    end

    Render()

    -- The config window sits at FULLSCREEN_DIALOG with a high frame level,
    -- so declaring the same strata is not enough: the selector opened
    -- BEHIND it and looked like nothing had happened. The import popup in
    -- Panels/Profiles.lua already raises itself this way.
    --
    -- Done here rather than in Build(): the panel is built once and reused,
    -- and the level to clear depends on what is on screen at the moment it
    -- opens, not on what was there the first time.
    local U = TomoMod_Utils
    if U and U.RaiseAboveTomoUI then
        U.RaiseAboveTomoUI(dimmer)
        -- Children do not follow a parent's level reliably once they have
        -- been created, so the popup is re-based off the dimmer explicitly.
        pop:SetFrameStrata("FULLSCREEN_DIALOG")
        pop:SetFrameLevel((dimmer:GetFrameLevel() or 0) + 10)
    end

    dimmer:Show()
    return true
end

--- Decode-and-show, for callers holding a raw import string.
function IS.ShowString(str, cb, opts)
    local P = TomoMod_Profiles
    if not P or not P.DecodeImport then return false, "Profiles indisponible" end

    -- The preview already decoded this exact string a moment ago and kept
    -- the payload. Decoding it a second time here doubled the wait for
    -- nothing; the cache was built for this and had no caller.
    local payload = P.TakeDecodedPayload and P.TakeDecodedPayload(str) or nil
    local err
    if not payload then
        payload, err = P.DecodeImport(str)
        if not payload then return false, err end
    end
    return IS.Show(payload.settings, cb, opts)
end

--- Pool figures, for the diagnostics panel.
function IS.PoolStats()
    return #rowPool, #groupPool, #usedRows, #usedGroups
end

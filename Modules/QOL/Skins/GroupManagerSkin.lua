-- =====================================
-- GroupManagerSkin.lua
-- Full reskin of Blizzard's "CompactRaidFrameManager" — the group-leader
-- toolbar docked to the left edge of the screen (mode dropdown, member
-- count, role/group filters, edit mode, settings, ready check, role poll,
-- countdown, raid target markers, ping restriction, leave group/instance).
--
-- ElvUI-style approach: strip Blizzard's decorative chrome (backgrounds,
-- borders, plates, dropdown/toggle art) down to flat dark slots with 1px
-- borders and the TomoMod mint accent, while KEEPING every functional
-- glyph (toolbar icons, raid marker textures) fully intact. Interactive
-- state (hover / pressed / selected / applied / disabled / active tab) is
-- reflected on our own slots by shadowing the exact texture the engine
-- drives, so the reskin never fights Blizzard's own updates.
--
-- Non-destructive & reversible: everything we hide is tracked and can be
-- restored live (config toggle) without a reload; every hook no-ops while
-- the skin is inactive. Colours come from the single BRAND source of truth
-- in Core/Utils.lua (U.BRAND / U.BRAND_HOVER / U.BRAND_DARK).
--
-- Setting: TomoModDB.raidFrames.skinGroupManager (unchanged)
-- Compatible with WoW 12.x (TWW / Midnight)
-- =====================================

TomoMod_GroupManagerSkin = TomoMod_GroupManagerSkin or {}
local GMS = TomoMod_GroupManagerSkin

-- =====================================
-- LOCALS, FONTS & PALETTE
-- =====================================

local U = TomoMod_Utils or {}

local FONT       = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"

-- Single source of truth for the accent (with defensive fallbacks in case
-- Core/Utils.lua load order ever changes — it currently loads first).
local BRAND       = U.BRAND       or { 0.180, 0.616, 0.847 }
local BRAND_HOVER = U.BRAND_HOVER or { 0.373, 0.737, 0.941 }
local BRAND_DARK  = U.BRAND_DARK  or { 0.110, 0.373, 0.541 }

-- Dark theme surfaces (match the rest of TomoMod's skins)
local BG_PANEL    = { 0.055, 0.059, 0.075, 0.96 } -- outer card
local BG_SLOT     = { 0.078, 0.086, 0.106, 1 }    -- button / control slot
local BG_INSET    = { 0.063, 0.070, 0.094, 1 }    -- sub-panel (marker body)
local BD_SLOT     = { 0.137, 0.149, 0.176, 1 }    -- slot border
local BD_INSET    = { 0.118, 0.129, 0.157, 1 }    -- sub-panel border
local BD_PANEL_A  = 0.35                           -- accent border alpha (card / toggle)
local HAIRLINE_A  = 0.07
local TEXT_LIGHT  = { 0.89, 0.91, 0.925 }
local TEXT_MUTE   = { 0.54, 0.57, 0.61 }

-- Danger styling for the leave-group buttons
local DANGER      = { 0.886, 0.294, 0.290 }
local DANGER_TX   = { 0.94, 0.647, 0.647 }
local DANGER_BD_A = 0.55

local isInitialized = false
GMS._active = false -- whether the skin is currently applied (guards every hook)

-- Toggle registries (plain arrays: all anchored to the persistent manager,
-- so no GC concern; deterministic iteration on enable/disable).
local overlays    = {} -- { o = frame/texture, cond = bool }
local killed      = {} -- Blizzard textures we forced to alpha 0
local refreshers  = {} -- callbacks re-run on enable (e.g. active-tab underline)

local restyledFonts = setmetatable({}, { __mode = "k" })

-- =====================================
-- SETTINGS
-- =====================================

local function IsEnabled()
    local db = TomoModDB and TomoModDB.raidFrames
    return db and db.skinGroupManager
end

-- =====================================
-- TRACKING HELPERS
-- =====================================

local function trackOverlay(o, cond)
    if o then overlays[#overlays + 1] = { o = o, cond = cond and true or false } end
    return o
end

local function killTexture(tex)
    if not tex or tex._tmKilled then return end
    tex._tmKilled = true
    pcall(tex.SetAlpha, tex, 0)
    killed[#killed + 1] = tex
end

local function setBorders(borders, r, g, b, a)
    for i = 1, #borders do
        borders[i]:SetColorTexture(r, g, b, a or 1)
    end
end

-- Add a flat slot (bg + 1px border) as TEXTURES on a button, drawn behind
-- the button's own glyph/text. Returns { bg = , borders = { t, b, l, r } }.
local function AddSlotTextures(btn, inset)
    if btn._tmSlot then return btn._tmSlot end
    inset = inset or 0

    local bg = btn:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetPoint("TOPLEFT", inset, -inset)
    bg:SetPoint("BOTTOMRIGHT", -inset, inset)
    bg:SetColorTexture(BG_SLOT[1], BG_SLOT[2], BG_SLOT[3], BG_SLOT[4])
    trackOverlay(bg, false)

    local function edge()
        local t = btn:CreateTexture(nil, "BACKGROUND", nil, -7)
        t:SetColorTexture(BD_SLOT[1], BD_SLOT[2], BD_SLOT[3], BD_SLOT[4])
        trackOverlay(t, false)
        return t
    end

    local top = edge(); top:SetHeight(1); top:SetPoint("TOPLEFT", bg, "TOPLEFT"); top:SetPoint("TOPRIGHT", bg, "TOPRIGHT")
    local bot = edge(); bot:SetHeight(1); bot:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT"); bot:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT")
    local lft = edge(); lft:SetWidth(1);  lft:SetPoint("TOPLEFT", bg, "TOPLEFT"); lft:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT")
    local rgt = edge(); rgt:SetWidth(1);  rgt:SetPoint("TOPRIGHT", bg, "TOPRIGHT"); rgt:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT")

    local slot = { bg = bg, borders = { top, bot, lft, rgt } }
    btn._tmSlot = slot
    return slot
end

-- Backdrop card (frame) for panel / sub-panel chrome.
local function CreateCard(parent, refRegion, bgColor, bdColor)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    if refRegion then card:SetAllPoints(refRegion) else card:SetAllPoints(parent) end
    card:SetFrameLevel(math.max(0, (parent:GetFrameLevel() or 1) - 1))
    card:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    card:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
    card:SetBackdropBorderColor(bdColor[1], bdColor[2], bdColor[3], bdColor[4] or 1)
    return card
end

local function RestyleFonts(frame, depth)
    if not frame then return end
    depth = depth or 0
    if depth > 6 then return end

    if frame.GetRegions then
        for _, r in pairs({ frame:GetRegions() }) do
            if r.IsObjectType and r:IsObjectType("FontString") and not restyledFonts[r] then
                restyledFonts[r] = true
                local _, size, flags = r:GetFont()
                pcall(function() r:SetFont(FONT, size or 12, flags) end)
            end
        end
    end
    if frame.GetChildren then
        for _, c in pairs({ frame:GetChildren() }) do
            RestyleFonts(c, depth + 1)
        end
    end
end

-- =====================================
-- OUTER CARD + BACKGROUND
-- =====================================

local function SkinManagerCard(manager)
    if not manager._tmCard then
        -- Parent the card to displayFrame, NOT the manager. Blizzard hides
        -- displayFrame when the panel is collapsed (and moves the manager
        -- off-screen), so a card anchored to the manager left its right edge
        -- poking out as a full-height strip. Parenting to displayFrame makes
        -- the card follow the panel's shown/hidden state automatically — the
        -- collapsed strip disappears with zero extra hooks.
        local host = manager.displayFrame or manager
        local card = CreateFrame("Frame", nil, host, "BackdropTemplate")
        card:SetPoint("TOPLEFT", host, "TOPLEFT", -4, 4)
        card:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 4, -4)
        card:SetFrameStrata(host:GetFrameStrata())
        card:SetFrameLevel(math.max(0, (host:GetFrameLevel() or 1) - 1))
        card:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        card:SetBackdropColor(BG_PANEL[1], BG_PANEL[2], BG_PANEL[3], BG_PANEL[4])
        card:SetBackdropBorderColor(BRAND[1], BRAND[2], BRAND[3], BD_PANEL_A)

        local strip = card:CreateTexture(nil, "OVERLAY", nil, 6)
        strip:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 1)
        strip:SetHeight(2)
        strip:SetPoint("TOPLEFT", 1, -1)
        strip:SetPoint("TOPRIGHT", -1, -1)

        manager._tmCard = card
        trackOverlay(card, false)
    end

    -- Kill the Blizzard "GM-bgOpen-*" atlas behind the panel. SetAtlas never
    -- restores alpha, so a single zero persists across Blizzard's re-atlasing.
    if manager.Background then killTexture(manager.Background) end
end

-- =====================================
-- SIDE TOGGLE (expand / collapse handle)
-- =====================================

local function SkinToggleButton(btn)
    if not btn or btn._tmSkinned then return end
    btn._tmSkinned = true

    -- Keep the directional arrow (it IS the NormalTexture) but tint it mint;
    -- the mixin only ever swaps its atlas, never its vertex colour.
    local nt = btn.GetNormalTexture and btn:GetNormalTexture()
    if nt then pcall(nt.SetVertexColor, nt, BRAND[1], BRAND[2], BRAND[3]) end

    if btn.GetPushedTexture then local t = btn:GetPushedTexture(); if t then killTexture(t) end end
    if btn.GetDisabledTexture then local t = btn:GetDisabledTexture(); if t then killTexture(t) end end
    if btn.GetHighlightTexture then local t = btn:GetHighlightTexture(); if t then killTexture(t) end end

    local slot = AddSlotTextures(btn, 0)
    setBorders(slot.borders, BRAND[1], BRAND[2], BRAND[3], BD_PANEL_A)
end

-- =====================================
-- COLLAPSED HANDLE → beveled pull-tab (drawn, BRAND-driven)
-- Replaces the forward toggle's look with a compact dark tab pinned to the
-- screen edge that stretches to the RIGHT (dark gradient body + mint accent
-- on the open edge + mint arrow). The tab is parented to the forward toggle,
-- so it shows/hides with the collapsed state automatically — no extra hooks.
-- (WoW can't cut transparent corners without a shaped texture, so the edges
--  are crisp/flat rather than a literal diagonal chamfer.)
-- =====================================

local function SkinCollapseTab(fwd)
    if not fwd or fwd._tmTab then return end
    fwd._tmTab = true

    -- Hide the forward toggle's own art; we redraw the indicator on the tab.
    for _, fn in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture" }) do
        local t = fwd[fn] and fwd[fn](fwd)
        if t then killTexture(t) end
    end

    local TAB_W, TAB_H = 26, 72

    local tab = CreateFrame("Button", nil, fwd)
    tab:SetSize(TAB_W, TAB_H)
    tab:SetPoint("LEFT", fwd, "LEFT", -2, 0) -- flush to the screen edge, stretching right
    tab:SetFrameLevel((fwd:GetFrameLevel() or 1) + 1)
    tab:SetScript("OnClick", function()
        if CompactRaidFrameManager_Toggle then CompactRaidFrameManager_Toggle() end
    end)

    -- Body: dark, subtle top->bottom gradient.
    local body = tab:CreateTexture(nil, "BACKGROUND", nil, -2)
    body:SetAllPoints()
    body:SetColorTexture(1, 1, 1, 1)
    if body.SetGradient and CreateColor then
        pcall(body.SetGradient, body, "VERTICAL",
            CreateColor(BG_INSET[1], BG_INSET[2], BG_INSET[3], 0.97),
            CreateColor(0.11, 0.12, 0.145, 0.97))
    else
        body:SetColorTexture(BG_SLOT[1], BG_SLOT[2], BG_SLOT[3], 0.97)
    end
    trackOverlay(body, false)

    -- Hover wash (mint).
    local hov = tab:CreateTexture(nil, "BACKGROUND", nil, -1)
    hov:SetAllPoints()
    hov:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 0.10)
    hov:Hide()
    trackOverlay(hov, true)

    -- 1px top / bottom borders.
    local top = tab:CreateTexture(nil, "BORDER", nil, 1)
    top:SetColorTexture(BD_SLOT[1], BD_SLOT[2], BD_SLOT[3], 1)
    top:SetHeight(1); top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT")
    trackOverlay(top, false)

    local bot = tab:CreateTexture(nil, "BORDER", nil, 1)
    bot:SetColorTexture(BD_SLOT[1], BD_SLOT[2], BD_SLOT[3], 1)
    bot:SetHeight(1); bot:SetPoint("BOTTOMLEFT"); bot:SetPoint("BOTTOMRIGHT")
    trackOverlay(bot, false)

    -- Mint accent stripe on the RIGHT edge (the open side facing the panel).
    local accent = tab:CreateTexture(nil, "OVERLAY", nil, 2)
    accent:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 1)
    accent:SetWidth(2)
    accent:SetPoint("TOPRIGHT"); accent:SetPoint("BOTTOMRIGHT")
    trackOverlay(accent, false)

    -- Mint arrow indicator (Blizzard's own forward/expand atlas), centered.
    local arrow = tab:CreateTexture(nil, "OVERLAY", nil, 3)
    pcall(arrow.SetAtlas, arrow, "gm-btnforward-normal")
    arrow:SetSize(11, 22)
    arrow:SetPoint("CENTER", tab, "CENTER", 1, 0)
    pcall(arrow.SetVertexColor, arrow, BRAND[1], BRAND[2], BRAND[3])
    trackOverlay(arrow, false)

    tab:HookScript("OnEnter", function()
        if not GMS._active then return end
        hov:Show()
        pcall(arrow.SetVertexColor, arrow, BRAND_HOVER[1], BRAND_HOVER[2], BRAND_HOVER[3])
    end)
    tab:HookScript("OnLeave", function()
        if not GMS._active then return end
        hov:Hide()
        pcall(arrow.SetVertexColor, arrow, BRAND[1], BRAND[2], BRAND[3])
    end)

    fwd._tmTabFrame = tab
end

-- =====================================
-- TOOLBAR ICON BUTTONS
-- (edit mode, settings, hide toggle, everyone-assist, difficulty, ready
--  check, role poll, countdown) — the glyph is the NormalTexture driven by
--  the engine, so we only add a slot BEHIND it and react to hover.
-- =====================================

local function SkinToolbarButton(btn)
    if not btn or btn._tmSkinned then return end
    btn._tmSkinned = true

    local slot = AddSlotTextures(btn, 0)
    setBorders(slot.borders, BD_SLOT[1], BD_SLOT[2], BD_SLOT[3], 1)

    btn:HookScript("OnEnter", function()
        if not GMS._active then return end
        setBorders(slot.borders, BRAND[1], BRAND[2], BRAND[3], 1)
    end)
    btn:HookScript("OnLeave", function()
        if not GMS._active then return end
        setBorders(slot.borders, BD_SLOT[1], BD_SLOT[2], BD_SLOT[3], 1)
    end)
end

-- =====================================
-- FILTER BUTTONS (role tank/heal/dps + group 1..8)
-- State is driven via NormalTexture:SetAtlas("common-button-tertiary-*").
-- We shadow that single call to recolour our slot; the count/number text
-- and role-icon markup stay untouched.
-- =====================================

local function SkinFilterButton(btn)
    if not btn or btn._tmSkinned then return end
    btn._tmSkinned = true

    local nt = btn.GetNormalTexture and btn:GetNormalTexture()
    if nt then killTexture(nt) end

    local slot = AddSlotTextures(btn, 1)

    local function paint(atlas)
        if atlas and atlas:find("selected") then
            setBorders(slot.borders, BRAND[1], BRAND[2], BRAND[3], 1)
            slot.bg:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 0.12)
        elseif atlas and atlas:find("hover") then
            setBorders(slot.borders, BRAND_HOVER[1], BRAND_HOVER[2], BRAND_HOVER[3], 1)
            slot.bg:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 0.06)
        else
            setBorders(slot.borders, BD_SLOT[1], BD_SLOT[2], BD_SLOT[3], 1)
            slot.bg:SetColorTexture(BG_SLOT[1], BG_SLOT[2], BG_SLOT[3], 1)
        end
    end

    paint(nil)
    if nt then
        pcall(hooksecurefunc, nt, "SetAtlas", function(_, atlas)
            if GMS._active then paint(atlas) end
        end)
    end

    local fs = btn.GetFontString and btn:GetFontString()
    if fs then
        local _, size, flags = fs:GetFont()
        pcall(function() fs:SetFont(FONT, size or 11, flags) end)
    end
end

-- =====================================
-- RAID MARKER BUTTONS
-- backgroundTexture is swapped through a full state machine
-- (available/hover/pressed/selected/applied/appliedSelected/disabled).
-- We hide it and mirror those states on our slot; the marker glyph
-- (skull, cross, ...) and Blizzard's desaturation are preserved.
-- =====================================

local MARKER_STATE = {
    ["GM-button-marker-available"]       = "normal",
    ["GM-button-marker-hover"]           = "hover",
    ["GM-button-marker-pressed"]         = "pressed",
    ["GM-button-marker-selected"]        = "selected",
    ["GM-button-marker-applied"]         = "applied",
    ["GM-button-marker-appliedSelected"] = "appliedSelected",
    ["GM-button-marker-disabled"]        = "disabled",
}

local function paintMarker(slot, state)
    if state == "hover" then
        setBorders(slot.borders, BRAND_HOVER[1], BRAND_HOVER[2], BRAND_HOVER[3], 1)
        slot.bg:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 0.12)
    elseif state == "pressed" then
        setBorders(slot.borders, BRAND_DARK[1], BRAND_DARK[2], BRAND_DARK[3], 1)
        slot.bg:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 0.18)
    elseif state == "selected" then
        setBorders(slot.borders, BRAND[1], BRAND[2], BRAND[3], 1)
        slot.bg:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 0.10)
    elseif state == "applied" then
        setBorders(slot.borders, BRAND[1], BRAND[2], BRAND[3], 1)
        slot.bg:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 0.16)
    elseif state == "appliedSelected" then
        setBorders(slot.borders, BRAND_HOVER[1], BRAND_HOVER[2], BRAND_HOVER[3], 1)
        slot.bg:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 0.22)
    elseif state == "disabled" then
        setBorders(slot.borders, BD_SLOT[1], BD_SLOT[2], BD_SLOT[3], 0.5)
        slot.bg:SetColorTexture(BG_SLOT[1], BG_SLOT[2], BG_SLOT[3], 0.5)
    else
        setBorders(slot.borders, BD_SLOT[1], BD_SLOT[2], BD_SLOT[3], 1)
        slot.bg:SetColorTexture(BG_SLOT[1], BG_SLOT[2], BG_SLOT[3], 1)
    end
end

local function SkinMarkerButton(btn)
    if not btn or btn._tmSkinned then return end
    btn._tmSkinned = true

    local bgTex = btn.backgroundTexture
    if bgTex then killTexture(bgTex) end

    local slot = AddSlotTextures(btn, 2)
    paintMarker(slot, "normal")

    if bgTex then
        pcall(hooksecurefunc, bgTex, "SetAtlas", function(_, atlas)
            if not GMS._active then return end
            local st = atlas and MARKER_STATE[atlas]
            if st then paintMarker(slot, st) end
        end)
    end
end

local function SkinMarkers(manager)
    local pool = manager.raidMarkerPool
    if pool and pool.EnumerateActive then
        for btn in pool:EnumerateActive() do
            SkinMarkerButton(btn)
        end
    end
end

-- =====================================
-- MARKER TABS ("Unit" / "Ground") + their body panel
-- =====================================

local function SkinMarkerTabs(raidMarkers)
    if not raidMarkers or raidMarkers._tmSkinned then return end
    raidMarkers._tmSkinned = true

    -- Replace the "GM-tab-body" background with our sub-panel card.
    if raidMarkers.BG then
        killTexture(raidMarkers.BG)
        local card = CreateCard(raidMarkers, raidMarkers.BG, BG_INSET, BD_INSET)
        trackOverlay(card, false)
    end

    local tabs = raidMarkers.Tabs
    if not tabs then return end

    for _, tab in ipairs(tabs) do
        local nt = tab.GetNormalTexture and tab:GetNormalTexture()
        if nt then killTexture(nt) end

        local bg = tab:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetAllPoints()
        bg:SetColorTexture(BG_INSET[1], BG_INSET[2], BG_INSET[3], 1)
        trackOverlay(bg, false)

        local ul = tab:CreateTexture(nil, "OVERLAY", nil, 2)
        ul:SetHeight(2)
        ul:SetPoint("BOTTOMLEFT")
        ul:SetPoint("BOTTOMRIGHT")
        ul:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 1)
        ul:Hide()
        trackOverlay(ul, true)
        tab._tmUnderline = ul

        local fs = tab.GetFontString and tab:GetFontString()
        if fs then
            local _, size, flags = fs:GetFont()
            pcall(function() fs:SetFont(FONT, size or 11, flags) end)
        end
    end

    local function refreshTabs()
        for _, tab in ipairs(tabs) do
            if tab._tmUnderline then
                if raidMarkers.activeTab == tab then tab._tmUnderline:Show() else tab._tmUnderline:Hide() end
            end
        end
    end

    pcall(hooksecurefunc, raidMarkers, "SetTab", function()
        if GMS._active then refreshTabs() end
    end)
    refreshers[#refreshers + 1] = refreshTabs
    refreshTabs()
end

-- =====================================
-- DROPDOWNS (mode control + restrict pings) — WowStyle1 template
-- =====================================

local function SkinDropdown(dd)
    if not dd or dd._tmSkinned then return end
    dd._tmSkinned = true

    if dd.Background then killTexture(dd.Background) end
    -- Keep the arrow, tint it mint (mixin only swaps its atlas).
    if dd.Arrow then pcall(dd.Arrow.SetVertexColor, dd.Arrow, BRAND[1], BRAND[2], BRAND[3]) end

    local slot = AddSlotTextures(dd, 0)
    setBorders(slot.borders, BD_SLOT[1], BD_SLOT[2], BD_SLOT[3], 1)

    if dd.Text then
        local _, size, flags = dd.Text:GetFont()
        pcall(function() dd.Text:SetFont(FONT, size or 12, flags) end)
        pcall(dd.Text.SetJustifyH, dd.Text, "LEFT")
    end

    dd:HookScript("OnEnter", function()
        if not GMS._active then return end
        setBorders(slot.borders, BRAND[1], BRAND[2], BRAND[3], 1)
    end)
    dd:HookScript("OnLeave", function()
        if not GMS._active then return end
        setBorders(slot.borders, BD_SLOT[1], BD_SLOT[2], BD_SLOT[3], 1)
    end)
end

-- =====================================
-- LEAVE GROUP / LEAVE INSTANCE BUTTONS (danger styling)
-- =====================================

local function SkinLeaveButton(btn)
    if not btn or btn._tmSkinned then return end
    btn._tmSkinned = true

    -- Strip the UIPanelButtonTemplate plate (textures only, keep the label).
    if btn.GetRegions then
        for _, r in pairs({ btn:GetRegions() }) do
            if r.IsObjectType and r:IsObjectType("Texture") then killTexture(r) end
        end
    end
    if btn.GetHighlightTexture then local h = btn:GetHighlightTexture(); if h then killTexture(h) end end

    local slot = AddSlotTextures(btn, 0)
    setBorders(slot.borders, DANGER[1], DANGER[2], DANGER[3], DANGER_BD_A)
    slot.bg:SetColorTexture(BG_SLOT[1], BG_SLOT[2], BG_SLOT[3], 1)

    local hov = btn:CreateTexture(nil, "BACKGROUND", nil, -6)
    hov:SetPoint("TOPLEFT", 1, -1)
    hov:SetPoint("BOTTOMRIGHT", -1, 1)
    hov:SetColorTexture(DANGER[1], DANGER[2], DANGER[3], 0.12)
    hov:Hide()
    trackOverlay(hov, true)

    btn:HookScript("OnEnter", function()
        if not GMS._active then return end
        hov:Show()
        setBorders(slot.borders, DANGER[1], DANGER[2], DANGER[3], 0.9)
    end)
    btn:HookScript("OnLeave", function()
        if not GMS._active then return end
        hov:Hide()
        setBorders(slot.borders, DANGER[1], DANGER[2], DANGER[3], DANGER_BD_A)
    end)

    local fs = btn.GetFontString and btn:GetFontString()
    if fs then
        local _, size, flags = fs:GetFont()
        pcall(function() fs:SetFont(FONT, size or 12, flags) end)
        pcall(fs.SetTextColor, fs, DANGER_TX[1], DANGER_TX[2], DANGER_TX[3])
    end
end

-- =====================================
-- DIVIDERS (transient, pooled) — hidden while the skin is active; restored
-- naturally when the skin is turned off.
-- =====================================

local function setDividerAlpha(a)
    local m = CompactRaidFrameManager
    if not m then return end
    for _, pool in ipairs({ m.dividerVerticalPool, m.dividerHorizontalPool }) do
        if pool and pool.EnumerateActive then
            for tex in pool:EnumerateActive() do
                pcall(tex.SetAlpha, tex, a)
            end
        end
    end
end

-- =====================================
-- VISIBILITY / LIVE TOGGLE
-- =====================================

function GMS.SetVisible(show)
    for i = 1, #overlays do
        local e = overlays[i]
        local o = e.o
        if o then
            if show then
                if e.cond then
                    if o.Hide then o:Hide() end -- reset; refreshers re-show as needed
                else
                    if o.Show then o:Show() end
                end
            else
                if o.Hide then o:Hide() end
            end
        end
    end

    for i = 1, #killed do
        local t = killed[i]
        if t and t.SetAlpha then pcall(t.SetAlpha, t, show and 0 or 1) end
    end

    setDividerAlpha(show and 0 or 1)

    if show then
        for i = 1, #refreshers do pcall(refreshers[i]) end
    end
end

-- =====================================
-- MAIN: apply the reskin
-- =====================================

function GMS.ApplySkin()
    if not IsEnabled() then return end
    local m = CompactRaidFrameManager
    if not m then return end

    GMS._active = true

    SkinManagerCard(m)
    SkinCollapseTab(m.toggleButtonForward)  -- collapsed: mint pull-tab, stretches right
    SkinToggleButton(m.toggleButtonBack)    -- expanded: mint collapse handle

    local df = m.displayFrame
    if df then
        SkinDropdown(df.ModeControlDropdown)
        SkinDropdown(df.RestrictPingsDropdown)

        local toolbar = { "editMode", "settings", "hiddenModeToggle", "everyoneIsAssistButton",
                          "difficulty", "readyCheckButton", "rolePollButton", "countdownButton" }
        for _, key in ipairs(toolbar) do
            SkinToolbarButton(df[key])
        end

        local fo = df.filterOptions
        if fo then
            SkinFilterButton(fo.filterRoleTank)
            SkinFilterButton(fo.filterRoleHealer)
            SkinFilterButton(fo.filterRoleDamager)
            if fo.filterGroupButtons then
                for _, b in ipairs(fo.filterGroupButtons) do
                    SkinFilterButton(b)
                end
            end
        end

        if df.raidMarkers then
            SkinMarkerTabs(df.raidMarkers)
            SkinMarkers(m)
        end

        RestyleFonts(df)
        if df.label then df.label:SetTextColor(TEXT_LIGHT[1], TEXT_LIGHT[2], TEXT_LIGHT[3]) end
        if df.memberCountLabel then df.memberCountLabel:SetTextColor(BRAND[1], BRAND[2], BRAND[3]) end
        if df.RestrictPingsLabel then df.RestrictPingsLabel:SetTextColor(TEXT_MUTE[1], TEXT_MUTE[2], TEXT_MUTE[3]) end
    end

    if m.BottomButtons and m.BottomButtons.GetChildren then
        for _, child in pairs({ m.BottomButtons:GetChildren() }) do
            if child.GetObjectType and child:GetObjectType() == "Button" then
                SkinLeaveButton(child)
            end
        end
    end

    GMS.SetVisible(true)
end

-- =====================================
-- SETTINGS / LIFECYCLE
-- =====================================

function GMS.ApplySettings()
    if IsEnabled() then
        GMS._active = true
        GMS.ApplySkin()
        GMS.SetVisible(true)
    else
        GMS._active = false
        GMS.SetVisible(false)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:SetScript("OnEvent", function()
    if not isInitialized then return end
    C_Timer.After(0.5, GMS.ApplySkin)
end)

function GMS.Initialize()
    if isInitialized then return end
    isInitialized = true

    local manager = CompactRaidFrameManager
    if manager then
        manager:HookScript("OnShow", function()
            C_Timer.After(0, GMS.ApplySkin)
        end)

        -- Keep the pooled dividers hidden as the flow container re-lays out
        -- (fires on roster changes, incl. in combat — cosmetic & cheap).
        if _G.CompactRaidFrameManager_UpdateOptionsFlowContainer then
            hooksecurefunc("CompactRaidFrameManager_UpdateOptionsFlowContainer", function()
                if GMS._active then setDividerAlpha(0) end
            end)
        end
    end

    C_Timer.After(0.5, GMS.ApplySkin)
end

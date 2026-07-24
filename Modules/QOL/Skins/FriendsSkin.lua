-- =====================================
-- FriendsSkin.lua
-- Full reskin of Blizzard's Friends / Contacts window (FriendsFrame) in the
-- TomoMod dark + mint theme: flat panel, 1px accent border, restyled bottom
-- tabs and sub-tabs, and one shared flat button treatment for every control
-- in the window (Add Friend, Send Message, Who, Convert to Raid, Raid Info,
-- Join Queue), plus the Who column headers and search box.
--
-- Scope is deliberately cosmetic. Blizzard's geometry is left untouched: no
-- frame resize, no ScrollBox reanchoring, no reparenting. The single layout
-- change is an even split of the two contact buttons across the bottom row,
-- which preserves their original vertical offset. Nothing functional is
-- rebuilt — lists, dropdowns, tooltips and handlers all stay native.
--
-- Hover and selected states are engine-driven wherever possible (HIGHLIGHT
-- draw-layer textures and font objects) instead of OnEnter/OnLeave scripts,
-- so the skin runs no code of its own inside a Blizzard interaction path —
-- notably on the Raid tab, whose buttons reach protected group APIs.
--
-- Reversible: every Blizzard region we remove is dimmed with SetAlpha(0) and
-- tracked with its previous alpha, never destroyed with SetTexture(nil), so
-- the config toggle restores the native look live. Fonts are the exception
-- and need a reload to revert.
--
-- Setting: TomoModDB.friendsSkin { enabled, scale }
-- Compatible with WoW 12.x (TWW / Midnight)
-- =====================================

TomoMod_FriendsSkin = TomoMod_FriendsSkin or {}
local FS = TomoMod_FriendsSkin

-- =====================================
-- LOCALS, FONTS & PALETTE
-- =====================================

local U = TomoMod_Utils or {}

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

-- Single source of truth for the accent (defensive fallbacks in case the
-- Core/Utils.lua load order ever changes — it currently loads first).
local BRAND       = U.BRAND       or { 0.180, 0.847, 0.518 }
local BRAND_HOVER = U.BRAND_HOVER or { 0.322, 0.941, 0.651 }

-- Dark surfaces (match the rest of TomoMod's skins)
local PANEL_BG    = { 0.043, 0.047, 0.061, 0.97 } -- window body
local INSET_BG    = { 0.063, 0.070, 0.090, 1 }    -- list / who panes
local INSET_BD    = { 0.137, 0.149, 0.176, 1 }    -- inset border
local BTN_BG      = { 0.078, 0.086, 0.106, 1 }    -- button slot
local TAB_BG      = { 0.055, 0.059, 0.075, 1 }    -- inactive bottom tab
local EDIT_BG     = { 0.031, 0.035, 0.047, 1 }    -- search box

local PANEL_BD_A  = 0.55  -- window border accent alpha
local BTN_BD_A    = 0.45  -- button border accent alpha
local BTN_HL_A    = 0.90  -- button border alpha while hovered
local BTN_HL_BG_A = 0.07  -- button fill alpha while hovered
local HAIRLINE_A  = 0.07  -- title divider / tab separators

local TEXT_TITLE  = { 0.88, 0.90, 0.92, 1 }
local TEXT_DIM    = { 0.60, 0.64, 0.68, 1 }
local TEXT_MUTE   = { 0.45, 0.48, 0.52, 1 }

local BTN_H = 22 -- height used when re-flowing the two contact buttons

-- Shared font objects. Buttons drive normal / hovered / disabled label colours
-- through these, so no OnEnter or OnLeave script is needed on any of them.
local BTN_FONT = CreateFont("TomoModFriendsButtonFont")
BTN_FONT:SetFont(FONT, 11, "")
BTN_FONT:SetTextColor(BRAND[1], BRAND[2], BRAND[3], 0.80)

local BTN_FONT_HL = CreateFont("TomoModFriendsButtonFontHighlight")
BTN_FONT_HL:SetFont(FONT, 11, "")
BTN_FONT_HL:SetTextColor(BRAND_HOVER[1], BRAND_HOVER[2], BRAND_HOVER[3], 1)

local BTN_FONT_DIS = CreateFont("TomoModFriendsButtonFontDisabled")
BTN_FONT_DIS:SetFont(FONT, 11, "")
BTN_FONT_DIS:SetTextColor(TEXT_MUTE[1], TEXT_MUTE[2], TEXT_MUTE[3], 0.70)

local isInitialized = false
FS._active = false

-- Structural passes already completed (each retried until its frame exists,
-- since some sub-panes are created later than FriendsFrame itself).
local done = {}

-- Toggle registries. Everything is anchored to the persistent FriendsFrame,
-- so plain arrays are fine and give deterministic iteration on enable.
local overlays = {} -- { o = texture/frame, state = bool }  our own artwork
local killed   = {} -- { o = region, a = previous alpha }   Blizzard artwork
local refreshers = {} -- callbacks re-run when the skin is switched back on

-- =====================================
-- SETTINGS
-- =====================================

local function GetSettings()
    local db = _G.TomoModDB
    return (db and db.friendsSkin) or {}
end

local function IsEnabled()
    return GetSettings().enabled == true
end

-- =====================================
-- TRACKING HELPERS
-- =====================================

-- Our own artwork. state = true marks a region whose visibility is driven by
-- selection state (tab underlines), so re-enabling refreshes it instead of
-- blindly showing it.
local function Track(o, state)
    if o then overlays[#overlays + 1] = { o = o, state = state and true or false } end
    return o
end

-- Blizzard artwork: dimmed, never destroyed, so it can be restored live.
local function Kill(o)
    if not o or o._tmFsMine or o._tmFsKilled then return o end
    if not o.SetAlpha then return o end
    o._tmFsKilled = true
    killed[#killed + 1] = { o = o, a = o:GetAlpha() or 1 }
    o:SetAlpha(0)
    return o
end

local function StripTextures(frame)
    if not frame or not frame.GetRegions then return end
    for _, region in pairs({ frame:GetRegions() }) do
        if region.IsObjectType and region:IsObjectType("Texture") then
            Kill(region)
        end
    end
end

-- Every named chrome piece Blizzard's portrait-frame templates may expose.
local CHROME_KEYS = {
    "Bg", "TitleBg", "TopTileStreaks", "PortraitContainer", "portrait",
    "PortraitFrame", "ArtOverlayFrame", "TopBorder", "TopLeftCorner",
    "TopRightCorner", "LeftBorder", "RightBorder", "BottomBorder",
    "BottomLeftCorner", "BottomRightCorner", "BtnCornerLeft", "BtnCornerRight",
}

local function KillChrome(frame)
    if not frame then return end
    if frame.NineSlice then
        StripTextures(frame.NineSlice)
        Kill(frame.NineSlice)
    end
    for _, key in ipairs(CHROME_KEYS) do
        Kill(frame[key])
    end
end

-- =====================================
-- DRAWING HELPERS
-- =====================================

local function NewTexture(parent, layer, sublevel)
    local tex
    if layer == "HIGHLIGHT" then
        tex = parent:CreateTexture(nil, "HIGHLIGHT")
    else
        tex = parent:CreateTexture(nil, layer, nil, sublevel)
    end
    tex._tmFsMine = true
    return tex
end

local function AddFill(parent, layer, sublevel, color, alpha)
    local tex = NewTexture(parent, layer, sublevel)
    tex:SetAllPoints(parent)
    tex:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
    return Track(tex)
end

-- Four 1px edges drawn as textures. Cheaper and far more predictable than a
-- backdrop, and works on any region layer including HIGHLIGHT.
local function AddEdges(parent, layer, sublevel, color, alpha)
    local function edge()
        local tex = NewTexture(parent, layer, sublevel)
        tex:SetColorTexture(color[1], color[2], color[3], alpha or 1)
        return Track(tex)
    end

    local top = edge(); top:SetHeight(1)
    top:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)

    local bot = edge(); bot:SetHeight(1)
    bot:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    bot:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    local lft = edge(); lft:SetWidth(1)
    lft:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -1)
    lft:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 1)

    local rgt = edge(); rgt:SetWidth(1)
    rgt:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -1)
    rgt:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 1)

    return { top, bot, lft, rgt }
end

-- =====================================
-- BUTTON TREATMENT
-- =====================================

local BUTTON_ART_KEYS = {
    "Left", "Middle", "Right",
    "LeftDisabled", "MiddleDisabled", "RightDisabled",
    "LeftSeparator", "RightSeparator", "Border", "Background",
}

local BUTTON_TEX_GETTERS = {
    "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture",
    "GetDisabledTexture",
}

-- Flat slot + accent border + engine-driven hover. Used for every button in
-- the window so Add Friend, Who and Raid Info all read identically.
local function SkinButton(btn)
    if not btn or btn._tmFsButton then return end
    btn._tmFsButton = true

    StripTextures(btn)
    for _, key in ipairs(BUTTON_ART_KEYS) do
        Kill(btn[key])
    end
    for _, getter in ipairs(BUTTON_TEX_GETTERS) do
        if btn[getter] then Kill(btn[getter](btn)) end
    end

    AddFill(btn, "BACKGROUND", -8, BTN_BG)
    AddEdges(btn, "BACKGROUND", -7, BRAND, BTN_BD_A)

    -- HIGHLIGHT layer is shown by the engine on mouseover: no scripts needed.
    AddFill(btn, "HIGHLIGHT", nil, BRAND, BTN_HL_BG_A)
    AddEdges(btn, "HIGHLIGHT", nil, BRAND_HOVER, BTN_HL_A)

    if btn.SetNormalFontObject   then btn:SetNormalFontObject(BTN_FONT) end
    if btn.SetHighlightFontObject then btn:SetHighlightFontObject(BTN_FONT_HL) end
    if btn.SetDisabledFontObject then btn:SetDisabledFontObject(BTN_FONT_DIS) end
    if btn.SetPushedTextOffset   then btn:SetPushedTextOffset(0, 0) end
end

-- =====================================
-- WINDOW CHROME
-- =====================================

local function SkinWindow()
    local frame = _G.FriendsFrame
    if not frame then return false end

    StripTextures(frame)
    KillChrome(frame)
    Kill(_G.FriendsFramePortrait)
    Kill(_G.FriendsFrameIcon)

    if frame.TitleContainer then StripTextures(frame.TitleContainer) end

    AddFill(frame, "BACKGROUND", -8, PANEL_BG)

    -- Border lives on its own frame above the content so the list never
    -- draws over it, which a plain backdrop on FriendsFrame would allow.
    local border = CreateFrame("Frame", nil, frame)
    border:SetAllPoints(frame)
    border:SetFrameLevel(frame:GetFrameLevel() + 20)
    border._tmFsMine = true
    AddEdges(border, "OVERLAY", 7, BRAND, PANEL_BD_A)
    Track(border)

    -- Title: keep Blizzard's own localized label, restyle it in place.
    local title = (frame.TitleContainer and (frame.TitleContainer.TitleText
                   or frame.TitleContainer:GetFontString()))
                  or _G.FriendsFrameTitleText
    if title and title.SetFont then
        title:SetFont(FONT_BOLD, 13, "")
        title:SetTextColor(TEXT_TITLE[1], TEXT_TITLE[2], TEXT_TITLE[3], TEXT_TITLE[4])
    end

    -- Hairline under the title bar.
    local div = NewTexture(frame, "OVERLAY", 1)
    div:SetHeight(1)
    div:SetColorTexture(1, 1, 1, HAIRLINE_A)
    div:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -30)
    div:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -30)
    Track(div)

    -- Close button: plain accent "x", the one place a script is worth it.
    local closeBtn = frame.CloseButton or _G.FriendsFrameCloseButton
    if closeBtn and not closeBtn._tmFsClose then
        closeBtn._tmFsClose = true
        StripTextures(closeBtn)
        for _, getter in ipairs(BUTTON_TEX_GETTERS) do
            if closeBtn[getter] then Kill(closeBtn[getter](closeBtn)) end
        end
        local x = closeBtn:CreateFontString(nil, "OVERLAY")
        x._tmFsMine = true
        x:SetFont(FONT_BOLD, 15, "")
        x:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
        x:SetText("x")
        x:SetTextColor(TEXT_DIM[1], TEXT_DIM[2], TEXT_DIM[3], 1)
        Track(x)
        closeBtn:HookScript("OnEnter", function()
            if not FS._active then return end
            x:SetTextColor(BRAND_HOVER[1], BRAND_HOVER[2], BRAND_HOVER[3], 1)
        end)
        closeBtn:HookScript("OnLeave", function()
            if not FS._active then return end
            x:SetTextColor(TEXT_DIM[1], TEXT_DIM[2], TEXT_DIM[3], 1)
        end)
    end

    -- Popups anchored to this window would otherwise sit under our border
    -- frame; raising their strata avoids reparenting them.
    if frame.IgnoreListWindow then frame.IgnoreListWindow:SetFrameStrata("DIALOG") end
    if _G.RaidInfoFrame then _G.RaidInfoFrame:SetFrameStrata("DIALOG") end
    if _G.FriendsTooltip then _G.FriendsTooltip:SetFrameStrata("TOOLTIP") end

    return true
end

-- =====================================
-- INSET PANES
-- =====================================

local function SkinInset(inset)
    if not inset or inset._tmFsInset then return end
    inset._tmFsInset = true

    StripTextures(inset)
    if inset.NineSlice then
        StripTextures(inset.NineSlice)
        Kill(inset.NineSlice)
    end
    Kill(inset.Bg)
    for _, key in ipairs({
        "InsetBorderTop", "InsetBorderTopLeft", "InsetBorderTopRight",
        "InsetBorderBottom", "InsetBorderBottomLeft", "InsetBorderBottomRight",
        "InsetBorderLeft", "InsetBorderRight",
    }) do
        Kill(inset[key])
    end

    AddFill(inset, "BACKGROUND", -7, INSET_BG)
    AddEdges(inset, "BACKGROUND", -6, INSET_BD, 1)
end

local function SkinInsets()
    local frame = _G.FriendsFrame
    if not frame then return false end

    SkinInset(frame.Inset)
    for _, name in ipairs({
        "FriendsFrameInset", "WhoFrameListInset", "RaidFrameInset",
        "QuickJoinFrameInset",
    }) do
        SkinInset(_G[name])
    end
    return true
end

-- =====================================
-- BOTTOM TABS
-- =====================================

local bottomTabs = {}

-- PanelTemplates disables the selected tab, so IsEnabled() is a reliable and
-- entirely passive way to read the current selection.
local function IsTabSelected(tab)
    return tab.IsEnabled and not tab:IsEnabled()
end

local function RefreshBottomTabs()
    for i = 1, #bottomTabs do
        local tab = bottomTabs[i]
        local selected = IsTabSelected(tab)
        if tab._tmFsLabel then
            if selected then
                tab._tmFsLabel:SetTextColor(BRAND[1], BRAND[2], BRAND[3], 1)
            else
                tab._tmFsLabel:SetTextColor(TEXT_DIM[1], TEXT_DIM[2], TEXT_DIM[3], 1)
            end
        end
        if tab._tmFsUnderline then
            tab._tmFsUnderline:SetShown(FS._active and selected)
        end
    end
end

local function SkinBottomTabs()
    local frame = _G.FriendsFrame
    if not frame then return false end

    local count = frame.numTabs or 4
    for i = 1, count do
        local tab = _G["FriendsFrameTab" .. i]
        if tab and not tab._tmFsTab then
            tab._tmFsTab = true

            StripTextures(tab)
            for _, key in ipairs({
                "Left", "Middle", "Right",
                "LeftDisabled", "MiddleDisabled", "RightDisabled",
                "LeftHighlight", "MiddleHighlight", "RightHighlight",
            }) do
                Kill(tab[key])
            end
            for _, getter in ipairs(BUTTON_TEX_GETTERS) do
                if tab[getter] then Kill(tab[getter](tab)) end
            end

            AddFill(tab, "BACKGROUND", -8, TAB_BG)
            AddFill(tab, "HIGHLIGHT", nil, BRAND, 0.06)

            local label = tab.Text or (tab.GetFontString and tab:GetFontString())
            if label and label.SetFont then
                label:SetFont(FONT, 11, "")
                tab._tmFsLabel = label
            end

            local underline = NewTexture(tab, "OVERLAY", 6)
            underline:SetHeight(2)
            underline:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 1)
            underline:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 4, 2)
            underline:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -4, 2)
            underline:Hide()
            tab._tmFsUnderline = Track(underline, true)

            -- Selection changes always go through Enable / Disable, so this
            -- catches every path without hooking a global function.
            hooksecurefunc(tab, "Enable", RefreshBottomTabs)
            hooksecurefunc(tab, "Disable", RefreshBottomTabs)

            bottomTabs[#bottomTabs + 1] = tab
        end
    end

    return #bottomTabs > 0
end

-- =====================================
-- SUB-TABS (Friends / Recent Allies / Recruit A Friend)
-- =====================================

local subTabs = {}

local function RefreshSubTabs()
    for i = 1, #subTabs do
        local tab = subTabs[i]
        local selected = IsTabSelected(tab)
        if tab._tmFsLabel then
            if selected then
                tab._tmFsLabel:SetTextColor(BRAND[1], BRAND[2], BRAND[3], 1)
            else
                tab._tmFsLabel:SetTextColor(TEXT_DIM[1], TEXT_DIM[2], TEXT_DIM[3], 1)
            end
        end
        if tab._tmFsUnderline then
            tab._tmFsUnderline:SetShown(FS._active and selected)
        end
    end
end

local function SkinSubTabs()
    local header = _G.FriendsTabHeader
    local system = header and header.TabSystem
    if not system then return false end

    StripTextures(header)
    StripTextures(system)

    for i = 1, select("#", system:GetChildren()) do
        local tab = select(i, system:GetChildren())
        if tab and tab.IsObjectType and tab:IsObjectType("Button") and not tab._tmFsSubTab then
            tab._tmFsSubTab = true

            StripTextures(tab)
            for _, key in ipairs({ "Left", "Middle", "Right", "Background" }) do
                Kill(tab[key])
            end
            for _, getter in ipairs(BUTTON_TEX_GETTERS) do
                if tab[getter] then Kill(tab[getter](tab)) end
            end

            AddFill(tab, "HIGHLIGHT", nil, BRAND, 0.06)

            local label = tab.Text or (tab.GetFontString and tab:GetFontString())
            if label and label.SetFont then
                label:SetFont(FONT, 11, "")
                tab._tmFsLabel = label
            end

            local underline = NewTexture(tab, "OVERLAY", 6)
            underline:SetHeight(2)
            underline:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 1)
            underline:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 2, 1)
            underline:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -2, 1)
            underline:Hide()
            tab._tmFsUnderline = Track(underline, true)

            if tab.Enable then hooksecurefunc(tab, "Enable", RefreshSubTabs) end
            if tab.Disable then hooksecurefunc(tab, "Disable", RefreshSubTabs) end

            subTabs[#subTabs + 1] = tab
        end
    end

    return #subTabs > 0
end

-- =====================================
-- CONTACT BUTTONS (bottom row)
-- =====================================

local contactRowY -- original vertical offset, captured before we move anything

local function LayoutContactButtons()
    if InCombatLockdown() then return end
    local frame = _G.FriendsFrame
    local add = _G.FriendsFrameAddFriendButton
    local msg = _G.FriendsFrameSendMessageButton
    if not (frame and add and msg) then return end

    -- Preserve Blizzard's own vertical placement: only the horizontal split
    -- changes, so the bottom row keeps its original relationship to the list.
    if not contactRowY then
        local btnBottom, frameBottom = add:GetBottom(), frame:GetBottom()
        if not (btnBottom and frameBottom) then return end
        contactRowY = math.floor(btnBottom - frameBottom + 0.5)
    end

    local pad, gap = 12, 6
    local width = math.floor((frame:GetWidth() - pad * 2 - gap) / 2)
    if width < 40 then return end

    add:ClearAllPoints()
    add:SetSize(width, BTN_H)
    add:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", pad, contactRowY)

    msg:ClearAllPoints()
    msg:SetSize(width, BTN_H)
    msg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -pad, contactRowY)
end

local function SkinContactButtons()
    local add = _G.FriendsFrameAddFriendButton
    local msg = _G.FriendsFrameSendMessageButton
    if not (add and msg) then return false end

    SkinButton(add)
    SkinButton(msg)
    return true
end

-- =====================================
-- WHO TAB
-- =====================================

local function SkinWhoTab()
    local who = _G.WhoFrame
    if not who then return false end

    for _, name in ipairs({
        "WhoFrameWhoButton", "WhoFrameAddFriendButton", "WhoFrameGroupInviteButton",
    }) do
        SkinButton(_G[name])
    end

    -- Sortable column headers: flat, dimmed, with an engine-driven hover and
    -- a 1px separator between each.
    for i = 1, 4 do
        local col = _G["WhoFrameColumnHeader" .. i]
        if col and not col._tmFsColumn then
            col._tmFsColumn = true
            StripTextures(col)
            for _, getter in ipairs(BUTTON_TEX_GETTERS) do
                if col[getter] then Kill(col[getter](col)) end
            end

            local label = col.GetFontString and col:GetFontString()
            if label and label.SetFont then
                label:SetFont(FONT, 10, "")
                label:SetTextColor(TEXT_DIM[1], TEXT_DIM[2], TEXT_DIM[3], 1)
            end

            AddFill(col, "HIGHLIGHT", nil, BRAND, 0.08)

            if i > 1 then
                local sep = NewTexture(col, "OVERLAY", 2)
                sep:SetWidth(1)
                sep:SetColorTexture(1, 1, 1, HAIRLINE_A)
                sep:SetPoint("TOPLEFT", col, "TOPLEFT", 0, -3)
                sep:SetPoint("BOTTOMLEFT", col, "BOTTOMLEFT", 0, 3)
                Track(sep)
            end
        end
    end

    local editBox = _G.WhoFrameEditBox
    if editBox and not editBox._tmFsEdit then
        editBox._tmFsEdit = true
        StripTextures(editBox)
        AddFill(editBox, "BACKGROUND", -7, EDIT_BG)
        AddEdges(editBox, "BACKGROUND", -6, INSET_BD, 1)
        if editBox.SetTextColor then editBox:SetTextColor(0.88, 0.90, 0.92, 1) end
    end

    local totals = _G.WhoFrameTotals
    if totals and totals.SetFont then
        totals:SetFont(FONT, 10, "")
        totals:SetTextColor(TEXT_DIM[1], TEXT_DIM[2], TEXT_DIM[3], 1)
    end

    return true
end

-- =====================================
-- RAID & QUICK JOIN TABS
-- =====================================

local function SkinRaidTab()
    local raid = _G.RaidFrame
    if not raid then return false end
    -- Purely texture and font-object work: nothing of ours executes when
    -- these buttons reach Blizzard's protected group APIs.
    SkinButton(_G.RaidFrameConvertToRaidButton)
    SkinButton(_G.RaidFrameRaidInfoButton)
    return true
end

local function SkinQuickJoinTab()
    local qj = _G.QuickJoinFrame
    if not qj then return false end
    SkinButton(qj.JoinQueueButton)
    return true
end

-- =====================================
-- ENABLE / DISABLE
-- =====================================

function FS.SetVisible(show)
    FS._active = show and true or false

    for i = 1, #overlays do
        local entry = overlays[i]
        if show then
            if not entry.state then entry.o:Show() end
        else
            entry.o:Hide()
        end
    end

    for i = 1, #killed do
        local entry = killed[i]
        entry.o:SetAlpha(show and 0 or entry.a)
    end

    for i = 1, #refreshers do
        refreshers[i]()
    end
end

refreshers[1] = RefreshBottomTabs
refreshers[2] = RefreshSubTabs

-- =====================================
-- PUBLIC API
-- =====================================

local function RunPass(key, fn)
    if done[key] then return end
    if fn() then done[key] = true end
end

function FS.ApplyScale()
    local frame = _G.FriendsFrame
    if not frame then return end
    local scale = tonumber(GetSettings().scale) or 1
    if not IsEnabled() then scale = 1 end
    if scale > 0 then frame:SetScale(scale) end
end

function FS.ApplySkin()
    if not IsEnabled() then return end
    if not _G.FriendsFrame then return end

    RunPass("window",   SkinWindow)
    RunPass("insets",   SkinInsets)
    RunPass("bottom",   SkinBottomTabs)
    RunPass("subtabs",  SkinSubTabs)
    RunPass("contacts", SkinContactButtons)
    RunPass("who",      SkinWhoTab)
    RunPass("raid",     SkinRaidTab)
    RunPass("quickjoin", SkinQuickJoinTab)

    -- Not a one-shot pass: GetBottom() returns nothing on a frame that has
    -- never been displayed, so the row offset may only become readable on a
    -- later call. Idempotent once captured.
    LayoutContactButtons()

    FS.SetVisible(true)
    FS.ApplyScale()
end

-- Entry point for the config panel: handles both directions of the toggle.
function FS.ApplySettings()
    if IsEnabled() then
        FS.ApplySkin() -- applies the scale itself
    else
        if FS._active then FS.SetVisible(false) end
        FS.ApplyScale() -- back to 1.0 while the skin is off
    end
end

-- =====================================
-- INITIALIZATION
-- =====================================

function FS.Initialize()
    if isInitialized then return end
    isInitialized = true

    local function hookWhenReady()
        local frame = _G.FriendsFrame
        if not frame then return false end
        frame:HookScript("OnShow", function()
            FS.ApplySettings()
            -- Second pass once Blizzard's own update has run, to catch panes
            -- created on first display (Recent Allies, Quick Join...).
            if C_Timer and C_Timer.After then
                C_Timer.After(0, FS.ApplySettings)
            end
        end)
        FS.ApplySettings()
        return true
    end

    if not hookWhenReady() then
        -- Blizzard_FriendsFrame is load-on-demand: wait for it.
        local waiter = CreateFrame("Frame")
        waiter:RegisterEvent("ADDON_LOADED")
        waiter:SetScript("OnEvent", function(self, _, name)
            if name == "Blizzard_FriendsFrame" or _G.FriendsFrame then
                if hookWhenReady() then self:UnregisterAllEvents() end
            end
        end)
    end
end

-- Self-initialize once the addon environment is up.
local _initFrame = CreateFrame("Frame")
_initFrame:RegisterEvent("PLAYER_LOGIN")
_initFrame:SetScript("OnEvent", function() FS.Initialize() end)

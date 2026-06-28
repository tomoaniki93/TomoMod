-- ============================================================
-- WhatsNew.lua — "What's New" popup after addon updates
-- Compares TomoModDB.lastSeenVersion with current version.
-- Shown once per version on PLAYER_LOGIN via C_Timer.After.
-- ============================================================

TomoMod_WhatsNew = TomoMod_WhatsNew or {}
local WN = TomoMod_WhatsNew
local L  = TomoMod_L

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local LOGO_TEX  = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Logo.tga"

-- Palette (matches Installer)
local A  = { TomoMod_Utils.BRAND[1], TomoMod_Utils.BRAND[2], TomoMod_Utils.BRAND[3] }
local BG = { 0.07,  0.07,  0.09,  0.98 }
local BD = { 0.18,  0.18,  0.22,  1    }
local TX = { 0.88,  0.90,  0.89,  1    }
local DM = { 0.48,  0.48,  0.54,  1    }

local PANEL_W = 520
local PANEL_H = 480

-- ============================================================
-- CHANGELOG DATA
-- Each version entry: { title = "...", highlights = { "...", ... } }
-- Only keep the last few versions to avoid bloating memory.
-- ============================================================

local CHANGELOG = {
    {
        version = "3.1.3",
        highlights = {
            L["wn_313_nav"]        or "Config UI redesigned: 16 panels consolidated into 6 grouped categories (Interface, Units, Combat, Comfort, Tools), each with its own accent color and a page header.",
            L["wn_313_accent"]     or "Widgets now auto-adopt the accent color of their host panel — cards, headers, separators, checkboxes, buttons and tabs all react to the active category context.",
            L["wn_313_segmented"]  or "New SegmentedControl widget replaces short dropdowns (Bag Bar, Micro Menu, Chat Skin, Bag Layout, Sort, Audio Channel).",
            L["wn_313_dashboard"]  or "Accueil dashboard rewritten: hero banner with live diagnostics status, quick-action shortcuts (Forge, Profiles, Diagnostics, Reload) and redesigned module toggles.",
            L["wn_313_np_preview"] or "Nameplates: new live preview panel at the top of the config — shows ally, hostile and boss plates, updates in real-time as you adjust width, height, cast bar and font size.",
            L["wn_313_loot_filter"] or "Loot class filter fix: items missing from the IDB (e.g. new raid drops) now fall back to armor-type matching instead of being shown for all classes.",
            L["wn_313_sporefall"]   or "Loot data: Sporefall raid (ejEncounterID 2711) added with 15 items from KeystoneLoot build 12.0.7.",
            L["wn_313_diag"]       or "Diagnostics: 7 new UIError exclusion keywords + console now always appears above the config menu.",
        },
    },
    {
        version = "3.1.2",
        highlights = {
            L["wn_312_brand"]         or "Brand color updated from #0cd29f to #2ed884 (mint green) across the entire UI — title bar, panels, chat messages, popups and default color values.",
            L["wn_312_brand_api"]     or "New TomoMod_Utils.BRAND / BRAND_DARK / BRAND_HOVER constants centralise the accent color: Config panels and the Widget theme now read from a single source of truth.",
            L["wn_312_companion_fix"] or "CompanionStatus: fixed a global variable leak (UpdateIcon was declared without 'local').",
        },
    },
    {
        version = "3.1.1",
        highlights = {
            L["wn_311_icicles"]      or "Frost Mage: new Icicles tracker in the Resource Bar (5 segments + Glacial Spike glow when full). Custom color available in CD & Resource → Colors.",
            L["wn_311_taint_money"]  or "Fixed a Midnight taint error: hovering items in the Encounter Journal no longer throws a 'secret number' error on the gold value — TomoMod no longer taints item-comparison tooltips.",
            L["wn_311_art_qty"]      or "AuctionRecipeTracker: clicking a reagent searches the Auction House and shows the required quantity in the status bar (e.g. Searching: Awakened Fire × 14).",
        },
    },
    {
        version = "3.1.0",
        highlights = {
            L["wn_310_brez_counter"] or "New movable Battle Rez counter: shows how many combat resurrections are left and the time until the next charge (reads the shared pool, so it works on any class).",
            L["wn_310_resurrect"]    or "New resurrection indicator on party and raid frames: a rez icon appears on a member while a resurrection is being cast on them.",
            L["wn_310_raid_sizes"]   or "Raid frames can now use per-size layouts (10 / 25 / 40): frame width and height adapt automatically to the current group size.",
            L["wn_310_brez_fix"]     or "Fixed the party-frame battle rez cooldown: the icon now greys out and shows the recharge timer correctly whenever a brez is consumed.",
        },
    },
    {
        version = "3.0.7",
        highlights = {
            L["wn_307_objective_tracker"],
            L["wn_307_guardian_rage"],
            L["wn_307_resource_bars"],
        },
    },
    {
        version = "3.0.6",
        highlights = {
            L["wn_306_extra_button"],
            L["wn_306_extra_mover"],
            L["wn_306_extra_scale"],
            L["wn_306_compass"],
            L["wn_306_bagskin"],
        },
    },
    {
        version = "3.0.5",
        highlights = {
            L["wn_305_rare_alert"],
            L["wn_305_rare_alert_marker"],
            L["wn_305_tm_fix"],
        },
    },
    {
        version = "3.0.4",
        highlights = {
            L["wn_304_consumable_bar"],
            L["wn_304_cursor_textures"],
            L["wn_304_mythichub_tp"],
        },
    },
    {
        version = "3.0.3",
        highlights = {
            L["wn_303_tracking_panel"],
            L["wn_303_collector_panel"],
            L["wn_303_collector_autoclose"],
            L["wn_303_tooltip_fix"],
            L["wn_303_coords_pos"],
        },
    },
    {
        version = "3.0.2",
        highlights = {
            L["wn_302_collector_capture"],
            L["wn_302_collector_clean"],
            L["wn_302_collector_poll"],
            L["wn_302_native_choice"],
        },
    },
    {
        version = "3.0.1",
        highlights = {
            L["wn_301_locale_fix"],
            L["wn_301_combat_movers"],
            L["wn_301_procglow_taint"],
            L["wn_301_ground_speed"],
            L["wn_301_buttonbag_clock"],
        },
    },
    {
        version = "3.0.0",
        highlights = {
            L["wn_300_installer"],
            L["wn_300_presets"],
            L["wn_300_dashboard"],
            L["wn_300_search"],
            L["wn_300_minimap"],
            L["wn_300_buttonbag"],
        },
    },
    {
        version = "2.9.21",
        highlights = {
            L["wn_2921_aura_mover"],
            L["wn_2921_aura_gui"],
            L["wn_2921_reload_safety"],
            L["wn_2921_waypoint_arrow"],
        },
    },
    {
        version = "2.9.20",
        highlights = {
            L["wn_2920_waypoint_redirect"],
            L["wn_2920_waypoint_blob"],
            L["wn_2920_waypoint_label"],
        },
    },
    {
        version = "2.9.19",
        highlights = {
            L["wn_2919_antiflicker"],
            L["wn_2919_collapsed_persist"],
            L["wn_2919_header_detection"],
            L["wn_2919_recipe_height"],
            L["wn_2919_reward_preview"],
        },
    },
    {
        version = "2.9.18",
        highlights = {
            L["wn_2918_buckets"],
            L["wn_2918_bucket_toggle"],
            L["wn_2918_tracker_width"],
            L["wn_2918_layout_fix"],
        },
    },
    {
        version = "2.9.17",
        highlights = {
            L["wn_2917_ab_master_toggle"],
            L["wn_2917_installer_raid"],
            L["wn_2917_installer_coverage"],
            L["wn_2917_chat_skin_fix"],
            L["wn_2917_talking_head_fix"],
            L["wn_2917_minimal_style"],
        },
    },
    {
        version = "2.9.16",
        highlights = {
            L["wn_2916_layout_fix"],
            L["wn_2916_safe_init"],
            L["wn_2916_art_total"],
            L["wn_2916_avr_gui"],
        },
    },
    {
        version = "2.9.15",
        highlights = {
            L["wn_2915_art_module"],
            L["wn_2915_art_tooltip"],
            L["wn_2915_art_scrollbar"],
            L["wn_2915_art_anchor"],
            L["wn_2915_art_scan_fix"],
        },
    },
    {
        version = "2.9.13",
        highlights = {
            L["wn_2913_boss_names"],
            L["wn_2913_boss_checkmark"],
            L["wn_2913_ej_pcall"],
        },
    },
    {
        version = "2.9.12",
        highlights = {
            L["wn_2912_party_cd_fix"],
            L["wn_2912_healer_interrupt"],
            L["wn_2912_perf_cdm"],
            L["wn_2912_perf_aura"],
            L["wn_2912_perf_resbars"],
        },
    },
    {
        version = "2.9.11",
        highlights = {
            L["wn_2911_cdm_hooks"],
            L["wn_2911_procglow_fixes"],
            L["wn_2911_buffskin_fixes"],
        },
    },
    {
        version = "2.9.10",
        highlights = {
            L["wn_2910_ej_boss_names"],
            L["wn_2910_ej_fallback"],
        },
    },
    {
        version = "2.9.9",
        highlights = {
            L["wn_299_merchant_tools"],
            L["wn_299_already_known"],
            L["wn_299_extend_pages"],
            L["wn_299_locales"],
            L["wn_299_lustsound"],
        },
    },
    {
        version = "2.9.8",
        highlights = {
            L["wn_298_housing"],
            L["wn_298_housing_hover"],
            L["wn_298_housing_clock"],
            L["wn_298_housing_teleport"],
            L["wn_298_icons"],
            L["wn_298_locales"],
        },
    },
    {
        version = "2.9.7",
        highlights = {
            L["wn_297_rf_live_preview"],
            L["wn_297_rf_preview_layout"],
            L["wn_297_rf_preview_scaling"],
            L["wn_297_taint_blizzard"],
            L["wn_297_range_fix"],
            L["wn_297_actionbars_fix"],
            L["wn_297_mp_tracker"],
            L["wn_297_role_icon"],
            L["wn_297_castbar_fix"],
            L["wn_297_diag_exclusions"],
        },
    },
    {
        version = "2.9.6",
        highlights = {
            L["wn_296_raid_frames"],
            L["wn_296_raid_health"],
            L["wn_296_raid_auras"],
            L["wn_296_raid_utilities"],
            L["wn_296_raid_config"],
        },
    },
    {
        version = "2.9.5",
        highlights = {
            L["wn_295_taint_fix"],
            L["wn_295_diag_taint"],
            L["wn_295_tooltip_ids_moved"],
            L["wn_295_chat_text_offset"],
        },
    },
    {
        version = "2.9.4",
        highlights = {
            L["wn_294_installer"],
            L["wn_294_uf_pf"],
            L["wn_294_cb_res"],
            L["wn_294_skins_qol"],
            L["wn_294_bugfixes"],
            L["wn_294_locales"],
        },
    },
    {
        version = "2.9.3",
        highlights = {
            L["wn_293_partyframe"],
            L["wn_293_actionbar_fix"],
            L["wn_293_chat_taint"],
            L["wn_293_diagnostics"],
            L["wn_293_autofill"],
        },
    },
    {
        version = "2.9.2",
        highlights = {
            L["wn_292_actionbar"],
            L["wn_292_diagnostics"],
        },
    },
}

-- ============================================================
-- VERSION COMPARISON
-- ============================================================

local function GetCurrentVersion()
    return C_AddOns.GetAddOnMetadata("TomoMod", "Version") or "0.0.0"
end

local function ShouldShow()
    if not TomoModDB then return false end
    local current = GetCurrentVersion()
    local seen    = TomoModDB.lastSeenVersion or ""
    return seen ~= current
end

local function MarkSeen()
    if TomoModDB then
        TomoModDB.lastSeenVersion = GetCurrentVersion()
    end
end

-- ============================================================
-- FIND ENTRY FOR CURRENT VERSION
-- ============================================================

local function GetCurrentEntry()
    local ver = GetCurrentVersion()
    for _, entry in ipairs(CHANGELOG) do
        if entry.version == ver then
            return entry
        end
    end
    return nil
end

-- ============================================================
-- UI
-- ============================================================

local frame

local function CreateFrame_WN()
    if frame then return frame end

    local backdrop = {
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    }

    -- Dimmer
    local dimmer = CreateFrame("Frame", nil, UIParent)
    dimmer:SetFrameStrata("DIALOG")
    dimmer:SetFrameLevel(140)
    dimmer:SetAllPoints()
    local dimTex = dimmer:CreateTexture(nil, "BACKGROUND")
    dimTex:SetAllPoints()
    dimTex:SetColorTexture(0, 0, 0, 0.50)
    dimmer:EnableMouse(true)

    -- Main panel
    frame = CreateFrame("Frame", "TomoModWhatsNewFrame", dimmer, "BackdropTemplate")
    frame:SetSize(PANEL_W, PANEL_H)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(141)
    frame:SetBackdrop(backdrop)
    frame:SetBackdropColor(BG[1], BG[2], BG[3], BG[4])
    frame:SetBackdropBorderColor(A[1], A[2], A[3], 0.40)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame._dimmer = dimmer

    -- Header bar
    local header = CreateFrame("Frame", nil, frame)
    header:SetHeight(48)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    local hbg = header:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints()
    hbg:SetColorTexture(0.05, 0.05, 0.07, 1)

    -- Logo
    local logo = header:CreateTexture(nil, "ARTWORK")
    logo:SetSize(24, 24)
    logo:SetPoint("LEFT", 14, 0)
    logo:SetTexture(LOGO_TEX)
    logo:SetVertexColor(A[1], A[2], A[3], 1)

    -- Title
    local title = header:CreateFontString(nil, "ARTWORK")
    title:SetFont(FONT_BOLD, 14)
    title:SetPoint("LEFT", logo, "RIGHT", 8, 0)
    title:SetTextColor(TX[1], TX[2], TX[3])
    frame._title = title

    -- Close button
    local close = CreateFrame("Button", nil, header)
    close:SetSize(28, 28)
    close:SetPoint("RIGHT", -10, 0)
    close:SetNormalFontObject(GameFontNormalLarge)
    local closeTxt = close:CreateFontString(nil, "ARTWORK")
    closeTxt:SetFont(FONT_BOLD, 18)
    closeTxt:SetPoint("CENTER")
    closeTxt:SetText("×")
    closeTxt:SetTextColor(DM[1], DM[2], DM[3])
    close:SetScript("OnEnter", function() closeTxt:SetTextColor(1, 0.3, 0.3) end)
    close:SetScript("OnLeave", function() closeTxt:SetTextColor(DM[1], DM[2], DM[3]) end)
    close:SetScript("OnClick", function() WN.Hide() end)

    -- Accent line under header
    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetHeight(1)
    accent:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
    accent:SetColorTexture(A[1], A[2], A[3], 0.60)

    -- Scroll frame for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 12, -12)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 52)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(PANEL_W - 44)
    scrollFrame:SetScrollChild(scrollChild)


    -- Style scrollbar (hidden if not needed, modern look if shown)
    local sb = scrollFrame.ScrollBar
    if sb then
        Mixin(sb, BackdropTemplateMixin)
        sb:SetWidth(7)
        sb:ClearAllPoints()
        sb:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 2, -2)
        sb:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 2, 2)
        sb:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        sb:SetBackdropColor(0.13, 0.13, 0.16, 0.18)
        sb:SetBackdropBorderColor(A[1], A[2], A[3], 0.18)
        local thumb = sb:GetThumbTexture()
        if thumb then
            thumb:SetColorTexture(A[1], A[2], A[3], 0.55)
            thumb:SetWidth(7)
            thumb:SetHeight(32)
            thumb:SetTexelSnappingBias(0)
            thumb:SetSnapToPixelGrid(false)
            -- Arrondi visuel (simulateur)
            if not sb._thumbBG then
                local bg = sb:CreateTexture(nil, "BACKGROUND")
                bg:SetColorTexture(0.13, 0.13, 0.16, 0.22)
                bg:SetPoint("TOPLEFT", sb, "TOPLEFT", 1, -1)
                bg:SetPoint("BOTTOMRIGHT", sb, "BOTTOMRIGHT", -1, 1)
                sb._thumbBG = bg
            end
        end
        sb:Hide() -- caché par défaut, affiché si besoin
    end

    frame._scrollChild = scrollChild
    frame._scrollFrame = scrollFrame

    -- OK button
    local okBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    okBtn:SetSize(140, 34)
    okBtn:SetPoint("BOTTOM", 0, 12)
    okBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    okBtn:SetBackdropColor(A[1], A[2], A[3], 0.15)
    okBtn:SetBackdropBorderColor(A[1], A[2], A[3], 0.40)
    local okTxt = okBtn:CreateFontString(nil, "ARTWORK")
    okTxt:SetFont(FONT_BOLD, 13)
    okTxt:SetPoint("CENTER")
    okTxt:SetText(L["wn_btn_ok"])
    okTxt:SetTextColor(A[1], A[2], A[3])
    okBtn:SetScript("OnEnter", function()
        okBtn:SetBackdropColor(A[1], A[2], A[3], 0.30)
    end)
    okBtn:SetScript("OnLeave", function()
        okBtn:SetBackdropColor(A[1], A[2], A[3], 0.15)
    end)
    okBtn:SetScript("OnClick", function() WN.Hide() end)

    tinsert(UISpecialFrames, "TomoModWhatsNewFrame")

    return frame
end

-- ============================================================
-- POPULATE CONTENT
-- ============================================================


local function PopulateContent(entry)
    local f = CreateFrame_WN()
    local parent = f._scrollChild
    local scrollFrame = f._scrollFrame

    -- Clear old children
    for _, child in ipairs({ parent:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, region in ipairs({ parent:GetRegions() }) do
        region:Hide()
        region:SetParent(nil)
    end

    f._title:SetText("TomoMod — " .. L["wn_title"])

    local y = 0

    -- Version badge
    local verText = parent:CreateFontString(nil, "ARTWORK")
    verText:SetFont(FONT_BOLD, 18)
    verText:SetPoint("TOPLEFT", 0, y)
    verText:SetText(string.format(L["wn_version"], entry.version))
    verText:SetTextColor(A[1], A[2], A[3])
    y = y - 30

    -- Subtitle
    local sub = parent:CreateFontString(nil, "ARTWORK")
    sub:SetFont(FONT, 12)
    sub:SetPoint("TOPLEFT", 0, y)
    sub:SetText(L["wn_subtitle"])
    sub:SetTextColor(DM[1], DM[2], DM[3])
    y = y - 24

    -- Separator
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 0, y)
    sep:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
    sep:SetColorTexture(A[1], A[2], A[3], 0.25)
    y = y - 16

    -- Highlights
    for _, text in ipairs(entry.highlights) do
        local bullet = parent:CreateFontString(nil, "ARTWORK")
        bullet:SetFont(FONT, 12.5)
        bullet:SetPoint("TOPLEFT", 4, y)
        bullet:SetWidth(PANEL_W - 64)
        bullet:SetJustifyH("LEFT")
        bullet:SetWordWrap(true)
        bullet:SetSpacing(3)
        bullet:SetText("|cff2ed884•|r  " .. text)
        bullet:SetTextColor(TX[1], TX[2], TX[3])
        local textH = bullet:GetStringHeight() or 16
        y = y - textH - 10
    end

    y = y - 8

    -- Reminder: /tm
    local remind = parent:CreateFontString(nil, "ARTWORK")
    remind:SetFont(FONT, 11)
    remind:SetPoint("TOPLEFT", 0, y)
    remind:SetWidth(PANEL_W - 64)
    remind:SetJustifyH("LEFT")
    remind:SetWordWrap(true)
    remind:SetText(L["wn_footer"])
    remind:SetTextColor(DM[1], DM[2], DM[3])
    y = y - (remind:GetStringHeight() or 14) - 8

    parent:SetHeight(math.abs(y) + 20)

    -- Hide scrollbar if not needed, show and style if needed
    if scrollFrame and scrollFrame.ScrollBar then
        local contentH = parent:GetHeight()
        local viewH = scrollFrame:GetHeight()
        if contentH <= viewH + 2 then
            scrollFrame.ScrollBar:Hide()
            scrollFrame:EnableMouseWheel(false)
        else
            scrollFrame.ScrollBar:Show()
            scrollFrame:EnableMouseWheel(true)
        end
    end
end

-- ============================================================
-- SHOW / HIDE
-- ============================================================

function WN.Show()
    local entry = GetCurrentEntry()
    if not entry then
        MarkSeen()
        return
    end
    PopulateContent(entry)
    frame:Show()
    frame._dimmer:Show()
end

function WN.Hide()
    if frame then
        frame:Hide()
        frame._dimmer:Hide()
    end
    MarkSeen()
end

-- ============================================================
-- AUTO TRIGGER (called from Init.lua)
-- ============================================================

function WN.TryShow()
    if not ShouldShow() then return end
    -- Skip if installer is about to show (first run)
    if TomoModDB and TomoModDB.installer and not TomoModDB.installer.completed then
        MarkSeen()
        return
    end
    WN.Show()
end

-- =====================================
-- Widgets.lua — Config UI Widgets v2.7.0
-- Redesigned visual style to match new GUI:
--   • SectionHeader  : bg strip + left accent bar + bold title
--   • Card           : grouped container with framed border  [NEW]
--   • Checkbox       : pill-style with animated tick
--   • Slider         : filled-track with value badge
--   • Button         : solid accent with invert-on-hover
--   • Dropdown       : cleaner arrow + item highlight
--   • TwoColumnRow   : side-by-side widget layout           [NEW]
--   • ScrollPanel    : slim thumb, auto-hide
-- =====================================

TomoMod_Widgets = {}
local W = TomoMod_Widgets

-- =====================================================================
-- THEME
-- =====================================================================
W.Theme = {
    bg           = { 0.07,  0.07,  0.09,  0.97 },
    bgLight      = { 0.11,  0.11,  0.14,  1    },
    bgMid        = { 0.09,  0.09,  0.115, 1    },
    bgDark       = { 0.045, 0.045, 0.060, 1    },
    accent       = { TomoMod_Utils.BRAND[1], TomoMod_Utils.BRAND[2], TomoMod_Utils.BRAND[3], 1    },  -- #2ed884
    accentDark   = { TomoMod_Utils.BRAND_DARK[1], TomoMod_Utils.BRAND_DARK[2], TomoMod_Utils.BRAND_DARK[3], 1    },
    accentHover  = { TomoMod_Utils.BRAND_HOVER[1], TomoMod_Utils.BRAND_HOVER[2], TomoMod_Utils.BRAND_HOVER[3], 1 },
    accentBg     = { TomoMod_Utils.BRAND[1], TomoMod_Utils.BRAND[2], TomoMod_Utils.BRAND[3], 0.12 },  -- very transparent teal bg
    border       = { 0.18,  0.18,  0.22,  1    },
    borderLight  = { 0.28,  0.28,  0.34,  1    },
    text         = { 0.88,  0.90,  0.89,  1    },
    textDim      = { 0.48,  0.48,  0.54,  1    },
    textHeader   = { TomoMod_Utils.BRAND[1], TomoMod_Utils.BRAND[2], TomoMod_Utils.BRAND[3], 1    },
    red          = { 0.88,  0.22,  0.22,  1    },
    yellow       = { 0.96,  0.80,  0.10,  1    },
    white        = { 1,     1,     1,     1    },
    separator    = { 0.16,  0.16,  0.20,  0.7  },
    cardBg       = { 0.090, 0.090, 0.115, 1    },
    cardBorder   = { 0.20,  0.20,  0.26,  1    },
}

local T = W.Theme
local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

local function SC(tex, colorTable)
    local a = colorTable[4] or 1
    if tex.SetColorTexture then
        tex:SetColorTexture(colorTable[1], colorTable[2], colorTable[3], a)
    elseif tex.SetTextColor then
        tex:SetTextColor(colorTable[1], colorTable[2], colorTable[3], a)
    end
end

function W.CloseDropdowns()
    if W._openDropdown then
        W._openDropdown:Hide()
        W._openDropdown = nil
    end
end

function W.SetPanelContext(context)
    W._panelContext = context
end

function W.ApplyPanelContext(frame, context)
    if frame and context then frame._muiDesign = context end
end

-- =====================================================================
-- BUILD CONTEXT (Global Search)  [Lot B]
-- Tracks which category / tab / section is being built so that widgets
-- can self-register into the search index (Config/GlobalSearch.lua).
-- Every hook is optional: without GlobalSearch.lua nothing changes.
-- =====================================================================
-- `tabPath` is the ordered list of { key, label } from the outermost tab
-- bar down to the innermost. Nested tab bars (UnitFrames, PartyFrames,
-- CooldownResource, ...) mean a widget's "tab" is a path, not one key:
-- ctx.tab alone only ever holds the INNERMOST one, which is not enough to
-- navigate back to it.
W._buildCtx = { cat = nil, catLabel = nil, tab = nil, tabLabel = nil, section = nil, tabPath = {} }

local function ClearFrom(list, from)
    for i = #list, from, -1 do list[i] = nil end
end

function W.SetBuildContext(catKey, catLabel)
    local ctx = W._buildCtx
    ctx.cat, ctx.catLabel = catKey, catLabel
    ctx.tab, ctx.tabLabel, ctx.section = nil, nil, nil
    ctx.tabPath = ctx.tabPath or {}
    ClearFrom(ctx.tabPath, 1)
end

-- Writes one level of the path and drops everything below it.
function W._SetBuildTabAt(level, tabKey, tabLabel)
    local ctx  = W._buildCtx
    local path = ctx.tabPath
    ClearFrom(path, level)
    path[level] = { key = tabKey, label = tabLabel }
    ctx.tab, ctx.tabLabel = tabKey, tabLabel
    ctx.section = nil
end

-- Back-compat entry point (ghost indexer and any external caller): the
-- caller is always describing the outermost level.
function W._SetBuildTab(tabKey, tabLabel)
    W._SetBuildTabAt(1, tabKey, tabLabel)
end

-- Snapshot of the current path as { key, ... }, for storing on an entry.
function W.GetBuildTabPath()
    local path, out = W._buildCtx.tabPath, {}
    for i = 1, #path do out[i] = path[i].key end
    return out
end

-- Snapshot/restore of the raw path, used by CreateTabPanel to re-establish
-- its ancestors before building a tab that is opened long after the page.
function W._CaptureTabPath()
    local path, out = W._buildCtx.tabPath, {}
    for i = 1, #path do out[i] = path[i] end
    return out
end

function W._RestoreTabPath(prefix)
    local path = W._buildCtx.tabPath
    ClearFrom(path, 1)
    for i = 1, #prefix do path[i] = prefix[i] end
end

function W._SetBuildSection(title)
    W._buildCtx.section = title
end

local function FindDesign(parent)
    local f = parent
    while f do
        if f._muiDesign then return f._muiDesign end
        f = f.GetParent and f:GetParent() or nil
    end
    return W._panelContext or {}
end

local function Accent(parent)
    local design = FindDesign(parent)
    local c = design.accent or T.accent
    return c[1] or T.accent[1], c[2] or T.accent[2], c[3] or T.accent[3]
end

local function SoftColor(r, g, b, factor, alpha)
    return { r * factor, g * factor, b * factor, alpha or 1 }
end

-- =====================================================================
-- ROLE TAGGING  [Lot A]
-- Sections can declare which roles they matter to with a compact spec
-- string: "T" tank, "H" healer, "D" damage — combinable ("TD", "THD").
--
-- Two visible effects:
--   1. small role icons in the section/card header (always shown),
--   2. an optional sidebar filter that DIMS sections belonging to other
--      roles. Nothing is ever hidden, and untagged sections always stay
--      at full opacity — so partial tagging is safe and a player never
--      loses track of a setting.
-- =====================================================================
local ROLE_TEX = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Roles\\"

-- Colours match the archetype cards in Config/Presets.lua on purpose.
W.ROLE_ORDER = { "TANK", "HEALER", "DAMAGER" }
W.ROLE_INFO  = {
    TANK    = { letter = "T", icon = ROLE_TEX .. "TANK.tga",    color = { 0.28, 0.52, 0.92 }, lk = "role_tank"   },
    HEALER  = { letter = "H", icon = ROLE_TEX .. "HEALER.tga",  color = { 0.36, 0.82, 0.42 }, lk = "role_healer" },
    DAMAGER = { letter = "D", icon = ROLE_TEX .. "DAMAGER.tga", color = { 0.85, 0.32, 0.32 }, lk = "role_dps"    },
}

if TomoMod_RegisterLocale then
    TomoMod_RegisterLocale("enUS", {
        ["role_tank"]              = "Tank",
        ["role_healer"]            = "Healer",
        ["role_dps"]               = "DPS",
        ["role_badge_title"]       = "Useful for",
        ["role_badge_hint"]        = "Use the role filter in the sidebar to bring these settings forward.",
        ["cfg_rolefilter_all"]     = "All",
        ["cfg_rolefilter_label"]   = "Role focus",
        ["cfg_rolefilter_tip"]     = "Keep only the settings that matter to a %s at full brightness. Nothing is hidden — everything else is simply dimmed.",
        ["cfg_rolefilter_tip_all"] = "Show every setting, with no role emphasis.",
    })
    TomoMod_RegisterLocale("frFR", {
        ["role_tank"]              = "Tank",
        ["role_healer"]            = "Soigneur",
        ["role_dps"]               = "DPS",
        ["role_badge_title"]       = "Utile pour",
        ["role_badge_hint"]        = "Utilise le filtre de rôle dans la barre latérale pour mettre ces réglages en avant.",
        ["cfg_rolefilter_all"]     = "Tous",
        ["cfg_rolefilter_label"]   = "Focus rôle",
        ["cfg_rolefilter_tip"]     = "Ne garder en pleine lumière que les réglages utiles à un %s. Rien n'est masqué : le reste est simplement estompé.",
        ["cfg_rolefilter_tip_all"] = "Afficher tous les réglages, sans mise en avant de rôle.",
    })
    TomoMod_RegisterLocale("deDE", {
        ["role_tank"]              = "Tank",
        ["role_healer"]            = "Heiler",
        ["role_dps"]               = "DPS",
        ["role_badge_title"]       = "Nützlich für",
        ["role_badge_hint"]        = "Nutze den Rollenfilter in der Seitenleiste, um diese Einstellungen hervorzuheben.",
        ["cfg_rolefilter_all"]     = "Alle",
        ["cfg_rolefilter_label"]   = "Rollenfokus",
        ["cfg_rolefilter_tip"]     = "Nur die für %s relevanten Einstellungen voll sichtbar lassen. Nichts wird ausgeblendet — der Rest wird lediglich abgedunkelt.",
        ["cfg_rolefilter_tip_all"] = "Alle Einstellungen anzeigen, ohne Rollenhervorhebung.",
    })
    TomoMod_RegisterLocale("esES", {
        ["role_tank"]              = "Tanque",
        ["role_healer"]            = "Sanador",
        ["role_dps"]               = "DPS",
        ["role_badge_title"]       = "Útil para",
        ["role_badge_hint"]        = "Usa el filtro de rol en la barra lateral para destacar estos ajustes.",
        ["cfg_rolefilter_all"]     = "Todos",
        ["cfg_rolefilter_label"]   = "Enfoque de rol",
        ["cfg_rolefilter_tip"]     = "Mantener a plena luz solo los ajustes que importan a un %s. No se oculta nada: el resto simplemente se atenúa.",
        ["cfg_rolefilter_tip_all"] = "Mostrar todos los ajustes, sin énfasis de rol.",
    })
    TomoMod_RegisterLocale("itIT", {
        ["role_tank"]              = "Difensore",
        ["role_healer"]            = "Guaritore",
        ["role_dps"]               = "DPS",
        ["role_badge_title"]       = "Utile per",
        ["role_badge_hint"]        = "Usa il filtro dei ruoli nella barra laterale per mettere in evidenza queste impostazioni.",
        ["cfg_rolefilter_all"]     = "Tutti",
        ["cfg_rolefilter_label"]   = "Focus ruolo",
        ["cfg_rolefilter_tip"]     = "Tenere in piena luce solo le impostazioni utili a un %s. Nulla viene nascosto: il resto è semplicemente attenuato.",
        ["cfg_rolefilter_tip_all"] = "Mostrare tutte le impostazioni, senza enfasi sul ruolo.",
    })
    TomoMod_RegisterLocale("ptBR", {
        ["role_tank"]              = "Tanque",
        ["role_healer"]            = "Curandeiro",
        ["role_dps"]               = "DPS",
        ["role_badge_title"]       = "Útil para",
        ["role_badge_hint"]        = "Use o filtro de função na barra lateral para destacar estes ajustes.",
        ["cfg_rolefilter_all"]     = "Todos",
        ["cfg_rolefilter_label"]   = "Foco de função",
        ["cfg_rolefilter_tip"]     = "Manter em destaque apenas os ajustes que importam a um %s. Nada é ocultado: o resto é apenas esmaecido.",
        ["cfg_rolefilter_tip_all"] = "Mostrar todos os ajustes, sem ênfase de função.",
    })
end

-- The locale metatable returns the raw key for unknown keys, so it is
-- not a usable nil-check: compare against the key itself.
local function Loc(key, fallback)
    local v = TomoMod_L and TomoMod_L[key]
    if v and v ~= key then return v end
    return fallback or key
end
W.Loc = Loc

local LETTER_TO_ROLE = { T = "TANK", H = "HEALER", D = "DAMAGER" }

-- "TD" -> { "TANK", "DAMAGER" }; nil / "" / garbage -> nil (untagged)
local function ParseRoles(spec)
    if type(spec) ~= "string" or spec == "" then return nil end
    local out = {}
    for i = 1, #spec do
        local role = LETTER_TO_ROLE[string.upper(string.sub(spec, i, i))]
        if role then
            local seen = false
            for j = 1, #out do
                if out[j] == role then seen = true; break end
            end
            if not seen then out[#out + 1] = role end
        end
    end
    if #out == 0 then return nil end
    return out
end
W.ParseRoles = ParseRoles

-- Registry of tagged sections. Only tagged sections land here, and each
-- frame is registered once, so this stays small (tens of entries) even
-- with GlobalSearch ghost-indexing every page.
W._roleSections = {}
W._roleFilter   = nil     -- nil = no filtering

local ROLE_DIM_ALPHA = 0.28

local function RegisterRoleSection(roles, frame, regions)
    if not frame or frame._roleRegistered then return end
    frame._roleRegistered = true
    W._roleSections[#W._roleSections + 1] = { roles = roles, frame = frame, regions = regions }
end

local function RoleEntryMatches(entry, active)
    if not active then return true end
    if not entry.roles then return true end   -- untagged is always relevant
    for i = 1, #entry.roles do
        if entry.roles[i] == active then return true end
    end
    return false
end

-- Re-applies the current filter to every registered section. Called
-- after a category or tab is built (panels are lazy) and on change.
function W.ApplyRoleFilter()
    local active = W._roleFilter
    local list   = W._roleSections
    for i = 1, #list do
        local e = list[i]
        local a = RoleEntryMatches(e, active) and 1 or ROLE_DIM_ALPHA
        if e.frame and e.frame.SetAlpha then e.frame:SetAlpha(a) end
        local regions = e.regions
        if regions then
            for j = 1, #regions do
                local rg = regions[j]
                if rg and rg.SetAlpha then rg:SetAlpha(a) end
            end
        end
    end
end

function W.SetRoleFilter(role)
    if role == "ALL" then role = nil end
    if role ~= nil and not W.ROLE_INFO[role] then role = nil end
    W._roleFilter = role
    W.ApplyRoleFilter()
end

function W.GetRoleFilter()
    return W._roleFilter
end

-- Hoisted: one closure for every badge instead of one per badge.
local function OnRoleBadgeEnter(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(Loc("role_badge_title", "Utile pour"), 1, 1, 1)
    local roles = self._roles
    for i = 1, #roles do
        local info = W.ROLE_INFO[roles[i]]
        if info then
            GameTooltip:AddLine(Loc(info.lk, roles[i]), info.color[1], info.color[2], info.color[3])
        end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(Loc("role_badge_hint", ""), 0.55, 0.55, 0.62, true)
    GameTooltip:Show()
end

local function OnRoleBadgeLeave()
    if GameTooltip then GameTooltip:Hide() end
end

local ROLE_BADGE_SIZE = 13
local ROLE_BADGE_GAP  = 3

-- Builds the icon strip and anchors it TOPRIGHT of `anchor`.
local function CreateRoleBadges(parent, roles, anchor, xOff, yOff)
    local n = #roles
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(n * (ROLE_BADGE_SIZE + ROLE_BADGE_GAP) - ROLE_BADGE_GAP, ROLE_BADGE_SIZE)
    holder:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", xOff, yOff)
    holder:EnableMouse(true)
    holder._roles = roles

    for i = 1, n do
        local info = W.ROLE_INFO[roles[i]]
        if info then
            local tex = holder:CreateTexture(nil, "OVERLAY")
            tex:SetSize(ROLE_BADGE_SIZE, ROLE_BADGE_SIZE)
            tex:SetPoint("LEFT", (i - 1) * (ROLE_BADGE_SIZE + ROLE_BADGE_GAP), 0)
            tex:SetTexture(info.icon)
            tex:SetVertexColor(info.color[1], info.color[2], info.color[3], 0.95)
        end
    end

    holder:SetScript("OnEnter", OnRoleBadgeEnter)
    holder:SetScript("OnLeave", OnRoleBadgeLeave)
    return holder
end

-- =====================================================================
-- SCROLL PANEL
-- =====================================================================
function W.CreateScrollPanel(parent)
    local SCROLLBAR_W   = 5
    local SCROLLBAR_PAD = 18
    local TRACK_PAD_V   = 8
    local THUMB_MIN_H   = 20

    local container = CreateFrame("Frame", nil, parent)
    container:SetAllPoints()
    container._muiDesign = FindDesign(parent)

    local track = container:CreateTexture(nil, "BACKGROUND")
    track:SetWidth(SCROLLBAR_W)
    track:SetPoint("TOPRIGHT",    -4, -TRACK_PAD_V)
    track:SetPoint("BOTTOMRIGHT", -4,  TRACK_PAD_V)
    track:SetColorTexture(0.12, 0.12, 0.16, 0.8)

    local thumbFrame = CreateFrame("Frame", nil, container)
    thumbFrame:SetWidth(SCROLLBAR_W)
    thumbFrame:SetPoint("TOPRIGHT", -4, -TRACK_PAD_V)
    local thumb = thumbFrame:CreateTexture(nil, "OVERLAY")
    thumb:SetAllPoints()
    SC(thumb, T.accent)

    local scroll = CreateFrame("ScrollFrame", nil, container)
    scroll:SetPoint("TOPLEFT",     0,              0)
    scroll:SetPoint("BOTTOMRIGHT", -SCROLLBAR_PAD, 0)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(scroll:GetWidth() or 1000)
    child:SetHeight(1)
    child._muiDesign = FindDesign(parent)
    scroll:SetScrollChild(child)

    local function UpdateThumb()
        local scrollH = scroll:GetHeight() or 0
        local childH  = child:GetHeight()  or 0
        local trackH  = scrollH - 2 * TRACK_PAD_V
        local maxS    = childH - scrollH
        if maxS <= 0 then thumbFrame:Hide(); track:Hide(); return end
        track:Show(); thumbFrame:Show()
        local ratio  = math.min(scrollH / childH, 1)
        local thumbH = math.max(math.floor(trackH * ratio), THUMB_MIN_H)
        thumbFrame:SetHeight(thumbH)
        local cur    = scroll:GetVerticalScroll()
        local thumbY = (cur / maxS) * (trackH - thumbH)
        thumbFrame:SetPoint("TOPRIGHT", -4, -(TRACK_PAD_V + thumbY))
    end

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * 36, max)))
        UpdateThumb()
    end)

    thumbFrame:EnableMouse(true)
    thumbFrame:RegisterForDrag("LeftButton")
    local dragStartY, dragStartScroll
    thumbFrame:SetScript("OnDragStart", function(self)
        dragStartY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        dragStartScroll = scroll:GetVerticalScroll()
        self:SetScript("OnUpdate", function()
            local curY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            local delta     = dragStartY - curY
            local scrollH   = scroll:GetHeight() or 0
            local childH    = child:GetHeight()  or 0
            local trackH    = scrollH - 2 * TRACK_PAD_V
            local ratio     = math.min(scrollH / childH, 1)
            local thumbH    = math.max(math.floor(trackH * ratio), THUMB_MIN_H)
            local maxScroll = childH - scrollH
            local newScroll = dragStartScroll + delta * (maxScroll / (trackH - thumbH))
            scroll:SetVerticalScroll(math.max(0, math.min(newScroll, maxScroll)))
            UpdateThumb()
        end)
    end)
    thumbFrame:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    thumbFrame:SetScript("OnEnter", function() SC(thumb, T.accentHover) end)
    thumbFrame:SetScript("OnLeave", function() SC(thumb, T.accent) end)

    scroll:SetScript("OnSizeChanged", function(self, w, h)
        child:SetWidth(math.max(w, 10)); UpdateThumb()
    end)
    scroll:SetScript("OnShow", function(self)
        local w = self:GetWidth()
        if w and w > 0 then child:SetWidth(w) end
        UpdateThumb()
    end)

    container.UpdateScroll = UpdateThumb
    container.child  = child
    container.scroll = scroll
    scroll.child        = child
    scroll.UpdateScroll = UpdateThumb
    return container
end

-- =====================================================================
-- SECTION HEADER  — bg strip + left accent bar + bold title
-- =====================================================================
function W.CreateSectionHeader(parent, text, yOffset, roles)
    local STRIP_H = 28
    local r, g, b = Accent(parent)

    local strip = parent:CreateTexture(nil, "BACKGROUND")
    strip:SetHeight(STRIP_H)
    strip:SetPoint("TOPLEFT",  8,  yOffset)
    strip:SetPoint("TOPRIGHT", -8, yOffset)
    strip:SetColorTexture(0.045 + r * 0.035, 0.045 + g * 0.030, 0.060 + b * 0.035, 1)

    local bar = parent:CreateTexture(nil, "ARTWORK")
    bar:SetWidth(3)
    bar:SetHeight(STRIP_H)
    bar:SetPoint("TOPLEFT", 8, yOffset)
    bar:SetColorTexture(r, g, b, 1)

    local topLine = parent:CreateTexture(nil, "ARTWORK")
    topLine:SetHeight(1)
    topLine:SetPoint("TOPLEFT", 8, yOffset)
    topLine:SetPoint("TOPRIGHT", -8, yOffset)
    topLine:SetColorTexture(r, g, b, 0.52)

    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_BOLD, 12, "")
    lbl:SetPoint("LEFT", bar, "RIGHT", 7, 0)
    lbl:SetTextColor(r, g, b, 1)
    lbl:SetText(text)

    -- [Lot A] Role tagging: the header regions are siblings on `parent`,
    -- not children of a container, so they are dimmed as an explicit list.
    local parsedRoles = ParseRoles(roles)
    if parsedRoles then
        local badges = CreateRoleBadges(parent, parsedRoles, strip, -6, -7)
        RegisterRoleSection(parsedRoles, badges, { strip, bar, topLine, lbl })
    end

    if W._SetBuildSection then W._SetBuildSection(text) end
    if W._RegisterSearchEntry then W._RegisterSearchEntry(text, lbl, "section") end

    return lbl, yOffset - STRIP_H - 8
end

-- =====================================================================
-- CARD  — frosted group container  [NEW]
-- Returns (card, innerY) where innerY is the Y offset for first child
-- Usage: local card, cy = W.CreateCard(c, "Titre", y)
--        W.CreateCheckbox(card.inner, ..., cy, ...)
--        W.FinalizeCard(card, cy)
-- =====================================================================
function W.CreateCard(parent, title, yOffset, roles)
    local r, g, b = Accent(parent)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT",  8,  yOffset)
    card:SetPoint("TOPRIGHT", -8, yOffset)
    card:SetHeight(40) -- will be adjusted by FinalizeCard
    if W._SetBuildSection then W._SetBuildSection(title) end
    if W._RegisterSearchEntry then W._RegisterSearchEntry(title, card, "section") end
    card:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    card._muiDesign = FindDesign(parent)
    card:SetBackdropColor(0.052, 0.050, 0.070, 0.98)
    card:SetBackdropBorderColor(r, g, b, 0.28)

    -- Left accent thin stripe
    local accentBar = card:CreateTexture(nil, "ARTWORK")
    accentBar:SetWidth(3)
    accentBar:SetPoint("TOPLEFT",    0, -1)
    accentBar:SetPoint("BOTTOMLEFT", 0,  1)
    accentBar:SetColorTexture(r, g, b, 0.92)

    local glow = card:CreateTexture(nil, "BACKGROUND", nil, -1)
    glow:SetPoint("TOPLEFT", 1, -1)
    glow:SetPoint("BOTTOMRIGHT", -1, 1)
    if glow.SetGradientAlpha then
        glow:SetGradientAlpha("HORIZONTAL", r, g, b, 0.12, 0, 0, 0, 0)
    else
        glow:SetColorTexture(r, g, b, 0.06)
    end

    local titleLbl
    local innerStartY
    if title and title ~= "" then
        -- Title area
        local titleBg = card:CreateTexture(nil, "BACKGROUND")
        titleBg:SetHeight(24)
        titleBg:SetPoint("TOPLEFT",  1, -1)
        titleBg:SetPoint("TOPRIGHT", -1, -1)
        titleBg:SetColorTexture(0.040 + r * 0.035, 0.038 + g * 0.030, 0.055 + b * 0.035, 1)

        titleLbl = card:CreateFontString(nil, "OVERLAY")
        titleLbl:SetFont(FONT_BOLD, 11, "")
        titleLbl:SetPoint("TOPLEFT", 10, -6)
        titleLbl:SetText(title)
        titleLbl:SetTextColor(r, g, b, 1)
        card.title = titleLbl

        local titleSep = card:CreateTexture(nil, "ARTWORK")
        titleSep:SetHeight(1)
        titleSep:SetPoint("TOPLEFT",  1, -24)
        titleSep:SetPoint("TOPRIGHT", -1, -24)
        titleSep:SetColorTexture(r, g, b, 0.24)

        innerStartY = -30
    else
        innerStartY = -8
    end

    -- Inner frame — children anchor to this
    local inner = CreateFrame("Frame", nil, card)
    inner:SetPoint("TOPLEFT",  6,   innerStartY)
    inner:SetPoint("TOPRIGHT", -6,  innerStartY)
    inner:SetHeight(1)
    card.inner        = inner
    card.innerStartY  = innerStartY
    card._startOffset = yOffset

    -- [Lot A] Role tagging. The card is a real frame, so dimming it
    -- carries every option inside it — that is the whole point of
    -- preferring cards over bare section headers for role-bound blocks.
    local parsedRoles = ParseRoles(roles)
    if parsedRoles then
        card._roles = parsedRoles
        CreateRoleBadges(card, parsedRoles, card, -8, titleLbl and -6 or -8)
        RegisterRoleSection(parsedRoles, card, nil)
    end

    return card, -4  -- -4 = first child y inside inner
end

function W.FinalizeCard(card, lastY)
    local contentH = math.abs(lastY) + 8
    card.inner:SetHeight(contentH)
    local titleH = card.title and 24 or 0
    local totalH = math.abs(card.innerStartY) + contentH + 8
    card:SetHeight(totalH)
    return card._startOffset - totalH - 6  -- returns new Y for next item after card
end

-- =====================================================================
-- SUBSECTION LABEL
-- =====================================================================
function W.CreateSubLabel(parent, text, yOffset)
    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 10, "")
    lbl:SetPoint("TOPLEFT", 16, yOffset)
    SC(lbl, T.textDim)
    lbl:SetText(text)
    return lbl, yOffset - 16
end

-- =====================================================================
-- SEPARATOR
-- =====================================================================
function W.CreateSeparator(parent, yOffset)
    local r, g, b = Accent(parent)
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  16, yOffset - 4)
    sep:SetPoint("TOPRIGHT", -16, yOffset - 4)
    sep:SetColorTexture(r, g, b, 0.18)
    return sep, yOffset - 14
end

-- =====================================================================
-- INFO TEXT  — with subtle ℹ badge
-- =====================================================================
function W.CreateInfoText(parent, text, yOffset)
    local r, g, b = Accent(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -16, yOffset)

    local dot = frame:CreateTexture(nil, "ARTWORK")
    dot:SetSize(4, 4)
    dot:SetPoint("TOPLEFT", 0, -5)
    dot:SetColorTexture(r, g, b, 0.82)

    local lbl = frame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 10, "")
    lbl:SetPoint("TOPLEFT",  8, 0)
    lbl:SetPoint("TOPRIGHT", 0, 0)
    lbl:SetJustifyH("LEFT")
    SC(lbl, T.textDim)
    lbl:SetText(text)

    local rawH = lbl:GetStringHeight()
    local h    = rawH or 0
    if h < 1 then h = 12 end
    local lines = math.max(1, math.ceil(h / 12))
    frame:SetHeight(lines * 14 + 4)
    return frame, yOffset - (lines * 14 + 10)
end

-- =====================================================================
-- CHECKBOX  — pill box with tick
-- =====================================================================
function W.CreateCheckbox(parent, text, checked, yOffset, callback)
    local r, g, b = Accent(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(26)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -4, yOffset)

    -- The clickable box (16×16 square, slightly rounded via backdrop)
    local box = CreateFrame("Button", nil, frame, "BackdropTemplate")
    box:SetSize(16, 16)
    box:SetPoint("LEFT", 0, 0)
    box:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    box:SetBackdropColor(T.bgLight[1], T.bgLight[2], T.bgLight[3], 1)
    box:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)
    box.bg = box

    -- Tick — a simple accent-colored fill inside
    local tick = box:CreateTexture(nil, "OVERLAY")
    tick:SetPoint("TOPLEFT",     2, -2)
    tick:SetPoint("BOTTOMRIGHT", -2,  2)
    tick:SetColorTexture(r, g, b, 1)

    -- Label
    local lbl = frame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, "")
    lbl:SetPoint("LEFT", box, "RIGHT", 8, 0)
    SC(lbl, T.text)
    lbl:SetText(text)

    local isChecked = checked

    local function UpdateVisual()
        if isChecked then
            tick:Show()
            box:SetBackdropColor(r * 0.12, g * 0.12, b * 0.12, 0.24)
            box:SetBackdropBorderColor(r, g, b, 0.80)
        else
            tick:Hide()
            box:SetBackdropColor(T.bgLight[1], T.bgLight[2], T.bgLight[3], 1)
            box:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)
        end
    end
    UpdateVisual()

    local function Toggle()
        isChecked = not isChecked
        UpdateVisual()
        if callback then callback(isChecked) end
    end

    box:SetScript("OnClick", Toggle)
    -- Also allow clicking on the label
    frame:EnableMouse(true)
    frame:SetScript("OnMouseUp", function(_, btn)
        if btn == "LeftButton" then Toggle() end
    end)
    box:SetScript("OnEnter", function()
        box:SetBackdropBorderColor(T.borderLight[1], T.borderLight[2], T.borderLight[3], 1)
    end)
    box:SetScript("OnLeave", function()
        if isChecked then
            box:SetBackdropBorderColor(r, g, b, 0.80)
        else
            box:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)
        end
    end)

    frame.SetChecked = function(_, val) isChecked = val; UpdateVisual() end
    frame.GetChecked = function() return isChecked end

    if W._RegisterSearchEntry then W._RegisterSearchEntry(text, frame, "option") end

    return frame, yOffset - 28
end

-- =====================================================================
-- SLIDER  — filled track + value badge
-- =====================================================================
function W.CreateSlider(parent, text, value, minVal, maxVal, step, yOffset, callback, formatStr, defaultVal)
    formatStr = formatStr or "%.0f"
    local resetVal = (defaultVal ~= nil) and defaultVal or value
    local TRACK_H = 6
    local THUMB_W = 11
    local THUMB_H = 18

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(52)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -16, yOffset)

    -- Label row
    local lbl = frame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, "")
    lbl:SetPoint("TOPLEFT", 0, 0)
    SC(lbl, T.text)
    lbl:SetText(text)

    -- Value badge (top-right)
    local valBox = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    valBox:SetSize(54, 18)
    valBox:SetPoint("TOPRIGHT", 0, 0)
    valBox:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    valBox:SetBackdropColor(T.accentBg[1], T.accentBg[2], T.accentBg[3], T.accentBg[4])
    valBox:SetBackdropBorderColor(T.accentDark[1], T.accentDark[2], T.accentDark[3], 0.5)

    local valTxt = valBox:CreateFontString(nil, "OVERLAY")
    valTxt:SetFont(FONT_BOLD, 10, "")
    valTxt:SetPoint("CENTER")
    SC(valTxt, T.accent)

    -- Track background
    local trackBg = frame:CreateTexture(nil, "BACKGROUND")
    trackBg:SetHeight(TRACK_H)
    trackBg:SetPoint("TOPLEFT",  0, -22)
    trackBg:SetPoint("TOPRIGHT", 0, -22)
    trackBg:SetColorTexture(T.bgLight[1], T.bgLight[2], T.bgLight[3], 1)

    -- Track fill (left side filled with accent)
    local trackFill = frame:CreateTexture(nil, "ARTWORK")
    trackFill:SetHeight(TRACK_H)
    trackFill:SetPoint("LEFT", trackBg, "LEFT")
    SC(trackFill, T.accentDark)

    -- Global name needed for WoW slider widget
    local sliderName = "TomoWidgetSlider_" .. tostring(math.random(1000000))
    local slider = CreateFrame("Slider", sliderName, frame, "BackdropTemplate")
    slider:SetOrientation("HORIZONTAL")
    slider:SetHeight(THUMB_H + 8)
    slider:SetPoint("TOPLEFT",  -2, -17)
    slider:SetPoint("TOPRIGHT",  2, -17)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(value)
    -- Transparent over the visible track
    slider:SetBackdropColor(0, 0, 0, 0)
    slider:SetBackdropBorderColor(0, 0, 0, 0)

    -- Custom thumb texture
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(THUMB_W, THUMB_H)
    SC(thumb, T.accent)

    local function UpdateFill(v)
        local range = maxVal - minVal
        local ratio = range > 0 and ((v - minVal) / range) or 0
        local w     = trackBg:GetWidth()
        if w and w > 0 then
            trackFill:SetWidth(math.max(0, ratio * w))
        end
    end

    local function UpdateVal(v)
        v = math.floor(v / step + 0.5) * step
        valTxt:SetText(string.format(formatStr, v))
        UpdateFill(v)
    end
    UpdateVal(value)

    slider:SetScript("OnValueChanged", function(_, v)
        v = math.floor(v / step + 0.5) * step
        UpdateVal(v)
        if callback then callback(v) end
    end)
    slider:SetScript("OnEnter", function() SC(thumb, T.accentHover) end)
    slider:SetScript("OnLeave", function() SC(thumb, T.accent) end)
    slider:SetScript("OnSizeChanged", function() UpdateFill(slider:GetValue()) end)

    frame.slider   = slider
    frame.SetValue = function(_, v) slider:SetValue(v); UpdateVal(v) end
    frame.GetValue = function() return slider:GetValue() end

    -- Direct value entry: right-click the value badge to type an exact number.
    -- Enter (or focus loss) applies it through the slider, which clamps to
    -- [minVal, maxVal], snaps to step, and fires the normal callback.
    local editBox = CreateFrame("EditBox", nil, valBox)
    editBox:SetAllPoints(valBox)
    editBox:SetFont(FONT_BOLD, 10, "")
    editBox:SetJustifyH("CENTER")
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(false)   -- allow decimals/%, we sanitize below
    SC(editBox, T.accent)
    editBox:Hide()

    local function CommitEdit()
        local raw = editBox:GetText() or ""
        local num = tonumber(raw:match("[%-%d%.]+"))   -- strip any suffix (%, px)
        editBox:Hide()
        editBox:ClearFocus()
        if num then
            slider:SetValue(num)   -- clamps + snaps + fires OnValueChanged
        end
    end

    editBox:SetScript("OnEnterPressed", CommitEdit)
    editBox:SetScript("OnEscapePressed", function() editBox:Hide(); editBox:ClearFocus() end)
    editBox:SetScript("OnEditFocusLost", function() editBox:Hide() end)

    valBox:EnableMouse(true)
    valBox:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            editBox:SetText(tostring(math.floor(slider:GetValue() / step + 0.5) * step))
            editBox:Show()
            editBox:HighlightText()
            editBox:SetFocus()
        elseif button == "LeftButton" and IsControlKeyDown() then
            -- Ctrl+click resets to the default (or the initial) value.
            slider:SetValue(resetVal)
        end
    end)
    valBox:SetScript("OnEnter", function(self)
        if editBox:IsShown() then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Clic droit : saisir  |  Ctrl+clic : reinitialiser", 0.8, 0.85, 0.9)
        GameTooltip:Show()
    end)
    valBox:SetScript("OnLeave", function() GameTooltip:Hide() end)

    frame.slider   = slider
    frame.SetValue = function(_, v) slider:SetValue(v); UpdateVal(v) end
    frame.GetValue = function() return slider:GetValue() end

    if W._RegisterSearchEntry then W._RegisterSearchEntry(text, frame, "option") end

    return frame, yOffset - 52
end

-- =====================================================================
-- DROPDOWN  — cleaner arrow + item highlight
-- =====================================================================
function W.CreateDropdown(parent, text, options, selected, yOffset, callback)
    local r, g, b = Accent(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(46)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -16, yOffset)

    local lbl = frame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, "")
    lbl:SetPoint("TOPLEFT", 0, 0)
    SC(lbl, T.text)
    lbl:SetText(text)

    local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    btn:SetHeight(24)
    btn:SetPoint("TOPLEFT",  0, -18)
    btn:SetPoint("TOPRIGHT", 0, -18)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(T.bgLight[1], T.bgLight[2], T.bgLight[3], 1)
    btn:SetBackdropBorderColor(r, g, b, 0.34)

    local btnTxt = btn:CreateFontString(nil, "OVERLAY")
    btnTxt:SetFont(FONT, 11, "")
    btnTxt:SetPoint("LEFT", 8, 0)
    btnTxt:SetPoint("RIGHT", -22, 0)
    SC(btnTxt, T.text)

    -- Arrow: drawn chevron (two rotated strokes) -- texture-independent,
    -- the old Interface\\Buttons\\Arrow-Down-Down renders as a grey box in 12.x
    local arrowL = btn:CreateTexture(nil, "OVERLAY")
    arrowL:SetSize(8, 2)
    arrowL:SetPoint("RIGHT", -13, 0)
    arrowL:SetRotation(-0.6)
    local arrowR = btn:CreateTexture(nil, "OVERLAY")
    arrowR:SetSize(8, 2)
    arrowR:SetPoint("RIGHT", -7, 0)
    arrowR:SetRotation(0.6)
    arrowL:SetColorTexture(1, 1, 1, 1)
    arrowR:SetColorTexture(1, 1, 1, 1)
    SC(arrowL, T.textDim)
    SC(arrowR, T.textDim)

    local function GetDisplayText(val)
        for _, opt in ipairs(options) do
            if opt.value == val then return opt.text end
        end
        return tostring(val or "")
    end
    btnTxt:SetText(GetDisplayText(selected))

    -- Menu frame: parented to UIParent so scroll panels/cards cannot clip it.
    local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    menu:EnableMouse(true)
    menu:SetPoint("TOPLEFT",  btn, "BOTTOMLEFT",  0, -2)
    menu:SetPoint("TOPRIGHT", btn, "BOTTOMRIGHT", 0, -2)
    menu:SetHeight(#options * 22 + 6)
    menu:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    menu:SetBackdropColor(T.bgMid[1], T.bgMid[2], T.bgMid[3], 1)
    menu:SetBackdropBorderColor(r, g, b, 0.45)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(9000)
    menu:SetToplevel(true)
    if menu.SetClampedToScreen then menu:SetClampedToScreen(true) end
    menu:Hide()

    for i, opt in ipairs(options) do
        local item = CreateFrame("Button", nil, menu)
        item:SetHeight(22)
        item:SetPoint("TOPLEFT",  3, -(i - 1) * 22 - 3)
        item:SetPoint("TOPRIGHT", -3, -(i - 1) * 22 - 3)

        local itemBg = item:CreateTexture(nil, "BACKGROUND")
        itemBg:SetAllPoints()
        itemBg:SetColorTexture(0, 0, 0, 0)

        local itemTxt = item:CreateFontString(nil, "OVERLAY")
        itemTxt:SetFont(FONT, 11, "")
        itemTxt:SetPoint("LEFT", 8, 0)
        SC(itemTxt, T.text)
        itemTxt:SetText(opt.text)

        item:SetScript("OnEnter", function() itemBg:SetColorTexture(r, g, b, 0.16) end)
        item:SetScript("OnLeave", function() itemBg:SetColorTexture(0, 0, 0, 0) end)
        item:SetScript("OnClick", function()
            selected = opt.value
            btnTxt:SetText(opt.text)
            menu:Hide()
            if W._openDropdown == menu then W._openDropdown = nil end
            btn:SetBackdropBorderColor(r, g, b, 0.34)
            if callback then callback(opt.value) end
        end)
    end

    btn:SetScript("OnClick", function()
        if menu:IsShown() then
            menu:Hide()
            if W._openDropdown == menu then W._openDropdown = nil end
            btn:SetBackdropBorderColor(r, g, b, 0.34)
        else
            W.CloseDropdowns()
            W._openDropdown = menu
            menu:ClearAllPoints()
            menu:SetPoint("TOPLEFT",  btn, "BOTTOMLEFT",  0, -2)
            menu:SetPoint("TOPRIGHT", btn, "BOTTOMRIGHT", 0, -2)
            menu:SetFrameStrata("TOOLTIP")
            menu:SetFrameLevel(9000)
            menu:Show()
            btn:SetBackdropBorderColor(r, g, b, 0.70)
        end
    end)
    btn:SetScript("OnEnter", function()
        btn:SetBackdropBorderColor(T.borderLight[1], T.borderLight[2], T.borderLight[3], 1)
    end)
    btn:SetScript("OnLeave", function()
        if not menu:IsShown() then
            btn:SetBackdropBorderColor(r, g, b, 0.34)
        end
    end)

    frame.SetValue = function(_, val)
        selected = val; btnTxt:SetText(GetDisplayText(val))
    end
    frame:SetScript("OnHide", function()
        menu:Hide()
        if W._openDropdown == menu then W._openDropdown = nil end
    end)
    if W._RegisterSearchEntry then W._RegisterSearchEntry(text, frame, "option") end

    return frame, yOffset - 48
end

-- =====================================================================
-- SEGMENTED CONTROL — direct choice buttons, no floating menu
-- =====================================================================
function W.CreateSegmentedControl(parent, text, options, selected, yOffset, callback, columns)
    local r, g, b = Accent(parent)
    local cols = math.max(1, columns or math.min(#options, 3))
    local gap = 8
    local rowH = 30
    local labelH = text and text ~= "" and 18 or 0
    local rows = math.max(1, math.ceil(#options / cols))
    local frameH = labelH + rows * rowH + (rows - 1) * gap + 4

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(frameH)
    frame:SetPoint("TOPLEFT", 16, yOffset)
    frame:SetPoint("TOPRIGHT", -16, yOffset)

    if text and text ~= "" then
        local lbl = frame:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT, 11, "")
        lbl:SetPoint("TOPLEFT", 0, 0)
        SC(lbl, T.text)
        lbl:SetText(text)
    end

    local buttons = {}
    local function LayoutButtons()
        local width = frame:GetWidth() or 0
        if width < 120 then width = 640 end
        local cellW = math.floor((width - gap * (cols - 1)) / cols)
        for _, data in ipairs(buttons) do
            local x = data.col * (cellW + gap)
            local y = -(labelH + data.row * (rowH + gap))
            data.btn:ClearAllPoints()
            data.btn:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
            data.btn:SetSize(cellW, rowH)
        end
    end

    local function Refresh()
        for _, data in ipairs(buttons) do
            local active = data.value == selected
            if active then
                data.btn:SetBackdropColor(r * 0.18, g * 0.18, b * 0.18, 0.96)
                data.btn:SetBackdropBorderColor(r, g, b, 0.92)
                data.line:SetColorTexture(r, g, b, 1)
                data.label:SetTextColor(1, 1, 1, 1)
            else
                data.btn:SetBackdropColor(T.bgLight[1], T.bgLight[2], T.bgLight[3], 0.86)
                data.btn:SetBackdropBorderColor(r, g, b, 0.28)
                data.line:SetColorTexture(r, g, b, 0.25)
                data.label:SetTextColor(T.textDim[1], T.textDim[2], T.textDim[3], 1)
            end
        end
    end

    for i, opt in ipairs(options) do
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        btn:SetHeight(rowH)
        btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })

        local line = btn:CreateTexture(nil, "ARTWORK")
        line:SetHeight(2)
        line:SetPoint("TOPLEFT", 1, -1)
        line:SetPoint("TOPRIGHT", -1, -1)

        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont(FONT_BOLD, 10, "")
        label:SetPoint("LEFT", 8, 0)
        label:SetPoint("RIGHT", -8, 0)
        label:SetJustifyH("CENTER")
        label:SetText(opt.text or tostring(opt.value or ""))

        local data = { btn = btn, line = line, label = label, value = opt.value, row = row, col = col }
        buttons[#buttons + 1] = data

        btn:SetScript("OnEnter", function()
            if selected ~= opt.value then
                btn:SetBackdropBorderColor(r, g, b, 0.60)
                label:SetTextColor(T.text[1], T.text[2], T.text[3], 1)
            end
        end)
        btn:SetScript("OnLeave", Refresh)
        btn:SetScript("OnClick", function()
            selected = opt.value
            Refresh()
            if callback then callback(opt.value) end
        end)
    end

    Refresh()
    LayoutButtons()
    frame:SetScript("OnSizeChanged", LayoutButtons)
    frame.SetValue = function(_, val)
        selected = val
        Refresh()
    end
    if W._RegisterSearchEntry then W._RegisterSearchEntry(text, frame, "option") end

    return frame, yOffset - frameH - 6
end

-- =====================================================================
-- BUTTON  — accent fill, invert on hover
-- =====================================================================
function W.CreateButton(parent, text, width, yOffset, callback)
    local r, g, b = Accent(parent)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width or 160, 28)
    btn:SetPoint("TOPLEFT", 16, yOffset)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(r * 0.20, g * 0.16, b * 0.22, 0.90)
    btn:SetBackdropBorderColor(r, g, b, 0.60)

    local line = btn:CreateTexture(nil, "ARTWORK")
    line:SetHeight(2)
    line:SetPoint("TOPLEFT", 1, -1)
    line:SetPoint("TOPRIGHT", -1, -1)
    line:SetColorTexture(r, g, b, 0.85)

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_BOLD, 11, "")
    lbl:SetPoint("CENTER")
    lbl:SetText(text)
    lbl:SetTextColor(1, 1, 1, 1)

    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(r, g, b, 1)
        btn:SetBackdropBorderColor(r, g, b, 1)
        lbl:SetTextColor(0.06, 0.06, 0.08, 1)
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(r * 0.20, g * 0.16, b * 0.22, 0.90)
        btn:SetBackdropBorderColor(r, g, b, 0.60)
        lbl:SetTextColor(1, 1, 1, 1)
    end)
    btn:SetScript("OnClick", function() if callback then callback() end end)

    btn.label = lbl
    btn.SetText = function(self, t) lbl:SetText(t) end

    if W._RegisterSearchEntry then W._RegisterSearchEntry(text, btn, "option") end

    return btn, yOffset - 36
end

-- =====================================================================
-- COLOR PICKER
-- =====================================================================
-- ColorPickerFrame is toplevel, but every TomoMod window lives in
-- FULLSCREEN_DIALOG with an explicit frame level (ConfigUI 500, the Forge
-- studio shell 100 + SetToplevel), so the picker regularly opens BEHIND the
-- window that spawned it -- very visible on small screens, where the panel
-- covers the middle of the display. We raise it while it is shown and put
-- its own strata/level back on hide, so no other addon inherits our z-order.
local function RaiseColorPicker()
    local cp = ColorPickerFrame
    if not cp then return end

    if not cp._tmZFix then
        cp._tmZFix = true
        cp:HookScript("OnHide", function(self)
            if self._tmPrevStrata then
                self:SetFrameStrata(self._tmPrevStrata)
                self:SetFrameLevel(self._tmPrevLevel or 1)
                self._tmPrevStrata, self._tmPrevLevel = nil, nil
            end
        end)
    end
    if not cp._tmPrevStrata then
        cp._tmPrevStrata = cp:GetFrameStrata()
        cp._tmPrevLevel  = cp:GetFrameLevel()
    end
    cp:SetFrameStrata("TOOLTIP")   -- above the widget-kit dropdowns (9000)
    cp:SetFrameLevel(9500)
    cp:SetToplevel(true)
    cp:SetClampedToScreen(true)
end

-- Park the picker next to the swatch that opened it instead of the screen
-- centre, which on a small resolution lands under (or half off) the panel.
-- Anchored to UIParent in absolute coordinates, NOT to the swatch: the
-- swatch lives in a scroll frame and the picker must not follow it if the
-- panel behind is scrolled. Called after Show() so the rect is valid.
local function PlaceColorPicker(swatch)
    local cp = ColorPickerFrame
    if not (cp and swatch and swatch.GetLeft) then return end
    local left, bottom = swatch:GetLeft(), swatch:GetBottom()
    if not (left and bottom) then return end

    local cs = cp:GetEffectiveScale()
    local ss = swatch:GetEffectiveScale()
    local ps = UIParent:GetEffectiveScale()
    if not (cs and ss and ps) or cs <= 0 then return end

    -- swatch rect -> screen pixels -> picker units
    local x  = (left   * ss) / cs
    local y  = (bottom * ss) / cs
    local sw = (UIParent:GetWidth()  * ps) / cs
    local sh = (UIParent:GetHeight() * ps) / cs
    local w  = cp:GetWidth()  or 350
    local h  = cp:GetHeight() or 400

    -- prefer the right of the swatch, flip to its left when that overflows,
    -- and clamp to the screen as a last resort (very small resolutions).
    local px = x + ((swatch:GetWidth() or 26) * ss) / cs + 12
    if px + w > sw - 4 then px = x - w - 12 end
    if px < 4 then px = math.max(4, (sw - w) / 2) end
    local py = y - (h / 2)
    if py + h > sh - 4 then py = sh - h - 4 end
    if py < 4 then py = 4 end

    cp:ClearAllPoints()
    cp:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", px, py)
end

function W.CreateColorPicker(parent, text, color, yOffset, callback)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(30)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -16, yOffset)

    local lbl = frame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, "")
    lbl:SetPoint("LEFT", 0, 0)
    SC(lbl, T.text)
    lbl:SetText(text)

    local swatch = CreateFrame("Button", nil, frame, "BackdropTemplate")
    swatch:SetSize(26, 18)
    swatch:SetPoint("RIGHT", 0, 0)
    swatch:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    swatch:SetBackdropColor(color.r, color.g, color.b, 1)
    swatch:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)

    local rgbTxt = frame:CreateFontString(nil, "OVERLAY")
    rgbTxt:SetFont(FONT, 9, "")
    rgbTxt:SetPoint("RIGHT", swatch, "LEFT", -6, 0)
    SC(rgbTxt, T.textDim)

    local function UpdateDisplay(r, g, b)
        swatch:SetBackdropColor(r, g, b, 1)
        rgbTxt:SetText(string.format("%d/%d/%d", r*255, g*255, b*255))
    end
    UpdateDisplay(color.r, color.g, color.b)

    swatch:SetScript("OnClick", function()
        local prev = { color.r, color.g, color.b }
        local function OnChanged()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            color.r, color.g, color.b = r, g, b
            UpdateDisplay(r, g, b)
            if callback then callback(r, g, b) end
        end
        local function OnCancel()
            color.r, color.g, color.b = prev[1], prev[2], prev[3]
            UpdateDisplay(prev[1], prev[2], prev[3])
            if callback then callback(prev[1], prev[2], prev[3]) end
        end
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc = OnChanged, cancelFunc = OnCancel,
                r = color.r, g = color.g, b = color.b, hasOpacity = false,
            })
        else
            ColorPickerFrame:SetColorRGB(color.r, color.g, color.b)
            ColorPickerFrame.hasOpacity = false
            ColorPickerFrame.func       = OnChanged
            ColorPickerFrame.cancelFunc = OnCancel
            ColorPickerFrame:Hide(); ColorPickerFrame:Show()
        end
        -- after Show(), so the frame has a real size to place and clamp
        RaiseColorPicker()
        PlaceColorPicker(swatch)
    end)
    swatch:SetScript("OnEnter", function()
        swatch:SetBackdropBorderColor(T.borderLight[1], T.borderLight[2], T.borderLight[3], 1)
    end)
    swatch:SetScript("OnLeave", function()
        swatch:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)
    end)

    frame.UpdateColor = function(_, r, g, b)
        color.r, color.g, color.b = r, g, b; UpdateDisplay(r, g, b)
    end
    if W._RegisterSearchEntry then W._RegisterSearchEntry(text, frame, "option") end

    return frame, yOffset - 32
end

-- =====================================================================
-- TWO-COLUMN ROW  [NEW]  — place two slim items side by side
-- Usage: local _, ny = W.CreateTwoColumnRow(c, y, builderLeft, builderRight)
-- Each builder: function(container) -> yOffset after
-- =====================================================================
function W.CreateTwoColumnRow(parent, yOffset, builderLeft, builderRight)
    local ROW_H = 36
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(ROW_H)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -16, yOffset)

    local leftCol = CreateFrame("Frame", nil, frame)
    leftCol:SetPoint("TOPLEFT",  0, 0)
    leftCol:SetPoint("TOPRIGHT", frame, "TOP", -4, 0)
    leftCol:SetHeight(ROW_H)

    local rightCol = CreateFrame("Frame", nil, frame)
    rightCol:SetPoint("TOPLEFT",  frame, "TOP", 4, 0)
    rightCol:SetPoint("TOPRIGHT", 0, 0)
    rightCol:SetHeight(ROW_H)

    local ny_l, ny_r = 0, 0
    if builderLeft  then ny_l = builderLeft(leftCol)   end
    if builderRight then ny_r = builderRight(rightCol)  end

    local usedH = math.max(math.abs(ny_l), math.abs(ny_r), ROW_H)
    frame:SetHeight(usedH)
    leftCol:SetHeight(usedH)
    rightCol:SetHeight(usedH)
    return frame, yOffset - usedH - 4
end

-- =====================================================================
-- COMPOSITE ROWS  [Lot W1]
-- Generic N-column row + sugar built on top of the base widgets.
-- Columns are laid out by ratio via OnSizeChanged, so rows follow the
-- resizable window live.
-- =====================================================================

-- builders: array of function(col) -> usedY (same contract as
-- CreateTwoColumnRow). splits: optional array of relative widths
-- (defaults to equal columns). Never pass nil holes in builders; use
-- function() return 0 end for an empty cell.
function W.CreateColumnRow(parent, yOffset, builders, splits)
    local ROW_H = 36
    local GAP   = 8
    local n = #builders

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(ROW_H)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -16, yOffset)

    local total = 0
    for i = 1, n do
        total = total + ((splits and splits[i]) or 1)
    end

    local cols = {}
    for i = 1, n do
        cols[i] = CreateFrame("Frame", nil, frame)
        cols[i]:SetHeight(ROW_H)
    end

    local function Relayout()
        local fw = frame:GetWidth()
        if not fw or fw <= 0 then return end
        local x = 0
        for i = 1, n do
            local ratio = ((splits and splits[i]) or 1) / total
            local w     = fw * ratio
            local padL  = (i > 1) and (GAP / 2) or 0
            local padR  = (i < n) and (GAP / 2) or 0
            local col   = cols[i]
            col:ClearAllPoints()
            col:SetPoint("TOPLEFT", frame, "TOPLEFT", x + padL, 0)
            col:SetWidth(math.max(1, w - padL - padR))
            x = x + w
        end
    end
    Relayout()
    frame:SetScript("OnSizeChanged", Relayout)

    local used = ROW_H
    for i = 1, n do
        local ny = builders[i] and builders[i](cols[i]) or 0
        used = math.max(used, math.abs(ny or 0))
    end
    frame:SetHeight(used)
    for i = 1, n do cols[i]:SetHeight(used) end
    frame.cols = cols
    return frame, yOffset - used - 4
end

function W.CreateThreeColumnRow(parent, yOffset, builderA, builderB, builderC, splits)
    return W.CreateColumnRow(parent, yOffset, { builderA, builderB, builderC }, splits)
end

-- defs a/b/c: { text=, value=, min=, max=, step=, callback=, fmt= }
-- A nil def leaves its cell empty (grid alignment kept).
function W.CreateTripleSlider(parent, yOffset, a, b, c)
    local defs, frames, builders = { a, b, c }, {}, {}
    for i = 1, 3 do
        local def = defs[i]
        builders[i] = function(col)
            if not def then return 0 end
            local f, ny = W.CreateSlider(col, def.text, def.value, def.min, def.max,
                def.step or 1, 0, def.callback, def.fmt)
            frames[i] = f
            return ny
        end
    end
    local row, ny = W.CreateColumnRow(parent, yOffset, builders)
    row.sliders = frames
    return row, ny
end

-- defs a/b/c: { text=, options=, selected=, callback= }
function W.CreateTripleDropdown(parent, yOffset, a, b, c)
    local defs, frames, builders = { a, b, c }, {}, {}
    for i = 1, 3 do
        local def = defs[i]
        builders[i] = function(col)
            if not def then return 0 end
            local f, ny = W.CreateDropdown(col, def.text, def.options, def.selected, 0, def.callback)
            frames[i] = f
            return ny
        end
    end
    local row, ny = W.CreateColumnRow(parent, yOffset, builders)
    row.dropdowns = frames
    return row, ny
end

-- Dropdown + sliders X/Y sur une seule rangee.
-- dd: { text=, options=, selected=, callback= }
-- offX/offY: { text=, value=, min=, max=, step=, callback=, fmt= } (nil = cellule vide)
function W.CreateDropdownWithOffsets(parent, yOffset, dd, offX, offY)
    local ddFrame, xFrame, yFrame
    local row, ny = W.CreateColumnRow(parent, yOffset, {
        function(col)
            local f, n = W.CreateDropdown(col, dd.text, dd.options, dd.selected, 0, dd.callback)
            ddFrame = f
            return n
        end,
        function(col)
            if not offX then return 0 end
            local f, n = W.CreateSlider(col, offX.text, offX.value, offX.min, offX.max,
                offX.step or 1, 0, offX.callback, offX.fmt)
            xFrame = f
            return n
        end,
        function(col)
            if not offY then return 0 end
            local f, n = W.CreateSlider(col, offY.text, offY.value, offY.min, offY.max,
                offY.step or 1, 0, offY.callback, offY.fmt)
            yFrame = f
            return n
        end,
    }, { 1.2, 1, 1 })
    row.dropdown, row.sliderX, row.sliderY = ddFrame, xFrame, yFrame
    return row, ny
end

-- swatches: array de { text=, color= (table {r,g,b} mutee en place), callback= }
function W.CreateMultiSwatchRow(parent, yOffset, swatches)
    local frames, builders = {}, {}
    for i = 1, #swatches do
        local def = swatches[i]
        builders[i] = function(col)
            local f, ny = W.CreateColorPicker(col, def.text, def.color, 0, def.callback)
            frames[i] = f
            return ny
        end
    end
    local row, ny = W.CreateColumnRow(parent, yOffset, builders)
    row.pickers = frames
    return row, ny
end

-- =====================================================================
-- REORDER DROPDOWN  [Lot W2]
-- Menu persistant : checkbox + fleches pour activer et reordonner des
-- elements d'affichage. items = tableau ORDONNE de { key=, text=,
-- checked= } ; il est mute en place et callback(items) est appele
-- apres chaque changement (coche ou ordre).
-- =====================================================================
function W.CreateReorderDropdown(parent, text, items, yOffset, callback)
    local r, g, b = Accent(parent)
    local ITEM_H = 24

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(46)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -16, yOffset)

    local lbl = frame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, "")
    lbl:SetPoint("TOPLEFT", 0, 0)
    SC(lbl, T.text)
    lbl:SetText(text)

    local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    btn:SetHeight(24)
    btn:SetPoint("TOPLEFT",  0, -18)
    btn:SetPoint("TOPRIGHT", 0, -18)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(T.bgLight[1], T.bgLight[2], T.bgLight[3], 1)
    btn:SetBackdropBorderColor(r, g, b, 0.34)

    local btnTxt = btn:CreateFontString(nil, "OVERLAY")
    btnTxt:SetFont(FONT, 11, "")
    btnTxt:SetPoint("LEFT", 8, 0)
    btnTxt:SetPoint("RIGHT", -22, 0)
    btnTxt:SetJustifyH("LEFT")
    btnTxt:SetWordWrap(false)
    SC(btnTxt, T.text)

    -- Arrow: drawn chevron (two rotated strokes) -- texture-independent,
    -- the old Interface\\Buttons\\Arrow-Down-Down renders as a grey box in 12.x
    local arrowL = btn:CreateTexture(nil, "OVERLAY")
    arrowL:SetSize(8, 2)
    arrowL:SetPoint("RIGHT", -13, 0)
    arrowL:SetRotation(-0.6)
    local arrowR = btn:CreateTexture(nil, "OVERLAY")
    arrowR:SetSize(8, 2)
    arrowR:SetPoint("RIGHT", -7, 0)
    arrowR:SetRotation(0.6)
    arrowL:SetColorTexture(1, 1, 1, 1)
    arrowR:SetColorTexture(1, 1, 1, 1)
    SC(arrowL, T.textDim)
    SC(arrowR, T.textDim)

    local function Summary()
        local on, names = 0, {}
        for _, it in ipairs(items) do
            if it.checked then
                on = on + 1
                if #names < 3 then names[#names + 1] = it.text end
            end
        end
        if on == 0 then return "\226\128\148" end
        local s = table.concat(names, ", ")
        if on > #names then s = s .. "  +" .. (on - #names) end
        return s
    end
    btnTxt:SetText(Summary())

    local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    menu:EnableMouse(true)
    menu:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    menu:SetBackdropColor(T.bgMid[1], T.bgMid[2], T.bgMid[3], 1)
    menu:SetBackdropBorderColor(r, g, b, 0.45)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(9000)
    menu:SetToplevel(true)
    if menu.SetClampedToScreen then menu:SetClampedToScreen(true) end
    menu:Hide()

    local rows = {}
    local Rebuild

    local function IndexOf(it)
        for i, v in ipairs(items) do
            if v == it then return i end
        end
    end

    local function Notify()
        if callback then callback(items) end
    end

    Rebuild = function()
        menu:SetHeight(#items * ITEM_H + 6)
        for i, it in ipairs(items) do
            local row = rows[i]
            if not row then
                row = CreateFrame("Frame", nil, menu)
                row:SetHeight(ITEM_H)

                row.hl = row:CreateTexture(nil, "BACKGROUND")
                row.hl:SetAllPoints()
                row.hl:SetColorTexture(1, 1, 1, 0)

                row.check = CreateFrame("Button", nil, row, "BackdropTemplate")
                row.check:SetSize(14, 14)
                row.check:SetPoint("LEFT", 6, 0)
                row.check:SetBackdrop({
                    bgFile   = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 1,
                })
                row.check:SetScript("OnClick", function(self)
                    local it2 = self:GetParent().item
                    if not it2 then return end
                    it2.checked = not it2.checked
                    Rebuild()
                    Notify()
                end)

                row.label = row:CreateFontString(nil, "OVERLAY")
                row.label:SetFont(FONT, 11, "")
                row.label:SetPoint("LEFT", row.check, "RIGHT", 7, 0)
                row.label:SetPoint("RIGHT", -42, 0)
                row.label:SetJustifyH("LEFT")
                row.label:SetWordWrap(false)

                local function MakeArrow(txt, dx)
                    local a = CreateFrame("Button", nil, row)
                    a:SetSize(16, 16)
                    a:SetPoint("RIGHT", dx, 0)
                    a.t = a:CreateFontString(nil, "OVERLAY")
                    a.t:SetFont(FONT_BOLD, 9, "")
                    a.t:SetPoint("CENTER", 0, 0)
                    a.t:SetText(txt)
                    SC(a.t, T.textDim)
                    a:SetScript("OnEnter", function(self) SC(self.t, T.accent) end)
                    a:SetScript("OnLeave", function(self) SC(self.t, T.textDim) end)
                    return a
                end
                row.up   = MakeArrow("\226\150\178", -22)
                row.down = MakeArrow("\226\150\188", -5)
                row.up:SetScript("OnClick", function(self)
                    local it2 = self:GetParent().item
                    local idx = it2 and IndexOf(it2)
                    if idx and idx > 1 then
                        items[idx], items[idx - 1] = items[idx - 1], items[idx]
                        Rebuild()
                        Notify()
                    end
                end)
                row.down:SetScript("OnClick", function(self)
                    local it2 = self:GetParent().item
                    local idx = it2 and IndexOf(it2)
                    if idx and idx < #items then
                        items[idx], items[idx + 1] = items[idx + 1], items[idx]
                        Rebuild()
                        Notify()
                    end
                end)

                row:SetScript("OnEnter", function(self) self.hl:SetColorTexture(1, 1, 1, 0.05) end)
                row:SetScript("OnLeave", function(self) self.hl:SetColorTexture(1, 1, 1, 0) end)
                rows[i] = row
            end
            row.item = it
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT",  3, -(i - 1) * ITEM_H - 3)
            row:SetPoint("TOPRIGHT", -3, -(i - 1) * ITEM_H - 3)
            row.label:SetText(it.text or tostring(it.key))
            if it.checked then
                row.check:SetBackdropColor(T.accent[1], T.accent[2], T.accent[3], 0.85)
                row.check:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 1)
                SC(row.label, T.text)
            else
                row.check:SetBackdropColor(T.bgLight[1], T.bgLight[2], T.bgLight[3], 1)
                row.check:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)
                SC(row.label, T.textDim)
            end
            row.up:SetShown(i > 1)
            row.down:SetShown(i < #items)
            row:Show()
        end
        for i = #items + 1, #rows do
            rows[i]:Hide()
            rows[i].item = nil
        end
        btnTxt:SetText(Summary())
    end

    btn:SetScript("OnClick", function()
        if menu:IsShown() then
            menu:Hide()
            if W._openDropdown == menu then W._openDropdown = nil end
            btn:SetBackdropBorderColor(r, g, b, 0.34)
        else
            W.CloseDropdowns()
            W._openDropdown = menu
            Rebuild()
            menu:ClearAllPoints()
            menu:SetPoint("TOPLEFT",  btn, "BOTTOMLEFT",  0, -2)
            menu:SetPoint("TOPRIGHT", btn, "BOTTOMRIGHT", 0, -2)
            menu:SetFrameStrata("TOOLTIP")
            menu:SetFrameLevel(9000)
            menu:Show()
            btn:SetBackdropBorderColor(r, g, b, 0.70)
        end
    end)
    btn:SetScript("OnEnter", function()
        btn:SetBackdropBorderColor(T.borderLight[1], T.borderLight[2], T.borderLight[3], 1)
    end)
    btn:SetScript("OnLeave", function()
        if not menu:IsShown() then
            btn:SetBackdropBorderColor(r, g, b, 0.34)
        end
    end)

    frame.SetItems = function(_, newItems)
        items = newItems or {}
        Rebuild()
    end
    frame.GetItems = function() return items end
    frame:SetScript("OnHide", function()
        menu:Hide()
        if W._openDropdown == menu then W._openDropdown = nil end
    end)
    if W._RegisterSearchEntry then W._RegisterSearchEntry(text, frame, "option") end

    return frame, yOffset - 48
end

-- =====================================================================
-- TAB PANEL
-- =====================================================================
function W.CreateTabPanel(parent, tabs, initialTab)
    -- A nested tab panel is always created from inside its parent's builder,
    -- so at this exact moment the parent's key is already on the path: the
    -- length of the path IS this panel's depth.
    local ownerPath = W._CaptureTabPath()
    local level     = #ownerPath + 1

    local r, g, b = Accent(parent)
    local wrapper = CreateFrame("Frame", nil, parent)
    wrapper:SetAllPoints()
    wrapper._muiDesign = FindDesign(parent)

    local TABS_PER_ROW = 6
    local totalTabs    = #tabs
    local numRows      = math.ceil(totalTabs / TABS_PER_ROW)
    local TAB_H        = 32

    -- Tab bar
    local tabBar = CreateFrame("Frame", nil, wrapper)
    tabBar:SetPoint("TOPLEFT")
    tabBar:SetPoint("TOPRIGHT")
    tabBar:SetHeight(TAB_H * numRows)

    local tabBarBg = tabBar:CreateTexture(nil, "BACKGROUND")
    tabBarBg:SetAllPoints()
    tabBarBg:SetColorTexture(0.052, 0.052, 0.066, 1)

    local tabBarBtm = tabBar:CreateTexture(nil, "ARTWORK")
    tabBarBtm:SetHeight(1)
    tabBarBtm:SetPoint("BOTTOMLEFT")
    tabBarBtm:SetPoint("BOTTOMRIGHT")
    tabBarBtm:SetColorTexture(r, g, b, 0.28)

    -- Content
    local content = CreateFrame("Frame", nil, wrapper)
    content:SetPoint("TOPLEFT",     0, -(TAB_H * numRows))
    content:SetPoint("BOTTOMRIGHT", 0, 0)
    content._muiDesign = FindDesign(parent)

    local tabButtons = {}
    local tabButtonList = {}
    local tabPanels  = {}
    local currentTab = nil

    local function GetPanelWidth()
        local w = parent:GetWidth() or wrapper:GetWidth() or 1030
        if not w or w < 60 then w = 1030 end
        return w
    end

    -- [Lot C] Tabs are cached: switching hides the current panel instead
    -- of destroying it; revisiting re-shows the cached panel as-is.
    local function HideCurrent()
        if W.CloseDropdowns then W.CloseDropdowns() end
        local cur = currentTab and tabPanels[currentTab]
        if cur and cur.Hide then pcall(cur.Hide, cur) end
    end

    local function SwitchTab(key)
        HideCurrent()

        for k, btn in pairs(tabButtons) do
            if k == key then
                btn.indicator:Show()
                btn.bg:SetColorTexture(r, g, b, 0.13)
                btn.lbl:SetTextColor(r, g, b, 1)
            else
                btn.indicator:Hide()
                btn.bg:SetColorTexture(0, 0, 0, 0)
                SC(btn.lbl, T.textDim)
            end
        end

        if not tabPanels[key] then
            for _, tab in ipairs(tabs) do
                if tab.key == key and tab.builder then
                    -- Re-establish ancestors: this tab may be opened long
                    -- after the page was built, when the live path has
                    -- moved on to some other category.
                    if W._RestoreTabPath then W._RestoreTabPath(ownerPath) end
                    if W._SetBuildTabAt then W._SetBuildTabAt(level, tab.key, tab.label) end
                    local p = tab.builder(content)
                    if p then
                        if p:GetParent() ~= content then p:SetParent(content) end
                        p:SetAllPoints(content)
                        tabPanels[key] = p
                    end
                    break
                end
            end
        end

        if tabPanels[key] then tabPanels[key]:Show() end
        currentTab = key

        -- [Lot A] Tab panels are built lazily, so sections tagged inside
        -- this tab only enter the registry now.
        if W.ApplyRoleFilter then W.ApplyRoleFilter() end
    end

    local tabsInRow1 = math.min(totalTabs, TABS_PER_ROW)
    for i, tab in ipairs(tabs) do
        local row  = math.floor((i - 1) / TABS_PER_ROW)
        local col  = (i - 1) % TABS_PER_ROW
        local tpR  = math.min(TABS_PER_ROW, totalTabs - row * TABS_PER_ROW)
        local tW   = math.floor(GetPanelWidth() / tpR)

        local btn = CreateFrame("Button", nil, tabBar)
        btn:SetSize(tW, TAB_H)
        btn:SetPoint("TOPLEFT", col * tW, -(row * TAB_H))

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(); bg:SetColorTexture(0, 0, 0, 0)
        btn.bg = bg

        -- Bottom indicator line
        local ind = btn:CreateTexture(nil, "ARTWORK")
        ind:SetHeight(2)
        ind:SetPoint("BOTTOMLEFT",  3, 0)
        ind:SetPoint("BOTTOMRIGHT", -3, 0)
        ind:SetColorTexture(r, g, b, 1)
        ind:Hide()
        btn.indicator = ind

        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT, 11, "")
        lbl:SetPoint("CENTER", 0, 1)
        SC(lbl, T.textDim)
        lbl:SetText(tab.label)
        btn.lbl = lbl

        btn:SetScript("OnEnter", function()
            if currentTab ~= tab.key then
                bg:SetColorTexture(r, g, b, 0.08)
                SC(lbl, T.text)
            end
        end)
        btn:SetScript("OnLeave", function()
            if currentTab ~= tab.key then
                bg:SetColorTexture(0, 0, 0, 0)
                SC(lbl, T.textDim)
            end
        end)
        btn:SetScript("OnClick", function() SwitchTab(tab.key) end)
        tabButtons[tab.key] = btn
        tabButtonList[#tabButtonList + 1] = btn
    end

    local function RelayoutTabs()
        for i, btn in ipairs(tabButtonList) do
            local row = math.floor((i - 1) / TABS_PER_ROW)
            local col = (i - 1) % TABS_PER_ROW
            local tpR = math.min(TABS_PER_ROW, totalTabs - row * TABS_PER_ROW)
            local tW  = math.floor(GetPanelWidth() / tpR)
            btn:SetSize(tW, TAB_H)
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", col * tW, -(row * TAB_H))
        end
    end
    tabBar:SetScript("OnSizeChanged", RelayoutTabs)

    -- [fix] honor the requested initial tab (tab persistence); fall back
    -- to the first tab when absent or unknown.
    -- A pending deep-link path wins: it names one tab per level, and this
    -- panel only ever reads its own.
    local pending = TomoMod_Config and TomoMod_Config._pendingTabPath
    local wanted  = pending and pending[level]
    if wanted then
        for _, tab in ipairs(tabs) do
            if tab.key == wanted then initialTab = wanted break end
        end
    end

    local startKey = tabs[1] and tabs[1].key
    if initialTab then
        for _, tab in ipairs(tabs) do
            if tab.key == initialTab then startKey = initialTab break end
        end
    end
    if startKey then SwitchTab(startKey) end
    wrapper.SwitchTab = SwitchTab
    wrapper.HasTab    = function(key) return key ~= nil and tabButtons[key] ~= nil end
    wrapper.content   = content
    wrapper:SetScript("OnHide", function()
        if W.CloseDropdowns then W.CloseDropdowns() end
    end)
    wrapper:SetScript("OnShow", function()
        if currentTab then
            SwitchTab(currentTab)
        elseif #tabs > 0 then
            SwitchTab(tabs[1].key)
        end
    end)
    return wrapper
end

-- =====================================================================
-- MULTI-LINE EDITBOX
-- =====================================================================
function W.CreateMultiLineEditBox(parent, labelText, height, yOffset, opts)
    opts = opts or {}
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT",  10, yOffset)
    container:SetPoint("TOPRIGHT", -10, yOffset)
    container:SetHeight(height + 28)

    if labelText and labelText ~= "" then
        local lbl = container:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT, 11, "")
        lbl:SetPoint("TOPLEFT", 0, 0)
        SC(lbl, T.text)
        lbl:SetText(labelText)
        container.label = lbl
    end

    local bg = container:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT",  0, -20)
    bg:SetPoint("BOTTOMRIGHT", 0, 0)
    bg:SetColorTexture(T.bgDark[1], T.bgDark[2], T.bgDark[3], 1)

    local bd = CreateFrame("Frame", nil, container, "BackdropTemplate")
    bd:SetPoint("TOPLEFT",  -1, -19)
    bd:SetPoint("BOTTOMRIGHT", 1, -1)
    bd:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    bd:SetBackdropBorderColor(T.border[1], T.border[2], T.border[3], 1)

    -- Plain ScrollFrame (no UIPanelScrollFrameTemplate) so we don't inherit the
    -- default gold arrows / Blizzard scrollbar. We draw our own thin scrollbar
    -- to match CreateScrollPanel.
    local scrollFrame = CreateFrame("ScrollFrame", nil, container)
    scrollFrame:SetPoint("TOPLEFT",  0, -22)
    scrollFrame:SetPoint("BOTTOMRIGHT", -12, 2)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFont(FONT, 10, "")
    editBox:SetTextColor(0.88, 0.90, 0.89, 1)
    editBox:SetWidth(scrollFrame:GetWidth() - 10)
    editBox:SetTextInsets(6, 6, 4, 4)
    scrollFrame:SetScrollChild(editBox)
    scrollFrame:SetScript("OnSizeChanged", function(self, w) editBox:SetWidth(math.max(w - 10, 100)) end)

    if opts.readOnly then
        editBox._readOnlyText = ""
        editBox:SetScript("OnTextChanged", function(self, userInput)
            if userInput then self:SetText(self._readOnlyText); self:HighlightText() end
        end)
        editBox:SetScript("OnMouseUp", function(self) self:HighlightText() end)
        local origST = editBox.SetText
        editBox.SetText = function(self, text) self._readOnlyText = text; origST(self, text) end
    end

    if opts.onTextChanged then
        editBox:SetScript("OnTextChanged", function(self, userInput)
            if userInput then opts.onTextChanged(self:GetText()) end
        end)
    end
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- [style] Home-made thin scrollbar matching CreateScrollPanel (thumb in the
    -- accent color) instead of the Blizzard gold arrows.
    local SBW = 5
    local track = container:CreateTexture(nil, "BACKGROUND")
    track:SetWidth(SBW)
    track:SetPoint("TOPRIGHT",    -2, -24)
    track:SetPoint("BOTTOMRIGHT", -2,  3)
    track:SetColorTexture(0.12, 0.12, 0.16, 0.8)
    local thumbFrame = CreateFrame("Frame", nil, container)
    thumbFrame:SetWidth(SBW)
    thumbFrame:SetPoint("TOPRIGHT", -2, -24)
    local thumb = thumbFrame:CreateTexture(nil, "OVERLAY")
    thumb:SetAllPoints()
    SC(thumb, T.accent)

    local function UpdateSB()
        local range = scrollFrame:GetVerticalScrollRange() or 0
        local viewH = scrollFrame:GetHeight() or 1
        if range <= 0 then thumbFrame:Hide(); track:Hide(); return end
        track:Show(); thumbFrame:Show()
        local trackH = viewH - 3
        local ratio  = viewH / (viewH + range)
        local thumbH = math.max(math.floor(trackH * ratio), 20)
        thumbFrame:SetHeight(thumbH)
        local cur = scrollFrame:GetVerticalScroll() or 0
        local y   = (cur / range) * (trackH - thumbH)
        thumbFrame:SetPoint("TOPRIGHT", -2, -(24 + y))
    end
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local range = self:GetVerticalScrollRange() or 0
        local cur   = self:GetVerticalScroll() or 0
        local step  = 20
        local newv  = cur - delta * step
        if newv < 0 then newv = 0 elseif newv > range then newv = range end
        self:SetVerticalScroll(newv)
    end)
    scrollFrame:SetScript("OnScrollRangeChanged", UpdateSB)
    scrollFrame:SetScript("OnVerticalScroll", UpdateSB)
    scrollFrame:HookScript("OnSizeChanged", UpdateSB)

    container.editBox    = editBox
    container.scrollFrame = scrollFrame
    return container, yOffset - (height + 32)
end

-- =====================================================================
-- CHECKBOX PAIR  — two checkboxes side by side  [NEW]
-- Usage: local _, ny = W.CreateCheckboxPair(c,
--            "Label A", valA, y, cbA,
--            "Label B", valB, cbB)
-- =====================================================================
function W.CreateCheckboxPair(parent, textA, valA, yOffset, cbA, textB, valB, cbB)
    local _, ny = W.CreateTwoColumnRow(parent, yOffset,
        function(col)
            local _, ny2 = W.CreateCheckbox(col, textA, valA, 0, cbA)
            return ny2
        end,
        function(col)
            local _, ny2 = W.CreateCheckbox(col, textB, valB, 0, cbB)
            return ny2
        end)
    return nil, ny
end

-- =====================================================================
-- COLOR PICKER PAIR  — two color pickers side by side  [NEW]
-- =====================================================================
function W.CreateColorPickerPair(parent, textA, colorA, textB, colorB, yOffset, cbA, cbB)
    local _, ny = W.CreateTwoColumnRow(parent, yOffset,
        function(col)
            local _, ny2 = W.CreateColorPicker(col, textA, colorA, 0, cbA)
            return ny2
        end,
        function(col)
            local _, ny2 = W.CreateColorPicker(col, textB, colorB, 0, cbB)
            return ny2
        end)
    return nil, ny
end

-- =====================================================================
-- CENTERED BUTTON GROUP  — multiple buttons in a horizontal row  [NEW]
-- buttons = { { text, width, cb }, ... }
-- =====================================================================
function W.CreateButtonRow(parent, buttons, yOffset)
    local r, g, blue = Accent(parent)
    local GAP   = 10
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(32)
    frame:SetPoint("TOPLEFT",  16, yOffset)
    frame:SetPoint("TOPRIGHT", -16, yOffset)

    local totalW = 0
    for _, def in ipairs(buttons) do totalW = totalW + (def.width or 140) + GAP end
    totalW = totalW - GAP

    local x = 0
    for _, def in ipairs(buttons) do
        local w = def.width or 140
        local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        btn:SetSize(w, 28)
        btn:SetPoint("LEFT", x, 0)
        btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })

        btn:SetBackdropColor(r * 0.20, g * 0.16, blue * 0.22, 0.9)
        btn:SetBackdropBorderColor(r, g, blue, 0.60)

        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf", 11, "")
        lbl:SetPoint("CENTER")
        lbl:SetText(def.text)
        lbl:SetTextColor(1, 1, 1, 1)

        btn:SetScript("OnEnter", function()
            btn:SetBackdropColor(r, g, blue, 1)
            lbl:SetTextColor(0.06, 0.06, 0.08, 1)
        end)
        btn:SetScript("OnLeave", function()
            btn:SetBackdropColor(r * 0.20, g * 0.16, blue * 0.22, 0.9)
            lbl:SetTextColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnClick", function()
            local fn = def.cb or def.callback
            if fn then fn() end
        end)

        x = x + w + GAP
    end

    return frame, yOffset - 38
end

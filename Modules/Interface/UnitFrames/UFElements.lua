-- =====================================================================
-- UFElements.lua -- AstralForge descriptors for the "unitframe" domain
-- Declares the anchorable hosts and the positionable elements of a
-- TomoMod unit frame. Every default below reproduces EXACTLY the anchor
-- that was hard-coded in the engine before the registry existed, so a
-- fresh profile and a migrated profile render identically.
--
-- Not registered on purpose:
--   * castbar -- lives in its own module with its own mover.
--
-- The two aura containers ARE registered. They used to keep their own
-- position under settings.auras.position, written by the Movers drag --
-- the last place in this domain with a second source of truth for where
-- something sits. The drag now writes an element record like everything
-- else, so a container can be placed from the studio, from the drag, or
-- from the config sliders and all three agree.
-- =====================================================================

local Forge = TomoMod_Forge
if not Forge or not Forge.Registry then return end

local R = Forge.Registry

TomoMod_UFElements = TomoMod_UFElements or {}
local UFE = TomoMod_UFElements

UFE.DOMAIN = "unitframe"
local DOMAIN = UFE.DOMAIN

-- ---------------------------------------------------------------------
-- Hosts
-- ---------------------------------------------------------------------
R.DefineHost(DOMAIN, {
    id       = "frame",
    labelKey = "anchor_host_frame",
    resolve  = function(frame) return frame end,
})

R.DefineHost(DOMAIN, {
    id       = "health",
    labelKey = "anchor_host_health",
    resolve  = function(frame) return frame and frame.health end,
})

R.DefineHost(DOMAIN, {
    id       = "power",
    labelKey = "anchor_host_power",
    resolve  = function(frame) return frame and frame.power end,
})

R.DefineHost(DOMAIN, {
    id       = "infoBar",
    labelKey = "anchor_host_infobar",
    resolve  = function(frame) return frame and frame.infoBar end,
})

-- ---------------------------------------------------------------------
-- Elements
-- ---------------------------------------------------------------------

-- Legacy: health.nameText:SetPoint("LEFT", x, y)  -- 2-arg form anchors
-- to the parent at the same point, i.e. LEFT of the health bar.
R.Define(DOMAIN, {
    id         = "name",
    kind       = "fontstring",
    labelKey   = "elem_name",
    order      = 10,
    anchorMode = "inside",
    default    = { point = "LEFT", relTo = "health", relPoint = "LEFT", x = 6, y = 0 },
    resolve    = function(frame) return frame and frame.health and frame.health.nameText end,
})

R.Define(DOMAIN, {
    id         = "level",
    kind       = "fontstring",
    labelKey   = "elem_level",
    order      = 20,
    anchorMode = "inside",
    default    = { point = "RIGHT", relTo = "health", relPoint = "RIGHT", x = -6, y = 0 },
    resolve    = function(frame) return frame and frame.health and frame.health.levelText end,
})

R.Define(DOMAIN, {
    id         = "healthText",
    kind       = "fontstring",
    labelKey   = "elem_health_text",
    order      = 30,
    anchorMode = "inside",
    default    = { point = "CENTER", relTo = "health", relPoint = "CENTER", x = 0, y = 0 },
    resolve    = function(frame) return frame and frame.health and frame.health.text end,
})

-- The power bar hangs UNDER the health bar. Its target whitelist is a real
-- safety rail, not a style choice: BuildVisuals anchors the info bar to
-- `self.power or health`, so letting power anchor BACK to the info bar
-- would close an anchor family and make the client raise an error on the
-- next layout pass. That edge lives in the engine, where the registry's
-- cycle walk cannot see it -- hence a static whitelist rather than a
-- dynamic check.
R.Define(DOMAIN, {
    id         = "power",
    kind       = "frame",
    labelKey   = "elem_power",
    order      = 40,
    anchorMode = "fixed",
    targets    = { "frame", "health" },
    default    = { point = "TOP", relTo = "health", relPoint = "BOTTOM", x = 0, y = 0 },
    resolve    = function(frame) return frame and frame.power end,
})

R.Define(DOMAIN, {
    id         = "raidIcon",
    kind       = "texture",
    labelKey   = "elem_raid_icon",
    order      = 50,
    anchorMode = "fixed",
    default    = { point = "BOTTOM", relTo = "health", relPoint = "TOP", x = 0, y = 2 },
    resolve    = function(frame) return frame and frame.health and frame.health.raidIcon end,
})

R.Define(DOMAIN, {
    id         = "leaderIcon",
    kind       = "texture",
    labelKey   = "elem_leader_icon",
    order      = 60,
    anchorMode = "fixed",
    default    = { point = "BOTTOMLEFT", relTo = "health", relPoint = "TOPLEFT", x = -2, y = 0 },
    resolve    = function(frame) return frame and frame.health and frame.health.leaderIcon end,
})

-- Historically anchored from settings.auras.position, which the drag wrote
-- with a CENTER/CENTER delta -- exactly the shape of an element record.
R.Define(DOMAIN, {
    id         = "auras",
    kind       = "frame",
    labelKey   = "elem_auras",
    order      = 65,
    anchorMode = "fixed",
    default    = { point = "BOTTOMLEFT", relTo = "frame", relPoint = "TOPLEFT", x = 0, y = 6 },
    resolve    = function(frame) return frame and frame.auraContainer end,
})

R.Define(DOMAIN, {
    id         = "enemyBuffs",
    kind       = "frame",
    labelKey   = "elem_enemy_buffs",
    order      = 66,
    anchorMode = "fixed",
    default    = { point = "BOTTOMRIGHT", relTo = "frame", relPoint = "TOPRIGHT", x = 0, y = 6 },
    resolve    = function(frame) return frame and frame.enemyBuffContainer end,
})

R.Define(DOMAIN, {
    id         = "threatText",
    kind       = "fontstring",
    labelKey   = "elem_threat_text",
    order      = 70,
    anchorMode = "inside",
    default    = { point = "CENTER", relTo = "health", relPoint = "CENTER", x = 0, y = 0 },
    resolve    = function(frame) return frame and frame.threatText end,
})

-- ---------------------------------------------------------------------
-- Instanced type: custom text
--
-- The user adds these; the registry builds them. The template is written
-- with square-bracket tokens, e.g. "[name] - [level]".
--
-- SECRET VALUES -- the reason this is a format engine and not a
-- concatenation. UnitName returns a SECRET STRING in Midnight, and Lua
-- must never touch one: `"a" .. UnitName(u)` errors. So the template is
-- compiled into a format string plus an ordered argument list, and the
-- secret values go straight into SetFormattedText, which resolves them
-- C-side. That is the same trick UpdateName already uses.
--
-- Only identity tokens are offered. Health and power are deliberately
-- absent: a raw value could be passed through safely, but the token people
-- actually want is a percentage, and that needs a division -- arithmetic on
-- a secret value, which is forbidden. The existing health text element
-- already does percentages through the status bar's C-side methods, and
-- that is where they stay.
-- ---------------------------------------------------------------------

UFE.TOKENS = {
    { token = "name",  fmt = "%s", labelKey = "token_name" },
    { token = "level", fmt = "%s", labelKey = "token_level" },
    { token = "class", fmt = "%s", labelKey = "token_class" },
    { token = "race",  fmt = "%s", labelKey = "token_race" },
    { token = "guild", fmt = "%s", labelKey = "token_guild" },
}

-- Le compilateur vit dans Forge.Text : il est partage avec le domaine
-- plaques de nom, pour que la partie risquee (ne jamais toucher une valeur
-- secrete en Lua) n'existe qu'a un seul endroit.
local TOKEN_FMT = Forge.Text and Forge.Text.CompileTokens(UFE.TOKENS) or {}

local function TokenValue(token, unit)
    if token == "name"  then return UnitName(unit) end
    if token == "level" then return UnitLevel(unit) end
    if token == "class" then
        -- [12.1] The display name can be secret, and a tag value is
        -- concatenated downstream. Empty reads better than an error.
        return (TomoMod_Utils and TomoMod_Utils.SafeStr(UnitClass(unit))) or ""
    end
    if token == "race"  then return (UnitRace(unit)) end
    if token == "guild" then return (GetGuildInfo(unit)) end
    return nil
end

-- Compile `template` et le pousse dans `fs`. Renvoie false quand il n'y a
-- rien a afficher, pour que l'appelant vide le widget.
function UFE.RenderCustomText(fs, unit, template)
    if not Forge.Text then return false end
    if not unit or not UnitExists(unit) then return false end
    return Forge.Text.Render(fs, template, TOKEN_FMT, TokenValue, unit)
end

R.DefineInstanced(DOMAIN, {
    id       = "customText",
    kind     = "fontstring",
    labelKey = "elem_custom_text",
    max      = 6,
    default  = {
        point = "CENTER", relTo = "frame", relPoint = "CENTER", x = 0, y = 0,
        text  = "[name]",
    },
    build = function(frame)
        if not frame or not frame.CreateFontString then return nil end
        local fs = frame:CreateFontString(nil, "OVERLAY")
        local db = TomoModDB and TomoModDB.unitFrames
        fs:SetFont(
            (db and db.font) or "Fonts\\FRIZQT__.TTF",
            (db and db.fontSize) or 12,
            (db and db.fontOutline) or "OUTLINE")
        fs:SetTextColor(1, 1, 1, 1)
        return fs
    end,
})

-- Refreshes every custom text on `frame`. Called from the same place the
-- name and level are refreshed, so the tokens track unit changes.
function UFE.RefreshCustomTexts(frame, store)
    if not frame then return 0 end
    local cache = rawget(frame, "_forgeInstances")
    if not cache then return 0 end
    local n = 0
    for _, inst in ipairs(R.ListInstances(DOMAIN, store)) do
        local fs = cache[inst.key]
        if fs and inst.typeID == "customText" then
            local rec = store[inst.key]
            if not UFE.RenderCustomText(fs, frame.unit, rec and rec.text) then
                fs:SetText("")
            end
            n = n + 1
        end
    end
    return n
end

-- ---------------------------------------------------------------------
-- Instanced type: custom status bar
-- ---------------------------------------------------------------------
local BAR_FALLBACK = { r = 0.18, g = 0.62, b = 0.85 }

R.DefineInstanced(DOMAIN, {
    id       = "customBar",
    kind     = "frame",
    labelKey = "af_elem_custom_bar",
    max      = 8,
    fields   = {
        source          = { type = "enum", values = { "health", "power", "static" } },
        width           = { type = "number", min = 20, max = 500 },
        height          = { type = "number", min = 2,  max = 80 },
        colorMode       = { type = "enum", values = { "source", "class", "custom" } },
        color           = { type = "color" },
        backgroundAlpha = { type = "number", min = 0, max = 1 },
        reverse         = { type = "boolean" },
    },
    default = {
        point = "TOPLEFT", relTo = "frame", relPoint = "BOTTOMLEFT", x = 0, y = -8,
        source = "health", width = 180, height = 10,
        colorMode = "source",
        color = { r = 0.18, g = 0.62, b = 0.85 },
        backgroundAlpha = 0.35,
        reverse = false,
    },
    build = function(frame)
        if not frame then return nil end
        local bar = CreateFrame("StatusBar", nil, frame)
        bar:SetSize(180, 10)
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(1)
        bar:EnableMouse(false)

        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bar.bg = bg
        return bar
    end,
})

local function CustomBarTexture()
    local db = TomoModDB and TomoModDB.unitFrames
    return (db and (db.texture or db.statusbarTexture))
        or "Interface\\Buttons\\WHITE8x8"
end

local function PaintCustomBar(frame, bar, rec, source, preview, powerType)
    if not (bar and rec) then return end

    bar:SetSize(rec.width or 180, rec.height or 10)
    if bar.SetReverseFill then bar:SetReverseFill(rec.reverse == true) end

    local tex = CustomBarTexture()
    bar:SetStatusBarTexture(tex)
    if bar.bg then
        bar.bg:SetTexture(tex)
        bar.bg:SetVertexColor(0.035, 0.045, 0.060, rec.backgroundAlpha or 0.35)
    end

    local painted = false
    if rec.colorMode == "custom" then
        local c = rec.color or BAR_FALLBACK
        bar:SetStatusBarColor(c.r or BAR_FALLBACK.r, c.g or BAR_FALLBACK.g,
            c.b or BAR_FALLBACK.b, 1)
        painted = true
    elseif rec.colorMode == "class" and not preview and frame.unit
        and TomoMod_Utils and TomoMod_Utils.ApplyClassColor then
        painted = TomoMod_Utils.ApplyClassColor(bar, frame.unit, "SetStatusBarColor")
    end

    if not painted and rec.colorMode ~= "custom" then
        if source == "power" and frame.power and frame.power.GetStatusBarColor then
            local r, g, b = frame.power:GetStatusBarColor()
            if r then bar:SetStatusBarColor(r, g, b, 1); painted = true end
        elseif source == "power" and powerType ~= nil
            and TomoMod_Utils and TomoMod_Utils.GetPowerColor then
            local r, g, b = TomoMod_Utils.GetPowerColor(powerType)
            if r then bar:SetStatusBarColor(r, g, b, 1); painted = true end
        elseif source == "health" and frame.health and frame.health.GetStatusBarColor then
            local r, g, b = frame.health:GetStatusBarColor()
            if r then bar:SetStatusBarColor(r, g, b, 1); painted = true end
        end
    end

    if not painted then
        bar:SetStatusBarColor(BAR_FALLBACK.r, BAR_FALLBACK.g, BAR_FALLBACK.b, 1)
    end
end

-- Hot-path update for one source. `current` and `maximum` may be Midnight
-- secret numbers: they are passed straight to C-side StatusBar APIs.
function UFE.RefreshCustomBarsSource(frame, store, source, current, maximum, powerType)
    if not frame or type(store) ~= "table" then return 0 end
    local n = 0
    for _, inst in ipairs(R.ListInstances(DOMAIN, store)) do
        if inst.typeID == "customBar" then
            local rec = store[inst.key]
            if rec and rec.source == source then
                local bar = R.ResolveInstance(DOMAIN, inst.key, frame)
                if bar then
                    PaintCustomBar(frame, bar, rec, source, false, powerType)
                    if source == "static" then
                        bar:SetMinMaxValues(0, 1)
                        bar:SetValue(1)
                    else
                        bar:SetMinMaxValues(0, maximum)
                        bar:SetValue(current)
                    end
                    bar:Show()
                    n = n + 1
                end
            end
        end
    end
    return n
end

-- Full refresh used after a style edit / rebuild and by the detached Studio
-- preview. Live health/power events use RefreshCustomBarsSource instead.
function UFE.RefreshCustomBars(frame, store, preview)
    if not frame or type(store) ~= "table" then return 0 end
    local n = 0
    local unit = frame.unit

    for _, inst in ipairs(R.ListInstances(DOMAIN, store)) do
        if inst.typeID == "customBar" then
            local rec = store[inst.key]
            local bar = R.ResolveInstance(DOMAIN, inst.key, frame)
            if rec and bar then
                local source = rec.source or "health"
                if preview then
                    PaintCustomBar(frame, bar, rec, source, true, source == "power" and 0 or nil)
                    bar:SetMinMaxValues(0, 100)
                    bar:SetValue(source == "power" and 64 or (source == "static" and 100 or 78))
                    bar:Show()
                elseif source == "static" then
                    PaintCustomBar(frame, bar, rec, source, false)
                    bar:SetMinMaxValues(0, 1)
                    bar:SetValue(1)
                    bar:Show()
                elseif unit and UnitExists(unit) and source == "health" then
                    local current, maximum = UnitHealth(unit), UnitHealthMax(unit)
                    UFE.RefreshCustomBarsSource(frame, store, "health", current, maximum)
                elseif unit and UnitExists(unit) and source == "power" then
                    local powerType = UnitPowerType(unit) or 0
                    local current, maximum = UnitPower(unit, powerType), UnitPowerMax(unit, powerType)
                    UFE.RefreshCustomBarsSource(frame, store, "power", current, maximum, powerType)
                else
                    bar:Hide()
                end
                n = n + 1
            end
        end
    end
    return n
end

-- ---------------------------------------------------------------------
-- Convenience wrappers (keep the domain string in one place)
-- ---------------------------------------------------------------------
function UFE.List()
    return R.List(DOMAIN)
end

function UFE.ListHosts()
    return R.ListHosts(DOMAIN)
end

function UFE.AllowedTargets(id, store)
    return R.AllowedTargets(DOMAIN, id, store)
end

function UFE.Defaults()
    local out = {}
    for _, desc in ipairs(R.List(DOMAIN)) do
        out[desc.id] = R.Default(DOMAIN, desc.id)
    end
    return out
end

function UFE.Ensure(store)
    return R.Ensure(DOMAIN, store)
end

function UFE.ApplyAll(frame, store)
    return R.ApplyAll(DOMAIN, frame, store)
end

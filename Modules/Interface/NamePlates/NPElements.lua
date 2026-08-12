-- =====================================================================
-- NPElements.lua -- AstralForge descriptors for the "nameplate" domain
-- Declares the anchorable hosts and the positionable elements of a
-- TomoMod nameplate. Every default below reproduces EXACTLY the anchor
-- CreatePlate hard-coded before the registry existed, so a fresh profile
-- and a migrated profile render identically.
--
-- Not registered on purpose -- these are not single positionable widgets
-- and a designer handle over them would lie about what it moves:
--   * auras / enemyBuffs -- arrays whose position is COMPUTED from the
--     index (fan-out, chained). Moving one moves nothing; the layout rule
--     is the thing to edit, which is a later lot.
--   * absorb, highlight, spark, niOverlay, stage markers -- pinned to the
--     health or castbar status bar TEXTURE, so they track fill rather than
--     geometry.
--   * rounded border, target glow, threat border/glow -- 9-slice frames
--     derived from the health bar's own rect.
--   * target arrows -- a mirrored pair derived from the name.
--
-- Anchor cycles: every edge the engine creates between a HOST and an
-- ELEMENT is also represented in the registry graph (health, castbar and
-- name are declared on both sides and resolve to the same widget), so the
-- dynamic cycle walk covers them and no static `targets` whitelist is
-- needed here -- unlike the unit frame domain, where the info bar edge is
-- invisible to the graph.
-- =====================================================================

local Forge = TomoMod_Forge
if not Forge or not Forge.Registry then return end

local R = Forge.Registry

TomoMod_NPElements = TomoMod_NPElements or {}
local NPE = TomoMod_NPElements

NPE.DOMAIN = "nameplate"
local DOMAIN = NPE.DOMAIN

-- ---------------------------------------------------------------------
-- Hosts
-- ---------------------------------------------------------------------
R.DefineHost(DOMAIN, {
    id       = "plate",
    labelKey = "np_host_plate",
    resolve  = function(plate) return plate end,
})

R.DefineHost(DOMAIN, {
    id       = "health",
    labelKey = "np_host_health",
    resolve  = function(plate) return plate and plate.health end,
})

R.DefineHost(DOMAIN, {
    id       = "castbar",
    labelKey = "np_host_castbar",
    resolve  = function(plate) return plate and plate.castbar end,
})

R.DefineHost(DOMAIN, {
    id       = "name",
    labelKey = "np_host_name",
    resolve  = function(plate) return plate and plate.nameText end,
})

-- ---------------------------------------------------------------------
-- Elements
-- ---------------------------------------------------------------------

R.Define(DOMAIN, {
    id         = "name",
    kind       = "fontstring",
    labelKey   = "np_elem_name",
    order      = 10,
    anchorMode = "fixed",
    default    = { point = "BOTTOM", relTo = "health", relPoint = "TOP", x = 0, y = 4 },
    resolve    = function(plate) return plate and plate.nameText end,
})

R.Define(DOMAIN, {
    id         = "hpNumber",
    kind       = "fontstring",
    labelKey   = "np_elem_hp_number",
    order      = 20,
    anchorMode = "inside",
    default    = { point = "CENTER", relTo = "health", relPoint = "CENTER", x = 0, y = 0 },
    resolve    = function(plate) return plate and plate.hpNumber end,
})

R.Define(DOMAIN, {
    id         = "hpPercent",
    kind       = "fontstring",
    labelKey   = "np_elem_hp_percent",
    order      = 30,
    anchorMode = "inside",
    default    = { point = "RIGHT", relTo = "health", relPoint = "RIGHT", x = -4, y = 0 },
    resolve    = function(plate) return plate and plate.hpPercent end,
})

R.Define(DOMAIN, {
    id         = "level",
    kind       = "fontstring",
    labelKey   = "np_elem_level",
    order      = 40,
    anchorMode = "fixed",
    default    = { point = "RIGHT", relTo = "health", relPoint = "LEFT", x = -3, y = 0 },
    resolve    = function(plate) return plate and plate.levelText end,
})

R.Define(DOMAIN, {
    id         = "classIcon",
    kind       = "frame",
    labelKey   = "np_elem_class_icon",
    order      = 50,
    anchorMode = "inside",
    default    = { point = "LEFT", relTo = "health", relPoint = "LEFT", x = 2, y = 0 },
    resolve    = function(plate) return plate and plate.classFrame end,
})

R.Define(DOMAIN, {
    id         = "classText",
    kind       = "fontstring",
    labelKey   = "np_elem_class_text",
    order      = 60,
    anchorMode = "fixed",
    default    = { point = "LEFT", relTo = "health", relPoint = "RIGHT", x = 3, y = 0 },
    resolve    = function(plate) return plate and plate.classText end,
})

R.Define(DOMAIN, {
    id         = "castbar",
    kind       = "frame",
    labelKey   = "np_elem_castbar",
    order      = 70,
    anchorMode = "fixed",
    default    = { point = "TOP", relTo = "health", relPoint = "BOTTOM", x = 0, y = 0 },
    resolve    = function(plate) return plate and plate.castbar end,
})

R.Define(DOMAIN, {
    id         = "castIcon",
    kind       = "frame",
    labelKey   = "np_elem_cast_icon",
    order      = 80,
    anchorMode = "fixed",
    default    = { point = "RIGHT", relTo = "castbar", relPoint = "LEFT", x = 0, y = 0 },
    resolve    = function(plate) return plate and plate.castbar and plate.castbar.iconFrame end,
})

R.Define(DOMAIN, {
    id         = "castText",
    kind       = "fontstring",
    labelKey   = "np_elem_cast_text",
    order      = 90,
    anchorMode = "inside",
    default    = { point = "LEFT", relTo = "castbar", relPoint = "LEFT", x = 5, y = 0 },
    resolve    = function(plate) return plate and plate.castbar and plate.castbar.text end,
})

R.Define(DOMAIN, {
    id         = "castTimer",
    kind       = "fontstring",
    labelKey   = "np_elem_cast_timer",
    order      = 100,
    anchorMode = "inside",
    default    = { point = "RIGHT", relTo = "castbar", relPoint = "RIGHT", x = -3, y = 0 },
    resolve    = function(plate) return plate and plate.castbar and plate.castbar.timer end,
})

R.Define(DOMAIN, {
    id         = "castShield",
    kind       = "frame",
    labelKey   = "np_elem_cast_shield",
    order      = 110,
    anchorMode = "fixed",
    default    = { point = "CENTER", relTo = "castbar", relPoint = "LEFT", x = 0, y = 0 },
    resolve    = function(plate) return plate and plate.castbar and plate.castbar.shieldFrame end,
})

R.Define(DOMAIN, {
    id         = "questIcon",
    kind       = "texture",
    labelKey   = "np_elem_quest_icon",
    order      = 120,
    anchorMode = "fixed",
    default    = { point = "RIGHT", relTo = "name", relPoint = "LEFT", x = -1, y = 0 },
    resolve    = function(plate) return plate and plate.questIcon end,
})

-- Historically driven by raidIconAnchor / raidIconX / raidIconY, which the
-- ufElements-style migration folds into this record.
R.Define(DOMAIN, {
    id         = "raidMarker",
    kind       = "frame",
    labelKey   = "np_elem_raid_marker",
    order      = 130,
    anchorMode = "inside",
    default    = { point = "TOPRIGHT", relTo = "health", relPoint = "TOPRIGHT", x = 2, y = 2 },
    resolve    = function(plate) return plate and plate.raidFrame end,
})

-- ---------------------------------------------------------------------
-- Instanced type: custom text
--
-- Same contract as the unit frame domain, and deliberately the same
-- compiler (Forge.Text): UnitName returns a secret string and
-- UnitEffectiveLevel a secret number, so the template is compiled to a
-- format string plus arguments and resolved C-side. Nothing in Lua ever
-- touches a fetched value.
--
-- The token set differs from the unit frame one because a nameplate shows
-- a different kind of unit: classification replaces guild, and the level
-- token uses UnitEffectiveLevel like the plate's own level text does.
--
-- Health and power tokens are absent here for the same reason as the other
-- domain: the useful token is a percentage, which needs a division on a
-- secret value. The plate's health text already does that through the
-- status bar's C-side methods.
-- ---------------------------------------------------------------------

NPE.TOKENS = {
    { token = "name",           fmt = "%s", labelKey = "token_name" },
    { token = "level",          fmt = "%s", labelKey = "token_level" },
    { token = "class",          fmt = "%s", labelKey = "token_class" },
    { token = "race",           fmt = "%s", labelKey = "token_race" },
    { token = "classification", fmt = "%s", labelKey = "token_classification" },
}

local TOKEN_FMT = Forge.Text and Forge.Text.CompileTokens(NPE.TOKENS) or {}

local function TokenValue(token, unit)
    if token == "name"           then return UnitName(unit) end
    if token == "level"          then return UnitEffectiveLevel(unit) end
    if token == "class"          then
        -- [12.1] The class display name can be secret, and a tag value is
        -- concatenated downstream. Empty reads better than an error.
        return (TomoMod_Utils and TomoMod_Utils.SafeStr(UnitClass(unit))) or ""
    end
    if token == "race"           then return (UnitRace(unit)) end
    if token == "classification" then return UnitClassification(unit) end
    return nil
end

function NPE.RenderCustomText(fs, unit, template)
    if not Forge.Text then return false end
    if not unit or not UnitExists(unit) then return false end
    return Forge.Text.Render(fs, template, TOKEN_FMT, TokenValue, unit)
end

R.DefineInstanced(DOMAIN, {
    id       = "customText",
    kind     = "fontstring",
    labelKey = "elem_custom_text",
    max      = 4,
    default  = {
        point = "CENTER", relTo = "health", relPoint = "CENTER", x = 0, y = 0,
        text  = "[name]",
    },
    build = function(plate)
        if not plate or not plate.CreateFontString then return nil end
        local fs = plate:CreateFontString(nil, "OVERLAY")
        local db = TomoModDB and TomoModDB.nameplates
        fs:SetFont(
            (db and db.font) or "Fonts\\FRIZQT__.TTF",
            (db and db.fontSize) or 11,
            (db and db.fontOutline) or "OUTLINE")
        fs:SetTextColor(1, 1, 1, 1)
        return fs
    end,
})

-- Rafraichit tous les textes personnalises d'une plaque. Appele depuis
-- UpdatePlate, au meme endroit que le nom : memes evenements, aucun nouvel
-- enregistrement, et une plaque recyclee repasse forcement par la.
function NPE.RefreshCustomTexts(plate, unit, store)
    if not plate then return 0 end
    local cache = rawget(plate, "_forgeInstances")
    if not cache then return 0 end
    local n = 0
    for _, inst in ipairs(R.ListInstances(DOMAIN, store)) do
        local fs = cache[inst.key]
        if fs and inst.typeID == "customText" then
            local rec = store[inst.key]
            if not NPE.RenderCustomText(fs, unit, rec and rec.text) then
                fs:SetText("")
            end
            n = n + 1
        end
    end
    return n
end

-- ---------------------------------------------------------------------
-- Convenience wrappers (keep the domain string in one place)
-- ---------------------------------------------------------------------
function NPE.List()         return R.List(DOMAIN) end
function NPE.ListHosts()    return R.ListHosts(DOMAIN) end
function NPE.Ensure(store)  return R.Ensure(DOMAIN, store) end

function NPE.AllowedTargets(id, store)
    return R.AllowedTargets(DOMAIN, id, store)
end

function NPE.Defaults()
    local out = {}
    for _, desc in ipairs(R.List(DOMAIN)) do
        out[desc.id] = R.Default(DOMAIN, desc.id)
    end
    return out
end

function NPE.ApplyAll(plate, store)
    return R.ApplyAll(DOMAIN, plate, store)
end

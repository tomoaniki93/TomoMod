-- =====================================================================
-- ResolutionPresets.lua — Install presets per screen (v4 Lot 5)
-- ---------------------------------------------------------------------
-- What the client actually does with resolution, because it shapes
-- everything below.
--
-- UIParent is measured in interface units, not pixels, and the uiScale
-- CVar is the conversion: UIParent height = 768 / uiScale. The pixel-
-- perfect value is 768 / physicalHeight, but the client refuses to go
-- below 0.64. So:
--
--     1080p   ideal 0.711   kept 0.711   ->  UIParent 1080 units
--     1440p   ideal 0.533   kept 0.640   ->  UIParent 1200 units
--     2160p   ideal 0.356   kept 0.640   ->  UIParent 1200 units
--
-- 1440p and 2160p therefore produce an IDENTICAL interface space. A 4K
-- player is not laying out a bigger canvas, they are laying out the same
-- 1200-unit canvas rendered onto more pixels. Three hand-positioned
-- layouts would mean authoring the same one twice.
--
-- What genuinely differs is legibility, and it differs in the direction
-- people do not expect. One unit is one physical pixel at 1080p, 1.2 at
-- 1440p and 1.8 at 2160p, so a 12-unit font renders at 12, 14 and 22
-- physical pixels. The small screen is the one that needs bigger type,
-- not the large one.
--
-- A preset is consequently three things, and positions are none of them:
--
--   uiScale    the value to recommend, honouring the 0.64 floor
--   fontScale  a multiplier on the declared legibility keys
--   stamping   marking existing positions with the current screen size
--              so the lot 2 layout engine starts rescaling them
--
-- Positions are already resolution-independent since lot 2. Rewriting
-- them here would fight that engine rather than use it.
--
-- Captured presets
-- ----------------
-- Computed values are a floor, not an ambition. Capture() snapshots a
-- real, tuned layout from a live client and stores it as that tier's
-- preset; a capture always wins over the computed values. That is the
-- path to shipping hand-authored presets without anyone having to guess
-- coordinates from outside the game.
-- =====================================================================

TomoMod_Resolution = TomoMod_Resolution or {}
local RES = TomoMod_Resolution

local R = TomoMod_Registry

RES.SCHEMA_VERSION = 1

-- The client will not apply a uiScale below this.
local UISCALE_FLOOR = 0.64
-- UIParent's height in units at scale 1. A client constant, not a guess.
local UI_BASE_HEIGHT = 768
RES.UISCALE_FLOOR   = UISCALE_FLOOR
RES.UI_BASE_HEIGHT  = UI_BASE_HEIGHT

-- ---------------------------------------------------------------------
-- TIERS
-- ---------------------------------------------------------------------
-- Matched on physical height, from the tallest down. A tier is a
-- recommendation, never a lock: Apply takes an explicit key, so a
-- 1440p player who prefers the 1080p type sizes can say so.
-- ---------------------------------------------------------------------

local TIERS = {
    { key = "2160p", label = "res_2160", minHeight = 1800, fontScale = 1.00 },
    { key = "1440p", label = "res_1440", minHeight = 1200, fontScale = 1.00 },
    { key = "1080p", label = "res_1080", minHeight = 0,    fontScale = 1.15 },
}
RES.TIERS = TIERS

local TIER_BY_KEY = {}
for _, t in ipairs(TIERS) do TIER_BY_KEY[t.key] = t end

-- ---------------------------------------------------------------------
-- LEGIBILITY KEYS
-- ---------------------------------------------------------------------
-- Written out rather than discovered by walking the defaults for
-- anything named "fontSize". A walk would silently pick up every key a
-- future module adds, including ones where scaling is wrong, and nobody
-- would notice until type went strange on someone's screen. The list is
-- checked against the real defaults by the test suite, so it cannot rot
-- quietly either.
-- ---------------------------------------------------------------------

local FONT_KEYS = {
    "actionBars.global.cooldownTextFontSize",
    "actionBars.global.countFontSize",
    "actionBars.global.keybindFontSize",
    "actionBars.global.macroNameFontSize",
    "battleRez.fontSize",
    "castbars.fontSize",
    "castbars.interruptFeedbackFontSize",
    "chatFrameSkin.fontSize",
    "chatFrameSkinV2.fontSize",
    "nameplates.fontSize",
    "nameplates.nameFontSize",
    "objectiveTracker.categoryFontSize",
    "objectiveTracker.headerFontSize",
    "objectiveTracker.objectiveFontSize",
    "objectiveTracker.questFontSize",
    "partyFrames.fontSize",
    "preyTracker.fontSize",
    "raidFrames.fontSize",
    "resourceBars.fontSize",
    "skyRide.fontSize",
    "tooltipSkin.fontSize",
    "unitFrames.fontSize",
}
RES.FONT_KEYS = FONT_KEYS

-- Below this, type stops being readable at any resolution.
local MIN_FONT = 8

-- ---------------------------------------------------------------------
-- DETECTION
-- ---------------------------------------------------------------------

function RES.PhysicalSize()
    if not GetPhysicalScreenSize then return nil, nil end
    local w, h = GetPhysicalScreenSize()
    if type(w) ~= "number" or type(h) ~= "number" or h <= 0 then return nil, nil end
    return w, h
end

function RES.Detect()
    local _, h = RES.PhysicalSize()
    if not h then return "1440p" end
    for _, t in ipairs(TIERS) do
        if h >= t.minHeight then return t.key end
    end
    return "1080p"
end

function RES.Get(key)
    return TIER_BY_KEY[key]
end

function RES.Tiers()
    local out = {}
    for i, t in ipairs(TIERS) do out[i] = t end
    return out
end

--- The scale facts for a given physical height. Pure arithmetic, so the
--- suite can check the floor behaviour without a client.
function RES.Describe(height)
    if type(height) ~= "number" or height <= 0 then return nil end
    local ideal   = UI_BASE_HEIGHT / height
    local floored = ideal < UISCALE_FLOOR
    local kept    = floored and UISCALE_FLOOR or ideal
    return {
        physicalHeight = height,
        idealScale     = ideal,
        appliedScale   = kept,
        floored        = floored,
        uiHeight       = UI_BASE_HEIGHT / kept,
        pixelsPerUnit  = height / (UI_BASE_HEIGHT / kept),
    }
end

-- ---------------------------------------------------------------------
-- STORAGE
-- ---------------------------------------------------------------------

local function Store()
    if not TomoModDB then return nil end
    if type(TomoModDB._resolution) ~= "table" then
        TomoModDB._resolution = { v = RES.SCHEMA_VERSION, captures = {} }
    end
    local s = TomoModDB._resolution
    if type(s.captures) ~= "table" then s.captures = {} end
    return s
end

function RES.Applied()
    local s = Store()
    return s and s.applied
end

-- ---------------------------------------------------------------------
-- FONT SCALING
-- ---------------------------------------------------------------------
-- Scaling is measured against the DEFAULTS, never against whatever is
-- currently stored. Multiplying the live value would compound every time
-- a preset is applied twice, and a player switching 1080p -> 1440p ->
-- 1080p would end up somewhere neither preset describes.
-- ---------------------------------------------------------------------

function RES.ScaledFont(base, factor)
    if type(base) ~= "number" then return nil end
    local v = math.floor(base * (factor or 1) + 0.5)
    if v < MIN_FONT then v = MIN_FONT end
    return v
end

--- The font values a tier implies, as path -> value. Returned rather
--- than written so a caller can preview before committing.
function RES.FontPlan(tierKey)
    local plan = {}
    local tier = TIER_BY_KEY[tierKey]
    if not tier or not R or not TomoMod_Defaults then return plan end
    for _, path in ipairs(FONT_KEYS) do
        local base = R.GetPath(TomoMod_Defaults, path)
        local v = RES.ScaledFont(base, tier.fontScale)
        if v then plan[path] = v end
    end
    return plan
end

-- ---------------------------------------------------------------------
-- CAPTURE
-- ---------------------------------------------------------------------

--- Snapshots the live layout as this tier's preset: every declared
--- anchor plus the legibility keys. Positions come from the registry's
--- anchor list, so a preset covers exactly what lot 0 declared and
--- cannot drift from it.
function RES.Capture(tierKey)
    local s = Store()
    if not s or not TIER_BY_KEY[tierKey] or not R or not TomoModDB then return false end

    local _, h = RES.PhysicalSize()
    local cap = {
        v          = RES.SCHEMA_VERSION,
        capturedAt = h,
        positions  = {},
        fonts      = {},
    }

    for _, a in ipairs(R.Anchors()) do
        local pos = R.GetPath(TomoModDB, a.path)
        if type(pos) == "table" then
            cap.positions[a.path] = {
                v = pos.v, point = pos.point, anchor = pos.anchor,
                x = pos.x, y = pos.y, refW = pos.refW, refH = pos.refH,
            }
        end
    end
    for _, path in ipairs(FONT_KEYS) do
        local v = R.GetPath(TomoModDB, path)
        if type(v) == "number" then cap.fonts[path] = v end
    end

    s.captures[tierKey] = cap
    return true, cap
end

function RES.HasCapture(tierKey)
    local s = Store()
    return (s and s.captures[tierKey]) and true or false
end

function RES.GetCapture(tierKey)
    local s = Store()
    return s and s.captures[tierKey]
end

function RES.ClearCapture(tierKey)
    local s = Store()
    if not s then return false end
    s.captures[tierKey] = nil
    return true
end

-- ---------------------------------------------------------------------
-- APPLY
-- ---------------------------------------------------------------------

--- Applies a tier. Returns a report rather than printing, on the same
--- reasoning as the lifecycle engine: the installer, the config panel
--- and the slash command each want to present the outcome differently.
---
--- opts.skipScale   leave the uiScale CVar alone
--- opts.skipFonts   leave the legibility keys alone
function RES.Apply(tierKey, opts)
    opts = opts or {}
    local report = { tier = tierKey, ok = false, fonts = 0, stamped = 0,
                     scale = nil, floored = false, fromCapture = false }

    local tier = TIER_BY_KEY[tierKey]
    if not tier or not TomoModDB or not R then return report end
    local s = Store()
    if not s then return report end

    local _, h = RES.PhysicalSize()
    local info = h and RES.Describe(h)
    if info then
        report.scale   = info.appliedScale
        report.floored = info.floored
    end

    local capture = s.captures[tierKey]

    if capture then
        -- A tuned capture beats anything computed here.
        report.fromCapture = true
        for path, pos in pairs(capture.positions) do
            local target = R.GetPath(TomoModDB, path)
            if type(target) == "table" then
                target.v, target.point, target.anchor = pos.v, pos.point, pos.anchor
                target.x, target.y   = pos.x, pos.y
                target.refW, target.refH = pos.refW, pos.refH
                report.stamped = report.stamped + 1
            end
        end
        if not opts.skipFonts then
            for path, v in pairs(capture.fonts) do
                R.SetPath(TomoModDB, path, v)
                report.fonts = report.fonts + 1
            end
        end
    else
        if not opts.skipFonts then
            for path, v in pairs(RES.FontPlan(tierKey)) do
                R.SetPath(TomoModDB, path, v)
                report.fonts = report.fonts + 1
            end
        end
        -- Positions migrated from the old schema carry no reference size,
        -- so the layout engine applies them verbatim and they never follow
        -- a resolution change. Stamping the current screen onto them is
        -- what opts them in, and doing it here is safe: at this moment the
        -- player has just told us the layout suits this screen.
        if TomoMod_Layout and TomoMod_Layout.StampReference then
            report.stamped = TomoMod_Layout.StampReference(TomoModDB)
        end
    end

    -- The CVar is only worth touching when it changes anything. Above
    -- 1200 physical lines the client ignores the request, so writing it
    -- would only produce a setting that disagrees with reality.
    if not opts.skipScale and info and not info.floored and SetCVar then
        pcall(SetCVar, "useUiScale", "1")
        pcall(SetCVar, "uiScale", tostring(info.appliedScale))
    end

    s.applied = tierKey
    report.ok = true

    if TomoMod_Config and TomoMod_Config.InvalidatePanels then
        TomoMod_Config.InvalidatePanels()
    end
    return report
end

--- Test seam.
function RES._Reset()
    if TomoModDB then TomoModDB._resolution = nil end
end

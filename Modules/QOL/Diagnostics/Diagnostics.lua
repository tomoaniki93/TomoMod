-- =====================================================================
-- Diagnostics.lua v1.0.0 — Error Capture & Report System
-- Background Lua error capture with zero combat popups.
-- Export clean reports for tracker-tomomod.onkoz.fr
-- Inspired by MidnightUI Diagnostics Console.
-- =====================================================================

TomoMod_Diagnostics = TomoMod_Diagnostics or {}
local D = TomoMod_Diagnostics

-- =====================================================================
-- CONSTANTS
-- =====================================================================

local ADDON_NAME    = "TomoMod"
local ADDON_PREFIX  = "|cff0cd29fTomo|rMod"
local FONT          = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local FONT_MEDIUM   = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_MONO     = "Fonts\\FRIZQT__.TTF"  -- monospace-ish for stack traces
local MAX_ERRORS    = 500        -- max stored entries (FIFO)
local FLOOD_LIMIT   = 30         -- max captures per second
local DEDUP_WINDOW  = 2          -- seconds before same error is re-logged
local VERSION       -- resolved from TOC at init

-- Entry kinds
local KIND_LUA_ERROR = "LuaError"
local KIND_TAINT     = "Taint"
local KIND_WARNING   = "Warning"
local KIND_UI_ERROR  = "UIError"
local KIND_DEBUG     = "Debug"

-- Gameplay UI error messages to exclude (these are normal game feedback, not bugs)
-- Built from WoW GlobalStrings at runtime to support all locales.
-- Exact matches stored in EXCLUDED_UI_ERRORS, pattern matches in EXCLUDED_UI_PATTERNS.
local EXCLUDED_UI_ERRORS = {}
local EXCLUDED_UI_PATTERNS = {}
local EXCLUDED_GLOBAL_KEYS = {
    -- Resource errors
    "ERR_OUT_OF_MANA", "ERR_OUT_OF_ENERGY", "ERR_OUT_OF_RAGE",
    "ERR_OUT_OF_FOCUS", "ERR_OUT_OF_RUNIC_POWER", "ERR_OUT_OF_RUNES",
    "ERR_OUT_OF_HOLY_POWER", "ERR_OUT_OF_CHI", "ERR_OUT_OF_COMBO_POINTS",
    "ERR_OUT_OF_SOUL_SHARDS", "ERR_OUT_OF_LUNAR_POWER", "ERR_OUT_OF_INSANITY",
    "ERR_OUT_OF_ARCANE_CHARGES", "ERR_OUT_OF_FURY", "ERR_OUT_OF_PAIN",
    "ERR_OUT_OF_MAELSTROM", "ERR_OUT_OF_HEALTH", "ERR_OUT_OF_ESSENCE",
    -- Cooldown / ability errors
    "ERR_ABILITY_COOLDOWN", "ERR_SPELL_COOLDOWN",
    "SPELL_FAILED_NOT_READY", "SPELL_FAILED_SPELL_IN_PROGRESS",
    "ERR_SPELL_FAILED_ANOTHER_IN_PROGRESS",
    "ERR_ATTACK_PACIFIED", "ERR_ATTACK_STUNNED", "ERR_ATTACK_FLEEING",
    -- Target / range errors
    "ERR_GENERIC_NO_TARGET", "ERR_NO_ATTACK_TARGET",
    "ERR_INVALID_ATTACK_TARGET", "SPELL_FAILED_BAD_TARGETS",
    "ERR_SPELL_OUT_OF_RANGE", "ERR_OUT_OF_RANGE",
    "SPELL_FAILED_OUT_OF_RANGE", "SPELL_FAILED_LINE_OF_SIGHT",
    -- Movement / state
    "ERR_AUTOFOLLOW_TOO_FAR", "SPELL_FAILED_MOVING",
    "ERR_NOT_WHILE_MOVING", "ERR_CANT_DO_THAT_IN_COMBAT",
    "ERR_NOT_IN_COMBAT", "ERR_AFFECTING_COMBAT",
    -- Inventory
    "ERR_ITEM_COOLDOWN", "ERR_BAG_FULL", "ERR_INV_FULL",
    "ERR_LOOT_GONE",
    -- Misc common combat messages
    "SPELL_FAILED_NOT_BEHIND", "SPELL_FAILED_NOT_INFRONT",
    "SPELL_FAILED_UNIT_NOT_INFRONT", "SPELL_FAILED_UNIT_NOT_BEHIND",
    "SPELL_FAILED_TOO_CLOSE", "SPELL_FAILED_INTERRUPTED",
    "INTERRUPTED",
    -- Facing / positioning
    "ERR_BADATTACKFACING", "ERR_BADATTACKPOS",
    "SPELL_FAILED_UNIT_NOT_INFRONT", "SPELL_FAILED_BAD_FACING",
    -- Target state
    "ERR_ATTACK_DEAD", "ERR_ENEMY_IS_DEAD",
    "SPELL_FAILED_TARGETS_DEAD", "ERR_INVALID_ATTACK_TARGET",
    -- Generic "can't do that"
    "ERR_GENERIC_STUNNED", "ERR_STUNNED",
    "ERR_CANT_DO_THAT_RIGHT_NOW", "ERR_SPELL_FAILED_STUNNED",
    "SPELL_FAILED_STUNNED", "SPELL_FAILED_SILENCED",
    "SPELL_FAILED_PACIFIED", "SPELL_FAILED_CHARMED",
    "SPELL_FAILED_FLEEING", "SPELL_FAILED_CONFUSED",
    "ERR_SPELL_FAILED_SHAPESHIFT_FORM_S",
    -- Immune / absorb
    "SPELL_FAILED_IMMUNE", "SPELL_FAILED_DAMAGE_IMMUNE",
    -- Mail
    "ERR_MAIL_DATABASE_ERROR",
    -- Currency / loot cap
    "ERR_CURRENCY_LIMIT_REACHED_S",
    "ERR_LOOT_CURRENCY_S_QUANTITY_OVERFLOW",
}

-- Convert a WoW format string ("%s", "%d", "%1$s" etc.) to a Lua pattern
local function FormatToPattern(fmt)
    -- Escape Lua magic characters except %
    local pat = fmt:gsub("([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
    -- Replace ordered format tokens (%1$s, %2$d etc.) with .+
    pat = pat:gsub("%%%%(%d+)%$[sd]", ".+")
    -- Replace simple format tokens (%s, %d) with .+
    pat = pat:gsub("%%%%[sd]", ".+")
    return "^" .. pat .. "$"
end

local function BuildExclusionSet()
    for _, key in ipairs(EXCLUDED_GLOBAL_KEYS) do
        local val = _G[key]
        if val and type(val) == "string" then
            if val:find("%%") then
                -- Contains format specifiers → store as lowercase pattern
                local ok, pat = pcall(FormatToPattern, val:lower())
                if ok and pat then
                    EXCLUDED_UI_PATTERNS[#EXCLUDED_UI_PATTERNS + 1] = pat
                end
            else
                EXCLUDED_UI_ERRORS[val] = true
            end
        end
    end

    -- Fallback: substring keywords that identify gameplay feedback regardless of locale
    -- gender inflections (e.g. French "(e)"), or missing GlobalString keys.
    -- Each entry is a lowercase substring checked via string.find.
    local keywords = {
        -- Stunned / incapacitated / disoriented (all locales)
        "stunned", "stun", "\195\169tourdi",         -- EN / FR étourdi
        "disoriented", "d\195\169sorient\195\169",   -- EN / FR désorienté
        "bet\195\164ubt",                             -- DE betäubt
        "desorientiert",                              -- DE
        "aturdid", "desorientad",                     -- ES aturdido/a, desorientado/a
        "stordito", "disorientat",                    -- IT
        "desorientad",                                -- PT
        -- In the air / falling
        "in the air", "dans les airs", "in der luft", "en el aire", "in aria", "no ar",
        -- Can't do that yet
        "can't do that yet", "pas encore faire cela", "noch nicht tun",
        "no puedes hacer eso", "non puoi farlo", "fazer isso ainda",
        -- Dice / loot roll pending
        "loot roll", "rolled yet", "d\195\169s ne sont",  -- FR "dés ne sont"
        "not yet rolled", "w\195\188rfel",             -- DE Würfel
        -- Not on ground
        "not on the ground", "sur le sol",
        -- Too far away / out of range
        "too far", "trop loin", "zu weit", "demasiado lejos", "troppo lontano", "muito longe",
        "out of range", "hors de port\195\169e",
        -- Currency / loot cap
        "can't get any more", "ne pouvez pas obtenir", "nicht mehr erhalten",
        "no puedes obtener", "non puoi ottenere", "obter mais",
        -- Friendly / wrong target type
        "target is friendly", "cible est amicale", "ziel ist freundlich",
        "objetivo es amistoso", "bersaglio \195\168 amichevole", "alvo \195\169 amig",
        -- Generic impossible / cannot
        "impossible tant que", "impossible lorsque", "impossible d'attaquer",
        -- Horrified (FR horrifié(e))
        "horrifi",
        -- Item not found / missing component (FR)
        "objet introuvable", "composant manquant",
        -- Outdoor only (FR extérieur)
        "en ext\195\169rieur",
        -- Too far to interact (FR rapprocher)
        "rapprocher",
    }
    for _, kw in ipairs(keywords) do
        EXCLUDED_UI_PATTERNS[#EXCLUDED_UI_PATTERNS + 1] = kw
    end
end

-- =====================================================================
-- STATE
-- =====================================================================

local db              = nil       -- reference to TomoModDB.diagnostics
local errors          = {}        -- array of error entries
local dedupMap        = {}        -- "kind::normalized" → entry index
local captureCount    = 0         -- captures this second
local captureResetAt  = 0         -- GetTime() of last counter reset
local droppedCount    = 0         -- flood-dropped this second
local inHandler       = false     -- re-entry guard for error handler
local inCapture       = false     -- re-entry guard for CaptureEntry
local prevErrorHandler = nil      -- original error handler
local sessionID       = 0        -- incremented each login
local suppressActive  = false     -- whether ScriptErrorsFrame is suppressed
local consoleFrame    = nil       -- the UI frame (lazy-created)
local L               = nil       -- locale table

-- Environment snapshot (captured once at login)
local envSnapshot = {}

-- =====================================================================
-- HELPERS
-- =====================================================================

local function SafeToString(val)
    if val == nil then return "nil" end
    -- WoW secret values: issecretvalue() check
    if issecretvalue and issecretvalue(val) then return "<secret>" end
    local ok, str = pcall(tostring, val)
    if ok then return str end
    return "<tostring failed>"
end

local function GetTimestamp()
    return date("!%Y-%m-%dT%H:%M:%SZ")
end

local function GetGameTime()
    return GetTime()
end

local function IsStackOverflow(msg)
    if not msg then return false end
    return msg:find("stack overflow") ~= nil
end

local function NormalizeMessage(msg)
    if not msg then return "" end
    -- Strip file paths to just filename:line
    local normalized = msg:gsub("Interface\\AddOns\\[^:]+\\", "")
    -- Strip memory addresses
    normalized = normalized:gsub("0x%x+", "<addr>")
    -- Strip table IDs
    normalized = normalized:gsub("table: %x+", "table:<id>")
    return normalized
end

local function IsTaintMessage(msg)
    if not msg then return false end
    local lower = msg:lower()
    return lower:find("taint") ~= nil
        or lower:find("forbidden") ~= nil
        or lower:find("blocked") ~= nil
end

local function IsTomoModError(msg, stack)
    local combined = (msg or "") .. (stack or "")
    return combined:find("TomoMod") ~= nil
end

-- =====================================================================
-- DATABASE
-- =====================================================================

local function EnsureDB()
    if not TomoModDB then return end
    if not TomoModDB.diagnostics then
        TomoModDB.diagnostics = {
            enabled = false,
            captureAll = false,       -- false = TomoMod-only, true = all addons
            suppressPopups = true,
            autoOpenOnError = false,
            sessionCount = 0,
        }
    end
    db = TomoModDB.diagnostics
    db.sessionCount = (db.sessionCount or 0) + 1
    sessionID = db.sessionCount

    if not db.errors then db.errors = {} end
    errors = db.errors
end

local function IsEnabled()
    return db and db.enabled
end

-- =====================================================================
-- ENVIRONMENT SNAPSHOT
-- =====================================================================

local function CaptureEnvironment()
    local _, build, _, tocVersion = GetBuildInfo()
    local _, class = UnitClass("player")
    local name = UnitName("player")
    local realm = GetRealmName()
    local locale = GetLocale()
    local res = ({GetPhysicalScreenSize()})

    envSnapshot = {
        addonVersion  = VERSION,
        wowBuild      = build or "?",
        tocVersion     = tocVersion or "?",
        playerName    = (name or "?") .. "-" .. (realm or "?"),
        playerClass   = class or "?",
        playerLevel   = UnitLevel("player") or 0,
        locale        = locale or "?",
        screenWidth   = res[1] or 0,
        screenHeight  = res[2] or 0,
        sessionID     = sessionID,
        timestamp     = GetTimestamp(),
    }

    -- Loaded addons list
    local addons = {}
    local numAddons = C_AddOns and C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or GetNumAddOns()
    for i = 1, numAddons do
        local name, _, _, loadable, reason
        if C_AddOns and C_AddOns.GetAddOnInfo then
            name, _, _, loadable, reason = C_AddOns.GetAddOnInfo(i)
        else
            name, _, _, loadable, reason = GetAddOnInfo(i)
        end
        local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(i)
                    or (IsAddOnLoaded and IsAddOnLoaded(i))
        if loaded then
            local ver = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(name, "Version")
                     or (GetAddOnMetadata and GetAddOnMetadata(name, "Version"))
            addons[#addons + 1] = { name = name, version = ver or "?" }
        end
    end
    envSnapshot.addons = addons
end

-- =====================================================================
-- CAPTURE ENGINE
-- =====================================================================

local function CaptureEntry(kind, message, stack, locals, meta)
    -- Allow TomoMod taint through even when diagnostics are disabled
    if not IsEnabled() and kind ~= KIND_TAINT then return end
    if inCapture then return end
    inCapture = true

    -- Flood control
    local now = GetGameTime()
    if now - captureResetAt >= 1 then
        if droppedCount > 0 then
            -- Inject a warning about dropped errors
            local dropMsg = string.format("[Diagnostics] %d errors dropped (flood limit %d/s)", droppedCount, FLOOD_LIMIT)
            -- Don't recurse — direct insert
            local entry = {
                kind = KIND_WARNING,
                message = dropMsg,
                timestamp = GetTimestamp(),
                gameTime = now,
                session = sessionID,
                count = 1,
            }
            errors[#errors + 1] = entry
        end
        captureCount = 0
        captureResetAt = now
        droppedCount = 0
    end
    if captureCount >= FLOOD_LIMIT then
        droppedCount = droppedCount + 1
        inCapture = false
        return
    end
    captureCount = captureCount + 1

    -- Dedup
    local normalized = NormalizeMessage(message or "")
    local dedupKey = kind .. "::" .. normalized
    local existingIdx = dedupMap[dedupKey]

    if existingIdx and errors[existingIdx] then
        local existing = errors[existingIdx]
        local timeSince = now - (existing.lastSeen or 0)
        if timeSince < DEDUP_WINDOW then
            existing.count = (existing.count or 1) + 1
            existing.lastSeen = now
            inCapture = false
            -- Refresh console if open
            if consoleFrame and consoleFrame:IsShown() then
                D.RefreshConsole()
            end
            return
        end
    end

    -- Build entry
    local entry = {
        kind       = kind,
        message    = message or "",
        stack      = stack,
        locals     = locals,
        timestamp  = GetTimestamp(),
        gameTime   = now,
        session    = sessionID,
        count      = 1,
        lastSeen   = now,
        meta       = meta,
        isTomoMod  = IsTomoModError(message, stack),
        inCombat   = InCombatLockdown() or false,
    }

    -- Prune if at limit
    if #errors >= MAX_ERRORS then
        table.remove(errors, 1)
        -- Rebuild dedup map (indexes shifted)
        wipe(dedupMap)
        for i, e in ipairs(errors) do
            local key = e.kind .. "::" .. NormalizeMessage(e.message)
            dedupMap[key] = i
        end
    end

    errors[#errors + 1] = entry
    dedupMap[dedupKey] = #errors

    inCapture = false

    -- Refresh console if open
    if consoleFrame and consoleFrame:IsShown() then
        D.RefreshConsole()
    end

    -- Auto-open (non-combat only) — for Lua errors AND taint from TomoMod
    if db and db.autoOpenOnError and not InCombatLockdown()
       and (kind == KIND_LUA_ERROR or kind == KIND_TAINT) and entry.isTomoMod then
        D.ShowConsole()
    end
end

-- =====================================================================
-- ERROR HANDLER
-- =====================================================================

local function OnLuaError(msg)
    if inHandler then return end
    inHandler = true

    local stack, locals
    if not IsStackOverflow(msg) then
        local ok1, s = pcall(debugstack, 4, 20, 0)
        stack = ok1 and s or nil
        local ok2, l = pcall(debuglocals, 4)
        locals = ok2 and l or nil
    end

    -- Filter: TomoMod-only unless captureAll
    local isOurs = IsTomoModError(msg, stack)
    if not db.captureAll and not isOurs then
        inHandler = false
        -- Forward to previous handler
        if prevErrorHandler then
            prevErrorHandler(msg)
        end
        return
    end

    -- Classify: taint vs lua error
    local kind = IsTaintMessage(msg) and KIND_TAINT or KIND_LUA_ERROR

    CaptureEntry(kind, msg, stack, locals, { inferred = (kind == KIND_TAINT) })

    inHandler = false

    -- Forward to previous handler if not suppressed
    if not suppressActive and prevErrorHandler then
        prevErrorHandler(msg)
    end
end

-- =====================================================================
-- EVENT HANDLERS
-- =====================================================================

local function OnTaintEvent(event, addon, action)
    -- Always capture TomoMod taint, even if diagnostics are disabled
    local addonStr = SafeToString(addon)
    local isOurs = addonStr:find("TomoMod") ~= nil
    if not IsEnabled() and not isOurs then return end
    local msg = string.format("[%s] %s: %s", event, addonStr, SafeToString(action))
    local stack
    local ok, s = pcall(debugstack, 3, 15, 0)
    stack = ok and s or nil
    CaptureEntry(KIND_TAINT, msg, stack, nil, { addon = addon, action = action, event = event })
end

local function OnLuaWarning(_, warnType, msg)
    if not IsEnabled() then return end
    CaptureEntry(KIND_WARNING, "[LUA_WARNING type=" .. SafeToString(warnType) .. "] " .. SafeToString(msg))
end

local function OnUiError(_, _, msg)
    if not IsEnabled() then return end
    local text = SafeToString(msg)
    -- Skip normal gameplay feedback (resource, cooldown, target, range messages)
    if EXCLUDED_UI_ERRORS[text] then return end
    -- Check pattern-based exclusions (GlobalString patterns + keyword substrings)
    local lower = text:lower()
    for _, pat in ipairs(EXCLUDED_UI_PATTERNS) do
        local ok, found = pcall(lower.find, lower, pat)
        if ok and found then return end
    end
    CaptureEntry(KIND_UI_ERROR, text)
end

-- =====================================================================
-- SUPPRESS SCRIPT ERRORS FRAME (zero combat popups)
-- =====================================================================

local function SuppressScriptErrors()
    if suppressActive then return end
    suppressActive = true

    if ScriptErrorsFrame then
        ScriptErrorsFrame:Hide()
        -- Replace Show with no-op
        ScriptErrorsFrame._origShow = ScriptErrorsFrame.Show
        ScriptErrorsFrame.Show = function() end
        -- Belt-and-suspenders
        ScriptErrorsFrame:HookScript("OnShow", function(self)
            self:Hide()
        end)
    end
end

local function RestoreScriptErrors()
    if not suppressActive then return end
    suppressActive = false

    if ScriptErrorsFrame and ScriptErrorsFrame._origShow then
        ScriptErrorsFrame.Show = ScriptErrorsFrame._origShow
        ScriptErrorsFrame._origShow = nil
    end
end

-- =====================================================================
-- INSTALL ERROR HANDLER
-- =====================================================================

local function InstallErrorHandler()
    -- Save the current error handler
    prevErrorHandler = geterrorhandler()
    seterrorhandler(OnLuaError)
end

-- =====================================================================
-- CONSOLE UI (Diagnostics Console)
-- =====================================================================

local scrollEntries = {}  -- displayed entries (filtered)

local function CreateConsole()
    if consoleFrame then return consoleFrame end

    local f = CreateFrame("Frame", "TomoMod_DiagConsole", UIParent, "BackdropTemplate")
    f:SetSize(700, 500)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(200)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    -- Backdrop
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.06, 0.06, 0.08, 0.97)
    f:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetHeight(36)
    titleBar:SetPoint("TOPLEFT"); titleBar:SetPoint("TOPRIGHT")

    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.08, 0.08, 0.10, 1)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT, 13, "")
    title:SetPoint("LEFT", 12, 0)
    title:SetTextColor(0.047, 0.824, 0.624, 1)
    title:SetText(ADDON_PREFIX .. " |cffaaaaaaDiagnostics Console|r")

    -- Error count badge
    local badge = titleBar:CreateFontString(nil, "OVERLAY")
    badge:SetFont(FONT_MEDIUM, 11, "")
    badge:SetPoint("LEFT", title, "RIGHT", 10, 0)
    badge:SetTextColor(0.6, 0.6, 0.65, 1)
    f._badge = badge

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(28, 28)
    closeBtn:SetPoint("RIGHT", -4, 0)
    closeBtn:SetNormalFontObject(GameFontNormal)
    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY")
    closeTxt:SetFont(FONT, 16, "")
    closeTxt:SetPoint("CENTER")
    closeTxt:SetText("x")
    closeTxt:SetTextColor(0.5, 0.5, 0.55, 1)
    closeBtn:SetScript("OnEnter", function() closeTxt:SetTextColor(1, 0.3, 0.3, 1) end)
    closeBtn:SetScript("OnLeave", function() closeTxt:SetTextColor(0.5, 0.5, 0.55, 1) end)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Filter bar
    local filterBar = CreateFrame("Frame", nil, f)
    filterBar:SetHeight(28)
    filterBar:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    filterBar:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)

    local filterBg = filterBar:CreateTexture(nil, "BACKGROUND")
    filterBg:SetAllPoints()
    filterBg:SetColorTexture(0.07, 0.07, 0.09, 1)

    -- Filter buttons
    local filters = { "All", "Errors", "Taint", "Warnings", "TomoMod" }
    f._activeFilter = "All"
    f._filterBtns = {}

    local fx = 8
    for _, label in ipairs(filters) do
        local btn = CreateFrame("Button", nil, filterBar)
        btn:SetSize(70, 20)
        btn:SetPoint("LEFT", fx, 0)

        local txt = btn:CreateFontString(nil, "OVERLAY")
        txt:SetFont(FONT_MEDIUM, 10, "")
        txt:SetPoint("CENTER")
        txt:SetText(label)
        btn._txt = txt
        btn._label = label

        local function UpdateColor()
            if f._activeFilter == label then
                txt:SetTextColor(0.047, 0.824, 0.624, 1)
            else
                txt:SetTextColor(0.45, 0.45, 0.50, 1)
            end
        end

        btn:SetScript("OnClick", function()
            f._activeFilter = label
            for _, b in ipairs(f._filterBtns) do
                b._txt:SetTextColor(0.45, 0.45, 0.50, 1)
            end
            txt:SetTextColor(0.047, 0.824, 0.624, 1)
            D.RefreshConsole()
        end)
        btn:SetScript("OnEnter", function()
            if f._activeFilter ~= label then
                txt:SetTextColor(0.7, 0.7, 0.75, 1)
            end
        end)
        btn:SetScript("OnLeave", UpdateColor)
        UpdateColor()

        f._filterBtns[#f._filterBtns + 1] = btn
        fx = fx + 74
    end

    -- Scroll area (custom slim scroll — no Blizzard template)
    local scrollFrame = CreateFrame("ScrollFrame", "TomoMod_DiagScroll", f)
    scrollFrame:SetPoint("TOPLEFT", filterBar, "BOTTOMLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 44)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() or 660)
    scrollFrame:SetScrollChild(scrollChild)
    f._scrollChild = scrollChild
    f._scrollFrame = scrollFrame

    -- Slim scroll track + thumb
    local TRACK_W = 3
    local track = CreateFrame("Frame", nil, f)
    track:SetWidth(TRACK_W)
    track:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)
    track:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 0)
    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(0.12, 0.12, 0.15, 0.4)

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(TRACK_W)
    thumb:SetHeight(40)
    thumb:SetPoint("TOP", track, "TOP", 0, 0)
    thumb:EnableMouse(true)
    local thumbTex = thumb:CreateTexture(nil, "OVERLAY")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(0.047, 0.824, 0.624, 0.5)
    thumb:SetScript("OnEnter", function() thumbTex:SetColorTexture(0.047, 0.824, 0.624, 0.8) end)
    thumb:SetScript("OnLeave", function() thumbTex:SetColorTexture(0.047, 0.824, 0.624, 0.5) end)
    thumb._dragging = false

    local function UpdateThumb()
        local viewH = scrollFrame:GetHeight()
        local contentH = scrollChild:GetHeight()
        if contentH <= viewH then
            thumb:Hide()
            trackBg:SetAlpha(0)
            return
        end
        thumb:Show()
        trackBg:SetAlpha(0.4)
        local trackH = track:GetHeight()
        local ratio = viewH / contentH
        local thumbH = max(20, trackH * ratio)
        thumb:SetHeight(thumbH)
        local scrollRange = contentH - viewH
        local current = scrollFrame:GetVerticalScroll()
        local pct = (scrollRange > 0) and (current / scrollRange) or 0
        local yOff = -pct * (trackH - thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, yOff)
    end
    f._updateThumb = UpdateThumb

    -- Thumb dragging
    thumb:RegisterForDrag("LeftButton")
    thumb:SetScript("OnDragStart", function(self)
        self._dragging = true
        self._dragStartY = select(2, GetCursorPosition()) / (self:GetEffectiveScale() or 1)
        self._dragStartScroll = scrollFrame:GetVerticalScroll()
    end)
    thumb:SetScript("OnDragStop", function(self) self._dragging = false end)
    thumb:SetScript("OnUpdate", function(self)
        if not self._dragging then return end
        local curY = select(2, GetCursorPosition()) / (self:GetEffectiveScale() or 1)
        local delta = self._dragStartY - curY
        local trackH = track:GetHeight()
        local thumbH = self:GetHeight()
        local scrollRange = scrollChild:GetHeight() - scrollFrame:GetHeight()
        if scrollRange <= 0 or (trackH - thumbH) <= 0 then return end
        local newScroll = self._dragStartScroll + delta * (scrollRange / (trackH - thumbH))
        newScroll = max(0, min(newScroll, scrollRange))
        scrollFrame:SetVerticalScroll(newScroll)
        UpdateThumb()
    end)

    -- Mouse wheel
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local step = 40
        local current = self:GetVerticalScroll()
        local maxScroll = max(0, scrollChild:GetHeight() - self:GetHeight())
        local newScroll = max(0, min(current - delta * step, maxScroll))
        self:SetVerticalScroll(newScroll)
        UpdateThumb()
    end)

    -- Bottom bar: buttons
    local bottomBar = CreateFrame("Frame", nil, f)
    bottomBar:SetHeight(38)
    bottomBar:SetPoint("BOTTOMLEFT"); bottomBar:SetPoint("BOTTOMRIGHT")

    local bottomBg = bottomBar:CreateTexture(nil, "BACKGROUND")
    bottomBg:SetAllPoints()
    bottomBg:SetColorTexture(0.08, 0.08, 0.10, 1)

    -- Clear button
    local clearBtn = CreateFrame("Button", nil, bottomBar, "BackdropTemplate")
    clearBtn:SetSize(80, 24)
    clearBtn:SetPoint("LEFT", 8, 0)
    clearBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1,
    })
    clearBtn:SetBackdropColor(0.12, 0.06, 0.06, 1)
    clearBtn:SetBackdropBorderColor(0.4, 0.15, 0.15, 1)
    local clearTxt = clearBtn:CreateFontString(nil, "OVERLAY")
    clearTxt:SetFont(FONT_MEDIUM, 10, "")
    clearTxt:SetPoint("CENTER")
    clearTxt:SetText("Clear All")
    clearTxt:SetTextColor(0.8, 0.3, 0.3, 1)
    clearBtn:SetScript("OnClick", function()
        wipe(errors)
        wipe(dedupMap)
        D.RefreshConsole()
    end)

    -- Export button (copies to clipboard via EditBox)
    local exportBtn = CreateFrame("Button", nil, bottomBar, "BackdropTemplate")
    exportBtn:SetSize(120, 24)
    exportBtn:SetPoint("LEFT", clearBtn, "RIGHT", 8, 0)
    exportBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1,
    })
    exportBtn:SetBackdropColor(0.06, 0.08, 0.06, 1)
    exportBtn:SetBackdropBorderColor(0.15, 0.30, 0.15, 1)
    local exportTxt = exportBtn:CreateFontString(nil, "OVERLAY")
    exportTxt:SetFont(FONT_MEDIUM, 10, "")
    exportTxt:SetPoint("CENTER")
    exportTxt:SetText("Copy Report")
    exportTxt:SetTextColor(0.047, 0.824, 0.624, 1)
    exportBtn:SetScript("OnClick", function()
        D.ShowExportFrame()
    end)

    -- Export for tracker button
    local trackerBtn = CreateFrame("Button", nil, bottomBar, "BackdropTemplate")
    trackerBtn:SetSize(140, 24)
    trackerBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
    trackerBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1,
    })
    trackerBtn:SetBackdropColor(0.06, 0.06, 0.10, 1)
    trackerBtn:SetBackdropBorderColor(0.15, 0.15, 0.35, 1)
    local trackerTxt = trackerBtn:CreateFontString(nil, "OVERLAY")
    trackerTxt:SetFont(FONT_MEDIUM, 10, "")
    trackerTxt:SetPoint("CENTER")
    trackerTxt:SetText("Export Tracker")
    trackerTxt:SetTextColor(0.5, 0.6, 1, 1)
    trackerBtn:SetScript("OnClick", function()
        D.ShowExportFrame("tracker")
    end)

    f:Hide()
    consoleFrame = f
    return f
end

-- =====================================================================
-- CONSOLE: REFRESH (rebuild entry list)
-- =====================================================================

local kindColors = {
    [KIND_LUA_ERROR] = { 0.9, 0.3, 0.3 },
    [KIND_TAINT]     = { 1.0, 0.5, 0.2 },
    [KIND_WARNING]   = { 1.0, 0.8, 0.3 },
    [KIND_UI_ERROR]  = { 0.7, 0.5, 0.8 },
    [KIND_DEBUG]     = { 0.5, 0.7, 0.9 },
}

local kindBadges = {
    [KIND_LUA_ERROR] = "|cffee5555ERROR|r",
    [KIND_TAINT]     = "|cffff8833TAINT|r",
    [KIND_WARNING]   = "|cffffcc55WARN|r",
    [KIND_UI_ERROR]  = "|cffaa77ccUI|r",
    [KIND_DEBUG]     = "|cff88bbddDEBUG|r",
}

function D.RefreshConsole()
    if not consoleFrame then return end
    local child = consoleFrame._scrollChild
    if not child then return end

    -- Clear previous entries
    for _, frame in ipairs(scrollEntries) do
        frame:Hide()
        frame:ClearAllPoints()
    end
    wipe(scrollEntries)

    -- Filter
    local filter = consoleFrame._activeFilter or "All"
    local filtered = {}
    for i = #errors, 1, -1 do  -- newest first
        local e = errors[i]
        local pass = false
        if filter == "All" then pass = true
        elseif filter == "Errors" then pass = (e.kind == KIND_LUA_ERROR)
        elseif filter == "Taint" then pass = (e.kind == KIND_TAINT)
        elseif filter == "Warnings" then pass = (e.kind == KIND_WARNING or e.kind == KIND_UI_ERROR)
        elseif filter == "TomoMod" then pass = e.isTomoMod
        end
        if pass then filtered[#filtered + 1] = e end
    end

    -- Update badge
    if consoleFrame._badge then
        local total = #errors
        local tomoCount = 0
        for _, e in ipairs(errors) do
            if e.isTomoMod then tomoCount = tomoCount + 1 end
        end
        consoleFrame._badge:SetText(string.format("(%d total, %d TomoMod)", total, tomoCount))
    end

    -- Render entries
    local y = 0
    local parentWidth = consoleFrame._scrollFrame:GetWidth() or 650
    child:SetWidth(parentWidth - 8)

    for idx, entry in ipairs(filtered) do
        local row = CreateFrame("Frame", nil, child, "BackdropTemplate")
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("TOPRIGHT", 0, -y)

        local colors = kindColors[entry.kind] or { 0.6, 0.6, 0.6 }

        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1,
        })
        local bgAlpha = (idx % 2 == 0) and 0.03 or 0.06
        row:SetBackdropColor(colors[1] * 0.15, colors[2] * 0.15, colors[3] * 0.15, bgAlpha)
        row:SetBackdropBorderColor(colors[1] * 0.3, colors[2] * 0.3, colors[3] * 0.3, 0.3)

        -- Header line: [BADGE] timestamp (xN)
        local header = row:CreateFontString(nil, "OVERLAY")
        header:SetFont(FONT_MEDIUM, 10, "")
        header:SetPoint("TOPLEFT", 6, -4)
        header:SetPoint("TOPRIGHT", -6, -4)
        header:SetJustifyH("LEFT")

        local badge = kindBadges[entry.kind] or entry.kind
        local countStr = (entry.count and entry.count > 1) and string.format(" |cff888888(x%d)|r", entry.count) or ""
        local timeStr = entry.timestamp or ""
        local combatStr = entry.inCombat and " |cffff4444[COMBAT]|r" or ""
        local tomoStr = entry.isTomoMod and " |cff0cd29f[TM]|r" or ""
        header:SetText(badge .. " " .. timeStr .. countStr .. combatStr .. tomoStr)

        -- Message
        local msg = row:CreateFontString(nil, "OVERLAY")
        msg:SetFont(FONT_MONO, 9, "")
        msg:SetPoint("TOPLEFT", 6, -20)
        msg:SetPoint("TOPRIGHT", -6, -20)
        msg:SetJustifyH("LEFT")
        msg:SetWordWrap(true)
        msg:SetMaxLines(3)
        msg:SetTextColor(0.85, 0.85, 0.85, 1)

        local displayMsg = entry.message or ""
        if #displayMsg > 300 then displayMsg = displayMsg:sub(1, 300) .. "..." end
        msg:SetText(displayMsg)

        local msgHeight = msg:GetStringHeight() or 14
        local rowHeight = 24 + msgHeight + 6

        -- Expand button for stack trace
        if entry.stack then
            local expandBtn = CreateFrame("Button", nil, row)
            expandBtn:SetSize(16, 16)
            expandBtn:SetPoint("TOPRIGHT", -6, -3)
            local expandTxt = expandBtn:CreateFontString(nil, "OVERLAY")
            expandTxt:SetFont(FONT, 10, "")
            expandTxt:SetPoint("CENTER")
            expandTxt:SetText("+")
            expandTxt:SetTextColor(0.5, 0.5, 0.55, 1)

            local expanded = false
            local stackText = nil

            expandBtn:SetScript("OnClick", function()
                expanded = not expanded
                if expanded then
                    expandTxt:SetText("-")
                    if not stackText then
                        stackText = row:CreateFontString(nil, "OVERLAY")
                        stackText:SetFont(FONT_MONO, 8, "")
                        stackText:SetPoint("TOPLEFT", msg, "BOTTOMLEFT", 0, -4)
                        stackText:SetPoint("TOPRIGHT", msg, "BOTTOMRIGHT", 0, -4)
                        stackText:SetJustifyH("LEFT")
                        stackText:SetWordWrap(true)
                        stackText:SetTextColor(0.55, 0.55, 0.60, 1)
                    end
                    local stackStr = entry.stack or ""
                    if #stackStr > 1000 then stackStr = stackStr:sub(1, 1000) .. "\n..." end
                    stackText:SetText(stackStr)
                    stackText:Show()
                    local stackH = stackText:GetStringHeight() or 14
                    row:SetHeight(rowHeight + stackH + 4)
                else
                    expandTxt:SetText("+")
                    if stackText then stackText:Hide() end
                    row:SetHeight(rowHeight)
                end
                -- Reflow would be complex; just note it expands in place
            end)
        end

        row:SetHeight(rowHeight)
        y = y + rowHeight + 2
        scrollEntries[#scrollEntries + 1] = row
    end

    child:SetHeight(y + 20)

    -- Update custom scrollbar thumb
    if consoleFrame._updateThumb then
        C_Timer.After(0.01, consoleFrame._updateThumb)
    end
end

-- =====================================================================
-- EXPORT FRAME (text copy via EditBox)
-- =====================================================================

local exportFrame = nil

function D.ShowExportFrame(mode)
    mode = mode or "readable"

    if not exportFrame then
        local ef = CreateFrame("Frame", "TomoMod_DiagExport", UIParent, "BackdropTemplate")
        ef:SetSize(600, 450)
        ef:SetPoint("CENTER")
        ef:SetFrameStrata("FULLSCREEN_DIALOG")
        ef:SetMovable(true)
        ef:EnableMouse(true)
        ef:RegisterForDrag("LeftButton")
        ef:SetScript("OnDragStart", ef.StartMoving)
        ef:SetScript("OnDragStop", ef.StopMovingOrSizing)
        ef:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1,
        })
        ef:SetBackdropColor(0.05, 0.05, 0.07, 0.98)
        ef:SetBackdropBorderColor(0.047, 0.824, 0.624, 0.6)

        -- Title
        local title = ef:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT, 12, "")
        title:SetPoint("TOP", 0, -10)
        title:SetTextColor(0.047, 0.824, 0.624, 1)
        ef._title = title

        -- Close
        local closeBtn = CreateFrame("Button", nil, ef)
        closeBtn:SetSize(24, 24)
        closeBtn:SetPoint("TOPRIGHT", -6, -6)
        local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY")
        closeTxt:SetFont(FONT, 14, "")
        closeTxt:SetPoint("CENTER")
        closeTxt:SetText("x")
        closeTxt:SetTextColor(0.5, 0.5, 0.55, 1)
        closeBtn:SetScript("OnClick", function() ef:Hide() end)

        -- Hint
        local hint = ef:CreateFontString(nil, "OVERLAY")
        hint:SetFont(FONT_MEDIUM, 9, "")
        hint:SetPoint("TOP", 0, -28)
        hint:SetTextColor(0.5, 0.5, 0.55, 1)
        hint:SetText("Ctrl+A then Ctrl+C to copy")

        -- EditBox in a custom slim scroll
        local scrollFrame = CreateFrame("ScrollFrame", "TomoMod_DiagExportScroll", ef)
        scrollFrame:SetPoint("TOPLEFT", 10, -46)
        scrollFrame:SetPoint("BOTTOMRIGHT", -14, 10)

        local editBox = CreateFrame("EditBox", "TomoMod_DiagExportEdit", scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(GameFontHighlightSmall)
        editBox:SetFont(FONT_MONO, 9, "")
        editBox:SetWidth(scrollFrame:GetWidth() or 550)
        editBox:SetAutoFocus(true)
        editBox:SetScript("OnEscapePressed", function() ef:Hide() end)
        scrollFrame:SetScrollChild(editBox)

        -- Slim scroll track for export
        local eTrack = CreateFrame("Frame", nil, ef)
        eTrack:SetWidth(3)
        eTrack:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)
        eTrack:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 0)
        local eTrackBg = eTrack:CreateTexture(nil, "BACKGROUND")
        eTrackBg:SetAllPoints()
        eTrackBg:SetColorTexture(0.12, 0.12, 0.15, 0.4)

        local eThumb = CreateFrame("Button", nil, eTrack)
        eThumb:SetWidth(3)
        eThumb:SetHeight(40)
        eThumb:SetPoint("TOP", eTrack, "TOP", 0, 0)
        eThumb:EnableMouse(true)
        local eThumbTex = eThumb:CreateTexture(nil, "OVERLAY")
        eThumbTex:SetAllPoints()
        eThumbTex:SetColorTexture(0.047, 0.824, 0.624, 0.5)
        eThumb:SetScript("OnEnter", function() eThumbTex:SetColorTexture(0.047, 0.824, 0.624, 0.8) end)
        eThumb:SetScript("OnLeave", function() eThumbTex:SetColorTexture(0.047, 0.824, 0.624, 0.5) end)

        local function UpdateExportThumb()
            local viewH = scrollFrame:GetHeight()
            local contentH = editBox:GetHeight()
            if contentH <= viewH then eThumb:Hide(); return end
            eThumb:Show()
            local trackH = eTrack:GetHeight()
            local ratio = viewH / contentH
            local thumbH = max(20, trackH * ratio)
            eThumb:SetHeight(thumbH)
            local scrollRange = contentH - viewH
            local current = scrollFrame:GetVerticalScroll()
            local pct = (scrollRange > 0) and (current / scrollRange) or 0
            local yOff = -pct * (trackH - thumbH)
            eThumb:ClearAllPoints()
            eThumb:SetPoint("TOP", eTrack, "TOP", 0, yOff)
        end

        eThumb._dragging = false
        eThumb:RegisterForDrag("LeftButton")
        eThumb:SetScript("OnDragStart", function(self)
            self._dragging = true
            self._dragStartY = select(2, GetCursorPosition()) / (self:GetEffectiveScale() or 1)
            self._dragStartScroll = scrollFrame:GetVerticalScroll()
        end)
        eThumb:SetScript("OnDragStop", function(self) self._dragging = false end)
        eThumb:SetScript("OnUpdate", function(self)
            if not self._dragging then return end
            local curY = select(2, GetCursorPosition()) / (self:GetEffectiveScale() or 1)
            local delta = self._dragStartY - curY
            local trackH = eTrack:GetHeight()
            local thumbH = self:GetHeight()
            local scrollRange = editBox:GetHeight() - scrollFrame:GetHeight()
            if scrollRange <= 0 or (trackH - thumbH) <= 0 then return end
            local newScroll = self._dragStartScroll + delta * (scrollRange / (trackH - thumbH))
            newScroll = max(0, min(newScroll, scrollRange))
            scrollFrame:SetVerticalScroll(newScroll)
            UpdateExportThumb()
        end)

        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local step = 40
            local current = self:GetVerticalScroll()
            local maxScroll = max(0, editBox:GetHeight() - self:GetHeight())
            local newScroll = max(0, min(current - delta * step, maxScroll))
            self:SetVerticalScroll(newScroll)
            UpdateExportThumb()
        end)

        ef._editBox = editBox
        ef._scrollFrame = scrollFrame
        ef._updateThumb = UpdateExportThumb
        ef:Hide()
        exportFrame = ef
    end

    -- Generate report
    local text
    if mode == "tracker" then
        exportFrame._title:SetText("Export for tracker-tomomod.onkoz.fr")
        text = D.BuildTrackerReport()
    else
        exportFrame._title:SetText("Diagnostics Report")
        text = D.BuildReadableReport()
    end

    exportFrame._editBox:SetText(text)
    exportFrame._editBox:SetWidth(exportFrame._scrollFrame:GetWidth() or 540)
    exportFrame:Show()
    exportFrame._editBox:HighlightText()
    exportFrame._editBox:SetFocus()
    if exportFrame._updateThumb then
        C_Timer.After(0.01, exportFrame._updateThumb)
    end
end

-- =====================================================================
-- REPORT BUILDERS
-- =====================================================================

function D.BuildReadableReport()
    local lines = {}
    lines[#lines + 1] = "============================================"
    lines[#lines + 1] = "TomoMod Diagnostics Report"
    lines[#lines + 1] = "Generated: " .. GetTimestamp()
    lines[#lines + 1] = "Session: #" .. sessionID
    lines[#lines + 1] = "============================================"
    lines[#lines + 1] = ""

    -- Environment
    lines[#lines + 1] = "--- Environment ---"
    lines[#lines + 1] = "Addon Version: " .. (envSnapshot.addonVersion or "?")
    lines[#lines + 1] = "WoW Build: " .. (envSnapshot.wowBuild or "?")
    lines[#lines + 1] = "TOC: " .. SafeToString(envSnapshot.tocVersion)
    lines[#lines + 1] = "Player: " .. (envSnapshot.playerName or "?")
    lines[#lines + 1] = "Class: " .. (envSnapshot.playerClass or "?")
    lines[#lines + 1] = "Level: " .. SafeToString(envSnapshot.playerLevel)
    lines[#lines + 1] = "Locale: " .. (envSnapshot.locale or "?")
    lines[#lines + 1] = "Resolution: " .. SafeToString(envSnapshot.screenWidth) .. "x" .. SafeToString(envSnapshot.screenHeight)
    lines[#lines + 1] = ""

    -- Errors
    lines[#lines + 1] = "--- Errors (" .. #errors .. " total) ---"
    lines[#lines + 1] = ""

    for i, entry in ipairs(errors) do
        local badge = entry.kind or "?"
        local countStr = (entry.count and entry.count > 1) and " (x" .. entry.count .. ")" or ""
        lines[#lines + 1] = string.format("[%d] %s %s%s%s",
            i, badge, entry.timestamp or "",
            entry.isTomoMod and " [TomoMod]" or "",
            countStr)
        lines[#lines + 1] = "  Message: " .. (entry.message or "")
        if entry.stack then
            lines[#lines + 1] = "  Stack:"
            for line in entry.stack:gmatch("[^\n]+") do
                lines[#lines + 1] = "    " .. line
            end
        end
        if entry.locals then
            lines[#lines + 1] = "  Locals:"
            local localStr = entry.locals
            if #localStr > 500 then localStr = localStr:sub(1, 500) .. "..." end
            for line in localStr:gmatch("[^\n]+") do
                lines[#lines + 1] = "    " .. line
            end
        end
        lines[#lines + 1] = ""
    end

    -- Loaded addons
    if envSnapshot.addons then
        lines[#lines + 1] = "--- Loaded Addons ---"
        for _, a in ipairs(envSnapshot.addons) do
            lines[#lines + 1] = "  " .. a.name .. " v" .. a.version
        end
    end

    return table.concat(lines, "\n")
end

function D.BuildTrackerReport()
    -- Structured format for tracker-tomomod.onkoz.fr
    -- Delimited blocks for easy parsing
    local lines = {}
    lines[#lines + 1] = "@@TOMOMOD_DIAG@@"
    lines[#lines + 1] = "version=" .. VERSION
    lines[#lines + 1] = "generated=" .. GetTimestamp()
    lines[#lines + 1] = "session=" .. sessionID
    lines[#lines + 1] = ""

    -- Environment block
    lines[#lines + 1] = "[env]"
    lines[#lines + 1] = "addon_version=" .. (envSnapshot.addonVersion or "?")
    lines[#lines + 1] = "wow_build=" .. (envSnapshot.wowBuild or "?")
    lines[#lines + 1] = "toc_version=" .. SafeToString(envSnapshot.tocVersion)
    lines[#lines + 1] = "player=" .. (envSnapshot.playerName or "?")
    lines[#lines + 1] = "class=" .. (envSnapshot.playerClass or "?")
    lines[#lines + 1] = "level=" .. SafeToString(envSnapshot.playerLevel)
    lines[#lines + 1] = "locale=" .. (envSnapshot.locale or "?")
    lines[#lines + 1] = "resolution=" .. SafeToString(envSnapshot.screenWidth) .. "x" .. SafeToString(envSnapshot.screenHeight)
    lines[#lines + 1] = ""

    -- Addons block
    lines[#lines + 1] = "[addons]"
    if envSnapshot.addons then
        for _, a in ipairs(envSnapshot.addons) do
            lines[#lines + 1] = a.name .. "=" .. a.version
        end
    end
    lines[#lines + 1] = ""

    -- Error blocks
    local total = #errors
    for i, entry in ipairs(errors) do
        lines[#lines + 1] = string.format("[error %d/%d]", i, total)
        lines[#lines + 1] = "kind=" .. (entry.kind or "?")
        lines[#lines + 1] = "timestamp=" .. (entry.timestamp or "")
        lines[#lines + 1] = "count=" .. SafeToString(entry.count or 1)
        lines[#lines + 1] = "is_tomomod=" .. SafeToString(entry.isTomoMod)
        lines[#lines + 1] = "in_combat=" .. SafeToString(entry.inCombat)

        if entry.meta then
            local metaParts = {}
            for k, v in pairs(entry.meta) do
                metaParts[#metaParts + 1] = k .. "=" .. SafeToString(v)
            end
            if #metaParts > 0 then
                lines[#lines + 1] = "meta=" .. table.concat(metaParts, ";")
            end
        end

        lines[#lines + 1] = "msg<<<" .. (entry.message or "") .. ">>>"

        if entry.stack then
            lines[#lines + 1] = "stack<<<" .. entry.stack .. ">>>"
        end
        if entry.locals then
            local localStr = entry.locals
            if #localStr > 2000 then localStr = localStr:sub(1, 2000) end
            lines[#lines + 1] = "locals<<<" .. localStr .. ">>>"
        end
        lines[#lines + 1] = ""
    end

    lines[#lines + 1] = "@@END@@"
    return table.concat(lines, "\n")
end

-- =====================================================================
-- PUBLIC API
-- =====================================================================

function D.ShowConsole()
    if not consoleFrame then CreateConsole() end
    consoleFrame:Show()
    D.RefreshConsole()
end

function D.HideConsole()
    if consoleFrame then consoleFrame:Hide() end
end

function D.ToggleConsole()
    if consoleFrame and consoleFrame:IsShown() then
        D.HideConsole()
    else
        D.ShowConsole()
    end
end

function D.GetErrorCount()
    return #errors
end

function D.GetTomoModErrorCount()
    local count = 0
    for _, e in ipairs(errors) do
        if e.isTomoMod then count = count + 1 end
    end
    return count
end

-- External logging API (for other TomoMod modules)
function D.LogDebug(message)
    CaptureEntry(KIND_DEBUG, SafeToString(message))
end

function D.LogDebugSource(source, message)
    CaptureEntry(KIND_DEBUG, "[" .. SafeToString(source) .. "] " .. SafeToString(message))
end

-- =====================================================================
-- SLASH COMMAND
-- =====================================================================

SLASH_TOMODIAG1 = "/tmdiag"
SLASH_TOMODIAG2 = "/tomodiag"
SlashCmdList["TOMODIAG"] = function(msg)
    msg = (msg or ""):trim():lower()
    if msg == "clear" then
        wipe(errors)
        wipe(dedupMap)
        print(ADDON_PREFIX .. " |cffaaaaaaDiagnostics cleared.|r")
    elseif msg == "export" then
        D.ShowExportFrame()
    elseif msg == "tracker" then
        D.ShowExportFrame("tracker")
    elseif msg == "on" then
        if db then db.enabled = true end
        InstallErrorHandler()
        if db and db.suppressPopups then SuppressScriptErrors() end
        print(ADDON_PREFIX .. " |cff0cd29fDiagnostics enabled.|r")
    elseif msg == "off" then
        if db then db.enabled = false end
        RestoreScriptErrors()
        print(ADDON_PREFIX .. " |cffaaaaaaDiagnostics disabled.|r")
    else
        D.ToggleConsole()
    end
end

-- =====================================================================
-- BOOT
-- =====================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
eventFrame:RegisterEvent("ADDON_ACTION_BLOCKED")

-- LUA_WARNING may not exist on all clients
if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid("LUA_WARNING") then
    eventFrame:RegisterEvent("LUA_WARNING")
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == ADDON_NAME then
            EnsureDB()
            L = TomoMod_L
            -- Read real addon version from TOC metadata
            local getMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
            VERSION = getMetadata and getMetadata(ADDON_NAME, "Version") or "?"
        end

    elseif event == "PLAYER_LOGIN" then
        if not IsEnabled() then return end
        BuildExclusionSet()
        CaptureEnvironment()
        InstallErrorHandler()
        if db.suppressPopups then
            SuppressScriptErrors()
        end
        -- Register UI_ERROR_MESSAGE
        eventFrame:RegisterEvent("UI_ERROR_MESSAGE")

    elseif event == "ADDON_ACTION_FORBIDDEN" or event == "ADDON_ACTION_BLOCKED" then
        OnTaintEvent(event, ...)

    elseif event == "LUA_WARNING" then
        OnLuaWarning(event, ...)

    elseif event == "UI_ERROR_MESSAGE" then
        OnUiError(event, ...)
    end
end)

-- =====================================================================
-- MythicTracker.lua — Mythic+ Dungeon Tracker (integrated from TomoMythic)
-- Replaces Blizzard's M+ objective tracker with a custom dark panel:
--   header (dungeon name, key level, affixes, deaths),
--   timer bar with chest countdowns,
--   forces bar,
--   boss kill timers,
--   completion banner.
-- =====================================================================

local L = TomoMod_L
local TMT = {}
TomoMod_MythicTracker = TMT

-- ═══════════════════════════════════════════════════════════════════════
--  COLOR PALETTE — derived from the TomoMod brand tokens
--  Built lazily rather than at parse time: Config/Widgets.lua does load
--  before this module, but a parse-time dependency on it would be a trap
--  for anyone reordering the TOC. Falls back to U.BRAND, then to the
--  literal mint, so the tracker always renders.
-- ═══════════════════════════════════════════════════════════════════════
TMT.C = {}

-- Linear blend between two {r,g,b} tables. Used for the forces ramp.
local function Mix(a, b, t)
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    return a[1] + (b[1] - a[1]) * t,
           a[2] + (b[2] - a[2]) * t,
           a[3] + (b[3] - a[3]) * t
end

local function ToHex(c)
    return string.format("%02x%02x%02x",
        math.floor(c[1] * 255 + 0.5),
        math.floor(c[2] * 255 + 0.5),
        math.floor(c[3] * 255 + 0.5))
end

function TMT:BuildPalette()
    local U  = TomoMod_Utils
    local TH = TomoMod_Widgets and TomoMod_Widgets.Theme
    local db = TomoModDB and TomoModDB.MythicTracker
    local custom = db and db.useCustomColors and type(db.colors) == "table" and db.colors or nil

    local function ResolveColor(value, fallback)
        if type(value) ~= "table" then return { fallback[1], fallback[2], fallback[3] } end
        return {
            tonumber(value.r or value[1]) or fallback[1],
            tonumber(value.g or value[2]) or fallback[2],
            tonumber(value.b or value[3]) or fallback[3],
        }
    end

    local baseBrand = (U and U.BRAND) or { 0.180, 0.847, 0.518 }
    local BRAND = ResolveColor(custom and custom.accent, baseBrand)
    local DARK  = custom and { BRAND[1] * 0.58, BRAND[2] * 0.58, BRAND[3] * 0.58 }
        or ((U and U.BRAND_DARK) or { 0.110, 0.541, 0.333 })
    local HOVER = custom and {
        math.min(1, BRAND[1] * 1.18 + 0.08),
        math.min(1, BRAND[2] * 1.18 + 0.08),
        math.min(1, BRAND[3] * 1.18 + 0.08),
    } or ((U and U.BRAND_HOVER) or { 0.322, 0.941, 0.651 })

    local text    = ResolveColor(custom and custom.text,       (TH and TH.text)    or { 0.88, 0.90, 0.89 })
    local textDim = ResolveColor(nil,                          (TH and TH.textDim) or { 0.48, 0.48, 0.54 })
    local border  = ResolveColor(nil,                          (TH and TH.border)  or { 0.18, 0.18, 0.22 })
    local red     = ResolveColor(custom and custom.danger,     (TH and TH.red)     or { 0.88, 0.22, 0.22 })
    local yellow  = ResolveColor(custom and custom.warning,    (TH and TH.yellow)  or { 0.96, 0.80, 0.10 })
    local comfort = ResolveColor(custom and custom.comfort,    BRAND)
    local forces  = ResolveColor(custom and custom.forces,     BRAND)
    local bg      = ResolveColor(custom and custom.background, { 0.035, 0.055, 0.046 })
    local header  = ResolveColor(custom and custom.header,     { 0.055, 0.092, 0.076 })

    local C = self.C
    for k in pairs(C) do C[k] = nil end

    C.BG         = { bg[1], bg[2], bg[3], 0.88 }
    C.BG_HEADER  = { header[1], header[2], header[3], 1.00 }
    C.BG_ROW_ALT = { header[1], header[2], header[3], 0.45 }
    C.BAR_TRACK  = { (bg[1]+header[1])*0.5, (bg[2]+header[2])*0.5, (bg[3]+header[3])*0.5, 1.00 }

    C.ACCENT = { BRAND[1], BRAND[2], BRAND[3], 1.00 }
    C.BORDER = { border[1], border[2], border[3], 0.85 }
    C.SEP    = { BRAND[1], BRAND[2], BRAND[3], 0.30 }

    C.SEG_RAMP = {
        [3] = { { DARK[1], DARK[2], DARK[3] }, { comfort[1], comfort[2], comfort[3] } },
        [2] = { { bg[1], bg[2], bg[3] },       { yellow[1],  yellow[2],  yellow[3]  } },
        [1] = { { bg[1], bg[2], bg[3] },       { red[1],     red[2],     red[3]     } },
    }
    C.SEG_RAMP_BRAND = { { DARK[1], DARK[2], DARK[3] }, { comfort[1], comfort[2], comfort[3] } }

    C.SEG_FILL = { comfort[1], comfort[2], comfort[3], 0.85 }
    C.SEG_DONE = { DARK[1],    DARK[2],    DARK[3],    0.85 }
    C.SEG_LOST = { red[1],     red[2],     red[3],     0.80 }

    C.FORCES_LOW  = { (bg[1]+forces[1])*0.5, (bg[2]+forces[2])*0.5, (bg[3]+forces[3])*0.5 }
    C.FORCES_HIGH = { forces[1], forces[2], forces[3] }
    C.FORCES_DONE = { HOVER[1], HOVER[2], HOVER[3], 0.90 }

    C.TEXT_WHITE  = { text[1], text[2], text[3], 1 }
    C.TEXT_GREY   = { textDim[1], textDim[2], textDim[3], 1 }
    C.TEXT_BRAND  = { BRAND[1], BRAND[2], BRAND[3], 1 }
    C.TEXT_YELLOW = { yellow[1], yellow[2], yellow[3], 1 }
    C.TEXT_RED    = { red[1], red[2], red[3], 1 }
    C.TEXT_SKULL  = { red[1], red[2], red[3], 1 }
    C.ON_FILL     = { 0.96, 0.99, 0.97, 1 }

    C.HEX_BRAND = ToHex(BRAND)
    C.HEX_RED   = ToHex(red)
    C.HEX_GREY  = ToHex(textDim)

    return C
end
-- ═══════════════════════════════════════════════════════════════════════
--  LAYOUT CONSTANTS
-- ═══════════════════════════════════════════════════════════════════════
TMT.W             = 300
TMT.PAD           = 9    -- inner horizontal padding for bars and text
TMT.HEADER_H_FULL = 34   -- dungeon name line + affix / key level line
TMT.HEADER_H_SLIM = 22   -- single line: deaths | affixes | key level
TMT.TIMER_LINE_H  = 26   -- elapsed, time limit, delta
TMT.SEG_H         = 18   -- segmented timer bar
TMT.BAR_H         = 18   -- forces bar
TMT.BOSS_H        = 18
TMT.GAP           = 2
TMT.SEG_GAP       = 2
TMT.EDGE          = 1
TMT.UPDATE_RATE   = 0.20
TMT.BOSS_NAME_MAX = 22

-- Bundled fonts. Poppins matches the config UI, Expressway is the
-- condensed face the HUD preset is designed around.
TMT.FONT_PANEL = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
TMT.FONT_HUD   = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Expressway.TTF"

-- ═══════════════════════════════════════════════════════════════════════
--  PRESETS
--  A preset is nothing but a set of values for the style toggles. The
--  moment the player flips one of those toggles by hand the preset key
--  moves to "custom", exactly like the UnitFrames preset engine — the
--  named presets stay meaningful instead of silently drifting.
-- ═══════════════════════════════════════════════════════════════════════
TMT.STYLE_KEYS = {
    "showBackground", "showHeaderBlock", "showDungeonName",
    "objectiveStyle", "timerLayout", "segmentColors", "fontLSM", "fontScale",
}

TMT.PRESETS = {
    panel = {
        showBackground  = true,
        showHeaderBlock = true,
        showDungeonName = false,
        objectiveStyle  = "rows",
        timerLayout     = "stacked",
        segmentColors   = "palier",
        fontLSM         = "",
        fontScale       = 1.0,
    },
    hud = {
        showBackground  = false,
        showHeaderBlock = false,
        showDungeonName = false,
        objectiveStyle  = "text",
        timerLayout     = "stacked",
        segmentColors   = "palier",
        fontLSM         = "",
        fontScale       = 1.15,
    },
    -- Three rows and nothing else: information, timer, forces. The boss
    -- list is gone, so its progress moves into the information row.
    minimal = {
        showBackground  = false,
        showHeaderBlock = false,
        showDungeonName = false,
        objectiveStyle  = "none",
        timerLayout     = "inline",
        segmentColors   = "palier",
        fontLSM         = "",
        fontScale       = 1.0,
    },
}

-- ═══════════════════════════════════════════════════════════════════════
--  DB ACCESS
-- ═══════════════════════════════════════════════════════════════════════
local function GetDB()
    return TomoModDB and TomoModDB.MythicTracker
end

-- ═══════════════════════════════════════════════════════════════════════
--  PRESET HELPERS
-- ═══════════════════════════════════════════════════════════════════════

-- Write a named preset's style values into the database. Unknown names
-- are ignored so a profile carrying "custom" (or a preset removed in a
-- later version) never wipes the player's settings.
function TMT:ApplyPreset(name)
    local db  = GetDB()
    local set = self.PRESETS[name]
    if not db or not set then return false end
    for key, value in pairs(set) do
        db[key] = value
    end
    db.preset = name
    return true
end

-- Called whenever a style toggle is changed by hand. Returns the preset
-- key the database now sits on: the named preset if every value still
-- matches it, "custom" otherwise.
function TMT:ResolvePreset()
    local db = GetDB()
    if not db then return "custom" end
    for name, set in pairs(self.PRESETS) do
        local match = true
        for key, value in pairs(set) do
            if db[key] ~= value then match = false; break end
        end
        if match then db.preset = name; return name end
    end
    db.preset = "custom"
    return "custom"
end

-- ═══════════════════════════════════════════════════════════════════════
--  SECRET VALUE HELPERS
--  In 12.x a growing number of API returns are opaque in combat. The
--  rule this module follows: call issecretvalue() BEFORE any comparison,
--  arithmetic or concatenation, and never assume a field is readable
--  just because it was last time.
-- ═══════════════════════════════════════════════════════════════════════
local _issecret = issecretvalue

local function IsSecret(v)
    if not _issecret then return false end
    local ok, secret = pcall(_issecret, v)
    return ok and secret or false
end

local function SafeNum(v)
    if v == nil or IsSecret(v) then return nil end
    return type(v) == "number" and v or nil
end

local function SafeBool(v)
    if v == nil or IsSecret(v) then return nil end
    return v and true or false
end

-- A string is only usable if the client will actually hand us its
-- characters. Pattern-matching an opaque string is the string equivalent
-- of comparing a secret number, so the guard runs first.
local function SafeStr(v)
    if v == nil or IsSecret(v) then return nil end
    return type(v) == "string" and v or nil
end

-- ═══════════════════════════════════════════════════════════════════════
--  FONT / UTILITY HELPERS
-- ═══════════════════════════════════════════════════════════════════════

-- Every FontString the tracker creates is registered here with the size
-- and flags it was built at, so a font or scale change can be re-applied
-- in place instead of forcing a frame rebuild.
TMT._fontStrings = {}

function TMT:GetFont(size, flags)
    local db    = GetDB()
    local scale = (db and db.fontScale) or 1
    local path

    -- LibStub is vendored, but guard anyway: a broken LSM stub registers
    -- as a truthy table with no Fetch, which would error on call.
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM and LSM.Fetch and db and db.fontLSM and db.fontLSM ~= "" then
        local fetched = LSM:Fetch("font", db.fontLSM, true)
        if fetched and fetched ~= "" then path = fetched end
    end

    if not path then
        path = ((db and db.preset) == "hud") and self.FONT_HUD or self.FONT_PANEL
    end

    return path, math.max(6, math.floor((size or 12) * scale + 0.5)), flags or "OUTLINE"
end

-- Re-apply the resolved font to every registered FontString.
function TMT:ApplyFonts()
    for i = 1, #self._fontStrings do
        local entry = self._fontStrings[i]
        if entry.fs then
            entry.fs:SetFont(self:GetFont(entry.size, entry.flags))
        end
    end
end

function TMT:FormatTime(sec, doCeil)
    if not sec then return "--:--" end
    -- Magnitude only. A negative slipped through here once and the modulo
    -- arithmetic turned -3:40 into "56:20" on screen; sign is the caller's
    -- business, and FormatDelta already owns it.
    sec = math.abs(sec)
    if doCeil then sec = math.ceil(sec) else sec = math.floor(sec) end
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s)
    else          return string.format("%d:%02d", m, s) end
end

function TMT:FormatDelta(diff)
    local sign = diff >= 0 and "+" or "-"
    return sign .. self:FormatTime(math.abs(diff))
end

function TMT:MakeBG(parent, r, g, b, a)
    local t = parent:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints(parent)
    t:SetColorTexture(r, g, b, a)
    return t
end

function TMT:MakeBorder(parent, r, g, b, a, size)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetAllPoints(parent)
    f:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = size or TMT.EDGE })
    f:SetBackdropBorderColor(r, g, b, a or 1)
    return f
end

function TMT:MakeLineBorders(parent, r, g, b, a, size)
    size = size or 1
    local c = { r, g, b, a or 1 }
    for _, info in ipairs({
        { "TOPLEFT",    "TOPRIGHT",    "h", size },
        { "BOTTOMLEFT", "BOTTOMRIGHT", "h", size },
        { "TOPLEFT",    "BOTTOMLEFT",  "v", size },
        { "TOPRIGHT",   "BOTTOMRIGHT", "v", size },
    }) do
        local t = parent:CreateTexture(nil, "BORDER")
        t:SetColorTexture(unpack(c))
        t:SetPoint(info[1], parent, info[1])
        t:SetPoint(info[2], parent, info[2])
        if info[3] == "h" then t:SetHeight(info[4])
        else                    t:SetWidth(info[4]) end
    end
end

function TMT:MakeFS(parent, size, flags, anchor, relTo, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(self:GetFont(size, flags))
    fs:SetShadowColor(0, 0, 0, 0.9)
    fs:SetShadowOffset(1, -1)
    if anchor then
        fs:SetPoint(anchor, relTo or parent, anchor, x or 0, y or 0)
    end
    self._fontStrings[#self._fontStrings + 1] = { fs = fs, size = size, flags = flags }
    return fs
end

-- UTF-8 safe substring (for boss names with special characters)
function TMT:Utf8Sub(str, startChar, numChars)
    if not str then return "" end
    local i = 1
    local curChar = 0
    local len = #str
    while i <= len and curChar < startChar - 1 do
        local byte = string.byte(str, i)
        if byte < 128 then i = i + 1
        elseif byte < 224 then i = i + 2
        elseif byte < 240 then i = i + 3
        else i = i + 4 end
        curChar = curChar + 1
    end
    local startByte = i
    curChar = 0
    while i <= len and curChar < numChars do
        local byte = string.byte(str, i)
        if byte < 128 then i = i + 1
        elseif byte < 224 then i = i + 2
        elseif byte < 240 then i = i + 3
        else i = i + 4 end
        curChar = curChar + 1
    end
    return string.sub(str, startByte, i - 1)
end

-- ═══════════════════════════════════════════════════════════════════════
--  EJ BOSS NAME LOOKUP
--  Mirrors WarpDeplete's approach: load the Encounter Journal addon and
--  resolve boss names via EJ_GetEncounterInfoByIndex so we display proper
--  localised names instead of the raw scenario criteriaString.
-- ═══════════════════════════════════════════════════════════════════════

-- [NO ROTTING DATA] This module used to carry a hand-written
-- challengeMapID -> journalInstanceID table copied from another addon.
-- Blizzard adds challenge maps every season and reuses journal instances
-- across them, so such a table is wrong the day a patch ships and nobody
-- notices until boss names silently degrade to "Boss 1".
--
-- Resolution is now entirely live, in three tiers:
--   1. Walk the player's map hierarchy calling EJ_GetInstanceForMap.
--      Multi-floor dungeons often have no mapping on the floor the
--      player stands on, but the parent map does.
--   2. Match the challenge map's client-supplied name against the
--      Encounter Journal's dungeon list, across every tier.
--   3. Give up. FindBossName already falls back to the raw criteria
--      description, so the tracker degrades instead of breaking.
--
-- A successful resolution is remembered in the database, keyed by
-- challengeMapID. That cache is learned at runtime and never authored,
-- so unlike the old table it cannot be stale: a wrong entry could only
-- come from the client itself.

-- Lower-case and strip everything that is not a letter or digit, so
-- punctuation and article differences between the challenge-mode name
-- and the journal name do not defeat the match.
local function NormalizeName(name)
    if type(name) ~= "string" then return nil end
    name = name:lower():gsub("[^%w]", "")
    return name ~= "" and name or nil
end

local function LearnedEJ()
    local db = GetDB()
    if not db then return nil end
    if type(db.learnedEJ) ~= "table" then db.learnedEJ = {} end
    return db.learnedEJ
end

-- Tier 1 — climb the map hierarchy.
local function InstanceFromMapChain()
    local mapID = C_Map.GetBestMapForUnit("player")
    local guard = 0
    while mapID and mapID ~= 0 and guard < 10 do
        local ok, instanceID = pcall(EJ_GetInstanceForMap, mapID)
        if ok and instanceID and instanceID ~= 0 then return instanceID end
        local info = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
        mapID = info and info.parentMapID
        guard = guard + 1
    end
    return nil
end

-- Tier 2 — scan the journal's dungeon list for a matching name.
local function InstanceFromName(challengeMapID)
    if not challengeMapID then return nil end
    local wanted = NormalizeName(C_ChallengeMode.GetMapUIInfo(challengeMapID))
    if not wanted then return nil end

    local numTiers = EJ_GetNumTiers and EJ_GetNumTiers() or 0
    if numTiers < 1 then return nil end
    local savedTier = EJ_GetCurrentTier and EJ_GetCurrentTier() or nil

    local found
    for tier = numTiers, 1, -1 do   -- newest expansion first
        if EJ_SelectTier then EJ_SelectTier(tier) end
        local index = 1
        while true do
            local id, name = EJ_GetInstanceByIndex(index, false)
            if not id then break end
            local norm = NormalizeName(name)
            if norm then
                -- Exact match wins. Otherwise accept containment, which
                -- covers the cases where one journal instance is split
                -- across several challenge maps under longer names.
                if norm == wanted then
                    found = id
                    break
                elseif not found and (wanted:find(norm, 1, true) or norm:find(wanted, 1, true)) then
                    found = id
                end
            end
            index = index + 1
        end
        if found then break end
    end

    if savedTier and EJ_SelectTier then EJ_SelectTier(savedTier) end
    return found
end

-- Returns the EJ journalInstanceID for the current M+ map, or nil.
function TMT:GetEJInstanceID()
    local challengeMapID = C_ChallengeMode.GetActiveChallengeMapID()

    local cache = LearnedEJ()
    if cache and challengeMapID and cache[challengeMapID] then
        return cache[challengeMapID]
    end

    local instanceID = InstanceFromMapChain() or InstanceFromName(challengeMapID)

    if instanceID and cache and challengeMapID then
        cache[challengeMapID] = instanceID
    end
    return instanceID
end

-- Loads the EJ addon if needed, then returns two tables:
--   byIndex[i]              = boss name at position i
--   byEncounterID[encID]    = boss name by dungeonEncounterID
-- Returns nil, nil on failure.
function TMT:FetchEJBossNames()
    local instanceID = self:GetEJInstanceID()
    if not instanceID then return nil, nil end

    local wasShown = EncounterJournal and EncounterJournal:IsShown()
    C_AddOns.LoadAddOn("Blizzard_EncounterJournal")
    -- EncounterJournal_OpenJournal can taint in 12.x — wrap in pcall
    pcall(EncounterJournal_OpenJournal, 8, instanceID)
    if not wasShown and EncounterJournal and EncounterJournal:IsShown() then
        HideUIPanel(EncounterJournal)
    end

    local byIndex    = {}
    local byEncounterID = {}
    EJ_SelectInstance(instanceID)
    for i = 1, 20 do
        local name, _, _, _, _, _, dungeonEncounterID = EJ_GetEncounterInfoByIndex(i, instanceID)
        if name then
            byIndex[#byIndex + 1] = name
            if dungeonEncounterID then
                byEncounterID[dungeonEncounterID] = name
            end
        end
    end

    if #byIndex == 0 then return nil, nil end
    return byIndex, byEncounterID
end

-- Refresh EJ names and store them on TMT. Retries up to `retries` times
-- with a 2-second delay if the EJ isn't ready yet.
function TMT:RefreshEJNames(retries)
    retries = retries or 5
    local byIndex, byEncounterID = self:FetchEJBossNames()
    if byIndex then
        self._ejByIndex      = byIndex
        self._ejByEncounterID = byEncounterID
    elseif retries > 0 then
        C_Timer.After(2, function() TMT:RefreshEJNames(retries - 1) end)
    end
end

-- Resolve a display name for one boss.
--   description        raw criteriaString from C_ScenarioInfo
--   index              1-based position among non-forces criteria
--   dungeonEncounterID from criteriaType==165 + assetID (may be nil)
function TMT:FindBossName(description, index, dungeonEncounterID)
    -- 1. Exact match by dungeonEncounterID
    if dungeonEncounterID and self._ejByEncounterID and self._ejByEncounterID[dungeonEncounterID] then
        local name = self._ejByEncounterID[dungeonEncounterID]
        return self:Utf8Sub(name, 1, self.BOSS_NAME_MAX)
    end
    -- 2. Match by ordered position in the EJ list
    if self._ejByIndex and self._ejByIndex[index] then
        local name = self._ejByIndex[index]
        return self:Utf8Sub(name, 1, self.BOSS_NAME_MAX)
    end
    -- 3. Fallback: strip common noise words from the raw description
    local filtered = description:gsub("Defeated", ""):gsub("defeated", ""):match("^%s*(.-)%s*$")
    return self:Utf8Sub(filtered ~= "" and filtered or description, 1, self.BOSS_NAME_MAX)
end

-- ═══════════════════════════════════════════════════════════════════════
--  BUILD FRAME
--  Every element is created unanchored vertically: LayoutFrame walks a
--  running offset from the top and places them. That keeps the "which
--  rows are visible" question in one function instead of a chain of
--  re-anchoring branches spread over the update path.
-- ═══════════════════════════════════════════════════════════════════════
function TMT:BuildFrame()
    if self.Frame then return end
    local db = GetDB()
    if not db then return end

    local C = self:BuildPalette()
    local W = self.W
    local F = CreateFrame("Frame", "TomoMod_MythicTrackerFrame", UIParent)
    self.Frame = F

    F:SetSize(W, 300)
    F:SetFrameStrata("MEDIUM")
    F:SetFrameLevel(50)
    F:SetClampedToScreen(true)
    F:Hide()

    -- ── PANEL CHROME ──────────────────────────────────────────────────
    F._bg = self:MakeBG(F, unpack(C.BG))

    F._accent = F:CreateTexture(nil, "ARTWORK")
    F._accent:SetWidth(3)
    F._accent:SetPoint("TOPLEFT",    F, "TOPLEFT",    0, 0)
    F._accent:SetPoint("BOTTOMLEFT", F, "BOTTOMLEFT", 0, 0)
    F._accent:SetColorTexture(unpack(C.ACCENT))

    F._bdrFrame = self:MakeBorder(F, unpack(C.BORDER))
    F._bdrFrame:SetFrameLevel(F:GetFrameLevel() + 8)

    -- Drag
    F:SetScript("OnDragStart", function(s) s:StartMoving() end)
    F:SetScript("OnDragStop",  function(s)
        s:StopMovingOrSizing()
        -- [DRAG] screen-absolute coords instead of GetPoint
        local left, bottom = s:GetLeft(), s:GetBottom()
        if left and bottom then
            local scale = s:GetEffectiveScale() / UIParent:GetEffectiveScale()
            local x = math.floor(left * scale * 10 + 0.5) / 10
            local y = math.floor(bottom * scale * 10 + 0.5) / 10
            self:SetPos("BOTTOMLEFT", "BOTTOMLEFT", x, y)
        end
    end)

    -- ── HEADER ────────────────────────────────────────────────────────
    local HDR = CreateFrame("Frame", nil, F)
    F.Hdr = HDR
    HDR:SetHeight(self.HEADER_H_SLIM)

    HDR._bg = HDR:CreateTexture(nil, "BACKGROUND")
    HDR._bg:SetAllPoints(HDR)
    HDR._bg:SetColorTexture(unpack(C.BG_HEADER))

    -- Dungeon name occupies its own line, and only when enabled: the
    -- panel preset hides it, which is what lets the header collapse to
    -- a single row.
    HDR.dungeonName = self:MakeFS(HDR, 12, "OUTLINE")
    HDR.dungeonName:SetWordWrap(false)
    HDR.dungeonName:SetNonSpaceWrap(false)
    HDR.dungeonName:SetTextColor(unpack(C.TEXT_WHITE))

    HDR.keyLevel = self:MakeFS(HDR, 14, "OUTLINE")
    HDR.keyLevel:SetTextColor(unpack(C.TEXT_BRAND))

    HDR.deaths = self:MakeFS(HDR, 10, "OUTLINE")
    HDR.deaths:SetTextColor(unpack(C.TEXT_SKULL))

    -- Boss progress, shown only when the boss list itself is hidden:
    -- without it the minimal layout would drop that information entirely.
    HDR.progress = self:MakeFS(HDR, 10, "OUTLINE")
    HDR.progress:SetTextColor(unpack(C.TEXT_WHITE))
    HDR.progress:Hide()

    -- ── DEATH TOOLTIP BUTTON ──────────────────────────────────────────
    HDR.deathBtn = CreateFrame("Button", nil, HDR)
    HDR.deathBtn:SetSize(110, 16)
    HDR.deathBtn:EnableMouse(true)
    HDR.deathBtn:SetScript("OnEnter", function(btn)
        local deaths, timeLost = C_ChallengeMode.GetDeathCount()
        if not deaths or deaths == 0 then return end
        GameTooltip:SetOwner(btn, "ANCHOR_CURSOR")
        GameTooltip:AddLine(L["tmt_deaths"], 1, 0.35, 0.30)
        GameTooltip:AddLine(string.format(L["tmt_time_lost"], TMT:FormatTime(timeLost or 0)), 0.7, 0.7, 0.7)
        local playerDeaths = TMT.playerDeaths or {}
        local sorted = {}
        for name, count in pairs(playerDeaths) do
            table.insert(sorted, {name, count})
        end
        table.sort(sorted, function(a, b)
            if a[2] == b[2] then return a[1] < b[1] end
            return a[2] > b[2]
        end)
        for _, v in ipairs(sorted) do
            GameTooltip:AddLine(string.format("%s  %d", v[1], v[2]), 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    HDR.deathBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    HDR.affixes = {}
    for i = 1, 4 do
        local ic = HDR:CreateTexture(nil, "OVERLAY")
        ic:SetSize(13, 13)
        ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        HDR.affixes[i] = ic
        ic:Hide()
    end

    F._sep1 = F:CreateTexture(nil, "ARTWORK")
    F._sep1:SetHeight(1)
    F._sep1:SetColorTexture(unpack(C.ACCENT))

    -- ── TIMER LINE (elapsed / limit / delta) ──────────────────────────
    -- The segmented bar below cannot carry this text: once it is cut
    -- into three paliers there is no full-width run left to put it on.
    local TL = CreateFrame("Frame", nil, F)
    F.TimerLine = TL
    TL:SetHeight(self.TIMER_LINE_H)

    TL.elapsed = self:MakeFS(TL, 19, "OUTLINE")
    TL.elapsed:SetPoint("BOTTOMLEFT", TL, "BOTTOMLEFT", self.PAD, 4)
    TL.elapsed:SetTextColor(unpack(C.TEXT_WHITE))

    TL.limit = self:MakeFS(TL, 10, "OUTLINE")
    TL.limit:SetPoint("BOTTOMLEFT", TL.elapsed, "BOTTOMRIGHT", 5, 2)
    TL.limit:SetTextColor(unpack(C.TEXT_GREY))

    TL.delta = self:MakeFS(TL, 11, "OUTLINE")
    TL.delta:SetPoint("BOTTOMRIGHT", TL, "BOTTOMRIGHT", -self.PAD, 5)

    -- ── SEGMENTED TIMER BAR ───────────────────────────────────────────
    -- One segment per chest palier. Segment widths come from the live
    -- chest times, never from hardcoded 60/20/20 fractions, so an affix
    -- that shifts the paliers reshapes the bar on its own.
    local SR = CreateFrame("Frame", nil, F)
    F.SegRow = SR
    SR:SetHeight(self.SEG_H)

    -- The inline timer layout draws the elapsed time over the first
    -- segment rather than on a row of its own.
    SR.elapsed = self:MakeFS(SR, 10, "OUTLINE")
    SR.elapsed:SetPoint("LEFT", SR, "LEFT", self.PAD + 5, 0)
    SR.elapsed:Hide()

    F.TimerSegs = {}
    for i = 1, 3 do
        local seg = CreateFrame("StatusBar", nil, SR)
        seg:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
        seg:SetMinMaxValues(0, 1)
        seg:SetValue(0)
        seg:SetHeight(self.SEG_H)

        seg._bg = seg:CreateTexture(nil, "BACKGROUND")
        seg._bg:SetAllPoints(seg)
        seg._bg:SetColorTexture(unpack(C.BAR_TRACK))

        -- Palier marker ("+3"), shown only on the segment being spent so
        -- the two narrow segments keep room for their countdown.
        seg.tag = self:MakeFS(seg, 10, "OUTLINE")
        seg.tag:SetPoint("LEFT", seg, "LEFT", 4, 0)
        seg.tag:SetTextColor(unpack(C.ON_FILL))

        seg.label = self:MakeFS(seg, 10, "OUTLINE")
        seg.label:SetPoint("RIGHT", seg, "RIGHT", -4, 0)
        seg.label:SetTextColor(unpack(C.TEXT_GREY))

        F.TimerSegs[i] = seg
    end

    -- ── FORCES BAR ────────────────────────────────────────────────────
    local FB = CreateFrame("StatusBar", nil, F)
    F.ForcesBar = FB
    FB:SetHeight(self.BAR_H)
    FB:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    FB:SetMinMaxValues(0, 1)
    FB:SetValue(0)

    FB._bg = FB:CreateTexture(nil, "BACKGROUND")
    FB._bg:SetAllPoints(FB)
    FB._bg:SetColorTexture(unpack(C.BAR_TRACK))

    FB.label = self:MakeFS(FB, 10, "OUTLINE")
    FB.label:SetPoint("LEFT", FB, "LEFT", 4, 0)
    FB.label:SetText(L["tmt_forces"])
    FB.label:SetTextColor(unpack(C.ON_FILL))

    FB.pct = self:MakeFS(FB, 11, "OUTLINE")
    FB.pct:SetPoint("CENTER", FB, "CENTER", 0, 0)
    FB.pct:SetTextColor(unpack(C.TEXT_WHITE))

    -- Remaining count reads better than "730 / 1000": the number that
    -- matters mid-pull is how much is left to kill.
    FB.count = self:MakeFS(FB, 10, "OUTLINE")
    FB.count:SetPoint("RIGHT", FB, "RIGHT", -4, 0)
    FB.count:SetTextColor(unpack(C.TEXT_GREY))

    -- ── FORCES COMPLETION ROW ─────────────────────────────────────────
    local FCR = CreateFrame("Frame", nil, F)
    F.ForcesCompRow = FCR
    FCR:SetHeight(13)

    FCR.time = self:MakeFS(FCR, 10, "OUTLINE")
    FCR.time:SetPoint("LEFT", FCR, "LEFT", self.PAD, 0)
    FCR.time:SetTextColor(unpack(C.TEXT_BRAND))
    FCR:Hide()

    -- ── SEPARATOR BEFORE BOSSES ───────────────────────────────────────
    F._sep3 = F:CreateTexture(nil, "ARTWORK")
    F._sep3:SetHeight(1)
    F._sep3:SetColorTexture(unpack(C.SEP))

    -- ── BOSS ROWS (up to 8) ──────────────────────────────────────────
    F.BossRows = {}
    for i = 1, 8 do
        local row = CreateFrame("Frame", nil, F)
        row:SetHeight(self.BOSS_H)

        row._bg = row:CreateTexture(nil, "BACKGROUND")
        row._bg:SetAllPoints(row)
        row._bg:SetColorTexture(0, 0, 0, 0)

        row.dot = row:CreateTexture(nil, "ARTWORK")
        row.dot:SetSize(6, 6)
        row.dot:SetPoint("LEFT", row, "LEFT", self.PAD, 0)
        row.dot:SetColorTexture(0.30, 0.30, 0.30, 1)

        row.name = self:MakeFS(row, 10, "OUTLINE")
        row.name:SetMaxLines(1)
        row.name:SetWordWrap(false)
        row.name:SetTextColor(unpack(C.TEXT_GREY))

        row.split = self:MakeFS(row, 9, "OUTLINE")
        row.split:SetPoint("RIGHT", row, "RIGHT", -52, 0)
        row.split:SetTextColor(unpack(C.TEXT_GREY))

        row.time = self:MakeFS(row, 10, "OUTLINE")
        row.time:SetPoint("RIGHT", row, "RIGHT", -self.PAD, 0)
        row.time:SetTextColor(unpack(C.TEXT_GREY))

        row:Hide()
        F.BossRows[i] = row
    end

    -- ── COMPLETION BANNER ─────────────────────────────────────────────
    local BNR = CreateFrame("Frame", nil, F)
    F.Banner = BNR
    BNR:SetHeight(22)

    BNR._bg = BNR:CreateTexture(nil, "BACKGROUND")
    BNR._bg:SetAllPoints(BNR)
    BNR._bg:SetColorTexture(0, 0.20, 0.10, 0.92)

    BNR.text = self:MakeFS(BNR, 12, "OUTLINE")
    BNR.text:SetPoint("CENTER", BNR, "CENTER", 0, 0)
    BNR.text:SetTextColor(unpack(C.TEXT_BRAND))
    BNR:Hide()

    self:ApplyStyle()
    self:SetMovable(not (db and db.locked))
end

-- ═══════════════════════════════════════════════════════════════════════
--  APPLY STYLE — everything the style toggles control, in one place.
--  Safe to call at any time; the caller follows with LayoutFrame.
-- ═══════════════════════════════════════════════════════════════════════
function TMT:ApplyStyle()
    local F  = self.Frame
    local db = GetDB()
    if not F or not db then return end

    local C = self:BuildPalette()

    -- Chrome
    local chrome = db.showBackground ~= false
    F._bg:SetColorTexture(unpack(C.BG))
    F._bg:SetShown(chrome)
    F._accent:SetColorTexture(unpack(C.ACCENT))
    F._accent:SetShown(chrome)
    if F._bdrFrame then
        F._bdrFrame:SetShown(chrome)
        F._bdrFrame:SetBackdropBorderColor(unpack(C.BORDER))
    end

    -- Header block fill and separator only exist in the panel look.
    local headerBlock = db.showHeaderBlock ~= false
    F.Hdr._bg:SetColorTexture(unpack(C.BG_HEADER))
    F.Hdr._bg:SetShown(headerBlock)
    F._sep1:SetColorTexture(unpack(C.ACCENT))
    F._sep1:SetShown(headerBlock)
    F._sep3:SetColorTexture(unpack(C.SEP))
    -- LayoutFrame owns sep3's visibility: it also depends on whether any
    -- boss row is showing, which is not known here.
    F._chromeSeps = headerBlock

    F.Hdr:SetHeight(db.showDungeonName and self.HEADER_H_FULL or self.HEADER_H_SLIM)

    -- Bar tracks
    for i = 1, 3 do
        F.TimerSegs[i]._bg:SetColorTexture(unpack(C.BAR_TRACK))
    end
    F.ForcesBar._bg:SetColorTexture(unpack(C.BAR_TRACK))
    F.ForcesBar.label:SetTextColor(unpack(C.ON_FILL))

    -- Objectives: pastilles and alternating row fill belong to the panel
    -- look; the HUD lists them as plain text.
    local rows = (db.objectiveStyle == "rows")
    for _, row in ipairs(F.BossRows) do
        row.dot:SetShown(rows)
        row.name:ClearAllPoints()
        row.name:SetPoint("LEFT", row, "LEFT", rows and (self.PAD + 11) or self.PAD, 0)
    end

    F.Hdr.progress:ClearAllPoints()
    F.Hdr.progress:SetPoint("RIGHT", F.Hdr.keyLevel, "LEFT", -8, 0)

    self:ApplyFonts()
end

-- ═══════════════════════════════════════════════════════════════════════
--  SHOW / HIDE
-- ═══════════════════════════════════════════════════════════════════════
function TMT:ShowFrame()
    local db = GetDB()
    if self.Frame then
        self.Frame:SetAlpha(db and db.alpha or 0.95)
        self.Frame:Show()
    end
end

function TMT:HideFrame()
    if self.Frame then self.Frame:Hide() end
end

-- ═══════════════════════════════════════════════════════════════════════
--  MOVABLE / POSITION
-- ═══════════════════════════════════════════════════════════════════════
function TMT:SetMovable(enable)
    if not self.Frame then return end
    local db = GetDB()
    if db then db.locked = not enable end
    local F = self.Frame
    F:SetMovable(enable)
    F:EnableMouse(enable)
    if enable then
        F:RegisterForDrag("LeftButton")
        if F._bdrFrame then
            F._bdrFrame:SetBackdropBorderColor(0.9, 0.75, 0.1, 1)
        end
    else
        if F._bdrFrame then
            local c = self.C.BORDER
            F._bdrFrame:SetBackdropBorderColor(unpack(c))
        end
    end
end

function TMT:SetPos(anchor, relTo, x, y)
    local db = GetDB()
    if not db then return end
    db.position.anchor = anchor
    db.position.relTo  = relTo
    db.position.x      = x
    db.position.y      = y
end

function TMT:ResetPosition()
    local def = TomoMod_Defaults.MythicTracker.position
    self:SetPos(def.anchor, def.relTo, def.x, def.y)
    if self.Frame then
        self.Frame:ClearAllPoints()
        self.Frame:SetPoint(def.anchor, UIParent, def.relTo, def.x, def.y)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  UPDATE — HEADER
--  Two shapes. "full" keeps the dungeon name on its own line with the
--  affixes and death count below it. "slim" drops the name and folds
--  everything onto one row: deaths | affixes | key level.
-- ═══════════════════════════════════════════════════════════════════════
function TMT:AnchorHeader()
    local HDR = self.Frame.Hdr
    local db  = GetDB()
    local showName = db and db.showDungeonName and true or false
    local mode = showName and "full" or "slim"
    if HDR._mode == mode then return end
    HDR._mode = mode

    HDR.dungeonName:ClearAllPoints()
    HDR.keyLevel:ClearAllPoints()
    HDR.deaths:ClearAllPoints()
    HDR.deathBtn:ClearAllPoints()

    if showName then
        HDR.dungeonName:SetPoint("TOPLEFT", HDR, "TOPLEFT", self.PAD, -4)
        HDR.dungeonName:SetWidth(self.W - self.PAD * 2 - 46)
        HDR.dungeonName:SetJustifyH("LEFT")
        HDR.dungeonName:Show()
        HDR.keyLevel:SetPoint("TOPRIGHT", HDR, "TOPRIGHT", -self.PAD, -3)
        HDR.deaths:SetPoint("BOTTOMRIGHT", HDR, "BOTTOMRIGHT", -self.PAD, 4)
        HDR.deathBtn:SetPoint("BOTTOMRIGHT", HDR, "BOTTOMRIGHT", -4, 2)
    else
        HDR.dungeonName:Hide()
        HDR.deaths:SetPoint("LEFT", HDR, "LEFT", self.PAD, 0)
        HDR.keyLevel:SetPoint("RIGHT", HDR, "RIGHT", -self.PAD, 0)
        HDR.deathBtn:SetPoint("LEFT", HDR, "LEFT", 4, 0)
    end
end

function TMT:UpdateHeader(preview)
    local HDR = self.Frame.Hdr
    local C   = self.C
    local db  = GetDB()

    self:AnchorHeader()

    if db and db.showDungeonName then
        local name = L["tmt_dungeon_unknown"]
        if preview then
            name = "Priory of the Sacred Flame"
        elseif self.mapID and self.mapID > 0 then
            local n = C_ChallengeMode.GetMapUIInfo(self.mapID)
            if n then name = n end
        end
        HDR.dungeonName:SetText(name)
    end

    local lvl = preview and 20 or (self.level or 0)
    HDR.keyLevel:SetText(lvl > 0 and string.format(L["tmt_key_level"], lvl) or "")

    local deaths, timeLost = 0, 0
    if preview then
        deaths, timeLost = 3, 15
    else
        deaths, timeLost = C_ChallengeMode.GetDeathCount()
        deaths   = deaths   or 0
        timeLost = timeLost or 0
    end

    if deaths > 0 then
        local skullIcon = "|TInterface\\Icons\\spell_shadow_soulleech_3:11:11:0:-1|t"
        HDR.deaths:SetText(skullIcon
            .. " |cFF" .. C.HEX_RED .. tostring(deaths) .. "|r"
            .. " |cFF" .. C.HEX_GREY .. "(+" .. self:FormatTime(timeLost) .. ")|r")
    else
        HDR.deaths:SetText("")
    end

    if db and db.objectiveStyle == "none" and self._bossTotal and self._bossTotal > 0 then
        HDR.progress:SetText(string.format("%d/%d", self._bossDone or 0, self._bossTotal))
        HDR.progress:Show()
    else
        HDR.progress:Hide()
    end

    local affixes = preview and {9, 12, 134, 11} or (self.affixes or {})

    -- Count first so the slim header can centre the row.
    local shown = {}
    for i = 1, 4 do
        if affixes[i] then
            local _, _, icon = C_ChallengeMode.GetAffixInfo(affixes[i])
            if icon then shown[#shown + 1] = { slot = i, icon = icon } end
        end
    end

    for i = 1, 4 do HDR.affixes[i]:ClearAllPoints(); HDR.affixes[i]:Hide() end

    local n = #shown
    local prev = nil
    for i = 1, n do
        local ic = HDR.affixes[i]
        ic:SetTexture(shown[i].icon)
        if prev then
            ic:SetPoint("LEFT", prev, "RIGHT", 3, 0)
        elseif HDR._mode == "full" then
            ic:SetPoint("BOTTOMLEFT", HDR, "BOTTOMLEFT", self.PAD, 4)
        else
            -- Centre the strip: n icons of 13px with 3px gaps.
            local total = n * 13 + (n - 1) * 3
            ic:SetPoint("LEFT", HDR, "CENTER", -total / 2, 0)
        end
        ic:Show()
        prev = ic
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  UPDATE — TIMER LINE + SEGMENTED BAR
--  One segment per chest palier, sized from the live chest times. Each
--  segment shows the time left before that palier is lost, which is the
--  number that actually drives decisions in a key.
-- ═══════════════════════════════════════════════════════════════════════
-- Paint one segment's fill.
--
-- The gradient is written onto the status bar texture. SetStatusBarColor
-- writes the same vertex colours, so the two cannot both drive one bar --
-- hence the fallback path rather than a belt-and-braces call to both.
-- ══════════════════════════════════════════════════════════════════════
--  SPLITS & CHECKPOINTS
--
--  Both features read from one store: your own best run per dungeon and
--  key level. Nothing here is authored. A curated table of "expected
--  forces at boss 2" would be the same rotting data as the old EJ map --
--  wrong the day a dungeon is retuned -- and it would also be somebody
--  else's route rather than yours.
--
--  Schema, per entry:
--    total      run time in milliseconds
--    level      key level the run was recorded at
--    recordedAt epoch seconds
--    bosses[i]  { time = seconds, forces = percent at that kill }
--    forcesDone seconds at which the forces count completed
-- ══════════════════════════════════════════════════════════════════════
function TMT:SplitStore()
    local db = GetDB()
    if not db then return nil end
    if type(db.splits) ~= "table" then db.splits = {} end
    return db.splits
end

-- Best run for this dungeon. An exact key-level match wins; failing that
-- the nearest level below (a slower reference is still a reference), then
-- the nearest above. Returns the entry and the level it came from, so the
-- caller can say where the comparison is coming from.
function TMT:GetBestRun(mapID, level)
    local store = self:SplitStore()
    local byLevel = store and mapID and store[mapID]
    if not byLevel or not level then return nil end
    if byLevel[level] then return byLevel[level], level end

    local lower, lowerLvl, higher, higherLvl
    for lvl, run in pairs(byLevel) do
        if type(lvl) == "number" then
            if lvl < level then
                if not lowerLvl or lvl > lowerLvl then lower, lowerLvl = run, lvl end
            elseif not higherLvl or lvl < higherLvl then
                higher, higherLvl = run, lvl
            end
        end
    end
    if lower  then return lower,  lowerLvl  end
    if higher then return higher, higherLvl end
    return nil
end

-- Store the run that just finished, if it beats what is on record. A
-- depleted run still counts: it may be the only data for that dungeon,
-- and a slow reference beats no reference.
function TMT:RecordRun()
    local db = GetDB()
    if not db or db.splitsEnabled == false then return false end

    local mapID, level, ms = self.mapID, self.level, self.completionTime
    if not mapID or not level or not ms or ms <= 0 then return false end

    local store = self:SplitStore()
    if not store then return false end
    store[mapID] = store[mapID] or {}

    local prev = store[mapID][level]
    if prev and prev.total and prev.total <= ms then return false end

    local bosses = {}
    for i, t in pairs(self.bossKillTimes or {}) do
        bosses[i] = { time = t, forces = (self.bossForces or {})[i] }
    end

    store[mapID][level] = {
        total      = ms,
        level      = level,
        recordedAt = time(),
        bosses     = bosses,
        forcesDone = self.forcesCompTime,
    }
    return true
end

function TMT:ClearSplits()
    local db = GetDB()
    if db then db.splits = {} end
end

-- The forces percentage the best run had reached by the boss you have
-- just killed. Between kills the reference holds, which is what makes it
-- readable at a glance instead of jittering every tick.
function TMT:CurrentCheckpoint()
    local db = GetDB()
    if not db or db.checkpointsEnabled == false then return nil end
    local done = self._bossDone
    if not done or done < 1 then return nil end
    local best = self:GetBestRun(self.mapID, self.level)
    local entry = best and best.bosses and best.bosses[done]
    return entry and entry.forces or nil
end

function TMT:PaintSegment(seg, index, state)
    local C  = self.C
    local db = GetDB()

    local ramp = C.SEG_RAMP_BRAND
    if not db or db.segmentColors ~= "brand" then
        ramp = C.SEG_RAMP[index] or C.SEG_RAMP_BRAND
    end

    -- A spent palier is history: it keeps its own colour so the bar still
    -- reads left to right, but dimmed, so the eye lands on the window
    -- actually being spent.
    local alpha = 0.90
    if state == "spent" then alpha = 0.42
    elseif state == "overtime" then alpha = 0.95 end

    local lo, hi = ramp[1], ramp[2]
    local tex = seg.GetStatusBarTexture and seg:GetStatusBarTexture()
    local ok = false
    if tex and tex.SetGradient and CreateColor then
        ok = pcall(tex.SetGradient, tex, "HORIZONTAL",
            CreateColor(lo[1], lo[2], lo[3], alpha),
            CreateColor(hi[1], hi[2], hi[3], alpha))
    end
    if not ok then
        -- No gradient support: the ramp's bright stop keeps the palier
        -- readable, only the shading is lost.
        seg:SetStatusBarColor(hi[1], hi[2], hi[3], alpha)
    end
end

function TMT:UpdateTimerBar(preview)
    local F  = self.Frame
    local TL = F.TimerLine
    local SR = F.SegRow
    local db = GetDB()
    if not db or not db.showTimer then
        TL:Hide(); SR:Hide()
        return
    end
    SR:Show()

    -- "inline" folds the elapsed time onto the segment row and drops the
    -- time limit and the delta: the last segment's countdown already is
    -- the time left before depletion, so both would be restating it.
    local inline = (db.timerLayout == "inline")
    TL:SetShown(not inline)
    SR.elapsed:SetShown(inline)

    local C         = self.C
    local elapsed   = 0
    local timeLimit = self.timeLimit or 1800

    if preview then
        elapsed, timeLimit = 754, 1800
    elseif self.completionTime then
        elapsed = self.completionTime / 1000
    elseif C_ChallengeMode.IsChallengeModeActive() then
        elapsed = select(2, GetWorldElapsedTime(1)) or 0
    end
    if timeLimit <= 0 then timeLimit = 1800 end

    -- Chest times, with a defensive fallback if the map info has not
    -- arrived yet. Index 1 is the full limit, 3 the +3 threshold.
    local ct  = self.chestTimes or {}
    local ct1 = ct[1] or timeLimit
    local ct2 = ct[2] or math.floor(timeLimit * 0.80)
    local ct3 = ct[3] or math.floor(timeLimit * 0.60)
    if ct1 <= 0 then ct1 = timeLimit end
    if ct2 <= 0 or ct2 >= ct1 then ct2 = math.floor(ct1 * 0.80) end
    if ct3 <= 0 or ct3 >= ct2 then ct3 = math.floor(ct1 * 0.60) end

    local limits = { ct1, ct2, ct3 }
    local spans  = { ct1 - ct2, ct2 - ct3, ct3 }

    -- ── Segment geometry ──────────────────────────────────────────────
    local usable = self.W - self.PAD * 2 - self.SEG_GAP * 2
    local w3 = math.floor(usable * spans[3] / ct1 + 0.5)
    local w2 = math.floor(usable * spans[2] / ct1 + 0.5)
    local w1 = usable - w3 - w2
    if w1 < 10 then w1 = 10 end
    if w2 < 10 then w2 = 10 end
    local widths = { w1, w2, w3 }

    local x3 = self.PAD
    local x2 = x3 + w3 + self.SEG_GAP
    local x1 = x2 + w2 + self.SEG_GAP
    local xs = { x1, x2, x3 }

    local overtime = elapsed > ct1

    for i = 1, 3 do
        local seg = F.TimerSegs[i]
        seg:ClearAllPoints()
        seg:SetPoint("LEFT", SR, "LEFT", xs[i], 0)
        seg:SetWidth(widths[i])

        local barMax    = spans[i]
        local remaining = limits[i] - elapsed
        local value     = 0
        if barMax > 0 then
            value = (barMax - remaining) / barMax
            if value < 0 then value = 0 elseif value > 1 then value = 1 end
        end
        seg:SetValue(value)

        local active = (value > 0 and value < 1)
        if i == 1 and overtime then
            seg:SetValue(1)
            self:PaintSegment(seg, i, "overtime")
        elseif value >= 1 then
            self:PaintSegment(seg, i, "spent")
        else
            self:PaintSegment(seg, i, "active")
        end

        -- Countdown text
        if i == 1 and overtime then
            seg.label:SetText("-" .. self:FormatTime(-remaining))
            seg.label:SetTextColor(unpack(C.ON_FILL))
        elseif remaining > 0 then
            seg.label:SetText(self:FormatTime(remaining))
            if active then
                seg.label:SetTextColor(unpack(C.TEXT_WHITE))
            else
                seg.label:SetTextColor(unpack(C.TEXT_GREY))
            end
        else
            seg.label:SetText("")
        end

        -- The palier marker rides the segment currently being spent. It
        -- yields its spot to the elapsed time in the inline layout.
        if active and not inline then
            seg.tag:SetText("+" .. i)
            seg.tag:SetTextColor(unpack(C.ON_FILL))
        else
            seg.tag:SetText("")
        end
    end

    -- ── Elapsed time ──────────────────────────────────────────────────
    if inline then
        SR.elapsed:SetText(self:FormatTime(elapsed))
        -- The text sits at the left edge of the first segment, which is
        -- bare track early in a key and filled later. Dark on dark is
        -- unreadable, so the colour follows what is actually behind it.
        if overtime then
            SR.elapsed:SetTextColor(unpack(C.TEXT_RED))
        elseif F.TimerSegs[3]:GetValue() > 0.12 then
            SR.elapsed:SetTextColor(unpack(C.ON_FILL))
        else
            SR.elapsed:SetTextColor(unpack(C.TEXT_WHITE))
        end
        return
    end

    TL.elapsed:SetText(self:FormatTime(elapsed))
    TL.elapsed:SetTextColor(unpack(overtime and C.TEXT_RED or C.TEXT_WHITE))
    TL.limit:SetText("/ " .. self:FormatTime(ct1))

    local diff = ct1 - elapsed
    if diff < 0 then
        TL.delta:SetText("|cFF" .. C.HEX_RED .. self:FormatDelta(diff) .. "|r")
    elseif diff <= ct1 * 0.20 then
        TL.delta:SetText(self:FormatDelta(diff))
        TL.delta:SetTextColor(unpack(C.TEXT_YELLOW))
    else
        TL.delta:SetText(self:FormatDelta(diff))
        TL.delta:SetTextColor(unpack(C.TEXT_BRAND))
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  UPDATE — FORCES BAR
-- ═══════════════════════════════════════════════════════════════════════
function TMT:UpdateForcesBar(preview)
    local FB  = self.Frame.ForcesBar
    local FCR = self.Frame.ForcesCompRow
    local db  = GetDB()
    if not db or not db.showForces then
        FB:Hide(); FCR:Hide()
        return
    end
    FB:Show()

    local C = self.C

    -- [SECRET VALUES] Scenario criteria fields are not guaranteed readable
    -- in combat in 12.x. Every field passes a guard before it is compared,
    -- matched or used in arithmetic, and the bar degrades in stages rather
    -- than lying: exact counts, then percentage only, then frozen.
    local qty, total, pct

    if preview then
        qty, total = 730, 1000
    else
        local steps = SafeNum(select(3, C_Scenario.GetStepInfo()))
        if steps and steps > 0 then
            for i = 1, steps do
                local cr = C_ScenarioInfo.GetCriteriaInfo(i)
                -- Presence, not magnitude: asking "is totalQuantity > 0"
                -- on an opaque value is exactly the banned comparison.
                if cr and SafeBool(cr.isWeightedProgress) and cr.totalQuantity ~= nil then
                    total = SafeNum(cr.totalQuantity)

                    -- For weighted progress the client puts the absolute
                    -- count in quantityString -- carrying a stray percent
                    -- sign despite being an absolute value -- while
                    -- quantity holds the percentage. Hence the string
                    -- first, the number as the fallback.
                    local qs = SafeStr(cr.quantityString)
                    if qs then qty = tonumber(qs:match("%d+")) end
                    if not qty then pct = SafeNum(cr.quantity) end
                    break
                end
            end
        end
    end

    if qty and total and total > 0 then
        pct = qty / total * 100
    end
    -- Published for UpdateBossRows, which snapshots it at each kill.
    self._forcesPct = pct

    -- Nothing readable this frame: hold the last known fill instead of
    -- dropping the bar to zero, which would read as "the pull reset".
    local ratio
    if pct then
        ratio = math.min(pct / 100, 1)
        self._lastForcesRatio = ratio
    else
        ratio = self._lastForcesRatio
    end
    FB:SetValue(ratio or 0)

    if pct and pct >= 100 then
        FB:SetStatusBarColor(unpack(C.FORCES_DONE))
        FB.pct:SetText(L["tmt_forces_done"])
        FB.pct:SetTextColor(unpack(C.ON_FILL))
        FB.label:Hide()
        FB.count:Hide()

        -- Show forces completion time
        local elapsed = 0
        if preview then
            elapsed = 620
        elseif C_ChallengeMode.IsChallengeModeActive() then
            elapsed = select(2, GetWorldElapsedTime(1)) or 0
        end
        if not self.forcesCompTime then
            self.forcesCompTime = elapsed
        end
        local line = "|cFF" .. C.HEX_BRAND .. L["tmt_forces"] .. "|r  " .. self:FormatTime(self.forcesCompTime)
        local best = (db.splitsEnabled ~= false)
            and self:GetBestRun(self.mapID, self.level) or nil
        if best and best.forcesDone then
            local delta = self.forcesCompTime - best.forcesDone
            local hex = (delta <= 0) and C.HEX_BRAND or C.HEX_RED
            line = line .. "  |cFF" .. hex .. self:FormatDelta(delta) .. "|r"
        end
        FCR.time:SetText(line)
        FCR:Show()
    else
        -- Brand ramp: dark mint at the pull, full mint as the count fills.
        -- With no readable numbers the ramp sits at its low end; the bar
        -- fill is still correct because it came from the raw values.
        local r, g, b = Mix(C.FORCES_LOW, C.FORCES_HIGH, ratio or 0)
        FB:SetStatusBarColor(r, g, b, 0.85)
        if pct then
            local text = string.format(L["tmt_forces_pct"], pct)
            -- Checkpoint: where the best run stood at the boss you have
            -- just killed. Up means ahead of that pace.
            local ref = self:CurrentCheckpoint()
            if ref then
                local delta = pct - ref
                local arrow = (delta >= 0) and "\226\150\178" or "\226\150\188"
                local hex   = (delta >= 0) and C.HEX_BRAND or C.HEX_RED
                text = text .. "  |cFF" .. hex .. arrow
                    .. string.format("%.1f", math.abs(delta)) .. "|r"
            end
            FB.pct:SetText(text)
        else
            FB.pct:SetText("")
        end
        FB.pct:SetTextColor(unpack(C.TEXT_WHITE))
        FB.label:Show()
        FB.count:Show()
        FCR:Hide()
        self.forcesCompTime = nil
    end

    -- What is left to kill reads better mid-pull than "730 / 1000".
    if qty and total then
        local remaining = total - qty
        if remaining < 0 then remaining = 0 end
        FB.count:SetText(string.format(L["tmt_forces_remaining"], remaining))
    else
        FB.count:SetText("")
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  UPDATE — BOSS ROWS
-- ═══════════════════════════════════════════════════════════════════════
function TMT:UpdateBossRows(preview)
    for _, row in ipairs(self.Frame.BossRows) do row:Hide() end
    self._bossDone, self._bossTotal = nil, nil
    local db = GetDB()
    if not db or not db.showBosses then return end

    local C       = self.C
    local elapsed = 0
    local striped = (db.objectiveStyle == "rows")

    if not preview and C_ChallengeMode.IsChallengeModeActive() then
        elapsed = select(2, GetWorldElapsedTime(1)) or 0
    end

    local criteria = {}
    if preview then
        criteria = {
            -- cr.elapsed counts seconds SINCE the kill, so the boss killed
            -- first carries the larger value. Reversed, the preview showed
            -- boss 2 dying before boss 1 and a negative leg time.
            { criteriaString = "Prioress Murrpray",   completed = true,  elapsed = 560 },
            { criteriaString = "Sergeant Shaynemail", completed = true,  elapsed = 340 },
            { criteriaString = "Captain Dailcry",     completed = false, elapsed = nil },
            { criteriaString = "High Priest Aemya",   completed = false, elapsed = nil },
        }
        elapsed = 900
    else
        local steps = select(3, C_Scenario.GetStepInfo()) or 0
        for i = 1, steps do
            local cr = C_ScenarioInfo.GetCriteriaInfo(i)
            -- Explicitly false, not "falsy": if the flag is opaque we
            -- cannot tell a boss from the forces counter, and listing the
            -- forces counter as a boss is the worse failure.
            if cr and SafeBool(cr.isWeightedProgress) == false then
                table.insert(criteria, cr)
            end
        end
    end

    -- Count before rendering: the minimal layout hides the rows but still
    -- reports the tally in the header, so the count has to survive the
    -- early return below.
    local done = 0
    for _, cr in ipairs(criteria) do
        if cr.completed then done = done + 1 end
    end
    self._bossDone, self._bossTotal = done, #criteria

    if db.objectiveStyle == "none" then return end

    self.bossKillTimes = self.bossKillTimes or {}
    self.bossForces    = self.bossForces or {}

    local best = (db.splitsEnabled ~= false)
        and self:GetBestRun(self.mapID, self.level) or nil

    for i, cr in ipairs(criteria) do
        local row = self.Frame.BossRows[i]
        if not row then break end
        row:Show()

        if striped and i % 2 == 0 then
            row._bg:SetColorTexture(unpack(C.BG_ROW_ALT))
        else
            row._bg:SetColorTexture(0, 0, 0, 0)
        end

        -- Resolve boss name via EJ (localised), fall back to raw criteria description.
        -- WoW 12.x (Midnight): the field was renamed from criteriaString to description.
        -- Strip Blizzard's leading checkmark (U+2713, completed state) and dash prefix.
        local dungeonEncounterID = (cr.criteriaType == 165) and cr.assetID or nil
        local rawDesc = cr.description or cr.criteriaString or ""
        rawDesc = rawDesc:gsub("^\226\156\147%s*", ""):gsub("^%-%s*", "")
        local bossName
        if preview then
            bossName = self:Utf8Sub(cr.criteriaString or ("Boss " .. i), 1, self.BOSS_NAME_MAX)
        else
            bossName = self:FindBossName(rawDesc ~= "" and rawDesc or ("Boss " .. i), i, dungeonEncounterID)
        end
        row.name:SetText(bossName)

        if cr.completed then
            row.dot:SetColorTexture(unpack(C.ACCENT))
            row.name:SetTextColor(unpack(C.TEXT_WHITE))

            local kt = self.bossKillTimes[i]
            if not kt and cr.elapsed and elapsed > 0 then
                kt = elapsed - cr.elapsed
                self.bossKillTimes[i] = kt
                -- Snapshot the forces count at the kill: this is what a
                -- future run compares itself against.
                self.bossForces[i] = self._forcesPct
            end
            row.time:SetText(kt and self:FormatTime(kt) or "")
            row.time:SetTextColor(unpack(C.TEXT_BRAND))

            -- Against the best run when there is one, otherwise fall back
            -- to the leg time from the previous boss.
            local ref = best and best.bosses and best.bosses[i] and best.bosses[i].time
            if kt and ref then
                local delta = kt - ref
                row.split:SetText(self:FormatDelta(delta))
                row.split:SetTextColor(unpack(delta <= 0 and C.TEXT_BRAND or C.TEXT_RED))
            elseif kt and i > 1 and self.bossKillTimes[i - 1] then
                row.split:SetText(self:FormatTime(kt - self.bossKillTimes[i - 1]))
                row.split:SetTextColor(unpack(C.TEXT_GREY))
            else
                row.split:SetText("")
            end
        else
            row.dot:SetColorTexture(0.30, 0.30, 0.30, 1)
            row.name:SetTextColor(unpack(C.TEXT_GREY))
            row.time:SetText("\226\128\148")
            row.time:SetTextColor(unpack(C.TEXT_GREY))
            row.split:SetText("")
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  UPDATE — COMPLETION BANNER
-- ═══════════════════════════════════════════════════════════════════════
function TMT:UpdateBanner()
    local BNR  = self.Frame.Banner
    local C    = self.C
    local info = C_ChallengeMode.GetChallengeCompletionInfo()

    -- Guard before comparing: the completion payload arrives on an event
    -- that can fire while still in combat.
    local ms = info and SafeNum(info.time)
    if not ms or ms <= 0 then
        BNR:Hide()
        return
    end

    local sec   = ms / 1000
    local limit = (self.chestTimes and self.chestTimes[1]) or self.timeLimit
    local upgrades = SafeNum(info.keystoneUpgradeLevels) or 0

    -- The margin is the number people actually talk about after a key:
    -- how much room was left, or by how much it was missed.
    local margin = limit and (limit - sec) or nil
    local marginText = ""
    if margin then
        marginText = "  |cFF" .. C.HEX_GREY .. "(" .. self:FormatDelta(margin) .. ")|r"
    end

    if limit and sec <= limit then
        BNR._bg:SetColorTexture(C.ACCENT[1] * 0.20, C.ACCENT[2] * 0.22, C.ACCENT[3] * 0.20, 0.92)
        local upText = upgrades > 0 and ("  |cFF" .. C.HEX_BRAND .. "+" .. upgrades .. "|r") or ""
        BNR.text:SetText("|cFF" .. C.HEX_BRAND .. L["tmt_completed_on_time"] .. "|r"
            .. upText .. "  " .. self:FormatTime(sec) .. marginText)
    else
        BNR._bg:SetColorTexture(C.TEXT_RED[1] * 0.24, C.TEXT_RED[2] * 0.10, C.TEXT_RED[3] * 0.08, 0.92)
        BNR.text:SetText("|cFF" .. C.HEX_RED .. L["tmt_completed_depleted"] .. "|r  "
            .. self:FormatTime(sec) .. marginText)
    end
    BNR:Show()
end

-- ═══════════════════════════════════════════════════════════════════════
--  LAYOUT — walk a running offset from the top of the frame
--  Elements are never anchored to each other, so a hidden row costs one
--  skipped branch here instead of a re-anchoring chain everywhere else.
-- ═══════════════════════════════════════════════════════════════════════
function TMT:LayoutFrame()
    if not self.Frame then return end
    local db = GetDB()
    if not db then return end

    local F   = self.Frame
    local GAP = self.GAP
    local off = 0

    local function Place(el, h, inset)
        inset = inset or 0
        el:ClearAllPoints()
        el:SetPoint("TOPLEFT",  F, "TOPLEFT",   inset, -off)
        el:SetPoint("TOPRIGHT", F, "TOPRIGHT", -inset, -off)
        if h then off = off + h end
    end

    -- Header
    local headerH = db.showDungeonName and self.HEADER_H_FULL or self.HEADER_H_SLIM
    F.Hdr:SetHeight(headerH)
    Place(F.Hdr, headerH)

    if F._sep1:IsShown() then
        Place(F._sep1, 1)
    end
    off = off + GAP

    -- Timer line + segmented bar
    if db.showTimer then
        -- [FIX] SegRow spans the full width: UpdateTimerBar already insets
        -- the segments by PAD, so insetting the row too pushed the last
        -- segment past the right edge of the frame.
        if F.TimerLine:IsShown() then
            Place(F.TimerLine, self.TIMER_LINE_H)
        end
        Place(F.SegRow, self.SEG_H)
        off = off + GAP
    end

    -- Forces
    if db.showForces then
        Place(F.ForcesBar, self.BAR_H, self.PAD)
        if F.ForcesCompRow:IsShown() then
            off = off + 1
            Place(F.ForcesCompRow, 13)
        end
        off = off + GAP
    end

    -- Bosses
    local bossCnt = 0
    for _, row in ipairs(F.BossRows) do
        if row:IsShown() then bossCnt = bossCnt + 1 end
    end

    F._sep3:SetShown((F._chromeSeps ~= false) and bossCnt > 0)
    if F._sep3:IsShown() then
        Place(F._sep3, 1)
        off = off + GAP
    end

    if bossCnt > 0 then
        for _, row in ipairs(F.BossRows) do
            if row:IsShown() then Place(row, self.BOSS_H) end
        end
    end

    -- Completion banner
    if F.Banner:IsShown() then
        off = off + GAP
        Place(F.Banner, 22)
    end

    off = off + 4
    F:SetHeight(math.max(off, self.HEADER_H_SLIM + 20))

    if F._bdrFrame then F._bdrFrame:SetAllPoints(F) end
end

-- ═══════════════════════════════════════════════════════════════════════
--  REFRESH ALL
-- ═══════════════════════════════════════════════════════════════════════
function TMT:RefreshAll(preview)
    if not self.Frame then return end
    -- Boss rows first: they compute the tally the header displays when
    -- the list itself is hidden.
    self:UpdateBossRows(preview)
    self:UpdateHeader(preview)
    self:UpdateTimerBar(preview)
    self:UpdateForcesBar(preview)
    self:UpdateBanner()
    self:LayoutFrame()
end

-- ═══════════════════════════════════════════════════════════════════════
--  PREVIEW
-- ═══════════════════════════════════════════════════════════════════════
function TMT:Preview()
    if not self.Frame then self:BuildFrame() end
    self.mapID          = 0
    self.level          = 20
    self.affixes        = {}
    self.timeLimit      = 1800
    self.chestTimes     = { [1] = 1800, [2] = 1440, [3] = 1080 }
    self.bossKillTimes  = {}
    self.completionTime = nil
    self:RefreshAll(true)
    self:ShowFrame()
    print(L["tmt_preview_active"])
end

-- ═══════════════════════════════════════════════════════════════════════
--  BLIZZARD UI SUPPRESSION
-- ═══════════════════════════════════════════════════════════════════════

local BLIZZARD_FRAMES = {
    "ScenarioFrame",
    "ScenarioTrackerProgressBar",
    "ObjectiveTrackerFrame",
    function() return ObjectiveTrackerFrame and ObjectiveTrackerFrame.CHALLENGE_BLOCK end,
    function() return ObjectiveTrackerFrame and ObjectiveTrackerFrame.BONUS_OBJECTIVE_TRACKER_MODULE end,
    "ScenarioStageBlock",
    function() return ScenarioObjectiveTracker end,
    function()
        if ObjectiveTrackerFrame and ObjectiveTrackerFrame.CHALLENGE_BLOCK then
            return ObjectiveTrackerFrame.CHALLENGE_BLOCK
        end
    end,
}

local BLIZZARD_OT_MODULES = {
    "CHALLENGE_BLOCK",
    "SCENARIO_CONTENT_TRACKER_MODULE",
    "BONUS_OBJECTIVE_TRACKER_MODULE",
    "UI_WIDGET_SCENARIO_TRACKER_MODULE",
}

TMT._blizzHooked   = false
TMT._inChallenge   = false
TMT._killedFrames  = {}  -- list of frames we've muted, for restore on /leave

-- [TWW TAINT] The old `hooksecurefunc(frame, "Show", function(f) f:Hide() end)` pattern
-- is a classic taint propagation vector. When Blizzard's secure code calls Show() and
-- our insecure hook immediately calls Hide(), the ensuing "hidden while secure expected
-- visible" state taints subsequent secure operations — particularly nasty in M+ where
-- this module is active.
--
-- Safe replacement: SetAlpha(0) from within the hook. SetAlpha is a visual-only
-- property (not protected), so writing to it from insecure code doesn't taint the
-- secure state. The frame remains "shown" logically — Blizzard's secure code still
-- sees it in the expected state — but is visually invisible to the player.

-- Register the hook idempotently (InitBlizzardSuppress calls this at module init
-- for defensive pre-hooking; the hook body is a no-op until _inChallenge=true).
local function RegisterShowHook(frame)
    if not frame or frame._tmtHooked then return end
    frame._tmtHooked = true
    hooksecurefunc(frame, "Show", function(f)
        if TMT._inChallenge then f:SetAlpha(0) end
    end)
end

-- Actively mute the frame and record it for later restore.
local function MuteFrame(frame)
    if not frame or frame._tmtMuted then return end
    frame._tmtMuted = true
    frame._tmtOrigAlpha = frame:GetAlpha() or 1
    frame:SetAlpha(0)
    if frame.EnableMouse then frame:EnableMouse(false) end
    TMT._killedFrames[#TMT._killedFrames + 1] = frame
end

-- Combined: mute now + ensure Show hook is registered (used by SuppressBlizzardUI).
local function HookHide(frame)
    if not frame then return end
    RegisterShowHook(frame)
    MuteFrame(frame)
end

-- HookSetShown removed — SetShown(true) calls Show() internally, so the Show hook
-- above covers it. One hook is enough and reduces taint surface area.

local function SuppressOTModules()
    local OT = ObjectiveTrackerFrame
    if not OT then return end
    HookHide(OT)
    for _, modKey in ipairs(BLIZZARD_OT_MODULES) do
        local mod = OT[modKey]
        if mod then
            HookHide(mod)
            if mod.Header   then HookHide(mod.Header) end
            if mod.contents then HookHide(mod.contents) end
        end
    end
end

local function SuppressNamedFrames()
    for _, entry in ipairs(BLIZZARD_FRAMES) do
        local frame
        if type(entry) == "string" then
            frame = _G[entry]
        elseif type(entry) == "function" then
            local ok, result = pcall(entry)
            if ok then frame = result end
        end
        if frame then HookHide(frame) end
    end
end

function TMT:SuppressBlizzardUI()
    TMT._inChallenge = true
    SuppressOTModules()
    SuppressNamedFrames()
    local attempts = 0
    local function retry()
        attempts = attempts + 1
        SuppressOTModules()
        SuppressNamedFrames()
        if attempts < 5 then
            C_Timer.After(2, retry)
        end
    end
    C_Timer.After(1, retry)
end

function TMT:RestoreBlizzardUI()
    TMT._inChallenge = false
    -- Restore alpha and mouse on all frames we muted during the challenge.
    -- We don't remove the Show hooks (they're permanent for the session), but
    -- with _inChallenge=false their body is a no-op.
    for i = 1, #TMT._killedFrames do
        local f = TMT._killedFrames[i]
        if f then
            f:SetAlpha(f._tmtOrigAlpha or 1)
            if f.EnableMouse then f:EnableMouse(true) end
            f._tmtMuted = nil  -- allow re-muting on next challenge
        end
    end
    -- Clear list — next challenge will repopulate via MuteFrame.
    for i = #TMT._killedFrames, 1, -1 do
        TMT._killedFrames[i] = nil
    end
end

function TMT:InitBlizzardSuppress()
    if TMT._blizzHooked then return end
    TMT._blizzHooked = true

    -- [TAINT] Pre-register the Show hooks at module init but do NOT mute these frames
    -- yet — they should remain fully visible out of M+. The hook body is gated on
    -- _inChallenge=true, so it's a no-op until SuppressBlizzardUI is called.
    -- ObjectiveTrackerFrame and ScenarioObjectiveTracker are routinely touched by
    -- Blizzard secure code during M+, so never call Hide() from these hooks.
    if ObjectiveTrackerFrame then
        RegisterShowHook(ObjectiveTrackerFrame)
    end
    if UIWidgetBelowMinimapContainerFrame then
        RegisterShowHook(UIWidgetBelowMinimapContainerFrame)
    end
    if ScenarioObjectiveTracker then
        RegisterShowHook(ScenarioObjectiveTracker)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  EVENTS & TICKER
-- ═══════════════════════════════════════════════════════════════════════
TMT._ticker = nil

function TMT:StartTicker()
    if self._ticker then return end
    local function tick()
        TMT._ticker = nil
        if TMT.Frame and C_ChallengeMode.IsChallengeModeActive() then
            TMT:UpdateTimerBar()
            TMT:UpdateForcesBar()
            TMT:UpdateHeader()
            TMT:LayoutFrame()
            TMT._ticker = C_Timer.NewTimer(TMT.UPDATE_RATE, tick)
        end
    end
    self._ticker = C_Timer.NewTimer(self.UPDATE_RATE, tick)
end

function TMT:StopTicker()
    if self._ticker then self._ticker:Cancel(); self._ticker = nil end
end

function TMT:_LoadActiveKey()
    self.mapID  = C_ChallengeMode.GetActiveChallengeMapID()
    self.level, self.affixes = C_ChallengeMode.GetActiveKeystoneInfo()
    local _, _, tl = C_ChallengeMode.GetMapUIInfo(self.mapID or 0)
    self.timeLimit  = tl or 1800
    self.chestTimes = {
        [1] = self.timeLimit,
        [2] = math.floor(self.timeLimit * 0.80),
        [3] = math.floor(self.timeLimit * 0.60),
    }
end

local EF = CreateFrame("Frame")
EF:RegisterEvent("PLAYER_LOGIN")
EF:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        EF:UnregisterEvent("PLAYER_LOGIN")
        EF:RegisterEvent("PLAYER_ENTERING_WORLD")
        EF:RegisterEvent("CHALLENGE_MODE_START")
        EF:RegisterEvent("CHALLENGE_MODE_COMPLETED")
        EF:RegisterEvent("CHALLENGE_MODE_DEATH_COUNT_UPDATED")
        EF:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
        EF:RegisterEvent("SCENARIO_POI_UPDATE")
        return
    end
    local db = GetDB()
    if not db or not db.enabled then return end

    if event == "PLAYER_ENTERING_WORLD" then
        if not TMT.Frame then
            TMT:BuildFrame()
            TMT:InitBlizzardSuppress()
            local p = db.position
            TMT.Frame:ClearAllPoints()
            TMT.Frame:SetPoint(p.anchor, UIParent, p.relTo, p.x, p.y)
            TMT.Frame:SetScale(db.scale)
        end
        C_MythicPlus.RequestMapInfo()
        if C_ChallengeMode.IsChallengeModeActive() then
            if db.hideBlizzard then TMT:SuppressBlizzardUI() end
            TMT:_LoadActiveKey()
            TMT:RefreshEJNames()
            TMT:RefreshAll(false)
            TMT:ShowFrame()
            TMT:StartTicker()
        else
            TMT:RestoreBlizzardUI()
            TMT:HideFrame()
        end

    elseif event == "CHALLENGE_MODE_START" then
        TMT.bossKillTimes = {}
        TMT.bossForces = {}
        TMT._forcesPct = nil
        TMT.completionTime = nil
        TMT.playerDeaths = {}
        TMT.forcesCompTime = nil
        TMT._ejByIndex = nil
        TMT._ejByEncounterID = nil
        if db.hideBlizzard then TMT:SuppressBlizzardUI() end
        TMT:_LoadActiveKey()
        TMT:RefreshEJNames()
        TMT:RefreshAll(false)
        TMT:ShowFrame()
        TMT:StartTicker()

    elseif event == "CHALLENGE_MODE_COMPLETED" then
        TMT:StopTicker()
        local info = C_ChallengeMode.GetChallengeCompletionInfo()
        -- Guarded: this event can fire before combat has dropped, and the
        -- value feeds arithmetic in UpdateTimerBar.
        TMT.completionTime = info and SafeNum(info.time) or nil
        TMT:RecordRun()
        TMT:UpdateTimerBar(false)
        TMT:UpdateBossRows(false)
        TMT:UpdateBanner()
        TMT:LayoutFrame()

    elseif event == "CHALLENGE_MODE_DEATH_COUNT_UPDATED" then
        TMT:UpdateHeader()

    elseif event == "SCENARIO_CRITERIA_UPDATE"
        or event == "SCENARIO_POI_UPDATE" then
        if TMT.Frame and C_ChallengeMode.IsChallengeModeActive() then
            TMT:UpdateBossRows()
            TMT:UpdateForcesBar()
            TMT:LayoutFrame()
        end

    end
end)

-- ═══════════════════════════════════════════════════════════════════════
--  STYLE REFRESH ENTRY POINT
--  The tracker used to carry a second, self-contained options window that
--  duplicated every setting already present in Config/Panels/MythicPlus.
--  It is gone: /tmt routes to the main config, and the panel calls this
--  after writing a style key.
-- ═══════════════════════════════════════════════════════════════════════
function TMT:RefreshStyle()
    if not self.Frame then return end
    self:ApplyStyle()
    self:RefreshAll(self._previewActive and true or false)
end

-- ═══════════════════════════════════════════════════════════════════════
--  SLASH COMMANDS
-- ═══════════════════════════════════════════════════════════════════════
SLASH_TOMOMYTHICTRACKER1 = "/tmt"
SlashCmdList["TOMOMYTHICTRACKER"] = function(msg)
    msg = strtrim(msg or ""):lower()
    if     msg == ""        then
        if TomoMod_Config and TomoMod_Config.Toggle then
            TomoMod_Config.Show()
            TomoMod_Config.SwitchCategory("mythicplus")
        end
    elseif msg == "unlock"  then TMT:SetMovable(true);  print(L["tmt_unlock_msg"])
    elseif msg == "lock"    then TMT:SetMovable(false); print(L["tmt_lock_msg"])
    elseif msg == "reset"   then TMT:ResetPosition();   print(L["tmt_reset_msg"])
    elseif msg == "preview" then TMT:Preview()
    elseif msg == "key"     then
        if TomoMod_MythicPartyKeys then
            TomoMod_MythicPartyKeys:SendKeysToChat()
        end
    elseif msg == "kr"      then
        if TomoMod_MythicPartyKeys then
            TomoMod_MythicPartyKeys:ShowKeyRoulette()
        end
    elseif msg == "keysync" then
        -- KeySync.Debug exists precisely to tell a silent transport apart from
        -- a lookup that never matched, but nothing routed to it: the function
        -- was unreachable from any slash command.
        if TomoMod_KeySync and TomoMod_KeySync.Debug then
            TomoMod_KeySync.Debug()
        else
            print("|cff2ed884TomoMod|r KeySync: module not loaded")
        end
    elseif msg == "help"    then print(L["tmt_cmd_usage"])
    else print(L["tmt_unknown_cmd"]); print(L["tmt_cmd_usage"])
    end
end

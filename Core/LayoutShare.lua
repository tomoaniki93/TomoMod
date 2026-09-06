-- =====================================================================
-- TomoMod -- Layout Share
-- ---------------------------------------------------------------------
-- Exchanging WHERE things sit, not how they are configured.
--
-- A full profile export runs to roughly fifty thousand characters and
-- carries every setting the addon owns. What players actually pass
-- around is a layout: the anchors, and the type sizes that make those
-- anchors look the way the author intended. That payload is about eight
-- hundred characters -- it fits in a chat message.
--
-- The shape already existed. RES.Capture walks R.Anchors() and stores
-- exactly { positions, fonts }, so this module does not invent a format:
-- it wraps that table in a header, encodes it, and validates hard on the
-- way back in.
--
-- Two properties are worth stating up front because they are the whole
-- reason a shared layout is usable at all:
--
--   * Every position carries the author's refW/refH. Layout.Apply
--     rescales against the importer's screen, so a 1440p layout lands
--     correctly on 1080p. The reference is preserved verbatim on import
--     -- rewriting it to the importer's screen would destroy exactly the
--     information that makes the conversion work.
--
--   * Font sizes travel through the tier ratio. 1080p needs LARGER type
--     values than 1440p (fontScale 1.15 against 1.00), so importing a
--     1440p layout on 1080p multiplies, and the other direction divides.
--     Copying the numbers across verbatim would hand a 1080p player type
--     that is physically too small.
--
-- Nothing here executes anything from the string. Writes are confined to
-- the paths the manifests declare: an incoming payload can only ever
-- touch anchors and legibility keys, never an arbitrary corner of
-- TomoModDB.
-- =====================================================================

TomoMod_LayoutShare = TomoMod_LayoutShare or {}
local LS = TomoMod_LayoutShare

local R      = TomoMod_Registry
local Layout = TomoMod_Layout
local RES    = TomoMod_Resolution

LS.HEADER         = "TOMOMOD_LAYOUT"
LS.SCHEMA_VERSION = 1

-- Positions the author never moved are not worth shipping, and a share
-- string is read by humans deciding whether to trust it.
local POS_FIELDS = { "v", "point", "anchor", "x", "y", "refW", "refH" }

-- ---------------------------------------------------------------------
-- WHITELISTS
-- ---------------------------------------------------------------------
-- Rebuilt on demand rather than cached at load: the registry is filled
-- by manifests that may not all have run when this file is parsed, and a
-- stale set would silently drop whole modules from an import.
-- ---------------------------------------------------------------------

--- path -> anchor descriptor, for every anchor the manifests declare.
function LS.AnchorPaths()
    local out = {}
    if not R or not R.Anchors then return out end
    for _, a in ipairs(R.Anchors()) do
        out[a.path] = a
    end
    return out
end

--- path -> true, for every legibility key a resolution preset owns.
function LS.FontPaths()
    local out = {}
    if not RES or not RES.FONT_KEYS then return out end
    for _, p in ipairs(RES.FONT_KEYS) do out[p] = true end
    return out
end

-- ---------------------------------------------------------------------
-- SOURCE
-- ---------------------------------------------------------------------

local function CopyPosition(pos)
    if type(pos) ~= "table" then return nil end
    -- A position with neither point nor anchor has never been placed;
    -- shipping it would overwrite the importer's own with nothing.
    if not pos.point and not pos.anchor then return nil end
    local out = {}
    for _, f in ipairs(POS_FIELDS) do out[f] = pos[f] end
    return out
end

--- Builds the { positions, fonts } body from the live database.
local function BodyFromDB()
    local body = { positions = {}, fonts = {} }
    if not R or not TomoModDB then return body end

    for path in pairs(LS.AnchorPaths()) do
        local copy = CopyPosition(R.GetPath(TomoModDB, path))
        if copy then body.positions[path] = copy end
    end
    for path in pairs(LS.FontPaths()) do
        local v = R.GetPath(TomoModDB, path)
        if type(v) == "number" then body.fonts[path] = v end
    end
    return body
end

--- Same shape, read out of a stored capture instead.
local function BodyFromCapture(cap)
    local body = { positions = {}, fonts = {} }
    local anchors, fonts = LS.AnchorPaths(), LS.FontPaths()

    for path, pos in pairs(cap.positions or {}) do
        if anchors[path] then
            local copy = CopyPosition(pos)
            if copy then body.positions[path] = copy end
        end
    end
    for path, v in pairs(cap.fonts or {}) do
        if fonts[path] and type(v) == "number" then body.fonts[path] = v end
    end
    return body
end

-- ---------------------------------------------------------------------
-- EXPORT
-- ---------------------------------------------------------------------

--- Encodes the player's layout.
---
--- opts.tier    tier to export, defaults to the detected one
--- opts.source  "capture" | "live" | nil. nil prefers the stored capture
---              for the tier and falls back to the live database, which
---              is what a player means by "share my layout".
--- opts.author  free-form credit string, trimmed and capped
---
--- Returns encoded, report. The report says which source was used, so a
--- panel can tell the player they exported a capture from last week
--- rather than what is currently on screen.
function LS.Export(opts)
    opts = opts or {}
    local LibSerialize = LibStub and LibStub("TomoSerialize-1.0", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate", true)
    if not LibSerialize or not LibDeflate then
        return nil, { err = "Librairies manquantes (LibSerialize / LibDeflate)" }
    end
    if not R or not RES then return nil, { err = "Registre indisponible" } end

    local tier = opts.tier or RES.Detect()
    local body, source

    if opts.source ~= "live" then
        local cap = RES.GetCapture and RES.GetCapture(tier)
        if cap then body, source = BodyFromCapture(cap), "capture" end
    end
    if not body then
        if opts.source == "capture" then
            return nil, { err = "Aucune capture pour ce palier", tier = tier }
        end
        body, source = BodyFromDB(), "live"
    end

    local nPos, nFonts = 0, 0
    for _ in pairs(body.positions) do nPos = nPos + 1 end
    for _ in pairs(body.fonts) do nFonts = nFonts + 1 end
    if nPos == 0 then
        return nil, { err = "Aucune position à partager", tier = tier }
    end

    local w, h = RES.PhysicalSize()
    local author = opts.author
    if type(author) == "string" then
        author = author:match("^%s*(.-)%s*$"):sub(1, 40)
        if author == "" then author = nil end
    else
        author = nil
    end

    local payload = {
        _h        = LS.HEADER,
        _v        = LS.SCHEMA_VERSION,
        tier      = tier,
        screen    = { w, h },
        author    = author,
        positions = body.positions,
        fonts     = body.fonts,
    }

    local ok, serialized = pcall(LibSerialize.Serialize, LibSerialize, payload)
    if not ok or not serialized then return nil, { err = "Sérialisation échouée" } end
    local ok2, compressed = pcall(LibDeflate.CompressDeflate, LibDeflate, serialized, { level = 9 })
    if not ok2 or not compressed then return nil, { err = "Compression échouée" } end
    local ok3, encoded = pcall(LibDeflate.EncodeForPrint, LibDeflate, compressed)
    if not ok3 or not encoded then return nil, { err = "Encodage échoué" } end

    return encoded, { source = source, tier = tier, positions = nPos,
                      fonts = nFonts, length = #encoded }
end

-- ---------------------------------------------------------------------
-- DECODE
-- ---------------------------------------------------------------------

--- Decodes and validates. Everything unrecognised is dropped here rather
--- than at write time, so Import only ever sees a payload it can trust
--- and the panel can show what was rejected before anything is applied.
---
--- Returns payload, err. The payload gains a `dropped` count.
function LS.Decode(str)
    if type(str) ~= "string" or str == "" then return nil, "Chaîne vide" end
    local LibSerialize = LibStub and LibStub("TomoSerialize-1.0", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate", true)
    if not LibSerialize or not LibDeflate then
        return nil, "Librairies manquantes (LibSerialize / LibDeflate)"
    end

    str = str:match("^%s*(.-)%s*$")
    local decoded = LibDeflate:DecodeForPrint(str)
    if not decoded then return nil, "Chaîne illisible" end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil, "Décompression échouée" end

    local ok, payload = pcall(LibSerialize.DeSerialize, LibSerialize, decompressed)
    if not ok or type(payload) ~= "table" then return nil, "Charge illisible" end
    if payload._h ~= LS.HEADER then return nil, "Ce n'est pas une disposition TomoMod" end
    if type(payload._v) ~= "number" or payload._v > LS.SCHEMA_VERSION then
        return nil, "Version de disposition trop récente"
    end

    -- The whitelist is the security boundary. A payload can name any key
    -- it likes; only the ones the manifests declare survive this filter,
    -- so a hostile string cannot reach past anchors and font sizes.
    local anchors, fonts = LS.AnchorPaths(), LS.FontPaths()
    local clean, dropped = { positions = {}, fonts = {} }, 0

    for path, pos in pairs(type(payload.positions) == "table" and payload.positions or {}) do
        local copy = (anchors[path] and type(pos) == "table") and CopyPosition(pos) or nil
        if copy and type(copy.x) == "number" and type(copy.y) == "number" then
            clean.positions[path] = copy
        else
            dropped = dropped + 1
        end
    end
    for path, v in pairs(type(payload.fonts) == "table" and payload.fonts or {}) do
        if fonts[path] and type(v) == "number" then clean.fonts[path] = v
        else dropped = dropped + 1 end
    end

    payload.positions = clean.positions
    payload.fonts     = clean.fonts
    payload.dropped   = dropped
    if type(payload.author) ~= "string" then payload.author = nil end
    if not RES or not RES.Get or not RES.Get(payload.tier) then payload.tier = nil end
    return payload
end

-- ---------------------------------------------------------------------
-- INSPECT
-- ---------------------------------------------------------------------

--- Groups a decoded payload by module, marking what actually differs.
--- Same role as SI.Inspect for profiles: the panel needs to offer a
--- meaningful "only what changes" before anything is written.
function LS.Inspect(payload)
    local out = {}
    if type(payload) ~= "table" or not R then return out end

    local byModule = {}
    for _, a in ipairs(R.Anchors()) do
        local incoming = payload.positions and payload.positions[a.path]
        if incoming then
            local current = TomoModDB and R.GetPath(TomoModDB, a.path)
            local differs = true
            if type(current) == "table" then
                differs = not (current.point == incoming.point
                    and current.anchor == incoming.anchor
                    and current.x == incoming.x
                    and current.y == incoming.y)
            end
            local g = byModule[a.module]
            if not g then
                g = { module = a.module, anchors = {} }
                byModule[a.module] = g
                out[#out + 1] = g
            end
            g.anchors[#g.anchors + 1] = {
                id = a.id, path = a.path, label = a.label, differs = differs,
            }
        end
    end
    return out
end

--- Every anchor path in the payload, or only the ones that differ.
function LS.AllPaths(payload, onlyChanged)
    local out = {}
    for _, g in ipairs(LS.Inspect(payload)) do
        for _, e in ipairs(g.anchors) do
            if not onlyChanged or e.differs then out[#out + 1] = e.path end
        end
    end
    table.sort(out)
    return out
end

-- ---------------------------------------------------------------------
-- IMPORT
-- ---------------------------------------------------------------------

--- The ratio to carry a font size from one tier to another. 1080p wants
--- larger values than 1440p, so a 1440p layout landing on 1080p scales
--- UP. Returns 1 when either end is unknown, which is the safe answer:
--- copying verbatim is wrong but survivable, guessing is not.
local function FontRatio(fromTier, toTier)
    if not RES or not RES.Get then return 1 end
    local a, b = RES.Get(fromTier), RES.Get(toTier)
    if not a or not b then return 1 end
    local from = tonumber(a.fontScale) or 1
    local to   = tonumber(b.fontScale) or 1
    if from == 0 then return 1 end
    return to / from
end
LS._FontRatio = FontRatio

--- Writes a decoded payload into the live database.
---
--- opts.paths     restrict to these anchor paths; nil means all of them
--- opts.fonts     false to leave the legibility keys alone
--- opts.positions false to leave the anchors alone
--- opts.capture   true to also store the result as the importer's
---                capture for their own detected tier
---
--- The importer's tier is the destination, never the author's: a 1080p
--- player taking a 1440p layout should not have to select 1440p to see
--- it. The author's refW/refH stay on each position so Layout.Apply can
--- do the conversion at draw time.
function LS.Import(payload, opts)
    opts = opts or {}
    local report = { ok = false, positions = 0, fonts = 0, skipped = 0,
                     tier = nil, fromTier = nil, ratio = 1 }
    if type(payload) == "string" then
        local decoded, err = LS.Decode(payload)
        if not decoded then report.err = err; return report end
        payload = decoded
    end
    if type(payload) ~= "table" or not R or not TomoModDB then
        report.err = "Charge invalide"
        return report
    end

    local myTier = (RES and RES.Detect and RES.Detect()) or nil
    report.tier, report.fromTier = myTier, payload.tier

    local only
    if type(opts.paths) == "table" then
        only = {}
        for _, p in ipairs(opts.paths) do only[p] = true end
    end

    if opts.positions ~= false then
        local anchors = LS.AnchorPaths()
        for path, pos in pairs(payload.positions or {}) do
            if anchors[path] and (not only or only[path]) then
                local copy = CopyPosition(pos)
                if copy then
                    copy.v = copy.v or (Layout and Layout.SCHEMA_VERSION) or 2
                    R.SetPath(TomoModDB, path, copy)
                    report.positions = report.positions + 1
                end
            elseif anchors[path] then
                report.skipped = report.skipped + 1
            end
        end
    end

    if opts.fonts ~= false then
        local ratio = FontRatio(payload.tier, myTier)
        report.ratio = ratio
        for path, v in pairs(payload.fonts or {}) do
            if LS.FontPaths()[path] and type(v) == "number" then
                local scaled = (RES and RES.ScaledFont)
                    and RES.ScaledFont(v, ratio)
                    or math.floor(v * ratio + 0.5)
                if scaled then
                    R.SetPath(TomoModDB, path, scaled)
                    report.fonts = report.fonts + 1
                end
            end
        end
    end

    if opts.capture and myTier and RES and RES.Capture then
        RES.Capture(myTier)
    end

    report.ok = (report.positions + report.fonts) > 0
    return report
end

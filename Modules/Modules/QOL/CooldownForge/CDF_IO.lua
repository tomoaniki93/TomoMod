-- =====================================================================
-- CooldownForge -- Import / Export (Lot 6)
-- Dedicated per-class share strings. Same pipeline as Core/Profiles:
--   Serialize (TomoSerialize-1.0) -> CompressDeflate{level=1} -> EncodeForPrint
-- and the reverse on import. Position is stripped on export; import merges
-- by bar id (absent -> appended, existing -> replaced) and never touches
-- other classes. Requires CDF_Core + CDF_API + CDF_Catalog.
-- =====================================================================

local CDF = TomoMod_CooldownForge

CDF.EXPORT_HEADER  = "TOMOCDF"
CDF.EXPORT_VERSION = 1

-- [L1] The encode/decode pipeline moved to Core/Forge/ForgeIO.lua and is
-- shared by every share string in the addon. Same libs, same error texts.
local codec

local function getCodec()
    if not codec and TomoMod_Forge and TomoMod_Forge.IO then
        codec = TomoMod_Forge.IO.MakeCodec(CDF.EXPORT_HEADER, CDF.EXPORT_VERSION, "CooldownForge")
    end
    return codec
end

-- ---------------------------------------------------------------------
-- Export: returns encoded string, or nil + reason.
-- ---------------------------------------------------------------------
function CDF.Export(class)
    if not getCodec() then return nil, "Librairies manquantes (LibSerialize / LibDeflate)" end
    class = class or CDF.PlayerClass()
    local bars = class and CDF.GetClassBars(class)
    if not bars then return nil, "Classe invalide" end

    local out = {}
    for i = 1, #bars do
        local b = CopyTable(bars[i])
        b.position = nil          -- personal; stripped on export
        out[i] = b
    end
    local payload = {
        _header  = CDF.EXPORT_HEADER,
        _version = CDF.EXPORT_VERSION,
        class    = class,
        bars     = out,
    }

    return getCodec().Encode(payload)
end

-- ---------------------------------------------------------------------
-- [S2] Export a single bar as a shareable asset. Same envelope as the
-- class export (header/version unchanged: older clients fail gracefully
-- with "Donnees manquantes" instead of a version error).
-- ---------------------------------------------------------------------
function CDF.ExportBar(class, id)
    if not getCodec() then return nil, "Librairies manquantes (LibSerialize / LibDeflate)" end
    class = class or CDF.PlayerClass()
    local bar = class and id and CDF.GetBar(class, id)
    if not bar then return nil, "Barre introuvable" end

    local b = CopyTable(bar)
    b.position = nil              -- personal; stripped on export
    local payload = {
        _header  = CDF.EXPORT_HEADER,
        _version = CDF.EXPORT_VERSION,
        class    = class,
        bar      = b,
    }

    return getCodec().Encode(payload)
end

-- ---------------------------------------------------------------------
-- Import: merges into payload.class by bar id. Returns true, { class, count }
-- on success, or false + reason. Never overwrites other classes.
-- [S2] Also accepts single-bar payloads (payload.bar): the bar is always
-- APPENDED under a fresh id so a shared asset never clobbers local bars.
-- ---------------------------------------------------------------------
function CDF.Import(str)
    if not getCodec() then return false, "Librairies manquantes (LibSerialize / LibDeflate)" end
    local payload, reason = getCodec().Decode(str)
    if not payload then return false, reason end
    if type(payload.class) ~= "string"
        or (type(payload.bars) ~= "table" and type(payload.bar) ~= "table") then
        return false, "Donnees manquantes"
    end

    local class = payload.class
    local arr = CDF.GetClassBars(class)
    if not arr then return false, "Classe cible invalide" end

    -- [S2] single-bar payload: sanitize, revalidate entries, fresh id, append
    if type(payload.bar) == "table" then
        local ib = payload.bar
        CDF.SanitizeBar(ib)
        local clean = {}
        for _, e in ipairs(ib.entries or {}) do
            if CDF.ValidateEntry(e) then clean[#clean + 1] = CDF.NewEntrySchema(e) end
        end
        ib.entries = clean
        ib.position = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 }
        ib.id = CDF.genBarId(arr)
        arr[#arr + 1] = ib
        return true, { class = class, count = 1, barId = ib.id }
    end

    -- Index existing bars by id for merge-by-id.
    local byId = {}
    for i = 1, #arr do byId[arr[i].id] = i end

    local count = 0
    for _, ib in ipairs(payload.bars) do
        if type(ib) == "table" then
            CDF.SanitizeBar(ib)
            -- Keep only valid entries (defensive against malformed imports).
            local clean = {}
            for _, e in ipairs(ib.entries or {}) do
                if CDF.ValidateEntry(e) then clean[#clean + 1] = CDF.NewEntrySchema(e) end
            end
            ib.entries = clean
            -- Position is personal; give the imported bar a neutral default.
            ib.position = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 }
            if type(ib.id) ~= "string" or ib.id == "" then ib.id = CDF.genBarId(arr) end

            local existing = byId[ib.id]
            if existing then
                arr[existing] = ib
            else
                arr[#arr + 1] = ib
                byId[ib.id] = #arr
            end
            count = count + 1
        end
    end

    return true, { class = class, count = count }
end

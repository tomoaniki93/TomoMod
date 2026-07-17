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

local function libs()
    local ser = LibStub and LibStub("TomoSerialize-1.0", true)
    local def = LibStub and LibStub("LibDeflate", true)
    return ser, def
end

-- ---------------------------------------------------------------------
-- Export: returns encoded string, or nil + reason.
-- ---------------------------------------------------------------------
function CDF.Export(class)
    local ser, def = libs()
    if not ser or not def then return nil, "Librairies manquantes (LibSerialize / LibDeflate)" end
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

    local ok, serialized = pcall(ser.Serialize, ser, payload)
    if not ok or not serialized then return nil, "Serialisation echouee" end
    local compressed = def:CompressDeflate(serialized, { level = 1 })
    if not compressed then return nil, "Compression echouee" end
    local encoded = def:EncodeForPrint(compressed)
    if not encoded then return nil, "Encodage echoue" end
    return encoded
end

-- ---------------------------------------------------------------------
-- Import: merges into payload.class by bar id. Returns true, { class, count }
-- on success, or false + reason. Never overwrites other classes.
-- ---------------------------------------------------------------------
function CDF.Import(str)
    local ser, def = libs()
    if not ser or not def then return false, "Librairies manquantes (LibSerialize / LibDeflate)" end
    if not str or str == "" then return false, "Chaine vide" end
    str = str:match("^%s*(.-)%s*$") or str

    local decoded = def:DecodeForPrint(str)
    if not decoded then return false, "Decodage echoue" end
    local decompressed = def:DecompressDeflate(decoded)
    if not decompressed then return false, "Decompression echouee" end

    local ok, payload = pcall(function() return ser:DeSerialize(decompressed) end)
    if not ok or type(payload) ~= "table" then return false, "Deserialisation echouee" end
    if payload._header ~= CDF.EXPORT_HEADER then return false, "Pas une chaine CooldownForge" end
    if type(payload._version) ~= "number" or payload._version > CDF.EXPORT_VERSION then
        return false, "Version incompatible (v" .. tostring(payload._version) .. ")"
    end
    if type(payload.class) ~= "string" or type(payload.bars) ~= "table" then
        return false, "Donnees manquantes"
    end

    local class = payload.class
    local arr = CDF.GetClassBars(class)
    if not arr then return false, "Classe cible invalide" end

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

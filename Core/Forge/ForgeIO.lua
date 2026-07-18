-- =====================================================================
-- TomoMod Forge -- IO (L1)
-- Versioned share-string codec factory. One pipeline for every share
-- string in the addon (class profiles, CooldownForge class/bar exports,
-- future AstralForge assets):
--   Serialize (TomoSerialize-1.0) -> CompressDeflate{level=1}
--   -> EncodeForPrint, and the exact reverse with header/version checks.
-- Error strings are the historical ones so existing UX is unchanged.
-- =====================================================================

local Forge = TomoMod_Forge
if not Forge then return end

Forge.IO = Forge.IO or {}

local function libs()
    local ser = LibStub and LibStub("TomoSerialize-1.0", true)
    local def = LibStub and LibStub("LibDeflate", true)
    return ser, def
end

-- header  : short uppercase tag stamped into the payload (e.g. "TOMOCDF")
-- version : payload format version; Decode rejects payloads newer than it
-- label   : optional human name used in the "not a X string" error
function Forge.IO.MakeCodec(header, version, label)
    local codec = {
        header  = header,
        version = tonumber(version) or 1,
        label   = label or header,
    }

    -- payload: plain table; _header/_version are stamped in (overwritten).
    -- Returns encoded string, or nil + reason.
    function codec.Encode(payload)
        local ser, def = libs()
        if not ser or not def then
            return nil, "Librairies manquantes (LibSerialize / LibDeflate)"
        end
        if type(payload) ~= "table" then
            return nil, "Donnees invalides"
        end
        payload._header  = codec.header
        payload._version = codec.version

        local ok, serialized = pcall(ser.Serialize, ser, payload)
        if not ok or not serialized then return nil, "Serialisation echouee" end
        local compressed = def:CompressDeflate(serialized, { level = 1 })
        if not compressed then return nil, "Compression echouee" end
        local encoded = def:EncodeForPrint(compressed)
        if not encoded then return nil, "Encodage echoue" end
        return encoded
    end

    -- Returns the decoded payload table, or nil + reason.
    function codec.Decode(str)
        local ser, def = libs()
        if not ser or not def then
            return nil, "Librairies manquantes (LibSerialize / LibDeflate)"
        end
        if not str or str == "" then return nil, "Chaine vide" end
        str = str:match("^%s*(.-)%s*$") or str

        local decoded = def:DecodeForPrint(str)
        if not decoded then return nil, "Decodage echoue" end
        local decompressed = def:DecompressDeflate(decoded)
        if not decompressed then return nil, "Decompression echouee" end

        local ok, payload = pcall(function() return ser:DeSerialize(decompressed) end)
        if not ok or type(payload) ~= "table" then return nil, "Deserialisation echouee" end
        if payload._header ~= codec.header then
            return nil, "Pas une chaine " .. codec.label
        end
        if type(payload._version) ~= "number" or payload._version > codec.version then
            return nil, "Version incompatible (v" .. tostring(payload._version) .. ")"
        end
        return payload
    end

    return codec
end

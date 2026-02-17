-- =====================================
-- Core/Profiles.lua — Profils par spécialisation + Import/Export
-- Chargé APRÈS Database.lua, AVANT Config panels
-- =====================================

TomoModMini_Profiles = {}
local P = TomoModMini_Profiles

-- Version intégrée dans chaque export
local EXPORT_VERSION = 1
local EXPORT_HEADER  = "TMOD"

-- Clés internes exclues des snapshots
local EXCLUDED_KEYS = {
    ["_profiles"] = true,
}

-- =====================================
-- HELPERS
-- =====================================

local function DeepCopy(src, skipKeys)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        if not (skipKeys and skipKeys[k]) then
            copy[k] = DeepCopy(v)
        end
    end
    return copy
end

-- Snapshot: extraire tous les settings modules de TomoModMiniDB
local function SnapshotSettings()
    local snap = {}
    for k, v in pairs(TomoModMiniDB) do
        if not EXCLUDED_KEYS[k] then
            snap[k] = DeepCopy(v)
        end
    end
    return snap
end

-- Appliquer un snapshot: écraser TomoModMiniDB (en préservant _profiles)
local function ApplySnapshot(snap)
    for k in pairs(TomoModMiniDB) do
        if not EXCLUDED_KEYS[k] then
            TomoModMiniDB[k] = nil
        end
    end
    for k, v in pairs(snap) do
        if not EXCLUDED_KEYS[k] then
            TomoModMiniDB[k] = DeepCopy(v)
        end
    end
    -- Remplir les clés manquantes depuis les defaults
    TomoModMini_MergeTables(TomoModMiniDB, TomoModMini_Defaults)
end

-- =====================================
-- SPEC PROFILE SYSTEM
-- =====================================

function P.GetAllSpecs()
    local specs = {}
    local numSpecs = GetNumSpecializations()
    for i = 1, numSpecs do
        local id, name, desc, icon, role = GetSpecializationInfo(i)
        if id then
            table.insert(specs, {
                index = i,
                id    = id,
                name  = name,
                icon  = icon,
                role  = role,
            })
        end
    end
    return specs
end

function P.GetCurrentSpecID()
    local specIndex = GetSpecialization()
    if not specIndex then return 0 end
    local id = GetSpecializationInfo(specIndex)
    return id or 0
end

function P.EnsureProfilesDB()
    if not TomoModMiniDB._profiles then
        TomoModMiniDB._profiles = {
            useSpecProfiles = false,
            specs = {},
            named = {},
            activeProfile = "Default",
        }
    end
    if not TomoModMiniDB._profiles.specs then
        TomoModMiniDB._profiles.specs = {}
    end
    if not TomoModMiniDB._profiles.named then
        TomoModMiniDB._profiles.named = {}
    end
    if not TomoModMiniDB._profiles.activeProfile then
        TomoModMiniDB._profiles.activeProfile = "Default"
    end
end

-- =====================================
-- NAMED PROFILES
-- =====================================

function P.GetActiveProfileName()
    P.EnsureProfilesDB()
    return TomoModMiniDB._profiles.activeProfile or "Default"
end

function P.GetProfileList()
    P.EnsureProfilesDB()
    local list = {}
    for name in pairs(TomoModMiniDB._profiles.named) do
        table.insert(list, name)
    end
    table.sort(list)
    -- Always have "Default" first
    local hasDefault = false
    for i, n in ipairs(list) do
        if n == "Default" then
            table.remove(list, i)
            hasDefault = true
            break
        end
    end
    table.insert(list, 1, "Default")
    return list
end

function P.CreateNamedProfile(name)
    if not name or name == "" then return false, "Empty name" end
    P.EnsureProfilesDB()
    TomoModMiniDB._profiles.named[name] = SnapshotSettings()
    TomoModMiniDB._profiles.activeProfile = name
    return true
end

function P.LoadNamedProfile(name)
    P.EnsureProfilesDB()
    local snap = TomoModMiniDB._profiles.named[name]
    if snap then
        ApplySnapshot(snap)
        TomoModMiniDB._profiles.activeProfile = name
        return true
    end
    return false
end

function P.DeleteNamedProfile(name)
    P.EnsureProfilesDB()
    if name == "Default" then return false end
    TomoModMiniDB._profiles.named[name] = nil
    if TomoModMiniDB._profiles.activeProfile == name then
        TomoModMiniDB._profiles.activeProfile = "Default"
    end
    return true
end

function P.SaveCurrentToActiveProfile()
    P.EnsureProfilesDB()
    local name = TomoModMiniDB._profiles.activeProfile or "Default"
    TomoModMiniDB._profiles.named[name] = SnapshotSettings()
end

function P.SaveToSpec(specID)
    P.EnsureProfilesDB()
    TomoModMiniDB._profiles.specs[specID] = SnapshotSettings()
end

function P.LoadFromSpec(specID)
    P.EnsureProfilesDB()
    local snap = TomoModMiniDB._profiles.specs[specID]
    if snap then
        ApplySnapshot(snap)
        return true
    end
    return false
end

function P.HasSpecProfile(specID)
    P.EnsureProfilesDB()
    return TomoModMiniDB._profiles.specs[specID] ~= nil
end

function P.DeleteSpecProfile(specID)
    P.EnsureProfilesDB()
    TomoModMiniDB._profiles.specs[specID] = nil
end

function P.CopyCurrentToSpec(specID)
    P.SaveToSpec(specID)
end

function P.EnableSpecProfiles()
    P.EnsureProfilesDB()
    TomoModMiniDB._profiles.useSpecProfiles = true
    local specID = P.GetCurrentSpecID()
    if specID > 0 then
        P.SaveToSpec(specID)
    end
end

function P.DisableSpecProfiles()
    P.EnsureProfilesDB()
    TomoModMiniDB._profiles.useSpecProfiles = false
end

-- Appelé lors de PLAYER_SPECIALIZATION_CHANGED
function P.OnSpecChanged(newSpecID)
    P.EnsureProfilesDB()
    if not TomoModMiniDB._profiles.useSpecProfiles then return false end

    -- Sauvegarder le profil actuel dans l'ancien spec (stocké temporairement)
    if P._lastSpecID and P._lastSpecID > 0 then
        P.SaveToSpec(P._lastSpecID)
    end

    -- Charger le nouveau profil si existant, sinon sauvegarder le courant
    if newSpecID and newSpecID > 0 then
        if P.HasSpecProfile(newSpecID) then
            P.LoadFromSpec(newSpecID)
            P._lastSpecID = newSpecID
            return true -- reload nécessaire
        else
            P.SaveToSpec(newSpecID)
            P._lastSpecID = newSpecID
        end
    end

    return false
end

-- Initialiser le tracking du spec ID courant
function P.InitSpecTracking()
    P._lastSpecID = P.GetCurrentSpecID()
end

-- =====================================
-- IMPORT / EXPORT
-- =====================================

function P.Export()
    local LibSerialize = LibStub and LibStub("LibSerialize", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate", true)

    if not LibSerialize or not LibDeflate then
        return nil, "Missing libraries (LibSerialize / LibDeflate)"
    end

    local payload = {
        _header  = EXPORT_HEADER,
        _version = EXPORT_VERSION,
        _class   = select(2, UnitClass("player")),
        _spec    = P.GetCurrentSpecID(),
        _date    = date("%Y-%m-%d %H:%M"),
        settings = SnapshotSettings(),
    }

    -- Serialize → Compress → Encode
    local serialized = LibSerialize:Serialize(payload)
    if not serialized then return nil, "Serialization failed" end

    local compressed = LibDeflate:CompressDeflate(serialized, { level = 9 })
    if not compressed then return nil, "Compression failed" end

    local encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then return nil, "Encoding failed" end

    return encoded
end

function P.Import(str)
    local LibSerialize = LibStub and LibStub("LibSerialize", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate", true)

    if not LibSerialize or not LibDeflate then
        return false, "Missing libraries (LibSerialize / LibDeflate)"
    end

    if not str or str == "" then
        return false, "Empty string"
    end

    -- Nettoyer les espaces/retours à la ligne
    str = str:gsub("%s+", "")

    -- Decode → Decompress → Deserialize
    local decoded = LibDeflate:DecodeForPrint(str)
    if not decoded then
        return false, "Decode failed"
    end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return false, "Decompression failed"
    end

    -- DeSerialize returns (success, data) — pcall adds its own bool prefix
    -- pcall(func) → ok, ret1, ret2  where ret1=success, ret2=data
    local pcallOk, deserializeOk, payload = pcall(function()
        return LibSerialize:DeSerialize(decompressed)
    end)

    if not pcallOk or not deserializeOk or not payload then
        return false, "Deserialization failed"
    end

    -- Validation de la structure
    if type(payload) ~= "table" then
        return false, "Invalid data"
    end

    if payload._header ~= EXPORT_HEADER then
        return false, "Not a TomoModMini export string"
    end

    if type(payload._version) ~= "number" or payload._version > EXPORT_VERSION then
        return false, "Incompatible version (v" .. tostring(payload._version) .. ")"
    end

    if type(payload.settings) ~= "table" then
        return false, "Missing settings"
    end

    -- Sanitize: seulement les clés connues depuis les defaults
    local sanitized = {}
    for k in pairs(TomoModMini_Defaults) do
        if payload.settings[k] ~= nil then
            sanitized[k] = DeepCopy(payload.settings[k])
        end
    end

    ApplySnapshot(sanitized)
    return true
end

-- Preview sans appliquer (pour afficher les métadonnées)
function P.PreviewImport(str)
    local LibSerialize = LibStub and LibStub("LibSerialize", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate", true)

    if not LibSerialize or not LibDeflate then return nil end
    if not str or str == "" then return nil end

    str = str:gsub("%s+", "")

    local decoded = LibDeflate:DecodeForPrint(str)
    if not decoded then return nil end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil end

    local pcallOk, deserializeOk, payload = pcall(function()
        return LibSerialize:DeSerialize(decompressed)
    end)

    if not pcallOk or not deserializeOk or type(payload) ~= "table" then return nil end
    if payload._header ~= EXPORT_HEADER then return nil end

    -- Compter le nombre de modules inclus
    local moduleCount = 0
    if type(payload.settings) == "table" then
        for k in pairs(payload.settings) do
            if TomoModMini_Defaults[k] then
                moduleCount = moduleCount + 1
            end
        end
    end

    return {
        version     = payload._version,
        class       = payload._class,
        spec        = payload._spec,
        date        = payload._date,
        moduleCount = moduleCount,
    }
end
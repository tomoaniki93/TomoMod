-- =====================================
-- Core/Profiles.lua
-- Système de profils TomoMod
--
-- Architecture :
--   TomoModDB._profiles = {
--     named        = { ["Default"] = snapshot, ... },
--     profileOrder = { "Default", ... },   -- ordre d'affichage
--     activeProfile  = "Default",
--     specProfiles   = { [specID] = "nomProfil" },  -- spec → nom profil
--   }
--
-- Inspiré d'EllesmereUI_Profiles.lua :
--   - specs mappés vers des profils nommés (pas des snapshots indépendants)
--   - auto-save du profil courant avant tout switch
--   - rename, duplicate
--   - profileOrder explicite
-- =====================================

TomoMod_Profiles = {}
local P = TomoMod_Profiles

local EXPORT_VERSION = 1
local EXPORT_HEADER  = "TMOD"

local EXCLUDED_KEYS = { ["_profiles"] = true }

-- =====================================
-- DEEP COPY / DEEP MERGE
-- =====================================

local function DeepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do copy[k] = DeepCopy(v) end
    return copy
end

local function DeepMerge(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then
            DeepMerge(dst[k], v)
        else
            dst[k] = (type(v) == "table") and DeepCopy(v) or v
        end
    end
end

-- =====================================
-- SNAPSHOT / APPLY
-- =====================================

local function SnapshotSettings()
    local snap = {}
    for k, v in pairs(TomoModDB) do
        if not EXCLUDED_KEYS[k] then snap[k] = DeepCopy(v) end
    end
    return snap
end

local function ApplySnapshot(snap)
    for k in pairs(TomoModDB) do
        if not EXCLUDED_KEYS[k] then TomoModDB[k] = nil end
    end
    for k, v in pairs(snap) do
        if not EXCLUDED_KEYS[k] then TomoModDB[k] = DeepCopy(v) end
    end
    TomoMod_MergeTables(TomoModDB, TomoMod_Defaults)
end

-- =====================================
-- DB INIT
-- =====================================

-- [PERF] Flag to avoid redundant init work on chained calls
local _profilesDBReady = false

function P.EnsureProfilesDB()
    if _profilesDBReady then return end

    if not TomoModDB._profiles then TomoModDB._profiles = {} end
    local db = TomoModDB._profiles

    if not db.named        then db.named        = {} end
    if not db.profileOrder then db.profileOrder = {} end
    if not db.specProfiles then db.specProfiles = {} end
    if not db.activeProfile then db.activeProfile = "Default" end

    -- Migration : ancien format specs = { [specID] = snapshot }
    -- On supprime simplement les anciens snapshots ; l'utilisateur
    -- réassignera ses specs aux profils nommés existants.
    if db.specs then
        db.specs = nil
    end

    -- Nettoyage : supprimer les profils "Spec-NNN" créés par une ancienne
    -- version de la migration. Ils ne correspondent à aucun profil nommé
    -- par l'utilisateur.
    if not db._specProfilesCleaned then
        db._specProfilesCleaned = true
        local toRemove = {}
        for _, name in ipairs(db.profileOrder) do
            if name:match("^Spec%-%d+$") then
                table.insert(toRemove, name)
            end
        end
        for _, name in ipairs(toRemove) do
            db.named[name] = nil
            -- Retirer de profileOrder
            for i = #db.profileOrder, 1, -1 do
                if db.profileOrder[i] == name then
                    table.remove(db.profileOrder, i)
                end
            end
            -- Retirer les assignations de spec qui pointaient dessus
            for specID, pName in pairs(db.specProfiles) do
                if pName == name then db.specProfiles[specID] = nil end
            end
        end
        -- Si le profil actif était un Spec-NNN, revenir sur Default
        if db.activeProfile and db.activeProfile:match("^Spec%-%d+$") then
            db.activeProfile = "Default"
        end
    end

    -- Garantir "Default" dans les profils nommés
    if not db.named["Default"] then
        db.named["Default"] = SnapshotSettings()
    end

    -- Garantir "Default" en tête de l'ordre
    local hasDefault = false
    for _, n in ipairs(db.profileOrder) do
        if n == "Default" then hasDefault = true; break end
    end
    if not hasDefault then
        table.insert(db.profileOrder, 1, "Default")
    end

    -- Synchronisation : tout profil présent dans named doit être dans profileOrder.
    -- Evite les profils "fantômes" (actifs mais invisibles dans la liste/dropdowns).
    local inOrder = {}
    for _, n in ipairs(db.profileOrder) do inOrder[n] = true end
    for name in pairs(db.named) do
        if not inOrder[name] then
            table.insert(db.profileOrder, name)
        end
    end

    _profilesDBReady = true
end

-- =====================================
-- SPEC HELPERS
-- =====================================

function P.GetAllSpecs()
    local specs = {}
    local numSpecs = GetNumSpecializations and GetNumSpecializations() or 0
    for i = 1, numSpecs do
        local id, name, _, icon, role = GetSpecializationInfo(i)
        if id then
            table.insert(specs, { index = i, id = id, name = name, icon = icon, role = role })
        end
    end
    return specs
end

function P.GetCurrentSpecID()
    local idx = GetSpecialization and GetSpecialization()
    if not idx then return 0 end
    local id = GetSpecializationInfo(idx)
    return id or 0
end

-- =====================================
-- PROFILS NOMMÉS
-- =====================================

function P.GetActiveProfileName()
    P.EnsureProfilesDB()
    return TomoModDB._profiles.activeProfile or "Default"
end

function P.GetProfileList()
    P.EnsureProfilesDB()
    return TomoModDB._profiles.profileOrder, TomoModDB._profiles.named
end

--- Sauvegarde les paramètres actuels dans le profil actif
function P.AutoSaveActiveProfile()
    P.EnsureProfilesDB()
    local name = TomoModDB._profiles.activeProfile or "Default"
    TomoModDB._profiles.named[name] = SnapshotSettings()
end

--- Crée un nouveau profil depuis les paramètres actuels
function P.CreateNamedProfile(name)
    if not name or name:match("^%s*$") then return false, "Empty name" end
    name = name:match("^%s*(.-)%s*$")
    P.EnsureProfilesDB()
    local db = TomoModDB._profiles

    -- Auto-save le profil actif avant de créer le nouveau
    P.AutoSaveActiveProfile()

    db.named[name] = SnapshotSettings()
    -- Insérer en tête de liste (après Default)
    local found = false
    for _, n in ipairs(db.profileOrder) do
        if n == name then found = true; break end
    end
    if not found then
        table.insert(db.profileOrder, 2, name)  -- position 1 = Default
    end
    db.activeProfile = name
    return true
end

--- Charge un profil nommé
function P.LoadNamedProfile(name)
    P.EnsureProfilesDB()
    local db = TomoModDB._profiles
    local snap = db.named[name]
    if not snap then return false end

    -- Sauvegarder le profil courant avant de changer
    P.AutoSaveActiveProfile()

    ApplySnapshot(snap)
    db.activeProfile = name
    return true
end

--- Supprime un profil nommé (pas "Default")
function P.DeleteNamedProfile(name)
    if name == "Default" then return false end
    P.EnsureProfilesDB()
    local db = TomoModDB._profiles
    db.named[name] = nil
    for i, n in ipairs(db.profileOrder) do
        if n == name then table.remove(db.profileOrder, i); break end
    end
    -- Nettoyer les assignations de spec qui pointaient dessus
    for specID, pName in pairs(db.specProfiles) do
        if pName == name then db.specProfiles[specID] = nil end
    end
    -- Si c'était le profil actif, revenir sur Default
    if db.activeProfile == name then
        db.activeProfile = "Default"
    end
    return true
end

--- Renomme un profil nommé
function P.RenameProfile(oldName, newName)
    if not newName or newName:match("^%s*$") then return false, "Empty name" end
    if oldName == "Default" then return false, "Cannot rename Default" end
    newName = newName:match("^%s*(.-)%s*$")
    P.EnsureProfilesDB()
    local db = TomoModDB._profiles
    if not db.named[oldName] then return false, "Profile not found" end
    if db.named[newName] then return false, "Name already exists" end

    db.named[newName] = db.named[oldName]
    db.named[oldName] = nil
    for i, n in ipairs(db.profileOrder) do
        if n == oldName then db.profileOrder[i] = newName; break end
    end
    for specID, pName in pairs(db.specProfiles) do
        if pName == oldName then db.specProfiles[specID] = newName end
    end
    if db.activeProfile == oldName then db.activeProfile = newName end
    return true
end

--- Duplique un profil sous un nouveau nom
function P.DuplicateProfile(fromName, toName)
    if not toName or toName:match("^%s*$") then return false, "Empty name" end
    toName = toName:match("^%s*(.-)%s*$")
    P.EnsureProfilesDB()
    local db = TomoModDB._profiles
    local snap = db.named[fromName]
    if not snap then return false, "Source profile not found" end
    if db.named[toName] then return false, "Name already exists" end

    db.named[toName] = DeepCopy(snap)
    local found = false
    for _, n in ipairs(db.profileOrder) do
        if n == toName then found = true; break end
    end
    if not found then
        -- Insérer juste après la source
        for i, n in ipairs(db.profileOrder) do
            if n == fromName then
                table.insert(db.profileOrder, i + 1, toName)
                found = true; break
            end
        end
        if not found then table.insert(db.profileOrder, toName) end
    end
    return true
end

-- =====================================
-- ASSIGNATION SPEC → PROFIL NOMMÉ
-- Architecture EllesmereUI : les specs pointent vers des noms de profils.
-- Modifier le profil nommé se reflète automatiquement sur la spec.
-- =====================================

--- Assigne une spécialisation à un profil nommé existant
function P.AssignSpecToProfile(specID, profileName)
    P.EnsureProfilesDB()
    local db = TomoModDB._profiles
    if not db.named[profileName] then return false end
    db.specProfiles[specID] = profileName
    return true
end

--- Désassigne une spécialisation
function P.UnassignSpec(specID)
    P.EnsureProfilesDB()
    TomoModDB._profiles.specProfiles[specID] = nil
end

--- Retourne le nom du profil assigné à une spec (ou nil)
function P.GetSpecAssignedProfile(specID)
    P.EnsureProfilesDB()
    return TomoModDB._profiles.specProfiles[specID]
end

--- true si les profils par spec sont actifs (au moins une assignation)
function P.IsSpecProfilesEnabled()
    P.EnsureProfilesDB()
    for _ in pairs(TomoModDB._profiles.specProfiles) do return true end
    return false
end

--- Active les profils spec : assigne la spec courante au profil actif
function P.EnableSpecProfiles()
    P.EnsureProfilesDB()
    local specID = P.GetCurrentSpecID()
    local active = P.GetActiveProfileName()
    if specID > 0 then
        P.AssignSpecToProfile(specID, active)
    end
end

--- Désactive : efface toutes les assignations
function P.DisableSpecProfiles()
    P.EnsureProfilesDB()
    TomoModDB._profiles.specProfiles = {}
end

-- =====================================
-- SPEC CHANGE HANDLER
-- =====================================

function P.OnSpecChanged(newSpecID)
    P.EnsureProfilesDB()
    if not P.IsSpecProfilesEnabled() then return false end
    if not newSpecID or newSpecID == 0 then return false end

    local targetName = P.GetSpecAssignedProfile(newSpecID)
    if not targetName then return false end

    local currentName = P.GetActiveProfileName()
    if currentName == targetName then return false end

    -- Sauvegarder le profil courant avant de switcher (pattern EllesmereUI)
    P.AutoSaveActiveProfile()

    -- [PERF] Load directly without the redundant auto-save inside LoadNamedProfile
    local db = TomoModDB._profiles
    local snap = db.named[targetName]
    if snap then
        ApplySnapshot(snap)
        db.activeProfile = targetName
        P._lastSpecID = newSpecID
        return true  -- reload recommandé
    end
    return false
end

function P.InitSpecTracking()
    P._lastSpecID = P.GetCurrentSpecID()
end

-- =====================================
-- IMPORT / EXPORT
-- =====================================

function P.Export()
    local LibSerialize = LibStub and LibStub("LibSerialize", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate",   true)
    if not LibSerialize or not LibDeflate then
        return nil, "Librairies manquantes (LibSerialize / LibDeflate)"
    end

    -- Auto-save avant export pour inclure les derniers changements
    P.AutoSaveActiveProfile()

    local payload = {
        _header  = EXPORT_HEADER,
        _version = EXPORT_VERSION,
        _class   = select(2, UnitClass("player")),
        _spec    = P.GetCurrentSpecID(),
        _date    = date("%Y-%m-%d %H:%M"),
        settings = SnapshotSettings(),
    }

    local serialized = LibSerialize:Serialize(payload)
    if not serialized then return nil, "Sérialisation échouée" end

    local compressed = LibDeflate:CompressDeflate(serialized, { level = 9 })
    if not compressed then return nil, "Compression échouée" end

    local encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then return nil, "Encodage échoué" end

    return encoded
end

function P.Import(str)
    local LibSerialize = LibStub and LibStub("LibSerialize", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate",   true)
    if not LibSerialize or not LibDeflate then
        return false, "Librairies manquantes (LibSerialize / LibDeflate)"
    end
    if not str or str == "" then return false, "Chaîne vide" end

    str = str:gsub("%s+", "")

    local decoded = LibDeflate:DecodeForPrint(str)
    if not decoded then return false, "Décodage échoué" end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return false, "Décompression échouée" end

    -- LibSerialize:DeSerialize retourne directement la valeur (pas bool+data)
    local pcallOk, payload = pcall(function()
        return LibSerialize:DeSerialize(decompressed)
    end)
    if not pcallOk or type(payload) ~= "table" then
        return false, "Désérialisation échouée"
    end

    if payload._header ~= EXPORT_HEADER then
        return false, "Pas une chaîne TomoMod"
    end
    if type(payload._version) ~= "number" or payload._version > EXPORT_VERSION then
        return false, "Version incompatible (v" .. tostring(payload._version) .. ")"
    end
    if type(payload.settings) ~= "table" then
        return false, "Données manquantes"
    end

    -- Sanitize : ne garder que les clés connues dans les defaults
    local sanitized = {}
    for k in pairs(TomoMod_Defaults) do
        if payload.settings[k] ~= nil then
            sanitized[k] = DeepCopy(payload.settings[k])
        end
    end

    ApplySnapshot(sanitized)
    return true
end

--- Importe et sauvegarde sous un profil nommé (sans ReloadUI immédiat)
function P.ImportAsProfile(str, profileName)
    local ok, err = P.Import(str)
    if not ok then return false, err end

    -- Les paramètres sont déjà appliqués en mémoire ; sauvegarder sous le nouveau nom
    P.EnsureProfilesDB()
    local db = TomoModDB._profiles
    db.named[profileName] = SnapshotSettings()
    local found = false
    for _, n in ipairs(db.profileOrder) do
        if n == profileName then found = true; break end
    end
    if not found then table.insert(db.profileOrder, 2, profileName) end
    db.activeProfile = profileName
    return true
end

--- Prévisualisation sans appliquer (retourne les métadonnées)
function P.PreviewImport(str)
    local LibSerialize = LibStub and LibStub("LibSerialize", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate",   true)
    if not LibSerialize or not LibDeflate or not str or str == "" then return nil end

    str = str:gsub("%s+", "")
    local decoded = LibDeflate:DecodeForPrint(str)
    if not decoded then return nil end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil end

    -- LibSerialize:DeSerialize retourne directement la valeur (pas bool+data)
    local pcallOk, payload = pcall(function()
        return LibSerialize:DeSerialize(decompressed)
    end)
    if not pcallOk or type(payload) ~= "table" then return nil end
    if payload._header ~= EXPORT_HEADER then return nil end

    local moduleCount = 0
    if type(payload.settings) == "table" then
        for k in pairs(payload.settings) do
            if TomoMod_Defaults[k] then moduleCount = moduleCount + 1 end
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

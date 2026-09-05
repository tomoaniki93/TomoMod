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
-- Profiles.lua :
--   - specs mappés vers des profils nommés (pas des snapshots indépendants)
--   - auto-save du profil courant avant tout switch
--   - rename, duplicate
--   - profileOrder explicite
--
-- [PERF v2] Optimisations :
--   - Compression level 1 au lieu de 9 (5-10x plus rapide, ratio quasi identique)
--   - Élimination des DeepCopy redondants dans Export/Import
--   - Export/Import asynchrones via coroutines pour éviter les lag spikes
--   - PreviewImport avec cache pour éviter le re-décodage sur chaque frappe
--   - Strip whitespace optimisé
-- =====================================

TomoMod_Profiles = {}
local P = TomoMod_Profiles

local EXPORT_VERSION = 1
local EXPORT_HEADER  = "TMOD"

-- Keys that must never travel inside a profile snapshot. "_migrations" is
-- bookkeeping, not configuration: a profile saved before a migration would
-- otherwise restore an empty flag table and let that migration run a second
-- time, re-applying a change the player may have deliberately reverted.
local EXCLUDED_KEYS = { ["_profiles"] = true, ["_migrations"] = true, ["_auraTrackerRescue"] = true }

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

-- [Lot C] Config pages are cached, so anything that rewrites the DB or
-- the profile list has to drop them. Without this the panel kept showing
-- the old list after a rename / delete, which reads as "nothing happened".
local function RefreshConfigPanels()
    if TomoMod_Config and TomoMod_Config.InvalidatePanels then
        TomoMod_Config.InvalidatePanels()
    end
end

local function ApplySnapshot(snap)
    for k in pairs(TomoModDB) do
        if not EXCLUDED_KEYS[k] then TomoModDB[k] = nil end
    end
    for k, v in pairs(snap) do
        if not EXCLUDED_KEYS[k] then TomoModDB[k] = DeepCopy(v) end
    end
    TomoMod_MergeTables(TomoModDB, TomoMod_Defaults)
    -- A snapshot saved before an element was added to the AstralForge
    -- registry has no entry for it; refill from the registry defaults.
    if TomoMod_NormalizeAllElements then TomoMod_NormalizeAllElements() end
    RefreshConfigPanels()
end

-- [PERF] Apply sans DeepCopy — utilisé quand on sait que snap ne sera plus référencé
-- (par ex. après désérialisation, le payload est jeté)
local function ApplySnapshotNoCopy(snap)
    for k in pairs(TomoModDB) do
        if not EXCLUDED_KEYS[k] then TomoModDB[k] = nil end
    end
    for k, v in pairs(snap) do
        if not EXCLUDED_KEYS[k] then TomoModDB[k] = v end
    end
    TomoMod_MergeTables(TomoModDB, TomoMod_Defaults)
    -- A snapshot saved before an element was added to the AstralForge
    -- registry has no entry for it; refill from the registry defaults.
    if TomoMod_NormalizeAllElements then TomoMod_NormalizeAllElements() end
    RefreshConfigPanels()
end

-- =====================================
-- DB INIT
-- =====================================

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
    if db.specs then
        db.specs = nil
    end

    -- Nettoyage : supprimer les profils "Spec-NNN" créés par une ancienne
    -- version de la migration
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
            for i = #db.profileOrder, 1, -1 do
                if db.profileOrder[i] == name then
                    table.remove(db.profileOrder, i)
                end
            end
            for specID, pName in pairs(db.specProfiles) do
                if pName == name then db.specProfiles[specID] = nil end
            end
        end
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

    -- Synchronisation : tout profil présent dans named doit être dans profileOrder
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
    local found = false
    for _, n in ipairs(db.profileOrder) do
        if n == name then found = true; break end
    end
    if not found then
        table.insert(db.profileOrder, 2, name)
    end
    db.activeProfile = name
    RefreshConfigPanels()
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

-- =====================================
-- CONTEXT SWAP (v4 lot 4)
-- =====================================
-- Comme LoadNamedProfile, à une réserve près : les modules que le
-- registre marque contextSwap = false ne suivent pas le contenu. Ce sont
-- des outils, pas de la mise en page — diagnostics, détection d'addons,
-- les studios. Quelqu'un qui ouvre un studio en raid ne doit pas le
-- retrouver fermé après être entré en clé.
--
-- L'épinglage ne s'applique QUE ici. Un chargement manuel de profil doit
-- tout remplacer, c'est ce que le joueur demande en cliquant.
function P.ApplyForContext(name)
    P.EnsureProfilesDB()
    local db = TomoModDB._profiles
    local snap = db.named[name]
    if not snap then return false end

    P.AutoSaveActiveProfile()

    local R = TomoMod_Registry
    local pinned = {}
    if R and R.ContextPinned then
        for _, key in ipairs(R.ContextPinned()) do
            local m = R.Get(key)
            local dbKey = m and m.dbKey
            if dbKey and TomoModDB[dbKey] ~= nil then
                pinned[dbKey] = DeepCopy(TomoModDB[dbKey])
            end
        end
    end

    ApplySnapshot(snap)

    for dbKey, value in pairs(pinned) do
        TomoModDB[dbKey] = value
    end

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
    for specID, pName in pairs(db.specProfiles) do
        if pName == name then db.specProfiles[specID] = nil end
    end
    if db.activeProfile == name then
        db.activeProfile = "Default"
    end
    RefreshConfigPanels()
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
    RefreshConfigPanels()
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
        for i, n in ipairs(db.profileOrder) do
            if n == fromName then
                table.insert(db.profileOrder, i + 1, toName)
                found = true; break
            end
        end
        if not found then table.insert(db.profileOrder, toName) end
    end
    RefreshConfigPanels()
    return true
end

-- =====================================
-- ASSIGNATION SPEC → PROFIL NOMMÉ
-- =====================================

function P.AssignSpecToProfile(specID, profileName)
    P.EnsureProfilesDB()
    local db = TomoModDB._profiles
    if not db.named[profileName] then return false end
    db.specProfiles[specID] = profileName
    return true
end

function P.UnassignSpec(specID)
    P.EnsureProfilesDB()
    TomoModDB._profiles.specProfiles[specID] = nil
end

function P.GetSpecAssignedProfile(specID)
    P.EnsureProfilesDB()
    return TomoModDB._profiles.specProfiles[specID]
end

function P.IsSpecProfilesEnabled()
    P.EnsureProfilesDB()
    for _ in pairs(TomoModDB._profiles.specProfiles) do return true end
    return false
end

function P.EnableSpecProfiles()
    P.EnsureProfilesDB()
    local specID = P.GetCurrentSpecID()
    local active = P.GetActiveProfileName()
    if specID > 0 then
        P.AssignSpecToProfile(specID, active)
    end
end

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

    P.AutoSaveActiveProfile()

    local db = TomoModDB._profiles
    local snap = db.named[targetName]
    if snap then
        ApplySnapshot(snap)
        db.activeProfile = targetName
        P._lastSpecID = newSpecID
        return true
    end
    return false
end

function P.InitSpecTracking()
    P._lastSpecID = P.GetCurrentSpecID()
end

-- =====================================
-- IMPORT / EXPORT
-- =====================================
-- [PERF v2] Optimisations principales :
--   1. Compression level 1 (vs 9) → 5-10x plus rapide, taille ~5-15% plus grande
--   2. Export : un seul SnapshotSettings() au lieu de AutoSave + Snapshot
--   3. Import : ApplySnapshotNoCopy évite un DeepCopy inutile (payload jetable)
--   4. ImportAsProfile : pas de re-snapshot, on réutilise la copie sanitizée
--   5. ExportAsync / ImportAsync : coroutines pour feedback UI sans freeze
-- =====================================

--- Export synchrone (rapide maintenant grâce à level 1)
function P.Export()
    local LibSerialize = LibStub and LibStub("TomoSerialize-1.0", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate",   true)
    if not LibSerialize or not LibDeflate then
        return nil, "Librairies manquantes (LibSerialize / LibDeflate)"
    end

    -- Un seul snapshot : on auto-save ET on l'utilise pour l'export
    P.EnsureProfilesDB()
    local snap = SnapshotSettings()
    local name = TomoModDB._profiles.activeProfile or "Default"
    TomoModDB._profiles.named[name] = snap

    local payload = {
        _header  = EXPORT_HEADER,
        _version = EXPORT_VERSION,
        _class   = select(2, UnitClass("player")),
        _spec    = P.GetCurrentSpecID(),
        _date    = date("%Y-%m-%d %H:%M"),
        settings = snap,  -- réutilise le même snapshot, pas de 2e DeepCopy
    }

    local serialized = LibSerialize:Serialize(payload)
    if not serialized then return nil, "Sérialisation échouée" end

    -- [PERF] level 1 au lieu de 9 : compression ~5-10x plus rapide
    local compressed = LibDeflate:CompressDeflate(serialized, { level = 1 })
    if not compressed then return nil, "Compression échouée" end

    local encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then return nil, "Encodage échoué" end

    return encoded
end

--- Export asynchrone via coroutine — appelle callback(encoded, err) à la fin
--- Utilise C_Timer.After(0) entre les étapes pour répartir le travail
function P.ExportAsync(callback)
    local LibSerialize = LibStub and LibStub("TomoSerialize-1.0", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate",   true)
    if not LibSerialize or not LibDeflate then
        callback(nil, "Librairies manquantes (LibSerialize / LibDeflate)")
        return
    end

    -- Étape 1 : snapshot (peut être lourd sur une grosse DB)
    P.EnsureProfilesDB()
    local snap = SnapshotSettings()
    local name = TomoModDB._profiles.activeProfile or "Default"
    TomoModDB._profiles.named[name] = snap

    local payload = {
        _header  = EXPORT_HEADER,
        _version = EXPORT_VERSION,
        _class   = select(2, UnitClass("player")),
        _spec    = P.GetCurrentSpecID(),
        _date    = date("%Y-%m-%d %H:%M"),
        settings = snap,
    }

    -- Étape 2 : sérialisation (frame suivant)
    C_Timer.After(0, function()
        local ok1, serialized = pcall(LibSerialize.Serialize, LibSerialize, payload)
        if not ok1 or not serialized then
            callback(nil, "Sérialisation échouée")
            return
        end

        -- Étape 3 : compression (frame suivant)
        C_Timer.After(0, function()
            local ok2, compressed = pcall(LibDeflate.CompressDeflate, LibDeflate, serialized, { level = 1 })
            if not ok2 or not compressed then
                callback(nil, "Compression échouée")
                return
            end

            -- Étape 4 : encodage (frame suivant)
            C_Timer.After(0, function()
                local ok3, encoded = pcall(LibDeflate.EncodeForPrint, LibDeflate, compressed)
                if not ok3 or not encoded then
                    callback(nil, "Encodage échoué")
                    return
                end
                callback(encoded, nil)
            end)
        end)
    end)
end

--- Import synchrone (optimisé)
function P.Import(str)
    local LibSerialize = LibStub and LibStub("TomoSerialize-1.0", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate",   true)
    if not LibSerialize or not LibDeflate then
        return false, "Librairies manquantes (LibSerialize / LibDeflate)"
    end
    if not str or str == "" then return false, "Chaîne vide" end

    -- [PERF] Trim rapide : on n'a besoin de virer que les espaces/newlines
    -- gsub("%s+", "") est O(n) mais crée une nouvelle string ; pour les très
    -- longues chaînes on utilise un match qui coupe les bords
    str = str:match("^%s*(.-)%s*$") or str

    local decoded = LibDeflate:DecodeForPrint(str)
    if not decoded then return false, "Décodage échoué" end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return false, "Décompression échouée" end

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

    -- [PERF] Sanitize in-place : on extrait les clés connues directement
    -- depuis payload.settings (qu'on va jeter), pas besoin de DeepCopy
    local sanitized = {}
    for k in pairs(TomoMod_Defaults) do
        if payload.settings[k] ~= nil then
            sanitized[k] = payload.settings[k]  -- move, pas copy
        end
    end
    payload.settings = nil  -- libérer la référence

    -- [PERF] ApplySnapshotNoCopy : sanitized n'est référencé nulle part ailleurs
    ApplySnapshotNoCopy(sanitized)
    return true
end

-- Validation + sanitize + apply, shared by the decode path and by the
-- fast path that reuses the payload already decoded for the preview.
local function FinishImport(payload, callback)
    if payload._header ~= EXPORT_HEADER then
        callback(false, "Pas une chaine TomoMod"); return
    end
    if type(payload._version) ~= "number" or payload._version > EXPORT_VERSION then
        callback(false, "Version incompatible (v" .. tostring(payload._version) .. ")"); return
    end
    if type(payload.settings) ~= "table" then
        callback(false, "Donnees manquantes"); return
    end

    local sanitized = {}
    for k in pairs(TomoMod_Defaults) do
        if payload.settings[k] ~= nil then
            sanitized[k] = payload.settings[k]
        end
    end
    payload.settings = nil

    ApplySnapshotNoCopy(sanitized)
    callback(true, nil)
end

--- Import asynchrone — callback(ok, err) à la fin
function P.ImportAsync(str, callback)
    local LibSerialize = LibStub and LibStub("TomoSerialize-1.0", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate",   true)
    if not LibSerialize or not LibDeflate then
        callback(false, "Librairies manquantes (LibSerialize / LibDeflate)")
        return
    end
    if not str or str == "" then callback(false, "Chaîne vide"); return end

    str = str:match("^%s*(.-)%s*$") or str

    -- [PERF] The import popup already decoded this exact string to build
    -- its preview. Reusing that payload removes a full second
    -- decode + decompress + deserialize on accept, which was most of the
    -- freeze players saw when clicking Import.
    local reused = P.TakeDecodedPayload(str)
    if reused then
        C_Timer.After(0, function() FinishImport(reused, callback) end)
        return
    end

    -- Étape 1 : décodage
    C_Timer.After(0, function()
        local decoded = LibDeflate:DecodeForPrint(str)
        if not decoded then callback(false, "Décodage échoué"); return end

        -- Étape 2 : décompression
        C_Timer.After(0, function()
            local decompressed = LibDeflate:DecompressDeflate(decoded)
            if not decompressed then callback(false, "Décompression échouée"); return end

            -- Étape 3 : désérialisation + application
            C_Timer.After(0, function()
                local pcallOk, payload = pcall(function()
                    return LibSerialize:DeSerialize(decompressed)
                end)
                if not pcallOk or type(payload) ~= "table" then
                    callback(false, "Désérialisation échouée"); return
                end
                FinishImport(payload, callback)
            end)
        end)
    end)
end

--- Importe et sauvegarde sous un profil nommé (sans ReloadUI immédiat)
--- Sauvegarde la configuration active sous `profileName` et l'active.
---
--- Le bloc snapshot + insertion dans profileOrder + bascule d'activeProfile
--- etait recopie dans ImportAsProfile et ImportAsProfileAsync. L'import
--- selectif en aurait fait une troisieme copie : les trois chemins
--- appliquent d'abord en memoire, puis figent le resultat sous un nom.
---
--- Insere en position 2 comme les copies d'origine : l'index 1 est le profil
--- par defaut, qui reste en tete de liste.
function P.SaveActiveAs(profileName)
    if type(profileName) ~= "string" then return false, "Empty name" end
    profileName = profileName:match("^%s*(.-)%s*$")
    if profileName == "" then return false, "Empty name" end

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

function P.ImportAsProfile(str, profileName)
    local ok, err = P.Import(str)
    if not ok then return false, err end

    -- [PERF] Les paramètres sont déjà appliqués en mémoire par Import()
    -- On snapshot une fois pour sauvegarder sous le nouveau nom
    return P.SaveActiveAs(profileName)
end

--- Import asynchrone comme profil nommé — callback(ok, err)
function P.ImportAsProfileAsync(str, profileName, callback)
    P.ImportAsync(str, function(ok, err)
        if not ok then callback(false, err); return end

        -- [PERF] SnapshotSettings deep-copies the whole settings tree.
        -- Yield one frame first so the client can draw the applied import
        -- instead of stacking both costs into the same frame.
        C_Timer.After(0, function()
            P.SaveActiveAs(profileName)
            callback(true, nil)
        end)
    end)
end

--- Prévisualisation sans appliquer (retourne les métadonnées)
--- [PERF] Cache interne pour éviter de re-décoder la même chaîne
local _previewCache = { str = nil, result = nil, payload = nil }

-- =====================================
-- DECODE (partagé)
-- =====================================
-- La séquence décode / décompresse / désérialise / valide l'en-tête était
-- recopiée dans Import, PreviewImport et ImportAsProfile. L'import
-- sélectif du lot 6 en aurait fait une quatrième copie, et les messages
-- d'erreur avaient déjà commencé à diverger entre les trois.
--
-- Ne consomme pas le cache d'aperçu : l'appelant peut inspecter la charge
-- utile puis l'appliquer sans repayer la désérialisation.
function P.DecodeImport(str)
    local LibSerialize = LibStub and LibStub("TomoSerialize-1.0", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate", true)
    if not LibSerialize or not LibDeflate then
        return nil, "Librairies manquantes (LibSerialize / LibDeflate)"
    end
    if type(str) ~= "string" or str == "" then return nil, "Chaîne vide" end

    str = str:match("^%s*(.-)%s*$") or str

    local decoded = LibDeflate:DecodeForPrint(str)
    if not decoded then return nil, "Décodage échoué" end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil, "Décompression échouée" end

    local okCall, payload = pcall(function()
        return LibSerialize:DeSerialize(decompressed)
    end)
    if not okCall or type(payload) ~= "table" then
        return nil, "Désérialisation échouée"
    end
    if payload._header ~= EXPORT_HEADER then
        return nil, "Pas une chaîne TomoMod"
    end
    if type(payload._version) ~= "number" or payload._version > EXPORT_VERSION then
        return nil, "Version incompatible (v" .. tostring(payload._version) .. ")"
    end
    if type(payload.settings) ~= "table" then
        return nil, "Données manquantes"
    end
    return payload
end

function P.PreviewImport(str)
    local LibSerialize = LibStub and LibStub("TomoSerialize-1.0", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate",   true)
    if not LibSerialize or not LibDeflate or not str or str == "" then return nil end

    -- [PERF] Cache : si la chaîne n'a pas changé, retourner le résultat précédent
    str = str:match("^%s*(.-)%s*$") or str
    if _previewCache.str == str then return _previewCache.result end

    -- Cache miss: the payload kept for the accept-time fast path is stale.
    _previewCache.payload = nil

    local decoded = LibDeflate:DecodeForPrint(str)
    if not decoded then
        _previewCache.str = str; _previewCache.result = nil
        return nil
    end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        _previewCache.str = str; _previewCache.result = nil
        return nil
    end

    local pcallOk, payload = pcall(function()
        return LibSerialize:DeSerialize(decompressed)
    end)
    if not pcallOk or type(payload) ~= "table" then
        _previewCache.str = str; _previewCache.result = nil
        return nil
    end
    if payload._header ~= EXPORT_HEADER then
        _previewCache.str = str; _previewCache.result = nil
        return nil
    end

    local moduleCount = 0
    if type(payload.settings) == "table" then
        for k in pairs(payload.settings) do
            if TomoMod_Defaults[k] then moduleCount = moduleCount + 1 end
        end
    end

    local result = {
        version     = payload._version,
        class       = payload._class,
        spec        = payload._spec,
        date        = payload._date,
        moduleCount = moduleCount,
    }

    _previewCache.str = str
    _previewCache.result = result
    _previewCache.payload = payload
    return result
end

--- Hands over the payload decoded by the last PreviewImport for `str`,
--- or nil. Single use: FinishImport moves `settings` out of it, so the
--- payload must never be served twice.
function P.TakeDecodedPayload(str)
    if type(str) ~= "string" then return nil end
    str = str:match("^%s*(.-)%s*$") or str
    if _previewCache.str ~= str then return nil end
    local payload = _previewCache.payload
    _previewCache.payload = nil
    if type(payload) ~= "table" or type(payload.settings) ~= "table" then return nil end
    return payload
end

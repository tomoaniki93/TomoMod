-- Local reliability patch: bounded, data-only imports and recoverable settings.
-- Existing share strings keep their format. No imported code is compiled.
TomoMod_ProfileSafety = {}
local S = TomoMod_ProfileSafety

S.MAX_ENCODED = 1024 * 1024
S.MAX_DECODED = 4 * 1024 * 1024
S.MAX_DEPTH = 24
S.MAX_NODES = 150000
S.MAX_BACKUPS = 5
S.EXCLUDED = { _profiles = true, _profileBackups = true, _migrations = true,
    _auraTrackerRescue = true, _floatingCombatTextBackup = true,
    _profileSafetyMigrationBackup = true }

local POINTS = { TOPLEFT=true, TOP=true, TOPRIGHT=true, LEFT=true, CENTER=true,
    RIGHT=true, BOTTOMLEFT=true, BOTTOM=true, BOTTOMRIGHT=true }
local NUMERIC_FIELDS = { fontsize=true, scale=true, alpha=true, opacity=true,
    width=true, height=true, size=true, x=true, y=true }
local POINT_FIELDS = { point=true, relpoint=true, relativepoint=true, corner=true }
local function Finite(n) return n == n and n ~= math.huge and n ~= -math.huge end
S.Finite = Finite

-- Bound the entire walk, including repeated references. An active-path set
-- rejects cycles while allowing legitimate references shared by siblings.
function S.Copy(value)
    local nodes, bytes, active = 0, 0, {}
    local function Visit(v, depth)
        nodes = nodes + 1
        if nodes > S.MAX_NODES or depth > S.MAX_DEPTH then error("Données trop complexes", 0) end
        local kind = type(v)
        if kind == "number" then
            if not Finite(v) then error("Nombre non fini", 0) end
        elseif kind == "string" then
            bytes = bytes + #v
            if #v > 524288 or bytes > S.MAX_DECODED then error("Données trop volumineuses", 0) end
        elseif kind == "table" then
            if active[v] then error("Référence circulaire", 0) end
            if getmetatable(v) then error("Métatable interdite", 0) end
            active[v] = true
            local out = {}
            for k, x in pairs(v) do
                if type(k) ~= "string" and type(k) ~= "number" then error("Clé invalide", 0) end
                Visit(k, depth + 1)
                out[k] = Visit(x, depth + 1)
            end
            active[v] = nil
            return out
        elseif kind ~= "boolean" and kind ~= "nil" then
            error("Type interdit : " .. kind, 0)
        end
        return v
    end
    local ok, result = pcall(Visit, value, 0)
    if not ok then return nil, result end
    return result
end

function S.Decode(str, header, version, shortHeader)
    if type(str) ~= "string" or str == "" then return nil, "Chaîne vide" end
    if #str > S.MAX_ENCODED then return nil, "Chaîne trop volumineuse (1 Mio maximum)" end
    local def = LibStub and LibStub("LibDeflate", true)
    local ser = LibStub and LibStub("TomoSerialize-1.0", true)
    if not def or not ser or not TomoMod_InflateBounded then return nil, "Codec d'import indisponible" end
    str = str:match("^%s*(.-)%s*$")
    local ok, packed = pcall(def.DecodeForPrint, def, str)
    if not ok or not packed then return nil, "Décodage échoué" end
    local inflated, status
    ok, inflated, status = pcall(TomoMod_InflateBounded, packed, S.MAX_DECODED)
    if not ok or not inflated then
        return nil, status == -100 and "Profil décompressé trop volumineux" or "Décompression échouée"
    end
    if status ~= 0 then return nil, "Données supplementaires apres le profil" end
    -- TomoSerialize V5 uses '~' as a delimiter (escaped inside strings).
    -- Check depth BEFORE its recursive parser, and reject its function tag.
    if inflated:sub(1, 3) ~= "~V5" or inflated:sub(-2) ~= "~v" then
        return nil, "Format de sérialisation invalide"
    end
    local depth, count = 0, 0
    for tag in inflated:gmatch("~(.)") do
        count = count + 1
        if count > S.MAX_NODES * 2 then return nil, "Profil trop complexe" end
        if tag == "D" then return nil, "Fonctions interdites dans les profils" end
        if tag == "T" then depth = depth + 1 end
        if tag == "t" then depth = depth - 1 end
        if depth < 0 or depth > S.MAX_DEPTH then return nil, "Imbrication invalide" end
    end
    if depth ~= 0 then return nil, "Profil incomplet" end
    local payload
    ok, payload = pcall(ser.DeSerialize, ser, inflated)
    if not ok or type(payload) ~= "table" then return nil, "Désérialisation échouée" end
    local clean, err = S.Copy(payload)
    if not clean then return nil, err end
    local h, v = shortHeader and "_h" or "_header", shortHeader and "_v" or "_version"
    if clean[h] ~= header then return nil, "Format de partage incompatible" end
    if type(clean[v]) ~= "number" or clean[v] < 1 or clean[v] % 1 ~= 0 or clean[v] > version then
        return nil, "Version de profil incompatible"
    end
    for _, key in ipairs({ "_class", "_date" }) do
        local value = clean[key]
        if value ~= nil and (type(value) ~= "string" or #value > 256) then
            return nil, "Métadonnées de profil invalides"
        end
    end
    if clean._spec ~= nil and (type(clean._spec) ~= "number" or clean._spec < 0 or clean._spec > 1000000 or clean._spec % 1 ~= 0) then
        return nil, "Spécialisation invalide"
    end
    return clean
end

local function CheckValue(v, default, path, key)
    if default ~= nil and type(v) ~= type(default) then return path .. " : type invalide" end
    key = type(key) == "string" and key:lower() or ""
    if key == "enabled" and type(v) ~= "boolean" then return path .. " : booléen attendu" end
    -- Optional records/overrides have no entry in the defaults to compare to.
    if default == nil then
        if key == "position" and type(v) ~= "table" then return path .. " : position invalide" end
        if NUMERIC_FIELDS[key] and type(v) ~= "number" then return path .. " : nombre attendu" end
        if POINT_FIELDS[key] and type(v) ~= "string" then return path .. " : point invalide" end
    end
    if type(v) == "number" then
        local lo, hi
        if path == "bagSkin.scale" then lo, hi = 1, 2000 -- legacy percentage
        elseif path == "bagSkin.opacity" then lo, hi = 0, 100
        elseif key:find("fontsize", 1, true) then lo, hi = 4, 256
        elseif key == "scale" or key:match("scale$") then lo, hi = 0.01, 20
        elseif key:match("alpha$") or key:match("opacity$") then lo, hi = 0, 1
        elseif key == "width" or key == "height" or key == "size" then lo, hi = 0, 16384
        elseif key == "x" or key == "y" then lo, hi = -100000, 100000 end
        if lo and (v < lo or v > hi) then return path .. " : valeur hors limites" end
    elseif type(v) == "string" and (key == "point" or key == "relpoint"
        or key == "relativepoint" or key == "corner") and not POINTS[v] then
        return path .. " : point d'ancrage invalide"
    elseif type(v) == "table" then
        for k, x in pairs(v) do
            local d
            if type(default) == "table" then d = default[k] end
            -- Homogeneous arrays use their first record as the element schema.
            if d == nil and type(k) == "number" and type(default) == "table" then d = default[1] end
            local err = CheckValue(x, d, path .. "." .. tostring(k), k)
            if err then return err end
        end
    end
end

function S.IsPortable(key)
    if type(key) ~= "string" or key:sub(1, 1) == "_" or S.EXCLUDED[key] then return false end
    local r = TomoMod_Registry
    local m = r and r.Get(key)
    if m and m.internal then return false end
    return TomoMod_Defaults and TomoMod_Defaults[key] ~= nil
end

function S.ValidateSettings(settings, selected)
    if type(settings) ~= "table" then return nil, "Réglages manquants" end
    local clean, err = S.Copy(settings)
    if not clean then return nil, err end
    local out, count = {}, 0
    for key, value in pairs(clean) do
        if type(key) ~= "string" or #key > 128 then return nil, "Cle de module invalide" end
        if S.IsPortable(key) and (not selected or selected[key]) then
            err = CheckValue(value, TomoMod_Defaults[key], tostring(key), key)
            if err then return nil, err end
            out[key], count = value, count + 1
        end
    end
    if count == 0 then return nil, "Aucun module valide à importer" end
    return out
end

function S.ValidatePosition(pos)
    if type(pos) ~= "table" then return false, "position invalide" end
    if not POINTS[pos.point or pos.anchor] then return false, "point invalide" end
    if pos.anchor and not POINTS[pos.anchor] then return false, "ancre invalide" end
    for _, key in ipairs({ "relativePoint", "relPoint" }) do
        if pos[key] ~= nil and not POINTS[pos[key]] then return false, "point relatif invalide" end
    end
    for _, key in ipairs({ "x", "y" }) do
        local n = pos[key]
        if type(n) ~= "number" or not Finite(n) or math.abs(n) > 100000 then return false, "coordonnée invalide" end
    end
    for _, key in ipairs({ "refW", "refH" }) do
        local n = pos[key]
        if n ~= nil and (type(n) ~= "number" or not Finite(n) or n <= 0 or n > 100000) then
            return false, "résolution de référence invalide"
        end
    end
    return true
end

local function SettingsSnapshot()
    local out = {}
    for key, value in pairs(TomoModDB or {}) do if not S.EXCLUDED[key] then out[key] = value end end
    return S.Copy(out)
end
S.Snapshot = SettingsSnapshot

function S.CreateBackup(reason, includeProfiles)
    if not TomoModDB then return nil, "Base indisponible" end
    local settings, err = SettingsSnapshot()
    if not settings then return nil, err end
    local profiles
    if includeProfiles and TomoModDB._profiles then
        profiles, err = S.Copy(TomoModDB._profiles)
        if not profiles then return nil, err end
    end
    local ring = TomoModDB._profileBackups
    if type(ring) ~= "table" then ring = {}; TomoModDB._profileBackups = ring end
    local entry = { settings = settings, profiles = profiles, reason = tostring(reason or "manual"),
        time = date and date("%Y-%m-%d %H:%M:%S") or "",
        profile = TomoModDB._profiles and TomoModDB._profiles.activeProfile or "Default" }
    table.insert(ring, 1, entry)
    while #ring > S.MAX_BACKUPS do table.remove(ring) end
    return entry
end

function S.ListBackups()
    local rows = {}
    for i, entry in ipairs(TomoModDB and TomoModDB._profileBackups or {}) do
        rows[#rows + 1] = { id = i, time = entry.time, reason = entry.reason, profile = entry.profile }
    end
    return rows
end

-- Validation belongs before this call. Roll back data on an application error;
-- keep the recovery snapshot even on failure. Never replace the global DB table.
function S.Transaction(reason, apply, includeProfiles)
    if InCombatLockdown and InCombatLockdown() then return false, "Disponible hors combat uniquement" end
    local backup, err = S.CreateBackup(reason, includeProfiles)
    if not backup then return false, err end
    local profiles
    if TomoModDB._profiles then
        profiles, err = S.Copy(TomoModDB._profiles)
        if not profiles then return false, err end
    end
    local ok, result = pcall(apply)
    if ok then return true, result end
    for key in pairs(TomoModDB) do if not S.EXCLUDED[key] then TomoModDB[key] = nil end end
    for key, value in pairs(backup.settings) do TomoModDB[key] = value end
    -- Keep the persistent snapshot independent of the restored live tables.
    backup.settings = assert(S.Copy(backup.settings))
    TomoModDB._profiles = profiles
    return false, "Application annulée : " .. tostring(result)
end

function S.RestoreBackup(id)
    local entry = (TomoModDB and TomoModDB._profileBackups or {})[tonumber(id) or 1]
    if not entry then return false, "Sauvegarde introuvable" end
    local settings, err = S.Copy(entry.settings)
    if not settings then return false, err end
    local profiles
    if entry.profiles then
        profiles, err = S.Copy(entry.profiles)
        if not profiles then return false, err end
    end
    return S.Transaction("avant restauration", function()
        for key in pairs(TomoModDB) do if not S.EXCLUDED[key] then TomoModDB[key] = nil end end
        for key, value in pairs(settings) do TomoModDB[key] = value end
        if profiles then TomoModDB._profiles = profiles end
        TomoMod_MergeTables(TomoModDB, TomoMod_Defaults)
        if TomoMod_NormalizeAllElements then TomoMod_NormalizeAllElements() end
        local p = TomoModDB._profiles
        if p and p.named and p.named[entry.profile] then p.activeProfile = entry.profile end
        if TomoMod_Profiles then TomoMod_Profiles.AutoSaveActiveProfile() end
    end, true)
end

function S.ConfirmRestore(id)
    if InCombatLockdown and InCombatLockdown() then
        print("|cffff8800TomoMod|r : restauration disponible hors combat."); return
    end
    local entry = (TomoModDB and TomoModDB._profileBackups or {})[tonumber(id) or 1]
    if not entry then print("TomoMod : aucune sauvegarde."); return end
    StaticPopupDialogs.TOMOMOD_BACKUP_RESTORE = {
        text = "Restaurer cette sauvegarde TomoMod ?\n%s\nL'interface sera rechargée.",
        button1 = ACCEPT or "Restaurer", button2 = CANCEL or "Annuler", timeout = 0,
        whileDead = true, hideOnEscape = true,
        OnAccept = function(_, data)
            -- Resolve the same entry, even if another backup was added meanwhile.
            local found
            for i, v in ipairs(TomoModDB._profileBackups or {}) do if v == data then found = i; break end end
            local ok, why = false, "Sauvegarde introuvable"
            if found then ok, why = S.RestoreBackup(found) end
            if ok then ReloadUI() else print("TomoMod : " .. tostring(why)) end
        end,
    }
    StaticPopup_Show("TOMOMOD_BACKUP_RESTORE", (entry.time or "") .. " - " .. entry.reason, nil, entry)
end

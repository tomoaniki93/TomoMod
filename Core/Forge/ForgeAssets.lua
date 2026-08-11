-- =====================================================================
-- TomoMod Forge -- Assets (L2)
-- Named layouts for any registry domain, plus share strings.
--
-- An "asset" is a snapshot of one element store: every anchor record, its
-- visual properties, and any instanced elements it contains. Saving and
-- applying are domain-agnostic -- the registry already knows what a valid
-- store looks like, so this file never needs to learn what a unit frame or
-- a nameplate is.
--
-- Everything that comes back in (apply, import) goes through Ensure, which
-- sanitises each record and breaks anchor cycles. That is what makes it
-- safe to accept a string a stranger pasted into chat: the worst a hostile
-- payload can do is describe a layout, and any field the registry does not
-- recognise is dropped on the way in.
-- =====================================================================

local Forge = TomoMod_Forge
if not Forge or not Forge.Registry then return end

Forge.Assets = Forge.Assets or {}
local A = Forge.Assets
local R = Forge.Registry

local type, pairs, ipairs, tostring = type, pairs, ipairs, tostring
local tsort = table.sort

A.HEADER  = "TOMOAF"
A.VERSION = 1
A.MAX_NAME = 40

local codec
local function getCodec()
    if not codec and Forge.IO then
        codec = Forge.IO.MakeCodec(A.HEADER, A.VERSION, "AstralForge")
    end
    return codec
end

-- ---------------------------------------------------------------------
-- Storage
-- ---------------------------------------------------------------------
local function root(create)
    if not TomoModDB then return nil end
    local r = TomoModDB.forgeAssets
    if type(r) ~= "table" then
        if not create then return nil end
        r = {}
        TomoModDB.forgeAssets = r
    end
    return r
end

local function bucket(domainName, create)
    local r = root(create)
    if not r then return nil end
    local b = r[domainName]
    if type(b) ~= "table" then
        if not create then return nil end
        b = {}
        r[domainName] = b
    end
    return b
end

-- Deep copy restricted to what an element store may contain: nested tables
-- of scalars, one level of records. Anything else is dropped rather than
-- carried, so a doctored payload cannot smuggle functions or cycles in.
local function copyStore(store)
    if type(store) ~= "table" then return nil end
    local out = {}
    for key, rec in pairs(store) do
        if type(key) == "string" and type(rec) == "table" then
            local r = {}
            for k, v in pairs(rec) do
                local tv = type(v)
                if type(k) == "string" and (tv == "string" or tv == "number" or tv == "boolean") then
                    r[k] = v
                end
            end
            out[key] = r
        end
    end
    return out
end

function A.SanitizeName(name)
    if type(name) ~= "string" then return nil end
    name = name:match("^%s*(.-)%s*$") or ""
    if name == "" then return nil end
    if #name > A.MAX_NAME then name = name:sub(1, A.MAX_NAME) end
    return name
end

-- ---------------------------------------------------------------------
-- CRUD
-- ---------------------------------------------------------------------

-- Names present for a domain, sorted so the GUI order never jitters.
function A.List(domainName)
    local b = bucket(domainName)
    local out = {}
    if not b then return out end
    for name in pairs(b) do out[#out + 1] = name end
    tsort(out)
    return out
end

function A.Exists(domainName, name)
    local b = bucket(domainName)
    name = A.SanitizeName(name)
    return (b ~= nil and name ~= nil and b[name] ~= nil)
end

-- Overwrites silently when the name already exists: the GUI asks first.
function A.Save(domainName, name, store)
    name = A.SanitizeName(name)
    if not name then return false, "Nom invalide" end
    local snapshot = copyStore(store)
    if not snapshot then return false, "Donnees invalides" end
    local b = bucket(domainName, true)
    if not b then return false, "Stockage indisponible" end
    b[name] = snapshot
    return true
end

function A.Delete(domainName, name)
    local b = bucket(domainName)
    name = A.SanitizeName(name)
    if not (b and name and b[name]) then return false end
    b[name] = nil
    return true
end

function A.Rename(domainName, oldName, newName)
    local b = bucket(domainName)
    oldName, newName = A.SanitizeName(oldName), A.SanitizeName(newName)
    if not (b and oldName and newName and b[oldName]) then return false end
    if b[newName] then return false, "Nom deja utilise" end
    b[newName], b[oldName] = b[oldName], nil
    return true
end

-- Writes a saved layout into `store` IN PLACE, because the caller's frames
-- already hold a reference to it. Singletons are overwritten, instances are
-- replaced wholesale (an asset describes the complete set), and Ensure has
-- the last word on validity.
function A.Apply(domainName, name, store)
    local b = bucket(domainName)
    name = A.SanitizeName(name)
    local snapshot = b and name and b[name]
    if not snapshot then return false, "Preset introuvable" end
    if type(store) ~= "table" then return false, "Donnees invalides" end

    for key in pairs(store) do
        if R.SplitKey(key) then store[key] = nil end
    end
    for key, rec in pairs(snapshot) do
        local copy = {}
        for k, v in pairs(rec) do copy[k] = v end
        store[key] = copy
    end

    R.Ensure(domainName, store)
    return true
end

-- ---------------------------------------------------------------------
-- Share strings
-- ---------------------------------------------------------------------
function A.Export(domainName, name)
    local c = getCodec()
    if not c then return nil, "Librairies manquantes (LibSerialize / LibDeflate)" end
    local b = bucket(domainName)
    name = A.SanitizeName(name)
    local snapshot = b and name and b[name]
    if not snapshot then return nil, "Preset introuvable" end

    return c.Encode({
        domain = domainName,
        name   = name,
        layout = snapshot,
    })
end

-- Exports whatever is currently applied, without saving it first.
function A.ExportStore(domainName, name, store)
    local c = getCodec()
    if not c then return nil, "Librairies manquantes (LibSerialize / LibDeflate)" end
    local snapshot = copyStore(store)
    if not snapshot then return nil, "Donnees invalides" end
    return c.Encode({
        domain = domainName,
        name   = A.SanitizeName(name) or "Import",
        layout = snapshot,
    })
end

-- Decodes and SAVES under the payload's name (suffixed when taken).
-- Returns the stored name, or nil + reason.
--
-- `expectDomain` is checked rather than trusted: a nameplate layout applied
-- to a unit frame store would resolve to nothing and silently blank the
-- frame, which reads as a bug rather than as a mistake.
function A.Import(str, expectDomain)
    local c = getCodec()
    if not c then return nil, "Librairies manquantes (LibSerialize / LibDeflate)" end

    local payload, err = c.Decode(str)
    if not payload then return nil, err end
    if type(payload.layout) ~= "table" then return nil, "Donnees manquantes" end
    if expectDomain and payload.domain ~= expectDomain then
        return nil, "Ce preset ne concerne pas ce type de cadre"
    end

    local domainName = payload.domain
    if type(domainName) ~= "string" then return nil, "Donnees manquantes" end

    local snapshot = copyStore(payload.layout)
    if not snapshot then return nil, "Donnees invalides" end

    local name = A.SanitizeName(payload.name) or "Import"
    local b = bucket(domainName, true)
    if not b then return nil, "Stockage indisponible" end

    if b[name] then
        local i = 2
        while b[name .. " (" .. i .. ")"] and i < 100 do i = i + 1 end
        name = name .. " (" .. i .. ")"
    end

    b[name] = snapshot
    return name, domainName
end

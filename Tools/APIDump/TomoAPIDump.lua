-- =====================================================================
-- Tools/APIDump/TomoAPIDump.lua
--
-- Since Midnight, the client ships the answer to the question that has
-- cost this addon the most crash reports: which API can hand back a
-- secret value. APIDocumentation carries it per function and per
-- structure field -- SecretReturnsForAspect, ConditionalSecret, and the
-- rest. It is simply never written down anywhere a build script can
-- read it.
--
-- This addon writes it down. It walks the documentation once, keeps
-- only the entries that say something about secrecy or forbidden
-- aspects, and drops them into SavedVariables as plain sorted lines.
-- Tools/apidoc_import.py turns that file into Tools/apidoc_secrets.txt,
-- which the linter reads.
--
-- Regenerate it after every content patch. That is the entire point:
-- a list Blizzard maintains cannot rot the way a hand-written one does.
--
-- USAGE
--   1. Copy this folder into Interface/AddOns/ (as TomoAPIDump).
--   2. Enable it, log in, run  /apidump
--   3. /reload   -- SavedVariables are only flushed on logout or reload
--   4. python3 Tools/apidoc_import.py <path to>/SavedVariables/TomoAPIDump.lua
--
-- Nothing here is loaded by TomoMod and .pkgmeta drops Tools/ from the
-- release zip, so no player ever sees it.
-- =====================================================================

local ADDON = ...

TomoAPIDumpDB = TomoAPIDumpDB or {}

-- The separator has to survive WoW's SavedVariables writer untouched and
-- never appear inside an identifier. `|` qualifies on both counts; it is
-- only special in strings the client renders, and nothing here is
-- rendered.
local SEP = "|"

local function Clean(value)
    if value == nil then return "" end
    if type(value) ~= "string" then value = tostring(value) end
    -- A stray separator inside a documentation string would shift every
    -- field after it by one, silently.
    value = value:gsub("%" .. SEP, "/")
    value = value:gsub("[\r\n\t]", " ")
    return value
end

local function Join(parts)
    return table.concat(parts, SEP)
end

-- Enum.SecretAspect maps name -> value; the documentation stores the
-- value. Reverse it once so records carry readable names instead of
-- integers that mean nothing in a diff a year from now.
local function ReverseEnum(enumTable)
    local out = {}
    if type(enumTable) ~= "table" then return out end
    for name, value in pairs(enumTable) do
        if type(value) == "number" then
            out[value] = name
        end
    end
    return out
end

local function AspectList(values, names)
    if type(values) ~= "table" then return "" end
    local out = {}
    for _, v in ipairs(values) do
        table.insert(out, names[v] or tostring(v))
    end
    table.sort(out)
    return table.concat(out, ",")
end

local function QualifiedName(system, entry)
    local ns = system and system.Namespace
    if ns and ns ~= "" then
        return ns .. "." .. entry.Name
    end
    return entry.Name
end

-- ---------------------------------------------------------------------
-- Structures
--
-- A function that returns a plain number is one problem; a function that
-- returns a table whose `name` field is ConditionalSecret is a different
-- one, and the call site looks identical. Index the structures first so
-- the function pass can say which returns carry secrets inside them.
-- ---------------------------------------------------------------------

local FIELD_FLAGS = {
    "ConditionalSecret",
    "NeverSecret",
    "ConditionalSecretContents",
    "NeverSecretContents",
}

local function CollectStructures(records)
    local secretStructures = {}
    local count = 0

    for _, system in ipairs(APIDocumentation.systems or {}) do
        for _, tbl in ipairs(system.Tables or {}) do
            if tbl.Type == "Structure" and type(tbl.Fields) == "table" then
                local carriesSecret = false
                for _, field in ipairs(tbl.Fields) do
                    local flags = {}
                    for _, flag in ipairs(FIELD_FLAGS) do
                        if field[flag] then
                            table.insert(flags, flag)
                        end
                    end
                    if #flags > 0 then
                        table.insert(records, Join({
                            "S", Clean(tbl.Name), Clean(field.Name),
                            table.concat(flags, ","),
                        }))
                        count = count + 1
                        -- NeverSecret is a promise, not a warning. Only
                        -- the conditional flags make the structure worth
                        -- flagging to callers.
                        if field.ConditionalSecret or field.ConditionalSecretContents then
                            carriesSecret = true
                        end
                    end
                end
                if carriesSecret then
                    secretStructures[tbl.Name] = true
                end
            end
        end
    end

    return secretStructures, count
end

-- ---------------------------------------------------------------------
-- Functions
-- ---------------------------------------------------------------------

local function ReturnStructures(func, secretStructures)
    local out = {}
    for _, ret in ipairs(func.Returns or {}) do
        local t = ret.Type
        if t and secretStructures[t] then
            out[t] = true
        end
        -- A table return declares its element type separately.
        local inner = ret.InnerType
        if inner and secretStructures[inner] then
            out[inner] = true
        end
    end
    local names = {}
    for name in pairs(out) do table.insert(names, name) end
    table.sort(names)
    return table.concat(names, ",")
end

local function CollectFunctions(records, secretStructures, aspectNames, forbiddenNames)
    local nReturns, nArgs, nForbidden = 0, 0, 0

    for _, system in ipairs(APIDocumentation.systems or {}) do
        for _, func in ipairs(system.Functions or {}) do
            local name = QualifiedName(system, func)

            local aspects = AspectList(func.SecretReturnsForAspect, aspectNames)
            local structs = ReturnStructures(func, secretStructures)

            -- Two independent reasons a call can put a secret into a
            -- local: the return itself is conditional, or the returned
            -- structure has conditional fields. Either one earns an F.
            if aspects ~= "" or structs ~= "" then
                table.insert(records, Join({ "F", Clean(name), aspects, structs }))
                nReturns = nReturns + 1
            end

            if func.SecretArguments then
                table.insert(records, Join({
                    "A", Clean(name), Clean(func.SecretArguments),
                    AspectList(func.SecretArgumentsAddAspect, aspectNames),
                }))
                nArgs = nArgs + 1
            end

            if type(func.ChecksForbiddenAspects) == "table" then
                local parts = {}
                for _, entry in ipairs(func.ChecksForbiddenAspects) do
                    local aspect = forbiddenNames[entry.Aspect] or tostring(entry.Aspect)
                    table.insert(parts, aspect .. "(" .. Clean(entry.Argument) .. ")")
                end
                table.sort(parts)
                table.insert(records, Join({ "X", Clean(name), table.concat(parts, ",") }))
                nForbidden = nForbidden + 1
            end
        end
    end

    return nReturns, nArgs, nForbidden
end

-- ---------------------------------------------------------------------
-- Driver
-- ---------------------------------------------------------------------

local function Dump()
    if not APIDocumentation then
        if type(APIDocumentation_LoadUI) == "function" then
            APIDocumentation_LoadUI()
        end
    end

    if not APIDocumentation or type(APIDocumentation.systems) ~= "table" then
        print("|cffff4444TomoAPIDump|r: APIDocumentation is not available on this client.")
        return
    end

    local aspectNames = ReverseEnum(Enum and Enum.SecretAspect)
    local forbiddenNames = ReverseEnum(Enum and Enum.ForbiddenAspect)

    local records = {}
    local secretStructures, nStructFields = CollectStructures(records)
    local nReturns, nArgs, nForbidden =
        CollectFunctions(records, secretStructures, aspectNames, forbiddenNames)

    -- Sorted so two dumps of the same build produce byte-identical
    -- output and a real API change is the only thing a diff shows.
    table.sort(records)

    local build, _, _, interface = GetBuildInfo()

    table.insert(records, 1, Join({
        "H", Clean(build), Clean(interface), date("%Y-%m-%d"),
    }))

    TomoAPIDumpDB = {
        version = 1,
        build = build,
        interface = interface,
        generated = date("%Y-%m-%d %H:%M:%S"),
        records = records,
    }

    print(string.format(
        "|cff2E9DD8TomoAPIDump|r: %d secret-returning functions, %d with secret arguments, "
        .. "%d forbidden-aspect checks, %d structure fields.",
        nReturns, nArgs, nForbidden, nStructFields))
    print("|cff2E9DD8TomoAPIDump|r: /reload to flush SavedVariables, then run Tools/apidoc_import.py.")
end

SLASH_TOMOAPIDUMP1 = "/apidump"
SLASH_TOMOAPIDUMP2 = "/tomoapidump"
SlashCmdList["TOMOAPIDUMP"] = Dump

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    print("|cff2E9DD8TomoAPIDump|r loaded. Run /apidump, then /reload.")
end)

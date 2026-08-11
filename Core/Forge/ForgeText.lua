-- =====================================================================
-- TomoMod Forge -- Text (L1)
-- Secret-safe template compiler, shared by every domain that offers
-- custom text elements.
--
-- WHY THIS IS A COMPILER AND NOT A CONCATENATION.
-- In Midnight, UnitName returns a SECRET STRING and UnitEffectiveLevel a
-- SECRET NUMBER. Lua must never touch either: `"a" .. UnitName(u)` raises,
-- and so does comparing or measuring one. So a template like
-- "[name] - [level]" is compiled into a FORMAT STRING plus an ordered
-- ARGUMENT LIST, and the values are handed straight to SetFormattedText,
-- which resolves them C-side. Nothing here ever reads a value it fetched.
--
-- Percent signs in literal text are escaped, or SetFormattedText would
-- read them as conversions and shift every argument after them.
--
-- Callers supply their own token table and resolver, so the domains share
-- the risky part and differ only in the harmless part.
-- =====================================================================

local Forge = TomoMod_Forge
if not Forge then return end

Forge.Text = Forge.Text or {}
local T = Forge.Text

local type, ipairs, unpack = type, ipairs, unpack
local tconcat = table.concat

-- Reused between calls: this runs on unit events, and a fresh table per
-- call would churn the collector for nothing.
local argBuffer = {}
local partsBuffer = {}

local function wipeList(t)
    for i = #t, 1, -1 do t[i] = nil end
end

-- tokens  : array of { token = "name", fmt = "%s", labelKey = ... }
-- Returns a lookup usable as the `fmts` argument of Render.
function T.CompileTokens(tokens)
    local out = {}
    for _, t in ipairs(tokens or {}) do
        if type(t.token) == "string" then out[t.token] = t.fmt or "%s" end
    end
    return out
end

-- fs       : FontString to write into
-- template : user string, e.g. "[name] - [level]"
-- fmts     : token -> format specifier (from CompileTokens)
-- resolve  : function(token, ctx) -> value|nil
-- ctx      : opaque, handed back to resolve (a unit token, usually)
--
-- Returns true when something was written. False means "nothing to show",
-- so the caller can blank the widget.
function T.Render(fs, template, fmts, resolve, ctx)
    if not fs or type(template) ~= "string" or template == "" then return false end
    if type(fmts) ~= "table" or type(resolve) ~= "function" then return false end

    wipeList(argBuffer)
    wipeList(partsBuffer)
    local n = 0

    local cursor = 1
    while true do
        local a, b, token = template:find("%[(%w+)%]", cursor)
        if not a then break end

        local literal = template:sub(cursor, a - 1)
        if literal ~= "" then
            partsBuffer[#partsBuffer + 1] = literal:gsub("%%", "%%%%")
        end

        local fmt = fmts[token]
        if fmt then
            local value = resolve(token, ctx)
            if value ~= nil then
                partsBuffer[#partsBuffer + 1] = fmt
                n = n + 1
                argBuffer[n] = value
            end
        else
            -- Unknown token: echo it verbatim rather than swallow it, so a
            -- typo is visible instead of mysteriously blank.
            partsBuffer[#partsBuffer + 1] = template:sub(a, b):gsub("%%", "%%%%")
        end
        cursor = b + 1
    end

    local tail = template:sub(cursor)
    if tail ~= "" then
        partsBuffer[#partsBuffer + 1] = tail:gsub("%%", "%%%%")
    end

    local fmt = tconcat(partsBuffer)
    if fmt == "" then return false end
    fs:SetFormattedText(fmt, unpack(argBuffer, 1, n))
    return true
end

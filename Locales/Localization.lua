-- =====================================
-- Localization.lua — Core localization system
-- Loaded FIRST — provides TomoMod_L table
-- =====================================

TomoMod_L = {}

-- Metatable: missing key returns the key itself (safe fallback)
setmetatable(TomoMod_L, {
    __index = function(_, key)
        return key
    end,
})

-- Helper: register locale strings
-- Usage: TomoMod_RegisterLocale("frFR", { key = "value", ... })
function TomoMod_RegisterLocale(locale, strings)
    local current = GetLocale()
    if locale == "enUS" then
        -- enUS is the base fallback — always load
        for k, v in pairs(strings) do
            -- rawget only: TomoMod_L has an __index that returns the key
            -- itself, so TomoMod_L[k] is never nil. The first test was always
            -- false AND fired the metamethod on every one of the ~2900 enUS
            -- keys for nothing.
            if rawget(TomoMod_L, k) == nil then
                rawset(TomoMod_L, k, v)
            end
        end
    elseif locale == current then
        -- Active locale overrides everything
        for k, v in pairs(strings) do
            rawset(TomoMod_L, k, v)
        end
    end
end

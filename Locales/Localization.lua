-- =====================================
-- Localization.lua — Core localization system
-- Loaded FIRST — provides TomoModMini_L table
-- =====================================

TomoModMini_L = {}

-- Metatable: missing key returns the key itself (safe fallback)
setmetatable(TomoModMini_L, {
    __index = function(_, key)
        return key
    end,
})

-- Helper: register locale strings
-- Usage: TomoModMini_RegisterLocale("frFR", { key = "value", ... })
function TomoModMini_RegisterLocale(locale, strings)
    local current = GetLocale()
    if locale == "enUS" then
        -- enUS is the base fallback — always load
        for k, v in pairs(strings) do
            if TomoModMini_L[k] == nil or rawget(TomoModMini_L, k) == nil then
                rawset(TomoModMini_L, k, v)
            end
        end
    elseif locale == current then
        -- Active locale overrides everything
        for k, v in pairs(strings) do
            rawset(TomoModMini_L, k, v)
        end
    end
end

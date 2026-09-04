local ADDON_NAME, TomoMod = ...
local ns = TomoMod.DM

-- ---------------------------------------------------------------------
-- Settings.lua -- one declarative description of every meter setting
--
-- Each setting is a database key plus the recipe for making the change
-- visible. Those recipes used to live inline in the standalone options
-- window; with the module also driven from TomoMod's own config page,
-- keeping them there would have meant two copies of "what to refresh when
-- the bar texture changes", and the two would drift the first time one was
-- edited.
--
-- The standalone window and the TomoMod page now both write through
-- ns.ApplySetting, so a setting behaves identically wherever it is changed.
-- ---------------------------------------------------------------------

local function ForEachWindow(method)
    for _, win in ipairs(ns.windows or {}) do
        if method and win[method] then win[method]() end
        if win.Refresh then win.Refresh() end
    end
end

-- Recipes, keyed by database field. A setting with no entry here just
-- writes its value: plenty of them are read at the next draw anyway.
local APPLY = {
    skin = function(val)
        if ns.ApplySkin then ns.ApplySkin(val) end
    end,

    barTexture = function() ForEachWindow("RefreshSkin") end,

    fontSize = function()
        if ns.ClearCharWidthCache then ns.ClearCharWidthCache() end
        ForEachWindow("RefreshFonts")
    end,

    fontPath = function()
        if ns.ClearCharWidthCache then ns.ClearCharWidthCache() end
        ForEachWindow("RefreshFonts")
        -- The breakdown panels build their own font strings and are not in
        -- ns.windows, so they need telling separately.
        if ns.RefreshBreakdownFonts then ns.RefreshBreakdownFonts() end
        if ns.RefreshTargetBreakdownFonts then ns.RefreshTargetBreakdownFonts() end
    end,

    barHeight = function()
        for _, win in ipairs(ns.windows or {}) do
            if win.RefreshBarHeight then win.RefreshBarHeight() end
        end
    end,

    accentUseClassColor = function()
        if ns.ApplyAccentColor then ns.ApplyAccentColor() end
        for _, win in ipairs(ns.windows or {}) do
            if win.RefreshAccentColor then win.RefreshAccentColor() end
        end
    end,

    bgAlpha = function(val)
        for _, win in ipairs(ns.windows or {}) do
            if win.SetBGAlpha then win.SetBGAlpha(val) end
        end
    end,

    -- Out-of-combat opacity is only visible out of combat; applying it
    -- mid-fight would fade the window the player is reading.
    oocAlpha = function()
        if ns.inCombat then return end
        for _, win in ipairs(ns.windows or {}) do
            if win.SetCombatAlpha then win.SetCombatAlpha(false) end
        end
    end,

    breakdownAlpha = function()
        if ns.ApplyBreakdownAlpha then ns.ApplyBreakdownAlpha() end
        if ns.ApplyDeathRecapAlpha then ns.ApplyDeathRecapAlpha() end
    end,

    showCombatTimer = function()
        for _, win in ipairs(ns.windows or {}) do
            if win.UpdateTimer then win.UpdateTimer() end
        end
    end,

    combatTimerPos = function() ForEachWindow("RefreshTimerPos") end,

    showSelfBar = function() ForEachWindow() end,
    stripRealm  = function() ForEachWindow() end,
    columns     = function() ForEachWindow("RefreshFonts") end,
}

-- Writes a setting and applies it. Returns false when the database is not
-- ready, which happens if something calls in before ADDON_LOADED.
function ns.ApplySetting(key, value)
    if not ns.db or not key then return false end
    ns.db[key] = value
    local fn = APPLY[key]
    if fn then
        -- A broken refresh must not stop the value being saved: the player
        -- would change a setting, see an error, and find it reverted.
        local ok, err = pcall(fn, value)
        if not ok then
            print("|cff2e9dd8TomoMod|r DamageMeter: " .. tostring(err))
        end
    end
    return true
end

function ns.GetSetting(key)
    return ns.db and ns.db[key]
end

-- Banc hors-jeu pour S.State — les trois états, avec une API qui se comporte
-- comme celle du jeu (GetAddOnInfo rend le nom demandé même s'il est absent).
_G.TomoMod_Widgets = {}
_G.TomoModDB = { Suite = {} }
_G.TomoMod_RegisterLocale = function() end
_G.TomoMod_L = setmetatable({}, { __index = function(_, k) return k end })

local INSTALLED, LOADED = {}, {}
_G.C_AddOns = {
    GetNumAddOns = function() return #INSTALLED end,
    -- Reproduit le piège : sur un NOM inconnu, l'API rend le nom demandé.
    GetAddOnInfo = function(k)
        if type(k) == "number" then return INSTALLED[k] end
        for _, n in ipairs(INSTALLED) do if n == k then return n, n, "", true end end
        return k, nil, nil, false, "MISSING"      -- <- absent, mais retour non nil
    end,
    IsAddOnLoaded = function(n) return LOADED[n] == true end,
}

assert(loadfile("Config/Panels/_Suite.lua"))()
local S = TomoMod_Suite

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-46s attendu=%-9s obtenu=%s"):format(good and "OK   " or "ÉCHEC", label, want, got))
end

INSTALLED, LOADED = { "TomoMod", "TomoBoss" }, { TomoBoss = true }
check("installé et activé", S.State("TomoBoss"), "loaded")

INSTALLED, LOADED = { "TomoMod", "TomoBoss" }, {}
check("présent mais désactivé", S.State("TomoBoss"), "disabled")

INSTALLED, LOADED = { "TomoMod" }, {}
check("supprimé du disque", S.State("TomoBoss"), "absent")

INSTALLED, LOADED = {}, {}
check("aucun addon", S.State("TomoBoss"), "absent")

INSTALLED, LOADED = { "tomoboss" }, {}
check("casse différente du dossier", S.State("TomoBoss"), "disabled")

local saved = C_AddOns; _G.C_AddOns = nil
check("API indisponible (repli prudent)", S.State("TomoBoss"), "absent")
_G.C_AddOns = saved

print(ok and "\n>>> TOUS LES ÉTATS CORRECTS" or "\n>>> ÉCHEC")
os.exit(ok and 0 or 1)
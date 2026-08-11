-- Banc hors-jeu pour les elements instancies (lot 6).
--
-- Deux blocs.
--
--   1. CYCLE DE VIE. Ajouter, supprimer, plafonner, et surtout : ne jamais
--      reutiliser un index libere. Supprimer le #2 de trois elements ne doit
--      pas faire entrer le suivant en collision avec le #3, sinon un relTo
--      pointerait silencieusement sur un autre widget.
--
--   2. MOTEUR DE FORMAT. C'est le point critique du lot. UnitName rend une
--      chaine SECRETE en Midnight : la concatener en Lua leve. Le modele est
--      donc compile en chaine de format + liste d'arguments, et les valeurs
--      partent telles quelles dans SetFormattedText, qui les resout cote C.
--      On verifie qu'AUCUNE concatenation n'a lieu en posant des sentinelles
--      qui explosent si Lua les touche.

_G.TomoMod_Forge = { BRAND = { 0, 0, 0 } }
_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
_G.unpack = unpack

-- ── Valeur "secrete" : toute operation Lua dessus leve, comme en jeu ──
local SECRET_MT = {
    __concat = function() error("concatenation d'une valeur secrete", 2) end,
    __add    = function() error("arithmetique sur une valeur secrete", 2) end,
    __len    = function() error("longueur d'une valeur secrete", 2) end,
    __tostring = function() return "<secret>" end,
}
local function Secret(plain)
    return setmetatable({ _plain = plain }, SECRET_MT)
end

local currentUnitName = Secret("Thrall")
_G.UnitExists = function(u) return u ~= nil and u ~= "none" end
_G.UnitName   = function() return currentUnitName end
_G.UnitLevel  = function() return Secret("70") end
_G.UnitClass  = function() return "Shaman", "SHAMAN" end
_G.UnitRace   = function() return "Orc", "Orc" end
_G.GetGuildInfo = function() return "Frostwolf" end
_G.TomoModDB = { unitFrames = { font = "F", fontSize = 12, fontOutline = "OUTLINE" } }

local function FontString(name)
    local o = { _name = name, _text = nil, _fmt = nil, _args = nil }
    function o:ClearAllPoints() self._pt = nil end
    function o:SetPoint(p, rel, rp, x, y) self._pt = { p, rel, rp, x, y } end
    function o:SetAlpha(a) self._alpha = a end
    function o:SetFont(f, s, fl) self._font = { f, s, fl } end
    function o:GetFont() local f = self._font or { "F", 12, "" } return f[1], f[2], f[3] end
    function o:SetTextColor() end
    function o:SetText(t) self._text = t; self._fmt = nil end
    function o:Hide() self._hidden = true end
    -- Cote C : le format et les arguments sont conserves tels quels, aucune
    -- valeur n'est touchee par Lua.
    function o:SetFormattedText(fmt, ...)
        self._fmt = fmt
        self._args = { ... }
        self._n = select("#", ...)
    end
    return o
end

local function MakeFrame(unit)
    local f = { unit = unit or "target" }
    function f:ClearAllPoints() end
    function f:SetPoint() end
    function f:CreateFontString() return FontString("custom") end
    f.health = { }
    function f.health:ClearAllPoints() end
    function f.health:SetPoint() end
    f.health.nameText   = FontString("nameText")
    f.health.levelText  = FontString("levelText")
    f.health.text       = FontString("healthText")
    f.health.raidIcon   = FontString("raidIcon")
    f.health.leaderIcon = FontString("leaderIcon")
    f.power      = FontString("power")
    f.threatText = FontString("threatText")
    return f
end

assert(loadfile("Core/Forge/ForgeRegistry.lua"))()
assert(loadfile("Core/Forge/ForgeText.lua"))()
assert(loadfile("Modules/Interface/UnitFrames/UFElements.lua"))()

local R   = TomoMod_Forge.Registry
local UFE = TomoMod_UFElements
local D   = UFE.DOMAIN

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-54s attendu=%-16s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

-- ═══════════════════════════════════════════════════════════════════════
print("── Declaration du type instanciable ──")
check("un type declare", #R.ListTypes(D), 1)
check("type = customText", R.ListTypes(D)[1].id, "customText")
check("plafond a 6", R.GetType(D, "customText").max, 6)
check("kind = fontstring", R.GetType(D, "customText").kind, "fontstring")
check("type inconnu -> nil", R.GetType(D, "plop"), nil)

print("── Cles d'instance ──")
local t, n = R.SplitKey("customText:3")
check("type extrait", t, "customText")
check("index extrait", n, 3)
check("cle sans index -> nil", R.SplitKey("customText"), nil)
check("cle nil -> nil", R.SplitKey(nil), nil)
check("Describe trouve un singleton", R.Describe(D, "name").id, "name")
check("Describe trouve un type", R.Describe(D, "customText:2").id, "customText")

-- ═══════════════════════════════════════════════════════════════════════
print("── Cycle de vie : ajout ──")
local store = {}
UFE.Ensure(store)
local k1 = R.AddInstance(D, store, "customText")
check("premiere cle", k1, "customText:1")
check("enregistrement cree", type(store[k1]), "table")
check("modele par defaut", store[k1].text, "[name]")
check("ancrage par defaut", store[k1].relTo, "frame")
check("proprietes du type appliquees (fontSize)", store[k1].fontSize, 0)
check("pas d'echelle sur une chaine", store[k1].scale, nil)

local k2 = R.AddInstance(D, store, "customText")
local k3 = R.AddInstance(D, store, "customText")
check("deuxieme cle", k2, "customText:2")
check("troisieme cle", k3, "customText:3")
check("compte = 3", R.CountInstances(D, store, "customText"), 3)
check("type inconnu refuse", R.AddInstance(D, store, "plop"), nil)

print("── Cycle de vie : suppression sans reutilisation d'index ──")
check("suppression du #2", R.RemoveInstance(D, store, k2), true)
check("compte = 2", R.CountInstances(D, store, "customText"), 2)
local k4 = R.AddInstance(D, store, "customText")
check("le suivant est :4, PAS :2", k4, "customText:4")
check("suppression d'une cle absente", R.RemoveInstance(D, store, "customText:99"), false)
check("suppression d'un singleton refusee", R.RemoveInstance(D, store, "name"), false)

print("── Suppression : les ancrages orphelins sont recuperes ──")
store[k1].relTo = k3
check("k1 ancre sur k3", store[k1].relTo, k3)
R.RemoveInstance(D, store, k3)
check("k1 rebascule sur son defaut", store[k1].relTo, "frame")

print("── Plafond ──")
local st2 = {}
UFE.Ensure(st2)
for _ = 1, 6 do R.AddInstance(D, st2, "customText") end
check("6 instances", R.CountInstances(D, st2, "customText"), 6)
local over, why = R.AddInstance(D, st2, "customText")
check("la 7e est refusee", over, nil)
check("raison = max", why, "max")

-- ═══════════════════════════════════════════════════════════════════════
print("── Application et purge ──")
local frame = MakeFrame("target")
local st3 = {}
UFE.Ensure(st3)
local a1 = R.AddInstance(D, st3, "customText")
local a2 = R.AddInstance(D, st3, "customText")
check("ApplyAll compte singletons + instances", UFE.ApplyAll(frame, st3), 9)
check("widget construit et cache", type(frame._forgeInstances[a1]), "table")
check("deux widgets", type(frame._forgeInstances[a2]), "table")
check("construit une seule fois",
    R.ResolveInstance(D, a1, frame), frame._forgeInstances[a1])

R.RemoveInstance(D, st3, a2)
UFE.ApplyAll(frame, st3)
check("widget supprime masque", frame._forgeInstances[a2]._hidden, true)
check("widget restant intact", frame._forgeInstances[a1]._hidden, nil)

print("── Instance comme cible d'ancrage ──")
check("instance vivante = cible", R.IsTarget(D, a1), true)
local st4 = {}
UFE.Ensure(st4)
local b1 = R.AddInstance(D, st4, "customText")
local b2 = R.AddInstance(D, st4, "customText")
st4[b2].relTo = b1
check("b2 ancre sur b1 accepte", R.Sanitize(D, b2, st4[b2]).relTo, b1)
check("boucle b1 -> b2 detectee", R.WouldCycle(D, st4, b1, b2), true)
local offered = {}
for _, tg in ipairs(R.AllowedTargets(D, b1, st4)) do offered[tg.id] = true end
check("b2 non propose a b1", offered[b2], nil)
check("frame propose a b1", offered.frame, true)

-- Store bricole : relTo pointe sur une instance disparue.
st4[b2].relTo = "customText:99"
R.Ensure(D, st4)
check("cible fantome recuperee", st4[b2].relTo, "frame")

-- ═══════════════════════════════════════════════════════════════════════
print("── Moteur de format : aucune concatenation Lua ──")
local fs = FontString("t")

check("modele simple rendu", UFE.RenderCustomText(fs, "target", "[name]"), true)
check("format = %s", fs._fmt, "%s")
check("un argument", fs._n, 1)
check("l'argument EST la valeur secrete", fs._args[1], currentUnitName)

check("texte litteral seul", UFE.RenderCustomText(fs, "target", "Cible"), true)
check("aucun argument", fs._n, 0)
check("format litteral", fs._fmt, "Cible")

UFE.RenderCustomText(fs, "target", "[level] - [name]")
check("deux jetons : format", fs._fmt, "%s - %s")
check("deux jetons : 2 arguments", fs._n, 2)
check("ordre preserve (nom en 2e)", fs._args[2], currentUnitName)

UFE.RenderCustomText(fs, "target", "<[class]>")
check("litteral autour du jeton", fs._fmt, "<%s>")
check("valeur non secrete passee", fs._args[1], "Shaman")

-- Un pourcent litteral doit etre echappe, sinon SetFormattedText le lirait
-- comme une conversion et decalerait les arguments.
UFE.RenderCustomText(fs, "target", "100% [name]")
check("pourcent echappe", fs._fmt, "100%% %s")
check("argument toujours unique", fs._n, 1)

UFE.RenderCustomText(fs, "target", "[inconnu]")
check("jeton inconnu affiche tel quel", fs._fmt, "[inconnu]")
check("jeton inconnu : 0 argument", fs._n, 0)

check("modele vide rejete", UFE.RenderCustomText(fs, "target", ""), false)
check("modele nil rejete", UFE.RenderCustomText(fs, "target", nil), false)
check("unite absente rejetee", UFE.RenderCustomText(fs, "none", "[name]"), false)

print("── RefreshCustomTexts ──")
local frame2 = MakeFrame("target")
local st5 = {}
UFE.Ensure(st5)
local c1 = R.AddInstance(D, st5, "customText")
st5[c1].text = "[guild]"
UFE.ApplyAll(frame2, st5)
check("2 rendus ? non : une seule instance",
    UFE.RefreshCustomTexts(frame2, st5), 1)
check("guilde rendue", frame2._forgeInstances[c1]._args[1], "Frostwolf")

st5[c1].text = ""
UFE.RefreshCustomTexts(frame2, st5)
check("modele vide -> texte efface", frame2._forgeInstances[c1]._text, "")

-- ═══════════════════════════════════════════════════════════════════════
print("── Conteneurs d'auras : desormais des elements ──")
check("auras enregistre", R.Get(D, "auras") ~= nil, true)
check("enemyBuffs enregistre", R.Get(D, "enemyBuffs") ~= nil, true)
check("auras : defaut historique", R.Default(D, "auras").point, "BOTTOMLEFT")
check("auras : relTo = frame", R.Default(D, "auras").relTo, "frame")
check("auras : y historique", R.Default(D, "auras").y, 6)
check("enemyBuffs : defaut historique", R.Default(D, "enemyBuffs").point, "BOTTOMRIGHT")
check("conteneurs = frames (echelle dispo)", R.HasProp(D, "auras", "scale"), true)

print(ok and "\nTOUS LES TESTS PASSENT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

-- Banc hors-jeu pour Core/ModuleRegistry.lua.
--
-- Le registre est la pièce dont dépendent les lots 1, 2, 4 et 6 : s'il
-- ment sur l'état d'un module ou sur ce qu'un profil contient, l'erreur
-- se propage partout. On exerce donc le contrat complet sur un jeu de
-- manifestes synthétique, indépendant du vrai inventaire (celui-ci est
-- couvert par test_module_manifest_static.lua).
--
-- Usage : luajit Tools/test_module_registry.lua   (depuis la racine)

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-58s attendu=%-10s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

assert(loadfile("Core/ModuleRegistry.lua"))()
local R = _G.TomoMod_Registry

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. Chemins pointés ──")

local root = { a = { b = { c = 7 } }, flag = false }
check("GetPath profond",            R.GetPath(root, "a.b.c"), 7)
check("GetPath branche absente",    R.GetPath(root, "a.x.c"), nil)
check("GetPath ne crée rien",       root.a.x,                 nil)
check("GetPath sur booléen faux",   R.GetPath(root, "flag"),  false)
R.SetPath(root, "a.b.d", 9)
check("SetPath dans table existante", root.a.b.d, 9)
R.SetPath(root, "new.deep.leaf", "v")
check("SetPath crée les paliers",     root.new.deep.leaf, "v")
check("SetPath chemin vide refusé",   R.SetPath(root, "", 1), false)

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Define : garde-fous structurels ──")

local function refuses(label, desc)
    local okCall = pcall(R.Define, desc)
    check(label, okCall, false)
end

refuses("manifeste sans clé",          { label = "l", group = "qol" })
refuses("groupe inconnu",              { key = "x1", label = "l", group = "nope" })
refuses("module public sans libellé",  { key = "x2", group = "qol" })
refuses("interne avec un groupe",      { key = "x3", internal = true, group = "qol" })
refuses("enabledPath ET toggles",      { key = "x4", label = "l", group = "qol",
                                         enabledPath = "x4.enabled", toggles = { { path = "x4.a" } } })
refuses("toggles vide",                { key = "x5", label = "l", group = "qol", toggles = {} })
refuses("ancre de forme inconnue",     { key = "x6", label = "l", group = "qol",
                                         anchors = { { id = "i", path = "x6.position", shape = "wat" } } })

R.Define{ key = "dup", label = "l", group = "qol" }
refuses("clé en double",               { key = "dup", label = "l", group = "qol" })

-- ═══════════════════════════════════════════════════════════════════════
print("── 3. Modèles de bascule ──")

R._Reset()
R.Define{ key = "simple",  label = "l_simple",  group = "qol", enabledPath = "simple.enabled" }
R.Define{ key = "comp",    label = "l_comp",    group = "qol",
          toggles = { { path = "comp.a" }, { path = "comp.b" } } }
R.Define{ key = "passive", label = "l_passive", group = "qol" }

check("modèle simple",    R.Get("simple").toggleModel,  "simple")
check("modèle composite", R.Get("comp").toggleModel,    "composite")
check("modèle passif",    R.Get("passive").toggleModel, "passive")

_G.TomoModDB = {
    simple  = { enabled = false },
    comp    = { a = false, b = true },
    passive = {},
}

check("simple : lecture off",         R.IsEnabled("simple"), false)
check("composite : une seule suffit", R.IsEnabled("comp"),   true)
check("passif : toujours actif",      R.IsEnabled("passive"), true)
check("module inconnu",               R.IsEnabled("ghost"),  nil)

local okSet, reload = R.SetEnabled("simple", true)
check("simple : SetEnabled rend ok",  okSet,  true)
check("simple : pas de reload requis", reload, false)
check("simple : flag écrit",          TomoModDB.simple.enabled, true)

-- Le point sensible : couper puis rallumer un module composite ne doit
-- pas repasser toutes les sous-options à « on ». Ici seule `b` était
-- active, elle doit être la seule à revenir.
R.SetEnabled("comp", false)
check("composite : a coupée",         TomoModDB.comp.a, false)
check("composite : b coupée",         TomoModDB.comp.b, false)
check("composite : vu comme éteint",  R.IsEnabled("comp"), false)
check("composite : état mémorisé",    type(TomoModDB.comp._suspended), "table")
R.SetEnabled("comp", true)
check("composite : a reste éteinte",  TomoModDB.comp.a, false)
check("composite : b restaurée",      TomoModDB.comp.b, true)
check("composite : mémo consommé",    TomoModDB.comp._suspended, nil)

-- Rallumer sans mémo (jamais suspendu) doit répondre quelque chose,
-- sinon l'interrupteur paraît cassé.
TomoModDB.comp2 = { a = false, b = false }
R.Define{ key = "comp2", label = "l", group = "qol",
          toggles = { { path = "comp2.a" }, { path = "comp2.b" } } }
R.SetEnabled("comp2", true)
check("composite sans mémo : tout on", TomoModDB.comp2.a and TomoModDB.comp2.b, true)

-- Suspendre alors que tout est déjà éteint, puis rallumer : le mémo ne
-- contient que des false, le repli « tout on » doit prendre le relais.
TomoModDB.comp3 = { a = false, b = false }
R.Define{ key = "comp3", label = "l", group = "qol",
          toggles = { { path = "comp3.a" }, { path = "comp3.b" } } }
R.SetEnabled("comp3", false)
R.SetEnabled("comp3", true)
check("composite mémo vide : tout on", TomoModDB.comp3.a and TomoModDB.comp3.b, true)

local okPassive = R.SetEnabled("passive", false)
check("passif : SetEnabled refusé",   okPassive, false)

-- ═══════════════════════════════════════════════════════════════════════
print("── 4. Groupes, arbre et internes ──")

R._Reset()
R.Define{ key = "m1",   label = "l1", group = "qol",     enabledPath = "m1.enabled" }
R.Define{ key = "m2",   label = "l2", group = "qol",     enabledPath = "m2.enabled" }
R.Define{ key = "m3",   label = "l3", group = "general", enabledPath = "m3.enabled" }
R.Define{ key = "hidden", internal = true }

check("List ignore les internes",     #R.List(),                3)
check("ListAll les compte",           #R.ListAll(),             4)
check("ListByGroup qol",              #R.ListByGroup("qol"),    2)
check("ListByGroup vide",             #R.ListByGroup("skins"),  0)
check("neuf groupes déclarés",        #R.Groups(),              9)

local tree = R.Tree()
check("Tree écarte les groupes vides", #tree, 2)
check("Tree respecte l'ordre",         tree[1].key, "general")

-- Un module interne ne doit jamais atterrir dans un arbre d'import.
local leaked = false
for _, g in ipairs(tree) do
    for _, m in ipairs(g.modules) do
        if m.key == "hidden" then leaked = true end
    end
end
check("Tree ne fuit aucun interne",   leaked, false)

-- ═══════════════════════════════════════════════════════════════════════
print("── 5. Contexte (arbitrage A) ──")

R._Reset()
R.Define{ key = "follows", label = "l", group = "qol", enabledPath = "follows.enabled" }
R.Define{ key = "pinned",  label = "l", group = "qol", enabledPath = "pinned.enabled", contextSwap = false }
R.Define{ key = "state",   internal = true }

check("suit le contexte par défaut",  R.Get("follows").contextSwap, true)
check("épinglé si demandé",           R.Get("pinned").contextSwap,  false)
check("interne toujours épinglé",     R.Get("state").contextSwap,   false)
check("liste des suiveurs",           #R.ContextSwappable(),        1)
check("liste des épinglés",           #R.ContextPinned(),           2)

-- ═══════════════════════════════════════════════════════════════════════
print("── 6. Ancres (arbitrage B) ──")

R._Reset()
R.Define{ key = "mv", label = "l", group = "qol", enabledPath = "mv.enabled",
          anchors = {
              { id = "mv.one", path = "mv.one.position", shape = "point_relativePoint" },
              { id = "mv.two", path = "mv.two.position", shape = "anchor_relTo" },
          } }
local anchors = R.Anchors()
check("ancres aplaties",              #anchors,            2)
check("ancre porte son module",       anchors[1].module,   "mv")
check("ancre porte sa forme",         anchors[2].shape,    "anchor_relTo")
check("trois formes connues",         (R.ANCHOR_SHAPES.point_relativePoint
                                        and R.ANCHOR_SHAPES.point_relPoint
                                        and R.ANCHOR_SHAPES.anchor_relTo) ~= nil, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 7. Dépendances ──")

R._Reset()
R.Define{ key = "base",  label = "l", group = "qol", enabledPath = "base.enabled" }
R.Define{ key = "child", label = "l", group = "qol", enabledPath = "child.enabled", deps = { "base" } }
_G.TomoModDB = { base = { enabled = false }, child = { enabled = true } }

check("dépendance manquante vue",     #R.MissingDeps("child"), 1)
check("dépendants retrouvés",         R.Dependents("base")[1], "child")
TomoModDB.base.enabled = true
check("dépendance satisfaite",        #R.MissingDeps("child"), 0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 8. Validate ──")

R._Reset()
R.Define{ key = "good", label = "l", group = "qol", enabledPath = "good.enabled" }
local vOK = R.Validate({ good = {} })
check("inventaire sain",              vOK, true)

R._Reset()
R.Define{ key = "orphan", label = "l", group = "qol", enabledPath = "orphan.enabled" }
local vOK2, errs2 = R.Validate({})
check("dbKey absent des defaults",    vOK2, false)
check("une erreur remontée",          #errs2, 1)

R._Reset()
R.Define{ key = "a", label = "l", group = "qol", enabledPath = "a.enabled", deps = { "b" } }
R.Define{ key = "b", label = "l", group = "qol", enabledPath = "b.enabled", deps = { "a" } }
local vOK3, errs3 = R.Validate({ a = {}, b = {} })
check("cycle de dépendances détecté", vOK3, false)
local sawCycle = false
for _, e in ipairs(errs3) do if e:find("cycle") then sawCycle = true end end
check("cycle nommé dans l'erreur",    sawCycle, true)

R._Reset()
R.Define{ key = "esc", label = "l", group = "qol", enabledPath = "autre.enabled" }
local vOK4 = R.Validate({ esc = {}, autre = {} })
check("enabledPath hors dbKey rejeté", vOK4, false)

R._Reset()
R.Define{ key = "esc2", label = "l", group = "qol",
          anchors = { { id = "i", path = "ailleurs.position", shape = "anchor_relTo" } } }
local vOK5 = R.Validate({ esc2 = {}, ailleurs = {} })
check("ancre hors dbKey rejetée",      vOK5, false)

R._Reset()
R.Define{ key = "d1", label = "l", group = "qol",
          anchors = { { id = "shared", path = "d1.position", shape = "anchor_relTo" } } }
R.Define{ key = "d2", label = "l", group = "qol",
          anchors = { { id = "shared", path = "d2.position", shape = "anchor_relTo" } } }
local vOK6 = R.Validate({ d1 = {}, d2 = {} })
check("id d'ancre en double rejeté",   vOK6, false)

R._Reset()
R.Define{ key = "k1", label = "l", group = "qol", dbKey = "shared" }
R.Define{ key = "k2", label = "l", group = "qol", dbKey = "shared" }
local vOK7 = R.Validate({ shared = {} })
check("dbKey revendiqué deux fois",    vOK7, false)

-- ═══════════════════════════════════════════════════════════════════════
print("── 9. Découpe de charge utile (lot 6) ──")

R._Reset()
R.Define{ key = "keep", label = "l", group = "qol",     enabledPath = "keep.enabled" }
R.Define{ key = "drop", label = "l", group = "qol",     enabledPath = "drop.enabled" }
R.Define{ key = "gen",  label = "l", group = "general", enabledPath = "gen.enabled" }
R.Define{ key = "priv", internal = true }

local payload = { keep = { v = 1 }, drop = { v = 2 }, gen = { v = 3 }, priv = { v = 4 } }
local slice = R.Slice(payload, { "keep", "gen" })
check("découpe garde le demandé",     slice.keep.v, 1)
check("découpe écarte le reste",      slice.drop,   nil)
check("découpe ignore l'inconnu",     next(R.Slice(payload, { "ghost" })), nil)

local desc = R.DescribePayload(payload)
check("charge décrite par groupe",    #desc, 2)
local total = 0
for _, g in ipairs(desc) do total = total + #g.modules end
check("internes jamais proposés",     total, 3)

local partial = R.DescribePayload({ keep = {} })
check("groupe vide non proposé",      #partial, 1)
check("seul le module présent",       #partial[1].modules, 1)

-- ═══════════════════════════════════════════════════════════════════════
print("── 10. Liaison de l'implémentation ──")

R._Reset()
R.Define{ key = "bound", label = "l", group = "qol", enabledPath = "bound.enabled" }
local impl = { Enable = function() end }
check("Bind sur manifeste connu",     R.Bind("bound", impl), true)
check("implémentation attachée",      R.Get("bound").impl,   impl)
check("Bind sur inconnu refusé",      R.Bind("nope", impl),  false)
R.BridgeLegacy({ bound = impl, nope = impl })
check("pont hérité sans casse",       R.Get("bound").impl,   impl)

-- ═══════════════════════════════════════════════════════════════════════
print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

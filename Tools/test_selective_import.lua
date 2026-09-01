-- Banc hors-jeu pour Core/SelectiveImport.lua.
--
-- Ce lot a une seule propriété qui compte vraiment, et tout le reste en
-- découle : **ce qui n'est pas coché ne doit pas bouger**. L'import
-- existant vidait TomoModDB avant d'écrire ; si celui-ci fait la moindre
-- chose de ce genre, il n'apporte rien et détruit du travail.
--
-- Deux autres points sont vérifiés de près :
--
--   * Le drapeau `differs`. Un profil complet porte les soixante-deux
--     modules ; sans lui, toutes les lignes se valent alors que trois
--     seulement apportent quelque chose.
--   * Les entrées non reconnues. Une charge utile venue d'une autre
--     version peut porter des clés qu'aucun manifeste ne revendique :
--     elles doivent être signalées, pas jetées en silence.
--
-- Usage : luajit Tools/test_selective_import.lua   (depuis la racine)

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-52s attendu=%-14s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

_G.GetLocale = function() return "enUS" end
_G.UIParent  = {}
_G.CreateFrame = function() return setmetatable({}, { __index = function() return function() end end }) end
_G.C_Timer   = { After = function() end, NewTicker = function() return { Cancel = function() end } end }
_G.InCombatLockdown = function() return false end
_G.hooksecurefunc = function() end
_G.issecretvalue  = function() return false end
_G.LibStub = function() return nil end
_G.StaticPopupDialogs, _G.SlashCmdList = {}, {}

assert(loadfile("Core/ModuleRegistry.lua"))()
assert(loadfile("Core/SelectiveImport.lua"))()
local R, SI = _G.TomoMod_Registry, _G.TomoMod_SelectiveImport

_G.TomoMod_MergeTables = function(dest, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dest[k]) ~= "table" then dest[k] = {} end
            TomoMod_MergeTables(dest[k], v)
        elseif dest[k] == nil then dest[k] = v end
    end
end

local reloadsAsked
local function ResetWorld()
    R._Reset()
    reloadsAsked = {}
    _G.TomoMod_Lifecycle = {
        Capability = function(key) return key == "lourd" and "reload" or "live" end,
        BeginBatch = function() end, EndBatch = function() end, ApplyAll = function() end,
        RequestReload = function(k) reloadsAsked[#reloadsAsked + 1] = k end,
    }
    _G.TomoMod_Defaults = {}
    _G.TomoModDB = {}
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. Comparaison profonde ──")

check("tables identiques",      SI.Differs({ a = 1 }, { a = 1 }),        false)
check("valeur différente",      SI.Differs({ a = 1 }, { a = 2 }),        true)
check("clé en plus à gauche",   SI.Differs({ a = 1, b = 2 }, { a = 1 }), true)
check("clé en plus à droite",   SI.Differs({ a = 1 }, { a = 1, b = 2 }), true)
check("imbriqué identique",     SI.Differs({ a = { b = { c = 1 } } }, { a = { b = { c = 1 } } }), false)
check("imbriqué différent",     SI.Differs({ a = { b = { c = 1 } } }, { a = { b = { c = 2 } } }), true)
check("cible absente",          SI.Differs({ a = 1 }, nil),              true)
check("types incompatibles",    SI.Differs({ a = 1 }, "texte"),          true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Arbre d'inspection ──")

ResetWorld()
R.Define{ key = "np",     label = "l_np",   group = "nameplates", enabledPath = "np.enabled" }
R.Define{ key = "uf",     label = "l_uf",   group = "unitframes", enabledPath = "uf.enabled" }
R.Define{ key = "cast",   label = "l_cast", group = "unitframes", enabledPath = "cast.enabled" }
R.Define{ key = "lourd",  label = "l_h",    group = "qol",        enabledPath = "lourd.enabled" }
R.Define{ key = "secret", internal = true }

TomoModDB.np    = { enabled = true,  taille = 10 }
TomoModDB.uf     = { enabled = true,  taille = 20 }
TomoModDB.cast   = { enabled = true,  taille = 30 }
TomoModDB.lourd  = { enabled = true }
TomoModDB.secret = { rien = 1 }

local payload = {
    np     = { enabled = true,  taille = 99 },   -- diffère
    uf     = { enabled = true,  taille = 20 },   -- identique
    lourd  = { enabled = false },                -- diffère ET reload
    secret = { rien = 2 },                       -- interne : jamais proposé
    inconnu_v5 = { x = 1 },                      -- aucun manifeste
    _profiles  = { named = {} },                 -- jamais importable
}

local groups, _, unknown = SI.Inspect(payload)
-- nameplates (np), unitframes (uf) et qol (lourd) portent quelque chose ;
-- cast est déclaré mais absent de la charge, donc son groupe le compte
-- sans lui et aucun groupe vide n'est proposé.
check("trois groupes peuplés", #groups, 3)

local rows = {}
for _, g in ipairs(groups) do
    for _, r in ipairs(g.modules) do rows[r.key] = r end
end
check("np proposé",              rows.np ~= nil,     true)
check("uf proposé",              rows.uf ~= nil,     true)
check("cast absent de la charge", rows.cast,          nil)
check("interne jamais proposé",  rows.secret,        nil)

check("np signalé modifié",      rows.np.differs,    true)
check("uf signalé identique",    rows.uf.differs,    false)
check("lourd modifié",           rows.lourd.differs, true)
check("lourd exige un reload",   rows.lourd.requiresReload, true)
check("np applicable à chaud",   rows.np.requiresReload,    false)

check("état actuel lu",          rows.lourd.enabledNow,       true)
check("état de la charge lu",    rows.lourd.enabledInPayload, false)

check("une entrée inconnue",     #unknown,   1)
check("c'est la bonne",          unknown[1], "inconnu_v5")

-- ═══════════════════════════════════════════════════════════════════════
print("── 3. Résumé et sélections ──")

local total, changed, reloads = SI.Summarize(groups)
check("total proposé",   total,   3)
check("dont modifiés",   changed, 2)
check("dont reloads",    reloads, 1)

local only = { np = true }
local t2, c2, r2 = SI.Summarize(groups, only)
check("résumé filtré : total",    t2, 1)
check("résumé filtré : modifiés", c2, 1)
check("résumé filtré : reloads",  r2, 0)

check("tout sélectionner",       #SI.AllKeys(groups),        3)
check("seulement ce qui change", #SI.AllKeys(groups, true),  2)
check("clés d'un groupe",        #SI.GroupKeys(groups, "unitframes"), 1)
check("groupe inexistant",       #SI.GroupKeys(groups, "skins"),      0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 4. Ce qui n'est pas coché ne bouge pas ──")

ResetWorld()
R.Define{ key = "pris",   label = "l", group = "qol", enabledPath = "pris.enabled" }
R.Define{ key = "laisse", label = "l", group = "qol", enabledPath = "laisse.enabled" }
TomoModDB.pris   = { enabled = true, marque = "avant" }
TomoModDB.laisse = { enabled = true, marque = "intact" }
TomoModDB.horsRegistre = { marque = "pas touché" }

local p2 = {
    pris   = { enabled = true, marque = "apres" },
    laisse = { enabled = true, marque = "ECRASE" },
}
local rep = SI.Apply(p2, { "pris" })

check("un module appliqué",       rep.applied,                1)
check("le coché est remplacé",    TomoModDB.pris.marque,      "apres")
check("le décoché est intact",    TomoModDB.laisse.marque,    "intact")
check("le hors-registre intact",  TomoModDB.horsRegistre.marque, "pas touché")

-- La table n'est jamais vidée : c'est toute la différence avec l'import
-- existant, et une régression ici détruirait le travail du joueur.
check("aucune clé disparue", TomoModDB.laisse ~= nil and TomoModDB.horsRegistre ~= nil, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 5. Refus et cas limites ──")

ResetWorld()
R.Define{ key = "mod",    label = "l", group = "qol", enabledPath = "mod.enabled" }
R.Define{ key = "interne", internal = true }
TomoModDB.mod = { v = 1 }

local rep2 = SI.Apply({ mod = { v = 2 }, interne = { v = 9 }, _profiles = { x = 1 } },
                      { "mod", "interne", "_profiles", "fantome" })
check("un seul appliqué",       rep2.applied, 1)
check("trois refusés",          rep2.skipped, 3)
check("interne non importé",    TomoModDB.interne, nil)
check("_profiles non importé",  TomoModDB._profiles, nil)

check("charge non-table",  SI.Apply(nil, { "mod" }).applied, 0)
check("clés non-table",    SI.Apply({ mod = {} }, nil).applied, 0)
check("liste vide",        SI.Apply({ mod = {} }, {}).applied,  0)
check("inspection du vide", #(select(1, SI.Inspect(nil))),      0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 6. Rechargements : seulement quand l'état bascule ──")

ResetWorld()
R.Define{ key = "lourd",  label = "l", group = "qol", enabledPath = "lourd.enabled" }
R.Define{ key = "leger",  label = "l", group = "qol", enabledPath = "leger.enabled" }
TomoModDB.lourd = { enabled = true,  couleur = "rouge" }
TomoModDB.leger = { enabled = true,  couleur = "rouge" }

-- Un réglage qui change sans toucher au flag : aucun rechargement, même
-- pour un module qui ne sait pas se désactiver à chaud.
local rep3 = SI.Apply({ lourd = { enabled = true, couleur = "bleu" },
                        leger = { enabled = true, couleur = "bleu" } },
                      { "lourd", "leger" })
check("changement cosmétique : 0 reload", #rep3.reloads, 0)
check("appliqué quand même",              rep3.applied,  2)
check("valeur bien écrite",               TomoModDB.lourd.couleur, "bleu")

-- Le flag bascule : seul le module sans chemin vivant en demande un.
ResetWorld()
R.Define{ key = "lourd", label = "l", group = "qol", enabledPath = "lourd.enabled" }
R.Define{ key = "leger", label = "l", group = "qol", enabledPath = "leger.enabled" }
TomoModDB.lourd = { enabled = true }
TomoModDB.leger = { enabled = true }
local rep4 = SI.Apply({ lourd = { enabled = false }, leger = { enabled = false } },
                      { "lourd", "leger" })
check("un seul reload",        #rep4.reloads,  1)
check("c'est le bon module",   rep4.reloads[1], "lourd")
check("demandé au moteur",     reloadsAsked[1], "lourd")

-- ═══════════════════════════════════════════════════════════════════════
print("── 7. Charge utile d'une version antérieure ──")

ResetWorld()
R.Define{ key = "mod", label = "l", group = "qol", enabledPath = "mod.enabled" }
_G.TomoMod_Defaults = { mod = { enabled = true, nouveau = "valeur v4", ancien = 1 } }
TomoModDB.mod = { enabled = true, nouveau = "valeur v4", ancien = 1 }

-- Un profil exporté avant l'ajout de `nouveau` ne le porte pas ; la
-- fusion doit le regarnir plutôt que laisser le module lire nil.
SI.Apply({ mod = { enabled = true, ancien = 42 } }, { "mod" })
check("valeur importée",       TomoModDB.mod.ancien,  42)
check("clé manquante regarnie", TomoModDB.mod.nouveau, "valeur v4")

print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

-- Banc hors-jeu pour les presets de disposition (lot 7).
--
-- Ce qui compte ici, c'est ce qui rentre. Un preset s'importe depuis une
-- chaine collee dans un canal public : il faut donc qu'une charge utile
-- hostile ou simplement cassee ne puisse decrire qu'une disposition, et
-- rien d'autre. Trois lignes de defense, testees separement :
--
--   1. copyStore ne recopie que des scalaires dans des enregistrements
--      plats -- ni fonction, ni table imbriquee, ni cycle.
--   2. Le domaine est VERIFIE, pas suppose : une disposition de plaque
--      appliquee a un cadre d'unite ne resoudrait rien et viderait le
--      cadre, ce qui se lit comme un bug et non comme une erreur.
--   3. Tout ce qui rentre repasse par Ensure, donc par l'assainissement
--      de chaque champ et la casse des cycles d'ancrage.

_G.TomoMod_Forge = { BRAND = { 0, 0, 0 } }
_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
_G.UnitExists = function() return true end
_G.UnitName = function() return "N" end
_G.UnitLevel = function() return 70 end
_G.UnitClass = function() return "Mage", "MAGE" end
_G.UnitRace = function() return "Orc" end
_G.UnitEffectiveLevel = function() return 70 end
_G.UnitClassification = function() return "elite" end
_G.GetGuildInfo = function() return "G" end
_G.TomoModDB = { forgeAssets = {} }

-- Codec factice : meme contrat que Forge.IO (entete + version verifies),
-- sans dependre de LibSerialize / LibDeflate qui n'existent pas hors jeu.
-- Coffre PARTAGE entre instances de codec : deux instances qui minteraient
-- la meme cle se voleraient mutuellement leurs charges, ce que le vrai
-- encodage (une chaine derivee du contenu) ne fait jamais.
local vault, seq = {}, 0

local function fakeIO()
    return {
        MakeCodec = function(header, version, label)
            local c = { header = header, version = version, label = label }
            function c.Encode(payload)
                if type(payload) ~= "table" then return nil, "Donnees invalides" end
                payload._header, payload._version = header, version
                seq = seq + 1
                local key = "ENC" .. seq
                -- Copie profonde : l'encodage reel serialise, donc l'appelant
                -- ne doit pas pouvoir muter la charge apres coup.
                local function deep(t)
                    local o = {}
                    for k, v in pairs(t) do o[k] = (type(v) == "table") and deep(v) or v end
                    return o
                end
                vault[key] = deep(payload)
                return key
            end
            function c.Decode(str)
                if type(str) ~= "string" or str == "" then return nil, "Chaine vide" end
                str = str:match("^%s*(.-)%s*$")
                local p = vault[str]
                if not p then return nil, "Decodage echoue" end
                if p._header ~= header then return nil, "Pas une chaine " .. label end
                if p._version > version then return nil, "Version incompatible" end
                return p
            end
            c._vault = vault
            return c
        end,
    }
end
TomoMod_Forge.IO = fakeIO()

assert(loadfile("Core/Forge/ForgeRegistry.lua"))()
assert(loadfile("Core/Forge/ForgeText.lua"))()
assert(loadfile("Core/Forge/ForgeAssets.lua"))()
assert(loadfile("Modules/Interface/UnitFrames/UFElements.lua"))()
assert(loadfile("Modules/Interface/NamePlates/NPElements.lua"))()

local R   = TomoMod_Forge.Registry
local A   = TomoMod_Forge.Assets
local UFE = TomoMod_UFElements
local NPE = TomoMod_NPElements
local D, ND = UFE.DOMAIN, NPE.DOMAIN

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-54s attendu=%-18s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

local function freshStore()
    local st = {}
    UFE.Ensure(st)
    return st
end

-- ═══════════════════════════════════════════════════════════════════════
print("── Noms ──")
check("nom espace nettoye", A.SanitizeName("  Mon preset  "), "Mon preset")
check("nom vide refuse", A.SanitizeName("   "), nil)
check("nom non-chaine refuse", A.SanitizeName(42), nil)
check("nom tronque a 40", #A.SanitizeName(string.rep("x", 80)), 40)

-- ═══════════════════════════════════════════════════════════════════════
print("── Enregistrer / lister / appliquer ──")
local st = freshStore()
st.name.x, st.name.point = 42, "RIGHT"
st.power.scale = 1.5
local k = R.AddInstance(D, st, "customText")
st[k].text = "[class]"

check("enregistrement", A.Save(D, "Compact", st), true)
check("nom vide refuse", (A.Save(D, "", st)), false)
check("store invalide refuse", (A.Save(D, "X", "pas une table")), false)
check("liste = 1", #A.List(D), 1)
check("Exists vrai", A.Exists(D, "Compact"), true)
check("Exists faux", A.Exists(D, "Absent"), false)

-- Le snapshot doit etre DETACHE : modifier le store apres coup ne doit pas
-- reecrire le preset.
st.name.x = 999
local st2 = freshStore()
check("application", A.Apply(D, "Compact", st2), true)
check("valeur d'ancrage restauree", st2.name.x, 42)
check("point restaure", st2.name.point, "RIGHT")
check("propriete restauree", st2.power.scale, 1.5)
check("instance restauree", st2[k] ~= nil, true)
check("modele d'instance restaure", st2[k].text, "[class]")

check("application sur nom inconnu", (A.Apply(D, "Absent", st2)), false)

print("── L'application remplace le jeu d'instances ──")
local st3 = freshStore()
local extra = R.AddInstance(D, st3, "customText")
A.Apply(D, "Compact", st3)
check("instance etrangere retiree", st3[extra] == nil or extra == k, true)
check("instance du preset presente", st3[k] ~= nil, true)

print("── Le store est modifie EN PLACE ──")
local st4 = freshStore()
local ref = st4
A.Apply(D, "Compact", st4)
check("meme table conservee", st4, ref)

-- ═══════════════════════════════════════════════════════════════════════
print("── Renommer / supprimer ──")
check("renommage", A.Rename(D, "Compact", "Dense"), true)
check("ancien nom parti", A.Exists(D, "Compact"), false)
check("nouveau nom present", A.Exists(D, "Dense"), true)
A.Save(D, "Autre", freshStore())
check("renommage vers un nom pris refuse", (A.Rename(D, "Autre", "Dense")), false)
check("suppression", A.Delete(D, "Autre"), true)
check("suppression d'un absent", A.Delete(D, "Autre"), false)

-- ═══════════════════════════════════════════════════════════════════════
print("── Cloisonnement des domaines ──")
local nst = {}
NPE.Ensure(nst)
A.Save(ND, "Plaque fine", nst)
check("domaine plaques : 1 preset", #A.List(ND), 1)
check("domaine cadres : inchange", #A.List(D), 1)
check("un nom de plaque n'existe pas cote cadres", A.Exists(D, "Plaque fine"), false)

-- ═══════════════════════════════════════════════════════════════════════
print("── Partage : aller-retour ──")
local str = A.Export(D, "Dense")
check("export produit une chaine", type(str), "string")
check("export d'un absent refuse", (A.Export(D, "Absent")), nil)

-- On repart d'un magasin vide, comme chez un autre joueur. La chaine de
-- plaque est regeneree apres coup, puisque le magasin la contenait.
local nstrKeep = A.Export(ND, "Plaque fine")
TomoModDB.forgeAssets = {}
local name, dom = A.Import(str, D)
check("import accepte", name, "Dense")
check("domaine rendu", dom, D)
local st5 = freshStore()
A.Apply(D, name, st5)
check("ancrage transmis", st5.name.x, 42)
check("propriete transmise", st5.power.scale, 1.5)
check("instance transmise", st5[k] ~= nil, true)
check("modele transmis", st5[k].text, "[class]")

print("── Import : collision de nom ──")
local str2 = A.Export(D, "Dense")
local name2 = A.Import(str2, D)
check("suffixe ajoute", name2, "Dense (2)")
check("les deux coexistent", #A.List(D), 2)

print("── Import : refus ──")
check("chaine vide", (A.Import("", D)), nil)
check("chaine inconnue", (A.Import("NIMPORTEQUOI", D)), nil)

-- Domaine verifie, pas suppose.
local nstr = nstrKeep
check("export plaque", type(nstr), "string")
local bad, why = A.Import(nstr, D)
check("disposition de plaque refusee cote cadres", bad, nil)
check("motif explicite", why ~= nil, true)
check("acceptee dans son propre domaine", (A.Import(nstr, ND)) ~= nil, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── Charge utile hostile ou cassee ──")
local codec = TomoMod_Forge.IO.MakeCodec(A.HEADER, A.VERSION, "AstralForge")
-- On fabrique une charge qui tente de faire passer une fonction, une table
-- imbriquee et une cle non-chaine.
local nasty = codec.Encode({
    domain = D,
    name   = "Piege",
    layout = {
        name = {
            point = "LEFT", relTo = "health", relPoint = "LEFT", x = 3, y = 0,
            evil    = function() error("execute") end,
            nested  = { deep = { deeper = true } },
        },
        [42] = { point = "LEFT" },
        ["level"] = "pas une table",
    },
})
local nname = A.Import(nasty, D)
check("import accepte apres nettoyage", nname, "Piege")
local st6 = freshStore()
A.Apply(D, nname, st6)
check("champ fonction supprime", st6.name.evil, nil)
check("table imbriquee supprimee", st6.name.nested, nil)
check("champ legitime conserve", st6.name.x, 3)
check("cle non-chaine ignoree", st6[42], nil)
check("enregistrement non-table ignore -> defaut", st6.level.point, "RIGHT")

print("── Ensure a le dernier mot sur ce qui rentre ──")
local cyc = codec.Encode({
    domain = D, name = "Boucle",
    layout = {
        name  = { point = "LEFT", relTo = "level",  relPoint = "LEFT", x = 0, y = 0 },
        level = { point = "LEFT", relTo = "name",   relPoint = "LEFT", x = 0, y = 0 },
        power = { point = "TOP",  relTo = "infoBar", relPoint = "BOTTOM", x = 0, y = 0 },
        raidIcon = { point = "PLOP", relTo = "health", relPoint = "TOP", x = "abc", y = 2 },
    },
})
local cname = A.Import(cyc, D)
local st7 = freshStore()
A.Apply(D, cname, st7)
check("boucle cassee a l'import",
    R.WouldCycle(D, st7, "name", st7.name.relTo), false)
check("cible interdite corrigee (liste blanche)", st7.power.relTo, "health")
check("point invalide corrige", st7.raidIcon.point, "BOTTOM")
check("x non numerique corrige", st7.raidIcon.x, 0)
check("les 9 elements fixes presents",
    (function() local n = 0
        for key in pairs(st7) do if not R.SplitKey(key) then n = n + 1 end end
        return n end)(), 9)

-- ═══════════════════════════════════════════════════════════════════════
print("── ExportStore : partager sans enregistrer ──")
local live = freshStore()
live.healthText.y = 17
local s2 = A.ExportStore(D, "Direct", live)
check("chaine produite", type(s2), "string")
TomoModDB.forgeAssets = {}
local n3 = A.Import(s2, D)
check("import du direct", n3, "Direct")
local st8 = freshStore()
A.Apply(D, n3, st8)
check("valeur transmise", st8.healthText.y, 17)

print(ok and "\nTOUS LES TESTS PASSENT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

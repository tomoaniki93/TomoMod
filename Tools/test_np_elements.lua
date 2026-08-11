-- Banc hors-jeu pour le domaine "nameplate" du registre AstralForge.
--
-- Deux choses a prouver ici.
--
--   1. Les 13 descripteurs reproduisent EXACTEMENT les ancrages que
--      CreatePlate codait en dur. C'est la garantie de non-regression :
--      un profil neuf doit rendre pixel pour pixel comme avant le lot.
--
--   2. Contrairement au domaine unitframe, ce domaine n'a AUCUNE liste
--      blanche statique. C'est justifie seulement si toute arete que le
--      moteur cree entre un hote et un element est aussi representee dans
--      le graphe -- sinon un cycle passerait a travers. On le verifie plutot
--      que de le supposer.

_G.TomoMod_Forge = { BRAND = { 0, 0, 0 } }
_G.TomoMod_L = setmetatable({}, { __index = function(_, k) return k end })
_G.TomoMod_RegisterLocale = function() end
_G.CopyTable = function(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = (type(v) == "table") and CopyTable(v) or v end
    return o
end
_G.GetPhysicalScreenSize = function() return 1920, 1080 end
_G.UnitClass = function() return "Warrior", "WARRIOR" end
_G.RAID_CLASS_COLORS = {}
_G.date = os.date
_G.geterrorhandler = function() return function() end end

local function loadNoBOM(path)
    local fh = assert(io.open(path, "rb"))
    local src = fh:read("*a")
    fh:close()
    return assert(loadstring(src:gsub("^\239\187\191", ""), "@" .. path))
end

local function Widget(name)
    return {
        _name = name, _pt = nil,
        ClearAllPoints = function(self) self._pt = nil end,
        SetPoint = function(self, point, rel, relPoint, x, y)
            self._pt = { point = point, rel = rel, relPoint = relPoint, x = x, y = y }
        end,
    }
end

local function MakePlate()
    local p = Widget("plate")
    p.health     = Widget("health")
    p.nameText   = Widget("nameText")
    p.hpNumber   = Widget("hpNumber")
    p.hpPercent  = Widget("hpPercent")
    p.levelText  = Widget("levelText")
    p.classFrame = Widget("classFrame")
    p.classText  = Widget("classText")
    p.questIcon  = Widget("questIcon")
    p.raidFrame  = Widget("raidFrame")
    p.castbar    = Widget("castbar")
    p.castbar.iconFrame   = Widget("castIcon")
    p.castbar.text        = Widget("castText")
    p.castbar.timer       = Widget("castTimer")
    p.castbar.shieldFrame = Widget("castShield")
    return p
end

loadNoBOM("Core/Utils.lua")()
loadNoBOM("Core/Forge/ForgeRegistry.lua")()
loadNoBOM("Modules/Interface/UnitFrames/UFElements.lua")()
loadNoBOM("Modules/Interface/NamePlates/NPElements.lua")()
loadNoBOM("Core/Database.lua")()

local R   = TomoMod_Forge.Registry
local NPE = TomoMod_NPElements
local D   = NPE.DOMAIN

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-54s attendu=%-14s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

-- ═══════════════════════════════════════════════════════════════════════
print("── Declaration du domaine ──")
check("13 elements", #NPE.List(), 13)
check("4 hotes", #NPE.ListHosts(), 4)
check("premier element : name", NPE.List()[1].id, "name")
check("dernier element : raidMarker", NPE.List()[13].id, "raidMarker")
check("domaines cloisonnes : unitframe intact", #TomoMod_UFElements.List(), 9)

-- ═══════════════════════════════════════════════════════════════════════
print("── Fidelite aux ancrages historiques de CreatePlate ──")
-- Table de reference relevee sur CreatePlate AVANT le lot. Toute
-- divergence ici est une regression visuelle.
local HISTORIQUE = {
    name       = { "BOTTOM",   "health",  "TOP",      0,  4 },
    hpNumber   = { "CENTER",   "health",  "CENTER",   0,  0 },
    hpPercent  = { "RIGHT",    "health",  "RIGHT",   -4,  0 },
    level      = { "RIGHT",    "health",  "LEFT",    -3,  0 },
    classIcon  = { "LEFT",     "health",  "LEFT",     2,  0 },
    classText  = { "LEFT",     "health",  "RIGHT",    3,  0 },
    castbar    = { "TOP",      "health",  "BOTTOM",   0,  0 },
    castIcon   = { "RIGHT",    "castbar", "LEFT",     0,  0 },
    castText   = { "LEFT",     "castbar", "LEFT",     5,  0 },
    castTimer  = { "RIGHT",    "castbar", "RIGHT",   -3,  0 },
    castShield = { "CENTER",   "castbar", "LEFT",     0,  0 },
    questIcon  = { "RIGHT",    "name",    "LEFT",    -1,  0 },
    raidMarker = { "TOPRIGHT", "health",  "TOPRIGHT", 2,  2 },
}
for id, ref in pairs(HISTORIQUE) do
    local d = R.Default(D, id)
    check(("%s : point"):format(id),    d and d.point,    ref[1])
    check(("%s : relTo"):format(id),    d and d.relTo,    ref[2])
    check(("%s : relPoint"):format(id), d and d.relPoint, ref[3])
    check(("%s : x"):format(id),        d and d.x,        ref[4])
    check(("%s : y"):format(id),        d and d.y,        ref[5])
end

-- ═══════════════════════════════════════════════════════════════════════
print("── Application sur une plaque complete ──")
local plate = MakePlate()
local store = {}
NPE.Ensure(store)
check("ApplyAll place les 13", NPE.ApplyAll(plate, store), 13)
check("name ancre a health", plate.nameText._pt.rel, plate.health)
check("castIcon ancre a castbar", plate.castbar.iconFrame._pt.rel, plate.castbar)
check("questIcon ancre au NOM (pas a health)", plate.questIcon._pt.rel, plate.nameText)
check("raidMarker point TOPRIGHT", plate.raidFrame._pt.point, "TOPRIGHT")
check("castShield relPoint LEFT", plate.castbar.shieldFrame._pt.relPoint, "LEFT")

-- Plaque amputee : la barre d'incantation n'existe pas encore.
local bare = MakePlate()
bare.castbar = nil
local store2 = {}
NPE.Ensure(store2)
check("sans castbar : 8 elements poses", NPE.ApplyAll(bare, store2), 8)

-- ═══════════════════════════════════════════════════════════════════════
print("── Absence de liste blanche : justifiee, pas supposee ──")
-- Aucun element du domaine ne declare de liste blanche...
for _, desc in ipairs(NPE.List()) do
    check(("%s : aucune liste blanche"):format(desc.id), desc._targetSet, nil)
end
-- ...ce qui n'est sain que si les trois hotes non structurels sont AUSSI
-- declares comme elements, donc presents dans le graphe de cycles.
for _, hostID in ipairs({ "health", "castbar", "name" }) do
    local isElement = (hostID == "health") or (R.Get(D, hostID) ~= nil)
    check(("hote %s couvert par le graphe"):format(hostID), isElement, true)
end
-- `health` est le seul hote sans element homonyme : il ne doit donc jamais
-- etre repositionne par personne, ce qui est le cas (aucun descripteur ne
-- le resout).
local healthIsElement = R.Get(D, "health") ~= nil
check("health reste purement structurel", healthIsElement, false)

-- Cycle utilisateur classique : castbar <-> castIcon.
local st3 = {}
NPE.Ensure(st3)
st3.castIcon.relTo = "castbar"
check("castbar -> castIcon fermerait la boucle",
    R.WouldCycle(D, st3, "castbar", "castIcon"), true)
local offered = {}
for _, t in ipairs(NPE.AllowedTargets("castbar", st3)) do offered[t.id] = true end
check("castIcon non propose a castbar", offered.castIcon, nil)
check("health propose a castbar", offered.health, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── Migration npElementsV1 ──")
_G.TomoModDB = {
    nameplates = {
        raidIconAnchor = "BOTTOMLEFT",
        raidIconX      = -7,
        raidIconY      = 11,
        raidIconSize   = 30,
    },
    unitFrames = { player = {}, target = {}, targettarget = {}, pet = {}, focus = {} },
}
TomoMod_InitDatabase()
local np = TomoModDB.nameplates
check("raidMarker.point reporte", np.elements.raidMarker.point, "BOTTOMLEFT")
check("raidMarker.relPoint reporte (meme point)", np.elements.raidMarker.relPoint, "BOTTOMLEFT")
check("raidMarker.x reporte", np.elements.raidMarker.x, -7)
check("raidMarker.y reporte", np.elements.raidMarker.y, 11)
check("raidIconAnchor supprime", np.raidIconAnchor, nil)
check("raidIconX supprime", np.raidIconX, nil)
check("raidIconY supprime", np.raidIconY, nil)
check("raidIconSize PRESERVE (taille, pas position)", np.raidIconSize, 30)
check("les 13 elements presents",
    (function() local n = 0; for _ in pairs(np.elements) do n = n + 1 end; return n end)(), 13)
check("drapeau de migration pose", TomoModDB._migrations.npElementsV1, true)

print("── Profil neuf : defauts du registre ──")
_G.TomoModDB = { nameplates = {}, unitFrames = { player = {} } }
TomoMod_InitDatabase()
check("raidMarker = defaut registre", TomoModDB.nameplates.elements.raidMarker.point, "TOPRIGHT")
check("castText = defaut registre", TomoModDB.nameplates.elements.castText.x, 5)

print("── Normalisation additive et idempotente ──")
TomoModDB.nameplates.elements.castText.x = 42
TomoModDB.nameplates.elements.castTimer  = nil
TomoMod_NormalizeAllElements()
check("valeur utilisateur conservee", TomoModDB.nameplates.elements.castText.x, 42)
check("element manquant recree", type(TomoModDB.nameplates.elements.castTimer), "table")

TomoModDB.nameplates.elements.level = { point = "NULLE_PART", x = "abc" }
TomoMod_NormalizeNPElements()
check("point invalide corrige", TomoModDB.nameplates.elements.level.point, "RIGHT")
check("x non numerique corrige", TomoModDB.nameplates.elements.level.x, -3)

_G.TomoModDB = {}
check("DB sans nameplates : pas de crash", TomoMod_NormalizeNPElements(), false)

print(ok and "\nTOUS LES TESTS PASSENT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

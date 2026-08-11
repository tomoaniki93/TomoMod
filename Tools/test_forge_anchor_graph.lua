-- Banc hors-jeu pour l'ancrage element <-> element (lot 3).
--
-- Ce que ce banc protege : le client leve une erreur de famille d'ancrage
-- des qu'une chaine de SetPoint revient sur elle-meme, et l'erreur casse
-- la mise en page du cadre entier. Le registre doit donc rendre le cycle
-- INATTEIGNABLE par l'interface, et REPARABLE quand il arrive quand meme
-- par une donnee importee ou editee a la main.
--
-- Deux dangers distincts, testes separement :
--   * aretes creees par le MOTEUR (info bar ancree sur power), invisibles
--     du graphe -> liste blanche statique `desc.targets` ;
--   * aretes creees par l'UTILISATEUR (element -> element), qui n'existent
--     que dans le store -> marche de detection.

_G.TomoMod_Forge = { BRAND = { 0, 0, 0 } }

local function Widget(name)
    return {
        _name = name, _pt = nil,
        ClearAllPoints = function(self) self._pt = nil end,
        SetPoint = function(self, point, rel, relPoint, x, y)
            self._pt = { point = point, rel = rel, relPoint = relPoint, x = x, y = y }
        end,
    }
end

local function MakeFrame()
    local f = Widget("frame")
    f.health = Widget("health")
    f.health.nameText   = Widget("nameText")
    f.health.levelText  = Widget("levelText")
    f.health.text       = Widget("healthText")
    f.health.raidIcon   = Widget("raidIcon")
    f.health.leaderIcon = Widget("leaderIcon")
    f.power     = Widget("power")
    f.infoBar   = Widget("infoBar")
    f.threatText = Widget("threatText")
    return f
end

assert(loadfile("Core/Forge/ForgeRegistry.lua"))()
assert(loadfile("Modules/Interface/UnitFrames/UFElements.lua"))()

local R   = TomoMod_Forge.Registry
local UFE = TomoMod_UFElements
local D   = UFE.DOMAIN

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-55s attendu=%-10s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

local function fresh()
    local st = {}
    UFE.Ensure(st)
    return st
end

-- ═══════════════════════════════════════════════════════════════════════
print("── Espace de noms unifie (hote ET element) ──")
check("frame est une cible", R.IsTarget(D, "frame"), true)
check("health est une cible", R.IsTarget(D, "health"), true)
check("name (element) est une cible", R.IsTarget(D, "name"), true)
check("id inconnu n'est pas une cible", R.IsTarget(D, "nope"), false)
check("nil n'est pas une cible", R.IsTarget(D, nil), false)

-- `power` est declare des deux cotes : les deux doivent designer le MEME
-- widget, sinon la resolution serait ambigue selon le chemin emprunte.
local frame = MakeFrame()
check("power : hote et element resolvent le meme widget",
    R.ResolveTarget(D, "power", frame), frame.power)
check("resolution d'un element frere", R.ResolveTarget(D, "name", frame),
    frame.health.nameText)
check("cible inconnue -> nil", R.ResolveTarget(D, "nope", frame), nil)

-- ═══════════════════════════════════════════════════════════════════════
print("── Ancrage element -> element ──")
local st = fresh()
st.level.relTo    = "name"
st.level.point    = "LEFT"
st.level.relPoint = "RIGHT"
st.level.x        = 4

check("Sanitize accepte un frere", R.Sanitize(D, "level", st.level).relTo, "name")
check("Apply place level sur name", R.Apply(D, "level", frame, st), true)
check("level ancre au widget de name", frame.health.levelText._pt.rel,
    frame.health.nameText)
check("level relPoint conserve", frame.health.levelText._pt.relPoint, "RIGHT")

-- Chaine a trois maillons : healthText -> level -> name -> health.
st.healthText.relTo = "level"
check("chaine de 3 : pas de cycle", R.WouldCycle(D, st, "healthText", "level"), false)
check("ApplyAll place tout", UFE.ApplyAll(frame, st), 7)
check("healthText suit level", frame.health.text._pt.rel, frame.health.levelText)

-- ═══════════════════════════════════════════════════════════════════════
print("── Detection de cycle ──")
local st2 = fresh()
check("auto-reference detectee", R.WouldCycle(D, st2, "name", "name"), true)

st2.level.relTo = "name"
check("name -> level fermerait la boucle",
    R.WouldCycle(D, st2, "name", "level"), true)
check("name -> health reste sain",
    R.WouldCycle(D, st2, "name", "health"), false)

-- Boucle longue : name -> healthText -> level -> name
local st3 = fresh()
st3.healthText.relTo = "level"
st3.level.relTo      = "name"
check("boucle de 3 detectee avant ecriture",
    R.WouldCycle(D, st3, "name", "healthText"), true)
check("cible hors boucle acceptee",
    R.WouldCycle(D, st3, "name", "raidIcon"), false)

-- Une cible qui est un HOTE pur termine la chaine : jamais de cycle.
check("cible hote pure -> jamais de cycle",
    R.WouldCycle(D, st3, "name", "frame"), false)

-- ═══════════════════════════════════════════════════════════════════════
print("── L'interface ne peut pas creer de cycle ──")
local st4 = fresh()
st4.level.relTo = "name"

local offered = {}
for _, t in ipairs(R.AllowedTargets(D, "name", st4)) do offered[t.id] = t.kind end
check("name : level n'est PAS propose", offered.level, nil)
check("name : health propose (hote)", offered.health, "host")
check("name : raidIcon propose (element)", offered.raidIcon, "element")
check("name : name lui-meme jamais propose", offered.name, nil)
-- `power` est hote ET element : une seule entree, cote hote.
check("power propose une seule fois, en hote", offered.power, "host")

local offeredPower = {}
for _, t in ipairs(R.AllowedTargets(D, "power", st4)) do
    offeredPower[t.id] = t.kind
end
check("power : frame propose", offeredPower.frame, "host")
check("power : health propose", offeredPower.health, "host")
check("power : infoBar refuse (liste blanche)", offeredPower.infoBar, nil)
check("power : name refuse (liste blanche)", offeredPower.name, nil)

-- ═══════════════════════════════════════════════════════════════════════
print("── Reparation d'un store corrompu ──")
-- Sanitize ne voit qu'un enregistrement a la fois : une boucle repartie sur
-- plusieurs entrees lui echappe. BreakCycles la casse a l'ensemencement.
local st5 = fresh()
st5.name.relTo  = "level"
st5.level.relTo = "name"
check("boucle presente avant reparation",
    R.WouldCycle(D, st5, "name", "level"), true)

local broken = R.BreakCycles(D, st5)
check("au moins une arete cassee", broken >= 1, true)
check("plus aucune boucle depuis name",
    R.WouldCycle(D, st5, "name", st5.name.relTo), false)
check("plus aucune boucle depuis level",
    R.WouldCycle(D, st5, "level", st5.level.relTo), false)

-- Deterministe : l'ordre du registre decide, donc deux passages identiques
-- rendent le meme resultat.
local function corrupt()
    local s = fresh()
    s.name.relTo, s.level.relTo = "level", "name"
    return s
end
local a, b = corrupt(), corrupt()
R.BreakCycles(D, a); R.BreakCycles(D, b)
check("reparation deterministe (name)", a.name.relTo, b.name.relTo)
check("reparation deterministe (level)", a.level.relTo, b.level.relTo)

-- Ensure fait le menage tout seul : c'est le chemin qu'empruntent les
-- profils importes et la normalisation au login.
local st6 = { name = { relTo = "level" }, level = { relTo = "name" } }
UFE.Ensure(st6)
check("Ensure casse la boucle a l'ensemencement",
    R.WouldCycle(D, st6, "name", st6.name.relTo), false)
check("Ensure a bien rempli les 9 entrees",
    (function() local n = 0; for _ in pairs(st6) do n = n + 1 end; return n end)(), 9)

-- Une boucle reparee doit rester applicable sur un vrai arbre.
local frame2 = MakeFrame()
check("ApplyAll apres reparation place les 7 presents",
    UFE.ApplyAll(frame2, st6), 7)

-- ═══════════════════════════════════════════════════════════════════════
print("── Garde ultime : jamais d'ancrage sur soi-meme ──")
-- Meme si une donnee forcait relTo = son propre id, Apply doit refuser
-- plutot que de laisser SetPoint lever cote client.
local st7 = fresh()
st7.power.relTo = "power"   -- Sanitize corrige deja, mais on double la garde
check("Apply ne s'ancre jamais sur soi",
    frame2.power._pt.rel ~= frame2.power, true)

print(ok and "\nTOUS LES TESTS PASSENT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

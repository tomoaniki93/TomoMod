-- Banc hors-jeu pour Forge.Registry + les descripteurs UnitFrames.
-- Vérifie le contrat du registre (tri, defaults, assainissement, repli
-- d'hôte) puis le pose sur un faux arbre de widgets pour contrôler que
-- chaque élément atterrit sur le bon couple d'ancrage.

_G.TomoMod_Forge = { BRAND = { 0, 0, 0 } }

-- ── Faux widget : mémorise le dernier SetPoint ────────────────────────
local function Widget(name)
    return {
        _name = name,
        _pt   = nil,
        ClearAllPoints = function(self) self._pt = nil end,
        SetPoint = function(self, point, rel, relPoint, x, y)
            self._pt = { point = point, rel = rel, relPoint = relPoint, x = x, y = y }
        end,
    }
end

local function MakeFrame(opts)
    opts = opts or {}
    local f = Widget("frame")
    f.health = Widget("health")
    f.health.nameText   = Widget("nameText")
    f.health.levelText  = Widget("levelText")
    f.health.text       = Widget("healthText")
    f.health.raidIcon   = Widget("raidIcon")
    f.health.leaderIcon = Widget("leaderIcon")
    if opts.power ~= false then f.power = Widget("power") end
    if opts.infoBar then f.infoBar = Widget("infoBar") end
    if opts.threatText ~= false then f.threatText = Widget("threatText") end
    return f
end

assert(loadfile("Core/Forge/ForgeRegistry.lua"))()
assert(loadfile("Modules/Interface/UnitFrames/UFElements.lua"))()

local R   = TomoMod_Forge.Registry
local UFE = TomoMod_UFElements

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-52s attendu=%-14s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

print("── Registre : déclaration ──")
check("9 éléments enregistrés", #UFE.List(), 9)
check("4 hôtes enregistrés", #UFE.ListHosts(), 4)
check("tri par order : 1er = name", UFE.List()[1].id, "name")
check("tri par order : dernier = threatText", UFE.List()[9].id, "threatText")
check("auras intercale a order 65", UFE.List()[7].id, "auras")
check("enemyBuffs juste apres", UFE.List()[8].id, "enemyBuffs")

print("── Registre : valeurs par défaut ──")
local d = R.Default("unitframe", "name")
check("name.point", d.point, "LEFT")
check("name.relTo", d.relTo, "health")
check("name.x", d.x, 6)
check("power : ancrage TOP/BOTTOM", R.Default("unitframe", "power").relPoint, "BOTTOM")
check("leaderIcon.point", R.Default("unitframe", "leaderIcon").point, "BOTTOMLEFT")
check("élément inconnu -> nil", R.Default("unitframe", "nope"), nil)

print("── Registre : assainissement ──")
local s = R.Sanitize("unitframe", "name", { point = "PLOP", relTo = "health", x = "12", y = 3 })
check("point invalide -> défaut", s.point, "LEFT")
check("x chaîne numérique -> nombre", s.x, 12)
check("y conservé", s.y, 3)
local s2 = R.Sanitize("unitframe", "name", { relTo = "inexistant" })
check("hôte inconnu -> défaut", s2.relTo, "health")
local s3 = R.Sanitize("unitframe", "name", "pas une table")
check("cfg non-table -> défaut complet", s3.point, "LEFT")
local s4 = R.Sanitize("unitframe", "healthText", { point = "TOPRIGHT", relPoint = "TOPRIGHT" })
check("point valide conservé", s4.point, "TOPRIGHT")

print("── Registre : Ensure ──")
local store = { name = { x = 99 } }
R.Ensure("unitframe", store)
check("entrée existante assainie (x gardé)", store.name.x, 99)
check("entrée existante complétée (point)", store.name.point, "LEFT")
check("entrée absente créée", store.threatText ~= nil, true)
local n = 0
for _ in pairs(store) do n = n + 1 end
check("Ensure crée exactement 9 entrées", n, 9)

print("── Application sur un arbre complet ──")
local frame = MakeFrame()
UFE.Ensure(frame._store or {})
local st = {}
UFE.Ensure(st)
check("ApplyAll place les 7 éléments présents", UFE.ApplyAll(frame, st), 7)
check("name ancré à health", frame.health.nameText._pt.rel, frame.health)
check("name point", frame.health.nameText._pt.point, "LEFT")
check("name x", frame.health.nameText._pt.x, 6)
check("level point", frame.health.levelText._pt.point, "RIGHT")
check("level x", frame.health.levelText._pt.x, -6)
check("power point", frame.power._pt.point, "TOP")
check("power relPoint", frame.power._pt.relPoint, "BOTTOM")
check("raidIcon relPoint", frame.health.raidIcon._pt.relPoint, "TOP")
check("leaderIcon y", frame.health.leaderIcon._pt.y, 0)
check("threatText ancré à health", frame.threatText._pt.rel, frame.health)

print("── Application : valeur utilisateur ──")
st.healthText.point, st.healthText.relPoint = "TOPRIGHT", "TOPRIGHT"
st.healthText.x, st.healthText.y = -4, -2
R.Apply("unitframe", "healthText", frame, st)
check("point utilisateur appliqué", frame.health.text._pt.point, "TOPRIGHT")
check("x utilisateur appliqué", frame.health.text._pt.x, -4)

print("── Application : widget ou hôte manquant ──")
local bare = MakeFrame({ power = false, threatText = false })
local st2 = {}
UFE.Ensure(st2)
check("arbre sans power/threat : 5 éléments posés", UFE.ApplyAll(bare, st2), 5)
check("power absent -> Apply rend false", R.Apply("unitframe", "power", bare, st2), false)

local frame2 = MakeFrame({ power = false })
local st3 = {}
UFE.Ensure(st3)
st3.name.relTo = "power"          -- hôte valide dans le registre, absent ici
check("hôte manquant -> repli sur le défaut",
    R.Apply("unitframe", "name", frame2, st3), true)
check("repli ancre bien sur health", frame2.health.nameText._pt.rel, frame2.health)

check("frame nil -> false", R.Apply("unitframe", "name", nil, st3), false)
check("domaine inconnu -> 0 élément", R.ApplyAll("nameplate", frame, {}), 0)

print(ok and "\nTOUS LES TESTS PASSENT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

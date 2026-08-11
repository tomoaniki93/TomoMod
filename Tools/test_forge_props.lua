-- Banc hors-jeu pour les proprietes par element (lot 5).
--
-- Trois invariants a tenir.
--
--   1. CAPACITES PAR TYPE. SetScale n'existe pas sur une region, SetFont
--      pas sur une texture. Le registre ne doit ecrire que ce que le widget
--      sait honorer, et la DB ne doit pas se remplir de cles que personne
--      ne lit.
--
--   2. IDEMPOTENCE. ApplyAll repasse a chaque rafraichissement (et pour les
--      plaques, a chaque UpdateSize). Une propriete appliquee en DELTA
--      derivrait a chaque passage -- c'est exactement le bug de double
--      comptage qui avait fait fuir les auras. Tout est absolu ici, et on
--      le verifie en appliquant trois fois de suite.
--
--   3. NON-REGRESSION. Un profil existant n'a aucune de ces cles : les
--      valeurs par defaut doivent etre neutres (opacite 1, echelle 1,
--      police heritee), sinon le lot changerait l'apparence de tout le
--      monde sans rien demander.

_G.TomoMod_Forge = { BRAND = { 0, 0, 0 } }

-- ── Widgets factices, par type ────────────────────────────────────────
local function base(name)
    return {
        _name = name, _alpha = nil, _scale = nil, _pt = nil,
        ClearAllPoints = function(self) self._pt = nil end,
        SetPoint = function(self, p, rel, rp, x, y)
            self._pt = { point = p, rel = rel, relPoint = rp, x = x, y = y }
        end,
        SetAlpha = function(self, a) self._alpha = a end,
    }
end

local function Frame(name)
    local o = base(name)
    o.SetScale = function(self, s) self._scale = s end
    return o
end

local function Texture(name)
    return base(name)   -- ni SetScale ni SetFont
end

local function FontString(name, family, size, flags)
    local o = base(name)
    o._font = { family or "F", size or 12, flags or "OUTLINE" }
    o.GetFont = function(self) return self._font[1], self._font[2], self._font[3] end
    o.SetFont = function(self, f, sz, fl) self._font = { f, sz, fl } end
    return o
end

local function MakeFrame()
    local f = Frame("frame")
    f.health = Frame("health")
    f.health.nameText   = FontString("nameText")
    f.health.levelText  = FontString("levelText")
    f.health.text       = FontString("healthText")
    f.health.raidIcon   = Texture("raidIcon")
    f.health.leaderIcon = Texture("leaderIcon")
    f.power      = Frame("power")
    f.threatText = FontString("threatText")
    return f
end

assert(loadfile("Core/Forge/ForgeRegistry.lua"))()
assert(loadfile("Modules/Interface/UnitFrames/UFElements.lua"))()
assert(loadfile("Modules/Interface/NamePlates/NPElements.lua"))()

local R   = TomoMod_Forge.Registry
local UFE = TomoMod_UFElements
local NPE = TomoMod_NPElements
local D   = UFE.DOMAIN

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-54s attendu=%-12s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

-- ═══════════════════════════════════════════════════════════════════════
print("── Capacites par type de widget ──")
check("power (frame) : echelle", R.HasProp(D, "power", "scale"), true)
check("power (frame) : opacite", R.HasProp(D, "power", "alpha"), true)
check("power (frame) : PAS de taille de police",
    R.HasProp(D, "power", "fontSize"), false)

check("name (chaine) : taille de police", R.HasProp(D, "name", "fontSize"), true)
check("name (chaine) : opacite", R.HasProp(D, "name", "alpha"), true)
check("name (chaine) : PAS d'echelle", R.HasProp(D, "name", "scale"), false)

check("raidIcon (texture) : opacite", R.HasProp(D, "raidIcon", "alpha"), true)
check("raidIcon (texture) : PAS d'echelle", R.HasProp(D, "raidIcon", "scale"), false)
check("raidIcon (texture) : PAS de police", R.HasProp(D, "raidIcon", "fontSize"), false)

check("Props(power) = 2", #R.Props(D, "power"), 2)
check("Props(name) = 2", #R.Props(D, "name"), 2)
check("Props(raidIcon) = 1", #R.Props(D, "raidIcon"), 1)
check("Props(element inconnu) = 0", #R.Props(D, "nope"), 0)

-- ═══════════════════════════════════════════════════════════════════════
print("── La DB ne recoit que les cles utiles ──")
local dPower, dName, dIcon = R.Default(D, "power"), R.Default(D, "name"), R.Default(D, "raidIcon")
check("power a scale", dPower.scale, 1)
check("power n'a PAS fontSize", dPower.fontSize, nil)
check("name a fontSize (0 = herite)", dName.fontSize, 0)
check("name n'a PAS scale", dName.scale, nil)
check("texture n'a ni scale ni fontSize",
    (dIcon.scale == nil) and (dIcon.fontSize == nil), true)
check("toutes ont alpha", (dPower.alpha == 1) and (dName.alpha == 1) and (dIcon.alpha == 1), true)

-- ═══════════════════════════════════════════════════════════════════════
print("── Defauts neutres : aucune regression visuelle ──")
for _, dom in ipairs({ UFE, NPE }) do
    for _, desc in ipairs(dom.List()) do
        local d = R.Default(dom.DOMAIN, desc.id)
        check(("%s/%s : opacite neutre"):format(dom.DOMAIN, desc.id), d.alpha, 1)
        if d.scale ~= nil then
            check(("%s/%s : echelle neutre"):format(dom.DOMAIN, desc.id), d.scale, 1)
        end
        if d.fontSize ~= nil then
            check(("%s/%s : police heritee"):format(dom.DOMAIN, desc.id), d.fontSize, 0)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════
print("── Bornage des valeurs ──")
check("alpha > 1 borne", R.Sanitize(D, "name", { alpha = 5 }).alpha, 1)
check("alpha < 0 borne", R.Sanitize(D, "name", { alpha = -2 }).alpha, 0)
check("alpha texte -> defaut", R.Sanitize(D, "name", { alpha = "plop" }).alpha, 1)
check("alpha chaine numerique acceptee", R.Sanitize(D, "name", { alpha = "0.5" }).alpha, 0.5)
check("scale enorme borne", R.Sanitize(D, "power", { scale = 99 }).scale, 4)
check("scale nul borne", R.Sanitize(D, "power", { scale = 0 }).scale, 0.25)
check("fontSize 0 conserve (sentinelle)", R.Sanitize(D, "name", { fontSize = 0 }).fontSize, 0)
check("fontSize 3 remonte au minimum", R.Sanitize(D, "name", { fontSize = 3 }).fontSize, 6)
check("fontSize 500 borne", R.Sanitize(D, "name", { fontSize = 500 }).fontSize, 64)
check("propriete non supportee ignoree",
    R.Sanitize(D, "name", { scale = 3 }).scale, nil)
check("propriete non supportee ignoree (texture)",
    R.Sanitize(D, "raidIcon", { fontSize = 20 }).fontSize, nil)

-- ═══════════════════════════════════════════════════════════════════════
print("── Application sur un vrai arbre ──")
local frame = MakeFrame()
local st = {}
UFE.Ensure(st)
st.power.scale   = 1.5
st.power.alpha   = 0.4
st.name.fontSize = 18
st.name.alpha    = 0.8
st.raidIcon.alpha = 0.25

check("ApplyAll place les 7", UFE.ApplyAll(frame, st), 7)
check("echelle appliquee au frame", frame.power._scale, 1.5)
check("opacite appliquee au frame", frame.power._alpha, 0.4)
check("taille de police appliquee", select(2, frame.health.nameText:GetFont()), 18)
check("famille de police preservee", (frame.health.nameText:GetFont()), "F")
check("flags de police preserves", select(3, frame.health.nameText:GetFont()), "OUTLINE")
check("opacite appliquee a la chaine", frame.health.nameText._alpha, 0.8)
check("opacite appliquee a la texture", frame.health.raidIcon._alpha, 0.25)
check("texture jamais mise a l'echelle", frame.health.raidIcon._scale, nil)

-- fontSize = 0 : le module garde la main.
local frame2 = MakeFrame()
local st2 = {}
UFE.Ensure(st2)
UFE.ApplyAll(frame2, st2)
check("fontSize 0 : taille du module intacte",
    select(2, frame2.health.nameText:GetFont()), 12)

-- ═══════════════════════════════════════════════════════════════════════
print("── Idempotence : trois passages consecutifs ──")
UFE.ApplyAll(frame, st)
UFE.ApplyAll(frame, st)
check("echelle stable apres 3x", frame.power._scale, 1.5)
check("opacite stable apres 3x", frame.power._alpha, 0.4)
check("police stable apres 3x", select(2, frame.health.nameText:GetFont()), 18)

-- Le module reecrit la police entre deux passages (cas reel : ApplyVisuals
-- pose la taille de base, puis le registre repasse). La surcharge doit
-- regagner, et la famille suivre le module.
frame.health.nameText:SetFont("AUTRE", 9, "")
UFE.ApplyAll(frame, st)
check("surcharge regagne apres reecriture du module",
    select(2, frame.health.nameText:GetFont()), 18)
check("famille du module reprise",
    (frame.health.nameText:GetFont()), "AUTRE")

-- ═══════════════════════════════════════════════════════════════════════
print("── Ensure : ajout additif sur un profil existant ──")
-- Un profil d'avant le lot n'a que l'ancrage.
local legacy = {
    name  = { point = "LEFT", relTo = "health", relPoint = "LEFT", x = 14, y = -3 },
    power = { point = "TOP",  relTo = "health", relPoint = "BOTTOM", x = 2, y = 0 },
}
UFE.Ensure(legacy)
check("ancrage utilisateur preserve", legacy.name.x, 14)
check("opacite ajoutee", legacy.name.alpha, 1)
check("fontSize ajoutee neutre", legacy.name.fontSize, 0)
check("echelle ajoutee au frame", legacy.power.scale, 1)
check("pas d'echelle sur la chaine", legacy.name.scale, nil)

-- ═══════════════════════════════════════════════════════════════════════
print("── Domaine plaques : repartition des types ──")
check("np castbar : echelle", R.HasProp(NPE.DOMAIN, "castbar", "scale"), true)
check("np castText : police", R.HasProp(NPE.DOMAIN, "castText", "fontSize"), true)
check("np castText : PAS d'echelle", R.HasProp(NPE.DOMAIN, "castText", "scale"), false)
check("np questIcon (texture) : opacite seule", #R.Props(NPE.DOMAIN, "questIcon"), 1)
check("np raidMarker (frame) : echelle", R.HasProp(NPE.DOMAIN, "raidMarker", "scale"), true)

print(ok and "\nTOUS LES TESTS PASSENT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

-- Banc hors-jeu pour Core/LayoutEngine.lua.
--
-- Deux propriétés valent plus que toutes les autres ici :
--
--   1. Une migration ne déplace rien. Un joueur qui met à jour doit
--      retrouver son écran à l'identique ; convertir la forme sans
--      toucher au résultat visuel est la seule façon d'y arriver.
--   2. Une position enregistrée puis relue sur le même écran revient
--      au pixel près. Sans ça, chaque cycle de sauvegarde introduit une
--      dérive, et l'élément descend d'un cran à chaque connexion.
--
-- Usage : luajit Tools/test_layout_engine.lua   (depuis la racine)

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-54s attendu=%-12s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end
local function near(label, got, want, tol)
    tol = tol or 0.01
    local good = type(got) == "number" and math.abs(got - want) <= tol
    if not good then ok = false end
    print(("  %s %-54s attendu=~%-11s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

-- ── Écran simulé ─────────────────────────────────────────────────────
local SCREEN = { w = 2560, h = 1440 }
_G.UIParent = {
    GetWidth  = function() return SCREEN.w end,
    GetHeight = function() return SCREEN.h end,
    GetEffectiveScale = function() return 1 end,
}

-- Une frame dont on contrôle les bords, comme après un drag.
local function Frame(left, bottom, w, h, scale)
    local f = { _pts = {} }
    f.GetLeft   = function() return left end
    f.GetBottom = function() return bottom end
    f.GetRight  = function() return left + w end
    f.GetTop    = function() return bottom + h end
    f.GetEffectiveScale = function() return scale or 1 end
    f.ClearAllPoints = function(self) self._pts = {} end
    f.SetPoint = function(self, p, rel, ap, x, y)
        self._pts = { point = p, anchor = ap, x = x, y = y }
    end
    return f
end

assert(loadfile("Core/LayoutEngine.lua"))()
local Layout = _G.TomoMod_Layout

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. Rescale : les maths pures ──")

local x, y = Layout.Rescale(200, 100, 2560, 1440, 1920, 1080)
near("x mis à l'échelle 2560->1920", x, 150)
near("y mis à l'échelle 1440->1080", y, 75)

x, y = Layout.Rescale(200, 100, 2560, 1440, 2560, 1440)
check("même écran : x intact", x, 200)
check("même écran : y intact", y, 100)

-- Le cas décisif : sans référence enregistrée, on n'invente pas.
x, y = Layout.Rescale(200, 100, nil, nil, 1920, 1080)
check("sans référence : x intact", x, 200)
check("sans référence : y intact", y, 100)

x, y = Layout.Rescale(200, 100, 0, 0, 1920, 1080)
check("référence nulle : x intact", x, 200)

x, y = Layout.Rescale(nil, nil, 2560, 1440, 1920, 1080)
check("offsets absents -> 0", x, 0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Choix de l'ancre ──")

check("coin bas-gauche",  Layout.PickAnchor(100, 100, 2560, 1440),   "BOTTOMLEFT")
check("coin haut-droit",  Layout.PickAnchor(2400, 1350, 2560, 1440), "TOPRIGHT")
check("bord bas centré",  Layout.PickAnchor(1280, 100, 2560, 1440),  "BOTTOM")
check("bord gauche",      Layout.PickAnchor(100, 720, 2560, 1440),   "LEFT")
check("plein centre",     Layout.PickAnchor(1280, 720, 2560, 1440),  "CENTER")
check("bord haut centré", Layout.PickAnchor(1280, 1350, 2560, 1440), "TOP")
check("écran nul",        Layout.PickAnchor(0, 0, 0, 0),             "CENTER")

-- ═══════════════════════════════════════════════════════════════════════
print("── 3. Migration : les trois formes héritées ──")

local a = { point = "CENTER", relativePoint = "CENTER", x = 10, y = 20 }
check("forme point/relativePoint convertie", Layout.MigratePosition(a), true)
check("  point conservé",  a.point,  "CENTER")
check("  ancre conservée", a.anchor, "CENTER")
check("  x conservé",      a.x,      10)
check("  version posée",   a.v,      2)
check("  ancienne clé retirée", a.relativePoint, nil)
check("  AUCUNE référence stampée", a.refW, nil)

local b = { anchor = "TOPLEFT", relTo = "TOPLEFT", x = -5, y = 30 }
Layout.MigratePosition(b)
check("forme anchor/relTo : point", b.point,  "TOPLEFT")
check("forme anchor/relTo : ancre", b.anchor, "TOPLEFT")
check("  relTo retiré",            b.relTo,  nil)

local c = { point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = 120 }
Layout.MigratePosition(c)
check("forme point/relPoint : ancre", c.anchor, "BOTTOM")
check("  relPoint retiré",            c.relPoint, nil)

-- Points dissymétriques : les deux doivent survivre tels quels.
local d = { point = "TOP", relativePoint = "BOTTOM", x = 0, y = -8 }
Layout.MigratePosition(d)
check("point ≠ ancre : point", d.point,  "TOP")
check("point ≠ ancre : ancre", d.anchor, "BOTTOM")

check("migration idempotente", Layout.MigratePosition(a), false)
check("table méconnaissable ignorée", Layout.MigratePosition({ x = 1, y = 2 }), false)
check("non-table ignorée", Layout.MigratePosition("bonjour"), false)

-- ═══════════════════════════════════════════════════════════════════════
print("── 4. Une migration ne déplace rien ──")

-- Une position héritée, appliquée après conversion, doit atterrir
-- exactement là où l'ancien SetPoint l'aurait mise, y compris sur un
-- écran différent de celui de la capture.
local legacy = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = 340, y = 220 }
local f1 = Frame(0, 0, 200, 60)
Layout.Apply(legacy, f1)
check("point identique",  f1._pts.point,  "BOTTOMLEFT")
check("ancre identique",  f1._pts.anchor, "BOTTOMLEFT")
check("x inchangé",       f1._pts.x,      340)
check("y inchangé",       f1._pts.y,      220)

SCREEN.w, SCREEN.h = 1920, 1080
local f2 = Frame(0, 0, 200, 60)
Layout.Apply(legacy, f2)
check("autre écran : x toujours inchangé", f2._pts.x, 340)
check("autre écran : y toujours inchangé", f2._pts.y, 220)
SCREEN.w, SCREEN.h = 2560, 1440

-- ═══════════════════════════════════════════════════════════════════════
print("── 5. Aller-retour Save/Apply ──")

-- Une frame de 200x60 posée à 300 du bord gauche, 200 du bas.
local store = {}
local f = Frame(300, 200, 200, 60)
check("Save réussit", Layout.Save(store, f), true)
check("ancre choisie", store.anchor, "BOTTOMLEFT")
check("référence stampée (largeur)", store.refW, 2560)
near("offset x = bord gauche", store.x, 300)
near("offset y = bord bas",    store.y, 200)

local back = Frame(0, 0, 200, 60)
Layout.Apply(store, back)
near("relu au même endroit : x", back._pts.x, 300)
near("relu au même endroit : y", back._pts.y, 200)

-- Un aller-retour répété ne doit pas dériver.
for _ = 1, 20 do
    local g = Frame(store.x, store.y, 200, 60)
    Layout.Save(store, g)
end
near("20 cycles sans dérive : x", store.x, 300, 0.001)
near("20 cycles sans dérive : y", store.y, 200, 0.001)

-- Coin opposé : l'offset doit être négatif et mesuré depuis ce coin.
local st2 = {}
Layout.Save(st2, Frame(2260, 1380, 200, 60))
check("coin haut-droit détecté", st2.anchor, "TOPRIGHT")
near("offset x négatif", st2.x, -100)
near("offset y négatif", st2.y, 0)

-- Élément centré.
local st3 = {}
Layout.Save(st3, Frame(1180, 690, 200, 60))
check("centre détecté", st3.anchor, "CENTER")
near("offset x ~0", st3.x, 0)
near("offset y ~0", st3.y, 0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 6. Changement de résolution après sauvegarde ──")

-- Sauvegardé en 2560x1440, relu en 1920x1080 : un élément collé au coin
-- bas-gauche garde sa distance au coin (le coin ne bouge pas), et
-- l'offset est mis à l'échelle proportionnellement.
local st4 = {}
Layout.Save(st4, Frame(256, 144, 200, 60))
SCREEN.w, SCREEN.h = 1920, 1080
local f4 = Frame(0, 0, 200, 60)
Layout.Apply(st4, f4)
near("x proportionnel", f4._pts.x, 192)
near("y proportionnel", f4._pts.y, 108)
SCREEN.w, SCREEN.h = 2560, 1440

-- ═══════════════════════════════════════════════════════════════════════
print("── 7. Échelle de la frame ──")

-- Une frame à 0.5 d'échelle rapporte des coordonnées dans son propre
-- repère ; elles doivent être ramenées dans celui d'UIParent avant
-- d'être enregistrées, sinon la position est fausse d'un facteur deux.
local st5 = {}
Layout.Save(st5, Frame(600, 400, 200, 60, 0.5))
near("échelle 0.5 convertie en x", st5.x, 300)
near("échelle 0.5 convertie en y", st5.y, 200)

-- ═══════════════════════════════════════════════════════════════════════
print("── 8. Repli et robustesse ──")

local defaults = { point = "CENTER", anchor = "CENTER", x = 0, y = -150 }
local f6 = Frame(0, 0, 100, 30)
Layout.Apply({}, f6, defaults)
check("store vide -> defaults", f6._pts.y, -150)

local f7 = Frame(0, 0, 100, 30)
check("aucune source -> refus", Layout.Apply(nil, f7, nil), false)

-- Une frame sans bords (jamais affichée) ne doit pas écrire n'importe
-- quoi dans le profil.
local blind = { GetLeft = function() return nil end, GetBottom = function() return nil end,
                GetRight = function() return nil end, GetTop = function() return nil end,
                GetEffectiveScale = function() return 1 end }
local st6 = {}
check("frame sans bords : Save refuse", Layout.Save(st6, blind), false)
check("  rien n'a été écrit", next(st6), nil)

check("Save sans frame", Layout.Save({}, nil), false)
check("Save sans store", Layout.Save(nil, Frame(0, 0, 10, 10)), false)

-- ═══════════════════════════════════════════════════════════════════════
print("── 9. Aller-retour à une échelle ≠ 1 ──")

-- Le trou de la version initiale. La section 7 vérifiait la conversion
-- d'échelle du côté Save, et la section 5 l'aller-retour à l'échelle 1 : la
-- combinaison des deux n'était testée nulle part.
--
-- Save stocke des offsets en unités UIParent, mais les offsets de SetPoint
-- sont interprétés dans le repère de la frame déplacée. Sans la conversion
-- inverse à l'application, une frame à l'échelle 0.8 revenait à 240 au lieu
-- de 300, et à 1.25 elle partait à 375 -- une dérive composée à chaque cycle,
-- sur la minimap, les barres de ressources, le suivi Mythique+ et le suivi
-- d'objectifs.
for _, sc in ipairs({ 0.8, 1.25, 2.0 }) do
    local store = {}
    -- Pour occuper 300/200 en unités UIParent, une frame d'échelle `sc` a ses
    -- bords à 300/sc et 200/sc dans son propre repère.
    Layout.Save(store, Frame(300 / sc, 200 / sc, 200 / sc, 60 / sc, sc))
    near(("échelle %.2f : offset stocké en unités UIParent"):format(sc), store.x, 300)

    local back = Frame(0, 0, 200 / sc, 60 / sc, sc)
    Layout.Apply(store, back)
    -- La position réelle vaut l'offset rendu à SetPoint, multiplié par l'échelle.
    near(("échelle %.2f : position réelle après Apply"):format(sc), back._pts.x * sc, 300)
    near(("échelle %.2f : ordonnée réelle"):format(sc),             back._pts.y * sc, 200)
end

-- À l'échelle 1 la conversion doit être neutre.
local st1 = {}
Layout.Save(st1, Frame(300, 200, 200, 60, 1))
local b1 = Frame(0, 0, 200, 60, 1)
Layout.Apply(st1, b1)
near("échelle 1 : aucune conversion", b1._pts.x, 300)

-- ═══════════════════════════════════════════════════════════════════════
print("── 10. Matches : comparaison indépendante de l'échelle ──")

-- Blizzard peut réancrer certaines frames sans qu'elles bougent à l'écran.
-- Matches doit répondre en unités UIParent, donc identiquement quelle que
-- soit l'échelle de la frame.
local stM = {}
Layout.Save(stM, Frame(300, 200, 200, 60, 1))
check("frame au bon endroit",     Layout.Matches(stM, Frame(300, 200, 200, 60, 1)), true)
check("frame déplacée détectée",  Layout.Matches(stM, Frame(500, 200, 200, 60, 1)), false)
-- Même position physique, échelle différente : Matches doit dire oui.
check("échelle 0.5, même position",
      Layout.Matches(stM, Frame(300 / 0.5, 200 / 0.5, 200 / 0.5, 60 / 0.5, 0.5)), true)
check("tolérance respectée",      Layout.Matches(stM, Frame(300.5, 200, 200, 60, 1), 1), true)
check("au-delà de la tolérance",  Layout.Matches(stM, Frame(305, 200, 200, 60, 1), 1), false)
check("store absent",             Layout.Matches(nil, Frame(0, 0, 10, 10)), false)
check("frame sans bords",
      Layout.Matches(stM, { GetLeft = function() return nil end, GetBottom = function() return nil end,
                            GetRight = function() return nil end, GetTop = function() return nil end,
                            GetEffectiveScale = function() return 1 end }), false)

print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

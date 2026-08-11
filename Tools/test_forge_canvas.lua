-- Banc hors-jeu pour Forge.Canvas.
--
-- Le glisser-deposer lui-meme demande une souris ; ce qui se teste, et ce
-- qui casse en pratique, c'est la GEOMETRIE : la conversion d'un rectangle
-- ecran en couple (x, y) pour SetPoint. On la verifie sur des widgets
-- factices duck-types (GetLeft/GetRight/GetTop/GetBottom + echelle), y
-- compris avec des echelles imbriquees -- le piege qui avait fait deriver
-- la minimap.

_G.TomoMod_Forge = { BRAND = { 0, 0, 0 } }
_G.IsShiftKeyDown = function() return false end

-- ── Widget factice ────────────────────────────────────────────────────
-- rect exprime dans l'espace de coordonnees du widget lui-meme.
local function Rect(l, b, w, h, scale, parent)
    local o = { _l = l, _b = b, _w = w, _h = h, _scale = scale, _parent = parent }
    function o:GetLeft()   return self._l end
    function o:GetBottom() return self._b end
    function o:GetRight()  return self._l + self._w end
    function o:GetTop()    return self._b + self._h end
    function o:GetParent() return self._parent end
    if scale then
        function o:GetEffectiveScale() return self._scale end
    end
    return o
end

assert(loadfile("Core/Forge/ForgeRegistry.lua"))()
assert(loadfile("Core/Forge/ForgeCanvas.lua"))()
assert(loadfile("Modules/Interface/UnitFrames/UFElements.lua"))()

local C   = TomoMod_Forge.Canvas
local R   = TomoMod_Forge.Registry
local UFE = TomoMod_UFElements

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-52s attendu=%-10s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end
local function near(label, got, want, tol)
    tol = tol or 1e-6
    local good = type(got) == "number" and math.abs(got - want) <= tol
    if not good then ok = false end
    print(("  %s %-52s attendu=%-10s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

-- ═══════════════════════════════════════════════════════════════════════
print("── Echelle effective ──")
local frameLike = Rect(0, 0, 10, 10, 2)
local regionLike = Rect(0, 0, 10, 10, nil, frameLike)
check("frame : sa propre echelle", C.EffectiveScale(frameLike), 2)
check("region : echelle du parent", C.EffectiveScale(regionLike), 2)
check("orphelin : repli sur 1", C.EffectiveScale(Rect(0, 0, 1, 1)), 1)
check("nil : repli sur 1", C.EffectiveScale(nil), 1)

-- ═══════════════════════════════════════════════════════════════════════
print("── Coordonnees d'un point ──")
local box = Rect(100, 200, 60, 40, 1)   -- L=100 B=200 R=160 T=240
local x, y = C.PointCoord(box, "TOPLEFT")
check("TOPLEFT x", x, 100); check("TOPLEFT y", y, 240)
x, y = C.PointCoord(box, "BOTTOMRIGHT")
check("BOTTOMRIGHT x", x, 160); check("BOTTOMRIGHT y", y, 200)
x, y = C.PointCoord(box, "CENTER")
check("CENTER x", x, 130); check("CENTER y", y, 220)
x, y = C.PointCoord(box, "LEFT")
check("LEFT x", x, 100); check("LEFT y (milieu vertical)", y, 220)
x, y = C.PointCoord(box, "TOP")
check("TOP x (milieu horizontal)", x, 130); check("TOP y", y, 240)
check("point inconnu -> CENTER", (C.PointCoord(box, "PLOP")), 130)

local unlaid = { GetLeft = function() return nil end, GetRight = function() return nil end,
                 GetTop = function() return nil end, GetBottom = function() return nil end }
check("rect non resolu -> nil", C.PointCoord(unlaid, "CENTER"), nil)

-- ═══════════════════════════════════════════════════════════════════════
print("── Decalage : cas simple (echelle 1) ──")
local host = Rect(0, 0, 200, 50, 1)          -- L=0 B=0 R=200 T=50
local el   = Rect(10, 20, 40, 10, 1)         -- L=10 B=20 R=50 T=30

x, y = C.ComputeOffset(el, host, "LEFT", "LEFT")
near("LEFT/LEFT x", x, 10); near("LEFT/LEFT y", y, 0)

x, y = C.ComputeOffset(el, host, "CENTER", "CENTER")
near("CENTER/CENTER x", x, -70)   -- 30 - 100
near("CENTER/CENTER y", y, 0)     -- 25 - 25

x, y = C.ComputeOffset(el, host, "TOP", "BOTTOM")
near("TOP/BOTTOM x", x, -70)   -- 30 - 100
near("TOP/BOTTOM y", y, 30)    -- 30 - 0

-- ═══════════════════════════════════════════════════════════════════════
print("── Decalage : echelles differentes ──")
-- L'hote vit a l'echelle 2, l'element a l'echelle 1 : sans conversion en
-- pixels ecran, le calcul serait faux d'un facteur 2.
local host2 = Rect(0, 0, 100, 25, 2)         -- ecran : L=0 R=200 B=0 T=50
local el2   = Rect(10, 20, 40, 10, 1)        -- ecran : L=10 R=50 B=20 T=30
x, y = C.ComputeOffset(el2, host2, "LEFT", "LEFT")
near("hote x2, element x1 : x", x, 10)
x, y = C.ComputeOffset(el2, host2, "CENTER", "CENTER")
near("hote x2, element x1 : centre x", x, -70)
near("hote x2, element x1 : centre y", y, 0)

-- Element a l'echelle 2 : le decalage est exprime DANS son espace, donc
-- divise par 2.
local el3 = Rect(5, 10, 20, 5, 2)            -- ecran : L=10 R=50 B=20 T=30
x, y = C.ComputeOffset(el3, host, "LEFT", "LEFT")
near("element x2 : decalage dans son espace", x, 5)

-- ═══════════════════════════════════════════════════════════════════════
print("── Aller-retour : poser puis remesurer ──")
-- Propriete centrale : si on place l'element avec le decalage calcule, une
-- nouvelle mesure doit rendre exactement le meme couple.
local function place(element, hostF, point, relPoint, ox, oy)
    local hx, hy = C.PointCoord(hostF, relPoint)
    local s = C.EffectiveScale(element)
    -- position ecran voulue du point de l'element
    local tx, ty = hx + ox * s, hy + oy * s
    -- rectangle de l'element replace pour que `point` tombe dessus
    local cx, cy = C.PointCoord(element, point)
    element._l = element._l + (tx - cx) / s
    element._b = element._b + (ty - cy) / s
end

for _, case in ipairs({
    { "LEFT", "LEFT", 6, 0 }, { "RIGHT", "RIGHT", -6, 0 },
    { "CENTER", "CENTER", 0, 0 }, { "TOP", "BOTTOM", 0, -3 },
    { "BOTTOMLEFT", "TOPLEFT", -2, 4 }, { "TOPRIGHT", "BOTTOM", 17, -9 },
}) do
    local p, rp, ox, oy = case[1], case[2], case[3], case[4]
    local e = Rect(0, 0, 40, 12, 1)
    place(e, host, p, rp, ox, oy)
    local mx, my = C.ComputeOffset(e, host, p, rp)
    near(("aller-retour %s/%s x"):format(p, rp), mx, ox, 1e-9)
    near(("aller-retour %s/%s y"):format(p, rp), my, oy, 1e-9)
end

-- ═══════════════════════════════════════════════════════════════════════
print("── Element mis a l'echelle (lot 5) ──")
-- Une propriete `scale` change l'echelle effective de l'element. La mesure
-- doit rester exacte, sinon poser une poignee sur un element agrandi
-- ecrirait un decalage faux -- la version element du bug de la minimap.
local hostS = Rect(0, 0, 200, 50, 1)
local elS   = Rect(10, 20, 40, 10, 1.5)   -- ecran : L=15 R=75 B=30 T=45
local sx, sy = C.ComputeOffset(elS, hostS, "LEFT", "LEFT")
near("element x1.5 : decalage dans son espace", sx, 10)
near("element x1.5 : y", sy, (37.5 - 25) / 1.5)

-- Aller-retour avec echelle : poser puis remesurer doit rendre l'identique.
local eS = Rect(0, 0, 40, 12, 2)
place(eS, hostS, "CENTER", "CENTER", -8, 3)
local mx2, my2 = C.ComputeOffset(eS, hostS, "CENTER", "CENTER")
near("aller-retour a l'echelle 2 : x", mx2, -8, 1e-9)
near("aller-retour a l'echelle 2 : y", my2, 3, 1e-9)

print("── Magnetisme (Snap) ──")
check("snap 2 : 5 -> 6", C.Snap(5, 2), 6)
check("snap 2 : 4.4 -> 4", C.Snap(4.4, 2), 4)
check("snap 2 : -3 -> -2", C.Snap(-3, 2), -2)
check("snap 1 : 7.6 -> 8", C.Snap(7.6, 1), 8)
check("snap 0 : inchange", C.Snap(7.6, 0), 7.6)

-- ═══════════════════════════════════════════════════════════════════════
print("── Guides d'alignement ──")
-- Element dont le centre est a 2px du centre de l'hote : il doit y coller.
local hostG = Rect(0, 0, 200, 50, 1)         -- centre (100, 25)
local elG   = Rect(78, 20, 40, 10, 1)        -- centre (98, 25)
local gx, gy
x, y, gx, gy = C.ApplyGuides(elG, hostG, "CENTER", "CENTER", 0, 0, 4)
near("guide X : decalage corrige", x, 2)
check("guide X allume", gx, true)
check("guide Y allume (deja aligne)", gy, true)

-- Hors tolerance : rien ne bouge.
local elFar = Rect(0, 20, 40, 10, 1)         -- centre x = 20, soit 80px
x, y, gx, gy = C.ApplyGuides(elFar, hostG, "CENTER", "CENTER", 0, 0, 4)
near("hors tolerance : x inchange", x, 0)
check("hors tolerance : guide eteint", gx, false)

-- ═══════════════════════════════════════════════════════════════════════
print("── Liste blanche statique (arete cote moteur) ──")
check("power : frame autorise",
    R.TargetAllowed(R.Get(UFE.DOMAIN, "power"), "frame"), true)
check("power : health autorise",
    R.TargetAllowed(R.Get(UFE.DOMAIN, "power"), "health"), true)
check("power : infoBar REFUSE (arete moteur invisible du graphe)",
    R.TargetAllowed(R.Get(UFE.DOMAIN, "power"), "infoBar"), false)
check("name : aucune liste blanche -> tout autorise",
    R.TargetAllowed(R.Get(UFE.DOMAIN, "name"), "infoBar"), true)

local bad = R.Sanitize(UFE.DOMAIN, "power", { relTo = "infoBar" })
check("Sanitize refuse la cible interdite", bad.relTo, "health")
local good = R.Sanitize(UFE.DOMAIN, "power", { relTo = "frame" })
check("Sanitize accepte la cible autorisee", good.relTo, "frame")
local anyHost = R.Sanitize(UFE.DOMAIN, "name", { relTo = "infoBar" })
check("Sanitize accepte toute cible sans liste", anyHost.relTo, "infoBar")
check("Sanitize refuse l'auto-reference",
    R.Sanitize(UFE.DOMAIN, "name", { relTo = "name" }).relTo, "health")

print(ok and "\nTOUS LES TESTS PASSENT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

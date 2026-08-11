-- Banc de non-regression : valeurs secretes dans la geometrie du canvas.
--
-- Reproduit la trace de la session #961 :
--   ForgeCanvas.lua:282: attempt to perform arithmetic on local 'r'
--   (a secret number value) -- _SyncHandle -> Rebuild -> SetSubject
--
-- Cause : en Midnight, le RECT d'un widget devient secret des que son
-- contenu derive de donnees protegees. Le texte de vie d'un cadre d'apercu
-- alimente en donnees REELLES est exactement ce cas : GetLeft() rend une
-- valeur secrete, et le `r - l` suivant leve.
--
-- Regle cardinale verifiee ici : issecretvalue() passe AVANT toute
-- arithmetique ET toute comparaison. Les sentinelles ci-dessous levent si
-- Lua les touche, donc un test qui passe est une preuve, pas une promesse.

_G.TomoMod_Forge = { BRAND = { 0, 0, 0 } }
_G.IsShiftKeyDown = function() return false end

-- ── Valeur secrete : toute operation Lua dessus leve, comme en jeu ────
local SECRET = {}
local SECRET_MT = {
    __add = function() error("arithmetique sur une valeur secrete", 2) end,
    __sub = function() error("arithmetique sur une valeur secrete", 2) end,
    __mul = function() error("arithmetique sur une valeur secrete", 2) end,
    __div = function() error("arithmetique sur une valeur secrete", 2) end,
    __lt  = function() error("comparaison d'une valeur secrete", 2) end,
    __le  = function() error("comparaison d'une valeur secrete", 2) end,
    __unm = function() error("arithmetique sur une valeur secrete", 2) end,
    __concat = function() error("concatenation d'une valeur secrete", 2) end,
    __tostring = function() return "<secret>" end,
}
local function Secret(n)
    local o = setmetatable({ _n = n }, SECRET_MT)
    SECRET[o] = true
    return o
end

-- L'API du client, telle qu'on doit l'utiliser : un test d'appartenance,
-- jamais une operation.
_G.issecretvalue = function(v) return SECRET[v] == true end

assert(loadfile("Core/Forge/ForgeRegistry.lua"))()
assert(loadfile("Core/Forge/ForgeCanvas.lua"))()
assert(loadfile("Modules/Interface/UnitFrames/UFElements.lua"))()

local C   = TomoMod_Forge.Canvas
local UFE = TomoMod_UFElements

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-54s attendu=%-12s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end
local function noThrow(label, fn)
    local good, err = pcall(fn)
    if not good then ok = false end
    print(("  %s %-54s %s"):format(good and "OK   " or "ÉCHEC", label,
        good and "aucune levee" or tostring(err)))
    return good
end

-- ── Widgets ───────────────────────────────────────────────────────────
local function Rect(l, b, w, h, scale)
    local o = { _l = l, _b = b, _w = w, _h = h, _scale = scale }
    function o:GetLeft()   return self._l end
    function o:GetBottom() return self._b end
    function o:GetRight()  return self._l + self._w end
    function o:GetTop()    return self._b + self._h end
    function o:GetEffectiveScale() return self._scale end
    return o
end

-- Widget dont le rect est SECRET : c'est le texte de vie en mode reel.
local function SecretRect(scale)
    local o = {}
    function o:GetLeft()   return Secret(10) end
    function o:GetRight()  return Secret(50) end
    function o:GetBottom() return Secret(20) end
    function o:GetTop()    return Secret(30) end
    function o:GetEffectiveScale() return scale or 1 end
    return o
end

-- ═══════════════════════════════════════════════════════════════════════
print("── Detection ──")
check("Plain rend un nombre ordinaire", C.Plain(42), 42)
check("Plain rejette une valeur secrete", C.Plain(Secret(42)), nil)
check("Plain rejette nil", C.Plain(nil), nil)
check("Plain rejette une chaine", C.Plain("12"), nil)
check("IsSecret vrai", C.IsSecret(Secret(1)), true)
check("IsSecret faux", C.IsSecret(1), false)

-- ═══════════════════════════════════════════════════════════════════════
print("── PointCoord : rect secret ──")
local secret = SecretRect()
noThrow("PointCoord ne leve pas sur rect secret", function()
    C.PointCoord(secret, "CENTER")
end)
check("PointCoord rend nil", C.PointCoord(secret, "CENTER"), nil)
check("PointCoord rend nil sur un coin", C.PointCoord(secret, "TOPLEFT"), nil)

-- Un seul cote secret suffit a rendre la mesure impossible.
local half = Rect(0, 0, 100, 20, 1)
half.GetRight = function() return Secret(100) end
noThrow("un seul cote secret ne leve pas", function() C.PointCoord(half, "LEFT") end)
check("mesure abandonnee", C.PointCoord(half, "LEFT"), nil)

print("── Echelle effective secrete ──")
local badScale = Rect(0, 0, 10, 10, 1)
badScale.GetEffectiveScale = function() return Secret(2) end
noThrow("EffectiveScale ne compare pas une valeur secrete", function()
    C.EffectiveScale(badScale)
end)
check("repli sur 1", C.EffectiveScale(badScale), 1)

print("── ComputeOffset et guides ──")
local host = Rect(0, 0, 200, 50, 1)
noThrow("ComputeOffset element secret", function()
    C.ComputeOffset(secret, host, "LEFT", "LEFT")
end)
check("ComputeOffset rend nil", (C.ComputeOffset(secret, host, "LEFT", "LEFT")), nil)
noThrow("ComputeOffset hote secret", function()
    C.ComputeOffset(host, secret, "LEFT", "LEFT")
end)
noThrow("ApplyGuides sur element secret", function()
    C.ApplyGuides(secret, host, "CENTER", "CENTER", 0, 0)
end)
local gx, gy = select(3, C.ApplyGuides(secret, host, "CENTER", "CENTER", 0, 0))
check("aucun guide allume", gx or gy, false)

-- ═══════════════════════════════════════════════════════════════════════
print("── Rejeu de la trace : _SyncHandle -> Rebuild ──")
-- Arbre d'apercu ou SEUL le texte de vie porte un rect secret, comme dans
-- la session #961.
local function MakeSubject()
    local f = Rect(0, 0, 260, 60, 1)
    f.health = Rect(0, 20, 260, 30, 1)
    f.health.nameText   = Rect(4, 30, 60, 12, 1)
    f.health.levelText  = Rect(200, 30, 20, 12, 1)
    f.health.text       = SecretRect(1)      -- <- le coupable
    f.health.raidIcon   = Rect(0, 52, 16, 16, 1)
    f.health.leaderIcon = Rect(20, 52, 16, 16, 1)
    f.power      = Rect(0, 0, 260, 8, 1)
    f.threatText = Rect(100, 30, 40, 12, 1)
    return f
end

-- Faux CanvasMT minimal : on exerce la geometrie de _SyncHandle sans
-- CreateFrame, en reproduisant sa sequence exacte.
local function SyncLike(el)
    local l, r = C.Plain(el:GetLeft()),   C.Plain(el:GetRight())
    local b, t = C.Plain(el:GetBottom()), C.Plain(el:GetTop())
    if not (l and r and b and t) then return nil end
    local es, hs = C.EffectiveScale(el), 1
    local k = es / hs
    return math.max((r - l) * k, 1), math.max((t - b) * k, 1)
end

local subject = MakeSubject()
local placed, hidden = 0, 0
noThrow("Rebuild complet ne leve pas", function()
    for _, desc in ipairs(UFE.List()) do
        local okr, el = pcall(desc.resolve, subject)
        if okr and el then
            if SyncLike(el) then placed = placed + 1 else hidden = hidden + 1 end
        end
    end
end)
check("les elements mesurables sont poses", placed, 6)
check("le seul element secret est masque", hidden, 1)

-- ═══════════════════════════════════════════════════════════════════════
print("── Un rect ordinaire reste mesure a l'identique ──")
local plainEl = Rect(10, 20, 40, 10, 1)
local w, h = SyncLike(plainEl)
check("largeur", w, 40)
check("hauteur", h, 10)
local x, y = C.ComputeOffset(plainEl, host, "LEFT", "LEFT")
check("decalage x inchange", x, 10)
check("decalage y inchange", y, 0)

print(ok and "\nTOUS LES TESTS PASSENT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

-- Banc hors-jeu pour Core/ResolutionPresets.lua.
--
-- Le piège de ce lot est arithmétique. Le plancher client de 0.64 sur
-- l'uiScale rend 1440p et 2160p rigoureusement identiques en unités
-- d'interface, et c'est assez contre-intuitif pour qu'une régression
-- passe inapercue. Les faits d'échelle sont donc verrouillés en dur.
--
-- Deux autres propriétés comptent autant :
--
--   * Les polices sont calculées depuis les DEFAULTS, jamais depuis la
--     valeur courante. Sinon appliquer deux fois le même preset
--     composerait le facteur, et un aller-retour 1080 -> 1440 -> 1080
--     finirait ailleurs qu'au point de départ.
--   * La liste des clés de lisibilité est écrite à la main. On vérifie
--     qu'elle correspond encore aux vrais defaults, sinon elle pourrit
--     en silence.
--
-- Usage : luajit Tools/test_resolution_presets.lua   (depuis la racine)

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-52s attendu=%-14s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end
local function near(label, got, want, tol)
    tol = tol or 0.001
    local good = type(got) == "number" and math.abs(got - want) <= tol
    if not good then ok = false end
    print(("  %s %-52s attendu=~%-13s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end
local function fail(m) ok = false; print("  ÉCHEC " .. m) end

-- ── Écran simulé ─────────────────────────────────────────────────────
local PHYS = { w = 2560, h = 1440 }
_G.GetPhysicalScreenSize = function() return PHYS.w, PHYS.h end
_G.UIParent = {
    GetWidth  = function() return PHYS.w end,
    GetHeight = function() return 1200 end,
    GetEffectiveScale = function() return 1 end,
}
local cvars = {}
_G.SetCVar     = function(k, v) cvars[k] = v end
_G.CreateFrame = function() return setmetatable({}, { __index = function() return function() end end }) end
_G.C_Timer     = { After = function() end, NewTicker = function() return { Cancel = function() end } end }
_G.GetLocale   = function() return "enUS" end
_G.InCombatLockdown = function() return false end
_G.hooksecurefunc   = function() end
_G.issecretvalue    = function() return false end
_G.LibStub          = function() return nil end
_G.StaticPopupDialogs, _G.SlashCmdList = {}, {}

pcall(assert(loadfile("Core/Database.lua")))
assert(loadfile("Core/ModuleRegistry.lua"))()
assert(loadfile("Core/ModuleManifest.lua"))()
assert(loadfile("Core/LayoutEngine.lua"))()
assert(loadfile("Core/ResolutionPresets.lua"))()

local R, Layout, RES = _G.TomoMod_Registry, _G.TomoMod_Layout, _G.TomoMod_Resolution
local D = _G.TomoMod_Defaults

local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local o = {}; for k, v in pairs(t) do o[k] = DeepCopy(v) end; return o
end
local function ResetDB()
    _G.TomoModDB = DeepCopy(D)
    cvars = {}
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. Arithmétique de l'échelle ──")

local d1080 = RES.Describe(1080)
near("1080p uiScale idéal",   d1080.idealScale,   768 / 1080)
near("1080p uiScale retenu",  d1080.appliedScale, 768 / 1080)
check("1080p non plafonné",   d1080.floored,      false)
near("1080p UIParent",        d1080.uiHeight,     1080, 0.5)
near("1080p px par unité",    d1080.pixelsPerUnit, 1, 0.001)

local d1440 = RES.Describe(1440)
near("1440p uiScale idéal",   d1440.idealScale,   768 / 1440)
check("1440p plafonné",       d1440.floored,      true)
near("1440p uiScale retenu",  d1440.appliedScale, 0.64)
near("1440p UIParent",        d1440.uiHeight,     1200, 0.5)
near("1440p px par unité",    d1440.pixelsPerUnit, 1.2, 0.001)

local d2160 = RES.Describe(2160)
check("2160p plafonné",       d2160.floored,      true)
near("2160p uiScale retenu",  d2160.appliedScale, 0.64)
near("2160p UIParent",        d2160.uiHeight,     1200, 0.5)
near("2160p px par unité",    d2160.pixelsPerUnit, 1.8, 0.001)

-- Le fait qui gouverne tout le lot.
check("1440p et 2160p : même espace d'interface",
      d1440.uiHeight == d2160.uiHeight, true)

check("hauteur nulle refusée", RES.Describe(0),    nil)
check("hauteur absurde refusée", RES.Describe(-1), nil)

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Détection du palier ──")

PHYS.h = 1080; check("1080 -> 1080p", RES.Detect(), "1080p")
PHYS.h = 1200; check("1200 -> 1440p", RES.Detect(), "1440p")
PHYS.h = 1440; check("1440 -> 1440p", RES.Detect(), "1440p")
PHYS.h = 1600; check("1600 -> 1440p", RES.Detect(), "1440p")
PHYS.h = 2160; check("2160 -> 2160p", RES.Detect(), "2160p")
PHYS.h = 900;  check("900 -> 1080p",  RES.Detect(), "1080p")
PHYS.h = 1440

check("palier inconnu",     RES.Get("720p"),  nil)
check("trois paliers",      #RES.Tiers(),     3)

-- ═══════════════════════════════════════════════════════════════════════
print("── 3. Mise à l'échelle des polices ──")

check("arrondi au plus proche", RES.ScaledFont(12, 1.15), 14)
check("facteur neutre",         RES.ScaledFont(12, 1.00), 12)
check("plancher de lisibilité", RES.ScaledFont(6, 1.00),  8)
check("base non numérique",     RES.ScaledFont(nil, 1.2), nil)

local plan1080 = RES.FontPlan("1080p")
local plan1440 = RES.FontPlan("1440p")
check("le plan 1080p couvre les clés", #RES.FONT_KEYS > 0
      and plan1080["unitFrames.fontSize"] ~= nil, true)
check("1080p grossit la police",  plan1080["unitFrames.fontSize"] > D.unitFrames.fontSize, true)
check("1440p est la référence",   plan1440["unitFrames.fontSize"],  D.unitFrames.fontSize)

-- Le point qui compte : deux applications successives ne composent pas.
ResetDB()
RES.Apply("1080p", { skipScale = true })
local once = TomoModDB.unitFrames.fontSize
RES.Apply("1080p", { skipScale = true })
check("appliquer deux fois ne compose pas", TomoModDB.unitFrames.fontSize, once)

-- Et un aller-retour revient exactement au point de départ.
RES.Apply("1440p", { skipScale = true })
check("aller-retour 1080->1440", TomoModDB.unitFrames.fontSize, D.unitFrames.fontSize)

-- ═══════════════════════════════════════════════════════════════════════
print("── 4. La liste de clés n'a pas pourri ──")

local missing, wrongType = 0, 0
for _, path in ipairs(RES.FONT_KEYS) do
    local v = R.GetPath(D, path)
    if v == nil then
        missing = missing + 1
        fail(("clé de lisibilité '%s' absente des defaults"):format(path))
    elseif type(v) ~= "number" then
        wrongType = wrongType + 1
        fail(("clé '%s' n'est pas un nombre"):format(path))
    end
end
check("toutes les clés existent",     missing,   0)
check("toutes sont numériques",       wrongType, 0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 5. CVar : seulement quand ça change quelque chose ──")

ResetDB()
PHYS.h = 1080
local r1 = RES.Apply("1080p")
check("1080p : uiScale écrit",  cvars.uiScale ~= nil, true)
check("1080p : useUiScale à 1", cvars.useUiScale,     "1")
check("1080p : non plafonné",   r1.floored,           false)

ResetDB()
PHYS.h = 1440
local r2 = RES.Apply("1440p")
check("1440p : CVar laissé tranquille", cvars.uiScale, nil)
check("1440p : plafonnement signalé",   r2.floored,    true)

ResetDB()
PHYS.h = 1080
RES.Apply("1080p", { skipScale = true })
check("skipScale respecté", cvars.uiScale, nil)
PHYS.h = 1440

-- ═══════════════════════════════════════════════════════════════════════
print("── 6. Estampillage des références (pont avec le lot 2) ──")

ResetDB()
-- Une position migrée ne porte pas de référence, donc elle ne suit pas
-- un changement de résolution. C'est l'application d'un preset qui doit
-- l'y inscrire.
local pos = R.GetPath(TomoModDB, "unitFrames.player.position")
Layout.MigratePosition(pos)
check("après migration : aucune référence", pos.refW, nil)

local n = Layout.StampReference(TomoModDB)
check("estampillage : ancres marquées", n > 0, true)
check("référence posée (largeur)", pos.refW, 2560)
check("référence posée (hauteur)", pos.refH, 1200)

-- Et la position estampillée suit désormais l'écran.
local before = pos.x
_G.UIParent.GetWidth = function() return 1920 end
_G.UIParent.GetHeight = function() return 1080 end
local f = { SetPoint = function(self, p, r, a, x, y) self._x = x end,
            ClearAllPoints = function() end }
Layout.Apply(pos, f)
check("suit maintenant l'écran", f._x ~= before or before == 0, true)
_G.UIParent.GetWidth = function() return PHYS.w end
_G.UIParent.GetHeight = function() return 1200 end

-- Appliquer un preset estampille tout seul.
ResetDB()
local r3 = RES.Apply("1440p", { skipScale = true })
check("Apply estampille", r3.stamped > 0, true)
check("Apply sans capture", r3.fromCapture, false)

-- ═══════════════════════════════════════════════════════════════════════
print("── 7. Captures ──")

ResetDB()
check("aucune capture au départ", RES.HasCapture("1440p"), false)

TomoModDB.unitFrames.fontSize = 17
local posP = R.GetPath(TomoModDB, "unitFrames.player.position")
Layout.MigratePosition(posP)
posP.x, posP.y = 123, 456

check("capture réussie",  (RES.Capture("1440p")), true)
check("capture presente", RES.HasCapture("1440p"), true)

local cap = RES.GetCapture("1440p")
check("capture : police relevée",  cap.fonts["unitFrames.fontSize"], 17)
check("capture : position relevée", cap.positions["unitFrames.player.position"].x, 123)
check("capture : écran noté",       cap.capturedAt, 1440)

-- On sabote la DB, puis on réapplique : la capture doit gagner sur les
-- valeurs calculées.
TomoModDB.unitFrames.fontSize = 99
posP.x = 0
local r4 = RES.Apply("1440p", { skipScale = true })
check("la capture prime",        r4.fromCapture, true)
check("police restaurée",        TomoModDB.unitFrames.fontSize, 17)
check("position restaurée",      R.GetPath(TomoModDB, "unitFrames.player.position").x, 123)

check("capture effacée", RES.ClearCapture("1440p"), true)
check("plus de capture", RES.HasCapture("1440p"),   false)

-- Sans capture on repasse au calculé.
local r5 = RES.Apply("1440p", { skipScale = true })
check("retour au calculé", r5.fromCapture, false)
check("police recalculée", TomoModDB.unitFrames.fontSize, D.unitFrames.fontSize)

check("palier inconnu refusé", RES.Apply("720p").ok, false)
check("capture d'un palier inconnu refusée", RES.Capture("720p"), false)

-- ═══════════════════════════════════════════════════════════════════════
print("── 8. DescribeTier ──")

-- Les panneaux doivent montrer ce que ferait 1080p alors que le client
-- annonce 1440p. Le mapping palier -> hauteur representative etait
-- recopie a la main dans la commande slash ; deux appelants de plus en
-- auraient fait trois copies.
PHYS.h = 1440
local t1080 = RES.DescribeTier("1080p")
check("1080p decrit hors du palier courant", t1080 ~= nil, true)
check("1080p non plafonne",                  t1080 and t1080.floored, false)
near("1080p UIParent",                       t1080 and t1080.uiHeight, 1080, 0.5)
check("cle reportee",                        t1080 and t1080.key,   "1080p")
check("libelle reporte",                     t1080 and t1080.label, "res_1080")

local t2160 = RES.DescribeTier("2160p")
check("2160p plafonne",   t2160 and t2160.floored,  true)
near("2160p UIParent",    t2160 and t2160.uiHeight, 1200, 0.5)

check("palier inconnu -> nil", RES.DescribeTier("720p"), nil)
check("cle absente -> nil",    RES.DescribeTier(nil),    nil)

-- L'etat de capture voyage avec la description : c'est lui qui allume la
-- pastille verte dans les deux panneaux.
RES._Reset()
check("sans capture", RES.DescribeTier("1080p").hasCapture, false)
RES.Capture("1080p")
check("avec capture", RES.DescribeTier("1080p").hasCapture, true)

-- Chaque palier doit porter sa hauteur representative, sinon Describe
-- renvoie nil et les panneaux affichent une rangee vide.
local missingSample = 0
for _, t in ipairs(RES.Tiers()) do
    if type(t.sampleHeight) ~= "number" then missingSample = missingSample + 1 end
    if RES.DescribeTier(t.key) == nil then missingSample = missingSample + 1 end
end
check("tous les paliers descriptibles", missingSample, 0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 9. Cablage des panneaux (garde statique) ──")

local function read(path)
    local fh = io.open(path, "rb")
    if not fh then return nil end
    local t = fh:read("*a"); fh:close()
    return (t:gsub("^\239\187\191", ""):gsub("\r\n", "\n"))
end

local ins = read("TomoMod_Options/Config/Installer.lua")
check("Installer lisible", ins ~= nil, true)
if ins then
    -- L'etape doit exister ET preceder le choix d'archetype dans les deux
    -- parcours : les tailles de police qu'un preset ecrit sont le terrain
    -- sur lequel les presets d'archetype s'appuient ensuite.
    check("page resolution definie", ins:find("pages.resolution", 1, true) ~= nil, true)
    for _, flowName in ipairs({ "FLOW_PRESET", "FLOW_CUSTOM" }) do
        local line = ins:match("local " .. flowName .. "%s*=%s*(%b{})")
        check(flowName .. " trouve", line ~= nil, true)
        if line then
            local iRes = line:find('"resolution"', 1, true)
            local iPick = line:find('"picker"', 1, true)
            check(flowName .. " contient resolution", iRes ~= nil, true)
            check(flowName .. " : resolution avant picker",
                  (iRes and iPick and iRes < iPick) or false, true)
        end
    end
    -- Une pastille par etape : le vivier doit couvrir le plus long parcours.
    local maxDots = tonumber(ins:match("local MAX_DOTS%s*=%s*(%d+)"))
    local custom  = ins:match("local FLOW_CUSTOM%s*=%s*(%b{})") or ""
    local n = 0
    for _ in custom:gmatch('"[%w_]+"') do n = n + 1 end
    check("assez de pastilles pour FLOW_CUSTOM", (maxDots or 0) >= n, true)
end

local acc = read("TomoMod_Options/Config/Panels/Accueil.lua")
check("Accueil lisible", acc ~= nil, true)
if acc then
    check("carte resolution definie", acc:find("CreateResolution", 1, true) ~= nil, true)
    local iRes  = acc:find("y = CreateResolution(c, y)", 1, true)
    local iQuick = acc:find("y = CreateQuickConfig(c, y)", 1, true)
    check("resolution avant la selection de role",
          (iRes and iQuick and iRes < iQuick) or false, true)
end

print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

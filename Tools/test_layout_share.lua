-- Banc hors-jeu pour Core/LayoutShare.lua.
--
-- Ce qui est verrouille ici, dans l'ordre d'importance :
--
--   1. La liste blanche. Une chaine peut nommer n'importe quelle cle ;
--      seules celles que les manifestes declarent doivent survivre. C'est
--      la frontiere de securite du module : sans elle, importer une
--      disposition revient a laisser un inconnu ecrire dans TomoModDB.
--   2. Les refW/refH de l'auteur restent intacts. C'est eux qui
--      permettent a Layout.Apply de convertir vers l'ecran de celui qui
--      importe ; les reecrire detruirait exactement l'information utile.
--   3. Le report des tailles de police passe par le ratio de palier.
--      1080p veut des valeurs PLUS GRANDES que 1440p, donc l'import
--      multiplie dans un sens et divise dans l'autre.
--
-- Usage : luajit Tools/test_layout_share.lua   (depuis la racine)

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-52s attendu=%-14s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end
local function near(label, got, want, tol)
    local good = type(got) == "number" and math.abs(got - want) <= (tol or 0.01)
    if not good then ok = false end
    print(("  %s %-52s attendu=~%-13s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

-- ── Stubs client ──────────────────────────────────────────────────────
_G.abs, _G.floor, _G.ceil = math.abs, math.floor, math.ceil
_G.max, _G.min = math.max, math.min
_G.format, _G.strlen, _G.strrep = string.format, string.len, string.rep
_G.gsub, _G.strfind = string.gsub, string.find
_G.strmatch, _G.strsub = string.match, string.sub
_G.strbyte, _G.strchar = string.byte, string.char
_G.tinsert, _G.tconcat = table.insert, table.concat
_G.frexp, _G.ldexp = math.frexp, math.ldexp
_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
_G.GetTime = function() return os.clock() end
_G.GetLocale = function() return "enUS" end
_G.InCombatLockdown = function() return false end
_G.hooksecurefunc = function() end
_G.issecretvalue  = function() return false end
_G.StaticPopupDialogs, _G.SlashCmdList = {}, {}

local PHYS = { w = 2560, h = 1440 }
_G.GetPhysicalScreenSize = function() return PHYS.w, PHYS.h end
local cvars = {}
_G.SetCVar = function(k, v) cvars[k] = v end
_G.GetCVar = function(k) return cvars[k] end
_G.UIParent = { GetWidth = function() return PHYS.w end,
                GetHeight = function() return 1200 end }

-- ── Librairies embarquees ─────────────────────────────────────────────
local libs = {}
_G.LibStub = function(name, silent) return libs[name] end
local function LoadLib(path, name, file)
    local prev = _G.LibStub
    local reg = {}
    _G.LibStub = setmetatable({
        NewLibrary = function(_, n) reg[n] = reg[n] or {}; return reg[n], 0 end,
        GetLibrary = function(_, n) return reg[n] end,
    }, { __call = function(_, n) return reg[n] end })
    assert(loadfile(path))(name, file)
    for n, lib in pairs(reg) do libs[n] = lib end
    _G.LibStub = prev
end
LoadLib("Libs/LibDeflate/LibDeflate.lua", "LibDeflate", "LibDeflate.lua")
LoadLib("Libs/libserialize/serializer.lua", "TomoSerialize", "serializer.lua")

-- ── Modules ───────────────────────────────────────────────────────────
pcall(assert(loadfile("Core/Database.lua")))
assert(loadfile("Core/ModuleRegistry.lua"))()
assert(loadfile("Core/ModuleManifest.lua"))()
assert(loadfile("Core/LayoutEngine.lua"))()
assert(loadfile("Core/ResolutionPresets.lua"))()
assert(loadfile("Core/LayoutShare.lua"))()

local R   = _G.TomoMod_Registry
local RES = _G.TomoMod_Resolution
local LS  = _G.TomoMod_LayoutShare
local D   = _G.TomoMod_Defaults

local function DeepCopy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = DeepCopy(x) end
    return t
end
local function ResetDB()
    _G.TomoModDB = DeepCopy(D)
    if RES._Reset then RES._Reset() end
end

-- Une disposition reconnaissable : chaque ancre a une position unique.
local function SeedLayout(offset, refW, refH)
    local i = 0
    for _, a in ipairs(R.Anchors()) do
        i = i + 1
        R.SetPath(_G.TomoModDB, a.path, {
            v = 2, point = "TOPLEFT", anchor = "CENTER",
            x = offset + i, y = offset - i, refW = refW, refH = refH,
        })
    end
    return i
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. Aller-retour ──")

ResetDB()
local nSeeded = SeedLayout(100, 2560, 1440)
check("des ancres declarees", nSeeded > 0, true)

local str, rep = LS.Export({ author = "  Tomo  ", source = "live" })
check("export produit une chaine", type(str) == "string", true)
check("source signalee",           rep and rep.source, "live")
check("toutes les ancres exportees", rep and rep.positions, nSeeded)
check("chaine courte (< 3000)",    (str and #str or 99999) < 3000, true)

local payload = LS.Decode(str)
check("decodage reussi",  type(payload) == "table", true)
check("auteur nettoye",   payload and payload.author, "Tomo")
check("rien de rejete",   payload and payload.dropped, 0)

-- Le point 2 : la reference de l'auteur doit survivre au voyage.
local anyPath = R.Anchors()[1].path
check("refW de l'auteur preserve", payload.positions[anyPath].refW, 2560)
check("refH de l'auteur preserve", payload.positions[anyPath].refH, 1440)

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Liste blanche (frontiere de securite) ──")

local LibS, LibD = libs["TomoSerialize-1.0"], libs["LibDeflate"]
local function Forge(tbl)
    return LibD:EncodeForPrint(LibD:CompressDeflate(LibS:Serialize(tbl), { level = 9 }))
end

local hostile = Forge({
    _h = LS.HEADER, _v = 1, tier = "1440p",
    positions = {
        ["profiles.named"]        = { point = "TOP", anchor = "TOP", x = 1, y = 1 },
        ["_resolution.captures"]  = { point = "TOP", anchor = "TOP", x = 2, y = 2 },
        [anyPath]                 = { point = "TOP", anchor = "TOP", x = 3, y = 3, v = 2 },
    },
    fonts = { ["profiles.activeProfile"] = 99, ["unitFrames.fontSize"] = 14 },
})
local hp = LS.Decode(hostile)
check("chemin hors registre rejete",  hp.positions["profiles.named"],       nil)
check("chemin interne rejete",        hp.positions["_resolution.captures"], nil)
check("ancre legitime conservee",     hp.positions[anyPath] ~= nil,         true)
check("cle police hors liste rejetee", hp.fonts["profiles.activeProfile"],  nil)
check("cle police legitime conservee", hp.fonts["unitFrames.fontSize"],     14)
check("rejets comptes",               hp.dropped,                           3)

ResetDB()
local before = R.GetPath(_G.TomoModDB, "profiles") and true or false
LS.Import(hp)
check("rien ecrit hors registre",
      R.GetPath(_G.TomoModDB, "profiles.named"), nil)
check("l'ancre legitime a bien ete ecrite",
      R.GetPath(_G.TomoModDB, anyPath).x, 3)

-- Defense en profondeur. LS.Import accepte aussi une table directement,
-- donc un appelant peut lui tendre une charge qui n'est jamais passee par
-- Decode. Le filtre doit exister DES DEUX COTES : verifier seulement au
-- decodage laisserait un chemin d'ecriture non garde.
ResetDB()
local raw = {
    _h = LS.HEADER, _v = 1, tier = "1440p",
    positions = {
        ["profiles.named"]       = { point = "TOP", anchor = "TOP", x = 7, y = 7, v = 2 },
        ["_resolution.captures"] = { point = "TOP", anchor = "TOP", x = 8, y = 8, v = 2 },
        [anyPath]                = { point = "TOP", anchor = "TOP", x = 9, y = 9, v = 2 },
    },
    fonts = { ["profiles.activeProfile"] = 42 },
}
local rRaw = LS.Import(raw, { fonts = true })
check("table brute : chemin hors registre ignore",
      R.GetPath(_G.TomoModDB, "profiles.named"), nil)
check("table brute : chemin interne ignore",
      R.GetPath(_G.TomoModDB, "_resolution.captures"), nil)
check("table brute : cle police hors liste ignoree",
      R.GetPath(_G.TomoModDB, "profiles.activeProfile"), nil)
check("table brute : seule l'ancre legitime est ecrite", rRaw.positions, 1)
check("table brute : ancre legitime bien ecrite",
      R.GetPath(_G.TomoModDB, anyPath).x, 9)

-- Une charge qui n'est pas une disposition doit etre refusee net.
check("en-tete etranger refuse",
      (LS.Decode(Forge({ _h = "AUTRE", _v = 1 }))) , nil)
check("version future refusee",
      (LS.Decode(Forge({ _h = LS.HEADER, _v = 99 }))), nil)
check("chaine vide refusee", (LS.Decode("")), nil)
check("charabia refuse",     (LS.Decode("pas une chaine valide !!")), nil)

-- ═══════════════════════════════════════════════════════════════════════
print("── 3. Report des tailles de police ──")

check("1440p -> 1080p agrandit", LS._FontRatio("1440p", "1080p") > 1, true)
check("1080p -> 1440p reduit",   LS._FontRatio("1080p", "1440p") < 1, true)
near("ratio 1440->1080",         LS._FontRatio("1440p", "1080p"), 1.15)
near("ratio identique",          LS._FontRatio("1440p", "1440p"), 1.00)
check("palier inconnu -> neutre", LS._FontRatio("720p", "1440p"), 1)
check("palier absent -> neutre",  LS._FontRatio(nil, nil), 1)

-- Un export 1440p importe sur un ecran 1080p doit remonter les tailles.
ResetDB()
SeedLayout(200, 2560, 1440)
R.SetPath(_G.TomoModDB, "unitFrames.fontSize", 12)
local s1440 = LS.Export({ source = "live", tier = "1440p" })

PHYS.h = 1080; PHYS.w = 1920
ResetDB()
local r = LS.Import(LS.Decode(s1440))
check("import reussi",            r.ok,        true)
check("palier de destination",    r.tier,      "1080p")
check("palier d'origine",         r.fromTier,  "1440p")
check("police remontee",          R.GetPath(_G.TomoModDB, "unitFrames.fontSize"), 14)
check("reference de l'auteur intacte",
      R.GetPath(_G.TomoModDB, anyPath).refW, 2560)
PHYS.h = 1440; PHYS.w = 2560

-- ═══════════════════════════════════════════════════════════════════════
print("── 4. Options d'import ──")

ResetDB()
SeedLayout(300, 2560, 1440)
R.SetPath(_G.TomoModDB, "unitFrames.fontSize", 12)
local full = LS.Decode(LS.Export({ source = "live" }))

ResetDB()
local rPos = LS.Import(full, { fonts = false })
check("fonts=false n'ecrit aucune police", rPos.fonts, 0)
check("mais ecrit les ancres",             rPos.positions > 0, true)

ResetDB()
local rFonts = LS.Import(full, { positions = false })
check("positions=false n'ecrit aucune ancre", rFonts.positions, 0)
check("mais ecrit les polices",               rFonts.fonts > 0, true)

ResetDB()
local one = { R.Anchors()[1].path }
local rOne = LS.Import(full, { paths = one, fonts = false })
check("selection d'un seul chemin", rOne.positions, 1)
check("les autres sont comptes ignores", rOne.skipped > 0, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 5. Inspection ──")

ResetDB()
SeedLayout(400, 2560, 1440)
local same = LS.Decode(LS.Export({ source = "live" }))
check("aucune difference avec soi-meme", #LS.AllPaths(same, true), 0)
check("mais tous les chemins listes",    #LS.AllPaths(same, false), nSeeded)

SeedLayout(500, 2560, 1440)   -- on bouge tout
check("tout differe apres deplacement",  #LS.AllPaths(same, true), nSeeded)

local groups = LS.Inspect(same)
check("regroupe par module", #groups > 0, true)
local labelled = true
for _, g in ipairs(groups) do
    if type(g.module) ~= "string" then labelled = false end
    for _, e in ipairs(g.anchors) do
        if type(e.path) ~= "string" or type(e.label) ~= "string" then labelled = false end
    end
end
check("chaque entree porte module, chemin et libelle", labelled, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 6. Source capture contre source vivante ──")

ResetDB()
SeedLayout(600, 2560, 1440)
RES.Capture("1440p")
SeedLayout(700, 2560, 1440)   -- la config vivante diverge de la capture

local sCap = LS.Export({ tier = "1440p" })              -- capture par defaut
local sLive = LS.Export({ tier = "1440p", source = "live" })
local pCap, pLive = LS.Decode(sCap), LS.Decode(sLive)
check("la capture est preferee par defaut", pCap.positions[anyPath].x, 601)
check("source=live lit la config actuelle", pLive.positions[anyPath].x, 701)

RES.ClearCapture("1440p")
local _, repFallback = LS.Export({ tier = "1440p" })
check("repli sur la config vivante", repFallback.source, "live")
local nilStr, repStrict = LS.Export({ tier = "1440p", source = "capture" })
check("source=capture stricte refuse", nilStr, nil)
check("et dit pourquoi", type(repStrict.err) == "string", true)

print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

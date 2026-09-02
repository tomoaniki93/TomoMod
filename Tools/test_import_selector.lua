-- Banc hors-jeu pour TomoMod_Options/Config/ImportSelector.lua.
--
-- Un panneau ne se teste pas à l'œil ici, mais deux choses s'y testent
-- très bien et sont exactement celles qui coûtent cher quand elles
-- ratent :
--
--   1. Le recyclage des lignes. Un profil porte soixante-deux modules et
--      l'arbre est redessiné à chaque case cochée. Les frames WoW ne se
--      détruisent pas : sans pool, chaque clic abandonne définitivement
--      une soixantaine de frames.
--   2. La sélection par défaut. Cocher les soixante-deux d'office ferait
--      du panneau une formalité, c'est-à-dire précisément le
--      comportement qu'il remplace.
--
-- Usage : luajit Tools/test_import_selector.lua   (depuis la racine)

local ok = true
-- Le sélecteur écrit dans le chat ; on le muselle plus bas, mais le banc
-- garde une référence au vrai print pour ses propres lignes.
local say = print
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    say(("  %s %-52s attendu=%-12s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

-- ── Stubs de frames, comptés ─────────────────────────────────────────
local framesCreated = 0
local scripts = {}

local function MakeFrame()
    local f = { _shown = false, _scripts = {}, _children = {} }
    local mt = { __index = function(t, k)
        if k == "CreateFontString" then return function() return MakeFrame() end end
        if k == "CreateTexture"    then return function() return MakeFrame() end end
        if k == "Show"    then return function(s) s._shown = true end end
        if k == "Hide"    then return function(s) s._shown = false end end
        if k == "IsShown" then return function(s) return s._shown end end
        if k == "SetScript" then
            return function(s, ev, fn) s._scripts[ev] = fn end
        end
        if k == "GetChecked" then return function(s) return s._checked end end
        if k == "SetChecked" then return function(s, v) s._checked = v end end
        if k == "SetText"    then return function(s, v) s._text = v end end
        if k == "GetText"    then return function(s) return s._text end end
        if k == "IsMouseOver" then return function() return false end end
        return function() end
    end }
    return setmetatable(f, mt)
end

_G.CreateFrame = function(_, name)
    framesCreated = framesCreated + 1
    local f = MakeFrame()
    f._name = name
    if name then _G[name] = f end
    return f
end
_G.UIParent   = MakeFrame()
_G.GetLocale  = function() return "enUS" end
_G.C_Timer    = { After = function() end, NewTicker = function() return { Cancel = function() end } end }
_G.InCombatLockdown = function() return false end
_G.hooksecurefunc   = function() end
_G.issecretvalue    = function() return false end
_G.LibStub          = function() return nil end
_G.StaticPopupDialogs, _G.SlashCmdList = {}, {}
_G.ACCEPT, _G.CANCEL = "Accept", "Cancel"
_G.TomoMod_L = setmetatable({}, { __index = function(_, k) return k end })
_G.TomoMod_Utils = { CloseOnEscape = function() end }
_G.print = function() end

assert(loadfile("Core/ModuleRegistry.lua"))()
assert(loadfile("Core/SelectiveImport.lua"))()

local R, SI = _G.TomoMod_Registry, _G.TomoMod_SelectiveImport
_G.TomoMod_MergeTables = function() end
_G.TomoMod_Defaults = {}

R.Define{ key = "np",   label = "l_np",   group = "nameplates", enabledPath = "np.enabled" }
R.Define{ key = "uf",   label = "l_uf",   group = "unitframes", enabledPath = "uf.enabled" }
R.Define{ key = "cast", label = "l_cast", group = "unitframes", enabledPath = "cast.enabled" }
R.Define{ key = "q1",   label = "l_q1",   group = "qol",        enabledPath = "q1.enabled" }
R.Define{ key = "q2",   label = "l_q2",   group = "qol",        enabledPath = "q2.enabled" }

_G.TomoModDB = {
    np = { enabled = true, v = 1 }, uf = { enabled = true, v = 1 },
    cast = { enabled = true, v = 1 }, q1 = { enabled = true, v = 1 },
    q2 = { enabled = true, v = 1 },
}
_G.TomoMod_Lifecycle = {
    Capability = function(k) return k == "uf" and "reload" or "live" end,
    BeginBatch = function() end, EndBatch = function() end,
    ApplyAll = function() end, RequestReload = function() end,
}

assert(loadfile("TomoMod_Options/Config/ImportSelector.lua"))()
local IS = _G.TomoMod_ImportSelector
assert(IS, "ImportSelector ne s'est pas chargé")

-- Trois modules diffèrent, deux sont identiques.
local payload = {
    np   = { enabled = true, v = 2 },
    uf   = { enabled = false, v = 1 },
    cast = { enabled = true, v = 1 },
    q1   = { enabled = true, v = 9 },
    q2   = { enabled = true, v = 1 },
}

-- ═══════════════════════════════════════════════════════════════════════
say("── 1. Ouverture et sélection par défaut ──")

check("le panneau s'ouvre", IS.Show(payload), true)

local free, gfree, used, gused = IS.PoolStats()
check("des lignes ont été créées", used > 0,  true)
check("des groupes ont été créés", gused > 0, true)
check("rien en réserve au départ", free,      0)

-- Trois groupes portent quelque chose : nameplates, unitframes, qol.
check("trois en-têtes de groupe", gused, 3)
check("cinq lignes affichées",    used,  5)

-- ═══════════════════════════════════════════════════════════════════════
say("── 2. Ce qui change est distingué ──")

local groups = SI.Inspect(payload)
local rows = {}
for _, g in ipairs(groups) do
    for _, r in ipairs(g.modules) do rows[r.key] = r end
end
check("np diffère",        rows.np.differs,   true)
check("uf diffère",        rows.uf.differs,   true)
check("cast identique",    rows.cast.differs, false)
check("q1 diffère",        rows.q1.differs,   true)
check("q2 identique",      rows.q2.differs,   false)
check("uf coûte un reload", rows.uf.requiresReload, true)
check("np applicable à chaud", rows.np.requiresReload, false)

check("sélection par défaut = ce qui change", #SI.AllKeys(groups, true), 3)
check("et pas tout",                          #SI.AllKeys(groups),       5)

-- ═══════════════════════════════════════════════════════════════════════
say("── 3. Recyclage des lignes ──")

-- Le point qui compte : redessiner ne doit pas allouer de nouvelles
-- frames une fois le pool amorcé.
local before = framesCreated
IS.Show(payload)
local after = framesCreated
check("second rendu : aucune frame en plus", after, before)

-- Un troisième, pour être sûr que ce n'est pas un hasard de cadence.
IS.Show(payload)
check("troisième rendu non plus", framesCreated, before)

local free2, gfree2, used2, gused2 = IS.PoolStats()
check("toujours cinq lignes en service", used2,  5)
check("toujours trois groupes",          gused2, 3)
check("la réserve reste vide",           free2,  0)

-- Une charge plus petite libère des lignes dans la réserve au lieu de
-- les abandonner.
local small = { np = { enabled = true, v = 2 } }
IS.Show(small)
local free3, _, used3 = IS.PoolStats()
check("charge réduite : une ligne",   used3, 1)
check("les autres sont en réserve",   free3, 4)
check("toujours aucune allocation",   framesCreated, before)

-- Et revenir à la charge complète les reprend sans rien créer.
IS.Show(payload)
local free4, _, used4 = IS.PoolStats()
check("retour complet : cinq lignes", used4, 5)
check("réserve reconsommée",          free4, 0)
check("zéro allocation sur tout le cycle", framesCreated, before)

-- ═══════════════════════════════════════════════════════════════════════
say("── 4. Refus propres ──")

check("charge vide refusée",        IS.Show({}),  false)
check("charge non-table refusée",   IS.Show(nil), false)

-- Aucun module reconnu : le panneau ne s'ouvre pas, l'appelant retombe
-- sur l'ancienne confirmation d'écrasement.
check("charge sans module connu", IS.Show({ inconnu = { x = 1 } }), false)

say(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

-- Banc hors-jeu pour Core/ModuleLifecycle.lua.
--
-- Le moteur touche à trois choses qui font mal quand elles ratent : le
-- flag persisté, l'appel au module, et le report différé en combat. On
-- monte donc de faux modules qui enregistrent ce qu'on leur fait, et on
-- vérifie non pas « ça n'a pas planté » mais « le bon appel a eu lieu,
-- avec le bon argument, au bon moment ».
--
-- Usage : luajit Tools/test_module_lifecycle.lua   (depuis la racine)

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-56s attendu=%-10s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

-- ── Stubs ────────────────────────────────────────────────────────────
local inCombat = false
_G.InCombatLockdown = function() return inCombat end
_G.debugstack       = function() return "" end
_G.geterrorhandler  = function() return function() end end

local combatHandler
_G.CreateFrame = function()
    return {
        RegisterEvent = function() end,
        SetScript = function(_, _, fn) combatHandler = fn end,
    }
end

assert(loadfile("Core/ModuleRegistry.lua"))()
assert(loadfile("Core/ModuleLifecycle.lua"))()
local R, LC = _G.TomoMod_Registry, _G.TomoMod_Lifecycle

-- ── Faux modules ─────────────────────────────────────────────────────
local log
local function ResetWorld()
    log = {}
    R._Reset(); LC._Reset()
    combatHandler, inCombat = nil, false
    _G.TomoModDB = {}
end

local function Spy(name)
    local t = {}
    t.SetEnabled    = function(v) log[#log+1] = name .. ":set(" .. tostring(v) .. ")" end
    t.ApplySettings = function()  log[#log+1] = name .. ":apply" end
    t.Enable        = function()  log[#log+1] = name .. ":enable" end
    t.Disable       = function()  log[#log+1] = name .. ":disable" end
    return t
end

local function joined() return table.concat(log, " ") end

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. Les trois modes d'application ──")

ResetWorld()
_G.SP_setter = Spy("setter")
_G.SP_gate   = Spy("gate")
_G.SP_pair   = Spy("pair")
R.Define{ key = "s", label = "l", group = "qol", enabledPath = "s.enabled",
          global = "SP_setter", applyMode = "setter", apply = "SetEnabled", combatSafe = true }
R.Define{ key = "g", label = "l", group = "qol", enabledPath = "g.enabled",
          global = "SP_gate",   applyMode = "gate",   apply = "ApplySettings", combatSafe = true }
R.Define{ key = "p", label = "l", group = "qol", enabledPath = "p.enabled",
          global = "SP_pair",   applyMode = "pair",   combatSafe = true }
TomoModDB.s = { enabled = false }
TomoModDB.g = { enabled = false }
TomoModDB.p = { enabled = false }
LC.Resolve()

check("setter reconnu vivant", LC.Capability("s"), "live")
check("gate reconnu vivant",   LC.Capability("g"), "live")
check("pair reconnu vivant",   LC.Capability("p"), "live")

log = {}
LC.SetEnabled("s", true)
check("setter reçoit la valeur", joined(), "setter:set(true)")
check("setter : flag écrit",     TomoModDB.s.enabled, true)

log = {}
LC.SetEnabled("g", true)
check("gate appelé sans argument", joined(), "gate:apply")
check("gate : flag écrit",         TomoModDB.g.enabled, true)

log = {}
LC.SetEnabled("p", true)
check("pair : Enable sur true",  joined(), "pair:enable")
log = {}
LC.SetEnabled("p", false)
check("pair : Disable sur false", joined(), "pair:disable")
check("pair : flag écrit",        TomoModDB.p.enabled, false)

-- Le flag est écrit par le registre AVANT l'appel, y compris pour un
-- module dont le SetEnabled n'écrit rien lui-même (cas RareAlert).
ResetWorld()
_G.SP_mute = { SetEnabled = function() end }
R.Define{ key = "mute", label = "l", group = "qol", enabledPath = "mute.enabled",
          global = "SP_mute", applyMode = "setter", apply = "SetEnabled", combatSafe = true }
TomoModDB.mute = { enabled = false }
LC.Resolve()
LC.SetEnabled("mute", true)
check("flag écrit même si le module l'ignore", TomoModDB.mute.enabled, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Absence de chemin vivant ──")

ResetWorld()
R.Define{ key = "dead", label = "l", group = "qol", enabledPath = "dead.enabled",
          requiresReload = true }
R.Define{ key = "unbound", label = "l", group = "qol", enabledPath = "unbound.enabled",
          global = "SP_absent", applyMode = "gate", apply = "ApplySettings" }
R.Define{ key = "passive", label = "l", group = "qol" }
TomoModDB.dead = { enabled = false }
TomoModDB.unbound = { enabled = false }
TomoModDB.passive = {}
LC.Resolve()

check("requiresReload -> reload",   LC.Capability("dead"),    "reload")
check("global absent -> reload",    LC.Capability("unbound"), "reload")
check("passif -> aucune bascule",   LC.Capability("passive"), "none")

local rep = LC.SetEnabled("dead", true)
check("reload : flag quand même écrit", TomoModDB.dead.enabled, true)
check("reload : signalé au caller",     rep.needsReload, true)
check("reload : pas appliqué",          rep.applied,     false)

local repP = LC.SetEnabled("passive", true)
check("passif : rien ne bouge", repP.ok, false)

-- ═══════════════════════════════════════════════════════════════════════
print("── 3. Report en combat ──")

ResetWorld()
_G.SP_unsafe = Spy("unsafe")
_G.SP_safe   = Spy("safe")
R.Define{ key = "unsafe", label = "l", group = "qol", enabledPath = "unsafe.enabled",
          global = "SP_unsafe", applyMode = "gate", apply = "ApplySettings" }
R.Define{ key = "safe", label = "l", group = "qol", enabledPath = "safe.enabled",
          global = "SP_safe", applyMode = "gate", apply = "ApplySettings", combatSafe = true }
TomoModDB.unsafe = { enabled = false }
TomoModDB.safe   = { enabled = false }
LC.Resolve()

inCombat = true
log = {}
local repU = LC.SetEnabled("unsafe", true)
check("combat : différé",            repU.deferred, true)
check("combat : rien appliqué",      joined(), "")
check("combat : flag NON écrit",     TomoModDB.unsafe.enabled, false)
check("file d'attente à 1",          LC.PendingCount(), 1)

local repS = LC.SetEnabled("safe", true)
check("combatSafe : passe quand même", repS.deferred, false)
check("combatSafe : appliqué",         TomoModDB.safe.enabled, true)

inCombat = false
check("un handler de combat est armé", type(combatHandler), "function")
log = {}
combatHandler()
check("rejoué à la sortie de combat", joined(), "unsafe:apply")
check("flag écrit au rejeu",          TomoModDB.unsafe.enabled, true)
check("file vidée",                   LC.PendingCount(), 0)

-- Deux écritures sur la même clé pendant le combat ne doivent rejouer
-- que la dernière volonté du joueur.
inCombat = true
LC.SetEnabled("unsafe", false)
LC.SetEnabled("unsafe", true)
check("une seule entrée par clé", LC.PendingCount(), 1)
inCombat = false
combatHandler()
check("dernière valeur retenue",  TomoModDB.unsafe.enabled, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 4. Dépendances en cascade ──")

ResetWorld()
_G.SP_base  = Spy("base")
_G.SP_child = Spy("child")
R.Define{ key = "base", label = "l", group = "qol", enabledPath = "base.enabled",
          global = "SP_base", applyMode = "gate", apply = "ApplySettings", combatSafe = true }
R.Define{ key = "child", label = "l", group = "qol", enabledPath = "child.enabled",
          deps = { "base" },
          global = "SP_child", applyMode = "gate", apply = "ApplySettings", combatSafe = true }
TomoModDB.base  = { enabled = true }
TomoModDB.child = { enabled = true }
LC.Resolve()

log = {}
local repC = LC.SetEnabled("base", false)
check("cascade signalée",        repC.cascade[1], "child")
check("dépendant coupé aussi",   TomoModDB.child.enabled, false)
check("les deux réappliqués",    #log, 2)

-- Rallumer ne remonte PAS la chaîne : on le signale au lieu de décider
-- à la place du joueur.
local repE = LC.SetEnabled("child", true)
check("pas de cascade montante",  TomoModDB.base.enabled, false)
check("dépendance manquante dite", repE.missingDeps[1], "base")

-- ═══════════════════════════════════════════════════════════════════════
print("── 5. Isolation des erreurs ──")

ResetWorld()
_G.SP_boom = { ApplySettings = function() error("boum") end }
_G.SP_fine = Spy("fine")
R.Define{ key = "boom", label = "l", group = "qol", enabledPath = "boom.enabled",
          global = "SP_boom", applyMode = "gate", apply = "ApplySettings", combatSafe = true }
R.Define{ key = "fine", label = "l", group = "qol", enabledPath = "fine.enabled",
          global = "SP_fine", applyMode = "gate", apply = "ApplySettings", combatSafe = true }
TomoModDB.boom = { enabled = false }
TomoModDB.fine = { enabled = false }
LC.Resolve()

local repB = LC.SetEnabled("boom", true)
check("l'erreur ne remonte pas",     repB.applied,  false)
check("le module en échec dit reload", repB.needsReload, true)
check("le flag a quand même bougé",  TomoModDB.boom.enabled, true)

log = {}
TomoModDB.fine.enabled = true
local applied = LC.ApplyAll()
check("ApplyAll survit au module cassé", applied, 1)

-- ═══════════════════════════════════════════════════════════════════════
print("── 6. Bascule et rapport ──")

ResetWorld()
_G.SP_t = Spy("t")
R.Define{ key = "t", label = "l", group = "qol", enabledPath = "t.enabled",
          global = "SP_t", applyMode = "setter", apply = "SetEnabled", combatSafe = true }
TomoModDB.t = { enabled = false }
LC.Resolve()

LC.Toggle("t")
check("Toggle allume",  TomoModDB.t.enabled, true)
LC.Toggle("t")
check("Toggle éteint",  TomoModDB.t.enabled, false)
check("Toggle inconnu sans casse", LC.Toggle("ghost").ok, false)

local live, reload, none = LC.Summary()
check("résumé : 1 vivant", live, 1)
check("résumé : 0 reload", reload, 0)
check("résumé : 0 inerte", none, 0)

local rows = LC.Report()
check("une ligne par module", #rows, 1)
check("la ligne porte la capacité", rows[1].capability, "live")
check("la ligne dit si c'est lié",  rows[1].bound, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 7. Idempotence ──")

ResetWorld()
_G.SP_i = Spy("i")
R.Define{ key = "i", label = "l", group = "qol", enabledPath = "i.enabled",
          global = "SP_i", applyMode = "setter", apply = "SetEnabled", combatSafe = true }
TomoModDB.i = { enabled = false }
LC.Resolve()
LC.SetEnabled("i", true)
log = {}
LC.SetEnabled("i", true)
check("réécrire la même valeur reste sûr", TomoModDB.i.enabled, true)
check("le module est bien rappelé",        joined(), "i:set(true)")

-- ═══════════════════════════════════════════════════════════════════════
print("── 8. File de rechargement ──")

-- Le debounce passe par C_Timer ; on le remplace par une exécution
-- immédiate contrôlée, pour observer le moment de l'invite au lieu de
-- l'attendre.
local timerQueue = {}
_G.C_Timer = { After = function(_, fn) timerQueue[#timerQueue + 1] = fn end }
local function RunTimers()
    local q = timerQueue; timerQueue = {}
    for _, fn in ipairs(q) do fn() end
end

local prompts
local function ArmSpy()
    prompts = 0
    LC.SetPromptHandler(function() prompts = prompts + 1 end)
end

ResetWorld()
R.Define{ key = "r1", label = "l", group = "qol", enabledPath = "r1.enabled", requiresReload = true }
R.Define{ key = "r2", label = "l", group = "qol", enabledPath = "r2.enabled", requiresReload = true }
R.Define{ key = "r3", label = "l", group = "qol", enabledPath = "r3.enabled", requiresReload = true }
TomoModDB.r1 = { enabled = false }
TomoModDB.r2 = { enabled = false }
TomoModDB.r3 = { enabled = false }
LC.Resolve()
ArmSpy()

LC.SetEnabled("r1", true)
check("mis en file",           LC.PendingReloadCount(), 1)
check("invite pas immédiate", prompts, 0)
LC.SetEnabled("r2", true)
LC.SetEnabled("r3", true)
check("trois en file",         LC.PendingReloadCount(), 3)
RunTimers()
check("une seule invite pour trois", prompts, 1)
check("la file survit au « plus tard »", LC.PendingReloadCount(), 3)

-- Revenir à l'état de connexion retire de la file : il n'y a plus rien
-- que le rechargement réaliserait.
LC.SetEnabled("r1", false)
check("retour à l'état initial -> retiré", LC.PendingReloadCount(), 2)
check("la clé n'est plus marquée",         LC.IsPendingReload("r1"), false)
check("les autres restent",                LC.IsPendingReload("r2"), true)

-- Une clé déjà en file ne réarme pas l'invite.
ArmSpy()
LC.RequestReload("r2")
RunTimers()
check("pas de seconde invite pour la même clé", prompts, 0)

local list = LC.PendingReload()
check("liste triée et complète", table.concat(list, ","), "r2,r3")

LC.ClearReload()
check("ClearReload vide tout", LC.PendingReloadCount(), 0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 9. Invite : combat et lots ──")

ResetWorld()
R.Define{ key = "rc", label = "l", group = "qol", enabledPath = "rc.enabled", requiresReload = true }
TomoModDB.rc = { enabled = false }
LC.Resolve()
ArmSpy()

inCombat = true
LC.RequestReload("rc")
RunTimers()
check("combat : invite retenue",  prompts, 0)
check("combat : file conservée",  LC.PendingReloadCount(), 1)
inCombat = false
combatHandler()
RunTimers()
check("invite libérée après le combat", prompts, 1)

-- Un lot (profil, preset) accumule sans interroger, puis conclut une
-- seule fois.
ResetWorld()
R.Define{ key = "b1", label = "l", group = "qol", enabledPath = "b1.enabled", requiresReload = true }
R.Define{ key = "b2", label = "l", group = "qol", enabledPath = "b2.enabled", requiresReload = true }
TomoModDB.b1 = { enabled = false }
TomoModDB.b2 = { enabled = false }
LC.Resolve()
ArmSpy()

LC.BeginBatch()
LC.SetEnabled("b1", true)
LC.SetEnabled("b2", true)
RunTimers()
check("lot : aucune invite pendant",  prompts, 0)
check("lot : file remplie",           LC.PendingReloadCount(), 2)
LC.EndBatch()
RunTimers()
check("lot : une invite à la fin",    prompts, 1)

-- ═══════════════════════════════════════════════════════════════════════
print("── 10. Notification du bandeau ──")

ResetWorld()
R.Define{ key = "w1", label = "l", group = "qol", enabledPath = "w1.enabled", requiresReload = true }
TomoModDB.w1 = { enabled = false }
LC.Resolve()
ArmSpy()

local seen = {}
LC.OnPendingChanged(function(n) seen[#seen + 1] = n end)
LC.RequestReload("w1")
check("bandeau prévenu de l'ajout", seen[#seen], 1)
LC.CancelReload("w1")
check("bandeau prévenu du retrait", seen[#seen], 0)

-- Un observateur qui plante ne doit pas bloquer le moteur.
LC.OnPendingChanged(function() error("bandeau cassé") end)
LC.RequestReload("w1")
check("observateur cassé sans effet", LC.PendingReloadCount(), 1)

-- Un module vivant ne met jamais rien en file.
ResetWorld()
_G.SP_ok = Spy("ok")
R.Define{ key = "livemod", label = "l", group = "qol", enabledPath = "livemod.enabled",
          global = "SP_ok", applyMode = "gate", apply = "ApplySettings", combatSafe = true }
TomoModDB.livemod = { enabled = false }
LC.Resolve()
LC.SetEnabled("livemod", true)
check("module vivant : rien en file", LC.PendingReloadCount(), 0)

-- Un instantané pris avant l'existence de la DB ne doit pas enregistrer
-- « éteint » pour tout le monde : sinon la première coche de chaque case
-- passerait pour un retour à l'état initial et sortirait de la file.
ResetWorld()
R.Define{ key = "early", label = "l", group = "qol", enabledPath = "early.enabled",
          requiresReload = true }
_G.TomoModDB = nil
LC.Resolve()
_G.TomoModDB = { early = { enabled = false } }
LC.SetEnabled("early", true)
check("instantané sans DB : la file tient", LC.PendingReloadCount(), 1)

print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

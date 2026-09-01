-- Banc hors-jeu pour Core/ContextProfiles.lua.
--
-- Le risque de ce lot n'est pas de mal détecter un donjon : c'est
-- d'échanger la configuration entière au mauvais moment. Trois choses
-- sont donc vérifiées plus que le reste :
--
--   1. Rien ne bouge en combat. Réécrire TomoModDB et réengendrer des
--      frames pendant un pull, c'est exactement le taint que cet addon
--      passe son temps à éviter.
--   2. Les neuf modules épinglés au lot 0 survivent à l'échange. Un
--      studio ouvert en raid ne doit pas se refermer en entrant en clé.
--   3. On ne réclame un /reload que si l'échange change vraiment quels
--      modules sont allumés. Sinon le joueur en prendrait un à chaque
--      changement de zone.
--
-- Usage : luajit Tools/test_context_profiles.lua   (depuis la racine)

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-54s attendu=%-12s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

-- ── Monde simulé ─────────────────────────────────────────────────────
local W = { challenge = false, instance = "none", inRaid = false, inGroup = false, combat = false }

_G.C_ChallengeMode = { IsChallengeModeActive = function() return W.challenge end }
_G.GetInstanceInfo  = function() return "Zone", W.instance end
_G.IsInRaid         = function() return W.inRaid end
_G.IsInGroup        = function() return W.inGroup end
_G.InCombatLockdown = function() return W.combat end

local combatHandlers = {}
_G.CreateFrame = function()
    return {
        RegisterEvent = function() end,
        SetScript = function(_, _, fn) combatHandlers[#combatHandlers + 1] = fn end,
    }
end

assert(loadfile("Core/ModuleRegistry.lua"))()
assert(loadfile("Core/ContextProfiles.lua"))()
local R, CTX = _G.TomoMod_Registry, _G.TomoMod_Context

-- Faux Profiles.lua : même surface que le vrai, mais observable.
local applied
local function FakeProfiles()
    return {
        EnsureProfilesDB   = function() end,
        GetCurrentSpecID   = function() return 250 end,
        AutoSaveActiveProfile = function() end,
        ApplyForContext = function(name)
            local db = TomoModDB._profiles
            local snap = db.named[name]
            if not snap then return false end
            -- Reproduit le vrai : remplace tout SAUF les épinglés.
            local pinned = {}
            for _, key in ipairs(R.ContextPinned()) do
                local m = R.Get(key)
                if m and TomoModDB[m.dbKey] ~= nil then pinned[m.dbKey] = TomoModDB[m.dbKey] end
            end
            for k in pairs(TomoModDB) do
                if k ~= "_profiles" then TomoModDB[k] = nil end
            end
            for k, v in pairs(snap) do TomoModDB[k] = v end
            for k, v in pairs(pinned) do TomoModDB[k] = v end
            db.activeProfile = name
            applied = name
            return true
        end,
    }
end

local function ResetWorld()
    R._Reset(); CTX._Reset()
    combatHandlers = {}
    applied = nil
    W.challenge, W.instance, W.inRaid, W.inGroup, W.combat = false, "none", false, false, false
    _G.TomoMod_Profiles = FakeProfiles()
    _G.TomoMod_Lifecycle = nil
    _G.TomoModDB = { _profiles = { named = {}, contextProfiles = {}, activeProfile = "Default",
                                   contextEnabled = true } }
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. Détection du contenu ──")

ResetWorld()
check("hors instance, seul",       CTX.Detect(), "solo")
W.inGroup = true
check("groupe en extérieur",       CTX.Detect(), "party")
W.inRaid = true
check("raid en extérieur",         CTX.Detect(), "raid")
W.inRaid, W.inGroup = false, false

W.instance = "party"
check("donjon",                    CTX.Detect(), "party")
W.challenge = true
check("clé lancée -> mythicplus",  CTX.Detect(), "mythicplus")
W.challenge = false
check("clé finie -> donjon",       CTX.Detect(), "party")

W.instance = "raid"
check("raid",                      CTX.Detect(), "raid")
W.instance = "arena"
check("arène -> pvp",              CTX.Detect(), "pvp")
W.instance = "pvp"
check("champ de bataille -> pvp",  CTX.Detect(), "pvp")

-- La clé prime sur tout : un donjon mythique+ reste mythique+ même en
-- groupe, en instance party.
W.instance, W.challenge, W.inGroup = "party", true, true
check("la clé prime",              CTX.Detect(), "mythicplus")

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Affectations et résolution ──")

ResetWorld()
TomoModDB._profiles.named["Raid"]  = { unitFrames = {} }
TomoModDB._profiles.named["Keys"]  = { unitFrames = {} }

check("profil inconnu refusé",     CTX.Assign(250, "raid", "Fantome"), false)
check("contexte inconnu refusé",   CTX.Assign(250, "nawak", "Raid"),   false)
check("affectation valide",        CTX.Assign(250, "raid", "Raid"),    true)
check("résolue pour cette spé",    CTX.Resolve("raid", 250),           "Raid")
check("pas pour une autre spé",    CTX.Resolve("raid", 577),           nil)

CTX.Assign("*", "mythicplus", "Keys")
check("joker toutes spés",         CTX.Resolve("mythicplus", 577),     "Keys")

-- La règle la plus spécifique gagne.
CTX.Assign(250, "mythicplus", "Raid")
check("spé précise prime sur joker", CTX.Resolve("mythicplus", 250),   "Raid")
check("le joker sert encore ailleurs", CTX.Resolve("mythicplus", 999), "Keys")

-- Un profil supprimé après affectation : on ne doit ni planter ni
-- appliquer du vide, et la clé morte doit disparaître.
TomoModDB._profiles.named["Keys"] = nil
check("affectation orpheline ignorée", CTX.Resolve("mythicplus", 999), nil)
check("clé morte nettoyée", TomoModDB._profiles.contextProfiles["*:mythicplus"], nil)

check("désaffectation", CTX.Unassign(250, "raid"), true)
check("plus rien",      CTX.Resolve("raid", 250),  nil)

-- ═══════════════════════════════════════════════════════════════════════
print("── 3. Échange effectif ──")

ResetWorld()
TomoModDB._profiles.named["Raid"] = { marker = "raid-snap" }
CTX.Assign("*", "raid", "Raid")
CTX.Initialize()
check("amorçage sans échange", applied, nil)

W.instance = "raid"
local rep = CTX.Evaluate()
check("échange déclenché",   rep.swapped, true)
check("bon profil appliqué", applied,     "Raid")
check("contexte retenu",     CTX.Current(), "raid")
check("DB remplacée",        TomoModDB.marker, "raid-snap")

-- Réévaluer sans changement ne doit rien refaire.
applied = nil
check("pas de ré-échange", CTX.Evaluate(), nil)
check("rien réappliqué",   applied,        nil)

-- Un contexte sans affectation laisse les règles de spé décider.
W.instance = "none"
applied = nil
local rep2 = CTX.Evaluate()
check("sans affectation : pas d'échange", rep2.swapped, false)
check("rien appliqué",                    applied,      nil)
check("contexte quand même noté",         CTX.Current(), "solo")

-- Désactivé globalement, rien ne se passe.
ResetWorld()
TomoModDB._profiles.contextEnabled = false
TomoModDB._profiles.named["Raid"] = {}
CTX.Assign("*", "raid", "Raid")
W.instance = "raid"
check("moteur éteint : aucun échange", CTX.Evaluate(), nil)

-- ═══════════════════════════════════════════════════════════════════════
print("── 4. Combat ──")

ResetWorld()
TomoModDB._profiles.named["Keys"] = { marker = "keys" }
CTX.Assign("*", "mythicplus", "Keys")
CTX.Initialize()

W.combat = true
W.instance, W.challenge = "party", true
local rep3 = CTX.Evaluate()
check("combat : différé",       rep3.deferred, true)
check("combat : rien appliqué", applied,       nil)
check("combat : en attente",    CTX.Pending(), "mythicplus")

W.combat = false
check("un observateur est armé", #combatHandlers > 0, true)
for _, fn in ipairs(combatHandlers) do fn(nil, "PLAYER_REGEN_ENABLED") end
check("rejoué après le combat", applied,       "Keys")
check("file vidée",             CTX.Pending(), nil)

-- ═══════════════════════════════════════════════════════════════════════
print("── 5. Modules épinglés (arbitrage lot 0) ──")

ResetWorld()
R.Define{ key = "layout", label = "l", group = "qol", enabledPath = "layout.enabled" }
R.Define{ key = "diag",   label = "l", group = "qol", enabledPath = "diag.enabled",
          contextSwap = false }
TomoModDB.layout = { enabled = true,  tag = "solo" }
TomoModDB.diag   = { enabled = true,  tag = "ouvert" }
TomoModDB._profiles.named["Raid"] = {
    layout = { enabled = true, tag = "raid" },
    diag   = { enabled = false, tag = "fermé" },
}
CTX.Assign("*", "raid", "Raid")
CTX.Initialize()
W.instance = "raid"
CTX.Evaluate()

check("module suiveur remplacé",  TomoModDB.layout.tag, "raid")
check("module épinglé conservé",  TomoModDB.diag.tag,   "ouvert")
check("épinglé garde son état",   TomoModDB.diag.enabled, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 6. Prédiction de rechargement ──")

ResetWorld()
_G.TomoMod_Lifecycle = {
    Capability = function(key) return key == "vivant" and "live" or "reload" end,
    BeginBatch = function() end, EndBatch = function() end,
    ApplyAll = function() end,
    RequestReload = function() end,
}
R.Define{ key = "vivant",  label = "l", group = "qol", enabledPath = "vivant.enabled" }
R.Define{ key = "lourd",   label = "l", group = "qol", enabledPath = "lourd.enabled" }
R.Define{ key = "identique", label = "l", group = "qol", enabledPath = "identique.enabled" }
R.Define{ key = "epingle", label = "l", group = "qol", enabledPath = "epingle.enabled",
          contextSwap = false }
TomoModDB.vivant    = { enabled = true }
TomoModDB.lourd     = { enabled = true }
TomoModDB.identique = { enabled = true }
TomoModDB.epingle   = { enabled = true }

local snap = {
    vivant    = { enabled = false },   -- change, mais applicable à chaud
    lourd     = { enabled = false },   -- change, et pas applicable
    identique = { enabled = true  },   -- ne change pas
    epingle   = { enabled = false },   -- épinglé : ne suit pas le contenu
}
local reloads = CTX.PredictReloads(snap)
check("un seul reload prédit",  #reloads,   1)
check("c'est le bon module",    reloads[1], "lourd")

-- Un réglage qui change sans toucher au flag ne justifie aucun reload :
-- c'est le cas courant d'un profil de contenu, et le contraire
-- réclamerait un /reload à chaque changement de zone.
local cosmetic = {
    vivant    = { enabled = true, taille = 42 },
    lourd     = { enabled = true, couleur = "rouge" },
    identique = { enabled = true },
    epingle   = { enabled = true },
}
check("changement cosmétique : aucun reload", #CTX.PredictReloads(cosmetic), 0)
check("snapshot vide toléré",  #CTX.PredictReloads({}),  0)
check("non-table tolérée",     #CTX.PredictReloads(nil), 0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 7. IsEnabledIn sur une table arbitraire ──")

ResetWorld()
R.Define{ key = "simple", label = "l", group = "qol", enabledPath = "simple.enabled" }
R.Define{ key = "comp",   label = "l", group = "qol",
          toggles = { { path = "comp.a" }, { path = "comp.b" } } }
local src = { simple = { enabled = true }, comp = { a = false, b = true } }
check("simple lu hors DB",     R.IsEnabledIn(src, "simple"), true)
check("composite lu hors DB",  R.IsEnabledIn(src, "comp"),   true)
check("source vide",           R.IsEnabledIn({}, "simple"),  false)
check("source non-table",      R.IsEnabledIn(nil, "simple"), nil)
check("module inconnu",        R.IsEnabledIn(src, "ghost"),  nil)

print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

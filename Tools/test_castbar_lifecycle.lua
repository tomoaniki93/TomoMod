-- Invariants du cycle de vie de la castbar : analyse statique.
--
-- Le correctif v4.0.1 repose sur quatre propriétés qui ne se voient pas à la
-- lecture d'un diff ultérieur, et dont la rupture ne produit aucune erreur --
-- juste une barre qui se ferme trop tôt, ou plus du tout. Elles sont donc
-- figées ici.
--
--   1. SUCCEEDED ne ferme plus la barre. C'était la cause du bug : un
--      instantané ou un proc lancé PENDANT un cast long émet son propre
--      SUCCEEDED, et l'ancien code fermait la barre du sort en cours.
--
--   2. Les identifiants de cast passent par issecretvalue avant toute
--      comparaison. Midnight peut marquer castGUID ou spellID secret, et
--      comparer un secret taint la session.
--
--   3. FadeOut appelle ResetState en premier. C'est ce qui garantit qu'aucun
--      castGUID périmé ne survit à une fermeture -- sans ça, le STOP du cast
--      suivant serait filtré comme « étranger » et la barre resterait figée.
--
--   4. Un filet de temps ferme une barre restée au-delà de sa fin annoncée.
--      Retirer SUCCEEDED du cycle a supprimé une redondance, et pour le joueur
--      il n'en restait aucune autre : le garde « l'unité a disparu » de
--      l'OnUpdate exclut explicitement "player".
--
-- Usage : luajit Tools/test_castbar_lifecycle.lua   (depuis la racine)

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-54s attendu=%-8s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end
local function fail(m) ok = false; print("  ÉCHEC " .. m) end

local fh = assert(io.open("Modules/Interface/Castbars/Castbar.lua", "rb"),
                  "Castbar.lua introuvable")
local src = fh:read("*a"); fh:close()
src = (src:gsub("^\239\187\191", ""):gsub("\r\n", "\n"))

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. SUCCEEDED ne termine plus le cycle ──")

local succeeded = src:match('elseif event == "UNIT_SPELLCAST_SUCCEEDED" then(.-)elseif event ==')
check("la branche SUCCEEDED existe", succeeded ~= nil, true)
if succeeded then
    check("elle n'appelle plus FadeOut", succeeded:find("FadeOut", 1, true), nil)
    check("elle sort immédiatement",     succeeded:find("return", 1, true) ~= nil, true)
end

-- STOP reste le signal canonique de fin.
check("STOP ferme toujours la barre",
      src:find('event == "UNIT_SPELLCAST_STOP"', 1, true) ~= nil, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Les valeurs secrètes sont gardées ──")

check("PlainEventValue existe",
      src:find("local function PlainEventValue", 1, true) ~= nil, true)
check("il appelle issecretvalue",
      src:find("issecretvalue", 1, true) ~= nil, true)

-- Le point qui compte : aucune comparaison directe des identifiants bruts.
-- Tout doit transiter par PlainEventValue.
local raw = 0
for line in src:gmatch("[^\n]+") do
    if line:find("_activeCastGUID") and line:find("==")
       and not line:find("PlainEventValue", 1, true) then
        raw = raw + 1
        fail("comparaison de castGUID sans garde : " .. line:gsub("^%s+", ""))
    end
end
check("aucune comparaison non gardée", raw, 0)

-- Le repli doit être permissif : sans identité sûre on ne filtre pas, sinon
-- un client qui cacherait les deux identifiants bloquerait toutes les barres.
local belongs = src:match("local function EventBelongsToActiveCast(.-)\n    end")
check("EventBelongsToActiveCast existe", belongs ~= nil, true)
if belongs then
    check("le repli renvoie true", belongs:match("return true%s*$") ~= nil, true)
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 3. Aucune identité périmée ne survit ──")

local fade = src:match("local function FadeOut%(self%)(.-)\n    end")
check("FadeOut existe", fade ~= nil, true)
if fade then
    -- ResetState doit être la PREMIÈRE instruction : si la barre se ferme sans
    -- effacer l'identité, le STOP du cast suivant est filtré comme étranger.
    local first = fade:match("^%s*([%w_]+)")
    check("ResetState est appelé en premier", first, "ResetState")
end

local reset = src:match("local function ResetState%(self%)(.-)\n    end")
check("ResetState efface le GUID",
      reset and reset:find("_activeCastGUID%s*=%s*nil") ~= nil, true)
check("ResetState efface le spellID",
      reset and reset:find("_activeEventSpellID%s*=%s*nil") ~= nil, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 4. Filet de temps ──")

check("la constante de grâce existe",
      src:find("STALE_CAST_GRACE", 1, true) ~= nil, true)

local grace = tonumber(src:match("local STALE_CAST_GRACE%s*=%s*([%d%.]+)"))
check("la grâce est définie", grace ~= nil, true)
if grace then
    -- Trop court : un cast repoussé se fermerait avant son DELAYED.
    -- Trop long : la barre reste visible assez longtemps pour être signalée.
    check("grâce ≥ 0.5 s", grace >= 0.5, true)
    check("grâce ≤ 3 s",   grace <= 3.0, true)
end

local onupdate = src:match('castbar:SetScript%("OnUpdate", function%(self, elapsed%)(.-)\n    end%)')
check("l'OnUpdate est trouvé", onupdate ~= nil, true)
if onupdate then
    check("le filet est dans l'OnUpdate",
          onupdate:find("STALE_CAST_GRACE", 1, true) ~= nil, true)
    -- Les sorts à charge se maintiennent volontairement au-delà de leur fin.
    local net = onupdate:match("(if self%._realEndSec.-STALE_CAST_GRACE then)")
    check("le filet exclut les sorts à charge",
          net and net:find("not self.empowered", 1, true) ~= nil, true)

    -- Il doit venir APRÈS l'arrêt anticipé, sinon il s'exécuterait sur une
    -- barre déjà éteinte et couperait les animations de fondu.
    local idleAt = onupdate:find("if not self.casting and not self.channeling", 1, true)
    local netAt  = onupdate:find("STALE_CAST_GRACE", 1, true)
    check("il vient après l'arrêt anticipé", (idleAt and netAt and netAt > idleAt) or false, true)
end

-- Le garde « unité disparue » exclut le joueur : c'est la raison d'être du
-- filet, donc si quelqu'un l'étend un jour au joueur, ce test doit être relu.
check("le garde d'unité exclut toujours le joueur",
      src:find('if self.unit ~= "player" then', 1, true) ~= nil, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 5. Les deux aperçus restent indépendants ──")

check("drapeau du mode layout",  src:find("_layoutPreview", 1, true) ~= nil, true)
check("drapeau du mode config",  src:find("_previewMode", 1, true) ~= nil, true)
check("matérialisation à la demande",
      src:find("local function EnsurePlayerCastbar", 1, true) ~= nil, true)

-- Le déverrouillage layout ne doit pas dépendre du panneau de config : c'est
-- tout l'objet du correctif, une castbar déplaçable sans ouvrir le GUI.
local unlock = src:match("function CB.UnlockPlayerCastbar%(%)(.-)\nend")
check("UnlockPlayerCastbar existe", unlock ~= nil, true)
if unlock then
    check("il ne dépend pas de TomoMod_Options",
          unlock:find("TomoMod_Options", 1, true), nil)
end

-- Entrer en combat doit rendre la main aux vrais casts.
check("le combat annule les aperçus",
      src:find('event == "PLAYER_REGEN_DISABLED"', 1, true) ~= nil, true)

print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

-- Couverture de l'inventaire réel : Core/ModuleManifest.lua confronté à
-- TomoMod_Defaults et aux six fichiers de langue.
--
-- Trois propriétés sont verrouillées ici, parce qu'aucune ne peut être
-- vérifiée en jeu sans que le joueur en paie le prix :
--
--   1. Bijection stricte manifeste <-> defaults. Une clé de DB sans
--      manifeste disparaîtrait de l'import sélectif sans que personne
--      ne s'en aperçoive ; un manifeste sans clé de DB pointerait dans
--      le vide.
--   2. Chaque chemin déclaré (bascule, sous-bascule, ancre) se résout
--      vraiment dans les defaults, avec la forme annoncée pour les
--      ancres. Une ancre qui pointe sur nil ferait échouer le lot 2 au
--      moment de la migration, pas à l'écriture.
--   3. Chaque clé de locale citée existe dans les SIX langues. Le
--      metatable de localisation renvoie la clé brute pour une clé
--      absente : une traduction manquante ne lève rien, elle s'affiche
--      telle quelle à l'écran.
--
-- Usage : luajit Tools/test_module_manifest_static.lua   (depuis la racine)

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-58s attendu=%-8s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end
local function fail(msg)
    ok = false
    print("  ÉCHEC " .. msg)
end

-- ── Stubs minimaux : Database.lua ne fait que remplir une table, mais
-- il est écrit pour tourner en jeu. On lui donne le strict nécessaire.
_G.GetLocale        = function() return "enUS" end
_G.UIParent         = {}
_G.CreateFrame      = function() return setmetatable({}, { __index = function() return function() end end }) end
_G.C_Timer          = { After = function() end, NewTicker = function() return { Cancel = function() end } end }
_G.GetPhysicalScreenSize = function() return 2560, 1440 end
_G.InCombatLockdown = function() return false end
_G.hooksecurefunc   = function() end
_G.issecretvalue    = function() return false end
_G.LibStub          = function() return nil end
_G.StaticPopupDialogs, _G.SlashCmdList = {}, {}

pcall(assert(loadfile("Core/Database.lua")))
local D = _G.TomoMod_Defaults
assert(type(D) == "table", "TomoMod_Defaults introuvable")

assert(loadfile("Core/ModuleRegistry.lua"))()
local R = _G.TomoMod_Registry
assert(loadfile("Core/ModuleManifest.lua"))()

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. Validate sur l'inventaire réel ──")

local vOK, errs = R.Validate(D)
if not vOK then
    for _, e in ipairs(errs) do print("       " .. e) end
end
check("aucune erreur de validation", vOK, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Bijection manifeste <-> TomoMod_Defaults ──")

local manifestByDB = {}
for _, m in ipairs(R.ListAll()) do manifestByDB[m.dbKey] = m end

local missing, dbCount = 0, 0
for key in pairs(D) do
    dbCount = dbCount + 1
    if not manifestByDB[key] then
        missing = missing + 1
        fail(("clé de defaults sans manifeste : '%s'"):format(key))
    end
end
check("toute clé de DB a son manifeste", missing, 0)

local extra = 0
for _, m in ipairs(R.ListAll()) do
    if D[m.dbKey] == nil then
        extra = extra + 1
        fail(("manifeste sans clé de defaults : '%s'"):format(m.key))
    end
end
check("tout manifeste a sa clé de DB", extra, 0)
check("couverture complète", #R.ListAll(), dbCount)

-- ═══════════════════════════════════════════════════════════════════════
print("── 3. Les chemins déclarés se résolvent ──")

local badToggle, badAnchor, badShape = 0, 0, 0

for _, m in ipairs(R.ListAll()) do
    if m.toggleModel == "simple" then
        if type(R.GetPath(D, m.enabledPath)) ~= "boolean" then
            badToggle = badToggle + 1
            fail(("'%s' : enabledPath '%s' n'est pas un booléen des defaults"):format(m.key, m.enabledPath))
        end
    elseif m.toggleModel == "composite" then
        for _, t in ipairs(m.toggles) do
            if type(R.GetPath(D, t.path)) ~= "boolean" then
                badToggle = badToggle + 1
                fail(("'%s' : sous-bascule '%s' n'est pas un booléen des defaults"):format(m.key, t.path))
            end
        end
    end

    for _, a in ipairs(m.anchors) do
        local node = R.GetPath(D, a.path)
        if type(node) ~= "table" then
            badAnchor = badAnchor + 1
            fail(("'%s' : ancre '%s' ne se résout pas ('%s')"):format(m.key, a.id, a.path))
        else
            -- La forme annoncée doit correspondre aux champs réellement
            -- présents, sinon le lot 2 lirait la mauvaise paire de clés.
            local shape = R.ANCHOR_SHAPES[a.shape]
            if node[shape.point] == nil or node[shape.rel] == nil then
                badShape = badShape + 1
                fail(("'%s' : ancre '%s' annonce '%s' mais ne porte pas %s/%s")
                    :format(m.key, a.id, a.shape, shape.point, shape.rel))
            end
        end
    end
end

check("bascules résolues",  badToggle, 0)
check("ancres résolues",    badAnchor, 0)
check("formes conformes",   badShape,  0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 4. Parité des locales sur les six langues ──")

local function read(path)
    local fh = assert(io.open(path, "rb"), "fichier introuvable : " .. path)
    local s = fh:read("*a")
    fh:close()
    s = s:gsub("^\239\187\191", "")
    return (s:gsub("\r\n", "\n"))
end

-- Chaque bloc TomoMod_RegisterLocale("xx", { ... }) du fichier de
-- libellés est dépouillé de ses clés. On ne cherche que celles-là :
-- les grands fichiers de langue ne sont pas censés porter le namespace.
local locSrc  = read("Locales/Locale_Modules.lua")
local LOCALES = { "enUS", "frFR", "deDE", "esES", "itIT", "ptBR" }
local defined = {}

for _, loc in ipairs(LOCALES) do
    defined[loc] = {}
    local blockStart = locSrc:find('TomoMod_RegisterLocale%("' .. loc .. '"', 1)
    if not blockStart then
        fail(("aucun bloc de locale pour %s"):format(loc))
    else
        local blockEnd = locSrc:find("\n}%)", blockStart) or #locSrc
        -- Toutes les clés, pas seulement le namespace mod_ : ce fichier
        -- porte aussi les noms de cadres (frame_*) et le repli générique
        -- de la superposition de déplacement.
        for key in locSrc:sub(blockStart, blockEnd):gmatch('%["([%w_]+)"%]%s*=') do
            defined[loc][key] = true
        end
    end
end

check("six blocs de locale", #LOCALES, 6)

-- Toutes les clés que les manifestes citent réellement.
local needed = {}
for _, g in ipairs(R.GROUPS) do needed[g.label] = true end
for _, m in ipairs(R.ListAll()) do
    if m.label then needed[m.label] = true end
    for _, t in ipairs(m.toggles or {}) do
        if t.label then needed[t.label] = true end
    end
    -- Lot 2 : le nom affiché sur la superposition de déplacement. Une
    -- clé manquante ici ne lève rien, elle s'affiche brute au milieu de
    -- l'écran pendant que le joueur déplace le cadre.
    for _, a in ipairs(m.anchors or {}) do
        if a.label then needed[a.label] = true end
    end
end

-- La couche de présentation du rechargement puise dans le même
-- namespace sans passer par un manifeste. On lit ses appels L("...")
-- pour que ses clés soient couvertes par la parité comme les autres, et
-- pour qu'elles ne soient pas comptées comme orphelines.
local uiSrc = read("Core/ModuleReloadUI.lua")
local uiKeys = 0
for key in uiSrc:gmatch('L%("(mod_[%w_]+)"') do
    needed[key] = true
    uiKeys = uiKeys + 1
end
check("clés citées par l'UI de rechargement", uiKeys > 0, true)

-- Core/Utils.lua consomme le repli de la superposition de déplacement
-- directement, sans passer par un manifeste.
local utilsSrc = read("Core/Utils.lua")
local utilsKeys = 0
for key in utilsSrc:gmatch('TomoMod_L%["(mover_[%w_]+)"%]') do
    needed[key] = true
    utilsKeys = utilsKeys + 1
end
check("repli de déplacement cité par Utils", utilsKeys > 0, true)

-- Lot 3 : les descripteurs de domaine AstralForge et la table de sujets
-- du studio puisent dans le même fichier de locale. Leurs clés arrivent
-- par labelKey, pas par un manifeste de module, donc on les relit à la
-- source plutôt que de les inscrire en dur ici -- une liste figée se
-- désynchroniserait au premier domaine ajouté.
local forgeConsumers = {
    "Modules/Interface/Castbars/CBElements.lua",
    "TomoMod_AstralForge/AstralForge.lua",
}
local forgeKeys = 0
for _, path in ipairs(forgeConsumers) do
    local src = read(path)
    for key in src:gmatch('labelKey%s*=%s*"([%w_]+)"') do
        needed[key] = true
        forgeKeys = forgeKeys + 1
    end
    -- Textes de démonstration de l'aperçu.
    for key in src:gmatch('TomoMod_L%["(cb_[%w_]+)"%]') do
        needed[key] = true
        forgeKeys = forgeKeys + 1
    end
end
check("clés citées par les domaines Forge", forgeKeys > 0, true)

-- Lot 4 : les libellés de contexte sont déclarés dans la table CONTEXTS
-- du moteur et consommés par la commande slash. Comme pour les domaines
-- Forge, on les relit à la source plutôt que d'en figer la liste.
local ctxKeys = 0
for _, path in ipairs({ "Core/ContextProfiles.lua", "Core/Init.lua" }) do
    local src = read(path)
    for key in src:gmatch('label%s*=%s*"(ctx_[%w_]+)"') do
        needed[key] = true; ctxKeys = ctxKeys + 1
    end
    for key in src:gmatch('L%["(ctx_[%w_]+)"%]') do
        needed[key] = true; ctxKeys = ctxKeys + 1
    end
end
-- ctx_any_spec habille le joker "*" dans la future interface ; il est
-- traduit d'avance, on l'inscrit pour qu'il ne compte pas pour orphelin.
needed["ctx_any_spec"] = true
check("clés de contexte citées", ctxKeys > 0, true)

-- Lot 5 : les libellés de palier vivent dans la table TIERS du moteur,
-- le reste est consommé par la commande slash. Même lecture à la source
-- que pour les lots 3 et 4.
local resKeys = 0
for _, path in ipairs({ "Core/ResolutionPresets.lua", "Core/Init.lua" }) do
    local src = read(path)
    for key in src:gmatch('label%s*=%s*"(res_[%w_]+)"') do
        needed[key] = true; resKeys = resKeys + 1
    end
    for key in src:gmatch('L%["(res_[%w_]+)"%]') do
        needed[key] = true; resKeys = resKeys + 1
    end
end
check("clés de résolution citées", resKeys > 0, true)

-- Lot 6 : les libellés de l'import sélectif sont consommés par la
-- commande slash en attendant le panneau du lot 7.
local impKeys = 0
for key in read("Core/Init.lua"):gmatch('L%["(imp_[%w_]+)"%]') do
    needed[key] = true; impKeys = impKeys + 1
end
-- Lot 7 : le panneau de sélection passe par son propre helper T(clé, repli).
for key in read("TomoMod_Options/Config/ImportSelector.lua"):gmatch('T%("(imp_[%w_]+)"') do
    needed[key] = true; impKeys = impKeys + 1
end
check("clés d'import citées", impKeys > 0, true)

local neededCount, gaps = 0, 0
for key in pairs(needed) do
    neededCount = neededCount + 1
    for _, loc in ipairs(LOCALES) do
        if not defined[loc][key] then
            gaps = gaps + 1
            fail(("clé '%s' absente de %s"):format(key, loc))
        end
    end
end
check("clés citées par les manifestes", neededCount > 0, true)
check("aucune traduction manquante",    gaps, 0)

-- L'inverse : une clé traduite six fois que plus personne ne cite est
-- du poids mort, et signale surtout un renommage à moitié fait.
local orphans = 0
for key in pairs(defined.enUS) do
    if not needed[key] then
        orphans = orphans + 1
        fail(("clé de locale orpheline : '%s'"):format(key))
    end
end
check("aucune clé orpheline", orphans, 0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 5. Cohérence de l'inventaire ──")

local pub = R.List()
check("modules publics",  #pub > 0, true)
check("groupes non vides", #R.Tree() > 0, true)

-- Chaque groupe déclaré doit être peuplé : un groupe vide dans le
-- registre est soit un oubli d'affectation, soit un groupe à supprimer.
local emptyGroups = 0
for _, g in ipairs(R.GROUPS) do
    if #R.ListByGroup(g.key) == 0 then
        emptyGroups = emptyGroups + 1
        fail(("groupe déclaré mais vide : '%s'"):format(g.key))
    end
end
check("aucun groupe vide", emptyGroups, 0)

-- Un module épinglé hors contexte est une exception qui doit rester
-- rare ; si la moitié de l'inventaire s'épingle, l'arbitrage A ne veut
-- plus rien dire.
local pinned = 0
for _, m in ipairs(pub) do
    if not m.contextSwap then pinned = pinned + 1 end
end
check("épinglés minoritaires", pinned * 2 < #pub, true)

-- Les domaines Forge cités doivent être ceux qui existent vraiment.
local KNOWN_DOMAINS = { unitframes = true, nameplates = true }
local badDomain = 0
for _, m in ipairs(R.ListAll()) do
    if m.forgeDomain and not KNOWN_DOMAINS[m.forgeDomain] then
        badDomain = badDomain + 1
        fail(("'%s' cite un domaine Forge inconnu : '%s'"):format(m.key, m.forgeDomain))
    end
end
check("domaines Forge connus", badDomain, 0)

print()
print(("  Inventaire : %d modules publics, %d internes, %d ancres, %d clés de locale")
    :format(#pub, #R.ListAll() - #pub, #R.Anchors(), neededCount))
local reloads = 0
for _, m in ipairs(pub) do if m.requiresReload then reloads = reloads + 1 end end
print(("  Lot 1 : %d/%d modules exigent encore un rechargement")
    :format(reloads, #pub))

-- ═══════════════════════════════════════════════════════════════════════
print("── 6. Les cibles du cycle de vie existent vraiment ──")

-- Un manifeste peut nommer n'importe quel global et n'importe quelle
-- méthode : rien ne le contredit tant que le jeu n'a pas tourné, et
-- l'erreur se voit alors comme un interrupteur qui ne répond pas. On
-- relit donc les sources pour prouver que chaque cible déclarée est
-- réellement définie quelque part.

local function ScanSources()
    local owners, methods = {}, {}
    local dirs = { "Modules", "Core" }
    local files = {}
    local function collect(dir)
        -- io.popen est disponible hors du jeu ; le harnais n'est jamais
        -- chargé en jeu, donc c'est sans conséquence pour le client.
        local pipe = io.popen('find "' .. dir .. '" -name "*.lua" 2>/dev/null')
        if not pipe then return end
        for line in pipe:lines() do files[#files + 1] = line end
        pipe:close()
    end
    for _, d in ipairs(dirs) do collect(d) end

    for _, path in ipairs(files) do
        local src = read(path)
        -- Table globale : « TomoMod_X = TomoMod_X or {} » ou « TomoMod_X = {} »
        for g in src:gmatch("\n(TomoMod_%w+)%s*=%s*[%w_]*%s*o?r?%s*{") do
            owners[g] = owners[g] or path
        end
        for g in src:gmatch("^(TomoMod_%w+)%s*=%s*[%w_]*%s*o?r?%s*{") do
            owners[g] = owners[g] or path
        end
        -- Alias local usuel : « local M = TomoMod_X »
        local aliases = {}
        for alias, g in src:gmatch("\nlocal%s+(%w+)%s*=%s*(TomoMod_%w+)") do
            aliases[alias] = g
        end
        for holder, fn in src:gmatch("\nfunction%s+([%w_]+)[.:]([%w_]+)") do
            local target = aliases[holder] or (holder:match("^TomoMod_") and holder)
            if target then
                methods[target] = methods[target] or {}
                methods[target][fn] = true
            end
        end
    end
    return owners, methods
end

local owners, methods = ScanSources()

local badGlobal, badMethod, withMode = 0, 0, 0
for _, m in ipairs(R.ListAll()) do
    if m.global then
        if not owners[m.global] and not (methods[m.global] and next(methods[m.global])) then
            badGlobal = badGlobal + 1
            fail(("'%s' : le global '%s' n'est défini nulle part"):format(m.key, m.global))
        end
    end
    if m.applyMode then
        withMode = withMode + 1
        local want = {}
        if m.applyMode == "pair" then
            want = { "Enable", "Disable" }
        else
            want = { m.apply }
        end
        for _, fn in ipairs(want) do
            if not (methods[m.global] and methods[m.global][fn]) then
                badMethod = badMethod + 1
                fail(("'%s' : %s.%s() introuvable dans les sources"):format(m.key, m.global, fn))
            end
        end
    end
end

check("globaux déclarés trouvés",  badGlobal, 0)
check("méthodes d'application trouvées", badMethod, 0)
check("au moins un module vivant",  withMode > 0, true)

-- Un mode d'application et un requiresReload s'excluent : Define lève
-- déjà, mais la garde est reprise ici pour que l'inventaire réel soit
-- couvert et pas seulement les manifestes synthétiques du banc.
local contradiction = 0
for _, m in ipairs(R.ListAll()) do
    if m.applyMode and m.requiresReload then
        contradiction = contradiction + 1
        fail(("'%s' déclare à la fois un applyMode et requiresReload"):format(m.key))
    end
end
check("aucune contradiction de mode", contradiction, 0)

print()
print(("  Lot 1 : %d modules avec un chemin d'application, dont %d hors combat")
    :format(withMode, (function()
        local n = 0
        for _, m in ipairs(R.ListAll()) do
            if m.applyMode and m.combatSafe then n = n + 1 end
        end
        return n
    end)()))

-- ═══════════════════════════════════════════════════════════════════════
print("── 7. Migration de layout sur les données réelles ──")

assert(loadfile("Core/LayoutEngine.lua"))()
local Layout = _G.TomoMod_Layout

-- Chaque ancre déclarée doit porter un nom affichable : c'est ce texte
-- que le joueur lit sur la superposition pendant qu'il déplace le cadre.
local unlabelled = 0
for _, a in ipairs(R.Anchors()) do
    if not a.label then
        unlabelled = unlabelled + 1
        fail(("ancre '%s' (%s) n'a pas de libellé"):format(a.id, a.module))
    end
end
check("toutes les ancres nommées", unlabelled, 0)

-- La migration tourne sur une copie des vrais defaults : les 29 ancres
-- doivent toutes passer en v2, et AUCUNE ne doit ressortir avec une
-- taille de référence -- c'est ce qui garantit qu'une mise à jour ne
-- déplace rien à l'écran.
local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = DeepCopy(v) end
    return o
end

local db = DeepCopy(D)
local converted, seen = Layout.MigrateAll(db)
check("toutes les ancres vues",     seen,      #R.Anchors())
check("toutes les ancres migrées",  converted, #R.Anchors())

local stamped, notV2, leftover = 0, 0, 0
for _, a in ipairs(R.Anchors()) do
    local pos = R.GetPath(db, a.path)
    if type(pos) == "table" then
        if pos.v ~= Layout.SCHEMA_VERSION then
            notV2 = notV2 + 1
            fail(("'%s' n'est pas passée en v2"):format(a.id))
        end
        if pos.refW or pos.refH then
            stamped = stamped + 1
            fail(("'%s' porte une taille de référence après migration"):format(a.id))
        end
        if pos.relativePoint or pos.relPoint or pos.relTo then
            leftover = leftover + 1
            fail(("'%s' garde une ancienne clé"):format(a.id))
        end
    end
end
check("toutes en v2",                      notV2,    0)
check("aucune référence stampée",          stamped,  0)
check("aucune ancienne clé résiduelle",    leftover, 0)

-- Rejouer la migration ne doit rien changer : le runner la protège déjà
-- par un drapeau, mais l'idempotence doit tenir toute seule.
local again = Layout.MigrateAll(db)
check("seconde passe sans effet", again, 0)

-- Et le point d'entrée du repli générique doit exister dans les six
-- langues, puisque Core/Utils.lua s'en sert quand un appelant ne
-- fournit pas de nom.
needed["mover_generic"] = true
local genGaps = 0
for _, loc in ipairs(LOCALES) do
    if not defined[loc]["mover_generic"] then
        genGaps = genGaps + 1
        fail(("mover_generic absent de %s"):format(loc))
    end
end
check("repli générique traduit partout", genGaps, 0)

print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

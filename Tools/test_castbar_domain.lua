-- Banc hors-jeu pour le troisieme domaine AstralForge ("castbar") et
-- pour la table de sujets qui remplace la chaine de « if » du studio.
--
-- Ce qui compte ici :
--
--   1. Les defauts des descripteurs reproduisent EXACTEMENT les ancres
--      que Castbar.lua pose a la main. Sans ca, brancher le registre
--      deplacerait les textes de tout le monde au premier lancement.
--   2. Chaque sujet du studio designe un registre et un chemin de
--      reglages qui existent. Une entree fautive ne se voit qu'a
--      l'ouverture du menu deroulant, en jeu.
--   3. Aucun libelle n'est ecrit en dur : ils etaient en francais pour
--      tout le monde avant ce lot.
--
-- Usage : luajit Tools/test_castbar_domain.lua   (depuis la racine)

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-52s attendu=%-14s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end
local function fail(msg) ok = false; print("  ÉCHEC " .. msg) end

local function read(path)
    local fh = assert(io.open(path, "rb"), "introuvable : " .. path)
    local s = fh:read("*a"); fh:close()
    return (s:gsub("^\239\187\191", ""):gsub("\r\n", "\n"))
end

-- ── Stubs ────────────────────────────────────────────────────────────
_G.GetLocale   = function() return "enUS" end
_G.UIParent    = {}
_G.CreateFrame = function() return setmetatable({}, { __index = function() return function() end end }) end
_G.C_Timer     = { After = function() end, NewTicker = function() return { Cancel = function() end } end }
_G.GetPhysicalScreenSize = function() return 2560, 1440 end
_G.InCombatLockdown = function() return false end
_G.hooksecurefunc   = function() end
_G.issecretvalue    = function() return false end
_G.LibStub          = function() return nil end
_G.StaticPopupDialogs, _G.SlashCmdList = {}, {}

pcall(assert(loadfile("Core/Database.lua")))
assert(loadfile("Core/Forge/Forge.lua"))()
assert(loadfile("Core/Forge/ForgeSchema.lua"))()
assert(loadfile("Core/Forge/ForgeRegistry.lua"))()
assert(loadfile("Modules/Interface/Castbars/CBElements.lua"))()

local R   = _G.TomoMod_Forge.Registry
local CBE = _G.TomoMod_CBElements
assert(CBE, "CBElements ne s'est pas enregistre")

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. Le domaine existe et se decrit ──")

check("nom du domaine", CBE.DOMAIN, "castbar")

local hosts = R.ListHosts(CBE.DOMAIN)
local hostIDs = {}
for _, h in ipairs(hosts) do hostIDs[h.id] = true end
check("hote : bar",        hostIDs.bar,        true)
check("hote : icon",       hostIDs.icon,       true)
check("hote : iconBorder", hostIDs.iconBorder, true)

local els = CBE.List()
local elIDs = {}
for _, e in ipairs(els) do elIDs[e.id] = true end
check("element : spellText",  elIDs.spellText,  true)
check("element : timerText",  elIDs.timerText,  true)
check("element : targetText", elIDs.targetText, true)
check("trois elements",       #els,             3)

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Les defauts reproduisent les ancres codees en dur ──")

-- Extraits de Castbar.lua, relus depuis la source : si quelqu'un change
-- l'ancre dans le module sans toucher au descripteur, ce test tombe.
local src = read("Modules/Interface/Castbars/Castbar.lua")

local function DefaultOf(id)
    return R.Get(CBE.DOMAIN, id).default
end

local spell = DefaultOf("spellText")
check("spellText point",    spell.point,    "LEFT")
check("spellText relTo",    spell.relTo,    "bar")
check("spellText relPoint", spell.relPoint, "LEFT")
check("spellText x",        spell.x,        4)
check("spellText y",        spell.y,        0)
if not src:find('spellText:SetPoint("LEFT", 4, 0)', 1, true) then
    fail("Castbar.lua n'ancre plus spellText en LEFT/4/0 : descripteur a resynchroniser")
end

local timer = DefaultOf("timerText")
check("timerText point",    timer.point,    "RIGHT")
check("timerText relPoint", timer.relPoint, "RIGHT")
check("timerText x",        timer.x,        -4)
if not src:find('timerText:SetPoint("RIGHT", -4, 0)', 1, true) then
    fail("Castbar.lua n'ancre plus timerText en RIGHT/-4/0 : descripteur a resynchroniser")
end

local target = DefaultOf("targetText")
check("targetText point",    target.point,    "LEFT")
check("targetText relTo",    target.relTo,    "spellText")
check("targetText relPoint", target.relPoint, "RIGHT")
check("targetText x",        target.x,        4)
if not src:find('targetText:SetPoint("LEFT", spellText, "RIGHT", 4, 0)', 1, true) then
    fail("Castbar.lua n'ancre plus targetText sur spellText : descripteur a resynchroniser")
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 3. Cibles d'ancrage et cycles ──")

for _, id in ipairs({ "spellText", "timerText", "targetText" }) do
    local d = R.Get(CBE.DOMAIN, id)
    if not R.IsTarget(CBE.DOMAIN, d.default.relTo) then
        fail(("'%s' vise '%s', qui n'est pas une cible declaree"):format(id, d.default.relTo))
    end
end
check("toutes les cibles par defaut sont declarees", ok, true)

-- targetText pointe sur spellText par defaut : renvoyer spellText sur
-- targetText fermerait la boucle et produirait une erreur d'ancrage
-- cote client. Le registre doit le refuser.
local store = CBE.Ensure({})
check("Ensure remplit les trois", store.spellText ~= nil and store.timerText ~= nil
                                   and store.targetText ~= nil, true)
check("cycle detecte", R.WouldCycle(CBE.DOMAIN, store, "spellText", "targetText"), true)
check("sens normal accepte", R.WouldCycle(CBE.DOMAIN, store, "timerText", "bar"), false)

-- ═══════════════════════════════════════════════════════════════════════
print("── 4. Resolution des widgets ──")

-- Une fausse barre portant les memes noms de champs que Castbar.lua.
local bar = { spellText = {}, timerText = {}, targetText = {}, icon = {}, iconBorder = {} }
for _, id in ipairs({ "spellText", "timerText", "targetText" }) do
    local d = R.Get(CBE.DOMAIN, id)
    if d.resolve(bar) ~= bar[id] then
        fail(("resolve('%s') ne rend pas le bon widget"):format(id))
    end
end
check("les trois elements se resolvent", ok, true)

-- Une barre sans texte de cible (joueur/familier) ne doit pas planter.
local slim = { spellText = {} }
check("widget absent -> nil", R.Get(CBE.DOMAIN, "targetText").resolve(slim), nil)
check("frame nil -> nil",     R.Get(CBE.DOMAIN, "spellText").resolve(nil),   nil)

-- ═══════════════════════════════════════════════════════════════════════
print("── 5. Table de sujets du studio ──")

local af = read("TomoMod_AstralForge/AstralForge.lua")

-- Plus aucun libelle en dur : ils etaient tous en francais.
local hard = 0
for line in af:gmatch("[^\n]+") do
    if line:find("value%s*=%s*\"") and line:find("text%s*=%s*\"") then
        hard = hard + 1
    end
end
check("aucun libelle de sujet en dur", hard, 0)

-- Chaque sujet declare une cle de locale et un registre.
local subjects = {}
for value, labelKey in af:gmatch('value%s*=%s*"([%w_]+)",%s*labelKey%s*=%s*"([%w_]+)"') do
    subjects[#subjects + 1] = { value = value, labelKey = labelKey }
end
check("onze sujets declares", #subjects, 11)

local seen = {}
for _, sub in ipairs(subjects) do
    if seen[sub.value] then fail(("sujet en double : %s"):format(sub.value)) end
    seen[sub.value] = true
end
check("aucun sujet en double", ok, true)
check("les cinq castbars presentes",
      (seen.castbar_player and seen.castbar_target and seen.castbar_focus
       and seen.castbar_pet and seen.castbar_boss) and true or false, true)

-- Les cles de libelle doivent exister dans les six langues.
local locSrc = read("Locales/Locale_Modules.lua")
local LOCALES = { "enUS", "frFR", "deDE", "esES", "itIT", "ptBR" }
local defined = {}
for _, loc in ipairs(LOCALES) do
    defined[loc] = {}
    local b = locSrc:find('TomoMod_RegisterLocale%("' .. loc .. '"')
    local e = locSrc:find("\n}%)", b or 1) or #locSrc
    for key in locSrc:sub(b or 1, e):gmatch('%["([%w_]+)"%]%s*=') do
        defined[loc][key] = true
    end
end

local gaps = 0
local function Need(key)
    for _, loc in ipairs(LOCALES) do
        if not defined[loc][key] then
            gaps = gaps + 1
            fail(("cle '%s' absente de %s"):format(key, loc))
        end
    end
end
for _, sub in ipairs(subjects) do Need(sub.labelKey) end
for _, h in ipairs(hosts) do if h.labelKey then Need(h.labelKey) end end
for _, e in ipairs(els)   do if e.labelKey then Need(e.labelKey) end end
Need("cb_preview_spell")
Need("cb_preview_target")
check("aucune traduction manquante", gaps, 0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 6. Contrat commun aux domaines ──")

-- AstralForge tient un registre sans savoir lequel. Les trois doivent
-- donc exposer les memes noms.
local UFE_src = read("Modules/Interface/UnitFrames/UFElements.lua")
local NPE_src = read("Modules/Interface/NamePlates/NPElements.lua")
local CBE_src = read("Modules/Interface/Castbars/CBElements.lua")
for _, fn in ipairs({ "Ensure", "ApplyAll", "List" }) do
    for name, s in pairs({ UFElements = UFE_src, NPElements = NPE_src, CBElements = CBE_src }) do
        if not s:find("function %w+%." .. fn) then
            fail(("%s n'expose pas %s()"):format(name, fn))
        end
    end
end
check("les trois domaines exposent le meme contrat", ok, true)

-- Seul le domaine castbar fabrique son propre sujet de scene ; c'est ce
-- que RebuildSubject teste pour choisir sa branche.
check("CBElements fournit CreatePreview", type(CBE.CreatePreview), "function")
check("RebuildSubject teste CreatePreview",
      af:find("reg.CreatePreview", 1, true) ~= nil, true)

-- Le fichier doit etre charge, sinon rien de tout ceci n'existe en jeu.
local xml = read("Modules/Interface/Castbars/CastBars.xml")
check("CBElements.lua charge par le XML", xml:find("CBElements.lua", 1, true) ~= nil, true)
check("charge avant Castbar.lua",
      (xml:find("CBElements.lua", 1, true) or 0) < (xml:find('"Castbar.lua"', 1, true) or 0), true)

-- Et Castbar.lua doit vraiment l'appliquer, sinon le studio ecrit dans
-- un store que personne ne lit.
local cbsrc = read("Modules/Interface/Castbars/Castbar.lua")
check("Castbar.lua applique le domaine",
      cbsrc:find("TomoMod_CBElements.ApplyAll", 1, true) ~= nil, true)

print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

-- Table de routage de l'engrenage de layout : analyse statique.
--
-- Le routage se fait sur le nom de la frame survolee. C'est deterministe et
-- gratuit a l'execution, mais ca deplace le risque : un motif qui ne
-- correspond a aucune frame reelle ne se voit pas en jeu, il ne fait
-- simplement jamais apparaitre l'engrenage. Et une destination qui n'est pas
-- une vraie categorie ouvre le panneau sur du vide.
--
-- Les deux se verifient depuis les sources, donc les deux sont verifies ici.
-- C'est ce qui rend l'approche par nom tenable : la version precedente
-- decouvrait les frames a l'execution et ne pouvait rien garantir avant
-- d'etre lancee dans le client.
--
-- Usage : luajit Tools/test_layout_gear.lua   (depuis la racine)

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-52s attendu=%-10s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end
local function fail(m) ok = false; print("  ÉCHEC " .. m) end

local function read(path)
    local fh = io.open(path, "rb")
    if not fh then return nil end
    local s = fh:read("*a"); fh:close()
    return (s:gsub("^\239\187\191", ""):gsub("\r\n", "\n"))
end

local moversSrc = read("Modules/QOL/Movers/Movers.lua")
assert(moversSrc, "Movers.lua introuvable")

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. Plus aucune découverte de frames ──")

-- Le defaut corrige : un parcours complet du graphe de frames, deux fois par
-- entree de mover. Vingt-quatre entrees faisaient quarante-huit parcours a
-- chaque ouverture du layout.
check("EnumerateFrames absent",    moversSrc:find("EnumerateFrames", 1, true), nil)
check("SnapshotFrames absent",     moversSrc:find("SnapshotFrames", 1, true), nil)
check("CaptureLayoutTargets absent", moversSrc:find("CaptureLayoutTargets", 1, true), nil)
-- Le routage par libelle traduit cassait en silence des qu'une traduction
-- changeait, et seulement pour la langue concernee.
check("routage par libellé absent", moversSrc:find("configRouteByLabel", 1, true), nil)

-- La boucle d'entrees doit etre revenue a sa forme simple.
check("boucle d'entrées restaurée",
      moversSrc:find("if unlock then entry.unlock() else entry.lock() end", 1, true) ~= nil, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Extraction de la table ──")

local block = moversSrc:match("local LAYOUT_ROUTES = %{(.-)\n%}")
assert(block, "LAYOUT_ROUTES introuvable")

local routes = {}
for pattern, dest in block:gmatch('%{%s*"([^"]+)",%s*"([%w_]+)"%s*%}') do
    routes[#routes + 1] = { pattern = pattern, category = dest }
end
for pattern, cat, page in block:gmatch('%{%s*"([^"]+)",%s*%{%s*category%s*=%s*"([%w_]+)",%s*page%s*=%s*"([%w_]+)"%s*%}%s*%}') do
    routes[#routes + 1] = { pattern = pattern, category = cat, page = page }
end

check("des routes sont déclarées", #routes > 20, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 3. Chaque motif correspond à une frame réelle ──")

-- Tous les noms de frames crees dans le depot.
local names = {}
local function Collect(dir)
    local pipe = io.popen('find "' .. dir .. '" -name "*.lua" 2>/dev/null')
    if not pipe then return end
    for path in pipe:lines() do
        if not path:find("/Libs/") then
            local src = read(path)
            if src then
                for n in src:gmatch('CreateFrame%([^,]+,%s*"(TomoMod[%w_]*)') do
                    names[#names + 1] = n
                end
                -- oUF nomme ses cadres a la volee : ouf:Spawn(unit, "TomoMod_UF_" .. unit)
                for n in src:gmatch('Spawn%([^,]+,%s*"(TomoMod[%w_]*)') do
                    names[#names + 1] = n
                end
            end
        end
    end
    pipe:close()
end
Collect("Modules")
Collect("Core")
check("des frames nommées ont été trouvées", #names > 30, true)

local unmatched = 0
for _, r in ipairs(routes) do
    -- Le motif est ancre (^Nom) ; on le compare aux prefixes reellement crees.
    local prefix = r.pattern:gsub("^%^", "")
    local found = false
    for _, n in ipairs(names) do
        if n:sub(1, #prefix) == prefix or prefix:sub(1, #n) == n then
            found = true
            break
        end
    end
    if not found then
        unmatched = unmatched + 1
        fail(("le motif '%s' ne correspond à aucune frame créée"):format(r.pattern))
    end
end
check("tous les motifs ont une frame", unmatched, 0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 4. Chaque destination existe dans le GUI ──")

local cfgSrc = read("TomoMod_Options/Config/ConfigUI.lua")
assert(cfgSrc, "ConfigUI.lua introuvable")

local badCat, badPage = 0, 0
for _, r in ipairs(routes) do
    if not cfgSrc:find('"' .. r.category .. '"', 1, true) then
        badCat = badCat + 1
        fail(("la catégorie '%s' n'existe pas dans ConfigUI"):format(r.category))
    end
    if r.page and r.category == "comfort" then
        -- Les pages du confort passent par OpenComfortPage, qui les nomme.
        if not cfgSrc:find('"' .. r.page .. '"', 1, true) then
            badPage = badPage + 1
            fail(("la page confort '%s' n'existe pas"):format(r.page))
        end
    end
end
check("catégories valides", badCat,  0)
check("pages confort valides", badPage, 0)

-- Les points d'entree utilises par OpenConfigRoute doivent exister.
local missingEntry = 0
for _, fn in ipairs({ "OpenComfortPage", "OpenCategory", "Show", "SwitchCategory" }) do
    if not cfgSrc:find("function C%." .. fn) then
        missingEntry = missingEntry + 1
        fail(("TomoMod_Config.%s() est appelé mais n'existe pas"):format(fn))
    end
end
check("points d'entrée du GUI présents", missingEntry, 0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 5. Ordre et unicité ──")

-- Le premier motif qui correspond gagne : un motif plus court place avant un
-- plus long masquerait ce dernier. "TomoMod_Castbar_" avant
-- "TomoMod_Castbar_GCD" enverrait le GCD sur la mauvaise page.
local shadowed = 0
for i = 1, #routes do
    for j = i + 1, #routes do
        local a = routes[i].pattern:gsub("^%^", "")
        local b = routes[j].pattern:gsub("^%^", "")
        if b:sub(1, #a) == a and #b > #a then
            shadowed = shadowed + 1
            fail(("'%s' (rang %d) masque '%s' (rang %d)"):format(a, i, b, j))
        end
    end
end
check("aucun motif n'en masque un autre", shadowed, 0)

local seen, dup = {}, 0
for _, r in ipairs(routes) do
    if seen[r.pattern] then dup = dup + 1; fail("motif en double : " .. r.pattern) end
    seen[r.pattern] = true
end
check("aucun motif en double", dup, 0)

-- La frame de l'engrenage et le chrome du layout ne doivent jamais etre des
-- cibles, sinon survoler l'engrenage le ferait sauter d'un element a l'autre.
check("le chrome du layout est exclu",
      moversSrc:find("GEAR_SELF", 1, true) ~= nil, true)
local missingSelf = 0
for _, self_ in ipairs({ "TomoModLayoutConfigGear", "TomoModLayoutHeader", "TomoModLayoutGrid" }) do
    if not moversSrc:find(self_ .. "%s*=%s*true") then
        missingSelf = missingSelf + 1
        fail(("'%s' n'est pas dans la liste d'exclusion"):format(self_))
    end
end
check("les trois frames de chrome sont exclues", missingSelf, 0)

print()
print(("  %d routes, %d frames nommées dans le dépôt"):format(#routes, #names))
print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

-- Barres de défilement du GUI face aux valeurs secrètes.
--
-- Rapport 4.1.2 (2026-11-09, moine frFR) : Widgets.lua:879 « attempt to
-- compare local 'maxS' (a secret number value, while execution tainted by
-- 'TomoMod_Options') ». Un ScrollFrame dont le contenu affiche une valeur
-- secrète (aperçu en direct) rend GetVerticalScrollRange() secret, et toute
-- comparaison depuis le code de l'addon lève une erreur.
--
--   1. W.ScrollRange / W.ScrollPos ne rendent jamais de secret : repli sur
--      la dernière valeur lisible, puis sur la hauteur du contenu, puis 0.
--   2. Plus aucun appel direct à GetVerticalScrollRange / GetVerticalScroll
--      dans TomoMod_Options en dehors de ces deux helpers.
--
-- Usage : lua5.1 Tools/run_test.lua Tools/test_scroll_secret_safe.lua

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-58s attendu=%-8s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

local function read(path)
    local fh = assert(io.open(path, "rb"))
    local s = fh:read("*a"); fh:close()
    return (s:gsub("^\239\187\191", ""):gsub("\r\n", "\n"))
end

-- ---------------------------------------------------------------------
print("── 1. Helpers face à une valeur secrète ──")

local src = read("TomoMod_Options/Config/Widgets.lua")
local s = src:find("local function PlainNumber", 1, true)
local e = src:find("\n%-%- =+\n%-%- THEME", s)
assert(s and e, "bloc SECRET-SAFE SCROLL METRICS introuvable")
local block = src:sub(s, e)

-- Une valeur secrète simulée : un nombre marqué, comparable seulement
-- par issecretvalue. Toute comparaison directe dans le helper serait une
-- erreur en jeu ; ici on vérifie qu'il ne la renvoie jamais.
local SECRETS = setmetatable({}, { __mode = "k" })
local function Secret() local t = {}; SECRETS[t] = true; return t end

local env = setmetatable({
    W = {},
    issecretvalue = function(v) return SECRETS[v] == true end,
}, { __index = _G })
-- type() d'un secret simulé doit dire "number", comme en jeu.
env.type = function(v) if SECRETS[v] then return "number" end return type(v) end
local chunk = assert(loadstring(block, "@ScrollHelpers"))
setfenv(chunk, env)
chunk()
local W = env.W

local function SF(range, pos, h, childH)
    local child = { GetHeight = function() return childH end }
    return {
        GetVerticalScrollRange = function() return range end,
        GetVerticalScroll = function() return pos end,
        GetHeight = function() return h end,
        GetScrollChild = function() return child end,
    }
end

check("range lisible rendue telle quelle", W.ScrollRange(SF(120, 0, 400, 1)), 120)
check("position lisible rendue telle quelle", W.ScrollPos(SF(120, 35, 400, 1)), 35)

local sf = SF(200, 0, 400, 1)
check("range lisible mémorisée", W.ScrollRange(sf), 200)
sf.GetVerticalScrollRange = function() return Secret() end
check("range secrète : dernière valeur lisible", W.ScrollRange(sf), 200)

check("range secrète sans historique : hauteur du contenu",
      W.ScrollRange(SF(Secret(), 0, 400, 1000)), 600)
check("contenu plus petit que la vue : 0",
      W.ScrollRange(SF(Secret(), 0, 400, 100)), 0)
check("tout secret : 0", W.ScrollRange(SF(Secret(), 0, 400, Secret())), 0)
check("position secrète : 0", W.ScrollPos(SF(10, Secret(), 400, 1)), 0)
check("position nil : 0", W.ScrollPos(SF(10, nil, 400, 1)), 0)
check("frame absente : 0", W.ScrollRange(nil), 0)

-- ---------------------------------------------------------------------
print("── 2. Plus d'appel direct dans TomoMod_Options ──")

local files = {}
local pipe = io.popen('find "TomoMod_Options" -name "*.lua" 2>/dev/null')
if pipe then
    for line in pipe:lines() do files[#files + 1] = line end
    pipe:close()
end
check("des fichiers ont été trouvés", #files > 10, true)

local raw = 0
for _, path in ipairs(files) do
    local text = read(path)
    local n = 0
    for line in text:gmatch("[^\n]+") do
        n = n + 1
        if (line:find("GetVerticalScrollRange()", 1, true) or line:find("GetVerticalScroll()", 1, true))
            and not line:find("PlainNumber(sf:", 1, true) then
            raw = raw + 1
            print(("  ÉCHEC appel direct %s:%d"):format(path, n))
            ok = false
        end
    end
end
check("aucun appel direct hors helpers", raw, 0)

print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

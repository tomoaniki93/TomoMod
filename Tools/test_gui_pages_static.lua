-- Navigation du GUI v2 (Config/ConfigUI.lua + Config/Kit.lua) : analyse
-- statique.
--
-- La fenêtre résout chaque clé par une table (pages, alias). Une clé qui ne
-- mène nulle part ne lève rien en jeu : le joueur atterrit sur l'Accueil sans
-- savoir pourquoi. Toutes les clés écrites dans le dépôt sont donc vérifiées
-- ici contre les pages réellement enregistrées.
--
-- Usage : lua5.1 Tools/run_test.lua Tools/test_gui_pages_static.lua

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-56s attendu=%-8s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end
local function fail(m) ok = false; print("  ÉCHEC " .. m) end

local function read(path)
    local fh = io.open(path, "rb")
    if not fh then return nil end
    local s = fh:read("*a"); fh:close()
    return (s:gsub("^\239\187\191", ""):gsub("\r\n", "\n"))
end

local CFG = "TomoMod_Options/Config/"
local cfg    = assert(read(CFG .. "ConfigUI.lua"), "ConfigUI.lua introuvable")
local frames = assert(read(CFG .. "Panels/Frames.lua"))
local groups = assert(read(CFG .. "Panels/Groups.lua"))
local plates = assert(read(CFG .. "Panels/Plates.lua"))
local roles  = assert(read(CFG .. "Panels/Roles.lua"))
local qol    = assert(read(CFG .. "Panels/QOL.lua"))
local layout = assert(read("Core/LayoutV41.lua"))
local movers = assert(read("Modules/QOL/Movers/Movers.lua"))
local toc    = assert(read("TomoMod_Options/TomoMod_Options.toc"))

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. Pages enregistrées ──")

local pages = {}
local function add(k, src) if k then pages[k] = src end end

-- LEGACY du shell
local legacy = cfg:match("local LEGACY = %{(.-)\n%}")
assert(legacy, "LEGACY introuvable")
for k in legacy:gmatch('%{ key = "([%w_]+)"') do add(k, "legacy") end
-- Pages Kit
for _, src in ipairs({ frames, groups, plates }) do
    for k in src:gmatch('K%.RegisterPage%(%{%s*key = "([%w_]+)"') do add(k, "kit") end
end
-- Pages par unité : key = "uf_" .. u.key
local units = frames:match("local UNITS = %{(.-)\n%}") or ""
for u in units:gmatch('%{ key = "([%w_]+)"') do add("uf_" .. u, "kit") end

local n = 0
for _ in pairs(pages) do n = n + 1 end
check("des pages sont enregistrées", n > 40, true)
for _, k in ipairs({ "home", "uf_player", "uf_boss", "castbar", "resources", "party", "raid",
                     "healer", "nameplates", "actionbars", "studio_cooldown", "studio_mythic",
                     "role_tank", "housing", "consumables", "profiles" }) do
    check("page " .. k, pages[k] ~= nil, true)
end
check("plus de Studio Astral / Groupe / Ressources dans la barre latérale",
      legacy:find('launch = function%(%) return C%.LaunchStudio%("astral"') == nil
      and legacy:find('LaunchStudio%("group"') == nil
      and legacy:find('LaunchStudio%("resourcecast"') == nil, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Alias ──")

local aliases = cfg:match("local ALIASES = %{(.-)\n%}")
assert(aliases, "ALIASES introuvable")
local bad = 0
for from, to in aliases:gmatch('%["([%w_]+)"%] = "([%w_]+)"') do
    if not pages[to] then bad = bad + 1; fail(("alias '%s' -> '%s' : page absente"):format(from, to)) end
end
check("chaque alias mène à une page", bad, 0)

local function resolves(k)
    return pages[k] ~= nil or aliases:find('["' .. k .. '"]', 1, true) ~= nil
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 3. Clés écrites ailleurs dans le dépôt ──")

bad = 0
for k in layout:match("local PAGE_BY_ANCHOR = %{(.-)\n%}"):gmatch('= "([%w_]+)"') do
    if not pages[k] then bad = bad + 1; fail("engrenage -> page absente : " .. k) end
end
check("engrenage du layout", bad, 0)

bad = 0
local routes = movers:match("local LAYOUT_ROUTES = %{(.-)\n%}")
for dest in routes:gmatch('%{%s*"[^"]+",%s*"([%w_]+)"%s*%}') do
    if not resolves(dest) then bad = bad + 1; fail("route Movers -> " .. dest) end
end
for page in routes:gmatch('page%s*=%s*"([%w_]+)"') do
    if not resolves(page) then bad = bad + 1; fail("page confort Movers -> " .. page) end
end
check("routes des Movers", bad, 0)

bad = 0
for k in roles:gmatch('page = "([%w_]+)"') do
    if not pages[k] then bad = bad + 1; fail("guide Rôles -> " .. k) end
end
check("liens des guides Rôles", bad, 0)

for _, tbl in ipairs({ "STUDIO_TO_PAGE", "ARG_TO_PAGE" }) do
    bad = 0
    local body = cfg:match("local " .. tbl .. " = %{(.-)\n%}") or ""
    for k in body:gmatch('= "([%w_]+)"') do
        if not pages[k] then bad = bad + 1; fail(tbl .. " -> " .. k) end
    end
    check(tbl, bad, 0)
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 4. Constructeurs ──")

-- Chaque panneau historique appelé par nom doit exister dans un fichier
-- chargé par le .toc.
local loaded = {}
for line in toc:gmatch("[^\n]+") do
    if not line:find("^#") and line:find("%.lua$") then
        loaded[#loaded + 1] = read("TomoMod_Options/" .. line:gsub("\\", "/")) or ""
    end
end
local all = table.concat(loaded, "\n")
bad = 0
for g in legacy:gmatch('LegacyPanel%("([%w_]+)"%)') do
    if not all:find("function " .. g .. "%(") then bad = bad + 1; fail("panneau introuvable : " .. g) end
end
check("panneaux historiques présents", bad, 0)

-- Chaque page QOL doit être un onglet du panneau QOL.
local tabs = qol:match("local tabs = %{(.-)\n    %}") or ""
bad = 0
for k in legacy:gmatch('QOLPage%("([%w_]+)"%)') do
    if not tabs:find('key = "' .. k .. '"', 1, true) then bad = bad + 1; fail("onglet QOL absent : " .. k) end
end
check("pages Confort = onglets QOL", bad, 0)

-- Ordre de chargement : Kit avant les pages, les pages avant le shell
-- (CollectPages lit K.PAGES au chargement du fichier).
local function pos(f) return toc:find(f, 1, true) or math.huge end
check("Kit avant les pages", pos("Config\\Kit.lua") < pos("Config\\Panels\\Frames.lua"), true)
check("pages avant ConfigUI",
      pos("Config\\Panels\\Plates.lua") < pos("Config\\ConfigUI.lua")
      and pos("Config\\Panels\\Groups.lua") < pos("Config\\ConfigUI.lua"), true)
check("GlobalSearch retiré", toc:find("GlobalSearch", 1, true), nil)

print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

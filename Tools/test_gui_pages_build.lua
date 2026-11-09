-- Construction des pages du GUI v2 contre la vraie base par défaut.
--
-- Les pages Kit (Frames, Groups, Plates) viennent de TomoModForever : elles
-- lisent TomoModDB par chemins. Une page qui touche un champ absent ou d'une
-- autre forme lève une erreur que K.Page attrape et affiche en rouge dans la
-- fenêtre : rien ne casse en jeu, mais la page est vide. Ce test construit
-- chaque page, en mode simple puis expert, avec des widgets factices et la
-- base par défaut de Core/Database.lua, et exige zéro erreur.
--
-- Il vérifie aussi que les réglages qui n'existent pas dans TomoMod (hérités
-- de Forever) sont sautés au lieu d'écrire des clés mortes.
--
-- Usage : lua5.1 Tools/run_test.lua Tools/test_gui_pages_build.lua

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-56s attendu=%-8s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

local function loadSrc(path)
    local fh = assert(io.open(path, "rb"))
    local s = fh:read("*a"); fh:close()
    s = s:gsub("^\239\187\191", "")
    return assert(loadstring(s, "@" .. path))
end

-- ── Frames factices ───────────────────────────────────────────────────
local FrameMT = {}
FrameMT.__index = function(t, k)
    local v = rawget(FrameMT, k)
    if v then return v end
    return function() return nil end
end
function FrameMT.CreateTexture(self) return setmetatable({}, FrameMT) end
function FrameMT.CreateFontString(self) return setmetatable({}, FrameMT) end
function FrameMT.GetWidth() return 400 end
function FrameMT.GetHeight() return 30 end
function FrameMT.GetStringHeight() return 13 end
function FrameMT.GetChildren() return end
function FrameMT.IsVisible() return false end
function FrameMT.IsShown() return false end
function FrameMT.GetFrameLevel() return 1 end
local function NewFrame() return setmetatable({}, FrameMT) end
CreateFrame = function() return NewFrame() end
UIParent = NewFrame()
C_Timer = { After = function() end, NewTicker = function() return { Cancel = function() end } end }
GetLocale = function() return "frFR" end
InCombatLockdown = function() return false end
IsInRaid = function() return false end
local caught = {}
geterrorhandler = function() return function(e) caught[#caught + 1] = tostring(e) end end
StaticPopupDialogs = {}
StaticPopup_Show = function() end
GameTooltip = NewFrame()
UnitClass = function() return "Guerrier", "WARRIOR" end
GetSpecialization = function() return 1 end
GetSpecializationInfo = function() return 71 end
C_NamePlate = {}
RAID_CLASS_COLORS = setmetatable({}, { __index = function() return { r = 1, g = 1, b = 1 } end })

TomoMod_Utils = { BRAND = { 0.18, 0.62, 0.85 } }
TomoMod_L = setmetatable({}, { __index = function(_, k) return k end })

-- ── Widgets factices : enregistrent ce qui est construit ───────────────
local built = { controls = 0 }
local W = {
    Theme = setmetatable({}, { __index = function() return { 0.5, 0.5, 0.5, 1 } end }),
}
local function mk(yIndex)
    return function(...)
        built.controls = built.controls + 1
        local y = select(yIndex, ...) or 0
        return NewFrame(), y - 20
    end
end
W.CreateScrollPanel = function() local s = NewFrame(); s.child = NewFrame(); return s end
W.CreateCard = function(parent, title, y) local c = NewFrame(); c.inner = NewFrame(); return c, -10 end
W.FinalizeCard = function(card, y) return (y or 0) - 30 end
W.CreateInfoText = mk(3)
W.CreateSubLabel = mk(3)
W.CreateCheckbox = mk(4)
W.CreateSlider = mk(7)
W.CreateDropdown = mk(5)
W.CreateSegmentedControl = mk(5)
W.CreateColorPicker = mk(4)
W.CreateButton = mk(4)
W.CreateDangerButton = mk(4)
W.CreateSeparator = mk(2)
W.CreateSectionHeader = mk(3)
W.SetTooltip = function() end
W.CreateTwoColumnRow = function(parent, y, l, r)
    local a = l(NewFrame()) or 0
    local b = r(NewFrame()) or 0
    return NewFrame(), y - math.max(math.abs(a), math.abs(b)) - 4
end
setmetatable(W, { __index = function(_, k) return function() return NewFrame(), 0 end end })
TomoMod_Widgets = W

-- ── Base par défaut réelle ─────────────────────────────────────────────
do
    local env = setmetatable({}, { __index = function(t, k)
        local v = _G[k]; if v ~= nil then return v end
        return setmetatable({}, { __index = function() return function() end end, __call = function() end })
    end })
    env._G = env
    local f = loadSrc("Core/Database.lua")
    setfenv(f, env)
    pcall(f)
    TomoMod_Defaults = rawget(env, "TomoMod_Defaults")
end
assert(type(TomoMod_Defaults) == "table", "TomoMod_Defaults introuvable")
local function deepcopy(t, seen)
    if type(t) ~= "table" then return t end
    seen = seen or {}
    if seen[t] then return seen[t] end
    local c = {}; seen[t] = c
    for k, v in pairs(t) do c[deepcopy(k, seen)] = deepcopy(v, seen) end
    return c
end
TomoModDB = deepcopy(TomoMod_Defaults)
TomoModDB.unitFrames.enabled = true

-- Registre de modules minimal pour K.IsModuleOn.
TomoMod_Registry = { IsEnabled = function() return true end }

-- ── Chargement Kit + pages ─────────────────────────────────────────────
loadSrc("TomoMod_Options/Config/Kit.lua")()
local K = TomoMod_Kit
for _, f in ipairs({ "Frames", "Groups", "Plates" }) do
    loadSrc("TomoMod_Options/Config/Panels/" .. f .. ".lua")()
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. Chaque page se construit, en mode simple puis expert ──")

local errors = {}
local function buildAll(expert)
    K.GuiDB().expert = expert
    for _, def in ipairs(K.PAGES) do
        local okBuild, err = pcall(def.build, NewFrame())
        if not okBuild then errors[#errors + 1] = def.key .. " : " .. tostring(err) end
        for _, e in ipairs(caught) do errors[#errors + 1] = def.key .. " : " .. e end
        for i = #caught, 1, -1 do caught[i] = nil end
    end
end
local before = deepcopy(TomoModDB)
buildAll(false)
buildAll(true)
for _, e in ipairs(errors) do print("    " .. e) end
print("    pages=" .. #K.PAGES .. " controls=" .. built.controls)
check("pages construites", #K.PAGES >= 13, true)
check("aucune erreur de construction", #errors, 0)
check("des contrôles ont été créés", built.controls > 150, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Réglages hérités de Forever sautés ──")

for _, path in ipairs({ "unitFrames.lowHealthPulse", "unitFrames.healthTrail",
                        "castbars.interruptShake", "nameplates.targetArrows" }) do
    check("absent : " .. path, K.Absent(path), true)
end
check("présent : unitFrames.player.width", K.Absent("unitFrames.player.width"), false)
-- Clés numériques écrites en chaîne dans Core/Database.lua ("10", "25", "40").
check("présent : raidSizeOverrides.10.width", K.Absent("raidFrames.raidSizeOverrides.10.width"), false)
check("lecture d'une clé chaîne numérique", K.Get("raidFrames.raidSizeOverrides.40.height"),
      TomoMod_Defaults.raidFrames.raidSizeOverrides["40"].height)

-- La construction ne doit rien écrire dans la base.
local function same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for k, v in pairs(a) do if not same(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
local dbNoGui = deepcopy(TomoModDB); dbNoGui.configGUI = nil
local beforeNoGui = deepcopy(before); beforeNoGui.configGUI = nil
check("la construction ne modifie pas la base", same(dbNoGui, beforeNoGui), true)

print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

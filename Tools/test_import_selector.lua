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
        if k == "SetFrameLevel"  then return function(s, v) s._level = v end end
        if k == "GetFrameLevel"  then return function(s) return s._level end end
        if k == "SetFrameStrata" then return function(s, v) s._strata = v end end
        if k == "GetFrameStrata" then return function(s) return s._strata end end
        if k == "GetChecked" then return function(s) return s._checked end end
        if k == "SetChecked" then return function(s, v) s._checked = v end end
        if k == "SetText"    then return function(s, v) s._text = v end end
        if k == "GetText"    then return function(s) return s._text end end
        if k == "IsMouseOver" then return function() return false end end
        return function() end
    end }
    return setmetatable(f, mt)
end

local allFrames = {}
_G.CreateFrame = function(_, name)
    framesCreated = framesCreated + 1
    local f = MakeFrame()
    f._name = name
    if name then _G[name] = f end
    allFrames[#allFrames + 1] = f
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

-- Le selecteur lit desormais son habillage dans TomoMod_Widgets. On fournit
-- un theme complet pour que le banc exerce ce chemin-la et non le repli.
local scrollPanels = 0
_G.TomoMod_Widgets = {
    Theme = {
        accent  = { 0.60, 0.30, 0.90, 1 },   -- volontairement PAS l'azur :
        bg      = { 0.07, 0.07, 0.09, 0.97 },-- une couleur ecrite en dur se
        bgLight = { 0.11, 0.11, 0.14, 1 },   -- verrait immediatement.
        bgMid   = { 0.09, 0.09, 0.115, 1 },
        border  = { 0.18, 0.18, 0.22, 1 },
        text    = { 0.88, 0.90, 0.89, 1 },
        textDim = { 0.48, 0.48, 0.54, 1 },
        yellow  = { 0.96, 0.80, 0.10, 1 },
        red     = { 0.88, 0.22, 0.22, 1 },
    },
    CreateScrollPanel = function(parent)
        scrollPanels = scrollPanels + 1
        local f = MakeFrame()
        f._parent = parent
        f.child = MakeFrame()
        return f
    end,
}
-- Compte les remontees de couche et retient le niveau vu au moment de
-- l'appel : le selecteur doit passer au-dessus de la fenetre de config
-- telle qu'elle est a l'ouverture, pas telle qu'elle etait a la creation.
local raises = { n = 0, seenLevel = nil }
_G.TomoMod_Utils = {
    CloseOnEscape = function() end,
    RaiseAboveTomoUI = function(frame)
        raises.n = raises.n + 1
        raises.frame = frame
        local cfg = _G.TomoModConfigFrame
        raises.seenLevel = cfg and cfg:GetFrameLevel() or 0
        if frame and frame.SetFrameLevel then
            frame:SetFrameLevel(raises.seenLevel + 40)
        end
    end,
}
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
say("── 3b. Couche d'affichage ──")

-- Le selecteur s'ouvre au-dessus de la fenetre de config. Sans cette
-- remontee il declare la meme strate qu'elle et se retrouve derriere.
local before3b = raises.n
_G.TomoModConfigFrame = MakeFrame()
_G.TomoModConfigFrame:Show()
_G.TomoModConfigFrame.GetFrameLevel = function() return 100 end
IS.Show(payload)
check("remontee demandee a l'ouverture", raises.n, before3b + 1)
check("niveau lu = fenetre de config", raises.seenLevel, 100)

-- Le panneau est construit une fois et reutilise : la remontee doit etre
-- refaite a CHAQUE ouverture, sinon un deuxieme import rouvre sur le
-- niveau perime de la premiere fois.
_G.TomoModConfigFrame.GetFrameLevel = function() return 250 end
IS.Show(payload)
check("remontee rejouee a la reouverture", raises.n, before3b + 2)
check("niveau relu, pas memorise", raises.seenLevel, 250)

-- Une charge refusee ne doit pas remonter quoi que ce soit : rien ne
-- s'affiche, il n'y a rien a mettre devant.
local before3c = raises.n
IS.Show({})
check("charge refusee ne remonte rien", raises.n, before3c)

-- La remontee porte sur le dimmer ; la fenetre est son enfant et ne suit
-- pas son parent de maniere fiable une fois creee. Elle doit donc etre
-- re-calee explicitement au-dessus de lui, sinon elle reste au niveau
-- qu'elle avait a la construction et repasse derriere la config.
local sel = _G.TomoModImportSelector
_G.TomoModConfigFrame.GetFrameLevel = function() return 400 end
IS.Show(payload)
check("dimmer remonte au-dessus de la config",
      raises.frame and raises.frame:GetFrameLevel(), 440)
check("fenetre re-calee sur le dimmer",        sel:GetFrameLevel(),          450)
check("fenetre en strate plein ecran",         sel:GetFrameStrata(),         "FULLSCREEN_DIALOG")

-- ═══════════════════════════════════════════════════════════════════════
say("── 4. Refus propres ──")

check("charge vide refusée",        IS.Show({}),  false)
check("charge non-table refusée",   IS.Show(nil), false)

-- Aucun module reconnu : le panneau ne s'ouvre pas, l'appelant retombe
-- sur l'ancienne confirmation d'écrasement.
check("charge sans module connu", IS.Show({ inconnu = { x = 1 } }), false)

-- ═══════════════════════════════════════════════════════════════════════
say("── 5. Habillage ──")

check("le panneau prend le scroll de la suite", scrollPanels > 0, true)

-- La case a cocher est desormais maison. Le gabarit Blizzard fournissait
-- SetChecked/GetChecked ; la remplacer sans les rendre fideles ferait un
-- panneau ou decocher ne decoche rien, et l'import ramenerait tout.
local checks = {}
for _, f in ipairs(allFrames) do
    if rawget(f, "SetChecked") and rawget(f, "GetChecked") then
        checks[#checks + 1] = f
    end
end
check("des cases maison ont ete creees", #checks > 0, true)

local box = checks[1]
if box then
    box:SetChecked(true)
    check("coche puis relu vrai",  box:GetChecked(), true)
    box:SetChecked(false)
    check("decoche puis relu faux", box:GetChecked(), false)
    box:SetChecked(nil)
    check("nil vaut decoche",       box:GetChecked(), false)
end

-- Garde statique. Le rendu ne se verifie pas ici, mais la provenance de
-- l'habillage si : le selecteur etait le seul morceau du GUI v4 a poser des
-- gabarits et des polices Blizzard, et a reecrire l'accent a la main.
local fh = assert(io.open("TomoMod_Options/Config/ImportSelector.lua", "rb"))
local src = fh:read("*a"); fh:close()

for _, tmpl in ipairs({ "UIPanelButtonTemplate", "UICheckButtonTemplate" }) do
    check("plus de " .. tmpl, src:find(tmpl, 1, true) ~= nil, false)
end
check("plus de police GameFont", src:find("GameFont", 1, true) ~= nil, false)

-- L'azur de marque ne doit plus apparaitre en dur : il arrive par le theme.
check("accent non ecrit en dur",
      src:find("0%.18%s*,%s*0%.62%s*,%s*0%.85") ~= nil, false)

-- Et les codes couleur en ligne doivent etre construits, pas tapes.
for _, lit in ipairs({ "|cff888888", "|cffff8800", "|cff555555", "|cff2e9dd8" }) do
    check("plus de code couleur " .. lit, src:find(lit, 1, true) ~= nil, false)
end

say(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

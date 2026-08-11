-- Banc hors-jeu pour la migration ufElementsV1 + TomoMod_NormalizeUFElements.
-- Charge le VRAI Core/Database.lua derrière des bouchons d'API, puis fait
-- passer trois profils typiques : ancien profil avec offsets personnalisés,
-- profil neuf, et profil déjà migré (idempotence).

_G.TomoMod_Forge = { BRAND = { 0, 0, 0 } }
_G.TomoMod_L = setmetatable({}, { __index = function(_, k) return k end })
_G.TomoMod_RegisterLocale = function() end

-- API WoW minimale utilisée au chargement / dans les fonctions testées.
_G.CopyTable = function(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = (type(v) == "table") and CopyTable(v) or v end
    return o
end
_G.GetPhysicalScreenSize = function() return 1920, 1080 end
_G.UnitClass = function() return "Warrior", "WARRIOR" end
_G.RAID_CLASS_COLORS = {}
_G.date = os.date
_G.geterrorhandler = function() return function() end end

-- Certains fichiers du dépôt portent un BOM UTF-8 (Core/Database.lua entre
-- autres) : loadfile s'y casse les dents alors que le client WoW l'accepte.
-- On lit donc le fichier et on retire le BOM avant loadstring.
local function loadNoBOM(path)
    local fh = assert(io.open(path, "rb"))
    local src = fh:read("*a")
    fh:close()
    src = src:gsub("^\239\187\191", "")
    return assert(loadstring(src, "@" .. path))
end

loadNoBOM("Core/Utils.lua")()
loadNoBOM("Core/Forge/ForgeRegistry.lua")()
loadNoBOM("Modules/Interface/UnitFrames/UFElements.lua")()
loadNoBOM("Core/Database.lua")()

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-54s attendu=%-12s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

local function freshDB()
    _G.TomoModDB = { unitFrames = { player = {}, target = {}, targettarget = {}, pet = {}, focus = {} } }
    return _G.TomoModDB
end

-- ═══════════════════════════════════════════════════════════════════════
print("── Profil ancien : offsets personnalisés ──")
local db = freshDB()
db.unitFrames.player = {
    elementOffsets = {
        name       = { x = 14, y = -3 },
        level      = { x = -9, y = 0 },
        healthText = { x = 0, y = 5 },
        power      = { x = 2, y = -1 },
        auras      = { x = 40, y = 40 },   -- clé morte depuis 3.0.5
    },
    raidIconOffset   = { x = 7, y = 11 },
    leaderIconOffset = { x = -5, y = 2 },
    threatText       = { enabled = true, fontSize = 13, offsetX = 3, offsetY = -8 },
    auras            = { position = { point = "BOTTOMRIGHT", x = 0, y = 6 } },
}
TomoMod_InitDatabase()

local pl = TomoModDB.unitFrames.player
check("name.x reporté", pl.elements.name.x, 14)
check("name.y reporté", pl.elements.name.y, -3)
check("name garde l'ancrage historique LEFT/LEFT", pl.elements.name.relPoint, "LEFT")
check("level.x reporté", pl.elements.level.x, -9)
check("healthText.y reporté", pl.elements.healthText.y, 5)
check("power garde TOP/BOTTOM", pl.elements.power.relPoint, "BOTTOM")
check("power.x reporté", pl.elements.power.x, 2)
check("raidIcon.x reporté", pl.elements.raidIcon.x, 7)
check("raidIcon garde BOTTOM/TOP", pl.elements.raidIcon.relPoint, "TOP")
check("leaderIcon.x reporté", pl.elements.leaderIcon.x, -5)
check("threatText.x reporté depuis offsetX", pl.elements.threatText.x, 3)
check("threatText.y reporté depuis offsetY", pl.elements.threatText.y, -8)

print("── Clés mortes supprimées ──")
check("elementOffsets supprimé", pl.elementOffsets, nil)
check("raidIconOffset supprimé", pl.raidIconOffset, nil)
check("leaderIconOffset supprimé", pl.leaderIconOffset, nil)
check("threatText.offsetX supprimé", pl.threatText.offsetX, nil)
check("threatText.offsetY supprimé", pl.threatText.offsetY, nil)
check("threatText.fontSize préservé", pl.threatText.fontSize, 13)

print("── auras : c'est auras.position qui fait foi, pas la cle morte ──")
-- Le profil de test porte DEUX valeurs concurrentes : elementOffsets.auras
-- (40, 40), morte depuis 3.0.5, et auras.position, ecrite par le drag. La
-- migration doit prendre la seconde et ignorer la premiere -- sinon les
-- auras d'un joueur sauteraient de 40px a la mise a jour.
check("elements.auras cree", type(pl.elements.auras), "table")
check("point repris de auras.position", pl.elements.auras.point, "BOTTOMRIGHT")
check("relTo = frame", pl.elements.auras.relTo, "frame")
check("relPoint replie sur le point", pl.elements.auras.relPoint, "BOTTOMRIGHT")
check("x repris de auras.position", pl.elements.auras.x, 0)
check("y repris de auras.position", pl.elements.auras.y, 6)
check("cle morte elementOffsets.auras ignoree", pl.elements.auras.x ~= 40, true)
check("auras.position supprimee", pl.auras.position, nil)

print("── Conteneur jamais deplace : defauts du registre ──")
check("enemyBuffs cree", type(pl.elements.enemyBuffs), "table")
check("enemyBuffs = defaut registre", pl.elements.enemyBuffs.point, "BOTTOMRIGHT")
check("enemyBuffs relPoint defaut", pl.elements.enemyBuffs.relPoint, "TOPRIGHT")
check("enemyBuffs y defaut", pl.elements.enemyBuffs.y, 6)
check("drapeau de migration auras pose", TomoModDB._migrations.ufAuraElementsV1, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── Profil neuf : defaults du registre ──")
local db2 = freshDB()
TomoMod_InitDatabase()
local tg = TomoModDB.unitFrames.target
check("target.elements créé", type(tg.elements), "table")
check("target name.x = défaut registre", tg.elements.name.x, 6)
check("target level.point = défaut registre", tg.elements.level.point, "RIGHT")
local cnt = 0
for _ in pairs(tg.elements) do cnt = cnt + 1 end
check("9 éléments présents", cnt, 9)

print("── Toutes les unités couvertes ──")
for _, u in ipairs({ "player", "target", "targettarget", "pet", "focus" }) do
    check(u .. ".elements présent", type(TomoModDB.unitFrames[u].elements), "table")
end

-- ═══════════════════════════════════════════════════════════════════════
print("── Idempotence : second passage ──")
TomoModDB.unitFrames.player.elements.name.x = 42
TomoMod_InitDatabase()
check("valeur utilisateur non écrasée", TomoModDB.unitFrames.player.elements.name.x, 42)
check("drapeau de migration posé", TomoModDB._migrations.ufElementsV1, true)

print("── Élément ajouté plus tard : complété additivement ──")
TomoModDB.unitFrames.player.elements.threatText = nil
TomoMod_NormalizeUFElements()
check("threatText recréé sans migration", type(TomoModDB.unitFrames.player.elements.threatText), "table")
check("name.x toujours à 42", TomoModDB.unitFrames.player.elements.name.x, 42)

print("── Valeur corrompue : assainie à la normalisation ──")
TomoModDB.unitFrames.player.elements.level = { point = "NOWHERE", x = "abc" }
TomoMod_NormalizeUFElements()
check("point invalide corrigé", TomoModDB.unitFrames.player.elements.level.point, "RIGHT")
check("x non numérique corrigé", TomoModDB.unitFrames.player.elements.level.x, -6)

-- ═══════════════════════════════════════════════════════════════════════
print("── Profil sans unitFrames : pas de crash ──")
_G.TomoModDB = {}
check("normalisation sur DB vide", TomoMod_NormalizeUFElements(), false)

print(ok and "\nTOUS LES TESTS PASSENT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

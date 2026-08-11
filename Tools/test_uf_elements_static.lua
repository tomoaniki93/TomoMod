-- Analyse statique du lot AstralForge 1.
--
-- Une suite runtime ne peut pas prouver qu'un SetPoint d'élément n'a pas
-- resurgi ailleurs dans le moteur : elle ne voit que le chemin qu'elle
-- exerce. On lit donc les sources et on verrouille trois propriétés :
--
--   1. Les clés héritées (elementOffsets, raidIconOffset, leaderIconOffset,
--      threatText.offsetX/Y) ne sont plus LUES nulle part -- seule la
--      migration a le droit de les mentionner, pour les convertir.
--   2. Le registre est le SEUL point qui positionne un élément géré :
--      aucun SetPoint sur nameText/levelText/health.text/power/raidIcon/
--      leaderIcon/threatText hors des fabriques de construction.
--   3. Chaque élément du registre a sa clé de locale dans les SIX fichiers
--      de langue (le metatable de localisation rend la clé brute, donc une
--      clé manquante s'affiche telle quelle au lieu d'échouer).

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-56s attendu=%-8s obtenu=%s"):format(
        good and "OK   " or "ÉCHEC", label, tostring(want), tostring(got)))
end

-- La lecture est binaire, pour ne pas dependre du mode texte de la
-- plateforme : la BOM et les fins de ligne sont donc normalisees ici. Sans
-- le second gsub, un fichier en CRLF laisse un "\r" a la fin de chaque
-- ligne et tout motif ancre sur "\nend\n" -- soit la fermeture d'une
-- fonction en colonne 0 -- echoue sur un depot Windows alors que le code
-- teste est correct.
local function read(path)
    local fh = assert(io.open(path, "rb"), "fichier introuvable : " .. path)
    local s = fh:read("*a")
    fh:close()
    s = s:gsub("^\239\187\191", "")
    return (s:gsub("\r\n", "\n"))
end

-- Retire les commentaires de ligne : un rappel historique dans un
-- commentaire ne doit pas faire échouer l'analyse.
local function stripComments(src)
    local out = {}
    for line in (src .. "\n"):gmatch("(.-)\n") do
        out[#out + 1] = line:gsub("%-%-.*$", "")
    end
    return table.concat(out, "\n")
end

local function countOccurrences(src, pattern)
    local n = 0
    for _ in src:gmatch(pattern) do n = n + 1 end
    return n
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. Clés héritées : plus aucune lecture hors migration ──")

local LEGACY = { "elementOffsets", "raidIconOffset", "leaderIconOffset" }
local CONSUMERS = {
    "Modules/Interface/UnitFrames/Units/UnitFrame.lua",
    "Modules/Interface/UnitFrames/Units/BossFrames.lua",
    "Modules/Interface/UnitFrames/Elements/Health.lua",
    "Modules/Interface/UnitFrames/Elements/Power.lua",
    "Modules/Interface/UnitFrames/Elements/Auras.lua",
    "Config/Panels/UnitFrames.lua",
    "Config/Panels/UFPreview.lua",
    "Config/Presets.lua",
}

for _, path in ipairs(CONSUMERS) do
    local src = stripComments(read(path))
    for _, key in ipairs(LEGACY) do
        check(("%s : %s"):format(path:match("[^/]+$"), key),
            countOccurrences(src, key), 0)
    end
end

-- threatText.offsetX / offsetY : la clé `offsetX` sert aussi à d'autres
-- modules, on cible donc l'accès qualifié.
for _, path in ipairs(CONSUMERS) do
    local src = stripComments(read(path))
    local n = countOccurrences(src, "threatText%.offset")
        + countOccurrences(src, "tt%.offset")
    check(("%s : threatText offset"):format(path:match("[^/]+$")), n, 0)
end

do
    local db = stripComments(read("Core/Database.lua"))
    check("Database.lua : elementOffsets seulement en migration",
        countOccurrences(db, "elementOffsets") > 0, true)
    check("Database.lua : plus de defaults elementOffsets",
        countOccurrences(db, "elementOffsets = {"), 0)
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Le registre est le seul point de placement ──")

-- Widgets gérés par le registre : aucun SetPoint direct ne doit subsister
-- dans le moteur en dehors des fabriques (Health.lua construit puis le
-- registre repositionne -- on autorise donc Health.lua, pas UnitFrame.lua).
local MANAGED = {
    "nameText", "levelText", "raidIcon", "leaderIcon", "threatText",
}

do
    local src = stripComments(read("Modules/Interface/UnitFrames/Units/UnitFrame.lua"))
    for _, w in ipairs(MANAGED) do
        check(("UnitFrame.lua : %s:SetPoint"):format(w),
            countOccurrences(src, w .. "[^\n]-:SetPoint"), 0)
    end
    check("UnitFrame.lua : health.text:SetPoint",
        countOccurrences(src, "health%.text:SetPoint"), 0)
    check("UnitFrame.lua : power:SetPoint dans ApplyVisuals",
        countOccurrences(src, "frame%.power:SetPoint"), 0)
    check("UnitFrame.lua : appelle bien le registre",
        countOccurrences(src, "UFE%.ApplyAll"), 1)
    check("UnitFrame.lua : Ensure avant Apply",
        src:find("UFE%.Ensure") < src:find("UFE%.ApplyAll"), true)
end

-- Les conteneurs d'auras sont passes dans le registre au lot 6 : plus
-- aucun placement direct ne doit subsister dans le moteur.
do
    local src = stripComments(read("Modules/Interface/UnitFrames/Units/UnitFrame.lua"))
    check("UnitFrame.lua : plus de auraContainer:SetPoint",
        countOccurrences(src, "auraContainer:SetPoint"), 0)
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 3. Registre : intégrité des descripteurs ──")

_G.TomoMod_Forge = { BRAND = { 0, 0, 0 } }
assert(loadstring(read("Core/Forge/ForgeRegistry.lua")))()
assert(loadstring(read("Modules/Interface/UnitFrames/UFElements.lua")))()

local R   = TomoMod_Forge.Registry
local UFE = TomoMod_UFElements

local seenOrder, seenID = {}, {}
for _, desc in ipairs(UFE.List()) do
    check(("%s : labelKey défini"):format(desc.id), type(desc.labelKey), "string")
    check(("%s : resolve défini"):format(desc.id), type(desc.resolve), "function")
    check(("%s : point par défaut valide"):format(desc.id),
        R.IsPoint(desc.default.point), true)
    check(("%s : relPoint par défaut valide"):format(desc.id),
        R.IsPoint(desc.default.relPoint), true)
    check(("%s : relTo est un hôte déclaré"):format(desc.id),
        R.GetHost(UFE.DOMAIN, desc.default.relTo) ~= nil, true)
    check(("%s : order unique"):format(desc.id), seenOrder[desc.order], nil)
    check(("%s : id unique"):format(desc.id), seenID[desc.id], nil)
    seenOrder[desc.order], seenID[desc.id] = true, true
end

for _, host in ipairs(UFE.ListHosts()) do
    check(("hôte %s : labelKey défini"):format(host.id), type(host.labelKey), "string")
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 4. Parité des locales (6 fichiers) ──")

local LOCALES = { "enUS", "frFR", "deDE", "esES", "itIT", "ptBR" }

local NEEDED = { "opt_element_anchor", "btn_reset_elements",
                 "btn_open_astralforge", "info_astralforge",
                 "target_kind_host", "target_kind_element" }
for _, desc in ipairs(UFE.List()) do NEEDED[#NEEDED + 1] = desc.labelKey end
for _, host in ipairs(UFE.ListHosts()) do NEEDED[#NEEDED + 1] = host.labelKey end

for _, loc in ipairs(LOCALES) do
    local src = read("Locales/" .. loc .. ".lua")
    local missing = {}
    for _, key in ipairs(NEEDED) do
        if not src:find('%["' .. key .. '"%]%s*=') then
            missing[#missing + 1] = key
        end
    end
    check(("%s : %d clés présentes"):format(loc, #NEEDED),
        #missing == 0 and "complet" or table.concat(missing, ","), "complet")
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 5. Chargement déclaré ──")

do
    local toc = read("TomoMod.toc")
    check("TOC : ForgeRegistry déclaré",
        toc:find("Core\\Forge\\ForgeRegistry%.lua") ~= nil, true)
    check("TOC : ForgeRegistry après Forge.lua",
        toc:find("Core\\Forge\\Forge%.lua") < toc:find("Core\\Forge\\ForgeRegistry%.lua"), true)

    local xml = read("Modules/Interface/UnitFrames/UnitFrames.xml")
    check("XML : UFElements déclaré", xml:find("UFElements%.lua") ~= nil, true)
    check("XML : UFElements avant UnitFrame.lua",
        xml:find("UFElements%.lua") < xml:find("UnitFrame%.lua"), true)
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 6. AstralForge : le studio n'edite jamais un cadre live ──")

do
    local src = stripComments(read("TomoMod_AstralForge/AstralForge.lua"))

    -- Le sujet vient TOUJOURS de la fabrique d'apercu. Un CreateFrame de
    -- cadre d'unite, un oUF:Spawn ou un acces aux frames de jeu ici
    -- signifierait qu'on manipule un cadre protege.
    check("studio : passe par UFP.CreateStandalone",
        countOccurrences(src, "CreateStandalone") >= 1, true)
    check("studio : aucun oUF:Spawn", countOccurrences(src, "Spawn"), 0)
    check("studio : aucun SetAttribute", countOccurrences(src, "SetAttribute"), 0)
    check("studio : aucun RegisterUnitWatch", countOccurrences(src, "RegisterUnitWatch"), 0)
    check("studio : aucun _G[\"TomoMod_UF_", countOccurrences(src, 'TomoMod_UF_'), 0)

    -- Les ecritures passent par le registre, jamais par un SetPoint direct
    -- sur un widget du sujet.
    check("studio : aucun SetPoint sur health/power",
        countOccurrences(src, "subject%.health") + countOccurrences(src, "subject%.power"), 0)

    -- Le canvas ne connait pas les unites : c'est ce qui garantit qu'il ne
    -- peut pas toucher une API secrete ni un cadre protege.
    local cv = stripComments(read("Core/Forge/ForgeCanvas.lua"))
    for _, api in ipairs({ "UnitHealth", "UnitPower", "UnitName", "UnitExists",
                           "UnitAura", "InCombatLockdown", "SetAttribute" }) do
        check(("canvas : aucun appel a %s"):format(api), countOccurrences(cv, api), 0)
    end

    -- Regle cardinale du mover : jamais GetPoint() pour relire une position.
    check("canvas : aucun GetPoint()", countOccurrences(cv, "GetPoint%("), 0)
    check("canvas : mesure via ComputeOffset",
        countOccurrences(cv, "ComputeOffset") >= 2, true)
end

print("── 7. Garde anti-cycle d'ancrage ──")

do
    -- BuildVisuals ancre l'info bar sur `self.power or health`. Tout element
    -- que l'info bar suit doit donc s'interdire de s'ancrer EN RETOUR sur
    -- elle, sinon le client leve une erreur de famille d'ancrage.
    local bv = stripComments(read("Modules/Interface/UnitFrames/Units/UnitFrame.lua"))
    local infoBarFollowsPower = bv:find("infoBar:SetPoint%(\"TOP\", self%.power") ~= nil
    check("info bar suit bien power (hypothese de la garde)", infoBarFollowsPower, true)
    check("power : infoBar exclu de ses cibles",
        R.TargetAllowed(R.Get(UFE.DOMAIN, "power"), "infoBar"), false)

    -- Toute valeur par defaut doit elle-meme etre une cible autorisee et
    -- declaree, sinon un profil neuf partirait deja en repli.
    for _, desc in ipairs(UFE.List()) do
        check(("%s : cible par defaut autorisee"):format(desc.id),
            R.TargetAllowed(desc, desc.default.relTo), true)
        check(("%s : cible par defaut declaree"):format(desc.id),
            R.IsTarget(UFE.DOMAIN, desc.default.relTo), true)
        check(("%s : cible par defaut != lui-meme"):format(desc.id),
            desc.default.relTo ~= desc.id, true)
    end

    -- Le graphe par defaut ne doit contenir aucune boucle : c'est ce qui
    -- part dans tous les profils neufs.
    local seed = {}
    for _, desc in ipairs(UFE.List()) do
        seed[desc.id] = { relTo = desc.default.relTo }
    end
    for _, desc in ipairs(UFE.List()) do
        check(("%s : pas de boucle par defaut"):format(desc.id),
            R.WouldCycle(UFE.DOMAIN, seed, desc.id, desc.default.relTo), false)
    end

    -- Un id declare a la fois comme hote ET comme element doit designer le
    -- meme widget, sinon la resolution dependrait du chemin emprunte.
    local shared = {}
    for _, h in ipairs(UFE.ListHosts()) do
        if R.Get(UFE.DOMAIN, h.id) then shared[#shared + 1] = h.id end
    end
    check("ids partages hote/element : au moins un (power)",
        #shared >= 1, true)
    for _, id in ipairs(shared) do
        local hostDesc = R.GetHost(UFE.DOMAIN, id)
        local elemDesc = R.Get(UFE.DOMAIN, id)
        local probe = { power = "W_POWER", health = "W_HEALTH", infoBar = "W_INFO" }
        check(("id partage %s : meme resolution"):format(id),
            hostDesc.resolve(probe), elemDesc.resolve(probe))
    end
end

print("── 8. Chargement du lot 2 ──")

do
    local toc = read("TomoMod.toc")
    check("TOC : ForgeCanvas declare",
        toc:find("Core\\Forge\\ForgeCanvas%.lua") ~= nil, true)
    check("TOC : ForgeCanvas apres ForgeRegistry",
        toc:find("Core\\Forge\\ForgeRegistry%.lua") < toc:find("Core\\Forge\\ForgeCanvas%.lua"), true)

    local stoc = read("TomoMod_AstralForge/TomoMod_AstralForge.toc")
    check("studio TOC : LoadOnDemand", stoc:find("## LoadOnDemand: 1") ~= nil, true)
    check("studio TOC : depend de TomoMod", stoc:find("## Dependencies: TomoMod") ~= nil, true)
    check("studio TOC : declare AstralForge.lua", stoc:find("AstralForge%.lua") ~= nil, true)

    -- Le studio est un addon FRERE : il ne doit jamais etre liste dans le
    -- TOC principal, sinon il perd son chargement a la demande.
    check("TOC principal : n'embarque pas le studio",
        toc:find("AstralForge") ~= nil, false)

    -- ...et il doit etre relocalise par le packager. Sans cette entree, le
    -- zip livre le dossier IMBRIQUE dans TomoMod/ ; WoW ne scanne que le
    -- premier niveau de Interface/AddOns, donc le studio serait invisible
    -- dans la liste des addons du joueur.
    local pkg = read(".pkgmeta")
    check("pkgmeta : AstralForge relocalise en addon frere",
        pkg:find("TomoMod/TomoMod_AstralForge: TomoMod_AstralForge") ~= nil, true)
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 9. Plaques de nom : le registre est le seul point de placement ──")

assert(loadstring(read("Core/Forge/ForgeText.lua")))()
assert(loadstring(read("Modules/Interface/NamePlates/NPElements.lua")))()
local NPE = TomoMod_NPElements

do
    local src = stripComments(read("Modules/Interface/NamePlates/Nameplates.lua"))

    -- Les cles heritees ne doivent plus etre LUES nulle part.
    for _, key in ipairs({ "raidIconAnchor", "raidIconX", "raidIconY" }) do
        check(("Nameplates.lua : %s"):format(key), countOccurrences(src, key), 0)
    end
    local panel = stripComments(read("Config/Panels/Nameplates.lua"))
    for _, key in ipairs({ "raidIconAnchor", "raidIconX", "raidIconY" }) do
        check(("panneau NP : %s"):format(key), countOccurrences(panel, key), 0)
    end
    check("raidIconSize conserve (taille)", countOccurrences(panel, "raidIconSize") >= 1, true)

    -- Un seul point d'application, appele a la construction ET au resize :
    -- une plaque recyclee par le client repasse forcement par la.
    check("ApplyElements defini une fois",
        countOccurrences(src, "local function ApplyElements"), 1)
    check("ApplyElements appele au moins deux fois",
        countOccurrences(src, "ApplyElements%(plate%)") >= 2, true)

    -- L'apercu du studio doit passer par LA MEME fabrique que les plaques
    -- de jeu, sinon les deux divergeraient.
    check("CreatePreviewPlate utilise CreatePlate",
        src:find("local plate = CreatePlate%(base%)") ~= nil, true)
    -- ...et ne doit lire aucune unite : le studio ne verrait alors que des
    -- valeurs secretes.
    for _, api in ipairs({ "UnitHealth", "UnitName", "UnitLevel", "UnitAura" }) do
        local body = src:match("function NP%.CreatePreviewPlate.-\nend") or ""
        check(("apercu NP : aucun %s"):format(api), countOccurrences(body, api), 0)
    end
end

print("── 10. Domaine nameplate : integrite des descripteurs ──")

do
    local seenOrder, seenID = {}, {}
    for _, desc in ipairs(NPE.List()) do
        check(("np %s : labelKey"):format(desc.id), type(desc.labelKey), "string")
        check(("np %s : point defaut valide"):format(desc.id),
            R.IsPoint(desc.default.point), true)
        check(("np %s : relPoint defaut valide"):format(desc.id),
            R.IsPoint(desc.default.relPoint), true)
        check(("np %s : cible defaut declaree"):format(desc.id),
            R.IsTarget(NPE.DOMAIN, desc.default.relTo), true)
        check(("np %s : cible defaut != lui-meme"):format(desc.id),
            desc.default.relTo ~= desc.id, true)
        check(("np %s : order unique"):format(desc.id), seenOrder[desc.order], nil)
        check(("np %s : id unique"):format(desc.id), seenID[desc.id], nil)
        seenOrder[desc.order], seenID[desc.id] = true, true
    end

    -- Graphe par defaut acyclique : c'est ce qui part dans tout profil neuf.
    local seed = {}
    for _, desc in ipairs(NPE.List()) do seed[desc.id] = { relTo = desc.default.relTo } end
    for _, desc in ipairs(NPE.List()) do
        check(("np %s : pas de boucle par defaut"):format(desc.id),
            R.WouldCycle(NPE.DOMAIN, seed, desc.id, desc.default.relTo), false)
    end

    -- Ids partages hote/element : meme resolution des deux cotes.
    for _, h in ipairs(NPE.ListHosts()) do
        local elemDesc = R.Get(NPE.DOMAIN, h.id)
        if elemDesc then
            local probe = { castbar = "W_CB", nameText = "W_NAME", health = "W_HP" }
            check(("np id partage %s : meme resolution"):format(h.id),
                h.resolve(probe), elemDesc.resolve(probe))
        end
    end

    -- Les deux domaines sont cloisonnes : aucun id de l'un ne fuit dans
    -- l'autre listing.
    check("unitframe garde 9 elements", #UFE.List(), 9)
    check("nameplate a 13 elements", #NPE.List(), 13)
    check("domaine inconnu : liste vide", #R.List("plop"), 0)
end

print("── 11. Parite des locales, domaine nameplate ──")

do
    local needed = {}
    for _, d in ipairs(NPE.List()) do needed[#needed + 1] = d.labelKey end
    for _, h in ipairs(NPE.ListHosts()) do needed[#needed + 1] = h.labelKey end
    needed[#needed + 1] = "section_np_elements"
    needed[#needed + 1] = "info_np_elements"

    for _, loc in ipairs(LOCALES) do
        local src = read("Locales/" .. loc .. ".lua")
        local missing = {}
        for _, key in ipairs(needed) do
            if not src:find('%["' .. key .. '"%]%s*=') then missing[#missing + 1] = key end
        end
        check(("%s : %d cles NP"):format(loc, #needed),
            #missing == 0 and "complet" or table.concat(missing, ","), "complet")
        -- La cle devenue orpheline ne doit trainer nulle part.
        check(("%s : opt_np_raid_icon_anchor retiree"):format(loc),
            src:find('opt_np_raid_icon_anchor') ~= nil, false)
    end

    local xml = read("Modules/Interface/NamePlates/Nameplates.xml")
    check("XML : NPElements declare", xml:find("NPElements%.lua") ~= nil, true)
    check("XML : NPElements avant Nameplates.lua",
        xml:find("NPElements%.lua") < xml:find('file="Nameplates%.lua"'), true)
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 12. Types de widget declares et coherents ──")

do
    -- Le `kind` decide des proprietes applicables. S'il ment, le registre
    -- appellera SetScale sur une region (erreur client) ou proposera une
    -- taille de police sur une texture (bouton mort).
    local RESOLVERS = {
        [UFE.DOMAIN] = {
            name = "fontstring", level = "fontstring", healthText = "fontstring",
            power = "frame", raidIcon = "texture", leaderIcon = "texture",
            threatText = "fontstring", auras = "frame", enemyBuffs = "frame",
        },
        [NPE.DOMAIN] = {
            name = "fontstring", hpNumber = "fontstring", hpPercent = "fontstring",
            level = "fontstring", classIcon = "frame", classText = "fontstring",
            castbar = "frame", castIcon = "frame", castText = "fontstring",
            castTimer = "fontstring", castShield = "frame",
            questIcon = "texture", raidMarker = "frame",
        },
    }

    for _, dom in ipairs({ UFE, NPE }) do
        local expected = RESOLVERS[dom.DOMAIN]
        for _, desc in ipairs(dom.List()) do
            check(("%s/%s : kind declare"):format(dom.DOMAIN, desc.id),
                R.KINDS[desc.kind] == true, true)
            check(("%s/%s : kind attendu"):format(dom.DOMAIN, desc.id),
                desc.kind, expected[desc.id])
        end
    end

    -- Coherence capacites <-> type, verifiee depuis le registre lui-meme.
    for _, dom in ipairs({ UFE, NPE }) do
        for _, desc in ipairs(dom.List()) do
            local scale = R.HasProp(dom.DOMAIN, desc.id, "scale")
            local font  = R.HasProp(dom.DOMAIN, desc.id, "fontSize")
            check(("%s/%s : echelle ssi frame"):format(dom.DOMAIN, desc.id),
                scale, desc.kind == "frame")
            check(("%s/%s : police ssi chaine"):format(dom.DOMAIN, desc.id),
                font, desc.kind == "fontstring")
            check(("%s/%s : opacite toujours"):format(dom.DOMAIN, desc.id),
                R.HasProp(dom.DOMAIN, desc.id, "alpha"), true)
        end
    end
end

print("── 13. Proprietes : absolues, jamais en delta ──")

do
    -- ApplyProps repasse a chaque rafraichissement. Une ecriture relative
    -- derivrait a chaque passage : on interdit les operateurs cumulatifs
    -- dans le corps de la fonction.
    local reg = stripComments(read("Core/Forge/ForgeRegistry.lua"))
    local body = reg:match("function R%.ApplyProps.-\nend") or ""
    check("ApplyProps existe", #body > 0, true)
    for _, pat in ipairs({ "GetAlpha%(", "GetScale%(", "%+=", "cfg%.alpha%s*%*", "cfg%.scale%s*%*" }) do
        check(("ApplyProps : aucun cumul (%s)"):format(pat),
            countOccurrences(body, pat), 0)
    end
    -- La famille et les flags viennent du module, seule la taille est forcee.
    check("ApplyProps relit la police du module",
        countOccurrences(body, "GetFont%(") >= 1, true)

    -- Couleur / visibilite / taille restent hors registre : ce sont les
    -- modules qui les recalculent en continu.
    for _, api in ipairs({ "SetTextColor", "SetVertexColor", "SetSize", "SetShown" }) do
        check(("ApplyProps : pas de %s"):format(api), countOccurrences(body, api), 0)
    end
end

print("── 14. Parite des locales, proprietes ──")

do
    local needed = { "sublabel_element_props", "opt_element_alpha",
                     "opt_element_scale", "opt_element_font_size",
                     "info_element_font_size" }
    for _, loc in ipairs(LOCALES) do
        local src = read("Locales/" .. loc .. ".lua")
        local missing = {}
        for _, key in ipairs(needed) do
            if not src:find('%["' .. key .. '"%]%s*=') then missing[#missing + 1] = key end
        end
        check(("%s : %d cles proprietes"):format(loc, #needed),
            #missing == 0 and "complet" or table.concat(missing, ","), "complet")
    end
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 15. Conteneurs d'auras : plus de seconde source de verite ──")

do
    -- Les deux conteneurs gardaient leur position dans auras.position /
    -- enemyBuffs.position. Plus aucune lecture ne doit subsister hors
    -- migration, sinon on aurait de nouveau deux verites concurrentes.
    for _, path in ipairs({
        "Modules/Interface/UnitFrames/Units/UnitFrame.lua",
        "Modules/Interface/UnitFrames/Elements/Auras.lua",
        "Config/Panels/UnitFrames.lua",
    }) do
        local src = stripComments(read(path))
        check(("%s : plus de auraSettings.position"):format(path:match("[^/]+$")),
            countOccurrences(src, "auraSettings%.position"), 0)
        check(("%s : plus de buffSettings.position"):format(path:match("[^/]+$")),
            countOccurrences(src, "buffSettings%.position"), 0)
    end

    -- Et surtout : la valeur par defaut doit avoir disparu de la DB. Tant
    -- qu'elle y est, MergeTables la ressuscite a chaque connexion et la cle
    -- morte revient indefiniment.
    local db = stripComments(read("Core/Database.lua"))
    check("Database : plus de position par defaut des conteneurs",
        countOccurrences(db, 'position = { point = "BOTTOMRIGHT", relativePoint = "TOPRIGHT", x = 0, y = 6 }'), 0)
    check("Database : migration des conteneurs presente",
        countOccurrences(db, "ufAuraElementsV1") >= 1, true)

    -- Un seul point de sauvegarde du drag, partage par les deux conteneurs.
    local auras = stripComments(read("Modules/Interface/UnitFrames/Elements/Auras.lua"))
    check("un seul SaveContainerDrag defini",
        countOccurrences(auras, "function UF_Elements%.SaveContainerDrag"), 1)
    check("appele par les deux conteneurs",
        countOccurrences(auras, "UF_Elements%.SaveContainerDrag%(self"), 2)
    check("le drag n'utilise jamais GetPoint",
        countOccurrences(auras, "GetPoint%("), 0)

    check("auras est un element du registre", R.Get(UFE.DOMAIN, "auras") ~= nil, true)
    check("enemyBuffs est un element du registre",
        R.Get(UFE.DOMAIN, "enemyBuffs") ~= nil, true)
    check("unitframe compte 9 elements fixes", #UFE.List(), 9)
end

print("── 16. Texte personnalise : aucune valeur secrete touchee par Lua ──")

do
    local src = stripComments(read("Modules/Interface/UnitFrames/UFElements.lua"))
    local body = src:match("function UFE%.RenderCustomText.-\nend") or ""
    check("RenderCustomText existe", #body > 0, true)

    -- Depuis le lot 7 le rendu est DELEGUE au compilateur partage : ce qui
    -- se verifie ici, c'est qu'il delegue bien et ne bricole rien au passage.
    -- Le compilateur lui-meme est verifie en section 19.
    check("delegue au compilateur partage",
        countOccurrences(body, "Forge%.Text%.Render") >= 1, true)
    check("verifie l'existence de l'unite",
        countOccurrences(body, "UnitExists") >= 1, true)
    for _, pat in ipairs({ "%.%.%s*UnitName", "UnitName%b()%s*%.%.", "tostring%(Unit",
                           "#Unit", "string%.format" }) do
        check(("RenderCustomText : aucun %s"):format(pat),
            countOccurrences(body, pat), 0)
    end

    -- Les jetons de vie / ressource sont volontairement absents : le jeton
    -- utile serait un pourcentage, donc une division sur valeur secrete.
    local tokens = src:match("UFE%.TOKENS = %{.-%}\n") or ""
    for _, forbidden in ipairs({ "hp", "health", "power", "perc", "mana" }) do
        check(("aucun jeton %s"):format(forbidden),
            countOccurrences(tokens, '"' .. forbidden), 0)
    end

    -- Le rafraichissement se greffe sur la mise a jour du nom : memes
    -- evenements, aucun nouvel enregistrement.
    local uf = stripComments(read("Modules/Interface/UnitFrames/Units/UnitFrame.lua"))
    check("RefreshCustomTexts appele depuis UpdateName",
        (uf:match("local function UpdateName.-\nend") or ""):find("RefreshCustomTexts") ~= nil, true)
end

print("── 17. Elements instancies : integrite ──")

do
    check("un type instanciable declare", #R.ListTypes(UFE.DOMAIN), 1)
    for _, t in ipairs(R.ListTypes(UFE.DOMAIN)) do
        check(("type %s : build defini"):format(t.id), type(t.build), "function")
        check(("type %s : plafond raisonnable"):format(t.id), t.max > 0 and t.max <= 20, true)
        check(("type %s : kind declare"):format(t.id), R.KINDS[t.kind] == true, true)
        check(("type %s : cible defaut declaree"):format(t.id),
            R.IsTarget(UFE.DOMAIN, t.default.relTo), true)
    end
    -- Le domaine plaques en declare un depuis le lot 7, avec son propre
    -- point de rafraichissement dans UpdatePlate.
    check("nameplate : un type instanciable", #R.ListTypes(NPE.DOMAIN), 1)
    for _, t in ipairs(R.ListTypes(NPE.DOMAIN)) do
        check(("np type %s : build defini"):format(t.id), type(t.build), "function")
        check(("np type %s : cible defaut declaree"):format(t.id),
            R.IsTarget(NPE.DOMAIN, t.default.relTo), true)
    end
end

print("── 18. Parite des locales, lot 6 ──")

do
    local needed = { "elem_auras", "elem_enemy_buffs", "elem_custom_text",
                     "opt_custom_text_template", "info_custom_text_tokens",
                     "btn_add_custom_text", "btn_reset_element", "btn_delete_element",
                     "msg_element_max_reached" }
    for _, t in ipairs(UFE.TOKENS or {}) do needed[#needed + 1] = t.labelKey end
    for _, loc in ipairs(LOCALES) do
        local src = read("Locales/" .. loc .. ".lua")
        local missing = {}
        for _, key in ipairs(needed) do
            if not src:find('%["' .. key .. '"%]%s*=') then missing[#missing + 1] = key end
        end
        check(("%s : %d cles lot 6"):format(loc, #needed),
            #missing == 0 and "complet" or table.concat(missing, ","), "complet")
    end
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 19. Compilateur de texte : un seul, partage ──")

do
    -- Le lot 7 factorise le compilateur dans Forge.Text. Les deux domaines
    -- doivent le DELEGUER, pas en garder une copie : la partie risquee (ne
    -- jamais toucher une valeur secrete en Lua) ne doit exister qu'une fois.
    local ft = stripComments(read("Core/Forge/ForgeText.lua"))
    check("Forge.Text.Render defini", countOccurrences(ft, "function T%.Render"), 1)
    check("Render passe par SetFormattedText",
        countOccurrences(ft, "SetFormattedText") >= 1, true)
    for _, pat in ipairs({ "value%s*%.%.", "%.%.%s*value", "#value", "tostring%(value" }) do
        check(("Forge.Text : aucun %s"):format(pat), countOccurrences(ft, pat), 0)
    end

    for _, path in ipairs({
        "Modules/Interface/UnitFrames/UFElements.lua",
        "Modules/Interface/NamePlates/NPElements.lua",
    }) do
        local src = stripComments(read(path))
        local short = path:match("[^/]+$")
        check(("%s : delegue a Forge.Text.Render"):format(short),
            countOccurrences(src, "Forge%.Text%.Render"), 1)
        -- Aucune reimplementation locale du parseur.
        check(("%s : pas de parseur local"):format(short),
            countOccurrences(src, "template:find"), 0)
        check(("%s : pas de SetFormattedText direct"):format(short),
            countOccurrences(src, "SetFormattedText"), 0)
    end

    -- Jetons interdits dans LES DEUX domaines, pour la meme raison : le
    -- jeton utile serait un pourcentage, donc une division sur secret.
    for _, path in ipairs({
        "Modules/Interface/UnitFrames/UFElements.lua",
        "Modules/Interface/NamePlates/NPElements.lua",
    }) do
        local src = read(path)
        local tokens = src:match("TOKENS = %{.-\n%}") or ""
        for _, forbidden in ipairs({ "hp", "health", "power", "perc", "mana" }) do
            check(("%s : aucun jeton %s"):format(path:match("[^/]+$"), forbidden),
                countOccurrences(tokens, '"' .. forbidden), 0)
        end
    end

    -- Le rafraichissement plaques se greffe sur UpdatePlate, la ou le nom
    -- est deja mis a jour : une plaque recyclee y repasse forcement.
    local np = stripComments(read("Modules/Interface/NamePlates/Nameplates.lua"))
    -- `.-` s'arrete au premier "\nend" rencontre ; on ancre donc sur un
    -- `end` en colonne 0, qui est la fermeture de la fonction elle-meme.
    local upBody = np:match("\nlocal function UpdatePlate%b()(.-)\nend\n") or ""
    check("NP : corps de UpdatePlate trouve", #upBody > 0, true)
    check("NP : RefreshCustomTexts appele depuis UpdatePlate",
        upBody:find("RefreshCustomTexts") ~= nil, true)
    check("nameplate declare un type instanciable", #R.ListTypes(NPE.DOMAIN), 1)
end

print("── 20. Presets : tout ce qui rentre est assaini ──")

do
    local fa = stripComments(read("Core/Forge/ForgeAssets.lua"))

    -- Une charge utile importee ne doit jamais etre recopiee telle quelle.
    check("copyStore defini", countOccurrences(fa, "local function copyStore"), 1)
    check("Apply repasse par Ensure",
        (fa:match("function A%.Apply.-\nend") or ""):find("R%.Ensure") ~= nil, true)
    check("Import repasse par copyStore",
        (fa:match("function A%.Import.-\nend") or ""):find("copyStore") ~= nil, true)
    check("Import verifie le domaine",
        (fa:match("function A%.Import.-\nend") or ""):find("expectDomain") ~= nil, true)

    -- Aucune execution de contenu importe.
    for _, api in ipairs({ "loadstring", "setfenv", "pcall%(payload", "RunScript" }) do
        check(("ForgeAssets : aucun %s"):format(api), countOccurrences(fa, api), 0)
    end

    -- Le codec partage est celui de Forge.IO, pas une pipeline maison.
    check("codec via Forge.IO.MakeCodec",
        countOccurrences(fa, "Forge%.IO%.MakeCodec"), 1)
    check("entete propre a AstralForge",
        fa:find('A%.HEADER%s*=%s*"TOMOAF"') ~= nil, true)

    -- Le studio doit verifier le domaine a l'import, sinon appliquer une
    -- disposition de plaque a un cadre viderait ce dernier.
    local studio = stripComments(read("TomoMod_AstralForge/AstralForge.lua"))
    check("studio : import avec domaine attendu",
        countOccurrences(studio, "A%.Import%(S%.state%.importText, dom%)"), 1)

    local toc = read("TomoMod.toc")
    check("TOC : ForgeText declare", toc:find("ForgeText%.lua") ~= nil, true)
    check("TOC : ForgeAssets declare", toc:find("ForgeAssets%.lua") ~= nil, true)
    check("TOC : ForgeText avant les registres",
        toc:find("ForgeText%.lua") < toc:find("ForgeRegistry%.lua"), true)
    check("TOC : ForgeAssets apres ForgeRegistry",
        toc:find("ForgeRegistry%.lua") < toc:find("ForgeAssets%.lua"), true)
end

print("── 21. Parite des locales, lot 7 ──")

do
    local needed = { "section_forge_presets", "btn_forge_presets", "info_forge_presets",
                     "opt_preset_name", "btn_preset_save", "opt_preset_saved",
                     "btn_preset_apply", "btn_preset_delete", "btn_preset_export",
                     "opt_preset_share_string", "info_preset_copy", "opt_preset_import",
                     "btn_preset_import", "info_no_preset", "msg_preset_saved",
                     "msg_preset_applied", "msg_preset_imported", "msg_preset_error",
                     "msg_presets_unavailable" }
    for _, t in ipairs(NPE.TOKENS or {}) do needed[#needed + 1] = t.labelKey end
    for _, loc in ipairs(LOCALES) do
        local src = read("Locales/" .. loc .. ".lua")
        local missing = {}
        for _, key in ipairs(needed) do
            if not src:find('%["' .. key .. '"%]%s*=') then missing[#missing + 1] = key end
        end
        check(("%s : %d cles lot 7"):format(loc, #needed),
            #missing == 0 and "complet" or table.concat(missing, ","), "complet")
    end
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 22. Valeurs secretes : le test precede toujours l'operation ──")

do
    -- Session #961 : GetLeft() rendait une valeur secrete et le `r - l`
    -- suivant levait. La regle est que issecretvalue() passe AVANT toute
    -- arithmetique ET toute comparaison -- une regle d'ORDRE, que seul un
    -- controle statique peut verifier.
    local cv = stripComments(read("Core/Forge/ForgeCanvas.lua"))

    check("helper Plain defini", countOccurrences(cv, "local function Plain"), 1)
    check("Plain interroge issecretvalue",
        (cv:match("local function Plain.-\nend") or ""):find("IsSecret") ~= nil, true)
    check("IsSecret passe par issecretvalue",
        (cv:match("local function IsSecret.-\nend") or ""):find("issecretvalue") ~= nil, true)

    -- Toute lecture de rect doit etre enveloppee. Un GetLeft() nu qui
    -- reapparaitrait ici ramenerait le crash.
    for _, getter in ipairs({ "GetLeft", "GetRight", "GetTop", "GetBottom" }) do
        local total   = countOccurrences(cv, ":" .. getter .. "%(%)")
        -- Un seul motif : "Plain(" attrape aussi bien l'appel local que
        -- "C.Plain(", les additionner compterait deux fois le meme site.
        local wrapped = countOccurrences(cv, "Plain%(%w+:" .. getter .. "%(%)%)")
        check(("%s toujours enveloppe (%d/%d)"):format(getter, wrapped, total),
            wrapped, total)
    end

    -- Idem pour l'echelle : la comparaison `s > 0` sur une valeur secrete
    -- leve tout autant que l'arithmetique.
    local scaleBody = cv:match("function C%.EffectiveScale.-\nend") or ""
    check("EffectiveScale : corps trouve", #scaleBody > 0, true)
    check("EffectiveScale enveloppe GetEffectiveScale",
        countOccurrences(scaleBody, "Plain%(%w+:GetEffectiveScale%(%)%)"),
        countOccurrences(scaleBody, ":GetEffectiveScale%(%)"))

    -- L'apercu du studio ne doit PAS partir en donnees reelles : un widget
    -- alimente en donnees protegees a un rect secret, donc non mesurable.
    -- C'est la correction de fond, le reste est la defense.
    local prev = stripComments(read("Config/Panels/UFPreview.lua"))
    local stand = prev:match("function UFP%.CreateStandalone.-\nend\n") or ""
    check("CreateStandalone : corps trouve", #stand > 0, true)
    check("apercu autonome simule par defaut",
        stand:find("opts and opts%.live") ~= nil, true)
    check("IsLive n'est plus inconditionnel",
        countOccurrences(stand, "ApplyDataMode%(pu, unitKey, settings, IsLive"), 0)

    -- Et la fenetre doit survivre a un apercu qui echoue.
    local studio = stripComments(read("TomoMod_AstralForge/AstralForge.lua"))
    local open = studio:match("function S%.Open%(%)(.-)\nend") or ""
    check("Open : corps trouve", #open > 0, true)
    check("Open protege la construction du sujet",
        open:find("pcall%(RebuildSubject%)") ~= nil, true)
    check("Open reconstruit la liste malgre l'echec",
        open:find("S%.RebuildSidebar") ~= nil, true)
end

print(ok and "\nTOUS LES TESTS PASSENT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

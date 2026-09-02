-- Hygiene des evenements : analyse statique de tout l'addon.
--
-- Ce que ce banc cherche, et pourquoi il vaut mieux qu'une passe manuelle.
--
-- Un evenement d'unite enregistre globalement reveille son handler pour
-- CHAQUE unite visible. En raid, UNIT_AURA et UNIT_HEALTH se declenchent
-- des centaines de fois par seconde. Quand le handler commence par
-- « si ce n'est pas le joueur, je sors », tout ce travail est jete --
-- mais il a quand meme traverse le dispatcher du client, alloue les
-- arguments et appele du Lua.
--
-- Le motif est invisible a la lecture parce qu'il a l'air correct : le
-- filtre EST la, juste au mauvais endroit. RegisterUnitEvent demande au
-- client de filtrer avant de reveiller quoi que ce soit.
--
-- L'audit du lot 8 a trouve exactement deux cas sur tout l'addon, et
-- surtout beaucoup de faux positifs : les plaques de nom, ClassReminder
-- et MicroBar filtraient deja correctement. C'est justement pour ca que
-- le controle est fige ici plutot que refait a la main : il ne se
-- trompe pas, et il ne se fatigue pas.
--
-- Usage : luajit Tools/test_event_hygiene.lua   (depuis la racine)

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

local function Sources()
    local files = {}
    for _, dir in ipairs({ "Core", "Modules" }) do
        local pipe = io.popen('find "' .. dir .. '" -name "*.lua" 2>/dev/null')
        if pipe then
            for line in pipe:lines() do
                if not line:find("/Libs/") then files[#files + 1] = line end
            end
            pipe:close()
        end
    end
    table.sort(files)
    return files
end

local files = Sources()
check("des sources ont ete trouvees", #files > 0, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. Evenements d'unite enregistres globalement ──")

-- Les plus bruyants. Un enregistrement global de ceux-la se paie a
-- chaque unite visible, a chaque tick.
local NOISY = {
    UNIT_AURA = true, UNIT_HEALTH = true, UNIT_MAXHEALTH = true,
    UNIT_POWER_UPDATE = true, UNIT_MAXPOWER = true,
    UNIT_DISPLAYPOWER = true, UNIT_NAME_UPDATE = true,
    UNIT_THREAT_LIST_UPDATE = true, UNIT_TARGET = true,
    UNIT_INVENTORY_CHANGED = true, UNIT_ABSORB_AMOUNT_CHANGED = true,
    UNIT_HEAL_PREDICTION = true, UNIT_PORTRAIT_UPDATE = true,
    UNIT_FLAGS = true, UNIT_CONNECTION = true,
}

-- Un enregistrement global est tolere quand le fichier montre qu'il sait
-- ce qu'il fait : soit il utilise RegisterUnitEvent ailleurs pour le meme
-- evenement (elargissement conditionnel, comme ClassReminder), soit il
-- desenregistre explicitement (activation par contexte, comme
-- ArenaFrames depuis ce lot).
local offenders, tolerated = {}, 0

for _, path in ipairs(files) do
    local src = read(path)
    if src then
        for ev in src:gmatch('RegisterEvent%("(UNIT_[%w_]+)"%)') do
            if NOISY[ev] then
                local filtered   = src:find('RegisterUnitEvent%("' .. ev .. '"') ~= nil
                local unregisters = src:find('UnregisterEvent%(') ~= nil
                    and src:find(ev, 1, true) ~= nil
                    and src:find('UNIT_EVENTS', 1, true) ~= nil
                if filtered or unregisters then
                    tolerated = tolerated + 1
                else
                    offenders[#offenders + 1] = path .. " -> " .. ev
                end
            end
        end
    end
end

for _, o in ipairs(offenders) do
    fail("evenement d'unite non filtre et non desenregistre : " .. o)
end
check("aucun enregistrement global injustifie", #offenders, 0)
check("des cas justifies existent", tolerated > 0, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Les deux corrections du lot 8 tiennent ──")

local cb = read("Modules/QOL/Consumables/ConsumableBar.lua")
check("ConsumableBar filtre UNIT_AURA",
      cb:find('RegisterUnitEvent%("UNIT_AURA", "player"%)') ~= nil, true)
check("ConsumableBar filtre l'inventaire",
      cb:find('RegisterUnitEvent%("UNIT_INVENTORY_CHANGED", "player"%)') ~= nil, true)
-- Le repli reste : RegisterUnitEvent existe sur tous les clients modernes,
-- mais le motif est celui deja utilise par MicroBar et on s'y tient.
check("le repli est conserve", cb:find("if eventFrame.RegisterUnitEvent then", 1, true) ~= nil, true)

local af = read("Modules/Interface/PartyFrame/ArenaFrames.lua")
check("ArenaFrames expose la bascule",
      af:find("function AF.SetUnitEventsActive", 1, true) ~= nil, true)
check("elle est appelee a l'entree en zone",
      af:find('AF.SetUnitEventsActive%(IsActiveBattlefieldArena') ~= nil, true)
-- Les cinq evenements doivent passer par la table, pas etre reposes en dur.
local hardcoded = 0
for _, ev in ipairs({ "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE",
                      "UNIT_MAXPOWER", "UNIT_NAME_UPDATE" }) do
    if af:find('eventFrame:RegisterEvent%("' .. ev .. '"%)') then
        hardcoded = hardcoded + 1
        fail(("ArenaFrames reenregistre '%s' en dur"):format(ev))
    end
end
check("aucun reenregistrement en dur", hardcoded, 0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 3. OnUpdate : inventaire, pas verdict ──")

-- Un OnUpdate sans accumulateur n'est PAS forcement fautif. L'audit en a
-- fait la demonstration : la frame de lot des plaques de nom se masque
-- elle-même apres un passage, et le studio en RETIRE un. Compter sert a
-- surveiller la tendance, pas a condamner.
local onUpdate, selfHiding = 0, 0
for _, path in ipairs(files) do
    local src = read(path)
    if src then
        for _ in src:gmatch('SetScript%("OnUpdate"') do onUpdate = onUpdate + 1 end
        for _ in src:gmatch('SetScript%("OnUpdate", function%b()%s*\n%s*self:Hide%(%)') do
            selfHiding = selfHiding + 1
        end
    end
end
print(("  %d gestionnaires OnUpdate, dont %d se masquent des le premier passage")
      :format(onUpdate, selfHiding))
check("le compte reste mesurable", onUpdate > 0, true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 4. Proportion filtree ──")

local globalN, unitN = 0, 0
for _, path in ipairs(files) do
    local src = read(path)
    if src then
        for _ in src:gmatch("RegisterUnitEvent%(") do unitN = unitN + 1 end
        for _ in src:gmatch("[^t]RegisterEvent%(") do globalN = globalN + 1 end
    end
end
print(("  %d RegisterEvent, %d RegisterUnitEvent"):format(globalN, unitN))
-- La grande majorite des RegisterEvent portent sur des evenements sans
-- unite (PLAYER_*, ZONE_*, BAG_*) pour lesquels il n'existe pas de
-- variante filtree : le ratio brut ne veut rien dire, seul le contenu de
-- la section 1 en dit quelque chose.
check("des evenements sont filtres", unitN > 0, true)

print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

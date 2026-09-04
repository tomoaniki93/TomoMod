-- Identite visuelle : garde statique.
--
-- Core/Utils.lua declarait deja U.BRAND sous le commentaire « single source of
-- truth ». Le jeton etait utilise 36 fois, la couleur ecrite en dur 389 fois.
-- Changer l'identite a donc demande de reprendre 505 emplacements au total au
-- lieu de quatre lignes.
--
-- Ce banc empeche la derive de recommencer. Il ne demande pas que tout passe
-- par le jeton -- 162 occurrences vivent dans des chaines traduites et ne le
-- peuvent pas -- mais il exige qu'une seule valeur de marque circule dans le
-- depot. Si quelqu'un reintroduit l'ancien vert, ou invente une troisieme
-- nuance, la suite tombe.
--
-- Usage : luajit Tools/test_brand_identity.lua   (depuis la racine)

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

local function Sources()
    local out = {}
    for _, dir in ipairs({ "Core", "Modules", "Locales", "TomoMod_Options",
                           "TomoMod_AstralForge", "TomoMod_CDStudio",
                           "TomoMod_HealerStudio", "TomoMod_MythicPlus" }) do
        local pipe = io.popen('find "' .. dir .. '" -name "*.lua" 2>/dev/null')
        if pipe then
            for line in pipe:lines() do
                if not line:find("/Libs/") then out[#out + 1] = line end
            end
            pipe:close()
        end
    end
    return out
end

-- ═══════════════════════════════════════════════════════════════════════
print("── 1. Le jeton porte bien l'azur ──")

_G.CreateFrame = function() return setmetatable({}, { __index = function() return function() end end }) end
_G.UIParent    = {}
_G.GetLocale   = function() return "enUS" end
_G.CreateColor = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end
assert(loadfile("Core/Utils.lua"))()
local U = _G.TomoMod_Utils
assert(U, "Utils ne s'est pas charge")

check("BRAND_HEX",  U.BRAND_HEX, "2e9dd8")
check("BRAND rouge", math.floor(U.BRAND[1] * 1000 + 0.5), 180)
check("BRAND vert",  math.floor(U.BRAND[2] * 1000 + 0.5), 616)
check("BRAND bleu",  math.floor(U.BRAND[3] * 1000 + 0.5), 847)

-- Le hex et le triplet doivent decrire la meme couleur : les laisser diverger
-- donne un accent qui change de teinte selon qu'il passe par un code |cff ou
-- par SetColorTexture, et personne ne voit pourquoi.
local function HexToBytes(hex)
    return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end
local hr, hg, hb = HexToBytes(U.BRAND_HEX)
check("hex et triplet concordent (R)", math.floor(U.BRAND[1] * 255 + 0.5), hr)
check("hex et triplet concordent (V)", math.floor(U.BRAND[2] * 255 + 0.5), hg)
check("hex et triplet concordent (B)", math.floor(U.BRAND[3] * 255 + 0.5), hb)

-- Les nuances doivent encadrer la base, sinon survol et enfoncement se
-- confondent avec l'etat normal.
check("HOVER plus clair que BRAND", U.BRAND_HOVER[3] > U.BRAND[3], true)
check("DARK plus sombre que BRAND", U.BRAND_DARK[3]  < U.BRAND[3], true)

-- ═══════════════════════════════════════════════════════════════════════
print("── 2. Aucune trace du vert precedent ──")

local BANNED_HEX = { "2ed884", "2ED884" }
local BANNED_RGB = {
    "0%.18%s*,%s*0%.85%s*,%s*0%.52",
    "0%.180%s*,%s*0%.847%s*,%s*0%.518",
    "0%.05%s*,%s*0%.82%s*,%s*0%.62",
    "0%.047%s*,%s*0%.824%s*,%s*0%.624",
}

local files = Sources()
check("des sources ont ete trouvees", #files > 100, true)

local hexHits, rgbHits = 0, 0
for _, path in ipairs(files) do
    local src = read(path)
    if src then
        for _, h in ipairs(BANNED_HEX) do
            if src:find(h, 1, true) then
                hexHits = hexHits + 1
                fail(("%s contient encore l'ancien hex"):format(path))
                break
            end
        end
        for _, r in ipairs(BANNED_RGB) do
            if src:find(r) then
                rgbHits = rgbHits + 1
                fail(("%s contient encore un triplet menthe"):format(path))
                break
            end
        end
    end
end
check("aucun hex menthe",     hexHits, 0)
check("aucun triplet menthe", rgbHits, 0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 3. Une seule couleur de marque circule ──")

-- Un hex de marque different de U.BRAND_HEX signale une troisieme nuance
-- introduite a la main. On tolere les couleurs d'etat, volontairement
-- inchangees, et le gris.
local ALLOWED = {
    [U.BRAND_HEX] = true,
    ["00ff00"] = true, ["ff0000"] = true, ["ffff00"] = true, ["ffcc00"] = true,
    ["ff4040"] = true, ["ff8800"] = true, ["00ccff"] = true,
    ["888888"] = true, ["aaaaaa"] = true, ["555555"] = true, ["ffffff"] = true,
    ["e4e4e4"] = true, ["cccccc"] = true, ["999999"] = true, ["666666"] = true,
    ["e0115f"] = true, ["c89530"] = true, ["bbbbbb"] = true, ["dddddd"] = true,
    ["777777"] = true, ["444444"] = true, ["333333"] = true, ["222222"] = true,
}
-- Toute couleur proche du vert menthe, quelle que soit sa valeur exacte.
local suspicious = 0
for _, path in ipairs(files) do
    local src = read(path)
    if src then
        for hex in src:gmatch("|c%x%x(%x%x%x%x%x%x)") do
            hex = hex:lower()
            if not ALLOWED[hex] then
                local r = tonumber(hex:sub(1, 2), 16)
                local g = tonumber(hex:sub(3, 4), 16)
                local b = tonumber(hex:sub(5, 6), 16)
                -- Vert domine, bleu moyen : la signature du teal.
                -- Un teal a du bleu en quantite. Les verts purs du
                -- DamageMeter (#40d040, #55ff55) n'en ont presque pas et ne
                -- relevent pas de l'identite de marque.
                if g > 150 and g > r + 60 and b >= 120 and b < g - 40 then
                    suspicious = suspicious + 1
                    fail(("%s : couleur teal residuelle #%s"):format(path, hex))
                end
            end
        end
    end
end
check("aucune teinte teal residuelle", suspicious, 0)

-- ═══════════════════════════════════════════════════════════════════════
print("── 4. La superposition a une seule definition ──")

check("StyleMoverOverlay existe", type(U.StyleMoverOverlay), "function")

local utilsSrc = read("Core/Utils.lua")
check("palette du mover déclarée", utilsSrc:find("U.MOVER_GRAD_TOP", 1, true) ~= nil, true)
-- The inner label plate was removed because it looked like a box inside a box
-- on small movers. MOVER_BAND now supplies the dark label colour instead.
check("aucun bandeau derriere le texte",
      utilsSrc:find("_tmMoverPlate", 1, true), nil)
check("texte sombre sur le degrade",
      utilsSrc:find("text:SetTextColor(band[1], band[2], band[3], 1)", 1, true) ~= nil, true)
-- Le degrade doit etre opaque : la superposition doit masquer ce qui est
-- dessous, c'est la demande explicite.
local alpha = tonumber(utilsSrc:match("CreateColor%(bot%[1%], bot%[2%], bot%[3%], ([%d%.]+)%)"))
check("dégradé opaque", alpha and alpha >= 0.9, true)

-- Les modules migres ne doivent plus peindre leur propre superposition.
local moverBad = 0
for _, spec in ipairs({
    { "Modules/QOL/Compass/Compass.lua",              "dragOverlay"  },
    { "Modules/QOL/Classes/ClassReminder.lua",        "dragOverlay"  },
    { "Modules/QOL/Quest/ObjectiveTracker.lua",       "moverOverlay" },
    { "Modules/Interface/UnitFrames/Units/BossFrames.lua", "dragFrame" },
    { "Modules/QOL/Consumables/ConsumableBar.lua",    "dragOverlay" },
    { "Modules/QOL/CooldownManager/CDMHolders.lua",   "o" },
    { "Modules/QOL/FrameAnchors/FrameAnchors.lua",    "anchor" },
    { "Modules/QOL/Minimap/Minimap.lua",              "moverOverlay" },
    { "Modules/Interface/Castbars/Castbar.lua",       "dragFrame" },
    { "Modules/Interface/ActionBars/TotemBarMover.lua", "overlay" },
}) do
    local src = read(spec[1])
    if src then
        if src:find(spec[2] .. ":SetBackdropColor", 1, true) then
            moverBad = moverBad + 1
            fail(("%s peint encore sa superposition"):format(spec[1]))
        end
        if not src:find("StyleMoverOverlay", 1, true) then
            moverBad = moverBad + 1
            fail(("%s n'appelle pas la fabrique de style"):format(spec[1]))
        end
    end
end
check("modules migrés conformes", moverBad, 0)

-- Migrated modules must reuse the common label instead of drawing another one
-- over it, which made the text unreadable in game.
local dupLabel = 0
for _, spec in ipairs({
    { "Modules/Interface/UnitFrames/Units/BossFrames.lua", "dragLabel = dragFrame:CreateFontString" },
    { "Modules/QOL/Classes/ClassReminder.lua",             "dragLabel = dragOverlay:CreateFontString" },
    { "Modules/QOL/Consumables/ConsumableBar.lua",         "dragLabel = dragOverlay:CreateFontString" },
    { "Modules/QOL/Quest/ObjectiveTracker.lua",            "drag to move" },
    { "Modules/QOL/Compass/Compass.lua",                    "dragLabel = dragOverlay:CreateFontString" },
    { "Modules/QOL/CooldownManager/CDMHolders.lua",         "local label = o:CreateFontString" },
    { "Modules/QOL/FrameAnchors/FrameAnchors.lua",          "local label = anchor:CreateFontString" },
    { "Modules/QOL/Minimap/Minimap.lua",                    "local label = moverOverlay:CreateFontString" },
    { "Modules/Interface/Castbars/Castbar.lua",             "local dragLabel = dragFrame:CreateFontString" },
    { "Modules/Interface/ActionBars/TotemBarMover.lua",     "local label = overlay:CreateFontString" },
}) do
    local src = read(spec[1])
    if src and src:find(spec[2], 1, true) then
        dupLabel = dupLabel + 1
        fail(("%s cree encore son propre libelle"):format(spec[1]))
    end
end
check("aucun libellé en double", dupLabel, 0)

print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)

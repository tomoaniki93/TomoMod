-- =====================================================================
-- Panels/Frames.lua -- "Mes cadres" : unit frames, castbars, resources
-- Replaces the Astral Forge and Resource & Cast Studios. Every control is
-- applied to the live frames as it moves; the page header pulses the real
-- frame so the player always knows what the page is talking about.
-- =====================================================================

local K = TomoMod_Kit
local T = K.T

local SECTION = "frames"

-- ---------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------
local function UF(unit) return "unitFrames." .. unit .. "." end

-- Auras "both" and the enemy-buff strip would draw the same buffs twice;
-- the old studio enforced this, the page keeps doing it.
local function EnforceAuraExclusivity(unit)
    local s = TomoModDB.unitFrames[unit]
    if type(s) ~= "table" or type(s.auras) ~= "table" or type(s.enemyBuffs) ~= "table" then return end
    if s.auras.enabled ~= false and s.auras.type == "ALL" then
        s.enemyBuffs.enabled = false
    end
end

-- Element anchor presets: plain words instead of anchor points.
local NAME_POS = {
    left  = { point = "LEFT",       relTo = "health", relPoint = "LEFT",    x = 6,  y = 0 },
    center= { point = "CENTER",     relTo = "health", relPoint = "CENTER",  x = 0,  y = 0 },
    above = { point = "BOTTOMLEFT", relTo = "health", relPoint = "TOPLEFT", x = 2,  y = 3 },
}
local HP_POS = {
    right  = { point = "RIGHT",  relTo = "health", relPoint = "RIGHT",  x = -6, y = 0 },
    center = { point = "CENTER", relTo = "health", relPoint = "CENTER", x = 0,  y = 0 },
    left   = { point = "LEFT",   relTo = "health", relPoint = "LEFT",   x = 6,  y = 0 },
}

local function ElementBinding(unit, id, presets)
    return {
        get = function()
            local s = TomoModDB.unitFrames[unit]
            local e = s and s.elements and s.elements[id]
            if type(e) ~= "table" then return nil end
            for key, p in pairs(presets) do
                if e.point == p.point and e.relPoint == p.relPoint and (e.relTo or "health") == p.relTo then
                    return key
                end
            end
            return nil
        end,
        set = function(key)
            local p = presets[key]
            local s = TomoModDB.unitFrames[unit]
            if not (p and s) then return end
            s.elements = s.elements or {}
            local e = s.elements[id]
            if type(e) ~= "table" then e = {}; s.elements[id] = e end
            e.point, e.relTo, e.relPoint, e.x, e.y = p.point, p.relTo, p.relPoint, p.x, p.y
        end,
    }
end

local function ReloadToggle(c, label, path, tip)
    return c:Toggle(label, path, K.NeedReload, tip)
end

-- ---------------------------------------------------------------------
-- One page per unit frame
-- ---------------------------------------------------------------------
local UNITS = {
    { key = "player",       fr = "Joueur",           en = "Player",
      descFr = "Ton propre cadre : vie, ressource (mana, énergie, rage) et barre d'infos.",
      descEn = "Your own frame: health, resource (mana, energy, rage) and info bar." },
    { key = "target",       fr = "Cible",            en = "Target",
      descFr = "Le cadre de ce que tu cibles. Cible quelqu'un pour le voir changer en direct.",
      descEn = "The frame of what you target. Target something to see it change live." },
    { key = "targettarget", fr = "Cible de la cible", en = "Target of target",
      descFr = "Petit cadre qui montre qui ta cible regarde.",
      descEn = "Small frame showing who your target is looking at." },
    { key = "focus",        fr = "Focalisation",     en = "Focus",
      descFr = "Cadre de ta cible de focalisation (/focus).",
      descEn = "Frame of your focus target (/focus)." },
    { key = "pet",          fr = "Familier",         en = "Pet",
      descFr = "Le cadre de ton familier ou de ta créature invoquée.",
      descEn = "Your pet or summoned creature frame." },
}

local function BuildUnitPage(page, u)
    local unit = u.key
    local p = UF(unit)
    local ap = "uf:" .. unit
    local s = TomoModDB.unitFrames[unit]
    local title = T(u.fr, u.en)

    page:Hero(title, T(u.descFr, u.descEn), "TomoMod_UF_" .. unit, title)
    page:UFPreview(unit)

    if not TomoModDB.unitFrames.enabled then
        local c = page:Card(T("Module désactivé", "Module disabled"))
        c:Info(T("Les cadres d'unité TomoMod sont désactivés. Active-les depuis l'Accueil.",
                 "TomoMod unit frames are turned off. Turn them on from Home."))
        c:Done()
    end

    -- ---- Size ---------------------------------------------------------
    local c = page:Card(T("Taille", "Size"))
    c:Slider(T("Largeur", "Width"), p .. "width", 60, 500, 1, ap)
    c:Slider(T("Hauteur de la barre de vie", "Health bar height"), p .. "healthHeight", 8, 80, 1, ap)
    if unit == "player" then
        c:Slider(T("Hauteur de la barre de mana / énergie", "Mana / energy bar height"), p .. "powerHeight", 0, 30, 1, ap, nil,
            T("0 = pas de barre. Si ta ressource est affichée au centre de l'écran, cette barre n'apparaît pas (voir plus bas).",
              "0 = no bar. If your resource is shown in the middle of the screen, this bar is not drawn (see below)."))
    else
        c:Slider(T("Hauteur de la barre de ressource", "Resource bar height"), p .. "powerHeight", 0, 30, 1, ap, nil,
            T("0 = pas de barre de ressource.", "0 = no resource bar."))
    end
    if s.infoBarHeight ~= nil then
        c:Slider(T("Hauteur de la barre d'infos", "Info bar height"), p .. "infoBarHeight", 0, 30, 1, ap, nil,
            T("Bande sous le cadre avec la vie et la ressource en texte. 0 = masquée.",
              "Strip under the frame with health and resource as text. 0 = hidden."))
    end
    c:Done()

    -- ---- Player: where is my mana? ---------------------------------------
    if unit == "player" then
        local c2 = page:Card(T("Où afficher ma ressource ?", "Where should my resource go?"))
        if K.IsModuleOn("resourceBars") then
            c2:Seg(nil, {
                get = function()
                    return TomoModDB.resourceBars.primaryPowerCentered and "center" or "frame"
                end,
                set = function(v) TomoModDB.resourceBars.primaryPowerCentered = (v == "center") end,
            }, {
                { text = T("Dans le cadre joueur", "In the player frame"), value = "frame" },
                { text = T("Au centre de l'écran", "Middle of the screen"), value = "center" },
            }, "res", 2)
            c2:Info(T("« Dans le cadre » utilise la hauteur réglée ci-dessus. « Au centre » se règle dans Ressources.",
                      "\"In the frame\" uses the height set above. \"Middle\" is set up in Resources."))
        else
            c2:Info(T("Les barres de ressources centrées sont désactivées : ta ressource est dans le cadre joueur.",
                      "Centered resource bars are off: your resource is in the player frame."))
        end
        c2:Done()
    end

    -- ---- Texts ------------------------------------------------------------
    c = page:Card(T("Textes", "Texts"))
    c:Pair(function(l) l:Toggle(T("Nom", "Name"), p .. "showName", ap) end,
           function(r) r:Toggle(T("Niveau", "Level"), p .. "showLevel", ap) end)
    c:Pair(function(l) l:Toggle(T("Vie en texte", "Health text"), p .. "showHealthText", ap) end,
           function(r) if s.showPowerText ~= nil then r:Toggle(T("Ressource en texte", "Resource text"), p .. "showPowerText", ap, T("Écrit sur la barre de ressource quand la barre d'infos est à 0.", "Written on the resource bar when the info bar is set to 0.")) end end)
    c:Select(T("Format de la vie", "Health format"), p .. "healthTextFormat", K.HP_FORMATS, ap)
    if s.nameTruncate ~= nil then
        c:Toggle(T("Raccourcir les noms longs", "Shorten long names"), p .. "nameTruncate", ap)
        c:Slider(T("Longueur maximale du nom", "Max name length"), p .. "nameTruncateLength", 4, 30, 1, ap)
    end
    c:Done()

    -- ---- Colours ----------------------------------------------------------
    c = page:Card(T("Couleurs", "Colours"))
    c:Toggle(T("Couleur de classe pour les joueurs", "Class colour for players"), p .. "useClassColor", ap)
    c:Toggle(T("Couleur de réaction (hostile, neutre, amical)", "Reaction colour (hostile, neutral, friendly)"), p .. "useFactionColor", ap)
    if s.useNameplateColors ~= nil then
        c:Toggle(T("Mêmes couleurs que les plaques de nom", "Same colours as nameplates"), p .. "useNameplateColors", ap,
            T("Lanceurs de sorts en bleu, élites en violet, etc.", "Casters blue, elites purple, etc."))
    end
    c:Done()

    if unit == "player" then
        c = page:Card(T("Alerte vie basse", "Low health alert"))
        c:Toggle(T("Le cadre pulse en rouge quand ta vie est basse", "The frame pulses red when your health is low"), "unitFrames.lowHealthPulse", ap)
        c:Slider(T("Seuil", "Threshold"), "unitFrames.lowHealthPct", 10, 60, 1, ap, "%d %%")
        c:Done()
    end

    -- ---- Indicators -------------------------------------------------------
    c = page:Card(T("Indicateurs", "Indicators"))
    c:Pair(function(l) l:Toggle(T("Boucliers (absorption)", "Shields (absorb)"), p .. "showAbsorb", ap) end,
           function(r) r:Toggle(T("Menace", "Threat"), p .. "showThreat", ap) end)
    if s.showLeaderIcon ~= nil or s.showRaidIcon ~= nil then
        c:Pair(function(l) if s.showLeaderIcon ~= nil then l:Toggle(T("Icône de chef", "Leader icon"), p .. "showLeaderIcon", ap) end end,
               function(r) if s.showRaidIcon ~= nil then r:Toggle(T("Marque de raid", "Raid marker"), p .. "showRaidIcon", ap) end end)
    end
    if s.showHappiness ~= nil then
        c:Toggle(T("Humeur du familier (chasseur)", "Pet happiness (hunter)"), p .. "showHappiness", ap,
            T("Heureux, content ou malheureux. Survole l'icône pour voir son régime.", "Happy, content or unhappy. Hover the icon to see its diet."))
    end
    if s.showQuestIcon ~= nil then
        c:Toggle(T("Icône de quête", "Quest icon"), p .. "showQuestIcon", ap)
    end
    if type(s.threatText) == "table" then
        c:Toggle(T("Pourcentage de menace en texte", "Threat percentage text"), p .. "threatText.enabled", ap)
    end
    c:Done()

    -- ---- Auras --------------------------------------------------------------
    if type(s.auras) == "table" then
        c = page:Card(T("Buffs et débuffs", "Buffs and debuffs"))
        c:Toggle(T("Afficher les auras", "Show auras"), p .. "auras.enabled", ap, nil, function() EnforceAuraExclusivity(unit) end)
        c:Seg(T("Lesquelles ?", "Which ones?"), {
            get = function() return s.auras.type end,
            set = function(v) s.auras.type = v; EnforceAuraExclusivity(unit) end,
        }, {
            { text = T("Débuffs", "Debuffs"), value = "HARMFUL" },
            { text = T("Buffs", "Buffs"),     value = "HELPFUL" },
            { text = T("Les deux", "Both"),   value = "ALL" },
        }, ap, 3)
        c:Pair(function(l) l:Slider(T("Nombre", "Count"), p .. "auras.maxAuras", 1, 12, 1, ap) end,
               function(r) r:Slider(T("Taille", "Size"), p .. "auras.size", 12, 50, 1, ap) end)
        c:Pair(function(l) l:Slider(T("Par ligne", "Per row"), p .. "auras.perRow", 1, 12, 1, ap) end,
               function(r) r:Slider(T("Espacement", "Spacing"), p .. "auras.spacing", 0, 10, 1, ap) end)
        c:Pair(function(l) l:Toggle(T("Seulement les miennes", "Only mine"), p .. "auras.showOnlyMine", ap) end,
               function(r) r:Toggle(T("Durée restante", "Time left"), p .. "auras.showDuration", ap) end)
        c:Seg(T("Sens de remplissage", "Growth direction"), p .. "auras.growDirection", {
            { text = T("Vers la gauche", "Leftwards"),  value = "LEFT" },
            { text = T("Vers la droite", "Rightwards"), value = "RIGHT" },
        }, ap, 2)
        c:Done()
    end

    if type(s.enemyBuffs) == "table" then
        c = page:Card(T("Buffs des ennemis", "Enemy buffs"), { adv = true })
        c:Info(T("Montre les buffs à dissiper ou voler sur un ennemi. Désactivé si les auras affichent déjà « Les deux ».",
                 "Shows buffs you can dispel or steal on an enemy. Off when auras already show \"Both\"."))
        c:Toggle(T("Activer", "Enable"), p .. "enemyBuffs.enabled", ap, nil, function() EnforceAuraExclusivity(unit) end)
        c:Pair(function(l) l:Slider(T("Nombre", "Count"), p .. "enemyBuffs.maxAuras", 1, 8, 1, ap) end,
               function(r) r:Slider(T("Taille", "Size"), p .. "enemyBuffs.size", 12, 40, 1, ap) end)
        c:Done()
    end

    -- ---- Blizzard's own buff / debuff frames (top-right of the screen) -------
    if unit == "player" then
        c = page:Card(T("Cadres d'auras Blizzard", "Blizzard aura frames"))
        c:Info(T("Les buffs et débuffs Blizzard en haut à droite de l'écran. N'affecte pas les auras des cadres TomoMod.",
                 "Blizzard's buffs and debuffs at the top right of the screen. Does not affect TomoMod frame auras."))
        c:Toggle(T("Laisser TomoMod gérer ces cadres", "Let TomoMod manage these frames"), "blizzardAuraFrames.enabled", "baf")
        c:Pair(function(l) l:Toggle(T("Buffs Blizzard", "Blizzard buffs"), "blizzardAuraFrames.showBuffs", "baf") end,
               function(r) r:Toggle(T("Débuffs Blizzard", "Blizzard debuffs"), "blizzardAuraFrames.showDebuffs", "baf") end)
        c:Done()
    end

    -- ---- Text placement (expert) -------------------------------------------
    c = page:Card(T("Position des textes", "Text placement"), { adv = true })
    c:Seg(T("Nom", "Name"), ElementBinding(unit, "name", NAME_POS), {
        { text = T("À gauche", "Left"),     value = "left" },
        { text = T("Au centre", "Center"),  value = "center" },
        { text = T("Au-dessus", "Above"),   value = "above" },
    }, ap, 3)
    c:Seg(T("Vie", "Health"), ElementBinding(unit, "healthText", HP_POS), {
        { text = T("À gauche", "Left"),     value = "left" },
        { text = T("Au centre", "Center"),  value = "center" },
        { text = T("À droite", "Right"),    value = "right" },
    }, ap, 3)
    c:Done()

    -- ---- On / off -----------------------------------------------------------
    c = page:Card(T("Cadre", "Frame"), { adv = true })
    ReloadToggle(c, T("Afficher ce cadre", "Show this frame"), p .. "enabled",
        T("Les cadres sont créés au chargement : demande un /rl.", "Frames are created at load: needs a /rl."))
    c:Info(T("Pour le déplacer : bouton « Déplacer » en haut de la fenêtre.",
             "To move it: \"Move\" button at the top of the window."))
    c:Done()

    page:StudioLink("astral", unit, "Astral Forge Studio")
end

for i, u in ipairs(UNITS) do
    K.RegisterPage({
        key = "uf_" .. u.key,
        section = SECTION,
        label = T(u.fr, u.en),
        kw = "unit frame cadre unite " .. u.key .. " " .. u.fr .. " " .. u.en
            .. (u.key == "player" and " mana energie energy rage ressource power moi" or ""),
        locate = "TomoMod_UF_" .. u.key,
        build = function(parent)
            return K.Page(parent, function(page) BuildUnitPage(page, u) end)
        end,
    })
end

-- ---------------------------------------------------------------------
-- Boss frames
-- ---------------------------------------------------------------------
K.RegisterPage({
    key = "uf_boss",
    section = SECTION,
    label = T("Boss", "Boss"),
    kw = "boss frames cadres boss rencontre encounter",
    locate = "TomoMod_Boss_1",
    build = function(parent)
        return K.Page(parent, function(page)
            page:Hero(T("Cadres de boss", "Boss frames"),
                T("Apparaissent pendant les rencontres de boss. Utilise « Déplacer » pour les voir hors combat.",
                  "Shown during boss encounters. Use \"Move\" to see them outside a fight."),
                "TomoMod_Boss_1", T("Boss", "Boss"))
            local c = page:Card(T("Taille", "Size"))
            c:Slider(T("Largeur", "Width"), "unitFrames.bossFrames.width", 80, 400, 1, "boss")
            c:Slider(T("Hauteur", "Height"), "unitFrames.bossFrames.height", 12, 60, 1, "boss")
            c:Slider(T("Espace entre les cadres", "Space between frames"), "unitFrames.bossFrames.spacing", 0, 30, 1, "boss")
            c:Done()
            c = page:Card(T("Cadre", "Frame"), { adv = true })
            ReloadToggle(c, T("Utiliser les cadres de boss TomoMod", "Use TomoMod boss frames"), "unitFrames.bossFrames.enabled")
            c:Done()
            page:StudioLink("astral", "bossframe", "Astral Forge Studio")
        end)
    end,
})

-- ---------------------------------------------------------------------
-- Shared look of every unit frame
-- ---------------------------------------------------------------------
K.RegisterPage({
    key = "uf_style",
    section = SECTION,
    label = T("Style commun", "Shared style"),
    kw = "texture police font taille contour style unit frames cadres apparence",
    locate = "TomoMod_UF_player",
    build = function(parent)
        return K.Page(parent, function(page)
            page:Hero(T("Style commun des cadres", "Shared frame style"),
                T("Texture et police utilisées par tous les cadres d'unité.", "Texture and font used by every unit frame."),
                "TomoMod_UF_player", T("Joueur", "Player"))
            local c = page:Card(T("Apparence", "Look"))
            c:Select(T("Texture des barres", "Bar texture"), "unitFrames.texture", K.TEXTURES, "ufall")
            c:Select(T("Police", "Font"), {
                get = function() return TomoModDB.unitFrames.fontFamily or TomoModDB.unitFrames.font end,
                set = function(v) TomoModDB.unitFrames.fontFamily = v; TomoModDB.unitFrames.font = v end,
            }, K.FONTS, "ufall")
            c:Slider(T("Taille du texte", "Text size"), "unitFrames.fontSize", 8, 22, 1, "ufall")
            c:Seg(T("Contour du texte", "Text outline"), "unitFrames.fontOutline", K.OUTLINES, "ufall", 3)
            c:Done()
            c = page:Card(T("Animations", "Animations"))
            c:Toggle(T("Traînée rouge quand un cadre perd de la vie", "Red trail when a frame loses health"), "unitFrames.healthTrail", "ufall",
                T("Le morceau de vie perdu reste affiché en rouge un instant puis s'écoule.", "The lost chunk of health stays red for a moment, then drains away."))
            c:Toggle(T("Cadre joueur qui pulse en rouge quand ta vie est basse", "Player frame pulses red on low health"), "unitFrames.lowHealthPulse", "uf:player")
            c:Slider(T("Seuil de vie basse", "Low health threshold"), "unitFrames.lowHealthPct", 10, 60, 1, "uf:player", "%d %%")
            c:Done()

            c = page:Card(T("Cadres Blizzard", "Blizzard frames"), { adv = true })
            ReloadToggle(c, T("Masquer les cadres Blizzard d'origine", "Hide the default Blizzard frames"), "unitFrames.hideBlizzardFrames")
            c:Done()
        end)
    end,
})

-- ---------------------------------------------------------------------
-- Castbars
-- ---------------------------------------------------------------------
local CAST_UNITS = {
    { key = "player", fr = "Joueur", en = "Player" },
    { key = "target", fr = "Cible",  en = "Target" },
    { key = "focus",  fr = "Focalisation", en = "Focus", adv = true },
    { key = "pet",    fr = "Familier", en = "Pet", adv = true },
    { key = "boss",   fr = "Boss", en = "Boss", adv = true },
}

K.RegisterPage({
    key = "castbar",
    section = SECTION,
    label = T("Barres d'incantation", "Castbars"),
    kw = "castbar cast incantation sort lancement barre gcd interrupt interruption",
    locate = "TomoMod_Castbar_player",
    onShow = function() K.CastPreview(true) end,
    onHide = function() K.CastPreview(false) end,
    build = function(parent)
        return K.Page(parent, function(page)
            page:Hero(T("Barres d'incantation", "Castbars"),
                T("Un aperçu reste affiché tant que cette page est ouverte, pour régler sans lancer de sort.",
                  "A preview stays on screen while this page is open, so you can tune it without casting."),
                "TomoMod_Castbar_player", T("Incantation", "Castbar"))

            local c = page:Card(T("Apparence", "Look"))
            c:Seg(T("Texture", "Texture"), "castbars.barTexture", {
                { text = "Blizzard", value = "blizzard" },
                { text = T("Lisse", "Smooth"), value = "smooth" },
                { text = T("Plat", "Flat"), value = "flat" },
            }, "cast", 3)
            c:Select(T("Police", "Font"), "castbars.font", K.FONTS, "cast")
            c:Slider(T("Taille du texte", "Text size"), "castbars.fontSize", 8, 20, 1, "cast")
            c:Toggle(T("Couleur de ma classe", "My class colour"), "castbars.useClassColor", "cast")
            c:Pair(function(l) l:Color(T("Interruptible", "Interruptible"), "castbars.castbarColor", "cast") end,
                   function(r) r:Color(T("Non interruptible", "Uninterruptible"), "castbars.castbarNIColor", "cast") end)
            c:Done()

            c = page:Card(T("Effets", "Effects"))
            c:Pair(function(l) l:Toggle(T("Étincelle", "Spark"), "castbars.showSpark", "cast") end,
                   function(r) r:Toggle(T("Ticks des canalisations", "Channel ticks"), "castbars.showChannelTicks", "cast") end)
            c:Toggle(T("Message « Interrompu ! »", "\"Interrupted!\" message"), "castbars.showInterruptFeedback", "cast")
            c:Toggle(T("La barre tremble quand un sort est interrompu", "The bar shakes when a cast is interrupted"), "castbars.interruptShake", "cast")
            if not K.Absent("castbars.interruptShake") then
                c:Button(T("Tester la secousse", "Test the shake"), function()
                    local cb = TomoMod_Castbar and TomoMod_Castbar.castbars and TomoMod_Castbar.castbars.player
                    if cb and TomoMod_Utils.Shake then TomoMod_Utils.Shake(cb, 5, 0.3) end
                end, 180)
            end
            c:Seg(T("Chronomètre", "Timer"), "castbars.timerFormat", {
                { text = T("Restant", "Remaining"), value = "remaining" },
                { text = T("Restant / total", "Left / total"), value = "remaining_total" },
                { text = T("Écoulé", "Elapsed"), value = "elapsed" },
            }, "cast", 3)
            c:Done()

            c = page:Card(T("Effets avancés", "Advanced effects"), { adv = true })
            c:Select(T("Style d'étincelle", "Spark style"), "castbars.sparkStyle", {
                { text = "Comet", value = "Comet" }, { text = "Pulse", value = "Pulse" },
                { text = "Helix", value = "Helix" }, { text = "Glitch", value = "Glitch" },
            }, "cast")
            c:Toggle(T("Barre de temps global (GCD)", "Global cooldown bar (GCD)"), "castbars.showGCDSpark", "cast")
            c:Slider(T("Hauteur du GCD", "GCD height"), "castbars.gcdHeight", 1, 12, 1, "cast")
            c:Done()

            for _, u in ipairs(CAST_UNITS) do
                local p = "castbars." .. u.key .. "."
                c = page:Card(T(u.fr, u.en), { adv = u.adv })
                c:Toggle(T("Activer", "Enable"), p .. "enabled", "cast")
                c:Pair(function(l) l:Slider(T("Largeur", "Width"), p .. "width", 60, 500, 1, "cast") end,
                       function(r) r:Slider(T("Hauteur", "Height"), p .. "height", 6, 40, 1, "cast") end)
                c:Pair(function(l) l:Toggle(T("Icône du sort", "Spell icon"), p .. "showIcon", "cast") end,
                       function(r) r:Toggle(T("Chronomètre", "Timer"), p .. "showTimer", "cast") end)
                if u.key == "player" then
                    c:Toggle(T("Latence (zone rouge)", "Latency (red zone)"), p .. "showLatency", "cast")
                else
                    c:Toggle(T("Coller sous le cadre d'unité", "Stick under the unit frame"), p .. "anchorToUnitFrame", "cast")
                end
                c:Done()
            end
            page:StudioLink("resourcecast", "cast", "Resource & Cast Studio")
        end)
    end,
})

-- ---------------------------------------------------------------------
-- Resources (centered HUD)
-- ---------------------------------------------------------------------
K.RegisterPage({
    key = "resources",
    section = SECTION,
    label = T("Ressources", "Resources"),
    kw = "resource ressources mana energie energy rage combo points runes hud barre centree",
    locate = "TomoMod_ResourceBars_Container",
    build = function(parent)
        return K.Page(parent, function(page)
            page:Hero(T("Ressources au centre de l'écran", "Resources in the middle of the screen"),
                T("Mana, énergie, rage, points de combo... juste sous ton personnage.",
                  "Mana, energy, rage, combo points... right under your character."),
                "TomoMod_ResourceBars_Container", T("Ressources", "Resources"))

            local c = page:Card(T("Activation", "On / off"))
            c:Toggle(T("Activer les barres de ressources", "Enable resource bars"), {
                get = function() return K.IsModuleOn("resourceBars") end,
                set = function(v) K.SetModule("resourceBars", v) end,
            }, "res")
            c:Toggle(T("Afficher la mana / énergie au centre", "Show mana / energy in the middle"), "resourceBars.primaryPowerCentered", "res",
                T("Sinon elle reste dans le cadre joueur.", "Otherwise it stays in the player frame."))
            c:Done()

            c = page:Card(T("Taille", "Size"))
            c:Slider(T("Largeur", "Width"), "resourceBars.width", 80, 500, 1, "res")
            c:Slider(T("Hauteur de la mana / énergie", "Mana / energy height"), "resourceBars.primaryPowerBarHeight", 4, 40, 1, "res")
            c:Slider(T("Hauteur des points (combo, runes...)", "Points height (combo, runes...)"), "resourceBars.primaryHeight", 4, 40, 1, "res")
            c:Slider(T("Échelle", "Scale"), "resourceBars.scale", 0.5, 2, 0.05, "res")
            c:Done()

            c = page:Card(T("Quand les afficher ?", "When to show them?"))
            c:Seg(nil, "resourceBars.visibilityMode", {
                { text = T("Toujours", "Always"),         value = "always" },
                { text = T("En combat", "In combat"),     value = "combat" },
                { text = T("Combat ou cible", "Combat or target"), value = "target" },
                { text = T("Jamais", "Never"),            value = "hidden" },
            }, "res", 2)
            c:Slider(T("Opacité hors combat", "Out of combat opacity"), "resourceBars.oocAlpha", 0, 1, 0.05, "res", "%.2f")
            c:Done()

            c = page:Card(T("Textes", "Texts"))
            c:Toggle(T("Valeur en texte", "Value as text"), "resourceBars.showText", "res")
            c:Slider(T("Taille du texte", "Text size"), "resourceBars.fontSize", 8, 20, 1, "res")
            c:Done()

            c = page:Card(T("Avancé", "Advanced"), { adv = true })
            c:Seg(T("Style", "Style"), "resourceBars.displayMode", {
                { text = T("Barres", "Bars"), value = "bars" },
                { text = T("Icônes", "Icons"), value = "icons" },
            }, "res", 2)
            c:Toggle(T("Barres fluides", "Smooth bars"), "resourceBars.smoothBars", "res")
            c:Toggle(T("Lueur quand la ressource est pleine", "Glow when the resource is full"), "resourceBars.showFullResourceGlow", "res")
            c:Toggle(T("Barre de vie centrée", "Centered health bar"), "resourceBars.healthBarEnabled", "res")
            c:Slider(T("Hauteur de la barre de vie", "Health bar height"), "resourceBars.healthBarHeight", 4, 30, 1, "res")
            c:Color(T("Couleur de la mana", "Mana colour"), "resourceBars.colors.mana", "res")
            c:Done()
            page:StudioLink("resourcecast", "resources", "Resource & Cast Studio")
        end)
    end,
})

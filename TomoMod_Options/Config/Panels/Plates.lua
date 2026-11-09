-- =====================================================================
-- Panels/Plates.lua -- nameplates (was the nameplate half of Astral Forge)
-- =====================================================================

local K = TomoMod_Kit
local T = K.T

local function TargetPlate()
    if C_NamePlate and C_NamePlate.GetNamePlateForUnit then
        return C_NamePlate.GetNamePlateForUnit("target")
    end
end

K.RegisterPage({
    key = "nameplates",
    section = "combat",
    label = T("Plaques de nom", "Nameplates"),
    kw = "nameplates plaques nom ennemis enemies tank menace threat castbar plates",
    locate = TargetPlate,
    build = function(parent)
        return K.Page(parent, function(page)
            page:Hero(T("Plaques de nom", "Nameplates"),
                T("Les barres au-dessus des ennemis. Cible un monstre pour voir les changements sur sa plaque.",
                  "The bars above enemies. Target a monster to see the changes on its plate."),
                TargetPlate, T("Plaque de ta cible", "Your target's plate"))

            local c = page:Card(T("Activation", "On / off"))
            c:Toggle(T("Utiliser les plaques TomoMod", "Use TomoMod nameplates"), {
                get = function() return K.IsModuleOn("nameplates") end,
                set = function(v) K.SetModule("nameplates", v) end,
            }, "np")
            c:Done()

            c = page:Card(T("Taille", "Size"))
            c:Pair(function(l) l:Slider(T("Largeur", "Width"), "nameplates.width", 60, 300, 1, "np") end,
                   function(r) r:Slider(T("Hauteur", "Height"), "nameplates.height", 4, 40, 1, "np") end)
            c:Pair(function(l) l:Slider(T("Opacité (cible)", "Opacity (target)"), "nameplates.selectedAlpha", 0.2, 1, 0.05, "np", "%.2f") end,
                   function(r) r:Slider(T("Opacité (autres)", "Opacity (others)"), "nameplates.unselectedAlpha", 0.1, 1, 0.05, "np", "%.2f") end)
            c:Done()

            c = page:Card(T("Textes", "Texts"))
            c:Pair(function(l) l:Toggle(T("Nom", "Name"), "nameplates.showName", "np") end,
                   function(r) r:Toggle(T("Niveau", "Level"), "nameplates.showLevel", "np") end)
            c:Pair(function(l) l:Toggle(T("Vie en texte", "Health text"), "nameplates.showHealthText", "np") end,
                   function(r) r:Toggle(T("Élite / rare", "Elite / rare"), "nameplates.showClassification", "np") end)
            c:Select(T("Format de la vie", "Health format"), "nameplates.healthTextFormat", K.HP_FORMATS, "np")
            c:Pair(function(l) l:Slider(T("Taille du nom", "Name size"), "nameplates.nameFontSize", 6, 20, 1, "np") end,
                   function(r) r:Slider(T("Taille de la vie", "Health size"), "nameplates.fontSize", 6, 20, 1, "np") end)
            c:Done()

            c = page:Card(T("Flèches de la cible", "Target arrows"))
            c:Toggle(T("Flèches de chaque côté de la cible", "Arrows on each side of the target"), "nameplates.targetArrows", "np")
            c:Seg(T("Style", "Style"), "nameplates.targetArrowStyle", {
                { text = T("Classique", "Classic"),       value = "classic" },
                { text = T("Chevron", "Chevron"),         value = "chevron" },
                { text = T("Triangle", "Triangle"),       value = "triangle" },
                { text = T("Double", "Double"),           value = "double" },
                { text = T("Lumineuse", "Glowing"),       value = "glow" },
            }, "np", 3)
            c:Pair(function(l) l:Slider(T("Taille", "Size"), "nameplates.targetArrowScale", 0.5, 2.5, 0.05, "np", "%.2f") end,
                   function(r) r:Slider(T("Écart", "Gap"), "nameplates.targetArrowOffset", -10, 30, 1, "np") end)
            c:Pair(function(l) l:Seg(T("Autour de", "Around"), "nameplates.targetArrowAnchor", {
                        { text = T("Nom", "Name"),   value = "name" },
                        { text = T("Barre", "Bar"),  value = "health" },
                    }, "np", 2) end,
                   function(r) r:Color(T("Couleur", "Colour"), "nameplates.targetArrowColor", "np") end)
            c:Done()

            c = page:Card(T("Couleurs", "Colours"))
            c:Toggle(T("Couleur de classe pour les joueurs", "Class colour for players"), "nameplates.useClassColors", "np")
            c:Toggle(T("Couleur selon le type (lanceur, élite...)", "Colour by type (caster, elite...)"), "nameplates.useClassificationColors", "np")
            c:Pair(function(l) l:Color(T("Hostile", "Hostile"), "nameplates.colors.hostile", "np") end,
                   function(r) r:Color(T("Neutre", "Neutral"), "nameplates.colors.neutral", "np") end)
            c:Pair(function(l) l:Color(T("Lanceur de sorts", "Caster"), "nameplates.colors.caster", "np") end,
                   function(r) r:Color(T("Élite", "Elite"), "nameplates.colors.miniboss", "np") end)
            c:Done()

            c = page:Card(T("Menace", "Threat"))
            c:Toggle(T("Afficher la menace", "Show threat"), "nameplates.showThreat", "np")
            c:Toggle(T("Mode tank (couleurs selon qui a l'aggro)", "Tank mode (colours by who has aggro)"), "nameplates.tankMode", "np",
                T("Vert : tu tiens le monstre. Rouge : il t'échappe.", "Green: you hold the monster. Red: you lost it."))
            c:Done()

            c = page:Card(T("Incantations", "Casts"))
            c:Toggle(T("Barre d'incantation sous la plaque", "Castbar under the plate"), "nameplates.showCastbar", "np")
            c:Slider(T("Hauteur", "Height"), "nameplates.castbarHeight", 4, 30, 1, "np")
            c:Pair(function(l) l:Color(T("Interruptible", "Interruptible"), "nameplates.castbarColor", "np") end,
                   function(r) r:Color(T("Non interruptible", "Uninterruptible"), "nameplates.castbarUninterruptible", "np") end)
            c:Done()

            c = page:Card(T("Auras", "Auras"))
            c:Pair(function(l) l:Toggle(T("Mes débuffs", "My debuffs"), "nameplates.showAuras", "np") end,
                   function(r) r:Toggle(T("Seulement les miens", "Only mine"), "nameplates.showOnlyMyAuras", "np") end)
            c:Pair(function(l) l:Slider(T("Nombre", "Count"), "nameplates.maxAuras", 1, 10, 1, "np") end,
                   function(r) r:Slider(T("Taille", "Size"), "nameplates.auraSize", 10, 40, 1, "np") end)
            c:Toggle(T("Buffs des ennemis (à dissiper)", "Enemy buffs (dispellable)"), "nameplates.showEnemyBuffs", "np")
            c:Done()

            c = page:Card(T("Alliés", "Friendly units"), { adv = true })
            c:Toggle(T("Plaques des alliés", "Friendly plates"), "nameplates.friendlyPlates", "np")
            c:Toggle(T("Alliés : nom seulement", "Friendly: name only"), "nameplates.friendlyNameOnly", "np")
            c:Toggle(T("Icônes de rôle sur les alliés", "Role icons on friendlies"), "nameplates.friendlyRoleIcons", "np")
            c:Done()

            c = page:Card(T("Empilement à l'écran", "Stacking on screen"), { adv = true })
            c:Slider(T("Chevauchement vertical", "Vertical overlap"), "nameplates.overlapV", 0.5, 3, 0.05, "np", "%.2f",
                T("Plus haut = plaques plus serrées.", "Higher = plates packed closer."))
            c:Slider(T("Hauteur max à l'écran", "Max height on screen"), "nameplates.topInset", 0.01, 0.5, 0.01, "np", "%.2f")
            c:Slider(T("Taille de la marque de raid", "Raid marker size"), "nameplates.raidIconSize", 10, 48, 1, "np")
            c:Done()
            page:StudioLink("astral", "nameplate", "Astral Forge Studio")
        end)
    end,
})

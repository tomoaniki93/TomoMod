-- =====================================
-- Panels/UnitFrames.lua — UnitFrames Config (Tabbed)
-- =====================================

local W = TomoMod_Widgets

-- Helper: build all options for a single unit inside a scroll panel
local function BuildUnitContent(parent, unitKey, displayName)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.unitFrames[unitKey]
    if not db then return scroll end

    local y = -10

    -- Activer
    local _, ny = W.CreateCheckbox(c, "Activer", db.enabled, y, function(v)
        db.enabled = v
        print("|cff0cd29fTomoMod|r " .. displayName .. ": " .. (v and "activé" or "désactivé") .. " (reload nécessaire)")
    end)
    y = ny

    -- =====================================
    -- DIMENSIONS
    -- =====================================
    local _, ny = W.CreateSubLabel(c, "— Dimensions —", y)
    y = ny

    local _, ny = W.CreateSlider(c, "Largeur", db.width, 80, 400, 5, y, function(v)
        db.width = v
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
            TomoMod_UnitFrames.RefreshUnit(unitKey)
        end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Hauteur vie", db.healthHeight, 10, 80, 2, y, function(v)
        db.healthHeight = v
        db.height = v + (db.powerHeight or 0) + 6
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
            TomoMod_UnitFrames.RefreshUnit(unitKey)
        end
    end)
    y = ny

    if db.powerHeight and db.powerHeight > 0 or unitKey == "player" or unitKey == "target" or unitKey == "focus" then
        local _, ny = W.CreateSlider(c, "Hauteur ressource", db.powerHeight or 8, 0, 20, 1, y, function(v)
            db.powerHeight = v
            db.height = (db.healthHeight or 38) + v + 6
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
        end)
        y = ny
    end

    -- =====================================
    -- AFFICHAGE
    -- =====================================
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, "— Affichage —", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Afficher le nom", db.showName, y, function(v)
        db.showName = v
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
            TomoMod_UnitFrames.RefreshUnit(unitKey)
        end
    end)
    y = ny

    if db.showLevel ~= nil then
        local _, ny = W.CreateCheckbox(c, "Afficher le niveau", db.showLevel, y, function(v)
            db.showLevel = v
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
        end)
        y = ny
    end

    local _, ny = W.CreateCheckbox(c, "Afficher le texte de vie", db.showHealthText, y, function(v)
        db.showHealthText = v
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
            TomoMod_UnitFrames.RefreshUnit(unitKey)
        end
    end)
    y = ny

    if db.healthTextFormat then
        local _, ny = W.CreateDropdown(c, "Format vie", {
            { text = "Courant (25.3K)", value = "current" },
            { text = "Pourcentage (75%)", value = "percent" },
            { text = "Courant + % (25.3K | 75%)", value = "current_percent" },
            { text = "Courant / Max", value = "current_max" },
        }, db.healthTextFormat, y, function(v)
            db.healthTextFormat = v
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
        end)
        y = ny
    end

    local _, ny = W.CreateCheckbox(c, "Couleur de classe", db.useClassColor, y, function(v)
        db.useClassColor = v
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
            TomoMod_UnitFrames.RefreshUnit(unitKey)
        end
    end)
    y = ny

    if db.useFactionColor ~= nil then
        local _, ny = W.CreateCheckbox(c, "Couleur de faction (PNJ)", db.useFactionColor, y, function(v)
            db.useFactionColor = v
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
        end)
        y = ny
    end

    if db.showAbsorb ~= nil then
        local _, ny = W.CreateCheckbox(c, "Barre d'absorption", db.showAbsorb, y, function(v)
            db.showAbsorb = v
        end)
        y = ny
    end

    if db.showThreat ~= nil then
        local _, ny = W.CreateCheckbox(c, "Indicateur de menace", db.showThreat, y, function(v)
            db.showThreat = v
        end)
        y = ny
    end

    if db.showLeaderIcon ~= nil then
        local _, ny = W.CreateCheckbox(c, "Icône leader", db.showLeaderIcon, y, function(v)
            db.showLeaderIcon = v
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
        end)
        y = ny
        if db.leaderIconOffset then
            local _, ny = W.CreateSlider(c, "Leader icône X", db.leaderIconOffset.x, -50, 50, 1, y, function(v)
                db.leaderIconOffset.x = v
                if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                    TomoMod_UnitFrames.RefreshUnit(unitKey)
                end
            end)
            y = ny
            local _, ny = W.CreateSlider(c, "Leader icône Y", db.leaderIconOffset.y, -50, 50, 1, y, function(v)
                db.leaderIconOffset.y = v
                if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                    TomoMod_UnitFrames.RefreshUnit(unitKey)
                end
            end)
            y = ny
        end
    end

    -- =====================================
    -- CASTBAR
    -- =====================================
    if db.castbar then
        local _, ny = W.CreateSeparator(c, y)
        y = ny
        local _, ny = W.CreateSubLabel(c, "— Castbar —", y)
        y = ny

        local _, ny = W.CreateCheckbox(c, "Activer castbar", db.castbar.enabled, y, function(v)
            db.castbar.enabled = v
        end)
        y = ny

        local _, ny = W.CreateSlider(c, "Largeur castbar", db.castbar.width, 50, 400, 5, y, function(v)
            db.castbar.width = v
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
        end)
        y = ny

        local _, ny = W.CreateSlider(c, "Hauteur castbar", db.castbar.height, 8, 40, 1, y, function(v)
            db.castbar.height = v
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
        end)
        y = ny

        local _, ny = W.CreateCheckbox(c, "Afficher icône", db.castbar.showIcon, y, function(v)
            db.castbar.showIcon = v
        end)
        y = ny

        local _, ny = W.CreateCheckbox(c, "Afficher timer", db.castbar.showTimer, y, function(v)
            db.castbar.showTimer = v
        end)
        y = ny
    end

    -- =====================================
    -- AURAS
    -- =====================================
    if db.auras then
        local _, ny = W.CreateSeparator(c, y)
        y = ny
        local _, ny = W.CreateSubLabel(c, "— Auras —", y)
        y = ny

        local _, ny = W.CreateCheckbox(c, "Activer les auras", db.auras.enabled, y, function(v)
            db.auras.enabled = v
        end)
        y = ny

        local _, ny = W.CreateSlider(c, "Nombre max d'auras", db.auras.maxAuras, 1, 16, 1, y, function(v)
            db.auras.maxAuras = v
        end)
        y = ny

        local _, ny = W.CreateSlider(c, "Taille des icônes", db.auras.size, 16, 48, 1, y, function(v)
            db.auras.size = v
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
        end)
        y = ny

        local _, ny = W.CreateDropdown(c, "Type d'auras", {
            { text = "Debuffs (nocifs)", value = "HARMFUL" },
            { text = "Buffs (bénéfiques)", value = "HELPFUL" },
            { text = "Tous", value = "ALL" },
        }, db.auras.type or "HARMFUL", y, function(v)
            db.auras.type = v
        end)
        y = ny

        local _, ny = W.CreateDropdown(c, "Direction de croissance", {
            { text = "Vers la droite", value = "RIGHT" },
            { text = "Vers la gauche", value = "LEFT" },
        }, db.auras.growDirection, y, function(v)
            db.auras.growDirection = v
        end)
        y = ny

        local _, ny = W.CreateCheckbox(c, "Seulement mes auras", db.auras.showOnlyMine, y, function(v)
            db.auras.showOnlyMine = v
        end)
        y = ny
    end

    -- =====================================
    -- ELEMENT OFFSETS (player + target only)
    -- =====================================
    if (unitKey == "player" or unitKey == "target") and db.elementOffsets then
        local _, ny = W.CreateSeparator(c, y)
        y = ny
        local _, ny = W.CreateSubLabel(c, "— Position des éléments —", y)
        y = ny

        local elements = {
            { key = "name",       label = "Nom" },
            { key = "level",      label = "Niveau" },
            { key = "healthText", label = "Texte de vie" },
            { key = "power",      label = "Barre de ressource" },
            { key = "castbar",    label = "Castbar" },
            { key = "auras",      label = "Auras" },
        }

        for _, elem in ipairs(elements) do
            if db.elementOffsets[elem.key] then
                local offData = db.elementOffsets[elem.key]

                local _, ny = W.CreateSlider(c, elem.label .. " X", offData.x, -100, 100, 1, y, function(v)
                    offData.x = v
                    if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                        TomoMod_UnitFrames.RefreshUnit(unitKey)
                    end
                end)
                y = ny

                local _, ny = W.CreateSlider(c, elem.label .. " Y", offData.y, -100, 100, 1, y, function(v)
                    offData.y = v
                    if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                        TomoMod_UnitFrames.RefreshUnit(unitKey)
                    end
                end)
                y = ny
            end
        end
    end

    -- =====================================
    -- RESET POSITION
    -- =====================================
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateButton(c, "Reset Position " .. displayName, 220, y, function()
        if TomoMod_Defaults.unitFrames[unitKey] and TomoMod_Defaults.unitFrames[unitKey].position then
            db.position = CopyTable(TomoMod_Defaults.unitFrames[unitKey].position)
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
            print("|cff0cd29fTomoMod|r Position de " .. displayName .. " réinitialisée")
        end
    end)
    y = ny

    -- Resize scroll child
    c:SetHeight(math.abs(y) + 40)
    return scroll
end

-- Helper: build general settings tab
local function BuildGeneralContent(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, "Paramètres Généraux", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Activer les UnitFrames TomoMod", TomoModDB.unitFrames.enabled, y, function(v)
        TomoModDB.unitFrames.enabled = v
        print("|cff0cd29fTomoMod|r UnitFrames " .. (v and "activés" or "désactivés") .. " (reload)")
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Masquer les frames Blizzard", TomoModDB.unitFrames.hideBlizzardFrames, y, function(v)
        TomoModDB.unitFrames.hideBlizzardFrames = v
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Taille de police globale", TomoModDB.unitFrames.fontSize, 8, 20, 1, y, function(v)
        TomoModDB.unitFrames.fontSize = v
    end)
    y = ny

    local _, ny = W.CreateButton(c, "Toggle Lock/Unlock (/tm uf)", 240, y, function()
        if TomoMod_UnitFrames and TomoMod_UnitFrames.ToggleLock then
            TomoMod_UnitFrames.ToggleLock()
        end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, "Déverrouillez pour déplacer les frames. Les positions sont sauvegardées automatiquement.", y)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

-- =====================================
-- MAIN PANEL ENTRY POINT
-- =====================================

function TomoMod_ConfigPanel_UnitFrames(parent)
    local tabs = {
        { key = "general",      label = "Général",  builder = function(p) return BuildGeneralContent(p) end },
        { key = "player",       label = "Player",   builder = function(p) return BuildUnitContent(p, "player", "Joueur") end },
        { key = "target",       label = "Target",   builder = function(p) return BuildUnitContent(p, "target", "Cible") end },
        { key = "targettarget", label = "ToT",      builder = function(p) return BuildUnitContent(p, "targettarget", "Cible de cible") end },
        { key = "pet",          label = "Pet",      builder = function(p) return BuildUnitContent(p, "pet", "Familier") end },
        { key = "focus",        label = "Focus",    builder = function(p) return BuildUnitContent(p, "focus", "Focus") end },
    }

    return W.CreateTabPanel(parent, tabs)
end

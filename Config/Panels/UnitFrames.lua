-- =====================================
-- Panels/UnitFrames.lua — UnitFrames Config (Tabbed)
-- =====================================

local W = TomoMod_Widgets
local L = TomoMod_L

-- Helper: build all options for a single unit inside a scroll panel
local function BuildUnitContent(parent, unitKey, displayName)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.unitFrames[unitKey]
    if not db then return scroll end

    local y = -10

    -- Activer
    local _, ny = W.CreateCheckbox(c, L["opt_enable"], db.enabled, y, function(v)
        db.enabled = v
        print("|cff0cd29fTomoMod|r " .. displayName .. ": " .. (v and L["msg_uf_enabled"] or L["msg_uf_disabled"]))
    end)
    y = ny

    -- =====================================
    -- DIMENSIONS
    -- =====================================
    local _, ny = W.CreateSubLabel(c, L["sublabel_dimensions"], y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_width"], db.width, 80, 400, 5, y, function(v)
        db.width = v
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
            TomoMod_UnitFrames.RefreshUnit(unitKey)
        end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_health_height"], db.healthHeight, 10, 80, 2, y, function(v)
        db.healthHeight = v
        db.height = v + (db.powerHeight or 0) + 6
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
            TomoMod_UnitFrames.RefreshUnit(unitKey)
        end
    end)
    y = ny

    if db.powerHeight and db.powerHeight > 0 or unitKey == "player" or unitKey == "target" or unitKey == "focus" then
        local _, ny = W.CreateSlider(c, L["opt_power_height"], db.powerHeight or 8, 0, 20, 1, y, function(v)
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
    local _, ny = W.CreateSubLabel(c, L["sublabel_display"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_name"], db.showName, y, function(v)
        db.showName = v
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
            TomoMod_UnitFrames.RefreshUnit(unitKey)
        end
    end)
    y = ny

    if db.showLevel ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_level"], db.showLevel, y, function(v)
            db.showLevel = v
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
        end)
        y = ny
    end

    local _, ny = W.CreateCheckbox(c, L["opt_show_health_text"], db.showHealthText, y, function(v)
        db.showHealthText = v
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
            TomoMod_UnitFrames.RefreshUnit(unitKey)
        end
    end)
    y = ny

    if db.healthTextFormat then
        local _, ny = W.CreateDropdown(c, L["opt_health_format"], {
            { text = L["fmt_current"], value = "current" },
            { text = L["fmt_percent"], value = "percent" },
            { text = L["fmt_current_percent"], value = "current_percent" },
            { text = L["fmt_current_max"], value = "current_max" },
        }, db.healthTextFormat, y, function(v)
            db.healthTextFormat = v
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
        end)
        y = ny
    end

    local _, ny = W.CreateCheckbox(c, L["opt_class_color_uf"], db.useClassColor, y, function(v)
        db.useClassColor = v
        if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
            TomoMod_UnitFrames.RefreshUnit(unitKey)
        end
    end)
    y = ny

    if db.useFactionColor ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_faction_color"], db.useFactionColor, y, function(v)
            db.useFactionColor = v
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
        end)
        y = ny
    end

    if db.showAbsorb ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_absorb"], db.showAbsorb, y, function(v)
            db.showAbsorb = v
        end)
        y = ny
    end

    if db.showThreat ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_threat"], db.showThreat, y, function(v)
            db.showThreat = v
        end)
        y = ny
    end

    if db.showLeaderIcon ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_leader_icon"], db.showLeaderIcon, y, function(v)
            db.showLeaderIcon = v
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
        end)
        y = ny
        if db.leaderIconOffset then
            local _, ny = W.CreateSlider(c, L["opt_leader_icon_x"], db.leaderIconOffset.x, -50, 50, 1, y, function(v)
                db.leaderIconOffset.x = v
                if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                    TomoMod_UnitFrames.RefreshUnit(unitKey)
                end
            end)
            y = ny
            local _, ny = W.CreateSlider(c, L["opt_leader_icon_y"], db.leaderIconOffset.y, -50, 50, 1, y, function(v)
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
        local _, ny = W.CreateSubLabel(c, L["sublabel_castbar"], y)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_castbar_enable"], db.castbar.enabled, y, function(v)
            db.castbar.enabled = v
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_castbar_width"], db.castbar.width, 50, 400, 5, y, function(v)
            db.castbar.width = v
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_castbar_height"], db.castbar.height, 8, 40, 1, y, function(v)
            db.castbar.height = v
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
        end)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_castbar_show_icon"], db.castbar.showIcon, y, function(v)
            db.castbar.showIcon = v
        end)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_castbar_show_timer"], db.castbar.showTimer, y, function(v)
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
        local _, ny = W.CreateSubLabel(c, L["sublabel_auras"], y)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_auras_enable"], db.auras.enabled, y, function(v)
            db.auras.enabled = v
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_auras_max"], db.auras.maxAuras, 1, 16, 1, y, function(v)
            db.auras.maxAuras = v
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_auras_size"], db.auras.size, 16, 48, 1, y, function(v)
            db.auras.size = v
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
        end)
        y = ny

        local _, ny = W.CreateDropdown(c, L["opt_auras_type"], {
            { text = L["aura_harmful"], value = "HARMFUL" },
            { text = L["aura_helpful"], value = "HELPFUL" },
            { text = L["aura_all"], value = "ALL" },
        }, db.auras.type or "HARMFUL", y, function(v)
            db.auras.type = v
        end)
        y = ny

        local _, ny = W.CreateDropdown(c, L["opt_auras_direction"], {
            { text = L["aura_dir_right"], value = "RIGHT" },
            { text = L["aura_dir_left"], value = "LEFT" },
        }, db.auras.growDirection, y, function(v)
            db.auras.growDirection = v
        end)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_auras_only_mine"], db.auras.showOnlyMine, y, function(v)
            db.auras.showOnlyMine = v
        end)
        y = ny
    end

    -- =====================================
    -- ENEMY BUFFS (target + focus only)
    -- =====================================
    if db.enemyBuffs and (unitKey == "target" or unitKey == "focus") then
        local _, ny = W.CreateSeparator(c, y)
        y = ny
        local _, ny = W.CreateSubLabel(c, L["sublabel_enemy_buffs"], y)
        y = ny

        local _, ny = W.CreateInfoText(c, L["info_enemy_buffs"], y)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_enemy_buffs_enable"], db.enemyBuffs.enabled, y, function(v)
            db.enemyBuffs.enabled = v
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_enemy_buffs_max"], db.enemyBuffs.maxAuras, 1, 8, 1, y, function(v)
            db.enemyBuffs.maxAuras = v
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_enemy_buffs_size"], db.enemyBuffs.size, 14, 40, 1, y, function(v)
            db.enemyBuffs.size = v
        end)
        y = ny
    end

    -- =====================================
    -- ELEMENT OFFSETS (player + target only)
    -- =====================================
    if (unitKey == "player" or unitKey == "target") and db.elementOffsets then
        local _, ny = W.CreateSeparator(c, y)
        y = ny
        local _, ny = W.CreateSubLabel(c, L["sublabel_element_offsets"], y)
        y = ny

        local elements = {
            { key = "name",       label = L["elem_name"] },
            { key = "level",      label = L["elem_level"] },
            { key = "healthText", label = L["elem_health_text"] },
            { key = "power",      label = L["elem_power"] },
            { key = "castbar",    label = L["elem_castbar"] },
            { key = "auras",      label = L["elem_auras"] },
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

    local _, ny = W.CreateButton(c, L["btn_reset_position"] .. " " .. displayName, 220, y, function()
        if TomoMod_Defaults.unitFrames[unitKey] and TomoMod_Defaults.unitFrames[unitKey].position then
            db.position = CopyTable(TomoMod_Defaults.unitFrames[unitKey].position)
            if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                TomoMod_UnitFrames.RefreshUnit(unitKey)
            end
            print("|cff0cd29fTomoMod|r " .. displayName .. " " .. L["msg_uf_position_reset"])
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

    local _, ny = W.CreateSectionHeader(c, L["section_general_settings"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_uf_enable"], TomoModDB.unitFrames.enabled, y, function(v)
        TomoModDB.unitFrames.enabled = v
        print("|cff0cd29fTomoMod|r " .. string.format(L["msg_uf_toggle"], v and L["enabled"] or L["disabled"]))
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_hide_blizzard"], TomoModDB.unitFrames.hideBlizzardFrames, y, function(v)
        TomoModDB.unitFrames.hideBlizzardFrames = v
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_global_font_size"], TomoModDB.unitFrames.fontSize, 8, 20, 1, y, function(v)
        TomoModDB.unitFrames.fontSize = v
    end)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_toggle_lock"], 240, y, function()
        if TomoMod_UnitFrames and TomoMod_UnitFrames.ToggleLock then
            TomoMod_UnitFrames.ToggleLock()
        end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_unlock_drag"], y)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

-- =====================================
-- MAIN PANEL ENTRY POINT
-- =====================================

function TomoMod_ConfigPanel_UnitFrames(parent)
    local tabs = {
        { key = "general",      label = L["tab_general"],  builder = function(p) return BuildGeneralContent(p) end },
        { key = "player",       label = L["tab_player"],   builder = function(p) return BuildUnitContent(p, "player", L["unit_player"]) end },
        { key = "target",       label = L["tab_target"],   builder = function(p) return BuildUnitContent(p, "target", L["unit_target"]) end },
        { key = "targettarget", label = L["tab_tot"],      builder = function(p) return BuildUnitContent(p, "targettarget", L["unit_tot"]) end },
        { key = "pet",          label = L["tab_pet"],      builder = function(p) return BuildUnitContent(p, "pet", L["unit_pet"]) end },
        { key = "focus",        label = L["tab_focus"],    builder = function(p) return BuildUnitContent(p, "focus", L["unit_focus"]) end },
    }

    return W.CreateTabPanel(parent, tabs)
end

-- =====================================
-- Panels/UnitFrames.lua — UnitFrames Config (Tabbed + Sub-Tabs)
-- =====================================

local W = TomoModMini_Widgets
local L = TomoModMini_L

local FONT_PATH = "Interface\\AddOns\\TomoModMini\\Assets\\Fonts\\"

-- Available fonts for the dropdown (Mini only ships Tomo.ttf)
local FONT_LIST = {
    { text = "Poppins SemiBold",  value = FONT_PATH .. "Poppins-SemiBold.ttf" },
    { text = "Poppins Bold",      value = FONT_PATH .. "Poppins-Bold.ttf" },
    { text = "Tomo",              value = FONT_PATH .. "Tomo.ttf" },
    { text = "Friz Quadrata (WoW)",   value = "Fonts\\FRIZQT__.TTF" },
    { text = "Arial Narrow (WoW)",    value = "Fonts\\ARIALN.TTF" },
    { text = "Morpheus (WoW)",        value = "Fonts\\MORPHEUS.TTF" },
}

-- Helper: refresh all units
local function RefreshAll()
    if TomoModMini_UnitFrames and TomoModMini_UnitFrames.RefreshAllUnits then
        TomoModMini_UnitFrames.RefreshAllUnits()
    end
end

local function RefreshUnit(unitKey)
    if TomoModMini_UnitFrames and TomoModMini_UnitFrames.RefreshUnit then
        TomoModMini_UnitFrames.RefreshUnit(unitKey)
    end
end

-- =====================================
-- SUB-TAB BUILDERS for Player/Target/Focus
-- =====================================

-- Sub-tab 1: Activer + Dimensions
local function BuildDimensionsTab(parent, unitKey, displayName)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModMiniDB.unitFrames[unitKey]
    if not db then return scroll end

    local y = -10

    -- Enable
    local _, ny = W.CreateCheckbox(c, L["opt_enable"], db.enabled, y, function(v)
        db.enabled = v
        print("|cffff3399TomoModMini|r " .. displayName .. ": " .. (v and L["msg_uf_enabled"] or L["msg_uf_disabled"]))
    end)
    y = ny

    -- Dimensions
    local _, ny = W.CreateSubLabel(c, L["sublabel_dimensions"], y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_width"], db.width, 80, 400, 5, y, function(v)
        db.width = v
        RefreshUnit(unitKey)
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_health_height"], db.healthHeight, 10, 80, 2, y, function(v)
        db.healthHeight = v
        db.height = v + (db.powerHeight or 0) + 6
        RefreshUnit(unitKey)
    end)
    y = ny

    if db.powerHeight and db.powerHeight > 0 or unitKey == "player" or unitKey == "target" or unitKey == "focus" then
        local _, ny = W.CreateSlider(c, L["opt_power_height"], db.powerHeight or 8, 0, 20, 1, y, function(v)
            db.powerHeight = v
            db.height = (db.healthHeight or 38) + v + 6
            RefreshUnit(unitKey)
        end)
        y = ny
    end

    -- Castbar dimensions (if applicable)
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
            RefreshUnit(unitKey)
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_castbar_height"], db.castbar.height, 8, 40, 1, y, function(v)
            db.castbar.height = v
            RefreshUnit(unitKey)
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

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

-- Sub-tab 2: Affichage
local function BuildDisplayTab(parent, unitKey)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModMiniDB.unitFrames[unitKey]
    if not db then return scroll end

    local y = -10

    local _, ny = W.CreateCheckbox(c, L["opt_show_name"], db.showName, y, function(v)
        db.showName = v
        RefreshUnit(unitKey)
    end)
    y = ny

    if db.nameTruncate ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_name_truncate"], db.nameTruncate, y, function(v)
            db.nameTruncate = v
            RefreshUnit(unitKey)
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_name_truncate_length"], db.nameTruncateLength or 20, 5, 40, 1, y, function(v)
            db.nameTruncateLength = v
            RefreshUnit(unitKey)
        end)
        y = ny
    end

    if db.showLevel ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_show_level"], db.showLevel, y, function(v)
            db.showLevel = v
            RefreshUnit(unitKey)
        end)
        y = ny
    end

    local _, ny = W.CreateCheckbox(c, L["opt_show_health_text"], db.showHealthText, y, function(v)
        db.showHealthText = v
        RefreshUnit(unitKey)
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
            RefreshUnit(unitKey)
        end)
        y = ny
    end

    local _, ny = W.CreateCheckbox(c, L["opt_class_color_uf"], db.useClassColor, y, function(v)
        db.useClassColor = v
        RefreshUnit(unitKey)
    end)
    y = ny

    if db.useFactionColor ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_faction_color"], db.useFactionColor, y, function(v)
            db.useFactionColor = v
            RefreshUnit(unitKey)
        end)
        y = ny
    end

    if db.useNameplateColors ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_use_nameplate_colors"], db.useNameplateColors, y, function(v)
            db.useNameplateColors = v
            RefreshUnit(unitKey)
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
            RefreshUnit(unitKey)
        end)
        y = ny
    end

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

-- Sub-tab 3: Auras
local function BuildAurasTab(parent, unitKey)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModMiniDB.unitFrames[unitKey]
    if not db then return scroll end

    local y = -10

    -- Debuffs/Buffs auras
    if db.auras then
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
            RefreshUnit(unitKey)
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

    -- Enemy Buffs (target + focus only)
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

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

-- Sub-tab 4: Positionnement
local function BuildPositionTab(parent, unitKey, displayName)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModMiniDB.unitFrames[unitKey]
    if not db then return scroll end

    local y = -10

    -- Element offsets
    if db.elementOffsets then
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
            -- Skip castbar offsets for player (player castbar is drag & drop)
            if elem.key == "castbar" and unitKey == "player" then
                -- noop
            elseif db.elementOffsets[elem.key] then
                local offData = db.elementOffsets[elem.key]

                local _, ny = W.CreateSlider(c, elem.label .. " X", offData.x, -100, 100, 1, y, function(v)
                    offData.x = v
                    RefreshUnit(unitKey)
                end)
                y = ny

                local _, ny = W.CreateSlider(c, elem.label .. " Y", offData.y, -100, 100, 1, y, function(v)
                    offData.y = v
                    RefreshUnit(unitKey)
                end)
                y = ny
            end
        end
    end

    -- Player castbar: reset position button (drag & drop)
    if unitKey == "player" and db.castbar then
        local _, ny = W.CreateSeparator(c, y)
        y = ny

        local _, ny = W.CreateInfoText(c, L["info_player_castbar_drag"], y)
        y = ny

        local _, ny = W.CreateButton(c, L["btn_reset_castbar_position"], 220, y, function()
            local def = TomoModMini_Defaults.unitFrames.player.castbar.position
            if def then
                db.castbar.position = CopyTable(def)
                RefreshUnit("player")
                print("|cffff3399TomoModMini|r " .. L["msg_castbar_position_reset"])
            end
        end)
        y = ny
    end

    -- Leader icon offsets
    if db.showLeaderIcon ~= nil and db.leaderIconOffset then
        local _, ny = W.CreateSeparator(c, y)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_leader_icon_x"], db.leaderIconOffset.x, -50, 50, 1, y, function(v)
            db.leaderIconOffset.x = v
            RefreshUnit(unitKey)
        end)
        y = ny
        local _, ny = W.CreateSlider(c, L["opt_leader_icon_y"], db.leaderIconOffset.y, -50, 50, 1, y, function(v)
            db.leaderIconOffset.y = v
            RefreshUnit(unitKey)
        end)
        y = ny
    end

    -- Reset position button
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_reset_position"] .. " " .. displayName, 220, y, function()
        if TomoModMini_Defaults.unitFrames[unitKey] and TomoModMini_Defaults.unitFrames[unitKey].position then
            db.position = CopyTable(TomoModMini_Defaults.unitFrames[unitKey].position)
            RefreshUnit(unitKey)
            print("|cffff3399TomoModMini|r " .. displayName .. " " .. L["msg_uf_position_reset"])
        end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

-- =====================================
-- BUILD UNIT WITH SUB-TABS (Player, Target, Focus)
-- =====================================

local function BuildUnitWithSubTabs(parent, unitKey, displayName)
    local tabs = {
        { key = "dims",    label = L["subtab_dimensions"],   builder = function(p) return BuildDimensionsTab(p, unitKey, displayName) end },
        { key = "display", label = L["subtab_display"],      builder = function(p) return BuildDisplayTab(p, unitKey) end },
        { key = "auras",   label = L["subtab_auras"],        builder = function(p) return BuildAurasTab(p, unitKey) end },
        { key = "pos",     label = L["subtab_positioning"],  builder = function(p) return BuildPositionTab(p, unitKey, displayName) end },
    }

    return W.CreateTabPanel(parent, tabs)
end

-- =====================================
-- BUILD SIMPLE UNIT (ToT, Pet — no sub-tabs)
-- =====================================

local function BuildSimpleUnitContent(parent, unitKey, displayName)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModMiniDB.unitFrames[unitKey]
    if not db then return scroll end

    local y = -10

    -- Enable
    local _, ny = W.CreateCheckbox(c, L["opt_enable"], db.enabled, y, function(v)
        db.enabled = v
        print("|cffff3399TomoModMini|r " .. displayName .. ": " .. (v and L["msg_uf_enabled"] or L["msg_uf_disabled"]))
    end)
    y = ny

    -- Dimensions
    local _, ny = W.CreateSubLabel(c, L["sublabel_dimensions"], y)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_width"], db.width, 80, 400, 5, y, function(v)
        db.width = v
        RefreshUnit(unitKey)
    end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_health_height"], db.healthHeight, 10, 80, 2, y, function(v)
        db.healthHeight = v
        db.height = v + (db.powerHeight or 0) + 6
        RefreshUnit(unitKey)
    end)
    y = ny

    -- Display
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_display"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_show_name"], db.showName, y, function(v)
        db.showName = v
        RefreshUnit(unitKey)
    end)
    y = ny

    if db.nameTruncate ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_name_truncate"], db.nameTruncate, y, function(v)
            db.nameTruncate = v
            RefreshUnit(unitKey)
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_name_truncate_length"], db.nameTruncateLength or 12, 5, 40, 1, y, function(v)
            db.nameTruncateLength = v
            RefreshUnit(unitKey)
        end)
        y = ny
    end

    local _, ny = W.CreateCheckbox(c, L["opt_class_color_uf"], db.useClassColor, y, function(v)
        db.useClassColor = v
        RefreshUnit(unitKey)
    end)
    y = ny

    if db.useFactionColor ~= nil then
        local _, ny = W.CreateCheckbox(c, L["opt_faction_color"], db.useFactionColor, y, function(v)
            db.useFactionColor = v
            RefreshUnit(unitKey)
        end)
        y = ny
    end

    -- Reset position
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_reset_position"] .. " " .. displayName, 220, y, function()
        if TomoModMini_Defaults.unitFrames[unitKey] and TomoModMini_Defaults.unitFrames[unitKey].position then
            db.position = CopyTable(TomoModMini_Defaults.unitFrames[unitKey].position)
            RefreshUnit(unitKey)
            print("|cffff3399TomoModMini|r " .. displayName .. " " .. L["msg_uf_position_reset"])
        end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

-- =====================================
-- GENERAL TAB
-- =====================================

local function BuildGeneralContent(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_general_settings"], y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_uf_enable"], TomoModMiniDB.unitFrames.enabled, y, function(v)
        TomoModMiniDB.unitFrames.enabled = v
        print("|cffff3399TomoModMini|r " .. string.format(L["msg_uf_toggle"], v and L["enabled"] or L["disabled"]))
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_hide_blizzard"], TomoModMiniDB.unitFrames.hideBlizzardFrames, y, function(v)
        TomoModMiniDB.unitFrames.hideBlizzardFrames = v
    end)
    y = ny

    -- Font family dropdown
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_font"], y)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_font_family"], FONT_LIST, TomoModMiniDB.unitFrames.fontFamily or TomoModMiniDB.unitFrames.font, y, function(v)
        TomoModMiniDB.unitFrames.fontFamily = v
        TomoModMiniDB.unitFrames.font = v
        RefreshAll()
    end)
    y = ny

    -- Font size slider (calls RefreshAllUnits for live update)
    local _, ny = W.CreateSlider(c, L["opt_global_font_size"], TomoModMiniDB.unitFrames.fontSize, 8, 20, 1, y, function(v)
        TomoModMiniDB.unitFrames.fontSize = v
        RefreshAll()
    end)
    y = ny

    -- Lock/Unlock
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_toggle_lock"], 240, y, function()
        if TomoModMini_UnitFrames and TomoModMini_UnitFrames.ToggleLock then
            TomoModMini_UnitFrames.ToggleLock()
        end
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_unlock_drag"], y)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

-- =====================================
-- COLORS TAB
-- =====================================

local function BuildColorsContent(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModMiniDB.unitFrames
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_castbar_colors"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_castbar_colors"], y)
    y = ny

    -- Interruptible castbar color (default: red)
    if not db.castbarColor then db.castbarColor = { r = 0.80, g = 0.10, b = 0.10 } end
    local _, ny = W.CreateColorPicker(c, L["opt_castbar_color"], db.castbarColor, y, function(r, g, b)
        db.castbarColor.r, db.castbarColor.g, db.castbarColor.b = r, g, b
    end)
    y = ny

    -- Non-interruptible overlay color (default: grey)
    if not db.castbarNIColor then db.castbarNIColor = { r = 0.50, g = 0.50, b = 0.50 } end
    local _, ny = W.CreateColorPicker(c, L["opt_castbar_ni_color"], db.castbarNIColor, y, function(r, g, b)
        db.castbarNIColor.r, db.castbarNIColor.g, db.castbarNIColor.b = r, g, b
    end)
    y = ny

    -- Interrupt color (default: green)
    if not db.castbarInterruptColor then db.castbarInterruptColor = { r = 0.10, g = 0.80, b = 0.10 } end
    local _, ny = W.CreateColorPicker(c, L["opt_castbar_interrupt_color"], db.castbarInterruptColor, y, function(r, g, b)
        db.castbarInterruptColor.r, db.castbarInterruptColor.g, db.castbarInterruptColor.b = r, g, b
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_castbar_colors_reload"], y)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

-- =====================================
-- MAIN PANEL ENTRY POINT
-- =====================================

function TomoModMini_ConfigPanel_UnitFrames(parent)
    local tabs = {
        { key = "general",      label = L["tab_general"],  builder = function(p) return BuildGeneralContent(p) end },
        { key = "player",       label = L["tab_player"],   builder = function(p) return BuildUnitWithSubTabs(p, "player", L["unit_player"]) end },
        { key = "target",       label = L["tab_target"],   builder = function(p) return BuildUnitWithSubTabs(p, "target", L["unit_target"]) end },
        { key = "targettarget", label = L["tab_tot"],      builder = function(p) return BuildSimpleUnitContent(p, "targettarget", L["unit_tot"]) end },
        { key = "pet",          label = L["tab_pet"],      builder = function(p) return BuildSimpleUnitContent(p, "pet", L["unit_pet"]) end },
        { key = "focus",        label = L["tab_focus"],    builder = function(p) return BuildUnitWithSubTabs(p, "focus", L["unit_focus"]) end },
        { key = "colors",       label = L["tab_colors"],   builder = function(p) return BuildColorsContent(p) end },
    }

    return W.CreateTabPanel(parent, tabs)
end

-- =====================================
-- Panels/UnitFrames.lua — UnitFrames Config (Tabbed + Sub-Tabs)
-- =====================================

local W = TomoMod_Widgets
local L = TomoMod_L

local FONT_PATH = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\"

-- Available fonts for the dropdown
local FONT_LIST = {
    { text = "Poppins Medium",    value = FONT_PATH .. "Poppins-Medium.ttf" },
    { text = "Poppins SemiBold",  value = FONT_PATH .. "Poppins-SemiBold.ttf" },
    { text = "Poppins Bold",      value = FONT_PATH .. "Poppins-Bold.ttf" },
    { text = "Poppins Black",     value = FONT_PATH .. "Poppins-Black.ttf" },
    { text = "Expressway",        value = FONT_PATH .. "Expressway.TTF" },
    { text = "Accidental Pres.",  value = FONT_PATH .. "accidental_pres.ttf" },
    { text = "Tomo",              value = FONT_PATH .. "Tomo.ttf" },
    { text = "Friz Quadrata (WoW)", value = "Fonts\\FRIZQT__.TTF" },
    { text = "Arial Narrow (WoW)",  value = "Fonts\\ARIALN.TTF" },
    { text = "Morpheus (WoW)",      value = "Fonts\\MORPHEUS.TTF" },
}

-- Helper: refresh all units
local function RefreshAll()
    if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshAllUnits then
        TomoMod_UnitFrames.RefreshAllUnits()
    end
    if TomoMod_UFPreview and TomoMod_UFPreview.Refresh then
        TomoMod_UFPreview.Refresh()
    end
end

local function RefreshUnit(unitKey)
    if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
        TomoMod_UnitFrames.RefreshUnit(unitKey)
    end
    if TomoMod_UFPreview and TomoMod_UFPreview.Refresh then
        TomoMod_UFPreview.Refresh()
    end
end

-- =====================================
-- SUB-TAB BUILDERS for Player/Target/Focus
-- =====================================

-- Sub-tab 1: Activer + Dimensions
local function BuildDimensionsTab(parent, unitKey, displayName)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.unitFrames[unitKey]
    if not db then return scroll end

    local y = -10

    -- Enable
    local _, ny = W.CreateCheckbox(c, L["opt_enable"], db.enabled, y, function(v)
        db.enabled = v
        print("|cff0cd29fTomoMod|r " .. displayName .. ": " .. (v and L["msg_uf_enabled"] or L["msg_uf_disabled"]))
    end)
    y = ny

    -- Dimensions
    local _, ny = W.CreateSubLabel(c, L["sublabel_dimensions"], y)
    y = ny

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, ny2 = W.CreateSlider(col, L["opt_width"], db.width, 80, 400, 5, 0, function(v)
                db.width = v; RefreshUnit(unitKey)
            end)
            return ny2
        end,
        function(col)
            local _, ny2 = W.CreateSlider(col, L["opt_health_height"], db.healthHeight, 10, 80, 2, 0, function(v)
                db.healthHeight = v
                db.height = v + (db.powerHeight or 0) + 6
                RefreshUnit(unitKey)
            end)
            return ny2
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

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- Sub-tab 2: Affichage
local function BuildDisplayTab(parent, unitKey)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.unitFrames[unitKey]
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

    if db.useFactionColor ~= nil then
        local _, ny = W.CreateCheckboxPair(c,
            L["opt_class_color_uf"], db.useClassColor,   y, function(v) db.useClassColor   = v; RefreshUnit(unitKey) end,
            L["opt_faction_color"],  db.useFactionColor,    function(v) db.useFactionColor  = v; RefreshUnit(unitKey) end)
        y = ny
    else
        local _, ny = W.CreateCheckbox(c, L["opt_class_color_uf"], db.useClassColor, y, function(v)
            db.useClassColor = v; RefreshUnit(unitKey)
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

    -- Threat text (% de menace — target uniquement)
    if db.threatText ~= nil then
        local _, ny = W.CreateSectionHeader(c, L["section_threat_text"], y)
        y = ny

        local _, ny = W.CreateCheckbox(c, L["opt_threat_text_enable"], db.threatText.enabled, y, function(v)
            db.threatText.enabled = v
            RefreshUnit(unitKey)
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_threat_text_font_size"], db.threatText.fontSize, 8, 24, 1, y, function(v)
            db.threatText.fontSize = v
            RefreshUnit(unitKey)
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_threat_text_offset_x"], db.threatText.offsetX, -200, 200, 1, y, function(v)
            db.threatText.offsetX = v
            RefreshUnit(unitKey)
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_threat_text_offset_y"], db.threatText.offsetY, -200, 200, 1, y, function(v)
            db.threatText.offsetY = v
            RefreshUnit(unitKey)
        end)
        y = ny

        local _, ny = W.CreateInfoText(c, L["info_threat_text"], y)
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
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- Sub-tab 3: Auras
local function BuildAurasTab(parent, unitKey)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.unitFrames[unitKey]
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
            RefreshUnit(unitKey)
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_enemy_buffs_max"], db.enemyBuffs.maxAuras, 1, 8, 1, y, function(v)
            db.enemyBuffs.maxAuras = v
            RefreshUnit(unitKey)
        end)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_enemy_buffs_size"], db.enemyBuffs.size, 14, 40, 1, y, function(v)
            db.enemyBuffs.size = v
            RefreshUnit(unitKey)
        end)
        y = ny
    end

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- Sub-tab 4: Positionnement
local function BuildPositionTab(parent, unitKey, displayName)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.unitFrames[unitKey]
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
            -- Skip castbar for player (standalone drag & drop via /tm sr)
            if elem.key == "castbar" and unitKey == "player" then
                -- no-op
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

    -- Raid icon offsets
    if db.showRaidIcon and db.raidIconOffset then
        local _, ny = W.CreateSeparator(c, y)
        y = ny

        local _, ny = W.CreateSlider(c, L["opt_raid_icon_x"], db.raidIconOffset.x, -100, 100, 1, y, function(v)
            db.raidIconOffset.x = v
            RefreshUnit(unitKey)
        end)
        y = ny
        local _, ny = W.CreateSlider(c, L["opt_raid_icon_y"], db.raidIconOffset.y, -100, 100, 1, y, function(v)
            db.raidIconOffset.y = v
            RefreshUnit(unitKey)
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
        if TomoMod_Defaults.unitFrames[unitKey] and TomoMod_Defaults.unitFrames[unitKey].position then
            db.position = CopyTable(TomoMod_Defaults.unitFrames[unitKey].position)
            RefreshUnit(unitKey)
            print("|cff0cd29fTomoMod|r " .. displayName .. " " .. L["msg_uf_position_reset"])
        end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
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
    local db = TomoModDB.unitFrames[unitKey]
    if not db then return scroll end

    local y = -10

    -- Enable
    local _, ny = W.CreateCheckbox(c, L["opt_enable"], db.enabled, y, function(v)
        db.enabled = v
        print("|cff0cd29fTomoMod|r " .. displayName .. ": " .. (v and L["msg_uf_enabled"] or L["msg_uf_disabled"]))
    end)
    y = ny

    -- Dimensions
    local _, ny = W.CreateSubLabel(c, L["sublabel_dimensions"], y)
    y = ny

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, ny2 = W.CreateSlider(col, L["opt_width"], db.width, 80, 400, 5, 0, function(v)
                db.width = v; RefreshUnit(unitKey)
            end)
            return ny2
        end,
        function(col)
            local _, ny2 = W.CreateSlider(col, L["opt_health_height"], db.healthHeight, 10, 80, 2, 0, function(v)
                db.healthHeight = v
                db.height = v + (db.powerHeight or 0) + 6
                RefreshUnit(unitKey)
            end)
            return ny2
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

    if db.useFactionColor ~= nil then
        local _, ny = W.CreateCheckboxPair(c,
            L["opt_class_color_uf"], db.useClassColor,   y, function(v) db.useClassColor   = v; RefreshUnit(unitKey) end,
            L["opt_faction_color"],  db.useFactionColor,    function(v) db.useFactionColor  = v; RefreshUnit(unitKey) end)
        y = ny
    else
        local _, ny = W.CreateCheckbox(c, L["opt_class_color_uf"], db.useClassColor, y, function(v)
            db.useClassColor = v; RefreshUnit(unitKey)
        end)
        y = ny
    end

    -- Reset position
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_reset_position"] .. " " .. displayName, 220, y, function()
        if TomoMod_Defaults.unitFrames[unitKey] and TomoMod_Defaults.unitFrames[unitKey].position then
            db.position = CopyTable(TomoMod_Defaults.unitFrames[unitKey].position)
            RefreshUnit(unitKey)
            print("|cff0cd29fTomoMod|r " .. displayName .. " " .. L["msg_uf_position_reset"])
        end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
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

    local _, ny = W.CreateCheckboxPair(c,
        L["opt_uf_enable"],    TomoModDB.unitFrames.enabled,             y,
        function(v)
            TomoModDB.unitFrames.enabled = v
            print("|cff0cd29fTomoMod|r " .. string.format(L["msg_uf_toggle"], v and L["enabled"] or L["disabled"]))
        end,
        L["opt_hide_blizzard"], TomoModDB.unitFrames.hideBlizzardFrames,
        function(v) TomoModDB.unitFrames.hideBlizzardFrames = v end)
    y = ny

    -- Font family dropdown
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_font"], y)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_font_family"], FONT_LIST, TomoModDB.unitFrames.fontFamily or TomoModDB.unitFrames.font, y, function(v)
        TomoModDB.unitFrames.fontFamily = v
        TomoModDB.unitFrames.font = v
        RefreshAll()
    end)
    y = ny

    -- Font size slider (calls RefreshAllUnits for live update)
    local _, ny = W.CreateSlider(c, L["opt_global_font_size"], TomoModDB.unitFrames.fontSize, 8, 20, 1, y, function(v)
        TomoModDB.unitFrames.fontSize = v
        RefreshAll()
    end)
    y = ny

    -- Lock/Unlock
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateButtonRow(c, {
        { text = L["btn_toggle_lock"], width = 200, cb = function()
            if TomoMod_UnitFrames and TomoMod_UnitFrames.ToggleLock then
                TomoMod_UnitFrames.ToggleLock()
            end
        end },
    }, y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_unlock_drag"], y)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- BUILD BOSS FRAMES CONTENT
-- =====================================

local function BuildBossContent(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.unitFrames.bossFrames
    if not db then return scroll end

    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_boss_frames"], y)
    y = ny

    -- Enable
    local _, ny = W.CreateCheckbox(c, L["opt_boss_enable"], db.enabled, y, function(v)
        db.enabled = v
        print("|cff0cd29fTomoMod|r Boss: " .. (v and L["msg_uf_enabled"] or L["msg_uf_disabled"]))
    end)
    y = ny

    -- Dimensions
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_dimensions"], y)
    y = ny

    local function RefreshBoss() if TomoMod_BossFrames and TomoMod_BossFrames.RefreshAll then TomoMod_BossFrames.RefreshAll() end end

    local _, ny = W.CreateTwoColumnRow(c, y,
        function(col)
            local _, ny2 = W.CreateSlider(col, L["opt_width"],       db.width,  100, 350, 5, 0, function(v) db.width  = v; RefreshBoss() end)
            return ny2
        end,
        function(col)
            local _, ny2 = W.CreateSlider(col, L["opt_boss_height"], db.height,  16,  50, 2, 0, function(v) db.height = v; RefreshBoss() end)
            return ny2
        end)
    y = ny

    local _, ny = W.CreateSlider(c, L["opt_boss_spacing"], db.spacing, 0, 20, 1, y, function(v)
        db.spacing = v
        if TomoMod_BossFrames and TomoMod_BossFrames.RefreshAll then
            TomoMod_BossFrames.RefreshAll()
        end
    end)
    y = ny

    -- Info
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_boss_drag"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_boss_colors"], y)
    y = ny

    -- Reset position
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_reset_position"] .. " Boss", 220, y, function()
        if TomoMod_Defaults.unitFrames.bossFrames and TomoMod_Defaults.unitFrames.bossFrames.position then
            db.position = CopyTable(TomoMod_Defaults.unitFrames.bossFrames.position)
            if TomoMod_BossFrames and TomoMod_BossFrames.RefreshAll then
                TomoMod_BossFrames.RefreshAll()
            end
            print("|cff0cd29fTomoMod|r Boss " .. L["msg_uf_position_reset"])
        end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

-- =====================================
-- MAIN PANEL ENTRY POINT
-- =====================================

-- ============================================================
-- MAIN ENTRY POINT
-- Layout :
--   ┌─ wrapper ──────────────────────────────────┐
--   │  preview strip  (hauteur dynamique ~165px) │
--   │────────────────────────────────────────────│
--   │  tab bar + contenus (remplit le reste)     │
--   └────────────────────────────────────────────┘
-- ============================================================

local PREVIEW_H_INITIAL = 165   -- hauteur initiale avant premier Refresh

function TomoMod_ConfigPanel_UnitFrames(parent)
    local wrapper = CreateFrame("Frame", nil, parent)
    wrapper:SetAllPoints()

    -- ── Preview strip ──────────────────────────────────────
    local preview = TomoMod_UFPreview.Create(wrapper)

    -- ── Tab host (positionné juste sous le strip) ──────────
    local tabHost = CreateFrame("Frame", nil, wrapper)
    tabHost:SetPoint("TOPLEFT",     wrapper, "TOPLEFT",     0, -PREVIEW_H_INITIAL)
    tabHost:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", 0, 0)

    -- Ré-ancrage automatique quand le strip change de hauteur
    preview:SetScript("OnSizeChanged", function(self)
        local h = math.floor(self:GetHeight() + 0.5)
        tabHost:ClearAllPoints()
        tabHost:SetPoint("TOPLEFT",     wrapper, "TOPLEFT",     0, -h)
        tabHost:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", 0, 0)
    end)

    -- ── Onglets ────────────────────────────────────────────
    local TAB_DEFS = {
        { key = "general",      label = L["tab_general"],  builder = function(p) return BuildGeneralContent(p) end },
        { key = "player",       label = L["tab_player"],   builder = function(p) return BuildUnitWithSubTabs(p, "player", L["unit_player"]) end },
        { key = "target",       label = L["tab_target"],   builder = function(p) return BuildUnitWithSubTabs(p, "target", L["unit_target"]) end },
        { key = "targettarget", label = L["tab_tot"],      builder = function(p) return BuildSimpleUnitContent(p, "targettarget", L["unit_tot"]) end },
        { key = "pet",          label = L["tab_pet"],      builder = function(p) return BuildSimpleUnitContent(p, "pet", L["unit_pet"]) end },
        { key = "focus",        label = L["tab_focus"],    builder = function(p) return BuildUnitWithSubTabs(p, "focus", L["unit_focus"]) end },
        { key = "boss",         label = L["tab_boss"],     builder = function(p) return BuildBossContent(p) end },
    }

    local tabWidget = W.CreateTabPanel(tabHost, TAB_DEFS)
    tabWidget:SetAllPoints(tabHost)

    -- ── Clic sur un aperçu → navigation vers son onglet ───
    local unitToTab = {
        player = "player", target = "target",
        targettarget = "targettarget", pet = "pet", focus = "focus",
    }
    for unitKey, tabKey in pairs(unitToTab) do
        preview.onUnitClick[unitKey] = function()
            tabWidget.SwitchTab(tabKey)
        end
    end

    -- Forcer un refresh à l'ouverture du panel
    wrapper:SetScript("OnShow", function()
        if TomoMod_UFPreview and TomoMod_UFPreview.ForceRefresh then
            TomoMod_UFPreview.ForceRefresh()
        end
    end)

    return wrapper
end

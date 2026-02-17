-- =====================================
-- Panels/Sound.lua — Sound/Lust Config Panel
-- New sidebar category "Son"
-- =====================================

local W = TomoMod_Widgets
local L = TomoMod_L

-- =====================================
-- HELPER: Build sorted dropdown options from registry
-- =====================================

local function GetSoundOptions()
    if not TomoMod_LustSound or not TomoMod_LustSound.soundRegistry then return {} end
    local opts = {}
    for key, entry in pairs(TomoMod_LustSound.soundRegistry) do
        opts[#opts + 1] = { text = entry.name, value = key }
    end
    table.sort(opts, function(a, b) return a.text < b.text end)
    return opts
end

local function GetChannelOptions()
    return {
        { text = "Master",   value = "Master" },
        { text = "SFX",      value = "SFX" },
        { text = "Music",    value = "Music" },
        { text = "Ambience", value = "Ambience" },
        { text = "Dialog",   value = "Dialog" },
    }
end

-- =====================================
-- TAB 1: GÉNÉRAL
-- =====================================

local function BuildGeneralTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.lustSound
    if not db then return scroll end
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_sound_general"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_sound_desc"], y)
    y = ny

    -- Enable
    local _, ny = W.CreateCheckbox(c, L["opt_sound_enable"], db.enabled, y, function(v)
        if TomoMod_LustSound and TomoMod_LustSound.SetEnabled then
            TomoMod_LustSound.SetEnabled(v)
        end
    end)
    y = ny

    -- Sound selection
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, L["sublabel_sound_choice"], y)
    y = ny

    local _, ny = W.CreateDropdown(c, L["opt_sound_file"], GetSoundOptions(), db.sound, y, function(v)
        db.sound = v
    end)
    y = ny

    -- Channel
    local _, ny = W.CreateDropdown(c, L["opt_sound_channel"], GetChannelOptions(), db.channel, y, function(v)
        db.channel = v
    end)
    y = ny

    -- Preview buttons
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_sound_preview"], 200, y, function()
        if TomoMod_LustSound then TomoMod_LustSound.PlayPreview() end
    end)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_sound_stop"], 200, y, function()
        if TomoMod_LustSound then TomoMod_LustSound.StopPreview() end
    end)
    y = ny

    -- Chat messages
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_sound_chat"], db.showChat, y, function(v)
        db.showChat = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, L["opt_sound_debug"], db.debug, y, function(v)
        db.debug = v
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

-- =====================================
-- TAB 2: DÉTECTION
-- =====================================

local function BuildDetectionTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.lustSound
    if not db then return scroll end
    local det = db.detection
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_sound_detection"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_sound_detection_desc"], y)
    y = ny

    -- Spike ratio
    local _, ny = W.CreateSlider(c, L["opt_sound_spike_ratio"], det.spike_ratio, 120, 240, 5, y, function(v)
        det.spike_ratio = v
    end, "%d%%")
    y = ny
    local _, ny = W.CreateInfoText(c, L["info_sound_spike_tooltip"], y)
    y = ny

    -- Jump ratio
    local _, ny = W.CreateSlider(c, L["opt_sound_jump_ratio"], det.jump_ratio, 110, 180, 5, y, function(v)
        det.jump_ratio = v
    end, "%d%%")
    y = ny
    local _, ny = W.CreateInfoText(c, L["info_sound_jump_tooltip"], y)
    y = ny

    -- Fade ratio
    local _, ny = W.CreateSlider(c, L["opt_sound_fade_ratio"], det.fade_ratio, 105, 140, 5, y, function(v)
        det.fade_ratio = v
    end, "%d%%")
    y = ny
    local _, ny = W.CreateInfoText(c, L["info_sound_fade_tooltip"], y)
    y = ny

    -- Reset detection
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_sound_reset_detection"], 220, y, function()
        local defaults = TomoMod_Defaults.lustSound.detection
        det.spike_ratio = defaults.spike_ratio
        det.jump_ratio = defaults.jump_ratio
        det.fade_ratio = defaults.fade_ratio
        print("|cff0cd29fTomoMod|r " .. L["msg_sound_detection_reset"])
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    return scroll
end

-- =====================================
-- MAIN PANEL ENTRY POINT
-- =====================================

function TomoMod_ConfigPanel_Sound(parent)
    local tabs = {
        { key = "general",   label = L["tab_sound_general"],   builder = function(p) return BuildGeneralTab(p) end },
        { key = "detection", label = L["tab_sound_detection"], builder = function(p) return BuildDetectionTab(p) end },
    }

    return W.CreateTabPanel(parent, tabs)
end

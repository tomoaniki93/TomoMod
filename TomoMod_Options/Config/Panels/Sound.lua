-- Panels/Sound.lua v2.7.0
local W = TomoMod_Widgets
local L = TomoMod_L

local function GetSoundOptions()
    if not TomoMod_LustSound or not TomoMod_LustSound.soundRegistry then return {} end
    local opts = {}
    for key, entry in pairs(TomoMod_LustSound.soundRegistry) do
        opts[#opts + 1] = { text = entry.name, value = key }
    end
    table.sort(opts, function(a, b) return a.text < b.text end)
    return opts
end

local CHANNEL_OPTIONS = {
    { text = "Master",   value = "Master"   },
    { text = "SFX",      value = "SFX"      },
    { text = "Music",    value = "Music"     },
    { text = "Ambience", value = "Ambience"  },
    { text = "Dialog",   value = "Dialog"    },
}

local CHANNEL_VOLUME_CVARS = {
    Master   = "Sound_MasterVolume",
    SFX      = "Sound_SFXVolume",
    Music    = "Sound_MusicVolume",
    Ambience = "Sound_AmbienceVolume",
    Dialog   = "Sound_DialogVolume",
}

local function GetChannelVolume(channel)
    local cvar = CHANNEL_VOLUME_CVARS[channel] or CHANNEL_VOLUME_CVARS.Master
    local getter = (C_CVar and C_CVar.GetCVar) or GetCVar
    local value = getter and tonumber(getter(cvar)) or 1
    return math.floor(math.max(0, math.min(1, value or 1)) * 100 + 0.5)
end

local function SetChannelVolume(channel, percent)
    local cvar = CHANNEL_VOLUME_CVARS[channel] or CHANNEL_VOLUME_CVARS.Master
    local setter = (C_CVar and C_CVar.SetCVar) or SetCVar
    if setter then
        setter(cvar, string.format("%.2f", math.max(0, math.min(100, percent)) / 100))
    end
end

function TomoMod_ConfigPanel_Sound(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local db = TomoModDB.lustSound
    if not db then return scroll end
    local y = -12

    -- ═══════════════════════════════════════════════
    -- ACTIVATION
    -- ═══════════════════════════════════════════════
    local card, cy = W.CreateCard(c, L["section_sound_general"], y)

    local _, cy = W.CreateInfoText(card.inner, L["info_sound_desc"], cy)
    local _, cy = W.CreateCheckbox(card.inner, L["opt_sound_enable"], db.enabled, cy, function(v)
        db.enabled = v
        if TomoMod_LustSound and TomoMod_LustSound.SetEnabled then TomoMod_LustSound.SetEnabled(v) end
    end)

    y = W.FinalizeCard(card, cy)

    -- ═══════════════════════════════════════════════
    -- CHOIX DU SON
    -- ═══════════════════════════════════════════════
    local card2, cy = W.CreateCard(c, L["sublabel_sound_choice"], y)

    local _, cy = W.CreateDropdown(card2.inner, L["opt_sound_file"], GetSoundOptions(), db.sound, cy, function(v)
        db.sound = v
        -- Sélectionner un son le joue aussitôt, pour l'entendre sans chercher.
        if TomoMod_LustSound and TomoMod_LustSound.PlayPreview then TomoMod_LustSound.PlayPreview() end
    end)

    -- Bouton d'écoute juste sous le sélecteur (découvrable immédiatement)
    local _, cy = W.CreateButton(card2.inner, L["btn_sound_test"], 200, cy, function()
        if TomoMod_LustSound and TomoMod_LustSound.PlayPreview then TomoMod_LustSound.PlayPreview() end
    end)

    local volumeSlider
    local _, cy = W.CreateSegmentedControl(card2.inner, L["opt_sound_channel"], CHANNEL_OPTIONS, db.channel, cy, function(v)
        db.channel = v
        if volumeSlider then
            volumeSlider:SetValue(GetChannelVolume(v))
        end
    end, 3)

    volumeSlider, cy = W.CreateSlider(card2.inner, L["opt_sound_volume"],
        GetChannelVolume(db.channel), 0, 100, 1, cy, function(v)
            SetChannelVolume(db.channel, v)
        end, "%d%%", GetChannelVolume(db.channel))

    local _, cy = W.CreateInfoText(card2.inner, L["info_sound_volume"], cy)

    y = W.FinalizeCard(card2, cy)

    -- ═══════════════════════════════════════════════
    -- PRÉVISUALISATION + OPTIONS
    -- ═══════════════════════════════════════════════
    local card3, cy = W.CreateCard(c, L["section_sound_preview"], y)

    local _, cy = W.CreateTwoColumnRow(card3.inner, cy,
        function(col)
            local _, ny = W.CreateButton(col, L["btn_sound_preview"], 180, 0, function()
                if TomoMod_LustSound then TomoMod_LustSound.PlayPreview() end
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateButton(col, L["btn_sound_stop"], 180, 0, function()
                if TomoMod_LustSound then TomoMod_LustSound.StopPreview() end
            end)
            return ny
        end)

    local _, cy = W.CreateTwoColumnRow(card3.inner, cy,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["opt_sound_chat"], db.showChat, 0, function(v)
                db.showChat = v
            end)
            return ny
        end,
        function(col)
            local _, ny = W.CreateCheckbox(col, L["opt_sound_debug"], db.debug, 0, function(v)
                db.debug = v
            end)
            return ny
        end)

    y = W.FinalizeCard(card3, cy)

    c:SetHeight(math.abs(y) + 20)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

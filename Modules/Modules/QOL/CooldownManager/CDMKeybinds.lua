-- =====================================
-- CDMKeybinds.lua — Phase 3: Enhanced Keybind System
-- Extracted from CooldownManager.lua inline hotkey code
-- Enhanced with DDingUI-style multi-layer caching
--
-- Features:
--   • Multi-layer cache: binding → slot → spell → keybind text
--   • Supports: Blizzard, ElvUI, Dominos, Bartender4 action bars
--   • Macro + item spell resolution
--   • Override/base spell fallback chain
--   • Weak table for keybind FontString frames (anti-taint)
--   • Event-driven auto-rebuild (bindings, talents, spec, bars)
--   • Configurable: font, size, anchor, color, visibility
--
-- Usage:
--   CDMKeybinds.Initialize()
--   CDMKeybinds.GetSpellHotkey(spellID)  → string|nil
--   CDMKeybinds.CreateHotkeyText(button, width) → FontString
--   CDMKeybinds.UpdateButton(button)
--   CDMKeybinds.RefreshVisibility()
--
-- Requires: CDMScanner.lua loaded before this file.
-- =====================================

TomoMod_CDMKeybinds = TomoMod_CDMKeybinds or {}
local Keybinds = TomoMod_CDMKeybinds

local Scanner = TomoMod_CDMScanner

-- =====================================
-- CONSTANTS
-- =====================================
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

-- =====================================
-- CACHES
-- =====================================
-- Layer 1: spellID → formatted keybind text (rebuilt on binding/bar changes)
local spellKeyBindCache = {}

-- Layer 2: action slot → formatted keybind text (legacy fallback)
local slotKeybindCache = {}

-- Cache validity flags
local bindingCacheValid = false
local isInitialized     = false

-- =====================================
-- ACTION BAR DEFINITIONS
-- =====================================
local BLIZZARD_BARS = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
}

local ELVUI_BARS = {
    "ElvUI_Bar1Button",
    "ElvUI_Bar2Button",
    "ElvUI_Bar3Button",
    "ElvUI_Bar4Button",
    "ElvUI_Bar5Button",
    "ElvUI_Bar6Button",
    "ElvUI_Bar7Button",
    "ElvUI_Bar8Button",
    "ElvUI_Bar9Button",
    "ElvUI_Bar10Button",
}

local EXTRA_BARS = {
    { "BonusActionButton", 12 },
    { "ExtraActionButton", 12 },
    { "VehicleMenuBarActionButton", 12 },
    { "OverrideActionBarButton", 12 },
    { "PetActionButton", 10 },
}

-- =====================================
-- SETTINGS ACCESSOR
-- =====================================
local function GetSettings()
    local db = TomoModDB and TomoModDB.cooldownManager
    return db
end

-- =====================================
-- KEY NAME FORMATTING
-- Abbreviate modifier + key names for compact display
-- =====================================
local KEY_SUBSTITUTIONS = {
    { "PADLTRIGGER",         "LT"   },
    { "PADRTRIGGER",         "RT"   },
    { "SHIFT%-",             "S"    },
    { "CTRL%-",              "C"    },
    { "STRG%-",              "ST"   },
    { "ALT%-",               "A"    },
    { "META%-",              "M"    },
    { "MOUSE%s?WHEEL%s?UP",  "MWU"  },
    { "MOUSE%s?WHEEL%s?DOWN","MWD"  },
    { "MIDDLE%s?MOUSE",      "MM"   },
    { "MOUSE%s?BUTTON%s?",   "M"    },
    { "BUTTON",              "M"    },
    { "NUMPAD%s?PLUS",       "N+"   },
    { "NUMPAD%s?MINUS",      "N-"   },
    { "NUMPAD%s?MULTIPLY",   "N*"   },
    { "NUMPAD%s?DIVIDE",     "N/"   },
    { "NUMPAD%s?DECIMAL",    "N."   },
    { "NUMPAD%s?ENTER",      "NEnt" },
    { "NUMPAD%s?",           "N"    },
    { "NUM%s?PAD%s?",        "N"    },
    { "NUM%s?",              "N"    },
    { "PAGE%s?UP",           "PGU"  },
    { "PAGE%s?DOWN",         "PGD"  },
    { "INSERT",              "INS"  },
    { "DELETE",              "DEL"  },
    { "SPACEBAR",            "Spc"  },
    { "ENTER",               "Ent"  },
    { "ESCAPE",              "Esc"  },
    { "TAB",                 "Tab"  },
    { "CAPS%s?LOCK",         "Caps" },
    { "HOME",                "Hom"  },
    { "END",                 "End"  },
    { "UP ARROW",            "^"    },
    { "DOWN ARROW",          "V"    },
    { "RIGHT ARROW",         ">"    },
    { "LEFT ARROW",          "<"    },
    { "BACKSPACE",           "Bs"   },
}

--- Format a raw keybind name into a compact display string.
--- @param name string — raw binding name (e.g. "SHIFT-F", "NUMPAD1")
--- @return string|nil — formatted name, or nil if empty
local function FormatKeyName(name)
    if not name or name == "" or name == "●" then return nil end
    name = string.upper(name)
    for _, sub in ipairs(KEY_SUBSTITUTIONS) do
        name = string.gsub(name, sub[1], sub[2])
    end
    return name
end

-- Export for external use
Keybinds.FormatKeyName = FormatKeyName

-- =====================================
-- SLOT → SPELL RESOLUTION
-- =====================================

--- Resolve an action slot to a spellID and assign keybind.
--- @param slot number — action bar slot
--- @param keyBind string — formatted keybind text
--- @param result table — accumulator: { [spellID] = keybind }
local function AssignSpellForSlot(slot, keyBind, result)
    local actionType, id, subType = GetActionInfo(slot)
    if not id or result[id] then return end

    if (actionType == "macro" and subType == "spell") or (actionType == "spell") then
        result[id] = keyBind
    elseif actionType == "macro" then
        local macroName = GetActionText(slot)
        local macroSpellID = macroName and GetMacroSpell(macroName)
        if macroSpellID and not result[macroSpellID] then
            result[macroSpellID] = keyBind
        end
    elseif actionType == "item" then
        local _, spellId = C_Item.GetItemSpell(id)
        if spellId and not result[spellId] then
            result[spellId] = keyBind
        end
    end
end

-- =====================================
-- FULL CACHE REBUILD
-- Scans all known action bars and builds spellID → keybind mapping
-- =====================================
local function RebuildCache()
    local result = {}

    -- ==================
    -- ElvUI bars
    -- ==================
    if _G["ElvUI_Bar1Button1"] then
        for _, barPrefix in ipairs(ELVUI_BARS) do
            for j = 1, 12 do
                local button = _G[barPrefix .. j]
                local slot = button and button.action
                if button and slot and button.config then
                    local keyBind = GetBindingKey(button.config.keyBoundTarget)
                    if keyBind then
                        local fmt = FormatKeyName(keyBind)
                        if fmt then AssignSpellForSlot(slot, fmt, result) end
                    end
                end
            end
        end
    end

    -- ==================
    -- Dominos
    -- ==================
    if _G["DominosActionButton1"] then
        for i = 1, 168 do
            local button = _G["DominosActionButton" .. i]
            if not button then break end
            local slot = button.action
            local hotkey = button.HotKey and button.HotKey:GetText()
            if slot and hotkey then
                local fmt = FormatKeyName(hotkey)
                if fmt then AssignSpellForSlot(slot, fmt, result) end
            end
        end
    end

    -- ==================
    -- Bartender4
    -- ==================
    if _G["BT4Button1"] then
        for i = 1, 120 do
            local button = _G["BT4Button" .. i]
            if not button then break end
            local slot = button.action or (button._state_action)
            -- BT4 uses GetBindingKey with "CLICK BT4ButtonN:LeftButton"
            local bindKey = GetBindingKey("CLICK BT4Button" .. i .. ":LeftButton")
            if slot and bindKey then
                local fmt = FormatKeyName(bindKey)
                if fmt then AssignSpellForSlot(slot, fmt, result) end
            end
        end
    end

    -- ==================
    -- Blizzard bars (uses GetBindingKey via commandName)
    -- ==================
    for _, barPrefix in ipairs(BLIZZARD_BARS) do
        for j = 1, 12 do
            local button = _G[barPrefix .. j]
            local slot = button and button.action
            local keyBoundTarget = button and button.commandName
            if button and slot and keyBoundTarget then
                local keyBind = GetBindingKey(keyBoundTarget)
                if keyBind then
                    local fmt = FormatKeyName(keyBind)
                    if fmt then AssignSpellForSlot(slot, fmt, result) end
                end
            end
        end
    end

    -- ==================
    -- Bonus, Extra, Override, Vehicle, Pet bars
    -- ==================
    wipe(slotKeybindCache)
    for _, info in ipairs(EXTRA_BARS) do
        local prefix, total = info[1], info[2]
        for j = 1, total do
            local button = _G[prefix .. j]
            if not button then break end
            local hotkey = _G[button:GetName() .. "HotKey"]
            local text = hotkey and hotkey:GetText()
            local slot = button.action
            if slot and text then
                local fmt = FormatKeyName(text)
                if fmt then slotKeybindCache[slot] = fmt end
            end
        end
    end

    -- Store final spellID → keybind mapping
    wipe(spellKeyBindCache)
    for spellID, keyBind in pairs(result) do
        spellKeyBindCache[spellID] = keyBind
    end

    bindingCacheValid = true
end

-- =====================================
-- PUBLIC: GET SPELL HOTKEY
-- =====================================

--- Get the formatted keybind text for a spellID.
--- Follows override → base → slot fallback chain.
--- @param spellID number
--- @return string|nil keybind
function Keybinds.GetSpellHotkey(spellID)
    if not spellID then return nil end
    if not bindingCacheValid then RebuildCache() end

    -- Direct cache hit
    if spellKeyBindCache[spellID] then return spellKeyBindCache[spellID] end

    -- Try override spell
    local overrideID = C_Spell.GetOverrideSpell and C_Spell.GetOverrideSpell(spellID)
    if overrideID and spellKeyBindCache[overrideID] then return spellKeyBindCache[overrideID] end

    -- Try base spell
    local baseID = C_Spell.GetBaseSpell and C_Spell.GetBaseSpell(spellID)
    if baseID and spellKeyBindCache[baseID] then return spellKeyBindCache[baseID] end

    -- Fallback: action bar slot lookup
    local slots = C_ActionBar.FindSpellActionButtons(spellID)
    if slots and #slots > 0 then
        for _, slot in ipairs(slots) do
            if slotKeybindCache[slot] then return slotKeybindCache[slot] end
        end
    end

    return nil
end

-- =====================================
-- PUBLIC: CREATE HOTKEY TEXT ON BUTTON
-- =====================================

--- Create the hotkey FontString on a CDM button.
--- @param button table — CDM icon frame
--- @param iconWidth number — button width for font scaling
--- @return FontString
function Keybinds.CreateHotkeyText(button, iconWidth)
    if button._cdm_hotkey then return button._cdm_hotkey end

    local fs = button:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT, math.max(8, iconWidth / 4 - 1), "OUTLINE")
    fs:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -1)
    fs:SetTextColor(0.9, 0.9, 0.9, 0.9)
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 1)
    fs:Hide()

    button._cdm_hotkey = fs
    return fs
end

-- =====================================
-- PUBLIC: UPDATE BUTTON HOTKEY
-- =====================================

--- Update the hotkey text on a single CDM button.
--- Uses CDMScanner for anti-taint spellID lookup.
--- @param button table — CDM icon frame
function Keybinds.UpdateButton(button)
    local settings = GetSettings()
    if not settings or not settings.showHotKey or not button._cdm_hotkey then return end

    local spellID = nil

    -- CDMScanner cached cooldownID → spellID (anti-taint)
    local cdID = Scanner.GetCachedCooldownID(button)
    if cdID then
        local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cdID)
        if ok and info then spellID = info.spellID end
    end

    -- Fallback: GetSpellID method
    if not spellID then
        spellID = button:GetSpellID()
        if type(spellID) == "nil" or (issecretvalue and issecretvalue(spellID)) then
            spellID = nil
        end
    end

    if spellID then
        button._cdm_spellID = spellID
        local keyText = Keybinds.GetSpellHotkey(spellID)
        if keyText then
            button._cdm_hotkey:SetText(keyText)
            button._cdm_hotkey:Show()
        else
            button._cdm_hotkey:Hide()
        end
    end
end

-- =====================================
-- PUBLIC: REFRESH VISIBILITY
-- =====================================

--- Show/hide all keybind texts based on current settings.
--- @param cdViewers table — array of Essential/Utility viewer frames
function Keybinds.RefreshVisibility(cdViewers)
    local settings = GetSettings()
    if not settings or not cdViewers then return end

    for _, viewer in ipairs(cdViewers) do
        if viewer then
            local children = { viewer:GetChildren() }
            for _, button in ipairs(children) do
                if button._cdm_hotkey then
                    if settings.showHotKey then
                        Keybinds.UpdateButton(button)
                    else
                        button._cdm_hotkey:Hide()
                    end
                end
            end
        end
    end
end

-- =====================================
-- PUBLIC: FORCE REBUILD
-- =====================================

--- Force a full cache rebuild. Call after spec/talent changes.
function Keybinds.Rebuild()
    bindingCacheValid = false
    RebuildCache()
end

-- =====================================
-- EVENT-DRIVEN AUTO-REBUILD
-- =====================================
local eventFrame = CreateFrame("Frame")

function Keybinds.Initialize()
    if isInitialized then return end
    isInitialized = true

    RebuildCache()

    eventFrame:RegisterEvent("UPDATE_BINDINGS")
    eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("SPELLS_CHANGED")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("ACTIONBAR_HIDEGRID")

    eventFrame:SetScript("OnEvent", function(_, event)
        -- Debounce: most events happen in bursts
        bindingCacheValid = false
        -- Defer rebuild to next frame (collapse rapid events)
        C_Timer.After(0, function()
            if not bindingCacheValid then
                RebuildCache()
            end
        end)
    end)
end

-- Export
_G.TomoMod_CDMKeybinds = Keybinds

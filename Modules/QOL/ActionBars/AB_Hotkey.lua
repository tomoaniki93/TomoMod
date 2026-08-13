-- =====================================================================
-- AB_Hotkey.lua v1.0.0 -- ActionBars hotkey layer (Lot A4)
--
-- Owns the keybind text on every action button, and the optional
-- bind-on-hover mode.
--
-- Why resolve the binding ourselves instead of reading Blizzard's HotKey
-- fontstring: a TomoMod-owned button (Lot A6) has no Blizzard fontstring to
-- read. Going through GetBindingKey() on the canonical binding name means
-- the same code path works for both, and it is also what the override-binding
-- work in A6 will need. The Blizzard fontstring is kept only as a fallback,
-- so an unexpected binding name in a future patch degrades instead of
-- showing nothing.
--
-- Bind-on-hover deliberately never touches the buttons' own scripts. It
-- creates its own overlay frames on top and destroys them on exit, so no
-- OnEnter/OnLeave handler is ever installed on a secure button.
-- =====================================================================

TomoMod_ABHotkey = TomoMod_ABHotkey or {}
local H = TomoMod_ABHotkey

local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

-- Locales are loaded before this file, but resolve lazily anyway so a load
-- order change cannot turn a chat message into an error.
local function L() return TomoMod_L end

local function Say(msg)
    if type(msg) == "string" and msg ~= "" then
        print("|cff2ed884TomoMod|r " .. msg)
    end
end

-- =====================================================================
-- BINDING NAMES
-- =====================================================================

local BINDING = {
    bar1     = "ACTIONBUTTON%d",
    bar2     = "MULTIACTIONBAR1BUTTON%d",
    bar3     = "MULTIACTIONBAR2BUTTON%d",
    bar4     = "MULTIACTIONBAR3BUTTON%d",
    bar5     = "MULTIACTIONBAR4BUTTON%d",
    bar6     = "MULTIACTIONBAR5BUTTON%d",
    bar7     = "MULTIACTIONBAR6BUTTON%d",
    bar8     = "MULTIACTIONBAR7BUTTON%d",
    pet      = "BONUSACTIONBUTTON%d",
    stance   = "SHAPESHIFTBUTTON%d",
    override = "ACTIONBUTTON%d",
    extra    = "EXTRAACTIONBUTTON%d",
}

H.BINDING = BINDING

-- =====================================================================
-- SETTINGS
-- =====================================================================

local DEFAULTS = {
    enabled    = true,
    abbreviate = true,
    fontSize   = 12,
    outline    = "OUTLINE",
    anchor     = "TOPRIGHT",
    offsetX    = -2,
    offsetY    = -2,
    color      = { 1, 1, 1, 1 },
    hideEmpty  = true,
}

H.DEFAULTS = DEFAULTS

local function GetSettings()
    if not TomoModDB then return DEFAULTS end
    if not TomoModDB.actionBars then TomoModDB.actionBars = {} end
    local db = TomoModDB.actionBars.hotkey
    if not db then db = {}; TomoModDB.actionBars.hotkey = db end
    for k, v in pairs(DEFAULTS) do
        if db[k] == nil then
            if type(v) == "table" then
                local copy = {}
                for i = 1, #v do copy[i] = v[i] end
                db[k] = copy
            else
                db[k] = v
            end
        end
    end
    return db
end

H.GetSettings = GetSettings

local function GetBarSettings(barId)
    local AB = TomoMod_ActionBars
    if AB and AB.GetBarDB and barId then
        local ok, res = pcall(AB.GetBarDB, barId)
        if ok and type(res) == "table" then return res end
    end
    return nil
end

-- =====================================================================
-- ABBREVIATION (ASCII only)
-- =====================================================================

local ABBREV_ORDER = {
    { "MOUSEWHEELUP",   "mwu" },
    { "MOUSEWHEELDOWN", "mwd" },
    { "NUMPAD",         "n"   },
    { "PAGEUP",         "pu"  },
    { "PAGEDOWN",       "pd"  },
    { "BACKSPACE",      "bs"  },
    { "CAPSLOCK",       "cl"  },
    { "ESCAPE",         "esc" },
    { "INSERT",         "ins" },
    { "DELETE",         "del" },
    { "MULTIPLY",       "*"   },
    { "SUBTRACT",       "-"   },
    { "DIVIDE",         "/"   },
    { "DECIMAL",        "."   },
    { "UPARROW",        "up"  },
    { "DOWNARROW",      "dn"  },
    { "LEFTARROW",      "lt"  },
    { "RIGHTARROW",     "rt"  },
    { "SPACE",          "sp"  },
    { "BUTTON",         "m"   },
    { "HOME",           "hm"  },
    { "ADD",            "+"   },
    { "END",            "en"  },
    { "ALT%-",          "a"   },
    { "CTRL%-",         "c"   },
    { "SHIFT%-",        "s"   },
    { "META%-",         "M"   },
}

local function Abbreviate(key)
    if type(key) ~= "string" or key == "" then return key end
    local out = key
    for i = 1, #ABBREV_ORDER do
        out = out:gsub(ABBREV_ORDER[i][1], ABBREV_ORDER[i][2])
    end
    return out
end

H.Abbreviate = Abbreviate

-- =====================================================================
-- KEY RESOLUTION
-- =====================================================================

-- The Blizzard command for this position (ACTIONBUTTON3, MULTIACTIONBAR4BUTTON1...).
function H.GetBlizzardBindingName(entry)
    if not entry or not entry.barId or not entry.index then return nil end
    local fmt = BINDING[entry.barId]
    if not fmt then return nil end
    return string.format(fmt, entry.index)
end

-- The command a binding should be WRITTEN to.
--
-- A TomoMod-owned button binds through its own click command rather than
-- through a Blizzard command name. That is what Dominos and Bartender4 both
-- do, and it buys three things: the binding lives in WoW's own binding set
-- and shows up in Blizzard's keybinding UI, no override binding has to be
-- re-applied on every UPDATE_BINDINGS, and the dedicated virtual button makes
-- cast-on-key-press behave. It also means we no longer depend on the
-- MULTIACTIONBAR5/6/7 command names, which I could never verify.
function H.GetBindingName(entry)
    local frame = entry and entry.frame
    local ABB = TomoMod_ABButton
    if frame and ABB and ABB.IsOwnButton and ABB.IsOwnButton(frame) then
        return ABB.ClickCommand(frame)
    end
    return H.GetBlizzardBindingName(entry)
end

local function BlizzardKeyText(button)
    if not button or not button.GetName then return nil end
    local hk = button.HotKey or _G[(button:GetName() or "") .. "HotKey"]
    if not hk or not hk.GetText then return nil end
    local ok, text = pcall(hk.GetText, hk)
    if not ok or type(text) ~= "string" or text == "" then return nil end
    -- Blizzard parks the out-of-range dot in this fontstring too.
    if RANGE_INDICATOR and text == RANGE_INDICATOR then return nil end
    return text
end

function H.GetKey(entry)
    local name = H.GetBindingName(entry)
    if name then
        local ok, key = pcall(GetBindingKey, name)
        if ok and type(key) == "string" and key ~= "" then return key, name end
    end

    -- An owned button with no binding of its own may still be driven by a
    -- legacy Blizzard binding that AB_Button bridges onto it: show that key.
    local blizzName = H.GetBlizzardBindingName(entry)
    if blizzName and blizzName ~= name then
        local ok, key = pcall(GetBindingKey, blizzName)
        if ok and type(key) == "string" and key ~= "" then return key, name end
    end

    -- Fallback: whatever Blizzard already worked out for this button.
    return BlizzardKeyText(entry and entry.frame), name
end

-- =====================================================================
-- TEXT RENDERING
-- =====================================================================

local texts = {}   -- entry -> FontString

local function EnsureText(entry)
    local fs = texts[entry]
    if fs then return fs end
    local button = entry.frame
    if not button or not button.CreateFontString then return nil end

    -- Blizzard's own hotkey string is suppressed rather than hidden: its
    -- own code re-shows it on button updates.
    local blizz = button.HotKey or _G[((button.GetName and button:GetName()) or "") .. "HotKey"]
    if blizz then pcall(blizz.SetAlpha, blizz, 0) end
    entry._blizzHotkey = blizz

    fs = button:CreateFontString(nil, "OVERLAY")
    texts[entry] = fs
    return fs
end

local function Render(entry)
    local db = GetSettings()
    local fs = EnsureText(entry)
    if not fs then return end

    if entry._blizzHotkey then pcall(entry._blizzHotkey.SetAlpha, entry._blizzHotkey, 0) end

    local barDB = GetBarSettings(entry.barId)
    local wanted = db.enabled and (not barDB or barDB.showHotkeyText ~= false)

    if not wanted then
        fs:SetText("")
        fs:Hide()
        return
    end

    if db.hideEmpty and entry.state and entry.state.hasAction == false then
        fs:SetText("")
        fs:Hide()
        return
    end

    local key = H.GetKey(entry)
    if type(key) ~= "string" or key == "" then
        fs:SetText("")
        fs:Hide()
        return
    end

    if db.abbreviate then key = Abbreviate(key) end

    -- Per-bar font size wins over the global one when it was set.
    local size = (barDB and barDB.hotkeyFontSize) or db.fontSize or 12
    local outline = db.outline
    if outline ~= "OUTLINE" and outline ~= "THICKOUTLINE" and outline ~= "" then
        outline = "OUTLINE"
    end
    pcall(fs.SetFont, fs, FONT, size, outline)

    local c = db.color or DEFAULTS.color
    fs:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)

    fs:ClearAllPoints()
    fs:SetPoint(db.anchor or "TOPRIGHT", entry.frame, db.anchor or "TOPRIGHT",
        db.offsetX or -2, db.offsetY or -2)
    if (db.anchor or "TOPRIGHT"):find("LEFT") then
        fs:SetJustifyH("LEFT")
    elseif (db.anchor or "TOPRIGHT"):find("RIGHT") then
        fs:SetJustifyH("RIGHT")
    else
        fs:SetJustifyH("CENTER")
    end

    fs:SetText(key)
    fs:Show()
end

function H.Render(entry) if entry then Render(entry) end end

function H.RenderAll()
    local ABE = TomoMod_ABEngine
    if not ABE or not ABE.Entries then return end
    for entry in ABE.Entries() do Render(entry) end
end

H.ApplySettings = H.RenderAll

-- =====================================================================
-- BIND-ON-HOVER
-- Overlay frames only. No script is ever attached to a secure button.
-- =====================================================================

local bindMode    = false
local overlays    = {}   -- entry -> overlay frame
local hovered     = nil
local bindHost    = nil

local MOUSE_MAP = {
    LeftButton   = nil,          -- reserved: clicking the overlay
    RightButton  = nil,          -- reserved: clear
    MiddleButton = "BUTTON3",
    Button4      = "BUTTON4",
    Button5      = "BUTTON5",
}

local function ModifierPrefix()
    local mod = ""
    if IsAltKeyDown()     then mod = mod .. "ALT-"   end
    if IsControlKeyDown() then mod = mod .. "CTRL-"  end
    if IsShiftKeyDown()   then mod = mod .. "SHIFT-" end
    return mod
end

local IGNORED_KEYS = {
    LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true,
    LALT = true, RALT = true, UNKNOWN = true,
}

local function SaveNow()
    if InCombatLockdown() then return end
    local set = GetCurrentBindingSet and GetCurrentBindingSet() or 1
    pcall(SaveBindings, set)
end

local function ApplyBinding(entry, key)
    if InCombatLockdown() then return false end
    local name = H.GetBindingName(entry)
    if not name or not key then return false end

    -- Free the key from whatever held it, then assign.
    pcall(SetBinding, key, nil)
    local ok = pcall(SetBinding, key, name)
    if not ok then return false end
    SaveNow()
    H.RenderAll()
    if overlays[entry] then overlays[entry].label:SetText(Abbreviate(key)) end
    return true
end

local function ClearBinding(entry)
    if InCombatLockdown() then return end
    local name = H.GetBindingName(entry)
    if not name then return end
    while true do
        local key = GetBindingKey(name)
        if not key or key == "" then break end
        pcall(SetBinding, key, nil)
    end
    SaveNow()
    H.RenderAll()
    if overlays[entry] then overlays[entry].label:SetText("") end
end

local function OverlayKeyDown(self, key)
    if not bindMode or IGNORED_KEYS[key] then return end
    local entry = self.entry
    if not entry then return end
    if key == "ESCAPE" then
        ClearBinding(entry)
        return
    end
    ApplyBinding(entry, ModifierPrefix() .. key)
end

local function BuildOverlay(entry)
    local overlay = overlays[entry]
    if overlay then return overlay end
    local button = entry.frame
    if not button then return nil end

    overlay = CreateFrame("Frame", nil, UIParent)
    overlay.entry = entry
    overlay:SetFrameStrata("DIALOG")
    overlay:SetAllPoints(button)
    overlay:EnableMouse(true)
    overlay:EnableMouseWheel(true)
    overlay:EnableKeyboard(true)

    local bg = overlay:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.18, 0.847, 0.518, 0.25)

    overlay.label = overlay:CreateFontString(nil, "OVERLAY")
    overlay.label:SetFont(FONT, 11, "OUTLINE")
    overlay.label:SetPoint("CENTER")
    overlay.label:SetTextColor(1, 1, 1, 1)

    overlay:SetScript("OnEnter", function(self)
        hovered = self.entry
        self:SetPropagateKeyboardInput(false)
        bg:SetColorTexture(0.18, 0.847, 0.518, 0.45)
    end)
    overlay:SetScript("OnLeave", function(self)
        if hovered == self.entry then hovered = nil end
        self:SetPropagateKeyboardInput(true)
        bg:SetColorTexture(0.18, 0.847, 0.518, 0.25)
    end)
    overlay:SetScript("OnKeyDown", OverlayKeyDown)
    overlay:SetScript("OnMouseWheel", function(self, delta)
        if not bindMode then return end
        local key = (delta > 0) and "MOUSEWHEELUP" or "MOUSEWHEELDOWN"
        ApplyBinding(self.entry, ModifierPrefix() .. key)
    end)
    overlay:SetScript("OnMouseDown", function(self, button)
        if not bindMode then return end
        if button == "RightButton" then
            ClearBinding(self.entry)
            return
        end
        local mapped = MOUSE_MAP[button]
        if mapped then ApplyBinding(self.entry, ModifierPrefix() .. mapped) end
    end)

    overlays[entry] = overlay
    return overlay
end

function H.IsBindMode() return bindMode end

function H.SetBindMode(on)
    on = on and true or false
    if bindMode == on then return bindMode end

    if on and InCombatLockdown() then
        Say(L() and L()["hotkey_combat_blocked"])
        return false
    end

    bindMode = on
    local ABE = TomoMod_ABEngine

    if on then
        if ABE and ABE.Entries then
            for entry in ABE.Entries() do
                local overlay = BuildOverlay(entry)
                if overlay then
                    local key = H.GetKey(entry)
                    overlay.label:SetText(type(key) == "string" and Abbreviate(key) or "")
                    overlay:Show()
                end
            end
        end
        Say(L() and L()["hotkey_bind_enter"])
    else
        hovered = nil
        for entry, overlay in pairs(overlays) do
            overlay:SetPropagateKeyboardInput(true)
            overlay:Hide()
        end
        SaveNow()
        H.RenderAll()
        Say(L() and L()["hotkey_bind_exit"])
    end

    return bindMode
end

function H.ToggleBindMode() return H.SetBindMode(not bindMode) end

-- =====================================================================
-- ENGINE BINDING + EVENTS
-- =====================================================================

local bound = false

local function OnEntry(entry) Render(entry) end

local function OnUnregister(entry)
    local fs = texts[entry]
    if fs then fs:Hide(); texts[entry] = nil end
    local overlay = overlays[entry]
    if overlay then overlay:Hide(); overlays[entry] = nil end
    if entry._blizzHotkey then pcall(entry._blizzHotkey.SetAlpha, entry._blizzHotkey, 1) end
end

function H.Bind()
    if bound then return end
    local ABE = TomoMod_ABEngine
    if not ABE or not ABE.RegisterCallback then return end
    bound = true
    ABE.RegisterCallback("ABHotkey", "register",   OnEntry)
    ABE.RegisterCallback("ABHotkey", "action",     OnEntry)
    ABE.RegisterCallback("ABHotkey", "unregister", OnUnregister)
end

function H.IsBound() return bound end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        -- Bindings cannot be written in combat; leave the mode rather than
        -- pretend it still works.
        if bindMode then H.SetBindMode(false) end
        return
    end
    local ABB = TomoMod_ABButton
    if ABB and ABB.RefreshBindings then ABB.RefreshBindings() end
    H.RenderAll()
end)

-- =====================================================================
-- BOOT
-- =====================================================================

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    C_Timer.After(0.9, function()
        H.Bind()
        C_Timer.After(0.5, H.RenderAll)
    end)
end)

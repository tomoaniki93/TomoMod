-- =====================================================================
-- AB_KeyBound.lua v1.0.0 -- LibKeyBound-1.0 integration (Lot A9)
--
-- SOFT dependency. TomoMod does not ship LibKeyBound: if another addon in
-- the profile provides it (Dominos, Bartender4, Bagnon, ...), TomoMod's bars
-- join its shared binding mode. If nothing provides it, this file does
-- nothing at all and the native binding mode from Lot A4 remains the only
-- one -- no error, no missing feature, no hooks installed.
--
-- The proxy pattern is lifted from Dominos: rather than mixing six library
-- methods into every action button, one hidden frame carries them and is
-- reparented onto whichever button the mouse is over. LibKeyBound only ever
-- talks to that frame.
--
-- All binding reads and writes go through AB_Hotkey.GetBindingName, so this
-- works identically on TomoMod-owned buttons (which bind through their own
-- CLICK command, Lot A8) and on reparented Blizzard ones (which bind through
-- ACTIONBUTTON / MULTIACTIONBAR names).
-- =====================================================================

TomoMod_ABKeyBound = TomoMod_ABKeyBound or {}
local K = TomoMod_ABKeyBound

local KB = LibStub and LibStub("LibKeyBound-1.0", true)

function K.IsAvailable() return KB ~= nil end

if not KB then
    -- Keep the ENTIRE public surface stable so nothing has to test for the
    -- library before calling in. Every entry point becomes a no-op.
    function K.Toggle()   return false end
    function K.IsActive() return false end
    function K.Bind()     return false end
    function K.IsBound()  return false end
    function K.HookAll()  end
    return
end

-- =====================================================================
-- PROXY
-- =====================================================================

local proxy = CreateFrame("Frame", "TomoModABKeyBoundProxy", UIParent)
proxy:Hide()

local function Owner()
    local button = proxy:GetParent()
    if not button or button == UIParent then return nil, nil end
    local ABE = TomoMod_ABEngine
    local entry = ABE and ABE.GetEntry and ABE.GetEntry(button) or nil
    return entry, button
end

local function BindingCommand()
    local entry = Owner()
    if not entry then return nil end
    local H = TomoMod_ABHotkey
    if not H or not H.GetBindingName then return nil end
    return H.GetBindingName(entry)
end

function proxy:GetHotkey()
    local entry = Owner()
    if not entry then return "" end
    local H = TomoMod_ABHotkey
    local key = H and H.GetKey and H.GetKey(entry)
    if type(key) ~= "string" or key == "" then return "" end
    return KB:ToShortKey(key)
end

function proxy:SetKey(key)
    if InCombatLockdown() then return end
    local command = BindingCommand()
    if not command or not key then return end
    pcall(SetBinding, key, command)
    local H = TomoMod_ABHotkey
    if H and H.RenderAll then H.RenderAll() end
end

function proxy:GetBindings()
    local command = BindingCommand()
    if not command then return nil end
    local ok, k1, k2 = pcall(GetBindingKey, command)
    if not ok then return nil end
    if type(k1) ~= "string" or k1 == "" then return nil end
    if type(k2) == "string" and k2 ~= "" then
        return k1 .. " " .. k2
    end
    return k1
end

-- Optional in the library's contract, but we must provide it. Without it
-- LibKeyBound falls back to comparing GetBindingAction(key) against
-- format("CLICK %s:LeftButton", button:GetName()) -- which for us is neither
-- the right button name (the proxy's) nor the right virtual button (:HOTKEY),
-- so it would report every key as stolen from somewhere else.
local lastFreed = {}

function proxy:FreeKey(key)
    if InCombatLockdown() or not key then return nil end

    local mine = BindingCommand()
    local ok, action = pcall(GetBindingAction, key)

    if not ok or type(action) ~= "string" or action == "" then
        -- The library calls FreeKey twice in a row for the same key; on the
        -- second call it is already free, so answer from the first result to
        -- keep the "unbound from X" message accurate.
        local remembered = lastFreed[key]
        lastFreed[key] = nil
        return remembered
    end

    if action == mine then return nil end

    pcall(SetBinding, key, nil)
    lastFreed[key] = action
    return action
end

function proxy:ClearBindings()
    if InCombatLockdown() then return end
    local command = BindingCommand()
    if not command then return end
    while true do
        local ok, key = pcall(GetBindingKey, command)
        if not ok or type(key) ~= "string" or key == "" then break end
        pcall(SetBinding, key, nil)
    end
    local H = TomoMod_ABHotkey
    if H and H.RenderAll then H.RenderAll() end
end

-- What LibKeyBound shows in its tooltip. The spell or item currently in the
-- slot is far more useful than the slot number, so prefer it.
function proxy:GetActionName()
    local entry, button = Owner()
    if not entry then return UNKNOWN or "?" end

    local ABE = TomoMod_ABEngine
    local content = ABE and ABE.GetContentCached and ABE.GetContentCached(entry) or nil

    if content then
        if content.macroText and content.macroText ~= "" then return content.macroText end
        if content.spellID and C_Spell and C_Spell.GetSpellName then
            local ok, spellName = pcall(C_Spell.GetSpellName, content.spellID)
            if ok and type(spellName) == "string" and spellName ~= "" then return spellName end
        end
        if content.itemID and C_Item and C_Item.GetItemNameByID then
            local ok, itemName = pcall(C_Item.GetItemNameByID, content.itemID)
            if ok and type(itemName) == "string" and itemName ~= "" then return itemName end
        end
    end

    local L = TomoMod_L
    if L and entry.barId and entry.index then
        local n = tonumber(tostring(entry.barId):match("^bar(%d+)$"))
        if n then return string.format(L["binding_button"], n, entry.index) end
    end
    return (button and button.GetName and button:GetName()) or (UNKNOWN or "?")
end

-- The library prints button:GetName() when it confirms a binding. Reporting
-- the proxy's own name there would be meaningless, so forward the real one.
function proxy:GetName()
    local _, button = Owner()
    if button and button.GetName then
        local name = button:GetName()
        if name then return name end
    end
    return "TomoModABKeyBoundProxy"
end

proxy:SetScript("OnLeave", function(self)
    self:ClearAllPoints()
    self:SetParent(UIParent)
    self:Hide()
end)

-- =====================================================================
-- HOVER WIRING
-- HookScript rather than SetScript: the reparented Blizzard buttons have
-- their own OnEnter and we must not replace it. This is the same thing
-- Dominos does, and no hook is installed at all when the library is absent.
-- =====================================================================

local function OnEnterHook(self)
    if not KB:IsShown() then return end
    proxy:ClearAllPoints()
    proxy:SetParent(self)
    proxy:SetAllPoints(self)
    proxy:Show()
    KB:Set(proxy)
end

local function HookButton(entry)
    local button = entry and entry.frame
    if not button or button._tomoKBHooked then return end
    if not button.HookScript then return end
    button._tomoKBHooked = true
    button:HookScript("OnEnter", OnEnterHook)
end

function K.HookAll()
    local ABE = TomoMod_ABEngine
    if not ABE or not ABE.Entries then return end
    for entry in ABE.Entries() do HookButton(entry) end
end

-- =====================================================================
-- MODE
-- =====================================================================

function K.IsActive()
    local ok, res = pcall(KB.IsShown, KB)
    return (ok and res) and true or false
end

function K.Toggle()
    if K.IsActive() then
        pcall(KB.Deactivate, KB)
    else
        pcall(KB.Activate, KB)
    end
    return K.IsActive()
end

-- =====================================================================
-- BINDING
-- =====================================================================

local bound = false

function K.Bind()
    if bound then return end
    local ABE = TomoMod_ABEngine
    if not ABE or not ABE.RegisterCallback then return end
    bound = true

    ABE.RegisterCallback("ABKeyBound", "register", HookButton)
    K.HookAll()

    KB.RegisterCallback(K, "LIBKEYBOUND_ENABLED", function()
        -- Two binding modes at once would fight over the same keypress.
        local H = TomoMod_ABHotkey
        if H and H.IsBindMode and H.IsBindMode() then H.SetBindMode(false) end
        if H and H.RenderAll then H.RenderAll() end
    end)

    KB.RegisterCallback(K, "LIBKEYBOUND_DISABLED", function()
        local H = TomoMod_ABHotkey
        if H and H.RenderAll then H.RenderAll() end
    end)
end

function K.IsBound() return bound end

-- =====================================================================
-- BOOT
-- =====================================================================

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    C_Timer.After(1.5, K.Bind)
end)

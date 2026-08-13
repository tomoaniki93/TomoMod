-- =====================================================================
-- AB_Button.lua v1.0.0 -- TomoMod-owned action buttons (Lot A6.1)
--
-- Creates real SecureActionButtonTemplate buttons owned by TomoMod, as an
-- alternative to reparenting Blizzard's. Opt-in PER BAR, off everywhere by
-- default, and reversible: untick the option, /reload, and the bar goes
-- back to Blizzard buttons.
--
-- Everything built in Lots A1-A5 works unchanged on these buttons, because
-- they register with the engine under the same "action" adapter: the adapter
-- reads frame.action and falls back to GetAttribute("action"), and we set
-- only the attribute. That is the whole point of having built the engine
-- first.
--
-- The secure plumbing is NOT reinvented here. ActionBars.lua already owns a
-- working paging setup (BuildPagingCondition + control:ChildUpdate("offset")
-- + the CHILD_UPDATE_OFFSET snippet, including IsPressHoldReleaseSpell), and
-- these buttons simply receive the same attributes Blizzard's do.
--
-- NOT COVERED BY A6.1 -- read this before enabling a bar:
--   * Flyouts (mage portals, hunter traps, summon flasks). A flyout slot on
--     a converted bar will not open its flyout.
--   * Vehicle / override / possess bar CONTENT. Paging follows, but the
--     specialised vehicle exit button and its artwork do not.
--   * Assisted Combat highlight. Blizzard draws it on its own buttons; use
--     the rotation glow from Lot A3 instead.
--   * Pet and stance bars. Those stay on Blizzard buttons.
-- =====================================================================

TomoMod_ABButton = TomoMod_ABButton or {}
local ABB = TomoMod_ABButton

local WHITE = "Interface\\Buttons\\WHITE8X8"

-- Virtual mouse button used by our click bindings. A dedicated name (rather
-- than LeftButton) is what makes cast-on-key-press behave: Bartender4
-- migrated away from LeftButton for exactly this reason.
local HOTKEY_BUTTON = "HOTKEY"

function ABB.ClickCommand(button)
    local name = button and button.GetName and button:GetName()
    if not name then return nil end
    return "CLICK " .. name .. ":" .. HOTKEY_BUTTON
end

-- =====================================================================
-- SLOT RESOLUTION
--
-- The authoritative source is the Blizzard counterpart button: whatever
-- action slot Blizzard assigned to MultiBarLeftButton3 is the slot our
-- replacement must drive. That sidesteps hardcoding slot ranges, which have
-- moved between expansions. The table below is only a fallback for the case
-- where the Blizzard button is missing.
-- =====================================================================

local SLOT_BASE_FALLBACK = {
    bar1 = 0,   bar2 = 60,  bar3 = 48,  bar4 = 24,
    bar5 = 36,  bar6 = 144, bar7 = 156, bar8 = 168,
}

function ABB.ResolveSlot(def, index)
    local blizz = _G[def.prefix .. index]
    if blizz then
        local slot = blizz.action
        if type(slot) ~= "number" and blizz.GetAttribute then
            local ok, res = pcall(blizz.GetAttribute, blizz, "action")
            if ok then slot = res end
        end
        if type(slot) == "number" and slot > 0 then return slot end
    end
    local base = SLOT_BASE_FALLBACK[def.id]
    if base then return base + index end
    return index
end

-- =====================================================================
-- CREATION
-- =====================================================================

local owned = {}   -- barId -> { button, ... }

-- Declared up here because ReleaseBar (below) has to undo a delegation, and
-- Lua resolves an undeclared local to a global: keeping these next to `owned`
-- is what makes that reference bind to the real table.
local delegated = {}          -- our button -> Blizzard button
local pendingDelegation = {}  -- our button -> wanted state, deferred out of combat
local ApplyDelegation         -- forward declaration, defined in the flyout section

local function ApplyClickRegistration(button)
    local down = false
    if GetCVarBool then
        local ok, res = pcall(GetCVarBool, "ActionButtonUseKeyDown")
        down = (ok and res) and true or false
    end
    -- Both are registered so the secure "typerelease" path set by
    -- CHILD_UPDATE_OFFSET keeps working for press-and-hold spells.
    if down then
        button:RegisterForClicks("AnyDown", "AnyUp")
    else
        button:RegisterForClicks("AnyUp")
    end
end

local function BarsLocked()
    if not GetCVarBool then return true end
    local ok, res = pcall(GetCVarBool, "lockActionBars")
    if not ok then return true end
    return res and true or false
end

local function OnDragStart(self)
    if InCombatLockdown() then return end
    if BarsLocked() and not IsModifiedClick("PICKUPACTION") then return end
    local slot = self:GetAttribute("action")
    if type(slot) == "number" then pcall(PickupAction, slot) end
end

local function OnReceiveDrag(self)
    if InCombatLockdown() then return end
    local slot = self:GetAttribute("action")
    if type(slot) == "number" then pcall(PlaceAction, slot) end
end

local function RefreshTexture(button)
    if not button or not button.icon then return end
    local slot = button:GetAttribute("action")
    if type(slot) ~= "number" then
        button.icon:SetTexture(nil)
        return
    end

    if GetActionTexture then
        local tex = GetActionTexture(slot)
        if type(tex) == "string" and tex ~= "" then
            button.icon:SetTexture(tex)
            button.icon:Show()
        else
            button.icon:SetTexture(nil)
            button.icon:Hide()
        end
    end
end

local function OnEnter(self)
    local slot = self:GetAttribute("action")
    if type(slot) ~= "number" then return end
    RefreshTexture(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    pcall(GameTooltip.SetAction, GameTooltip, slot)
    ABB._tooltipOwner = self
end

local function OnLeave(self)
    if ABB._tooltipOwner == self then ABB._tooltipOwner = nil end
    GameTooltip:Hide()
end

local function OnPostClick(self)
    local ABE = TomoMod_ABEngine
    RefreshTexture(self)
    if ABE and ABE.RefreshButton then ABE.RefreshButton(self) end
end

function ABB.Create(def, container, index)
    local name = "TomoModAB_" .. def.id .. "_" .. index
    local button = _G[name]

    if not button then
        button = CreateFrame("CheckButton", name, container, "SecureActionButtonTemplate")

        -- Regions the A2-A5 layers expect to find. AB_Render adopts .icon and
        -- .cooldown; AB_Hotkey and AB_Special create their own on top.
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        button.icon = icon

        local cd = CreateFrame("Cooldown", name .. "Cooldown", button, "CooldownFrameTemplate")
        cd:SetAllPoints(icon)
        button.cooldown = cd

        -- Plain white so ActionBarSkin can recolour them like it does
        -- Blizzard's; without these the button would have no hover, pushed
        -- or checked feedback at all.
        button:SetHighlightTexture(WHITE)
        button:SetPushedTexture(WHITE)
        button:SetCheckedTexture(WHITE)
        local hl = button:GetHighlightTexture()
        if hl then hl:SetColorTexture(1, 1, 1, 0.10) end
        local pu = button:GetPushedTexture()
        if pu then pu:SetColorTexture(0, 0, 0, 0.30) end
        local ck = button:GetCheckedTexture()
        if ck then ck:SetColorTexture(1, 1, 1, 0.14) end

        button:RegisterForDrag("LeftButton")
        button:SetScript("OnDragStart", OnDragStart)
        button:SetScript("OnReceiveDrag", OnReceiveDrag)
        button:SetScript("OnEnter", OnEnter)
        button:SetScript("OnLeave", OnLeave)
        button:SetScript("PostClick", OnPostClick)
    else
        button:SetParent(container)
    end

    ApplyClickRegistration(button)

    if not InCombatLockdown() then
        button:SetAttribute("type", "action")
        button:SetAttribute("checkselfcast", true)
        button:SetAttribute("checkfocuscast", true)
        button:SetAttribute("useparent-unit", true)
        button:SetAttribute("index", index)
        button:SetAttribute("action", ABB.ResolveSlot(def, index))

        -- Without this the up-click of a key press would fire the action a
        -- second time. Blizzard's own answer is typerelease + pressAndHoldAction;
        -- the paging snippet sets them on bar 1, so every other bar needs them
        -- set here and refreshed whenever the slot's spell changes.
        button:SetAttribute("typerelease", "actionrelease")

        if def.paging then
            local AB = TomoMod_ActionBars
            local snippet = AB and AB.CHILD_UPDATE_OFFSET
            if snippet then
                button:SetAttribute("_childupdate-offset", snippet)
            end
        end

        RefreshTexture(button)
    end

    button:Show()
    return button
end

function ABB.BuildBar(def, container)
    local list = {}
    for i = 1, def.count do
        list[i] = ABB.Create(def, container, i)
    end
    owned[def.id] = list
    return list
end

function ABB.ReleaseBar(barId)
    local list = owned[barId]
    if not list then return end
    for i = 1, #list do
        local b = list[i]
        if b then
            if delegated[b] then ApplyDelegation(b, false) end
            b:Hide()
            local ABE = TomoMod_ABEngine
            if ABE and ABE.UnregisterButton then ABE.UnregisterButton(b) end
        end
    end
    owned[barId] = nil
end

function ABB.IsOwnButton(frame)
    if not frame then return false end
    local barId = frame._tomoBarId
    local list = barId and owned[barId]
    if not list then return false end
    for i = 1, #list do
        if list[i] == frame then return true end
    end
    return false
end

function ABB.GetButtons(barId) return owned[barId] end
function ABB.IsOwned(barId) return owned[barId] ~= nil end

-- =====================================================================
-- EMPTY SLOT VISIBILITY
-- Blizzard's "showgrid" attribute is handled by ActionBarButtonMixin, which
-- our buttons do not inherit, so we do it ourselves.
-- =====================================================================

-- Mirrors what the paging snippet does, for the bars that have no paging.
local function UpdatePressAndHold(button)
    if InCombatLockdown() then return end
    if not IsPressHoldReleaseSpell then return end
    local slot = button:GetAttribute("action")
    if type(slot) ~= "number" then return end

    local pressAndHold = false
    local ok, actionType, id, subType = pcall(GetActionInfo, slot)
    if ok and actionType == "spell" then
        local ok2, res = pcall(IsPressHoldReleaseSpell, id)
        pressAndHold = (ok2 and res) and true or false
    elseif ok and actionType == "macro" and subType == "spell" then
        local ok2, res = pcall(IsPressHoldReleaseSpell, id)
        pressAndHold = (ok2 and res) and true or false
    end
    button:SetAttribute("pressAndHoldAction", pressAndHold)
end

local function UpdateVisibility(button)
    local AB = TomoMod_ActionBars
    if not AB or not AB.GetBarDB then return end
    local barId = button._tomoBarId
    if not barId then return end
    local barDB = AB.GetBarDB(barId)
    if barDB and barDB.showEmptyButtons then
        button:Show()
        return
    end
    local slot = button:GetAttribute("action")
    local has = false
    if type(slot) == "number" then
        local ok, res = pcall(HasAction, slot)
        has = (ok and res) and true or false
    end
    button:SetShown(has)
end

function ABB.UpdateVisibilityAll()
    for barId, list in pairs(owned) do
        for i = 1, #list do
            list[i]._tomoBarId = barId
            UpdateVisibility(list[i])
        end
    end
end

-- =====================================================================
-- FLYOUT DELEGATION
--
-- Flyouts are the one thing a hand-rolled secure button cannot fake. The
-- native path is a documented minefield: type="flyout" on an addon-created
-- SecureActionButtonTemplate has thrown errors for years, and SpellFlyout
-- ignores flyoutDirection whenever isActionBar is set, which it always is for
-- secure buttons. The reference implementation (LibActionButton) answers this
-- by reimplementing the entire flyout with its own secure handler frame --
-- several hundred lines of secure snippets that cannot be tested outside the
-- game.
--
-- So we do not fake it. For a slot that holds a flyout, that ONE grid position
-- is handed back to Blizzard's own button, which handles flyouts correctly by
-- construction. Our button stays laid out but hidden, and the Blizzard button
-- is anchored to it, so every layout change (size, spacing, position, scale)
-- still flows through LayoutBar exactly as before.
-- =====================================================================

local function BlizzCounterpart(barId, index)
    local AB = TomoMod_ActionBars
    local def = AB and AB.GetDef and AB.GetDef(barId)
    if not def then return nil end
    return _G[def.prefix .. index], def
end

ApplyDelegation = function(button, wanted)
    local barId = button._tomoBarId
    local index = button:GetAttribute("index")
    if not barId or type(index) ~= "number" then return end

    local current = delegated[button] and true or false
    if current == wanted then return end

    if InCombatLockdown() then
        -- SetParent is protected; defer rather than half-apply.
        pendingDelegation[button] = wanted
        return
    end
    pendingDelegation[button] = nil

    local blizz, def = BlizzCounterpart(barId, index)
    if not blizz then return end

    local ABE = TomoMod_ABEngine
    local ABS = TomoMod_ActionBarSkin

    if wanted then
        delegated[button] = blizz
        button:Hide()

        blizz:SetParent(button:GetParent())
        blizz:ClearAllPoints()
        blizz:SetAllPoints(button)
        blizz:Show()

        if ABS and ABS.SkinOne then ABS.SkinOne(blizz) end
        if ABE and ABE.RegisterButton then
            ABE.RegisterButton(blizz, "action", barId, index)
            if ABE.RefreshButton then ABE.RefreshButton(blizz) end
        end
    else
        delegated[button] = nil

        if ABE and ABE.UnregisterButton then ABE.UnregisterButton(blizz) end
        if ABS and ABS.UnskinOne then ABS.UnskinOne(blizz) end

        blizz:ClearAllPoints()
        blizz:Hide()
        local home = def and _G[def.blizzFrame]
        if home then blizz:SetParent(home) end

        button:Show()
        UpdateVisibility(button)
    end
end

local function IsFlyoutEntry(entry)
    local ABE = TomoMod_ABEngine
    if not ABE or not ABE.GetContentCached then return false end
    local content = ABE.GetContentCached(entry)
    return content ~= nil and content.actionType == "flyout"
end

function ABB.IsDelegated(button) return delegated[button] ~= nil end

function ABB.RefreshDelegation()
    local ABE = TomoMod_ABEngine
    if not ABE or not ABE.Entries then return end
    for entry in ABE.Entries() do
        local button = entry.frame
        if button and button._tomoBarId and not delegated[button] then
            -- Only our own buttons drive delegation; the Blizzard button we
            -- delegated TO also has an entry and must be skipped.
            if owned[button._tomoBarId] then
                local isOurs = false
                local list = owned[button._tomoBarId]
                for i = 1, #list do
                    if list[i] == button then isOurs = true; break end
                end
                if isOurs then ApplyDelegation(button, IsFlyoutEntry(entry)) end
            end
        end
    end
end

-- =====================================================================
-- OVERRIDE BINDINGS
-- Blizzard's hidden buttons keep their own bindings, and since they point at
-- the same action slot the spell still fires without this. What the override
-- buys is that OUR button receives the click, so it gets the pushed state,
-- the PostClick refresh and the correct tooltip anchor.
-- =====================================================================

local bindHeader

local function GetBindHeader()
    if not bindHeader then
        bindHeader = CreateFrame("Frame", "TomoModABBindHeader", UIParent,
            "SecureHandlerBaseTemplate")
    end
    return bindHeader
end

function ABB.RefreshBindings()
    if InCombatLockdown() then return false end
    local header = GetBindHeader()
    pcall(ClearOverrideBindings, header)

    local HK = TomoMod_ABHotkey
    local formats = HK and HK.BINDING
    if not formats then return false end

    for barId, list in pairs(owned) do
        local fmt = formats[barId]
        if fmt then
            for i = 1, #list do
                local button = list[i]

                -- A key the player assigned to THIS button wins outright: it is
                -- a real binding in WoW's binding set and needs no bridge.
                local okOwn, ownKey = pcall(GetBindingKey, ABB.ClickCommand(button))
                local hasOwn = okOwn and type(ownKey) == "string" and ownKey ~= ""

                if not hasOwn then
                    -- Otherwise bridge the legacy Blizzard binding onto our
                    -- button, so an existing keybind keeps working AND lights
                    -- the right button, without rewriting the player's config.
                    local ok, k1, k2 = pcall(GetBindingKey, string.format(fmt, i))
                    if ok then
                        if type(k1) == "string" and k1 ~= "" then
                            pcall(SetOverrideBindingClick, header, false, k1,
                                button:GetName(), HOTKEY_BUTTON)
                        end
                        if type(k2) == "string" and k2 ~= "" then
                            pcall(SetOverrideBindingClick, header, false, k2,
                                button:GetName(), HOTKEY_BUTTON)
                        end
                    end
                end
            end
        end
    end
    return true
end

-- =====================================================================
-- EVENTS
-- =====================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("CVAR_UPDATE")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "CVAR_UPDATE" then
        if arg1 ~= "ActionButtonUseKeyDown" and arg1 ~= "lockActionBars" then return end
        if InCombatLockdown() then return end
        for _, list in pairs(owned) do
            for i = 1, #list do ApplyClickRegistration(list[i]) end
        end
        return
    end
    if InCombatLockdown() then return end
    if next(pendingDelegation) then
        local todo = {}
        for button, wanted in pairs(pendingDelegation) do todo[button] = wanted end
        for button, wanted in pairs(todo) do ApplyDelegation(button, wanted) end
    end
    ABB.RefreshBindings()
end)

-- =====================================================================
-- ENGINE BINDING
-- =====================================================================

local bound = false

local function OnAction(entry)
    local button = entry.frame
    if not button or not button._tomoBarId then return end
    local list = owned[button._tomoBarId]
    local isOurs = false
    if list then
        for i = 1, #list do
            if list[i] == button then isOurs = true; break end
        end
    end
    if isOurs then
        ApplyDelegation(button, IsFlyoutEntry(entry))
        if not delegated[button] then
            UpdateVisibility(button)
            UpdatePressAndHold(button)
        end
    end
end

function ABB.Bind()
    if bound then return end
    local ABE = TomoMod_ABEngine
    if not ABE or not ABE.RegisterCallback then return end
    bound = true
    ABE.RegisterCallback("ABButton", "action", OnAction)
end

function ABB.IsBound() return bound end

-- =====================================================================
-- BINDING LABELS
-- Bindings.xml declares the commands so they appear in Blizzard's keybinding
-- UI; these globals give them readable names there.
-- =====================================================================

function ABB.SetupBindingNames()
    local L = TomoMod_L
    if not L then return end

    _G["BINDING_CATEGORY_TOMOMOD"] = L["binding_category"]

    local AB = TomoMod_ActionBars
    local defs = AB and AB.BAR_DEFS
    if not defs then return end

    for _, def in ipairs(defs) do
        local n = tonumber(def.id:match("^bar(%d+)$"))
        if n then
            _G["BINDING_HEADER_TOMOMOD_BAR" .. n] = string.format(L["binding_bar_header"], n)
            for i = 1, def.count do
                _G[string.format("BINDING_NAME_CLICK TomoModAB_bar%d_%d:HOTKEY", n, i)] =
                    string.format(L["binding_button"], n, i)
            end
        end
    end
end

-- =====================================================================
-- BOOT
-- =====================================================================

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    C_Timer.After(1.4, function()
        ABB.SetupBindingNames()
        ABB.Bind()
        ABB.UpdateVisibilityAll()
        ABB.RefreshDelegation()
        ABB.RefreshBindings()
    end)
end)

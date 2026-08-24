-- =====================================================================
-- Ported from Tui: TUI_ActionBars/actionbars/actionbars_builder.lua
--
-- Every edit made to this file is marked with "TOMOMOD:" so upstream changes
-- stay diffable. Do not reformat: the point of keeping it verbatim is that a
-- newer Tui revision can be re-imported by replaying the same edits.
-- =====================================================================
local ADDON_NAME, ns = "TomoMod", TomoMod_TuiNS -- TOMOMOD: was `...`
local env = ns.ActionBarsEnv
env.ADDON_NAME = ADDON_NAME
env.ns = ns
env.SetChunkEnv(1, env)

---@diagnostic disable: lowercase-global -- SetChunkEnv installs a setfenv

function GetOriginalBlizzButtons(barKey)
    local buttons = {}
    local pattern = BUTTON_PATTERNS[barKey]
    local count = BUTTON_COUNTS[barKey] or 12
    if not pattern then return buttons end
    for i = 1, count do
        local buttonName = string.format(pattern, i)
        local button = _G[buttonName]
        if button then
            table.insert(buttons, button)
        end
    end
    return buttons
end

function SharedOwnedButtonPostDrag(self)
    OwnedButton_PostDrag(self)
end

-- Midnight 12.1:
-- Never let addon-owned standard buttons enter Blizzard's native action-button
-- registries in the first place. ActionBarButtonTemplate runs
-- ActionBarActionButtonMixin:OnLoad(), which unconditionally inserts the new
-- frame into ActionBarButtonEventsFrame.frames. ActionBarController_UpdateAll()
-- later iterates that exact table during Druid/bonus/vehicle paging. Removing an
-- addon-created entry afterwards still leaves us writing Blizzard-owned registry
-- state and can taint every native ActionButton update that follows.
--
-- Blizzard's own BaseActionButtonMixin documents the supported addon pattern:
-- use ActionButtonTemplate + SecureActionButtonTemplate for a bare secure action
-- button. That keeps the stock visuals/flyout surface but DOES NOT run the native
-- ActionBarActionButton OnLoad registration path. TUI already owns refreshing,
-- cooldowns, usability, paging and keybinds, so no native broadcaster membership
-- is required.
function DetachOwnedActionButtonFromBlizzardRegistries(btn)
    -- Intentionally no-op. A TUI standard button must never have been
    -- registered with the Blizzard ActionBar registries, so there is nothing to
    -- remove and, critically, no Blizzard-owned table is ever written here.
end

local function InstallBareOwnedActionButtonMethods(btn)
    if not btn then return end

    -- ActionButtonTemplate supplies icon/Count/Name/Border/Flash/cooldown and the
    -- BaseActionButton flyout helpers, but not ActionBarActionButtonMixin methods.
    -- TUI only needs these tiny visual helpers; keeping them local prevents the
    -- Blizzard mixin from registering the button in any native update frame.
    if not btn.UpdateCount then
        btn.UpdateCount = function(self)
            if not self.Count then return end
            local action = GetSafeActionSlot(self)
            if not action or (Helpers.IsSecretValue and Helpers.IsSecretValue(action)) then
                self.Count:SetText("")
                return
            end
            local fn = C_ActionBar and C_ActionBar.GetActionDisplayCount
            if not fn then
                self.Count:SetText("")
                return
            end
            local ok, count = pcall(fn, action, self.maxDisplayCount)
            if ok then
                self.Count:SetText(count or "")
            end
        end
    end

    if not btn.StartFlash then
        btn.StartFlash = function(self)
            self.flashing = 1
            self.flashtime = 0
            if self.Flash then self.Flash:Show() end
        end
    end

    if not btn.StopFlash then
        btn.StopFlash = function(self)
            self.flashing = 0
            self.flashtime = 0
            if self.Flash then self.Flash:Hide() end
        end
    end
end

function EnsureOwnedActionButton(container, barKey, btnName, index)
    local btn = _G[btnName]
    local existed = btn ~= nil
    if not btn then
        local ok
        ok, btn = ns.SafeCall("best-effort-style", CreateFrame, "CheckButton", btnName, container, "ActionButtonTemplate,SecureActionButtonTemplate")
        if not ok then btn = _G[btnName] end
        InstallBareOwnedActionButtonMethods(btn)
        -- ActionButtonTemplate carries a cosmetic OnAttributeChanged handler.
        -- TUI owns action changes and flyout refreshes itself; remove that Lua
        -- callback before installing our restricted secure wrapper below so an
        -- in-combat page change never re-enters Blizzard ActionButton Lua.
        if btn and btn.SetScript then btn:SetScript("OnAttributeChanged", nil) end
        btn:SetAttribute("type", "action")
        -- TOMOMOD INPUT HOTFIX:
        -- The bare ActionButtonTemplate + SecureActionButtonTemplate combination
        -- intentionally skips ActionBarActionButtonMixin:OnLoad() to stay out of
        -- Blizzard's native action-button registries. Recreate the secure
        -- press/release attribute that Blizzard normally initializes there.
        --
        -- Keep RegisterForClicks("AnyDown", "AnyUp") below: TUI keybinds are
        -- routed through secure click bindings and need both phases (notably for
        -- press/hold/release spells).
        btn:SetAttribute("typerelease", "actionrelease")
        btn:SetAttribute("checkselfcast", true)
        btn:SetAttribute("checkfocuscast", true)
        btn:SetAttribute("checkmouseovercast", true)
        btn:SetAttribute("useparent-unit", true)
        btn:SetAttribute("useparent-actionpage", true)
        btn:RegisterForDrag("LeftButton", "RightButton")
        btn:RegisterForClicks("AnyDown", "AnyUp")
        do
            local _db = GetDB()
            local _g = _db and _db.global
            btn:SetAttribute("useOnKeyDown", not _g or _g.useOnKeyDown ~= false)
        end
        -- ActionButtonTemplate already inherits Blizzard's FlyoutButtonTemplate.
        -- Do not install addon-owned popup methods here: SpellFlyout:Toggle()
        -- calls the source button's popup API before populating native popup
        -- buttons, so replacing that API widens the taint path to CastSpellByID.
        -- BaseActionButtonMixin.UpdateFlyout explicitly supports this bare
        -- ActionButtonTemplate + SecureActionButtonTemplate combination.
        btn.flashing = 0
        btn.flashtime = 0

    else
        btn:SetParent(container)
        InstallBareOwnedActionButtonMethods(btn)
    end
    btn._tomomodBarKey = barKey
    btn._tomomodButtonIndex = index
    btn:SetAttribute("qui-button-index", index)

    btn:SetAttribute("qui-refresh-ref", "btn-refresh-" .. barKey .. "-" .. index)
    InstallSecureActionFlagRefresh(btn)
    return btn, existed
end

function SetupPagedOwnedActionButton(container, btn, index)
    btn:SetAttribute("index", index)
    btn:SetAttribute("_childupdate-offset", [[
        local index = self:GetAttribute("index")
        local newAction = index + (message or 0)
        self:SetAttribute("action", newAction)
        self:RunAttribute("TUI_UpdateActionFlags")
    ]])
    SetupFixedOwnedActionButton(container, btn, index)
end

function SetupFixedOwnedActionButton(container, btn, action)
    container:SetFrameRef("init-btn", btn)
    container:Execute(string.format([[
        local btn = self:GetFrameRef("init-btn")
        btn:SetAttribute("action", %d)
        btn:RunAttribute("TUI_UpdateActionFlags")
    ]], action))
end

function FinalizeStandardOwnedActionButtons(container, barKey, buttons)
    SetupSecureActionFlagRefresh(container)
    for i, btn in ipairs(buttons) do
        container:SetFrameRef("btn-refresh-" .. barKey .. "-" .. i, btn)
    end
end

function BuildStandardOwnedButtons(container, barKey)
    local buttons = {}

    if barKey == "bar1" then
        for i = 1, 12 do
            local btnName = "TUI_Bar1Button" .. i
            local btn, existed = EnsureOwnedActionButton(container, barKey, btnName, i)
            if not existed then
                SetupPagedOwnedActionButton(container, btn, i)
            end
            btn:Show()
            buttons[i] = btn
        end
        SetupBar1Paging(container)
        return buttons
    end

    local offset = BAR_ACTION_OFFSETS[barKey] or 0
    local barNum = barKey:sub(4)
    for i = 1, 12 do
        local btnName = "TUI_Bar" .. barNum .. "Button" .. i
        local btn, existed = EnsureOwnedActionButton(container, barKey, btnName, i)
        local action = offset + i
        if not existed then
            SetupFixedOwnedActionButton(container, btn, action)
        end
        btn:Show()
        buttons[i] = btn
    end

    return buttons
end

function SetupStandardOwnedButtonRuntime(container, btn)
    btn:SetAttribute("buttonlock", GetCVar("lockActionBars") == "1")
    btn.TUI_PostDrag = SharedOwnedButtonPostDrag

    -- P3.2.2: pre-create TomoMod's unprotected glow wrapper while the secure
    -- action button is being built. Proc transitions can then start/stop only
    -- textures/animations in combat instead of creating a child frame there.
    if ns.NativeGlow and ns.NativeGlow.Prepare then
        ns.NativeGlow.Prepare(btn, "TomoMod_IconGlow")
    end

    if not btn.quiSecureHooksInstalled then
        btn.quiSecureHooksInstalled = true
        SecureHandlerWrapScript(btn, "OnAttributeChanged", btn, [[
            -- Do not re-enter TUI_UpdateActionFlags from the action
            -- attribute callback. The page ChildUpdate runs it immediately
            -- after the action write, and slot-content events trigger the
            -- dedicated secure refresh path. Running it here happened BEFORE
            -- Blizzard's original OnAttributeChanged and multiplied protected
            -- attribute callbacks inside the same combat state-driver pass.
            if name == "action" then
                local container = self:GetParent()
                local flyoutHandler = container and container.GetFrameRef and container:GetFrameRef("qui-flyout-handler")
                if flyoutHandler and flyoutHandler:GetAttribute("flyoutParentHandle") == self then
                    local actionType, flyoutID = value and GetActionInfo(value)
                    if actionType ~= "flyout" or flyoutID ~= flyoutHandler:GetAttribute("flyoutID") then
                        flyoutHandler:Hide()
                    end
                end
            end
        ]])

        btn:HookScript("OnEnter", function(self)
            local global = GetGlobalSettings()
            if global and global.showTooltips == false then
                GameTooltip:Hide()
            end
        end)
        btn:HookScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        if container then
            SecureHandlerWrapScript(btn, "OnClick", container, [[
                local flyoutHandler = owner:GetFrameRef("qui-flyout-handler")
                if self:GetAttribute("type") == "action" then
                    local action = self:GetAttribute("action")
                    local actionType, flyoutID, subType = action and GetActionInfo(action)
                    if actionType == "flyout" and flyoutHandler then
                        if not down then
                            -- Use the live action-slot flyout first. Bar 1 can page
                            -- while in combat, so the cached attribute may describe the
                            -- previous page and must only be a fallback.
                            local effectiveFlyoutID = flyoutID or subType or self:GetAttribute("qui-flyout-id")
                            flyoutHandler:SetAttribute("flyoutParentHandle", self)
                            flyoutHandler:SetAttribute("flyoutID", effectiveFlyoutID)
                            flyoutHandler:RunAttribute("HandleFlyout")
                        end
                        return false
                    end
                    if flyoutHandler then
                        flyoutHandler:SetAttribute("flyoutID", nil)
                        flyoutHandler:Hide()
                    end
                    -- Pickup: a modified click on a locked bar should pick the
                    -- action up, not cast it, so temporarily clear on-down
                    -- casting (restored in the post-body). Done here in the
                    -- secure snippet rather than an insecure PreClick — an
                    -- insecure SetAttribute on useOnKeyDown taints the dispatch
                    -- and breaks AllowedWhenUntainted calls such as a /tm
                    -- macro's SetRaidTarget.
                    if button ~= "Keybind" and button ~= "Key"
                        and self:GetAttribute("buttonlock")
                        and IsModifiedClick("PICKUPACTION")
                        and not self:GetAttribute("LABdisableDragNDrop")
                        and self:GetAttribute("useOnKeyDown") then
                        self:SetAttribute("qui-keydown-restore", true)
                        self:SetAttribute("useOnKeyDown", false)
                    end
                elseif flyoutHandler and (not down or self:GetParent() ~= flyoutHandler) then
                    flyoutHandler:SetAttribute("flyoutID", nil)
                    flyoutHandler:Hide()
                end
                if button == "Keybind" or button == "Key" then
                    return "LeftButton"
                end
            ]], [[
                -- Restore on-down casting after a pickup click (see pre-body).
                if self:GetAttribute("qui-keydown-restore") then
                    self:SetAttribute("qui-keydown-restore", nil)
                    self:SetAttribute("useOnKeyDown", true)
                end
            ]])
        end

        btn:SetScript("OnDragStart", nil)
        SecureHandlerWrapScript(btn, "OnDragStart", btn, [[
            if (self:GetAttribute("buttonlock") and not IsModifiedClick("PICKUPACTION"))
                or self:GetAttribute("LABdisableDragNDrop") then
                return false
            end
            return "action", self:GetAttribute("action")
        ]])
        SecureHandlerWrapScript(btn, "OnDragStart", btn, [[
            return "message", "update"
        ]], [[
            self:CallMethod("TUI_PostDrag")
        ]])

        btn:SetScript("OnReceiveDrag", nil)
        SecureHandlerWrapScript(btn, "OnReceiveDrag", btn, [[
            if (self:GetAttribute("buttonlock") and not IsModifiedClick("PICKUPACTION"))
                or self:GetAttribute("LABdisableDragNDrop") then
                return false
            end
            return "action", self:GetAttribute("action")
        ]])
        SecureHandlerWrapScript(btn, "OnReceiveDrag", btn, [[
            return "message", "update"
        ]], [[
            self:CallMethod("TUI_PostDrag")
        ]])
    end
end

function PrimeStandardOwnedButtonVisuals(buttons)
    for _, btn in ipairs(buttons) do
        local barKey = btn and btn._tomomodBarKey
        if ShouldUseOwnedFlyoutForBar and ShouldUseOwnedFlyoutForBar(barKey) then
            -- Quarantined bar: never associate this button with Blizzard's
            -- native SpellFlyout. SafeUpdate covers the rest of the visuals
            -- while RefreshOwnedButtonFlyout() stays a no-op for it.
            if ActionBarsOwned.SafeUpdate then
                ActionBarsOwned.SafeUpdate(btn)
            end
        elseif ActionButton_Update and securecallfunction then
            -- Keep the initial Blizzard visual pass out of the addon-tainted call
            -- chain. ActionButton_Update reaches BaseActionButtonMixin.UpdateFlyout,
            -- which associates the button with the native SpellFlyout.
            securecallfunction(ActionButton_Update, btn)
        elseif ActionBarsOwned.SafeUpdate then
            -- WoW retail always provides securecallfunction; this fallback is
            -- intentionally TomoMod-only and does not enter native flyout Lua.
            ActionBarsOwned.SafeUpdate(btn)
        end
        ActionBarsOwned.UpdateCooldown(btn)
        ActionBarsOwned.UpdateOverlayGlow(btn)
    end
end

function BuildBar(barKey)
    if barKey == "microbar" then
        -- TOMOMOD 3.6.1 / Midnight 12.1:
        -- Keep Blizzard's MicroMenu completely native. Do not create a TomoMod
        -- container for it and do not enter the legacy reparent/layout/hook path
        -- below. TomoMod only keeps alpha-based mouseover presentation through
        -- actionbars_mouseover.lua.
        ActionBarsOwned.nativeButtons[barKey] = nil
        ActionBarsOwned.containers[barKey] = nil
        SetupBarMouseover(barKey)
        return
    end

    if barKey == "bags" then
        return
    end

    local barFrame = GetBarFrame(barKey)

    if not ActionBarsOwned.containers[barKey] then
        ActionBarsOwned.containers[barKey] = CreateBarContainer(barKey)
    end
    local container = ActionBarsOwned.containers[barKey]

    -- TOMOMOD 3.6.1: alpha-suppressed native bars still exist as mouse
    -- surfaces. Keep TUI's input-critical bars above those native surfaces by
    -- frame LEVEL, not by promoting the entire bar to HIGH strata. HIGH can
    -- render above Blizzard full-screen panels such as the World Map.
    -- Blizzard action bars normally live on MEDIUM; our higher frame levels
    -- are sufficient to keep TUI buttons on top within that strata.
    -- Possession uses bar1 paging, so bar1 is included here as well.
    if barKey == "bar1" or barKey == "pet" or barKey == "stance" then
        container:SetFrameStrata("MEDIUM")
        container:SetFrameLevel(math.max(container:GetFrameLevel(), 20))
    end

    local settings = GetEffectiveSettings(barKey)
    local buttons = {}

    if barKey == "bar1" or (barKey:match("^bar[2-8]$")) then
        buttons = BuildStandardOwnedButtons(container, barKey)
    elseif barKey == "pet" or barKey == "stance" then
        -- TOMOMOD P2.9 / Midnight 12.1:
        -- ActionBarController_UpdateAll() calls StanceBar:Update() before it writes
        -- MainActionBar's protected actionpage attribute. Mutating StanceBar or
        -- StanceButton* from addon execution can therefore taint the controller
        -- before MainActionBar:SetAttribute() is reached. Leave the native stance
        -- graph completely Blizzard-owned. The TUI stance buttons are separate.
        --
        -- TOMOMOD P2.12 / Midnight 12.1 Edit Mode hardening:
        -- Keep PetActionBar Blizzard-owned too. Edit Mode setup touches
        -- PetActionBar before RefreshTargetAndFocus(); retiring or silencing
        -- the native pet bar from addon execution can taint that setup pass,
        -- causing the protected TargetUnit()/FocusUnit() calls that follow to
        -- be attributed to TomoMod. TUI_PetButton* are separate owned buttons,
        -- so the native PetActionBar/PetActionButton* graph can stay untouched.
        -- StanceBar/PossessActionBar already follow this zero-touch rule.

        -- Midnight 12.1:
        -- StanceButtonTemplate is NOT safe for an addon-owned clone. Its normal
        -- OnClick calls the global Blizzard StanceBar:Select(), which writes
        -- StanceBar.lastSelected and then casts the form. During combat that
        -- addon-originated write taints StanceBar before ActionBarController
        -- validates MainActionBar/MultiBars, producing SetShownBase/ShowBase and
        -- secret-cooldown failures. Build TUI stance buttons as independent
        -- SecureActionButtons instead; the secure "spell" action casts the form
        -- without ever entering the native StanceBar object.
        -- P3.5.15 / Midnight 12.1:
        -- Pet and stance controls are fully TUI-owned secure buttons.  Do not
        -- inherit PetActionButtonTemplate or StanceButtonTemplate: both carry
        -- Blizzard bar-specific Lua behavior.  SecureActionButtonTemplate
        -- already provides pristine protected handlers for type="pet" and
        -- type="spell", so these controls can remain independent of the
        -- native PetActionBar/StanceBar graphs.
        local template = "ActionButtonTemplate,SecureActionButtonTemplate"
        local prefix = barKey == "pet" and "TUI_PetButton" or "TUI_StanceButton"
        local count = BUTTON_COUNTS[barKey] or 10

        for i = 1, count do
            local btnName = prefix .. i
            local btn = _G[btnName]
            if not btn then
                local ok
                ok, btn = ns.SafeCall("best-effort-style", CreateFrame, "CheckButton", btnName, container, template)
                if not ok then btn = _G[btnName] end
                btn:SetID(i)
            else
                btn:SetParent(container)
            end
            -- Keep the secure OnClick installed by SecureActionButtonTemplate.
            -- Removing it disables the protected spell/pet dispatcher entirely.
            InstallBareOwnedActionButtonMethods(btn)
            btn:SetScript("OnAttributeChanged", nil)
            btn:EnableMouse(true)
            if btn.SetMouseClickEnabled then btn:SetMouseClickEnabled(true) end
            if btn.SetMouseMotionEnabled then btn:SetMouseMotionEnabled(true) end
            btn:RegisterForClicks("AnyDown", "AnyUp")
            btn:SetFrameStrata("MEDIUM")
            btn:SetFrameLevel(math.max((container.GetFrameLevel and container:GetFrameLevel() or 0) + 10, 10))

            do
                local _db = GetDB()
                local _g = _db and _db.global
                btn:SetAttribute("useOnKeyDown", not _g or _g.useOnKeyDown ~= false)
            end

            if barKey == "pet" then
                btn.id = i
                -- Left click is a native secure pet action.  Right click is
                -- configured by UpdatePetButton() as a secure macro only when
                -- the slot supports autocast.
                btn:SetAttribute("type1", "pet")
                btn:SetAttribute("action1", i)
                btn:SetAttribute("type2", ATTRIBUTE_NOOP or "")
                btn:SetAttribute("macrotext2", nil)
                btn:RegisterForDrag("LeftButton", "RightButton")
                btn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetPetAction(self:GetID())
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", GameTooltip_Hide)
                btn:SetScript("OnDragStart", function(self)
                    if InCombatLockdown() then return end
                    local slot = self.id or self:GetID()
                    if not slot or slot < 1 then return end
                    self:SetChecked(false)
                    PickupPetAction(slot)
                    ActionBarsOwned.UpdatePetButton(self)
                end)
                btn:SetScript("OnReceiveDrag", function(self)
                    if InCombatLockdown() then return end
                    local slot = self.id or self:GetID()
                    if not slot or slot < 1 then return end
                    local cursorType = GetCursorInfo()
                    if cursorType == "petaction" then
                        self:SetChecked(false)
                        PickupPetAction(slot)
                        ActionBarsOwned.UpdatePetButton(self)
                    end
                end)
            else
                -- type=spell is executed by SecureActionButton_OnClick.  The
                -- spell attribute itself is refreshed out of combat in
                -- UpdateStanceButton(), while form transitions in combat need no
                -- further protected writes.
                btn:SetAttribute("type", "spell")
                btn:SetScript("OnEnter", function(self)
                    GameTooltip_SetDefaultAnchor(GameTooltip, self)
                    GameTooltip:SetShapeshift(self:GetID())
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", GameTooltip_Hide)
            end
            btn:Show()
            if barKey == "pet" then
                ActionBarsOwned.UpdatePetButton(btn)
            elseif barKey == "stance" then
                ActionBarsOwned.UpdateStanceButton(btn)
            end
            buttons[i] = btn
        end
    elseif barKey == "microbar" then
        if barFrame then
            HideManagedBlizzardBarFrame(barFrame, true)
        end

        local origLayout = MicroMenu and MicroMenu.Layout
        if MicroMenu then MicroMenu.Layout = function() end end

        ActionBarsOwned._microAnchors = {}
        for i, name in ipairs(MICRO_BUTTON_NAMES) do
            local btn = _G[name]
            if btn then
                ActionBarsOwned._microAnchors[i] = { btn:GetPoint() }
                btn:SetParent(container)
                btn:Show()
                buttons[#buttons + 1] = btn
            end
        end

        -- HelpMicroButton is a distinct Blizzard Help action, not the Game Menu.
        -- Do not reparent or overlay it on TomoMod's micro bar; MainMenuMicroButton
        -- is the real logout/settings button and stays in MICRO_BUTTON_NAMES.
        if MicroMenu and origLayout then MicroMenu.Layout = origLayout end

        local barDB = GetBarSettings("microbar")
        local clickthrough = barDB and barDB.clickthrough
        for _, btn in ipairs(buttons) do
            -- Always restore mouse input when click-through is turned back off.
            btn:EnableMouse(not clickthrough)
        end

        local function RefreshCharacterMicroPortrait()
            local charBtn = _G.CharacterMicroButton
            if not charBtn then return end
            if charBtn.UpdateMicroButton then
                if securecallfunction then
                    securecallfunction(charBtn.UpdateMicroButton, charBtn)
                else
                    pcall(charBtn.UpdateMicroButton, charBtn)
                end
            end
            if charBtn.Portrait and SetPortraitTexture then
                SetPortraitTexture(charBtn.Portrait, "player")
                charBtn.Portrait:Show()
            end
        end
        RefreshCharacterMicroPortrait()

        if not ActionBarsOwned._microLayoutHooked then
            ActionBarsOwned._microLayoutHooked = true

            local microCombatLayoutPending = false
            local function ReclaimMicroButtons()
                if not ActionBarsOwned.initialized then return end
                if ActionBarsOwned._microOwnedByUI then return end

                if MicroMenu then
                    MicroMenu.oldGridSettings = nil
                end

                local btns = ActionBarsOwned.nativeButtons["microbar"]
                local cont = ActionBarsOwned.containers["microbar"]
                if not btns or not cont then return end

                local needsReparent = false
                for _, btn in ipairs(btns) do
                    if btn:GetParent() ~= cont then
                        needsReparent = true
                        break
                    end
                end

                if needsReparent and InCombatLockdown() then
                    if not ActionBarsOwned._microDeferPending then
                        ActionBarsOwned._microDeferPending = true
                        ns.Addon:RegisterEvent("PLAYER_REGEN_ENABLED", function()
                            ns.Addon:UnregisterEvent("PLAYER_REGEN_ENABLED")
                            ActionBarsOwned._microDeferPending = false
                            ReclaimMicroButtons()
                        end)
                    end
                    return
                end

                if needsReparent then
                    for _, btn in ipairs(btns) do
                        if btn:GetParent() ~= cont then
                            btn:SetParent(cont)
                        end
                    end
                end
                local microDB = GetBarSettings("microbar")
                local ct = microDB and microDB.clickthrough
                for _, btn in ipairs(btns) do
                    -- Mouse state can outlive a reparent; reconcile it every pass.
                    btn:EnableMouse(not ct)
                end
                RefreshCharacterMicroPortrait()

                if InCombatLockdown() then
                    if not microCombatLayoutPending then
                        microCombatLayoutPending = true
                        local f = ActionBarsOwned._microLayoutFrame
                        if not f then
                            f = CreateFrame("Frame")
                            ActionBarsOwned._microLayoutFrame = f
                        end
                        f:RegisterEvent("PLAYER_REGEN_ENABLED")
                        f:SetScript("OnEvent", function(self)
                            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                            microCombatLayoutPending = false
                            if not ActionBarsOwned._microOwnedByUI then
                                LayoutNativeButtons("microbar")
                            end
                        end)
                    end
                else
                    LayoutNativeButtons("microbar")
                end
            end

            local function YieldMicroButtons()
                ActionBarsOwned._microOwnedByUI = true
                local btns = ActionBarsOwned.nativeButtons["microbar"]
                if btns and MicroMenu then
                    local savedAnchors = ActionBarsOwned._microAnchors
                    for i, btn in ipairs(btns) do
                        btn:SetParent(MicroMenu)
                        btn:EnableMouse(true)
                        if savedAnchors and savedAnchors[i] then
                            btn:ClearAllPoints()
                            btn:SetPoint(unpack(savedAnchors[i]))
                        end
                    end
                end
            end

            local function ReclaimOrYield()
                if MicroMenu and MicroMenu:GetParent() ~= UIParent then
                    YieldMicroButtons()
                else
                    ActionBarsOwned._microOwnedByUI = false
                    ReclaimMicroButtons()
                end
            end

            if MicroMenu then
                hooksecurefunc(MicroMenu, "SetParent", function(_, parent)
                    if not ActionBarsOwned.initialized then return end
                    if parent == UIParent then
                        ActionBarsOwned._microOwnedByUI = false
                        ReclaimMicroButtons()
                    else
                        YieldMicroButtons()
                    end
                end)
            end

            if MicroMenuContainer and MicroMenuContainer.Layout then
                hooksecurefunc(MicroMenuContainer, "Layout", ReclaimMicroButtons)
            end
            if MicroMenu and MicroMenu.Layout and MicroMenu ~= MicroMenuContainer then
                hooksecurefunc(MicroMenu, "Layout", ReclaimMicroButtons)
            end

            if MicroMenu and MicroMenu.UpdateHelpTicketButtonAnchor then
                local ticketAnchorPending = false
                hooksecurefunc(MicroMenu, "UpdateHelpTicketButtonAnchor", function()
                    if not ActionBarsOwned.initialized then return end
                    if ticketAnchorPending then return end
                    ticketAnchorPending = true
                    C_Timer.After(0, function()
                        ticketAnchorPending = false
                        AnchorHelpTicketButton()
                    end)
                end)
            end

            if UpdateMicroButtons then
                hooksecurefunc("UpdateMicroButtons", ReclaimMicroButtons)
            end

            if UpdateMicroButtonsParent then
                hooksecurefunc("UpdateMicroButtonsParent", ReclaimOrYield)
            end

            -- P2.2: do not hook the secure ActionBarController update path.
            -- UpdateMicroButtons / UpdateMicroButtonsParent already reclaim the
            -- micro menu, and keeping our callback off this controller further
            -- reduces attribution/taint surface during action-page transitions.

            if C_PetBattles then
                local petBattleFrame = CreateFrame("Frame")
                petBattleFrame:RegisterEvent("PET_BATTLE_CLOSE")
                petBattleFrame:SetScript("OnEvent", function()
                    if not ActionBarsOwned.initialized then return end
                    ActionBarsOwned._microOwnedByUI = false
                    if MicroMenu and MicroMenu:GetParent() ~= UIParent then
                        MicroMenu:SetParent(UIParent)
                    else
                        ReclaimMicroButtons()
                    end
                end)
            end

            if not ActionBarsOwned._microAlertAnchorHooked then
                ActionBarsOwned._microAlertAnchorHooked = true

                local EDGE_THRESHOLD_Y = 200
                local EDGE_THRESHOLD_X = 60

                local function ReanchorMicroAlert(button)
                    if not button then return end
                    local alert = button.alert
                    if not alert and button.GetName then
                        alert = _G[button:GetName() .. "Alert"]
                    end
                    if alert == button.FlashBorder or alert == button.FlashContent then
                        return
                    end
                    if not alert or not alert:IsShown() then return end

                    local screenH = GetScreenHeight()
                    local screenW = GetScreenWidth()
                    if not screenH or screenH == 0 then return end

                    local _, btnTop = button:GetCenter()
                    local btnLeft = button:GetLeft()
                    local btnRight = button:GetRight()
                    if not btnTop or not btnLeft then return end

                    local nearTop = (screenH - btnTop) < EDGE_THRESHOLD_Y
                    local xOff = 0
                    if btnLeft < EDGE_THRESHOLD_X then
                        xOff = EDGE_THRESHOLD_X - btnLeft
                    elseif btnRight and (screenW - btnRight) < EDGE_THRESHOLD_X then
                        xOff = -( EDGE_THRESHOLD_X - (screenW - btnRight) )
                    end

                    alert:ClearAllPoints()
                    if nearTop then
                        alert:SetPoint("TOP", button, "BOTTOM", xOff, -4)
                        if alert.Arrow then
                            alert.Arrow:ClearAllPoints()
                            alert.Arrow:SetPoint("BOTTOM", alert, "TOP", 0, -2)
                            alert.Arrow:SetTexCoord(0, 1, 1, 0)
                        end
                    else
                        alert:SetPoint("BOTTOM", button, "TOP", xOff, 4)
                        if alert.Arrow then
                            alert.Arrow:ClearAllPoints()
                            alert.Arrow:SetPoint("TOP", alert, "BOTTOM", 0, 2)
                            alert.Arrow:SetTexCoord(0, 1, 0, 1)
                        end
                    end
                end

                if type(MainMenuMicroButton_ShowAlert) == "function" then
                    hooksecurefunc("MainMenuMicroButton_ShowAlert", function(button)
                        C_Timer.After(0, function()
                            ReanchorMicroAlert(button)
                        end)
                    end)
                end
            end
        end
    elseif barKey == "bags" then
        if barFrame then
            HideManagedBlizzardBarFrame(barFrame, true)
        end

        local bagButtons = GetBarButtons("bags")
        ---@type fun(...)
        local noopFunc = function() end
        for i, btn in ipairs(bagButtons) do
            btn:SetParent(container)
            btn:Show()
            if btn.SetBarExpanded then
                btn.SetBarExpanded = noopFunc
            end
            buttons[i] = btn
        end

        if BagsBar and EventRegistry and EventRegistry.UnregisterCallback then
            ns.SafeCallMethod("best-effort-style", EventRegistry, "UnregisterCallback", "MainMenuBarManager.OnExpandChanged", BagsBar)
        end

        if not ActionBarsOwned._bagsLayoutHooked then
            ActionBarsOwned._bagsLayoutHooked = true
            local bagsBar = BagsBar
            if bagsBar and bagsBar.Layout then
                hooksecurefunc(bagsBar, "Layout", function()
                    if not ActionBarsOwned.initialized then return end
                    if not ActionBarsOwned.nativeButtons["bags"] then return end
                    if InCombatLockdown() then
                        ActionBarsOwned.pendingBagsReclaim = true
                        return
                    end
                    C_Timer.After(0, function()
                        if InCombatLockdown() then
                            ActionBarsOwned.pendingBagsReclaim = true
                            return
                        end
                        local btns = ActionBarsOwned.nativeButtons["bags"]
                        local cont = ActionBarsOwned.containers["bags"]
                        if btns and cont then
                            for _, btn in ipairs(btns) do
                                if btn:GetParent() ~= cont then
                                    btn:SetParent(cont)
                                end
                            end
                            LayoutNativeButtons("bags")
                        end
                    end)
                end)
            end
        end
    end

    ActionBarsOwned.nativeButtons[barKey] = buttons
    if barKey ~= "pet" and barKey ~= "stance" and barKey ~= "microbar" and barKey ~= "bags" then
        FinalizeStandardOwnedActionButtons(container, barKey, buttons)
        if EnsureOwnedFlyoutFrame and ShouldUseOwnedFlyoutForBar and ShouldUseOwnedFlyoutForBar(barKey) then
            local flyoutHandler = EnsureOwnedFlyoutFrame()
            if flyoutHandler then
                container:SetFrameRef("qui-flyout-handler", flyoutHandler)
            end
        end
    end

    if not ActionBarsOwned.slotMap then ActionBarsOwned.slotMap = {} end
    for _, btn in ipairs(buttons) do
        local action = GetSafeActionSlot(btn)
        if action and action > 0 then
            ActionBarsOwned.slotMap[action] = { button = btn, barKey = barKey }
        end
    end

    if barKey ~= "pet" and barKey ~= "stance" and barKey ~= "microbar" and barKey ~= "bags" then
        for _, btn in ipairs(buttons) do
            SetupStandardOwnedButtonRuntime(container, btn)
        end

        PrimeStandardOwnedButtonVisuals(buttons)
    end

    if SKINNABLE_BAR_KEYS[barKey] then
        layoutHandler:SetFrameRef("bar-" .. barKey, container)
        for i, btn in ipairs(buttons) do
            layoutHandler:SetFrameRef("btn-" .. barKey .. "-" .. i, btn)
        end
    end

    if SKINNABLE_BAR_KEYS[barKey] then
        local capturedSettings = settings
        C_Timer.After(0, function()
            if not capturedSettings then return end
            local btns = ActionBarsOwned.nativeButtons[barKey]
            if not btns then return end
            for _, btn in ipairs(btns) do
                local st = GetFrameState(btn)
                st.sk_sz = nil
                SkinButton(btn, capturedSettings)
                UpdateButtonText(btn, capturedSettings)
                UpdateEmptySlotVisibility(btn, capturedSettings)
            end
        end)

        local prefix = BINDING_COMMANDS[barKey]
        if prefix then
            local LKB = LibStub("LibKeyBound-1.0", true)
            for i, btn in ipairs(buttons) do
                local state = GetFrameState(btn)
                state.bindingCommand = prefix .. i
                state.keybindMethods = true
                if LKB and not state.lkbHooked then
                    state.lkbHooked = true
                    btn:HookScript("OnEnter", function(self)
                        if LKB:IsShown() then
                            local bf = LKB.frame
                            if not bf or bf.button ~= self then
                                LKB:Set(self)
                            end
                        end
                    end)
                end
            end
        end
    end

    LayoutNativeButtons(barKey)
    RestoreContainerPosition(barKey)
    SetupOwnedBarMouseover(barKey)

    if SKINNABLE_BAR_KEYS[barKey] then
        ApplyBarOverrideBindings(barKey)
    end

end
